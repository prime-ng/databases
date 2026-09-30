-- =========================================================================================================
-- Prime-AI — Behavioural Assessment Module — Database Schema
-- =========================================================================================================
-- Module        : BehaviouralAssessment  (Modules\BehaviouralAssessment)
-- File          : Behavioural_Assess_DDL_v7.0.sql
-- Version       : 7.0
-- Date          : 2026-09-05
-- Supersedes    : LMS_BehaviouralAssess_DDL_v2.sql  (v2.0, April 2026, 16 tables)
-- Table prefix  : ba_*   (29 tables)
-- Database      : tenant_db  — one database per tenant (stancl/tenancy v3.9). NO tenant_id column.
-- MySQL         : 8.0.16 or later  — CHECK constraints are only ENFORCED from 8.0.16
-- Engine        : InnoDB / utf8mb4 / utf8mb4_unicode_ci
--
-- Governed by   : Behavioural_Assess_BRD_v3.md   (business requirement — decides WHAT)
-- Designed in   : Solution_Design_v2.md          (solution design   — decides HOW)
-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
-- WHAT THIS SCHEMA IS FOR
-- ---------------------------------------------------------------------------------------------------------
--     A behavioural competency tracking and case-management engine for Indian K-12 schools.
--
--     It holds two things that most schools keep apart, and joins them:
--
--       1. PERIODIC ASSESSMENT — planned, criteria-based, cohort-wide. Produces a number.
--       2. INCIDENT MANAGEMENT — event-driven, individual. Produces a documented case with an
--          owner and an outcome.
--
--     The deliverable is a longitudinal behavioural-development record, not a marks-entry screen.
--
-- ---------------------------------------------------------------------------------------------------------
-- WHY v7.0 EXISTS  (read this before changing anything)
-- ---------------------------------------------------------------------------------------------------------
--     The 2026-06-29 technical audit of the live module scored it 57/100 Amber and assessed 30 business
--     rules: 15 ENFORCED, 6 PARTIAL, 9 MISSING. Two findings explain the shape of this file.
--
--       BUG-BA-001  "The lock guard checks assessment.status === 'locked', but NO code ever sets that
--                    status. Period lock() updates only the period row. Net effect: 'locked' periods
--                    don't actually freeze ratings, and approved scores can be silently edited out of
--                    sync with the cache and the audit trail."
--
--       SEC-BA-001  "Severe-incident parent notification is entirely absent. A grep for
--                    Notification|notify|dispatch|event( across app/ returns zero.
--                    parent_notification_threshold is dead config and is_notified is never written."
--
--     These are not two coding oversights. They share one cause:
--
--         THE SCHEMA EXPRESSED INTENT THAT IT GAVE THE APPLICATION NO WAY TO KEEP.
--
--       - A status column on a period, with no relationship to the rows it was meant to freeze, made
--         the lock cascade something a developer had to remember. They did not.
--       - An is_notified BOOLEAN on an incident, with no row representing the obligation, made
--         notification something a developer had to remember. They did not.
--
--     Hence the governing principle of this file:
--
--         IF A RULE MATTERS, GIVE IT A ROW, A CONSTRAINT OR A TRIGGER.
--         A rule that lives only in a developer's memory of the spec will be missing from the code,
--         and nothing will notice.
--
-- ---------------------------------------------------------------------------------------------------------
-- WHAT CHANGED FROM v2.0
-- ---------------------------------------------------------------------------------------------------------
--     Additive. No table dropped, no column dropped, no rename. 16 tables -> 29.
--
--     NEW TABLES (13)
--       ba_comment_bank                 Reusable remark templates (BRD v2 sec.32 described it; nothing stored it)
--       ba_class_scale_jnt              Optional per-class rating-scale override            (Decision D-02)
--       ba_framework_snapshots          Freezes the framework when a period locks           (Decision D-07)
--       ba_assessment_status_history    Who moved this, when, and why                       (REQ-BA-022)
--       ba_audit_log_archive            Archival without deletion                           (BR-BA-093)
--       ba_computed_overall             Overall score gets its own row, not "the first category row"
--       ba_score_runs                   Computation provenance                              (BR-BA-063)
--       ba_incident_attachments         Relational evidence, replacing attachments_json     (REQ-BA-024)
--       ba_incident_followups           Append-only follow-up log                           (REQ-BA-025)
--       ba_intervention_progress        Append-only intervention progress log               (BR-BA-081)
--       ba_notifications                The notification OUTBOX                             (REQ-BA-017)
--       ba_report_exports               Export = disclosure event                           (BR-BA-087/096)
--       ba_behaviour_points             Optional incident->standing ledger, OFF by default  (Decision D-09)
--
--     CORRECTED IN EXISTING TABLES
--       1.  created_by / updated_by were BIGINT UNSIGNED. sys_users.id is INT UNSIGNED.
--           The columns were four bytes wider than the values they held and could not be constrained.
--           -> INT UNSIGNED, with a real foreign key to sys_users on created_by. updated_by is
--              corrected in type but left unconstrained: a second FK per table would double the
--              index count across 29 tables to answer a question nothing asks. ba_audit_log is
--              exempted entirely — see the note on that table.
--       2.  Soft-delete + UNIQUE produced 500s (DATA-BA-004): a soft-deleted row blocked re-creation.
--           -> deleted_at is DATETIME(6), plus a generated uq_guard column in every affected UNIQUE key.
--              See "SOFT DELETION AND UNIQUENESS" below. This is not cosmetic.
--       3.  Multiple rating scales could be is_default=1 (BR-BA-028 unenforced).
--           -> generated is_default_flag + UNIQUE key. Declarative, not convention.
--       4.  A scale's numeric shape could change after ratings existed (BR-BA-029 unenforced).
--           -> is_locked + trigger.
--       5.  Period FSM was inverted: open->locked was allowed, locked->closed was allowed, and no
--           close() existed so open->closed was unreachable (BUG-BA-002).
--           -> trg_ba_period_status_bu enumerates the legal transitions.
--       6.  Period lock did not cascade (BUG-BA-001).
--           -> lock is enforced WHERE THE WRITE HAPPENS: trg_ba_rating_biu reads the parent
--              assessment and period. That is the difference from v2.
--       7.  Witnesses had no column for a statement, while the BRD specified length limits and an
--              access rule for statement text. The requirement had nowhere to live.
--           -> statement, statement_recorded_by/at, is_confidential, frozen_at.
--       8.  Applied interventions stored a note and nothing else — no owner, no due date, no status.
--           -> full case-management columns (Decision D-01).
--       9.  Incidents had no lifecycle. The module recorded that something happened and never
--              recorded that anything was done.
--           -> status FSM, resolution and closure columns (Decision D-06).
--      10.  follow_up_notes was a single TEXT column that each new note overwrote (BUG-BA-009).
--           -> ba_incident_followups, insert-only.
--      11.  attachments_json could not be indexed, counted, or permission-checked per file.
--           -> ba_incident_attachments.
--      12.  overall_score was stored "on the first category row per student-period". That depends on
--              row ordering and breaks when a category is deactivated.
--           -> ba_computed_overall with UNIQUE(student_id, period_id).
--      13.  A rating pointed at a level; deleting the level set it NULL and the rating silently became
--              "not rated" — a locked, published assessment lost data.
--           -> ratings store rating_value, the number they meant  (BR-BA-057).
--      14.  Negative-polarity inversion was (max + 1) - raw. That is only correct for 1-based scales.
--           -> (max + min) - raw. Identical for every 1-based scale, so NO existing school's numbers
--              change; correct for 0-based and 2-based scales. Documented at ba_categories.
--      15.  ba_config held 5 settings while the screens described ~35 policy decisions.
--           -> grouped policy record. Every analytical threshold is a PERCENTAGE OF SCALE RANGE,
--              never an absolute like 2.5 or 1.20, so policy survives a change of scale (BR-BA-048).
--      16.  Audit covered 3 entity types; configuration, framework, period and export activity were
--              expected to be discoverable and were not recorded at all.
--           -> 10 entity types, plus ip_address, user_agent and reason.
--
-- ---------------------------------------------------------------------------------------------------------
-- TABLE PREFIX — ba_, NOT bha_
-- ---------------------------------------------------------------------------------------------------------
--     The live tenant migrations, all 16 Eloquent models and the 24 v1 screen specs use ba_.
--     Only 2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql uses bha_, and the 2026-06-29
--     verification already ruled that document stale. It should be RETIRED — it is the only artefact
--     in the repository that sends an auditor looking for tables that do not exist.
--
-- ---------------------------------------------------------------------------------------------------------
-- SOFT DELETION AND UNIQUENESS  (Solution_Design_v2 sec.3.4 — the pattern used throughout)
-- ---------------------------------------------------------------------------------------------------------
--     PROBLEM. A class-category mapping is soft-deleted. The admin re-creates it.
--     UNIQUE(class_id, category_id) rejects the insert: the deleted row is still physically there.
--
--     WRONG FIX 1 — add deleted_at to the key. MySQL treats every NULL as distinct in a unique index,
--     so EVERY LIVE ROW BECOMES UNIQUE regardless of its natural key. The constraint silently stops
--     enforcing anything. Worse than the bug, because nothing fails.
--
--     WRONG FIX 2 — drop the constraint, check in code. Two concurrent requests both pass and insert.
--
--     THE PATTERN:
--         `deleted_at` DATETIME(6) NULL DEFAULT NULL,
--         `uq_guard`   DATETIME(6) GENERATED ALWAYS AS
--                        (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
--         UNIQUE KEY (`natural`, `key`, `uq_guard`)
--
--     Every live row carries the same sentinel, so the natural key is enforced among live rows exactly
--     as intended. Every deleted row carries its own deletion instant, so any number of deleted rows
--     may share the natural key.
--
--     WHY DATETIME(6) AND NOT TIMESTAMP:
--       - microsecond precision removes the case where two soft-deletes of the same natural key inside
--         one second would collide;
--       - a TIMESTAMP -> DATETIME conversion is time-zone dependent, which MySQL rejects in a STORED
--         generated column;
--       - TIMESTAMP cannot represent '1970-01-01 00:00:00' (that is its zero value), so the sentinel
--         would be invalid.
--     Applied to ALL ba_* tables, not only those with unique keys, so a developer never has to check
--     which convention a given table follows. created_at / updated_at remain TIMESTAMP.
--
--     THE EXCEPTIONS, and why: eight tables carry NO deleted_at at all, because they are insert-only
--     or append-only by design and a soft delete would be a way of unsaying something that was said:
--         ba_audit_log, ba_audit_log_archive, ba_framework_snapshots, ba_assessment_status_history,
--         ba_incident_followups, ba_intervention_progress, ba_score_runs, ba_behaviour_points.
--     Their UPDATE and DELETE paths are closed by triggers in Section 20.
--
-- ---------------------------------------------------------------------------------------------------------
-- KEY TYPE DISCIPLINE  (verified against the tenant DDL — do not "tidy" these)
-- ---------------------------------------------------------------------------------------------------------
--     +-------------------------------------+------------------+-------------------------------------+
--     | Referenced table                    | PK type          | BA columns                          |
--     +-------------------------------------+------------------+-------------------------------------+
--     | std_students                        | INT UNSIGNED     | student_id, witness_id (student)    |
--     | sch_employees                       | INT UNSIGNED     | teacher_id, reviewed_by, reported_by|
--     |                                     |                  | assigned_to, witness_id (staff)     |
--     | sch_class_section_jnt               | INT UNSIGNED     | class_section_id                    |
--     | sch_classes                         | INT UNSIGNED     | class_id                            |
--     | sch_subjects                        | INT UNSIGNED     | subject_id                          |
--     | sch_org_academic_sessions_jnt       | SMALLINT UNSIGNED| academic_session_id                 |
--     | sch_academic_term                   | SMALLINT UNSIGNED| academic_term_id                    |
--     | sys_users                           | INT UNSIGNED     | created_by, updated_by, changed_by  |
--     +-------------------------------------+------------------+-------------------------------------+
--     ba_* primary keys stay BIGINT UNSIGNED: ba_assessment_ratings alone reaches ~460,000 rows per
--     session, and a multi-year tenant will pass the INT range on audit rows.
--
-- ---------------------------------------------------------------------------------------------------------
-- ENFORCEMENT MODEL — where each kind of rule lives
-- ---------------------------------------------------------------------------------------------------------
--     DATABASE  (CHECK / UNIQUE / FK / TRIGGER)  Invariants. Never true, regardless of who is asking.
--                                                "Negative incidents have severity."
--                                                "Locked assessments do not change."
--                                                "Audit rows are not updated."
--     SERVICE                                    Workflow and permission. Depends on actor and config.
--                                                "Who may reopen a period." "Is review required."
--     FORMREQUEST                                Shape and range of input.
--     POLICY                                     Authorisation.
--
--     Service checks run FIRST so users get clean messages. The database is the backstop, not the
--     user experience — but it is the backstop that a console command, a queued job, a seeder, a
--     data-fix script and a future developer are all equally bound by.
--
-- ---------------------------------------------------------------------------------------------------------
-- SECTIONS OF THIS FILE
-- ---------------------------------------------------------------------------------------------------------
--      1  Layer 1 — Foundation masters       ba_rating_scales, ba_categories, ba_interventions,
--                                            ba_comment_bank
--      2  Layer 2 — Master detail            ba_rating_levels, ba_criteria
--      3  Layer 3 — Setup and applicability  ba_class_category_jnt, ba_class_scale_jnt,
--                                            ba_assessment_periods, ba_config, ba_framework_snapshots
--      4  Layer 4 — Workflow headers         ba_assessments, ba_assessment_status_history,
--                                            ba_audit_log, ba_audit_log_archive
--      5  Layer 5 — Core transactions        ba_assessment_ratings, ba_student_remarks,
--                                            ba_computed_scores, ba_computed_overall,
--                                            ba_score_runs, ba_incidents
--      6  Layer 6 — Incident detail          ba_incident_witnesses_jnt, ba_incident_intervention_jnt,
--                                            ba_incident_attachments, ba_incident_followups,
--                                            ba_intervention_progress
--      7  Layer 7 — Operations               ba_notifications, ba_report_exports, ba_behaviour_points
--      8  Deferred foreign keys (circular references)
--      9  Views
--     10  Seed data
--     20  Integrity triggers  — SEE THE NOTE AT THAT SECTION BEFORE OMITTING IT
-- =========================================================================================================

SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';
SET FOREIGN_KEY_CHECKS = 0;


-- =========================================================================================================
-- SECTION 1 — LAYER 1: FOUNDATION MASTERS
-- No dependency on any other ba_* table.
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 1: ba_rating_scales
-- ---------------------------------------------------------------------------------------------------------
-- The measurement instrument. A scale is an ordered set of levels (ba_rating_levels) with labels and
-- numeric values. One scale is active per academic session (ba_config.rating_scale_id); a class may
-- override it (ba_class_scale_jnt) so Grades 1-2 can use a 3-point scale while Grades 6-12 use 5-point.
--
-- min_rating / max_rating drive three things:
--   (a) normalisation to a 0-100 range for report-card integration;
--   (b) negative-polarity inversion:  inverted = (max + min) - raw     <-- see ba_categories
--   (c) validation that every level's numeric_value falls inside the scale.
--
-- TWO v7.0 CORRECTIONS
--   is_default_flag  Generated column + UNIQUE. In v2 nothing stopped two scales both being default
--                    (BR-BA-028 was assessed as unenforced). This makes it structurally impossible
--                    rather than a rule someone has to remember.
--   is_locked        A scale becomes locked the first time a rating references one of its levels.
--                    From then on min_rating, max_rating and every level's numeric_value are frozen
--                    (BR-BA-029). Labels and descriptions stay editable — renaming "Good" to "Meets
--                    Expectations" changes no arithmetic. Enforced by trg_ba_scale_locked_bu.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_rating_scales` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`            VARCHAR(30)     NOT NULL                COMMENT 'Machine identifier, e.g. 5_POINT, 3_POINT',
  `name`            VARCHAR(100)    NOT NULL                COMMENT 'e.g. "5-Point Behavioural Scale"',
  `description`     TEXT            DEFAULT NULL,
  `grade_type`      ENUM('letter','numeric','descriptive') NOT NULL DEFAULT 'letter'
                                                            COMMENT 'How the UI renders a mapped grade',
  `min_rating`      DECIMAL(4,2)    NOT NULL                COMMENT 'Lowest value on the scale, e.g. 1.00',
  `max_rating`      DECIMAL(4,2)    NOT NULL                COMMENT 'Highest value on the scale, e.g. 5.00',
  `is_default`      TINYINT(1)      NOT NULL DEFAULT 0      COMMENT 'The school preferred scale',
  `is_locked`       TINYINT(1)      NOT NULL DEFAULT 0      COMMENT 'v7.0 BR-BA-029 — set once ratings exist; numeric shape frozen',
  `locked_at`       TIMESTAMP       NULL DEFAULT NULL,
  `is_active`       TINYINT(1)      NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED    NOT NULL                COMMENT 'FK sys_users.id (v7.0: was BIGINT)',
  `updated_by`      INT UNSIGNED    NOT NULL                COMMENT 'FK sys_users.id (v7.0: was BIGINT)',
  `created_at`      TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`      DATETIME(6)     NULL DEFAULT NULL,
  `uq_guard`        DATETIME(6)     GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  `is_default_flag` TINYINT UNSIGNED GENERATED ALWAYS AS
                      (CASE WHEN `is_default` = 1 AND `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED
                                                            COMMENT 'v7.0 BR-BA-028 — at most one default, enforced by UNIQUE',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_scale_code`    (`code`, `uq_guard`),
  UNIQUE KEY `uq_ba_scale_default` (`is_default_flag`),
  KEY `idx_ba_scale_active` (`is_active`),
  CONSTRAINT `fk_ba_scale_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_scale_range` CHECK (`max_rating` > `min_rating` AND `min_rating` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Rating scales. is_locked freezes the numeric shape once ratings exist (BR-BA-029).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 2: ba_categories
-- ---------------------------------------------------------------------------------------------------------
-- Broad behavioural domains. 9 are seeded: 5 positive, 4 negative.
--
-- POLARITY AND THE INVERSION FORMULA  (v7.0 correction — BR-BA-007)
--
--   Positive categories: a higher rating is better.
--   Negative categories: the raw value is inverted so direction stays consistent framework-wide:
--
--        inverted = (scale.max_rating + scale.min_rating) - raw
--
--   v2.0 and BRD v2 both said (max + 1) - raw. That is only correct when min_rating = 1.
--
--        scale 1-5, raw 5 :  old 6-5 = 1   new 6-5 = 1     both correct
--        scale 0-4, raw 4 :  old 5-4 = 1   new 4-4 = 0     OLD WRONG — worst rating scored 1, so
--                                                          negative categories sat a point above
--                                                          positive ones for the whole school
--        scale 2-6, raw 6 :  old 7-6 = 1   new 8-6 = 2     OLD WRONG — result fell below the minimum
--
--   Every 1-based scale reduces to the old formula, so NO EXISTING SCHOOL'S NUMBERS CHANGE.
--   This is a latent defect fix, not a policy change.
--
-- WEIGHTING (BR-BA-036). Weights are PROPORTIONAL and normalised at computation:
--        contribution = score x (weight / SUM of applicable weights)
--   They need not total 100. The UI shows both the entered weight and its effective percentage, so an
--   administrator can see that four categories at 100 each are 25% apiece. The engine must never
--   depend on an administrator keeping a running total correct.
--
-- HIERARCHY (BR-BA-034/035). At most two levels: parent -> child. Criteria attach only to LEAF
--   categories. Deeper trees make weighting unexplainable to the teachers who have to use it.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_categories` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_id`   BIGINT UNSIGNED DEFAULT NULL              COMMENT 'Self-reference; NULL = top level. Max depth 2 (BR-BA-034)',
  `code`        VARCHAR(30)     NOT NULL                  COMMENT 'v7.0 — stable identifier, e.g. CLS_ENG',
  `name`        VARCHAR(100)    NOT NULL,
  `description` TEXT            DEFAULT NULL,
  `polarity`    ENUM('positive','negative') NOT NULL      COMMENT 'negative categories are inverted at computation',
  `weight`      DECIMAL(5,2)    NOT NULL DEFAULT 100.00   COMMENT 'Proportional; normalised at computation (BR-BA-036)',
  `sort_order`  SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_system`   TINYINT(1)      NOT NULL DEFAULT 0        COMMENT 'v7.0 — seeded categories are protected from deletion',
  `is_active`   TINYINT(1)      NOT NULL DEFAULT 1,
  `created_by`  INT UNSIGNED    NOT NULL,
  `updated_by`  INT UNSIGNED    NOT NULL,
  `created_at`  TIMESTAMP       NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP       NULL DEFAULT NULL,
  `deleted_at`  DATETIME(6)     NULL DEFAULT NULL,
  `uq_guard`    DATETIME(6)     GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_cat_code` (`code`, `uq_guard`),
  KEY `idx_ba_cat_parent`   (`parent_id`),
  KEY `idx_ba_cat_polarity` (`polarity`),
  KEY `idx_ba_cat_active`   (`is_active`, `sort_order`),
  CONSTRAINT `fk_ba_cat_parent`  FOREIGN KEY (`parent_id`)  REFERENCES `ba_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ba_cat_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_cat_weight` CHECK (`weight` >= 0 AND `weight` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Behavioural categories. Negative polarity inverts as (max+min)-raw (BR-BA-007).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 3: ba_interventions
-- ---------------------------------------------------------------------------------------------------------
-- Master list of actions a school can take in response to an incident.
--
-- CANONICAL TYPES: reward | corrective | counselling.
--   The v1 screens used "Reinforcement" and "Supportive". Those are DISPLAY ALIASES, not separate
--   types (BRD D-05 reasoning applied to intervention vocabulary). Two vocabularies in one product
--   guarantee mismatched thresholds and unusable exports.
--
-- v7.0 ADDITIONS that make case management possible (Decision D-01):
--   default_due_days        seeds scheduled_date = incident_date + this
--   requires_owner          when 1, assigned_to is mandatory on application
--   requires_parent_meeting drives the parent-notification obligation
--
-- BR-BA-037: a reward may only be applied to a positive incident, a corrective only to a negative one.
--            Counselling applies to either. Enforced in BaInterventionService.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_interventions` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                    VARCHAR(30)  NOT NULL             COMMENT 'v7.0 — stable identifier, e.g. WRITTEN_WARN',
  `name`                    VARCHAR(100) NOT NULL,
  `description`             TEXT         DEFAULT NULL,
  `intervention_type`       ENUM('reward','corrective','counselling') NOT NULL,
  `default_due_days`        SMALLINT UNSIGNED NOT NULL DEFAULT 7  COMMENT 'v7.0 — seeds scheduled_date',
  `requires_owner`          TINYINT(1)   NOT NULL DEFAULT 1    COMMENT 'v7.0 — assigned_to mandatory when 1',
  `requires_parent_meeting` TINYINT(1)   NOT NULL DEFAULT 0    COMMENT 'v7.0 — raises a parent obligation',
  `sort_order`              SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_system`               TINYINT(1)   NOT NULL DEFAULT 0,
  `is_active`               TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`              INT UNSIGNED NOT NULL,
  `updated_by`              INT UNSIGNED NOT NULL,
  `created_at`              TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`              DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`                DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_interv_code` (`code`, `uq_guard`),
  KEY `idx_ba_interv_type` (`intervention_type`, `is_active`),
  CONSTRAINT `fk_ba_interv_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Intervention master. default_due_days and requires_owner drive case management (D-01).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 4: ba_comment_bank                                                        [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Reusable narrative templates for criterion and overall remarks.
--
-- BRD v2 sec.32 described the Comment Bank in detail and no table anywhere stored one, so the feature
-- could not be built. This is that table.
--
-- BR-BA-038 — INSERT, THEN OWN. A template is a starting point. The inserted text is fully editable
--   and is stored as the teacher's own words. template_id is recorded on nothing; usage_count here is
--   incremented for analytics only. The point is consistent professional language, not identical
--   comments on thirty report cards.
--
-- BR-BA-039 — PLACEHOLDERS. {student} resolves to the preferred/first name at insertion.
--   {he_she} / {him_her} / {his_her} resolve from StudentProfile. Where gender is unrecorded or "Prefer not to
--   say", the NEUTRAL form (they / their) is used — a wrong guess misgenders a real child on a
--   document their parents will read.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_comment_bank` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id`   BIGINT UNSIGNED DEFAULT NULL          COMMENT 'Optional scope to a behavioural domain',
  `code`          VARCHAR(40)  NOT NULL,
  `sentiment`     ENUM('positive','neutral','developmental') NOT NULL,
  `applies_to`    ENUM('criterion_remark','overall_remark','both') NOT NULL DEFAULT 'both',
  `template_text` VARCHAR(1000) NOT NULL               COMMENT 'May contain {student}, {he_she}, {him_her}, {his_her}',
  `usage_count`   INT UNSIGNED NOT NULL DEFAULT 0      COMMENT 'Analytics only — never affects output',
  `sort_order`    SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_system`     TINYINT(1)   NOT NULL DEFAULT 0,
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NOT NULL,
  `updated_by`    INT UNSIGNED NOT NULL,
  `created_at`    TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`    TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`    DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`      DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_comment_code` (`code`, `uq_guard`),
  KEY `idx_ba_comment_cat`  (`category_id`, `is_active`),
  KEY `idx_ba_comment_sent` (`sentiment`, `applies_to`),
  CONSTRAINT `fk_ba_comment_cat`     FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ba_comment_created` FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_comment_len` CHECK (CHAR_LENGTH(`template_text`) >= 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reusable remark templates. BRD v2 sec.32 specified this feature and nothing stored it.';


-- =========================================================================================================
-- SECTION 2 — LAYER 2: MASTER DETAIL
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 5: ba_rating_levels
-- ---------------------------------------------------------------------------------------------------------
-- The ordered levels within a scale. sort_order = 1 is the LOWEST (worst).
--
-- numeric_value is the raw number that feeds computation. It must lie inside the parent scale's
-- [min_rating, max_rating] range — a CHECK constraint cannot express that because it would have to
-- read another row, so trg_ba_level_range_bi/bu enforces it (BR-BA-027, audit finding VAL-BA-002).
--
-- BR-BA-033: label and numeric_value are each unique within a scale. Two levels called "Good", or two
-- levels both worth 3.0, make a grid ambiguous to the teacher and the average meaningless.
--
-- 5-Point seed:  1 Unsatisfactory 1.0 | 2 Needs Improvement 2.0 | 3 Good 3.0 | 4 Very Good 4.0 |
--                5 Outstanding 5.0
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_rating_levels` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `rating_scale_id` BIGINT UNSIGNED NOT NULL,
  `label`           VARCHAR(50)  NOT NULL              COMMENT 'e.g. "Outstanding"',
  `numeric_value`   DECIMAL(4,2) NOT NULL              COMMENT 'Must fall inside the parent scale range',
  `description`     VARCHAR(255) DEFAULT NULL,
  `grade_label`     VARCHAR(5)   DEFAULT NULL          COMMENT 'v7.0 — optional report-card band, e.g. A+',
  `sort_order`      TINYINT UNSIGNED NOT NULL          COMMENT '1 = lowest',
  `is_active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED NOT NULL,
  `updated_by`      INT UNSIGNED NOT NULL,
  `created_at`      TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`      DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`        DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_level_order` (`rating_scale_id`, `sort_order`,    `uq_guard`),
  UNIQUE KEY `uq_ba_level_label` (`rating_scale_id`, `label`,         `uq_guard`),
  UNIQUE KEY `uq_ba_level_value` (`rating_scale_id`, `numeric_value`, `uq_guard`),
  KEY `idx_ba_level_scale` (`rating_scale_id`, `is_active`),
  CONSTRAINT `fk_ba_level_scale`   FOREIGN KEY (`rating_scale_id`) REFERENCES `ba_rating_scales` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_level_created` FOREIGN KEY (`created_by`)      REFERENCES `sys_users` (`id`)        ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_level_value` CHECK (`numeric_value` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Ordered levels within a scale. Range validated by trigger (BR-BA-027).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 6: ba_criteria
-- ---------------------------------------------------------------------------------------------------------
-- Observable behaviours within a category. 58 are seeded across the 9 default categories.
--
-- NO PER-CRITERION max_score. The v1 screen spec proposed one; it is REJECTED (Decision D-11).
-- The rating range belongs to the SCALE. A per-criterion maximum would let two columns of the same
-- grid use different ranges, which teachers cannot reason about and which breaks averaging. A
-- criterion's influence is expressed through its WEIGHT.
--
-- min_coverage_percent (v7.0, BR-BA-061): if fewer than this proportion of a category's applicable
-- criteria are rated, the category score is recorded as insufficient rather than as a number. A
-- category score derived from one criterion out of eight is not a measurement. Stored on the category
-- side of the relationship would be equally valid; it is here so a school can relax it for a category
-- with a single criterion.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_criteria` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` BIGINT UNSIGNED NOT NULL,
  `code`        VARCHAR(30)  NOT NULL                COMMENT 'v7.0 — unique within the category',
  `name`        VARCHAR(255) NOT NULL                COMMENT 'The observable behaviour',
  `description` TEXT         DEFAULT NULL,
  `weight`      DECIMAL(5,2) NOT NULL DEFAULT 0.00   COMMENT 'Proportional within the category',
  `sort_order`  SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `is_system`   TINYINT(1)   NOT NULL DEFAULT 0,
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`  INT UNSIGNED NOT NULL,
  `updated_by`  INT UNSIGNED NOT NULL,
  `created_at`  TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`  DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`    DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_criteria_code` (`category_id`, `code`, `uq_guard`),
  KEY `idx_ba_criteria_cat` (`category_id`, `is_active`, `sort_order`),
  CONSTRAINT `fk_ba_criteria_cat`     FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_criteria_created` FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_criteria_weight` CHECK (`weight` >= 0 AND `weight` <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Observable criteria. Range comes from the scale, never from the criterion (D-11).';


-- =========================================================================================================
-- SECTION 3 — LAYER 3: SETUP AND APPLICABILITY
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 7: ba_class_category_jnt
-- ---------------------------------------------------------------------------------------------------------
-- Which behavioural categories apply to which class, so a Grade 1 grid does not contain
-- "Academic Misconduct".
--
-- Maps to sch_classes (the grade level), NOT sch_class_groups_jnt (a subject+study-format junction
-- used by Timetable). Getting this wrong was a documented earlier confusion.
--
-- BR-BA-009 — PERMISSIVE FALLBACK. If a class has NO mappings at all, ALL active categories apply.
--   This is deliberate: a school that has not configured mapping yet must still be able to assess.
--   The audit found this fallback missing, which produced empty grids and blocked teachers entirely.
--   Once a class has at least one mapping, only mapped categories apply. The distinction between
--   "no rows" and "some rows" is the whole rule — do not "helpfully" seed a row per class.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_class_category_jnt` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `class_id`    INT UNSIGNED    NOT NULL              COMMENT 'FK sch_classes.id — cross-module, read-only',
  `category_id` BIGINT UNSIGNED NOT NULL,
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`  INT UNSIGNED NOT NULL,
  `updated_by`  INT UNSIGNED NOT NULL,
  `created_at`  TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`  TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`  DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`    DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_class_cat` (`class_id`, `category_id`, `uq_guard`),
  KEY `idx_ba_cc_class` (`class_id`, `is_active`),
  KEY `idx_ba_cc_cat`   (`category_id`),
  CONSTRAINT `fk_ba_cc_class`   FOREIGN KEY (`class_id`)    REFERENCES `sch_classes` (`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_ba_cc_cat`     FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_cc_created` FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Category applicability per class. No rows for a class => all categories apply (BR-BA-009).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 8: ba_class_scale_jnt                                                     [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Optional per-class override of the session's rating scale.  Decision D-02.
--
-- BRD v2 sec.104 asked: one scale per session, or a scale per class? The answer is BOTH, layered.
--   - A single session-level scale suits most schools and keeps cross-class comparison meaningful.
--   - A Montessori-style 3-point scale for Grades 1-2 alongside a 5-point scale for Grades 6-12 is a
--     real requirement in Indian K-12 and cannot be expressed with one session-level column.
--
-- Making the override OPTIONAL means the simple case stays simple: this table is empty in most
-- tenants, and resolution falls through to ba_config.rating_scale_id.
--
--     effective_scale(class) := ba_class_scale_jnt[class] ?? ba_config[session].rating_scale_id
--
-- CONSEQUENCE for reporting: overall scores from two different scales are NOT directly comparable.
-- Any cross-class report must normalise to 0-100 first. v_ba_student_period_scores exposes both the
-- raw score and the scale bounds so a report can normalise without a second lookup.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_class_scale_jnt` (
  `id`                  BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL          COMMENT 'FK sch_org_academic_sessions_jnt.id',
  `class_id`            INT UNSIGNED      NOT NULL          COMMENT 'FK sch_classes.id',
  `rating_scale_id`     BIGINT UNSIGNED   NOT NULL          COMMENT 'Overrides ba_config for this class',
  `reason`              VARCHAR(255)      DEFAULT NULL      COMMENT 'Why this class differs — shown in Configuration',
  `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED NOT NULL,
  `created_at`          TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`          DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`            DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_class_scale` (`academic_session_id`, `class_id`, `uq_guard`),
  KEY `idx_ba_cs_scale` (`rating_scale_id`),
  CONSTRAINT `fk_ba_cs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_cs_class`   FOREIGN KEY (`class_id`)            REFERENCES `sch_classes` (`id`)                   ON DELETE CASCADE,
  CONSTRAINT `fk_ba_cs_scale`   FOREIGN KEY (`rating_scale_id`)     REFERENCES `ba_rating_scales` (`id`)              ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_cs_created` FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`)                     ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Optional per-class scale override. Usually empty; falls through to ba_config (D-02).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 9: ba_assessment_periods
-- ---------------------------------------------------------------------------------------------------------
-- The data-entry windows. "Term 1 Assessment", "Monthly - August", "Annual".
--
-- LIFECYCLE (BR-BA-044). The legal transitions, and only these:
--
--          +--------------- reopen() ---------------+
--          v                                        |
--       [OPEN] ---- close() ----> [CLOSED] ---- lock() ----> [LOCKED]   terminal
--
--       open -> locked    REJECTED. A period must be closed before it is locked.
--       locked -> *       REJECTED. Terminal.
--
--   v2.0 shipped the inverse of this: open->locked was allowed, locked->closed was allowed, and no
--   close() action existed at all, so open->closed was unreachable (audit BUG-BA-002). The table above
--   is now normative and is enforced by trg_ba_period_status_bu — a SIGNAL, not a code comment.
--
-- LOCKING CASCADES (BR-BA-045). BaPeriodService::lock() sets every reviewed assessment to locked and
--   seals a framework snapshot. Ratings need no update: trg_ba_rating_biu reads the parent assessment
--   and this period on every write. THE LOCK IS ENFORCED WHERE THE WRITE HAPPENS, not where the lock
--   is set. That single change is what fixes BUG-BA-001.
--
-- snapshot_id points at the framework frozen for this period. The FK is added in Section 8 because
--   ba_framework_snapshots also references this table.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_assessment_periods` (
  `id`                  BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL         COMMENT 'FK sch_org_academic_sessions_jnt.id',
  `academic_term_id`    SMALLINT UNSIGNED DEFAULT NULL     COMMENT 'FK sch_academic_term.id — NULL = independent cycle',
  `name`                VARCHAR(100) NOT NULL,
  `start_date`          DATE         NOT NULL,
  `end_date`            DATE         NOT NULL,
  `deadline`            DATE         NOT NULL              COMMENT 'Teacher submission deadline; >= end_date',
  `status`              ENUM('open','closed','locked') NOT NULL DEFAULT 'open',
  `closed_by`           INT UNSIGNED DEFAULT NULL          COMMENT 'v7.0 — FK sch_employees.id',
  `closed_at`           TIMESTAMP    NULL DEFAULT NULL,
  `locked_by`           INT UNSIGNED DEFAULT NULL          COMMENT 'v7.0 — FK sch_employees.id',
  `locked_at`           TIMESTAMP    NULL DEFAULT NULL,
  `reopen_count`        SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v7.0 — a reopened period is an exception worth counting',
  `snapshot_id`         BIGINT UNSIGNED DEFAULT NULL       COMMENT 'v7.0 — frozen framework; FK added in Section 8',
  `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED NOT NULL,
  `created_at`          TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`          DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`            DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_period_name` (`academic_session_id`, `name`, `uq_guard`),
  KEY `idx_ba_period_session` (`academic_session_id`, `status`),
  KEY `idx_ba_period_term`    (`academic_term_id`),
  KEY `idx_ba_period_dates`   (`start_date`, `end_date`),
  CONSTRAINT `fk_ba_period_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_period_term`    FOREIGN KEY (`academic_term_id`)    REFERENCES `sch_academic_term` (`id`)             ON DELETE SET NULL,
  CONSTRAINT `fk_ba_period_closed`  FOREIGN KEY (`closed_by`)           REFERENCES `sch_employees` (`id`)                 ON DELETE SET NULL,
  CONSTRAINT `fk_ba_period_locked`  FOREIGN KEY (`locked_by`)           REFERENCES `sch_employees` (`id`)                 ON DELETE SET NULL,
  CONSTRAINT `fk_ba_period_created` FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`)                     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_period_dates`    CHECK (`end_date` >= `start_date`),
  CONSTRAINT `chk_ba_period_deadline` CHECK (`deadline`  >= `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Assessment windows. FSM open<->closed->locked enforced by trigger (BR-BA-044, BUG-BA-002).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 10: ba_config
-- ---------------------------------------------------------------------------------------------------------
-- One row per academic session. v2.0 held 5 settings; the screens described roughly 35 policy
-- decisions, most of which were therefore hard-coded somewhere or simply absent.
--
-- WHY EVERY ANALYTICAL THRESHOLD IS A PERCENTAGE  (BR-BA-048)
--   BRD v2 proposed at-risk below 2.5/5 and a consistency warning above an SD of 1.20. Both are
--   5-point constants. On a 3-point scale, 2.5 flags almost nobody; on a 10-point scale it flags
--   almost everybody. Stored as a PERCENTAGE OF SCALE RANGE, the same POLICY travels across scales:
--
--       score threshold : absolute = scale.min + (percent/100) x (scale.max - scale.min)
--       delta / spread  : absolute =              (percent/100) x (scale.max - scale.min)
--
--   The defaults below reproduce the familiar 5-point behaviour EXACTLY:
--       at_risk_score_percent  50.0  ->  1 + 0.50 x 4 = 3.00 ... set to 37.5 for the classic 2.5
--       trend_improve_percent   7.5  ->        0.075 x 4 = 0.30
--       trend_stable_percent    5.0  ->        0.050 x 4 = 0.20
--       consistency_sd_percent 30.0  ->        0.300 x 4 = 1.20
--   at_risk_score_percent defaults to 37.5 precisely so that a 1-5 school sees the 2.5 it expects.
--
-- FEATURE FLAGS. is_review_required and auto_lock_on_approval implement Decisions D-04 and D-03.
--   BR-BA-025 (publish on submit when there is no HOD layer) was assessed as MISSING with no config
--   flag and no branch anywhere in the code. It now has both.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_config` (
  `id`                              BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `academic_session_id`             SMALLINT UNSIGNED NOT NULL,
  `rating_scale_id`                 BIGINT UNSIGNED   NOT NULL   COMMENT 'Session default; ba_class_scale_jnt may override',

  -- ---- Workflow -----------------------------------------------------------------------------------
  `is_review_required`              TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'v7.0 D-04 BR-BA-025 — 0 => submit() goes straight to reviewed',
  `auto_lock_on_approval`           TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'v7.0 D-03 — one UI action, still two recorded events',
  `autosave_interval_seconds`       SMALLINT UNSIGNED NOT NULL DEFAULT 30,
  `min_coverage_percent`            DECIMAL(5,2) NOT NULL DEFAULT 50.00 COMMENT 'v7.0 BR-BA-061 — below this a category reports insufficient data',

  -- ---- Scoring ------------------------------------------------------------------------------------
  `aggregation_method`              ENUM('average','weighted_average','separate_display') NOT NULL DEFAULT 'weighted_average',
  `normalisation_base`              DECIMAL(6,2) NOT NULL DEFAULT 100.00 COMMENT 'Scale to which scores normalise for integration',

  -- ---- Result integration -------------------------------------------------------------------------
  `is_result_integration_enabled`   TINYINT(1)   NOT NULL DEFAULT 0  COMMENT 'OFF by default (BR-BA-023)',
  `weightage_percent`               DECIMAL(4,1) NOT NULL DEFAULT 10.0 COMMENT '5.0-20.0 when integration is enabled',

  -- ---- Notification -------------------------------------------------------------------------------
  `parent_notification_threshold`   ENUM('minor','moderate','major','critical') NOT NULL DEFAULT 'moderate',
  `notify_parent`                   TINYINT(1) NOT NULL DEFAULT 1,
  `notify_class_teacher`            TINYINT(1) NOT NULL DEFAULT 1,
  `notify_hod`                      TINYINT(1) NOT NULL DEFAULT 0,
  `notify_principal`                TINYINT(1) NOT NULL DEFAULT 0,
  `notify_positive_incidents`       TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'v7.0 — recognition should travel as readily as reprimand',
  `notification_channels_json`      JSON       DEFAULT NULL        COMMENT 'v7.0 e.g. ["in_app","email","sms"]',
  `principal_daily_digest`          TINYINT(1) NOT NULL DEFAULT 0,

  -- ---- Escalation (v7.0 — ENH-BA-001, REQ-BA-028) --------------------------------------------------
  `incident_escalation_count`       TINYINT UNSIGNED  NOT NULL DEFAULT 3  COMMENT 'N negative incidents ...',
  `incident_escalation_window_days` SMALLINT UNSIGNED NOT NULL DEFAULT 30 COMMENT '... within this rolling window triggers escalation',

  -- ---- Incident policy ----------------------------------------------------------------------------
  `incident_backdating_days`        TINYINT UNSIGNED  NOT NULL DEFAULT 7   COMMENT 'D-12 — default, not a hard rule; Admin may override with an audited reason',
  `incident_desc_min_length`        SMALLINT UNSIGNED NOT NULL DEFAULT 20,
  `incident_desc_max_length`        SMALLINT UNSIGNED NOT NULL DEFAULT 1000,
  `witness_stmt_min_length`         SMALLINT UNSIGNED NOT NULL DEFAULT 10,
  `witness_stmt_max_length`         SMALLINT UNSIGNED NOT NULL DEFAULT 500,
  `freeze_witness_on_closure`       TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'BR-BA-077',

  -- ---- Analytical thresholds — ALL AS PERCENT OF SCALE RANGE (BR-BA-048) ---------------------------
  `at_risk_score_percent`           DECIMAL(5,2) NOT NULL DEFAULT 37.50 COMMENT '= 2.50 on a 1-5 scale',
  `at_risk_incident_count`          TINYINT UNSIGNED NOT NULL DEFAULT 2,
  `trend_improve_percent`           DECIMAL(5,2) NOT NULL DEFAULT 7.50  COMMENT '= 0.30 on a 1-5 scale',
  `trend_stable_percent`            DECIMAL(5,2) NOT NULL DEFAULT 5.00  COMMENT '= 0.20 on a 1-5 scale',
  `consistency_sd_percent`          DECIMAL(5,2) NOT NULL DEFAULT 30.00 COMMENT '= 1.20 on a 1-5 scale',
  `max_trend_lines`                 TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Chart clutter limit on Period Progress',

  -- ---- Privacy and retention ----------------------------------------------------------------------
  `allowed_demographics_json`       JSON DEFAULT NULL           COMMENT 'v7.0 D-08 — NULL = demographic analytics disabled',
  `min_group_size_for_analytics`    TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Small-cell suppression',
  `audit_retention_months`          SMALLINT UNSIGNED NOT NULL DEFAULT 36 COMMENT 'D-13 — eligibility only; archival is an explicit action',

  -- ---- Features -----------------------------------------------------------------------------------
  `is_comment_bank_enabled`         TINYINT(1) NOT NULL DEFAULT 1,
  `is_behaviour_points_enabled`     TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'v7.0 D-09 — OFF. Incidents do not affect scores unless a school chooses it',

  -- ---- Performance --------------------------------------------------------------------------------
  `export_async_row_threshold`      INT UNSIGNED     NOT NULL DEFAULT 1000,
  `export_expiry_days`              SMALLINT UNSIGNED NOT NULL DEFAULT 7,

  `is_active`  TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED NOT NULL,
  `updated_by` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP    NULL DEFAULT NULL,
  `updated_at` TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at` DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`   DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_config_session` (`academic_session_id`, `uq_guard`),
  KEY `idx_ba_config_scale` (`rating_scale_id`),
  CONSTRAINT `fk_ba_config_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_config_scale`   FOREIGN KEY (`rating_scale_id`)     REFERENCES `ba_rating_scales` (`id`)              ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_config_created` FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`)                     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_config_weightage` CHECK (
        `weightage_percent` >= 0 AND `weightage_percent` <= 100
    AND (`is_result_integration_enabled` = 0
         OR (`weightage_percent` >= 5.0 AND `weightage_percent` <= 20.0))),
  CONSTRAINT `chk_ba_config_percents` CHECK (
        `at_risk_score_percent`  BETWEEN 0 AND 100
    AND `trend_improve_percent`  BETWEEN 0 AND 100
    AND `trend_stable_percent`   BETWEEN 0 AND 100
    AND `consistency_sd_percent` BETWEEN 0 AND 100
    AND `min_coverage_percent`   BETWEEN 0 AND 100),
  CONSTRAINT `chk_ba_config_escalation` CHECK (`incident_escalation_count` >= 1 AND `incident_escalation_window_days` >= 1),
  CONSTRAINT `chk_ba_config_desc_len`   CHECK (`incident_desc_max_length` > `incident_desc_min_length`),
  CONSTRAINT `chk_ba_config_stmt_len`   CHECK (`witness_stmt_max_length`  > `witness_stmt_min_length`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Per-session policy. Every analytical threshold is a percent of scale range (BR-BA-048).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 11: ba_framework_snapshots                                                [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- The frozen behavioural framework a locked period was scored against.   Decision D-07.
--
-- WHY THIS TABLE EXISTS
--   BRD v2 sec.98 called historical integrity "one of the most important requirements to address in the
--   next schema revision" and sec.108 left it as an open decision. Without it, an administrator
--   adjusting a category weight in March silently rewrites what a September report card MEANT. A
--   parent-facing historical grade must stay explainable, and "we changed the weights since then"
--   is not an explanation anyone can act on.
--
-- CAPTURED AT PERIOD LOCK, before any score is computed (CaptureFrameworkSnapshotJob).
--
-- checksum exists so BR-BA-064 is TESTABLE: recompute a locked period, and if the snapshot checksum
--   differs from the one the score run recorded, report the discrepancy instead of silently
--   overwriting a published score.
--
-- is_retrospective is an honesty flag. A snapshot taken during the v2->v7.0 migration for a period
--   locked six months ago records TODAY'S framework, not the framework in force then. If a weight
--   changed in between, that period's history is already unrecoverable. The flag makes that visible
--   in the data rather than assumed away. From v7.0 forward, snapshots are genuine.
--
-- IMMUTABLE: no updated_at, no deleted_at. trg_ba_snapshot_bu / _bd reject UPDATE and DELETE.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_framework_snapshots` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period_id`        BIGINT UNSIGNED NOT NULL,
  `version`          SMALLINT UNSIGNED NOT NULL DEFAULT 1  COMMENT 'Incremented when a reopened period is re-locked',
  `scale_json`       JSON NOT NULL   COMMENT 'Scale attributes + every level: label, numeric_value, sort_order',
  `categories_json`  JSON NOT NULL   COMMENT 'id, code, name, polarity, weight, parent_id',
  `criteria_json`    JSON NOT NULL   COMMENT 'id, code, name, weight, category_id',
  `class_map_json`   JSON DEFAULT NULL COMMENT 'The class -> category mapping in force',
  `config_json`      JSON NOT NULL   COMMENT 'aggregation_method, normalisation_base, integration settings',
  `checksum`         CHAR(64) NOT NULL COMMENT 'SHA-256 over the canonical JSON — makes BR-BA-064 testable',
  `is_retrospective` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'v7.0 migration only — see the note above. NOT a true freeze',
  `captured_by`      INT UNSIGNED DEFAULT NULL COMMENT 'FK sys_users.id; NULL = system job',
  `captured_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`        TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`       INT UNSIGNED NOT NULL,
  `created_at`       TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_snapshot` (`period_id`, `version`),
  KEY `idx_ba_snapshot_period` (`period_id`),
  CONSTRAINT `fk_ba_snapshot_period`  FOREIGN KEY (`period_id`)  REFERENCES `ba_assessment_periods` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_snapshot_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)             ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='IMMUTABLE frozen framework per locked period (D-07). No update path by design.';


-- =========================================================================================================
-- SECTION 4 — LAYER 4: WORKFLOW HEADERS AND AUDIT
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 12: ba_assessments
-- ---------------------------------------------------------------------------------------------------------
-- One teacher's evaluation of one class-section for one period.
--
-- LIFECYCLE (BR-BA-052):
--
--                        +---- sendBack() ----+
--                        |                    |
--     [DRAFT] --submit()--> [SUBMITTED] --approve()--> [REVIEWED] --lock()--> [LOCKED]  terminal
--        ^                      |                          |
--        +---- sendBack() ------+<-------------------------+
--
--   When ba_config.is_review_required = 0, submit() goes DRAFT -> REVIEWED directly (BR-BA-025),
--   and onward to LOCKED if auto_lock_on_approval is set.
--
-- APPROVE AND LOCK ARE TWO EVENTS (Decision D-03). approved_by/at and locked_by/at are separate
--   columns because they answer different questions with different accountability: "who accepted this
--   content?" and "who made it final?" are frequently different people. A school that wants one click
--   sets auto_lock_on_approval; both events are still recorded distinctly.
--
-- v7.0 ADDITIONS
--   assessment_scope + subject_id  BR-BA-050. Makes "who rated this child, in what capacity"
--                                  answerable, and lets a school later weight the class teacher's
--                                  view differently (ENH-BA-009) without a schema change.
--   sent_back_count                BR-BA-054. A third send-back is a coaching signal, not a data problem.
--   completion_percent             Maintained on save so My Assessments and the dashboard read a
--                                  number instead of counting half a million cells.
--   snapshot_id                    The framework this assessment was frozen against.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_assessments` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period_id`         BIGINT UNSIGNED NOT NULL,
  `teacher_id`        INT UNSIGNED    NOT NULL           COMMENT 'FK sch_employees.id — the assessor',
  `class_section_id`  INT UNSIGNED    NOT NULL           COMMENT 'FK sch_class_section_jnt.id',
  `assessment_scope`  ENUM('class_teacher','subject_teacher') NOT NULL DEFAULT 'class_teacher' COMMENT 'v7.0 BR-BA-050',
  `subject_id`        INT UNSIGNED    DEFAULT NULL       COMMENT 'v7.0 — FK sch_subjects.id; required for subject scope',
  `status`            ENUM('draft','submitted','reviewed','locked') NOT NULL DEFAULT 'draft',
  `completion_percent` DECIMAL(5,2)   NOT NULL DEFAULT 0.00 COMMENT 'v7.0 — maintained on save; avoids counting cells',
  `last_autosaved_at` TIMESTAMP       NULL DEFAULT NULL  COMMENT 'v7.0 — shown as "last saved" in the grid',
  `submitted_by`      INT UNSIGNED    DEFAULT NULL       COMMENT 'v7.0 — FK sch_employees.id',
  `submitted_at`      TIMESTAMP       NULL DEFAULT NULL,
  `reviewed_by`       INT UNSIGNED    DEFAULT NULL       COMMENT 'FK sch_employees.id — retained name',
  `reviewed_at`       TIMESTAMP       NULL DEFAULT NULL,
  `approved_by`       INT UNSIGNED    DEFAULT NULL       COMMENT 'v7.0 D-03 — who accepted the content',
  `approved_at`       TIMESTAMP       NULL DEFAULT NULL,
  `locked_by`         INT UNSIGNED    DEFAULT NULL       COMMENT 'v7.0 D-03 — who made it final',
  `locked_at`         TIMESTAMP       NULL DEFAULT NULL,
  `reviewer_remarks`  TEXT            DEFAULT NULL       COMMENT 'Mandatory on send-back',
  `sent_back_count`   TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v7.0 BR-BA-054',
  `last_sent_back_at` TIMESTAMP       NULL DEFAULT NULL,
  `snapshot_id`       BIGINT UNSIGNED DEFAULT NULL       COMMENT 'v7.0 — framework frozen at lock',
  `is_active`         TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`        INT UNSIGNED NOT NULL,
  `updated_by`        INT UNSIGNED NOT NULL,
  `created_at`        TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`        TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`        DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`          DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_assessment` (`teacher_id`, `class_section_id`, `period_id`, `uq_guard`),
  KEY `idx_ba_assess_queue`    (`period_id`, `status`),
  KEY `idx_ba_assess_mine`     (`teacher_id`, `period_id`),
  KEY `idx_ba_assess_cs`       (`class_section_id`, `period_id`),
  KEY `idx_ba_assess_reviewer` (`reviewed_by`),
  KEY `idx_ba_assess_snapshot` (`snapshot_id`),
  CONSTRAINT `fk_ba_assess_period`   FOREIGN KEY (`period_id`)        REFERENCES `ba_assessment_periods` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_assess_teacher`  FOREIGN KEY (`teacher_id`)       REFERENCES `sch_employees` (`id`)          ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_assess_cs`       FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_assess_subject`  FOREIGN KEY (`subject_id`)       REFERENCES `sch_subjects` (`id`)           ON DELETE SET NULL,
  CONSTRAINT `fk_ba_assess_reviewer` FOREIGN KEY (`reviewed_by`)      REFERENCES `sch_employees` (`id`)          ON DELETE SET NULL,
  CONSTRAINT `fk_ba_assess_approver` FOREIGN KEY (`approved_by`)      REFERENCES `sch_employees` (`id`)          ON DELETE SET NULL,
  CONSTRAINT `fk_ba_assess_locker`   FOREIGN KEY (`locked_by`)        REFERENCES `sch_employees` (`id`)          ON DELETE SET NULL,
  CONSTRAINT `fk_ba_assess_snapshot` FOREIGN KEY (`snapshot_id`)      REFERENCES `ba_framework_snapshots` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ba_assess_created`  FOREIGN KEY (`created_by`)       REFERENCES `sys_users` (`id`)              ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_assess_completion` CHECK (`completion_percent` >= 0 AND `completion_percent` <= 100),
  CONSTRAINT `chk_ba_assess_subject`    CHECK (`assessment_scope` <> 'subject_teacher' OR `subject_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Assessment header. Approve and lock are separate events (D-03). FSM by trigger.';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 13: ba_assessment_status_history                                          [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Every state transition of every assessment.   REQ-BA-022.
--
-- This is NOT a duplicate of ba_audit_log. They answer different questions:
--     ba_audit_log             "what changed"  — field-level, across many entity types
--     ba_assessment_status_history  "who moved this, when, and why" — workflow-level, one entity
--
-- The Review Queue reads it to show how long a submission has waited and how often it has bounced;
-- the Student Report reads it to show when a period was finalised. Deriving either from a field-level
-- audit log means parsing a generic table for a specific narrative, and every screen would do it
-- slightly differently.
--
-- INSERT-ONLY. trg_ba_status_hist_bu / _bd reject UPDATE and DELETE.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_assessment_status_history` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id` BIGINT UNSIGNED NOT NULL,
  `from_status`   ENUM('draft','submitted','reviewed','locked') DEFAULT NULL COMMENT 'NULL on creation',
  `to_status`     ENUM('draft','submitted','reviewed','locked') NOT NULL,
  `action`        ENUM('create','submit','approve','send_back','lock','auto_publish') NOT NULL,
  `remark`        TEXT         DEFAULT NULL COMMENT 'Mandatory for send_back',
  `actor_id`      INT UNSIGNED NOT NULL COMMENT 'FK sys_users.id',
  `ip_address`    VARBINARY(16) DEFAULT NULL COMMENT 'INET6_ATON form',
  `changed_at`    TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`    INT UNSIGNED NOT NULL,
  `created_at`    TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_hist_assess` (`assessment_id`, `changed_at`),
  KEY `idx_ba_hist_actor`  (`actor_id`),
  CONSTRAINT `fk_ba_hist_assess` FOREIGN KEY (`assessment_id`) REFERENCES `ba_assessments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_hist_actor`  FOREIGN KEY (`actor_id`)      REFERENCES `sys_users` (`id`)      ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_hist_created` FOREIGN KEY (`created_by`)    REFERENCES `sys_users` (`id`)      ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_hist_sendback` CHECK (`action` <> 'send_back' OR `remark` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='INSERT-ONLY workflow history. Answers "who moved this and why" (REQ-BA-022).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 14: ba_audit_log
-- ---------------------------------------------------------------------------------------------------------
-- IMMUTABLE field-level change record.  No updated_at. No deleted_at. Insert-only (BR-BA-012),
-- enforced by trg_ba_audit_bu / _bd — not by a model convention that a raw query can bypass.
--
-- v7.0 EXTENDS entity_type FROM 3 TO 10 VALUES.
--   v2 audited assessment_rating, assessment and incident only. BRD v2 sec.85 noted that the screens
--   expected configuration and lock activity to be discoverable in the audit report; those events were
--   not recorded at all, so the report could not show them.
--
--   Three of the new types are READ events, not writes:
--       witness_read   BR-BA-031 — statement text is the module's most sensitive field
--       export         BR-BA-096 — an export of behavioural data is a disclosure
--       (demographic analytics runs are recorded as entity_type='export')
--   A disclosure that nobody can reconstruct is not a controlled disclosure.
--
-- reason exists for the two operations that require justification: severity escalation (BR-BA-073)
--   and period reopen. An audit row saying WHAT changed without WHY is half a record.
--
-- NOTE ON created_by. Every other ba_* table carries a foreign key on created_by. This one does not,
--   deliberately: created_by here always equals changed_by, which is already constrained and indexed,
--   and this is the largest table in the module (~500,000 rows per session). A second index over the
--   same value would cost storage and write throughput on every audited operation and answer no
--   question the changed_by index does not already answer.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_audit_log` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_type` ENUM('assessment','assessment_rating','incident','intervention','witness',
                     'witness_read','config','framework','period','export') NOT NULL,
  `entity_id`   BIGINT UNSIGNED NOT NULL,
  `field_name`  VARCHAR(64)  NOT NULL COMMENT 'Column changed, or the read action for read events',
  `old_value`   VARCHAR(500) DEFAULT NULL,
  `new_value`   VARCHAR(500) DEFAULT NULL,
  `reason`      VARCHAR(500) DEFAULT NULL COMMENT 'v7.0 — required for severity escalation and period reopen',
  `changed_by`  INT UNSIGNED NOT NULL COMMENT 'FK sys_users.id (v7.0: was BIGINT)',
  `ip_address`  VARBINARY(16) DEFAULT NULL COMMENT 'v7.0 — INET6_ATON form',
  `user_agent`  VARCHAR(255)  DEFAULT NULL COMMENT 'v7.0',
  `changed_at`  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`  INT UNSIGNED NOT NULL,
  `created_at`  TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_audit_entity`  (`entity_type`, `entity_id`, `changed_at`),
  KEY `idx_ba_audit_actor`   (`changed_by`, `changed_at`),
  KEY `idx_ba_audit_when`    (`changed_at`),
  CONSTRAINT `fk_ba_audit_actor` FOREIGN KEY (`changed_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='IMMUTABLE audit. 10 entity types including read events (BR-BA-012/031/096).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 15: ba_audit_log_archive                                                  [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Identical shape to ba_audit_log. Rows move here when an administrator EXPLICITLY runs
-- ArchiveAuditLogJob for records older than ba_config.audit_retention_months (default 36).
--
-- BR-BA-093 — THERE IS NO SCHEDULED PURGE. Deleting a compliance record because a timer expired is
-- not a retention policy; it is data loss with a cron entry. Archival is an administrative act, it is
-- itself audited, and the rows remain queryable.
--
-- BRD v2 sec.87 proposed a 3-year prune and correctly flagged it as a policy decision. Resolved as:
-- 36-month default eligibility, explicit archival, no deletion.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_audit_log_archive` (
  `id`           BIGINT UNSIGNED NOT NULL,
  `entity_type`  VARCHAR(30)  NOT NULL,
  `entity_id`    BIGINT UNSIGNED NOT NULL,
  `field_name`   VARCHAR(64)  NOT NULL,
  `old_value`    VARCHAR(500) DEFAULT NULL,
  `new_value`    VARCHAR(500) DEFAULT NULL,
  `reason`       VARCHAR(500) DEFAULT NULL,
  `changed_by`   INT UNSIGNED NOT NULL,
  `ip_address`   VARBINARY(16) DEFAULT NULL,
  `user_agent`   VARCHAR(255)  DEFAULT NULL,
  `changed_at`   TIMESTAMP(6) NOT NULL,
  `archived_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `archived_by`  INT UNSIGNED NOT NULL COMMENT 'The administrator who ran the archival',
  PRIMARY KEY (`id`),
  KEY `idx_ba_arch_entity` (`entity_type`, `entity_id`),
  KEY `idx_ba_arch_when`   (`changed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Archived audit rows. Moved only by explicit admin action, never on a schedule (BR-BA-093).';


-- =========================================================================================================
-- SECTION 5 — LAYER 5: CORE TRANSACTIONS
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 16: ba_assessment_ratings
-- ---------------------------------------------------------------------------------------------------------
-- THE core fact table. One row per grid cell: student x criterion x assessment.
-- Roughly 460,000 rows per tenant per session (2,000 students x 58 criteria x 4 periods).
-- Every reporting path must reach behavioural numbers through the computed cache, never through here.
-- The single sanctioned exception is the Student Report's criterion detail panel, which reads ONE
-- student for ONE period on the primary key path.
--
-- rating_value — THE MOST IMPORTANT NEW COLUMN IN v7.0  (BR-BA-057)
--   v2 stored only rating_level_id, with ON DELETE SET NULL. Delete a rating level and every rating
--   that used it silently became "not rated" — a LOCKED, PUBLISHED assessment quietly lost data, and
--   the next recomputation produced different numbers with no error anywhere.
--   Storing the numeric value the teacher actually selected makes a rating SELF-DESCRIBING:
--     - a locked period recomputes identically forever;
--     - the level may be renamed, reordered, deactivated or deleted without touching history;
--     - the averaging query reads one column instead of joining to levels 460,000 times.
--   rating_level_id is retained for display ("Very Good") and for editability while the period is open.
--
-- LOCK ENFORCEMENT. trg_ba_rating_bi / _bu / _bd read the parent assessment AND its period on every
--   write and reject when the assessment is locked or the period is closed or locked. This is the fix
--   for BUG-BA-001: the guard lives where the WRITE happens, not where the lock is set.
--
-- BR-BA-060: an unrated cell contributes to neither numerator nor denominator. A NULL rating_value is
--   "not observed", never zero. Treating it as zero punishes a student for a teacher's omission.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_assessment_ratings` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id`   BIGINT UNSIGNED NOT NULL,
  `student_id`      INT UNSIGNED    NOT NULL          COMMENT 'FK std_students.id',
  `criterion_id`    BIGINT UNSIGNED NOT NULL,
  `rating_level_id` BIGINT UNSIGNED DEFAULT NULL      COMMENT 'Selected level; NULL = not yet rated',
  `rating_value`    DECIMAL(4,2)    DEFAULT NULL      COMMENT 'v7.0 BR-BA-057 — the number the teacher meant, frozen at save',
  `remark`          VARCHAR(500)    DEFAULT NULL      COMMENT 'Optional per-criterion remark',
  `rated_at`        TIMESTAMP       NULL DEFAULT NULL COMMENT 'v7.0 — when the cell was last given a value',
  `is_active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED NOT NULL,
  `updated_by`      INT UNSIGNED NOT NULL,
  `created_at`      TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`      DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`        DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_rating` (`assessment_id`, `student_id`, `criterion_id`, `uq_guard`),
  KEY `idx_ba_rating_assess`  (`assessment_id`),
  KEY `idx_ba_rating_avg`     (`student_id`, `criterion_id`, `rating_value`) COMMENT 'Multi-teacher averaging',
  KEY `idx_ba_rating_analytic`(`criterion_id`, `rating_value`)               COMMENT 'Category performance analytics',
  KEY `idx_ba_rating_level`   (`rating_level_id`),
  CONSTRAINT `fk_ba_rating_assess`    FOREIGN KEY (`assessment_id`)   REFERENCES `ba_assessments` (`id`)    ON DELETE CASCADE,
  CONSTRAINT `fk_ba_rating_student`   FOREIGN KEY (`student_id`)      REFERENCES `std_students` (`id`)      ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_rating_criterion` FOREIGN KEY (`criterion_id`)    REFERENCES `ba_criteria` (`id`)       ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_rating_level`     FOREIGN KEY (`rating_level_id`) REFERENCES `ba_rating_levels` (`id`)  ON DELETE SET NULL,
  CONSTRAINT `fk_ba_rating_created`   FOREIGN KEY (`created_by`)      REFERENCES `sys_users` (`id`)         ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_rating_value`    CHECK (`rating_value` IS NULL OR `rating_value` >= 0),
  CONSTRAINT `chk_ba_rating_paired`   CHECK (`rating_level_id` IS NULL OR `rating_value` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Core fact table. rating_value makes a rating self-describing (BR-BA-057). Lock by trigger.';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 17: ba_student_remarks
-- ---------------------------------------------------------------------------------------------------------
-- One holistic remark per student per assessment. Distinct from the per-criterion remark on a rating:
-- that one explains a cell, this one describes the child.
--
-- comment_template_id records which Comment Bank template seeded the text, for usage analytics only
-- (BR-BA-038). The stored text is the teacher's own words, edited from wherever they started.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_student_remarks` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `assessment_id`       BIGINT UNSIGNED NOT NULL,
  `student_id`          INT UNSIGNED    NOT NULL      COMMENT 'FK std_students.id',
  `remark_text`         TEXT            NOT NULL,
  `comment_template_id` BIGINT UNSIGNED DEFAULT NULL  COMMENT 'v7.0 — analytics only; the text is the teachers own',
  `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED NOT NULL,
  `created_at`          TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`          DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`            DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_remark` (`assessment_id`, `student_id`, `uq_guard`),
  KEY `idx_ba_remark_student` (`student_id`),
  CONSTRAINT `fk_ba_remark_assess`   FOREIGN KEY (`assessment_id`)       REFERENCES `ba_assessments` (`id`)   ON DELETE CASCADE,
  CONSTRAINT `fk_ba_remark_student`  FOREIGN KEY (`student_id`)          REFERENCES `std_students` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_remark_template` FOREIGN KEY (`comment_template_id`) REFERENCES `ba_comment_bank` (`id`)  ON DELETE SET NULL,
  CONSTRAINT `fk_ba_remark_created`  FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`)        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Holistic per-student remark. Comment Bank seeds it; the teacher owns it (BR-BA-038).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 18: ba_computed_scores
-- ---------------------------------------------------------------------------------------------------------
-- Materialised CATEGORY-level score cache: one row per student x category x period.
--
-- v7.0 REMOVES overall_score / overall_grade FROM THIS TABLE. v2 stored the overall "on the first
-- category row per student-period". That makes the overall depend on row ordering, breaks when the
-- first category is deactivated, and forces every overall query to guess which row is authoritative.
-- The overall now has its own table with a clean UNIQUE(student_id, period_id). See ba_computed_overall.
--
-- is_insufficient_data (BR-BA-061): set when fewer than ba_config.min_coverage_percent of the
-- category's applicable criteria were rated. A category score derived from one criterion out of eight
-- is not a measurement, and reporting it as a number is worse than reporting nothing, because a
-- number invites comparison.
--
-- score_run_id ties every cached number to the run that produced it (BR-BA-063). A score whose
-- provenance cannot be stated cannot be defended to a parent.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_computed_scores` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`           INT UNSIGNED    NOT NULL,
  `category_id`          BIGINT UNSIGNED NOT NULL,
  `period_id`            BIGINT UNSIGNED NOT NULL,
  `numeric_score`        DECIMAL(6,3)    DEFAULT NULL COMMENT 'NULL when is_insufficient_data = 1',
  `normalised_score`     DECIMAL(6,3)    DEFAULT NULL COMMENT 'v7.0 — 0..normalisation_base; scale-independent comparison',
  `grade`                VARCHAR(5)      DEFAULT NULL COMMENT 'Mapped from the scale level bands',
  `criteria_rated`       SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v7.0 — coverage numerator',
  `criteria_applicable`  SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v7.0 — coverage denominator',
  `teacher_count`        TINYINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT 'v7.0 — "averaged across 3 teachers"',
  `is_insufficient_data` TINYINT(1)      NOT NULL DEFAULT 0   COMMENT 'v7.0 BR-BA-061',
  `score_run_id`         BIGINT UNSIGNED DEFAULT NULL         COMMENT 'v7.0 — provenance',
  `computed_at`          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`            TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`           INT UNSIGNED NOT NULL,
  `updated_by`           INT UNSIGNED NOT NULL,
  `created_at`           TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`           TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`           DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`             DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_score` (`student_id`, `category_id`, `period_id`, `uq_guard`),
  KEY `idx_ba_score_student` (`student_id`, `period_id`),
  KEY `idx_ba_score_cohort`  (`period_id`, `category_id`, `numeric_score`),
  KEY `idx_ba_score_run`     (`score_run_id`),
  CONSTRAINT `fk_ba_score_student` FOREIGN KEY (`student_id`)  REFERENCES `std_students` (`id`)           ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_score_cat`     FOREIGN KEY (`category_id`) REFERENCES `ba_categories` (`id`)          ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_score_period`  FOREIGN KEY (`period_id`)   REFERENCES `ba_assessment_periods` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_score_created` FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)              ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_score_value`  CHECK (`numeric_score` IS NULL OR `numeric_score` >= 0),
  CONSTRAINT `chk_ba_score_insuff` CHECK (`is_insufficient_data` = 0 OR `numeric_score` IS NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Category score cache. Overall moved to ba_computed_overall — v2 stored it on "the first row".';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 19: ba_computed_overall                                                   [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- One row per student per period: the overall behavioural standing.
--
-- Why this is a separate table rather than a column on ba_computed_scores is explained above. In
-- short: an overall stored on "whichever category row happens to be first" is not addressable.
--
-- previous_overall / score_delta / trend are DENORMALISED here on purpose. Period Progress, Class
-- Analysis, the dashboard and the Student Report all need the same delta, and computing it in four
-- places produces four slightly different answers the first time someone changes a threshold. The
-- values are written by the same score run that writes the score, so they cannot drift.
--
-- trend bands come from ba_config, expressed as percentages of scale range (BR-BA-088):
--     improving : delta >  trend_improve_percent x range
--     stable    : |delta| <= trend_stable_percent x range
--     declining : delta < -trend_improve_percent x range
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_computed_overall` (
  `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`         INT UNSIGNED    NOT NULL,
  `period_id`          BIGINT UNSIGNED NOT NULL,
  `overall_score`      DECIMAL(6,3)    DEFAULT NULL COMMENT 'NULL when aggregation_method = separate_display',
  `normalised_score`   DECIMAL(6,3)    DEFAULT NULL COMMENT '0..normalisation_base — what result integration consumes',
  `overall_grade`      VARCHAR(5)      DEFAULT NULL,
  `categories_scored`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `previous_overall`   DECIMAL(6,3)    DEFAULT NULL COMMENT 'Previous period, same student',
  `score_delta`        DECIMAL(6,3)    DEFAULT NULL COMMENT 'overall - previous_overall',
  `trend`              ENUM('improving','stable','declining','no_baseline') NOT NULL DEFAULT 'no_baseline',
  `is_at_risk`         TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'BR-BA-089 composite rule, evaluated at compute time',
  `at_risk_reason`     VARCHAR(255)    DEFAULT NULL       COMMENT 'Which limb of the rule fired — score, incidents, or both',
  `score_run_id`       BIGINT UNSIGNED DEFAULT NULL,
  `computed_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`          TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`         INT UNSIGNED NOT NULL,
  `updated_by`         INT UNSIGNED NOT NULL,
  `created_at`         TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`         TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`         DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`           DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_overall` (`student_id`, `period_id`, `uq_guard`),
  KEY `idx_ba_overall_rank`   (`period_id`, `overall_score`),
  KEY `idx_ba_overall_risk`   (`period_id`, `is_at_risk`),
  KEY `idx_ba_overall_run`    (`score_run_id`),
  CONSTRAINT `fk_ba_overall_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`)          ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_overall_period`  FOREIGN KEY (`period_id`)  REFERENCES `ba_assessment_periods` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_overall_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)             ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Overall score per student-period, with delta and trend computed once and read everywhere.';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 20: ba_score_runs                                                         [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Provenance for every score computation.   BR-BA-063, BR-BA-064.
--
-- WHY. A behavioural score reaches a report card and then a parent-teacher meeting. When a parent
-- asks how it was arrived at, "the system calculated it" is not an answer. This table lets the school
-- state: what triggered the run, who ran it, when, against which frozen framework, over how many
-- students, and whether it completed.
--
-- snapshot_checksum is what makes BR-BA-064 TESTABLE. Recompute a locked period; if the snapshot's
-- current checksum differs from the one recorded here, the framework has been tampered with or the
-- snapshot is not the one that was used. Report the discrepancy — do NOT silently overwrite a
-- published score.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_score_runs` (
  `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `period_id`          BIGINT UNSIGNED NOT NULL,
  `trigger_source`     ENUM('assessment_approved','period_locked','manual_admin','migration','scheduled') NOT NULL,
  `triggered_by`       INT UNSIGNED    DEFAULT NULL COMMENT 'FK sys_users.id; NULL = system',
  `snapshot_id`        BIGINT UNSIGNED DEFAULT NULL COMMENT 'Framework in force; NULL for an open period',
  `snapshot_checksum`  CHAR(64)        DEFAULT NULL COMMENT 'Copied at run time — see the note above',
  `students_processed` INT UNSIGNED    NOT NULL DEFAULT 0,
  `scores_written`     INT UNSIGNED    NOT NULL DEFAULT 0,
  `status`             ENUM('running','completed','failed','completed_with_warnings') NOT NULL DEFAULT 'running',
  `warning_json`       JSON            DEFAULT NULL COMMENT 'e.g. students with insufficient data',
  `error_message`      TEXT            DEFAULT NULL,
  `started_at`         TIMESTAMP(3)    NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `finished_at`        TIMESTAMP(3)    NULL DEFAULT NULL,
  `duration_ms`        INT UNSIGNED    DEFAULT NULL,
  `is_active`          TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`         INT UNSIGNED NOT NULL,
  `created_at`         TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_run_period` (`period_id`, `started_at`),
  KEY `idx_ba_run_status` (`status`),
  CONSTRAINT `fk_ba_run_period`   FOREIGN KEY (`period_id`)   REFERENCES `ba_assessment_periods` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_ba_run_snapshot` FOREIGN KEY (`snapshot_id`) REFERENCES `ba_framework_snapshots` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ba_run_created`  FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)              ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Computation provenance. A score that cannot state its provenance cannot be defended.';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 21: ba_incidents
-- ---------------------------------------------------------------------------------------------------------
-- Behavioural events, positive or negative, recorded independently of assessment periods.
--
-- LIFECYCLE (Decision D-06, BR-BA-067/068/069) — NEW IN v7.0:
--
--   [OPEN] -> [UNDER_REVIEW] -> [ACTION_TAKEN] -> [RESOLVED] -> [CLOSED]
--      +-------------+---------------+--------------+--------> [CANCELLED]  (reason mandatory)
--
--   v2 had no status at all. The module recorded that something happened and never recorded that
--   anything was done about it — which is precisely the business problem it was built to solve.
--   A positive incident may go open -> closed directly (BR-BA-069).
--
-- IMMUTABILITY (BR-BA-008) and ITS ONE EXCEPTION (BR-BA-073):
--   student_id, incident_date, incident_type, description and location are frozen after creation.
--   SEVERITY IS THE EXCEPTION. Investigation frequently shows an incident logged as moderate was in
--   fact major, and forcing cancel-and-re-raise there would destroy the witness statements and
--   interventions already attached. So severity may be ESCALATED — never reduced — by an Admin or
--   Principal, with a reason, an audit row carrying old and new values, and a re-evaluation of the
--   notification threshold. trg_ba_incident_bu permits the column to change; BaIncidentService
--   enforces who may do it and that the new value is higher.
--   A materially wrong incident is CANCELLED with a reason and re-raised (BR-BA-072). Records are
--   never edited into a different truth and never hard-deleted.
--
-- incident_no (v7.0): a human reference, INC-YYYY-NNNNNN, generated by trg_ba_incident_no_bi.
--   Used in letters, meetings and cross-references. "Incident 4471" is not something a parent can
--   quote; "INC-2026-000417" is.
--
-- LOCATION gained assembly, sports_ground, hostel and online (BR-BA-071). Cyber-bullying and
--   transport/hostel incidents are real and were previously forced into "other", where they
--   disappeared from hotspot analysis.
--
-- is_notified is RETAINED but is NOT authoritative. ba_notifications is (see Table 26). The boolean
--   stays as a cheap denormalisation for list rendering, maintained from the outbox.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_incidents` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_no`           VARCHAR(20)     NOT NULL DEFAULT '' COMMENT 'v7.0 — INC-YYYY-NNNNNN. DEFAULT is empty so trg_ba_incident_no_bi can fill it under STRICT mode',
  `student_id`            INT UNSIGNED    NOT NULL          COMMENT 'FK std_students.id — IMMUTABLE',
  `reported_by`           INT UNSIGNED    NOT NULL          COMMENT 'FK sch_employees.id',
  `category_id`           BIGINT UNSIGNED DEFAULT NULL      COMMENT 'Optional link to the framework',
  `criterion_id`          BIGINT UNSIGNED DEFAULT NULL,
  `incident_date`         DATE            NOT NULL          COMMENT 'IMMUTABLE. Not future. Backdating limited by config',
  `incident_time`         TIME            DEFAULT NULL,
  `incident_type`         ENUM('positive_reinforcement','negative_incident') NOT NULL COMMENT 'IMMUTABLE',
  `severity`              ENUM('minor','moderate','major','critical') DEFAULT NULL
                            COMMENT 'Required for negative, forbidden for positive. May ESCALATE only (BR-BA-073)',
  `description`           TEXT            NOT NULL          COMMENT 'IMMUTABLE. Length bounded by config',
  `location`              ENUM('classroom','playground','corridor','lab','transport','canteen','library',
                               'assembly','sports_ground','hostel','online','other')
                            NOT NULL DEFAULT 'classroom'    COMMENT 'v7.0 added assembly/sports_ground/hostel/online',
  `status`                ENUM('open','under_review','action_taken','resolved','closed','cancelled')
                            NOT NULL DEFAULT 'open'         COMMENT 'v7.0 D-06',
  `intervention_notes`    TEXT            DEFAULT NULL      COMMENT 'Free text; the tracked cases live in the junction',
  `is_follow_up_required` TINYINT(1)      NOT NULL DEFAULT 0,
  `follow_up_date`        DATE            DEFAULT NULL      COMMENT 'The NEXT follow-up; history is in ba_incident_followups',
  `resolved_by`           INT UNSIGNED    DEFAULT NULL      COMMENT 'v7.0 — FK sch_employees.id',
  `resolved_at`           TIMESTAMP       NULL DEFAULT NULL,
  `closure_notes`         TEXT            DEFAULT NULL      COMMENT 'v7.0 — mandatory to close (BR-BA-068)',
  `closed_at`             TIMESTAMP       NULL DEFAULT NULL,
  `cancellation_reason`   VARCHAR(500)    DEFAULT NULL      COMMENT 'v7.0 — mandatory to cancel (BR-BA-072)',
  `severity_escalated_at` TIMESTAMP       NULL DEFAULT NULL COMMENT 'v7.0 — the one permitted core-field change',
  `original_severity`     ENUM('minor','moderate','major','critical') DEFAULT NULL COMMENT 'v7.0 — what it was first logged as',
  `is_backdated_override` TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'v7.0 — admin overrode the backdating window',
  `is_notified`           TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Denormalised convenience. ba_notifications is authoritative',
  `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED NOT NULL,
  `created_at`            TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`            DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`              DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_incident_no` (`incident_no`, `uq_guard`),
  KEY `idx_ba_incident_timeline` (`student_id`, `incident_date`),
  KEY `idx_ba_incident_open`     (`status`, `severity`),
  KEY `idx_ba_incident_hotspot`  (`incident_date`, `location`),
  KEY `idx_ba_incident_reporter` (`reported_by`),
  KEY `idx_ba_incident_cat`      (`category_id`),
  KEY `idx_ba_incident_crit`     (`criterion_id`),
  KEY `idx_ba_incident_escal`    (`student_id`, `incident_type`, `incident_date`) COMMENT 'Escalation window count',
  CONSTRAINT `fk_ba_incident_student`  FOREIGN KEY (`student_id`)   REFERENCES `std_students` (`id`)   ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_incident_reporter` FOREIGN KEY (`reported_by`)  REFERENCES `sch_employees` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_incident_resolver` FOREIGN KEY (`resolved_by`)  REFERENCES `sch_employees` (`id`)  ON DELETE SET NULL,
  CONSTRAINT `fk_ba_incident_cat`      FOREIGN KEY (`category_id`)  REFERENCES `ba_categories` (`id`)  ON DELETE SET NULL,
  CONSTRAINT `fk_ba_incident_crit`     FOREIGN KEY (`criterion_id`) REFERENCES `ba_criteria` (`id`)    ON DELETE SET NULL,
  CONSTRAINT `fk_ba_incident_created`  FOREIGN KEY (`created_by`)   REFERENCES `sys_users` (`id`)      ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_incident_severity` CHECK (
        (`incident_type` = 'negative_incident'      AND `severity` IS NOT NULL)
     OR (`incident_type` = 'positive_reinforcement' AND `severity` IS NULL)),
  CONSTRAINT `chk_ba_incident_closure` CHECK (
        `status` <> 'closed' OR (`closure_notes` IS NOT NULL AND CHAR_LENGTH(`closure_notes`) >= 5)),
  CONSTRAINT `chk_ba_incident_cancel` CHECK (
        `status` <> 'cancelled' OR (`cancellation_reason` IS NOT NULL AND CHAR_LENGTH(`cancellation_reason`) >= 5)),
  CONSTRAINT `chk_ba_incident_followup` CHECK (
        `is_follow_up_required` = 0 OR `follow_up_date` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Incidents with a lifecycle (D-06). Core fields immutable; severity may escalate (BR-BA-073).';


-- =========================================================================================================
-- SECTION 6 — LAYER 6: INCIDENT DETAIL
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 22: ba_incident_witnesses_jnt
-- ---------------------------------------------------------------------------------------------------------
-- Who saw it, and what they said.
--
-- v7.0 ADDS THE STATEMENT. v2 declared this table with witness_type and witness_id and NO COLUMN TO
--   HOLD A STATEMENT — while BRD v2 sec.56 specified statement length limits and sec.58 specified who
--   may read them. The requirement had nowhere to live, so it could not be built. This is the clearest
--   single example of the pattern this schema revision exists to correct.
--
-- WITNESS STATEMENTS ARE THE MODULE'S MOST SENSITIVE FIELD. Three controls:
--   1. ACCESS   — BaWitnessPolicy::viewStatement(), SEPARATE from view(). HOD, Counsellor, Principal
--                 only (BR-BA-019/031). A class teacher may see that there were three witnesses and
--                 may not see what they said. is_confidential narrows it further to Principal and
--                 Counsellor.
--   2. AUDITED ON READ — every statement read writes ba_audit_log with entity_type='witness_read'.
--                 A disclosure nobody can reconstruct is not a controlled disclosure.
--   3. FROZEN ON CLOSURE — when the incident closes and config.freeze_witness_on_closure is on,
--                 frozen_at is set and trg_ba_witness_bu rejects further writes (BR-BA-077).
--                 A statement editable after the case concludes has no evidential value.
--
-- witness_id is POLYMORPHIC (std_students.id or sch_employees.id per witness_type) so it carries NO
--   database foreign key. The application validates it against the correct master. This is a
--   deliberate, documented trade: the alternative is two nullable FK columns and a CHECK that exactly
--   one is populated, which is more correct but makes every query branch. Revisit if witness data ever
--   needs to be joined in bulk.
--
-- BR-BA-075: the subject student cannot witness their own incident — enforced in BaWitnessService,
--   which is the only place that knows the incident's student_id at insert time.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_incident_witnesses_jnt` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_id`           BIGINT UNSIGNED NOT NULL,
  `witness_type`          ENUM('student','staff') NOT NULL,
  `witness_id`            INT UNSIGNED    NOT NULL COMMENT 'std_students.id or sch_employees.id — polymorphic, no DB FK',
  `statement`             VARCHAR(500)    DEFAULT NULL COMMENT 'v7.0 — the factual account. RESTRICTED READ',
  `is_confidential`       TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'v7.0 — narrows access to Principal + Counsellor',
  `statement_recorded_by` INT UNSIGNED    DEFAULT NULL COMMENT 'v7.0 — FK sch_employees.id',
  `statement_recorded_at` TIMESTAMP       NULL DEFAULT NULL,
  `frozen_at`             TIMESTAMP       NULL DEFAULT NULL COMMENT 'v7.0 — set on case closure (BR-BA-077)',
  `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`            INT UNSIGNED NOT NULL,
  `updated_by`            INT UNSIGNED NOT NULL,
  `created_at`            TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`            TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`            DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`              DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_witness` (`incident_id`, `witness_type`, `witness_id`, `uq_guard`),
  KEY `idx_ba_witness_incident` (`incident_id`),
  KEY `idx_ba_witness_person`   (`witness_type`, `witness_id`),
  CONSTRAINT `fk_ba_witness_incident` FOREIGN KEY (`incident_id`)           REFERENCES `ba_incidents` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_ba_witness_recorder` FOREIGN KEY (`statement_recorded_by`) REFERENCES `sch_employees` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ba_witness_created`  FOREIGN KEY (`created_by`)            REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_witness_stmt` CHECK (
        `statement` IS NULL OR (CHAR_LENGTH(`statement`) >= 10 AND CHAR_LENGTH(`statement`) <= 500))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Witnesses WITH statements. v2 specified the rule and had no column for it. Restricted read.';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 23: ba_incident_intervention_jnt
-- ---------------------------------------------------------------------------------------------------------
-- An applied intervention as a TRACKED CASE.   Decision D-01.
--
-- v2 stored incident_id, intervention_id and a note. BRD v2 sec.62 recorded that the v1 screens
-- described assigned staff, a scheduled date, a status, progress notes, a completion date and a
-- cancellation justification, and concluded: "this is a significant business requirement to preserve
-- and reconcile in the next schema revision." It is reconciled here, in favour of the business.
--
-- An intervention nobody owns and nothing tracks is a checkbox, not a response — and "incidents go
-- nowhere" is the single business problem this module exists to solve.
--
--   [ASSIGNED] -> [IN_PROGRESS] -> [COMPLETED]     completed_on + completion_notes required
--        +--------------+--------> [CANCELLED]     cancellation_reason required
--
-- OVERDUE IS DERIVED, NEVER STORED (Solution_Design SD-05):
--     status IN ('assigned','in_progress') AND scheduled_date < CURDATE()
--   A stored is_overdue flag would depend on a nightly job to keep it true, and a flag that depends on
--   a job is a flag that is wrong between runs. v_ba_open_interventions exposes it.
--
-- outcome (BR-BA-082) is optional and prompted at completion. Over two sessions it makes "which
--   interventions actually work in THIS school" answerable (ENH-BA-013). It is confounded by severity
--   and by selection, so it must be presented as a prompt for discussion, never as a causal claim.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_incident_intervention_jnt` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_id`         BIGINT UNSIGNED NOT NULL,
  `intervention_id`     BIGINT UNSIGNED NOT NULL,
  `assigned_to`         INT UNSIGNED    DEFAULT NULL COMMENT 'v7.0 — FK sch_employees.id. Mandatory when the master requires an owner',
  `assigned_by`         INT UNSIGNED    DEFAULT NULL COMMENT 'v7.0 — FK sch_employees.id',
  `scheduled_date`      DATE            DEFAULT NULL COMMENT 'v7.0 — defaults to incident_date + default_due_days',
  `status`              ENUM('assigned','in_progress','completed','cancelled') NOT NULL DEFAULT 'assigned' COMMENT 'v7.0',
  `started_at`          TIMESTAMP       NULL DEFAULT NULL,
  `completed_on`        DATE            DEFAULT NULL COMMENT 'v7.0 — mandatory to complete',
  `completion_notes`    TEXT            DEFAULT NULL COMMENT 'v7.0 — mandatory to complete (BR-BA-078)',
  `cancellation_reason` VARCHAR(500)    DEFAULT NULL COMMENT 'v7.0 — mandatory to cancel (BR-BA-079)',
  `outcome`             ENUM('effective','partially_effective','not_effective','not_assessed')
                          NOT NULL DEFAULT 'not_assessed' COMMENT 'v7.0 — prompted at completion (BR-BA-082)',
  `notes`               VARCHAR(500)    DEFAULT NULL COMMENT 'Context recorded at assignment',
  `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `updated_by`          INT UNSIGNED NOT NULL,
  `created_at`          TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`          TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`          DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`            DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_inc_int` (`incident_id`, `intervention_id`, `uq_guard`),
  KEY `idx_ba_ii_worklist` (`assigned_to`, `status`, `scheduled_date`) COMMENT 'Owner worklist + overdue sweep',
  KEY `idx_ba_ii_incident` (`incident_id`, `status`),
  KEY `idx_ba_ii_interv`   (`intervention_id`, `outcome`)              COMMENT 'Effectiveness analytics',
  CONSTRAINT `fk_ba_ii_incident` FOREIGN KEY (`incident_id`)     REFERENCES `ba_incidents` (`id`)     ON DELETE CASCADE,
  CONSTRAINT `fk_ba_ii_interv`   FOREIGN KEY (`intervention_id`) REFERENCES `ba_interventions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_ii_owner`    FOREIGN KEY (`assigned_to`)     REFERENCES `sch_employees` (`id`)    ON DELETE SET NULL,
  CONSTRAINT `fk_ba_ii_assigner` FOREIGN KEY (`assigned_by`)     REFERENCES `sch_employees` (`id`)    ON DELETE SET NULL,
  CONSTRAINT `fk_ba_ii_created`  FOREIGN KEY (`created_by`)      REFERENCES `sys_users` (`id`)        ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_ii_completed` CHECK (
        `status` <> 'completed'
     OR (`completed_on` IS NOT NULL AND `completion_notes` IS NOT NULL AND CHAR_LENGTH(`completion_notes`) >= 5)),
  CONSTRAINT `chk_ba_ii_cancelled` CHECK (
        `status` <> 'cancelled'
     OR (`cancellation_reason` IS NOT NULL AND CHAR_LENGTH(`cancellation_reason`) >= 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Applied interventions as tracked cases: owner, due date, status, outcome (D-01).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 24: ba_intervention_progress                                              [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Append-only progress log for an applied intervention.   BR-BA-081.
--
-- Progress had nowhere to live in v2 — there was one `notes` column, so the second update overwrote
-- the first. What a school actually DID, step by step, is exactly the part that must accumulate.
--
-- INSERT-ONLY: trg_ba_progress_bu / _bd reject UPDATE and DELETE.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_intervention_progress` (
  `id`                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_intervention_id` BIGINT UNSIGNED NOT NULL,
  `progress_date`          DATE         NOT NULL,
  `note`                   TEXT         NOT NULL,
  `status_at_entry`        ENUM('assigned','in_progress','completed','cancelled') NOT NULL,
  `recorded_by`            INT UNSIGNED NOT NULL COMMENT 'FK sch_employees.id',
  `recorded_at`            TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `is_active`              TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`             INT UNSIGNED NOT NULL,
  `created_at`             TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_prog_parent` (`incident_intervention_id`, `progress_date`),
  KEY `idx_ba_prog_author` (`recorded_by`),
  CONSTRAINT `fk_ba_prog_parent`  FOREIGN KEY (`incident_intervention_id`) REFERENCES `ba_incident_intervention_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ba_prog_author`  FOREIGN KEY (`recorded_by`)              REFERENCES `sch_employees` (`id`)                ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_prog_created` FOREIGN KEY (`created_by`)               REFERENCES `sys_users` (`id`)                    ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_prog_note` CHECK (CHAR_LENGTH(`note`) >= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='INSERT-ONLY intervention progress log (BR-BA-081).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 25: ba_incident_followups                                                 [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Append-only follow-up log.   REQ-BA-025.
--
-- v2 had one `follow_up_notes TEXT` column on the incident. The audit recorded (BUG-BA-009) that each
-- new note OVERWROTE the last. The history of what a school did about a child's behaviour is precisely
-- the part that must not be overwritten — it is the record that gets read in a disciplinary review, a
-- parent dispute or a transfer certificate two years later.
--
-- The incident keeps is_follow_up_required and the NEXT follow_up_date; every entry lives here.
--
-- INSERT-ONLY: trg_ba_followup_bu / _bd reject UPDATE and DELETE.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_incident_followups` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_id`      BIGINT UNSIGNED NOT NULL,
  `followup_date`    DATE         NOT NULL,
  `note`             TEXT         NOT NULL,
  `outcome`          ENUM('improved','no_change','deteriorated','not_assessed') NOT NULL DEFAULT 'not_assessed',
  `next_followup_date` DATE       DEFAULT NULL COMMENT 'Written back to ba_incidents.follow_up_date by the service',
  `recorded_by`      INT UNSIGNED NOT NULL COMMENT 'FK sch_employees.id',
  `recorded_at`      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `is_active`        TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`       INT UNSIGNED NOT NULL,
  `created_at`       TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_fup_incident` (`incident_id`, `followup_date`),
  KEY `idx_ba_fup_author`   (`recorded_by`),
  CONSTRAINT `fk_ba_fup_incident` FOREIGN KEY (`incident_id`) REFERENCES `ba_incidents` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_ba_fup_author`   FOREIGN KEY (`recorded_by`) REFERENCES `sch_employees` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_fup_created`  FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_fup_note` CHECK (CHAR_LENGTH(`note`) >= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='INSERT-ONLY follow-up log. v2 overwrote each note with the next (BUG-BA-009).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 26: ba_incident_attachments                                               [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Relational evidence, replacing ba_incidents.attachments_json.   REQ-BA-024.
--
-- WHY A TABLE AND NOT JSON. A JSON array cannot be indexed, counted, permission-checked per file, or
-- reconciled against media storage when a file is purged. "How many incidents have photographic
-- evidence?" and "which evidence files reference a media id that no longer exists?" should be queries,
-- not scans of every incident row.
--
-- BR-BA-074: attachment access follows incident access, with the additional rule that evidence on a
-- case involving multiple students is visible to STAFF ROLES ONLY, never to any parent.
--
-- The bytes live in Prime-AI media storage. This table holds references and metadata only.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_incident_attachments` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `incident_id`      BIGINT UNSIGNED NOT NULL,
  `media_id`         BIGINT UNSIGNED DEFAULT NULL COMMENT 'Reference into Prime-AI media storage',
  `file_path`        VARCHAR(500) DEFAULT NULL    COMMENT 'Fallback path when media storage is not used',
  `original_name`    VARCHAR(255) NOT NULL,
  `mime_type`        VARCHAR(100) NOT NULL,
  `file_size_bytes`  INT UNSIGNED NOT NULL,
  `caption`          VARCHAR(255) DEFAULT NULL,
  `is_staff_only`    TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'BR-BA-074 — multi-student evidence is never parent-visible',
  `uploaded_by`      INT UNSIGNED NOT NULL COMMENT 'FK sch_employees.id',
  `uploaded_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`        TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`       INT UNSIGNED NOT NULL,
  `updated_by`       INT UNSIGNED NOT NULL,
  `created_at`       TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`       TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`       DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`         DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  KEY `idx_ba_att_incident` (`incident_id`),
  KEY `idx_ba_att_media`    (`media_id`),
  CONSTRAINT `fk_ba_att_incident` FOREIGN KEY (`incident_id`) REFERENCES `ba_incidents` (`id`)  ON DELETE CASCADE,
  CONSTRAINT `fk_ba_att_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `sch_employees` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_att_created`  FOREIGN KEY (`created_by`)  REFERENCES `sys_users` (`id`)     ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_att_ref` CHECK (`media_id` IS NOT NULL OR `file_path` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Relational evidence. Replaces attachments_json, which could not be indexed or gated.';


-- =========================================================================================================
-- SECTION 7 — LAYER 7: OPERATIONS
-- =========================================================================================================


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 27: ba_notifications                                                      [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- THE NOTIFICATION OUTBOX.   REQ-BA-017, BR-BA-013 / 083 / 084.
--
-- WHY THIS TABLE IS THE MOST IMPORTANT ADDITION IN v7.0
--   The 2026-06-29 audit finding SEC-BA-001 reads, in full: "Severe-incident parent notification is
--   ENTIRELY ABSENT (REQ-BA-015 / BR-BA-013) — no Notification module call, no event, anywhere.
--   parent_notification_threshold is dead config and is_notified is never written."
--
--   The requirement was in the FRD, in the BRD, and on the Configuration screen. It was never built,
--   and nothing anywhere noticed, because a BOOLEAN gave the obligation nowhere to live. A boolean can
--   express "we tried and it worked". It cannot express "we tried three times, the parent's number is
--   wrong, and nobody knows" — and THAT is the state that matters. A school believing a parent was
--   informed about a serious incident, when they were not, is worse than a school knowing the message
--   failed.
--
-- HOW IT WORKS
--   1. BaNotificationService::evaluate() writes one PENDING row per recipient per channel.
--   2. DispatchNotificationJob hands the row to the Notification module and writes back the outcome.
--   3. Failures retry with backoff to a bounded attempt count, then rest as 'failed' and appear on the
--      Notification Outbox screen, where they can be retried by hand (BR-BA-083).
--
--   BA's responsibility ends at recording the obligation and its outcome. BA implements no transport.
--
-- BR-BA-084 — NO DUPLICATE ALERTS. uq_ba_notif_dedupe makes re-saving an incident incapable of
--   producing a second alert; only a severity ESCALATION creates a new obligation, and then only if
--   the new severity crosses the threshold and the previous one did not. Enforcing this with a UNIQUE
--   key rather than a service check means a retry storm or a double-clicked button cannot cause a
--   parent to receive the same alert twice.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_notifications` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_type`      ENUM('incident_severity','incident_escalation','incident_critical',
                         'positive_incident','assessment_deadline','assessment_overdue',
                         'intervention_assigned','intervention_overdue','review_pending',
                         'daily_digest','export_ready') NOT NULL,
  `entity_type`     ENUM('incident','assessment','intervention','period','export','student') NOT NULL,
  `entity_id`       BIGINT UNSIGNED NOT NULL,
  `dedupe_key`      VARCHAR(120) NOT NULL COMMENT 'event_type + entity + recipient + severity-at-trigger (BR-BA-084)',
  `recipient_type`  ENUM('parent','employee','role') NOT NULL,
  `recipient_id`    INT UNSIGNED DEFAULT NULL COMMENT 'std_students.id for parent-of-student, sch_employees.id for employee',
  `recipient_role`  VARCHAR(50)  DEFAULT NULL COMMENT 'Used when recipient_type = role',
  `channel`         ENUM('in_app','email','sms','push') NOT NULL DEFAULT 'in_app',
  `subject`         VARCHAR(255) DEFAULT NULL,
  `payload_json`    JSON         DEFAULT NULL COMMENT 'Rendered variables handed to the Notification module',
  `status`          ENUM('pending','sent','failed','suppressed') NOT NULL DEFAULT 'pending',
  `attempt_count`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `last_attempt_at` TIMESTAMP    NULL DEFAULT NULL,
  `sent_at`         TIMESTAMP    NULL DEFAULT NULL,
  `failure_reason`  VARCHAR(500) DEFAULT NULL COMMENT 'Visible on the Outbox screen — a silent failure is the danger',
  `suppress_reason` VARCHAR(255) DEFAULT NULL COMMENT 'e.g. duplicate, channel disabled, no contact on file',
  `is_active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED NOT NULL,
  `updated_by`      INT UNSIGNED NOT NULL,
  `created_at`      TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`      DATETIME(6)  NULL DEFAULT NULL,
  `uq_guard`        DATETIME(6)  GENERATED ALWAYS AS (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ba_notif_dedupe` (`dedupe_key`, `channel`, `uq_guard`),
  KEY `idx_ba_notif_queue`  (`status`, `created_at`) COMMENT 'Outbox processing',
  KEY `idx_ba_notif_entity` (`entity_type`, `entity_id`),
  KEY `idx_ba_notif_recip`  (`recipient_type`, `recipient_id`),
  CONSTRAINT `fk_ba_notif_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_notif_failed` CHECK (`status` <> 'failed' OR `failure_reason` IS NOT NULL),
  CONSTRAINT `chk_ba_notif_recip`  CHECK (`recipient_id` IS NOT NULL OR `recipient_role` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Notification OUTBOX. Replaces a boolean that could not represent a failure (SEC-BA-001).';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 28: ba_report_exports                                                     [NEW IN v7.0]
-- ---------------------------------------------------------------------------------------------------------
-- Every export of behavioural data.   BR-BA-087 (performance) and BR-BA-096 (disclosure).
--
-- One table serves two purposes that turn out to be the same purpose:
--   PERFORMANCE — above ba_config.export_async_row_threshold rows (default 1,000) the export is
--                 queued and the user is notified in-app when the file is ready.
--   COMPLIANCE  — an export of student behavioural records is a DISCLOSURE EVENT. Who took what data,
--                 with which filters, when, and in what format is exactly what an audit asks for.
--
-- Every export is recorded regardless of size, so the disclosure record has no gap for small ones.
-- The generated file expires after ba_config.export_expiry_days; THIS ROW IS RETAINED, because the
-- record of the disclosure must outlive the file.
--
-- is_anonymised records whether the identity-suppressing variant was used (BR-BA-020).
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_report_exports` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_code`     VARCHAR(40)  NOT NULL COMMENT 'RPT-BA-001 .. RPT-BA-010',
  `report_name`     VARCHAR(120) NOT NULL,
  `filters_json`    JSON         DEFAULT NULL COMMENT 'Exactly what was asked for — the disclosure scope',
  `format`          ENUM('pdf','xlsx','csv') NOT NULL DEFAULT 'xlsx',
  `is_anonymised`   TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'BR-BA-020',
  `row_count`       INT UNSIGNED DEFAULT NULL,
  `mode`            ENUM('sync','async') NOT NULL DEFAULT 'sync',
  `status`          ENUM('queued','generating','ready','failed','expired') NOT NULL DEFAULT 'queued',
  `file_path`       VARCHAR(500) DEFAULT NULL,
  `file_size_bytes` INT UNSIGNED DEFAULT NULL,
  `error_message`   TEXT         DEFAULT NULL,
  `requested_by`    INT UNSIGNED NOT NULL COMMENT 'FK sys_users.id — who took the data',
  `requested_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at`    TIMESTAMP    NULL DEFAULT NULL,
  `expires_at`      TIMESTAMP    NULL DEFAULT NULL COMMENT 'The FILE expires; this ROW is retained',
  `ip_address`      VARBINARY(16) DEFAULT NULL,
  `is_active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`      INT UNSIGNED NOT NULL,
  `updated_by`      INT UNSIGNED NOT NULL,
  `created_at`      TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`      TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`      DATETIME(6)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_export_user`   (`requested_by`, `requested_at`),
  KEY `idx_ba_export_status` (`status`, `requested_at`),
  KEY `idx_ba_export_report` (`report_code`),
  CONSTRAINT `fk_ba_export_user`    FOREIGN KEY (`requested_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_export_created` FOREIGN KEY (`created_by`)   REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Export register. Performance routing and the disclosure record are the same mechanism.';


-- ---------------------------------------------------------------------------------------------------------
-- TABLE 29: ba_behaviour_points                                                   [NEW IN v7.0 — OPTIONAL]
-- ---------------------------------------------------------------------------------------------------------
-- OPTIONAL incident-driven points ledger.   Decision D-09.
--
-- DISABLED BY DEFAULT (ba_config.is_behaviour_points_enabled = 0). When off, this table stays empty
-- and nothing reads it. Periodic scores are unaffected.
--
-- WHY IT EXISTS AT ALL. BRD v2 sec.109 asked whether incidents should affect the numeric score and
-- left it open. Two schools will give opposite answers, both defensibly:
--   - Keeping the periodic score clean preserves the distinction between a MEASUREMENT (observed
--     behaviour against criteria) and an EVENT (something that happened once). It also stops the score
--     reacting to reporting rate rather than to behaviour: a diligent teacher who logs everything
--     would otherwise depress their whole class.
--   - A school running a house-points or merit system genuinely wants incidents to count, and will
--     build it in a spreadsheet if the module refuses.
--
-- So: OFF by default, with a defined and auditable mechanism for the school that turns it on — rather
-- than an undefined one that appears in Excel.
--
-- The ledger is append-only in practice (entries are reversed by a compensating negative entry, never
-- edited), which is why `points` may be negative and why there is no update path in the service.
-- Points NEVER modify ba_computed_scores; they are reported alongside it as a separate standing.
-- ---------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ba_behaviour_points` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`          INT UNSIGNED    NOT NULL,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL,
  `incident_id`         BIGINT UNSIGNED DEFAULT NULL COMMENT 'NULL for a manual award or a reversal',
  `points`              SMALLINT        NOT NULL COMMENT 'Positive = merit, negative = demerit. Never zero',
  `reason`              VARCHAR(255)    NOT NULL,
  `entry_type`          ENUM('incident','manual','reversal') NOT NULL DEFAULT 'incident',
  `reverses_id`         BIGINT UNSIGNED DEFAULT NULL COMMENT 'The entry this one compensates',
  `awarded_by`          INT UNSIGNED    NOT NULL COMMENT 'FK sch_employees.id',
  `awarded_at`          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`          INT UNSIGNED NOT NULL,
  `created_at`          TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ba_points_student` (`student_id`, `academic_session_id`),
  KEY `idx_ba_points_incident`(`incident_id`),
  CONSTRAINT `fk_ba_points_student`  FOREIGN KEY (`student_id`)          REFERENCES `std_students` (`id`)                   ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_points_session`  FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)  ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_points_incident` FOREIGN KEY (`incident_id`)         REFERENCES `ba_incidents` (`id`)                   ON DELETE SET NULL,
  CONSTRAINT `fk_ba_points_awarder`  FOREIGN KEY (`awarded_by`)          REFERENCES `sch_employees` (`id`)                  ON DELETE RESTRICT,
  CONSTRAINT `fk_ba_points_reverses` FOREIGN KEY (`reverses_id`)         REFERENCES `ba_behaviour_points` (`id`)            ON DELETE SET NULL,
  CONSTRAINT `fk_ba_points_created`  FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`)                      ON DELETE RESTRICT,
  CONSTRAINT `chk_ba_points_nonzero` CHECK (`points` <> 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='OPTIONAL merit/demerit ledger. OFF by default. Never modifies computed scores (D-09).';


-- =========================================================================================================
-- SECTION 8 — DEFERRED FOREIGN KEYS
-- ba_assessment_periods.snapshot_id and ba_framework_snapshots.period_id reference each other.
-- The snapshot FK is added here, after both tables exist.
-- =========================================================================================================

ALTER TABLE `ba_assessment_periods`
  ADD CONSTRAINT `fk_ba_period_snapshot`
  FOREIGN KEY (`snapshot_id`) REFERENCES `ba_framework_snapshots` (`id`) ON DELETE SET NULL;

ALTER TABLE `ba_computed_scores`
  ADD CONSTRAINT `fk_ba_score_run`
  FOREIGN KEY (`score_run_id`) REFERENCES `ba_score_runs` (`id`) ON DELETE SET NULL;

ALTER TABLE `ba_computed_overall`
  ADD CONSTRAINT `fk_ba_overall_run`
  FOREIGN KEY (`score_run_id`) REFERENCES `ba_score_runs` (`id`) ON DELETE SET NULL;

SET FOREIGN_KEY_CHECKS = 1;


-- =========================================================================================================
-- SECTION 9 — VIEWS
-- Views encapsulate the rules that would otherwise be re-derived, and re-derived DIFFERENTLY, in each
-- of ten reports. Every one of them reads cached or bounded data — none touches ba_assessment_ratings.
-- =========================================================================================================


-- v_ba_student_period_scores
-- Overall + per-category scores for a student-period, with the scale bounds carried alongside so a
-- cross-class report can normalise without a second lookup (needed because ba_class_scale_jnt allows
-- two classes to sit on different scales — see Table 8).
CREATE OR REPLACE VIEW `v_ba_student_period_scores` AS
SELECT
    o.`student_id`,
    o.`period_id`,
    p.`name`                AS `period_name`,
    p.`academic_session_id`,
    p.`status`              AS `period_status`,
    o.`overall_score`,
    o.`normalised_score`    AS `overall_normalised`,
    o.`overall_grade`,
    o.`previous_overall`,
    o.`score_delta`,
    o.`trend`,
    o.`is_at_risk`,
    o.`at_risk_reason`,
    c.`category_id`,
    cat.`code`              AS `category_code`,
    cat.`name`              AS `category_name`,
    cat.`polarity`,
    c.`numeric_score`       AS `category_score`,
    c.`normalised_score`    AS `category_normalised`,
    c.`grade`               AS `category_grade`,
    c.`is_insufficient_data`,
    c.`teacher_count`,
    c.`criteria_rated`,
    c.`criteria_applicable`,
    o.`computed_at`
FROM `ba_computed_overall` o
JOIN `ba_assessment_periods` p ON p.`id` = o.`period_id`
LEFT JOIN `ba_computed_scores` c ON c.`student_id` = o.`student_id`
                                AND c.`period_id`  = o.`period_id`
                                AND c.`deleted_at` IS NULL
LEFT JOIN `ba_categories` cat ON cat.`id` = c.`category_id`
WHERE o.`deleted_at` IS NULL;


-- v_ba_assessment_progress
-- Completion state per assessment. Reads the stored completion_percent rather than counting cells,
-- which is the whole reason that column exists.
CREATE OR REPLACE VIEW `v_ba_assessment_progress` AS
SELECT
    a.`id`                AS `assessment_id`,
    a.`period_id`,
    p.`name`              AS `period_name`,
    p.`deadline`,
    DATEDIFF(p.`deadline`, CURDATE()) AS `days_to_deadline`,
    a.`teacher_id`,
    a.`class_section_id`,
    a.`assessment_scope`,
    a.`subject_id`,
    a.`status`,
    a.`completion_percent`,
    a.`sent_back_count`,
    a.`submitted_at`,
    a.`approved_at`,
    a.`locked_at`,
    CASE
      WHEN a.`status` = 'draft' AND p.`deadline` < CURDATE() THEN 1 ELSE 0
    END                   AS `is_overdue`,
    CASE
      WHEN a.`submitted_at` IS NOT NULL AND DATE(a.`submitted_at`) > p.`deadline` THEN 1 ELSE 0
    END                   AS `was_late`
FROM `ba_assessments` a
JOIN `ba_assessment_periods` p ON p.`id` = a.`period_id`
WHERE a.`deleted_at` IS NULL;


-- v_ba_open_interventions
-- The owner worklist. is_overdue is DERIVED here, never stored (Solution_Design SD-05): a stored flag
-- would depend on a nightly job to keep it true, and would therefore be wrong between runs.
CREATE OR REPLACE VIEW `v_ba_open_interventions` AS
SELECT
    ii.`id`               AS `incident_intervention_id`,
    ii.`incident_id`,
    i.`incident_no`,
    i.`student_id`,
    i.`severity`,
    i.`status`            AS `incident_status`,
    ii.`intervention_id`,
    iv.`name`             AS `intervention_name`,
    iv.`intervention_type`,
    ii.`assigned_to`,
    ii.`scheduled_date`,
    ii.`status`           AS `intervention_status`,
    ii.`outcome`,
    CASE
      WHEN ii.`status` IN ('assigned','in_progress') AND ii.`scheduled_date` < CURDATE()
      THEN 1 ELSE 0
    END                   AS `is_overdue`,
    CASE
      WHEN ii.`status` IN ('assigned','in_progress') AND ii.`scheduled_date` < CURDATE()
      THEN DATEDIFF(CURDATE(), ii.`scheduled_date`) ELSE 0
    END                   AS `days_overdue`
FROM `ba_incident_intervention_jnt` ii
JOIN `ba_incidents` i     ON i.`id`  = ii.`incident_id`
JOIN `ba_interventions` iv ON iv.`id` = ii.`intervention_id`
WHERE ii.`status` IN ('assigned','in_progress')
  AND ii.`deleted_at` IS NULL
  AND i.`deleted_at`  IS NULL;


-- v_ba_incident_summary
-- Per-student incident counts. Feeds the at-risk rule, the dashboard and Class Analysis, so all three
-- necessarily agree.
CREATE OR REPLACE VIEW `v_ba_incident_summary` AS
SELECT
    i.`student_id`,
    COUNT(*)                                                                   AS `total_incidents`,
    SUM(i.`incident_type` = 'negative_incident')                               AS `negative_count`,
    SUM(i.`incident_type` = 'positive_reinforcement')                          AS `positive_count`,
    SUM(i.`severity` = 'minor')                                                AS `minor_count`,
    SUM(i.`severity` = 'moderate')                                             AS `moderate_count`,
    SUM(i.`severity` = 'major')                                                AS `major_count`,
    SUM(i.`severity` = 'critical')                                             AS `critical_count`,
    SUM(i.`status` IN ('open','under_review','action_taken'))                   AS `open_count`,
    SUM(i.`status` IN ('resolved','closed'))                                    AS `resolved_count`,
    MAX(i.`incident_date`)                                                      AS `last_incident_date`,
    AVG(CASE WHEN i.`resolved_at` IS NOT NULL
             THEN DATEDIFF(DATE(i.`resolved_at`), i.`incident_date`) END)       AS `avg_days_to_resolution`
FROM `ba_incidents` i
WHERE i.`deleted_at` IS NULL
  AND i.`status` <> 'cancelled'
GROUP BY i.`student_id`;


-- v_ba_at_risk_students
-- BR-BA-089. The composite rule lives here once, so the dashboard, Class Analysis and the counsellor's
-- register cannot drift apart. is_at_risk / at_risk_reason are written by the score run; this view
-- joins them to the incident side so the reason is legible without a second query.
CREATE OR REPLACE VIEW `v_ba_at_risk_students` AS
SELECT
    o.`student_id`,
    o.`period_id`,
    p.`academic_session_id`,
    o.`overall_score`,
    o.`normalised_score`,
    o.`trend`,
    o.`score_delta`,
    COALESCE(s.`negative_count`, 0)  AS `negative_incidents`,
    COALESCE(s.`major_count`, 0)     AS `major_incidents`,
    COALESCE(s.`critical_count`, 0)  AS `critical_incidents`,
    o.`at_risk_reason`,
    o.`computed_at`
FROM `ba_computed_overall` o
JOIN `ba_assessment_periods` p ON p.`id` = o.`period_id`
LEFT JOIN `v_ba_incident_summary` s ON s.`student_id` = o.`student_id`
WHERE o.`is_at_risk` = 1
  AND o.`deleted_at` IS NULL;


-- =========================================================================================================
-- SECTION 10 — SEED DATA
-- Provisioned during tenant onboarding. Idempotent: every row is keyed on a stable `code`.
--
--   1 rating scale (5-Point) + 5 levels
--   9 categories (5 positive, 4 negative) + 58 criteria — verbatim from the approved framework
--  12 interventions (the 9 originals + 3 added in v7.0)
--  12 comment-bank templates
--
-- ba_config IS DELIBERATELY NOT SEEDED. It is auto-created for a session on first access using module
-- defaults, so a school never inherits another school's policy by accident. Result integration is OFF.
-- =========================================================================================================

SET @sys := 1;   -- sys_users.id of the system/bootstrap user
SET @now := NOW();


-- ---- Rating scale + levels -------------------------------------------------------------------------------
INSERT INTO `ba_rating_scales`
  (`id`,`code`,`name`,`description`,`grade_type`,`min_rating`,`max_rating`,`is_default`,`is_active`,
   `created_by`,`updated_by`,`created_at`,`updated_at`)
VALUES
  (1,'5_POINT','5-Point Behavioural Scale',
   'Default behavioural rating scale: Unsatisfactory(1) through Outstanding(5).',
   'letter',1.00,5.00,1,1,@sys,@sys,@now,@now)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `ba_rating_levels`
  (`rating_scale_id`,`label`,`numeric_value`,`description`,`grade_label`,`sort_order`,`is_active`,
   `created_by`,`updated_by`,`created_at`,`updated_at`)
VALUES
  (1,'Unsatisfactory',   1.00,'Consistently falls short of expectations','D',1,1,@sys,@sys,@now,@now),
  (1,'Needs Improvement',2.00,'Occasionally meets expectations','C',        2,1,@sys,@sys,@now,@now),
  (1,'Good',             3.00,'Generally meets expectations','B',           3,1,@sys,@sys,@now,@now),
  (1,'Very Good',        4.00,'Frequently exceeds expectations','A',        4,1,@sys,@sys,@now,@now),
  (1,'Outstanding',      5.00,'Consistently exceeds expectations','A+',     5,1,@sys,@sys,@now,@now)
ON DUPLICATE KEY UPDATE `description`=VALUES(`description`);


-- ---- Categories ------------------------------------------------------------------------------------------
-- All 9 carry weight 100.00, i.e. equal proportional contribution. Weights are normalised at
-- computation (BR-BA-036), so 100 x 9 means "one ninth each", not "900%".
INSERT INTO `ba_categories`
  (`id`,`parent_id`,`code`,`name`,`description`,`polarity`,`weight`,`sort_order`,`is_system`,`is_active`,
   `created_by`,`updated_by`,`created_at`,`updated_at`)
VALUES
  (1,NULL,'CLS_ENG','Classroom Engagement',
     'Measures how actively and constructively a student participates in the learning environment.',
     'positive',100.00,1,1,1,@sys,@sys,@now,@now),
  (2,NULL,'RES_RSP','Respect and Responsibility',
     'Evaluates a student ability to treat others with dignity and take ownership of their actions.',
     'positive',100.00,2,1,1,@sys,@sys,@now,@now),
  (3,NULL,'COOP_COL','Cooperation and Collaboration',
     'Assesses teamwork skills and the ability to work harmoniously with others.',
     'positive',100.00,3,1,1,@sys,@sys,@now,@now),
  (4,NULL,'EMO_SOC','Emotional and Social Development',
     'Tracks emotional intelligence, self-regulation and interpersonal maturity.',
     'positive',100.00,4,1,1,@sys,@sys,@now,@now),
  (5,NULL,'LEAD_INI','Leadership and Initiative',
     'Recognises students who proactively contribute to school life and inspire others.',
     'positive',100.00,5,1,1,@sys,@sys,@now,@now),
  (6,NULL,'DISRUPT','Disruptive Behaviours',
     'Records behaviours that hinder the learning environment for self or others.',
     'negative',100.00,6,1,1,@sys,@sys,@now,@now),
  (7,NULL,'AGGRESS','Aggressive or Bullying Behaviours',
     'Captures serious behavioural concerns involving harm or intimidation.',
     'negative',100.00,7,1,1,@sys,@sys,@now,@now),
  (8,NULL,'ACAD_MIS','Academic Misconduct',
     'Tracks dishonesty and non-compliance in academic contexts.',
     'negative',100.00,8,1,1,@sys,@sys,@now,@now),
  (9,NULL,'HLTH_SAF','Health and Safety Violations',
     'Behaviours that endanger physical safety on school premises.',
     'negative',100.00,9,1,1,@sys,@sys,@now,@now)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `description`=VALUES(`description`);


-- ---- Criteria (58) ---------------------------------------------------------------------------------------
-- Criterion weights are 100 / (criteria in category), which is why an 8-criterion category shows 12.50
-- and a 7-criterion category shows 14.29. They do not have to total exactly 100 — the engine
-- normalises (BR-BA-036, Decision D-10). The UI warns when a category strays far from 100; it does
-- not block saving, because the engine must never depend on an administrator's arithmetic.
INSERT INTO `ba_criteria`
  (`category_id`,`code`,`name`,`weight`,`sort_order`,`is_system`,`is_active`,
   `created_by`,`updated_by`,`created_at`,`updated_at`)
VALUES
  -- 1. Classroom Engagement (8) — positive
  (1,'CLS_ENG_01','Active participation in class discussions and oral activities',12.50,1,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_02','Asking thoughtful, relevant, and clarifying questions',12.50,2,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_03','Paying sustained attention to instructions, lessons, and demonstrations',12.50,3,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_04','Completing classwork, assignments, and homework on time and with care',12.50,4,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_05','Demonstrating effort, persistence, and resilience when facing academic challenges',12.50,5,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_06','Showing curiosity and initiative in exploring topics beyond the syllabus',12.50,6,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_07','Bringing required materials and being prepared for class',12.50,7,1,1,@sys,@sys,@now,@now),
  (1,'CLS_ENG_08','Responding constructively to teacher feedback and corrections',12.50,8,1,1,@sys,@sys,@now,@now),
  -- 2. Respect and Responsibility (8) — positive
  (2,'RES_RSP_01','Respecting teachers, peers, support staff, and visitors',12.50,1,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_02','Following school rules, classroom procedures, and safety guidelines',12.50,2,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_03','Taking responsibility for personal actions, mistakes, and belongings',12.50,3,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_04','Being courteous, polite, and using appropriate language at all times',12.50,4,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_05','Demonstrating honesty and integrity in all interactions',12.50,5,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_06','Respecting school property, shared resources, and the environment',12.50,6,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_07','Being punctual to school and classes',12.50,7,1,1,@sys,@sys,@now,@now),
  (2,'RES_RSP_08','Maintaining personal hygiene and adhering to the dress code',12.50,8,1,1,@sys,@sys,@now,@now),
  -- 3. Cooperation and Collaboration (7) — positive
  (3,'COOP_COL_01','Working effectively and equitably in group assignments and projects',14.29,1,1,1,@sys,@sys,@now,@now),
  (3,'COOP_COL_02','Helping classmates who are struggling without being asked',14.29,2,1,1,@sys,@sys,@now,@now),
  (3,'COOP_COL_03','Sharing ideas, perspectives, and resources respectfully',14.29,3,1,1,@sys,@sys,@now,@now),
  (3,'COOP_COL_04','Actively participating in school events, assemblies, and extracurricular activities',14.29,4,1,1,@sys,@sys,@now,@now),
  (3,'COOP_COL_05','Accepting and respecting diverse viewpoints and cultural differences',14.29,5,1,1,@sys,@sys,@now,@now),
  (3,'COOP_COL_06','Mediating or de-escalating minor peer conflicts constructively',14.29,6,1,1,@sys,@sys,@now,@now),
  (3,'COOP_COL_07','Contributing to a positive classroom atmosphere',14.26,7,1,1,@sys,@sys,@now,@now),
  -- 4. Emotional and Social Development (6) — positive
  (4,'EMO_SOC_01','Demonstrating empathy and compassion towards peers',16.67,1,1,1,@sys,@sys,@now,@now),
  (4,'EMO_SOC_02','Managing emotions appropriately under stress or frustration',16.67,2,1,1,@sys,@sys,@now,@now),
  (4,'EMO_SOC_03','Accepting constructive criticism gracefully',16.67,3,1,1,@sys,@sys,@now,@now),
  (4,'EMO_SOC_04','Showing self-confidence without arrogance',16.67,4,1,1,@sys,@sys,@now,@now),
  (4,'EMO_SOC_05','Resolving personal conflicts through dialogue rather than aggression',16.67,5,1,1,@sys,@sys,@now,@now),
  (4,'EMO_SOC_06','Demonstrating patience and turn-taking in conversations and activities',16.65,6,1,1,@sys,@sys,@now,@now),
  -- 5. Leadership and Initiative (6) — positive
  (5,'LEAD_INI_01','Volunteering for classroom or school responsibilities',16.67,1,1,1,@sys,@sys,@now,@now),
  (5,'LEAD_INI_02','Taking initiative to organise or lead group activities',16.67,2,1,1,@sys,@sys,@now,@now),
  (5,'LEAD_INI_03','Mentoring or tutoring fellow students',16.67,3,1,1,@sys,@sys,@now,@now),
  (5,'LEAD_INI_04','Demonstrating good sportsmanship in competitions',16.67,4,1,1,@sys,@sys,@now,@now),
  (5,'LEAD_INI_05','Representing school values in external events or inter-school activities',16.67,5,1,1,@sys,@sys,@now,@now),
  (5,'LEAD_INI_06','Proposing constructive ideas for class or school improvement',16.65,6,1,1,@sys,@sys,@now,@now),
  -- 6. Disruptive Behaviours (7) — negative
  (6,'DISRUPT_01','Talking out of turn or disrupting ongoing lessons',14.29,1,1,1,@sys,@sys,@now,@now),
  (6,'DISRUPT_02','Creating unnecessary noise, distractions, or disturbances',14.29,2,1,1,@sys,@sys,@now,@now),
  (6,'DISRUPT_03','Not following instructions, rules, or safety procedures',14.29,3,1,1,@sys,@sys,@now,@now),
  (6,'DISRUPT_04','Being consistently off-task, inattentive, or not participating',14.29,4,1,1,@sys,@sys,@now,@now),
  (6,'DISRUPT_05','Using mobile phones or electronic devices without permission',14.29,5,1,1,@sys,@sys,@now,@now),
  (6,'DISRUPT_06','Leaving the classroom without permission',14.29,6,1,1,@sys,@sys,@now,@now),
  (6,'DISRUPT_07','Eating or drinking in class without permission',14.26,7,1,1,@sys,@sys,@now,@now),
  -- 7. Aggressive or Bullying Behaviours (6) — negative
  (7,'AGGRESS_01','Physical aggression (hitting, pushing, fighting) towards others',16.67,1,1,1,@sys,@sys,@now,@now),
  (7,'AGGRESS_02','Verbal aggression (shouting, threatening, using abusive language)',16.67,2,1,1,@sys,@sys,@now,@now),
  (7,'AGGRESS_03','Bullying or teasing other students (physical, verbal, or cyber)',16.67,3,1,1,@sys,@sys,@now,@now),
  (7,'AGGRESS_04','Harassment, discrimination, or exclusion based on caste, religion, gender, or appearance',16.67,4,1,1,@sys,@sys,@now,@now),
  (7,'AGGRESS_05','Intimidating, coercing, or blackmailing peers',16.67,5,1,1,@sys,@sys,@now,@now),
  (7,'AGGRESS_06','Damaging or stealing school or peer property',16.65,6,1,1,@sys,@sys,@now,@now),
  -- 8. Academic Misconduct (6) — negative
  (8,'ACAD_MIS_01','Cheating during exams or assessments',16.67,1,1,1,@sys,@sys,@now,@now),
  (8,'ACAD_MIS_02','Plagiarism or copying homework/assignments',16.67,2,1,1,@sys,@sys,@now,@now),
  (8,'ACAD_MIS_03','Repeatedly not completing or submitting assignments',16.67,3,1,1,@sys,@sys,@now,@now),
  (8,'ACAD_MIS_04','Forging signatures or tampering with academic records',16.67,4,1,1,@sys,@sys,@now,@now),
  (8,'ACAD_MIS_05','Disrespectful or defiant behaviour towards teachers during instruction',16.67,5,1,1,@sys,@sys,@now,@now),
  (8,'ACAD_MIS_06','Providing false information or making dishonest excuses',16.65,6,1,1,@sys,@sys,@now,@now),
  -- 9. Health and Safety Violations (4) — negative
  (9,'HLTH_SAF_01','Engaging in dangerous play or stunts on school premises',25.00,1,1,1,@sys,@sys,@now,@now),
  (9,'HLTH_SAF_02','Possession or use of prohibited substances on campus',25.00,2,1,1,@sys,@sys,@now,@now),
  (9,'HLTH_SAF_03','Violating laboratory, workshop, or sports safety rules',25.00,3,1,1,@sys,@sys,@now,@now),
  (9,'HLTH_SAF_04','Encouraging or daring peers to engage in risky behaviours',25.00,4,1,1,@sys,@sys,@now,@now)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `weight`=VALUES(`weight`);


-- ---- Interventions (12) ----------------------------------------------------------------------------------
-- The 9 originals plus 3 added in v7.0, marked below. default_due_days and requires_owner are the
-- v7.0 columns that make case management work (Decision D-01).
INSERT INTO `ba_interventions`
  (`code`,`name`,`description`,`intervention_type`,`default_due_days`,`requires_owner`,
   `requires_parent_meeting`,`sort_order`,`is_system`,`is_active`,
   `created_by`,`updated_by`,`created_at`,`updated_at`)
VALUES
  ('AWARD_CERT','Award/Certificate','Formal recognition through certificate or award for positive behaviour','reward',14,0,0,1,1,1,@sys,@sys,@now,@now),
  ('PUB_RECOG','Public Recognition','Public acknowledgement in assembly or class for exemplary behaviour','reward',7,0,0,2,1,1,@sys,@sys,@now,@now),
  ('EXTRA_PRIV','Extra Privileges','Granting additional privileges as positive reinforcement','reward',7,0,0,3,1,1,@sys,@sys,@now,@now),
  ('VERBAL_WARN','Verbal Warning','Verbal caution to the student about the behaviour','corrective',1,1,0,4,1,1,@sys,@sys,@now,@now),
  ('WRITTEN_WARN','Written Warning','Formal written warning documented in the student record','corrective',3,1,0,5,1,1,@sys,@sys,@now,@now),
  ('DETENTION','Detention','Student required to stay after school hours as a corrective measure','corrective',7,1,0,6,1,1,@sys,@sys,@now,@now),
  ('SUSPENSION','Suspension','Temporary suspension from school for serious behavioural violations','corrective',3,1,1,7,1,1,@sys,@sys,@now,@now),
  ('PARENT_MEET','Parent Meeting','Meeting with parents/guardians to discuss concerns and agree an action plan','counselling',7,1,1,8,1,1,@sys,@sys,@now,@now),
  ('COUNS_REF','Counselling Referral','Referral to the school counsellor for behavioural support and guidance','counselling',14,1,0,9,1,1,@sys,@sys,@now,@now),
  -- v7.0 additions
  ('BEHAV_CONTRACT','Behaviour Contract','A written, time-boxed agreement with the student setting specific behavioural goals and review dates','corrective',30,1,1,10,1,1,@sys,@sys,@now,@now),
  ('RESTORATIVE','Restorative Conversation','A facilitated conversation between those affected, focused on repair rather than punishment','counselling',7,1,0,11,1,1,@sys,@sys,@now,@now),
  ('PEER_MEDIATE','Peer Mediation','Structured mediation between students, supervised by a trained staff member','counselling',7,1,0,12,1,1,@sys,@sys,@now,@now)
ON DUPLICATE KEY UPDATE `description`=VALUES(`description`), `default_due_days`=VALUES(`default_due_days`);


-- ---- Comment bank (12) -----------------------------------------------------------------------------------
-- Placeholders: {student} = preferred/first name; {he_she} / {his_her} resolve from StudentProfile and
-- default to the NEUTRAL form (they / their) when gender is unrecorded (BR-BA-039). These are starting
-- points; the teacher edits and owns the result (BR-BA-038).
INSERT INTO `ba_comment_bank`
  (`category_id`,`code`,`sentiment`,`applies_to`,`template_text`,`sort_order`,`is_system`,`is_active`,
   `created_by`,`updated_by`,`created_at`,`updated_at`)
VALUES
  (NULL,'OV_POS_01','positive','overall_remark','{student} has had an excellent term. {he_she} engages readily, treats others with consistent respect, and can be relied on to do the right thing without being asked.',1,1,1,@sys,@sys,@now,@now),
  (NULL,'OV_POS_02','positive','overall_remark','{student} is a settled and constructive member of the class. {his_her} willingness to help classmates has been noticed by several teachers.',2,1,1,@sys,@sys,@now,@now),
  (NULL,'OV_NEU_01','neutral','overall_remark','{student} has met behavioural expectations this term. {he_she} works steadily and responds well when given clear structure.',3,1,1,@sys,@sys,@now,@now),
  (NULL,'OV_DEV_01','developmental','overall_remark','{student} has found parts of this term difficult. With continued support around self-regulation, and the strategies agreed with {his_her} parents, we expect steady improvement.',4,1,1,@sys,@sys,@now,@now),
  (NULL,'OV_DEV_02','developmental','overall_remark','{student} is capable of much more than {he_she} has shown this term. The pattern is one of inconsistency rather than unwillingness, and short, specific targets are likely to help.',5,1,1,@sys,@sys,@now,@now),
  (1,'CR_ENG_POS','positive','criterion_remark','{student} contributes thoughtfully and listens as well as {he_she} speaks.',6,1,1,@sys,@sys,@now,@now),
  (1,'CR_ENG_DEV','developmental','criterion_remark','{student} has the ideas but rarely offers them. Encouraging {him_her} to speak first in small groups would help.',7,1,1,@sys,@sys,@now,@now),
  (2,'CR_RES_POS','positive','criterion_remark','{student} is courteous to staff and peers alike, and takes ownership when {he_she} gets something wrong.',8,1,1,@sys,@sys,@now,@now),
  (3,'CR_COOP_POS','positive','criterion_remark','{student} works well in a group and makes room for quieter members.',9,1,1,@sys,@sys,@now,@now),
  (4,'CR_EMO_DEV','developmental','criterion_remark','{student} finds frustration hard to manage in the moment. The agreed pause-and-return strategy is beginning to help.',10,1,1,@sys,@sys,@now,@now),
  (5,'CR_LEAD_POS','positive','criterion_remark','{student} takes on responsibility willingly and follows through without reminders.',11,1,1,@sys,@sys,@now,@now),
  (6,'CR_DIS_DEV','developmental','criterion_remark','{student} is often off-task in the second half of a lesson. Seating and a mid-lesson check-in are being trialled.',12,1,1,@sys,@sys,@now,@now)
ON DUPLICATE KEY UPDATE `template_text`=VALUES(`template_text`);


-- =========================================================================================================
-- SECTION 20 — INTEGRITY TRIGGERS
-- =========================================================================================================
--
-- READ THIS BEFORE OMITTING THIS SECTION.
--
-- The 2026-06-29 audit assessed 30 business rules against the live code: 15 ENFORCED, 6 PARTIAL,
-- 9 MISSING. The missing nine were not obscure. They included "locked assessments cannot be edited",
-- "a scale in use cannot change shape", "the permissive class-mapping default", and "severe incidents
-- notify parents". Every one of them had been written down, agreed, and then simply not built — and
-- nothing failed, so nothing noticed.
--
-- The triggers below make the INVARIANTS unbypassable. They bind a controller, a queued job, a
-- console command, a seeder, a data-fix script and a future developer equally. Service code performs
-- the same checks FIRST so that users get clean, specific messages; these are the backstop, not the
-- user experience.
--
-- WHAT IS *NOT* HERE, ON PURPOSE:
--   - anything that depends on WHO is asking (that is a Policy);
--   - anything that depends on configuration (that is a Service);
--   - anything requiring judgement (reviewer quality signals ADVISE, they never block).
--
-- Every trigger raises SIGNAL SQLSTATE '45000' with a message prefixed 'BA:' so the application layer
-- can map it to user-facing text.
--
-- OMITTING THIS SECTION leaves every table, key, foreign key and CHECK valid, and the schema will
-- load and work. It also reproduces exactly the conditions under which nine agreed rules went missing.
-- The recommendation is to keep it.
-- =========================================================================================================

DELIMITER $$

-- ---------------------------------------------------------------------------------------------------------
-- 20.1  RATING SCALE — numeric shape frozen once in use  (BR-BA-029, audit DATA-BA-001)
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_scale_locked_bu`$$
CREATE TRIGGER `trg_ba_scale_locked_bu` BEFORE UPDATE ON `ba_rating_scales`
FOR EACH ROW
BEGIN
    IF OLD.`is_locked` = 1
       AND (NEW.`min_rating` <> OLD.`min_rating` OR NEW.`max_rating` <> OLD.`max_rating`) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: this rating scale is in use; its numeric range cannot change (BR-BA-029). Create a new scale instead.';
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.2  RATING LEVELS — value must lie inside the parent scale  (BR-BA-027, audit VAL-BA-002)
--       A CHECK constraint cannot express this: it would have to read another row.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_level_range_bi`$$
CREATE TRIGGER `trg_ba_level_range_bi` BEFORE INSERT ON `ba_rating_levels`
FOR EACH ROW
BEGIN
    DECLARE v_min DECIMAL(4,2);
    DECLARE v_max DECIMAL(4,2);
    SELECT `min_rating`, `max_rating` INTO v_min, v_max
      FROM `ba_rating_scales` WHERE `id` = NEW.`rating_scale_id`;
    IF v_min IS NOT NULL AND (NEW.`numeric_value` < v_min OR NEW.`numeric_value` > v_max) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: rating level value falls outside the scale range (BR-BA-027).';
    END IF;
END$$

DROP TRIGGER IF EXISTS `trg_ba_level_range_bu`$$
CREATE TRIGGER `trg_ba_level_range_bu` BEFORE UPDATE ON `ba_rating_levels`
FOR EACH ROW
BEGIN
    DECLARE v_min    DECIMAL(4,2);
    DECLARE v_max    DECIMAL(4,2);
    DECLARE v_locked TINYINT(1);
    SELECT `min_rating`, `max_rating`, `is_locked` INTO v_min, v_max, v_locked
      FROM `ba_rating_scales` WHERE `id` = NEW.`rating_scale_id`;
    IF v_locked = 1 AND NEW.`numeric_value` <> OLD.`numeric_value` THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: this scale is in use; a level value cannot change (BR-BA-029). Labels may still be edited.';
    END IF;
    IF v_min IS NOT NULL AND (NEW.`numeric_value` < v_min OR NEW.`numeric_value` > v_max) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: rating level value falls outside the scale range (BR-BA-027).';
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.3  ASSESSMENT PERIOD — the state machine  (BR-BA-044, audit BUG-BA-002)
--
--       Legal:   open -> closed | closed -> open | closed -> locked
--       Illegal: open -> locked (must close first) | anything out of locked (terminal)
--
--       v2 shipped the inverse of this. This trigger is the specification.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_period_status_bu`$$
CREATE TRIGGER `trg_ba_period_status_bu` BEFORE UPDATE ON `ba_assessment_periods`
FOR EACH ROW
BEGIN
    IF NEW.`status` <> OLD.`status` THEN
        IF OLD.`status` = 'locked' THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'BA: a locked period is final and cannot change state (BR-BA-044).';
        END IF;
        IF OLD.`status` = 'open' AND NEW.`status` = 'locked' THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'BA: a period must be closed before it can be locked (BR-BA-044).';
        END IF;
        IF NOT ((OLD.`status` = 'open'   AND NEW.`status` = 'closed')
             OR (OLD.`status` = 'closed' AND NEW.`status` IN ('open','locked'))) THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'BA: illegal assessment-period state transition (BR-BA-044).';
        END IF;
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.4  ASSESSMENT — the state machine, and locked is terminal  (BR-BA-010, BR-BA-052)
--
--       Legal:   draft -> submitted | draft -> reviewed (review disabled, BR-BA-025)
--                submitted -> reviewed | submitted -> draft (send back)
--                reviewed -> draft (send back) | reviewed -> locked
--       Illegal: anything out of locked
--
--       The FIRST block is the important one: once locked, the status, the soft-delete state, the
--       completion figure and the reviewer remark are all frozen. Bookkeeping columns the lock itself
--       writes (updated_at, locked_by, locked_at, snapshot_id) are set during the reviewed -> locked
--       transition, when OLD.status is still 'reviewed', so they are unaffected. That is what makes a
--       published behavioural score defensible.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_assessment_status_bu`$$
CREATE TRIGGER `trg_ba_assessment_status_bu` BEFORE UPDATE ON `ba_assessments`
FOR EACH ROW
BEGIN
    IF OLD.`status` = 'locked'
       AND NOT (NEW.`status` = 'locked'
                AND NEW.`deleted_at` <=> OLD.`deleted_at`
                AND NEW.`completion_percent` = OLD.`completion_percent`
                AND NEW.`reviewer_remarks`   <=> OLD.`reviewer_remarks`) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: this assessment is locked and cannot be modified (BR-BA-010).';
    END IF;

    IF NEW.`status` <> OLD.`status` THEN
        IF NOT ((OLD.`status` = 'draft'     AND NEW.`status` IN ('submitted','reviewed'))
             OR (OLD.`status` = 'submitted' AND NEW.`status` IN ('reviewed','draft'))
             OR (OLD.`status` = 'reviewed'  AND NEW.`status` IN ('locked','draft'))) THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'BA: illegal assessment state transition (BR-BA-052).';
        END IF;
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.5  RATINGS — THE LOCK CASCADE  (BR-BA-045, audit BUG-BA-001)
--
--       THIS IS THE MOST IMPORTANT TRIGGER IN THE FILE.
--
--       v2 checked assessment.status = 'locked' in the UI, and no code ever set that status, so
--       "locked" periods froze nothing and approved scores could be edited out of sync with the cache
--       and the audit trail. The fix is not to remember to set a flag; it is to CHECK THE PARENT AT
--       THE POINT OF WRITE. A rating cannot be written when its assessment is locked, or when its
--       period is closed or locked — no matter who is writing or from where.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_rating_bi`$$
CREATE TRIGGER `trg_ba_rating_bi` BEFORE INSERT ON `ba_assessment_ratings`
FOR EACH ROW
BEGIN
    DECLARE v_astatus VARCHAR(20);
    DECLARE v_pstatus VARCHAR(20);
    SELECT a.`status`, p.`status` INTO v_astatus, v_pstatus
      FROM `ba_assessments` a
      JOIN `ba_assessment_periods` p ON p.`id` = a.`period_id`
     WHERE a.`id` = NEW.`assessment_id`;
    IF v_astatus = 'locked' OR v_pstatus IN ('closed','locked') THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: ratings cannot be added — the assessment is locked or the period is closed (BR-BA-045).';
    END IF;
END$$

DROP TRIGGER IF EXISTS `trg_ba_rating_bu`$$
CREATE TRIGGER `trg_ba_rating_bu` BEFORE UPDATE ON `ba_assessment_ratings`
FOR EACH ROW
BEGIN
    DECLARE v_astatus VARCHAR(20);
    DECLARE v_pstatus VARCHAR(20);
    SELECT a.`status`, p.`status` INTO v_astatus, v_pstatus
      FROM `ba_assessments` a
      JOIN `ba_assessment_periods` p ON p.`id` = a.`period_id`
     WHERE a.`id` = NEW.`assessment_id`;
    IF v_astatus = 'locked' OR v_pstatus = 'locked' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: this rating is locked and cannot be modified (BR-BA-045).';
    END IF;
END$$

DROP TRIGGER IF EXISTS `trg_ba_rating_bd`$$
CREATE TRIGGER `trg_ba_rating_bd` BEFORE DELETE ON `ba_assessment_ratings`
FOR EACH ROW
BEGIN
    DECLARE v_astatus VARCHAR(20);
    SELECT `status` INTO v_astatus FROM `ba_assessments` WHERE `id` = OLD.`assessment_id`;
    IF v_astatus = 'locked' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: ratings under a locked assessment cannot be deleted (BR-BA-045).';
    END IF;
END$$

DROP TRIGGER IF EXISTS `trg_ba_remark_bu`$$
CREATE TRIGGER `trg_ba_remark_bu` BEFORE UPDATE ON `ba_student_remarks`
FOR EACH ROW
BEGIN
    DECLARE v_astatus VARCHAR(20);
    SELECT `status` INTO v_astatus FROM `ba_assessments` WHERE `id` = NEW.`assessment_id`;
    IF v_astatus = 'locked' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: remarks under a locked assessment cannot be modified (BR-BA-045).';
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.6  INCIDENT NUMBER — INC-YYYY-NNNNNN
--
--       Only fires when the application has not supplied one, which it normally does. The MAX+1 read
--       is racy under concurrent inserts; uq_ba_incident_no catches the collision and the service
--       retries. If a deployment's MySQL configuration rejects reading the subject table inside a
--       trigger, drop this trigger and generate the number in BaIncidentService — the UNIQUE key
--       remains the guarantee either way.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_incident_no_bi`$$
CREATE TRIGGER `trg_ba_incident_no_bi` BEFORE INSERT ON `ba_incidents`
FOR EACH ROW
BEGIN
    DECLARE v_year CHAR(4);
    DECLARE v_seq  INT UNSIGNED;
    IF NEW.`incident_no` IS NULL OR NEW.`incident_no` = '' THEN
        SET v_year = DATE_FORMAT(NEW.`incident_date`, '%Y');
        SELECT IFNULL(MAX(CAST(SUBSTRING(`incident_no`, 10) AS UNSIGNED)), 0) + 1
          INTO v_seq
          FROM `ba_incidents`
         WHERE `incident_no` LIKE CONCAT('INC-', v_year, '-%');
        SET NEW.`incident_no` = CONCAT('INC-', v_year, '-', LPAD(v_seq, 6, '0'));
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.7  INCIDENT — core-field immutability, with severity as the single permitted exception
--       (BR-BA-008, BR-BA-072, BR-BA-073)
--
--       Frozen: student_id, incident_date, incident_type, description, location.
--       Severity may change because investigation genuinely reveals that a "moderate" was a "major",
--       and forcing cancel-and-re-raise there would destroy the witness statements and interventions
--       already attached. This trigger permits the column to move; BaIncidentService enforces that
--       only an Admin or Principal may do it, that it may only ESCALATE, and that a reason is written
--       to the audit log.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_incident_bu`$$
CREATE TRIGGER `trg_ba_incident_bu` BEFORE UPDATE ON `ba_incidents`
FOR EACH ROW
BEGIN
    IF NEW.`student_id`    <> OLD.`student_id`
    OR NEW.`incident_date` <> OLD.`incident_date`
    OR NEW.`incident_type` <> OLD.`incident_type`
    OR NEW.`location`      <> OLD.`location`
    OR NOT (NEW.`description` <=> OLD.`description`) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: incident core facts are immutable (BR-BA-008). Cancel this incident with a reason and raise a corrected one.';
    END IF;

    IF OLD.`status` = 'cancelled' AND NEW.`status` <> 'cancelled' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: a cancelled incident cannot be reopened (BR-BA-072).';
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.8  WITNESS — frozen on case closure  (BR-BA-077)
--       A statement that can be revised after the case concludes has no evidential value.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_witness_bu`$$
CREATE TRIGGER `trg_ba_witness_bu` BEFORE UPDATE ON `ba_incident_witnesses_jnt`
FOR EACH ROW
BEGIN
    IF OLD.`frozen_at` IS NOT NULL AND NEW.`frozen_at` IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'BA: this witness record was frozen when the case closed (BR-BA-077).';
    END IF;
END$$

-- ---------------------------------------------------------------------------------------------------------
-- 20.9  IMMUTABLE AND APPEND-ONLY TABLES
--
--       ba_audit_log                  insert-only  (BR-BA-012)
--       ba_framework_snapshots        immutable    (BR-BA-047)
--       ba_assessment_status_history  append-only  (REQ-BA-022)
--       ba_incident_followups         append-only  (REQ-BA-025 — v2 overwrote each note)
--       ba_intervention_progress      append-only  (BR-BA-081)
--
--       A model convention ($timestamps = false, no SoftDeletes) is not enforcement: any raw query,
--       migration or console command bypasses it. These triggers do not.
-- ---------------------------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_ba_audit_bu`$$
CREATE TRIGGER `trg_ba_audit_bu` BEFORE UPDATE ON `ba_audit_log`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: the audit log is insert-only (BR-BA-012).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_audit_bd`$$
CREATE TRIGGER `trg_ba_audit_bd` BEFORE DELETE ON `ba_audit_log`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: audit rows cannot be deleted. Use the archival process (BR-BA-093).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_snapshot_bu`$$
CREATE TRIGGER `trg_ba_snapshot_bu` BEFORE UPDATE ON `ba_framework_snapshots`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: a framework snapshot is immutable (BR-BA-047). Re-lock to create a new version.';
END$$

DROP TRIGGER IF EXISTS `trg_ba_snapshot_bd`$$
CREATE TRIGGER `trg_ba_snapshot_bd` BEFORE DELETE ON `ba_framework_snapshots`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: a framework snapshot cannot be deleted — locked periods depend on it (BR-BA-047).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_status_hist_bu`$$
CREATE TRIGGER `trg_ba_status_hist_bu` BEFORE UPDATE ON `ba_assessment_status_history`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: workflow history is append-only (REQ-BA-022).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_status_hist_bd`$$
CREATE TRIGGER `trg_ba_status_hist_bd` BEFORE DELETE ON `ba_assessment_status_history`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: workflow history cannot be deleted (REQ-BA-022).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_followup_bu`$$
CREATE TRIGGER `trg_ba_followup_bu` BEFORE UPDATE ON `ba_incident_followups`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: follow-up entries are append-only. Add a new entry (REQ-BA-025).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_followup_bd`$$
CREATE TRIGGER `trg_ba_followup_bd` BEFORE DELETE ON `ba_incident_followups`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: follow-up entries cannot be deleted (REQ-BA-025).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_progress_bu`$$
CREATE TRIGGER `trg_ba_progress_bu` BEFORE UPDATE ON `ba_intervention_progress`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: intervention progress notes are append-only (BR-BA-081).';
END$$

DROP TRIGGER IF EXISTS `trg_ba_progress_bd`$$
CREATE TRIGGER `trg_ba_progress_bd` BEFORE DELETE ON `ba_intervention_progress`
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BA: intervention progress notes cannot be deleted (BR-BA-081).';
END$$

DELIMITER ;


-- =========================================================================================================
-- QUICK REFERENCE — how the 29 tables connect
-- =========================================================================================================
--
--  +-- CONFIGURATION (admin, once per session) ------------------------------------------------------+
--  |                                                                                                 |
--  |  ba_rating_scales --+-- ba_rating_levels                                                        |
--  |                     +-- ba_config            (session default scale + ~35 policy settings)      |
--  |                     +-- ba_class_scale_jnt   (optional per-class override — D-02)               |
--  |                                                                                                 |
--  |  ba_categories -----+-- ba_criteria          (9 categories, 58 criteria)                        |
--  |                     +-- ba_class_category_jnt -- sch_classes   (no rows => all apply)           |
--  |                                                                                                 |
--  |  ba_interventions   (12)          ba_comment_bank   (12 templates)                              |
--  |  ba_assessment_periods            open <-> closed -> locked                                     |
--  +-------------------------------------------------------------------------------------------------+
--
--  +-- ASSESSMENT (teachers fill, supervisors review) ------------------------------------------------+
--  |                                                                                                 |
--  |  ba_assessments  (teacher x class-section x period)                                             |
--  |     +-- ba_assessment_ratings  (students x criteria; rating_level_id AND rating_value)          |
--  |     +-- ba_student_remarks     (one holistic remark per student)                                |
--  |     +-- ba_assessment_status_history  (append-only: who moved this, when, why)                  |
--  |                                                                                                 |
--  |  draft -> submitted -> reviewed -> locked        (review may be switched off per session)       |
--  |  Every change after submit -> ba_audit_log (immutable)                                          |
--  +-------------------------------------------------------------------------------------------------+
--
--  +-- LOCK AND FREEZE -------------------------------------------------------------------------------+
--  |                                                                                                 |
--  |  lock(period)                                                                                   |
--  |     +-> ba_framework_snapshots   scale + categories + criteria + weights + mapping, sealed      |
--  |     +-> every reviewed assessment  -> status = locked                                           |
--  |     +-> trg_ba_rating_biu now refuses every write beneath it                                    |
--  |                                                                                                 |
--  |  This is BUG-BA-001. In v2 the lock set a flag nothing read.                                    |
--  +-------------------------------------------------------------------------------------------------+
--
--  +-- SCORING ---------------------------------------------------------------------------------------+
--  |                                                                                                 |
--  |  ba_assessment_ratings   (status IN reviewed, locked only)                                      |
--  |      |  AVG(rating_value) per student x criterion across teachers                               |
--  |      |  negative polarity: (max + min) - value                                                  |
--  |      v                                                                                          |
--  |  weighted average per category  -> ba_computed_scores                                           |
--  |      v                                                                                          |
--  |  weighted average overall       -> ba_computed_overall  (+ delta, trend, at-risk)               |
--  |      v                                                                                          |
--  |  every run recorded in ba_score_runs  (trigger, actor, snapshot, checksum, duration)            |
--  |      v                                                                                          |
--  |  BehaviouralScoreService::getBulkScores()  <-- Exam/Result, locked periods only                 |
--  +-------------------------------------------------------------------------------------------------+
--
--  +-- INCIDENTS AND CASES ---------------------------------------------------------------------------+
--  |                                                                                                 |
--  |  ba_incidents   INC-YYYY-NNNNNN                                                                 |
--  |     |  open -> under_review -> action_taken -> resolved -> closed   (| cancelled)               |
--  |     +-- ba_incident_witnesses_jnt   statements, restricted read, frozen on closure              |
--  |     +-- ba_incident_attachments     relational evidence                                         |
--  |     +-- ba_incident_followups       append-only                                                 |
--  |     +-- ba_incident_intervention_jnt  owner + due date + status + outcome                       |
--  |             +-- ba_intervention_progress   append-only                                          |
--  |     +-- threshold or repeat-count met -> ba_notifications  (OUTBOX: pending/sent/failed)        |
--  |     +-- optional, OFF by default     -> ba_behaviour_points                                     |
--  +-------------------------------------------------------------------------------------------------+
--
-- =========================================================================================================
-- TABLE COUNT — 29
-- =========================================================================================================
--   Layer 1 (4): ba_rating_scales, ba_categories, ba_interventions, ba_comment_bank
--   Layer 2 (2): ba_rating_levels, ba_criteria
--   Layer 3 (5): ba_class_category_jnt, ba_class_scale_jnt, ba_assessment_periods, ba_config,
--                ba_framework_snapshots
--   Layer 4 (4): ba_assessments, ba_assessment_status_history, ba_audit_log, ba_audit_log_archive
--   Layer 5 (6): ba_assessment_ratings, ba_student_remarks, ba_computed_scores, ba_computed_overall,
--                ba_score_runs, ba_incidents
--   Layer 6 (5): ba_incident_witnesses_jnt, ba_incident_intervention_jnt, ba_incident_attachments,
--                ba_incident_followups, ba_intervention_progress
--   Layer 7 (3): ba_notifications, ba_report_exports, ba_behaviour_points
--
--   Views (5): v_ba_student_period_scores, v_ba_assessment_progress, v_ba_open_interventions,
--              v_ba_incident_summary, v_ba_at_risk_students
--
--   Triggers (22): scale lock (1), level range (2), period FSM (1), assessment FSM (1),
--                  rating/remark lock (4), incident number (1), incident immutability (1),
--                  witness freeze (1), immutable + append-only (10)
-- =========================================================================================================
-- END OF Behavioural_Assess_DDL_v7.0.sql
-- =========================================================================================================
