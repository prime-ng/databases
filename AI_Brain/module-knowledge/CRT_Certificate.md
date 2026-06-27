# Module Knowledge: Certificate (CRT)
# Last Updated: 2026-06-27 (update pass — file counts verified against Herd/prime_ai)
# Completion Status: ~55–60% (all models/controllers/services/policies present; 39 views; 4 seeders; 0 tests critical; DmsService not created)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `crt_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Certificates_DDL_v1.sql` — 10 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/CRT_Certificate_Requirement.md` |
| Routes | **134 lines** in `Modules/Certificate/routes/web.php` (re-verified 2026-06-27; prior estimate ~59) |
| Controllers | **10** actual (re-verified — **corrected from 9**; extra: `CertificateController` as base/main controller): BulkGenerationController, CertificateController, CertificateIssuedController, CertificateReportController, CertificateRequestController, CertificateTemplateController, CertificateTypeController, IdCardConfigController, StudentDocumentController, VerificationController |
| Models | **10** actual (re-verified — matches DDL table count): BulkJob, CertificateRequest, CertificateTemplate, CertificateType, IdCardConfig, IssuedCertificate, SerialCounter, StudentDocument, TcRegister, TemplateVersion |
| Services | **3** actual (re-verified — **composition differs from proposal**): CertificateGenerationService ✅, QrVerificationService ✅, **IdCardGenerationService** ✅ — `DmsService` was proposed but **NOT created**; ID card gets its own service instead |
| FormRequests | **10** actual (not counted in seeding): ApproveCertificateRequest, BulkGenerateCertificates, RejectCertificateRequest, RevokeCertificate, StoreCertificateRequest, StoreCertificateTemplate, StoreCertificateType, StoreIdCardConfig, StoreStudentDocument, VerifyStudentDocument |
| Policies | **7** actual (not counted in seeding): BulkGeneration, CertificateIssued, CertificateRequest, CertificateTemplate, CertificateType, IdCardConfig, StudentDocument |
| Jobs | **1** actual: `BulkGenerateCertificatesJob` ✅ |
| Seeders | **4** actual: CertificateDatabaseSeeder, CrtCertificateTypeSeeder, CrtSeederRunner, CrtTemplateSeeder |
| Blade Views | **39** actual (re-verified; prior estimate ~30) |
| Tests | **0** actual (**30 test cases proposed — none implemented**; critical gap) |
| Migrations | **0** — module uses DDL directly |
| Functional Requirements | 12 (FR-CRT-001 … FR-CRT-012) |
| Business Rules | 15 (BR-CRT-001 … BR-CRT-015) |
| FRD | Not yet generated |

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

## DDL Gaps (Requirement references tables not in DDL v1)

| Gap ID | Table | Referenced In | Impact |
|--------|-------|--------------|--------|
| DDL-001 | `crt_verification_logs` | FR-CRT-007 — every public QR scan + API call must be logged (IP, user-agent, method, result) | **P0** — VerificationController::logs() admin screen and QrVerificationService::verifyHash() cannot write logs without this table |
| DDL-002 | `crt_id_card_issued` | FR-CRT-008 — handover tracking (`card_received`, date, student_id, config_id, issued_by) | **P1** — ID card handover marking (BR-CRT requirement AC6) is unimplementable without this table |

**Action required**: DB Architect must add these 2 tables to DDL v2 before implementation.

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

## Known Gaps & Open Issues (as of 2026-06-27)

| Priority | Gap | Detail |
|----------|-----|--------|
| P0 | **`crt_verification_logs` table missing from DDL** | QR scan logging (`VerificationController::logs()`, `QrVerificationService::verifyHash()`) cannot write logs — table undefined. Must be added to DDL v2 before Phase 6 implementation. |
| P0 | **`DmsService` not created** | The seeded knowledge file included full DmsService method signatures (uploadDocument, verifyDocument, getDocumentsByStudent, hasVerifiedDocument). Actual code has no DmsService — `StudentDocumentController` likely handles DMS logic directly (fat controller risk). Needs audit. |
| P1 | **0 test files** | 30 test cases specified (T01–T30); none implemented. HMAC-SHA256 hash uniqueness, `SELECT...FOR UPDATE` on serial counters, bulk threshold enforcement (>200), duplicate certificate detection, and TC fee-clearance check are all high-risk without tests. |
| P1 | **`crt_id_card_issued` table missing from DDL** | ID card handover tracking (FR-CRT-008, BR requirement AC6) unimplementable. `IdCardGenerationService` exists but cannot record issued status. |
| P1 | **`std_students.tc_issued` column missing** | BR-CRT-011 requires writing this column after TC generation. Column must be added via `ALTER TABLE` migration before Phase 5 implementation. |
| P1 | **0 migrations** | Module uses DDL directly; cannot bootstrap a fresh tenant via `artisan migrate`. |
| P2 | **`IdCardGenerationService` service signature unknown** | This service was not in the V2 requirement — no documented method signatures. Needs Technical Audit to understand what it generates and how it interacts with `IdCardConfigController`. |
| P2 | **Controller logic completeness unknown** | 10 controllers present but all 11 implementation phases are complex (concurrency, FSM, HMAC, PDF generation). Technical Audit needed to assess stub vs. implemented. |
| P3 | **Rate limiting on `/verify/{hash}` unconfirmed** | BR-CRT-010 + verification API require rate limiting (60 req/min for API key endpoint). Not confirmed in routes or middleware. |

---

## Pending Next Steps

- [ ] DB Architect: Add `crt_verification_logs` + `crt_id_card_issued` tables to DDL v2
- [ ] DB Architect: Confirm `crt_tc_register.sl_no SMALLINT UNSIGNED` — state boards with > 32,767 TCs/year need INT UNSIGNED
- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for Certificate"
- [ ] CRT_Migration.php: Include `ALTER TABLE std_students ADD COLUMN tc_issued` in `up()`
- [ ] Verify `maatwebsite/excel` installation (required for FR-CRT-011 export)
- [ ] Implement rate limiting on public `/verify/{hash}` endpoint (BR-CRT-010 + S06 suggestion)
- [ ] Seed 5 pre-built templates (Bonafide, TC government format, Character, Sports landscape, ID CR80) as DB seeders (S03 suggestion)
- [ ] Code Gap Analysis → `act as Technical Auditor` — after FRD generated

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (CRT_Certificate_Requirement.md v2) + DDL (Certificates_DDL_v1.sql). Identified 2 DDL gaps (crt_verification_logs, crt_id_card_issued), cross-module schema change (std_students.tc_issued). Status incorrectly recorded as 0% Greenfield — code not checked at seeding. DmsService method signatures documented but service was never created. |
| 2026-06-27 | Business Analyst | Update pass: verified actual file counts against prime_ai/Modules/Certificate/. Status corrected to ~55–60%. Corrections: controllers 9→10 (CertificateController found), services composition differs (IdCardGenerationService present, DmsService absent — P0 gap). Added: 10 FormRequests, 7 policies, 4 seeders (not counted at seeding). Views ~30→39, routes ~59→134 lines. 0 tests (30 proposed — critical). DDL gaps from seeding still open. |
