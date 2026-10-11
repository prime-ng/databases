STANDARD CONSTRAINT CATALOG (ENTERPRISE-GRADE)
==============================================

This is the authoritative list of constraint types that your Timetable Engine will support, all stored in ONE table: tt_constraint.

Each constraint is defined by:
	- target_type
	- rule_json.type
    - rule_json
    - is_hard
    - weight
    - is_active
    
Required parameters
    - Hard / Soft nature

Typical usage

A. TEACHER-LEVEL CONSTRAINTS
1. MAX_PERIODS_PER_DAY
    { "type": "MAX_PERIODS_PER_DAY", "value": 5 }

    Target: TEACHER
    Hard / Soft: Hard
    Meaning: Teacher cannot teach more than N periods/day

2. MAX_PERIODS_PER_WEEK
    { "type": "MAX_PERIODS_PER_WEEK", "value": 28 }

    Prevents overload
    Used for workload balancing

3. MAX_CONSECUTIVE_PERIODS
    { "type": "MAX_CONSECUTIVE_PERIODS", "value": 2 }

    Common for senior teachers

4. NO_CONSECUTIVE_PERIODS
    { "type": "NO_CONSECUTIVE_PERIODS", "value": true }

    Teacher must have a break between classes

5. UNAVAILABLE_PERIODS
    {
    "type": "UNAVAILABLE_PERIODS",
    "days": ["MON","WED"],
    "periods": [1,2]
    }

    Teacher not available in specific slots

6. PREFERRED_FREE_DAY
    { "type": "PREFERRED_FREE_DAY", "day": "FRI" }

    Soft constraint

    Used for optimization, not rejection

🔹 B. CLASS / SUBJECT (CLASS_GROUP) CONSTRAINTS
7. WEEKLY_PERIODS
    { "type": "WEEKLY_PERIODS", "value": 6 }

    Usually comes from tt_class_group_requirement

    Still evaluated as constraint

8. MAX_PERIODS_PER_DAY
    { "type": "MAX_PERIODS_PER_DAY", "value": 2 }

    Example: Maths not more than twice a day

9. NOT_FIRST_PERIOD
    { "type": "NOT_FIRST_PERIOD", "value": true }

    Avoid heavy subjects early morning

10. NOT_LAST_PERIOD
    { "type": "NOT_LAST_PERIOD", "value": true }

11. CONSECUTIVE_REQUIRED
    { "type": "CONSECUTIVE_REQUIRED", "count": 2 }

    Mandatory for labs / practicals

12. MIN_GAP_BETWEEN_CLASSES
    { "type": "MIN_GAP", "value": 1 }

    Avoids back-to-back same subject

🔹 C. ROOM-LEVEL CONSTRAINTS
13. ROOM_UNAVAILABLE
    {
    "type": "ROOM_UNAVAILABLE",
    "dates": ["2025-09-15"],
    "periods": [3,4]
    }

14. MAX_ROOM_USAGE_PER_DAY
    { "type": "MAX_ROOM_USAGE_PER_DAY", "value": 6 }

15. ROOM_EXCLUSIVE_USE
    { "type": "ROOM_EXCLUSIVE_USE", "value": true }

    No overlapping usage

🔹 D. MODE / EXAM-RELATED CONSTRAINTS
16. EXAM_ONLY_PERIODS
    { "type": "EXAM_ONLY_PERIODS", "periods": [1,2,3] }

17. NO_TEACHING_AFTER_EXAM
    { "type": "NO_TEACHING_AFTER_EXAM", "value": true }

    Reinforces teaching_after_exam_flag

18. EXAM_CUTOFF_TIME
    { "type": "EXAM_CUTOFF_TIME", "value": "12:00" }


🔹 E. GLOBAL / POLICY CONSTRAINTS
19. FIXED_PERIOD
    {
    "type": "FIXED_PERIOD",
    "day": "MON",
    "period": 1
    }

    Assembly / Prayer

20. NO_CLASSES_ON_DATE
    { "type": "NO_CLASSES_ON_DATE", "date": "2025-10-02" }

21. MAX_TEACHING_DAYS_PER_WEEK
    { "type": "MAX_TEACHING_DAYS", "value": 5 }


🔹 F. OPTIONAL / OPTIMIZATION (SOFT) CONSTRAINTS
22. PREFER_MORNING_CLASSES
    { "type": "PREFER_MORNING_CLASSES" }

23. PREFER_SAME_ROOM
    { "type": "PREFER_SAME_ROOM" }

24. BALANCED_DISTRIBUTION
    { "type": "BALANCED_DISTRIBUTION" }


Spreads classes evenly across week

How ALL of these fit into ONE TABLE
tt_constraint
-------------
target_type = TEACHER / CLASS_GROUP / ROOM / GLOBAL
target_id   = entity id (or NULL)
rule_json   = one of the above JSON blocks
is_hard     = 1 / 0
weight      = importance score


No schema change needed ever again.



----------------------------------------------------------------------------
I want to update tt_class_requirement_subgroups.student_count 

update tt_class_requirement_subgroups.student_count = Select count(std_student_academic_sessions.id) from std_student_academic_sessions where 
std_student_academic_sessions.subject_group_id = sch_subject_groups.id AND
sch_subject_group_subject_jnt.subject_group_id = sch_subject_groups.id AND
sch_subject_groups.class_id = tt_class_requirement_subgroups.class_id AND
sch_subject_groups.section_id = tt_class_requirement_subgroups.section_id AND
sch_subject_group_subject_jnt.subject_study_format_id = tt_class_requirement_subgroups.subject_study_format_id AND


  -- changed below Table name to - `tt_requirement_subgroups` from `tt_class_subgroup`
  CREATE TABLE IF NOT EXISTS `tt_class_requirement_subgroups` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,                                 -- Copy from sch_class_groups_jnt.code
    `name` VARCHAR(100) NOT NULL,                                -- Copy from sch_class_groups_jnt.name
    `class_group_id` INT unsigned NOT NULL,                      -- FK to sch_class_groups.id
    -- Key Field to apply Constraints
    `class_id` INT unsigned NOT NULL,                            -- FK to sch_classes.id
    `section_id` INT unsigned DEFAULT NULL,                      -- FK to sch_sections.id
    `subject_id` INT unsigned NOT NULL,                            -- FK to sch_subjects.id
    `study_format_id` INT unsigned NOT NULL,                       -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    `subject_type_id` INT unsigned NOT NULL,                       -- FK to sch_subject_types.id. e.g MAJOR, MINOR, OPTIONAL, etc.
    `subject_study_format_id` INT unsigned NOT NULL,               -- FK to sch_study_formats.id. e.g SCI_LEC, SCI_LAB, COM_LEC, COM_OPT, etc.
    -- Info Collected from diffrent Tables
    `class_house_room_id` INT UNSIGNED NOT NULL,                 -- FK to 'sch_rooms' (Added new). (Fetch from sch_class_section_jnt)
    `student_count` INT UNSIGNED DEFAULT NULL,                   -- Number of students in this subgroup
    `eligible_teacher_count` INT UNSIGNED DEFAULT NULL,          -- Number of teachers available for this group (Will capture from Teachers profile)
    -- Only below 2 parameter can be modified at tt_class_requirement_subgroups screen
    `is_shared_across_sections` TINYINT(1) NOT NULL DEFAULT 0,   -- Whether this subgroup is shared across sections
    `is_shared_across_classes` TINYINT(1) NOT NULL DEFAULT 0,    -- Whether this subgroup is shared across classes
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_subgroup_code` (`code`),
    UNIQUE KEY `uq_classGroup_subStdFmt_class_section_subjectType` (`class_id`,`section_id`,`sub_stdy_frmt_id`),
    KEY `idx_subgroup_type` (`subgroup_type`),
    CONSTRAINT `fk_subgroup_class_group` FOREIGN KEY (`class_subject_group_id`) REFERENCES `tt_class_subject_groups` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `std_student_academic_sessions` (
    `id` INT UNSIGNED AUTO_INCREMENT,
    `student_id` INT UNSIGNED NOT NULL,
    -- Academic Session
    `academic_session_id` INT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions (or sch_org_academic_sessions_jnt)
    `class_section_id` INT UNSIGNED NOT NULL,         -- FK to sch_class_section_jnt
    `roll_no` INT UNSIGNED DEFAULT NULL,
    `subject_group_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_subject_groups (if streams apply)
    -- Other Detail
    `house` INT UNSIGNED DEFAULT NULL,             -- FK to sys_dropdown_table
    `is_current` TINYINT(1) DEFAULT 0,                -- Only one active record per student
    `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
    `session_status_id` INT UNSIGNED NOT NULL DEFAULT 'ACTIVE',    -- FK to sys_dropdown_table (PROMOTED, ACTIVE, LEFT, SUSPENDED, ALUMNI, WITHDRAWN)
    `leaving_date` DATE DEFAULT NULL,
    `count_as_attrition` TINYINT(1) NOT NULL,         -- Can we count this record as Attrition
    `reason_quit` int NULL,                           -- FK to `sys_dropdown_table` (Reason for leaving the Session)
    -- Note
    `dis_note` text NOT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`),
    UNIQUE KEY `uq_std_acad_sess_student_session` (`student_id`, `academic_session_id`),
    CONSTRAINT `fk_sas_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sas_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sas_class_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sas_subj_group` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sas_status` FOREIGN KEY (`session_status_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

Provide Select to update student_count in tt_class_requirement_subgroups