-- ====================================================================================================
   NOTIFICATION MODULE — SCHOOL (TENANT) DDL  v4.0
   Compatible with MySQL 8.x
   Enhanced from: 2-DDL_Tenant_Consolidated/Notification_DDL_v3.sql
   Written 2026-10-09 · Plan: prime_info/Final/automation-core/01-IMPLEMENTATION-PLAN.md
   Central catalogue (glb_ntf_events, glb_ntf_templates): ../Automation/Automation_Central_DDL_v1.sql
-- ====================================================================================================

-- ====================================================================================================
   v4.0 CHANGELOG (from v3)
-- ====================================================================================================

-- REMOVED
   -- R1  `tenant_id` dropped from all 6 tables that had it (channel_master, provider_master,
   --     notifications, target_groups, templates, notification_threads). Decision B2: the
   --     school database IS the isolation; the column was INT in v3 and VARCHAR(36) live
   --     (drift CHNL-17). Uniques that included tenant_id now use the code alone.

   -- ABSORBED (fixes that lived only in migrations / comments in v3)
   -- F1  CHNL-10 / TGRP-10: soft-delete aware UNIQUE keys (active_flag generated column).
   -- F2  TGRP-13: ntf_target_groups.created_by -> sys_users FK (RESTRICT).
   -- F3  THRD-18 / THRD-21 / TMBR-07 / DLVY-08: deleted_at columns + uq_thread_uuid.
   -- F4  ntf_templates.dlt_template_id stays dropped (2026_08_09_220000).

-- NEW TABLE
   -- N1  ntf_events — school copy of glb_ntf_events (tier, channels, fallback, wording
   --     tuned by the school). Tier and is_locked are read-only for the school (D16).

   -- ENHANCED (columns added; nothing renamed, so existing screens keep working)
   -- E1  ntf_notifications becomes the OUTBOX: one row per send request — from a module
   --     (Notify::event), from a rule (notify action -> aut_action_run_id), or composed by
   --     an admin. Adds event_code, tier, pipeline_status, context/audience JSON, dedupe
   --     base, send_at, chunk cursor, skipped/held counters.
   --     notification_status_id (dropdown) is kept for the existing admin screen and is
   --     mirrored from pipeline_status; the pipeline never reads it.
   -- E2  ntf_resolved_recipients becomes the per-person-per-channel STATE MACHINE:
   --     user nullable + contact columns (people with no login: applicants, visitors,
   --     guardians without accounts — NEW-7), dedupe_key UNIQUE, state, lease, attempts,
   --     reason, provider_message_id, fallback link.
   -- E3  ntf_provider_master: per-school WhatsApp (Meta Cloud API) and email-override
   --     fields, rate limit, webhook token, test-send status.
   -- E4  ntf_templates: event_code link, WhatsApp template name + variable order, locale
   --     index, approval of WhatsApp templates by Meta tracked separately.
   -- E5  ntf_user_devices: app (primeapp / primeadmin), fcm token unique per device.
   -- E6  ntf_user_preferences: per EVENT + channel (event_code NULL = channel default).
   -- E7  ntf_delivery_logs: user / provider / recipient nullable (in-app has no provider;
   --     a no-login contact has no user).

-- DEPRECATED (kept so current screens work; no new code may write them)
   -- D1  ntf_delivery_queue  — replaced by Redis queues + recipient leases.
   -- D2  ntf_schedule_audit  — replaced by aut_schedule_runs (Automation core).
   -- D3  ntf_notification_channels — channel choice now lives in ntf_events.channels_json
   --     per event; kept for the old manual-notification screen until it is rebuilt.
-- ========================================================= */


-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_channel_master
-- Purpose: Available channels (EMAIL, SMS, WHATSAPP, IN_APP, PUSH).
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_channel_master` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code` VARCHAR(20) NOT NULL COMMENT 'EMAIL, SMS, WHATSAPP, IN_APP, PUSH',
	`name` VARCHAR(50) NOT NULL COMMENT 'Display name',
	`description` VARCHAR(255) NULL,
	`channel_type` ENUM('IMMEDIATE', 'BULK', 'TRANSACTIONAL') DEFAULT 'TRANSACTIONAL',
	`priority_order` TINYINT DEFAULT 5 COMMENT '1-Highest, 10-Lowest',
	`max_retry` INT DEFAULT 3,
	`retry_delay_minutes` INT DEFAULT 5,
	`rate_limit_per_minute` INT DEFAULT 100 COMMENT 'v4: informational; the real limit is ntf_provider_master.rate_per_second via Redis throttle',
	`daily_limit` INT DEFAULT 10000,
	`monthly_limit` INT DEFAULT 100000,
	`cost_per_unit` DECIMAL(10,4) DEFAULT 0.0000 COMMENT 'Used for the broadcast cost estimate',
	`fallback_channel_id` INT UNSIGNED NULL COMMENT 'v4: superseded by ntf_events.fallback_json; kept for the old screen',
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	`active_flag` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED,
	UNIQUE KEY `uq_ntf_channel_code_active` (`code`, `active_flag`),
	CONSTRAINT `fk_ntf_channel_fallback` FOREIGN KEY (`fallback_channel_id`) REFERENCES `ntf_channel_master`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_provider_master
-- Purpose: The school's own provider accounts (D12): WhatsApp (Meta Cloud API) and
--          an optional email override. Push uses Prime's FCM project (D14) and needs
--          no row here. Credentials are Laravel-encrypted and never logged.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_provider_master` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`channel_id` INT UNSIGNED NOT NULL,
	`provider_name` VARCHAR(50) NOT NULL COMMENT 'META_CLOUD, SMTP, SES, BREVO, MSG91, TWILIO',
	`provider_type` ENUM('PRIMARY', 'SECONDARY', 'BACKUP') DEFAULT 'PRIMARY',
	`api_endpoint` VARCHAR(500) NULL,
	`api_key_encrypted` TEXT NULL COMMENT 'Encrypted API credentials',
	`api_secret_encrypted` TEXT NULL,
	`from_address` VARCHAR(255) NULL COMMENT 'Sender email / phone / name',
	`reply_to_address` VARCHAR(255) NULL COMMENT 'v4: email Reply-To (school office)',
	`mailer_dsn_encrypted` TEXT NULL COMMENT 'v4: email override as one Symfony Mailer DSN (smtp://, ses+api://, brevo+api://)',
	`wa_phone_number_id` VARCHAR(50) NULL COMMENT 'v4: Meta Cloud API phone number id',
	`wa_business_account_id` VARCHAR(50) NULL COMMENT 'v4: WABA id (from Embedded Signup)',
	`wa_access_token_encrypted` TEXT NULL COMMENT 'v4: long-lived system-user token',
	`wa_quality_rating` ENUM('GREEN', 'YELLOW', 'RED', 'UNKNOWN') NULL DEFAULT 'UNKNOWN' COMMENT 'v4: from Meta webhooks',
	`rate_per_second` SMALLINT UNSIGNED NOT NULL DEFAULT 10 COMMENT 'v4: Redis throttle ntf:rate:{school}:{channel}',
	`webhook_token` CHAR(40) NULL COMMENT 'v4: identifies this school in /ntf/hook/{provider}/{token}',
	`configuration` JSON NULL COMMENT 'Provider-specific config',
	`priority` TINYINT DEFAULT 5 COMMENT '1-Highest, 10-Lowest',
	`last_test_at` DATETIME NULL COMMENT 'v4: last "Test send" from the Channels screen',
	`last_test_status` ENUM('OK', 'FAILED') NULL,
	`last_test_message` VARCHAR(512) NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	UNIQUE KEY `uq_ntf_provider_webhook_token` (`webhook_token`),
	INDEX `idx_ntf_provider_channel` (`channel_id`, `is_active`, `priority`),
	CONSTRAINT `fk_ntf_provider_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_events  (NEW in v4)
-- Purpose: School copy of global_master.glb_ntf_events. A message type with its
--          delivery rules. School may tune: channels_json, fallback_json (within the
--          tier's allowed set), send_time_local (NORMAL / SCHEDULED only), is_enabled
--          (unless is_locked). Tier, category, is_locked, confidential are read-only.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_events` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`code` VARCHAR(80) NOT NULL COMMENT 'Same as glb_ntf_events.code',
	`module_key` varchar(10) NOT NULL,  -- FK to glb_app_modules.key
	-- `module_code` VARCHAR(50) NOT NULL,  -- Not required as we have used module_key
	`name` VARCHAR(150) NOT NULL,
	`description` VARCHAR(500) NULL,
	`tier` ENUM('CRITICAL', 'HIGH', 'NORMAL', 'SCHEDULED') NOT NULL COMMENT 'Read-only for the school',
	`category` ENUM('SEC','EMG','LIVE','APR','DEC','ASN','ACT','FIN','ACA','ANN','REM','THR','ESC','OPS','SYS','DIG','FEED') NOT NULL,  -- FK to glb_ntf_events.category
	`channels_json` JSON NOT NULL COMMENT 'School-tuned channel list; starts as Prime default',
	`fallback_json` JSON NULL,
	`quiet_hours_policy` ENUM('RESPECT', 'IGNORE') NOT NULL DEFAULT 'RESPECT',
	`send_time_local` TIME NULL COMMENT 'Optional fixed send time for NORMAL / SCHEDULED (e.g. 08:00)',
	`is_locked` TINYINT(1) NOT NULL DEFAULT 0,
	`confidential` TINYINT(1) NOT NULL DEFAULT 0,
	`dedupe_shape` VARCHAR(150) NOT NULL,
	`variables_schema_json` JSON NOT NULL,
	`default_audience_json` JSON NULL,
	`ttl_minutes` INT UNSIGNED NULL,
	`is_enabled` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Ignored when is_locked = 1',
	`school_overridden` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = channels / fallback / time tuned by the school',
	`prime_version` INT UNSIGNED NOT NULL DEFAULT 1,
	`prime_update_available` TINYINT(1) NOT NULL DEFAULT 0,
	`synced_at` DATETIME NOT NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_ntf_event_code` (`code`),
	INDEX `idx_ntf_event_tier` (`tier`, `is_enabled`),
	CONSTRAINT fk_ntf_event_code FOREIGN KEY (`code`) REFERENCES `glb_ntf_events`(`code`),
	CONSTRAINT fk_ntf_event_module_key FOREIGN KEY (`module_key`) REFERENCES `glb_app_modules`(`key`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_templates
-- Purpose: Wording per message type × channel × language. is_system_template = 1
--          rows are synced from glb_ntf_templates; the school edits its copy.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_templates` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`template_code` VARCHAR(50) NOT NULL,
	`event_code` VARCHAR(80) NULL COMMENT 'v4: ntf_events.code this template renders (NULL = free template for manual sends)',
	`template_name` VARCHAR(100) NOT NULL,
	`channel_id` INT UNSIGNED NOT NULL,
	`template_version` INT DEFAULT 1,
	`subject` VARCHAR(255) NULL,
	`body` TEXT NOT NULL,
	`alt_body` TEXT NULL COMMENT 'Plain text version',
	`placeholders` JSON NULL COMMENT 'List of required placeholders',
	`language_code` VARCHAR(10) DEFAULT 'en',
	`wa_template_name` VARCHAR(100) NULL COMMENT 'v4: name registered in the school WhatsApp account',
	`wa_variable_order_json` JSON NULL COMMENT 'v4: positional variable order for Meta',
	`wa_meta_status` ENUM('NOT_SUBMITTED', 'PENDING', 'APPROVED', 'REJECTED', 'PAUSED') NULL COMMENT 'v4: Meta template approval (WhatsApp only)',
	`media_id` INT UNSIGNED NULL,
	`is_system_template` TINYINT(1) DEFAULT 0 COMMENT '1 = copied from Prime',
	`approval_status` ENUM('DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'ARCHIVED') DEFAULT 'DRAFT',
	`approved_by` INT UNSIGNED NULL,
	`approved_at` DATETIME NULL,
	`effective_from` DATETIME NULL,
	`effective_to` DATETIME NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_by` INT UNSIGNED NOT NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	`active_flag` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED,
	UNIQUE KEY `uq_template_code_version_active` (`template_code`, `template_version`, `active_flag`),
	INDEX `idx_template_render` (`event_code`, `channel_id`, `language_code`, `approval_status`) COMMENT 'v4: send-time lookup',
	INDEX `idx_template_channel` (`channel_id`),
	INDEX `idx_template_status` (`approval_status`),
	CONSTRAINT `fk_ntf_template_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
	CONSTRAINT `fk_ntf_template_event` FOREIGN KEY (`event_code`) REFERENCES `ntf_events`(`code`) ON UPDATE CASCADE,
	CONSTRAINT `fk_ntf_template_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_notifications  (the OUTBOX in v4)
-- Purpose: One row per send request. Written in the caller's transaction;
--          Chunk(outbox_id, 0) is dispatched after commit. The chunk job resolves
--          200 people per pass (next_chunk cursor), writes recipient rows, sends.
--          Counters are updated once per chunk, never per recipient.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_notifications` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`notification_uuid` CHAR(36) NOT NULL COMMENT 'Public-facing unique ID',
	`event_code` VARCHAR(80) NULL COMMENT 'v4: ntf_events.code; NULL only for legacy manual rows',
	`tier` ENUM('CRITICAL', 'HIGH', 'NORMAL', 'SCHEDULED') NOT NULL DEFAULT 'NORMAL' COMMENT 'v4: copied from ntf_events at creation',
	`origin` ENUM('MODULE', 'RULE', 'SCHEDULE', 'ADMIN') NOT NULL DEFAULT 'MODULE' COMMENT 'v4',
	`aut_action_run_id` BIGINT UNSIGNED NULL COMMENT 'v4: aut_action_runs.id when a rule or schedule started this send',
	`source_module` VARCHAR(50) NOT NULL,
	`source_record_id` INT UNSIGNED NULL COMMENT 'ID in source module',
	`notification_event` VARCHAR(50) NOT NULL COMMENT 'Legacy name of event_code; kept for the old screens',
	`notification_type` ENUM('TRANSACTIONAL', 'PROMOTIONAL', 'ALERT', 'REMINDER', 'DIGEST') DEFAULT 'TRANSACTIONAL',
	`title` VARCHAR(255) NOT NULL,
	`description` VARCHAR(512) NULL,
	`template_id` INT UNSIGNED NULL,
	`context_json` JSON NULL COMMENT 'v4: ids + scalars for template variables (no rendered text)',
	`audience_json` JSON NOT NULL COMMENT 'v4: e.g. {"type":"guardians_of_student","student_id":1758} or {"type":"class_section","class_id":3,"section_id":1,"with_guardians":true}',
	`dedupe_base` VARCHAR(150) NOT NULL COMMENT 'v4: dedupe_shape filled for this send, e.g. FEE_DUE_REMINDER:7381:T-7',
	`priority_id` INT UNSIGNED NULL COMMENT 'v4: nullable; tier replaces it in the pipeline',
	`confidentiality_level_id` INT UNSIGNED NULL COMMENT 'v4: nullable; ntf_events.confidential is authoritative',
	-- Scheduling
	`schedule_type` ENUM('IMMEDIATE', 'SCHEDULED', 'RECURRING', 'TRIGGERED') DEFAULT 'IMMEDIATE',
	`send_at` DATETIME NULL COMMENT 'v4: UTC; NULL = now. Recurring sends are aut_schedules, not this row',
	`scheduled_at` DATETIME NULL COMMENT 'Legacy, mirrors send_at',
	`schedule_timezone` VARCHAR(50) DEFAULT 'Asia/Kolkata',
	`recurring_pattern` ENUM('NONE', 'HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM') DEFAULT 'NONE' COMMENT 'Legacy; recurring = aut_schedules',
	`recurring_expression` VARCHAR(100) NULL COMMENT 'Legacy',
	`recurring_end_at` DATETIME NULL COMMENT 'Legacy',
	`recurring_end_count` INT NULL COMMENT 'Legacy',
	`recurring_executed_count` INT DEFAULT 0 COMMENT 'Legacy',
	-- Expiry
	`expires_at` DATETIME NULL COMMENT 'TTL: recipient rows not sent by then become SKIPPED (expired)',
	-- Pipeline (v4)
	`pipeline_status` ENUM('PENDING', 'SCHEDULED', 'RUNNING', 'PAUSED', 'DONE', 'CANCELLED', 'IGNORED') NOT NULL DEFAULT 'PENDING',
	`status_reason` VARCHAR(512) NULL COMMENT 'v4: e.g. IGNORED: event disabled by school',
	`next_chunk` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v4: audience cursor (keyset page number)',
	`chunk_size` SMALLINT UNSIGNED NOT NULL DEFAULT 200,
	-- Tracking
	`total_recipients` INT DEFAULT 0 COMMENT 'Calculated per chunk',
	`sent_count` INT DEFAULT 0,
	`failed_count` INT DEFAULT 0,
	`skipped_count` INT DEFAULT 0 COMMENT 'v4: muted / no contact / not configured / expired',
	`held_count` INT DEFAULT 0 COMMENT 'v4: waiting for quiet hours to end',
	`delivered_count` INT DEFAULT 0,
	`read_count` INT DEFAULT 0,
	`click_count` INT DEFAULT 0,
	-- Cost
	`estimated_cost` DECIMAL(12,4) DEFAULT 0.0000 COMMENT 'Shown in the broadcast confirm dialog',
	`actual_cost` DECIMAL(12,4) DEFAULT 0.0000,
	-- Status (legacy display)
	`notification_status_id` INT UNSIGNED NULL COMMENT 'v4: nullable, mirrored from pipeline_status for the old screen',
	`is_manual` TINYINT(1) DEFAULT 0 COMMENT 'Composed by an admin',
	`created_by` INT UNSIGNED NULL COMMENT 'v4: nullable (rule / schedule sends have no user)',
	`approved_by` INT UNSIGNED NULL,
	`approved_at` DATETIME NULL,
	`processed_at` DATETIME NULL,
	`completed_at` DATETIME NULL,
	`paused_by` INT UNSIGNED NULL COMMENT 'v4',
	`cancelled_by` INT UNSIGNED NULL COMMENT 'v4',
	-- Audit
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	UNIQUE KEY `uq_ntf_uuid` (`notification_uuid`),
	UNIQUE KEY `uq_ntf_dedupe_base` (`dedupe_base`) COMMENT 'v4: the same send request can only exist once',
	INDEX `idx_ntf_pipeline` (`pipeline_status`, `send_at`),
	INDEX `idx_ntf_source` (`source_module`, `source_record_id`),
	INDEX `idx_ntf_event` (`event_code`, `created_at`),
	INDEX `idx_ntf_run` (`aut_action_run_id`),
	CONSTRAINT `fk_ntf_event_code` FOREIGN KEY (`event_code`) REFERENCES `ntf_events`(`code`) ON UPDATE CASCADE,
	CONSTRAINT `fk_ntf_priority` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdown_table`(`id`),
	CONSTRAINT `fk_ntf_confidentiality` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `sys_dropdown_table`(`id`),
	CONSTRAINT `fk_ntf_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
	CONSTRAINT `fk_ntf_notification_status` FOREIGN KEY (`notification_status_id`) REFERENCES `sys_dropdown_table`(`id`),
	CONSTRAINT `fk_ntf_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_ntf_aut_run` FOREIGN KEY (`aut_action_run_id`) REFERENCES `aut_action_runs`(`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_notification_channels  (DEPRECATED D3)
-- Purpose: Channel assignments per notification — used only by the old manual
--          notification screen. The pipeline reads ntf_events.channels_json.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_notification_channels` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`notification_id` INT UNSIGNED NOT NULL,
	`channel_id` INT UNSIGNED NOT NULL,
	`provider_id` INT UNSIGNED NULL,
	`template_id` INT UNSIGNED NULL COMMENT 'Override template',
	`priority_order` TINYINT DEFAULT 5,
	`sending_order` INT DEFAULT 1 COMMENT 'Sequence for fallback',
	`status_id` INT UNSIGNED NULL COMMENT 'v4: nullable (2026_06_19_200235)',
	`scheduled_at` DATETIME NULL,
	`sent_at` DATETIME NULL,
	`failure_reason` VARCHAR(512) NULL,
	`retry_count` INT DEFAULT 0,
	`max_retry` INT DEFAULT 3,
	`next_retry_at` DATETIME NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	UNIQUE KEY `uq_notification_channel_template` (`notification_id`, `channel_id`, `template_id`),
	INDEX `idx_ntf_channel_status` (`status_id`),
	CONSTRAINT `fk_ntf_channel_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
	CONSTRAINT `fk_ntf_channel_type` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
	CONSTRAINT `fk_ntf_channel_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`),
	CONSTRAINT `fk_ntf_channel_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
	CONSTRAINT `fk_ntf_channel_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_target_groups
-- Purpose: Reusable audiences. v4: dynamic_query is replaced by audience_json in the
--          same shape as ntf_notifications.audience_json, resolved by the core
--          AudienceResolver (never raw SQL).
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_target_groups` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`group_name` VARCHAR(100) NOT NULL,
	`group_code` VARCHAR(50) NOT NULL,
	`description` VARCHAR(255) NULL,
	`group_type` ENUM('STATIC', 'DYNAMIC') DEFAULT 'STATIC',
	`dynamic_query` TEXT NULL COMMENT 'Legacy free-form JSON; v4 reads audience_json',
	`audience_json` JSON NULL COMMENT 'v4: {"type":"role","role":"Teacher"} / {"type":"class_section",...}',
	`total_members` INT DEFAULT 0 COMMENT 'Calculated by the resolver (Count button)',
	`last_refreshed_at` DATETIME NULL,
	`is_system_group` TINYINT(1) DEFAULT 0,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_by` INT UNSIGNED NOT NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	`active_flag` TINYINT(1) GENERATED ALWAYS AS (CASE WHEN `deleted_at` IS NULL THEN 1 ELSE NULL END) STORED,
	UNIQUE KEY `uq_target_group_code_active` (`group_code`, `active_flag`),
	INDEX `idx_target_group_type` (`group_type`),
	CONSTRAINT `fk_ntf_target_group_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_notification_targets
-- Purpose: Target definitions for admin-composed notifications (old screen).
--          v4 rule / module sends use ntf_notifications.audience_json instead.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_notification_targets` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`notification_id` INT UNSIGNED NOT NULL,
	`target_type_id` INT UNSIGNED NOT NULL,
	`target_group_id` INT UNSIGNED NULL COMMENT 'Reusable group',
	`target_table_name` VARCHAR(60) DEFAULT NULL,
	`target_selected_id` INT UNSIGNED NULL,
	`target_condition` JSON NULL COMMENT 'Additional filters',
	`estimated_count` INT NULL COMMENT 'Pre-resolution estimate',
	`actual_count` INT NULL COMMENT 'Post-resolution count',
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	INDEX `idx_ntf_target_lookup` (`target_type_id`, `target_selected_id`),
	INDEX `idx_ntf_target_group` (`target_group_id`),
	CONSTRAINT `fk_ntf_target_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
	CONSTRAINT `fk_ntf_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdown_table`(`id`),
	CONSTRAINT `fk_ntf_target_group` FOREIGN KEY (`target_group_id`) REFERENCES `ntf_target_groups`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_user_devices
-- Purpose: The ONE push token store (gap report §4.6). The app registers its FCM
--          token after login (POST /api/devices) and deletes it on logout. An FCM
--          UNREGISTERED reply deletes the row.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_user_devices` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`user_id` INT UNSIGNED NOT NULL,
	`app` ENUM('PRIMEAPP', 'PRIMEADMIN', 'WEB') NOT NULL DEFAULT 'PRIMEAPP' COMMENT 'v4',
	`device_type` ENUM('ANDROID', 'IOS', 'WEB', 'DESKTOP') NOT NULL,
	`device_token` VARCHAR(512) NOT NULL COMMENT 'FCM registration token',
	`device_token_hash` CHAR(64) GENERATED ALWAYS AS (SHA2(`device_token`, 256)) STORED COMMENT 'v4: unique per device across users (a phone handed to another login moves its token)',
	`device_name` VARCHAR(100) NULL,
	`app_version` VARCHAR(20) NULL,
	`os_version` VARCHAR(20) NULL,
	`last_active_at` DATETIME NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY `uq_device_token_hash` (`device_token_hash`),
	INDEX `idx_device_user` (`user_id`, `app`, `is_active`),
	CONSTRAINT `fk_ntf_device_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_user_preferences
-- Purpose: Per user × channel × (optional) event. event_code NULL = the user's
--          default for that channel. Locked events (ntf_events.is_locked) ignore
--          this table entirely. Quiet hours default to sys_settings.ntf_quiet_hours_*.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_user_preferences` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`user_id` INT UNSIGNED NOT NULL,
	`channel_id` INT UNSIGNED NOT NULL,
	`event_code` VARCHAR(80) NULL COMMENT 'v4: NULL = channel default',
	`event_code_key` VARCHAR(80) GENERATED ALWAYS AS (COALESCE(`event_code`, '*')) STORED COMMENT 'v4: NULL-safe unique',
	`is_enabled` TINYINT(1) DEFAULT 1,
	`is_opted_in` TINYINT(1) DEFAULT 1 COMMENT 'Consent',
	`opted_in_at` DATETIME NULL,
	`opted_out_at` DATETIME NULL,
	`contact_value` VARCHAR(255) NULL COMMENT 'Override email/phone',
	`quiet_hours_start` TIME NULL COMMENT 'NULL = school default',
	`quiet_hours_end` TIME NULL,
	`quiet_hours_timezone` VARCHAR(50) DEFAULT 'Asia/Kolkata',
	`daily_digest` TINYINT(1) DEFAULT 0,
	`digest_time` TIME NULL,
	`priority_threshold_id` INT UNSIGNED NULL COMMENT 'Min priority to receive',
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	UNIQUE KEY `uq_user_channel_event` (`user_id`, `channel_id`, `event_code_key`),
	INDEX `idx_pref_user` (`user_id`, `is_enabled`),
	CONSTRAINT `fk_ntf_pref_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE CASCADE,
	CONSTRAINT `fk_ntf_pref_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
	CONSTRAINT `fk_ntf_pref_priority` FOREIGN KEY (`priority_threshold_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_resolved_recipients  (the per-person STATE MACHINE in v4)
-- Purpose: One row per person × channel for one send.
--          PENDING -> SENDING (lease 2 min) -> SENT -> DELIVERED -> READ
--          PENDING -> HELD (quiet hours) -> PENDING
--          PENDING -> SKIPPED (muted / no contact / not configured / expired)
--          SENDING -> PENDING (temporary error, backoff) | FAILED (permanent / 4 tries)
--          FAILED  -> fallback creates a NEW row on the next channel (fallback_of_id)
--          dedupe_key UNIQUE makes every retry, double click and re-run harmless.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_resolved_recipients` (
	`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'v4: BIGINT (one row per person per channel per send)',
	`notification_id` INT UNSIGNED NOT NULL,
	`chunk_no` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v4: which 200-person pass created it',
	`channel_id` INT UNSIGNED NOT NULL,
	`template_id` INT UNSIGNED NULL COMMENT 'v4: nullable; chosen at send time by locale',
	`notification_target_id` INT UNSIGNED NULL COMMENT 'v4: nullable; only admin-composed sends have targets',
	`user_preference_id` INT UNSIGNED NULL,
	`resolved_user_id` INT UNSIGNED NULL COMMENT 'v4: NULL for people with no login (NEW-7)',
	`contact_type` ENUM('USER', 'STUDENT', 'GUARDIAN', 'STAFF', 'APPLICANT', 'VISITOR', 'VENDOR', 'OTHER') NOT NULL DEFAULT 'USER' COMMENT 'v4',
	`contact_ref_table` VARCHAR(64) NULL COMMENT 'v4: e.g. std_guardians',
	`contact_ref_id` BIGINT UNSIGNED NULL COMMENT 'v4: e.g. std_guardians.id',
	`device_id` INT UNSIGNED NULL COMMENT 'For push notifications',
	`recipient_address` VARCHAR(255) NULL COMMENT 'Resolved email / phone (E.164) / device token hash',
	`locale` VARCHAR(10) NOT NULL DEFAULT 'en' COMMENT 'v4: from std_guardians.preferred_language etc.',
	`personalized_subject` VARCHAR(500) NULL COMMENT 'Rendered at send time (audit copy)',
	`personalized_body` TEXT NULL COMMENT 'v4: NOT stored for confidential events',
	`personalization_data` JSON NULL COMMENT 'Per-recipient variables (e.g. marks)',
	`priority` TINYINT DEFAULT 5,
	`dedupe_key` VARCHAR(191) NOT NULL COMMENT 'v4: dedupe_base + channel + recipient, UNIQUE',
	`state` ENUM('PENDING', 'HELD', 'SENDING', 'SENT', 'DELIVERED', 'READ', 'SKIPPED', 'FAILED', 'CANCELLED') NOT NULL DEFAULT 'PENDING' COMMENT 'v4',
	`lease_until` DATETIME NULL COMMENT 'v4: SENDING claim expiry; the pump returns expired leases to PENDING',
	`release_at` DATETIME NULL COMMENT 'v4: HELD until (end of quiet hours)',
	`next_attempt_at` DATETIME NULL COMMENT 'v4: backoff for temporary errors',
	`attempts` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v4',
	`reason` VARCHAR(512) NULL COMMENT 'v4: muted / no contact / not configured / provider error text',
	`provider_message_id` VARCHAR(255) NULL COMMENT 'v4: matched by provider webhooks',
	`fallback_of_id` BIGINT UNSIGNED NULL COMMENT 'v4: the FAILED row this fallback replaces',
	`sent_at` DATETIME NULL COMMENT 'v4',
	`cost` DECIMAL(10,4) NULL COMMENT 'v4',
	`batch_id` VARCHAR(36) NULL COMMENT 'Legacy',
	`batch_sequence` INT NULL COMMENT 'Legacy',
	`is_processed` TINYINT(1) DEFAULT 0 COMMENT 'Legacy; v4 reads state',
	`processed_at` DATETIME NULL,
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL,
	UNIQUE KEY `uq_ntf_recipient_dedupe` (`dedupe_key`),
	INDEX `idx_ntf_recipient_claim` (`notification_id`, `chunk_no`, `channel_id`, `state`) COMMENT 'v4: the per-chunk claim UPDATE',
	INDEX `idx_ntf_recipient_repair` (`state`, `lease_until`) COMMENT 'v4: lease repair',
	INDEX `idx_ntf_recipient_held` (`state`, `release_at`) COMMENT 'v4: quiet-hours release',
	INDEX `idx_ntf_recipient_user` (`resolved_user_id`),
	INDEX `idx_ntf_recipient_provider_msg` (`provider_message_id`),
	INDEX `idx_ntf_recipient_contact` (`contact_ref_table`, `contact_ref_id`),
	CONSTRAINT `fk_ntf_recipient_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
	CONSTRAINT `fk_ntf_recipient_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
	CONSTRAINT `fk_ntf_recipient_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
	CONSTRAINT `fk_ntf_recipient_preference` FOREIGN KEY (`user_preference_id`) REFERENCES `ntf_user_preferences`(`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_ntf_recipient_target` FOREIGN KEY (`notification_target_id`) REFERENCES `ntf_notification_targets`(`id`),
	CONSTRAINT `fk_ntf_recipient_user` FOREIGN KEY (`resolved_user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_ntf_recipient_device` FOREIGN KEY (`device_id`) REFERENCES `ntf_user_devices`(`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_ntf_recipient_fallback` FOREIGN KEY (`fallback_of_id`) REFERENCES `ntf_resolved_recipients`(`id`) ON DELETE SET NULL
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_delivery_queue  (DEPRECATED D1)
-- Purpose: Kept only so the existing Delivery Queue tab loads. Nothing writes it in v4;
--          Redis queues + recipient leases replace it. Drop with the tab.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_delivery_queue` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`resolved_recipient_id` BIGINT UNSIGNED NOT NULL COMMENT 'v4: BIGINT to match the parent',
	`notification_id` INT UNSIGNED NOT NULL,
	`channel_id` INT UNSIGNED NOT NULL,
	`provider_id` INT UNSIGNED NOT NULL,
	`queue_status` ENUM('PENDING', 'PROCESSING', 'SENT', 'FAILED', 'RETRY', 'CANCELLED') DEFAULT 'PENDING',
	`priority` TINYINT DEFAULT 5,
	`scheduled_at` DATETIME NULL,
	`locked_by` VARCHAR(50) NULL COMMENT 'Worker ID',
	`locked_at` DATETIME NULL,
	`attempt_count` INT DEFAULT 0,
	`max_attempts` INT DEFAULT 3,
	`last_error` VARCHAR(512) NULL,
	`next_attempt_at` DATETIME NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	INDEX `idx_queue_status` (`queue_status`, `scheduled_at`, `priority`),
	CONSTRAINT `fk_queue_recipient` FOREIGN KEY (`resolved_recipient_id`) REFERENCES `ntf_resolved_recipients`(`id`),
	CONSTRAINT `fk_queue_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
	CONSTRAINT `fk_queue_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
	CONSTRAINT `fk_queue_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_delivery_logs
-- Purpose: Append-only audit of every send ATTEMPT and every provider status update
--          (one recipient row can have several log rows). This is the admin delivery
--          audit only; the bell / app list read the Laravel `notifications` table.
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_delivery_logs` (
	`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'v4: BIGINT',
	`notification_id` INT UNSIGNED NOT NULL,
	`channel_id` INT UNSIGNED NOT NULL,
	`resolved_recipient_id` BIGINT UNSIGNED NULL COMMENT 'v4: nullable, BIGINT',
	`resolved_user_id` INT UNSIGNED NULL COMMENT 'v4: nullable (no-login contacts)',
	`provider_id` INT UNSIGNED NULL COMMENT 'v4: nullable (in-app / push have no school provider row)',
	`delivery_status_id` INT UNSIGNED NOT NULL,
	`delivery_stage` ENUM('QUEUED', 'SENT', 'DELIVERED', 'READ', 'CLICKED', 'BOUNCED', 'COMPLAINT', 'UNSUBSCRIBED', 'FAILED') DEFAULT 'SENT' COMMENT 'v4: + FAILED',
	`attempt_no` TINYINT UNSIGNED NULL COMMENT 'v4',
	`provider_message_id` VARCHAR(255) NULL,
	`delivered_at` DATETIME NULL,
	`read_at` DATETIME NULL,
	`clicked_at` DATETIME NULL,
	`bounced_at` DATETIME NULL,
	`complaint_at` DATETIME NULL,
	`response_code` VARCHAR(20) NULL,
	`response_payload` JSON NULL COMMENT 'Provider reply, credentials stripped',
	`error_message` VARCHAR(512) NULL,
	`duration_ms` INT NULL COMMENT 'Delivery latency',
	`ip_address` VARCHAR(45) NULL COMMENT 'For read/click tracking',
	`user_agent` VARCHAR(255) NULL,
	`cost` DECIMAL(12,4) DEFAULT 0.0000,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL COMMENT 'Reserved (DLVY-08); no SoftDeletes on the model',
	INDEX `idx_ntf_delivery_user` (`resolved_user_id`),
	INDEX `idx_ntf_delivery_status` (`delivery_status_id`, `delivery_stage`),
	INDEX `idx_ntf_delivery_provider_msg` (`provider_message_id`),
	INDEX `idx_ntf_delivery_notification` (`notification_id`),
	INDEX `idx_ntf_delivery_recipient` (`resolved_recipient_id`),
	CONSTRAINT `fk_ntf_log_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
	CONSTRAINT `fk_ntf_log_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
	CONSTRAINT `fk_ntf_log_recipient` FOREIGN KEY (`resolved_recipient_id`) REFERENCES `ntf_resolved_recipients`(`id`) ON DELETE SET NULL,
	CONSTRAINT `fk_ntf_log_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`),
	CONSTRAINT `fk_ntf_log_status` FOREIGN KEY (`delivery_status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_notification_threads  (unchanged except tenant_id removed)
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_notification_threads` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`thread_uuid` CHAR(36) NOT NULL,
	`thread_type` ENUM('CONVERSATION', 'DIGEST', 'BROADCAST') DEFAULT 'BROADCAST',
	`thread_subject` VARCHAR(255) NULL,
	`parent_thread_id` INT UNSIGNED NULL,
	`root_notification_id` INT UNSIGNED NULL,
	`total_notifications` INT DEFAULT 0 COMMENT 'Calculated',
	`participant_count` INT DEFAULT 0 COMMENT 'Calculated',
	`is_active` TINYINT(1) DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	UNIQUE KEY `uq_thread_uuid` (`thread_uuid`),
	INDEX `idx_thread_parent` (`parent_thread_id`),
	CONSTRAINT `fk_thread_parent` FOREIGN KEY (`parent_thread_id`) REFERENCES `ntf_notification_threads`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_notification_thread_members  (unchanged)
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_notification_thread_members` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`thread_id` INT UNSIGNED NOT NULL,
	`notification_id` INT UNSIGNED NOT NULL,
	`sequence_order` INT DEFAULT 1,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL DEFAULT NULL,
	UNIQUE KEY `uq_thread_notification` (`thread_id`, `notification_id`),
	CONSTRAINT `fk_thread_member_thread` FOREIGN KEY (`thread_id`) REFERENCES `ntf_notification_threads`(`id`),
	CONSTRAINT `fk_thread_member_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------------------------------
-- TABLE: ntf_schedule_audit  (DEPRECATED D2 — replaced by aut_schedule_runs)
-- ----------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ntf_schedule_audit` (
	`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	`notification_id` INT UNSIGNED NOT NULL,
	`scheduled_instance_id` INT UNSIGNED NULL COMMENT 'Child notification ID',
	`scheduled_execution_time` DATETIME NOT NULL,
	`actual_execution_time` DATETIME NULL,
	`execution_status` ENUM('PENDING', 'SUCCESS', 'FAILED', 'SKIPPED') DEFAULT 'PENDING',
	`error_message` VARCHAR(512) NULL,
	`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	`deleted_at` TIMESTAMP NULL COMMENT 'Present live (2026_06_20_123003)',
	INDEX `idx_schedule_notification` (`notification_id`, `scheduled_execution_time`),
	CONSTRAINT `fk_schedule_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
