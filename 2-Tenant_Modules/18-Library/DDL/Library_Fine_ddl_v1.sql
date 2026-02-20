-- =====================================================
-- ENHANCED FINE MANAGEMENT TABLES
-- =====================================================

-- ----------------------------------------------------------------------------
-- 1. FINE SLAB CONFIGURATION TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lib_fine_slab_config` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Standard Student Fine Slab, Staff Fine Slab',
    `membership_type_id` INT NULL COMMENT 'If NULL, applies to all membership types',
    `resource_type_id` INT NULL COMMENT 'If NULL, applies to all resource types',
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') DEFAULT 'Late Return',
    `max_fine_amount` DECIMAL(10,2) NULL COMMENT 'Maximum fine cap (could be book cost or school-defined limit)',
    `max_fine_type` ENUM('Fixed', 'BookCost', 'Unlimited') DEFAULT 'Unlimited',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE NULL,
    `priority` INT DEFAULT 0 COMMENT 'Higher priority slabs are evaluated first',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`),
    INDEX `idx_fine_slab_membership` (`membership_type_id`),
    INDEX `idx_fine_slab_active` (`is_active`, `effective_from`, `effective_to`),
    INDEX `idx_fine_slab_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. FINE SLAB DETAILS TABLE (for day ranges)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lib_fine_slab_details` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `fine_slab_config_id` INT NOT NULL,
    `from_day` INT NOT NULL CHECK (from_day >= 0),
    `to_day` INT NOT NULL CHECK (to_day >= from_day),
    `rate_per_day` DECIMAL(10,2) NOT NULL,
    `rate_type` ENUM('Fixed', 'Percentage') DEFAULT 'Fixed' COMMENT 'Fixed amount or percentage of book cost',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_slab_days` (`fine_slab_config_id`, `from_day`, `to_day`),
    INDEX `idx_slab_day_range` (`from_day`, `to_day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. ENHANCED LIB_FINES TABLE (modified)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` BIGINT NOT NULL,
    `member_id` INT NOT NULL,
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    `days_overdue` INT NOT NULL DEFAULT 0,
    `calculated_from` DATE NOT NULL,
    `calculated_to` DATE NOT NULL,
    `fine_slab_config_id` INT NULL COMMENT 'Reference to slab used for calculation',
    `calculation_breakdown` JSON COMMENT 'Stores day-wise breakdown of fine calculation',
    `waived_amount` DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),
    `waived_by_id` INT NULL,
    `waived_reason` TEXT NULL,
    `waived_at` DATETIME NULL,
    `status` ENUM('Pending', 'Paid', 'Waived', 'Overdue') DEFAULT 'Pending',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    FOREIGN KEY (`waived_by_id`) REFERENCES `users`(id),
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    INDEX `idx_fine_transaction` (`transaction_id`),
    INDEX `idx_fine_member` (`member_id`, `status`),
    INDEX `idx_fine_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 4. UPDATED AUTO-CALCULATE FINES EVENT
-- ----------------------------------------------------------------------------

DELIMITER $$

CREATE OR REPLACE EVENT auto_calculate_fines_slab_based
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE
DO
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_transaction_id BIGINT;
    DECLARE v_copy_id INT;
    DECLARE v_member_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_membership_type_id INT;
    DECLARE v_resource_type_id INT;
    DECLARE v_book_cost DECIMAL(10,2);
    DECLARE v_days_overdue INT;
    DECLARE v_fine_amount DECIMAL(10,2);
    DECLARE v_breakdown JSON;
    DECLARE v_slab_config_id INT;
    DECLARE v_max_fine DECIMAL(10,2);
    DECLARE v_max_fine_type VARCHAR(20);
    
    DECLARE cur CURSOR FOR 
        SELECT 
            t.id, t.copy_id, t.member_id, t.due_date,
            m.membership_type_id,
            b.resource_type_id,
            bc.purchase_price
        FROM lib_transactions t
        INNER JOIN lib_members m ON t.member_id = m.id
        INNER JOIN lib_book_copies bc ON t.copy_id = bc.id
        INNER JOIN lib_books_master b ON bc.book_id = b.id
        WHERE t.status = 'issued' 
            AND t.due_date < CURDATE()
            AND NOT EXISTS (
                SELECT 1 FROM lib_fines f 
                WHERE f.transaction_id = t.id 
                AND f.fine_type = 'Late Return'
                AND f.status = 'Pending'
            );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_transaction_id, v_copy_id, v_member_id, v_due_date, 
                      v_membership_type_id, v_resource_type_id, v_book_cost;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Calculate days overdue considering grace period
        SELECT DATEDIFF(CURDATE(), v_due_date) INTO v_days_overdue;
        
        -- Get applicable fine slab with highest priority
        SELECT 
            fsc.id, fsc.max_fine_amount, fsc.max_fine_type
        INTO v_slab_config_id, v_max_fine, v_max_fine_type
        FROM lib_fine_slab_config fsc
        WHERE fsc.is_active = 1
            AND fsc.effective_from <= CURDATE()
            AND (fsc.effective_to IS NULL OR fsc.effective_to >= CURDATE())
            AND (fsc.membership_type_id IS NULL OR fsc.membership_type_id = v_membership_type_id)
            AND (fsc.resource_type_id IS NULL OR fsc.resource_type_id = v_resource_type_id)
        ORDER BY fsc.priority DESC, fsc.id
        LIMIT 1;
        
        -- Calculate fine based on slab if config found
        IF v_slab_config_id IS NOT NULL THEN
            -- Call stored procedure to calculate slab-based fine
            CALL calculate_slab_fine(
                v_slab_config_id, 
                v_days_overdue, 
                v_book_cost,
                v_fine_amount,
                v_breakdown
            );
            
            -- Apply max fine cap
            IF v_max_fine_type = 'Fixed' AND v_max_fine IS NOT NULL THEN
                SET v_fine_amount = LEAST(v_fine_amount, v_max_fine);
            ELSEIF v_max_fine_type = 'BookCost' AND v_book_cost > 0 THEN
                SET v_fine_amount = LEAST(v_fine_amount, v_book_cost);
            END IF;
            
            -- Insert fine record
            INSERT INTO lib_fines (
                transaction_id, member_id, fine_type, amount, 
                days_overdue, calculated_from, calculated_to,
                fine_slab_config_id, calculation_breakdown, status
            ) VALUES (
                v_transaction_id, v_member_id, 'Late Return', v_fine_amount,
                v_days_overdue, v_due_date, CURDATE(),
                v_slab_config_id, v_breakdown, 'Pending'
            );
        END IF;
        
    END LOOP;
    
    CLOSE cur;
END$$

-- ----------------------------------------------------------------------------
-- 5. STORED PROCEDURE FOR SLAB-BASED FINE CALCULATION
-- ----------------------------------------------------------------------------

CREATE PROCEDURE calculate_slab_fine(
    IN p_slab_config_id INT,
    IN p_days_overdue INT,
    IN p_book_cost DECIMAL(10,2),
    OUT p_fine_amount DECIMAL(10,2),
    OUT p_breakdown JSON
)
BEGIN
    DECLARE v_from_day INT;
    DECLARE v_to_day INT;
    DECLARE v_rate_per_day DECIMAL(10,2);
    DECLARE v_rate_type VARCHAR(20);
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_remaining_days INT;
    DECLARE v_slab_days INT;
    DECLARE v_slab_fine DECIMAL(10,2);
    DECLARE v_breakdown_array JSON DEFAULT JSON_ARRAY();
    
    DECLARE cur_slabs CURSOR FOR 
        SELECT from_day, to_day, rate_per_day, rate_type
        FROM lib_fine_slab_details
        WHERE fine_slab_config_id = p_slab_config_id
        ORDER BY from_day;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    SET p_fine_amount = 0;
    SET v_remaining_days = p_days_overdue;
    
    OPEN cur_slabs;
    
    slab_loop: LOOP
        FETCH cur_slabs INTO v_from_day, v_to_day, v_rate_per_day, v_rate_type;
        
        IF v_done THEN
            LEAVE slab_loop;
        END IF;
        
        -- Calculate days applicable for this slab
        IF v_remaining_days <= 0 THEN
            LEAVE slab_loop;
        END IF;
        
        SET v_slab_days = LEAST(v_remaining_days, (v_to_day - v_from_day + 1));
        
        -- Calculate fine for this slab
        IF v_rate_type = 'Fixed' THEN
            SET v_slab_fine = v_slab_days * v_rate_per_day;
        ELSE -- Percentage of book cost
            SET v_slab_fine = v_slab_days * (p_book_cost * v_rate_per_day / 100);
        END IF;
        
        -- Add to total
        SET p_fine_amount = p_fine_amount + v_slab_fine;
        
        -- Build breakdown JSON
        SET v_breakdown_array = JSON_ARRAY_APPEND(
            v_breakdown_array,
            '$',
            JSON_OBJECT(
                'from_day', v_from_day,
                'to_day', v_to_day,
                'days_applied', v_slab_days,
                'rate', v_rate_per_day,
                'rate_type', v_rate_type,
                'slab_fine', v_slab_fine
            )
        );
        
        SET v_remaining_days = v_remaining_days - v_slab_days;
        
    END LOOP;
    
    CLOSE cur_slabs;
    
    SET p_breakdown = JSON_OBJECT(
        'total_days', p_days_overdue,
        'total_fine', p_fine_amount,
        'breakdown', v_breakdown_array,
        'calculated_at', NOW()
    );
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 6. SAMPLE SEED DATA FOR FINE SLABS
-- ----------------------------------------------------------------------------

-- Standard Student Fine Slab
INSERT INTO lib_fine_slab_config 
(name, membership_type_id, fine_type, max_fine_amount, max_fine_type, effective_from, priority) 
VALUES 
('Student Late Fine Slab', 
    (SELECT id FROM lib_membership_types WHERE code = 'STD_STUDENT'), 
    'Late Return', 500.00, 'Fixed', CURDATE(), 10);

SET @student_slab = LAST_INSERT_ID();

INSERT INTO lib_fine_slab_details (fine_slab_config_id, from_day, to_day, rate_per_day, rate_type) VALUES
(@student_slab, 1, 10, 10.00, 'Fixed'),
(@student_slab, 11, 20, 20.00, 'Fixed'),
(@student_slab, 21, 30, 30.00, 'Fixed'),
(@student_slab, 31, 999, 50.00, 'Fixed');

-- Staff Fine Slab (lower rates)
INSERT INTO lib_fine_slab_config 
(name, membership_type_id, fine_type, max_fine_amount, max_fine_type, effective_from, priority) 
VALUES 
('Staff Late Fine Slab', 
    (SELECT id FROM lib_membership_types WHERE code = 'STD_STAFF'), 
    'Late Return', NULL, 'Unlimited', CURDATE(), 10);

SET @staff_slab = LAST_INSERT_ID();

INSERT INTO lib_fine_slab_details (fine_slab_config_id, from_day, to_day, rate_per_day, rate_type) VALUES
(@staff_slab, 1, 15, 5.00, 'Fixed'),
(@staff_slab, 16, 30, 10.00, 'Fixed'),
(@staff_slab, 31, 999, 20.00, 'Fixed');

-- Premium Student Slab
INSERT INTO lib_fine_slab_config 
(name, membership_type_id, fine_type, max_fine_amount, max_fine_type, effective_from, priority) 
VALUES 
('Premium Student Late Fine Slab', 
    (SELECT id FROM lib_membership_types WHERE code = 'PREMIUM_STUDENT'), 
    'Late Return', 1000.00, 'Fixed', CURDATE(), 10);

SET @premium_slab = LAST_INSERT_ID();

INSERT INTO lib_fine_slab_details (fine_slab_config_id, from_day, to_day, rate_per_day, rate_type) VALUES
(@premium_slab, 1, 10, 8.00, 'Fixed'),
(@premium_slab, 11, 20, 15.00, 'Fixed'),
(@premium_slab, 21, 30, 25.00, 'Fixed'),
(@premium_slab, 31, 999, 40.00, 'Fixed');

