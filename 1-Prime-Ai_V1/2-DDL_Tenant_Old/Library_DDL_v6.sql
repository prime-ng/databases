-- =====================================================
-- Library Module Database Schema
-- Version: v6 — Comprehensive fixes + New Tables
-- Fixes: F-001 to F-045 from Lib_DDL_Enhancement_Report.md
-- MySQL 8 Compatible | Prime-AI Multi-Tenant ERP
-- Created: 2026-06-09
-- =====================================================

-- ----------------------------------------------------------------------------
-- Sub-Menu 1: BOOK MASTERS
-- ----------------------------------------------------------------------------

  -- Tab-1.1 : Classification of resource formats (physical books, e-books, PDFs, audio books, etc.) to handle different media types appropriately.
  CREATE TABLE IF NOT EXISTS `lib_resource_types` (
    `id`             SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`           VARCHAR(30) NOT NULL UNIQUE,            -- Business code (e.g., 'PHY_BOOK', 'EBOOK')
    `name`           VARCHAR(100) NOT NULL,                  -- Display name (e.g., 'Physical Book', 'E-Book')
    `is_physical`    TINYINT(1) NOT NULL DEFAULT 1,          -- Whether this is a physical resource
    `is_digital`     TINYINT(1) NOT NULL DEFAULT 0,          -- Whether this is a digital resource
    `is_audio_books` TINYINT(1) NOT NULL DEFAULT 0,          -- Whether this resource type represents audio books
    `is_borrowable`  TINYINT(1) NOT NULL DEFAULT 1,          -- Whether resources of this type can be borrowed
    `is_active`      TINYINT(1) NOT NULL DEFAULT 1,          -- Whether this resource type is currently active
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`     TIMESTAMP NULL,
    INDEX `idx_lib_resType_active` (`is_active`),
    UNIQUE KEY `uq_lib_resType_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-1.2 : Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization.
  CREATE TABLE IF NOT EXISTS `lib_categories` (
    `id`                 INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `parent_category_id` INT UNSIGNED NULL,            -- Self-reference for hierarchical categories
    `code`               VARCHAR(30) NOT NULL,         -- Business code (e.g., 'FIC', 'SCI_FI')
    `name`               VARCHAR(100) NOT NULL,        -- Display name (e.g., 'Fiction', 'Science Fiction')
    `description`        VARCHAR(255),                 -- Detailed description of the category
    `level`              TINYINT UNSIGNED DEFAULT 1,   -- Depth in hierarchy (1 = top level)
    `display_order`      TINYINT UNSIGNED DEFAULT 1,   -- Order for display in dropdowns
    `is_active`          TINYINT(1) DEFAULT TRUE,
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`         TIMESTAMP NULL,
    INDEX `idx_lib_category_parentCatId` (`parent_category_id`),
    INDEX `idx_lib_category_active` (`is_active`),
    INDEX `idx_lib_category_order` (`display_order`),
    UNIQUE KEY `uq_lib_category_code` (`code`),
    CONSTRAINT `fk_lib_category_parentCatId` FOREIGN KEY (`parent_category_id`) REFERENCES `lib_categories`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition:
  -- Use Grouping for showing Categories under Parent Category

  -- Tab-1.3 : Tags for literary genres that can be applied across categories for flexible searching and recommendations.
  CREATE TABLE IF NOT EXISTS `lib_genres` (
    `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`        VARCHAR(30) NOT NULL,           -- Business code (e.g., 'SF', 'MYSTERY')
    `name`        VARCHAR(100) NOT NULL,          -- Display name (e.g., 'Science Fiction', 'Mystery')
    `description` VARCHAR(255),                   -- Description of the genre
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP NULL,
    INDEX `idx_lib_genre_active` (`is_active`),
    UNIQUE KEY `uq_lib_genre_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-1.4 : Standardized condition states for physical books to track wear and tear, damage, and usability.
  CREATE TABLE IF NOT EXISTS `lib_book_conditions` (
    `id`            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(30) NOT NULL,           -- Business code (e.g., 'NEW', 'DAMAGED')
    `name`          VARCHAR(50) NOT NULL,           -- Display name (e.g., 'New', 'Damaged')
    `description`   VARCHAR(255),                   -- Detailed description of the condition
    `is_borrowable` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether books in this condition can be issued
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    INDEX `idx_lib_condition_active` (`is_active`),
    UNIQUE KEY `uq_lib_condition_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-1.5 : Master list of publishers for books and resources.
  CREATE TABLE IF NOT EXISTS `lib_publishers` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`       VARCHAR(30) NOT NULL,   -- Business code for the publisher
    `name`       VARCHAR(200) NOT NULL,  -- Full name of the publishing company
    `address`    TEXT NULL,              -- Physical/registered address
    `contact`    VARCHAR(100) NULL,      -- Primary contact person
    `email`      VARCHAR(100) NULL,      -- Contact email address
    `phone`      VARCHAR(20) NULL,       -- Contact phone number
    `website`    VARCHAR(255) NULL,      -- Publisher's website URL
    `is_active`  TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_lib_publisher_active` (`is_active`),
    UNIQUE KEY `uq_lib_publisher_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-1.6 : Master list of authors for books and resources.
  CREATE TABLE IF NOT EXISTS `lib_authors` (
    `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `short_name`       VARCHAR(50) NOT NULL,   -- Short identifier or pen name for the author
    `author_name`      VARCHAR(200) NOT NULL,  -- Full name of the author
    `country_id`       INT UNSIGNED NOT NULL,  -- FK to glb_countries.id, Country of the author
    `primary_genre_id` INT UNSIGNED NOT NULL,  -- FK to lib_genres.id, Primary genre preference of the author
    `notes`            TEXT DEFAULT NULL,      -- Additional notes about the author
    `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_author_shortName` (`short_name`),
    UNIQUE KEY `uq_lib_author_Name` (`author_name`),
    INDEX `idx_lib_author_active` (`is_active`),
    CONSTRAINT `fk_lib_authors_countries` FOREIGN KEY (`country_id`) REFERENCES `glb_countries` (`id`),
    CONSTRAINT `fk_lib_authors_genres` FOREIGN KEY (`primary_genre_id`) REFERENCES `lib_genres` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-1.7 : Searchable keywords that can be applied across books for flexible discovery and filtering.
  CREATE TABLE IF NOT EXISTS `lib_keywords` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`       VARCHAR(30) NOT NULL UNIQUE,         -- Business code for the keyword
    `name`       VARCHAR(100) NOT NULL,               -- Keyword text
    `is_active`  TINYINT(1) NOT NULL DEFAULT 1,       -- Whether this keyword is currently active
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_lib_keyword_active` (`is_active`),
    UNIQUE KEY `uq_lib_keyword_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- Sub-Menu 2: LOCATION MASTERS
-- ----------------------------------------------------------------------------

  -- Tab-2.1 : This table will hold all available options for Zone, Floor, Aisle, Shelf, Rack.
  CREATE TABLE IF NOT EXISTS `lib_locations_master` (
    `id`            MEDIUMINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`          VARCHAR(30) NOT NULL,              -- Business code (e.g., 'A1-S1-R1')
    `name`          VARCHAR(50) NOT NULL,              -- Display name (e.g., 'Aisle 1', 'Shelf 1')
    `description`   VARCHAR(255),                      -- Detailed description of the location
    `location_type` ENUM('Zone', 'Floor', 'Aisle', 'Shelf', 'Rack') NOT NULL,  -- Location type (Renamed from `type` to avoid reserved word)
    `building_id`   INT UNSIGNED NOT NULL,             -- FK to sch_buildings.id
    `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    TIMESTAMP NULL,
    INDEX `idx_lib_location_active` (`is_active`),
    UNIQUE KEY `uq_lib_location_code` (`code`),
    CONSTRAINT `fk_lib_location_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-2.2 : Physical location mapping for books in the library, enabling efficient shelving and retrieval.
  CREATE TABLE IF NOT EXISTS `lib_shelf_locations` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`         VARCHAR(30) NOT NULL,           -- Business code (e.g., 'A1-S1-R1')
    `building_id`  INT UNSIGNED NOT NULL,          -- FK to sch_buildings.id
    `zone_id`      MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_locations_master.id, Zone or section
    `floor_id`     MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_locations_master.id, Floor/level in the building
    `aisle_id`     MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_locations_master.id, Aisle identifier (e.g., 'A1', 'B2'). 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `rack_id`      MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_locations_master.id, Rack identifier
    `shelf_id`     MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_locations_master.id, Shelf identifier within aisle
    `description`  VARCHAR(255),                   -- Additional location details
    `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_shelfLocations_code` (`code`),
    INDEX `idx_lib_shelfLocations_active` (`is_active`),
    CONSTRAINT `fk_lib_shelfLocations_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_zoneId`     FOREIGN KEY (`zone_id`)     REFERENCES `lib_locations_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_floorId`    FOREIGN KEY (`floor_id`)    REFERENCES `lib_locations_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_aisleId`    FOREIGN KEY (`aisle_id`)    REFERENCES `lib_locations_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_rackId`     FOREIGN KEY (`rack_id`)     REFERENCES `lib_locations_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_shelfId`    FOREIGN KEY (`shelf_id`)    REFERENCES `lib_locations_master`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
    -- Aisle Number - An aisle is the open passage or walkway between rows of shelving units.
    -- shelf_number - A shelf is a flat, horizontal surface, typically made of wood or metal, used for storing or displaying items.
    -- rack_number - A rack is a framework, typically consisting of bars or hooks, used for storing or displaying items.
    -- floor_number - A floor is the lower surface of a room, on which one walks.
    -- zone - A zone is an area or stretch of land having a particular characteristic, purpose, or use, or subject to particular restrictions.


-- ----------------------------------------------------------------------------
-- Sub-Menu 3. LIBRARY CONFIGURATION
-- ----------------------------------------------------------------------------

  -- Tab-3.1 : Library Fine Types
  CREATE TABLE IF NOT EXISTS `lib_fine_type` (
    `id`          SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`        VARCHAR(30) NOT NULL, -- Code for the fine type (e.g., 'LateReturn', 'LostBook', 'DamagedBook', 'ProcessingFee')
    `name`        VARCHAR(50) NOT NULL, -- Name of the fine type ('Late Book Return Fine', 'Lost Book Fine', 'Damaged Book Fine')
    `description` VARCHAR(250) NULL,
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,  -- added is_active column
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_fineType_code` (`code`),
    UNIQUE KEY `uq_lib_fineType_name` (`name`),
    INDEX `idx_lib_fineType_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.2 : Library Fine Slab Config (Parent)
  CREATE TABLE IF NOT EXISTS `lib_fine_slab_config` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `name`                VARCHAR(100) NOT NULL,        -- Name of the fine slab
    `membership_type_id`  INT UNSIGNED NULL,            -- FK to lib_membership_types.id (NULL = applies to all)
    `resource_type_id`    SMALLINT UNSIGNED NULL,       -- FK to lib_resource_types.id (NULL = applies to all)
    `fine_type_id`        SMALLINT UNSIGNED NOT NULL,   -- FK to lib_fine_type.id
    `max_fine_cap`        ENUM('Fixed', 'BookCost', 'Unlimited') DEFAULT 'Unlimited',
    `max_fine_amt`        DECIMAL(10,2) NULL,
    `fine_amt_calc_type`  ENUM('Fixed', 'Percentage', 'BookCost') DEFAULT 'Fixed',
    `effective_from`      DATE NOT NULL,                -- Date from which this slab is effective
    `effective_to`        DATE NULL,                    -- Date until which this slab is effective, If NULL, slab is effective indefinitely
    `priority`            TINYINT UNSIGNED DEFAULT 0,   -- Priority for slab evaluation (Higher priority slabs are evaluated first)
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `fk_lib_fineSlabConfig_membershipType` FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    CONSTRAINT `fk_lib_fineSlabConfig_resourceType`   FOREIGN KEY (`resource_type_id`)   REFERENCES `lib_resource_types`(`id`),
    CONSTRAINT `fk_lib_fineSlabConfig_fineType`       FOREIGN KEY (`fine_type_id`)       REFERENCES `lib_fine_type`(`id`),
    INDEX `idx_lib_fineSlabConfig_membership` (`membership_type_id`),
    INDEX `idx_lib_fineSlabConfig_active_EffFrom_EffTo` (`is_active`, `effective_from`, `effective_to`),
    INDEX `idx_lib_fineSlabConfig_priority` (`priority`),
    UNIQUE KEY `uq_lib_fineSlabConf_memType_fineType_EffFrom` (`membership_type_id`, `fine_type_id`, `effective_from`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.3 : Library Fine Slab Details (Child)
  -- Fixed duplicate Tab label (was Tab-3.2 in v4)
  CREATE TABLE IF NOT EXISTS `lib_fine_slab_details` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `fine_slab_config_id` INT UNSIGNED NOT NULL,
    `from_day`            TINYINT UNSIGNED NOT NULL CHECK (from_day >= 0),
    `to_day`              TINYINT UNSIGNED NOT NULL CHECK (to_day >= from_day),
    `fine_rate`           DECIMAL(10,2) NOT NULL,
    `rate_type`           ENUM('Fixed', 'Percentage') DEFAULT 'Fixed',  -- This will decide whether 
    `calculation_type`    ENUM('Per_Day', 'Per_Week', 'Per_Month', 'Per_Year', 'Per_Book') DEFAULT 'Per_Day',
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `fk_lib_fineSlabDetails_fineSlabConfig` FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_fineSlabDetails_slabConfig_slabDays` (`fine_slab_config_id`, `from_day`, `to_day`),
    INDEX `idx_lib_fineSlabDetails_dayRange` (`from_day`, `to_day`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.4 : Library Account Entry Config
  CREATE TABLE IF NOT EXISTS `lib_account_entry_config` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `name`                VARCHAR(100) NOT NULL,
    `fine_type_id`        SMALLINT UNSIGNED NOT NULL,   -- FK to lib_fine_type.id ('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee')
    `fine_slab_config_id` INT UNSIGNED NULL,            -- FK to lib_fine_slab_config.id (NULL = applies to all slabs)
    `account_group_id`    INT UNSIGNED NOT NULL,        -- FK to acc_account_groups.id
    `ledger_id`           INT UNSIGNED NOT NULL,        -- FK to acc_ledgers.id
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_aec_name` (`name`),
    CONSTRAINT `fk_lib_aec_fineType`       FOREIGN KEY (`fine_type_id`)        REFERENCES `lib_fine_type`(`id`),
    CONSTRAINT `fk_lib_aec_fineSlabConfig` FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    CONSTRAINT `fk_lib_aec_accountGroup`   FOREIGN KEY (`account_group_id`)    REFERENCES `acc_account_groups`(`id`),
    CONSTRAINT `fk_lib_aec_ledger`         FOREIGN KEY (`ledger_id`)            REFERENCES `acc_ledgers`(`id`),
    UNIQUE KEY `uq_lib_aec_fineType_SlabConf_accGrp_ledger` (`fine_type_id`, `fine_slab_config_id`, `account_group_id`, `ledger_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.5 : Library Status Master
  -- F-002 fix: All ENUM values now use single-quoted strings; "Inventry" typo fixed; added Digital Resource Status and Digital Access Transaction Status
  -- F-038 fix: Renamed unique key from uq_accounting_status_code to uq_lib_status_typeCode
  CREATE TABLE IF NOT EXISTS `lib_library_status_masters` (
    `id`          SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `status_type` ENUM('Book Status','Member Status','Transaction Status','Reservation Status','Fine Status','Inventory Audit Status','Inventory Audit Detail Status','Digital Resource Status','Digital Access Transaction Status') NOT NULL,
    `code`        VARCHAR(20)  NOT NULL,  -- e.g. 'Available', 'Issued', 'Pending'
    `name`        VARCHAR(100) NOT NULL,  -- e.g. 'Available', 'Issued', 'Pending'
    `is_system`   TINYINT(1)   NOT NULL DEFAULT 0,  -- Cannot be deleted / edited
    `is_active`   TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP    NULL,
    UNIQUE KEY `uq_lib_statusMaster_StatusType_Code` (`status_type`, `code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    COMMENT='Generic master for dynamic status codes across modules; allows adding new statuses without code changes';

  -- Data seed for lib_library_status_masters:
  	-- Status Type                                                             Code
		-- ---------------------------------------------------------------------   ----------------------------------------------------------------------------------
		-- `lib_book_copies` (Book Status)                                       : 'Available', 'Issued', 'Reserved', 'Under_Maintenance', 'Lost', 'Withdrawn'
    -- `lib_digital_resources` (Digital Resource Status)                     : 'Available', 'License Consumed', 'License Expired'
		-- `lib_members` (Member Status)                                         : 'Active', 'Expired', 'Suspended', 'Deactivated'
		-- `lib_transactions` (Transaction Status)                               : 'Issued', 'Returned', 'Overdue', 'Lost'
    -- `lib_reservations` (Reservation Status)                               : 'Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired'
    -- `lib_digital_access_requests` (Digital Access Request Status)         : 'Pending', 'Approved', 'Rejected', 'Withdrawn'
		-- `lib_fines` (Fine Status)                                             : 'Pending', 'Paid', 'Waived', 'Overdue'
    -- `lib_inventory_audit` (Inventry Audit Status)                         : 'In Progress', 'Completed', 'Cancelled'
    -- `lib_inventory_audit_details` (Inventory Audit Detail Status)         : 'Found', 'Missing', 'Misplaced', 'Damaged'
    -- `lib_digital_access_transactions` (Digital Access Transaction Status) : Active, Expired, Revoked, Completed


-- ----------------------------------------------------------------------------
-- Sub-Menu 4. ACQUISITION & CATALOGING
-- ----------------------------------------------------------------------------
-- Tab-4.1 : Book Master Creation
-- F-016 fix: cover_image_media_id changed from VARCHAR(500) to INT UNSIGNED NULL with FK to sys_media
-- F-026 fix: tags → tags_json, key_concepts → key_concepts_json, awards TEXT → awards_json JSON
-- F-037 fix: popularity_rank changed from TINYINT UNSIGNED to MEDIUMINT UNSIGNED
-- F-004 fix: FK references now use (id) not (publisher_id) / (resource_type_id)
  CREATE TABLE IF NOT EXISTS `lib_books_master` (
    `id`                         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `title`                      VARCHAR(500) NOT NULL,               -- Main title of the book
    `subtitle`                   VARCHAR(500),                        -- Subtitle if applicable
    `edition`                    VARCHAR(50),                         -- Edition information (e.g., '2nd', 'Revised')
    `isbn`                       VARCHAR(20) UNIQUE,                  -- International Standard Book Number (13 digits)
    `issn`                       VARCHAR(20),                         -- International Standard Serial Number (for journals)
    `doi`                        VARCHAR(100),                        -- Digital Object Identifier
    `publication_year`           SMALLINT UNSIGNED,                   -- Year of publication
    `publisher_id`               INT UNSIGNED NOT NULL,               -- FK to lib_publishers.id
    `language`                   INT UNSIGNED NOT NULL,               -- FK to sys_dropdown_table.id
    `page_count`                 INT CHECK (page_count > 0),          -- Total number of pages
    `summary`                    TEXT NULL,                           -- Brief summary/abstract
    `table_of_contents`          TEXT NULL,                           -- Structured table of contents
    `cover_image_media_id`       INT UNSIGNED NULL,                   -- FK to sys_media.id
    `resource_type_id`           SMALLINT UNSIGNED NOT NULL,          -- FK to lib_resource_types.id
    `is_reference_only`          TINYINT(1) NOT NULL DEFAULT 0,       -- Whether book cannot be borrowed (in-library use only)
    -- Analytics
    `lexile_level`               VARCHAR(20) NULL,                    -- Reading difficulty level e.g. 'Level 3'
    `reading_age_range`          VARCHAR(20) NULL,                    -- Recommended reading age range (e.g., '8-12 years')
    `awards_json`                JSON NULL,                           -- List of awards won by the book (was awards TEXT)
    `series_name`                VARCHAR(200) NULL,                   -- Series name if book is part of a series
    `series_position`            TINYINT UNSIGNED NULL,               -- Position of the book within the series
    `popularity_rank`            MEDIUMINT UNSIGNED NULL,             -- Popularity rank (was TINYINT UNSIGNED, max 255)
    `academic_rating`            DECIMAL(3,2) NULL,                   -- Rating by faculty
    `student_rating`             DECIMAL(3,2) NULL,                   -- Average student rating
    `rating_count`               INT DEFAULT 0,                       -- Number of ratings received
    `curricular_relevance_score` DECIMAL(5,2) NOT NULL DEFAULT 0.00,  -- Curricular relevance score
    `tags_json`                  JSON NULL,                           -- Auto-generated tags from AI analysis (was tags)
    `ai_summary`                 TEXT NULL,                           -- AI-generated summary
    `key_concepts_json`          JSON NULL,                           -- Key concepts extracted from the book (was key_concepts)
    `is_available`               TINYINT(1) NOT NULL DEFAULT 1,       -- Whether the book is currently available (cached, updated by trigger)
    -- Audit
    `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,       -- Whether this title is currently active
    `created_at`                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                 TIMESTAMP NULL,
    CONSTRAINT `fk_lib_booksM_publisherId`       FOREIGN KEY (`publisher_id`)       REFERENCES `lib_publishers`(`id`),
    CONSTRAINT `fk_lib_booksM_resourceTypeId`    FOREIGN KEY (`resource_type_id`)   REFERENCES `lib_resource_types`(`id`),
    CONSTRAINT `fk_lib_booksM_coverImageMediaId` FOREIGN KEY (`cover_image_media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lib_booksM_language`          FOREIGN KEY (`language`)             REFERENCES `sys_dropdown_table`(`id`),
    INDEX `idx_lib_book_title` (`title`(191)),
    INDEX `idx_lib_book_isbn` (`isbn`),
    INDEX `idx_lib_book_year` (`publication_year`),
    INDEX `idx_lib_book_active` (`is_active`),
    INDEX `idx_lib_book_publisher` (`publisher_id`),
    FULLTEXT INDEX `ft_lib_book_search` (`title`, `subtitle`, `summary`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- If `is_reference_only` = 1, then book can not be borrowed (in-library use only).
  -- Show Book Status from Field 'is_available' in Book Master.
  -- Create Data in Table 'dropdown_table' for `language`

  -- Junction table to link books with their authors (many-to-many).
  -- F-004 fix: FK references lib_books_master(id) and lib_authors(id)
  -- Other fix: book_id and author_id changed to INT UNSIGNED NOT NULL
  CREATE TABLE IF NOT EXISTS `lib_book_author_jnt` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`      INT UNSIGNED NOT NULL,                 -- FK to lib_books_master.id
    `author_id`    INT UNSIGNED NOT NULL,                 -- FK to lib_authors.id
    `author_order` INT NOT NULL DEFAULT 1,                -- Display order of authors (1 = first)
    `is_primary`   TINYINT(1) NOT NULL DEFAULT 0,         -- Whether this is the primary author
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookAuthorJnt_bookId`   FOREIGN KEY (`book_id`)   REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookAuthorJnt_authorId` FOREIGN KEY (`author_id`) REFERENCES `lib_authors`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_bookAuthorJnt_book_author` (`book_id`, `author_id`, `author_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their categories (many-to-many).
  -- F-004 fix: FK references use (id); book_id/category_id changed to INT UNSIGNED
  CREATE TABLE IF NOT EXISTS `lib_book_category_jnt` (
    `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`     INT UNSIGNED NOT NULL,                   -- FK to lib_books_master.id
    `category_id` INT UNSIGNED NOT NULL,                   -- FK to lib_categories.id
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookCategoryJnt_bookId`     FOREIGN KEY (`book_id`)     REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookCategoryJnt_categoryId` FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_bookCategory_book_category` (`book_id`, `category_id`),
    INDEX `idx_lib_bookCategoryJnt_categoryId` (`category_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their genres (many-to-many).
  -- F-004 fix: FK references use (id)
  CREATE TABLE IF NOT EXISTS `lib_book_genre_jnt` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`    INT UNSIGNED NOT NULL,                   -- FK to lib_books_master.id
    `genre_id`   INT UNSIGNED NOT NULL,                   -- FK to lib_genres.id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookGenreJnt_bookId`  FOREIGN KEY (`book_id`)  REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookGenreJnt_genreId` FOREIGN KEY (`genre_id`) REFERENCES `lib_genres`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_bookGenreJnt_book_genre` (`book_id`, `genre_id`),
    INDEX `idx_genre_book` (`genre_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their subjects (many-to-many).
  -- F-004 fix: FK references use (id); all INT NOT NULL → INT UNSIGNED NOT NULL
  CREATE TABLE IF NOT EXISTS `lib_book_subject_jnt` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`    INT UNSIGNED NOT NULL,                   -- FK to lib_books_master.id
    `class_id`   INT UNSIGNED NOT NULL,                   -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL,                   -- FK to sch_subjects.id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookSubjectJnt_bookId`    FOREIGN KEY (`book_id`)    REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookSubjectJnt_classId`   FOREIGN KEY (`class_id`)   REFERENCES `sch_classes`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookSubjectJnt_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_bookSubjectJnt_book_class_subject` (`book_id`, `class_id`, `subject_id`),
    INDEX `idx_lib_bookSubjectJnt_Class_subject_book` (`class_id`, `subject_id`, `book_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their keywords (many-to-many).
  -- F-004 fix: FK references use (id); INT NOT NULL → INT UNSIGNED NOT NULL
  CREATE TABLE IF NOT EXISTS `lib_book_keyword_jnt` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`    INT UNSIGNED NOT NULL,                                            -- FK to lib_books_master.id
    `keyword_id` INT UNSIGNED NOT NULL,                                            -- FK to lib_keywords.id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookKeywordJnt_bookId`    FOREIGN KEY (`book_id`)    REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookKeywordJnt_keywordId` FOREIGN KEY (`keyword_id`) REFERENCES `lib_keywords`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_bookKeywordJnt_book_keyword` (`book_id`, `keyword_id`),
    INDEX `idx_bookKeywordJnt_keyword` (`keyword_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tab-4.2 : Book Acquisition (Purchase)
-- F-001 fix: Removed orphan FK constraints for book_id/resource_type_id/book_copy_id/digital_resource_id
--            that referenced non-existent columns in lib_book_purchases header table.
--            These columns + FKs belong ONLY in lib_book_purchases_items.
--            Kept only vendor_id FK (corrected reference to vnd_vendors(id)).
--            Removed INDEX idx_book_id which referenced a non-existent column.
  CREATE TABLE IF NOT EXISTS `lib_book_purchases` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `vendor_id`    INT UNSIGNED NOT NULL,             -- FK to vnd_vendors.id (supplier/vendor)
    `bill_no`      VARCHAR(50) NULL,                  -- Vendor Invoice No
    `bill_date`    DATE NOT NULL,                     -- Date when copy was purchased
    `bill_amt`     DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total cost of all copies
    `bill_tax_amt` DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Total Tax amount
    `bill_net_amt` DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total cost including Tax amount
    `notes`        VARCHAR(150) NULL,                 -- Any note related to Purchase
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookPurchase_vendorId` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE RESTRICT,
    INDEX `idx_lib_bookPurchase_vendorId` (`vendor_id`),
    INDEX `idx_lib_bookPurchase_billDate` (`bill_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Check `resource_type_id` in lib_resource_types master table and showcase on screen whether the Item is physical or digital.

  -- F-006 fix: Renamed all FK constraints to fk_bookPurchItems_* to avoid duplicate constraint names
  -- F-004 fix: All FK references now use (id)
  CREATE TABLE IF NOT EXISTS `lib_book_purchases_items` (
    `id`                   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_purchase_id`     INT UNSIGNED NOT NULL,             -- FK to lib_book_purchases.id
    `book_id`              INT UNSIGNED NOT NULL,             -- FK to lib_books_master.id
    `resource_type_id`     SMALLINT UNSIGNED NOT NULL,        -- FK to lib_resource_types.id
    `book_copy_id`         INT UNSIGNED NULL,                 -- FK to lib_book_copies.id (updated after copy created)
    `digital_resource_id`  INT UNSIGNED NULL,                 -- FK to lib_digital_resources.id (updated after resource created)
    `book_price`           DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Purchase cost per unit
    `book_quantity`        INT NOT NULL DEFAULT 1,            -- Number of copies purchased
    `book_amt`             DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total cost (Price x Quantity) (Auto calculated)
    `book_tax_head`        VARCHAR(50) NULL,                  -- What type of tax
    `book_tax_percent`     DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Tax % on the Book (if any)
    `book_tax_amt`         DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Book Tax amount (Auto calculated)
    `book_net_amt`         DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total Book cost including Tax (Auto calculated = `book_amt` + `book_tax_amt`)
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookPurchItems_purchId`    FOREIGN KEY (`book_purchase_id`)    REFERENCES `lib_book_purchases`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookPurchItems_bookId`     FOREIGN KEY (`book_id`)             REFERENCES `lib_books_master`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_lib_bookPurchItems_resTypeId`  FOREIGN KEY (`resource_type_id`)    REFERENCES `lib_resource_types`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_bookPurchItems_copyId`   FOREIGN KEY (`book_copy_id`)        REFERENCES `lib_book_copies`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_bookPurchItems_digResId`  FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE SET NULL;
    INDEX `idx_lib_bookPurchItems_purchaseId` (`book_purchase_id`),
    INDEX `idx_lib_bookPurchItems_bookId` (`book_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Check `resource_type_id` in lib_resource_types master table and showcase on screen whether it is physical or digital.


-- Tab-4.3 : Book Copy Management
-- F-007 fix: idx_copy_status now uses (status, is_active) — removed non-existent is_deleted column
-- F-008 fix: removed duplicate idx_book_id
-- F-039 fix: UNIQUE KEY names changed from unique_* to uq_* prefix
-- F-004 fix: All FK references now use (id)
  CREATE TABLE IF NOT EXISTS `lib_book_copies` (
    `id`                   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`              INT UNSIGNED NOT NULL,          -- FK to lib_books_master.id
    `accession_number`     VARCHAR(50) NOT NULL,           -- Institution's unique accession number
    `barcode`              VARCHAR(100) NOT NULL,          -- Scannable barcode for circulation
    `rfid_tag`             VARCHAR(100) NULL,              -- RFID tag identifier if used
    `shelf_location_id`    INT UNSIGNED NULL,              -- FK to lib_shelf_locations.id
    `current_condition_id` INT UNSIGNED NOT NULL,          -- FK to lib_book_conditions.id (Will Update on Purchase & Receive)
    `book_purchase_id`     INT UNSIGNED NULL,              -- FK to lib_book_purchases.id
    `is_lost`              TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is reported lost; cannot be issued
    `is_damaged`           TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is damaged
    `is_withdrawn`         TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is withdrawn from collection
    `withdrawal_reason`    VARCHAR(512),                   -- Reason for withdrawal
    `status`               SMALLINT UNSIGNED NOT NULL,     -- FK to lib_library_status_masters.id
    `current_due_date`     DATE NULL,                      -- Current due date (When Book will be issued then this date will be updated)
    `notes`                TEXT,
    `is_active`            TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    INDEX `idx_lib_bookCopy_book` (`book_id`),
    INDEX `idx_lib_bookCopy_barcode` (`barcode`),
    INDEX `idx_lib_bookCopy_accession` (`accession_number`),
    INDEX `idx_lib_bookCopy_location` (`shelf_location_id`),
    INDEX `idx_lib_bookCopy_status_active` (`status`, `is_active`),
    INDEX `idx_lib_bookCopy_condition` (`current_condition_id`),
    UNIQUE KEY `uq_lib_bookCopy_barcode`    (`barcode`),
    UNIQUE KEY `uq_lib_bookCopy_accession`  (`accession_number`),
    UNIQUE KEY `uq_lib_bookCopy_rfid`       (`rfid_tag`),
    CONSTRAINT `fk_lib_bookCopy_bookId`           FOREIGN KEY (`book_id`)              REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_bookCopy_shelfLocationId`  FOREIGN KEY (`shelf_location_id`)    REFERENCES `lib_shelf_locations`(`id`),
    CONSTRAINT `fk_lib_bookCopy_conditionId`      FOREIGN KEY (`current_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_bookCopy_purchaseId`        FOREIGN KEY (`book_purchase_id`)     REFERENCES `lib_book_purchases`(`id`),
    CONSTRAINT `fk_lib_bookCopy_status`            FOREIGN KEY (`status`)               REFERENCES `lib_library_status_masters`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- When Issue/Approving Renewal Request -> Update current_condition in lib_book_copies.
  -- When Issue/Approving Renewal Request -> Update `current_due_date` in lib_book_copies.
  -- When Issue/Return Book -> Update 'current_condition' & 'Status' in lib_book_copies.

  -- Historical condition log per book copy for tracking wear and damage over time.
  -- F-005 fix: Fixed CONSTRAINT FOREIGN KEY syntax (was CONSTRAINT FOREIGN KEY (colname), now CONSTRAINT fk_name FOREIGN KEY (colname))
  -- F-004 fix: All FK references now use (id)
  CREATE TABLE IF NOT EXISTS `lib_book_condition_jnt` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `date`         DATE NOT NULL,               -- Date when condition was assessed
    `book_id`      INT UNSIGNED NOT NULL,        -- FK to lib_books_master.id
    `book_copy_id` INT UNSIGNED NOT NULL,        -- FK to lib_book_copies.id
    `condition_id` INT UNSIGNED NOT NULL,        -- FK to lib_book_conditions.id
    `note`         VARCHAR(255),                -- Additional notes about this condition assessment
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookCondJnt_bookId`   FOREIGN KEY (`book_id`)      REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookCondJnt_copyId`   FOREIGN KEY (`book_copy_id`) REFERENCES `lib_book_copies`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookCondJnt_condId`   FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`id`) ON DELETE CASCADE,
    INDEX `idx_lib_bookCondJnt_book_copy_date_cond` (`book_id`, `book_copy_id`, `date`, `condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- This table will have an Entry Record every time on Book Receiving (Return) & Purchase (Receive)
  -- Also Book condition will be updated in `lib_book_copies`

-- Tab-4.4 : Digital Resource Management
-- F-024 fix: license_count changed from TINYINT NOT NULL DEFAULT 0 to SMALLINT UNSIGNED NULL DEFAULT NULL
-- F-025 fix: file_size_bytes changed from INT UNSIGNED to BIGINT UNSIGNED
-- F-004 fix: FK references now use (id)
-- Cross-module fix: file_media_id now references sys_media(id) (not media_files)
  CREATE TABLE IF NOT EXISTS `lib_digital_resources` (
    `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`               INT UNSIGNED NOT NULL,           -- FK to lib_books_master.id
    `file_name`             VARCHAR(255) NOT NULL,           -- Original file name
    `file_media_id`         INT UNSIGNED DEFAULT NULL,       -- FK to sys_media.id for stored file
    `file_path`             VARCHAR(500) NOT NULL,           -- Storage path or URL
    `file_size_bytes`       BIGINT UNSIGNED NOT NULL,        -- F-025: Size of the file in bytes (was INT UNSIGNED)
    `mime_type`             VARCHAR(100) NULL,                    -- MIME type (e.g., 'application/pdf')
    `file_format`           VARCHAR(50) NULL,                     -- Format (e.g., 'PDF', 'EPUB', 'MP3')
    `can_student_download`  TINYINT(1) NOT NULL DEFAULT 1,   -- Whether students can download
    `can_teacher_download`  TINYINT(1) NOT NULL DEFAULT 1,   -- Whether teachers can download
    `can_staff_download`    TINYINT(1) NOT NULL DEFAULT 1,   -- Whether other staff can download
    `download_count`        INT UNSIGNED NOT NULL DEFAULT 0, -- Number of times downloaded
    `view_count`            INT UNSIGNED NOT NULL DEFAULT 0, -- Number of times viewed online
    -- OPTIONAL FIELDS
    `license_key`           VARCHAR(100) NULL,                    -- License identifier if applicable
    `license_type`          VARCHAR(50) NULL,                     -- Type of license (e.g., 'Single User', 'Concurrent', 'Site')
    `license_start_date`    DATE NULL,                            -- License validity start date
    `license_end_date`      DATE NULL,                            -- License validity end date
    `license_count`         SMALLINT UNSIGNED NULL DEFAULT NULL COMMENT 'Number of concurrent licenses. NULL = unlimited.',  -- F-024
    --
    `status`                SMALLINT UNSIGNED NOT NULL,      -- FK to lib_library_status_masters.id
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    CONSTRAINT `fk_lib_digitalRes_bookId`      FOREIGN KEY (`book_id`)       REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_digitalRes_fileMediaId` FOREIGN KEY (`file_media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lib_digitalRes_status`      FOREIGN KEY (`status`)        REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_digitalRes_book` (`book_id`),
    INDEX `idx_lib_digitalRes_licensePeriod` (`license_start_date`, `license_end_date`),
    INDEX `idx_lib_digitalRes_active` (`is_active`),
    FULLTEXT INDEX `ft_lib_digitalRes_search` (`file_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- If `license_count` IS NOT NULL then the number of concurrent access is limited to `license_count`.
  -- If `license_count` IS NULL then access is unlimited.


  -- NT-003 fix (F-015): lib_digital_access_request_types — referenced table, now defined
  -- Must come before lib_digital_access_requests which FKs to it
  CREATE TABLE IF NOT EXISTS `lib_digital_access_request_types` (
    `id`          SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`        VARCHAR(30) NOT NULL,   -- Access Request Type e.g. 'Download', 'View_Online', 'Withdrawal'
    `name`        VARCHAR(100) NOT NULL,
    `description` VARCHAR(255) NULL,
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_digAccReqType_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Other fix: FK references lib_digital_resources(id); added updated_at and deleted_at
  CREATE TABLE IF NOT EXISTS `lib_digital_resource_tags` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `digital_resource_id` INT UNSIGNED NOT NULL,                        -- FK to lib_digital_resources.id
    `tag_name`            VARCHAR(100) NOT NULL,                        -- Tag text (e.g., 'interactive', 'video-lecture')
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `fk_lib_digitalResTags_digResId` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_digResTags_resourceId_tagName` (`digital_resource_id`, `tag_name`),
    INDEX `idx_lib_digResTags_tagName` (`tag_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ----------------------------------------------------------------------------
-- Sub-Menu 5. MEMBER & ACCESS MANAGEMENT
-- ----------------------------------------------------------------------------

  -- Tab-5.1 : Defines different types of library memberships with associated privileges and rules.
  -- F-013 fix: Removed trailing comma before closing )
  -- F-023 fix: CHECK on max_books_allowed now correctly references max_books_allowed (not loan_period_days)
  CREATE TABLE IF NOT EXISTS `lib_membership_types` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`                VARCHAR(30) NOT NULL UNIQUE,                                       -- Business code (e.g., 'STD_STUDENT', 'PREMIUM_STAFF')
    `name`                VARCHAR(100) NOT NULL,                                             -- Display name (e.g., 'Standard Student', 'Premium Staff')
    `max_books_allowed`   TINYINT UNSIGNED NOT NULL CHECK (max_books_allowed > 0),           -- F-023: Maximum number of books a member can borrow simultaneously
    `loan_period_days`    TINYINT UNSIGNED NOT NULL CHECK (loan_period_days > 0),            -- Standard loan duration in days
    `renewal_allowed`     TINYINT(1) DEFAULT 1,                                              -- Whether members can renew books
    `max_renewals`        TINYINT UNSIGNED NOT NULL DEFAULT 0,                               -- Maximum number of times a book can be renewed
    -- `fine_rate_per_day`   DECIMAL(8,2) NOT NULL DEFAULT 0.00 CHECK (fine_rate_per_day >= 0), -- Daily fine amount for late returns
    `grace_period_days`   TINYINT UNSIGNED NOT NULL DEFAULT 0,                               -- Days after due date before fines start
    `priority_level`      TINYINT UNSIGNED NOT NULL DEFAULT 1,                               -- Priority for reservations (higher = better)
    `digital_access_days` TINYINT UNSIGNED NOT NULL DEFAULT 0,                               -- How many days digital resource access is provided
    `can_restricted_members_view_list` TINYINT(1) DEFAULT 0,                                 -- If 0, restricted members cannot view Book List
    `is_active`           TINYINT(1) DEFAULT TRUE,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    INDEX `idx_lib_membershipType_active` (`is_active`),
    INDEX `idx_lib_membershipType_priority` (`priority_level`),
    UNIQUE KEY `uq_lib_membershipType_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition on Table lib_membership_types :
    -- When Student tries to request a Book, check max_books_allowed. If limit reached, show "Reached Limit".
    -- When Book Issue, check max_books_allowed. If limit reached, show "Reached Limit".
    -- Check whether user is a Member. If not, show "You are not Authorized to issue Book".
    -- If can_restricted_members_view_list is 0, then Restricted Members cannot see the Book List.

  -- Tab-5.2 : Library Members
  -- F-004 fix: FK references use (id) not aliased PK names
  -- Cross-module fix: user_id FK now references sys_users(id) consistently
  -- F-040 fix: outstanding_fines is NOT NULL
  CREATE TABLE IF NOT EXISTS `lib_members` (
    `id`                              INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `user_id`                         INT UNSIGNED NOT NULL,                -- FK to sys_users.id
    `membership_type_id`              INT UNSIGNED NOT NULL,                -- FK to lib_membership_types.id
    `user_type`                       ENUM('Student', 'Teacher', 'Staff') NOT NULL,
    `membership_number`               VARCHAR(50) NOT NULL,                 -- Unique library membership number
    `library_card_barcode`            VARCHAR(100) NOT NULL,                -- Barcode on physical library card
    `registration_date`               DATE NOT NULL,                        -- Date of membership registration
    `expiry_date`                     DATE NOT NULL,                        -- Membership expiry date
    `is_icard_auto_renew`             TINYINT(1) NOT NULL DEFAULT 1,        -- Whether library card is auto-renewed
    `last_activity_date`              DATE NULL,                            -- Last library activity date
    `total_books_borrowed`            INT NOT NULL DEFAULT 0,               -- Lifetime total books borrowed
    `total_fines_paid`                DECIMAL(10,2) DEFAULT 0.00,           -- Lifetime fines paid
    `outstanding_fines`               DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (outstanding_fines >= 0),  -- F-040: NOT NULL added
    `status`                          SMALLINT UNSIGNED NOT NULL,           -- FK to lib_library_status_masters.id
    `suspension_reason`               TEXT NULL,
    `notes`                           TEXT NULL,
    -- Analytics
    `reading_level`                   ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NULL,
    `preferred_notification_channel`  ENUM('Email', 'SMS', 'Push', 'InApp') DEFAULT 'InApp',
    `member_segment`                  VARCHAR(50) COMMENT 'e.g., High-Value, At-Risk, Inactive, New',
    `segment_updated_on`              TIMESTAMP NULL,             -- Last time segment was updated
    `engagement_score`                DECIMAL(5,2) DEFAULT 0.00,  -- This is a mannually calculated value, needs to be updated by Library Team
    `churn_risk_score`                DECIMAL(5,2) DEFAULT 0.00,  -- This is a mannually calculated value, needs to be updated by Library Team
    `lifetime_value`                  DECIMAL(10,2) DEFAULT 0.00, -- This is a mannually calculated value, needs to be updated by Library Team
    `preferred_language`              INT UNSIGNED NOT NULL,               -- FK to sys_dropdown_table.id
    `reading_goal_annual`             INT DEFAULT 0,              -- This is a mannually calculated value, needs to be updated by Library Team
    `reading_progress_ytd`            INT DEFAULT 0,              -- This is a mannually calculated value, needs to be updated by Library Team
    -- System
    `is_active`                       TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`                      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                      TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_member_user`                 (`user_id`),
    UNIQUE KEY `uq_lib_member_membership_number`    (`membership_number`),
    UNIQUE KEY `uq_lib_member_library_card_barcode` (`library_card_barcode`),
    CONSTRAINT `fk_lib_members_userId`         FOREIGN KEY (`user_id`)           REFERENCES `sys_users`(`id`),
    CONSTRAINT `fk_lib_members_membershipType` FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    CONSTRAINT `fk_lib_members_status`         FOREIGN KEY (`status`)             REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_member_membership` (`membership_type_id`),
    INDEX `idx_lib_member_status` (`status`, `expiry_date`),
    INDEX `idx_lib_member_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition on Table lib_members :
-- Use same Dropdown Table for Language Field as used for lib_books_master
-- Whenever Member will do any Activity then `last_activity_date` will be updated for him.
-- Whenever Memeber will Borrow (Book Issue) any Book app will update `total_books_borrowed`, `total_fines_paid`, `outstanding_fines`.



  -- Tab-5.3 : Digital Resource Access Restrictions
  -- F-017 fix: role_id, designation_id, department_id, user_id are now INT UNSIGNED NULL (not NOT NULL)
  --            Added CHECK constraint that at least one is not null
  -- F-004 fix: FK references lib_digital_resources(id)
  -- F-035 fix: Replaced heavy 6-col composite index with narrower focused indexes
  CREATE TABLE IF NOT EXISTS `lib_digital_resource_access_restrictions` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `digital_resource_id` INT UNSIGNED NOT NULL,            -- FK to lib_digital_resources.id
    `role_id`             INT UNSIGNED NULL,                 -- FK to sys_roles.id (NULL = not restricted by role)
    `designation_id`      INT UNSIGNED NULL,                 -- FK to sys_designations.id
    `department_id`       INT UNSIGNED NULL,                 -- FK to sys_departments.id
    `user_id`             INT UNSIGNED NULL,                 -- FK to sys_users.id (NULL = not restricted by user)
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `chk_drar_at_least_one` CHECK (role_id IS NOT NULL OR designation_id IS NOT NULL OR department_id IS NOT NULL OR user_id IS NOT NULL),
    CONSTRAINT `fk_lib_drar_digResId`     FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_drar_roleId`       FOREIGN KEY (`role_id`)             REFERENCES `sys_roles`(`id`),
    CONSTRAINT `fk_lib_drar_designId`     FOREIGN KEY (`designation_id`)      REFERENCES `sys_designations`(`id`),
    CONSTRAINT `fk_lib_drar_deptId`       FOREIGN KEY (`department_id`)       REFERENCES `sys_departments`(`id`),
    CONSTRAINT `fk_lib_drar_userId`       FOREIGN KEY (`user_id`)             REFERENCES `sys_users`(`id`),
    UNIQUE KEY `uq_lib_drar_digRes_userId` (`digital_resource_id`, `user_id`),
    INDEX `idx_lib_drar_resId_active` (`digital_resource_id`, `is_active`),
    INDEX `idx_lib_drar_roleId`       (`role_id`),
    INDEX `idx_lib_drar_userId`       (`user_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions :
  -- Use this table when allowing raising Access Request by Members. Is User/Role/Department/Designation Restricted then he can not raise Request for that Digital_Resource.
  -- Check same condition at the time of Allowing Access Request.

-- ----------------------------------------------------------------------------
-- Sub-Menu 6. OPERATION MANAGEMENT
-- ----------------------------------------------------------------------------

  -- Tab-6.1 : Request for Borrowing / Renewal for a Physical Book.
  -- F-020+F-028 fix: Restored queue_position column; idx_reserve_book now includes it
  -- F-021 fix: is_renewal_reuest → is_renewal_request (typo fixed)
  -- F-004 fix: all FK references use (id)
  -- Other fix: FK for transaction_id now references lib_transactions(id) (not lib_book_transactions)
  CREATE TABLE IF NOT EXISTS `lib_physical_book_requests` (
    `id`                      INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`                 INT UNSIGNED NOT NULL,           -- FK to lib_books_master.id
    `member_id`               INT UNSIGNED NOT NULL,           -- FK to lib_members.id
    `request_date`            DATETIME NOT NULL,               -- Date and time of reservation
    `expected_available_date` DATE NULL,                       -- Estimated date when book will be available (Capture from lib_book_copy.current_due_date)
    `notification_sent`       TINYINT(1) NOT NULL DEFAULT 0,   -- Whether availability notification was sent
    `notification_sent_at`    DATETIME NULL,                   -- When notification was sent
    `pickup_by_date`          DATE NULL,                       -- Date by which member must pick up the book
    `transaction_id`          INT UNSIGNED NULL,               -- Book Issued Transaction ID against this request
    `status`                  SMALLINT UNSIGNED NOT NULL,      -- FK to lib_library_status_masters.id
    `withdrawal_reason`       TEXT NULL,                       -- Reason why he Withdrawn the Request
    `is_renewal_request`      TINYINT(1) NOT NULL DEFAULT 0,   -- F-021: Whether this is a renewal request (was is_renewal_reuest)
    `renewal_days_requested`  TINYINT DEFAULT 0,               -- Number of days requested for renewal
    `renewal_approved`        TINYINT(1) NOT NULL DEFAULT 0,
    `renewal_approved_at`     DATETIME NULL,
    `renewal_approved_by_id`  INT UNSIGNED NULL,               -- FK to sys_users.id
    `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`              TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_reserve_book_member_status` (`book_id`, `member_id`, `status`),
    INDEX `idx_lib_reserve_book_status_queue`   (`book_id`, `status`),
    INDEX `idx_lib_reserve_member_status` (`member_id`, `status`),
    INDEX `idx_lib_reserve_status_date` (`status`, `pickup_by_date`),
    CONSTRAINT `fk_lib_reservation_bookId`       FOREIGN KEY (`book_id`)              REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_reservation_memberId`     FOREIGN KEY (`member_id`)            REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_reservation_status`       FOREIGN KEY (`status`)               REFERENCES `lib_library_status_masters`(`id`),
    CONSTRAINT `fk_lib_reservation_transId` FOREIGN KEY (`transaction_id`)  REFERENCES `lib_transactions`(`id`),
    CONSTRAINT `fk_lib_reservation_approvedById` FOREIGN KEY (`renewal_approved_by_id`) REFERENCES `sys_users`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- Member can request for Renewal; Renewal Request will be Approved by Library Incharge.
    -- Member can also Withdraw the Renewal / Reservation Request.
    -- When raising Renewal Request -> Check renewal_allowed in lib_membership_types; only allowed if renewal_allowed = 1.
    -- When raising Renewal Request -> Check max_renewals in lib_membership_types, then check renewal_count in lib_transactions.
    -- When raising Renewal Request -> Check max_books_allowed in lib_membership_types.
    -- Notification will be sent on below Events :
    -- 1. Member raises Boorwing / Renewal Request - Send message to member (Request Received)
    -- 2. Member withdraws his Request -  Send message to member (WithdrawnRequest Received)
    -- 3. When Book is Returned in the Library - Send message to member (Book Available, please collect)



  -- Tab-6.2 : Book Transactions (Issue, Return, Renewal, etc.)
  -- F-018 fix: Added book_id column with FK to lib_books_master(id)
  -- F-027 fix: Index idx_trans_issued_by now references issued_by_id (not issued_by)
  -- F-004 fix: All FK references now use (id)
  CREATE TABLE IF NOT EXISTS `lib_transactions` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`             INT UNSIGNED NOT NULL,                -- F-018: FK to lib_books_master.id
    `copy_id`             INT UNSIGNED NOT NULL,                -- FK to lib_book_copies.id
    `member_id`           INT UNSIGNED NOT NULL,                -- FK to lib_members.id
    `issue_date`          DATETIME NOT NULL,                    -- Date and time when book was issued
    `due_date`            DATE NOT NULL,                        -- Expected return date
    `return_date`         DATETIME NULL,                        -- Actual return date (NULL if not yet returned)
    `issued_by_id`        INT UNSIGNED NOT NULL,                -- FK to sys_users.id — who issued the book
    `received_by_id`      INT UNSIGNED NULL,                    -- FK to sys_users.id — who received the return
    `issue_condition_id`  INT UNSIGNED NOT NULL,                -- FK to lib_book_conditions.id — condition at issue
    `return_condition_id` INT UNSIGNED NULL,                    -- FK to lib_book_conditions.id — condition at return
    `is_fine_applicable`  TINYINT(1) NOT NULL DEFAULT 0,        -- If `issue_condition_id` != `return_condition_id` OR Book
    `is_renewed`          TINYINT(1) NOT NULL DEFAULT 0,
    `renewal_count`       INT DEFAULT 0,                        -- Number of times renewed
    `status`              SMALLINT UNSIGNED NOT NULL,           -- FK to lib_library_status_masters.id
    `notes`               TEXT,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `fk_lib_trans_bookId`          FOREIGN KEY (`book_id`)             REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_trans_copyId`          FOREIGN KEY (`copy_id`)             REFERENCES `lib_book_copies`(`id`),
    CONSTRAINT `fk_lib_trans_memberId`        FOREIGN KEY (`member_id`)           REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_trans_issuedById`      FOREIGN KEY (`issued_by_id`)        REFERENCES `sys_users`(`id`),
    CONSTRAINT `fk_lib_trans_receivedById`    FOREIGN KEY (`received_by_id`)      REFERENCES `sys_users`(`id`),
    CONSTRAINT `fk_lib_trans_issueCondId`     FOREIGN KEY (`issue_condition_id`)  REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_trans_returnCondId`    FOREIGN KEY (`return_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_trans_status`          FOREIGN KEY (`status`)              REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_trans_book_status`         (`book_id`, `status`),
    INDEX `idx_lib_trans_copy_status`         (`copy_id`, `status`),
    INDEX `idx_lib_trans_member_status`       (`member_id`, `status`),
    INDEX `idx_lib_trans_issueDt_dueDt_retDt` (`issue_date`, `due_date`, `return_date`),
    INDEX `idx_lib_trans_status_dueDt`        (`status`, `due_date`),
    INDEX `idx_lib_trans_issuedById`          (`issued_by_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- When Issue -> Check max_books_allowed in lib_membership_types; if limit exceeded, member cannot issue.
    -- When Return -> Check pending requests in lib_reservations for that book; notify members by queue position (FCFS: First Come First Serve).
    -- e.g. 3 members requested on 10th May & 1 member requested on 12th May. Then, send msg. to all 3 members requested on 10th May and then issue the book the member who come first to collect the book.
    -- Next time when book is returned OR purchased new book, then send msg. to 2 members who requested for the same book on 10th may and then 3rd time send to the last member who requested for the same book on 10th may.
    -- When Renewal -> Check renewal_allowed and max_renewals in lib_membership_types; check renewal_count.
    -- When Renewal -> Check `max_renewals` in `lib_membership_types` master table, and then check `renewal_count` in `lib_transactions` table. If member has reached the limit, then the member cannot renew a book.
    -- When Return -> Check book condition at issue vs return; charge fine if condition degraded.
    -- When Return -> Check grace_period_days before applying fine.


  -- Tab-6.3 : Digital Access Requests
  -- F-015 fix: request_type now has FK to lib_digital_access_request_types(id)
  -- F-004 fix: All FK references use (id)
  CREATE TABLE IF NOT EXISTS `lib_digital_access_requests` (
    `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `request_type`        SMALLINT UNSIGNED NOT NULL,     -- FK to lib_digital_access_request_types.id
    `member_id`           INT UNSIGNED NOT NULL,          -- FK to lib_members.id
    `book_id`             INT UNSIGNED NOT NULL,          -- FK to lib_books_master.id
    `digital_resource_id` INT UNSIGNED DEFAULT NULL,      -- FK to lib_digital_resources.id
    `reason`              TEXT DEFAULT NULL,
    `status`              SMALLINT UNSIGNED NOT NULL,     -- FK to lib_library_status_masters.id
    `reviewed_by_id`      INT UNSIGNED DEFAULT NULL,      -- FK to sys_users.id
    `reviewed_at`         TIMESTAMP NULL DEFAULT NULL,
    `notes`               TEXT DEFAULT NULL,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP NULL DEFAULT NULL,
    `updated_at`          TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_lib_daReq_reqTypeId`        FOREIGN KEY (`request_type`)        REFERENCES `lib_digital_access_request_types`(`id`) ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_daReq_memberId`         FOREIGN KEY (`member_id`)           REFERENCES `lib_members`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_lib_daReq_bookId`           FOREIGN KEY (`book_id`)             REFERENCES `lib_books_master`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_lib_daReq_digitalResourceId` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_daReq_reviewedById`     FOREIGN KEY (`reviewed_by_id`)      REFERENCES `sys_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY `uq_lib_daReq_member_book_status` (`member_id`, `book_id`, `status`),
    INDEX `idx_lib_daReq_member_status` (`member_id`, `status`),
    INDEX `idx_lib_daReq_book_status`   (`book_id`, `status`),
    INDEX `idx_lib_daReq_status_date`   (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- Member can request for digital access; reviewed and approved by Library Incharge.
    -- Member can also Withdraw the request.
    -- Check renewal_allowed, max_renewals, max_books_allowed in lib_membership_types.
    -- Notification will be sent on below Events :
    -- 1. Member raises Access / Renewal Request - Send message to member (Request Received)
    -- 2. Member withdraws his Request -  Send message to member (WithdrawnRequest Received)
    -- 3. When Access is withdrawn for the Book - Send message to member (Your Access for the Book - xxxxxxxx is withdrawn) Need to be handled by Service.
    -- 4. At Approval of Digital Access Request - Send message to member (Request is Approved, please check the access link)


  -- Tab-6.4 : Digital Access Transactions
  -- F-019 already resolved in v4 — copied exactly as-is from v4 (book_id, digital_resource_id, access_request_id present; no access_condition_id)
  -- F-033 already resolved in v4 — no access_condition_id in this table
  CREATE TABLE IF NOT EXISTS `lib_digital_access_transactions` (
    `id`                        INT UNSIGNED    PRIMARY KEY AUTO_INCREMENT,

    -- Core References
    `member_id`                 INT UNSIGNED    NOT NULL,                     -- FK to lib_members.id
    `book_id`                   INT UNSIGNED    NOT NULL,                     -- FK to lib_books_master.id
    `digital_resource_id`       INT UNSIGNED    NOT NULL,                     -- FK to lib_digital_resources.id
    `access_request_id`         INT UNSIGNED    NULL,                         -- FK to lib_digital_access_requests.id (NULL if direct-grant)

    -- Access Window
    `access_type`               ENUM('View_Online', 'Download', 'Stream', 'Read_Online') NOT NULL DEFAULT 'View_Online',
    `access_start_at`           DATETIME        NOT NULL,
    `access_expires_at`         DATETIME        NULL,                         -- NULL = no expiry / permanent
    `last_accessed_at`          DATETIME        NULL,

    -- Download Tracking
    `is_downloaded`             TINYINT(1)      NOT NULL DEFAULT 0,
    `download_count`            SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `first_downloaded_at`       DATETIME        NULL,
    `last_downloaded_at`        DATETIME        NULL,
    `last_download_ip`          VARCHAR(45)     NULL,
    `last_download_device`      ENUM('Desktop', 'Mobile', 'Tablet', 'Kiosk', 'Other') NULL,
    `last_download_user_agent`  VARCHAR(500)    NULL,
    `download_history_json`     JSON            NULL,                         -- [{downloaded_at, ip, device, user_agent}, ...]

    -- Online View Tracking
    `view_count`                SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `total_view_duration_sec`   INT UNSIGNED    NOT NULL DEFAULT 0,
    `last_view_ip`              VARCHAR(45)     NULL,
    `last_view_device`          ENUM('Desktop', 'Mobile', 'Tablet', 'Kiosk', 'Other') NULL,

    -- Access Grant & Revocation
    `granted_by_id`             INT UNSIGNED    NULL,                         -- FK sys_users.id
    `revoked_by_id`             INT UNSIGNED    NULL,                         -- FK sys_users.id
    `revoked_at`                DATETIME        NULL,
    `revocation_reason`         VARCHAR(255)    NULL,

    -- Status & Notes
    `status`                    SMALLINT UNSIGNED NOT NULL,                   -- FK lib_library_status_masters.id
    `notes`                     TEXT            NULL,

    -- Audit
    `created_at`                TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP       NULL,

    -- FK Constraints
    CONSTRAINT `fk_lib_digAccTx_memberId`    FOREIGN KEY (`member_id`)           REFERENCES `lib_members`(`id`)                 ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_digAccTx_bookId`      FOREIGN KEY (`book_id`)             REFERENCES `lib_books_master`(`id`)            ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_digAccTx_digResId`    FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`)       ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_digAccTx_accReqId`    FOREIGN KEY (`access_request_id`)   REFERENCES `lib_digital_access_requests`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_digAccTx_grantedById` FOREIGN KEY (`granted_by_id`)       REFERENCES `sys_users`(`id`)                   ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_digAccTx_revokedById` FOREIGN KEY (`revoked_by_id`)       REFERENCES `sys_users`(`id`)                   ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_digAccTx_status`      FOREIGN KEY (`status`)              REFERENCES `lib_library_status_masters`(`id`),

    -- Indexes
    INDEX `idx_lib_digAccTx_member_status`   (`member_id`, `status`),
    INDEX `idx_lib_digAccTx_book_member`     (`book_id`, `member_id`),
    INDEX `idx_lib_digAccTx_digRes`          (`digital_resource_id`, `status`),
    INDEX `idx_lib_digAccTx_accessReq`       (`access_request_id`),
    INDEX `idx_lib_digAccTx_accessWindow`    (`access_start_at`, `access_expires_at`),
    INDEX `idx_lib_digAccTx_downloaded`      (`is_downloaded`, `download_count`),
    INDEX `idx_lib_digAccTx_lastDownloaded`  (`last_downloaded_at`),
    INDEX `idx_lib_digAccTx_lastDownloadIp`  (`last_download_ip`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions :
  --   One row per granted access window. New row created on re-request after expiry.
  --   download_count increments on every download event; download_history_json appends a new object.
  --   view_count increments when member opens the resource online without downloading.
  --   total_view_duration_sec updated via application on session close (heartbeat approach).
  --   Status transitions: Active → Expired (scheduled job when access_expires_at < NOW())
  --                       Active → Revoked  (manual staff action)
  --                       Active → Completed (member explicitly closes or license consumed)

  -- Tab-6.5 : Fines
  -- F-004 fix: all FK references use (id)
  -- Cross-module fix: waived_by_id FK now references sys_users(id)
  -- Other fix: Added deleted_at
  CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id`                        INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `transaction_id`            INT UNSIGNED NOT NULL,                         -- FK to lib_transactions.id
    `member_id`                 INT UNSIGNED NOT NULL,                         -- FK to lib_members.id
    `fine_type`                 SMALLINT UNSIGNED NOT NULL,                    -- FK to lib_fine_type.id
    `amount`                    DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    `days_overdue`              INT NOT NULL DEFAULT 0,
    `calculated_from`           DATE NOT NULL,
    `calculated_to`             DATE NOT NULL,
    `fine_slab_config_id`       INT UNSIGNED NULL,                             -- FK to lib_fine_slab_config.id
    `calculation_breakdown_json` JSON,                                         -- F-026: was calculation_breakdown
    `waived_amount`             DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),
    `waived_by_id`              INT UNSIGNED NULL,                             -- FK to sys_users.id
    `waived_reason`             TEXT NULL,
    `waived_at`                 DATETIME NULL,
    `status`                    SMALLINT UNSIGNED NOT NULL,                    -- FK to lib_library_status_masters.id
    `notes`                     TEXT,
    `created_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                TIMESTAMP NULL,
    CONSTRAINT `fk_lib_fines_transId`       FOREIGN KEY (`transaction_id`)    REFERENCES `lib_transactions`(`id`),
    CONSTRAINT `fk_lib_vfines_memberId`      FOREIGN KEY (`member_id`)         REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_vfines_waivedById`    FOREIGN KEY (`waived_by_id`)      REFERENCES `sys_users`(`id`),
    CONSTRAINT `fk_lib_fines_fineSlabConf`  FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    CONSTRAINT `fk_lib_fines_status`        FOREIGN KEY (`status`)            REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_fines_transaction` (`transaction_id`),
    INDEX `idx_lib_fines_member`      (`member_id`, `status`),
    INDEX `idx_lib_fines_status`      (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-6.6 : Fine Payments
  -- F-004 fix: fine_id FK now references lib_fines(id) not lib_fines(fine_id)
  -- Cross-module fix: received_by_id now references sys_users(id)
  CREATE TABLE IF NOT EXISTS `lib_fine_payments` (
    `id`                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `fine_id`           INT UNSIGNED NOT NULL,                                  -- FK to lib_fines.id
    `amount_paid`       DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),
    `payment_method`    ENUM('Cash', 'Card', 'Online', 'Waiver') NOT NULL,
    `payment_reference` VARCHAR(100),
    `payment_date`      DATETIME NOT NULL,
    `received_by_id`    INT UNSIGNED NOT NULL,                                  -- FK to sys_users.id
    `receipt_number`    VARCHAR(50) NOT NULL,
    `notes`             TEXT,
    `created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_finePayment_receipt` (`receipt_number`),
    CONSTRAINT `fk_finePayment_fineId`       FOREIGN KEY (`fine_id`)        REFERENCES `lib_fines`(`id`),
    CONSTRAINT `fk_finePayment_receivedById` FOREIGN KEY (`received_by_id`) REFERENCES `sys_users`(`id`),
    INDEX `idx_lib_finePayment_fine`    (`fine_id`),
    INDEX `idx_lib_finePayment_receipt` (`receipt_number`),
    INDEX `idx_lib_finePayment_date`    (`payment_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- Sub-Menu 7. AUDIT AND HISTORY
-- ----------------------------------------------------------------------------

  -- Tab-7.1 : Transaction History
  -- F-009 fix: FK now correctly references performed_by_id (not performed_by)
  -- F-026 fix: old_value → old_value_json, new_value → new_value_json
  -- F-004 fix: FK references lib_transactions(id); sys_users(id) instead of users(id)
  CREATE TABLE IF NOT EXISTS `lib_transaction_history` (
    `id`              INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `transaction_id`  INT UNSIGNED NOT NULL,                  -- FK to lib_transactions.id
    `action_type`     ENUM('issued', 'returned', 'renewed', 'marked_lost', 'condition_updated') NOT NULL,
    `old_value_json`  JSON,                                   -- F-026: Previous values as JSON (was old_value)
    `new_value_json`  JSON,                                   -- F-026: New values as JSON (was new_value)
    `performed_by_id` INT UNSIGNED NOT NULL,                  -- FK to sys_users.id
    `performed_at`    DATETIME DEFAULT CURRENT_TIMESTAMP,
    `notes`           TEXT,
    `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`      TIMESTAMP NULL,
    CONSTRAINT `fk_lib_txHistory_transId`        FOREIGN KEY (`transaction_id`)  REFERENCES `lib_transactions`(`id`),
    CONSTRAINT `fk_lib_txHistory_performedById`  FOREIGN KEY (`performed_by_id`) REFERENCES `sys_users`(`id`),
    INDEX `idx_lib_txHistory_transaction` (`transaction_id`),
    INDEX `idx_lib_txHistory_performed`   (`performed_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-7.2 : Inventory Audit
  -- F-010 fix: FK now correctly references performed_by_id (not performed_by)
  -- F-004 fix: FK references sys_users(id) instead of users(id)
  CREATE TABLE IF NOT EXISTS `lib_inventory_audit` (
    `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `audit_date`       DATE NOT NULL,
    `performed_by_id`  INT UNSIGNED NOT NULL,                 -- FK to sys_users.id
    `total_scanned`    INT DEFAULT 0,
    `total_expected`   INT DEFAULT 0,
    `missing_copies`   INT DEFAULT 0,
    `misplaced_copies` INT DEFAULT 0,
    `damaged_copies`   INT DEFAULT 0,
    `status`           SMALLINT UNSIGNED NOT NULL,            -- FK to lib_library_status_masters.id
    `completed_at`     DATETIME NULL,
    `notes`            TEXT,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       TIMESTAMP NULL,
    CONSTRAINT `fk_lib_invAudit_performedById` FOREIGN KEY (`performed_by_id`) REFERENCES `sys_users`(`id`),
    CONSTRAINT `fk_lib_invAudit_status`        FOREIGN KEY (`status`)          REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_invAudit_date`   (`audit_date`),
    INDEX `idx_lib_invAudit_status` (`status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-7.3 : Inventory Audit Details
  -- F-004 fix: All FK references now use (id)
  -- Note from report (item 7): Added created_at, updated_at, deleted_at
  CREATE TABLE IF NOT EXISTS `lib_inventory_audit_details` (
    `id`                   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `audit_id`             INT UNSIGNED NOT NULL,             -- FK to lib_inventory_audit.id
    `copy_id`              INT UNSIGNED NOT NULL,             -- FK to lib_book_copies.id
    `expected_location_id` INT UNSIGNED NULL,                 -- FK to lib_shelf_locations.id (where copy should be)
    `actual_location_id`   INT UNSIGNED NULL,                 -- FK to lib_shelf_locations.id (where copy was found)
    `scanned_at`           DATETIME NOT NULL,
    `condition_id`         INT UNSIGNED NULL,                 -- FK to lib_book_conditions.id
    `status`               SMALLINT UNSIGNED NOT NULL,        -- FK to lib_library_status_masters.id
    `notes`                TEXT,
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    CONSTRAINT `fk_lib_invAuditDet_auditId`         FOREIGN KEY (`audit_id`)             REFERENCES `lib_inventory_audit`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_invAuditDet_copyId`          FOREIGN KEY (`copy_id`)              REFERENCES `lib_book_copies`(`id`),
    CONSTRAINT `fk_lib_invAuditDet_expLocId`        FOREIGN KEY (`expected_location_id`) REFERENCES `lib_shelf_locations`(`id`),
    CONSTRAINT `fk_lib_invAuditDet_actLocId`        FOREIGN KEY (`actual_location_id`)   REFERENCES `lib_shelf_locations`(`id`),
    CONSTRAINT `fk_lib_invAuditDet_condId`          FOREIGN KEY (`condition_id`)         REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_invAuditDet_status`          FOREIGN KEY (`status`)               REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_invAuditDet_audit` (`audit_id`),
    INDEX `idx_lib_invAuditDet_copy`  (`copy_id`),
    UNIQUE KEY `uq_lib_invAuditDet_audit_copy` (`audit_id`, `copy_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- Sub-Menu 8. ADVANCED ANALYTICS & INSIGHTS
-- ----------------------------------------------------------------------------

  -- Tab-8.1 : Reading Behavior Analytics
  -- F-031 fix: academic_year VARCHAR(20) → academic_year_id INT UNSIGNED NOT NULL FK to academic_years(id)
  -- F-004 fix: All FK references use (id)
  -- F-045 fix: Added updated_at
  CREATE TABLE IF NOT EXISTS `lib_reading_behavior_analytics` (
    `id`                        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `member_id`                 INT UNSIGNED NOT NULL,                    -- FK to lib_members.id
    `academic_year_id`          INT UNSIGNED NOT NULL,                    -- F-031: FK to academic_years.id (was academic_year VARCHAR(20))
    `total_books_read`          INT DEFAULT 0,
    `total_pages_read`          BIGINT DEFAULT 0,
    `avg_reading_days_per_book` DECIMAL(5,2),
    `preferred_genre_id`        INT UNSIGNED NULL,                        -- FK to lib_genres.id
    `preferred_category_id`     INT UNSIGNED NULL,                        -- FK to lib_categories.id
    `preferred_language`        VARCHAR(50),
    `avg_loan_completion_rate`  DECIMAL(5,2) COMMENT 'Percentage of books returned on time',
    `peak_borrowing_month`      INT,
    `peak_borrowing_day`        VARCHAR(20),
    `reading_consistency_score` DECIMAL(5,2) COMMENT '0-100 score based on borrowing regularity',
    `genre_diversity_index`     DECIMAL(5,2) COMMENT 'Shannon diversity index for genres',
    `author_diversity_index`    DECIMAL(5,2),
    `preferred_borrowing_time`  ENUM('Morning', 'Afternoon', 'Evening', 'Weekend'),
    `digital_vs_physical_ratio` DECIMAL(5,2),
    `renewal_frequency`         DECIMAL(5,2) COMMENT 'Average renewals per book',
    `reservation_frequency`     INT DEFAULT 0,
    `reading_speed_estimate`    DECIMAL(5,2) COMMENT 'Estimated pages per day',
    `completion_rate_trend`     DECIMAL(5,2) COMMENT 'Month-over-month trend',
    `last_calculated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- F-045
    CONSTRAINT `fk_lib_readBeh_memberId`       FOREIGN KEY (`member_id`)           REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_readBeh_academicYearId` FOREIGN KEY (`academic_year_id`)    REFERENCES `academic_years`(`id`),
    CONSTRAINT `fk_lib_readBeh_genreId`        FOREIGN KEY (`preferred_genre_id`)  REFERENCES `lib_genres`(`id`),
    CONSTRAINT `fk_lib_readBeh_categoryId`     FOREIGN KEY (`preferred_category_id`) REFERENCES `lib_categories`(`id`),
    INDEX `idx_lib_readBeh_member_academicYear` (`member_id`, `academic_year_id`),
    INDEX `idx_lib_readBeh_genreId`  (`preferred_genre_id`),
    INDEX `idx_lib_readBeh_consistencyScore`  (`reading_consistency_score`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-8.2 : Book Popularity Trends
  -- F-004 fix: FK references lib_books_master(id)
  CREATE TABLE IF NOT EXISTS `lib_book_popularity_trends` (
    `id`                     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`                INT UNSIGNED NOT NULL,                       -- FK to lib_books_master.id
    `tracking_date`          DATE NOT NULL,
    `daily_requests`         INT DEFAULT 0,
    `daily_issues`           INT DEFAULT 0,
    `daily_reservations`     INT DEFAULT 0,
    `daily_digital_views`    INT DEFAULT 0,
    `daily_digital_downloads` INT DEFAULT 0,
    `popularity_score`       DECIMAL(5,2) COMMENT 'Weighted composite score',
    `trend_direction`        ENUM('Rising', 'Falling', 'Stable') DEFAULT 'Stable',
    `velocity_score`         DECIMAL(5,2) COMMENT 'Rate of popularity change',
    `seasonality_factor`     DECIMAL(5,2) COMMENT 'Seasonal adjustment factor',
    `peer_comparison_rank`   INT COMMENT 'Rank among similar books',
    `shelf_turnover_rate`    DECIMAL(5,2) COMMENT 'How often book moves from shelf',
    `waitlist_length`        INT DEFAULT 0,
    `avg_wait_days`          DECIMAL(5,2),
    `recommendation_weight`  DECIMAL(5,2) COMMENT 'Weight for recommendation engine',
    `created_at`             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`             TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_lib_bookPopTrend_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
    UNIQUE KEY `uq_lib_bookPopTrend_bookId_trkDate` (`book_id`, `tracking_date`),
    INDEX `idx_lib_bookPopTrend_date`  (`tracking_date`),
    INDEX `idx_lib_bookPopTrend_popScore` (`popularity_score`),
    INDEX `idx_lib_bookPopTrend_trendDir_velocity` (`trend_direction`, `velocity_score`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-8.3 : Collection Health Metrics
  -- F-036 fix: Added FK constraints for category_id and genre_id
  CREATE TABLE IF NOT EXISTS `lib_collection_health_metrics` (
    `id`                           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `metric_date`                  DATE NOT NULL,
    `category_id`                  INT UNSIGNED NULL,             -- FK to lib_categories.id (NULL = all categories)
    `genre_id`                     INT UNSIGNED NULL,             -- FK to lib_genres.id (NULL = all genres)
    `total_titles`                 INT DEFAULT 0,
    `total_copies`                 INT DEFAULT 0,
    `active_titles`                INT DEFAULT 0,
    `inactive_titles`              INT DEFAULT 0,
    `damaged_copies`               INT DEFAULT 0,
    `lost_copies`                  INT DEFAULT 0,
    `withdrawn_copies`             INT DEFAULT 0,
    `utilization_rate`             DECIMAL(5,2) COMMENT 'Percentage of collection in circulation',
    `turnover_rate`                DECIMAL(5,2) COMMENT 'Average issues per copy',
    `age_of_collection`            DECIMAL(5,2) COMMENT 'Average age in years',
    `collection_diversity_score`   DECIMAL(5,2) COMMENT 'Based on genre/category distribution',
    `relevance_score`              DECIMAL(5,2) COMMENT 'How well collection matches demand',
    `acquisition_effectiveness`    DECIMAL(5,2) COMMENT 'ROI on new acquisitions',
    `weeding_priority_score`       DECIMAL(5,2) COMMENT 'Priority for removal/replacement',
    `budget_allocation_efficiency` DECIMAL(5,2),
    `digital_penetration_rate`     DECIMAL(5,2),
    `physical_vs_digital_ratio`    DECIMAL(5,2),
    `created_at`                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_lib_collHealth_categoryId` FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lib_collHealth_genreId`    FOREIGN KEY (`genre_id`)    REFERENCES `lib_genres`(`id`) ON DELETE SET NULL,
    INDEX `idx_lib_collHealth_date`        (`metric_date`),
    INDEX `idx_lib_collHealth_category`    (`category_id`),
    INDEX `idx_lib_collHealth_genre`       (`genre_id`),
    INDEX `idx_lib_collHealth_utilization` (`utilization_rate`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-8.4 : Predictive Analytics
  -- F-044 fix: Added deleted_at
  -- F-026 fix: features_used → features_used_json
  CREATE TABLE IF NOT EXISTS `lib_predictive_analytics` (
    `id`                      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `prediction_date`         DATE NOT NULL,
    `prediction_type`         ENUM('Demand_Forecast', 'Member_Churn', 'Resource_Optimization', 'Acquisition_Recommendation', 'Seasonal_Pattern', 'Budget_Projection') NOT NULL,
    `target_entity_type`      ENUM('Book', 'Category', 'Genre', 'Member', 'Department', 'All') NOT NULL,
    `target_entity_id`        INT UNSIGNED NULL,
    `prediction_period_start` DATE NOT NULL,
    `prediction_period_end`   DATE NOT NULL,
    `predicted_value`         DECIMAL(10,2) NOT NULL,
    `confidence_score`        DECIMAL(5,2) COMMENT '0-100 confidence level',
    `actual_value`            DECIMAL(10,2),
    `accuracy_score`          DECIMAL(5,2),
    `model_version`           VARCHAR(50),
    `features_used_json`      JSON COMMENT 'Features used in prediction',   -- F-026: was features_used
    `insights`                TEXT,
    `recommendations`         TEXT,
    `is_active`               TINYINT(1) DEFAULT 1,
    `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`              TIMESTAMP NULL,                                -- F-044
    INDEX `idx_lib_predAnalytics_type`       (`prediction_type`, `prediction_date`),
    INDEX `idx_lib_predictive_entity`     (`target_entity_type`, `target_entity_id`),
    INDEX `idx_lib_predictive_period`     (`prediction_period_start`, `prediction_period_end`),
    INDEX `idx_lib_predictive_confidence` (`confidence_score`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-8.5 : Curricular Alignment
  -- F-031 fix: academic_year VARCHAR(20) → academic_year_id INT UNSIGNED NOT NULL FK to academic_years(id)
  -- F-004 fix: All FK references use (id)
  -- Maps books to class/subject/academic-year combinations with alignment scoring, faculty endorsement, and usage tracking, to support curriculum-integrated collection planning.
  CREATE TABLE IF NOT EXISTS `lib_curricular_alignment` (
    `id`                      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `academic_year_id`        INT UNSIGNED NOT NULL,                      -- F-031: FK to academic_years.id (was academic_year VARCHAR)
    `class_id`                INT UNSIGNED NOT NULL,                      -- FK to sch_classes.id
    `subject_id`              INT UNSIGNED NOT NULL,                      -- FK to sch_subjects.id
    `book_id`                 INT UNSIGNED NOT NULL,                      -- FK to lib_books_master.id
    `alignment_score`         DECIMAL(5,2) COMMENT 'How well book aligns with curriculum',
    `recommended_by_faculty`  TINYINT(1) DEFAULT 0,
    `faculty_rating`          DECIMAL(3,2) COMMENT '1-5 rating from faculty',
    `student_usage_count`     INT DEFAULT 0,  -- Number of times students have used this book for this class/subject
    `exam_reference_count`    INT DEFAULT 0,  -- Number of times the book has been referenced in exams
    `assignment_citations`    INT DEFAULT 0,  -- Number of times the book has been cited in assignments
    `curriculum_unit`         VARCHAR(200),   -- Curriculum unit this book supports
    `term_recommended`        ENUM('Term1', 'Term2', 'Term3', 'All'),
    `priority_level`          ENUM('Essential', 'Recommended', 'Supplementary', 'Optional') DEFAULT 'Supplementary',
    `notes`                   TEXT NULL,
    `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_lib_CurrAlign_academicYearId` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years`(`id`),
    CONSTRAINT `fk_lib_CurrAlign_classId`        FOREIGN KEY (`class_id`)         REFERENCES `sch_classes`(`id`),
    CONSTRAINT `fk_lib_CurrAlign_subjectId`      FOREIGN KEY (`subject_id`)       REFERENCES `sch_subjects`(`id`),
    CONSTRAINT `fk_lib_CurrAlign_bookId`         FOREIGN KEY (`book_id`)          REFERENCES `lib_books_master`(`id`),
    UNIQUE KEY `uq_lib_CurrAlign_yesr_class_subject_book` (`academic_year_id`, `class_id`, `subject_id`, `book_id`),
    INDEX `idx_lib_CurrAlign_alignment` (`alignment_score`),
    INDEX `idx_lib_CurrAlign_priority`  (`priority_level`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Brij - We need to showcase this on screen to provide Rating, Recommendations & other Information and also another.
  -- Brij - We need to showcase this on screen on Student Portal t showcase as Recommended Books for Stundets as per their Class and Subjects.
  -- Check in "/Library/Analysis/Calculation_Formulas.md" for 
  -- How to determine `exam_reference_count`?
  -- How to determine `assignment_citations`?



  -- Tab-8.6 : Engagement Events
  -- F-026 fix: filters_used → filters_used_json
  -- F-004 fix: all FK references use (id)
  -- Tracks granular user interactions with the library system for detailed behavior analysis.
  CREATE TABLE IF NOT EXISTS `lib_engagement_events` (
    `id`                   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `member_id`            INT UNSIGNED NOT NULL,                         -- FK to lib_members.id
    `event_type`           ENUM('Search','Browse','View_Details','Add_Reservation','Cancel_Reservation','Renew_Online','Digital_View','Digital_Download','Read_Online','Share_Resource','Add_Review','Rate_Book','Save_To_Wishlist','Request_Purchase','Ask_Librarian','Attend_Event') NOT NULL,
    `book_id`              INT UNSIGNED NULL,                             -- FK to lib_books_master.id (if applicable)
    `digital_resource_id`  INT UNSIGNED NULL,                             -- FK to lib_digital_resources.id (if applicable)
    `search_query`         VARCHAR(500) NULL,
    `filters_used_json`    JSON NULL,                                          -- F-026: was filters_used
    `session_id`           VARCHAR(100) NULL,
    `device_type`          ENUM('Desktop', 'Mobile', 'Tablet', 'Kiosk'),
    `browser`              VARCHAR(50) NULL,
    `ip_address`           VARCHAR(45) NULL,
    `location_id`          INT UNSIGNED NULL COMMENT 'Physical location if in library',
    `time_spent_seconds`   MEDIUMINT UNSIGNED NULL,
    `interaction_outcome`  VARCHAR(255),
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_lib_engEvent_memberId`   FOREIGN KEY (`member_id`)          REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_engEvent_bookId`     FOREIGN KEY (`book_id`)            REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_engEvent_digResId`   FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`),
    INDEX `idx_lib_engEvent_member`  (`member_id`, `created_at`),
    INDEX `idx_lib_engEvent_type`    (`event_type`, `created_at`),
    INDEX `idx_lib_engEvent_book`    (`book_id`),
    INDEX `idx_lib_engEvent_session` (`session_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Condition :
-- we ned to have some plan to remove record from this Table in the future as this is capturing all the events.

-- ----------------------------------------------------------------------------
-- Sub-Menu 9. NEW TABLES (NT-001 to NT-005)
-- ----------------------------------------------------------------------------

  -- NT-001 : Book Reviews & Ratings
  -- Stores individual member ratings and reviews; lib_books_master.student_rating is populated from aggregates here.
  CREATE TABLE IF NOT EXISTS `lib_book_reviews_ratings` (
    `id`             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`        INT UNSIGNED NOT NULL,                        -- FK to lib_books_master.id
    `member_id`      INT UNSIGNED NOT NULL,                        -- FK to lib_members.id
    `transaction_id` INT UNSIGNED NULL,                            -- FK to lib_transactions.id (the transaction that led to this review)
    `rating`         TINYINT UNSIGNED NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
    `review_text`    TEXT NULL,
    `is_faculty`     TINYINT(1) NOT NULL DEFAULT 0,                -- Whether the reviewer is a faculty member
    `is_approved`    TINYINT(1) NOT NULL DEFAULT 0,                -- Moderation flag, whether the review is approved for display
    `approved_by_id` INT UNSIGNED NULL,                            -- FK to sys_users.id, who approved the review (set NULL on delete)
    `approved_at`    TIMESTAMP NULL,
    `is_active`      TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`     TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookReview_bookId`       FOREIGN KEY (`book_id`)        REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookReview_memberId`     FOREIGN KEY (`member_id`)      REFERENCES `lib_members`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookReview_txId`         FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lib_bookReview_approvedById` FOREIGN KEY (`approved_by_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
    UNIQUE KEY `uq_lib_bookReview_member_book` (`book_id`, `member_id`),
    INDEX `idx_lib_bookReview_book`   (`book_id`, `is_approved`),
    INDEX `idx_lib_bookReview_member` (`member_id`),
    INDEX `idx_lib_bookReview_rating` (`rating`, `is_approved`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Brij - We need to create a Fuctionality(screen) to provide Rating` & Review by Faculty, Staff & Students on a particuler Book
  -- Brij - We need to create a Fuctionality(screen) to provide Rating` & Review by Faculty, Staff & Students for a Particuler transaction
  -- Then we need to create a Fuctionality(screen) to Approve the Rating` & Review by Faculty, Staff & Students for a Particuler Book OR Transaction


  -- NT-002 : Member Wishlist
  -- Personal reading wishlist for future borrowing or purchase requests.
  -- Linked to Save_To_Wishlist engagement event type.
  CREATE TABLE IF NOT EXISTS `lib_wishlist` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `member_id`  INT UNSIGNED NOT NULL,                            -- FK to lib_members.id
    `book_id`    INT UNSIGNED NOT NULL,                            -- FK to lib_books_master.id
    `notes`      VARCHAR(255) NULL,
    `priority`   TINYINT UNSIGNED NOT NULL DEFAULT 1,              -- Priority of this wishlist entry
    `is_active`  TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    CONSTRAINT `fk_lib_wishlist_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_wishlist_bookId`   FOREIGN KEY (`book_id`)   REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_wishlist_member_book` (`member_id`, `book_id`),
    INDEX `idx_lib_wishlist_member` (`member_id`, `is_active`),
    INDEX `idx_lib_wishlist_book`   (`book_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Brij - We need to create a Fuctionality(screen) to provide Wishlist by Faculty, Staff & Students. 



  -- NT-003 : Digital Access Request Types (also fixes F-015)
  -- Already placed in Sub-Menu 4 before lib_digital_access_requests to satisfy FK dependency.
  -- (lib_digital_access_request_types defined above near Tab-4.4)


-- Brij - Below tables are Not Required as of Now, We may consider later
-- ---------------------------------------------------------------------

  -- NT-004 : Library Settings — module-level key-value configuration
  CREATE TABLE IF NOT EXISTS `lib_library_settings` (
    `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `academic_year_id` INT UNSIGNED NULL,                          -- NULL = global default; non-null = year-specific override
    `setting_key`      VARCHAR(100) NOT NULL,
    `setting_value`    VARCHAR(500) NOT NULL,
    `value_type`       ENUM('string','integer','decimal','boolean','json') NOT NULL DEFAULT 'string',
    `description`      VARCHAR(255) NULL,
    `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       TIMESTAMP NULL,
    CONSTRAINT `fk_lib_libSettings_academicYearId` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_libSettings_year_key` (`academic_year_id`, `setting_key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- Sub-Menu 10. COMPOSITE INDEXES FOR PERFORMANCE OPTIMIZATION
-- ----------------------------------------------------------------------------
-- F-011 fix: All partial indexes (WHERE clause) removed — MySQL 8 does not support them.
--            Replaced with standard composite indexes for equivalent query coverage.

  -- Overdue transactions: replace partial index WHERE status = 'issued'
  CREATE INDEX `idx_transactions_overdue`   ON `lib_transactions`      (`status`, `due_date`);
  -- Members with outstanding fines
  CREATE INDEX `idx_members_outstanding`    ON `lib_members`           (`outstanding_fines`);
  -- Pending fines
  CREATE INDEX `idx_fines_pending`          ON `lib_fines`             (`status`, `created_at`);
  -- Pending reservations
  CREATE INDEX `idx_reservations_available` ON `lib_reservations`      (`status`, `expected_available_date`, `notification_sent`);
  -- Digital license expiry
  CREATE INDEX `idx_digital_license_expiry` ON `lib_digital_resources` (`license_end_date`);

  -- Composite indexes for reporting
  CREATE INDEX `idx_books_publisher_year`    ON `lib_books_master`   (`publisher_id`, `publication_year`);
  CREATE INDEX `idx_copies_location_status`  ON `lib_book_copies`    (`shelf_location_id`, `status`);
  CREATE INDEX `idx_transactions_member_dates` ON `lib_transactions` (`member_id`, `issue_date`, `return_date`);


-- ----------------------------------------------------------------------------
-- Sub-Menu 11. TRIGGERS FOR DATA INTEGRITY
-- ----------------------------------------------------------------------------

DELIMITER $$

-- Trigger to update member's total borrowed count
-- Fix: Use DECLARE variable with SELECT INTO to get 'Issued' status ID dynamically
CREATE TRIGGER `update_member_borrowed_count`
  AFTER INSERT ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    DECLARE v_issued_status_id SMALLINT UNSIGNED;
    SELECT id INTO v_issued_status_id
      FROM lib_library_status_masters
     WHERE status_type = 'Transaction Status' AND code = 'Issued'
     LIMIT 1;
    IF NEW.status = v_issued_status_id THEN
      UPDATE lib_members
         SET total_books_borrowed = total_books_borrowed + 1,
             last_activity_date = CURDATE()
       WHERE id = NEW.member_id;
    END IF;
  END$$

-- Trigger to update book copy status when a transaction is issued
-- Fix: Use DECLARE/SELECT INTO for status IDs instead of string literals
CREATE TRIGGER `update_copy_status_on_issue`
  AFTER INSERT ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    DECLARE v_issued_tx_status   SMALLINT UNSIGNED;
    DECLARE v_issued_copy_status SMALLINT UNSIGNED;
    SELECT id INTO v_issued_tx_status
      FROM lib_library_status_masters
     WHERE status_type = 'Transaction Status' AND code = 'Issued'
     LIMIT 1;
    SELECT id INTO v_issued_copy_status
      FROM lib_library_status_masters
     WHERE status_type = 'Book Status' AND code = 'Issued'
     LIMIT 1;
    IF NEW.status = v_issued_tx_status THEN
      UPDATE lib_book_copies
         SET status = v_issued_copy_status
       WHERE id = NEW.copy_id;
    END IF;
  END$$

-- Trigger to update book copy status when a transaction is returned
-- Fix: Use DECLARE/SELECT INTO for status IDs
CREATE TRIGGER `update_copy_status_on_return`
  AFTER UPDATE ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    DECLARE v_returned_tx_status   SMALLINT UNSIGNED;
    DECLARE v_available_copy_status SMALLINT UNSIGNED;
    SELECT id INTO v_returned_tx_status
      FROM lib_library_status_masters
     WHERE status_type = 'Transaction Status' AND code = 'Returned'
     LIMIT 1;
    SELECT id INTO v_available_copy_status
      FROM lib_library_status_masters
     WHERE status_type = 'Book Status' AND code = 'Available'
     LIMIT 1;
    IF NEW.status = v_returned_tx_status AND OLD.status != v_returned_tx_status THEN
      UPDATE lib_book_copies
         SET status = v_available_copy_status,
             current_condition_id = NEW.return_condition_id
       WHERE id = NEW.copy_id;
    END IF;
  END$$

-- Event to automatically calculate fines on overdue items (runs daily)
-- Fix: Use subqueries for status IDs; use lib_fine_type code lookup; id references fixed
CREATE EVENT `auto_calculate_fines`
  ON SCHEDULE EVERY 1 DAY
  STARTS CURRENT_DATE
  DO
  BEGIN
    DECLARE v_issued_status   SMALLINT UNSIGNED;
    DECLARE v_pending_status  SMALLINT UNSIGNED;
    DECLARE v_late_fine_type  SMALLINT UNSIGNED;
    SELECT id INTO v_issued_status
      FROM lib_library_status_masters
     WHERE status_type = 'Transaction Status' AND code = 'Issued'
     LIMIT 1;
    SELECT id INTO v_pending_status
      FROM lib_library_status_masters
     WHERE status_type = 'Fine Status' AND code = 'Pending'
     LIMIT 1;
    SELECT id INTO v_late_fine_type
      FROM lib_fine_type
     WHERE code = 'LateReturn'
     LIMIT 1;

    INSERT INTO lib_fines (
      transaction_id, member_id, fine_type, amount,
      days_overdue, calculated_from, calculated_to, status
    )
    SELECT
      t.id,
      t.member_id,
      v_late_fine_type,
      DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day,
      DATEDIFF(CURDATE(), t.due_date),
      t.due_date,
      CURDATE(),
      v_pending_status
    FROM lib_transactions t
    INNER JOIN lib_members m         ON t.member_id = m.id
    INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.id
    WHERE t.status = v_issued_status
      AND t.due_date < CURDATE()
      AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days
      AND NOT EXISTS (
          SELECT 1 FROM lib_fines f
           WHERE f.transaction_id = t.id
             AND f.fine_type = v_late_fine_type
             AND f.status = v_pending_status
      );
  END$$

DELIMITER ;


-- ----------------------------------------------------------------------------
-- Sub-Menu 12. VIEWS FOR COMMON REPORTING
-- ----------------------------------------------------------------------------
-- Fix: All views updated to use correct column references (b.id, r.id, t.id, m.id, c.id)
--      instead of old aliased PK names (b.book_id, r.reservation_id, etc.)
-- Fix: JOIN to sys_users (not users table)

  -- Comprehensive 360-degree view of member engagement and behavior.
  CREATE OR REPLACE VIEW `lib_view_member_360` AS
    SELECT
        m.id                          AS member_id,
        m.membership_number,
        u.first_name,
        u.last_name,
        u.email,
        u.phone,
        mt.name                       AS membership_type,
        m.registration_date,
        m.expiry_date,
        m.status,
        m.total_books_borrowed,
        m.outstanding_fines,
        m.engagement_score,
        m.churn_risk_score,
        m.lifetime_value,
        m.reading_level,
        rba.total_pages_read,
        rba.avg_reading_days_per_book,
        rba.reading_consistency_score,
        rba.genre_diversity_index,
        g.name                        AS preferred_genre,
        rba.preferred_borrowing_time,
        rba.digital_vs_physical_ratio,
        (
            SELECT COUNT(*)
              FROM lib_reservations r
             WHERE r.member_id = m.id
               AND r.status IN (
                   SELECT id FROM lib_library_status_masters
                    WHERE status_type = 'Reservation Status' AND code = 'Pending'
               )
        )                             AS active_reservations,
        (
            SELECT COUNT(*)
              FROM lib_transactions t
             WHERE t.member_id = m.id
               AND t.status IN (
                   SELECT id FROM lib_library_status_masters
                    WHERE status_type = 'Transaction Status' AND code = 'Issued'
               )
        )                             AS currently_borrowed,
        DATEDIFF(CURDATE(), m.last_activity_date) AS days_since_last_activity,
        CASE
            WHEN m.last_activity_date IS NULL               THEN 'New'
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) <= 30  THEN 'Active'
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) <= 90  THEN 'At Risk'
            ELSE 'Inactive'
        END                           AS activity_status
    FROM lib_members m
    INNER JOIN sys_users u              ON m.user_id = u.id
    INNER JOIN lib_membership_types mt  ON m.membership_type_id = mt.id
    LEFT  JOIN lib_reading_behavior_analytics rba
           ON m.id = rba.member_id
          AND rba.academic_year_id = (
              SELECT id FROM academic_years
               WHERE YEAR(CURDATE()) BETWEEN YEAR(start_date) AND YEAR(end_date)
               LIMIT 1
          )
    LEFT  JOIN lib_genres g ON rba.preferred_genre_id = g.id;

  -- Real-time performance metrics for collection management.
  CREATE OR REPLACE VIEW `lib_view_collection_performance` AS
    SELECT
        b.id                          AS book_id,
        b.title,
        b.isbn,
        p.name                        AS publisher,
        rt.name                       AS resource_type,
        COUNT(DISTINCT c.id)          AS total_copies,
        SUM(CASE WHEN cs.code = 'Available' THEN 1 ELSE 0 END) AS available_copies,
        SUM(CASE WHEN cs.code = 'Issued'    THEN 1 ELSE 0 END) AS issued_copies,
        SUM(CASE WHEN cs.code = 'Reserved'  THEN 1 ELSE 0 END) AS reserved_copies,
        SUM(CASE WHEN c.is_lost = 1    THEN 1 ELSE 0 END)      AS lost_copies,
        SUM(CASE WHEN c.is_damaged = 1 THEN 1 ELSE 0 END)      AS damaged_copies,
        COUNT(DISTINCT t.id)          AS total_issues,
        COUNT(DISTINCT CASE WHEN t.return_date IS NULL AND t.due_date < CURDATE() THEN t.id END) AS overdue_count,
        AVG(CASE WHEN t.return_date IS NOT NULL THEN DATEDIFF(t.return_date, t.issue_date) END)  AS avg_loan_days,
        COUNT(DISTINCT r.id)          AS active_reservations,
        AVG(r.queue_position)         AS avg_queue_position,
        b.popularity_rank,
        b.curricular_relevance_score,
        b.student_rating,
        pt.popularity_score,
        pt.trend_direction,
        chm.utilization_rate          AS collection_utilization_rate,
        CASE
            WHEN COUNT(DISTINCT t.id) > 100 THEN 'High Demand'
            WHEN COUNT(DISTINCT t.id) >  50 THEN 'Medium Demand'
            WHEN COUNT(DISTINCT t.id) >  10 THEN 'Low Demand'
            ELSE 'Very Low Demand'
        END                           AS demand_category
    FROM lib_books_master b
    LEFT JOIN lib_publishers p         ON b.publisher_id = p.id
    LEFT JOIN lib_resource_types rt    ON b.resource_type_id = rt.id
    LEFT JOIN lib_book_copies c        ON b.id = c.book_id
    LEFT JOIN lib_library_status_masters cs ON c.status = cs.id
    LEFT JOIN lib_transactions t       ON c.id = t.copy_id
    LEFT JOIN lib_reservations r       ON b.id = r.book_id
          AND r.status IN (
              SELECT id FROM lib_library_status_masters
               WHERE status_type = 'Reservation Status' AND code = 'Pending'
          )
    LEFT JOIN lib_book_popularity_trends pt
           ON b.id = pt.book_id AND pt.tracking_date = CURDATE()
    LEFT JOIN lib_collection_health_metrics chm ON chm.metric_date = CURDATE()
    GROUP BY b.id, b.title, b.isbn, p.name, rt.name, b.popularity_rank,
             b.curricular_relevance_score, b.student_rating,
             pt.popularity_score, pt.trend_direction, chm.utilization_rate;

  -- Predictive demand forecasting for inventory planning.
  CREATE OR REPLACE VIEW `lib_view_predictive_demand` AS
    SELECT
        b.id   AS book_id,
        b.title,
        c.name AS category_name,
        g.name AS genre_name,
        b.publication_year,
        (
            SELECT COUNT(*)
              FROM lib_transactions t
             INNER JOIN lib_book_copies cp ON t.copy_id = cp.id
             WHERE cp.book_id = b.id
               AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        ) AS last_3_months_issues,
        (
            SELECT COUNT(*)
              FROM lib_transactions t
             INNER JOIN lib_book_copies cp ON t.copy_id = cp.id
             WHERE cp.book_id = b.id
               AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
        ) AS last_year_issues,
        pa.predicted_value  AS predicted_next_3_months,
        pa.confidence_score,
        pa.insights,
        pa.recommendations,
        ca.alignment_score  AS curricular_relevance,
        CASE
            WHEN pa.predicted_value > 50 THEN 'Acquire More Copies'
            WHEN pa.predicted_value > 30 THEN 'Monitor Demand'
            WHEN pa.predicted_value > 10 THEN 'Maintain Current'
            ELSE 'Consider Weeding'
        END AS acquisition_recommendation
    FROM lib_books_master b
    LEFT JOIN lib_book_category_jnt bc ON b.id = bc.book_id
    LEFT JOIN lib_categories c         ON bc.category_id = c.id
    LEFT JOIN lib_book_genre_jnt bg    ON b.id = bg.book_id
    LEFT JOIN lib_genres g             ON bg.genre_id = g.id
    LEFT JOIN lib_predictive_analytics pa
           ON b.id = pa.target_entity_id
          AND pa.prediction_type = 'Demand_Forecast'
          AND pa.prediction_date = CURDATE()
    LEFT JOIN lib_curricular_alignment ca
           ON b.id = ca.book_id
          AND ca.academic_year_id = (
              SELECT id FROM academic_years
               WHERE YEAR(CURDATE()) BETWEEN YEAR(start_date) AND YEAR(end_date)
               LIMIT 1
          )
    WHERE pa.predicted_value IS NOT NULL
    GROUP BY b.id, b.title, c.name, g.name, b.publication_year,
             pa.predicted_value, pa.confidence_score, pa.insights,
             pa.recommendations, ca.alignment_score;

  -- Overdue books view
  CREATE OR REPLACE VIEW `lib_view_overdue_books` AS
    SELECT
        t.id   AS transaction_id,
        b.title,
        b.isbn,
        c.barcode,
        m.membership_number,
        u.first_name,
        u.last_name,
        u.email,
        u.phone,
        t.due_date,
        DATEDIFF(CURDATE(), t.due_date)                          AS days_overdue,
        mt.fine_rate_per_day,
        DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day   AS estimated_fine
    FROM lib_transactions t
    INNER JOIN lib_book_copies c        ON t.copy_id = c.id
    INNER JOIN lib_books_master b       ON c.book_id = b.id
    INNER JOIN lib_members m            ON t.member_id = m.id
    INNER JOIN sys_users u              ON m.user_id = u.id
    INNER JOIN lib_membership_types mt  ON m.membership_type_id = mt.id
    WHERE t.status IN (
              SELECT id FROM lib_library_status_masters
               WHERE status_type = 'Transaction Status' AND code = 'Issued'
          )
      AND t.due_date < CURDATE()
      AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days;

  -- Most issued books view
  CREATE OR REPLACE VIEW `lib_view_most_issued_books` AS
    SELECT
        b.id   AS book_id,
        b.title,
        COUNT(t.id)             AS issue_count,
        COUNT(DISTINCT t.member_id) AS unique_borrowers,
        AVG(CASE WHEN t.return_date IS NOT NULL
                 THEN DATEDIFF(t.return_date, t.issue_date) END) AS avg_loan_days
    FROM lib_books_master b
    LEFT JOIN lib_book_copies c   ON b.id = c.book_id
    LEFT JOIN lib_transactions t  ON c.id = t.copy_id
    WHERE t.status IN (
              SELECT id FROM lib_library_status_masters
               WHERE status_type = 'Transaction Status' AND code = 'Returned'
          )
    GROUP BY b.id, b.title
    ORDER BY issue_count DESC;


-- ----------------------------------------------------------------------------
-- Sub-Menu 13. SEED DATA (Lookup Tables)
-- ----------------------------------------------------------------------------

  -- Lib Library Status Masters
  -- F-002 fix: single-quoted ENUM values; "Inventry" typo fixed → "Inventory"
  -- F-038 fix: unique key is now uq_lib_status_typeCode
  -- New: Digital Resource Status and Digital Access Transaction Status added
  INSERT INTO `lib_library_status_masters` (`status_type`, `code`, `name`, `is_system`, `is_active`) VALUES
    -- Book Status
    ('Book Status', 'Available',         'Available',          1, 1),
    ('Book Status', 'Issued',            'Issued',             1, 1),
    ('Book Status', 'Reserved',          'Reserved',           1, 1),
    ('Book Status', 'Under_Maintenance', 'Under Maintenance',  1, 1),
    ('Book Status', 'Lost',              'Lost',               1, 1),
    ('Book Status', 'Withdrawn',         'Withdrawn',          1, 1),
    -- Digital Resource Status
    ('Digital Resource Status', 'Available',         'Available',         1, 1),
    ('Digital Resource Status', 'License_Consumed',  'License Consumed',  1, 1),
    ('Digital Resource Status', 'License_Expired',   'License Expired',   1, 1),
    -- Member Status
    ('Member Status', 'Active',       'Active',       1, 1),
    ('Member Status', 'Expired',      'Expired',      1, 1),
    ('Member Status', 'Suspended',    'Suspended',    1, 1),
    ('Member Status', 'Deactivated',  'Deactivated',  1, 1),
    -- Transaction Status
    ('Transaction Status', 'Issued',    'Issued',    1, 1),
    ('Transaction Status', 'Returned',  'Returned',  1, 1),
    ('Transaction Status', 'Overdue',   'Overdue',   1, 1),
    ('Transaction Status', 'Lost',      'Lost',      1, 1),
    -- Reservation Status
    ('Reservation Status', 'Pending',    'Pending',    1, 1),
    ('Reservation Status', 'Available',  'Available',  1, 1),
    ('Reservation Status', 'Picked_Up',  'Picked Up',  1, 1),
    ('Reservation Status', 'Cancelled',  'Cancelled',  1, 1),
    ('Reservation Status', 'Expired',    'Expired',    1, 1),
    -- Fine Status
    ('Fine Status', 'Pending',  'Pending',  1, 1),
    ('Fine Status', 'Paid',     'Paid',     1, 1),
    ('Fine Status', 'Waived',   'Waived',   1, 1),
    ('Fine Status', 'Overdue',  'Overdue',  1, 1),
    -- Inventory Audit Status
    ('Inventory Audit Status', 'In_Progress',  'In Progress',  1, 1),
    ('Inventory Audit Status', 'Completed',    'Completed',    1, 1),
    ('Inventory Audit Status', 'Cancelled',    'Cancelled',    1, 1),
    -- Inventory Audit Detail Status
    ('Inventory Audit Detail Status', 'Found',      'Found',      1, 1),
    ('Inventory Audit Detail Status', 'Missing',    'Missing',    1, 1),
    ('Inventory Audit Detail Status', 'Misplaced',  'Misplaced',  1, 1),
    ('Inventory Audit Detail Status', 'Damaged',    'Damaged',    1, 1),
    -- Digital Access Transaction Status
    ('Digital Access Transaction Status', 'Active',     'Active',     1, 1),
    ('Digital Access Transaction Status', 'Expired',    'Expired',    1, 1),
    ('Digital Access Transaction Status', 'Revoked',    'Revoked',    1, 1),
    ('Digital Access Transaction Status', 'Completed',  'Completed',  1, 1);

  -- Fine Types
  -- F-022 fix: is_active column now present
  -- F-014 fix: correct column names (code, name)
  INSERT INTO `lib_fine_type` (`code`, `name`, `description`, `is_active`) VALUES
    ('LateReturn',    'Late Book Return Fine',  'Fine charged for returning a book after the due date',     1),
    ('LostBook',      'Lost Book Fine',          'Fine charged when a borrowed book is reported lost',       1),
    ('DamagedBook',   'Damaged Book Fine',       'Fine charged when a borrowed book is returned damaged',    1),
    ('ProcessingFee', 'Processing Fee',          'Administrative processing fee for library transactions',   1);

  -- Digital Access Request Types (NT-003 / F-015 seed)
  INSERT INTO `lib_digital_access_request_types` (`code`, `name`, `description`) VALUES
    ('Download',   'Download Request',         'Request to download the digital resource to local device'),
    ('View_Online','Online View Request',       'Request to view the resource online in browser'),
    ('Stream',     'Stream Request',            'Request to stream audio/video digital resource'),
    ('Offline',    'Offline Access Request',    'Request for offline access via app'),
    ('Extended',   'Extended License Request',  'Request to extend access beyond standard period');

  -- Membership Types
  -- F-013 fix: trailing comma removed
  -- F-014 fix: correct column names (code, name, not membership_type_code, membership_type_name)
  INSERT INTO `lib_membership_types` (`code`, `name`, `max_books_allowed`, `loan_period_days`, `fine_rate_per_day`, `grace_period_days`, `priority_level`, `digital_access_days`) VALUES
    ('STD_STUDENT',      'Standard Student',   5,  14,  5.00, 2, 1,  7),
    ('STD_STAFF',        'Standard Staff',    10,  30,  2.00, 5, 3, 30),
    ('RESEARCH_SCHOLAR', 'Research Scholar',  15,  45,  2.00, 7, 4, 60),
    ('PREMIUM_STUDENT',  'Premium Student',   10,  21,  3.00, 3, 2, 14),
    ('EXTERNAL',         'External Member',    3,  14, 10.00, 0, 0,  0);

  -- Categories
  -- F-014 fix: correct column names (code, name, level)
  INSERT INTO `lib_categories` (`code`, `name`, `level`) VALUES
    ('FIC',  'Fiction',          1),
    ('NFIC', 'Non-Fiction',      1),
    ('SCI',  'Science',          2),
    ('MATH', 'Mathematics',      2),
    ('CS',   'Computer Science', 2),
    ('LIT',  'Literature',       2),
    ('HIST', 'History',          2),
    ('GEO',  'Geography',        2),
    ('ART',  'Art',              2);

  -- Genres
  -- F-014 fix: correct column names (code, name)
  INSERT INTO `lib_genres` (`code`, `name`) VALUES
    ('SF',   'Science Fiction'),
    ('FAN',  'Fantasy'),
    ('MYS',  'Mystery'),
    ('BIO',  'Biography'),
    ('TECH', 'Technology'),
    ('EDU',  'Educational'),
    ('REF',  'Reference'),
    ('CLS',  'Classics'),
    ('POE',  'Poetry');

  -- Resource Types
  -- F-014 fix: correct column names (code, name)
  INSERT INTO `lib_resource_types` (`code`, `name`, `is_physical`, `is_digital`) VALUES
    ('PHY_BOOK', 'Physical Book',  1, 0),
    ('EBOOK',    'E-Book',         0, 1),
    ('PDF',      'PDF Document',   0, 1),
    ('AUDIO',    'Audio Book',     0, 1),
    ('VIDEO',    'Video Resource', 0, 1),
    ('JOURNAL',  'Journal',        1, 1),
    ('MAGAZINE', 'Magazine',       1, 0);

  -- Book Conditions
  -- F-014 fix: correct column names (code, name)
  INSERT INTO `lib_book_conditions` (`code`, `name`, `description`, `is_borrowable`) VALUES
    ('NEW',       'New',        'Brand new condition, never issued',           1),
    ('EXC',       'Excellent',  'Like new, no signs of wear',                  1),
    ('GOOD',      'Good',       'Normal wear and tear, fully readable',        1),
    ('FAIR',      'Fair',       'Significant wear but all pages intact',       1),
    ('POOR',      'Poor',       'Damaged, may have missing pages',             0),
    ('DAMAGED',   'Damaged',    'Needs repair before circulation',             0),
    ('LOST',      'Lost',       'Reported lost by member',                     0),
    ('WITHDRAWN', 'Withdrawn',  'Removed from collection',                     0);

  -- Background Services
  -- F-012 fix: table now exists (NT-005 above)
  INSERT INTO `lib_background_services` (`service_name`, `service_url`, `service_interval`) VALUES
    ('Book Condition Update', 'https://library.example.com/update_book_conditions', 1440);


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Change Log
-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- v5 — 2026-06-09 (Comprehensive fixes from Lib_DDL_Enhancement_Report.md)
-- CRITICAL fixes: F-001 through F-014 — syntax/execution failures resolved
-- HIGH fixes: F-015 through F-028 — broken design corrected
-- MEDIUM fixes: F-031, F-034, F-036, F-037, F-038, F-039 — design quality improved
-- Other fixes: missing timestamps, sys_users consistency, idx name corrections
-- New Tables: NT-001 lib_book_reviews_ratings, NT-002 lib_wishlist,
--             NT-003 lib_digital_access_request_types (also F-015),
--             NT-004 lib_library_settings, NT-005 lib_background_services (also F-012)
-- Triggers/Event: Status comparisons use DECLARE+SELECT INTO instead of string literals
-- Views: All column references corrected (b.id not b.book_id, r.id not r.reservation_id, etc.)
-- --------------------------------------------------------------------------------------------------------------------------------------------------

