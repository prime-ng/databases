-- =========================================================================
-- SECTION 1: BOOK & PUBLICATION MANAGEMENT (NEW)
-- =========================================================================

-- ---------------------------------------------------------------------
-- Menu Option : Syllabus Books
-- Tab : A. Authors
-- ---------------------------------------------------------------------

-- Authors table (Many-to-Many with Books)
CREATE TABLE IF NOT EXISTS `slb_book_authors` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `qualification` VARCHAR(200) DEFAULT NULL,
  `bio` TEXT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_author_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Menu Option : Syllabus Books
-- Tab : 1. Books (Section-1.1)
-- ---------------------------------------------------------------------

-- Master table for Books/Publications used across schools
CREATE TABLE IF NOT EXISTS `slb_books` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `uuid` BINARY(16) NOT NULL,  -- UUID 
  `isbn` VARCHAR(20) DEFAULT NULL,              -- International Standard Book Number
  `title` VARCHAR(100) NOT NULL,
  `subtitle` VARCHAR(255) DEFAULT NULL,
  `description` VARCHAR(512) DEFAULT NULL,
  `edition` VARCHAR(50) DEFAULT NULL,           -- e.g., '5th Edition', 'Revised 2024'
  `publication_year` YEAR DEFAULT NULL,         -- e.g., 2024
  `publisher_name` VARCHAR(150) DEFAULT NULL,   -- e.g., 'NCERT', 'S.Chand', 'Pearson'
  `language` INT UNSIGNED NOT NULL,          -- FK to sys_dropdown_table e.g "English", "Hindi", "Sanskrit"
  `total_pages` INT UNSIGNED DEFAULT NULL,
  `cover_image_media_id` INT UNSIGNED DEFAULT NULL,  -- FK to media_files.id
  `tags` JSON DEFAULT NULL,                     -- Additional search tags
  `is_ncert` TINYINT(1) DEFAULT 0,              -- Flag for NCERT books
  `is_cbse_recommended` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book_uuid` (`uuid`),
  UNIQUE KEY `uq_book_isbn` (`isbn`),
  KEY `idx_book_title` (`title`),
  KEY `idx_book_publisher` (`publisher_name`),
  KEY `idx_book_year` (`publication_year`),
  CONSTRAINT `fk_book_language` FOREIGN KEY (`language`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_book_cover_image_media_id` FOREIGN KEY (`cover_image_media_id`) REFERENCES `media_files` (`id`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Menu Option : Syllabus Books
-- Tab : 1. Books (Section-1.2)
-- ---------------------------------------------------------------------
-- Junction: Book-Author relationship
CREATE TABLE IF NOT EXISTS `slb_book_author_jnt` (
  `book_id` INT UNSIGNED NOT NULL,
  `author_id` INT UNSIGNED NOT NULL,
  `author_role` ENUM('PRIMARY','CO_AUTHOR','EDITOR','CONTRIBUTOR') DEFAULT 'PRIMARY',
  `ordinal` TINYINT UNSIGNED DEFAULT 1,
  PRIMARY KEY (`book_id`, `author_id`),
  CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `bok_books` (`id`),
  CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `bok_book_authors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Menu Option : Syllabus Books
-- Tab : 1. Books (Section-1.3)
-- ---------------------------------------------------------------------
-- Link Books to Class/Subject (which books are used for which class/subject)
CREATE TABLE IF NOT EXISTS `slb_book_class_subject_jnt` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `book_id` INT UNSIGNED NOT NULL,  -- FK to slb_books.id
  `class_id` INT UNSIGNED NOT NULL,    -- FK to sch_classes.id
  `subject_id` INT UNSIGNED NOT NULL, -- FK to sch_subjects.id
  `academic_session_id` INT UNSIGNED NOT NULL, -- FK to sch_org_academic_sessions_jnt.id
  `is_primary` TINYINT(1) DEFAULT 1,            -- Primary textbook vs reference
  `is_mandatory` TINYINT(1) DEFAULT 1,
  `remarks` VARCHAR(255) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_bcs_book_class_subject_session` (`book_id`, `class_id`, `subject_id`, `academic_session_id`),
  CONSTRAINT `fk_bcs_book` FOREIGN KEY (`book_id`) REFERENCES `bok_books` (`id`),
  CONSTRAINT `fk_bcs_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
  CONSTRAINT `fk_bcs_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
  CONSTRAINT `fk_bcs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
