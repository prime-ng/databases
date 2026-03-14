




CREATE TABLE IF NOT EXISTS tt_school_timing_profile (
  sch_profile_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  profile_name   VARCHAR(100) NOT NULL,       -- e.g., Summer Standard
  short_name     VARCHAR(20)  NULL,           -- e.g., SUMMER_STD
  description    VARCHAR(200) NULL,
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted     TINYINT(1)   NOT NULL DEFAULT 0,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at     TIMESTAMP    NULL,
  UNIQUE KEY uq_sch_profile_name (profile_name),
  UNIQUE KEY uq_sch_profile_short (short_name),
  KEY idx_sch_profile_active_deleted (is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- detailed timing profiles (School-level Days & Periods)

CREATE TABLE IF NOT EXISTS tt_timing_profile (
  timing_profile_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  profile_code      VARCHAR(50)  NOT NULL UNIQUE,  -- e.g., SUMMER_STD_8P
  name              VARCHAR(200) NOT NULL,         -- e.g., Summer Standard (8 periods)
  total_periods     INT UNSIGNED NOT NULL,         -- teaching periods per day
  timezone          VARCHAR(64)  NULL,             -- keep if you run multi-timezone; else leave NULL
  notes             VARCHAR(500) NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted    TINYINT(1) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    TIMESTAMP  NULL,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_class_group (
  class_group_id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id          INT UNSIGNED NOT NULL,              -- FK to tt_school
  class_label     VARCHAR(10)  NOT NULL,              -- Like "8th, VIII"
  subject_id      INT UNSIGNED NOT NULL,              -- FK to tt_subject
  erp_class_id    INT UNSIGNED NOT NULL,              -- optional pointer to our PrimeAi
  short_name      VARCHAR(20) NULL,                   -- Like "9-MATH"
  description     VARCHAR(50) NULL,
  is_major        TINYINT(1)   NOT NULL DEFAULT 1,    -- mark majors if you want
  is_active       TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted      TINYINT(1)   NOT NULL DEFAULT 0,
  created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP    NULL,
  CONSTRAINT fk_cg_school  FOREIGN KEY (org_id)     REFERENCES tt_school(org_id)     ON DELETE CASCADE,
  CONSTRAINT fk_cg_subject FOREIGN KEY (subject_id) REFERENCES tt_subject(subject_id) ON DELETE CASCADE,
  UNIQUE KEY uq_cg_class_subject (org_id, class_label, subject_id),      -- one row per (Class, Subject) in a school
  KEY idx_cg_active_deleted (is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_class_subgroup (
  class_subgroup_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            INT UNSIGNED NOT NULL,            -- FK to tt_school
  class_group_id    INT UNSIGNED NOT NULL,            -- FK to tt_class_group
  section_label     VARCHAR(10)  NOT NULL,            -- e.g., "A", "B"
  short_name        VARCHAR(20) NULL,                 -- e.g., "9-A MATH"
  erp_section_id    INT UNSIGNED NULL,             -- Reference to our PrimeAi
  strength          INT UNSIGNED NULL,                -- headcount for this section in THIS subject
  is_active         TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted        TINYINT(1)   NOT NULL DEFAULT 0,
  created_at        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at        TIMESTAMP    NULL,
  CONSTRAINT fk_csg_school FOREIGN KEY (org_id)         REFERENCES tt_school(org_id)        ON DELETE CASCADE,
  CONSTRAINT fk_csg_cg     FOREIGN KEY (class_group_id) REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  UNIQUE KEY uq_csg_section (class_group_id, section_label),  -- Prevent duplicates of the same section under a (Class, Subject)
  KEY idx_csg_cg (org_id, class_group_id),
  KEY idx_csg_active_deleted (is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- To assign Class Teacher to each Class + Section
CREATE TABLE IF NOT EXISTS tt_class_teacher (
  class_teacher_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id           INT UNSIGNED NOT NULL,
  teacher_id       INT UNSIGNED NOT NULL,
  class_label      VARCHAR(10)  NOT NULL,        -- e.g., "VIII"
  section_label    VARCHAR(10)  NOT NULL,        -- e.g., "A"
  erp_class_id     INT UNSIGNED NULL,
  erp_section_id   INT UNSIGNED NULL,
  role             ENUM('CLASS_TEACHER','CO_CLASS_TEACHER','ASSISTANT') NOT NULL DEFAULT 'CLASS_TEACHER',
  is_primary       TINYINT(1) NOT NULL DEFAULT 1,   -- mark the main class teacher when multiple roles exist
  effective_from   DATE NOT NULL,
  effective_to     DATE NULL,                       -- NULL = open-ended
  is_active        TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted       TINYINT(1) NOT NULL DEFAULT 0,
  created_at       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP  NULL,
  CONSTRAINT fk_ct_school  FOREIGN KEY (org_id)     REFERENCES tt_school(org_id)        ON DELETE CASCADE,
  CONSTRAINT fk_ct_teacher FOREIGN KEY (teacher_id) REFERENCES tt_teacher(teacher_id)   ON DELETE CASCADE,
  UNIQUE KEY uq_ct_unique (org_id, teacher_id, class_label, section_label, role, effective_from),
  KEY idx_ct_section (org_id, class_label, section_label, is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_days (
  day_id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id  INT UNSIGNED NOT NULL,
  label   VARCHAR(30) NOT NULL,
  ordinal INT UNSIGNED NOT NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  TIMESTAMP  NULL,
  CONSTRAINT fk_days_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_days_org_ord (org_id, ordinal),
  UNIQUE KEY uq_days_org_label (org_id, label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_periods (
  period_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id    INT UNSIGNED NOT NULL,
  label     VARCHAR(30) NOT NULL,
  ordinal   INT UNSIGNED NOT NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  TIMESTAMP  NULL,
  CONSTRAINT fk_periods_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_periods_org_ord (org_id, ordinal),
  UNIQUE KEY uq_periods_org_label (org_id, label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_room_unavailable (
  unavail_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id     INT UNSIGNED NOT NULL,
  room_id    INT UNSIGNED NOT NULL, -- FK to tt_days
  day_id     INT UNSIGNED NULL,  -- FK to tt_days
  period_id  INT UNSIGNED NULL,  -- FK to tt_periods
  date_from  DATE NULL,
  date_to    DATE NULL,
  reason     VARCHAR(200) NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP  NULL,
  CONSTRAINT fk_ru_room FOREIGN KEY (room_id) REFERENCES tt_room(room_id) ON DELETE CASCADE,
  CONSTRAINT fk_ru_day    FOREIGN KEY (day_id)    REFERENCES tt_days(day_id)     ON DELETE CASCADE,
  CONSTRAINT fk_ru_period FOREIGN KEY (period_id) REFERENCES tt_periods(period_id) ON DELETE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_timing_profile_period (
  profile_period_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  timing_profile_id INT UNSIGNED NOT NULL,
  segment_ordinal   INT UNSIGNED NOT NULL,          -- 1..n (Assembly, P1, P2, Break, ...)
  label             VARCHAR(100) NOT NULL,          -- "Assembly", "Period 1", "Break"
  segment_type      ENUM('PERIOD','BREAK','ASSEMBLY','LUNCH','OTHER') NOT NULL DEFAULT 'PERIOD',
  counts_as_period  TINYINT(1) NOT NULL DEFAULT 1,  -- 0 for non-teaching segments
  period_ordinal    INT UNSIGNED NULL,              -- map teaching segments to abstract Period # (1..total_periods)
  start_time        TIME NOT NULL,
  end_time          TIME NOT NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  TIMESTAMP  NULL,
  CONSTRAINT fk_tpp_profile FOREIGN KEY (timing_profile_id)
    REFERENCES tt_timing_profile(timing_profile_id) ON DELETE CASCADE,
  UNIQUE KEY uq_tpp_ord (timing_profile_id, segment_ordinal),
  KEY idx_tpp_period_map (timing_profile_id, period_ordinal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Per-date school calendar (campus Open, Holiday, Event etc.)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_school_calendar (
  calendar_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id      INT UNSIGNED NOT NULL,
  date        DATE NOT NULL,
  status      ENUM('WORKING','HOLIDAY','HALF_DAY','EVENT') NOT NULL DEFAULT 'WORKING',
  remarks     VARCHAR(255) NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP  NULL,
  CONSTRAINT fk_cal_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_calendar (org_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Attach timing profile to (school[, class], date) using class_id normalization
-- This table simply answers: “On 2025-04-01, which profile does School X use?”
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_calendar_profile_map (
  map_id             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id             INT UNSIGNED NOT NULL,
  date               DATE NOT NULL,
  timing_profile_id  INT UNSIGNED NOT NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  TIMESTAMP  NULL,
  CONSTRAINT fk_cpm_school   FOREIGN KEY (org_id)      REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_cpm_calendar FOREIGN KEY (org_id, date) REFERENCES tt_school_calendar (org_id, date) ON DELETE CASCADE, -- Strong link to calendar row without storing calendar_id:
  CONSTRAINT fk_cpm_profile  FOREIGN KEY (timing_profile_id) REFERENCES tt_timing_profile(timing_profile_id) ON DELETE RESTRICT,
  UNIQUE KEY uq_cpm (org_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Teacher weekly/date availability
-- --------------------------------
CREATE TABLE IF NOT EXISTS tt_teacher_unavailable (
  unavail_id     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id         INT UNSIGNED NOT NULL,
  teacher_id     INT UNSIGNED NOT NULL,
  -- Weekly pattern (optional)
  day_id         INT UNSIGNED NULL,    -- FK tt_days
  period_id      INT UNSIGNED NULL,    -- FK tt_periods
  -- Date range (optional)
  date_from      DATE NULL,
  date_to        DATE NULL,
  reason         VARCHAR(200) NULL,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted     TINYINT(1) NOT NULL DEFAULT 0,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at     TIMESTAMP NULL,
  CONSTRAINT fk_tu_school  FOREIGN KEY (org_id)     REFERENCES tt_school(org_id)    ON DELETE CASCADE,
  CONSTRAINT fk_tu_teacher FOREIGN KEY (teacher_id) REFERENCES tt_teacher(teacher_id) ON DELETE CASCADE,
  CONSTRAINT fk_tu_day     FOREIGN KEY (day_id)     REFERENCES tt_days(day_id)      ON DELETE CASCADE,
  CONSTRAINT fk_tu_period  FOREIGN KEY (period_id)  REFERENCES tt_periods(period_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- TTeacher assignment (who actually teaches which Class+Subject sections)
-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_teacher_assignment (
  assignment_id     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            INT UNSIGNED NOT NULL,
  teacher_id        INT UNSIGNED NOT NULL,
  subject_id        INT UNSIGNED NOT NULL,
  format_id         INT UNSIGNED NULL,     -- Lecture/Lab/Prac, optional
  class_group_id    INT UNSIGNED NULL,     -- Assign across ALL sections of a class+subject (group), or to one section (subgroup)
  class_subgroup_id INT UNSIGNED NULL,
  priority          ENUM('PRIMARY','SECONDARY') NOT NULL DEFAULT 'PRIMARY',
  effective_from    DATE NULL,
  effective_to      DATE NULL,
  notes             VARCHAR(200) NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted        TINYINT(1) NOT NULL DEFAULT 0,
  created_at        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at        TIMESTAMP  NULL,
  CONSTRAINT fk_ta_school  FOREIGN KEY (org_id)            REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_ta_teacher FOREIGN KEY (teacher_id)        REFERENCES tt_teacher(teacher_id) ON DELETE CASCADE,
  CONSTRAINT fk_ta_subject FOREIGN KEY (subject_id)        REFERENCES tt_subject(subject_id) ON DELETE CASCADE,
  CONSTRAINT fk_ta_format  FOREIGN KEY (format_id)         REFERENCES tt_study_format(format_id) ON DELETE SET NULL,
  CONSTRAINT fk_ta_cg      FOREIGN KEY (class_group_id)    REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  CONSTRAINT fk_ta_csg     FOREIGN KEY (class_subgroup_id) REFERENCES tt_class_subgroup(class_subgroup_id) ON DELETE CASCADE,
-- Exactly one target must be set
  CONSTRAINT chk_ta_target_one CHECK (
    (class_group_id IS NOT NULL AND class_subgroup_id IS NULL) OR
    (class_group_id IS NULL AND class_subgroup_id IS NOT NULL)
  ),
-- Avoid duplicates for the same plan
  UNIQUE KEY uq_ta (org_id, teacher_id, subject_id, IFNULL(format_id,0),
                    IFNULL(class_group_id,0), IFNULL(class_subgroup_id,0), priority),
  KEY idx_ta_lookup (org_id, subject_id, class_group_id, class_subgroup_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Class+Subject requirements (what to place each week)
-- ----------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_class_group_requirement (
  req_id            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            INT UNSIGNED NOT NULL,
  class_group_id    INT UNSIGNED NOT NULL,       -- Class+Subject anchor
  format_id         INT UNSIGNED NULL,           -- optional split by format
  weekly_periods    INT UNSIGNED NOT NULL,          -- how many teaching periods per week
  max_per_day       TINYINT UNSIGNED NULL,          -- e.g., Math ≤ 1/day
  min_gap_periods   TINYINT UNSIGNED NULL,          -- spread rule
  allow_consecutive TINYINT(1) NOT NULL DEFAULT 0,  -- labs may be double
  must_first_or_last ENUM('NONE','FIRST','LAST','FIRST_OR_LAST') NOT NULL DEFAULT 'NONE',
  notes             VARCHAR(200) NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted        TINYINT(1) NOT NULL DEFAULT 0,
  created_at        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at        TIMESTAMP  NULL,
  CONSTRAINT fk_cgr_school FOREIGN KEY (org_id)         REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_cgr_cg     FOREIGN KEY (class_group_id) REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  CONSTRAINT fk_cgr_fmt    FOREIGN KEY (format_id)      REFERENCES tt_study_format(format_id) ON DELETE SET NULL,
  UNIQUE KEY uq_cgr (class_group_id, IFNULL(format_id,0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Timetable Generation runs (versioning and reproducibility)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_generation_run (
  run_id        INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id        INT UNSIGNED NOT NULL,
  session_id    INT UNSIGNED NULL,     -- academic session
  started_at    DATETIME NOT NULL,
  finished_at   DATETIME NULL,
  status        ENUM('RUNNING','SUCCESS','FAILED','CANCELLED') NOT NULL DEFAULT 'RUNNING',
  algorithm     VARCHAR(50) NULL DEFAULT 'heuristic',
  params_json   JSON NULL,                -- seed/weights/toggles
  stats_json    JSON NULL,                -- placements, score, etc.
  created_by    VARCHAR(100) NULL,
  is_active     TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted    TINYINT(1) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    TIMESTAMP  NULL,
  CONSTRAINT fk_gr_school  FOREIGN KEY (org_id)     REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_gr_session FOREIGN KEY (session_id) REFERENCES tt_academic_session(session_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Timetable cells (the actual schedule, with support for combined sections and co-teaching)
-- -----------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_timetable_cell (
  cell_id           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            INT UNSIGNED NOT NULL,
  run_id            INT UNSIGNED NULL,         -- which generation produced it (NULL if manually inserted)
  date              DATE NOT NULL,                -- respects tt_school_calendar
  timing_profile_id INT UNSIGNED NOT NULL,     -- Time profile schedule in use that day
  segment_ordinal   INT UNSIGNED NOT NULL,        -- which segment in the profile (Period 1..n, Break etc.)
  period_ordinal    INT UNSIGNED NULL,            -- abstract period number (for teaching segments)
  class_group_id    INT UNSIGNED NOT NULL,     -- Class+Subject anchor
  subject_id        INT UNSIGNED NOT NULL,
  format_id         INT UNSIGNED NULL,
  room_id           INT UNSIGNED NULL,         -- NULL until roomed
  locked            TINYINT(1) NOT NULL DEFAULT 0,  -- manual lock
  source            ENUM('AUTO','MANUAL','ADJUST') NOT NULL DEFAULT 'AUTO',
  notes             VARCHAR(200) NULL,
  is_active         TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted        TINYINT(1) NOT NULL DEFAULT 0,
  created_at        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at        TIMESTAMP  NULL,
  CONSTRAINT fk_tc_school   FOREIGN KEY (org_id)            REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_tc_run      FOREIGN KEY (run_id)            REFERENCES tt_generation_run(run_id) ON DELETE SET NULL,
  CONSTRAINT fk_tc_profile  FOREIGN KEY (timing_profile_id) REFERENCES tt_timing_profile(timing_profile_id) ON DELETE RESTRICT,
  CONSTRAINT fk_tc_cg       FOREIGN KEY (class_group_id)    REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  CONSTRAINT fk_tc_subject  FOREIGN KEY (subject_id)        REFERENCES tt_subject(subject_id) ON DELETE CASCADE,
  CONSTRAINT fk_tc_format   FOREIGN KEY (format_id)         REFERENCES tt_study_format(format_id) ON DELETE SET NULL,
  CONSTRAINT fk_tc_room     FOREIGN KEY (room_id)           REFERENCES tt_room(room_id) ON DELETE SET NULL,
  KEY idx_tc_dayseg (org_id, date, segment_ordinal),
  KEY idx_tc_cg     (org_id, class_group_id),
  KEY idx_tc_room   (org_id, room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- which sections are participating in a cell (supports A+B combined or separate)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_timetable_cell_subgroup (
  cell_id           INT UNSIGNED NOT NULL,
  class_subgroup_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (cell_id, class_subgroup_id),
  CONSTRAINT fk_tcs_cell FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE,
  CONSTRAINT fk_tcs_csg  FOREIGN KEY (class_subgroup_id) REFERENCES tt_class_subgroup(class_subgroup_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- which teacher(s) are delivering (supports co-teach and substitutions)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_timetable_cell_teacher (
  cell_id     INT UNSIGNED NOT NULL,
  teacher_id  INT UNSIGNED NOT NULL,
  role        ENUM('LEAD','CO_TEACH','SUBSTITUTE') NOT NULL DEFAULT 'LEAD',
  PRIMARY KEY (cell_id, teacher_id),
  CONSTRAINT fk_tct_cell    FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE,
  CONSTRAINT fk_tct_teacher FOREIGN KEY (teacher_id) REFERENCES tt_teacher(teacher_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Substitution log (optional but very useful)
-- -------------------------------------------
CREATE TABLE IF NOT EXISTS tt_substitution_log (
  sub_id                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id                INT UNSIGNED NOT NULL,
  cell_id               INT UNSIGNED NOT NULL,
  absent_teacher_id     INT UNSIGNED NOT NULL,
  substitute_teacher_id INT UNSIGNED NOT NULL,
  decided_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reason                VARCHAR(200) NULL,
  is_active             TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted            TINYINT(1) NOT NULL DEFAULT 0,
  created_at            TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at            TIMESTAMP  NULL,
  CONSTRAINT fk_sl_school  FOREIGN KEY (org_id)                REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_sl_cell    FOREIGN KEY (cell_id)               REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE,
  CONSTRAINT fk_sl_absent  FOREIGN KEY (absent_teacher_id)     REFERENCES tt_teacher(teacher_id) ON DELETE CASCADE,
  CONSTRAINT fk_sl_sub     FOREIGN KEY (substitute_teacher_id) REFERENCES tt_teacher(teacher_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



