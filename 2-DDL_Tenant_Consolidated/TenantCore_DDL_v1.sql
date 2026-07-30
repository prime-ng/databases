-- =============================================================================
-- TCO — Tenant_Core Module DDL
-- Module: TenantCore (Modules\TenantCore)
-- Table Prefixes: tco_* (1 table)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-07-25
-- =============================================================================

-- This table will capture the activity logs for Tenants.
-- ------------------------------------------------------------------------

CREATE TABLE `tco_central_activity_logs` (
  `id` bigint UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `subject_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` int UNSIGNED NOT NULL,
  `event` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `properties` json DEFAULT NULL,
  `ip_address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
  INDEX `idx_tco_centralActivityLogs_subjectType_subjectId` (`subject_type`, `subject_id`),
  INDEX `idx_tco_centralActivityLogs_userId` (`user_id`),
  INDEX `idx_tco_centralActivityLogs_createdAt_userId` (`created_at`, `user_id`),
  CONSTRAINT `fk_tco_centralActivityLogs_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tco_central_activity_logs`
--

INSERT INTO `tco_central_activity_logs` (`id`, `subject_type`, `subject_id`, `user_id`, `event`, `properties`, `ip_address`, `user_agent`, `created_at`, `updated_at`) VALUES
(1, 'Modules\\Prime\\Models\\Tenant', 'ed574a75-79b2-472c-b2df-4591676e3479', 1, 'created', '{\"message\": \"New school \'Test Public School\' registered. Database setup queued.\"}', '127.0.0.1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-09 14:21:31', '2026-07-09 14:21:31'),
(2, 'Modules\\GlobalMaster\\Models\\Module', '1', 1, 'updated', '{\"changes\": {\"available_perm_add\": {\"new\": false, \"old\": true}, \"available_perm_edit\": {\"new\": false, \"old\": true}, \"available_perm_view\": {\"new\": false, \"old\": true}, \"available_perm_print\": {\"new\": false, \"old\": true}, \"available_perm_delete\": {\"new\": false, \"old\": true}, \"available_perm_export\": {\"new\": false, \"old\": true}, \"available_perm_import\": {\"new\": false, \"old\": true}}, \"message\": \"Module was updated.\", \"performed_by\": \"Super Admin\"}', '127.0.0.1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-09 14:27:07', '2026-07-09 14:27:07'),
(3, 'Modules\\GlobalMaster\\Models\\Module', '1', 1, 'Updated', '{\"other\": \"some other information\", \"message\": \"A new module was updated.\"}', '127.0.0.1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-09 14:27:07', '2026-07-09 14:27:07');


