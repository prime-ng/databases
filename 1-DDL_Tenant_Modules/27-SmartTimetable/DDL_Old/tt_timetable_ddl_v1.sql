-- timetable_ddl_clean.sql
-- Timetable Module - Clean canonical DDL (MySQL 8, Laravel-ready)
-- PURPOSE: Create the core timetable tables, constraints, and seed lookups.

/*
TABLE: tt_school
Purpose: Lightweight reference to organization/school already in ERP (if not, create)
Key Fields: org_id PK
Relationship: referenced by most tt_* tables
Growth: low cardinality (one row per tenant)
*/
-- CREATE TABLE IF NOT EXISTS tt_school (
--   org_id INT UNSIGNED PRIMARY KEY,
--   name VARCHAR(255) NOT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


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


-- TIMING & CALENDAR
CREATE TABLE IF NOT EXISTS tt_days (
  day_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  label VARCHAR(30) NOT NULL,
  ordinal INT UNSIGNED NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_days_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_days_org_ord (org_id, ordinal),
  UNIQUE KEY uq_days_org_label (org_id, label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tt_periods (
  period_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  label VARCHAR(50) NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  ordinal INT UNSIGNED NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_periods_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_periods_org_ord (org_id, ordinal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tt_timing_profile (
  timing_profile_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  days_json JSON NOT NULL, -- {"day_ordinals":[1,2,3..],"period_map":[{"segment_ordinal":1,"period_id":11},...]}
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tp_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tt_room_unavailable (
  unavail_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  room_id INT UNSIGNED NOT NULL,
  day_id INT UNSIGNED NULL,
  period_id INT UNSIGNED NULL,
  date_from DATE NULL,
  date_to DATE NULL,
  reason VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_ru_room FOREIGN KEY (room_id) REFERENCES tt_room(room_id) ON DELETE CASCADE,
  CONSTRAINT fk_ru_day FOREIGN KEY (day_id) REFERENCES tt_days(day_id) ON DELETE SET NULL,
  CONSTRAINT fk_ru_period FOREIGN KEY (period_id) REFERENCES tt_periods(period_id) ON DELETE SET NULL,
  KEY idx_ru_room (room_id, date_from, date_to)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- SUBJECTS / FORMATS / TAGS (use existing sch_subjects where possible)
CREATE TABLE IF NOT EXISTS tt_study_format (
  format_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_fmt_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_fmt_org_code (org_id, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tt_activity_tag (
  tag_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tag_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  UNIQUE KEY uq_tag_org_name(org_id,name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- CLASS GROUPS & SUBGROUPS
CREATE TABLE IF NOT EXISTS tt_class_group (
  class_group_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  class_id INT UNSIGNED NOT NULL,   -- FK to sch_classes.id
  subject_id INT UNSIGNED NOT NULL, -- FK to sch_subjects.id
  default_format_id INT UNSIGNED NULL,
  notes VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cg_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tt_class_subgroup (
  class_subgroup_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  class_group_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  student_count INT UNSIGNED DEFAULT NULL,
  CONSTRAINT fk_csg_cg FOREIGN KEY (class_group_id) REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  UNIQUE KEY uq_csg_cg_name (class_group_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- CLASS GROUP REQUIREMENTS (weekly requirements)
CREATE TABLE IF NOT EXISTS tt_class_group_requirement (
  req_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  class_group_id INT UNSIGNED NOT NULL,
  format_id INT UNSIGNED NULL,
  weekly_periods INT UNSIGNED NOT NULL,
  max_per_day TINYINT UNSIGNED NULL,
  min_gap_periods TINYINT UNSIGNED NULL,
  allow_consecutive TINYINT(1) NOT NULL DEFAULT 0,
  must_first_or_last ENUM('NONE','FIRST','LAST','FIRST_OR_LAST') NOT NULL DEFAULT 'NONE',
  notes VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_cgr_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_cgr_cg FOREIGN KEY (class_group_id) REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  CONSTRAINT fk_cgr_fmt FOREIGN KEY (format_id) REFERENCES tt_study_format(format_id) ON DELETE SET NULL,
  UNIQUE KEY uq_cgr (class_group_id, IFNULL(format_id,0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- GENERATION RUNS (versioning)
CREATE TABLE IF NOT EXISTS tt_generation_run (
  run_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  session_id INT UNSIGNED NULL, -- fk to academic session in ERP
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  status ENUM('RUNNING','SUCCESS','FAILED','CANCELLED') NOT NULL DEFAULT 'RUNNING',
  algorithm VARCHAR(50) NULL DEFAULT 'heuristic',
  params_json JSON NULL,
  stats_json JSON NULL,
  created_by INT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_gr_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- TIMETABLE CELLS (placements)
CREATE TABLE IF NOT EXISTS tt_timetable_cell (
  cell_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  run_id INT UNSIGNED NULL,
  date DATE NOT NULL,
  timing_profile_id INT UNSIGNED NOT NULL,
  segment_ordinal INT UNSIGNED NOT NULL,
  period_ordinal INT UNSIGNED NULL,
  class_group_id INT UNSIGNED NOT NULL,
  subject_id INT UNSIGNED NOT NULL,
  format_id INT UNSIGNED NULL,
  room_id INT UNSIGNED NULL,
  locked TINYINT(1) NOT NULL DEFAULT 0,
  source ENUM('AUTO','MANUAL','ADJUST') NOT NULL DEFAULT 'AUTO',
  notes VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_tc_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_tc_run FOREIGN KEY (run_id) REFERENCES tt_generation_run(run_id) ON DELETE SET NULL,
  CONSTRAINT fk_tc_profile FOREIGN KEY (timing_profile_id) REFERENCES tt_timing_profile(timing_profile_id) ON DELETE RESTRICT,
  CONSTRAINT fk_tc_cg FOREIGN KEY (class_group_id) REFERENCES tt_class_group(class_group_id) ON DELETE CASCADE,
  KEY idx_tc_dayseg (org_id, date, segment_ordinal),
  KEY idx_tc_cg (org_id, class_group_id),
  KEY idx_tc_room (org_id, room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- which subgroups are participating in a cell (supports A+B combined or separate)
CREATE TABLE IF NOT EXISTS tt_timetable_cell_subgroup (
  cell_id INT UNSIGNED NOT NULL,
  class_subgroup_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (cell_id, class_subgroup_id),
  CONSTRAINT fk_tcs_cell FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE,
  CONSTRAINT fk_tcs_csg FOREIGN KEY (class_subgroup_id) REFERENCES tt_class_subgroup(class_subgroup_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- teacher participation
CREATE TABLE IF NOT EXISTS tt_timetable_cell_teacher (
  cell_id INT UNSIGNED NOT NULL,
  teacher_id INT UNSIGNED NOT NULL, -- FK to tt_teacher
  role ENUM('LEAD','CO_TEACH','SUBSTITUTE') NOT NULL DEFAULT 'LEAD',
  PRIMARY KEY (cell_id, teacher_id),
  CONSTRAINT fk_tct_cell FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- substitution log
CREATE TABLE IF NOT EXISTS tt_substitution_log (
  sub_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  cell_id INT UNSIGNED NOT NULL,
  absent_teacher_id INT UNSIGNED NOT NULL,
  substitute_teacher_id INT UNSIGNED NOT NULL,
  decided_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reason VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  CONSTRAINT fk_sl_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE,
  CONSTRAINT fk_sl_cell FOREIGN KEY (cell_id) REFERENCES tt_timetable_cell(cell_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- GENERIC CONSTRAINTS TABLE (flexible)
CREATE TABLE IF NOT EXISTS tt_constraint (
  constraint_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  name VARCHAR(200) NOT NULL,
  target_type ENUM('TEACHER','CLASS_GROUP','ROOM','ACTIVITY','GLOBAL') NOT NULL,
  target_id INT UNSIGNED NULL,
  is_hard TINYINT(1) NOT NULL DEFAULT 0, -- 1 = hard constraint (100%), 0 = soft
  weight INT UNSIGNED NOT NULL DEFAULT 100, -- 0..100
  rule_json JSON NOT NULL, -- expressive rule body
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_c_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- PUBLISH/LOCK metadata
CREATE TABLE IF NOT EXISTS tt_timetable_publish (
  publish_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  org_id INT UNSIGNED NOT NULL,
  run_id INT UNSIGNED NOT NULL,
  published_by INT UNSIGNED NULL,
  published_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  scope ENUM('RUN','DAY','CLASS_GROUP','CUSTOM') NOT NULL DEFAULT 'RUN',
  scope_detail JSON NULL,
  is_locked TINYINT(1) NOT NULL DEFAULT 1,
  notes VARCHAR(255) NULL,
  CONSTRAINT fk_pub_run FOREIGN KEY (run_id) REFERENCES tt_generation_run(run_id) ON DELETE CASCADE,
  CONSTRAINT fk_pub_school FOREIGN KEY (org_id) REFERENCES tt_school(org_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- SEED DATA EXAMPLES (lookup)
INSERT INTO tt_study_format (org_id, code, name) VALUES (1,'LECT','Lecture'),(1,'LAB','Lab'),(1,'TUT','Tutorial')
ON DUPLICATE KEY UPDATE name=VALUES(name);

INSERT INTO tt_activity_tag (org_id, name) VALUES (1,'LECTURE'),(1,'LAB'),(1,'EXAM_PREP')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Index recommendation summary (add indexes on frequently filtered columns)
-- e.g., add composite idx on tt_timetable_cell(org_id, date, class_group_id, subject_id)

