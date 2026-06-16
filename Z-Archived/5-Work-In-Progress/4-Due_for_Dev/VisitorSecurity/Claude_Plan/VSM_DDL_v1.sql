-- =============================================================================
-- VSM — Visitor & Security Management Module DDL
-- Module: VisitorSecurity (Modules\VisitorSecurity)
-- Table Prefix: vsm_* (13 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-27
-- Based on: VSM_VisitorSecurity_Requirement.md v2
-- Sub-Modules: Visitor Management, Gate Operations, Contractor Access,
--              Guard Shifts, Patrol Rounds, Emergency System, CCTV Hooks
-- =============================================================================
-- FK Type Note:
--   vsm_* PKs and internal FKs  → BIGINT UNSIGNED
--   Cross-module FKs (sys_users, sys_media, std_students) → INT UNSIGNED
--   (tenant_db_v2 defines sys_users.id, sys_media.id, std_students.id as INT UNSIGNED;
--    MySQL requires FK column type to match referenced column type exactly)
-- =============================================================================

-- =============================================================================
-- LAYER 1 — No vsm_* FK dependencies (may reference sys_* only)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. vsm_visitors — Master visitor profile (matched by mobile_no)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_visitors` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT             COMMENT 'Primary key',
    `name`                 VARCHAR(150)     NOT NULL                            COMMENT 'Full visitor name',
    `mobile_no`            VARCHAR(20)      NOT NULL                            COMMENT 'Primary match key; used for blacklist check on every registration',
    `email`                VARCHAR(100)     NULL     DEFAULT NULL               COMMENT 'Optional email for QR gate pass dispatch',
    `id_type`              ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other')
                                            NULL     DEFAULT NULL               COMMENT 'Government-issued ID type',
    `id_number`            VARCHAR(50)      NULL     DEFAULT NULL               COMMENT 'Secondary blacklist match key; matched along with mobile_no',
    `company_name`         VARCHAR(150)     NULL     DEFAULT NULL               COMMENT 'Employer or organisation name',
    `photo_media_id`       INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_media.id; visitor photo stored on private disk (BR-VSM-009)',
    `id_proof_media_id`    INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_media.id; ID proof scan stored on private disk (BR-VSM-009)',
    `visit_count`          INT UNSIGNED     NOT NULL DEFAULT 0                  COMMENT 'Denormalised total confirmed check-ins; incremented at application layer on each check-in (BR-VSM-013)',
    `is_blacklisted`       TINYINT(1)       NOT NULL DEFAULT 0                  COMMENT 'Cache flag; set when blacklist match found for fast dashboard display',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1                  COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id; user who created the record',
    `updated_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id; user who last updated',
    `created_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Soft delete timestamp; NULL = active',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_vis_mobile`    (`mobile_no`),
    KEY `idx_vsm_vis_id_number` (`id_number`),
    KEY `idx_vsm_vis_photo`     (`photo_media_id`),
    KEY `idx_vsm_vis_idproof`   (`id_proof_media_id`),
    KEY `idx_vsm_vis_created`   (`created_by`),

    CONSTRAINT `fk_vsm_vis_photo`    FOREIGN KEY (`photo_media_id`)    REFERENCES `sys_media`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_vis_idproof`  FOREIGN KEY (`id_proof_media_id`) REFERENCES `sys_media`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_vis_created`  FOREIGN KEY (`created_by`)        REFERENCES `sys_users`  (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Master visitor profile; one row per unique visitor matched by mobile_no; upserted on each new registration';

-- -----------------------------------------------------------------------------
-- 2. vsm_blacklist — Blacklisted persons (checked on every registration)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_blacklist` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT             COMMENT 'Primary key',
    `name`                 VARCHAR(150)     NOT NULL                            COMMENT 'Full name of blacklisted person',
    `mobile_no`            VARCHAR(20)      NULL     DEFAULT NULL               COMMENT 'Primary match key; checked against vsm_visitors.mobile_no on every registration (BR-VSM-001)',
    `id_type`              ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other')
                                            NULL     DEFAULT NULL               COMMENT 'ID document type for secondary match',
    `id_number`            VARCHAR(50)      NULL     DEFAULT NULL               COMMENT 'Secondary match key; checked along with mobile_no (BR-VSM-001)',
    `photo_media_id`       INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_media.id; optional blacklist photo for visual verification',
    `reason`               TEXT             NOT NULL                            COMMENT 'Why this person is blacklisted; shown to reception staff when blocked',
    `blacklisted_by`       INT UNSIGNED     NOT NULL                            COMMENT 'FK→sys_users.id; admin or principal who added to blacklist',
    `valid_until`          DATE             NULL     DEFAULT NULL               COMMENT 'Expiry date; NULL = permanent blacklist; auto-expired by daily job when valid_until < TODAY() (BR-VSM-014)',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1                  COMMENT 'Soft enable/disable; set to 0 by ExpireBlacklistEntriesJob when valid_until < TODAY()',
    `created_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id',
    `updated_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id',
    `created_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_bl_mobile`     (`mobile_no`),
    KEY `idx_vsm_bl_id_number`  (`id_number`),
    KEY `idx_vsm_bl_by`         (`blacklisted_by`),
    KEY `idx_vsm_bl_photo`      (`photo_media_id`),
    KEY `idx_vsm_bl_created`    (`created_by`),

    CONSTRAINT `fk_vsm_bl_photo`    FOREIGN KEY (`photo_media_id`)  REFERENCES `sys_media`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_bl_by`       FOREIGN KEY (`blacklisted_by`)  REFERENCES `sys_users`  (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_bl_created`  FOREIGN KEY (`created_by`)      REFERENCES `sys_users`  (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Blacklisted persons; checked on every registration attempt; at least one of mobile_no or id_number must be set';

-- -----------------------------------------------------------------------------
-- 3. vsm_emergency_protocols — SOP templates per emergency type
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_emergency_protocols` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT          COMMENT 'Primary key',
    `protocol_type`           ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other')
                                               NOT NULL                         COMMENT 'Emergency category; links to vsm_emergency_events.emergency_type',
    `title`                   VARCHAR(200)     NOT NULL                         COMMENT 'Protocol title; e.g. Campus Lockdown Protocol',
    `description`             TEXT             NOT NULL                         COMMENT 'Step-by-step SOP instructions',
    `responsible_roles_json`  JSON             NULL     DEFAULT NULL            COMMENT 'Array of role slugs responsible for this protocol; e.g. ["Admin","Principal","Guard"]',
    `media_ids_json`          JSON             NULL     DEFAULT NULL            COMMENT 'Array of sys_media IDs; evacuation maps, SOP PDF documents',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1               COMMENT 'Soft enable/disable',
    `created_by`              INT UNSIGNED     NULL     DEFAULT NULL            COMMENT 'FK→sys_users.id',
    `updated_by`              INT UNSIGNED     NULL     DEFAULT NULL            COMMENT 'FK→sys_users.id',
    `created_at`              TIMESTAMP        NULL     DEFAULT NULL            COMMENT 'Record creation timestamp',
    `updated_at`              TIMESTAMP        NULL     DEFAULT NULL            COMMENT 'Record last update timestamp',
    `deleted_at`              TIMESTAMP        NULL     DEFAULT NULL            COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_ep_type`    (`protocol_type`),
    KEY `idx_vsm_ep_created` (`created_by`),

    CONSTRAINT `fk_vsm_ep_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Emergency SOP templates; seeded with 5 standard types; school admin customises descriptions';

-- -----------------------------------------------------------------------------
-- 4. vsm_patrol_checkpoints — Campus checkpoint definitions (QR placed at location)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_patrol_checkpoints` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT             COMMENT 'Primary key',
    `name`                 VARCHAR(100)     NOT NULL                            COMMENT 'Checkpoint name; e.g. Lab Block Entrance, Main Gate',
    `location_description` TEXT             NULL     DEFAULT NULL               COMMENT 'Detailed location description for guard reference',
    `building`             VARCHAR(100)     NULL     DEFAULT NULL               COMMENT 'Building name; e.g. Admin Block, Science Wing',
    `floor`                VARCHAR(20)      NULL     DEFAULT NULL               COMMENT 'Floor identifier; e.g. Ground, 1st, Basement',
    `sequence_order`       TINYINT UNSIGNED NOT NULL DEFAULT 0                  COMMENT 'Recommended patrol route order; lower = earlier in round',
    `qr_token`             VARCHAR(100)     NOT NULL                            COMMENT 'UUID v4 QR token placed at physical location; guard scans to log presence',
    `qr_code_path`         VARCHAR(255)     NULL     DEFAULT NULL               COMMENT 'File path of generated QR code image (SimpleSoftwareIO)',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1                  COMMENT 'Soft enable/disable; only active checkpoints count toward patrol completion',
    `created_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id',
    `updated_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id',
    `created_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_vsm_pc_qr_token` (`qr_token`),
    KEY `idx_vsm_pc_created` (`created_by`),

    CONSTRAINT `fk_vsm_pc_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Campus patrol checkpoint definitions; each has a unique QR code placed at the physical location';

-- =============================================================================
-- LAYER 2 — Depends on Layer 1 tables
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5. vsm_visits — Per-visit record with 6-state FSM
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_visits` (
    `id`                         BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT       COMMENT 'Primary key',
    `visit_number`               VARCHAR(30)      NOT NULL                      COMMENT 'Human-readable ID; format: VSM-YYYYMMDD-XXXX; generated in VisitorService',
    `visitor_id`                 BIGINT UNSIGNED  NOT NULL                      COMMENT 'FK→vsm_visitors.id; the visitor this visit belongs to',
    `host_user_id`               INT UNSIGNED     NULL     DEFAULT NULL         COMMENT 'FK→sys_users.id; staff member being visited; NULL allowed for delivery/maintenance walk-ins',
    `purpose`                    ENUM('PTM','Admission','Meeting','Delivery','Maintenance','Interview','StudentPickup','Contractor','Other')
                                                  NOT NULL                      COMMENT 'Visit purpose; StudentPickup triggers pickup auth flow; Contractor for contractor entries',
    `purpose_detail`             VARCHAR(255)     NULL     DEFAULT NULL         COMMENT 'Optional free-text purpose detail',
    `expected_date`              DATE             NOT NULL                      COMMENT 'Date visitor is expected; used by overdue scheduler and no-show flagging',
    `expected_time`              TIME             NULL     DEFAULT NULL         COMMENT 'Expected arrival time; optional',
    `expected_duration_minutes`  SMALLINT UNSIGNED NOT NULL DEFAULT 60          COMMENT 'Expected visit duration; used by FlagOverdueVisitorsJob: checkin_time + this < NOW → is_overdue=1 (BR-VSM-004)',
    `vehicle_number`             VARCHAR(20)      NULL     DEFAULT NULL         COMMENT 'Vehicle registration number; optional',
    `gate_assigned`              VARCHAR(50)      NULL     DEFAULT NULL         COMMENT 'Assigned entry gate; e.g. Main Gate, Back Gate',
    `checkin_time`               TIMESTAMP        NULL     DEFAULT NULL         COMMENT 'Gate check-in timestamp; set by VisitorService::processCheckin inside DB::transaction()',
    `checkin_photo_media_id`     INT UNSIGNED     NULL     DEFAULT NULL         COMMENT 'FK→sys_media.id; live gate photo captured at check-in; optional',
    `checkout_time`              TIMESTAMP        NULL     DEFAULT NULL         COMMENT 'Gate check-out timestamp',
    `duration_minutes`           SMALLINT UNSIGNED NULL    DEFAULT NULL         COMMENT 'Computed: (checkout_time - checkin_time) in minutes; set on check-out',
    `status`                     ENUM('Pre_Registered','Registered','Checked_In','Checked_Out','No_Show','Cancelled')
                                                  NOT NULL DEFAULT 'Registered' COMMENT 'Visit lifecycle state: Pre_Registered=pre-reg pending; Registered=walk-in; Checked_In=on campus; Checked_Out=exited; No_Show=expected_date passed without checkin; Cancelled=cancelled by host/admin',
    `is_overdue`                 TINYINT(1)       NOT NULL DEFAULT 0            COMMENT 'Overdue flag; set by FlagOverdueVisitorsJob every 15 min when checkin_time+expected_duration < NOW AND status=Checked_In; cleared on check-out (BR-VSM-004)',
    `blacklist_hit`              TINYINT(1)       NOT NULL DEFAULT 0            COMMENT 'Set to 1 at registration time if visitor mobile_no or id_number matched vsm_blacklist (BR-VSM-001)',
    `notes`                      TEXT             NULL     DEFAULT NULL         COMMENT 'Freeform notes',
    `is_active`                  TINYINT(1)       NOT NULL DEFAULT 1            COMMENT 'Soft enable/disable',
    `created_by`                 INT UNSIGNED     NULL     DEFAULT NULL         COMMENT 'FK→sys_users.id',
    `updated_by`                 INT UNSIGNED     NULL     DEFAULT NULL         COMMENT 'FK→sys_users.id',
    `created_at`                 TIMESTAMP        NULL     DEFAULT NULL         COMMENT 'Record creation timestamp',
    `updated_at`                 TIMESTAMP        NULL     DEFAULT NULL         COMMENT 'Record last update timestamp',
    `deleted_at`                 TIMESTAMP        NULL     DEFAULT NULL         COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_vsm_visit_number` (`visit_number`),
    KEY `idx_vsm_vst_date_status`  (`expected_date`, `status`),
    KEY `idx_vsm_vst_visitor`      (`visitor_id`),
    KEY `idx_vsm_vst_host`         (`host_user_id`),
    KEY `idx_vsm_vst_checkin`      (`checkin_time`),
    KEY `idx_vsm_vst_checkin_photo`(`checkin_photo_media_id`),
    KEY `idx_vsm_vst_created`      (`created_by`),

    CONSTRAINT `fk_vsm_vst_visitor`       FOREIGN KEY (`visitor_id`)            REFERENCES `vsm_visitors` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_vst_host`          FOREIGN KEY (`host_user_id`)          REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_vst_checkin_photo` FOREIGN KEY (`checkin_photo_media_id`)REFERENCES `sys_media`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_vst_created`       FOREIGN KEY (`created_by`)            REFERENCES `sys_users`    (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-visit record with 6-state FSM; one row per visit attempt; is_overdue set by scheduler; blacklist_hit set at registration';

-- -----------------------------------------------------------------------------
-- 6. vsm_emergency_events — Active emergency event log
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_emergency_events` (
    `id`                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT            COMMENT 'Primary key',
    `emergency_type`        ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other')
                                             NOT NULL                           COMMENT 'Type of emergency; Lockdown type sets is_lockdown_active=1 and blocks gate passes',
    `protocol_id`           BIGINT UNSIGNED  NULL     DEFAULT NULL              COMMENT 'FK→vsm_emergency_protocols.id; optional linked SOP template',
    `message`               TEXT             NOT NULL                           COMMENT 'Emergency broadcast message sent to all active staff',
    `affected_zones`        VARCHAR(500)     NULL     DEFAULT NULL              COMMENT 'Affected campus zones; free text',
    `triggered_by`          INT UNSIGNED     NOT NULL                           COMMENT 'FK→sys_users.id; admin or principal who triggered the alert',
    `triggered_at`          TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Immutable trigger timestamp; set on INSERT; not updatable',
    `resolved_at`           TIMESTAMP        NULL     DEFAULT NULL              COMMENT 'Set by admin on resolution; clears lockdown mode',
    `is_lockdown_active`    TINYINT(1)       NOT NULL DEFAULT 0                 COMMENT 'When 1: gate pass generation disabled; check-in screen shows LOCKDOWN banner; new walk-in registration requires admin override (BR-VSM-010)',
    `notification_count`    INT UNSIGNED     NOT NULL DEFAULT 0                 COMMENT 'Count of active sys_users notified; updated by EmergencyBroadcastJob',
    `headcount_initiated`   TINYINT(1)       NOT NULL DEFAULT 0                 COMMENT '1 when ATT module headcount dispatch has been initiated',
    `is_active`             TINYINT(1)       NOT NULL DEFAULT 1                 COMMENT 'Soft enable/disable',
    `created_by`            INT UNSIGNED     NULL     DEFAULT NULL              COMMENT 'FK→sys_users.id',
    `updated_by`            INT UNSIGNED     NULL     DEFAULT NULL              COMMENT 'FK→sys_users.id',
    `created_at`            TIMESTAMP        NULL     DEFAULT NULL              COMMENT 'Record creation timestamp',
    `updated_at`            TIMESTAMP        NULL     DEFAULT NULL              COMMENT 'Record last update timestamp',
    `deleted_at`            TIMESTAMP        NULL     DEFAULT NULL              COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_ee_lockdown`  (`is_lockdown_active`),
    KEY `idx_vsm_ee_triggered` (`triggered_at`),
    KEY `idx_vsm_ee_protocol`  (`protocol_id`),
    KEY `idx_vsm_ee_by`        (`triggered_by`),
    KEY `idx_vsm_ee_created`   (`created_by`),

    CONSTRAINT `fk_vsm_ee_protocol`  FOREIGN KEY (`protocol_id`)  REFERENCES `vsm_emergency_protocols` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_ee_by`        FOREIGN KEY (`triggered_by`) REFERENCES `sys_users`               (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_ee_created`   FOREIGN KEY (`created_by`)   REFERENCES `sys_users`               (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Active emergency events log; is_lockdown_active=1 disables gate pass generation platform-wide';

-- -----------------------------------------------------------------------------
-- 7. vsm_guard_shifts — Guard shift schedules and attendance
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_guard_shifts` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT              COMMENT 'Primary key',
    `guard_user_id`       INT UNSIGNED     NOT NULL                             COMMENT 'FK→sys_users.id; the guard assigned to this shift',
    `shift_date`          DATE             NOT NULL                             COMMENT 'Date of the shift',
    `shift_start_time`    TIME             NOT NULL                             COMMENT 'Scheduled shift start time',
    `shift_end_time`      TIME             NOT NULL                             COMMENT 'Scheduled shift end time',
    `post`                VARCHAR(100)     NOT NULL                             COMMENT 'Guard post assignment; e.g. Main Gate, Back Gate, Lab Block',
    `actual_start_time`   TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Actual clock-in time recorded by guard; NULL until clocked in',
    `actual_end_time`     TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Actual clock-out time recorded by guard; NULL until clocked out',
    `attendance_status`   ENUM('Scheduled','Present','Absent','Late','Early_Departure')
                                           NOT NULL DEFAULT 'Scheduled'         COMMENT 'Scheduled=awaiting; Present=on time; Absent=no show; Late=actual_start > shift_start+15min; Early_Departure=actual_end < shift_end-15min (BR-VSM-007)',
    `notes`               TEXT             NULL     DEFAULT NULL                COMMENT 'Supervisor notes',
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1                   COMMENT 'Soft enable/disable',
    `created_by`          INT UNSIGNED     NULL     DEFAULT NULL                COMMENT 'FK→sys_users.id',
    `updated_by`          INT UNSIGNED     NULL     DEFAULT NULL                COMMENT 'FK→sys_users.id',
    `created_at`          TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Record creation timestamp',
    `updated_at`          TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Record last update timestamp',
    `deleted_at`          TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_vsm_gs_guard_shift` (`guard_user_id`, `shift_date`, `shift_start_time`),
    KEY `idx_vsm_gs_guard`   (`guard_user_id`),
    KEY `idx_vsm_gs_created` (`created_by`),

    CONSTRAINT `fk_vsm_gs_guard`   FOREIGN KEY (`guard_user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_gs_created` FOREIGN KEY (`created_by`)    REFERENCES `sys_users` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Guard shift schedules and attendance; UNIQUE on (guard_user_id, shift_date, shift_start_time) prevents overlap';

-- =============================================================================
-- LAYER 3 — Depends on Layer 2 tables
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 8. vsm_gate_passes — QR gate pass tokens (one per visit)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_gate_passes` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT                   COMMENT 'Primary key',
    `visit_id`       BIGINT UNSIGNED  NOT NULL                                  COMMENT 'FK→vsm_visits.id; UNIQUE — one gate pass per visit (BR-VSM-002)',
    `visitor_id`     BIGINT UNSIGNED  NOT NULL                                  COMMENT 'FK→vsm_visitors.id; denormalised for fast badge rendering',
    `pass_token`     VARCHAR(100)     NOT NULL                                  COMMENT 'UUID v4 token encoded in QR code; UNIQUE; generated via Str::uuid(); never sequential; lookup key at gate (BR-VSM-002)',
    `qr_code_path`   VARCHAR(255)     NULL     DEFAULT NULL                     COMMENT 'File path of QR code image generated by SimpleSoftwareIO; hosted URL embedded in SMS',
    `status`         ENUM('Issued','Used','Expired','Revoked')
                                      NOT NULL DEFAULT 'Issued'                 COMMENT 'Issued=valid; Used=scanned at gate; Expired=expires_at<NOW set by hourly job; Revoked=admin cancelled',
    `issued_at`      TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP        COMMENT 'When pass was generated',
    `expires_at`     TIMESTAMP        NOT NULL                                  COMMENT 'MIN(end of expected_date, issued_at + 24h); server-side comparison only — never trust client (BR-VSM-002)',
    `used_at`        TIMESTAMP        NULL     DEFAULT NULL                     COMMENT 'When QR was scanned at gate; set inside DB::transaction() on check-in',
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1                        COMMENT 'Soft enable/disable',
    `created_by`     INT UNSIGNED     NULL     DEFAULT NULL                     COMMENT 'FK→sys_users.id',
    `updated_by`     INT UNSIGNED     NULL     DEFAULT NULL                     COMMENT 'FK→sys_users.id',
    `created_at`     TIMESTAMP        NULL     DEFAULT NULL                     COMMENT 'Record creation timestamp',
    `updated_at`     TIMESTAMP        NULL     DEFAULT NULL                     COMMENT 'Record last update timestamp',
    `deleted_at`     TIMESTAMP        NULL     DEFAULT NULL                     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_vsm_gp_visit`   (`visit_id`),
    UNIQUE KEY `uq_vsm_gp_token`   (`pass_token`),
    KEY `idx_vsm_gp_visitor`       (`visitor_id`),
    KEY `idx_vsm_gp_expires`       (`expires_at`),
    KEY `idx_vsm_gp_created`       (`created_by`),

    CONSTRAINT `fk_vsm_gp_visit`   FOREIGN KEY (`visit_id`)   REFERENCES `vsm_visits`   (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_gp_visitor` FOREIGN KEY (`visitor_id`) REFERENCES `vsm_visitors` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_gp_created` FOREIGN KEY (`created_by`) REFERENCES `sys_users`    (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='QR gate pass tokens; one per visit; pass_token = UUID v4; expires_at enforced server-side only';

-- -----------------------------------------------------------------------------
-- 9. vsm_pickup_auth — Student pickup authorisation log
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_pickup_auth` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT             COMMENT 'Primary key',
    `visit_id`             BIGINT UNSIGNED  NOT NULL                            COMMENT 'FK→vsm_visits.id; the visit record for this pickup (purpose=StudentPickup)',
    `student_id`           INT UNSIGNED     NOT NULL                            COMMENT 'FK→std_students.id; student being picked up',
    `guardian_name`        VARCHAR(150)     NOT NULL                            COMMENT 'Name of person at gate claiming to pick up student',
    `guardian_mobile`      VARCHAR(20)      NOT NULL                            COMMENT 'Mobile number of person at gate',
    `relationship`         VARCHAR(50)      NULL     DEFAULT NULL               COMMENT 'Stated relationship; e.g. Father, Mother, Uncle',
    `is_authorised`        TINYINT(1)       NOT NULL                            COMMENT '1 = guardian found in std_student_guardian_jnt with can_pickup=1; 0 = not in authorised list (override required — BR-VSM-011)',
    `id_proof_media_id`    INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_media.id; guardian ID proof scanned at gate',
    `override_by`          INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id; supervisor who overrode unauthorised pickup; NULL when is_authorised=1 (BR-VSM-011)',
    `override_reason`      TEXT             NULL     DEFAULT NULL               COMMENT 'Required when override_by is set; explains why supervisor allowed pickup',
    `processed_by`         INT UNSIGNED     NOT NULL                            COMMENT 'FK→sys_users.id; reception staff or guard who processed this pickup',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1                  COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id',
    `updated_by`           INT UNSIGNED     NULL     DEFAULT NULL               COMMENT 'FK→sys_users.id',
    `created_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Record last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     DEFAULT NULL               COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_pa_student`    (`student_id`),
    KEY `idx_vsm_pa_visit`      (`visit_id`),
    KEY `idx_vsm_pa_idproof`    (`id_proof_media_id`),
    KEY `idx_vsm_pa_override`   (`override_by`),
    KEY `idx_vsm_pa_processed`  (`processed_by`),
    KEY `idx_vsm_pa_created`    (`created_by`),

    CONSTRAINT `fk_vsm_pa_visit`      FOREIGN KEY (`visit_id`)          REFERENCES `vsm_visits`    (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_pa_student`    FOREIGN KEY (`student_id`)        REFERENCES `std_students`  (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_pa_idproof`    FOREIGN KEY (`id_proof_media_id`) REFERENCES `sys_media`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_pa_override`   FOREIGN KEY (`override_by`)       REFERENCES `sys_users`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_pa_processed`  FOREIGN KEY (`processed_by`)      REFERENCES `sys_users`     (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_pa_created`    FOREIGN KEY (`created_by`)        REFERENCES `sys_users`     (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student pickup authorisation log; is_authorised=1 if guardian matched std_student_guardian_jnt.can_pickup=1; override required otherwise';

-- -----------------------------------------------------------------------------
-- 10. vsm_contractors — Multi-day contractor/vendor access management
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_contractors` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT              COMMENT 'Primary key',
    `contractor_name`     VARCHAR(150)     NOT NULL                             COMMENT 'Full name of contractor/vendor',
    `company_name`        VARCHAR(150)     NULL     DEFAULT NULL                COMMENT 'Company or agency name',
    `mobile_no`           VARCHAR(20)      NOT NULL                             COMMENT 'Contact mobile; also checked against vsm_blacklist on registration',
    `id_type`             ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other')
                                           NULL     DEFAULT NULL                COMMENT 'ID document type',
    `id_number`           VARCHAR(50)      NULL     DEFAULT NULL                COMMENT 'ID document number',
    `photo_media_id`      INT UNSIGNED     NULL     DEFAULT NULL                COMMENT 'FK→sys_media.id; contractor photo',
    `work_order_no`       VARCHAR(100)     NULL     DEFAULT NULL                COMMENT 'Work order reference number',
    `work_description`    TEXT             NULL     DEFAULT NULL                COMMENT 'Description of work being performed',
    `allowed_zones_json`  JSON             NULL     DEFAULT NULL                COMMENT 'Array of campus zone names contractor is permitted to access; e.g. ["Lab Block","Admin Block"]',
    `access_from`         DATE             NOT NULL                             COMMENT 'Start date of access period',
    `access_until`        DATE             NOT NULL                             COMMENT 'End date of access period; auto-expired by ExpireContractorPassesJob daily',
    `entry_days_json`     JSON             NULL     DEFAULT NULL                COMMENT 'Array of permitted day abbreviations; e.g. ["Mon","Tue","Wed","Thu","Fri"]; NULL = any day within date range (BR-VSM-012)',
    `pass_token`          VARCHAR(100)     NOT NULL                             COMMENT 'UUID v4 token; reusable within date range (differs from single-use visitor pass_token); generated via Str::uuid()',
    `pass_status`         ENUM('Active','Expired','Revoked')
                                           NOT NULL DEFAULT 'Active'            COMMENT 'Active=valid; Expired=auto-set when access_until < TODAY(); Revoked=admin cancelled',
    `entry_count`         INT UNSIGNED     NOT NULL DEFAULT 0                   COMMENT 'Total entries recorded; incremented at application layer (NOT trigger)',
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1                   COMMENT 'Soft enable/disable',
    `created_by`          INT UNSIGNED     NULL     DEFAULT NULL                COMMENT 'FK→sys_users.id',
    `updated_by`          INT UNSIGNED     NULL     DEFAULT NULL                COMMENT 'FK→sys_users.id',
    `created_at`          TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Record creation timestamp',
    `updated_at`          TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Record last update timestamp',
    `deleted_at`          TIMESTAMP        NULL     DEFAULT NULL                COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_vsm_con_token`  (`pass_token`),
    KEY `idx_vsm_con_mobile`       (`mobile_no`),
    KEY `idx_vsm_con_access`       (`access_from`, `access_until`),
    KEY `idx_vsm_con_status`       (`pass_status`),
    KEY `idx_vsm_con_photo`        (`photo_media_id`),
    KEY `idx_vsm_con_created`      (`created_by`),

    CONSTRAINT `fk_vsm_con_photo`   FOREIGN KEY (`photo_media_id`) REFERENCES `sys_media`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_con_created` FOREIGN KEY (`created_by`)     REFERENCES `sys_users`  (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Contractor/vendor multi-day access management; pass_token reusable within date range; entry_days_json restricts allowed days';

-- -----------------------------------------------------------------------------
-- 11. vsm_patrol_rounds — Per-patrol round summary
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_patrol_rounds` (
    `id`                     BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT           COMMENT 'Primary key',
    `guard_user_id`          INT UNSIGNED     NOT NULL                          COMMENT 'FK→sys_users.id; guard conducting the patrol',
    `guard_shift_id`         BIGINT UNSIGNED  NULL     DEFAULT NULL             COMMENT 'FK→vsm_guard_shifts.id; optional link to the guard shift this patrol belongs to',
    `patrol_start_time`      TIMESTAMP        NOT NULL                          COMMENT 'When patrol round was started',
    `patrol_end_time`        TIMESTAMP        NULL     DEFAULT NULL             COMMENT 'When patrol round was completed or marked incomplete; NULL while in progress',
    `checkpoints_total`      TINYINT UNSIGNED NOT NULL DEFAULT 0                COMMENT 'Count of active checkpoints at round start; set by PatrolService::startRound',
    `checkpoints_completed`  TINYINT UNSIGNED NOT NULL DEFAULT 0                COMMENT 'Count of checkpoints scanned so far; incremented on each valid scan',
    `completion_pct`         DECIMAL(5,2)     NOT NULL DEFAULT 0.00             COMMENT 'Completion percentage = (checkpoints_completed / checkpoints_total) × 100; computed at application layer (NOT generated column)',
    `status`                 ENUM('In_Progress','Completed','Incomplete')
                                              NOT NULL DEFAULT 'In_Progress'    COMMENT 'In_Progress=active patrol; Completed=all or >=80% scanned; Incomplete=<80% completion at time of finish (BR-VSM-006)',
    `notes`                  TEXT             NULL     DEFAULT NULL             COMMENT 'Supervisor or guard notes',
    `is_active`              TINYINT(1)       NOT NULL DEFAULT 1                COMMENT 'Soft enable/disable',
    `created_by`             INT UNSIGNED     NULL     DEFAULT NULL             COMMENT 'FK→sys_users.id',
    `updated_by`             INT UNSIGNED     NULL     DEFAULT NULL             COMMENT 'FK→sys_users.id',
    `created_at`             TIMESTAMP        NULL     DEFAULT NULL             COMMENT 'Record creation timestamp',
    `updated_at`             TIMESTAMP        NULL     DEFAULT NULL             COMMENT 'Record last update timestamp',
    `deleted_at`             TIMESTAMP        NULL     DEFAULT NULL             COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_pr_guard`   (`guard_user_id`),
    KEY `idx_vsm_pr_shift`   (`guard_shift_id`),
    KEY `idx_vsm_pr_created` (`created_by`),

    CONSTRAINT `fk_vsm_pr_guard`   FOREIGN KEY (`guard_user_id`)  REFERENCES `sys_users`       (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_vsm_pr_shift`   FOREIGN KEY (`guard_shift_id`) REFERENCES `vsm_guard_shifts`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsm_pr_created` FOREIGN KEY (`created_by`)     REFERENCES `sys_users`       (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-patrol round summary; completion_pct computed by PatrolService; <80% triggers Incomplete status and admin alert';

-- -----------------------------------------------------------------------------
-- 12. vsm_cctv_events — Inbound webhook events from CCTV systems (IMMUTABLE)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_cctv_events` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT                 COMMENT 'Primary key',
    `camera_id`        VARCHAR(100)     NOT NULL                                COMMENT 'External camera identifier provided by CCTV system',
    `event_type`       VARCHAR(100)     NOT NULL                                COMMENT 'Event type from CCTV system; e.g. motion_detected, gate_open, person_detected',
    `event_timestamp`  TIMESTAMP        NOT NULL                                COMMENT 'Event timestamp from CCTV system payload',
    `snapshot_url`     VARCHAR(500)     NULL     DEFAULT NULL                   COMMENT 'External snapshot URL provided by CCTV system; may expire',
    `linked_visit_id`  BIGINT UNSIGNED  NULL     DEFAULT NULL                   COMMENT 'FK→vsm_visits.id; auto-linked when camera is a gate camera and there is an active visit within the check-in window',
    `raw_payload_json` JSON             NULL     DEFAULT NULL                   COMMENT 'Full raw webhook payload stored for audit and debugging',
    `created_at`       TIMESTAMP        NULL     DEFAULT CURRENT_TIMESTAMP      COMMENT 'Record insertion timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_ce_camera_time` (`camera_id`, `event_timestamp`),
    KEY `idx_vsm_ce_visit`       (`linked_visit_id`),

    CONSTRAINT `fk_vsm_ce_visit` FOREIGN KEY (`linked_visit_id`) REFERENCES `vsm_visits` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable inbound webhook event log from CCTV systems; no updated_at/deleted_at; hardware integration out of scope (webhook ingestion only)';

-- =============================================================================
-- LAYER 4 — Depends on Layer 3 tables
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 13. vsm_patrol_checkpoint_log — Per-checkpoint scan within a round (IMMUTABLE)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `vsm_patrol_checkpoint_log` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT                 COMMENT 'Primary key',
    `patrol_round_id`  BIGINT UNSIGNED  NOT NULL                                COMMENT 'FK→vsm_patrol_rounds.id; the patrol round this scan belongs to',
    `checkpoint_id`    BIGINT UNSIGNED  NOT NULL                                COMMENT 'FK→vsm_patrol_checkpoints.id; the checkpoint that was scanned',
    `scanned_at`       TIMESTAMP        NOT NULL                                COMMENT 'Immutable timestamp when guard scanned the checkpoint QR; set on INSERT',
    `notes`            TEXT             NULL     DEFAULT NULL                   COMMENT 'Optional guard note at checkpoint',
    `created_at`       TIMESTAMP        NULL     DEFAULT CURRENT_TIMESTAMP      COMMENT 'Record insertion timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_vsm_pcl_round`      (`patrol_round_id`),
    KEY `idx_vsm_pcl_checkpoint` (`checkpoint_id`),

    CONSTRAINT `fk_vsm_pcl_round`      FOREIGN KEY (`patrol_round_id`) REFERENCES `vsm_patrol_rounds`      (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vsm_pcl_checkpoint` FOREIGN KEY (`checkpoint_id`)   REFERENCES `vsm_patrol_checkpoints` (`id`) ON DELETE RESTRICT

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable per-checkpoint scan log; one row per checkpoint scan within a patrol round; no updated_at/deleted_at/is_active';

-- =============================================================================
-- END OF VSM DDL
-- Tables created: 13
-- Layer 1 (4): vsm_visitors, vsm_blacklist, vsm_emergency_protocols, vsm_patrol_checkpoints
-- Layer 2 (3): vsm_visits, vsm_emergency_events, vsm_guard_shifts
-- Layer 3 (5): vsm_gate_passes, vsm_pickup_auth, vsm_contractors, vsm_patrol_rounds, vsm_cctv_events
-- Layer 4 (1): vsm_patrol_checkpoint_log
-- =============================================================================
