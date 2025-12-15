-- =======================================================================
-- TRANSPORT MODULE ENHANCED (v1.2) for MySQL 8.x
-- Strategy: Create staging objects, backfill from v1, verify, then atomic RENAME TABLE swap.
--
-- KEY ENHANCEMENTS:
-- 1. Soft Deletes: Added `deleted_at` TIMESTAMP column to all core tables for safe deletion
-- 2. SRID = 4326: All spatial columns (POINT, LINESTRING) use WGS84 coordinates for interoperability
-- 3. Spatial Indexes: Added SPATIAL INDEX on geometry columns for fast geo-queries
-- 4. Telemetry Indexes: Added composite indexes on (trip_id, log_time) and (vehicle_id, log_time)
-- 5. No Partition Clauses: As requested, no PARTITION BY clauses (add later via ALTER as needed)
-- 6. No org_id: Tenant isolation via separate database per tenant
--
-- BLUE-GREEN SWAP EXAMPLE (run after backfill & verification):
--   START TRANSACTION;
--   RENAME TABLE tpt_vehicle TO tpt_vehicle_old,
--                tpt_vehicle_staging TO tpt_vehicle,
--                tpt_vehicle_old TO tpt_vehicle_staging_old;
--   RENAME TABLE tpt_personnel TO tpt_personnel_old,
--                tpt_personnel_staging TO tpt_personnel,
--                tpt_personnel_old TO tpt_personnel_staging_old;
--   -- ... repeat for all tables ...
--   COMMIT;
--
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VEHICLE, DRIVER, HELPER, SHIFT
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,
    `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
    `model` VARCHAR(50),                            -- Vehicle model
    `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
    `vehicle_type` VARCHAR(20) NOT NULL,            -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type` VARCHAR(20) NOT NULL,               -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
    `ownership_type` VARCHAR(20) NOT NULL,          -- fk to sys_dropdown_table ('Owned','Leased','Rented')
    `fitness_valid_upto` DATE,                      -- Fitness certificate expiry date
    `insurance_valid_upto` DATE,                    -- Insurance expiry date
    `pollution_valid_upto` DATE,                    -- Pollution certificate expiry date
    `gps_device_id` VARCHAR(50),                    -- Installed GPS device identifier
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,         -- e.g., 'Aadhaar','Passport','DriverLicense'
    `id_no` VARCHAR(100) DEFAULT NULL,          -- Govt issued ID number
    `role` VARCHAR(20) NOT NULL,                -- fk to sys_role ('Driver','Helper','Conductor')
    `license_no` VARCHAR(50) DEFAULT NULL,      -- Driver's license number
    `license_valid_upto` DATE DEFAULT NULL,                 -- License expiry date
    `assigned_vehicle_id` BIGINT UNSIGNED DEFAULT NULL,     -- fk to tpt_vehicle
    `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,    -- Total driving experience in months
    `address` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_shift` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(20) NOT NULL,        --  Shift code e.g., 'MORNING', 'AFTERNOON'
    `name` VARCHAR(100) NOT NULL,
    `effective_from` DATE NOT NULL,     --  Shift validity period
    `effective_to` DATE NOT NULL,       --  Shift validity period
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_shift_code` (`code`),
    UNIQUE KEY `uq_shift_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- ROUTES & STOPS with SRID=4326
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_route` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` BIGINT UNSIGNED NOT NULL,        -- fk to tpt_shift
    `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,     -- WGS84 route path
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
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,      -- WGS84 latitude
    `longitude` DECIMAL(10,7) DEFAULT NULL,     -- WGS84 longitude
    `location` POINT NOT NULL SRID 4326,        -- WGS84 spatial point
    `total_distance` DECIMAL(7,2) DEFAULT NULL, -- Distance from route start in KM
    `estimated_time` INT DEFAULT NULL,          -- Estimated time from route start in minutes
    `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` BIGINT UNSIGNED NOT NULL,
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
    `pickup_point_id` BIGINT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickupPointRoute_shift_pickupPoint` (`shift_id`,`pickup_point_id`,`route_id`),
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
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
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

-- Prevent overlapping assignments for same vehicle/driver on same shift+route should be enforced at app or via triggers
CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scheduled_date` DATE NOT NULL,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `driver_id` BIGINT UNSIGNED DEFAULT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
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
    `trip_date` DATE NOT NULL,                      -- Date of the trip
    `pickup_route_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to 'tpt_route' for pickup
    `route_id` BIGINT UNSIGNED NOT NULL,            -- FK to 'tpt_route' for drop
    `vehicle_id` BIGINT UNSIGNED NOT NULL,          -- FK to 'tpt_vehicle'
    `driver_id` BIGINT UNSIGNED NOT NULL,           -- FK to 'tpt_personnel' for driver
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,       -- FK to 'tpt_personnel' for helper
    `trip_type` BIGINT UNSIGNED DEFAULT NULL,       -- FK to 'tpt_shift' for trip type
    `start_time` DATETIME DEFAULT NULL,             -- Actual start time
    `end_time` DATETIME DEFAULT NULL,               -- Actual end time
    `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled', -- fk to sys_dropdown_table
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_trip_route_sched` (`route_id`, `trip_date`),
    KEY `idx_trip_vehicle` (`vehicle_id`),
    CONSTRAINT `fk_trip_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_tripType` FOREIGN KEY (`trip_type`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- LIVE TRIP STATUS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_live_trip` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `current_stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `eta` DATETIME DEFAULT NULL,
    `reached_flag` TINYINT(1) NOT NULL DEFAULT 0,
    `emergency_flag` TINYINT(1) DEFAULT 0,
    `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_live_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_live_current_stop` FOREIGN KEY (`current_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- DRIVER ATTENDANCE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_out_time` DATETIME DEFAULT NULL,
    `geo_lat` DECIMAL(10,7) DEFAULT NULL,       -- Location of check-in
    `geo_lng` DECIMAL(10,7) DEFAULT NULL,       -- Location of check-in
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,    -- 1=App, 0=Manual
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_da_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_allocation_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED NOT NULL,  -- FK to 'std_student_sessions_jnt'
    `route_id` BIGINT UNSIGNED NOT NULL,            -- FK to 'tpt_route'
    `pickup_stop_id` BIGINT UNSIGNED NOT NULL,
    `drop_stop_id` BIGINT UNSIGNED NOT NULL,
    `fare` DECIMAL(10,2) NOT NULL,
    `effective_from` DATE NOT NULL,
    `active_status` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sa_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

11  Route -2    Pickpoint - 21  Fare 500.00 01/04/2025  
11  Route -4    Pickpoint - 12  Fare 700.00 01/10/2025

-- =======================================================================
-- TRANSPORT FEE
-- =======================================================================

-- define fines based on delay days
CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` BIGINT UNSIGNED NOT NULL,    -- FK to 'std_academic_sessions'
    `fine_from_days` TINYINT DEFAULT 0,
    `fine_to_days` TINYINT DEFAULT 0,
    `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
    `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- generate Invoice on 1st of every month for the month
-- Example: fine_from_days - 1  fine_to_days - 5  fine_type - 'Fixed'  fine_rate - 50.00
CREATE TABLE IF NOT EXISTS `tpt_fee_master` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` BIGINT UNSIGNED NOT NULL,    -- FK to 'std_academic_sessions'
    `month` DATE NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `total_amount` DECIMAL(10,2) NOT NULL,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'Pending',  -- FK - to sys_dropdown_table       e.g. 'Paid','Pending','Overdue'
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- link fines to fee master
CREATE TABLE IF NOT EXISTS `tpt_fee_fine_detail` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `fee_master_id` BIGINT UNSIGNED NOT NULL,    -- FK to 'tpt_fee_master'
    `fine_master_id` BIGINT UNSIGNED NOT NULL,   -- FK to 'tpt_fine_master'
    `fine_days` TINYINT DEFAULT 0,
    `fine_type` ENUM('Fixed','Percentage') DEFAULT 'Fixed',
    `fine_rate` DECIMAL(5,2) DEFAULT 0.00,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
    CONSTRAINT `fk_fc_master` FOREIGN KEY (`fee_master_id`) REFERENCES `tpt_fee_master`(`id`) ON DELETE RESTRICT
    CONSTRAINT `fk_fc_fine_master` FOREIGN KEY (`fine_master_id`) REFERENCES `tpt_fine_master`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Example: fee_master_id - 1  fine_days - 5  fine_type - 'Percentage'  fine_rate - 2.00

-- record fee payment against student allocation
CREATE TABLE IF NOT EXISTS `tpt_fee_collection` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_allocation_id` BIGINT UNSIGNED NOT NULL,
    `fee_master_id` BIGINT UNSIGNED NOT NULL,
    `payment_date` DATE NOT NULL,
    `total_delay_days` INT DEFAULT 0,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_mode`  VARCHAR(20) NOT NULL, -- FK - to sys_dropdown_table       e.g. 'Cash','Card','Online'
    `status` VARCHAR(20) NOT NULL,        -- FK - to sys_dropdown_table       e.g. 'Paid','Pending','Overdue'
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_fc_allocation` FOREIGN KEY (`student_allocation_id`) REFERENCES `tpt_student_allocation_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fc_master` FOREIGN KEY (`fee_master_id`) REFERENCES `tpt_fee_master`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- ML / FEATURE STORE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `ml_models` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(200) NOT NULL,
    `version` VARCHAR(50) NOT NULL,
    `model_type` VARCHAR(50) DEFAULT NULL,
    `artifact_uri` VARCHAR(1024) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `metrics` JSON DEFAULT NULL,
    `status` ENUM('TRAINED','DEPLOYED','DEPRECATED') DEFAULT 'TRAINED',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ml_model_name_version` (`name`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ml_model_features` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` BIGINT UNSIGNED NOT NULL,
    `feature_name` VARCHAR(200) NOT NULL,
    `feature_type` VARCHAR(50) DEFAULT NULL,
    `transformation` JSON DEFAULT NULL,
    CONSTRAINT `fk_mmf_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_feature_store` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `feature_date` DATE NOT NULL,
    `route_id` BIGINT UNSIGNED DEFAULT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `feature_vector` JSON NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_feature_date_route` (`feature_date`, `route_id`),
    CONSTRAINT `fk_fs_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fs_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_model_recommendations` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` BIGINT UNSIGNED NOT NULL,
    `model_version` VARCHAR(50) DEFAULT NULL,
    `run_id` VARCHAR(100) DEFAULT NULL,
    `generated_for_date` DATE DEFAULT NULL,
    `route_id` BIGINT UNSIGNED DEFAULT NULL,
    `recommended_path` LINESTRING SRID 4326 DEFAULT NULL,
    `predicted_time_minutes` INT DEFAULT NULL,
    `predicted_distance_km` DECIMAL(7,2) DEFAULT NULL,
    `confidence` DECIMAL(5,4) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    SPATIAL INDEX `sp_idx_recommended_path` (`recommended_path`),
    CONSTRAINT `fk_mr_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mr_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_recommendation_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `recommendation_id` BIGINT UNSIGNED NOT NULL,
    `applied_at` DATETIME DEFAULT NULL,
    `applied_by` BIGINT UNSIGNED DEFAULT NULL,
    `outcome` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_rh_recommendation` FOREIGN KEY (`recommendation_id`) REFERENCES `tpt_model_recommendations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT BOARD/ALIGHT EVENTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_event_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED DEFAULT NULL,
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
    `stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `event_type` ENUM('BOARD','ALIGHT') NOT NULL,
    `recorded_at` DATETIME NOT NULL,
    `device_id` VARCHAR(200) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sel_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sel_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- TRIP INCIDENTS & ALERTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `incident_type` VARCHAR(100) NOT NULL,
    `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `recorded_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- GPS LOGS - CRITICAL TELEMETRY TABLE
-- Heavy table: Composite index on (trip_id, log_time) and (vehicle_id, log_time)
-- Spatial index on location (SRID 4326). NO PARTITION by request (add later via ALTER).
-- Recommended: stream to object storage (S3), curate time-window data here.
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `log_time` DATETIME NOT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `location` POINT NOT NULL SRID 4326,
    `speed` DECIMAL(6,2) DEFAULT NULL,
    `ignition_status` TINYINT(1) DEFAULT NULL,
    `deviation_flag` TINYINT(1) DEFAULT 0,
    `raw_payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_gps_trip_time` (`trip_id`, `log_time`),
    KEY `idx_gps_vehicle_time` (`vehicle_id`, `log_time`),
    SPATIAL INDEX `sp_idx_gps_location` (`location`),
    CONSTRAINT `fk_gps_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_gps_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- PRODUCTION NOTE: Partition this table by month or week after deployment
-- Example (run only after data is in place):
-- ALTER TABLE tpt_gps_trip_log PARTITION BY RANGE (YEAR(log_time)*100 + MONTH(log_time))
-- (PARTITION p202401 VALUES LESS THAN (202402),
--  PARTITION p202402 VALUES LESS THAN (202403),
--  PARTITION p_future VALUES LESS THAN MAXVALUE);

CREATE TABLE IF NOT EXISTS `tpt_gps_alerts` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `alert_type` ENUM('Overspeed','Idle','RouteDeviation','GeofenceBreach') NOT NULL,
    `log_time` DATETIME NOT NULL,
    `message` VARCHAR(512) NOT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_gps_alerts_vehicle` (`vehicle_id`, `log_time`),
    CONSTRAINT `fk_gps_alert_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- FUEL & MAINTENANCE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `fuel_type` ENUM('Diesel','Petrol','CNG','Electric') NOT NULL,
    `odometer_reading` BIGINT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `maintenance_type` VARCHAR(120) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `workshop_details` VARCHAR(512) DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vm_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- NOTIFICATIONS & LOGS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_notification_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
    `trip_id` BIGINT UNSIGNED DEFAULT NULL,
    `stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `notification_type` ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') DEFAULT NULL,
    `sent_time` DATETIME DEFAULT NULL,
    `status` ENUM('Sent','Failed') NOT NULL DEFAULT 'Sent',
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_nl_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- AUDIT & MIGRATION TRACKING
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_audit_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity` VARCHAR(128) NOT NULL,
    `entity_id` BIGINT UNSIGNED DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `performed_by` VARCHAR(128) DEFAULT NULL,
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_data_migration_jobs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `job_key` VARCHAR(128) NOT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Pending','Running','Completed','Failed') NOT NULL DEFAULT 'Pending',
    `started_at` DATETIME DEFAULT NULL,
    `finished_at` DATETIME DEFAULT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
-- =======================================================================
-- END OF SCRIPT
-- =======================================================================  


-- ---------------------------------------------------------------------------------------------------------------------------
-- Change Log
-- ---------------------------------------------------------------------------------------------------------------------------
-- v1.0 - Initial version
-- v1.1 - Added ML / Feature Store tables
-- v1.2 - Added Student Event Log and Trip Incidents tables
-- v1.3 - Added Notification Log and Audit Log tables
-- v1.4 - Added Fuel & Maintenance tables
-- ---------------------------------------------------------------------------------------------------------------------------
-- Change Filed Type - Table (tpt_trip) - Change column 'trip_type' ENUM('Morning','Afternoon','Evening','Custom') DEFAULT 'Morning') to FK to tpt_shift
-- ALTER TABLE `tpt_trip` MODIFY COLUMN `trip_type` BIGINT UNSIGNED DEFAULT NULL;
-- Add foreign key constraint
-- ALTER TABLE `tpt_trip` ADD CONSTRAINT `fk_trip_tripType` FOREIGN KEY (`trip_type`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL;
-- ALTER TABLE `tpt_trip` MODIFY COLUMN `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled';
-- ALTER TABLE `tpt_trip` ADD COLUMN `remarks` VARCHAR(512) DEFAULT NULL,
-- ----------------------------------------------------------------------------------------------------------------------------- 