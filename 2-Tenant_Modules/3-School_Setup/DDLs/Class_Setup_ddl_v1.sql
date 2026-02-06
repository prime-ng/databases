-- ===========================================================================
-- 3.1 - CLASS SETUP SUB-MODULE (sch)
-- ===========================================================================

  CREATE TABLE IF NOT EXISTS `sch_sections` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(20) NOT NULL,            -- e.g. 'A', 'B'
    `ordinal` tinyint unsigned DEFAULT 1,   -- will have sequence order for Sections
    `code` CHAR(1) NOT NULL,                -- e.g., 'A','B','C','D' and so on (This will be used for Timetable)
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
    `name` varchar(50) NOT NULL,                -- e.g. 'Grade 1' or 'Class 10'
    `short_name` varchar(10) DEFAULT NULL,      -- e.g. 'G1' or '10A'
    `ordinal` tinyint DEFAULT NULL,             -- will have sequence order for Classes NURSARY = -3, LKG = -2, UKG = -1, 1st = 1, 2nd = 2, 3rd = 3, 4th = 4, 5th = 5, 6th = 6, 7th = 7, 8th = 8, 9th = 9, 10th = 10, 11th = 11, 12th = 12
    `code` CHAR(3) NOT NULL,                    -- e.g., 'BV1','BV2','1st','1' and so on (This will be used for Timetable)
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classes_shortName` (`short_name`),
    UNIQUE KEY `uq_classes_code` (`code`),
    UNIQUE KEY `uq_classes_name` (`name`),
    UNIQUE KEY `uq_classes_ordinal` (`ordinal`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_class_section_jnt` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `class_id` int unsigned NOT NULL,               -- FK to sch_classes
    `section_id` int unsigned NOT NULL,             -- FK to sch_sections
    `class_secton_code` char(5) NOT NULL,           -- Combination of class Code + section Code i.e. '8th_A', '10h_B'  
    `capacity` tinyint unsigned DEFAULT NULL,       -- Targeted / Planned Quantity of stundets in Each Sections of every class.
    `total_student` tinyint unsigned DEFAULT NULL,  -- Actual Number of Student in the Class+Section
    `class_teacher_id` bigint unsigned NOT NULL,    -- FK to sch_users
    `assistance_class_teacher_id` bigint unsigned NOT NULL,  -- FK to sch_users
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classSection_classId_sectionId` (`class_id`,`section_id`),
    UNIQUE KEY `uq_classSection_code` (`class_secton_code`),
    UNIQUE KEY `uq_classSection_classTeacherId` (`class_teacher_id`),
    UNIQUE KEY `uq_classSection_assistanceClassTeacherId` (`assistance_class_teacher_id`),
    CONSTRAINT `fk_classSection_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classSection_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classSection_classTeacherId` FOREIGN KEY (`class_teacher_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classSection_assistanceClassTeacherId` FOREIGN KEY (`assistance_class_teacher_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- subject_type will represent what type of subject it is - Major, Minor, Core, Main, Optional etc.
  CREATE TABLE IF NOT EXISTS `sch_subject_types` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `short_name` varchar(20) NOT NULL,  -- 'MAJOR','MINOR','OPTIONAL'
    `name` varchar(50) NOT NULL,
    `code` char(3) NOT NULL,         -- 'MAJ','MIN','OPT','ACT','SPO'
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
    `short_name` varchar(20) NOT NULL,  -- 'LECTURE','LAB','PRACTICAL','TUTORIAL','SEMINAR','WORKSHOP','GROUP_DISCUSSION','OTHER'
    `name` varchar(50) NOT NULL,
    `code` CHAR(3) NOT NULL,            -- e.g., 'LAC','LAB','ACT','ART' and so on (This will be used for Timetable)
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
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `short_name` varchar(20) NOT NULL,  -- e.g. 'SCIENCE','MATH','SST','ENGLISH' and so on
    `name` varchar(50) NOT NULL,
    `code` CHAR(3) NOT NULL,         -- e.g., 'SCI','MTH','SST','ENG' and so on (This will be used for Timetable)
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
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `subject_id` bigint unsigned NOT NULL,            -- FK to 'sch_subjects'
    `study_format_id` int unsigned NOT NULL,          -- FK to 'sch_study_formats'
    `name` varchar(50) NOT NULL,                      -- e.g., 'Science Lecture','Science Lab','Math Lecture','Math Lab' and so on
    `subj_stdformat_code` CHAR(7) NOT NULL,         -- Will be combination of (Subject.codee+'-'+StudyFormat.code) e.g., 'SCI_LAC','SCI_LAB','SST_LAC','ENG_LAC' (This will be used for Timetable)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subStudyFormat_subjectId_stFormat` (`subject_id`,`study_format_id`),
    UNIQUE KEY `uq_subStudyFormat_subStdformatCode` (`subj_stdformat_code`),
    CONSTRAINT `fk_subStudyFormat_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subStudyFormat_studyFormatId` FOREIGN KEY (`study_format_id`) REFERENCES `sch_study_formats` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Ths table will be used to define different Class Groups like 10th-A Science Lecture Major, 7th-B Commerce Optional etc.
  -- old name 'sch_subject_study_format_class_subj_types_jnt' changed to 'sch_class_groups_jnt'
  CREATE TABLE IF NOT EXISTS `sch_class_groups_jnt` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,                  -- FK
    `class_id` int unsigned NOT NULL,                              -- FK to 'sch_classes'
    `section_id` int unsigned NULL,                            -- FK to 'sch_sections'
    `subject_Study_format_id` bigint unsigned NOT NULL,   -- FK to 'sch_subject_study_format_jnt'
    `subject_type_id` int unsigned NOT NULL,              -- FK to 'sch_subject_types'
    `rooms_type_id` int unsigned NOT NULL,             -- FK to 'sch_rooms_type'
    `class_house_roome_id` int unsigned NOT NULL,             -- FK to 'sch_rooms
    `name` varchar(50) NOT NULL,                          -- 10th-A Science Lacture Major
    `code` CHAR(17) NOT NULL, -- Combination of (Class+Section+Subject+StudyFormat+SubjType) e.g., '10h_A_SCI_LAC_MAJ','8th_MAT_LAC_OPT' (This will be used for Timetable)
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_Study_format_id`),
    UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`), 
    CONSTRAINT `fk_classGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subjStudyFormatId` FOREIGN KEY (`subject_Study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_subTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_classGroups_roomTypeId` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Table 'sch_subject_groups' will be used to assign all subjects to the students
  -- There will be a Variable in 'sch_settings' table named 'SubjGroup_For_All_Sections' (Subj_Group_will_be_used_for_all_sections_of_a_class)
  -- if above variable is True then section_id will be Nul in below table and
  -- Every Group will eb avalaible accross sections for a particuler class
  CREATE TABLE IF NOT EXISTS `sch_subject_groups` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `class_id` int UNSIGNED NOT NULL,                        -- FK to 'sch_classes'
    `section_id` int UNSIGNED NULL,                          -- FK (Section can be null if Group will be used for all sectons)
    `short_name` varchar(30) NOT NULL,              -- 7th Science, 7th Commerce, 7th-A Science etc.
    `name` varchar(100) NOT NULL,                   -- '7th (Sci,Mth,Eng,Hindi,SST with Sanskrit,Dance)'
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjectGroups_shortName` (`short_name`),
    UNIQUE KEY `uq_subjectGroups_name` (`class_id`,`name`),
    CONSTRAINT `fk_subGroups_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subGroups_sectionId` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_subject_group_subject_jnt` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `subject_group_id` bigint unsigned NOT NULL,              -- FK to 'sch_subject_groups'
    `class_group_id` bigint unsigned NOT NULL,                -- FK to 'sch_class_groups_jnt'
    `subject_id` int unsigned NOT NULL,                       -- FK to 'sch_subjects'
    `subject_type_id` int unsigned NOT NULL,                  -- FK to 'sch_subject_types'
    `subject_study_format_id` bigint unsigned NOT NULL,       -- FK to 'sch_subject_study_format_jnt'
    `is_compulsory` tinyint(1) NOT NULL DEFAULT '0',          -- Is this Subject compulsory for Student or Optional
    `weekly_periods` TINYINT UNSIGNED NOT NULL,  -- Total periods required per week
    `min_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods required per week
    `max_periods_per_week` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods required per week
    `max_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Maximum periods per day
    `min_per_day` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum periods per day
    `min_gap_periods` TINYINT UNSIGNED DEFAULT NULL,  -- Minimum gap periods
    `allow_consecutive` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether consecutive periods are allowed
    `max_consecutive` TINYINT UNSIGNED DEFAULT 2,  -- Maximum consecutive periods
    `priority` SMALLINT UNSIGNED DEFAULT 50,  -- Priority of this requirement
    `compulsory_room_type` INT UNSIGNED DEFAULT NULL,  -- FK to sch_room_types.id
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subjGrpSubj_subjGrpId_classGroup` (`subject_group_id`,`class_group_id`),
    CONSTRAINT `fk_subjGrpSubj_subjectGroup` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_classGroup` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectTypeId` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_subjGrpSubj_subjectStudyFormatId` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Add new Field for Timetable -
  -- is_compulsory, min_periods_per_week, max_periods_per_week, max_per_day, min_per_day, min_gap_periods, allow_consecutive, max_consecutive, priority, compulsory_room_type
