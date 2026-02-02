-- =====================================================================
-- TIMETABLE MODULE - VERSION 1.0 (Took from Migration File)
-- Enhanced from 2026-02-01_tenant_enhanced.sql
-- =====================================================================
-- ENHANCEMENTS IN 2026-02-01_tenant_enhanced.sql
-- Added Reference Tables from Other Modules
--
-- =====================================================================

-- -------------------------------------------------
--  SECTION 0: EXTRA TABLES
-- -------------------------------------------------
CREATE TABLE `tt_days` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_modes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `has_exam` tinyint(1) NOT NULL DEFAULT '0',
  `has_teaching` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_timetable_mode_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timing_profile` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `profile_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_periods` int unsigned NOT NULL,
  `timezone` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tt_timing_profile_profile_code_unique` (`profile_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timing_profile_period` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `timing_profile_id` bigint unsigned NOT NULL,
  `segment_ordinal` int unsigned NOT NULL,
  `label` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `segment_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PERIOD',
  `counts_as_period` tinyint(1) NOT NULL DEFAULT '1',
  `period_ordinal` int unsigned DEFAULT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tpp_ord` (`timing_profile_id`,`segment_ordinal`),
  KEY `idx_tpp_period_map` (`timing_profile_id`,`period_ordinal`),
  CONSTRAINT `tt_timing_profile_period_timing_profile_id_foreign` FOREIGN KEY (`timing_profile_id`) REFERENCES `tt_timing_profile` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_periods` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ordinal` int unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- -------------------------------------------------
--  SECTION 1: MASTER TABLES
-- -------------------------------------------------
CREATE TABLE `tt_shifts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `default_start_time` time DEFAULT NULL,
  `default_end_time` time DEFAULT NULL,
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shift_code` (`code`),
  UNIQUE KEY `uq_shift_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_day_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_working_day` tinyint(1) NOT NULL DEFAULT '1',
  `reduced_periods` tinyint(1) NOT NULL DEFAULT '0',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_daytype_code` (`code`),
  UNIQUE KEY `uq_daytype_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `icon` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_schedulable` tinyint(1) NOT NULL DEFAULT '1',
  `counts_as_teaching` tinyint(1) NOT NULL DEFAULT '0',
  `counts_as_workload` tinyint(1) NOT NULL DEFAULT '0',
  `is_break` tinyint(1) NOT NULL DEFAULT '0',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_periodtype_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_teacher_assignment_roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_primary_instructor` tinyint(1) NOT NULL DEFAULT '0',
  `counts_for_workload` tinyint(1) NOT NULL DEFAULT '1',
  `allows_overlap` tinyint(1) NOT NULL DEFAULT '0',
  `workload_factor` decimal(3,2) NOT NULL DEFAULT '1.00',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tarole_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_school_days` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `ordinal` smallint unsigned NOT NULL,
  `is_school_day` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_schoolday_code` (`code`),
  UNIQUE KEY `uq_schoolday_dow` (`day_of_week`),
  KEY `idx_schoolday_ordinal` (`ordinal`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_working_day` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `day_type_id` bigint unsigned NOT NULL,
  `is_school_day` tinyint(1) NOT NULL DEFAULT '1',
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_workday_date_daytype` (`date`,`day_type_id`),
  KEY `idx_workday_daytype` (`day_type_id`),
  CONSTRAINT `idx_workday_daytype` FOREIGN KEY (`day_type_id`) REFERENCES `tt_day_types` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_sets` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_periods` tinyint unsigned NOT NULL,
  `teaching_periods` tinyint unsigned NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `applicable_class_ids` json DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_periodset_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_period_set_period_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `period_set_id` bigint unsigned NOT NULL,
  `period_type_id` bigint unsigned NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `period_ord` tinyint unsigned NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `duration_minutes` smallint unsigned GENERATED ALWAYS AS (timestampdiff(MINUTE,`start_time`,`end_time`)) STORED,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_psp_set_ord` (`period_set_id`,`period_ord`),
  UNIQUE KEY `uq_psp_set_code` (`period_set_id`,`code`),
  KEY `idx_psp_type` (`period_type_id`),
  CONSTRAINT `tt_period_set_period_jnt_period_set_id_foreign` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_period_set_period_jnt_period_type_id_foreign` FOREIGN KEY (`period_type_id`) REFERENCES `tt_period_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `chk_psp_time` CHECK ((`end_time` > `start_time`))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `shift_id` bigint unsigned DEFAULT NULL,
  `default_period_set_id` bigint unsigned DEFAULT NULL,
  `day_type_id` bigint unsigned DEFAULT NULL,
  `effective_from_date` date DEFAULT NULL,
  `effective_to_date` date DEFAULT NULL,
  `school_start_time` time DEFAULT NULL,
  `school_end_time` time DEFAULT NULL,
  `assembly_duration_min` smallint unsigned DEFAULT NULL,
  `short_break_duration_min` smallint unsigned DEFAULT NULL,
  `lunch_duration_min` smallint unsigned DEFAULT NULL,
  `has_exam` tinyint(1) NOT NULL DEFAULT '0',
  `has_teaching` tinyint(1) NOT NULL DEFAULT '1',
  `ordinal` smallint unsigned NOT NULL DEFAULT '1',
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tttype_code` (`code`),
  KEY `idx_tttype_shift` (`shift_id`),
  KEY `tt_timetable_types_default_period_set_id_foreign` (`default_period_set_id`),
  KEY `tt_timetable_types_day_type_id_foreign` (`day_type_id`),
  KEY `idx_tttype_effective` (`effective_from_date`,`effective_to_date`),
  CONSTRAINT `idx_tttype_shift` FOREIGN KEY (`shift_id`) REFERENCES `tt_shifts` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_types_day_type_id_foreign` FOREIGN KEY (`day_type_id`) REFERENCES `tt_day_types` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_types_default_period_set_id_foreign` FOREIGN KEY (`default_period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_mode_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_id` bigint unsigned NOT NULL,
  `timetable_mode_id` bigint unsigned NOT NULL,
  `period_set_id` bigint unsigned NOT NULL,
  `allow_teaching_periods` tinyint(1) NOT NULL DEFAULT '1',
  `allow_exam_periods` tinyint(1) NOT NULL DEFAULT '0',
  `exam_period_count` tinyint unsigned DEFAULT NULL,
  `teaching_after_exam_flag` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cmr_class_mode` (`class_id`,`timetable_mode_id`),
  KEY `tt_class_mode_rules_timetable_mode_id_foreign` (`timetable_mode_id`),
  KEY `tt_class_mode_rules_period_set_id_foreign` (`period_set_id`),
  CONSTRAINT `tt_class_mode_rules_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_mode_rules_period_set_id_foreign` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_mode_rules_timetable_mode_id_foreign` FOREIGN KEY (`timetable_mode_id`) REFERENCES `tt_timetable_modes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_subgroups` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `class_group_id` bigint unsigned DEFAULT NULL,
  `subgroup_type` enum('OPTIONAL_SUBJECT','HOBBY','SKILL','LANGUAGE','STREAM','ACTIVITY','SPORTS','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OTHER',
  `student_count` int unsigned DEFAULT NULL,
  `min_students` int unsigned DEFAULT NULL,
  `max_students` int unsigned DEFAULT NULL,
  `is_shared_across_sections` tinyint(1) NOT NULL DEFAULT '0',
  `is_shared_across_classes` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subgroup_code` (`code`),
  KEY `tt_class_subgroups_class_group_id_foreign` (`class_group_id`),
  KEY `idx_subgroup_type` (`subgroup_type`),
  CONSTRAINT `tt_class_subgroups_class_group_id_foreign` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_subgroup_members` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_subgroup_id` bigint unsigned NOT NULL,
  `class_id` bigint unsigned NOT NULL,
  `section_id` bigint unsigned DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_csm_subgroup_class_section` (`class_subgroup_id`,`class_id`,`section_id`),
  KEY `tt_class_subgroup_members_class_id_foreign` (`class_id`),
  KEY `tt_class_subgroup_members_section_id_foreign` (`section_id`),
  CONSTRAINT `tt_class_subgroup_members_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_subgroup_members_class_subgroup_id_foreign` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_subgroup_members_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_class_groups_jnt` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_id` bigint unsigned NOT NULL,
  `section_id` bigint unsigned NOT NULL,
  `subject_study_format_id` bigint unsigned NOT NULL,
  `subject_type_id` bigint unsigned NOT NULL,
  `rooms_type_id` bigint unsigned NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` char(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`,`section_id`,`subject_study_format_id`,`subject_type_id`),
  UNIQUE KEY `uq_classGroups_subStdformatCode` (`code`),
  KEY `tt_class_groups_jnt_section_id_foreign` (`section_id`),
  KEY `tt_class_groups_jnt_subject_study_format_id_foreign` (`subject_study_format_id`),
  KEY `tt_class_groups_jnt_subject_type_id_foreign` (`subject_type_id`),
  KEY `tt_class_groups_jnt_rooms_type_id_foreign` (`rooms_type_id`),
  CONSTRAINT `tt_class_groups_jnt_class_id_foreign` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_groups_jnt_rooms_type_id_foreign` FOREIGN KEY (`rooms_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_groups_jnt_section_id_foreign` FOREIGN KEY (`section_id`) REFERENCES `sch_sections` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_groups_jnt_subject_study_format_id_foreign` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_class_groups_jnt_subject_type_id_foreign` FOREIGN KEY (`subject_type_id`) REFERENCES `sch_subject_types` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------
--  SECTION 2: CONSTRAINT ENGINE
-- -------------------------------------------------
CREATE TABLE `tt_constraint_types` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `category` enum('TIME','SPACE','TEACHER','STUDENT','ACTIVITY','ROOM') COLLATE utf8mb4_unicode_ci NOT NULL,
  `scope` enum('GLOBAL','TEACHER','STUDENT','ROOM','ACTIVITY','CLASS','CLASS_SUBJECT','STUDY_FORMAT','SUBJECT','STUDENT_SET','CLASS_GROUP','CLASS_SUBGROUP') COLLATE utf8mb4_unicode_ci NOT NULL,
  `default_weight` tinyint unsigned NOT NULL DEFAULT '100',
  `is_hard_capable` tinyint(1) NOT NULL DEFAULT '1',
  `param_schema` json DEFAULT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ctype_code` (`code`),
  KEY `idx_ctype_category` (`category`),
  KEY `idx_ctype_scope` (`scope`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_constraints` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `constraint_type_id` bigint unsigned NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `academic_session_id` bigint unsigned NOT NULL,
  `target_type` enum('GLOBAL','TEACHER','STUDENT_SET','ROOM','ACTIVITY','CLASS','SUBJECT','STUDY_FORMAT','CLASS_GROUP','CLASS_SUBGROUP') COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_id` bigint unsigned DEFAULT NULL,
  `is_hard` tinyint(1) NOT NULL DEFAULT '0',
  `weight` tinyint unsigned NOT NULL DEFAULT '100',
  `params_json` json NOT NULL,
  `effective_from` date DEFAULT NULL,
  `effective_to` date DEFAULT NULL,
  `applies_to_days_json` json DEFAULT NULL,
  `status` enum('DRAFT','ACTIVE','DISABLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_constraint_uuid` (`uuid`),
  KEY `idx_constraint_type` (`constraint_type_id`),
  KEY `tt_constraints_academic_session_id_foreign` (`academic_session_id`),
  KEY `tt_constraints_created_by_foreign` (`created_by`),
  KEY `idx_constraint_target` (`target_type`,`target_id`),
  KEY `idx_constraint_status` (`status`),
  CONSTRAINT `idx_constraint_type` FOREIGN KEY (`constraint_type_id`) REFERENCES `tt_constraint_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_constraints_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_constraints_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_teacher_unavailables` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `teacher_id` bigint unsigned NOT NULL,
  `constraint_id` bigint unsigned DEFAULT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `period_ord` tinyint unsigned DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_recurring` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tu_teacher` (`teacher_id`),
  KEY `tt_teacher_unavailables_constraint_id_foreign` (`constraint_id`),
  KEY `idx_tu_day_period` (`day_of_week`,`period_ord`),
  CONSTRAINT `idx_tu_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_teacher_unavailables_constraint_id_foreign` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_room_unavailables` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `room_id` bigint unsigned NOT NULL,
  `constraint_id` bigint unsigned DEFAULT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `period_ord` tinyint unsigned DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_recurring` tinyint(1) NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ru_room` (`room_id`),
  KEY `tt_room_unavailables_constraint_id_foreign` (`constraint_id`),
  KEY `idx_ru_day_period` (`day_of_week`,`period_ord`),
  CONSTRAINT `idx_ru_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_room_unavailables_constraint_id_foreign` FOREIGN KEY (`constraint_id`) REFERENCES `tt_constraints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------
--  SECTION 3: TIMETABLE OPERATION TABLES
-- -------------------------------------------------
CREATE TABLE `tt_class_group_requirements` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `class_group_id` bigint unsigned DEFAULT NULL,
  `class_subgroup_id` bigint unsigned DEFAULT NULL,
  `academic_session_id` bigint unsigned NOT NULL,
  `weekly_periods` tinyint unsigned NOT NULL,
  `min_periods_per_week` tinyint unsigned DEFAULT NULL,
  `max_periods_per_week` tinyint unsigned DEFAULT NULL,
  `max_per_day` tinyint unsigned DEFAULT NULL,
  `min_per_day` tinyint unsigned DEFAULT NULL,
  `min_gap_periods` tinyint unsigned DEFAULT NULL,
  `allow_consecutive` tinyint(1) NOT NULL DEFAULT '0',
  `max_consecutive` tinyint unsigned NOT NULL DEFAULT '2',
  `preferred_periods_json` json DEFAULT NULL,
  `avoid_periods_json` json DEFAULT NULL,
  `spread_evenly` tinyint(1) NOT NULL DEFAULT '1',
  `priority` smallint unsigned NOT NULL DEFAULT '50',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cgr_group_session` (`class_group_id`,`class_subgroup_id`,`academic_session_id`),
  KEY `tt_class_group_requirements_class_subgroup_id_foreign` (`class_subgroup_id`),
  KEY `tt_class_group_requirements_academic_session_id_foreign` (`academic_session_id`),
  CONSTRAINT `tt_class_group_requirements_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_class_group_requirements_class_group_id_foreign` FOREIGN KEY (`class_group_id`) REFERENCES `tt_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_class_group_requirements_class_subgroup_id_foreign` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_cgr_target` CHECK ((((`class_group_id` is not null) and (`class_subgroup_id` is null)) or ((`class_group_id` is null) and (`class_subgroup_id` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_activities` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `academic_session_id` bigint unsigned NOT NULL,
  `class_group_jnt_id` bigint unsigned DEFAULT NULL,
  `class_subgroup_id` bigint unsigned DEFAULT NULL,
  `duration_periods` tinyint unsigned NOT NULL DEFAULT '1',
  `weekly_periods` tinyint unsigned NOT NULL DEFAULT '1',
  `total_periods` smallint unsigned GENERATED ALWAYS AS ((`duration_periods` * `weekly_periods`)) STORED,
  `split_allowed` tinyint(1) NOT NULL DEFAULT '0',
  `is_compulsory` tinyint(1) NOT NULL DEFAULT '1',
  `priority` tinyint unsigned NOT NULL DEFAULT '50',
  `difficulty_score` tinyint unsigned NOT NULL DEFAULT '50',
  `requires_room` tinyint(1) NOT NULL DEFAULT '1',
  `preferred_room_type_id` bigint unsigned DEFAULT NULL,
  `preferred_room_ids` json DEFAULT NULL,
  `status` enum('DRAFT','ACTIVE','LOCKED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_activity_uuid` (`uuid`),
  UNIQUE KEY `uq_activity_code` (`code`),
  KEY `tt_activities_academic_session_id_foreign` (`academic_session_id`),
  KEY `idx_activity_class_group` (`class_group_jnt_id`),
  KEY `idx_activity_subgroup` (`class_subgroup_id`),
  KEY `tt_activities_preferred_room_type_id_foreign` (`preferred_room_type_id`),
  KEY `tt_activities_created_by_foreign` (`created_by`),
  KEY `idx_activity_status` (`status`),
  CONSTRAINT `idx_activity_class_group` FOREIGN KEY (`class_group_jnt_id`) REFERENCES `tt_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `idx_activity_subgroup` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_activities_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_activities_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_activities_preferred_room_type_id_foreign` FOREIGN KEY (`preferred_room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_activity_target` CHECK ((((`class_group_jnt_id` is not null) and (`class_subgroup_id` is null)) or ((`class_group_jnt_id` is null) and (`class_subgroup_id` is not null))))
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_activity_teachers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `activity_id` bigint unsigned NOT NULL,
  `teacher_id` bigint unsigned NOT NULL,
  `assignment_role_id` bigint unsigned NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT '1',
  `ordinal` tinyint unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tt_activity_teachers_activity_id_foreign` (`activity_id`),
  KEY `idx_at_teacher` (`teacher_id`),
  KEY `tt_activity_teachers_assignment_role_id_foreign` (`assignment_role_id`),
  CONSTRAINT `idx_at_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_activity_teachers_activity_id_foreign` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_activity_teachers_assignment_role_id_foreign` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_sub_activities` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `parent_activity_id` bigint unsigned NOT NULL,
  `sub_activity_ord` tinyint unsigned NOT NULL,
  `code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `duration_periods` tinyint unsigned NOT NULL DEFAULT '1',
  `same_day_as_parent` tinyint(1) NOT NULL DEFAULT '0',
  `consecutive_with_previous` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_subact_parent_ord` (`parent_activity_id`,`sub_activity_ord`),
  UNIQUE KEY `uq_subact_code` (`code`),
  CONSTRAINT `tt_sub_activities_parent_activity_id_foreign` FOREIGN KEY (`parent_activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- -------------------------------------------------
--  SECTION 4: TIMETABLE GENERATION TABLES
-- -------------------------------------------------
CREATE TABLE `tt_timetables` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `academic_session_id` bigint unsigned NOT NULL,
  `timetable_type_id` bigint unsigned NOT NULL,
  `period_set_id` bigint unsigned NOT NULL,
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `generation_method` enum('MANUAL','SEMI_AUTO','FULL_AUTO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MANUAL',
  `version` smallint unsigned NOT NULL DEFAULT '1',
  `parent_timetable_id` bigint unsigned DEFAULT NULL,
  `status` enum('DRAFT','GENERATING','GENERATED','PUBLISHED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `published_at` timestamp NULL DEFAULT NULL,
  `published_by` bigint unsigned DEFAULT NULL,
  `constraint_violations` int unsigned NOT NULL DEFAULT '0',
  `soft_score` decimal(8,2) DEFAULT NULL,
  `stats_json` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tt_uuid` (`uuid`),
  UNIQUE KEY `uq_tt_code` (`code`),
  KEY `tt_timetables_academic_session_id_foreign` (`academic_session_id`),
  KEY `idx_tt_type` (`timetable_type_id`),
  KEY `tt_timetables_period_set_id_foreign` (`period_set_id`),
  KEY `tt_timetables_parent_timetable_id_foreign` (`parent_timetable_id`),
  KEY `tt_timetables_published_by_foreign` (`published_by`),
  KEY `tt_timetables_created_by_foreign` (`created_by`),
  KEY `idx_tt_effective` (`effective_from`,`effective_to`),
  KEY `idx_tt_status` (`status`),
  CONSTRAINT `idx_tt_type` FOREIGN KEY (`timetable_type_id`) REFERENCES `tt_timetable_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetables_academic_session_id_foreign` FOREIGN KEY (`academic_session_id`) REFERENCES `global_master`.`glb_academic_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetables_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetables_parent_timetable_id_foreign` FOREIGN KEY (`parent_timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetables_period_set_id_foreign` FOREIGN KEY (`period_set_id`) REFERENCES `tt_period_sets` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetables_published_by_foreign` FOREIGN KEY (`published_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

- Missing Table - tt_constraint_violation

CREATE TABLE `tt_generation_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varbinary(16) NOT NULL,
  `timetable_id` bigint unsigned NOT NULL,
  `run_number` int unsigned NOT NULL DEFAULT '1',
  `started_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` timestamp NULL DEFAULT NULL,
  `status` enum('QUEUED','RUNNING','COMPLETED','FAILED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QUEUED',
  `algorithm_version` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `max_recursion_depth` int unsigned NOT NULL DEFAULT '14',
  `max_placement_attempts` int unsigned DEFAULT NULL,
  `params_json` json DEFAULT NULL,
  `activities_total` int unsigned NOT NULL DEFAULT '0',
  `activities_placed` int unsigned NOT NULL DEFAULT '0',
  `activities_failed` int unsigned NOT NULL DEFAULT '0',
  `hard_violations` int unsigned NOT NULL DEFAULT '0',
  `soft_violations` int unsigned NOT NULL DEFAULT '0',
  `soft_score` decimal(10,4) DEFAULT NULL,
  `stats_json` json DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_gr_tt_run` (`timetable_id`,`run_number`),
  UNIQUE KEY `uq_gr_uuid` (`uuid`),
  KEY `tt_generation_runs_triggered_by_foreign` (`triggered_by`),
  KEY `idx_gr_status` (`status`),
  CONSTRAINT `tt_generation_runs_timetable_id_foreign` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_generation_runs_triggered_by_foreign` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_cells` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `timetable_id` bigint unsigned NOT NULL,
  `generation_run_id` bigint unsigned DEFAULT NULL,
  `day_of_week` tinyint unsigned NOT NULL,
  `period_ord` tinyint unsigned NOT NULL,
  `cell_date` date DEFAULT NULL,
  `class_group_id` bigint unsigned DEFAULT NULL,
  `class_subgroup_id` bigint unsigned DEFAULT NULL,
  `activity_id` bigint unsigned DEFAULT NULL,
  `sub_activity_id` bigint unsigned DEFAULT NULL,
  `room_id` bigint unsigned DEFAULT NULL,
  `source` enum('AUTO','MANUAL','SWAP','LOCK') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AUTO',
  `is_locked` tinyint(1) NOT NULL DEFAULT '0',
  `locked_by` bigint unsigned DEFAULT NULL,
  `locked_at` timestamp NULL DEFAULT NULL,
  `has_conflict` tinyint(1) NOT NULL DEFAULT '0',
  `conflict_details_json` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cell_tt_day_period_group` (`timetable_id`,`day_of_week`,`period_ord`,`class_group_id`,`class_subgroup_id`),
  KEY `tt_timetable_cells_generation_run_id_foreign` (`generation_run_id`),
  KEY `tt_timetable_cells_class_group_id_foreign` (`class_group_id`),
  KEY `tt_timetable_cells_class_subgroup_id_foreign` (`class_subgroup_id`),
  KEY `idx_cell_activity` (`activity_id`),
  KEY `tt_timetable_cells_sub_activity_id_foreign` (`sub_activity_id`),
  KEY `idx_cell_room` (`room_id`),
  KEY `tt_timetable_cells_locked_by_foreign` (`locked_by`),
  KEY `idx_cell_day_period` (`day_of_week`,`period_ord`),
  KEY `idx_cell_date` (`cell_date`),
  CONSTRAINT `idx_cell_activity` FOREIGN KEY (`activity_id`) REFERENCES `tt_activities` (`id`) ON DELETE SET NULL,
  CONSTRAINT `idx_cell_room` FOREIGN KEY (`room_id`) REFERENCES `sch_rooms` (`id`) ON DELETE SET NULL,
  CONSTRAINT `idx_cell_tt` FOREIGN KEY (`timetable_id`) REFERENCES `tt_timetables` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cells_class_group_id_foreign` FOREIGN KEY (`class_group_id`) REFERENCES `sch_class_groups_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cells_class_subgroup_id_foreign` FOREIGN KEY (`class_subgroup_id`) REFERENCES `tt_class_subgroups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cells_generation_run_id_foreign` FOREIGN KEY (`generation_run_id`) REFERENCES `tt_generation_runs` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_cells_locked_by_foreign` FOREIGN KEY (`locked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tt_timetable_cells_sub_activity_id_foreign` FOREIGN KEY (`sub_activity_id`) REFERENCES `tt_sub_activities` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_cell_target` CHECK ((((`class_group_id` is not null) and (`class_subgroup_id` is null)) or ((`class_group_id` is null) and (`class_subgroup_id` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `tt_timetable_cell_teachers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cell_id` bigint unsigned NOT NULL,
  `teacher_id` bigint unsigned NOT NULL,
  `assignment_role_id` bigint unsigned NOT NULL,
  `is_substitute` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cct_cell_teacher` (`cell_id`,`teacher_id`),
  KEY `idx_cct_teacher` (`teacher_id`),
  KEY `tt_timetable_cell_teachers_assignment_role_id_foreign` (`assignment_role_id`),
  CONSTRAINT `idx_cct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `sch_teachers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tt_timetable_cell_teachers_assignment_role_id_foreign` FOREIGN KEY (`assignment_role_id`) REFERENCES `tt_teacher_assignment_roles` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `tt_timetable_cell_teachers_cell_id_foreign` FOREIGN KEY (`cell_id`) REFERENCES `tt_timetable_cells` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -------------------------------------------------
--  SECTION 5: TIMETABLE REPORTS
-- -------------------------------------------------


-- -------------------------------------------------
--  SECTION 6: SUBSTITUTION MANAGEMENT
-- -------------------------------------------------


-- -------------------------------------------------
--  REFERENCE TABLES FROM OTHER MODULE
-- -------------------------------------------------

