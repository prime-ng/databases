-- =====================================================================
-- PTM (PARENT-TEACHER MEETING) MODULE — VERSION 2.0 (PRODUCTION-GRADE)
-- Enhanced from Ptm_Setup_ddl_v1.sql
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant (runs inside tenant_db)
-- TABLE PREFIX: ptm_  (Parent-Teacher Meeting sub-module of School Setup)
-- =====================================================================

-- ---------------------------------------------------------------------
-- FK DEPENDENCIES (must already exist in tenant_db):
--   - sch_classes              (id)
--   - sch_sections             (id)
--   - sch_class_section_jnt    (id)
--   - sch_rooms                (id)              -- physical room (optional)
--   - sys_users                (id)              -- teachers / creators
--   - std_students             (id)              -- booking student
-- ---------------------------------------------------------------------

-- =========================================================================
-- SECTION: PTM SETUP & CONFIGURATION
-- =========================================================================

-- ---------------------------------------------------------------------------
-- The top-level PTM event (e.g. "Term 1 Parent-Teacher Meet 2025-26").
-- One school can run several events per academic year. Everything else
-- (assignments, batches, slots, bookings) is scoped under an event.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_events` (
  `id`                  int unsigned NOT NULL AUTO_INCREMENT,
  `code`                varchar(20)  NOT NULL,           -- e.g. 'PTM-T1-2526' (unique short code, used in URLs / reports)
  `title`               varchar(255) NOT NULL,           -- e.g. 'Term 1 Parent-Teacher Meet 2025-26'
  `academic_session_id` INT  NOT NULL,                   -- FK to sch_org_academic_sessions_jnt.id, e.g. '2025-2026'
  `academic_term`       SMALLINT  DEFAULT NULL,          -- FK to sch_academic_terms.id, e.g. 'Term 1', 'Mid-Term', 'Annual'
  `description`         text         DEFAULT NULL,       -- free-form notes shown to staff & parents
  `event_start_date`    date         NOT NULL,           -- first day on which any class will hold its PTM (e.g. 2026-05-10)
  `event_end_date`      date         NOT NULL,           -- last day on which any class will hold its PTM (e.g. 2026-05-15)
  `default_meeting_mode` ENUM('IN_PERSON', 'ONLINE', 'HYBRID') DEFAULT 'IN_PERSON', -- How Parent can join the PTM by default, can be overridden at class+section level (Req §3 — Meeting Mode)
  -- Settings that apply to ALL classes+sections in the event, unless overridden at the assignment level:
  `booking_window_start`        datetime     NOT NULL,        -- when parents can START booking (e.g. 2026-05-01 09:00:00)
  `booking_window_end`          datetime     NOT NULL,        -- when parents can NO LONGER book (e.g. 2026-05-09 23:59:59)
  `cancellation_lead_time_hrs`  smallint unsigned NOT NULL DEFAULT 24, -- min hrs before slot_start that a booking can still be cancelled (e.g. 24)
  `allow_reschedule`            tinyint(1)   NOT NULL DEFAULT 1,        -- if 0, parent can only cancel — not move to another slot
  `default_slot_duration_min`   tinyint unsigned NOT NULL DEFAULT 10,   -- fallback duration if a batch does not override (Req §3 — Dynamic Duration)
  `default_buffer_min`          tinyint unsigned NOT NULL DEFAULT 0,    -- school-wide default buffer between slots (Req §3 — Buffer Times)
  `default_max_participants`    tinyint unsigned NOT NULL DEFAULT 1,    -- 1 = 1-on-1, >1 = group slot
  `notify_parent_on_book`       tinyint(1)   NOT NULL DEFAULT 1,        -- send confirmation Notification/mail/SMS on booking
  `notify_parent_on_cancel`     tinyint(1)   NOT NULL DEFAULT 1,        -- send Notification on cancellation
  `is_active`           tinyint(1)   NOT NULL DEFAULT 1, -- master switch — turning OFF hides the event from parents
  `created_by`          int unsigned DEFAULT NULL,       -- FK sys_users.id — staff who created the event
  `created_at`          timestamp    NULL DEFAULT NULL,
  `updated_at`          timestamp    NULL DEFAULT NULL,
  `deleted_at`          timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmEvents_code` (`code`),
  KEY `idx_ptmEvents_academicSession` (`academic_session_id`),
  KEY `idx_ptmEvents_dates` (`event_start_date`, `event_end_date`),
  CONSTRAINT `fk_ptmEvents_academicSession` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
  CONSTRAINT `fk_ptmEvents_academicTerm` FOREIGN KEY (`academic_term`) REFERENCES `sch_academic_terms` (`id`),
  CONSTRAINT `fk_ptmEvents_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample row:
--   (1,'PTM-T1-2526','Term 1 Parent-Teacher Meet 2025-26','2025-2026','Term 1',
--    'Term 1 progress review for grades 1-12','2026-05-10','2026-05-15','IN_PERSON',1, ...)


-- ---------------------------------------------------------------------------
-- Which (class+section) participate in a given event, and on what date(s).
-- A class+section can have ONE date per event by default; if a class needs to
-- be split across two days, create two rows (most schools won't need this —
-- the unique key below blocks it; remove the UNIQUE if you allow it).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_event_class_section_jnt` (
  `id`                   int unsigned NOT NULL AUTO_INCREMENT,
  `ptm_event_id`         int unsigned NOT NULL,             -- FK ptm_events.id
  `class_section_id`     int unsigned NOT NULL,             -- FK sch_class_section_jnt.id (e.g. 10-A)
  `scheduled_date`       date         NOT NULL,             -- the day THIS class+section meets parents (e.g. 2026-05-10)
  `day_start_time`       time         NOT NULL,             -- earliest slot may start (e.g. '09:00:00')
  `day_end_time`         time         NOT NULL,             -- last slot must finish by (e.g. '13:00:00')
  `meeting_mode`         ENUM('IN_PERSON', 'ONLINE', 'HYBRID') DEFAULT 'IN_PERSON',  -- 'IN_PERSON' | 'ONLINE' | 'HYBRID', inherits ptm_events.default_meeting_mode, overrides event default
  `room_id`              int unsigned DEFAULT NULL,         -- FK sch_rooms.id — physical room (NULL when virtual)
  `virtual_link`         varchar(500) DEFAULT NULL,         -- Zoom / Teams / Meet URL (NULL when in-person)
  `notes`                text         DEFAULT NULL,         -- e.g. 'Use main hall, 2 entry points'
  `is_active`            tinyint(1)   NOT NULL DEFAULT 1,
  `created_by`           int unsigned DEFAULT NULL,
  `created_at`           timestamp    NULL DEFAULT NULL,
  `updated_at`           timestamp    NULL DEFAULT NULL,
  `deleted_at`           timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmEventCS_event_classSec` (`ptm_event_id`,`class_section_id`),
  KEY `idx_ptmEventCS_date` (`scheduled_date`),
  CONSTRAINT `fk_ptmEventCS_eventId`     FOREIGN KEY (`ptm_event_id`)     REFERENCES `ptm_events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmEventCS_classSecId`  FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`),
  CONSTRAINT `fk_ptmEventCS_roomId`      FOREIGN KEY (`room_id`)          REFERENCES `sch_rooms` (`id`),
  CONSTRAINT `fk_ptmEventCS_createdBy`   FOREIGN KEY (`created_by`)       REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows (event 1 = Term 1 PTM):
--   (1, 1, 12 /*10-A*/, '2026-05-10', '09:00','13:00','IN_PERSON',  5, NULL, ...)
--   (2, 1, 13 /*10-B*/, '2026-05-11', '09:00','13:00','IN_PERSON',  5, NULL, ...)
--   (3, 1,  7 /* 5-A*/, '2026-05-12', '14:00','17:00','ZOOM',     NULL,'https://zoom.us/j/123', ...)


-- ---------------------------------------------------------------------------
-- Reusable BATCH TEMPLATE created by a teacher (or admin on behalf of a
-- teacher). Defines the SHAPE — total window, slot duration, capacity, buffer.
-- The *time-grid* of the batch is stored in ptm_batch_slot_template.
-- A single batch template can be applied to many class+sections (Req §3 —
-- Template Reusability).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_batches_template` (
  `id`                       int unsigned NOT NULL AUTO_INCREMENT,
  `code`                     varchar(30)  NOT NULL,         -- e.g. 'BATCH_2H_12STU' (unique short code)
  `name`                     varchar(100) NOT NULL,         -- e.g. 'Morning 9-11 AM, 12 students × 10 min'
      `owner_teacher_id`         int unsigned NOT NULL,         -- FK sys_users.id — staff who owns the template
  `window_start_time`        time         NOT NULL,         -- e.g. '09:00:00' — wall-clock start of the batch on any given day
  `window_end_time`          time         NOT NULL,         -- e.g. '11:00:00' — wall-clock end
  `slot_duration_min`        tinyint unsigned NOT NULL,     -- per-meeting duration in minutes (e.g. 10, 15)
  `buffer_min`               tinyint unsigned NOT NULL DEFAULT 0, -- gap between consecutive slots (e.g. 2)
  `max_participants_per_slot` tinyint unsigned NOT NULL DEFAULT 1, -- 1 = 1-on-1, >1 = group slot (Req §3 — Slot Capacity)
  `expected_total_slots`     tinyint unsigned DEFAULT NULL, -- denormalized count of generated bookable slots — useful for quick UI display
  `description`              text         DEFAULT NULL,     -- e.g. 'Standard secondary template — 10-min meetings'
  `is_active`                tinyint(1)   NOT NULL DEFAULT 1,
  `created_by`               int unsigned DEFAULT NULL,
  `created_at`               timestamp    NULL DEFAULT NULL,
  `updated_at`               timestamp    NULL DEFAULT NULL,
  `deleted_at`               timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmBatches_code` (`code`),
  KEY `idx_ptmBatches_ownerTeacher` (`owner_teacher_id`),
  CONSTRAINT `fk_ptmBatches_ownerTeacherId` FOREIGN KEY (`owner_teacher_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmBatches_createdBy`      FOREIGN KEY (`created_by`)       REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows:
--   (1, 'BATCH_2H_12STU', 'Morning 9-11 AM, 12 students × 10 min', 45 /*Mrs. Sharma*/,
--    '09:00:00','11:00:00', 10, 0, 1, 12, 'Std secondary 10-min', ...)
--   (2, 'BATCH_PRIM_15M', 'Primary 15-min slots',                  72,
--    '09:00:00','12:00:00', 15, 0, 1, 12, 'Primary grades — 15 min meetings', ...)


-- ---------------------------------------------------------------------------
-- The fixed time-grid of a batch (relative offsets within the batch window).
-- Most rows are bookable meeting slots; rows with `is_break = 1` represent
-- mandatory breaks (Req §3 — Mandatory Breaks) and are NEVER bookable.
-- These rows are usually generated programmatically from window_start +
-- duration + buffer, but storing them explicitly lets a teacher
-- hand-customise (e.g. add a break in the middle).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_batch_slot_template` (
  `id`                int unsigned NOT NULL AUTO_INCREMENT,
  `batch_template_id` int unsigned NOT NULL,            -- FK ptm_batches_template.id
  `ordinal`           tinyint unsigned NOT NULL,        -- 1,2,3… display + generation order
  `slot_start_time`   time         NOT NULL,            -- relative wall-clock start (e.g. '09:00:00')
  `slot_end_time`     time         NOT NULL,            -- relative wall-clock end   (e.g. '09:10:00')
  `is_break`          tinyint(1)   NOT NULL DEFAULT 0,  -- 1 = unbookable break/buffer marker
  `break_label`       varchar(50)  DEFAULT NULL,        -- e.g. 'Tea break', 'Staff meeting' (only when is_break=1)
  `is_active`         tinyint(1)   NOT NULL DEFAULT 1,
  `created_at`        timestamp    NULL DEFAULT NULL,
  `updated_at`        timestamp    NULL DEFAULT NULL,
  `deleted_at`        timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmBatchSlotDef_batch_template_ordinal` (`batch_template_id`,`ordinal`),
  UNIQUE KEY `uq_ptmBatchSlotDef_batch_template_startTime` (`batch_template_id`,`slot_start_time`),
  CONSTRAINT `fk_ptmBatchSlotDef_batchTemplateId` FOREIGN KEY (`batch_template_id`) REFERENCES `ptm_batches_template` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows for batch_template_id=1 (12 × 10-min slots, 9-11 AM):
--   (1, 1, 1, '09:00:00','09:10:00', 0, NULL, ...)
--   (2, 1, 2, '09:10:00','09:20:00', 0, NULL, ...)
--   ...
--   (12,1,12, '10:50:00','11:00:00', 0, NULL, ...)
-- Sample with break:
--   (5, 1, 5, '09:40:00','09:50:00', 1, 'Tea break', ...)

-- =========================================================================
-- SECTION: PTM ASSIGNMENTS & SLOT GENERATION
-- =========================================================================

-- ---------------------------------------------------------------------------
-- Applies a BATCH to a specific (event, class+section). The *concrete*
-- bookable slots in ptm_slots are generated from this row.
-- One class+section can have multiple assignments only when it is split into
-- sub-batches with different teachers (see ptm_assignment_teacher_jnt). For
-- the simple case (1 teacher per class+section), there is exactly 1 row here
-- per (event, class+section).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_assignments` (
  `id`                          int unsigned NOT NULL AUTO_INCREMENT,
  `ptm_event_id`                int unsigned NOT NULL,             -- FK ptm_events.id
  `event_class_section_id`      int unsigned NOT NULL,             -- FK ptm_event_class_section_jnt.id (gives event+class+section+date+room)
  `batch_template_id`           int unsigned NOT NULL,             -- FK ptm_batches_template.id (the template applied)
  `primary_teacher_id`          int unsigned NOT NULL,             -- FK sys_users.id — default = class teacher; admin may override
  `allocation_mode`             ENUM('SCHOOL_ALLOCATED', 'PARENT_PICK') NOT NULL DEFAULT 'SCHOOL_ALLOCATED', -- 'SCHOOL_ALLOCATED' | 'PARENT_PICK' (Req §2)
  `override_buffer_min`         tinyint unsigned DEFAULT NULL,     -- if set, overrides ptm_batches_template.buffer_min for THIS assignment
  `override_max_participants`   tinyint unsigned DEFAULT NULL,     -- if set, overrides ptm_batches_template.max_participants_per_slot
  `is_published`                tinyint(1)   NOT NULL DEFAULT 0,   -- 0 = draft (slots hidden from parents); 1 = visible / bookable
  `published_at`                timestamp    NULL DEFAULT NULL,    -- timestamp at which is_published flipped 0→1
  `notes`                       text         DEFAULT NULL,         -- internal notes for staff
  `is_active`                   tinyint(1)   NOT NULL DEFAULT 1,
  `created_by`                  int unsigned DEFAULT NULL,
  `created_at`                  timestamp    NULL DEFAULT NULL,
  `updated_at`                  timestamp    NULL DEFAULT NULL,
  `deleted_at`                  timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmAssign_evCS_teacher` (`event_class_section_id`,`primary_teacher_id`), -- one row per (class+section, teacher) within event
  KEY `idx_ptmAssign_event` (`ptm_event_id`),
  KEY `idx_ptmAssign_batch_template` (`batch_template_id`),
  KEY `idx_ptmAssign_teacher` (`primary_teacher_id`),
  CONSTRAINT `fk_ptmAssign_eventId`     FOREIGN KEY (`ptm_event_id`)           REFERENCES `ptm_events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmAssign_eventCSId`   FOREIGN KEY (`event_class_section_id`) REFERENCES `ptm_event_class_section_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmAssign_batchTempId` FOREIGN KEY (`batch_template_id`)      REFERENCES `ptm_batches_template` (`id`),
  CONSTRAINT `fk_ptmAssign_teacherId`   FOREIGN KEY (`primary_teacher_id`)     REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmAssign_createdBy`   FOREIGN KEY (`created_by`)             REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows:
--   (1, 1, 1, 1, 45,'SCHOOL_ALLOCATED', NULL, NULL, 1,'2026-05-01 10:00:00', NULL, ...)  -- 10-A on 2026-05-10, school auto-allocates
--   (2, 1, 2, 1, 46,'PARENT_PICK',     NULL, NULL, 1,'2026-05-01 10:05:00', NULL, ...)  -- 10-B on 2026-05-11, parents pick
-- Conditions:
--   * Only the primary_teacher OR a user with `ptm.assignment.manage` permission
--     may modify slots/bookings under this assignment (Req §3 — Ownership).
--   * If override_* is NULL, application falls back to the parent ptm_batches_template values.


-- ---------------------------------------------------------------------------
-- Multi-teacher support: when a class+section is split into parallel sub-
-- batches running at the same time, each sub-batch has its own teacher
-- (Req §3 — Multi-Teacher Assignment). For the simple 1-teacher case, this
-- table can be skipped (slots use ptm_assignments.primary_teacher_id).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_assignment_teacher_jnt` (
  `id`                int unsigned NOT NULL AUTO_INCREMENT,
  `assignment_id`     int unsigned NOT NULL,           -- FK ptm_assignments.id
  `teacher_id`        int unsigned NOT NULL,           -- FK sys_users.id
  `sub_batch_label`   varchar(50)  DEFAULT NULL,       -- e.g. 'Group 1 (Roll 1-15)', 'Group 2 (Roll 16-30)'
  `room_id`           int unsigned DEFAULT NULL,       -- FK sch_rooms.id — sub-batch can use a different room
  `virtual_link`      varchar(500) DEFAULT NULL,       -- sub-batch can use a different virtual link
      `student_filter_json` json       DEFAULT NULL,       -- e.g. {"roll_from":1,"roll_to":15} or {"student_ids":[12,15,17]}
  `is_active`         tinyint(1)   NOT NULL DEFAULT 1,
  `created_at`        timestamp    NULL DEFAULT NULL,
  `updated_at`        timestamp    NULL DEFAULT NULL,
  `deleted_at`        timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmAsgnTeacher_asgn_teacher` (`assignment_id`,`teacher_id`),
  CONSTRAINT `fk_ptmAsgnTeacher_asgnId`    FOREIGN KEY (`assignment_id`) REFERENCES `ptm_assignments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmAsgnTeacher_teacherId` FOREIGN KEY (`teacher_id`)    REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmAsgnTeacher_roomId`    FOREIGN KEY (`room_id`)       REFERENCES `sch_rooms` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows (assignment 1 = 10-A split into two parallel groups):
--   (1, 1, 45, 'Group 1 (Roll 1-15)',  5, NULL, '{"roll_from":1,"roll_to":15}', ...)
--   (2, 1, 78, 'Group 2 (Roll 16-30)', 6, NULL, '{"roll_from":16,"roll_to":30}', ...)


-- ---------------------------------------------------------------------------
-- A teacher's GLOBAL unavailability window inside the PTM event (lunch, staff
-- meeting, personal). Slot generation MUST skip these intervals; booking MUST
-- reject any attempt that overlaps. This is the cross-class teacher
-- availability constraint (Req §3 — No Double-Booking, Mandatory Breaks).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_blockouts` (
  `id`            int unsigned NOT NULL AUTO_INCREMENT,
  `ptm_event_id`  int unsigned NOT NULL,                  -- FK ptm_events.id (scoped to one event)
  `teacher_id`    int unsigned NULL,                  -- FK sys_users.id (If NULL, applies to all teachers — e.g. power outage; if set, applies only to the specified teacher — e.g. lunch)
  `blockout_date` date         NOT NULL,                  -- e.g. 2026-05-10
  `start_time`    time         NOT NULL,                  -- e.g. '12:00:00'
  `end_time`      time         NOT NULL,                  -- e.g. '13:00:00'
  `reason`        varchar(100) NOT NULL,                  -- e.g. 'Lunch', 'Staff meeting'
  `is_active`     tinyint(1)   NOT NULL DEFAULT 1,
  `created_by`    int unsigned DEFAULT NULL,
  `created_at`    timestamp    NULL DEFAULT NULL,
  `updated_at`    timestamp    NULL DEFAULT NULL,
  `deleted_at`    timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ptmBlockouts_event_teacher_date` (`ptm_event_id`,`teacher_id`,`blockout_date`),
  CONSTRAINT `fk_ptmBlockouts_eventId`   FOREIGN KEY (`ptm_event_id`) REFERENCES `ptm_events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmBlockouts_teacherId` FOREIGN KEY (`teacher_id`)   REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmBlockouts_createdBy` FOREIGN KEY (`created_by`)   REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows:
--   (1, 1, 45, '2026-05-10', '12:00:00','13:00:00', 'Lunch', ...)
--   (2, 1, 45, '2026-05-10', '14:30:00','15:00:00', 'Staff meeting', ...)


-- ---------------------------------------------------------------------------
-- The CONCRETE bookable slot — wall-clock date + time, generated from
-- (assignment + batch_slot_definition + teacher). One row per actual
-- meeting opportunity. For 1-on-1 mode capacity = 1; for "Group Slot"
-- capacity > 1.
-- The teacher field is denormalized here so the application can quickly
-- enforce "no double-booking across all classes" without joining back to
-- ptm_assignments / ptm_assignment_teacher_jnt.
v
CREATE TABLE IF NOT EXISTS `ptm_slots` (
  `id`                  int unsigned NOT NULL AUTO_INCREMENT,
  `assignment_id`       int unsigned NOT NULL,                  -- FK ptm_assignments.id
  `assignment_teacher_id` int unsigned DEFAULT NULL,            -- FK ptm_assignment_teacher_jnt.id (NULL when single-teacher assignment)
  `batch_slot_template_id` int unsigned DEFAULT NULL,           -- FK ptm_batch_slot_template.id (the template row this came from; NULL if hand-created)
  `teacher_id`          int unsigned NOT NULL,                  -- FK sys_users.id (denormalized for fast cross-class conflict checks)
  `slot_start`          datetime     NOT NULL,                  -- absolute wall-clock start, e.g. 2026-05-10 09:00:00
  `slot_end`            datetime     NOT NULL,                  -- absolute wall-clock end,   e.g. 2026-05-10 09:10:00
  `capacity`            tinyint unsigned NOT NULL DEFAULT 1,    -- 1 = 1-on-1, >1 = group slot
  `booked_count`        tinyint unsigned NOT NULL DEFAULT 0,    -- denormalized count of confirmed bookings (matches COUNT(*) in ptm_slot_bookings)
  `status`              ENUM('AVAILABLE', 'BOOKED', 'FULL', 'BLOCKED', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'AVAILABLE', -- 'AVAILABLE' = open for booking, 'BOOKED' = at least 1 booking but not full, 'FULL' = booked_count=capacity, 'BLOCKED' = cannot be booked (e.g. overlaps a ptm_blockouts or is_break), 'COMPLETED' = meeting happened, 'CANCELLED' = slot cancelled by admin/teacher
  `is_break`            tinyint(1)   NOT NULL DEFAULT 0,        -- mirrors batch_slot_def.is_break (carried for fast filtering)
  `room_id`             int unsigned DEFAULT NULL,              -- FK sch_rooms.id — usually inherits from event_class_section / sub-batch
  `virtual_link`        varchar(500) DEFAULT NULL,              -- per-slot virtual link override (rarely used)
  `is_active`           tinyint(1)   NOT NULL DEFAULT 1,
  `created_at`          timestamp    NULL DEFAULT NULL,
  `updated_at`          timestamp    NULL DEFAULT NULL,
  `deleted_at`          timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ptmSlots_teacher_start` (`teacher_id`,`slot_start`),    -- enforces "no double-booking" across all assignments (Req §3)
  KEY `idx_ptmSlots_assignment` (`assignment_id`),
  KEY `idx_ptmSlots_status` (`status`),
  KEY `idx_ptmSlots_slotStart` (`slot_start`),
  CONSTRAINT `fk_ptmSlots_assignmentId`        FOREIGN KEY (`assignment_id`)         REFERENCES `ptm_assignments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmSlots_assignmentTeacherId` FOREIGN KEY (`assignment_teacher_id`) REFERENCES `ptm_assignment_teacher_jnt` (`id`),
  CONSTRAINT `fk_ptmSlots_batchSlotDefId`      FOREIGN KEY (`batch_slot_def_id`)     REFERENCES `ptm_batch_slot_template` (`id`),
  CONSTRAINT `fk_ptmSlots_teacherId`           FOREIGN KEY (`teacher_id`)            REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmSlots_roomId`              FOREIGN KEY (`room_id`)               REFERENCES `sch_rooms` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows (assignment 1, teacher 45, 2026-05-10):
--   (1, 1, NULL, 1, 45, '2026-05-10 09:00:00','2026-05-10 09:10:00', 1, 0, 'AVAILABLE', 0, 5, NULL, ...)
--   (2, 1, NULL, 2, 45, '2026-05-10 09:10:00','2026-05-10 09:20:00', 1, 1, 'BOOKED',    0, 5, NULL, ...)
--   (5, 1, NULL, 5, 45, '2026-05-10 09:40:00','2026-05-10 09:50:00', 0, 0, 'BLOCKED',   1, 5, NULL, ...)  -- tea break
-- Conditions:
--   * status BLOCKED is set when the slot overlaps a ptm_blockouts row OR has is_break=1.
--   * status FULL is set when booked_count = capacity.
--   * The UNIQUE (teacher_id, slot_start) enforces No-Double-Booking at DB level.
--     Application must also verify slot_end of the previous slot does not overlap.


-- ---------------------------------------------------------------------------
-- The actual booking by a student/parent. Separated from ptm_slots so that:
--   - 1-on-1 slots have exactly 1 booking,
--   - "Group Slots" can hold up to capacity bookings,
--   - cancellation history is preserved (status change, not row delete).
-- The unique key enforces "one booking per student per teacher per event"
-- (Req §2 — Limit per Student) without forbidding the student to also book
-- a different teacher in the same event.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ptm_slot_bookings` (
  `id`                int unsigned NOT NULL AUTO_INCREMENT,
  `slot_id`           int unsigned NOT NULL,                       -- FK ptm_slots.id
  `ptm_event_id`      int unsigned NOT NULL,                       -- FK ptm_events.id (denormalized — used in the unique key below)
  `teacher_id`        int unsigned NOT NULL,                       -- FK sys_users.id  (denormalized — used in the unique key below)
  `student_id`        int unsigned NOT NULL,                       -- FK std_students.id
  `booked_by_user_id` int unsigned DEFAULT NULL,                   -- FK sys_users.id — parent / staff user who placed the booking
  `parent_comments`   text         DEFAULT NULL,                   -- "Want to discuss math performance"
  `status`            ENUM('CONFIRMED', 'CANCELLED', 'NO_SHOW', 'COMPLETED', 'RESCHEDULED') NOT NULL DEFAULT 'CONFIRMED',   -- CONFIRMED | CANCELLED | NO_SHOW | COMPLETED | RESCHEDULED
  `booked_at`         timestamp    NULL DEFAULT NULL,              -- when the booking was placed
  `cancelled_at`      timestamp    NULL DEFAULT NULL,              -- when it was cancelled (NULL while CONFIRMED)
  `cancel_reason`     varchar(255) DEFAULT NULL,                   -- e.g. 'Parent unavailable'
  `attended`          tinyint(1)   DEFAULT NULL,                   -- 1=attended, 0=no-show, NULL=meeting hasn't happened yet
  `meeting_notes`     text         DEFAULT NULL,                   -- post-meeting notes captured by teacher
  -- Generated column: only CONFIRMED rows participate in the unique key —
  -- this lets a student re-book after cancelling.
  `active_booking_key` int unsigned GENERATED ALWAYS AS (CASE WHEN `status` = 'CONFIRMED' THEN `student_id` ELSE NULL END) VIRTUAL,
  `is_active`         tinyint(1)   NOT NULL DEFAULT 1,
  `created_by`        int unsigned DEFAULT NULL,
  `created_at`        timestamp    NULL DEFAULT NULL,
  `updated_at`        timestamp    NULL DEFAULT NULL,
  `deleted_at`        timestamp    NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  -- One CONFIRMED booking per student per event (Req §2 — Limit per Student)
  UNIQUE KEY `uq_ptmBooking_event_teacher_studentActive` (`ptm_event_id`,`active_booking_key`),
  -- A student cannot occupy the same slot twice (paranoia constraint)
  UNIQUE KEY `uq_ptmBooking_slot_studentActive` (`slot_id`,`active_booking_key`),
  KEY `idx_ptmBooking_slot` (`slot_id`),
  KEY `idx_ptmBooking_student` (`student_id`),
  KEY `idx_ptmBooking_status` (`status`),
  CONSTRAINT `fk_ptmBooking_slotId`       FOREIGN KEY (`slot_id`)           REFERENCES `ptm_slots` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmBooking_eventId`      FOREIGN KEY (`ptm_event_id`)      REFERENCES `ptm_events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ptmBooking_teacherId`    FOREIGN KEY (`teacher_id`)        REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmBooking_studentId`    FOREIGN KEY (`student_id`)        REFERENCES `std_students` (`id`),
  CONSTRAINT `fk_ptmBooking_bookedBy`     FOREIGN KEY (`booked_by_user_id`) REFERENCES `sys_users` (`id`),
  CONSTRAINT `fk_ptmBooking_createdBy`    FOREIGN KEY (`created_by`)        REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Sample rows:
--   (1, 2, 1, 45, 312, 1100, 'Discuss math performance', 'CONFIRMED',
--    '2026-05-02 14:21:00', NULL, NULL, NULL, NULL, ...)
--   (2, 7, 1, 45, 318, 1107, 'Sport activity feedback',  'CANCELLED',
--    '2026-05-02 15:00:00', '2026-05-08 09:00:00', 'Parent travelling', NULL, NULL, ...)
--   (3, 7, 1, 45, 318, 1107, 'Re-booked',                'CONFIRMED',
--    '2026-05-08 10:00:00', NULL, NULL, NULL, NULL, ...)  -- allowed because (#2) is CANCELLED


-- =====================================================================
-- END OF PTM MODULE V2
-- =====================================================================
-- IMPLEMENTATION NOTES (application layer — NOT enforced by DDL alone):
-- A. SLOT GENERATION (when ptm_assignments.is_published flips to 1):
--    For each ptm_batch_slot_template row of the assignment's batch,
--    insert a ptm_slots row at scheduled_date + slot_start_time.
--    Mark `status='BLOCKED'` and `is_break=1` if the def is a break OR if
--    it overlaps any ptm_blockouts of primary_teacher_id.
-- B. BOOKING (PARENT_PICK mode):
--    1. Verify NOW between booking_window_start and booking_window_end.
--    2. Lock target ptm_slots row (SELECT … FOR UPDATE).
--    3. Reject if status != 'AVAILABLE' OR booked_count >= capacity.
--    4. INSERT ptm_slot_bookings (status='CONFIRMED').
--    5. UPDATE ptm_slots SET booked_count = booked_count + 1,
--       status = IF(booked_count+1 = capacity, 'FULL', 'BOOKED').
-- C. SCHOOL_ALLOCATED mode:
--    Bypass step 1. Admin or scheduler service inserts bookings directly,
--    typically one per student in the class+section's roster.
-- D. CANCELLATION:
--    1. Verify NOW + cancellation_lead_time_hrs <= slot_start.
--    2. UPDATE ptm_slot_bookings SET status='CANCELLED', cancelled_at=NOW().
--    3. UPDATE ptm_slots SET booked_count = booked_count - 1,
--       status = IF(booked_count-1 = 0, 'AVAILABLE', 'BOOKED').
-- E. CROSS-CLASS TEACHER CONFLICT:
--    The UNIQUE (teacher_id, slot_start) on ptm_slots stops two slots from
--    EXISTING at the same teacher+start. App should additionally check
--    [slot_start, slot_end) overlap with the teacher's other slots (e.g.
--    when slot durations differ across batches).
-- =====================================================================
