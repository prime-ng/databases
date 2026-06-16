-- =============================================================================
-- CRT — Certificate & Template Module DDL
-- Module: Certificate (Modules\Certificate)
-- Table Prefix: crt_* (10 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: 2026-03-28
-- Based on: CRT_Certificate_Requirement.md v2
-- Sub-Modules: L1 Type/Template, L2 Requests, L3 Generation, L4 TC (Legal),
--              L5 Bulk Jobs, L6 Verification, L7 ID Cards, L8 DMS
-- =============================================================================
--
-- DDL CORRECTIONS (verified against tenant_db_v2.sql):
--   Phase 2 prompt specifies BIGINT UNSIGNED for all PKs/FKs — INCORRECT for this codebase.
--   Actual types used throughout tenant_db:
--     sys_users.id                     → INT UNSIGNED       (line 88 tenant_db_v2.sql)
--     std_students.id                  → INT UNSIGNED       (line 4619)
--     sys_media.id                     → INT UNSIGNED       (line 259)
--     sys_dropdown_table.id            → INT UNSIGNED       (line 201)
--     sch_org_academic_sessions_jnt.id → SMALLINT UNSIGNED  (line 446)
--   All crt_* PKs: INT UNSIGNED (consistent with platform convention).
--   FK column types match the actual PK type of the referenced table.
--
--   Cross-module reference correction:
--     Prompt references sch_academic_sessions — table does NOT exist.
--     Correct table: sch_org_academic_sessions_jnt (SMALLINT UNSIGNED PK).
--
--   Cross-module schema change (BR-CRT-011):
--     std_students.tc_issued does NOT exist in current tenant_db_v2.sql.
--     ALTER TABLE statement included at the bottom of this file.
--
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;

-- ===========================================================================
-- LAYER 1 — No crt_* dependencies (may reference sys_* or sch_* only)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Table 1: crt_certificate_types
-- Master definitions for each certificate type (Bonafide, TC, Character, etc.)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_certificate_types` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `name`              VARCHAR(150) NOT NULL COMMENT 'Display name e.g. Bonafide Certificate, Transfer Certificate',
  `code`              VARCHAR(10) NOT NULL COMMENT 'Unique short code e.g. BON, TC, CHR; alphanumeric max 10',
  `category`          ENUM('administrative','legal','character','achievement','identity') NOT NULL COMMENT 'Type category: administrative, legal, character, achievement, identity',
  `requires_approval` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = approval workflow required; 0 = auto-approve on submission and trigger generation immediately',
  `validity_days`     SMALLINT UNSIGNED NULL COMMENT 'Certificate validity in days; NULL = no expiry',
  `serial_format`     VARCHAR(100) NOT NULL DEFAULT '{TYPE_CODE}-{YYYY}-{SEQ6}' COMMENT 'Serial number format tokens: {TYPE_CODE},{YYYY},{YY},{SEQ4},{SEQ6}',
  `description`       TEXT NULL COMMENT 'Admin notes or description for this certificate type',
  `is_active`         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable; 0 hides type from portal request form',
  `created_by`        INT UNSIGNED NOT NULL COMMENT 'sys_users.id — user who created this record',
  `updated_by`        INT UNSIGNED NOT NULL COMMENT 'sys_users.id — user who last updated this record',
  `created_at`        TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`        TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`        TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_ct_code` (`code`),
  KEY `idx_crt_ct_is_active` (`is_active`),
  KEY `idx_crt_ct_category` (`category`),
  KEY `idx_crt_ct_created_by` (`created_by`),
  KEY `idx_crt_ct_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_ct_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_ct_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Master certificate type definitions — code, category, approval rules, serial format';

-- ---------------------------------------------------------------------------
-- Table 2: crt_id_card_configs
-- ID card template configurations (layout, fields, card size, QR placement)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_id_card_configs` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `card_type`            ENUM('student','staff') NOT NULL COMMENT 'student = Student ID Card; staff = Staff ID Card',
  `name`                 VARCHAR(150) NOT NULL COMMENT 'Configuration display name e.g. 2025-2026 Student CR80',
  `academic_session_id`  SMALLINT UNSIGNED NOT NULL COMMENT 'sch_org_academic_sessions_jnt.id — session this config applies to',
  `card_size`            ENUM('a5','cr80') NOT NULL DEFAULT 'cr80' COMMENT 'a5 = A5 paper; cr80 = credit-card size (85.6 x 54 mm)',
  `orientation`          ENUM('portrait','landscape') NOT NULL DEFAULT 'portrait' COMMENT 'Print orientation',
  `template_json`        JSON NOT NULL COMMENT 'Card layout: field positions, colors, font sizes, QR code placement coordinates',
  `cards_per_sheet`      TINYINT UNSIGNED NOT NULL DEFAULT 8 COMMENT 'Number of cards per A4 sheet for CR80 layout (valid: 1-20)',
  `is_active`            TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`           TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`           TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_crt_icc_card_type` (`card_type`),
  KEY `idx_crt_icc_academic_session_id` (`academic_session_id`),
  KEY `idx_crt_icc_created_by` (`created_by`),
  KEY `idx_crt_icc_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_icc_academic_session_id` FOREIGN KEY (`academic_session_id`) REFERENCES `sch_org_academic_sessions_jnt` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_icc_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_icc_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='ID card template configurations — layout, card size, QR placement per academic session';

-- ===========================================================================
-- LAYER 2 — Depends on Layer 1 (crt_certificate_types) or external tables
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Table 3: crt_templates
-- HTML/CSS certificate templates; multiple per type; only one is_default per type
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_templates` (
  `id`                       INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `certificate_type_id`      INT UNSIGNED NOT NULL COMMENT 'crt_certificate_types.id — type this template serves',
  `name`                     VARCHAR(150) NOT NULL COMMENT 'Template display name e.g. Bonafide A4 2026 Standard',
  `template_content`         LONGTEXT NOT NULL COMMENT 'Full HTML/CSS body with {{placeholder}} merge fields',
  `variables_json`           JSON NOT NULL COMMENT 'Declared merge field names array; all {{placeholders}} in template_content must appear here',
  `page_size`                ENUM('a4','a5','letter','custom') NOT NULL DEFAULT 'a4' COMMENT 'DomPDF paper size',
  `orientation`              ENUM('portrait','landscape') NOT NULL DEFAULT 'portrait' COMMENT 'DomPDF paper orientation',
  `is_default`               TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = default template for its type; application enforces only one per type (BR-CRT-012)',
  `signature_placement_json` JSON NULL COMMENT 'Optional x/y coordinates + dimensions for digital signature block',
  `version_no`               SMALLINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current version number; incremented on each save; prior version archived in crt_template_versions',
  `is_active`                TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`               INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`               INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`               TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`               TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`               TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_crt_tpl_certificate_type_id` (`certificate_type_id`),
  KEY `idx_crt_tpl_is_default` (`is_default`),
  KEY `idx_crt_tpl_created_by` (`created_by`),
  KEY `idx_crt_tpl_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_tpl_certificate_type_id` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_crt_tpl_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_tpl_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='HTML/CSS certificate templates; cascade-deletes with type; template hard-delete blocked by crt_issued_certificates FK';

-- ---------------------------------------------------------------------------
-- Table 4: crt_serial_counters
-- Per-type, per-year sequential counter; SELECT FOR UPDATE ensures no gaps (BR-CRT-015)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_serial_counters` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `certificate_type_id`  INT UNSIGNED NOT NULL COMMENT 'crt_certificate_types.id — one counter per type per year',
  `academic_year`        SMALLINT UNSIGNED NOT NULL COMMENT '4-digit year e.g. 2026; counter resets at start of each academic year',
  `last_seq_no`          INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Last issued sequence number; incremented atomically via SELECT FOR UPDATE (BR-CRT-015)',
  `is_active`            TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`           TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`           TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_sc_type_year` (`certificate_type_id`, `academic_year`),
  KEY `idx_crt_sc_certificate_type_id` (`certificate_type_id`),
  KEY `idx_crt_sc_created_by` (`created_by`),
  KEY `idx_crt_sc_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_sc_certificate_type_id` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_sc_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_sc_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Sequential certificate number counters — one row per type per year; SELECT FOR UPDATE prevents race conditions';

-- ---------------------------------------------------------------------------
-- Table 5: crt_bulk_jobs
-- Async bulk certificate generation job tracker (BulkGenerateCertificatesJob)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_bulk_jobs` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `certificate_type_id`  INT UNSIGNED NOT NULL COMMENT 'crt_certificate_types.id — type being bulk-generated',
  `initiated_by`         INT UNSIGNED NOT NULL COMMENT 'sys_users.id — Admin who triggered the bulk job',
  `filter_json`          JSON NULL COMMENT 'Filter: {class_id: INT|null, section_id: INT|null, student_ids: [INT]}',
  `total_count`          INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total certificates to be generated in this job',
  `processed_count`      INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Successfully generated so far',
  `failed_count`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Individual student failures (batch continues — BR-CRT-009)',
  `status`               ENUM('queued','processing','completed','failed') NOT NULL DEFAULT 'queued' COMMENT 'Job lifecycle: queued→processing→completed/failed',
  `zip_path`             VARCHAR(500) NULL COMMENT 'Relative path to completed ZIP on storage disk; populated when status=completed',
  `error_log_json`       JSON NULL COMMENT 'Per-student failure log: [{student_id, student_name, error}]',
  `started_at`           TIMESTAMP NULL COMMENT 'When queue worker picked up this job',
  `completed_at`         TIMESTAMP NULL COMMENT 'When job finished (completed or failed)',
  `is_active`            TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`           TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`           TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_crt_bj_certificate_type_id` (`certificate_type_id`),
  KEY `idx_crt_bj_initiated_by` (`initiated_by`),
  KEY `idx_crt_bj_status` (`status`),
  KEY `idx_crt_bj_created_by` (`created_by`),
  KEY `idx_crt_bj_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_bj_certificate_type_id` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_bj_initiated_by` FOREIGN KEY (`initiated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_bj_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_bj_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Async bulk certificate generation job tracker (BulkGenerateCertificatesJob)';

-- ---------------------------------------------------------------------------
-- Table 6: crt_student_documents
-- DMS — incoming student documents with admin verification workflow
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_student_documents` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `student_id`              INT UNSIGNED NOT NULL COMMENT 'std_students.id — document owner',
  `document_category_id`    INT UNSIGNED NOT NULL COMMENT 'sys_dropdown_table.id — seeded categories: TC, Migration, DOB, Aadhaar, Caste, Disability, Photo, Other',
  `document_name`           VARCHAR(255) NOT NULL COMMENT 'Human-readable document name e.g. Birth Certificate 2010',
  `document_date`           DATE NULL COMMENT 'Date printed on the document (e.g. issue date of previous TC)',
  `media_id`                INT UNSIGNED NOT NULL COMMENT 'sys_media.id — polymorphic file storage (model_type=StudentDocument)',
  `verification_status`     ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending' COMMENT 'pending = awaiting admin review; verified = confirmed valid; rejected = rejected (cannot satisfy eligibility BR-CRT-008)',
  `verification_remarks`    TEXT NULL COMMENT 'Admin remarks; required when verification_status = rejected',
  `verified_by`             INT UNSIGNED NULL COMMENT 'sys_users.id — Admin who verified or rejected; NULL while pending',
  `verified_at`             TIMESTAMP NULL COMMENT 'Timestamp of verification action',
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`              INT UNSIGNED NOT NULL COMMENT 'sys_users.id — clerk who uploaded',
  `updated_by`              INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`              TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`              TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`              TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  KEY `idx_crt_sd_student_id` (`student_id`),
  KEY `idx_crt_sd_document_category_id` (`document_category_id`),
  KEY `idx_crt_sd_media_id` (`media_id`),
  KEY `idx_crt_sd_verified_by` (`verified_by`),
  KEY `idx_crt_sd_verification_status` (`verification_status`),
  KEY `idx_crt_sd_created_by` (`created_by`),
  KEY `idx_crt_sd_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_sd_student_id` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_sd_document_category_id` FOREIGN KEY (`document_category_id`) REFERENCES `sys_dropdown_table` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_sd_media_id` FOREIGN KEY (`media_id`) REFERENCES `sys_media` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_sd_verified_by` FOREIGN KEY (`verified_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crt_sd_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_sd_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='DMS — incoming student documents (TC, DOB cert, Aadhaar etc.) with verification workflow';

-- ===========================================================================
-- LAYER 3 — Depends on Layer 2
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Table 7: crt_template_versions
-- Immutable archive snapshot of template content before each edit
-- NOTE: NO deleted_at column — versions are immutable archive records (DDL Rule 14)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_template_versions` (
  `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `template_id`      INT UNSIGNED NOT NULL COMMENT 'crt_templates.id — the live template this version was archived from',
  `version_no`       SMALLINT UNSIGNED NOT NULL COMMENT 'Sequential version number per template; archived before each save',
  `template_content` LONGTEXT NOT NULL COMMENT 'Snapshot of HTML/CSS template content at this version',
  `variables_json`   JSON NOT NULL COMMENT 'Snapshot of declared merge field names at this version',
  `saved_by`         INT UNSIGNED NOT NULL COMMENT 'sys_users.id — user who triggered the save that archived this version',
  `saved_at`         TIMESTAMP NOT NULL COMMENT 'Exact timestamp when this version was archived',
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`       INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`       INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`       TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`       TIMESTAMP NULL COMMENT 'Last update timestamp',
  -- NO deleted_at column: versions are immutable archives; they are never soft-deleted (DDL Rule 14)
  PRIMARY KEY (`id`),
  KEY `idx_crt_tv_template_id` (`template_id`),
  KEY `idx_crt_tv_version_no` (`version_no`),
  KEY `idx_crt_tv_saved_by` (`saved_by`),
  KEY `idx_crt_tv_created_by` (`created_by`),
  KEY `idx_crt_tv_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_tv_template_id` FOREIGN KEY (`template_id`) REFERENCES `crt_templates` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_crt_tv_saved_by` FOREIGN KEY (`saved_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_tv_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_tv_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable archive snapshots of certificate templates — no soft delete; cascade with parent template';

-- ---------------------------------------------------------------------------
-- Table 8: crt_requests
-- Certificate request workflow — 6-state FSM
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_requests` (
  `id`                       INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `request_no`               VARCHAR(30) NOT NULL COMMENT 'Auto-generated request number: REQ-YYYY-000001 (year-wise sequential)',
  `certificate_type_id`      INT UNSIGNED NOT NULL COMMENT 'crt_certificate_types.id',
  `requester_type`           ENUM('student','parent','staff','admin') NOT NULL COMMENT 'Who submitted this request',
  `requester_id`             INT UNSIGNED NOT NULL COMMENT 'sys_users.id — polymorphic; resolved by requester_type; no DB-level FK',
  `beneficiary_student_id`   INT UNSIGNED NULL COMMENT 'std_students.id — student for whom the certificate is; NULL for staff certs',
  `purpose`                  TEXT NOT NULL COMMENT 'Stated reason for requesting the certificate',
  `required_by_date`         DATE NULL COMMENT 'Requested delivery date — used for urgency sorting in pending queue',
  `supporting_doc_media_id`  INT UNSIGNED NULL COMMENT 'sys_media.id — attached supporting document (polymorphic model_type=CertificateRequest, BR-CRT-014)',
  `status`                   ENUM('pending','under_review','approved','rejected','generated','issued') NOT NULL DEFAULT 'pending' COMMENT 'FSM: pending→under_review→approved/rejected→generated→issued',
  `approved_by`              INT UNSIGNED NULL COMMENT 'sys_users.id — Principal or Admin who approved; NULL until approved',
  `approved_at`              TIMESTAMP NULL COMMENT 'Approval timestamp',
  `approval_remarks`         TEXT NULL COMMENT 'Optional approver comments',
  `rejection_reason`         TEXT NULL COMMENT 'Mandatory when status=rejected (BR-CRT-013); validated in RejectCertificateRequestRequest',
  `is_active`                TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`               INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`               INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`               TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`               TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`               TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_req_request_no` (`request_no`),
  INDEX `idx_crt_req_student_type_status` (`beneficiary_student_id`, `certificate_type_id`, `status`),
  KEY `idx_crt_req_certificate_type_id` (`certificate_type_id`),
  KEY `idx_crt_req_status` (`status`),
  KEY `idx_crt_req_approved_by` (`approved_by`),
  KEY `idx_crt_req_supporting_doc` (`supporting_doc_media_id`),
  KEY `idx_crt_req_created_by` (`created_by`),
  KEY `idx_crt_req_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_req_certificate_type_id` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_req_beneficiary_student_id` FOREIGN KEY (`beneficiary_student_id`) REFERENCES `std_students` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_req_supporting_doc_media_id` FOREIGN KEY (`supporting_doc_media_id`) REFERENCES `sys_media` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crt_req_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crt_req_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_req_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Certificate requests — 6-state FSM (pending→under_review→approved/rejected→generated→issued)';

-- ===========================================================================
-- LAYER 4 — Depends on Layer 3
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Table 9: crt_issued_certificates
-- All generated certificates (request-based and direct/bulk admin-initiated)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_issued_certificates` (
  `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `certificate_no`       VARCHAR(50) NOT NULL COMMENT 'Generated serial number e.g. BON-2026-000042; globally unique per tenant',
  `request_id`           INT UNSIGNED NULL COMMENT 'crt_requests.id — NULL for direct-issue (achievement/bulk) certificates',
  `certificate_type_id`  INT UNSIGNED NOT NULL COMMENT 'crt_certificate_types.id',
  `template_id`          INT UNSIGNED NOT NULL COMMENT 'crt_templates.id — ON DELETE RESTRICT prevents template hard-delete if referenced (BR-CRT-006)',
  `recipient_type`       ENUM('student','staff') NOT NULL COMMENT 'Recipient entity type',
  `recipient_id`         INT UNSIGNED NOT NULL COMMENT 'std_students.id or sys_users.id — resolved by recipient_type; polymorphic: no DB-level FK',
  `issue_date`           DATE NOT NULL COMMENT 'Official certificate issue date',
  `validity_date`        DATE NULL COMMENT 'Certificate expiry date; NULL = no expiry (open-ended)',
  `verification_hash`    VARCHAR(64) NOT NULL COMMENT 'HMAC-SHA256 hex of (certificate_no+issue_date+recipient_id+APP_KEY); used for QR verification lookup',
  `file_path`            VARCHAR(500) NOT NULL COMMENT 'Relative path: storage/tenant_{id}/certificates/{type_code}/{YYYY}/{cert_no}.pdf',
  `is_revoked`           TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = certificate revoked; verification returns REVOKED status not 404 (BR-CRT-005)',
  `revoked_at`           TIMESTAMP NULL COMMENT 'Revocation timestamp',
  `revoked_by`           INT UNSIGNED NULL COMMENT 'sys_users.id — Admin who revoked; NULL until revoked',
  `revocation_reason`    TEXT NULL COMMENT 'Reason for revocation; required when is_revoked = 1',
  `is_duplicate`         TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = second issuance to same recipient+type; PDF renders with DUPLICATE COPY watermark (BR-CRT-003)',
  `is_active`            TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id — user who triggered generation (serves as issued_by)',
  `updated_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`           TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`           TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`           TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_ic_certificate_no` (`certificate_no`),
  UNIQUE KEY `uq_crt_ic_verification_hash` (`verification_hash`),
  KEY `idx_crt_ic_request_id` (`request_id`),
  KEY `idx_crt_ic_certificate_type_id` (`certificate_type_id`),
  KEY `idx_crt_ic_template_id` (`template_id`),
  KEY `idx_crt_ic_recipient` (`recipient_type`, `recipient_id`),
  KEY `idx_crt_ic_issue_date` (`issue_date`),
  KEY `idx_crt_ic_validity_date` (`validity_date`),
  KEY `idx_crt_ic_is_revoked` (`is_revoked`),
  KEY `idx_crt_ic_revoked_by` (`revoked_by`),
  KEY `idx_crt_ic_created_by` (`created_by`),
  KEY `idx_crt_ic_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_ic_request_id` FOREIGN KEY (`request_id`) REFERENCES `crt_requests` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crt_ic_certificate_type_id` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_ic_template_id` FOREIGN KEY (`template_id`) REFERENCES `crt_templates` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_ic_revoked_by` FOREIGN KEY (`revoked_by`) REFERENCES `sys_users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_crt_ic_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_ic_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='All issued certificates; verification_hash UNIQUE for O(1) QR verification lookup';

-- ===========================================================================
-- LAYER 5 — Depends on Layer 4
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Table 10: crt_tc_register
-- Formal TC register — legally mandated sequential logbook (Indian state boards)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `crt_tc_register` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `sl_no`                 SMALLINT UNSIGNED NOT NULL COMMENT 'Sequential TC serial number for the year; no gaps allowed (BR-CRT-002)',
  `academic_year`         SMALLINT UNSIGNED NOT NULL COMMENT '4-digit academic year e.g. 2026; sl_no resets each year',
  `issued_certificate_id` INT UNSIGNED NOT NULL COMMENT 'crt_issued_certificates.id — the TC certificate this register entry corresponds to',
  `student_name`          VARCHAR(200) NOT NULL COMMENT 'Full student name snapshot at time of TC issuance',
  `father_name`           VARCHAR(200) NULL COMMENT 'Father/guardian name snapshot',
  `date_of_birth`         DATE NOT NULL COMMENT 'Student date of birth snapshot',
  `class_at_leaving`      VARCHAR(50) NOT NULL COMMENT 'Class/Section at time of leaving e.g. Grade 10 - A',
  `date_of_admission`     DATE NOT NULL COMMENT 'Original admission date to this school',
  `date_of_leaving`       DATE NOT NULL COMMENT 'Date of leaving school — mandatory TC input field',
  `conduct`               VARCHAR(100) NOT NULL DEFAULT 'Good' COMMENT 'Conduct remark e.g. Good, Excellent, Satisfactory',
  `reason_for_leaving`    VARCHAR(255) NOT NULL COMMENT 'Reason for transfer — mandatory TC input field',
  `is_duplicate_entry`    TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = this TC register entry is for a re-issued (duplicate) TC',
  `prepared_by`           INT UNSIGNED NOT NULL COMMENT 'sys_users.id — Principal or Admin who prepared and authorised the TC',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable',
  `created_by`            INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `updated_by`            INT UNSIGNED NOT NULL COMMENT 'sys_users.id',
  `created_at`            TIMESTAMP NULL COMMENT 'Record creation timestamp',
  `updated_at`            TIMESTAMP NULL COMMENT 'Last update timestamp',
  `deleted_at`            TIMESTAMP NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_tc_sl_year` (`sl_no`, `academic_year`),
  KEY `idx_crt_tc_issued_certificate_id` (`issued_certificate_id`),
  KEY `idx_crt_tc_academic_year` (`academic_year`),
  KEY `idx_crt_tc_prepared_by` (`prepared_by`),
  KEY `idx_crt_tc_created_by` (`created_by`),
  KEY `idx_crt_tc_updated_by` (`updated_by`),
  CONSTRAINT `fk_crt_tc_issued_certificate_id` FOREIGN KEY (`issued_certificate_id`) REFERENCES `crt_issued_certificates` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_tc_prepared_by` FOREIGN KEY (`prepared_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_tc_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crt_tc_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `sys_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Formal TC register — legally mandated sequential logbook for Transfer Certificates (Indian state boards)';

SET FOREIGN_KEY_CHECKS = 1;

-- ===========================================================================
-- CROSS-MODULE SCHEMA CHANGE (required by CRT module)
-- ===========================================================================
-- BR-CRT-011 requires writing std_students.tc_issued = true after TC generation.
-- This column does NOT exist in current tenant_db_v2.sql.
-- Run this ALTER as part of the CRT module installation migration (CRT_Migration.php up()):
--
-- ALTER TABLE `std_students`
--   ADD COLUMN `tc_issued` TINYINT(1) NOT NULL DEFAULT 0
--     COMMENT 'Set to 1 by CRT module after TC issuance (BR-CRT-011)'
--   AFTER `current_status_id`;
--
-- Revert (CRT_Migration.php down()):
-- ALTER TABLE `std_students` DROP COLUMN IF EXISTS `tc_issued`;
-- ===========================================================================
