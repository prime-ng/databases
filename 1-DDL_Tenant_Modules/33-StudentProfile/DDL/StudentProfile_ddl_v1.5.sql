-- ========================================================================================================
-- Student Profile Module DDL v1.5
-- ========================================================================================================
-- Author: DB Architect
-- Date: 2026-04-08
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
--   - [NEW v1.5] Student Leave Management (std_leave_types, std_leave_applications,
--                std_leave_application_documents, std_leave_application_remarks)
--
-- v1.5 Changes:
--   Added 4 new tables for Student Leave Application workflow:
--   1. std_leave_types               — Leave type master (Sick, Casual, Medical, etc.)
--   2. std_leave_applications        — Application with Submitted→Approved/Rejected FSM
--   3. std_leave_application_documents — Supporting documents (Medical Cert, Parent Letter, etc.)
--   4. std_leave_application_remarks — Teacher↔Student query/response thread
--
-- Dependencies:
--   - sys_users (User Login)
--   - glb_cities, glb_states, glb_countries (Geography)
--   - sch_classes, sch_sections, sch_class_section_jnt, sch_subject_groups (Academic)
--   - sys_dropdown_table (Lookups)
-- ========================================================================================================


-- --------------------------------------------------------------------------------------------------------
-- Screen - 1 : Tab Name (Registration) User Creation & Login
-- --------------------------------------------------------------------------------------------------------
-- This tab will update sys_users table
-- Capture all th Value needs to be filled into sys_user

-- --------------------------------------------------------------------------------------------------------
-- Screen - 2 : Tab Name (Student Detail)
-- --------------------------------------------------------------------------------------------------------

  -- Main Student Entity, linked to System User for Login/Auth
  CREATE TABLE IF NOT EXISTS `std_students` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Student Info
    `user_id` INT UNSIGNED NOT NULL,              -- Link to sys_users for login credentials
    `admission_no` VARCHAR(50) NOT NULL,             -- Unique School Admission Number
    `admission_date` DATE NOT NULL,                  -- Date of admission
    -- ID Cards
    `student_qr_code` VARCHAR(20) DEFAULT NULL,      -- For ID Cards (this will be saved as emp_code in sys_users table)
    `student_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `smart_card_id` VARCHAR(100) DEFAULT NULL,       -- RFID/NFC Tag ID
    -- Identity Documents
    `aadhar_id` VARCHAR(20) DEFAULT NULL,            -- National ID (India)
    `apaar_id` VARCHAR(100) DEFAULT NULL,            -- Academic Bank of Credits ID
    `birth_cert_no` VARCHAR(50) DEFAULT NULL,
    -- Basic Info (Demographics)
    `first_name` VARCHAR(50) NOT NULL,               -- (Combined (First_name+Middle_name+last_name) and saved as `name` in sys_users table (Check Max_Length should not be more than 100))
    `middle_name` VARCHAR(50) DEFAULT NULL,
    `last_name` VARCHAR(50) DEFAULT NULL,              -- (Combined (First_name+Middle_name+last_name) and saved as `name` in sys_users table (Check Max_Length should not be more than 100))
    -- Personal Info
    `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
    `dob` DATE NOT NULL,
    `photo_file_name` VARCHAR(100) DEFAULT NULL,     -- Fk to sys_media (file name to show in UI)
    `media_id` INT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
    -- Status
    `current_status_id` INT UNSIGNED NOT NULL,    -- FK to sys_dropdown_table (Active, Left, Suspended, Alumni, Withdrawn)
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
  -- Condition:
  -- Short Name - (sys_user.short_name VARCHAR(30)) - This field value will be saved as 'short_name' in 'sys_users' table
  -- Password - (sys_user.password VARCHAR(255)) - The Hashed Value of Password will be saved as 'password' in 'sys_users' table


  -- Extended Personal Profile
  CREATE TABLE IF NOT EXISTS `std_student_profiles` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Student Info
    `student_id` INT UNSIGNED NOT NULL,
    `mobile` VARCHAR(20) DEFAULT NULL,               -- Student/Parent mobile (This will be saved as mobile in sys_users table)
    `email` VARCHAR(150) DEFAULT NULL,               -- Student/Parent email (This will be saved as email in sys_users table)
    -- Social / Category
    `religion` INT UNSIGNED DEFAULT NULL,         -- FK to sys_dropdown_table
    `caste_category` INT UNSIGNED DEFAULT NULL,   -- FK to sys_dropdown_table
    `nationality` INT UNSIGNED DEFAULT NULL,      -- FK to sys_dropdown_table
    `mother_tongue` INT UNSIGNED DEFAULT NULL,    -- FK to sys_dropdown_table
    -- Financial / Banking
    `bank_account_no` VARCHAR(100) DEFAULT NULL,
    `bank_name` VARCHAR(100) DEFAULT NULL,
    `ifsc_code` VARCHAR(50) DEFAULT NULL,
    -- Bank Details
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
    -- Additional Info
    `additional_info` json DEFAULT NULL,
    --  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') DEFAULT NULL, (Remove this Field, it is already there Health Table)
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

  -- Student Addresses (1:N)
  CREATE TABLE IF NOT EXISTS `std_student_addresses` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `address_type` ENUM('Permanent','Correspondence','Guardian','Local') NOT NULL DEFAULT 'Correspondence',
    `address` VARCHAR(512) NOT NULL,
    `city_id` INT UNSIGNED NOT NULL,  -- FK to glb_cities
    `pincode` VARCHAR(10) NOT NULL,
    `is_primary` TINYINT(1) DEFAULT 0, -- To mark primary communication address
    `is_active` TINYINT(1) DEFAULT 1, -- To mark address as active
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_std_addr_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_std_addr_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- --------------------------------------------------------------------------------------------------------
  -- Screen - 3 : Tab Name (Parents)
  -- --------------------------------------------------------------------------------------------------------

  -- Parent/Guardian Master
  -- Guardians can be parents to multiple students (Siblings).
  -- Optional link to sys_users if Parent Portal access is granted.
  CREATE TABLE IF NOT EXISTS `std_guardians` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_code` VARCHAR(20) NOT NULL,  -- Unique code for guardian (this will be saved as emp_code in sys_users table)
    -- User Info
    `user_id` INT UNSIGNED DEFAULT NOT NULL,        -- Nullable. Set when Parent Portal access is created.
    `first_name` VARCHAR(50) NOT NULL,                 -- First_name+last_name will be saved as name in sys_users table
    `last_name` VARCHAR(50) DEFAULT NULL,              -- First_name+last_name will be saved as name in sys_users table
    -- Personal Info
    `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
    `mobile_no` VARCHAR(20) NOT NULL,                -- Primary identifier if user_id is null
    `phone_no` VARCHAR(20) DEFAULT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    -- Professional Info
    `occupation` VARCHAR(100) DEFAULT NULL,
    `qualification` VARCHAR(100) DEFAULT NULL,
    `annual_income` DECIMAL(15,2) DEFAULT NULL,
    `preferred_language` INT unsigned NOT NULL,   -- fk to glb_languages
    -- Media & Status
    `photo_file_name` VARCHAR(100) DEFAULT NULL,     -- Fk to sys_media (file name to show in UI)
    `media_id` INT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
    `is_active` TINYINT(1) DEFAULT 1,
    -- Meta
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_std_guardians_mobile` (`mobile_no`), -- Assumes unique mobile per parent
    UNIQUE KEY `uq_std_guardians_userId` (`user_id`),
    CONSTRAINT `fk_std_guardians_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- Short Name - (sys_user.short_name VARCHAR(30)) - This field value will be saved as 'short_name' in 'sys_users' table
  -- Password - (sys_user.password VARCHAR(255)) - The Hashed Value of Password will be saved as 'password' in 'sys_users' table


  -- Student-Guardian Junction
  -- M:N Relationship (Student has Father, Mother; Parent has multiple kids)
  CREATE TABLE IF NOT EXISTS `std_student_guardian_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `guardian_id` INT UNSIGNED NOT NULL,
    --
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

  -- | Name (Firt Name + Last Name). | Relation Type | Relationship | Emergency Contact | Can Pick | Fee Payer | Portal Access | Notifications | Notification Pref. |

  -- --------------------------------------------------------------------------------------------------------
  -- Screen - 4 : Tab Name (Session)
  -- --------------------------------------------------------------------------------------------------------

  -- Tracks chronological academic history (Class/Section allocation per session)
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
    `is_current` TINYINT(1) NOT NULL DEFAULT 0,                -- Only one active record per student
    `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
    `session_status_id` INT UNSIGNED NOT NULL DEFAULT 'ACTIVE',    -- FK to sys_dropdown_table (PROMOTED, ACTIVE, LEFT, SUSPENDED, ALUMNI, WITHDRAWN)
    `count_for_timetable` TINYINT(1) NOT NULL DEFAULT 1,      -- Can we count this record for Timetable
    `leaving_date` DATE DEFAULT NULL,
    `count_as_attrition` TINYINT(1) NOT NULL DEFAULT 0,         -- Can we count this record as Attrition
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


  -- --------------------------------------------------------------------------------------------------------
  -- Screen - 5 : Tab Name (Previous Education)
  -- --------------------------------------------------------------------------------------------------------

  -- Student's Previous Education History (e.g. Previous Schools attended)
  CREATE TABLE IF NOT EXISTS `std_previous_education` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    -- School Details
    `school_name` VARCHAR(150) NOT NULL,
    `school_address` VARCHAR(255) DEFAULT NULL,
    `board` VARCHAR(50) DEFAULT NULL,           -- e.g. CBSE, ICSE, State Board
    -- Class Details
    `class_passed` VARCHAR(50) DEFAULT NULL,    -- e.g. 5th, 8th, 10th
    `year_of_passing` YEAR DEFAULT NULL,
    `percentage_grade` VARCHAR(20) DEFAULT NULL,
    `medium_of_instruction` VARCHAR(30) DEFAULT NULL, -- e.g. English, Hindi, Gujarati
    `tc_number` VARCHAR(50) DEFAULT NULL,       -- Transfer Certificate Number
    `tc_date` DATE DEFAULT NULL,                -- Transfer Certificate Date
    `is_recognized` TINYINT(1) DEFAULT 1,       -- Was the previous school recognized?
    -- Note
    `remarks` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_prev_edu_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Student Documents (Uploads for Previous Education, ID Proofs, etc.)
  CREATE TABLE IF NOT EXISTS `std_student_documents` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `document_name` VARCHAR(100) NOT NULL,           -- e.g. 'Transfer Certificate', 'Mark Sheet', 'Aadhar Card'
    `document_type_id` INT UNSIGNED NOT NULL,     -- FK to sys_dropdown_table (Category of doc)
    `document_number` VARCHAR(100) DEFAULT NULL,     -- e.g. TC No, Serial No
    `issue_date` DATE DEFAULT NULL,
    `expiry_date` DATE DEFAULT NULL,
    `issuing_authority` VARCHAR(150) DEFAULT NULL,
    `is_verified` TINYINT(1) DEFAULT 0,              -- Verified by school admin
    `verified_by` INT UNSIGNED DEFAULT NULL,      -- FK to sys_users
    `verification_date` DATETIME DEFAULT NULL,
    `file_name` VARCHAR(100) DEFAULT NULL,           -- Fk to sys_media (file name to show in UI)
    `media_id` INT UNSIGNED DEFAULT NULL,         -- Optional if using sys_media table
    `notes` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_std_docs_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_std_docs_type` FOREIGN KEY (`document_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_std_docs_verifier` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- --------------------------------------------------------------------------------------------------------
  -- Screen - 6 : Tab Name (Health)
  -- --------------------------------------------------------------------------------------------------------

  -- Medical Profile
  CREATE TABLE IF NOT EXISTS `std_health_profiles` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    --
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `vaccine_name` VARCHAR(100) NOT NULL,
    `date_administered` DATE DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_vacc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Medical Incidents (School Clinic Log)
  CREATE TABLE IF NOT EXISTS `std_medical_incidents` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `incident_date` DATETIME NOT NULL,
    `incident_type_id` INT UNSIGNED NOT NULL, -- FK to sys_dropdown_table (e.g. Injury, Sickness, Fainting)
    `location` VARCHAR(100) DEFAULT NULL,     -- Playground, Classroom
    `description` TEXT NOT NULL,
    `first_aid_given` TEXT DEFAULT NULL,
    `action_taken` VARCHAR(255) DEFAULT NULL, -- Sent home, Rested in sick bay, Taken to hospital
    `reported_by` INT UNSIGNED DEFAULT NULL, --  fk to sys_users (Teacher/Staff)
    `parent_notified` TINYINT(1) DEFAULT 0,
    `closure_date` DATE DEFAULT NULL,
    `follow_up_required` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_med_inc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_med_inc_reporter` FOREIGN KEY (`reported_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- --------------------------------------------------------------------------------------------------------
  -- Screen - 7 : Tab Name (Attendance)
  -- --------------------------------------------------------------------------------------------------------

  -- Variable in sys_setting (Key "Period_wise_Student_Attendance", Value-TRUE/FALSE)
  -- Daily Attendance Log
  CREATE TABLE IF NOT EXISTS `std_student_attendance` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `academic_session_id` INT UNSIGNED NOT NULL,
    `class_section_id` INT UNSIGNED NOT NULL,
    `attendance_date` DATE NOT NULL, -- Date of attendance
    `attendance_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `marked_by` INT UNSIGNED DEFAULT NULL,        -- User ID who marked attendance
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `attendance_id` INT UNSIGNED NOT NULL,        -- FK to std_student_attendance
    `requested_by` INT UNSIGNED NOT NULL,         -- Parent or Student User ID
    `requested_status` ENUM('Present','Absent','Late','Half Day','Short Leave','Leave') NOT NULL,
    `requested_period` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `reason` TEXT NOT NULL,
    `status` ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    `admin_remarks` VARCHAR(255) DEFAULT NULL,       -- Admin/Teacher Remark on approval/rejection
    `action_by` INT UNSIGNED DEFAULT NULL,        -- Admin/Teacher who approved/rejected
    `action_at` TIMESTAMP NULL DEFAULT NULL,         -- When approved/rejected
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_att_corr_attId` FOREIGN KEY (`attendance_id`) REFERENCES `std_student_attendance` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_att_corr_reqBy` FOREIGN KEY (`requested_by`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_att_corr_actBy` FOREIGN KEY (`action_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ========================================================================================================
-- [NEW v1.5] STUDENT LEAVE MANAGEMENT
-- ========================================================================================================
-- Feature: Student applies for leave via StudentPortal (Screen 30 — Apply Leave).
--          Class Teacher reviews, approves/rejects, or asks for more info/documents.
--
-- Workflow (FSM):
--   Student submits → [Submitted]
--   Teacher opens   → [Under Review]
--   Teacher queries → [Info Requested] or [Doc Requested]
--   Student responds → [Submitted] (re-opens for review)
--   Teacher decides  → [Approved] or [Rejected]
--   Student cancels  → [Cancelled] (only from Submitted/Info Requested/Doc Requested)
--
-- On Approval: Application layer marks std_student_attendance.status = 'Leave'
--              for each date in the approved leave range.
-- ========================================================================================================


  -- --------------------------------------------------------------------------------------------------------
  -- Screen - 8 : Tab Name (Leave)   [NEW v1.5]
  -- --------------------------------------------------------------------------------------------------------

  -- --------------------------------------------------------------------------------------------------------
  -- TABLE: std_leave_types
  -- Master configuration for leave categories. Seeded by school admin.
  -- Examples: Sick Leave, Casual Leave, Medical Leave, Bereavement Leave, Festival Leave
  -- --------------------------------------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `std_leave_types` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Identity
    `code`                      VARCHAR(30) NOT NULL COMMENT 'Unique code: SICK, CASUAL, MEDICAL, BEREAVEMENT, FESTIVAL, etc.',
    `name`                      VARCHAR(100) NOT NULL COMMENT 'Display name shown in UI: Sick Leave, Casual Leave, etc.',
    `description`               VARCHAR(255) DEFAULT NULL COMMENT 'When to use this leave type',
    -- Policy
    `max_days_per_application`  TINYINT UNSIGNED NOT NULL DEFAULT 30 COMMENT 'Maximum consecutive days allowed in one application (0 = no limit)',
    `max_days_per_year`         SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Annual quota — total days allowed per academic year (0 = unlimited)',
    `requires_document`         TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = supporting document (medical cert, etc.) is mandatory at submission',
    `allow_half_day`            TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = student can apply for half-day leave of this type',
    `advance_notice_days`       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Minimum advance notice required in days (0 = same day allowed)',
    `is_active`                 TINYINT(1) NOT NULL DEFAULT 1, 
    `created_by`                INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users',
    `created_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_leave_type_code` (`code`, `deleted_at`),
    INDEX `idx_leave_type_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Leave type master — school configures leave categories with their policies';


  -- --------------------------------------------------------------------------------------------------------
  -- TABLE: std_leave_applications
  -- Core leave application record. One row per leave request.
  --
  -- STATUS FSM:
  --   Draft          → Saved but not yet submitted (visible only to student)
  --   Submitted      → Formally submitted; visible to class teacher
  --   Under Review   → Class teacher has opened and is reviewing
  --   Info Requested → Teacher asked for additional information (ball in student's court)
  --   Doc Requested  → Teacher asked for supporting document (ball in student's court)
  --   Approved       → Leave approved; app layer marks attendance as 'Leave'
  --   Rejected       → Leave rejected with reason
  --   Cancelled      → Cancelled by student before final decision
  -- --------------------------------------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `std_leave_applications` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Applicant Context
    `student_id`            INT UNSIGNED NOT NULL COMMENT 'FK → std_students',
    `academic_session_id`   INT UNSIGNED NOT NULL COMMENT 'FK → sch_org_academic_sessions_jnt — academic year of the leave',
    `class_section_id`      INT UNSIGNED NOT NULL COMMENT 'FK → sch_class_section_jnt — routes application to the correct class teacher',
    -- Leave Details
    `leave_type_id`         INT UNSIGNED NOT NULL COMMENT 'FK → std_leave_types',
    `from_date`             DATE NOT NULL COMMENT 'First day of requested leave',
    `to_date`               DATE NOT NULL COMMENT 'Last day of requested leave (= from_date for single-day)',
    `total_days`            TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Total calendar days requested (application layer calculates, excluding holidays if configured)',
    `is_half_day`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = half-day leave (only valid when from_date = to_date)',
    `half_day_slot`         ENUM('Morning','Afternoon') DEFAULT NULL COMMENT 'Which half of the day — only populated when is_half_day = 1',
    `reason`                TEXT NOT NULL COMMENT 'Student-provided reason for leave',
    -- Workflow
    `status`                ENUM('Draft','Submitted','Under Review','Info Requested','Doc Requested','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Draft' COMMENT 'FSM state of the leave application',
    `applied_by`            INT UNSIGNED NOT NULL COMMENT 'FK → sys_users — student or parent who submitted the application',
    -- Review Details (set when teacher acts)
    `reviewed_by`           INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_users — class teacher who reviewed',
    `reviewed_at`           TIMESTAMP NULL DEFAULT NULL COMMENT 'Timestamp of final approve/reject action',
    `approved_days`         TINYINT UNSIGNED DEFAULT NULL COMMENT 'Actual approved days (may differ from total_days if partially approved)',
    `review_remarks`        TEXT DEFAULT NULL COMMENT 'Class teacher remarks on approval or rejection',
    -- Soft delete / audit
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    -- Indexes
    INDEX `idx_la_student`          (`student_id`, `academic_session_id`),
    INDEX `idx_la_class_section`    (`class_section_id`, `status`) COMMENT 'Class teacher inbox: filter by section + status',
    INDEX `idx_la_status`           (`status`),
    INDEX `idx_la_dates`            (`from_date`, `to_date`),
    INDEX `idx_la_reviewer`         (`reviewed_by`),
    -- Constraints
    CONSTRAINT `fk_la_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_la_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_la_class_section` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_la_leave_type` FOREIGN KEY (`leave_type_id`) REFERENCES `std_leave_types` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_la_applied_by` FOREIGN KEY (`applied_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_la_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student leave applications with class-teacher approval workflow';
  -- Condition:
  -- is_half_day = 1 is only valid when from_date = to_date
  -- On status change to Approved: application layer must create std_student_attendance records
  --   with status = Leave for each working day in [from_date .. to_date]
  -- On status change to Cancelled or Rejected: no attendance impact


  -- --------------------------------------------------------------------------------------------------------
  -- TABLE: std_leave_application_documents
  -- Supporting documents attached to a leave application.
  -- Can be submitted at initial application time OR uploaded later in response to a teacher's
  -- document request (is_in_response_to_request = 1, request_remark_id links to the specific query).
  -- --------------------------------------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `std_leave_application_documents` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `leave_application_id`  INT UNSIGNED NOT NULL COMMENT 'FK → std_leave_applications',
    -- Document Metadata
    `document_name`         VARCHAR(150) NOT NULL COMMENT 'Display name: Medical Certificate, Parent Authorization Letter, etc.',
    `document_type_id`      INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_dropdown_table (document category)',
    `description`           VARCHAR(255) DEFAULT NULL COMMENT 'Additional context for this document',
    -- File
    `file_name`             VARCHAR(255) NOT NULL COMMENT 'Stored file name in sys_media',
    `media_id`              INT UNSIGNED DEFAULT NULL COMMENT 'FK → sys_media (optional explicit link)',
    -- Upload Context
    `uploaded_by`           INT UNSIGNED NOT NULL COMMENT 'FK → sys_users — student or parent who uploaded',
    `is_in_response_to_request` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0 = submitted voluntarily; 1 = uploaded in response to teacher document request',
    `request_remark_id`     INT UNSIGNED DEFAULT NULL COMMENT 'FK → std_leave_application_remarks (the Doc Requested remark that triggered this upload)',
    -- Meta
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_lad_application`     (`leave_application_id`),
    INDEX `idx_lad_request_remark`  (`request_remark_id`),
    CONSTRAINT `fk_lad_application` FOREIGN KEY (`leave_application_id`) REFERENCES `std_leave_applications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lad_doc_type` FOREIGN KEY (`document_type_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lad_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Documents attached to leave applications: medical certs, parent letters, etc.';


  -- --------------------------------------------------------------------------------------------------------
  -- TABLE: std_leave_application_remarks
  -- Communication thread between Class Teacher and Student/Parent on a leave application.
  -- Also serves as the FSM transition log (auto-inserted on every status change).
  --
  -- REMARK TYPES:
  --   comment        → General note from teacher or student (informational)
  --   info_request   → Teacher asking student for additional information/clarification
  --   doc_request    → Teacher requesting a specific supporting document
  --   response       → Student/Parent response to an info_request or doc_request
  --   status_change  → Auto-logged by system on every FSM state transition (for audit trail)
  -- --------------------------------------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `std_leave_application_remarks` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `leave_application_id`  INT UNSIGNED NOT NULL COMMENT 'FK → std_leave_applications',
    -- Remark Content
    `remark_type`           ENUM('Comment', 'Info_Request', 'Doc_Request', 'Response', 'Status_Change') NOT NULL DEFAULT 'Comment'  --COMMENT 'Type of remark — drives UI rendering and workflow logic',
    `message`               TEXT NOT NULL COMMENT 'The remark text, question, request, or response',
    -- Sender
    `is_from_teacher`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = remark from class teacher; 0 = remark from student or parent',
    `remarked_by`           INT UNSIGNED NOT NULL COMMENT 'FK → sys_users — who wrote this remark',
    -- Thread Context
    `parent_remark_id`      INT UNSIGNED DEFAULT NULL COMMENT 'FK → self — links a response to the specific query it is answering',
    -- Resolution Tracking (for info_request and doc_request types)
    `is_resolved`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = the request has been answered/fulfilled (set by teacher or on student response)',
    `resolved_at`           TIMESTAMP NULL DEFAULT NULL COMMENT 'When the request was marked resolved',
    -- Status Snapshot (for status_change type only)
    `old_status`            VARCHAR(30) DEFAULT NULL COMMENT 'Previous status before transition (status_change type only)',
    `new_status`            VARCHAR(30) DEFAULT NULL COMMENT 'New status after transition (status_change type only)',
    -- Meta
    `created_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_lar_application`     (`leave_application_id`, `remark_type`),
    INDEX `idx_lar_parent_remark`   (`parent_remark_id`),
    INDEX `idx_lar_remarked_by`     (`remarked_by`),
    INDEX `idx_lar_unresolved`      (`leave_application_id`, `is_resolved`) COMMENT 'Find open requests on an application quickly',
    CONSTRAINT `fk_lar_application` FOREIGN KEY (`leave_application_id`) REFERENCES `std_leave_applications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lar_remarked_by` FOREIGN KEY (`remarked_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_lar_parent_remark` FOREIGN KEY (`parent_remark_id`) REFERENCES `std_leave_application_remarks` (`id`) ON DELETE SET NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Teacher↔Student communication thread on leave applications. Also serves as FSM audit log.';
  -- Condition:
  -- remark_type = info_request  → teacher writes message asking for info; application status → Info Requested
  -- remark_type = doc_request   → teacher writes message requesting a document; status → Doc Requested
  -- remark_type = response      → student/parent writes reply; set parent_remark_id = the request being answered;
  --                                application status reverts to → Submitted for teacher to re-review
  -- remark_type = status_change → inserted automatically by application layer on EVERY status change;
  --                                old_status and new_status must be populated; message = system description
  -- is_resolved = 1             → set by teacher after reviewing the student's response, OR automatically
  --                                when student uploads a doc (doc_request) or writes a response (info_request)


-- ========================================================================================================
-- End of DDL
-- ========================================================================================================
-- Change Log:
-- v1.3 → v1.4: Added `count_for_timetable` column to `std_student_academic_sessions` table
-- v1.4 → v1.5: Added Student Leave Management — 4 new tables:
--              std_leave_types, std_leave_applications,
--              std_leave_application_documents, std_leave_application_remarks
-- ========================================================================================================
