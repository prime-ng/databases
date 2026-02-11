-- =======================================================================
-- TRANSPORT MODULE ENHANCED (v1.2) for MySQL 8.x
-- Purpose: Blue-Green enhancement (In-DB RENAME strategy)
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,
    `registration_no` VARCHAR(30) NOT NULL,
    `model` VARCHAR(50),
    `manufacturer` VARCHAR(50),
    `vehicle_type` VARCHAR(20) NOT NULL,        -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type` VARCHAR(20) NOT NULL,           -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,
    `ownership_type` VARCHAR(20) NOT NULL,      -- fk to sys_dropdown_table ('Owned','Leased','Rented')
    `fitness_valid_upto` DATE,
    `insurance_valid_upto` DATE,
    `pollution_valid_upto` DATE,
    `gps_device_id` VARCHAR(50),                -- FK to GPS device table if exists
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED DEFAULT NULL,
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,
    `id_no` VARCHAR(100) DEFAULT NULL,
    `role` VARCHAR(20) NOT NULL,
    `license_no` VARCHAR(50) DEFAULT NULL,
    `license_valid_upto` DATE DEFAULT NULL,
    `assigned_vehicle_id` INT UNSIGNED DEFAULT NULL,
    `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,
    `address` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_shift` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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


-- =======================================================================
-- ROUTES & STOPS with SRID=4326
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_route` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` INT UNSIGNED NOT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `location` POINT NOT NULL SRID 4326,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` INT UNSIGNED NOT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `pickup_point_id` INT UNSIGNED NOT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED NOT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scheduled_date` DATE NOT NULL,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,
    `pickup_route_id` INT UNSIGNED DEFAULT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED NOT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `trip_type` ENUM('Morning','Afternoon','Evening','Custom') DEFAULT 'Morning',
    `start_time` DATETIME DEFAULT NULL,
    `end_time` DATETIME DEFAULT NULL,
    `status` ENUM('Scheduled','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_trip_route_sched` (`route_id`, `trip_date`),
    KEY `idx_trip_vehicle` (`vehicle_id`),
    CONSTRAINT `fk_trip_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- LIVE TRIP STATUS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_live_trip` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `current_stop_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` INT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_out_time` DATETIME DEFAULT NULL,
    `geo_lat` DECIMAL(10,7) DEFAULT NULL,
    `geo_lng` DECIMAL(10,7) DEFAULT NULL,
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_da_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_allocation_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `pickup_stop_id` INT UNSIGNED NOT NULL,
    `drop_stop_id` INT UNSIGNED NOT NULL,
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


-- =======================================================================
-- TRANSPORT FEE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_fee_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `session_id` INT UNSIGNED NOT NULL,
    `month` TINYINT NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_fee_collection` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_allocation_id` INT UNSIGNED NOT NULL,
    `fee_master_id` INT UNSIGNED NOT NULL,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_date` DATE NOT NULL,
    `payment_mode` ENUM('Cash','UPI','Card','Bank','Cheque') NOT NULL,
    `status` ENUM('Paid','Partial','Pending') NOT NULL DEFAULT 'Paid',
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` INT UNSIGNED NOT NULL,
    `feature_name` VARCHAR(200) NOT NULL,
    `feature_type` VARCHAR(50) DEFAULT NULL,
    `transformation` JSON DEFAULT NULL,
    CONSTRAINT `fk_mmf_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_feature_store` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `feature_date` DATE NOT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `feature_vector` JSON NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_feature_date_route` (`feature_date`, `route_id`),
    CONSTRAINT `fk_fs_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fs_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_model_recommendations` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` INT UNSIGNED NOT NULL,
    `model_version` VARCHAR(50) DEFAULT NULL,
    `run_id` VARCHAR(100) DEFAULT NULL,
    `generated_for_date` DATE DEFAULT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `recommendation_id` INT UNSIGNED NOT NULL,
    `applied_at` DATETIME DEFAULT NULL,
    `applied_by` INT UNSIGNED DEFAULT NULL,
    `outcome` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_rh_recommendation` FOREIGN KEY (`recommendation_id`) REFERENCES `tpt_model_recommendations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT BOARD/ALIGHT EVENTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_event_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED DEFAULT NULL,
    `student_session_id` INT UNSIGNED DEFAULT NULL,
    `stop_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `fuel_type` ENUM('Diesel','Petrol','CNG','Electric') NOT NULL,
    `odometer_reading` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` INT UNSIGNED DEFAULT NULL,
    `trip_id` INT UNSIGNED DEFAULT NULL,
    `stop_id` INT UNSIGNED DEFAULT NULL,
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity` VARCHAR(128) NOT NULL,
    `entity_id` INT UNSIGNED DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `performed_by` VARCHAR(128) DEFAULT NULL,
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_data_migration_jobs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
-- BLUE-GREEN MIGRATION CHECKLIST
-- =======================================================================
--
-- STEP 1: BACKFILL DATA (run in order)
--   INSERT INTO tpt_vehicle SELECT * FROM tpt_vehicle_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_personnel SELECT * FROM tpt_personnel_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_shift SELECT * FROM tpt_shift_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_route SELECT * FROM tpt_route_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_pickup_points SELECT id, code, name, latitude, longitude, ST_SRID(location,4326), total_distance, estimated_time, stop_type, shift_id, is_active, created_at, updated_at, deleted_at FROM tpt_pickup_points_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_pickup_points_route_jnt SELECT * FROM tpt_pickup_points_route_jnt_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_driver_route_vehicle_jnt SELECT * FROM tpt_driver_route_vehicle_jnt_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_route_scheduler_jnt SELECT * FROM tpt_route_scheduler_jnt_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_trip SELECT * FROM tpt_trip_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_live_trip SELECT * FROM tpt_live_trip_old WHERE deleted_at IS NULL;
--   INSERT INTO tpt_gps_trip_log SELECT id, trip_id, vehicle_id, log_time, latitude, longitude, ST_SRID(location,4326), speed, ignition_status, deviation_flag, raw_payload, created_at, deleted_at FROM tpt_gps_trip_log_old WHERE deleted_at IS NULL;
--   ... continue for all remaining tables ...
--
-- STEP 2: VERIFY DATA INTEGRITY
--   SELECT COUNT(*) as v1_count FROM tpt_vehicle_old WHERE deleted_at IS NULL;
--   SELECT COUNT(*) as v2_count FROM tpt_vehicle;
--   -- Should match (repeat for all core tables)
--
-- STEP 3: ATOMIC RENAME (BLUE-GREEN SWAP)
--   START TRANSACTION;
--   RENAME TABLE tpt_vehicle_old TO tpt_vehicle_backup,
--                tpt_vehicle TO tpt_vehicle_old,
--                tpt_vehicle_backup TO tpt_vehicle_archive;
--   -- repeat for other tables
--   COMMIT;
--
-- STEP 4: TEST & VALIDATE
--   SELECT * FROM tpt_vehicle LIMIT 1;
--   SELECT * FROM tpt_route WHERE id = <sample_route_id>;
--   -- Run application queries and compare results
--
-- STEP 5: ROLLBACK (IF NEEDED)
--   If issues detected, reverse the rename by restoring backups
--
-- STEP 6: CLEANUP
--   Once confident (after 24-48 hours of monitoring):
--   DROP TABLE tpt_vehicle_archive;  -- Keep backups in archive storage if needed
--
-- =======================================================================
-- WHAT'S CHANGED IN v1.2:
-- ✓ Soft Deletes: All core tables have `deleted_at` TIMESTAMP NULL DEFAULT NULL
-- ✓ SRID = 4326: POINT and LINESTRING columns use WGS84 (lat/lon) coordinates
-- ✓ Spatial Indexes: SPATIAL INDEX on route_geometry, location, recommended_path
-- ✓ Telemetry Indexes: Composite (trip_id, log_time), (vehicle_id, log_time) for telemetry
-- ✓ Feature Store Index: (feature_date, route_id) for fast model-serving queries
-- ✓ Blue-Green Ready: Final table names used, migration checklist provided
-- ✓ No org_id: Tenant isolation via separate database per tenant
-- ✓ No Partition Clauses: See comments for how to add partitioning post-deploy
-- ✓ ML Tables Included: ml_models, feature_store, recommendations, history
-- =======================================================================

-- End of tpt_transport_v1.2.sql
-- =======================================================================
-- TRANSPORT MODULE ENHANCED (v1.2) for MySQL 8.x
-- Purpose: Blue-Green enhancement (In-DB RENAME strategy)
-- Strategy: Create _v2 objects, backfill from v1, verify, then atomic RENAME TABLE swap.
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
--                tpt_vehicle_v2 TO tpt_vehicle,
--                tpt_vehicle_old TO tpt_vehicle_v2_old;
--   RENAME TABLE tpt_personnel TO tpt_personnel_old,
--                tpt_personnel_v2 TO tpt_personnel,
--                tpt_personnel_old TO tpt_personnel_v2_old;
--   -- ... repeat for all tables ...
--   COMMIT;
--
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VEHICLE, DRIVER, HELPER, SHIFT (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,
    `registration_no` VARCHAR(30) NOT NULL,
    `model` VARCHAR(50),
    `manufacturer` VARCHAR(50),
    `vehicle_type` VARCHAR(20) NOT NULL,
    `fuel_type` VARCHAR(20) NOT NULL,
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,
    `ownership_type` VARCHAR(20) NOT NULL,
    `fitness_valid_upto` DATE,
    `insurance_valid_upto` DATE,
    `pollution_valid_upto` DATE,
    `gps_device_id` VARCHAR(50),
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_personnel_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED DEFAULT NULL,
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,
    `id_no` VARCHAR(100) DEFAULT NULL,
    `role` VARCHAR(20) NOT NULL,
    `license_no` VARCHAR(50) DEFAULT NULL,
    `license_valid_upto` DATE DEFAULT NULL,
    `assigned_vehicle_id` INT UNSIGNED DEFAULT NULL,
    `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,
    `address` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_personnel_vehicle_v2` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_shift_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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


-- =======================================================================
-- ROUTES & STOPS with SRID=4326 (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_route_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` INT UNSIGNED NOT NULL,
    `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_route_code` (`code`),
    UNIQUE KEY `uq_route_name` (`name`),
    SPATIAL INDEX `sp_idx_route_geometry_v2` (`route_geometry`),
    CONSTRAINT `fk_route_shiftId_v2` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `location` POINT NOT NULL SRID 4326,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` INT UNSIGNED NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickup_code` (`code`),
    UNIQUE KEY `uq_pickup_name` (`name`),
    SPATIAL INDEX `sp_idx_pickup_location_v2` (`location`),
    CONSTRAINT `fk_pickupPoint_shiftId_v2` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `pickup_point_id` INT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickupPointRoute_shift_pickupPoint` (`shift_id`,`pickup_point_id`,`route_id`),
    KEY `idx_pprj_route_ordinal_v2` (`route_id`, `ordinal`),
    CONSTRAINT `fk_pickupPointRoute_shiftId_v2` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pickupPointRoute_routeId_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pickupPointRoute_pickupPointId_v2` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- ROUTE SCHEDULE & DRIVER ASSIGNMENT (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED NOT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_routeVehicle_shiftId_v2` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_routeId_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_vehicleId_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_driverId_v2` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_routeVehicle_helperId_v2` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scheduled_date` DATE NOT NULL,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sched_shift_v2` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_route_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_driver_v2` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel_v2`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_helper_v2` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- TRIPS (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,
    `pickup_route_id` INT UNSIGNED DEFAULT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED NOT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `trip_type` ENUM('Morning','Afternoon','Evening','Custom') DEFAULT 'Morning',
    `start_time` DATETIME DEFAULT NULL,
    `end_time` DATETIME DEFAULT NULL,
    `status` ENUM('Scheduled','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_trip_route_sched_v2` (`route_id`, `trip_date`),
    KEY `idx_trip_vehicle_v2` (`vehicle_id`),
    CONSTRAINT `fk_trip_route_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver_v2` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel_v2`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- LIVE TRIP STATUS (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_live_trip_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `current_stop_id` INT UNSIGNED DEFAULT NULL,
    `eta` DATETIME DEFAULT NULL,
    `reached_flag` TINYINT(1) NOT NULL DEFAULT 0,
    `emergency_flag` TINYINT(1) DEFAULT 0,
    `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_live_trip_v2` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_live_current_stop_v2` FOREIGN KEY (`current_stop_id`) REFERENCES `tpt_pickup_points_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- DRIVER ATTENDANCE (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` INT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_out_time` DATETIME DEFAULT NULL,
    `geo_lat` DECIMAL(10,7) DEFAULT NULL,
    `geo_lng` DECIMAL(10,7) DEFAULT NULL,
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_da_driver_v2` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT ALLOCATION (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_allocation_jnt_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `pickup_stop_id` INT UNSIGNED NOT NULL,
    `drop_stop_id` INT UNSIGNED NOT NULL,
    `fare` DECIMAL(10,2) NOT NULL,
    `effective_from` DATE NOT NULL,
    `active_status` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sa_route_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup_v2` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points_v2`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop_v2` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points_v2`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- TRANSPORT FEE (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_fee_master_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `session_id` INT UNSIGNED NOT NULL,
    `month` TINYINT NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_fee_collection_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_allocation_id` INT UNSIGNED NOT NULL,
    `fee_master_id` INT UNSIGNED NOT NULL,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_date` DATE NOT NULL,
    `payment_mode` ENUM('Cash','UPI','Card','Bank','Cheque') NOT NULL,
    `status` ENUM('Paid','Partial','Pending') NOT NULL DEFAULT 'Paid',
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_fc_allocation_v2` FOREIGN KEY (`student_allocation_id`) REFERENCES `tpt_student_allocation_jnt_v2`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fc_master_v2` FOREIGN KEY (`fee_master_id`) REFERENCES `tpt_fee_master_v2`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- ML / FEATURE STORE (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `ml_models_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(200) NOT NULL,
    `version` VARCHAR(50) NOT NULL,
    `model_type` VARCHAR(50) DEFAULT NULL,
    `artifact_uri` VARCHAR(1024) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `metrics` JSON DEFAULT NULL,
    `status` ENUM('TRAINED','DEPLOYED','DEPRECATED') DEFAULT 'TRAINED',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ml_model_name_version` (`name`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ml_model_features_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` INT UNSIGNED NOT NULL,
    `feature_name` VARCHAR(200) NOT NULL,
    `feature_type` VARCHAR(50) DEFAULT NULL,
    `transformation` JSON DEFAULT NULL,
    CONSTRAINT `fk_mmf_model_v2` FOREIGN KEY (`model_id`) REFERENCES `ml_models_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_feature_store_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `feature_date` DATE NOT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `feature_vector` JSON NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_feature_date_route_v2` (`feature_date`, `route_id`),
    CONSTRAINT `fk_fs_route_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fs_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_model_recommendations_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` INT UNSIGNED NOT NULL,
    `model_version` VARCHAR(50) DEFAULT NULL,
    `run_id` VARCHAR(100) DEFAULT NULL,
    `generated_for_date` DATE DEFAULT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
    `recommended_path` LINESTRING SRID 4326 DEFAULT NULL,
    `predicted_time_minutes` INT DEFAULT NULL,
    `predicted_distance_km` DECIMAL(7,2) DEFAULT NULL,
    `confidence` DECIMAL(5,4) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    SPATIAL INDEX `sp_idx_recommended_path_v2` (`recommended_path`),
    CONSTRAINT `fk_mr_model_v2` FOREIGN KEY (`model_id`) REFERENCES `ml_models_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mr_route_v2` FOREIGN KEY (`route_id`) REFERENCES `tpt_route_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_recommendation_history_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `recommendation_id` INT UNSIGNED NOT NULL,
    `applied_at` DATETIME DEFAULT NULL,
    `applied_by` INT UNSIGNED DEFAULT NULL,
    `outcome` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_rh_recommendation_v2` FOREIGN KEY (`recommendation_id`) REFERENCES `tpt_model_recommendations_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT BOARD/ALIGHT EVENTS (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_event_log_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED DEFAULT NULL,
    `student_session_id` INT UNSIGNED DEFAULT NULL,
    `stop_id` INT UNSIGNED DEFAULT NULL,
    `event_type` ENUM('BOARD','ALIGHT') NOT NULL,
    `recorded_at` DATETIME NOT NULL,
    `device_id` VARCHAR(200) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_sel_trip_v2` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sel_stop_v2` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- TRIP INCIDENTS & ALERTS (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip_incidents_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `incident_type` VARCHAR(100) NOT NULL,
    `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `recorded_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_ti_trip_v2` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- GPS LOGS (_v2) - CRITICAL TELEMETRY TABLE
-- Heavy table: Composite index on (trip_id, log_time) and (vehicle_id, log_time)
-- Spatial index on location (SRID 4326). NO PARTITION by request (add later via ALTER).
-- Recommended: stream to object storage (S3), curate time-window data here.
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
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
    KEY `idx_gps_trip_time_v2` (`trip_id`, `log_time`),
    KEY `idx_gps_vehicle_time_v2` (`vehicle_id`, `log_time`),
    SPATIAL INDEX `sp_idx_gps_location_v2` (`location`),
    CONSTRAINT `fk_gps_trip_v2` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip_v2`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_gps_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- PRODUCTION NOTE: Partition this table by month or week after deployment
-- Example (run only after data is in v2):
-- ALTER TABLE tpt_gps_trip_log_v2 PARTITION BY RANGE (YEAR(log_time)*100 + MONTH(log_time))
-- (PARTITION p202401 VALUES LESS THAN (202402),
--  PARTITION p202402 VALUES LESS THAN (202403),
--  PARTITION p_future VALUES LESS THAN MAXVALUE);

CREATE TABLE IF NOT EXISTS `tpt_gps_alerts_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `alert_type` ENUM('Overspeed','Idle','RouteDeviation','GeofenceBreach') NOT NULL,
    `log_time` DATETIME NOT NULL,
    `message` VARCHAR(512) NOT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_gps_alerts_vehicle_v2` (`vehicle_id`, `log_time`),
    CONSTRAINT `fk_gps_alert_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- FUEL & MAINTENANCE (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel_log_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `date` DATE NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `fuel_type` ENUM('Diesel','Petrol','CNG','Electric') NOT NULL,
    `odometer_reading` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vfl_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `maintenance_type` VARCHAR(120) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `workshop_details` VARCHAR(512) DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vm_vehicle_v2` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle_v2`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- NOTIFICATIONS & LOGS (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_notification_log_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` INT UNSIGNED DEFAULT NULL,
    `trip_id` INT UNSIGNED DEFAULT NULL,
    `stop_id` INT UNSIGNED DEFAULT NULL,
    `notification_type` ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled') DEFAULT NULL,
    `sent_time` DATETIME DEFAULT NULL,
    `status` ENUM('Sent','Failed') NOT NULL DEFAULT 'Sent',
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_nl_trip_v2` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip_v2`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_stop_v2` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points_v2`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- AUDIT & MIGRATION TRACKING (_v2)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_audit_log_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `entity` VARCHAR(128) NOT NULL,
    `entity_id` INT UNSIGNED DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `performed_by` VARCHAR(128) DEFAULT NULL,
    `payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_data_migration_jobs_v2` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `job_key` VARCHAR(128) NOT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Pending','Running','Completed','Failed') NOT NULL DEFAULT 'Pending',
    `started_at` DATETIME DEFAULT NULL,
    `finished_at` DATETIME DEFAULT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =======================================================================
-- BLUE-GREEN MIGRATION CHECKLIST
-- =======================================================================
--
-- STEP 1: BACKFILL DATA (run in order)
--   INSERT INTO tpt_vehicle_v2 SELECT * FROM tpt_vehicle WHERE deleted_at IS NULL;
--   INSERT INTO tpt_personnel_v2 SELECT * FROM tpt_personnel WHERE deleted_at IS NULL;
--   INSERT INTO tpt_shift_v2 SELECT * FROM tpt_shift WHERE deleted_at IS NULL;
--   INSERT INTO tpt_route_v2 SELECT * FROM tpt_route WHERE deleted_at IS NULL;
--   INSERT INTO tpt_pickup_points_v2 SELECT id, code, name, latitude, longitude, ST_SRID(location,4326), total_distance, estimated_time, stop_type, shift_id, is_active, created_at, updated_at, deleted_at FROM tpt_pickup_points WHERE deleted_at IS NULL;
--   INSERT INTO tpt_pickup_points_route_jnt_v2 SELECT * FROM tpt_pickup_points_route_jnt WHERE deleted_at IS NULL;
--   INSERT INTO tpt_driver_route_vehicle_jnt_v2 SELECT * FROM tpt_driver_route_vehicle_jnt WHERE deleted_at IS NULL;
--   INSERT INTO tpt_route_scheduler_jnt_v2 SELECT * FROM tpt_route_scheduler_jnt WHERE deleted_at IS NULL;
--   INSERT INTO tpt_trip_v2 SELECT * FROM tpt_trip WHERE deleted_at IS NULL;
--   INSERT INTO tpt_live_trip_v2 SELECT * FROM tpt_live_trip WHERE deleted_at IS NULL;
--   INSERT INTO tpt_gps_trip_log_v2 SELECT id, trip_id, vehicle_id, log_time, latitude, longitude, ST_SRID(location,4326), speed, ignition_status, deviation_flag, raw_payload, created_at, deleted_at FROM tpt_gps_trip_log WHERE deleted_at IS NULL;
--   ... continue for all remaining tables ...
--
-- STEP 2: VERIFY DATA INTEGRITY
--   SELECT COUNT(*) as v1_count FROM tpt_vehicle WHERE deleted_at IS NULL;
--   SELECT COUNT(*) as v2_count FROM tpt_vehicle_v2;
--   -- Should match (repeat for all core tables)
--
-- STEP 3: ATOMIC RENAME (BLUE-GREEN SWAP)
--   START TRANSACTION;
--   RENAME TABLE tpt_vehicle TO tpt_vehicle_old,
--                tpt_vehicle_v2 TO tpt_vehicle,
--                tpt_vehicle_old TO tpt_vehicle_v2_old;
--   RENAME TABLE tpt_personnel TO tpt_personnel_old,
--                tpt_personnel_v2 TO tpt_personnel,
--                tpt_personnel_old TO tpt_personnel_v2_old;
--   -- ... repeat for all tables ...
--   COMMIT;
--
-- STEP 4: TEST & VALIDATE
--   SELECT * FROM tpt_vehicle LIMIT 1;
--   SELECT * FROM tpt_route WHERE id = <sample_route_id>;
--   -- Run application queries and compare results
--
-- STEP 5: ROLLBACK (IF NEEDED)
--   If issues detected, reverse the rename:
--   START TRANSACTION;
--   RENAME TABLE tpt_vehicle TO tpt_vehicle_v2,
--                tpt_vehicle_old TO tpt_vehicle;
--   COMMIT;
--
-- STEP 6: CLEANUP
--   Once confident (after 24-48 hours of monitoring):
--   DROP TABLE tpt_vehicle_v2_old;  -- Keep backups in archive storage if needed
--
-- =======================================================================
-- WHAT'S CHANGED IN v1.2:
-- ✓ Soft Deletes: All core tables have `deleted_at` TIMESTAMP NULL DEFAULT NULL
-- ✓ SRID = 4326: POINT and LINESTRING columns use WGS84 (lat/lon) coordinates
-- ✓ Spatial Indexes: SPATIAL INDEX on route_geometry, location, recommended_path
-- ✓ Telemetry Indexes: Composite (trip_id, log_time), (vehicle_id, log_time), (vehicle_id, log_time) on alerts
-- ✓ Feature Store Index: (feature_date, route_id) for fast model-serving queries
-- ✓ Blue-Green Ready: All tables have _v2 suffix for safe in-DB swapping
-- ✓ No org_id: Tenant isolation via separate database per tenant
-- ✓ No Partition Clauses: See comments for how to add partitioning post-deploy
-- ✓ ML Tables Included: ml_models, feature_store, recommendations, history
-- =======================================================================

-- End of tpt_transport_v1.2.sql
