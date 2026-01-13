-- ========================================================================================================
-- Student Profile Module DDL v1.3
-- ========================================================================================================
-- Author: ERP Architect GPT
-- Date: 2026-01-13
-- Module: Student Profile (std)
-- Description: 
--   Comprehensive schema for Student Management including:
--   - Core Profile (std_students, std_student_profiles)
--   - Family & Guardians (std_guardians, std_student_guardian_jnt)
--   - Addresses (std_student_addresses)
--   - Academic Session History (std_student_academic_sessions)
--   - Previous Education History (std_previous_education)
--   - Student Documents (std_student_documents)
--   - Daily Attendance (std_student_attendance, std_attendance_corrections)
--   - Health & Medical (std_health_profiles, std_medical_incidents, std_vaccination_records)
-- 
-- Dependencies: 
--   - sys_users (User Login)
--   - glb_cities, glb_states, glb_countries (Geography)
--   - sch_classes, sch_sections, sch_class_section_jnt, sch_subject_groups (Academic)
--   - sys_dropdown_table (Lookups)
-- ========================================================================================================

-- --------------------------------------------------------------------------------------------------------
-- 1. Student Core Tables
-- --------------------------------------------------------------------------------------------------------

-- Main Student Entity, linked to System User for Login/Auth
CREATE TABLE IF NOT EXISTS `std_students` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT UNSIGNED NOT NULL,              -- Link to sys_users for login credentials
  `admission_no` VARCHAR(50) NOT NULL,             -- Unique School Admission Number
  `admission_date` DATE NOT NULL,                  -- Date of admission
  `student_qr_code` VARCHAR(50) DEFAULT NULL,      -- For ID Cards
  `student_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
  `smart_card_id` VARCHAR(100) DEFAULT NULL,       -- RFID/NFC Tag ID
  -- Identity Documents
  `aadhar_id` VARCHAR(20) DEFAULT NULL,            -- National ID (India)
  `apaar_id` VARCHAR(100) DEFAULT NULL,            -- Academic Bank of Credits ID
  `birth_cert_no` VARCHAR(50) DEFAULT NULL,
  -- Basic Info (Demographics)
  `first_name` VARCHAR(100) NOT NULL,
  `middle_name` VARCHAR(100) DEFAULT NULL,
  `last_name` VARCHAR(100) DEFAULT NULL,
  `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
  `dob` DATE NOT NULL,
  `photo` VARCHAR(255) DEFAULT NULL,               -- Path to profile photo
  -- Status
  `current_status_id` BIGINT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (Active, Left, Suspended, Alumni, Withdrawn)
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  -- Meta
  `note` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_std_students_admissionNo` (`admission_no`),
  UNIQUE KEY `uq_std_students_userId` (`user_id`),
  UNIQUE KEY `uq_std_students_aadhar` (`aadhar_id`),
  CONSTRAINT `fk_std_students_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Extended Personal Profile
CREATE TABLE IF NOT EXISTS `std_student_profiles` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  -- Contact Info (Personal)
  `mobile` VARCHAR(20) DEFAULT NULL,               -- Student's own mobile
  `email` VARCHAR(100) DEFAULT NULL,               -- Student's own email
  -- Social / Category
  `religion` BIGINT UNSIGNED DEFAULT NULL,         -- FK to sys_dropdown_table
  `caste_category` BIGINT UNSIGNED DEFAULT NULL,   -- FK to sys_dropdown_table
  `nationality` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sys_dropdown_table
  `mother_tongue` BIGINT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table
  -- Financial / Banking
  `bank_account_no` VARCHAR(100) DEFAULT NULL,
  `bank_name` VARCHAR(100) DEFAULT NULL,
  `ifsc_code` VARCHAR(50) DEFAULT NULL,
  `bank_branch` VARCHAR(100) DEFAULT NULL,
  `upi_id` VARCHAR(100) DEFAULT NULL,
  `fee_depositor_pan_number` VARCHAR(10) DEFAULT NULL,    -- For tax benefit
  -- RTE / Government Schemes
  `right_to_education` TINYINT(1) NOT NULL DEFAULT 0, -- RTE Quota
  `is_ews` TINYINT(1) NOT NULL DEFAULT 0,             -- Economically Weaker Section
  -- Physical Stats (Latest snapshot, history in Health)
  `height_cm` DECIMAL(5,2) DEFAULT NULL,
  `weight_kg` DECIMAL(5,2) DEFAULT NULL,
  `measurement_date` date DEFAULT NULL,
  `additional_info` json DEFAULT NULL,
  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') DEFAULT NULL,
  -- Meta
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_std_profiles_studentId` (`student_id`),
  CONSTRAINT `fk_std_profiles_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_std_profiles_religion` FOREIGN KEY (`religion`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_caste_category` FOREIGN KEY (`caste_category`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_nationality` FOREIGN KEY (`nationality`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_std_profiles_mother_tongue` FOREIGN KEY (`mother_tongue`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- 2. Contact & Family Tables (Normalized)
-- --------------------------------------------------------------------------------------------------------

-- Student Addresses (1:N)
CREATE TABLE IF NOT EXISTS `std_student_addresses` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `address_type` ENUM('Permanent','Correspondence','Guardian','Local') NOT NULL DEFAULT 'Correspondence',
  `address_line_1` VARCHAR(255) NOT NULL,
  `address_line_2` VARCHAR(255) DEFAULT NULL,
  `city_id` BIGINT UNSIGNED NOT NULL,  -- FK to glb_cities
  `pincode` VARCHAR(10) NOT NULL,
  `is_primary` TINYINT(1) DEFAULT 0, -- To mark primary communication address
  `is_active` TINYINT(1) DEFAULT 1, -- To mark address as active
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_std_addr_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_std_addr_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Parent/Guardian Master
-- Guardians can be parents to multiple students (Siblings). 
-- Optional link to sys_users if Parent Portal access is granted.
CREATE TABLE IF NOT EXISTS `std_guardians` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT UNSIGNED DEFAULT NOT NULL,        -- Nullable. Set when Parent Portal access is created.
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) DEFAULT NULL,
  `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
  `mobile_no` VARCHAR(20) NOT NULL,                -- Primary identifier if user_id is null
  `phone_no` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `occupation` VARCHAR(100) DEFAULT NULL,
  `qualification` VARCHAR(100) DEFAULT NULL,
  `annual_income` DECIMAL(15,2) DEFAULT NULL,
  `photo` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_std_guardians_mobile` (`mobile_no`), -- Assumes unique mobile per parent
  UNIQUE KEY `uq_std_guardians_userId` (`user_id`),
  CONSTRAINT `fk_std_guardians_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Student-Guardian Junction
-- M:N Relationship (Student has Father, Mother; Parent has multiple kids)
CREATE TABLE IF NOT EXISTS `std_student_guardian_jnt` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `guardian_id` BIGINT UNSIGNED NOT NULL,
  `relation_type` ENUM('Father','Mother','Guardian') NOT NULL, 
  `relationship` VARCHAR(50) NOT NULL, -- Father, Mother, Uncle, Brother, Sister, Grandfather, Grandmother
  `is_emergency_contact` TINYINT(1) DEFAULT 0,
  `can_pickup` TINYINT(1) DEFAULT 0,   -- Authorization to pick up child
  `is_fee_payer` TINYINT(1) DEFAULT 0, -- Who pays the fees?
  `can_access_parent_portal` TINYINT(1) DEFAULT 0,  -- Can he access Paret Portal or Not
  `can_receive_notifications` TINYINT(1) DEFAULT 1,
  `notification_preference` ENUM('Email','SMS','WhatsApp','All') DEFAULT 'All',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_std_guard_jnt` (`student_id`, `guardian_id`),
  CONSTRAINT `fk_sg_jnt_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sg_jnt_guardian` FOREIGN KEY (`guardian_id`) REFERENCES `std_guardians` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- 3. Academic Information Tables
-- --------------------------------------------------------------------------------------------------------

-- Tracks chronological academic history (Class/Section allocation per session)
CREATE TABLE IF NOT EXISTS `std_student_academic_sessions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,   -- FK to glb_academic_sessions (or sch_org_academic_sessions_jnt)
  `class_section_id` INT UNSIGNED NOT NULL,         -- FK to sch_class_section_jnt
  `roll_no` INT UNSIGNED DEFAULT NULL,
  `subject_group_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to sch_subject_groups (if streams apply)
  `is_current` TINYINT(1) DEFAULT 0,                -- Only one active record per student
  `current_flag` bigint GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
  `session_status_id` BIGINT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (Promoted, Active, Left, Suspended, Alumni, Withdrawn)
  `leaving_date` DATE DEFAULT NULL,
  `reason_quit` int NULL,                       -- FK to `gl_dropdown_table` (Reason for leaving the Session)
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


-- --------------------------------------------------------------------------------------------------------
-- 4. Previous Education & Documents (New in v1.3)
-- --------------------------------------------------------------------------------------------------------

-- Student's Previous Education History (e.g. Previous Schools attended)
CREATE TABLE IF NOT EXISTS `std_previous_education` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `school_name` VARCHAR(150) NOT NULL,
  `school_address` VARCHAR(255) DEFAULT NULL,
  `board` VARCHAR(50) DEFAULT NULL,           -- e.g. CBSE, ICSE, State Board
  `class_passed` VARCHAR(50) DEFAULT NULL,    -- e.g. 5th, 8th, 10th
  `year_of_passing` YEAR DEFAULT NULL,
  `percentage_grade` VARCHAR(20) DEFAULT NULL,
  `medium_of_instruction` VARCHAR(30) DEFAULT NULL,
  `tc_number` VARCHAR(50) DEFAULT NULL,       -- Transfer Certificate Number
  `tc_date` DATE DEFAULT NULL,                -- Transfer Certificate Date
  `is_recognized` TINYINT(1) DEFAULT 1,       -- Was the previous school recognized?
  `remarks` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_prev_edu_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student Documents (Uploads for Previous Education, ID Proofs, etc.)
CREATE TABLE IF NOT EXISTS `std_student_documents` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `document_name` VARCHAR(100) NOT NULL,           -- e.g. 'Transfer Certificate', 'Mark Sheet', 'Aadhar Card'
  `document_type_id` BIGINT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (Category of doc)
  `document_number` VARCHAR(100) DEFAULT NULL,     -- e.g. TC No, Serial No
  `issue_date` DATE DEFAULT NULL,
  `expiry_date` DATE DEFAULT NULL,
  `issuing_authority` VARCHAR(150) DEFAULT NULL,
  `is_verified` TINYINT(1) DEFAULT 0,              -- Verified by school admin
  `verified_by` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sys_users
  `verification_date` DATETIME DEFAULT NULL,
  `file_name` VARCHAR(100) DEFAULT NULL,           -- Fk to sys_media (file name to show in UI)
  `media_id` BIGINT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
  `notes` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_std_docs_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_std_docs_type` FOREIGN KEY (`document_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_std_docs_verifier` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- 5. Health & Medical Tables
-- --------------------------------------------------------------------------------------------------------

-- Medical Profile
CREATE TABLE IF NOT EXISTS `std_health_profiles` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') DEFAULT NULL,
  `height_cm` DECIMAL(5,2) DEFAULT NULL,    -- Last recorded
  `weight_kg` DECIMAL(5,2) DEFAULT NULL,    -- Last recorded
  `measurement_date` date DEFAULT NULL,
  `allergies` TEXT DEFAULT NULL,            -- CSV or Notes
  `chronic_conditions` TEXT DEFAULT NULL,   -- Asthma, Diabetes, etc.
  `medications` TEXT DEFAULT NULL,          -- Ongoing medications
  `dietary_restrictions` TEXT DEFAULT NULL,
  `vision_left` VARCHAR(20) DEFAULT NULL,
  `vision_right` VARCHAR(20) DEFAULT NULL,
  `doctor_name` VARCHAR(100) DEFAULT NULL,
  `doctor_phone` VARCHAR(20) DEFAULT NULL,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_health_student` (`student_id`),
  CONSTRAINT `fk_health_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vaccination History
CREATE TABLE IF NOT EXISTS `std_vaccination_records` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `vaccine_name` VARCHAR(100) NOT NULL,
  `date_administered` DATE DEFAULT NULL,
  `next_due_date` DATE DEFAULT NULL,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_vacc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Medical Incidents (School Clinic Log)
CREATE TABLE IF NOT EXISTS `std_medical_incidents` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `incident_date` DATETIME NOT NULL,
  `incident_type_id` BIGINT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (e.g. Injury, Sickness, Fainting)
  `location` VARCHAR(100) DEFAULT NULL,     -- Playground, Classroom
  `description` TEXT NOT NULL,
  `first_aid_given` TEXT DEFAULT NULL,
  `action_taken` VARCHAR(255) DEFAULT NULL, -- Sent home, Rested in sick bay, Taken to hospital
  `reported_by` BIGINT UNSIGNED DEFAULT NULL, --  fk to sys_users (Teacher/Staff)
  `parent_notified` TINYINT(1) DEFAULT 0,
  `closure_date` DATE DEFAULT NULL,
  `follow_up_required` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_med_inc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_med_inc_reporter` FOREIGN KEY (`reported_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------------------------------------------------------
-- 6. Attendance Tables
-- --------------------------------------------------------------------------------------------------------

-- Daily Attendance Log
CREATE TABLE IF NOT EXISTS `std_student_attendance` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `class_section_id` INT UNSIGNED NOT NULL,
  `attendance_date` DATE NOT NULL,
  `attendance_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `marked_by` BIGINT UNSIGNED DEFAULT NULL,        -- User ID who marked attendance
  `marked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_std_att_student_date` (`student_id`, `attendance_date`, `attendance_period`),
  KEY `idx_std_att_class_date` (`class_section_id`, `attendance_date`),
  CONSTRAINT `fk_att_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_class` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_marker` FOREIGN KEY (`marked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Attendance Correction Requests
CREATE TABLE IF NOT EXISTS `std_attendance_corrections` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `attendance_id` BIGINT UNSIGNED NOT NULL,        -- FK to std_student_attendance
  `requested_by` BIGINT UNSIGNED NOT NULL,         -- Parent or Student User ID
  `requested_status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
  `requested_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `reason` TEXT NOT NULL,
  `status` ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `admin_remarks` VARCHAR(255) DEFAULT NULL,       -- Admin/Teacher Remark on approval/rejection
  `action_by` BIGINT UNSIGNED DEFAULT NULL,        -- Admin/Teacher who approved/rejected
  `action_at` TIMESTAMP NULL DEFAULT NULL,         -- When approved/rejected
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_att_corr_attId` FOREIGN KEY (`attendance_id`) REFERENCES `std_student_attendance` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_corr_reqBy` FOREIGN KEY (`requested_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_att_corr_actBy` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- --------------------------------------------------------------------------------------------------------
-- 7. Seed Data (Dropdowns & Lookups)
-- --------------------------------------------------------------------------------------------------------

-- Example INSERTs for sys_dropdown_needs and sys_dropdown_table
-- Note: Assuming sys_dropdown_needs entries exist or are created dynamically. 
-- Here we act as if we are seeding the values relative to the Student Module.

-- (Conceptual Seed Data - Un-comment or use as reference)
/*
-- 1. Student Status
INSERT INTO sys_dropdown_table (dropdown_needs_id, ordinal, key, value, type, is_active)
VALUES 
(1, 1, 'std_students.current_status_id.Active', 'Active', 'String', 1),
(1, 2, 'std_students.current_status_id.Alumni', 'Alumni', 'String', 1),
(1, 3, 'std_students.current_status_id.Suspended', 'Suspended', 'String', 1);

-- 2. Address Types (Hardcoded ENUM in DDL, but if Dropdown used)
-- 3. Incident Types
INSERT INTO sys_dropdown_table (dropdown_needs_id, ordinal, key, value, type, is_active)
VALUES 
(2, 1, 'std_medical_incidents.incident_type.Injury', 'Injury', 'String', 1),
(2, 2, 'std_medical_incidents.incident_type.Sickness', 'Sickness', 'String', 1);
*/

-- ========================================================================================================
-- End of DDL
-- ========================================================================================================
