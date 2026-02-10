-- =====================================================================
-- CLASS SUB-MODULE - VERSION 2.0 (PRODUCTION-GRADE)
-- Enhanced from Class_Setup_ddl_v1.0.sql
-- =====================================================================
-- Target: MySQL 8.x | Stack: PHP + Laravel
-- Architecture: Multi-tenant, Constraint-based Auto-Scheduling
-- TABLE PREFIX: sch_ - Class Sub-Module
-- =====================================================================
-- ENHANCEMENTS IN V2.0:
-- 1. Changed Timetabel Parametere (Subject_Study-Format) Requirement to sch_class_group, previously it was in sch_subj_group_subject_jnt table
-- 2. Made sch_subject_group_subject_jnt table only for subject group and subject combination to allign with Stuents.
-- 3. Table Purpose more refined and clear
-- 4. 
-- =====================================================================

-- ===========================================================================
-- 3.1 - CLASS SETUP SUB-MODULE (sch)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `sch_sections` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint unsigned DEFAULT 1,   -- will have sequence order for Sections (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,                -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NULL,      -- e.g. 'SEC-A' or 'SEC-B' (NEW)
    `name` varchar(50) NOT NULL,            -- e.g. 'Section - A', 'Section - B'
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sections_name` (`name`),
    UNIQUE KEY `uq_sections_code` (`code`),
    UNIQUE KEY `uq_sections_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Classes, Sections, Subjects, Subject Types, Study Formats, Class-Section Junctions, Subject-StudyFormat Junctions, Class Groups, Subject Groups
  CREATE TABLE IF NOT EXISTS `sch_classes` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,             -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,                    -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
    `short_name` varchar(20) DEFAULT NULL,      -- e.g. 'G1' or '10th', '11th', '12th'
    `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th', 'Class - 12th'
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classes_code` (`code`),
    UNIQUE KEY `uq_classes_shortName` (`short_name`),
    UNIQUE KEY `uq_classes_name` (`name`),
    UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order  (Added new) (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,  -- FK to sch_classes
    `section_id` int unsigned NOT NULL,  -- FK to sch_sections
    `code` char(10) NOT NULL,  -- Combination of class Code + section Code i.e. '8th_A', '10h_B' (Changed from class_secton_code)
    `name` varchar(50) NOT NULL,  -- e.g. 'Grade 1' or 'Class - 10th', 'Class - 11th Section - A', 'Class - 12th Section - B' (Added new)
    `capacity` tinyint unsigned DEFAULT NULL,  -- Targeted / Planned Quantity of stundets in Each Sections of every class.
    `actual_total_student` tinyint unsigned DEFAULT NULL,  -- Actual Number of Student in the Class+Section (changed from total_student)
    `min_required_student` tinyint unsigned DEFAULT NULL,  -- Minimum Number of Student required to start a class+section (Added new)
    `max_allowed_student` tinyint unsigned DEFAULT NULL,  -- Maximum Number of Student allowed in a class+section (Added new)
    `class_teacher_id` INT unsigned NOT NULL,  -- FK to sch_users
    `assistance_class_teacher_id` INT unsigned NOT NULL,  -- FK to sch_users
    `rooms_type_id` int unsigned NOT NULL,  -- FK to 'sch_rooms_type' (Added new)
    `class_house_room_id` int unsigned NOT NULL,  -- FK to 'sch_rooms' (Added new)
    `total_periods_daily` tinyint unsigned DEFAULT NULL,  -- Total Number of Periods in a day for this class+section (Added new)
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
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
    `is_active` tinyint(1) NOT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_studyFormats_shortName` (`short_name`),
    UNIQUE KEY `uq_studyFormats_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Data Seed for Study_Format - LECTURE, LAB, PRACTICAL, TUTORIAL, SEMINAR, WORKSHOP, GROUP_DISCUSSION, OTHER

  CREATE TABLE IF NOT EXISTS `sch_subjects` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `code` CHAR(5) NOT NULL,         -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
    `short_name` varchar(20) NOT NULL,  -- e.g. 'SCIENCE','MATH','SST','ENGLISH' and so on
    `name` varchar(50) NOT NULL,        -- 'SCIENCE','MATH','SST','ENGLISH' and so on
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjects_shortName` (`short_name`),
    UNIQUE KEY `uq_subjects_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- subject_study_format is grouping for different streams like Sci-10 Lacture, Arts-10 Activity, Core-10
  -- I have removed 'sub_types' from 'sch_subject_study_format_jnt' because one Subject_StudyFormat may belongs to different Subject_type for different classes
  -- Removed 'short_name' as we can use `sub_stdformat_code`
  CREATE TABLE IF NOT EXISTS `sch_subject_study_format_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `subject_id` INT unsigned NOT NULL,        -- FK to 'sch_subjects'
    `study_format_id` int unsigned NOT NULL,      -- FK to 'sch_study_formats'
    `subject_type_id` int unsigned NOT NULL,      -- FK to 'sch_subject_types'
    `code` CHAR(30) NOT NULL,                     -- e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (Changed from 'subject_studyformat_code')
    `name` varchar(50) NOT NULL,                  -- e.g., 'Science Lecture','Science Lab','Math Lecture','Math Lab' and so on
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subStudyFormat_code` (`code`),
    UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
    CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
    `id` INT unsigned NOT NULL AUTO_INCREMENT,
    `ordinal` tinyint DEFAULT NULL,     -- will have sequence order (Auto Update by Drag & Drop)
    `class_id` int unsigned NOT NULL,             -- FK to 'sch_classes'
    `section_id` int unsigned NOT NULL,           -- FK to 'sch_sections' (Optional)
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
    `max_consecutive_periods` TINYINT UNSIGNED DEFAULT 1,          -- Maximum consecutive periods
    `priority_score` SMALLINT UNSIGNED DEFAULT 10,                 -- Priority of this requirement on 1-100 scale
    `compulsory_specific_room_type` TINYINT(1) NOT NULL DEFAULT 0, -- Whether specific room type is required (TRUE - if Specific Room Type is Must)
    `required_room_type_id` INT UNSIGNED NOT NULL,      -- FK to sch_room_types.id (Required)
    `required_room_id` INT UNSIGNED DEFAULT NULL,      -- FK to sch_rooms.id (Optional)
    -- Audit Fields
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`), 
    UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`),
    CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`required_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_roomId` FOREIGN KEY (`required_room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE,
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- There will be a Variable in 'sch_settings' table named (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- Remove above condition and make Scetion_id optional.

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
    `subject_id` int unsigned NOT NULL,                       -- FK to 'sch_subjects' (De-Normalization)
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

