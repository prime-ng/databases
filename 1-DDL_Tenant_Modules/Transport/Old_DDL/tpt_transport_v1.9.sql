-- =======================================================================
-- TRANSPORT MODULE ENHANCED (working) for MySQL 8.x
-- Strategy: Took backup from v1.9, verify, then Enhance.
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VEHICLE, DRIVER, HELPER, SHIFT
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vendor` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_short_name` VARCHAR(50) NOT NULL,
    `vendor_name` VARCHAR(100) NOT NULL,
    `agreement_start_date` DATE NOT NULL,
    `agreement_end_date` DATE NOT NULL,
    `contact_no` VARCHAR(30) NOT NULL,
    `contact_person` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `address` VARCHAR(512) NOT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vendor_name` (`vendor_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- conditions:
    -- 1. vendor_name must be unique.
    -- 2. Agreement file will be stored in sys_media_table.
    -- 3. contact_no must be valid phone number.
    -- 4. email must be valid email address.
    -- 5. address must be valid address.
    -- 6. is_active indicates if vendor is currently active.

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_no` VARCHAR(20) NOT NULL,              -- Vehicle number(Vehicle Identification Number (VIN)/Chassis Number: A unique 17-character code stamped on the vehicle's chassis)
    `registration_no` VARCHAR(30) NOT NULL,         -- Unique govt registration number
    `model` VARCHAR(50),                            -- Vehicle model
    `manufacturer` VARCHAR(50),                     -- Vehicle manufacturer 
    `vehicle_type` VARCHAR(20) NOT NULL,            -- fk to sys_dropdown_table ('BUS','VAN','CAR')
    `fuel_type` VARCHAR(20) NOT NULL,               -- fk to sys_dropdown_table ('Diesel','Petrol','CNG','Electric')
    `capacity` INT UNSIGNED NOT NULL DEFAULT 40,    -- Seating capacity
    `max_capacity` INT UNSIGNED NOT NULL DEFAULT 40, -- Maximum allowed capacity including standing
    `ownership_type` VARCHAR(20) NOT NULL,          -- fk to sys_dropdown_table ('Owned','Leased','Rented')
    `vendor_id` INT UNSIGNED NOT NULL,            -- fk to tpt_vendor
    `fitness_valid_upto` DATE,                      -- Fitness certificate expiry date
    `insurance_valid_upto` DATE,                    -- Insurance expiry date
    `pollution_valid_upto` DATE,                    -- Pollution certificate expiry date
    `vehicle_emission_class` VARCHAR(20),           -- Vehicle emission class e.g. 'BS IV', 'BS V', 'BS VI'
    `fire_extinguisher_valid_upto` DATE,            -- Fire extinguisher expiry date
    `gps_device_id` VARCHAR(50),                    -- Installed GPS device identifier
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_vehicle_vehicleNo` (`vehicle_no`),
    UNIQUE KEY `uq_vehicle_registration_no` (`registration_no`),
    CONSTRAINT `fk_vehicle_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `tpt_vendor`(`id`) ON DELETE CASCADE    
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

CREATE TABLE IF NOT EXISTS `tpt_vendor_vehicle_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vendor_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `aggrement_start_date` DATE NOT NULL,
    `aggrement_end_date` DATE NOT NULL,
--    `aggrement_file` VARCHAR(255) NOT NULL,
    `charge_type` VARCHAR(20) NOT NULL DEFAULT 'Fixed', -- 'Fixed', 'Km_Basis', 'Hybrid'
    `monthly_fixed_charge` DECIMAL(10, 2) DEFAULT 0.00,
    `rate_per_km` DECIMAL(10, 2) DEFAULT 0.00,
    `rate_per_month` DECIMAL(10, 2) DEFAULT 0.00,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vendor_vehicle_jnt_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `tpt_vendor`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vendor_vehicle_jnt_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
 

-- =======================================================================
-- PERSONNEL (Transport Staff)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED DEFAULT NULL,
    `user_qr_code` VARCHAR(30) NOT NULL,     -- User code Auto generated (This will be used to generate QR token)    `qr_token` VARCHAR(100) NOT NULL,       -- QR token Auto generated using user_code
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
    `police_verification_done` TINYINT(1) NOT NULL DEFAULT 0,     -- Police verification done or not
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
    -- 3. Some users may have multiple roles (e.g., Driver + Helper) but will have separate records.
    -- 4. Some user whose primary Role belongs to some other department (e.g., Staff) can be regitered as Substitute Driver/Helper to be used in emergency(Driver/helper absent) situations.
    -- 5. In case of absence of dedicated Driver/Helper personnel, other Staff registered as temporarily Driver/Helper can be assigned.
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
    `total_distance` DECIMAL(7,2) DEFAULT NULL, -- Distance of pickup point/drop point from school in KM
    `estimated_time` INT DEFAULT NULL,          -- Estimated time from/to pickup_point/drop_point from School in minutes
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
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',  -- Indicates if this entry is for Pickup or Drop point, can not be 'Both'. Both have different ordinal & fare.
-- All below fields will move while doing Drag & Drp Function -----------------------
    `pickup_point_id` INT UNSIGNED NOT NULL,     -- fk to tpt_pickup_points
    `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1, -- Sequence of the pickup point / drop point in the route.
    `total_distance` DECIMAL(7,2) DEFAULT NULL,     -- Distance of pickup point/drop point from school in KM
    `arrival_time` INT DEFAULT NULL,                -- Arrival time at this point
    `departure_time` INT DEFAULT NULL,              -- Departure time from this point   
    `estimated_time` INT DEFAULT NULL,              -- Estimated time from/to pickup_point/drop_point from School in minutes
    `pickup_fare` DECIMAL(10,2) DEFAULT NULL,       -- Estimated fare to this point
    `drop_fare` DECIMAL(10,2) DEFAULT NULL,         -- Estimated fare from this point
    `both_side_fare` DECIMAL(10,2) DEFAULT NOT NULL, -- Estimated fare for both side to this point
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
-- --------------------------------------------------------------------------------
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
    -- 4. Amount in 'both_side_fare' is mandatory, cannot be null.
    -- 5. This table will have separate records for Pickup and Drop points for same pickup_point_id on same route.
    -- 6. pickup_drop indicates if this entry is for Pickup or Drop point, can not be 'Both'. Both have different ordinal & fare.
    -- 7. total_distance and estimated_time are optional, can be null.
    -- 8. If pickup_drop is 'Pickup", then dropdown to select pick_point_id should show only those points which are defined as 'Pickup' or 'Both' in tpt_pickup_points.
    -- 9. If pickup_drop is 'Drop", then dropdown to select pick_point_id should show only those points which are defined as 'Drop' or 'Both' in tpt_pickup_points.
    -- 10. is_active indicates if the pickup point is currently in use for the route.
    -- 11. deleted_at is for soft delete.

-- =======================================================================
-- ROUTE SCHEDULE & DRIVER ASSIGNMENT
-- =======================================================================
-- Junction table to assign Drivers and Vehicles to Routes for specific Shifts with effective date ranges.
CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `shift_id` INT UNSIGNED NOT NULL,        -- fk to 'tpt_shift'
    `route_id` INT UNSIGNED NOT NULL,        -- fk to 'tpt_route'
    `vehicle_id` INT UNSIGNED NOT NULL,      -- fk to 'tpt_vehicle'
    `driver_id` INT UNSIGNED NOT NULL,       -- fk to 'tpt_personnel'
    `helper_id` INT UNSIGNED DEFAULT NULL,   -- fk to 'tpt_personnel'
    `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    `effective_from` DATE NOT NULL,             -- Assignment validity period
    `effective_to` DATE DEFAULT NULL,           -- Assignment validity period
    `total_students` INT NOT NULL DEFAULT 0,    -- Total number of students assigned to this route
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
-- Conditions:
    -- 1. combination of shift_id, route_id, vehicle_id must be unique with non-overlapping effective date ranges.
    -- 2. combination of shift_id, route_id, driver_id must be unique with non-overlapping effective date ranges.
    -- 3. effective_from must be less than effective_to if effective_to is not null.
    -- 4. One Driver / Helper can be assigned to multiple vehicles/routes on same shift for different date ranges,but not overlapping date ranges.
    -- 5. A Vehicle can have different Drivers / Helpers on same shift for different date ranges but not overlapping date ranges.
    -- 6. A Driver / Helper can be assigned to different Vehicles on same shift for different date ranges but not overlapping date ranges.
    -- 7. pickup_drop indicates if the assignment is for Pickup, Drop or Both.
    -- 8. total_students indicates the total number of students assigned to this route. check if the total students assigned to a route is not greater than the capacity of the vehicle.
    -- 9. App logic to enforce capacity checks during Bus allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.
    -- 10. is_active indicates if the assignment is currently active.
    -- 11. deleted_at is for soft delete.

-- Trigger to enforce unique assignment of driver/vehicle/route/shift with non-overlapping date ranges
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
-- Conditions:
    -- 1. A Route can not be scheduled more than once on same date for same shift.
    -- 2. A Vehicle can not be scheduled for more than one route on same date for same shift.
    -- 3. A Driver can not be scheduled for more than one route on same date for same shift.
    -- 4. A Helper can not be scheduled for more than one route on same date for same shift.
    -- 5. pickup_drop indicates if the schedule is for Pickup or Drop.
    -- 6. This table will be pre-populated based on entries in 'tpt_driver_route_vehicle_jnt' for the date range.
    -- 7. App logic or DB triggers should prevent overlapping assignments for same vehicle/driver on same shift+route.
    -- 8. is_active indicates if the schedule is currently active.
    -- 9. deleted_at is for soft delete.

-- =======================================================================
-- TRIPS (will be creted by background service on Weekly/Monthly basis)
-- =======================================================================
-- 'tpt_route_scheduler_jnt' will be used to get schedule details for trip creation, whereas 'tpt_trip' will store actual trip details.
CREATE TABLE IF NOT EXISTS `tpt_trip` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_date` DATE NOT NULL,                      -- Date of the trip
    `route_scheduler_id` INT UNSIGNED NOT NULL,  -- FK to 'tpt_route_scheduler_jnt' for getting schedule details
    `vehicle_id` INT UNSIGNED NOT NULL,          -- FK to 'tpt_vehicle' (Actual vehicle used for the trip)
    `driver_id` INT UNSIGNED NOT NULL,           -- FK to 'tpt_personnel' (Actual driver for the trip)
    `helper_id` INT UNSIGNED DEFAULT NULL,       -- FK to 'tpt_personnel' (Actual helper for the trip)
    `start_time` DATETIME DEFAULT NULL,             -- Actual start time
    `end_time` DATETIME DEFAULT NULL,               -- Actual end time
    `status` VARCHAR(20) NOT NULL DEFAULT 'Scheduled', -- fk to sys_dropdown_table e.g. 'Scheduled', 'Completed', 'Cancelled'
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
-- Conditions:
    -- 1. route_scheduler_id links to tpt_route_scheduler_jnt to get schedule details.
    -- 2. vehicle_id, driver_id, helper_id are being captured to accomodate any change from scheduled assignment (e.e, substitute driver or vehicle).
    -- 3. status indicates current status of the trip (Scheduled, In-Progress, Completed, Cancelled).
    -- 4. is_active indicates if the trip is currently active.
    -- 5. deleted_at is for soft delete.


-- =======================================================================
-- LIVE TRIP STATUS
-- =======================================================================
-- Table to track live status of trips including current stop, ETA, and emergency situations.
-- This table needs to be filled and updated in real-time by GPS tracking system or mobile app. No Entry Screen needed.
CREATE TABLE IF NOT EXISTS `tpt_trip_stop_detail` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,                 -- FK to 'tpt_trip'
    `stop_id` INT UNSIGNED DEFAULT NULL,             -- FK to 'tpt_pickup_points'
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `sch_arrival_time` DATETIME DEFAULT NULL,          -- Scheduled time of arrival at next stop
    `sch_departure_time` DATETIME DEFAULT NULL,         -- Scheduled time of departure from next stop
    `reached_flag` TINYINT(1) NOT NULL DEFAULT 0,       -- 1=Reached current stop, 0=Not yet reached
    `reaching_time` TIMESTAMP DEFAULT NULL,             -- Time when the vehicle reached the current stop
    `leaving_time` TIMESTAMP DEFAULT NULL,              -- Time when the vehicle left the current stop
    `emergency_flag` TINYINT(1) DEFAULT 0,              -- 1=Emergency situation, 0=Normal
    `emergency_time` TIMESTAMP DEFAULT NULL,            -- Time when the emergency situation was triggered
    `emergency_remarks` VARCHAR(512) DEFAULT NULL,      -- Remarks for emergency situation
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `updated_by` INT UNSIGNED DEFAULT NULL,           -- FK to 'tpt_personnel'
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_trip_stop_detail_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_trip_stop_detail_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_trip_stop_detail_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. trip_id links to tpt_trip to get trip details.
    -- 2. stop_id indicates the last reached pickup point.
    -- 3. sch_arriving_time indicates scheduled time of arrival at next stop.
    -- 4. sch_departing_time indicates scheduled time of departure from next stop.
    -- 5. reached_flag indicates if the vehicle has reached the current stop.
    -- 6. emergency_flag indicates if there is an emergency situation.
    -- 7. last_update captures the last update timestamp.
    -- 8. deleted_at is for soft delete.

-- To store 'sch_arrival_time' and 'sch_departure_time' into 'tpt_trip_stop_detail' for a trip, we can use the following query:

-- tpt_trip -> tpt_route_scheduler_jnt 
-- Get route from tpt_route_scheduler_jnt and connect to tpt_pickup_points_route_jnt to find all the pickup_point_id in the route.
-- Then using pickup_point_id connect to tpt_pickup_points to get pickup_point_name and pickup_point_address.

-- =======================================================================
-- DRIVER ATTENDANCE
-- =======================================================================

-- ATTENDANCE FLOW (QR-based)
        -- Driver scans QR
        --     ↓
        -- App validates user_qr_id
        --     ↓
        -- Device authorization check
        --     ↓
        -- Log attendance event
        --     ↓
        -- Update daily summary
        --     ↓
        -- Notify Transport Incharge (optional)

-- SECURITY & ANTI-FRAUD DESIGN (IMPORTANT)
    -- - Unique user_qr_id per driver to prevent cloning.
    -- - Device authorization to ensure only registered devices can log attendance.
    -- - Geo-fencing to validate location of attendance scans. (Optional)
    -- - Time-based checks to prevent rapid multiple scans. (Optional)
    -- - Regular audits of attendance logs to identify anomalies. (Optional)
    -- - Alerts for suspicious activities (e.g., multiple failed scans, out-of-area scans). (Optional)
    -- - Data encryption for sensitive information (e.g., user_qr_id, location data). (Optional)
    -- - Access controls to restrict who can view or modify attendance records. (Optional)
    -- - Comprehensive logging of all attendance-related actions for audit trails. (Optional)

--  QR Token Rules:
    --  Token ≠ Driver ID (This will be used to generate QR token)
    --  Rotate token if card is lost
    --  Expire QR if driver is inactive

-- Attendance Validation Logic:
    --  Check for duplicate scans within a short time frame. (Reject duplicate IN within X minutes) 
    --  Validate scan location against predefined geo-fences. (Geo-fence validation (optional)
    --  Ensure scans occur during valid time windows (e.g., shift hours).
    --  Cross-check against driver assignments to prevent unauthorized attendance logging.
    --  Flag and review any anomalies detected during validation. Block scan from unauthorized device
    --  Maintain audit logs for all validation checks performed. 

-- Attendance can be done from at School Gate, Depot, Mobile App; hence Devices must be tracked for security & audit
-- Devices must be tracked for security & audit
CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `device_code` VARCHAR(50) NOT NULL UNIQUE,
    `device_name` VARCHAR(100) NOT NULL,
    `device_type` ENUM('Mobile','Scanner','Tablet','Gate') NOT NULL,    -- Type of device
    `location` VARCHAR(150) NULL,                       -- Physical location of the device
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

-- Daily Attendance Summary for Performance Optimization. ERP dashboards & payroll reports need fast daily status.
CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` INT UNSIGNED NOT NULL,
    `attendance_date` DATE NOT NULL,
    `first_in_time` DATETIME NULL,              --  First check-in time of the day
    `last_out_time` DATETIME NULL,              --  Last check-out time of the day
    `total_work_minutes` INT NULL,              --  Total work minutes of the day
    `attendance_status` ENUM('Present','Absent','Half-Day','Late') NOT NULL,    --  Attendance status of the day    
    `via_app` TINYINT(1) NOT NULL DEFAULT 1,    -- 1=App, 0=Manual
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_driver_day` (`driver_id`, `attendance_date`),
    FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. driver_id links to tpt_personnel to get driver details.
    -- 2. attendance_date captures the date of attendance.
    -- 3. first_in_time captures the first check-in time of the day.
    -- 4. last_out_time captures the last check-out time of the day.
    -- 5. total_work_minutes calculates total minutes worked based on in/out times.
    -- 6. attendance_status indicates overall attendance status for the day.
    -- 7. created_at captures the creation timestamp.
    -- 8. combination of driver_id and attendance_date must be unique.
    -- 9. App logic to aggregate daily attendance from event-based logs.
    -- 10. App logic to generate daily, weekly, monthly attendance reports.
    -- 11. App logic to handle exceptions like missing in/out times or overlapping scans.

-- Event-Based Attendance Logging. Allows: Multiple scans, Fraud detection, Late entry detection
CREATE TABLE IF NOT EXISTS `tpt_driver_attendance_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `attendance_id` INT UNSIGNED NOT NULL,   -- fk to tpt_driver_attendance
    `scan_time` DATETIME NOT NULL,          
    `attendance_type` ENUM('IN','OUT') NOT NULL,
    `scan_method` ENUM('QR','RFID','NFC','Manual') NOT NULL,        
    `device_id` INT UNSIGNED NOT NULL,
    `latitude` DECIMAL(10,6) NULL,      
    `longitude` DECIMAL(10,6) NULL,
    `scan_status` ENUM('Valid','Duplicate','Rejected') NOT NULL DEFAULT 'Valid',
    `remarks` VARCHAR(255) NULL,    
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_da_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `tpt_driver_attendance`(`id`) ON DELETE CASCADE,
    CONSTRAINT `FK_da_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. driver_id links to tpt_personnel to get driver details.
    -- 2. device_id links to tpt_attendance_device to get device details.
    -- 3. scan_time captures the timestamp of the scan.
    -- 4. attendance_type indicates if the scan is for check-in or check-out.
    -- 5. scan_method indicates the method used for scanning.
    -- 6. latitude and longitude capture the location of the scan.
    -- 7. scan_status indicates if the scan was valid, duplicate, or rejected.
    -- 8. remarks is optional, can be null.
    -- 9. created_at captures the creation timestamp.
    -- 10. App logic to validate scans and prevent duplicates.
    -- 11. App logic to generate reports based on attendance patterns and device usage.
    -- 12. App logic to manage attendance records and ensure data integrity.
    -- 13. If a Driver is already Login (Means the last entry in 'tpt_driver_attendance_log' is 'IN') then he can register Out Entry but can not register IN entry again.
    -- 14. If a Driver is already Logout (Means the last entry in 'tpt_driver_attendance_log' is 'OUT') then he can register In Entry but can not register Out entry again.



-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_jnt` (
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
    CONSTRAINT `fk_sa_studentSession` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_sessions_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_pickup` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_sa_drop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. student_session_id links to std_student_sessions_jnt to get student details.
    -- 2. route_id links to tpt_route to get route details.
    -- 3. pickup_stop_id and drop_stop_id link to tpt_pickup_points to get stop details.
    -- 4. fare indicates the transport fare for the student.
    -- 5. effective_from indicates the start date of the allocation.
    -- 6. active_status indicates if the allocation is currently active. only one allocation can be active for a student_session_id.
    -- 7. deleted_at is for soft delete.
    -- 8. App logic to ensure that pickup_stop_id and drop_stop_id belong to the selected route_id.
    -- 9. App logic to prevent duplicate active allocations for the same student_session_id.
    -- 10. App logic to manage allocation lifecycle (activation, deactivation, changes).
    -- 11. App logic to enforce capacity checks during student allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.
    -- 12. If 'Allow_different_pickup_and_drop_point' is true, then only pickup_stop_id & drop_stop_id can. be different.
    -- 13. If 'Allow_different_pickup_and_drop_point' is false, then pickup_stop_id & drop_stop_id must be same.
    -- 14. App logic to enforce fare checks during student allocation based on 'Allow_different_pickup_and_drop_point' setting.
   

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
-- Conditions:
    -- 1. generate Invoice on 1st of every month for the month
    -- 2. Example: fine_from_days - 1  fine_to_days - 5  fine_type - 'Fixed'  fine_rate - 50.00
    -- 3. old table name - tpt_fee_master    
    -- 4. std_academic_sessions_id links to std_academic_sessions to get academic session details.
    -- 5. fine_from_days and fine_to_days define the range of delay days for which the fine is applicable.
    -- 6. fine_type indicates the type of fine (Fixed or Percentage).
    -- 7. fine_rate defines the amount of fine.
    -- 8. Remark is optional, can be null.
    -- 9. created_at captures the creation timestamp.
    -- 10. deleted_at is for soft delete.
    -- 11. App logic to calculate fine based on delay days and fine rate.
    -- 12. App logic to generate invoices based on fine details.
    -- 13. App logic to manage fine lifecycle (activation, deactivation, changes).
    -- 14. App logic to enforce capacity checks during student allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.

CREATE TABLE IF NOT EXISTS `tpt_student_fee_detail` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `std_academic_sessions_id` INT UNSIGNED NOT NULL,    -- FK to 'std_academic_sessions'
    `month` DATE NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `fine_amount` DECIMAL(10,2) DEFAULT 0.00,
    `total_amount` DECIMAL(10,2) NOT NULL,
    `due_date` DATE NOT NULL,
    `Remark` VARCHAR(512) DEFAULT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'Pending',  -- FK - to sys_dropdown_table       e.g. 'Paid','Pending','Overdue'
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. tpt_student_fee_detail_id will have only one record for the same month.
    -- 2. Multipal tpt_studnt_fee_collection_id can be linked to the same tpt_student_fee_detail_id.
    -- 3. App logic to calculate fine based on delay days and fine rate.
    -- 4. App logic to generate invoices based on fine details.
    -- 5. App logic to manage fine lifecycle (activation, deactivation, changes).
    -- 6. App logic to enforce capacity checks during student allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.


-- link fines to fee master
-- old table name - tpt_fee_fine_detail
CREATE TABLE IF NOT EXISTS `tpt_student_fine_detail` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_fee_detail_id` INT UNSIGNED NOT NULL,    -- FK to 'tpt_student_fee_detail'
    `fine_master_id` INT UNSIGNED NOT NULL,   -- FK to 'tpt_fine_master'
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
-- Example: fee_master_id - 1  fine_days - 5  fine_type - 'Percentage'  fine_rate - 2.00    fine_amount - 10.00 
-- conditions:
    -- 1. student_fee_detail_id links to tpt_student_fee_detail to get fee details.
    -- 2. fine_master_id links to tpt_fine_master to get fine details.
    -- 3. App logic to calculate fine based on delay days and fine rate.
    -- 4. App logic to generate invoices based on fine details.
    -- 5. App logic to manage fine lifecycle (activation, deactivation, changes).
    -- 6. App logic to enforce capacity checks during student allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.

-- record fee payment against student allocation
-- old table name - tpt_fee_collection
CREATE TABLE IF NOT EXISTS `tpt_student_fee_collection` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_fee_detail_id` INT UNSIGNED NOT NULL,    -- FK to 'tpt_student_fee_detail'
    `payment_date` DATE NOT NULL,
    `total_delay_days` INT DEFAULT 0,
    `paid_amount` DECIMAL(10,2) NOT NULL,
    `payment_mode`  VARCHAR(20) NOT NULL, -- FK - to sys_dropdown_table       e.g. 'Cash','Card','Online'
    `status` VARCHAR(20) NOT NULL,        -- FK - to sys_dropdown_table       e.g. 'Paid','Pending','Overdue'
    `reconciled` TINYINT(1) NOT NULL DEFAULT 0,     -- 1 - Reconciled, 0 - Not Reconciled
    `remarks` VARCHAR(512) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_fc_fee_detail` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_fc_master` FOREIGN KEY (`fee_master_id`) REFERENCES `tpt_fee_master`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
    -- 1. student_fee_detail_id links to tpt_student_fee_detail to get fee details.
    -- 2. App logic to calculate fine based on delay days and fine rate.
    -- 3. App logic to generate invoices based on fine details.
    -- 4. App logic to manage fine lifecycle (activation, deactivation, changes).
    -- 5. App logic to enforce capacity checks during student allocation based on 'Allow_extra_student_in_vehicale_beyond_capacity' setting.    

-- --------------------------------------------------------------------------------------------------
-- Table to capture all Payment related activities across modules (Transport, Hostel, Tuition, etc.)
-- --------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `std_student_pay_log` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,              -- FK to std_students
  `academic_session_id` INT UNSIGNED NOT NULL,     -- FK to sch_org_academic_sessions_jnt (Mandatory for session-scoped filtering)
  `module_name` VARCHAR(50) NOT NULL,                 -- e.g. 'Transport', 'Tuition', 'Hostel', 'Library'
  `activity_type` VARCHAR(50) NOT NULL,               -- e.g. 'Invoice Generated', 'Payment Received', 'Payment Overdue', 'Reminder Sent', 'Part Payment'
  `amount` DECIMAL(10,2) DEFAULT NULL,                -- Amount involved in the activity (if any)
  `log_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reference_id` INT UNSIGNED DEFAULT NULL,        -- ID of the related record (Polymorphic Reference to the source record (e.g. Invoice ID or Collection ID))
  `reference_table` VARCHAR(100) DEFAULT NULL,        -- Table name of the reference record (e.g. 'tpt_student_fee_detail', 'tpt_student_fee_collection')
  `description` VARCHAR(512) DEFAULT NULL,                    -- Detailed description or remarks
  `triggered_by` INT UNSIGNED DEFAULT NULL,        -- FK to sys_users (User who performed the action, NULL for System/Job)
  `is_system_generated` TINYINT(1) DEFAULT 0,         -- 1 = Auto-generated by System (e.g. daily job), 0 = Manual Action
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
-- conditions:
    -- 1. log_date is the date when the payment was made.
    -- 2. App logic to manage complete student payment lifecycle (Invoice Generated, Payment Received, Payment Overdue, Reminder Sent, Part Payment).

-- =======================================================================
-- FUEL & MAINTENANCE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `date` DATE NOT NULL,
    `quantity` DECIMAL(10,3) NOT NULL,
    `cost` DECIMAL(12,2) NOT NULL,
    `fuel_type` INT UNSIGNED NOT NULL,   -- FK to 'sys_dropdown_table'
    `odometer_reading` INT UNSIGNED DEFAULT NULL,
    `remarks` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vfl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vfl_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions: 
-- 1. Approval will be done using "Action" Button
-- 2. Variable "tpt_vehicle_fuel_maintenance_approved_by" in 'sch_settings' table will be used to store the Role ID of the persons who can approve the fuel & maintenance logs  (Multiple Role IDs can be separated by comma)

Create Table if not EXISTS `tpt_daily_vehicle_inspection_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `inspection_date` DATE NOT NULL,
    `odometer_reading` INT UNSIGNED DEFAULT NULL,
    `fuel_level_percentage` DECIMAL(6,2) DEFAULT NULL, -- Percentage of fuel remaining
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
    `inspected_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `inspected_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_dvil_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_dvil_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_dvil_inspectedBy` FOREIGN KEY (`inspected_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Conditions:
-- 1. Approval will be done using "Action" Button
-- 2. Variable "tpt_vehicle_inspection_approved_by" in 'sch_settings' table will be used to store the Role ID of the persons who can approve the daily vehicle inspection logs  (Multiple Role IDs can be separated by comma)

Create Table if not EXISTS `tpt_vehicle_service_log` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_id` INT UNSIGNED NOT NULL, 
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `date_from` TIMESTAMP NOT NULL,
    `date_to` TIMESTAMP NOT NULL,
    `reason` VARCHAR(512) NOT NULL,
    `Vehicle_status` INT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown_table e.g. 'Available','Not Available','Under Maintenance','In Garage','Breakdown','Repaired','Not in Service','Other'
    `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',  -- Approval Status for Maintenance
    `approved_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vsl_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vsl_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vsl_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `vehicle_service_log_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `date` DATE NOT NULL,
    `maintenance_type` VARCHAR(120) NOT NULL,   -- e.g. 'Oil Change', 'Brake Inspection', 'Tire Rotation', 'Routine Service', 'Major Service', 'Other'
    `cost` DECIMAL(12,2) NOT NULL,
    `out_service` TINYINT(1) DEFAULT 0,
    `out_service_date` DATE DEFAULT NULL,
    `out_service_reason` VARCHAR(512) DEFAULT NULL,
    `workshop_details` VARCHAR(512) DEFAULT NULL,
    `next_due_date` DATE DEFAULT NULL,
    `remarks` VARCHAR(512) DEFAULT NULL,
    `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
    `approved_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_vm_vehicle_service_log` FOREIGN KEY (`vehicle_service_log_id`) REFERENCES `tpt_vehicle_service_log`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_vm_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_vm_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- TRIP INCIDENTS & ALERTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `incident_time` TIMESTAMP NOT NULL,
    `incident_type` INT UNSIGNED NOT NULL,  -- FK to sys_dropdown_table e.g. 'Accident', 'Breakdown', 'Fire', 'Theft', 'Tire Flat', 'Other'
    `severity` ENUM('LOW','MEDIUM','HIGH') DEFAULT 'MEDIUM',
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `status` INT UNSIGNED DEFAULT NULL,  -- FK to sys_dropdown_table e.g. 'Resolved', 'Pending', 'Investigating', 'Raised'
    `raised_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `raised_to` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `raised_at` TIMESTAMP NULL DEFAULT NULL,
    `resolved_at` TIMESTAMP NULL DEFAULT NULL,
    `resolved_by` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT `fk_ti_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ti_raisedBy` FOREIGN KEY (`raised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ti_raisedTo` FOREIGN KEY (`raised_to`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ti_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- --------------------------------------------------------------------------------------------------------






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
-- Add Table 'tpt_driver_route_vehicle_jnt' Add column 'total_students' INT DEFAULT NULL AFTER 'registration_number';
-- Reason: To store total number of students assigned to a route in a shift.
-- -----------------------------------------------------------------------------------------------------------------------------
-- Alter table 'tpt_live_trip' to add some columns 'reaching_time', 'leaving_time', 'emergency_flag', 'emergency_time', 'emergency_remarks'
-- Reason: To track live status of trips including current stop, ETA, and emergency situations.
-- -----------------------------------------------------------------------------------------------------------------------------
Changes in v1.8:
1. Add column 'police_verification_done' to 'tpt_driver' table to track if police verification is done or not.
2. Need to capture Police Verification Certificate & Police Verification Report in sys_media table.
3. Column 'vehicle_no' to 'tpt_vehicle' table to store Vehicle Identification Number (VIN)/Chassis Number: A unique 17-character code stamped on the vehicle's chassis.
4. Add column 'fire_extinguisher_valid_upto' to 'tpt_vehicle' table to store Fire Extinguisher Expiry Date.
5. Add column 'police_verification_done' to 'tpt_personnel' table to store whether Police Verification is done or not.

