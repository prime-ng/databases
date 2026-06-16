-- =============================================================================
-- CAF — Cafeteria Module DDL
-- Module: Cafeteria (Modules\Cafeteria)
-- Table Prefix: caf_* (21 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-27
-- Based on: CAF_Cafeteria_Requirement.md v2
-- Sub-Modules: L1 Menu Planning, L2 Orders & Attendance,
--              L3 Meal Cards & POS, L4 Stock & Compliance
-- NOTE: All caf_* PKs and intra-module FKs use INT UNSIGNED (not BIGINT).
--       Cross-module refs to sys_users use INT UNSIGNED (verified:
--       sys_users.id = INT UNSIGNED at line 88 of tenant_db_v2.sql).
--       sch_academic_term.id = SMALLINT UNSIGNED (singular table, verified).
-- CORRECTION: Requirement doc claims sys_users refs = BIGINT UNSIGNED.
--             Actual DDL shows sys_users.id = INT UNSIGNED. Corrected here.
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================================
-- LAYER 1 — No caf_* dependencies (may reference sys_*/std_*/sch_* only)
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 1. caf_menu_categories
-- Meal-type category master (Breakfast, Lunch, Snacks, Dinner, Tuck Shop)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_menu_categories` (
  `id`               INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name`             VARCHAR(100)     NOT NULL                COMMENT 'Category name e.g. Breakfast, Lunch',
  `code`             VARCHAR(20)      NULL     DEFAULT NULL   COMMENT 'Short code e.g. BRK, LNC, SNK — nullable UNIQUE',
  `meal_time`        ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop')
                                      NOT NULL                COMMENT 'Serving type',
  `meal_start_time`  TIME             NULL     DEFAULT NULL   COMMENT 'Scheduled serving start time',
  `description`      TEXT             NULL     DEFAULT NULL   COMMENT 'Optional description',
  `display_order`    TINYINT UNSIGNED NOT NULL DEFAULT 0      COMMENT 'Sort order on student portal',
  `is_active`        TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`       INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`       TIMESTAMP        NULL     DEFAULT NULL,
  `updated_at`       TIMESTAMP        NULL     DEFAULT NULL,
  `deleted_at`       TIMESTAMP        NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_mc_code` (`code`),
  KEY `idx_caf_mc_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Meal-type category master — Breakfast, Lunch, Snacks, Dinner, Tuck Shop';


-- ----------------------------------------------------------------------------
-- 2. caf_suppliers
-- Food and material supplier register with FSSAI license tracking
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_suppliers` (
  `id`                     INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name`                   VARCHAR(150) NOT NULL                COMMENT 'Supplier company name',
  `contact_person`         VARCHAR(100) NULL     DEFAULT NULL   COMMENT 'Primary contact person name',
  `phone`                  VARCHAR(20)  NULL     DEFAULT NULL   COMMENT 'Contact phone number',
  `email`                  VARCHAR(100) NULL     DEFAULT NULL   COMMENT 'Contact email address',
  `address`                TEXT         NULL     DEFAULT NULL   COMMENT 'Physical address',
  `fssai_license_no`       VARCHAR(50)  NULL     DEFAULT NULL   COMMENT 'Supplier own FSSAI license number',
  `fssai_expiry_date`      DATE         NULL     DEFAULT NULL   COMMENT 'Alert 30 days (and 7 days) before expiry (BR-CAF-014)',
  `supply_categories_json` JSON         NULL     DEFAULT NULL   COMMENT 'Array e.g. ["Vegetables","Grains","Dairy"]',
  `is_active`              TINYINT(1)   NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`             INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`             TIMESTAMP    NULL     DEFAULT NULL,
  `updated_at`             TIMESTAMP    NULL     DEFAULT NULL,
  `deleted_at`             TIMESTAMP    NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_caf_sup_fssai_expiry` (`fssai_expiry_date`),
  KEY `idx_caf_sup_is_active`    (`is_active`),
  KEY `idx_caf_sup_created_by`   (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Food and material supplier register with FSSAI expiry tracking';


-- ----------------------------------------------------------------------------
-- 3. caf_fssai_records
-- FSSAI license and hygiene audit records (no deleted_at — compliance record)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_fssai_records` (
  `id`                      INT UNSIGNED    NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `record_type`             ENUM('License','Audit')
                                            NOT NULL                COMMENT 'Discriminator: License or Audit record',
  `license_number`          VARCHAR(50)     NULL     DEFAULT NULL   COMMENT 'FSSAI license number — for License records',
  `license_type`            ENUM('Basic','State','Central')
                                            NULL     DEFAULT NULL   COMMENT 'License category — for License records',
  `issue_date`              DATE            NULL     DEFAULT NULL   COMMENT 'License issue date',
  `expiry_date`             DATE            NULL     DEFAULT NULL   COMMENT 'Alert 60 days (and 30 days) before expiry (BR-CAF-014)',
  `licensed_entity_name`    VARCHAR(150)    NULL     DEFAULT NULL   COMMENT 'School or cafeteria unit name on license',
  `fssai_document_media_id` INT UNSIGNED    NULL     DEFAULT NULL   COMMENT 'sys_media.id — license document scan upload',
  `audit_date`              DATE            NULL     DEFAULT NULL   COMMENT 'Audit conducted date — for Audit records',
  `auditor_name`            VARCHAR(100)    NULL     DEFAULT NULL   COMMENT 'Auditor name',
  `audit_score`             TINYINT UNSIGNED NULL    DEFAULT NULL   COMMENT 'Hygiene score on 1-10 scale',
  `audit_remarks`           TEXT            NULL     DEFAULT NULL   COMMENT 'Audit findings and observations',
  `corrective_actions`      TEXT            NULL     DEFAULT NULL   COMMENT 'Corrective actions taken',
  `next_audit_date`         DATE            NULL     DEFAULT NULL   COMMENT 'Scheduled next audit date',
  `is_active`               TINYINT(1)      NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`              INT UNSIGNED    NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`              TIMESTAMP       NULL     DEFAULT NULL,
  `updated_at`              TIMESTAMP       NULL     DEFAULT NULL,
  -- No deleted_at: compliance record; never soft-deleted
  PRIMARY KEY (`id`),
  KEY `idx_caf_fr_record_type` (`record_type`),
  KEY `idx_caf_fr_expiry_date` (`expiry_date`),
  KEY `idx_caf_fr_doc_media`   (`fssai_document_media_id`),
  KEY `idx_caf_fr_created_by`  (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='FSSAI license and hygiene audit compliance log';


-- ----------------------------------------------------------------------------
-- 4. caf_daily_menus
-- Daily menu headers — one record per calendar date (BR-CAF-018)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_daily_menus` (
  `id`               INT UNSIGNED   NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `menu_date`        DATE           NOT NULL                COMMENT 'Calendar date — UNIQUE; one menu per date (BR-CAF-018)',
  `week_start_date`  DATE           NOT NULL                COMMENT 'ISO Monday of the menu week',
  `academic_term_id` SMALLINT UNSIGNED NULL  DEFAULT NULL   COMMENT 'sch_academic_term.id (SMALLINT — verified)',
  `status`           ENUM('Draft','Published','Archived')
                                    NOT NULL DEFAULT 'Draft' COMMENT 'Menu lifecycle: Draft→Published→Archived',
  `published_at`     TIMESTAMP      NULL     DEFAULT NULL   COMMENT 'Timestamp when menu was published',
  `published_by`     INT UNSIGNED   NULL     DEFAULT NULL   COMMENT 'sys_users.id who published the menu',
  `notes`            TEXT           NULL     DEFAULT NULL   COMMENT 'Kitchen notes for this day',
  `is_active`        TINYINT(1)     NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`       INT UNSIGNED   NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`       TIMESTAMP      NULL     DEFAULT NULL,
  `updated_at`       TIMESTAMP      NULL     DEFAULT NULL,
  `deleted_at`       TIMESTAMP      NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_dm_menu_date` (`menu_date`),
  KEY `idx_caf_dm_week_start`    (`week_start_date`),
  KEY `idx_caf_dm_academic_term` (`academic_term_id`),
  KEY `idx_caf_dm_status`        (`status`),
  KEY `idx_caf_dm_published_by`  (`published_by`),
  KEY `idx_caf_dm_created_by`    (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Daily menu header — one record per calendar date, Draft→Published→Archived';


-- ----------------------------------------------------------------------------
-- 5. caf_subscription_plans
-- Meal subscription plan definitions (monthly/termly/annual)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_subscription_plans` (
  `id`                        INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name`                      VARCHAR(150)     NOT NULL                COMMENT 'Plan name e.g. Full Day Plan, Hostel Mess Plan',
  `description`               TEXT             NULL     DEFAULT NULL   COMMENT 'Plan description',
  `included_category_ids_json` JSON            NOT NULL                COMMENT 'Array of caf_menu_categories.id included in this plan',
  `billing_period`            ENUM('Monthly','Termly','Annual')
                                               NOT NULL DEFAULT 'Monthly' COMMENT 'Billing cycle',
  `price`                     DECIMAL(10,2)    NOT NULL                COMMENT 'Plan price in INR',
  `academic_term_id`          SMALLINT UNSIGNED NULL    DEFAULT NULL   COMMENT 'sch_academic_term.id — term this plan applies to',
  `is_hostel_plan`            TINYINT(1)       NOT NULL DEFAULT 0      COMMENT 'Links to HST module — auto-enroll on hostel admission (BR-CAF-015)',
  `is_staff_plan`             TINYINT(1)       NOT NULL DEFAULT 0      COMMENT 'For staff meal deductions via PAY module signal',
  `is_active`                 TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`                INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`                TIMESTAMP        NULL     DEFAULT NULL,
  `updated_at`                TIMESTAMP        NULL     DEFAULT NULL,
  `deleted_at`                TIMESTAMP        NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_caf_sp_academic_term` (`academic_term_id`),
  KEY `idx_caf_sp_is_hostel`     (`is_hostel_plan`),
  KEY `idx_caf_sp_is_staff`      (`is_staff_plan`),
  KEY `idx_caf_sp_created_by`    (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Meal subscription plan definitions — Monthly, Termly, or Annual';


-- ----------------------------------------------------------------------------
-- 6. caf_meal_cards
-- Student prepaid wallet — one active card per student (BR-CAF-004)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_meal_cards` (
  `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `student_id`      INT UNSIGNED  NOT NULL                COMMENT 'std_students.id — one active card per student (BR-CAF-004)',
  `card_number`     VARCHAR(20)   NOT NULL                COMMENT 'Unique card identifier e.g. CAF-CARD-XXXXXXXX',
  `current_balance` DECIMAL(10,2) NOT NULL DEFAULT 0.00   COMMENT 'Current wallet balance — updated atomically by MealCardService via SELECT...FOR UPDATE',
  `total_credited`  DECIMAL(10,2) NOT NULL DEFAULT 0.00   COMMENT 'Lifetime top-up total — for ledger integrity',
  `total_debited`   DECIMAL(10,2) NOT NULL DEFAULT 0.00   COMMENT 'Lifetime spend total — for ledger integrity',
  `valid_from_date` DATE          NOT NULL                COMMENT 'Card validity start date',
  `valid_to_date`   DATE          NULL     DEFAULT NULL   COMMENT 'Card expiry — typically end of academic year',
  `is_active`       TINYINT(1)    NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`      INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id who issued the card',
  `created_at`      TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`      TIMESTAMP     NULL     DEFAULT NULL,
  `deleted_at`      TIMESTAMP     NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_mcard_student` (`student_id`),
  UNIQUE KEY `uq_caf_mcard_number`  (`card_number`),
  KEY `idx_caf_mcard_is_active`  (`is_active`),
  KEY `idx_caf_mcard_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student prepaid meal wallet — UNIQUE per student; atomic balance via SELECT...FOR UPDATE';


-- ----------------------------------------------------------------------------
-- 7. caf_pos_sessions
-- POS shift sessions — open/close model per staff per day (no created_by; opened_by serves)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_pos_sessions` (
  `id`                   INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `session_date`         DATE          NOT NULL                COMMENT 'Date of POS session',
  `opened_by`            INT UNSIGNED  NOT NULL                COMMENT 'sys_users.id — staff who opened this session',
  `opened_at`            TIMESTAMP     NOT NULL                COMMENT 'Session open timestamp',
  `closed_at`            TIMESTAMP     NULL     DEFAULT NULL   COMMENT 'Session close timestamp; NULL = session still active (BR-CAF-013)',
  `total_cash_collected` DECIMAL(10,2) NOT NULL DEFAULT 0.00   COMMENT 'Total cash collected — for end-of-day reconciliation',
  `total_card_debited`   DECIMAL(10,2) NOT NULL DEFAULT 0.00   COMMENT 'Total meal card amounts debited in this session',
  `total_transactions`   INT UNSIGNED  NOT NULL DEFAULT 0      COMMENT 'Running count of transactions in this session',
  `notes`                TEXT          NULL     DEFAULT NULL   COMMENT 'Session closing notes or discrepancy notes',
  `is_active`            TINYINT(1)    NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_at`           TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`           TIMESTAMP     NULL     DEFAULT NULL,
  -- No deleted_at; no created_by (opened_by serves as creator context)
  PRIMARY KEY (`id`),
  KEY `idx_caf_ps_session_date` (`session_date`),
  KEY `idx_caf_ps_opened_by`    (`opened_by`),
  KEY `idx_caf_ps_closed_at`    (`closed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='POS shift sessions — open/close model; active session required for transactions';


-- ----------------------------------------------------------------------------
-- 8. caf_dietary_profiles
-- Per-student dietary preference and restriction flags (one profile per student)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_dietary_profiles` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `student_id`           INT UNSIGNED NOT NULL                COMMENT 'std_students.id — UNIQUE; one profile per student',
  `food_preference`      ENUM('Veg','Non_Veg','Egg','Jain')
                                      NOT NULL DEFAULT 'Veg'  COMMENT 'Primary food preference',
  `is_no_onion_garlic`   TINYINT(1)   NOT NULL DEFAULT 0      COMMENT '1 = no onion/garlic restriction',
  `is_gluten_free`       TINYINT(1)   NOT NULL DEFAULT 0      COMMENT '1 = gluten-free restriction',
  `is_nut_allergy`       TINYINT(1)   NOT NULL DEFAULT 0      COMMENT '1 = nut allergy — flagged on POS scan (BR-CAF-002)',
  `is_dairy_free`        TINYINT(1)   NOT NULL DEFAULT 0      COMMENT '1 = dairy-free restriction',
  `custom_restrictions`  TEXT         NULL     DEFAULT NULL   COMMENT 'Free-form additional dietary notes',
  `medical_dietary_note` TEXT         NULL     DEFAULT NULL   COMMENT 'Doctor-recommended dietary guidance',
  `is_active`            TINYINT(1)   NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`           TIMESTAMP    NULL     DEFAULT NULL,
  `updated_at`           TIMESTAMP    NULL     DEFAULT NULL,
  `deleted_at`           TIMESTAMP    NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_dp_student` (`student_id`),
  KEY `idx_caf_dp_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-student dietary preference and restriction profile — UNIQUE per student';


-- =============================================================================
-- LAYER 2 — Depends on Layer 1 only
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 9. caf_menu_items
-- Dish library with nutritional macros, food type, allergen notes, dish photo
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_menu_items` (
  `id`             INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `category_id`    INT UNSIGNED     NOT NULL                COMMENT 'caf_menu_categories.id — which meal category this dish belongs to',
  `name`           VARCHAR(150)     NOT NULL                COMMENT 'Dish name',
  `description`    TEXT             NULL     DEFAULT NULL   COMMENT 'Dish description',
  `price`          DECIMAL(8,2)     NOT NULL                COMMENT 'Per-serving price in INR',
  `food_type`      ENUM('Veg','Non_Veg','Egg','Jain')
                                    NOT NULL DEFAULT 'Veg'  COMMENT 'Food type — used for dietary conflict check',
  `calories`       SMALLINT UNSIGNED NULL    DEFAULT NULL   COMMENT 'Calories per serving (kcal)',
  `protein_grams`  DECIMAL(5,2)     NULL     DEFAULT NULL   COMMENT 'Protein per serving (g)',
  `carbs_grams`    DECIMAL(5,2)     NULL     DEFAULT NULL   COMMENT 'Carbohydrates per serving (g)',
  `fat_grams`      DECIMAL(5,2)     NULL     DEFAULT NULL   COMMENT 'Fat per serving (g)',
  `allergen_notes` TEXT             NULL     DEFAULT NULL   COMMENT 'Free-form allergen information',
  `photo_media_id` INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'sys_media.id — dish photo',
  `is_available`   TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Real-time availability toggle for POS counter',
  `is_active`      TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`     INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`     TIMESTAMP        NULL     DEFAULT NULL,
  `updated_at`     TIMESTAMP        NULL     DEFAULT NULL,
  `deleted_at`     TIMESTAMP        NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_caf_mi_category`    (`category_id`),
  KEY `idx_caf_mi_photo_media` (`photo_media_id`),
  KEY `idx_caf_mi_food_type`   (`food_type`),
  KEY `idx_caf_mi_is_available` (`is_available`),
  KEY `idx_caf_mi_created_by`  (`created_by`),
  CONSTRAINT `fk_caf_mi_category_id` FOREIGN KEY (`category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Dish library with full nutritional info, allergen notes, and dish photo';


-- ----------------------------------------------------------------------------
-- 10. caf_stock_items
-- Raw material inventory with reorder threshold and INV bridge support
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_stock_items` (
  `id`               INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `supplier_id`      INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'caf_suppliers.id — preferred supplier (nullable)',
  `name`             VARCHAR(150)  NOT NULL                COMMENT 'Raw material name',
  `category`         ENUM('Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other')
                                   NOT NULL                COMMENT 'Material category',
  `unit`             VARCHAR(20)   NOT NULL                COMMENT 'Unit of measurement: kg, litre, piece, dozen',
  `current_quantity` DECIMAL(10,3) NOT NULL DEFAULT 0.000  COMMENT 'Current stock level — updated by StockService on each consumption log',
  `reorder_level`    DECIMAL(10,3) NOT NULL                COMMENT 'Alert threshold — triggers reorder notification (BR-CAF-007)',
  `reorder_quantity` DECIMAL(10,3) NULL     DEFAULT NULL   COMMENT 'Suggested purchase quantity for INV bridge PR',
  `cost_per_unit`    DECIMAL(8,2)  NULL     DEFAULT NULL   COMMENT 'Cost per unit in INR',
  `is_active`        TINYINT(1)    NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`       INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`       TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`       TIMESTAMP     NULL     DEFAULT NULL,
  `deleted_at`       TIMESTAMP     NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_caf_si_supplier`  (`supplier_id`),
  KEY `idx_caf_si_category`  (`category`),
  KEY `idx_caf_si_is_active` (`is_active`),
  KEY `idx_caf_si_created_by` (`created_by`),
  CONSTRAINT `fk_caf_si_supplier_id` FOREIGN KEY (`supplier_id`)
    REFERENCES `caf_suppliers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Raw material inventory with reorder threshold and optional INV purchase requisition bridge';


-- ----------------------------------------------------------------------------
-- 11. caf_event_meals
-- Special/festival meal headers with optional class-group targeting
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_event_meals` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `name`                 VARCHAR(150) NOT NULL                COMMENT 'Event meal name e.g. Diwali Special Lunch',
  `event_date`           DATE         NOT NULL                COMMENT 'Date of the special/festival meal',
  `meal_category_id`     INT UNSIGNED NOT NULL                COMMENT 'caf_menu_categories.id — which meal type',
  `target_class_ids_json` JSON        NULL     DEFAULT NULL   COMMENT 'Array of class IDs targeted; NULL = all students (BR-CAF-016)',
  `status`               ENUM('Draft','Published','Archived')
                                      NOT NULL DEFAULT 'Draft' COMMENT 'Event meal lifecycle status',
  `published_at`         TIMESTAMP    NULL     DEFAULT NULL   COMMENT 'When event meal was published',
  `notes`                TEXT         NULL     DEFAULT NULL   COMMENT 'Additional notes for kitchen',
  `is_active`            TINYINT(1)   NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`           TIMESTAMP    NULL     DEFAULT NULL,
  `updated_at`           TIMESTAMP    NULL     DEFAULT NULL,
  `deleted_at`           TIMESTAMP    NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_caf_em_event_date`  (`event_date`),
  KEY `idx_caf_em_category`    (`meal_category_id`),
  KEY `idx_caf_em_status`      (`status`),
  KEY `idx_caf_em_created_by`  (`created_by`),
  CONSTRAINT `fk_caf_em_meal_category_id` FOREIGN KEY (`meal_category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Special and festival meal headers with optional class-group targeting';


-- ----------------------------------------------------------------------------
-- 12. caf_subscription_enrollments
-- Student/staff × plan enrollment records
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_subscription_enrollments` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `subscription_plan_id` INT UNSIGNED NOT NULL                COMMENT 'caf_subscription_plans.id',
  `student_id`           INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'std_students.id — mutually exclusive with staff_id',
  `staff_id`             INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id — mutually exclusive with student_id',
  `meal_card_id`         INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'caf_meal_cards.id — plan fee deducted from this card',
  `start_date`           DATE         NOT NULL                COMMENT 'Enrollment start date',
  `end_date`             DATE         NULL     DEFAULT NULL   COMMENT 'Enrollment end date (NULL = plan expiry)',
  `status`               ENUM('Active','Paused','Cancelled','Expired')
                                      NOT NULL DEFAULT 'Active' COMMENT 'Enrollment status',
  `cancellation_reason`  TEXT         NULL     DEFAULT NULL   COMMENT 'Reason if cancelled',
  `is_active`            TINYINT(1)   NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`           TIMESTAMP    NULL     DEFAULT NULL,
  `updated_at`           TIMESTAMP    NULL     DEFAULT NULL,
  `deleted_at`           TIMESTAMP    NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  KEY `idx_caf_se_plan`      (`subscription_plan_id`),
  KEY `idx_caf_se_student`   (`student_id`),
  KEY `idx_caf_se_staff`     (`staff_id`),
  KEY `idx_caf_se_meal_card` (`meal_card_id`),
  KEY `idx_caf_se_status`    (`status`),
  KEY `idx_caf_se_created_by` (`created_by`),
  CONSTRAINT `fk_caf_se_plan_id`      FOREIGN KEY (`subscription_plan_id`)
    REFERENCES `caf_subscription_plans` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_caf_se_meal_card_id` FOREIGN KEY (`meal_card_id`)
    REFERENCES `caf_meal_cards` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Student and staff meal subscription enrollment records';


-- ----------------------------------------------------------------------------
-- 13. caf_meal_card_transactions
-- Credit/Debit/Refund/Adjustment ledger (no deleted_at — immutable financial record)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_meal_card_transactions` (
  `id`                  INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `meal_card_id`        INT UNSIGNED  NOT NULL                COMMENT 'caf_meal_cards.id',
  `student_id`          INT UNSIGNED  NOT NULL                COMMENT 'std_students.id — denormalized for efficient queries',
  `transaction_type`    ENUM('Credit','Debit','Refund','Adjustment')
                                      NOT NULL                COMMENT 'Transaction direction',
  `amount`              DECIMAL(10,2) NOT NULL                COMMENT 'Transaction amount in INR',
  `balance_after`       DECIMAL(10,2) NOT NULL                COMMENT 'Balance snapshot AFTER this transaction — critical for ledger integrity',
  `reference_type`      VARCHAR(50)   NULL     DEFAULT NULL   COMMENT 'Source context: Order, POS, TopUp, Refund, Adjustment',
  `reference_id`        INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'Polymorphic FK to referenced record',
  `payment_mode`        ENUM('Online','Cash','Wallet','Free')
                                      NULL     DEFAULT NULL   COMMENT 'Payment mode — applicable for top-up (Credit) transactions',
  `razorpay_payment_id` VARCHAR(100)  NULL     DEFAULT NULL   COMMENT 'Razorpay payment ID — UNIQUE for idempotency (BR-CAF-011); multiple NULLs allowed',
  `notes`               TEXT          NULL     DEFAULT NULL   COMMENT 'Transaction notes',
  `created_by`          INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`          TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`          TIMESTAMP     NULL     DEFAULT NULL,
  -- No deleted_at: financial ledger; immutable records
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_mct_razorpay` (`razorpay_payment_id`),
  KEY `idx_caf_mct_meal_card`    (`meal_card_id`),
  KEY `idx_caf_mct_student`      (`student_id`),
  KEY `idx_caf_mct_type`         (`transaction_type`),
  KEY `idx_caf_mct_card_created` (`meal_card_id`, `created_at`),
  KEY `idx_caf_mct_created_by`   (`created_by`),
  CONSTRAINT `fk_caf_mct_meal_card_id` FOREIGN KEY (`meal_card_id`)
    REFERENCES `caf_meal_cards` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Meal card credit/debit/refund ledger — immutable financial records; razorpay idempotency via UNIQUE';


-- ----------------------------------------------------------------------------
-- 14. caf_meal_attendance
-- QR/biometric scan records — idempotent; no is_active/updated_at (immutable)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_meal_attendance` (
  `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `student_id`       INT UNSIGNED NOT NULL                COMMENT 'std_students.id',
  `meal_date`        DATE         NOT NULL                COMMENT 'Date of meal serving',
  `meal_category_id` INT UNSIGNED NOT NULL                COMMENT 'caf_menu_categories.id — which meal was served',
  `scanned_at`       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Exact scan timestamp',
  `scan_method`      ENUM('QR','Biometric','Manual')
                                  NOT NULL DEFAULT 'QR'   COMMENT 'Method of attendance marking',
  `counter_name`     VARCHAR(100) NULL     DEFAULT NULL   COMMENT 'POS counter name where scan occurred',
  `scanned_by`       INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id — staff for manual scans only',
  `created_at`       TIMESTAMP    NULL     DEFAULT NULL,
  -- No updated_at, no is_active, no deleted_at: immutable scan record
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_ma` (`student_id`, `meal_date`, `meal_category_id`),
  KEY `idx_caf_ma_meal_date`   (`meal_date`),
  KEY `idx_caf_ma_category`    (`meal_category_id`),
  KEY `idx_caf_ma_scanned_by`  (`scanned_by`),
  CONSTRAINT `fk_caf_ma_meal_category_id` FOREIGN KEY (`meal_category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='QR/biometric meal scan records — idempotent UNIQUE per student per meal per day';


-- ----------------------------------------------------------------------------
-- 15. caf_pos_transactions
-- Individual POS counter sales — items_json snapshot; immutable after save
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_pos_transactions` (
  `id`               INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `pos_session_id`   INT UNSIGNED  NOT NULL                COMMENT 'caf_pos_sessions.id — must be active session (BR-CAF-013)',
  `student_id`       INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'std_students.id — NULL if anonymous/cash sale',
  `staff_id`         INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id — NULL if student transaction',
  `meal_card_id`     INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'caf_meal_cards.id — NULL for cash transactions',
  `items_json`       JSON          NOT NULL                COMMENT 'Immutable snapshot: [{menu_item_id,name,qty,price}]',
  `total_amount`     DECIMAL(10,2) NOT NULL                COMMENT 'Total transaction amount in INR',
  `payment_mode`     ENUM('MealCard','Cash')
                                   NOT NULL                COMMENT 'Payment method for this POS transaction',
  `balance_after`    DECIMAL(10,2) NULL     DEFAULT NULL   COMMENT 'Meal card balance after deduction (MealCard mode only)',
  `dietary_flags_json` JSON        NULL     DEFAULT NULL   COMMENT 'Snapshot of student dietary flags at scan time',
  `receipt_sent`     TINYINT(1)    NOT NULL DEFAULT 0      COMMENT '1 = digital receipt was sent',
  `created_by`       INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id who processed this transaction',
  `created_at`       TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`       TIMESTAMP     NULL     DEFAULT NULL,
  -- No is_active, no deleted_at: transactional record; immutable after save
  PRIMARY KEY (`id`),
  KEY `idx_caf_pt_session`    (`pos_session_id`),
  KEY `idx_caf_pt_student`    (`student_id`),
  KEY `idx_caf_pt_staff`      (`staff_id`),
  KEY `idx_caf_pt_meal_card`  (`meal_card_id`),
  KEY `idx_caf_pt_created_by` (`created_by`),
  CONSTRAINT `fk_caf_pt_session_id`   FOREIGN KEY (`pos_session_id`)
    REFERENCES `caf_pos_sessions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_caf_pt_meal_card_id` FOREIGN KEY (`meal_card_id`)
    REFERENCES `caf_meal_cards` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Individual POS counter sales — items_json snapshot; immutable after save';


-- ----------------------------------------------------------------------------
-- 16. caf_staff_meal_logs
-- Staff meal tracking with payroll deduction signal (no is_active/deleted_at)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_staff_meal_logs` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `staff_id`              INT UNSIGNED NOT NULL                COMMENT 'sys_users.id — staff member who had the meal',
  `meal_date`             DATE         NOT NULL                COMMENT 'Date of meal',
  `meal_category_id`      INT UNSIGNED NOT NULL                COMMENT 'caf_menu_categories.id — which meal',
  `items_json`            JSON         NULL     DEFAULT NULL   COMMENT 'Items consumed (immutable snapshot)',
  `amount`                DECIMAL(8,2) NOT NULL DEFAULT 0.00   COMMENT 'Meal amount charged in INR',
  `payment_mode`          ENUM('Subscription','Cash','CardDeduction')
                                       NOT NULL                COMMENT 'How this meal was paid for',
  `payroll_deduction_flag` TINYINT(1)  NOT NULL DEFAULT 0      COMMENT '1 = PAY module should deduct from payroll (BR-CAF-019); CAF never writes to pay_*',
  `created_by`            INT UNSIGNED NULL     DEFAULT NULL   COMMENT 'sys_users.id who logged this entry',
  `created_at`            TIMESTAMP    NULL     DEFAULT NULL,
  `updated_at`            TIMESTAMP    NULL     DEFAULT NULL,
  -- No is_active, no deleted_at: transactional log; no soft delete
  PRIMARY KEY (`id`),
  KEY `idx_caf_sml_staff`         (`staff_id`),
  KEY `idx_caf_sml_meal_date`     (`meal_date`),
  KEY `idx_caf_sml_category`      (`meal_category_id`),
  KEY `idx_caf_sml_payroll_flag`  (`payroll_deduction_flag`),
  KEY `idx_caf_sml_created_by`    (`created_by`),
  CONSTRAINT `fk_caf_sml_meal_category_id` FOREIGN KEY (`meal_category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Staff meal tracking — payroll_deduction_flag signals PAY module; CAF never writes to pay_*';


-- ----------------------------------------------------------------------------
-- 17. caf_orders
-- Meal pre-order headers — student orders before cutoff time
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_orders` (
  `id`                  INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `order_number`        VARCHAR(30)   NOT NULL                COMMENT 'Unique order identifier e.g. CAF-2026-XXXXXXXX',
  `student_id`          INT UNSIGNED  NOT NULL                COMMENT 'std_students.id — order placed by this student',
  `meal_card_id`        INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'caf_meal_cards.id — NULL if cash or counter payment',
  `order_date`          DATE          NOT NULL                COMMENT 'Calendar date the meal is ordered for',
  `meal_category_id`    INT UNSIGNED  NOT NULL                COMMENT 'caf_menu_categories.id — which meal type',
  `total_amount`        DECIMAL(10,2) NOT NULL                COMMENT 'Sum of all line item totals',
  `payment_mode`        ENUM('MealCard','Cash','Counter','Subscription')
                                      NOT NULL DEFAULT 'MealCard' COMMENT 'Payment method',
  `status`              ENUM('Pending','Confirmed','Served','Cancelled')
                                      NOT NULL DEFAULT 'Confirmed' COMMENT 'Order lifecycle status',
  `cancelled_at`        TIMESTAMP     NULL     DEFAULT NULL   COMMENT 'When order was cancelled',
  `cancellation_reason` VARCHAR(255)  NULL     DEFAULT NULL   COMMENT 'Why order was cancelled',
  `notes`               TEXT          NULL     DEFAULT NULL   COMMENT 'Order notes',
  `is_active`           TINYINT(1)    NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`          INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id who created this record',
  `created_at`          TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`          TIMESTAMP     NULL     DEFAULT NULL,
  `deleted_at`          TIMESTAMP     NULL     DEFAULT NULL   COMMENT 'Soft delete',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_orders_number` (`order_number`),
  KEY `idx_caf_ord_student`        (`student_id`),
  KEY `idx_caf_ord_meal_card`      (`meal_card_id`),
  KEY `idx_caf_ord_category`       (`meal_category_id`),
  KEY `idx_caf_ord_student_date`   (`student_id`, `order_date`),
  KEY `idx_caf_ord_date_cat_status` (`order_date`, `meal_category_id`, `status`),
  KEY `idx_caf_ord_created_by`     (`created_by`),
  CONSTRAINT `fk_caf_ord_meal_card_id`    FOREIGN KEY (`meal_card_id`)
    REFERENCES `caf_meal_cards` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_caf_ord_meal_category_id` FOREIGN KEY (`meal_category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Meal pre-order headers — student orders placed before cutoff time';


-- =============================================================================
-- LAYER 3 — Depends on Layer 2
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 18. caf_daily_menu_items_jnt
-- Day × meal-category × dish assignments (no deleted_at — junction table)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_daily_menu_items_jnt` (
  `id`                 INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `daily_menu_id`      INT UNSIGNED     NOT NULL                COMMENT 'caf_daily_menus.id',
  `menu_item_id`       INT UNSIGNED     NOT NULL                COMMENT 'caf_menu_items.id — the dish being assigned',
  `meal_category_id`   INT UNSIGNED     NOT NULL                COMMENT 'caf_menu_categories.id — which meal on this day',
  `serving_size_notes` VARCHAR(100)     NULL     DEFAULT NULL   COMMENT 'e.g. 1 plate, 200ml',
  `display_order`      TINYINT UNSIGNED NOT NULL DEFAULT 0      COMMENT 'Sort order within this meal category',
  `is_active`          TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`         INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'sys_users.id who added this item',
  `created_at`         TIMESTAMP        NULL     DEFAULT NULL,
  `updated_at`         TIMESTAMP        NULL     DEFAULT NULL,
  -- No deleted_at: junction table; no soft delete on individual assignments
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_dmij` (`daily_menu_id`, `menu_item_id`, `meal_category_id`),
  KEY `idx_caf_dmij_daily_menu`  (`daily_menu_id`),
  KEY `idx_caf_dmij_menu_item`   (`menu_item_id`),
  KEY `idx_caf_dmij_category`    (`meal_category_id`),
  KEY `idx_caf_dmij_created_by`  (`created_by`),
  CONSTRAINT `fk_caf_dmij_daily_menu_id`   FOREIGN KEY (`daily_menu_id`)
    REFERENCES `caf_daily_menus` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_caf_dmij_menu_item_id`    FOREIGN KEY (`menu_item_id`)
    REFERENCES `caf_menu_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_caf_dmij_meal_category_id` FOREIGN KEY (`meal_category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Daily menu × meal category × dish assignments — what is served at each meal on each day';


-- ----------------------------------------------------------------------------
-- 19. caf_event_meal_items_jnt
-- Event meal × dish assignments — menu_item_id nullable for free-text items
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_event_meal_items_jnt` (
  `id`                   INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `event_meal_id`        INT UNSIGNED     NOT NULL                COMMENT 'caf_event_meals.id',
  `menu_item_id`         INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'caf_menu_items.id — NULLABLE: free-text items allowed when dish not in library',
  `free_text_item`       VARCHAR(150)     NULL     DEFAULT NULL   COMMENT 'Item name when not in dish library (used when menu_item_id is NULL)',
  `quantity_per_student` DECIMAL(5,2)     NULL     DEFAULT NULL   COMMENT 'Serving quantity per student',
  `display_order`        TINYINT UNSIGNED NOT NULL DEFAULT 0      COMMENT 'Sort order of items in this event meal',
  `is_active`            TINYINT(1)       NOT NULL DEFAULT 1      COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED     NULL     DEFAULT NULL   COMMENT 'sys_users.id who added this item',
  `created_at`           TIMESTAMP        NULL     DEFAULT NULL,
  `updated_at`           TIMESTAMP        NULL     DEFAULT NULL,
  -- No deleted_at: junction table; no soft delete
  PRIMARY KEY (`id`),
  -- No UNIQUE beyond PK: free-text items can duplicate dish-library items
  KEY `idx_caf_emij_event_meal`  (`event_meal_id`),
  KEY `idx_caf_emij_menu_item`   (`menu_item_id`),
  KEY `idx_caf_emij_created_by`  (`created_by`),
  CONSTRAINT `fk_caf_emij_event_meal_id` FOREIGN KEY (`event_meal_id`)
    REFERENCES `caf_event_meals` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_caf_emij_menu_item_id`  FOREIGN KEY (`menu_item_id`)
    REFERENCES `caf_menu_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Event meal × dish assignments — menu_item_id nullable for free-text festival items';


-- ----------------------------------------------------------------------------
-- 20. caf_consumption_logs
-- Daily raw material usage log (no is_active/deleted_at — consumption log)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_consumption_logs` (
  `id`               INT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `stock_item_id`    INT UNSIGNED  NOT NULL                COMMENT 'caf_stock_items.id — which material was consumed',
  `log_date`         DATE          NOT NULL                COMMENT 'Date of consumption',
  `quantity_used`    DECIMAL(10,3) NOT NULL                COMMENT 'Amount consumed — deducted from caf_stock_items.current_quantity',
  `meal_category_id` INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'caf_menu_categories.id — which meal consumed this material',
  `notes`            VARCHAR(255)  NULL     DEFAULT NULL   COMMENT 'Consumption notes',
  `created_by`       INT UNSIGNED  NULL     DEFAULT NULL   COMMENT 'sys_users.id who logged this entry',
  `created_at`       TIMESTAMP     NULL     DEFAULT NULL,
  `updated_at`       TIMESTAMP     NULL     DEFAULT NULL,
  -- No is_active, no deleted_at: usage log; no soft delete
  PRIMARY KEY (`id`),
  KEY `idx_caf_cl_stock_item`  (`stock_item_id`),
  KEY `idx_caf_cl_log_date`    (`log_date`),
  KEY `idx_caf_cl_category`    (`meal_category_id`),
  KEY `idx_caf_cl_item_date`   (`stock_item_id`, `log_date`),
  KEY `idx_caf_cl_created_by`  (`created_by`),
  CONSTRAINT `fk_caf_cl_stock_item_id`    FOREIGN KEY (`stock_item_id`)
    REFERENCES `caf_stock_items` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_caf_cl_meal_category_id` FOREIGN KEY (`meal_category_id`)
    REFERENCES `caf_menu_categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Daily raw material consumption log — deducted from stock on each entry';


-- =============================================================================
-- LAYER 4 — Depends on Layer 3
-- =============================================================================

-- ----------------------------------------------------------------------------
-- 21. caf_order_items
-- Pre-order line items with price snapshot (no is_active/created_by/deleted_at)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `caf_order_items` (
  `id`           INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `order_id`     INT UNSIGNED     NOT NULL                COMMENT 'caf_orders.id',
  `menu_item_id` INT UNSIGNED     NOT NULL                COMMENT 'caf_menu_items.id',
  `quantity`     TINYINT UNSIGNED NOT NULL DEFAULT 1      COMMENT 'Number of servings ordered',
  `unit_price`   DECIMAL(8,2)     NOT NULL                COMMENT 'Price snapshot at order time — NEVER re-read from caf_menu_items.price',
  `line_total`   DECIMAL(10,2)    NOT NULL                COMMENT 'quantity × unit_price — populated at insert; not GENERATED to allow future adjustments',
  `created_at`   TIMESTAMP        NULL     DEFAULT NULL,
  `updated_at`   TIMESTAMP        NULL     DEFAULT NULL,
  -- No id auto — has id PK above; No is_active, no created_by, no deleted_at: transactional line item
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_caf_oi_order_item` (`order_id`, `menu_item_id`),
  KEY `idx_caf_oi_order`     (`order_id`),
  KEY `idx_caf_oi_menu_item` (`menu_item_id`),
  CONSTRAINT `fk_caf_oi_order_id`     FOREIGN KEY (`order_id`)
    REFERENCES `caf_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_caf_oi_menu_item_id` FOREIGN KEY (`menu_item_id`)
    REFERENCES `caf_menu_items` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pre-order line items with unit_price snapshot at order time — immutable after order placed';


SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- End of CAF DDL — 21 tables created
-- Layer 1 (8): caf_menu_categories, caf_suppliers, caf_fssai_records,
--              caf_daily_menus, caf_subscription_plans, caf_meal_cards,
--              caf_pos_sessions, caf_dietary_profiles
-- Layer 2 (9): caf_menu_items, caf_stock_items, caf_event_meals,
--              caf_subscription_enrollments, caf_meal_card_transactions,
--              caf_meal_attendance, caf_pos_transactions, caf_staff_meal_logs,
--              caf_orders
-- Layer 3 (3): caf_daily_menu_items_jnt, caf_event_meal_items_jnt,
--              caf_consumption_logs
-- Layer 4 (1): caf_order_items
-- =============================================================================
