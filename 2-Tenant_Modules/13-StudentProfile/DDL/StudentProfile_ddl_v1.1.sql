-- ========================================================================================================
-- Student Profile Module DDL v1.1
-- ========================================================================================================

CREATE TABLE IF NOT EXISTS `std_students` (
  `id` INT UNSIGNED AUTO_INCREMENT,
  `user_id` INT unsigned NOT NULL,          -- FK to sch_user
  `student_qr_code` VARCHAR(30) NOT NULL,
  `student_id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
  --`parent_id` INT unsigned NOT NULL,        -- FK to sch_user
  `aadhar_id` VARCHAR(20) NOT NULL,            -- always permanent identity
  `apaar_id` VARCHAR(100) NOT NULL,            -- 12 digits numeric i.e. 9876 5432 1098
  `birth_cert_no` VARCHAR(50) NULL,
  --`health_id` VARCHAR(50) NULL,                -- like ABHA number in India
  `smart_card_id` VARCHAR(100) NULL,           -- RFID Card Number / Smart Card Number
  `first_name` VARCHAR(100) NOT NULL,
  `middle_name` VARCHAR(100) DEFAULT NULL,
  `last_name` VARCHAR(100) DEFAULT NULL,
  `gender` ENUM('Male','Female','Transgender','Prefer Not to Say') NOT NULL DEFAULT 'Male',
  `dob` DATE NOT NULL,
  `blood_group` ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-') NOT NULL,
  `photo` VARCHAR(255) DEFAULT NULL,
  `current_status_id` int NOT NULL,    -- FK to `gl_dropdown_table`
  `note` varchar(200) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_aadharId` (`aadhar_id`),
  UNIQUE KEY `uq_student_userId` (`user_id`),
  CONSTRAINT `fk_students_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_students_parentId` FOREIGN KEY (`parent_id`) REFERENCES `sys_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Changed table name from 'std_student_detail' to 'std_student_personal_details'
CREATE TABLE IF NOT EXISTS `std_student_personal_details` (
  `id` INT unsigned NOT NULL AUTO_INCREMENT,
  `student_id` INT UNSIGNED DEFAULT NULL,         -- FK to 'std_students'
-  `mobile` varchar(20) DEFAULT NULL,     -- Student Mobile
-  `email` varchar(100) DEFAULT NULL,     -- Student Mail ID
  `current_address` text,
  `permanent_address` text,
  `city_id` INT UNSIGNED DEFAULT NULL,   -- FK to 'glb_city'
  `pin` varchar(10) DEFAULT NULL,
-  `religion` varchar(50) DEFAULT NULL,   -- FK to `gl_dropdown_table`
-  `cast` varchar(50) DEFAULT NULL,       -- FK to `gl_dropdown_table`
-  `right_to_edu` tinyint(1) NOT NULL DEFAULT '0',
-  `bank_account_no` varchar(100) DEFAULT NULL,
-  `bank_name` varchar(100) DEFAULT NULL,
-  `ifsc_code` varchar(100) DEFAULT NULL,
-  `upi_id` varchar(100) DEFAULT NULL,
-  `fee_depositor_pan_number` varchar(10) DEFAULT NULL,    -- For tax benefit
  `father_name` varchar(50) DEFAULT NULL,
  `father_phone` varchar(10) DEFAULT NULL,
  `father_occupation` varchar(20) DEFAULT NULL,
  `father_email` varchar(100) DEFAULT NULL,
  `father_pic` varchar(200) NOT NULL,
  `mother_name` varchar(50) DEFAULT NULL,
  `mother_phone` varchar(10) DEFAULT NULL,
  `mother_occupation` varchar(20) DEFAULT NULL,
  `mother_email` varchar(100) DEFAULT NULL,
  `mother_pic` varchar(200) NOT NULL,
  `guardian_is` ENUM('Father','Mother','Other') NOT NULL DEFAULT 'Father',
  `guardian_name` varchar(50) DEFAULT NULL,
  `guardian_relation` varchar(100) DEFAULT NULL,
  `guardian_relationship_proof_id` varchar(50) DEFAULT NULL,  -- for non-biological guardians
  `guardian_phone` varchar(10) DEFAULT NULL,
  `guardian_occupation` varchar(20) NOT NULL,
  `guardian_address` text,
  `guardian_email` varchar(100) DEFAULT NULL,
  `guardian_pic` varchar(200) NOT NULL,
  `previous_school_detail` text,
-  `height` varchar(100) NOT NULL,
-  `weight` varchar(100) NOT NULL,
  `measurement_date` date DEFAULT NULL,
  `additional_info` json DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_studentDetail_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentDetail_cityId` FOREIGN KEY (`city_id`) REFERENCES `glb_cities` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `std_student_sessions_jnt` (
  `id` INT UNSIGNED AUTO_INCREMENT,
  `student_id` INT UNSIGNED NOT NULL,            -- FK
  `user_id` INT unsigned NOT NULL,               -- FK to sch_user
  `academic_sessions_id` INT unsigned NOT NULL,  -- FK - sch_org_academic_sessions_jnt
  `admission_no` VARCHAR(50) NOT NULL,
  `roll_no` INT DEFAULT NULL,
  `admission_date` DATE DEFAULT NULL,
  `registration_no` VARCHAR(50) DEFAULT NULL,
  `default_mobile` ENUM('Father','Mother','Guardian','All') NOT NULL DEFAULT 'Mother',
  `default_email` ENUM('Father','Mother','Guardian','All') NOT NULL DEFAULT 'Mother',
  `class_section_id` INT UNSIGNED NOT NULL,         -- FK (Instead of selecting Class & Section, we will be using Class+Section)
  `subject_group_id` INT UNSIGNED NOT NULL,      -- FK - sch_subject_groups
  `session_status_id` INT UNSIGNED DEFAULT NULL, -- FK - gl_dropdown_table (Status of the Student in the Session)
  `is_current` TINYINT(1) DEFAULT 1,  -- Only one session can be current at a time for one student
  `current_flag` INT GENERATED ALWAYS AS ((case when (`is_current` = 1) then `student_id` else NULL end)) STORED,
  `leaving_date` DATE DEFAULT NULL,
  `reason_quit` int NULL,                       -- FK to `gl_dropdown_table` (Reason for leaving the Session)
  `dis_note` text NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_studentSessions_currentFlag` (`current_flag`),
  CONSTRAINT `fk_studentSessions_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_academicSession` FOREIGN KEY (`academic_sessions_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_classSectionId` FOREIGN KEY (`class_section_id`) REFERENCES `sch_class_section_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_subjGroupId` FOREIGN KEY (`subject_group_id`) REFERENCES `sch_subject_groups` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_sessionStatusId` FOREIGN KEY (`session_status_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_studentSessions_reasonQuit` FOREIGN KEY (`reason_quit`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
