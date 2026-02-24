/* ============================================================
   COMMON ACADEMIC & HR MASTER TABLES
   Scope  : Tenant DB (Per School)
   DB     : MySQL 8+
   Style  : Audit-ready, Soft Delete
   ============================================================ */

SET FOREIGN_KEY_CHECKS = 0;

/* ============================================================
   ATTENDANCE TYPE
   ============================================================ */
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
) ENGINE=InnoDB;


/* ============================================================
   STAFF LEAVE TYPE
   ============================================================ */
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
) ENGINE=InnoDB;


/* ============================================================
   STUDENT CATEGORIES
   ============================================================ */
CREATE TABLE IF NOT EXISTS `sch_categories` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`       VARCHAR(30) NOT NULL,
    `name`       VARCHAR(100) NOT NULL,
    `description`         VARCHAR(255) NULL,
    `applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_student_category_code` (`code`)
) ENGINE=InnoDB;


/* ============================================================
   STAFF LEAVE CONFIGURATION
   ============================================================ */
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


/* ============================================================
   DISABLE REASONS
   ============================================================ */
CREATE TABLE IF NOT EXISTS `sch_disable_reasons` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`         VARCHAR(30) NOT NULL,
    `name`         VARCHAR(150) NOT NULL,
    `description`         VARCHAR(255) NULL,
    `is_reversible`       TINYINT(1) NOT NULL DEFAULT 1,
    `applicable_for`      ENUM('STUDENT','STAFF','BOTH') NOT NULL,
    `count_attrition`     TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_disable_reason_code` (`code`)
) ENGINE=InnoDB;


SET FOREIGN_KEY_CHECKS = 1;
