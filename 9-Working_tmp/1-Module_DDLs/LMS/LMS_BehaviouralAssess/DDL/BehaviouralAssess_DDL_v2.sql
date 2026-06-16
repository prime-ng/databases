-- =============================================================================
-- BA — Behavioural Assessment Module DDL
-- Module    : BehaviouralAssessment (Modules\BehaviouralAssessment)
-- File      : BA_DDL_v2.sql
-- Version   : 2.0 — April 2026
-- Table Prefix: ba_* (16 tables)
-- Database  : tenant_db (one per tenant, no tenant_id columns)
-- Based on  : BehaviouralAssessment_v1.md + BA_FeatureSpec.md
-- =============================================================================
--
-- PURPOSE:
--   Provides a complete behavioural competency tracking and assessment engine
--   for Indian K-12 schools within the Prime-AI multi-tenant platform.
--   Schools can define behavioural categories (Classroom Engagement, Respect,
--   Leadership, etc.), assign observable criteria under each, and have teachers
--   rate students periodically using configurable rating scales.
--
-- WHAT THIS MODULE COVERS:
--   1. Rating Configuration    — Configurable scales (5-point, 3-point, etc.)
--                                with ordered levels, numeric values, and
--                                min/max boundaries for grade mapping
--   2. Categories & Criteria   — Hierarchical behavioural categories (positive/
--                                negative polarity) with weighted criteria
--   3. Assessment Workflow     — Teacher enters per-student per-criterion ratings
--                                via grid UI; Draft → Submitted → Reviewed → Locked
--   4. Incident Logging        — Ad-hoc positive/negative behavioural events with
--                                severity, witnesses, interventions, and follow-up
--   5. Score Computation       — Weighted criterion → category → overall aggregation
--                                with multi-teacher averaging and grade mapping
--   6. Report Card Integration — Optional weighted contribution of behavioural
--                                score to final academic result (5–20% weightage)
--
-- DEPENDENCY ARCHITECTURE (6 Layers):
--   Layer 1: ba_rating_scales, ba_categories, ba_interventions
--            (no deps on other ba_* tables — foundation entities)
--   Layer 2: ba_rating_levels → ba_rating_scales
--            ba_criteria → ba_categories
--   Layer 3: ba_class_category_jnt → ba_categories + sch_classes
--            ba_assessment_periods → sch_org_academic_sessions_jnt
--            ba_config → ba_rating_scales + sch_org_academic_sessions_jnt
--   Layer 4: ba_assessments → ba_assessment_periods + sch_employees + sch_class_section_jnt
--            ba_audit_log (standalone — polymorphic, no FK deps)
--   Layer 5: ba_assessment_ratings → ba_assessments + std_students + ba_criteria + ba_rating_levels
--            ba_student_remarks → ba_assessments + std_students
--            ba_computed_scores → std_students + ba_categories + ba_assessment_periods
--            ba_incidents → std_students + sch_employees + ba_categories + ba_criteria
--   Layer 6: ba_incident_witnesses_jnt → ba_incidents
--            ba_incident_intervention_jnt → ba_incidents + ba_interventions
--
-- CROSS-MODULE DEPENDENCIES (read-only — BA never modifies these tables):
--   ┌──────────────────────────────────┬──────────────┬──────────────────────────┐
--   │ Table                            │ PK Type      │ BA Usage                 │
--   ├──────────────────────────────────┼──────────────┼──────────────────────────┤
--   │ std_students                     │ INT UNSIGNED │ Student being assessed   │
--   │ sch_employees                    │ INT UNSIGNED │ Teacher/staff reference  │
--   │ sch_class_section_jnt            │ INT UNSIGNED │ Class+section scope      │
--   │ sch_classes                      │ INT UNSIGNED │ Category applicability   │
--   │ sch_org_academic_sessions_jnt    │ SMALLINT UNS │ Session scoping          │
--   │ sch_academic_term                │ SMALLINT UNS │ Optional period linking  │
--   │ sys_users                        │ INT UNSIGNED │ Audit (created/updated)  │
--   └──────────────────────────────────┴──────────────┴──────────────────────────┘
--
-- KEY DESIGN DECISIONS:
--   • No tenant_id column — stancl/tenancy v3.9 uses database-per-tenant isolation
--   • ba_class_category_jnt maps to sch_classes directly (NOT sch_class_groups_jnt
--     which is a subject+study_format junction used by Timetable)
--   • Result integration is pull-based — Exam/Result module calls
--     BehaviouralScoreService::getBulkScores(). BA never writes to exm_* tables.
--   • ba_audit_log is IMMUTABLE — no updated_at, no deleted_at
--   • Negative polarity categories are scored inversely at the service layer:
--     inverted_score = (max_scale_value + 1) - raw_score
--   • Multi-teacher averaging: when multiple teachers rate the same student on the
--     same criterion, their ratings are averaged during score computation
--
-- ASSESSMENT WORKFLOW FSM:
--   draft ──submit()──▶ submitted ──approve()──▶ reviewed ──lock()──▶ locked
--     ▲                     │                       │
--     └──── sendBack() ─────┘                       │
--     └──── sendBack() ─────────────────────────────┘
--
-- ASSESSMENT PERIOD LIFECYCLE:
--   open ──close()──▶ closed ──lock()──▶ locked (terminal)
--     ▲                  │
--     └── reopen() ──────┘
--
-- SCORE COMPUTATION FLOW:
--   ba_assessment_ratings (raw teacher ratings per student per criterion)
--     → GROUP BY criterion → AVG across teachers → criterion_score
--       → For negative polarity: invert (max+1 - raw)
--     → GROUP BY category → WEIGHTED_AVG(criterion_scores, weights) → category_score
--     → WEIGHTED_AVG(category_scores, category_weights) → overall_score
--     → MAP to grade via ba_rating_scales min/max boundaries
--     → UPSERT to ba_computed_scores (cached)
--
-- SEEDED DATA (provisioned during tenant onboarding):
--   • 1 rating scale (5-Point) + 5 levels (Outstanding → Unsatisfactory)
--   • 9 categories (5 Positive + 4 Negative) + 58 criteria (verbatim from spec)
--   • 9 interventions (3 reward + 4 corrective + 2 counselling)
--   • ba_config is NOT seeded — school must explicitly configure
--
-- v2 CHANGES FROM v1:
--   • ba_rating_scales: added `code`, `grade_type`, `min_rating`, `max_rating`
--     columns; removed `grade_boundaries_json` (grade mapping now derived from
--     min/max rating + ba_rating_levels numeric_value ranges)
--
-- PRE-REQUISITE: SchoolSetup module tables must already exist:
--   sch_classes, sch_class_section_jnt, sch_employees,
--   sch_org_academic_sessions_jnt, sch_academic_term, std_students
-- =============================================================================


-- =========================================================================
-- LAYER 1 — No dependencies on other ba_* tables
-- These are the foundation entities that other ba_* tables reference.
-- They can be created in any order among themselves.
-- =========================================================================


-- =========================================================================
-- TABLE 1: ba_rating_scales
-- =========================================================================
-- Defines the rating scales available to a school for behavioural assessment.
-- A rating scale is the measurement instrument teachers use to rate students
-- on each behavioural criterion. Each scale has an ordered set of levels
-- (stored in ba_rating_levels) with labels and numeric values.
--
-- EXAMPLES:
--   • "5-Point Behavioural Scale" — Outstanding(5), Very Good(4), Good(3),
--     Needs Improvement(2), Unsatisfactory(1)
--   • "3-Point Scale" — Exceeds(3), Meets(2), Below(1)
--   • "Descriptive Scale" — Always(4), Often(3), Sometimes(2), Rarely(1)
--
-- HOW IT WORKS:
--   • Each school can define multiple scales, but only ONE is active per
--     academic session (linked via ba_config.rating_scale_id)
--   • `code` provides a machine-readable identifier (e.g., "5_POINT")
--   • `grade_type` tells the UI/report layer how to display grades:
--     "letter" → A+/A/B+/B/C; "numeric" → 5/4/3/2/1; "descriptive" → words
--   • `min_rating` and `max_rating` define the numeric range of the scale.
--     These are used by the score computation engine to:
--     (a) Normalise scores to a 0–100 range for report card integration
--     (b) Invert negative polarity scores: inverted = (max + 1) - raw
--     (c) Validate that ba_rating_levels.numeric_value falls within bounds
--   • `is_default` marks the school's preferred scale. Only one scale should
--     have is_default=1 at a time (enforced at application layer)
--   • When a scale is deleted (soft), its levels remain but are also soft-deleted
--     via CASCADE on ba_rating_levels.rating_scale_id
--
-- RELATIONSHIP TO OTHER TABLES:
--   • ba_rating_levels.rating_scale_id → this table (1:N — levels within scale)
--   • ba_config.rating_scale_id → this table (active scale for session)
--
-- SEED DATA: One default scale ("5-Point Behavioural Scale") with code "5_POINT",
--   grade_type "letter", min_rating 1.0, max_rating 5.0
-- =========================================================================
CREATE TABLE IF NOT EXISTS `ba_rating_scales` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL COMMENT 'Unique code for the scale (e.g., "5_POINT", "3_POINT")',
  `name` VARCHAR(100) NOT NULL COMMENT 'Scale name (e.g., "5-Point Behavioural Scale")',
  `description` TEXT DEFAULT NULL COMMENT 'Optional description of the scale',
  `grade_type` VARCHAR(20) NOT NULL COMMENT 'Type of grade mapping (letter grades like A/B/C or numeric like 4/3/2)',
  `min_rating` DECIMAL(3,1) NOT NULL COMMENT 'Minimum rating value (e.g., 1.0)',
  `max_rating` DECIMAL(3,1) NOT NULL COMMENT 'Maximum rating value (e.g., 5.0)',
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


-- =========================================================================
-- TABLE 2: ba_categories
-- =========================================================================
-- Master table for behavioural categories. Categories are the top-level
-- groupings of related behavioural traits that teachers assess students on.
--
-- POLARITY CONCEPT:
--   Every category has a `polarity` — either 'positive' or 'negative'.
--   • POSITIVE categories (e.g., "Classroom Engagement", "Leadership") measure
--     desirable behaviours. Higher ratings = better score.
--   • NEGATIVE categories (e.g., "Disruptive Behaviours", "Bullying") measure
--     undesirable behaviours. The score computation engine INVERTS these:
--     inverted_score = (max_scale_value + 1) - raw_rating
--     So a student rated 5 (worst) on "Bullying" gets an inverted score of 1.
--
-- HIERARCHY:
--   Categories support self-referencing via `parent_id` for sub-categories.
--   In the default seed data, all 9 categories are top-level (parent_id=NULL).
--   Schools can optionally create sub-categories for finer-grained tracking
--   (e.g., "Classroom Engagement" → "Verbal Participation", "Written Work").
--
-- WEIGHTING:
--   `weight` determines how much this category contributes to the overall
--   behavioural score. Weights are PROPORTIONAL — they do NOT need to sum
--   to 100. The engine calculates:
--     category_contribution = (category_score × category_weight) / sum_of_all_weights
--   Default: all categories have weight=100 (equal contribution).
--
-- DEFAULT SEED DATA (9 categories):
--   POSITIVE (5): Classroom Engagement (8 criteria), Respect & Responsibility (8),
--     Cooperation & Collaboration (7), Emotional & Social Development (6),
--     Leadership & Initiative (6)
--   NEGATIVE (4): Disruptive Behaviours (7), Aggressive/Bullying (6),
--     Academic Misconduct (6), Health & Safety Violations (4)
--   Total: 58 criteria across 9 categories
--
-- RELATIONSHIP TO OTHER TABLES:
--   • ba_criteria.category_id → this table (1:N — criteria within category)
--   • ba_class_category_jnt.category_id → this table (N:M — category ↔ classes)
--   • ba_computed_scores.category_id → this table (scores per category)
--   • ba_incidents.category_id → this table (optional incident categorisation)
--   • self-reference: parent_id → ba_categories.id (hierarchy)
--
-- ON DELETE:
--   • parent_id ON DELETE SET NULL — orphans sub-categories to top-level
--   • ba_criteria uses ON DELETE CASCADE — deleting a category removes its criteria
-- =========================================================================
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


-- =========================================================================
-- TABLE 3: ba_interventions
-- =========================================================================
-- Master list of predefined interventions — actions that can be taken in
-- response to a behavioural incident (positive or negative).
--
-- THREE TYPES:
--   • REWARD       — Positive reinforcement actions given for good behaviour.
--                    Examples: Award/Certificate, Public Recognition, Extra Privileges
--   • CORRECTIVE   — Disciplinary actions for negative behaviour.
--                    Examples: Verbal Warning, Written Warning, Detention, Suspension
--   • COUNSELLING  — Supportive actions involving guidance professionals or parents.
--                    Examples: Parent Meeting, Counselling Referral
--
-- HOW IT WORKS:
--   • When a teacher logs an incident (ba_incidents), they can select one or
--     more interventions from this master list via ba_incident_intervention_jnt
--   • Teachers can also write free-text intervention notes directly on the
--     incident record (ba_incidents.intervention_notes) in addition to or
--     instead of selecting from this list
--   • Schools can add custom interventions beyond the 9 seeded defaults
--   • sort_order controls display sequence in the UI dropdown/checkbox list
--
-- RELATIONSHIP TO OTHER TABLES:
--   • ba_incident_intervention_jnt.intervention_id → this table (N:M junction
--     linking incidents to interventions applied)
--
-- SEED DATA (9 interventions):
--   Reward(3): Award/Certificate, Public Recognition, Extra Privileges
--   Corrective(4): Verbal Warning, Written Warning, Detention, Suspension
--   Counselling(2): Parent Meeting, Counselling Referral
-- =========================================================================
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
-- These tables reference Layer 1 tables only. They define the detail records
-- (levels within scales, criteria within categories).
-- =========================================================================


-- =========================================================================
-- TABLE 4: ba_rating_levels
-- =========================================================================
-- Individual levels within a rating scale. Each level has a human-readable
-- label and a numeric value used for score computation.
--
-- HOW IT WORKS:
--   • A scale has N ordered levels. For a 5-Point scale: 5 levels.
--   • Teachers select ONE level per student per criterion when filling the
--     assessment grid (ba_assessment_ratings.rating_level_id → this table)
--   • The `numeric_value` is the raw score that feeds into the weighted
--     average computation in BehaviouralScoreService
--   • `sort_order` defines display order in the UI dropdown. sort_order=1
--     represents the LOWEST level (worst); highest sort_order = best.
--   • The UNIQUE constraint (rating_scale_id, sort_order) prevents two
--     levels from occupying the same display position within a scale.
--
-- EXAMPLE (5-Point Scale):
--   sort_order=1: "Unsatisfactory"    numeric_value=1.0
--   sort_order=2: "Needs Improvement" numeric_value=2.0
--   sort_order=3: "Good"              numeric_value=3.0
--   sort_order=4: "Very Good"         numeric_value=4.0
--   sort_order=5: "Outstanding"       numeric_value=5.0
--
-- VALIDATION:
--   At the application layer, numeric_value must fall within the parent
--   scale's [min_rating, max_rating] range. E.g., for a scale with
--   min_rating=1.0 and max_rating=5.0, all levels must have
--   1.0 ≤ numeric_value ≤ 5.0
--
-- ON DELETE:
--   • CASCADE from ba_rating_scales — deleting a scale removes all its levels
--   • ba_assessment_ratings.rating_level_id uses ON DELETE SET NULL — if a
--     level is deleted, existing ratings become unlinked (NULL = not rated)
--
-- RELATIONSHIP TO OTHER TABLES:
--   • ba_rating_levels.rating_scale_id → ba_rating_scales.id (parent)
--   • ba_assessment_ratings.rating_level_id → this table (selected level)
-- =========================================================================
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


-- =========================================================================
-- TABLE 5: ba_criteria
-- =========================================================================
-- Individual, observable behavioural criteria within a category. Each
-- criterion is a specific behaviour that teachers can observe and rate.
--
-- HOW IT WORKS:
--   • Each criterion belongs to exactly one category (ba_categories)
--   • Teachers rate students on each active criterion during assessments
--     using the configured rating scale levels
--   • Criteria inherit their polarity from the parent category — there is
--     no separate polarity field on criteria
--   • `weight` determines this criterion's contribution to the category
--     score. Weights are proportional (see ba_categories.weight explanation)
--     Default: equal weight = 100 / criteria_count within the category
--
-- EXAMPLES (from "Classroom Engagement" category):
--   1. "Active participation in class discussions and oral activities"
--   2. "Asking thoughtful, relevant, and clarifying questions"
--   3. "Paying sustained attention to instructions, lessons, and demonstrations"
--   4. "Completing classwork, assignments, and homework on time and with care"
--   ... (8 criteria total in this category)
--
-- SCORE COMPUTATION ROLE:
--   criterion_score = rating.numeric_value (from ba_rating_levels)
--   If multiple teachers rate the same student on the same criterion:
--     criterion_score = AVG(all_teacher_ratings_for_this_criterion)
--   category_score = WEIGHTED_AVG(criterion_scores, criterion_weights)
--
-- RELATIONSHIP TO OTHER TABLES:
--   • ba_criteria.category_id → ba_categories.id (parent category)
--   • ba_assessment_ratings.criterion_id → this table (rated criterion)
--   • ba_incidents.criterion_id → this table (optional incident linkage)
--
-- ON DELETE:
--   • CASCADE from ba_categories — deleting a category removes all its criteria
--   • ba_assessment_ratings uses ON DELETE RESTRICT — cannot delete a criterion
--     that has existing ratings (must deactivate via is_active instead)
-- =========================================================================
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
-- LAYER 3 — Depends on sch_* (cross-module) + Layer 1
-- These tables link BA entities to existing SchoolSetup tables and
-- configure the assessment infrastructure (periods, school-level settings).
-- =========================================================================


-- =========================================================================
-- TABLE 6: ba_class_category_jnt
-- =========================================================================
-- Junction table that maps which behavioural categories apply to which
-- classes (grade levels). This allows schools to have different behavioural
-- criteria for different age groups.
--
-- WHY THIS EXISTS:
--   A primary school (Grades 1-5) may assess students on "Classroom Engagement"
--   and "Cooperation" but NOT on "Academic Misconduct" (cheating), which is more
--   relevant for secondary students (Grades 6-12). This table enables that
--   differentiation.
--
-- WHY sch_classes AND NOT sch_class_groups_jnt:
--   The existing DDL table `sch_class_groups_jnt` is a class+section+subject+
--   studyFormat junction used by the Timetable module — it is NOT a simple
--   "Primary vs Secondary" grouping concept. To avoid semantic confusion, this
--   junction maps categories directly to `sch_classes` (individual grade levels).
--   The UI can present this as checkboxes grouped by school level (e.g.,
--   "Select all Primary classes") for convenience.
--
-- HOW IT WORKS:
--   • Admin maps each category to the classes where it should apply
--   • During assessment entry, the system filters available criteria based
--     on which categories are mapped to the student's class
--   • UNIQUE (class_id, category_id) prevents duplicate mappings
--   • If no mappings exist for a class, ALL categories apply (permissive default)
--
-- EXAMPLE:
--   Class "Grade 1" → Classroom Engagement, Respect, Cooperation, Emotional Dev
--   Class "Grade 10" → All 9 categories (including negative ones)
--
-- CROSS-MODULE FK:
--   • class_id → sch_classes.id (PK: INT UNSIGNED)
--     sch_classes stores grade levels: BV1, BV2, 1st, 2nd, ... 12th
-- =========================================================================
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


-- =========================================================================
-- TABLE 7: ba_assessment_periods
-- =========================================================================
-- Defines the time windows during which teachers record behavioural
-- assessments. Assessment periods can align with academic exam terms
-- or be entirely independent.
--
-- LIFECYCLE (FSM):
--   open ──close()──▶ closed ──lock()──▶ locked (terminal)
--     ▲                  │
--     └── reopen() ──────┘
--
--   • OPEN: Teachers can create and edit assessments. This is the active
--     data-entry window.
--   • CLOSED: Deadline has passed or admin manually closed. No NEW assessments
--     can be created, but existing drafts remain editable. Submitted assessments
--     can still be reviewed by Principal/HOD.
--   • LOCKED: All assessments finalised. Scores are computed and cached in
--     ba_computed_scores. No further edits allowed. Scores become available
--     for report card integration via BehaviouralScoreService.
--
-- RELATIONSHIP TO ACADEMIC TERMS:
--   • `academic_session_id` (REQUIRED) → sch_org_academic_sessions_jnt.id
--     Every period belongs to an academic session (e.g., 2025-26)
--   • `academic_term_id` (OPTIONAL) → sch_academic_term.id
--     If provided, links this period to an exam term (e.g., Term 1, Term 2).
--     This allows behavioural scores to appear alongside term-wise exam results.
--     If NULL, the period is independent (e.g., "Monthly Behaviour Review").
--
-- DATE VALIDATION (enforced at application layer):
--   • start_date < end_date (assessment window)
--   • deadline ≥ end_date (teachers get at least until the window closes)
--   • Multiple periods per session are allowed (e.g., Term 1, Term 2, Annual)
--
-- CROSS-MODULE FKs:
--   • academic_session_id → sch_org_academic_sessions_jnt.id (PK: SMALLINT UNSIGNED)
--   • academic_term_id → sch_academic_term.id (PK: SMALLINT UNSIGNED)
--     NOTE: No `exm_exam_terms` table exists in the DDL. The correct reference
--     is `sch_academic_term` which stores term/quarter/semester structure.
-- =========================================================================
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


-- =========================================================================
-- TABLE 8: ba_config
-- =========================================================================
-- School-level configuration for the Behavioural Assessment module.
-- ONE record per academic session — allows year-over-year changes in
-- how behavioural scores are computed and integrated.
--
-- KEY SETTINGS:
--   • `rating_scale_id` — Which rating scale is active for this session.
--     All assessments in this session's periods use this scale's levels.
--   • `is_result_integration_enabled` — Master toggle for whether behavioural
--     scores contribute to the final academic report card. Default: OFF.
--     Schools must explicitly enable this.
--   • `weightage_percent` — When integration is enabled, this is the percentage
--     contribution of the behavioural score to the final result (5.0–20.0%).
--     Example: 10% means Final = (Academic × 0.90) + (Behavioural_norm × 0.10)
--   • `aggregation_method` — How category scores combine into the overall score:
--     - 'average': Simple average of all category scores
--     - 'weighted_average': Weighted by ba_categories.weight (DEFAULT — recommended)
--     - 'separate_display': No numeric merge; categories shown individually on report
--   • `parent_notification_threshold` — The minimum incident severity that
--     triggers an automatic parent notification:
--     - 'minor': Notify for ALL incidents (most verbose)
--     - 'moderate': Notify for moderate, major, critical (DEFAULT)
--     - 'major': Notify only for major and critical
--     - 'critical': Notify only for critical incidents (least verbose)
--
-- NOT SEEDED:
--   ba_config is NOT seeded during tenant onboarding. When first accessed,
--   BehaviouralConfigService::getConfig() creates a default record with
--   is_result_integration_enabled=false and the default rating scale.
--
-- UNIQUE CONSTRAINT:
--   uq_ba_config_session ensures ONE config per academic session.
--   If a school needs different settings for a new year, they create a new
--   config record for the new session (old session's config is preserved).
-- =========================================================================
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
-- These tables represent the transactional assessment records and the
-- audit trail. They reference assessment periods, teachers, and class-sections.
-- =========================================================================


-- =========================================================================
-- TABLE 9: ba_assessments
-- =========================================================================
-- Header record for a teacher's behavioural assessment of a class-section
-- during an assessment period. This is the parent record that groups all
-- individual rating entries (ba_assessment_ratings) together.
--
-- ONE ASSESSMENT PER TEACHER PER CLASS-SECTION PER PERIOD:
--   The UNIQUE constraint (teacher_id, class_section_id, period_id) ensures
--   that each teacher submits exactly one assessment for each class-section
--   in each assessment period. This prevents duplicate submissions.
--
-- TEACHER ASSIGNMENT:
--   The system does NOT store teacher-class assignments in the BA module.
--   Instead, it resolves them from existing SchoolSetup data:
--   • Class Teacher: sch_class_section_jnt.class_teacher_id → sys_users.id
--     → sch_employees (via user_id). Class teachers assess ALL categories
--     for all students in their section.
--   • Subject Teacher: Resolved from timetable allocations. Subject teachers
--     assess ONLY the categories mapped to their class via ba_class_category_jnt.
--
-- ASSESSMENT WORKFLOW (FSM):
--   draft ──submit()──▶ submitted ──approve()──▶ reviewed ──lock()──▶ locked
--     ▲                     │                       │
--     └──── sendBack() ─────┘                       │
--     └──── sendBack() ─────────────────────────────┘
--
--   • DRAFT: Teacher is entering/editing ratings. Auto-save every 30 seconds.
--   • SUBMITTED: Teacher has completed all ratings and submitted for review.
--     `submitted_at` timestamp recorded. NotifyPrincipal event fired.
--   • REVIEWED: Principal/HOD has approved. `reviewed_by` + `reviewed_at` set.
--     Score computation triggered automatically via AssessmentApproved event.
--   • LOCKED: Assessment period locked. Terminal state — no further edits.
--
-- SEND-BACK FLOW:
--   Principal can send back to draft with `reviewer_remarks` explaining what
--   needs correction. Teacher sees the remarks and can revise their ratings
--   before re-submitting.
--
-- CROSS-MODULE FKs:
--   • teacher_id → sch_employees.id (INT UNSIGNED) — the assessing teacher
--   • class_section_id → sch_class_section_jnt.id (INT UNSIGNED) — class+section
--   • reviewed_by → sch_employees.id (INT UNSIGNED) — reviewer (nullable)
--
-- INDEX STRATEGY:
--   • idx_ba_assess_status (period_id, status) — Powers the Principal's
--     dashboard query: "Show me all submitted assessments for Term 1"
--   • Separate indexes on teacher_id, class_section_id, period_id for
--     individual lookups and join performance
-- =========================================================================
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


-- =========================================================================
-- TABLE 10: ba_audit_log
-- =========================================================================
-- Immutable audit trail recording every change to assessment ratings,
-- assessment status transitions, and incident modifications.
--
-- IMMUTABILITY:
--   This table has NO `updated_at`, NO `updated_by`, NO `deleted_at`.
--   Once a row is inserted, it is NEVER modified or deleted. This guarantees
--   audit integrity — even a database admin cannot silently alter history.
--
-- WHAT IS LOGGED:
--   • entity_type = 'assessment_rating': Every time a teacher changes a
--     student's rating on a criterion. Captures old_value (previous level)
--     and new_value (new level). Triggered by Eloquent Observer on
--     BaAssessmentRating model's `updating` event.
--   • entity_type = 'assessment': Status transitions (draft→submitted,
--     submitted→reviewed, etc.). Triggered by Observer on BaAssessment.
--   • entity_type = 'incident': Follow-up note additions or severity corrections.
--
-- POLYMORPHIC DESIGN:
--   Uses entity_type + entity_id instead of separate FK columns per table.
--   This avoids needing 3 nullable FK columns and makes the table extensible
--   to new audit sources without schema changes.
--
-- COMPLIANCE:
--   Required for CBSE/ICSE CCE (Continuous and Comprehensive Evaluation)
--   audit requirements. Schools must be able to demonstrate that behavioural
--   ratings were not tampered with after submission.
--
-- EXAMPLE ROW:
--   entity_type='assessment_rating', entity_id=4521, field_name='rating_level_id',
--   old_value='3', new_value='4', changed_by=42,
--   changed_at='2026-03-15 14:30:00'
--   → Teacher (user 42) upgraded student's rating from level 3 to 4
--
-- QUERY PATTERNS:
--   • "Show all changes to a specific rating": WHERE entity_type='assessment_rating'
--     AND entity_id=<rating_id> ORDER BY changed_at
--   • "Show all audit activity by a teacher": WHERE changed_by=<user_id>
--   • "Show all changes in a date range": WHERE changed_at BETWEEN ... AND ...
-- =========================================================================
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
-- These are the core transactional tables — the assessment fact table,
-- student remarks, computed score cache, and incident records.
-- This layer represents the bulk of the module's data volume.
-- =========================================================================


-- =========================================================================
-- TABLE 11: ba_assessment_ratings
-- =========================================================================
-- The CORE FACT TABLE of the entire module. Each row represents one
-- teacher's rating of one student on one behavioural criterion.
--
-- VOLUME ESTIMATION:
--   For a school with 2,000 students, 20 active criteria, 2 assessment
--   periods per year, and 1.5 teachers per student on average:
--   2,000 × 20 × 2 × 1.5 = 120,000 rows per academic year.
--   This table will be the largest in the module.
--
-- HOW IT WORKS:
--   • The assessment grid UI displays students as rows and criteria as columns
--   • Each cell in the grid corresponds to one ba_assessment_ratings row
--   • `rating_level_id` is NULL when the teacher hasn't rated that cell yet
--     (draft state — partially filled grids are allowed during data entry)
--   • `remark` allows an optional per-criterion, per-student note
--     (e.g., "Excellent presentation on climate change project")
--   • Auto-save creates/updates rows every 30 seconds during data entry
--
-- UNIQUE CONSTRAINT:
--   uq_ba_rating (assessment_id, student_id, criterion_id) prevents
--   duplicate entries. One rating per student per criterion per assessment.
--   If a teacher rates the same criterion twice, it UPSERTs (overwrites).
--
-- MULTI-TEACHER AVERAGING:
--   Multiple teachers CAN rate the same student on the same criterion IF
--   they have separate assessment records (different assessment_ids for the
--   same class-section-period). During score computation, the engine:
--   1. Groups all ratings for (student, criterion, period)
--   2. Averages the numeric_value across all teacher assessments
--   This gives a more balanced view when both the class teacher and a
--   subject teacher assess the same student.
--
-- INDEX STRATEGY:
--   • idx_ba_rating_lookup (student_id, criterion_id, assessment_id) — The
--     primary query pattern for score computation: "Get all ratings for this
--     student across all criteria for assessments in a given period"
--   • Individual indexes on assessment_id, student_id, criterion_id for
--     join performance and filtered queries
--
-- ON DELETE:
--   • CASCADE from ba_assessments — deleting an assessment removes all its ratings
--   • RESTRICT from std_students — cannot delete a student with existing ratings
--   • RESTRICT from ba_criteria — cannot delete a criterion with existing ratings
--   • SET NULL from ba_rating_levels — if a level is deleted, rating becomes unlinked
--
-- AUDIT:
--   Every update to rating_level_id is captured by the Eloquent Observer
--   → written to ba_audit_log with old and new values
-- =========================================================================
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


-- =========================================================================
-- TABLE 12: ba_student_remarks
-- =========================================================================
-- Overall teacher remarks per student per assessment. This is DIFFERENT from
-- the per-criterion remarks on ba_assessment_ratings.remark.
--
-- PURPOSE:
--   After rating a student on all individual criteria, the teacher can write
--   a holistic summary remark about the student's overall behaviour for the
--   period. This remark appears on the student's behavioural report card and
--   in the parent portal view.
--
-- EXAMPLES:
--   "Rahul has shown remarkable improvement in classroom engagement this term.
--    He actively participates in group discussions and helps peers. Continue
--    encouraging leadership activities."
--
--   "Priya needs to work on respecting classroom rules. Multiple incidents
--    of talking out of turn. Recommended for counsellor follow-up."
--
-- UNIQUE CONSTRAINT:
--   uq_ba_remark (assessment_id, student_id) — one overall remark per student
--   per assessment. If the teacher updates their remark, it overwrites.
--
-- RELATIONSHIP TO OTHER TABLES:
--   • ba_student_remarks.assessment_id → ba_assessments.id (parent assessment)
--   • ba_student_remarks.student_id → std_students.id (cross-module)
--   • Consumed by BehaviouralReportService for student reports and parent views
-- =========================================================================
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


-- =========================================================================
-- TABLE 13: ba_computed_scores
-- =========================================================================
-- Cached computed scores per student per category per assessment period.
-- This is a MATERIALISED/DENORMALISED table — scores are computed from
-- ba_assessment_ratings and cached here for fast retrieval.
--
-- WHY CACHE SCORES:
--   Computing scores requires joining ba_assessment_ratings with ba_criteria,
--   ba_categories, ba_rating_levels, and potentially averaging across multiple
--   teacher assessments. For a school with 5,000 students, doing this on-the-fly
--   for every report card render would be too slow. Caching ensures:
--   • Report card generation: O(1) lookup per student per period
--   • Bulk retrieval for class/school reports: efficient indexed query
--   • School-wide computation target: ≤ 30 seconds (queued job)
--
-- HOW SCORES ARE STORED:
--   For each student-period combination, there are N rows — one per category.
--   Each row stores that category's `numeric_score` and `grade`.
--   The `overall_score` and `overall_grade` (across all categories) are stored
--   on the FIRST category row for each student-period pair to avoid redundancy.
--   All other rows for the same student-period have overall_score = NULL.
--
-- COMPUTATION FLOW (BehaviouralScoreService::computeStudentScore):
--   1. SELECT all ba_assessment_ratings for this student + period
--   2. GROUP BY criterion_id → AVG across all teacher ratings
--   3. For negative polarity criteria: invert = (max_rating + 1) - raw_avg
--   4. GROUP criteria BY category_id
--   5. For each category: WEIGHTED_AVG(criterion_scores, criterion.weight)
--   6. Overall: WEIGHTED_AVG(category_scores, category.weight) per aggregation_method
--   7. Map scores to grades using ba_rating_scales min_rating/max_rating bounds
--   8. UPSERT into ba_computed_scores (uses ON DUPLICATE KEY UPDATE)
--
-- RECOMPUTATION TRIGGERS:
--   • AssessmentApproved event → recomputes for the affected class-section-period
--   • Manual "Recompute" button in admin UI → ComputeSchoolScoresJob (queued)
--   • computed_at timestamp tracks when each row was last computed
--
-- PUBLIC API (consumed by Exam/Result module):
--   BehaviouralScoreService::getStudentScore(studentId, periodId)
--   BehaviouralScoreService::getBulkScores(studentIds[], periodId)
--   → These read directly from this table for O(1) performance
--
-- UNIQUE CONSTRAINT:
--   uq_ba_score (student_id, category_id, period_id) — one score per
--   student per category per period. UPSERT on recomputation.
--
-- INDEX STRATEGY:
--   • idx_ba_score_lookup (student_id, period_id) — Primary query pattern
--     for "get all category scores for this student in this period"
-- =========================================================================
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


-- =========================================================================
-- TABLE 14: ba_incidents
-- =========================================================================
-- Records individual behavioural incidents — both positive (awards, good
-- deeds) and negative (disruptions, aggression, safety violations).
-- Incidents are logged independently of assessment periods and can be
-- created at any time throughout the academic year.
--
-- KEY DIFFERENCES FROM ASSESSMENTS:
--   • Assessments are periodic (per assessment period), structured (grid),
--     and apply to all students in a section simultaneously.
--   • Incidents are ad-hoc, event-driven, and apply to individual students.
--   • Incidents do NOT directly affect computed scores (they are separate
--     from the rating-based scoring system). However, they appear on student
--     reports and provide qualitative evidence alongside quantitative scores.
--
-- INCIDENT TYPES:
--   • 'positive_reinforcement' — Good behaviour worth recording.
--     Severity is NULL for positive incidents.
--     Examples: Student helped a peer, led a school event, showed initiative
--   • 'negative_incident' — Behaviour that needs attention or correction.
--     Severity is REQUIRED for negative incidents.
--
-- SEVERITY LEVELS (for negative incidents only):
--   • minor    — Low-impact behaviour (e.g., talking out of turn).
--                Usually handled with verbal reminder.
--   • moderate — Repeated or disruptive behaviour (e.g., not following rules).
--                May trigger parent notification (depends on ba_config threshold).
--   • major    — Serious misconduct (e.g., bullying, property damage).
--                Typically triggers parent notification and formal intervention.
--   • critical — Dangerous or harmful behaviour (e.g., physical aggression,
--                substance possession). Always triggers parent notification.
--                May require external authority involvement.
--
-- LOCATION TRACKING:
--   Records WHERE the incident occurred to enable spatial analysis:
--   classroom, playground, corridor, lab, transport, canteen, library, other.
--   School analytics can identify hotspot locations for targeted supervision.
--
-- IMMUTABILITY (BR-BA-008):
--   Once created, core incident fields CANNOT be modified:
--   student_id, incident_date, incident_type, severity, description, location
--   ONLY these fields can be updated after creation:
--   follow_up_notes, follow_up_date, is_follow_up_required, is_notified
--   This is enforced at the service layer (BehaviouralIncidentService).
--
-- PARENT NOTIFICATIONS:
--   When an incident is created, BehaviouralIncidentService checks:
--   incident.severity ≥ ba_config.parent_notification_threshold
--   If true, IncidentCreated event fires → Notification module sends alert.
--   `is_notified` flag tracks whether the notification was sent.
--
-- FOLLOW-UP WORKFLOW:
--   • Teacher sets is_follow_up_required = true with a follow_up_date
--   • Follow-up reminders surface on the teacher's dashboard
--   • When the follow-up occurs, teacher appends to follow_up_notes
--   • follow_up_notes is appendable (not overwriteable) — each addition
--     timestamps itself within the text
--
-- ATTACHMENTS:
--   attachments_json stores references to uploaded evidence files:
--   [{"media_id": 12, "filename": "playground_incident.jpg"}, ...]
--   Files are stored via Spatie MediaLibrary in the tenant's storage path.
--   The JSON column avoids a separate attachments junction table for this
--   relatively low-volume feature.
--
-- INDEX STRATEGY:
--   • idx_ba_incident_timeline (student_id, incident_date) — Primary query
--     for "show me all incidents for this student in chronological order"
--   • idx_ba_incident_type and idx_ba_incident_severity — For analytics:
--     "count all major incidents this term" or "all positive reinforcements"
--
-- CROSS-MODULE FKs:
--   • student_id → std_students.id (INT UNSIGNED) — student involved
--   • reported_by → sch_employees.id (INT UNSIGNED) — reporting teacher/staff
--   • category_id → ba_categories.id (OPTIONAL — links incident to a category)
--   • criterion_id → ba_criteria.id (OPTIONAL — links to specific criterion)
-- =========================================================================
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
-- Junction tables for incident relationships (witnesses, interventions).
-- These are the leaf tables in the dependency graph.
-- =========================================================================


-- =========================================================================
-- TABLE 15: ba_incident_witnesses_jnt
-- =========================================================================
-- Junction table linking incidents to witnesses. Witnesses can be either
-- students or staff members (polymorphic).
--
-- POLYMORPHIC DESIGN:
--   Instead of separate student_witness_id and staff_witness_id columns
--   (which would be mostly NULL), this table uses a type+id pattern:
--   • witness_type = 'student' → witness_id references std_students.id
--   • witness_type = 'staff'   → witness_id references sch_employees.id
--
--   There is NO database-level FK on witness_id because it points to
--   different tables depending on witness_type. Referential integrity is
--   enforced at the application layer (BehaviouralIncidentService validates
--   that the referenced student/employee exists before inserting).
--
-- WHY TRACK WITNESSES:
--   • Corroboration: multiple witnesses strengthen the incident record
--   • Investigation: if the incident escalates (e.g., bullying complaint),
--     the school has a record of who saw what happened
--   • Transparency: witnesses can confirm or dispute the incident if parents
--     question the report
--
-- UNIQUE CONSTRAINT:
--   uq_ba_witness (incident_id, witness_type, witness_id) prevents the
--   same person from being listed as a witness twice for the same incident.
--
-- ON DELETE:
--   • CASCADE from ba_incidents — deleting an incident removes its witnesses
-- =========================================================================
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


-- =========================================================================
-- TABLE 16: ba_incident_intervention_jnt
-- =========================================================================
-- Junction table mapping incidents to the interventions applied. An incident
-- can have multiple interventions (e.g., both a Written Warning AND a Parent
-- Meeting), and an intervention can be used across many incidents.
--
-- HOW IT WORKS:
--   When logging an incident, the teacher selects one or more interventions
--   from the ba_interventions master list (displayed as checkboxes in the UI).
--   Each selection creates a row in this junction table.
--
--   The `notes` field allows per-application context. For example:
--   • Intervention: "Parent Meeting" → notes: "Meeting scheduled for 15-Mar
--     with mother. Father unavailable due to travel."
--   • Intervention: "Counselling Referral" → notes: "Referred to Dr. Sharma.
--     Initial session completed on 16-Mar."
--
-- COMPLEMENTARY TO ba_incidents.intervention_notes:
--   • ba_incidents.intervention_notes = free-text description of what was done
--     (for cases where the teacher doesn't select from the predefined list)
--   • ba_incident_intervention_jnt = structured selection from the master list
--     (for consistent tracking and analytics)
--   Both can be used simultaneously.
--
-- ANALYTICS VALUE:
--   This structured mapping enables queries like:
--   "How many times was 'Suspension' used this year?" → COUNT by intervention_id
--   "What interventions are most common for 'Bullying' incidents?" → JOIN with
--   ba_incidents WHERE category = 'Aggressive or Bullying'
--
-- UNIQUE CONSTRAINT:
--   uq_ba_inc_int (incident_id, intervention_id) prevents the same intervention
--   from being linked to the same incident twice.
--
-- ON DELETE:
--   • CASCADE from ba_incidents — deleting an incident removes its intervention links
--   • RESTRICT from ba_interventions — cannot delete an intervention that has been
--     used in incident records (must deactivate via is_active instead)
-- =========================================================================
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


-- ============================================================================
-- QUICK REFERENCE: How the 16 tables connect (data flow)
-- ============================================================================
--
--  ┌── CONFIGURATION (admin sets up once per session) ──────────────────────┐
--  │                                                                        │
--  │  ba_rating_scales ──┬── ba_rating_levels (5 levels per scale)          │
--  │                     └── ba_config (active scale for session)            │
--  │                              │                                         │
--  │  ba_categories ──┬── ba_criteria (58 criteria across 9 categories)     │
--  │                  └── ba_class_category_jnt ── sch_classes              │
--  │                                                                        │
--  │  ba_interventions (9 predefined actions)                               │
--  │  ba_assessment_periods (Term 1, Term 2, Annual, etc.)                  │
--  │                                                                        │
--  └────────────────────────────────────────────────────────────────────────┘
--
--  ┌── ASSESSMENT WORKFLOW (teachers fill, principal reviews) ──────────────┐
--  │                                                                        │
--  │  Teacher selects: Period + Class-Section → creates ba_assessments       │
--  │       │                                                                │
--  │       ├── ba_assessment_ratings (students × criteria grid)             │
--  │       │     Each cell = one row: student_id + criterion_id → level_id  │
--  │       │     UNIQUE (assessment_id, student_id, criterion_id)           │
--  │       │                                                                │
--  │       └── ba_student_remarks (overall remark per student)              │
--  │             UNIQUE (assessment_id, student_id)                         │
--  │                                                                        │
--  │  Status: draft ──▶ submitted ──▶ reviewed ──▶ locked                   │
--  │                                                                        │
--  │  Every rating change ──▶ ba_audit_log (immutable)                      │
--  │                                                                        │
--  └────────────────────────────────────────────────────────────────────────┘
--
--  ┌── SCORE COMPUTATION (triggered on assessment approval) ───────────────┐
--  │                                                                        │
--  │  ba_assessment_ratings (raw teacher ratings)                           │
--  │       │  GROUP BY criterion → AVG across teachers                      │
--  │       │  For negative polarity: invert = (max + 1) - raw              │
--  │       ▼                                                                │
--  │  WEIGHTED_AVG per category (criterion weights)                         │
--  │       │                                                                │
--  │       ▼                                                                │
--  │  WEIGHTED_AVG overall (category weights + aggregation method)          │
--  │       │                                                                │
--  │       ▼                                                                │
--  │  ba_computed_scores (cached: score + grade per student per category)   │
--  │       │                                                                │
--  │       ▼                                                                │
--  │  BehaviouralScoreService::getBulkScores() ◄── Exam/Result module      │
--  │  Final = (Academic × (1-w)) + (Behavioural_norm × w)                  │
--  │                                                                        │
--  └────────────────────────────────────────────────────────────────────────┘
--
--  ┌── INCIDENT TRACKING (ad-hoc, independent of assessments) ─────────────┐
--  │                                                                        │
--  │  Teacher logs: ba_incidents (student, date, type, severity, description│
--  │       │        location, intervention_notes, attachments_json)          │
--  │       │                                                                │
--  │       ├── ba_incident_witnesses_jnt (polymorphic: student or staff)    │
--  │       │                                                                │
--  │       ├── ba_incident_intervention_jnt → ba_interventions              │
--  │       │                                                                │
--  │       └── if severity ≥ threshold ──▶ IncidentCreated event            │
--  │                                       ──▶ Parent notification          │
--  │                                                                        │
--  │  Core fields IMMUTABLE after creation (BR-BA-008)                      │
--  │  Only follow_up_notes, follow_up_date appendable                       │
--  │                                                                        │
--  └────────────────────────────────────────────────────────────────────────┘
--
-- ============================================================================
-- TABLE COUNT SUMMARY: 16 tables
-- ============================================================================
--   Layer 1 (3): ba_rating_scales, ba_categories, ba_interventions
--   Layer 2 (2): ba_rating_levels, ba_criteria
--   Layer 3 (3): ba_class_category_jnt, ba_assessment_periods, ba_config
--   Layer 4 (2): ba_assessments, ba_audit_log
--   Layer 5 (4): ba_assessment_ratings, ba_student_remarks, ba_computed_scores, ba_incidents
--   Layer 6 (2): ba_incident_witnesses_jnt, ba_incident_intervention_jnt
-- ============================================================================
-- END OF BA_DDL_v2.sql
-- ============================================================================
