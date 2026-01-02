/* =========================================================
   NOTIFICATION MODULE — MASTER DDL
   Compatible with MySQL 8.x
   Tenant DB Level
   ========================================================= */

SET FOREIGN_KEY_CHECKS = 0;

/* =========================================================
   1. NOTIFICATION MASTER
   ========================================================= */
CREATE TABLE IF NOT EXISTS ntf_notifications (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `source_module` VARCHAR(50) NOT NULL,     -- Triggering module: Exam, Fee, Transport, Complaint etc
    `notification_event` VARCHAR(50) NOT NULL, -- Triggering event: Student Registered, Student Promoted, Exam Result Published, Fee Payment Reminder etc
    `title` VARCHAR(255) NOT NULL,             -- Notification title
    `description` VARCHAR(512) NULL,           -- Notification description
    `template_id` BIGINT UNSIGNED NULL,        -- Template ID
    `priority_id` BIGINT UNSIGNED NOT NULL,    -- 'LOW, NORMAL, HIGH, URGENT'
    `confidentiality_level_id` BIGINT UNSIGNED NOT NULL, -- 'PUBLIC, RESTRICTED, CONFIDENTIAL'
    `scheduled_at` DATETIME NULL,
    `recurring` TINYINT(1) DEFAULT 0,             -- 0: One Time, 1: Recurring
    `recurring_interval_id` BIGINT UNSIGNED NULL, -- fk to sys_dropdown_table e.g. 'HOURLY, DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY'
    `recurring_end_at` DATETIME NULL,             -- End date or time for recurring notifications
    `recurring_end_count` INT NULL,               -- End count for recurring notifications
    `expires_at` DATETIME NULL,                   -- Expiry date or time for notifications
    `created_by` BIGINT UNSIGNED NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_schedule` (`scheduled_at`),
    INDEX `idx_ntf_source` (`source_module`),
    CONSTRAINT `fk_ntf_priority` FOREIGN KEY (`priority_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_confidentiality` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_recurring_interval` FOREIGN KEY (`recurring_interval_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* =========================================================
   2. NOTIFICATION CHANNELS
   ========================================================= */
CREATE TABLE IF NOT EXISTS ntf_notification_channels (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` BIGINT UNSIGNED NOT NULL,
    `channel_id` BIGINT UNSIGNED NOT NULL,    -- fk to sys_dropdown_table e.g. 'APP, SMS, WHATSAPP, EMAIL'
    `provider_id` BIGINT UNSIGNED NULL,       -- fk to sys_dropdown_table e.g. 'MSG91, Twilio, AWS SES, Meta API'
    `status_id` BIGINT UNSIGNED NOT NULL,     -- fk to sys_dropdown_table e.g. 'PENDING, SENT, FAILED, RETRIED'
    `scheduled_at` DATETIME NULL,
    `sent_at` DATETIME NULL,
    `failure_reason` VARCHAR(512) NULL,
    `retry_count` INT DEFAULT 0,
    `max_retry` INT DEFAULT 3,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_notification_channel` (`notification_id`, `channel_id`),
    INDEX `idx_ntf_channel_status` (`status_id`),
    INDEX `idx_ntf_channel_scheduled_at` (`scheduled_at`),
    CONSTRAINT `fk_ntf_channel_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_channel_type` FOREIGN KEY (`channel_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_channel_provider` FOREIGN KEY (`provider_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_channel_status` FOREIGN KEY (`status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/* =========================================================
   3. NOTIFICATION TARGETING
   ========================================================= */
CREATE TABLE IF NOT EXISTS ntf_notification_targets (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` BIGINT UNSIGNED NOT NULL,
    `target_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table e.g. USER, ROLE, DEPARTMENT, DESIGNATION, CLASS, SECTION, SUBJECT, ENTITY_GROUP, ENTIRE_SCHOOL
    `target_table_name` VARCHAR(60) DEFAULT NULL, -- e.g. sys_user, sys_role, sch_department, sch_designation, sch_classes, sch_sections, sch_subjects, sch_entity_groups, sch_staff_groups
    `target_selected_id` BIGINT UNSIGNED NULL, -- Reference ID based on target type e.g. user_id, role_id, designation_id, etc.
    `resolved_user_id` BIGINT UNSIGNED NULL, -- Final resolved recipient
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_target_lookup` (`target_type_id`, `target_selected_id`),
    INDEX `idx_ntf_target_user` (`resolved_user_id`),
    CONSTRAINT `fk_ntf_target_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_target_type` FOREIGN KEY (`target_type_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/* =========================================================
   4. USER NOTIFICATION PREFERENCES
   ========================================================= */
CREATE TABLE IF NOT EXISTS ntf_user_preferences (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `channel_id` BIGINT UNSIGNED NOT NULL, -- 'APP, SMS, WHATSAPP, EMAIL'
    `is_enabled` TINYINT(1) DEFAULT 1,
    `quiet_hours_start` TIME NULL,
    `quiet_hours_end` TIME NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_user_channel` (`user_id`, `channel_id`),
    CONSTRAINT `fk_ntf_pref_channel` FOREIGN KEY (`channel_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/* =========================================================
   5. NOTIFICATION TEMPLATES
   ========================================================= */
CREATE TABLE IF NOT EXISTS ntf_templates (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `template_code` VARCHAR(50) NOT NULL,
    `channel_id` BIGINT UNSIGNED NOT NULL,
    `subject` VARCHAR(255) NULL, -- 'Used for Email'
    `body` TEXT NOT NULL, -- 'Supports {{placeholders}}'
    `language_code` VARCHAR(10) DEFAULT 'en',
    `media_id` BIGINT UNSIGNED NULL,
    `is_system_template` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_template_code_channel` (`template_code`, `channel_id`),
    CONSTRAINT `fk_ntf_template_channel` FOREIGN KEY (`channel_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_template_media` FOREIGN KEY (`media_id`) REFERENCES `sys_media`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


/* =========================================================
   6. NOTIFICATION DELIVERY LOGS
   ========================================================= */
CREATE TABLE IF NOT EXISTS ntf_delivery_logs (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `notification_id` BIGINT UNSIGNED NOT NULL,
    `channel_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `delivery_status_id` BIGINT UNSIGNED NOT NULL, -- 'SENT, FAILED, READ, CLICKED'
    `delivered_at` DATETIME NULL,
    `read_at` DATETIME NULL,
    `response_payload` JSON NULL, -- 'Provider response'
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_ntf_delivery_user` (`user_id`),
    INDEX `idx_ntf_delivery_status` (`delivery_status_id`),
    CONSTRAINT `fk_ntf_log_notification` FOREIGN KEY (`notification_id`) REFERENCES `ntf_notifications`(`id`),
    CONSTRAINT `fk_ntf_log_channel` FOREIGN KEY (`channel_id`) REFERENCES `sys_dropdown_table`(`id`),
    CONSTRAINT `fk_ntf_log_status` FOREIGN KEY (`delivery_status_id`) REFERENCES `sys_dropdown_table`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

