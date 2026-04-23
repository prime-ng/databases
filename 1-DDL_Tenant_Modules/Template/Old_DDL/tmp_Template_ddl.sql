CREATE TABLE IF NOT EXISTS `tmp_templates` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `type` VARCHAR(30) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `canvas_json` JSON DEFAULT NULL,  -- store drageable element and their position
    `html_content` LONGTEXT DEFAULT NULL,  -- store html content of template
    `variables` JSON DEFAULT NULL,  -- store variables used in template, e.g. {{name}}, {{date}}, etc.
    `background_image` VARCHAR(255) DEFAULT NULL,  -- store background image url or path
    `is_active` TINYINT(1) NOT NULL DEFAULT 0,  -- 0 = inactive, 1 = active
    `created_by` BIGINT UNSIGNED DEFAULT NULL,
    `updated_by` BIGINT UNSIGNED DEFAULT NULL,
    `created_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NULL DEFAULT NULL,
    `deleted_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_created_by` (`created_by`),
    INDEX `idx_updated_by` (`updated_by`),
    INDEX `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

