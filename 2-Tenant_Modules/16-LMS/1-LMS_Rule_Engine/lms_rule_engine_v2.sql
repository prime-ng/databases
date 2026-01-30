/* =========================================================
   LMS RULE ENGINE – PHASE 1 (CORE + AUDIT + MULTI ACTION)
   Compatible with Laravel + MySQL 8+
   ========================================================= */

/* =========================================================
   1. TRIGGER EVENTS
   ========================================================= */
CREATE TABLE IF NOT EXISTS lms_trigger_event (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT NULL,

    event_logic JSON NOT NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* =========================================================
   2. ACTION TYPES (WHAT SYSTEM CAN DO)
   ========================================================= */
CREATE TABLE IF NOT EXISTS lms_action_type (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT NULL,

    action_logic JSON NOT NULL,
    required_parameters JSON NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* =========================================================
   3. RULE ENGINE CONFIG (CORE RULE DEFINITION)
   ========================================================= */
CREATE TABLE IF NOT EXISTS lms_rule_engine_config (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    rule_code VARCHAR(50) NOT NULL UNIQUE,
    rule_name VARCHAR(100) NOT NULL,
    description TEXT NULL,

    trigger_event_id BIGINT UNSIGNED NOT NULL,
    applicable_class_group_id BIGINT UNSIGNED NULL,

    logic_config JSON NOT NULL,

    priority INT NOT NULL DEFAULT 100,
    stop_further_execution TINYINT(1) NOT NULL DEFAULT 0,

    ai_enabled TINYINT(1) NOT NULL DEFAULT 0,
    ai_confidence_score DECIMAL(5,2) NULL,

    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT fk_rule_trigger
        FOREIGN KEY (trigger_event_id)
        REFERENCES lms_trigger_event(id),

    CONSTRAINT fk_rule_class_group
        FOREIGN KEY (applicable_class_group_id)
        REFERENCES sch_class_groups_jnt(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* =========================================================
   4. RULE → ACTION MAPPING (MULTIPLE ACTIONS PER RULE)
   ========================================================= */
CREATE TABLE IF NOT EXISTS lms_rule_action_map (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    rule_id BIGINT UNSIGNED NOT NULL,
    action_type_id BIGINT UNSIGNED NOT NULL,

    execution_order INT NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,

    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL,

    CONSTRAINT fk_rule_action_rule
        FOREIGN KEY (rule_id)
        REFERENCES lms_rule_engine_config(id),

    CONSTRAINT fk_rule_action_action
        FOREIGN KEY (action_type_id)
        REFERENCES lms_action_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* =========================================================
   5. RULE EXECUTION LOG (AUDIT + DEBUG + AI DATA)
   ========================================================= */
CREATE TABLE IF NOT EXISTS lms_rule_execution_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    rule_id BIGINT UNSIGNED NOT NULL,
    trigger_event_id BIGINT UNSIGNED NOT NULL,
    action_type_id BIGINT UNSIGNED NOT NULL,

    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,

    execution_context JSON NOT NULL,

    execution_result ENUM('SUCCESS','FAILED','SKIPPED') NOT NULL,
    error_message TEXT NULL,

    executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_rule (rule_id),
    INDEX idx_trigger (trigger_event_id),
    INDEX idx_entity (entity_type, entity_id),

    CONSTRAINT fk_log_rule
        FOREIGN KEY (rule_id)
        REFERENCES lms_rule_engine_config(id),

    CONSTRAINT fk_log_trigger
        FOREIGN KEY (trigger_event_id)
        REFERENCES lms_trigger_event(id),

    CONSTRAINT fk_log_action
        FOREIGN KEY (action_type_id)
        REFERENCES lms_action_type(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


/* =========================================================
   6. MASTER DATA (OPTIONAL SEED)
   ========================================================= */

/* Trigger Events */
INSERT INTO lms_trigger_event (code, name, description, event_logic, is_active, created_at)
VALUES
('ON_QUIZ_COMPLETION','On Quiz Completion','Triggered when quiz is evaluated',
 '{"event":"quiz_completed"}',1,NOW()),

('ON_HOMEWORK_OVERDUE','On Homework Overdue','Triggered when homework crosses due date',
 '{"event":"homework_overdue"}',1,NOW());


/* Action Types */
INSERT INTO lms_action_type (code, name, description, action_logic, is_active, created_at)
VALUES
('AUTO_ASSIGN_REMEDIAL','Auto Assign Remedial',
 'Assign remedial lesson automatically',
 '{"handler":"assign_remedial"}',1,NOW()),

('NOTIFY_PARENT','Notify Parent',
 'Send notification to parent',
 '{"handler":"notify_parent"}',1,NOW());


/* =========================================================
   END OF FILE
   ========================================================= */
