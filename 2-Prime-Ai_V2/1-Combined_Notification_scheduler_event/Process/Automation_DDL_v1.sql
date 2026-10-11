/* =========================================================
   AUTOMATION CORE — SCHOOL (TENANT) DDL  v1.0
   Compatible with MySQL 8.x
   Database: every school DB (tenant_*)
   Written 2026-10-09 · Plan: prime_info/Final/automation-core/01-IMPLEMENTATION-PLAN.md
   Central catalogue: Automation_Central_DDL_v1.sql · Notification side: ../Notification/Notification_DDL_v4.sql
   ========================================================= */

/* =========================================================
   HOW THE TABLES FIT TOGETHER
   =========================================================

        catalogue copy                 configuration                     runtime (truth)
   ┌──────────────────┐        ┌──────────────────────┐        ┌──────────────────────────────┐
   │ aut_events       │◄───────│ aut_rules            │───────►│ aut_action_runs              │
   │ aut_actions      │◄───────│  event → if → action │        │  one per (occurrence × rule) │
   └──────────────────┘        └──────────────────────┘        └──────────────▲───────────────┘
                               ┌──────────────────────┐                       │
                               │ aut_schedules        │──fires──► aut_schedule_runs ──emits──┐
                               │  when + what         │                                       │
                               └──────────────────────┘                                       ▼
   Automation::emit() from module code ─────────────────────────────────────────► aut_event_log
   aut_due (follow-ups, "in 7 days") ───────────────────────────────── emits when due ─────────┘
   aut_condition_state  (once-per-crossing memory for SWEEP events, e.g. attendance < 75 %)
   aut_webhooks         (school's outside URLs for the webhook action)
   aut_daily_stats      (90-day roll-up target; detail rows older than 90 days are deleted)

   RULES THAT SHAPE THIS DDL
   1. NO tenant_id column. The school database IS the isolation (decision B2, 9 Oct 2026).
   2. Codes link to the catalogue (event_code, action_code), so a Prime sync never
      re-numbers anything.
   3. Every runtime table has an idempotency guarantee in a UNIQUE key:
        aut_event_log      UNIQUE(idempotency_key)
        aut_action_runs    UNIQUE(event_log_id, owner_key)
        aut_schedule_runs  UNIQUE(schedule_id, planned_at)
   4. Timestamps are stored in UTC. The school's timezone (sys_settings.school_timezone,
      default Asia/Kolkata) is applied when a schedule is computed and when a time is shown.
   5. Statuses used only by the pipeline are ENUMs (read on every job, never re-labelled by
      users). Statuses users manage stay in sys_dropdown_table as elsewhere.
   6. Soft-delete aware UNIQUE keys use the house pattern (active_flag generated column).
   ========================================================= */


	-- -----------------------------------------------------------------
	-- TABLE: aut_events
	-- Purpose: School copy of global_master.glb_aut_events (synced by aut:sync-school).
	--          The school can switch an event off, which silences every rule on it.
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_events` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(80) NOT NULL COMMENT 'Same code as glb_aut_events.code',
    `module_code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` VARCHAR(500) NULL,
    `event_kind` ENUM('RECORD', 'TIME', 'SWEEP', 'SYSTEM') NOT NULL DEFAULT 'RECORD',
    `subject_table` VARCHAR(64) NULL,
    `payload_schema_json` JSON NOT NULL COMMENT 'Copied; drives condition fields and template variables',
    `default_queue` ENUM('aut-high', 'aut-bulk') NOT NULL DEFAULT 'aut-high',
    `is_schedulable` TINYINT(1) NOT NULL DEFAULT 0,
    `is_school_visible` TINYINT(1) NOT NULL DEFAULT 1,
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'School switch. 0 = event is logged but no rule runs',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Catalogue flag (0 = removed from code)',
    `catalogue_hash` CHAR(64) NOT NULL COMMENT 'glb registry_hash at last sync',
    `synced_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_aut_event_code` (`code`),
    INDEX `idx_aut_event_module` (`module_code`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_actions
	-- Purpose: School copy of global_master.glb_aut_actions.
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_actions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(100) NOT NULL,
    `module_code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `description` VARCHAR(500) NULL,
    `action_kind` ENUM('NOTIFY', 'RECORD', 'FOLLOW_UP', 'WEBHOOK') NOT NULL,
    `params_schema_json` JSON NOT NULL,
    `emits_events_json` JSON NULL,
    `compatible_events_json` JSON NULL COMMENT 'Copied from glb_aut_event_action_compat: ["*"] or ["STUDENT_ADMITTED",...]',
    `is_school_usable` TINYINT(1) NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `catalogue_hash` CHAR(64) NOT NULL,
    `synced_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_aut_action_code` (`code`),
    INDEX `idx_aut_action_kind` (`action_kind`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_rules
	-- Purpose: "When <event> and <conditions>, run <action> with <params>".
	--          origin = PRIME : copied from glb_aut_rules. School may disable (unless
	--                           is_locked) and tune params_json; event_code and
	--                           action_code are read-only; never deleted (B3).
	--          origin = SCHOOL: built by the School Admin in the rule builder.
	--          No approval step for school rules (decision B4: never).
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_rules` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_code` VARCHAR(100) NOT NULL COMMENT 'PRM_... for Prime copies, SCH_<n> for school rules',
    `name` VARCHAR(150) NOT NULL,
    `description` VARCHAR(500) NULL,
    `origin` ENUM('PRIME', 'SCHOOL') NOT NULL DEFAULT 'SCHOOL',
    `prime_rule_code` VARCHAR(100) NULL COMMENT 'glb_aut_rules.rule_code for origin = PRIME',
    `prime_version` INT UNSIGNED NULL COMMENT 'glb_aut_rules.version last applied',
    `prime_update_available` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Prime changed the rule but this copy has school-tuned params',
    `event_code` VARCHAR(80) NOT NULL,
    `conditions_json` JSON NULL COMMENT 'NULL = always. {"all":[{"field":"class_id","op":"in","value":[3,4]}],"any":[...]}',
    `action_code` VARCHAR(100) NOT NULL,
    `params_json` JSON NOT NULL COMMENT 'Validated against aut_actions.params_schema_json on save',
    `params_overridden` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = school tuned a Prime rule',
    `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Lower first when several rules match',
    `is_locked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Copied from Prime; 1 = cannot be disabled',
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `consecutive_failures` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `auto_pause_after` SMALLINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Auto-disable after N failures in a row',
    `paused_at` DATETIME NULL COMMENT 'Set when auto-paused; cleared when an admin re-enables',
    `paused_reason` VARCHAR(512) NULL,
    `last_fired_at` DATETIME NULL,
    `fire_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Lifetime, maintained per run (not per recipient)',
    `created_by` INT UNSIGNED NULL,
    `updated_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL COMMENT 'School rules only; PRIME rows are never soft-deleted',
    `active_flag` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED,
    UNIQUE KEY `uq_aut_rule_code_active` (`rule_code`, `active_flag`),
    INDEX `idx_aut_rule_match` (`event_code`, `is_enabled`, `priority`) COMMENT 'Hot path: rules for one event',
    INDEX `idx_aut_rule_action` (`action_code`),
    CONSTRAINT `fk_aut_rule_event` FOREIGN KEY (`event_code`) REFERENCES `aut_events`(`code`) ON UPDATE CASCADE,
    CONSTRAINT `fk_aut_rule_action` FOREIGN KEY (`action_code`) REFERENCES `aut_actions`(`code`) ON UPDATE CASCADE,
    CONSTRAINT `fk_aut_rule_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_aut_rule_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_schedules
	-- Purpose: "At <when>, do <what>". Built by the School Admin.
	--          when_type INTERVAL / CRON / ONCE / HOLIDAY (preset from glb_aut_frequencies).
	--          HOLIDAY: fires on the next sch_holidays row whose holiday_code matches
	--                   (+ offset_days, at time_of_day). If no future row exists the
	--                   schedule shows waiting_reason = "No DIWALI date after <date>".
	--          what_type EMIT_EVENT : emits event_code with context_json; rules respond.
	--                    RUN_ACTION : runs action_code with params_json directly
	--                                 (no rule needed, e.g. "send Happy Diwali").
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_schedules` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `schedule_code` VARCHAR(100) NOT NULL COMMENT 'SCH_<n> or PRM_<code> for Prime-shipped school schedules',
    `name` VARCHAR(150) NOT NULL,
    `description` VARCHAR(500) NULL,
    `origin` ENUM('PRIME', 'SCHOOL') NOT NULL DEFAULT 'SCHOOL',
    -- WHEN
    `frequency_code` VARCHAR(40) NOT NULL COMMENT 'glb_aut_frequencies.code',
    `when_type` ENUM('INTERVAL', 'CRON', 'ONCE', 'HOLIDAY') NOT NULL,
    `interval_minutes` INT UNSIGNED NULL COMMENT 'INTERVAL (EVERY_N_DAYS = N x 1440)',
    `cron_expression` VARCHAR(100) NULL COMMENT 'CRON, resolved from the builder fields',
    `run_at` DATETIME NULL COMMENT 'ONCE, UTC',
    `holiday_code` VARCHAR(50) NULL COMMENT 'HOLIDAY: sch_holidays.holiday_code, e.g. DIWALI',
    `offset_days` SMALLINT NOT NULL DEFAULT 0 COMMENT 'HOLIDAY: -1 = the day before',
    `time_of_day` TIME NULL COMMENT 'School local time for DAILY/WEEKLY/MONTHLY/YEARLY/HOLIDAY',
    `when_json` JSON NOT NULL COMMENT 'Raw builder fields, kept to re-open the builder exactly',
    `timezone` VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata' COMMENT 'Copied from sys_settings.school_timezone on save',
    `active_from` DATE NULL,
    `active_to` DATE NULL,
    -- WHAT
    `what_type` ENUM('EMIT_EVENT', 'RUN_ACTION') NOT NULL,
    `event_code` VARCHAR(80) NULL COMMENT 'EMIT_EVENT: must be is_schedulable',
    `action_code` VARCHAR(100) NULL COMMENT 'RUN_ACTION',
    `context_json` JSON NULL COMMENT 'EMIT_EVENT: fixed payload; RUN_ACTION: unused',
    `params_json` JSON NULL COMMENT 'RUN_ACTION: action parameters',
    -- STATE
    `overlap_policy` ENUM('SKIP', 'QUEUE') NOT NULL DEFAULT 'SKIP',
    `next_run_at` DATETIME NULL COMMENT 'UTC; mirrored into Redis ZSET aut:due. NULL = nothing ahead',
    `waiting_reason` VARCHAR(255) NULL COMMENT 'Why next_run_at is NULL (holiday date missing, ended ...)',
    `last_run_at` DATETIME NULL,
    `last_status` ENUM('DONE', 'FAILED', 'SKIPPED') NULL,
    `consecutive_failures` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `run_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED NULL,
    `updated_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    `active_flag` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED,
    UNIQUE KEY `uq_aut_schedule_code_active` (`schedule_code`, `active_flag`),
    INDEX `idx_aut_schedule_next` (`is_enabled`, `next_run_at`) COMMENT 'Nightly ZSET rebuild + repair',
    INDEX `idx_aut_schedule_holiday` (`holiday_code`),
    -- No ON UPDATE CASCADE on these two: both columns are used by chk_aut_schedule_what, and MySQL
    -- refuses a CHECK on a column whose FK has a referential action (errno 3823). Codes never change.
    CONSTRAINT `fk_aut_schedule_event` FOREIGN KEY (`event_code`) REFERENCES `aut_events`(`code`),
    CONSTRAINT `fk_aut_schedule_action` FOREIGN KEY (`action_code`) REFERENCES `aut_actions`(`code`),
    CONSTRAINT `fk_aut_schedule_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_aut_schedule_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `chk_aut_schedule_what` CHECK (
        (`what_type` = 'EMIT_EVENT' AND `event_code` IS NOT NULL) OR
        (`what_type` = 'RUN_ACTION' AND `action_code` IS NOT NULL)
    ),
    CONSTRAINT `chk_aut_schedule_when` CHECK (
        (`when_type` = 'INTERVAL' AND `interval_minutes` IS NOT NULL) OR
        (`when_type` = 'CRON'     AND `cron_expression` IS NOT NULL) OR
        (`when_type` = 'ONCE'     AND `run_at` IS NOT NULL) OR
        (`when_type` = 'HOLIDAY'  AND `holiday_code` IS NOT NULL AND `time_of_day` IS NOT NULL)
    )
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_event_log
	-- Purpose: One row per occurrence — module emit, schedule firing, follow-up
	--          coming due, manual "Run now", or an action emitting a new event.
	--          Written in the CALLER'S transaction; MatchRules is dispatched after
	--          commit. Holds ids only (context_json), never personal data.
	--          Detail kept 90 days, then rolled into aut_daily_stats and deleted.
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_event_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `event_code` VARCHAR(80) NOT NULL,
    `subject_table` VARCHAR(64) NULL,
    `subject_id` BIGINT UNSIGNED NULL,
    `context_json` JSON NULL COMMENT 'Payload fields per aut_events.payload_schema_json (ids + scalars only)',
    `idempotency_key` VARCHAR(191) NOT NULL COMMENT 'e.g. STUDENT_ADMITTED:1758 or schedule:12:2026-11-08T03:30Z',
    `source` ENUM('MODULE', 'SCHEDULE', 'FOLLOW_UP', 'MANUAL', 'ACTION') NOT NULL,
    `source_ref_id` BIGINT UNSIGNED NULL COMMENT 'aut_schedule_runs.id / aut_due.id / aut_action_runs.id',
    `chain_id` CHAR(36) NOT NULL COMMENT 'Same for every event in one cause-and-effect chain',
    `depth` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Emits deeper than 3 are REFUSED (loop guard)',
    `status` ENUM('PENDING', 'MATCHED', 'NO_RULES', 'DISABLED', 'REFUSED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    `matched_rules` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `emitted_by` INT UNSIGNED NULL COMMENT 'sys_users.id of the logged-in user, if any',
    `emitted_at` DATETIME(3) NOT NULL,
    `processed_at` DATETIME(3) NULL,
    `error_message` VARCHAR(512) NULL,
    UNIQUE KEY `uq_aut_event_idem` (`idempotency_key`),
    INDEX `idx_aut_event_code_time` (`event_code`, `emitted_at`),
    INDEX `idx_aut_event_subject` (`subject_table`, `subject_id`),
    INDEX `idx_aut_event_chain` (`chain_id`),
    INDEX `idx_aut_event_status` (`status`, `emitted_at`),
    CONSTRAINT `fk_aut_event_log_event` FOREIGN KEY (`event_code`) REFERENCES `aut_events`(`code`) ON UPDATE CASCADE,
    CONSTRAINT `fk_aut_event_log_user` FOREIGN KEY (`emitted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_action_runs
	-- Purpose: One row per (occurrence × rule), or (occurrence × schedule) for
	--          RUN_ACTION schedules. owner_key makes "never twice" one UNIQUE key.
	--          Each row is one queued job; one broken rule never blocks another.
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_action_runs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `event_log_id` BIGINT UNSIGNED NOT NULL,
    `rule_id` INT UNSIGNED NULL COMMENT 'Set when a rule matched',
    `schedule_id` INT UNSIGNED NULL COMMENT 'Set for RUN_ACTION schedules (no rule)',
    `owner_key` VARCHAR(20) GENERATED ALWAYS AS (
        CASE WHEN `rule_id` IS NOT NULL THEN CONCAT('R', `rule_id`) ELSE CONCAT('S', `schedule_id`) END
    ) STORED COMMENT 'R<rule_id> or S<schedule_id>',
    `action_code` VARCHAR(100) NOT NULL,
    `params_json` JSON NOT NULL COMMENT 'Snapshot of the params used (rule may change later)',
    `status` ENUM('PENDING', 'RUNNING', 'DONE', 'SKIPPED', 'FAILED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    `attempts` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `reason` VARCHAR(512) NULL COMMENT 'Why skipped / failed, readable by the School Admin',
    `result_json` JSON NULL COMMENT 'e.g. {"lib_member_id":91} or {"ntf_notification_id":5521}',
    `queued_at` DATETIME(3) NULL,
    `started_at` DATETIME(3) NULL,
    `finished_at` DATETIME(3) NULL,
    `duration_ms` INT UNSIGNED NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_aut_run_once` (`event_log_id`, `owner_key`),
    INDEX `idx_aut_run_rule` (`rule_id`, `created_at`),
    INDEX `idx_aut_run_schedule` (`schedule_id`, `created_at`),
    INDEX `idx_aut_run_status` (`status`, `created_at`),
    CONSTRAINT `fk_aut_run_event_log` FOREIGN KEY (`event_log_id`) REFERENCES `aut_event_log`(`id`) ON DELETE CASCADE,
    -- RESTRICT, not SET NULL: rule_id / schedule_id feed the stored generated owner_key and the CHECK,
    -- and MySQL forbids SET NULL / CASCADE on such columns (errno 3104 / 3823). Rules and schedules are
    -- soft-deleted, never hard-deleted, so RESTRICT never blocks normal use.
    CONSTRAINT `fk_aut_run_rule` FOREIGN KEY (`rule_id`) REFERENCES `aut_rules`(`id`),
    CONSTRAINT `fk_aut_run_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `aut_schedules`(`id`),
    CONSTRAINT `fk_aut_run_action` FOREIGN KEY (`action_code`) REFERENCES `aut_actions`(`code`) ON UPDATE CASCADE,
    CONSTRAINT `chk_aut_run_owner` CHECK (`rule_id` IS NOT NULL OR `schedule_id` IS NOT NULL)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_schedule_runs
	-- Purpose: One row per planned firing of a school schedule.
	--          UNIQUE(schedule_id, planned_at): a slow / repeated / restarted pump
	--          can never fire the same planned time twice (the Diwali greeting goes once).
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_schedule_runs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `schedule_id` INT UNSIGNED NOT NULL,
    `planned_at` DATETIME NOT NULL COMMENT 'UTC planned time',
    `started_at` DATETIME(3) NULL,
    `finished_at` DATETIME(3) NULL,
    `status` ENUM('QUEUED', 'RUNNING', 'DONE', 'SKIPPED', 'FAILED') NOT NULL DEFAULT 'QUEUED',
    `event_log_id` BIGINT UNSIGNED NULL COMMENT 'The occurrence this firing emitted',
    `reason` VARCHAR(512) NULL COMMENT 'e.g. "skipped: previous run still running"',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_aut_sch_run` (`schedule_id`, `planned_at`),
    INDEX `idx_aut_sch_run_status` (`status`, `planned_at`),
    CONSTRAINT `fk_aut_sch_run_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `aut_schedules`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_aut_sch_run_event_log` FOREIGN KEY (`event_log_id`) REFERENCES `aut_event_log`(`id`) ON DELETE SET NULL
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_due
	-- Purpose: Timed one-off events created by the follow_up action
	--          ("7 days after admission, remind to upload documents").
	--          At due_at the pump asks still_applies_check; if the condition no longer
	--          holds (documents uploaded) the row is SKIPPED, otherwise it emits event_code.
	--          cancel_key lets a module cancel every waiting follow-up for a subject
	--          (Automation::cancelDue('docs:student:1758')).
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_due` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `created_by_run_id` BIGINT UNSIGNED NULL COMMENT 'aut_action_runs.id of the follow_up action',
    `due_at` DATETIME NOT NULL COMMENT 'UTC',
    `event_code` VARCHAR(80) NOT NULL COMMENT 'Event to emit when due',
    `subject_table` VARCHAR(64) NULL,
    `subject_id` BIGINT UNSIGNED NULL,
    `context_json` JSON NULL,
    `still_applies_check` VARCHAR(100) NULL COMMENT 'Registered check code, e.g. std.documents_missing; NULL = always fire',
    `check_params_json` JSON NULL COMMENT 'e.g. {"document_types":["AADHAAR","BIRTH_CERT"]}',
    `cancel_key` VARCHAR(191) NULL COMMENT 'e.g. docs:student:1758',
    `chain_id` CHAR(36) NOT NULL,
    `depth` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `status` ENUM('WAITING', 'FIRED', 'SKIPPED', 'CANCELLED', 'FAILED') NOT NULL DEFAULT 'WAITING',
    `fired_event_log_id` BIGINT UNSIGNED NULL,
    `reason` VARCHAR(512) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_aut_due_pending` (`status`, `due_at`),
    INDEX `idx_aut_due_cancel` (`cancel_key`, `status`),
    INDEX `idx_aut_due_subject` (`subject_table`, `subject_id`),
    CONSTRAINT `fk_aut_due_run` FOREIGN KEY (`created_by_run_id`) REFERENCES `aut_action_runs`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_aut_due_event` FOREIGN KEY (`event_code`) REFERENCES `aut_events`(`code`) ON UPDATE CASCADE,
    CONSTRAINT `fk_aut_due_fired` FOREIGN KEY (`fired_event_log_id`) REFERENCES `aut_event_log`(`id`) ON DELETE SET NULL
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_condition_state
	-- Purpose: Memory for "once per crossing" SWEEP events (requirement NEW-9).
	--          e.g. attendance below 75 %: the sweep emits STUDENT_ATTENDANCE_BELOW only
	--          when a student goes from OK -> BELOW; it emits nothing while the student
	--          stays below, and STUDENT_ATTENDANCE_RECOVERED on BELOW -> OK.
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_condition_state` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `condition_code` VARCHAR(80) NOT NULL COMMENT 'e.g. ATTENDANCE_BELOW_THRESHOLD',
    `subject_table` VARCHAR(64) NOT NULL,
    `subject_id` BIGINT UNSIGNED NOT NULL,
    `state` VARCHAR(30) NOT NULL COMMENT 'e.g. OK / BELOW',
    `state_value` DECIMAL(10,2) NULL COMMENT 'Last measured value, e.g. 72.50',
    `since` DATETIME NOT NULL COMMENT 'When the current state began',
    `last_checked_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_aut_cond_subject` (`condition_code`, `subject_table`, `subject_id`),
    INDEX `idx_aut_cond_state` (`condition_code`, `state`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_webhooks
	-- Purpose: School's outside endpoints for the `webhook` action.
	--          HTTPS only; private / loopback IPs refused at send time (SSRF guard);
	--          each POST is signed: X-Prime-Signature = HMAC-SHA256(secret, body).
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_webhooks` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `url` VARCHAR(500) NOT NULL COMMENT 'https:// only',
    `secret_encrypted` TEXT NOT NULL COMMENT 'Laravel encrypted; shown once on create',
    `timeout_seconds` TINYINT UNSIGNED NOT NULL DEFAULT 10,
    `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
    `consecutive_failures` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `auto_disable_after` SMALLINT UNSIGNED NOT NULL DEFAULT 20,
    `last_success_at` DATETIME NULL,
    `last_failure_at` DATETIME NULL,
    `last_error` VARCHAR(512) NULL,
    `created_by` INT UNSIGNED NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    CONSTRAINT `fk_aut_webhook_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

	-- -----------------------------------------------------------------
	-- TABLE: aut_daily_stats
	-- Purpose: Roll-up of detail rows older than the retention window
	--          (sys_settings.aut_log_retention_days, default 90). The nightly
	--          aut:prune job adds a day's counts here, then deletes that day's detail.
	-- -----------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `aut_daily_stats` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `stat_date` DATE NOT NULL COMMENT 'School local date',
    `kind` ENUM('EVENT', 'RULE', 'SCHEDULE', 'WEBHOOK', 'FOLLOW_UP') NOT NULL,
    `ref_code` VARCHAR(100) NOT NULL COMMENT 'event_code / rule_code / schedule_code / webhook id',
    `total` INT UNSIGNED NOT NULL DEFAULT 0,
    `done` INT UNSIGNED NOT NULL DEFAULT 0,
    `skipped` INT UNSIGNED NOT NULL DEFAULT 0,
    `failed` INT UNSIGNED NOT NULL DEFAULT 0,
    `avg_duration_ms` INT UNSIGNED NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_aut_stats` (`stat_date`, `kind`, `ref_code`)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


/* =========================================================
   CHANGES TO EXISTING TABLES
   ========================================================= */

	-- -----------------------------------------------------------------
	-- sch_holidays: holiday_code (decision B5 — school holidays only, no Prime calendar)
	-- A HOLIDAY schedule fires on the next row with its code. The school enters each
	-- year's Diwali row as it does today and picks the code once; the name stays free text.
	-- Codes come from a dropdown (sys_dropdown_table key 'sch_holidays.holiday_code'):
	-- DIWALI, HOLI, EID_UL_FITR, CHRISTMAS, INDEPENDENCE_DAY, REPUBLIC_DAY, GANDHI_JAYANTI,
	-- RAKSHA_BANDHAN, DUSSEHRA, GURU_NANAK_JAYANTI, PONGAL, ONAM, NEW_YEAR, OTHER.
	-- -----------------------------------------------------------------
	ALTER TABLE `sch_holidays`
    ADD COLUMN `holiday_code` VARCHAR(50) NULL COMMENT 'Optional festival code for HOLIDAY schedules' AFTER `name`,
    ADD INDEX `idx_sch_holiday_code_date` (`holiday_code`, `holiday_date`);

	-- -----------------------------------------------------------------
	-- sys_settings: per-school values the core reads (key/value table, no schema change)
	-- -----------------------------------------------------------------
	INSERT INTO `sys_settings` (`key`, `description`, `value`, `type`, `is_public`, `created_at`, `updated_at`)
	SELECT * FROM (
        SELECT 'school_timezone'          AS `key`, 'IANA timezone for schedules, quiet hours and displayed times' AS `description`, 'Asia/Kolkata' AS `value`, 'string' AS `type`, 0 AS `is_public`, NOW() AS `created_at`, NOW() AS `updated_at`
        UNION ALL SELECT 'aut_log_retention_days', 'Days of automation detail kept before roll-up',      '90',    'integer', 0, NOW(), NOW()
        UNION ALL SELECT 'ntf_quiet_hours_start',  'Quiet hours start (school local time)',                '21:00', 'string',  0, NOW(), NOW()
        UNION ALL SELECT 'ntf_quiet_hours_end',    'Quiet hours end (school local time)',                  '07:00', 'string',  0, NOW(), NOW()
	) AS s
	WHERE NOT EXISTS (SELECT 1 FROM `sys_settings` x WHERE x.`key` = s.`key`);
