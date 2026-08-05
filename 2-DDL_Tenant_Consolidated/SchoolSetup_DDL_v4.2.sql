-- =====================================================================
-- SCHOOL SETUP MODULE - VERSION 4.0 (PRODUCTION-GRADE) on 01-Jul-2026
-- SUB-MODULE: CLASS SETUP, EMPLOYEE SETUP, INFRA SETUP
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- TABLE PREFIX: sch_ - Class Sub-Module
-- =====================================================================

-- ===========================================================================
-- 1 - CLASS SETUP SUB-MODULE (sch) class_setup v4(Enhanced)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `sch_sections` (
    `id`         int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal`    tinyint unsigned NOT NULL DEFAULT 0,       -- will have sequence order for Sections (Auto Update by Drag & Drop)
    `code`       CHAR(5) NOT NULL,                    -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
    `short_name` varchar(20) NOT NULL,          -- e.g. 'SEC-A' or 'SEC-B' (NEW)
    `name`       varchar(50) NOT NULL,                -- e.g. 'Section - A', 'Section - B'
    `is_active`  tinyint(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sections_name` (`name`),
    UNIQUE KEY `uq_sections_code` (`code`),
    UNIQUE KEY `uq_sections_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Classes, Sections, Subjects, Subject Types, Study Formats, Class-Section Junctions, Subject-StudyFormat Junctions, Class Groups, Subject Groups
  CREATE TABLE IF NOT EXISTS `sch_classes` (
    `id`         int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal`    tinyint NOT NULL DEFAULT 0,             -- will have sequence order (Auto Update by Drag & Drop)
    `code`       CHAR(5) NOT NULL,                    -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NOT NULL,      -- e.g. 'G1' or '10th', '11th', '12th'
    `name`       varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th', 'Class - 12th'
    `is_active`  tinyint(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classes_code` (`code`),
    UNIQUE KEY `uq_classes_shortName` (`short_name`),
    UNIQUE KEY `uq_classes_name` (`name`),
    UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NOT NULL DEFAULT 0,                        -- will have sequence order  (Added new) (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,                      -- FK to sch_classes
    `section_id` int unsigned NOT NULL,                    -- FK to sch_sections
    `code` char(10) NOT NULL,                              -- Combination of class Code + section Code i.e. '8th_A', '10h_B' (Changed from class_secton_code)
    `name` varchar(50) NOT NULL,                           -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th Section - A', 'Class - 12th Section - B' (Added new)
    `capacity` tinyint unsigned DEFAULT NULL,              -- Targeted / Planned Quantity of stundets in Each Sections of every class.
    `actual_total_student` tinyint unsigned DEFAULT NULL,  -- Actual Number of Student in the Class+Section (changed from total_student)
    `min_required_student` tinyint unsigned DEFAULT NULL,  -- Minimum Number of Student required to start a class+section (Added new)
    `max_allowed_student` tinyint unsigned DEFAULT NULL,   -- Maximum Number of Student allowed in a class+section (Added new)
    `class_teacher_id` INT unsigned NOT NULL,              -- FK to sch_users
    `assistance_class_teacher_id` INT unsigned NOT NULL,   -- FK to sch_users
    `rooms_type_id` int unsigned NOT NULL,                 -- FK to 'sch_rooms_type' (Added new)
    `class_house_room_id` int unsigned NOT NULL,           -- FK to 'sch_rooms' (Added new)
    `total_periods_daily` tinyint unsigned DEFAULT NULL,   -- Total Number of Periods in a day for this class+section (Added new)
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classSection_ordinal` (`ordinal`),
    UNIQUE KEY `uq_classSection_code` (`code`),
    UNIQUE KEY `uq_classSection_name` (`name`),
    UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
    CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_classSection_classTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_classSection_assistanceClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_classSection_roomsTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_classSection_classHouseRoomeId` FOREIGN KEY (`class_house_roome_id`) REFERENCES `sch_rooms` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- Soft Delete is not available in this Table, instead we wil use `is_active` Column.
  -- If ser triy to Create a Section for a Class which is present in Tabel but is_active=0 then it will throw an error.
  --   - and will ask user to Re-activate the Section for the Class, rather creating a new One.

  -- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
  CREATE TABLE IF NOT EXISTS `sch_subject_types` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` char(5) NOT NULL,            -- 'MAJ','MIN','OPT','ACT','SPO'
    `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
    `name` varchar(50) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectTypes_shortName` (`short_name`),
    UNIQUE KEY `uq_subjectTypes_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_study_formats` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,            -- e.g., 'LECT','LAB','PRAC','TUT','SEM','WSH','GRD','OTH'
    `short_name` varchar(20) NOT NULL,  -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
    `name` varchar(50) NOT NULL,        -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
    `is_system` tinyint(1) NOT NULL DEFAULT '0',  -- If (TRUE), System defined subjects, which can not be deleted or edited. (Added new)
    `is_active` tinyint(1) NOT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_studyFormats_shortName` (`short_name`),
    UNIQUE KEY `uq_studyFormats_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- 1. Must have a Record with `is_system` = 1, `code` = 'FREE', `short_name` = 'FREE PERIOD', and `name` = 'FREE PERIOD'.
  --    - This will be used as default study format in case no Subject_StduyFormat assign for that period.
  --    - Example - Class 2nd has 32 weekly Periods, School days-6 days. So, 2nd need to have 6 Periods daily but now Total Periods in 6days will be 36.
  --    - So we will assign 32 periods within 36 available periods, and balance 4 periods will be shown as (Subject='FREE PERIOD', StudyFormat="FREE".

  CREATE TABLE IF NOT EXISTS `sch_subjects` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,            -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
    `short_name` varchar(20) NOT NULL,  -- e.g. 'SCIENCE','MATH','SST','ENGLISH' and so on
    `name` varchar(50) NOT NULL,        -- 'SCIENCE','MATH','SST','ENGLISH' and so on
    `is_optional` tinyint(1) NOT NULL DEFAULT '0',  -- Whether this subject is optional for students or compulsory (Added new)
    `is_system` tinyint(1) NOT NULL DEFAULT '0',  -- If (TRUE), System defined subjects, which can not be deleted or edited. (Added new)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjects_shortName` (`short_name`),
    UNIQUE KEY `uq_subjects_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- 1. Must have a Record with `is_system` = 1, `code` = 'FREE', `short_name` = 'FREE PERIOD', and `name` = 'FREE PERIOD'.
  --    - This will be used as default study format in case no Subject_StduyFormat assign for that period.
  --    - Example - Class 2nd has 32 weekly Periods, School days-6 days. So, 2nd need to have 6 Periods daily but now Total Periods in 6days will be 36.
  --    - So we will assign 32 periods within 36 available periods, and balance 4 periods will be shown as (Subject='FREE PERIOD', StudyFormat="FREE".
  -- 2. Brij Check - Whether "is_optional, should be added in this table or not."


  -- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
    -- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
    -- Removed 'short_name' as we can use `sub_stdformat_code`
  CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,               -- will have sequence order (Auto Update by Drag & Drop)
    `subject_id` INT unsigned NOT NULL,           -- FK to 'sch_subjects'
    `study_format_id` int unsigned NOT NULL,      -- FK to 'sch_study_formats'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(30) NOT NULL,                     -- e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (Changed from 'subject_studyformat_code')
    `name` varchar(50) NOT NULL,                  -- e.g., 'Science Lecture','Science Lab','Math Lecture','Math Lab' and so on
    `require_class_house_room` TINYINT(1) NOT NULL DEFAULT 0, -- Whether Class House Room is required for this Class Group
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_rooms_type.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional)
    `has_multiple_options` tinyint(1) NOT NULL DEFAULT '0',  -- Whether this subject has multiple options for students (e.g. Computer Science, Physical Education, Fine Arts etc.) (Added new)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subStudyFormat_code` (`code`),
    UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`,`subject_type_id`),
    CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- Addedd - `has_multiple_options` to capture whether this Subject_StudyFormat has multiple options for students 
  -- Subject:Games, StudyFormat:Activity, Has multiple options for students (e.g. Football, Basketball, Volleyball etc.)

  -- 'sch_subject_study_format_options' is grouping for different subjects under same group (Games - Football, Basketball, Volleyball etc.) and will be used for TimeTable. It is also used to define whether specific room type is required for this subject-study format combination.
  CREATE TABLE IF NOT EXISTS `sch_subject_study_format_options` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_study_format_id` int unsigned NOT NULL,          -- FK to 'sch_subject_study_format_jnt'
    `subject_studyformat_option_code` varchar(20) NOT NULL,   -- e.g. 'Football', 'Basketball', 'Volleyball' etc.
    `subject_studyformat_option_name` varchar(50) NOT NULL,   -- e.g. 'Football', 'Basketball', 'Volleyball' etc.
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectOptions_subjectStudyFormatOptionCode` (`subject_studyformat_option_code`),
    UNIQUE KEY `uq_subjectOptions_subjectStudyFormatId_subjectStudyFormatOptionName` (`subject_study_format_id`,`subject_studyformat_option_name`),
    CONSTRAINT `fk_subjectOptions_subjectStudyFormatId` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 
  -- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `class_id` int unsigned NOT NULL,             -- FK to 'sch_classes'
    `section_id` int unsigned NULL,           -- FK to 'sch_sections' (Optional) If Null then will be applicable to all thr sections
    `subject_Study_format_id` INT unsigned NOT NULL,  -- FK to 'sch_subject_study_format_jnt'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(50) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `name` varchar(100) NOT NULL,                 -- 10th-A Science Lacture Major
    -- Information for Timetable Module
    `is_compulsory` tinyint(1) NOT NULL DEFAULT '0',       -- Is this Subject compulsory for Student or Optional
    `required_weekly_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1,   -- Total periods required per week for this Class Group (Class+{Section}+Subject+StudyFormat)
    `min_weekly_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Minimum periods required per week for this Class Group
    `max_weekly_periods` TINYINT UNSIGNED DEFAULT NULL,    -- Maximum periods required per week for this Class Group
    `min_daily_periods` TINYINT UNSIGNED DEFAULT NULL,     -- Minimum periods per day for this Class Group
    `max_daily_periods` TINYINT UNSIGNED DEFAULT NULL,     -- Maximum periods per day for this Class Group
    `min_gap_between_periods` TINYINT UNSIGNED DEFAULT NULL,       -- Minimum gap periods for this Class Group
    `allow_consecutive_periods` TINYINT(1) NOT NULL DEFAULT 0,     -- Whether consecutive periods are allowed for this Class Group
    `max_consecutive_periods` TINYINT UNSIGNED NOT NULL DEFAULT 1, -- Maximum consecutive periods
    `priority_score` SMALLINT UNSIGNED NOT NULL DEFAULT 10,        -- Priority of this requirement on 1-100 scale 
    --
    `require_class_house_room` TINYINT(1) NOT NULL DEFAULT 0, -- Whether Class House Room is required for this Class Group
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_rooms_type.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional)
    -- Audit Fields
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`), 
    UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`),
    CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`),
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`),
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`),
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`),
    CONSTRAINT `fk_classGroups_roomId` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`),
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.
  -- if 'required_room_type' is House Room, then 'required_room_id' will be ignored.



  -- Table 'sch_subject_groups' will be used to assign all subjects to the students
  CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `class_id` int UNSIGNED NOT NULL,   -- FK to 'sch_classes'
    `section_id` int UNSIGNED NULL,     -- FK (Section can be null if Group will be used for all sectons) (Optional)
    `code` CHAR(20) NOT NULL,           -- Combination of (Class+{Section}+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,  -- 7th Science, 7th Commerce, 7th-A Science etc.
    `name` varchar(100) NOT NULL,       -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
    `registered_students_count` int NOT NULL DEFAULT 0, -- Total registered students in this group
    `default_group_for_class` tinyint(1) NOT NULL DEFAULT 0, -- Whether this group is default for the class
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectGroups_code` (`code`),
    UNIQUE KEY `uq_subjectGroups_shortName` (`short_name`),
    UNIQUE KEY `uq_subjectGroups_name` (`class_id`,`name`),
    CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.

  CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_id` INT unsigned NOT NULL,              -- FK to 'sch_subject_groups'
    `class_group_id` INT unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
    `subject_id` int unsigned NOT NULL,                    -- FK to 'sch_subjects' (De-Normalization)
    `subject_study_format_id` INT unsigned NOT NULL,       -- FK to 'sch_subject_study_format_jnt'
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjGrpSubj_subjGrpId_classGroup` (`subject_group_id`,`class_group_id`),
    CONSTRAINT `fk_subjGrpSubj_subjectGroup` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_classGroup` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectStudyFormatId` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Add new Field for Timetable -
  -- is_compulsory, min_periods_per_week, max_periods_per_week, max_per_day, min_per_day, min_gap_periods, allow_consecutive, max_consecutive, priority, compulsory_room_type


-- ===========================================================================
-- 2 - EMPLOYEE SETUP SUB-MODULE (sch)
-- ===========================================================================

  -- ===========================================================================
  -- 2.1 : LEAVE CONFIGURATION TABLES
  -- ===========================================================================
  -- we need to create a table to annual session for leave which will start from Jan and will end in Dec. This table will be used to link the leave with the annual session and also to calculate the leave balance for the employees. This table will be linked with the sch_employee_leave_balance table and sch_employee_leave_applications table.
    CREATE TABLE IF NOT EXISTS `sch_annual_leave_sessions` (
      `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
      `name`                  VARCHAR(100) NOT NULL,  -- e.g. "2024 Calendar Year", "2024-25 Academic Year"
      `start_date`            DATE NOT NULL,
      `end_date`              DATE NOT NULL,
      `description`           VARCHAR(255) DEFAULT NULL,
      `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
      `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at`            TIMESTAMP NULL,
      UNIQUE KEY `uq_session_name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    COMMENT='Defines annual sessions for leave tracking (e.g., calendar year, academic year).';

    CREATE TABLE IF NOT EXISTS `sch_staff_attendance_types` (
      `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
      `code`                  VARCHAR(10) NOT NULL,  -- e.g. 'PR', 'AB', 'LV', 'LT', 'HD'
      `name`                  VARCHAR(100) NOT NULL,  -- e.g. 'Present', 'Absent', 'Leave', 'Late', 'Holiday'
      `category`              ENUM('Attendance','Leave','Holiday','Other') NOT NULL DEFAULT 'Attendance',  -- Grouping for reports
      `is_present`            TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Absent, 1: Present (core logic flag)
      `can_be_half_day`       TINYINT(1) NOT NULL DEFAULT 0,  -- 1: Allows half-day marking (e.g., Late, Leave)
      `affects_payroll`       TINYINT(1) NOT NULL DEFAULT 1,  -- 1: Counts toward payroll calculation, 0: Excluded (e.g., Holiday)
      `payroll_percentage`    DECIMAL(5,2) NOT NULL DEFAULT 100.00,  -- % of daily pay (100.00 = full, 50.00 = half, 0.00 = none)
      `requires_approval`     TINYINT(1) NOT NULL DEFAULT 0,  -- 1: Requires supervisor approval (e.g., Absent, Late)
      `color_hex`             VARCHAR(7) DEFAULT NULL,  -- #FF5733 for calendar/UI display
      `icon_class`            VARCHAR(50) DEFAULT NULL,  -- CSS class for icon (e.g., 'fas fa-check', 'fas fa-times')
      `display_order`         INT NOT NULL DEFAULT 0,
      `is_system`             TINYINT(1) NOT NULL DEFAULT 0,  -- 1: Built-in, cannot be deleted/modified by users
      `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
      `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      `deleted_at`            TIMESTAMP NULL,
      UNIQUE KEY `uq_attendance_code` (`code`),
      INDEX `idx_attendance_active` (`is_active`, `deleted_at`),
      INDEX `idx_attendance_category` (`category`, `is_active`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------------------------
  -- sch_holidays   (NEW in v4)
  -- ---------------------------------------------------------------------------
  -- School holiday calendar. Used by leave-day-counting (skip holidays in the
  -- "total_days" calculation) and attendance (mark is_holiday=1).
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_holidays` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    --`academic_session_id`   INT UNSIGNED NOT NULL,
    `annual_leave_sessions_id`   INT UNSIGNED NOT NULL,   -- FK to sch_annual_leave_sessions.id
    `holiday_date`          DATE         NOT NULL,
    `name`                  VARCHAR(150) NOT NULL,
    `description`           VARCHAR(500) DEFAULT NULL,
    `holiday_type`          ENUM('Public','Religious','Optional','School_Specific','Sunday','Saturday','Vacation','Other') NOT NULL DEFAULT 'Public',
    `is_optional`           TINYINT(1)   NOT NULL DEFAULT 0  COMMENT 'Optional holidays — employee chooses from a list',
    `is_paid`               TINYINT(1)   NOT NULL DEFAULT 1,  -- 0: Unpaid holiday (e.g., optional), 1: Paid holiday (e.g., public)
    `applies_to_role_id`    INT UNSIGNED DEFAULT NULL,   -- FK to sch_employee_roles.id; NULL means applies to all roles,
    `applies_to_department_id` INT UNSIGNED DEFAULT NULL,   -- FK to sch_departments.id; NULL means applies to all departments
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_hol_session_date` (`annual_leave_sessions_id`, `holiday_date`),
    KEY `idx_hol_date`         (`holiday_date`),
    CONSTRAINT `fk_hol_session`    FOREIGN KEY (`annual_leave_sessions_id`)   REFERENCES `sch_annual_leave_sessions` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hol_role`       FOREIGN KEY (`applies_to_role_id`)    REFERENCES `sch_employee_roles` (`id`)            ON DELETE SET NULL,
    CONSTRAINT `fk_hol_department` FOREIGN KEY (`applies_to_department_id`) REFERENCES `sch_departments` (`id`)            ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='School holiday calendar (public, religious, optional, school-specific).';

  -- ---------------------------------------------------------------------------
  -- sch_employee_shifts   (NEW in v4)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_shifts` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(20)  NOT NULL,
    `name`                  VARCHAR(100) NOT NULL,
    `start_time`            TIME NOT NULL,
    `end_time`              TIME NOT NULL,
    `break_duration_minutes` SMALLINT UNSIGNED NOT NULL DEFAULT 0,  -- e.g., 60 for a 1-hour lunch break; used to calculate net working hours
    `working_hours`         DECIMAL(4,2) NOT NULL  COMMENT 'Net working hours (excluding break)',
    `grace_minutes_late`    SMALLINT UNSIGNED NOT NULL DEFAULT 10  COMMENT 'Late beyond this triggers half-day mark',
    `grace_minutes_early`   SMALLINT UNSIGNED NOT NULL DEFAULT 10  COMMENT 'Leaving early beyond this triggers half-day mark',
    `half_day_threshold_minutes` SMALLINT UNSIGNED DEFAULT 240  COMMENT 'Below this many present minutes = half-day',
    `applies_to_days`       JSON         DEFAULT NULL  COMMENT '[Mon, Tue, …] — null = all days',
    `is_default`            TINYINT(1)   NOT NULL DEFAULT 0,
    `description`           VARCHAR(255) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_shift_code` (`code`),
    KEY `idx_shift_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Shift master — start/end times, grace, half-day thresholds.';
  -- Conditions:
  -- `half_day_threshold_minutes`- If present minutes < threshold → half-day (If `working_hours_present_min < half_day_threshold_minutes` → `Half Day`)

  -- ---------------------------------------------------------------------------
  -- sch_employee_shift_assignments   Employee × shift × effective range.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_shift_assignments` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `shift_id`              INT UNSIGNED NOT NULL,
    `effective_from`        DATE         NOT NULL,
    `effective_to`          DATE         DEFAULT NULL,
    `assignment_reason`     VARCHAR(255) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `active_flag`           TINYINT(1) GENERATED ALWAYS AS (CASE WHEN (`is_active` = 1 AND `deleted_at` IS NULL) THEN 1 ELSE NULL END) STORED,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_employee_shift_active` (`employee_id`, `active_flag`)  COMMENT 'Only one active shift per employee at a time',
    KEY `idx_esa_shift` (`shift_id`),
    CONSTRAINT `fk_esa_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`)        ON DELETE CASCADE,
    CONSTRAINT `fk_esa_shift`    FOREIGN KEY (`shift_id`)    REFERENCES `sch_employee_shifts` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee shift assignment with effective range.';


  -- ===========================================================================
  -- 2.2 : LEAVE CONFIGURATION TABLES
  -- ===========================================================================

  -- sch_staff_leave_types   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  -- Master list of leave categories. Referenced by sch_leave_approval_policies,
  -- sch_employee_leave_applications, sch_employee_leave_balance, and
  -- sch_staff_leave_config.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_staff_leave_types` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code`                  VARCHAR(20)  NOT NULL  COMMENT 'CL, SL, EL, ML, PL, COMP, LWP, HALF',
    `name`                  VARCHAR(100) NOT NULL  COMMENT 'Casual Leave, Sick Leave, Earned Leave, …',
    `description`           VARCHAR(500) DEFAULT NULL,
    -- Behavior flags
    `is_paid`               TINYINT(1)   NOT NULL DEFAULT 1   COMMENT '0: Unpaid Leave, 1: Paid Leave',
    `is_carry_forwardable`  TINYINT(1)   NOT NULL DEFAULT 0,  -- Can unused leave be carried forward to next year
    `max_carry_forward`     DECIMAL(5,2) DEFAULT NULL,         -- 'Max days that can be carried forward; NULL means no limit',
    `is_encashable`         TINYINT(1)   NOT NULL DEFAULT 0   COMMENT 'Can be paid out at year-end',
    `is_encashable_at_separation` TINYINT(1) NOT NULL DEFAULT 0, -- 'Can this leave type be encashed at separation (resignation/retirement)?',
    `max_encashable_days`         DECIMAL(5,2) DEFAULT NULL,     -- 'Max days that can be encashed at separation; NULL means no limit',
    `requires_doc`          TINYINT(1)   NOT NULL DEFAULT 0   COMMENT 'e.g., medical cert for Sick Leave',
    `min_doc_required_days` TINYINT UNSIGNED DEFAULT NULL     COMMENT 'Doc only required if leave > N days',
    `requires_substitute`   TINYINT(1)   NOT NULL DEFAULT 0   COMMENT 'For teachers — auto-create sub flow',
    `allows_half_day`       TINYINT(1)   NOT NULL DEFAULT 1,  -- 0: No Approval Required, 1: Approval Required
    `allows_back_dated`     TINYINT(1)   NOT NULL DEFAULT 0   COMMENT 'For Sick Leave / emergency',
    `requires_approval`     TINYINT(1) NOT NULL DEFAULT 1,  -- 0: No Approval Required, 1: Approval Required
    -- Constraints
    `min_days_per_application` DECIMAL(4,1) NOT NULL DEFAULT 0.5,  -- 'Min days that can be applied for in a single application',
    `max_days_per_application` DECIMAL(4,1) DEFAULT NULL,          -- NULL means no limit; e.g., for Maternity Leave, max might be 90 days
    `min_advance_notice_days`  TINYINT UNSIGNED DEFAULT 0     COMMENT 'Must apply N days in advance',
    `max_consecutive_days`     TINYINT UNSIGNED DEFAULT NULL,  -- 'Max consecutive days allowed; NULL means no limit',
    -- Display
    `display_order`         TINYINT UNSIGNED DEFAULT 100,
    `color_hex`             VARCHAR(7)   DEFAULT NULL  COMMENT 'For calendar UI: #FF5733',
    `is_system`             TINYINT(1)   NOT NULL DEFAULT 0   COMMENT '1 = built-in, cannot be deleted by user',
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_lt_code`   (`code`),
    KEY `idx_lt_active`       (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Master list of leave types (CL, SL, EL, ML, PL, LWP, etc.).';

  -- ---------------------------------------------------------------------------
  -- sch_staff_leave_config   (NEW in v4)
  -- ---------------------------------------------------------------------------
  -- Per-(role × leave_type) entitlement: opening balance, max carry forward,
  -- accrual schedule. Used at year-rollover to seed sch_employee_leave_balance.
  -- POLICY MATCHING (role / department / designation):
  --   • Most-specific match wins; otherwise the catch-all (all-NULL) row applies.
  --   • This mirrors sch_leave_approval_policies semantics.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_staff_leave_config` (
    `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `leave_type_id`             INT UNSIGNED NOT NULL,           -- FK to sch_staff_leave_types
    `applies_to_role_id`        INT UNSIGNED DEFAULT NULL,   -- FK to sch_employee_roles; NULL means applies to all roles
    `applies_to_department_id`  INT UNSIGNED DEFAULT NULL,   -- FK to sch_departments; NULL means applies to all departments
    `applies_to_designation_id` INT UNSIGNED DEFAULT NULL,   -- FK to sch_designations; NULL means applies to all designations
    `applies_to_employment_type` ENUM('Permanent','Contract','Temporary','Visiting','Intern','Probation') DEFAULT NULL,
    -- Entitlement
    `annual_entitlement`        DECIMAL(5,2) NOT NULL DEFAULT 0.00  COMMENT 'Days granted per academic year',
    `accrual_method`            ENUM('Lump_Sum','Monthly_Pro_Rata','Quarterly') NOT NULL DEFAULT 'Lump_Sum',
    `accrual_start_offset_months` TINYINT UNSIGNED DEFAULT 0    COMMENT 'Wait N months from joining before accrual starts',
    -- Carry forward
    `is_carry_forwardable`        TINYINT(1)   NOT NULL DEFAULT 0,   -- 'Can unused leave be carried forward to next year',
    `max_carry_forward`           DECIMAL(5,2) DEFAULT NULL,         -- 'Max days that can be carried forward; NULL means no limit',
    -- Encashment
    `is_encashable_at_separation` TINYINT(1) NOT NULL DEFAULT 0, -- 'Can this leave type be encashed at separation (resignation/retirement)?',
    `max_encashable_days`         DECIMAL(5,2) DEFAULT NULL,     -- 'Max days that can be encashed at separation; NULL means no limit',
    -- Probation behavior
    `available_during_probation` TINYINT(1) NOT NULL DEFAULT 0,      -- 0: No leave during probation, 1: Leave available during probation
    `probation_entitlement_pro_rata` TINYINT(1) NOT NULL DEFAULT 1,  -- 0: No pro-rata during probation, 1: Pro-rata based on probation duration
    -- Tie-breaker (mirrors sch_leave_approval_policies pattern)
    `priority`              TINYINT UNSIGNED NOT NULL DEFAULT 10,    -- Lower number = higher priority. Evaluated when multiple rows match an employee.
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_lc_lookup` (`leave_type_id`, `applies_to_role_id`, `applies_to_department_id`, `applies_to_designation_id`, `is_active`),
    CONSTRAINT `fk_lc_leave_type`  FOREIGN KEY (`leave_type_id`)            REFERENCES `sch_staff_leave_types` (`id`)        ON DELETE CASCADE,
    CONSTRAINT `fk_lc_role`        FOREIGN KEY (`applies_to_role_id`)        REFERENCES `sch_employee_roles` (`id`)    ON DELETE SET NULL,
    CONSTRAINT `fk_lc_department`  FOREIGN KEY (`applies_to_department_id`)  REFERENCES `sch_departments` (`id`)       ON DELETE SET NULL,
    CONSTRAINT `fk_lc_designation` FOREIGN KEY (`applies_to_designation_id`) REFERENCES `sch_designations` (`id`)      ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Leave entitlement config — drives year-rollover and accrual.';

  -- ---------------------------------------------------------------------------
  -- sch_leave_approval_policies   (v3 retained)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_approval_policies` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                  VARCHAR(150) NOT NULL,
    `description`           VARCHAR(500) DEFAULT NULL,
    `applies_to_role_id`        INT UNSIGNED DEFAULT NULL,
    `applies_to_department_id`  INT UNSIGNED DEFAULT NULL,
    `applies_to_designation_id` INT UNSIGNED DEFAULT NULL,
    `applies_to_leave_type_id`  INT UNSIGNED DEFAULT NULL,
    `priority`              TINYINT UNSIGNED NOT NULL DEFAULT 10,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_lap_role`        (`applies_to_role_id`),
    INDEX `idx_lap_department`  (`applies_to_department_id`),
    INDEX `idx_lap_designation` (`applies_to_designation_id`),
    INDEX `idx_lap_leave_type`  (`applies_to_leave_type_id`),
    INDEX `idx_lap_active`      (`is_active`),
    CONSTRAINT `fk_lap_role`        FOREIGN KEY (`applies_to_role_id`)        REFERENCES `sch_employee_roles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lap_department`  FOREIGN KEY (`applies_to_department_id`)  REFERENCES `sch_departments` (`id`)    ON DELETE SET NULL,
    CONSTRAINT `fk_lap_designation` FOREIGN KEY (`applies_to_designation_id`) REFERENCES `sch_designations` (`id`)  ON DELETE SET NULL,
    CONSTRAINT `fk_lap_leave_type`  FOREIGN KEY (`applies_to_leave_type_id`)  REFERENCES `sch_staff_leave_types` (`id`)   ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Approval policy master — matches employee context to an approval pipeline';

  -- ---------------------------------------------------------------------------
  -- sch_leave_approval_policy_levels   (v3 retained)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_approval_policy_levels` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `policy_id`             INT UNSIGNED NOT NULL,         -- FK to sch_leave_approval_policies.id
    `level_number`          TINYINT UNSIGNED NOT NULL,     -- 1 for first level, 2 for second, etc. (enforced unique per policy)
    `level_name`            VARCHAR(100) NOT NULL,         -- e.g., "Reporting Manager", "Department Head", "HR", "Principal"
    `approval_mode`         ENUM('ANY_ONE', 'ALL') NOT NULL DEFAULT 'ANY_ONE',  -- ANY_ONE = any one of the approvers at this level can approve; ALL = all approvers must approve
    `escalation_after_hours` SMALLINT UNSIGNED DEFAULT NULL,  -- If not approved within this many hours, automatically escalate to next level (NULL means no escalation)
    `notify_applicant_on_escalation` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether to notify the applicant when their leave request is escalated to the next level
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_policy_level` (`policy_id`, `level_number`),
    INDEX `idx_lapl_policy` (`policy_id`),
    CONSTRAINT `fk_lapl_policy` FOREIGN KEY (`policy_id`) REFERENCES `sch_leave_approval_policies` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ordered approval levels within a policy';

  -- ---------------------------------------------------------------------------
  -- sch_leave_approval_level_approvers   (v3 retained)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_approval_level_approvers` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `level_id`              INT UNSIGNED NOT NULL,   -- FK to sch_leave_approval_policy_levels.id
    `approver_type`         ENUM('USER','ROLE','DESIGNATION','DEPARTMENT_HEAD','REPORTING_TO') NOT NULL,
    `approver_user_id`         INT UNSIGNED DEFAULT NULL,
    `approver_role_id`         INT UNSIGNED DEFAULT NULL,
    `approver_designation_id`  INT UNSIGNED DEFAULT NULL,
    `approver_department_id`   INT UNSIGNED DEFAULT NULL,
    `approver_reporting_to_id` INT UNSIGNED DEFAULT NULL,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_lala_level`       (`level_id`),
    INDEX `idx_lala_user`        (`approver_user_id`),
    INDEX `idx_lala_role`        (`approver_role_id`),
    INDEX `idx_lala_designation` (`approver_designation_id`),
    CONSTRAINT `fk_lala_level`       FOREIGN KEY (`level_id`)              REFERENCES `sch_leave_approval_policy_levels` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lala_user`        FOREIGN KEY (`approver_user_id`)      REFERENCES `sys_users` (`id`)          ON DELETE SET NULL,
    CONSTRAINT `fk_lala_role`        FOREIGN KEY (`approver_role_id`)      REFERENCES `sch_employee_roles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lala_designation` FOREIGN KEY (`approver_designation_id`) REFERENCES `sch_designations` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lala_department`  FOREIGN KEY (`approver_department_id`) REFERENCES `sch_departments` (`id`)  ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Authorised approvers per level';

  -- ---------------------------------------------------------------------------
  -- sch_employee_leave_balance   (v3 retained — name kept for compat)
  -- ---------------------------------------------------------------------------
  -- Note: name should be plural per convention; deferred to v5.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_leave_balance` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `academic_year`         VARCHAR(9)   NOT NULL,
    `leave_type_id`         INT UNSIGNED NOT NULL,
    `opening_balance`       DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    `carry_forward`         DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    `total_used`            DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    `total_pending`         DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    `available_balance`     DECIMAL(5,2) GENERATED ALWAYS AS (opening_balance + carry_forward - total_used) STORED,
    `manual_adjustment`     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    `adjustment_reason`     VARCHAR(255) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_leave_balance` (`employee_id`, `academic_year`, `leave_type_id`),
    INDEX `idx_elb_employee`      (`employee_id`, `academic_year`),
    INDEX `idx_elb_leave_type`    (`leave_type_id`),
    INDEX `idx_elb_active`        (`is_active`),
    CONSTRAINT `fk_elb_employee`   FOREIGN KEY (`employee_id`)  REFERENCES `sch_employees` (`id`)   ON DELETE RESTRICT,
    CONSTRAINT `fk_elb_leave_type` FOREIGN KEY (`leave_type_id`) REFERENCES `sch_staff_leave_types` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Live leave-balance ledger per employee per leave type per academic year';


  -- ===========================================================================
  -- 2.3 : EMPLOYEE CREATION & PROFILE MANAGEMENT
  -- ===========================================================================

  -- ---------------------------------------------------------------------------
  -- sch_employees   (enhanced in v4)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employees` (
    `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`                   INT UNSIGNED NOT NULL              COMMENT 'FK → sys_users.id',
    -- Employee identity (v3)
    `emp_code`                  VARCHAR(20)  NOT NULL,
    `emp_id_card_type`          ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `emp_smart_card_id`         VARCHAR(100) DEFAULT NULL,
  
    -- Personal details (v4 — additive, all nullable so v3 rows still valid)
    `first_name`                VARCHAR(100) DEFAULT NULL          COMMENT 'v4 — kept on sys_users too; mirror here for fast HR queries',
    `middle_name`               VARCHAR(100) DEFAULT NULL          COMMENT 'v4',
    `last_name`                 VARCHAR(100) DEFAULT NULL          COMMENT 'v4',
    `gender`                    ENUM('Male','Female','Other','Prefer Not to Say') DEFAULT NULL COMMENT 'v4',
    `date_of_birth`             DATE         DEFAULT NULL          COMMENT 'v4',
    `marital_status`            ENUM('Single','Married','Divorced','Widowed','Separated') DEFAULT NULL COMMENT 'v4',
    `blood_group`               ENUM('A+','A-','B+','B-','O+','O-','AB+','AB-','Unknown') DEFAULT NULL COMMENT 'v4',
    `nationality`               VARCHAR(50)  DEFAULT 'Indian'      COMMENT 'v4',
    `religion`                  VARCHAR(50)  DEFAULT NULL          COMMENT 'v4',
    `mother_tongue`             VARCHAR(50)  DEFAULT NULL          COMMENT 'v4',
    `photo_media_id`            INT UNSIGNED DEFAULT NULL          COMMENT 'v4 — FK → sys_media.id',
    -- Contact (v4)
    `mobile_number_primary`     VARCHAR(20)  DEFAULT NULL          COMMENT 'v4',
    `mobile_number_alternate`   VARCHAR(20)  DEFAULT NULL          COMMENT 'v4',
    `personal_email`            VARCHAR(150) DEFAULT NULL          COMMENT 'v4',
    `official_email`            VARCHAR(150) DEFAULT NULL          COMMENT 'v4',
    -- Identity numbers (Indian context, v4 — encrypt at app layer)
    `aadhaar_number`            VARCHAR(20)  DEFAULT NULL          COMMENT 'v4 — encrypted at app layer; partial visible in UI',
    `pan_number`                VARCHAR(15)  DEFAULT NULL          COMMENT 'v4',
    `pf_number`                 VARCHAR(30)  DEFAULT NULL          COMMENT 'v4 — Provident Fund',
    `esi_number`                VARCHAR(30)  DEFAULT NULL          COMMENT 'v4 — Employee State Insurance',
    `uan_number`                VARCHAR(20)  DEFAULT NULL          COMMENT 'v4 — Universal Account Number for PF',
  
    -- Employment info (v3)
    `is_teacher`                TINYINT(1)   NOT NULL DEFAULT 0,
    `joining_date`              DATE         NOT NULL,
    `total_experience_years`    DECIMAL(4,1) DEFAULT NULL,
    `highest_qualification`     VARCHAR(100) DEFAULT NULL,
    `specialization`            VARCHAR(150) DEFAULT NULL,
    `last_institution`          VARCHAR(200) DEFAULT NULL,
    `awards`                    TEXT         DEFAULT NULL,
    `skills`                    TEXT         DEFAULT NULL,
    `qualifications_json`       JSON         DEFAULT NULL,
    `certifications_json`       JSON         DEFAULT NULL,
    `experiences_json`          JSON         DEFAULT NULL,
    -- Employment lifecycle (v4)
    `employment_status`         ENUM('Active','On Leave','On Sabbatical','Notice Period','Resigned','Terminated','Retired','Suspended') NOT NULL DEFAULT 'Active' COMMENT 'v4',
    `employment_type`           ENUM('Permanent','Contract','Temporary','Visiting','Intern','Probation') NOT NULL DEFAULT 'Permanent' COMMENT 'v4',
    `confirmation_date`         DATE         DEFAULT NULL          COMMENT 'v4 — date confirmed after probation',
    `probation_end_date`        DATE         DEFAULT NULL          COMMENT 'v4',
    `last_working_date`         DATE         DEFAULT NULL          COMMENT 'v4 — set on resignation / termination',
    `notes`                     TEXT         DEFAULT NULL,
    -- Required audit columns (v4 fixed — added is_active)
    `is_active`                 TINYINT(1)   NOT NULL DEFAULT 1    COMMENT 'v4',
    `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
    UNIQUE KEY `uq_employees_aadhaar`     (`aadhaar_number`)        COMMENT 'v4 — partial uniqueness (NULLs allowed)',
    UNIQUE KEY `uq_employees_pan`         (`pan_number`)            COMMENT 'v4',
    KEY `teachers_user_id_foreign`        (`user_id`),
    KEY `idx_employees_branch`            (`branch_id`)             COMMENT 'v4',
    KEY `idx_employees_is_teacher`        (`is_teacher`)            COMMENT 'v4',
    KEY `idx_employees_employment_status` (`employment_status`)     COMMENT 'v4',
    KEY `idx_employees_joining_date`      (`joining_date`)          COMMENT 'v4',
    KEY `idx_employees_active`            (`is_active`, `deleted_at`) COMMENT 'v4',
    CONSTRAINT `fk_employees_userId` FOREIGN KEY (`user_id`)        REFERENCES `sys_users` (`id`)   ON DELETE CASCADE,
    CONSTRAINT `fk_employees_photo`  FOREIGN KEY (`photo_media_id`) REFERENCES `sys_media` (`id`)   ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee master record. Personal + identity + employment lifecycle (enhanced in v4).';

  -- ---------------------------------------------------------------------------
  -- sch_employees_profile   (enhanced in v4 — fixed UNIQUE
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employees_profile` (
    `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`               INT UNSIGNED NOT NULL,
    `user_id`                   INT UNSIGNED NOT NULL,
    `role_id`                   INT UNSIGNED NOT NULL,
    `department_id`             INT UNSIGNED DEFAULT NULL,
    `specialization_area`       VARCHAR(100) DEFAULT NULL,  -- e.g., for teachers: subject specialization; for admin: HR, Finance, etc.
    `qualification_level`       VARCHAR(50)  DEFAULT NULL,  -- e.g., 'Bachelor', 'Master', 'PhD', 'Diploma'
    `qualification_field`       VARCHAR(100) DEFAULT NULL,  -- e.g., 'Computer Science', 'Business Administration'
    `certifications`            JSON         DEFAULT NULL,  -- e.g., [{"name": "PMP", "issued_by": "PMI", "issue_date": "2020-05-01", "expiry_date": "2023-05-01"}]
    `work_hours_daily`          DECIMAL(4,2) DEFAULT 8.0,   -- Expected daily work hours (e.g., 8.0)
    `max_hours_daily`           DECIMAL(4,2) DEFAULT 10.0,  -- Maximum daily work hours before overtime applies (e.g., 10.0)
    `work_hours_weekly`         DECIMAL(5,2) DEFAULT 40.0,  -- Expected weekly work hours (e.g., 40.0)
    `max_hours_weekly`          DECIMAL(5,2) DEFAULT 50.0,  -- Maximum weekly work hours before overtime applies (e.g., 50.0)
    `preferred_shift`           ENUM('Morning','Evening','Flexible') DEFAULT 'Morning',
    `is_full_time`              TINYINT(1)   DEFAULT 1,     -- 0: Part-time, 1: Full-time
    `core_responsibilities`     JSON         DEFAULT NULL,  -- e.g., [{"type": "Teaching", "description": "Teach Computer Science to grades 9-12"}, {"type": "Admin", "description": "Manage school IT infrastructure"}]
    `technical_skills`          JSON         DEFAULT NULL,  -- e.g., [{"skill": "Python", "proficiency": "Advanced"}, {"skill": "Project Management", "proficiency": "Intermediate"}]
    `soft_skills`               JSON         DEFAULT NULL,  -- e.g., [{"skill": "Communication", "proficiency": "Advanced"}, {"skill": "Teamwork", "proficiency": "Advanced"}]
    `experience_months`         SMALLINT UNSIGNED DEFAULT NULL,  -- e.g., 24 (for 2 years)
    `performance_rating`        TINYINT UNSIGNED  DEFAULT NULL,  -- e.g., 4 (on a scale of 1-5)
    `last_performance_review`   DATE         DEFAULT NULL,       -- Date of last performance review
    `security_clearance_done`   TINYINT(1)   DEFAULT 0,          -- 0: No, 1: Yes
    `reporting_to`              INT UNSIGNED DEFAULT NULL,       -- FK to sch_employees.id; NULL means reports to no one (e.g., top-level admin)
    `can_approve_budget`        TINYINT(1)   DEFAULT 0,       -- 0: No, 1: Yes  
    `can_manage_staff`          TINYINT(1)   DEFAULT 0,     -- 0: No, 1: Yes (e.g., for teachers: can they be a class teacher with student management responsibilities? For admin: can they have direct reports?)
    `can_access_sensitive_data` TINYINT(1)   DEFAULT 0,     -- 0: No, 1: Yes (e.g., salary info, personal details of other employees)
    `assignment_meta`           JSON         DEFAULT NULL,  -- e.g., {"current_projects": ["School Website Redesign", "Annual Day Event"], "past_projects": ["Science Fair 2023", "Math Olympiad 2022"]}
    `notes`                     TEXT         DEFAULT NULL,
    `effective_from`            DATE         DEFAULT NULL,    -- `effective_to` is now unused (v4) but kept for historical/audit purposes; active_flag GENERATED COLUMN enforces "one active per employee_id + role_id"
    `effective_to`              DATE         DEFAULT NULL,    -- `effective_to` is now unused (v4) but kept for historical/audit purposes; active_flag GENERATED COLUMN enforces "one active per employee_id + role_id"
    `is_active`                 TINYINT(1)   NOT NULL DEFAULT 1,
    -- v4 — generated active_flag so the UNIQUE actually enforces "only one active per (employee, role)"
    `active_flag`               TINYINT(1) GENERATED ALWAYS AS (CASE WHEN (`is_active` = 1 AND `deleted_at` IS NULL) THEN 1 ELSE NULL END) STORED,
    `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_employee_role_active` (`employee_id`, `role_id`, `active_flag`)  COMMENT 'v4 — fixed: NULLable active_flag enforces single active row per pair',
    KEY `idx_emp_profile_reporting`     (`reporting_to`),
    KEY `idx_emp_profile_department`    (`department_id`),
    KEY `idx_emp_profile_active`        (`is_active`, `deleted_at`),
    CONSTRAINT `fk_employeeProfile_employeeId`   FOREIGN KEY (`employee_id`)   REFERENCES `sch_employees` (`id`)        ON DELETE CASCADE,
    CONSTRAINT `fk_employeeProfile_userId`       FOREIGN KEY (`user_id`)       REFERENCES `sys_users` (`id`)            ON DELETE RESTRICT,
    CONSTRAINT `fk_employeeProfile_roleId`       FOREIGN KEY (`role_id`)       REFERENCES `sch_employee_roles` (`id`)   ON DELETE RESTRICT,
    CONSTRAINT `fk_employeeProfile_departmentId` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`)      ON DELETE SET NULL,
    CONSTRAINT `fk_employeeProfile_reportingTo`  FOREIGN KEY (`reporting_to`)  REFERENCES `sch_employees` (`id`)        ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Non-teacher employee profile (admin/staff). One active row per (employee, role).';

  -- ---------------------------------------------------------------------------
  -- sch_teacher_profile   (enhanced in v4)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_teacher_profile` (
    `id`                              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`                     INT UNSIGNED NOT NULL,
    `user_id`                         INT UNSIGNED NOT NULL,
    `role_id`                         INT UNSIGNED NOT NULL,
    `department_id`                   INT UNSIGNED NOT NULL,
    `designation_id`                  INT UNSIGNED NOT NULL,
    `teacher_house_room_id`           INT UNSIGNED DEFAULT NULL,
    -- Class teacher assignment (v4)
    `is_class_teacher`                TINYINT(1)   NOT NULL DEFAULT 0  COMMENT 'v4 — denormalized flag for fast filter',
    `class_teacher_of_class_id`       INT UNSIGNED DEFAULT NULL          COMMENT 'v4 — FK → sch_classes.id',
    `class_teacher_of_section_id`     INT UNSIGNED DEFAULT NULL          COMMENT 'v4 — FK → sch_sections.id',
    -- Coloumn from (v3)
    `is_full_time`                    TINYINT(1)   DEFAULT 1,   -- 0: Part-time, 1: Full-time
    `preferred_shift`                 ENUM('Morning','Evening','Flexible') DEFAULT 'Morning',  -- v4 — added Flexible option
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,   -- 0: No, 1: Yes (can this teacher handle multiple classes/sections if needed?)
    `can_be_used_for_substitution`    TINYINT(1)   DEFAULT 1,   -- 0: No, 1: Yes (can this teacher be assigned as a substitute for another teacher's class if needed?)
    `certified_for_lab`               TINYINT(1)   DEFAULT 0,   -- 0: No, 1: Yes (is this teacher certified to handle lab sessions, if applicable?)
    `is_proficient_with_computer`     TINYINT(1)   DEFAULT 0,   -- 0: No, 1: Yes (can this teacher use computer software for teaching or administrative tasks?)
    `can_manage_staff`                TINYINT(1)   DEFAULT 0,   -- 0: No, 1: Yes (can this teacher have administrative responsibilities or manage other staff members?)
    `special_skill_area`              VARCHAR(100) DEFAULT NULL, -- e.g., 'STEM Education', 'Special Needs Education', 'Sports Coaching'
    `soft_skills`                     JSON         DEFAULT NULL, -- e.g., [{"skill": "Communication", "proficiency": "Advanced"}, {"skill": "Classroom Management", "proficiency": "Intermediate"}]
    `assignment_meta`                 JSON         DEFAULT NULL,  -- e.g., {"current_classes": ["10A", "12B"], "past_classes": ["9C", "11A"]}
    `max_available_periods_weekly`    TINYINT UNSIGNED DEFAULT 48,  -- Max periods this teacher can be assigned per week (e.g., 48 for full-time)
    `min_available_periods_weekly`    TINYINT UNSIGNED DEFAULT 36,  -- Min periods this teacher should be assigned per week to be considered full-time (e.g., 36)
    `max_allocated_periods_weekly`    TINYINT UNSIGNED DEFAULT 1,   -- Max periods this teacher should be allocated per week to avoid overloading (e.g., 1 for part-time, or 5 for full-time)
    `min_allocated_periods_weekly`    TINYINT UNSIGNED DEFAULT 1,   -- Min periods this teacher should be allocated per week to ensure they are utilized effectively (e.g., 1 for part-time, or 10 for full-time)
    `can_be_split_across_sections`    TINYINT(1)   DEFAULT 0,       -- 0: No, 1: Yes (can this teacher's assigned class be split across multiple sections if needed?)
    `min_teacher_availability_score`  DECIMAL(7,2) UNSIGNED DEFAULT 1,  -- Minimum availability score (0 to 1) required for this teacher to be considered for allocation; calculated based on their availability and preferences
    `max_teacher_availability_score`  DECIMAL(7,2) UNSIGNED DEFAULT 1,  -- Maximum availability score (0 to 1) for this teacher; can be used to deprioritize teachers with low availability or preferences
    `performance_rating`              TINYINT UNSIGNED DEFAULT NULL,    -- e.g., 4 (on a scale of 1-5)
    `last_performance_review`         DATE         DEFAULT NULL,       -- Date of last performance review
    `security_clearance_done`         TINYINT(1)   DEFAULT 0,          -- 0: No, 1: Yes
    `reporting_to`                    INT UNSIGNED DEFAULT NULL,       -- FK to sch_employees.id; NULL means reports to no one (e.g., top-level admin)
    `can_access_sensitive_data`       TINYINT(1)   DEFAULT 0,          -- 0: No, 1: Yes (e.g., salary info, personal details of other employees)
    `notes`                           TEXT         NULL,
    `effective_from`                  DATE         DEFAULT NULL,
    `effective_to`                    DATE         DEFAULT NULL,     
    `created_at`                      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                      TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_employee` (`employee_id`),
    KEY `idx_teacher_class_teacher`  (`is_class_teacher`, `class_teacher_of_class_id`, `class_teacher_of_section_id`)  COMMENT 'v4',
    KEY `idx_teacher_active`         (`is_active`, `deleted_at`),
    CONSTRAINT `fk_teacher_employee`     FOREIGN KEY (`employee_id`)               REFERENCES `sch_employees` (`id`)          ON DELETE CASCADE,
    CONSTRAINT `fk_teacher_user`         FOREIGN KEY (`user_id`)                   REFERENCES `sys_users` (`id`)              ON DELETE RESTRICT,
    CONSTRAINT `fk_teacher_role`         FOREIGN KEY (`role_id`)                   REFERENCES `sch_employee_roles` (`id`)     ON DELETE RESTRICT,
    CONSTRAINT `fk_teacher_department`   FOREIGN KEY (`department_id`)             REFERENCES `sch_departments` (`id`)        ON DELETE RESTRICT,
    CONSTRAINT `fk_teacher_designation`  FOREIGN KEY (`designation_id`)            REFERENCES `sch_designations` (`id`)       ON DELETE RESTRICT,
    CONSTRAINT `fk_teacher_reporting_to` FOREIGN KEY (`reporting_to`)              REFERENCES `sch_employees` (`id`)          ON DELETE SET NULL,
    CONSTRAINT `fk_teacher_class`        FOREIGN KEY (`class_teacher_of_class_id`) REFERENCES `sch_classes` (`id`)            ON DELETE SET NULL,
    CONSTRAINT `fk_teacher_section`      FOREIGN KEY (`class_teacher_of_section_id`) REFERENCES `sch_sections` (`id`)         ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Teacher-specific profile. One row per teacher.';

  -- ---------------------------------------------------------------------------
  -- sch_teacher_capabilities   (enhanced in v4 — fixed typo, added effective_to)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_teacher_capabilities` (
    `id`                          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `teacher_profile_id`          INT UNSIGNED NOT NULL,
    `class_id`                    INT UNSIGNED NOT NULL,
    `subject_study_format_id`     INT UNSIGNED NOT NULL,
    `proficiency_percentage`      TINYINT UNSIGNED DEFAULT NULL,   -- 0 to 100 indicating how proficient this teacher is in teaching this subject-format; can be used for allocation scoring and prioritization
    `teaching_experience_months`  SMALLINT UNSIGNED DEFAULT NULL,  -- Number of months of experience teaching this subject-format; can be used for allocation scoring and prioritization
    `is_primary_subject`          TINYINT(1)   NOT NULL DEFAULT 1, -- 0: No, 1: Yes (is this subject-format one of the primary ones this teacher should be allocated to if possible?)
    `competency_level`            ENUM('Facilitator','Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic'  COMMENT 'v4 — fixed typo from competancy_level',
    `priority_order`              INT UNSIGNED DEFAULT NULL,       -- Lower number = higher priority for allocation; can be used as a tie-breaker when proficiency and experience are similar
    `priority_weight`             TINYINT UNSIGNED DEFAULT NULL,   -- Weight (0-100) indicating how important it is to allocate this teacher to this subject-format; can be used in allocation scoring to balance teacher preferences and institutional priorities
    `scarcity_index`              TINYINT UNSIGNED DEFAULT NULL,   -- Calculated scarcity index for this subject-format based on the number of teachers available with proficiency in it; can be used to prioritize allocation of teachers to high-scarcity subjects
    `is_hard_constraint`          TINYINT(1)   DEFAULT 0,          -- 0: No, 1: Yes (if true, the allocation engine should treat this capability as a hard constraint and not allocate this teacher to this subject-format if it doesn't meet the proficiency/experience requirements)
    `allocation_strictness`       ENUM('Hard','Medium','Soft') DEFAULT 'Medium',  -- Indicates how strictly the allocation engine should try to meet this capability when allocating this teacher to this subject-format; can be used to allow flexibility in allocations while still prioritizing important capabilities
    `override_priority`           TINYINT UNSIGNED DEFAULT NULL,   -- Manual override for priority order; lower number = higher priority. If set, this takes precedence over calculated priority_order based on proficiency and experience.
    `override_reason`             VARCHAR(255) DEFAULT NULL,       -- Reason for manual override (e.g., "Principal's recommendation", "Recent training in this subject-format", etc.)
    `historical_success_ratio`    TINYINT UNSIGNED DEFAULT NULL,   -- Historical success ratio for this teacher's performance in teaching this subject-format; can be used for allocation scoring and prioritization
    `last_allocation_score`       TINYINT UNSIGNED DEFAULT NULL,   -- Last calculated allocation score for this teacher-subject-format combination based on proficiency, experience, priority weight, scarcity index, and other factors; can be used to track how well this capability is being utilized in allocations
    `effective_from`              DATE         DEFAULT NULL,
    `effective_to`                DATE         DEFAULT NULL          COMMENT 'v4',
    `is_active`                   TINYINT(1)   NOT NULL DEFAULT 1,
    `active_flag`                 TINYINT(1) GENERATED ALWAYS AS (CASE WHEN (`is_active` = 1) THEN 1 ELSE NULL END) STORED,
    `created_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                  TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                  TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_capability` (`teacher_profile_id`, `class_id`, `subject_study_format_id`, `active_flag`),
    KEY `idx_tc_lookup` (`class_id`, `subject_study_format_id`, `is_active`)  COMMENT 'v4 — common solver lookup pattern',
    CONSTRAINT `fk_tc_teacher_profile`      FOREIGN KEY (`teacher_profile_id`)      REFERENCES `sch_teacher_profile` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tc_class`                FOREIGN KEY (`class_id`)                REFERENCES `sch_classes` (`id`)         ON DELETE RESTRICT,
    CONSTRAINT `fk_tc_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Teacher capability matrix: which class × subject_format they can teach, with proficiency / priority.';

  -- ---------------------------------------------------------------------------
  -- sch_employee_addresses   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  -- Multi-row per employee. address_type distinguishes Current / Permanent /
  -- Local Guardian. Same employee can have multiple active addresses.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_addresses` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `address_type`          ENUM('Current','Permanent','Emergency','Local_Address','Other') NOT NULL DEFAULT 'Current',
    `address_line_1`        VARCHAR(200) NOT NULL,
    `address_line_2`        VARCHAR(200) DEFAULT NULL,
    `landmark`              VARCHAR(150) DEFAULT NULL,
    `city`                  VARCHAR(100) NOT NULL,
    `district`              VARCHAR(100) DEFAULT NULL,
    `state`                 VARCHAR(100) NOT NULL,
    `pincode`               VARCHAR(15)  NOT NULL,
    `country`               VARCHAR(50)  NOT NULL DEFAULT 'India',
    `is_same_as_permanent`  TINYINT(1)   NOT NULL DEFAULT 0  COMMENT 'Quick flag for "current = permanent"',
    `is_primary`            TINYINT(1)   NOT NULL DEFAULT 0  COMMENT 'Primary address among multiple of same type',
    `effective_from`        DATE         DEFAULT NULL,
    `effective_to`          DATE         DEFAULT NULL,
    `notes`                 VARCHAR(255) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_ea_employee_type` (`employee_id`, `address_type`),
    KEY `idx_ea_active`        (`is_active`, `deleted_at`),
    CONSTRAINT `fk_ea_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee addresses (current, permanent, emergency, local guardian).';

  -- ---------------------------------------------------------------------------
  -- sch_employee_emergency_contacts   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_emergency_contacts` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `contact_name`          VARCHAR(150) NOT NULL,
    `relation`              VARCHAR(50)  NOT NULL          COMMENT 'Spouse, Father, Mother, Sibling, Friend, Other',
    `mobile_number`         VARCHAR(20)  NOT NULL,
    `alternate_number`      VARCHAR(20)  DEFAULT NULL,
    `email`                 VARCHAR(150) DEFAULT NULL,
    `address`               VARCHAR(500) DEFAULT NULL,
    `is_primary`            TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '1 = call this person FIRST in an emergency',
    `priority_order`        TINYINT UNSIGNED DEFAULT 1       COMMENT 'Order to attempt contact (1 first)',
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_eec_employee` (`employee_id`, `priority_order`),
    CONSTRAINT `fk_eec_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Emergency contact persons per employee.';

  -- ---------------------------------------------------------------------------
  -- sch_employee_bank_details   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  -- For salary credit. Account numbers should be encrypted at the application
  -- layer; partial-mask in UI by default.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_bank_details` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `bank_name`             VARCHAR(150) NOT NULL,
    `branch_name`           VARCHAR(150) DEFAULT NULL,
    `account_holder_name`   VARCHAR(150) NOT NULL,
    `account_number`        VARCHAR(50)  NOT NULL          COMMENT 'Encrypted at app layer',
    `account_type`          ENUM('Savings','Current','Salary','NRE','NRO','Other') NOT NULL DEFAULT 'Savings',
    `ifsc_code`             VARCHAR(20)  NOT NULL,
    `swift_code`            VARCHAR(20)  DEFAULT NULL,
    `iban`                  VARCHAR(40)  DEFAULT NULL      COMMENT 'For overseas wires',
    `is_primary_for_salary` TINYINT(1)   NOT NULL DEFAULT 0,
    `verified_at`           TIMESTAMP NULL DEFAULT NULL,
    `verified_by`           INT UNSIGNED DEFAULT NULL,    -- FK to sys_users.id for who verified this bank detail
    `cancelled_cheque_media_id` INT UNSIGNED DEFAULT NULL  COMMENT 'FK → sys_media.id',
    `notes`                 VARCHAR(255) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_ebd_employee_primary` (`employee_id`, `is_primary_for_salary`),
    CONSTRAINT `fk_ebd_employee` FOREIGN KEY (`employee_id`)             REFERENCES `sch_employees` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ebd_verified` FOREIGN KEY (`verified_by`)              REFERENCES `sys_users` (`id`)     ON DELETE SET NULL,
    CONSTRAINT `fk_ebd_cheque`   FOREIGN KEY (`cancelled_cheque_media_id`) REFERENCES `sys_media` (`id`)    ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee bank account details for salary disbursement.';

  -- ---------------------------------------------------------------------------
  -- sch_employee_documents   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  -- Generic document store: joining letter, ID proof, contract, NDA, training
  -- certificates, salary slips, etc. Spatie-media link (media_id) is the
  -- preferred integration, with file_name kept for legacy convenience.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_documents` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `document_category`     ENUM('ID_Proof','Address_Proof','Educational','Experience','Joining','Contract','NDA','Salary_Slip','Tax','Health','Photo','Other') NOT NULL,
    `document_name`         VARCHAR(150) NOT NULL          COMMENT 'Display: "Aadhaar Card", "Joining Letter 2026"',
    `document_number`       VARCHAR(100) DEFAULT NULL      COMMENT 'For ID proofs: card / cert number',
    `issued_by`             VARCHAR(150) DEFAULT NULL,
    `issued_date`           DATE         DEFAULT NULL,
    `expiry_date`           DATE         DEFAULT NULL      COMMENT 'NULL if non-expiring',
    `media_id`              INT UNSIGNED DEFAULT NULL      COMMENT 'FK → sys_media (Spatie)',
    `file_name`             VARCHAR(255) DEFAULT NULL      COMMENT 'Convenience: stored filename if not using media',
    `is_verified`           TINYINT(1)   NOT NULL DEFAULT 0,
    `verified_at`           TIMESTAMP NULL DEFAULT NULL,
    `verified_by`           INT UNSIGNED DEFAULT NULL,    -- FK to sys_users.id for who verified this document
    `notes`                 VARCHAR(500) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_edoc_employee_category` (`employee_id`, `document_category`),
    KEY `idx_edoc_expiry`            (`expiry_date`)        COMMENT 'For expiry-warning scheduler',
    CONSTRAINT `fk_edoc_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_edoc_media`    FOREIGN KEY (`media_id`)    REFERENCES `sys_media` (`id`)     ON DELETE SET NULL,
    CONSTRAINT `fk_edoc_verified` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`)     ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee documents (ID proof, joining letter, contracts, expiry-tracked credentials).';


  -- ===========================================================================
  -- 2.4 : EMPLOYMENT TRANSFER & PROMOTION (NEW in v4)
  -- ===========================================================================

  -- ---------------------------------------------------------------------------
  -- sch_employee_role_history   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  -- Append-only audit of role / department / designation changes (promotion,
  -- transfer, demotion). One row per change. Keeps the active assignment in
  -- sch_employees_profile / sch_teacher_profile; this table is the trail.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_role_history` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `change_type`           ENUM('Promotion','Demotion','Transfer','Role_Change','Department_Change','Designation_Change','Confirmation','Probation_Extended','Other') NOT NULL,
    -- Snapshot BEFORE the change
    `from_role_id`          INT UNSIGNED DEFAULT NULL,
    `from_department_id`    INT UNSIGNED DEFAULT NULL,
    `from_designation_id`   INT UNSIGNED DEFAULT NULL,
    -- Snapshot AFTER the change
    `to_role_id`            INT UNSIGNED DEFAULT NULL,
    `to_department_id`      INT UNSIGNED DEFAULT NULL,
    `to_designation_id`     INT UNSIGNED DEFAULT NULL,
    -- Effective range
    `effective_from`        DATE         NOT NULL,
    `effective_to`          DATE         DEFAULT NULL  COMMENT 'NULL = current; set when superseded',
    -- Reason / approval
    `reason`                VARCHAR(500) DEFAULT NULL,
    `order_reference`       VARCHAR(100) DEFAULT NULL  COMMENT 'HR order number',
    `approved_by`           INT UNSIGNED DEFAULT NULL,
    `approved_at`           TIMESTAMP NULL DEFAULT NULL,
    `order_media_id`        INT UNSIGNED DEFAULT NULL  COMMENT 'FK → sys_media — scanned order',
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_erh_employee_effective` (`employee_id`, `effective_from`),
    KEY `idx_erh_change_type`        (`change_type`),
    CONSTRAINT `fk_erh_employee`     FOREIGN KEY (`employee_id`)        REFERENCES `sch_employees` (`id`)        ON DELETE CASCADE,
    CONSTRAINT `fk_erh_from_role`    FOREIGN KEY (`from_role_id`)       REFERENCES `sch_employee_roles` (`id`)   ON DELETE SET NULL,
    CONSTRAINT `fk_erh_to_role`      FOREIGN KEY (`to_role_id`)         REFERENCES `sch_employee_roles` (`id`)   ON DELETE SET NULL,
    CONSTRAINT `fk_erh_from_dept`    FOREIGN KEY (`from_department_id`) REFERENCES `sch_departments` (`id`)      ON DELETE SET NULL,
    CONSTRAINT `fk_erh_to_dept`      FOREIGN KEY (`to_department_id`)   REFERENCES `sch_departments` (`id`)      ON DELETE SET NULL,
    CONSTRAINT `fk_erh_from_desig`   FOREIGN KEY (`from_designation_id`) REFERENCES `sch_designations` (`id`)    ON DELETE SET NULL,
    CONSTRAINT `fk_erh_to_desig`     FOREIGN KEY (`to_designation_id`)   REFERENCES `sch_designations` (`id`)    ON DELETE SET NULL,
    CONSTRAINT `fk_erh_approved`     FOREIGN KEY (`approved_by`)         REFERENCES `sys_users` (`id`)           ON DELETE SET NULL,
    CONSTRAINT `fk_erh_order_media`  FOREIGN KEY (`order_media_id`)      REFERENCES `sys_media` (`id`)           ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Append-only audit of role / department / designation / branch changes per employee.';

  -- ---------------------------------------------------------------------------
  -- sch_employee_separations   (NEW Table in v4)
  -- ---------------------------------------------------------------------------
  -- Resignation / termination / retirement workflow. One active row per
  -- employee at a time. Drives the FSM for sch_employees.employment_status.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_separations` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `separation_type`       ENUM('Resignation','Termination','Retirement','End_of_Contract','Death','Absconded','Other') NOT NULL,
    `initiated_by`          ENUM('Employee','Employer','System') NOT NULL,
    `initiated_at`          TIMESTAMP NULL DEFAULT NULL,
    `notice_period_days`    SMALLINT UNSIGNED DEFAULT NULL,
    `notice_start_date`     DATE         DEFAULT NULL,
    `intended_last_working_date` DATE    DEFAULT NULL,
    `actual_last_working_date`   DATE    DEFAULT NULL,
    `reason_category`       VARCHAR(100) DEFAULT NULL  COMMENT 'Better_Opportunity / Personal / Performance / Misconduct / Health / Family',
    `reason`                TEXT         DEFAULT NULL,
    -- Workflow status
    `status`                ENUM('Initiated','Under_Review','Approved','Notice_Period','Completed','Cancelled','Rejected') NOT NULL DEFAULT 'Initiated',
    `approved_by`           INT UNSIGNED DEFAULT NULL,
    `approved_at`           TIMESTAMP NULL DEFAULT NULL,
    -- Exit formalities
    `exit_interview_done`   TINYINT(1)   NOT NULL DEFAULT 0,
    `exit_interview_notes`  TEXT         DEFAULT NULL,
    `clearance_complete`    TINYINT(1)   NOT NULL DEFAULT 0,
    `clearance_summary_json` JSON        DEFAULT NULL  COMMENT 'Per-department clearance: IT, Library, Finance, Stores, etc.',
    `final_settlement_done` TINYINT(1)   NOT NULL DEFAULT 0,
    `final_settlement_amount` DECIMAL(12,2) DEFAULT NULL,
    `relieving_letter_issued` TINYINT(1) NOT NULL DEFAULT 0,
    `experience_letter_issued` TINYINT(1) NOT NULL DEFAULT 0,
    `relieving_letter_media_id` INT UNSIGNED DEFAULT NULL,
    `experience_letter_media_id` INT UNSIGNED DEFAULT NULL,
    `is_eligible_for_rehire` TINYINT(1)  NOT NULL DEFAULT 1,
    `rehire_notes`          VARCHAR(500) DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_esep_employee`  (`employee_id`, `status`),
    KEY `idx_esep_lwd`       (`actual_last_working_date`),
    CONSTRAINT `fk_esep_employee`     FOREIGN KEY (`employee_id`)             REFERENCES `sch_employees` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_esep_approved`     FOREIGN KEY (`approved_by`)             REFERENCES `sys_users` (`id`)     ON DELETE SET NULL,
    CONSTRAINT `fk_esep_relieving`    FOREIGN KEY (`relieving_letter_media_id`) REFERENCES `sys_media` (`id`)   ON DELETE SET NULL,
    CONSTRAINT `fk_esep_experience`   FOREIGN KEY (`experience_letter_media_id`) REFERENCES `sys_media` (`id`)  ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee separation (resignation / termination / retirement) workflow.';


  -- ===========================================================================
  -- 2.5 : EMPLOYEE ATTENDANCE MANAGEMENT (v3 fixed + v4 enhancements + new tables)
  -- ===========================================================================

  -- ---------------------------------------------------------------------------
  -- sch_employee_attendance   (FIXED + enhanced in v4)
  -- ---------------------------------------------------------------------------
  -- One row per (employee × date). Aggregated final state.
  -- Raw punches live in sch_employee_attendance_punches.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_attendance` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `date`                  DATE NOT NULL,
    `shift_id`              INT UNSIGNED DEFAULT NULL  COMMENT 'v4 — which shift was applicable that day',
    -- Aggregate punch summary
    `check_in_time`         TIME DEFAULT NULL  COMMENT 'First punch-in of the day',
    `check_out_time`        TIME DEFAULT NULL  COMMENT 'Last punch-out of the day',
    `total_punches`         SMALLINT UNSIGNED NOT NULL DEFAULT 0  COMMENT 'v4',
    -- Geo & source for first/last punch (v4)
    `attendance_source`     ENUM('Biometric','MobileApp','Manual','SmartCard','QRCode','RFID','WebCheckIn','Other') NOT NULL DEFAULT 'Manual'  COMMENT 'v4',
    `device_id`             VARCHAR(100) DEFAULT NULL  COMMENT 'v4 — biometric / RFID terminal ID',
    `check_in_lat`          DECIMAL(10,7) DEFAULT NULL  COMMENT 'v4 — for geo-fenced mobile apps',
    `check_in_lng`          DECIMAL(10,7) DEFAULT NULL  COMMENT 'v4',
    `check_out_lat`         DECIMAL(10,7) DEFAULT NULL  COMMENT 'v4',
    `check_out_lng`         DECIMAL(10,7) DEFAULT NULL  COMMENT 'v4',
    -- Calculated metrics (set by attendance engine on day-close)
    `working_hours`         DECIMAL(5,2) DEFAULT NULL  COMMENT 'v4 — net hours present',
    `late_minutes`          SMALLINT DEFAULT NULL      COMMENT 'v4 — minutes late beyond grace',
    `early_minutes`         SMALLINT DEFAULT NULL      COMMENT 'v4 — minutes left early beyond grace',
    `is_overtime`           TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'v4',
    `overtime_hours`        DECIMAL(4,2) DEFAULT NULL  COMMENT 'v4',
    -- Day classification (v4)
    `is_holiday`            TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'v4 — denormalized from sch_holidays',
    `is_weekend`            TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'v4',
    `status`                ENUM('Present','Absent','On Leave','Half Day','Late','Holiday','Weekend','On_Tour','Work_From_Home') NOT NULL DEFAULT 'Absent',
    `leave_application_id`  INT UNSIGNED DEFAULT NULL,
    `remarks`               VARCHAR(255) DEFAULT NULL,
    -- Marked-by audit
    `marked_by`             INT UNSIGNED DEFAULT NULL,
    `marked_at`             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `auto_marked`           TINYINT(1) NOT NULL DEFAULT 0  COMMENT 'v4 — 1 = system computed, 0 = manual',
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'v4',
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL  COMMENT 'v4',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_attendance` (`employee_id`, `date`),
    INDEX `idx_attendance_date`     (`date`),
    INDEX `idx_attendance_status`   (`status`)        COMMENT 'v4',
    INDEX `idx_attendance_shift`    (`shift_id`)      COMMENT 'v4',
    INDEX `idx_attendance_late`     (`late_minutes`)  COMMENT 'v4',
    CONSTRAINT `fk_attendance_employee`           FOREIGN KEY (`employee_id`)         REFERENCES `sch_employees` (`id`)                ON DELETE CASCADE,
    CONSTRAINT `fk_attendance_shift`              FOREIGN KEY (`shift_id`)            REFERENCES `sch_employee_shifts` (`id`)          ON DELETE SET NULL,
    CONSTRAINT `fk_attendance_leave_application`  FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_attendance_marked_by`          FOREIGN KEY (`marked_by`)           REFERENCES `sys_users` (`id`)                    ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Daily attendance summary per employee. One row per (employee, date). Raw punches in sch_employee_attendance_punches.';

  -- ---------------------------------------------------------------------------
  -- sch_employee_attendance_punches   (NEW in v4)
  -- ---------------------------------------------------------------------------
  -- Raw punch log. One row per swipe / mobile check-in.
  -- Aggregated nightly into sch_employee_attendance.
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_attendance_punches` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    `attendance_id`         INT UNSIGNED DEFAULT NULL  COMMENT 'FK → sch_employee_attendance.id (set after aggregation)',
    `punch_at`              DATETIME NOT NULL,
    `punch_type`            ENUM('In','Out','Break_Out','Break_In','Tour_Out','Tour_In','Unknown') NOT NULL DEFAULT 'Unknown',
    `attendance_source`     ENUM('Biometric','MobileApp','Manual','SmartCard','QRCode','RFID','WebCheckIn','Other') NOT NULL,
    `device_id`             VARCHAR(100) DEFAULT NULL,
    `device_location`       VARCHAR(150) DEFAULT NULL,
    `latitude`              DECIMAL(10,7) DEFAULT NULL,
    `longitude`             DECIMAL(10,7) DEFAULT NULL,
    `ip_address`            VARCHAR(45)  DEFAULT NULL  COMMENT 'IPv4 or IPv6',
    `user_agent`            VARCHAR(255) DEFAULT NULL,
    `is_within_geofence`    TINYINT(1)   DEFAULT NULL  COMMENT 'NULL if no geofence configured',
    `is_processed`          TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '1 = aggregated into attendance row',
    `is_invalid`            TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '1 = duplicate / out-of-shift / spam',
    `invalidation_reason`   VARCHAR(255) DEFAULT NULL,
    `raw_payload`           JSON         DEFAULT NULL  COMMENT 'Full vendor payload for forensic',
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_eap_employee_date` (`employee_id`, `punch_at`),
    KEY `idx_eap_unprocessed`   (`is_processed`, `punch_at`),
    KEY `idx_eap_attendance`    (`attendance_id`),
    CONSTRAINT `fk_eap_employee`   FOREIGN KEY (`employee_id`)   REFERENCES `sch_employees` (`id`)         ON DELETE CASCADE,
    CONSTRAINT `fk_eap_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `sch_employee_attendance` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Raw biometric / mobile punch log. Aggregated into sch_employee_attendance.';

  -- ---------------------------------------------------------------------------
  -- sch_employee_attendance_corrections   (NEW in v4)
  -- ---------------------------------------------------------------------------
  -- Manual correction request workflow (employee files, manager approves).
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_attendance_corrections` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `attendance_id`         INT UNSIGNED NOT NULL,
    `employee_id`           INT UNSIGNED NOT NULL,
    `correction_type`       ENUM('Forgot_Punch_In','Forgot_Punch_Out','Wrong_Status','On_Tour','Work_From_Home','Time_Adjustment','Other') NOT NULL,
    `requested_check_in`    TIME DEFAULT NULL,
    `requested_check_out`   TIME DEFAULT NULL,
    `requested_status`      ENUM('Present','Absent','On Leave','Half Day','Late','Holiday','Weekend','On_Tour','Work_From_Home') DEFAULT NULL,
    `reason`                TEXT NOT NULL,
    `supporting_doc_media_id` INT UNSIGNED DEFAULT NULL,
    `status`                ENUM('Pending','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
    `reviewed_by`           INT UNSIGNED DEFAULT NULL,
    `reviewed_at`           TIMESTAMP NULL DEFAULT NULL,
    `review_remarks`        VARCHAR(500) DEFAULT NULL,
    `applied_at`            TIMESTAMP NULL DEFAULT NULL  COMMENT 'When the correction was actually written back to attendance row',
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_eac_attendance` (`attendance_id`),
    KEY `idx_eac_employee`   (`employee_id`, `status`),
    KEY `idx_eac_pending`    (`status`, `created_at`),
    CONSTRAINT `fk_eac_attendance` FOREIGN KEY (`attendance_id`)         REFERENCES `sch_employee_attendance` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_eac_employee`   FOREIGN KEY (`employee_id`)           REFERENCES `sch_employees` (`id`)           ON DELETE CASCADE,
    CONSTRAINT `fk_eac_reviewer`   FOREIGN KEY (`reviewed_by`)           REFERENCES `sys_users` (`id`)               ON DELETE SET NULL,
    CONSTRAINT `fk_eac_doc`        FOREIGN KEY (`supporting_doc_media_id`) REFERENCES `sys_media` (`id`)             ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Attendance correction request / approval workflow.';


  -- ===========================================================================
  -- 2.6 : LEAVE MANAGEMENT (v3 retained + v4 minor fixes)
  -- ===========================================================================

  -- ---------------------------------------------------------------------------
  -- sch_employee_leave_applications   (v3 + v4 additions)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_leave_applications` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id`           INT UNSIGNED NOT NULL,
    -- `academic_session_id`   INT UNSIGNED NOT NULL,
    `annual_leave_sessions_id`   INT UNSIGNED NOT NULL,   -- FK to sch_annual_leave_sessions.id
    `leave_type_id`         INT UNSIGNED NOT NULL,
    `from_date`             DATE NOT NULL,
    `to_date`               DATE NOT NULL,
    `total_days`            DECIMAL(4,1) NOT NULL DEFAULT 1.0,
    `is_half_day`           TINYINT(1) NOT NULL DEFAULT 0,
    `half_day_slot`         ENUM('Morning','Afternoon') DEFAULT NULL,
    `is_emergency`          TINYINT(1) NOT NULL DEFAULT 0,    -- v4 addition: whether this leave is being applied for on an emergency basis (e.g., same-day or next-day leave due to unforeseen circumstances)
    `reason`                TEXT NOT NULL,
    `status`                ENUM('Draft','Submitted','Under Review','Info Requested','Doc Requested','Escalated','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Draft',
    `approval_policy_id`    INT UNSIGNED DEFAULT NULL,       -- FK to sch_leave_approval_policies.id; determined at submission time based on employee context and cached here for easy reference during approval workflow
    `current_level_number`  TINYINT UNSIGNED DEFAULT NULL,
    `pending_with_user_id`  INT UNSIGNED DEFAULT NULL,     -- FK to sys_users.id; the user who currently needs to take action on this application (approve/reject/request info); NULL if not currently pending with anyone (e.g., in Draft status or after final approval/rejection)
    `applied_by`            INT UNSIGNED NOT NULL,        -- FK to sys_users.id; the user who created this leave application (usually the employee themselves, but could be an admin or manager submitting on their behalf)
    `submitted_at`          TIMESTAMP NULL DEFAULT NULL,
    -- Cancellation (v4)
    `cancelled_by`          INT UNSIGNED DEFAULT NULL  COMMENT 'v4',  -- FK to sys_users.id; the user who cancelled this application (could be the employee or an admin/manager)
    `cancelled_at`          TIMESTAMP NULL DEFAULT NULL  COMMENT 'v4',
    `cancellation_reason`   VARCHAR(500) DEFAULT NULL  COMMENT 'v4',
    -- Final decision
    `final_reviewed_by`     INT UNSIGNED DEFAULT NULL,    -- FK to sys_users.id; the user who took the final decision on this application (could be an approver or an admin)
    `final_reviewed_at`     TIMESTAMP NULL DEFAULT NULL,
    `approved_days`         DECIMAL(4,1) DEFAULT NULL,    -- In case of partial approval (e.g., manager approves 3 out of 5 days requested), this field captures the total number of days approved. NULL means not applicable or not yet reviewed.
    `final_remarks`         TEXT DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1  COMMENT 'v4',
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_ela_employee`         (`employee_id`, `annual_leave_sessions_id`),
    INDEX `idx_ela_status`           (`status`),
    INDEX `idx_ela_dates`            (`from_date`, `to_date`),
    INDEX `idx_ela_leave_type`       (`leave_type_id`),
    INDEX `idx_ela_policy`           (`approval_policy_id`),
    INDEX `idx_ela_applied_by`       (`applied_by`),
    INDEX `idx_ela_final_reviewed`   (`final_reviewed_by`),
    INDEX `idx_ela_pending_with`     (`pending_with_user_id`)  COMMENT 'v4 — fast dashboard query',
    CONSTRAINT `fk_ela_employee`      FOREIGN KEY (`employee_id`)         REFERENCES `sch_employees` (`id`)                  ON DELETE RESTRICT,
    CONSTRAINT `fk_ela_session`       FOREIGN KEY (`annual_leave_sessions_id`) REFERENCES `sch_annual_leave_sessions` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ela_leave_type`    FOREIGN KEY (`leave_type_id`)       REFERENCES `sch_staff_leave_types` (`id`)          ON DELETE RESTRICT,
    CONSTRAINT `fk_ela_policy`        FOREIGN KEY (`approval_policy_id`)  REFERENCES `sch_leave_approval_policies` (`id`)    ON DELETE SET NULL,
    CONSTRAINT `fk_ela_applied_by`    FOREIGN KEY (`applied_by`)          REFERENCES `sys_users` (`id`)                      ON DELETE RESTRICT,
    CONSTRAINT `fk_ela_final_reviewed` FOREIGN KEY (`final_reviewed_by`)  REFERENCES `sys_users` (`id`)                      ON DELETE SET NULL,
    CONSTRAINT `fk_ela_cancelled_by`  FOREIGN KEY (`cancelled_by`)        REFERENCES `sys_users` (`id`)                      ON DELETE SET NULL,
    CONSTRAINT `fk_ela_pending_with`  FOREIGN KEY (`pending_with_user_id`) REFERENCES `sys_users` (`id`)                     ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Employee leave application — core request record';

  -- ---------------------------------------------------------------------------
  -- sch_employee_leave_approvals   (v3 + v4 audit columns)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_leave_approvals` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `leave_application_id`  INT UNSIGNED NOT NULL,     -- FK to sch_employee_leave_applications.id
    `policy_level_id`       INT UNSIGNED NOT NULL,     -- FK to sch_leave_approval_policy_levels.id; captures which level of the approval policy this approval action corresponds to (e.g., level 1 = Reporting Manager, level 2 = Department Head, etc.)
    `level_number`          TINYINT UNSIGNED NOT NULL,    -- Redundant but convenient for queries: the level number (1, 2, 3, etc.) corresponding to the policy_level_id; helps avoid joins when we just want to know which level this approval action is for
    `level_name`            VARCHAR(100) NOT NULL,
    `approver_user_id`      INT UNSIGNED DEFAULT NULL,    -- FK to sys_users.id; the user who took this approval action (could be a manager, HR, or even the employee themselves in case of cancellation)
    `action`                ENUM('Pending','Approved','Rejected','Info Requested','Doc Requested','Escalated','Skipped') NOT NULL DEFAULT 'Pending',
    `remarks`               TEXT DEFAULT NULL,
    `acted_at`              TIMESTAMP NULL DEFAULT NULL,
    `escalation_deadline`   TIMESTAMP NULL DEFAULT NULL,
    `escalated_at`          TIMESTAMP NULL DEFAULT NULL,
    `escalated_to_level`    TINYINT UNSIGNED DEFAULT NULL,   -- If this approval action was escalated, this field captures the next level number it was escalated to (e.g., if level 1 approval was escalated to level 2, this would be 2). NULL means not escalated.
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1  COMMENT 'v4',
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL  COMMENT 'v4',
    PRIMARY KEY (`id`),
    INDEX `idx_elap_application`     (`leave_application_id`, `level_number`),
    INDEX `idx_elap_approver`        (`approver_user_id`),
    INDEX `idx_elap_action`          (`action`),
    INDEX `idx_elap_pending`         (`leave_application_id`, `action`),
    INDEX `idx_elap_deadline`        (`escalation_deadline`),
    CONSTRAINT `fk_elap_application` FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`)   ON DELETE CASCADE,
    CONSTRAINT `fk_elap_level`       FOREIGN KEY (`policy_level_id`)      REFERENCES `sch_leave_approval_policy_levels` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_elap_approver`    FOREIGN KEY (`approver_user_id`)     REFERENCES `sys_users` (`id`)                        ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-level approver action trail + escalation log';

  -- ---------------------------------------------------------------------------
  -- sch_employee_leave_application_docs   (v3 retained)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_leave_application_docs` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `leave_application_id`  INT UNSIGNED NOT NULL,
    `document_name`         VARCHAR(150) NOT NULL,
    `document_type_id`      INT UNSIGNED DEFAULT NULL,
    `description`           VARCHAR(255) DEFAULT NULL,
    `file_name`             VARCHAR(255) NOT NULL,
    `media_id`              INT UNSIGNED DEFAULT NULL,
    `uploaded_by`           INT UNSIGNED NOT NULL,
    `is_in_response_to_request` TINYINT(1) NOT NULL DEFAULT 0,
    `request_remark_id`     INT UNSIGNED DEFAULT NULL,
    `is_active`             TINYINT(1)   NOT NULL DEFAULT 1  COMMENT 'v4',
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_elad_application`     (`leave_application_id`),
    INDEX `idx_elad_request_remark`  (`request_remark_id`),
    CONSTRAINT `fk_elad_application` FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_elad_doc_type`    FOREIGN KEY (`document_type_id`)     REFERENCES `sys_dropdown_table` (`id`)             ON DELETE SET NULL,
    CONSTRAINT `fk_elad_uploaded_by` FOREIGN KEY (`uploaded_by`)          REFERENCES `sys_users` (`id`)                      ON DELETE RESTRICT,
    CONSTRAINT `fk_elad_media`       FOREIGN KEY (`media_id`)             REFERENCES `sys_media` (`id`)                      ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Supporting documents for employee leave applications';

  -- ---------------------------------------------------------------------------
  -- sch_employee_leave_application_remarks   (v3 + v4 audit + read tracking)
  -- ---------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_employee_leave_application_remarks` (
    `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `leave_application_id`  INT UNSIGNED NOT NULL,
    `approval_level_id`     INT UNSIGNED DEFAULT NULL,
    `remark_type`           ENUM('Comment','Info_Request','Doc_Request','Response','Status_Change') NOT NULL DEFAULT 'Comment',
    `message`               TEXT NOT NULL,
    `is_from_approver`      TINYINT(1) NOT NULL DEFAULT 0,
    `remarked_by`           INT UNSIGNED NOT NULL,
    `parent_remark_id`      INT UNSIGNED DEFAULT NULL,
    `is_resolved`           TINYINT(1) NOT NULL DEFAULT 0,
    `resolved_at`           TIMESTAMP NULL DEFAULT NULL,
    `read_at`               TIMESTAMP NULL DEFAULT NULL  COMMENT 'v4 — when the recipient first read this remark',
    `read_by`               INT UNSIGNED DEFAULT NULL    COMMENT 'v4',
    `old_status`            VARCHAR(30) DEFAULT NULL,
    `new_status`            VARCHAR(30) DEFAULT NULL,
    `is_active`             TINYINT(1)  NOT NULL DEFAULT 1  COMMENT 'v4',
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL  COMMENT 'v4',
    PRIMARY KEY (`id`),
    INDEX `idx_elar_application`   (`leave_application_id`, `remark_type`),
    INDEX `idx_elar_level`         (`approval_level_id`),
    INDEX `idx_elar_parent`        (`parent_remark_id`),
    INDEX `idx_elar_remarked_by`   (`remarked_by`),
    INDEX `idx_elar_unresolved`    (`leave_application_id`, `is_resolved`),
    CONSTRAINT `fk_elar_application`   FOREIGN KEY (`leave_application_id`) REFERENCES `sch_employee_leave_applications` (`id`)        ON DELETE CASCADE,
    CONSTRAINT `fk_elar_level`         FOREIGN KEY (`approval_level_id`)    REFERENCES `sch_leave_approval_policy_levels` (`id`)      ON DELETE SET NULL,
    CONSTRAINT `fk_elar_remarked_by`   FOREIGN KEY (`remarked_by`)          REFERENCES `sys_users` (`id`)                              ON DELETE RESTRICT,
    CONSTRAINT `fk_elar_parent_remark` FOREIGN KEY (`parent_remark_id`)     REFERENCES `sch_employee_leave_application_remarks` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_elar_read_by`       FOREIGN KEY (`read_by`)              REFERENCES `sys_users` (`id`)                              ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Approver ↔ Employee communication thread + FSM audit log';


-- ===========================================================================
-- 3 - INFRA SETUP SUB-MODULE (sch)
-- ===========================================================================

  -- Building Coding format is - 2 Digit for Buildings(10-99)
  CREATE TABLE IF NOT EXISTS `sch_buildings` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` char(10) NOT NULL,                      -- 2 digits code (10,11,12) 
    `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_buildings_code` (`code`),
    UNIQUE KEY `uq_buildings_name` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Room types, this will be used to define different types of rooms like Science Lab, Computer Lab, Sports Room etc.
  CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` CHAR(10) NOT NULL,                         -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT', "HOUSE_ROOM"
    `short_name` varchar(30) NOT NULL,                -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
    `name` varchar(100) NOT NULL,
    `required_resources` text DEFAULT NULL,           -- e.g., 'Microscopes, Lab Coats, Safety Goggles' for Science Lab
    `class_house_room` tinyint(1) NOT NULL DEFAULT 0, -- 1=Class House Room, 0=Other Room
    `room_count_in_category` smallint unsigned DEFAULT 0, -- Total Number of Rooms in this category
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_roomType_code` (`code`),
    UNIQUE KEY `uq_roomType_shortName` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
  CREATE TABLE IF NOT EXISTS `sch_rooms` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `building_id` int unsigned NOT NULL,      -- FK to 'sch_buildings' table
    `room_type_id` int NOT NULL,              -- FK to 'sch_rooms_type' table
    `code` CHAR(20) NOT NULL,                 -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,        -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(100) NOT NULL,
    `capacity` int unsigned DEFAULT NULL,               -- Seating Capacity of the Room
    `max_limit` int unsigned DEFAULT NULL,              -- Maximum Limit of the Room, Maximum how many students can accomodate in the room
    `resource_tags` text DEFAULT NULL,                  -- e.g., 'Projector, Smart Board, AC, Lab Equipment' etc.
    `can_host_lecture` TINYINT(1) NOT NULL DEFAULT 0,   -- Seats + Writing Surface
    `can_host_practical` TINYINT(1) NOT NULL DEFAULT 0, -- Seats + Writing Surface + Lab Equipment
    `can_host_exam` TINYINT(1) NOT NULL DEFAULT 0,      -- Seats + Writing Surface + Exam Equipment
    `can_host_activity` TINYINT(1) NOT NULL DEFAULT 0,  -- Open space for movement
    `can_host_sports` TINYINT(1) NOT NULL DEFAULT 0,    -- Specific for PE/Games
    `room_available_from_date` DATE DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_rooms_code` (`code`),
    UNIQUE KEY `uq_rooms_shortName` (`short_name`),
    CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================================================================================
  -- ===========================================================================
  -- OLD Change Log:
  -- ===========================================================================
    -- Table: `sch_study_formats`
    -- Addedd - `is_system` tinyint(1) NOT NULL DEFAULT '0',
    --
    -- Table: `sch_subjects`
    -- Addedd - `is_system` tinyint(1) NOT NULL DEFAULT '0',
    --
    -- Table: `sch_subject_study_format_jnt`
    -- Added - `has_multiple_options` tinyint(1) NOT NULL DEFAULT '0',
    --
    -- Added New Table: `sch_subject_study_format_options`
    --
    -- ENHANCEMENTS IN V4.0 from V3.0:
    -- 1. Addedd `is_system` in Table - `sch_study_formats` & `sch_subjects`
    -- 2. Addedd `has_multiple_options` in Table - `sch_subject_study_format_jnt`
    -- 3. Remove Table - `sch_class_group_subject_options_jnt`
  

  -- ===========================================================================
  -- NEW ENHANCEMENTS IN V4.1 from V4.0:
  -- ===========================================================================

-- 1. Addedd `is_system` in Table - `sch_study_formats` & `sch_subjects`
-- 2. Addedd `has_multiple_options` in Table - `sch_subject_study_format_jnt`
-- 3. Removed `has_multiple_options` in Table - `sch_class_group_subject_options_jnt`
