# CRT — Certificate & Template Module Feature Specification
**Module:** CRT | **Version:** 1.0 | **Date:** 2026-03-27 | **Status:** Draft
**Based on:** `CRT_Certificate_Requirement.md` v2 (2026-03-26)

---

## DDL Correction Notice (Verified against `tenant_db_v2.sql`)

> The Phase 2 DDL prompt template states "All IDs and FK references: `BIGINT UNSIGNED`".
> This is **incorrect** for this codebase. Verified actual types:
>
> | Referenced Table | PK Column | Actual Type |
> |---|---|---|
> | `sys_users` | `id` | `INT UNSIGNED` |
> | `std_students` | `id` | `INT UNSIGNED` |
> | `sys_media` | `id` | `INT UNSIGNED` |
> | `sys_dropdown_table` | `id` | `INT UNSIGNED` |
> | `sch_org_academic_sessions_jnt` | `id` | `SMALLINT UNSIGNED` |
> | `sch_academic_term` | `id` | `SMALLINT UNSIGNED` |
>
> All FK columns in `crt_*` tables referencing these must use the matching type.
> All `crt_*` PKs use `INT UNSIGNED` (matching platform-wide convention).
>
> **Cross-module column correction — BR-CRT-011:**
> `std_students.tc_issued` and `std_students.status` columns do NOT exist in current `tenant_db_v2.sql`.
> - Student status is `std_students.current_status_id` (FK → `sys_dropdown_table.id`)
> - `tc_issued` flag must be added to `std_students` via a CRT module migration (ALTER TABLE)
> - "Withdrawn" state → update `std_students.current_status_id` to the `sys_dropdown_table` row where `key = 'std_students.current_status_id'` and `value = 'Withdrawn'`
>
> **Merge field `{{student_name}}` correction:**
> `std_students` has no `full_name` column. Name is stored as `first_name + middle_name + last_name`.
> `resolveMergeFields()` must concatenate these three columns.

---

## Section 1 — Module Identity

| Field | Value |
|---|---|
| Module Code | CRT |
| Human Name | Certificate & Template Management |
| Laravel Module Path | `Modules/Certificate` |
| Namespace | `Modules\Certificate` |
| Table Prefix | `crt_` |
| Database | `tenant_db` (one per school — **no `tenant_id` column** on any table) |
| Menu Path | School Admin Panel → Certificate |
| Dev Status | 0% — Greenfield |
| Proposed Tables | 10 (`crt_*`) |
| Proposed Controllers | 9 |
| Proposed Services | 3 |
| Proposed Jobs | 1 (`BulkGenerateCertificatesJob`) |
| Proposed Web Routes | ~58 |
| Proposed API Routes | 2 |
| Proposed Blade Views | ~30 |

**Sub-Module Map:**
| Layer | Sub-Module | Tables |
|---|---|---|
| L1 | Type & Template Management | `crt_certificate_types`, `crt_templates`, `crt_template_versions` |
| L2 | Request Workflow | `crt_requests` |
| L3 | Certificate Generation & Issuance | `crt_issued_certificates`, `crt_serial_counters` |
| L4 | TC Register (Legal) | `crt_tc_register` |
| L5 | Bulk Certificate Generation | `crt_bulk_jobs` |
| L6 | Digital Verification (QR + API) | reads `crt_issued_certificates`; logs → `sys_activity_logs` |
| L7 | ID Card Generation | `crt_id_card_configs` |
| L8 | Document Management System (DMS) | `crt_student_documents` |

**Package Dependencies:**
| Package | Version | Purpose | Installed |
|---|---|---|---|
| `barryvdh/laravel-dompdf` | v3.1 | PDF generation | Yes (via HPC module) |
| `simplesoftwareio/simple-qrcode` | v4.2 | QR code generation | Yes (via Transport module) |
| `stancl/tenancy` | v3.9 | Tenant isolation | Yes (platform-wide) |
| `nwidart/laravel-modules` | v12 | Module scaffolding | Yes (platform-wide) |
| Laravel Queue | Built-in | Async bulk generation | Yes |
| `maatwebsite/excel` | v3.x | Excel export | Verify installation |

---

## Section 2 — Entity Inventory

All 10 `crt_*` tables. No `tenant_id` column on any.

### 1. `crt_certificate_types`
**Purpose:** Master definitions for each certificate type (Bonafide, TC, Character, etc.)

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `name` | VARCHAR(150) NOT NULL | Display name |
| `code` | VARCHAR(10) NOT NULL | Alphanumeric, UNIQUE; e.g. `BON`, `TC` |
| `category` | ENUM('administrative','legal','character','achievement','identity') | |
| `requires_approval` | TINYINT(1) DEFAULT 1 | If 0 → auto-approve on submission |
| `validity_days` | SMALLINT UNSIGNED NULL | NULL = no expiry |
| `serial_format` | VARCHAR(100) NOT NULL | Token string e.g. `{TYPE_CODE}-{YYYY}-{SEQ6}` |
| `description` | TEXT NULL | |
| `is_active` | TINYINT(1) DEFAULT 1 | |
| Standard audit cols | | `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at` |

**Constraints:** `UNIQUE(code)`

---

### 2. `crt_templates`
**Purpose:** HTML/CSS certificate templates for each type.

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `certificate_type_id` | INT UNSIGNED NOT NULL FK → `crt_certificate_types.id` CASCADE | |
| `name` | VARCHAR(150) NOT NULL | Template display name |
| `template_content` | LONGTEXT NOT NULL | Full HTML/CSS body |
| `variables_json` | JSON NOT NULL | Array of declared merge field names |
| `page_size` | ENUM('a4','a5','letter','custom') DEFAULT 'a4' | |
| `orientation` | ENUM('portrait','landscape') DEFAULT 'portrait' | |
| `is_default` | TINYINT(1) DEFAULT 0 | Only one per type (app-enforced toggle) |
| `signature_placement_json` | JSON NULL | x/y coordinates + dimensions for digital signature block |
| `version_no` | SMALLINT UNSIGNED DEFAULT 1 | Tracks current version |
| Standard audit cols | | + `deleted_at` |

**FK:** `crt_templates.certificate_type_id` → `crt_certificate_types.id` ON DELETE CASCADE (soft-deleting type cascades to templates)

---

### 3. `crt_template_versions`
**Purpose:** Immutable archive of every prior template save.
> **No `deleted_at` column** — versions are never soft-deleted (DDL rule 14).

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `template_id` | INT UNSIGNED NOT NULL FK → `crt_templates.id` CASCADE | |
| `version_no` | SMALLINT UNSIGNED NOT NULL | Sequential per template |
| `template_content` | LONGTEXT NOT NULL | Snapshot of HTML at this version |
| `variables_json` | JSON NOT NULL | Snapshot of variables |
| `saved_by` | INT UNSIGNED NOT NULL FK → `sys_users.id` | User who triggered the save |
| `saved_at` | TIMESTAMP NOT NULL | When snapshot was taken |
| Standard audit cols | | `created_by`, `updated_by`, `created_at`, `updated_at` — **NO `deleted_at`** |

---

### 4. `crt_requests`
**Purpose:** Certificate request workflow records (6-state FSM).

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `request_no` | VARCHAR(30) NOT NULL UNIQUE | Format: `REQ-YYYY-000001` |
| `certificate_type_id` | INT UNSIGNED NOT NULL FK → `crt_certificate_types.id` RESTRICT | |
| `requester_type` | ENUM('student','parent','staff','admin') | Who submitted |
| `requester_id` | INT UNSIGNED NOT NULL | FK → `sys_users.id` |
| `beneficiary_student_id` | INT UNSIGNED NULL FK → `std_students.id` RESTRICT | NULL for staff certs |
| `purpose` | TEXT NOT NULL | Stated reason |
| `required_by_date` | DATE NULL | Urgency indicator |
| `supporting_doc_media_id` | INT UNSIGNED NULL FK → `sys_media.id` SET NULL | Polymorphic supporting doc (BR-CRT-014) |
| `status` | ENUM('pending','under_review','approved','rejected','generated','issued') DEFAULT 'pending' | |
| `approved_by` | INT UNSIGNED NULL FK → `sys_users.id` | |
| `approved_at` | TIMESTAMP NULL | |
| `approval_remarks` | TEXT NULL | |
| `rejection_reason` | TEXT NULL | Required when rejected (BR-CRT-013) |
| Standard audit cols | | + `deleted_at` |

**Indexes:** `INDEX idx_crt_req_student_type_status (beneficiary_student_id, certificate_type_id, status)` — for duplicate request check

---

### 5. `crt_issued_certificates`
**Purpose:** All generated certificates — both request-based and direct-issue.

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `certificate_no` | VARCHAR(50) NOT NULL UNIQUE | Generated by SerialCounter |
| `request_id` | INT UNSIGNED NULL FK → `crt_requests.id` SET NULL | NULL for direct/bulk/admin-initiated |
| `certificate_type_id` | INT UNSIGNED NOT NULL FK → `crt_certificate_types.id` RESTRICT | |
| `template_id` | INT UNSIGNED NOT NULL FK → `crt_templates.id` **ON DELETE RESTRICT** (BR-CRT-006) | |
| `recipient_type` | ENUM('student','staff') | |
| `recipient_id` | INT UNSIGNED NOT NULL | FK → `std_students.id` or `sys_users.id` (app-resolved) |
| `issue_date` | DATE NOT NULL | |
| `validity_date` | DATE NULL | NULL = no expiry |
| `verification_hash` | VARCHAR(64) NOT NULL UNIQUE | HMAC-SHA256 of `(certificate_no + issue_date + recipient_id + APP_KEY)` |
| `file_path` | VARCHAR(500) NOT NULL | `storage/tenant_{id}/certificates/{type}/{YYYY}/filename.pdf` |
| `is_revoked` | TINYINT(1) DEFAULT 0 | Revoked = DB stays, verification returns REVOKED (BR-CRT-005) |
| `revoked_at` | TIMESTAMP NULL | |
| `revoked_by` | INT UNSIGNED NULL FK → `sys_users.id` | |
| `revocation_reason` | TEXT NULL | |
| `is_duplicate` | TINYINT(1) DEFAULT 0 | True if same student+type already has a prior cert (BR-CRT-003) |
| `issued_by` | INT UNSIGNED NOT NULL FK → `sys_users.id` | |
| Standard audit cols | | + `deleted_at` |

**Critical constraints:**
- `UNIQUE(certificate_no)` — no duplicate cert numbers per tenant
- `UNIQUE(verification_hash)` — required for O(1) hash lookup at verification time
- `template_id → crt_templates.id` FK uses `ON DELETE RESTRICT` (BR-CRT-006)

---

### 6. `crt_tc_register`
**Purpose:** Formal state-board TC register — legally mandated sequential logbook.

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `sl_no` | SMALLINT UNSIGNED NOT NULL | Sequential per year — no gaps (BR-CRT-002) |
| `academic_year` | SMALLINT UNSIGNED NOT NULL | 4-digit year e.g. 2026 |
| `issued_certificate_id` | INT UNSIGNED NOT NULL FK → `crt_issued_certificates.id` RESTRICT | |
| `student_name` | VARCHAR(200) NOT NULL | Snapshot at time of TC |
| `father_name` | VARCHAR(200) NULL | |
| `date_of_birth` | DATE NOT NULL | |
| `class_at_leaving` | VARCHAR(50) NOT NULL | e.g., "Grade 10 - A" |
| `date_of_admission` | DATE NOT NULL | |
| `date_of_leaving` | DATE NOT NULL | |
| `conduct` | VARCHAR(100) NOT NULL DEFAULT 'Good' | |
| `reason_for_leaving` | VARCHAR(255) NOT NULL | |
| `is_duplicate_entry` | TINYINT(1) DEFAULT 0 | True for re-issued TC |
| `prepared_by` | INT UNSIGNED NOT NULL FK → `sys_users.id` | |
| Standard audit cols | | + `deleted_at` |

**Constraint:** `UNIQUE(sl_no, academic_year)` — TC serial unique per year

---

### 7. `crt_serial_counters`
**Purpose:** Per-type, per-year sequential counter. Locked with `SELECT FOR UPDATE` (BR-CRT-015).

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `certificate_type_id` | INT UNSIGNED NOT NULL FK → `crt_certificate_types.id` RESTRICT | |
| `academic_year` | SMALLINT UNSIGNED NOT NULL | 4-digit year |
| `last_seq_no` | INT UNSIGNED NOT NULL DEFAULT 0 | Incremented atomically |
| Standard audit cols | | + `deleted_at` |

**Constraint:** `UNIQUE(certificate_type_id, academic_year)` — one counter per type per year

---

### 8. `crt_bulk_jobs`
**Purpose:** Async bulk generation job tracking record.

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `certificate_type_id` | INT UNSIGNED NOT NULL FK → `crt_certificate_types.id` RESTRICT | |
| `initiated_by` | INT UNSIGNED NOT NULL FK → `sys_users.id` | |
| `filter_json` | JSON NULL | Stores `class_id`, `section_id`, `student_ids` filter criteria |
| `total_count` | SMALLINT UNSIGNED NOT NULL DEFAULT 0 | |
| `processed_count` | SMALLINT UNSIGNED NOT NULL DEFAULT 0 | |
| `failed_count` | SMALLINT UNSIGNED NOT NULL DEFAULT 0 | |
| `status` | ENUM('queued','processing','completed','failed') DEFAULT 'queued' | |
| `zip_path` | VARCHAR(500) NULL | Path to generated ZIP on completion |
| `error_log_json` | JSON NULL | Per-student failure details |
| `started_at` | TIMESTAMP NULL | |
| `completed_at` | TIMESTAMP NULL | |
| Standard audit cols | | + `deleted_at` |

---

### 9. `crt_id_card_configs`
**Purpose:** ID card template configurations (layout, fields, card size).

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `card_type` | ENUM('student','staff') NOT NULL | |
| `name` | VARCHAR(150) NOT NULL | Config display name |
| `academic_session_id` | SMALLINT UNSIGNED NOT NULL FK → `sch_org_academic_sessions_jnt.id` RESTRICT | |
| `card_size` | ENUM('a5','cr80') DEFAULT 'cr80' | CR80 = standard credit-card size |
| `orientation` | ENUM('portrait','landscape') DEFAULT 'portrait' | |
| `template_json` | JSON NOT NULL | Field positions, colors, QR placement coordinates |
| `cards_per_sheet` | TINYINT UNSIGNED NOT NULL DEFAULT 8 | For A4 sheet layout (1–20) |
| Standard audit cols | | + `deleted_at` |

---

### 10. `crt_student_documents`
**Purpose:** DMS — incoming student document store with verification workflow.

| Column | Type | Notes |
|---|---|---|
| `id` | INT UNSIGNED PK | |
| `student_id` | INT UNSIGNED NOT NULL FK → `std_students.id` RESTRICT | |
| `document_category_id` | INT UNSIGNED NOT NULL FK → `sys_dropdown_table.id` RESTRICT | Seeded categories: TC, Migration, DOB, Aadhaar, Caste, Disability, Photo, Other |
| `document_name` | VARCHAR(255) NOT NULL | |
| `document_date` | DATE NULL | Date on document |
| `media_id` | INT UNSIGNED NOT NULL FK → `sys_media.id` RESTRICT | Polymorphic file store |
| `verification_status` | ENUM('pending','verified','rejected') DEFAULT 'pending' | |
| `verification_remarks` | TEXT NULL | Required when rejected (BR-CRT-008) |
| `verified_by` | INT UNSIGNED NULL FK → `sys_users.id` | |
| `verified_at` | TIMESTAMP NULL | |
| Standard audit cols | | + `deleted_at` |

---

### Entity Summary

| # | Table | Row Type | has `deleted_at` | Notes |
|---|---|---|---|---|
| 1 | `crt_certificate_types` | Config master | Yes | |
| 2 | `crt_templates` | Config master | Yes | |
| 3 | `crt_template_versions` | Archive (immutable) | **NO** | Versions never soft-deleted |
| 4 | `crt_requests` | Transactional | Yes | |
| 5 | `crt_issued_certificates` | Transactional | Yes | |
| 6 | `crt_tc_register` | Legal record | Yes | |
| 7 | `crt_serial_counters` | Config/Counter | Yes | |
| 8 | `crt_bulk_jobs` | Job tracker | Yes | |
| 9 | `crt_id_card_configs` | Config | Yes | |
| 10 | `crt_student_documents` | Transactional | Yes | |

---

## Section 3 — Entity Relationship Diagram (ERD)

```
sys_users ─────────────────────────────────────────────────────────────────────┐
(created_by, approved_by, issued_by, revoked_by, prepared_by, saved_by)        │
                                                                                │
std_students ─────────FK(beneficiary)──────────────────────────────────────────┤
             ─────────FK(student)──────────────────────────────────────────────┤
                                                                                │
sys_media ────────────FK(media_id)─────────────────────────────────────────────┤
sys_dropdown_table ───FK(doc_category)─────────────────────────────────────────┤
sch_org_academic_sessions_jnt ──FK(academic_session)───────────────────────────┤
                                                                                │
[L1 — Type & Template]                                                          │
crt_certificate_types ──(1)─────────────────────────────────────────────────── │
  │   │   │                                                                     │
  │  (M) (M)                                                                    │
  │   │   └── crt_serial_counters   [UNIQUE(type_id, year)]                     │
  │   │                                                                         │
  │  (M)── crt_templates ──(1)──hasMany──(M)── crt_template_versions           │
  │           │                                  [immutable — no deleted_at]    │
  │           └── (M crt_issued_certificates.template_id — ON DELETE RESTRICT)  │
  │                                                                             │
[L2 — Requests]                                                                 │
  └── (M)── crt_requests                                                        │
               │   [UNIQUE request_no]                                           │
               │   [INDEX (beneficiary_student_id, type_id, status)]            │
               │                                                                │
[L3 — Issuance]                                                                 │
               └── (0..1)── crt_issued_certificates                             │
                               │   [UNIQUE certificate_no, verification_hash]    │
                               │                                                │
[L4 — TC]                      └── (0..1)── crt_tc_register                    │
                                               [UNIQUE(sl_no, academic_year)]   │

[L5 — Bulk]
crt_certificate_types ──(M)── crt_bulk_jobs

[L7 — ID Cards]
sch_org_academic_sessions_jnt ──(M)── crt_id_card_configs

[L8 — DMS]
std_students ──(M)── crt_student_documents ──FK── sys_media
```

**Cardinality Summary:**
- `CertificateType` → `CertificateTemplate`: 1-to-many (one type, many templates; only one `is_default`)
- `CertificateTemplate` → `CertificateTemplateVersion`: 1-to-many (immutable archive)
- `CertificateType` → `SerialCounter`: 1-to-many (one per year per type)
- `CertificateRequest` → `CertificateIssued`: 1-to-0..1 (request-based; NULL for direct-issue)
- `CertificateIssued` → `TcRegister`: 1-to-0..1 (only when type = TC)
- `CertificateTemplate` → `CertificateIssued`: 1-to-many (RESTRICT prevents template deletion if referenced)

---

## Section 4 — Business Rules

| ID | Rule | Enforcement Point |
|---|---|---|
| BR-CRT-001 | TC cannot be generated if student has outstanding fee dues (`fin_fee_dues > 0`) unless admin records override justification | `CertificateGenerationService::generateTC()` — query `fin_*` table + policy gate |
| BR-CRT-002 | TC serial number (`crt_tc_register.sl_no`) must be sequential and year-wise; gaps not allowed | `QrVerificationService::incrementSerialCounter()` with `SELECT FOR UPDATE` in DB transaction |
| BR-CRT-003 | Second issuance to same recipient = `is_duplicate = true`; PDF renders with "DUPLICATE COPY" watermark | `CertificateGenerationService::generateFromRequest()` Step 6 — check prior cert exists |
| BR-CRT-004 | Certificate number unique per tenant; format `{TYPE_CODE}-{YYYY}-{SEQ}` as configured | `UNIQUE INDEX` on `certificate_no` + `SerialCounter` lock |
| BR-CRT-005 | Revoked certificates remain in DB; verification returns `REVOKED` status, not 404 | `QrVerificationService::verifyHash()` — check `is_revoked` before returning result |
| BR-CRT-006 | Templates with referenced issued certificates cannot be hard-deleted | `FK ON DELETE RESTRICT` on `crt_issued_certificates.template_id` |
| BR-CRT-007 | ID cards must display blood group when present in `std_profiles`; blank field (not hidden) when absent | `IdCardController::generate()` — conditional rendering in PDF template |
| BR-CRT-008 | DMS documents with `verification_status = rejected` cannot satisfy certificate eligibility checks | `DmsService::hasVerifiedDocument()` — status check; `CertificateRequestController::store()` validation |
| BR-CRT-009 | Bulk generation exceeding 200 certificates **must** use queue; synchronous processing forbidden above threshold | `BulkGenerationController::generate()` — count check before dispatch |
| BR-CRT-010 | Public verification endpoint must not expose full student name, DOB, class, or address | `VerificationController::verify()` response DTO — only first name + last initial + school name |
| BR-CRT-011 | Once TC issued: `std_students.tc_issued = true`; student status transitions to `withdrawn` | Post-hook in `CertificateGenerationService::generateTC()` — direct write (not event) |
| BR-CRT-012 | Only one template per certificate type may have `is_default = true` at any time | Toggle logic in `CertificateTemplateController` — wrap in DB transaction, clear others first |
| BR-CRT-013 | Rejection requires `rejection_reason` (NOT NULL) | `RejectCertificateRequestRequest` FormRequest — `required` validation rule |
| BR-CRT-014 | Supporting documents stored in `sys_media` with `model_type = CertificateRequest` (polymorphic) | Upload logic in `CertificateRequestController::store()` |
| BR-CRT-015 | Serial counter increment uses `SELECT ... FOR UPDATE` in a DB transaction | `QrVerificationService::incrementSerialCounter()` — `lockForUpdate()` |

---

## Section 5 — FSMs (Finite State Machines)

### 5.1 Certificate Request Lifecycle

```
[SUBMITTED by student / parent / clerk / admin]
  → creates crt_requests row, status = 'pending'
  → if certificate_type.requires_approval = false:
      → status auto-advances to 'approved'
      → CertificateGenerationService::generateFromRequest() triggered immediately

[PENDING]
  → Admin opens the request record
  → status = 'under_review'
  Side effect: logs to sys_activity_logs

[UNDER_REVIEW]
  ─ approve ──→ status = 'approved'
               Side effects:
               • approved_by + approved_at set
               • CertificateGenerationService::generateFromRequest() fired
  ─ reject  ──→ status = 'rejected' [TERMINAL — negative]
               Side effects:
               • rejection_reason required (BR-CRT-013)
               • Notification fired → requester notified

[APPROVED]
  ─ generation succeeds ──→ status = 'generated'
                            Side effects:
                            • crt_issued_certificates row created
                            • If type = TC: crt_tc_register row created
                                           std_students.tc_issued = true (BR-CRT-011)
                                           std_students.current_status_id → 'Withdrawn'
  ─ generation fails    ──→ status stays 'approved'
                            Error logged; admin can retry

[GENERATED]
  → Admin records physical handover
  → status = 'issued' [TERMINAL — positive]
  Side effect: Notification → requester (download link)
```

### 5.2 Certificate Generation Flow (Direct / Bulk)

```
[Admin initiates direct or bulk generation]
  ─ count ≤ 200 → synchronous: CertificateGenerationService::generateDirect()
  ─ count > 200 → MANDATORY queue: BulkGenerateCertificatesJob dispatched (BR-CRT-009)

[PER STUDENT GENERATION]
  Step 1: Load certificate type + active default template
  Step 2: resolveMergeFields(student_id)
  Step 3: DB::transaction begins
  Step 4: SerialCounter::nextForType() [SELECT FOR UPDATE] → certificate_no
  Step 5: Check for duplicate (prior cert same student+type) → set is_duplicate if true
  Step 6: QrVerificationService::generateVerificationHash() → 64-char HMAC-SHA256 hex
  Step 7: QrVerificationService::generateQrCode(verificationUrl) → base64 PNG
  Step 8: DomPDF renders HTML template with resolved fields + QR embedded as base64 img
  Step 9: Store PDF at storage/tenant_{id}/certificates/{type}/{YYYY}/
  Step 10: Create crt_issued_certificates row
  Step 11 (TC only):
    → Check fee_dues = 0 OR override justification present (BR-CRT-001)
    → Write crt_tc_register (sl_no via SerialCounter SELECT FOR UPDATE)
    → UPDATE std_students.tc_issued = true (BR-CRT-011)
    → UPDATE std_students.current_status_id → 'Withdrawn'
  Step 12: Update crt_requests.status = 'generated'
  Step 13: DB::transaction commits
  Step 14: Fire CertificateGenerated event → NTF module → email/SMS with download link
```

### 5.3 QR Verification Flow

```
[Third party scans QR code → GET /verify/{hash}]
  → QrVerificationService::verifyHash($hash)
  → SELECT * FROM crt_issued_certificates WHERE verification_hash = $hash

  ─ not found  ──→ result = 'NOT_FOUND'
                   Log to sys_activity_logs (method=qr, result=NOT_FOUND, IP, user-agent)
                   Render: Not Found page

  ─ found:
      is_revoked = true  ──→ result = 'REVOKED' (BR-CRT-005 — NOT 404)
      validity_date < today ──→ result = 'EXPIRED'
      else ──→ result = 'VALID'

  → Log to sys_activity_logs (method=qr, result=..., IP, user-agent)
  → Render public.blade.php — response DTO: {certificate_type, first_name + last_initial, school_name, issue_date, validity_status}
    (BR-CRT-010: full name, DOB, class, address NOT exposed)
```

### 5.4 Bulk Generation Job FSM

```
crt_bulk_jobs.status transitions:

[QUEUED]
  → BulkGenerateCertificatesJob dispatched to queue
  → Worker picks up job

[QUEUED] → [PROCESSING]
  → job starts; processed_count = 0; started_at = now()

[PROCESSING] — per student loop:
  ─ success → generateDirect() for student; processed_count++
  ─ failure → failed_count++; failure logged to error_log_json (BR: batch continues — BR-CRT-009)

[PROCESSING] → [COMPLETED]
  → All students processed
  → ZIP created: {CertType}_{Class}_{YYYYMMDD}.zip (PDFs named {CertNo}_{StudentName}.pdf)
  → zip_path set; completed_at = now()
  → Download link shown to admin

[PROCESSING] → [FAILED]
  → Fatal job exception (not per-student failure)
  → Admin notified; retry option offered
```

---

## Section 6 — Functional Requirements

| FR | Title | Priority | Status | Tables |
|---|---|---|---|---|
| FR-CRT-001 | Certificate Type Management | Critical | Proposed | `crt_certificate_types`, `crt_serial_counters` |
| FR-CRT-002 | Certificate Template Designer | Critical | Proposed | `crt_templates`, `crt_template_versions` |
| FR-CRT-003 | Certificate Request Workflow | Critical | Proposed | `crt_requests` |
| FR-CRT-004 | Certificate Generation & Issuance | Critical | Proposed | `crt_issued_certificates`, `crt_serial_counters` |
| FR-CRT-005 | Transfer Certificate (TC) | Critical | Proposed | `crt_requests`, `crt_issued_certificates`, `crt_tc_register` |
| FR-CRT-006 | Achievement & Bulk Certificates | High | Proposed | `crt_issued_certificates`, `crt_bulk_jobs` |
| FR-CRT-007 | Digital Verification (QR + API) | Critical | Proposed | `crt_issued_certificates`; logs → `sys_activity_logs` |
| FR-CRT-008 | ID Card Generation | High | Proposed | `crt_id_card_configs` |
| FR-CRT-009 | Document Management System (DMS) | High | Proposed | `crt_student_documents` |
| FR-CRT-010 | Certificate Number Format Configuration | Medium | Proposed | `crt_serial_counters`, `crt_certificate_types` |
| FR-CRT-011 | Reports & Analytics | Medium | Proposed | `crt_issued_certificates`, `crt_requests` |
| FR-CRT-012 | Student & Parent Portal Access | High | Proposed | `crt_requests`, `crt_issued_certificates` |

### Key Acceptance Criteria per FR:

**FR-CRT-001:** Unique `code` enforced (AC1); `requires_approval=0` → auto-approve (AC2); `validity_days NULL` = no expiry (AC3); serial counter resets yearly (AC4); hard delete blocked by FK if certs exist (AC5); `is_active=false` hides from portal (AC6).

**FR-CRT-002:** LONGTEXT HTML content (AC1); `variables_json` must list all `{{placeholders}}` in content — mismatch = validation error (AC2); preview via DomPDF with dummy data (AC3); save archives prior version (AC4); restore creates new version entry (AC5); only one `is_default=true` per type — BR-CRT-012 (AC6); template hard-delete blocked by FK — BR-CRT-006 (AC7).

**FR-CRT-003:** Auto-generated `request_no = REQ-YYYY-000001` (AC1); `requires_approval=0` → immediate approval + generation (AC2); duplicate pending request blocked (AC7).

**FR-CRT-004:** Unique cert no per tenant (AC1); merge fields from `std_students`, `std_profiles`, `sch_org_academic_sessions_jnt` (AC2); PDF at `storage/tenant_{id}/certificates/{type}/{YYYY}/` (AC3); `verification_hash = HMAC-SHA256(certificate_no + issue_date + recipient_id + APP_KEY)` (AC4); revoke stores `revoked_at`, `revoked_by`, `revocation_reason` (AC6); duplicate issuance → `is_duplicate=true` + "DUPLICATE COPY" watermark (AC7).

**FR-CRT-005:** Fee check gate — BR-CRT-001 (AC1); TC register auto-created (AC2); `sl_no` sequential year-wise — BR-CRT-002 (AC3); `date_of_leaving` and `reason_for_leaving` required (AC4); BR-CRT-011 post-hook (AC6).

**FR-CRT-006:** Direct generation without request workflow (AC1); filter: `certificate_type_id` + optional `class_id`/`section_id`/`student_ids` (AC2); > 200 certs → queue mandatory — BR-CRT-009 (AC3); failure logging in `error_log_json` (AC7).

**FR-CRT-007:** QR encodes `https://{school-domain}/verify/{verification_hash}` (AC1); public page: type, issued-to (first name + last initial only), school, issue date, status (AC2); every verification logged to `sys_activity_logs` with IP + user-agent + method + result (AC3); API `/api/v1/certificate/verify?hash=&api_key=` (AC4); unauthorised API → 401 (AC5).

**FR-CRT-009:** MIME whitelist: pdf, jpeg, png; max 5 MB (AC1); category from `sys_dropdown_table` (AC2); files via `sys_media` polymorphic (AC3); verification workflow: pending → verified/rejected (AC4); rejected docs cannot satisfy eligibility — BR-CRT-008 (AC5).

**FR-CRT-010:** Format tokens: `{TYPE_CODE}`, `{YYYY}`, `{YY}`, `{SEQ4}`, `{SEQ6}` (AC1); one `crt_serial_counters` row per type per year (AC2); `SELECT ... FOR UPDATE` for concurrency — BR-CRT-015 (AC3).

---

## Section 7 — Permissions & Policies

### 7.1 Permission Strings

| Permission | Description |
|---|---|
| `certificate.types.view` | List certificate types |
| `certificate.types.manage` | Create/edit/delete types |
| `certificate.templates.view` | List/preview templates |
| `certificate.templates.manage` | Create/edit/delete/restore templates |
| `certificate.requests.create` | Submit a certificate request |
| `certificate.requests.approve` | Approve a request (Admin/Principal only) |
| `certificate.requests.reject` | Reject a request (Admin/Principal only) |
| `certificate.issued.view` | View issued certificates register |
| `certificate.issued.download` | Download certificate PDF |
| `certificate.issued.revoke` | Revoke a certificate (Admin only) |
| `certificate.bulk-generate` | Initiate bulk certificate generation |
| `certificate.id-card.manage` | Configure and generate ID cards |
| `certificate.documents.upload` | Upload DMS documents |
| `certificate.documents.verify` | Mark documents verified/rejected (Admin only) |
| `certificate.reports.view` | Access analytics and report pages |

### 7.2 Policy Classes

| Policy Class | File | Controller |
|---|---|---|
| `CertificateTypePolicy` | `Modules/Certificate/app/Policies/CertificateTypePolicy.php` | `CertificateTypeController` |
| `CertificateTemplatePolicy` | `…/CertificateTemplatePolicy.php` | `CertificateTemplateController` |
| `CertificateRequestPolicy` | `…/CertificateRequestPolicy.php` | `CertificateRequestController` |
| `CertificateIssuedPolicy` | `…/CertificateIssuedPolicy.php` | `CertificateIssuedController` |
| `BulkGenerationPolicy` | `…/BulkGenerationPolicy.php` | `BulkGenerationController` |
| `IdCardPolicy` | `…/IdCardPolicy.php` | `IdCardController` |
| `DocumentManagementPolicy` | `…/DocumentManagementPolicy.php` | `DocumentManagementController` |
| `CertificateReportPolicy` | `…/CertificateReportPolicy.php` | `CertificateReportController` |

### 7.3 Permission Matrix

| Permission | Admin | Principal | Clerk | Class Teacher | Student | Parent |
|---|---|---|---|---|---|---|
| `certificate.types.manage` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `certificate.types.view` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| `certificate.templates.manage` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `certificate.templates.view` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `certificate.requests.create` | ✅ | ✅ | ✅ | ❌ | ✅ (own) | ✅ (ward) |
| `certificate.requests.approve` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `certificate.requests.reject` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `certificate.issued.view` | ✅ | ✅ | ✅ | ✅ (own class) | ✅ (own) | ✅ (ward) |
| `certificate.issued.download` | ✅ | ✅ | ✅ | ❌ | ✅ (own) | ✅ (ward) |
| `certificate.issued.revoke` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `certificate.bulk-generate` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `certificate.id-card.manage` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `certificate.documents.upload` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `certificate.documents.verify` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `certificate.reports.view` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## Section 8 — Service Architecture

### 8.1 CertificateGenerationService

```
Service:     CertificateGenerationService
File:        app/Services/CertificateGenerationService.php
Namespace:   Modules\Certificate\app\Services
Depends on:  QrVerificationService (hash generation, QR code)
             DmsService (TC eligibility check — BR-CRT-008)
             FinFeeService (TC fee-clear check — BR-CRT-001)
Fires:       CertificateGenerated (event → NTF module)
             CertificateRequestApproved (event → NTF module)
```

**Key Methods:**
```php
generateFromRequest(CertificateRequest $request): CertificateIssued
  └── 14-step generation flow (see pseudocode below)

generateDirect(CertificateType $type, int $recipientId, array $extraFields = []): CertificateIssued
  └── Generates without a request workflow (achievement/bulk)

generateTC(CertificateRequest $request, array $tcData): CertificateIssued
  └── TC-specific: fee-clear gate (BR-CRT-001) + tc_register write + std_students write (BR-CRT-011)

resolveMergeFields(int $studentId, array $extra = []): array
  └── Builds merge field map from std_students (first+middle+last name, dob, admission_no),
      std_profiles (father_name, mother_name, blood_group, nationality, religion),
      sch_org_academic_sessions_jnt (name → {{academic_session}}),
      sch_classes + sch_sections ({{class_section}}),
      sch_school_profiles ({{school_name}}, {{principal_name}}, {{school_address}})

generateCertificateNo(CertificateType $type): string
  └── Delegates to QrVerificationService::incrementSerialCounter(); formats using serial_format tokens
```

**Certificate Generation 14-Step Pseudocode:**
```
generateFromRequest(CertificateRequest $request): CertificateIssued
  Step 1:  Verify $request->status == 'approved'; throw if not
  Step 2:  Load CertificateType + active default CertificateTemplate (where is_default=1)
  Step 3:  resolveMergeFields($request->beneficiary_student_id, $request->extra_fields)
           → builds array of {{placeholder}} => 'actual value' pairs
  Step 4:  DB::transaction begins
  Step 5:  QrVerificationService::incrementSerialCounter($type, $year)
             → SELECT crt_serial_counters WHERE type_id=X AND year=Y FOR UPDATE
             → last_seq_no++
             → return formatCertificateNo($type->serial_format, $type->code, $year, last_seq_no)
  Step 6:  Check if crt_issued_certificates WHERE recipient_id = student_id AND certificate_type_id = type_id EXISTS
             → set $isDuplicate = true if found
  Step 7:  $hash = QrVerificationService::generateVerificationHash($cert)
             → HMAC-SHA256 of (certificate_no . issue_date . recipient_id . APP_KEY)
  Step 8:  $qrBase64 = QrVerificationService::generateQrCode("https://{domain}/verify/{$hash}")
             → SimpleSoftwareIO generates base64 PNG; embedded as <img src="data:image/png;base64,…">
  Step 9:  DomPDF renders template_content with resolved merge fields + QR image embedded
             → stores PDF at storage/tenant_{id}/certificates/{type_code}/{YYYY}/{cert_no}.pdf
             → PDF DPI ≥ 150; UTF-8 font for Devanagari/Tamil character support
             → "DUPLICATE COPY" watermark added if $isDuplicate = true (BR-CRT-003)
  Step 10: Create crt_issued_certificates row (certificate_no, verification_hash, file_path, is_duplicate)
  Step 11: If $type->code == 'TC':
             → BR-CRT-001: check fin_fee_dues == 0 OR $request->override_justification present
             → QrVerificationService::incrementSerialCounter($tcCounterType, $year) for TC sl_no
             → Create crt_tc_register row (sl_no, student_name, father_name, class_at_leaving, etc.)
             → UPDATE std_students.tc_issued = true  (requires ALTER TABLE migration)
             → UPDATE std_students.current_status_id → sys_dropdown_table id for 'Withdrawn'
  Step 12: $request->update(['status' => 'generated'])
  Step 13: DB::transaction commits
  Step 14: event(new CertificateGenerated($cert)) → NTF module sends download link to requester
```

---

### 8.2 QrVerificationService

```
Service:     QrVerificationService
File:        app/Services/QrVerificationService.php
Namespace:   Modules\Certificate\app\Services
Depends on:  (none — standalone)
Fires:       (none — logs go directly to sys_activity_logs)
```

**Key Methods:**
```php
generateVerificationHash(CertificateIssued $cert): string
  └── HMAC-SHA256 of ($cert->certificate_no . $cert->issue_date . $cert->recipient_id . config('app.key'))
      → returns 64-char lowercase hex string

generateQrCode(string $verificationUrl): string
  └── SimpleSoftwareIO\QrCode\Facades\QrCode::format('png')->size(150)->generate($url)
      → returns base64-encoded PNG string; embedded in template as <img data: src>

verifyHash(string $hash): array
  └── Lookup crt_issued_certificates WHERE verification_hash = $hash
      → not found: result = 'NOT_FOUND'
      → is_revoked = true: result = 'REVOKED' (BR-CRT-005 — not 404)
      → validity_date < today: result = 'EXPIRED'
      → else: result = 'VALID'
      → Log to sys_activity_logs: {user_type=public, action=certificate_verify, method=qr, ip, user_agent, result}
      → Return DTO: {result, certificate_type_name, issued_to_display (first_name + last_initial), school_name, issue_date, expires_on}
        (BR-CRT-010: full name, DOB, class, address NOT in DTO)
```

**Serial Counter Concurrency Pseudocode — `incrementSerialCounter()`:**
```
incrementSerialCounter(CertificateType $type, int $year): string
  Step 1: DB::transaction begins
  Step 2: $counter = CrtSerialCounter::where([
              'certificate_type_id' => $type->id,
              'academic_year'       => $year
          ])->lockForUpdate()->firstOrCreate(['last_seq_no' => 0])
  Step 3: $counter->increment('last_seq_no')
  Step 4: DB::transaction commits
  Step 5: return formatCertificateNo($type->serial_format, $type->code, $year, $counter->fresh()->last_seq_no)

formatCertificateNo(string $format, string $code, int $year, int $seq): string
  → replaces {TYPE_CODE} → $code
  → replaces {YYYY} → $year
  → replaces {YY} → substr($year, 2)
  → replaces {SEQ6} → str_pad($seq, 6, '0', STR_PAD_LEFT)
  → replaces {SEQ4} → str_pad($seq, 4, '0', STR_PAD_LEFT)
```

---

### 8.3 DmsService

```
Service:     DmsService
File:        app/Services/DmsService.php
Namespace:   Modules\Certificate\app\Services
Depends on:  (none — uses sys_media polymorphic)
Fires:       (none)
```

**Key Methods:**
```php
uploadDocument(int $studentId, UploadedFile $file, array $meta): StudentDocument
  └── Store file via sys_media (polymorphic: model_type='StudentDocument', model_id)
      → Create crt_student_documents row (student_id, document_category_id, document_name, media_id, status='pending')
      → Log upload to sys_activity_logs

verifyDocument(StudentDocument $doc, string $status, string $remarks, int $verifierId): void
  └── Update crt_student_documents.verification_status = $status
      → verification_remarks required when $status = 'rejected'
      → verified_by = $verifierId; verified_at = now()

getDocumentsByStudent(int $studentId): Collection
  └── SELECT * FROM crt_student_documents WHERE student_id = ? AND deleted_at IS NULL
      WITH sys_media, sys_dropdown_table (category name)

hasVerifiedDocument(int $studentId, string $categoryCode): bool
  └── Check crt_student_documents WHERE student_id = ?
        AND document_category_id = (sys_dropdown_table.id WHERE key LIKE 'crt_student_documents.document_category_id' AND value = $categoryCode)
        AND verification_status = 'verified'
        AND deleted_at IS NULL
      → returns true if at least one verified document exists
      → BR-CRT-008: 'rejected' status docs do NOT satisfy this check
```

---

## Section 9 — Integration Contracts

| Event / Hook | Fired By | Listener Module | Payload | Action |
|---|---|---|---|---|
| `CertificateRequestApproved` (event) | `CertificateRequestController::approve()` | NTF module | `{request_id, requester_name, requester_email, requester_phone, certificate_type_name, approved_by_name, approved_at}` | Email + SMS notification to requester |
| `CertificateGenerated` (event) | `CertificateGenerationService` Step 14 | NTF module | `{cert_id, certificate_no, recipient_name, recipient_email, download_url, certificate_type_name, issue_date}` | Email + SMS with download link to requester |
| TC post-hook (direct write — no event) | `CertificateGenerationService::generateTC()` Step 11 | Student Management (std_*) | N/A — direct DB write | Sets `std_students.tc_issued = true`; updates `std_students.current_status_id` → Withdrawn |

**Notification Payload for `CertificateRequestApproved`:**
```json
{
  "notification_type": "certificate_request_approved",
  "request_id": 142,
  "request_no": "REQ-2026-000142",
  "requester_name": "Priya Sharma",
  "requester_email": "priya@example.com",
  "requester_phone": "+91-9876543210",
  "certificate_type_name": "Bonafide Certificate",
  "approved_by_name": "Principal Mehta",
  "approved_at": "2026-03-27T10:30:00+05:30",
  "school_name": "Delhi Public School"
}
```

---

## Section 10 — Non-Functional Requirements

| Category | Requirement | Target | Implementation Note |
|---|---|---|---|
| Performance | Single PDF generation | < 3 seconds | DomPDF single-page; QR embedded as base64 — no HTTP fetch at render time |
| Performance | Bulk generation throughput | > 50 certs/minute | Queue worker; configurable Horizon concurrency |
| Performance | Public verification endpoint | < 500 ms | Single hash lookup on indexed column + one log insert; no auth overhead |
| Performance | Page load (admin cert list) | < 2 seconds | Paginated (15/page); eager-load type + recipient |
| Storage | Tenant-isolated file paths | `storage/tenant_{id}/certificates/` | stancl/tenancy disk configuration — `config/filesystems.php` tenant disk |
| Storage | PDF quality | 150 DPI minimum | `config/dompdf.php` → `dpi` key |
| Storage | Max DMS file upload | 5 MB per document | Enforced in `DocumentUploadRequest` → `max:5120` (KB) |
| Security | Verification hash algorithm | HMAC-SHA256 | Key = `APP_KEY`; hash is immutable after issuance |
| Security | Third-party API auth | API key in query param | Key stored hashed in tenant config; rate-limited 60 req/min |
| Security | Certificate PDF access | Authorised users only | `Storage::temporaryUrl()` or signed route — Laravel `URL::signedRoute()` |
| Security | Public verification privacy | First name + last initial + school name only | Response DTO in `QrVerificationService::verifyHash()` — BR-CRT-010 |
| Security | Rate limiting on public /verify | 20 per IP per hour | `throttle:20,60` middleware on public route (Suggestion S06) |
| Reliability | Bulk job failure handling | Per-student failures logged; batch continues | `error_log_json` in `crt_bulk_jobs`; try/catch in job loop |
| Maintainability | Soft deletes | All tables except `crt_template_versions` | Standard `deleted_at` pattern |
| Maintainability | Audit trail | All data changes | `sys_activity_logs` — standard platform pattern |
| Scalability | Queue-based bulk | Required > 200 certs | Laravel Horizon or Redis queue |
| Compatibility | PDF page sizes | A4/A5/Letter/Custom | DomPDF `paper` config in template render |
| Localisation | UTF-8 names | Hindi, Marathi, Tamil | `utf8mb4` + DomPDF DejaVu Unicode font |

---

## Section 11 — Test Plan Outline

### Feature Tests (Pest) — 8 files

| File | Path | T01–T30 Scenarios Covered |
|---|---|---|
| `CertificateTypeTest.php` | `tests/Feature/Certificate/CertificateTypeTest.php` | T01 (create type), T02 (duplicate code), implicit config for all others |
| `CertificateTemplateTest.php` | `tests/Feature/Certificate/CertificateTemplateTest.php` | T03 (preview), T04 (versioning), T05 (restore version), T06 (BR-CRT-012 default toggle) |
| `CertificateRequestWorkflowTest.php` | `tests/Feature/Certificate/CertificateRequestWorkflowTest.php` | T07 (request + approve + generate), T08 (duplicate request blocked), T29 (portal own records only) |
| `CertificateGenerationTest.php` | `tests/Feature/Certificate/CertificateGenerationTest.php` | T07 (merge fields), T25 (BR-CRT-003 duplicate watermark), T27 (concurrent generation) |
| `QrVerificationTest.php` | `tests/Feature/Certificate/QrVerificationTest.php` | T09 (QR resolves), T10 (REVOKED), T11 (privacy BR-CRT-010), T23 (API valid), T24 (API 401), T30 (revoked download blocked) |
| `TcRegistrationTest.php` | `tests/Feature/Certificate/TcRegistrationTest.php` | T12 (fee gate BR-CRT-001), T13 (sl_no sequential), T14 (std_students write BR-CRT-011) |
| `BulkGenerationTest.php` | `tests/Feature/Certificate/BulkGenerationTest.php` | T15 (bulk ≤ 200 synchronous), T16 (> 200 → queue BR-CRT-009), T17 (per-student failure handling) |
| `DmsTest.php` | `tests/Feature/Certificate/DmsTest.php` | T20 (upload), T21 (verify/reject), T22 (BR-CRT-008 rejected blocks TC eligibility) |

**Additional tests from T-series not mapped to single file:**
- T18, T19 (ID card + handover) → `IdCardGenerationTest.php` (Feature)
- T26, T28 (reports export + analytics) → `CertificateReportTest.php` (Feature)

### Unit Tests (PHPUnit) — 3 files

| File | Path | Scenarios |
|---|---|---|
| `SerialCounterTest.php` | `tests/Unit/Certificate/SerialCounterTest.php` | `SELECT FOR UPDATE` uniqueness (T27); concurrent calls produce unique sequential numbers; format token expansion (`{SEQ4}`, `{SEQ6}`, `{TYPE_CODE}`, `{YYYY}`) |
| `QrVerificationServiceTest.php` | `tests/Unit/Certificate/QrVerificationServiceTest.php` | Hash generation deterministic; `verifyHash()` returns VALID/EXPIRED/REVOKED/NOT_FOUND correctly; QR base64 output format |
| `MergeFieldResolverTest.php` | `tests/Unit/Certificate/MergeFieldResolverTest.php` | All 17 merge fields resolve correctly from mock student/profile data; `{{student_name}}` concatenates first+middle+last; NULL `blood_group` produces empty string (not error) |

### Policy Tests

| Test | Scenarios |
|---|---|
| `CertificatePolicyTest.php` | Student can request own cert; Principal can approve TC; Clerk cannot revoke; Student cannot view other students' certs (FR-CRT-012); Class Teacher sees only own class certs |

### Test Setup Requirements

```php
// Feature test base
uses(Tests\TestCase::class, RefreshDatabase::class);

// Required fakes
Queue::fake();           // for BulkGenerateCertificatesJob (T15, T16)
Event::fake();           // for CertificateGenerated / CertificateRequestApproved (T07)
Storage::fake();         // for PDF + DMS file storage (T07, T20)

// Mock fin_* fee check in TC tests (T12)
// Option A: Stub CertificateGenerationService::generateTC()
// Option B: Mock Eloquent query on fin_fee_dues column directly
```

### Required Factories

| Factory | Key Generated Fields |
|---|---|
| `CertificateTypeFactory` | `code` (random alphanumeric ≤ 10), `category`, `requires_approval` (bool), `serial_format` |
| `CertificateTemplateFactory` | `template_content` (LONGTEXT HTML with at least 3 `{{placeholders}}`), `variables_json` array |
| `CertificateRequestFactory` | `request_no` (`REQ-YYYY-NNN`), `status = 'pending'` |
| `CertificateIssuedFactory` | `certificate_no`, `verification_hash` (sha256 placeholder), `is_revoked = false` |

### Minimum BR Coverage in Tests

| BR | Test File | Scenario |
|---|---|---|
| BR-CRT-001 (TC fee gate) | `TcRegistrationTest` | `fin_fee_dues > 0` → blocks TC; admin override → allows |
| BR-CRT-002 (TC sl_no sequential) | `TcRegistrationTest` | 3 concurrent TCs → sl_no = 1, 2, 3 with no gaps |
| BR-CRT-003 (duplicate watermark) | `CertificateGenerationTest` | Second issuance sets `is_duplicate = true` |
| BR-CRT-005 (REVOKED not 404) | `QrVerificationTest` | Revoked cert → `result = 'REVOKED'`, HTTP 200 |
| BR-CRT-009 (> 200 → queue) | `BulkGenerationTest` | 201 students → `Queue::assertPushed(BulkGenerateCertificatesJob::class)` |
| BR-CRT-010 (privacy) | `QrVerificationTest` | Response JSON does NOT contain `full_name`, `dob`, `class`, `section` |
| BR-CRT-011 (TC → std_students) | `TcRegistrationTest` | `assertDatabaseHas('std_students', ['tc_issued' => 1])` after TC generation |
| BR-CRT-015 (SELECT FOR UPDATE) | `SerialCounterTest` | Concurrent `incrementSerialCounter()` calls → unique sequential results |

---

## Phase 1 Quality Gate — Self-Check

- [x] All 10 `crt_*` tables appear in Section 2 entity inventory
- [x] All 12 FRs (CRT-001 to CRT-012) appear in Section 6
- [x] All 15 business rules (BR-CRT-001 to BR-CRT-015) in Section 4 with enforcement point
- [x] All 4 FSMs documented with ASCII state diagram and side effects
- [x] All 3 services listed with key method signatures in Section 8
- [x] Certificate generation 14-step pseudocode present in `CertificateGenerationService`
- [x] All 3 integration contracts documented in Section 9
- [x] `crt_issued_certificates.verification_hash` noted as HMAC-SHA256 of `(certificate_no + issue_date + recipient_id + APP_KEY)`
- [x] `crt_issued_certificates.template_id → crt_templates.id` noted as ON DELETE RESTRICT (BR-CRT-006)
- [x] `crt_serial_counters` UNIQUE on `(certificate_type_id, academic_year)` noted
- [x] **No `tenant_id` column** mentioned anywhere
- [x] `SerialCounter::incrementSerialCounter()` concurrency note: `SELECT FOR UPDATE` in DB transaction (BR-CRT-015)
- [x] BR-CRT-001 (TC fee gate) explicitly documented in `CertificateGenerationService`
- [x] BR-CRT-009 (bulk > 200 = queue mandatory) explicitly documented in `BulkGenerationController`
- [x] BR-CRT-010 (public verification privacy) enforcement noted in `QrVerificationService` response DTO
- [x] BR-CRT-011 (TC → std_students write) documented as post-hook in `CertificateGenerationService`
- [x] Permission matrix covers Admin / Principal / Clerk / Class Teacher / Student / Parent roles
- [x] Cross-module column names verified against `tenant_db_v2.sql` — corrections documented in DDL Correction Notice
