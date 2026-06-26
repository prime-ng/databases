# CRT — Certificate & Template Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY
**Module Code:** CRT | **Table Prefix:** `crt_` | **DB:** tenant_db
**Laravel Module Path:** `Modules/Certificate`

---

## 1. Executive Summary

The Certificate & Template module provides an end-to-end certificate lifecycle management system for Indian K-12 schools on the Prime-AI platform. It handles template design, certificate request workflows, PDF generation, digital verification, bulk issuance, ID card generation, and a document management system (DMS) for incoming student documents.

Every issued certificate carries a tamper-evident HMAC-SHA256 verification hash and an embedded QR code. Third-party institutions (banks, embassies, universities) can scan the QR code to reach a no-login public verification endpoint — confirming authenticity without contacting the school.

**V2 additions over V1:** Migration Certificate added as a distinct type; serial-number format made configurable per type; `crt_serial_counters` table formalised; `crt_tc_register` preserved as a separate formal table; `crt_bulk_jobs` added for async job tracking; digital signature placement field added to templates; staff document management extended under DMS.

| Metric | Count |
|---|---|
| Functional Requirements | 12 (FR-CRT-001 … FR-CRT-012) |
| Proposed DB Tables (`crt_*`) | 10 |
| Proposed Named Web Routes | ~58 |
| Proposed API Routes | 2 |
| Proposed Blade Views | ~30 |
| Proposed Controllers | 9 |
| Proposed Services | 3 |
| Proposed Jobs | 1 (bulk generation) |
| Overall Implementation | ❌ 0% — Greenfield |

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools issue a high volume of certificates throughout the academic year. Without a dedicated module schools use ad-hoc Word/PDF templates — leading to inconsistency, no tracking, no verification capability, and easy forgery. The CRT module solves this by:

1. Standardising templates — school admins design once, the system fills merge fields automatically.
2. Enforcing workflow — requests go through an approval gate before PDF is generated.
3. Creating a complete audit trail — every certificate has a unique serial number, issue date, issuing authority, and a tamper-evident hash.
4. Enabling digital verification — any third party can scan the QR code or call the API.
5. Centralising incoming documents — the DMS stores birth certificates, previous TCs, migration certificates with verification status.

### 2.2 Certificate Type Categories

| Category | Types | Approval Required | Auto-Number Format |
|---|---|---|---|
| Administrative | Bonafide, Study/Conduct | Yes | `BON-YYYY-000001` |
| Legal / Government | Transfer Certificate (TC), Migration | Yes + fee-clear check | `TC-YYYY-0001` |
| Character / Conduct | Character, Good Conduct | Yes | `CHR-YYYY-000001` |
| Achievement | Merit, Sports, Participation, Custom | No (admin-initiated) | `ACH-YYYY-000001` |
| Identity | Student ID Card, Staff ID Card | No | N/A (batch) |

### 2.3 Module Architecture

```
Modules/Certificate/
├── Http/Controllers/
│   ├── CertificateTypeController.php
│   ├── CertificateTemplateController.php
│   ├── CertificateRequestController.php
│   ├── CertificateIssuedController.php
│   ├── BulkGenerationController.php
│   ├── IdCardController.php
│   ├── DocumentManagementController.php
│   ├── VerificationController.php        # public verify + admin logs
│   └── CertificateReportController.php
├── Jobs/
│   └── BulkGenerateCertificatesJob.php
├── Models/  (10 models)
├── Services/
│   ├── CertificateGenerationService.php
│   ├── QrVerificationService.php
│   └── DmsService.php
└── resources/views/certificate/  (~30 blade files)
```

### 2.4 Menu Navigation

```
School Admin Panel
└── Certificate [/certificate]
    ├── Dashboard
    ├── Template Management
    │   ├── Certificate Types
    │   └── Templates
    ├── Certificates
    │   ├── Requests (pending queue)
    │   ├── Issued Register
    │   └── Bulk Generation
    ├── ID Cards
    │   ├── ID Card Config
    │   └── Generate ID Cards
    ├── Document Management (DMS)
    ├── Verification Logs
    └── Reports
        ├── Issued Certificates
        ├── Pending Requests
        └── Type Analytics
```

---

## 3. Stakeholders & Roles

| Actor | Permissions | Key Actions |
|---|---|---|
| School Admin | Full access | Configure types/templates, approve requests, issue certificates, revoke, manage DMS, view all reports |
| Principal | Approve/reject, view all | Final approver for TC and Character; digital authority on template |
| Clerk / Front Office | create-request, issue, dms.upload | Submit on behalf of students; record physical handover |
| Class Teacher | view (own class only) | View certificates issued to own class students |
| Student | create-request (own), view (own) | Submit via portal; download own issued certificates |
| Parent | create-request (ward), view (ward) | Submit via portal for their ward |
| Third Party / External | Public endpoint only | Scan QR code to verify authenticity — no login required |
| System | Internal actor | Auto-generate certificate number, send notifications, dispatch bulk jobs |

---

## 4. Functional Requirements

---

### FR-CRT-001: Certificate Type Management
**Status:** 📐 Proposed
**Priority:** Critical — prerequisite for all certificate generation
**Tables:** `crt_certificate_types`, `crt_serial_counters`

**Description:** Admins define named certificate types with categories, approval requirements, validity rules, and serial-number format configuration. Serial counters are maintained separately to allow year-wise sequential reset.

**Acceptance Criteria:**
- AC1: Certificate type has a unique code (max 10 chars, alphanumeric); duplicate code rejected.
- AC2: `requires_approval` flag drives whether requests auto-proceed or queue for approval.
- AC3: `validity_days` NULL means no expiry; non-null certificates auto-expire.
- AC4: Serial counter resets at start of each academic year; no gaps in sequence within a year.
- AC5: Deleting a type with issued certificates is blocked (soft delete only; hard delete prevented by FK).
- AC6: Toggling `is_active = false` hides type from portal request form but preserves existing records.

---

### FR-CRT-002: Certificate Template Designer
**Status:** 📐 Proposed
**Priority:** Critical
**Tables:** `crt_templates`, `crt_template_versions`

**Description:** Admins create HTML/CSS templates using merge field placeholders (`{{student_name}}`, `{{class_section}}`, `{{dob}}`, `{{admission_no}}`, `{{certificate_no}}`, `{{issue_date}}`, `{{principal_name}}`, `{{school_name}}`, `{{school_address}}`). Page size, orientation, and digital signature placement are configurable. Every save archives the previous version.

**Acceptance Criteria:**
- AC1: Template content stored as LONGTEXT HTML; variables declared in `variables_json` array.
- AC2: All placeholders in `template_content` must be listed in `variables_json` — validation rejects mismatches.
- AC3: Preview renders template with dummy student data via DomPDF; result served as inline PDF.
- AC4: Saving an edited template creates a new row in `crt_template_versions` with incremented `version_no` before overwriting.
- AC5: Admin can view version history and restore any prior version; restore creates a new version entry for the current content first.
- AC6: Only one template per certificate type can have `is_default = true`; marking one default auto-clears others.
- AC7: Template cannot be hard-deleted if referenced by any `crt_issued_certificates` record.
- AC8: `signature_placement_json` optionally stores x/y coordinates and dimensions for digital signature block.

---

### FR-CRT-003: Certificate Request Workflow
**Status:** 📐 Proposed
**Priority:** Critical
**Tables:** `crt_requests`

**Description:** Students, parents, or staff submit certificate requests through the portal. Admin/Principal reviews, validates eligibility, then approves or rejects. On approval the certificate is auto-generated. Status lifecycle: `pending → under_review → approved/rejected → generated → issued`.

**Acceptance Criteria:**
- AC1: Request number auto-generated in format `REQ-YYYY-000001` (year-wise sequential).
- AC2: If `certificate_type.requires_approval = false`, request status immediately advances to `approved` and generation is triggered.
- AC3: Supporting documents (PDF/image, max 5MB each) can be attached via `sys_media`.
- AC4: Approver can add `approval_remarks`; rejecter must provide `rejection_reason`.
- AC5: Email/SMS notification sent on: request submission, status change to approved, status change to rejected.
- AC6: Requester (student/parent) can track status in real time via the portal.
- AC7: Duplicate pending request for same student + same type is blocked (unique check on `beneficiary_student_id + certificate_type_id + status IN (pending, under_review, approved)`).

---

### FR-CRT-004: Certificate Generation & Issuance
**Status:** 📐 Proposed
**Priority:** Critical
**Tables:** `crt_issued_certificates`, `crt_serial_counters`

**Description:** On request approval (or admin direct-issue for achievement types), `CertificateGenerationService` resolves merge fields from student records, generates sequential certificate number, embeds QR code, renders PDF via DomPDF, stores the file, and writes the `crt_issued_certificates` record.

**Acceptance Criteria:**
- AC1: Certificate number unique per tenant; format `[TYPE_CODE]-[YYYY]-[6-digit-seq]` (e.g., `BON-2026-000042`).
- AC2: All required merge fields resolved from `std_students`, `std_profiles`, `sch_academic_sessions`.
- AC3: PDF stored in `storage/tenant_{id}/certificates/{type}/{YYYY}/` path.
- AC4: `verification_hash` = HMAC-SHA256 of `(certificate_no + issue_date + recipient_id + APP_KEY)`; stored in `crt_issued_certificates`.
- AC5: Issued certificate can be downloaded by authorised users; download event logged in `sys_activity_logs`.
- AC6: Admin can revoke a certificate; revocation stores `revoked_at`, `revoked_by`, `revocation_reason`. Verification endpoint returns REVOKED for revoked certs.
- AC7: Second issuance of same certificate type to same student is marked `is_duplicate = true` and renders with "DUPLICATE COPY" watermark.

---

### FR-CRT-005: Transfer Certificate (TC)
**Status:** 📐 Proposed
**Priority:** Critical
**Tables:** `crt_requests`, `crt_issued_certificates`, `crt_tc_register`

**Description:** TC is a legally mandated document in India. It uses a government-prescribed format and requires a formal TC register (sequential logbook). TC issuance is blocked if student has outstanding fee dues (unless admin provides override justification).

**Acceptance Criteria:**
- AC1: TC cannot be generated if `fin_fee_dues > 0` unless admin records override justification.
- AC2: TC register entry auto-created on TC generation; includes all fields required by state boards (sl. no., name, father's name, class at leaving, date of admission, date of leaving, conduct, duplicate flag).
- AC3: TC serial number (`crt_tc_register.sl_no`) is sequential and year-wise; gaps are not allowed.
- AC4: `date_of_leaving` and `reason_for_leaving` are mandatory input for TC.
- AC5: TC register can be printed as a formatted table (admin route).
- AC6: Once TC is issued, `std_students.tc_issued = true`; student status auto-updated to withdrawn.

---

### FR-CRT-006: Achievement & Bulk Certificates
**Status:** 📐 Proposed
**Priority:** High
**Tables:** `crt_issued_certificates`, `crt_bulk_jobs`

**Description:** Admin can generate sports, merit, participation, or custom achievement certificates for individual or multiple students in one operation. Achievement certificates do not require a prior request or approval. Bulk generation is asynchronous via `BulkGenerateCertificatesJob`.

**Acceptance Criteria:**
- AC1: Achievement certificates can be generated directly by admin without request workflow.
- AC2: Bulk generation accepts: `certificate_type_id`, `class_id`, `section_id` (optional), explicit `student_ids` array (optional).
- AC3: Bulk jobs exceeding 200 certificates must be dispatched to queue; smaller batches may be synchronous.
- AC4: `crt_bulk_jobs` records: `total_count`, `processed_count`, `failed_count`, `status` ENUM(`queued`, `processing`, `completed`, `failed`), `zip_path`.
- AC5: Polling endpoint `/certificate/bulk-generate/{job}/status` returns current progress JSON.
- AC6: On completion, ZIP file available for download; named `[CertType]_[Class]_[YYYYMMDD].zip`; individual PDFs inside named `[CertNo]_[StudentName].pdf`.
- AC7: Individual generation failures do not abort the entire batch; failures logged in `crt_bulk_jobs.error_log_json`.

---

### FR-CRT-007: Digital Verification (QR + API)
**Status:** 📐 Proposed
**Priority:** Critical
**Tables:** `crt_issued_certificates`, `crt_verification_logs`

**Description:** Every issued certificate embeds a QR code pointing to a public verification URL. A no-login web page shows validity status. A REST API allows third-party institutions to verify programmatically with an API key.

**Acceptance Criteria:**
- AC1: QR encodes URL `https://{school-domain}/verify/{verification_hash}`.
- AC2: Public page at `/verify/{hash}` displays: certificate type, issued-to (first name + last initial only), issuing school name, issue date, validity status (VALID / EXPIRED / REVOKED). Does NOT expose full name, DOB, class, or address.
- AC3: Every verification attempt logged in `crt_verification_logs` with IP, user-agent, method, and result.
- AC4: API endpoint `GET /api/v1/certificate/verify?hash={hash}&api_key={key}` requires valid API key; returns JSON `{valid, certificate_type, issued_to, issued_date, issued_by, expires_on}`.
- AC5: Unauthorised API calls return HTTP 401.
- AC6: Admin can view all verification logs for any certificate; filterable by date range and method.

---

### FR-CRT-008: ID Card Generation
**Status:** 📐 Proposed
**Priority:** High
**Tables:** `crt_id_card_configs`, `crt_id_card_issued`

**Description:** Admin designs ID card templates for students and staff. Student cards include photo, name, class/section, admission number, blood group, emergency contact, academic year, and QR code. Staff cards include photo, name, designation, employee ID, and QR code. Bulk printable PDF arranges multiple cards per A4 sheet.

**Acceptance Criteria:**
- AC1: Card sizes supported: A5 and CR80 (85.6 × 54 mm credit-card size).
- AC2: Student photo fetched from `sys_media` (polymorphic); placeholder shown if no photo uploaded.
- AC3: QR code per card encodes student/staff identifier; generated with SimpleSoftwareIO QR.
- AC4: Blood group must be shown when present in `std_profiles`; blank field if absent.
- AC5: Printable sheet arranges CR80 cards in grid (default 8 per A4 page, configurable `cards_per_sheet`).
- AC6: Handover tracking: admin can mark individual students as `card_received = true` with date.

---

### FR-CRT-009: Document Management System (DMS)
**Status:** 📐 Proposed
**Priority:** High
**Tables:** `crt_student_documents`

**Description:** School staff upload incoming student documents (birth certificate, previous TC, migration certificate, caste certificate, disability certificate, Aadhaar, photos) and categorise them. Admin reviews and marks each document as verified/rejected. Document verification status feeds into certificate eligibility checks.

**Acceptance Criteria:**
- AC1: Allowed MIME types: `application/pdf`, `image/jpeg`, `image/png`; max 5 MB per file.
- AC2: Document category selectable from `sys_dropdown_table` (seeded: TC, Migration, DOB, Aadhaar, Caste, Disability, Photo, Other).
- AC3: Uploaded files stored via `sys_media` (polymorphic model `StudentDocument`).
- AC4: Verification status: `pending → verified` or `pending → rejected` with mandatory rejection remarks.
- AC5: Documents with status `rejected` cannot satisfy certificate eligibility checks (e.g., TC issuance requiring verified previous TC).
- AC6: Download events logged in `sys_activity_logs` with user_id, document_id, and timestamp.

---

### FR-CRT-010: Certificate Number Format Configuration
**Status:** 📐 Proposed (🆕 New in V2)
**Priority:** Medium
**Tables:** `crt_serial_counters`, `crt_certificate_types`

**Description:** Admins can configure the serial number format per certificate type. Format string supports tokens: `{TYPE_CODE}`, `{YYYY}`, `{YY}`, `{SEQ4}`, `{SEQ6}`. Counter resets annually. This replaces the hardcoded format from V1.

**Acceptance Criteria:**
- AC1: Default format: `{TYPE_CODE}-{YYYY}-{SEQ6}` producing `BON-2026-000001`.
- AC2: `crt_serial_counters` table maintains one row per `(certificate_type_id, year)` with `last_seq_no INT`.
- AC3: Increment operation uses `SELECT ... FOR UPDATE` to prevent race conditions in concurrent generation.
- AC4: Admin can preview the format with a sample output before saving.

---

### FR-CRT-011: Reports & Analytics
**Status:** 📐 Proposed
**Priority:** Medium
**Tables:** `crt_issued_certificates`, `crt_requests`

**Description:** Three report views: (1) Issued Certificates Register — filterable by type, date range, class/section, exportable to PDF and Excel. (2) Pending Requests — shows days-since-submission and required-by urgency. (3) Type Analytics — bar/pie chart of request volume by type, monthly trend.

**Acceptance Criteria:**
- AC1: Issued register export generates an Excel file using Laravel Excel or CSV via `fputcsv`.
- AC2: Pending report highlights overdue requests (required_by_date < today) in red.
- AC3: Analytics chart data served from a JSON endpoint; rendered client-side (Chart.js).
- AC4: All reports respect tenant scope; no cross-tenant data leakage.

---

### FR-CRT-012: Student & Parent Portal Access
**Status:** 📐 Proposed
**Priority:** High
**Tables:** `crt_requests`, `crt_issued_certificates`

**Description:** Students and parents access the certificate module through the portal to submit requests, track status, and download issued certificates. Portal views are simplified versions of the admin screens.

**Acceptance Criteria:**
- AC1: Portal shows only the requesting student's own requests and issued certificates.
- AC2: Student can submit a new request selecting from active certificate types marked as portal-eligible.
- AC3: Download is available only after certificate status = `issued` and `is_revoked = false`.
- AC4: Real-time status display for each request with timestamp per stage.

---

## 5. Data Model

### 5.1 New Tables (`crt_*` prefix) — All 📐 Proposed

| Table | Description | Key Columns |
|---|---|---|
| `crt_certificate_types` | Certificate type definitions | `id`, `name`, `code` UNIQUE, `category` ENUM, `requires_approval`, `validity_days`, `serial_format`, `is_active`, soft-delete |
| `crt_templates` | HTML/CSS certificate templates | `id`, `certificate_type_id` FK, `template_content` LONGTEXT, `variables_json` JSON, `page_size` ENUM, `orientation` ENUM, `is_default`, `signature_placement_json` JSON, soft-delete |
| `crt_template_versions` | Archived template snapshots | `id`, `template_id` FK, `version_no`, `template_content` LONGTEXT, `variables_json` JSON, `saved_by`, `saved_at` |
| `crt_requests` | Certificate requests (workflow) | `id`, `request_no` UNIQUE, `certificate_type_id` FK, `requester_type` ENUM, `requester_id`, `beneficiary_student_id` FK→std_students, `purpose`, `status` ENUM(6 states), `approved_by`, `approved_at`, `rejection_reason`, soft-delete |
| `crt_issued_certificates` | All issued certificates | `id`, `certificate_no` UNIQUE, `request_id` FK nullable, `certificate_type_id` FK, `recipient_type` ENUM, `recipient_id`, `template_id` FK, `issue_date`, `validity_date` nullable, `verification_hash` UNIQUE, `file_path`, `is_revoked`, `revoked_at`, `revocation_reason`, `is_duplicate`, soft-delete |
| `crt_tc_register` | Formal TC register (state board) | `id`, `sl_no` UNIQUE per year, `issued_certificate_id` FK, `student_name`, `father_name`, `class_at_leaving`, `date_of_admission`, `date_of_leaving`, `conduct`, `is_duplicate_entry`, `academic_year` |
| `crt_serial_counters` | Sequential number tracker per type/year | `id`, `certificate_type_id` FK, `academic_year` INT, `last_seq_no` INT DEFAULT 0, UNIQUE(`certificate_type_id`, `academic_year`) |
| `crt_bulk_jobs` | Async bulk generation job tracker | `id`, `certificate_type_id` FK, `initiated_by` FK, `filter_json` JSON, `total_count`, `processed_count`, `failed_count`, `status` ENUM(4), `zip_path`, `error_log_json` JSON, `started_at`, `completed_at` |
| `crt_id_card_configs` | ID card template configuration | `id`, `card_type` ENUM(student/staff), `name`, `academic_session_id`, `card_size` ENUM, `orientation` ENUM, `template_json` JSON, `cards_per_sheet`, soft-delete |
| `crt_student_documents` | Incoming student document DMS | `id`, `student_id` FK→std_students, `document_category_id` FK→sys_dropdown, `document_name`, `document_date`, `media_id` FK→sys_media, `verification_status` ENUM(3), `verification_remarks`, `verified_by`, `verified_at`, soft-delete |

### 5.2 Relationships

```
CertificateType
  ├── hasMany → CertificateTemplate      (one type, many templates)
  ├── hasOne  → CertificateTemplate (default)
  ├── hasMany → CertificateRequest
  ├── hasMany → CertificateIssued
  └── hasMany → SerialCounter

CertificateTemplate
  ├── belongsTo → CertificateType
  └── hasMany   → CertificateTemplateVersion

CertificateRequest
  ├── belongsTo → CertificateType
  ├── belongsTo → Student (beneficiary_student_id)
  └── hasOne    → CertificateIssued

CertificateIssued
  ├── belongsTo → CertificateType
  ├── belongsTo → CertificateTemplate
  ├── belongsTo → CertificateRequest (nullable)
  ├── hasOne    → TcRegister (when type=TC)
  └── hasMany   → VerificationLog

StudentDocument
  ├── belongsTo → Student
  └── morphOne  → sys_media (media_id)
```

### 5.3 Key Constraints & Indexes

| Table | Constraint | Detail |
|---|---|---|
| `crt_certificate_types` | UNIQUE `code` | Type codes must be unique across tenant |
| `crt_templates` | FK `certificate_type_id` ON DELETE CASCADE | Templates removed with type (soft) |
| `crt_issued_certificates` | UNIQUE `certificate_no` | No duplicate cert numbers |
| `crt_issued_certificates` | UNIQUE `verification_hash` | Hash must be unique for verification lookup |
| `crt_serial_counters` | UNIQUE (`certificate_type_id`, `academic_year`) | One counter per type per year |
| `crt_tc_register` | UNIQUE (`sl_no`, `academic_year`) | TC serial unique per year |
| `crt_requests` | INDEX (`beneficiary_student_id`, `certificate_type_id`, `status`) | Duplicate request check |

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (tenant.php — prefix: `certificate`, middleware: `auth, verified, tenant`)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | `/certificate/dashboard` | `CertificateTypeController@dashboard` | tenant | Module dashboard |
| GET | `/certificate/types` | `CertificateTypeController@index` | tenant | List all types |
| GET | `/certificate/types/create` | `CertificateTypeController@create` | tenant | Create type form |
| POST | `/certificate/types` | `CertificateTypeController@store` | tenant | Save new type |
| GET | `/certificate/types/{type}` | `CertificateTypeController@show` | tenant | Type detail |
| GET | `/certificate/types/{type}/edit` | `CertificateTypeController@edit` | tenant | Edit form |
| PUT | `/certificate/types/{type}` | `CertificateTypeController@update` | tenant | Update type |
| DELETE | `/certificate/types/{type}` | `CertificateTypeController@destroy` | tenant | Soft delete |
| GET | `/certificate/types/trashed` | `CertificateTypeController@trashed` | tenant | Trash list |
| PUT | `/certificate/types/{type}/restore` | `CertificateTypeController@restore` | tenant | Restore soft-deleted |
| DELETE | `/certificate/types/{type}/force-delete` | `CertificateTypeController@forceDelete` | tenant | Hard delete |
| PATCH | `/certificate/types/{type}/toggle` | `CertificateTypeController@toggleStatus` | tenant | Toggle is_active |
| GET | `/certificate/templates` | `CertificateTemplateController@index` | tenant | List templates |
| GET | `/certificate/templates/create` | `CertificateTemplateController@create` | tenant | Create template form |
| POST | `/certificate/templates` | `CertificateTemplateController@store` | tenant | Save template |
| GET | `/certificate/templates/{tpl}` | `CertificateTemplateController@show` | tenant | Template detail |
| GET | `/certificate/templates/{tpl}/edit` | `CertificateTemplateController@edit` | tenant | Edit form |
| PUT | `/certificate/templates/{tpl}` | `CertificateTemplateController@update` | tenant | Update (archives version) |
| DELETE | `/certificate/templates/{tpl}` | `CertificateTemplateController@destroy` | tenant | Soft delete |
| GET | `/certificate/templates/{tpl}/preview` | `CertificateTemplateController@preview` | tenant | Inline PDF preview |
| GET | `/certificate/templates/{tpl}/versions` | `CertificateTemplateController@versions` | tenant | Version history |
| POST | `/certificate/templates/{tpl}/restore-version/{v}` | `CertificateTemplateController@restoreVersion` | tenant | Restore old version |
| GET | `/certificate/requests` | `CertificateRequestController@index` | tenant | Request queue |
| GET | `/certificate/requests/create` | `CertificateRequestController@create` | tenant | Submit request form |
| POST | `/certificate/requests` | `CertificateRequestController@store` | tenant | Submit request |
| GET | `/certificate/requests/{req}` | `CertificateRequestController@show` | tenant | Request detail |
| POST | `/certificate/requests/{req}/approve` | `CertificateRequestController@approve` | tenant | Approve + trigger generation |
| POST | `/certificate/requests/{req}/reject` | `CertificateRequestController@reject` | tenant | Reject with reason |
| GET | `/certificate/issued` | `CertificateIssuedController@index` | tenant | Issued register |
| GET | `/certificate/issued/{cert}` | `CertificateIssuedController@show` | tenant | Certificate detail |
| GET | `/certificate/issued/{cert}/download` | `CertificateIssuedController@download` | tenant | Download PDF |
| POST | `/certificate/issued/{cert}/revoke` | `CertificateIssuedController@revoke` | tenant | Revoke certificate |
| GET | `/certificate/bulk-generate` | `BulkGenerationController@index` | tenant | Bulk generate form |
| POST | `/certificate/bulk-generate` | `BulkGenerationController@generate` | tenant | Dispatch bulk job |
| GET | `/certificate/bulk-generate/{job}/status` | `BulkGenerationController@status` | tenant | Poll job progress (JSON) |
| GET | `/certificate/bulk-generate/{job}/download` | `BulkGenerationController@download` | tenant | Download ZIP |
| GET | `/certificate/id-card-config` | `IdCardController@indexConfig` | tenant | List ID card configs |
| GET | `/certificate/id-card-config/create` | `IdCardController@createConfig` | tenant | Create config form |
| POST | `/certificate/id-card-config` | `IdCardController@storeConfig` | tenant | Save config |
| GET | `/certificate/id-card-config/{cfg}/edit` | `IdCardController@editConfig` | tenant | Edit config |
| PUT | `/certificate/id-card-config/{cfg}` | `IdCardController@updateConfig` | tenant | Update config |
| GET | `/certificate/id-cards/generate` | `IdCardController@generateForm` | tenant | Generate form |
| POST | `/certificate/id-cards/generate` | `IdCardController@generate` | tenant | Generate ID card PDF |
| PATCH | `/certificate/id-cards/{issued}/received` | `IdCardController@markReceived` | tenant | Mark card as handed over |
| GET | `/certificate/documents` | `DocumentManagementController@index` | tenant | DMS document list |
| POST | `/certificate/documents/upload` | `DocumentManagementController@upload` | tenant | Upload document |
| GET | `/certificate/documents/{doc}` | `DocumentManagementController@show` | tenant | View document |
| POST | `/certificate/documents/{doc}/verify` | `DocumentManagementController@verify` | tenant | Verify/reject document |
| GET | `/certificate/documents/{doc}/download` | `DocumentManagementController@download` | tenant | Download document |
| GET | `/certificate/verification-logs` | `VerificationController@logs` | tenant | Admin verification log |
| GET | `/certificate/tc-register` | `CertificateIssuedController@tcRegister` | tenant | View/print TC register |
| GET | `/certificate/reports/issued` | `CertificateReportController@issued` | tenant | Issued certificates report |
| GET | `/certificate/reports/pending` | `CertificateReportController@pending` | tenant | Pending requests report |
| GET | `/certificate/reports/analytics` | `CertificateReportController@analytics` | tenant | Type analytics chart |

### 6.2 Public Routes (no auth required)

| Method | URI | Controller@Method | Description |
|---|---|---|---|
| GET | `/verify/{hash}` | `VerificationController@verify` | Public QR code verification page |

### 6.3 API Routes (api.php)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | `/api/v1/certificate/verify` | `Api\CertificateVerifyController@verify` | API key (query param) | Third-party JSON verification |

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Description |
|---|---|---|---|
| CRT-S01 | Certificate Dashboard | `certificate.dashboard` | Stats tiles: pending, issued today, expiring soon; quick links |
| CRT-S02 | Certificate Types — Index | `certificate.types.index` | Paginated table with search; requires_approval badge |
| CRT-S03 | Certificate Types — Form | `certificate.types.create/edit` | Form: name, code, category, validity, serial format, approval flag |
| CRT-S04 | Templates — Index | `certificate.templates.index` | Grouped by certificate type; default badge |
| CRT-S05 | Template Designer | `certificate.templates.create/edit` | HTML/CSS textarea + variable chip list + live preview pane |
| CRT-S06 | Template Preview | `certificate.templates.preview` | Inline `<embed>` PDF with dummy student data |
| CRT-S07 | Template Version History | `certificate.templates.versions` | Timeline of versions; Restore button per version |
| CRT-S08 | Requests — Index | `certificate.requests.index` | Tabs: Pending / Under Review / All; urgency badge |
| CRT-S09 | Request — Create | `certificate.requests.create` | Step form: select type → student → purpose → attach docs |
| CRT-S10 | Request — Review | `certificate.requests.show` | Student panel + attached docs + Approve / Reject actions |
| CRT-S11 | Issued Register | `certificate.issued.index` | Searchable/filterable; Download and Revoke per row |
| CRT-S12 | Issued Certificate Detail | `certificate.issued.show` | Full metadata + embedded QR preview + download link |
| CRT-S13 | Bulk Generation | `certificate.bulk-generate.index` | Class/section picker + progress bar polling status endpoint |
| CRT-S14 | ID Card Config — List | `certificate.id-card-config.index` | List by card_type; Preview button |
| CRT-S15 | ID Card Config — Form | `certificate.id-card-config.create` | Layout editor: field positions, colors, QR placement |
| CRT-S16 | Generate ID Cards | `certificate.id-cards.generate` | Filter form → download printable PDF sheet |
| CRT-S17 | DMS — Document List | `certificate.documents.index` | Student search → document list with verification badges |
| CRT-S18 | DMS — Upload | `certificate.documents.upload` | Drag-and-drop upload + category picker |
| CRT-S19 | DMS — Document View | `certificate.documents.show` | Inline PDF/image viewer + Verify/Reject actions |
| CRT-S20 | Verification Logs | `certificate.verification-logs` | Paginated log; filter by method, date, result |
| CRT-S21 | TC Register | `certificate.tc-register` | Formal printable register table; print button |
| CRT-S22 | Report — Issued Certificates | `certificate.reports.issued` | Filter + export table (PDF/Excel) |
| CRT-S23 | Report — Pending Requests | `certificate.reports.pending` | Overdue highlighted red; sorted by required_by_date |
| CRT-S24 | Report — Type Analytics | `certificate.reports.analytics` | Chart.js bar (monthly) + pie (by type) |
| CRT-S25 | Public Verification Page | `certificate.verify.public` | No-login; VALID/EXPIRED/REVOKED banner + minimal details |
| CRT-S26 | Portal — My Certificates | `portal.certificate.index` | Student portal: own requests + issued certs + download links |

---

## 8. Business Rules

| Rule ID | Rule | Enforcement Point |
|---|---|---|
| BR-CRT-001 | TC cannot be generated if student has outstanding fee dues unless admin records override justification | `CertificateGenerationService::generateTC()` + policy |
| BR-CRT-002 | TC serial number (`crt_tc_register.sl_no`) must be sequential, year-wise; gaps not allowed | `SerialCounter::nextForType()` with `SELECT FOR UPDATE` |
| BR-CRT-003 | Second issuance to same recipient = `is_duplicate = true` with "DUPLICATE COPY" watermark in PDF | `CertificateIssuedController::store()` |
| BR-CRT-004 | Certificate number unique per tenant; format `{TYPE_CODE}-{YYYY}-{SEQ}` | UNIQUE index + `SerialCounter` lock |
| BR-CRT-005 | Revoked certificates remain in DB; verification returns REVOKED status, not 404 | `QrVerificationService::verifyHash()` |
| BR-CRT-006 | Templates with referenced issued certificates cannot be hard-deleted | FK `ON DELETE RESTRICT` on `crt_issued_certificates.template_id` |
| BR-CRT-007 | ID cards must display blood group when present in `std_profiles`; blank field (not hidden) when absent | `IdCardController::generate()` |
| BR-CRT-008 | DMS documents with `verification_status = rejected` cannot satisfy certificate eligibility checks | `CertificateRequestController::store()` validation |
| BR-CRT-009 | Bulk generation exceeding 200 certificates must use the queue; synchronous forbidden above threshold | `BulkGenerationController::generate()` count check |
| BR-CRT-010 | Public verification endpoint must not expose full student name, DOB, class, or address | `VerificationController::verify()` response DTO |
| BR-CRT-011 | Once TC issued: `std_students.tc_issued = true`; student status transitions to `withdrawn` | Post-hook in `CertificateGenerationService` |
| BR-CRT-012 | Only one template per certificate type may have `is_default = true` at any time | Toggle logic in `CertificateTemplateController` |
| BR-CRT-013 | Rejection requires `rejection_reason` (NOT NULL); validated in FormRequest | `RejectRequestRequest` FormRequest |
| BR-CRT-014 | Supporting documents stored in `sys_media` with `model_type = CertificateRequest` | Polymorphic upload |
| BR-CRT-015 | Serial counter increment uses `SELECT ... FOR UPDATE` in a DB transaction | `SerialCounter::increment()` |

---

## 9. Workflow Diagrams (FSM Descriptions)

### 9.1 Certificate Request Lifecycle

```
[SUBMITTED by student/parent/clerk]
  → status = 'pending'
  → if requires_approval = false → auto-advance to APPROVED

[PENDING] → admin opens record → status = 'under_review'

[UNDER_REVIEW]
  → approve → status = 'approved' → CertificateGenerationService fired
  → reject  → status = 'rejected' [TERMINAL — rejection_reason required]

[APPROVED]
  → generation succeeds → status = 'generated'; crt_issued_certificates created
  → generation fails    → status stays 'approved'; error logged; admin retries

[GENERATED] → admin records handover → status = 'issued' [TERMINAL — positive]
```

### 9.2 Certificate Generation (Direct / Bulk)

```
Admin selects type + students
  → CertificateGenerationService::generateDirect()
  → Resolve merge fields (std_students, sch_academic_sessions)
  → SerialCounter::nextForType() [SELECT FOR UPDATE]
  → QrVerificationService::generateQrCode()
  → DomPDF renders HTML template
  → Store PDF: storage/tenant_{id}/certificates/{type}/{YYYY}/
  → Write crt_issued_certificates (verification_hash = HMAC-SHA256)
  → If TC: write crt_tc_register + update std_students.tc_issued
  → Notify requester (if request-based) via NTF module
```

### 9.3 QR Verification Flow

```
Third party scans QR → /verify/{hash}
  → Lookup crt_issued_certificates WHERE verification_hash = {hash}
    → not found: log(not_found) → NOT FOUND page
    → found:
        is_revoked? → REVOKED
        validity_date < today? → EXPIRED
        else → VALID
  → Log to crt_verification_logs (IP, agent, method=qr, result)
  → Render public.blade.php — minimal info only (BR-CRT-010)
```

### 9.4 Bulk Generation Job FSM

```
[QUEUED] → worker picks up → [PROCESSING]
[PROCESSING]
  → per student: generate PDF → processed_count++
  → individual failure: failed_count++; log to error_log_json
  → all done: create ZIP → [COMPLETED]
  → fatal error: [FAILED]
[COMPLETED] → download link shown to admin
[FAILED]    → admin notified; retry option offered
```

---

## 10. Non-Functional Requirements

| Category | Requirement | Target | Notes |
|---|---|---|---|
| Performance | Single PDF generation time | < 3 seconds | DomPDF single-page certificate with embedded QR |
| Performance | Bulk generation throughput | > 50 certificates/minute | Via queue worker; configurable worker concurrency |
| Performance | Public verification endpoint response | < 500 ms | Simple hash lookup + log insert |
| Performance | Page load (admin certificate list) | < 2 seconds | Paginated; eager-load type + recipient |
| Storage | Tenant-isolated file paths | `storage/tenant_{id}/certificates/` | stancl/tenancy disk configuration |
| Storage | PDF quality | 150 DPI minimum | DomPDF `dpi` config key |
| Storage | Max DMS file size | 5 MB per document | Validated in `DocumentUploadRequest` |
| Security | Verification hash algorithm | HMAC-SHA256 | Key = APP_KEY; immutable field binding |
| Security | Third-party API authentication | API key in query param | Key stored hashed; rate-limited (60 req/min) |
| Security | Certificate PDF access | Authorised users only; signed URL for downloads | Laravel `Storage::temporaryUrl()` or signed route |
| Security | Public verification privacy | Only first name + last initial + school name exposed | BR-CRT-010 |
| Reliability | Bulk job failure handling | Individual failures logged; batch continues | `error_log_json` in `crt_bulk_jobs` |
| Maintainability | Soft deletes | All tables support `deleted_at` | Standard platform pattern |
| Maintainability | Audit trail | All data changes logged via `sys_activity_logs` | Standard platform pattern |
| Scalability | Queue-based bulk processing | Required for > 200 certs | Laravel Horizon or Redis queue |
| Compatibility | PDF rendering | A4 portrait/landscape, A5, letter, custom page sizes | DomPDF page-size config |
| Localisation | Certificate content | UTF-8 (Hindi, Marathi, Tamil names supported) | utf8mb4 + DomPDF Unicode font |

---

## 11. Module Dependencies

### 11.1 Internal Dependencies (reads from)

| Module | Prefix | Data Used | Usage |
|---|---|---|---|
| Student Management | `std_*` | `std_students`, `std_profiles` | Name, DOB, photo, class, section, admission_no, blood_group, tc_issued flag |
| Academic Setup | `sch_*` | `sch_academic_sessions`, `sch_classes`, `sch_sections` | Session names, class/section labels for merge fields |
| Finance / Fees | `fin_*` | Fee outstanding amount | TC issuance eligibility check (BR-CRT-001) |
| System Media | `sys_media` | Polymorphic file store | Logo, seal, student photos for templates; DMS document storage |
| System Dropdown | `sys_dropdown_table` | Document categories | DMS category select list |
| System Users | `sys_users` | `approved_by`, `issued_by`, `verified_by` | FK references throughout |

### 11.2 Internal Dependencies (triggers / writes to)

| Module | Interaction | Trigger |
|---|---|---|
| Notification System | Outbound — email/SMS | On request submission, approval, rejection |
| Student Management | Write `std_students.tc_issued = true` | On TC generation |
| Audit Log | Write `sys_activity_logs` | On every data-changing action |

### 11.3 External Package Dependencies

| Package | Version | Purpose | Already Installed |
|---|---|---|---|
| `barryvdh/laravel-dompdf` | v3.1 | PDF generation for certificates and ID cards | Yes (via HPC module) |
| `simplesoftwareio/simple-qrcode` | v4.2 | QR code generation | Yes (via Transport module) |
| `stancl/tenancy` | v3.9 | Tenant isolation and scoped disk paths | Yes (platform-wide) |
| `nwidart/laravel-modules` | v12 | Module scaffolding | Yes (platform-wide) |
| Laravel Queue | Built-in | Async bulk generation via `BulkGenerateCertificatesJob` | Yes |
| `maatwebsite/excel` | v3.x | Excel export for reports | Verify installation |

### 11.4 Dependencies On CRT (downstream)

| Module | Usage |
|---|---|
| Student Portal | Display and download certificates issued to student |
| Parent Portal | Request certificates and download for ward |

---

## 12. Test Scenarios

| # | Test Case | Type | FR / BR Ref | Priority |
|---|---|---|---|---|
| T01 | Create certificate type with unique code → appears in list | Browser | FR-CRT-001 | High |
| T02 | Create type with duplicate code → validation error | Feature | FR-CRT-001 | High |
| T03 | Design template with all merge fields; preview PDF renders correctly with dummy data | Browser | FR-CRT-002 | High |
| T04 | Update template → previous version archived in `crt_template_versions` with incremented version_no | Feature | FR-CRT-002 | High |
| T05 | Restore old template version → content matches archived snapshot | Feature | FR-CRT-002 | Medium |
| T06 | Mark template as default → previous default is auto-unset | Feature | BR-CRT-012 | Medium |
| T07 | Submit Bonafide request → admin approves → PDF generated with correct merge fields (name, class, session) | Feature | FR-CRT-003, FR-CRT-004 | High |
| T08 | Duplicate pending request for same student + type → blocked with validation error | Feature | FR-CRT-003 | High |
| T09 | QR code on generated certificate resolves to valid public verification page | Feature | FR-CRT-007 | High |
| T10 | Revoked certificate shows REVOKED on public verification page | Feature | FR-CRT-007, BR-CRT-005 | High |
| T11 | Public verification page does not expose full name, DOB, or class section | Feature | BR-CRT-010 | High |
| T12 | TC generation blocked when `fin_fee_dues > 0`; unblocked with admin override justification | Feature | FR-CRT-005, BR-CRT-001 | High |
| T13 | TC register sl_no increments sequentially; no gaps within academic year | Unit | FR-CRT-005, BR-CRT-002 | High |
| T14 | TC issued → `std_students.tc_issued = true` and status = withdrawn | Feature | BR-CRT-011 | High |
| T15 | Bulk generation for 50 students dispatched to queue; ZIP downloadable on completion | Feature | FR-CRT-006 | High |
| T16 | Bulk generation for 201+ students → dispatched to queue (not synchronous) | Feature | BR-CRT-009 | Medium |
| T17 | Individual PDF failure in bulk job → other students still succeed; failure logged in error_log_json | Feature | FR-CRT-006 | Medium |
| T18 | ID card generated with student photo embedded; blood group shown when available | Browser | FR-CRT-008, BR-CRT-007 | Medium |
| T19 | ID card handover marked as received → date and user logged | Feature | FR-CRT-008 | Low |
| T20 | DMS document upload (PDF and image); category selectable from dropdown | Browser | FR-CRT-009 | Medium |
| T21 | DMS document verification status updated (verified/rejected); rejection requires remarks | Feature | FR-CRT-009, BR-CRT-008 | Medium |
| T22 | Rejected DMS document cannot satisfy TC eligibility check | Feature | BR-CRT-008 | Medium |
| T23 | Third-party API `/api/v1/certificate/verify` returns correct JSON for valid hash | Feature | FR-CRT-007 | Medium |
| T24 | Third-party API called without valid api_key → HTTP 401 response | Feature | FR-CRT-007 | High |
| T25 | Second certificate issuance to same student → `is_duplicate = true` + "DUPLICATE COPY" watermark | Feature | BR-CRT-003 | Medium |
| T26 | Issued register export generates valid Excel file with correct columns | Feature | FR-CRT-011 | Low |
| T27 | Serial counter uses SELECT FOR UPDATE — concurrent generation produces unique sequential numbers | Unit | BR-CRT-015 | High |
| T28 | Analytics chart data endpoint returns correct JSON structure | Feature | FR-CRT-011 | Low |
| T29 | Student portal shows only own certificates; cannot view other students' records | Feature | FR-CRT-012 | High |
| T30 | Download of revoked certificate is blocked for all roles | Feature | BR-CRT-005 | High |

---

## 13. Glossary

| Term | Definition |
|---|---|
| TC | Transfer Certificate — a legally mandated document issued when a student leaves the school |
| Bonafide Certificate | Proof of current enrollment issued to a student; required by banks, embassies, and government offices |
| Character Certificate | A certificate attesting to the student's character and conduct during their period of study |
| Migration Certificate | Certificate allowing a student to migrate from one education board to another |
| Verification Hash | HMAC-SHA256 computed from immutable certificate fields; used to prove authenticity without storing the certificate centrally |
| DMS | Document Management System — the sub-module for uploading and managing incoming student documents |
| Merge Field | A placeholder variable (e.g., `{{student_name}}`) in a template that is replaced with real data at generation time |
| Serial Counter | A per-type, per-year counter that ensures sequential, gap-free certificate numbers |
| Bulk Job | An asynchronous queue job (`BulkGenerateCertificatesJob`) that generates certificates for many students |
| CR80 | Standard credit card size (85.6 × 54 mm); used for student/staff ID cards |
| DomPDF | PHP PDF rendering library (`barryvdh/laravel-dompdf`) used to convert HTML templates to PDF |
| is_duplicate | Flag on `crt_issued_certificates` indicating this is a re-issued copy of a previously issued certificate |
| TC Register | A formal sequential logbook of all issued Transfer Certificates, as mandated by Indian state education boards |
| API Key | A secret key issued to a third-party institution allowing programmatic certificate verification |
| Revocation | Admin action that marks a certificate as invalid without deleting it; verification returns REVOKED |

---

## 14. Suggestions & Improvements

| # | Suggestion | Rationale | Priority |
|---|---|---|---|
| S01 | **DigiLocker Integration stub** — Add a `digilocker_sync` column on `crt_issued_certificates` and a stub API endpoint for future integration with India's national document wallet | Many government offices now accept DigiLocker documents; stubs are cheap to add now | Medium |
| S02 | **Configurable serial number format per type** — Allow admin to set `{TYPE_CODE}-{YYYY}-{SEQ4}` vs `{TYPE_CODE}-{YY}-{SEQ6}` per type | Different boards expect different TC numbering formats; V1 hardcoded format | High |
| S03 | **Template marketplace / seed templates** — Ship 5 pre-built templates (Bonafide, TC government format, Character, Sports landscape, ID card CR80) as database seeders | Reduces time-to-value for new schools; no blank canvas | High |
| S04 | **E-signature placeholder support** — Reserve a `signature_placement_json` field in `crt_templates` to define coordinates for a digital signature image or DSC-stamp block | Schools are increasingly using digital signatures on documents; field costs nothing to add now | Medium |
| S05 | **Certificate expiry notification** — Schedule a daily job to identify certificates approaching `validity_date` (within 30 days) and notify the student/admin via the NTF module | Bonafide certificates issued to embassies expire; proactive reminder prevents issues | Low |
| S06 | **QR verification rate limiting** — Apply rate limiting (e.g., 20 verifications per IP per hour) on the public `/verify/{hash}` endpoint to prevent scraping attacks | Hash enumeration attacks could expose validity of bulk-generated certs | High |
| S07 | **Duplicate request auto-link** — When a duplicate certificate request is submitted, auto-link it to the original issued certificate to surface the original easily | Admin workflow improvement; reduces confusion | Medium |
| S08 | **Print-ready ID card sheet preview** — Provide a browser-preview of the card grid before committing to PDF generation | Prevents wasted A4 sheets due to layout errors | Medium |
| S09 | **State-board-specific TC format templates** — Seed templates for CBSE, ICSE, and major state boards (Maharashtra, Karnataka, Tamil Nadu) with their prescribed TC field order | TC format compliance is mandatory; each board differs | High |
| S10 | **Bulk DMS upload via ZIP** — Allow staff to upload a ZIP of student documents with a CSV mapping (filename → student_id, category) | Reduces time for annual batch admissions where 500+ documents are collected | Low |

---

## 15. Appendices

### 15.1 Merge Field Reference

| Merge Field | Source Table | Column | Notes |
|---|---|---|---|
| `{{student_name}}` | `std_students` | `full_name` | Full legal name |
| `{{father_name}}` | `std_profiles` | `father_name` | Father / guardian name |
| `{{mother_name}}` | `std_profiles` | `mother_name` | Mother name |
| `{{dob}}` | `std_students` | `dob` | Formatted per school locale |
| `{{admission_no}}` | `std_students` | `admission_no` | School-assigned ID |
| `{{class_section}}` | `sch_classes`, `sch_sections` | `name` | e.g., "Grade 10 — A" |
| `{{academic_session}}` | `sch_academic_sessions` | `name` | e.g., "2025–2026" |
| `{{date_of_admission}}` | `std_students` | `admission_date` | |
| `{{nationality}}` | `std_profiles` | `nationality` | Default: "Indian" |
| `{{religion}}` | `std_profiles` | `religion` | |
| `{{blood_group}}` | `std_profiles` | `blood_group` | |
| `{{certificate_no}}` | `crt_issued_certificates` | `certificate_no` | Auto-generated |
| `{{issue_date}}` | `crt_issued_certificates` | `issue_date` | Formatted date |
| `{{validity_date}}` | `crt_issued_certificates` | `validity_date` | "No Expiry" when NULL |
| `{{principal_name}}` | `sch_school_profiles` | `principal_name` | |
| `{{school_name}}` | `sch_school_profiles` | `school_name` | |
| `{{school_address}}` | `sch_school_profiles` | `address` | Multi-line |
| `{{purpose}}` | `crt_requests` | `purpose` | e.g., "Bank account opening" |
| `{{qr_code}}` | Generated | base64 PNG | Embedded as `<img src="data:image/png;base64,…">` |

### 15.2 Certificate Number Format Tokens

| Token | Expands To | Example |
|---|---|---|
| `{TYPE_CODE}` | Certificate type code | `BON` |
| `{YYYY}` | 4-digit academic year | `2026` |
| `{YY}` | 2-digit year | `26` |
| `{SEQ4}` | 4-digit zero-padded sequence | `0042` |
| `{SEQ6}` | 6-digit zero-padded sequence | `000042` |

Default format: `{TYPE_CODE}-{YYYY}-{SEQ6}` → `BON-2026-000042`

### 15.3 Proposed Service Method Signatures

**`CertificateGenerationService`**
```php
generateFromRequest(CertificateRequest $request): CertificateIssued
generateDirect(CertificateType $type, int $recipientId, array $extraFields = []): CertificateIssued
generateTC(CertificateRequest $request, array $tcData): CertificateIssued
resolveMergeFields(int $studentId, array $extra = []): array
generateCertificateNo(CertificateType $type): string
```

**`QrVerificationService`**
```php
generateVerificationHash(CertificateIssued $cert): string
generateQrCode(string $verificationUrl): string  // returns base64 PNG
verifyHash(string $hash): array  // {valid, certificate, result, logged}
```

**`DmsService`**
```php
uploadDocument(int $studentId, UploadedFile $file, array $meta): StudentDocument
verifyDocument(StudentDocument $doc, string $status, string $remarks, int $verifierId): void
getDocumentsByStudent(int $studentId): Collection
hasVerifiedDocument(int $studentId, string $categoryCode): bool
```

---

## 16. V1 → V2 Delta

| Section | V1 (2026-03-25) | V2 Change | Type |
|---|---|---|---|
| Certificate Types | Category ENUM: student/staff/achievement | Added configurable `serial_format` column per type | 🆕 New column |
| Templates | Basic page_size + orientation | Added `signature_placement_json` column for digital signature block coordinates | 🆕 New column |
| Tables | 8 tables proposed | 10 tables — added `crt_tc_register` and `crt_bulk_jobs` as explicit formal tables | 🆕 New tables |
| Serial Numbers | Hardcoded format `BON-YYYY-000001` | Configurable per type via format token string; FR-CRT-010 added | 📐 New FR |
| TC Register | Mentioned as a concept inside FR-CRT-003 | Formalised as own FR-CRT-005 with dedicated `crt_tc_register` table and all state-board fields | 📐 Expanded |
| Achievement Certs | Covered inside FR-CRT-005 | Separated into FR-CRT-006; bulk job tracking via `crt_bulk_jobs` table made explicit | 📐 Restructured |
| Bulk Jobs | `crt_bulk_jobs` mentioned but not fully specified | Full table definition with `error_log_json`, `started_at`, `completed_at`; bulk FSM documented | 📐 Expanded |
| FR Count | 12 FRs | 12 FRs (restructured; FR-CRT-010 is new serial-number config FR) | Restructured |
| Business Rules | 10 rules | 15 rules — added BR-CRT-011 (TC flag on student), BR-CRT-012 (one default template), BR-CRT-013 (rejection reason), BR-CRT-014 (polymorphic docs), BR-CRT-015 (SELECT FOR UPDATE) | 🆕 New rules |
| Routes | ~55 routes mentioned in text | 58 web + 1 public + 1 API; formatted as table with Method/URI/Controller/Auth/Description | Reformatted |
| Screens | 29 view files listed | 26 screen entries in structured table (consolidated config forms) | Reformatted |
| Test Cases | 15 test cases | 30 test cases (T01–T30) with FR/BR cross-reference | Expanded |
| Suggestions | Not present in V1 | 10 suggestions added (S01–S10) covering DigiLocker, rate limiting, state-board templates, etc. | 🆕 New section |
| Appendices | Not present in V1 | Added merge field reference, serial token table, service method signatures | 🆕 New section |
| Mode | RBS_ONLY / all ❌ Not Started | All FRs re-marked as 📐 Proposed (consistent V2 convention) | Convention fix |
