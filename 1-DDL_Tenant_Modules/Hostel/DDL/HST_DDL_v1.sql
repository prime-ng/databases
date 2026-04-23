-- =============================================================================
-- HST — Hostel Management Module DDL
-- Module: Hostel Management (Modules\Hostel)
-- Table Prefix: hst_* (21 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-27
-- Based on: HST_Hostel_Requirement.md v2
-- Sub-Modules: K1 Room & Bed Mgmt, K2 Allocation, K3 Attendance,
--              K3b Leave Pass, K4 Mess, K5 Fee, K6 Complaints,
--              Warden Mgmt, Visitor Log, Sick Bay, Room Inventory
-- =============================================================================
--
-- FK TYPE NOTE:
--   hst_* PKs and internal FKs: BIGINT UNSIGNED
--   Cross-module FKs: INT UNSIGNED (matches actual parent table PK types in tenant_db_v2.sql)
--     sys_users.id        → INT UNSIGNED
--     sys_media.id        → INT UNSIGNED
--     std_students.id     → INT UNSIGNED
--     sch_academic_term.id → INT UNSIGNED  (requirement says sch_academic_sessions — actual DDL: sch_academic_term)
--   created_by / updated_by: INT UNSIGNED (consistent with sys_users.id = INT UNSIGNED)
--   hst_incident_media.media_id: INT UNSIGNED (NOT BIGINT) — matches sys_media.id
--   hst_sick_bay_log.hpc_record_id: BIGINT UNSIGNED NULL — NO FK CONSTRAINT (soft ref to HPC module)
--
-- TABLE ORDER (dependency-safe, Layer 1 → 8):
--   L1: hst_hostels
--   L2: hst_floors, hst_warden_assignments
--   L3: hst_rooms
--   L4: hst_beds, hst_fee_structures, hst_mess_weekly_menus, hst_room_inventory
--   L5: hst_allotments, hst_special_diets, hst_visitor_log, hst_movement_log
--   L6: hst_attendance, hst_incidents, hst_mess_attendance, hst_complaints, hst_sick_bay_log
--   L7: hst_attendance_entries, hst_room_change_requests, hst_leave_passes
--   L8: hst_incident_media
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 1 — No hst_* dependencies
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_hostels` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `name`                 VARCHAR(150)     NOT NULL COMMENT 'Hostel/building display name',
    `type`                 ENUM('boys','girls','mixed') NOT NULL COMMENT 'Gender restriction: boys=male students only, girls=female only, mixed=no restriction',
    `code`                 VARCHAR(20)      NULL     COMMENT 'Short hostel code (BH1, GH1, etc.); UNIQUE nullable — multiple NULLs allowed',
    `warden_id`            INT UNSIGNED     NULL     COMMENT 'Current chief warden (sys_users.id); nullable — hostel may not have an assigned warden',
    `total_capacity`       SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total bed count; recomputed by AllotmentService when beds are added/removed/changed',
    `current_occupancy`    SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Denormalized occupied bed count; maintained synchronously by AllotmentService on every allot/vacate/transfer',
    `sick_bay_capacity`    TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Maximum beds in sick bay for this hostel; used by SickBayService::admit() capacity check',
    `address`              VARCHAR(500)     NULL     COMMENT 'Physical location/address of hostel building',
    `contact_phone`        VARCHAR(20)      NULL     COMMENT 'Hostel direct contact phone number',
    `visiting_days_json`   JSON             NULL     COMMENT 'Visiting day/hour config array; e.g. [{"day":"Sunday","from":"10:00","to":"13:00"}]',
    `facilities_json`      JSON             NULL     COMMENT 'Array of available facility names; e.g. ["WiFi","Common Room","Laundry","Medical Room"]',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable; 1=active, 0=disabled',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp; NULL = not deleted',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_hostel_code` (`code`),
    KEY `idx_hst_hostel_warden` (`warden_id`),

    CONSTRAINT `fk_hst_hostel_warden` FOREIGN KEY (`warden_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel/building configuration master; one row per hostel building';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 2 — Depends on Layer 1 (hst_hostels) only
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_floors` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`            BIGINT UNSIGNED  NOT NULL COMMENT 'Parent hostel (hst_hostels.id)',
    `floor_number`         TINYINT          NOT NULL COMMENT 'Floor number; 0 = Ground Floor',
    `display_name`         VARCHAR(100)     NULL     COMMENT 'Human-readable floor label; e.g. Ground Floor, First Floor, North Wing',
    `floor_incharge_id`    INT UNSIGNED     NULL     COMMENT 'Current floor incharge staff (sys_users.id); nullable',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_floor_num` (`hostel_id`, `floor_number`),
    KEY `idx_hst_floor_hostel` (`hostel_id`),
    KEY `idx_hst_floor_incharge` (`floor_incharge_id`),

    CONSTRAINT `fk_hst_floor_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_floor_incharge` FOREIGN KEY (`floor_incharge_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Floor within a hostel building; unique per (hostel, floor_number)';


CREATE TABLE IF NOT EXISTS `hst_warden_assignments` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`            BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel context (hst_hostels.id)',
    `floor_id`             BIGINT UNSIGNED  NULL     COMMENT 'Floor scope (hst_floors.id); NULL = hostel-level chief warden assignment',
    `user_id`              INT UNSIGNED     NOT NULL COMMENT 'Staff assigned as warden (sys_users.id)',
    `assignment_type`      ENUM('chief','block','floor','assistant') NOT NULL COMMENT 'Warden role: chief=chief warden of entire hostel, block=block warden, floor=floor incharge, assistant=assistant warden',
    `effective_from`       DATE             NOT NULL COMMENT 'Assignment start date',
    `effective_to`         DATE             NULL     COMMENT 'Assignment end date; NULL = currently active',
    `remarks`              VARCHAR(300)     NULL     COMMENT 'Rotation notes or reason for assignment change',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_wa_hostel_floor_to` (`hostel_id`, `floor_id`, `effective_to`),
    KEY `idx_hst_wa_user` (`user_id`),
    KEY `idx_hst_wa_floor` (`floor_id`),

    CONSTRAINT `fk_hst_wa_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_wa_floor` FOREIGN KEY (`floor_id`) REFERENCES `hst_floors` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_wa_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Warden rotation log; INDEX (hostel_id, floor_id, effective_to) used for current-warden lookup';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 3 — Depends on Layer 2 (hst_floors)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_rooms` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `floor_id`             BIGINT UNSIGNED  NOT NULL COMMENT 'Parent floor (hst_floors.id)',
    `room_number`          VARCHAR(20)      NOT NULL COMMENT 'Room number/label within floor; e.g. 101, A-12',
    `room_type`            ENUM('single','double','triple','dormitory') NOT NULL COMMENT 'Room type: single=1 student, double=2, triple=3, dormitory=4+',
    `capacity`             TINYINT UNSIGNED NOT NULL COMMENT 'Total beds in room; max allotable students',
    `current_occupancy`    TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Denormalized occupied bed count; maintained by AllotmentService',
    `status`               ENUM('available','full','maintenance') NOT NULL DEFAULT 'available' COMMENT 'Room status: auto-set to full when current_occupancy >= capacity (BR-HST-010); maintenance = blocked from allotments',
    `amenities_json`       JSON             NULL     COMMENT 'Array of room amenities; e.g. ["AC","Attached Bath","Ceiling Fan","WiFi Port"]',
    `priority_flags_json`  JSON             NULL     COMMENT 'Priority allocation flags; e.g. {"medical":true,"senior":false,"merit":false}',
    `notes`                VARCHAR(500)     NULL     COMMENT 'Admin notes for this room',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_room_num` (`floor_id`, `room_number`),
    KEY `idx_hst_room_floor` (`floor_id`),

    CONSTRAINT `fk_hst_room_floor` FOREIGN KEY (`floor_id`) REFERENCES `hst_floors` (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Room within a floor; status auto-updated by AllotmentService on occupancy change (BR-HST-010)';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 4 — Depends on Layer 3 + cross-module
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_beds` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `room_id`              BIGINT UNSIGNED  NOT NULL COMMENT 'Parent room (hst_rooms.id)',
    `bed_label`            VARCHAR(20)      NOT NULL COMMENT 'Bed label within room; e.g. Bed A, Bed 1, Lower Bunk',
    `status`               ENUM('available','occupied','maintenance') NOT NULL DEFAULT 'available' COMMENT 'Bed status: available=can be allotted, occupied=active allotment exists, maintenance=blocked',
    `condition`            ENUM('good','fair','poor') NOT NULL DEFAULT 'good' COMMENT 'Physical condition of the bed',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_bed_label` (`room_id`, `bed_label`),
    KEY `idx_hst_bed_room` (`room_id`),

    CONSTRAINT `fk_hst_bed_room` FOREIGN KEY (`room_id`) REFERENCES `hst_rooms` (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Individual bed within a room; status updated by AllotmentService on allot/vacate';


CREATE TABLE IF NOT EXISTS `hst_fee_structures` (
    `id`                          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`                   BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel this fee structure applies to (hst_hostels.id)',
    `academic_session_id`         INT UNSIGNED     NOT NULL COMMENT 'Academic session scope (sch_academic_term.id)',
    `room_type`                   ENUM('single','double','triple','dormitory') NOT NULL COMMENT 'Room type this fee rate applies to',
    `meal_plan`                   ENUM('full_board','lunch_only','dinner_only','none') NOT NULL COMMENT 'Meal plan variant: full_board=3 meals, lunch_only, dinner_only, none=no mess',
    `room_rent_monthly`           DECIMAL(10,2)    NOT NULL DEFAULT 0.00 COMMENT 'Monthly room rent amount in INR',
    `mess_charge_monthly`         DECIMAL(10,2)    NOT NULL DEFAULT 0.00 COMMENT 'Monthly mess charge; varies by meal_plan selection',
    `electricity_charge_monthly`  DECIMAL(10,2)    NOT NULL DEFAULT 0.00 COMMENT 'Monthly electricity and water charge',
    `laundry_charge_monthly`      DECIMAL(10,2)    NOT NULL DEFAULT 0.00 COMMENT 'Monthly laundry charge',
    `security_deposit`            DECIMAL(10,2)    NOT NULL DEFAULT 0.00 COMMENT 'One-time security deposit at allotment',
    `effective_from`              DATE             NOT NULL COMMENT 'Fee rate effective start date; allows mid-year fee revisions',
    `effective_to`                DATE             NULL     COMMENT 'Fee rate effective end date; NULL = still current',
    `is_active`                   TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`                  INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`                  INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`                  TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`                  TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`                  TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_fee_struct` (`hostel_id`, `academic_session_id`, `room_type`, `meal_plan`, `effective_from`),
    KEY `idx_hst_fs_hostel` (`hostel_id`),
    KEY `idx_hst_fs_session` (`academic_session_id`),

    CONSTRAINT `fk_hst_fs_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_fs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_academic_term` (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel fee rates per room type per meal plan per academic session; no FK to fin_* tables — HostelFeeService pushes demands via service call (BR-HST-011/015)';


CREATE TABLE IF NOT EXISTS `hst_mess_weekly_menus` (
    `id`                          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`                   BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel this menu belongs to (hst_hostels.id)',
    `academic_session_id`         INT UNSIGNED     NOT NULL COMMENT 'Academic session (sch_academic_term.id)',
    `week_start_date`             DATE             NOT NULL COMMENT 'Monday of the menu week (week_start_date must be Monday; validated in FormRequest)',
    `day_of_week`                 TINYINT UNSIGNED NOT NULL COMMENT 'Day: 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday, 7=Sunday',
    `meal_type`                   ENUM('breakfast','lunch','dinner','snacks') NOT NULL COMMENT 'Meal time slot',
    `menu_description`            TEXT             NULL     COMMENT 'Detailed menu items description for this meal',
    `is_special_diet_available`   TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = special diet option available for this meal slot',
    `special_diet_description`    VARCHAR(500)     NULL     COMMENT 'Description of special diet being offered (if is_special_diet_available=1)',
    `is_published`                TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = published and visible to students/parents via portal; 0 = draft',
    `is_active`                   TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`                  INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`                  INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`                  TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`                  TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`                  TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_menu_slot` (`hostel_id`, `week_start_date`, `day_of_week`, `meal_type`),
    KEY `idx_hst_menu_hostel` (`hostel_id`),
    KEY `idx_hst_menu_session` (`academic_session_id`),

    CONSTRAINT `fk_hst_menu_hostel` FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_menu_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_academic_term` (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Weekly mess menu plan; one row per hostel/week/day/meal combination; copy-week copies all 28 rows (7 days x 4 meals)';


CREATE TABLE IF NOT EXISTS `hst_room_inventory` (
    `id`                     BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `room_id`                BIGINT UNSIGNED  NOT NULL COMMENT 'Room this inventory item belongs to (hst_rooms.id)',
    `item_name`              VARCHAR(150)     NOT NULL COMMENT 'Furniture/fixture name; e.g. Bed, Mattress, Study Table, Chair, Cupboard, Ceiling Fan',
    `quantity`               TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Count of this item in the room',
    `condition`              ENUM('good','fair','poor','under_repair','disposed') NOT NULL DEFAULT 'good' COMMENT 'Current condition of item',
    `last_inspected_at`      DATE             NULL     COMMENT 'Date of last physical inspection',
    `damage_description`     TEXT             NULL     COMMENT 'Description of damage (if condition=poor/under_repair)',
    `estimated_repair_cost`  DECIMAL(10,2)    NULL     COMMENT 'Estimated cost to repair or replace damaged item',
    `repair_status`          ENUM('none','pending','under_repair','repaired','written_off') NOT NULL DEFAULT 'none' COMMENT 'Repair workflow status: none=undamaged, pending=repair requested, under_repair=in workshop, repaired=fixed, written_off=disposed',
    `responsible_student_id` INT UNSIGNED     NULL     COMMENT 'Student found responsible for damage (std_students.id); nullable — set only when student identified',
    `charge_pushed_to_fee`   TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = damage charge pushed to StudentFee module via HostelFeeService::pushDamageCharge()',
    `is_active`              TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`             INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`             INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`             TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`             TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`             TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_inv_room` (`room_id`),
    KEY `idx_hst_inv_student` (`responsible_student_id`),

    CONSTRAINT `fk_hst_inv_room` FOREIGN KEY (`room_id`) REFERENCES `hst_rooms` (`id`),
    CONSTRAINT `fk_hst_inv_student` FOREIGN KEY (`responsible_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Room furniture and fixtures inventory; damage reporting and repair workflow; cost recovery via HostelFeeService';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 5 — Depends on Layer 4 + cross-module (std_students)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_allotments` (
    `id`                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `student_id`            INT UNSIGNED     NOT NULL COMMENT 'Student being allotted (std_students.id)',
    `bed_id`                BIGINT UNSIGNED  NOT NULL COMMENT 'Assigned bed (hst_beds.id)',
    `academic_session_id`   INT UNSIGNED     NOT NULL COMMENT 'Academic session scope (sch_academic_term.id)',
    `allotment_date`        DATE             NOT NULL COMMENT 'Date student was allotted to this bed',
    `vacating_date`         DATE             NULL     COMMENT 'Date student vacated; NULL = currently occupying the bed',
    `meal_plan`             ENUM('full_board','lunch_only','dinner_only','none') NOT NULL DEFAULT 'full_board' COMMENT 'Meal plan: full_board=3 meals, lunch_only, dinner_only, none=no mess (fee computed accordingly)',
    `status`                ENUM('active','vacated','transferred','waitlisted') NOT NULL DEFAULT 'active' COMMENT 'Allotment lifecycle: active=currently occupying, vacated=left hostel, transferred=moved to different bed, waitlisted=waiting for bed',
    `remarks`               VARCHAR(500)     NULL     COMMENT 'Notes for this allotment',

    -- GENERATED COLUMNS for partial UNIQUE index (double-allotment prevention)
    -- BR-HST-001: one active allotment per bed at a time
    -- BR-HST-002: one active allotment per student at a time
    `gen_active_bed_id`     BIGINT           GENERATED ALWAYS AS (IF(`status` = 'active', `bed_id`, NULL)) STORED COMMENT 'Generated: bed_id when active, NULL otherwise; enables partial UNIQUE on active allotments per bed (BR-HST-001)',
    `gen_active_student_id` BIGINT           GENERATED ALWAYS AS (IF(`status` = 'active', `student_id`, NULL)) STORED COMMENT 'Generated: student_id when active, NULL otherwise; enables partial UNIQUE on active allotments per student (BR-HST-002)',

    `is_active`             TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`            INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`            INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`            TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`            TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`            TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_allot_active_bed`     (`gen_active_bed_id`),
    UNIQUE KEY `uq_hst_allot_active_student` (`gen_active_student_id`),
    KEY `idx_hst_allot_student_status`  (`student_id`, `status`),
    KEY `idx_hst_allot_bed_status`      (`bed_id`, `status`),
    KEY `idx_hst_allot_session`         (`academic_session_id`),

    CONSTRAINT `fk_hst_allot_student` FOREIGN KEY (`student_id`)           REFERENCES `std_students`       (`id`),
    CONSTRAINT `fk_hst_allot_bed`     FOREIGN KEY (`bed_id`)                REFERENCES `hst_beds`           (`id`),
    CONSTRAINT `fk_hst_allot_session` FOREIGN KEY (`academic_session_id`)   REFERENCES `sch_academic_term`  (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Student bed allotment; UNIQUE on gen_active_bed_id prevents 2 active allotments to same bed (BR-HST-001); UNIQUE on gen_active_student_id prevents student with 2 active allotments (BR-HST-002)';


CREATE TABLE IF NOT EXISTS `hst_special_diets` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `student_id`           INT UNSIGNED     NOT NULL COMMENT 'Student with special dietary requirement (std_students.id)',
    `hostel_id`            BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel context for this diet assignment (hst_hostels.id)',
    `diet_type`            ENUM('diabetic','jain_vegetarian','gluten_free','nut_allergy','religious_fasting','custom') NOT NULL COMMENT 'Diet category: diabetic, jain_vegetarian, gluten_free, nut_allergy, religious_fasting, custom (use custom_description for details)',
    `custom_description`   VARCHAR(300)     NULL     COMMENT 'Detailed description for custom diet type; required when diet_type=custom',
    `fasting_days_json`    JSON             NULL     COMMENT 'Specific fasting days or periods for religious_fasting type; e.g. [{"day":"Monday"},{"period":"Navratri"}]',
    `effective_from`       DATE             NOT NULL COMMENT 'Diet assignment start date',
    `effective_to`         DATE             NULL     COMMENT 'Diet end date; NULL = ongoing for academic year',
    `prescribed_by`        VARCHAR(150)     NULL     COMMENT 'Doctor or authority who prescribed this diet',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_sd_student` (`student_id`),
    KEY `idx_hst_sd_hostel`  (`hostel_id`),

    CONSTRAINT `fk_hst_sd_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_sd_hostel`  FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-student special diet assignments; flagged in mess attendance marking UI when student is marked present';


CREATE TABLE IF NOT EXISTS `hst_visitor_log` (
    `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`                BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel being visited (hst_hostels.id)',
    `student_id`               INT UNSIGNED     NOT NULL COMMENT 'Student being visited (std_students.id)',
    `visitor_name`             VARCHAR(150)     NOT NULL COMMENT 'Visitor full name',
    `relationship`             ENUM('parent','guardian','sibling','relative','other') NOT NULL COMMENT 'Visitor relationship to student',
    `visitor_phone`            VARCHAR(20)      NULL     COMMENT 'Visitor contact phone number',
    `id_proof_type`            VARCHAR(50)      NULL     COMMENT 'ID proof type: Aadhaar / PAN / Passport / DL',
    `id_proof_number_masked`   VARCHAR(30)      NULL     COMMENT 'LAST 4 DIGITS ONLY of ID proof number — full number never stored (security policy)',
    `visit_date`               DATE             NOT NULL COMMENT 'Date of visit',
    `in_time`                  TIME             NOT NULL COMMENT 'Visitor check-in time',
    `out_time`                 TIME             NULL     COMMENT 'Visitor check-out time; NULL = still inside hostel',
    `purpose`                  VARCHAR(300)     NULL     COMMENT 'Purpose of visit',
    `allowed_by`               INT UNSIGNED     NULL     COMMENT 'Warden who authorised entry (sys_users.id); nullable',
    `is_outside_visiting_hours` TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = visit logged outside configured visiting hours (hst_hostels.visiting_days_json)',
    `override_reason`          VARCHAR(300)     NULL     COMMENT 'Warden reason for allowing out-of-hours visit; required when is_outside_visiting_hours=1 (BR-HST-021)',
    `is_active`                TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`               INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`               INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`               TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`               TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`               TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_vl_hostel_date` (`hostel_id`, `visit_date`),
    KEY `idx_hst_vl_student`     (`student_id`),
    KEY `idx_hst_vl_allowed_by`  (`allowed_by`),

    CONSTRAINT `fk_hst_vl_hostel`     FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_vl_student`    FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_vl_allowed_by` FOREIGN KEY (`allowed_by`) REFERENCES `sys_users`    (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel visitor register; separate from campus-wide Frontdesk module (fnt_*); ID proof stored as last 4 digits only';


CREATE TABLE IF NOT EXISTS `hst_movement_log` (
    `id`                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `student_id`            INT UNSIGNED     NOT NULL COMMENT 'Student who went out (std_students.id)',
    `hostel_id`             BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel (hst_hostels.id)',
    `movement_date`         DATE             NOT NULL COMMENT 'Date of out-movement',
    `out_time`              TIME             NOT NULL COMMENT 'Departure time from hostel',
    `in_time`               TIME             NULL     COMMENT 'Actual return time; NULL = student has not returned yet',
    `expected_return_time`  TIME             NULL     COMMENT 'Expected return time (for pending-returns dashboard)',
    `destination`           VARCHAR(255)     NOT NULL COMMENT 'Destination or reason for going out',
    `purpose`               VARCHAR(500)     NULL     COMMENT 'Additional purpose details',
    `gate_pass_issued_by`   INT UNSIGNED     NULL     COMMENT 'Warden who issued the gate pass (sys_users.id); nullable',
    `overdue_notified`      TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = overdue return notification already sent to parent',
    `is_active`             TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`            INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`            INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`            TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`            TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`            TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_ml_hostel_date`   (`hostel_id`, `movement_date`),
    KEY `idx_hst_ml_student_in`    (`student_id`, `in_time`),
    KEY `idx_hst_ml_issued_by`     (`gate_pass_issued_by`),

    CONSTRAINT `fk_hst_ml_student`   FOREIGN KEY (`student_id`)           REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_ml_hostel`    FOREIGN KEY (`hostel_id`)             REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_ml_issued_by` FOREIGN KEY (`gate_pass_issued_by`)   REFERENCES `sys_users`    (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='In-out movement register; INDEX(student_id, in_time) used for pending-returns query WHERE in_time IS NULL';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 6 — Depends on Layer 5 + cross-module
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_attendance` (
    `id`              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`       BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel for this roll call (hst_hostels.id)',
    `attendance_date` DATE             NOT NULL COMMENT 'Roll call date',
    `shift`           ENUM('morning','evening','night') NOT NULL COMMENT 'Shift: morning=06:30, evening=19:00, night=21:30 (configurable per school)',
    `marked_by`       INT UNSIGNED     NOT NULL COMMENT 'Warden who created this session (sys_users.id)',
    `present_count`   SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Pre-computed present count; set by HstAttendanceService::computeAndStoreCounts() at save time — never aggregated on load',
    `absent_count`    SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Pre-computed absent count; set at save time',
    `leave_count`     SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Pre-computed on-leave count; set at save time',
    `late_count`      SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Pre-computed late arrival count; set at save time',
    `is_locked`       TINYINT(1)        NOT NULL DEFAULT 0 COMMENT '1 = locked after 24 hours; editable only by Chief Warden (hostel.attendance.lock permission)',
    `remarks`         VARCHAR(500)      NULL     COMMENT 'Session-level notes by marking warden',
    `is_active`       TINYINT(1)        NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`      INT UNSIGNED      NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`      INT UNSIGNED      NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`      TIMESTAMP         NULL     COMMENT 'Record creation timestamp',
    `updated_at`      TIMESTAMP         NULL     COMMENT 'Last update timestamp',
    `deleted_at`      TIMESTAMP         NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_att_session` (`hostel_id`, `attendance_date`, `shift`),
    KEY `idx_hst_att_hostel`     (`hostel_id`),
    KEY `idx_hst_att_marked_by`  (`marked_by`),

    CONSTRAINT `fk_hst_att_hostel`    FOREIGN KEY (`hostel_id`) REFERENCES `hst_hostels` (`id`),
    CONSTRAINT `fk_hst_att_marked_by` FOREIGN KEY (`marked_by`) REFERENCES `sys_users`   (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Roll call session; UNIQUE(hostel_id, attendance_date, shift) prevents duplicate sessions; counts stored at save time (BR-HST-007)';


CREATE TABLE IF NOT EXISTS `hst_incidents` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `student_id`           INT UNSIGNED     NOT NULL COMMENT 'Student involved in incident (std_students.id)',
    `hostel_id`            BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel where incident occurred (hst_hostels.id)',
    `incident_date`        DATE             NOT NULL COMMENT 'Date of incident',
    `incident_time`        TIME             NULL     COMMENT 'Time of incident (optional)',
    `incident_type`        VARCHAR(100)     NOT NULL COMMENT 'Type: late_arrival / rule_violation / property_damage / misconduct / ragging / unauthorized_absence / other; reference values seeded via HstIncidentTypeSeeder',
    `description`          TEXT             NOT NULL COMMENT 'Detailed description of the incident',
    `severity`             ENUM('minor','moderate','serious') NOT NULL COMMENT 'Severity level: minor=record only, moderate=parent notification, serious=parent notification + Principal escalation',
    `action_taken`         TEXT             NULL     COMMENT 'Action taken by warden',
    `reported_by`          INT UNSIGNED     NOT NULL COMMENT 'Warden who recorded the incident (sys_users.id)',
    `is_escalated`         TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = escalated to Principal',
    `escalated_at`         TIMESTAMP        NULL     COMMENT 'Escalation timestamp',
    `warning_letter_sent`  TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = warning letter PDF generated and sent via IncidentService::generateWarningLetter()',
    `parent_notified`      TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = parent notification dispatched (HostelIncidentRecorded event)',
    `is_auto_generated`    TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = automatically created by system (e.g., late return from leave via LeavePassService::markReturned())',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_inc_student`     (`student_id`),
    KEY `idx_hst_inc_hostel`      (`hostel_id`),
    KEY `idx_hst_inc_reported_by` (`reported_by`),
    KEY `idx_hst_inc_date`        (`incident_date`),

    CONSTRAINT `fk_hst_inc_student`     FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_inc_hostel`      FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_inc_reported_by` FOREIGN KEY (`reported_by`) REFERENCES `sys_users`   (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Discipline incident register; is_auto_generated=1 for late-return incidents; 3+ incidents flags repeated_offender on dashboard (BR-HST-022)';


CREATE TABLE IF NOT EXISTS `hst_mess_attendance` (
    `id`                       BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`                BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel (hst_hostels.id)',
    `attendance_date`          DATE             NOT NULL COMMENT 'Date of meal',
    `meal_type`                ENUM('breakfast','lunch','dinner','snacks') NOT NULL COMMENT 'Meal time slot',
    `student_id`               INT UNSIGNED     NOT NULL COMMENT 'Student (std_students.id)',
    `status`                   ENUM('present','absent','on_leave','opted_out') NOT NULL COMMENT 'Meal status: present=attended, absent=not attended, on_leave=set by LeavePassService on leave approval (BR-HST-006), opted_out=student opted out',
    `is_special_diet_served`   TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = special diet was served to this student at this meal',
    `special_diet_served_desc` VARCHAR(255)     NULL     COMMENT 'Description of special diet served (if is_special_diet_served=1)',
    `marked_by`                INT UNSIGNED     NULL     COMMENT 'Mess supervisor who marked (sys_users.id); NULL if auto-marked by LeavePassService',
    `is_active`                TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`               INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`               INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`               TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`               TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`               TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_mess_att` (`hostel_id`, `attendance_date`, `meal_type`, `student_id`),
    KEY `idx_hst_ma_hostel`    (`hostel_id`),
    KEY `idx_hst_ma_student`   (`student_id`),
    KEY `idx_hst_ma_marked_by` (`marked_by`),

    CONSTRAINT `fk_hst_ma_hostel`    FOREIGN KEY (`hostel_id`)  REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_ma_student`   FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_ma_marked_by` FOREIGN KEY (`marked_by`)  REFERENCES `sys_users`    (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Meal attendance per student per meal; on_leave status auto-set by LeavePassService on leave approval (BR-HST-006)';


CREATE TABLE IF NOT EXISTS `hst_complaints` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`               BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel (hst_hostels.id)',
    `room_id`                 BIGINT UNSIGNED  NULL     COMMENT 'Specific room related to complaint (hst_rooms.id); nullable for general complaints',
    `reported_by_student_id`  INT UNSIGNED     NULL     COMMENT 'Student reporter (std_students.id); nullable — staff may report',
    `reported_by_user_id`     INT UNSIGNED     NULL     COMMENT 'Staff reporter (sys_users.id); nullable — student may report',
    `category`                ENUM('maintenance','electrical','plumbing','cleanliness','security','food','other') NOT NULL COMMENT 'Complaint category',
    `subject`                 VARCHAR(255)     NOT NULL COMMENT 'Short subject line',
    `description`             TEXT             NOT NULL COMMENT 'Detailed complaint description',
    `priority`                ENUM('low','medium','high','urgent') NOT NULL DEFAULT 'medium' COMMENT 'Priority level; affects SLA deadline computation (BR-HST-020)',
    `status`                  ENUM('open','in_progress','resolved','escalated','closed') NOT NULL DEFAULT 'open' COMMENT 'Status FSM: open→in_progress→resolved/escalated→closed',
    `assigned_to`             INT UNSIGNED     NULL     COMMENT 'Staff assigned to resolve complaint (sys_users.id)',
    `resolution_notes`        TEXT             NULL     COMMENT 'Required when resolving; description of resolution action',
    `resolved_at`             TIMESTAMP        NULL     COMMENT 'Resolution timestamp',
    `sla_due_at`              TIMESTAMP        NULL     COMMENT 'SLA deadline computed by HstComplaintService::computeSlaDeadline() on creation; urgent/high=+48h, medium=+72h, low=+7d',
    `is_escalated`            TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = escalated by SendHstComplaintEscalationJob after SLA breach (BR-HST-020)',
    `escalated_at`            TIMESTAMP        NULL     COMMENT 'Escalation timestamp',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`              INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`              INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`              TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`              TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`              TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_cmp_hostel`   (`hostel_id`),
    KEY `idx_hst_cmp_room`     (`room_id`),
    KEY `idx_hst_cmp_student`  (`reported_by_student_id`),
    KEY `idx_hst_cmp_user`     (`reported_by_user_id`),
    KEY `idx_hst_cmp_assigned` (`assigned_to`),
    KEY `idx_hst_cmp_sla`      (`sla_due_at`),

    CONSTRAINT `fk_hst_cmp_hostel`   FOREIGN KEY (`hostel_id`)              REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_cmp_room`     FOREIGN KEY (`room_id`)                 REFERENCES `hst_rooms`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_student`  FOREIGN KEY (`reported_by_student_id`) REFERENCES `std_students` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_user`     FOREIGN KEY (`reported_by_user_id`)    REFERENCES `sys_users`    (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_cmp_assigned` FOREIGN KEY (`assigned_to`)            REFERENCES `sys_users`    (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Hostel-internal maintenance complaint register; SEPARATE from school-wide cmp_* module; SLA auto-escalation by hourly scheduler (BR-HST-020)';


CREATE TABLE IF NOT EXISTS `hst_sick_bay_log` (
    `id`                   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `hostel_id`            BIGINT UNSIGNED  NOT NULL COMMENT 'Hostel sick bay (hst_hostels.id); capacity checked against hst_hostels.sick_bay_capacity',
    `student_id`           INT UNSIGNED     NOT NULL COMMENT 'Admitted student (std_students.id)',
    `admission_datetime`   DATETIME         NOT NULL COMMENT 'Admission date and time',
    `discharge_datetime`   DATETIME         NULL     COMMENT 'Discharge date and time; NULL = currently in sick bay',
    `presenting_symptoms`  TEXT             NOT NULL COMMENT 'Symptoms reported on admission',
    `initial_diagnosis`    VARCHAR(500)     NULL     COMMENT 'Initial assessment by attending staff',
    `treatment_notes`      TEXT             NULL     COMMENT 'Treatment administered and medication given',
    `attending_staff_id`   INT UNSIGNED     NULL     COMMENT 'Nurse or warden attending (sys_users.id)',
    `discharge_notes`      TEXT             NULL     COMMENT 'Discharge instructions and follow-up',
    `is_hospital_referred` TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = student referred to hospital; links to HPC module via hpc_record_id',
    `hpc_record_id`        BIGINT UNSIGNED  NULL     COMMENT 'Soft reference to HPC module record ID (NO FK CONSTRAINT); set when is_hospital_referred=1; HPC module reads this column for linking',
    `parent_notified`      TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = SickBayAdmissionRecorded event dispatched to parent',
    `is_active`            TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`           INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`           TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`           TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`           TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_sb_hostel_admission` (`hostel_id`, `admission_datetime`),
    KEY `idx_hst_sb_student`          (`student_id`),
    KEY `idx_hst_sb_discharge`        (`discharge_datetime`),
    KEY `idx_hst_sb_staff`            (`attending_staff_id`),

    CONSTRAINT `fk_hst_sb_hostel`  FOREIGN KEY (`hostel_id`)         REFERENCES `hst_hostels`  (`id`),
    CONSTRAINT `fk_hst_sb_student` FOREIGN KEY (`student_id`)        REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_hst_sb_staff`   FOREIGN KEY (`attending_staff_id`) REFERENCES `sys_users`   (`id`) ON DELETE SET NULL
    -- hpc_record_id has NO FK CONSTRAINT — soft reference to HPC module; never enforced at DB level

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sick bay admission/discharge log; INDEX(discharge_datetime) for current inpatient query WHERE discharge_datetime IS NULL; hpc_record_id is a soft FK with no DB constraint';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 7 — Depends on Layer 5 (allotments) + Layer 6 (attendance, incidents)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_attendance_entries` (
    `id`             BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `attendance_id`  BIGINT UNSIGNED  NOT NULL COMMENT 'Parent attendance session (hst_attendance.id); CASCADE DELETE — entry deleted when session deleted',
    `student_id`     INT UNSIGNED     NOT NULL COMMENT 'Student (std_students.id)',
    `status`         ENUM('present','absent','leave','home','late','sick_bay') NOT NULL COMMENT 'Attendance status: present=attended roll call, absent=missing without leave, leave=on approved leave pass (auto-set by LeavePassService), home=weekend home leave, late=attended but after shift time, sick_bay=admitted to sick bay (BR-HST-016)',
    `late_remarks`   VARCHAR(255)     NULL     COMMENT 'Remarks for late or absent entries',
    `check_in_time`  TIME             NULL     COMMENT 'Actual check-in time for late arrivals',
    `is_active`      TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`     INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`     INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`     TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`     TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`     TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_hst_att_entry` (`attendance_id`, `student_id`),
    KEY `idx_hst_ae_attendance` (`attendance_id`),
    KEY `idx_hst_ae_student`    (`student_id`),

    CONSTRAINT `fk_hst_ae_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `hst_attendance` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_ae_student`    FOREIGN KEY (`student_id`)    REFERENCES `std_students`   (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-student attendance row within a session; CASCADE DELETE from hst_attendance; sick_bay status set by SickBayService (BR-HST-016); leave status set by LeavePassService (BR-HST-005)';


CREATE TABLE IF NOT EXISTS `hst_room_change_requests` (
    `id`                BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `student_id`        INT UNSIGNED     NOT NULL COMMENT 'Requesting student (std_students.id)',
    `from_allotment_id` BIGINT UNSIGNED  NOT NULL COMMENT 'Current active allotment (hst_allotments.id)',
    `requested_room_id` BIGINT UNSIGNED  NULL     COMMENT 'Preferred target room (hst_rooms.id); nullable — warden selects bed on approval',
    `reason`            TEXT             NOT NULL COMMENT 'Reason for room change request',
    `status`            ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending' COMMENT 'Request status FSM',
    `approved_by`       INT UNSIGNED     NULL     COMMENT 'Warden who approved/rejected (sys_users.id)',
    `approved_at`       TIMESTAMP        NULL     COMMENT 'Approval/rejection timestamp',
    `rejection_reason`  TEXT             NULL     COMMENT 'Required when status=rejected',
    `new_allotment_id`  BIGINT UNSIGNED  NULL     COMMENT 'New allotment created by AllotmentService::transfer() on approval (hst_allotments.id)',
    `is_active`         TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`        INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`        INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`        TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`        TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`        TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_rcr_student`      (`student_id`),
    KEY `idx_hst_rcr_from_allot`   (`from_allotment_id`),
    KEY `idx_hst_rcr_room`         (`requested_room_id`),
    KEY `idx_hst_rcr_approved_by`  (`approved_by`),
    KEY `idx_hst_rcr_new_allot`    (`new_allotment_id`),

    CONSTRAINT `fk_hst_rcr_student`     FOREIGN KEY (`student_id`)        REFERENCES `std_students`  (`id`),
    CONSTRAINT `fk_hst_rcr_from_allot`  FOREIGN KEY (`from_allotment_id`) REFERENCES `hst_allotments`(`id`),
    CONSTRAINT `fk_hst_rcr_room`        FOREIGN KEY (`requested_room_id`) REFERENCES `hst_rooms`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rcr_approved_by` FOREIGN KEY (`approved_by`)       REFERENCES `sys_users`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_rcr_new_allot`   FOREIGN KEY (`new_allotment_id`)  REFERENCES `hst_allotments`(`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Room change/transfer request workflow; on approval calls AllotmentService::transfer() which vacates old bed and creates new allotment';


CREATE TABLE IF NOT EXISTS `hst_leave_passes` (
    `id`                      BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `student_id`              INT UNSIGNED     NOT NULL COMMENT 'Student applying for leave (std_students.id)',
    `allotment_id`            BIGINT UNSIGNED  NOT NULL COMMENT 'Active allotment at time of application (hst_allotments.id)',
    `leave_type`              ENUM('home','emergency','medical','festival','vacation','other') NOT NULL COMMENT 'Leave category',
    `from_date`               DATE             NOT NULL COMMENT 'Leave start date',
    `to_date`                 DATE             NOT NULL COMMENT 'Leave end date; >= from_date (FormRequest validated — BR-HST-004)',
    `destination`             VARCHAR(255)     NOT NULL COMMENT 'Destination during leave',
    `purpose`                 VARCHAR(500)     NOT NULL COMMENT 'Purpose of leave',
    `guardian_contact`        VARCHAR(20)      NULL     COMMENT 'Guardian contact during leave period',
    `applied_by`              INT UNSIGNED     NOT NULL COMMENT 'Staff who created the application (sys_users.id)',
    `approved_by`             INT UNSIGNED     NULL     COMMENT 'Warden who approved or rejected (sys_users.id)',
    `approved_at`             TIMESTAMP        NULL     COMMENT 'Approval or rejection timestamp',
    `status`                  ENUM('pending','approved','rejected','returned','cancelled') NOT NULL DEFAULT 'pending' COMMENT 'Leave pass FSM: pending→approved/rejected; approved→returned/cancelled',
    `rejection_reason`        TEXT             NULL     COMMENT 'Required when status=rejected',
    `actual_return_date`      DATE             NULL     COMMENT 'Actual return date filled by warden on markReturned(); if > to_date → auto-incident (BR-HST-012)',
    `late_return_incident_id` BIGINT UNSIGNED  NULL     COMMENT 'Auto-created incident ID when actual_return_date > to_date (hst_incidents.id); set by LeavePassService::markReturned() (BR-HST-012)',
    `parent_notified`         TINYINT(1)       NOT NULL DEFAULT 0 COMMENT '1 = LeavePassApproved event dispatched to parent',
    `is_active`               TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`              INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`              INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`              TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`              TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`              TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_lp_student`   (`student_id`),
    KEY `idx_hst_lp_allotment` (`allotment_id`),
    KEY `idx_hst_lp_applied_by`  (`applied_by`),
    KEY `idx_hst_lp_approved_by` (`approved_by`),
    KEY `idx_hst_lp_incident`  (`late_return_incident_id`),

    CONSTRAINT `fk_hst_lp_student`   FOREIGN KEY (`student_id`)              REFERENCES `std_students`  (`id`),
    CONSTRAINT `fk_hst_lp_allotment` FOREIGN KEY (`allotment_id`)            REFERENCES `hst_allotments`(`id`),
    CONSTRAINT `fk_hst_lp_applied`   FOREIGN KEY (`applied_by`)              REFERENCES `sys_users`     (`id`),
    CONSTRAINT `fk_hst_lp_approved`  FOREIGN KEY (`approved_by`)             REFERENCES `sys_users`     (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_hst_lp_incident`  FOREIGN KEY (`late_return_incident_id`) REFERENCES `hst_incidents` (`id`) ON DELETE SET NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Leave pass FSM; approval runs inside DB::transaction() covering pass update + all attendance entries + all mess attendance (BR-HST-005/006); late return auto-creates incident (BR-HST-012)';

-- ─────────────────────────────────────────────────────────────────────────────
-- LAYER 8 — Depends on Layer 6 (hst_incidents) + sys_media
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `hst_incident_media` (
    `id`          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    `incident_id` BIGINT UNSIGNED  NOT NULL COMMENT 'Parent incident (hst_incidents.id); CASCADE DELETE',
    `media_id`    INT UNSIGNED     NOT NULL COMMENT 'Attached file (sys_media.id); INT UNSIGNED — matches sys_media.id which is INT UNSIGNED (NOT BIGINT)',
    `media_type`  VARCHAR(50)      NULL     COMMENT 'Media classification: photo / document / witness_statement',
    `is_active`   TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
    `created_by`  INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of creator',
    `updated_by`  INT UNSIGNED     NOT NULL COMMENT 'sys_users.id of last updater',
    `created_at`  TIMESTAMP        NULL     COMMENT 'Record creation timestamp',
    `updated_at`  TIMESTAMP        NULL     COMMENT 'Last update timestamp',
    `deleted_at`  TIMESTAMP        NULL     COMMENT 'Soft delete timestamp',

    PRIMARY KEY (`id`),
    KEY `idx_hst_im_incident` (`incident_id`),
    KEY `idx_hst_im_media`    (`media_id`),

    CONSTRAINT `fk_hst_im_incident` FOREIGN KEY (`incident_id`) REFERENCES `hst_incidents` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hst_im_media`    FOREIGN KEY (`media_id`)    REFERENCES `sys_media`      (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Incident photo/document attachments; media_id is INT UNSIGNED to match sys_media.id; CASCADE DELETE from hst_incidents';

-- =============================================================================
-- END OF HST DDL — 21 tables created
-- =============================================================================
