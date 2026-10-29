-- =======================================================================
-- PRIME TRANSPORT MODULE v1.0 for MySQL 8.x            (created 2026-10-23)
-- Table prefix: ptr_  (plus two tpt_ GPS tables owned by Transport)
-- Lives beside: Transport_DDL_v2.4.sql  (that file is NOT changed)
-- =======================================================================
--
-- WHY THIS FILE EXISTS
-- --------------------
-- PrimeTransport (Modules/PrimeTransport) plans, reviews, publishes and rolls back
-- changes to the school bus network, and runs live ETA, disruption and safety
-- features on top of it. Its plan is prime_info/smart-transport-audit/07-PRIMETRANSPORT-PLAN.md.
--
-- The "PROPOSED ROUTE AND PICKUP POINTS" section of Transport_DDL_v2.4.sql
-- (tpt_route_proposal_master, tpt_proposed_*, tpt_*_history) was reviewed for this
-- purpose and is NOT used, for three reasons
-- (full review: prime_info/smart-transport-audit/10-PROPOSAL-TABLES-REVIEW.md):
--
--   1. SmartTransport already owns and writes those tables (RouteProposalPlanner::applyPlan).
--      Sharing them would mix the two modules' plans, and SmartTransport's "apply" could
--      publish a PrimeTransport plan without PrimeTransport's checks. Plan decision D1
--      says SmartTransport is not touched; S1 says PrimeTransport uses ptr_ tables.
--   2. They cover only the draft route network. They have no plan status, effective date,
--      baseline hash, KPI or scenario columns, no locks or reviews, and nothing for geo,
--      engine runs, the Advisor, live ops or safety.
--   3. The *_history tables cannot serve as a rollback snapshot: every row points at a live
--      row through a foreign key, so they break when the live row is deleted. A rollback
--      copy must survive that (plan S5).
--
-- Decision taken 2026-10-23 (Tarun): PrimeTransport gets its own ptr_ tables, and this
-- separate DDL file holds them. Transport_DDL_v2.4.sql keeps its known mismatches with the
-- live database; they are listed in report 10, section 4.
--
-- FOREIGN-KEY POLICY IN THIS FILE
-- --------------------------------
--   * A plan's own children (routes, stops, allocations, ...) use ON DELETE CASCADE:
--     deleting a draft plan removes its contents.
--   * References to LIVE Transport / Student / User rows use ON DELETE SET NULL (optional
--     columns) or RESTRICT (required columns). Tidying live data never silently erases
--     a plan or its history.
--   * ptr_snapshots stores self-contained JSON and has NO foreign key to any live row.
--   * Every constraint name starts with fk_ptr_ / uq_ptr_ / idx_ptr_ so names stay unique
--     across the whole tenant schema.
--
-- TABLE LIST (25)
--   Settings  : ptr_settings, ptr_rule_settings
--   Geo       : ptr_distance_matrix, ptr_segment_speeds, ptr_student_geo
--   Engine    : ptr_engine_runs
--   Plans     : ptr_plans, ptr_plan_routes, ptr_plan_new_stops, ptr_plan_route_stops,
--               ptr_plan_allocations, ptr_plan_vehicle_assignments, ptr_plan_locks,
--               ptr_plan_reviews, ptr_snapshots
--   Advisor   : ptr_advisor_runs, ptr_suggestions, ptr_suggestion_outcomes
--   Live ops  : ptr_eta_live, ptr_disruptions, ptr_admission_quotes
--   Safety    : ptr_safety_rules, ptr_safety_scores
--   Transport : tpt_gps_trip_log, tpt_gps_alerts   (plan item T5)
--   (23 ptr_ + 2 tpt_ = 25)
-- =======================================================================


-- =======================================================================
-- SETTINGS
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_settings` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`group` VARCHAR(50) NOT NULL DEFAULT 'general',   -- 'general','engine','advisor','ops','safety','maps'
		`key` VARCHAR(100) NOT NULL,                        -- e.g. 'engine.max_ride_minutes'
		`value_json` JSON NOT NULL,                          -- typed value, e.g. 60 / "osrm" / {"am":"07:00"}
		`description` VARCHAR(500) DEFAULT NULL,
		`is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`updated_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		UNIQUE KEY `uq_ptr_settings_key` (`key`),
		CONSTRAINT `fk_ptr_settings_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_settings_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- One row per setting. Read through a cached settings service (cache key must carry the tenant id).

	CREATE TABLE IF NOT EXISTS `ptr_rule_settings` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`rule_code` VARCHAR(60) NOT NULL,                   -- code from 09-RULE-CATALOGUE.md, e.g. 'CAP_OVERLOAD'
		`family` VARCHAR(40) NOT NULL,                      -- 'compliance','capacity','cost','fees','punctuality','fuel','crew','safety','comms'
		`is_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`severity` ENUM('info','low','medium','high','critical') NOT NULL DEFAULT 'medium',
		`params_json` JSON DEFAULT NULL,                    -- thresholds the school can tune
		`is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`updated_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		UNIQUE KEY `uq_ptr_ruleSettings_code` (`rule_code`),
		CONSTRAINT `fk_ptr_ruleSettings_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_ruleSettings_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Per-school on/off and thresholds for every Advisor rule. Seeded from the rule catalogue.


-- =======================================================================
-- GEO (open-source, self-hosted routing only — plan S4b)
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_distance_matrix` (
		`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`from_point_type` ENUM('school','stop','new_stop','student') NOT NULL,
		`from_point_id` INT UNSIGNED NOT NULL,              -- id in the table named by from_point_type (0 = the school)
		`to_point_type` ENUM('school','stop','new_stop','student') NOT NULL,
		`to_point_id` INT UNSIGNED NOT NULL,
		`distance_m` INT UNSIGNED NOT NULL,                 -- road distance in metres
		`duration_s` INT UNSIGNED NOT NULL,                 -- free-flow drive time in seconds
		`source` ENUM('osrm','haversine','manual') NOT NULL DEFAULT 'osrm',
		`computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_distMatrix_pair` (`from_point_type`,`from_point_id`,`to_point_type`,`to_point_id`),
		KEY `idx_ptr_distMatrix_to` (`to_point_type`,`to_point_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Polymorphic point ids, so no foreign keys. A cache, not a record: rows can be rebuilt from OSRM at any time.
	-- Size today: 136 stops -> about 18,500 stop-to-stop pairs per school.

	CREATE TABLE IF NOT EXISTS `ptr_segment_speeds` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`from_stop_id` INT UNSIGNED NOT NULL,               -- fk to tpt_pickup_points
		`to_stop_id` INT UNSIGNED NOT NULL,                 -- fk to tpt_pickup_points
		`shift_id` INT UNSIGNED DEFAULT NULL,               -- fk to tpt_shift (NULL = any shift)
		`time_band` VARCHAR(20) NOT NULL DEFAULT 'all',     -- e.g. '07:00-08:00'
		`avg_speed_kmph` DECIMAL(6,2) UNSIGNED NOT NULL,
		`avg_duration_s` INT UNSIGNED NOT NULL,
		`sample_count` INT UNSIGNED NOT NULL DEFAULT 0,     -- number of GPS traversals averaged
		`last_sampled_at` TIMESTAMP NULL DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_segSpeed_seg` (`from_stop_id`,`to_stop_id`,`shift_id`,`time_band`),
		CONSTRAINT `fk_ptr_segSpeed_fromStop` FOREIGN KEY (`from_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_segSpeed_toStop` FOREIGN KEY (`to_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_segSpeed_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Learned real-world speed per road segment, from tpt_gps_trip_log. Derived data: CASCADE is safe here.

	CREATE TABLE IF NOT EXISTS `ptr_student_geo` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`student_id` INT UNSIGNED NOT NULL,                 -- fk to std_students (std_students has no lat/lng column)
		`latitude` DECIMAL(10,7) DEFAULT NULL,
		`longitude` DECIMAL(10,7) DEFAULT NULL,
		`address_text` VARCHAR(500) DEFAULT NULL,           -- the PICKUP address (latitude/longitude are the pickup point)
		`drop_latitude` DECIMAL(10,7) DEFAULT NULL,         -- drop point, from std_student_addresses.is_drop_location (2026-10-26)
		`drop_longitude` DECIMAL(10,7) DEFAULT NULL,
		`drop_address_text` VARCHAR(500) DEFAULT NULL,      -- the drop address
		`geocode_source` ENUM('nominatim','pin_drop','parent_app','manual','generated') NOT NULL DEFAULT 'manual', -- generated = built from std_student_addresses by Generate; a re-run refreshes only these
		`geocode_accuracy_m` INT UNSIGNED DEFAULT NULL,
		`consent_given` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,  -- parent consent to store the home location
		`consent_at` TIMESTAMP NULL DEFAULT NULL,
		`consent_by` INT UNSIGNED DEFAULT NULL,             -- fk to sys_users (parent/guardian or staff who recorded it)
		`is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`updated_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		UNIQUE KEY `uq_ptr_studentGeo_student` (`student_id`),
		CONSTRAINT `fk_ptr_studentGeo_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_studentGeo_consentBy` FOREIGN KEY (`consent_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_studentGeo_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_studentGeo_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Personal data. Coordinates are only used when consent_given = 1. One row per student.


-- =======================================================================
-- PLANS (a plan is a full copy of the network it proposes — plan S5)
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_plans` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`code` VARCHAR(50) NOT NULL,
		`name` VARCHAR(200) NOT NULL,
		`academic_session_id` SMALLINT UNSIGNED NOT NULL,   -- fk to sch_org_academic_sessions_jnt
		`shift_id` INT UNSIGNED DEFAULT NULL,               -- fk to tpt_shift (NULL = all shifts)
		`source` ENUM('engine','manual','advisor','disruption') NOT NULL DEFAULT 'engine',
		`status` ENUM('Draft','InReview','Approved','Scheduled','Published','Superseded','Rejected','RolledBack') NOT NULL DEFAULT 'Draft',
		`parent_plan_id` INT UNSIGNED DEFAULT NULL,         -- the plan this one was cloned from (scenario branching)
		`effective_from` DATE DEFAULT NULL,                 -- the day the plan goes live (set when Scheduled)
		`baseline_hash` CHAR(64) DEFAULT NULL,              -- SHA-256 of the live network when the plan was built (drift guard)
		`levers_json` JSON DEFAULT NULL,                    -- scenario inputs: max ride time, vehicle cap, stop walk radius, ...
		`kpi_json` JSON DEFAULT NULL,                       -- results: buses used, total km, avg/max ride, cost per student, ...
		`submitted_at` TIMESTAMP NULL DEFAULT NULL,
		`approved_at` TIMESTAMP NULL DEFAULT NULL,
		`approved_by` INT UNSIGNED DEFAULT NULL,
		`published_at` TIMESTAMP NULL DEFAULT NULL,
		`published_by` INT UNSIGNED DEFAULT NULL,
		`rolled_back_at` TIMESTAMP NULL DEFAULT NULL,
		`remarks` VARCHAR(1000) DEFAULT NULL,
		`is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`updated_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		UNIQUE KEY `uq_ptr_plans_code` (`code`),
		KEY `idx_ptr_plans_status` (`status`,`effective_from`),
		CONSTRAINT `fk_ptr_plans_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt`(`id`) ON DELETE RESTRICT,
		CONSTRAINT `fk_ptr_plans_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_plans_parent` FOREIGN KEY (`parent_plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_plans_approvedBy` FOREIGN KEY (`approved_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_plans_publishedBy` FOREIGN KEY (`published_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_plans_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_plans_updatedBy` FOREIGN KEY (`updated_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Conditions:
	--   1. Only Draft plans are editable. Moving past InReview freezes the plan's children.
	--   2. Publish refuses if the live network's hash no longer equals baseline_hash (drift guard).
	--   3. Publish writes a 'before_publish' row to ptr_snapshots first, then changes tpt_* rows.
	--   4. Published / Superseded / RolledBack plans are never hard-deleted (keep them as history).
	--   5. uq_ptr_plans_code is not soft-delete aware: a trashed plan keeps its code.

	CREATE TABLE IF NOT EXISTS `ptr_plan_routes` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED NOT NULL,                    -- fk to ptr_plans
		`source_route_id` INT UNSIGNED DEFAULT NULL,        -- fk to tpt_route (NULL = brand-new route)
		`change_kind` ENUM('unchanged','added','changed','removed') NOT NULL DEFAULT 'unchanged',
		`code` VARCHAR(50) NOT NULL,
		`name` VARCHAR(200) NOT NULL,
		`pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
		`shift_id` INT UNSIGNED DEFAULT NULL,               -- fk to tpt_shift
		`route_geometry` LINESTRING SRID 4326 DEFAULT NULL, -- path drawn on the map
		`total_distance_km` DECIMAL(8,2) UNSIGNED DEFAULT NULL,
		`est_duration_min` SMALLINT UNSIGNED DEFAULT NULL,
		`student_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
		`change_note` VARCHAR(500) DEFAULT NULL,            -- why the engine/user changed it
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_planRoutes_plan_code` (`plan_id`,`code`),
		KEY `idx_ptr_planRoutes_source` (`source_route_id`),
		CONSTRAINT `fk_ptr_planRoutes_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planRoutes_sourceRoute` FOREIGN KEY (`source_route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planRoutes_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Every live route is copied into the plan (change_kind = 'unchanged' when untouched), so the plan is complete on its own.

	CREATE TABLE IF NOT EXISTS `ptr_plan_new_stops` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED NOT NULL,                    -- fk to ptr_plans
		`code` VARCHAR(50) NOT NULL,
		`name` VARCHAR(200) NOT NULL,
		`latitude` DECIMAL(10,7) NOT NULL,
		`longitude` DECIMAL(10,7) NOT NULL,
		`reason` VARCHAR(500) DEFAULT NULL,                 -- e.g. 'cluster of 9 students > 800 m from any stop'
		`promoted_stop_id` INT UNSIGNED DEFAULT NULL,       -- fk to tpt_pickup_points, set when the plan is published
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_planNewStops_plan_code` (`plan_id`,`code`),
		CONSTRAINT `fk_ptr_planNewStops_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planNewStops_promoted` FOREIGN KEY (`promoted_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Stops that do not exist yet. On publish each one becomes a tpt_pickup_points row.

	CREATE TABLE IF NOT EXISTS `ptr_plan_route_stops` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_route_id` INT UNSIGNED NOT NULL,              -- fk to ptr_plan_routes
		`stop_id` INT UNSIGNED DEFAULT NULL,                -- fk to tpt_pickup_points (an existing stop) ...
		`new_stop_id` INT UNSIGNED DEFAULT NULL,            -- ... or fk to ptr_plan_new_stops (a proposed stop); exactly one is set
		`sequence` SMALLINT UNSIGNED NOT NULL,
		`pickup_time` TIME DEFAULT NULL,
		`drop_time` TIME DEFAULT NULL,
		`distance_from_school_km` DECIMAL(7,2) UNSIGNED DEFAULT NULL,
		`change_kind` ENUM('unchanged','added','changed','removed') NOT NULL DEFAULT 'unchanged',
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_planRouteStops_seq` (`plan_route_id`,`sequence`),
		CONSTRAINT `fk_ptr_planRouteStops_planRoute` FOREIGN KEY (`plan_route_id`) REFERENCES `ptr_plan_routes`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planRouteStops_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE RESTRICT,
		CONSTRAINT `fk_ptr_planRouteStops_newStop` FOREIGN KEY (`new_stop_id`) REFERENCES `ptr_plan_new_stops`(`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Exactly one of stop_id / new_stop_id must be set. Enforced in the app, NOT by a CHECK: MySQL 8 rejects a CHECK on a
	-- column whose FK has a referential action such as CASCADE (errno 3823), and new_stop_id must cascade with its plan.
	-- stop_id is RESTRICT: a live stop used by a draft plan cannot be deleted until the plan drops it.

	CREATE TABLE IF NOT EXISTS `ptr_plan_allocations` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED NOT NULL,                    -- fk to ptr_plans
		`student_id` INT UNSIGNED NOT NULL,                 -- fk to std_students
		`source_allocation_id` INT UNSIGNED DEFAULT NULL,   -- fk to tpt_student_route_allocation_jnt (NULL = new rider)
		`pickup_plan_route_id` INT UNSIGNED DEFAULT NULL,   -- fk to ptr_plan_routes
		`pickup_route_stop_id` INT UNSIGNED DEFAULT NULL,   -- fk to ptr_plan_route_stops
		`drop_plan_route_id` INT UNSIGNED DEFAULT NULL,     -- fk to ptr_plan_routes
		`drop_route_stop_id` INT UNSIGNED DEFAULT NULL,     -- fk to ptr_plan_route_stops
		`walk_distance_m` SMALLINT UNSIGNED DEFAULT NULL,   -- home to pickup stop
		`ride_minutes` SMALLINT UNSIGNED DEFAULT NULL,
		`change_kind` ENUM('unchanged','added','changed','removed') NOT NULL DEFAULT 'unchanged',
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_planAlloc_plan_student` (`plan_id`,`student_id`),
		CONSTRAINT `fk_ptr_planAlloc_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planAlloc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planAlloc_sourceAlloc` FOREIGN KEY (`source_allocation_id`) REFERENCES `tpt_student_route_allocation_jnt`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planAlloc_pickupRoute` FOREIGN KEY (`pickup_plan_route_id`) REFERENCES `ptr_plan_routes`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planAlloc_pickupStop` FOREIGN KEY (`pickup_route_stop_id`) REFERENCES `ptr_plan_route_stops`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planAlloc_dropRoute` FOREIGN KEY (`drop_plan_route_id`) REFERENCES `ptr_plan_routes`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planAlloc_dropStop` FOREIGN KEY (`drop_route_stop_id`) REFERENCES `ptr_plan_route_stops`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- One row per student per plan. Points at the PLAN's own copies of routes/stops, never at live tpt_route rows.

	CREATE TABLE IF NOT EXISTS `ptr_plan_vehicle_assignments` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_route_id` INT UNSIGNED NOT NULL,              -- fk to ptr_plan_routes
		`shift_id` INT UNSIGNED DEFAULT NULL,               -- fk to tpt_shift
		`pickup_drop` ENUM('Pickup','Drop','Both') NOT NULL DEFAULT 'Both',
		`vehicle_id` INT UNSIGNED DEFAULT NULL,             -- fk to tpt_vehicle
		`driver_id` INT UNSIGNED DEFAULT NULL,              -- fk to tpt_personnel
		`helper_id` INT UNSIGNED DEFAULT NULL,              -- fk to tpt_personnel
		`seats_used` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
		`effective_from` DATE DEFAULT NULL,
		`change_kind` ENUM('unchanged','added','changed','removed') NOT NULL DEFAULT 'unchanged',
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_planVehicle_route_shift` (`plan_route_id`,`shift_id`,`pickup_drop`),
		CONSTRAINT `fk_ptr_planVehicle_planRoute` FOREIGN KEY (`plan_route_id`) REFERENCES `ptr_plan_routes`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planVehicle_shift` FOREIGN KEY (`shift_id`) REFERENCES `tpt_shift`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planVehicle_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planVehicle_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planVehicle_helper` FOREIGN KEY (`helper_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- On publish these become tpt_driver_route_vehicle_jnt rows (that table's overlap trigger still applies).

	CREATE TABLE IF NOT EXISTS `ptr_plan_locks` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED NOT NULL,                    -- fk to ptr_plans
		`lock_type` ENUM('route','stop','student','vehicle','driver') NOT NULL,
		`target_id` INT UNSIGNED NOT NULL,                  -- live id of the locked thing (polymorphic, no FK)
		`reason` VARCHAR(500) DEFAULT NULL,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_planLocks_target` (`plan_id`,`lock_type`,`target_id`),
		CONSTRAINT `fk_ptr_planLocks_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planLocks_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Things the engine must not move when it re-plans (e.g. "keep route 4 exactly as it is").

	CREATE TABLE IF NOT EXISTS `ptr_plan_reviews` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED NOT NULL,                    -- fk to ptr_plans
		`plan_route_id` INT UNSIGNED DEFAULT NULL,          -- fk to ptr_plan_routes (NULL = a decision on the whole plan)
		`step` ENUM('submit','review','approve','reject','schedule','publish','rollback','comment') NOT NULL,
		`decision` ENUM('approved','rejected','changes_requested','noted') DEFAULT NULL,
		`comment` VARCHAR(1000) DEFAULT NULL,
		`reviewer_id` INT UNSIGNED DEFAULT NULL,            -- fk to sys_users
		`decided_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		KEY `idx_ptr_planReviews_plan` (`plan_id`,`decided_at`),
		CONSTRAINT `fk_ptr_planReviews_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_planReviews_planRoute` FOREIGN KEY (`plan_route_id`) REFERENCES `ptr_plan_routes`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_planReviews_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Append-only audit trail of every lifecycle step. Never edited.

	CREATE TABLE IF NOT EXISTS `ptr_snapshots` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED DEFAULT NULL,                -- fk to ptr_plans (the plan whose publish produced it)
		`kind` ENUM('before_publish','after_publish','before_rollback','manual') NOT NULL,
		`scope_json` JSON DEFAULT NULL,                     -- which tables/ids are inside the payload
		`payload_json` LONGTEXT NOT NULL,                   -- full copy of the affected tpt_* rows; NO foreign keys to them
		`checksum` CHAR(64) NOT NULL,                       -- SHA-256 of payload_json
		`row_count` INT UNSIGNED NOT NULL DEFAULT 0,
		`taken_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`taken_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		KEY `idx_ptr_snapshots_plan` (`plan_id`,`kind`),
		CONSTRAINT `fk_ptr_snapshots_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_snapshots_takenBy` FOREIGN KEY (`taken_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- This is the rollback source, NOT the tpt_*_history tables. It must still restore the network after the
	-- live rows it copied have been deleted, which is why it holds JSON and no FK to any tpt_* row.
	-- Never delete live tpt_* rows before the 'before_publish' snapshot is written (plan S5).


-- =======================================================================
-- ENGINE
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_engine_runs` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`plan_id` INT UNSIGNED DEFAULT NULL,                -- fk to ptr_plans (the plan this run fills)
		`run_type` ENUM('full_plan','repair','what_if','admission_quote') NOT NULL DEFAULT 'full_plan',
		`status` ENUM('queued','running','succeeded','failed','cancelled') NOT NULL DEFAULT 'queued',
		`progress_pct` TINYINT UNSIGNED NOT NULL DEFAULT 0,
		`stage` VARCHAR(100) DEFAULT NULL,                  -- e.g. 'clustering stops', 'solving VRP'
		`input_json` JSON DEFAULT NULL,                     -- levers + counts sent to the Python solver
		`output_json` JSON DEFAULT NULL,                    -- solver summary (objective, unassigned, timings)
		`error_text` TEXT DEFAULT NULL,                     -- full error for the log; the UI shows a fixed message
		`solver_version` VARCHAR(50) DEFAULT NULL,
		`started_at` TIMESTAMP NULL DEFAULT NULL,
		`finished_at` TIMESTAMP NULL DEFAULT NULL,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		KEY `idx_ptr_engineRuns_status` (`status`,`created_at`),
		CONSTRAINT `fk_ptr_engineRuns_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_engineRuns_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- The UI polls this row for live progress while the queued job runs.


-- =======================================================================
-- ADVISOR
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_advisor_runs` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`trigger` ENUM('scheduled','manual','event') NOT NULL DEFAULT 'scheduled',
		`status` ENUM('queued','running','succeeded','failed') NOT NULL DEFAULT 'queued',
		`scope_json` JSON DEFAULT NULL,                     -- which rule families / routes were checked
		`suggestion_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
		`error_text` TEXT DEFAULT NULL,
		`started_at` TIMESTAMP NULL DEFAULT NULL,
		`finished_at` TIMESTAMP NULL DEFAULT NULL,
		`created_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		CONSTRAINT `fk_ptr_advisorRuns_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `ptr_suggestions` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`advisor_run_id` INT UNSIGNED NOT NULL,             -- fk to ptr_advisor_runs
		`rule_code` VARCHAR(60) NOT NULL,                   -- matches ptr_rule_settings.rule_code
		`severity` ENUM('info','low','medium','high','critical') NOT NULL DEFAULT 'medium',
		`target_type` ENUM('route','stop','vehicle','driver','student','fee','network') NOT NULL,
		`target_id` INT UNSIGNED DEFAULT NULL,              -- live id (polymorphic, no FK)
		`title` VARCHAR(250) NOT NULL,
		`detail_json` JSON DEFAULT NULL,                    -- the evidence (numbers) behind the suggestion
		`impact_json` JSON DEFAULT NULL,                    -- estimated saving / risk reduced
		`dedupe_key` CHAR(64) NOT NULL,                     -- hash of rule_code + target, so a repeat run does not duplicate an open suggestion
		`status` ENUM('open','accepted','dismissed','snoozed','resolved') NOT NULL DEFAULT 'open',
		`snoozed_until` DATE DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		KEY `idx_ptr_suggestions_status` (`status`,`severity`),
		KEY `idx_ptr_suggestions_dedupe` (`dedupe_key`,`status`),
		CONSTRAINT `fk_ptr_suggestions_run` FOREIGN KEY (`advisor_run_id`) REFERENCES `ptr_advisor_runs`(`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `ptr_suggestion_outcomes` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`suggestion_id` INT UNSIGNED NOT NULL,              -- fk to ptr_suggestions
		`decision` ENUM('accepted','dismissed','snoozed') NOT NULL,
		`reason` VARCHAR(500) DEFAULT NULL,
		`plan_id` INT UNSIGNED DEFAULT NULL,                -- fk to ptr_plans, when the suggestion was turned into a plan
		`measured_effect_json` JSON DEFAULT NULL,           -- before/after numbers once the change has been live a while
		`decided_by` INT UNSIGNED DEFAULT NULL,
		`decided_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		CONSTRAINT `fk_ptr_suggOutcomes_suggestion` FOREIGN KEY (`suggestion_id`) REFERENCES `ptr_suggestions`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_suggOutcomes_plan` FOREIGN KEY (`plan_id`) REFERENCES `ptr_plans`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_suggOutcomes_decidedBy` FOREIGN KEY (`decided_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- The ledger that shows whether accepted suggestions actually helped.


-- =======================================================================
-- LIVE OPERATIONS
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_eta_live` (
		`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`trip_id` INT UNSIGNED NOT NULL,                    -- fk to tpt_trip
		`stop_id` INT UNSIGNED NOT NULL,                    -- fk to tpt_pickup_points
		`scheduled_at` TIME DEFAULT NULL,
		`eta_at` TIMESTAMP NULL DEFAULT NULL,
		`delay_s` INT DEFAULT NULL,                         -- negative = early
		`status` ENUM('pending','arrived','skipped') NOT NULL DEFAULT 'pending',
		`computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_etaLive_trip_stop` (`trip_id`,`stop_id`),
		CONSTRAINT `fk_ptr_etaLive_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE CASCADE,
		CONSTRAINT `fk_ptr_etaLive_stop` FOREIGN KEY (`stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE CASCADE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Overwritten (upsert) as GPS points arrive. Transient data, so CASCADE is acceptable.

	CREATE TABLE IF NOT EXISTS `ptr_disruptions` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`type` ENUM('vehicle_breakdown','driver_absent','road_closed','weather','event','other') NOT NULL,
		`route_id` INT UNSIGNED DEFAULT NULL,               -- fk to tpt_route
		`vehicle_id` INT UNSIGNED DEFAULT NULL,             -- fk to tpt_vehicle
		`starts_at` TIMESTAMP NOT NULL,
		`ends_at` TIMESTAMP NULL DEFAULT NULL,
		`description` VARCHAR(1000) DEFAULT NULL,
		`override_json` JSON DEFAULT NULL,                  -- the replacement vehicle/driver/route written to tpt_route_scheduler_jnt
		`scheduler_row_ids_json` JSON DEFAULT NULL,         -- tpt_route_scheduler_jnt ids created, so they can be undone
		`parents_notified_at` TIMESTAMP NULL DEFAULT NULL,
		`status` ENUM('open','applied','resolved','cancelled') NOT NULL DEFAULT 'open',
		`created_by` INT UNSIGNED DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		KEY `idx_ptr_disruptions_window` (`status`,`starts_at`),
		CONSTRAINT `fk_ptr_disruptions_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_disruptions_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_disruptions_createdBy` FOREIGN KEY (`created_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `ptr_admission_quotes` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`enquiry_ref` VARCHAR(100) DEFAULT NULL,            -- admission enquiry number, if the quote came from one
		`latitude` DECIMAL(10,7) NOT NULL,
		`longitude` DECIMAL(10,7) NOT NULL,
		`address_text` VARCHAR(500) DEFAULT NULL,
		`nearest_stop_id` INT UNSIGNED DEFAULT NULL,        -- fk to tpt_pickup_points
		`route_id` INT UNSIGNED DEFAULT NULL,               -- fk to tpt_route
		`walk_distance_m` SMALLINT UNSIGNED DEFAULT NULL,
		`seat_available` TINYINT(1) UNSIGNED DEFAULT NULL,
		`fare_quote` DECIMAL(10,2) UNSIGNED DEFAULT NULL,
		`result_json` JSON DEFAULT NULL,                    -- alternatives considered
		`quoted_by` INT UNSIGNED DEFAULT NULL,
		`quoted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		CONSTRAINT `fk_ptr_admQuotes_stop` FOREIGN KEY (`nearest_stop_id`) REFERENCES `tpt_pickup_points`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_admQuotes_route` FOREIGN KEY (`route_id`) REFERENCES `tpt_route`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_ptr_admQuotes_quotedBy` FOREIGN KEY (`quoted_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- "Can we take this child, from this address, and for how much?" answered before admission.


-- =======================================================================
-- SAFETY
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `ptr_safety_rules` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`code` VARCHAR(60) NOT NULL,                        -- e.g. 'OVERSPEED','HARSH_BRAKE','ROUTE_DEVIATION','LONG_IDLE'
		`name` VARCHAR(200) NOT NULL,
		`threshold_json` JSON NOT NULL,                     -- e.g. {"max_kmph":50,"min_duration_s":10}
		`severity` ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
		`score_penalty` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
		`is_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`is_system` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0, -- if 1, code cannot be changed or deleted
		`is_active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at` TIMESTAMP NULL DEFAULT NULL,
		UNIQUE KEY `uq_ptr_safetyRules_code` (`code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	CREATE TABLE IF NOT EXISTS `ptr_safety_scores` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`driver_id` INT UNSIGNED NOT NULL,                  -- fk to tpt_personnel
		`period_type` ENUM('day','week','month') NOT NULL DEFAULT 'week',
		`period_start` DATE NOT NULL,
		`score` DECIMAL(5,2) UNSIGNED NOT NULL,             -- 0..100
		`trips_counted` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
		`km_counted` DECIMAL(9,2) UNSIGNED NOT NULL DEFAULT 0,
		`breakdown_json` JSON DEFAULT NULL,                 -- events per safety rule
		`computed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		UNIQUE KEY `uq_ptr_safetyScores_period` (`driver_id`,`period_type`,`period_start`),
		CONSTRAINT `fk_ptr_safetyScores_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- RESTRICT: a driver's safety record must not disappear when the personnel row is removed. Deactivate instead.


-- =======================================================================
-- TRANSPORT ADDITIONS (plan T5) — owned by Modules/Transport, written by PrimeTransport's GPS ingest
-- =======================================================================

	CREATE TABLE IF NOT EXISTS `tpt_gps_trip_log` (
		`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`trip_id` INT UNSIGNED DEFAULT NULL,                -- fk to tpt_trip (NULL = vehicle moving outside a trip)
		`vehicle_id` INT UNSIGNED NOT NULL,                 -- fk to tpt_vehicle
		`latitude` DECIMAL(10,7) NOT NULL,
		`longitude` DECIMAL(10,7) NOT NULL,
		`speed_kmph` DECIMAL(6,2) UNSIGNED DEFAULT NULL,
		`heading_deg` SMALLINT UNSIGNED DEFAULT NULL,
		`accuracy_m` SMALLINT UNSIGNED DEFAULT NULL,
		`source` ENUM('device','driver_app','import') NOT NULL DEFAULT 'device',
		`recorded_at` TIMESTAMP NOT NULL,                   -- time on the device
		`received_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		KEY `idx_tpt_gpsLog_trip_time` (`trip_id`,`recorded_at`),
		KEY `idx_tpt_gpsLog_vehicle_time` (`vehicle_id`,`recorded_at`),
		CONSTRAINT `fk_tpt_gpsLog_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_tpt_gpsLog_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- High-volume, insert-only. No updated_at / deleted_at on purpose. Plan a retention job (e.g. keep 180 days).

	CREATE TABLE IF NOT EXISTS `tpt_gps_alerts` (
		`id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
		`trip_id` INT UNSIGNED DEFAULT NULL,                -- fk to tpt_trip
		`vehicle_id` INT UNSIGNED NOT NULL,                 -- fk to tpt_vehicle
		`driver_id` INT UNSIGNED DEFAULT NULL,              -- fk to tpt_personnel
		`safety_rule_id` INT UNSIGNED DEFAULT NULL,         -- fk to ptr_safety_rules (the rule that fired)
		`alert_type` VARCHAR(60) NOT NULL,                  -- same code as ptr_safety_rules.code
		`value` DECIMAL(10,2) DEFAULT NULL,                 -- e.g. the speed that was measured
		`latitude` DECIMAL(10,7) DEFAULT NULL,
		`longitude` DECIMAL(10,7) DEFAULT NULL,
		`recorded_at` TIMESTAMP NOT NULL,
		`acknowledged_by` INT UNSIGNED DEFAULT NULL,
		`acknowledged_at` TIMESTAMP NULL DEFAULT NULL,
		`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
		`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		KEY `idx_tpt_gpsAlerts_vehicle_time` (`vehicle_id`,`recorded_at`),
		KEY `idx_tpt_gpsAlerts_open` (`acknowledged_at`),
		CONSTRAINT `fk_tpt_gpsAlerts_trip` FOREIGN KEY (`trip_id`) REFERENCES `tpt_trip`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_tpt_gpsAlerts_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `tpt_vehicle`(`id`) ON DELETE RESTRICT,
		CONSTRAINT `fk_tpt_gpsAlerts_driver` FOREIGN KEY (`driver_id`) REFERENCES `tpt_personnel`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_tpt_gpsAlerts_rule` FOREIGN KEY (`safety_rule_id`) REFERENCES `ptr_safety_rules`(`id`) ON DELETE SET NULL,
		CONSTRAINT `fk_tpt_gpsAlerts_ackBy` FOREIGN KEY (`acknowledged_by`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
	-- Created by ptr_safety_rules -> must come AFTER ptr_safety_rules in this file (it does).

-- =======================================================================
-- CHANGELOG
--   v1.0  2026-10-23  First version. 23 ptr_ tables + tpt_gps_trip_log + tpt_gps_alerts.
--                     Reason and table-by-table justification: report 10 in
--                     prime_info/smart-transport-audit/. Nothing in Transport_DDL_v2.4.sql changed.
-- =======================================================================
