-- =======================================================================
-- TRANSPORT MODULE ENHANCED (v1.5) for MySQL 8.x
-- Strategy: Took backup from v1.4, verify, then Enhance.
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VEHICLE, DRIVER, HELPER, SHIFT
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,
    `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
    `model` VARCHAR(50),                            -- Vehicle model
    `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
    `vehicle_type` VARCHAR(20) NOT NULL,            -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type` VARCHAR(20) NOT NULL,               -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
    `max_capacity` INT UNSIGNED NOT NULL DEFAULT 40, -- Maximum allowed capacity including standing
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
-- Conditions:
-- 1. vehicle_no and registration_no must be unique.
-- 2. fitness_valid_upto, insurance_valid_upto, pollution_valid_upto must be future dates when adding new vehicle.
-- 3. capacity must be positive integer.
-- 4. gps_device_id is optional, can be null.
-- 5. is_active indicates if vehicle is currently in service.
-- 6. deleted_at is for soft delete.
-- 7. new Variable in Table 'sch_settings' named 'Allow_extra_student_in_vehicale_beyond_capacity' to indicate if school allow extra students beyond vehicle capacity.
-- 8. App logic to enforce capacity checks during student allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED DEFAULT NULL,
    `driver_code` VARCHAR(30) NOT NULL,
    `qr_token` VARCHAR(100) NOT NULL,
    `id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
    `name` VARCHAR(100) NOT NULL,
    `phone` VARCHAR(30) DEFAULT NULL,
    `id_type` VARCHAR(20) DEFAULT NULL,         -- FK to sys_dropdown_table e.g., 'Aadhaar','Passport','DriverLicense'
    `id_no` VARCHAR(100) DEFAULT NULL,          -- Govt issued ID number
    `role` VARCHAR(20) NOT NULL,                -- fk to sys_role ('Driver','Helper','Conductor','Substitute Driver','Substitute Helper')
    `license_no` VARCHAR(50) DEFAULT NULL,      -- Driver's license number
    `license_valid_upto` DATE DEFAULT NULL,                 -- License expiry date
    `assigned_vehicle_id` INT UNSIGNED DEFAULT NULL,     -- fk to tpt_vehicle
    `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,    -- Total driving experience in months
    `address` VARCHAR(512) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. user_id is optional, can be null for non-system users (e.g., external drivers/helpers).
-- 2. role must be one of the predefined roles in sys_role table.
-- 3. Some users may have multiple roles (e.g., Driver + Helper).
-- 4. Some user whose primary Role belongs to some other department (e.g., Staff) may also be regitered as Driver/Helper to be used in emergency(Driver/helper absent) situations.
-- 5. In case of absence of dedicated Driver/Helper personnel, other Staff regitered as temporarily Driver/Helper can be assigned.
-- 6. id_type and id_no are optional, can be null.
-- 7. license_no and license_valid_upto are mandatory for role='Driver'.
-- 8. assigned_vehicle_id is optional, can be null if not currently assigned.
-- 9. is_active indicates if personnel is currently employed/active.
-- 10. deleted_at is for soft delete.
-- 11. App logic to ensure that a vehicle can have only one active Driver and one active Helper assigned at any given time.
-- 12. App logic to ensure that a Driver or Helper cannot be assigned to more than one vehicle at the same time.
-- 13. App logic to validate license_valid_upto when assigning Driver to a vehicle.
-- 14. App logic to prevent assigning personnel marked as inactive.
-- 15. App logic to handle temporary assignments of other Staff as Driver/Helper during emergencies.
-- 16. QR token generation and management to be handled at application level.
-- 17. id_card_type indicates the type of identification card used for personnel.
-- 18. combination of driver_code and role must be unique.
-- 19. license_no must be unique among Drivers.
-- 20. phone number should be unique if provided.
-- 21. one user_id can be used in multipale personnel records for different roles.
-- 22. assigned_vehicle_id can be same for multiple personnel records if they are not active at the same time.
-- 23. App logic to manage active assignments and ensure no conflicts.
-- 

CREATE TABLE IF NOT EXISTS `tpt_shift` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
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
-- Conditions:
-- 1. code and name must be unique.
-- 2. effective_from must be less than effective_to.
-- 3. is_active indicates if shift is currently in use.
-- 4. deleted_at is for soft delete.


-- =======================================================================
-- ROUTES & STOPS with SRID=4326
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_route` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,        -- Route code
    `name` VARCHAR(200) NOT NULL,       -- Route name
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `shift_id` INT UNSIGNED NOT NULL,                    -- fk to 'tpt_shift'
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
-- Conditions:
-- 1. code and name must be unique.
-- 2. route_geometry is optional, can be null initially.
-- 3. is_active indicates if route is currently in use.
-- 4. deleted_at is for soft delete.

-- -----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,      -- WGS84 latitude
    `longitude` DECIMAL(10,7) DEFAULT NULL,     -- WGS84 longitude
    `location` POINT NOT NULL SRID 4326,        -- WGS84 spatial point e.g., POINT(longitude latitude)
    `total_distance` DECIMAL(7,2) DEFAULT NULL, -- Distance from route start in KM
    `estimated_time` INT DEFAULT NULL,          -- Estimated time from route start in minutes
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
-- Conditions:
-- 1. code and name must be unique.
-- 2. latitude and longitude are optional, can be null if location point is provided.
-- 3. location is mandatory, cannot be null.
-- 4. is_active indicates if pickup point is currently in use.
-- 5. deleted_at is for soft delete.

-- -----------------------------------------------------------------------
-- Junction table to link pickup points to routes. It will have separate entries for Pickup and Drop points.
-- Table 'sch_settings' has a Variable named 'Allow_only_one_side_transport_charges' to indicate if school allow one side fare.
-- Table 'sch_settings' has a Variable named 'Allow_different_pickup_and_drop_point' to indicate if school allow different pickup & drop fare.
-- If 'Allow_only_one_side_transport_charges' OR 'Allow_different_pickup_and_drop_point' is true, then app logic will enforce appropriate validations.
CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,            -- fk to tpt_shift
    `route_id` INT UNSIGNED NOT NULL,            -- fk to tpt_route
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `pickup_point_id` INT UNSIGNED NOT NULL,     -- fk to tpt_pickup_points
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `total_distance` DECIMAL(7,2) DEFAULT NULL,
    `estimated_time` INT DEFAULT NULL,
    `pickup_fare` DECIMAL(10,2) DEFAULT NULL,  -- Estimated fare to this point
    `drop_fare` DECIMAL(10,2) DEFAULT NULL,    -- Estimated fare from this point
    `both_side_fare` DECIMAL(10,2) DEFAULT NOT NULL, -- Estimated fare for both side to this point
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
-- Conditions:
-- 1. combination of shift_id, pickup_point_id, route_id must be unique.
-- 2. ordinal indicates the sequence of the pickup point in the route.
-- 3. If 'Allow_only_one_side_transport_charges' or 'Allow_different_pickup_and_drop_point' is true,  is true, then only one of pickup_fare or drop_fare should be set.
-- 4. both_side_fare is mandatory, cannot be null.
-- 5. This table will have separate entries for Pickup and Drop points for same pickup_point_id on same route.
-- 6. is_active indicates if the pickup point is currently in use for the route.
-- 7. deleted_at is for soft delete.

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
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
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

-- Conditions:
-- 1. combination of shift_id, route_id, vehicle_id, driver_id must be unique.
-- 2. effective_from must be less than effective_to if effective_to is not null.
-- 3. One Driver / Helper can be assigned to multiple vehicles/routes on same shift for different date ranges,but not overlapping date ranges.
-- 4. A Vehicle can have different Drivers / Helpers on same shift for different date ranges but not overlapping date ranges.
-- 5. A Driver / Helper can be assigned to different Vehicles on same shift for different date ranges but not overlapping date ranges.
-- 6. pickup_drop indicates if the assignment is for Pickup, Drop or Both.
-- 7. is_active indicates if the assignment is currently active.
-- 8. deleted_at is for soft delete.

-- -----------------------------------------------------------------------

-- Prevent overlapping assignments for same vehicle/driver on same shift+route should be enforced at app or via triggers
CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `scheduled_date` DATE NOT NULL,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED NOT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_route_scheduler_schedDate_shift_route` (`scheduled_date`,`shift_id`,`route_id`),
    UNIQUE KEY `uq_route_scheduler_vehicle_schedDate_shift` (`vehicle_id`,`scheduled_date`,`shift_id`),
    UNIQUE KEY `uq_route_scheduler_driver_schedDate_shift` (`driver_id`,`scheduled_date`,`shift_id`),
    UNIQUE KEY `uq_route_scheduler_helper_schedDate_shift` (`helper_id`,`scheduled_date`,`shift_id`),
    CONSTRAINT `fk_sched_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sched_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sched_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. A Route can not be scheduled more than once on same date for same shift.
-- 2. A Vehicle can not be scheduled for more than one route on same date for same shift.
-- 3. A Driver can not be scheduled for more than one route on same date for same shift.
-- 4. A Helper can not be scheduled for more than one route on same date for same shift.
-- 5. pickup_drop indicates if the schedule is for Pickup or Drop.
-- 6. This table will be pre-populated based on entries in 'tpt_driver_route_vehicle_jnt' for the date range.
-- 7. App logic or DB triggers should prevent overlapping assignments for same vehicle/driver on same shift+route.
-- 6. is_active indicates if the schedule is currently active.
-- 7. deleted_at is for soft delete.

-- =======================================================================
-- TRIPS
-- =======================================================================
-- 'tpt_route_scheduler_jnt' will be used to get schedule details for trip creation, whereas 'tpt_trip' will store actual trip details.
CREATE TABLE IF NOT EXISTS `tpt_trip` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,                      -- Date of the trip
    `route_scheduler_id` INT UNSIGNED NOT NULL,  -- FK to 'tpt_route_scheduler_jnt' for getting schedule details
    `vehicle_id` INT UNSIGNED NOT NULL,          -- FK to 'tpt_vehicle'
    `driver_id` INT UNSIGNED NOT NULL,           -- FK to 'tpt_personnel' for driver
    `helper_id` INT UNSIGNED DEFAULT NULL,       -- FK to 'tpt_personnel' for helper
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
-- Conditions:
-- 1. route_scheduler_id links to tpt_route_scheduler_jnt to get schedule details.
-- 2. vehicle_id, driver_id, helper_id are being captured to accomodate any change from scheduled assignment (e.e, substitute driver or vehicle).
-- 3. status indicates current status of the trip (Scheduled, In-Progress, Completed, Cancelled).
-- 4. is_active indicates if the trip is currently active.
-- 5. deleted_at is for soft delete.

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
-- Conditions:
-- 1. trip_id links to tpt_trip to get trip details.
-- 2. current_stop_id indicates the last reached pickup point.
-- 3. eta indicates estimated time of arrival at next stop.
-- 4. reached_flag indicates if the vehicle has reached the current stop.
-- 5. emergency_flag indicates if there is an emergency situation.
-- 6. last_update captures the last update timestamp.
-- 7. deleted_at is for soft delete.

-- =======================================================================
-- DRIVER ATTENDANCE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` INT UNSIGNED NOT NULL,
    `check_in_time` DATETIME NOT NULL,
    `check_out_time` DATETIME DEFAULT NULL,
    `geo_lat` DECIMAL(10,7) DEFAULT NULL,       -- Location of check-in
    `geo_lng` DECIMAL(10,7) DEFAULT NULL,       -- Location of check-in
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,    -- 1=App, 0=Manual
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_da_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. driver_id links to tpt_personnel to get driver details.
-- 2. check_in_time and check_out_time capture attendance timings.
-- 3. geo_lat and geo_lng capture location of check-in.
-- 4. via_app indicates if attendance was marked via app or manually.
-- 5. deleted_at is for soft delete.

-- =======================================================================
-- Attendance can be done from at School Gate, Depot, Mobile App; hence Devices must be tracked for security & audit
Devices must be tracked for security & audit
CREATE TABLE transport_attendance_device (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_code VARCHAR(50) NOT NULL UNIQUE,
    device_name VARCHAR(100) NOT NULL,
    device_type ENUM('Mobile','Scanner','Tablet','Gate') NOT NULL,
    location VARCHAR(150) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. device_code must be unique.
-- 2. is_active indicates if device is currently in use.
-- 3. location is optional, can be null.
-- 4. created_at captures the creation timestamp.
-- 5. App logic to manage device assignments and usage.
-- 6. deleted_at is for soft delete.
-- 7. This table can be used to track devices used for attendance marking.
-- 8. device_type indicates the type of device being used.
-- 9. App logic to ensure only active devices are used for attendance marking.
-- 10. App logic to link attendance records to specific devices if needed.
-- 11. App logic to manage device lifecycle (activation, deactivation, replacement).
-- 12. App logic to generate reports based on device usage and attendance patterns.
-- 13. App logic to maintain a history of device assignments and usage for auditing purposes.
--

-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_allocation_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` INT UNSIGNED NOT NULL,  -- FK to 'std_student_sessions_jnt'
    `route_id` INT UNSIGNED NOT NULL,            -- FK to 'tpt_route'
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

11  Route -2    Pickpoint - 21  Fare 500.00 01/04/2025  
11  Route -4    Pickpoint - 12  Fare 700.00 01/10/2025

-- =======================================================================
-- TRANSPORT FEE
-- =======================================================================

-- define fines based on delay days
CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` INT UNSIGNED NOT NULL,    -- FK to 'std_academic_sessions'
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` INT UNSIGNED NOT NULL,    -- FK to 'std_academic_sessions'
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `fee_master_id` INT UNSIGNED NOT NULL,    -- FK to 'tpt_fee_master'
    `fine_master_id` INT UNSIGNED NOT NULL,   -- FK to 'tpt_fine_master'
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
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_allocation_id` INT UNSIGNED NOT NULL,
    `fee_master_id` INT UNSIGNED NOT NULL,
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
-- END OF SCRIPT
-- =======================================================================  


-- ---------------------------------------------------------------------------------------------------------------------------
-- Change Log
-- ---------------------------------------------------------------------------------------------------------------------------
-- Data Points for 'sch_settings' Table:
-- -------------------------------------
-- Add a Key Value paid in Table 'sch_settings' with Variable named 'Allow_only_one_side_transport_charges' to indicate if school allow one side fare.
-- Add a Key Value paid in Table 'sch_settings' with Variable named 'Allow_different_pickup_and_drop_point' to indicate if school allow different pickup & drop fare.
-- ---------------------------------------------------------------------------------------------------------------------------
-- Change Filed Type - Table (tpt_trip) - Change column 'trip_type' ENUM('Morning','Afternoon','Evening','Custom') DEFAULT 'Morning') to FK to tpt_shift
-- ALTER TABLE `tpt_trip` MODIFY COLUMN `trip_type` INT UNSIGNED DEFAULT NULL;
-- Add foreign key constraint
-- ALTER TABLE `tpt_trip` ADD CONSTRAINT `fk_trip_tripType` FOREIGN KEY (`trip_type`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL;
-- ALTER TABLE `tpt_trip` MODIFY COLUMN `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled';
-- ALTER TABLE `tpt_trip` ADD COLUMN `remarks` VARCHAR(512) DEFAULT NULL,
-- ALTER TABLE `tpt_trip` MODIFY COLUMN `pickup_route_id` - Make it 'pickup_drop' ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
-- Alter Table 'tpt_trip' Add Column 'route_scheduler_id' INT UNSIGNED NOT NULL AFTER 'trip_date';
-- Add foreign key constraint
-- ALTER TABLE `tpt_trip` ADD CONSTRAINT `fk_trip_route` FOREIGN KEY (`route_scheduler_id`) REFERENCES `tpt_route_scheduler_jnt`(`id`) ON DELETE RESTRICT;
-- Reason: To link trip to route schedule for getting shift, route, vehicle, driver, helper & pickup/drop info.
-- Alter Table 'tpt_trip' Drop Column 'route_id', 'pickup_drop', 'trip_type'. These are now derivable from route_scheduler_id.
-- ----------------------------------------------------------------------------------------------------------------------------- 
-- ALTER TABLE `tpt_pickup_points_route_jnt` ADD COLUMN `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup' AFTER `route_id`;
-- Reason of adding above col. is to differentiate between pickup and drop points in same route. Ordinal will be unique per pickup/drop type.
-- -----------------------------------------------------------------------------------------------------------------------------
-- Alter Table 'tpt_pickup_points_route_jnt' Add column 'pickup_fare' DECIMAL(10,2) DEFAULT NULL AFTER 'estimated_time';
-- Alter Table 'tpt_pickup_points_route_jnt' Add column 'drop_fare' DECIMAL(10,2) DEFAULT NULL AFTER 'pickup_fare';
-- Alter Table 'tpt_pickup_points_route_jnt' Add column 'both_side_fare' DECIMAL(10,2) DEFAULT NULL AFTER 'drop_fare';
-- Reason: To store estimated fare to/from each pickup point in a particuler route. Routes have different Path hence fare may vary for same pickup point in different routes.
-- Reason: Student may opt for pickup only OR drop only OR both side OR different Pickup & Drop Point transport. Fare needs to be stored accordingly.
-- -----------------------------------------------------------------------------------------------------------------------------
-- Alter Table 'tpt_driver_route_vehicle_jnt' Add column 'pickup_drop' ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both' AFTER 'helper_id';
-- Reason: To differentiate between Pickup/Drop/Both side assignments for same route in a shift.
-- -----------------------------------------------------------------------------------------------------------------------------
-- Add Table 'tpt_vehicle' Add column 'max_capacity' INT DEFAULT NULL AFTER 'registration_number';
-- Reason: To store Maximum allowed capacity including standing beyond seating capacity of vehicle.
-- -----------------------------------------------------------------------------------------------------------------------------