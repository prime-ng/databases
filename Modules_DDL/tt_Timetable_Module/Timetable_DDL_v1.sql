Timetable_DDL

/* ====================================================================================
   Integrated Timetable Module — MASTER DDL
   ------------------------------------------------------------------------------------
   Notes:
   - All tables prefixed with tt_
   - Minimal audit columns (is_active, is_deleted, created_at, updated_at, deleted_at)
   - Sensible UNIQUEs and FKs
   - No org_id for GLOBAL Masters ; i.e tt_country, tt_state etc.
   ==================================================================================== */

SET NAMES utf8mb4;

-- =================================
-- Global Masters without Org ID
-- =================================

CREATE TABLE IF NOT EXISTS tt_academic_session (
  session_id      INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  session         VARCHAR(20)  NOT NULL,  -- e.g., 2025-26
  erp_sessions_id int UNSIGNED NULL,
  start_date      DATE         NOT NULL,
  end_date        DATE         NOT NULL,
  is_current      TINYINT(1)   NOT NULL DEFAULT 0,
  is_deleted      TINYINT(1)   NOT NULL DEFAULT 0,
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP    NULL,
  UNIQUE KEY uq_session (session),
  KEY idx_session_current_deleted (is_current, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_country (
  country_id       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name             VARCHAR(50) NOT NULL,
  short_name       VARCHAR(10)  NULL,
  isd_code         VARCHAR(8)   NULL,
  currency_code    VARCHAR(8)   NULL,
  default_timezone VARCHAR(64)  NULL,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted       TINYINT(1)   NOT NULL DEFAULT 0,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP    NULL,
  UNIQUE KEY uq_country_name (name),
  KEY idx_country_active_deleted (is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_state (
  state_id         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  country_id       INT UNSIGNED NOT NULL,
  name             VARCHAR(50) NOT NULL,
  short_name       VARCHAR(10)  NULL,
  global_code      VARCHAR(10)  NULL, -- IN-WB, IN-WB
  default_timezone VARCHAR(64)  NULL,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted       TINYINT(1)   NOT NULL DEFAULT 0,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP    NULL,
  CONSTRAINT fk_state_country FOREIGN KEY (country_id) REFERENCES tt_country(country_id) ON DELETE CASCADE,
  UNIQUE KEY uq_state_country_name (country_id, name),
  KEY idx_state_active_deleted (is_active, is_deleted),
  KEY idx_state_global_code (global_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_district (
  district_id      INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  state_id         INT UNSIGNED NOT NULL,
  name             VARCHAR(50) NOT NULL,
  short_name       VARCHAR(10)  NULL,
  global_code      VARCHAR(10)  NULL,
  default_timezone VARCHAR(64)  NULL,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted       TINYINT(1)   NOT NULL DEFAULT 0,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP    NULL,
  CONSTRAINT fk_district_state FOREIGN KEY (state_id) REFERENCES tt_state(state_id) ON DELETE CASCADE,
  UNIQUE KEY uq_district_state_name (state_id, name),
  KEY idx_district_active_deleted (is_active, is_deleted),
  KEY idx_district_global_code (global_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_city (
  city_id          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  district_id      INT UNSIGNED NOT NULL,
  state_id         INT UNSIGNED NOT NULL,
  name             VARCHAR(50) NOT NULL,
  short_name       VARCHAR(10)  NULL,
  global_code      VARCHAR(10)  NULL,
  default_timezone VARCHAR(64)  NULL,
  is_active        TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted       TINYINT(1)   NOT NULL DEFAULT 0,
  created_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP    NULL,
  CONSTRAINT fk_city_district FOREIGN KEY (state_id) REFERENCES tt_district(district_id) ON DELETE SET NULL,
  CONSTRAINT fk_city_state FOREIGN KEY (state_id) REFERENCES tt_state(state_id) ON DELETE SET NULL,
  UNIQUE KEY uq_city_state_name (state_id, name),
  KEY idx_city_active_deleted (is_active, is_deleted),
  KEY idx_city_global_code (global_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_board (
  board_id   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name       VARCHAR(50) NOT NULL,
  short_name VARCHAR(10)  NULL,
  is_active  TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted TINYINT(1)   NOT NULL DEFAULT 0,
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP    NULL,
  UNIQUE KEY uq_board_name (name),
  UNIQUE KEY uq_board_short (short_name),
  KEY idx_board_active_deleted (is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- ============================================================
-- Organization specific Tables alligned with school.org_id)
-- School Table which will provide Org Id
-- ============================================================

CREATE TABLE IF NOT EXISTS tt_school (
  org_id             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  school_name        VARCHAR(100) NOT NULL,
  short_name         VARCHAR(20)  NULL,
  udise_code         VARCHAR(30)  NULL,
  affiliation_no     VARCHAR(60)  NULL,
  email              VARCHAR(100) NULL,
  website_url        VARCHAR(150) NULL,
  address_line1      VARCHAR(200) NULL,
  address_line2      VARCHAR(200) NULL,
  phone1             VARCHAR(20)  NULL,
  phone2             VARCHAR(20)  NULL,
  whatsapp_number    VARCHAR(20)  NULL,
  area               VARCHAR(100) NULL,
  city_id            INT UNSIGNED NULL,
  district_id        INT UNSIGNED NULL,
  state_id           INT UNSIGNED NULL,
  country_id         INT UNSIGNED NULL,
  pincode            VARCHAR(10)  NULL,
  longitude          DECIMAL(10,7) NULL,
  latitude           DECIMAL(10,7) NULL,
  timezone           VARCHAR(64)  NULL,
  current_session_id INT UNSIGNED NULL,
  school_logo        VARCHAR(255) NULL,
  start_date         DATE         NULL,
  is_active          TINYINT(1)   NOT NULL DEFAULT 1,
  is_deleted         TINYINT(1)   NOT NULL DEFAULT 0,
  created_at         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at         TIMESTAMP    NULL,
  CONSTRAINT fk_school_group   FOREIGN KEY (school_group_id)   REFERENCES tt_school_group(sch_group_id) ON DELETE SET NULL,
  CONSTRAINT fk_school_city    FOREIGN KEY (city_id)           REFERENCES tt_City(city_id)             ON DELETE SET NULL,
  CONSTRAINT fk_school_district FOREIGN KEY (district_id)      REFERENCES tt_District(district_id)     ON DELETE SET NULL,
  CONSTRAINT fk_school_state   FOREIGN KEY (state_id)          REFERENCES tt_State(state_id)           ON DELETE SET NULL,
  CONSTRAINT fk_school_country FOREIGN KEY (country_id)        REFERENCES tt_Country(country_id)       ON DELETE SET NULL,
  CONSTRAINT fk_school_session FOREIGN KEY (current_session_id) REFERENCES tt_academic_session(session_id) ON DELETE SET NULL,
  UNIQUE KEY uq_school_udise        (udise_code),
  UNIQUE KEY uq_school_affiliation  (affiliation_no),
  UNIQUE KEY uq_school_name_group   (school_group_id, school_name),
  KEY idx_school_active_deleted (is_active, is_deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_subject (
  subject_id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id      INT UNSIGNED NOT NULL,
  code        VARCHAR(10) NOT NULL,
  name        VARCHAR(50) NOT NULL,
  major_minor ENUM('MAJOR','MINOR','OPTIONAL') NOT NULL DEFAULT 'MAJOR',
  preferred_weekly_frequency TINYINT UNSIGNED NULL,
  is_active  TINYINT(1)   NOT NULL DEFAULT 1,  -- (0-INACTIVE, 1-ACTIVE)
  is_deleted TINYINT(1)   NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP    NULL,
  CONSTRAINT fk_subject_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE SET NULL,
  UNIQUE KEY uq_subject_org_code (org_id, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_study_format (
  format_id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id     INT UNSIGNED NOT NULL,
  code       VARCHAR(10) NOT NULL,   -- e.g., LEC/LAB/PRAC/ACT
  name       VARCHAR(50) NOT NULL,
  is_active  TINYINT(1)   NOT NULL DEFAULT 1,  -- (0-INACTIVE, 1-ACTIVE)
  is_deleted TINYINT(1)   NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP    NULL,
  CONSTRAINT fk_format_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE SET NULL,
  UNIQUE KEY uq_format_org_code (org_id, code)
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
  erp_section_id    BIGINT UNSIGNED NULL,             -- Reference to our PrimeAi
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

CREATE TABLE IF NOT EXISTS tt_teacher (
  teacher_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id     INT UNSIGNED NOT NULL,
  emp_code   VARCHAR(20)  NULL,
  name       VARCHAR(50) NOT NULL,
  email      VARCHAR(100) NULL,
  phone      VARCHAR(20)  NULL,
  status     ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
  max_periods_per_week INT UNSIGNED NULL,       -- Workload caps
  max_periods_per_day  TINYINT UNSIGNED NULL,   -- Workload caps
  max_days_per_week    TINYINT UNSIGNED NULL,   -- Workload caps
  joining_date DATE NOT NULL,                   -- Can not assign prior to this date
  notes      VARCHAR(200) NULL,
  is_active  TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP  NULL,
  CONSTRAINT fk_teacher_school FOREIGN KEY (org_id)
    REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_teacher_org_code (org_id, emp_code),
  KEY idx_teacher_active_deleted (is_active, is_deleted)
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

-- Who can teach what (Primery & Secondary)
CREATE TABLE IF NOT EXISTS tt_teacher_subject_scope (
  scope_id        INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id          INT UNSIGNED NOT NULL,            -- FK to tt_school
  teacher_id      INT UNSIGNED NOT NULL,            -- FK to tt_teacher
  subject_id      INT UNSIGNED NOT NULL,            -- FK to tt_subject
  format_id       INT UNSIGNED NULL,                -- FK to tt_study_format (Lecture/Lab/Prac…), optional
  priority        ENUM('PRIMARY','SECONDARY') NOT NULL DEFAULT 'PRIMARY',
  proficiency     TINYINT UNSIGNED NULL,               -- 1..5 (1-Low & 5-High)
  notes           VARCHAR(200) NULL,
  effective_from  DATE NULL,
  effective_to    DATE NULL,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted      TINYINT(1) NOT NULL DEFAULT 0,
  created_at      TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP  NULL,
  CONSTRAINT fk_tsss_school  FOREIGN KEY (org_id)     REFERENCES tt_school(org_id)          ON DELETE CASCADE,
  CONSTRAINT fk_tsss_teacher FOREIGN KEY (teacher_id) REFERENCES tt_teacher(teacher_id)     ON DELETE CASCADE,
  CONSTRAINT fk_tsss_subject FOREIGN KEY (subject_id) REFERENCES tt_subject(subject_id)     ON DELETE CASCADE,
  CONSTRAINT fk_tsss_format  FOREIGN KEY (format_id)  REFERENCES tt_study_format(format_id) ON DELETE SET NULL,  
  format_id_norm BIGINT UNSIGNED GENERATED ALWAYS AS (COALESCE(format_id, 0)) STORED,  -- Normalize NULL for uniqueness (so “any format” can’t be duplicated)
  UNIQUE KEY uq_tsss (org_id, teacher_id, subject_id, format_id_norm),                 -- One row per (teacher, subject[, format]) — change `priority` by UPDATE
  KEY idx_tsss_teacher (org_id, teacher_id, is_active, is_deleted),
  KEY idx_tsss_subject (org_id, subject_id, priority),
  KEY idx_tsss_effect  (effective_from, effective_to)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Facilities (Buildings / Rooms) scoped to school
-- ============================================================

CREATE TABLE IF NOT EXISTS tt_building (
  building_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id      INT UNSIGNED NOT NULL,
  name        VARCHAR(100) NOT NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at      TIMESTAMP  NULL,
  CONSTRAINT fk_building_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_building_name (org_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tt_room (
  room_id     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id      INT UNSIGNED NOT NULL,
  building_id INT UNSIGNED NOT NULL,
  name        VARCHAR(50) NOT NULL,
  capacity    INT UNSIGNED NULL,                  -- Made it Not NULL
  max_limit   INT UNSIGNED NULL,                  -- *************** New Field **************
  is_lab      TINYINT(1) NOT NULL DEFAULT 0,
  resource_tags VARCHAR(200) NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at  TIMESTAMP  NULL,
  CONSTRAINT fk_room_building FOREIGN KEY (building_id) REFERENCES tt_building(building_id) ON DELETE CASCADE,
  UNIQUE KEY uq_room_name (building_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Calendar & Timing (now scoped to school)
-- ============================================================

CREATE TABLE IF NOT EXISTS tt_days (
  day_id  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
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
  period_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id    BIGINT UNSIGNED NOT NULL,
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


-- detailed timing profiles (School-level Days & Periods)

CREATE TABLE IF NOT EXISTS tt_timing_profile (
  timing_profile_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
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

CREATE TABLE IF NOT EXISTS tt_timing_profile_period (
  profile_period_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  timing_profile_id BIGINT UNSIGNED NOT NULL,
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
  calendar_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id      BIGINT UNSIGNED NOT NULL,
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
  map_id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id             BIGINT UNSIGNED NOT NULL,
  date               DATE NOT NULL,
  timing_profile_id  BIGINT UNSIGNED NOT NULL,
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
  unavail_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id         INT UNSIGNED NOT NULL,
  teacher_id     INT UNSIGNED NOT NULL,
  -- Weekly pattern (optional)
  day_id         BIGINT UNSIGNED NULL,    -- FK tt_days
  period_id      BIGINT UNSIGNED NULL,    -- FK tt_periods
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
  assignment_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            BIGINT UNSIGNED NOT NULL,
  teacher_id        BIGINT UNSIGNED NOT NULL,
  subject_id        BIGINT UNSIGNED NOT NULL,
  format_id         BIGINT UNSIGNED NULL,     -- Lecture/Lab/Prac, optional
  class_group_id    BIGINT UNSIGNED NULL,     -- Assign across ALL sections of a class+subject (group), or to one section (subgroup)
  class_subgroup_id BIGINT UNSIGNED NULL,
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
  req_id            BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            BIGINT UNSIGNED NOT NULL,
  class_group_id    BIGINT UNSIGNED NOT NULL,       -- Class+Subject anchor
  format_id         BIGINT UNSIGNED NULL,           -- optional split by format
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
  run_id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id        BIGINT UNSIGNED NOT NULL,
  session_id    BIGINT UNSIGNED NULL,     -- academic session
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
  cell_id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id            BIGINT UNSIGNED NOT NULL,
  run_id            BIGINT UNSIGNED NULL,         -- which generation produced it (NULL if manually inserted)
  date              DATE NOT NULL,                -- respects tt_school_calendar
  timing_profile_id BIGINT UNSIGNED NOT NULL,     -- Time profile schedule in use that day
  segment_ordinal   INT UNSIGNED NOT NULL,        -- which segment in the profile (Period 1..n, Break etc.)
  period_ordinal    INT UNSIGNED NULL,            -- abstract period number (for teaching segments)
  class_group_id    BIGINT UNSIGNED NOT NULL,     -- Class+Subject anchor
  subject_id        BIGINT UNSIGNED NOT NULL,
  format_id         BIGINT UNSIGNED NULL,
  room_id           BIGINT UNSIGNED NULL,         -- NULL until roomed
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
  cell_id           BIGINT UNSIGNED NOT NULL,
  class_subgroup_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (cell_id, class_subgroup_id),
  CONSTRAINT fk_tcs_cell FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE,
  CONSTRAINT fk_tcs_csg  FOREIGN KEY (class_subgroup_id) REFERENCES tt_class_subgroup(class_subgroup_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- which teacher(s) are delivering (supports co-teach and substitutions)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tt_timetable_cell_teacher (
  cell_id     BIGINT UNSIGNED NOT NULL,
  teacher_id  INT UNSIGNED NOT NULL,
  role        ENUM('LEAD','CO_TEACH','SUBSTITUTE') NOT NULL DEFAULT 'LEAD',
  PRIMARY KEY (cell_id, teacher_id),
  CONSTRAINT fk_tct_cell    FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE,
  CONSTRAINT fk_tct_teacher FOREIGN KEY (teacher_id) REFERENCES tt_teacher(teacher_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Substitution log (optional but very useful)
-- -------------------------------------------
CREATE TABLE IF NOT EXISTS tt_substitution_log (
  sub_id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id                BIGINT UNSIGNED NOT NULL,
  cell_id               BIGINT UNSIGNED NOT NULL,
  absent_teacher_id     BIGINT UNSIGNED NOT NULL,
  substitute_teacher_id BIGINT UNSIGNED NOT NULL,
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



