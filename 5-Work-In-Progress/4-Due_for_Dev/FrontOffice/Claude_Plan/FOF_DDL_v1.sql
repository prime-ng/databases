-- =============================================================================
-- FOF — Front Office Module DDL
-- Module: FrontOffice (Modules\FrontOffice)
-- Table Prefix: fof_* (22 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-27
-- Based on: FOF_FrontOffice_Requirement.md v2
-- Sub-Modules: Core Registers, Communication, Appointments & Support,
--              Complaints & Feedback, Communication Logs
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================================
-- LAYER 1 — No fof_* dependencies (refs cross-module only)
-- 7 tables: visitor_purposes, emergency_contacts, notices, school_events,
--           email_templates, feedback_forms, key_register
-- =============================================================================

-- 1. fof_visitor_purposes — Visitor visit purpose lookup master (seeded)
CREATE TABLE IF NOT EXISTS `fof_visitor_purposes` (
  `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name`                VARCHAR(100)     NOT NULL COMMENT 'Display name, e.g., Parent Meeting',
  `code`                VARCHAR(30)      NOT NULL COMMENT 'Programmatic lookup key, e.g., PARENT_MTG',
  `is_government_visit` TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = permanent retention; delete blocked by VisitorPolicy per BR-FOF-007',
  `sort_order`          TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Display order in dropdown; lower = first',
  `is_active`           TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`          BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_vp_code` (`code`),
  KEY `idx_fof_vp_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Visitor purpose lookup master — seeded with 8 purposes including GOVT_INSPECTION';


-- 2. fof_emergency_contacts — External emergency contact directory
CREATE TABLE IF NOT EXISTS `fof_emergency_contacts` (
  `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `contact_name`    VARCHAR(100)     NOT NULL COMMENT 'Name of contact or organization',
  `organization`    VARCHAR(150)     NULL     COMMENT 'Organization name',
  `contact_type`    ENUM('Hospital','Police','Fire','Ambulance','Transport','Utility','Parent_Emergency','Government','Other') NOT NULL COMMENT 'Category for grouping in UI',
  `primary_phone`   VARCHAR(15)      NOT NULL COMMENT 'Primary phone number',
  `alternate_phone` VARCHAR(15)      NULL     COMMENT 'Backup phone number',
  `address`         VARCHAR(200)     NULL     COMMENT 'Physical address',
  `notes`           TEXT             NULL     COMMENT 'Additional info',
  `sort_order`      TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Display order within type group',
  `is_active`       TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`      BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`      BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`      TIMESTAMP NULL,
  `updated_at`      TIMESTAMP NULL,
  `deleted_at`      TIMESTAMP NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_ec_type` (`contact_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='External emergency contact directory (hospital, police, fire, transport)';


-- 3. fof_notices — Digital notice board entries
CREATE TABLE IF NOT EXISTS `fof_notices` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `title`               VARCHAR(200)    NOT NULL COMMENT 'Notice heading',
  `content`             LONGTEXT        NOT NULL COMMENT 'Full notice body (rich text HTML)',
  `category`            ENUM('Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other') NOT NULL COMMENT 'Notice category',
  `audience`            ENUM('All','Students','Staff','Parents') NOT NULL DEFAULT 'All' COMMENT 'Target audience for visibility',
  `display_from`        DATE            NOT NULL COMMENT 'Notice visible from this date',
  `display_until`       DATE            NULL     COMMENT 'NULL = no expiry; bypassed when is_emergency=1',
  `is_pinned`           TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = always shown at top of board',
  `is_emergency`        TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = bypasses display date constraints per BR-FOF-014',
  `attachment_media_id` INT UNSIGNED    NULL     COMMENT 'FK sys_media.id (INT UNSIGNED) — optional attachment',
  `status`              ENUM('Active','Archived') NOT NULL DEFAULT 'Active' COMMENT 'Active = displayed; Archived = hidden',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_ntc_display`    (`display_from`, `display_until`, `status`),
  KEY `idx_fof_ntc_emergency`  (`is_emergency`),
  KEY `idx_fof_ntc_audience`   (`audience`),
  KEY `idx_fof_ntc_pinned`     (`is_pinned`),
  KEY `idx_fof_ntc_attachment` (`attachment_media_id`),
  CONSTRAINT `fk_fof_ntc_attachment_media_id` FOREIGN KEY (`attachment_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Digital notice board — pinning, emergency bypass, display date control';


-- 4. fof_school_events — Public-facing school calendar events
CREATE TABLE IF NOT EXISTS `fof_school_events` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `event_name`        VARCHAR(200)    NOT NULL COMMENT 'Event title',
  `event_type`        ENUM('Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other') NOT NULL COMMENT 'Event category',
  `start_date`        DATE            NOT NULL COMMENT 'Event start date',
  `end_date`          DATE            NOT NULL COMMENT 'Event end date; must be >= start_date',
  `description`       TEXT            NULL     COMMENT 'Event description',
  `venue`             VARCHAR(200)    NULL     COMMENT 'Event location or venue name',
  `audience`          ENUM('All','Students','Staff','Parents') NOT NULL DEFAULT 'All' COMMENT 'Target audience',
  `is_public`         TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = visible on public-facing school website',
  `notification_sent` TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = NTF blast has been dispatched',
  `is_active`         TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`        BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`        BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`        TIMESTAMP NULL,
  `updated_at`        TIMESTAMP NULL,
  `deleted_at`        TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_se_date_type` (`start_date`, `event_type`),
  KEY `idx_fof_se_public`    (`is_public`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Public-facing school calendar events (Sports Day, PTM, Annual Function)';


-- 5. fof_email_templates — Reusable email templates with placeholder support
CREATE TABLE IF NOT EXISTS `fof_email_templates` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name`       VARCHAR(100)    NOT NULL COMMENT 'Template name for internal reference',
  `subject`    VARCHAR(300)    NOT NULL COMMENT 'Email subject; may contain {{placeholder}} tokens',
  `body`       LONGTEXT        NOT NULL COMMENT 'HTML body with {{placeholder}} support',
  `module`     VARCHAR(50)     NULL     COMMENT 'Source module, e.g., FrontOffice',
  `is_active`  TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by` BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_et_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Reusable email templates for bulk communication';


-- 6. fof_feedback_forms — Feedback form definitions (MCQ/rating/text questions)
CREATE TABLE IF NOT EXISTS `fof_feedback_forms` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `title`                VARCHAR(200)    NOT NULL COMMENT 'Form title shown to respondents',
  `description`          TEXT            NULL     COMMENT 'Form instructions or description',
  `questions_json`       JSON            NOT NULL COMMENT 'Array of questions: [{type, question, options}]',
  `token`                VARCHAR(64)     NOT NULL COMMENT 'Public access token for GET /feedback/{token} URL',
  `is_anonymous_allowed` TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = anonymous submissions accepted per BR-FOF-010',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable; inactive forms show closed page',
  `created_by`           BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`           BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`           TIMESTAMP NULL,
  `updated_at`           TIMESTAMP NULL,
  `deleted_at`           TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_ff_token`  (`token`),
  KEY `idx_fof_ff_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Feedback form definitions with JSON question schema and public token URL';


-- 7. fof_key_register — Physical key issue/return tracking
CREATE TABLE IF NOT EXISTS `fof_key_register` (
  `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `key_label`          VARCHAR(100)    NOT NULL COMMENT 'Descriptive label, e.g., Science Lab A Key',
  `key_tag_number`     VARCHAR(30)     NOT NULL COMMENT 'Physical tag or number printed on the key',
  `key_type`           ENUM('Room','Lab','Vehicle','Cabinet','Store','Other') NOT NULL COMMENT 'Key category',
  `issued_to_user_id`  INT UNSIGNED    NULL     COMMENT 'FK sys_users.id; NULL = key is currently available',
  `purpose`            VARCHAR(200)    NULL     COMMENT 'Stated reason for issuing the key',
  `issued_at`          DATETIME        NULL     COMMENT 'Issue timestamp',
  `expected_return_at` DATETIME        NULL     COMMENT 'Expected return time',
  `returned_at`        DATETIME        NULL     COMMENT 'Actual return timestamp',
  `status`             ENUM('Available','Issued','Overdue','Lost') NOT NULL DEFAULT 'Available' COMMENT 'Key status; Overdue auto-set when past expected_return_at',
  `is_active`          TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`         BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`         BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`         TIMESTAMP NULL,
  `updated_at`         TIMESTAMP NULL,
  `deleted_at`         TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_kr_status_user` (`status`, `issued_to_user_id`),
  KEY `idx_fof_kr_issued_to`   (`issued_to_user_id`),
  CONSTRAINT `fk_fof_kr_issued_to_user_id` FOREIGN KEY (`issued_to_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Physical key issue/return tracking with overdue flag';


-- =============================================================================
-- LAYER 2 — Depends on Layer 1 + cross-module refs
-- 10 tables: visitors, gate_passes, early_departures, phone_diary,
--            postal_register, dispatch_register, appointments, lost_found,
--            certificate_requests, complaints
-- =============================================================================

-- 8. fof_visitors — Visitor register (digital replacement for paper visitor book)
CREATE TABLE IF NOT EXISTS `fof_visitors` (
  `id`                 BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `pass_number`        VARCHAR(25)      NOT NULL COMMENT 'Auto-generated VP-YYYYMMDD-NNN; unique per day',
  `vsm_visitor_id`     BIGINT UNSIGNED  NULL     COMMENT 'vsm_visitors.id — nullable; optional pre-registered visitor handoff from VSM gate security (VSM module pending; FK omitted until VSM created)',
  `visitor_name`       VARCHAR(100)     NOT NULL COMMENT 'Full name of visitor',
  `visitor_mobile`     VARCHAR(15)      NOT NULL COMMENT 'Primary mobile number',
  `visitor_email`      VARCHAR(100)     NULL     COMMENT 'Optional visitor email address',
  `id_proof_type`      ENUM('Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other') NULL COMMENT 'Government-issued ID type per BR-FOF-001',
  `id_proof_number`    VARCHAR(50)      NULL     COMMENT 'Full ID number stored; last 4 shown in UI per BR-FOF-015',
  `address`            VARCHAR(200)     NULL     COMMENT 'Visitor home or work address',
  `organization`       VARCHAR(100)     NULL     COMMENT 'Visitor company or organization name',
  `purpose_id`         BIGINT UNSIGNED  NOT NULL COMMENT 'FK fof_visitor_purposes.id — visit purpose required',
  `person_to_meet`     VARCHAR(100)     NULL     COMMENT 'Name of staff member or department to meet',
  `meet_user_id`       INT UNSIGNED     NULL     COMMENT 'FK sys_users.id — linked staff member (optional)',
  `vehicle_number`     VARCHAR(20)      NULL     COMMENT 'Vehicle registration number if applicable',
  `accompanying_count` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of additional accompanying persons',
  `photo_media_id`     INT UNSIGNED     NULL     COMMENT 'FK sys_media.id (INT UNSIGNED) — optional webcam photo',
  `in_time`            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Registration timestamp; set at creation',
  `out_time`           DATETIME         NULL     COMMENT 'Checkout timestamp; NULL until checked out',
  `status`             ENUM('In','Out','Overstay') NOT NULL DEFAULT 'In' COMMENT 'In=on campus; Out=checked out; Overstay=not checked out by closing time per BR-FOF-002',
  `notes`              TEXT             NULL     COMMENT 'Additional remarks',
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`         BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`         BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`         TIMESTAMP NULL,
  `updated_at`         TIMESTAMP NULL,
  `deleted_at`         TIMESTAMP NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_vis_pass_number` (`pass_number`),
  KEY `idx_fof_vis_date`       ((DATE(`in_time`))),
  KEY `idx_fof_vis_status`     (`status`),
  KEY `idx_fof_vis_mobile`     (`visitor_mobile`),
  KEY `idx_fof_vis_purpose`    (`purpose_id`),
  KEY `idx_fof_vis_vsm`        (`vsm_visitor_id`),
  KEY `idx_fof_vis_meet_user`  (`meet_user_id`),
  KEY `idx_fof_vis_photo`      (`photo_media_id`),
  CONSTRAINT `fk_fof_vis_purpose_id`   FOREIGN KEY (`purpose_id`)   REFERENCES `fof_visitor_purposes` (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_vis_meet_user_id` FOREIGN KEY (`meet_user_id`) REFERENCES `sys_users`             (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_vis_photo_media_id` FOREIGN KEY (`photo_media_id`) REFERENCES `sys_media`         (`id`) ON DELETE SET NULL ON UPDATE CASCADE
  -- vsm_visitor_id FK omitted: vsm_visitors table does not yet exist (VSM module is pending)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Visitor register — auto-generates VP-YYYYMMDD-NNN; government visits permanently retained per BR-FOF-007';


-- 9. fof_gate_passes — Student/staff early exit authorization
CREATE TABLE IF NOT EXISTS `fof_gate_passes` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `pass_number`          VARCHAR(25)     NOT NULL COMMENT 'Auto-generated GP-YYYYMMDD-NNN',
  `person_type`          ENUM('Student','Staff') NOT NULL COMMENT 'Determines which FK is populated: student_id or staff_user_id',
  `student_id`           INT UNSIGNED    NULL     COMMENT 'FK std_students.id (INT UNSIGNED); NULL for staff passes',
  `staff_user_id`        INT UNSIGNED    NULL     COMMENT 'FK sys_users.id (INT UNSIGNED); NULL for student passes',
  `purpose`              ENUM('Medical','Personal','Official','Sports','Family_Emergency','Other') NOT NULL COMMENT 'Reason for early exit',
  `purpose_details`      VARCHAR(200)    NULL     COMMENT 'Free-text elaboration of purpose',
  `exit_time`            DATETIME        NULL     COMMENT 'Actual exit timestamp; set when marking Exited',
  `expected_return_time` DATETIME        NULL     COMMENT 'Stated expected return time',
  `actual_return_time`   DATETIME        NULL     COMMENT 'Actual return timestamp; set when marking Returned',
  `parent_notified`      TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = NTF dispatched to parent (student passes per BR-FOF-003)',
  `status`               ENUM('Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled') NOT NULL DEFAULT 'Pending_Approval' COMMENT 'Gate pass lifecycle state',
  `approved_by`          INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — Principal or HOD who approved or rejected',
  `approved_at`          DATETIME        NULL     COMMENT 'Approval or rejection timestamp',
  `rejection_reason`     TEXT            NULL     COMMENT 'Required when status = Rejected',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`           BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`           TIMESTAMP NULL,
  `updated_at`           TIMESTAMP NULL,
  `deleted_at`           TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_gp_pass_number` (`pass_number`),
  KEY `idx_fof_gp_student`     (`student_id`),
  KEY `idx_fof_gp_staff`       (`staff_user_id`),
  KEY `idx_fof_gp_status`      (`status`),
  KEY `idx_fof_gp_approved_by` (`approved_by`),
  CONSTRAINT `fk_fof_gp_student_id`    FOREIGN KEY (`student_id`)   REFERENCES `std_students` (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_gp_staff_user_id` FOREIGN KEY (`staff_user_id`) REFERENCES `sys_users`  (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_gp_approved_by`   FOREIGN KEY (`approved_by`)  REFERENCES `sys_users`   (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student/staff early exit gate pass; approval workflow; parent NTF per BR-FOF-003; BR-FOF-004 one active pass rule';


-- 10. fof_early_departures — Student mid-day parent pickup (feeds ATT module)
CREATE TABLE IF NOT EXISTS `fof_early_departures` (
  `id`                         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `departure_number`           VARCHAR(25)     NOT NULL COMMENT 'Auto-generated ED-YYYYMMDD-NNN',
  `student_id`                 INT UNSIGNED    NOT NULL COMMENT 'FK std_students.id (INT UNSIGNED)',
  `departure_time`             DATETIME        NOT NULL COMMENT 'Time student is collected by parent/guardian',
  `reason`                     ENUM('Medical','Family_Emergency','Event','Bereavement','Other') NOT NULL COMMENT 'Departure reason',
  `reason_details`             VARCHAR(200)    NULL     COMMENT 'Optional elaboration of reason',
  `collecting_person_name`     VARCHAR(100)    NOT NULL COMMENT 'Name of collecting adult (security audit trail)',
  `collecting_person_relation` ENUM('Father','Mother','Guardian','Sibling','Other') NOT NULL COMMENT 'Relation of collector to student',
  `collecting_id_proof_type`   ENUM('Aadhar','Driving_License','Passport','Other') NULL COMMENT 'ID proof type of collecting person',
  `collecting_id_proof_number` VARCHAR(50)     NULL     COMMENT 'ID proof number of collecting person',
  `parent_authorized`          TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = parent verbally or written authorized the pickup',
  `att_sync_status`            ENUM('Pending','Synced','Failed') NOT NULL DEFAULT 'Pending' COMMENT 'ATT module sync status per BR-FOF-013; silent failure not acceptable',
  `att_synced_at`              DATETIME        NULL     COMMENT 'Timestamp when ATT sync succeeded',
  `notes`                      TEXT            NULL     COMMENT 'Additional remarks',
  `is_active`                  TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`                 BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`                 BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`                 TIMESTAMP NULL,
  `updated_at`                 TIMESTAMP NULL,
  `deleted_at`                 TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_ed_departure_number` (`departure_number`),
  KEY `idx_fof_ed_student`  (`student_id`),
  KEY `idx_fof_ed_date`     ((DATE(`departure_time`))),
  KEY `idx_fof_ed_att_sync` (`att_sync_status`),
  CONSTRAINT `fk_fof_ed_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student mid-day parent pickup; att_sync_status tracks ATT module sync; retry job on failure per BR-FOF-013';


-- 11. fof_phone_diary — Incoming/outgoing call log
CREATE TABLE IF NOT EXISTS `fof_phone_diary` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `call_type`           ENUM('Incoming','Outgoing') NOT NULL COMMENT 'Direction of call',
  `call_date`           DATE            NOT NULL COMMENT 'Date of call',
  `call_time`           TIME            NOT NULL COMMENT 'Time of call',
  `caller_name`         VARCHAR(100)    NOT NULL COMMENT 'Caller name (Incoming) or person called (Outgoing)',
  `caller_number`       VARCHAR(15)     NULL     COMMENT 'Phone number of caller',
  `caller_organization` VARCHAR(100)    NULL     COMMENT 'Organization of caller or recipient',
  `recipient_name`      VARCHAR(100)    NULL     COMMENT 'Name of staff who took or made the call',
  `recipient_user_id`   INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — linked staff member (optional)',
  `purpose`             VARCHAR(200)    NOT NULL COMMENT 'Call purpose summary',
  `message`             TEXT            NULL     COMMENT 'Full call notes',
  `action_required`     TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = follow-up action is pending',
  `action_notes`        TEXT            NULL     COMMENT 'Details of required action',
  `action_completed`    TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = action has been resolved',
  `logged_by`           INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff who logged the call',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_pd_date_type`  (`call_date`, `call_type`),
  KEY `idx_fof_pd_recipient`  (`recipient_user_id`),
  KEY `idx_fof_pd_action`     (`action_required`),
  KEY `idx_fof_pd_logged_by`  (`logged_by`),
  CONSTRAINT `fk_fof_pd_recipient_user_id` FOREIGN KEY (`recipient_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_pd_logged_by`         FOREIGN KEY (`logged_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Incoming/outgoing phone call log with action-required flag and follow-up tracking';


-- 12. fof_postal_register — Inward/outward mail and courier register
CREATE TABLE IF NOT EXISTS `fof_postal_register` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `postal_type`         ENUM('Inward','Outward') NOT NULL COMMENT 'Direction of mail',
  `postal_number`       VARCHAR(30)     NOT NULL COMMENT 'Auto-generated IN-YYYY-NNNN (Inward) or OUT-YYYY-NNNN (Outward)',
  `postal_date`         DATE            NOT NULL COMMENT 'Date received or dispatched',
  `sender_name`         VARCHAR(100)    NULL     COMMENT 'Sender name (Inward records)',
  `sender_address`      VARCHAR(200)    NULL     COMMENT 'Sender address',
  `recipient_name`      VARCHAR(100)    NULL     COMMENT 'Recipient name (Outward records)',
  `recipient_address`   VARCHAR(200)    NULL     COMMENT 'Recipient address',
  `document_type`       ENUM('Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other') NOT NULL COMMENT 'Type of postal item',
  `subject`             VARCHAR(200)    NOT NULL COMMENT 'Brief description of contents',
  `courier_company`     VARCHAR(100)    NULL     COMMENT 'Courier service name',
  `tracking_number`     VARCHAR(100)    NULL     COMMENT 'Courier tracking number',
  `department`          VARCHAR(100)    NULL     COMMENT 'School department concerned',
  `assigned_to_user_id` INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff assigned to handle or follow up',
  `acknowledgement_by`  VARCHAR(100)    NULL     COMMENT 'Name of person who acknowledged receipt',
  `acknowledged_at`     DATETIME        NULL     COMMENT 'Acknowledgement timestamp; once set record is locked per BR-FOF-009',
  `remarks`             TEXT            NULL     COMMENT 'Additional notes',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_pr_postal_number` (`postal_number`),
  KEY `idx_fof_pr_type_date` (`postal_type`, `postal_date`),
  KEY `idx_fof_pr_assigned`  (`assigned_to_user_id`),
  CONSTRAINT `fk_fof_pr_assigned_to_user_id` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Inward/outward postal and courier register; record locked after acknowledgement per BR-FOF-009';


-- 13. fof_dispatch_register — Official outgoing correspondence log
CREATE TABLE IF NOT EXISTS `fof_dispatch_register` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `dispatch_number`   VARCHAR(30)     NOT NULL COMMENT 'Auto-generated DSP-YYYY-NNNN',
  `dispatch_date`     DATE            NOT NULL COMMENT 'Date of dispatch',
  `addressee_name`    VARCHAR(100)    NOT NULL COMMENT 'Recipient name or organization',
  `addressee_address` VARCHAR(200)    NULL     COMMENT 'Recipient address',
  `subject`           VARCHAR(200)    NOT NULL COMMENT 'Subject or brief description of document',
  `document_type`     ENUM('Letter','Notice','Legal','Certificate','Report','Circular','Other') NOT NULL COMMENT 'Type of document dispatched',
  `dispatch_mode`     ENUM('Hand','Post','Courier','Email','Fax') NOT NULL COMMENT 'Delivery method',
  `reference_number`  VARCHAR(100)    NULL     COMMENT 'Internal or external reference number',
  `copy_retained`     TINYINT(1)      NOT NULL DEFAULT 1 COMMENT '1 = copy kept at school',
  `dispatched_by`     INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff who dispatched',
  `remarks`           TEXT            NULL     COMMENT 'Additional notes',
  `is_active`         TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`        BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`        BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`        TIMESTAMP NULL,
  `updated_at`        TIMESTAMP NULL,
  `deleted_at`        TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_dr_dispatch_number` (`dispatch_number`),
  KEY `idx_fof_dr_date`         (`dispatch_date`),
  KEY `idx_fof_dr_dispatched_by` (`dispatched_by`),
  CONSTRAINT `fk_fof_dr_dispatched_by` FOREIGN KEY (`dispatched_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Official outgoing correspondence dispatch log; DSP-YYYY-NNNN auto-numbering';


-- 14. fof_appointments — Meeting scheduling with slot conflict check
CREATE TABLE IF NOT EXISTS `fof_appointments` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `appointment_number`  VARCHAR(25)     NOT NULL COMMENT 'Auto-generated APT-YYYYMMDD-NNN',
  `appointment_type`    ENUM('Parent_Teacher_Meeting','Principal_Meeting','Grievance','Admission_Enquiry','Other') NOT NULL COMMENT 'Type of meeting',
  `with_user_id`        INT UNSIGNED    NOT NULL COMMENT 'FK sys_users.id — staff member being met',
  `visitor_name`        VARCHAR(100)    NOT NULL COMMENT 'Visitor or parent name',
  `visitor_mobile`      VARCHAR(15)     NOT NULL COMMENT 'Contact number of visitor',
  `visitor_email`       VARCHAR(100)    NULL     COMMENT 'Optional visitor email',
  `purpose`             VARCHAR(300)    NOT NULL COMMENT 'Meeting agenda or purpose',
  `appointment_date`    DATE            NOT NULL COMMENT 'Scheduled meeting date',
  `start_time`          TIME            NOT NULL COMMENT 'Slot start time',
  `end_time`            TIME            NOT NULL COMMENT 'Slot end time; must be > start_time',
  `status`              ENUM('Pending','Confirmed','Completed','Cancelled','No_Show') NOT NULL DEFAULT 'Pending' COMMENT 'Appointment lifecycle status',
  `confirmed_by`        INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff who confirmed',
  `confirmed_at`        DATETIME        NULL     COMMENT 'Confirmation timestamp',
  `cancellation_reason` VARCHAR(300)    NULL     COMMENT 'Required when status = Cancelled',
  `notes`               TEXT            NULL     COMMENT 'Pre or post meeting notes',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_apt_appointment_number` (`appointment_number`),
  KEY `idx_fof_apt_with_user`   (`with_user_id`),
  KEY `idx_fof_apt_date`        (`appointment_date`),
  KEY `idx_fof_apt_status`      (`status`),
  KEY `idx_fof_apt_confirmed_by` (`confirmed_by`),
  KEY `idx_fof_apt_slot`        (`with_user_id`, `appointment_date`, `start_time`, `end_time`),
  CONSTRAINT `fk_fof_apt_with_user_id` FOREIGN KEY (`with_user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_apt_confirmed_by` FOREIGN KEY (`confirmed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Appointment scheduling; slot conflict checked via idx_fof_apt_slot; APT-YYYYMMDD-NNN auto-numbering';


-- 15. fof_lost_found — Lost and found item register
CREATE TABLE IF NOT EXISTS `fof_lost_found` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `item_number`      VARCHAR(25)     NOT NULL COMMENT 'Auto-generated LF-YYYY-NNNN',
  `item_description` VARCHAR(300)    NOT NULL COMMENT 'Description of found item',
  `category`         ENUM('Electronics','Clothing','Stationery','ID_Card','Money','Jewellery','Books','Sports','Other') NOT NULL COMMENT 'Item category',
  `found_date`       DATE            NOT NULL COMMENT 'Date item was found',
  `found_location`   VARCHAR(200)    NOT NULL COMMENT 'Where on campus item was found',
  `found_by_name`    VARCHAR(100)    NOT NULL COMMENT 'Name of person who found the item',
  `found_by_user_id` INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — linked user if finder is staff',
  `photo_media_id`   INT UNSIGNED    NULL     COMMENT 'FK sys_media.id (INT UNSIGNED) — photo of item',
  `status`           ENUM('Unclaimed','Claimed','Disposed','Returned_to_Authority') NOT NULL DEFAULT 'Unclaimed' COMMENT 'Item disposition status',
  `claimant_name`    VARCHAR(100)    NULL     COMMENT 'Name of person claiming item',
  `claimant_contact` VARCHAR(15)     NULL     COMMENT 'Contact number of claimant',
  `claimed_date`     DATE            NULL     COMMENT 'Date item was claimed',
  `disposal_notes`   TEXT            NULL     COMMENT 'Notes when Disposed or Returned to Authority',
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`       BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`       TIMESTAMP NULL,
  `updated_at`       TIMESTAMP NULL,
  `deleted_at`       TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_lf_item_number` (`item_number`),
  KEY `idx_fof_lf_status`      (`status`),
  KEY `idx_fof_lf_found_date`  (`found_date`),
  KEY `idx_fof_lf_found_by`    (`found_by_user_id`),
  KEY `idx_fof_lf_photo`       (`photo_media_id`),
  CONSTRAINT `fk_fof_lf_found_by_user_id` FOREIGN KEY (`found_by_user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_lf_photo_media_id`   FOREIGN KEY (`photo_media_id`)   REFERENCES `sys_media`  (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Lost and found item register; LF-YYYY-NNNN auto-numbering';


-- 16. fof_certificate_requests — Certificate request with multi-stage approval and PDF issuance
CREATE TABLE IF NOT EXISTS `fof_certificate_requests` (
  `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `request_number`    VARCHAR(25)      NOT NULL COMMENT 'Auto-generated CERT-YYYY-NNNNN',
  `student_id`        INT UNSIGNED     NOT NULL COMMENT 'FK std_students.id (INT UNSIGNED)',
  `cert_type`         ENUM('Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other') NOT NULL COMMENT 'Certificate type; TC_Copy and Migration require FIN fee clearance per BR-FOF-005',
  `purpose`           VARCHAR(200)     NOT NULL COMMENT 'Stated purpose of request',
  `copies_requested`  TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Number of copies; 1 to 5',
  `is_urgent`         TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = escalates approval priority',
  `applicant_name`    VARCHAR(100)     NULL     COMMENT 'Name of person requesting (parent or student)',
  `applicant_contact` VARCHAR(15)      NULL     COMMENT 'Contact number of applicant',
  `stages_json`       JSON             NULL     COMMENT 'Multi-stage approval history: [{stage, status, by, at, remarks}]',
  `status`            ENUM('Pending_Approval','Approved','Rejected','Issued','Cancelled') NOT NULL DEFAULT 'Pending_Approval' COMMENT 'Certificate request lifecycle status',
  `approved_by`       INT UNSIGNED     NULL     COMMENT 'FK sys_users.id — approving authority',
  `approved_at`       DATETIME         NULL     COMMENT 'Approval timestamp',
  `rejection_reason`  TEXT             NULL     COMMENT 'Required when status = Rejected',
  `cert_number`       VARCHAR(30)      NULL     COMMENT 'BON-YYYY-NNN etc.; NULL until issued; UNIQUE enforces BR-FOF-006; MySQL UNIQUE allows multiple NULLs',
  `issued_at`         DATETIME         NULL     COMMENT 'Certificate issuance timestamp',
  `issued_by`         INT UNSIGNED     NULL     COMMENT 'FK sys_users.id — staff who issued the certificate',
  `issued_to`         VARCHAR(100)     NULL     COMMENT 'Receiver name; may differ from applicant',
  `media_id`          INT UNSIGNED     NULL     COMMENT 'FK sys_media.id (INT UNSIGNED) — generated PDF stored via DomPDF',
  `is_active`         TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`        BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`        BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`        TIMESTAMP NULL,
  `updated_at`        TIMESTAMP NULL,
  `deleted_at`        TIMESTAMP NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_cr_request_number` (`request_number`),
  UNIQUE KEY `uq_fof_cr_cert_number`    (`cert_number`),
  KEY `idx_fof_cr_student`    (`student_id`),
  KEY `idx_fof_cr_status`     (`status`),
  KEY `idx_fof_cr_cert_type`  (`cert_type`),
  KEY `idx_fof_cr_approved_by` (`approved_by`),
  KEY `idx_fof_cr_issued_by`  (`issued_by`),
  KEY `idx_fof_cr_media`      (`media_id`),
  CONSTRAINT `fk_fof_cr_student_id`  FOREIGN KEY (`student_id`)  REFERENCES `std_students` (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cr_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`    (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cr_issued_by`   FOREIGN KEY (`issued_by`)   REFERENCES `sys_users`    (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cr_media_id`    FOREIGN KEY (`media_id`)    REFERENCES `sys_media`    (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Certificate request register — Bonafide/Character/TC/Migration; DomPDF issuance; cert_number UNIQUE NULL';


-- 17. fof_complaints — Front-office lightweight complaint intake
CREATE TABLE IF NOT EXISTS `fof_complaints` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `complaint_number`    VARCHAR(30)     NOT NULL COMMENT 'Auto-generated FOF-CMP-YYYY-NNNNN',
  `complainant_name`    VARCHAR(100)    NOT NULL COMMENT 'Person filing the complaint',
  `complainant_contact` VARCHAR(15)     NULL     COMMENT 'Contact number of complainant',
  `complaint_type`      ENUM('Academic','Facility','Staff_Behavior','Fee','Safety','Transportation','Food','Hygiene','Other') NOT NULL COMMENT 'Complaint category',
  `description`         TEXT            NOT NULL COMMENT 'Full complaint description',
  `urgency`             ENUM('Normal','Urgent','Critical') NOT NULL DEFAULT 'Normal' COMMENT 'Priority level',
  `assigned_to_user_id` INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff handling the complaint',
  `status`              ENUM('Open','In_Progress','Resolved','Closed','Escalated') NOT NULL DEFAULT 'Open' COMMENT 'Complaint resolution status',
  `resolution_notes`    TEXT            NULL     COMMENT 'Resolution details',
  `resolved_at`         DATETIME        NULL     COMMENT 'Resolution timestamp',
  `resolved_by`         INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff who resolved',
  `cmp_complaint_id`    INT UNSIGNED    NULL     COMMENT 'FK cmp_complaints.id (INT UNSIGNED); set only on escalation to CMP module',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_cmp_complaint_number` (`complaint_number`),
  KEY `idx_fof_cmp_status_urgency` (`status`, `urgency`),
  KEY `idx_fof_cmp_assigned`       (`assigned_to_user_id`),
  KEY `idx_fof_cmp_escalated`      (`cmp_complaint_id`),
  KEY `idx_fof_cmp_resolved_by`    (`resolved_by`),
  CONSTRAINT `fk_fof_cmp_assigned_to_user_id` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `sys_users`     (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cmp_resolved_by`         FOREIGN KEY (`resolved_by`)         REFERENCES `sys_users`     (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cmp_cmp_complaint_id`    FOREIGN KEY (`cmp_complaint_id`)    REFERENCES `cmp_complaints` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Front-office lightweight complaint intake; escalation links to CMP module via cmp_complaint_id';


-- =============================================================================
-- LAYER 3 — Depends on Layer 2
-- 2 tables: circulars, feedback_responses
-- =============================================================================

-- 18. fof_circulars — Official school circulars with approval and distribution lifecycle
CREATE TABLE IF NOT EXISTS `fof_circulars` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `circular_number`      VARCHAR(30)     NOT NULL COMMENT 'Auto-generated CIR-YYYY-NNNN',
  `title`                VARCHAR(200)    NOT NULL COMMENT 'Circular heading or title',
  `subject`              VARCHAR(300)    NOT NULL COMMENT 'One-line subject of circular',
  `body`                 LONGTEXT        NOT NULL COMMENT 'Rich text HTML body of circular',
  `audience`             ENUM('Parents','Staff','Both','Specific_Class','Specific_Section') NOT NULL COMMENT 'Target recipient group',
  `audience_filter_json` JSON            NULL     COMMENT 'Class/section IDs when audience = Specific_Class or Specific_Section; e.g., {"class_ids":[3,4]}',
  `effective_date`       DATE            NOT NULL COMMENT 'Circular effective or issue date',
  `expires_on`           DATE            NULL     COMMENT 'Optional expiry date',
  `attachment_media_id`  INT UNSIGNED    NULL     COMMENT 'FK sys_media.id (INT UNSIGNED) — optional PDF attachment',
  `status`               ENUM('Draft','Pending_Approval','Approved','Distributed','Recalled') NOT NULL DEFAULT 'Draft' COMMENT 'Circular lifecycle status; edit blocked after Approved per BR-FOF-008',
  `approved_by`          INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — Principal or admin who approved',
  `approved_at`          DATETIME        NULL     COMMENT 'Approval timestamp',
  `distributed_at`       DATETIME        NULL     COMMENT 'Distribution trigger timestamp',
  `distributed_by`       INT UNSIGNED    NULL     COMMENT 'FK sys_users.id — staff who triggered distribution',
  `is_active`            TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`           BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`           TIMESTAMP NULL,
  `updated_at`           TIMESTAMP NULL,
  `deleted_at`           TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_fof_cir_circular_number` (`circular_number`),
  KEY `idx_fof_cir_status`         (`status`),
  KEY `idx_fof_cir_approved_by`    (`approved_by`),
  KEY `idx_fof_cir_distributed_by` (`distributed_by`),
  KEY `idx_fof_cir_attachment`     (`attachment_media_id`),
  CONSTRAINT `fk_fof_cir_approved_by`         FOREIGN KEY (`approved_by`)         REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cir_distributed_by`      FOREIGN KEY (`distributed_by`)      REFERENCES `sys_users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cir_attachment_media_id` FOREIGN KEY (`attachment_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='School circulars; Draft→Pending_Approval→Approved→Distributed FSM; edit locked after Approved per BR-FOF-008';


-- 19. fof_feedback_responses — Individual form submissions
CREATE TABLE IF NOT EXISTS `fof_feedback_responses` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `feedback_form_id`    BIGINT UNSIGNED NOT NULL COMMENT 'FK fof_feedback_forms.id',
  `respondent_user_id`  INT UNSIGNED    NULL     COMMENT 'FK sys_users.id; NULL = anonymous submission per BR-FOF-010',
  `respondent_name`     VARCHAR(100)    NULL     COMMENT 'Optional name for anonymous submissions',
  `is_anonymous`        TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = user chose anonymous; respondent_user_id MUST be NULL',
  `responses_json`      JSON            NOT NULL COMMENT 'Array of answers: [{question_id, answer}]',
  `submitted_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Submission timestamp',
  `is_active`           TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`          BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'sys_users.id; use 0 for anonymous submissions',
  `updated_by`          BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_fr_form`       (`feedback_form_id`),
  KEY `idx_fof_fr_respondent` (`respondent_user_id`),
  KEY `idx_fof_fr_submitted`  (`submitted_at`),
  CONSTRAINT `fk_fof_fr_feedback_form_id`   FOREIGN KEY (`feedback_form_id`)   REFERENCES `fof_feedback_forms` (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_fr_respondent_user_id` FOREIGN KEY (`respondent_user_id`) REFERENCES `sys_users`          (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Feedback form responses; supports anonymous submissions per BR-FOF-010';


-- =============================================================================
-- LAYER 4 — Depends on Layer 3
-- 3 tables: circular_distributions, communication_logs, sms_logs
-- =============================================================================

-- 20. fof_circular_distributions — Append-only per-recipient NTF delivery log
-- EXCEPTION: No deleted_at, no updated_by — immutable append-only log
CREATE TABLE IF NOT EXISTS `fof_circular_distributions` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `circular_id`       BIGINT UNSIGNED NOT NULL COMMENT 'FK fof_circulars.id',
  `recipient_user_id` INT UNSIGNED    NOT NULL COMMENT 'FK sys_users.id — recipient user',
  `channel`           ENUM('Email','SMS','Push') NOT NULL COMMENT 'Delivery channel',
  `status`            ENUM('Queued','Sent','Delivered','Failed') NOT NULL DEFAULT 'Queued' COMMENT 'Delivery status',
  `sent_at`           TIMESTAMP NULL COMMENT 'Timestamp when NTF job was dispatched',
  `delivered_at`      TIMESTAMP NULL COMMENT 'Delivery confirmation from NTF gateway',
  `read_at`           TIMESTAMP NULL COMMENT 'Read receipt if available from gateway',
  `ntf_log_id`        BIGINT UNSIGNED NULL COMMENT 'NTF module log reference; no FK constraint — cross-module reference',
  `is_active`         TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`        BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  -- No updated_by: append-only immutable log
  -- No deleted_at: no soft delete on distribution log
  `created_at`        TIMESTAMP NULL,
  `updated_at`        TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  KEY `idx_fof_cd_circular`       (`circular_id`),
  KEY `idx_fof_cd_recipient`      (`circular_id`, `recipient_user_id`),
  KEY `idx_fof_cd_status`         (`status`),
  KEY `idx_fof_cd_recipient_user` (`recipient_user_id`),
  CONSTRAINT `fk_fof_cd_circular_id`       FOREIGN KEY (`circular_id`)       REFERENCES `fof_circulars` (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_cd_recipient_user_id` FOREIGN KEY (`recipient_user_id`) REFERENCES `sys_users`    (`id`) ON DELETE RESTRICT  ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Append-only per-recipient distribution log for circulars; no soft delete, no updated_by';


-- 21. fof_communication_logs — Bulk email/SMS send audit log
CREATE TABLE IF NOT EXISTS `fof_communication_logs` (
  `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `template_id`      BIGINT UNSIGNED NULL     COMMENT 'FK fof_email_templates.id; NULL for ad-hoc messages',
  `channel`          ENUM('Email','SMS') NOT NULL COMMENT 'Communication channel used',
  `subject`          VARCHAR(300)    NULL     COMMENT 'Email subject; NULL for SMS',
  `body`             TEXT            NOT NULL COMMENT 'Message body',
  `recipient_group`  VARCHAR(100)    NOT NULL COMMENT 'e.g., All_Parents, Class_5_Parents, All_Staff',
  `total_recipients` INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'Total recipient count',
  `sent_count`       INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'Successfully sent count',
  `failed_count`     INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'Failed delivery count',
  `sent_at`          TIMESTAMP NULL COMMENT 'Timestamp when bulk send was dispatched',
  `is_active`        TINYINT(1)      NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`       BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`       BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`       TIMESTAMP NULL,
  `updated_at`       TIMESTAMP NULL,
  `deleted_at`       TIMESTAMP NULL  COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_cl_created_at` (`created_at`),
  KEY `idx_fof_cl_channel`    (`channel`),
  KEY `idx_fof_cl_template`   (`template_id`),
  CONSTRAINT `fk_fof_cl_template_id` FOREIGN KEY (`template_id`) REFERENCES `fof_email_templates` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Bulk email/SMS campaign audit log with total/sent/failed recipient counters';


-- 22. fof_sms_logs — Per-recipient SMS delivery tracking
CREATE TABLE IF NOT EXISTS `fof_sms_logs` (
  `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `communication_log_id` BIGINT UNSIGNED  NOT NULL COMMENT 'FK fof_communication_logs.id — parent bulk send log',
  `recipient_user_id`    INT UNSIGNED     NOT NULL COMMENT 'FK sys_users.id — recipient user',
  `mobile_number`        VARCHAR(15)      NOT NULL COMMENT 'Destination mobile number',
  `message`              TEXT             NOT NULL COMMENT 'SMS message text',
  `sms_units`            TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Number of SMS units; >160 chars = multi-unit per BR-FOF-011',
  `status`               ENUM('Queued','Sent','Delivered','Failed') NOT NULL DEFAULT 'Queued' COMMENT 'Delivery status',
  `sent_at`              TIMESTAMP NULL COMMENT 'Send timestamp',
  `delivered_at`         TIMESTAMP NULL COMMENT 'Delivery confirmation timestamp',
  `gateway_response`     TEXT             NULL     COMMENT 'Raw gateway response for debugging',
  `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `updated_by`           BIGINT UNSIGNED  NOT NULL COMMENT 'sys_users.id — no FK constraint',
  `created_at`           TIMESTAMP NULL,
  `updated_at`           TIMESTAMP NULL,
  `deleted_at`           TIMESTAMP NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_fof_sl_comm_log`  (`communication_log_id`),
  KEY `idx_fof_sl_recipient` (`recipient_user_id`),
  KEY `idx_fof_sl_status`    (`status`),
  CONSTRAINT `fk_fof_sl_communication_log_id` FOREIGN KEY (`communication_log_id`) REFERENCES `fof_communication_logs` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_fof_sl_recipient_user_id`    FOREIGN KEY (`recipient_user_id`)    REFERENCES `sys_users`              (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-recipient SMS delivery tracking with gateway response; sms_units for multi-part messages';


SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- Schema Stats: 22 tables | Layer 1: 7 | Layer 2: 10 | Layer 3: 2 | Layer 4: 3
-- Cross-module FKs: sys_users (16), sys_media (5), std_students (3),
--                   cmp_complaints (1), fof_visitor_purposes (1)
-- FK omitted: vsm_visitors (VSM module pending)
-- =============================================================================
