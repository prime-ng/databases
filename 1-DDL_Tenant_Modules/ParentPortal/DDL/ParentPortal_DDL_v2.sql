-- =============================================================================
-- PPT (Parent Portal) Module — DDL v2
-- Tables: 6 new ppt_* tables
-- Date: 2026-Jun-04
-- DB: tenant_db | Engine: InnoDB | Charset: utf8mb4_unicode_ci
-- =============================================================================

-- -----------------------------------------------------------------------
-- Purpose: Per-device portal state — active child, push tokens, prefs
-- Rows per tenant: ~3–5 per guardian (multi-device); medium volume
-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ppt_parent_sessions` (
  `id`                              INT UNSIGNED        NOT NULL AUTO_INCREMENT,
  `guardian_id`                     INT UNSIGNED        NOT NULL,                    -- FK → std_guardians.id
  `active_student_id`               INT UNSIGNED        NULL,                        -- FK → std_students.id; currently selected child
  `device_token_fcm`                VARCHAR(255)        NULL,                        -- Android FCM push token
  `device_token_apns`               VARCHAR(255)        NULL,                        -- iOS APNs push token
  `device_token_webpush`            TEXT                NULL,                        -- Web Push (PWA) subscription JSON
  `device_type`                     ENUM('Android','iOS','Web','Unknown') NOT NULL DEFAULT 'Unknown',
  `notification_preferences_json`   JSON                NULL,                        -- {"FeeReminder":{"in_app":1,"sms":1,"email":0}}
  `quiet_hours_start`               TIME                NULL,                        -- e.g. 22:00
  `quiet_hours_end`                 TIME                NULL,                        -- e.g. 07:00
  `last_active_at`                  TIMESTAMP           NULL,
  `is_active`                       TINYINT(1)          NOT NULL DEFAULT 1,          -- 0 = logged out
  `created_by`                      BIGINT UNSIGNED     NULL,                        -- platform standard
  `created_at`                      TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`                      TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  -- NOTE: NO deleted_at — use is_active=0 on logout; hard-delete stale sessions via cron
  PRIMARY KEY (`id`),
  UNIQUE KEY  `uq_ppt_session_guardian_device_fcm` (`guardian_id`, `device_token_fcm`),
  INDEX       `idx_ppt_sessions_guardian`          (`guardian_id`),
  INDEX       `idx_ppt_sessions_active_student`    (`active_student_id`),
  INDEX       `idx_ppt_sessions_is_active`         (`is_active`),
  CONSTRAINT `fk_ppt_sess_guardian` FOREIGN KEY (`guardian_id`)        REFERENCES `std_guardians` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppt_sess_student` FOREIGN KEY (`active_student_id`)  REFERENCES `std_students`  (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-device portal state: active child, push tokens, notification preferences';


-- -----------------------------------------------------------------------
-- Purpose: Parent RSVPs and volunteer sign-ups for school events
-- Rows per tenant: medium (events × guardians)
-- UNIQUE on (event_id, guardian_id) enforces BR-PPT-016
-- NO deleted_at — RSVPs updated in-place (rsvp_status changed)
-- Brijesh : Currently thsi Table is on Hold. It is being used in ParentPortal (view only) but there is not Table to Ceate a Event, for which this Table is required t respond.
-- I need to create a new Table for Event or even a small Module to register Upcomming Events in the School for which Student/Parents can Register themself.
-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ppt_event_rsvps` (
  `id`                INT UNSIGNED        NOT NULL AUTO_INCREMENT,
  `event_id`          INT UNSIGNED        NOT NULL,                                  -- FK to Event Engine event record ???????????????
  `guardian_id`       INT UNSIGNED        NOT NULL,                                  -- FK → std_guardians.id
  `student_id`        INT UNSIGNED        NULL,                                      -- FK → std_students.id (child context for this RSVP)
  `rsvp_status`       ENUM('Attending','Not_Attending','Maybe') NOT NULL DEFAULT 'Attending',
  `is_volunteer`      TINYINT(1)          NOT NULL DEFAULT 0,
  `volunteer_role`    VARCHAR(150)        NULL,                                       -- e.g. "Food stall", "Registration desk"
  `rsvp_notes`        TEXT                NULL,
  `confirmed_at`      TIMESTAMP           NULL,                                       -- when RSVP was confirmed
  `reminder_sent_at`  TIMESTAMP           NULL,                                       -- last reminder dispatch timestamp
  `is_active`         TINYINT(1)          NOT NULL DEFAULT 1,
  `created_by`        BIGINT UNSIGNED     NULL,
  `created_at`        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  -- NOTE: NO deleted_at — RSVPs not soft-deleted; update rsvp_status = 'Not_Attending' to cancel
  PRIMARY KEY (`id`),
  UNIQUE KEY  `uq_ppt_rsvp_event_guardian`  (`event_id`, `guardian_id`),             -- BR-PPT-016: one RSVP per guardian per event
  INDEX       `idx_ppt_rsvp_guardian`       (`guardian_id`),
  INDEX       `idx_ppt_rsvp_student`        (`student_id`),
  INDEX       `idx_ppt_rsvp_event`          (`event_id`),
  CONSTRAINT `fk_ppt_rsvp_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppt_rsvp_student` FOREIGN KEY (`student_id`)  REFERENCES `std_students`  (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Parent event RSVPs and volunteer registrations; unique per guardian per event';


-- -----------------------------------------------------------------------
-- Purpose: Online requests for duplicate certificates and official documents
-- Rows per tenant: low-medium (10–30 per student lifetime)
-- payment_reference UNIQUE (nullable) = idempotency guard for Razorpay
-- MySQL UNIQUE on nullable column allows multiple NULLs natively
-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ppt_document_requests` (
  `id`                    INT UNSIGNED        NOT NULL AUTO_INCREMENT,
  `request_number`        VARCHAR(30)         NOT NULL,                              -- PPT-DR-2026-00000001 (unique)
  `student_id`            INT UNSIGNED        NOT NULL,                              -- FK → std_students.id
  `guardian_id`           INT UNSIGNED        NOT NULL,                              -- FK → std_guardians.id
  `document_type`         ENUM('TC','MarkSheet','Bonafide','Character','Migration','MedicalFitness','Other') NOT NULL,
  `reason`                TEXT                NOT NULL,
  `urgency`               ENUM('Normal','Urgent') NOT NULL DEFAULT 'Normal',
  `status`                ENUM('Pending','Processing','Ready','Completed','Rejected') NOT NULL DEFAULT 'Pending',
  `admin_notes`           TEXT                NULL,
  `fee_required`          DECIMAL(8,2)        NOT NULL DEFAULT 0.00,                 -- 0 = free
  `fee_paid`              TINYINT(1)          NOT NULL DEFAULT 0,
  `payment_reference`     VARCHAR(100)        NULL,                                  -- Razorpay payment_id; UNIQUE nullable (idempotency)
  `fulfilled_media_id`    INT UNSIGNED        NULL,                                  -- FK → sys_media.id (uploaded by admin)
  `fulfilled_at`          TIMESTAMP           NULL,
  `is_active`             TINYINT(1)          NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED     NULL,
  `created_at`            TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`            TIMESTAMP           NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY  `uq_ppt_doc_request_number`   (`request_number`),
  UNIQUE KEY  `uq_ppt_doc_payment_ref`      (`payment_reference`),                   -- NULL-safe unique (BR-PPT-011 idempotency)
  INDEX       `idx_ppt_doc_student_status`  (`student_id`, `status`),
  INDEX       `idx_ppt_doc_guardian`        (`guardian_id`),
  INDEX       `idx_ppt_doc_status`          (`status`),
  CONSTRAINT `fk_ppt_doc_student` FOREIGN KEY (`student_id`)       REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppt_doc_guardian` FOREIGN KEY (`guardian_id`)      REFERENCES `std_guardians` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppt_doc_media` FOREIGN KEY (`fulfilled_media_id`) REFERENCES `sys_media`  (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Online requests for duplicate certificates; payment_reference unique for Razorpay idempotency';


-- -----------------------------------------------------------------------
-- Purpose: Parent consent forms
-- Rows per tenant: low-medium (10–30 per student lifetime)
-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ppt_consent_forms` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(200) NOT NULL,
  `content` LONGTEXT NOT NULL COMMENT 'HTML body of the form',  -- Complete Consent Form, which Parents need to respond to.
  `class_id` BIGINT UNSIGNED NULL COMMENT 'FK → sch_classes.id — null = all classes',  -- null = all classes
  `section_id` BIGINT UNSIGNED NULL COMMENT 'FK → sch_sections.id — null = all sections in class',  -- null = all sections
  `deadline` TIMESTAMP NOT NULL COMMENT 'Parents cannot sign after this',  -- null = no deadline
  `allow_decline` TINYINT(1) NOT NULL DEFAULT 1,  -- allow parents to opt-out
  `status` ENUM('Draft', 'Published', 'Closed') NOT NULL DEFAULT 'Published',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NULL DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT NULL,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ppt_cf_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ppt_cf_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ppt_cf_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  INDEX `idx_ppt_cf_status_deadline` (`status`, `deadline`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='School digital consent forms (IMMUTABLE)';

-- -----------------------------------------------------------------------
-- Purpose: Parent responses to school digital consent forms (IMMUTABLE)
-- Rows per tenant: low-medium (forms × students × parents)
-- CRITICAL: NO deleted_at — consent responses are immutable after creation
-- CRITICAL: signed_at is a BUSINESS timestamp, NOT created_at alias
-- UNIQUE (consent_form_id, student_id, guardian_id) = BR-PPT-014 double-sign prevention
-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ppt_consent_form_responses` (
  `id`                INT UNSIGNED        NOT NULL AUTO_INCREMENT,
  `consent_form_id`   INT UNSIGNED        NOT NULL,                                  -- FK to ppt_consent_forms.id; school's consent form (Event/Activity module)
  `student_id`        INT UNSIGNED        NOT NULL,                                  -- FK → std_students.id
  `guardian_id`       INT UNSIGNED        NOT NULL,                                  -- FK → std_guardians.id
  `response`          ENUM('Signed','Declined') NOT NULL,
  `decline_reason`    TEXT                NULL,                                      -- required when response=Declined (FormRequest enforced)
  `signer_name`       VARCHAR(150)        NOT NULL,                                  -- parent's typed name (e-signature)
  `signed_ip`         VARCHAR(45)         NULL,                                      -- IPv4/IPv6 at time of signing
  `signed_at`         TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- BUSINESS timestamp (immutable); separate from created_at
  `is_active`         TINYINT(1)          NOT NULL DEFAULT 1,
  `created_by`        BIGINT UNSIGNED     NULL,
  `created_at`        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  -- NOTE: NO deleted_at — consent form responses MUST be immutable after signing
  --       Do NOT add softDeletes or deleted_at to this table under any circumstance.
  PRIMARY KEY (`id`),
  UNIQUE KEY  `uq_ppt_consent_response`     (`consent_form_id`, `student_id`, `guardian_id`), -- BR-PPT-014: no double-sign
  INDEX       `idx_ppt_consent_student`     (`student_id`),
  INDEX       `idx_ppt_consent_guardian`    (`guardian_id`),
  INDEX       `idx_ppt_consent_form`        (`consent_form_id`),
  CONSTRAINT `fk_ppt_consent_form` FOREIGN KEY (`consent_form_id`) REFERENCES `ppt_consent_forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppt_consent_student` FOREIGN KEY (`student_id`)  REFERENCES `std_students`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppt_consent_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable parent consent form responses; signed_at+signed_ip recorded permanently';
