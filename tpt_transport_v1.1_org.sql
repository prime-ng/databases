-- =======================================================================
-- TRANSPORT MODULE - ENHANCED (AI-READY) DDL
-- File: transport_module_enhanced.sql
-- Purpose: corrected/normalized transport schema + AI/ML tables + ingestion readiness
-- Notes: Canonical prefix `tpt_` used across all transport tables
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VEHICLE, DRIVER, HELPER, SHIFT
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,
    `registration_no` VARCHAR(30) NOT NULL,
    `model` VARCHAR(50),
    `manufacturer` VARCHAR(50),
    `vehicle_type` VARCHAR(20) NOT NULL,           -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type` VARCHAR(20) NOT NULL,           -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,
    `ownership_type` VARCHAR(20) NOT NULL,          -- fk to sys_dropdown_table ('Owned','Leased','Rented')
    `fitness_valid_upto` DATE,
    `insurance_valid_upto` DATE,
    `pollution_valid_upto` DATE,
    `gps_device_id` VARCHAR(50),               -- optional GPS device identifier
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Old table name 'tpt_driver_helpr'
CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,      -- FK to sys_users (optional)
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,      -- fk ('Aadhaar','PAN','Passport','Other')
    `id_no` VARCHAR(100) DEFAULT NULL,
--    `role` ENUM('Driver','Helper','Both') NOT NULL DEFAULT 'Driver',
    `role` VARCHAR(20) NOT NULL,               -- fk ('Driver','Helper','Other')
    `license_no` VARCHAR(50) DEFAULT NULL,
    `license_valid_upto` DATE DEFAULT NULL,
    `assigned_vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
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


-- =======================================================================
-- ROUTES & STOPS (use spatial types where possible)
-- Note: If using MySQL < 5.7 spatial features are limited; consider PostGIS for advanced geo
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_route` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_geometry` GEOMETRY DEFAULT NULL, -- LINESTRING of route path (optional)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_route_code` (`code`),
    UNIQUE KEY `uq_route_name` (`name`),
    CONSTRAINT `fk_route_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,6) DEFAULT NULL,      -- Latitude of the pickup/drop point
    `longitude` DECIMAL(10,6) DEFAULT NULL,     -- Longitude of the pickup/drop point
    `location` POINT DEFAULT NULL,                -- Spatial point (latitude, longitude)
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,            -- Time in Minutes
    `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickup_code` (`code`),
    UNIQUE KEY `uq_pickup_name` (`name`),
    CONSTRAINT `fk_pickupPoint_shiftId` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- spatial index (MySQL spatial indexes require non-nullable columns for some versions)
-- If using MySQL spatial, you may need to set NOT NULL on `location` and use a SPATIAL INDEX

CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `pickup_point_id` BIGINT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,     -- Order of the stop in the route
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_pickupPointRoute_shift_pickupPoint` (`shift_id`,`pickup_point_id`,`route_id`),
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;



-- =======================================================================
-- TRIPS
-- Use canonical trip table `tpt_trip` and link to scheduler
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,
    `pickup_route_id` BIGINT UNSIGNED DEFAULT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `helper_id` BIGINT UNSIGNED DEFAULT NULL,
    `trip_type` ENUM('Morning','Afternoon','Evening','Custom') DEFAULT 'Morning',
    `start_time` DATETIME DEFAULT NULL,
    `end_time` DATETIME DEFAULT NULL,
    `status` ENUM('Scheduled','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Scheduled',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_trip_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


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
    CONSTRAINT `fk_live_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_live_current_stop` FOREIGN KEY (`current_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- DRIVER ATTENDANCE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_out_time` DATETIME DEFAULT NULL,
    `geo_lat` DECIMAL(10,6) DEFAULT NULL,
    `geo_lng` DECIMAL(10,6) DEFAULT NULL,
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_da_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_allocation_jnt` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` BIGINT UNSIGNED NOT NULL,
    `route_id` BIGINT UNSIGNED NOT NULL,
    `pickup_stop_id` BIGINT UNSIGNED NOT NULL,
    `drop_stop_id` BIGINT UNSIGNED NOT NULL,
    `fare` DECIMAL(10,2) NOT NULL,
    `effective_from` DATE NOT NULL,
    `active_status` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_sa_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- TRANSPORT FEE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_fee_master` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `session_id` BIGINT UNSIGNED NOT NULL,
    `month` TINYINT NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_fee_collection` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_allocation_id` BIGINT UNSIGNED NOT NULL,
    `fee_master_id` BIGINT UNSIGNED NOT NULL,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_date` DATE NOT NULL,
    `payment_mode` ENUM('Cash','UPI','Card','Bank','Cheque') NOT NULL,
    `status` ENUM('Paid','Partial','Pending') NOT NULL DEFAULT 'Paid',
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_fc_allocation` FOREIGN KEY (`student_allocation_id`) REFERENCES `tpt_student_allocation_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fc_master` FOREIGN KEY (`fee_master_id`) REFERENCES `tpt_fee_master`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- ADVANCED (AI / ML) TABLES
-- =======================================================================

-- Model registry / metadata
CREATE TABLE IF NOT EXISTS `ml_models` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(200) NOT NULL,
    `version` VARCHAR(50) NOT NULL,
    `model_type` VARCHAR(50) DEFAULT NULL, -- e.g., 'route_optimizer','eta_predictor'
    `artifact_uri` VARCHAR(1024) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `metrics` JSON DEFAULT NULL,
    `status` ENUM('TRAINED','DEPLOYED','DEPRECATED') DEFAULT 'TRAINED',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ml_model_name_version` (`name`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ml_model_features` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` BIGINT UNSIGNED NOT NULL,
    `feature_name` VARCHAR(200) NOT NULL,
    `feature_type` VARCHAR(50) DEFAULT NULL,
    `transformation` JSON DEFAULT NULL,
    CONSTRAINT `fk_mmf_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- Feature store (precomputed features per route/vehicle/day)
CREATE TABLE IF NOT EXISTS `tpt_feature_store` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `feature_date` DATE NOT NULL,
    `route_id` BIGINT UNSIGNED DEFAULT NULL,
    `vehicle_id` BIGINT UNSIGNED DEFAULT NULL,
    `feature_vector` JSON NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_fs_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_fs_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- Model recommendations produced by optimizer
CREATE TABLE IF NOT EXISTS `tpt_model_recommendations` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `model_id` BIGINT UNSIGNED NOT NULL,
    `model_version` VARCHAR(50) DEFAULT NULL,
    `run_id` VARCHAR(100) DEFAULT NULL,
    `generated_for_date` DATE DEFAULT NULL,
    `route_id` BIGINT UNSIGNED DEFAULT NULL,
    `recommended_path` GEOMETRY DEFAULT NULL, -- LINESTRING or JSON representation
    `predicted_time_minutes` INT DEFAULT NULL,
    `predicted_distance_km` DECIMAL(7,2) DEFAULT NULL,
    `confidence` DECIMAL(5,4) DEFAULT NULL,
    `parameters` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mr_model` FOREIGN KEY (`model_id`) REFERENCES `ml_models`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mr_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- Recommendation history to evaluate model performance
CREATE TABLE IF NOT EXISTS `tpt_recommendation_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `recommendation_id` BIGINT UNSIGNED NOT NULL,
    `applied_at` DATETIME DEFAULT NULL,
    `applied_by` BIGINT UNSIGNED DEFAULT NULL,
    `outcome` JSON DEFAULT NULL, -- actual_time, actual_distance, deviation, notes
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_rh_recommendation` FOREIGN KEY (`recommendation_id`) REFERENCES `tpt_model_recommendations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- Student board/alight events for signal quality
CREATE TABLE IF NOT EXISTS `tpt_student_event_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED DEFAULT NULL,
    `student_session_id` BIGINT UNSIGNED DEFAULT NULL,
    `stop_id` BIGINT UNSIGNED DEFAULT NULL,
    `event_type` ENUM('BOARD','ALIGHT') NOT NULL,
    `recorded_at` DATETIME NOT NULL,
    `device_id` VARCHAR(200) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_sel_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sel_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- Trip incidents & alerts
CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `incident_type` VARCHAR(100) NOT NULL, -- e.g., 'Breakdown','Accident','Traffic','Delay'
    `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    `latitude` DECIMAL(10,6) DEFAULT NULL,
    `longitude` DECIMAL(10,6) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `recorded_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- GPS LOGS (raw) — heavy table: partition by `log_time` in production
-- Use streaming ingestion (Kafka) into raw store; store curated/cleaned rows here
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` BIGINT UNSIGNED NOT NULL,
    `log_time` DATETIME NOT NULL,
    `latitude` DECIMAL(10,6) NOT NULL,
    `longitude` DECIMAL(10,6) NOT NULL,
    `location` POINT NOT NULL,
    `speed` DECIMAL(6,2) DEFAULT NULL,
    `ignition_status` TINYINT(1) DEFAULT NULL,
    `deviation_flag` TINYINT(1) DEFAULT 0,
    `raw_payload` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_gps_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

-- Recommended production change: RANGE PARTITION by TO_DAYS(`log_time`) or by MONTH(log_time)
-- e.g., PARTITION BY RANGE (YEAR(log_time)*100 + MONTH(log_time)) ...

CREATE TABLE IF NOT EXISTS `tpt_gps_alerts` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `alert_type` ENUM('Overspeed','Idle','RouteDeviation','GeofenceBreach') NOT NULL,
    `log_time` DATETIME NOT NULL,
    `message` VARCHAR(512) NOT NULL,
    `meta` JSON DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_gps_alert_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


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
    CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` BIGINT UNSIGNED NOT NULL,
    `maintenance_type` VARCHAR(120) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `workshop_details` VARCHAR(512) DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_vm_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;


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
    CONSTRAINT `fk_nl_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_nl_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4_COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =======================================================================
-- INDEXING & MAINTENANCE NOTES (apply in production as ALTER statements)
-- - Add indexes: (tpt_gps_trip_log: trip_id, log_time), (tpt_pickup_points_route_jnt: route_id, ordinal)
-- - Partition `tpt_gps_trip_log` by time (monthly) for performance & retention.
-- - Use spatial indexes for `location` and `route_geometry` when supported.
-- - Keep raw telemetry in object store (S3) for ML training; use this DB for curated events.
--
-- Suggested Post-deploy tasks:
-- 1. Seed reference tables (vehicle types, fuel types, shifts)
-- 2. Configure Kafka topics for GPS/events ingestion
-- 3. Create stream processor jobs for ETA, deviation detection, and enrichment
-- 4. Build nightly batch jobs to populate `tpt_feature_store`
-- 5. Implement retention and archiving for older partitions
-- =======================================================================

-- End of transport_module_enhanced.sql
