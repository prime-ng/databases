-- =========================================================================
-- SYLLABUS BOOKS & NOTES MODULE (v3)
-- =========================================================================
-- Changes from v2:
--   * Fixed trailing comma syntax error in `slb_books`
--   * Fixed wrong FK prefixes (`bok_*` -> `slb_*`)
--   * Added `created_by` column per project conventions
--   * NEW Section 1: Module configuration (`slb_config`)
--   * NEW Section 3: Book file storage with per-file `is_downloadable`
--   * NEW Section 4: Book chapters (notes can be linked to a chapter)
--   * NEW Section 5: Notes (upload by Teacher/Student, approval workflow)
--   * NEW Section 6: Download/view audit trail & ratings
-- =========================================================================


-- =========================================================================
-- SECTION 1: MODULE CONFIGURATION (NEW)
-- =========================================================================

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books > Settings
  -- Tab : 1. Configuration
  -- ---------------------------------------------------------------------
  -- Tenant-wide configuration for Books & Notes upload/download behavior.
  -- One row per tenant (singleton pattern).
  CREATE TABLE IF NOT EXISTS `slb_config` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    -- Book upload constraints
    `max_book_size_mb` SMALLINT UNSIGNED NOT NULL DEFAULT 50,        -- Max book file size (MB)
    `allowed_book_formats` ENUM('PDF','EPUB','JPG','PNG') NOT NULL,  -- e.g. ["PDF","EPUB","JPG","PNG"]
    `is_book_downloadable` TINYINT(1) NOT NULL DEFAULT 0,            -- Default value when uploading a new book
    -- Notes upload constraints
    `max_notes_size_mb` SMALLINT UNSIGNED NOT NULL DEFAULT 20,       -- Max notes file size (MB)
    `allowed_notes_formats` ENUM('PDF','DOCX','JPG','PNG') NOT NULL, -- e.g. ["PDF","DOCX","JPG","PNG"]
    `is_notes_downloadable` TINYINT(1) NOT NULL DEFAULT 1,
    -- Student upload behavior
    `allow_student_notes_upload` TINYINT(1) NOT NULL DEFAULT 1,      -- Master switch
    `student_notes_require_approval` TINYINT(1) NOT NULL DEFAULT 1,  -- Teacher must approve student notes
    `student_max_uploads_per_day` SMALLINT UNSIGNED NOT NULL DEFAULT 5,
    `student_max_uploads_per_subject` SMALLINT UNSIGNED DEFAULT NULL, -- NULL = unlimited
    -- Teacher upload behavior
    `teacher_notes_require_approval` TINYINT(1) NOT NULL DEFAULT 0,  -- Usually auto-approved
    -- Content protection
    `watermark_enabled` TINYINT(1) NOT NULL DEFAULT 0,               -- Add tenant/user watermark on download
    `watermark_text` VARCHAR(150) DEFAULT NULL,                      -- e.g. "Property of {school_name}"
    `prevent_pdf_print` TINYINT(1) NOT NULL DEFAULT 0,               -- Disable print in viewer
    `prevent_pdf_copy` TINYINT(1) NOT NULL DEFAULT 0,                -- Disable text copy in viewer
    -- Visibility defaults
    `notes_visible_to_other_classes` TINYINT(1) NOT NULL DEFAULT 0,  -- Cross-class notes sharing
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================================
-- SECTION 2: BOOK & PUBLICATION MANAGEMENT
-- =========================================================================

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : A. Authors
  -- ---------------------------------------------------------------------
  -- Authors table (Many-to-Many with Books)
  CREATE TABLE IF NOT EXISTS `slb_book_authors` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(150) NOT NULL,                 -- Full name of the author
    `qualification` VARCHAR(200) DEFAULT NULL,    -- e.g. "PhD in Physics", "MSc Mathematics"
    `bio` TEXT DEFAULT NULL,                      -- Short biography of the author
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
    `uuid` BINARY(16) NOT NULL,                       -- UUID
    `isbn` VARCHAR(20) DEFAULT NULL,                  -- International Standard Book Number
    `title` VARCHAR(100) NOT NULL,
    `subtitle` VARCHAR(255) DEFAULT NULL,
    `description` VARCHAR(512) DEFAULT NULL,
    `edition` VARCHAR(50) DEFAULT NULL,               -- e.g., '5th Edition', 'Revised 2024'
    `publication_year` YEAR DEFAULT NULL,             -- e.g., 2024
    `publisher_name` VARCHAR(150) DEFAULT NULL,       -- e.g., 'NCERT', 'S.Chand', 'Pearson'
    `language` INT UNSIGNED NOT NULL,                 -- FK to sys_dropdown_table e.g "English", "Hindi", "Sanskrit"
    `total_pages` INT UNSIGNED DEFAULT NULL,
    `cover_image_media_id` INT UNSIGNED DEFAULT NULL, -- FK to media_files.id
    `tags` JSON DEFAULT NULL,                         -- Additional search tags
    `is_ncert` TINYINT(1) DEFAULT 0,                  -- Flag for NCERT books
    `is_cbse_recommended` TINYINT(1) DEFAULT 0,
    `is_downloadable` TINYINT(1) NOT NULL DEFAULT 0,  -- Master flag: students can download this book
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
    CONSTRAINT `fk_book_cover_image_media_id` FOREIGN KEY (`cover_image_media_id`) REFERENCES `media_files` (`id`)
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
    CONSTRAINT `fk_ba_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`),
    CONSTRAINT `fk_ba_author` FOREIGN KEY (`author_id`) REFERENCES `slb_book_authors` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : 1. Books (Section-1.3)
  -- ---------------------------------------------------------------------
  -- Link Books to Class/Subject (which books are used for which class/subject)
  CREATE TABLE IF NOT EXISTS `slb_book_class_subject_jnt` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_id` INT UNSIGNED NOT NULL,                  -- FK to slb_books.id
    `class_id` INT UNSIGNED NOT NULL,                 -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL,               -- FK to sch_subjects.id
    `academic_session_id` INT UNSIGNED NOT NULL,      -- FK to sch_org_academic_sessions_jnt.id
    `is_primary` TINYINT(1) DEFAULT 1,                -- Primary textbook vs reference
    `is_mandatory` TINYINT(1) DEFAULT 1,
    `remarks` VARCHAR(255) DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_bcs_book_class_subject_session` (`book_id`, `class_id`, `subject_id`, `academic_session_id`),
    CONSTRAINT `fk_bcs_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`),
    CONSTRAINT `fk_bcs_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_bcs_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_bcs_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 3: BOOK FILES (NEW) - Actual uploaded file(s) per book
-- =========================================================================

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : 1. Books (Section-1.4) > Files
  -- ---------------------------------------------------------------------
  -- One book can have multiple file representations (e.g. full PDF + chapter-wise PDFs,
  -- or PDF + EPUB). Per-file `is_downloadable` overrides book-level flag.
  CREATE TABLE IF NOT EXISTS `slb_book_files` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_id` INT UNSIGNED NOT NULL,                  -- FK to slb_books.id
    `media_id` INT UNSIGNED NOT NULL,                 -- FK to media_files.id (actual file)
    `file_format` ENUM('PDF','EPUB','JPG','PNG','DOCX','MOBI','OTHER') NOT NULL,
    `file_size_kb` INT UNSIGNED NOT NULL,
    `label` VARCHAR(150) DEFAULT NULL,                -- e.g. "Full Book", "Chapter 1-5", "Solutions"
    `is_downloadable` TINYINT(1) NOT NULL DEFAULT 0,  -- Per-file override; falls back to slb_books.is_downloadable when NULL semantics aren't needed
    `is_primary` TINYINT(1) NOT NULL DEFAULT 0,       -- Primary file shown by default
    `book_edition` VARCHAR(50) DEFAULT NULL,          -- e.g. "5th Edition", "Revised 2024" (if different from master book record)
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_bf_book` (`book_id`),
    CONSTRAINT `fk_bf_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`),
    CONSTRAINT `fk_bf_media` FOREIGN KEY (`media_id`) REFERENCES `media_files` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 4: BOOK CHAPTERS (NEW) - Chapter index for navigation & note linkage
-- =========================================================================

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books
  -- Tab : 1. Books (Section-1.5) > Chapters
  -- ---------------------------------------------------------------------
  -- Chapter index inside a book. Optional but useful: notes can be tagged
  -- to a specific chapter for easier navigation.
  CREATE TABLE IF NOT EXISTS `slb_book_chapters` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_id` INT UNSIGNED NOT NULL,                  -- FK to slb_books.id
    `chapter_no` SMALLINT UNSIGNED NOT NULL,          -- Sequence within the book
    `title` VARCHAR(255) NOT NULL,
    `start_page` INT UNSIGNED DEFAULT NULL,
    `end_page` INT UNSIGNED DEFAULT NULL,
    `summary` TEXT DEFAULT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_chapter_book_no` (`book_id`, `chapter_no`),
    CONSTRAINT `fk_chap_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================================
-- SECTION 5: NOTES (NEW) - Teacher & Student uploaded study notes
-- =========================================================================

  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books > Notes
  -- Tab : 2. Notes (Section-2.1) > Files
  -- ---------------------------------------------------------------------
  -- One notes record can have multiple attached files (e.g. PDF + supporting images).
  CREATE TABLE IF NOT EXISTS `slb_notes_files` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `notes_id` INT UNSIGNED NOT NULL,                 -- FK to slb_notes.id
    `media_id` INT UNSIGNED NOT NULL,                 -- FK to media_files.id
    `file_format` ENUM('PDF','DOCX','JPG','PNG','EPUB','OTHER') NOT NULL,
    `file_size_kb` INT UNSIGNED NOT NULL,
    `ordinal` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_nf_notes` (`notes_id`),
    CONSTRAINT `fk_nf_notes` FOREIGN KEY (`notes_id`) REFERENCES `slb_notes` (`id`),
    CONSTRAINT `fk_nf_media` FOREIGN KEY (`media_id`) REFERENCES `media_files` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


  -- ---------------------------------------------------------------------
  -- Menu Option : Syllabus Books > Notes
  -- Tab : 2. Notes (Section-2.2)
  -- ---------------------------------------------------------------------
  -- Notes uploaded by Teachers (to help students) or Students (to help peers).
  -- Student-uploaded notes typically require teacher approval before being
  -- visible to other students (controlled by slb_config.student_notes_require_approval).
  CREATE TABLE IF NOT EXISTS `slb_notes` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(150) NOT NULL,
    `description` VARCHAR(1000) DEFAULT NULL,
    -- Academic context
    `class_id` INT UNSIGNED NOT NULL,                 -- FK to sch_classes.id
    `subject_id` INT UNSIGNED NOT NULL,               -- FK to sch_subjects.id
    `academic_session_id` INT UNSIGNED NOT NULL,      -- FK to sch_org_academic_sessions_jnt.id
    `book_id` INT UNSIGNED DEFAULT NULL,              -- Optional: tied to a specific book
    `chapter_id` INT UNSIGNED DEFAULT NULL,           -- Optional: tied to a specific chapter
    `topic` INT UNSIGNED DEFAULT NULL,                -- FK to slb_topics.id for predefined topics
    -- Categorization
    `notes_type` ENUM('LECTURE_NOTES','SAMPLE_PAPER','QUESTION_BANK','SOLUTIONS','SUMMARY','MIND_MAP','REVISION_NOTES','PROJECT','OTHER') NOT NULL DEFAULT 'LECTURE_NOTES',
    `tags` JSON DEFAULT NULL,
    -- Uploader info
    `uploaded_by_user_id` INT UNSIGNED NOT NULL,      -- FK to sys_users.id
    `uploader_role` ENUM('TEACHER','STUDENT','ADMIN') NOT NULL,
    -- Approval workflow
    `status` ENUM('DRAFT','PENDING_APPROVAL','APPROVED','REJECTED','ARCHIVED')
      NOT NULL DEFAULT 'PENDING_APPROVAL',
    `approved_by_user_id` INT UNSIGNED DEFAULT NULL,  -- FK to sys_users.id (teacher/admin)
    `approved_at` TIMESTAMP NULL DEFAULT NULL,
    `rejection_reason` VARCHAR(500) DEFAULT NULL,
    -- Visibility & download control
    `is_downloadable` TINYINT(1) NOT NULL DEFAULT 1,  -- Overrides config default
    `visibility` ENUM('CLASS_ONLY','SUBJECT_WIDE','SCHOOL_WIDE') NOT NULL DEFAULT 'CLASS_ONLY',
    -- Counters (denormalized for performance)
    `view_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `download_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `like_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `avg_rating` DECIMAL(3,2) DEFAULT NULL,           -- 0.00 - 5.00
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_notes_uuid` (`uuid`),
    KEY `idx_notes_class_subject` (`class_id`, `subject_id`, `academic_session_id`),
    KEY `idx_notes_uploader` (`uploaded_by_user_id`),
    KEY `idx_notes_status` (`status`),
    KEY `idx_notes_book_chapter` (`book_id`, `chapter_id`),
    CONSTRAINT `fk_notes_class` FOREIGN KEY (`class_id`) REFERENCES `sch_classes` (`id`),
    CONSTRAINT `fk_notes_subject` FOREIGN KEY (`subject_id`) REFERENCES `sch_subjects` (`id`),
    CONSTRAINT `fk_notes_session` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`),
    CONSTRAINT `fk_notes_book` FOREIGN KEY (`book_id`) REFERENCES `slb_books` (`id`),
    CONSTRAINT `fk_notes_chapter` FOREIGN KEY (`chapter_id`) REFERENCES `slb_book_chapters` (`id`),
    CONSTRAINT `fk_notes_uploader` FOREIGN KEY (`uploaded_by_user_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_notes_approver` FOREIGN KEY (`approved_by_user_id`) REFERENCES `sys_users` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================================
-- SECTION 6: ACTIVITY TRACKING (NEW) - Audit trail for downloads / views / ratings
-- =========================================================================

  -- ---------------------------------------------------------------------
  -- Section-3.1 : Book download audit
  -- ---------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `slb_book_downloads` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `book_file_id` INT UNSIGNED NOT NULL,             -- FK to slb_book_files.id
    `user_id` INT UNSIGNED NOT NULL,                  -- FK to sys_users.id
    `downloaded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_agent` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_bd_book_file` (`book_file_id`),
    KEY `idx_bd_user_date` (`user_id`, `downloaded_at`),
    CONSTRAINT `fk_bd_book_file` FOREIGN KEY (`book_file_id`) REFERENCES `slb_book_files` (`id`),
    CONSTRAINT `fk_bd_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------------------
  -- Section-3.2 : Notes download audit
  -- ---------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `slb_notes_downloads` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `notes_id` INT UNSIGNED NOT NULL,                 -- FK to slb_notes.id
    `user_id` INT UNSIGNED NOT NULL,                  -- FK to sys_users.id
    `downloaded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_agent` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_nd_notes` (`notes_id`),
    KEY `idx_nd_user_date` (`user_id`, `downloaded_at`),
    CONSTRAINT `fk_nd_notes` FOREIGN KEY (`notes_id`) REFERENCES `slb_notes` (`id`),
    CONSTRAINT `fk_nd_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

  -- ---------------------------------------------------------------------
  -- Section-3.3 : Notes ratings (students rate helpful notes)
  -- ---------------------------------------------------------------------
  CREATE TABLE IF NOT EXISTS `slb_notes_ratings` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `notes_id` INT UNSIGNED NOT NULL,                 -- FK to slb_notes.id
    `user_id` INT UNSIGNED NOT NULL,                  -- FK to sys_users.id (rater)
    `rating` TINYINT UNSIGNED NOT NULL,               -- 1-5
    `review` VARCHAR(500) DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_rating_user_notes` (`notes_id`, `user_id`),
    CONSTRAINT `fk_nr_notes` FOREIGN KEY (`notes_id`) REFERENCES `slb_notes` (`id`),
    CONSTRAINT `fk_nr_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `chk_rating_range` CHECK (`rating` BETWEEN 1 AND 5)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
