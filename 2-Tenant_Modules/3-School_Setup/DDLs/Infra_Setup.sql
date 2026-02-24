-- ===========================================================================
-- 3.2 - INFRA SETUP SUB-MODULE (sch)
-- ===========================================================================

-- Building Coding format is - 2 Digit for Buildings(10-99)
  CREATE TABLE IF NOT EXISTS `sch_buildings` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` char(10) NOT NULL,                      -- 2 digits code (10,11,12) 
    `short_name` varchar(30) NOT NULL,            -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(50) NOT NULL,                  -- Detailed Name of the Building
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_buildings_code` (`code`),
    UNIQUE KEY `uq_buildings_name` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tables for Room types, this will be used to define different types of rooms like Science Lab, Computer Lab, Sports Room etc.
  CREATE TABLE IF NOT EXISTS `sch_rooms_type` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `code` CHAR(10) NOT NULL,                         -- e.g., 'SCI_LAB','BIO_LAB','CRI_GRD','TT_ROOM','BDM_CRT', "HOUSE_ROOM"
    `short_name` varchar(30) NOT NULL,                -- e.g., 'Science Lab','Biology Lab','Cricket Ground','Table Tanis Room','Badminton Court'
    `name` varchar(100) NOT NULL,
    `required_resources` text DEFAULT NULL,           -- e.g., 'Microscopes, Lab Coats, Safety Goggles' for Science Lab
    `class_house_room` tinyint(1) NOT NULL DEFAULT 0, -- 1=Class House Room, 0=Other Room
    `room_count_in_category` smallint unsigned DEFAULT 0, -- Total Number of Rooms in this category
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_roomType_code` (`code`),
    UNIQUE KEY `uq_roomType_shortName` (`short_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Room Coding format is - 2 Digit for Buildings(10-99), 1 Digit-Building Floor(G,F,S,T,F / A,B,C,D,E), & Last 3 Character defin Class+Section (09A,10A,12B)
  CREATE TABLE IF NOT EXISTS `sch_rooms` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `building_id` int unsigned NOT NULL,      -- FK to 'sch_buildings' table
    `room_type_id` int NOT NULL,              -- FK to 'sch_rooms_type' table
    `code` CHAR(20) NOT NULL,                 -- e.g., '11G-10A','12F-11A','11S-12A' and so on (This will be used for Timetable)
    `short_name` varchar(50) NOT NULL,        -- e.g., 'Junior Wing','Primary Wing','Middle Wing','Senior Wing','Administration Wings'
    `name` varchar(100) NOT NULL,
    `capacity` int unsigned DEFAULT NULL,               -- Seating Capacity of the Room
    `max_limit` int unsigned DEFAULT NULL,              -- Maximum Limit of the Room, Maximum how many students can accomodate in the room
    `resource_tags` text DEFAULT NULL,                  -- e.g., 'Projector, Smart Board, AC, Lab Equipment' etc.
    `can_host_lecture` TINYINT(1) NOT NULL DEFAULT 0,   -- Seats + Writing Surface
    `can_host_practical` TINYINT(1) NOT NULL DEFAULT 0, -- Seats + Writing Surface + Lab Equipment
    `can_host_exam` TINYINT(1) NOT NULL DEFAULT 0,      -- Seats + Writing Surface + Exam Equipment
    `can_host_activity` TINYINT(1) NOT NULL DEFAULT 0,  -- Open space for movement
    `can_host_sports` TINYINT(1) NOT NULL DEFAULT 0,    -- Specific for PE/Games
    `room_available_from_date` DATE DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `deleted_at` timestamp NULL DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_rooms_code` (`code`),
    UNIQUE KEY `uq_rooms_shortName` (`short_name`),
    CONSTRAINT `fk_rooms_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rooms_roomTypeId` FOREIGN KEY (`room_type_id`) REFERENCES `sch_rooms_type` (`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ----------------------------------------------------------------------------------------------------------------------
  -- Change Log :
  -- ----------------------------------------------------------------------------------------------------------------------
  -- 1. Add `room_count_in_category` column to `sch_rooms_type` table
  -- 2. Add `can_host_lecture`, `can_host_practical`, `can_host_exam`, `can_host_activity`, `can_host_sports` columns to `sch_rooms` table
  -- 3. Add `room_available_from_date` column to `sch_rooms` table  
  