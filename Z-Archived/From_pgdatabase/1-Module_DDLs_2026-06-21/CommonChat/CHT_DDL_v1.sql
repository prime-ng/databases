-- ==================================================================================================================================================
-- CommonChat Module (CHT) — Tenant Database Schema
-- Table Prefix : cht_
-- Scope        : tenant_db (per-school isolated, NOT prime_db)
-- Version      : v1.0
-- Date         : 2026-05-14
-- Requirement  : CHT_Requirements_v1.md
-- ==================================================================================================================================================
--
-- SECTION 0: Conventions
--   - All PKs          : BIGINT UNSIGNED AUTO_INCREMENT
--   - All FKs          : BIGINT UNSIGNED
--   - All tables       : InnoDB, utf8mb4_unicode_ci
--   - Standard columns : is_active, created_by, updated_by,
--                        created_at, updated_at, deleted_at
--   - Junction tables  : suffixed _jnt (none in this module)
--   - JSON columns     : suffixed _json
--
-- SECTION 1: cht_settings         (school-level config, 1 row)
-- SECTION 2: cht_user_settings    (per-user preferences)
-- SECTION 3: cht_user_presence    (online status, upsert pattern)
-- SECTION 4: cht_conversations    (conversation header; DM + Group + Announcement)
-- SECTION 5: cht_participants     (who is in each conversation)
-- SECTION 6: cht_messages         (individual messages)
-- SECTION 7: cht_message_receipts (read receipts, per-message per-recipient)
-- SECTION 8: cht_attachments      (file metadata for message attachments)
-- ==================================================================================================================================================

-- ==================================================================================================================================================
-- PURPOSE: This table will controls which role-pairs can message each other and sets attachment/retention limits.
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_settings` (
    `id`                            TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `max_group_members`             SMALLINT UNSIGNED NOT NULL DEFAULT 100,  -- Number of participants (including creator) allowed in a group chat. Enforced at service layer with a hard upper limit of 500.
    `max_file_attachment_size_mb`   TINYINT UNSIGNED NOT NULL DEFAULT 10,  -- 10 MB default, configurable by school admin. Enforced at service layer and re-validated at file upload.
    `max_audio_attachment_size_mb`  TINYINT UNSIGNED NOT NULL DEFAULT 10,  -- 10 MB default, configurable by school admin. Enforced at service layer and re-validated at file upload.
    `max_video_attachment_size_mb`  TINYINT UNSIGNED NOT NULL DEFAULT 10,  -- 10 MB default, configurable by school admin. Enforced at service layer and re-validated at file upload.
    `message_retention_days`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,  -- 0 means keep messages indefinitely; otherwise, messages older than this many days will be automatically purged by a scheduled job.
    `default_typing_indicator_enabled` TINYINT(1) NOT NULL DEFAULT 1,  -- When 1, the client shows typing indicators via polling; can be disabled if the school has performance issues with the polling mechanism for typing indicators.
    -- default setting for 'permission_config'
    `default_read_receipt_enabled`  TINYINT(1) NOT NULL DEFAULT 1,  -- When 1, the UI shows read receipts based on cht_message_receipts. When 0, receipts are still tracked in the DB but not displayed in the UI.
    `default_show_online_status`    TINYINT(1) NOT NULL DEFAULT 1,  -- Privacy setting: when 0, user appears Offline to others regardless of actual cht_user_presence.last_seen_at value.
    `default_notify_on_new_message` TINYINT(1) NOT NULL DEFAULT 1,  -- When 0, no in-app notifications for new chat messages (still increments unread counts in non-muted conversations).
    `default_notify_on_mention`     TINYINT(1) NOT NULL DEFAULT 1,  -- When 1, user receives a notification when @mentioned in a group message.
    `show_message_preview_in_notif` TINYINT(1) NOT NULL DEFAULT 1,  -- When 0, notification shows only "New message" without body preview. Privacy option for users sharing devices.
    -- default setting for 'permission_config'
    `can_text_chat`                 TINYINT(1) NOT NULL DEFAULT 0,  -- whether text messaging is allowed between the specified role pairs.
    `can_send_attachment`           TINYINT(1) NOT NULL DEFAULT 1,  -- whether sending attachments is allowed between the specified role pairs.
    `can_send_audio`                TINYINT(1) NOT NULL DEFAULT 0,  -- whether sending audio messages is allowed between the specified role pairs.
    `can_send_video`                TINYINT(1) NOT NULL DEFAULT 0,  -- whether sending video messages is allowed between the specified role pairs.
    `can_send_url`                  TINYINT(1) NOT NULL DEFAULT 0,  -- whether sending URL links is allowed between the specified role pairs.
    `can_send_emoji`                TINYINT(1) NOT NULL DEFAULT 1,  -- whether sending emojis is allowed between the specified role pairs.
    `can_create_group`              TINYINT(1) NOT NULL DEFAULT 0,  -- whether users with the allowed role can create group conversations with the specified role.
    `can_create_announcement`       TINYINT(1) NOT NULL DEFAULT 0,  -- whether users with the allowed role can create announcement conversations with the specified role.
    `can_message_anyone`            TINYINT(1) NOT NULL DEFAULT 0,  -- if 1, users with the allowed role can message any other user regardless of the Role_whom_can_be_chat_with setting. This overrides the role-based
    `read_receipt_enabled`          TINYINT(1) NOT NULL DEFAULT 1,  -- This will override the default setting. When 1, the UI shows read receipts based on cht_message_receipts. When 0, receipts are still tracked in the DB but not displayed in the UI.
    -- Standard audit columns
    `created_at`                    TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
    UNIQUE `uq_cht_setting` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='School-level configuration for the CommonChat module. One row per tenant.';
-- Scheduled Job : ChtPurgeOldMessagesJob (runs daily; deletes messages older than cht_settings.message_retention_days).
-- This table will have only 1 Record

-- This table will capture who can initiate Chat with whom and what all action he can perform. This will be used to control the UI and API access. 
-- For example, if allow_student_to_parent is 0, then the UI will not show the option for students to message parents, and the API will return a 403 if a student tries to message a parent.
CREATE TABLE IF NOT EXISTS `cht_permission_config` (
    `id`                            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `permission_for_role_id`        INT UNSIGNED NOT NULL,  -- FK to sys_roles.id; identifies which role the permissions apply to. For example, if this is set to the role_id for "Student", then this row defines who students can message and what actions they can perform.
    `permission_for_user_id`        INT UNSIGNED NULL,  -- Optional FK to sys_users.id for user-specific overrides. If NULL, the permissions apply to all users with the role specified in permission_for_role_id. If set, this row defines permissions for that specific user, overriding the role-based permissions.
    `allowed_whom_to_connect_with`  INT UNSIGNED NOT NULL,  -- FK to sys_roles.id; identifies which role can be messaged by users with the allowed role.
    `can_text_chat`                 TINYINT(1) NOT NULL DEFAULT 0,  -- whether text messaging is allowed between the specified role pairs.
    `can_send_attachment`           TINYINT(1) NOT NULL DEFAULT 1,  -- whether sending attachments is allowed between the specified role pairs.
    `can_send_audio`                TINYINT(1) NOT NULL DEFAULT 0,  -- whether sending audio messages is allowed between the specified role pairs.
    `can_send_video`                TINYINT(1) NOT NULL DEFAULT 0,  -- whether sending video messages is allowed between the specified role pairs.
    `can_send_url`                  TINYINT(1) NOT NULL DEFAULT 0,  -- whether sending URL links is allowed between the specified role pairs.
    `can_send_emoji`                TINYINT(1) NOT NULL DEFAULT 1,  -- whether sending emojis is allowed between the specified role pairs.
    `can_create_group`              TINYINT(1) NOT NULL DEFAULT 0,  -- whether users with the allowed role can create group conversations with the specified role.
    `can_create_announcement`       TINYINT(1) NOT NULL DEFAULT 0,  -- whether users with the allowed role can create announcement conversations with the specified role.
    `can_message_anyone`            TINYINT(1) NOT NULL DEFAULT 0,  -- if 1, users with the allowed role can message any other user regardless of the Role_whom_can_be_chat_with setting. This overrides the role-based
    `read_receipt_enabled`          TINYINT(1) NOT NULL DEFAULT 1,  -- This will override the default setting. When 1, the UI shows read receipts based on cht_message_receipts. When 0, receipts are still tracked in the DB but not displayed in the UI.
    -- Standard audit columns
    `is_active`                     TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`                    TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                    TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
    UNIQUE KEY `uq_cht_permission_config_role_user` (`permission_for_role_id`, `permission_for_user_id`, `allowed_whom_to_connect_with`),
    CONSTRAINT `fk_cht_permission_config_permission_for_role_id` FOREIGN KEY (`permission_for_role_id`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_permission_config_permission_for_user_id` FOREIGN KEY (`permission_for_user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_permission_config_allowed_whom_to_connect_with` FOREIGN KEY (`allowed_whom_to_connect_with`) REFERENCES `sys_roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci


-- ==================================================================================================================================================
-- PURPOSE: Per-user notification and privacy preferences for the chat module. Created lazily on first chat access or pre-seeded for all users at module enablement. 
-- Updated by users via a settings UI. One row per sys_users.id.
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_personalization_settings` (
    `id`                             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `role_id`                        INT UNSIGNED NOT NULL,  -- FK to sys_roles.id for easy querying of role-based defaults. Updated on role change.
    `user_id`                        INT UNSIGNED NULL,      -- FK to sys_users.id; one-to-one relationship
    `show_online_status`             TINYINT(1) NOT NULL DEFAULT 1,  -- Privacy setting: when 0, user appears Offline to others regardless of actual cht_user_presence.last_seen_at value.
    `notify_on_new_message`          TINYINT(1) NOT NULL DEFAULT 1,  -- When 0, no in-app notifications for new chat messages (still increments unread counts in non-muted conversations).
    `notify_on_mention`              TINYINT(1) NOT NULL DEFAULT 1,  -- When 1, user receives a notification when @mentioned in a group message.
    `show_message_preview_in_notif`  TINYINT(1) NOT NULL DEFAULT 1,  -- When 0, notification shows only "New message" without body preview. Privacy option for users sharing devices.
    `show_read_receipt_enabled`  TINYINT(1) NOT NULL DEFAULT 1,  -- When 1, the UI shows read receipts based on cht_message_receipts. When 0, receipts are still tracked in the DB but not displayed in the UI.
    `is_deactivated_by_admin`        TINYINT(1) NOT NULL DEFAULT 0,  -- When 1, the user's chat access is disabled by an admin. The user cannot send or receive messages but their existing conversations and message history remain visible (with a "Chat access disabled" notice in the UI). This allows admins to restrict chat access without deleting user accounts or message history.
    -- Standard audit columns
    `is_active`                      TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`                     INT UNSIGNED NULL,  -- 
    `created_at`                     TIMESTAMP NULL DEFAULT NULL,
    `updated_at`                     TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`                     TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_cht_personalization_settings_roleId_userId` (`role_id`,`user_id`),
    CONSTRAINT `fk_cht_personalization_settings_user_id` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_cht_personalization_settings_role_id` FOREIGN KEY (`role_id`) REFERENCES `sys_roles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-user notification and privacy preferences for CommonChat.';
-- Condition:
-- 1st check if we have permission setting for user_id, if 'Not Available' then check permission for his Role(Role for which he is logged-in right now)
-- If above both permission is not available then use Default Permission from `cht_settings` table
-- If someone has made `show_read_receipt_enabled` = "No" then he will not be able to see "Read_Statud" of Others also.


-- ==================================================================================================================================================
-- PURPOSE: Tracks the last time each user pinged the server to support online/offline status display. Uses user_id as PK (one row per user) with an upsert pattern:
-- INSERT INTO cht_user_presence (user_id, last_seen_at, device_type, ...)  ON DUPLICATE KEY UPDATE last_seen_at = VALUES(last_seen_at), ...
--          NOT a full audit table — no deleted_at or created_by. Deliberately omits is_active, deleted_at (always current state).
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_user_presence` (
    -- user_id is both the PK and the FK to sys_users.id
    `user_id`       INT UNSIGNED NOT NULL,  -- FK to sys_users.id
    `last_seen_at`  TIMESTAMP NULL DEFAULT NULL, -- UTC timestamp of the last heartbeat ping. A user is considered "Online" if last_seen_at > (UTC_TIMESTAMP() - INTERVAL 60 SECOND).
    `device_type`   VARCHAR(20) NULL,  -- Optional: 'web', 'mobile', 'tablet'. Informational only. Allows showing "Active on mobile" style status.
    -- Minimal timestamps — no full audit trail needed for ephemeral presence data
    `created_at`    TIMESTAMP NULL DEFAULT NULL,
    `updated_at`    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`user_id`),
    INDEX `idx_cht_user_presence_last_seen_at` (`last_seen_at`),
    CONSTRAINT `fk_cht_user_presence_user_id` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Live presence tracking. One row per user, upsert on each heartbeat ping.';


-- ==================================================================================================================================================
-- PURPOSE: Header record for every conversation — whether a 1:1 direct message (DM), a named group chat, or a one-way announcement broadcast thread. DM uniqueness is enforced at the 
--          DB level via the dm_pair_hash STORED generated column (pattern from Architectural Decision D-TMP-003). The service layer sets user_a_id = LEAST(userId, recipientId) and
--          user_b_id = GREATEST(userId, recipientId) before insert to guarantee the ordering that dm_pair_hash depends on. Requires MySQL 8.0+ (LEAST/GREATEST in generated columns).
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_conversations` (
    `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conversation_type`    ENUM('Direct', 'Group', 'Announcement') NOT NULL DEFAULT 'Direct',  -- 'Direct'—1:1 private DM between two users. 'Group'—Named multi-user conversation. 'Announcement' — One-way broadcast; only creator/admins can post.
    `name`                 VARCHAR(150) NULL, -- NULL for DM conversations (name is derived at query time from the other participant's sys_users.name). Required for group/announcement.
    `description`          VARCHAR(1000) NULL, -- Optional group or announcement description. NULL for DMs.
    `avatar_media_id`      INT UNSIGNED NULL,  -- Spatie Media Library media.id for the group avatar image. NULL for DMs and until a group avatar is uploaded.
    `user_a_id`            INT UNSIGNED NULL,  -- Only populated for conversation_type = 'direct'. The service layer MUST ensure user_a_id < user_b_id (LEAST/GREATEST). NULL for group and announcement types.
    `user_b_id`            INT UNSIGNED NULL,  -- Only populated for conversation_type = 'direct'. The service layer MUST ensure user_a_id < user_b_id (LEAST/GREATEST). NULL for group and announcement types.
    -- dm_pair_hash: STORED generated column: CONCAT(LEAST(user_a_id, user_b_id), '_', GREATEST(...)) for direct conversations; NULL for groups/announcements. UNIQUE index on this column enforces BR-CHT-001 (one DM per pair). The hash is a string like "42_178" — intentionally not reversible to a URL.
    `dm_pair_hash`         VARCHAR(100) GENERATED ALWAYS AS (CASE WHEN `conversation_type` = 'Direct' AND `user_a_id` IS NOT NULL AND `user_b_id` IS NOT NULL THEN CONCAT(LEAST(`user_a_id`, `user_b_id`), '_', GREATEST(`user_a_id`, `user_b_id`)) ELSE NULL END) STORED,
    `last_message_at`      TIMESTAMP NULL DEFAULT NULL,  -- Used as the primary sort key for the conversation list. (Denormalised: updated within DB::transaction() on every new message.)
    `last_message_preview` VARCHAR(100) NULL,  -- Stored here to avoid a JOIN to cht_messages on every list render. Denormalised: first 100 characters of the last message body. Cleared to NULL if the last message is soft-deleted.
    `is_archived`          TINYINT(1) NOT NULL DEFAULT 0,  -- When 1, conversation is read-only for all participants. Per-user archiving is handled in cht_participants.archived_at.
    -- Standard audit columns
    `created_by`           INT UNSIGNED NULL,  -- FK to 
    `updated_by`           INT UNSIGNED NULL,
    `created_at`           TIMESTAMP NULL DEFAULT NULL,
    `updated_at`           TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`           TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- NULL values are treated as distinct by MySQL UNIQUE indexes, so group/announcement rows (where dm_pair_hash IS NULL) do not conflict.
    UNIQUE KEY `uq_cht_conv_dm_pair_hash` (`dm_pair_hash`),
    UNIQUE KEY `uq_cht_conv_creator_type_name` (`created_by`, `conversation_type`, `name`, `deleted_at`),
    INDEX `idx_cht_conv_type`            (`conversation_type`),
    INDEX `idx_cht_conv_last_message_at` (`last_message_at`),
    INDEX `idx_cht_conv_user_a_id`       (`user_a_id`),
    INDEX `idx_cht_conv_user_b_id`       (`user_b_id`),
    INDEX `idx_cht_conv_is_archived`     (`is_archived`),
    CONSTRAINT `fk_cht_conv_user_a_id` FOREIGN KEY (`user_a_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_conv_user_b_id` FOREIGN KEY (`user_b_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_conv_created_by_id` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `chk_conv_group_announcement_name` CHECK ((`conversation_type` IN ('Group', 'Announcement') AND `name` IS NOT NULL) OR (`conversation_type` = 'Direct' AND `name` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Header record for each conversation (DM, group, or announcement).';
-- Condition:
-- `dm_pair_hash` will take care the uniqueness for Direct chat between 2 users and 

-- ==================================================================================================================================================
-- PURPOSE: Membership table linking users to conversations. Every user-conversation relationship has exactly one row here. Stores per-user state: unread count, mute, pin order, archive, 
-- and departure timestamp. For DMs: 2 rows (one per participant). For groups: N rows (one per member, including admins). For announcements: N rows (recipients) + 1 (creator/admin).
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_participants` (
    `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conversation_id`  BIGINT UNSIGNED NOT NULL,  -- Parent conversation. Cascade-delete removes participant record. if the conversation is hard-deleted (e.g., by admin force-delete).
    `user_id`          INT UNSIGNED NOT NULL,  -- The participating user from sys_users. FK to sys_users.id
    `role`             ENUM('Member', 'Admin') NOT NULL DEFAULT 'Member',  -- 'Member' — Regular participant (can read and send messages). 'Admin'—Group administrator (can add/remove members, archive, rename). Only meaningful for group/announcement types.
    `joined_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- When the user was added to the conversation. Set at creation for founding members; set at invitation time for later additions.
    `left_at`          TIMESTAMP NULL DEFAULT NULL,  -- Set when the user voluntarily leaves a group (BR-CHT-013). NULL means currently active in the conversation. A user with left_at IS NOT NULL cannot send/receive new messages.
    `muted_until`      TIMESTAMP NULL DEFAULT NULL,  -- NULL = conversation is not muted. Future timestamp = muted until that time. '9999-12-31 23:59:59' = muted indefinitely (BR-CHT-006). Prevents unread_count increment and notification dispatch.
    `is_pinned`        TINYINT(1) NOT NULL DEFAULT 0,  -- Whether this user has pinned this conversation (BR-CHT-015). Max 5 pins per user enforced at ChatService level.
    `pin_order`        TINYINT UNSIGNED NULL,  -- Display order of pinned conversations (1 = topmost). NULL if not pinned.
    `unread_count`     INT UNSIGNED NOT NULL DEFAULT 0,  -- Denormalised count of unread messages for this user in this conversation. Incremented on new non-muted message; reset to 0 on mark-read (BR-CHT-012).
    `archived_at`      TIMESTAMP NULL DEFAULT NULL,  -- Per-user archive timestamp. When set, this conversation is hidden from the user's main list and shown in the "Archived" tab. Does NOT affect other participants (per-user, not school-wide).
    -- Standard audit columns (excluding deleted_at — membership uses left_at instead)
    `created_by`       INT UNSIGNED NULL,
    `updated_by`       INT UNSIGNED NULL,
    `created_at`       TIMESTAMP NULL DEFAULT NULL,
    `updated_at`       TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`       TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- Enforces that a user can only appear once in any given conversation.
    UNIQUE KEY `uq_cht_participants_conv_user` (`conversation_id`, `user_id`),
    INDEX `idx_cht_participants_user_id`       (`user_id`),
    INDEX `idx_cht_participants_left_at`       (`left_at`),
    INDEX `idx_cht_participants_muted_until`   (`muted_until`),
    INDEX `idx_cht_participants_is_pinned`     (`is_pinned`),
    INDEX `idx_cht_participants_unread_count`  (`unread_count`),
    INDEX `idx_cht_participants_archived_at`   (`archived_at`),
    CONSTRAINT `fk_cht_participants_conversation_id` FOREIGN KEY (`conversation_id`) REFERENCES `cht_conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_participants_user_id` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Membership table: one row per user per conversation. Stores per-user unread count, mute, pin, and archive state.';


-- ==================================================================================================================================================
-- PURPOSE: Stores every message sent within a conversation. Fetched ordered by created_at ASC within a conversation (same pattern as EmployeeLeaveApplicationRemarkController::getByApplication()).
--          Soft-deleted messages retain their row but have body cleared and is_deleted = 1 (BR-CHT-004, BR-CHT-012).
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_messages` (
    `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `conversation_id`  BIGINT UNSIGNED NOT NULL,  -- The conversation this message belongs to.
    `sender_id`        INT UNSIGNED NULL,  -- The sys_users.id of the message author. SET NULL on user delete so the message record is preserved but attributed to "Deleted User".
    `parent_message_id` BIGINT UNSIGNED NULL,  -- For reply-to threading (F-CHT-04). References another cht_messages.id in the SAME conversation. NULL for top-level messages. Reply depth capped at 1 level (BR-CHT-016).
    `body`             VARCHAR(2000) NULL,  -- Plain text message content (no HTML). UTF-8 to support all Indian regional scripts and emoji. Max 5,000 characters enforced at FormRequest. Cleared to NULL when is_deleted = 1 (privacy on soft-delete).
    `message_type`     ENUM('Text', 'Attachment', 'System') NOT NULL DEFAULT 'text',  -- 'text' — Regular text message (body may be NULL if attachment present). 'attachment' — Message with a file attachment (body optional). 'system' — Auto-generated message: "User joined", "Admin removed message", "User left", "Ownership transferred", etc.
    `is_deleted`       TINYINT(1) NOT NULL DEFAULT 0,  -- 1 = message has been soft-deleted. body is set to NULL.
    `deleted_by`       INT UNSIGNED NULL,  -- sys_users.id of who performed the delete. If deleted_by = sender_id → "This message was deleted". If deleted_by != sender_id (admin action) → "Removed by Admin".
    -- Standard audit columns
    `created_by`       INT UNSIGNED NULL,
    `updated_by`       INT UNSIGNED NULL,
    `created_at`       TIMESTAMP NULL DEFAULT NULL,
    `updated_at`       TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`       TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- Primary fetch pattern: all messages in a conversation ordered by time. Composite index supports: WHERE conversation_id = ? ORDER BY created_at ASC
    INDEX `idx_cht_messages_conv_time`      (`conversation_id`, `created_at`),
    INDEX `idx_cht_messages_sender_id`      (`sender_id`),
    INDEX `idx_cht_messages_parent_msg_id`  (`parent_message_id`),
    INDEX `idx_cht_messages_is_deleted`     (`is_deleted`),
    INDEX `idx_cht_messages_message_type`   (`message_type`),
    CONSTRAINT `fk_cht_messages_conversation_id` FOREIGN KEY (`conversation_id`) REFERENCES `cht_conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_messages_sender_id` FOREIGN KEY (`sender_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_messages_parent_message_id` FOREIGN KEY (`parent_message_id`) REFERENCES `cht_messages` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_messages_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Individual messages within conversations. Soft-delete clears body; row is retained for audit.';


-- ==================================================================================================================================================
-- PURPOSE: Per-message, per-recipient read receipt tracking (F-CHT-05). One row is created for each non-sender participant when a message is sent. read_at is set when the participant opens
-- the conversation (bulk mark-read endpoint). Intentionally has NO deleted_at — receipts are an immutable delivery audit log. For DMs: 1 row per message (one recipient). For groups of
-- N: (N-1) rows per message (all non-senders). Performance note: this table grows rapidly. Index on (message_id, user_id) and (user_id, read_at) for the two primary query patterns:
--  1. "Who read message M?" (message view).   2. "Mark all unread messages in conversation C as read for user U"
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_message_receipts` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `message_id`  BIGINT UNSIGNED NOT NULL,  -- The message this receipt tracks.
    `user_id`     INT UNSIGNED NOT NULL,  -- The recipient (non-sender) participant.
    `read_at`     TIMESTAMP NULL DEFAULT NULL,  -- NULL = message has not been read by this recipient. Timestamp = when the recipient first read the message. Set in bulk by the mark-read endpoint when the user opens the conversation.
    `created_at`  TIMESTAMP NULL DEFAULT NULL,  -- Intentionally omitting: deleted_at, is_active, created_by, updated_by Receipts are append-only records; they are never modified after read_at is set.
    `updated_at`  TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- Ensures one receipt per message per recipient (BR-CHT-005 data integrity).
    UNIQUE KEY `uq_cht_message_receipts_msg_user` (`message_id`, `user_id`),
    -- Pattern 2: fetch all unread messages for user U in conversation C (JOIN cht_messages ON message_id to filter by conversation_id)
    INDEX `idx_cht_message_receipts_user_read` (`user_id`, `read_at`),
    CONSTRAINT `fk_cht_message_receipts_message_id` FOREIGN KEY (`message_id`) REFERENCES `cht_messages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_cht_message_receipts_user_id` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-message, per-recipient read receipts. No deleted_at — immutable delivery log.';


-- ==================================================================================================================================================
-- PURPOSE: File metadata for attachments linked to messages (F-CHT-03). One attachment per message in Phase-1. The actual file is stored via Spatie Media Library in: 
-- storage/tenant_{uuid}/chat-attachments/ This table stores metadata for display and download without requiring a Media Library JOIN on every message fetch.
-- Intentionally has NO deleted_at — attachment rows follow the lifecycle of their parent message. When a message is soft-deleted (is_deleted = 1), the attachment row is retained
-- but the file URL is no longer served (ChatAttachment model accessor returns NULL if message.is_deleted = 1).
-- ==================================================================================================================================================
CREATE TABLE IF NOT EXISTS `cht_attachments` (
    `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `message_id`   BIGINT UNSIGNED NOT NULL,  -- The message this attachment belongs to. Cascade-delete removes the attachment record when the message is hard-deleted (admin action).
    `file_name`    VARCHAR(255) NOT NULL,  -- Original filename as uploaded by the user (client-provided, sanitised server-side before storage). Displayed as the download link label.
    `file_path`    VARCHAR(500) NOT NULL,  -- Storage path relative to the tenant disk root. Example: "chat-attachments/2026/05/14/abc123_contract.pdf"
    `file_size`    INT UNSIGNED NOT NULL,  -- File size in bytes. Used to display "2.4 MB" labels in the UI without re-fetching the file.
    `mime_type`    VARCHAR(100) NOT NULL,  -- Server-validated MIME type. Used to determine icon rendering and preview eligibility (images can be shown inline; PDFs/docs use icon).
    `media_id`     INT UNSIGNED NULL,  -- Spatie Media Library spatie_media.id for this file. NULL if stored without Spatie (direct disk storage fallback).
    `thumbnail_media_id` INT UNSIGNED NULL,  -- Spatie media.id for the generated thumbnail (images only). NULL for non-image attachments.
    -- Standard audit columns (no deleted_at — follows message lifecycle)
    `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`   INT UNSIGNED NULL,
    `updated_by`   INT UNSIGNED NULL,
    `created_at`   TIMESTAMP NULL DEFAULT NULL,
    `updated_at`   TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    -- One attachment per message in Phase-1. UNIQUE constraint removed for Phase-2 multi-attachment support. Index retained for JOIN performance.
    INDEX `idx_cht_attachments_message_id` (`message_id`),
    INDEX `idx_cht_attachments_media_id`   (`media_id`),
    CONSTRAINT `fk_cht_attachments_message_id` FOREIGN KEY (`message_id`) REFERENCES `cht_messages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='File attachment metadata for chat messages. Actual files via Spatie Media Library.';


-- ==================================================================================================================================================
-- SUMMARY
-- ==================================================================================================================================================
-- Table                  | Rows / Scale              | Notes
-- -----------------------|---------------------------|-----------------------------
-- cht_settings           | 1 per tenant              | Seeded on tenant create
-- cht_user_settings      | 1 per active user         | Lazy-created on first chat
-- cht_user_presence      | 1 per active user         | Upserted every 30s
-- cht_conversations      | 1 per conversation        | DM + Group + Announcement
-- cht_participants       | ~N users × M convos       | High cardinality; indexed
-- cht_messages           | Very high (all messages)  | Paginated; indexed by conv+time
-- cht_message_receipts   | msg_count × recipient_N   | Highest volume; append-only
-- cht_attachments        | ≤ 1 per message           | Moderate volume
-- ==================================================================================================================================================
-- Total new tables: 8
-- All tables: tenant_db only (never prime_db / global_db)
-- Migration file: 2026_05_14_000001_create_cht_common_chat_tables.php
-- Seeder: ChtSettingsSeeder (seeds 1 row in cht_settings with all defaults)
-- ==================================================================================================================================================
