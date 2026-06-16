-- ===================================================================================================================================
-- Check Table `sch_categories` & `sch_disable_reasons`, may be used in Student. If not then Removed these also.
-- ===================================================================================================================================

   -- ----------------------------------------------------------------------------
   -- This table will capture Departments in the School.
   -- ----------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `sch_department` (
		`id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`name`       VARCHAR(100) NOT NULL, -- e.g. "Transport", "Academic", "Rash Driving"
		`code`       VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TPT", "ACD"
		`is_active`  TINYINT(1) DEFAULT 1,
		`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- ----------------------------------------------------------------------------
    -- This table will capture Designation in the School.
	-- ----------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `sch_designation` (
		`id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
		`name`       VARCHAR(100) NOT NULL, -- e.g. "Teacher", "Staff", "Student"
		`code`       VARCHAR(30) DEFAULT NULL, -- Optional short code e.g. "TCH", "STF", "STD"
		`is_active`  TINYINT(1) DEFAULT 1,
		`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- ----------------------------------------------------------------------------
    -- This table will capture different categories for both students and staff. 
    -- ----------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `sch_categories` (
		`id`              INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		`code`            VARCHAR(30) NOT NULL,
		`name`            VARCHAR(100) NOT NULL,
		`description`     VARCHAR(255) NULL,
		`applicable_for`  ENUM('STUDENT','STAFF','BOTH') NOT NULL,
		`is_active`       TINYINT(1) NOT NULL DEFAULT 1,
		`created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		`updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at`      TIMESTAMP NULL,
		UNIQUE KEY `uq_student_category_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

   -- ----------------------------------------------------------------------------
   -- This table will capture the reasons for disabling a student or staff. 
   -- It will be used in disable/enable operations and reporting.
   -- ----------------------------------------------------------------------------
	CREATE TABLE IF NOT EXISTS `sch_disable_reasons` (
		`id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		`code`                VARCHAR(30) NOT NULL,
		`name`                VARCHAR(150) NOT NULL,
		`description`         VARCHAR(255) NULL,
		`is_reversible`       TINYINT(1) NOT NULL DEFAULT 1,
		`applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
		`count_attrition`     TINYINT(1) NOT NULL DEFAULT 0,
		`is_active`           TINYINT(1) NOT NULL DEFAULT 1,
		`created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		`updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at`          TIMESTAMP NULL,
		UNIQUE KEY `uq_disable_reason_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
