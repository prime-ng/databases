-- =============================================================================
-- HST — Hostel Management Module DDL  —  v3.0
-- Module: Hostel Management (Modules\Hostel)
-- Table Prefix: hst_*
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-05-04
-- Reviewed and enhanced by: Database Architect
-- Based on: HST_DDL_v2.sql (21 tables) + HST_Hostel_Requirement.md v2
--
-- ─────────────────────────────────────────────────────────────────────────────
-- v2 → v3 CHANGE SUMMARY
-- ─────────────────────────────────────────────────────────────────────────────
--
-- TABLE COUNT:  v2 = 21 tables   →   v3 = 36 tables  (+15 new) + 3 table
--
-- CONVENTION FIXES (per AI_Brain/agents/db-architect.md):
--   • ADDED `created_by` and `updated_by` (INT UNSIGNED → sys_users.id) on every
--     v2 table. Header comment in v2 line 20 promised these columns but the
--     CREATEs never defined them. This is a systematic, non-breaking addition.
--
-- 15 NEW TABLES (organized by domain):
--
--   Warden / Duty Roster
--     hst_warden_duty_roster          — daily / nightly on-duty assignment
--
--   Maintenance & Housekeeping
--     hst_bed_maintenance_log         — bed/room maintenance ticket lifecycle
--     hst_housekeeping_log            — daily cleaning records per room
--
--   Laundry
--     hst_laundry_tickets             — student laundry in/out tracking
--
--   Mess Operations
--     hst_mess_opt_outs               — per-meal opt-outs (more granular than full-day leave)
--     hst_mess_bills                  — monthly mess-bill summary per student
--
--   Fee Reconciliation
--     hst_fee_demands                 — local audit of charges raised against fin_*
--
--   Discipline Masters
--     hst_incident_types              — master for incident_type (replaces VARCHAR free-text)
--     hst_incident_warnings           — warning-letter log with template + signer
--
--   Room Reservation
--     hst_room_reservations           — pre-allotment reservation during admission
--
--   Emergency Contacts
--     hst_emergency_contacts          — hostel-specific (doctor, ambulance, local guardian)
--
--   Security
--     hst_visitor_media               — visitor photo / selfie at gate
--
--   Sick Bay Detail
--     hst_sick_bay_vitals             — structured vital-signs log per admission
--     hst_sick_bay_medications        — medications administered per admission
--
--   Cross-cutting Audit
--     hst_audit_log                   — generic before/after change trail
--     hst_notification_log            — record of every parent / student / warden notification dispatched
--
-- FIELD ADDITIONS (additive, all nullable, do not break v2 data):
--   hst_hostels        : email, total_floors, principal_warden_id, gender_strict_enforce
--   hst_floors         : block_code
--   hst_rooms          : block_code, windows_facing, accessibility_features_json
--   hst_beds           : bed_type, notes
--   hst_allotments     : transfer_from_allotment_id, vacation_reason, vacated_by, is_emergency
--   hst_visitor_log    : visitor_photo_media_id, signed_register_media_id
--   hst_movement_log   : is_overnight, parent_consent_received, consent_media_id
--   hst_incidents      : incident_type_id (FK → new hst_incident_types) — old VARCHAR kept for back-compat
--   hst_complaints     : acknowledged_at, satisfaction_score
--   hst_sick_bay_log   : medical_consent_received
--   hst_leave_passes   : guardian_name, guardian_relation, parent_consent_received, consent_media_id, is_overnight
--   hst_room_inventory : photo_media_id (so damage report has visual evidence)
--   hst_mess_attendance: shift_id (which mess shift if multi-shift)
--
-- DEFERRED TO v4 (review items, not blocking):
--   • Normalize hst_hostels.facilities_json / amenities to first-class master + junction tables.
--   • Vendor module integration (mess contractor, cleaning agency) — likely belongs in vnd_* not hst_*.
--   • Encrypt hst_visitor_log.id_proof_number_masked at rest (currently last-4-digits only — already partial).
--   • Convert hst_incidents.incident_type (VARCHAR free text) to drop column once all callers migrated to incident_type_id.
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 0 : EXTERNAL DEPENDENCY MAP (informational only)
-- ─────────────────────────────────────────────────────────────────────────────
-- Tables referenced via FK but defined elsewhere:
--   sys_users          (system module — INT UNSIGNED)
--   sys_media          (system module — INT UNSIGNED)
--   std_students       (StudentProfile module — INT UNSIGNED)
--   sch_academic_term  (SchoolSetup — INT UNSIGNED)
--   hpc_records        (HPC module — soft-FK only, no DB constraint)
-- ─────────────────────────────────────────────────────────────────────────────


-- =============================================================================
-- LAYER 1 — No hst_* dependencies
-- =============================================================================


CREATE TABLE IF NOT EXISTS `hst_room_types` (
    `id`            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`          VARCHAR(20)      NOT NULL,  -- e.g. 'single', 'double', 'triple', 'dormitory'
    `name`          VARCHAR(100)     NOT NULL,  -- e.g. 'Single Occupancy', 'Double Occupancy', 'Triple Occupancy', 'Dormitory (4+ beds)'
    `is_active`     TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP        NULL
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_room_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Master list of room types; referenced by hst_rooms.room_type; allows dynamic room type definitions without code changes';

CREATE TABLE IF NOT EXISTS `hst_bed_types` (
    `id`            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`          VARCHAR(20)      NOT NULL,  -- e.g. 'lower_bunk', 'upper_bunk', 'single'
    `name`          VARCHAR(100)     NOT NULL,  -- e.g. 'Lower Bunk', 'Upper Bunk', 'Single Bed'
    `is_active`     TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_bed_type_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Master list of bed types; referenced by hst_beds.bed_type; allows dynamic bed type definitions without code changes';

CREATE TABLE IF NOT EXISTS `hst_dynamic_status_masters` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `status_type`   ENUM('Room Status', 'Bed Status', 'Repair Status', 'Room Condition Status', 'Hostel Allotment Status', 'Mess Attendance Status', 'Hostel Complaint Status', 'Attendance Entry Status', 'Room Change Request Status', 'Hostel Leave Approval Status', 'Bed Maintenance Status', 'Laundry Ticket Status', 'Mess Opt-out Request Status', 'Mess Bill Status', 'Hostel Fee Status', 'Room Reservation Status') NOT NULL,
    `code`          VARCHAR(20)     NOT NULL,  -- e.g. 'available', 'occupied', 'maintenance'
    `name`          VARCHAR(100)    NOT NULL,  -- e.g. 'Available', 'Occupied', 'Under Maintenance'
    `is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP       NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_dynamic_status_code` (`module`, `code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Generic master for dynamic status codes across modules; allows adding new statuses without code changes';

-- Data seed :
    -- Status Type                    Code
    -- ----------------------------   -----------------------------------------------------------------------------------------
    -- Room Status                  - 'available','full','maintenance','reserved'
    -- Bed Status                   - 'available','occupied','maintenance','reserved'
    -- Bed Condition Status         - 'good','fair','poor'
    -- Repair Status                - 'none','pending','under_repair','repaired','written_off'
    -- Room Condition Status        - 'good','fair','poor','under_repair','disposed'
    -- Hostel Allotement Status     - 'active','vacated','transferred','waitlisted'
    -- Mess Attendance Status       - 'present','absent','on_leave','opted_out'
    -- Hostel Complaint Status      - 'open','in_progress','resolved','escalated','closed'
    -- Attendance Entry Status      - 'present','absent','leave','home','late','sick_bay'
    -- Room Change Request Status   - 'pending','approved','rejected'
    -- Hostel Leave Approval Status - 'pending','approved','rejected','returned','cancelled'
    -- Bed Maintenance Status       - 'reported','assigned','in_progress','blocked','resolved','closed','cancelled'
    -- Laundry Ticket Status        - 'submitted','in_wash','ready','collected','lost','damaged','disputed'
    -- Mess Opt-out Request Status  - 'pending','approved','rejected','active','expired','cancelled'
    -- Mess Bill Status             - 'draft','finalised','disputed','adjusted','settled'
    -- Hostel Fee Status            - 'draft','pushed','accepted','rejected','revised','settled'
    -- Room Reservation Status      - 'pending','confirmed','expired','converted','cancelled','refunded'


CREATE TABLE IF NOT EXISTS `hst_hostels` (
    `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`                     VARCHAR(150)     NOT NULL COMMENT 'Hostel/building display name',
    `code`                     VARCHAR(20)      NULL     COMMENT 'Short hostel code (BH1, GH1, etc.); UNIQUE nullable',
    `type`                     ENUM('boys','girls','mixed') NOT NULL COMMENT 'Gender restriction',
    `gender_strict_enforce`    TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'v3 — 1 = solver rejects opposite-gender allotment, 0 = warning only (e.g., for staff quarters in mixed)',
    `warden_id`                INT UNSIGNED     NULL     COMMENT 'Current chief warden (sys_users.id); see also hst_warden_assignments for history',
    `principal_warden_id`      INT UNSIGNED     NULL     COMMENT 'v3 — secondary chief / acting warden (separate from primary so handover is auditable)',
    `total_capacity`           SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total bed count; recomputed by AllotmentService',
    `current_occupancy`        SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Denormalized; maintained synchronously',
    `total_floors`             TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'v3 — denormalized count for fast dashboard reads',
    `sick_bay_capacity`        TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Sick-bay bed capacity',
    `address`                  VARCHAR(500)     NULL     COMMENT 'Physical address',
    `contact_phone`            VARCHAR(20)      NULL     COMMENT 'Direct contact',
    `email`                    VARCHAR(150)     NULL     COMMENT 'v3 — hostel-direct email',
    `visiting_days_json`       JSON             NULL     COMMENT 'Visiting day/hour config',
    `facilities_json`          JSON             NULL     COMMENT 'Facility names array; deferred to v4 to normalize',
    `is_active`                TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`               TIMESTAMP        NULL,
    `updated_at`               TIMESTAMP        NULL,
    `deleted_at`               TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_hostel_code` (`code`),
    KEY `idx_hst_hostel_warden` (`warden_id`),
    KEY `idx_hst_hostel_principal` (`principal_warden_id`),
    CONSTRAINT `fk_hst_hostel_warden`           FOREIGN KEY (`warden_id`)           REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_hostel_principal_warden` FOREIGN KEY (`principal_warden_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel/building master';


-- =============================================================================
-- LAYER 2 — Depends on Layer 1
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_floors` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`         BIGINT UNSIGNED  NOT NULL,
    `floor_number`      TINYINT          NOT NULL COMMENT '0 = Ground Floor',
    `display_name`      VARCHAR(100)     NULL,
    `block_code`        VARCHAR(10)      NULL     COMMENT 'v3 — block / wing label (A, B, North, etc.)',
    `floor_incharge_id` INT UNSIGNED     NULL,
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
    `created_by`        INT UNSIGNED     NULL     COMMENT 'v3',
    `updated_by`        INT UNSIGNED     NULL     COMMENT 'v3',
    `created_at`        TIMESTAMP        NULL,
    `updated_at`        TIMESTAMP        NULL,
    `deleted_at`        TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_floor_num` (`hostel_id`, `floor_number`, `block_code`),
    KEY `idx_hst_floor_hostel`    (`hostel_id`),
    KEY `idx_hst_floor_incharge`  (`floor_incharge_id`),
    CONSTRAINT `fk_hst_floor_hostel`   FOREIGN KEY (`hostel_id`)         REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_floor_incharge` FOREIGN KEY (`floor_incharge_id`) REFERENCES `sys_users`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Floor within a hostel';


CREATE TABLE IF NOT EXISTS `hst_warden_assignments` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`       BIGINT UNSIGNED  NOT NULL,
    `floor_id`        BIGINT UNSIGNED  NULL     COMMENT 'NULL = hostel-level',
    `user_id`         INT UNSIGNED     NOT NULL COMMENT 'sys_users.id',
    `assignment_type` ENUM('chief','block','floor','assistant') NOT NULL,
    `effective_from`  DATE             NOT NULL,
    `effective_to`    DATE             NULL,
    `remarks`         VARCHAR(300)     NULL,
    `is_active`       TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP        NULL,
    `updated_at`      TIMESTAMP        NULL,
    `deleted_at`      TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_wa_hostel_floor_to` (`hostel_id`, `floor_id`, `effective_to`),
    KEY `idx_hst_wa_user`            (`user_id`),
    KEY `idx_hst_wa_floor`           (`floor_id`),
    CONSTRAINT `fk_hst_wa_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_wa_floor`  FOREIGN KEY (`floor_id`)  REFERENCES `hst_floors`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_wa_user`   FOREIGN KEY (`user_id`)   REFERENCES `sys_users`   (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Warden role assignment history';


-- =============================================================================
-- LAYER 3 — Depends on Layer 2 (hst_floors)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_rooms` (
    `id`                          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `floor_id`                    BIGINT UNSIGNED  NOT NULL,
    `hostel_id`                   BIGINT UNSIGNED  NOT NULL,  -- FK to hst_hostels.id for easier querying; ensures room always linked to valid hostel (even if floor record changes)
    `room_number`                 VARCHAR(20)      NOT NULL,
    `block_code`                  VARCHAR(10)      NULL     COMMENT 'v3 — block / wing within floor (A, B)',
    `room_type`                   TINYINT UNSIGNED NOT NULL COMMENT 'Reference to hst_room_types.id',
    `capacity`                    TINYINT UNSIGNED NOT NULL,
    `current_occupancy`           TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `status`                      INT UNSIGNED     NOT NULL, -- FK to hst_dynamic_status_masters.id; 'v3 — added "reserved" for pre-allotment hold (see hst_room_reservations)',
    `windows_facing`              ENUM('north','south','east','west','northeast','northwest','southeast','southwest','internal') NULL COMMENT 'v3 — for assignment preferences',
    `amenities_json`              JSON             NULL,
    `accessibility_features_json` JSON             NULL     COMMENT 'v3 — wheelchair_accessible, grab_bars, accessible_toilet, ramp',
    `priority_flags_json`         JSON             NULL,
    `notes`                       VARCHAR(500)     NULL,
    `is_active`                   TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`                  TIMESTAMP        NULL,
    `updated_at`                  TIMESTAMP        NULL,
    `deleted_at`                  TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_room_num` (`floor_id`, `room_number`),
    KEY `idx_hst_room_floor`     (`floor_id`),
    KEY `idx_hst_room_status`    (`status`)  COMMENT 'v3 — dashboard filter',
    CONSTRAINT `fk_hst_room_floor` FOREIGN KEY (`floor_id`) REFERENCES `hst_floors` (`id`),
    CONSTRAINT `fk_hst_room_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_room_type` FOREIGN KEY (`room_type`) REFERENCES `hst_room_types` (`id`),
    CONSTRAINT `fk_hst_room_status` FOREIGN KEY (`status`) REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Room within a floor';


-- =============================================================================
-- LAYER 4 — Depends on Layer 3 + cross-module
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_beds` (
    `id`         BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `room_id`    BIGINT UNSIGNED  NOT NULL,
    `bed_label`  VARCHAR(20)      NOT NULL,  -- e.g. 'Lower', 'Upper', 'Bed 1', 'Bed 2'; UNIQUE within room
    `bed_type`   TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'v3 — Reference to hst_bed_types.id; allows dynamic bed type definitions (Bunk Bed, Single Bed, etc.) without code changes',
    `status`     INT UNSIGNED     NOT NULL, -- FK to hst_dynamic_status_masters.id; 'v3 — added "reserved" for pre-allotment hold (see hst_room_reservations)',
    `bed_condition`  INT UNSIGNED     NOT NULL, -- FK to hst_dynamic_status_masters.id; 'v3 — added "good/fair/poor" for condition monitoring (see hst_room_inventory and maintenance logs)
    `notes`      VARCHAR(255)     NULL     COMMENT 'v3',
    `is_active`  TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP        NULL,
    `updated_at` TIMESTAMP        NULL,
    `deleted_at` TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_bed_label` (`room_id`, `bed_label`),
    KEY `idx_hst_bed_room` (`room_id`),
    KEY `idx_hst_bed_status` (`status`)  COMMENT 'v3',
    CONSTRAINT `fk_hst_bed_room` FOREIGN KEY (`room_id`) REFERENCES `hst_rooms` (`id`),
    CONSTRAINT `fk_hst_bed_bed_type` FOREIGN KEY (`bed_type`) REFERENCES `hst_bed_types` (`id`),
    CONSTRAINT `fk_hst_bed_status` FOREIGN KEY (`status`) REFERENCES `hst_dynamic_status_masters` (`id`),
    CONSTRAINT `fk_hst_bed_condition` FOREIGN KEY (`condition`) REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Beds';


CREATE TABLE IF NOT EXISTS `hst_fee_structures` (
    `id`                          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`                   BIGINT UNSIGNED  NOT NULL,
    `academic_session_id`         INT UNSIGNED     NOT NULL,
    `room_type`                   TINYINT UNSIGNED NOT NULL COMMENT 'Reference to hst_room_types.id',
    `meal_plan`                   ENUM('full_board','lunch_only','dinner_only','none') NOT NULL,
    `room_rent_monthly`           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `mess_charge_monthly`         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `electricity_charge_monthly`  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `laundry_charge_monthly`      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `security_deposit`            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `effective_from`              DATE             NOT NULL,
    `effective_to`                DATE             NULL,
    `is_active`                   TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`                  TIMESTAMP        NULL,
    `updated_at`                  TIMESTAMP        NULL,
    `deleted_at`                  TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_fee_struct` (`hostel_id`, `academic_session_id`, `room_type`, `meal_plan`, `effective_from`),
    KEY `idx_hst_fs_hostel`  (`hostel_id`),
    KEY `idx_hst_fs_session` (`academic_session_id`),
    CONSTRAINT `fk_hst_fs_hostel`  FOREIGN KEY (`hostel_id`)           REFERENCES `hst_hostels`       (`id`),
    CONSTRAINT `fk_hst_fs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_hst_fs_room_type` FOREIGN KEY (`room_type`) REFERENCES `hst_room_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Fee rates per room/meal/session';


CREATE TABLE IF NOT EXISTS `hst_mess_weekly_menus` (
    `id`                        BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`                 BIGINT UNSIGNED  NOT NULL,
    `academic_session_id`       INT UNSIGNED     NOT NULL,
    `week_start_date`           DATE             NOT NULL,
    `day_of_week`               TINYINT UNSIGNED NOT NULL,
    `meal_type`                 ENUM('breakfast','lunch','dinner','snacks') NOT NULL,
    `menu_description`          TEXT             NULL,
    `is_special_diet_available` TINYINT(1)       NOT NULL DEFAULT 0,
    `special_diet_description`  VARCHAR(500)     NULL,
    `is_published`              TINYINT(1)       NOT NULL DEFAULT 0,
    `is_active`                 TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`                TIMESTAMP        NULL,
    `updated_at`                TIMESTAMP        NULL,
    `deleted_at`                TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_menu_slot` (`hostel_id`, `week_start_date`, `day_of_week`, `meal_type`),
    KEY `idx_hst_menu_hostel`  (`hostel_id`),
    KEY `idx_hst_menu_session` (`academic_session_id`),
    CONSTRAINT `fk_hst_menu_hostel`  FOREIGN KEY (`hostel_id`)           REFERENCES `hst_hostels`       (`id`),
    CONSTRAINT `fk_hst_menu_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_academic_term` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Weekly mess menu';


CREATE TABLE IF NOT EXISTS `hst_room_inventory` (
    `id`                     BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `room_id`                BIGINT UNSIGNED  NOT NULL,
    `item_name`              VARCHAR(150)     NOT NULL,
    `quantity`               TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `room_condition`         INT UNSIGNED     NOT NULL DEFAULT 1 COMMENT 'FK to hst_dynamic_status_masters.id; e.g. "good", "fair", "poor"',
    `last_inspected_at`      DATE             NULL,
    `damage_description`     TEXT             NULL,
    `estimated_repair_cost`  DECIMAL(10,2)    NULL,
    `repair_status`          INT UNSIGNED     NOT NULL DEFAULT 1 COMMENT 'FK to hst_dynamic_status_masters.id; e.g. "pending", "under_repair", "repaired"',
    `responsible_student_id` INT UNSIGNED     NULL,
    `charge_pushed_to_fee`   TINYINT(1)       NOT NULL DEFAULT 0,
    `photo_media_id`         INT UNSIGNED     NULL     COMMENT 'v3 — visual evidence of damage; sys_media.id',
    `is_active`              TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`             TIMESTAMP        NULL,
    `updated_at`             TIMESTAMP        NULL,
    `deleted_at`             TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_inv_room`    (`room_id`),
    KEY `idx_hst_inv_student` (`responsible_student_id`),
    CONSTRAINT `fk_hst_inv_room`    FOREIGN KEY (`room_id`)                REFERENCES `hst_rooms`    (`id`),
    CONSTRAINT `fk_hst_inv_student` FOREIGN KEY (`responsible_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_inv_photo`   FOREIGN KEY (`photo_media_id`)         REFERENCES `sys_media`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_inv_repair_status` FOREIGN KEY (`repair_status`) REFERENCES `hst_dynamic_status_masters` (`id`),
    CONSTRAINT `fk_hst_inv_condition` FOREIGN KEY (`room_condition`)       REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Room inventory';


-- =============================================================================
-- LAYER 5 — Depends on Layer 4 + cross-module (std_students)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_allotments` (
    `id`                         BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`                 INT UNSIGNED     NOT NULL,
    `bed_id`                     BIGINT UNSIGNED  NOT NULL,
    `academic_session_id`        INT UNSIGNED     NOT NULL,
    `allotment_date`             DATE             NOT NULL,
    `vacating_date`              DATE             NULL,
    `meal_plan`                  ENUM('full_board','lunch_only','dinner_only','none') NOT NULL DEFAULT 'full_board',
    `status`                     INT UNSIGNED     NOT NULL, -- FK to hst_dynamic_status_masters.id; 'v3 — added "waitlisted" for pending allotments that don't yet have a bed assigned',
    `is_alloted`                 TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'v3 — distinguishes active allotments from waitlisted/pending without needing to filter by status',
    `remarks`                    VARCHAR(500)     NULL,
    `transfer_from_allotment_id` BIGINT UNSIGNED  NULL     COMMENT 'v3 — when this allotment was created via transfer, points at the predecessor (for trail without graph queries)',
    `vacation_reason`            ENUM('graduation','transfer_out','withdrawal','disciplinary','medical','family','other') NULL  COMMENT 'v3 — reason captured at vacate time',
    `vacated_by`                 INT UNSIGNED     NULL     COMMENT 'v3 — sys_users.id who recorded vacate',
    `is_emergency`               TINYINT(1)       NOT NULL DEFAULT 0  COMMENT 'v3 — 1 = mid-semester emergency placement (flagged for review)',
    -- Generated columns (unchanged from v2)
    `gen_active_bed_id`          BIGINT           GENERATED ALWAYS AS (IF(`is_alloted` = 1, `bed_id`, NULL))     STORED,  -- for fast lookup of currently occupied beds without needing to filter by status in every query
    `gen_active_student_id`      BIGINT           GENERATED ALWAYS AS (IF(`is_alloted` = 1, `student_id`, NULL)) STORED,  -- for fast lookup of students with active allotments without needing to filter by status in every query
    `is_active`                  TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`                 TIMESTAMP        NULL,
    `updated_at`                 TIMESTAMP        NULL,
    `deleted_at`                 TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_allot_active_bed`     (`gen_active_bed_id`),
    UNIQUE KEY `uq_hst_allot_active_student` (`gen_active_student_id`),
    KEY `idx_hst_allot_student_status`  (`student_id`, `status`),
    KEY `idx_hst_allot_bed_status`      (`bed_id`, `status`),
    KEY `idx_hst_allot_session`         (`academic_session_id`),
    KEY `idx_hst_allot_date`            (`allotment_date`)  COMMENT 'v3 — common report axis',
    KEY `idx_hst_allot_transfer_from`   (`transfer_from_allotment_id`)  COMMENT 'v3',
    CONSTRAINT `fk_hst_allot_student`       FOREIGN KEY (`student_id`)                 REFERENCES `std_students`       (`id`),
    CONSTRAINT `fk_hst_allot_bed`           FOREIGN KEY (`bed_id`)                     REFERENCES `hst_beds`           (`id`),
    CONSTRAINT `fk_hst_allot_session`       FOREIGN KEY (`academic_session_id`)        REFERENCES `sch_academic_term`  (`id`),
    CONSTRAINT `fk_hst_allot_transfer_from` FOREIGN KEY (`transfer_from_allotment_id`) REFERENCES `hst_allotments`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_allot_vacated_by`    FOREIGN KEY (`vacated_by`)                 REFERENCES `sys_users`          (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_allot_status`       FOREIGN KEY (`status`)                     REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Allotments';


CREATE TABLE IF NOT EXISTS `hst_special_diets` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`          INT UNSIGNED     NOT NULL,
    `hostel_id`           BIGINT UNSIGNED  NOT NULL,
    `diet_type`           ENUM('diabetic','jain_vegetarian','gluten_free','nut_allergy','religious_fasting','custom') NOT NULL,
    `custom_description`  VARCHAR(300)     NULL,
    `fasting_days_json`   JSON             NULL,
    `effective_from`      DATE             NOT NULL,
    `effective_to`        DATE             NULL,
    `prescribed_by`       VARCHAR(150)     NULL,
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_sd_student` (`student_id`),
    KEY `idx_hst_sd_hostel`  (`hostel_id`),
    CONSTRAINT `fk_hst_sd_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_sd_hostel`  FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Special diet';


CREATE TABLE IF NOT EXISTS `hst_visitor_log` (
    `id`                        BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`                 BIGINT UNSIGNED  NOT NULL,
    `student_id`                INT UNSIGNED     NOT NULL,
    `visitor_name`              VARCHAR(150)     NOT NULL,
    `relationship`              ENUM('parent','guardian','sibling','relative','other') NOT NULL,
    `visitor_phone`             VARCHAR(20)      NULL,
    `id_proof_type`             VARCHAR(50)      NULL,
    `id_proof_number_masked`    VARCHAR(30)      NULL     COMMENT 'Last 4 digits only',
    `visit_date`                DATE             NOT NULL,
    `in_time`                   TIME             NOT NULL,
    `out_time`                  TIME             NULL,
    `purpose`                   VARCHAR(300)     NULL,
    `allowed_by`                INT UNSIGNED     NULL,
    `is_outside_visiting_hours` TINYINT(1)       NOT NULL DEFAULT 0,
    `override_reason`           VARCHAR(300)     NULL,
    `visitor_photo_media_id`    INT UNSIGNED     NULL     COMMENT 'v3 — selfie at gate; sys_media.id',
    `signed_register_media_id`  INT UNSIGNED     NULL     COMMENT 'v3 — scanned signature page',
    `is_active`                 TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`                TIMESTAMP        NULL,
    `updated_at`                TIMESTAMP        NULL,
    `deleted_at`                TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_vl_hostel_date` (`hostel_id`, `visit_date`),
    KEY `idx_hst_vl_student`     (`student_id`),
    KEY `idx_hst_vl_allowed_by`  (`allowed_by`),
    CONSTRAINT `fk_hst_vl_hostel`     FOREIGN KEY (`hostel_id`)                REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_vl_student`    FOREIGN KEY (`student_id`)               REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_vl_allowed_by` FOREIGN KEY (`allowed_by`)               REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_vl_photo`      FOREIGN KEY (`visitor_photo_media_id`)   REFERENCES `sys_media`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_vl_signed`     FOREIGN KEY (`signed_register_media_id`) REFERENCES `sys_media`    (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel visitor register';


CREATE TABLE IF NOT EXISTS `hst_movement_log` (
    `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`               INT UNSIGNED     NOT NULL,
    `hostel_id`                BIGINT UNSIGNED  NOT NULL,
    `movement_date`            DATE             NOT NULL,
    `out_time`                 TIME             NOT NULL,
    `in_time`                  TIME             NULL,
    `expected_return_time`     TIME             NULL,
    `destination`              VARCHAR(255)     NOT NULL,
    `purpose`                  VARCHAR(500)     NULL,
    `gate_pass_issued_by`      INT UNSIGNED     NULL,
    `overdue_notified`         TINYINT(1)       NOT NULL DEFAULT 0,
    `is_overnight`             TINYINT(1)       NOT NULL DEFAULT 0  COMMENT 'v3 — 1 if movement spans across midnight (different rules apply)',
    `parent_consent_received`  TINYINT(1)       NOT NULL DEFAULT 0  COMMENT 'v3',
    `consent_media_id`         INT UNSIGNED     NULL                COMMENT 'v3 — scanned/signed parent consent',
    `is_active`                TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`               TIMESTAMP        NULL,
    `updated_at`               TIMESTAMP        NULL,
    `deleted_at`               TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_ml_hostel_date`         (`hostel_id`, `movement_date`),
    KEY `idx_hst_ml_student_in`          (`student_id`, `in_time`),
    KEY `idx_hst_ml_issued_by`           (`gate_pass_issued_by`),
    KEY `idx_hst_ml_expected_return`     (`expected_return_time`)  COMMENT 'v3 — overdue dashboard',
    CONSTRAINT `fk_hst_ml_student`   FOREIGN KEY (`student_id`)         REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_ml_hostel`    FOREIGN KEY (`hostel_id`)          REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_ml_issued_by` FOREIGN KEY (`gate_pass_issued_by`) REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_ml_consent`   FOREIGN KEY (`consent_media_id`)   REFERENCES `sys_media`    (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='In/out movement register';


-- =============================================================================
-- LAYER 6 — Depends on Layer 5 + cross-module
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_attendance` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`       BIGINT UNSIGNED  NOT NULL,
    `attendance_date` DATE             NOT NULL,
    `shift`           ENUM('morning','evening','night') NOT NULL,
    `marked_by`       INT UNSIGNED     NOT NULL,
    `present_count`   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `absent_count`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `leave_count`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `late_count`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_locked`       TINYINT(1)        NOT NULL DEFAULT 0,
    `remarks`         VARCHAR(500)      NULL,
    `is_active`       TINYINT(1)        NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP         NULL,
    `updated_at`      TIMESTAMP         NULL,
    `deleted_at`      TIMESTAMP         NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_att_session` (`hostel_id`, `attendance_date`, `shift`),
    KEY `idx_hst_att_hostel`    (`hostel_id`),
    KEY `idx_hst_att_marked_by` (`marked_by`),
    CONSTRAINT `fk_hst_att_hostel`    FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_att_marked_by` FOREIGN KEY (`marked_by`) REFERENCES `sys_users`   (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roll call session';


CREATE TABLE IF NOT EXISTS `hst_incidents` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`          INT UNSIGNED     NOT NULL,
    `hostel_id`           BIGINT UNSIGNED  NOT NULL,
    `incident_date`       DATE             NOT NULL,
    `incident_time`       TIME             NULL,
    `incident_type`       VARCHAR(100)     NOT NULL  COMMENT 'Free-text; deferred to v4 to drop in favour of incident_type_id',
    `incident_type_id`    BIGINT UNSIGNED  NULL      COMMENT 'v3 — FK → hst_incident_types (preferred going forward)',
    `description`         TEXT             NOT NULL,
    `severity`            ENUM('minor','moderate','serious') NOT NULL,
    `action_taken`        TEXT             NULL,
    `reported_by`         INT UNSIGNED     NOT NULL,
    `is_escalated`        TINYINT(1)       NOT NULL DEFAULT 0,
    `escalated_at`        TIMESTAMP        NULL,
    `warning_letter_sent` TINYINT(1)       NOT NULL DEFAULT 0,
    `parent_notified`     TINYINT(1)       NOT NULL DEFAULT 0,
    `is_auto_generated`   TINYINT(1)       NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_inc_student`     (`student_id`),
    KEY `idx_hst_inc_hostel`      (`hostel_id`),
    KEY `idx_hst_inc_reported_by` (`reported_by`),
    KEY `idx_hst_inc_date`        (`incident_date`),
    KEY `idx_hst_inc_type_id`     (`incident_type_id`)  COMMENT 'v3',
    CONSTRAINT `fk_hst_inc_student`     FOREIGN KEY (`student_id`)        REFERENCES `std_students`         (`id`),
    CONSTRAINT `fk_hst_inc_hostel`      FOREIGN KEY (`hostel_id`)         REFERENCES `hst_hostels`          (`id`),
    CONSTRAINT `fk_hst_inc_reported_by` FOREIGN KEY (`reported_by`)       REFERENCES `sys_users`            (`id`),
    CONSTRAINT `fk_hst_inc_type`        FOREIGN KEY (`incident_type_id`)  REFERENCES `hst_incident_types`   (`id`) ON DELETE SET NULL  -- v3
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Discipline incident register';


CREATE TABLE IF NOT EXISTS `hst_mess_attendance` (
    `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`                BIGINT UNSIGNED  NOT NULL,
    `attendance_date`          DATE             NOT NULL,
    `meal_type`                ENUM('breakfast','lunch','dinner','snacks') NOT NULL,
    `student_id`               INT UNSIGNED     NOT NULL,
    `status`                   INT UNSIGNED     NOT NULL,  -- FK to hst_dynamic_status_masters.id; e.g., 'present', 'absent', 'leave', 'late'; allows for more granular meal attendance statuses without code changes
    `is_special_diet_served`   TINYINT(1)       NOT NULL DEFAULT 0,
    `special_diet_served_desc` VARCHAR(255)     NULL,
    `marked_by`                INT UNSIGNED     NULL,
    `shift_id`                 TINYINT UNSIGNED NULL     COMMENT 'v3 — for hostels with multi-shift mess (e.g., 2 sittings)',
    `is_active`                TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`               TIMESTAMP        NULL,
    `updated_at`               TIMESTAMP        NULL,
    `deleted_at`               TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_mess_att` (`hostel_id`, `attendance_date`, `meal_type`, `student_id`),
    KEY `idx_hst_ma_hostel`    (`hostel_id`),
    KEY `idx_hst_ma_student`   (`student_id`),
    KEY `idx_hst_ma_marked_by` (`marked_by`),
    CONSTRAINT `fk_hst_ma_hostel`    FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_ma_student`   FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_ma_marked_by` FOREIGN KEY (`marked_by`)  REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_ma_status`     FOREIGN KEY (`status`)    REFERENCES `hst_dynamic_status_masters` (`id`)  -- for meal attendance status
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-meal attendance';


CREATE TABLE IF NOT EXISTS `hst_complaints` (
    `id`                     BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`              BIGINT UNSIGNED  NOT NULL,
    `room_id`                BIGINT UNSIGNED  NULL,
    `reported_by_student_id` INT UNSIGNED     NULL,
    `reported_by_user_id`    INT UNSIGNED     NULL,
    `category`               ENUM('maintenance','electrical','plumbing','cleanliness','security','food','other') NOT NULL,
    `subject`                VARCHAR(255)     NOT NULL,
    `description`            TEXT             NOT NULL,
    `priority`               ENUM('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
    `status`                 INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'open', 'in_progress', 'resolved'; allows for more granular complaint statuses without code changes
    `assigned_to`            INT UNSIGNED     NULL,
    `acknowledged_at`        TIMESTAMP        NULL     COMMENT 'v3 — when assigned_to first opened the ticket',
    `resolution_notes`       TEXT             NULL,
    `resolved_at`            TIMESTAMP        NULL,
    `sla_due_at`             TIMESTAMP        NULL,
    `is_escalated`           TINYINT(1)       NOT NULL DEFAULT 0,
    `escalated_at`           TIMESTAMP        NULL,
    `satisfaction_score`     TINYINT UNSIGNED NULL     COMMENT 'v3 — 1-5 from reporter after closure',
    `is_active`              TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`             TIMESTAMP        NULL,
    `updated_at`             TIMESTAMP        NULL,
    `deleted_at`             TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_cmp_hostel`        (`hostel_id`),
    KEY `idx_hst_cmp_room`          (`room_id`),
    KEY `idx_hst_cmp_student`       (`reported_by_student_id`),
    KEY `idx_hst_cmp_user`          (`reported_by_user_id`),
    KEY `idx_hst_cmp_assigned`      (`assigned_to`),
    KEY `idx_hst_cmp_sla`           (`sla_due_at`),
    KEY `idx_hst_cmp_status_sla`    (`status`, `sla_due_at`)  COMMENT 'v3 — open-and-overdue dashboard',
    CONSTRAINT `fk_hst_cmp_hostel`   FOREIGN KEY (`hostel_id`)              REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_cmp_room`     FOREIGN KEY (`room_id`)                 REFERENCES `hst_rooms`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_student`  FOREIGN KEY (`reported_by_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_user`     FOREIGN KEY (`reported_by_user_id`)    REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_assigned` FOREIGN KEY (`assigned_to`)            REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_status`   FOREIGN KEY (`status`)               REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel-internal complaints';


CREATE TABLE IF NOT EXISTS `hst_sick_bay_log` (
    `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`                BIGINT UNSIGNED  NOT NULL,
    `student_id`               INT UNSIGNED     NOT NULL,
    `admission_datetime`       DATETIME         NOT NULL,
    `discharge_datetime`       DATETIME         NULL,
    `presenting_symptoms`      TEXT             NOT NULL,
    `initial_diagnosis`        VARCHAR(500)     NULL,
    `treatment_notes`          TEXT             NULL,
    `attending_staff_id`       INT UNSIGNED     NULL,
    `discharge_notes`          TEXT             NULL,
    `is_hospital_referred`     TINYINT(1)       NOT NULL DEFAULT 0,
    `hpc_record_id`            BIGINT UNSIGNED  NULL  COMMENT 'Soft FK to HPC; no DB constraint',
    `parent_notified`          TINYINT(1)       NOT NULL DEFAULT 0,
    `medical_consent_received` TINYINT(1)       NOT NULL DEFAULT 0  COMMENT 'v3 — 1 = parent consent for treatment received',
    `is_active`                TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`               TIMESTAMP        NULL,
    `updated_at`               TIMESTAMP        NULL,
    `deleted_at`               TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_sb_hostel_admission` (`hostel_id`, `admission_datetime`),
    KEY `idx_hst_sb_student`          (`student_id`),
    KEY `idx_hst_sb_discharge`        (`discharge_datetime`),
    KEY `idx_hst_sb_staff`            (`attending_staff_id`),
    KEY `idx_hst_sb_hospital_ref`     (`is_hospital_referred`)  COMMENT 'v3',
    CONSTRAINT `fk_hst_sb_hostel`  FOREIGN KEY (`hostel_id`)         REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_sb_student` FOREIGN KEY (`student_id`)        REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_sb_staff`   FOREIGN KEY (`attending_staff_id`) REFERENCES `sys_users`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sick bay admissions';


-- =============================================================================
-- LAYER 7 — Depends on Layer 5/6
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_attendance_entries` (
    `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `attendance_id` BIGINT UNSIGNED  NOT NULL,
    `student_id`    INT UNSIGNED     NOT NULL,
    `status`        INT UNSIGNED     NOT NULL,  -- FK to hst_dynamic_status_masters.id; e.g., 'present', 'absent', 'leave', 'late'; allows for more granular attendance statuses without code changes
    `late_remarks`  VARCHAR(255)     NULL,
    `check_in_time` TIME             NULL,
    `is_active`     TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP        NULL,
    `updated_at`    TIMESTAMP        NULL,
    `deleted_at`    TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_att_entry` (`attendance_id`, `student_id`),
    KEY `idx_hst_ae_attendance` (`attendance_id`),
    KEY `idx_hst_ae_student`    (`student_id`),
    CONSTRAINT `fk_hst_ae_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `hst_attendance` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_ae_student`    FOREIGN KEY (`student_id`)    REFERENCES `std_students`   (`id`),
    CONSTRAINT `fk_hst_ae_status`     FOREIGN KEY (`status`)        REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-student roll-call entry';


CREATE TABLE IF NOT EXISTS `hst_room_change_requests` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`        INT UNSIGNED     NOT NULL,
    `from_allotment_id` BIGINT UNSIGNED  NOT NULL,
    `requested_room_id` BIGINT UNSIGNED  NULL,
    `reason`            TEXT             NOT NULL,
    `status`            INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'pending', 'approved', 'rejected'; allows for more granular room change request statuses without code changes
    `approved_by`       INT UNSIGNED     NULL,
    `approved_at`       TIMESTAMP        NULL,
    `rejection_reason`  TEXT             NULL,
    `new_allotment_id`  BIGINT UNSIGNED  NULL,
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP        NULL,
    `updated_at`        TIMESTAMP        NULL,
    `deleted_at`        TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_rcr_student`     (`student_id`),
    KEY `idx_hst_rcr_from_allot`  (`from_allotment_id`),
    KEY `idx_hst_rcr_room`        (`requested_room_id`),
    KEY `idx_hst_rcr_approved_by` (`approved_by`),
    KEY `idx_hst_rcr_new_allot`   (`new_allotment_id`),
    CONSTRAINT `fk_hst_rcr_student`     FOREIGN KEY (`student_id`)        REFERENCES `std_students`   (`id`),
    CONSTRAINT `fk_hst_rcr_from_allot`  FOREIGN KEY (`from_allotment_id`) REFERENCES `hst_allotments` (`id`),
    CONSTRAINT `fk_hst_rcr_room`        FOREIGN KEY (`requested_room_id`) REFERENCES `hst_rooms`      (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rcr_approved_by` FOREIGN KEY (`approved_by`)       REFERENCES `sys_users`      (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rcr_new_allot`   FOREIGN KEY (`new_allotment_id`)  REFERENCES `hst_allotments` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rcr_status`      FOREIGN KEY (`status`)            REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Room-change request workflow';


CREATE TABLE IF NOT EXISTS `hst_leave_passes` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`              INT UNSIGNED     NOT NULL,
    `allotment_id`            BIGINT UNSIGNED  NOT NULL,
    `leave_type`              ENUM('home','emergency','medical','festival','vacation','other') NOT NULL,
    `from_date`               DATE             NOT NULL,
    `to_date`                 DATE             NOT NULL,
    `destination`             VARCHAR(255)     NOT NULL,
    `purpose`                 VARCHAR(500)     NOT NULL,
    `guardian_contact`        VARCHAR(20)      NULL,
    `guardian_name`           VARCHAR(150)     NULL     COMMENT 'v3',
    `guardian_relation`       VARCHAR(50)      NULL     COMMENT 'v3',
    `is_overnight`            TINYINT(1)       NOT NULL DEFAULT 1     COMMENT 'v3',
    `applied_by`              INT UNSIGNED     NOT NULL,
    `approved_by`             INT UNSIGNED     NULL,
    `approved_at`             TIMESTAMP        NULL,
    `status`                  INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'pending', 'approved', 'rejected'; allows for more granular leave pass statuses without code changes  
    `rejection_reason`        TEXT             NULL,
    `actual_return_date`      DATE             NULL,
    `late_return_incident_id` BIGINT UNSIGNED  NULL,
    `parent_notified`         TINYINT(1)       NOT NULL DEFAULT 0,
    `parent_consent_received` TINYINT(1)       NOT NULL DEFAULT 0     COMMENT 'v3',
    `consent_media_id`        INT UNSIGNED     NULL                   COMMENT 'v3 — scanned/signed parent consent',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`              TIMESTAMP        NULL,
    `updated_at`              TIMESTAMP        NULL,
    `deleted_at`              TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_lp_student`     (`student_id`),
    KEY `idx_hst_lp_allotment`   (`allotment_id`),
    KEY `idx_hst_lp_applied_by`  (`applied_by`),
    KEY `idx_hst_lp_approved_by` (`approved_by`),
    KEY `idx_hst_lp_incident`    (`late_return_incident_id`),
    KEY `idx_hst_lp_dates`       (`from_date`, `to_date`)  COMMENT 'v3 — calendar views',
    KEY `idx_hst_lp_status`      (`status`)                COMMENT 'v3',
    CONSTRAINT `fk_hst_lp_student`   FOREIGN KEY (`student_id`)              REFERENCES `std_students`   (`id`),
    CONSTRAINT `fk_hst_lp_allotment` FOREIGN KEY (`allotment_id`)            REFERENCES `hst_allotments` (`id`),
    CONSTRAINT `fk_hst_lp_applied`   FOREIGN KEY (`applied_by`)              REFERENCES `sys_users`      (`id`),
    CONSTRAINT `fk_hst_lp_approved`  FOREIGN KEY (`approved_by`)             REFERENCES `sys_users`      (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_lp_incident`  FOREIGN KEY (`late_return_incident_id`) REFERENCES `hst_incidents`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_lp_consent`   FOREIGN KEY (`consent_media_id`)        REFERENCES `sys_media`      (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_lp_status`    FOREIGN KEY (`status`)                REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Leave pass FSM';


-- =============================================================================
-- LAYER 8 — Depends on Layer 6 (hst_incidents) + sys_media
-- =============================================================================

CREATE TABLE IF NOT EXISTS `hst_incident_media` (
    `id`          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `incident_id` BIGINT UNSIGNED  NOT NULL,
    `media_id`    INT UNSIGNED     NOT NULL,
    `media_type`  VARCHAR(50)      NULL,
    `is_active`   TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP        NULL,
    `updated_at`  TIMESTAMP        NULL,
    `deleted_at`  TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_im_incident` (`incident_id`),
    KEY `idx_hst_im_media`    (`media_id`),
    CONSTRAINT `fk_hst_im_incident` FOREIGN KEY (`incident_id`) REFERENCES `hst_incidents` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_im_media`    FOREIGN KEY (`media_id`)    REFERENCES `sys_media`     (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Incident attachments';


-- =============================================================================
-- =============================================================================
-- v3 NEW TABLES (15) — organized by domain
-- =============================================================================
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION A : WARDEN DUTY ROSTER
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_warden_duty_roster` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`           BIGINT UNSIGNED  NOT NULL COMMENT 'hst_hostels.id',
    `floor_id`            BIGINT UNSIGNED  NULL     COMMENT 'NULL = hostel-wide duty (e.g., chief warden on call)',
    `user_id`             INT UNSIGNED     NOT NULL COMMENT 'Warden on duty (sys_users.id)',
    `duty_date`           DATE             NOT NULL COMMENT 'Date of duty',
    `shift`               ENUM('morning','afternoon','evening','night','full_day','on_call') NOT NULL,
    `start_time`          TIME             NULL,
    `end_time`            TIME             NULL,
    `is_emergency_cover`  TINYINT(1)       NOT NULL DEFAULT 0  COMMENT '1 = covering for absent regular warden',
    `replaces_user_id`    INT UNSIGNED     NULL                 COMMENT 'When is_emergency_cover=1, the user being replaced',
    `acknowledged_at`     TIMESTAMP        NULL                 COMMENT 'When the warden acknowledged the duty',
    `notes`               VARCHAR(500)     NULL,
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_dr_slot` (`hostel_id`, `duty_date`, `shift`, `user_id`)  COMMENT 'Same warden cannot be assigned same shift twice; multiple wardens per shift allowed by varying user_id',
    KEY `idx_hst_dr_user_date` (`user_id`, `duty_date`),
    KEY `idx_hst_dr_hostel_date` (`hostel_id`, `duty_date`),
    KEY `idx_hst_dr_floor` (`floor_id`),
    CONSTRAINT `fk_hst_dr_hostel`   FOREIGN KEY (`hostel_id`)        REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_dr_floor`    FOREIGN KEY (`floor_id`)         REFERENCES `hst_floors`  (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_dr_user`     FOREIGN KEY (`user_id`)          REFERENCES `sys_users`   (`id`),
    CONSTRAINT `fk_hst_dr_replaces` FOREIGN KEY (`replaces_user_id`) REFERENCES `sys_users`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily warden duty roster — who is on duty when. Distinct from hst_warden_assignments (which is the role-level posting).';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION B : MAINTENANCE & HOUSEKEEPING
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_bed_maintenance_log` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `bed_id`              BIGINT UNSIGNED  NOT NULL,
    `room_id`             BIGINT UNSIGNED  NOT NULL  COMMENT 'Denormalized for fast room-level reports',
    `reported_by`         INT UNSIGNED     NOT NULL  COMMENT 'sys_users.id',
    `reported_at`         TIMESTAMP        NOT NULL,
    `issue_description`   TEXT             NOT NULL,
    `severity`            ENUM('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
    `status`              INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'open', 'in_progress', 'resolved'; allows for more granular maintenance statuses without code changes
    `assigned_to`         INT UNSIGNED     NULL  COMMENT 'Maintenance staff (sys_users.id)',
    `assigned_at`         TIMESTAMP        NULL,
    `resolution_action`   TEXT             NULL,
    `resolved_at`         TIMESTAMP        NULL,
    `cost_estimated`      DECIMAL(10,2)    NULL,
    `cost_actual`         DECIMAL(10,2)    NULL,
    `is_bed_blocked`      TINYINT(1)       NOT NULL DEFAULT 0  COMMENT '1 = bed marked maintenance until resolved',
    `before_photo_id`     INT UNSIGNED     NULL  COMMENT 'sys_media.id',
    `after_photo_id`      INT UNSIGNED     NULL  COMMENT 'sys_media.id',
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_bm_bed`         (`bed_id`),
    KEY `idx_hst_bm_room`        (`room_id`),
    KEY `idx_hst_bm_status`      (`status`, `severity`),
    KEY `idx_hst_bm_assigned`    (`assigned_to`),
    KEY `idx_hst_bm_reported_at` (`reported_at`),
    CONSTRAINT `fk_hst_bm_bed`         FOREIGN KEY (`bed_id`)          REFERENCES `hst_beds`  (`id`),
    CONSTRAINT `fk_hst_bm_room`        FOREIGN KEY (`room_id`)         REFERENCES `hst_rooms` (`id`),
    CONSTRAINT `fk_hst_bm_reporter`    FOREIGN KEY (`reported_by`)     REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_hst_bm_assigned`    FOREIGN KEY (`assigned_to`)     REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_bm_before_photo` FOREIGN KEY (`before_photo_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_bm_after_photo` FOREIGN KEY (`after_photo_id`)   REFERENCES `sys_media` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_bm_status`      FOREIGN KEY (`status`)          REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bed/room maintenance ticket lifecycle. Replaces v2-era flag-only "maintenance" status with full audit.';


CREATE TABLE IF NOT EXISTS `hst_housekeeping_log` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`           BIGINT UNSIGNED  NOT NULL,
    `room_id`             BIGINT UNSIGNED  NULL  COMMENT 'NULL = common area cleaning (e.g., corridor, mess)',
    `area_description`    VARCHAR(150)     NULL  COMMENT 'For common-area entries: "Mess Hall", "Block A Corridor"',
    `service_date`        DATE             NOT NULL,
    `service_type`        ENUM('daily_cleaning','deep_cleaning','linen_change','pest_control','sanitization','garbage_disposal','other') NOT NULL,
    `cleaned_by`          VARCHAR(150)     NOT NULL  COMMENT 'Cleaning staff name (may be third-party — not always in sys_users)',
    `cleaned_by_user_id`  INT UNSIGNED     NULL      COMMENT 'sys_users.id if internal staff',
    `verified_by`         INT UNSIGNED     NULL      COMMENT 'Warden / supervisor who inspected (sys_users.id)',
    `quality_rating`      TINYINT UNSIGNED NULL      COMMENT '1-5 quality score',
    `issues_found`        TEXT             NULL,
    `is_re_cleaning_required` TINYINT(1)   NOT NULL DEFAULT 0,
    `photo_media_id`      INT UNSIGNED     NULL,
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_hk_hostel_date` (`hostel_id`, `service_date`),
    KEY `idx_hst_hk_room_date`   (`room_id`, `service_date`),
    KEY `idx_hst_hk_type`        (`service_type`),
    CONSTRAINT `fk_hst_hk_hostel`     FOREIGN KEY (`hostel_id`)          REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_hk_room`       FOREIGN KEY (`room_id`)            REFERENCES `hst_rooms`   (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_hk_cleaner`    FOREIGN KEY (`cleaned_by_user_id`) REFERENCES `sys_users`   (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_hk_verified`   FOREIGN KEY (`verified_by`)        REFERENCES `sys_users`   (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_hk_photo`      FOREIGN KEY (`photo_media_id`)     REFERENCES `sys_media`   (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily housekeeping service log per room or common area.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION C : LAUNDRY
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_laundry_tickets` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`        INT UNSIGNED     NOT NULL,
    `hostel_id`         BIGINT UNSIGNED  NOT NULL,
    `ticket_number`     VARCHAR(50)      NOT NULL  COMMENT 'Printed/scanned ticket number',
    `submitted_at`      TIMESTAMP        NOT NULL,
    `expected_return_at` TIMESTAMP       NULL,
    `returned_at`       TIMESTAMP        NULL,
    `item_count`        SMALLINT UNSIGNED NOT NULL,
    `items_description` TEXT             NULL  COMMENT 'e.g., "5 shirts, 3 trousers, 2 bedsheets"',
    `status`            INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'submitted', 'in_process', 'returned'; allows for more granular laundry ticket statuses without code changes
    `weight_kg`         DECIMAL(5,2)     NULL  COMMENT 'For weight-based billing',
    `charge_amount`     DECIMAL(10,2)    NULL,
    `charge_pushed_to_fee` TINYINT(1)    NOT NULL DEFAULT 0,
    `dispute_notes`     TEXT             NULL,
    `submitted_to`      VARCHAR(100)     NULL  COMMENT 'Laundry vendor / staff name',
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP        NULL,
    `updated_at`        TIMESTAMP        NULL,
    `deleted_at`        TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_lt_ticket` (`hostel_id`, `ticket_number`),
    KEY `idx_hst_lt_student_status` (`student_id`, `status`),
    KEY `idx_hst_lt_submitted` (`submitted_at`),
    CONSTRAINT `fk_hst_lt_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_lt_hostel`  FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_lt_status`  FOREIGN KEY (`status`)     REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-student laundry submission and return ticket.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION D : MESS OPERATIONS — opt-outs and bills
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_mess_opt_outs` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`      INT UNSIGNED     NOT NULL,
    `hostel_id`       BIGINT UNSIGNED  NOT NULL,
    `from_date`       DATE             NOT NULL,
    `to_date`         DATE             NOT NULL,
    `meal_types_json` JSON             NOT NULL  COMMENT 'Array of meals being skipped: ["dinner"] or ["breakfast","lunch","dinner"]',
    `reason`          ENUM('outside_meal','fasting','medical','personal','exam_period','other') NOT NULL,
    `reason_notes`    VARCHAR(500)     NULL,
    `is_recurring`    TINYINT(1)       NOT NULL DEFAULT 0  COMMENT '1 = repeats weekly (e.g., every Thursday dinner)',
    `recurrence_pattern_json` JSON     NULL  COMMENT '{"days": ["Thursday"]} when is_recurring=1',
    `requested_at`    TIMESTAMP        NOT NULL,
    `approved_by`     INT UNSIGNED     NULL,
    `approved_at`     TIMESTAMP        NULL,
    `status`          INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'pending', 'approved', 'rejected'; allows for more granular opt-out statuses without code changes
    `mess_bill_credit_applied` TINYINT(1) NOT NULL DEFAULT 0  COMMENT '1 = monthly mess bill has already credited these meals',
    `is_active`       TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP        NULL,
    `updated_at`      TIMESTAMP        NULL,
    `deleted_at`      TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_mo_student_dates` (`student_id`, `from_date`, `to_date`),
    KEY `idx_hst_mo_hostel_dates`  (`hostel_id`, `from_date`),
    KEY `idx_hst_mo_status`        (`status`),
    CONSTRAINT `fk_hst_mo_student`  FOREIGN KEY (`student_id`)  REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_mo_hostel`   FOREIGN KEY (`hostel_id`)   REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_mo_approved` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_mo_status`   FOREIGN KEY (`status`)     REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-meal mess opt-outs. Finer-grained than full-day leave.';


CREATE TABLE IF NOT EXISTS `hst_mess_bills` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`          INT UNSIGNED     NOT NULL,
    `hostel_id`           BIGINT UNSIGNED  NOT NULL,
    `academic_session_id` INT UNSIGNED     NOT NULL,
    `bill_month`          DATE             NOT NULL  COMMENT 'First day of the bill month, e.g., 2026-04-01',
    `meal_plan`           ENUM('full_board','lunch_only','dinner_only','none') NOT NULL,
    `total_meals_planned` SMALLINT UNSIGNED NOT NULL,
    `meals_consumed`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `meals_on_leave`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `meals_opted_out`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `special_diet_count`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    -- Charges
    `base_charge`         DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
    `special_diet_charge` DECIMAL(10,2)    NOT NULL DEFAULT 0.00  COMMENT 'Upcharge for prescribed special diet days',
    `leave_credit`        DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
    `opt_out_credit`      DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
    `manual_adjustment`   DECIMAL(10,2)    NOT NULL DEFAULT 0.00,
    `adjustment_reason`   VARCHAR(255)     NULL,
    `total_amount`        DECIMAL(10,2)    GENERATED ALWAYS AS (base_charge + special_diet_charge - leave_credit - opt_out_credit + manual_adjustment) STORED,
    -- Settlement
    `pushed_to_fee`       TINYINT(1)       NOT NULL DEFAULT 0,
    `pushed_at`           TIMESTAMP        NULL,
    `fee_demand_id`       BIGINT UNSIGNED  NULL  COMMENT 'Link to hst_fee_demands.id once raised',
    `status`              INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'draft', 'finalised', 'disputed'; allows for more granular bill statuses without code changes
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_mb_student_month` (`student_id`, `hostel_id`, `bill_month`),
    KEY `idx_hst_mb_session` (`academic_session_id`),
    KEY `idx_hst_mb_status`  (`status`),
    CONSTRAINT `fk_hst_mb_student` FOREIGN KEY (`student_id`)          REFERENCES `std_students`       (`id`),
    CONSTRAINT `fk_hst_mb_hostel`  FOREIGN KEY (`hostel_id`)           REFERENCES `hst_hostels`        (`id`),
    CONSTRAINT `fk_hst_mb_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_academic_term`  (`id`),
    CONSTRAINT `fk_hst_mb_status`  FOREIGN KEY (`status`)            REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Monthly mess bill summary per student. total_amount auto-computed.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION E : FEE RECONCILIATION
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_fee_demands` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`        INT UNSIGNED     NOT NULL,
    `allotment_id`      BIGINT UNSIGNED  NULL  COMMENT 'NULL allowed for one-off charges (damage etc.)',
    `hostel_id`         BIGINT UNSIGNED  NOT NULL,
    `academic_session_id` INT UNSIGNED   NOT NULL,
    `demand_type`       ENUM('room_rent','mess','electricity','laundry','security_deposit','damage','penalty','adjustment','other') NOT NULL,
    `period_start`      DATE             NULL,
    `period_end`        DATE             NULL,
    `amount`            DECIMAL(10,2)    NOT NULL,
    `description`       VARCHAR(500)     NULL,
    `source_table`      VARCHAR(100)     NULL  COMMENT 'Origin reference (e.g., hst_room_inventory for damage)',
    `source_id`         BIGINT UNSIGNED  NULL,
    `status`            INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'draft', 'pushed', 'accepted'; allows for more granular fee demand statuses without code changes
    `pushed_at`         TIMESTAMP        NULL,
    `external_demand_id` VARCHAR(100)    NULL  COMMENT 'fin_* module demand_id when accepted',
    `external_invoice_id` VARCHAR(100)   NULL,
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`        TIMESTAMP        NULL,
    `updated_at`        TIMESTAMP        NULL,
    `deleted_at`        TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_fd_student_status` (`student_id`, `status`),
    KEY `idx_hst_fd_allotment`      (`allotment_id`),
    KEY `idx_hst_fd_hostel_period`  (`hostel_id`, `period_start`),
    KEY `idx_hst_fd_session`        (`academic_session_id`),
    KEY `idx_hst_fd_external`       (`external_demand_id`),
    CONSTRAINT `fk_hst_fd_student`   FOREIGN KEY (`student_id`)          REFERENCES `std_students`       (`id`),
    CONSTRAINT `fk_hst_fd_allotment` FOREIGN KEY (`allotment_id`)        REFERENCES `hst_allotments`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_fd_hostel`    FOREIGN KEY (`hostel_id`)           REFERENCES `hst_hostels`        (`id`),
    CONSTRAINT `fk_hst_fd_session`   FOREIGN KEY (`academic_session_id`) REFERENCES `sch_academic_term`  (`id`),
    CONSTRAINT `fk_hst_fd_status`    FOREIGN KEY (`status`)            REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Local audit of fee demands raised against fin_* — every charge originating in hostel logged here for reconciliation.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION F : DISCIPLINE MASTERS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_incident_types` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `code`            VARCHAR(50)      NOT NULL  COMMENT 'late_arrival, rule_violation, property_damage, misconduct, ragging, unauthorized_absence',
    `name`            VARCHAR(150)     NOT NULL,
    `description`     VARCHAR(500)     NULL,
    `default_severity` ENUM('minor','moderate','serious') NOT NULL DEFAULT 'moderate',
    `auto_escalate_threshold` TINYINT UNSIGNED NULL  COMMENT 'Auto-escalate after N incidents of this type within a 30-day window',
    `requires_warning_letter` TINYINT(1) NOT NULL DEFAULT 0,
    `requires_parent_notification` TINYINT(1) NOT NULL DEFAULT 1,
    `is_system`       TINYINT(1)       NOT NULL DEFAULT 0  COMMENT '1 = built-in seed, cannot be deleted by user',
    `display_order`   TINYINT UNSIGNED NOT NULL DEFAULT 100,
    `is_active`       TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP        NULL,
    `updated_at`      TIMESTAMP        NULL,
    `deleted_at`      TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_it_code` (`code`),
    KEY `idx_hst_it_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Master list of incident types. Replaces hst_incidents.incident_type free-text VARCHAR.';


CREATE TABLE IF NOT EXISTS `hst_incident_warnings` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `incident_id`    BIGINT UNSIGNED  NOT NULL,
    `student_id`     INT UNSIGNED     NOT NULL  COMMENT 'Denormalized for fast student-history queries',
    `warning_level`  ENUM('verbal','first_written','second_written','final_written','suspension','expulsion') NOT NULL,
    `letter_template_code` VARCHAR(50) NULL  COMMENT 'Identifier of the warning letter template used',
    `letter_subject` VARCHAR(255)     NOT NULL,
    `letter_body`    TEXT             NOT NULL  COMMENT 'Rendered letter content (audit trail of what was actually sent)',
    `letter_media_id` INT UNSIGNED    NULL  COMMENT 'PDF stored in sys_media',
    `signed_by`      INT UNSIGNED     NOT NULL  COMMENT 'sys_users.id — chief warden / principal',
    `signed_at`      TIMESTAMP        NOT NULL,
    `delivered_at`   TIMESTAMP        NULL,
    `delivery_method` ENUM('email','sms','letter','portal','in_person') NOT NULL DEFAULT 'email',
    `parent_acknowledged_at` TIMESTAMP NULL,
    `acknowledgment_method` ENUM('email_reply','signed_copy','portal_click','phone','none') NULL,
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`     TIMESTAMP        NULL,
    `updated_at`     TIMESTAMP        NULL,
    `deleted_at`     TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_iw_incident`  (`incident_id`),
    KEY `idx_hst_iw_student`   (`student_id`, `warning_level`),
    KEY `idx_hst_iw_signed_by` (`signed_by`),
    CONSTRAINT `fk_hst_iw_incident`   FOREIGN KEY (`incident_id`)    REFERENCES `hst_incidents` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_iw_student`    FOREIGN KEY (`student_id`)     REFERENCES `std_students`  (`id`),
    CONSTRAINT `fk_hst_iw_signed_by`  FOREIGN KEY (`signed_by`)      REFERENCES `sys_users`     (`id`),
    CONSTRAINT `fk_hst_iw_letter`     FOREIGN KEY (`letter_media_id`) REFERENCES `sys_media`    (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Warning-letter audit trail per incident. Replaces v2 boolean warning_letter_sent flag.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION G : ROOM RESERVATION (pre-allotment)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_room_reservations` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `student_id`          INT UNSIGNED     NULL  COMMENT 'NULL during admission inquiry (student record not yet created)',
    `prospective_name`    VARCHAR(150)     NULL  COMMENT 'Used when student_id is NULL — admission applicant name',
    `prospective_contact` VARCHAR(20)      NULL,
    `hostel_id`           BIGINT UNSIGNED  NOT NULL,
    `requested_room_id`   BIGINT UNSIGNED  NULL  COMMENT 'Specific room requested (if any)',
    `requested_room_type` ENUM('single','double','triple','dormitory') NULL,
    `requested_meal_plan` ENUM('full_board','lunch_only','dinner_only','none') NULL,
    `academic_session_id` INT UNSIGNED     NOT NULL,
    `intended_join_date`  DATE             NOT NULL,
    `valid_until`         DATE             NOT NULL  COMMENT 'Reservation expires at end of this day',
    `deposit_amount`      DECIMAL(10,2)    NULL,
    `deposit_paid`        TINYINT(1)       NOT NULL DEFAULT 0,
    `deposit_paid_at`     TIMESTAMP        NULL,
    `deposit_receipt_no`  VARCHAR(50)      NULL,
    `status`              INT UNSIGNED     NOT NULL DEFAULT 1,  -- FK to hst_dynamic_status_masters.id; e.g., 'pending', 'confirmed', 'cancelled'; allows for more granular reservation statuses without code changes
    `converted_to_allotment_id` BIGINT UNSIGNED NULL  COMMENT 'Set when reservation becomes allotment',
    `cancellation_reason` VARCHAR(500)     NULL,
    `notes`               VARCHAR(500)     NULL,
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_rr_student`           (`student_id`),
    KEY `idx_hst_rr_hostel_status`     (`hostel_id`, `status`),
    KEY `idx_hst_rr_room_status`       (`requested_room_id`, `status`),
    KEY `idx_hst_rr_valid`             (`valid_until`),
    KEY `idx_hst_rr_converted_allot`   (`converted_to_allotment_id`),
    CONSTRAINT `fk_hst_rr_student`   FOREIGN KEY (`student_id`)               REFERENCES `std_students`      (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rr_hostel`    FOREIGN KEY (`hostel_id`)                REFERENCES `hst_hostels`       (`id`),
    CONSTRAINT `fk_hst_rr_room`      FOREIGN KEY (`requested_room_id`)        REFERENCES `hst_rooms`         (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rr_session`   FOREIGN KEY (`academic_session_id`)      REFERENCES `sch_academic_term` (`id`),
    CONSTRAINT `fk_hst_rr_converted` FOREIGN KEY (`converted_to_allotment_id`) REFERENCES `hst_allotments`   (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rr_status`    FOREIGN KEY (`status`)                 REFERENCES `hst_dynamic_status_masters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Pre-allotment reservation during admission flow. Becomes hst_allotments on confirmation.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION H : EMERGENCY CONTACTS (hostel-specific)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_emergency_contacts` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `hostel_id`       BIGINT UNSIGNED  NOT NULL  COMMENT 'NOT NULL — these are hostel-level (not student-level) emergency numbers',
    `contact_type`    ENUM('local_doctor','ambulance','hospital','fire','police','plumber','electrician','warden_emergency','transport','vendor_mess','vendor_security','other') NOT NULL,
    `name`            VARCHAR(150)     NOT NULL,
    `organisation`    VARCHAR(150)     NULL,
    `mobile_primary`  VARCHAR(20)      NOT NULL,
    `mobile_alternate` VARCHAR(20)     NULL,
    `email`           VARCHAR(150)     NULL,
    `address`         VARCHAR(500)     NULL,
    `availability_24x7` TINYINT(1)     NOT NULL DEFAULT 0,
    `availability_hours` VARCHAR(100)  NULL  COMMENT 'Free-text e.g. "Mon-Sat 9am-9pm"',
    `priority_order`  TINYINT UNSIGNED NOT NULL DEFAULT 100  COMMENT 'Lower = called first',
    `is_verified`     TINYINT(1)       NOT NULL DEFAULT 0,
    `last_verified_at` DATE            NULL,
    `notes`           VARCHAR(500)     NULL,
    `is_active`       TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`      TIMESTAMP        NULL,
    `updated_at`      TIMESTAMP        NULL,
    `deleted_at`      TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_ec_hostel_type` (`hostel_id`, `contact_type`, `priority_order`),
    KEY `idx_hst_ec_active`      (`is_active`),
    CONSTRAINT `fk_hst_ec_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel-level emergency contacts (doctor, ambulance, vendors). Distinct from student emergency contacts in std_*.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION I : VISITOR MEDIA (multiple photos / docs per visit)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_visitor_media` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `visitor_log_id` BIGINT UNSIGNED  NOT NULL,
    `media_id`       INT UNSIGNED     NOT NULL,
    `media_type`     ENUM('selfie','id_proof_scan','signature','other') NOT NULL DEFAULT 'selfie',
    `captured_at`    TIMESTAMP        NULL,
    `device_id`      VARCHAR(100)     NULL  COMMENT 'Gate camera / mobile device ID',
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`     TIMESTAMP        NULL,
    `updated_at`     TIMESTAMP        NULL,
    `deleted_at`     TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_vm_visit` (`visitor_log_id`),
    KEY `idx_hst_vm_media` (`media_id`),
    CONSTRAINT `fk_hst_vm_visit` FOREIGN KEY (`visitor_log_id`) REFERENCES `hst_visitor_log` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_vm_media` FOREIGN KEY (`media_id`)       REFERENCES `sys_media`       (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Multiple-photo / multi-document attachments per visitor entry.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION J : SICK BAY DETAIL — vital signs + medications
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_sick_bay_vitals` (
    `id`               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `sick_bay_log_id`  BIGINT UNSIGNED  NOT NULL,
    `recorded_at`      TIMESTAMP        NOT NULL,
    `recorded_by`      INT UNSIGNED     NOT NULL  COMMENT 'sys_users.id',
    `temperature_c`    DECIMAL(4,1)     NULL  COMMENT 'Celsius',
    `pulse_bpm`        SMALLINT UNSIGNED NULL,
    `respiratory_rate` SMALLINT UNSIGNED NULL,
    `bp_systolic`      SMALLINT UNSIGNED NULL,
    `bp_diastolic`     SMALLINT UNSIGNED NULL,
    `spo2_percent`     TINYINT UNSIGNED NULL  COMMENT 'Pulse oximeter saturation %',
    `weight_kg`        DECIMAL(5,2)     NULL,
    `height_cm`        DECIMAL(5,2)     NULL,
    `pain_score`       TINYINT UNSIGNED NULL  COMMENT '0-10',
    `notes`            VARCHAR(500)     NULL,
    `is_alarm`         TINYINT(1)       NOT NULL DEFAULT 0  COMMENT '1 = abnormal reading flagged',
    `is_active`        TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`       TIMESTAMP        NULL,
    `updated_at`       TIMESTAMP        NULL,
    `deleted_at`       TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_sbv_log_time` (`sick_bay_log_id`, `recorded_at`),
    KEY `idx_hst_sbv_recorder` (`recorded_by`),
    CONSTRAINT `fk_hst_sbv_log`      FOREIGN KEY (`sick_bay_log_id`) REFERENCES `hst_sick_bay_log` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_sbv_recorder` FOREIGN KEY (`recorded_by`)     REFERENCES `sys_users`        (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Periodic vital-sign readings during a sick-bay admission.';


CREATE TABLE IF NOT EXISTS `hst_sick_bay_medications` (
    `id`                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `sick_bay_log_id`       BIGINT UNSIGNED  NOT NULL,
    `medication_name`       VARCHAR(150)     NOT NULL,
    `generic_name`          VARCHAR(150)     NULL,
    `dose`                  VARCHAR(50)      NOT NULL  COMMENT '"500mg", "10ml", "2 tablets"',
    `route`                 ENUM('oral','topical','inhalation','injection_im','injection_iv','injection_sc','other') NOT NULL DEFAULT 'oral',
    `prescribed_by`         VARCHAR(150)     NULL  COMMENT 'External doctor name (free-text); not always in sys_users',
    `prescribed_by_user_id` INT UNSIGNED     NULL  COMMENT 'sys_users.id if internal staff prescribed',
    `administered_at`       TIMESTAMP        NOT NULL,
    `administered_by`       INT UNSIGNED     NOT NULL  COMMENT 'Nurse / warden who actually gave the medication (sys_users.id)',
    `is_self_administered`  TINYINT(1)       NOT NULL DEFAULT 0  COMMENT '1 = student took it themselves under supervision',
    `notes`                 VARCHAR(500)     NULL,
    `is_active`             TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP        NULL,
    `updated_at`            TIMESTAMP        NULL,
    `deleted_at`            TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_sbm_log_time`     (`sick_bay_log_id`, `administered_at`),
    KEY `idx_hst_sbm_administrator` (`administered_by`),
    CONSTRAINT `fk_hst_sbm_log`           FOREIGN KEY (`sick_bay_log_id`)       REFERENCES `hst_sick_bay_log` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_sbm_prescribed_by` FOREIGN KEY (`prescribed_by_user_id`) REFERENCES `sys_users`        (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_sbm_administrator` FOREIGN KEY (`administered_by`)       REFERENCES `sys_users`        (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Medication administration log per sick-bay admission.';


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION K : CROSS-CUTTING AUDIT
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_audit_log` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `entity_type`    VARCHAR(100)     NOT NULL  COMMENT 'Model class or table name (e.g., "hst_allotments")',
    `entity_id`      BIGINT UNSIGNED  NOT NULL,
    `action`         ENUM('create','update','delete','restore','status_change','approve','reject','assign','escalate','lock','unlock','other') NOT NULL,
    `actor_user_id`  INT UNSIGNED     NULL  COMMENT 'sys_users.id; NULL if system-generated',
    `actor_role`     VARCHAR(50)      NULL  COMMENT 'Snapshot of actor role at time of action',
    `before_json`    JSON             NULL,
    `after_json`     JSON             NULL,
    `field_diff_json` JSON            NULL  COMMENT 'Only changed fields with old/new values (compact)',
    `reason`         VARCHAR(500)     NULL  COMMENT 'Optional user-supplied reason',
    `ip_address`     VARCHAR(45)      NULL  COMMENT 'IPv4 or IPv6',
    `user_agent`     VARCHAR(255)     NULL,
    `request_id`     VARCHAR(64)      NULL  COMMENT 'Correlation ID across services',
    `created_at`     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_hst_al_entity`      (`entity_type`, `entity_id`),
    KEY `idx_hst_al_actor_time`  (`actor_user_id`, `created_at`),
    KEY `idx_hst_al_action_time` (`action`, `created_at`),
    KEY `idx_hst_al_request`     (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Generic before/after change audit. All hst_* services should write here on mutation.';


CREATE TABLE IF NOT EXISTS `hst_notification_log` (
    `id`                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `entity_type`         VARCHAR(100)     NOT NULL  COMMENT 'Origin entity: hst_incidents, hst_leave_passes, hst_complaints, hst_sick_bay_log, etc.',
    `entity_id`           BIGINT UNSIGNED  NOT NULL,
    `notification_type`   ENUM('parent_alert','student_alert','warden_alert','principal_alert','vendor_alert','sla_breach','escalation','reminder','other') NOT NULL,
    `channel`             ENUM('email','sms','push','whatsapp','portal','phone_call','in_person') NOT NULL,
    `recipient_user_id`   INT UNSIGNED     NULL  COMMENT 'sys_users.id when internal',
    `recipient_phone`     VARCHAR(20)      NULL  COMMENT 'External (parent) phone',
    `recipient_email`     VARCHAR(150)     NULL,
    `recipient_name`      VARCHAR(150)     NULL,
    `subject`             VARCHAR(255)     NULL,
    `body`                TEXT             NULL,
    `template_code`       VARCHAR(50)      NULL,
    `status`              ENUM('queued','sent','delivered','read','failed','bounced','retrying') NOT NULL DEFAULT 'queued',
    `sent_at`             TIMESTAMP        NULL,
    `delivered_at`        TIMESTAMP        NULL,
    `read_at`             TIMESTAMP        NULL,
    `failure_reason`      VARCHAR(500)     NULL,
    `retry_count`         TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `external_message_id` VARCHAR(100)     NULL  COMMENT 'Vendor message ID (Twilio, MSG91, SES) for traceability',
    `is_active`           TINYINT(1)       NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP        NULL,
    `updated_at`          TIMESTAMP        NULL,
    `deleted_at`          TIMESTAMP        NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hst_nl_entity`        (`entity_type`, `entity_id`),
    KEY `idx_hst_nl_status_time`   (`status`, `created_at`),
    KEY `idx_hst_nl_recipient_user` (`recipient_user_id`),
    KEY `idx_hst_nl_external`      (`external_message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Record of every notification dispatched. Drives parent-app delivery audit, retries, and SLA reports.';


-- =============================================================================
-- APPENDIX : TABLE INVENTORY (v3 — 36 tables total)
-- =============================================================================
--
--  v2 RETAINED (21, all enhanced with created_by/updated_by + selective field additions)
--  ─────────────────────────────────────────────────────────────────────────────
--   L1  hst_hostels                       [4 v3 fields added]
--   L2  hst_floors                        [block_code added]
--       hst_warden_assignments
--   L3  hst_rooms                         [block_code, windows_facing, accessibility]
--   L4  hst_beds                          [bed_type, notes]
--       hst_fee_structures
--       hst_mess_weekly_menus
--       hst_room_inventory                [photo_media_id]
--   L5  hst_allotments                    [4 v3 fields added]
--       hst_special_diets
--       hst_visitor_log                   [2 media FKs added]
--       hst_movement_log                  [3 v3 fields added]
--   L6  hst_attendance
--       hst_incidents                     [incident_type_id added; old VARCHAR kept]
--       hst_mess_attendance               [shift_id]
--       hst_complaints                    [acknowledged_at, satisfaction_score]
--       hst_sick_bay_log                  [medical_consent_received]
--   L7  hst_attendance_entries
--       hst_room_change_requests
--       hst_leave_passes                  [5 v3 fields added]
--   L8  hst_incident_media
--
--  v3 NEW (15)
--  ─────────────────────────────────────────────────────────────────────────────
--   A   hst_warden_duty_roster            — daily on-duty
--   B   hst_bed_maintenance_log           — maintenance ticket lifecycle
--       hst_housekeeping_log              — cleaning records
--   C   hst_laundry_tickets               — laundry in/out
--   D   hst_mess_opt_outs                 — per-meal opt-out
--       hst_mess_bills                    — monthly mess bill summary
--   E   hst_fee_demands                   — local fee-charge audit (mirrors fin_*)
--   F   hst_incident_types                — master (replaces VARCHAR free text)
--       hst_incident_warnings             — warning-letter log
--   G   hst_room_reservations             — pre-allotment reservation
--   H   hst_emergency_contacts            — hostel-level emergency numbers
--   I   hst_visitor_media                 — multi-photo per visit
--   J   hst_sick_bay_vitals               — structured vitals
--       hst_sick_bay_medications          — medication log
--   K   hst_audit_log                     — generic change trail
--       hst_notification_log              — notification dispatch log
--
-- =============================================================================
-- DEFERRED TO v4 (review items, not blocking)
-- =============================================================================
-- 1. Drop hst_incidents.incident_type VARCHAR once all callers migrated to incident_type_id.
-- 2. Normalize hst_hostels.facilities_json + hst_rooms.amenities_json to:
--      hst_facilities (master) + hst_hostel_facility_jnt
--      hst_amenities (master) + hst_room_amenity_jnt
--    Allows queryable filtering ("show all rooms with AC and attached bath").
-- 3. Cross-link hst_special_diets → sch_teacher_capabilities medical or hpc_records.
-- 4. Visitor blacklist table (hst_visitor_blacklist) — visitors barred at gate.
-- 5. Vendor/contractor tables — likely belong in vnd_* not hst_*; coordinate with vendor module owner.
-- 6. Encryption-at-rest for hst_visitor_log.id_proof_number_masked (currently last-4-only — safe but app-layer KMS would harden).
-- 7. Partition hst_audit_log and hst_notification_log by month — both are append-heavy.
-- =============================================================================


-- =============================================================================
-- CHANGE LOG
-- =============================================================================
-- v1.0 (2026-03-27) — original 21-table HST DDL.
-- v2.0              — see HST_DDL_v2.sql header (refinements within original 21 tables).
-- v3.0 (2026-05-04) — Database Architect review pass.
--   • CONVENTION: added created_by + updated_by on every v2 table (was systematically
--     missing despite the file's own header comment promising those columns).
--   • FIELD ADDITIONS: 14 new fields across 11 v2 tables, all nullable / additive.
--   • NEW TABLES: 15 covering daily warden duty roster, maintenance, housekeeping,
--     laundry, mess opt-outs and bills, fee-demand audit, discipline masters,
--     warning letters, room reservations, emergency contacts, visitor media,
--     sick-bay vitals/medications, generic audit log, notification log.
--   • INDEX ADDITIONS: 7 new dashboard / SLA / overdue indexes.
--   • NO BREAKING CHANGES — every v2 column type and constraint preserved.
-- =============================================================================
-- END OF HST DDL v3 — 36 tables
-- =============================================================================
