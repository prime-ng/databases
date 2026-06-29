# Module Knowledge: Certificate (CRT)
# Last Updated: 2026-06-29 (FRD pass — live-tree re-verification: migrations, tests, rate-limit, verification logging, API stub)
# Completion Status: ~70–75% (10 live tenant migrations; all 12 features have controllers+routes+views; generation/TC/verification/serial-lock/rate-limit/DMS-gating implemented; keyed verify API is a stub; ID-card handover store absent; 0 in-module unit/feature tests but ~45-method Dusk suite exists)

> 2026-06-29 CORRECTIONS to prior (2026-06-27) seeding/update — verified against live tree:
> - **Migrations: 0 → 10** `crt_*` create migrations live in `database/migrations/tenant/` (NOT the module's own empty `database/migrations/`), plus `2026_06_15_155842_add_tc_issued_to_std_students_table`. The module CAN bootstrap a fresh tenant. Prior "0 migrations / uses DDL directly" was WRONG.
> - **`std_students.tc_issued` gap RESOLVED** — alter migration exists (boolean default false). No longer a blocker.
> - **`crt_verification_logs` is NOT a P0 gap** — verification logging is BY DESIGN routed to `sys_activity_logs` (event `certificate.verify.qr`) via `QrVerificationService::logVerification()`; admin reader `VerificationController::logs()` queries `sys_activity_logs`. Reclassified from gap → design decision.
> - **Rate limiting IMPLEMENTED** — public `/certificate/verify/{hash}` route carries `throttle:20,60` (20/IP/hour). Prior "P3 unconfirmed" → resolved.
> - **Tests: not zero for browser** — a Dusk suite exists at `tests/Browser/Modules/Certificate/` (10 test classes: CertificateType, CertificateTemplate, CertificateRequest, CertificateIssued, CertificateReport, IdCardConfig, Verification, StudentDocument, BulkGeneration, CertificateStub; ~45 test methods). Still 0 PHPUnit/Pest unit/feature tests in-module.
> - **API `CertificateController` confirmed a non-functional stub** (`routes/api.php` → `apiResource('certificates', CertificateController)`; empty store/update/destroy, view-returning index/show). The keyed third-party verify interface (FR/REQ-CRT-007 AC4) is therefore NOT functional.

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `crt_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Certificates_DDL_v1.sql` — 10 tables |
| Migrations (LIVE) | **10** `crt_*` create migrations in `database/migrations/tenant/` (`2026_06_16_083558…083607`) + `add_tc_issued_to_std_students` (`2026_06_15_155842`). Module's own `database/migrations/` is empty (.gitkeep). Three-way reconcile DDL↔migration↔model PASSES; PK/FK = INT UNSIGNED (`increments()`/`unsignedInteger()`) consistent with DDL. |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/CRT_Certificate_Requirement.md` |
| V1 screen specs | `4-Requirement_Module_wise/2-Module_Requirement_V1/Certificate_v2/` — 13 files (00-Overview … 12-Type_Analytics) |
| Routes | **134 lines** `web.php` + **8 lines** `api.php` (verified 2026-06-29) |
| Controllers | **10**: BulkGenerationController, CertificateController (API stub), CertificateIssuedController, CertificateReportController, CertificateRequestController, CertificateTemplateController, CertificateTypeController, IdCardConfigController, StudentDocumentController, VerificationController. Note: V2-proposed `IdCardController` + `DocumentManagementController` were NOT used — replaced by `IdCardConfigController` + `StudentDocumentController`. |
| Models | **10** (matches DDL): BulkJob, CertificateRequest, CertificateTemplate, CertificateType, IdCardConfig, IssuedCertificate, SerialCounter, StudentDocument, TcRegister, TemplateVersion |
| Services | **3**: CertificateGenerationService ✅, QrVerificationService ✅ (also holds serial-counter `lockForUpdate` + TC `sl_no` increment + cert-number formatting + HMAC + QR), IdCardGenerationService ✅. `DmsService` proposed but **NOT created** — DMS logic lives in `StudentDocumentController` + TC gate in `CertificateGenerationService::generateTC()`. |
| FormRequests | **10**: ApproveCertificateRequest, BulkGenerateCertificates, RejectCertificateRequest, RevokeCertificate, StoreCertificateRequest, StoreCertificateTemplate, StoreCertificateType, StoreIdCardConfig, StoreStudentDocument, VerifyStudentDocument |
| Policies | **7**: BulkGeneration, CertificateIssued, CertificateRequest, CertificateTemplate, CertificateType, IdCardConfig, StudentDocument |
| Jobs | **1**: `BulkGenerateCertificatesJob` ✅ |
| Seeders | **4**: CertificateDatabaseSeeder, CrtCertificateTypeSeeder, CrtSeederRunner, CrtTemplateSeeder |
| Blade Views | **39** |
| Exports | **1**: `app/Exports/TcRegisterExport.php` (maatwebsite/excel TC register export) |
| Tests (in-module) | **0** PHPUnit/Pest |
| Tests (Dusk browser) | **~45 methods / 10 classes** at `tests/Browser/Modules/Certificate/` |
| FRD | **Complete FRD generated 2026-06-29** → `0-FRD_Documents/CRT_FRD_Complete_2026-06-29.md` (REQ-/BR-/RPT- IDs assigned — see FRD Summary) |

---

## DDL Layer Structure (10 tables)

| Layer | Tables | Notes |
|-------|--------|-------|
| Layer 1 (no crt_* deps) | `crt_certificate_types`, `crt_id_card_configs` | Both reference sys_* and sch_* only |
| Layer 2 (deps Layer 1) | `crt_templates`, `crt_serial_counters`, `crt_bulk_jobs`, `crt_student_documents` | Reference crt_certificate_types + sys/std tables |
| Layer 3 (deps Layer 2) | `crt_template_versions`, `crt_requests` | Versions archive templates; requests link to types |
| Layer 4 (deps Layer 3) | `crt_issued_certificates` | Links to requests + templates |
| Layer 5 (deps Layer 4) | `crt_tc_register` | Links to issued_certificates (TC legal register) |

---

## Feature Groups

| FR | Feature | Tables | Priority |
|----|---------|--------|----------|
| FR-CRT-001 | Certificate Type Management | `crt_certificate_types`, `crt_serial_counters` | Critical |
| FR-CRT-002 | Certificate Template Designer | `crt_templates`, `crt_template_versions` | Critical |
| FR-CRT-003 | Certificate Request Workflow | `crt_requests` | Critical |
| FR-CRT-004 | Certificate Generation & Issuance | `crt_issued_certificates`, `crt_serial_counters` | Critical |
| FR-CRT-005 | Transfer Certificate (TC) | `crt_requests`, `crt_issued_certificates`, `crt_tc_register` | Critical |
| FR-CRT-006 | Achievement & Bulk Certificates | `crt_issued_certificates`, `crt_bulk_jobs` | High |
| FR-CRT-007 | Digital Verification (QR + API) | `crt_issued_certificates`, `crt_verification_logs`* | Critical |
| FR-CRT-008 | ID Card Generation | `crt_id_card_configs`, `crt_id_card_issued`* | High |
| FR-CRT-009 | Document Management System (DMS) | `crt_student_documents` | High |
| FR-CRT-010 | Certificate Number Format Config | `crt_serial_counters`, `crt_certificate_types` | Medium |
| FR-CRT-011 | Reports & Analytics | `crt_issued_certificates`, `crt_requests` | Medium |
| FR-CRT-012 | Student & Parent Portal Access | `crt_requests`, `crt_issued_certificates` | High |

*Tables marked with asterisk are referenced in the requirement but NOT defined in DDL v1 — see DDL Gaps section.

---

## DDL Gaps (Requirement references tables not in DDL/migrations) — REASSESSED 2026-06-29

| Gap ID | Table | Referenced In | Status (2026-06-29) |
|--------|-------|--------------|---------------------|
| DDL-001 | `crt_verification_logs` | FR/REQ-CRT-007 — log every QR scan + keyed call | **RESOLVED / NOT A GAP — by design.** Logging goes to `sys_activity_logs` (event `certificate.verify.qr`); `VerificationController::logs()` reads from there. No table needed. |
| DDL-002 | `crt_id_card_issued` | FR/REQ-CRT-008 — handover tracking (card_received, date, student, config, issued_by) | **OPEN (P2).** No data store exists; ID-card handover/mark-received is unimplemented. No `markReceived` route. Tracked as ENH-CRT-011. |

**Action required**: only DDL-002 remains, and it is now a P2 enhancement (handover tracking), not a build blocker.

---

## DDL Corrections & Platform Deviations

| Item | Requirement Doc Claims | DDL Actual | Note |
|------|----------------------|------------|------|
| PK / FK types | BIGINT UNSIGNED (inferred from some prompts) | INT UNSIGNED | Matches `sys_users.id = INT UNSIGNED` in tenant_db |
| Academic session FK | `sch_academic_sessions` | `sch_org_academic_sessions_jnt` SMALLINT UNSIGNED | `sch_academic_sessions` does not exist in tenant_db |
| `std_students.tc_issued` | Assumed present | Does NOT exist in current tenant_db | Needs ALTER TABLE (see Cross-Module Schema Changes) |

---

## Cross-Module Schema Changes Required

BR-CRT-011 requires writing `std_students.tc_issued = true` after TC generation. This column does not exist.

**Migration (CRT_Migration.php up()):**
```sql
ALTER TABLE `std_students`
  ADD COLUMN `tc_issued` TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'Set to 1 by CRT module after TC issuance (BR-CRT-011)'
  AFTER `current_status_id`;
```

**Rollback (CRT_Migration.php down()):**
```sql
ALTER TABLE `std_students` DROP COLUMN IF EXISTS `tc_issued`;
```

---

## Key Design Decisions

1. **HMAC-SHA256 verification hash**: `verification_hash = HMAC-SHA256(certificate_no + issue_date + recipient_id + APP_KEY)`. UNIQUE index on `crt_issued_certificates.verification_hash` gives O(1) QR verification lookup. Immutable field — never recompute after issuance.

2. **`crt_template_versions` has NO `deleted_at`**: Archive records are immutable. Versions cannot be soft-deleted. If the parent template is deleted (CASCADE), all versions cascade-delete permanently. This is declared in DDL comment as "DDL Rule 14."

3. **`SELECT ... FOR UPDATE` on serial counters (BR-CRT-015)**: `SerialCounter::increment()` wraps `SELECT last_seq_no FROM crt_serial_counters WHERE certificate_type_id = ? AND academic_year = ? FOR UPDATE` in a DB transaction. This prevents concurrent generation from producing duplicate or non-sequential certificate numbers.

4. **TC issuance blocked by fee dues (BR-CRT-001)**: `CertificateGenerationService::generateTC()` checks `fin_fee_dues > 0` before proceeding. Admin can bypass only by recording an explicit override justification. The override is NOT stored in the DDL (no column for it) — it must be logged in `sys_activity_logs`.

5. **Revoked certificates stay in DB (BR-CRT-005)**: Verification endpoint returns REVOKED, not 404. `is_revoked = 1` + `revoked_at` + `revocation_reason` on `crt_issued_certificates`. Revoked certificates are soft-present — they prove existence of a previously valid certificate.

6. **Bulk threshold = 200 (BR-CRT-009)**: `BulkGenerationController::generate()` counts requested students: ≤ 200 may be synchronous; > 200 MUST dispatch `BulkGenerateCertificatesJob` to queue. Individual student failures log to `crt_bulk_jobs.error_log_json` and do not abort the batch.

7. **Public verification privacy (BR-CRT-010)**: `/verify/{hash}` response exposes ONLY: certificate type, issued-to (first name + last initial), issuing school name, issue date, validity status. Full name, DOB, class, section, address are NEVER exposed.

8. **One default template per type (BR-CRT-012)**: Setting `is_default = 1` on a template must auto-clear `is_default` on all other templates of the same `certificate_type_id`. Application-enforced toggle logic — no DB-level partial UNIQUE index used.

9. **Template cascade with type (FK ON DELETE CASCADE)**: `crt_templates.certificate_type_id` FK has `ON DELETE CASCADE`. However, `crt_issued_certificates.template_id` FK has `ON DELETE RESTRICT`. So: soft-deleting a type (soft) doesn't cascade; if a type is hard-deleted, templates cascade, but only if those templates have no issued certs (RESTRICT would block hard delete anyway).

10. **`requester_id` on `crt_requests` is polymorphic with no DB FK**: `requester_type ENUM('student','parent','staff','admin')` + `requester_id INT UNSIGNED` — no DB-level FK constraint. Application resolves the actual entity. Same pattern for `recipient_id` on `crt_issued_certificates`.

11. **Serial counter `academic_year` is the 4-digit year (SMALLINT UNSIGNED)**: e.g., 2026. Counter resets at start of each academic year. Serial format tokens: `{TYPE_CODE}`, `{YYYY}`, `{YY}`, `{SEQ4}`, `{SEQ6}`. Default format: `{TYPE_CODE}-{YYYY}-{SEQ6}` → `BON-2026-000042`.

---

## Business Rules

| Rule ID | Rule | Enforcement Point |
|---------|------|-------------------|
| BR-CRT-001 | TC blocked if `fin_fee_dues > 0`; admin override requires justification logged | `CertificateGenerationService::generateTC()` |
| BR-CRT-002 | TC serial (`crt_tc_register.sl_no`) must be sequential year-wise; no gaps | `SerialCounter::nextForType()` with `SELECT FOR UPDATE` |
| BR-CRT-003 | 2nd issuance to same recipient+type = `is_duplicate=true`; "DUPLICATE COPY" watermark in PDF | `CertificateIssuedController::store()` |
| BR-CRT-004 | `certificate_no` unique per tenant; format `{TYPE_CODE}-{YYYY}-{SEQ}` | UNIQUE index + SerialCounter lock |
| BR-CRT-005 | Revoked certs stay in DB; verification returns REVOKED, not 404 | `QrVerificationService::verifyHash()` |
| BR-CRT-006 | Templates with referenced issued certs cannot be hard-deleted | FK ON DELETE RESTRICT on `crt_issued_certificates.template_id` |
| BR-CRT-007 | ID cards must show blood group when present in `std_profiles`; blank field when absent | `IdCardController::generate()` |
| BR-CRT-008 | DMS docs with `verification_status=rejected` cannot satisfy cert eligibility checks | `CertificateRequestController::store()` validation |
| BR-CRT-009 | Bulk generation > 200 certs MUST use queue; sync forbidden above threshold | `BulkGenerationController::generate()` count check |
| BR-CRT-010 | Public verify endpoint must NOT expose full name, DOB, class, or address | `VerificationController::verify()` response DTO |
| BR-CRT-011 | TC issued → `std_students.tc_issued = true` + student status → withdrawn | Post-hook in `CertificateGenerationService` |
| BR-CRT-012 | Only one template per cert type may have `is_default=true` at any time | Toggle logic in `CertificateTemplateController` |
| BR-CRT-013 | Request rejection requires `rejection_reason` (NOT NULL) | `RejectCertificateRequestRequest` FormRequest |
| BR-CRT-014 | Supporting documents stored in `sys_media` with `model_type=CertificateRequest` | Polymorphic upload |
| BR-CRT-015 | Serial counter increment uses `SELECT ... FOR UPDATE` in a DB transaction | `SerialCounter::increment()` |

---

## Request Lifecycle (FSM)

```
[SUBMITTED by student/parent/clerk]
  → status = 'pending'
  → if requires_approval = false → auto-advance to APPROVED

[PENDING] → admin opens record → status = 'under_review'

[UNDER_REVIEW]
  → approve → status = 'approved' → CertificateGenerationService fired
  → reject  → status = 'rejected' [TERMINAL — rejection_reason required BR-CRT-013]

[APPROVED]
  → generation succeeds → status = 'generated'; crt_issued_certificates created
  → generation fails    → status stays 'approved'; error logged; admin retries

[GENERATED] → admin records handover → status = 'issued' [TERMINAL — positive]
```

## Bulk Job Lifecycle (FSM)

```
[QUEUED] → worker picks up → [PROCESSING]
[PROCESSING]
  → per student: generate PDF → processed_count++
  → individual failure: failed_count++; log to error_log_json (batch continues)
  → all done: create ZIP → [COMPLETED]
  → fatal error: [FAILED]
[COMPLETED] → download link shown to admin
[FAILED]    → admin notified; retry option
```

## QR Verification Flow

```
Third party scans QR → /verify/{hash}
  → Lookup crt_issued_certificates WHERE verification_hash = {hash}
    → not found: log(not_found) → NOT FOUND page
    → found:
        is_revoked?          → REVOKED
        validity_date < today → EXPIRED
        else                  → VALID
  → Log to crt_verification_logs (IP, agent, method=qr, result) [table not yet in DDL — DDL-001]
  → Render public.blade.php — minimal info only (BR-CRT-010)
```

---

## Cross-Module Dependencies

### Inbound (CRT reads from / integrates with)

| Module | Tables / Service | Data Used |
|--------|-----------------|-----------|
| StudentProfile (STD) | `std_students`, `std_profiles` | Name, DOB, photo, class, section, admission_no, blood_group, tc_issued flag |
| Academic Setup (SCH) | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_sections` | Session names, class/section labels for merge fields |
| Finance (FIN) | Fee outstanding amount | TC issuance eligibility check (BR-CRT-001) |
| System Media (SYS) | `sys_media` | Logo, seal, student photos for templates; DMS document storage |
| System Dropdown (SYS) | `sys_dropdown_table` | DMS document categories |
| System Users (SYS) | `sys_users` | `approved_by`, `issued_by`, `verified_by` — FK references throughout |

### Outbound (CRT writes to / triggers)

| Module | Interaction | Trigger |
|--------|------------|---------|
| Notification (NTF) | Outbound email/SMS dispatch | On request submission, approval, rejection |
| StudentProfile (STD) | Writes `std_students.tc_issued = true` | On TC generation (BR-CRT-011); requires ALTER TABLE |
| Audit Log (SYS) | Writes `sys_activity_logs` | On every data-changing action including downloads |

### Downstream (Modules that depend on CRT)

| Module | Usage |
|--------|-------|
| StudentPortal (STP) | Display and download own certificates; submit requests |
| ParentPortal (PPT) | Request certificates for ward; download issued certs |

---

## Merge Field Reference

| Merge Field | Source Table | Column |
|-------------|-------------|--------|
| `{{student_name}}` | `std_students` | `full_name` |
| `{{father_name}}` | `std_profiles` | `father_name` |
| `{{mother_name}}` | `std_profiles` | `mother_name` |
| `{{dob}}` | `std_students` | `dob` |
| `{{admission_no}}` | `std_students` | `admission_no` |
| `{{class_section}}` | `sch_classes`, `sch_sections` | `name` (joined) |
| `{{academic_session}}` | `sch_org_academic_sessions_jnt` | `name` |
| `{{date_of_admission}}` | `std_students` | `admission_date` |
| `{{nationality}}` | `std_profiles` | `nationality` |
| `{{blood_group}}` | `std_profiles` | `blood_group` |
| `{{certificate_no}}` | `crt_issued_certificates` | `certificate_no` |
| `{{issue_date}}` | `crt_issued_certificates` | `issue_date` |
| `{{validity_date}}` | `crt_issued_certificates` | `validity_date` (NULL → "No Expiry") |
| `{{principal_name}}` | `sch_school_profiles` | `principal_name` |
| `{{school_name}}` | `sch_school_profiles` | `school_name` |
| `{{qr_code}}` | Generated | base64 PNG embedded as `<img>` |

---

## Service Method Signatures

**`CertificateGenerationService`**
```php
generateFromRequest(CertificateRequest $request): CertificateIssued
generateDirect(CertificateType $type, int $recipientId, array $extraFields = []): CertificateIssued
generateTC(CertificateRequest $request, array $tcData): CertificateIssued
resolveMergeFields(int $studentId, array $extra = []): array
generateCertificateNo(CertificateType $type): string  // calls SerialCounter::increment()
```

**`QrVerificationService`**
```php
generateVerificationHash(CertificateIssued $cert): string  // HMAC-SHA256
generateQrCode(string $verificationUrl): string            // base64 PNG
verifyHash(string $hash): array                            // {valid, certificate, result, logged}
```

**`DmsService`**
```php
uploadDocument(int $studentId, UploadedFile $file, array $meta): StudentDocument
verifyDocument(StudentDocument $doc, string $status, string $remarks, int $verifierId): void
getDocumentsByStudent(int $studentId): Collection
hasVerifiedDocument(int $studentId, string $categoryCode): bool
```

---

## Technology Stack Notes

- **PDF Generation**: `barryvdh/laravel-dompdf` v3.1 — certificates and ID cards; UTF-8 for Hindi/Marathi/Tamil names
- **QR Codes**: `simplesoftwareio/simple-qrcode` v4.2 — one QR per certificate (verification URL) and per ID card (student/staff identifier)
- **Concurrency**: `SELECT ... FOR UPDATE` on `crt_serial_counters` (BR-CRT-015)
- **Queues**: Laravel Queue (Horizon/Redis) — `BulkGenerateCertificatesJob` required for > 200 certs
- **Excel Export**: `maatwebsite/excel` v3.x — issued register export; verify installation before use
- **File Storage**: `storage/tenant_{id}/certificates/{type_code}/{YYYY}/` — stancl/tenancy scoped disk
- **Verification API**: `GET /api/v1/certificate/verify?hash={hash}&api_key={key}` — API key rate-limited (60 req/min); returns HTTP 401 on missing/invalid key

---

## Certificate Type Categories & Serial Formats

| Category | Examples | Approval Required | Default Serial Format |
|----------|---------|------------------|----------------------|
| Administrative | Bonafide, Study/Conduct | Yes | `BON-2026-000001` |
| Legal / Government | TC, Migration | Yes + fee-clear check | `TC-2026-0001` |
| Character / Conduct | Character, Good Conduct | Yes | `CHR-2026-000001` |
| Achievement | Merit, Sports, Participation | No (admin-initiated) | `ACH-2026-000001` |
| Identity | Student ID Card, Staff ID Card | No (batch) | N/A |

**Serial format tokens**: `{TYPE_CODE}`, `{YYYY}`, `{YY}`, `{SEQ4}`, `{SEQ6}`
Default: `{TYPE_CODE}-{YYYY}-{SEQ6}` → `BON-2026-000042`

---

## Implementation Blockers (Prerequisites)

| # | Prerequisite | Owner Module | Blocks |
|---|-------------|-------------|--------|
| P1 | `std_students`, `std_profiles` tables complete | STD | All certificate generation (merge fields) |
| P2 | `sch_org_academic_sessions_jnt` complete | SCC/SCH | `crt_id_card_configs.academic_session_id` FK |
| P3 | `sys_users`, `sys_media`, `sys_dropdown_table` complete | SYS | All created_by FKs; DMS document storage; DMS categories |
| P4 | NTF module complete | NTF | Request status notifications |
| P5 | FIN module (fee check) | FIN | TC issuance eligibility (BR-CRT-001) |
| P6 | STD `tc_issued` column added via ALTER TABLE | STD/CRT | TC issuance post-hook (BR-CRT-011) |
| P7 | DDL v2 adds `crt_verification_logs` + `crt_id_card_issued` | DB Architect | FR-CRT-007 verification logs; FR-CRT-008 handover tracking |

---

## Implementation Sequence (Recommended)

| Phase | Components |
|-------|-----------|
| Phase 1 — Masters | `crt_certificate_types` CRUD + `crt_serial_counters` auto-init + serial format preview |
| Phase 2 — Templates | `crt_templates` CRUD + template version archive + default toggle + DomPDF preview |
| Phase 3 — Requests | `crt_requests` submission + 6-state FSM + duplicate block + media attachment |
| Phase 4 — Generation | `CertificateGenerationService` + HMAC hash + QR embed + PDF store + `crt_issued_certificates` |
| Phase 5 — TC | TC eligibility check + `crt_tc_register` auto-create + `std_students.tc_issued` update |
| Phase 6 — Verification | Public `/verify/{hash}` page + `crt_verification_logs` + API endpoint + rate limiting |
| Phase 7 — Bulk & Achievement | Direct issue (no request) + `BulkGenerateCertificatesJob` + ZIP download |
| Phase 8 — ID Cards | `crt_id_card_configs` + `crt_id_card_issued` + CR80/A5 layout + printable PDF grid |
| Phase 9 — DMS | `crt_student_documents` upload + verification workflow + eligibility gate |
| Phase 10 — Reports | Issued register export (Excel) + pending report + analytics chart (Chart.js) |
| Phase 11 — Portal | STP/PPT restricted views — own records + download + request submission |

---

## Immutable / Special Records

| Table | Special Behaviour |
|-------|-----------------|
| `crt_template_versions` | NO `deleted_at` — immutable archive; versions cascade-delete with parent template |
| `crt_issued_certificates` | `is_revoked` replaces deletion — never hard-delete issued certs |
| `crt_tc_register` | Legally mandated register; should never be deleted; has `deleted_at` in DDL but use with extreme caution |

---

## Technical Audit — Mode X (2026-06-29) — Authoritative 12-layer findings

> Code gap analysis completed against `CRT_FRD_Complete_2026-06-29.md`. Report:
> `3-Audit_Reports/V1_Jun-2026/Certificate_Complete_Audit_2026-06-29.md`.
> **Health 66/100 (Amber) — no P0 (uncapped). P0=0 · P1=6 · P2=6 · P3=5.**
> Structurally sound + well-gated module undermined by a cluster of wrong-table/column DB refs.

**Runtime-broken core features (P1) — wrong table/column refs verified against live tenant migrations:**
- **BUG-CRT-001** — TC fee gate queries `fin_fee_invoices` (table is `fee_invoices`; no `student_id`/`payment_status`/`net_payable` — linkage is `student_assignment_id`, col is `status` enum `'Paid'`, amount `balance_amount`). `generateTC()` throws `42S02` at the fee gate every time → REQ-CRT-005 non-functional. `CertificateGenerationService.php:91`.
- **BUG-CRT-002** — `generateTC()` snapshot joins `std_students.class_id/section_id` (absent — class/section is via `std_student_academic_sessions`→`sch_class_section_jnt`), reads `std_students.date_of_birth` (col is `dob`), queries `std_profiles` (table is `std_student_profiles`). `:119-146`.
- **BUG-CRT-003** — `IdCardGenerationService.php:82-94` repeats the same wrong joins (`class_id/section_id`, `std_profiles`, `date_of_birth`) → ID-card sheet generation (REQ-CRT-008) throws.
- **BUG-CRT-004** — `StudentDocumentController::store()` inserts `media_id => 0` into a `NOT NULL` FK→`sys_media` column → `23000` FK violation; DMS upload (REQ-CRT-009) fails for every doc, breaking the BR-CRT-008 TC gate dependency.
- **VAL-CRT-001** — BR-CRT-023 not enforced: `ApproveCertificateRequestRequest` marks `date_of_leaving`/`reason_for_leaving` nullable and `approve()` substitutes silent defaults (`today()`/`'Transfer'`).
- **SEC-CRT-001** — keyed verify API (REQ-CRT-007 AC4 / BR-CRT-027) is the empty scaffold `CertificateController` (`apiResource` returns Blade views). = ENH-CRT-012 / RISK-CRT-003.

**P2:** BUG-CRT-005 (restore/forceDelete always 403 on Issued/Request/Template — policies lack those abilities, no `before()`); DATA-CRT-001 ({{father_name}}/{{mother_name}}/{{blood_group}} always blank — `std_student_profiles` has no such cols; {{nationality}}/{{religion}} emit raw FK ids); SEC-CRT-002 (no `EnsureTenantHasModule`); DEAD-CRT-001 (scaffold controller); PERF-CRT-001 (BR-CRT-033 overdue highlight missing); SCH-CRT-001 (D29 ~10 enums).

**CORRECTIONS to prior notes (verified against live tenant migrations 2026-06-29):**
- `sys_dropdowns` **does exist in tenant_db** (created as `sys_dropdown_table`, renamed by `...145407_rename_sys_dropdown_table_to_sys_dropdowns`). The Section-20 "category → sys_dropdown_table" note and the "status-master table name" open item are RESOLVED — code uses `sys_dropdowns` correctly.
- `sys_activity_logs` **exists** (migration file `create_activity_logs_table.php` but `Schema::create('sys_activity_logs')`). Verification + download logging target a real table.
- **RISK-CRT-005 (PDF storage isolation) — FALSE POSITIVE / RESOLVED.** `config/tenancy.php` enables `FilesystemTenancyBootstrapper` + `suffix_storage_path => true`, so `storage_path('app/tenant_certificates/...')` is per-tenant (`storage/tenant<id>/`). No cross-tenant collision. (Hygiene note: relies on implicit suffixing, not an explicit `Storage::disk('tenant')`.)
- Job tenancy is **correct** (QueueTenancyBootstrapper enabled + dispatched in tenant context); only `tries=1`/no backoff remains (P3). Bulk inherits the platform `queue=database` vs Horizon `redis` mismatch (DEPLOY-HRZ-01).

---

## Known Gaps & Open Issues (REASSESSED 2026-06-29)

| Priority | Gap | Detail |
|----------|-----|--------|
| P1 | **TC fee-override path NOT implemented** | BR-CRT-001 allows an admin override on fee dues, but `CertificateGenerationService::generateTC()` throws unconditionally when dues > 0 (`fin_fee_invoices` sum of `net_payable` where `payment_status != 'paid'`). No override capture. (RISK-CRT-002, Sprint task 1.) |
| P1 | **Keyed third-party verification interface is a non-functional stub** | `routes/api.php` → `apiResource('certificates', CertificateController)`; `CertificateController` has empty store/update/destroy and view-returning index/show. REQ-CRT-007 AC4 keyed verify is not functional. (RISK-CRT-003, ENH-CRT-012.) |
| P1 | **Certificate file storage not tenant-scoped** | PDFs written to `storage_path('app/tenant_certificates/...')` (local), not the stancl tenant-scoped disk implied by NFR-CRT-006. Confirm isolation. (RISK-CRT-005.) |
| P1 | **0 in-module unit/feature tests** | Concurrency-critical logic (serial-counter `lockForUpdate`, duplicate detection, >200 bulk threshold, TC fee/doc gate) untested by PHPUnit/Pest. ~45-method Dusk suite exists but covers UI flows, not the locking/HMAC internals. |
| P2 | **ID card handover tracking absent** | No `crt_id_card_issued` store and no mark-received route; REQ-CRT-008 handover unimplemented. (ENH-CRT-011.) |
| P2 | **`DmsService` not created** | DMS logic lives in `StudentDocumentController` + the TC gate in `CertificateGenerationService::generateTC()` (rejected-doc count check). Not a defect, just a composition difference; audit for fat-controller risk. |
| P2 | **Status-master table name** | TC withdrawal resolves via `sys_dropdowns` (key `student_status`, value `Withdrawn`); confirm this matches the platform status master (vs `sys_dropdown_table`). |
| P0(gov) | **Cross-module TC / request overlap** | Separate `adm_transfer_certificates` (Admission) and `fof_certificate_requests` (Front Office) tables exist in parallel with CRT's TC register & request flow. Two legal TC registers risk conflict. Decide authoritative owner. (RISK-CRT-001; FRD Q-CRT-1, Q-CRT-2.) |

> CLOSED since 2026-06-27: `crt_verification_logs` (by-design → sys_activity_logs), `std_students.tc_issued` (migration added), "0 migrations" (10 exist), rate-limiting (throttle:20,60 present).

---

## Pending Next Steps

- [ ] **Code Gap Analysis** → `act as Technical Auditor` against `CRT_FRD_Complete_2026-06-29.md` (12-layer, reuse REQ-/BR- IDs)
- [ ] Implement TC fee-override capture + audit (BR-CRT-001 / Sprint task 1)
- [ ] Implement or remove the keyed third-party verify interface (REQ-CRT-007 / ENH-CRT-012)
- [ ] Confirm/repair tenant-scoped certificate file storage (NFR-CRT-006 / RISK-CRT-005)
- [ ] Add feature/unit tests for serial-counter lock, duplicate, bulk threshold, TC gate
- [ ] Governance: resolve CRT-vs-Admission TC and CRT-vs-FrontOffice request overlap (Q-CRT-1, Q-CRT-2)
- [ ] DB Architect: confirm `crt_tc_register.sl_no SMALLINT UNSIGNED` — state boards with > 32,767 TCs/year need INT UNSIGNED
- [ ] Seed pre-built templates (Bonafide, TC, Character, Sports, ID CR80) — S03/ENH-CRT-003

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (CRT_Certificate_Requirement.md v2) + DDL (Certificates_DDL_v1.sql). Identified 2 DDL gaps (crt_verification_logs, crt_id_card_issued), cross-module schema change (std_students.tc_issued). Status incorrectly recorded as 0% Greenfield — code not checked at seeding. DmsService method signatures documented but service was never created. |
| 2026-06-27 | Business Analyst | Update pass: verified actual file counts against prime_ai/Modules/Certificate/. Status corrected to ~55–60%. Corrections: controllers 9→10 (CertificateController found), services composition differs (IdCardGenerationService present, DmsService absent — P0 gap). Added: 10 FormRequests, 7 policies, 4 seeders (not counted at seeding). Views ~30→39, routes ~59→134 lines. 0 tests (30 proposed — critical). DDL gaps from seeding still open. |
| 2026-06-29 | Technical Auditor | Mode X complete audit vs CRT_FRD_Complete. Health 66/100 (no P0). Found P1 cluster: TC/ID-card/DMS broken at runtime via wrong table/column refs (BUG-CRT-001..004), BR-CRT-023 not enforced (VAL-CRT-001), keyed verify API stub (SEC-CRT-001). P2: restore/forceDelete 403 (BUG-CRT-005), blank merge fields (DATA-CRT-001), no module-plan middleware (SEC-CRT-002), D29 enums. Corrected stale notes: sys_dropdowns/sys_activity_logs exist in tenant; RISK-CRT-005 false positive (suffix_storage_path=true); job tenancy OK. Report at 3-Audit_Reports/V1_Jun-2026/Certificate_Complete_Audit_2026-06-29.md. |
