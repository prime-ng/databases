/* ============================================================
   STUDENT FEE MANAGEMENT MODULE
   Database: MySQL 8+
   Architecture: Tenant DB (Per School)
   ============================================================ */

SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------------
-- 1. FEE HEAD MASTER
-- This table will store the fee heads for the school.
-- --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_fee_heads` (
    `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`             VARCHAR(50) NOT NULL,  -- e.g. TUITION_FEE, ADMISSION_FEE, TRANSPORT_FEE, HOSTEL_FEE, LIBRARY_FEE, LAB_FEE, EXAM_FEE, COMPUTER_FEE, ACTIVITY_FEE, OTHER_FEE
    `name`             VARCHAR(100) NOT NULL,
    `is_recurring`     TINYINT(1) NOT NULL DEFAULT 0,
    `recurrence_type`  ENUM('MONTHLY','QUARTERLY','HALF_YEARLY','YEARLY','ONE_TIME') NULL,
    `is_taxable`       TINYINT(1) NOT NULL DEFAULT 0,
    `is_refundable`    TINYINT(1) NOT NULL DEFAULT 0,
    `display_order`    TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
    `is_deleted`       TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       TIMESTAMP NULL,
    UNIQUE KEY `uq_fee_head_code` (`code`),
    INDEX `idx_fee_head_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fee_heads` (`code`, `name`, `is_recurring`, `recurrence_type`, `is_taxable`, `is_refundable`, `display_order`, `is_active`, `is_deleted`) VALUES
	('TUITION_FEE', 'Tuition Fee', 1, 'MONTHLY', 1, 0, 1, 1, 0),
	('ADMISSION_FEE', 'Admission Fee', 0, 'ONE_TIME', 1, 0, 2, 1, 0),
	('TRANSPORT_FEE', 'Transport Fee', 1, 'MONTHLY', 1, 0, 3, 1, 0),
	('HOSTEL_FEE', 'Hostel Fee', 1, 'MONTHLY', 1, 0, 4, 1, 0),
	('LIBRARY_FEE', 'Library Fee', 1, 'MONTHLY', 1, 0, 5, 1, 0),
	('LAB_FEE', 'Lab Fee', 1, 'MONTHLY', 1, 0, 6, 1, 0),
	('EXAM_FEE', 'Exam Fee', 1, 'MONTHLY', 1, 0, 7, 1, 0),
	('COMPUTER_FEE', 'Computer Fee', 1, 'MONTHLY', 1, 0, 8, 1, 0),
	('ACTIVITY_FEE', 'Activity Fee', 1, 'MONTHLY', 1, 0, 9, 1, 0),
	('OTHER_FEE', 'Other Fee', 1, 'MONTHLY', 1, 0, 10, 1, 0);

-- --------------------------------------------------------------
-- 2. FEE STRUCTURE MASTER
-- This table will store the fee structures for the school.
-- --------------------------------------------------------------
CREATE TABLE `std_fee_structures` (
    `id`   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `academic_year`      VARCHAR(9) NOT NULL,
    `class_id`           INT UNSIGNED NOT NULL,
    `category_id`        INT UNSIGNED NULL,  --  FK to std_categories.id Optional: For fee concessions based on category
    `fee_head_id`        INT UNSIGNED NOT NULL,
    `total_amount`       DECIMAL(10,2) NOT NULL,
    `payment_cycle`      ENUM('MONTHLY','QUARTERLY','HALF_YEARLY','YEARLY','ONE_TIME') NOT NULL,
    `is_locked`          TINYINT(1) NOT NULL DEFAULT 0,
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
    `is_deleted`         TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_fee_structure` (`academic_year`, `class_id`, `category_id`, `fee_head_id`),
    INDEX `idx_fee_structure_lookup` (`class_id`, `academic_year`),
    CONSTRAINT `fk_fs_fee_head` FOREIGN KEY (`fee_head_id`) REFERENCES `std_fee_heads` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fee_structures` (`academic_year`, `class_id`, `category_id`, `fee_head_id`, `total_amount`, `payment_cycle`, `is_locked`, `is_active`, `is_deleted`) VALUES
	('2022-2023', '1', '1', '1', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '2', '10000.00', 'ONE_TIME', 0, 1, 0),
	('2022-2023', '1', '1', '3', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '4', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '5', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '6', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '7', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '8', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '9', '10000.00', 'MONTHLY', 0, 1, 0),
	('2022-2023', '1', '1', '10', '10000.00', 'MONTHLY', 0, 1, 0);

-- --------------------------------------------------------------
-- 3. FEE INSTALLMENTS
-- This table will store the fee installments for the school.
-- --------------------------------------------------------------
CREATE TABLE `std_fee_installments` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `fee_structure_id`   INT UNSIGNED NOT NULL,
    `installment_name`   VARCHAR(50) NOT NULL,
    `due_date`           DATE NOT NULL,
    `amount`             DECIMAL(10,2) NOT NULL,
    `sequence_no`        INT NOT NULL,
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
    `is_deleted`         TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_installment` (`fee_structure_id`, `installment_name`),
    INDEX `idx_installment_due` (`due_date`),
    CONSTRAINT `fk_installment_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `std_fee_structures` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fee_installments` (`fee_structure_id`, `installment_name`, `due_date`, `amount`, `sequence_no`, `is_active`, `is_deleted`) VALUES
	('1', 'Admission Fee', '2022-06-30', 10000, 1, 1, 0),
	('2', 'Tuition Fee', '2022-06-30', 5000, 1, 1, 0),
	('2', 'Tuition Fee', '2022-07-31', 5000, 2, 1, 0),
	('2', 'Tuition Fee', '2022-08-31', 5000, 3, 1, 0),
	('2', 'Tuition Fee', '2022-09-30', 5000, 4, 1, 0),
	('2', 'Tuition Fee', '2022-10-31', 5000, 5, 1, 0),
	('2', 'Tuition Fee', '2022-11-30', 5000, 6, 1, 0),
	('2', 'Tuition Fee', '2022-12-31', 5000, 7, 1, 0),
	('2', 'Tuition Fee', '2023-01-31', 5000, 8, 1, 0),
	('2', 'Tuition Fee', '2023-02-28', 5000, 9, 1, 0),
	('2', 'Tuition Fee', '2023-03-31', 5000, 10, 1, 0),
	('2', 'Tuition Fee', '2023-04-30', 5000, 11, 1, 0);

-- --------------------------------------------------------------
-- 4. FINE POLICY MASTER
-- This table will store the fine policies for the school.
-- --------------------------------------------------------------
CREATE TABLE `std_fine_policies` (
    `id`     INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `policy_name`        VARCHAR(100) NOT NULL,
    `description`        TEXT NULL,
    `removal_after_days` INT NOT NULL DEFAULT 61,
    `grace_days`         INT NOT NULL DEFAULT 0,
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
    `is_deleted`         TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_fine_policy_name` (`policy_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fine_policies` (`policy_name`, `description`, `removal_after_days`, `grace_days`, `is_active`, `is_deleted`) VALUES
	('Default Fine Policy', 'Standard fine policy for all students', 61, 0, 1, 0);

-- --------------------------------------------------------------
-- 5. FINE SLAB RULES
-- This table will store the fine slab rules for the school.
-- --------------------------------------------------------------
CREATE TABLE `std_fine_slabs` (
    `id`       INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `fine_policy_id`     INT UNSIGNED NOT NULL,
    `from_day`           INT NOT NULL,
    `to_day`             INT NOT NULL,
    `fine_mode`          ENUM('PERCENT','FIXED_PER_DAY','MAX_OF_BOTH') NOT NULL,
    `percent_value`      DECIMAL(5,2) NULL,
    `amount_per_day`     DECIMAL(10,2) NULL,
    `action_code`        ENUM('NONE','REMOVE_STUDENT') NOT NULL DEFAULT 'NONE',
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (`from_day` <= `to_day`),
    INDEX `idx_fine_slab_range` (`fine_policy_id`, `from_day`, `to_day`),
    CONSTRAINT `fk_fine_slab_policy` FOREIGN KEY (`fine_policy_id`) REFERENCES `std_fine_policies` (`fine_policy_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fine_slabs` (`fine_policy_id`, `from_day`, `to_day`, `fine_mode`, `percent_value`, `amount_per_day`, `action_code`, `created_at`) VALUES
	('1', '1', '10', 'FIXED_PER_DAY', NULL, 10.00, 'NONE', '2022-06-01 00:00:00'),
	('1', '11', '30', 'FIXED_PER_DAY', NULL, 20.00, 'NONE', '2022-06-01 00:00:00'),
	('1', '31', '60', 'FIXED_PER_DAY', NULL, 50.00, 'NONE', '2022-06-01 00:00:00'),
	('1', '61', '90', 'MAX_OF_BOTH', 5.00, 100.00, 'REMOVE_STUDENT', '2022-06-01 00:00:00');

-- --------------------------------------------------------------
-- 6. STUDENT FEE MAPPING
-- This table will store the fee mappings for the students.
-- --------------------------------------------------------------
CREATE TABLE `std_student_fee_map` (
    `id` INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `student_id`         INT UNSIGNED NOT NULL,
    `fee_structure_id`   INT UNSIGNED NOT NULL,
    `concession_type`    ENUM('NONE','PERCENT','FIXED') NOT NULL DEFAULT 'NONE',
    `concession_value`   DECIMAL(10,2) NULL,
    `effective_from`     DATE NOT NULL,
    `effective_to`       DATE NULL,
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
    `is_deleted`         TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_student_fee` (`student_id`, `fee_structure_id`, `effective_from`),
    CONSTRAINT `fk_student_fee_structure` FOREIGN KEY (`fee_structure_id`) REFERENCES `std_fee_structures` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_student_fee_map` (`student_id`, `fee_structure_id`, `concession_type`, `concession_value`, `effective_from`, `effective_to`, `is_active`, `is_deleted`) VALUES
	('1', '1', 'NONE', NULL, '2022-06-01', NULL, 1, 0),
	('1', '2', 'NONE', NULL, '2022-06-01', NULL, 1, 0);

-- --------------------------------------------------------------
-- 7. STUDENT FEE LEDGER (CORE)
-- This table will store the fee ledger for the students.
-- --------------------------------------------------------------
CREATE TABLE `std_student_fee_ledger` (
    `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `student_id`         INT UNSIGNED NOT NULL,
    `reference_type`     ENUM('DEMAND','PAYMENT','FINE','ADJUSTMENT','REVERSAL') NOT NULL,
    `reference_id`       INT UNSIGNED NULL,
    `fee_head_id`        INT UNSIGNED NULL,
    `installment_id`     INT UNSIGNED NULL,
    `transaction_date`   DATE NOT NULL,
    `debit_amount`       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `credit_amount`      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `running_balance`    DECIMAL(12,2) NOT NULL,
    `remarks`            VARCHAR(255) NULL,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_ledger_student_date` (`student_id`, `transaction_date`),
    INDEX `idx_ledger_ref` (`reference_type`, `reference_id`),
    CONSTRAINT `fk_ledger_fee_head` FOREIGN KEY (`fee_head_id`) REFERENCES `std_fee_heads` (`id`),
    CONSTRAINT `fk_ledger_installment` FOREIGN KEY (`installment_id`) REFERENCES `std_fee_installments` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_student_fee_ledger` (`student_id`, `reference_type`, `reference_id`, `fee_head_id`, `installment_id`, `transaction_date`, `debit_amount`, `credit_amount`, `running_balance`, `remarks`, `created_at`) VALUES
	('1', 'DEMAND', '1', '1', '1', '2022-06-01', 10000.00, 0.00, 10000.00, 'Admission Fee Demand', '2022-06-01 00:00:00'),
	('1', 'DEMAND', '2', '2', '2', '2022-06-01', 5000.00, 0.00, 15000.00, 'Tuition Fee Demand', '2022-06-01 00:00:00');

-- --------------------------------------------------------------
-- 8. FEE PAYMENTS
-- This table will store the fee payments for the students.
-- --------------------------------------------------------------
CREATE TABLE `std_fee_payments` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `student_id`         INT UNSIGNED NOT NULL,
    `payment_date`       DATE NOT NULL,
    `payment_mode`       ENUM('CASH','CHEQUE','UPI','CARD','NETBANKING','WALLET') NOT NULL,
    `reference_no`       VARCHAR(100) NULL,
    `amount_paid`        DECIMAL(10,2) NOT NULL,
    `created_by`         INT UNSIGNED NOT NULL,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_payment_student` (`student_id`, `payment_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fee_payments` (`student_id`, `payment_date`, `payment_mode`, `reference_no`, `amount_paid`, `created_by`, `created_at`) VALUES
	('1', '2022-06-01', 'CASH', NULL, 10000.00, '1', '2022-06-01 00:00:00');

-- --------------------------------------------------------------
-- 9. FEE RECEIPTS
-- This table will store the fee receipts for the students.
-- --------------------------------------------------------------
CREATE TABLE `std_fee_receipts` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `payment_id`         INT UNSIGNED NOT NULL,
    `receipt_no`         VARCHAR(50) NOT NULL,
    `receipt_date`       DATE NOT NULL,
    `total_amount`       DECIMAL(10,2) NOT NULL,
    `pdf_path`           VARCHAR(255) NULL,
    `is_cancelled`       TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_receipt_no` (`receipt_no`),
    CONSTRAINT `fk_receipt_payment` FOREIGN KEY (`payment_id`) REFERENCES `std_fee_payments` (`payment_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_fee_receipts` (`payment_id`, `receipt_no`, `receipt_date`, `total_amount`, `pdf_path`, `is_cancelled`, `created_at`) VALUES
	('1', '2022-06-01', '2022-06-01', 10000.00, NULL, 0, '2022-06-01 00:00:00');

-- --------------------------------------------------------------
-- 10. STUDENT FEE STATUS HISTORY
-- This table will store the fee status history for the students.
-- --------------------------------------------------------------
CREATE TABLE `std_student_fee_status_history` (
    `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `student_id`         INT UNSIGNED NOT NULL,
    `old_status`         ENUM('ACTIVE','OVERDUE','REMOVED','READMISSION_PENDING') NOT NULL,
    `new_status`         ENUM('ACTIVE','OVERDUE','REMOVED','READMISSION_PENDING') NOT NULL,
    `reason`             VARCHAR(255) NULL,
    `changed_by`         INT UNSIGNED NULL,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status_student` (`student_id`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_student_fee_status_history` (`student_id`, `old_status`, `new_status`, `reason`, `changed_by`, `created_at`) VALUES
	('1', 'ACTIVE', 'OVERDUE', 'Fee not paid on time', '1', '2022-06-01 00:00:00');

-- --------------------------------------------------------------
-- 11. STUDENT FEE SNAPSHOT (AI / REPORTING)
-- This table will store the fee snapshot for the students.
-- --------------------------------------------------------------
CREATE TABLE `std_student_fee_snapshot` (
    `id`                 INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `student_id`         INT UNSIGNED NOT NULL,  -- FK to std_students.id
    `fee_structure_id`   INT UNSIGNED NOT NULL,  -- FK to std_fee_structures.id
    `total_fee`          DECIMAL(12,2) NOT NULL,
    `total_paid`         DECIMAL(12,2) NOT NULL,
    `total_fine`         DECIMAL(12,2) NOT NULL,
    `outstanding`        DECIMAL(12,2) NOT NULL,
    `overdue_days`       INT NOT NULL,
    `risk_score`         DECIMAL(5,2) NULL,
    `last_calculated_at` TIMESTAMP NOT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	INSERT INTO `std_student_fee_snapshot` (`student_id`, `fee_structure_id`, `total_fee`, `total_paid`, `total_fine`, `outstanding`, `overdue_days`, `risk_score`, `last_calculated_at`) VALUES
	('1', '1', '10000.00', '10000.00', '0.00', '0.00', '0', '0.00', '2022-06-01 00:00:00');


