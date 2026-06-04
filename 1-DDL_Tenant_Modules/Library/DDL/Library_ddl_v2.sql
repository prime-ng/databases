-- =====================================================
-- Library Module Database Schema
-- Version: v2 — Field-level descriptions added from data_dictionary.md
-- MySQL 8 Compatible
-- =====================================================

-- ----------------------------------------------------------------------------
-- 1. LIBRARY MASTERS 
-- ----------------------------------------------------------------------------
  -- Defines different types of library memberships with their associated privileges and rules. Controls borrowing limits, loan periods, and fine calculations.
  CREATE TABLE IF NOT EXISTS `lib_membership_types` (
    `id`                INT PRIMARY KEY AUTO_INCREMENT,                                     -- Unique identifier for each membership type
    `code`              VARCHAR(30) NOT NULL UNIQUE,                                        -- Business code (e.g., 'STD_STUDENT', 'PREMIUM_STAFF')
    `name`              VARCHAR(100) NOT NULL,                                              -- Display name (e.g., 'Standard Student', 'Premium Staff')
    `max_books_allowed` INT NOT NULL CHECK (max_books_allowed >= 0),                       -- Maximum number of books a member can borrow simultaneously
    `loan_period_days`  INT NOT NULL CHECK (loan_period_days > 0),                         -- Standard loan duration in days
    `renewal_allowed`   TINYINT(1) DEFAULT TRUE,                                           -- Whether members can renew books
    `max_renewals`      INT DEFAULT 0 CHECK (max_renewals >= 0),                           -- Maximum number of times a book can be renewed
    `fine_rate_per_day` DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (fine_rate_per_day >= 0),-- Daily fine amount for late returns
    `grace_period_days` INT DEFAULT 0 CHECK (grace_period_days >= 0),                     -- Days after due date before fines start accruing
    `priority_level`    INT DEFAULT 0,                                                     -- Priority for reservations (higher = better priority)
    `is_active`         TINYINT(1) DEFAULT TRUE,                                           -- Whether this membership type is currently available
    `created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                               -- Record creation timestamp
    `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,   -- Last update timestamp
    `deleted_at`        TIMESTAMP NULL,                                                    -- Soft delete timestamp
    INDEX `idx_membership_active` (`is_active`, `is_deleted`),
    INDEX `idx_membership_priority` (`priority_level`),
    UNIQUE KEY `uk_membership_type_code` (`code`),
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Classification of resource formats (physical books, e-books, PDFs, audio books, etc.) to handle different media types appropriately.
  CREATE TABLE IF NOT EXISTS `lib_resource_types` (
    `id`             SMALLINT PRIMARY KEY AUTO_INCREMENT,                                  -- Unique identifier for each resource type
    `code`           VARCHAR(30) NOT NULL UNIQUE,                                          -- Business code (e.g., 'PHY_BOOK', 'EBOOK')
    `name`           VARCHAR(100) NOT NULL,                                                -- Display name (e.g., 'Physical Book', 'E-Book')
    `is_physical`    TINYINT(1) NOT NULL DEFAULT 1,                                        -- Whether this is a physical resource
    `is_digital`     TINYINT(1) NOT NULL DEFAULT 0,                                        -- Whether this is a digital resource
    `is_audio_books` TINYINT(1) NOT NULL DEFAULT 0,                                        -- Whether this resource type represents audio books
    `is_borrowable`  TINYINT(1) NOT NULL DEFAULT 1,                                        -- Whether resources of this type can be borrowed
    `is_active`      TINYINT(1) NOT NULL DEFAULT 1,                                        -- Whether this resource type is currently active
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                  -- Record creation timestamp
    `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,      -- Last update timestamp
    `deleted_at`     TIMESTAMP NULL,                                                       -- Soft delete timestamp
    INDEX `idx_restype_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization.
  CREATE TABLE IF NOT EXISTS `lib_categories` (
    `id`                 INT PRIMARY KEY AUTO_INCREMENT,                                   -- Unique identifier for each category
    `parent_category_id` INT NULL,                                                         -- Self-reference for hierarchical categories
    `code`               VARCHAR(30) NOT NULL UNIQUE,                                      -- Business code (e.g., 'FIC', 'SCI_FI')
    `name`               VARCHAR(100) NOT NULL,                                            -- Display name (e.g., 'Fiction', 'Science Fiction')
    `description`        VARCHAR(255),                                                     -- Detailed description of the category
    `level`              INT DEFAULT 1,                                                    -- Depth in hierarchy (1 = top level)
    `display_order`      INT DEFAULT 0,                                                    -- Order for display in dropdowns
    `is_active`          TINYINT(1) DEFAULT TRUE,                                          -- Whether this category is currently active
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                              -- Record creation timestamp
    `updated_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Last update timestamp
    `deleted_at`         TIMESTAMP NULL,                                                   -- Soft delete timestamp
    FOREIGN KEY (`parent_category_id`) REFERENCES `lib_categories`(`category_id`),
    INDEX `idx_category_parent` (`parent_category_id`),
    INDEX `idx_category_active` (`is_active`, `is_deleted`),
    INDEX `idx_category_order` (`display_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tags for literary genres that can be applied across categories for flexible searching and recommendations.
  CREATE TABLE IF NOT EXISTS `lib_genres` (
    `id`          INT PRIMARY KEY AUTO_INCREMENT,                                          -- Unique identifier for each genre
    `code`        VARCHAR(30) NOT NULL UNIQUE,                                             -- Business code (e.g., 'SF', 'MYSTERY')
    `name`        VARCHAR(100) NOT NULL,                                                   -- Display name (e.g., 'Science Fiction', 'Mystery')
    `description` VARCHAR(255),                                                            -- Description of the genre
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,                                           -- Whether this genre is currently active
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                     -- Record creation timestamp
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,         -- Last update timestamp
    `deleted_at`  TIMESTAMP NULL,                                                          -- Soft delete timestamp
    INDEX `idx_genre_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Standardized condition states for physical books to track wear and tear, damage, and usability.
  CREATE TABLE IF NOT EXISTS `lib_book_conditions` (
    `id`           INT PRIMARY KEY AUTO_INCREMENT,                                          -- Unique identifier for each condition
    `code`         VARCHAR(30) NOT NULL UNIQUE,                                            -- Business code (e.g., 'NEW', 'DAMAGED')
    `name`         VARCHAR(50) NOT NULL,                                                   -- Display name (e.g., 'New', 'Damaged')
    `description`  VARCHAR(255),                                                           -- Detailed description of the condition
    `is_borrowable` TINYINT(1) NOT NULL DEFAULT 1,                                         -- Whether books in this condition can be issued
    `is_active`    TINYINT(1) NOT NULL DEFAULT 1,                                          -- Whether this condition is currently active
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                    -- Record creation timestamp
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,        -- Last update timestamp
    `deleted_at`   TIMESTAMP NULL,                                                         -- Soft delete timestamp
    INDEX `idx_condition_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Physical location mapping for books in the library, enabling efficient shelving and retrieval.
  CREATE TABLE IF NOT EXISTS `lib_shelf_locations` (
    `id`           INT PRIMARY KEY AUTO_INCREMENT,  -- Unique identifier for each shelf location
    `code`         VARCHAR(30) NOT NULL UNIQUE,     -- Business code (e.g., 'A1-S1-R1')
    `building`     VARCHAR(100),                    -- Building name or code
    `zone`         VARCHAR(50),                     -- Zone or section (e.g., 'Reference', 'Children')
    `floor_number` VARCHAR(10),                     -- Floor/level in the building
    `aisle_number` VARCHAR(20) NOT NULL,            -- Aisle identifier (e.g., 'A1', 'B2'). 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `rack_number`  VARCHAR(20),                     -- Rack identifier if applicable. 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `shelf_number` VARCHAR(20) NOT NULL,            -- Shelf identifier within aisle. 1 aisle can have multipal racks and 1 rack can have multipal shelves
    `description`  VARCHAR(255),                    -- Additional location details
    `is_active`    TINYINT(1) NOT NULL DEFAULT 1,   -- Whether this location is currently active
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    UNIQUE KEY `uk_shelf_location` (`aisle_number`, `shelf_number`, `rack_number`),
    INDEX `idx_location_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Master list of publishers for books and resources.
  CREATE TABLE IF NOT EXISTS `lib_publishers` (
    `id`         INT PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each publisher
    `code`       VARCHAR(30) NOT NULL UNIQUE,                                              -- Business code for the publisher
    `name`       VARCHAR(200) NOT NULL,                                                    -- Full name of the publishing company
    `address`    TEXT,                                                                     -- Physical/registered address
    `contact`    VARCHAR(100),                                                             -- Primary contact person
    `email`      VARCHAR(100),                                                             -- Contact email address
    `phone`      VARCHAR(20),                                                              -- Contact phone number
    `website`    VARCHAR(255),                                                             -- Publisher's website URL
    `is_active`  TINYINT(1) DEFAULT TRUE,                                                  -- Whether this publisher is currently active
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    INDEX `idx_publisher_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_authors` (
    `id`               INT AUTO_INCREMENT PRIMARY KEY,                                      -- Unique identifier for each author record
    `short_name`       VARCHAR(50) NOT NULL,                                               -- Short identifier or pen name for the author
    `author_name`      VARCHAR(200) NOT NULL,                                              -- Full name of the author
    `country`          VARCHAR(120),                                                       -- Country of the author (FK to glb_countries)
    `primary_genre_id` INT,                                                                -- Primary genre preference of the author (FK to lib_genres)
    `notes`            TEXT DEFAULT NULL,                                                  -- Additional notes about the author
    `is_active`        TINYINT(1) NOT NULL DEFAULT 1,                                      -- Whether this author record is active
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                -- Record creation timestamp
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,    -- Last update timestamp
    `deleted_at`       TIMESTAMP NULL,                                                     -- Soft delete timestamp
    UNIQUE KEY `uq_author_shortName` (`short_name`),
    UNIQUE KEY `uq_author_name` (`author_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 2. LIBRARY CONFIGURATION
-- -------------------------

  CREATE TABLE IF NOT EXISTS `lib_fine_slab_config` (
    `id`                  INT PRIMARY KEY AUTO_INCREMENT,                                   -- Unique identifier for each fine slab configuration
    `name`                VARCHAR(100) NOT NULL COMMENT 'e.g., Standard Student Fine Slab, Staff Fine Slab', -- Name of the fine slab
    `membership_type_id`  INT NULL COMMENT 'If NULL, applies to all membership types',     -- Reference to lib_membership_types (NULL = all types)
    `resource_type_id`    SMALLINT NULL COMMENT 'If NULL, applies to all resource types',  -- Reference to lib_resource_types (NULL = all types)
    `fine_type`           ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') DEFAULT 'Late Return', -- Type of fine this slab applies to
    `max_fine_amount`     DECIMAL(10,2) NULL COMMENT 'Maximum fine cap (could be book cost or school-defined limit)', -- Maximum fine cap
    `max_fine_type`       ENUM('Fixed', 'BookCost', 'Unlimited') DEFAULT 'Unlimited',      -- Type of maximum fine cap (Fixed, BookCost, Unlimited)
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,                                   -- Whether this fine slab is currently active
    `effective_from`      DATE NOT NULL,                                                   -- Date from which this slab is effective
    `effective_to`        DATE NULL,                                                       -- Date until which this slab is effective
    `priority`            INT DEFAULT 0 COMMENT 'Higher priority slabs are evaluated first', -- Priority for slab evaluation (higher = evaluated first)
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                                                  -- Soft delete timestamp
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`),
    INDEX `idx_fine_slab_membership` (`membership_type_id`),
    INDEX `idx_fine_slab_active` (`is_active`, `effective_from`, `effective_to`),
    INDEX `idx_fine_slab_priority` (`priority`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_fine_slab_details` (
    `id`                  INT PRIMARY KEY AUTO_INCREMENT,                                   -- Unique identifier for each fine slab day range
    `fine_slab_config_id` INT NOT NULL,                                                    -- Reference to lib_fine_slab_config
    `from_day`            INT NOT NULL CHECK (from_day >= 0),                              -- Starting day of the overdue range (inclusive)
    `to_day`              INT NOT NULL CHECK (to_day >= from_day),                         -- Ending day of the overdue range (inclusive)
    `rate_per_day`        DECIMAL(10,2) NOT NULL,                                          -- Fine rate per day for this overdue range
    `rate_type`           ENUM('Fixed', 'Percentage') DEFAULT 'Fixed' COMMENT 'Fixed amount or percentage of book cost', -- Type of rate (Fixed amount or percentage of book cost)
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                                                  -- Soft delete timestamp
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_slab_days` (`fine_slab_config_id`, `from_day`, `to_day`),
    INDEX `idx_slab_day_range` (`from_day`, `to_day`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


	CREATE TABLE IF NOT EXISTS `lib_library_status_masters` (
		`id`            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
		`status_type`   ENUM(`Book Status`, `Member Status`, `Transaction Status`, `Reservation Status`, 'Fine Status', `Inventry Audit Status`, `Inventory Audit Detail Status`) NOT NULL,
		`code`          VARCHAR(20)     NOT NULL,  -- e.g. 'available', 'occupied', 'maintenance'
		`name`          VARCHAR(100)    NOT NULL,  -- e.g. 'Available', 'Occupied', 'Under Maintenance'
		`is_active`     TINYINT(1)      NOT NULL DEFAULT 1,
		`created_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
		`updated_at`    TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		`deleted_at`    TIMESTAMP       NULL,
		PRIMARY KEY (`id`),
		UNIQUE KEY `uq_accounting_status_code` (`status_type`, `code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Generic master for dynamic status codes across modules; allows adding new statuses without code changes';

	-- Data seed (`lib_library_status_masters`) :
		-- Status Type                        Code
		-- --------------------------------   ----------------------------------------------------------------------------------
		-- `Book Status`                    - 'Available', 'Issued', 'Reserved', 'Under_Maintenance', 'Lost', 'Withdrawn'
		-- `Member Status`                  - 'Active', 'Expired', 'Suspended', 'Deactivated'
		-- `Transaction Status`             - 'Issued', 'Returned', 'Overdue', 'Lost'
    -- `Reservation Status`             - 'Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired'
		-- 'Fine Status'                    - 'Pending', 'Paid', 'Waived', 'Overdue'
    -- `Inventry Audit Status`          - 'In Progress', 'Completed', 'Cancelled'
    -- `Inventory Audit Detail Status`  - 'Found', 'Missing', 'Misplaced', 'Damaged'

  -- Searchable keywords that can be applied across books for flexible discovery and filtering.
  CREATE TABLE IF NOT EXISTS `lib_keywords` (
    `id`         INT PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each keyword
    `code`       VARCHAR(30) NOT NULL UNIQUE,                                              -- Business code for the keyword
    `name`       VARCHAR(100) NOT NULL,                                                    -- Keyword text
    `is_active`  TINYINT(1) NOT NULL DEFAULT 1,                                            -- Whether this keyword is currently active
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    INDEX `idx_keyword_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ----------------------------------------------------------------------------
-- 2. BOOK ACQUISITION & CATALOGING
-- ----------------------------------------------------------------------------
-- 2.1 Book Master Creation
-- ------------------------
  -- Master catalog of all books and resources owned by the library.
  CREATE TABLE IF NOT EXISTS `lib_books_master` (
    `id`                         INT PRIMARY KEY AUTO_INCREMENT,                                       -- Unique identifier for each book title
    `title`                      VARCHAR(500) NOT NULL,                                               -- Main title of the book
    `subtitle`                   VARCHAR(500),                                                        -- Subtitle if applicable
    `edition`                    VARCHAR(50),                                                         -- Edition information (e.g., '2nd', 'Revised')
    `isbn`                       VARCHAR(20) UNIQUE,                                                  -- International Standard Book Number (13 digits)
    `issn`                       VARCHAR(20),                                                         -- International Standard Serial Number (for journals)
    `doi`                        VARCHAR(100),                                                        -- Digital Object Identifier
    `publication_year`           INT,                                                                 -- Year of publication
    `publisher_id`               INT,                                                                 -- Reference to lib_publishers
    `language`                   VARCHAR(50) DEFAULT 'English',                                       -- Primary language of the resource
    `page_count`                 INT CHECK (page_count > 0),                                          -- Total number of pages
    `summary`                    TEXT,                                                                -- Brief summary/abstract
    `table_of_contents`          TEXT,                                                               -- Structured table of contents
    `cover_image_url`            VARCHAR(500),                                                        -- URL to cover image
    `resource_type_id`           SMALLINT NOT NULL,                                                   -- Reference to lib_resource_types
    `is_reference_only`          TINYINT(1) NOT NULL DEFAULT 0,                                       -- Whether book cannot be borrowed (in-library use only)
    -- Analytics
    `lexile_level`               VARCHAR(20) NULL,                                                    -- Reading difficulty level
    `reading_age_range`          VARCHAR(20) NULL,                                                    -- Recommended reading age range (e.g., '8-12 years')
    `awards`                     TEXT NULL,                                                           -- List of awards won by the book
    `series_name`                VARCHAR(200) NULL,                                                   -- Series name if book is part of a series
    `series_position`            INT NULL,                                                            -- Position of the book within the series
    `popularity_rank`            INT NULL,                                                            -- Popularity rank of the book
    `academic_rating`            DECIMAL(3,2) NULL,                                                   -- Rating by faculty
    `student_rating`             DECIMAL(3,2) NULL,                                                   -- Average student rating
    `rating_count`               INT DEFAULT 0,                                                       -- Number of ratings received
    `curricular_relevance_score` DECIMAL(5,2) NOT NULL DEFAULT 0.00,                                  -- Curricular relevance score
    `tags`                       JSON NULL,                                                           -- Auto-generated tags from AI analysis
    `ai_summary`                 TEXT NULL,                                                           -- AI-generated summary
    `key_concepts`               JSON NULL,                                                           -- Key concepts extracted from the book
    -- Audit
    `is_active`                  TINYINT(1) NOT NULL DEFAULT 1,                                       -- Whether this title is currently active
    `created_at`                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                 -- Record creation timestamp
    `updated_at`                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,     -- Last update timestamp
    `deleted_at`                 TIMESTAMP NULL,                                                      -- Soft delete timestamp
    FOREIGN KEY (`publisher_id`) REFERENCES `lib_publishers`(`publisher_id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`resource_type_id`),
    INDEX `idx_book_title` (`title`(191)),
    INDEX `idx_book_isbn` (`isbn`),
    INDEX `idx_book_year` (`publication_year`),
    INDEX `idx_book_active` (`is_active`),
    INDEX `idx_book_publisher` (`publisher_id`),
    FULLTEXT INDEX `ft_book_search` (`title`, `subtitle`, `summary`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their authors (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_author_jnt` (
    `id`           INT PRIMARY KEY AUTO_INCREMENT,                                          -- Unique identifier for each author assignment
    `book_id`      INT NOT NULL,                                                           -- Reference to lib_books_master
    `author_id`    INT NOT NULL,                                                           -- Reference to lib_authors
    `author_order` INT NOT NULL DEFAULT 1,                                                 -- Display order of authors (1 = first)
    `is_primary`   TINYINT(1) NOT NULL DEFAULT 0,                                          -- Whether this is the primary author
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                    -- Record creation timestamp
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,        -- Last update timestamp
    `deleted_at`   TIMESTAMP NULL,                                                         -- Soft delete timestamp
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`author_id`) REFERENCES `lib_authors`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_book_author` (`book_id`, `author_id`, `author_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their categories (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_category_jnt` (
    `id`          INT PRIMARY KEY AUTO_INCREMENT,                                           -- Unique identifier for each book-category mapping
    `book_id`     INT NOT NULL,                                                            -- Reference to lib_books_master
    `category_id` INT NOT NULL,                                                            -- Reference to lib_categories
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                     -- Record creation timestamp
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,         -- Last update timestamp
    `deleted_at`  TIMESTAMP NULL,                                                          -- Soft delete timestamp
    PRIMARY KEY (`book_id`, `category_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`category_id`) ON DELETE CASCADE,
    INDEX `idx_category_book` (`category_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their genres (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_genre_jnt` (
    `id`         INT PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each book-genre mapping
    `book_id`    INT NOT NULL,                                                             -- Reference to lib_books_master
    `genre_id`   INT NOT NULL,                                                             -- Reference to lib_genres
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    PRIMARY KEY (`book_id`, `genre_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`genre_id`) REFERENCES `lib_genres`(`genre_id`) ON DELETE CASCADE,
    INDEX `idx_genre_book` (`genre_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their subjects (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_subject_jnt` (
    `id`         INT PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each book-subject-class mapping
    `book_id`    INT NOT NULL,                                                             -- Reference to lib_books_master
    `class_id`   INT NOT NULL,                                                             -- Reference to sch_classes
    `subject_id` INT NOT NULL,                                                             -- Reference to sch_subjects
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    INDEX `idx_subject_book` (`class_id`, `subject_id`, `book_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`class_id`) ON DELETE CASCADE,
    FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`subject_id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their keywords (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_keyword_jnt` (
    `id`         INT PRIMARY KEY AUTO_INCREMENT,                                            -- Unique identifier for each book-keyword mapping
    `book_id`    INT NOT NULL,                                                             -- Reference to lib_books_master
    `keyword_id` INT NOT NULL,                                                             -- Reference to lib_keywords
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                      -- Record creation timestamp
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,          -- Last update timestamp
    `deleted_at` TIMESTAMP NULL,                                                           -- Soft delete timestamp
    PRIMARY KEY (`book_id`, `keyword_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`keyword_id`) REFERENCES `lib_keywords`(`keyword_id`) ON DELETE CASCADE,
    INDEX `idx_keyword_book` (`keyword_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 2.2 Book Acquisition (Purchase)
-- -------------------------------
  CREATE TABLE IF NOT EXISTS `lib_book_purchases` (
    `id`                   INT PRIMARY KEY AUTO_INCREMENT,    -- Unique identifier for each book purchase
    `purchase_date`        DATE NOT NULL,                     -- Date when copy was purchased
    `book_id`              INT UNSIGNED NOT NULL,             -- FK to lib_books_master, Reference to lib_books_master.id
    `resource_type_id`     SMALLINT UNSIGNED NOT NULL,        -- FK to lib_resource_types, Reference to lib_resource_types.id (e.g., 'PHY_BOOK', 'EBOOK')
    `book_copy_id`         INT UNSIGNED NULL,                 -- FK to lib_book_copies.id
    `digital_resource_id`  INT UNSIGNED NULL,                 -- FK to lib_digital_resources.id
    `purchase_price`       DECIMAL(10,2) NOT NULL DEFAULT 0,  -- Purchase cost
    `vendor_id`            INT NULL,                          -- Reference to vnd_vendors (supplier/vendor)
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    CONSTRAINT `fk_bookPurchase_book_id` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    CONSTRAINT `fk_bookPurchase_resourceType_id` FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`resource_type_id`) ON DELETE SET NULL,
    CONSTRAINT `fk_bookPurchase_bookCopy_id` FOREIGN KEY (`book_copy_id`) REFERENCES `lib_book_copies`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_bookPurchase_digitalResource_id` FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_bookPurchase_vendor_id` FOREIGN KEY (`vendor_id`) REFERENCES `vnd_vendors`(`vendor_id`) ON DELETE SET NULL,
    INDEX `idx_book_id` (`book_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 2.2 Book Copy Management
-- ------------------------
  -- Item-level tracking of each physical copy of a book, including location, condition, and circulation status.
  CREATE TABLE IF NOT EXISTS `lib_book_copies` (
    `id`                   INT PRIMARY KEY AUTO_INCREMENT, -- Unique identifier for each physical copy
    `book_id`              INT UNSIGNED NOT NULL,          -- Reference to lib_books_master
    `accession_number`     VARCHAR(50) NOT NULL,           -- Institution's unique accession number
    `barcode`              VARCHAR(100) NOT NULL,          -- Scannable barcode for circulation
    `rfid_tag`             VARCHAR(100) NULL,              -- RFID tag identifier if used
    `shelf_location_id`    INT UNSIGNED NULL,              -- Current physical location
    `current_condition_id` INT UNSIGNED NOT NULL,          -- Current condition of the copy
    `book_purchase_id`     INT UNSIGNED NULL,              -- FK to lib_book_purchases.id
    `is_lost`              TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is reported lost
    `is_damaged`           TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is damaged
    `is_withdrawn`         TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is withdrawn from collection
    `withdrawal_reason`    VARCHAR(512),                   -- Reason for withdrawal
    `status`               SMALLINT UNSIGNED NOT NULL,     -- FK to `lib_library_status_masters`. Circulation status (e.g. Available', 'issued', 'reserved', 'under_maintenance' etc.)
    `notes`                TEXT,
    `is_active`            TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`           TIMESTAMP NULL,
    INDEX `idx_copy_book` (`book_id`),
    INDEX `idx_copy_barcode` (`barcode`),
    INDEX `idx_copy_accession` (`accession_number`),
    INDEX `idx_copy_location` (`shelf_location_id`),
    INDEX `idx_copy_status` (`status`, `is_active`, `is_deleted`),
    INDEX `idx_copy_condition` (`current_condition_id`),
    UNIQUE KEY `unique_copy_barcode` (`barcode`),
    UNIQUE KEY `unique_copy_accession` (`accession_number`),
    UNIQUE KEY `unique_copy_rfid` (`rfid_tag`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`shelf_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
    FOREIGN KEY (`current_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    FOREIGN KEY (`book_purchase_id`) REFERENCES `lib_book_purchases`(`id`),
    FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(`status_id`)
    INDEX `idx_book_id` (`book_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Historical condition log per book copy for tracking wear and damage over time.
  CREATE TABLE IF NOT EXISTS `lib_book_condition_jnt` (
    `id`           INT PRIMARY KEY AUTO_INCREMENT,
    `date`         DATE NOT NULL,   -- Date when condition was assessed
    `book_id`      INT NOT NULL,    -- FK to lib_books_master
    `book_copy_id` INT NOT NULL,    -- FK to lib_book_copies, Reference to lib_book_copies
    `condition_id` INT NOT NULL,    -- Reference to lib_book_conditions
    `note`         VARCHAR(255),    -- Additional notes about this condition assessment
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`   TIMESTAMP NULL,
    CONSTRAINT FOREIGN KEY (`bookCondition_book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY (`bookCondition_book_copy_id`) REFERENCES `lib_book_copies`(`id`) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY (`bookCondition_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`) ON DELETE CASCADE,
    INDEX `idx_condition_book` (`book_id`, `book_copy_id`, `date`, `condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;



 -- 2.2 Digital Resource Management
 -- -------------------------------
  CREATE TABLE IF NOT EXISTS `lib_digital_resources` (
    `id`                 INT PRIMARY KEY AUTO_INCREMENT,                                    -- Unique identifier for each digital resource
    `book_id`            INT NOT NULL,                                                     -- Reference to lib_books_master
    `file_name`          VARCHAR(255) NOT NULL,                                            -- Original file name
    `file_media_id`      INT UNSIGNED DEFAULT NULL,                                        -- Reference to media_files for stored file
    `file_path`          VARCHAR(500) NOT NULL,                                            -- Storage path or URL
    `file_size_bytes`    BIGINT,                                                           -- Size of the file in bytes
    `mime_type`          VARCHAR(100),                                                     -- MIME type (e.g., 'application/pdf')
    `file_format`        VARCHAR(50),                                                      -- Format (e.g., 'PDF', 'EPUB', 'MP3')
    `download_count`     INT DEFAULT 0,                                                    -- Number of times downloaded
    `view_count`         INT DEFAULT 0,                                                    -- Number of times viewed online
    `license_key`        VARCHAR(100),                                                     -- License identifier if applicable
    `license_type`       VARCHAR(50),                                                      -- Type of license (e.g., 'Single User', 'Concurrent', 'Site')
    `license_start_date` DATE,                                                             -- License validity start date
    `license_end_date`   DATE,                                                             -- License validity end date
    `access_restriction` JSON,                                                             -- JSON defining access rules (user roles, IP ranges, etc.)
    `is_active`          TINYINT(1) NOT NULL DEFAULT 1,                                    -- Whether this resource is currently active
    `created_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                              -- Record creation timestamp
    `updated_at`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Last update timestamp
    `deleted_at`         TIMESTAMP NULL,                                                   -- Soft delete timestamp
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`file_media_id`) REFERENCES `media_files`(id),
    INDEX `idx_digital_book` (`book_id`),
    INDEX `idx_digital_license` (`license_start_date`, `license_end_date`),
    INDEX `idx_digital_active` (`is_active`),
    FULLTEXT INDEX `ft_digital_search` (`file_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_digital_resource_tags` (
    `id`                  INT PRIMARY KEY AUTO_INCREMENT,                                   -- Unique identifier for each tag assignment
    `digital_resource_id` INT NOT NULL,                                                    -- Reference to lib_digital_resources
    `tag_name`            VARCHAR(100) NOT NULL,                                           -- Tag text (e.g., 'interactive', 'video-lecture')
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`digital_resource_id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_resource_tag` (`digital_resource_id`, `tag_name`),
    INDEX `idx_tag_name` (`tag_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- ----------------------------------------------------------------------------
-- 3. BOOK ACQUISITION
-- ----------------------------------------------------------------------------




  CREATE TABLE IF NOT EXISTS `lib_members` (
    `id`                            INT PRIMARY KEY AUTO_INCREMENT,
    `user_id`                       INT NOT NULL,                   -- Reference to main users table in ERP
    `membership_type_id`            INT NOT NULL,                   -- Reference to lib_membership_types
    `user_type`                     ENUM('Student', 'Teacher', 'Staff') NOT NULL,  -- Type of user (Student, Teacher, Staff)
    `membership_number`             VARCHAR(50) NOT NULL,           -- Unique library membership number
    `library_card_barcode`          VARCHAR(100),                   -- Barcode on physical library card
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
    UNIQUE KEY `uq_member_user` (`user_id`),
    UNIQUE KEY `uq_member_membership_number` (`membership_number`),
    UNIQUE KEY `uq_member_library_card_barcode` (`library_card_barcode`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(id),
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(membership_type_id),
    FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_member_membership` (`membership_type_id`),
    INDEX `idx_member_status` (`status`, `expiry_date`),
    INDEX `idx_member_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

 -- ----------------------------------------------------------------------------
 -- OPERATION MANAGEMENT
 -- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_transactions` (
    `id`                  BIGINT PRIMARY KEY AUTO_INCREMENT,                                -- Unique identifier for each circulation transaction
    `copy_id`             INT NOT NULL,                                                    -- Reference to lib_book_copies
    `member_id`           INT NOT NULL,                                                    -- Reference to lib_members
    `issue_date`          DATETIME NOT NULL,                                               -- Date and time when book was issued
    `due_date`            DATE NOT NULL,                                                   -- Expected return date
    `return_date`         DATETIME NULL,                                                   -- Actual return date (NULL if not yet returned)
    `issued_by_id`        INT NOT NULL,                                                    -- User ID who issued the book
    `received_by_id`      INT NULL,                                                        -- User ID who received the return
    `issue_condition_id`  INT NOT NULL,                                                    -- Condition at time of issue
    `return_condition_id` INT NULL,                                                        -- Condition at time of return
    `is_renewed`          TINYINT(1) NOT NULL DEFAULT 0,                                   -- Whether this transaction is a renewal
    `renewal_count`       INT DEFAULT 0,                                                   -- Number of times this has been renewed
    `status`              SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Transaction status ('Issued', 'Returned', 'Overdue', 'Lost')
    `notes`               TEXT,                                                            -- Additional notes
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                             -- Record creation timestamp
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`          TIMESTAMP NULL,                                                  -- Soft delete timestamp
    FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`copy_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    FOREIGN KEY (`issued_by_id`) REFERENCES `sys_users`(id),
    FOREIGN KEY (`received_by_id`) REFERENCES `sys_users`(id),
    FOREIGN KEY (`issue_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    FOREIGN KEY (`return_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_trans_copy` (`copy_id`, `status`),
    INDEX `idx_trans_member` (`member_id`, `status`),
    INDEX `idx_trans_dates` (`issue_date`, `due_date`, `return_date`),
    INDEX `idx_trans_status` (`status`, `due_date`),
    INDEX `idx_trans_issued_by` (`issued_by`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_reservations` (
    `id`                      BIGINT PRIMARY KEY AUTO_INCREMENT,                            -- Unique identifier for each reservation
    `book_id`                 INT NOT NULL,                                                -- Reference to lib_books_master
    `member_id`               INT NOT NULL,                                                -- Reference to lib_members
    `reservation_date`        DATETIME NOT NULL,                                           -- Date and time of reservation
    `expected_available_date` DATE NOT NULL,                                               -- Estimated date when book will be available
    `notification_sent`       TINYINT(1) NOT NULL DEFAULT 0,                               -- Whether availability notification was sent
    `notification_sent_at`    DATETIME NULL,                                               -- When notification was sent
    `pickup_by_date`          DATE NULL,                                                   -- Date by which member must pick up the book
    `status`                  SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Reservation status ('Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired')
    `queue_position`          INT NOT NULL DEFAULT 1,                                      -- Position in reservation queue
    `cancellation_reason`     TEXT,                                                        -- Reason if cancelled
    `created_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                         -- Record creation timestamp
    `updated_at`              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update timestamp
    `deleted_at`              TIMESTAMP NULL,                                              -- Soft delete timestamp
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    UNIQUE KEY `uk_active_reservation` (`book_id`, `member_id`, `status`),
    INDEX `idx_reserve_book` (`book_id`, `status`, `queue_position`),
    INDEX `idx_reserve_member` (`member_id`, `status`),
    INDEX `idx_reserve_status` (`status`, `pickup_by_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id`                    INT PRIMARY KEY AUTO_INCREMENT,                                 -- Unique identifier for each fine
    `transaction_id`        BIGINT NOT NULL,                                               -- Reference to lib_transactions
    `member_id`             INT NOT NULL,                                                  -- Reference to lib_members
    `fine_type`             ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') NOT NULL, -- Type of fine
    `amount`                DECIMAL(10,2) NOT NULL CHECK (amount >= 0),                    -- Fine amount
    `days_overdue`          INT NOT NULL DEFAULT 0,                                        -- Number of days overdue (for late returns)
    `calculated_from`       DATE NOT NULL,                                                 -- Start date for fine calculation
    `calculated_to`         DATE NOT NULL,                                                 -- End date for fine calculation
    `fine_slab_config_id`   INT NULL COMMENT 'Reference to slab used for calculation',    -- Reference to fine slab used for calculation
    `calculation_breakdown` JSON COMMENT 'Stores day-wise breakdown of fine calculation',  -- JSON storing day-wise breakdown of fine calculation
    `waived_amount`         DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),         -- Amount waived
    `waived_by_id`          INT NULL,                                                      -- User ID who waived the fine
    `waived_reason`         TEXT NULL,                                                     -- Reason for waiving
    `waived_at`             DATETIME NULL,                                                 -- When fine was waived
    `status`                SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Fine status ('Pending', 'Paid', 'Waived', 'Overdue')
    `notes`                 TEXT,                                                          -- Additional notes
    `created_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                           -- Record creation timestamp
    `updated_at`            TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,-- Last update timestamp
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    FOREIGN KEY (`waived_by_id`) REFERENCES `users`(id),
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(id),
    INDEX `idx_fine_transaction` (`transaction_id`),
    INDEX `idx_fine_member` (`member_id`, `status`),
    INDEX `idx_fine_status` (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  CREATE TABLE IF NOT EXISTS `lib_fine_payments` (
    `id`                INT PRIMARY KEY AUTO_INCREMENT,                                     -- Unique identifier for each payment
    `fine_id`           INT NOT NULL,                                                      -- Reference to lib_fines
    `amount_paid`       DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),                    -- Amount paid
    `payment_method`    ENUM('Cash', 'Card', 'Online', 'Waiver') NOT NULL,                 -- Method (cash, card, online, waiver)
    `payment_reference` VARCHAR(100),                                                      -- External reference (e.g., transaction ID)
    `payment_date`      DATETIME NOT NULL,                                                 -- Date and time of payment
    `received_by_id`    INT NOT NULL,                                                      -- User ID who received payment
    `receipt_number`    VARCHAR(50) NOT NULL,                                              -- Generated receipt number
    `notes`             TEXT,                                                              -- Additional notes
    `created_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                               -- Record creation timestamp
    `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,   -- Last update timestamp
    `deleted_at`        TIMESTAMP NULL,                                                    -- Soft delete timestamp
    UNIQUE KEY `uk_payment_receipt` (`receipt_number`),
    FOREIGN KEY (`fine_id`) REFERENCES `lib_fines`(`fine_id`),
    FOREIGN KEY (`received_by_id`) REFERENCES `users`(id),
    INDEX `idx_payment_fine` (`fine_id`),
    INDEX `idx_payment_receipt` (`receipt_number`),
    INDEX `idx_payment_date` (`payment_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;





  -- ----------------------------------------------------------------------------
  -- AUDIT AND HISTORY
  -- ----------------------------------------------------------------------------

    CREATE TABLE IF NOT EXISTS `lib_transaction_history` (
      `id`             INT PRIMARY KEY AUTO_INCREMENT,                                        -- Unique identifier for each history record
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
      FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`transaction_id`),
      FOREIGN KEY (`performed_by`) REFERENCES `users`(id),
      INDEX `idx_history_transaction` (`transaction_id`),
      INDEX `idx_history_performed` (`performed_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `lib_inventory_audit` (
      `id`               INT PRIMARY KEY AUTO_INCREMENT,                                      -- Unique identifier for each audit
      `uuid`             CHAR(36) NOT NULL UNIQUE,                                           -- UUID for distributed tracing
      `audit_date`       DATE NOT NULL,                                                      -- Date of audit
      `performed_by_id`  INT NOT NULL,                                                       -- User ID who performed the audit
      `total_scanned`    INT DEFAULT 0,                                                      -- Total copies scanned
      `total_expected`   INT DEFAULT 0,                                                      -- Total copies expected in collection
      `missing_copies`   INT DEFAULT 0,                                                      -- Number of copies not found
      `misplaced_copies` INT DEFAULT 0,                                                      -- Number of copies found in wrong location
      `damaged_copies`   INT DEFAULT 0,                                                      -- Number of copies found damaged
      `status`             SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Audit status ('In Progress', 'Completed', 'Cancelled')
      `completed_at`     DATETIME NULL,                                                      -- When audit was completed
      `notes`            TEXT,                                                               -- Additional notes
      `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                                -- Record creation timestamp
      `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,    -- Last update timestamp
      `deleted_at`       TIMESTAMP NULL,                                                     -- Soft delete timestamp
      FOREIGN KEY (`performed_by`) REFERENCES `users`(id),
      FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(`id`),
      INDEX `idx_audit_date` (`audit_date`),
      INDEX `idx_audit_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    CREATE TABLE IF NOT EXISTS `lib_inventory_audit_details` (
      `id`                   BIGINT PRIMARY KEY AUTO_INCREMENT,                               -- Unique identifier for each audit detail
      `audit_id`             BIGINT NOT NULL,                                                -- Reference to lib_inventory_audit
      `copy_id`              INT NOT NULL,                                                   -- Reference to lib_book_copies
      `expected_location_id` INT,                                                            -- Where copy should be located
      `actual_location_id`   INT,                                                            -- Where copy was actually found
      `scanned_at`           DATETIME NOT NULL,                                              -- When this copy was scanned
      `condition_id`         INT,                                                            -- Observed condition of the copy
      `status`               SMALLINT UNSIGNED NOT NULL,  -- FK to `lib_library_status_masters`. Status os this copy during audit ('found', 'missing', 'misplaced', 'damaged')
      `notes`                TEXT,                                                           -- Additional notes
      FOREIGN KEY (`audit_id`) REFERENCES `lib_inventory_audit`(`audit_id`) ON DELETE CASCADE,
      FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`copy_id`),
      FOREIGN KEY (`expected_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
      FOREIGN KEY (`actual_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
      FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
      FOREIGN KEY (`status`) REFERENCES `lib_library_status_masters`(`id`),
      INDEX `idx_audit_details_audit` (`audit_id`),
      INDEX `idx_audit_details_copy` (`copy_id`),
      UNIQUE KEY `uk_audit_copy` (`audit_id`, `copy_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;





  -- ----------------------------------------------------------------------------
  -- ADVANCED ANALYTICS & INSIGHTS
  -- ----------------------------------------------------------------------------

    -- Tracks individual member reading patterns, preferences, and behavior metrics for personalized recommendations and engagement analysis.
    CREATE TABLE IF NOT EXISTS `lib_reading_behavior_analytics` (
      `id`                        BIGINT PRIMARY KEY AUTO_INCREMENT,                          -- Unique identifier for each reading behavior record
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
      FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
      FOREIGN KEY (`preferred_genre_id`) REFERENCES `lib_genres`(`genre_id`),
      FOREIGN KEY (`preferred_category_id`) REFERENCES `lib_categories`(`category_id`),
      INDEX `idx_reading_behavior_member` (`member_id`, `academic_year`),
      INDEX `idx_reading_behavior_genre` (`preferred_genre_id`),
      INDEX `idx_reading_behavior_score` (`reading_consistency_score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Tracks real-time and historical popularity metrics for books to optimize acquisition and shelving decisions.
    CREATE TABLE IF NOT EXISTS `lib_book_popularity_trends` (
      `id`                   BIGINT PRIMARY KEY AUTO_INCREMENT,                               -- Unique identifier for each popularity trend record
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
      FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
      UNIQUE KEY `uk_book_daily_trend` (`book_id`, `tracking_date`),
      INDEX `idx_popularity_date` (`tracking_date`),
      INDEX `idx_popularity_score` (`popularity_score`),
      INDEX `idx_popularity_trend` (`trend_direction`, `velocity_score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Provides comprehensive metrics on the health, diversity, and utilization of the library collection.
    CREATE TABLE IF NOT EXISTS `lib_collection_health_metrics` (
      `id`                          BIGINT PRIMARY KEY AUTO_INCREMENT,                        -- Unique identifier for each health metric record
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
      INDEX `idx_health_date` (`metric_date`),
      INDEX `idx_health_category` (`category_id`),
      INDEX `idx_health_genre` (`genre_id`),
      INDEX `idx_health_utilization` (`utilization_rate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Stores predictive model outputs for demand forecasting, member churn prediction, and resource optimization.
    CREATE TABLE IF NOT EXISTS `lib_predictive_analytics` (
      `id`                      BIGINT PRIMARY KEY AUTO_INCREMENT,                            -- Unique identifier for each prediction record
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
      INDEX `idx_predictive_type` (`prediction_type`, `prediction_date`),
      INDEX `idx_predictive_entity` (`target_entity_type`, `target_entity_id`),
      INDEX `idx_predictive_period` (`prediction_period_start`, `prediction_period_end`),
      INDEX `idx_predictive_confidence` (`confidence_score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Tracks how well library resources align with curriculum requirements and academic schedules.
    CREATE TABLE IF NOT EXISTS `lib_curricular_alignment` (
      `id`                    BIGINT PRIMARY KEY AUTO_INCREMENT,                              -- Unique identifier for each alignment record
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
      FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`class_id`),
      FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`subject_id`),
      FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
      UNIQUE KEY `uk_curricular_book` (`academic_year`, `class_id`, `subject_id`, `book_id`),
      INDEX `idx_curricular_alignment` (`alignment_score`),
      INDEX `idx_curricular_priority` (`priority_level`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

    -- Tracks granular user interactions with the library system for detailed behavior analysis.
    CREATE TABLE IF NOT EXISTS `lib_engagement_events` (
      `id`                   BIGINT PRIMARY KEY AUTO_INCREMENT,                               -- Unique identifier for each engagement event
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
      FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
      FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
      FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`digital_resource_id`),
      INDEX `idx_engagement_member` (`member_id`, `created_at`),
      INDEX `idx_engagement_type` (`event_type`, `created_at`),
      INDEX `idx_engagement_book` (`book_id`),
      INDEX `idx_engagement_session` (`session_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;









  -- ----------------------------------------------------------------------------
  -- 11. INDEX PERFORMANCE OPTIMIZATION
  -- ----------------------------------------------------------------------------

  -- Additional indexes for complex queries
    CREATE INDEX idx_transactions_overdue ON lib_transactions(status, due_date) WHERE status = 'issued';
    CREATE INDEX idx_members_outstanding ON lib_members(outstanding_fines) WHERE outstanding_fines > 0;
    CREATE INDEX idx_fines_pending ON lib_fines(status, created_at) WHERE status = 'pending';
    CREATE INDEX idx_reservations_available ON lib_reservations(status, expected_available_date, notification_sent) WHERE status = 'pending';
    CREATE INDEX idx_digital_license_expiry ON lib_digital_resources(license_end_date) WHERE license_end_date IS NOT NULL;

  -- Composite indexes for reporting
    CREATE INDEX idx_books_publisher_year ON lib_books_master(publisher_id, publication_year);
    CREATE INDEX idx_copies_location_status ON lib_book_copies(shelf_location_id, status);
    CREATE INDEX idx_transactions_member_dates ON lib_transactions(member_id, issue_date, return_date);

  -- ----------------------------------------------------------------------------
  -- 12. TRIGGERS FOR DATA INTEGRITY
  -- ----------------------------------------------------------------------------

  DELIMITER $$

  -- Trigger to update member's total borrowed count
  CREATE TRIGGER update_member_borrowed_count
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
  CREATE TRIGGER update_copy_status_on_issue
    AFTER INSERT ON lib_transactions
    FOR EACH ROW
    BEGIN
        IF NEW.status = 'issued' THEN
            UPDATE lib_book_copies
            SET status = 'issued'
            WHERE copy_id = NEW.copy_id;
        END IF;
    END$$

    CREATE TRIGGER update_copy_status_on_return
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
        m.member_id,
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
            WHERE r.member_id = m.member_id
              AND r.status = 'Pending'
        ) as active_reservations,
        (
            SELECT COUNT(*)
            FROM lib_transactions t
            WHERE t.member_id = m.member_id
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
    LEFT JOIN lib_reading_behavior_analytics rba ON m.member_id = rba.member_id AND rba.academic_year = YEAR(CURDATE())
    LEFT JOIN lib_genres g ON rba.preferred_genre_id = g.id;

  -- Real-time performance metrics for collection management.
  CREATE OR REPLACE VIEW `lib_view_collection_performance` AS
    SELECT
        b.book_id,
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
    LEFT JOIN lib_book_copies c ON b.book_id = c.book_id
    LEFT JOIN lib_transactions t ON c.copy_id = t.copy_id
    LEFT JOIN lib_reservations r ON b.book_id = r.book_id AND r.status = 'Pending'
    LEFT JOIN lib_book_popularity_trends pt ON b.book_id = pt.book_id AND pt.tracking_date = CURDATE()
    LEFT JOIN lib_collection_health_metrics chm ON chm.metric_date = CURDATE()
    GROUP BY b.book_id, b.title, b.isbn, p.name, rt.name, b.popularity_rank,
            b.curricular_relevance_score, b.student_rating, pt.popularity_score, pt.trend_direction;

  -- Predictive demand forecasting for inventory planning.
  CREATE OR REPLACE VIEW `lib_view_predictive_demand` AS
    SELECT b.book_id, b.title, c.name as category_name, g.name as genre_name, b.publication_year,
        (
            SELECT COUNT(*)
            FROM lib_transactions t
            INNER JOIN lib_book_copies cp ON t.copy_id = cp.copy_id
            WHERE cp.book_id = b.book_id
              AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        ) as last_3_months_issues,
        (
            SELECT COUNT(*)
            FROM lib_transactions t
            INNER JOIN lib_book_copies cp ON t.copy_id = cp.copy_id
            WHERE cp.book_id = b.book_id
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
    LEFT JOIN lib_book_category_jnt bc ON b.book_id = bc.book_id
    LEFT JOIN lib_categories c ON bc.category_id = c.id
    LEFT JOIN lib_book_genre_jnt bg ON b.book_id = bg.book_id
    LEFT JOIN lib_genres g ON bg.genre_id = g.id
    LEFT JOIN lib_predictive_analytics pa ON b.book_id = pa.target_entity_id AND pa.prediction_type = 'Demand_Forecast' AND pa.prediction_date = CURDATE()
    LEFT JOIN lib_curricular_alignment ca ON b.book_id = ca.book_id AND ca.academic_year = YEAR(CURDATE())
    WHERE pa.predicted_value IS NOT NULL
    GROUP BY b.book_id, b.title, c.name, g.name, b.publication_year, pa.predicted_value, pa.confidence_score, pa.insights, pa.recommendations, ca.alignment_score;

  CREATE VIEW lib_view_overdue_books AS
    SELECT
        t.transaction_id, b.title, b.isbn, c.barcode, m.membership_number,
        u.first_name, u.last_name, u.email, u.phone,
        t.due_date, DATEDIFF(CURDATE(), t.due_date) as days_overdue,
        mt.fine_rate_per_day, DATEDIFF(CURDATE(), t.due_date) * mt.fine_rate_per_day as estimated_fine
    FROM lib_transactions t
    INNER JOIN lib_book_copies c ON t.copy_id = c.copy_id
    INNER JOIN lib_books_master b ON c.book_id = b.book_id
    INNER JOIN lib_members m ON t.member_id = m.member_id
    INNER JOIN users u ON m.user_id = u.id
    INNER JOIN lib_membership_types mt ON m.membership_type_id = mt.membership_type_id
    WHERE t.status = 'issued' AND t.due_date < CURDATE() AND DATEDIFF(CURDATE(), t.due_date) > mt.grace_period_days;

  CREATE VIEW lib_view_most_issued_books AS
    SELECT
        b.book_id, b.title, COUNT(t.transaction_id) as issue_count,
        COUNT(DISTINCT t.member_id) as unique_borrowers,
        AVG(CASE WHEN t.return_date IS NOT NULL THEN DATEDIFF(t.return_date, t.issue_date) END) as avg_loan_days
    FROM lib_books_master b
    LEFT JOIN lib_book_copies c ON b.book_id = c.book_id
    LEFT JOIN lib_transactions t ON c.copy_id = t.copy_id
    WHERE t.status = 'returned'
    GROUP BY b.book_id, b.title
    ORDER BY issue_count DESC;

  -- ----------------------------------------------------------------------------
  -- 10. SEED DATA (Lookup Tables)
  -- ----------------------------------------------------------------------------

  -- Membership Types
  INSERT INTO lib_membership_types (membership_type_code, membership_type_name, max_books_allowed, loan_period_days, fine_rate_per_day, grace_period_days, priority_level) VALUES
    ('STD_STUDENT', 'Standard Student', 5, 14, 5.00, 2, 1),
    ('STD_STAFF', 'Standard Staff', 10, 30, 2.00, 5, 3),
    ('RESEARCH_SCHOLAR', 'Research Scholar', 15, 45, 2.00, 7, 4),
    ('PREMIUM_STUDENT', 'Premium Student', 10, 21, 3.00, 3, 2),
    ('EXTERNAL', 'External Member', 3, 14, 10.00, 0, 0);

  -- Categories
  INSERT INTO lib_categories (category_code, category_name, category_level) VALUES
    ('FIC', 'Fiction', 1),
    ('NFIC', 'Non-Fiction', 1),
    ('SCI', 'Science', 2),
    ('MATH', 'Mathematics', 2),
    ('CS', 'Computer Science', 2),
    ('LIT', 'Literature', 2),
    ('HIST', 'History', 2),
    ('GEO', 'Geography', 2),
    ('ART', 'Art', 2);

  -- Genres
  INSERT INTO lib_genres (genre_code, genre_name) VALUES
    ('SF', 'Science Fiction'),
    ('FAN', 'Fantasy'),
    ('MYS', 'Mystery'),
    ('BIO', 'Biography'),
    ('TECH', 'Technology'),
    ('EDU', 'Educational'),
    ('REF', 'Reference'),
    ('CLS', 'Classics'),
    ('POE', 'Poetry');

  -- Resource Types
  INSERT INTO lib_resource_types (resource_type_code, resource_type_name, is_physical, is_digital) VALUES
    ('PHY_BOOK', 'Physical Book', TRUE, FALSE),
    ('EBOOK', 'E-Book', FALSE, TRUE),
    ('PDF', 'PDF Document', FALSE, TRUE),
    ('AUDIO', 'Audio Book', FALSE, TRUE),
    ('VIDEO', 'Video Resource', FALSE, TRUE),
    ('JOURNAL', 'Journal', TRUE, TRUE),
    ('MAGAZINE', 'Magazine', TRUE, FALSE);

  -- Book Conditions
  INSERT INTO lib_book_conditions (condition_code, condition_name, description, is_borrowable) VALUES
    ('NEW', 'New', 'Brand new condition, never issued', TRUE),
    ('EXC', 'Excellent', 'Like new, no signs of wear', TRUE),
    ('GOOD', 'Good', 'Normal wear and tear, fully readable', TRUE),
    ('FAIR', 'Fair', 'Significant wear but all pages intact', TRUE),
    ('POOR', 'Poor', 'Damaged, may have missing pages', FALSE),
    ('DAMAGED', 'Damaged', 'Needs repair before circulation', FALSE),
    ('LOST', 'Lost', 'Reported lost by member', FALSE),
    ('WITHDRAWN', 'Withdrawn', 'Removed from collection', FALSE);

  -- Shelf Locations
  INSERT INTO lib_shelf_locations (location_code, aisle_number, shelf_number, rack_number, floor_number, building) VALUES
    ('A1-S1-R1', 'A1', 'S1', 'R1', '1', 'Main Library'),
    ('A1-S1-R2', 'A1', 'S1', 'R2', '1', 'Main Library'),
    ('A1-S2-R1', 'A1', 'S2', 'R1', '1', 'Main Library'),
    ('B2-S1-R1', 'B2', 'S1', 'R1', '2', 'Science Block'),
    ('REF-A1', 'REF', 'A1', NULL, '1', 'Reference Section');

  -- --------------------------------------------------------------------------------------------------------------------------
  -- Dropdown Table Entry
  -- use existing Dropdown table of table-name - bok_books column_name - language


-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Change Log
-- --------------------------------------------------------------------------------------------------------------------------------------------------
-- Added Field in Table : lib_book_condition_jnt ; Filed Name : book_copy_id
-- Modfied Field in Table : lib_book_copies ; Filed Name : `rfid_tag`; Old : NOT NULL; New : NULL
-- New table : lib_library_status_masters
-- New table : lib_book_purchases
