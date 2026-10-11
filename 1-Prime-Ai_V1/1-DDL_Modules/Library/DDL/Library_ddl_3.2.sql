-- =====================================================
-- Library Module Database Schema
-- Version: v3 — Field-level descriptions added from data_dictionary.md
-- MySQL 8 Compatible
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
    INDEX `idx_restype_active` (`is_active`),
    UNIQUE KEY `uq_restype_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-1.2 :  Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization.
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
  -- Use Grouping for showng Categories under Parent Category

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
    UNIQUE KEY `uq_lib_author_name` (`author_name`),
    INDEX `idx_lib_author_active` (`is_active`),
    CONSTRAINT `fk_lib_authors_countries` FOREIGN KEY (`country_id`) REFERENCES `glb_countries`(`id`),
    CONSTRAINT `fk_lib_authors_genres` FOREIGN KEY (`primary_genre_id`) REFERENCES `lib_genres`(`id`)
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
  CREATE TABLE IF NOT EXISTS `lib_location_master` (
    `id`          MEDIUMINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`        VARCHAR(30) NOT NULL,              -- Business code (e.g., 'A1-S1-R1')
    `name`        VARCHAR(50) NOT NULL,              -- Display name (e.g., 'Aisle 1', 'Shelf 1')
    `description` VARCHAR(255),                      -- Detailed description of the location
    `type`        ENUM('Zone', 'Floor', 'Aisle', 'Shelf', 'Rack') NOT NULL,  -- Location type
    `building_id` INT UNSIGNED NOT NULL,             -- FK to sch_buildings.id
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP NULL,
    INDEX `idx_lib_location_active` (`is_active`),
    UNIQUE KEY `uq_lib_location_code` (`code`),
    CONSTRAINT `fk_lib_locationMaster_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-2.2 : Physical location mapping for books in the library, enabling efficient shelving and retrieval.
  CREATE TABLE IF NOT EXISTS `lib_shelf_locations` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`         VARCHAR(30) NOT NULL,           -- Business code (e.g., 'A1-S1-R1')
    `building_id`  INT UNSIGNED NOT NULL,          -- FK to sch_buildings.id
    `zone_id`      MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_location_master.id, Zone or section (e.g., 'Reference', 'Children')
    `floor_id`     MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_location_master.id, Floor/level in the building
    `aisle_id`     MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_location_master.id, Aisle identifier (e.g., 'A1', 'B2'). 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `rack_id`      MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_location_master.id, Rack identifier if applicable. 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `shelf_id`     MEDIUMINT UNSIGNED NOT NULL,    -- FK to lib_location_master.id, Shelf identifier within aisle. 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `description`  VARCHAR(255),                   -- Additional location details
    `is_active`    TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_shelf_location_code` (`code`),
    INDEX `idx_lib_location_active` (`is_active`),
    CONSTRAINT `fk_lib_shelfLocations_buildingId` FOREIGN KEY (`building_id`) REFERENCES `sch_buildings`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_zoneId` FOREIGN KEY (`zone_id`) REFERENCES `lib_location_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_floorId` FOREIGN KEY (`floor_id`) REFERENCES `lib_location_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_aisleId` FOREIGN KEY (`aisle_id`) REFERENCES `lib_location_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_rackId` FOREIGN KEY (`rack_id`) REFERENCES `lib_location_master`(`id`),
    CONSTRAINT `fk_lib_shelfLocations_shelfId` FOREIGN KEY (`shelf_id`) REFERENCES `lib_location_master`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
    -- Aisle Number - An aisle is the open passage or walkway between rows of shelving units.
    -- shelf_number - A shelf is a flat, horizontal surface, typically made of wood or metal, used for storing or displaying items.
    -- rack_number - A rack is a framework, typically consisting of bars or hooks, used for storing or displaying items.
    -- floor_number - A floor is the lower surface of a room, on which one walks.
    -- zone - A zone is an area or stretch of land having a particular characteristic, purpose, or use, or subject to particular restrictions.
    -- description - A description is a spoken or written representation or account of a person, object, or event.
    -- Physical location mapping for books in the library, enabling efficient shelving and retrieval.



-- ----------------------------------------------------------------------------
-- Sub-Menu 3. LIBRARY CONFIGURATION
-- ----------------------------------------------------------------------------
  -- Tab-3.1 : Library Fine Types
  CREATE TABLE IF NOT EXISTS `lib_fine_type` (
    `id`          SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`        VARCHAR(30) NOT NULL, -- Code for the fine type ('e.g., LateReturn', 'LostBook', 'DamagedBook', 'ProcessingFee')
    `name`        VARCHAR(50) NOT NULL, -- Name of the fine type ('Late Book Return Fine', 'Lost Book Fine', 'Damaged Book Fine', 'Processing Fee Fine')
    `description` VARCHAR(250) NULL,
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_fine_type_code` (`code`),
    UNIQUE KEY `uq_lib_fine_type_name` (`name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.2 : Library Fine Slab Config (Parent)
  CREATE TABLE IF NOT EXISTS `lib_fine_slab_config` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `name`                VARCHAR(100) NOT NULL,        -- Name of the fine slab ('e.g., Standard Student Fine Slab, Staff Fine Slab')
    `membership_type_id`  INT UNSIGNED NULL,            -- Fk to `lib_membership_types.id` (If NULL, applies to all membership types)
    `resource_type_id`    SMALLINT UNSIGNED NULL,       -- Fk to `lib_resource_types.id` (If NULL, applies to all resource types)
    `fine_type_id`        SMALLINT UNSIGNED NOT NULL,   -- FK to `lib_fine_type.id` ('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee')
    `max_fine_cap`        ENUM('Fixed', 'BookCost', 'Unlimited') DEFAULT 'Unlimited',      -- Type of maximum fine cap (Fixed, BookCost, Unlimited)
    `max_fine_amt`        DECIMAL(10,2) NULL,           -- Maximum fine cap (could school-defined limit OR if Fixed, this is the fixed amount)
    `fine_amt_calc_type`  ENUM('Fixed', 'Percentage', 'BookCost') DEFAULT 'Fixed', -- Type of maximum fine cap (Fixed, BookCost, Unlimited)
    `effective_from`      DATE NOT NULL,                -- Date from which this slab is effective
    `effective_to`        DATE NULL,                    -- Date until which this slab is effective, If NULL, slab is effective indefinitely
    `priority`            TINYINT UNSIGNED DEFAULT 0,   -- Priority for slab evaluation (Higher priority slabs are evaluated first)
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `fk_lib_fineSlabConfig_membershipType` FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    CONSTRAINT `fk_lib_fineSlabConfig_resourceType` FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`),
    CONSTRAINT `fk_lib_fineSlabConfig_fineType` FOREIGN KEY (`fine_type_id`) REFERENCES `lib_fine_type`(`id`),
    INDEX `idx_lib_fineSlabConfig_membership` (`membership_type_id`),
    INDEX `idx_lib_fineSlabConfig_active_EffFrom_EffTo` (`is_active`, `effective_from`, `effective_to`),
    INDEX `idx_lib_fineSlabConfig_priority` (`priority`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.2 : Library Fine Slab Details (Child)
  CREATE TABLE IF NOT EXISTS `lib_fine_slab_details` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `fine_slab_config_id` INT UNSIGNED NOT NULL,                                 -- Reference to lib_fine_slab_config
    `from_day`            TINYINT UNSIGNED NOT NULL CHECK (from_day >= 0),       -- Starting day of the overdue range (inclusive)
    `to_day`              TINYINT UNSIGNED NOT NULL CHECK (to_day >= from_day),  -- Ending day of the overdue range (inclusive)
    `fine_rate`           DECIMAL(10,2) NOT NULL,                                -- Fine rate per day for this overdue range
    `rate_type`           ENUM('Fixed', 'Percentage') DEFAULT 'Fixed',           -- Type of rate (Fixed amount or percentage of book cost)
    `calculation_type`    ENUM('Per_Day', 'Per_Week', 'Per_Month', 'Per_Year', 'Per_Book') DEFAULT 'Per_Day', -- Type of rate (Fixed amount or percentage of book cost)
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    CONSTRAINT `fk_lib_fineSlabDetails_fineSlabConfig` FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_slab_days` (`fine_slab_config_id`, `from_day`, `to_day`),
    INDEX `idx_lib_slab_day_range` (`from_day`, `to_day`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.3 : Library Account Entry Config
  CREATE TABLE IF NOT EXISTS `lib_account_entry_config` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `name`                VARCHAR(100) NOT NULL,        -- Name of the fine slab ('e.g., Standard Student Fine Slab, Staff Fine Slab')
    `fine_type_id`        SMALLINT UNSIGNED NOT NULL,   -- FK to `lib_fine_type.id` ('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee')
    `fine_slab_config_id` INT UNSIGNED NULL,            -- FK to `lib_fine_slab_config.id` (If NULL, applies to all fine slabs for this fine_type)
    `account_group_id`    INT UNSIGNED NOT NULL,        -- Fk to `acc_account_groups.id`
    `ledger_id`           INT UNSIGNED NOT NULL,        -- Fk to `acc_ledgers.id`
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_account_entry_config_name` (`name`),
    CONSTRAINT `fk_lib_aec_fineType` FOREIGN KEY (`fine_type_id`) REFERENCES `lib_fine_type`(`id`),
    CONSTRAINT `fk_lib_aec_fineSlabConfig` FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    CONSTRAINT `fk_lib_aec_accountGroup` FOREIGN KEY (`account_group_id`) REFERENCES `acc_account_groups`(`id`),
    CONSTRAINT `fk_lib_aec_ledger` FOREIGN KEY (`ledger_id`) REFERENCES `acc_ledgers`(`id`),
    UNIQUE KEY `uq_lib_aec_fineType_SlabConf_accGrp_ledger` (`fine_type_id`, `fine_slab_config_id`, `account_group_id`, `ledger_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-3.4 : Library Status Master
	CREATE TABLE IF NOT EXISTS `lib_library_status_masters` (
		`id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
		`status_type`   ENUM('Book Status', 'Member Status', 'Transaction Status', 'Reservation Status', 'Fine Status', 'Inventry Audit Status', 'Inv. Audit Detail Status') NOT NULL,
		`code`          VARCHAR(20)     NOT NULL,  -- e.g. 'available', 'occupied', 'maintenance'
		`name`          VARCHAR(100)    NOT NULL,  -- e.g. 'Available', 'Occupied', 'Under Maintenance'
    `is_system`     TINYINT(1)      NOT NULL DEFAULT 0,  -- Can not be deleted / Edited
		`is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
		`created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
		`updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at`    TIMESTAMP       NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_lib_accounting_status_code` (`status_type`, `code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Generic master for dynamic status codes across modules; allows adding new statuses without code changes';

	-- Data seed (`lib_library_status_masters`) :
		-- Status Type                                                      Code
		-- --------------------------------------------------------------   ----------------------------------------------------------------------------------
		-- `lib_book_copies` (Book Status)                                - 'Available', 'Issued', 'Reserved', 'Under_Maintenance', 'Lost', 'Withdrawn'
    -- `lib_digital_resources` (Digital Resource Status)              - 'Available', 'License Consumed', 'License Expired'
		-- `lib_members` (Member Status)                                  - 'Active', 'Expired', 'Suspended', 'Deactivated'
		-- `lib_transactions` (Transaction Status)                        - 'Issued', 'Returned', 'Overdue', 'Lost'
    -- `lib_reservations` (Reservation Status)                        - 'Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired'
    -- `lib_digital_access_requests` (Digital Access Request Status)  - 'Pending', 'Approved', 'Rejected', 'Withdrawn'
		-- `lib_fines` (Fine Status)                                      - 'Pending', 'Paid', 'Waived', 'Overdue'
    -- `lib_inventory_audit` (Inventry Audit Status)                  - 'In Progress', 'Completed', 'Cancelled'
    -- `lib_inventory_audit_details` (Inventory Audit Detail Status)  - 'Found', 'Missing', 'Misplaced', 'Damaged'


-- ----------------------------------------------------------------------------
-- Sub-Menu 4. ACQUISITION & CATALOGING
-- ----------------------------------------------------------------------------
-- Tab-4.1 : Book Master Creation
-- ------------------------------
  -- Master catalog of all books and resources owned by the library.
  CREATE TABLE IF NOT EXISTS `lib_books_master` (
    `id`                         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `title`                      VARCHAR(500) NOT NULL,               -- Main title of the book
    `subtitle`                   VARCHAR(500),                        -- Subtitle if applicable
    `edition`                    VARCHAR(50),                         -- Edition information (e.g., '2nd', 'Revised')
    `isbn`                       VARCHAR(20) UNIQUE,                  -- International Standard Book Number (13 digits)
    `issn`                       VARCHAR(20),                         -- International Standard Serial Number (for journals)
    `doi`                        VARCHAR(100),                        -- Digital Object Identifier
    `publication_year`           SMALLINT UNSIGNED,                   -- Year of publication
    `publisher_id`               INT UNSIGNED NOT NULL,               -- Reference to lib_publishers
    `language`                   VARCHAR(50) DEFAULT 'English',       -- Primary language of the resource
    `page_count`                 INT CHECK (page_count > 0),          -- Total number of pages
    `summary`                    TEXT NULL,                           -- Brief summary/abstract
    `table_of_contents`          TEXT NULL,                           -- Structured table of contents
    `cover_image_media_id`       VARCHAR(500),                        -- FK to sys_media.id, URL to cover image
    `resource_type_id`           SMALLINT UNSIGNED NOT NULL,          -- FK to lib_resource_types.id
    `is_reference_only`          TINYINT(1) NOT NULL DEFAULT 0,       -- Whether book cannot be borrowed (in-library use only)
    -- Analytics
    `lexile_level`               VARCHAR(20) NULL,                    -- Reading difficulty level
    `reading_age_range`          VARCHAR(20) NULL,                    -- Recommended reading age range (e.g., '8-12 years')
    `awards`                     TEXT NULL,                           -- List of awards won by the book
    `series_name`                VARCHAR(200) NULL,                   -- Series name if book is part of a series
    `series_position`            TINYINT UNSIGNED NULL,               -- Position of the book within the series e.g. 1, 2
    `popularity_rank`            TINYINT UNSIGNED NULL,               -- Popularity rank of the book e.g. 1, 2, 3
    `academic_rating`            DECIMAL(3,2) NULL,                   -- Rating by faculty
    `student_rating`             DECIMAL(3,2) NULL,                   -- Average student rating
    `rating_count`               INT DEFAULT 0,                       -- Number of ratings received
    `curricular_relevance_score` DECIMAL(5,2) NOT NULL DEFAULT 0.00,  -- Curricular relevance score
    `tags`                       JSON NULL,                           -- Auto-generated tags from AI analysis
    `ai_summary`                 TEXT NULL,                           -- AI-generated summary
    `key_concepts`               JSON NULL,                           -- Key concepts extracted from the book
    `is_available`               TINYINT(1) NOT NULL DEFAULT 1,       -- Whether the book is currently available        
    -- Audit
    `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,       -- Whether this title is currently active
    `created_at`                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                 TIMESTAMP NULL,
    CONSTRAINT `fk_lib_book_publisherId` FOREIGN KEY (`publisher_id`) REFERENCES `lib_publishers`(`id`),
    CONSTRAINT `fk_lib_book_resourceType` FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`),
    INDEX `idx_lib_book_title` (`title`(191)),
    INDEX `idx_lib_book_isbn` (`isbn`),
    INDEX `idx_lib_book_year` (`publication_year`),
    INDEX `idx_lib_book_active` (`is_active`),
    INDEX `idx_lib_book_publisher` (`publisher_id`)
    --FULLTEXT INDEX `ft_lib_book_search` (`title`, `subtitle`, `summary`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- If `is_reference_only` = 1, then book can not be borrowed (in-library use only).
  -- Show Book Sttaus from Field 'is_available' in Book Master.
  
  -- Junction table to link books with their authors (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_author_jnt` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                          -- Unique identifier for each author assignment
    `book_id`      INT NOT NULL,                                                           -- Reference to lib_books_master
    `author_id`    INT NOT NULL,                                                           -- Reference to lib_authors
    `author_order` INT NOT NULL DEFAULT 1,                                                 -- Display order of authors (1 = first)
    `is_primary`   TINYINT(1) NOT NULL DEFAULT 0,                                          -- Whether this is the primary author
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                    -- Record creation timestamp
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,        -- Last update timestamp
    `deleted_at`   TIMESTAMP NULL,                                                         -- Soft delete timestamp
    CONSTRAINT `fk_lib_bookAuthor_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookAuthor_authorId` FOREIGN KEY (`author_id`) REFERENCES `lib_authors`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_book_author` (`book_id`, `author_id`, `author_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their categories (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_category_jnt` (
    `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                           -- Unique identifier for each book-category mapping
    `book_id`     INT NOT NULL,                                                            -- Reference to lib_books_master
    `category_id` INT NOT NULL,                                                            -- Reference to lib_categories
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                     -- Record creation timestamp
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,         -- Last update timestamp
    `deleted_at`  TIMESTAMP NULL,                                                          -- Soft delete timestamp
    CONSTRAINT `fk_lib_bookCategory_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookCategory_categoryId` FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`id`) ON DELETE CASCADE,
    INDEX `idx_lib_category_book` (`category_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their genres (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_genre_jnt` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each book-genre mapping
    `book_id`    INT UNSIGNED NOT NULL,                                                             -- Reference to lib_books_master
    `genre_id`   INT UNSIGNED NOT NULL,                                                             -- Reference to lib_genres
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    CONSTRAINT `fk_lib_bookGenre_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookGenre_genreId` FOREIGN KEY (`genre_id`) REFERENCES `lib_genres`(`id`) ON DELETE CASCADE,
    INDEX `idx_lib_genre_book` (`genre_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their subjects (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_subject_jnt` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each book-subject-class mapping
    `book_id`    INT NOT NULL,                                                             -- Reference to lib_books_master
    `class_id`   INT NOT NULL,                                                             -- Reference to sch_classes
    `subject_id` INT NOT NULL,                                                             -- Reference to sch_subjects
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    INDEX `idx_lib_subject_book` (`class_id`, `subject_id`, `book_id`),
    CONSTRAINT `fk_lib_bookSubject_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookSubject_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookSubject_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their keywords (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_keyword_jnt` (
    `id`         INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each book-keyword mapping
    `book_id`    INT NOT NULL,                                                             -- Reference to lib_books_master
    `keyword_id` INT NOT NULL,                                                             -- Reference to lib_keywords
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    CONSTRAINT `fk_lib_bookKeyword_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookKeyword_keywordId` FOREIGN KEY (`keyword_id`) REFERENCES `lib_keywords`(`id`) ON DELETE CASCADE,
    INDEX `idx_lib_keyword_book` (`keyword_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tab-4.2 : Book Acquisition (Purchase)
-- -------------------------------------
  CREATE TABLE IF NOT EXISTS `lib_book_purchases` (
    `id`             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `vendor_id`      INT UNSIGNED NOT NULL,             -- FK to vnd_vendors (supplier/vendor)
    `bill_no`        VARCHAR(50) NULL,                  -- Vendot Invoice No
    `bill_date`      DATE NOT NULL,                     -- Date when copy was purchased
    `bill_amt`       DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total cost of all copies
    `bill_tax_amt`   DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Total Tax amount 
    `bill_net_amt`   DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total cost including Tax amount
    `note`           VARCHAR(150) NULL,                 -- Any note related to Purchase
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`     TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookPurchase_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`id`) ON DELETE SET NULL,
    INDEX `idx_lib_book_id` (`vendor_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Check `resource_type_id` in lib_resource_types master table and showcase on screen whether the Item is physical or digital .

  CREATE TABLE IF NOT EXISTS `lib_book_purchases_items` (
    `id`                   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,    -- Unique identifier for each book purchase
    `book_purchase_id`     INT UNSIGNED NOT NULL,             -- Unique identifier for each book purchase
    `book_id`              INT UNSIGNED NOT NULL,             -- FK to lib_books_master, Reference to lib_books_master.id
    `resource_type_id`     SMALLINT UNSIGNED NOT NULL,        -- FK to lib_resource_types, Reference to lib_resource_types.id (e.g., 'PHY_BOOK', 'EBOOK')
    `book_copy_id`         INT UNSIGNED NULL,                 -- FK to lib_book_copies.id. Will be updated later
    `digital_resource_id`  INT UNSIGNED NULL,                 -- FK to lib_digital_resources.id. Will be updated later
    `book_price`           DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Purchase cost
    `book_quantity`        INT NOT NULL DEFAULT 1,            -- Number of copies purchased
    `book_amt`             DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total cost of all copies (Price x Quantity)
    `book_tax_head`        VARCHAR(50) NULL,
    `book_tax_percent`     DECIMAL(5,2) NOT NULL DEFAULT 0,   -- Tax % on the Book (If Any)
    `book_tax_amt`         DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Book Tax amount 
    `book_net_amt`         DECIMAL(12,2) NOT NULL DEFAULT 0,  -- Total Book cost including Tax amount
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookPurchaseItems_book_id` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookPurchaseItems_resourceType_id` FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lib_bookPurchaseItems_bookCopy_id` FOREIGN KEY (`book_copy_id`) REFERENCES `lib_book_copies`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_lib_bookPurchaseItems_digitalResource_id` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE SET NULL,
    INDEX `idx_lib_book_id` (`book_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
  -- Check `resource_type_id` in lib_resource_types master table and showcase on screen whether it is physical or digital.


-- Tab-4.3 : Book Copy Management
-- ------------------------------
  -- Item-level tracking of each physical copy of a book, including location, condition, and circulation status.
  CREATE TABLE IF NOT EXISTS `lib_book_copies` (
    `id`                   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT, -- Unique identifier for each physical copy
    `book_id`              INT UNSIGNED NOT NULL,          -- Reference to lib_books_master
    `accession_number`     VARCHAR(50) NOT NULL,           -- Institution's unique accession number
    `barcode`              VARCHAR(100) NOT NULL,          -- Scannable barcode for circulation
    `rfid_tag`             VARCHAR(100) NULL,              -- RFID tag identifier if used
    `shelf_location_id`    INT UNSIGNED NULL,              -- Current physical location
    `current_condition_id` INT UNSIGNED NOT NULL,          -- Current condition of the copy
    `book_purchase_id`     INT UNSIGNED NULL,              -- FK to lib_book_purchases.id
    `is_lost`              TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is reported lost. Can not be Issued
    `is_damaged`           TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is damaged
    `is_withdrawn`         TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is withdrawn from collection
    `withdrawal_reason`    VARCHAR(512),                   -- Reason for withdrawal
    `status`               SMALLINT UNSIGNED NOT NULL,     -- FK to `lib_library_status_masters`. Circulation status (e.g. 'Available', 'Issued', 'reserved', 'under_maintenance' etc.)
    `notes`                TEXT,
    `is_active`            TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    INDEX `idx_lib_bookCopy_book` (`book_id`),
    INDEX `idx_lib_bookCopy_status` (`status`, `is_active`),
    INDEX `idx_lib_bookCopy_condition` (`current_condition_id`),
    UNIQUE KEY `uq_lib_bookCopy_barcode` (`barcode`),
    UNIQUE KEY `uq_lib_bookCopy_accession` (`accession_number`),
    UNIQUE KEY `uq_lib_bookCopy_rfid` (`rfid_tag`),
    CONSTRAINT `fk_lib_bookCopy_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_bookCopy_shelfLocationId` FOREIGN KEY (`shelf_location_id`) REFERENCES `lib_shelf_locations`(`id`),
    CONSTRAINT `fk_lib_bookCopy_currentCondId` FOREIGN KEY (`current_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_bookCopy_PurchaseId` FOREIGN KEY (`book_purchase_id`) REFERENCES `lib_book_purchases`(`id`),
    CONSTRAINT `fk_lib_bookCopy_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Historical condition log per book copy for tracking wear and damage over time.
  CREATE TABLE IF NOT EXISTS `lib_book_condition_jnt` (
    `id`           INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `date`         DATE NOT NULL,   -- Date when condition was assessed
    `book_id`      INT NOT NULL,    -- FK to lib_books_master
    `book_copy_id` INT NOT NULL,    -- FK to lib_book_copies, Reference to lib_book_copies
    `condition_id` INT NOT NULL,    -- Reference to lib_book_conditions
    `note`         VARCHAR(255),    -- Additional notes about this condition assessment
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    CONSTRAINT `fk_lib_bookCond_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookCond_bookCopyId` FOREIGN KEY (`book_copy_id`) REFERENCES `lib_book_copies`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_bookCond_conditionId` FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`id`) ON DELETE CASCADE,
    INDEX `idx_lib_condition_book` (`book_id`, `book_copy_id`, `date`, `condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Tab-4.4 : Digital Resource Management
-- -------------------------------------
  CREATE TABLE IF NOT EXISTS `lib_digital_resources` (
    `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`               INT NOT NULL,                    -- FK to lib_books_master
    `file_name`             VARCHAR(255) NOT NULL,           -- Original file name
    `file_media_id`         INT UNSIGNED DEFAULT NULL,       -- Reference to media_files for stored file
    `file_path`             VARCHAR(500) NOT NULL,           -- Storage path or URL (Auto save, will not be visibal to users)
    `file_size_bytes`       INT UNSIGNED NOT NULL,           -- Size of the file in bytes
    `mime_type`             VARCHAR(100) NULL,               -- MIME type (e.g., 'application/pdf')
    `file_format`           VARCHAR(50) NULL,                -- Format (e.g., 'PDF', 'EPUB', 'MP3')
    `can_student_download`  TINYINT(1) NOT NULL DEFAULT 1,   -- Does Student allowed to download the Book
    `can_teacher_download`  TINYINT(1) NOT NULL DEFAULT 1,   -- Does Teacher allowed to download the Book
    `can_staff_download`    TINYINT(1) NOT NULL DEFAULT 1,   -- Does Other Staff allowed to download the Book
    `download_count`        INT UNSIGNED NOT NULL DEFAULT 0, -- Number of times downloaded
    `view_count`            INT UNSIGNED NOT NULL DEFAULT 0, -- Number of times viewed online
    `license_key`           VARCHAR(100) NULL,               -- License identifier if applicable
    `license_type`          VARCHAR(50) NULL,                -- Type of license (e.g., 'Single User', 'Concurrent', 'Site')
    `license_start_date`    DATE NULL,                       -- License validity start date
    `license_end_date`      DATE NULL,                       -- License validity end date
    `license_count`         TINYINT NOT NULL DEFAULT 0,      -- Number of concurrent licenses, IF `license_count` = 0 THEN UNLIMITED DOWNOAD COUNT
    `status`                SMALLINT UNSIGNED NOT NULL,      -- FK to `lib_library_status_masters`. Status of the digital resource
    `is_active`             TINYINT(1) NOT NULL DEFAULT 1,   -- Whether this resource is currently active
    `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            TIMESTAMP NULL,
    CONSTRAINT `fk_lib_digitalResources_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_digitalResources_fileId` FOREIGN KEY (`file_media_id`) REFERENCES `media_files`(id),
    INDEX `idx_lib_digital_book` (`book_id`),
    INDEX `idx_lib_digital_license` (`license_start_date`, `license_end_date`),
    INDEX `idx_lib_digital_active` (`is_active`),
    -- FULLTEXT INDEX `ft_lib_digital_search` (`file_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- If `license_count` > 0 then the number of downloads will be limited to `license_count`

  CREATE TABLE IF NOT EXISTS `lib_digital_resource_tags` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                   -- Unique identifier for each tag assignment
    `digital_resource_id` INT NOT NULL,                                                    -- Reference to lib_digital_resources
    `tag_name`            VARCHAR(100) NOT NULL,                                           -- Tag text (e.g., 'interactive', 'video-lecture')
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    CONSTRAINT `fk_lib_digitalResourceTag_digitalResourceId` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uq_lib_resource_tag` (`digital_resource_id`, `tag_name`),
    INDEX `idx_lib_tag_name` (`tag_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ----------------------------------------------------------------------------
-- 5. MEMBER & ACCESS MANAGEMENT
-- ----------------------------------------------------------------------------

  -- Tab-5.1 : Defines different types of library memberships with their associated privileges and rules. Controls borrowing limits, loan periods, and fine calculations.
  CREATE TABLE IF NOT EXISTS `lib_membership_types` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `code`                VARCHAR(30) NOT NULL UNIQUE,                            -- Business code (e.g., 'STD_STUDENT', 'PREMIUM_STAFF')
    `name`                VARCHAR(100) NOT NULL,                                  -- Display name (e.g., 'Standard Student', 'Premium Staff')
    `max_books_allowed`   TINYINT UNSIGNED NOT NULL CHECK (loan_period_days > 0), -- Maximum number of books a member can borrow simultaneously
    `loan_period_days`    TINYINT UNSIGNED NOT NULL CHECK (loan_period_days > 0), -- Standard loan duration in days
    `renewal_allowed`     TINYINT(1) DEFAULT 1,                                   -- Whether members can renew books
    `max_renewals`        TINYINT UNSIGNED NOT NULL DEFAULT 0,                    -- Maximum number of times a book can be renewed
    `fine_rate_per_day`   DECIMAL(8,2) NOT NULL DEFAULT 0.00 CHECK (fine_rate_per_day >= 0), -- Daily fine amount for late returns
    `grace_period_days`   TINYINT UNSIGNED NOT NULL DEFAULT 0,                    -- Days after due date before fines start accruing
    `priority_level`      TINYINT UNSIGNED NOT NULL DEFAULT 1,                    -- Priority for reservations (higher = better priority)
    `digital_access_days` TINYINT UNSIGNED NOT NULL DEFAULT 0,                    -- For how many Digital Resource access will be provided to this membership type
    `can_restricted_members_view_list` TINYINT(1) DEFAULT 0,                      -- If 0, then Restricted Members can not View the Book List
    `is_active`           TINYINT(1) DEFAULT TRUE,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    INDEX `idx_lib_membership_active` (`is_active`),
    INDEX `idx_lib_membership_priority` (`priority_level`),
    UNIQUE KEY `uq_lib_membership_type_code` (`code`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition on Table `lib_membership_types` :
    -- When Student try to request for a Book, check `max_books_allowed` in `lib_membership_types` master table, If member has exceeded the limit, then the member Get msg "Reached Limit".
    -- When Book Issue then check `max_books_allowed` in `lib_membership_types` master table, If member has Reached the limit, then show msg "Reached Limit".
    -- Check whether user is Membr of the Membership Type or Not. If Not he will not be able to see Book List, get msg. "You are not Authorized to issue Book".
    -- If `can_restricted_members_view_list` is 0, then Restricted Members can not see the Book List.
    -- Once 

  -- Tab-5.2 : Stores information about library members, including their membership type, membership number, and other details.
  CREATE TABLE IF NOT EXISTS `lib_members` (
    `id`                            INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `user_id`                       INT NOT NULL,                   -- Reference to main users table in ERP
    `membership_type_id`            INT NOT NULL,                   -- Reference to lib_membership_types
    `user_type`                     ENUM('Student', 'Teacher', 'Staff') NOT NULL,  -- Type of user (Student, Teacher, Staff)
    `membership_number`             VARCHAR(50) NOT NULL,           -- Unique library membership number
    `library_card_barcode`          VARCHAR(100) NOT NULL,          -- Barcode on physical library card
    `registration_date`             DATE NOT NULL,                  -- Date of membership registration
    `expiry_date`                   DATE NOT NULL,                  -- Membership expiry date
    `is_auto_renew`                 TINYINT(1) NOT NULL DEFAULT 1,  -- Whether membership auto-renews
    `last_activity_date`            DATE,                           -- Last library activity date
    `total_books_borrowed`          INT DEFAULT 0,                  -- Lifetime total books borrowed
    `total_fines_paid`              DECIMAL(10,2) DEFAULT 0.00,     -- Lifetime fines paid
    `outstanding_fines`             DECIMAL(10,2) DEFAULT 0.00 CHECK (outstanding_fines >= 0),  -- Current unpaid fines
    `status`                        SMALLINT UNSIGNED NOT NULL,     -- FK to `lib_library_status_masters`. Membership  status (e.g. 'active', 'expired', 'suspended', 'deactivated')
    `suspension_reason`             TEXT,                           -- Reason if membership is suspended
    `notes`                         TEXT,                           -- Additional notes
    -- Analytics
    `reading_level`                 ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NULL, -- Reading difficulty level of member
    `preferred_notification_channel` ENUM('Email', 'SMS', 'Push', 'InApp') DEFAULT 'Email', -- Preferred channel for notifications
    `member_segment`                VARCHAR(50) COMMENT 'e.g., High-Value, At-Risk, Inactive, New', -- Member segmentation category
    `last_segment_calculation`      TIMESTAMP NULL,                 -- When member segment was last calculated
    `engagement_score`              DECIMAL(5,2) DEFAULT 0.00,      -- Member engagement score
    `churn_risk_score`              DECIMAL(5,2) DEFAULT 0.00,      -- Risk score for member churn
    `lifetime_value`                DECIMAL(10,2) DEFAULT 0.00,     -- Estimated lifetime value of the member
    `preferred_language`            VARCHAR(50) DEFAULT 'English',  -- Preferred reading/communication language
    `reading_goal_annual`           INT DEFAULT 0,                  -- Annual reading goal (books per year)
    `reading_progress_ytd`          INT DEFAULT 0,                  -- Year-to-date reading progress
    -- System
    `is_active`                     TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`                    TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_member_user` (`user_id`),
    UNIQUE KEY `uq_lib_member_membership_number` (`membership_number`),
    UNIQUE KEY `uq_lib_member_library_card_barcode` (`library_card_barcode`),
    CONSTRAINT `fk_lib_member_user` FOREIGN KEY (`user_id`) REFERENCES `users`(id),
    CONSTRAINT `fk_lib_member_membershipType` FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(id),
    CONSTRAINT `fk_lib_member_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_lib_member_membership` (`membership_type_id`),
    INDEX `idx_lib_member_status` (`status`, `expiry_date`),
    INDEX `idx_lib_member_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tab-5.3 : This table will hold the access restrictions configuration for digital resources
  CREATE TABLE IF NOT EXISTS `lib_digital_resource_access_restrictions` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                  -- Unique identifier for each tag assignment
    `digital_resource_id` INT NOT NULL,                                                    -- Reference to lib_digital_resources
    `role_id`             INT NOT NULL,                                                    -- Reference to main roles table in ERP
    `designation_id`      INT NOT NULL,                                                    -- Reference to main designations table in ERP
    `department_id`       INT NOT NULL,                                                    -- Reference to main departments table in ERP
    `user_id`             INT NOT NULL,                                                    -- Reference to main users table in ERP
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,                                   -- Whether this resource is currently active
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                                                  -- Soft delete timestamp
    UNIQUE KEY `uq_lib_resource_user` (`digital_resource_id`, `user_id`),
    INDEX `idx_lib_digital_resource_id` (`digital_resource_id`,`is_active`),
    INDEX `idx_lib_digital_access_active_resource` (`digital_resource_id`, `role_id`, `designation_id`, `department_id`, `user_id`, `is_active`),
    CONSTRAINT `fk_lib_drar_digitalResourceId` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_drar_userId` FOREIGN KEY (`user_id`) REFERENCES `sys_users`(`id`),
    CONSTRAINT `fk_lib_drar_roleId` FOREIGN KEY (`role_id`) REFERENCES `sys_roles`(`id`),
    CONSTRAINT `fk_lib_drar_designationId` FOREIGN KEY (`designation_id`) REFERENCES `sys_designations`(`id`),
    CONSTRAINT `fk_lib_drar_departmentId` FOREIGN KEY (`department_id`) REFERENCES `sys_departments`(`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ----------------------------------------------------------------------------
-- 6- OPERATION MANAGEMENT
-- ----------------------------------------------------------------------------

  -- Tab-6.1 : This table will hold the book Reservations & Renewals
  CREATE TABLE IF NOT EXISTS `lib_reservations` (
    `id`                      INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`                 INT NOT NULL,                    -- Reference to lib_books_master
    `member_id`               INT NOT NULL,                    -- Reference to lib_members
    `reservation_date`        DATETIME NOT NULL,               -- Date and time of reservation/ Request Date
    `expected_available_date` DATE NULL,                       -- Estimated date when book will be available
    `notification_sent`       TINYINT(1) NOT NULL DEFAULT 0,   -- Whether availability notification was sent
    `notification_sent_at`    DATETIME NULL,                   -- When notification was sent
    `pickup_by_date`          DATE NULL,                       -- Date by which member must pick up the book
    `transaction_id`          INT UNSIGNED NULL,               -- Book Issued Transaction ID against this request
    `status`                  SMALLINT UNSIGNED NOT NULL,      -- FK to `lib_library_status_masters`. Reservation status ('Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired')
    -- `queue_position`          INT NULL DEFAULT 1,           -- Position in reservation queue
    `cancellation_reason`     TEXT,                            -- Reason if cancelled
    `is_renewal_reuest`       TINYINT(1) NOT NULL DEFAULT 0,   -- Whether this is a renewal request
    `renewal_days_requested`  TINYINT DEFAULT 0,               -- Number of times this has been renewed
    `renewal_approved`        TINYINT(1) NOT NULL DEFAULT 0,   -- Whether renewal was approved
    `renewal_approved_at`     DATETIME NULL,                   -- When renewal was approved
    `renewal_approved_by_id`  INT NULL,                        -- User ID who approved renewal
    `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`              TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_active_reservation` (`book_id`, `member_id`, `status`),
    INDEX `idx_lib_reserve_book` (`book_id`, `status`, `queue_position`),
    INDEX `idx_lib_reserve_member` (`member_id`, `status`),
    INDEX `idx_lib_reserve_status` (`status`, `pickup_by_date`),
    CONSTRAINT `fk_lib_reservation_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
    CONSTRAINT `fk_lib_reservation_membrId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_reservation_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    CONSTRAINT `fk_lib_reservation_transactionId` FOREIGN KEY (`transaction_id`) REFERENCES `lib_book_transactions`(`id`),
    CONSTRAINT `fk_lib_reservation_approvedBy` FOREIGN KEY (`renewal_approved_by_id`) REFERENCES `sys_users`(id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- Mamber can request for Renewal, then Renewal Request will be Approved by Library Incharge.
    -- Member can also Withdraw the Renewal / Reservation Request.
    -- When raise Renewal Request -> Check `renewal_allowed` in `lib_membership_types` master table, Renewal is allowed only if `renewal_allowed` is 1 for his Membership Type in `lib_membership_types` master table.
    -- When raise Renewal Request -> Check `max_renewals` in `lib_membership_types` master table, and then check `renewal_count` in `lib_transactions` table. If member has reached the limit, then the member cannot renew a book.
    -- When raise Renewal Request -> Check `max_books_allowed` in `lib_membership_types` master table, If member has reached the limit, then the member cannot renew a book.
  

  -- Tab-6.2 : This table will hold the book transactions (Issue, Return, Renewal, etc.)
  CREATE TABLE IF NOT EXISTS `lib_transactions` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `book_id`             INT NOT NULL,                  -- FK to lib_books_master
    `copy_id`             INT NOT NULL,                  -- Reference to lib_book_copies
    `member_id`           INT NOT NULL,                  -- Reference to lib_members
    `issue_date`          DATETIME NOT NULL,             -- Date and time when book was issued
    `due_date`            DATE NOT NULL,                 -- Expected return date
    `return_date`         DATETIME NULL,                 -- Actual return date (NULL if not yet returned)
    `issued_by_id`        INT NOT NULL,                  -- User ID who issued the book
    `received_by_id`      INT NULL,                      -- User ID who received the return
    `issue_condition_id`  INT NOT NULL,                  -- Condition at time of issue
    `return_condition_id` INT NULL,                      -- Condition at time of return
    `is_renewed`          TINYINT(1) NOT NULL DEFAULT 0, -- Whether this transaction is a renewal
    `renewal_count`       INT DEFAULT 0,                                                   -- Number of times this has been renewed
    `status`              SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Transaction status ('Issued', 'Returned', 'Overdue', 'Lost')
    `notes`               TEXT,                                                            -- Additional notes
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                                                  -- Soft delete timestamp
    CONSTRAINT `fk_lib_trans_copyId` FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`id`),
    CONSTRAINT `fk_lib_trans_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_trans_issuedById` FOREIGN KEY (`issued_by_id`) REFERENCES `sys_users`(id),
    CONSTRAINT `fk_lib_trans_receivedById` FOREIGN KEY (`received_by_id`) REFERENCES `sys_users`(id),
    CONSTRAINT `fk_lib_trans_issueConditionId` FOREIGN KEY (`issue_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_trans_returnConditionId` FOREIGN KEY (`return_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_trans_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_lib_trans_copy` (`copy_id`, `status`),
    INDEX `idx_lib_trans_member` (`member_id`, `status`),
    INDEX `idx_lib_trans_dates` (`issue_date`, `due_date`, `return_date`),
    INDEX `idx_lib_trans_status` (`status`, `due_date`),
    INDEX `idx_lib_trans_issued_by` (`issued_by`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- When Issue Check -> Check `max_books_allowed` in `lib_membership_types` master table, If member has exceeded the limit, then the member cannot issue a new book.
    -- When Return -> Check all the pending requests in `lib_reservations` table for that book. Send msg. to the members requested first for the Book. e.g.
    -- 3 members requested on 10th May & 1 member requested on 12th May. Then, send msg. to all 3 members requested on 10th May and then issue the book the member who come first to collect the book.
    -- Next time when book is returned OR purchased new book, then send msg. to 2 members who requested for the same book on 10th may and then 3rd time send to the last member who requested for the same book on 10th may.
    -- When Renewal -> Check `renewal_allowed` in `lib_membership_types` master table, Renewal is allowed only if `renewal_allowed` is 1.
    -- When Renewal -> Check `max_renewals` in `lib_membership_types` master table, and then check `renewal_count` in `lib_transactions` table. If member has reached the limit, then the member cannot renew a book.
    -- When Return -> Check the Book condition at time of issue & return. If condition is not same, then update the condition for the book and see whther any fine needs to be charged to the member.
    -- When Return -> Check Return date is before due date. If Not then check `grace_period_days` in `lib_membership_types` master table. If member has exceeded the grace period, then fine needs to be charged to the member.


  -- Tab-6.3 : This table will capture the Access Requests for Digital Books / Media
  CREATE TABLE IF NOT EXISTS `lib_digital_access_requests` (
    `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `request_type`        ENUM('New Access Request', 'Access Extension Request') NOT NULL,
    `member_id`           INT UNSIGNED NOT NULL,        -- FK to `lib_members`
    `book_id`             INT UNSIGNED NOT NULL,        -- FK to `lib_books_master`
    `digital_resource_id` INT UNSIGNED DEFAULT NULL,    -- FK to `lib_digital_resources`
    `reason`              TEXT DEFAULT NULL,            -- Reason for request
    `status`              SMALLINT UNSIGNED NOT NULL,   -- FK to `lib_library_status_masters`. Request status ('Pending', 'Approved', 'Rejected', 'Withdrawn')
    `reviewed_by_id`      INT UNSIGNED DEFAULT NULL,    -- FK to `sys_users` (User who reviewed & Approved/Reject the request)
    `reviewed_at`         TIMESTAMP NULL DEFAULT NULL,  -- Review timestamp
    `notes`               TEXT DEFAULT NULL,            -- Additional notes
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP NULL DEFAULT NULL,
    `updated_at`          TIMESTAMP NULL DEFAULT NULL,
    `deleted_at`          TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_lib_daReq_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_lib_daReq_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_lib_daReq_digitalResourceId` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_lib_daReq_reviewedById` FOREIGN KEY (`reviewed_by_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY `uq_lib_daReq_member_book_status` (`member_id`, `book_id`, `status`),
    INDEX `idx_lib_daReq_member_status` (`member_id`, `status`),
    INDEX `idx_lib_daReq_book_status` (`book_id`, `status`),
    INDEX `idx_lib_daReq_status_date` (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Condition :
    -- Mamber can request for Renewal, then Renewal Request will be Reviewed & Approved by Library Incharge.
    -- Member can also Withdraw the Renewal / Reservation Request.
    -- When raise Renewal Request -> Check `renewal_allowed` in `lib_membership_types` master table, Renewal is allowed only if `renewal_allowed` is 1 for his Membership Type in `lib_membership_types` master table.
    -- When raise Renewal Request -> Check `max_renewals` in `lib_membership_types` master table, and then check `renewal_count` in `lib_transactions` table. If member has reached the limit, then the member cannot renew a book.
    -- When raise Renewal Request -> Check `max_books_allowed` in `lib_membership_types` master table, If member has reached the limit, then the member cannot renew a book.

  -- Tab-6.3 : This table will capture the Access Transactions for Digital Books / Media
  CREATE TABLE IF NOT EXISTS `old_digital_access_transactions` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `member_id`           INT NOT NULL,                    -- Reference to lib_members
    `access_start_date`   DATETIME NOT NULL,               -- Date and time when book was issued
    `access_end_date`     DATE NOT NULL,                   -- Expected return date
    `can_download`        TINYINT(1) NOT NULL DEFAULT 1,   -- Whether member can download the book
    `access_condition_id` INT NOT NULL,                    -- Condition at time of issue
    `status`              SMALLINT UNSIGNED NOT NULL,      -- FK to `lib_library_status_masters`. Transaction status ('Issued', 'Returned', 'Overdue', 'Lost')
    `notes`               TEXT,                            -- Additional notes
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                  -- Soft delete timestamp
    CONSTRAINT `fk_lib_digitalTransactions_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_digitalTransactions_accessConditionId` FOREIGN KEY (`access_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_digitalTransactions_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_lib_trans_member` (`member_id`, `status`),
    INDEX `idx_lib_trans_dates` (`access_date`, `due_date`, `return_date`),
    INDEX `idx_lib_trans_status` (`status`, `due_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

----------------

  -- Tab-6.3 : This table will capture the Access Transactions for Digital Books / Media
  CREATE TABLE IF NOT EXISTS `lib_digital_access_transactions` (
    `id`                  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `member_id`           INT NOT NULL,                    -- Reference to lib_members
    `access_start_date`   DATETIME NOT NULL,               -- Date and time when book was issued
    `access_end_date`     DATE NOT NULL,                   -- Expected return date
    `can_download`        TINYINT(1) NOT NULL DEFAULT 1,   -- Whether member can download the book
    `access_condition_id` INT NOT NULL,                    -- Condition at time of issue
    `status`              SMALLINT UNSIGNED NOT NULL,      -- FK to `lib_library_status_masters`. Transaction status ('Issued', 'Returned', 'Overdue', 'Lost')
    `notes`               TEXT,                            -- Additional notes
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                  -- Soft delete timestamp
    CONSTRAINT `fk_lib_digitalTransactions_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_digitalTransactions_accessConditionId` FOREIGN KEY (`access_condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_digitalTransactions_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_lib_trans_member` (`member_id`, `status`),
    INDEX `idx_lib_trans_dates` (`access_date`, `due_date`, `return_date`),
    INDEX `idx_lib_trans_status` (`status`, `due_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



  CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id`                    INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `transaction_id`        INT NOT NULL,                                           -- Reference to lib_transactions
    `member_id`             INT NOT NULL,                                           -- Reference to lib_members
    `fine_type`             SMALLINT UNSIGNED NOT NULL,                             -- FK to `lib_fine_type` (Late Return, Lost Book, Damaged Book, etc.)
    `amount`                DECIMAL(10,2) NOT NULL CHECK (amount >= 0),             -- Fine amount
    `days_overdue`          INT NOT NULL DEFAULT 0,                                 -- Number of days overdue (for late returns)
    `calculated_from`       DATE NOT NULL,                                          -- Start date for fine calculation
    `calculated_to`         DATE NOT NULL,                                          -- End date for fine calculation
    `fine_slab_config_id`   INT NULL,                                               -- FK to `lib_fine_slab_config`. Reference to fine slab used for calculation
    `calculation_breakdown` JSON,                                                   -- JSON storing day-wise breakdown of fine calculation
    `waived_amount`         DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),  -- Amount waived
    `waived_by_id`          INT NULL,                                               -- User ID who waived the fine
    `waived_reason`         TEXT NULL,                                              -- Reason for waiving
    `waived_at`             DATETIME NULL,                                          -- When fine was waived
    `status`                SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Fine status ('Pending', 'Paid', 'Waived', 'Overdue')
    `notes`                 TEXT,                                                   -- Additional notes
    `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_lib_fines_transactionId` FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`),
    CONSTRAINT `fk_lib_fines_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    CONSTRAINT `fk_lib_fines_waivedById` FOREIGN KEY (`waived_by_id`) REFERENCES `users`(id),
    CONSTRAINT `fk_lib_fines_fineSlabConfigId` FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    CONSTRAINT `fk_lib_fines_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_lib_fine_transaction` (`transaction_id`),
    INDEX `idx_lib_fine_member` (`member_id`, `status`),
    INDEX `idx_lib_fine_status` (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

----------------------

  CREATE TABLE IF NOT EXISTS `lib_fine_payments` (
    `id`                INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                     -- Unique identifier for each payment
    `fine_id`           INT NOT NULL,                                                      -- Reference to lib_fines
    `amount_paid`       DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),                    -- Amount paid
    `payment_method`    ENUM('Cash', 'Card', 'Online', 'Waiver') NOT NULL,                 -- Method (cash, card, online, waiver)
    `payment_reference` VARCHAR(100),                                                      -- External reference (e.g., transaction ID)
    `payment_date`      DATETIME NOT NULL,                                                 -- Date and time of payment
    `received_by_id`    INT NOT NULL,                                                      -- User ID who received payment
    `receipt_number`    VARCHAR(50) NOT NULL,                                              -- Generated receipt number
    `notes`             TEXT,                                                              -- Additional notes
    `created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`        TIMESTAMP NULL,
    UNIQUE KEY `uq_lib_payment_receipt` (`receipt_number`),
    CONSTRAINT `fk_lib_fine_payments_fineId` FOREIGN KEY (`fine_id`) REFERENCES `lib_fines`(`id`),
    CONSTRAINT `fk_lib_fine_payments_receivedById` FOREIGN KEY (`received_by_id`) REFERENCES `users`(`id`),
    INDEX `idx_lib_payment_fine` (`fine_id`),
    INDEX `idx_lib_payment_receipt` (`receipt_number`),
    INDEX `idx_lib_payment_date` (`payment_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



-- ----------------------------------------------------------------------------
-- AUDIT AND HISTORY
-- ----------------------------------------------------------------------------

-- This table will store the history of transactions
  CREATE TABLE IF NOT EXISTS `lib_transaction_history` (
    `id`             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                                       -- Unique identifier for each history record
    `transaction_id` INT NOT NULL,                                                         -- Reference to lib_transactions
    `action_type`    ENUM('issued', 'returned', 'renewed', 'marked_lost', 'condition_updated') NOT NULL, -- Type of action performed
    `old_value`      JSON,                                                                 -- Previous values as JSON
    `new_value`      JSON,                                                                 -- New values as JSON
    `performed_by_id` INT NOT NULL,                                                        -- User ID who performed the action
    `performed_at`   DATETIME DEFAULT CURRENT_TIMESTAMP,                                   -- When action was performed
    `notes`          TEXT,                                                                 -- Additional notes
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                  -- Record creation timestamp
    `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,      -- Last update timestamp
    `deleted_at`     TIMESTAMP NULL,                                                       -- Soft delete timestamp
    CONSTRAINT `fk_lib_tranHistory_transactionId` FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`),
    CONSTRAINT `fk_lib_tranHistory_performedBy` FOREIGN KEY (`performed_by_id`) REFERENCES `users`(`id`),
    INDEX `idx_lib_history_transaction` (`transaction_id`),
    INDEX `idx_lib_history_performed` (`performed_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_inventory_audit` (
    `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `audit_date`       DATE NOT NULL,               -- Date of audit
    `performed_by_id`  INT NOT NULL,                -- User ID who performed the audit
    `total_scanned`    INT DEFAULT 0,               -- Total copies scanned
    `total_expected`   INT DEFAULT 0,               -- Total copies expected in collection
    `missing_copies`   INT DEFAULT 0,               -- Number of copies not found
    `misplaced_copies` INT DEFAULT 0,               -- Number of copies found in wrong location
    `damaged_copies`   INT DEFAULT 0,               -- Number of copies found damaged
    `status`           SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Audit status ('In Progress', 'Completed', 'Cancelled')
    `completed_at`     DATETIME NULL,               -- When audit was completed
    `notes`            TEXT,                        -- Additional notes
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       TIMESTAMP NULL,
    CONSTRAINT `fk_lib_audit_performedBy` FOREIGN KEY (`performed_by_id`) REFERENCES `users`(`id`),
    CONSTRAINT `fk_lib_audit_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_audit_date` (`audit_date`),
    INDEX `idx_lib_audit_status` (`status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_inventory_audit_details` (
    `id`                   INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                               -- Unique identifier for each audit detail
    `audit_id`             INT NOT NULL,                                                -- Reference to lib_inventory_audit
    `copy_id`              INT NOT NULL,                                                   -- Reference to lib_book_copies
    `expected_location_id` INT,                                                            -- Where copy should be located
    `actual_location_id`   INT,                                                            -- Where copy was actually found
    `scanned_at`           DATETIME NOT NULL,                                              -- When this copy was scanned
    `condition_id`         INT,                                                            -- Observed condition of the copy
    `status`               SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Status os this copy during audit ('found', 'missing', 'misplaced', 'damaged')
    `notes`                TEXT,                                                           -- Additional notes
    CONSTRAINT `fk_lib_auditDetail_auditId` FOREIGN KEY (`audit_id`) REFERENCES `lib_inventory_audit`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lib_auditDetail_copyId` FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`id`),
    CONSTRAINT `fk_lib_auditDetail_expectedLocationId` FOREIGN KEY (`expected_location_id`) REFERENCES `lib_shelf_locations`(`id`),
    CONSTRAINT `fk_lib_auditDetail_actualLocationId` FOREIGN KEY (`actual_location_id`) REFERENCES `lib_shelf_locations`(`id`),
    CONSTRAINT `fk_lib_auditDetail_conditionId` FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`id`),
    CONSTRAINT `fk_lib_auditDetail_status` FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(`id`),
    INDEX `idx_lib_audit_details_audit` (`audit_id`),
    INDEX `idx_lib_audit_details_copy` (`copy_id`),
    UNIQUE KEY `uq_lib_audit_copy` (`audit_id`, `copy_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;





  -- ----------------------------------------------------------------------------
  -- ADVANCED ANALYTICS & INSIGHTS
  -- ----------------------------------------------------------------------------

    -- Tracks individual member reading patterns, preferences, and behavior metrics for personalized recommendations and engagement analysis.
    CREATE TABLE IF NOT EXISTS `lib_reading_behavior_analytics` (
      `id`                        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                -- Unique identifier for each reading behavior record
      `member_id`                 INT NOT NULL,                                              -- Reference to lib_members
      `academic_year`             VARCHAR(20) NOT NULL,                                      -- Academic year this analytics record covers
      `total_books_read`          INT DEFAULT 0,                                             -- Total books read in the academic year
      `total_pages_read`          BIGINT DEFAULT 0,                                          -- Cumulative pages read in the academic year
      `avg_reading_days_per_book` DECIMAL(5,2),                                              -- Average number of days spent per book
      `preferred_genre_id`        INT,                                                       -- Most borrowed genre (FK to lib_genres)
      `preferred_category_id`     INT,                                                       -- Most borrowed category (FK to lib_categories)
      `preferred_language`        VARCHAR(50),                                               -- Most borrowed language
      `avg_loan_completion_rate`  DECIMAL(5,2) COMMENT 'Percentage of books returned on time', -- Percentage of books returned on time
      `peak_borrowing_month`      INT,                                                       -- Month with highest borrowing activity (1-12)
      `peak_borrowing_day`        VARCHAR(20),                                               -- Day of week with highest borrowing activity
      `reading_consistency_score` DECIMAL(5,2) COMMENT '0-100 score based on borrowing regularity', -- 0-100 score based on borrowing regularity
      `genre_diversity_index`     DECIMAL(5,2) COMMENT 'Shannon diversity index for genres', -- Shannon diversity index for genres borrowed
      `author_diversity_index`    DECIMAL(5,2),                                              -- Diversity index for authors read
      `preferred_borrowing_time`  ENUM('Morning', 'Afternoon', 'Evening', 'Weekend'),        -- Time of day/week when member most often borrows
      `digital_vs_physical_ratio` DECIMAL(5,2),                                              -- Ratio of digital to physical resource usage
      `renewal_frequency`         DECIMAL(5,2) COMMENT 'Average renewals per book',         -- Average number of renewals per borrowed book
      `reservation_frequency`     INT DEFAULT 0,                                             -- Number of reservations placed in the period
      `reading_speed_estimate`    DECIMAL(5,2) COMMENT 'Estimated pages per day',           -- Estimated reading speed in pages per day
      `completion_rate_trend`     DECIMAL(5,2) COMMENT 'Month-over-month trend',            -- Month-over-month trend in completion rate
      `last_calculated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Timestamp when analytics were last recalculated
      `created_at`                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                       -- Record creation timestamp
      CONSTRAINT `fk_lib_readBehavAnalytics_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
      CONSTRAINT `fk_lib_readBehavAnalytics_prefGenreId` FOREIGN KEY (`preferred_genre_id`) REFERENCES `lib_genres`(`id`),
      CONSTRAINT `fk_lib_readBehavAnalytics_prefCatId` FOREIGN KEY (`preferred_category_id`) REFERENCES `lib_categories`(`id`),
      INDEX `idx_lib_reading_behavior_member` (`member_id`, `academic_year`),
      INDEX `idx_lib_reading_behavior_genre` (`preferred_genre_id`),
      INDEX `idx_lib_reading_behavior_score` (`reading_consistency_score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Tracks real-time and historical popularity metrics for books to optimize acquisition and shelving decisions.
    CREATE TABLE IF NOT EXISTS `lib_book_popularity_trends` (
      `id`                   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                               -- Unique identifier for each popularity trend record
      `book_id`              INT NOT NULL,                                                   -- Reference to lib_books_master
      `tracking_date`        DATE NOT NULL,                                                  -- Date for which metrics are recorded
      `daily_requests`       INT DEFAULT 0,                                                  -- Total requests (issue + reservation) on this date
      `daily_issues`         INT DEFAULT 0,                                                  -- Number of issues (transactions) on this date
      `daily_reservations`   INT DEFAULT 0,                                                  -- Number of new reservations on this date
      `daily_digital_views`  INT DEFAULT 0,                                                  -- Number of digital resource views on this date
      `daily_digital_downloads` INT DEFAULT 0,                                               -- Number of digital resource downloads on this date
      `popularity_score`     DECIMAL(5,2) COMMENT 'Weighted composite score',               -- Weighted composite popularity score
      `trend_direction`      ENUM('Rising', 'Falling', 'Stable') DEFAULT 'Stable',           -- Direction of popularity trend
      `velocity_score`       DECIMAL(5,2) COMMENT 'Rate of popularity change',              -- Rate of change in popularity score
      `seasonality_factor`   DECIMAL(5,2) COMMENT 'Seasonal adjustment factor',             -- Seasonal adjustment applied to score
      `peer_comparison_rank` INT COMMENT 'Rank among similar books',                        -- Rank of this book among books in the same genre/category
      `shelf_turnover_rate`  DECIMAL(5,2) COMMENT 'How often book moves from shelf',        -- How often the book leaves the shelf
      `waitlist_length`      INT DEFAULT 0,                                                  -- Current number of members in reservation queue
      `avg_wait_days`        DECIMAL(5,2),                                                   -- Average days members wait for this book
      `recommendation_weight` DECIMAL(5,2) COMMENT 'Weight for recommendation engine',      -- Weight used by the recommendation engine
      `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                            -- Record creation timestamp
      `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,-- Last update timestamp
      CONSTRAINT `fk_lib_bookPopularityTrend_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
      UNIQUE KEY `uq_lib_book_daily_trend` (`book_id`, `tracking_date`),
      INDEX `idx_lib_popularity_date` (`tracking_date`),
      INDEX `idx_lib_popularity_score` (`popularity_score`),
      INDEX `idx_lib_popularity_trend` (`trend_direction`, `velocity_score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Provides comprehensive metrics on the health, diversity, and utilization of the library collection.
    CREATE TABLE IF NOT EXISTS `lib_collection_health_metrics` (
      `id`                          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                        -- Unique identifier for each health metric record
      `metric_date`                 DATE NOT NULL,                                           -- Date for which metrics are recorded
      `category_id`                 INT,                                                     -- Category scope (NULL = across all categories)
      `genre_id`                    INT,                                                     -- Genre scope (NULL = across all genres)
      `total_titles`                INT DEFAULT 0,                                           -- Total unique titles in scope
      `total_copies`                INT DEFAULT 0,                                           -- Total physical copies in scope
      `active_titles`               INT DEFAULT 0,                                           -- Titles with at least one active copy
      `inactive_titles`             INT DEFAULT 0,                                           -- Titles with no active copies
      `damaged_copies`              INT DEFAULT 0,                                           -- Copies currently in damaged state
      `lost_copies`                 INT DEFAULT 0,                                           -- Copies reported lost
      `withdrawn_copies`            INT DEFAULT 0,                                           -- Copies withdrawn from collection
      `utilization_rate`            DECIMAL(5,2) COMMENT 'Percentage of collection in circulation', -- Percentage of collection currently issued
      `turnover_rate`               DECIMAL(5,2) COMMENT 'Average issues per copy',         -- Average number of issues per physical copy
      `age_of_collection`           DECIMAL(5,2) COMMENT 'Average age in years',            -- Average age of the collection in years
      `collection_diversity_score`  DECIMAL(5,2) COMMENT 'Based on genre/category distribution', -- Diversity score based on genre/category distribution
      `relevance_score`             DECIMAL(5,2) COMMENT 'How well collection matches demand', -- How well the collection matches member demand
      `acquisition_effectiveness`   DECIMAL(5,2) COMMENT 'ROI on new acquisitions',         -- ROI score for new acquisitions
      `weeding_priority_score`      DECIMAL(5,2) COMMENT 'Priority for removal/replacement',-- Score indicating priority for weeding/replacement
      `budget_allocation_efficiency` DECIMAL(5,2),                                          -- Efficiency score for budget allocation
      `digital_penetration_rate`    DECIMAL(5,2),                                           -- Percentage of collection available digitally
      `physical_vs_digital_ratio`   DECIMAL(5,2),                                           -- Ratio of physical to digital resources
      `created_at`                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                     -- Record creation timestamp
      `updated_at`                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
      INDEX `idx_lib_health_date` (`metric_date`),
      INDEX `idx_lib_health_category` (`category_id`),
      INDEX `idx_lib_health_genre` (`genre_id`),
      INDEX `idx_lib_health_utilization` (`utilization_rate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Stores predictive model outputs for demand forecasting, member churn prediction, and resource optimization.
    CREATE TABLE IF NOT EXISTS `lib_predictive_analytics` (
      `id`                      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                            -- Unique identifier for each prediction record
      `prediction_date`         DATE NOT NULL,                                               -- Date on which prediction was generated
      `prediction_type`         ENUM('Demand_Forecast', 'Member_Churn', 'Resource_Optimization', 'Acquisition_Recommendation', 'Seasonal_Pattern', 'Budget_Projection') NOT NULL, -- Category of prediction
      `target_entity_type`      ENUM('Book', 'Category', 'Genre', 'Member', 'Department', 'All') NOT NULL, -- Type of entity the prediction targets
      `target_entity_id`        INT,                                                         -- ID of the target entity (NULL if type is 'All')
      `prediction_period_start` DATE NOT NULL,                                               -- Start of the period being predicted
      `prediction_period_end`   DATE NOT NULL,                                               -- End of the period being predicted
      `predicted_value`         DECIMAL(10,2) NOT NULL,                                      -- Predicted numeric value
      `confidence_score`        DECIMAL(5,2) COMMENT '0-100 confidence level',              -- Confidence level of the prediction (0-100)
      `actual_value`            DECIMAL(10,2),                                               -- Actual observed value (populated after period ends)
      `accuracy_score`          DECIMAL(5,2),                                               -- Accuracy of the prediction vs actual value
      `model_version`           VARCHAR(50),                                                 -- Version of the model used for prediction
      `features_used`           JSON COMMENT 'Features used in prediction',                 -- JSON array of features used in the prediction model
      `insights`                TEXT,                                                        -- Human-readable insights from the prediction
      `recommendations`         TEXT,                                                        -- Action recommendations based on prediction
      `is_active`               TINYINT(1) DEFAULT 1,                                        -- Whether this prediction record is active
      `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                         -- Record creation timestamp
      `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
      INDEX `idx_lib_predictive_type` (`prediction_type`, `prediction_date`),
      INDEX `idx_lib_predictive_entity` (`target_entity_type`, `target_entity_id`),
      INDEX `idx_lib_predictive_period` (`prediction_period_start`, `prediction_period_end`),
      INDEX `idx_lib_predictive_confidence` (`confidence_score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Tracks how well library resources align with curriculum requirements and academic schedules.
    CREATE TABLE IF NOT EXISTS `lib_curricular_alignment` (
      `id`                    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                              -- Unique identifier for each alignment record
      `academic_year`         VARCHAR(20) NOT NULL,                                          -- Academic year for this alignment record
      `class_id`              INT NOT NULL,                                                  -- Reference to sch_classes
      `subject_id`            INT NOT NULL,                                                  -- Reference to sch_subjects
      `book_id`               INT NOT NULL,                                                  -- Reference to lib_books_master
      `alignment_score`       DECIMAL(5,2) COMMENT 'How well book aligns with curriculum',  -- Score indicating how well the book aligns with curriculum
      `recommended_by_faculty` TINYINT(1) DEFAULT 0,                                         -- Whether the book is faculty recommended
      `faculty_rating`        DECIMAL(3,2) COMMENT '1-5 rating from faculty',               -- Faculty rating (1-5 scale)
      `student_usage_count`   INT DEFAULT 0,                                                 -- Number of times borrowed by students
      `exam_reference_count`  INT DEFAULT 0 COMMENT 'Times referenced in exams',            -- Number of times referenced in exam papers
      `assignment_citations`  INT DEFAULT 0,                                                 -- Number of assignment citations
      `curriculum_unit`       VARCHAR(200),                                                  -- Specific curriculum unit the book supports
      `term_recommended`      ENUM('Term1', 'Term2', 'Term3', 'All'),                        -- Term(s) in which book is recommended
      `priority_level`        ENUM('Essential', 'Recommended', 'Supplementary', 'Optional') DEFAULT 'Supplementary', -- Priority of recommendation
      `notes`                 TEXT,                                                          -- Additional notes
      `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                           -- Record creation timestamp
      `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
      CONSTRAINT `fk_lib_curricularAlign_classId` FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`id`),
      CONSTRAINT `fk_lib_curricularAlign_subjectId` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`id`),
      CONSTRAINT `fk_lib_curricularAlign_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
      UNIQUE KEY `uq_lib_curricular_book` (`academic_year`, `class_id`, `subject_id`, `book_id`),
      INDEX `idx_lib_curricular_alignment` (`alignment_score`),
      INDEX `idx_lib_curricular_priority` (`priority_level`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Tracks granular user interactions with the library system for detailed behavior analysis.
    CREATE TABLE IF NOT EXISTS `lib_engagement_events` (
      `id`                   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,                               -- Unique identifier for each engagement event
      `member_id`            INT NOT NULL,                                                   -- Reference to lib_members
      `event_type`           ENUM('Search','Browse','View_Details','Add_Reservation','Cancel_Reservation','Renew_Online','Digital_View','Digital_Download','Read_Online','Share_Resource','Add_Review','Rate_Book','Save_To_Wishlist','Request_Purchase','Ask_Librarian','Attend_Event') NOT NULL, -- Type of engagement event
      `book_id`              INT,                                                            -- Reference to lib_books_master (if applicable)
      `digital_resource_id`  INT,                                                            -- Reference to lib_digital_resources (if applicable)
      `search_query`         VARCHAR(500),                                                   -- Search query string (for Search events)
      `filters_used`         JSON,                                                           -- Filters applied during search or browse
      `session_id`           VARCHAR(100),                                                   -- Browser/app session identifier
      `device_type`          ENUM('Desktop', 'Mobile', 'Tablet', 'Kiosk'),                   -- Type of device used
      `browser`              VARCHAR(50),                                                    -- Browser or app name
      `ip_address`           VARCHAR(45),                                                    -- IP address of the user
      `location_id`          INT COMMENT 'Physical location if in library',                  -- Physical shelf/zone location if member is in library
      `time_spent_seconds`   INT,                                                            -- Time spent on this interaction in seconds
      `interaction_outcome`  VARCHAR(255),                                                   -- Outcome of the interaction (e.g., 'Reserved', 'Downloaded')
      `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                            -- Record creation timestamp
      CONSTRAINT `fk_engagementEvent_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
      CONSTRAINT `fk_engagementEvent_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
      CONSTRAINT `fk_engagementEvent_digitalResourceId` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`),
      INDEX `idx_lib_engagement_member` (`member_id`, `created_at`),
      INDEX `idx_lib_engagement_type` (`event_type`, `created_at`),
      INDEX `idx_lib_engagement_book` (`book_id`),
      INDEX `idx_lib_engagement_session` (`session_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




  -- ----------------------------------------------------------------------------
  -- 12. TRIGGERS FOR DATA INTEGRITY
  -- ----------------------------------------------------------------------------

  DELIMITER $$

  -- Trigger to update member's total borrowed count
  CREATE TRIGGER lib_update_member_borrowed_count
    AFTER INSERT ON lib_transactions
    FOR EACH ROW
    BEGIN
        IF NEW.status = 'issued' THEN
            UPDATE lib_members
            SET total_books_borrowed = total_books_borrowed + 1,
                last_activity_date = CURDATE()
            WHERE member_id = NEW.member_id;
        END IF;
    END$$

  -- Trigger to update book copy status on transaction
  CREATE TRIGGER lib_update_copy_status_on_issue
    AFTER INSERT ON lib_transactions
    FOR EACH ROW
    BEGIN
        IF NEW.status = 'issued' THEN
            UPDATE lib_book_copies
            SET status = 'issued'
            WHERE copy_id = NEW.copy_id;
        END IF;
    END$$

    CREATE TRIGGER lib_update_copy_status_on_return
    AFTER UPDATE ON lib_transactions
    FOR EACH ROW
    BEGIN
        IF NEW.status = 'returned' AND OLD.status != 'returned' THEN
            UPDATE lib_book_copies
            SET status = 'available',
                current_condition_id = NEW.return_condition_id
            WHERE copy_id = NEW.copy_id;
        END IF;
    END$$

  -- Event to automatically calculate fines on overdue items (runs daily)
  CREATE EVENT auto_calculate_fines
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_DATE
    DO
    BEGIN
        INSERT INTO lib_fines (transaction_id, member_id, fine_type, amount, days_overdue, calculated_from, calculated_to, status)
        SELECT
            t.transaction_id,
            t.member_id,
            'late_return',
            DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day,
            DATEDIFF(CURDATE(), t.due_date),
            t.due_date,
            CURDATE(),
            'pending'
        FROM lib_transactions t
        INNER JOIN lib_members m ON t.member_id = m.member_id
        INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.membership_type_id
        WHERE t.status = 'issued'
          AND t.due_date < CURDATE()
          AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days
          AND NOT EXISTS (
              SELECT 1 FROM lib_fines f
              WHERE f.transaction_id = t.transaction_id
                AND f.fine_type = 'late_return'
                AND f.status = 'pending'
          );
    END$$

  DELIMITER ;

  -- ----------------------------------------------------------------------------
  -- 13. VIEWS FOR COMMON REPORTING
  -- ----------------------------------------------------------------------------

  -- Comprehensive 360-degree view of member engagement and behavior.
  CREATE OR REPLACE VIEW `lib_view_member_360` AS
    SELECT
        m.id,
        m.membership_number,
        u.first_name,
        u.last_name,
        u.email,
        u.phone,
        mt.name as membership_type,
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
        g.name as preferred_genre,
        rba.preferred_borrowing_time,
        rba.digital_vs_physical_ratio,
        (
            SELECT COUNT(*)
            FROM lib_reservations r
            WHERE r.member_id = m.id
              AND r.status = 'Pending'
        ) as active_reservations,
        (
            SELECT COUNT(*)
            FROM lib_transactions t
            WHERE t.member_id = m.id
              AND t.status = 'Issued'
        ) as currently_borrowed,
        DATEDIFF(CURDATE(), m.last_activity_date) as days_since_last_activity,
        CASE
            WHEN m.last_activity_date IS NULL THEN 'New'
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) <= 30 THEN 'Active'
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) <= 90 THEN 'At Risk'
            ELSE 'Inactive'
        END as activity_status
    FROM lib_members m
    INNER JOIN users u ON m.user_id = u.id
    INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.id
    LEFT JOIN lib_reading_behavior_analytics rba ON m.id = rba.member_id AND rba.academic_year = YEAR(CURDATE())
    LEFT JOIN lib_genres g ON rba.preferred_genre_id = g.id;

  -- Real-time performance metrics for collection management.
  CREATE OR REPLACE VIEW `lib_view_collection_performance` AS
    SELECT
        b.id,
        b.title,
        b.isbn,
        p.name as publisher,
        rt.name as resource_type,
        COUNT(DISTINCT c.copy_id) as total_copies,
        SUM(CASE WHEN c.status = 'available' THEN 1 ELSE 0 END) as available_copies,
        SUM(CASE WHEN c.status = 'issued' THEN 1 ELSE 0 END) as issued_copies,
        SUM(CASE WHEN c.status = 'reserved' THEN 1 ELSE 0 END) as reserved_copies,
        SUM(CASE WHEN c.is_lost = 1 THEN 1 ELSE 0 END) as lost_copies,
        SUM(CASE WHEN c.is_damaged = 1 THEN 1 ELSE 0 END) as damaged_copies,
        COUNT(DISTINCT t.transaction_id) as total_issues,
        COUNT(DISTINCT CASE WHEN t.return_date IS NULL AND t.due_date < CURDATE() THEN t.transaction_id END) as overdue_count,
        AVG(CASE WHEN t.return_date IS NOT NULL THEN DATEDIFF(t.return_date, t.issue_date) END) as avg_loan_days,
        COUNT(DISTINCT r.reservation_id) as active_reservations,
        AVG(r.queue_position) as avg_queue_position,
        b.popularity_rank,
        b.curricular_relevance_score,
        b.student_rating,
        pt.popularity_score,
        pt.trend_direction,
        chm.utilization_rate as collection_utilization_rate,
        CASE
            WHEN COUNT(DISTINCT t.transaction_id) > 100 THEN 'High Demand'
            WHEN COUNT(DISTINCT t.transaction_id) > 50 THEN 'Medium Demand'
            WHEN COUNT(DISTINCT t.transaction_id) > 10 THEN 'Low Demand'
            ELSE 'Very Low Demand'
        END as demand_category
    FROM lib_books_master b
    LEFT JOIN lib_publishers p ON b.publisher_id = p.id
    LEFT JOIN lib_resource_types rt ON b.resource_type_id = rt.id
    LEFT JOIN lib_book_copies c ON b.id = c.book_id
    LEFT JOIN lib_transactions t ON c.id = t.copy_id
    LEFT JOIN lib_reservations r ON b.id = r.book_id AND r.status = 'Pending'
    LEFT JOIN lib_book_popularity_trends pt ON b.id = pt.book_id AND pt.tracking_date = CURDATE()
    LEFT JOIN lib_collection_health_metrics chm ON chm.metric_date = CURDATE()
    GROUP BY b.id, b.title, b.isbn, p.name, rt.name, b.popularity_rank,
            b.curricular_relevance_score, b.student_rating, pt.popularity_score, pt.trend_direction;

  -- Predictive demand forecasting for inventory planning.
  CREATE OR REPLACE VIEW `lib_view_predictive_demand` AS
    SELECT b.id, b.title, c.name as category_name, g.name as genre_name, b.publication_year,
        (
            SELECT COUNT(*)
            FROM lib_transactions t
            INNER JOIN lib_book_copies cp ON t.copy_id = cp.id
            WHERE cp.book_id = b.id
              AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        ) as last_3_months_issues,
        (
            SELECT COUNT(*)
            FROM lib_transactions t
            INNER JOIN lib_book_copies cp ON t.copy_id = cp.id
            WHERE cp.book_id = b.id
              AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
        ) as last_year_issues,
        pa.predicted_value as predicted_next_3_months, pa.confidence_score, pa.insights, pa.recommendations,
        ca.alignment_score as curricular_relevance,
        CASE
            WHEN pa.predicted_value > 50 THEN 'Acquire More Copies'
            WHEN pa.predicted_value > 30 THEN 'Monitor Demand'
            WHEN pa.predicted_value > 10 THEN 'Maintain Current'
            ELSE 'Consider Weeding'
        END as acquisition_recommendation
    FROM lib_books_master b
    LEFT JOIN lib_book_category_jnt bc ON b.id = bc.book_id
    LEFT JOIN lib_categories c ON bc.category_id = c.id
    LEFT JOIN lib_book_genre_jnt bg ON b.id = bg.book_id
    LEFT JOIN lib_genres g ON bg.genre_id = g.id
    LEFT JOIN lib_predictive_analytics pa ON b.id = pa.target_entity_id AND pa.prediction_type = 'Demand_Forecast' AND pa.prediction_date = CURDATE()
    LEFT JOIN lib_curricular_alignment ca ON b.id = ca.book_id AND ca.academic_year = YEAR(CURDATE())
    WHERE pa.predicted_value IS NOT NULL
    GROUP BY b.book_id, b.title, c.name, g.name, b.publication_year, pa.predicted_value, pa.confidence_score, pa.insights, pa.recommendations, ca.alignment_score;

  CREATE VIEW lib_view_overdue_books AS
    SELECT
        t.id, b.title, b.isbn, c.barcode, m.membership_number,
        u.first_name, u.last_name, u.email, u.phone,
        t.due_date, DATEDIFF(CURDATE(), t.due_date) as days_overdue,
        mt.fine_rate_per_day, DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day as estimated_fine
    FROM lib_transactions t
    INNER JOIN lib_book_copies c ON t.copy_id = c.id
    INNER JOIN lib_books_master b ON c.book_id = b.id
    INNER JOIN lib_members m ON t.member_id = m.id
    INNER JOIN users u ON m.user_id = u.id
    INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.id
    WHERE t.status = 'issued' AND t.due_date < CURDATE() AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days;

  CREATE VIEW lib_view_most_issued_books AS
    SELECT
        b.id, b.title, COUNT(t.id) as issue_count,
        COUNT(DISTINCT t.member_id) as unique_borrowers,
        AVG(CASE WHEN t.return_date IS NOT NULL THEN DATEDIFF(t.return_date, t.issue_date) END) as avg_loan_days
    FROM lib_books_master b
    LEFT JOIN lib_book_copies c ON b.id = c.book_id
    LEFT JOIN lib_transactions t ON c.id = t.copy_id
    WHERE t.status = 'returned'
    GROUP BY b.id, b.title
    ORDER BY issue_count DESC;


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Change Log
-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Added Field in Table : lib_book_condition_jnt ; Filed Name : book_copy_id
-- Modfied Field in Table : lib_book_copies ; Filed Name : `rfid_tag`; Old : NOT NULL; New : NULL
-- New table : lib_library_status_masters
-- New table : `lib_book_purchases` & `lib_book_purchases_items`
-- New table : `lib_fine_type`
-- New table : `lib_location_master`
-- New Fields in Table : lib_digital_resources  ; Filed Name : `can_student_download`, `can_teacher_download`, `can_staff_download`
-- Remove Field in Table : lib_inventory_audit ; Filed Name : uuid
-- Remove Field in Table : `lib_digital_resources` ; Filed Name : `access_restriction`
