-- ===========================================================================
-- 3.3 - EMPLOYEE SETUP SUB-MODULE (sch)
-- ===========================================================================

  -- Teacher table will store additional information about teachers
  CREATE TABLE IF NOT EXISTS `sch_employees` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INT UNSIGNED NOT NULL,  -- fk to sys_users.id
    -- Employee id details
    `emp_code` VARCHAR(20) NOT NULL,     -- Employee Code (Unique code for each user) (This will be used for QR Code)
    `emp_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `emp_smart_card_id` VARCHAR(100) DEFAULT NULL,       -- RFID/NFC Tag ID
    -- 
    `is_teacher` TINYINT(1) NOT NULL DEFAULT 0,
    `joining_date` DATE NOT NULL,
    `total_experience_years` DECIMAL(4,1) DEFAULT NULL,       -- Total teaching experience
    `highest_qualification` VARCHAR(100) DEFAULT NULL,        -- e.g. M.Sc., Ph.D.
    `specialization` VARCHAR(150) DEFAULT NULL,               -- e.g. Mathematics, Physics
    `last_institution` VARCHAR(200) DEFAULT NULL,             -- e.g. DPS Delhi
    `awards` TEXT DEFAULT NULL,                               -- brief summary
    `skills` TEXT DEFAULT NULL,                               -- general skills list (comma/JSON)
    `qualifications_json` JSON DEFAULT NULL,   -- Array of {degree, specialization, university, year, grade}
    `certifications_json` JSON DEFAULT NULL,   -- Array of {name, issued_by, issue_date, expiry_date, verified}
    `experiences_json` JSON DEFAULT NULL,      -- Array of {institution, role, from_date, to_date, subject, remarks}
    `notes` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `teachers_emp_code_unique` (`emp_code`),
    KEY `teachers_user_id_foreign` (`user_id`),
    CONSTRAINT `fk_teachers_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_employees_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id` INT UNSIGNED NOT NULL,              -- FK to sch_employees.id
    `user_id` INT UNSIGNED NOT NULL,                  -- FK to sys_users.id
    `role_id` INT UNSIGNED NOT NULL,                  -- FK to employee_roles table (Principal, Accountant, Admin, etc.)
    `department_id` INT UNSIGNED DEFAULT NULL,        -- FK to sch_departments (Administration, Accounts, IT, etc.)
    -- Core Competencies & Qualifications
    `specialization_area` VARCHAR(100) DEFAULT NULL,     -- e.g., Finance Management, HR Administration, IT Infrastructure
    `qualification_level` VARCHAR(50) DEFAULT NULL,      -- e.g., Bachelor's, Master's, Certified Accountant
    `qualification_field` VARCHAR(100) DEFAULT NULL,     -- e.g., Business Administration, Computer Science
    `certifications` JSON DEFAULT NULL,                  -- JSON array of certifications: ["CPA", "CISSP", "PMP"]
    -- Work Capacity & Availability
    `work_hours_daily` DECIMAL(4,2) DEFAULT 8.0,         -- Standard daily work hours
    `max_hours_daily` DECIMAL(4,2) DEFAULT 10.0,         -- Maximum daily work hours
    `work_hours_weekly` DECIMAL(5,2) DEFAULT 40.0,       -- Standard weekly work hours
    `max_hours_weekly` DECIMAL(5,2) DEFAULT 50.0,        -- Maximum weekly work hours
    `preferred_shift` ENUM('morning', 'evening', 'flexible') DEFAULT 'morning',
    `is_full_time` TINYINT(1) DEFAULT 1,                 -- 1=Full-time, 0=Part-time
    -- Skills & Responsibilities (JSON for flexibility)
    `core_responsibilities` JSON DEFAULT NULL,           -- e.g., ["budget_management", "staff_supervision", "policy_implementation"]
    `technical_skills` JSON DEFAULT NULL,                -- e.g., ["quickbooks", "ms_expert", "erp_systems"]
    `soft_skills` JSON DEFAULT NULL,                     -- e.g., ["leadership", "communication", "problem_solving"]
    -- Performance & Experience
    `experience_months` SMALLINT UNSIGNED DEFAULT NULL,  -- Relevant experience in months
    `performance_rating` TINYINT UNSIGNED DEFAULT NULL,  -- rating out of (1 to 10)
    `last_performance_review` DATE DEFAULT NULL,
    -- Administrative Controls
    `security_clearance_done` TINYINT(1) DEFAULT 0,
    `reporting_to` INT UNSIGNED DEFAULT NULL,         -- FK to sch_employees.id (who they report to)
    `can_approve_budget` TINYINT(1) DEFAULT 0,
    `can_manage_staff` TINYINT(1) DEFAULT 0,
    `can_access_sensitive_data` TINYINT(1) DEFAULT 0,
    -- Additional Details
    `assignment_meta` JSON DEFAULT NULL,                 -- e.g., { "previous_role": "Assistant Principal", "achievements": ["System Upgrade 2023"] }
    `notes` TEXT DEFAULT NULL,
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_employee_role_active` (`employee_id`, `role_id`, `effective_to`),
    -- Foreign Key Constraints
    CONSTRAINT `fk_employeeProfile_employeeId` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`),
    CONSTRAINT `fk_employeeProfile_roleId` FOREIGN KEY (`role_id`) REFERENCES `sch_employee_roles` (`id`),
    CONSTRAINT `fk_employeeProfile_departmentId` FOREIGN KEY (`department_id`) REFERENCES `sch_departments` (`id`),
    CONSTRAINT `fk_employeeProfile_reportingTo` FOREIGN KEY (`reporting_to`) REFERENCES `sch_employees` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Teacher Profile table will store detailed proficiency to teach specific subjects, study formats, and classes
  CREATE TABLE IF NOT EXISTS `sch_teacher_profile` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `employee_id` INT UNSIGNED NOT NULL,             -- FK sch_employees.id
    `user_id` INT UNSIGNED NOT NULL,                 -- FK sys_users.id
    `role_id` INT UNSIGNED NOT NULL,                 -- FK to   Teacher / Principal / etc.
    `department_id` INT UNSIGNED NOT NULL,           -- sch_department.id 
    `designation_id` INT UNSIGNED NOT NULL,          -- sch_designation.id
    `teacher_house_room_id` INT UNSIGNED DEFAULT NULL,  -- FK to sch_rooms.id
    -- Employment nature & capability
    `is_full_time` TINYINT(1) DEFAULT 1,
    `preferred_shift` INT UNSIGNED DEFAULT NULL,    -- FK to sch_shift.id
    `capable_handling_multiple_classes` TINYINT(1) DEFAULT 0,
    `can_be_used_for_substitution` TINYINT(1) DEFAULT 1,
    -- Skills & Responsibilities (JSON for flexibility)
    `certified_for_lab` TINYINT(1) DEFAULT 0,          -- allowed to conduct practicals
    `is_proficient_with_computer` TINYINT(1) DEFAULT 0,
    `can_manage_staff` TINYINT(1) DEFAULT 0,
    `special_skill_area` VARCHAR(100) DEFAULT NULL,
    `soft_skills` JSON DEFAULT NULL,                     -- e.g., ["leadership", "communication", "problem_solving"]
    `assignment_meta` JSON DEFAULT NULL,                 -- e.g. { "qualification": "M.Sc Physics", "experience": "7 years" }
    -- LOAD & SCHEDULING CONSTRAINTS
    `max_periods_daily` TINYINT UNSIGNED DEFAULT 6,
    `min_periods_daily` TINYINT UNSIGNED DEFAULT 1,
    `max_periods_weekly` TINYINT UNSIGNED DEFAULT 48,
    `min_periods_weekly` TINYINT UNSIGNED DEFAULT 15,
    `can_be_split_across_sections` TINYINT(1) DEFAULT 0,
    -- Performance & compliance
    `teacher_availability_ratio` DECIMAL(6,2) NOT NULL,  -- Formula is Given below the table (new)
    `performance_rating` TINYINT UNSIGNED DEFAULT NULL,  -- rating out of (1 to 10)
    `last_performance_review` DATE DEFAULT NULL,
    `security_clearance_done` TINYINT(1) DEFAULT 0,
    `reporting_to` INT UNSIGNED DEFAULT NULL,
    `can_access_sensitive_data` TINYINT(1) DEFAULT 0,
    `notes` TEXT NULL,
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_teacher_employee` (`employee_id`),
    CONSTRAINT `fk_teacher_employee` FOREIGN KEY (`employee_id`) REFERENCES `sch_employees` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `sch_teacher_capabilities` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- CORE RELATIONSHIP
    `teacher_profile_id` INT UNSIGNED NOT NULL,   -- FK sch_teacher_profile.id
    `class_id` INT UNSIGNED NOT NULL,                 -- FK sch_classes.id
    `section_id` INT UNSIGNED DEFAULT NULL,           -- FK sch_sections.id (NULL = all sections)
    `subject_study_format_id` INT UNSIGNED NOT NULL,   -- FK sch_subject_study_format_jnt.id
    -- TEACHING STRENGTH
    `proficiency_percentage` TINYINT UNSIGNED DEFAULT NULL, -- 1–100
    `teaching_experience_months` SMALLINT UNSIGNED DEFAULT NULL,
    `is_primary_subject` TINYINT(1) NOT NULL DEFAULT 1,  -- 1=Yes, 0=No
    `competancy_level` ENUM('Basic','Intermediate','Advanced','Expert') DEFAULT 'Basic',

    -- PRIORITY MATRIX INTELLIGENCE
    `priority_order` INT UNSIGNED DEFAULT NULL,   -- Priority Order of the Teacher for the Class+Subject+Study_Format
    `priority_weight` TINYINT UNSIGNED DEFAULT NULL,   -- manual / computed weight (1–10) (Even if teachers are available, how important is THIS activity to the school?)
    `scarcity_index` TINYINT UNSIGNED DEFAULT NULL,    -- 1=abundant, 10=very rare
    `is_hard_constraint` TINYINT(1) DEFAULT 0,         -- if true cannot be voilated e.g. Physics Lab teacher for Class 12
    `allocation_strictness` ENUM('hard','medium','soft') DEFAULT 'medium', e.g. Senior Maths teacher - Hard, Preferred English teacher - Medium, Art / Sports / Activity - Soft
    -- AI / HISTORICAL FEEDBACK
    `historical_success_ratio` TINYINT UNSIGNED DEFAULT NULL, -- 1–100 (sessions_completed_without_change / total_sessions_allocated ) * 100)
    `last_allocation_score` TINYINT UNSIGNED DEFAULT NULL,   -- last run score
    -- GOVERNANCE & OVERRIDE
    `override_priority` TINYINT UNSIGNED DEFAULT NULL, -- admin override
    `override_reason` VARCHAR(255) DEFAULT NULL,
    -- EFFECTIVITY & STATUS
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY `uq_teacher_capability` (`teacher_profile_id`, `class_id`, `section_id`, `subject_id`, `study_format_id`),
    CONSTRAINT `fk_tc_teacher_profile` FOREIGN KEY (`teacher_profile_id`) REFERENCES `sch_teacher_profile`(id) ON DELETE CASCADE,
    CONSTRAINT `fk_tc_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(id),
    CONSTRAINT `fk_tc_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections`(id),
    CONSTRAINT `fk_tc_subject_study_format` FOREIGN KEY (`subject_study_format_id`) REFERENCES `sch_subject_study_format_jnt`(id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- Formula: historical_success_ratio = (sessions_completed_without_change / total_sessions_allocated ) * 100)
  -- last_allocation_score = (proficiency_percentage * 0.4) + (load_balance * 0.3) + (strictness_match * 0.2) + (historical_success_ratio * 0.1)
  -- Importance - “Teacher selected because last allocation score = 87 (highest)”

----------------------------------------------------------------------------------
-- Made Changes :
-- 1. Added `teacher_availability_ratio` to `sch_teacher_profile` table.
-- 2. Added `priority_order` to `sch_teacher_capabilities` table.
-- 3. Removed `subject_id` from `sch_teacher_capabilities` table.
-- 4. Removed `study_format_id` from `sch_teacher_capabilities` table.
-- 5. Removed `max_periods_daily`, `min_periods_daily`, `max_periods_weekly`, `min_periods_weekly`, `can_be_split_across_sections` from `sch_teacher_capabilities` table.
-- 6. Added `max_periods_daily`, `min_periods_daily`, `max_periods_weekly`, `min_periods_weekly`, `can_be_split_across_sections` to `sch_teacher_profile` table.



