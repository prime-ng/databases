-- =====================================================
-- Library Module Database Schema
-- MySQL 8 Compatible
-- =====================================================

-- ----------------------------------------------------------------------------
-- 1. CORE LOOKUP TABLES (System Dropdowns)
-- ----------------------------------------------------------------------------

  -- Defines different types of library memberships with their associated privileges and rules. Controls borrowing limits, loan periods, and fine calculations.
  CREATE TABLE IF NOT EXISTS `lib_membership_types` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `max_books_allowed` INT NOT NULL CHECK (max_books_allowed >= 0),
    `loan_period_days` INT NOT NULL CHECK (loan_period_days > 0),
    `renewal_allowed` TINYINT(1) DEFAULT TRUE,
    `max_renewals` INT DEFAULT 0 CHECK (max_renewals >= 0),
    `fine_rate_per_day` DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (fine_rate_per_day >= 0),
    `grace_period_days` INT DEFAULT 0 CHECK (grace_period_days >= 0),
    `priority_level` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_membership_active` (`is_active`, `is_deleted`),
    INDEX `idx_membership_priority` (`priority_level`),
    UNIQUE KEY `uk_membership_type_code` (`code`),
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization.
  CREATE TABLE IF NOT EXISTS `lib_categories` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `parent_category_id` INT NULL,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255),
    `level` INT DEFAULT 1,
    `display_order` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`parent_category_id`) REFERENCES `lib_categories`(`category_id`),
    INDEX `idx_category_parent` (`parent_category_id`),
    INDEX `idx_category_active` (`is_active`, `is_deleted`),
    INDEX `idx_category_order` (`display_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tags for literary genres that can be applied across categories for flexible searching and recommendations.
  CREATE TABLE IF NOT EXISTS `lib_genres` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255),
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_genre_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Master list of publishers for books and resources.
  CREATE TABLE IF NOT EXISTS `lib_publishers` ( 
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(200) NOT NULL,
    `address` TEXT,
    `contact` VARCHAR(100),
    `email` VARCHAR(100),
    `phone` VARCHAR(20),
    `website` VARCHAR(255),
    `is_active` TINYINT(1) DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_publisher_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Classification of resource formats (physical books, e-books, PDFs, audio books, etc.) to handle different media types appropriately.
  CREATE TABLE IF NOT EXISTS `lib_resource_types` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `is_physical` TINYINT(1) NOT NULL DEFAULT 1,
    `is_digital` TINYINT(1) NOT NULL DEFAULT 0,
    `is_audio_books` TINYINT(1) NOT NULL DEFAULT 0,
    `is_borrowable` TINYINT(1) NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_restype_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Physical location mapping for books in the library, enabling efficient shelving and retrieval. 
  CREATE TABLE IF NOT EXISTS `lib_shelf_locations` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `aisle_number` VARCHAR(20) NOT NULL,  -- These numbers are listed on signs at the end of shelves (e.g., Aisle 1, Side A)
    `shelf_number` VARCHAR(20) NOT NULL,  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `rack_number` VARCHAR(20),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `floor_number` VARCHAR(10),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `building` VARCHAR(100),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `zone` VARCHAR(50),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `description` VARCHAR(255),  -- These numbers are usually on the side of the shelf (e.g., Shelf 1, 2, 3)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uk_shelf_location` (`aisle_number`, `shelf_number`, `rack_number`),
    INDEX `idx_location_active` (`is_active`, `is_deleted`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  -- Conditions:
  -- Aisle Number - An aisle is the open passage or walkway between rows of shelving units.
  -- shelf_number - A shelf is a flat, horizontal surface, typically made of wood or metal, used for storing or displaying items.
  -- rack_number - A rack is a framework, typically consisting of bars or hooks, used for storing or displaying items.
  -- floor_number - A floor is the lower surface of a room, on which one walks.
  -- zone - A zone is an area or stretch of land having a particular characteristic, purpose, or use, or subject to particular restrictions.
  -- description - A description is a spoken or written representation or account of a person, object, or event.
  -- Physical location mapping for books in the library, enabling efficient shelving and retrieval.

  -- Standardized condition states for physical books to track wear and tear, damage, and usability.
  CREATE TABLE IF NOT EXISTS `lib_book_conditions` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(50) NOT NULL,
    `description` VARCHAR(255),
    `is_borrowable` TINYINT(1) NOT NULL DEFAULT 1,  -- Whether books in this condition can be issued
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_condition_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. MASTER TABLES
-- ----------------------------------------------------------------------------

  -- Master catalog of all books and resources owned by the library.
  CREATE TABLE IF NOT EXISTS `lib_books_master` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `title` VARCHAR(500) NOT NULL,
    `subtitle` VARCHAR(500),
    `edition` VARCHAR(50),                                              -- Edition of the book (e.g., 1st, 2nd, 3rd)
    `isbn` VARCHAR(20) UNIQUE,                                          -- International Standard Book Number - A unique identifier for books
    `issn` VARCHAR(20),                                                 -- International Standard Serial Number - A unique identifier for serials
    `doi` VARCHAR(100),                                                 -- Digital Object Identifier - A unique identifier for digital objects
    `publication_year` INT,                                             -- Year the book was published
    `publisher_id` INT,                                                 -- FK to lib_publishers
    `language` VARCHAR(50) DEFAULT 'English',                           -- FK to sys_dropdown_table (Map with Exisiting Dropdown table-name - bok_books coloumn_name - language)
    `page_count` INT CHECK (page_count > 0),                            -- Number of pages in the book
    `summary` TEXT,                                                     -- Summary of the book
    `table_of_contents` TEXT,                                           -- Table of contents of the book
    `cover_image_url` VARCHAR(500),                                     -- URL of the cover image
    `resource_type_id` INT NOT NULL,                                    -- FK to lib_resource_types
    `is_reference_only` TINYINT(1) NOT NULL DEFAULT 0,                  -- Whether book cannot be borrowed (in-library use only)
    -- Analytics
    `lexile_level` VARCHAR(20) NULL,                                    -- Reading difficulty level
    `reading_age_range` VARCHAR(20) NULL,                               -- e.g., 8-12 years
    `awards` TEXT NULL,                                                 -- List of awards won by book
    `series_name` VARCHAR(200) NULL,                                    -- Series name of the book
    `series_position` INT NULL,                                         -- Position of the book in the series
    `popularity_rank` INT NULL,                                         -- Popularity rank of the book
    `academic_rating` DECIMAL(3,2) NULL,                                -- Rating by faculty
    `student_rating` DECIMAL(3,2) NULL,                                 -- Average student rating
    `rating_count` INT DEFAULT 0,                                       -- Number of ratings
    `curricular_relevance_score` DECIMAL(5,2) NOT NULL DEFAULT 0.00,    -- Curricular relevance score
    `tags` JSON NULL,                                                   -- Auto-generated tags from AI analysis
    `ai_summary` TEXT NULL,                                             -- AI-generated summary
    `key_concepts` JSON NULL,                                           -- Key concepts extracted from book
    -- Audit
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`publisher_id`) REFERENCES `lib_publishers`(`publisher_id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`resource_type_id`),
    INDEX `idx_book_title` (`title`(191)),
    INDEX `idx_book_isbn` (`isbn`),
    INDEX `idx_book_year` (`publication_year`),
    INDEX `idx_book_active` (`is_active`),
    INDEX `idx_book_publisher` (`publisher_id`),
    FULLTEXT INDEX `ft_book_search` (`title`, `subtitle`, `summary`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lib_authors` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `short_name` VARCHAR(50) NOT NULL,
  `author_name` VARCHAR(200) NOT NULL,
  `country` VARCHAR(120),  -- FK to glb_countries
  `primary_genre_id` INT,  -- FK to lib_genres
  `notes` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL,
  UNIQUE KEY `uq_author_shortName` (`short_name`),
  UNIQUE KEY `uq_author_name` (`author_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

  -- Junction table to link books with their authors (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_author_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master
    `author_id` INT NOT NULL,  -- FK to lib_authors
    `author_order` INT NOT NULL DEFAULT 1,
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`author_id`) REFERENCES `lib_authors`(`id`) ON DELETE CASCADE, 
    UNIQUE KEY `uk_book_author` (`book_id`, `author_id`, `author_order`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their categories (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_category_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master
    `category_id` INT NOT NULL,  -- FK to lib_categories
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `category_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`category_id`) ON DELETE CASCADE,
    INDEX `idx_category_book` (`category_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their genres (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_genre_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master
    `genre_id` INT NOT NULL,  -- FK to lib_genres
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `genre_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`genre_id`) REFERENCES `lib_genres`(`genre_id`) ON DELETE CASCADE,
    INDEX `idx_genre_book` (`genre_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their subjects (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_subject_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,  -- FK to lib_books_master.book_id
    `class_id` INT NOT NULL,  -- FK to sch_classes.id
    `subject_id` INT NOT NULL,  -- FK to sch_subjects.id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_subject_book` (`class_id`, `subject_id`, `book_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`class_id`) ON DELETE CASCADE,
    FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`subject_id`) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Tags for literary genres that can be applied across categories for flexible searching and recommendations.
  CREATE TABLE IF NOT EXISTS `lib_keywords` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `code` VARCHAR(30) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    INDEX `idx_keyword_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their keywords (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_keyword_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,         -- FK to lib_books_master.book_id
    `keyword_id` INT NOT NULL,      -- FK to lib_keywords.keyword_id
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `keyword_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`keyword_id`) REFERENCES `lib_keywords`(`keyword_id`) ON DELETE CASCADE,
    INDEX `idx_keyword_book` (`keyword_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- Junction table to link books with their conditions (many-to-many).
  CREATE TABLE IF NOT EXISTS `lib_book_condition_jnt` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `date` DATE NOT NULL,
    `book_id` INT NOT NULL,         -- FK to lib_books_master.book_id
    `condition_id` INT NOT NULL,    -- FK to lib_book_conditions.condition_id
    `note` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    PRIMARY KEY (`book_id`, `condition_id`),
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`) ON DELETE CASCADE,
    FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`condition_id`) ON DELETE CASCADE,
    INDEX `idx_condition_book` (`condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- RESOURCES MANAGEMENT
-- ----------------------------------------------------------------------------

-- Item-level tracking of each physical copy of a book, including location, condition, and circulation status.
  CREATE TABLE IF NOT EXISTS `lib_book_copies` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,                 -- FK to lib_books_master.book_id
    `accession_number` VARCHAR(50) NOT NULL,
    `barcode` VARCHAR(100) NOT NULL,
    `rfid_tag` VARCHAR(100) NOT NULL,
    `shelf_location_id` INT NULL,           -- FK to lib_shelf_locations.shelf_location_id
    `current_condition_id` INT NOT NULL,    -- FK to lib_book_conditions.condition_id
    `purchase_date` DATE NOT NULL,
    `purchase_price` DECIMAL(10,2) NOT NULL DEFAULT 0,
    `vendor_id` INT NULL,                   -- FK to vnd_vendors.vendor_id
    `is_lost` TINYINT(1) NOT NULL DEFAULT 0,
    `is_damaged` TINYINT(1) NOT NULL DEFAULT 0,
    `is_withdrawn` TINYINT(1) NOT NULL DEFAULT 0,  -- Whether copy is withdrawn from collection
    `withdrawal_reason` VARCHAR(512),
    `status` ENUM('available', 'issued', 'reserved', 'under_maintenance', 'lost', 'withdrawn') DEFAULT 'available',
    `notes` TEXT,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
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
    FOREIGN KEY (`current_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_digital_resources` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,                 -- FK to lib_books_master.book_id
    `file_name` VARCHAR(255) NOT NULL,
    `file_media_id` INT UNSIGNED DEFAULT NULL,     -- FK to media_files.id
    `file_path` VARCHAR(500) NOT NULL,
    `file_size_bytes` BIGINT,
    `mime_type` VARCHAR(100),
    `file_format` VARCHAR(50),
    `download_count` INT DEFAULT 0,
    `view_count` INT DEFAULT 0,
    `license_key` VARCHAR(100),
    `license_type` VARCHAR(50),
    `license_start_date` DATE,
    `license_end_date` DATE,
    `access_restriction` JSON,  -- JSON defining access rules (user roles, IP ranges, etc.)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`file_media_id`) REFERENCES `media_files`(id),
    INDEX `idx_digital_book` (`book_id`),
    INDEX `idx_digital_license` (`license_start_date`, `license_end_date`),
    INDEX `idx_digital_active` (`is_active`),
    FULLTEXT INDEX `ft_digital_search` (`file_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_digital_resource_tags` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `digital_resource_id` INT NOT NULL,
    `tag_name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`digital_resource_id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_resource_tag` (`digital_resource_id`, `tag_name`),
    INDEX `idx_tag_name` (`tag_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_members` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `user_id` INT NOT NULL,
    `membership_type_id` INT NOT NULL,
    `membership_number` VARCHAR(50) NOT NULL,
    `library_card_barcode` VARCHAR(100),
    `registration_date` DATE NOT NULL,
    `expiry_date` DATE NOT NULL,
    `is_auto_renew` TINYINT(1) NOT NULL DEFAULT 1,
    `last_activity_date` DATE,
    `total_books_borrowed` INT DEFAULT 0,
    `total_fines_paid` DECIMAL(10,2) DEFAULT 0.00,
    `outstanding_fines` DECIMAL(10,2) DEFAULT 0.00 CHECK (outstanding_fines >= 0),
    `status` ENUM('active', 'expired', 'suspended', 'deactivated') DEFAULT 'active',
    `suspension_reason` TEXT,
    `notes` TEXT,
    -- analytics
    `reading_level` ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NULL,
    `preferred_notification_channel` ENUM('Email', 'SMS', 'Push', 'InApp') DEFAULT 'Email',
    `member_segment` VARCHAR(50) COMMENT 'e.g., High-Value, At-Risk, Inactive, New',
    `last_segment_calculation` TIMESTAMP NULL,
    `engagement_score` DECIMAL(5,2) DEFAULT 0.00,
    `churn_risk_score` DECIMAL(5,2) DEFAULT 0.00,
    `lifetime_value` DECIMAL(10,2) DEFAULT 0.00,
    `preferred_language` VARCHAR(50) DEFAULT 'English',
    `reading_goal_annual` INT DEFAULT 0,
    `reading_progress_ytd` INT DEFAULT 0,
    -- system
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uq_member_user` (`user_id`),
    UNIQUE KEY `uq_member_membership_number` (`membership_number`),
    UNIQUE KEY `uq_member_library_card_barcode` (`library_card_barcode`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(id),  -- Reference to main users table
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(membership_type_id),
    INDEX `idx_member_membership` (`membership_type_id`),
    INDEX `idx_member_status` (`status`, `expiry_date`),
    INDEX `idx_member_active` (`is_active`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- OPERATION MANAGEMENT
-- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_transactions` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `copy_id` INT NOT NULL,  -- fk to lib_book_copies.id
    `member_id` INT NOT NULL,  -- fk to lib_members.id
    `issue_date` DATETIME NOT NULL,
    `due_date` DATE NOT NULL,
    `return_date` DATETIME NULL,
    `issued_by_id` INT NOT NULL,  -- fk sys_user.id
    `received_by_id` INT NULL,  -- fk sys_user.id
    `issue_condition_id` INT NOT NULL,  -- fk lib_book_conditions.id
    `return_condition_id` INT NULL,  -- fk lib_book_conditions.id
    `is_renewed` TINYINT(1) NOT NULL DEFAULT 0,
    `renewal_count` INT DEFAULT 0,
    `status` ENUM('Issued', 'Returned', 'Overdue', 'Lost') DEFAULT 'Issued',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`copy_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    FOREIGN KEY (`issued_by_id`) REFERENCES `sys_users`(id),
    FOREIGN KEY (`received_by_id`) REFERENCES `sys_users`(id),
    FOREIGN KEY (`issue_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    FOREIGN KEY (`return_condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    INDEX `idx_trans_copy` (`copy_id`, `status`),
    INDEX `idx_trans_member` (`member_id`, `status`),
    INDEX `idx_trans_dates` (`issue_date`, `due_date`, `return_date`),
    INDEX `idx_trans_status` (`status`, `due_date`),
    INDEX `idx_trans_issued_by` (`issued_by`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_reservations` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `book_id` INT NOT NULL,    -- fk to lib_books_master.id
    `member_id` INT NOT NULL,  -- fk to lib_members.id
    `reservation_date` DATETIME NOT NULL,
    `expected_available_date` DATE NOT NULL,
    `notification_sent` TINYINT(1) NOT NULL DEFAULT 0,
    `notification_sent_at` DATETIME NULL,
    `pickup_by_date` DATE NULL,
    `status` ENUM('Pending', 'Available', 'Picked_Up', 'Cancelled', 'Expired') DEFAULT 'Pending',
    `queue_position` INT NOT NULL DEFAULT 1,
    `cancellation_reason` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    UNIQUE KEY `uk_active_reservation` (`book_id`, `member_id`, `status`),
    INDEX `idx_reserve_book` (`book_id`, `status`, `queue_position`),
    INDEX `idx_reserve_member` (`member_id`, `status`),
    INDEX `idx_reserve_status` (`status`, `pickup_by_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` BIGINT NOT NULL,  -- fk to lib_transactions.id
    `member_id` INT NOT NULL,  -- fk to lib_members.id
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    `days_overdue` INT NOT NULL DEFAULT 0,
    `calculated_from` DATE NOT NULL,
    `calculated_to` DATE NOT NULL,
    `waived_amount` DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),
    `waived_by_id` INT NOT NULL,  -- fk sys_user.id
    `waived_reason` TEXT NOT NULL,
    `waived_at` DATETIME NOT NULL,
    `status` ENUM('Pending', 'Paid', 'Waived', 'Overdue') DEFAULT 'Pending',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`transaction_id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
    FOREIGN KEY (`waived_by_id`) REFERENCES `sys_users`(id),
    INDEX `idx_fine_transaction` (`transaction_id`),
    INDEX `idx_fine_member` (`member_id`, `status`),
    INDEX `idx_fine_status` (`status`, `created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_fine_payments` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `fine_id` INT NOT NULL,  -- fk to lib_fines.id
    `amount_paid` DECIMAL(10,2) NOT NULL CHECK (amount_paid > 0),
    `payment_method` ENUM('Cash', 'Card', 'Online', 'Waiver') NOT NULL,
    `payment_reference` VARCHAR(100),
    `payment_date` DATETIME NOT NULL,
    `received_by_id` INT NOT NULL,  -- sys_user.id
    `receipt_number` VARCHAR(50) NOT NULL,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    UNIQUE KEY `uk_payment_receipt` (`receipt_number`),
    FOREIGN KEY (`fine_id`) REFERENCES `lib_fines`(`fine_id`),
    FOREIGN KEY (`received_by_id`) REFERENCES `users`(id),
    INDEX `idx_payment_fine` (`fine_id`),
    INDEX `idx_payment_receipt` (`receipt_number`),
    INDEX `idx_payment_date` (`payment_date`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS `lib_fine_slab_config` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Standard Student Fine Slab, Staff Fine Slab',
    `membership_type_id` INT NULL COMMENT 'If NULL, applies to all membership types',
    `resource_type_id` INT NULL COMMENT 'If NULL, applies to all resource types',
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') DEFAULT 'Late Return',
    `max_fine_amount` DECIMAL(10,2) NULL COMMENT 'Maximum fine cap (could be book cost or school-defined limit)',
    `max_fine_type` ENUM('Fixed', 'BookCost', 'Unlimited') DEFAULT 'Unlimited',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `effective_from` DATE NOT NULL,
    `effective_to` DATE NULL,
    `priority` INT DEFAULT 0 COMMENT 'Higher priority slabs are evaluated first',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`membership_type_id`) REFERENCES `lib_membership_types`(`id`),
    FOREIGN KEY (`resource_type_id`) REFERENCES `lib_resource_types`(`id`),
    INDEX `idx_fine_slab_membership` (`membership_type_id`),
    INDEX `idx_fine_slab_active` (`is_active`, `effective_from`, `effective_to`),
    INDEX `idx_fine_slab_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. FINE SLAB DETAILS TABLE (for day ranges)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lib_fine_slab_details` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `fine_slab_config_id` INT NOT NULL,
    `from_day` INT NOT NULL CHECK (from_day >= 0),
    `to_day` INT NOT NULL CHECK (to_day >= from_day),
    `rate_per_day` DECIMAL(10,2) NOT NULL,
    `rate_type` ENUM('Fixed', 'Percentage') DEFAULT 'Fixed' COMMENT 'Fixed amount or percentage of book cost',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_slab_days` (`fine_slab_config_id`, `from_day`, `to_day`),
    INDEX `idx_slab_day_range` (`from_day`, `to_day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. ENHANCED LIB_FINES TABLE (modified)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lib_fines` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` BIGINT NOT NULL,
    `member_id` INT NOT NULL,
    `fine_type` ENUM('Late Return', 'Lost Book', 'Damaged Book', 'Processing Fee') NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    `days_overdue` INT NOT NULL DEFAULT 0,
    `calculated_from` DATE NOT NULL,
    `calculated_to` DATE NOT NULL,
    `fine_slab_config_id` INT NULL COMMENT 'Reference to slab used for calculation',
    `calculation_breakdown` JSON COMMENT 'Stores day-wise breakdown of fine calculation',
    `waived_amount` DECIMAL(10,2) DEFAULT 0.00 CHECK (waived_amount >= 0),
    `waived_by_id` INT NULL,
    `waived_reason` TEXT NULL,
    `waived_at` DATETIME NULL,
    `status` ENUM('Pending', 'Paid', 'Waived', 'Overdue') DEFAULT 'Pending',
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`),
    FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`),
    FOREIGN KEY (`waived_by_id`) REFERENCES `users`(id),
    FOREIGN KEY (`fine_slab_config_id`) REFERENCES `lib_fine_slab_config`(`id`),
    INDEX `idx_fine_transaction` (`transaction_id`),
    INDEX `idx_fine_member` (`member_id`, `status`),
    INDEX `idx_fine_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;






-- ----------------------------------------------------------------------------
-- AUDIT AND HISTORY
-- ----------------------------------------------------------------------------

  CREATE TABLE IF NOT EXISTS `lib_transaction_history` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `transaction_id` INT NOT NULL,  -- fk to lib_transactions.id
    `action_type` ENUM('issued', 'returned', 'renewed', 'marked_lost', 'condition_updated') NOT NULL,
    `old_value` JSON,
    `new_value` JSON,
    `performed_by_id` INT NOT NULL,  -- sys_user.id
    `performed_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`transaction_id`),
    FOREIGN KEY (`performed_by`) REFERENCES `users`(id),
    INDEX `idx_history_transaction` (`transaction_id`),
    INDEX `idx_history_performed` (`performed_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_inventory_audit` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `uuid` CHAR(36) NOT NULL UNIQUE,
    `audit_date` DATE NOT NULL,
    `performed_by_id` INT NOT NULL,  -- sys_user.id
    `total_scanned` INT DEFAULT 0,
    `total_expected` INT DEFAULT 0,
    `missing_copies` INT DEFAULT 0,
    `misplaced_copies` INT DEFAULT 0,
    `damaged_copies` INT DEFAULT 0,
    `status` ENUM('In Progress', 'Completed', 'Cancelled') DEFAULT 'In Progress',
    `completed_at` DATETIME NULL,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL,
    FOREIGN KEY (`performed_by`) REFERENCES `users`(id),
    INDEX `idx_audit_date` (`audit_date`),
    INDEX `idx_audit_status` (`status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  CREATE TABLE IF NOT EXISTS `lib_inventory_audit_details` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
    `audit_id` BIGINT NOT NULL,
    `copy_id` INT NOT NULL,
    `expected_location_id` INT,
    `actual_location_id` INT,
    `scanned_at` DATETIME NOT NULL,
    `condition_id` INT,
    `status` ENUM('found', 'missing', 'misplaced', 'damaged') DEFAULT 'found',
    `notes` TEXT,
    FOREIGN KEY (`audit_id`) REFERENCES `lib_inventory_audit`(`audit_id`) ON DELETE CASCADE,
    FOREIGN KEY (`copy_id`) REFERENCES `lib_book_copies`(`copy_id`),
    FOREIGN KEY (`expected_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
    FOREIGN KEY (`actual_location_id`) REFERENCES `lib_shelf_locations`(`shelf_location_id`),
    FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`condition_id`),
    INDEX `idx_audit_details_audit` (`audit_id`),
    INDEX `idx_audit_details_copy` (`copy_id`),
    UNIQUE KEY `uk_audit_copy` (`audit_id`, `copy_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;




-- ----------------------------------------------------------------------------
-- ADVANCED ANALYTICS & INSIGHTS
-- ----------------------------------------------------------------------------
	-- Tracks individual member reading patterns, preferences, and behavior metrics for personalized recommendations and engagement analysis.
	CREATE TABLE IF NOT EXISTS `lib_reading_behavior_analytics` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`member_id` INT NOT NULL,
			`academic_year` VARCHAR(20) NOT NULL,
			`total_books_read` INT DEFAULT 0,
			`total_pages_read` BIGINT DEFAULT 0,
			`avg_reading_days_per_book` DECIMAL(5,2),
			`preferred_genre_id` INT,
			`preferred_category_id` INT,
			`preferred_language` VARCHAR(50),
			`avg_loan_completion_rate` DECIMAL(5,2) COMMENT 'Percentage of books returned on time',
			`peak_borrowing_month` INT,
			`peak_borrowing_day` VARCHAR(20),
			`reading_consistency_score` DECIMAL(5,2) COMMENT '0-100 score based on borrowing regularity',
			`genre_diversity_index` DECIMAL(5,2) COMMENT 'Shannon diversity index for genres',
			`author_diversity_index` DECIMAL(5,2),
			`preferred_borrowing_time` ENUM('Morning', 'Afternoon', 'Evening', 'Weekend'),
			`digital_vs_physical_ratio` DECIMAL(5,2),
			`renewal_frequency` DECIMAL(5,2) COMMENT 'Average renewals per book',
			`reservation_frequency` INT DEFAULT 0,
			`reading_speed_estimate` DECIMAL(5,2) COMMENT 'Estimated pages per day',
			`completion_rate_trend` DECIMAL(5,2) COMMENT 'Month-over-month trend',
			`last_calculated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`member_id`),
			FOREIGN KEY (`preferred_genre_id`) REFERENCES `lib_genres`(`genre_id`),
			FOREIGN KEY (`preferred_category_id`) REFERENCES `lib_categories`(`category_id`),
			INDEX `idx_reading_behavior_member` (`member_id`, `academic_year`),
			INDEX `idx_reading_behavior_genre` (`preferred_genre_id`),
			INDEX `idx_reading_behavior_score` (`reading_consistency_score`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	--Tracks real-time and historical popularity metrics for books to optimize acquisition and shelving decisions.
	CREATE TABLE IF NOT EXISTS `lib_book_popularity_trends` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`book_id` INT NOT NULL,
			`tracking_date` DATE NOT NULL,
			`daily_requests` INT DEFAULT 0,
			`daily_issues` INT DEFAULT 0,
			`daily_reservations` INT DEFAULT 0,
			`daily_digital_views` INT DEFAULT 0,
			`daily_digital_downloads` INT DEFAULT 0,
			`popularity_score` DECIMAL(5,2) COMMENT 'Weighted composite score',
			`trend_direction` ENUM('Rising', 'Falling', 'Stable') DEFAULT 'Stable',
			`velocity_score` DECIMAL(5,2) COMMENT 'Rate of popularity change',
			`seasonality_factor` DECIMAL(5,2) COMMENT 'Seasonal adjustment factor',
			`peer_comparison_rank` INT COMMENT 'Rank among similar books',
			`shelf_turnover_rate` DECIMAL(5,2) COMMENT 'How often book moves from shelf',
			`waitlist_length` INT DEFAULT 0,
			`avg_wait_days` DECIMAL(5,2),
			`recommendation_weight` DECIMAL(5,2) COMMENT 'Weight for recommendation engine',
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
			UNIQUE KEY `uk_book_daily_trend` (`book_id`, `tracking_date`),
			INDEX `idx_popularity_date` (`tracking_date`),
			INDEX `idx_popularity_score` (`popularity_score`),
			INDEX `idx_popularity_trend` (`trend_direction`, `velocity_score`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Provides comprehensive metrics on the health, diversity, and utilization of the library collection.
	CREATE TABLE IF NOT EXISTS `lib_collection_health_metrics` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`metric_date` DATE NOT NULL,
			`category_id` INT,
			`genre_id` INT,
			`total_titles` INT DEFAULT 0,
			`total_copies` INT DEFAULT 0,
			`active_titles` INT DEFAULT 0,
			`inactive_titles` INT DEFAULT 0,
			`damaged_copies` INT DEFAULT 0,
			`lost_copies` INT DEFAULT 0,
			`withdrawn_copies` INT DEFAULT 0,
			`utilization_rate` DECIMAL(5,2) COMMENT 'Percentage of collection in circulation',
			`turnover_rate` DECIMAL(5,2) COMMENT 'Average issues per copy',
			`age_of_collection` DECIMAL(5,2) COMMENT 'Average age in years',
			`collection_diversity_score` DECIMAL(5,2) COMMENT 'Based on genre/category distribution',
			`relevance_score` DECIMAL(5,2) COMMENT 'How well collection matches demand',
			`acquisition_effectiveness` DECIMAL(5,2) COMMENT 'ROI on new acquisitions',
			`weeding_priority_score` DECIMAL(5,2) COMMENT 'Priority for removal/replacement',
			`budget_allocation_efficiency` DECIMAL(5,2),
			`digital_penetration_rate` DECIMAL(5,2),
			`physical_vs_digital_ratio` DECIMAL(5,2),
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX `idx_health_date` (`metric_date`),
			INDEX `idx_health_category` (`category_id`),
			INDEX `idx_health_genre` (`genre_id`),
			INDEX `idx_health_utilization` (`utilization_rate`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Stores predictive model outputs for demand forecasting, member churn prediction, and resource optimization.
	CREATE TABLE IF NOT EXISTS `lib_predictive_analytics` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`prediction_date` DATE NOT NULL,
			`prediction_type` ENUM(
					'Demand_Forecast', 
					'Member_Churn', 
					'Resource_Optimization', 
					'Acquisition_Recommendation',
					'Seasonal_Pattern',
					'Budget_Projection'
			) NOT NULL,
			`target_entity_type` ENUM('Book', 'Category', 'Genre', 'Member', 'Department', 'All') NOT NULL,
			`target_entity_id` INT,
			`prediction_period_start` DATE NOT NULL,
			`prediction_period_end` DATE NOT NULL,
			`predicted_value` DECIMAL(10,2) NOT NULL,
			`confidence_score` DECIMAL(5,2) COMMENT '0-100 confidence level',
			`actual_value` DECIMAL(10,2),
			`accuracy_score` DECIMAL(5,2),
			`model_version` VARCHAR(50),
			`features_used` JSON COMMENT 'Features used in prediction',
			`insights` TEXT,
			`recommendations` TEXT,
			`is_active` TINYINT(1) DEFAULT 1,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			INDEX `idx_predictive_type` (`prediction_type`, `prediction_date`),
			INDEX `idx_predictive_entity` (`target_entity_type`, `target_entity_id`),
			INDEX `idx_predictive_period` (`prediction_period_start`, `prediction_period_end`),
			INDEX `idx_predictive_confidence` (`confidence_score`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Tracks how well library resources align with curriculum requirements and academic schedules.
	CREATE TABLE IF NOT EXISTS `lib_curricular_alignment` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`academic_year` VARCHAR(20) NOT NULL,
			`class_id` INT NOT NULL,
			`subject_id` INT NOT NULL,
			`book_id` INT NOT NULL,
			`alignment_score` DECIMAL(5,2) COMMENT 'How well book aligns with curriculum',
			`recommended_by_faculty` TINYINT(1) DEFAULT 0,
			`faculty_rating` DECIMAL(3,2) COMMENT '1-5 rating from faculty',
			`student_usage_count` INT DEFAULT 0,
			`exam_reference_count` INT DEFAULT 0 COMMENT 'Times referenced in exams',
			`assignment_citations` INT DEFAULT 0,
			`curriculum_unit` VARCHAR(200),
			`term_recommended` ENUM('Term1', 'Term2', 'Term3', 'All'),
			`priority_level` ENUM('Essential', 'Recommended', 'Supplementary', 'Optional') DEFAULT 'Supplementary',
			`notes` TEXT,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			FOREIGN KEY (`class_id`) REFERENCES `sch_classes`(`class_id`),
			FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects`(`subject_id`),
			FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`book_id`),
			UNIQUE KEY `uk_curricular_book` (`academic_year`, `class_id`, `subject_id`, `book_id`),
			INDEX `idx_curricular_alignment` (`alignment_score`),
			INDEX `idx_curricular_priority` (`priority_level`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

	-- Tracks granular user interactions with the library system for detailed behavior analysis.
	CREATE TABLE IF NOT EXISTS `lib_engagement_events` (
			`id` BIGINT PRIMARY KEY AUTO_INCREMENT,
			`member_id` INT NOT NULL,
			`event_type` ENUM('Search','Browse','View_Details','Add_Reservation','Cancel_Reservation','Renew_Online','Digital_View','Digital_Download','Read_Online','Share_Resource','Add_Review','Rate_Book','Save_To_Wishlist','Request_Purchase','Ask_Librarian','Attend_Event') NOT NULL,
			`book_id` INT,
			`digital_resource_id` INT,
			`search_query` VARCHAR(500),
			`filters_used` JSON,
			`session_id` VARCHAR(100),
			`device_type` ENUM('Desktop', 'Mobile', 'Tablet', 'Kiosk'),
			`browser` VARCHAR(50),
			`ip_address` VARCHAR(45),
			`location_id` INT COMMENT 'Physical location if in library',
			`time_spent_seconds` INT,
			`interaction_outcome` VARCHAR(255),
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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

	-- Trigger to automatically calculate fines on overdue items
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
        pa.predicted_value as predicted_next_3_months, pa.confidence_score, pa.insights, pa.recommendations, ca.alignment_score as curricular_relevance,
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
    t.transaction_id, b.title, b.isbn, c.barcode, m.membership_number, u.first_name, u.last_name, u.email, u.phone, t.due_date, DATEDIFF(CURDATE(), t.due_date) as days_overdue, 
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
    b.book_id, b.title, COUNT(t.transaction_id) as issue_count, COUNT(DISTINCT t.member_id) as unique_borrowers,
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

-- use existing Dropdown table of table-name - bok_books coloumn_name - language
