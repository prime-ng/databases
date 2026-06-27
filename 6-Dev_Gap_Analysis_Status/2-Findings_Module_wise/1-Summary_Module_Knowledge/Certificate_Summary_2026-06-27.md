# Module Knowledge Summary: Certificate (CRT)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/CRT_Certificate_Requirement.md` (V2, 12 FRs, 15 BRs)
- `2-DDL_Tenant_Consolidated/Certificates_DDL_v1.sql` (10 tables, 5 dependency layers)
- `Herd/prime_ai/Modules/Certificate/` (live filesystem verification — two passes: seeding + update on 2026-06-27)

**Knowledge File:** `AI_Brain/module-knowledge/CRT_Certificate.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `CRT` |
| Table Prefix | `crt_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/Certificate/` |
| DDL Version | v1 (5 dependency layers, 10 tables — 2 additional tables needed for v2) |
| V2 Requirement | `CRT_Certificate_Requirement.md` (12 FRs, 15 BRs) |
| Compliance Scope | Legal certificates (TC, Migration), HMAC-SHA256 tamper-proof verification, QR verification logging |
| FRD Status | Not yet generated |

**Key Discovery from this session:** Seeded as 0% Greenfield, corrected to ~55–60% on same-session update pass. Additionally: `DmsService` was fully documented in the knowledge file with 4 method signatures as if implemented — but the service does not exist in the actual codebase. `IdCardGenerationService` (not in the V2 req) was created instead. This is the most significant service substitution found in the audit to date.

---

## 2. Actual vs. Proposed Comparison

| Metric | Seeded Estimate | Actual (Verified) | Change |
|--------|----------------|-------------------|--------|
| Controllers | **9** (undercount) | **10** | +1 (`CertificateController` as base/main) |
| Models | 10 proposed | **10** | Exact match (one per DDL table) |
| Services | 3 proposed | **3** (composition differs — see Section 4) | Count matches; names don't |
| FormRequests | Not counted | **10** | Discovered in update pass |
| Policies | Not counted | **7** | Discovered in update pass |
| Jobs | 1 proposed | **1** (`BulkGenerateCertificatesJob`) | Exact match |
| Seeders | Not counted | **4** | Discovered in update pass |
| Tests | 30 proposed | **0** | Critical gap |
| Blade Views | ~30 estimated | **39** | +9 |
| Route Lines | ~59 estimated | **134 lines** | +75 (2.3× estimate) |
| Migrations | Required | **0** | Gap |
| Completion % | 0% (incorrectly seeded) | **~55–60%** | Corrected |

**Noteworthy:** FormRequests (10) and Policies (7) were not recorded at all during seeding — not 0, just not checked. Seeders (4) also discovered only on update pass. Seeding a module without running `ls app/Http/Requests/`, `ls app/Policies/`, and `ls database/seeders/` misses entire code categories.

---

## 3. DDL Architecture: 5-Layer Dependency Chain (10 Tables)

| Layer | Tables | Role |
|-------|--------|------|
| 1 — Masters | `crt_certificate_types`, `crt_id_card_configs` | No crt_* dependencies; pure config masters |
| 2 — Setup | `crt_templates`, `crt_serial_counters`, `crt_bulk_jobs`, `crt_student_documents` | Reference Layer 1 + sys/std tables |
| 3 — Versioning & Requests | `crt_template_versions`, `crt_requests` | Versions archive templates; requests link to types |
| 4 — Issuance | `crt_issued_certificates` | Links to requests + templates; core issuance record |
| 5 — Legal Register | `crt_tc_register` | Links to issued certificates; legally mandated TC register |

**Migration order must follow layers 1→2→3→4→5.** 10 migrations needed for existing tables + 2 more once DDL v2 adds the missing tables.

---

## 4. The DmsService Discovery: Documented but Never Created (P0)

**This is the most significant finding in this module's knowledge work.**

The seeding pass documented `DmsService` with full PHP method signatures:
```php
uploadDocument(int $studentId, UploadedFile $file, array $meta): StudentDocument
verifyDocument(StudentDocument $doc, string $status, string $remarks, int $verifierId): void
getDocumentsByStudent(int $studentId): Collection
hasVerifiedDocument(int $studentId, string $categoryCode): bool
```

The update pass found that **`DmsService` does not exist.** The `app/Services/` directory contains:
- `CertificateGenerationService` ✅ (in V2 req)
- `QrVerificationService` ✅ (in V2 req)
- `IdCardGenerationService` ✅ (**NOT in V2 req — new discovery**)

**What this means:**
1. Document upload, verification, and eligibility-gate logic (`BR-CRT-008`: docs with `verification_status=rejected` block cert eligibility) likely lives inside `StudentDocumentController` directly — a fat controller risk.
2. `IdCardGenerationService` was created as a replacement scope, but its method signatures are unknown — not in any requirement document.
3. `hasVerifiedDocument()` (eligibility gate for cert requests based on doc verification status) has no confirmed implementation location.

**Risk:** If document verification logic is in the controller, it cannot be unit-tested in isolation. The eligibility gate (`BR-CRT-008`) cannot be called from other controllers without duplicating the check.

---

## 5. Two DDL Gaps — Tables Required But Not Defined in DDL v1

Two feature areas in the V2 requirement reference tables that do not exist in DDL v1. Both must be added to DDL v2 before the corresponding features can be implemented.

### DDL-001: `crt_verification_logs` — P0

| Item | Detail |
|------|--------|
| Referenced in | FR-CRT-007 — every public QR scan + API call must be logged |
| What it stores | IP address, user-agent, scan method (QR / API), result (valid/revoked/expired/not_found), timestamp |
| Impact | `VerificationController::logs()` admin screen cannot populate; `QrVerificationService::verifyHash()` cannot write logs |
| Why P0 | Without this table, the public verification endpoint silently succeeds or fails with no audit trail — unacceptable for legal certificates |

### DDL-002: `crt_id_card_issued` — P1

| Item | Detail |
|------|--------|
| Referenced in | FR-CRT-008 — handover tracking (card_received flag, date, student_id, config_id, issued_by) |
| Impact | `IdCardGenerationService` can generate cards but cannot record that the physical card was handed to the student |
| Why P1 | ID card handover marking is a compliance requirement (AC6); `IdCardGenerationService` exists but is incomplete without this table |

---

## 6. Cross-Module Schema Change Required: `std_students.tc_issued`

BR-CRT-011 requires writing `std_students.tc_issued = true` after TC issuance. This column **does not exist** in the current `std_students` table.

A cross-module ALTER TABLE migration is required:
```sql
-- Must run in CRT's migration file (not STD's — CRT owns the business rule)
ALTER TABLE `std_students`
  ADD COLUMN `tc_issued` TINYINT(1) NOT NULL DEFAULT 0
  COMMENT 'Set to 1 by CRT module after TC issuance (BR-CRT-011)'
  AFTER `current_status_id`;
```

**Implication:** CRT module migrations must run after STD module migrations. CRT owns the `tc_issued` column life-cycle — STD tables are a prerequisite. The rollback (`DROP COLUMN IF EXISTS`) must also be in CRT's migration `down()`.

---

## 7. HMAC-SHA256 Verification — Core Security Architecture

The certificate verification system is built on HMAC-SHA256 tamper-proof hashing:

```
verification_hash = HMAC-SHA256(certificate_no + issue_date + recipient_id + APP_KEY)
```

Properties of this design:
- UNIQUE index on `crt_issued_certificates.verification_hash` → O(1) QR verification lookup (no full-table scan)
- `APP_KEY` rotation = ALL verification hashes become invalid (breaking change — must communicate to users)
- Immutable after issuance — **never recompute the hash after `crt_issued_certificates` row is created**
- QR code URL = `/verify/{hash}` — hash is the only lookup key; certificate_no is not in the URL

**Current test coverage for HMAC:** 0 — the hash generation (`QrVerificationService::generateVerificationHash()`) has no tests. A hash collision or incorrect input concatenation order would produce invalid QR codes for all future certificates without any visible error.

---

## 8. SELECT...FOR UPDATE on Serial Counters

Concurrent certificate generation from two browser sessions would produce duplicate certificate numbers without row-level locking. `SerialCounter::increment()` uses:

```php
DB::transaction(function () use ($typeId, $year) {
    $counter = SerialCounter::lockForUpdate()
        ->where('certificate_type_id', $typeId)
        ->where('academic_year', $year)
        ->first();
    // increment last_seq_no
    // return formatted certificate_no
});
```

**Business Rule BR-CRT-015:** Serial counter increment MUST use `SELECT ... FOR UPDATE` in a DB transaction.

**Also applies to TC serial register:** `crt_tc_register.sl_no` must be sequential year-wise (BR-CRT-002). Both share the same `SerialCounter::increment()` pattern.

**Type concern flagged:** `crt_tc_register.sl_no` is `SMALLINT UNSIGNED` (max 32,767). Large state boards issuing TC for multiple schools may exceed this in a single year. DB Architect must decide: keep SMALLINT or migrate to INT UNSIGNED before production.

**Current test coverage for concurrency:** 0 — no tests verify that concurrent increment calls produce unique sequential numbers.

---

## 9. Bulk Certificate Generation: Sync vs Queue Threshold

**Business Rule BR-CRT-009:** Bulk generation logic in `BulkGenerationController::generate()`:

```
if (count(requested_students) <= 200):
    → May be synchronous (blocks HTTP request)
else:
    → MUST dispatch BulkGenerateCertificatesJob (queued)
```

`BulkGenerateCertificatesJob` exists and implements `ShouldQueue` ✅. The job:
- Generates PDF per student (calls `CertificateGenerationService`)
- On individual failure: increments `failed_count`, logs to `crt_bulk_jobs.error_log_json` — **batch continues**
- On all done: creates ZIP archive → status = `COMPLETED`
- On fatal error: status = `FAILED`

**Current test coverage for bulk threshold:** 0 — no test verifies that ≤200 stays synchronous and >200 dispatches the job. A misconfigured threshold could silently block long HTTP requests in production.

---

## 10. Key Architecture Decisions (11 Documented)

| Decision | Summary | Risk if Missed |
|----------|---------|---------------|
| D1 — HMAC-SHA256 verification hash | Unique hash per cert; UNIQUE index; immutable after issuance | Hash recompute post-issuance breaks QR for certificate holders |
| D2 — `crt_template_versions` immutable | No `deleted_at`; cascade-delete with parent template only | Accidental soft-delete attempt produces error |
| D3 — SELECT...FOR UPDATE on serial counters | Row-level lock per type per year | Concurrent generation produces duplicate cert numbers |
| D4 — TC blocked by fee dues + override audit | `fin_fee_dues > 0` check; admin override logged to `sys_activity_logs` only (no DDL column) | Silent TC generation without fee clearance |
| D5 — Revoked certs stay in DB | `is_revoked = 1` + `revoked_at` + `revocation_reason`; verification returns REVOKED, not 404 | Hard-delete on revoke destroys evidence of prior valid cert |
| D6 — Bulk threshold = 200 | ≤200 synchronous; >200 MUST use queue; individual failure doesn't abort batch | Large bulk run blocks HTTP if threshold check is missing |
| D7 — Public verification minimal exposure | `/verify/{hash}` exposes: cert type, first-name + last-initial, school, date, status ONLY | Full name/DOB/class exposure violates privacy (BR-CRT-010) |
| D8 — One default template per type | `is_default = 1` toggle auto-clears all others for same type; application-level, no partial UNIQUE index | Two defaults for same type = ambiguous template selection |
| D9 — Template cascade vs issued cert restrict | Templates cascade-delete with type (`ON DELETE CASCADE`); issued certs RESTRICT template delete | Attempting to delete a template with issued certs throws FK error |
| D10 — `requester_id` polymorphic, no FK | `requester_type ENUM + requester_id INT` — no DB-level FK; app resolves actual entity | No referential integrity on requester; orphan request records possible |
| D11 — Serial counter resets per academic year | Counter keyed by `certificate_type_id + academic_year (SMALLINT/4-digit)` | Wrong year key produces duplicate serial from prior year's sequence |

---

## 11. Request Lifecycle FSM (6 States)

```
SUBMITTED (student/parent/clerk)
  → pending
  → if requires_approval = false → auto-advance to APPROVED

PENDING → admin opens → UNDER_REVIEW

UNDER_REVIEW
  → approve → APPROVED → CertificateGenerationService fires
  → reject  → REJECTED [TERMINAL — rejection_reason required (BR-CRT-013)]

APPROVED
  → generation succeeds → GENERATED; crt_issued_certificates created
  → generation fails    → stays APPROVED; error logged; admin retries

GENERATED → admin records handover → ISSUED [TERMINAL — positive]
```

**QR Verification Flow:**
```
Third party scans QR → GET /verify/{hash}
  → Lookup crt_issued_certificates WHERE verification_hash = hash
    → not found       → NOT FOUND page
    → is_revoked = 1  → REVOKED
    → validity_date < today → EXPIRED
    → else            → VALID
  → Log to crt_verification_logs [TABLE NOT YET IN DDL — DDL-001]
  → Render public.blade.php — minimal info only (BR-CRT-010)
```

---

## 12. Open Gaps & Recommended Actions

### P0 — Must Resolve Before Implementation

| Gap | Recommended Action |
|-----|-------------------|
| **`crt_verification_logs` table missing from DDL** | DB Architect: add table to DDL v2 with columns: id, hash, ip_address, user_agent, method ENUM('qr','api'), result ENUM('valid','revoked','expired','not_found'), verified_at. No `updated_at`, no `deleted_at` (immutable log). |
| **`DmsService` never created** | Technical Audit: check `StudentDocumentController` for DMS logic; extract to `DmsService` with documented method signatures; verify `hasVerifiedDocument()` is callable for cert eligibility gate (BR-CRT-008) |

### P1 — Critical Before Go-Live

| Gap | Recommended Action |
|-----|-------------------|
| **0 test files** (30 proposed T01–T30) | Priority: HMAC-SHA256 hash correctness, `SELECT...FOR UPDATE` serial counter concurrency, bulk threshold enforcement (≤200 sync vs >200 queue), duplicate certificate detection (BR-CRT-003), TC fee-clearance check (BR-CRT-001) |
| **`crt_id_card_issued` table missing** | DB Architect: add table to DDL v2; `IdCardGenerationService` is incomplete without handover tracking |
| **`std_students.tc_issued` column missing** | Developer: create `CRT_Migration.php` with `ALTER TABLE std_students ADD COLUMN tc_issued` in `up()`; `DROP COLUMN IF EXISTS` in `down()` |
| **0 migrations** | Create 10 tenant migrations in 5-layer order; include ALTER TABLE for `std_students.tc_issued` |

### P2 — Architecture Verification

| Gap | Recommended Action |
|-----|-------------------|
| **`IdCardGenerationService` method signatures unknown** | Technical Audit: document what this service generates, how it interacts with `IdCardConfigController`, and what CR80/A5 layout options it supports |
| **Controller logic completeness unknown** | Technical Audit (Mode A): verify whether all 11 implementation phases have implemented logic or stubs |
| **Rate limiting on `/verify/{hash}` unconfirmed** | Check routes + middleware: must be 60 req/min for API key endpoint; public QR endpoint should also be throttled |

### P3 — Pre-Production Items

| Gap | Recommended Action |
|-----|-------------------|
| **`crt_tc_register.sl_no` type** | DB Architect: decide SMALLINT UNSIGNED (max 32,767) vs INT UNSIGNED for large boards |
| **5 pre-built template seeders** | Developer: Bonafide, TC government format, Character, Sports landscape, ID CR80 as seeded DomPDF templates |
| **`maatwebsite/excel` installation** | Verify package is in `composer.json` before FR-CRT-011 (issued register export) work begins |

---

## 13. Cross-Module Integration Map

### CRT Reads From:
| Module | Integration |
|--------|-----------|
| StudentProfile (STD) | `std_students`, `std_profiles` — name, DOB, photo, class, section, admission_no, blood_group |
| SchoolSetup (SCH) | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_sections` — session names, class/section labels for merge fields |
| Finance (FIN) | Fee outstanding amount — TC issuance eligibility check (BR-CRT-001) |
| System (SYS) | `sys_media` — logo, seal, student photos, DMS document storage; `sys_dropdown_table` — DMS categories; `sys_users` — `approved_by`, `issued_by`, `verified_by` FKs |

### CRT Writes To / Triggers:
| Module | Interaction |
|--------|-----------|
| StudentProfile (STD) | Writes `std_students.tc_issued = true` on TC generation (BR-CRT-011); column must be pre-added via ALTER TABLE |
| Notification (NTF) | Outbound dispatch on request submission, approval, rejection |
| System Audit (SYS) | Writes `sys_activity_logs` on every data-changing action including downloads |

### Downstream Consumers:
| Module | Uses |
|--------|------|
| Student Portal (STP) | View and download own certificates; submit cert requests |
| Parent Portal (PPT) | Request certificates for ward; download issued certs |

---

## 14. Key Lessons Learned

1. **A service documented with full method signatures in a knowledge file is NOT the same as an implemented service.** `DmsService` had 4 fully documented PHP method signatures in the seeded knowledge file. The update pass found no DmsService file. The lesson: document what the requirement *proposes*; verify what *exists*; clearly distinguish the two. Any seeding that copies method signatures from a requirement doc must label them "Proposed — not yet verified."

2. **Service substitution happens during development without requirement updates.** `IdCardGenerationService` was created in place of `DmsService` (or as an addition to it) — this design decision is not reflected in the V2 requirement doc. The requirement described `DmsService`; the developer created `IdCardGenerationService`. The requirement is now stale on the service layer. FRD generation must read actual `app/Services/` contents, not just the req doc.

3. **DDL gaps that block entire feature areas must be discovered before seeding is complete.** `crt_verification_logs` and `crt_id_card_issued` are referenced in requirement text but not defined in DDL v1. If implementation starts based on seeded knowledge (which came from the req doc), these gaps would only surface when `QrVerificationService::verifyHash()` tries to insert a log row. Discovering them at seeding time gives DB Architect lead time before development begins.

4. **Cross-module ALTER TABLE migrations are a hidden dependency.** `std_students.tc_issued` is owned by the STD module's table but added by a CRT module migration. This means CRT migrations have a hard dependency on STD migrations completing first. Multi-module migration ordering must be documented explicitly.

5. **FormRequests, Policies, and Seeders are systematically missed when seeding from requirement docs.** All three categories (10 FormRequests, 7 policies, 4 seeders) were discovered only in the update pass. Requirement docs describe screens and business rules — they do not itemise FormRequest or Policy classes. The seeding checklist must always include explicit `ls` of these three directories.

6. **Concurrency-critical and security-critical code with 0 tests is the highest audit risk.** CRT has two concurrency-critical paths (serial counter `SELECT...FOR UPDATE`, bulk threshold enforcement) and one security-critical path (HMAC-SHA256 hash generation). All three have 0 tests. A bug in any of these produces: duplicate certificate numbers (correctness), performance failures on bulk (scalability), or broken QR verification for all future certificates (trust/compliance).

7. **Revoked-not-deleted is a legal certificate design contract.** `is_revoked = 1` on `crt_issued_certificates` preserves evidence of a previously valid certificate. Hard-delete on revoke destroys this evidence. Any developer who sees "delete" in a certificate revoke ticket and issues a `->delete()` call is violating this contract. The knowledge file must communicate this more visibly — and a test should verify it.

---

## 15. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | DB Architect: Add `crt_verification_logs` + `crt_id_card_issued` tables to DDL v2 | DB Architect |
| 2 | Technical Audit: Audit `StudentDocumentController` for DMS logic; document `IdCardGenerationService` method signatures | Technical Auditor |
| 3 | Add 0 → meaningful tests: HMAC hash correctness, serial counter concurrency, bulk threshold, duplicate detection, TC fee-clearance, revoke-not-delete | Testing Architect |
| 4 | Create migrations: 10 crt_* tables + `ALTER TABLE std_students ADD COLUMN tc_issued` + 2 new DDL v2 tables (after DB Architect adds them) | Developer |
| 5 | Extract `DmsService` from `StudentDocumentController` if fat-controller confirmed | Backend Developer |
| 6 | Generate FRD — must use DDL v1 + document the 2 missing tables as DDL v2 prerequisites; document `IdCardGenerationService` as undocumented service requiring Technical Audit | Business Analyst → "create an FRD for Certificate" |
| 7 | Confirm `maatwebsite/excel` in `composer.json`; verify rate limiting on `/verify/{hash}` and API endpoint | Developer |
| 8 | DB Architect: Decide `crt_tc_register.sl_no` type (SMALLINT max 32,767 vs INT) before TC migrations are created | DB Architect |
