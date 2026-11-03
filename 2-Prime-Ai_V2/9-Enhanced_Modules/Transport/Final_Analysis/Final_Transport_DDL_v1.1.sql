-- =======================================================================
-- PRIME-AI TRANSPORT FAMILY — FINAL REFINED TENANT SCHEMA
-- File: 02-Final_Transport_DDL_v1.0.sql
-- Target: MySQL 8.0.32+ / InnoDB / utf8mb4
-- Date: 2026-11-01
-- =======================================================================
--
-- PURPOSE
-- -------
  -- This is the consolidated target schema for the three Transport generations:
  --   * Modules/Transport      — Foundation (tpt_* live network, operations, billing,
  --                              plan lifecycle, history, Advisor tables)
  --   * Modules/SmartTransport — Standard add-on (no own tables; reads tpt_*)
  --   * Modules/PrimeTransport — Prime add-on (ptr_* engine/geo/ETA/safety tables)
--
-- TABLE COUNT: 82 (67 tpt_ + 14 ptr_ + 1 shared std_student_pay_log) + 3 views.
--
-- It replaces, for new work:
  --   * Transport_DDL_v2.3.sql
  --   * Transport_DDL_v2.7.sql
  --   * PrimeTransport_DDL_v1.0.sql
  --   * the tpt_route_proposal_* / tpt_*_history proposal tables
  --   * ptr_plans / ptr_plan_* (migrated into tpt_transport_plan + tpt_plan_*)
--
-- DESIGN RULES
-- ------------
  --   1. tpt_* = the live network, operations, finance, plan lifecycle, history,
  --      and Standard Advisor data. Owned by Foundation.
  --   2. ptr_* = Prime intelligence only: settings, distance cache, student geo,
  --      engine runs, stop-generation runs, ETA, disruptions, quotes, safety.
  --   3. A plan is a versioned, class-and-date-scoped network. Draft children
  --      live in tpt_plan_*; publish is the ONLY writer of live network tables.
  --   4. History is anchored to tpt_plan_publication, never to a proposal.
  --      A history row survives deletion of the live row it came from.
  --   5. Every invoice/charge/payment carries plan + publication id.
  --   6. Missing coordinates stay NULL. A separate tpt_pickup_point_geo table
  --      holds the NOT NULL spatial POINT so a SPATIAL INDEX is valid.
  --   7. All FK names are unique across the tenant schema (fk_<table>_<column>).
  --   8. Standard columns: is_active, created_by, updated_by, created_at,
  --      updated_at, deleted_at. High-volume logs omit soft-delete columns.
  --   9. Money DECIMAL(12,2) unless a smaller range is clearly safe.
  --  10. MySQL cannot put a SPATIAL INDEX on a nullable geometry column.
  --      Therefore route_geometry is nullable and has no spatial index; use
  --      ST_Distance_Sphere on the stored WKT or the point geo table instead.
--
-- MIGRATION
-- ---------
-- See 02-Schema_Evaluation_and_Design.md for the old-to-new table mapping.
-- This file is additive/target-state; it does not drop anything.
--
-- =======================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================================
-- SECTION A — FOUNDATION MASTERS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_plan_type` (
   `id` TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `code` VARCHAR(30) NOT NULL COMMENT 'Regular, Junior, Senior, PrePrimary, Sports, Staff, Event',
   `name` VARCHAR(100) NOT NULL,
   `description` VARCHAR(500) DEFAULT NULL,
   `is_system` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_plan_type_code` (`code`),
   UNIQUE KEY `uq_tpt_plan_type_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Plan type master: Regular, Junior, Senior, Sports, Staff, Event.';

CREATE TABLE IF NOT EXISTS `tpt_shift` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `code` VARCHAR(20) NOT NULL,
   `name` VARCHAR(100) NOT NULL,
   `description` VARCHAR(500) DEFAULT NULL,
   `effective_from` DATE NOT NULL,
   `effective_to` DATE NOT NULL,
   `shift_start_time` TIME NOT NULL COMMENT 'Time all buses of this shift must reach school.',
   `shift_end_time` TIME NOT NULL COMMENT 'Time buses leave school for this shift.',
   `pickup_reach_by` TIME DEFAULT NULL COMMENT 'Hard pickup arrival target used by the Prime engine.',
   `drop_depart_at` TIME DEFAULT NULL COMMENT 'Hard drop departure target used by the Prime engine.',
   `days_of_week` SET('Mon','Tue','Wed','Thu','Fri','Sat','Sun') NOT NULL DEFAULT 'Mon,Tue,Wed,Thu,Fri,Sat',
   `grace_minutes` SMALLINT UNSIGNED NOT NULL DEFAULT 5,
   `direction` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_shift_code` (`code`),
   UNIQUE KEY `uq_tpt_shift_name` (`name`),
   KEY `idx_tpt_shift_window` (`is_active`, `shift_start_time`, `shift_end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Operating window: arrival target, departure time, working days, grace.';

CREATE TABLE IF NOT EXISTS `tpt_vehicle` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `vehicle_no` VARCHAR(20) NOT NULL COMMENT 'VIN / chassis / internal vehicle number.',
   `registration_no` VARCHAR(30) NOT NULL COMMENT 'Government registration number.',
   `model` VARCHAR(50) DEFAULT NULL,
   `manufacturer` VARCHAR(50) DEFAULT NULL,
   `facilities` JSON DEFAULT NULL COMMENT '{"is_ac":true,"is_cctv":true,"wifi":true,"tv":true,"water_bottle":true}',
   `vehicle_type_id` INT UNSIGNED NOT NULL COMMENT 'FK sys_dropdown_table (BUS/VAN/CAR).',
   `fuel_type_id` INT UNSIGNED NOT NULL COMMENT 'FK sys_dropdown_table (Diesel/Petrol/CNG/Electric).',
   `capacity` INT UNSIGNED NOT NULL DEFAULT 40 COMMENT 'Seating capacity.',
   `max_capacity` INT UNSIGNED NOT NULL DEFAULT 40 COMMENT 'Maximum including standing.',
   `ownership_type_id` INT UNSIGNED NOT NULL COMMENT 'FK sys_dropdown_table (Owned/Leased/Rented).',
   `vendor_id` INT UNSIGNED DEFAULT NULL COMMENT 'Required when ownership is Leased/Rented.',
   `depot_name` VARCHAR(200) DEFAULT NULL,
   `depot_latitude` DECIMAL(10,7) DEFAULT NULL,
   `depot_longitude` DECIMAL(10,7) DEFAULT NULL,
   `fitness_valid_upto` DATE DEFAULT NULL,
   `insurance_valid_upto` DATE DEFAULT NULL,
   `pollution_valid_upto` DATE DEFAULT NULL,
   `fire_extinguisher_valid_upto` DATE DEFAULT NULL,
   `vehicle_emission_class_id` INT UNSIGNED DEFAULT NULL COMMENT 'FK sys_dropdown_table (BS IV/BS VI/Euro).',
   `gps_device_id` VARCHAR(50) DEFAULT NULL,
   `vehicle_photo_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `registration_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `fitness_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `insurance_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `pollution_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `vehicle_emission_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `fire_extinguisher_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `gps_device_cert_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `availability_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1 COMMENT '0 = not available, 1 = available.',
   `avg_exp_per_km` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
   `avg_fare_per_km` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
   `rating` DECIMAL(3,2) UNSIGNED NOT NULL DEFAULT 0.00,
   `odometer_difference_check_required` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,  -- IF True then check difference between last day end_odometer with Start_odometer
   `odometer_tolerence_km` SMALLINT UNSIGNED DEFAULT NULL,  -- NULL - Unlimited
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_vehicle_regNo_vehicleNo` (`registration_no`, `vehicle_no`),
   KEY `idx_tpt_vehicle_available` (`is_active`, `availability_status`),
   KEY `idx_tpt_vehicle_vendor` (`vendor_id`),
   CONSTRAINT `fk_tpt_vehicle_type` FOREIGN KEY (`vehicle_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_vehicle_fuel` FOREIGN KEY (`fuel_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_vehicle_ownership` FOREIGN KEY (`ownership_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_vehicle_emission` FOREIGN KEY (`vehicle_emission_class_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_vehicle_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fleet vehicle master: capacity, ownership, vendor, depot, compliance, cost/km.';
-- Conditions :
  -- Start odometer must be ≥ last completed end odometer; this will be must for owned buses but optional for leased/rented. 
  -- Default tolerance 5 km (warning) and hard block beyond, if `odometer_difference_check_required` has been set = True by school.
  -- Tolerance can be configured saperately for each bus by school - `odometer_tolerence_km`
--

CREATE TABLE IF NOT EXISTS `tpt_personnel` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `user_id` INT UNSIGNED DEFAULT NULL,
   `user_qr_code` VARCHAR(30) NOT NULL,
   `id_card_type` ENUM('QR','RFID','NFC','Barcode') NOT NULL DEFAULT 'QR',
   `name` VARCHAR(100) NOT NULL,
   `phone` VARCHAR(30) DEFAULT NULL,
   `email` VARCHAR(150) DEFAULT NULL,
   `id_type` VARCHAR(20) DEFAULT NULL COMMENT 'Aadhaar/PAN/Passport/VoterID.',
   `id_no_encrypted` TEXT DEFAULT NULL COMMENT 'Encrypted at rest by the application cast.',
   `id_no_hash` CHAR(64) DEFAULT NULL COMMENT 'SHA-256 for exact-match search only.',
   `role` VARCHAR(30) NOT NULL COMMENT 'Driver/Helper/TransportManager/Coordinator/Other.',
   `license_no_encrypted` TEXT DEFAULT NULL,
   `license_no_hash` CHAR(64) DEFAULT NULL,
   `license_valid_upto` DATE DEFAULT NULL,
   `assigned_vehicle_id` INT UNSIGNED DEFAULT NULL,
   `driving_exp_months` SMALLINT UNSIGNED DEFAULT NULL,
   `police_verification_done` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `police_verification_valid_upto` DATE DEFAULT NULL,
   `address` VARCHAR(512) DEFAULT NULL,
   `id_card_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `photo_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `driving_license_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `police_verification_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `address_proof_upload` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_personnel_qr` (`user_qr_code`),
   KEY `idx_tpt_personnel_role` (`role`, `is_active`),
   KEY `idx_tpt_personnel_license` (`license_valid_upto`),
   CONSTRAINT `fk_tpt_personnel_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_personnel_vehicle` FOREIGN KEY (`assigned_vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Driver/helper/manager master: licence, experience, police verification, encrypted IDs.';

CREATE TABLE IF NOT EXISTS `tpt_transport_plan` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `code` VARCHAR(50) NOT NULL,
   `name` VARCHAR(200) NOT NULL,
   `description` VARCHAR(1000) DEFAULT NULL,
   `plan_type_id` TINYINT UNSIGNED NOT NULL,
   `academic_session_id` SMALLINT UNSIGNED NOT NULL,
   `source` ENUM('Manual','Engine','Advisor','Disruption','Import','WhatIf') NOT NULL DEFAULT 'Manual',
   `status` ENUM('Draft','InReview','Approved','Scheduled','Published','Superseded','Rejected','Cancelled','Archived','RolledBack') NOT NULL DEFAULT 'Draft',
   `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
   `parent_plan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Plan cloned/regenerated from.',
   `baseline_hash` CHAR(64) DEFAULT NULL COMMENT 'SHA-256 of the live network used to build the plan.',
   `levers_json` JSON DEFAULT NULL COMMENT 'Generation inputs: objective, constraints, what-if levers.',
   `kpi_json` JSON DEFAULT NULL COMMENT 'Students, routes, buses, km, cost, income, margin, ride, walk, unserved.',
   `effective_from` DATE DEFAULT NULL,
   `effective_to` DATE DEFAULT NULL,
   `is_billable` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `billing_mode` ENUM('Monthly','Term','Annual','PerTrip','None') NOT NULL DEFAULT 'Monthly',
   `proration_policy` ENUM('FullMonth','DailyProrata','NextCycle') NOT NULL DEFAULT 'DailyProrata',
   `currency` CHAR(3) NOT NULL DEFAULT 'INR',
   `submitted_at` TIMESTAMP NULL DEFAULT NULL,
   `submitted_by` INT UNSIGNED DEFAULT NULL,
   `approved_at` TIMESTAMP NULL DEFAULT NULL,
   `approved_by` INT UNSIGNED DEFAULT NULL,
   `published_at` TIMESTAMP NULL DEFAULT NULL,
   `published_by` INT UNSIGNED DEFAULT NULL,
   `rolled_back_at` TIMESTAMP NULL DEFAULT NULL,
   `archived_at` TIMESTAMP NULL DEFAULT NULL,
   `remarks` VARCHAR(1000) DEFAULT NULL,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_plan_code` (`code`),
   KEY `idx_tpt_plan_status` (`status`, `effective_from`, `effective_to`),
   KEY `idx_tpt_plan_session` (`academic_session_id`, `status`),
   KEY `idx_tpt_plan_parent` (`parent_plan_id`),
   CONSTRAINT `fk_tpt_plan_type` FOREIGN KEY (`plan_type_id`) REFERENCES `tpt_plan_type`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_plan_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_plan_parent` FOREIGN KEY (`parent_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_plan_submittedBy` FOREIGN KEY (`submitted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_plan_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_plan_publishedBy` FOREIGN KEY (`published_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_plan_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
   CONSTRAINT `fk_tpt_plan_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One versioned, class-and-date-scoped transport network. Draft -> review -> approve -> publish -> supersede/rollback.';

CREATE TABLE IF NOT EXISTS `tpt_transport_plan_class_jnt` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `plan_id` INT UNSIGNED NOT NULL,
   `academic_session_id` SMALLINT UNSIGNED NOT NULL,
   `class_id` INT UNSIGNED NOT NULL,
   `section_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL = all sections of the class.',
   `effective_from` DATE NOT NULL,
   `effective_to` DATE DEFAULT NULL,
   `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Higher wins only when an explicit override is allowed.',
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_plan_class` (`plan_id`, `class_id`, `section_id`, `effective_from`),
   KEY `idx_tpt_plan_class_scope` (`class_id`, `section_id`, `effective_from`, `effective_to`, `is_active`),
   CONSTRAINT `fk_tpt_plan_class_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tpt_plan_class_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_plan_class_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`) ON DELETE RESTRICT,
   CONSTRAINT `fk_tpt_plan_class_section` FOREIGN KEY (`section_id`) REFERENCES `sch_sections`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Which classes/sections a plan applies to, and for which date range. section_id NULL = all sections; the application enforces uniqueness for the NULL case because MySQL allows multiple NULLs in a unique key.';

CREATE TABLE IF NOT EXISTS `tpt_transport_plan_shift_jnt` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `plan_id` INT UNSIGNED NOT NULL,
   `shift_id` INT UNSIGNED NOT NULL,
   `pickup_drop` ENUM('Pickup','Drop') NOT NULL,
   `pickup_reach_by` TIME DEFAULT NULL,
   `drop_depart_at` TIME DEFAULT NULL,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   UNIQUE KEY `uq_tpt_plan_shift` (`plan_id`, `shift_id`, `pickup_drop`),
   CONSTRAINT `fk_tpt_plan_shift_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tpt_plan_shift_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Shifts and direction covered by a plan, with timing overrides.';

CREATE TABLE IF NOT EXISTS `tpt_transport_plan_rule` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `plan_id` INT UNSIGNED NOT NULL,
   `rule_code` VARCHAR(60) NOT NULL COMMENT 'e.g. MAX_RIDE_MIN, MAX_WALK_M, ARRIVAL_BUFFER_MIN.',
   `scope_type` ENUM('Plan','Class','Route','Student') NOT NULL DEFAULT 'Plan',
   `scope_id` INT UNSIGNED DEFAULT NULL,
   `value_json` JSON NOT NULL,
   `is_hard` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   UNIQUE KEY `uq_tpt_plan_rule` (`plan_id`, `rule_code`, `scope_type`, `scope_id`),
   CONSTRAINT `fk_tpt_plan_rule_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-plan constraint snapshot/override; makes generation reproducible.';

CREATE TABLE IF NOT EXISTS `tpt_compliance_document` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `entity_type` ENUM('Vehicle','Personnel') NOT NULL,
   `entity_id` INT UNSIGNED NOT NULL,
   `document_type` ENUM('Fitness','Insurance','Pollution','FireExtinguisher','Emission','GPS','Registration','DrivingLicence','PoliceVerification','AddressProof','Other') NOT NULL,
   `document_no` VARCHAR(100) DEFAULT NULL,
   `valid_from` DATE DEFAULT NULL,
   `valid_upto` DATE DEFAULT NULL,
   `media_id` INT UNSIGNED DEFAULT NULL,
   `verification_status` ENUM('Pending','Verified','Rejected','Expired') NOT NULL DEFAULT 'Pending',
   `verified_by` INT UNSIGNED DEFAULT NULL,
   `verified_at` TIMESTAMP NULL DEFAULT NULL,
   `remarks` VARCHAR(500) DEFAULT NULL,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   KEY `idx_tpt_doc_entity` (`entity_type`, `entity_id`, `document_type`, `valid_upto`),
   KEY `idx_tpt_doc_expiry` (`valid_upto`, `verification_status`),
   CONSTRAINT `fk_tpt_doc_verifiedBy` FOREIGN KEY (`verified_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Polymorphic compliance document with validity; replaces per-column upload flags over time.';

-- =======================================================================
-- SECTION B — NETWORK
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_pickup_points` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `code` VARCHAR(50) NOT NULL,
   `name` VARCHAR(200) NOT NULL,
   `latitude` DECIMAL(10,7) DEFAULT NULL,
   `longitude` DECIMAL(10,7) DEFAULT NULL,
   `location` POINT SRID 4326 DEFAULT NULL COMMENT 'Nullable for compatibility; indexed copy in tpt_pickup_point_geo.',
   `geohash` VARCHAR(12) DEFAULT NULL,
   `geocode_status` ENUM('Pending','Geocoded','Manual','Failed') NOT NULL DEFAULT 'Pending',
   `address_text` VARCHAR(500) DEFAULT NULL,
   `landmark` VARCHAR(200) DEFAULT NULL,
   `stop_type` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
   `total_distance` DECIMAL(7,2) DEFAULT NULL COMMENT 'KM from school.',
   `estimated_time` INT DEFAULT NULL COMMENT 'Minutes from school.',
   `safety_flags` JSON DEFAULT NULL COMMENT '{"main_road_crossing":false,"lit":true,"shelter":true,"narrow_lane":false,"safe_preprimary":true}',
   `is_verified` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_stop_code` (`code`),
   UNIQUE KEY `uq_tpt_stop_name` (`name`),
   KEY `idx_tpt_stop_lat_lng` (`latitude`, `longitude`),
   KEY `idx_tpt_stop_geocode` (`geocode_status`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Physical stop master. Missing coordinates remain NULL and are flagged as Pending.';

CREATE TABLE IF NOT EXISTS `tpt_pickup_point_geo` (
   `stop_id` INT UNSIGNED NOT NULL,
   `location` POINT NOT NULL SRID 4326,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`stop_id`),
   SPATIAL INDEX `sp_idx_tpt_stop_geo` (`location`),
   CONSTRAINT `fk_tpt_stop_geo_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Spatial copy for indexed proximity queries. One row per geocoded stop.';

CREATE TABLE IF NOT EXISTS `tpt_route` (
   `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   `tpt_plan_id` INT UNSIGNED NOT NULL,
   `shift_id` INT UNSIGNED NOT NULL,
   `code` VARCHAR(50) NOT NULL,
   `name` VARCHAR(200) NOT NULL,
   `description` VARCHAR(500) DEFAULT NULL,
   `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
   `route_geometry` LINESTRING SRID 4326 DEFAULT NULL COMMENT 'Real road path when available; estimated path otherwise.',
   `total_distance_km` DECIMAL(8,2) UNSIGNED DEFAULT NULL,
   `est_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
   `est_exp_per_km` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
   `capacity_allocated` SMALLINT UNSIGNED DEFAULT NULL,
   `status` ENUM('Draft','Active','Inactive','Archived') NOT NULL DEFAULT 'Active',
   `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
   `created_by` INT UNSIGNED DEFAULT NULL,
   `updated_by` INT UNSIGNED DEFAULT NULL,
   `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
   `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `deleted_at` TIMESTAMP NULL DEFAULT NULL,
   UNIQUE KEY `uq_tpt_route_plan_code` (`tpt_plan_id`, `code`),
   KEY `idx_tpt_route_shift` (`shift_id`, `pickup_drop`, `status`, `is_active`),
   CONSTRAINT `fk_tpt_route_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
   CONSTRAINT `fk_tpt_route_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='A route belongs to a plan and a shift; direction is Pickup or Drop only.';

CREATE TABLE IF NOT EXISTS `tpt_pickup_points_route_jnt` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `route_id` INT UNSIGNED NOT NULL,
  `pickup_point_id` INT UNSIGNED NOT NULL,
  `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
  `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `total_distance` DECIMAL(7,2) DEFAULT NULL,
  `arrival_time` INT DEFAULT NULL COMMENT 'Minutes from midnight.',
  `departure_time` INT DEFAULT NULL COMMENT 'Minutes from midnight.',
  `estimated_time` INT DEFAULT NULL COMMENT 'Minutes from school.',
  `pickup_drop_fare` DECIMAL(10,2) DEFAULT NULL,
  `both_side_fare` DECIMAL(10,2) DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_route_stop` (`route_id`, `pickup_point_id`),
  UNIQUE KEY `uq_tpt_route_ordinal` (`route_id`, `ordinal`),
  KEY `idx_tpt_route_stop_stop` (`pickup_point_id`),
  CONSTRAINT `fk_tpt_route_stop_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_route_stop_stop` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ordered stop sequence on a route with times and fallback fares.';

CREATE TABLE IF NOT EXISTS `tpt_transport_fare` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tpt_plan_id` INT UNSIGNED NOT NULL,
  `route_id` INT UNSIGNED DEFAULT NULL,
  `pickup_point_id` INT UNSIGNED DEFAULT NULL,
  `class_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL = all classes.',
  `pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
  `one_way_fare` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `both_way_fare` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `effective_from` DATE NOT NULL,
  `effective_to` DATE DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_fare_scope` (`tpt_plan_id`, `route_id`, `pickup_point_id`, `class_id`, `effective_from`),
  CONSTRAINT `fk_tpt_fare_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_fare_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_fare_stop` FOREIGN KEY (`pickup_point_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_fare_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Versioned plan-aware fare matrix by route, stop, class and direction.';

-- =======================================================================
-- SECTION C — ASSIGNMENT, ROSTER, TRIPS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_jnt` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `shift_id` INT UNSIGNED NOT NULL,
  `route_id` INT UNSIGNED NOT NULL,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `driver_id` INT UNSIGNED NOT NULL,
  `helper_id` INT UNSIGNED DEFAULT NULL,
  `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
  `effective_from` DATE NOT NULL,
  `effective_to` DATE DEFAULT NULL,
  `total_students` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Derived; never a drifting hand-maintained counter.',
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_assign_route` (`route_id`, `effective_from`, `effective_to`),
  KEY `idx_tpt_assign_driver` (`driver_id`, `effective_from`, `effective_to`),
  KEY `idx_tpt_assign_vehicle` (`vehicle_id`, `effective_from`, `effective_to`),
  CONSTRAINT `fk_tpt_assign_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_assign_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_assign_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_assign_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_assign_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Dated driver+helper+vehicle assignment to a route. Overlap enforced by app + optional trigger.';

CREATE TABLE IF NOT EXISTS `tpt_route_scheduler_jnt` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `scheduled_date` DATE NOT NULL,
  `shift_id` INT UNSIGNED NOT NULL,
  `route_id` INT UNSIGNED NOT NULL,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `driver_id` INT UNSIGNED NOT NULL,
  `helper_id` INT UNSIGNED DEFAULT NULL,
  `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
  `tpt_plan_id` INT UNSIGNED DEFAULT NULL,
  `is_override` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `override_reason` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_sched_route` (`scheduled_date`, `shift_id`, `route_id`, `pickup_drop`),
  UNIQUE KEY `uq_tpt_sched_vehicle` (`vehicle_id`, `scheduled_date`, `shift_id`, `pickup_drop`),
  UNIQUE KEY `uq_tpt_sched_driver` (`driver_id`, `scheduled_date`, `shift_id`, `pickup_drop`),
  UNIQUE KEY `uq_tpt_sched_helper` (`helper_id`, `scheduled_date`, `shift_id`, `pickup_drop`),
  KEY `idx_tpt_sched_date` (`scheduled_date`, `shift_id`, `is_active`),
  CONSTRAINT `fk_tpt_sched_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_sched_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_sched_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_sched_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_sched_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_sched_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Daily roster: one route, vehicle, driver and helper per date/shift/direction.';

CREATE TABLE IF NOT EXISTS `tpt_trip` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `trip_date` DATE NOT NULL,
  `route_scheduler_id` INT UNSIGNED NOT NULL,
  `route_id` INT UNSIGNED NOT NULL,
  `shift_id` INT UNSIGNED NOT NULL,
  `tpt_plan_id` INT UNSIGNED DEFAULT NULL,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `driver_id` INT UNSIGNED NOT NULL,
  `helper_id` INT UNSIGNED DEFAULT NULL,
  `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
  `start_time` DATETIME DEFAULT NULL,
  `end_time` DATETIME DEFAULT NULL,
  `start_odometer_reading` DECIMAL(11,2) DEFAULT NULL COMMENT 'NULL when not entered; never silently 0.',
  `end_odometer_reading` DECIMAL(11,2) DEFAULT NULL,
  `start_fuel_reading` DECIMAL(8,3) DEFAULT NULL,
  `end_fuel_reading` DECIMAL(8,3) DEFAULT NULL,
  `status` ENUM('Scheduled','InTransit','Completed','Cancelled','Approved') NOT NULL DEFAULT 'Scheduled',
  `approved` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `remarks` VARCHAR(1000) DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_trip_date` (`trip_date`, `status`),
  KEY `idx_tpt_trip_route` (`route_id`, `trip_date`),
  KEY `idx_tpt_trip_vehicle` (`vehicle_id`, `trip_date`),
  KEY `idx_tpt_trip_driver` (`driver_id`, `trip_date`),
  CONSTRAINT `fk_tpt_trip_scheduler` FOREIGN KEY (`route_scheduler_id`) REFERENCES `tpt_route_scheduler_jnt`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_trip_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_trip_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_trip_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_trip_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_trip_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_trip_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_trip_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One run of a route on a date; approval freezes operational data.';

CREATE TABLE IF NOT EXISTS `tpt_trip_stop_detail` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `trip_id` INT UNSIGNED NOT NULL,
  `stop_id` INT UNSIGNED DEFAULT NULL,
  `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
  `ordinal` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `sch_arrival_time` DATETIME DEFAULT NULL,
  `sch_departure_time` DATETIME DEFAULT NULL,
  `reached_flag` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `reaching_time` DATETIME DEFAULT NULL,
  `leaving_time` DATETIME DEFAULT NULL,
  `emergency_flag` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `emergency_time` TIMESTAMP NULL DEFAULT NULL,
  `emergency_remarks` VARCHAR(500) DEFAULT NULL,
  `gps_latitude` DECIMAL(10,7) DEFAULT NULL,
  `gps_longitude` DECIMAL(10,7) DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_trip_stop` (`trip_id`, `stop_id`, `pickup_drop`),
  KEY `idx_tpt_trip_stop_order` (`trip_id`, `ordinal`),
  KEY `idx_tpt_trip_stop_time` (`sch_arrival_time`),
  CONSTRAINT `fk_tpt_trip_stop_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_trip_stop_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_trip_stop_user` FOREIGN KEY (`updated_by`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Scheduled vs actual stop events within a trip.';

CREATE TABLE IF NOT EXISTS `tpt_trip_incidents` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `trip_id` INT UNSIGNED NOT NULL,
  `incident_time` DATETIME NOT NULL,
  `incident_type_id` INT UNSIGNED NOT NULL COMMENT 'FK sys_dropdown_table (Breakdown/Accident/Delay/Speeding/Medical/Discipline).',
  `severity` ENUM('LOW','MEDIUM','HIGH','CRITICAL') NOT NULL DEFAULT 'MEDIUM',
  `latitude` DECIMAL(10,7) DEFAULT NULL,
  `longitude` DECIMAL(10,7) DEFAULT NULL,
  `description` VARCHAR(1000) NOT NULL,
  `status` ENUM('Open','InProgress','Resolved','Closed') NOT NULL DEFAULT 'Open',
  `action_taken` VARCHAR(1000) DEFAULT NULL,
  `raised_by` INT UNSIGNED DEFAULT NULL,
  `raised_at` TIMESTAMP NULL DEFAULT NULL,
  `resolved_at` TIMESTAMP NULL DEFAULT NULL,
  `resolved_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_incident_trip` (`trip_id`, `status`),
  KEY `idx_tpt_incident_severity` (`severity`, `created_at`),
  CONSTRAINT `fk_tpt_incident_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_incident_type` FOREIGN KEY (`incident_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_incident_raisedBy` FOREIGN KEY (`raised_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_incident_resolvedBy` FOREIGN KEY (`resolved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Safety and operational incident; never deleted by plan operations.';

-- =======================================================================
-- SECTION D — ATTENDANCE, BOARDING, EVENTS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_attendance_device` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL COMMENT 'FK tpt_personnel; devices bind to people, not vehicles.',
  `device_uuid` CHAR(36) NOT NULL,
  `device_type` ENUM('Mobile','Tablet','Laptop','Desktop') NOT NULL,
  `location` VARCHAR(150) DEFAULT NULL,
  `device_os` INT UNSIGNED NOT NULL COMMENT 'FK sys_dropdown_table.',
  `os_version` VARCHAR(50) DEFAULT NULL,
  `device_name` VARCHAR(100) NOT NULL,
  `device_model` VARCHAR(100) DEFAULT NULL,
  `app_version` VARCHAR(20) DEFAULT NULL,
  `fcm_token_encrypted` TEXT DEFAULT NULL,
  `first_registered_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen_at` TIMESTAMP NULL DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_device_uuid` (`device_uuid`),
  UNIQUE KEY `uq_tpt_device_user` (`user_id`, `device_uuid`),
  KEY `idx_tpt_device_user` (`user_id`, `is_active`),
  CONSTRAINT `fk_tpt_device_user` FOREIGN KEY (`user_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_device_os` FOREIGN KEY (`device_os`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Registered QR/RFID/app device; suspended device returns 403.';

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `driver_id` INT UNSIGNED NOT NULL,
  `attendance_date` DATE NOT NULL,
  `first_in_time` DATETIME DEFAULT NULL,
  `last_out_time` DATETIME DEFAULT NULL,
  `total_work_minutes` INT DEFAULT NULL,
  `attendance_status` INT UNSIGNED NOT NULL COMMENT 'FK sys_dropdown_table (Present/Absent/Half-Day/Late).',
  `via_app` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `source` ENUM('App','Manual','Device') NOT NULL DEFAULT 'App',
  `remarks` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_attendance_day` (`driver_id`, `attendance_date`),
  KEY `idx_tpt_attendance_date` (`attendance_date`, `attendance_status`),
  CONSTRAINT `fk_tpt_attendance_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_attendance_status` FOREIGN KEY (`attendance_status`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One daily attendance summary per driver/helper.';

CREATE TABLE IF NOT EXISTS `tpt_driver_attendance_log` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `attendance_id` INT UNSIGNED NOT NULL,
  `scan_time` DATETIME NOT NULL,
  `attendance_type` ENUM('IN','OUT') NOT NULL,
  `scan_method` ENUM('QR','RFID','NFC','Manual','App') NOT NULL,
  `device_id` INT UNSIGNED DEFAULT NULL,
  `latitude` DECIMAL(10,7) DEFAULT NULL,
  `longitude` DECIMAL(10,7) DEFAULT NULL,
  `scan_status` ENUM('Valid','Duplicate','Rejected') NOT NULL DEFAULT 'Valid',
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_att_log_attendance` (`attendance_id`, `scan_time`),
  CONSTRAINT `fk_tpt_att_log_attendance` FOREIGN KEY (`attendance_id`) REFERENCES `tpt_driver_attendance`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_att_log_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Punch-level log; immutable after capture.';

CREATE TABLE IF NOT EXISTS `tpt_student_boarding_log` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `trip_date` DATE NOT NULL,
  `trip_id` INT UNSIGNED DEFAULT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `student_session_id` INT UNSIGNED NOT NULL,
  `route_id` INT UNSIGNED DEFAULT NULL,
  `stop_id` INT UNSIGNED DEFAULT NULL,
  `direction` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
  `boarding_time` DATETIME DEFAULT NULL,
  `unboarding_time` DATETIME DEFAULT NULL,
  `unboarding_stop_id` INT UNSIGNED DEFAULT NULL,
  `device_id` INT UNSIGNED DEFAULT NULL,
  `scan_status` ENUM('Valid','Duplicate','Rejected','Manual') NOT NULL DEFAULT 'Valid',
  `is_manual` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_boarding_student` (`student_id`, `trip_date`),
  KEY `idx_tpt_boarding_trip` (`trip_id`, `direction`),
  KEY `idx_tpt_boarding_date` (`trip_date`, `route_id`),
  CONSTRAINT `fk_tpt_boarding_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_boarding_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_boarding_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_boarding_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_boarding_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_boarding_unboardStop` FOREIGN KEY (`unboarding_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_boarding_device` FOREIGN KEY (`device_id`) REFERENCES `tpt_attendance_device`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Child movement record: boarding and unboarding per trip/direction.';

CREATE TABLE IF NOT EXISTS `tpt_student_event_log` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `student_session_id` INT UNSIGNED NOT NULL,
  `event_type` ENUM('Boarding','Unboarding','Absent','StopChange','AllocationChange','Incident','PlanChange') NOT NULL,
  `event_time` DATETIME NOT NULL,
  `trip_id` INT UNSIGNED DEFAULT NULL,
  `stop_id` INT UNSIGNED DEFAULT NULL,
  `route_id` INT UNSIGNED DEFAULT NULL,
  `metadata_json` JSON DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_tpt_student_event` (`student_id`, `event_time`),
  KEY `idx_tpt_student_event_type` (`event_type`, `event_time`),
  CONSTRAINT `fk_tpt_student_event_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_student_event_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Audit trail of every student transport event.';

-- =======================================================================
-- SECTION E — VEHICLE LIFECYCLE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_vehicle_fuel` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `driver_id` INT UNSIGNED DEFAULT NULL,
  `trip_id` INT UNSIGNED DEFAULT NULL,
  `fuel_date` DATE NOT NULL,
  `quantity` DECIMAL(10,3) NOT NULL,
  `cost` DECIMAL(12,2) NOT NULL,
  `fuel_type_id` INT UNSIGNED NOT NULL,
  `odometer_reading` INT UNSIGNED DEFAULT NULL,
  `station` VARCHAR(200) DEFAULT NULL,
  `invoice_no` VARCHAR(80) DEFAULT NULL,
  `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_fuel_vehicle_date` (`vehicle_id`, `fuel_date`, `status`),
  CONSTRAINT `fk_tpt_fuel_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_fuel_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_fuel_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_fuel_type` FOREIGN KEY (`fuel_type_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fuel_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fuel voucher; only Approved rows count toward km/L and P&L.';

CREATE TABLE IF NOT EXISTS `tpt_daily_vehicle_inspection` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `driver_id` INT UNSIGNED DEFAULT NULL,
  `inspection_date` DATETIME NOT NULL,
  `odometer_reading` INT UNSIGNED DEFAULT NULL,
  `fuel_level_reading` DECIMAL(6,2) DEFAULT NULL,
  `tire_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `lights_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `brakes_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `engine_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `battery_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `fire_extinguisher_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `first_aid_kit_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `seat_belts_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `headlights_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `tailights_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `wipers_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `mirrors_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `steering_wheel_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `emergency_tools_condition_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `cleanliness_ok` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `any_issues_found` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `issues_description` VARCHAR(1000) DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `inspection_status` ENUM('Passed','Failed','Pending') NOT NULL DEFAULT 'Pending',
  `inspected_by` INT UNSIGNED DEFAULT NULL,
  `inspected_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_inspection_vehicle` (`vehicle_id`, `inspection_date`, `inspection_status`),
  CONSTRAINT `fk_tpt_inspection_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_inspection_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_inspection_user` FOREIGN KEY (`inspected_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='15-point pre-trip checklist; critical failure blocks dispatch.';

CREATE TABLE IF NOT EXISTS `tpt_vehicle_service_request` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `vehicle_inspection_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL only for a manual fault with a reason.',
  `request_date` DATETIME NOT NULL,
  `reason` VARCHAR(1000) DEFAULT NULL,
  `vehicle_status_id` INT UNSIGNED DEFAULT NULL COMMENT 'FK sys_dropdown_table (Due for Service/In-Service/Service Done).',
  `priority` ENUM('Low','Normal','High','Critical') NOT NULL DEFAULT 'Normal',
  `service_completion_date` DATETIME DEFAULT NULL,
  `request_approval_status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_service_vehicle` (`vehicle_id`, `request_approval_status`),
  CONSTRAINT `fk_tpt_service_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_service_inspection` FOREIGN KEY (`vehicle_inspection_id`) REFERENCES `tpt_daily_vehicle_inspection`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_service_status` FOREIGN KEY (`vehicle_status_id`) REFERENCES `sys_dropdown_table`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_service_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Service request from failed inspection or manual fault; approval creates maintenance.';

CREATE TABLE IF NOT EXISTS `tpt_vehicle_maintenance` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `vehicle_id` INT UNSIGNED NOT NULL,
  `vehicle_service_request_id` INT UNSIGNED NOT NULL,
  `maintenance_initiation_date` DATE NOT NULL,
  `maintenance_type` VARCHAR(120) NOT NULL,
  `cost` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `vendor_id` INT UNSIGNED DEFAULT NULL,
  `invoice_no` VARCHAR(80) DEFAULT NULL,
  `in_service_date` DATE DEFAULT NULL,
  `out_service_date` DATE DEFAULT NULL,
  `workshop_details` VARCHAR(500) DEFAULT NULL,
  `next_due_date` DATE DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `status` ENUM('Approved','Pending','Rejected') NOT NULL DEFAULT 'Pending',
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_maint_vehicle` (`vehicle_id`, `maintenance_initiation_date`),
  KEY `idx_tpt_maint_due` (`next_due_date`, `status`),
  CONSTRAINT `fk_tpt_maint_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_maint_request` FOREIGN KEY (`vehicle_service_request_id`) REFERENCES `tpt_vehicle_service_request`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_maint_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_maint_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Approved repair record; approval raises a vendor payable for leased/rented vehicles.';

-- =======================================================================
-- SECTION F — STUDENT ALLOCATION
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_jnt` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `student_session_id` INT UNSIGNED NOT NULL,
  `tpt_plan_id` INT UNSIGNED NOT NULL,
  `transport_use_type` ENUM('Pickup','Drop','Both') NOT NULL,
  `pickup_route_id` INT UNSIGNED DEFAULT NULL,
  `pickup_stop_id` INT UNSIGNED DEFAULT NULL,
  `drop_route_id` INT UNSIGNED DEFAULT NULL,
  `drop_stop_id` INT UNSIGNED DEFAULT NULL,
  `fare` DECIMAL(10,2) DEFAULT NULL COMMENT 'NULL until a billable fare is known.',
  `fare_source` ENUM('Master','Allocation','Override','Manual') NOT NULL DEFAULT 'Master',
  `effective_from` DATE NOT NULL,
  `effective_to` DATE DEFAULT NULL,
  `active_status` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `change_reason` VARCHAR(500) DEFAULT NULL,
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_alloc_student` (`student_session_id`, `active_status`, `effective_from`),
  KEY `idx_tpt_alloc_pickup` (`pickup_route_id`, `pickup_stop_id`, `active_status`),
  KEY `idx_tpt_alloc_drop` (`drop_route_id`, `drop_stop_id`, `active_status`),
  KEY `idx_tpt_alloc_plan` (`tpt_plan_id`, `active_status`),
  CONSTRAINT `fk_tpt_alloc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_alloc_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_alloc_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_alloc_pickupRoute` FOREIGN KEY (`pickup_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_alloc_pickupStop` FOREIGN KEY (`pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_alloc_dropRoute` FOREIGN KEY (`drop_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_alloc_dropStop` FOREIGN KEY (`drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_alloc_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Current student allocation; plan-aware and date-ranged. One active per student/session/direction.';

CREATE TABLE IF NOT EXISTS `tpt_student_stop_change_request` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `student_session_id` INT UNSIGNED NOT NULL,
  `current_allocation_id` INT UNSIGNED DEFAULT NULL,
  `requested_pickup_route_id` INT UNSIGNED DEFAULT NULL,
  `requested_pickup_stop_id` INT UNSIGNED DEFAULT NULL,
  `requested_drop_route_id` INT UNSIGNED DEFAULT NULL,
  `requested_drop_stop_id` INT UNSIGNED DEFAULT NULL,
  `reason` VARCHAR(500) DEFAULT NULL,
  `status` ENUM('Pending','Approved','Rejected','Cancelled') NOT NULL DEFAULT 'Pending',
  `requested_by` INT UNSIGNED DEFAULT NULL,
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `effective_from` DATE DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_stop_change_student` (`student_id`, `status`),
  CONSTRAINT `fk_tpt_stop_change_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_stop_change_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tpt_stop_change_alloc` FOREIGN KEY (`current_allocation_id`) REFERENCES `tpt_student_route_allocation_jnt`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_stop_change_pickupRoute` FOREIGN KEY (`requested_pickup_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_stop_change_pickupStop` FOREIGN KEY (`requested_pickup_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_stop_change_dropRoute` FOREIGN KEY (`requested_drop_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_stop_change_dropStop` FOREIGN KEY (`requested_drop_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_stop_change_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
  COMMENT='Parent/staff stop-change request and approval workflow.';
-- Conditions:
-- Need to add 1 more field (`new_fare_effective_from` DATE DEFAULT NULL,), which will be used for billing.

-- =======================================================================
-- SECTION G — BILLING AND ACCOUNTING
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_fine_category` (
  `id` TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `category_name` VARCHAR(100) NOT NULL,
  `initiated_by` ENUM('Transport','Finance') NOT NULL DEFAULT 'Transport',
  `evidence_required` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_fine_category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Fine/charge category master.';

CREATE TABLE IF NOT EXISTS `tpt_fine_master` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `fine_category_id` TINYINT UNSIGNED NOT NULL,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL,
  `tpt_plan_id` INT UNSIGNED DEFAULT NULL,
  `code` VARCHAR(40) NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  `charge_type` ENUM('LateFee','Penalty','Damage','LostCard','StopChange','Other') NOT NULL DEFAULT 'LateFee',
  `calc_type` ENUM('Fixed','Percentage','PerDay','Slab') NOT NULL DEFAULT 'PerDay',
  `fine_from_days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `fine_to_days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `fine_rate` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `max_amount` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '0 = no cap.',
  `grace_days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `student_restricted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Transport-only restriction; never ERP deactivation.',
  `applies_to` ENUM('Invoice','Student','Allocation') NOT NULL DEFAULT 'Invoice',
  `effective_from` DATE DEFAULT NULL,
  `effective_to` DATE DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_fine_code` (`academic_session_id`, `code`),
  KEY `idx_tpt_fine_band` (`academic_session_id`, `charge_type`, `fine_from_days`, `fine_to_days`),
  CONSTRAINT `fk_tpt_fine_category` FOREIGN KEY (`fine_category_id`) REFERENCES `tpt_fine_category`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fine_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fine_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Late fee/penalty/damage rule with day bands, grace and cap.';

CREATE TABLE IF NOT EXISTS `tpt_billing_run` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL,
  `billing_month` DATE NOT NULL COMMENT 'First day of the billing month.',
  `tpt_plan_id` INT UNSIGNED DEFAULT NULL,
  `run_type` ENUM('Regular','LateFee','Penalty','Adjustment') NOT NULL DEFAULT 'Regular',
  `status` ENUM('Queued','Running','Completed','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
  `total_students` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_amount` DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  `generated_by` INT UNSIGNED DEFAULT NULL,
  `started_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `error_text` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY `idx_tpt_billing_run` (`academic_session_id`, `billing_month`, `run_type`, `status`),
  CONSTRAINT `fk_tpt_billing_run_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_billing_run_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_billing_run_user` FOREIGN KEY (`generated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Idempotent billing run header; one per session/month/plan/type.';

CREATE TABLE IF NOT EXISTS `tpt_plan_publication` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `plan_id` INT UNSIGNED NOT NULL,
  `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `effective_from` DATE NOT NULL,
  `effective_to` DATE DEFAULT NULL,
  `published_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `published_by` INT UNSIGNED DEFAULT NULL,
  `status` ENUM('Published','Superseded','RolledBack') NOT NULL DEFAULT 'Published',
  `baseline_hash_before` CHAR(64) DEFAULT NULL,
  `baseline_hash_after` CHAR(64) DEFAULT NULL,
  `snapshot_before_id` INT UNSIGNED DEFAULT NULL,
  `snapshot_after_id` INT UNSIGNED DEFAULT NULL,
  `superseded_plan_id` INT UNSIGNED DEFAULT NULL,
  `notes` VARCHAR(1000) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tpt_publication_version` (`plan_id`, `version`),
  KEY `idx_tpt_publication_scope` (`status`, `effective_from`, `effective_to`),
  CONSTRAINT `fk_tpt_publication_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_publication_publishedBy` FOREIGN KEY (`published_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_publication_superseded` FOREIGN KEY (`superseded_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='A plan going live. Anchors all history and billing references.';

CREATE TABLE IF NOT EXISTS `tpt_transport_invoice` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `invoice_no` VARCHAR(40) NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `student_session_id` INT UNSIGNED NOT NULL,
  `tpt_plan_id` INT UNSIGNED NOT NULL,
  `plan_publication_id` INT UNSIGNED DEFAULT NULL COMMENT 'Which published network version this invoice belongs to.',
  `allocation_id` INT UNSIGNED DEFAULT NULL,
  `billing_run_id` INT UNSIGNED DEFAULT NULL,
  `invoice_type` ENUM('Regular','LateFee','Penalty','Adjustment','CreditNote') NOT NULL DEFAULT 'Regular',
  `billing_period_from` DATE NOT NULL,
  `billing_period_to` DATE NOT NULL,
  `subtotal` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `discount_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `fine_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `paid_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `balance_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `due_date` DATE NOT NULL,
  `status` ENUM('Draft','Issued','PartiallyPaid','Paid','Overdue','Cancelled','WrittenOff') NOT NULL DEFAULT 'Issued',
  `accounting_status` ENUM('Pending','Posted','Failed','NotRequired') NOT NULL DEFAULT 'Pending',
  `accounting_voucher_id` INT UNSIGNED DEFAULT NULL,
  `accounting_voucher_no` VARCHAR(60) DEFAULT NULL,
  `issued_at` TIMESTAMP NULL DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `updated_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_invoice_no` (`invoice_no`),
  UNIQUE KEY `uq_tpt_invoice_period` (`student_session_id`, `tpt_plan_id`, `billing_period_from`, `billing_period_to`, `invoice_type`),
  KEY `idx_tpt_invoice_student` (`student_id`, `status`),
  KEY `idx_tpt_invoice_due` (`due_date`, `status`),
  KEY `idx_tpt_invoice_plan` (`tpt_plan_id`, `plan_publication_id`),
  CONSTRAINT `fk_tpt_invoice_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_invoice_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_invoice_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_invoice_publication` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_invoice_alloc` FOREIGN KEY (`allocation_id`) REFERENCES `tpt_student_route_allocation_jnt`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_invoice_run` FOREIGN KEY (`billing_run_id`) REFERENCES `tpt_billing_run`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Routine, late-fee, penalty, adjustment and credit-note invoice; plan-aware.';

CREATE TABLE IF NOT EXISTS `tpt_transport_invoice_line` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT UNSIGNED NOT NULL,
  `line_type` ENUM('TransportFee','LateFee','Penalty','Adjustment','Discount','Tax','Other') NOT NULL,
  `reference_table` VARCHAR(60) DEFAULT NULL,
  `reference_id` INT UNSIGNED DEFAULT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `quantity` DECIMAL(8,2) NOT NULL DEFAULT 1.00,
  `unit_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  KEY `idx_tpt_invoice_line` (`invoice_id`, `sort_order`),
  CONSTRAINT `fk_tpt_invoice_line_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Invoice line detail; immutable after issue.';

CREATE TABLE IF NOT EXISTS `tpt_transport_charge` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `student_session_id` INT UNSIGNED NOT NULL,
  `tpt_plan_id` INT UNSIGNED NOT NULL,
  `charge_type` ENUM('LateFee','Penalty','Damage','LostCard','StopChange','Other') NOT NULL,
  `fine_master_id` INT UNSIGNED DEFAULT NULL,
  `reference_invoice_id` INT UNSIGNED DEFAULT NULL,
  `charge_date` DATE NOT NULL,
  `due_date` DATE DEFAULT NULL,
  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `waived_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `net_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('Pending','Invoiced','Paid','Waived','Cancelled') NOT NULL DEFAULT 'Pending',
  `invoice_id` INT UNSIGNED DEFAULT NULL,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `approved_by` INT UNSIGNED DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_by` INT UNSIGNED DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_charge_student` (`student_id`, `status`),
  KEY `idx_tpt_charge_plan` (`tpt_plan_id`, `charge_type`),
  CONSTRAINT `fk_tpt_charge_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_charge_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_charge_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_charge_rule` FOREIGN KEY (`fine_master_id`) REFERENCES `tpt_fine_master`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_charge_refInvoice` FOREIGN KEY (`reference_invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_charge_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_charge_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Separate late-fee/penalty/damage charge; invoiced independently of the routine invoice.';

CREATE TABLE IF NOT EXISTS `tpt_transport_payment` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `invoice_id` INT UNSIGNED NOT NULL,
  `student_id` INT UNSIGNED NOT NULL,
  `receipt_no` VARCHAR(40) NOT NULL,
  `payment_date` DATE NOT NULL,
  `amount` DECIMAL(12,2) NOT NULL,
  `payment_mode` ENUM('Cash','Cheque','NEFT','UPI','Card','Gateway','Adjustment') NOT NULL,
  `transaction_ref` VARCHAR(120) DEFAULT NULL,
  `gateway` VARCHAR(60) DEFAULT NULL,
  `status` ENUM('Pending','Cleared','Processing','Bounced','Reversed','Failed') NOT NULL DEFAULT 'Cleared',
  `reconciled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `reconciled_at` TIMESTAMP NULL DEFAULT NULL,
  `reversal_of_id` INT UNSIGNED DEFAULT NULL,
  `collected_by` INT UNSIGNED DEFAULT NULL,
  `accounting_status` ENUM('Pending','Posted','Failed','NotRequired') NOT NULL DEFAULT 'Pending',
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_payment_receipt` (`receipt_no`),
  KEY `idx_tpt_payment_invoice` (`invoice_id`, `status`),
  KEY `idx_tpt_payment_student` (`student_id`, `payment_date`),
  CONSTRAINT `fk_tpt_payment_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_payment_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_payment_reversal` FOREIGN KEY (`reversal_of_id`) REFERENCES `tpt_transport_payment`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_payment_user` FOREIGN KEY (`collected_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Payment/receipt; reversals are new negative rows, never edits.';

CREATE TABLE IF NOT EXISTS `tpt_student_fee_detail` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_session_id` INT UNSIGNED NOT NULL,
  `tpt_plan_id` INT UNSIGNED DEFAULT NULL,
  `invoice_id` INT UNSIGNED DEFAULT NULL,
  `billing_month` DATE NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(10,2) NOT NULL,
  `due_date` DATE NOT NULL,
  `remark` VARCHAR(500) DEFAULT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'Pending',
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY `uq_tpt_fee_detail_month` (`student_session_id`, `billing_month`),
  KEY `idx_tpt_fee_detail_status` (`status`, `due_date`),
  CONSTRAINT `fk_tpt_fee_detail_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fee_detail_plan` FOREIGN KEY (`tpt_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_tpt_fee_detail_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='LEGACY-COMPAT: monthly fee record. New code uses tpt_transport_invoice.';

CREATE TABLE IF NOT EXISTS `tpt_student_fine_detail` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_fee_detail_id` INT UNSIGNED NOT NULL,
  `fine_master_id` INT UNSIGNED NOT NULL,
  `invoice_id` INT UNSIGNED DEFAULT NULL,
  `fine_days` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `fine_type` ENUM('Fixed','Percentage') NOT NULL DEFAULT 'Fixed',
  `fine_rate` DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `waived_fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Canonical spelling; legacy code used waved_fine_amount.',
  `net_fine_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `remark` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_fine_detail_fee` (`student_fee_detail_id`),
  CONSTRAINT `fk_tpt_fine_detail_fee` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fine_detail_rule` FOREIGN KEY (`fine_master_id`) REFERENCES `tpt_fine_master`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fine_detail_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='LEGACY-COMPAT: applied fine detail. New code uses tpt_transport_charge.';

CREATE TABLE IF NOT EXISTS `tpt_student_fee_collection` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_fee_detail_id` INT UNSIGNED NOT NULL,
  `invoice_id` INT UNSIGNED DEFAULT NULL,
  `payment_date` DATE NOT NULL,
  `total_delay_days` INT NOT NULL DEFAULT 0,
  `paid_amount` DECIMAL(12,2) NOT NULL,
  `payment_mode` VARCHAR(20) NOT NULL,
  `status` VARCHAR(20) NOT NULL,
  `reconciled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `remarks` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_tpt_fee_collection_fee` (`student_fee_detail_id`),
  CONSTRAINT `fk_tpt_fee_collection_fee` FOREIGN KEY (`student_fee_detail_id`) REFERENCES `tpt_student_fee_detail`(`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_tpt_fee_collection_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `tpt_transport_invoice`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='LEGACY-COMPAT: payment record. New code uses tpt_transport_payment.';

CREATE TABLE IF NOT EXISTS `std_student_pay_log` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `student_id` INT UNSIGNED NOT NULL,
  `academic_session_id` SMALLINT UNSIGNED NOT NULL,
  `module_name` VARCHAR(50) NOT NULL,
  `activity_type` VARCHAR(50) NOT NULL,
  `amount` DECIMAL(12,2) DEFAULT NULL,
  `log_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reference_id` INT UNSIGNED DEFAULT NULL,
  `reference_table` VARCHAR(100) DEFAULT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `triggered_by` INT UNSIGNED DEFAULT NULL,
  `is_system_generated` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  KEY `idx_payLog_student` (`student_id`),
  KEY `idx_payLog_module` (`module_name`),
  KEY `idx_payLog_date` (`log_date`),
  KEY `idx_payLog_reference` (`reference_table`, `reference_id`),
  CONSTRAINT `fk_payLog_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_payLog_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_payLog_user` FOREIGN KEY (`triggered_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Cross-module immutable payment audit log.';

CREATE TABLE IF NOT EXISTS `tpt_accounting_posting` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `source_table` VARCHAR(60) NOT NULL,
  `source_id` INT UNSIGNED NOT NULL,
  `module` VARCHAR(40) NOT NULL DEFAULT 'Transport',
  `voucher_type` ENUM('FeeReceipt','LateFee','Penalty','Refund','CreditNote','Fuel','Maintenance','VendorBill','Reversal') NOT NULL,
  `amount` DECIMAL(14,2) NOT NULL,
  `debit_ledger_id` INT UNSIGNED DEFAULT NULL,
  `credit_ledger_id` INT UNSIGNED DEFAULT NULL,
  `voucher_no` VARCHAR(60) DEFAULT NULL,
  `posting_date` DATE NOT NULL,
  `status` ENUM('Pending','Posted','Failed','Skipped') NOT NULL DEFAULT 'Pending',
  `error_text` TEXT DEFAULT NULL,
  `retry_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `posted_by` INT UNSIGNED DEFAULT NULL,
  `posted_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_tpt_acct_source` (`source_table`, `source_id`, `voucher_type`),
  KEY `idx_tpt_acct_status` (`status`, `posting_date`),
  CONSTRAINT `fk_tpt_acct_postedBy` FOREIGN KEY (`posted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Accounting outbox: idempotent posting with retry and visible failure.';

-- =======================================================================
-- SECTION G2 — NOTIFICATIONS AND GPS
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_notification_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_session_id` INT UNSIGNED DEFAULT NULL,
    `trip_id` INT UNSIGNED DEFAULT NULL,
    `stop_id` INT UNSIGNED DEFAULT NULL,
    `notification_type` ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled','Boarded','Unboarded','FeeDue','FeeOverdue','DocumentExpiry','Incident','PlanChange','Other') NOT NULL,
    `recipient_type` ENUM('Parent','Student','Driver','Helper','Staff','Admin') NOT NULL DEFAULT 'Parent',
    `recipient_id` INT UNSIGNED DEFAULT NULL,
    `template_code` VARCHAR(60) DEFAULT NULL,
    `sent_time` DATETIME DEFAULT NULL,
    `app_notification_status` ENUM('NotRegistered','Pending','Sent','Failed') DEFAULT NULL,
    `sms_notification_status` ENUM('NotRegistered','Pending','Sent','Failed') DEFAULT NULL,
    `email_notification_status` ENUM('NotRegistered','Pending','Sent','Failed') DEFAULT NULL,
    `whatsapp_notification_status` ENUM('NotRegistered','Pending','Sent','Failed') DEFAULT NULL,
    `provider_message_id` VARCHAR(120) DEFAULT NULL,
    `retry_count` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `error_text` VARCHAR(500) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_tpt_notification_student` (`student_session_id`, `created_at`),
    KEY `idx_tpt_notification_type` (`notification_type`, `created_at`),
    KEY `idx_tpt_notification_status` (`sms_notification_status`, `app_notification_status`),
    CONSTRAINT `fk_tpt_notification_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_notification_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_notification_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Parent/crew notification event with independent channel status; Notification owns delivery.';

CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL = vehicle moving outside a trip.',
    `vehicle_id` INT UNSIGNED NOT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `speed_kmph` DECIMAL(6,2) UNSIGNED DEFAULT NULL,
    `heading_deg` SMALLINT UNSIGNED DEFAULT NULL,
    `accuracy_m` SMALLINT UNSIGNED DEFAULT NULL,
    `source` ENUM('Device','DriverApp','Import') NOT NULL DEFAULT 'Device',
    `recorded_at` TIMESTAMP NOT NULL COMMENT 'Time on the device.',
    `received_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_gps_trip_time` (`trip_id`, `recorded_at`),
    KEY `idx_tpt_gps_vehicle_time` (`vehicle_id`, `recorded_at`),
    CONSTRAINT `fk_tpt_gps_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_gps_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='High-volume insert-only GPS point; retention job required.';

CREATE TABLE IF NOT EXISTS `tpt_gps_alerts` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED DEFAULT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `safety_rule_id` INT UNSIGNED DEFAULT NULL COMMENT 'Logical reference to ptr_safety_rules; no FK to keep layering clean.',
    `alert_type` VARCHAR(60) NOT NULL,
    `value` DECIMAL(10,2) DEFAULT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `recorded_at` TIMESTAMP NOT NULL,
    `acknowledged_by` INT UNSIGNED DEFAULT NULL,
    `acknowledged_at` TIMESTAMP NULL DEFAULT NULL,
    `status` ENUM('Open','Acknowledged','Resolved','Ignored') NOT NULL DEFAULT 'Open',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_tpt_gps_alert_vehicle` (`vehicle_id`, `recorded_at`),
    KEY `idx_tpt_gps_alert_open` (`status`, `recorded_at`),
    CONSTRAINT `fk_tpt_gps_alert_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_gps_alert_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tpt_gps_alert_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_gps_alert_user` FOREIGN KEY (`acknowledged_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Overspeed/harsh brake/deviation/panic/tamper alert.';

-- =======================================================================
-- SECTION H — PLAN STAGING (draft children; live tables untouched)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_plan_route` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `source_route_id` INT UNSIGNED DEFAULT NULL COMMENT 'Live route this replaces; NULL = brand new.',
    `change_kind` ENUM('Unchanged','Added','Changed','Removed') NOT NULL DEFAULT 'Unchanged',
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `shift_id` INT UNSIGNED NOT NULL,
    `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,
    `total_distance_km` DECIMAL(8,2) UNSIGNED DEFAULT NULL,
    `est_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
    `student_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `change_note` VARCHAR(500) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_plan_route_code` (`plan_id`, `code`),
    KEY `idx_tpt_plan_route_source` (`source_route_id`),
    CONSTRAINT `fk_tpt_plan_route_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_route_source` FOREIGN KEY (`source_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_route_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Draft route in a plan; every live route is copied as Unchanged.';

CREATE TABLE IF NOT EXISTS `tpt_plan_new_stop` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `generation_run_id` INT UNSIGNED DEFAULT NULL COMMENT 'FK ptr_stop_generation_runs when created by the stop generator.',
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `location` POINT SRID 4326 DEFAULT NULL,
    `reason` VARCHAR(500) DEFAULT NULL,
    `walk_radius_m` SMALLINT UNSIGNED DEFAULT NULL,
    `safety_flags` JSON DEFAULT NULL,
    `promoted_stop_id` INT UNSIGNED DEFAULT NULL COMMENT 'Live tpt_pickup_points id after publish.',
    `status` ENUM('Proposed','Accepted','Rejected','Promoted') NOT NULL DEFAULT 'Proposed',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_plan_new_stop_code` (`plan_id`, `code`),
    KEY `idx_tpt_plan_new_stop_promoted` (`promoted_stop_id`),
    CONSTRAINT `fk_tpt_plan_new_stop_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_new_stop_promoted` FOREIGN KEY (`promoted_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Stop the plan wants to create; promoted to a live stop at publish.';

CREATE TABLE IF NOT EXISTS `tpt_plan_route_stop` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_route_id` INT UNSIGNED NOT NULL,
    `stop_id` INT UNSIGNED DEFAULT NULL COMMENT 'Existing live stop.',
    `new_stop_id` INT UNSIGNED DEFAULT NULL COMMENT 'Proposed stop; exactly one of stop_id/new_stop_id is set.',
    `sequence` SMALLINT UNSIGNED NOT NULL,
    `pickup_time` TIME DEFAULT NULL,
    `drop_time` TIME DEFAULT NULL,
    `distance_from_school_km` DECIMAL(7,2) UNSIGNED DEFAULT NULL,
    `walk_distance_m` SMALLINT UNSIGNED DEFAULT NULL,
    `change_kind` ENUM('Unchanged','Added','Changed','Removed') NOT NULL DEFAULT 'Unchanged',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_plan_route_stop_seq` (`plan_route_id`, `sequence`),
    KEY `idx_tpt_plan_route_stop_stop` (`stop_id`),
    KEY `idx_tpt_plan_route_stop_new` (`new_stop_id`),
    CONSTRAINT `fk_tpt_plan_route_stop_route` FOREIGN KEY (`plan_route_id`) REFERENCES `tpt_plan_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_route_stop_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tpt_plan_route_stop_new` FOREIGN KEY (`new_stop_id`) REFERENCES `tpt_plan_new_stop`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ordered stop in a draft route; supports existing and proposed stops.';

CREATE TABLE IF NOT EXISTS `tpt_plan_allocation` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `student_session_id` INT UNSIGNED NOT NULL,
    `source_allocation_id` INT UNSIGNED DEFAULT NULL COMMENT 'Live allocation this replaces; NULL = new rider.',
    `pickup_plan_route_id` INT UNSIGNED DEFAULT NULL,
    `pickup_route_stop_id` INT UNSIGNED DEFAULT NULL,
    `drop_plan_route_id` INT UNSIGNED DEFAULT NULL,
    `drop_route_stop_id` INT UNSIGNED DEFAULT NULL,
    `transport_use_type` ENUM('Pickup','Drop','Both') NOT NULL,
    `fare` DECIMAL(10,2) DEFAULT NULL,
    `walk_distance_m` SMALLINT UNSIGNED DEFAULT NULL,
    `ride_minutes` SMALLINT UNSIGNED DEFAULT NULL,
    `change_kind` ENUM('Unchanged','Added','Changed','Removed') NOT NULL DEFAULT 'Unchanged',
    `status` ENUM('Planned','Unserved','Excluded') NOT NULL DEFAULT 'Planned',
    `unserved_reason` VARCHAR(200) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_plan_alloc_student` (`plan_id`, `student_id`),
    KEY `idx_tpt_plan_alloc_source` (`source_allocation_id`),
    KEY `idx_tpt_plan_alloc_pickup` (`pickup_plan_route_id`),
    KEY `idx_tpt_plan_alloc_drop` (`drop_plan_route_id`),
    CONSTRAINT `fk_tpt_plan_alloc_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_alloc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_alloc_session` FOREIGN KEY (`student_session_id`) REFERENCES `std_student_academic_sessions`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_alloc_source` FOREIGN KEY (`source_allocation_id`) REFERENCES `tpt_student_route_allocation_jnt`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_alloc_pickupRoute` FOREIGN KEY (`pickup_plan_route_id`) REFERENCES `tpt_plan_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_alloc_pickupStop` FOREIGN KEY (`pickup_route_stop_id`) REFERENCES `tpt_plan_route_stop`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_alloc_dropRoute` FOREIGN KEY (`drop_plan_route_id`) REFERENCES `tpt_plan_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_alloc_dropStop` FOREIGN KEY (`drop_route_stop_id`) REFERENCES `tpt_plan_route_stop`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One row per planned student; unserved students are explicit, never silently dropped.';

CREATE TABLE IF NOT EXISTS `tpt_plan_vehicle_assignment` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `plan_route_id` INT UNSIGNED NOT NULL,
    `shift_id` INT UNSIGNED NOT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL DEFAULT 'Pickup',
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `seats_used` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `effective_from` DATE DEFAULT NULL,
    `change_kind` ENUM('Unchanged','Added','Changed','Removed') NOT NULL DEFAULT 'Unchanged',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_plan_vehicle_route` (`plan_route_id`, `shift_id`, `pickup_drop`),
    CONSTRAINT `fk_tpt_plan_vehicle_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_vehicle_route` FOREIGN KEY (`plan_route_id`) REFERENCES `tpt_plan_route`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_vehicle_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tpt_plan_vehicle_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_vehicle_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_vehicle_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Planned bus/crew per route; becomes a live assignment at publish.';

CREATE TABLE IF NOT EXISTS `tpt_plan_lock` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `lock_type` ENUM('Route','Stop','Student','Vehicle','Driver') NOT NULL,
    `target_id` INT UNSIGNED NOT NULL COMMENT 'Polymorphic live id; no FK by design.',
    `reason` VARCHAR(500) DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_plan_lock_target` (`plan_id`, `lock_type`, `target_id`),
    CONSTRAINT `fk_tpt_plan_lock_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_lock_user` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pins the engine must not move when regenerating.';

CREATE TABLE IF NOT EXISTS `tpt_plan_review` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `plan_route_id` INT UNSIGNED DEFAULT NULL COMMENT 'NULL = decision on the whole plan.',
    `step` ENUM('Submit','Review','Approve','Reject','Schedule','Publish','Rollback','Cancel','Restore','Archive','Comment') NOT NULL,
    `decision` ENUM('Approved','Rejected','ChangesRequested','Noted') DEFAULT NULL,
    `comment` VARCHAR(1000) DEFAULT NULL,
    `reviewer_id` INT UNSIGNED DEFAULT NULL,
    `decided_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_plan_review_plan` (`plan_id`, `decided_at`),
    CONSTRAINT `fk_tpt_plan_review_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_plan_review_route` FOREIGN KEY (`plan_route_id`) REFERENCES `tpt_plan_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_review_user` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Append-only audit trail of every plan lifecycle step.';

CREATE TABLE IF NOT EXISTS `tpt_plan_snapshot` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED DEFAULT NULL,
    `plan_publication_id` INT UNSIGNED DEFAULT NULL,
    `kind` ENUM('BeforePublish','AfterPublish','BeforeRollback','Manual','Roster') NOT NULL,
    `scope_json` JSON DEFAULT NULL,
    `payload_json` LONGTEXT NOT NULL COMMENT 'Self-contained copy; no FK to the live rows it holds.',
    `checksum` CHAR(64) NOT NULL,
    `row_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `taken_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `taken_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_plan_snapshot_plan` (`plan_id`, `kind`),
    KEY `idx_tpt_plan_snapshot_pub` (`plan_publication_id`, `kind`),
    CONSTRAINT `fk_tpt_plan_snapshot_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_snapshot_pub` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_plan_snapshot_user` FOREIGN KEY (`taken_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Rollback source; survives deletion of the live rows it copied.';

CREATE TABLE IF NOT EXISTS `tpt_plan_comparison` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `baseline_plan_id` INT UNSIGNED DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `compared_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `notes` VARCHAR(1000) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_tpt_comparison_code` (`code`),
    CONSTRAINT `fk_tpt_comparison_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tpt_comparison_baseline` FOREIGN KEY (`baseline_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_comparison_user` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Saved comparison of two or more plans.';

CREATE TABLE IF NOT EXISTS `tpt_plan_comparison_item` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `comparison_id` INT UNSIGNED NOT NULL,
    `plan_id` INT UNSIGNED NOT NULL,
    `plan_source` ENUM('Draft','Live') NOT NULL DEFAULT 'Draft',
    `label` VARCHAR(100) DEFAULT NULL,
    `metrics_json` JSON NOT NULL COMMENT 'students, routes, stops, buses, km, cost, income, margin, ride, walk, safety, unserved.',
    `rank` SMALLINT UNSIGNED DEFAULT NULL,
    `is_selected` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_tpt_comparison_item` (`comparison_id`, `plan_id`),
    CONSTRAINT `fk_tpt_comparison_item_header` FOREIGN KEY (`comparison_id`) REFERENCES `tpt_plan_comparison`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_comparison_item_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One plan inside a saved comparison, with its metric snapshot.';

-- =======================================================================
-- SECTION I — HISTORY (immutable archive of replaced plans)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_route_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_publication_id` INT UNSIGNED NOT NULL,
    `original_route_id` INT UNSIGNED NOT NULL,
    `plan_id` INT UNSIGNED DEFAULT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_geometry` LINESTRING SRID 4326 DEFAULT NULL,
    `total_distance_km` DECIMAL(8,2) UNSIGNED DEFAULT NULL,
    `est_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
    `est_exp_per_km` DECIMAL(10,2) UNSIGNED DEFAULT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `change_kind` ENUM('Unchanged','Added','Changed','Removed') DEFAULT NULL,
    `archived_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `archive_reason` VARCHAR(200) DEFAULT NULL,
    `snapshot_json` JSON DEFAULT NULL,
    KEY `idx_tpt_route_hist_pub` (`plan_publication_id`),
    KEY `idx_tpt_route_hist_original` (`original_route_id`),
    CONSTRAINT `fk_tpt_route_hist_pub` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_tpt_route_hist_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Archived route; survives deletion of the live route.';

CREATE TABLE IF NOT EXISTS `tpt_pickup_point_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_publication_id` INT UNSIGNED NOT NULL,
    `original_stop_id` INT UNSIGNED NOT NULL,
    `code` VARCHAR(50) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `geocode_status` VARCHAR(20) DEFAULT NULL,
    `stop_type` ENUM('Pickup','Drop','Both') DEFAULT NULL,
    `safety_flags` JSON DEFAULT NULL,
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `archived_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `archive_reason` VARCHAR(200) DEFAULT NULL,
    `snapshot_json` JSON DEFAULT NULL,
    KEY `idx_tpt_stop_hist_pub` (`plan_publication_id`),
    KEY `idx_tpt_stop_hist_original` (`original_stop_id`),
    CONSTRAINT `fk_tpt_stop_hist_pub` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Archived stop master copy.';

CREATE TABLE IF NOT EXISTS `tpt_pickup_point_route_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_publication_id` INT UNSIGNED NOT NULL,
    `original_jnt_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `pickup_point_id` INT UNSIGNED NOT NULL,
    `ordinal` SMALLINT UNSIGNED NOT NULL,
    `arrival_time` INT DEFAULT NULL,
    `departure_time` INT DEFAULT NULL,
    `pickup_drop_fare` DECIMAL(10,2) DEFAULT NULL,
    `both_side_fare` DECIMAL(10,2) DEFAULT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `archived_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_route_stop_hist_pub` (`plan_publication_id`),
    KEY `idx_tpt_route_stop_hist_route` (`route_id`, `ordinal`),
    CONSTRAINT `fk_tpt_route_stop_hist_pub` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Archived route-stop link, including the fare in force.';

CREATE TABLE IF NOT EXISTS `tpt_student_route_allocation_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_publication_id` INT UNSIGNED NOT NULL,
    `original_allocation_id` INT UNSIGNED NOT NULL,
    `student_id` INT UNSIGNED NOT NULL,
    `student_session_id` INT UNSIGNED NOT NULL,
    `plan_id` INT UNSIGNED DEFAULT NULL,
    `transport_use_type` ENUM('Pickup','Drop','Both') NOT NULL,
    `pickup_route_id` INT UNSIGNED DEFAULT NULL,
    `pickup_stop_id` INT UNSIGNED DEFAULT NULL,
    `drop_route_id` INT UNSIGNED DEFAULT NULL,
    `drop_stop_id` INT UNSIGNED DEFAULT NULL,
    `fare` DECIMAL(10,2) DEFAULT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `billing_locked` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '1 = invoices already exist for this period.',
    `archived_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `archive_reason` VARCHAR(200) DEFAULT NULL,
    KEY `idx_tpt_alloc_hist_pub` (`plan_publication_id`),
    KEY `idx_tpt_alloc_hist_student` (`student_id`, `effective_from`),
    KEY `idx_tpt_alloc_hist_original` (`original_allocation_id`),
    CONSTRAINT `fk_tpt_alloc_hist_pub` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Archived allocation with fare; the key to explaining any historical invoice.';

CREATE TABLE IF NOT EXISTS `tpt_driver_route_vehicle_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_publication_id` INT UNSIGNED NOT NULL,
    `original_assignment_id` INT UNSIGNED NOT NULL,
    `shift_id` INT UNSIGNED NOT NULL,
    `route_id` INT UNSIGNED NOT NULL,
    `vehicle_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED NOT NULL,
    `helper_id` INT UNSIGNED DEFAULT NULL,
    `pickup_drop` ENUM('Pickup','Drop') NOT NULL,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE DEFAULT NULL,
    `archived_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_assign_hist_pub` (`plan_publication_id`),
    KEY `idx_tpt_assign_hist_route` (`route_id`, `effective_from`),
    CONSTRAINT `fk_tpt_assign_hist_pub` FOREIGN KEY (`plan_publication_id`) REFERENCES `tpt_plan_publication`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Archived driver/vehicle assignment.';

CREATE TABLE IF NOT EXISTS `tpt_transport_plan_history` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `version` SMALLINT UNSIGNED NOT NULL,
    `status` VARCHAR(30) NOT NULL,
    `plan_type_id` TINYINT UNSIGNED DEFAULT NULL,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `effective_from` DATE DEFAULT NULL,
    `effective_to` DATE DEFAULT NULL,
    `kpi_json` JSON DEFAULT NULL,
    `published_at` TIMESTAMP NULL DEFAULT NULL,
    `published_by` INT UNSIGNED DEFAULT NULL,
    `archived_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `archive_reason` VARCHAR(200) DEFAULT NULL,
    `snapshot_json` JSON DEFAULT NULL,
    KEY `idx_tpt_plan_hist_plan` (`plan_id`, `version`),
    KEY `idx_tpt_plan_hist_session` (`academic_session_id`, `effective_from`),
    CONSTRAINT `fk_tpt_plan_hist_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Versioned plan header archive; immutable.';

-- =======================================================================
-- SECTION J — STANDARD ADVISOR (rule-based, no AI generation)
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_adv_rule_settings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_code` VARCHAR(60) NOT NULL,
    `family` VARCHAR(40) NOT NULL COMMENT 'compliance/capacity/cost/fees/punctuality/fuel/crew/safety/comms.',
    `is_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `severity` ENUM('Info','Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `params_json` JSON DEFAULT NULL,
    `is_system` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_tpt_adv_rule_code` (`rule_code`),
    KEY `idx_tpt_adv_rule_family` (`family`, `is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-school Advisor thresholds; replaces hard-coded constants.';

CREATE TABLE IF NOT EXISTS `tpt_adv_runs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trigger` ENUM('Scheduled','Manual','Event') NOT NULL DEFAULT 'Scheduled',
    `status` ENUM('Queued','Running','Succeeded','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
    `scope_json` JSON DEFAULT NULL,
    `rules_run` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `suggestion_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `error_text` TEXT DEFAULT NULL,
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `finished_at` TIMESTAMP NULL DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_tpt_adv_run_status` (`status`, `created_at`),
    CONSTRAINT `fk_tpt_adv_run_user` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One Advisor execution; page reads stored suggestions.';

CREATE TABLE IF NOT EXISTS `tpt_adv_suggestions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `advisor_run_id` INT UNSIGNED NOT NULL,
    `rule_code` VARCHAR(60) NOT NULL,
    `family` VARCHAR(40) NOT NULL,
    `category` ENUM('Safety','Saving','Income','Service','Maintenance','Compliance','Modernization','Operations') NOT NULL,
    `severity` ENUM('Info','Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `target_type` ENUM('Route','Stop','Vehicle','Driver','Student','Fee','Network','Plan') NOT NULL,
    `target_id` INT UNSIGNED DEFAULT NULL COMMENT 'Polymorphic live id; no FK by design.',
    `title` VARCHAR(250) NOT NULL,
    `problem_text` VARCHAR(1000) DEFAULT NULL,
    `action_text` VARCHAR(1000) DEFAULT NULL,
    `benefit_text` VARCHAR(500) DEFAULT NULL,
    `benefit_amount` DECIMAL(14,2) DEFAULT NULL,
    `benefit_unit` VARCHAR(20) DEFAULT NULL COMMENT 'rupees/minutes/days/students/buses/km/percent/none.',
    `calculation_json` JSON DEFAULT NULL,
    `impact_json` JSON DEFAULT NULL,
    `dedupe_key` CHAR(64) NOT NULL,
    `status` ENUM('Open','Accepted','Dismissed','Snoozed','Resolved','Expired') NOT NULL DEFAULT 'Open',
    `owner_id` INT UNSIGNED DEFAULT NULL,
    `due_date` DATE DEFAULT NULL,
    `snoozed_until` DATE DEFAULT NULL,
    `action_plan_id` INT UNSIGNED DEFAULT NULL COMMENT 'Draft plan created from this advice (Prime).',
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_tpt_adv_sug_status` (`status`, `severity`, `created_at`),
    KEY `idx_tpt_adv_sug_dedupe` (`dedupe_key`, `status`),
    KEY `idx_tpt_adv_sug_target` (`target_type`, `target_id`),
    CONSTRAINT `fk_tpt_adv_sug_run` FOREIGN KEY (`advisor_run_id`) REFERENCES `tpt_adv_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_adv_sug_plan` FOREIGN KEY (`action_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_adv_sug_owner` FOREIGN KEY (`owner_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Persisted Advisor suggestion with calculation trace and lifecycle.';

CREATE TABLE IF NOT EXISTS `tpt_adv_suggestion_outcomes` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `suggestion_id` BIGINT UNSIGNED NOT NULL,
    `decision` ENUM('Accepted','Dismissed','Snoozed') NOT NULL,
    `reason` VARCHAR(500) DEFAULT NULL,
    `action_plan_id` INT UNSIGNED DEFAULT NULL,
    `baseline_json` JSON DEFAULT NULL,
    `measured_json` JSON DEFAULT NULL,
    `predicted_saving` DECIMAL(14,2) DEFAULT NULL,
    `actual_saving` DECIMAL(14,2) DEFAULT NULL,
    `confidence` ENUM('High','Medium','Low') DEFAULT NULL,
    `decided_by` INT UNSIGNED DEFAULT NULL,
    `decided_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `measured_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_adv_outcome_sug` (`suggestion_id`, `decided_at`),
    CONSTRAINT `fk_tpt_adv_outcome_sug` FOREIGN KEY (`suggestion_id`) REFERENCES `tpt_adv_suggestions`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_tpt_adv_outcome_plan` FOREIGN KEY (`action_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_adv_outcome_user` FOREIGN KEY (`decided_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Decision and measured outcome for a suggestion.';

CREATE TABLE IF NOT EXISTS `tpt_adv_savings_ledger` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `suggestion_id` BIGINT UNSIGNED DEFAULT NULL,
    `plan_id` INT UNSIGNED DEFAULT NULL,
    `period_start` DATE NOT NULL,
    `period_end` DATE NOT NULL,
    `baseline_cost` DECIMAL(14,2) DEFAULT NULL,
    `actual_cost` DECIMAL(14,2) DEFAULT NULL,
    `saving_amount` DECIMAL(14,2) DEFAULT NULL,
    `confidence` ENUM('High','Medium','Low') DEFAULT NULL,
    `measured_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `notes` VARCHAR(1000) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_ledger_period` (`period_start`, `period_end`),
    CONSTRAINT `fk_tpt_ledger_sug` FOREIGN KEY (`suggestion_id`) REFERENCES `tpt_adv_suggestions`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_tpt_ledger_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Measured savings ledger; predicted and actual are separate.';

-- =======================================================================
-- SECTION K — PRIME INTELLIGENCE
-- =======================================================================

CREATE TABLE IF NOT EXISTS `ptr_settings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `group_name` VARCHAR(50) NOT NULL DEFAULT 'general' COMMENT 'engine/advisor/ops/safety/maps/billing/pnl/geo.',
    `setting_key` VARCHAR(100) NOT NULL,
    `value_json` JSON NOT NULL,
    `description` VARCHAR(500) DEFAULT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_ptr_settings_key` (`setting_key`),
    KEY `idx_ptr_settings_group` (`group_name`, `is_active`),
    CONSTRAINT `fk_ptr_settings_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_settings_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Typed per-school engine/ops/billing settings; cache key must carry tenant id.';

CREATE TABLE IF NOT EXISTS `ptr_rule_settings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `rule_code` VARCHAR(60) NOT NULL,
    `family` VARCHAR(40) NOT NULL,
    `is_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `severity` ENUM('Info','Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `params_json` JSON DEFAULT NULL,
    `is_system` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_ptr_rule_code` (`rule_code`),
    KEY `idx_ptr_rule_family` (`family`, `is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Prime engine/advisor rule switches and thresholds (distinct from Standard tpt_adv_rule_settings).';

CREATE TABLE IF NOT EXISTS `ptr_distance_matrix` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `from_point_type` ENUM('School','Stop','NewStop','Student') NOT NULL,
    `from_point_id` INT UNSIGNED NOT NULL,
    `to_point_type` ENUM('School','Stop','NewStop','Student') NOT NULL,
    `to_point_id` INT UNSIGNED NOT NULL,
    `distance_m` INT UNSIGNED NOT NULL,
    `duration_s` INT UNSIGNED NOT NULL,
    `source` ENUM('OSRM','Haversine','Manual') NOT NULL DEFAULT 'OSRM',
    `computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ptr_dist_pair` (`from_point_type`, `from_point_id`, `to_point_type`, `to_point_id`),
    KEY `idx_ptr_dist_to` (`to_point_type`, `to_point_id`),
    KEY `idx_ptr_dist_source` (`source`, `computed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Cached distance/time matrix; rebuildable, polymorphic ids, no FKs.';

CREATE TABLE IF NOT EXISTS `ptr_segment_speeds` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `from_stop_id` INT UNSIGNED NOT NULL,
    `to_stop_id` INT UNSIGNED NOT NULL,
    `shift_id` INT UNSIGNED DEFAULT NULL,
    `time_band` VARCHAR(20) NOT NULL DEFAULT 'all',
    `avg_speed_kmph` DECIMAL(6,2) UNSIGNED NOT NULL,
    `avg_duration_s` INT UNSIGNED NOT NULL,
    `sample_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `last_sampled_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ptr_seg_speed` (`from_stop_id`, `to_stop_id`, `shift_id`, `time_band`),
    CONSTRAINT `fk_ptr_seg_speed_from` FOREIGN KEY (`from_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ptr_seg_speed_to` FOREIGN KEY (`to_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ptr_seg_speed_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Learned speed per stop pair, shift and time band.';

CREATE TABLE IF NOT EXISTS `ptr_student_geo` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `student_id` INT UNSIGNED NOT NULL,
    `latitude` DECIMAL(10,7) DEFAULT NULL,
    `longitude` DECIMAL(10,7) DEFAULT NULL,
    `address_text` VARCHAR(500) DEFAULT NULL,
    `drop_latitude` DECIMAL(10,7) DEFAULT NULL,
    `drop_longitude` DECIMAL(10,7) DEFAULT NULL,
    `drop_address_text` VARCHAR(500) DEFAULT NULL,
    `geocode_source` ENUM('Nominatim','PinDrop','ParentApp','Manual','Generated') NOT NULL DEFAULT 'Manual',
    `geocode_status` ENUM('Pending','Verified','Failed') NOT NULL DEFAULT 'Pending',
    `geocode_accuracy_m` INT UNSIGNED DEFAULT NULL,
    `consent_given` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `consent_at` TIMESTAMP NULL DEFAULT NULL,
    `consent_by` INT UNSIGNED DEFAULT NULL,
    `verified_at` TIMESTAMP NULL DEFAULT NULL,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `updated_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_ptr_student_geo` (`student_id`),
    KEY `idx_ptr_student_geo_point` (`latitude`, `longitude`),
    CONSTRAINT `fk_ptr_student_geo_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ptr_student_geo_consentBy` FOREIGN KEY (`consent_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student home/drop point with consent. Sensitive personal data.';

CREATE TABLE IF NOT EXISTS `ptr_engine_runs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED DEFAULT NULL,
    `run_type` ENUM('FullPlan','Repair','WhatIf','AdmissionQuote','StopGeneration') NOT NULL DEFAULT 'FullPlan',
    `status` ENUM('Queued','Running','Succeeded','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
    `progress_pct` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `stage` VARCHAR(100) DEFAULT NULL,
    `input_json` JSON DEFAULT NULL,
    `output_json` JSON DEFAULT NULL,
    `error_text` TEXT DEFAULT NULL,
    `solver_version` VARCHAR(50) DEFAULT NULL,
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `finished_at` TIMESTAMP NULL DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_ptr_run_status` (`status`, `created_at`),
    KEY `idx_ptr_run_plan` (`plan_id`),
    CONSTRAINT `fk_ptr_run_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_run_user` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One engine run; UI polls progress; newer run supersedes older.';

CREATE TABLE IF NOT EXISTS `ptr_stop_generation_runs` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `academic_session_id` SMALLINT UNSIGNED NOT NULL,
    `plan_id` INT UNSIGNED DEFAULT NULL,
    `run_type` ENUM('FromStudentGeo','FromExistingStops','Refresh') NOT NULL DEFAULT 'FromStudentGeo',
    `status` ENUM('Queued','Running','Succeeded','Failed','Cancelled') NOT NULL DEFAULT 'Queued',
    `params_json` JSON DEFAULT NULL,
    `input_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `cluster_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `generated_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `output_json` JSON DEFAULT NULL,
    `error_text` TEXT DEFAULT NULL,
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `finished_at` TIMESTAMP NULL DEFAULT NULL,
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_ptr_stopgen_status` (`status`, `created_at`),
    CONSTRAINT `fk_ptr_stopgen_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_ptr_stopgen_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_stopgen_user` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One automatic stop-generation run.';

CREATE TABLE IF NOT EXISTS `ptr_stop_generation_candidate` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `run_id` INT UNSIGNED NOT NULL,
    `cluster_key` VARCHAR(60) DEFAULT NULL,
    `proposed_code` VARCHAR(50) NOT NULL,
    `proposed_name` VARCHAR(200) NOT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `location` POINT SRID 4326 DEFAULT NULL,
    `student_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `centroid_latitude` DECIMAL(10,7) DEFAULT NULL,
    `centroid_longitude` DECIMAL(10,7) DEFAULT NULL,
    `radius_m` SMALLINT UNSIGNED DEFAULT NULL,
    `max_walk_m` SMALLINT UNSIGNED DEFAULT NULL,
    `nearest_stop_id` INT UNSIGNED DEFAULT NULL,
    `nearest_walk_m` SMALLINT UNSIGNED DEFAULT NULL,
    `safety_flags` JSON DEFAULT NULL,
    `decision` ENUM('Proposed','Accepted','Rejected','Merged','Promoted') NOT NULL DEFAULT 'Proposed',
    `promoted_stop_id` INT UNSIGNED DEFAULT NULL,
    `plan_new_stop_id` INT UNSIGNED DEFAULT NULL,
    `reason` VARCHAR(500) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ptr_stopgen_candidate` (`run_id`, `proposed_code`),
    KEY `idx_ptr_stopgen_decision` (`decision`),
    CONSTRAINT `fk_ptr_stopgen_cand_run` FOREIGN KEY (`run_id`) REFERENCES `ptr_stop_generation_runs`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ptr_stopgen_cand_nearest` FOREIGN KEY (`nearest_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_stopgen_cand_promoted` FOREIGN KEY (`promoted_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_stopgen_cand_planstop` FOREIGN KEY (`plan_new_stop_id`) REFERENCES `tpt_plan_new_stop`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Proposed stop from lat/lng clustering with walk, safety and decision.';

CREATE TABLE IF NOT EXISTS `ptr_plan_constraint` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `plan_id` INT UNSIGNED NOT NULL,
    `constraint_code` VARCHAR(60) NOT NULL,
    `scope_type` ENUM('Plan','Class','Route','Student') NOT NULL DEFAULT 'Plan',
    `scope_id` INT UNSIGNED DEFAULT NULL,
    `value_json` JSON NOT NULL,
    `is_hard` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `priority` SMALLINT UNSIGNED NOT NULL DEFAULT 100,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ptr_plan_constraint` (`plan_id`, `constraint_code`, `scope_type`, `scope_id`),
    CONSTRAINT `fk_ptr_plan_constraint_plan` FOREIGN KEY (`plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-plan hard/soft constraint used by the solver; mirrors tpt_transport_plan_rule for Prime-specific keys.';

CREATE TABLE IF NOT EXISTS `ptr_eta_live` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `trip_id` INT UNSIGNED NOT NULL,
    `stop_id` INT UNSIGNED NOT NULL,
    `scheduled_at` TIME DEFAULT NULL,
    `eta_at` TIMESTAMP NULL DEFAULT NULL,
    `delay_s` INT DEFAULT NULL COMMENT 'Negative = early.',
    `status` ENUM('Pending','Arrived','Skipped') NOT NULL DEFAULT 'Pending',
    `computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ptr_eta_trip_stop` (`trip_id`, `stop_id`),
    CONSTRAINT `fk_ptr_eta_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ptr_eta_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Transient live ETA per trip/stop; upserted on GPS/stop events.';

CREATE TABLE IF NOT EXISTS `ptr_disruptions` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `type` ENUM('VehicleBreakdown','DriverAbsent','RoadClosed','Weather','Event','Other') NOT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `starts_at` TIMESTAMP NOT NULL,
    `ends_at` TIMESTAMP NULL DEFAULT NULL,
    `description` VARCHAR(1000) DEFAULT NULL,
    `options_json` JSON DEFAULT NULL,
    `chosen_option_json` JSON DEFAULT NULL,
    `scheduler_row_ids_json` JSON DEFAULT NULL,
    `resolution_plan_id` INT UNSIGNED DEFAULT NULL,
    `parents_notified_at` TIMESTAMP NULL DEFAULT NULL,
    `status` ENUM('Open','Applied','Resolved','Cancelled') NOT NULL DEFAULT 'Open',
    `created_by` INT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    KEY `idx_ptr_disruption_window` (`status`, `starts_at`),
    CONSTRAINT `fk_ptr_disruption_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_disruption_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_disruption_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_disruption_plan` FOREIGN KEY (`resolution_plan_id`) REFERENCES `tpt_transport_plan`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_disruption_user` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Breakdown/absence/closure with ranked options and a date-only override.';

CREATE TABLE IF NOT EXISTS `ptr_admission_quotes` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `enquiry_ref` VARCHAR(100) DEFAULT NULL,
    `latitude` DECIMAL(10,7) NOT NULL,
    `longitude` DECIMAL(10,7) NOT NULL,
    `address_text` VARCHAR(500) DEFAULT NULL,
    `nearest_stop_id` INT UNSIGNED DEFAULT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
    `walk_distance_m` SMALLINT UNSIGNED DEFAULT NULL,
    `seat_available` TINYINT(1) UNSIGNED DEFAULT NULL,
    `fare_quote` DECIMAL(10,2) UNSIGNED DEFAULT NULL,
    `result_json` JSON DEFAULT NULL,
    `quoted_by` INT UNSIGNED DEFAULT NULL,
    `quoted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY `idx_ptr_quote_enquiry` (`enquiry_ref`),
    CONSTRAINT `fk_ptr_quote_stop` FOREIGN KEY (`nearest_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_quote_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_quote_user` FOREIGN KEY (`quoted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pre-admission transport quote: nearest stop, walk, seats, fare.';

CREATE TABLE IF NOT EXISTS `ptr_safety_rules` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(60) NOT NULL,
    `name` VARCHAR(200) NOT NULL,
    `threshold_json` JSON NOT NULL,
    `severity` ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
    `score_penalty` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `is_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `is_system` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    UNIQUE KEY `uq_ptr_safety_rule_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Overspeed/harsh brake/deviation/attendant rule catalogue.';

CREATE TABLE IF NOT EXISTS `ptr_safety_scores` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `score_type` ENUM('Driver','Vehicle','Route') NOT NULL DEFAULT 'Driver',
    `entity_id` INT UNSIGNED NOT NULL,
    `driver_id` INT UNSIGNED DEFAULT NULL,
    `vehicle_id` INT UNSIGNED DEFAULT NULL,
    `route_id` INT UNSIGNED DEFAULT NULL,
    `period_type` ENUM('Day','Week','Month') NOT NULL DEFAULT 'Week',
    `period_start` DATE NOT NULL,
    `score` DECIMAL(5,2) UNSIGNED NOT NULL,
    `trips_counted` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `km_counted` DECIMAL(9,2) UNSIGNED NOT NULL DEFAULT 0.00,
    `breakdown_json` JSON DEFAULT NULL,
    `computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_ptr_safety_score` (`score_type`, `entity_id`, `period_type`, `period_start`),
    CONSTRAINT `fk_ptr_safety_score_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_safety_score_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_ptr_safety_score_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Driver/vehicle/route safety score per period with component breakdown.';

-- =======================================================================
-- SECTION L — INTEGRATION OUTBOX
-- =======================================================================

CREATE TABLE IF NOT EXISTS `tpt_domain_event_outbox` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `event_type` VARCHAR(80) NOT NULL COMMENT 'TripStarted, StopReached, PlanPublished, AllocationChanged, ...',
    `aggregate_type` VARCHAR(60) NOT NULL,
    `aggregate_id` INT UNSIGNED NOT NULL,
    `payload_json` JSON NOT NULL,
    `status` ENUM('Pending','Processing','Processed','Failed','Dead') NOT NULL DEFAULT 'Pending',
    `attempts` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `available_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `processed_at` TIMESTAMP NULL DEFAULT NULL,
    `error_text` TEXT DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_tpt_outbox_status` (`status`, `available_at`),
    KEY `idx_tpt_outbox_aggregate` (`aggregate_type`, `aggregate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Reliable domain-event delivery to Notification, Accounting, ParentPortal.';

-- =======================================================================
-- SECTION M — CURRENT-VIEW HELPERS
-- =======================================================================

CREATE OR REPLACE VIEW `v_tpt_current_plan` AS
SELECT p.*
FROM `tpt_transport_plan` p
WHERE p.`status` = 'Published'
  AND p.`is_active` = 1
  AND p.`deleted_at` IS NULL
  AND (p.`effective_from` IS NULL OR p.`effective_from` <= CURDATE())
  AND (p.`effective_to` IS NULL OR p.`effective_to` >= CURDATE());

CREATE OR REPLACE VIEW `v_tpt_current_route` AS
SELECT r.*
FROM `tpt_route` r
JOIN `v_tpt_current_plan` p ON p.`id` = r.`tpt_plan_id`
WHERE r.`status` = 'Active'
  AND r.`is_active` = 1
  AND r.`deleted_at` IS NULL;

CREATE OR REPLACE VIEW `v_tpt_current_student_allocation` AS
SELECT a.*
FROM `tpt_student_route_allocation_jnt` a
JOIN `v_tpt_current_plan` p ON p.`id` = a.`tpt_plan_id`
WHERE a.`active_status` = 1
  AND a.`deleted_at` IS NULL
  AND a.`effective_from` <= CURDATE()
  AND (a.`effective_to` IS NULL OR a.`effective_to` >= CURDATE());

-- =======================================================================
-- OPTIONAL — OVERLAP TRIGGER (run separately; application validation is mandatory)
-- =======================================================================
-- MySQL clients differ in DELIMITER support, so this block is commented.
-- Enable it in environments where the mysql CLI (or an equivalent) is used:
--
-- DELIMITER $$
-- CREATE TRIGGER `trg_tpt_assign_overlap`
-- BEFORE INSERT ON `tpt_driver_route_vehicle_jnt`
-- FOR EACH ROW
-- BEGIN
--     IF EXISTS (
--         SELECT 1 FROM `tpt_driver_route_vehicle_jnt` a
--         WHERE a.`deleted_at` IS NULL
--           AND a.`is_active` = 1
--           AND a.`shift_id` = NEW.`shift_id`
--           AND a.`route_id` = NEW.`route_id`
--           AND a.`vehicle_id` = NEW.`vehicle_id`
--           AND a.`driver_id` = NEW.`driver_id`
--           AND (
--                 (NEW.`effective_to` IS NULL AND (a.`effective_to` IS NULL OR a.`effective_to` >= NEW.`effective_from`))
--              OR (NEW.`effective_to` IS NOT NULL AND a.`effective_from` <= NEW.`effective_to` AND a.`effective_to` >= NEW.`effective_from`)
--              OR (NEW.`effective_to` IS NOT NULL AND a.`effective_to` IS NULL)
--           )
--     ) THEN
--         SIGNAL SQLSTATE '45000'
--             SET MESSAGE_TEXT = 'Overlapping assignment for the same shift, route, vehicle and driver.';
--     END IF;
-- END$$
-- DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;

-- =======================================================================
-- END OF SCHEMA
-- =======================================================================
