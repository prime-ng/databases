# FrontOffice · CertificateRequest — Validation Report

> Artifact 4 of 5. QA gate/verdict for the CertificateRequest test artifact set.

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `fof_CertificateRequestTcList_Require.md` (combined TcList + Manual Steps) | ✅ |
| 2 | `fof_CertificateRequestGAPANALYSIS_Require.md` | ✅ |
| 3 | `fof_CertificateRequest_TestCas.php` | ✅ |
| 4 | `fof_CertificateRequestValidation_Report.md` (this file) | ✅ |
| 5 | `run-CertificateRequest-tests.php` (single cross-platform runner) | ✅ |

No separate MANUALTESTING file, no `.ps1`/`.sh` pair, no V1/V2 split — contract satisfied.

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix `fof_` matches DDL `CREATE TABLE fof_certificate_requests` | ✅ |
| Feature PascalCase `CertificateRequest` | ✅ |
| Class name = filename `fof_CertificateRequest_TestCas` | ✅ |
| snake_case test methods, semantic bands (01–09,10–19,20–29,30–39,40–49,50–59,60–69,70–79,90–99) | ✅ |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| `extends DuskTestCase`, namespace `Tests\Browser` | ✅ |
| `setUp()`/`tearDown()` with tenancy init + guarded `tenancy()->end()` | ✅ |
| Typed properties initialised (`?User $adminUser = null`, strings) | ✅ |
| `php -l` clean | ✅ **No syntax errors detected** |
| ONE test style (browser + DB/source/Gate; no `actingAs()->post()` mix) | ✅ |

## 4. Coverage Completeness

- **Total test methods: 37.**
- Coverage: Positive 100%, Negative 100%, Dependency 100%, State-machine 100% (8/8 BC-SM rows: 3 legal transitions + illegal-guard + download-guard + Cancelled-gap + update-jump), Tenancy 100% (P1), Security (XSS) present.
- Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see Method Index + Gap Analysis).
- DDL-derived coverage: duplicate-rejection for BOTH UNIQUE keys (request_number, cert_number) + multiple-NULL positive (G43); missing-value negative for every NOT-NULL-no-default col (G44); over-length + exact-length boundary for purpose(200) & cert_number(30) (G45); `test_cert_01` full DDL↔app alignment matrix vs LIVE schema; soft-delete col/trait independent (G46/#30); CRUD via verified `CertificateRequest` model (G47); auto fields (request_number/cert_number/issued_by/approved_by/created_by) tested as auto-behaviour, never form inputs (G48).
- No hollow methods (`addToAssertionCount`/empty) — verified; no `isCasted(`/`->isActive(` — verified. `->refresh()` used before default/computed reads. Counts use `assertGreaterThanOrEqual`/`find`. Permission negative uses `forgetCachedPermissions()` + non-super-admin + `Gate::denies`. All created records force-deleted in `finally`.

## 5. Known Source Defects Documented

| ID | Where documented | Proving test |
|----|------------------|--------------|
| DAT-FOF-001 (fee-gate) — REMEDIATED in current source | TcList §6, Gap §4 | test_cert_41 |
| BUG-FOF-001 (toggleStatus JsonResponse) — REMEDIATED (import present, line 10) | TcList §6 | source import verified |
| BUG-FOF-004 (cert_number slash format) — CONFIRMED | TcList §6 | test_cert_13 |
| DEV-FOF-CR-01 (permission key/verb mismatch vs requirement doc) | TcList §6, Gap §4 #10 | test_cert_50 |
| DEV-FOF-CR-02 (copies max:10 vs 1–5) | TcList §6, Gap §4 #8 | test_cert_35 |
| DEV-FOF-CR-03 (Cancelled unreachable) | TcList §6, Gap §4 #7 | test_cert_25 |
| DEV-FOF-CR-04 (update() status-jump bypasses issue guard) | TcList §6, Gap §4 #7 | test_cert_72 |
| DEV-FOF-CR-05 (`.issue` has no policy method) | Gap §4 #3 | test_cert_50 (gate) |
| DEV-FOF-CR-06 (no CertificateIssuanceService; logic inline) | Gap §4 #6 | test_cert_41 |
| DEV-FOF-CR-07 (UNIQUE enforced at DB only, no FormRequest `unique:`) | Gap §4 #12 | test_cert_70/71 |
| SEC-FOF-003 (no FormRequest) / PERF-FOF-001 / DAT-FOF-002(mitigated) | TcList §6 | noted |

## 6. Environment Prerequisites (execution-time)

1. **#19 — FrontOffice = `false` in `prime_testing/modules_statuses.json`** → all `/front-office/*` routes 404 until the module is ENABLED. This is the top blocker for browser-flow methods (they `markTestSkipped()` gracefully). NOT a code fix.
2. **#20** — `APP_ENV=testing` (Dusk CSRF bypass) — set by the runner env.
3. **#11** — `sys_media` may be absent in the test DB → media/PDF (`media_id`) paths guarded; cert issuance PDF storage not exercised.
4. **Cross-module** — `std_students` must have ≥1 active row (FK RESTRICT) and StudentFee (`fee_invoices`/`fee_student_assignments`) present for the fee-gate; absent → `markTestSkipped()`.
5. **#41** — validation 500-vs-422 tolerated; illegal-transition guards raise DomainException (HTTP 500) by design — assert tolerantly. Stale route cache → `php artisan route:clear` prereq. ChromeDriver aligned to installed Chrome.
6. The test file must be copied into `prime_testing/tests/Browser/Modules/FrontOffice/CertificateRequest/` (namespace `Tests\Browser`) for `artisan dusk` discovery. `prime_testing` itself is never modified by this generation run.

## 7. Deliberately skipped dimensions

- Responsive/mobile-viewport smoke and console-error (a11y) smoke: omitted (module disabled → cannot render reliably); the security dimension (stored XSS) IS included.
- Live `toggleStatus` 200 assertion: omitted as a route hit (module disabled); import verified at source instead.

## 8. Final Verdict

**PASS WITH NOTES.**

Notes: (a) All 5 artifacts present with correct names; `php -l` clean; 37 methods; coverage gates met. (b) Two audit-flagged P1 defects for this feature (DAT-FOF-001 fee-gate, BUG-FOF-001 toggleStatus import) are **verified REMEDIATED** in the current source — proving tests assert current behaviour and the divergence-from-audit is documented. (c) Seven live divergences (DEV-FOF-CR-01..07) plus BUG-FOF-004 confirmed and each carries a proving test. (d) Execution requires enabling FrontOffice in `modules_statuses.json` and a live tenant/ChromeDriver; browser-flow methods skip gracefully in a partial environment.
