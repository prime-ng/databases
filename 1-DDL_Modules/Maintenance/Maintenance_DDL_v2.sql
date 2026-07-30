-- =============================================================================
-- MNT — MAINTENANCE (BACKUP, ARCHIVE, RETENTION & RESTORE) MODULE DDL
-- =============================================================================
-- Module        : Maintenance (Modules\Maintenance)
-- Module Code   : MNT
-- Table Prefix  : mnt_        (20 tables)
-- Target DB     : prime_db    (CENTRAL / control-plane database)
-- Engine        : MySQL 8.x  | InnoDB | utf8mb4 / utf8mb4_unicode_ci
-- Version       : 2.0
-- Supersedes    : 2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql (3 tables)
-- Generated     : 2026-07-27
-- =============================================================================
--
-- WHY prime_db AND NOT tenant_db / global_db
-- ------------------------------------------
-- This module is a CONTROL-PLANE module. It backs up EVERY tenant database and
-- every tenant's media store. Its catalogue therefore cannot live inside a
-- tenant database (a tenant DB that is corrupt/dropped would take its own
-- backup catalogue down with it — the single worst failure mode for a backup
-- system). All FK anchors it needs (`prm_tenant`, `prm_tenant_domains`,
-- `sys_users`, `bil_tenant_invoices`) already live in `prime_db`.
-- v1 declared `global_db`; that is corrected here.
--
-- PREFIX COLLISION NOTICE
-- -----------------------
-- `1-DDL_Modules/_Maintenance/Claude_Plan/MNT_DDL_v1.sql` defines a DIFFERENT
-- module (physical asset / ticket / AMC maintenance) that also uses `mnt_` but
-- in `tenant_db`. The two never share a schema, so there is no hard collision,
-- but Laravel model/table registration must keep them in separate connections.
-- RECOMMENDATION: rename this module's prefix to `bkp_` (Backup & Archive) at
-- the next review to remove the ambiguity permanently. Prefix kept as `mnt_`
-- in v2 to stay aligned with `0-Prime_Ai_Detail/module_list.md`.
--
-- =============================================================================
-- EVALUATION OF v1  (what was wrong / missing)
-- =============================================================================
-- A. HARD SQL ERRORS in v1
--    A1. `mnt_tenant_archive_access_requests`: line ending `... ,`status`);`
--        used a SEMICOLON instead of a comma — the CREATE TABLE cannot parse.
--    A2. Same table: UNIQUE KEY references `tenant_id`, but that column is
--        commented out — unknown column error.
--    A3. `approved_by_user_id` declared BIGINT UNSIGNED while `sys_users`.`id`
--        is INT UNSIGNED — FK impossible; no FK was declared at all.
--    A4. `requested_by_tenant_user_id` BIGINT UNSIGNED with no target table
--        and no FK — orphan column.
--
-- B. CONVENTION VIOLATIONS (AI_Brain/memory/conventions.md)
--    B1. PKs used BIGINT UNSIGNED; prime_db standard is INT UNSIGNED.
--    B2. No `deleted_at`, no `is_active`, no `updated_by` on any table.
--    B3. `created_by` FK used ON DELETE CASCADE — deleting a user would delete
--        the backup schedule. Must be RESTRICT / SET NULL.
--    B4. Redundant per-column COLLATE on a table that already declares it.
--
-- C. FUNCTIONAL GAPS (the requirement is ~20% covered by v1)
--    C1. RETENTION IS ENTIRELY ABSENT. No retention policy, no backup end
--        date, no purge, no extension. This is the core of the request.
--    C2. No paid-extension workflow and no link to `bil_tenant_invoices`.
--    C3. `databases_json` / `all_tenants` blob means you cannot answer
--        "did tenant X's backup succeed on 12-Jul?" — no per-tenant row,
--        no per-tenant size, path, status or retention date.
--    C4. No file-level catalogue (path, filename, mime, size, checksum,
--        multi-part volumes) — the requirement asks for exactly this.
--    C5. No integrity data: no checksum, no encryption, no compression,
--        no verification / test-restore record. A backup you never verified
--        is not a backup.
--    C6. No RESTORE side at all, though the module is titled Backup & Restore.
--    C7. No activity log table, though "complete Log for all the activities"
--        is an explicit requirement.
--    C8. No maintenance PLAN entity — "different maintenance plans for
--        different Schools" cannot be expressed.
--    C9. Storage target was two free-text strings (`remote_disk`,
--        `remote_path`) — no destination master, no credentials reference,
--        no storage class/tier, no offsite copy tracking.
--    C10. Archive access request had no session/credential/expiry lifecycle,
--         no audit of what was accessed.
--
-- D. POINTS THE REQUIREMENT DID NOT MENTION BUT THE MODULE NEEDS
--    D1. Pre-restore safety backup (auto-snapshot before any overwrite).
--    D2. Legal hold — freeze purge regardless of retention expiry.
--    D3. Backup verification / periodic test-restore drill.
--    D4. Maintenance windows (announced downtime) + tenant notification.
--    D5. Incremental / differential chains (`parent_run_id`) so a purge never
--        orphans a chain child.
--    D6. Per-tenant storage usage snapshots — needed to bill GB-months.
--    D7. Expiry pre-warning alerts (T-30 / T-15 / T-7 / T-1) with dedupe.
--    D8. RPO / RTO targets per plan, and SLA breach detection.
--    D9. Purge approval + reclaimed-bytes audit (compliance evidence).
--    D10. Encryption key REFERENCE (vault path) — never the key itself.
--    D11. Multi-part / chunked archive volumes for very large tenants.
--    D12. GDPR / DPDP erasure as a first-class purge reason.
--
-- =============================================================================
-- TABLE INVENTORY (creation order = FK dependency order)
-- =============================================================================
--  LAYER 1 — CONFIGURATION MASTERS
--   1. mnt_storage_destinations          Where backups physically live
--   2. mnt_retention_policies            How long, and what it costs to extend
--   3. mnt_maintenance_plans             Per-tenant plan (policy + destination)
--  LAYER 2 — SCHEDULING
--   4. mnt_backup_schedules              Cron definitions
--   5. mnt_schedule_tenant_jnt           Explicit tenant targeting
--   6. mnt_maintenance_windows           Announced downtime windows
--  LAYER 3 — EXECUTION CATALOGUE
--   7. mnt_backup_runs                   One row per execution (header)
--   8. mnt_backup_run_items              One row per tenant per content type
--   9. mnt_backup_files                  One row per physical file / volume
--  10. mnt_backup_verifications          Checksum / test-restore evidence
--  LAYER 4 — RESTORE
--  11. mnt_restore_requests              Ask + approval
--  12. mnt_restore_runs                  Execution + rollback
--  LAYER 5 — RETENTION, ARCHIVE ACCESS, PURGE
--  13. mnt_retention_extension_requests  Paid extension of backup end date
--  14. mnt_retention_extension_item_jnt  Which backups the extension covers
--  15. mnt_archive_access_requests       Tenant asks to read archived data
--  16. mnt_archive_access_sessions       Granted, time-boxed access session
--  17. mnt_purge_logs                    Deletion evidence
--  LAYER 6 — OBSERVABILITY
--  18. mnt_activity_logs                 Full module activity trail
--  19. mnt_alert_dispatches              Notifications sent (deduped)
--  20. mnt_storage_usage_snapshots       Daily GB per tenant (billing input)
-- =============================================================================


-- =============================================================================
-- LAYER 1 — CONFIGURATION MASTERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. mnt_storage_destinations
--    Master of every physical place a backup can be written. Replaces v1's
--    free-text `disk_path` / `remote_disk` / `remote_path`.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_storage_destinations` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                    VARCHAR(30)  NOT NULL,                 -- 'LOCAL_NAS','S3_MUM','WASABI_OFFSITE'
  `short_name`              VARCHAR(50)  NOT NULL,                 -- dropdown label
  `name`                    VARCHAR(150) NOT NULL,
  `driver`                  ENUM('LOCAL','SFTP','FTP','S3','S3_COMPATIBLE','AZURE_BLOB','GCS','GOOGLE_DRIVE','DROPBOX','BACKBLAZE_B2','WASABI','TAPE') NOT NULL DEFAULT 'LOCAL',
  `laravel_disk_name`       VARCHAR(60)  DEFAULT NULL,             -- key in config/filesystems.php
  `region`                  VARCHAR(50)  DEFAULT NULL,
  `bucket_or_share`         VARCHAR(150) DEFAULT NULL,
  `base_path`               VARCHAR(255) NOT NULL DEFAULT '/',     -- root prefix under which MNT writes
  `endpoint_url`            VARCHAR(255) DEFAULT NULL,
  `credential_ref`          VARCHAR(255) DEFAULT NULL,             -- vault/ENV key name — NEVER the secret
  `is_offsite`              TINYINT(1)   NOT NULL DEFAULT 0,       -- satisfies the 3-2-1 rule
  `is_immutable`            TINYINT(1)   NOT NULL DEFAULT 0,       -- WORM / object-lock enabled (ransomware guard)
  `default_storage_class`   ENUM('HOT','WARM','COLD','ARCHIVE','DEEP_ARCHIVE') NOT NULL DEFAULT 'HOT',
  `supports_server_side_encryption` TINYINT(1) NOT NULL DEFAULT 0,
  `capacity_bytes`          BIGINT UNSIGNED DEFAULT NULL,          -- NULL = elastic / unmetered
  `used_bytes`              BIGINT UNSIGNED NOT NULL DEFAULT 0,    -- refreshed by StorageUsageJob
  `low_space_threshold_pct` TINYINT UNSIGNED NOT NULL DEFAULT 85,  -- raise alert above this
  `bandwidth_limit_mbps`    SMALLINT UNSIGNED DEFAULT NULL,        -- throttle so backups do not choke the app
  `cost_per_gb_month`       DECIMAL(10,4) NOT NULL DEFAULT 0.0000, -- feeds extension pricing
  `currency`                CHAR(3)      NOT NULL DEFAULT 'INR',
  `health_status`           ENUM('HEALTHY','DEGRADED','UNREACHABLE','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
  `last_health_check_at`    TIMESTAMP    NULL DEFAULT NULL,
  `priority`                TINYINT UNSIGNED NOT NULL DEFAULT 10,  -- lower = preferred target
  `is_default`              TINYINT(1)   NOT NULL DEFAULT 0,
  `default_flag`            TINYINT GENERATED ALWAYS AS (CASE WHEN `is_default` = 1 THEN 1 ELSE NULL END) STORED,
  `remarks`                 VARCHAR(255) DEFAULT NULL,
  `is_active`               TINYINT(1)   NOT NULL DEFAULT 1,
  `created_by`              INT UNSIGNED DEFAULT NULL,
  `updated_by`              INT UNSIGNED DEFAULT NULL,
  `created_at`              TIMESTAMP    NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP    NULL DEFAULT NULL,
  `deleted_at`              TIMESTAMP    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntStorageDest_code`        (`code`),
  UNIQUE KEY `uq_mntStorageDest_defaultFlag` (`default_flag`),     -- exactly one default
  KEY `idx_mntStorageDest_driver_isActive`   (`driver`,`is_active`),
  KEY `idx_mntStorageDest_health`            (`health_status`),
  CONSTRAINT `fk_mntStorageDest_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntStorageDest_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntStorageDest_threshold` CHECK (`low_space_threshold_pct` BETWEEN 1 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. At least ONE destination with is_offsite = 1 must be active, otherwise the
--     3-2-1 rule is broken; the app must raise a config warning.
--  2. `credential_ref` stores a lookup key only. Storing a live secret here is a
--     security defect — see AI_Brain/rules/security-rules.md.
--  3. A destination with is_immutable = 1 cannot be selected by purge jobs until
--     its object-lock period has elapsed.


-- -----------------------------------------------------------------------------
-- 2. mnt_retention_policies
--    "How long do we keep it, and what does it cost to keep it longer."
--    Grandfather-Father-Son (GFS) tiering + paid-extension price book.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_retention_policies` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`                        VARCHAR(30)  NOT NULL,             -- 'STD_90D','GOLD_7Y','TRIAL_7D'
  `short_name`                  VARCHAR(50)  NOT NULL,
  `name`                        VARCHAR(150) NOT NULL,
  `description`                 VARCHAR(500) DEFAULT NULL,
  -- --- GFS retention tiers ---------------------------------------------------
  `keep_daily_days`             SMALLINT UNSIGNED NOT NULL DEFAULT 7,
  `keep_weekly_weeks`           SMALLINT UNSIGNED NOT NULL DEFAULT 4,
  `keep_monthly_months`         SMALLINT UNSIGNED NOT NULL DEFAULT 12,
  `keep_yearly_years`           SMALLINT UNSIGNED NOT NULL DEFAULT 3,
  `keep_last_n_full`            SMALLINT UNSIGNED NOT NULL DEFAULT 3,  -- floor: never drop below N fulls
  -- --- Absolute bounds -------------------------------------------------------
  `default_retention_days`      SMALLINT UNSIGNED NOT NULL DEFAULT 90, -- drives backup_end_date
  `min_retention_days`          SMALLINT UNSIGNED NOT NULL DEFAULT 30, -- statutory floor
  `max_retention_days`          SMALLINT UNSIGNED DEFAULT NULL,        -- NULL = unbounded
  `grace_period_days`           SMALLINT UNSIGNED NOT NULL DEFAULT 7,  -- soft window after expiry before hard delete
  -- --- Purge behaviour -------------------------------------------------------
  `auto_purge_enabled`          TINYINT(1) NOT NULL DEFAULT 1,
  `purge_requires_approval`     TINYINT(1) NOT NULL DEFAULT 1,
  `purge_notify_tenant`         TINYINT(1) NOT NULL DEFAULT 1,
  `expiry_warning_days_json`    JSON DEFAULT (JSON_ARRAY(30,15,7,1)),  -- T-minus alert ladder
  -- --- Extension (PAID SERVICE) ---------------------------------------------
  `allow_extension`             TINYINT(1) NOT NULL DEFAULT 1,
  `extension_min_days`          SMALLINT UNSIGNED NOT NULL DEFAULT 30,
  `extension_max_days`          SMALLINT UNSIGNED DEFAULT NULL,        -- NULL = no cap
  `max_extensions_allowed`      TINYINT UNSIGNED DEFAULT NULL,         -- NULL = unlimited
  `extension_is_chargeable`     TINYINT(1) NOT NULL DEFAULT 1,
  `extension_rate_per_gb_month` DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
  `extension_flat_fee_month`    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `extension_min_charge`        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `extension_tax_percent`       DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  `currency`                    CHAR(3) NOT NULL DEFAULT 'INR',
  `extension_lead_time_days`    SMALLINT UNSIGNED NOT NULL DEFAULT 3,  -- must request N days before expiry
  -- --- Integrity / compliance ------------------------------------------------
  `verify_after_backup`         TINYINT(1) NOT NULL DEFAULT 1,         -- checksum verify every run
  `test_restore_frequency_days` SMALLINT UNSIGNED DEFAULT NULL,        -- NULL = no drill
  `require_offsite_copy`        TINYINT(1) NOT NULL DEFAULT 0,
  `require_encryption`          TINYINT(1) NOT NULL DEFAULT 1,
  `compliance_tag`              VARCHAR(60) DEFAULT NULL,              -- 'DPDP-2023','ISO-27001'
  `is_system_defined`           TINYINT(1) NOT NULL DEFAULT 0,         -- 1 = seeded, not deletable
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                  INT UNSIGNED DEFAULT NULL,
  `updated_by`                  INT UNSIGNED DEFAULT NULL,
  `created_at`                  TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntRetPolicy_code` (`code`),
  KEY `idx_mntRetPolicy_isActive`   (`is_active`),
  CONSTRAINT `fk_mntRetPolicy_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRetPolicy_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntRetPolicy_minMax`   CHECK (`max_retention_days` IS NULL OR `max_retention_days` >= `min_retention_days`),
  CONSTRAINT `chk_mntRetPolicy_default`  CHECK (`default_retention_days` >= `min_retention_days`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. `default_retention_days` is what stamps `mnt_backup_run_items.retention_end_date`
--     at creation time. Changing the policy later does NOT retro-change existing
--     backups — retention is snapshotted per item (see table 8).
--  2. A backup can never be purged before `min_retention_days` even by a manual
--     purge, unless purge_reason = 'GDPR_ERASURE' with dual approval.
--  3. Extension charge = MAX(min_charge,
--        (flat_fee_month + rate_per_gb_month * GB) * months) * (1 + tax%).


-- -----------------------------------------------------------------------------
-- 3. mnt_maintenance_plans
--    Binds a tenant (or the whole platform) to a retention policy, a primary +
--    offsite destination, an RPO/RTO target and a backup scope.
--    tenant_id NULL = the platform-default plan used by any tenant with no
--    explicit plan of its own.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_maintenance_plans` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plan_code`                   VARCHAR(30)  NOT NULL,
  `name`                        VARCHAR(150) NOT NULL,
  `description`                 VARCHAR(500) DEFAULT NULL,
  `tenant_id`                   INT UNSIGNED DEFAULT NULL,         -- NULL = platform default plan
  `tenant_group_id`             INT UNSIGNED DEFAULT NULL,         -- optional: plan for a whole school group
  `retention_policy_id`         INT UNSIGNED NOT NULL,
  `primary_destination_id`      INT UNSIGNED NOT NULL,
  `offsite_destination_id`      INT UNSIGNED DEFAULT NULL,
  `archive_destination_id`      INT UNSIGNED DEFAULT NULL,         -- cold tier after `move_to_archive_after_days`
  `move_to_archive_after_days`  SMALLINT UNSIGNED DEFAULT NULL,
  -- --- Scope: what gets backed up -------------------------------------------
  `backup_database`             TINYINT(1) NOT NULL DEFAULT 1,
  `backup_images`               TINYINT(1) NOT NULL DEFAULT 1,
  `backup_videos`               TINYINT(1) NOT NULL DEFAULT 0,     -- heavy — opt-in
  `backup_documents`            TINYINT(1) NOT NULL DEFAULT 1,     -- PDF / DOCX / XLSX
  `backup_audio`                TINYINT(1) NOT NULL DEFAULT 0,
  `backup_config_files`         TINYINT(1) NOT NULL DEFAULT 1,
  `backup_app_logs`             TINYINT(1) NOT NULL DEFAULT 0,
  `include_paths_json`          JSON DEFAULT NULL,                 -- extra explicit paths
  `exclude_paths_json`          JSON DEFAULT NULL,                 -- e.g. ["cache/**","tmp/**"]
  `exclude_tables_json`         JSON DEFAULT NULL,                 -- e.g. ["sessions","jobs","*_cache"]
  `max_file_size_mb`            INT UNSIGNED DEFAULT NULL,         -- skip single files above this
  -- --- Processing options ----------------------------------------------------
  `default_backup_type`         ENUM('FULL','INCREMENTAL','DIFFERENTIAL','SNAPSHOT') NOT NULL DEFAULT 'FULL',
  `compression_type`            ENUM('NONE','GZIP','BZIP2','ZIP','ZSTD','XZ','7Z') NOT NULL DEFAULT 'GZIP',
  `compression_level`           TINYINT UNSIGNED NOT NULL DEFAULT 6,
  `encryption_enabled`          TINYINT(1) NOT NULL DEFAULT 1,
  `encryption_algo`             VARCHAR(40) NOT NULL DEFAULT 'AES-256-GCM',
  `encryption_key_ref`          VARCHAR(255) DEFAULT NULL,         -- vault path, never the key
  `checksum_algo`               ENUM('MD5','SHA1','SHA256','SHA512','CRC32','XXH64') NOT NULL DEFAULT 'SHA256',
  `split_volume_size_mb`        INT UNSIGNED DEFAULT NULL,         -- chunk large archives
  -- --- SLA -------------------------------------------------------------------
  `rpo_minutes`                 INT UNSIGNED DEFAULT NULL,         -- max acceptable data loss
  `rto_minutes`                 INT UNSIGNED DEFAULT NULL,         -- max acceptable restore time
  `max_run_duration_minutes`    INT UNSIGNED DEFAULT 240,          -- kill / alert beyond this
  `alert_on_failure`            TINYINT(1) NOT NULL DEFAULT 1,
  `alert_recipients_json`       JSON DEFAULT NULL,                 -- [{"channel":"EMAIL","to":"..."}]
  -- --- Commercial ------------------------------------------------------------
  `is_paid_plan`                TINYINT(1) NOT NULL DEFAULT 0,
  `included_storage_gb`         INT UNSIGNED NOT NULL DEFAULT 0,   -- free quota before overage billing
  `overage_rate_per_gb_month`   DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
  `currency`                    CHAR(3) NOT NULL DEFAULT 'INR',
  -- --- Lifecycle -------------------------------------------------------------
  `effective_from`              DATE NOT NULL,
  `effective_to`                DATE DEFAULT NULL,
  `is_current`                  TINYINT(1) NOT NULL DEFAULT 1,
  `current_plan_flag`           INT GENERATED ALWAYS AS (CASE WHEN (`is_current` = 1 AND `deleted_at` IS NULL) THEN IFNULL(`tenant_id`, 0) ELSE NULL END) STORED,
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                  INT UNSIGNED DEFAULT NULL,
  `updated_by`                  INT UNSIGNED DEFAULT NULL,
  `created_at`                  TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntPlan_planCode`        (`plan_code`),
  UNIQUE KEY `uq_mntPlan_currentPerTenant` (`current_plan_flag`),  -- one live plan per tenant (0 = platform default)
  KEY `idx_mntPlan_tenantId`              (`tenant_id`),
  KEY `idx_mntPlan_retentionPolicyId`     (`retention_policy_id`),
  KEY `idx_mntPlan_primaryDestId`         (`primary_destination_id`),
  KEY `idx_mntPlan_effective`             (`effective_from`,`effective_to`),
  CONSTRAINT `fk_mntPlan_tenantId`          FOREIGN KEY (`tenant_id`)              REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntPlan_tenantGroupId`     FOREIGN KEY (`tenant_group_id`)        REFERENCES `prm_tenant_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPlan_retentionPolicyId` FOREIGN KEY (`retention_policy_id`)    REFERENCES `mnt_retention_policies` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntPlan_primaryDestId`     FOREIGN KEY (`primary_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntPlan_offsiteDestId`     FOREIGN KEY (`offsite_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPlan_archiveDestId`     FOREIGN KEY (`archive_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPlan_createdBy`         FOREIGN KEY (`created_by`)             REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPlan_updatedBy`         FOREIGN KEY (`updated_by`)             REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntPlan_effectiveRange`   CHECK (`effective_to` IS NULL OR `effective_to` >= `effective_from`),
  CONSTRAINT `chk_mntPlan_scopeNotEmpty`    CHECK (`backup_database` + `backup_images` + `backup_videos` + `backup_documents` + `backup_audio` + `backup_config_files` + `backup_app_logs` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. Resolution order for a tenant's effective plan:
--     tenant-specific current plan → tenant_group plan → platform default (tenant_id IS NULL).
--  2. Superseding a plan = set is_current = 0 + effective_to on the old row and
--     INSERT a new row. Never UPDATE a live plan in place — history matters.
--  3. If `encryption_enabled` = 1 the policy's `require_encryption` must be
--     satisfiable; a run that cannot encrypt must FAIL, not silently downgrade.


-- =============================================================================
-- LAYER 2 — SCHEDULING
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4. mnt_backup_schedules   (enhanced from v1)
--    v1 held targets in a `databases_json` blob + `all_tenants` flag. v2 keeps
--    a declarative target_scope and moves explicit tenants to a junction table.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_backup_schedules` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_code`             VARCHAR(30)  NOT NULL,
  `label`                     VARCHAR(150) NOT NULL,               -- v1 field, kept
  `description`               VARCHAR(500) DEFAULT NULL,
  `maintenance_plan_id`       INT UNSIGNED DEFAULT NULL,           -- NULL = ad-hoc central schedule
  -- --- Targeting -------------------------------------------------------------
  `target_scope`              ENUM('ALL_TENANTS','PLAN_TENANTS','SELECTED_TENANTS','TENANT_GROUP','CENTRAL_DB_ONLY','GLOBAL_MASTER_ONLY') NOT NULL DEFAULT 'PLAN_TENANTS',
  `tenant_group_id`           INT UNSIGNED DEFAULT NULL,           -- used when target_scope = 'TENANT_GROUP'
  `include_central_db`        TINYINT(1) NOT NULL DEFAULT 0,       -- also dump prime_db
  `include_global_master_db`  TINYINT(1) NOT NULL DEFAULT 0,       -- also dump global_master
  `content_scope_json`        JSON DEFAULT NULL,                   -- override plan scope: ["DATABASE","IMAGES"]
  -- --- Timing ----------------------------------------------------------------
  `backup_type`               ENUM('FULL','INCREMENTAL','DIFFERENTIAL','SNAPSHOT','LOG') NOT NULL DEFAULT 'FULL',
  `frequency`                 ENUM('HOURLY','DAILY','WEEKLY','MONTHLY','QUARTERLY','YEARLY','CUSTOM_CRON') NOT NULL DEFAULT 'DAILY',
  `cron_expression`           VARCHAR(100) NOT NULL,               -- v1 field, kept
  `timezone`                  VARCHAR(64)  NOT NULL DEFAULT 'Asia/Kolkata',
  `preferred_start_time`      TIME DEFAULT NULL,                   -- human-readable mirror of cron
  `execution_window_minutes`  SMALLINT UNSIGNED DEFAULT NULL,      -- do not START after window closes
  `blackout_dates_json`       JSON DEFAULT NULL,                   -- ["2026-03-31"] exam day, board result day
  -- --- Execution behaviour ---------------------------------------------------
  `priority`                  TINYINT UNSIGNED NOT NULL DEFAULT 5, -- 1 = highest
  `max_parallel_tenants`      TINYINT UNSIGNED NOT NULL DEFAULT 3, -- throttle so DB server survives
  `retry_on_failure`          TINYINT(1) NOT NULL DEFAULT 1,
  `max_retry_attempts`        TINYINT UNSIGNED NOT NULL DEFAULT 2,
  `retry_delay_minutes`       SMALLINT UNSIGNED NOT NULL DEFAULT 15,
  `skip_if_previous_running`  TINYINT(1) NOT NULL DEFAULT 1,       -- prevents overlap pile-up
  `auto_verify`               TINYINT(1) NOT NULL DEFAULT 1,
  `retention_days_override`   SMALLINT UNSIGNED DEFAULT NULL,      -- NULL = inherit policy
  -- --- Runtime state ---------------------------------------------------------
  `last_run_at`               TIMESTAMP NULL DEFAULT NULL,         -- v1 field, kept
  `next_run_at`               TIMESTAMP NULL DEFAULT NULL,         -- v1 field, kept
  `last_run_id`               INT UNSIGNED DEFAULT NULL,           -- FK added after mnt_backup_runs exists
  `last_run_status`           ENUM('PENDING','QUEUED','RUNNING','COMPLETED','COMPLETED_WITH_WARNINGS','FAILED','CANCELLED','PAUSED','TIMED_OUT','SKIPPED') DEFAULT NULL,
  `consecutive_failure_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `auto_disable_after_failures` TINYINT UNSIGNED DEFAULT NULL,     -- self-park a broken schedule
  `total_run_count`           INT UNSIGNED NOT NULL DEFAULT 0,
  `is_paused`                 TINYINT(1) NOT NULL DEFAULT 0,
  `paused_reason`             VARCHAR(255) DEFAULT NULL,
  `paused_until`              TIMESTAMP NULL DEFAULT NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,       -- v1 field, kept
  `created_by`                INT UNSIGNED DEFAULT NULL,           -- v1 had NOT NULL + CASCADE (wrong) — fixed
  `updated_by`                INT UNSIGNED DEFAULT NULL,
  `created_at`                TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntSchedule_scheduleCode`  (`schedule_code`),
  KEY `idx_mntSchedule_planId`              (`maintenance_plan_id`),
  KEY `idx_mntSchedule_isActive_nextRunAt`  (`is_active`,`is_paused`,`next_run_at`),
  KEY `idx_mntSchedule_targetScope`         (`target_scope`),
  KEY `idx_mntSchedule_createdBy`           (`created_by`),
  CONSTRAINT `fk_mntSchedule_planId`        FOREIGN KEY (`maintenance_plan_id`) REFERENCES `mnt_maintenance_plans` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntSchedule_tenantGroupId` FOREIGN KEY (`tenant_group_id`)     REFERENCES `prm_tenant_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntSchedule_createdBy`     FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntSchedule_updatedBy`     FOREIGN KEY (`updated_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntSchedule_maxParallel`  CHECK (`max_parallel_tenants` >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. `next_run_at` is recomputed by the scheduler after every dispatch from
--     `cron_expression` evaluated in `timezone` — not in server time.
--  2. If target_scope = 'SELECTED_TENANTS', at least one row must exist in
--     `mnt_schedule_tenant_jnt`; enforce in the FormRequest.
--  3. When `consecutive_failure_count` reaches `auto_disable_after_failures`,
--     set is_active = 0 and raise a CRITICAL alert.
--  4. An INCREMENTAL/DIFFERENTIAL schedule must have a FULL schedule on the same
--     plan; otherwise there is no base to chain to.


-- -----------------------------------------------------------------------------
-- 5. mnt_schedule_tenant_jnt
--    Explicit tenant targeting for target_scope = 'SELECTED_TENANTS', and
--    per-tenant exclusion (is_excluded = 1) for the ALL_TENANTS case.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_schedule_tenant_jnt` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `backup_schedule_id`      INT UNSIGNED NOT NULL,
  `tenant_id`               INT UNSIGNED NOT NULL,
  `is_excluded`             TINYINT(1) NOT NULL DEFAULT 0,         -- 1 = opt this tenant OUT
  `exclusion_reason`        VARCHAR(255) DEFAULT NULL,
  `content_scope_json`      JSON DEFAULT NULL,                     -- per-tenant scope override
  `retention_days_override` SMALLINT UNSIGNED DEFAULT NULL,
  `sequence_no`             SMALLINT UNSIGNED DEFAULT NULL,        -- deterministic processing order
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`              INT UNSIGNED DEFAULT NULL,
  `created_at`              TIMESTAMP NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntSchTenant_scheduleId_tenantId` (`backup_schedule_id`,`tenant_id`),
  KEY `idx_mntSchTenant_tenantId`                  (`tenant_id`),
  CONSTRAINT `fk_mntSchTenant_scheduleId` FOREIGN KEY (`backup_schedule_id`) REFERENCES `mnt_backup_schedules` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntSchTenant_tenantId`   FOREIGN KEY (`tenant_id`)          REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntSchTenant_createdBy`  FOREIGN KEY (`created_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- 6. mnt_maintenance_windows
--    Announced downtime / degraded-service windows. Backups, restores and
--    purges should be scheduled INSIDE a window; tenants are notified ahead.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_maintenance_windows` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `window_code`             VARCHAR(30)  NOT NULL,
  `title`                   VARCHAR(200) NOT NULL,
  `description`             TEXT DEFAULT NULL,
  `window_type`             ENUM('SCHEDULED_BACKUP','RESTORE','DB_UPGRADE','APP_DEPLOYMENT','STORAGE_MIGRATION','PURGE','EMERGENCY','OTHER') NOT NULL DEFAULT 'SCHEDULED_BACKUP',
  `scope`                   ENUM('PLATFORM','TENANT_GROUP','SELECTED_TENANTS','SINGLE_TENANT') NOT NULL DEFAULT 'PLATFORM',
  `tenant_id`               INT UNSIGNED DEFAULT NULL,
  `tenant_group_id`         INT UNSIGNED DEFAULT NULL,
  `affected_tenants_json`   JSON DEFAULT NULL,                     -- [tenant_id,...] for SELECTED_TENANTS
  `starts_at`               DATETIME NOT NULL,
  `ends_at`                 DATETIME NOT NULL,
  `timezone`                VARCHAR(64) NOT NULL DEFAULT 'Asia/Kolkata',
  `is_recurring`            TINYINT(1) NOT NULL DEFAULT 0,
  `recurrence_cron`         VARCHAR(100) DEFAULT NULL,
  `expected_downtime_minutes` SMALLINT UNSIGNED DEFAULT NULL,
  `is_read_only_mode`       TINYINT(1) NOT NULL DEFAULT 0,         -- app stays up, writes blocked
  `is_full_outage`          TINYINT(1) NOT NULL DEFAULT 0,
  `notify_days_before`      TINYINT UNSIGNED NOT NULL DEFAULT 3,
  `notification_sent_at`    TIMESTAMP NULL DEFAULT NULL,
  `reminder_sent_at`        TIMESTAMP NULL DEFAULT NULL,
  `banner_message`          VARCHAR(500) DEFAULT NULL,             -- shown in tenant UI
  `status`                  ENUM('PLANNED','ANNOUNCED','IN_PROGRESS','COMPLETED','CANCELLED','EXTENDED') NOT NULL DEFAULT 'PLANNED',
  `actual_started_at`       TIMESTAMP NULL DEFAULT NULL,
  `actual_ended_at`         TIMESTAMP NULL DEFAULT NULL,
  `outcome_notes`           TEXT DEFAULT NULL,
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`              INT UNSIGNED DEFAULT NULL,
  `updated_by`              INT UNSIGNED DEFAULT NULL,
  `created_at`              TIMESTAMP NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`              TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntWindow_windowCode`   (`window_code`),
  KEY `idx_mntWindow_startsAt_endsAt`    (`starts_at`,`ends_at`),
  KEY `idx_mntWindow_status`             (`status`),
  KEY `idx_mntWindow_tenantId`           (`tenant_id`),
  CONSTRAINT `fk_mntWindow_tenantId`      FOREIGN KEY (`tenant_id`)       REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntWindow_tenantGroupId` FOREIGN KEY (`tenant_group_id`) REFERENCES `prm_tenant_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntWindow_createdBy`     FOREIGN KEY (`created_by`)      REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntWindow_updatedBy`     FOREIGN KEY (`updated_by`)      REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntWindow_range`        CHECK (`ends_at` > `starts_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. A destructive restore (target_type = 'SAME_TENANT_OVERWRITE') MUST be
--     linked to a maintenance window whose status is 'IN_PROGRESS'.
--  2. Tenants are notified at `notify_days_before` and again 1 hour prior.


-- =============================================================================
-- LAYER 3 — EXECUTION CATALOGUE  (runs -> items -> files -> verifications)
-- =============================================================================
-- Three-level design, deliberately:
--   RUN   = one execution of a schedule (or one manual trigger)
--   ITEM  = one logical backup set  (one tenant  x  one content type)
--   FILE  = one physical file on disk/cloud (a run item may be split into
--           multiple volumes, and may exist as primary + offsite copies)
-- v1 collapsed all three into a single row, which is why it could not answer
-- per-tenant or per-file questions.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 7. mnt_backup_runs   (enhanced from v1)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_backup_runs` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_uuid`                  CHAR(36) NOT NULL,                   -- stable external id / idempotency key
  `run_no`                    VARCHAR(40) NOT NULL,                -- human ref e.g. 'BKP-2026-07-27-0007'
  `name`                      VARCHAR(200) NOT NULL,               -- v1 field, kept
  `backup_schedule_id`        INT UNSIGNED DEFAULT NULL,           -- NULL = manual / ad-hoc run
  `maintenance_plan_id`       INT UNSIGNED DEFAULT NULL,
  `maintenance_window_id`     INT UNSIGNED DEFAULT NULL,
  `parent_run_id`             INT UNSIGNED DEFAULT NULL,           -- base FULL run for INCR/DIFF chains
  `chain_id`                  CHAR(36) DEFAULT NULL,               -- groups a FULL + its INCR children
  -- --- What was attempted ----------------------------------------------------
  `backup_type`               ENUM('FULL','INCREMENTAL','DIFFERENTIAL','SNAPSHOT','LOG') NOT NULL DEFAULT 'FULL',
  `trigger_type`              ENUM('SCHEDULED','MANUAL','API','PRE_RESTORE','PRE_UPGRADE','PRE_OFFBOARDING','TENANT_REQUEST','RETRY','DR_DRILL') NOT NULL DEFAULT 'SCHEDULED',
  `target_scope`              ENUM('ALL_TENANTS','PLAN_TENANTS','SELECTED_TENANTS','TENANT_GROUP','CENTRAL_DB_ONLY','GLOBAL_MASTER_ONLY','SINGLE_TENANT') NOT NULL DEFAULT 'PLAN_TENANTS',
  `content_scope_json`        JSON DEFAULT NULL,                   -- ["DATABASE","IMAGES","VIDEOS","DOCUMENTS"]
  `target_tenants_json`       JSON DEFAULT NULL,                   -- snapshot of tenant ids resolved at dispatch
  `include_central_db`        TINYINT(1) NOT NULL DEFAULT 0,
  `include_files`             TINYINT(1) NOT NULL DEFAULT 0,       -- v1 field, kept (media/files included)
  -- --- Where it went ---------------------------------------------------------
  `primary_destination_id`    INT UNSIGNED DEFAULT NULL,
  `offsite_destination_id`    INT UNSIGNED DEFAULT NULL,
  `root_path`                 VARCHAR(500) DEFAULT NULL,           -- run-level folder e.g. '/backups/2026/07/27/BKP-...'
  -- --- Lifecycle -------------------------------------------------------------
  `status`                    ENUM('PENDING','QUEUED','RUNNING','COMPLETED','COMPLETED_WITH_WARNINGS','PARTIALLY_FAILED','FAILED','CANCELLED','PAUSED','TIMED_OUT','SKIPPED') NOT NULL DEFAULT 'PENDING',
  `progress_percent`          TINYINT UNSIGNED NOT NULL DEFAULT 0, -- v1 `progress`, renamed for clarity
  `current_stage`             VARCHAR(60) DEFAULT NULL,            -- 'DUMPING','COMPRESSING','ENCRYPTING','UPLOADING','VERIFYING','REPLICATING'
  `queued_at`                 TIMESTAMP NULL DEFAULT NULL,
  `started_at`                TIMESTAMP NULL DEFAULT NULL,         -- v1 field, kept
  `completed_at`              TIMESTAMP NULL DEFAULT NULL,         -- v1 field, kept
  `duration_seconds`          INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, `started_at`, `completed_at`)) STORED,
  `attempt_no`                TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `max_attempts`              TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `retry_of_run_id`           INT UNSIGNED DEFAULT NULL,
  -- --- Roll-up counters (maintained from mnt_backup_run_items) ---------------
  `total_items`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `success_items`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `warning_items`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `failed_items`              SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `skipped_items`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `total_files_count`         INT UNSIGNED NOT NULL DEFAULT 0,
  `total_original_bytes`      BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `total_stored_bytes`        BIGINT UNSIGNED NOT NULL DEFAULT 0,  -- after compression
  `file_size_bytes`           BIGINT UNSIGNED DEFAULT NULL,        -- v1 field, kept = total_stored_bytes mirror
  -- --- Execution environment (for forensics) ---------------------------------
  `queue_job_id`              VARCHAR(100) DEFAULT NULL,
  `worker_host`               VARCHAR(100) DEFAULT NULL,
  `worker_pid`                INT UNSIGNED DEFAULT NULL,
  `app_version`               VARCHAR(30) DEFAULT NULL,
  `db_server_version`         VARCHAR(50) DEFAULT NULL,
  `peak_memory_mb`            INT UNSIGNED DEFAULT NULL,
  -- --- Outcome ---------------------------------------------------------------
  `error_code`                VARCHAR(50) DEFAULT NULL,
  `error_message`             TEXT DEFAULT NULL,                   -- v1 field, kept
  `error_trace`               MEDIUMTEXT DEFAULT NULL,
  `warning_count`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `summary_json`              JSON DEFAULT NULL,                   -- per-stage timings, throughput
  `is_verified`               TINYINT(1) NOT NULL DEFAULT 0,
  `verified_at`               TIMESTAMP NULL DEFAULT NULL,
  `is_offsite_replicated`     TINYINT(1) NOT NULL DEFAULT 0,
  `offsite_replicated_at`     TIMESTAMP NULL DEFAULT NULL,
  -- --- Who / when ------------------------------------------------------------
  `triggered_by`              INT UNSIGNED DEFAULT NULL,           -- v1 field, kept — FK to sys_users
  `triggered_by_name`         VARCHAR(100) DEFAULT NULL,           -- denormalised: survives user deletion
  `triggered_by_type`         ENUM('USER','SYSTEM','CRON','API','TENANT_USER') NOT NULL DEFAULT 'CRON',
  `requested_by_tenant_id`    INT UNSIGNED DEFAULT NULL,           -- set when a tenant asked for it
  `requested_at`              TIMESTAMP NULL DEFAULT NULL,
  `cancelled_by`              INT UNSIGNED DEFAULT NULL,
  `cancelled_at`              TIMESTAMP NULL DEFAULT NULL,
  `cancellation_reason`       VARCHAR(255) DEFAULT NULL,
  `remarks`                   VARCHAR(500) DEFAULT NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                TIMESTAMP NULL DEFAULT NULL,         -- v1 field, kept
  `updated_at`                TIMESTAMP NULL DEFAULT NULL,         -- v1 field, kept
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntBackupRuns_runUuid`         (`run_uuid`),
  UNIQUE KEY `uq_mntBackupRuns_runNo`           (`run_no`),
  KEY `idx_mntBackupRuns_scheduleId_startedAt`  (`backup_schedule_id`,`started_at`),
  KEY `idx_mntBackupRuns_status_createdAt`      (`status`,`created_at`),
  KEY `idx_mntBackupRuns_triggeredBy`           (`triggered_by`),
  KEY `idx_mntBackupRuns_backupType_status`     (`backup_type`,`status`),
  KEY `idx_mntBackupRuns_parentRunId`           (`parent_run_id`),
  KEY `idx_mntBackupRuns_chainId`               (`chain_id`),
  KEY `idx_mntBackupRuns_planId`                (`maintenance_plan_id`),
  KEY `idx_mntBackupRuns_startedAt`             (`started_at`),
  CONSTRAINT `fk_mntBackupRuns_scheduleId`    FOREIGN KEY (`backup_schedule_id`)     REFERENCES `mnt_backup_schedules` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_planId`        FOREIGN KEY (`maintenance_plan_id`)    REFERENCES `mnt_maintenance_plans` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_windowId`      FOREIGN KEY (`maintenance_window_id`)  REFERENCES `mnt_maintenance_windows` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_parentRunId`   FOREIGN KEY (`parent_run_id`)          REFERENCES `mnt_backup_runs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntBackupRuns_retryOfRunId`  FOREIGN KEY (`retry_of_run_id`)        REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_primaryDestId` FOREIGN KEY (`primary_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntBackupRuns_offsiteDestId` FOREIGN KEY (`offsite_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_reqTenantId`   FOREIGN KEY (`requested_by_tenant_id`) REFERENCES `prm_tenant` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_triggeredBy`   FOREIGN KEY (`triggered_by`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntBackupRuns_cancelledBy`   FOREIGN KEY (`cancelled_by`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntBackupRuns_progress`     CHECK (`progress_percent` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. STATUS MACHINE:
--     PENDING -> QUEUED -> RUNNING -> {COMPLETED | COMPLETED_WITH_WARNINGS |
--                                      PARTIALLY_FAILED | FAILED | TIMED_OUT}
--     RUNNING -> PAUSED -> RUNNING ; {PENDING|QUEUED|RUNNING|PAUSED} -> CANCELLED
--     A run whose items are mixed success/failure = 'PARTIALLY_FAILED'.
--  2. `parent_run_id` uses ON DELETE RESTRICT on purpose: a FULL backup that
--     still has INCREMENTAL children can never be deleted (chain integrity).
--  3. `triggered_by_name` is denormalised deliberately — audit evidence must
--     survive `sys_users` row deletion (FK is SET NULL).
--  4. `duration_seconds` is a STORED generated column; it is NULL while running.
--  5. A run is 'COMPLETED' only after every non-skipped item reaches SUCCESS
--     AND (if plan.require_offsite_copy = 1) offsite replication succeeded.


-- -----------------------------------------------------------------------------
-- 8. mnt_backup_run_items
--    THE BACKUP CATALOGUE. One row per (run x tenant x content type).
--    This is the table the "Backup History" screen reads, and the table that
--    owns RETENTION — `retention_end_date` is the "Backup End Date" the tenant
--    can pay to extend.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_backup_run_items` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `item_uuid`                   CHAR(36) NOT NULL,
  `backup_run_id`               INT UNSIGNED NOT NULL,
  `sequence_no`                 SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- --- Tenant identity (denormalised on purpose — see condition 2) -----------
  `tenant_id`                   INT UNSIGNED DEFAULT NULL,         -- NULL = central/global DB item
  `tenant_code`                 VARCHAR(20)  DEFAULT NULL,         -- snapshot of prm_tenant.code
  `tenant_name`                 VARCHAR(150) DEFAULT NULL,         -- snapshot of prm_tenant.name
  `tenant_group_code`           VARCHAR(20)  DEFAULT NULL,
  `database_name`               VARCHAR(100) DEFAULT NULL,         -- snapshot of prm_tenant_domains.db_name
  `database_host`               VARCHAR(200) DEFAULT NULL,
  `domain_name`                 VARCHAR(255) DEFAULT NULL,
  -- --- What this item is -----------------------------------------------------
  `content_type`                ENUM('DATABASE','IMAGES','VIDEOS','DOCUMENTS','AUDIO','MEDIA_ALL','CONFIG','APP_LOGS','FULL_FILESYSTEM','OTHER') NOT NULL DEFAULT 'DATABASE',
  `backup_type`                 ENUM('FULL','INCREMENTAL','DIFFERENTIAL','SNAPSHOT','LOG') NOT NULL DEFAULT 'FULL',
  `parent_item_id`              INT UNSIGNED DEFAULT NULL,         -- base item for INCR/DIFF
  `source_path`                 VARCHAR(500) DEFAULT NULL,         -- what was read (media root, etc.)
  `table_count`                 SMALLINT UNSIGNED DEFAULT NULL,    -- for DATABASE items
  `row_count_estimate`          BIGINT UNSIGNED DEFAULT NULL,
  `source_file_count`           INT UNSIGNED DEFAULT NULL,         -- for FILE items
  -- --- Where it landed (roll-up of mnt_backup_files) --------------------------
  `storage_destination_id`      INT UNSIGNED DEFAULT NULL,
  `storage_path`                VARCHAR(500) DEFAULT NULL,         -- folder holding this item's files
  `primary_file_name`           VARCHAR(255) DEFAULT NULL,         -- the main/first archive file
  `file_extension`              VARCHAR(20)  DEFAULT NULL,         -- 'sql.gz','zip','tar.zst'
  `mime_type`                   VARCHAR(120) DEFAULT NULL,
  `file_count`                  SMALLINT UNSIGNED NOT NULL DEFAULT 0,  -- volumes/parts
  `is_multipart`                TINYINT(1) NOT NULL DEFAULT 0,
  `original_size_bytes`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `stored_size_bytes`           BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `compression_ratio`           DECIMAL(6,3) GENERATED ALWAYS AS (CASE WHEN `original_size_bytes` > 0 THEN (`stored_size_bytes` / `original_size_bytes`) ELSE NULL END) STORED,
  `compression_type`            ENUM('NONE','GZIP','BZIP2','ZIP','ZSTD','XZ','7Z') NOT NULL DEFAULT 'GZIP',
  -- --- Integrity / security --------------------------------------------------
  `checksum_algo`               ENUM('MD5','SHA1','SHA256','SHA512','CRC32','XXH64') NOT NULL DEFAULT 'SHA256',
  `checksum_value`              VARCHAR(128) DEFAULT NULL,         -- over the manifest of all files
  `is_encrypted`                TINYINT(1) NOT NULL DEFAULT 0,
  `encryption_algo`             VARCHAR(40) DEFAULT NULL,
  `encryption_key_ref`          VARCHAR(255) DEFAULT NULL,         -- vault path — NEVER the key
  `manifest_json`               JSON DEFAULT NULL,                 -- file list + per-file hash
  -- --- Execution -------------------------------------------------------------
  `status`                      ENUM('PENDING','RUNNING','SUCCESS','SUCCESS_WITH_WARNINGS','FAILED','SKIPPED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  `started_at`                  TIMESTAMP NULL DEFAULT NULL,
  `completed_at`                TIMESTAMP NULL DEFAULT NULL,
  `duration_seconds`            INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, `started_at`, `completed_at`)) STORED,
  `throughput_mbps`             DECIMAL(10,2) DEFAULT NULL,
  `attempt_no`                  TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `error_code`                  VARCHAR(50) DEFAULT NULL,
  `error_message`               TEXT DEFAULT NULL,
  `warning_message`             TEXT DEFAULT NULL,
  `skip_reason`                 VARCHAR(255) DEFAULT NULL,
  -- --- Verification ----------------------------------------------------------
  `verification_status`         ENUM('NOT_VERIFIED','PENDING','PASSED','FAILED','EXPIRED') NOT NULL DEFAULT 'NOT_VERIFIED',
  `last_verified_at`            TIMESTAMP NULL DEFAULT NULL,
  `last_test_restore_at`        TIMESTAMP NULL DEFAULT NULL,
  `is_restorable`               TINYINT(1) NOT NULL DEFAULT 1,     -- 0 once verification fails
  -- --- Offsite / tiering -----------------------------------------------------
  `has_offsite_copy`            TINYINT(1) NOT NULL DEFAULT 0,
  `offsite_destination_id`      INT UNSIGNED DEFAULT NULL,
  `offsite_copied_at`           TIMESTAMP NULL DEFAULT NULL,
  `storage_class`               ENUM('HOT','WARM','COLD','ARCHIVE','DEEP_ARCHIVE') NOT NULL DEFAULT 'HOT',
  `tier_transitioned_at`        TIMESTAMP NULL DEFAULT NULL,
  `restore_lead_time_hours`     SMALLINT UNSIGNED DEFAULT NULL,    -- thaw time for ARCHIVE/DEEP_ARCHIVE
  -- ===========================================================================
  -- RETENTION — the heart of the requirement
  -- ===========================================================================
  `retention_policy_id`         INT UNSIGNED DEFAULT NULL,
  `retention_class`             ENUM('DAILY','WEEKLY','MONTHLY','YEARLY','MANUAL','PRE_RESTORE','LEGAL_HOLD') NOT NULL DEFAULT 'DAILY',
  `retention_start_date`        DATE DEFAULT NULL,                 -- normally the backup date
  `retention_days`              SMALLINT UNSIGNED DEFAULT NULL,    -- effective days at creation
  `original_retention_end_date` DATE DEFAULT NULL,                 -- immutable: what it was before any extension
  `retention_end_date`          DATE DEFAULT NULL,                 -- CURRENT "Backup End Date" — extensions move this
  `grace_end_date`              DATE DEFAULT NULL,                 -- retention_end_date + policy grace days
  `extension_count`             TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `total_extended_days`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `last_extension_request_id`   INT UNSIGNED DEFAULT NULL,         -- FK added after table 13 exists
  `is_legal_hold`               TINYINT(1) NOT NULL DEFAULT 0,     -- blocks ALL purge
  `legal_hold_reason`           VARCHAR(255) DEFAULT NULL,
  `legal_hold_by`               INT UNSIGNED DEFAULT NULL,
  `legal_hold_at`               TIMESTAMP NULL DEFAULT NULL,
  `is_locked`                   TINYINT(1) NOT NULL DEFAULT 0,     -- WORM / object-lock applied at destination
  -- --- Purge lifecycle -------------------------------------------------------
  `purge_status`                ENUM('ACTIVE','EXPIRING_SOON','EXPIRED','PENDING_APPROVAL','APPROVED_FOR_PURGE','PURGED','PURGE_FAILED','ON_HOLD','EXTENDED') NOT NULL DEFAULT 'ACTIVE',
  `expiry_warning_sent_json`    JSON DEFAULT NULL,                 -- {"30":"2026-06-27","7":"2026-07-20"} dedupe
  `purge_approved_by`           INT UNSIGNED DEFAULT NULL,
  `purge_approved_at`           TIMESTAMP NULL DEFAULT NULL,
  `purged_at`                   TIMESTAMP NULL DEFAULT NULL,
  `purge_log_id`                INT UNSIGNED DEFAULT NULL,         -- FK added after table 17 exists
  -- --- Access / usage stats --------------------------------------------------
  `download_count`              SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `restore_count`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `last_accessed_at`            TIMESTAMP NULL DEFAULT NULL,
  `last_accessed_by`            INT UNSIGNED DEFAULT NULL,
  `is_billable`                 TINYINT(1) NOT NULL DEFAULT 0,     -- counts toward tenant storage billing
  `remarks`                     VARCHAR(500) DEFAULT NULL,
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                  TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntRunItems_itemUuid`                (`item_uuid`),
  UNIQUE KEY `uq_mntRunItems_runId_tenantId_content`  (`backup_run_id`,`tenant_id`,`content_type`),
  KEY `idx_mntRunItems_tenantId_status`               (`tenant_id`,`status`),
  KEY `idx_mntRunItems_tenantCode`                    (`tenant_code`),
  KEY `idx_mntRunItems_retentionEndDate`              (`retention_end_date`),
  KEY `idx_mntRunItems_purgeStatus_retentionEnd`      (`purge_status`,`retention_end_date`),
  KEY `idx_mntRunItems_tenantId_contentType_created`  (`tenant_id`,`content_type`,`created_at`),
  KEY `idx_mntRunItems_status`                        (`status`),
  KEY `idx_mntRunItems_legalHold`                     (`is_legal_hold`),
  KEY `idx_mntRunItems_storageDestId`                 (`storage_destination_id`),
  KEY `idx_mntRunItems_parentItemId`                  (`parent_item_id`),
  KEY `idx_mntRunItems_verificationStatus`            (`verification_status`),
  CONSTRAINT `fk_mntRunItems_backupRunId`     FOREIGN KEY (`backup_run_id`)          REFERENCES `mnt_backup_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntRunItems_parentItemId`    FOREIGN KEY (`parent_item_id`)         REFERENCES `mnt_backup_run_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRunItems_tenantId`        FOREIGN KEY (`tenant_id`)              REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRunItems_storageDestId`   FOREIGN KEY (`storage_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRunItems_offsiteDestId`   FOREIGN KEY (`offsite_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRunItems_retPolicyId`     FOREIGN KEY (`retention_policy_id`)    REFERENCES `mnt_retention_policies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRunItems_legalHoldBy`     FOREIGN KEY (`legal_hold_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRunItems_purgeApprovedBy` FOREIGN KEY (`purge_approved_by`)      REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRunItems_lastAccessedBy`  FOREIGN KEY (`last_accessed_by`)       REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntRunItems_retentionRange` CHECK (`retention_end_date` IS NULL OR `retention_start_date` IS NULL OR `retention_end_date` >= `retention_start_date`),
  CONSTRAINT `chk_mntRunItems_extensionOnly`  CHECK (`original_retention_end_date` IS NULL OR `retention_end_date` IS NULL OR `retention_end_date` >= `original_retention_end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. `fk_mntRunItems_tenantId` is RESTRICT, not CASCADE: deleting a tenant must
--     NOT silently destroy its backup catalogue. Off-boarding is an explicit
--     purge workflow (see mnt_purge_logs, reason = 'TENANT_OFFBOARDED').
--  2. tenant_code / tenant_name / database_name are SNAPSHOTS taken at backup
--     time. A school that later renames itself must still be findable in history
--     by the name it had when the backup was taken. This directly satisfies the
--     requirement "Tenant detail (Tenant Name, Code, DB Name etc.)".
--  3. RETENTION MATH at insert time:
--       retention_start_date        = DATE(completed_at)
--       retention_days              = COALESCE(schedule.retention_days_override,
--                                              policy.default_retention_days)
--       original_retention_end_date = retention_start_date + retention_days
--       retention_end_date          = original_retention_end_date
--       grace_end_date              = retention_end_date + policy.grace_period_days
--     `original_retention_end_date` is written ONCE and never updated — it is the
--     evidence of what the tenant was originally entitled to.
--  4. EXTENSION (paid) only ever moves `retention_end_date` FORWARD; the CHECK
--     constraint `chk_mntRunItems_extensionOnly` enforces this at the DB level.
--  5. PURGE ELIGIBILITY (all must hold):
--       purge_status IN ('EXPIRED','APPROVED_FOR_PURGE')
--       AND CURDATE() > grace_end_date
--       AND is_legal_hold = 0 AND is_locked = 0
--       AND NOT EXISTS (child item with parent_item_id = this.id)
--       AND NOT EXISTS (active archive-access session on this item)
--       AND (retention_start_date + policy.min_retention_days) <= CURDATE()
--  6. `is_billable` = 1 for items retained beyond the plan's included quota or
--     retained under a paid extension; feeds mnt_storage_usage_snapshots.


-- -----------------------------------------------------------------------------
-- 9. mnt_backup_files
--    One row per PHYSICAL file. Covers (a) multi-volume archives of one item,
--    and (b) the same archive replicated to primary + offsite + archive tiers.
--    BIGINT PK: high row count (tenants x content types x parts x copies x runs).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_backup_files` (
  `id`                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `file_uuid`               CHAR(36) NOT NULL,
  `backup_run_item_id`      INT UNSIGNED NOT NULL,
  `backup_run_id`           INT UNSIGNED NOT NULL,                 -- denormalised for fast run-level queries
  `tenant_id`               INT UNSIGNED DEFAULT NULL,             -- denormalised for per-tenant storage sums
  -- --- Copy identity ---------------------------------------------------------
  `copy_type`               ENUM('PRIMARY','OFFSITE_REPLICA','ARCHIVE_TIER','TAPE','LOCAL_CACHE','EXPORT_COPY') NOT NULL DEFAULT 'PRIMARY',
  `source_file_id`          BIGINT UNSIGNED DEFAULT NULL,          -- the PRIMARY this copy was made from
  `part_no`                 SMALLINT UNSIGNED NOT NULL DEFAULT 1,  -- volume number for split archives
  `total_parts`             SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  -- --- Location & identity (explicit requirement) ----------------------------
  `storage_destination_id`  INT UNSIGNED NOT NULL,
  `disk_name`               VARCHAR(60)  DEFAULT NULL,             -- Laravel disk key
  `directory_path`          VARCHAR(500) NOT NULL,                 -- folder only
  `file_name`               VARCHAR(255) NOT NULL,                 -- file only
  `full_path`               VARCHAR(760) DEFAULT NULL,             -- convenience: directory_path + '/' + file_name
  `relative_path`           VARCHAR(500) DEFAULT NULL,             -- path relative to destination base_path
  `external_object_key`     VARCHAR(500) DEFAULT NULL,             -- S3 key / Drive fileId
  `external_version_id`     VARCHAR(120) DEFAULT NULL,             -- S3 object version
  `public_url`              VARCHAR(760) DEFAULT NULL,             -- normally NULL — backups must not be public
  -- --- File info (explicit requirement) --------------------------------------
  `file_type`               ENUM('DB_DUMP','ARCHIVE','IMAGE','VIDEO','PDF','DOCUMENT','AUDIO','MANIFEST','CHECKSUM','LOG','CONFIG','OTHER') NOT NULL DEFAULT 'ARCHIVE',
  `file_extension`          VARCHAR(20)  DEFAULT NULL,
  `mime_type`               VARCHAR(120) DEFAULT NULL,
  `size_bytes`              BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `original_size_bytes`     BIGINT UNSIGNED DEFAULT NULL,          -- pre-compression
  `is_compressed`           TINYINT(1) NOT NULL DEFAULT 1,
  `compression_type`        ENUM('NONE','GZIP','BZIP2','ZIP','ZSTD','XZ','7Z') NOT NULL DEFAULT 'GZIP',
  `is_encrypted`            TINYINT(1) NOT NULL DEFAULT 0,
  `encryption_algo`         VARCHAR(40) DEFAULT NULL,
  `encryption_key_ref`      VARCHAR(255) DEFAULT NULL,             -- vault path — NEVER the key
  `checksum_algo`           ENUM('MD5','SHA1','SHA256','SHA512','CRC32','XXH64') NOT NULL DEFAULT 'SHA256',
  `checksum_value`          VARCHAR(128) DEFAULT NULL,
  `etag`                    VARCHAR(120) DEFAULT NULL,             -- remote-side integrity token
  -- --- Upload / state --------------------------------------------------------
  `upload_status`           ENUM('PENDING','UPLOADING','UPLOADED','VERIFIED','FAILED','DELETED','MISSING','CORRUPT') NOT NULL DEFAULT 'PENDING',
  `uploaded_at`             TIMESTAMP NULL DEFAULT NULL,
  `upload_duration_seconds` INT UNSIGNED DEFAULT NULL,
  `storage_class`           ENUM('HOT','WARM','COLD','ARCHIVE','DEEP_ARCHIVE') NOT NULL DEFAULT 'HOT',
  `is_immutable_locked`     TINYINT(1) NOT NULL DEFAULT 0,
  `object_lock_until`       DATE DEFAULT NULL,
  `last_integrity_check_at` TIMESTAMP NULL DEFAULT NULL,
  `integrity_check_result`  ENUM('NOT_CHECKED','OK','CHECKSUM_MISMATCH','NOT_FOUND','UNREADABLE') NOT NULL DEFAULT 'NOT_CHECKED',
  `error_message`           TEXT DEFAULT NULL,
  -- --- Deletion --------------------------------------------------------------
  `is_deleted`              TINYINT(1) NOT NULL DEFAULT 0,
  `deleted_from_storage_at` TIMESTAMP NULL DEFAULT NULL,
  `purge_log_id`            INT UNSIGNED DEFAULT NULL,             -- FK added after table 17 exists
  `download_count`          SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`              TIMESTAMP NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`              TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntBackupFiles_fileUuid`            (`file_uuid`),
  UNIQUE KEY `uq_mntBackupFiles_item_copy_part`      (`backup_run_item_id`,`copy_type`,`part_no`),
  KEY `idx_mntBackupFiles_runId`                     (`backup_run_id`),
  KEY `idx_mntBackupFiles_tenantId_isDeleted`        (`tenant_id`,`is_deleted`),
  KEY `idx_mntBackupFiles_storageDestId_uploadSt`    (`storage_destination_id`,`upload_status`),
  KEY `idx_mntBackupFiles_fileName`                  (`file_name`),
  KEY `idx_mntBackupFiles_checksumValue`             (`checksum_value`),
  KEY `idx_mntBackupFiles_sourceFileId`              (`source_file_id`),
  KEY `idx_mntBackupFiles_uploadStatus`              (`upload_status`),
  CONSTRAINT `fk_mntBackupFiles_runItemId`   FOREIGN KEY (`backup_run_item_id`)     REFERENCES `mnt_backup_run_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntBackupFiles_runId`       FOREIGN KEY (`backup_run_id`)          REFERENCES `mnt_backup_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntBackupFiles_tenantId`    FOREIGN KEY (`tenant_id`)              REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntBackupFiles_storageDest` FOREIGN KEY (`storage_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntBackupFiles_sourceFile`  FOREIGN KEY (`source_file_id`)         REFERENCES `mnt_backup_files` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. `full_path` is maintained by the application (MySQL cannot index a 760-char
--     generated column under utf8mb4 without a prefix). Keep it in sync in the
--     model's saving() hook.
--  2. `public_url` must stay NULL for real backups. A non-null value is a
--     security finding — see AI_Brain/rules/security-rules.md.
--  3. A file row is NEVER hard-deleted when the physical object is removed:
--     set is_deleted = 1, deleted_from_storage_at, purge_log_id. The catalogue
--     row is the compliance evidence that the data was destroyed.
--  4. `integrity_check_result` = 'CHECKSUM_MISMATCH' must flip the parent item's
--     is_restorable to 0 and raise a CRITICAL alert.


-- -----------------------------------------------------------------------------
-- 10. mnt_backup_verifications
--     Evidence that a backup is actually usable. Three escalating levels:
--     checksum -> archive open/list -> full test restore into a sandbox DB.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_backup_verifications` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `verification_uuid`       CHAR(36) NOT NULL,
  `backup_run_item_id`      INT UNSIGNED NOT NULL,
  `backup_run_id`           INT UNSIGNED DEFAULT NULL,
  `tenant_id`               INT UNSIGNED DEFAULT NULL,
  `verification_type`       ENUM('CHECKSUM','FILE_EXISTS','ARCHIVE_INTEGRITY','SCHEMA_VALIDATION','TEST_RESTORE','ROW_COUNT_MATCH','DR_DRILL') NOT NULL DEFAULT 'CHECKSUM',
  `trigger_type`            ENUM('AUTO_POST_BACKUP','SCHEDULED_DRILL','MANUAL','PRE_RESTORE','PRE_PURGE','AUDIT') NOT NULL DEFAULT 'AUTO_POST_BACKUP',
  `status`                  ENUM('PENDING','RUNNING','PASSED','PASSED_WITH_WARNINGS','FAILED','SKIPPED','ERROR') NOT NULL DEFAULT 'PENDING',
  `expected_checksum`       VARCHAR(128) DEFAULT NULL,
  `actual_checksum`         VARCHAR(128) DEFAULT NULL,
  `expected_size_bytes`     BIGINT UNSIGNED DEFAULT NULL,
  `actual_size_bytes`       BIGINT UNSIGNED DEFAULT NULL,
  `files_checked_count`     INT UNSIGNED NOT NULL DEFAULT 0,
  `files_failed_count`      INT UNSIGNED NOT NULL DEFAULT 0,
  `expected_table_count`    SMALLINT UNSIGNED DEFAULT NULL,
  `actual_table_count`      SMALLINT UNSIGNED DEFAULT NULL,
  `expected_row_count`      BIGINT UNSIGNED DEFAULT NULL,
  `actual_row_count`        BIGINT UNSIGNED DEFAULT NULL,
  `sandbox_db_name`         VARCHAR(100) DEFAULT NULL,             -- for TEST_RESTORE
  `sandbox_dropped_at`      TIMESTAMP NULL DEFAULT NULL,           -- sandbox MUST be dropped after the drill
  `started_at`              TIMESTAMP NULL DEFAULT NULL,
  `completed_at`            TIMESTAMP NULL DEFAULT NULL,
  `duration_seconds`        INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, `started_at`, `completed_at`)) STORED,
  `result_json`             JSON DEFAULT NULL,                     -- per-file / per-table detail
  `failure_reason`          TEXT DEFAULT NULL,
  `next_verification_due`   DATE DEFAULT NULL,                     -- policy.test_restore_frequency_days
  `verified_by`             INT UNSIGNED DEFAULT NULL,             -- NULL = system
  `remarks`                 VARCHAR(500) DEFAULT NULL,
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`              TIMESTAMP NULL DEFAULT NULL,
  `updated_at`              TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntVerif_verificationUuid`     (`verification_uuid`),
  KEY `idx_mntVerif_runItemId_type`             (`backup_run_item_id`,`verification_type`),
  KEY `idx_mntVerif_status_completedAt`         (`status`,`completed_at`),
  KEY `idx_mntVerif_tenantId`                   (`tenant_id`),
  KEY `idx_mntVerif_nextVerificationDue`        (`next_verification_due`),
  CONSTRAINT `fk_mntVerif_runItemId`  FOREIGN KEY (`backup_run_item_id`) REFERENCES `mnt_backup_run_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntVerif_runId`      FOREIGN KEY (`backup_run_id`)      REFERENCES `mnt_backup_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntVerif_tenantId`   FOREIGN KEY (`tenant_id`)          REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntVerif_verifiedBy` FOREIGN KEY (`verified_by`)        REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. A FAILED verification sets the item's verification_status = 'FAILED',
--     is_restorable = 0, and raises a CRITICAL alert. It must also SUPPRESS the
--     purge of the previous good backup until a fresh good backup exists.
--  2. TEST_RESTORE always targets a throwaway sandbox DB, never a live tenant DB.
--     `sandbox_dropped_at` NULL more than 24h after completion = cleanup defect.
--  3. A PRE_PURGE verification is mandatory when purging the LAST remaining
--     backup of a tenant.


-- =============================================================================
-- LAYER 4 — RESTORE  (absent entirely from v1)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 11. mnt_restore_requests
--     The ASK + APPROVAL. Separated from execution because a restore is a
--     high-blast-radius action that must be authorised before it runs.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_restore_requests` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_uuid`                CHAR(36) NOT NULL,
  `request_no`                  VARCHAR(40) NOT NULL,              -- 'RST-2026-07-27-0003'
  `tenant_id`                   INT UNSIGNED DEFAULT NULL,
  `tenant_code`                 VARCHAR(20)  DEFAULT NULL,         -- snapshot
  `tenant_name`                 VARCHAR(150) DEFAULT NULL,         -- snapshot
  -- --- Source ----------------------------------------------------------------
  `backup_run_item_id`          INT UNSIGNED DEFAULT NULL,         -- the backup to restore FROM
  `backup_run_id`               INT UNSIGNED DEFAULT NULL,
  `source_backup_date`          DATE DEFAULT NULL,                 -- snapshot for the UI
  `point_in_time_at`            DATETIME DEFAULT NULL,             -- PITR target (needs binlog/LOG backups)
  -- --- What & where ----------------------------------------------------------
  `restore_type`                ENUM('FULL_DATABASE','SELECTED_TABLES','FILES_ONLY','SINGLE_FILE','POINT_IN_TIME','SANDBOX_CLONE','DOWNLOAD_ONLY') NOT NULL DEFAULT 'FULL_DATABASE',
  `target_type`                 ENUM('SAME_TENANT_OVERWRITE','NEW_SANDBOX_DB','ALTERNATE_TENANT','DOWNLOAD_TO_ADMIN','EXTERNAL_HANDOVER') NOT NULL DEFAULT 'NEW_SANDBOX_DB',
  `target_tenant_id`            INT UNSIGNED DEFAULT NULL,         -- when target_type = 'ALTERNATE_TENANT'
  `target_database_name`        VARCHAR(100) DEFAULT NULL,
  `target_storage_path`         VARCHAR(500) DEFAULT NULL,         -- for FILES_ONLY
  `selected_tables_json`        JSON DEFAULT NULL,
  `selected_files_json`         JSON DEFAULT NULL,
  `overwrite_existing`          TINYINT(1) NOT NULL DEFAULT 0,
  `truncate_before_restore`     TINYINT(1) NOT NULL DEFAULT 0,
  -- --- Justification & risk --------------------------------------------------
  `reason_category`             ENUM('DATA_LOSS','DATA_CORRUPTION','ACCIDENTAL_DELETION','RANSOMWARE','MIGRATION','AUDIT','LEGAL','TESTING','DR_DRILL','TENANT_REQUEST','OTHER') NOT NULL DEFAULT 'OTHER',
  `reason`                      TEXT NOT NULL,
  `business_justification`      TEXT DEFAULT NULL,
  `risk_level`                  ENUM('LOW','MEDIUM','HIGH','CRITICAL') NOT NULL DEFAULT 'MEDIUM',
  `requires_downtime`           TINYINT(1) NOT NULL DEFAULT 0,
  `estimated_downtime_minutes`  SMALLINT UNSIGNED DEFAULT NULL,
  `maintenance_window_id`       INT UNSIGNED DEFAULT NULL,
  `requires_pre_restore_backup` TINYINT(1) NOT NULL DEFAULT 1,     -- safety net before overwrite
  `pre_restore_run_id`          INT UNSIGNED DEFAULT NULL,         -- the safety backup actually taken
  -- --- Requester -------------------------------------------------------------
  `requested_by_user_id`        INT UNSIGNED DEFAULT NULL,         -- prime_db (PG) user
  `requested_by_tenant_user_id` INT UNSIGNED DEFAULT NULL,         -- id inside the tenant DB — no FK possible
  `requested_by_name`           VARCHAR(100) DEFAULT NULL,
  `requested_by_email`          VARCHAR(150) DEFAULT NULL,
  `requested_by_type`           ENUM('PG_ADMIN','PG_SUPPORT','TENANT_ADMIN','SYSTEM','API') NOT NULL DEFAULT 'PG_ADMIN',
  `requested_at`                TIMESTAMP NULL DEFAULT NULL,
  `requester_ip_address`        VARCHAR(45) DEFAULT NULL,
  -- --- Approval (dual control for destructive restores) ----------------------
  `status`                      ENUM('DRAFT','PENDING_APPROVAL','APPROVED','REJECTED','SCHEDULED','IN_PROGRESS','COMPLETED','PARTIALLY_COMPLETED','FAILED','CANCELLED','ROLLED_BACK','EXPIRED') NOT NULL DEFAULT 'DRAFT',
  `requires_dual_approval`      TINYINT(1) NOT NULL DEFAULT 0,     -- forced 1 when SAME_TENANT_OVERWRITE
  `approver1_user_id`           INT UNSIGNED DEFAULT NULL,
  `approver1_at`                TIMESTAMP NULL DEFAULT NULL,
  `approver1_remark`            VARCHAR(500) DEFAULT NULL,
  `approver2_user_id`           INT UNSIGNED DEFAULT NULL,
  `approver2_at`                TIMESTAMP NULL DEFAULT NULL,
  `approver2_remark`            VARCHAR(500) DEFAULT NULL,
  `rejected_by`                 INT UNSIGNED DEFAULT NULL,
  `rejected_at`                 TIMESTAMP NULL DEFAULT NULL,
  `rejection_reason`            VARCHAR(500) DEFAULT NULL,
  `tenant_consent_received`     TINYINT(1) NOT NULL DEFAULT 0,     -- tenant signed off on data overwrite
  `tenant_consent_at`           TIMESTAMP NULL DEFAULT NULL,
  `tenant_consent_ref`          VARCHAR(255) DEFAULT NULL,         -- ticket / email ref
  -- --- Scheduling ------------------------------------------------------------
  `scheduled_at`                DATETIME DEFAULT NULL,
  `expires_at`                  DATETIME DEFAULT NULL,             -- approval goes stale if unused
  `priority`                    ENUM('LOW','NORMAL','HIGH','EMERGENCY') NOT NULL DEFAULT 'NORMAL',
  `remarks`                     VARCHAR(500) DEFAULT NULL,
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                  INT UNSIGNED DEFAULT NULL,
  `updated_by`                  INT UNSIGNED DEFAULT NULL,
  `created_at`                  TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntRestoreReq_requestUuid`   (`request_uuid`),
  UNIQUE KEY `uq_mntRestoreReq_requestNo`     (`request_no`),
  KEY `idx_mntRestoreReq_tenantId_status`     (`tenant_id`,`status`),
  KEY `idx_mntRestoreReq_status_requestedAt`  (`status`,`requested_at`),
  KEY `idx_mntRestoreReq_runItemId`           (`backup_run_item_id`),
  KEY `idx_mntRestoreReq_requestedByUserId`   (`requested_by_user_id`),
  KEY `idx_mntRestoreReq_scheduledAt`         (`scheduled_at`),
  CONSTRAINT `fk_mntRestoreReq_tenantId`        FOREIGN KEY (`tenant_id`)             REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRestoreReq_targetTenantId`  FOREIGN KEY (`target_tenant_id`)      REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRestoreReq_runItemId`       FOREIGN KEY (`backup_run_item_id`)    REFERENCES `mnt_backup_run_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRestoreReq_runId`           FOREIGN KEY (`backup_run_id`)         REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_windowId`        FOREIGN KEY (`maintenance_window_id`) REFERENCES `mnt_maintenance_windows` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_preRestoreRun`   FOREIGN KEY (`pre_restore_run_id`)    REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_requestedBy`     FOREIGN KEY (`requested_by_user_id`)  REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_approver1`       FOREIGN KEY (`approver1_user_id`)     REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_approver2`       FOREIGN KEY (`approver2_user_id`)     REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_rejectedBy`      FOREIGN KEY (`rejected_by`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_createdBy`       FOREIGN KEY (`created_by`)            REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreReq_updatedBy`       FOREIGN KEY (`updated_by`)            REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. HARD RULES (enforce in RestoreService + FormRequest):
--     a. target_type = 'SAME_TENANT_OVERWRITE' FORCES requires_dual_approval = 1,
--        requires_pre_restore_backup = 1, tenant_consent_received = 1 and a
--        linked maintenance_window_id.
--     b. approver1_user_id <> approver2_user_id, and neither may equal
--        requested_by_user_id. Self-approval is prohibited.
--     c. The source item must have is_restorable = 1 and verification_status
--        IN ('PASSED','PASSED_WITH_WARNINGS').
--  2. `requested_by_tenant_user_id` is intentionally FK-less: tenant users live
--     in tenant_db, which prime_db cannot reference. The name/email snapshot
--     columns exist precisely to keep the record readable.
--  3. An APPROVED request past `expires_at` moves to 'EXPIRED' and must be
--     re-approved — stale approvals are a real-world audit failure.
--  4. `restore_type = 'POINT_IN_TIME'` requires LOG-type backups covering the
--     interval between the base backup and `point_in_time_at`.


-- -----------------------------------------------------------------------------
-- 12. mnt_restore_runs
--     Execution of an approved restore request, with rollback tracking.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_restore_runs` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `run_uuid`                  CHAR(36) NOT NULL,
  `run_no`                    VARCHAR(40) NOT NULL,
  `restore_request_id`        INT UNSIGNED NOT NULL,
  `backup_run_item_id`        INT UNSIGNED DEFAULT NULL,
  `tenant_id`                 INT UNSIGNED DEFAULT NULL,
  `tenant_code`               VARCHAR(20) DEFAULT NULL,
  `attempt_no`                TINYINT UNSIGNED NOT NULL DEFAULT 1,
  -- --- Execution -------------------------------------------------------------
  `status`                    ENUM('PENDING','QUEUED','PREPARING','DOWNLOADING','DECRYPTING','DECOMPRESSING','RESTORING','VERIFYING','COMPLETED','COMPLETED_WITH_WARNINGS','FAILED','CANCELLED','ROLLED_BACK','ROLLBACK_FAILED') NOT NULL DEFAULT 'PENDING',
  `current_stage`             VARCHAR(60) DEFAULT NULL,
  `progress_percent`          TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `target_database_name`      VARCHAR(100) DEFAULT NULL,
  `target_storage_path`       VARCHAR(500) DEFAULT NULL,
  `queued_at`                 TIMESTAMP NULL DEFAULT NULL,
  `started_at`                TIMESTAMP NULL DEFAULT NULL,
  `completed_at`              TIMESTAMP NULL DEFAULT NULL,
  `duration_seconds`          INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, `started_at`, `completed_at`)) STORED,
  `downtime_start_at`         TIMESTAMP NULL DEFAULT NULL,
  `downtime_end_at`           TIMESTAMP NULL DEFAULT NULL,
  `actual_downtime_minutes`   SMALLINT UNSIGNED DEFAULT NULL,
  `rto_target_minutes`        INT UNSIGNED DEFAULT NULL,           -- copied from the plan
  `rto_breached`              TINYINT(1) NOT NULL DEFAULT 0,
  -- --- Volume ----------------------------------------------------------------
  `bytes_downloaded`          BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `bytes_restored`            BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `tables_restored_count`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `rows_restored_count`       BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `files_restored_count`      INT UNSIGNED NOT NULL DEFAULT 0,
  `files_failed_count`        INT UNSIGNED NOT NULL DEFAULT 0,
  -- --- Post-restore verification --------------------------------------------
  `post_restore_verified`     TINYINT(1) NOT NULL DEFAULT 0,
  `post_restore_check_json`   JSON DEFAULT NULL,                   -- row counts, key table spot checks
  `data_loss_window_minutes`  INT UNSIGNED DEFAULT NULL,           -- actual RPO achieved
  -- --- Rollback --------------------------------------------------------------
  `is_rolled_back`            TINYINT(1) NOT NULL DEFAULT 0,
  `rollback_run_id`           INT UNSIGNED DEFAULT NULL,           -- self-ref: the restore that undid this one
  `rolled_back_at`            TIMESTAMP NULL DEFAULT NULL,
  `rollback_reason`           VARCHAR(500) DEFAULT NULL,
  -- --- Environment / outcome -------------------------------------------------
  `queue_job_id`              VARCHAR(100) DEFAULT NULL,
  `worker_host`               VARCHAR(100) DEFAULT NULL,
  `executed_by`               INT UNSIGNED DEFAULT NULL,
  `executed_by_name`          VARCHAR(100) DEFAULT NULL,
  `error_code`                VARCHAR(50) DEFAULT NULL,
  `error_message`             TEXT DEFAULT NULL,
  `error_trace`               MEDIUMTEXT DEFAULT NULL,
  `warning_count`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `summary_json`              JSON DEFAULT NULL,
  `remarks`                   VARCHAR(500) DEFAULT NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntRestoreRuns_runUuid`      (`run_uuid`),
  UNIQUE KEY `uq_mntRestoreRuns_runNo`        (`run_no`),
  UNIQUE KEY `uq_mntRestoreRuns_req_attempt`  (`restore_request_id`,`attempt_no`),
  KEY `idx_mntRestoreRuns_status_startedAt`   (`status`,`started_at`),
  KEY `idx_mntRestoreRuns_tenantId`           (`tenant_id`),
  KEY `idx_mntRestoreRuns_runItemId`          (`backup_run_item_id`),
  KEY `idx_mntRestoreRuns_executedBy`         (`executed_by`),
  CONSTRAINT `fk_mntRestoreRuns_requestId`   FOREIGN KEY (`restore_request_id`)  REFERENCES `mnt_restore_requests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntRestoreRuns_runItemId`   FOREIGN KEY (`backup_run_item_id`)  REFERENCES `mnt_backup_run_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRestoreRuns_tenantId`    FOREIGN KEY (`tenant_id`)           REFERENCES `prm_tenant` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntRestoreRuns_rollbackRun` FOREIGN KEY (`rollback_run_id`)     REFERENCES `mnt_restore_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntRestoreRuns_executedBy`  FOREIGN KEY (`executed_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntRestoreRuns_progress`   CHECK (`progress_percent` BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. A run may only start when its request is 'APPROVED' (or 'SCHEDULED') and
--     not expired. The service must re-check at execution time, not only at
--     approval time.
--  2. Rollback = execute a NEW restore run from `pre_restore_run_id`'s backup,
--     then stamp rollback_run_id / is_rolled_back on the failed run.
--  3. `rto_breached` = 1 when actual duration exceeds `rto_target_minutes`;
--     drives the SLA report.
--  4. On success the service increments the source item's `restore_count` and
--     stamps `last_accessed_at` / `last_accessed_by`.


-- =============================================================================
-- LAYER 5 — RETENTION EXTENSION, ARCHIVE ACCESS, PURGE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 13. mnt_retention_extension_requests
--     "Backup will be kept for a certain period but Tenant can demand (Paid
--      Service) to extend the duration" + "We can extend the Backup End Date".
--     This table is the request, the quote, the approval and the billing link.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_retention_extension_requests` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_uuid`                CHAR(36) NOT NULL,
  `request_no`                  VARCHAR(40) NOT NULL,              -- 'EXT-2026-07-27-0011'
  `tenant_id`                   INT UNSIGNED NOT NULL,
  `tenant_code`                 VARCHAR(20)  DEFAULT NULL,         -- snapshot
  `tenant_name`                 VARCHAR(150) DEFAULT NULL,         -- snapshot
  `maintenance_plan_id`         INT UNSIGNED DEFAULT NULL,
  `retention_policy_id`         INT UNSIGNED DEFAULT NULL,
  -- --- Scope of the extension ------------------------------------------------
  `scope_type`                  ENUM('SINGLE_ITEM','SELECTED_ITEMS','ALL_ITEMS_IN_RUN','DATE_RANGE','ALL_TENANT_BACKUPS','FUTURE_BACKUPS') NOT NULL DEFAULT 'SELECTED_ITEMS',
  `backup_run_id`               INT UNSIGNED DEFAULT NULL,         -- for ALL_ITEMS_IN_RUN
  `scope_from_date`             DATE DEFAULT NULL,                 -- for DATE_RANGE
  `scope_to_date`               DATE DEFAULT NULL,
  `content_types_json`          JSON DEFAULT NULL,                 -- ["DATABASE","IMAGES"]
  `items_count`                 SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `total_size_bytes`            BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `total_size_gb`               DECIMAL(12,4) GENERATED ALWAYS AS (`total_size_bytes` / 1073741824) STORED,
  -- --- The ask ---------------------------------------------------------------
  `requested_extension_days`    SMALLINT UNSIGNED NOT NULL,
  `requested_extension_months`  DECIMAL(6,2) DEFAULT NULL,         -- billing unit
  `current_end_date`            DATE DEFAULT NULL,                 -- earliest retention_end_date in scope
  `requested_new_end_date`      DATE DEFAULT NULL,
  `granted_extension_days`      SMALLINT UNSIGNED DEFAULT NULL,    -- may differ from requested
  `granted_new_end_date`        DATE DEFAULT NULL,                 -- what was actually applied
  `reason`                      TEXT DEFAULT NULL,                 -- audit / legal case / migration
  `reason_category`             ENUM('AUDIT','LEGAL_CASE','STATUTORY','ACCREDITATION','MIGRATION','DISPUTE','INTERNAL_REVIEW','OTHER') NOT NULL DEFAULT 'OTHER',
  `priority`                    ENUM('LOW','NORMAL','HIGH','URGENT') NOT NULL DEFAULT 'NORMAL',
  -- --- Requester -------------------------------------------------------------
  `requested_by_user_id`        INT UNSIGNED DEFAULT NULL,         -- PG user raising on tenant's behalf
  `requested_by_tenant_user_id` INT UNSIGNED DEFAULT NULL,         -- lives in tenant_db — no FK
  `requested_by_name`           VARCHAR(100) DEFAULT NULL,
  `requested_by_email`          VARCHAR(150) DEFAULT NULL,
  `requested_by_mobile`         VARCHAR(32)  DEFAULT NULL,
  `requested_by_type`           ENUM('TENANT_ADMIN','PG_ADMIN','PG_SUPPORT','SYSTEM','API') NOT NULL DEFAULT 'TENANT_ADMIN',
  `requested_at`                TIMESTAMP NULL DEFAULT NULL,
  `requester_ip_address`        VARCHAR(45) DEFAULT NULL,
  -- --- Commercial (PAID SERVICE) --------------------------------------------
  `is_chargeable`               TINYINT(1) NOT NULL DEFAULT 1,
  `is_waived`                   TINYINT(1) NOT NULL DEFAULT 0,
  `waiver_reason`               VARCHAR(255) DEFAULT NULL,
  `waived_by`                   INT UNSIGNED DEFAULT NULL,
  `rate_per_gb_month`           DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
  `flat_fee_month`              DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `billable_months`             DECIMAL(6,2)  NOT NULL DEFAULT 0.00,
  `sub_total`                   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `discount_percent`            DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  `discount_amount`             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `discount_remark`             VARCHAR(100)  DEFAULT NULL,
  `tax_percent`                 DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
  `tax_amount`                  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total_amount`                DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `currency`                    CHAR(3) NOT NULL DEFAULT 'INR',
  `quote_generated_at`          TIMESTAMP NULL DEFAULT NULL,
  `quote_valid_until`           DATE DEFAULT NULL,
  `quote_accepted_at`           TIMESTAMP NULL DEFAULT NULL,
  `quote_accepted_by_name`      VARCHAR(100) DEFAULT NULL,
  `payment_status`              ENUM('NOT_APPLICABLE','PENDING_QUOTE','QUOTED','AWAITING_PAYMENT','PARTIALLY_PAID','PAID','FAILED','REFUNDED','WAIVED') NOT NULL DEFAULT 'PENDING_QUOTE',
  `paid_amount`                 DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `paid_at`                     TIMESTAMP NULL DEFAULT NULL,
  `tenant_invoice_id`           INT UNSIGNED DEFAULT NULL,         -- FK to bil_tenant_invoices
  `payment_reference`           VARCHAR(100) DEFAULT NULL,
  -- --- Approval & application ------------------------------------------------
  `status`                      ENUM('DRAFT','SUBMITTED','UNDER_REVIEW','QUOTED','AWAITING_PAYMENT','APPROVED','REJECTED','APPLIED','PARTIALLY_APPLIED','CANCELLED','EXPIRED','FAILED') NOT NULL DEFAULT 'DRAFT',
  `reviewed_by`                 INT UNSIGNED DEFAULT NULL,
  `reviewed_at`                 TIMESTAMP NULL DEFAULT NULL,
  `approved_by`                 INT UNSIGNED DEFAULT NULL,
  `approved_at`                 TIMESTAMP NULL DEFAULT NULL,
  `admin_remark`                TEXT DEFAULT NULL,
  `rejected_by`                 INT UNSIGNED DEFAULT NULL,
  `rejected_at`                 TIMESTAMP NULL DEFAULT NULL,
  `rejection_reason`            VARCHAR(500) DEFAULT NULL,
  `applied_at`                  TIMESTAMP NULL DEFAULT NULL,       -- when retention_end_date was actually moved
  `applied_by`                  INT UNSIGNED DEFAULT NULL,
  `items_applied_count`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `items_failed_count`          SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `apply_error_message`         TEXT DEFAULT NULL,
  `is_auto_renew`               TINYINT(1) NOT NULL DEFAULT 0,     -- keep extending each cycle
  `next_renewal_date`           DATE DEFAULT NULL,
  `previous_request_id`         INT UNSIGNED DEFAULT NULL,         -- chain of successive extensions
  `remarks`                     VARCHAR(500) DEFAULT NULL,
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                  INT UNSIGNED DEFAULT NULL,
  `updated_by`                  INT UNSIGNED DEFAULT NULL,
  `created_at`                  TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                  TIMESTAMP NULL DEFAULT NULL,
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntExtReq_requestUuid`       (`request_uuid`),
  UNIQUE KEY `uq_mntExtReq_requestNo`         (`request_no`),
  KEY `idx_mntExtReq_tenantId_status`         (`tenant_id`,`status`),
  KEY `idx_mntExtReq_status_requestedAt`      (`status`,`requested_at`),
  KEY `idx_mntExtReq_paymentStatus`           (`payment_status`),
  KEY `idx_mntExtReq_invoiceId`               (`tenant_invoice_id`),
  KEY `idx_mntExtReq_nextRenewalDate`         (`next_renewal_date`),
  KEY `idx_mntExtReq_previousRequestId`       (`previous_request_id`),
  CONSTRAINT `fk_mntExtReq_tenantId`      FOREIGN KEY (`tenant_id`)           REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntExtReq_planId`        FOREIGN KEY (`maintenance_plan_id`) REFERENCES `mnt_maintenance_plans` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_retPolicyId`   FOREIGN KEY (`retention_policy_id`) REFERENCES `mnt_retention_policies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_backupRunId`   FOREIGN KEY (`backup_run_id`)       REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_invoiceId`     FOREIGN KEY (`tenant_invoice_id`)   REFERENCES `bil_tenant_invoices` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_prevRequestId` FOREIGN KEY (`previous_request_id`) REFERENCES `mnt_retention_extension_requests` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_requestedBy`   FOREIGN KEY (`requested_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_reviewedBy`    FOREIGN KEY (`reviewed_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_approvedBy`    FOREIGN KEY (`approved_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_rejectedBy`    FOREIGN KEY (`rejected_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_waivedBy`      FOREIGN KEY (`waived_by`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_appliedBy`     FOREIGN KEY (`applied_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_createdBy`     FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntExtReq_updatedBy`     FOREIGN KEY (`updated_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntExtReq_extensionDays` CHECK (`requested_extension_days` > 0),
  CONSTRAINT `chk_mntExtReq_scopeDates`    CHECK (`scope_to_date` IS NULL OR `scope_from_date` IS NULL OR `scope_to_date` >= `scope_from_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. STATUS MACHINE:
--     DRAFT -> SUBMITTED -> UNDER_REVIEW -> QUOTED -> AWAITING_PAYMENT
--           -> APPROVED -> APPLIED   (any state -> REJECTED / CANCELLED / EXPIRED)
--     Free extensions (is_chargeable = 0 or is_waived = 1) skip
--     QUOTED / AWAITING_PAYMENT and go UNDER_REVIEW -> APPROVED -> APPLIED.
--  2. PRICING FORMULA (stamped at quote time, never recomputed later):
--       billable_months = CEIL(granted_extension_days / 30)
--       sub_total       = MAX(policy.extension_min_charge,
--                             (flat_fee_month + rate_per_gb_month * total_size_gb)
--                             * billable_months)
--       tax_amount      = (sub_total - discount_amount) * tax_percent / 100
--       total_amount    = sub_total - discount_amount + tax_amount
--  3. VALIDATION before SUBMITTED:
--     a. policy.allow_extension = 1
--     b. requested_extension_days BETWEEN policy.extension_min_days
--        AND COALESCE(policy.extension_max_days, requested_extension_days)
--     c. item.extension_count < COALESCE(policy.max_extensions_allowed, 999)
--     d. current_end_date - CURDATE() >= policy.extension_lead_time_days
--        (cannot request the day before deletion)
--     e. No item in scope may already be PURGED.
--  4. APPLY step (transactional, per item, logged in the junction table 14):
--     UPDATE mnt_backup_run_items
--        SET retention_end_date       = retention_end_date + granted_extension_days,
--            grace_end_date           = retention_end_date + policy.grace_period_days,
--            extension_count          = extension_count + 1,
--            total_extended_days      = total_extended_days + granted_extension_days,
--            last_extension_request_id= <this id>,
--            purge_status             = 'EXTENDED',
--            is_billable              = 1
--     `original_retention_end_date` is NOT touched.
--  5. If payment fails or is refunded, the extension is REVERSED via the
--     junction table's stored previous_end_date — never by guessing.


-- -----------------------------------------------------------------------------
-- 14. mnt_retention_extension_item_jnt
--     Exactly which backup items an extension covered, and the before/after
--     end dates. This is what makes an extension reversible and auditable.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_retention_extension_item_jnt` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `extension_request_id`      INT UNSIGNED NOT NULL,
  `backup_run_item_id`        INT UNSIGNED NOT NULL,
  `previous_end_date`         DATE NOT NULL,                       -- value BEFORE this extension (rollback source)
  `new_end_date`              DATE NOT NULL,                       -- value AFTER this extension
  `extended_days`             SMALLINT UNSIGNED NOT NULL,
  `item_size_bytes`           BIGINT UNSIGNED NOT NULL DEFAULT 0,  -- size at quote time (billing evidence)
  `item_charge_amount`        DECIMAL(12,2) NOT NULL DEFAULT 0.00, -- allocated share of total_amount
  `apply_status`              ENUM('PENDING','APPLIED','FAILED','REVERSED','SKIPPED') NOT NULL DEFAULT 'PENDING',
  `applied_at`                TIMESTAMP NULL DEFAULT NULL,
  `reversed_at`               TIMESTAMP NULL DEFAULT NULL,
  `reversal_reason`           VARCHAR(255) DEFAULT NULL,
  `error_message`             VARCHAR(500) DEFAULT NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntExtItem_reqId_itemId`  (`extension_request_id`,`backup_run_item_id`),
  KEY `idx_mntExtItem_runItemId`           (`backup_run_item_id`),
  KEY `idx_mntExtItem_applyStatus`         (`apply_status`),
  CONSTRAINT `fk_mntExtItem_extReqId`  FOREIGN KEY (`extension_request_id`) REFERENCES `mnt_retention_extension_requests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntExtItem_runItemId` FOREIGN KEY (`backup_run_item_id`)   REFERENCES `mnt_backup_run_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_mntExtItem_dateOrder` CHECK (`new_end_date` > `previous_end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. Rows are inserted with apply_status = 'PENDING' at APPROVAL time and
--     flipped to 'APPLIED' inside the same transaction that updates the item.
--  2. REVERSAL sets the item's retention_end_date back to `previous_end_date`
--     and decrements extension_count / total_extended_days.


-- -----------------------------------------------------------------------------
-- 15. mnt_archive_access_requests   (rewrite of v1 `mnt_tenant_archive_access_requests`)
--     "Tenant can raise request to access Archived Database for a certain period."
--     v1's version did not compile (see EVALUATION A1/A2) and had no lifecycle.
--     Renamed: the `tenant_` infix was redundant.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_archive_access_requests` (
  `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_uuid`                CHAR(36) NOT NULL,
  `request_no`                  VARCHAR(40) NOT NULL,              -- 'ARC-2026-07-27-0004'
  `tenant_id`                   INT UNSIGNED NOT NULL,             -- v1 had this COMMENTED OUT but indexed it — fixed
  `tenant_code`                 VARCHAR(20)  NOT NULL,             -- v1 field, kept (now a snapshot alongside FK)
  `tenant_name`                 VARCHAR(150) DEFAULT NULL,
  -- --- What archive is being asked for ---------------------------------------
  `archive_reference`           VARCHAR(255) DEFAULT NULL,         -- v1 `archive_tenant_id`, renamed & clarified
  `backup_run_item_id`          INT UNSIGNED DEFAULT NULL,         -- the specific archived backup
  `backup_run_id`               INT UNSIGNED DEFAULT NULL,
  `archived_academic_year`      VARCHAR(20)  DEFAULT NULL,         -- '2019-2020' — how schools actually ask
  `archive_from_date`           DATE DEFAULT NULL,
  `archive_to_date`             DATE DEFAULT NULL,
  `content_types_json`          JSON DEFAULT NULL,                 -- ["DATABASE","DOCUMENTS"]
  `access_mode`                 ENUM('READ_ONLY_DB','REPORT_ONLY','FILE_DOWNLOAD','SANDBOX_FULL','EXPORT_EXTRACT') NOT NULL DEFAULT 'READ_ONLY_DB',
  `specific_modules_json`       JSON DEFAULT NULL,                 -- limit to e.g. ["StudentProfile","Exam"]
  `specific_tables_json`        JSON DEFAULT NULL,
  -- --- Duration --------------------------------------------------------------
  `requested_duration_minutes`  INT UNSIGNED DEFAULT NULL,         -- v1 field, kept
  `granted_duration_minutes`    INT UNSIGNED DEFAULT NULL,         -- v1 field, kept
  `requested_from_at`           DATETIME DEFAULT NULL,
  `requested_to_at`             DATETIME DEFAULT NULL,
  `max_sessions_allowed`        TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `max_concurrent_users`        TINYINT UNSIGNED NOT NULL DEFAULT 1,
  -- --- Justification ---------------------------------------------------------
  `purpose_category`            ENUM('AUDIT','LEGAL','ALUMNI_RECORD','TC_ISSUE','CERTIFICATE_REISSUE','GOVT_INSPECTION','ACCREDITATION','PARENT_QUERY','INTERNAL_REVIEW','OTHER') NOT NULL DEFAULT 'OTHER',
  `purpose`                     TEXT NOT NULL,
  `supporting_document_ref`     VARCHAR(255) DEFAULT NULL,         -- sys_media reference / ticket no
  -- --- Requester (v1 fields kept, types corrected) ---------------------------
  `requested_by_user_id`        INT UNSIGNED DEFAULT NULL,         -- v1 field, kept — INT to match sys_users
  `requested_by_tenant_user_id` INT UNSIGNED DEFAULT NULL,         -- v1 field, kept — lives in tenant_db, no FK
  `requested_by_tenant_user_email` VARCHAR(150) DEFAULT NULL,      -- v1 field, kept
  `requested_by_tenant_user_name`  VARCHAR(100) DEFAULT NULL,      -- v1 field, kept
  `requested_by_designation`    VARCHAR(100) DEFAULT NULL,
  `requested_by_mobile`         VARCHAR(32)  DEFAULT NULL,
  `requested_at`                TIMESTAMP NULL DEFAULT NULL,
  `requester_ip_address`        VARCHAR(45) DEFAULT NULL,
  -- --- Commercial (archive access may itself be chargeable) ------------------
  `is_chargeable`               TINYINT(1) NOT NULL DEFAULT 0,
  `charge_amount`               DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax_amount`                  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total_amount`                DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `currency`                    CHAR(3) NOT NULL DEFAULT 'INR',
  `payment_status`              ENUM('NOT_APPLICABLE','AWAITING_PAYMENT','PAID','WAIVED','REFUNDED') NOT NULL DEFAULT 'NOT_APPLICABLE',
  `tenant_invoice_id`           INT UNSIGNED DEFAULT NULL,
  -- --- Approval (v1 fields kept, types corrected) ----------------------------
  `status`                      ENUM('DRAFT','PENDING','UNDER_REVIEW','APPROVED','REJECTED','PROVISIONING','ACTIVE','EXPIRED','REVOKED','COMPLETED','FAILED') NOT NULL DEFAULT 'PENDING',
  `approved_by_user_id`         INT UNSIGNED DEFAULT NULL,         -- v1 field, kept — was BIGINT (mismatch), now INT
  `approved_at`                 TIMESTAMP NULL DEFAULT NULL,       -- v1 field, kept
  `admin_remark`                TEXT DEFAULT NULL,                 -- v1 field, kept
  `rejected_by_user_id`         INT UNSIGNED DEFAULT NULL,
  `rejected_at`                 TIMESTAMP NULL DEFAULT NULL,
  `rejection_reason`            VARCHAR(500) DEFAULT NULL,
  `revoked_by_user_id`          INT UNSIGNED DEFAULT NULL,
  `revoked_at`                  TIMESTAMP NULL DEFAULT NULL,
  `revocation_reason`           VARCHAR(500) DEFAULT NULL,
  -- --- Access control --------------------------------------------------------
  `access_ip_address`           VARCHAR(45)  DEFAULT NULL,         -- v1 field, kept (requester's IP at grant)
  `allowed_ip_list_json`        JSON DEFAULT NULL,                 -- IP allow-list for the session
  `require_mfa`                 TINYINT(1) NOT NULL DEFAULT 1,
  `is_watermarked`              TINYINT(1) NOT NULL DEFAULT 1,     -- stamp exports with requester identity
  `allow_download`              TINYINT(1) NOT NULL DEFAULT 0,
  `allow_export`                TINYINT(1) NOT NULL DEFAULT 0,
  `nda_accepted`                TINYINT(1) NOT NULL DEFAULT 0,
  `nda_accepted_at`             TIMESTAMP NULL DEFAULT NULL,
  -- --- Outcome ---------------------------------------------------------------
  `access_granted_at`           TIMESTAMP NULL DEFAULT NULL,
  `access_expired_at`           TIMESTAMP NULL DEFAULT NULL,       -- v1 field, kept — hard expiry
  `sessions_created_count`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `extension_count`             TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `remarks`                     VARCHAR(500) DEFAULT NULL,
  `is_active`                   TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                  INT UNSIGNED DEFAULT NULL,
  `updated_by`                  INT UNSIGNED DEFAULT NULL,
  `created_at`                  TIMESTAMP NULL DEFAULT NULL,       -- v1 field, kept
  `updated_at`                  TIMESTAMP NULL DEFAULT NULL,       -- v1 field, kept
  `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntArcReq_requestUuid`         (`request_uuid`),
  UNIQUE KEY `uq_mntArcReq_requestNo`           (`request_no`),
  KEY `idx_mntArcReq_tenantId_status`           (`tenant_id`,`status`),
  KEY `idx_mntArcReq_tenantCode`                (`tenant_code`),         -- v1 index, kept
  KEY `idx_mntArcReq_archiveRef_status`         (`archive_reference`,`status`),  -- v1 index, kept (fixed)
  KEY `idx_mntArcReq_status_requestedAt`        (`status`,`requested_at`),
  KEY `idx_mntArcReq_accessExpiredAt`           (`access_expired_at`),
  KEY `idx_mntArcReq_runItemId`                 (`backup_run_item_id`),
  KEY `idx_mntArcReq_requestedByUserId`         (`requested_by_user_id`),
  CONSTRAINT `fk_mntArcReq_tenantId`      FOREIGN KEY (`tenant_id`)            REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntArcReq_runItemId`     FOREIGN KEY (`backup_run_item_id`)   REFERENCES `mnt_backup_run_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntArcReq_runId`         FOREIGN KEY (`backup_run_id`)        REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_invoiceId`     FOREIGN KEY (`tenant_invoice_id`)    REFERENCES `bil_tenant_invoices` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_requestedBy`   FOREIGN KEY (`requested_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_approvedBy`    FOREIGN KEY (`approved_by_user_id`)  REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_rejectedBy`    FOREIGN KEY (`rejected_by_user_id`)  REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_revokedBy`     FOREIGN KEY (`revoked_by_user_id`)   REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_createdBy`     FOREIGN KEY (`created_by`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcReq_updatedBy`     FOREIGN KEY (`updated_by`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntArcReq_archiveRange` CHECK (`archive_to_date` IS NULL OR `archive_from_date` IS NULL OR `archive_to_date` >= `archive_from_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. v1's UNIQUE (tenant_id, archive_tenant_id) is DELIBERATELY NOT carried
--     forward. It would have permitted a tenant only ONE archive request per
--     archive, ever — a school cannot ask twice in two different years.
--     Repeat requests are legitimate; uniqueness lives on request_no instead.
--  2. An APPROVED request grants access only while
--     CURRENT_TIMESTAMP < access_expired_at AND status = 'ACTIVE'.
--     A nightly job expires stale rows and drops their sandbox databases.
--  3. Approval must verify the source item still exists and is not PURGED. If
--     the backup has been purged, the request is auto-REJECTED with reason
--     'SOURCE_BACKUP_PURGED'.
--  4. If the archive lives in ARCHIVE / DEEP_ARCHIVE storage class, provisioning
--     must first thaw it — see mnt_backup_run_items.restore_lead_time_hours.
--     Tenant is told the realistic availability time, not "instant".


-- -----------------------------------------------------------------------------
-- 16. mnt_archive_access_sessions
--     A single time-boxed, credentialled access session created from an
--     approved request, plus what was actually done during it.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_archive_access_sessions` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `session_uuid`              CHAR(36) NOT NULL,
  `archive_access_request_id` INT UNSIGNED NOT NULL,
  `tenant_id`                 INT UNSIGNED NOT NULL,
  `backup_run_item_id`        INT UNSIGNED DEFAULT NULL,
  `session_no`                TINYINT UNSIGNED NOT NULL DEFAULT 1,
  -- --- Provisioned resource --------------------------------------------------
  `access_mode`               ENUM('READ_ONLY_DB','REPORT_ONLY','FILE_DOWNLOAD','SANDBOX_FULL','EXPORT_EXTRACT') NOT NULL DEFAULT 'READ_ONLY_DB',
  `sandbox_db_name`           VARCHAR(100) DEFAULT NULL,
  `sandbox_db_host`           VARCHAR(200) DEFAULT NULL,
  `sandbox_db_username`       VARCHAR(100) DEFAULT NULL,
  `sandbox_credential_ref`    VARCHAR(255) DEFAULT NULL,           -- vault ref — NEVER a plaintext password
  `sandbox_url`               VARCHAR(500) DEFAULT NULL,           -- read-only UI entry point
  `access_token_hash`         VARCHAR(255) DEFAULT NULL,           -- hash only
  `is_read_only`              TINYINT(1) NOT NULL DEFAULT 1,
  `provisioned_at`            TIMESTAMP NULL DEFAULT NULL,
  `provisioning_duration_sec` INT UNSIGNED DEFAULT NULL,
  -- --- Validity --------------------------------------------------------------
  `valid_from`                DATETIME NOT NULL,
  `valid_until`               DATETIME NOT NULL,
  `status`                    ENUM('PROVISIONING','ACTIVE','IDLE','EXPIRED','REVOKED','TERMINATED','FAILED','CLEANED_UP') NOT NULL DEFAULT 'PROVISIONING',
  `auto_extend_allowed`       TINYINT(1) NOT NULL DEFAULT 0,
  `extension_count`           TINYINT UNSIGNED NOT NULL DEFAULT 0,
  -- --- Usage audit -----------------------------------------------------------
  `first_login_at`            TIMESTAMP NULL DEFAULT NULL,
  `last_activity_at`          TIMESTAMP NULL DEFAULT NULL,
  `login_count`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `query_count`               INT UNSIGNED NOT NULL DEFAULT 0,
  `records_viewed_count`      INT UNSIGNED NOT NULL DEFAULT 0,
  `downloads_count`           SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `exports_count`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `bytes_transferred`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `accessed_modules_json`     JSON DEFAULT NULL,
  `accessed_from_ip`          VARCHAR(45)  DEFAULT NULL,
  `user_agent`                VARCHAR(255) DEFAULT NULL,
  `mfa_verified_at`           TIMESTAMP NULL DEFAULT NULL,
  `suspicious_activity_flag`  TINYINT(1) NOT NULL DEFAULT 0,       -- bulk export / off-hours / IP mismatch
  `suspicious_activity_note`  VARCHAR(500) DEFAULT NULL,
  -- --- Teardown --------------------------------------------------------------
  `terminated_at`             TIMESTAMP NULL DEFAULT NULL,
  `terminated_by`             INT UNSIGNED DEFAULT NULL,
  `termination_reason`        VARCHAR(255) DEFAULT NULL,
  `sandbox_dropped_at`        TIMESTAMP NULL DEFAULT NULL,         -- MUST be set — leaving it up leaks data
  `cleanup_status`            ENUM('PENDING','DONE','FAILED') NOT NULL DEFAULT 'PENDING',
  `cleanup_error`             VARCHAR(500) DEFAULT NULL,
  `remarks`                   VARCHAR(500) DEFAULT NULL,
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                INT UNSIGNED DEFAULT NULL,
  `created_at`                TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntArcSess_sessionUuid`      (`session_uuid`),
  UNIQUE KEY `uq_mntArcSess_reqId_sessionNo`  (`archive_access_request_id`,`session_no`),
  KEY `idx_mntArcSess_tenantId_status`        (`tenant_id`,`status`),
  KEY `idx_mntArcSess_validUntil_status`      (`valid_until`,`status`),
  KEY `idx_mntArcSess_cleanupStatus`          (`cleanup_status`),
  KEY `idx_mntArcSess_runItemId`              (`backup_run_item_id`),
  CONSTRAINT `fk_mntArcSess_requestId`   FOREIGN KEY (`archive_access_request_id`) REFERENCES `mnt_archive_access_requests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntArcSess_tenantId`    FOREIGN KEY (`tenant_id`)                 REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntArcSess_runItemId`   FOREIGN KEY (`backup_run_item_id`)        REFERENCES `mnt_backup_run_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_mntArcSess_terminatedBy` FOREIGN KEY (`terminated_by`)            REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntArcSess_createdBy`   FOREIGN KEY (`created_by`)                REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_mntArcSess_validity`   CHECK (`valid_until` > `valid_from`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. A backup item with an ACTIVE session on it can NEVER be purged. The purge
--     eligibility check must join this table.
--  2. Cleanup job: every 15 minutes, for sessions past valid_until —
--     status -> EXPIRED, revoke DB grants, DROP the sandbox DB, invalidate the
--     token, stamp sandbox_dropped_at and cleanup_status = 'DONE'.
--  3. `sandbox_credential_ref` and `access_token_hash` never hold recoverable
--     secrets. Credentials are one-time, shown once at provisioning.


-- -----------------------------------------------------------------------------
-- 17. mnt_purge_logs
--     "After that pre-defined period, we can remove the old Backup."
--     Evidence of destruction. One row per purge BATCH; the affected items and
--     files point back here via purge_log_id.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_purge_logs` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `purge_uuid`                CHAR(36) NOT NULL,
  `purge_no`                  VARCHAR(40) NOT NULL,                -- 'PRG-2026-07-27-0002'
  `purge_type`                ENUM('SCHEDULED_RETENTION','MANUAL','STORAGE_RECLAIM','TENANT_OFFBOARDING','GDPR_ERASURE','DUPLICATE_CLEANUP','CORRUPT_CLEANUP','FAILED_RUN_CLEANUP') NOT NULL DEFAULT 'SCHEDULED_RETENTION',
  `purge_reason`              VARCHAR(500) DEFAULT NULL,
  `tenant_id`                 INT UNSIGNED DEFAULT NULL,           -- NULL = cross-tenant batch
  `tenant_code`               VARCHAR(20)  DEFAULT NULL,           -- snapshot (tenant may be gone afterwards)
  `tenant_name`               VARCHAR(150) DEFAULT NULL,           -- snapshot
  `storage_destination_id`    INT UNSIGNED DEFAULT NULL,
  `retention_policy_id`       INT UNSIGNED DEFAULT NULL,
  -- --- Scope & selection evidence -------------------------------------------
  `selection_criteria_json`   JSON DEFAULT NULL,                   -- the exact filter used (reproducible)
  `dry_run`                   TINYINT(1) NOT NULL DEFAULT 0,       -- preview mode: nothing is deleted
  `items_selected_count`      INT UNSIGNED NOT NULL DEFAULT 0,
  `items_purged_count`        INT UNSIGNED NOT NULL DEFAULT 0,
  `items_skipped_count`       INT UNSIGNED NOT NULL DEFAULT 0,
  `items_failed_count`        INT UNSIGNED NOT NULL DEFAULT 0,
  `files_deleted_count`       INT UNSIGNED NOT NULL DEFAULT 0,
  `bytes_reclaimed`           BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `gb_reclaimed`              DECIMAL(14,4) GENERATED ALWAYS AS (`bytes_reclaimed` / 1073741824) STORED,
  `purged_items_json`         JSON DEFAULT NULL,                   -- [{item_id,tenant_code,end_date,bytes}]
  `skipped_items_json`        JSON DEFAULT NULL,                   -- [{item_id,skip_reason}]
  `earliest_backup_date`      DATE DEFAULT NULL,
  `latest_backup_date`        DATE DEFAULT NULL,
  -- --- Safety gates ----------------------------------------------------------
  `pre_purge_verified`        TINYINT(1) NOT NULL DEFAULT 0,       -- a newer good backup exists
  `legal_hold_checked`        TINYINT(1) NOT NULL DEFAULT 1,
  `active_sessions_checked`   TINYINT(1) NOT NULL DEFAULT 1,
  `chain_dependency_checked`  TINYINT(1) NOT NULL DEFAULT 1,       -- no INCR child left orphaned
  `min_retention_respected`   TINYINT(1) NOT NULL DEFAULT 1,
  `tenant_notified`           TINYINT(1) NOT NULL DEFAULT 0,
  `tenant_notified_at`        TIMESTAMP NULL DEFAULT NULL,
  `is_recoverable`            TINYINT(1) NOT NULL DEFAULT 0,       -- 1 only if destination has versioning/trash
  `recoverable_until`         DATE DEFAULT NULL,
  -- --- Approval --------------------------------------------------------------
  `requires_approval`         TINYINT(1) NOT NULL DEFAULT 1,
  `approval_status`           ENUM('NOT_REQUIRED','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'PENDING',
  `approved_by`               INT UNSIGNED DEFAULT NULL,
  `approved_at`               TIMESTAMP NULL DEFAULT NULL,
  `approval_remark`           VARCHAR(500) DEFAULT NULL,
  `second_approved_by`        INT UNSIGNED DEFAULT NULL,           -- dual control for GDPR_ERASURE
  `second_approved_at`        TIMESTAMP NULL DEFAULT NULL,
  `rejected_by`               INT UNSIGNED DEFAULT NULL,
  `rejected_at`               TIMESTAMP NULL DEFAULT NULL,
  `rejection_reason`          VARCHAR(500) DEFAULT NULL,
  -- --- Execution -------------------------------------------------------------
  `status`                    ENUM('PENDING','APPROVED','QUEUED','RUNNING','COMPLETED','COMPLETED_WITH_ERRORS','FAILED','CANCELLED','SKIPPED') NOT NULL DEFAULT 'PENDING',
  `started_at`                TIMESTAMP NULL DEFAULT NULL,
  `completed_at`              TIMESTAMP NULL DEFAULT NULL,
  `duration_seconds`          INT UNSIGNED GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, `started_at`, `completed_at`)) STORED,
  `executed_by`               INT UNSIGNED DEFAULT NULL,           -- NULL = system cron
  `executed_by_name`          VARCHAR(100) DEFAULT NULL,
  `executed_by_type`          ENUM('USER','SYSTEM','CRON','API') NOT NULL DEFAULT 'CRON',
  `executor_ip_address`       VARCHAR(45) DEFAULT NULL,
  `error_code`                VARCHAR(50) DEFAULT NULL,
  `error_message`             TEXT DEFAULT NULL,
  -- --- Compliance evidence ---------------------------------------------------
  `destruction_certificate_no` VARCHAR(60) DEFAULT NULL,           -- issued for GDPR/DPDP erasure
  `certificate_issued_at`      TIMESTAMP NULL DEFAULT NULL,
  `compliance_tag`             VARCHAR(60) DEFAULT NULL,
  `remarks`                    VARCHAR(500) DEFAULT NULL,
  `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`                 TIMESTAMP NULL DEFAULT NULL,
  `updated_at`                 TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntPurge_purgeUuid`        (`purge_uuid`),
  UNIQUE KEY `uq_mntPurge_purgeNo`          (`purge_no`),
  KEY `idx_mntPurge_tenantId_status`        (`tenant_id`,`status`),
  KEY `idx_mntPurge_status_startedAt`       (`status`,`started_at`),
  KEY `idx_mntPurge_purgeType`              (`purge_type`),
  KEY `idx_mntPurge_approvalStatus`         (`approval_status`),
  KEY `idx_mntPurge_executedBy`             (`executed_by`),
  CONSTRAINT `fk_mntPurge_tenantId`      FOREIGN KEY (`tenant_id`)              REFERENCES `prm_tenant` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPurge_storageDestId` FOREIGN KEY (`storage_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPurge_retPolicyId`   FOREIGN KEY (`retention_policy_id`)    REFERENCES `mnt_retention_policies` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPurge_approvedBy`    FOREIGN KEY (`approved_by`)            REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPurge_secondApprover` FOREIGN KEY (`second_approved_by`)    REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPurge_rejectedBy`    FOREIGN KEY (`rejected_by`)            REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntPurge_executedBy`    FOREIGN KEY (`executed_by`)            REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. `fk_mntPurge_tenantId` is SET NULL (not CASCADE / RESTRICT): the proof that
--     a tenant's data was destroyed must OUTLIVE the tenant row. That is why the
--     tenant_code / tenant_name snapshots are mandatory on this table.
--  2. NOTHING is deleted until approval_status IN ('NOT_REQUIRED','APPROVED')
--     and all five safety-gate flags are 1.
--  3. Always run `dry_run = 1` first for MANUAL and GDPR_ERASURE purges; the
--     UI shows the preview from `purged_items_json` before real execution.
--  4. GDPR_ERASURE requires dual approval (approved_by <> second_approved_by)
--     and issues a `destruction_certificate_no`.
--  5. Purge order per item: delete OFFSITE/ARCHIVE copies, then PRIMARY, then
--     mark files is_deleted = 1, then item purge_status = 'PURGED'. Never delete
--     the last remaining copy before the others are confirmed gone.


-- =============================================================================
-- LAYER 6 — OBSERVABILITY
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 18. mnt_activity_logs
--     "It should capture the complete Log for all the activities of the module."
--     Polymorphic, append-only. BIGINT PK — this is the highest-volume table.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_activity_logs` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `log_uuid`              CHAR(36) NOT NULL,
  `correlation_id`        CHAR(36) DEFAULT NULL,                   -- ties every log line of one run together
  -- --- Subject ---------------------------------------------------------------
  `entity_type`           ENUM('STORAGE_DESTINATION','RETENTION_POLICY','MAINTENANCE_PLAN','BACKUP_SCHEDULE','MAINTENANCE_WINDOW','BACKUP_RUN','BACKUP_RUN_ITEM','BACKUP_FILE','VERIFICATION','RESTORE_REQUEST','RESTORE_RUN','EXTENSION_REQUEST','ARCHIVE_ACCESS_REQUEST','ARCHIVE_ACCESS_SESSION','PURGE_LOG','MODULE_CONFIG','OTHER') NOT NULL,
  `entity_id`             BIGINT UNSIGNED DEFAULT NULL,
  `entity_reference`      VARCHAR(60) DEFAULT NULL,                -- run_no / request_no for human search
  `backup_run_id`         INT UNSIGNED DEFAULT NULL,               -- fast filter for "show me this run's log"
  `backup_run_item_id`    INT UNSIGNED DEFAULT NULL,
  `tenant_id`             INT UNSIGNED DEFAULT NULL,
  `tenant_code`           VARCHAR(20) DEFAULT NULL,                -- snapshot
  -- --- What happened ---------------------------------------------------------
  `action_category`       ENUM('CONFIG','SCHEDULE','BACKUP','VERIFY','REPLICATE','RESTORE','RETENTION','EXTENSION','ARCHIVE_ACCESS','PURGE','BILLING','SECURITY','NOTIFICATION','SYSTEM') NOT NULL DEFAULT 'SYSTEM',
  `action`                VARCHAR(60) NOT NULL,                    -- 'BACKUP_STARTED','EXTENSION_APPROVED','PURGE_EXECUTED'
  `stage`                 VARCHAR(60) DEFAULT NULL,                -- 'DUMPING','UPLOADING'
  `severity`              ENUM('DEBUG','INFO','NOTICE','WARNING','ERROR','CRITICAL') NOT NULL DEFAULT 'INFO',
  `outcome`               ENUM('SUCCESS','FAILURE','PARTIAL','PENDING','INFO') NOT NULL DEFAULT 'INFO',
  `message`               VARCHAR(1000) NOT NULL,
  `error_code`            VARCHAR(50) DEFAULT NULL,
  `context_json`          JSON DEFAULT NULL,                       -- sizes, paths, counts, timings
  `old_values_json`       JSON DEFAULT NULL,                       -- for config/state changes
  `new_values_json`       JSON DEFAULT NULL,
  `changed_fields_json`   JSON DEFAULT NULL,
  -- --- Actor -----------------------------------------------------------------
  `actor_type`            ENUM('USER','TENANT_USER','SYSTEM','CRON','QUEUE_WORKER','API','WEBHOOK') NOT NULL DEFAULT 'SYSTEM',
  `performed_by_user_id`  INT UNSIGNED DEFAULT NULL,
  `performed_by_name`     VARCHAR(100) DEFAULT NULL,               -- survives user deletion
  `performed_by_email`    VARCHAR(150) DEFAULT NULL,
  `impersonated_by_user_id` INT UNSIGNED DEFAULT NULL,             -- support acting as someone
  -- --- Request context -------------------------------------------------------
  `ip_address`            VARCHAR(45)  DEFAULT NULL,
  `user_agent`            VARCHAR(255) DEFAULT NULL,
  `request_id`            VARCHAR(64)  DEFAULT NULL,
  `request_method`        VARCHAR(10)  DEFAULT NULL,
  `request_url`           VARCHAR(500) DEFAULT NULL,
  `session_id`            VARCHAR(100) DEFAULT NULL,
  `queue_job_id`          VARCHAR(100) DEFAULT NULL,
  `worker_host`           VARCHAR(100) DEFAULT NULL,
  -- --- Measurements ----------------------------------------------------------
  `duration_ms`           INT UNSIGNED DEFAULT NULL,
  `bytes_affected`        BIGINT UNSIGNED DEFAULT NULL,
  `records_affected`      INT UNSIGNED DEFAULT NULL,
  `occurred_at`           DATETIME(3) NOT NULL,                    -- millisecond precision for ordering
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntActLog_logUuid`                  (`log_uuid`),
  KEY `idx_mntActLog_entityType_entityId`            (`entity_type`,`entity_id`),
  KEY `idx_mntActLog_backupRunId_occurredAt`         (`backup_run_id`,`occurred_at`),
  KEY `idx_mntActLog_tenantId_occurredAt`            (`tenant_id`,`occurred_at`),
  KEY `idx_mntActLog_actionCategory_occurredAt`      (`action_category`,`occurred_at`),
  KEY `idx_mntActLog_severity_occurredAt`            (`severity`,`occurred_at`),
  KEY `idx_mntActLog_performedByUserId`              (`performed_by_user_id`),
  KEY `idx_mntActLog_correlationId`                  (`correlation_id`),
  KEY `idx_mntActLog_occurredAt`                     (`occurred_at`),
  KEY `idx_mntActLog_entityReference`                (`entity_reference`),
  CONSTRAINT `fk_mntActLog_tenantId`       FOREIGN KEY (`tenant_id`)            REFERENCES `prm_tenant` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntActLog_backupRunId`    FOREIGN KEY (`backup_run_id`)        REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntActLog_runItemId`      FOREIGN KEY (`backup_run_item_id`)   REFERENCES `mnt_backup_run_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntActLog_performedBy`    FOREIGN KEY (`performed_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntActLog_impersonatedBy` FOREIGN KEY (`impersonated_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. APPEND-ONLY. No UPDATE, no soft delete, no `updated_at`. Any UPDATE on this
--     table is an audit-integrity violation. Enforce with a DB-level trigger or
--     a restricted grant in production.
--  2. `entity_id` is BIGINT UNSIGNED so it can hold `mnt_backup_files.id`
--     (BIGINT) as well as the INT PKs of every other table.
--  3. RETENTION OF THE LOG ITSELF: keep 24 months hot, then archive to cold
--     storage. Consider RANGE partitioning on `occurred_at` by month once the
--     table exceeds ~50M rows:
--       ALTER TABLE mnt_activity_logs PARTITION BY RANGE COLUMNS(occurred_at) (...)
--     Note: partitioning requires dropping the FKs above — evaluate the
--     trade-off at that point, do not pre-optimise now.
--  4. `correlation_id` = the parent run's `run_uuid`, so an operator can pull
--     the entire narrative of one backup with a single indexed lookup.
--  5. This table does NOT replace `sys_activity_logs`; it is module-specific and
--     far richer. Cross-module summary events may be mirrored to sys_activity_logs.


-- -----------------------------------------------------------------------------
-- 19. mnt_alert_dispatches
--     Every notification the module sends, with a dedupe key so a T-30 expiry
--     warning is never sent twice for the same backup.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_alert_dispatches` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `alert_uuid`            CHAR(36) NOT NULL,
  `dedupe_key`            VARCHAR(180) NOT NULL,                   -- e.g. 'EXPIRY_WARN:item:48211:30'
  `alert_type`            ENUM('BACKUP_STARTED','BACKUP_SUCCESS','BACKUP_FAILED','BACKUP_PARTIAL','BACKUP_MISSED','VERIFICATION_FAILED','OFFSITE_REPLICATION_FAILED','STORAGE_LOW_SPACE','STORAGE_UNREACHABLE','RETENTION_EXPIRY_WARNING','RETENTION_EXPIRED','EXTENSION_REQUESTED','EXTENSION_QUOTED','EXTENSION_APPROVED','EXTENSION_REJECTED','EXTENSION_PAYMENT_DUE','EXTENSION_APPLIED','PURGE_SCHEDULED','PURGE_COMPLETED','RESTORE_REQUESTED','RESTORE_APPROVED','RESTORE_COMPLETED','RESTORE_FAILED','ARCHIVE_ACCESS_REQUESTED','ARCHIVE_ACCESS_APPROVED','ARCHIVE_ACCESS_EXPIRING','ARCHIVE_ACCESS_REVOKED','MAINTENANCE_WINDOW_ANNOUNCED','MAINTENANCE_WINDOW_STARTING','SLA_BREACH','SUSPICIOUS_ACCESS','OTHER') NOT NULL,
  `severity`              ENUM('INFO','WARNING','ERROR','CRITICAL') NOT NULL DEFAULT 'INFO',
  `entity_type`           VARCHAR(40) DEFAULT NULL,
  `entity_id`             BIGINT UNSIGNED DEFAULT NULL,
  `entity_reference`      VARCHAR(60) DEFAULT NULL,
  `tenant_id`             INT UNSIGNED DEFAULT NULL,
  `backup_run_id`         INT UNSIGNED DEFAULT NULL,
  `backup_run_item_id`    INT UNSIGNED DEFAULT NULL,
  -- --- Delivery --------------------------------------------------------------
  `channel`               ENUM('EMAIL','SMS','WHATSAPP','IN_APP','PUSH','WEBHOOK','SLACK','TEAMS') NOT NULL DEFAULT 'EMAIL',
  `recipient_type`        ENUM('PG_ADMIN','PG_SUPPORT','TENANT_ADMIN','TENANT_USER','ROLE_GROUP','EXTERNAL','SYSTEM') NOT NULL DEFAULT 'PG_ADMIN',
  `recipient_user_id`     INT UNSIGNED DEFAULT NULL,
  `recipient_address`     VARCHAR(255) DEFAULT NULL,               -- email / mobile / webhook URL
  `recipient_name`        VARCHAR(100) DEFAULT NULL,
  `template_code`         VARCHAR(60)  DEFAULT NULL,               -- links to Template / Notification module
  `subject`               VARCHAR(255) DEFAULT NULL,
  `body_preview`          VARCHAR(500) DEFAULT NULL,               -- first 500 chars only
  `payload_json`          JSON DEFAULT NULL,                       -- merge variables used
  `notification_ref_id`   INT UNSIGNED DEFAULT NULL,               -- id in the NTF module, if routed there
  -- --- State -----------------------------------------------------------------
  `status`                ENUM('QUEUED','SENDING','SENT','DELIVERED','READ','FAILED','BOUNCED','SUPPRESSED','CANCELLED') NOT NULL DEFAULT 'QUEUED',
  `scheduled_for`         DATETIME DEFAULT NULL,
  `sent_at`               TIMESTAMP NULL DEFAULT NULL,
  `delivered_at`          TIMESTAMP NULL DEFAULT NULL,
  `read_at`               TIMESTAMP NULL DEFAULT NULL,
  `retry_count`           TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `max_retries`           TINYINT UNSIGNED NOT NULL DEFAULT 3,
  `next_retry_at`         TIMESTAMP NULL DEFAULT NULL,
  `error_message`         VARCHAR(500) DEFAULT NULL,
  `suppression_reason`    VARCHAR(255) DEFAULT NULL,               -- 'DUPLICATE','QUIET_HOURS','OPTED_OUT'
  `requires_action`       TINYINT(1) NOT NULL DEFAULT 0,           -- e.g. approve extension / pay invoice
  `action_url`            VARCHAR(500) DEFAULT NULL,
  `action_taken_at`       TIMESTAMP NULL DEFAULT NULL,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntAlert_alertUuid`               (`alert_uuid`),
  UNIQUE KEY `uq_mntAlert_dedupeKey_channel`       (`dedupe_key`,`channel`),
  KEY `idx_mntAlert_tenantId_alertType`            (`tenant_id`,`alert_type`),
  KEY `idx_mntAlert_status_scheduledFor`           (`status`,`scheduled_for`),
  KEY `idx_mntAlert_entityType_entityId`           (`entity_type`,`entity_id`),
  KEY `idx_mntAlert_backupRunId`                   (`backup_run_id`),
  KEY `idx_mntAlert_severity_createdAt`            (`severity`,`created_at`),
  KEY `idx_mntAlert_recipientUserId`               (`recipient_user_id`),
  CONSTRAINT `fk_mntAlert_tenantId`      FOREIGN KEY (`tenant_id`)          REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntAlert_backupRunId`   FOREIGN KEY (`backup_run_id`)      REFERENCES `mnt_backup_runs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntAlert_runItemId`     FOREIGN KEY (`backup_run_item_id`) REFERENCES `mnt_backup_run_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntAlert_recipientUser` FOREIGN KEY (`recipient_user_id`)  REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. `uq_mntAlert_dedupeKey_channel` is the whole point of this table: the
--     expiry-warning job can run every hour and still send each warning once.
--     Build the key as '<ALERT_TYPE>:<entity_type>:<entity_id>:<qualifier>'.
--  2. The module raises the alert here; actual delivery may be delegated to the
--     Notification (NTF) module — `notification_ref_id` links the two.
--  3. CRITICAL alerts must ignore quiet hours and always reach PG_ADMIN.


-- -----------------------------------------------------------------------------
-- 20. mnt_storage_usage_snapshots
--     Daily per-tenant storage footprint. Feeds the storage-overage invoice and
--     the "how much will my extension cost" quote.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mnt_storage_usage_snapshots` (
  `id`                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `snapshot_date`             DATE NOT NULL,
  `tenant_id`                 INT UNSIGNED DEFAULT NULL,           -- NULL = platform-level roll-up row
  `tenant_code`               VARCHAR(20) DEFAULT NULL,
  `storage_destination_id`    INT UNSIGNED DEFAULT NULL,           -- NULL = all destinations combined
  `content_type`              ENUM('DATABASE','IMAGES','VIDEOS','DOCUMENTS','AUDIO','MEDIA_ALL','CONFIG','APP_LOGS','FULL_FILESYSTEM','ALL') NOT NULL DEFAULT 'ALL',
  `storage_class`             ENUM('HOT','WARM','COLD','ARCHIVE','DEEP_ARCHIVE','ALL') NOT NULL DEFAULT 'ALL',
  -- --- Volume ----------------------------------------------------------------
  `backup_items_count`        INT UNSIGNED NOT NULL DEFAULT 0,
  `backup_files_count`        INT UNSIGNED NOT NULL DEFAULT 0,
  `total_bytes`               BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `total_gb`                  DECIMAL(14,4) GENERATED ALWAYS AS (`total_bytes` / 1073741824) STORED,
  `billable_bytes`            BIGINT UNSIGNED NOT NULL DEFAULT 0,  -- beyond included quota / under extension
  `billable_gb`               DECIMAL(14,4) GENERATED ALWAYS AS (`billable_bytes` / 1073741824) STORED,
  `extended_retention_bytes`  BIGINT UNSIGNED NOT NULL DEFAULT 0,  -- held only because of a paid extension
  `legal_hold_bytes`          BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `offsite_bytes`             BIGINT UNSIGNED NOT NULL DEFAULT 0,
  -- --- Movement --------------------------------------------------------------
  `bytes_added_today`         BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `bytes_purged_today`        BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `net_change_bytes`          BIGINT DEFAULT NULL,                 -- signed
  `growth_percent`            DECIMAL(8,3) DEFAULT NULL,
  -- --- Retention profile -----------------------------------------------------
  `oldest_backup_date`        DATE DEFAULT NULL,
  `newest_backup_date`        DATE DEFAULT NULL,
  `earliest_expiry_date`      DATE DEFAULT NULL,
  `items_expiring_in_30_days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `items_on_legal_hold`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  -- --- Billing linkage -------------------------------------------------------
  `included_quota_gb`         INT UNSIGNED NOT NULL DEFAULT 0,
  `overage_gb`                DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  `estimated_cost`            DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `currency`                  CHAR(3) NOT NULL DEFAULT 'INR',
  `is_billed`                 TINYINT(1) NOT NULL DEFAULT 0,
  `tenant_invoice_id`         INT UNSIGNED DEFAULT NULL,
  `computed_at`               TIMESTAMP NULL DEFAULT NULL,
  `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_mntUsage_date_tenant_dest_content_class` (`snapshot_date`,`tenant_id`,`storage_destination_id`,`content_type`,`storage_class`),
  KEY `idx_mntUsage_tenantId_snapshotDate`  (`tenant_id`,`snapshot_date`),
  KEY `idx_mntUsage_snapshotDate`           (`snapshot_date`),
  KEY `idx_mntUsage_isBilled`               (`is_billed`),
  KEY `idx_mntUsage_invoiceId`              (`tenant_invoice_id`),
  CONSTRAINT `fk_mntUsage_tenantId`      FOREIGN KEY (`tenant_id`)              REFERENCES `prm_tenant` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mntUsage_storageDestId` FOREIGN KEY (`storage_destination_id`) REFERENCES `mnt_storage_destinations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mntUsage_invoiceId`     FOREIGN KEY (`tenant_invoice_id`)      REFERENCES `bil_tenant_invoices` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
--  1. Written once daily by StorageUsageSnapshotJob AFTER the purge job, so the
--     figure reflects end-of-day reality.
--  2. GB-month billing = AVG(billable_gb) over the billing period, not the peak
--     and not the last day. That is why a DAILY row is required.
--  3. NULL tenant_id / NULL storage_destination_id rows are roll-ups; always
--     filter explicitly to avoid double counting.
--  4. `net_change_bytes` is a signed BIGINT (not UNSIGNED) — it is negative on
--     heavy purge days.


-- =============================================================================
-- DEFERRED FOREIGN KEYS
-- Added after all tables exist, to keep the CREATE order free of cycles.
-- =============================================================================

ALTER TABLE `mnt_backup_schedules`
  ADD CONSTRAINT `fk_mntSchedule_lastRunId`
      FOREIGN KEY (`last_run_id`) REFERENCES `mnt_backup_runs` (`id`) ON DELETE SET NULL;

ALTER TABLE `mnt_backup_run_items`
  ADD CONSTRAINT `fk_mntRunItems_lastExtReqId`
      FOREIGN KEY (`last_extension_request_id`) REFERENCES `mnt_retention_extension_requests` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_mntRunItems_purgeLogId`
      FOREIGN KEY (`purge_log_id`) REFERENCES `mnt_purge_logs` (`id`) ON DELETE SET NULL;

ALTER TABLE `mnt_backup_files`
  ADD CONSTRAINT `fk_mntBackupFiles_purgeLogId`
      FOREIGN KEY (`purge_log_id`) REFERENCES `mnt_purge_logs` (`id`) ON DELETE SET NULL;


-- =============================================================================
-- REPORTING VIEWS (optional but recommended — the UI reads these)
-- =============================================================================

-- Backup History grid: one row per backup, tenant-readable.
CREATE OR REPLACE VIEW `v_mnt_backup_history` AS
SELECT
    i.`id`                        AS backup_item_id,
    i.`item_uuid`,
    r.`run_no`,
    r.`name`                      AS run_name,
    i.`tenant_id`,
    i.`tenant_code`,
    i.`tenant_name`,
    i.`database_name`,
    i.`content_type`,
    i.`backup_type`,
    r.`trigger_type`,
    i.`status`,
    i.`storage_path`,
    i.`primary_file_name`,
    i.`file_count`,
    i.`stored_size_bytes`,
    ROUND(i.`stored_size_bytes` / 1073741824, 4) AS stored_size_gb,
    i.`started_at`,
    i.`completed_at`,
    i.`duration_seconds`,
    i.`verification_status`,
    i.`is_restorable`,
    i.`has_offsite_copy`,
    i.`storage_class`,
    i.`retention_start_date`,
    i.`original_retention_end_date`,
    i.`retention_end_date`,
    i.`grace_end_date`,
    DATEDIFF(i.`retention_end_date`, CURDATE()) AS days_to_expiry,
    i.`extension_count`,
    i.`total_extended_days`,
    i.`is_legal_hold`,
    i.`purge_status`,
    i.`purged_at`,
    r.`triggered_by`,
    r.`triggered_by_name`,
    r.`triggered_by_type`,
    r.`requested_at`
FROM `mnt_backup_run_items` i
JOIN `mnt_backup_runs` r ON r.`id` = i.`backup_run_id`
WHERE i.`deleted_at` IS NULL;

-- Purge queue: what the retention job will act on next.
CREATE OR REPLACE VIEW `v_mnt_purge_candidates` AS
SELECT
    i.`id` AS backup_item_id,
    i.`tenant_id`,
    i.`tenant_code`,
    i.`content_type`,
    i.`retention_end_date`,
    i.`grace_end_date`,
    i.`stored_size_bytes`,
    i.`purge_status`,
    i.`storage_destination_id`,
    DATEDIFF(CURDATE(), i.`grace_end_date`) AS days_past_grace
FROM `mnt_backup_run_items` i
WHERE i.`deleted_at`   IS NULL
  AND i.`purge_status` NOT IN ('PURGED','ON_HOLD','PENDING_APPROVAL')
  AND i.`is_legal_hold` = 0
  AND i.`is_locked`     = 0
  AND i.`grace_end_date` IS NOT NULL
  AND i.`grace_end_date` < CURDATE()
  AND NOT EXISTS (SELECT 1 FROM `mnt_backup_run_items` c
                   WHERE c.`parent_item_id` = i.`id` AND c.`purge_status` <> 'PURGED')
  AND NOT EXISTS (SELECT 1 FROM `mnt_archive_access_sessions` s
                   WHERE s.`backup_run_item_id` = i.`id`
                     AND s.`status` IN ('PROVISIONING','ACTIVE','IDLE'));


-- =============================================================================
-- SEED DATA (minimum viable configuration)
-- =============================================================================

INSERT INTO `mnt_retention_policies`
  (`code`,`short_name`,`name`,`description`,`keep_daily_days`,`keep_weekly_weeks`,`keep_monthly_months`,`keep_yearly_years`,
   `default_retention_days`,`min_retention_days`,`grace_period_days`,`allow_extension`,`extension_is_chargeable`,
   `extension_rate_per_gb_month`,`extension_flat_fee_month`,`extension_tax_percent`,`is_system_defined`,`created_at`)
VALUES
  ('TRIAL_30D','Trial 30D','Trial — 30 Days Retention','For trial tenants',7,2,1,0,30,7,3,1,1,5.0000,0.00,18.00,1,NOW()),
  ('STD_90D','Standard 90D','Standard — 90 Days Retention','Default plan for paid tenants',7,4,3,1,90,30,7,1,1,4.0000,0.00,18.00,1,NOW()),
  ('GOLD_365D','Gold 1Y','Gold — 1 Year Retention','Premium tenants',14,8,12,2,365,90,15,1,1,3.0000,0.00,18.00,1,NOW()),
  ('STATUTORY_7Y','Statutory 7Y','Statutory — 7 Year Retention','Board/affiliation record keeping',30,12,24,7,2555,1825,30,1,0,0.0000,0.00,18.00,1,NOW());


-- =============================================================================
-- CHANGE LOG
-- =============================================================================
-- v2.0 | 2026-07-27
--   * Fixed 4 hard SQL errors carried in v1 (see EVALUATION section A).
--   * Retargeted from `global_db` to `prime_db` (control-plane placement).
--   * 3 tables -> 20 tables across 6 layers.
--   * Added retention model end-to-end: policy -> per-item end date ->
--     expiry warning -> paid extension -> grace -> approval -> purge -> evidence.
--   * Added restore (request + approval + execution + rollback), verification,
--     archive-access sessions, activity log, alert dedupe and usage snapshots.
--   * All PKs INT UNSIGNED to match prime_db; BIGINT UNSIGNED only on the four
--     high-volume tables (mnt_backup_files, mnt_activity_logs,
--     mnt_alert_dispatches, mnt_storage_usage_snapshots).
--   * Audit columns (is_active / created_by / updated_by / deleted_at) added
--     everywhere except the append-only log tables — documented exception.
--
-- v1.0 | 2026-07-24
--   * Initial draft: mnt_backup_schedules, mnt_backup_runs,
--     mnt_tenant_archive_access_requests.
--   * mnt_backup_runs.status: extended the ENUM.
-- =============================================================================
