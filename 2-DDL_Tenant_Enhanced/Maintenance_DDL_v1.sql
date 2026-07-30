-- =============================================================================
-- MNT — MAINTENANCE Module DDL
-- Module: Maintenance (Modules\Maintenance)
-- Table Prefixes: mnt_*
-- Database: global_db
-- Generated: 2026-07-24
-- Version: 1.0
-- =============================================================================


-- This table will capture the backup schedules.
-- ------------------------------------------------------------------------
CREATE TABLE `mnt_backup_schedules` (
  `id` bigint UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `label` varchar(255) NOT NULL,
  `databases_json` json NOT NULL,
  `all_tenants` tinyint(1) NOT NULL DEFAULT '0',
  `include_files` tinyint(1) NOT NULL DEFAULT '0',
  `cron_expression` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_run_at` timestamp NULL DEFAULT NULL,
  `next_run_at` timestamp NULL DEFAULT NULL,
  `created_by` int UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  INDEX `mnt_backup_schedules_created_by_foreign` (`created_by`),
  INDEX `mnt_backup_schedules_is_active_index` (`is_active`),
  CONSTRAINT `mnt_backup_schedules_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This table will capture the backup runs.
-- ------------------------------------------------------------------------
CREATE TABLE `mnt_backup_runs` (
  `id` bigint UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(255) NOT NULL,
  `databases_json` json NOT NULL,
  `all_tenants` tinyint(1) NOT NULL DEFAULT '0',
  `include_files` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('Pending','Running','Completed','Completed_with_warnings','Failed','Cancelled','Paused') NOT NULL DEFAULT 'Pending',
  `progress` tinyint UNSIGNED NOT NULL DEFAULT '0',
  `disk_path` varchar(255) DEFAULT NULL,
  `remote_disk` varchar(255) DEFAULT NULL,
  `remote_path` varchar(255) DEFAULT NULL,
  `file_size_bytes` bigint UNSIGNED DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `triggered_by` int UNSIGNED DEFAULT NULL,     -- fk to sys_users
  `error_message` text,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  INDEX `idx_mnt_backupRuns_triggeredBy` (`triggered_by`),
  INDEX `idx_mnt_backupRuns_status` (`status`),
  INDEX `idx_mnt_backupRuns_createdAt` (`created_at`),
  CONSTRAINT `fk_mnt_backupRuns_triggeredBy` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- This table will capture the archive access requests.
-- ------------------------------------------------------------------------

CREATE TABLE `mnt_tenant_archive_access_requests` (
  `id` bigint UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  -- `tenant_id` varchar(255) NOT NULL,
  `tenant_code` varchar(20) NOT NULL,
  `archive_tenant_id` varchar(255) NOT NULL,
  `requested_by_user_id` INT UNSIGNED DEFAULT NULL,
  `requested_by_tenant_user_id` bigint UNSIGNED DEFAULT NULL,
  `requested_by_tenant_user_email` varchar(255) DEFAULT NULL,
  `requested_by_tenant_user_name` varchar(100) DEFAULT NULL,
  `status` enum('pending','approved','rejected','revoked') NOT NULL DEFAULT 'pending',
  `approved_by_user_id` bigint UNSIGNED DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `admin_remark` text,
  `requested_duration_minutes` int UNSIGNED DEFAULT NULL,
  `granted_duration_minutes` int UNSIGNED DEFAULT NULL,
  `access_ip_address` varchar(45) DEFAULT NULL,
  `access_expired_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  INDEX `idx_mnt_taar_tenantCode` (`tenant_code`),
  INDEX `idx_mnt_taar_archiveTenantId_status` (`archive_tenant_id`,`status`);
  UNIQUE KEY `uq_mnt_taar_tenantId_archiveTenantId` (`tenant_id`,`archive_tenant_id`),
  CONSTRAINT `fk_mnt_taar_requestedByUserId` FOREIGN KEY (`requested_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Condition:
-- 
-- ========================================================================================================================================
-- Change Log
-- ========================================================================================================================================
-- Table : mnt_backup_runs; Column : status; Added more Enums
-- 