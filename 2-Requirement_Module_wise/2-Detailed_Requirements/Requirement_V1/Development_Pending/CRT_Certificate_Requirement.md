# Certificate Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** CRT | **Module Path:** `Modules/Certificate`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `crt_*` | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module R — Certificates & Identity Management (lines 3640-3754)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The Certificate module provides a comprehensive, end-to-end certificate lifecycle management system for Indian K-12 schools on the Prime-AI platform. It handles the creation, approval, generation, issuance, and digital verification of all school-issued certificates — from common administrative documents (Bonafide, Transfer Certificate, Character Certificate) to achievement awards, ID cards, and document management. Every issued certificate carries a cryptographic verification hash and QR code that enables third-party institutions to authenticate certificates without contacting the school directly.

### 1.2 Scope

This module covers:
- Dynamic template engine (header/body/footer, merge fields, logo/seal upload, fonts, QR placement, version control)
- Seven certificate type categories: Bonafide, Transfer Certificate (TC), Character, Study/Conduct, Sports, Achievement, and custom
- Student document management system (DMS) — upload, categorise, verify, access-control
- ID card design and bulk generation for students and staff with QR/barcode support
- Certificate request workflow: student/parent submits → admin reviews → approves/rejects → auto-generates PDF (DomPDF) → issues
- Digital verification: QR-encoded URL + HMAC hash; public verification endpoint (no login required); API for third-party checks
- Bulk generation: class/section/batch download as ZIP
- Reports: issued certificates register, pending requests, type-wise analytics

Out of scope for this version: integration with DigiLocker/CBSE verification APIs, e-signature via DSC tokens (digital signature certificate via USB dongle), mobile app barcode scanning (API stubs only).

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.R*) | 14 (R1–R7) |
| RBS Tasks | 22 |
| RBS Sub-tasks | 52 |
| Proposed DB Tables (crt_*) | 8 |
| Proposed Named Routes | ~55 |
| Proposed Blade Views | ~35 |
| Proposed Controllers | 8 |
| Proposed Models | 8 |
| Proposed Services | 3 |
| Proposed Jobs | 1 (bulk generation) |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 8 tables proposed |
| Models | ❌ Not Started | 8 models proposed |
| Controllers | ❌ Not Started | 8 controllers proposed |
| Services | ❌ Not Started | CertificateGenerationService, QrVerificationService, DmsService |
| Blade Views | ❌ Not Started | ~35 views proposed |
| PDF Generation | ❌ Not Started | DomPDF v3.1 (already installed via HPC module) |
| QR Code | ❌ Not Started | SimpleSoftwareIO QR v4.2 (already installed via Transport module) |
| Routes | ❌ Not Started | tenant.php additions required |
| Tests | ❌ Not Started | Browser + Feature tests proposed |

**Overall Implementation: 0% — Greenfield**

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian schools generate a high volume of certificates throughout the academic year. Bonafide certificates are required by banks, embassies, and government offices as proof of enrollment. Transfer Certificates (TCs) are legally mandated documents issued when a student leaves school, and many state boards require them to follow a government-prescribed format. Character certificates are required for competitive exam applications. Sports and achievement certificates motivate students and are expected by parents.

Without a dedicated module, schools print these on ad-hoc Word/PDF templates — leading to inconsistency, no tracking, no verification capability, and easy forgery. The Certificate module solves this by:

1. **Standardising templates** — school admins design once, the system fills merge fields automatically.
2. **Enforcing workflow** — requests go through an approval gate; only approved requests generate a PDF.
3. **Creating an audit trail** — every issued certificate has a unique serial number, issue date, issuing authority, and a tamper-evident hash.
4. **Enabling digital verification** — any third party can scan the QR code or call the API to confirm authenticity.
5. **Centralising documents** — the DMS stores all incoming student documents (birth certificate, previous TC, migration certificate) with verification status.

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Template Management | Dynamic templates with merge fields, version control, logo/seal | F.R1.1, F.R1.2 | ❌ Not Started |
| Bonafide Certificate | Most-issued cert; auto-fills enrollment details | FR-CRT-002 | ❌ Not Started |
| Transfer Certificate (TC) | Government-format TC with serial register | FR-CRT-003 | ❌ Not Started |
| Character Certificate | Character/conduct attestation | FR-CRT-004 | ❌ Not Started |
| Sports/Achievement Cert | Award-style certificates with custom wording | FR-CRT-005 | ❌ Not Started |
| Study/Conduct Certificate | General purpose study/behaviour attestation | FR-CRT-006 | ❌ Not Started |
| Request Workflow | Student/parent submits → admin approves → PDF generated | F.R2.1, F.R2.2 | ❌ Not Started |
| Certificate Issuance | Print, record issue, track handover | F.R3.1, F.R3.2 | ❌ Not Started |
| Bulk Generation | Generate for entire class/batch; download as ZIP | ST.R3.1.2 | ❌ Not Started |
| ID Card Generation | Student + staff ID cards with photo + QR code | F.R5.1, F.R5.2 | ❌ Not Started |
| Document Management System | Upload, categorise, verify incoming student docs | F.R4.1, F.R4.2 | ❌ Not Started |
| QR Verification | Public endpoint to verify issued certificates | F.R6.1 | ❌ Not Started |
| Third-Party API | API key secured verification endpoint | F.R6.2 | ❌ Not Started |
| Reports & Analytics | Issued register, pending queue, type analytics | F.R7.1, F.R7.2 | ❌ Not Started |

### 2.3 Menu Navigation Path

```
School Admin Panel
└── Certificate [/certificate]
    ├── Dashboard              [/certificate/dashboard]
    ├── Template Management
    │   ├── Certificate Types  [/certificate/types]
    │   └── Templates          [/certificate/templates]
    ├── Certificates
    │   ├── Requests           [/certificate/requests]
    │   ├── Issued Register    [/certificate/issued]
    │   └── Bulk Generation    [/certificate/bulk-generate]
    ├── ID Cards
    │   ├── ID Card Config     [/certificate/id-card-config]
    │   └── Generate ID Cards  [/certificate/id-cards/generate]
    ├── Document Management
    │   ├── Upload Documents   [/certificate/documents/upload]
    │   └── Verify Documents   [/certificate/documents/verify]
    ├── Verification
    │   └── Verification Logs  [/certificate/verification-logs]
    └── Reports
        ├── Issued Certificates  [/certificate/reports/issued]
        ├── Pending Requests     [/certificate/reports/pending]
        └── Type Analytics       [/certificate/reports/analytics]
```

### 2.4 Proposed Module Architecture

```
Modules/Certificate/
├── app/
│   ├── Http/Controllers/
│   │   ├── CertificateTypeController.php        # CRUD for certificate types
│   │   ├── CertificateTemplateController.php    # CRUD + preview + version restore
│   │   ├── CertificateRequestController.php     # Request workflow (submit/review/approve/reject)
│   │   ├── CertificateIssuedController.php      # Issued register + PDF download
│   │   ├── BulkGenerationController.php         # Bulk generate + ZIP download
│   │   ├── IdCardController.php                 # ID card config + generation
│   │   ├── DocumentManagementController.php     # DMS upload + verify
│   │   ├── VerificationController.php           # Public QR verify + verification logs
│   │   └── CertificateReportController.php      # All reports
│   ├── Jobs/
│   │   └── BulkGenerateCertificatesJob.php      # Queued bulk PDF generation
│   ├── Models/
│   │   ├── CertificateType.php
│   │   ├── CertificateTemplate.php
│   │   ├── CertificateRequest.php
│   │   ├── CertificateIssued.php
│   │   ├── CertificateVerificationLog.php
│   │   ├── IdCardConfig.php
│   │   ├── StudentDocument.php
│   │   └── DocumentVerification.php
│   ├── Policies/ (8 policies)
│   ├── Providers/
│   │   ├── CertificateServiceProvider.php
│   │   └── RouteServiceProvider.php
│   └── Services/
│       ├── CertificateGenerationService.php     # PDF generation via DomPDF
│       ├── QrVerificationService.php            # QR generation + hash verification
│       └── DmsService.php                       # Document upload + verification
├── database/migrations/ (8 migrations)
├── resources/
│   ├── views/certificate/
│   │   ├── dashboard.blade.php
│   │   ├── types/           # create, edit, index, show, trash
│   │   ├── templates/       # create, edit, index, show, trash, preview
│   │   ├── requests/        # create, index, show, review, trash
│   │   ├── issued/          # index, show
│   │   ├── bulk/            # index (form), progress
│   │   ├── id-cards/        # config-create, config-edit, config-index, generate, preview
│   │   ├── documents/       # upload, index, verify, show
│   │   └── verification/    # public-verify, logs-index
│   └── views/reports/certificate/
│       ├── issued.blade.php
│       ├── pending.blade.php
│       └── analytics.blade.php
└── routes/
    ├── api.php              # Verification API endpoints
    └── web.php
```

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role in Certificate Module | Permissions |
|---|---|---|
| School Admin | Full access: configure types/templates, approve requests, issue certificates, manage DMS | All permissions |
| Principal | Approve/reject requests, sign (digital authority on template), view all issued | view, approve, reject |
| Clerk / Front Office Staff | Submit requests on behalf of students, record issuance, manage DMS uploads | create-request, issue, dms.upload |
| Teacher (Class Teacher) | View certificates issued to their students | view (own class only) |
| Student | Submit certificate request via student portal; view own issued certificates | create-request (own), view (own) |
| Parent | Submit certificate request via portal on behalf of ward | create-request (ward), view (ward) |
| Third Party / External | Scan QR code to verify certificate authenticity (no login required) | public endpoint |
| System | Auto-generates certificate number, sends notifications, queues bulk jobs | system actor |

---

## 4. FUNCTIONAL REQUIREMENTS

---

### FR-CRT-001: Certificate Template Management

**RBS Reference:** F.R1.1 — Template Creation, F.R1.2 — Template Management
**Priority:** 🔴 Critical (prerequisite for all certificate generation)
**Status:** ❌ Not Started
**Table(s):** `crt_certificate_types`, `crt_templates`, `crt_template_versions`

#### Requirements

**REQ-CRT-001.1: Create Certificate Type**
| Attribute | Detail |
|---|---|
| Description | Admin defines a named certificate type (e.g., "Bonafide Certificate") with a category, default validity, and approval requirement flag |
| Actors | School Admin |
| Preconditions | Authenticated with `tenant.certificate-type.create` permission |
| Input | name (required, max 150), code (required, unique, max 20), category ENUM('student','staff','achievement'), description (optional), requires_approval TINYINT(1) DEFAULT 1, validity_days INT NULL (NULL = no expiry), is_active |
| Processing | Validate unique code; create `crt_certificate_types` record |
| Output | Redirect to types index with success flash |
| Status | 📐 Proposed |

**REQ-CRT-001.2: Design Certificate Template**
| Attribute | Detail |
|---|---|
| Description | Admin creates an HTML/CSS template for a certificate type. Template uses merge field placeholders (e.g., `{{student_name}}`, `{{class_section}}`, `{{dob}}`, `{{admission_no}}`, `{{issue_date}}`, `{{certificate_no}}`, `{{principal_name}}`). School logo and seal are uploaded and embedded. |
| Actors | School Admin |
| Preconditions | Certificate type exists; `tenant.certificate-template.create` |
| Input | name, certificate_type_id FK, template_content (LONGTEXT HTML), variables_json (array of merge fields used), page_size ENUM('a4','letter','custom'), orientation ENUM('portrait','landscape'), custom_width_mm NULL, custom_height_mm NULL, is_default TINYINT(1) |
| Processing | Validate HTML content not empty; validate all `{{variables}}` declared in variables_json; create record; if is_default=true set other templates for same type to is_default=false |
| Output | Redirect to templates index; preview link active |
| Status | 📐 Proposed |

**REQ-CRT-001.3: Template Preview**
| Attribute | Detail |
|---|---|
| Description | Admin can preview a template rendered with dummy student data before activating it |
| Input | template_id (GET param) |
| Processing | Load template; substitute all merge fields with placeholder values; render via DomPDF; return inline PDF |
| Output | Inline PDF preview in browser |
| Status | 📐 Proposed |

**REQ-CRT-001.4: Template Version Control**
| Attribute | Detail |
|---|---|
| Description | Every time a template is saved (updated), the previous version is archived in `crt_template_versions`. Admin can view version history and restore an older version. |
| Input | template_id, restore action |
| Processing | On update: INSERT current template_content into `crt_template_versions` before overwriting; on restore: copy version content back to main template and create a new version entry for the current content |
| Output | Success flash; current template reflects restored version |
| Status | 📐 Proposed |

**REQ-CRT-001.5: Assign Default Template to Certificate Type**
| Attribute | Detail |
|---|---|
| Description | Admin marks one template as the default for a given certificate type. The default template is used during auto-generation unless explicitly overridden. |
| Processing | Toggle `is_default` flag; enforce single default per type via unique partial index |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.R1.1.1.1 — Template can define header, body, footer sections as distinct HTML regions
- [ ] ST.R1.1.1.2 — Merge fields `{{student_name}}`, `{{class_section}}`, `{{dob}}`, `{{admission_no}}`, `{{certificate_no}}`, `{{issue_date}}` work correctly in generated PDF
- [ ] ST.R1.1.1.3 — School logo and seal uploaded via sys_media are embedded in rendered PDF
- [ ] ST.R1.1.2.1 — Fonts, colors, border styles persist in saved template
- [ ] ST.R1.1.2.2 — QR code auto-placed in template at designated coordinates
- [ ] ST.R1.2.1.1 — Version history shows all saved revisions with timestamp
- [ ] ST.R1.2.1.2 — Restoring an older version renders correctly in preview
- [ ] ST.R1.2.2.1 — Certificate type has exactly one default template at any time
- [ ] ST.R1.2.2.2 — Permission control prevents unauthorized template editing

**Proposed Test Cases:**
| # | Scenario | Type | Priority |
|---|---|---|---|
| 1 | Create template with all merge fields; preview renders correctly | Browser | High |
| 2 | Update template — old version archived in version history | Feature | High |
| 3 | Restore old version — content matches archived snapshot | Feature | Medium |
| 4 | Mark template as default — previous default is unset | Feature | Medium |

---

### FR-CRT-002: Bonafide Certificate

**RBS Reference:** ST.R3.1.1, ST.R3.2.2 — most common school certificate
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `crt_requests`, `crt_issued_certificates`

#### Requirements

**REQ-CRT-002.1: Submit Bonafide Certificate Request**
| Attribute | Detail |
|---|---|
| Description | Student, parent, or admin submits a request for a Bonafide Certificate. The certificate attests that the named student is currently enrolled in the school in the specified class. |
| Actors | Student (portal), Parent (portal), Clerk, Admin |
| Input | certificate_type_id (Bonafide type), student_id, academic_session_id, purpose (e.g., "Bank account opening", "Passport application"), required_by_date (optional), remarks |
| Processing | Validate student is currently enrolled and active in the given session; check for duplicate pending request; create `crt_requests` record with status='pending'; notify approving authority |
| Output | Request created; request tracking number displayed; email/SMS notification sent |
| Status | 📐 Proposed |

**REQ-CRT-002.2: Auto-Generate Bonafide PDF**
| Attribute | Detail |
|---|---|
| Description | On approval, system auto-generates PDF by injecting student data into the Bonafide template. Data injected includes: student full name, father's name, class, section, academic session, date of admission, date of birth, nationality, religion, and purpose of certificate. |
| Processing | Load active Bonafide template; resolve all merge fields from `std_students`, `std_profiles`, `std_academic_sessions`; generate sequential `certificate_no` (format: `BON-YYYY-000001`); generate QR code pointing to public verification URL; render PDF via DomPDF; store file path in `crt_issued_certificates` |
| Output | PDF stored; download link provided; record in `crt_issued_certificates` with verification_hash |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Bonafide accurately reflects current enrollment (class, section, session)
- [ ] Certificate number is sequential and unique for the academic year
- [ ] QR code on certificate resolves to correct public verification URL
- [ ] PDF renders school logo and principal name/signature area correctly

**Proposed Test Cases:**
| # | Scenario | Type | Priority |
|---|---|---|---|
| 1 | Submit request → approve → PDF generated with correct student data | Feature | High |
| 2 | Duplicate pending request is blocked | Feature | High |
| 3 | QR code resolves to valid verification page | Feature | High |

---

### FR-CRT-003: Transfer Certificate (TC)

**RBS Reference:** F.R2, F.R3 (government format compliance)
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `crt_requests`, `crt_issued_certificates`, `crt_tc_register`

#### Requirements

**REQ-CRT-003.1: TC Request and Government Format**
| Attribute | Detail |
|---|---|
| Description | TC is issued when a student leaves the school. Unlike other certificates, TC uses a government-prescribed format that includes: serial number from TC register, date of admission, date of leaving, conduct, character, whether all dues cleared, reason for leaving, and signature of Principal. |
| Actors | Admin, Principal |
| Preconditions | Student withdrawal process must be initiated (linked to `std_students.is_active = 0` or withdrawal record); fee dues cleared |
| Input | student_id, date_of_leaving, reason_for_leaving ENUM('parentRequest','migration','completion','other'), is_fees_cleared TINYINT(1), conduct_rating, remarks |
| Processing | Validate student exists and withdrawal is recorded; check fees cleared flag; auto-populate TC register fields from student profile; assign TC register serial number (sequential, year-wise); generate PDF |
| Output | TC PDF generated; TC register entry created; student record updated with tc_issued=true |
| Status | 📐 Proposed |

**REQ-CRT-003.2: TC Register**
| Attribute | Detail |
|---|---|
| Description | Maintain a formal TC register (serial-numbered logbook) as required by state boards. Each entry records: sl. no., student name, father's name, class at leaving, date of admission, date of leaving, conduct, whether original TC issued, whether duplicate issued. |
| Table | `crt_tc_register` |
| Processing | Auto-insert on TC generation; allow view and print of full register |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] TC serial number follows year-wise sequential format (TC-2025-0001)
- [ ] TC cannot be generated if fee dues are not cleared (unless admin override with justification)
- [ ] TC register is printable and shows all issued TCs for the academic year
- [ ] Duplicate TC issuance is tracked separately with "Duplicate" watermark

---

### FR-CRT-004: Character Certificate

**RBS Reference:** F.R3 (certificate generation)
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `crt_requests`, `crt_issued_certificates`

#### Requirements

**REQ-CRT-004.1: Character Certificate Generation**
| Attribute | Detail |
|---|---|
| Description | Attests to the student's character and conduct during their period of study. Common for competitive exam applications, job applications for older students, and college admissions. |
| Input | student_id, purpose, academic_session_id, date_range (from_year, to_year) |
| Processing | Fetch student name, enrollment period, class range from academic records; inject into Character Certificate template; generate certificate |
| Output | PDF with character attestation, certificate number, principal signature block |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Character certificate accurately reflects study period (admission year to current/leaving year)
- [ ] Template allows customization of character description wording

---

### FR-CRT-005: Sports and Achievement Certificates

**RBS Reference:** F.R1 (custom templates), F.R3 (generation)
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `crt_requests`, `crt_issued_certificates`

#### Requirements

**REQ-CRT-005.1: Achievement Certificate Creation**
| Attribute | Detail |
|---|---|
| Description | Award-style certificates for sports achievements, academic excellence, competitions, cultural events. These are landscape-oriented, highly visual certificates with custom award text. |
| Input | certificate_type_id (sports/achievement), recipient student_id(s) (supports bulk), event_name, achievement_description, award_rank (1st/2nd/3rd/Participation), award_date, authorizing_teacher_id |
| Processing | Can be issued in bulk without a prior request (admin-initiated); generates certificate for each student with their specific achievement text; no mandatory approval workflow |
| Output | Individual PDFs or ZIP for bulk; records in `crt_issued_certificates` |
| Status | 📐 Proposed |

**REQ-CRT-005.2: Bulk Achievement Certificates**
| Attribute | Detail |
|---|---|
| Description | Admin selects multiple students (e.g., all sports day participants), defines award details, and generates all certificates in a single bulk job dispatched as a queue job |
| Processing | Dispatch `BulkGenerateCertificatesJob`; store per-student files; provide ZIP download link |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Achievement certificates can be generated without going through approval workflow
- [ ] Bulk generation dispatches asynchronously; progress indicator shown
- [ ] ZIP download contains all generated PDFs named as `[CertNo]_[StudentName].pdf`

---

### FR-CRT-006: Study and Conduct Certificate

**RBS Reference:** F.R3 (certificate generation)
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `crt_requests`, `crt_issued_certificates`

#### Requirements

**REQ-CRT-006.1: Study Certificate Generation**
| Attribute | Detail |
|---|---|
| Description | Attests that the student studied in the school for a specified period. Similar to Bonafide but explicitly states the period of study rather than current enrollment. Required by some government offices for address proof or academic history. |
| Input | student_id, from_date, to_date, purpose |
| Processing | Validate date range falls within the student's enrollment period; inject study period details into template |
| Output | PDF with study period clearly stated |
| Status | 📐 Proposed |

---

### FR-CRT-007: ID Card Generation

**RBS Reference:** F.R5.1 — ID Card Templates, F.R5.2 — ID Card Generation
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `crt_id_card_configs`, `crt_id_card_issued`

#### Requirements

**REQ-CRT-007.1: ID Card Template Configuration**
| Attribute | Detail |
|---|---|
| Description | Admin designs ID card templates for students and staff. Student ID cards include: photo, name, class/section, admission number, blood group, emergency contact, academic year, QR code (encodes student ID), school logo and name, school address. Staff ID cards include: photo, name, designation, department, employee ID, QR code. |
| Actors | School Admin |
| Input | card_type ENUM('student','staff'), template_json (field positions, background color, logo placement, QR position), academic_session_id (for student cards), custom_css |
| Processing | Save configuration; support A5 and credit-card (CR80) sizes; preview renders a sample card using DomPDF |
| Output | Config saved; preview PDF available |
| Status | 📐 Proposed |

**REQ-CRT-007.2: Bulk ID Card Generation**
| Attribute | Detail |
|---|---|
| Description | Admin selects class/section or all students/staff and generates ID cards in bulk. Generated as printable sheet (multiple cards per A4 page for credit-card size) for easy printing and cutting. |
| Input | card_type, academic_session_id, filter (class_id, section_id, or 'all') |
| Processing | Fetch student photos from `sys_media`; generate QR code per student (SimpleSoftwareIO QR); render ID card per student; arrange multiple cards per printable sheet; generate single PDF |
| Output | Printable PDF sheet with grid of ID cards; issuance records in `crt_id_card_issued` |
| Status | 📐 Proposed |

**REQ-CRT-007.3: ID Card Handover Tracking**
| Attribute | Detail |
|---|---|
| Description | Track which students have received their physical ID cards (issued vs. pending distribution) |
| Processing | Mark individual or bulk students as card_received; record date and received_by |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.R5.1.1.1 — Student photo field renders actual uploaded photo
- [ ] ST.R5.1.1.2 — QR code placement respects template configuration
- [ ] ST.R5.2.1.1 — Auto-fetch student name, class, section, admission_no, blood group
- [ ] ST.R5.2.2.1 — Printable sheet arranges credit-card-size cards in grid layout
- [ ] ST.R5.2.2.2 — ID card handover tracked per student

---

### FR-CRT-008: Certificate Request Workflow

**RBS Reference:** F.R2.1 — Submission, F.R2.2 — Approval Process
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `crt_requests`

#### Requirements

**REQ-CRT-008.1: Request Submission**
| Attribute | Detail |
|---|---|
| Description | Student, parent, or staff member submits a certificate request through the portal or admin creates on their behalf. Multiple supporting documents can be attached. |
| Input | certificate_type_id, requester_id (the person requesting), beneficiary_student_id, purpose, supporting_documents (file uploads to sys_media), required_by_date, remarks |
| Processing | Validate student enrollment status; check if certificate type requires_approval; if requires_approval=false → auto-proceed to generation; if requires_approval=true → status='pending', notify approver group |
| Output | Request record created; tracking number displayed (format: `REQ-YYYY-000001`); push notification/email sent |
| Status | 📐 Proposed |

**REQ-CRT-008.2: Request Review and Approval**
| Attribute | Detail |
|---|---|
| Description | Admin/Principal reviews the request, validates supporting documents, checks student eligibility, then approves or rejects. |
| Input | request_id, action ENUM('approve','reject'), approval_remarks, approved_by |
| Processing | On approve: update status='approved'; trigger certificate generation; send notification; On reject: update status='rejected'; capture rejection_reason; notify requester |
| Output | Status updated; notification sent; if approved, certificate auto-generated |
| Status | 📐 Proposed |

**REQ-CRT-008.3: Request Status Tracking**
| Attribute | Detail |
|---|---|
| Description | Requester (student/parent) can track the status of their certificate request in real-time through the student portal |
| Processing | Status transitions: pending → under_review → approved/rejected → generated → issued |
| Output | Status display with timestamp for each stage |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.R2.1.1.1 — Certificate type can be selected from active types
- [ ] ST.R2.1.1.2 — Purpose field is mandatory
- [ ] ST.R2.1.1.3 — Supporting documents can be attached (PDF/image)
- [ ] ST.R2.1.2.1 — Requester can view current status
- [ ] ST.R2.1.2.2 — SMS/email notification sent on status change
- [ ] ST.R2.2.1.1 — Approver can view attached supporting documents
- [ ] ST.R2.2.1.2 — Student eligibility check (enrollment + fee status) runs on review
- [ ] ST.R2.2.2.1 — Approval remarks recorded
- [ ] ST.R2.2.2.2 — Auto-notification on approval or rejection

---

### FR-CRT-009: Digital Certificate with QR Verification

**RBS Reference:** F.R6.1 — QR Code Verification, F.R6.2 — API Verification
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `crt_issued_certificates`, `crt_verification_logs`

#### Requirements

**REQ-CRT-009.1: QR Code Generation and Embedding**
| Attribute | Detail |
|---|---|
| Description | Every issued certificate contains a QR code generated using SimpleSoftwareIO QR Code. The QR encodes a public verification URL: `https://{school-domain}/verify/{verification_hash}`. The verification_hash is HMAC-SHA256 of (certificate_no + issue_date + student_id + secret key). |
| Processing | On certificate generation: compute HMAC hash; store in `crt_issued_certificates.verification_hash`; generate QR code image; embed in PDF template |
| Output | QR code embedded in PDF; verification URL is active |
| Status | 📐 Proposed |

**REQ-CRT-009.2: Public Verification Endpoint**
| Attribute | Detail |
|---|---|
| Description | No-login public URL that any third party can visit after scanning the QR code. Displays: certificate type, issued to (student name), issued by (school name), issue date, validity status (valid/expired/revoked). Does NOT expose full student details for privacy. |
| Route | GET `/verify/{hash}` — public, no auth required |
| Processing | Lookup `verification_hash` in `crt_issued_certificates`; check is_active and validity_date; log access in `crt_verification_logs` with IP + user-agent + timestamp |
| Output | Verification result page (simple HTML, mobile-friendly) |
| Status | 📐 Proposed |

**REQ-CRT-009.3: API Verification Endpoint**
| Attribute | Detail |
|---|---|
| Description | REST API for third-party institutions to programmatically verify certificates. Secured with API key issued per institution. |
| Route | GET `/api/v1/certificate/verify?hash={hash}&api_key={key}` |
| Processing | Validate API key; lookup hash; return JSON `{valid, certificate_type, issued_to, issued_date, issued_by, expires_on}` |
| Output | JSON response |
| Status | 📐 Proposed |

**REQ-CRT-009.4: Verification Log Management**
| Attribute | Detail |
|---|---|
| Description | Admin can view all verification attempts for any certificate — useful to detect suspicious re-use or forgery attempts |
| Processing | Log: certificate_issued_id, accessed_at, accessor_ip, accessor_agent, verification_method ENUM('qr','api','manual') |
| Output | Verification log table in admin panel |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.R6.1.1.1 — QR scan fetches correct certificate details
- [ ] ST.R6.1.1.2 — Authenticity status clearly shown (VALID / EXPIRED / REVOKED)
- [ ] ST.R6.1.2.1 — Every verification attempt is logged
- [ ] ST.R6.1.2.2 — Log includes source (QR scan IP, API call, manual)
- [ ] ST.R6.2.1.1 — Third-party API returns correct JSON response
- [ ] ST.R6.2.1.2 — API key is required; unauthorized calls return 401

---

### FR-CRT-010: Bulk Certificate Generation

**RBS Reference:** ST.R3.1.2.1 — Generate for batch, ST.R3.1.2.2 — Download ZIP
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `crt_bulk_jobs`, `crt_issued_certificates`

#### Requirements

**REQ-CRT-010.1: Bulk Generation Job**
| Attribute | Detail |
|---|---|
| Description | Admin can generate the same certificate type for an entire class, section, or custom student selection in a single operation. Processing is asynchronous via queue job. |
| Input | certificate_type_id, academic_session_id, class_id (optional), section_id (optional), student_ids (array, optional — for custom selection), override_template_id (optional) |
| Processing | Dispatch `BulkGenerateCertificatesJob`; for each student: generate PDF; store file; create `crt_issued_certificates` record; on completion create ZIP archive; update `crt_bulk_jobs.status` |
| Output | Job progress trackable via polling endpoint; ZIP file available for download on completion |
| Status | 📐 Proposed |

**REQ-CRT-010.2: Bulk Job Status Tracking**
| Attribute | Detail |
|---|---|
| Description | Admin sees progress bar showing X/N certificates generated. On completion, download ZIP button appears. |
| Processing | `crt_bulk_jobs` stores: total_count, processed_count, failed_count, status ENUM('queued','processing','completed','failed'), zip_path |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Bulk job for 100 students completes without timeout (queue-based)
- [ ] ZIP file named `[CertType]_[Class]_[Date].zip` with individual PDFs inside
- [ ] Failed individual generations do not abort entire bulk job; failures are logged

---

### FR-CRT-011: Document Management System (DMS)

**RBS Reference:** F.R4.1 — Document Upload, F.R4.2 — Document Verification
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `crt_student_documents`, `crt_document_verifications`

#### Requirements

**REQ-CRT-011.1: Student Document Upload**
| Attribute | Detail |
|---|---|
| Description | School staff can upload incoming student documents (birth certificate, previous school TC, migration certificate, caste certificate, disability certificate, aadhar, photos) and categorise them. Supports bulk upload via ZIP with student-to-file mapping. |
| Input | student_id, document_category_id (from sys_dropdown_table), document_name, document_date, file (PDF/JPG/PNG, max 5MB), remarks |
| Processing | Validate MIME type; store via sys_media (polymorphic); create `crt_student_documents` record |
| Output | Document listed in student's DMS folder |
| Status | 📐 Proposed |

**REQ-CRT-011.2: Document Verification**
| Attribute | Detail |
|---|---|
| Description | Admin reviews uploaded document and marks it as verified, rejected (with reason), or pending. Verification status is used in certificate eligibility checks. |
| Input | document_id, verification_status ENUM('pending','verified','rejected'), verification_remarks, verified_by |
| Processing | Update `crt_student_documents.verification_status`; create log entry in `crt_document_verifications` |
| Output | Verification status updated; badge shown on student DMS list |
| Status | 📐 Proposed |

**REQ-CRT-011.3: DMS Access Control**
| Attribute | Detail |
|---|---|
| Description | Document access can be restricted. Admin can set who can view or download each document category. Access download events are logged. |
| Processing | Check permission before file download; log download event with user_id + timestamp |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.R4.1.1.1 — PDFs and images can be uploaded
- [ ] ST.R4.1.1.2 — Document category selectable from dropdown (TC, Migration, DOB, Aadhar, etc.)
- [ ] ST.R4.2.1.1 — Uploaded file viewable in browser before verification
- [ ] ST.R4.2.1.2 — Verification status updated (pending / verified / rejected)
- [ ] ST.R4.2.2.2 — Download events logged with user and timestamp

---

### FR-CRT-012: Certificate Reports and Analytics

**RBS Reference:** F.R7.1 — Certificate Reports, F.R7.2 — Usage Analytics
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `crt_issued_certificates`, `crt_requests`

#### Requirements

**REQ-CRT-012.1: Issued Certificates Report**
| Attribute | Detail |
|---|---|
| Description | Tabular report showing all issued certificates with filters: certificate type, date range, class/section, status. Exportable to PDF and Excel. |
| Status | 📐 Proposed |

**REQ-CRT-012.2: Pending Requests Report**
| Attribute | Detail |
|---|---|
| Description | List of all pending and under-review requests with days-since-submission, required-by date, and urgency indicator. |
| Status | 📐 Proposed |

**REQ-CRT-012.3: Type Analytics**
| Attribute | Detail |
|---|---|
| Description | Bar chart / pie chart showing request volume by certificate type; monthly trend; peak request periods identification |
| Addresses | ST.R7.2.1.1 — Identify peak request periods; ST.R7.2.1.2 — Detect most-requested types |
| Status | 📐 Proposed |

---

## 5. PROPOSED DATABASE SCHEMA

### 5.1 Table: `crt_certificate_types`

```sql
CREATE TABLE `crt_certificate_types` (
  `id`                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`               VARCHAR(150) NOT NULL,
  `code`               VARCHAR(20) NOT NULL,
  `category`           ENUM('student','staff','achievement') NOT NULL DEFAULT 'student',
  `description`        TEXT NULL,
  `requires_approval`  TINYINT(1) NOT NULL DEFAULT 1,
  `validity_days`      INT UNSIGNED NULL COMMENT 'NULL = no expiry',
  `default_template_id` INT UNSIGNED NULL,
  `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`         BIGINT UNSIGNED NULL,
  `created_at`         TIMESTAMP NULL,
  `updated_at`         TIMESTAMP NULL,
  `deleted_at`         TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_types_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.2 Table: `crt_templates`

```sql
CREATE TABLE `crt_templates` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`                VARCHAR(200) NOT NULL,
  `certificate_type_id` INT UNSIGNED NOT NULL,
  `template_content`    LONGTEXT NOT NULL COMMENT 'HTML/CSS with {{merge_field}} placeholders',
  `variables_json`      JSON NULL COMMENT 'Array of merge field names used in this template',
  `page_size`           ENUM('a4','a5','letter','custom') NOT NULL DEFAULT 'a4',
  `orientation`         ENUM('portrait','landscape') NOT NULL DEFAULT 'portrait',
  `custom_width_mm`     DECIMAL(6,2) NULL,
  `custom_height_mm`    DECIMAL(6,2) NULL,
  `is_default`          TINYINT(1) NOT NULL DEFAULT 0,
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          BIGINT UNSIGNED NULL,
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crtTpl_type` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.3 Table: `crt_template_versions`

```sql
CREATE TABLE `crt_template_versions` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`         INT UNSIGNED NOT NULL,
  `version_no`          INT UNSIGNED NOT NULL DEFAULT 1,
  `template_content`    LONGTEXT NOT NULL,
  `variables_json`      JSON NULL,
  `saved_by`            BIGINT UNSIGNED NULL,
  `saved_at`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crtTplVer_template` FOREIGN KEY (`template_id`) REFERENCES `crt_templates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.4 Table: `crt_requests`

```sql
CREATE TABLE `crt_requests` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_no`            VARCHAR(30) NOT NULL COMMENT 'Format: REQ-YYYY-000001',
  `certificate_type_id`   INT UNSIGNED NOT NULL,
  `requester_type`        ENUM('student','parent','staff','admin') NOT NULL,
  `requester_id`          BIGINT UNSIGNED NOT NULL COMMENT 'FK → sys_users',
  `beneficiary_student_id` INT UNSIGNED NOT NULL COMMENT 'FK → std_students',
  `academic_session_id`   INT UNSIGNED NULL,
  `purpose`               VARCHAR(500) NOT NULL,
  `required_by_date`      DATE NULL,
  `status`                ENUM('pending','under_review','approved','rejected','generated','issued') NOT NULL DEFAULT 'pending',
  `approval_remarks`      TEXT NULL,
  `rejection_reason`      TEXT NULL,
  `approved_by`           BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
  `approved_at`           TIMESTAMP NULL,
  `remarks`               TEXT NULL,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_requests_no` (`request_no`),
  CONSTRAINT `fk_crtReq_type` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crtReq_student` FOREIGN KEY (`beneficiary_student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.5 Table: `crt_issued_certificates`

```sql
CREATE TABLE `crt_issued_certificates` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `certificate_no`        VARCHAR(40) NOT NULL COMMENT 'Format: BON-YYYY-000001',
  `request_id`            INT UNSIGNED NULL COMMENT 'NULL for admin-initiated (bulk/achievement)',
  `certificate_type_id`   INT UNSIGNED NOT NULL,
  `recipient_type`        ENUM('student','staff') NOT NULL DEFAULT 'student',
  `recipient_id`          INT UNSIGNED NOT NULL,
  `template_id`           INT UNSIGNED NOT NULL,
  `issue_date`            DATE NOT NULL,
  `validity_date`         DATE NULL COMMENT 'NULL = no expiry',
  `qr_code_data`          VARCHAR(500) NULL COMMENT 'QR encoded URL',
  `verification_hash`     VARCHAR(128) NOT NULL COMMENT 'HMAC-SHA256',
  `file_path`             VARCHAR(500) NULL COMMENT 'Stored PDF path',
  `is_revoked`            TINYINT(1) NOT NULL DEFAULT 0,
  `revoked_at`            TIMESTAMP NULL,
  `revoked_by`            BIGINT UNSIGNED NULL,
  `revocation_reason`     TEXT NULL,
  `issued_by`             BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
  `is_duplicate`          TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Duplicate copy issued',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_crt_issued_certno` (`certificate_no`),
  UNIQUE KEY `uq_crt_issued_hash` (`verification_hash`),
  CONSTRAINT `fk_crtIss_type` FOREIGN KEY (`certificate_type_id`) REFERENCES `crt_certificate_types` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_crtIss_template` FOREIGN KEY (`template_id`) REFERENCES `crt_templates` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.6 Table: `crt_verification_logs`

```sql
CREATE TABLE `crt_verification_logs` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `certificate_issued_id`   INT UNSIGNED NOT NULL,
  `verification_method`     ENUM('qr','api','manual') NOT NULL DEFAULT 'qr',
  `accessor_ip`             VARCHAR(45) NULL,
  `accessor_agent`          VARCHAR(500) NULL,
  `api_key_id`              INT UNSIGNED NULL COMMENT 'FK → api_keys table if used',
  `verification_result`     ENUM('valid','expired','revoked','not_found') NOT NULL,
  `accessed_at`             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at`              TIMESTAMP NULL,
  `updated_at`              TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crtVlog_issued` FOREIGN KEY (`certificate_issued_id`) REFERENCES `crt_issued_certificates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.7 Table: `crt_id_card_configs`

```sql
CREATE TABLE `crt_id_card_configs` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `card_type`             ENUM('student','staff') NOT NULL,
  `name`                  VARCHAR(150) NOT NULL,
  `academic_session_id`   INT UNSIGNED NULL,
  `card_size`             ENUM('a5','cr80','custom') NOT NULL DEFAULT 'cr80',
  `orientation`           ENUM('portrait','landscape') NOT NULL DEFAULT 'portrait',
  `template_json`         JSON NOT NULL COMMENT 'Field positions, colors, fonts, QR placement',
  `cards_per_sheet`       TINYINT UNSIGNED NOT NULL DEFAULT 8,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.8 Table: `crt_student_documents`

```sql
CREATE TABLE `crt_student_documents` (
  `id`                      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`              INT UNSIGNED NOT NULL,
  `document_category_id`    INT UNSIGNED NOT NULL COMMENT 'FK → sys_dropdown_table',
  `document_name`           VARCHAR(200) NOT NULL,
  `document_date`           DATE NULL,
  `media_id`                BIGINT UNSIGNED NULL COMMENT 'FK → sys_media (polymorphic)',
  `verification_status`     ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  `verification_remarks`    TEXT NULL,
  `verified_by`             BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
  `verified_at`             TIMESTAMP NULL,
  `remarks`                 TEXT NULL,
  `is_active`               TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`              BIGINT UNSIGNED NULL,
  `created_at`              TIMESTAMP NULL,
  `updated_at`              TIMESTAMP NULL,
  `deleted_at`              TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_crtDoc_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6. PROPOSED ROUTES

### 6.1 Web Routes (tenant.php additions)

```
Route Group: prefix='certificate', middleware=['auth','verified','tenant']

Certificate Types
  GET    /certificate/types                          → CertificateTypeController@index
  GET    /certificate/types/create                   → CertificateTypeController@create
  POST   /certificate/types                          → CertificateTypeController@store
  GET    /certificate/types/{type}                   → CertificateTypeController@show
  GET    /certificate/types/{type}/edit              → CertificateTypeController@edit
  PUT    /certificate/types/{type}                   → CertificateTypeController@update
  DELETE /certificate/types/{type}                   → CertificateTypeController@destroy
  GET    /certificate/types/trashed                  → CertificateTypeController@trashed
  PUT    /certificate/types/{type}/restore           → CertificateTypeController@restore
  DELETE /certificate/types/{type}/force-delete      → CertificateTypeController@forceDelete

Certificate Templates
  GET    /certificate/templates                      → CertificateTemplateController@index
  GET    /certificate/templates/create               → CertificateTemplateController@create
  POST   /certificate/templates                      → CertificateTemplateController@store
  GET    /certificate/templates/{tpl}                → CertificateTemplateController@show
  GET    /certificate/templates/{tpl}/edit           → CertificateTemplateController@edit
  PUT    /certificate/templates/{tpl}                → CertificateTemplateController@update
  DELETE /certificate/templates/{tpl}                → CertificateTemplateController@destroy
  GET    /certificate/templates/{tpl}/preview        → CertificateTemplateController@preview
  GET    /certificate/templates/{tpl}/versions       → CertificateTemplateController@versions
  POST   /certificate/templates/{tpl}/restore-version/{v} → CertificateTemplateController@restoreVersion

Certificate Requests
  GET    /certificate/requests                       → CertificateRequestController@index
  GET    /certificate/requests/create                → CertificateRequestController@create
  POST   /certificate/requests                       → CertificateRequestController@store
  GET    /certificate/requests/{req}                 → CertificateRequestController@show
  POST   /certificate/requests/{req}/approve         → CertificateRequestController@approve
  POST   /certificate/requests/{req}/reject          → CertificateRequestController@reject

Issued Certificates
  GET    /certificate/issued                         → CertificateIssuedController@index
  GET    /certificate/issued/{cert}                  → CertificateIssuedController@show
  GET    /certificate/issued/{cert}/download         → CertificateIssuedController@download
  POST   /certificate/issued/{cert}/revoke           → CertificateIssuedController@revoke

Bulk Generation
  GET    /certificate/bulk-generate                  → BulkGenerationController@index
  POST   /certificate/bulk-generate                  → BulkGenerationController@generate
  GET    /certificate/bulk-generate/{job}/status     → BulkGenerationController@status
  GET    /certificate/bulk-generate/{job}/download   → BulkGenerationController@download

ID Cards
  GET    /certificate/id-card-config                 → IdCardController@indexConfig
  POST   /certificate/id-card-config                 → IdCardController@storeConfig
  GET    /certificate/id-cards/generate              → IdCardController@generateForm
  POST   /certificate/id-cards/generate              → IdCardController@generate

Documents (DMS)
  GET    /certificate/documents                      → DocumentManagementController@index
  POST   /certificate/documents/upload               → DocumentManagementController@upload
  GET    /certificate/documents/{doc}                → DocumentManagementController@show
  POST   /certificate/documents/{doc}/verify         → DocumentManagementController@verify
  GET    /certificate/documents/{doc}/download       → DocumentManagementController@download

Verification Logs (admin)
  GET    /certificate/verification-logs              → VerificationController@logs

Reports
  GET    /certificate/reports/issued                 → CertificateReportController@issued
  GET    /certificate/reports/pending                → CertificateReportController@pending
  GET    /certificate/reports/analytics              → CertificateReportController@analytics
```

### 6.2 Public Routes (no auth)

```
GET /verify/{hash}                                   → VerificationController@verify (public)
```

### 6.3 API Routes (api.php)

```
GET /api/v1/certificate/verify                       → Api\CertificateVerifyController@verify
```

---

## 7. PROPOSED BLADE VIEWS

| View Path | Purpose |
|---|---|
| `certificate/dashboard.blade.php` | Module dashboard — recent requests, pending queue, quick stats |
| `certificate/types/index.blade.php` | List all certificate types |
| `certificate/types/create.blade.php` | Create type form |
| `certificate/types/edit.blade.php` | Edit type form |
| `certificate/types/show.blade.php` | Type detail + linked templates |
| `certificate/types/trash.blade.php` | Soft-deleted types |
| `certificate/templates/index.blade.php` | List templates |
| `certificate/templates/create.blade.php` | Template designer with live preview panel |
| `certificate/templates/edit.blade.php` | Edit template |
| `certificate/templates/show.blade.php` | Template detail |
| `certificate/templates/versions.blade.php` | Version history list |
| `certificate/templates/preview.blade.php` | Inline PDF preview (embed) |
| `certificate/requests/index.blade.php` | Request queue with filter tabs (pending / all) |
| `certificate/requests/create.blade.php` | Submit new request |
| `certificate/requests/show.blade.php` | Request detail + review/approve/reject actions |
| `certificate/issued/index.blade.php` | Issued certificates register |
| `certificate/issued/show.blade.php` | Issued certificate detail + download + revoke |
| `certificate/bulk/index.blade.php` | Bulk generation form + job status |
| `certificate/id-cards/config-index.blade.php` | List ID card configurations |
| `certificate/id-cards/config-form.blade.php` | Create/edit ID card config |
| `certificate/id-cards/generate.blade.php` | Generate ID cards form + preview |
| `certificate/documents/index.blade.php` | DMS document list per student |
| `certificate/documents/upload.blade.php` | Upload form |
| `certificate/documents/show.blade.php` | Document viewer |
| `certificate/verification/logs.blade.php` | Verification log table |
| `certificate/verification/public.blade.php` | Public certificate verification result (no auth) |
| `reports/certificate/issued.blade.php` | Issued certificates report |
| `reports/certificate/pending.blade.php` | Pending requests report |
| `reports/certificate/analytics.blade.php` | Type analytics charts |

---

## 8. PROPOSED CONTROLLERS

| Controller | Methods | Notes |
|---|---|---|
| `CertificateTypeController` | index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus | Full CRUD + soft delete lifecycle |
| `CertificateTemplateController` | index, create, store, show, edit, update, destroy, preview, versions, restoreVersion | Includes DomPDF preview |
| `CertificateRequestController` | index, create, store, show, approve, reject | Workflow actions |
| `CertificateIssuedController` | index, show, download, revoke | Issued register management |
| `BulkGenerationController` | index, generate, status, download | Async job + ZIP download |
| `IdCardController` | indexConfig, storeConfig, updateConfig, generateForm, generate | Config + generation |
| `DocumentManagementController` | index, upload, show, verify, download | DMS CRUD + verification |
| `VerificationController` | verify (public), logs (admin) | QR verification |
| `CertificateReportController` | issued, pending, analytics | Report generation |

---

## 9. PROPOSED MODELS

| Model | Table | Key Relationships |
|---|---|---|
| `CertificateType` | `crt_certificate_types` | hasMany(CertificateTemplate), hasMany(CertificateRequest), hasMany(CertificateIssued) |
| `CertificateTemplate` | `crt_templates` | belongsTo(CertificateType), hasMany(TemplateVersion) |
| `CertificateTemplateVersion` | `crt_template_versions` | belongsTo(CertificateTemplate) |
| `CertificateRequest` | `crt_requests` | belongsTo(CertificateType), belongsTo(Student via beneficiary_student_id), hasOne(CertificateIssued) |
| `CertificateIssued` | `crt_issued_certificates` | belongsTo(CertificateType), belongsTo(CertificateTemplate), hasMany(VerificationLog) |
| `CertificateVerificationLog` | `crt_verification_logs` | belongsTo(CertificateIssued) |
| `IdCardConfig` | `crt_id_card_configs` | standalone |
| `StudentDocument` | `crt_student_documents` | belongsTo(Student), morphOne(Media via sys_media) |

---

## 10. PROPOSED SERVICES

### 10.1 `CertificateGenerationService`
- `generateFromRequest(CertificateRequest $request): CertificateIssued` — resolves merge fields, renders DomPDF, stores PDF, creates `crt_issued_certificates` record
- `generateDirect(array $data): CertificateIssued` — admin-initiated generation without request
- `resolveMergeFields(Student $student, array $extraFields): array` — pulls data from std_students, std_profiles, academic session
- `generateCertificateNo(string $typeCode): string` — generates sequential cert number per type per year

### 10.2 `QrVerificationService`
- `generateVerificationHash(CertificateIssued $cert): string` — HMAC-SHA256
- `generateQrCode(string $verificationUrl): string` — SimpleSoftwareIO QR; returns base64 image
- `verifyHash(string $hash): array` — lookup + validity check + log creation

### 10.3 `DmsService`
- `uploadDocument(Student $student, UploadedFile $file, array $meta): StudentDocument`
- `verifyDocument(StudentDocument $doc, string $status, string $remarks, User $verifier): void`
- `getDocumentsByStudent(int $studentId): Collection`

---

## 11. EXTERNAL DEPENDENCIES

| Dependency | Version | Usage |
|---|---|---|
| DomPDF (barryvdh/laravel-dompdf) | v3.1 | PDF generation for certificates and ID cards (already installed via HPC module) |
| SimpleSoftwareIO/simplesoftwareio-qrcode | v4.2 | QR code generation for certificates and ID cards (already installed via Transport module) |
| stancl/tenancy | v3.9 | Tenant isolation |
| Laravel Queue | built-in | Async bulk generation via `BulkGenerateCertificatesJob` |

---

## 12. BUSINESS RULES

| Rule ID | Rule | Source |
|---|---|---|
| BR-CRT-001 | A Transfer Certificate cannot be issued unless `is_fees_cleared = true` or admin provides override justification | Indian school policy |
| BR-CRT-002 | TC serial number must be sequential and year-wise (cannot skip numbers) | State board requirement |
| BR-CRT-003 | A second issuance of any certificate is marked as `is_duplicate = true` and should carry a "DUPLICATE COPY" watermark | Standard practice |
| BR-CRT-004 | Certificate number format must be unique across the tenant. Format: `[TYPE_CODE]-[YYYY]-[6-digit seq]` | Data integrity |
| BR-CRT-005 | Verification hash must be computed from immutable fields. If certificate is revoked, verification returns REVOKED (not deleted from DB) | Audit trail |
| BR-CRT-006 | Certificate templates may only be deleted (soft) if no issued certificates reference them | Referential integrity |
| BR-CRT-007 | ID cards must include blood group when available in `std_profiles` — critical for emergencies | Safety |
| BR-CRT-008 | DMS documents marked as 'rejected' cannot be used to satisfy eligibility checks | Workflow integrity |
| BR-CRT-009 | Bulk generation exceeding 200 certificates must be processed via queue (not synchronous) | Performance |
| BR-CRT-010 | Public verification endpoint must not expose the student's full name, DOB, or class — only type, validity, and issuing school | Privacy |

---

## 13. NON-FUNCTIONAL REQUIREMENTS

| Requirement | Target | Notes |
|---|---|---|
| PDF Generation Time | < 3 seconds per certificate | DomPDF single-page certificates with embedded QR |
| Bulk Generation Throughput | > 50 certificates/minute via queue | Background job with queue worker |
| Verification Endpoint Response | < 500ms | Simple hash lookup + log insert |
| Storage | DMS files stored in tenant-isolated disk path | `storage/tenant_{id}/certificates/` |
| PDF Quality | 150 DPI minimum for printable output | DomPDF quality setting |
| Security | HMAC-SHA256 verification hash; API key for third-party endpoints | Tamper-evident |
| Soft Delete | All tables support `deleted_at` | Standard pattern |
| Audit | All data changes logged via `sys_activity_logs` | Standard pattern |

---

## 14. INTEGRATION POINTS

| Module | Integration Type | Direction | Description |
|---|---|---|---|
| Student Management (`std_*`) | Data Read | CRT reads STD | Student name, DOB, class, section, admission_no, photo from `std_students`, `std_profiles` |
| Academic Setup (`sch_*`) | Data Read | CRT reads SCH | Class, section, academic session names for merge fields |
| HPC Module (`hpc_*`) | Tool Reuse | Shared infrastructure | DomPDF already configured; Report Card generation remains in HPC |
| Transport Module (`tpt_*`) | Tool Reuse | Shared infrastructure | SimpleSoftwareIO QR Code already installed |
| Notification System | Outbound trigger | CRT triggers | Send SMS/email on request status change (approval/rejection) |
| Finance Module (`fin_*`) | Data Read | CRT reads FIN | Fee clearance status for TC issuance eligibility check |
| System Media (`sys_media`) | Polymorphic | Bidirectional | Logo, seal, student photos for templates; DMS document storage |
| Recommendation Module (`rec_*`) | None | — | No direct integration |

---

## 15. PROPOSED TEST CASES

| # | Test Case | Type | FR Reference | Priority |
|---|---|---|---|---|
| 1 | Create certificate type; appears in list | Browser | FR-CRT-001 | High |
| 2 | Design template with merge fields; preview renders correctly | Browser | FR-CRT-001 | High |
| 3 | Update template; previous version archived in version history | Feature | FR-CRT-001 | High |
| 4 | Submit Bonafide request → approve → PDF generated with correct merge fields | Feature | FR-CRT-002 | High |
| 5 | QR code on generated certificate resolves to valid public verification page | Feature | FR-CRT-009 | High |
| 6 | Revoked certificate shows REVOKED status on verification | Feature | FR-CRT-009 | High |
| 7 | TC cannot be generated when fee dues outstanding | Feature | FR-CRT-003 | High |
| 8 | TC serial number increments sequentially within academic year | Unit | FR-CRT-003 | High |
| 9 | Bulk generation for 50 students completes via queue; ZIP downloadable | Feature | FR-CRT-010 | High |
| 10 | ID card generated with student photo embedded | Browser | FR-CRT-007 | Medium |
| 11 | DMS document upload; verify status updated | Browser | FR-CRT-011 | Medium |
| 12 | Third-party API endpoint returns correct JSON; unauthorized call returns 401 | Feature | FR-CRT-009 | Medium |
| 13 | Duplicate certificate issued with DUPLICATE watermark | Feature | BR-CRT-003 | Medium |
| 14 | Public verification does not expose full student name/DOB | Feature | BR-CRT-010 | High |
| 15 | Analytics report shows most-requested certificate types | Browser | FR-CRT-012 | Low |
