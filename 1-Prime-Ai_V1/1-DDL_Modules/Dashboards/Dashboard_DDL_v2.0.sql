-- ===============================================================================================================================
-- DASHBOARD INSIGHTS DDL — dsh_ prefix (tenant database)
-- Version: 1.0 — 2026-10-20
-- Alerts / suggestions / KPI cards on the role dashboards.
-- Rules run on a schedule (php artisan tenant:insights:run, daily 05:30) and write cards here; 
-- dashboards only READ these tables.Nothing here changes school data.
-- Migrations: database/migrations/tenant/2026_10_20_00000{1..4}_create_dsh_*.php
-- Exported from the live tenant schema (test.localhost) after migration.
-- Depends on: sys_users, sch_org_academic_sessions_jnt
-- ===============================================================================================================================


  -- 1. dsh_role_dashboards - Role → landing dashboard. After login the user is redirected to the dashboard_url of their role
  --    (resolved by LoginRedirectResolver); a role with no row keeps the old hardcoded redirect.
  --    One dashboard per role: the unique key is on role_id ALONE. A (role_id, deleted_at) key would not
  --    hold, as MySQL treats NULLs as distinct. Re-adding a soft-deleted role's row restores that row.
  -- ------------------------------------------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `dsh_role_dashboards` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `role_id` INT unsigned NOT NULL,              -- FK to sys_roles
    `dashboard_url` varchar(255) NOT NULL,        -- RELATIVE path, e.g. /dashboard/transport (never a full URL, so one row works on every tenant domain)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_role_dashboard_role` (`role_id`),
    CONSTRAINT `fk_role_dashboard_role` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 1. dsh_insight_rules — the rule registry. One row per rule class in Modules/Dashboard/config/insights.php,
--    synced by DashboardInsightRuleSeeder. A school may override params / roles / is_active; the seeder never overwrites them.
-- ------------------------------------------------------------------------------------------------------------------------------ 
CREATE TABLE IF NOT EXISTS `dsh_insight_rules` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `rule_key` varchar(20) NOT NULL COMMENT 'Catalogue id, e.g. LMS-07',
  `module_key` varchar(10) NOT NULL, -- FK to glb_app_modules.key
  `title` varchar(150) NOT NULL,
  `description` varchar(500) DEFAULT NULL COMMENT 'Plain-words rule, shown as "Why am I seeing this?"',
  `type` enum('Alert','Suggestion','KPI') NOT NULL DEFAULT 'Alert',
  `module_area` varchar(30) NOT NULL, -- FK to glb_app_modules.code
  -- `area` varchar(30) NOT NULL COMMENT 'Dashboard group: academics, students, staff, finance, operations, compliance, system',
  `schedule` enum('Monthly','Weekly','Daily','Hourly') NOT NULL DEFAULT 'Daily',
  `default_severity` decimal(3,2) NOT NULL DEFAULT '0.60' COMMENT '0-1; safety 1.0, money/compliance 0.8, quality 0.6, efficiency 0.4',
  `default_params` json DEFAULT NULL COMMENT 'Thresholds from the rule class',
  `params` json DEFAULT NULL COMMENT 'School override of default_params; NULL = defaults',
  `default_roles` json DEFAULT NULL COMMENT 'Role names (sys_roles.name) from the rule class',
  `roles` json DEFAULT NULL COMMENT 'School override of default_roles; NULL = defaults',
  `default_visibility` tinyint(1) NOT NULL DEFAULT '1',  -- Default visibility on all the dashboards
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_run_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dsh_rule_key` (`rule_key`),
  KEY `idx_dsh_rule_active_schedule` (`is_active`,`schedule`),
  CONSTRAINT `fk_dsh_rule_module_area` FOREIGN KEY (`module_area`) REFERENCES `glb_app_modules` (`code`) ON DELETE RESTRICT,
  CONSTRAINT `fk_dsh_rule_module_key` FOREIGN KEY (`module_key`) REFERENCES `glb_app_modules` (`key`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `dsh_dashboard_insight_rule_jnt` (
  `dashboard_id` INT unsigned NOT NULL,
  `rule_id` INT unsigned NOT NULL,
  `dashboard_severity` decimal(3,2) NOT NULL DEFAULT '0.60',  -- Role(dashboard) wise severity ()'0-1; safety 1.0, quality 0.6, efficiency 0.4')
  `is_visible` tinyint(1) NOT NULL DEFAULT '1',               -- Role(dashboard) wise visibility
  PRIMARY KEY (`dashboard_id`,`rule_id`),
  KEY `fk_dsh_dashboard_insight_rule_jnt_dashboard_id` (`dashboard_id`),
  KEY `fk_dsh_dashboard_insight_rule_jnt_rule_id` (`rule_id`),
  CONSTRAINT `fk_dsh_dashboard_insights_jnt_dashboard_id` FOREIGN KEY (`dashboard_id`) REFERENCES `dsh_role_dashboards` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_dsh_dashboard_insights_jnt_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `dsh_insight_rules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. dsh_insights — one row per detected condition on one entity (the card).
--    open_fingerprint is NULL once resolved, so the unique index allows only ONE live card per fingerprint
--    while keeping any number of resolved history rows (avoids the NULL-distinct trap of a plain unique).
-- ------------------------------------------------------------------------------------------------------------------------------ 
CREATE TABLE IF NOT EXISTS `dsh_insights` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` int unsigned NOT NULL,
  `fingerprint` char(40) NOT NULL COMMENT 'sha1 of rule + entity',
  `status` enum('Open','Acknowledged','Assigned','Snoozed','Dismissed','Resolved') NOT NULL DEFAULT 'Open',
  `open_fingerprint` char(40) GENERATED ALWAYS AS ((case when (`status` <> _utf8mb4'Resolved') then `fingerprint` else NULL end)) STORED, -- Generated: fingerprint while live, NULL once resolved
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
-- ------------------------------------------------------------------------------------------------------------------------------ 
CREATE TABLE IF NOT EXISTS `dsh_insight_actions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `insight_id` bigint unsigned NOT NULL,
  `action` enum('Detected','Acknowledged','Assigned','Snoozed','Snooze_Expired','Dismissed','Reopened','Auto_Resolved','Opened_Link') NOT NULL,
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
-- ------------------------------------------------------------------------------------------------------------------------------ 
CREATE TABLE IF NOT EXISTS `dsh_insight_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` int unsigned NOT NULL,
  `trigger` enum('Schedule','Manual') NOT NULL DEFAULT 'Schedule',
  `status` enum('Running','Success','Failed') NOT NULL DEFAULT 'Running',
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
