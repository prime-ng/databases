-- ============================================================================
-- DASHBOARD INSIGHTS DDL — dsh_ prefix (tenant database)
-- Version: 1.0 — 2026-10-20
-- Alerts / suggestions / KPI cards on the role dashboards.
-- Rules run on a schedule (php artisan tenant:insights:run, daily 05:30) and write
-- cards here; dashboards only READ these tables. Nothing here changes school data.
-- Migrations: database/migrations/tenant/2026_10_20_00000{1..4}_create_dsh_*.php
-- Exported from the live tenant schema (test.localhost) after migration.
-- Depends on: sys_users, sch_org_academic_sessions_jnt
-- ============================================================================

-- 1. dsh_insight_rules — the rule registry. One row per rule class in Modules/Dashboard/config/insights.php,
--    synced by DashboardInsightRuleSeeder. A school may override params / roles / is_active; the seeder never overwrites them.
CREATE TABLE IF NOT EXISTS `dsh_insight_rules` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `rule_key` varchar(20) NOT NULL COMMENT 'Catalogue id, e.g. LMS-07',
  `module` varchar(50) NOT NULL COMMENT 'Source module, e.g. LmsHomework',
  `title` varchar(150) NOT NULL,
  `description` varchar(500) DEFAULT NULL COMMENT 'Plain-words rule, shown as "Why am I seeing this?"',
  `type` enum('alert','suggestion','kpi') NOT NULL DEFAULT 'alert',
  `area` varchar(30) NOT NULL COMMENT 'Dashboard group: academics, students, staff, finance, operations, compliance, system',
  `severity` decimal(3,2) NOT NULL DEFAULT '0.60' COMMENT '0-1; safety 1.0, money/compliance 0.8, quality 0.6, efficiency 0.4',
  `schedule` enum('daily','hourly') NOT NULL DEFAULT 'daily',
  `default_params` json DEFAULT NULL COMMENT 'Thresholds from the rule class',
  `params` json DEFAULT NULL COMMENT 'School override of default_params; NULL = defaults',
  `default_roles` json DEFAULT NULL COMMENT 'Role names (sys_roles.name) from the rule class',
  `roles` json DEFAULT NULL COMMENT 'School override of default_roles; NULL = defaults',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_run_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dsh_rule_key` (`rule_key`),
  KEY `idx_dsh_rule_active_schedule` (`is_active`,`schedule`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. dsh_insights — one row per detected condition on one entity (the card).
--    open_fingerprint is NULL once resolved, so the unique index allows only ONE live card per fingerprint
--    while keeping any number of resolved history rows (avoids the NULL-distinct trap of a plain unique).
CREATE TABLE IF NOT EXISTS `dsh_insights` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` int unsigned NOT NULL,
  `fingerprint` char(40) NOT NULL COMMENT 'sha1 of rule + entity',
  `status` enum('open','acknowledged','assigned','snoozed','dismissed','resolved') NOT NULL DEFAULT 'open',
  `open_fingerprint` char(40) GENERATED ALWAYS AS ((case when (`status` <> _utf8mb4'resolved') then `fingerprint` else NULL end)) STORED COMMENT 'Generated: fingerprint while live, NULL once resolved',
  `entity_type` varchar(60) NOT NULL COMMENT 'What the card is about, e.g. teacher, vehicle',
  `entity_id` bigint unsigned DEFAULT NULL,
  `academic_session_id` smallint unsigned DEFAULT NULL,
  `headline` varchar(255) NOT NULL,
  `payload` json DEFAULT NULL COMMENT 'Evidence series, baseline, numbers, link',
  `impact_count` int unsigned DEFAULT NULL COMMENT 'Students / staff / items affected',
  `impact_amount` decimal(14,2) DEFAULT NULL COMMENT 'Rupees affected',
  `confidence` decimal(4,3) NOT NULL DEFAULT '1.000',
  `priority_score` decimal(5,2) NOT NULL DEFAULT '0.00' COMMENT '0-100, see PriorityScorer',
  `since_date` date DEFAULT NULL COMMENT 'When the condition started, per the rule evidence',
  `assignee_id` int unsigned DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `snoozed_until` datetime DEFAULT NULL,
  `first_detected_at` datetime NOT NULL,
  `last_detected_at` datetime NOT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dsh_insight_open_fingerprint` (`open_fingerprint`),
  KEY `fk_dsh_insight_session` (`academic_session_id`),
  KEY `idx_dsh_insight_status_priority` (`status`,`priority_score`),
  KEY `idx_dsh_insight_rule_status` (`rule_id`,`status`),
  KEY `idx_dsh_insight_assignee_status` (`assignee_id`,`status`),
  KEY `idx_dsh_insight_fingerprint` (`fingerprint`),
  CONSTRAINT `fk_dsh_insight_assignee` FOREIGN KEY (`assignee_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_dsh_insight_rule` FOREIGN KEY (`rule_id`) REFERENCES `dsh_insight_rules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_dsh_insight_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. dsh_insight_actions — append-only audit trail of everything that happened to a card.
CREATE TABLE IF NOT EXISTS `dsh_insight_actions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `insight_id` bigint unsigned NOT NULL,
  `action` enum('detected','acknowledged','assigned','snoozed','snooze_expired','dismissed','reopened','auto_resolved','opened_link') NOT NULL,
  `actor_id` int unsigned DEFAULT NULL,
  `assignee_id` int unsigned DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `snoozed_until` datetime DEFAULT NULL,
  `reason_code` varchar(40) DEFAULT NULL COMMENT 'Dismiss reason: not_a_problem, already_handled, wrong_data, too_sensitive, other',
  `note` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_dsh_action_actor` (`actor_id`),
  KEY `fk_dsh_action_assignee` (`assignee_id`),
  KEY `idx_dsh_action_insight_time` (`insight_id`,`created_at`),
  KEY `idx_dsh_action_type_time` (`action`,`created_at`),
  CONSTRAINT `fk_dsh_action_actor` FOREIGN KEY (`actor_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_dsh_action_assignee` FOREIGN KEY (`assignee_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_dsh_action_insight` FOREIGN KEY (`insight_id`) REFERENCES `dsh_insights` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. dsh_insight_runs — one row per rule evaluation (scheduled or manual), for monitoring.
CREATE TABLE IF NOT EXISTS `dsh_insight_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` int unsigned NOT NULL,
  `trigger` enum('schedule','manual') NOT NULL DEFAULT 'schedule',
  `status` enum('running','success','failed') NOT NULL DEFAULT 'running',
  `started_at` datetime NOT NULL,
  `finished_at` datetime DEFAULT NULL,
  `duration_ms` int unsigned DEFAULT NULL,
  `findings_count` int unsigned NOT NULL DEFAULT '0',
  `opened_count` int unsigned NOT NULL DEFAULT '0',
  `updated_count` int unsigned NOT NULL DEFAULT '0',
  `resolved_count` int unsigned NOT NULL DEFAULT '0',
  `error_message` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dsh_run_rule_time` (`rule_id`,`started_at`),
  KEY `idx_dsh_run_status_time` (`status`,`started_at`),
  CONSTRAINT `fk_dsh_run_rule` FOREIGN KEY (`rule_id`) REFERENCES `dsh_insight_rules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Permissions (config/permissionslist.php — not DDL, created by /school-setup/sync-permissions)
--   tenant.dashboard.insights.viewAny           see the cards
--   tenant.dashboard.insights.act               acknowledge / assign / snooze / dismiss / reopen
--   tenant.dashboard.insight-settings.viewAny   open the per-school rule settings page
--   tenant.dashboard.insight-settings.update    switch rules on/off, change roles and thresholds
-- ============================================================================
