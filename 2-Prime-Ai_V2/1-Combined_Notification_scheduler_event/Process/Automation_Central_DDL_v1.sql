-- ======================================================================================================================================================
-- AUTOMATION CORE — CENTRAL DDL  v1.0
-- Compatible with MySQL 8.x
-- Databases: `global_master` (catalogue, read by every school through sync)
--             `prime_db`      (Prime-level schedules)
-- Written 2026-10-09 · Plan: prime_info/Final/automation-core/01-IMPLEMENTATION-PLAN.md
-- ======================================================================================================================================================

-- WHAT THIS FILE IS
-- ======================================================================================================================================================
--
  -- The Automation core joins three features into one mechanism:
    --      Event Engine  : "when X happens, do Y"
    --      Scheduler     : "at this time, do Y"   (time is just another event)
    --      Notification  : one of the things Y can be

    --    This CENTRAL file holds the CATALOGUE that Prime owns:
    --      - which events exist            (glb_aut_events)       — filled from code by `php artisan aut:sync-registry`
    --      - which actions exist           (glb_aut_actions)      — filled from code by `php artisan aut:sync-registry`
    --      - Prime's default rules         (glb_aut_rules)        — written by Prime admins
    --      - the schedule presets offered  (glb_aut_frequencies)  — seeded
    --      - the notification catalogue    (glb_ntf_events, glb_ntf_templates) — Prime admins

    --    Every school DB gets a COPY of the parts it needs (aut_events, aut_actions, aut_rules
    --    origin=PRIME, ntf_events, ntf_templates is_system_template=1) — see Automation_DDL_v1.sql.
    --    A school never reads these tables live. That keeps the school DB self-contained (the
    --    Hostinger cross-schema trap, 2026-09-23) and makes a Prime change an explicit sync.

    --    Codes, not ids, link catalogue rows (event_code, action_code). A code is stable across
    --    every database; an auto-increment id is not.

  --    DECISIONS this DDL implements (9 Oct 2026):
    --      A1  Developers register events + actions in code; Prime ships default rules;
    --          School Admin wires rules from dropdowns. Nobody types code or SQL.
    --      A2  v1 action kinds: NOTIFY, RECORD (developer-written only), FOLLOW_UP, WEBHOOK.
    --      B3  A school may DISABLE a Prime rule and TUNE its params, never delete it or change
    --          its event. is_locked rules cannot even be disabled.
    --      B6  Prime schedules (billing, backups) stay central in prime_db.
-- ======================================================================================================================================================


-- ======================================================================================================================================================
-- PART 1 — global_master
-- ======================================================================================================================================================

USE `global_master`;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_aut_events
-- Purpose: Every event a developer registered with #[AutomationEvent]. Source of truth is CODE; this table is a mirror refreshed by `aut:sync-registry`.
--          Rows are never edited by hand.
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_aut_events` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code` VARCHAR(80) NOT NULL COMMENT 'STUDENT_ADMITTED, FEE_COLLECTED, HRS_LEAVE_APPROVED ...',
	`module_code` VARCHAR(50) NOT NULL COMMENT 'Owning module: Admission, StudentFee, HrStaff ...',
	`name` VARCHAR(150) NOT NULL COMMENT 'Shown in the rule builder dropdown',
	`description` VARCHAR(500) NULL,
	`event_kind` ENUM('RECORD', 'TIME', 'SWEEP', 'SYSTEM') NOT NULL DEFAULT 'RECORD' COMMENT 'RECORD = a row changed; TIME = a schedule fired; SWEEP = a periodic check found something; SYSTEM = platform',
	`subject_table` VARCHAR(64) NULL COMMENT 'Main table of the subject, e.g. std_students',
	`payload_schema_json` JSON NOT NULL COMMENT '{field: type} usable in conditions and templates, e.g. {"class_id":"id:sch_classes","is_hosteller":"bool"}',
	`default_queue` ENUM('aut-high', 'aut-bulk') NOT NULL DEFAULT 'aut-high' COMMENT 'Queue for MatchRules of this event',
	`is_schedulable` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = a school schedule may emit it (TIME / SWEEP events)',
	`is_school_visible` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '0 = internal, hidden from the rule builder',
	`registry_hash` CHAR(64) NOT NULL COMMENT 'sha256 of the code declaration; changes when a developer changes the event',
	`is_active` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '0 = removed from code; kept so old logs still resolve',
	`synced_at` DATETIME NOT NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_glb_aut_event_code` (`code`),
	INDEX `idx_glb_aut_event_module` (`module_code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_aut_actions
-- Purpose: Every action type a developer registered with #[AutomationAction]. params_schema_json drives the rule-builder form, so a new action
--          appears in the UI with no screen work.
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_aut_actions` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code` VARCHAR(100) NOT NULL COMMENT 'notify, follow_up, webhook, record.library.create_member, record.fee.apply_late_fines ...',
	`module_code` VARCHAR(50) NOT NULL COMMENT 'Core for notify/follow_up/webhook; owning module for record.*',
	`name` VARCHAR(150) NOT NULL,
	`description` VARCHAR(500) NULL,
	`action_kind` ENUM('NOTIFY', 'RECORD', 'FOLLOW_UP', 'WEBHOOK') NOT NULL,
	`params_schema_json` JSON NOT NULL COMMENT 'Form fields: {"card_type":{"type":"enum","values":["STUDENT","STAFF"],"required":true}}',
	`handler_class` VARCHAR(255) NOT NULL COMMENT 'FQCN implementing AutomationAction',
	`emits_events_json` JSON NULL COMMENT 'Event codes this action may emit (used for loop detection at rule save)',
	`is_school_usable` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '0 = only Prime default rules may use it',
	`registry_hash` CHAR(64) NOT NULL,
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`synced_at` DATETIME NOT NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_glb_aut_action_code` (`code`),
	INDEX `idx_glb_aut_action_kind` (`action_kind`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_aut_event_action_compat
-- Purpose: Which actions make sense for which events (e.g. record.library.create_member needs a subject that has a user). The rule builder only offers
--          compatible pairs. A row with event_code = '*' means "any event".
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_aut_event_action_compat` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`event_code` VARCHAR(80) NOT NULL COMMENT 'Event code or * for any',
	`action_code` VARCHAR(100) NOT NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_glb_aut_compat` (`event_code`, `action_code`),
	CONSTRAINT `fk_glb_aut_compat_action` FOREIGN KEY (`action_code`) REFERENCES `glb_aut_actions`(`code`) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_aut_rules
-- Purpose: Prime's default rules. Copied into every school as aut_rules origin = 'PRIME'. A school may disable (unless is_locked) and tune params;
--          it can never change event_code / action_code or delete the row (B3). `version` increments on every Prime edit; the sync updates schools whose
--          copy has params_overridden = 0 and flags the others "Prime update available".
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_aut_rules` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`rule_code` VARCHAR(100) NOT NULL COMMENT 'PRM_STUDENT_ADMITTED_LIBRARY_CARD ...',
	`name` VARCHAR(150) NOT NULL,
	`description` VARCHAR(500) NULL,
	`event_code` VARCHAR(80) NOT NULL,
	`conditions_json` JSON NULL COMMENT 'NULL = always. {"all":[{"field":"is_hosteller","op":"=","value":true}]}',
	`action_code` VARCHAR(100) NOT NULL,
	`params_json` JSON NOT NULL COMMENT 'Default parameter values for the action',
	`priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Lower runs first when several rules match one event',
	`is_locked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = school cannot disable (legal / CRITICAL), e.g. fee receipt',
	`is_enabled_by_default` TINYINT(1) NOT NULL DEFAULT 1,
	`version` INT UNSIGNED NOT NULL DEFAULT 1,
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_by` INT UNSIGNED NULL COMMENT 'prime_db.sys_users.id (central admin), no FK across databases',
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	`active_flag` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED
		COMMENT 'Soft-delete aware unique (house pattern, see CHNL-10)',
	UNIQUE KEY `uq_glb_aut_rule_code_active` (`rule_code`, `active_flag`),
	INDEX `idx_glb_aut_rule_event` (`event_code`),
	CONSTRAINT `fk_glb_aut_rule_event` FOREIGN KEY (`event_code`) REFERENCES `glb_aut_events`(`code`) ON UPDATE CASCADE,
	CONSTRAINT `fk_glb_aut_rule_action` FOREIGN KEY (`action_code`) REFERENCES `glb_aut_actions`(`code`) ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_aut_frequencies
-- Purpose: Schedule presets Prime offers in the schedule builder. Schools may use every one, including EVERY_1_MIN (decision A6).
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_aut_frequencies` (
	`id` SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code` VARCHAR(40) NOT NULL COMMENT 'EVERY_1_MIN, HOURLY, DAILY, WEEKLY, EVERY_N_DAYS, MONTHLY, YEARLY, HOLIDAY, ONCE, CRON',
	`name` VARCHAR(100) NOT NULL,
	`when_type` ENUM('INTERVAL', 'CRON', 'ONCE', 'HOLIDAY') NOT NULL,
	`interval_minutes` INT UNSIGNED NULL COMMENT 'Fixed interval presets only',
	`cron_template` VARCHAR(100) NULL COMMENT 'e.g. "{m} {h} * * *" filled from the builder fields',
	`needs_fields_json` JSON NULL COMMENT 'Builder fields this preset asks for: ["time_of_day","weekday","day_of_month","every_n_days"]',
	`sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 100,
	`is_school_usable` TINYINT(1) NOT NULL DEFAULT 1,
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_glb_aut_freq_code` (`code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

INSERT INTO `glb_aut_frequencies` (`code`, `name`, `when_type`, `interval_minutes`, `cron_template`, `needs_fields_json`, `sort_order`) VALUES
	('EVERY_1_MIN',   'Every minute',             'INTERVAL', 1,     NULL,                 NULL,                                10),
	('EVERY_5_MIN',   'Every 5 minutes',          'INTERVAL', 5,     NULL,                 NULL,                                20),
	('EVERY_15_MIN',  'Every 15 minutes',         'INTERVAL', 15,    NULL,                 NULL,                                30),
	('HOURLY',        'Every hour',               'INTERVAL', 60,    NULL,                 NULL,                                40),
	('DAILY',         'Every day at ...',         'CRON',     NULL,  '{m} {h} * * *',      '["time_of_day"]',                   50),
	('WEEKLY',        'Every week on ...',        'CRON',     NULL,  '{m} {h} * * {dow}',  '["time_of_day","weekday"]',         60),
	('EVERY_N_DAYS',  'Every N days (e.g. 15)',   'INTERVAL', NULL,  NULL,                 '["every_n_days","time_of_day"]',    70),
	('MONTHLY',       'Every month on day ...',   'CRON',     NULL,  '{m} {h} {dom} * *',  '["time_of_day","day_of_month"]',    80),
	('YEARLY',        'Every year on date ...',   'CRON',     NULL,  '{m} {h} {dom} {mon} *', '["time_of_day","day_of_month","month"]', 90),
	('HOLIDAY',       'On a school holiday (e.g. Diwali)', 'HOLIDAY', NULL, NULL,          '["holiday_code","time_of_day","offset_days"]', 100),
	('ONCE',          'Once, at a date and time', 'ONCE',     NULL,  NULL,                 '["run_at"]',                        110),
	('CRON',          'Advanced (cron expression)', 'CRON',   NULL,  NULL,                 '["cron_expression"]',               120);

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_ntf_events
-- Purpose: Notification catalogue — WHAT a message type is and HOW it is delivered (tier, channels, fallback). Separate from glb_aut_events:
--          an automation event says "something happened"; a notification event says "send this kind of message". The `notify` action links the two.
--          Tier is fixed by Prime (D16): a school cannot change it.
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_ntf_events` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code` VARCHAR(80) NOT NULL COMMENT 'GUARDIAN_WELCOME, FEE_DUE_REMINDER, FESTIVAL_GREETING ...',
	`module_code` VARCHAR(50) NOT NULL,
	`name` VARCHAR(150) NOT NULL,
	`description` VARCHAR(500) NULL,
	`tier` ENUM('CRITICAL', 'HIGH', 'NORMAL', 'SCHEDULED') NOT NULL COMMENT 'Fixed by Prime; sets queue, quiet hours, fallback (§4 of the architecture plan)',
	`category` ENUM('SEC','EMG','LIVE','APR','DEC','ASN','ACT','FIN','ACA','ANN','REM','THR','ESC','OPS','SYS','DIG','FEED') NOT NULL COMMENT 'Requirement category (NOTIFICATION-CATEGORIES.md)',
	`default_channels_json` JSON NOT NULL COMMENT '["IN_APP","PUSH","WHATSAPP"]',
	`fallback_json` JSON NULL COMMENT '{"WHATSAPP":"EMAIL"} — NULL for CRITICAL (all at once) and SCHEDULED (no fallback)',
	`quiet_hours_policy` ENUM('RESPECT', 'IGNORE') NOT NULL DEFAULT 'RESPECT',
	`is_locked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = user cannot mute and school cannot disable (CRITICAL, receipts)',
	`confidential` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = outside channels get a content-free stub (NEW-11)',
	`dedupe_shape` VARCHAR(150) NOT NULL COMMENT 'e.g. {event}:{invoice_id}:{offset}:{recipient}',
	`variables_schema_json` JSON NOT NULL COMMENT 'Template variables this message type provides',
	`default_audience_json` JSON NULL COMMENT 'Default audience, e.g. {"type":"guardians_of_student","from":"student_id"}',
	`ttl_minutes` INT UNSIGNED NULL COMMENT 'Drop if not sent within N minutes (LIVE events); NULL = no expiry',
	`version` INT UNSIGNED NOT NULL DEFAULT 1,
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_glb_ntf_event_code` (`code`),
	INDEX `idx_glb_ntf_event_tier` (`tier`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: glb_ntf_templates
-- Purpose: Prime's default wording per message type × channel × language. Copied into each school's ntf_templates (is_system_template = 1);
--          a school edits its copy, never this row.
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `glb_ntf_templates` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`event_code` VARCHAR(80) NOT NULL,
	`channel_code` ENUM('IN_APP', 'PUSH', 'EMAIL', 'WHATSAPP', 'SMS') NOT NULL,
	`locale` VARCHAR(10) NOT NULL DEFAULT 'en' COMMENT 'en, hi (launch languages)',
	`subject` VARCHAR(255) NULL COMMENT 'Email subject / push + in-app title',
	`body` TEXT NOT NULL COMMENT 'Uses {{variable}} from glb_ntf_events.variables_schema_json',
	`wa_template_name` VARCHAR(100) NULL COMMENT 'Name to register in the school WhatsApp account (Meta requires approval per account)',
	`wa_variable_order_json` JSON NULL COMMENT 'Meta templates take positional variables: ["guardian_name","student_name","amount"]',
	`version` INT UNSIGNED NOT NULL DEFAULT 1,
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_glb_ntf_tpl` (`event_code`, `channel_code`, `locale`, `version`),
	CONSTRAINT `fk_glb_ntf_tpl_event` FOREIGN KEY (`event_code`) REFERENCES `glb_ntf_events`(`code`) ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;


-- ======================================================================================================================================================
   -- PART 2 — prime_db
   -- Prime-level schedules (central jobs: billing report, backups, tenant emails, "run X for every school"). This REPLACES the Scheduler module's
   -- `schedules` / `schedule_runs` migrations, which never ran (no table in prime_db, verified 2026-10-09). School schedules live in each school DB
   -- (aut_schedules), never here.
-- ======================================================================================================================================================

USE `prime_db`;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: prm_schedules
-- Purpose: Prime schedules. job_key resolves through the Scheduler JobRegistry (SchedulableJob contract, kept from the existing module).
--          scope = ALL_SCHOOLS dispatches the job once per active school, inside that school (tenancy()->runForMultiple).
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prm_schedules` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`name` VARCHAR(150) NOT NULL,
	`description` VARCHAR(500) NULL,
	`job_key` VARCHAR(100) NOT NULL COMMENT 'Key in Scheduler JobRegistry, e.g. prime_billing_report_job',
	`scope` ENUM('CENTRAL', 'ALL_SCHOOLS', 'ONE_SCHOOL') NOT NULL DEFAULT 'CENTRAL',
	`tenant_id` VARCHAR(36) NULL COMMENT 'prm_tenant.id (UUID) when scope = ONE_SCHOOL',
	`payload_json` JSON NULL COMMENT 'Constructor arguments for the job (ids only)',
	`frequency_code` VARCHAR(40) NOT NULL COMMENT 'global_master.glb_aut_frequencies.code',
	`when_json` JSON NOT NULL COMMENT 'Builder fields: {"time_of_day":"02:00"} / {"cron_expression":"..."} / {"run_at":"..."}',
	`cron_expression` VARCHAR(100) NULL COMMENT 'Resolved cron (CRON presets) — computed on save',
	`interval_minutes` INT UNSIGNED NULL COMMENT 'Resolved interval (INTERVAL presets)',
	`timezone` VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata',
	`overlap_policy` ENUM('SKIP', 'QUEUE') NOT NULL DEFAULT 'SKIP' COMMENT 'SKIP = do not start while the previous run is still RUNNING',
	`next_run_at` DATETIME NULL COMMENT 'UTC. Mirrored into the Redis due index aut:due',
	`last_run_at` DATETIME NULL,
	`last_status` ENUM('DONE', 'FAILED', 'SKIPPED') NULL,
	`consecutive_failures` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
	`is_active` TINYINT(1) NOT NULL DEFAULT 1,
	`created_by` INT UNSIGNED NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	INDEX `idx_prm_sch_next` (`is_active`, `next_run_at`),
	INDEX `idx_prm_sch_tenant` (`tenant_id`),
	CONSTRAINT `fk_prm_sch_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------
-- TABLE: prm_schedule_runs
-- Purpose: One row per planned firing. UNIQUE(schedule_id, planned_at, tenant_id_key) makes a slow or repeated tick harmless. Status reflects the JOB,
--          not the dispatch (the old command marked "success" on dispatch).
-- ------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prm_schedule_runs` (
	`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`schedule_id` INT UNSIGNED NOT NULL,
	`tenant_id` VARCHAR(36) NULL COMMENT 'Set when an ALL_SCHOOLS schedule fans out: one run row per school',
	`tenant_id_key` VARCHAR(36) GENERATED ALWAYS AS (COALESCE(`tenant_id`, '-')) STORED COMMENT 'NULL-safe unique',
	`planned_at` DATETIME NOT NULL COMMENT 'UTC planned time — the idempotency key',
	`queued_at` DATETIME NULL,
	`started_at` DATETIME NULL,
	`finished_at` DATETIME NULL,
	`status` ENUM('QUEUED', 'RUNNING', 'DONE', 'FAILED', 'SKIPPED') NOT NULL DEFAULT 'QUEUED',
	`reason` VARCHAR(512) NULL COMMENT 'Why skipped / failed',
	`duration_ms` INT UNSIGNED NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_prm_sch_run` (`schedule_id`, `planned_at`, `tenant_id_key`),
	INDEX `idx_prm_sch_run_status` (`status`, `planned_at`),
	CONSTRAINT `fk_prm_sch_run_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `prm_schedules`(`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
