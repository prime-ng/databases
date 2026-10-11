-- Tables Removed as of now - No USE OF Those
=============================================


-- ===================================================================================================================================
-- From School_Setup
-- ===================================================================================================================================
   -- ----------------------------------------------------------------------------
   -- This table will capture different types of attendance status for both students and staff. 
   -- It will be used in attendance marking and reporting.
   -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_attendance_types` (
    `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`                  VARCHAR(10) NOT NULL,  -- e.g. 'P', 'A', 'L', 'H'
    `name`                  VARCHAR(100) NOT NULL,  -- e.g. 'Present', 'Absent', 'Leave', 'Late', 'Holiday'
    `applicable_for`        ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `is_present`            TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Absent, 1: Present
    -- `is_absent`             TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Absent, 1: Absent
    `display_order`         INT NOT NULL DEFAULT 0,
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    UNIQUE KEY `uq_attendance_code` (`code`),
    INDEX `idx_attendance_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB;


   -- ----------------------------------------------------------------------------
   -- This table will capture type of Leaves available for staff. 
   -- It will be used in leave application and reporting.
   -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_types` (
    `id`       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(10) NOT NULL,  -- e.g. 'EL', 'CL', 'SL', 'PTL', 'MTL', 'Short', 'Half-Day' etc.
    `name`          VARCHAR(100) NOT NULL,  -- e.g. 'Earned Leave', 'Casual Leave', 'Sick Leave', 'Parental Leave', 'Maternity Leave', 'Short Leave', 'Half Day Leave' etc.
    `is_paid`             TINYINT(1) NOT NULL DEFAULT 1,  -- 0: Unpaid Leave, 1: Paid Leave
    `requires_approval`   TINYINT(1) NOT NULL DEFAULT 1,  -- 0: No Approval Required, 1: Approval Required
    `allow_half_day`      TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Full Day Leave Only, 1: Half Day Leave Allowed
    `display_order`       INT NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_leave_code` (`code`)
  ) ENGINE=InnoDB;

   -- ----------------------------------------------------------------------------
   -- This table will capture Leave configuration for different staff categories and leave types.
   -- It will be used in leave application and reporting.
   -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_config` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `academic_year`       VARCHAR(9) NOT NULL,
    `staff_category_id`   INT UNSIGNED NOT NULL,   -- FK to `sch_categories.id`
    `leave_type_id`       INT UNSIGNED NOT NULL,   -- FK to `sch_leave_types.id`
    `total_allowed`       DECIMAL(5,2) NOT NULL,
    `carry_forward`       TINYINT(1) NOT NULL DEFAULT 0,  -- 0: No Carry Forward, 1: Carry Forward
    `max_carry_forward`   DECIMAL(5,2) NULL,              -- Maximum carry forward allowed
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_leave_config` (`academic_year`, `staff_category_id`, `leave_type_id`),
    CONSTRAINT `fk_leave_config_category` FOREIGN KEY (`staff_category_id`) REFERENCES `sch_categories` (`id`),
    CONSTRAINT `fk_leave_config_type` FOREIGN KEY (`leave_type_id`) REFERENCES `sch_leave_types` (`id`)
  ) ENGINE=InnoDB;


-- =====================================================================================================================
 -- BELOW 3 TABLES NEEDS TO BE REMOVED
-- =====================================================================================================================

  -- CHECK - This table is not being used. Neither in Employee & nor in Student.
  -- Not being used. Employee module is having `sch_staff_attendance_types` Tables
  -- Need to be be Removed
  -- ---------------------------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_attendance_types` (
    `id`  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`     VARCHAR(10) NOT NULL,  -- e.g. 'P', 'A', 'L', 'H'
    `name`     VARCHAR(100) NOT NULL,  -- e.g. 'Present', 'Absent', 'Leave', 'Holiday'
    `applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `is_present`          TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Present, 1: Present
    `is_absent`           TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Absent, 1: Absent
    `display_order`       INT NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_attendance_code` (`code`),
    INDEX `idx_attendance_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------
  -- This table will capture type of Leaves available for staff. 
  -- It will be used in leave application and reporting.
  -- Not being used. Employee module is having `sch_staff_leave_types` Tables and Student have `std_leave_types`
  -- Check - Need to be Removed
  -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_types` (
    `id`       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(10) NOT NULL,  -- e.g. 'CL', 'SL', 'PL', 'LOP'
    `name`          VARCHAR(100) NOT NULL,  -- e.g. 'Casual Leave', 'Sick Leave', 'Parental Leave', 'Leave On Pay'
    `is_paid`             TINYINT(1) NOT NULL DEFAULT 1,  -- 0: Unpaid Leave, 1: Paid Leave
    `requires_approval`   TINYINT(1) NOT NULL DEFAULT 1,  -- 0: No Approval Required, 1: Approval Required
    `allow_half_day`      TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Full Day Leave Only, 1: Half Day Leave Allowed
    `display_order`       INT NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_leave_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------
  -- This table will capture Leave configuration for different staff categories and leave types.
  -- Not being used. Employee module is having Tables to capture same information
  -- Check - Need to be Removed
  -- ----------------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `sch_leave_config` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `academic_year`       VARCHAR(9) NOT NULL,
    `staff_category_id`   INT UNSIGNED NOT NULL,   -- FK to `sch_categories.id`
    `leave_type_id`       INT UNSIGNED NOT NULL,   -- FK to `sch_leave_types.id`
    `total_allowed`       DECIMAL(5,2) NOT NULL,
    `carry_forward`       TINYINT(1) NOT NULL DEFAULT 0,  -- 0: No Carry Forward, 1: Carry Forward
    `max_carry_forward`   DECIMAL(5,2) NULL,              -- Maximum carry forward allowed
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_leave_config` (`academic_year`, `staff_category_id`, `leave_type_id`),
    CONSTRAINT `fk_leave_config_category` FOREIGN KEY (`staff_category_id`) REFERENCES `sch_categories` (`id`),
    CONSTRAINT `fk_leave_config_type` FOREIGN KEY (`leave_type_id`) REFERENCES `sch_leave_types` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ===================================================================================================================================
-- From 
-- ===================================================================================================================================



