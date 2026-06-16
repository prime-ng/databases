# CRT — Certificate & Template Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **CRT (Certificate)** module using `CRT_Certificate_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `CRT_FeatureSpec.md` — Feature Specification
2. `CRT_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `CRT_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** Certificate — End-to-end certificate lifecycle management for Indian K-12 schools.
Tables: `crt_*` (10 tables covering types, templates, requests, issuance, TC register, serial counters, bulk jobs, ID cards, documents, verification).

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = CRT
MODULE            = Certificate
MODULE_DIR        = Modules/Certificate/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = X                              # Certificate & Template in RBS
DB_TABLE_PREFIX   = crt_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/Certificates/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/CRT_Certificate_Requirement.md

FEATURE_FILE      = CRT_FeatureSpec.md
DDL_FILE_NAME     = CRT_DDL_v1.sql
DEV_PLAN_FILE     = CRT_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — CRT (CERTIFICATE) MODULE

### What This Module Does

The Certificate module provides an **end-to-end certificate lifecycle management system** for Indian K-12 schools on the Prime-AI SaaS platform. It covers the full lifecycle from certificate type and template configuration through a structured request-and-approval workflow, PDF generation (DomPDF), HMAC-SHA256 tamper-evident verification, QR-code-enabled public verification, bulk async issuance, ID card generation, and a Document Management System (DMS) for incoming student documents.

Every issued certificate carries a `verification_hash` (HMAC-SHA256 of `certificate_no + issue_date + recipient_id + APP_KEY`) and an embedded QR code pointing to a no-login public verification endpoint.

**L1 — Certificate Type & Template Management:**
- Certificate types with categories (Administrative, Legal, Character, Achievement, Identity), `requires_approval` flag, validity, and configurable serial-number format (`{TYPE_CODE}-{YYYY}-{SEQ6}` default)
- HTML/CSS templates with merge field placeholders (`{{student_name}}`, `{{class_section}}`, `{{certificate_no}}`, etc.)
- Template versioning — every save archives the previous version in `crt_template_versions`
- One default template per type enforced via toggle logic

**L2 — Certificate Request Workflow:**
- 6-state FSM: `pending → under_review → approved/rejected → generated → issued`
- `requires_approval = false` → request auto-advances to `approved` and generation triggers immediately
- Supporting documents attached via polymorphic `sys_media`
- Duplicate request prevention: unique check on `(beneficiary_student_id, certificate_type_id, status IN (pending, under_review, approved))`

**L3 — Certificate Generation & Issuance:**
- `CertificateGenerationService` resolves merge fields from `std_students`, `std_profiles`, `sch_academic_sessions`
- Serial counter increments via `SELECT ... FOR UPDATE` (BR-CRT-015: race condition prevention)
- PDF rendered via DomPDF; stored at `storage/tenant_{id}/certificates/{type}/{YYYY}/`
- Download via signed URLs (`Storage::temporaryUrl()`)
- Second issuance = `is_duplicate = true` with "DUPLICATE COPY" watermark

**L4 — Transfer Certificate (TC) — Legal:**
- Fee-clear gate: TC blocked if `fin_fee_dues > 0` unless admin override (BR-CRT-001)
- Formal `crt_tc_register` table (state-board mandated: sl_no, father_name, class_at_leaving, date_of_admission, date_of_leaving, conduct)
- TC serial number sequential, year-wise, no gaps (BR-CRT-002)
- Post-issuance: `std_students.tc_issued = true`; student status transitions to `withdrawn` (BR-CRT-011)

**L5 — Bulk Generation:**
- Achievement/participation certificates — no request/approval workflow
- `BulkGenerateCertificatesJob` dispatched to queue for > 200 certificates
- `crt_bulk_jobs` tracks `total_count`, `processed_count`, `failed_count`, `status`, `zip_path`, `error_log_json`
- Individual failures do not abort the batch

**L6 — Digital Verification (QR + API):**
- Public page `/verify/{hash}` — no login; shows VALID / EXPIRED / REVOKED with minimal info only (BR-CRT-010)
- REST API `GET /api/v1/certificate/verify?hash={hash}&api_key={key}` for third-party institutions
- All verification attempts logged in `crt_verification_logs` (IP, user-agent, method, result)

**L7 — ID Card Generation:**
- Student and staff ID card templates; CR80 (85.6 × 54 mm) and A5 sizes
- QR code per card via SimpleSoftwareIO/simple-qrcode; student photo from `sys_media`
- Bulk printable PDF: 8 cards per A4 sheet (configurable `cards_per_sheet`)
- Handover tracking: `card_received = true` with date

**L8 — Document Management System (DMS):**
- Upload incoming student documents (birth cert, previous TC, migration cert, Aadhaar, caste, photo, etc.)
- Verification status: `pending → verified / rejected`; rejection requires remarks
- Rejected documents cannot satisfy certificate eligibility checks (BR-CRT-008)
- Files stored via polymorphic `sys_media`

### Architecture Decisions
- **Single Laravel module** (`Modules\Certificate`) — all 8 sub-modules in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `certificate/` | Route name prefix: `certificate.`
- Public route: `/verify/{hash}` — no auth, no middleware (third-party QR scan endpoint)
- DomPDF (`barryvdh/laravel-dompdf` v3.1) — already installed (used by HPC module)
- SimpleSoftwareIO/simple-qrcode v4.2 — already installed (used by Transport module)
- Student data: reads `std_students`, `std_profiles` (Student module); never duplicates student master
- TC fee check: reads from `fin_*` (Finance module); never writes to `fin_*`
- After TC issuance: writes `std_students.tc_issued = true` (authorised cross-module write, documented in BR-CRT-011)

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 9 (from req spec Section 2.3) |
| Models | 10 |
| Services | 3 |
| FormRequests | 10 (from req spec Section 15) |
| Policies | 8 |
| Jobs | 1 (BulkGenerateCertificatesJob) |
| crt_* tables | 10 |
| Blade views (estimated) | ~30 |
| Web routes | ~58 |
| API routes | 2 (verify JSON + public verify page) |

### Complete Table Inventory

**Template & Type (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `crt_certificate_types` | Type definitions | UNIQUE `(code)` |
| 2 | `crt_templates` | HTML/CSS templates | FK → crt_certificate_types; `is_default` toggle |
| 3 | `crt_template_versions` | Archived template snapshots | FK → crt_templates; `version_no` sequential |

**Workflow (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 4 | `crt_requests` | Request FSM | UNIQUE `(request_no)`; INDEX `(beneficiary_student_id, certificate_type_id, status)` |
| 5 | `crt_issued_certificates` | All issued certificates | UNIQUE `(certificate_no)`, UNIQUE `(verification_hash)` |

**TC & Serial (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 6 | `crt_tc_register` | Formal TC logbook | UNIQUE `(sl_no, academic_year)` |
| 7 | `crt_serial_counters` | Per-type, per-year counter | UNIQUE `(certificate_type_id, academic_year)` |
| 8 | `crt_bulk_jobs` | Async bulk generation tracker | — |

**ID Card & DMS (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 9 | `crt_id_card_configs` | ID card template config | — |
| 10 | `crt_student_documents` | Incoming student documents (DMS) | FK → std_students, sys_media |

**NOTE:** `crt_verification_logs` is NOT a standalone table — verification events are written to `sys_activity_logs` (polymorphic). Refer to req v2 Section 4 (FR-CRT-007) for exact logging fields.

**Existing Tables REUSED (Certificate reads from; never modifies schema unless documented):**
| Table | Source | Certificate Usage |
|---|---|---|
| `std_students` | StudentProfile (STD) | Name, DOB, admission_no, blood_group, tc_issued flag (written on TC issuance) |
| `std_profiles` | StudentProfile (STD) | Father name, mother name, nationality, religion |
| `sch_academic_sessions` | SchoolSetup (SCH) | Academic year for serial counter reset + merge field |
| `sch_classes`, `sch_sections` | SchoolSetup (SCH) | Class/section label for merge fields |
| `sch_school_profiles` | SchoolSetup (SCH) | School name, address, principal name for template merge |
| `fin_fee_dues` | StudentFee (FIN) | TC issuance eligibility check (BR-CRT-001) |
| `sys_media` | System | Logo, seal, student photos, DMS document storage |
| `sys_dropdown_table` | System | DMS document categories |
| `sys_users` | System | All `created_by`, `approved_by`, `issued_by`, `verified_by`, etc. |
| `sys_activity_logs` | System | Audit trail — all data-changing actions + verification events |
| `ntf_notifications` | Notification (NTF) | Request submission, approval, rejection notifications |

### Cross-Module Integration (TC Post-Hooks)
```
On TC Generation:
  Write std_students.tc_issued = true
  Write std_students.status = 'withdrawn'
  → Done inside CertificateGenerationService::generateTC()
  → Post-generation hook, not an event (direct model update)

On Certificate Request Approved:
  → Fire event to Notification module: email/SMS to requester
  (Notification module owns listener)

On Bulk Job Completed:
  → Notify initiating admin via NTF module
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — CRT v2 requirement (12 FRs, Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: std_students, std_profiles, sch_academic_sessions, sch_classes, sch_sections, sch_school_profiles, sys_users, sys_media, sys_dropdown_table (use exact column names in spec)

### Phase 1 Task — Generate `CRT_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope sub-modules (L1–L8: Type/Template, Request Workflow, Generation, TC, Bulk, Verification, ID Cards, DMS — verbatim from req v2 Section 2.3)
- Out-of-scope items (student master management `std_*`, fee calculation `fin_*`, depreciation, student portal display [owned by STP/PPT])
- Module scale table (controller / model / service / job / FormRequest / policy / table / view counts)

#### Section 2 — Entity Inventory (All 10 Tables)
For each `crt_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Type & Template** (crt_certificate_types, crt_templates, crt_template_versions)
- **Workflow** (crt_requests, crt_issued_certificates)
- **TC & Serial** (crt_tc_register, crt_serial_counters, crt_bulk_jobs)
- **ID Card & DMS** (crt_id_card_configs, crt_student_documents)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 10 tables grouped by layer (crt_* vs cross-module reads from std_*/sch_*/fin_*/sys_*).
Use `→` for FK direction (child → parent).

Critical cross-module FKs to highlight:
- `crt_requests.beneficiary_student_id → std_students.id`
- `crt_issued_certificates.template_id → crt_templates.id` (ON DELETE RESTRICT — BR-CRT-006)
- `crt_tc_register.issued_certificate_id → crt_issued_certificates.id`
- `crt_serial_counters.certificate_type_id → crt_certificate_types.id` with UNIQUE `(certificate_type_id, academic_year)`
- `crt_student_documents.student_id → std_students.id`
- `crt_student_documents.media_id → sys_media.id`

#### Section 4 — Business Rules (15 rules)
For each rule, state:
- Rule ID (BR-CRT-001 to BR-CRT-015)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event`

Critical rules to emphasise:
- BR-CRT-001: TC blocked if `fin_fee_dues > 0` unless admin override — `CertificateGenerationService::generateTC()` + policy
- BR-CRT-002: TC `sl_no` sequential, year-wise, no gaps — `SerialCounter::nextForType()` with `SELECT FOR UPDATE`
- BR-CRT-003: Second issuance → `is_duplicate = true` with "DUPLICATE COPY" watermark
- BR-CRT-005: Revoked certificates remain in DB; verification returns REVOKED (not 404)
- BR-CRT-006: `crt_templates` with referenced issued certs cannot be hard-deleted — FK `ON DELETE RESTRICT`
- BR-CRT-009: Bulk generation > 200 certificates MUST use queue; synchronous forbidden above threshold
- BR-CRT-010: Public verification must NOT expose full name, DOB, class, or address
- BR-CRT-011: TC issuance writes `std_students.tc_issued = true` + status = `withdrawn`
- BR-CRT-015: Serial counter increment uses `SELECT ... FOR UPDATE` in DB transaction — no race conditions
- **No `tenant_id` column** — isolation at DB level via stancl/tenancy

#### Section 5 — Workflow State Machines (4 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, post-hooks)

FSMs to document:
1. **Certificate Request Lifecycle** — `pending → under_review → approved/rejected → generated → issued`
   - If `requires_approval = false`: skip to `approved` immediately on submission
   - On `approved`: `CertificateGenerationService::generateFromRequest()` triggered
   - On `generated`: `crt_issued_certificates` row created; status waits for physical handover
   - Side effects: NTF events on submission + approval/rejection + generation success
2. **Certificate Generation Flow** — Admin direct / Bulk
   - `SerialCounter::nextForType()` [SELECT FOR UPDATE] → DomPDF render → PDF store → write `crt_issued_certificates` (HMAC hash) → if TC: write `crt_tc_register` + update `std_students`
   - Side effects: verification hash generation; QR code embedded in PDF
3. **QR Verification Flow** — `hash lookup → VALID / EXPIRED / REVOKED / NOT_FOUND` → log to `sys_activity_logs`
4. **Bulk Generation Job FSM** — `queued → processing → completed/failed`
   - On `completed`: ZIP created; download link available
   - Individual per-student failures logged to `error_log_json`; batch does not abort

#### Section 6 — Functional Requirements Summary (12 FRs)
For each FR-CRT-001 to FR-CRT-012:
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by sub-module (L1–L8 per req v2 Sections 4.1–4.8).

#### Section 7 — Permission Matrix
| Permission String | Admin | Principal | Clerk/FO | Class Teacher | Student | Parent |
|---|---|---|---|---|---|---|

Derive permissions from req v2 Section 3 (Stakeholders & Roles). Include:
- `certificate.type.*` (CRUD for certificate types)
- `certificate.template.*` (CRUD for templates)
- `certificate.request.create` (student/parent/clerk can submit)
- `certificate.request.approve` (admin/principal only)
- `certificate.request.reject` (admin/principal only)
- `certificate.issued.view`
- `certificate.issued.download`
- `certificate.issued.revoke` (admin only)
- `certificate.bulk-generate`
- `certificate.id-card.*`
- `certificate.documents.upload`
- `certificate.documents.verify` (admin only)
- `certificate.reports.view`
Which Policy class enforces each permission (8 policies from req v2 Section 15)

#### Section 8 — Service Architecture (3 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\Certificate\app\Services
Depends on:  [other services it calls]
Fires:       [events it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **CertificateGenerationService** — generateFromRequest, generateDirect, generateTC, resolveMergeFields, generateCertificateNo; DomPDF rendering; PDF storage at `storage/tenant_{id}/certificates/{type}/{YYYY}/`; HMAC-SHA256 hash generation; post-TC hook (tc_issued flag + student status update)
2. **QrVerificationService** — generateVerificationHash (HMAC-SHA256 of `certificate_no + issue_date + recipient_id + APP_KEY`), generateQrCode (returns base64 PNG via SimpleSoftwareIO), verifyHash (lookup + status determination + log to sys_activity_logs)
3. **DmsService** — uploadDocument, verifyDocument, getDocumentsByStudent, hasVerifiedDocument; polymorphic `sys_media` integration; eligibility check for TC issuance (BR-CRT-008)

Include the certificate generation sequence as inline pseudocode in `CertificateGenerationService`:
```
generateFromRequest(CertificateRequest $request): CertificateIssued
  Step 1: Verify request status == 'approved'
  Step 2: Load certificate type + active default template
  Step 3: Resolve merge fields from std_students, std_profiles, sch_academic_sessions
  Step 4: DB transaction begins
  Step 5: SerialCounter::nextForType($type, $year) [SELECT FOR UPDATE]
           → increments last_seq_no, returns formatted certificate_no
  Step 6: Check if prior certificate exists for same student + type → set is_duplicate = true if so
  Step 7: QrVerificationService::generateVerificationHash($cert)
  Step 8: QrVerificationService::generateQrCode($verificationUrl) → embed in template HTML
  Step 9: DomPDF renders template with resolved merge fields + QR → stores PDF
  Step 10: Create crt_issued_certificates (certificate_no, verification_hash, file_path, is_duplicate)
  Step 11: If type == 'TC':
            → Write crt_tc_register (sl_no via serial counter, all state-board fields)
            → Update std_students.tc_issued = true, status = 'withdrawn'
  Step 12: Update crt_requests.status = 'generated'
  Step 13: DB transaction commits
  Step 14: Fire notification event (NTF module listener sends email/SMS to requester)
```

#### Section 9 — Integration Contracts (3 events/hooks)
For each integration point:
| Event / Hook | Fired By | Listener Module | Payload | Action |
|---|---|---|---|---|
- `CertificateRequestApproved` (or equivalent NTF trigger) → Notification → Email/SMS to requester
- `CertificateGenerated` → Notification → Email/SMS with download link
- TC post-hook → std_students write (direct, not event) — `tc_issued=true`, `status=withdrawn`

Document the notification payload structure for `CertificateRequestApproved`.

#### Section 10 — Non-Functional Requirements
From req v2 Sections 10.1–10.6.
For each NFR, add an "Implementation Note" column explaining HOW it will be met in code:
- Single PDF generation: < 3 seconds — DomPDF single-page; QR embedded as base64 (no HTTP fetch)
- Bulk generation throughput: > 50 certificates/minute — queue worker; configurable concurrency
- Public verification: < 500ms — single hash lookup + log insert; no auth overhead
- Serial counter concurrency: `SELECT ... FOR UPDATE` in DB transaction (BR-CRT-015)
- Tenant-isolated file paths: `storage/tenant_{id}/certificates/` via stancl/tenancy disk config
- Certificate download access: `Storage::temporaryUrl()` or signed route — authorised users only
- Public verification privacy: response DTO exposes only first name + last initial + school name (BR-CRT-010)
- Rate limiting on public `/verify/{hash}`: 20 verifications per IP per hour (suggestion S06)
- DMS file upload: max 5 MB; MIME type whitelist in `DocumentUploadRequest`

#### Section 11 — Test Plan Outline
From req v2 Sections 12 (T01–T30):

**Feature Tests (Pest) — 8 test files:**
| File | Key Scenarios |
|---|---|
(List all test files covering: certificate types, templates+versioning, request workflow, generation+issuance, TC+register, bulk jobs, verification, DMS+eligibility)

**Unit Tests (PHPUnit) — 3 test files:**
| File | Key Scenarios |
|---|---|
(Cover: SerialCounterTest — SELECT FOR UPDATE uniqueness; QrVerificationServiceTest — hash + QR gen; MergeFieldResolverTest — all 17 merge fields resolve correctly)

**Policy Tests:**
- `CertificatePolicyTest` — Student can request own cert; Principal can approve TC; Clerk cannot revoke; Student cannot view other students' certs

**Test Data:**
- Required seeders for test DB: CrtCertificateTypeSeeder (5 types), CrtTemplateSeeder (5 templates)
- Required factories: CertificateTypeFactory, CertificateTemplateFactory, CertificateRequestFactory, CertificateIssuedFactory
- Mock strategy: `Queue::fake()` for BulkGenerateCertificatesJob; `Event::fake()` for notification triggers; `Storage::fake()` for PDF file storage; mock `fin_*` fee check in TC tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `CRT_FeatureSpec.md` | `{OUTPUT_DIR}/CRT_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 10 crt_* tables appear in Section 2 entity inventory
- [ ] All 12 FRs (CRT-001 to CRT-012) appear in Section 6
- [ ] All 15 business rules (BR-CRT-001 to BR-CRT-015) in Section 4 with enforcement point
- [ ] All 4 FSMs documented with ASCII state diagram and side effects
- [ ] All 3 services listed with key method signatures in Section 8
- [ ] Certificate generation 14-step pseudocode present in CertificateGenerationService
- [ ] All 3 integration contracts documented in Section 9
- [ ] `crt_issued_certificates.verification_hash` noted as HMAC-SHA256 of `(certificate_no + issue_date + recipient_id + APP_KEY)`
- [ ] `crt_issued_certificates.template_id → crt_templates.id` noted as ON DELETE RESTRICT (BR-CRT-006)
- [ ] `crt_serial_counters` UNIQUE on `(certificate_type_id, academic_year)` noted
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] `SerialCounter::nextForType()` concurrency note: `SELECT FOR UPDATE` in DB transaction (BR-CRT-015)
- [ ] BR-CRT-001 (TC fee-clear gate) explicitly documented in CertificateGenerationService
- [ ] BR-CRT-009 (bulk > 200 = queue mandatory) explicitly documented in BulkGenerationController
- [ ] BR-CRT-010 (public verification privacy) enforcement noted in QrVerificationService response DTO
- [ ] BR-CRT-011 (TC → std_students write) documented as post-hook in CertificateGenerationService
- [ ] Permission matrix covers Admin / Principal / Clerk / Class Teacher / Student / Parent roles
- [ ] All cross-module column names verified against tenant_db_v2.sql (use EXACT names from DDL)

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/CRT_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/CRT_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 10 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`CRT_DDL_v1.sql`)

Generate CREATE TABLE statements for all 10 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**

1. Table prefix: `crt_` for all tables — no exceptions
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (not applicable to CRT — no pure junction tables)
5. JSON columns: suffix `_json` (e.g. `variables_json`, `signature_placement_json`, `filter_json`, `error_log_json`, `template_json`)
6. Boolean flag columns: prefix `is_` or `has_`
7. All IDs and FK references: `BIGINT UNSIGNED` (consistency with tenant_db convention)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_crt_{tableshort}_{column}` (e.g. `fk_crt_tpl_certificate_type_id`)
12. **Do NOT recreate std_*, sch_*, fin_*, sys_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `crt_template_versions`: NO deleted_at column — versions are immutable archive records (never soft-deleted)

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No crt_* dependencies (may reference sys_* only):
  `crt_certificate_types` (no crt_* deps — references sys_users only),
  `crt_id_card_configs` (no crt_* deps — references sch_academic_sessions)

Layer 2 — Depends on Layer 1:
  `crt_templates` (→ crt_certificate_types CASCADE DELETE),
  `crt_serial_counters` (→ crt_certificate_types),
  `crt_bulk_jobs` (→ crt_certificate_types),
  `crt_student_documents` (→ std_students + sys_media + sys_dropdown_table)

Layer 3 — Depends on Layer 2:
  `crt_template_versions` (→ crt_templates CASCADE DELETE),
  `crt_requests` (→ crt_certificate_types + std_students nullable + sys_users)

Layer 4 — Depends on Layer 3:
  `crt_issued_certificates` (→ crt_certificate_types + crt_templates RESTRICT + crt_requests nullable + sys_users)

Layer 5 — Depends on Layer 4:
  `crt_tc_register` (→ crt_issued_certificates + sys_users)

**Critical unique constraints to include:**
```sql
-- crt_certificate_types
UNIQUE KEY uq_crt_ct_code (code)

-- crt_templates
-- No unique — multiple templates per type allowed; is_default enforced in application layer

-- crt_issued_certificates
UNIQUE KEY uq_crt_ic_certificate_no (certificate_no)
UNIQUE KEY uq_crt_ic_verification_hash (verification_hash)

-- crt_serial_counters
UNIQUE KEY uq_crt_sc_type_year (certificate_type_id, academic_year)

-- crt_tc_register
UNIQUE KEY uq_crt_tc_sl_year (sl_no, academic_year)

-- crt_requests
-- Composite index (not unique — status varies): INDEX idx_crt_req_student_type_status (beneficiary_student_id, certificate_type_id, status)
```

**ENUM values (exact, to match application code):**
```
crt_certificate_types.category:         'administrative','legal','character','achievement','identity'
crt_templates.page_size:               'a4','a5','letter','custom'
crt_templates.orientation:             'portrait','landscape'
crt_requests.requester_type:           'student','parent','staff','admin'
crt_requests.status:                   'pending','under_review','approved','rejected','generated','issued'
crt_issued_certificates.recipient_type: 'student','staff'
crt_bulk_jobs.status:                  'queued','processing','completed','failed'
crt_id_card_configs.card_type:         'student','staff'
crt_id_card_configs.card_size:         'a5','cr80'
crt_id_card_configs.orientation:       'portrait','landscape'
crt_student_documents.verification_status: 'pending','verified','rejected'
```

**Critical columns to get right:**
- `crt_templates.template_content`: `LONGTEXT NOT NULL` — HTML/CSS template body
- `crt_templates.variables_json`: `JSON NOT NULL` — array of merge field names declared in template
- `crt_templates.signature_placement_json`: `JSON NULL` — x/y coordinates + dimensions for digital signature block
- `crt_templates.is_default`: `TINYINT(1) NOT NULL DEFAULT 0` — only one per type (application-enforced toggle)
- `crt_template_versions.version_no`: `SMALLINT UNSIGNED NOT NULL` — auto-incremented per template
- `crt_template_versions`: **NO deleted_at column** (immutable archive — DDL rule 14)
- `crt_issued_certificates.request_id`: `BIGINT UNSIGNED NULL` — NULL for direct-issue (achievement/bulk)
- `crt_issued_certificates.validity_date`: `DATE NULL` — NULL means no expiry
- `crt_issued_certificates.verification_hash`: `VARCHAR(64) NOT NULL` — HMAC-SHA256 hex string
- `crt_issued_certificates.is_revoked`: `TINYINT(1) NOT NULL DEFAULT 0`
- `crt_issued_certificates.is_duplicate`: `TINYINT(1) NOT NULL DEFAULT 0`
- `crt_serial_counters.last_seq_no`: `INT UNSIGNED NOT NULL DEFAULT 0`
- `crt_serial_counters.academic_year`: `SMALLINT UNSIGNED NOT NULL` — 4-digit year (e.g. 2026)
- `crt_bulk_jobs.filter_json`: `JSON NULL` — stores class_id, section_id, student_ids filter
- `crt_bulk_jobs.error_log_json`: `JSON NULL` — per-student failure log
- `crt_tc_register.sl_no`: `SMALLINT UNSIGNED NOT NULL` — sequential per year (gaps forbidden, BR-CRT-002)
- `crt_tc_register.academic_year`: `SMALLINT UNSIGNED NOT NULL` — 4-digit year

**File header comment to include:**
```sql
-- =============================================================================
-- CRT — Certificate & Template Module DDL
-- Module: Certificate (Modules\Certificate)
-- Table Prefix: crt_* (10 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: CRT_Certificate_Requirement.md v2
-- Sub-Modules: L1 Type/Template, L2 Requests, L3 Generation, L4 TC (Legal),
--              L5 Bulk Jobs, L6 Verification, L7 ID Cards, L8 DMS
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`CRT_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_crt_tables.php`.
- `up()`: creates all 10 tables in Layer 1 → Layer 5 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 5 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, JSON with `->json()`, text with `->longText()`
- All FK constraints added in `up()` using `$table->foreign()`
- Note: `crt_template_versions` — do NOT add `$table->softDeletes()` (DDL rule 14 — immutable archive)

### Phase 2C Task — Generate Seeders (2 seeders + 1 runner)

Namespace: `Modules\Certificate\Database\Seeders`

**1. `CrtCertificateTypeSeeder.php`** — 5 seeded certificate types (`is_active=1`):
```
Bonafide Certificate   | code: BON  | category: administrative | requires_approval: true  | validity_days: 180 | serial_format: {TYPE_CODE}-{YYYY}-{SEQ6}
Transfer Certificate   | code: TC   | category: legal          | requires_approval: true  | validity_days: NULL | serial_format: {TYPE_CODE}-{YYYY}-{SEQ4}
Character Certificate  | code: CHR  | category: character      | requires_approval: true  | validity_days: 365 | serial_format: {TYPE_CODE}-{YYYY}-{SEQ6}
Merit Certificate      | code: MRT  | category: achievement    | requires_approval: false | validity_days: NULL | serial_format: {TYPE_CODE}-{YYYY}-{SEQ6}
Sports Certificate     | code: SPT  | category: achievement    | requires_approval: false | validity_days: NULL | serial_format: {TYPE_CODE}-{YYYY}-{SEQ6}
```

**2. `CrtTemplateSeeder.php`** — Seed 5 starter templates (one per type above), each with:
- Minimal HTML boilerplate with `{{school_name}}`, `{{student_name}}`, `{{certificate_no}}`, `{{issue_date}}`, `{{principal_name}}` as mandatory merge fields
- `variables_json` declaring the 5 merge field names
- `is_default = true`, `page_size = 'a4'`, `orientation = 'portrait'`
- `version_no = 1` in corresponding `crt_template_versions` row
- Note: seeder should insert template first, then template_version row referencing it

**3. `CrtSeederRunner.php`** (Master seeder, calls all in order):
```php
$this->call([
    CrtCertificateTypeSeeder::class,  // no dependencies
    CrtTemplateSeeder::class,         // depends on CrtCertificateTypeSeeder (for certificate_type_id)
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `CRT_DDL_v1.sql` | `{OUTPUT_DIR}/CRT_DDL_v1.sql` |
| `CRT_Migration.php` | `{OUTPUT_DIR}/CRT_Migration.php` |
| `CRT_TableSummary.md` | `{OUTPUT_DIR}/CRT_TableSummary.md` |
| `Seeders/CrtCertificateTypeSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/CrtTemplateSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/CrtSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 10 crt_* tables exist in DDL (3 Type/Template + 2 Workflow + 3 TC/Serial + 2 ID/DMS = 10 ✓)
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on ALL 10 tables EXCEPT `crt_template_versions` (no deleted_at — DDL rule 14)
- [ ] `crt_template_versions` does NOT have a `deleted_at` column
- [ ] `crt_issued_certificates.verification_hash` is `VARCHAR(64) NOT NULL` with UNIQUE index
- [ ] `crt_issued_certificates.request_id` is nullable (NULL for direct-issue certificates)
- [ ] `crt_issued_certificates.template_id → crt_templates.id` FK uses `ON DELETE RESTRICT`
- [ ] `crt_serial_counters` UNIQUE on `(certificate_type_id, academic_year)`
- [ ] `crt_tc_register` UNIQUE on `(sl_no, academic_year)`
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] `crt_templates.template_content` is `LONGTEXT` (not TEXT or VARCHAR)
- [ ] `crt_templates.variables_json` and `signature_placement_json` are JSON columns (not TEXT)
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_crt_` convention throughout
- [ ] CrtCertificateTypeSeeder has all 5 types with correct `serial_format` values
- [ ] CrtTemplateSeeder inserts both template row AND template_version row per type
- [ ] `CrtSeederRunner.php` calls seeders in dependency order (TypeSeeder before TemplateSeeder)
- [ ] `CRT_TableSummary.md` has one-line description for all 10 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `CRT_DDL_v1.sql` + Migration + 3 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/CRT_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 12 (test cases T01–T30), Section 14 (implementation suggestions), Section 15 (file list)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `CRT_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 6 (routes). For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (9 total, from req v2 Section 2.3):
1. `CertificateTypeController` — index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus, dashboard
2. `CertificateTemplateController` — index, create, store, show, edit, update, destroy, preview, versions, restoreVersion
3. `CertificateRequestController` — index, create, store, show, approve, reject
4. `CertificateIssuedController` — index, show, download, revoke, tcRegister
5. `BulkGenerationController` — index, generate, status (JSON polling), download (ZIP)
6. `IdCardController` — indexConfig, createConfig, storeConfig, editConfig, updateConfig, generateForm, generate, markReceived
7. `DocumentManagementController` — index, upload, show, verify, download
8. `VerificationController` — verify (public — no auth), logs (admin — auth)
9. `CertificateReportController` — issued, pending, analytics (JSON endpoint)

#### Section 2 — Service Inventory (3 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events fired / hooks executed
- Other services called (dependency graph)

Include the generation sequence pseudocode (14 steps) for `CertificateGenerationService` as documented in Phase 1 Section 8.

Include the serial counter concurrency pseudocode in `QrVerificationService`:
```
incrementSerialCounter(CertificateType $type, int $year): string
  Step 1: DB::transaction begins
  Step 2: $counter = CrtSerialCounter::where(['certificate_type_id'=>$type->id, 'academic_year'=>$year])
              ->lockForUpdate()->firstOrCreate(...)
  Step 3: $counter->increment('last_seq_no')
  Step 4: DB::transaction commits
  Step 5: Return formatCertificateNo($type->serial_format, $type->code, $year, $counter->last_seq_no)
```

#### Section 3 — FormRequest Inventory (10 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

10 total (from req v2 Section 15):
- `StoreCertificateTypeRequest` — name required, code required alphanumeric max 10, category valid enum, validity_days nullable integer min 1, serial_format required with valid tokens
- `StoreCertificateTemplateRequest` — certificate_type_id exists in crt_certificate_types, template_content required, variables_json required array (all `{{field}}` in content must appear), page_size valid enum, orientation valid enum
- `StoreCertificateRequestRequest` — certificate_type_id exists + is_active, beneficiary_student_id exists in std_students, purpose required, required_by_date nullable `after:today`; duplicate check: no pending/under_review/approved request for same student + type
- `ApproveCertificateRequestRequest` — approval_remarks nullable string max 500
- `RejectCertificateRequestRequest` — rejection_reason required string (BR-CRT-013)
- `RevokeCertificateRequest` — revocation_reason required string
- `BulkGenerateCertificatesRequest` — certificate_type_id exists, class_id optional, section_id optional, student_ids optional array (at least one of class_id or student_ids required)
- `StoreIdCardConfigRequest` — card_type valid enum, name required, card_size valid enum, orientation valid enum, cards_per_sheet integer 1–20
- `DocumentUploadRequest` — student_id exists in std_students, document_category_id exists in sys_dropdown_table, file required MIME in [pdf,jpeg,png] max 5MB
- `VerifyDocumentRequest` — verification_status in [verified,rejected], verification_remarks required_if:verification_status,rejected

#### Section 4 — Blade View Inventory (~30 views)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and screen counts (from req v2 Section 7 CRT-S01 to CRT-S26):
- Dashboard: 1 view (CRT-S01)
- Certificate Types: 2 views — index + create/edit form (CRT-S02, CRT-S03)
- Templates: 4 views — index, designer, preview, version history (CRT-S04 to CRT-S07)
- Requests: 3 views — queue index, create form, review/show (CRT-S08 to CRT-S10)
- Issued: 2 views — register, certificate detail (CRT-S11, CRT-S12)
- Bulk Generation: 1 view — form + progress bar (CRT-S13)
- ID Cards: 3 views — config list, config form, generate form (CRT-S14 to CRT-S16)
- DMS: 3 views — document list, upload, document view+verify (CRT-S17 to CRT-S19)
- Verification & TC: 2 views — verification logs, TC register (CRT-S20, CRT-S21)
- Reports: 3 views — issued register, pending requests, type analytics (CRT-S22 to CRT-S24)
- Public: 1 view — no-login verification result (CRT-S25)
- Portal: 1 view — student/parent portal my-certificates (CRT-S26)
- Shared partials: ~4 partials (pagination, export buttons, status badge, QR preview)

For key screens document:
- Template Designer (CRT-S05) — HTML/CSS textarea + merge field chip list + live preview pane (AJAX call to `preview` endpoint)
- Bulk Generation (CRT-S13) — Class/section picker + JS polling of `/bulk-generate/{job}/status` every 3s
- Public Verification Page (CRT-S25) — VALID/EXPIRED/REVOKED banner; strict DTO: first name + last initial + school name only (BR-CRT-010)

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by section (6.1 Web Routes, 6.2 Public Routes, 6.3 API Routes). Count total routes at the end (target ~60).
- Web routes middleware: `['auth', 'verified', 'tenant', 'EnsureTenantHasModule:Certificate']`
- Public route `/verify/{hash}`: **NO auth middleware** — accessible by third parties with no login
- API route `/api/v1/certificate/verify`: API key authentication (query param `api_key`)

#### Section 6 — Implementation Phases (4 phases)

For each phase, provide a detailed sprint plan:

**Phase 1 — Foundation: Types, Templates, DDL, Seeders** (no cross-module deps beyond sys_*):
FRs: CRT-001, CRT-002, CRT-010
Files to create:
- DDL/Migration (from Phase 2)
- Seeders: CrtCertificateTypeSeeder, CrtTemplateSeeder, CrtSeederRunner
- Models: CertificateType, CertificateTemplate, CertificateTemplateVersion, SerialCounter
- Controllers: CertificateTypeController (full CRUD + toggleStatus + dashboard), CertificateTemplateController (full CRUD + preview + versions + restoreVersion)
- FormRequests: StoreCertificateTypeRequest, StoreCertificateTemplateRequest
- Services: QrVerificationService (generateVerificationHash, generateQrCode, incrementSerialCounter stubs)
- Views: CRT-S01, CRT-S02, CRT-S03, CRT-S04, CRT-S05, CRT-S06, CRT-S07
- Tests: CertificateTypeTest (duplicate code, toggleStatus), CertificateTemplateTest (versioning, default toggle)

**Phase 2 — Request Workflow + Core Generation** (requires std_*, sch_*):
FRs: CRT-003, CRT-004, CRT-007
Files to create:
- Models: CertificateRequest, CertificateIssued
- Controllers: CertificateRequestController (index, create, store, show, approve, reject), CertificateIssuedController (index, show, download, revoke), VerificationController (verify public + logs admin)
- Services: CertificateGenerationService (full — all 14 steps), QrVerificationService (complete — verifyHash + log)
- Jobs: BulkGenerateCertificatesJob (stub — full in Phase 3)
- FormRequests: StoreCertificateRequestRequest, ApproveCertificateRequestRequest, RejectCertificateRequestRequest, RevokeCertificateRequest
- Policies: CertificateRequestPolicy, CertificateIssuedPolicy
- Views: CRT-S08, CRT-S09, CRT-S10, CRT-S11, CRT-S12, CRT-S25
- Tests: CertificateRequestWorkflowTest (FSM transitions), CertificateGenerationTest (merge fields, hash, PDF store), QrVerificationTest (VALID/EXPIRED/REVOKED/NOT_FOUND), SerialCounterTest (SELECT FOR UPDATE concurrency)

**Phase 3 — TC, Bulk Jobs, ID Cards** (requires fin_* for TC fee check):
FRs: CRT-005, CRT-006, CRT-008
Files to create:
- Models: TcRegister, BulkJob, IdCardConfig, IdCardIssued
- Controllers: BulkGenerationController (full — generate + status polling + ZIP download), IdCardController (full)
- Services: CertificateGenerationService::generateTC() (complete — fee check + tc_register + std_students write)
- Jobs: BulkGenerateCertificatesJob (full implementation — per-student loop, error_log_json, ZIP)
- FormRequests: BulkGenerateCertificatesRequest, StoreIdCardConfigRequest
- Views: CRT-S13, CRT-S14, CRT-S15, CRT-S16, CRT-S21
- Tests: TcRegistrationTest (BR-CRT-001 fee gate, BR-CRT-002 sl_no sequence, BR-CRT-011 std_students write), BulkGenerationTest (> 200 → queue, per-student failure logged), IdCardGenerationTest

**Phase 4 — DMS, Reports, Portal, Artisan** (reads sys_media, sys_dropdown_table):
FRs: CRT-009, CRT-011, CRT-012
Files to create:
- Models: StudentDocument
- Controllers: DocumentManagementController (full), CertificateReportController (issued + pending + analytics JSON)
- Services: DmsService (full — upload, verify, eligibility check)
- Artisan: `certificate:expire-certificates` (daily — flags `validity_date < today` in `sys_activity_logs`)
- FormRequests: DocumentUploadRequest, VerifyDocumentRequest
- Views: CRT-S17, CRT-S18, CRT-S19, CRT-S20, CRT-S22, CRT-S23, CRT-S24, CRT-S26 (portal partial)
- Tests: DmsTest (upload, verify, BR-CRT-008 rejected doc blocks TC eligibility), CertificateReportTest (export Excel, analytics JSON structure), CertificatePortalTest (own certs only — BR-CRT-012 privacy)

#### Section 7 — Seeder Execution Order

```
php artisan module:seed Certificate --class=CrtSeederRunner
  ↓ CrtCertificateTypeSeeder    (no dependencies)
  ↓ CrtTemplateSeeder           (depends on CrtCertificateTypeSeeder — uses certificate_type_id)
```

For test runs: use `CrtCertificateTypeSeeder` as minimum (needed for any request/generation test).
For Phase 2+ tests: add `CrtTemplateSeeder` (required for PDF generation — default template).

Artisan scheduled commands (register in `routes/console.php`):
```
certificate:expire-certificates    → daily midnight
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// Queue::fake() in BulkGenerateCertificatesJob tests
// Event::fake() for notification trigger tests
// Storage::fake() for PDF and DMS file upload tests
// Mock fin_* fee check: stub CertificateGenerationService or mock StudentFee query directly
```

**Minimum Test Coverage Targets:**
- BR-CRT-001 (TC fee gate): explicitly tested — fee_dues > 0 blocks TC; admin override allows it
- BR-CRT-002 (TC sl_no sequential): TcRegistrationTest — 3 concurrent TCs produce sl_no 1, 2, 3 with no gaps
- BR-CRT-003 (duplicate issuance watermark): second issuance sets `is_duplicate = true`
- BR-CRT-005 (revoked cert → REVOKED not 404): VerificationController returns REVOKED status
- BR-CRT-009 (> 200 certs → queue mandatory): BulkGenerationTest — 201 students dispatches job; 50 students is synchronous
- BR-CRT-010 (public verification privacy): response JSON/HTML does NOT contain full_name, dob, class, section
- BR-CRT-011 (TC → std_students write): TcRegistrationTest — `std_students.tc_issued = 1` and `status = 'withdrawn'` after TC generation
- BR-CRT-015 (SELECT FOR UPDATE): SerialCounterTest — concurrent generation produces unique sequential cert numbers

**Feature Test File Summary (derive from req v2 T01–T30):**
List all feature test files with file path, test count mapping to T01–T30 scenarios.

**Unit Test File Summary:**
List 3 unit test files: SerialCounterTest, QrVerificationServiceTest, MergeFieldResolverTest.

**Factory Requirements:**
```
CertificateTypeFactory      — generates type with code, category, requires_approval
CertificateTemplateFactory  — generates template with LONGTEXT content + variables_json
CertificateRequestFactory   — generates request_no (REQ-YYYY-NNN), status=pending
CertificateIssuedFactory    — generates certificate_no, verification_hash (sha256 placeholder)
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `CRT_Dev_Plan.md` | `{OUTPUT_DIR}/CRT_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 9 controllers listed with all methods
- [ ] All 3 services listed with at minimum 3 key method signatures each
- [ ] CertificateGenerationService 14-step pseudocode present
- [ ] QrVerificationService::incrementSerialCounter() 5-step SELECT FOR UPDATE pseudocode present
- [ ] All 10 FormRequests listed with their key validation rules
- [ ] All 12 FRs (CRT-001 to CRT-012) appear in at least one implementation phase
- [ ] All 4 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented with dependency note (TypeSeeder before TemplateSeeder)
- [ ] Artisan command `certificate:expire-certificates` listed with daily schedule
- [ ] Route list consolidated with middleware and FR reference (~60 routes total)
- [ ] Public `/verify/{hash}` route explicitly marked with NO auth middleware
- [ ] View count per sub-module totals approximately 30
- [ ] Test strategy includes Queue::fake() for BulkGenerateCertificatesJob
- [ ] Test strategy includes Storage::fake() for PDF + DMS file tests
- [ ] BR-CRT-001 (TC fee gate) test explicitly referenced
- [ ] BR-CRT-010 (public verification privacy) test explicitly referenced
- [ ] BR-CRT-015 (SELECT FOR UPDATE serial counter) test explicitly referenced

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `CRT_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/CRT_FeatureSpec.md`
2. `{OUTPUT_DIR}/CRT_DDL_v1.sql` + Migration + 3 Seeders
3. `{OUTPUT_DIR}/CRT_Dev_Plan.md`
Development lifecycle for CRT (Certificate) module is ready to begin."

---

## QUICK REFERENCE — CRT Module Tables vs Controllers vs Services

| Domain | crt_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Type & Template | crt_certificate_types, crt_templates, crt_template_versions | CertificateTypeController, CertificateTemplateController | QrVerificationService (serial format) |
| Requests | crt_requests | CertificateRequestController | CertificateGenerationService |
| Issuance | crt_issued_certificates | CertificateIssuedController | CertificateGenerationService, QrVerificationService |
| TC Register | crt_tc_register | CertificateIssuedController (tcRegister) | CertificateGenerationService::generateTC() |
| Serial Counters | crt_serial_counters | (internal — no direct routes) | QrVerificationService::incrementSerialCounter() |
| Bulk Jobs | crt_bulk_jobs | BulkGenerationController | CertificateGenerationService (via Job) |
| ID Cards | crt_id_card_configs | IdCardController | CertificateGenerationService (PDF render) |
| DMS | crt_student_documents | DocumentManagementController | DmsService |
| Verification (public) | (reads crt_issued_certificates) | VerificationController | QrVerificationService::verifyHash() |
| Reports | (reads crt_* tables) | CertificateReportController | — (direct queries) |
| Dashboard | (aggregates crt_* tables) | CertificateTypeController::dashboard() | — (direct queries) |
