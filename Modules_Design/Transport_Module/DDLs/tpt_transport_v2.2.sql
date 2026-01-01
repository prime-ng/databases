-- =======================================================================
-- TRANSPORT MODULE v2.0 for MySQL 8.x
-- Strategy: Enhanced v1.9 with Vendor Lease, Billing, and Payment tables.
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- TRANSPORT MASTER TABLES
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,              -- Vehicle number(Vehicle Identification Number (VIN)/Chassis Number: A unique 17-character code stamped on the vehicle's chassis)
    `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
    `model` VARCHAR(50),                            -- Vehicle model
    `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
    `vehicle_type_id` BIGINT UNSIGNED NOT NULL,     -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type_id` BIGINT UNSIGNED NOT NULL,        -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
    `max_capacity` INT UNSIGNED NOT NULL DEFAULT 40, -- Maximum allowed capacity including standing
    `ownership_type_id` BIGINT UNSIGNED NOT NULL,   -- fk to sys_dropdown_table ('Owned','Leased','Rented')
    `vendor_id` BIGINT UNSIGNED NOT NULL,           -- fk to tpt_vendor
    `fitness_valid_upto` DATE NOT NULL,             -- Fitness certificate expiry date
    `insurance_valid_upto` DATE NOT NULL,           -- Insurance expiry date
    `pollution_valid_upto` DATE NOT NULL,           -- Pollution certificate expiry date
    `vehicle_emission_class_id` BIGINT UNSIGNED NOT NULL,  -- fk to sys_dropdown_table ('BS IV', 'BS V', 'BS VI')
    `fire_extinguisher_valid_upto` DATE NOT NULL,    -- Fire extinguisher expiry date
    `gps_device_id` VARCHAR(50),                    -- Installed GPS device identifier
    `vehicle_photo_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (vehicle photo will be uploaded in sys.media)
    `registration_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (registration certificate will be uploaded in sys.media)
    `fitness_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (fitness certificate will be uploaded in sys.media)
    `insurance_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (insurance certificate will be uploaded in sys.media)
    `pollution_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (pollution certificate will be uploaded in sys.media)
    `vehicle_emission_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (vehicle emission certificate will be uploaded in sys.media)
    `fire_extinguisher_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (fire extinguisher certificate will be uploaded in sys.media)
    `gps_device_cert_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (gps device certificate will be uploaded in sys.media)
    `availability_status` tinyint(1) unsigned not null default 1,  -- 0: Not Available, 1: Available
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`),
    CONSTRAINT `fk_vehicle_vehicle_type` FOREIGN KEY (`vehicle_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vehicle_fuel_type` FOREIGN KEY (`fuel_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vehicle_ownership_type` FOREIGN KEY (`ownership_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vehicle_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `tpt_vendor`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vehicle_vehicle_emission_class` FOREIGN KEY (`vehicle_emission_class_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,
    `user_qr_code` VARCHAR(30) NOT NULL,
    `id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,     -- ID Type (e.g., Aadhaar, PAN, Passport)
    `id_no` VARCHAR(100) DEFAULT NULL,      -- ID Number   
    `role` VARCHAR(20) NOT NULL,            -- Role (e.g., Driver, Helper, Transport Manager etc.)
    `license_no` VARCHAR(50) DEFAULT NULL,  -- License Number
    `license_valid_upto` DATE DEFAULT NULL,  -- License Valid Upto
    `assigned_vehicle_id` BIGINT UNSIGNED DEFAULT NULL,  -- fk to tpt_vehicle
    `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,  -- Driving Experience in Months
    `police_verification_done` TINYINT(1) NOT NULL DEFAULT 0,  -- 0: Not Done, 1: Done
    `address` VARCHAR(512) DEFAULT NULL,
    `id_card_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (id card will be uploaded in sys.media)
    `photo_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (photo will be uploaded in sys.media)
    `driving_license_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (driving license will be uploaded in sys.media)
    `police_verification_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (police verification will be uploaded in sys.media)
    `address_proof_upload` tinyint(1) unsigned not null default 0,  -- 0: Not Uploaded, 1: Uploaded (address proof will be uploaded in sys.media)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_shift` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_shift_code` (`code`),
    UNIQUE KEY `uq_shift_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
CREATE TABLE IF NOT EXISTS `tpt_route` (
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_route_code` (`code`),
    UNIQUE KEY `uq_route_name` (`name`),
    SPATIAL INDEX `sp_idx_route_geometry` (`route_geometry`),
    CONSTRAINT `fk_route_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `location` POINT NOT NULL SRID 4326,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickup_code` (`code`),
    UNIQUE KEY `uq_pickup_name` (`name`),
    SPATIAL INDEX `sp_idx_pickup_location` (`location`),
    CONSTRAINT `fk_pickupPoint_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `pickup_point_id` BIGINT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `arrival_time` INT DEFAULT NULL,
    `departure_time` INT DEFAULT NULL,   
    `estimated_time` INT DEFAULT NULL,
    `pickup_drop_fare` DECIMAL(10,2) DEFAULT NULL,  -- One Side (Pickup / Drop) Fare
    `both_side_fare` DECIMAL(10,2) DEFAULT NULL,    -- Bothside Fare if Student choose same Stop for Pickup & Drop both
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickupPointRoute_route_pickupPoint` (`route_id`,`pickup_drop`,`pickup_point_id`),
    KEY `idx_pprj_route_ordinal` (`route_id`, `ordinal`),
    CONSTRAINT `fk_pickupPointRoute_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pickupPointRoute_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pickupPointRoute_pickupPointId` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- ROUTE SCHEDULE & DRIVER ASSIGNMENT
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `total_students` INT NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_routeVehicle_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_routeId` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_vehicleId` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_driverId` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_helperId` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER `trg_driver_route_vehicle_unique_assignment`
BEFORE INSERT ON `tpt_driver_route_vehicle_jnt`
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM `tpt_driver_route_vehicle_jnt`
        WHERE `shift_id` = NEW.`shift_id`
          AND `route_id` = NEW.`route_id`
          AND `vehicle_id` = NEW.`vehicle_id`
          AND `driver_id` = NEW.`driver_id`
          AND (
              (NEW.`effective_to` IS NULL AND (`effective_to` IS NULL OR `effective_to` >= NEW.`effective_from`))
              OR
              (NEW.`effective_to` IS NOT NULL AND (
                  (`effective_from` <= NEW.`effective_to` AND `effective_to` >= NEW.`effective_from`)
              ))
          )
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Overlapping assignment for the same shift, route, vehicle, and driver.';
    END IF;
END$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scheduled_date` DATE NOT NULL,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_route_scheduler_schedDate_shift_route` (`scheduled_date`,`shift_id`,`route_id`,`pickup_drop`),
    UNIQUE KEY `uq_route_scheduler_vehicle_schedDate_shift` (`vehicle_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
    UNIQUE KEY `uq_route_scheduler_driver_schedDate_shift` (`driver_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
    UNIQUE KEY `uq_route_scheduler_helper_schedDate_shift` (`helper_id`,`scheduled_date`,`shift_id`,`pickup_drop`),
    CONSTRAINT `fk_sched_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- TRIPS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,      --  Date of the trip
    `route_scheduler_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_route_scheduler_jnt
    `vehicle_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_vehicle
    `driver_id` BIGINT UNSIGNED NOT NULL, -- FK to tpt_personnel
    `helper_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to tpt_personnel
    `start_time` DATETIME DEFAULT NULL, -- Start time of the trip
    `end_time` DATETIME DEFAULT NULL, -- End time of the trip
    `start_odometer_reading` DECIMAL(11, 2) DEFAULT 0.00,
    `end_odometer_reading` DECIMAL(11, 2) DEFAULT 0.00,
    `start_fuel_reading` DECIMAL(8, 3) DEFAULT 0.00,
    `end_fuel_reading` DECIMAL(8, 3) DEFAULT 0.00,
    `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled',
    `approved` TINYINT(1) NOT NULL DEFAULT 0,
    `approved_by` BIGINT UNSIGNED DEFAULT NULL,
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `remarks` VARCHAR(512) DEFAULT NULL, 
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_trip_routeSched_tripDate` (`route_scheduler_id`, `trip_date`),
    KEY `idx_trip_vehicle` (`vehicle_id`),
    CONSTRAINT `fk_trip_route_scheduler` FOREIGN KEY (`route_scheduler_id`) REFERENCES `tpt_route_scheduler_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_trip_stop_detail` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `sch_arrival_time` DATETIME DEFAULT NULL,
    `sch_departure_time` DATETIME DEFAULT NULL,
    `reached_flag` TINYINT(1) NOT NULL DEFAULT 0,
    `reaching_time` TIMESTAMP DEFAULT NULL,
    `leaving_time` TIMESTAMP DEFAULT NULL,
    `emergency_flag` TINYINT(1) DEFAULT 0,
    `emergency_time` TIMESTAMP DEFAULT NULL,
    `emergency_remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `updated_by` BIGINT UNSIGNED DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_trip_stop_detail_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_trip_stop_detail_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_trip_stop_detail_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- DRIVER ATTENDANCE
-- =======================================================================

-- CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
--     `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--     `device_code` VARCHAR(50) NOT NULL UNIQUE,
--     `device_name` VARCHAR(100) NOT NULL,
--     `device_type` ENUM('Mobile','Scanner','Tablet','Gate') NOT NULL,
--     `location` VARCHAR(150) NULL,
--     `is_active` TINYINT(1) NOT NULL DEFAULT 1,
--     `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
    `id` BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,     -- fk to tpt_personnel
    `device_uuid` CHAR(36) NOT NULL,        -- Unique identifier of the device
    `device_type` ENUM('Mobile','Tablet','Laptop','Desktop') NOT NULL,
    `location` VARCHAR(150) NULL,
    `device_os` BIGINT NOT NULL,            -- fk to sys_dropdown_table ('android','ios','windows','linux','mac')
    `os_version` VARCHAR(50),               -- OS version
    `device_name` VARCHAR(100) NOT NULL,
    `device_model` VARCHAR(100),            -- Device model e.g. iPhone 12 Pro
    `pg_app_version` VARCHAR(20),           -- App version e.g. 1.0.0
    `pg_fcm_token` TEXT,                    -- FCM token of the device e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
    `pg_first_registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `pg_last_seen_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_attendance_device_user` (`user_id`),
    UNIQUE KEY uq_device (device_uuid),
    UNIQUE KEY uq_user_device (user_id, device_uuid),
    CONSTRAINT `fk_attendance_device_user` FOREIGN KEY (`user_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `attendance_date` DATE NOT NULL,
    `first_in_time` DATETIME NULL,
    `last_out_time` DATETIME NULL,
    `total_work_minutes` INT NULL,
    `attendance_status` ENUM('Present','Absent','Half-Day','Late') NOT NULL,
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_driver_day` (`driver_id`, `attendance_date`),
    FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `attendance_id` BIGINT UNSIGNED NOT NULL,
    `scan_time` DATETIME NOT NULL,
    `attendance_type` ENUM('IN','OUT') NOT NULL,
    `scan_method` ENUM('QR','RFID','NFC','Manual') NOT NULL,
    `device_id` BIGINT UNSIGNED NOT NULL,
    `latitude` DECIMAL(10,6) NULL,
    `longitude` DECIMAL(10,6) NULL,
    `scan_status` ENUM('Valid','Duplicate','Rejected') NOT NULL DEFAULT 'Valid',
    `remarks` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_da_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `tpt_driver_attendance`(`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_da_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED NOT NULL,
    `student_id` BIGINT UNSIGNED NOT NULL,
    `pickup_route_id` BIGINT UNSIGNED NOT NULL,
    `pickup_stop_id` BIGINT UNSIGNED NOT NULL,
    `drop_route_id` BIGINT UNSIGNED NOT NULL,
    `drop_stop_id` BIGINT UNSIGNED NOT NULL,
    `fare` DECIMAL(10,2) NOT NULL,
    `effective_from` DATE NOT NULL,
    `active_status` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sa_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_sessions_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- TRANSPORT FEE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` BIGINT UNSIGNED NOT NULL,
    `fine_from_days` TINYINT DEFAULT 0,
    `fine_to_days` TINYINT DEFAULT 0,
    `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
    `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
    `student_restricted` TINYINT(1) DEFAULT 0,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_student_fee_detail` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` BIGINT UNSIGNED NOT NULL,
    `month` DATE NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `total_amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'Pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_student_fine_detail` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_fee_detail_id` BIGINT UNSIGNED NOT NULL,
    `fine_master_id` BIGINT UNSIGNED NOT NULL,
    `fine_days` TINYINT DEFAULT 0,
    `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
    `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `waved_fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `net_fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sf_master` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sf_fine_master` FOREIGN KEY (`fine_master_id`) REFERENCES `tpt_fine_master`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_student_fee_collection` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_fee_detail_id` BIGINT UNSIGNED NOT NULL,
    `payment_date` DATE NOT NULL,
    `total_delay_days` INT DEFAULT 0,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_mode`  VARCHAR(20) NOT NULL,
    `status` VARCHAR(20) NOT NULL,
    `reconciled` TINYINT(1) NOT NULL DEFAULT 0,
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_fc_fee_detail` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT
    -- Removed fk_fc_master as tpt_fee_master is not directly linked here in v1.9 schema provided in context,
    -- or if it was intended, the column fee_master_id was missing in the column list in v1.9.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `std_student_pay_log` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` BIGINT UNSIGNED NOT NULL,
  `academic_session_id` BIGINT UNSIGNED NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `activity_type` VARCHAR(50) NOT NULL,
  `amount` DECIMAL(10,2) DEFAULT NULL,
  `log_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reference_id` BIGINT UNSIGNED DEFAULT NULL,
  `reference_table` VARCHAR(100) DEFAULT NULL,
  `description` VARCHAR(512) DEFAULT NULL,
  `triggered_by` BIGINT UNSIGNED DEFAULT NULL,
  `is_system_generated` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_payLog_student` (`student_id`),
  KEY `idx_payLog_module` (`module_name`),
  KEY `idx_payLog_date` (`log_date`),
  KEY `idx_payLog_reference` (`reference_table`, `reference_id`),
  KEY `idx_payLog_trigger` (`triggered_by`),
  CONSTRAINT `fk_payLog_studentId` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_payLog_sessionId` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_payLog_triggeredBy` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- FUEL & MAINTENANCE
-- =======================================================================

-- Single Screen - 5 tab (Fuel, Inspection, Service Request, Maintenance, Approval)

CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED DEFAULT NULL,
    `date` DATE NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `fuel_type` BIGINT UNSIGNED NOT NULL,
    `odometer_reading` BIGINT UNSIGNED DEFAULT NULL,
    `remarks` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vfl_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
    -- 1. After Fuel Entry, it need to be approved by the adminAuthorised Personnel.
    -- 2. To make sure the availaibility of Approval to the Authorise Person only, we need to keep Approval on Fuel & Maintenance on a seperate Tab.

Create Table if not EXISTS `tpt_daily_vehicle_inspection` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED DEFAULT NULL,
    `inspection_date` TIMESTAMP NOT NULL,
    `odometer_reading` BIGINT UNSIGNED DEFAULT NULL,
    `fuel_level_reading` DECIMAL(6,2) DEFAULT NULL,
    `tire_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `lights_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `brakes_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `engine_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `battery_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `fire_extinguisher_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `first_aid_kit_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `seat_belts_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `headlights_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `tailights_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `wipers_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `mirrors_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `steering_wheel_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `emergency_tools_condition_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `cleanliness_ok` TINYINT(1) NOT NULL DEFAULT 0,
    `any_issues_found` TINYINT(1) NOT NULL DEFAULT 0,
    `issues_description` VARCHAR(512) DEFAULT NULL,
    `remarks` VARCHAR(512) DEFAULT NULL,
    `inspection_status` ENUM('Passed','Failed','Pending') NOT NULL DEFAULT 'Pending',
    `inspected_by` BIGINT UNSIGNED DEFAULT NULL, 
    `inspected_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_dvil_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_dvil_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_dvil_inspectedBy` FOREIGN KEY (`inspected_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
    -- 1. If Inspection is Failed, a new entry will be created in 'tpt_vehicle_service_request' table with available information.
    -- 2. If Inspection is Failed, application will change Status in the "tpt_Vehicle make '`availability_status` to 'Not Available'



Create Table if not EXISTS `tpt_vehicle_service_request` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_inspection_id` BIGINT UNSIGNED NOT NULL,
    `request_date` TIMESTAMP NOT NULL,
    `reason` VARCHAR(512) DEFAULT NULL,  -- Reason can be filled by anyone
    `Vehicle_status` BIGINT UNSIGNED DEFAULT NULL,  -- fk to sys_dropdown_table ('Due for Service', 'In-Service', 'Service Done')
    `service_completion_date` TIMESTAMP NULL DEFAULT NULL,
    `request_approval_status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
    `approved_by` BIGINT UNSIGNED DEFAULT NULL,
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vsl_vehicleInspection` FOREIGN KEY (`vehicle_inspection_id`) REFERENCES `tpt_daily_vehicle_inspection`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vsl_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
    -- 1. If Inspection is Failed, a new entry will be created in 'tpt_vehicle_service_request' table with available information.
    -- 2. To make sure the availaibility of Approval to the Authorise Person only, we need to keep Approval in a seperate Tab.
    -- 3. user can create a new entry in 'tpt_vehicle_service_request' table as per the need.
    -- 4. Once Request i Approved by Authorised Person, a new entry will be created in 'tpt_vehicle_maintenance' table with available information.
    -- 5. Direct Entry in 'tpt_vehicle_maintenance' table is not allowed. 
    -- 6. Once Entry is created in 'tpt_vehicle_service_request' table, it will be redirected to 'tpt_vehicle_maintenance' table.


CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_service_request_id` BIGINT UNSIGNED NOT NULL,
    `maintenance_initiation_date` DATE NOT NULL,  -- Date of Service Initiated (Vehicle reached in garage)
    `maintenance_type` VARCHAR(120) NOT NULL,    -- Mannual Entry
    `cost` DECIMAL(12,2) NOT NULL,
    `in_service_date` DATE DEFAULT NULL,   -- Date of Service Initiated (Vehicle reached in garage)
    `out_service_date` DATE DEFAULT NULL,  -- Date of Service Completion 
    `workshop_details` VARCHAR(512) DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,     -- Next Due Date (if Any)
    `remarks` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
    `approved_by` BIGINT UNSIGNED DEFAULT NULL,
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vm_vehicle_service_request` FOREIGN KEY (`vehicle_service_request_id`) REFERENCES `tpt_vehicle_service_request`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vm_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition:
    -- 1. New Entry Can not be created in 'tpt_vehicle_maintenance' table. Only Edit of existing entry is allowed.
    -- 2. Approval of Both the Tables should be done by Authorised Person in "Approval" Tab.
    -- 3. Once Maintenance Entry is Approved by Authorised Person, it will create a entry in 'vnd_vendor_bill_due_for_payment' table.

-- =======================================================================
-- TRIP INCIDENTS & ALERTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `incident_time` TIMESTAMP NOT NULL,
    `incident_type` BIGINT UNSIGNED NOT NULL,
    `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `status` BIGINT UNSIGNED DEFAULT NULL,
    `raised_by` BIGINT UNSIGNED DEFAULT NULL,  -- fk to sys_users
    `raised_at` TIMESTAMP NULL DEFAULT NULL,    -- When Incident is Raised
    `resolved_at` TIMESTAMP NULL DEFAULT NULL,  -- When Incident is Resolved
    `resolved_by` BIGINT UNSIGNED DEFAULT NULL,  -- fk to sys_users
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ti_raisedBy` FOREIGN KEY (`raised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ti_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------------------------------------------
-- New Tables
-- ---------------------------------------------------------------------------------------------------------------

-- =======================================================================
-- STUDENT BOARD/UN-BOARD EVENTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_boarding_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,
    `student_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK to tpt_students
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_student_session
    `boarding_route_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_routes
    `boarding_trip_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_trip
    `boarding_stop_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_pickup_points
    `boarding_time` DATETIME DEFAULT NULL,
    `unboarding_route_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_routes
    `unboarding_trip_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_trip
    `unboarding_stop_id` BIGINT UNSIGNED DEFAULT NULL,   -- FK to tpt_pickup_points
    `unboarding_time` DATETIME DEFAULT NULL,
    `device_id` BIGINT UNSIGNED DEFAULT NULL,  -- FK to tpt_attendance_device
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sel_student` FOREIGN KEY (`student_id`) REFERENCES `tpt_students`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `tpt_student_session`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_boardingRoute` FOREIGN KEY (`boarding_route_id`) REFERENCES `tpt_routes`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_boardingTrip` FOREIGN KEY (`boarding_trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_boardingStop` FOREIGN KEY (`boarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_unboardingRoute` FOREIGN KEY (`unboarding_route_id`) REFERENCES `tpt_routes`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_unboardingTrip` FOREIGN KEY (`unboarding_trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_unboardingStop` FOREIGN KEY (`unboarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sel_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- NOTIFICATIONS & LOGS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_notification_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
    `trip_id` BIGINT UNSIGNED DEFAULT NULL,
    `boarding_stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `notification_type` ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') DEFAULT NULL,
    `sent_time` DATETIME DEFAULT NULL,
    `app_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
    `sms_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
    `email_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
    `whatsapp_notification_status` ENUM('NotRegistered','Sent','Failed') DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_nl_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `tpt_student_session`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- AUDIT TRACKING. 
-- This may not be required. we use Common Audit Log of the System
-- =======================================================================

-- CREATE TABLE IF NOT EXISTS `tpt_audit_log` (
--     `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
--     `entity` VARCHAR(128) NOT NULL,
--     `entity_id` BIGINT UNSIGNED DEFAULT NULL,
--     `action` VARCHAR(64) NOT NULL,
--     `performed_by` VARCHAR(128) DEFAULT NULL,
--     `payload` JSON DEFAULT NULL,
--     `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------------------------------------------------------------------
-- New Conditions:
-- 1. When Bus will complete the Trip and register it's Trip completion in the System. Someone (Authorise Person) will Approve the Trip Completion. 
-- 2. Application will check the Status of "trip_usage_needs_to_be_updated_into_vendor_usage_log" variable in "sch_settings" table.
-- 3. If "trip_usage_needs_to_be_updated_into_vendor_usage_log" is True, then application will update the 'vnd_usage_logs' with the Trip Usage.
-- -------------------------------------------------------------------------------------------------------------------
-- Change on 29th Dec 2025:
-- 1. Enhanced Table tpt_attendance_device to have unique device_uuid for each user.
-- 2. Add New Table tpt_student_boarding_log to track the Boarding and Unboarding of Students.
-- 3. Add New Table tpt_notification_log to track the Notifications sent to Students.
-- -------------------------------------------------------------------------------------------------------------------
-- Change on 31st Dec 2025:
-- 1. Changed the UNIQUE KEY `uq_pickupPointRoute_shift_pickupPoint` (`shift_id`,`route_id`,`pickup_point_id`), to `uq_pickupPointRoute_shift_pickupPoint` (`route_id`,`pickup_point_id`),
--    to make sure one Route can have multiple Pickup Points but One Route can be allocate only in one Shift.
-- 2. Change filed `route_id` to `pickup_route_id` in tpt_student_route_allocation_jnt
-- 3. Add filed `drop_route_id` in tpt_student_route_allocation_jnt
-- 4. Enhanced Table tpt_student_boarding_log to track the Boarding and Unboarding of Students.
-- 5. Enhanced Table tpt_student_route_allocation_jnt to have `pickup_route_id` and `drop_route_id`.
-- 6. Enhanced Table tpt_route to have `pickup_drop` field to define if the Route is for Pickup or Drop, can not be for Both.

