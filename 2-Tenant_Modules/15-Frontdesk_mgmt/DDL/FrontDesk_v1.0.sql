/* =========================================================
   FRONTDESK MODULE - CONSOLIDATED SQL
   Compatible: MySQL 8.x
   ========================================================= */

SET FOREIGN_KEY_CHECKS = 0;

/* =========================================================
   1. VISITOR MANAGEMENT
   ========================================================= */

DROP TABLE IF EXISTS fd_visitor_visits;
DROP TABLE IF EXISTS fd_visitors;

CREATE TABLE fd_visitors (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    visitor_name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20) NOT NULL,
    email VARCHAR(150),
    address TEXT,
    organization VARCHAR(150),
    visitor_type ENUM('Parent','Vendor','Guest','Official','Alumni','Other') NOT NULL,
    id_proof_type VARCHAR(50),
    id_proof_number VARCHAR(100),
    photo_path VARCHAR(255),
    blacklisted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

CREATE TABLE fd_visitor_visits (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    visitor_id BIGINT NOT NULL,
    purpose TEXT NOT NULL,
    host_type ENUM('Student','Staff','Department') NOT NULL,
    host_id BIGINT,
    expected_out_time DATETIME,
    checkin_time DATETIME,
    checkout_time DATETIME,
    pass_number VARCHAR(50) UNIQUE,
    pass_qr_path VARCHAR(255),
    status ENUM('CheckedIn','CheckedOut','Cancelled') DEFAULT 'CheckedIn',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_fd_visit_visitor FOREIGN KEY (visitor_id) REFERENCES fd_visitors(id)
) ENGINE=InnoDB;

/* =========================================================
   2. GATE PASS MANAGEMENT
   ========================================================= */

DROP TABLE IF EXISTS fd_gate_logs;
DROP TABLE IF EXISTS fd_gate_passes;

CREATE TABLE fd_gate_passes (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pass_number VARCHAR(50) UNIQUE,
    pass_for ENUM('Student','Staff') NOT NULL,
    person_id BIGINT NOT NULL,
    reason TEXT NOT NULL,
    pass_type ENUM('Outgoing','Incoming','Temporary') NOT NULL,
    expected_return_time DATETIME,
    approved_by BIGINT,
    approval_status ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

CREATE TABLE fd_gate_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    gate_pass_id BIGINT NOT NULL,
    scan_type ENUM('IN','OUT') NOT NULL,
    scan_time DATETIME NOT NULL,
    scanned_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_fd_gate_log_pass FOREIGN KEY (gate_pass_id) REFERENCES fd_gate_passes(id)
) ENGINE=InnoDB;

/* =========================================================
   3. APPROVAL WORKFLOW (COMMON)
   ========================================================= */

DROP TABLE IF EXISTS fd_approvals;

CREATE TABLE fd_approvals (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    module ENUM('Visitor','GatePass','Certificate','Request','Complaint') NOT NULL,
    reference_id BIGINT NOT NULL,
    approver_id BIGINT NOT NULL,
    level INT NOT NULL,
    status ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    comments TEXT,
    acted_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    INDEX idx_fd_approval_ref (module, reference_id)
) ENGINE=InnoDB;

/* =========================================================
   4. COMMUNICATION & NOTIFICATIONS
   ========================================================= */

DROP TABLE IF EXISTS fd_message_logs;
DROP TABLE IF EXISTS fd_message_templates;

CREATE TABLE fd_message_templates (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    template_name VARCHAR(100),
    channel ENUM('SMS','Email','WhatsApp') NOT NULL,
    subject VARCHAR(150),
    body TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

CREATE TABLE fd_message_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    channel ENUM('SMS','Email','WhatsApp') NOT NULL,
    recipient_type ENUM('Student','Parent','Staff','Visitor'),
    recipient_contact VARCHAR(150),
    message TEXT,
    delivery_status ENUM('Pending','Sent','Delivered','Failed') DEFAULT 'Pending',
    provider_response TEXT,
    sent_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    INDEX idx_fd_msg_status (delivery_status)
) ENGINE=InnoDB;

/* =========================================================
   5. COMPLAINT & GRIEVANCE MANAGEMENT
   ========================================================= */

DROP TABLE IF EXISTS fd_complaint_logs;
DROP TABLE IF EXISTS fd_complaints;

CREATE TABLE fd_complaints (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    complaint_no VARCHAR(50) UNIQUE,
    raised_by ENUM('Student','Parent','Staff') NOT NULL,
    raised_by_id BIGINT NOT NULL,
    category ENUM('Academic','Transport','Infrastructure','Safety','Other'),
    priority ENUM('Low','Medium','High','Critical') DEFAULT 'Medium',
    description TEXT NOT NULL,
    assigned_to BIGINT,
    status ENUM('Open','InProgress','OnHold','Resolved','Closed') DEFAULT 'Open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

CREATE TABLE fd_complaint_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    complaint_id BIGINT NOT NULL,
    action VARCHAR(150),
    remarks TEXT,
    action_by BIGINT,
    action_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_fd_complaint_log FOREIGN KEY (complaint_id) REFERENCES fd_complaints(id)
) ENGINE=InnoDB;

/* =========================================================
   6. FEEDBACK MANAGEMENT
   ========================================================= */

DROP TABLE IF EXISTS fd_feedback_responses;
DROP TABLE IF EXISTS fd_feedback_forms;

CREATE TABLE fd_feedback_forms (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150),
    audience ENUM('Student','Parent','Staff'),
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

CREATE TABLE fd_feedback_responses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    form_id BIGINT NOT NULL,
    respondent_id BIGINT,
    rating INT,
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    CONSTRAINT fk_fd_feedback_form FOREIGN KEY (form_id) REFERENCES fd_feedback_forms(id)
) ENGINE=InnoDB;

/* =========================================================
   7. STUDENT REQUEST MANAGEMENT
   ========================================================= */

DROP TABLE IF EXISTS fd_requests;

CREATE TABLE fd_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    request_no VARCHAR(50) UNIQUE,
    student_id BIGINT NOT NULL,
    request_type ENUM('Certificate','Leave','IDCard','Other') NOT NULL,
    description TEXT,
    status ENUM('Pending','Approved','Rejected','Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

/* =========================================================
   8. CERTIFICATE MANAGEMENT
   ========================================================= */

DROP TABLE IF EXISTS fd_certificates;

CREATE TABLE fd_certificates (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    certificate_no VARCHAR(50) UNIQUE,
    certificate_type ENUM('Bonafide','Character','TC','Attendance'),
    student_id BIGINT NOT NULL,
    issued_on DATE,
    pdf_path VARCHAR(255),
    issued_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
) ENGINE=InnoDB;

/* =========================================================
   9. AUDIT & SECURITY
   ========================================================= */

DROP TABLE IF EXISTS fd_audit_logs;

CREATE TABLE fd_audit_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    module VARCHAR(50),
    reference_id BIGINT,
    action VARCHAR(100),
    performed_by BIGINT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    INDEX idx_fd_audit_ref (module, reference_id)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

/* ===================== END OF FILE ====================== */
