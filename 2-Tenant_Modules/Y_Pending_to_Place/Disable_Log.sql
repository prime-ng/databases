

/* ============================================================
   7. DISABLED LOG
   ============================================================ */
CREATE TABLE IF NOT EXISTS `sch_students_disable_log` (
    `id`     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    `user_id`             BIGINT UNSIGNED NOT NULL,
    `academic_year`       VARCHAR(9) NOT NULL,
    `disable_reason_id`   BIGINT UNSIGNED NOT NULL,  -- FK to `sch_disable_reasons.id`
    `disabled_date`       DATE NOT NULL,
    `remarks`             VARCHAR(255) NULL,
    `disabled_by`         BIGINT UNSIGNED NOT NULL,  -- FK to `sys_users.id`
    `reactivated_date`    DATE NULL,
    `reactivated_by`      BIGINT UNSIGNED NULL,  -- FK to `sys_users.id`
    `reactivated_reason`  VARCHAR(255) NULL,
    `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`          TIMESTAMP NULL,
    INDEX `idx_disabled_student` (`student_id`, `disabled_date`),
    CONSTRAINT `fk_disabled_reason` FOREIGN KEY (`disable_reason_id`) REFERENCES `stu_disable_reasons` (`id`),
    CONSTRAINT `fk_disabled_by` FOREIGN KEY (`disabled_by`) REFERENCES `sys_users` (`id`),
    CONSTRAINT `fk_reactivated_by` FOREIGN KEY (`reactivated_by`) REFERENCES `sys_users` (`id`)
) ENGINE=InnoDB;
