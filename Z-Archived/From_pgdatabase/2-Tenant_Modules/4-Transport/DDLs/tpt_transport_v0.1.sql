-- =======================================================================
--  TRANSPORT MODULE - COMPLETE DATABASE STRUCTURE
--  Includes: Standard + Advanced Transport Tables
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- VEHICLE, DRIVER, HELPER, SHIFT
-- =======================================================================

CREATE TABLE tpt_vehicle (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_no VARCHAR(20) NOT NULL,
    registration_no VARCHAR(30) NOT NULL,
    model VARCHAR(50),
    manufacturer VARCHAR(50),
    vehicle_type VARCHAR(20) NOT NULL,           -- fk to (sys_dropdown_table) ('BUS','VAN','CAR')
    fuel_type VARCHAR(20) NOT NULL,              -- fk to (sys_dropdown_table)
    capacity INT UNSIGNED NOT NULL DEFAULT 40,
    ownership_type VARCHAR(20) NOT NULL,         -- fk to (sys_dropdown_table)
    fitness_valid_upto DATE,
    insurance_valid_upto DATE,
    pollution_valid_upto DATE,
    gps_device_id VARCHAR(50),
    is_active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_vehicle_vehicleNo (vehicle_no),
    UNIQUE KEY uq_vehicle_vehicleNo (registration_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tpt_driver_helper (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,      -- FK to sch_users (driver user)
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    id_type VARCHAR(10) NOT NULL,
    id_No VARCHAR() NOT NULL,
    driver_helper ENUM('Driver','Helper','Both') NOT NULL DEFAULT 'Driver',
    license_no VARCHAR(50) NULL,
    license_valid_upto DATE NULL,
    assigned_vehicle_id INT UNSIGNED,
    driving_exp_months TINYINT UNSIGNED NULL,
    address VARCHAR(255),
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_driverHelpr_userId FOREIGN KEY (user_id) REFERENCES sys_users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tpt_shift (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(50) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL,
    is_active tinyint(1) NOT NULL DEFAULT 1,
    created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at timestamp NULL DEFAULT NULL,
    UNIQUE KEY uq_shift_code (code),
    UNIQUE KEY uq_shift_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- ROUTES & STOPS
-- =======================================================================

CREATE TABLE tpt_route (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200) NULL,
    pickup_drop ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    shift_id INT unsigned NOT NULL,       -- FK
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_route_code (code),
    UNIQUE KEY uq_route_name (name),
    CONSTRAINT fk_route_shiftId FOREIGN KEY (shift_id) REFERENCES tpt_shift (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE tpt_pickup_points (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    total_distance DECIMAL(6,2) NOT NULL,
    estimated_time INT NOT NULL,            -- Time in Minutes
    stop_type ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
    shift_id INT unsigned NOT NULL,       -- FK
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY uq_route_code (code),
    UNIQUE KEY uq_route_name (name),
    CONSTRAINT fk_pickupPoint_shiftId FOREIGN KEY (shift_id) REFERENCES tpt_shift (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE tpt_pickup_points_route_jnt (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    shift_id INT unsigned NOT NULL,              -- FK
    route_id INT unsigned NOT NULL,              -- FK
    pickup_point_id INT unsigned NOT NULL,       -- FK
    ordinal tinyint(1) unsigned NOT NULL DEFAULT 1,
    total_distance DECIMAL(6,2) NOT NULL,
    estimated_time INT NOT NULL,            -- Time in Minutes
    is_active tinyint(1) NOT NULL DEFAULT 1,
    created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at timestamp NULL DEFAULT NULL,
    UNIQUE KEY uq_pickupPointRoute_shift_pickupPoint (shift_id,pickup_point_id),
    CONSTRAINT fk_pickupPointRoute_shiftId FOREIGN KEY (shift_id) REFERENCES tpt_shift (id) ON DELETE CASCADE,
    CONSTRAINT fk_pickupPointRoute_routeId FOREIGN KEY (route_id) REFERENCES tpt_route (id) ON DELETE CASCADE,
    CONSTRAINT fk_pickupPointRoute_pickupPointId FOREIGN KEY (pickup_point_id) REFERENCES tpt_pickup_points (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- Route Schedule & Driver Assignment
-- In this table we will captur Driver & Vehicle assignment to the Route for a period
-- =======================================================================

CREATE TABLE tpt_driver_route_vehicle_jnt (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    shift_id INT unsigned NOT NULL,          -- FK
    route_id INT unsigned NOT NULL,          -- FK
    vehicle_id INT UNSIGNED NOT NULL,        -- FK
    driver_id INT UNSIGNED NOT NULL,         -- fk
    helper_id INT UNSIGNED,                  -- fk
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    is_active tinyint(1) NOT NULL DEFAULT 1,
    created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at timestamp NULL DEFAULT NULL,
    CONSTRAINT fk_routeVehicle_shiftId FOREIGN KEY (shift_id) REFERENCES tpt_shift (id) ON DELETE CASCADE
    CONSTRAINT fk_routeVehicle_routeId FOREIGN KEY (route_id) REFERENCES tpt_route (id) ON DELETE CASCADE
    CONSTRAINT fk_routeVehicle_vehicleId FOREIGN KEY (vehicle_id) REFERENCES tpt_vehicle (id) ON DELETE CASCADE
    CONSTRAINT fk_routeVehicle_driverId FOREIGN KEY (driver_id) REFERENCES tpt_driver_helpr (id) ON DELETE CASCADE
    CONSTRAINT fk_routeVehicle_helperId FOREIGN KEY (helper_id) REFERENCES tpt_driver_helpr (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- This table will captur record for every Route for entire Academic Session
CREATE TABLE tpt_route_scheduler_jnt (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    scheduled_date DATE NOT NULL,
    shift_id INT unsigned NOT NULL,          -- FK
    route_id INT unsigned NOT NULL,          -- FK
    driver_id INT UNSIGNED NOT NULL,         -- fk
    helper_id INT UNSIGNED,                  -- fk
    is_active tinyint(1) NOT NULL DEFAULT 1,
    created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at timestamp NULL DEFAULT NULL,
    FOREIGN KEY (fk_routeVehicle_routeId) REFERENCES tpt_route(id),
    FOREIGN KEY (fk_routeVehicle_vehicleId) REFERENCES tpt_vehicle(id),
    FOREIGN KEY (fk_routeVehicle_driverId) REFERENCES tpt_driver_helpr(id),
    FOREIGN KEY (fk_routeVehicle_helperId) REFERENCES tpt_driver_helpr(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =======================================================================
-- TRIPS
-- =======================================================================

CREATE TABLE tpt_trip_jnt (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_date DATE NOT NULL,
    pickup_route_id INT UNSIGNED NOT NULL,   -- fk
    route_id INT UNSIGNED NOT NULL,
    vehicle_id INT UNSIGNED NOT NULL,
    driver_id INT UNSIGNED NOT NULL,
    helper_id INT UNSIGNED NULL,                -- Can be Null
    trip_type ENUM('Morning','Afternoon','Evening','Custom'),
    start_time DATETIME,
    end_time DATETIME,
    status ENUM('Scheduled','Ongoing','Completed','Cancelled') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES transport_route(id),
    FOREIGN KEY (vehicle_id) REFERENCES transport_vehicle(id),
    FOREIGN KEY (driver_id) REFERENCES transport_driver(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;





-- =======================================================================
-- LIVE TRIP STATUS
-- =======================================================================

CREATE TABLE tpt_live_trip (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_id INT UNSIGNED NOT NULL,
    current_stop_id INT UNSIGNED,
    eta DATETIME,                         -- eta (Estimated Time of Arrival)
    reached_flag TINYINT(1) NOT NULL DEFAULT 0,
    emergency_flag TINYINT(1) DEFAULT 0,
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES transport_trip(id),
    FOREIGN KEY (current_stop_id) REFERENCES transport_route_stops(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- DRIVER ATTENDANCE
-- =======================================================================

CREATE TABLE tpt_driver_attendance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    driver_id INT UNSIGNED NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    geo_lat DECIMAL(10,6),
    geo_lng DECIMAL(10,6),
    via_app TINYINT(1) NOT NULL DEFAULT 1,
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- =======================================================================
-- STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE tpt_student_allocation_jnt (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_session_id INT UNSIGNED NOT NULL,
    route_id INT UNSIGNED NOT NULL,
    pickup_stop_id INT UNSIGNED NOT NULL,
    drop_stop_id INT UNSIGNED NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    effective_from DATE NOT NULL,
    active_status TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES transport_route(id),
    FOREIGN KEY (pickup_stop_id) REFERENCES transport_route_stops(id),
    FOREIGN KEY (drop_stop_id) REFERENCES transport_route_stops(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- TRANSPORT FEE
-- =======================================================================

CREATE TABLE tpt_fee_master (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id INT UNSIGNED NOT NULL,
    month TINYINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    fine_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tpt_fee_collection (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_allocation_id INT UNSIGNED NOT NULL,
    fee_master_id INT UNSIGNED NOT NULL,
    paid_amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_mode ENUM('Cash','UPI','Card','Bank','Cheque') NOT NULL,
    status ENUM('Paid','Partial','Pending') NOT NULL DEFAULT 'Paid',
    remarks VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_allocation_id) REFERENCES transport_student_allocation(id),
    FOREIGN KEY (fee_master_id) REFERENCES transport_fee_master(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;






-- =======================================================================
-- ADVANCED (AI MODULE)
-- =======================================================================

CREATE TABLE tpt_route_simulation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    simulation_date DATETIME NOT NULL,
    input_students_json JSON NOT NULL,
    input_stops_json JSON NOT NULL,
    optimized_route_json JSON NOT NULL,
    optimized_distance DECIMAL(6,2),
    optimized_time INT,
    ai_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tpt_route_ai_recommendation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    simulation_id INT UNSIGNED NOT NULL,
    suggested_stops_json JSON NOT NULL,
    merged_stops_json JSON,
    student_shift_json JSON,
    potential_distance_saving DECIMAL(6,2),
    potential_fuel_saving DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES transport_route_simulation(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- GPS LOGS
-- =======================================================================

CREATE TABLE tpt_gps_trip_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_id INT UNSIGNED NOT NULL,
    log_time DATETIME NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    speed DECIMAL(5,2),
    ignition_status TINYINT(1),
    deviation_flag TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES transport_trip(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tpt_gps_alerts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT UNSIGNED NOT NULL,
    alert_type ENUM('Overspeed','Idle','RouteDeviation') NOT NULL,
    log_time DATETIME NOT NULL,
    message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES transport_vehicle(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- FUEL & MAINTENANCE
-- =======================================================================

CREATE TABLE vehicle_fuel_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT UNSIGNED NOT NULL,
    date DATE NOT NULL,
    quantity DECIMAL(6,2) NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    fuel_type ENUM('Diesel','Petrol','CNG','Electric') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES transport_vehicle(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE vehicle_maintenance (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT UNSIGNED NOT NULL,
    maintenance_type VARCHAR(80) NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    workshop_details VARCHAR(255),
    next_due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES transport_vehicle(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =======================================================================
-- NOTIFICATIONS
-- =======================================================================

CREATE TABLE transport_notification_log (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_session_id INT UNSIGNED NOT NULL,
    trip_id INT UNSIGNED NOT NULL,
    stop_id INT UNSIGNED,
    notification_type ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled'),
    sent_time DATETIME NOT NULL,
    status ENUM('Sent','Failed') NOT NULL DEFAULT 'Sent',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trip_id) REFERENCES transport_trip(id),
    FOREIGN KEY (stop_id) REFERENCES transport_route_stops(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;


-- ----------------------------------------------------------------------------------------------------------
-- Change Log
-- ----------------------------------------------------------------------------------------------------------
-- Edit Field     -  Table(tpt_driver_helpr) -
--                -  license_no VARCHAR(50) NOT NULL,    ->    license_no VARCHAR(50) NULL,
--                -  license_valid_upto DATE NOT NULL,   ->    license_valid_upto DATE NULL,
--                -  Reason(If Person is Helper than 'license_no' & 'license_valid_upto' will be null)
-- Remove Field   -  Table(tpt_route) - Remove Fields (total_distance)
-- Remove Field   -  Table(tpt_route) - Remove Fields (estimated_time)
-- Add New Field  -  Table(tpt_route) - New Field(pickup_drop)
--                -  Reason(Path of the Rout can be different for Pickup & Drop OR Different Ordinal of Pickup Points)
-- Add New Field  -  Table(tpt_route) - New Field(shift_id)
-- Add New Field  -  Table(tpt_pickup_points) - New Field(shift_id)
-- Add New Field  -  Table(tpt_pickup_points) - New Field(total_distance)
-- Add New Field  -  Table(tpt_pickup_points) - New Field(estimated_time)
-- Add New Field  -  Table(tpt_pickup_points_route_jnt) - New Field(total_distance)
-- Add New Field  -  Table(tpt_pickup_points_route_jnt) - New Field((estimated_time)
-- update UQ      -  Table(tpt_pickup_points_route_jnt) - (UNIQUE KEY uq_pickupPointRoute_shift_pickupPoint_route)
-- Add New Field  -  Table(tpt_vehicle) - New Field(vehicle_type)
-- Add New Field  -  Table(tpt_driver_helper) - New Field(user_id)
-- ----------------------------------------------------------------------------------------------------------
-- 
--
