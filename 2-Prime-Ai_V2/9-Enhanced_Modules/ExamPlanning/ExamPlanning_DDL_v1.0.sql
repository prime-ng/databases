-- =====================================================================
-- EXAM PLANNING MODULE - VERSION 1.0 (PRODUCTION-GRADE DRAFT) on 03-Nov-2026
-- SUB-MODULES: DATE SHEET, SEATING PLAN, INVIGILATION, PRINTOUTS & NOTICES
-- Companion report: ExamPlanning_Plan_Report_v1.0.md (same folder)
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel | Engine: Python + OR-Tools CP-SAT
-- Architecture: Multi-tenant (tenant DB), rule-driven auto-planning
-- TABLE PREFIX: exp_
-- =====================================================================
-- Builds on (read-only, never altered by this module):
--   sch_classes, sch_sections, sch_class_section_jnt, sch_subjects,
--   sch_buildings, sch_rooms, sch_rooms_type, sch_holidays,
--   sch_employees, sch_teacher_profile, sch_teacher_capabilities,
--   sch_employee_leave_applications, sch_org_academic_sessions_jnt,
--   std_students, std_student_academic_sessions, std_student_opted_subjects,
--   lms_exam_types, lms_exams, lms_exam_papers (optional link / import source),
--   tt_timetable_cells + tt_timetable_cell_teachers (who teaches what), sys_users
--
-- Design rules used throughout:
--   * Code-owned state machines (plan status, run status, source) = ENUM.
--   * School-extendable lists (need types, rules, print templates) = lookup tables.
--   * Rules are DATA: exp_rule_definitions (catalogue) + exp_plan_rules (per-plan
--     instance with HARD/SOFT, weight, params JSON). A new rule = 1 catalogue row
--     + 1 Python handler; no DDL change.
--   * Engine OUTPUT tables carry `source` + `is_locked` + `generation_run_id`, so a
--     re-run replaces only unlocked ENGINE rows and keeps MANUAL / locked ones.
--   * Every `*_json` / `params` column is for forward-compatible settings.
--   * No CHECK constraint touches an FK column (MySQL errno 3823 trap).
--   * UNIQUE keys that include a NULLable column (scope_class_id, subject_id, plan_slot_id,
--     sitting_id) do NOT stop duplicate NULL rows in MySQL - the FormRequest enforces those.
-- =====================================================================


-- ===========================================================================
-- 1 - MASTERS (shared across all exam plans)
-- ===========================================================================

  -- Catalogue of every rule the Python engine understands. Seeded by the system (is_system=1).
  -- The engine looks up a handler by `code`; unknown codes are reported as warnings, never crash.
  CREATE TABLE IF NOT EXISTS `exp_rule_definitions` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`               VARCHAR(50)  NOT NULL,                  -- e.g. 'DS_NO_STUDENT_CLASH','ST_NO_ADJ_SIDE','IV_NOT_OWN_SUBJECT'
    `stage`              ENUM('DATESHEET','SEATING','INVIGILATION') NOT NULL,
    `name`               VARCHAR(150) NOT NULL,                  -- e.g. 'No two students of the same paper side by side'
    `description`        TEXT         DEFAULT NULL,              -- shown as help text on the Rules tab
    `default_strictness` ENUM('HARD','SOFT') NOT NULL DEFAULT 'SOFT',
    `default_weight`     SMALLINT UNSIGNED NOT NULL DEFAULT 10,  -- SOFT penalty weight (ignored when HARD)
    `allow_hard`         TINYINT(1)   NOT NULL DEFAULT 1,        -- 0 = rule can only ever be SOFT (e.g. fairness)
    `allow_soft`         TINYINT(1)   NOT NULL DEFAULT 1,        -- 0 = rule can only ever be HARD (e.g. capacity)
    `params_schema_json` JSON         DEFAULT NULL,              -- JSON-schema of params; drives the edit form, e.g. {"min_gap_days":{"type":"int","min":0,"max":5,"default":1}}
    `default_params_json` JSON        DEFAULT NULL,              -- e.g. {"min_gap_days":1}
    `relax_priority`     TINYINT UNSIGNED NOT NULL DEFAULT 50,   -- order in which HARD rules are suggested for relaxing when a run is infeasible (higher = relax first)
    `is_default_enabled` TINYINT(1)   NOT NULL DEFAULT 1,        -- copied into exp_plan_rules.is_enabled when a plan is created
    `engine_min_version` VARCHAR(20)  DEFAULT NULL,              -- engine version that first implements the rule
    `ordinal`            SMALLINT UNSIGNED NOT NULL DEFAULT 0,   -- display order inside its stage
    `is_system`          TINYINT(1)   NOT NULL DEFAULT 1,
    `is_active`          TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`         TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expRuleDef_code` (`code`),
    KEY `idx_expRuleDef_stage` (`stage`, `ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Special-needs categories (school can add more). Flags tell the engine how to seat them.
  CREATE TABLE IF NOT EXISTS `exp_need_types` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(30)  NOT NULL,               -- e.g. 'SCRIBE','READER','MEDICAL_ISOLATION','MOBILITY','EXTRA_TIME','LOW_VISION'
    `name`                  VARCHAR(100) NOT NULL,
    `needs_separate_room`   TINYINT(1)   NOT NULL DEFAULT 0,     -- seat only in a room flagged exp_room_layouts.is_special_room
    `needs_accessible_room` TINYINT(1)   NOT NULL DEFAULT 0,     -- seat only in a room flagged exp_room_layouts.is_accessible
    `needs_front_row`       TINYINT(1)   NOT NULL DEFAULT 0,     -- e.g. LOW_VISION / hearing impaired (SOFT preference)
    `default_extra_minutes` SMALLINT UNSIGNED NOT NULL DEFAULT 0,-- e.g. 20 (CBSE: 20 min per hour for eligible CWSN) - editable per student
    `needs_companion_seat`  TINYINT(1)   NOT NULL DEFAULT 0,     -- scribe/reader occupies the next seat
    `is_system`             TINYINT(1)   NOT NULL DEFAULT 0,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expNeedType_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Exam seating layout of a physical room. One row per sch_rooms room that can host exams.
  -- Seat address = (row_no, column_no, seat_pos). row 1 = front; column 1 = left as seen by the invigilator's desk.
  CREATE TABLE IF NOT EXISTS `exp_room_layouts` (
    `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_id`              INT UNSIGNED NOT NULL,                -- FK to sch_rooms.id (only rooms with can_host_exam = 1 are offered)
    `rows_count`           TINYINT UNSIGNED NOT NULL,            -- benches front-to-back, e.g. 6
    `columns_count`        TINYINT UNSIGNED NOT NULL,            -- bench columns left-to-right, e.g. 4
    `seats_per_bench`      TINYINT UNSIGNED NOT NULL DEFAULT 2,  -- 1 = single desks, 2 = dual desks, 3 = triple benches
    `gross_seats`          SMALLINT UNSIGNED GENERATED ALWAYS AS (`rows_count` * `columns_count` * `seats_per_bench`) STORED,
    `usable_seats`         SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- gross_seats minus blocked seats (maintained by app on every layout / block change)
    `aisle_after_columns`  VARCHAR(50)  DEFAULT NULL,            -- CSV of column numbers followed by an aisle, e.g. '2' -> aisle between col 2 and 3 (adjacency across an aisle is a rule param)
    `seat_label_format`    VARCHAR(50)  NOT NULL DEFAULT '{room}-R{row:02}-C{col}-{pos}', -- tokens: {room},{row},{col},{pos},{seq}; pos renders as L/M/R
    `floor_no`             TINYINT      DEFAULT NULL,            -- 0 = ground floor
    `is_accessible`        TINYINT(1)   NOT NULL DEFAULT 0,      -- step-free / ground floor: allowed for MOBILITY needs
    `is_special_room`      TINYINT(1)   NOT NULL DEFAULT 0,      -- usable for SCRIBE / READER / MEDICAL_ISOLATION students
    `default_invigilators` TINYINT UNSIGNED DEFAULT NULL,        -- NULL = use plan ratio rule; a value overrides the ratio for this room
    `display_order`        SMALLINT UNSIGNED NOT NULL DEFAULT 0, -- order rooms are opened / printed (also the engine's tie-break)
    `layout_meta_json`     JSON         DEFAULT NULL,            -- future: door position, CCTV, invigilator desk side, irregular grids
    `remarks`              VARCHAR(255) DEFAULT NULL,
    `is_active`            TINYINT(1)   NOT NULL DEFAULT 1,
    `created_by`           INT UNSIGNED DEFAULT NULL,            -- FK to sys_users.id
    `created_at`           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expRoomLayout_roomId` (`room_id`),
    CONSTRAINT `fk_expRoomLayout_roomId`    FOREIGN KEY (`room_id`)    REFERENCES `sch_rooms` (`id`),
    CONSTRAINT `fk_expRoomLayout_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Individual seats that must never be used (broken bench, pillar, near door ...).
  CREATE TABLE IF NOT EXISTS `exp_room_blocked_seats` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `room_layout_id` INT UNSIGNED NOT NULL,                      -- FK to exp_room_layouts.id
    `row_no`         TINYINT UNSIGNED NOT NULL,
    `column_no`      TINYINT UNSIGNED NOT NULL,
    `seat_pos`       TINYINT UNSIGNED NOT NULL DEFAULT 0,        -- 0 = whole bench blocked, 1..seats_per_bench = one seat
    `reason`         VARCHAR(150) DEFAULT NULL,
    `created_at`     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expBlockedSeat_seat` (`room_layout_id`, `row_no`, `column_no`, `seat_pos`),
    CONSTRAINT `fk_expBlockedSeat_layoutId` FOREIGN KEY (`room_layout_id`) REFERENCES `exp_room_layouts` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Reusable exam slot templates (copied into exp_plan_slots when a plan is created).
  CREATE TABLE IF NOT EXISTS `exp_slot_templates` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`       VARCHAR(20)  NOT NULL,                          -- e.g. 'MORNING','AFTERNOON','UT_SHORT'
    `name`       VARCHAR(50)  NOT NULL,                          -- e.g. 'Morning (09:00-12:00)'
    `start_time` TIME         NOT NULL,
    `end_time`   TIME         NOT NULL,
    `ordinal`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`  TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSlotTpl_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Printable outputs. System rows map to Blade views; the school can add variants (own header, size).
  CREATE TABLE IF NOT EXISTS `exp_print_templates` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`          VARCHAR(50)  NOT NULL,                       -- e.g. 'DATESHEET_CLASS','ROOM_DOOR_LIST','SEAT_STICKERS','ATTENDANCE_SHEET','STUDENT_SEAT_SLIP','INVIGILATOR_DUTY_LETTER','DUTY_CHART','ROOM_SEAT_MAP'
    `output_type`   ENUM('DATESHEET','ROOM_DOOR_LIST','SEAT_STICKER','ATTENDANCE_SHEET','STUDENT_SLIP','INVIGILATOR_LETTER','DUTY_CHART','SEAT_MAP','OTHER') NOT NULL,
    `name`          VARCHAR(100) NOT NULL,
    `view_name`     VARCHAR(150) NOT NULL,                       -- Blade view, e.g. 'exam-planning::print.room-door-list'
    `paper_size`    ENUM('A4','A3','LETTER','LABEL_A4_24','LABEL_A4_65') NOT NULL DEFAULT 'A4',
    `orientation`   ENUM('PORTRAIT','LANDSCAPE') NOT NULL DEFAULT 'PORTRAIT',
    `options_json`  JSON         DEFAULT NULL,                   -- e.g. {"show_photo":true,"show_signature_box":true,"per_page":24}
    `is_default`    TINYINT(1)   NOT NULL DEFAULT 0,             -- default template for its output_type (app keeps one per type)
    `is_system`     TINYINT(1)   NOT NULL DEFAULT 0,
    `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPrintTpl_code` (`code`),
    KEY `idx_expPrintTpl_type` (`output_type`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Special needs of a student for an academic session (re-used by every plan of that session).
  CREATE TABLE IF NOT EXISTS `exp_student_needs` (
    `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `student_id`          INT UNSIGNED NOT NULL,                 -- FK to std_students.id
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,            -- FK to sch_org_academic_sessions_jnt.id (same as std_student_academic_sessions)
    `need_type_id`        INT UNSIGNED NOT NULL,                 -- FK to exp_need_types.id
    `extra_minutes`       SMALLINT UNSIGNED DEFAULT NULL,        -- NULL = take exp_need_types.default_extra_minutes
    `subject_id`          BIGINT UNSIGNED DEFAULT NULL,             -- FK to sch_subjects.id; NULL = all subjects (e.g. scribe only for Maths)
    `valid_from`          DATE         DEFAULT NULL,
    `valid_to`            DATE         DEFAULT NULL,             -- e.g. temporary fracture
    `document_media_id`   INT UNSIGNED DEFAULT NULL,             -- FK to sys_media.id (certificate) - no FK constraint, media is polymorphic
    `remarks`             VARCHAR(255) DEFAULT NULL,
    `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
    `created_by`          INT UNSIGNED DEFAULT NULL,             -- FK to sys_users.id
    `created_at`          TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expStudentNeed_student_type_subject` (`student_id`, `academic_session_id`, `need_type_id`, `subject_id`),
    KEY `idx_expStudentNeed_session` (`academic_session_id`),
    CONSTRAINT `fk_expStudentNeed_studentId`  FOREIGN KEY (`student_id`)          REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_expStudentNeed_sessionId`  FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_expStudentNeed_needTypeId` FOREIGN KEY (`need_type_id`)        REFERENCES `exp_need_types` (`id`),
    CONSTRAINT `fk_expStudentNeed_subjectId`  FOREIGN KEY (`subject_id`)          REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_expStudentNeed_createdBy`  FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 2 - EXAM PLAN SETUP (one plan = one examination event, e.g. 'Half Yearly 2026-27')
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `exp_exam_plans` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid`                  BINARY(16)   NOT NULL,
    `academic_session_id`   SMALLINT UNSIGNED NOT NULL,          -- FK to sch_org_academic_sessions_jnt.id
    `exam_type_id`          INT UNSIGNED DEFAULT NULL,           -- FK to lms_exam_types.id (optional: link to LmsExam 'HY-EXAM' etc.)
    `code`                  VARCHAR(50)  NOT NULL,               -- e.g. 'HY_2026_27'
    `name`                  VARCHAR(150) NOT NULL,               -- e.g. 'Half Yearly Examination 2026-27'
    `description`           TEXT         DEFAULT NULL,
    `start_date`            DATE         NOT NULL,               -- first possible exam day
    `end_date`              DATE         NOT NULL,               -- last possible exam day
    `weekly_off_days`       VARCHAR(20)  NOT NULL DEFAULT '7',   -- CSV ISO weekday numbers (1=Mon..7=Sun), e.g. '7' or '6,7'
    `status`                ENUM('DRAFT','DATESHEET_READY','DATESHEET_PUBLISHED','SEATING_READY','INVIGILATION_READY','PUBLISHED','IN_PROGRESS','CONCLUDED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
    `source`                ENUM('MANUAL','LMS_IMPORT','COPY') NOT NULL DEFAULT 'MANUAL',
    `copied_from_plan_id`   INT UNSIGNED DEFAULT NULL,           -- FK to exp_exam_plans.id (plan cloned from a previous exam)
    `sync_to_lms`           TINYINT(1)   NOT NULL DEFAULT 0,     -- 1 = on publish, write date/time/room back to lms_exam_allocations (open question Q1)
    `settings_json`         JSON         DEFAULT NULL,           -- future plan-level switches, e.g. {"seat_label_scope":"plan","solver_time_limit_s":60}
    `current_version_no`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,-- last exp_plan_snapshots.version_no published
    `published_at`          DATETIME     DEFAULT NULL,
    `published_by`          INT UNSIGNED DEFAULT NULL,           -- FK to sys_users.id
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_by`            INT UNSIGNED DEFAULT NULL,           -- FK to sys_users.id
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlan_uuid` (`uuid`),
    UNIQUE KEY `uq_expPlan_session_code` (`academic_session_id`, `code`),
    KEY `idx_expPlan_status` (`status`),
    CONSTRAINT `fk_expPlan_sessionId`   FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_expPlan_examTypeId`  FOREIGN KEY (`exam_type_id`)        REFERENCES `lms_exam_types` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_expPlan_copiedFrom`  FOREIGN KEY (`copied_from_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_expPlan_publishedBy` FOREIGN KEY (`published_by`)        REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_expPlan_createdBy`   FOREIGN KEY (`created_by`)          REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Which class-sections take part in this plan (e.g. UT for IX-X only).
  CREATE TABLE IF NOT EXISTS `exp_plan_class_sections` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`     INT UNSIGNED NOT NULL,                    -- FK to exp_exam_plans.id
    `class_section_id` INT UNSIGNED NOT NULL,                    -- FK to sch_class_section_jnt.id
    `class_id`         INT UNSIGNED NOT NULL,                    -- FK to sch_classes.id (denormalised for fast grouping)
    `student_count`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,     -- refreshed by the Prepare step from std_student_academic_sessions
    `is_included`      TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanCs_plan_cs` (`exam_plan_id`, `class_section_id`),
    KEY `idx_expPlanCs_class` (`exam_plan_id`, `class_id`),
    CONSTRAINT `fk_expPlanCs_planId`    FOREIGN KEY (`exam_plan_id`)     REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanCs_csId`      FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`),
    CONSTRAINT `fk_expPlanCs_classId`   FOREIGN KEY (`class_id`)         REFERENCES `sch_classes` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Exam windows of a day for this plan (1..N per day).
  CREATE TABLE IF NOT EXISTS `exp_plan_slots` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`     INT UNSIGNED NOT NULL,                    -- FK to exp_exam_plans.id
    `slot_template_id` INT UNSIGNED DEFAULT NULL,                -- FK to exp_slot_templates.id (where it was copied from)
    `code`             VARCHAR(20)  NOT NULL,                    -- e.g. 'MORNING'
    `name`             VARCHAR(50)  NOT NULL,
    `start_time`       TIME         NOT NULL,
    `end_time`         TIME         NOT NULL,
    `reporting_time`   TIME         DEFAULT NULL,                -- invigilator reporting time (printed on duty letters)
    `ordinal`          TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`        TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanSlot_plan_code` (`exam_plan_id`, `code`),
    CONSTRAINT `fk_expPlanSlot_planId`     FOREIGN KEY (`exam_plan_id`)     REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanSlot_templateId` FOREIGN KEY (`slot_template_id`) REFERENCES `exp_slot_templates` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Classes allowed in a slot. NO rows for a slot = every class may use it.
  CREATE TABLE IF NOT EXISTS `exp_plan_slot_classes` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plan_slot_id` INT UNSIGNED NOT NULL,                        -- FK to exp_plan_slots.id
    `class_id`     INT UNSIGNED NOT NULL,                        -- FK to sch_classes.id
    `created_at`   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSlotClass_slot_class` (`plan_slot_id`, `class_id`),
    CONSTRAINT `fk_expSlotClass_slotId`  FOREIGN KEY (`plan_slot_id`) REFERENCES `exp_plan_slots` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSlotClass_classId` FOREIGN KEY (`class_id`)     REFERENCES `sch_classes` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Calendar of the plan: every date between start and end, pre-filled from weekly_off_days + sch_holidays.
  CREATE TABLE IF NOT EXISTS `exp_plan_days` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id` INT UNSIGNED NOT NULL,                        -- FK to exp_exam_plans.id
    `exam_date`    DATE         NOT NULL,
    `day_type`     ENUM('EXAM_DAY','WEEKLY_OFF','HOLIDAY','BLOCKED','PREP_DAY') NOT NULL DEFAULT 'EXAM_DAY',
    `holiday_id`   INT UNSIGNED DEFAULT NULL,                    -- FK to sch_holidays.id when day_type = HOLIDAY
    `note`         VARCHAR(150) DEFAULT NULL,                    -- e.g. 'Sports day', 'Diwali'
    `created_at`   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanDay_plan_date` (`exam_plan_id`, `exam_date`),
    CONSTRAINT `fk_expPlanDay_planId`    FOREIGN KEY (`exam_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanDay_holidayId` FOREIGN KEY (`holiday_id`)   REFERENCES `sch_holidays` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Papers to schedule: one row per class x subject (x option). Typed by hand, copied, or imported from lms_exam_papers.
  CREATE TABLE IF NOT EXISTS `exp_plan_papers` (
    `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`        INT UNSIGNED NOT NULL,                 -- FK to exp_exam_plans.id
    `class_id`            INT UNSIGNED NOT NULL,                 -- FK to sch_classes.id
    `subject_id`          BIGINT UNSIGNED NOT NULL,                 -- FK to sch_subjects.id
    `lms_exam_paper_id`   INT UNSIGNED DEFAULT NULL,             -- FK to lms_exam_papers.id (set when imported / linked)
    `paper_code`          VARCHAR(50)  NOT NULL,                 -- e.g. 'X-MTH', 'XII-PHY-TH'
    `title`               VARCHAR(150) NOT NULL,                 -- e.g. 'Mathematics (Standard)'
    `audience_type`       ENUM('WHOLE_CLASS','OPTED_ONLY') NOT NULL DEFAULT 'WHOLE_CLASS', -- OPTED_ONLY = only students with the subject in std_student_opted_subjects
    `duration_minutes`    SMALLINT UNSIGNED NOT NULL,            -- e.g. 180
    `is_major`            TINYINT(1)   NOT NULL DEFAULT 0,       -- 'heavy' paper: DS_MAJOR_GAP rule applies
    `min_gap_days_before` TINYINT UNSIGNED DEFAULT NULL,         -- per-paper override of the DS_MAJOR_GAP param
    `group_key`           VARCHAR(50)  DEFAULT NULL,             -- papers sharing a key MUST sit together (e.g. Hindi/Sanskrit/French options of IX = 'IX-LANG2')
    `preferred_date`      DATE         DEFAULT NULL,             -- SOFT wish
    `fixed_date`          DATE         DEFAULT NULL,             -- HARD pin (manual)
    `fixed_slot_id`       INT UNSIGNED DEFAULT NULL,             -- FK to exp_plan_slots.id, HARD pin (manual)
    `is_practical`        TINYINT(1)   NOT NULL DEFAULT 0,       -- practicals can be excluded from the written date sheet
    `exclude_from_seating` TINYINT(1)  NOT NULL DEFAULT 0,       -- 1 = scheduled but held in own lab / class (no seating plan)
    `candidate_count`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,  -- refreshed by Prepare from exp_plan_paper_students
    `ordinal`             SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanPaper_plan_code` (`exam_plan_id`, `paper_code`),
    KEY `idx_expPlanPaper_class` (`exam_plan_id`, `class_id`),
    KEY `idx_expPlanPaper_group` (`exam_plan_id`, `group_key`),
    CONSTRAINT `fk_expPlanPaper_planId`    FOREIGN KEY (`exam_plan_id`)      REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanPaper_classId`   FOREIGN KEY (`class_id`)          REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_expPlanPaper_subjectId` FOREIGN KEY (`subject_id`)        REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_expPlanPaper_lmsPaper`  FOREIGN KEY (`lms_exam_paper_id`) REFERENCES `lms_exam_papers` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_expPlanPaper_fixedSlot` FOREIGN KEY (`fixed_slot_id`)     REFERENCES `exp_plan_slots` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Materialised candidate list of each paper (built by Prepare; admin may add / exempt a student).
  -- This is what the engine reads, so a run is reproducible even if student data changes later.
  CREATE TABLE IF NOT EXISTS `exp_plan_paper_students` (
    `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plan_paper_id`               INT UNSIGNED NOT NULL,         -- FK to exp_plan_papers.id
    `student_id`                  INT UNSIGNED NOT NULL,         -- FK to std_students.id
    `student_academic_session_id` INT UNSIGNED NOT NULL,         -- FK to std_student_academic_sessions.id
    `class_section_id`            INT UNSIGNED NOT NULL,         -- FK to sch_class_section_jnt.id (denormalised)
    `roll_no`                     INT UNSIGNED DEFAULT NULL,     -- copied for seat-fill order
    `status`                      ENUM('CANDIDATE','EXEMPTED','MANUAL_ADD') NOT NULL DEFAULT 'CANDIDATE',
    `remarks`                     VARCHAR(150) DEFAULT NULL,
    `created_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPaperStd_paper_student` (`plan_paper_id`, `student_id`),
    KEY `idx_expPaperStd_student` (`student_id`),
    CONSTRAINT `fk_expPaperStd_paperId`   FOREIGN KEY (`plan_paper_id`)               REFERENCES `exp_plan_papers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPaperStd_studentId` FOREIGN KEY (`student_id`)                  REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_expPaperStd_sasId`     FOREIGN KEY (`student_academic_session_id`) REFERENCES `std_student_academic_sessions` (`id`),
    CONSTRAINT `fk_expPaperStd_csId`      FOREIGN KEY (`class_section_id`)            REFERENCES `sch_class_section_jnt` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Rule instances of this plan (copied from exp_rule_definitions when the plan is created; then edited).
  -- The same rule may appear more than once with a scope (e.g. a stricter gap only for class X).
  CREATE TABLE IF NOT EXISTS `exp_plan_rules` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`       INT UNSIGNED NOT NULL,                  -- FK to exp_exam_plans.id
    `rule_definition_id` INT UNSIGNED NOT NULL,                  -- FK to exp_rule_definitions.id
    `scope_class_id`     INT UNSIGNED DEFAULT NULL,              -- FK to sch_classes.id; NULL = whole plan
    `is_enabled`         TINYINT(1)   NOT NULL DEFAULT 1,
    `strictness`         ENUM('HARD','SOFT') NOT NULL,
    `weight`             SMALLINT UNSIGNED NOT NULL DEFAULT 10,
    `params_json`        JSON         DEFAULT NULL,              -- validated against exp_rule_definitions.params_schema_json
    `created_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanRule_plan_rule_scope` (`exam_plan_id`, `rule_definition_id`, `scope_class_id`),
    CONSTRAINT `fk_expPlanRule_planId`  FOREIGN KEY (`exam_plan_id`)       REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanRule_ruleId`  FOREIGN KEY (`rule_definition_id`) REFERENCES `exp_rule_definitions` (`id`),
    CONSTRAINT `fk_expPlanRule_classId` FOREIGN KEY (`scope_class_id`)     REFERENCES `sch_classes` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Rooms offered to this plan (subset of exp_room_layouts).
  CREATE TABLE IF NOT EXISTS `exp_plan_rooms` (
    `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`         INT UNSIGNED NOT NULL,                -- FK to exp_exam_plans.id
    `room_layout_id`       INT UNSIGNED NOT NULL,                -- FK to exp_room_layouts.id
    `max_seats_override`   SMALLINT UNSIGNED DEFAULT NULL,       -- e.g. use only 30 of 48 seats for this exam
    `priority`             TINYINT UNSIGNED NOT NULL DEFAULT 50, -- higher = opened first (e.g. rooms near the exam cell)
    `is_available`         TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanRoom_plan_layout` (`exam_plan_id`, `room_layout_id`),
    CONSTRAINT `fk_expPlanRoom_planId`   FOREIGN KEY (`exam_plan_id`)   REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanRoom_layoutId` FOREIGN KEY (`room_layout_id`) REFERENCES `exp_room_layouts` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- A plan room that is NOT available on a date (and optionally only one slot).
  CREATE TABLE IF NOT EXISTS `exp_plan_room_blocks` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plan_room_id` INT UNSIGNED NOT NULL,                        -- FK to exp_plan_rooms.id
    `block_date`   DATE         NOT NULL,
    `plan_slot_id` INT UNSIGNED DEFAULT NULL,                    -- FK to exp_plan_slots.id; NULL = whole day
    `reason`       VARCHAR(150) DEFAULT NULL,
    `created_at`   TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expRoomBlock_room_date_slot` (`plan_room_id`, `block_date`, `plan_slot_id`),
    CONSTRAINT `fk_expRoomBlock_planRoomId` FOREIGN KEY (`plan_room_id`) REFERENCES `exp_plan_rooms` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expRoomBlock_slotId`     FOREIGN KEY (`plan_slot_id`) REFERENCES `exp_plan_slots` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Invigilator pool of this plan. Anchored on sch_employees so non-teaching staff can be added later.
  CREATE TABLE IF NOT EXISTS `exp_plan_invigilators` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`       INT UNSIGNED NOT NULL,                  -- FK to exp_exam_plans.id
    `employee_id`        INT UNSIGNED NOT NULL,                  -- FK to sch_employees.id
    `teacher_profile_id` INT UNSIGNED DEFAULT NULL,              -- FK to sch_teacher_profile.id (NULL for non-teaching staff)
    `allowed_roles`      SET('INVIGILATOR','FLYING_SQUAD','RELIEVER','CHIEF_SUPERINTENDENT','SPECIAL_ROOM') NOT NULL DEFAULT 'INVIGILATOR,RELIEVER',
    `max_duties_total`   TINYINT UNSIGNED DEFAULT NULL,          -- NULL = use IV_MAX_DUTIES rule param
    `max_duties_per_day` TINYINT UNSIGNED DEFAULT NULL,          -- NULL = use IV_MAX_DUTIES rule param
    `is_available`       TINYINT(1)   NOT NULL DEFAULT 1,        -- 0 = excluded from this plan entirely
    `remarks`            VARCHAR(150) DEFAULT NULL,
    `created_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expPlanInvig_plan_employee` (`exam_plan_id`, `employee_id`),
    CONSTRAINT `fk_expPlanInvig_planId`    FOREIGN KEY (`exam_plan_id`)       REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPlanInvig_employee`  FOREIGN KEY (`employee_id`)        REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_expPlanInvig_teacher`   FOREIGN KEY (`teacher_profile_id`) REFERENCES `sch_teacher_profile` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Manual unavailability of an invigilator (approved leave is read live from sch_employee_leave_applications).
  CREATE TABLE IF NOT EXISTS `exp_invigilator_blocks` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plan_invigilator_id` INT UNSIGNED NOT NULL,                 -- FK to exp_plan_invigilators.id
    `block_date`         DATE         NOT NULL,
    `plan_slot_id`       INT UNSIGNED DEFAULT NULL,              -- FK to exp_plan_slots.id; NULL = whole day
    `reason`             VARCHAR(150) DEFAULT NULL,              -- e.g. 'Paper evaluation', 'Board duty'
    `created_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expInvigBlock_inv_date_slot` (`plan_invigilator_id`, `block_date`, `plan_slot_id`),
    CONSTRAINT `fk_expInvigBlock_invId`  FOREIGN KEY (`plan_invigilator_id`) REFERENCES `exp_plan_invigilators` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expInvigBlock_slotId` FOREIGN KEY (`plan_slot_id`)        REFERENCES `exp_plan_slots` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 3 - ENGINE RUNS (one row per Generate click; full audit + diagnostics)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `exp_generation_runs` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `uuid`               BINARY(16)   NOT NULL,                  -- also the engine job id over HTTP
    `exam_plan_id`       INT UNSIGNED NOT NULL,                  -- FK to exp_exam_plans.id
    `stage`              ENUM('DATESHEET','SEATING','INVIGILATION') NOT NULL,
    `scope_sitting_id`   INT UNSIGNED DEFAULT NULL,              -- FK to exp_sittings.id: re-plan ONE sitting only (NULL = all)
    `status`             ENUM('QUEUED','RUNNING','SUCCEEDED','PARTIAL','INFEASIBLE','FAILED','CANCELLED') NOT NULL DEFAULT 'QUEUED',
    `solver`             VARCHAR(30)  NOT NULL DEFAULT 'CP_SAT', -- 'CP_SAT' | 'GREEDY' (fallback) - future solvers add here
    `engine_version`     VARCHAR(20)  DEFAULT NULL,
    `driver`             ENUM('LOCAL','HTTP') DEFAULT NULL,      -- config/engines.php driver that ran it
    `time_limit_seconds` SMALLINT UNSIGNED NOT NULL DEFAULT 60,
    `random_seed`        INT UNSIGNED DEFAULT NULL,              -- same input + seed = same output
    `input_hash`         CHAR(64)     DEFAULT NULL,              -- sha256 of the input JSON (skip re-run if unchanged)
    `input_path`         VARCHAR(255) DEFAULT NULL,              -- storage path of the input JSON (kept for replay / bug reports)
    `output_path`        VARCHAR(255) DEFAULT NULL,
    `progress_json`      JSON         DEFAULT NULL,              -- last progress snapshot (live modal reads cache; this is the final copy)
    `stats_json`         JSON         DEFAULT NULL,              -- e.g. {"students":1820,"rooms_opened":38,"seats_used":1820,"objective":412}
    `hard_violations`    INT UNSIGNED NOT NULL DEFAULT 0,
    `soft_penalty`       INT UNSIGNED NOT NULL DEFAULT 0,
    `is_applied`         TINYINT(1)   NOT NULL DEFAULT 0,        -- 1 = result written into output tables
    `error_message`      TEXT         DEFAULT NULL,
    `queued_at`          DATETIME     DEFAULT NULL,
    `started_at`         DATETIME     DEFAULT NULL,
    `finished_at`        DATETIME     DEFAULT NULL,
    `duration_ms`        INT UNSIGNED DEFAULT NULL,
    `triggered_by`       INT UNSIGNED DEFAULT NULL,              -- FK to sys_users.id
    `created_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expRun_uuid` (`uuid`),
    KEY `idx_expRun_plan_stage` (`exam_plan_id`, `stage`, `status`),
    CONSTRAINT `fk_expRun_planId`      FOREIGN KEY (`exam_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expRun_triggeredBy` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
    -- fk to exp_sittings added after exp_sittings is created (see section 4)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Everything the engine wants a human to see: broken soft rules, infeasibility cores, unplaced items.
  CREATE TABLE IF NOT EXISTS `exp_run_issues` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `generation_run_id` INT UNSIGNED NOT NULL,                   -- FK to exp_generation_runs.id
    `severity`          ENUM('ERROR','WARNING','INFO') NOT NULL,
    `issue_code`        VARCHAR(50)  NOT NULL,                   -- e.g. 'INFEASIBLE_CORE','SOFT_BROKEN','UNPLACED_PAPER','UNPLACED_STUDENT','ROOM_SHORTAGE','RULE_NOT_IMPLEMENTED'
    `rule_code`         VARCHAR(50)  DEFAULT NULL,               -- exp_rule_definitions.code involved (if any)
    `entity_type`       VARCHAR(30)  DEFAULT NULL,               -- 'PAPER','STUDENT','ROOM','SITTING','EMPLOYEE','CLASS'
    `entity_id`         INT UNSIGNED DEFAULT NULL,
    `message`           VARCHAR(500) NOT NULL,                   -- human readable, e.g. 'Class X Maths and Science need a 1-day gap but only 6 exam days exist'
    `suggestion`        VARCHAR(500) DEFAULT NULL,               -- e.g. 'Relax DS_MAJOR_GAP to SOFT or add 2 exam days'
    `details_json`      JSON         DEFAULT NULL,
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_expRunIssue_run` (`generation_run_id`, `severity`),
    CONSTRAINT `fk_expRunIssue_runId` FOREIGN KEY (`generation_run_id`) REFERENCES `exp_generation_runs` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 4 - OUTPUTS (written by the engine or by hand; read by printouts / portals)
-- ===========================================================================

  -- A sitting = one exam window (date + slot). Every paper in it starts together.
  CREATE TABLE IF NOT EXISTS `exp_sittings` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`   INT UNSIGNED NOT NULL,                      -- FK to exp_exam_plans.id
    `exam_date`      DATE         NOT NULL,
    `plan_slot_id`   INT UNSIGNED NOT NULL,                      -- FK to exp_plan_slots.id
    `start_time`     TIME         NOT NULL,                      -- copied from the slot (can be edited for one day)
    `end_time`       TIME         NOT NULL,                      -- latest regular end; extra-time rooms end later (exp_sitting_rooms.end_time)
    `candidate_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `seating_status` ENUM('NOT_PLANNED','PLANNED','LOCKED') NOT NULL DEFAULT 'NOT_PLANNED',
    `invigilation_status` ENUM('NOT_PLANNED','PLANNED','LOCKED') NOT NULL DEFAULT 'NOT_PLANNED',
    `status`         ENUM('SCHEDULED','IN_PROGRESS','DONE','CANCELLED','POSTPONED') NOT NULL DEFAULT 'SCHEDULED',
    `created_at`     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSitting_plan_date_slot` (`exam_plan_id`, `exam_date`, `plan_slot_id`),
    CONSTRAINT `fk_expSitting_planId` FOREIGN KEY (`exam_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSitting_slotId` FOREIGN KEY (`plan_slot_id`) REFERENCES `exp_plan_slots` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  ALTER TABLE `exp_generation_runs`
    ADD CONSTRAINT `fk_expRun_scopeSitting` FOREIGN KEY (`scope_sitting_id`) REFERENCES `exp_sittings` (`id`) ON DELETE SET NULL;

  -- THE DATE SHEET: which paper sits in which sitting. One row per paper.
  CREATE TABLE IF NOT EXISTS `exp_sitting_papers` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sitting_id`        INT UNSIGNED NOT NULL,                   -- FK to exp_sittings.id
    `plan_paper_id`     INT UNSIGNED NOT NULL,                   -- FK to exp_plan_papers.id
    `source`            ENUM('ENGINE','MANUAL','IMPORT') NOT NULL DEFAULT 'ENGINE',
    `is_locked`         TINYINT(1)   NOT NULL DEFAULT 0,         -- locked rows survive a re-run and are sent to the engine as pins
    `generation_run_id` INT UNSIGNED DEFAULT NULL,               -- FK to exp_generation_runs.id
    `lms_allocation_synced_at` DATETIME DEFAULT NULL,            -- when written back to lms_exam_allocations (if sync_to_lms)
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSittingPaper_paper` (`plan_paper_id`),
    KEY `idx_expSittingPaper_sitting` (`sitting_id`),
    CONSTRAINT `fk_expSittingPaper_sittingId` FOREIGN KEY (`sitting_id`)        REFERENCES `exp_sittings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSittingPaper_paperId`   FOREIGN KEY (`plan_paper_id`)     REFERENCES `exp_plan_papers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSittingPaper_runId`     FOREIGN KEY (`generation_run_id`) REFERENCES `exp_generation_runs` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Rooms opened for a sitting.
  CREATE TABLE IF NOT EXISTS `exp_sitting_rooms` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sitting_id`            INT UNSIGNED NOT NULL,               -- FK to exp_sittings.id
    `plan_room_id`          INT UNSIGNED NOT NULL,               -- FK to exp_plan_rooms.id
    `room_kind`             ENUM('REGULAR','SPECIAL','ACCESSIBLE','EXTRA_TIME') NOT NULL DEFAULT 'REGULAR',
    `seats_used`            SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `invigilators_required` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- from IV_RATIO rule at plan time
    `end_time`              TIME         DEFAULT NULL,           -- > sitting end_time when extra-time students sit here
    `pattern_code`          VARCHAR(30)  DEFAULT NULL,           -- seating pattern used, e.g. 'LANE_ALTERNATE','CHECKERBOARD'
    `source`                ENUM('ENGINE','MANUAL') NOT NULL DEFAULT 'ENGINE',
    `is_locked`             TINYINT(1)   NOT NULL DEFAULT 0,
    `generation_run_id`     INT UNSIGNED DEFAULT NULL,           -- FK to exp_generation_runs.id
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSittingRoom_sitting_room` (`sitting_id`, `plan_room_id`),
    CONSTRAINT `fk_expSittingRoom_sittingId` FOREIGN KEY (`sitting_id`)        REFERENCES `exp_sittings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSittingRoom_roomId`    FOREIGN KEY (`plan_room_id`)      REFERENCES `exp_plan_rooms` (`id`),
    CONSTRAINT `fk_expSittingRoom_runId`     FOREIGN KEY (`generation_run_id`) REFERENCES `exp_generation_runs` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Admin pins BEFORE generating: student -> room (and optionally exact seat). Engine treats as HARD.
  CREATE TABLE IF NOT EXISTS `exp_seat_pins` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`  INT UNSIGNED NOT NULL,                       -- FK to exp_exam_plans.id
    `student_id`    INT UNSIGNED NOT NULL,                       -- FK to std_students.id
    `sitting_id`    INT UNSIGNED DEFAULT NULL,                   -- FK to exp_sittings.id; NULL = every sitting of the plan
    `plan_room_id`  INT UNSIGNED NOT NULL,                       -- FK to exp_plan_rooms.id
    `row_no`        TINYINT UNSIGNED DEFAULT NULL,               -- NULL = any seat in the room
    `column_no`     TINYINT UNSIGNED DEFAULT NULL,
    `seat_pos`      TINYINT UNSIGNED DEFAULT NULL,
    `reason`        VARCHAR(150) DEFAULT NULL,
    `created_by`    INT UNSIGNED DEFAULT NULL,                   -- FK to sys_users.id
    `created_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSeatPin_plan_student_sitting` (`exam_plan_id`, `student_id`, `sitting_id`),
    CONSTRAINT `fk_expSeatPin_planId`    FOREIGN KEY (`exam_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSeatPin_studentId` FOREIGN KEY (`student_id`)   REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_expSeatPin_sittingId` FOREIGN KEY (`sitting_id`)   REFERENCES `exp_sittings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSeatPin_roomId`    FOREIGN KEY (`plan_room_id`) REFERENCES `exp_plan_rooms` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSeatPin_createdBy` FOREIGN KEY (`created_by`)   REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- THE SEATING PLAN: one row per student per sitting.
  CREATE TABLE IF NOT EXISTS `exp_seat_allocations` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sitting_id`        INT UNSIGNED NOT NULL,                   -- FK to exp_sittings.id
    `sitting_room_id`   INT UNSIGNED NOT NULL,                   -- FK to exp_sitting_rooms.id
    `sitting_paper_id`  INT UNSIGNED NOT NULL,                   -- FK to exp_sitting_papers.id (which paper this student writes)
    `student_id`        INT UNSIGNED NOT NULL,                   -- FK to std_students.id
    `class_section_id`  INT UNSIGNED NOT NULL,                   -- FK to sch_class_section_jnt.id (denormalised for door lists)
    `row_no`            TINYINT UNSIGNED NOT NULL,
    `column_no`         TINYINT UNSIGNED NOT NULL,
    `seat_pos`          TINYINT UNSIGNED NOT NULL,
    `seat_label`        VARCHAR(30)  NOT NULL,                   -- rendered from exp_room_layouts.seat_label_format, e.g. '11G-10A-R02-C3-L'
    `extra_minutes`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,    -- resolved from exp_student_needs at plan time
    `need_type_codes`   VARCHAR(100) DEFAULT NULL,               -- CSV snapshot, e.g. 'SCRIBE,EXTRA_TIME' (for stickers / door list)
    `source`            ENUM('ENGINE','MANUAL','PIN') NOT NULL DEFAULT 'ENGINE',
    `is_locked`         TINYINT(1)   NOT NULL DEFAULT 0,
    `generation_run_id` INT UNSIGNED DEFAULT NULL,               -- FK to exp_generation_runs.id
    `attendance_status` ENUM('NOT_MARKED','PRESENT','ABSENT','LATE','UFM') NOT NULL DEFAULT 'NOT_MARKED', -- v2 room attendance; UFM = unfair means
    `answer_sheet_no`   VARCHAR(30)  DEFAULT NULL,               -- v2: booklet serial written on the attendance sheet
    `created_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSeatAlloc_sitting_student` (`sitting_id`, `student_id`),
    UNIQUE KEY `uq_expSeatAlloc_room_seat` (`sitting_room_id`, `row_no`, `column_no`, `seat_pos`),
    KEY `idx_expSeatAlloc_student` (`student_id`),
    KEY `idx_expSeatAlloc_paper` (`sitting_paper_id`),
    CONSTRAINT `fk_expSeatAlloc_sittingId` FOREIGN KEY (`sitting_id`)        REFERENCES `exp_sittings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSeatAlloc_roomId`    FOREIGN KEY (`sitting_room_id`)   REFERENCES `exp_sitting_rooms` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSeatAlloc_paperId`   FOREIGN KEY (`sitting_paper_id`)  REFERENCES `exp_sitting_papers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSeatAlloc_studentId` FOREIGN KEY (`student_id`)        REFERENCES `std_students` (`id`),
    CONSTRAINT `fk_expSeatAlloc_csId`      FOREIGN KEY (`class_section_id`)  REFERENCES `sch_class_section_jnt` (`id`),
    CONSTRAINT `fk_expSeatAlloc_runId`     FOREIGN KEY (`generation_run_id`) REFERENCES `exp_generation_runs` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- THE DUTY CHART: one row per person per sitting (room duty, or a roving role with sitting_room_id NULL).
  CREATE TABLE IF NOT EXISTS `exp_invigilation_duties` (
    `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sitting_id`           INT UNSIGNED NOT NULL,                -- FK to exp_sittings.id
    `sitting_room_id`      INT UNSIGNED DEFAULT NULL,            -- FK to exp_sitting_rooms.id; NULL for FLYING_SQUAD / RELIEVER / CHIEF
    `plan_invigilator_id`  INT UNSIGNED NOT NULL,                -- FK to exp_plan_invigilators.id
    `employee_id`          INT UNSIGNED NOT NULL,                -- FK to sch_employees.id (denormalised for 'my duties' queries)
    `duty_role`            ENUM('INVIGILATOR','FLYING_SQUAD','RELIEVER','CHIEF_SUPERINTENDENT','SPECIAL_ROOM') NOT NULL DEFAULT 'INVIGILATOR',
    `source`               ENUM('ENGINE','MANUAL') NOT NULL DEFAULT 'ENGINE',
    `is_locked`            TINYINT(1)   NOT NULL DEFAULT 0,
    `generation_run_id`    INT UNSIGNED DEFAULT NULL,            -- FK to exp_generation_runs.id
    `status`               ENUM('ASSIGNED','ACKNOWLEDGED','REPLACED','ABSENT','DONE') NOT NULL DEFAULT 'ASSIGNED',
    `replaced_by_duty_id`  INT UNSIGNED DEFAULT NULL,            -- FK to exp_invigilation_duties.id (day-of swap)
    `acknowledged_at`      DATETIME     DEFAULT NULL,            -- teacher pressed 'Seen' on the portal / app
    `remarks`              VARCHAR(150) DEFAULT NULL,
    `created_at`           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expDuty_sitting_employee` (`sitting_id`, `employee_id`),
    KEY `idx_expDuty_room` (`sitting_room_id`),
    KEY `idx_expDuty_employee` (`employee_id`),
    CONSTRAINT `fk_expDuty_sittingId`  FOREIGN KEY (`sitting_id`)          REFERENCES `exp_sittings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expDuty_roomId`     FOREIGN KEY (`sitting_room_id`)     REFERENCES `exp_sitting_rooms` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expDuty_invId`      FOREIGN KEY (`plan_invigilator_id`) REFERENCES `exp_plan_invigilators` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expDuty_employeeId` FOREIGN KEY (`employee_id`)         REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_expDuty_runId`      FOREIGN KEY (`generation_run_id`)   REFERENCES `exp_generation_runs` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_expDuty_replacedBy` FOREIGN KEY (`replaced_by_duty_id`) REFERENCES `exp_invigilation_duties` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 5 - PUBLISH, SNAPSHOTS & NOTICES
-- ===========================================================================

  -- Frozen copy of what was published (date sheet / seating / duties), for rollback, audit and 'what changed'.
  CREATE TABLE IF NOT EXISTS `exp_plan_snapshots` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`  INT UNSIGNED NOT NULL,                       -- FK to exp_exam_plans.id
    `version_no`    SMALLINT UNSIGNED NOT NULL,                  -- 1, 2, 3 ... per plan
    `scope`         SET('DATESHEET','SEATING','INVIGILATION') NOT NULL,
    `snapshot_json` LONGTEXT     NOT NULL,                       -- full output rows at publish time (JSON document)
    `change_note`   VARCHAR(255) DEFAULT NULL,                   -- e.g. 'Room 11G-10A under repair, 34 students moved'
    `published_by`  INT UNSIGNED DEFAULT NULL,                   -- FK to sys_users.id
    `created_at`    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_expSnapshot_plan_version` (`exam_plan_id`, `version_no`),
    CONSTRAINT `fk_expSnapshot_planId`      FOREIGN KEY (`exam_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expSnapshot_publishedBy` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Every notice sent (date sheet to parents, seat slip to students, duty letter to teachers).
  CREATE TABLE IF NOT EXISTS `exp_publications` (
    `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `exam_plan_id`       INT UNSIGNED NOT NULL,                  -- FK to exp_exam_plans.id
    `snapshot_id`        INT UNSIGNED DEFAULT NULL,              -- FK to exp_plan_snapshots.id (what version was announced)
    `audience`           ENUM('STUDENTS','PARENTS','TEACHERS','STAFF','ALL') NOT NULL,
    `content_type`       ENUM('DATESHEET','SEAT_SLIP','DUTY_LETTER','CHANGE_NOTICE','CUSTOM') NOT NULL,
    `channels`           SET('PORTAL','APP_PUSH','EMAIL','SMS','WHATSAPP') NOT NULL DEFAULT 'PORTAL',
    `scope_json`         JSON         DEFAULT NULL,              -- e.g. {"class_ids":[10,11]} or {"sitting_ids":[5]}
    `recipient_count`    INT UNSIGNED NOT NULL DEFAULT 0,
    `status`             ENUM('DRAFT','QUEUED','SENT','PARTIAL','FAILED') NOT NULL DEFAULT 'DRAFT',
    `notification_ref`   VARCHAR(100) DEFAULT NULL,              -- id of the batch in the Notification module (aut_ core)
    `scheduled_at`       DATETIME     DEFAULT NULL,
    `sent_at`            DATETIME     DEFAULT NULL,
    `created_by`         INT UNSIGNED DEFAULT NULL,              -- FK to sys_users.id
    `created_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_expPublication_plan` (`exam_plan_id`, `content_type`),
    CONSTRAINT `fk_expPublication_planId`     FOREIGN KEY (`exam_plan_id`) REFERENCES `exp_exam_plans` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_expPublication_snapshotId` FOREIGN KEY (`snapshot_id`)  REFERENCES `exp_plan_snapshots` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_expPublication_createdBy`  FOREIGN KEY (`created_by`)   REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ===========================================================================
-- 6 - REFERENCE SEED DATA (system rows; becomes the Laravel seeder)
-- ===========================================================================

  INSERT INTO `exp_rule_definitions`
    (`code`,`stage`,`name`,`default_strictness`,`default_weight`,`allow_hard`,`allow_soft`,`default_params_json`,`relax_priority`,`is_default_enabled`,`ordinal`) VALUES
    -- DATE SHEET
    ('DS_NO_STUDENT_CLASH',     'DATESHEET','A student never has two papers in the same sitting',                 'HARD',100,1,0, NULL,                                         0,  1, 10),
    ('DS_MAX_PAPERS_PER_DAY',   'DATESHEET','Maximum papers per student per day',                                 'HARD', 50,1,1, '{"max":1}',                                  40, 1, 20),
    ('DS_MAJOR_GAP',            'DATESHEET','Minimum gap (days) before a major paper',                            'HARD', 30,1,1, '{"min_gap_days":1,"count_weekly_off":false}',80, 1, 30),
    ('DS_SKIP_NON_EXAM_DAYS',   'DATESHEET','Only schedule on EXAM_DAY dates (holidays / weekly off skipped)',    'HARD',100,1,0, NULL,                                         0,  1, 40),
    ('DS_SLOT_SEAT_CAPACITY',   'DATESHEET','Candidates in a sitting must fit the exam seats available',          'HARD',100,1,0, '{"seat_buffer_pct":5}',                      10, 1, 50),
    ('DS_CLASS_ALLOWED_SLOTS',  'DATESHEET','Classes only in the slots allowed for them',                         'HARD', 50,1,0, NULL,                                         20, 1, 60),
    ('DS_GROUP_TOGETHER',       'DATESHEET','Papers with the same group_key sit in the same sitting',             'HARD', 50,1,0, NULL,                                         10, 1, 70),
    ('DS_PREFERRED_DATE',       'DATESHEET','Honour preferred dates',                                             'SOFT', 10,0,1, NULL,                                         0,  1, 80),
    ('DS_SPREAD_EVENLY',        'DATESHEET','Spread each class''s papers evenly over the exam window',            'SOFT', 10,0,1, NULL,                                         0,  1, 90),
    ('DS_FINISH_EARLY',         'DATESHEET','Prefer finishing the exam in as few days as possible',               'SOFT',  5,0,1, NULL,                                         0,  0, 100),
    -- SEATING
    ('ST_ROOM_CAPACITY',        'SEATING',  'Never exceed usable seats; never use a blocked seat',                'HARD',100,1,0, NULL,                                         0,  1, 10),
    ('ST_NO_ADJ_SIDE',          'SEATING',  'No two students of the same group side by side',                     'HARD', 50,1,1, '{"separate_by":"PAPER","across_aisle":false}',60, 1, 20),
    ('ST_NO_ADJ_FRONT_BACK',    'SEATING',  'No two students of the same group directly in front / behind',       'SOFT', 30,1,1, '{"separate_by":"PAPER"}',                    70, 1, 30),
    ('ST_NO_ADJ_DIAGONAL',      'SEATING',  'No two students of the same group diagonally adjacent',              'SOFT', 10,1,1, '{"separate_by":"PAPER"}',                    90, 0, 40),
    ('ST_SPECIAL_ROOM',         'SEATING',  'Scribe / reader / isolation students only in special rooms',         'HARD',100,1,0, NULL,                                         30, 1, 50),
    ('ST_ACCESSIBLE_ROOM',      'SEATING',  'Mobility-need students only in accessible rooms',                    'HARD',100,1,0, NULL,                                         30, 1, 60),
    ('ST_EXTRA_TIME_GROUPING',  'SEATING',  'Extra-time students grouped so other rooms release on time',         'SOFT', 40,1,1, '{"mode":"SEPARATE_ROOM"}',                   50, 1, 70),
    ('ST_FRONT_ROW_NEED',       'SEATING',  'Front-row needs (low vision etc.) get row 1-2',                      'SOFT', 30,1,1, '{"max_row":2}',                              50, 1, 80),
    ('ST_PINS',                 'SEATING',  'Respect admin seat pins',                                            'HARD',100,1,0, NULL,                                         5,  1, 90),
    ('ST_ROLL_ORDER',           'SEATING',  'Fill each lane in roll-number order',                                'SOFT',  5,0,1, NULL,                                         0,  1, 100),
    ('ST_MIN_ROOMS',            'SEATING',  'Open as few rooms as possible',                                      'SOFT', 20,0,1, NULL,                                         0,  1, 110),
    ('ST_KEEP_SECTION_TOGETHER','SEATING',  'Keep a section in as few rooms as possible',                         'SOFT', 10,0,1, NULL,                                         0,  1, 120),
    ('ST_NOT_HOME_ROOM',        'SEATING',  'Student not seated in their own class room',                         'SOFT', 10,1,1, NULL,                                         70, 0, 130),
    ('ST_STABLE_SEAT',          'SEATING',  'Same seat for a student across sittings where possible',             'SOFT',  5,0,1, NULL,                                         0,  0, 140),
    -- INVIGILATION
    ('IV_RATIO',                'INVIGILATION','Invigilators per room = max(min, ceil(students / ratio))',       'HARD',100,1,0, '{"students_per_invigilator":30,"min_per_room":1,"special_room_extra":0}',10,1,10),
    ('IV_FLYING_SQUAD',         'INVIGILATION','Flying squad / relievers per sitting',                            'HARD', 50,1,1, '{"flying_squad":1,"relievers_per_rooms":10}',40, 1, 20),
    ('IV_ONE_PLACE',            'INVIGILATION','A person has at most one duty per sitting',                       'HARD',100,1,0, NULL,                                         0,  1, 30),
    ('IV_LEAVE_AVAILABILITY',   'INVIGILATION','No duty while on approved leave or blocked',                      'HARD',100,1,0, '{"leave_statuses":["Approved"]}',            20, 1, 40),
    ('IV_NOT_OWN_SUBJECT',      'INVIGILATION','Never invigilate a paper of a subject you teach to that class',   'HARD', 50,1,1, '{"source":"TIMETABLE_THEN_CAPABILITY"}',     60, 1, 50),
    ('IV_NOT_OWN_CLASS',        'INVIGILATION','Class teacher not in a room containing own section',              'HARD', 40,1,1, NULL,                                         70, 1, 60),
    ('IV_MAX_DUTIES',           'INVIGILATION','Maximum duties per day / per plan',                               'HARD', 40,1,1, '{"per_day":1,"per_plan":null}',             60, 1, 70),
    ('IV_FAIR_SPREAD',          'INVIGILATION','Spread duties evenly (minimise max - min)',                       'SOFT', 30,0,1, NULL,                                         0,  1, 80),
    ('IV_ROTATE_ROOMS',         'INVIGILATION','Avoid the same room / same partner on consecutive sittings',      'SOFT',  5,0,1, NULL,                                         0,  0, 90),
    ('IV_GENDER_MIX',           'INVIGILATION','At least one female invigilator in rooms with girl candidates',   'SOFT', 20,1,1, NULL,                                         80, 0, 100);

  INSERT INTO `exp_need_types`
    (`code`,`name`,`needs_separate_room`,`needs_accessible_room`,`needs_front_row`,`default_extra_minutes`,`needs_companion_seat`,`is_system`) VALUES
    ('SCRIBE',            'Writer / Scribe',          1,0,0,20,1,1),
    ('READER',            'Reader',                   1,0,0,20,1,1),
    ('MEDICAL_ISOLATION', 'Medical isolation',        1,0,0, 0,0,1),
    ('MOBILITY',          'Mobility / wheelchair',    0,1,0, 0,0,1),
    ('EXTRA_TIME',        'Compensatory extra time',  0,0,0,20,0,1),
    ('LOW_VISION',        'Low vision (front row)',   0,0,1,20,0,1);

  INSERT INTO `exp_slot_templates` (`code`,`name`,`start_time`,`end_time`,`ordinal`) VALUES
    ('MORNING',   'Morning (09:00-12:00)',   '09:00:00','12:00:00',1),
    ('AFTERNOON', 'Afternoon (13:00-16:00)', '13:00:00','16:00:00',2);

  INSERT INTO `exp_print_templates` (`code`,`output_type`,`name`,`view_name`,`paper_size`,`orientation`,`is_default`,`is_system`) VALUES
    ('DATESHEET_CLASS',         'DATESHEET',          'Date sheet (class-wise)',       'examplanning::print.datesheet',         'A4','LANDSCAPE',1,1),
    ('ROOM_DOOR_LIST',          'ROOM_DOOR_LIST',     'Room door list',                'examplanning::print.room-door-list',     'A4','PORTRAIT', 1,1),
    ('ROOM_SEAT_MAP',           'SEAT_MAP',           'Room seat map (grid)',          'examplanning::print.room-seat-map',      'A4','LANDSCAPE',1,1),
    ('SEAT_STICKERS',           'SEAT_STICKER',       'Desk stickers (24 per sheet)',  'examplanning::print.seat-stickers',      'LABEL_A4_24','PORTRAIT',1,1),
    ('ATTENDANCE_SHEET',        'ATTENDANCE_SHEET',   'Room attendance sheet',         'examplanning::print.attendance-sheet',   'A4','PORTRAIT', 1,1),
    ('STUDENT_SEAT_SLIP',       'STUDENT_SLIP',       'Student seat slip',             'examplanning::print.student-seat-slip',  'A4','PORTRAIT', 1,1),
    ('INVIGILATOR_DUTY_LETTER', 'INVIGILATOR_LETTER', 'Invigilator duty letter',       'examplanning::print.duty-letter',        'A4','PORTRAIT', 1,1),
    ('DUTY_CHART',              'DUTY_CHART',         'Master duty chart',             'examplanning::print.duty-chart',         'A3','LANDSCAPE',1,1);

-- =====================================================================
-- END OF ExamPlanning_DDL_v1.0  (29 tables)
-- =====================================================================
