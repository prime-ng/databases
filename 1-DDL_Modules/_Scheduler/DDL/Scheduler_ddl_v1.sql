




-- Tab-4.3: Scheduled run definitions (Phase 2 — included now for forward compatibility, unused in Phase 1 UI)
CREATE TABLE IF NOT EXISTS `tst_schedules` (
  `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `name`             VARCHAR(150) NOT NULL,
  `scope_json`       JSON NOT NULL,               -- same shape as tst_test_runs.scope_json
  `cron_expression`  VARCHAR(100) NOT NULL,       -- 
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `last_run_id`      INT UNSIGNED NULL,           -- FK tst_test_runs.id of most recent scheduled run
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  UNIQUE KEY `uq_tst_schedules_name` (`name`),
  INDEX `idx_tst_schedules_active` (`is_active`),
  CONSTRAINT `fk_tst_schedules_lastRun` FOREIGN KEY (`last_run_id`) REFERENCES `tst_test_runs`(`id`) ON DELETE SET NUL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


