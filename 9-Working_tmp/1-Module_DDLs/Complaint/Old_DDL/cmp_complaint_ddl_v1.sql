-- =========================================================
-- ERP COMPLAINT & GRIEVANCE MANAGEMENT MODULE
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- 1. MASTER COMPLAINT TABLE
-- =========================================================
CREATE TABLE erp_complaints (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    -- Who raised the complaint
    complainant_type VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Parent, Student, Staff, Vendor, Other)
    complainant_user_id INT UNSIGNED NULL,
    -- Against whom / which entity
    target_type VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Department, Staff, Driver, Helper, Vehicle, System, Other)
    target_id INT UNSIGNED NULL,
    -- Complaint classification
    complaint_category VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Behaviour, Safety, Medical, Harassment, Service, Delay, Misconduct, Other)
    complaint_subcategory VARCHAR(100) NULL, -- FK to sys_dropdown_table e.g. (Late, Cancelled, Other)
    severity_level VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Low, Medium, High, Critical)
    -- Transport & compliance specific flags
    is_transport_related TINYINT(1) NOT NULL DEFAULT 0,
    alcohol_suspected TINYINT(1) DEFAULT 0,
    medical_unfit_suspected TINYINT(1) DEFAULT 0,
    safety_violation TINYINT(1) DEFAULT 0,
    -- Core content
    complaint_title VARCHAR(200) NOT NULL,
    complaint_description TEXT NOT NULL,
    -- Status & SLA
    complaint_status VARCHAR(20) NOT NULL DEFAULT 'Open', -- FK to sys_dropdown_table e.g. (Open, In-Progress, Escalated, Resolved, Closed, Rejected)
    priority_score TINYINT NOT NULL DEFAULT 3, -- 1 highest, 5 lowest
    expected_resolution_hours INT NULL,
    -- Audit
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (complaint_status),
    INDEX idx_category (complaint_category),
    INDEX idx_severity (severity_level),
    INDEX idx_transport (is_transport_related)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =========================================================
-- 2. COMPLAINT ACTION / TIMELINE
-- =========================================================

CREATE TABLE erp_complaint_actions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    complaint_id INT UNSIGNED NOT NULL,
    action_type VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Created, Assigned, Comment, Investigation, MedicalCheck, WarningIssued, Suspension, Escalated, Resolved, Closed, Reopened)
    performed_by_user_id INT UNSIGNED NOT NULL,
    performed_by_role VARCHAR(50) NOT NULL, 
    action_notes TEXT NULL,
    action_result VARCHAR(20) NULL, -- Pending, Passed, Failed, NotApplicable
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_complaint_actions_complaints (complaint_id) REFERENCES erp_complaints(id) ON DELETE CASCADE,
    INDEX idx_complaint_action (complaint_id, action_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3. MEDICAL & SAFETY CHECKS (TRANSPORT COMPLIANCE)
-- =========================================================
CREATE TABLE erp_complaint_medical_checks (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    complaint_id INT UNSIGNED NOT NULL,
    check_type VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (AlcoholTest, MedicalFitness, DrugTest)
    conducted_by VARCHAR(100) NULL,
    test_time DATETIME NOT NULL,
    result VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Positive, Negative, Inconclusive)
    remarks VARCHAR(255) NULL,
    FOREIGN KEY fk_complaint_medical_checks_complaints (complaint_id) REFERENCES erp_complaints(id) ON DELETE CASCADE,
    INDEX idx_medical_result (check_type, result)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 4. COMPLAINT ATTACHMENTS
-- =========================================================
CREATE TABLE erp_complaint_attachments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    complaint_id INT UNSIGNED NOT NULL,
    file_type VARCHAR(20) NOT NULL, -- FK to sys_dropdown_table e.g. (Image, Video, Audio, Document)
    file_path VARCHAR(255) NOT NULL,
    uploaded_by_user_id INT UNSIGNED NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY fk_complaint_attachments_complaints (complaint_id) REFERENCES erp_complaints(id) ON DELETE CASCADE,
                    INDEX idx_file_type (file_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- END: COMPLAINT MANAGEMENT MODULE
-- =========================================================








