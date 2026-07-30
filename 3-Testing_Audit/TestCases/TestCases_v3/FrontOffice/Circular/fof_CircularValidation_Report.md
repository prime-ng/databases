# FrontOffice → Circular — Validation Report

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `fof_CircularTcList_Require.md` (combined: Feature Info + BC + TC list + Method Index + Manual Steps + Known Defects) | ✅ |
| 2 | `fof_CircularGAPANALYSIS_Require.md` | ✅ |
| 3 | `fof_Circular_TestCas.php` (one comprehensive suite) | ✅ |
| 4 | `fof_CircularValidation_Report.md` | ✅ |
| 5 | `run-Circular-tests.php` (single cross-platform runner — no `.ps1`/`.sh`) | ✅ |

No separate MANUALTESTING file; no V1/V2 split. Exactly 5 artifacts.

## 2. Naming Conventions

- Prefix `fof_` — **verified** against DDL `CREATE TABLE fof_circulars` (and `fof_circular_distributions`). Registry, DDL, and model `$table` agree.
- Feature `Circular` (PascalCase); class `fof_Circular_TestCas` = filename.
- Methods snake_case, semantic bands (01–09 schema, 10–19 biz, 20–29 FSM, 30–39 validation, 40–49 FK, 50–59 auth, 60–69 UI, 70–79 edge, 90–99 tenancy/security).

## 3. Structure Validation

- `extends Tests\DuskTestCase` (namespace `Tests\Browser\Modules\FrontOffice\Circular`) — mirrors the committed Complaint sibling (FOF has no committed Dusk base class).
- `setUp()` initialises tenant context (`Modules\Prime\Models\Domain` → `tenancy()->initialize`) and resolves the admin user + permissions BEFORE any `actingAs()`.
- `tearDown()` guards `tenancy()->end()`.
- Typed properties initialised (`?User $adminUser = null;` etc.).
- **`php -l`: PASS** (no syntax errors) on both `fof_Circular_TestCas.php` and `run-Circular-tests.php`.

## 4. Coverage Completeness

- **42 test methods.** Every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see Method Index).
- Negative **100%**, Positive **100%** (2 partial: cross-module recipient dep, `sys_media` media path), Dependency **100%** (1 guarded), Permissions **100%**, BC-SM every legal + key illegal transition.
- DDL-derived coverage: duplicate-rejection (G43, test_02), missing-value per NOT-NULL (G44, test_03), over-length + max-length (G45, test_05), full alignment matrix with soft-delete col/trait asserted independently (G46, test_01), CRUD via verified `Circular` model (G47), programmatically-managed fields (`circular_number`, `status`, `approved_by/at`, `distributed_by/at`, `created_by/updated_by`) tested as auto-behaviour, never as form inputs (G48).
- Constraint compliance: real assertions only (F33 — no `addToAssertionCount`/empty bodies), real Laravel-12 methods (F34), `->refresh()` before default reads (F35), permission negatives use a fresh non-super-admin + `forgetCachedPermissions()` and assert 403/302 (F37/#31), tolerant 500-vs-422 sets (F41), every created record cleaned up via `try/finally` + `hardDelete()` (F38), no hand-written URLs/selectors — all from `routes/web.php` and the real Blade (F40).

## 5. Known Source Defects Documented

| ID | Where proven | Note |
|----|-------------|------|
| DEV-FOF-C01 (=BUG-FOF-002, partially remediated) | test_circular_13 | distribute() inserts distribution rows but no real NTF dispatch (Queued, sent_at/ntf_log_id NULL). **Live source diverges from the audit's "status-flip stub" description — distribution IS now implemented; only the NTF delivery is missing.** |
| DEV-FOF-C02 | test_circular_33 | Validation `in:All` vs DDL ENUM lacking `All` |
| DEV-FOF-C03 | test_circular_26 | `recall()` service method has no route → Recalled unreachable |
| DEV-FOF-C04 | test_circular_70, _73 | soft destroy() & toggleStatus() write no activity log |
| DEV-FOF-C05 | TC-S51..55 | CircularPolicy dead (string gates used); no dedicated FormRequest (inline validate) → SEC-FOF-003 N/A here |

## 6. Environment Prerequisites (must hold for a green run)

1. **FrontOffice DISABLED** in `prime_testing/modules_statuses.json` (`"FrontOffice": false`) → all `/front-office/*` routes 404 until enabled (#19). **This is an env prerequisite, not a code fix — MUST be enabled to run the browser/HTTP methods.**
2. `APP_ENV=testing` (Dusk CSRF bypass, else 419) (#20).
3. `sys_media` table may be absent → force-delete/media paths guarded with `try/catch` + `markTestSkipped` (#11); a stale route cache is cleared by the runner (`route:clear`) (#41).
4. Cross-module dependencies (SchoolSetup `User`/`ClassSection`, StudentProfile `Guardian`/`StudentAcademicSession`) needed for recipient resolution → guarded with `markTestSkipped` (HARD RULE #9).
5. Tenant reachable via `DUSK_TENANT_URL` + a `Modules\Prime\Models\Domain` row; ChromeDriver aligned with Chrome.

## 7. Dimensions deliberately lightened

- No file-upload happy-path automation (attachment): requires `sys_media` present + a real fixture file; covered as manual (BC-VAL-07) and the SET-NULL/optional path is asserted (test_42).
- Responsive/a11y smoke omitted (page-based CRUD, low risk) — noted here per the "record skipped dimensions" rule.

## 8. Final Verdict

**PASS WITH NOTES.**
- All 5 artifacts present, correctly named, `php -l` clean; 42 methods; coverage gates met (Negative 100%, Positive ≥ 90%, Dependency ≥ 90%, every BC-SM transition).
- Notes: (a) FrontOffice must be enabled in `modules_statuses.json` before execution; (b) five DEV-FOF-C0x defects documented with proving tests — **BUG-FOF-002 is now only partially open** (distribution rows written; NTF dispatch still missing), which diverges from the Fact Pack §6 "status-flip stub" wording and should be reconciled by the maintainer; (c) 4 methods are dependency/media-guarded (Partial), not gaps.
