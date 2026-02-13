/* =========================================================
   NOTIFICATION MODULE — ENHANCED MASTER DDL
   Compatible with MySQL 8.x
   Tenant DB Level with Multi-Tenant Support
   ========================================================= */

SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- TABLE: ntf_channel_master
-- Purpose: Defines available notification channels
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_channel_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL COMMENT 'Multi-tenant isolation',
    `code` VARCHAR(20) NOT NULL COMMENT 'EMAIL, SMS, WHATSAPP, IN_APP, PUSH',
    `name` VARCHAR(50) NOT NULL COMMENT 'Display name',
    `description` VARCHAR(255) NULL,
    `channel_type` ENUM('IMMEDIATE', 'BULK', 'TRANSACTIONAL') DEFAULT 'TRANSACTIONAL',
    `priority_order` TINYINT DEFAULT 5 COMMENT '1-Highest, 10-Lowest',
    `max_retry` INT DEFAULT 3,
    `retry_delay_minutes` INT DEFAULT 5,
    `rate_limit_per_minute` INT DEFAULT 100,
    `daily_limit` INT DEFAULT 10000,
    `monthly_limit` INT DEFAULT 100000,
    `cost_per_unit` DECIMAL(10,4) DEFAULT 0.0000,
    `fallback_channel_id` INT UNSIGNED NULL COMMENT 'Auto-fallback on failure',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_channel_tenant` (`tenant_id`),
    INDEX `idx_ntf_channel_code` (`code`),
    CONSTRAINT `uq_ntf_channel_tenant_code` UNIQUE (`tenant_id`, `code`),
    CONSTRAINT `fk_ntf_channel_fallback` FOREIGN KEY (`fallback_channel_id`) REFERENCES `ntf_channel_master`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- =========================================================
-- TABLE: ntf_provider_master
-- Purpose: External service providers configuration
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_provider_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `provider_name` VARCHAR(50) NOT NULL COMMENT 'Twilio, MSG91, AWS SES, Meta, Firebase',
    `provider_type` ENUM('PRIMARY', 'SECONDARY', 'BACKUP') DEFAULT 'PRIMARY',
    `api_endpoint` VARCHAR(500) NULL,
    `api_key_encrypted` TEXT NULL COMMENT 'Encrypted API credentials',
    `api_secret_encrypted` TEXT NULL,
    `from_address` VARCHAR(255) NULL COMMENT 'Sender email/phone/ID',
    `configuration` JSON NULL COMMENT 'Provider-specific config',
    `priority` TINYINT DEFAULT 5 COMMENT '1-Highest, 10-Lowest',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_provider_channel` (`channel_id`),
    CONSTRAINT `fk_ntf_provider_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_notifications
-- Purpose: Core notification request registry
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_notifications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `notification_uuid` CHAR(36) NOT NULL COMMENT 'Public-facing unique ID',
    `source_module` VARCHAR(50) NOT NULL,
    `source_record_id` INT UNSIGNED NULL COMMENT 'ID in source module',
    `notification_event` VARCHAR(50) NOT NULL,
    `notification_type` ENUM('TRANSACTIONAL', 'PROMOTIONAL', 'ALERT', 'REMINDER', 'DIGEST') DEFAULT 'TRANSACTIONAL',
    `title` VARCHAR(255) NOT NULL,
    `description` VARCHAR(512) NULL,
    `template_id` INT UNSIGNED NULL,
    `priority_id` INT UNSIGNED NOT NULL,
    `confidentiality_level_id` INT UNSIGNED NOT NULL,
    -- Scheduling
    `schedule_type` ENUM('IMMEDIATE', 'SCHEDULED', 'RECURRING', 'TRIGGERED') DEFAULT 'IMMEDIATE',
    `scheduled_at` DATETIME NULL,
    `schedule_timezone` VARCHAR(50) DEFAULT 'UTC',
    -- Recurring
    `recurring_pattern` ENUM('NONE', 'HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM') DEFAULT 'NONE',
    `recurring_expression` VARCHAR(100) NULL COMMENT 'Cron expression or RRULE',
    `recurring_end_at` DATETIME NULL,
    `recurring_end_count` INT NULL,
    `recurring_executed_count` INT DEFAULT 0 COMMENT 'Calculated',
    -- Expiry
    `expires_at` DATETIME NULL,
    -- Tracking
    `total_recipients` INT DEFAULT 0 COMMENT 'Calculated from ntf_resolved_recipients',
    `sent_count` INT DEFAULT 0 COMMENT 'Calculated',
    `failed_count` INT DEFAULT 0 COMMENT 'Calculated',
    `delivered_count` INT DEFAULT 0 COMMENT 'Calculated',
    `read_count` INT DEFAULT 0 COMMENT 'Calculated',
    `click_count` INT DEFAULT 0 COMMENT 'Calculated',
    -- Cost
    `estimated_cost` DECIMAL(12,4) DEFAULT 0.0000 COMMENT 'Calculated',
    `actual_cost` DECIMAL(12,4) DEFAULT 0.0000 COMMENT 'Calculated',
    -- Status
    `notification_status_id` INT UNSIGNED NOT NULL COMMENT 'DRAFT, SCHEDULED, PROCESSING, COMPLETED, PARTIAL, FAILED, CANCELLED, EXPIRED',
    `is_manual` TINYINT(1) DEFAULT 0 COMMENT 'Manually created',
    `created_by` INT UNSIGNED NOT NULL,
    `approved_by` INT UNSIGNED NULL,
    `approved_at` DATETIME NULL,
    `processed_at` DATETIME NULL,
    `completed_at` DATETIME NULL,
    -- Audit
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_tenant` (`tenant_id`),
    INDEX `idx_ntf_schedule` (`scheduled_at`, `notification_status_id`),
    INDEX `idx_ntf_source` (`source_module`, `source_record_id`),
    INDEX `idx_ntf_uuid` (`notification_uuid`),
    INDEX `idx_ntf_status` (`notification_status_id`),
    INDEX `idx_ntf_event` (`notification_event`),
    CONSTRAINT `fk_ntf_priority` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_confidentiality` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
    CONSTRAINT `fk_ntf_notification_status` FOREIGN KEY (`notification_status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_notification_channels
-- Purpose: Channel assignments per notification
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_notification_channels` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `provider_id` INT UNSIGNED NULL,
    `template_id` INT UNSIGNED NULL COMMENT 'Override template',
    `priority_order` TINYINT DEFAULT 5,
    `sending_order` INT DEFAULT 1 COMMENT 'Sequence for fallback',
    `status_id` INT UNSIGNED NOT NULL,
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
    INDEX `idx_ntf_channel_retry` (`next_retry_at`, `retry_count`),
    CONSTRAINT `fk_ntf_channel_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_channel_type` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_channel_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`),
    CONSTRAINT `fk_ntf_channel_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
    CONSTRAINT `fk_ntf_channel_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_target_groups
-- Purpose: Reusable user segments/target groups
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_target_groups` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `group_name` VARCHAR(100) NOT NULL,
    `group_code` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255) NULL,
    `group_type` ENUM('STATIC', 'DYNAMIC') DEFAULT 'STATIC',
    `dynamic_query` TEXT NULL COMMENT 'JSON/SQL for dynamic groups',
    `total_members` INT DEFAULT 0 COMMENT 'Calculated',
    `last_refreshed_at` DATETIME NULL,
    `is_system_group` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_by` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    UNIQUE KEY `uq_target_group_tenant_code` (`tenant_id`, `group_code`),
    INDEX `idx_target_group_type` (`group_type`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_notification_targets
-- Purpose: Target definitions for notifications
-- =========================================================
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
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_user_devices
-- Purpose: Push notification device registry
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_user_devices` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `device_type` ENUM('ANDROID', 'IOS', 'WEB', 'DESKTOP') NOT NULL,
    `device_token` VARCHAR(512) NOT NULL,
    `device_name` VARCHAR(100) NULL,
    `app_version` VARCHAR(20) NULL,
    `os_version` VARCHAR(20) NULL,
    `last_active_at` DATETIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uq_user_device_token` (`user_id`, `device_token`),
    INDEX `idx_device_token` (`device_token`),
    CONSTRAINT `fk_ntf_device_user` FOREIGN KEY (`user_id`) REFERENCES `sys_user`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_user_preferences
-- Purpose: Enhanced user notification preferences
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_user_preferences` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `is_enabled` TINYINT(1) DEFAULT 1,
    `is_opted_in` TINYINT(1) DEFAULT 1 COMMENT 'GDPR consent',
    `opted_in_at` DATETIME NULL,
    `opted_out_at` DATETIME NULL,
    `contact_value` VARCHAR(255) NULL COMMENT 'Override email/phone',
    `quiet_hours_start` TIME NULL,
    `quiet_hours_end` TIME NULL,
    `quiet_hours_timezone` VARCHAR(50) DEFAULT 'UTC',
    `daily_digest` TINYINT(1) DEFAULT 0,
    `digest_time` TIME NULL,
    `priority_threshold_id` INT UNSIGNED NULL COMMENT 'Min priority to receive',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    UNIQUE KEY `uq_user_channel` (`user_id`, `channel_id`),
    INDEX `idx_pref_user` (`user_id`, `is_enabled`),
    
    CONSTRAINT `fk_ntf_pref_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_pref_priority` FOREIGN KEY (`priority_threshold_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_templates
-- Purpose: Enhanced notification templates
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_templates` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
    `template_code` VARCHAR(50) NOT NULL,
    `template_name` VARCHAR(100) NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `template_version` INT DEFAULT 1,
    `subject` VARCHAR(255) NULL,
    `body` TEXT NOT NULL,
    `alt_body` TEXT NULL COMMENT 'Plain text version',
    `placeholders` JSON NULL COMMENT 'List of required placeholders',
    `language_code` VARCHAR(10) DEFAULT 'en',
    `media_id` INT UNSIGNED NULL,
    `is_system_template` TINYINT(1) DEFAULT 0,
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
    
    UNIQUE KEY `uq_template_code_version` (`tenant_id`, `template_code`, `template_version`),
    INDEX `idx_template_channel` (`channel_id`),
    INDEX `idx_template_status` (`approval_status`),
    
    CONSTRAINT `fk_ntf_template_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_template_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_resolved_recipients
-- Purpose: Final resolved recipient list with personalization
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_resolved_recipients` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `template_id` INT UNSIGNED NOT NULL,
    `notification_target_id` INT UNSIGNED NOT NULL,
    `user_preference_id` INT UNSIGNED NULL,
    `resolved_user_id` INT UNSIGNED NOT NULL,
    `device_id` INT UNSIGNED NULL COMMENT 'For push notifications',
    `recipient_address` VARCHAR(255) NULL COMMENT 'Resolved email/phone/ID',
    `personalized_subject` VARCHAR(500) NULL COMMENT 'Rendered with placeholders',
    `personalized_body` TEXT NULL COMMENT 'Rendered with placeholders',
    `personalization_data` JSON NULL COMMENT 'Placeholder values used',
    `priority` TINYINT DEFAULT 5,
    `batch_id` VARCHAR(36) NULL COMMENT 'For bulk processing',
    `batch_sequence` INT NULL,
    `is_processed` TINYINT(1) DEFAULT 0,
    `processed_at` DATETIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    
    INDEX `idx_ntf_recipient_notification` (`notification_id`, `is_processed`),
    INDEX `idx_ntf_recipient_user` (`resolved_user_id`),
    INDEX `idx_ntf_recipient_batch` (`batch_id`),
    INDEX `idx_ntf_recipient_address` (`recipient_address`),
    
    CONSTRAINT `fk_ntf_recipient_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_recipient_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_recipient_template` FOREIGN KEY (`template_id`) REFERENCES `ntf_templates`(`id`),
    CONSTRAINT `fk_ntf_recipient_preference` FOREIGN KEY (`user_preference_id`) REFERENCES `ntf_user_preferences`(`id`),
    CONSTRAINT `fk_ntf_recipient_target` FOREIGN KEY (`notification_target_id`) REFERENCES `ntf_notification_targets`(`id`),
    CONSTRAINT `fk_ntf_recipient_user` FOREIGN KEY (`resolved_user_id`) REFERENCES `sys_user`(`id`),
    CONSTRAINT `fk_ntf_recipient_device` FOREIGN KEY (`device_id`) REFERENCES `ntf_user_devices`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_delivery_queue
-- Purpose: Queue management for notification sending
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_delivery_queue` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `resolved_recipient_id` INT UNSIGNED NOT NULL,
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
    INDEX `idx_queue_next_attempt` (`next_attempt_at`),
    INDEX `idx_queue_lock` (`locked_by`, `locked_at`),
    
    CONSTRAINT `fk_queue_recipient` FOREIGN KEY (`resolved_recipient_id`) REFERENCES `ntf_resolved_recipients`(`id`),
    CONSTRAINT `fk_queue_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_queue_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_queue_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_delivery_logs
-- Purpose: Complete delivery audit trail
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_delivery_logs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `channel_id` INT UNSIGNED NOT NULL,
    `resolved_recipient_id` INT UNSIGNED NOT NULL,
    `resolved_user_id` INT UNSIGNED NOT NULL,
    `provider_id` INT UNSIGNED NOT NULL,
    `delivery_status_id` INT UNSIGNED NOT NULL,
    `delivery_stage` ENUM('QUEUED', 'SENT', 'DELIVERED', 'READ', 'CLICKED', 'BOUNCED', 'COMPLAINT', 'UNSUBSCRIBED') DEFAULT 'SENT',
    `provider_message_id` VARCHAR(255) NULL,
    `delivered_at` DATETIME NULL,
    `read_at` DATETIME NULL,
    `clicked_at` DATETIME NULL,
    `bounced_at` DATETIME NULL,
    `complaint_at` DATETIME NULL,
    `response_code` VARCHAR(20) NULL,
    `response_payload` JSON NULL,
    `error_message` VARCHAR(512) NULL,
    `duration_ms` INT NULL COMMENT 'Delivery latency',
    `ip_address` VARCHAR(45) NULL COMMENT 'For read/click tracking',
    `user_agent` VARCHAR(255) NULL,
    `cost` DECIMAL(12,4) DEFAULT 0.0000,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_ntf_delivery_user` (`resolved_user_id`),
    INDEX `idx_ntf_delivery_status` (`delivery_status_id`, `delivery_stage`),
    INDEX `idx_ntf_delivery_provider_msg` (`provider_message_id`),
    INDEX `idx_ntf_delivery_notification` (`notification_id`),
    INDEX `idx_ntf_delivery_recipient` (`resolved_recipient_id`),
    INDEX `idx_ntf_delivery_timeline` (`delivered_at`, `read_at`, `clicked_at`),
    
    CONSTRAINT `fk_ntf_log_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_log_channel` FOREIGN KEY (`channel_id`) REFERENCES `ntf_channel_master`(`id`),
    CONSTRAINT `fk_ntf_log_recipient` FOREIGN KEY (`resolved_recipient_id`) REFERENCES `ntf_resolved_recipients`(`id`),
    CONSTRAINT `fk_ntf_log_provider` FOREIGN KEY (`provider_id`) REFERENCES `ntf_provider_master`(`id`),
    CONSTRAINT `fk_ntf_log_status` FOREIGN KEY (`delivery_status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_notification_threads
-- Purpose: Group related notifications (conversations)
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_notification_threads` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `tenant_id` INT UNSIGNED NOT NULL,
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
    
    INDEX `idx_thread_uuid` (`thread_uuid`),
    INDEX `idx_thread_parent` (`parent_thread_id`),
    
    CONSTRAINT `fk_thread_parent` FOREIGN KEY (`parent_thread_id`) REFERENCES `ntf_notification_threads`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_notification_thread_members
-- Purpose: Thread-notification association
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_notification_thread_members` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `thread_id` INT UNSIGNED NOT NULL,
    `notification_id` INT UNSIGNED NOT NULL,
    `sequence_order` INT DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uq_thread_notification` (`thread_id`, `notification_id`),
    CONSTRAINT `fk_thread_member_thread` FOREIGN KEY (`thread_id`) REFERENCES `ntf_notification_threads`(`id`),
    CONSTRAINT `fk_thread_member_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =========================================================
-- TABLE: ntf_schedule_audit
-- Purpose: Track recurring notification executions
-- =========================================================
CREATE TABLE IF NOT EXISTS `ntf_schedule_audit` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` INT UNSIGNED NOT NULL,
    `scheduled_instance_id` INT UNSIGNED NULL COMMENT 'Child notification ID',
    `scheduled_execution_time` DATETIME NOT NULL,
    `actual_execution_time` DATETIME NULL,
    `execution_status` ENUM('PENDING', 'SUCCESS', 'FAILED', 'SKIPPED') DEFAULT 'PENDING',
    `error_message` VARCHAR(512) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_schedule_notification` (`notification_id`, `scheduled_execution_time`),
    CONSTRAINT `fk_schedule_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;