# D6 — Test Coverage & Quality Gates (Production-Readiness Audit)

**Date:** 2026-07-02 | **Auditor:** Testing Architect (parallel worker)
**App:** `/Users/bkwork/Herd/prime_ai` (Pest 4.x / Laravel 12) | **Browser repo:** `/Users/bkwork/Herd/prime_testing`
**Verdict: FAIL — the automated quality gate is non-functional.** The canonical test command cannot complete a run, test-DB isolation is broken (tests point at the LIVE `prime_db`), and the two highest-risk business flows (tenant creation, payment) have zero *executed* coverage.

---

## 1. Test DB Isolation + Actual Suite Run

### 1a. phpunit.xml DB config — NOT SQLite, and effectively NOT isolated

`phpunit.xml` (`/Users/bkwork/Herd/prime_ai/phpunit.xml`) does **not** use SQLite `:memory:`. It sets dedicated MySQL test DBs via `<env>`:
- `DB_DATABASE=prime_test`, `GLOBAL_DB_DATABASE=global_master_test` (host 127.0.0.1:3306, user `admin`), tenant DBs "created dynamically per test run".

**However, these overrides are dead config.** A stale cached config exists at `bootstrap/cache/config.php` (dated 2026-05-21) containing `'database' => 'prime_db'` and `'database' => 'global_master'` — the **live** database names. Laravel ignores `<env>` vars from phpunit.xml when a config cache is present. Verified empirically: every Feature test attempted to connect to `Database: prime_db` (not `prime_test`):

```
SQLSTATE[HY000] [2002] Connection refused (Connection: mysql, Host: 127.0.0.1,
Port: 3306, Database: prime_db, SQL: select * from `sys_users` where `email` =
superadmin1@primeai.com ...)
```

Tests also authenticate as a real seeded user (`superadmin1@primeai.com`), i.e. they *depend on live-DB state*. The only reason no live data was touched today is that **no MySQL server is running (or even installed) on this machine** — connection refused on 3306; no Herd Pro services, no brew mysql, no docker. If MySQL were up, `php artisan test` would execute against the live `prime_db`. → **D6-P1-1**

### 1b. Actual test-run results (executed 2026-07-02)

| Run | Command | Result |
|---|---|---|
| Full suite | `php artisan test` | **ABORTED** — 10 passed (Backup unit tests), then silent death, exit 2, **no summary, no error printed**. Never reaches Feature/Modules suites. |
| Feature suite | `pest --testsuite=Feature` | **0 passed / 26 failed** (100% fail) — all `QueryException: SQLSTATE[HY000] [2002] Connection refused` against `prime_db`. Duration 174.6s. |
| Modules-Unit suite | `pest --testsuite=Modules-Unit` | **Silent crash** — exit 2, zero bytes of output, zero tests executed. |
| All module tests by path | `pest Modules` | **FATAL, 0 tests** — `Error: Class "Tests\TenantTestCase" not found` at `Modules/Library/tests/Feature/LibDigitalResourceGapFixesTest.php:12`. `Tests\TenantTestCase` does not exist anywhere in the repo (only `TestCase`, `DuskTestCase`). |
| Unit dir | `pest tests/Unit` | **ABORTED after 10 passed** — crasher isolated to `tests/Unit/Central/ControllerAuthTest.php`, which terminates the Pest process silently (alphabetically right after the Backup tests → explains the full-suite abort point). |

Individually-run files (bypassing the crashers) DO work without a DB, proving the harness itself is fine:

| File | Result |
|---|---|
| tests/Unit/Central/ModelStructureTest.php | 148 passed (2 deprecated) |
| tests/Unit/Central/PolicyTest.php | 86 passed, **1 failed**, 2 risky |
| tests/Unit/Central/ViewIntegrityTest.php | 15 passed, **1 failed** |
| tests/Unit/Central/PermissionConfigTest.php | 30 passed, **1 failed**, 1 risky |
| tests/Unit/Backup*(2 files) | 10 passed |
| Modules/Prime/tests/Unit/SettingModelTest.php | 16 passed |
| Modules/Accounting/tests/Unit/PolicyTest.php | 51 passed |
| tests/Unit/Hpc + SmartTimetable + StudentProfile | multiple **FAIL** classes (DB-dependent), run again aborted silently (exit 2, no summary) |

**Aggregate of everything actually executed today: ~356 passed / 29+ failed / 2 silent process-killers / 1 fatal collection error. No configuration exists in which the suite completes end-to-end.**

---

## 2. Per-Module Test Counts (45 modules)

Sources: **M** = `prime_ai/Modules/{X}/tests` (`*Test.php`); **A** = `prime_ai/tests/{Unit,Feature}` per-module; **B1** = `prime_ai/tests/Browser/Modules` (Dusk, `*Test.php`, 423 files total — NOT in phpunit.xml); **B2** = `prime_testing/tests/Browser/Modules` (all `.php`, 319 files, 311 of which are `*_TestCas.php` — not PHPUnit-discoverable).

| Module | M | A | B1 (Dusk) | B2 (prime_testing) | PHPUnit-runnable? |
|---|---|---|---|---|---|
| Accounting | 19 | 0 | 1 | 3 | YES |
| Admission Mgmt. | 0 | 0 | 13 | 0 | **NO** |
| BehaviouralAssessment | 0 | 0 | 8 | 0 | **NO** |
| Billing | 1 | 0 | 1 | 1 | YES |
| Cafeteria | 1 | 0 | 12 | 0 | yes (not registered) |
| Certificate | 0 | 0 | 10 | 0 | **NO** |
| CommonChat | 0 | 0 | 8 | 0 | **NO** |
| Complaint | 0 | 0 | 6 | 15 | **NO** |
| Dashboard | 0 | 0 | 0 | 0 | **NO — ZERO ANY** |
| Documentation | 1 | 0 | 0 | 0 | yes (not registered) |
| EventEngine | 0 | 0 | 0 | 0 | **NO — ZERO ANY** |
| Feedback | 0 | 0 | 9 | 0 | **NO** |
| FrontOffice | 1 | 0 | 8 | 0 | yes (not registered) |
| GlobalMaster | 4 | 0 | 9 | 0 | YES |
| Hostel | 0 | 0 | 0* | 0 | **NO — ZERO ANY** |
| Hpc | 0 | 7 | 11 | 8 | YES (app tests) |
| HrStaff | 0 | 0 | 8 | 29 (Employee) | **NO** |
| Inventory | 0 | 0 | 15 | 0 | **NO** |
| Library | 1** | 0 | 14 | 66 | broken** |
| LmsExam | 0 | 0 | 7 | 24 | **NO** |
| LmsHomework | 1 | 0 | 5 | 1 | YES |
| LmsQuests | 0 | 0 | 4 | 0 | **NO** |
| LmsQuiz | 0 | 0 | 6 | 0 | **NO** |
| MarksheetGeneration | 10 | 0 | 2 | 0 | YES |
| Notification | 0 | 0 | 0 | 0 | **NO — ZERO ANY** |
| ParentPortal | 0 | 0 | 17 | 0 | **NO** |
| Payment | 11 | 0 | 0 | 0 | yes (**not registered**) |
| Prime | 9 | 12 (Central/Backup) | 27 | 9 | YES |
| PTM | 0 | 0 | 8 | 8 | **NO** |
| QuestionBank | 0 | 0 | 8 | 16 | **NO** |
| Recommendation | 0 | 0 | 10 | 1 | **NO** |
| Scheduler | 1 | 0 | 0 | 0 | yes (not registered) |
| SchoolSetup | 0 | 0 | 37 (+9 Class&SubjectMgmt) | 21 (+20 Class&SubjectMgmt) | **NO** |
| SmartTimetable | 3 | 7 | 15 | 0 | YES |
| StandardTimetable | 0 | 0 | 2 | 0 | **NO** |
| StudentFee | 26 | 0 | 14 | 1 | YES |
| StudentPortal | 9 | 0 | 25 | 0 | YES |
| StudentProfile | 0 | 1 | 12 | 5 | YES (1 app test) |
| Syllabus | 0 | 0 | 9 | 35 | **NO** |
| SyllabusBooks | 0 | 0 | 6 | 6 | **NO** |
| SystemConfig | 1 | 0 | 0 | 0 (Dropdown empty) | YES |
| Template | 2 | 0 | 4 | 0 | yes (not registered) |
| TimetableFoundation | 6 | 0 | 30 | 1 | YES |
| Transport | 0 | 0 | 17 | 40 | **NO** |
| Vendor | 0 | 0 | 7 | 7 | **NO** |

\* Hostel: only indirect mention in `StudentPortal/StudentPortalTransportHostelTest.php` (Dusk). ** Library's single module test is the file that fatally crashes every run (missing `Tests\TenantTestCase`).

### Today's exact zero-coverage lists

**Zero PHPUnit-runnable coverage (25 modules):** Admission, BehaviouralAssessment, Certificate, CommonChat, Complaint, Dashboard, EventEngine, Feedback, Hostel, HrStaff, Inventory, LmsExam, LmsQuests, LmsQuiz, Notification, ParentPortal, PTM, QuestionBank, Recommendation, SchoolSetup, StandardTimetable, Syllabus, SyllabusBooks, Transport, Vendor. (Prior report's "~20 modules" is confirmed and slightly understated.)

**Zero coverage of ANY kind, incl. browser (4 modules):** **Dashboard, EventEngine, Hostel, Notification.**

Also: phpunit.xml registers 20 module test dirs but **omits 7 modules that actually have tests** (Payment, Cafeteria, Documentation, FrontOffice, Library, Scheduler, Template) while registering several whose test dirs are empty (Hpc, LmsExam, LmsQuiz, Notification, QuestionBank, SchoolSetup, StudentProfile, Syllabus, Transport module dirs).

---

## 3. Critical-Flow Coverage

| Flow | Status | Evidence |
|---|---|---|
| Login / auth | PARTIAL (browser-only) | `prime_ai/tests/Browser/LoginTest.php`, `prime_testing/tests/Browser/LoginTest.php`, `prime_ai/tests/Browser/Modules/StudentPortal/StudentPortalLoginTest.php`. **No runnable HTTP feature test for login.** Structural checks only in `tests/Unit/Central/ControllerAuthTest.php` (the file that crashes the suite). |
| **Tenant creation / onboarding** | **ABSENT → P1** | No test file anywhere in prime_ai or prime_testing exercises tenant creation/onboarding. |
| **Fee payment flow** | **EXISTS BUT NEVER EXECUTED → P1** | `Modules/Payment/tests/` (9 unit: GatewayManagerTest, OfflineGatewayTest, PaymentEventsTest, DTO/model tests; 2 feature: `PaymentControllerTest.php`, `PaymentGatewayControllerTest.php`) + `Modules/StudentFee/tests/Unit/FeeTransactionModelTest.php`, `FeePaymentGatewayLogModelTest.php`. **Payment module is NOT registered in phpunit.xml**, so its tests never run in any suite; and no suite completes anyway. |
| Exam marks entry | Effectively absent | Only `prime_testing/.../LmsExam/AssessmentMarks/*_TestCas.php` (non-discoverable naming, manual browser tests). No app-level test. |
| Marksheet generation | PRESENT (unverified execution) | `Modules/MarksheetGeneration/tests/` — 10 files incl. `MarksheetDataProviderTest.php`, `StudentResultPrintTest.php`, Compute/ScoreReaders suites; registered in phpunit.xml. Could not be verified green (suite crash + DB down). |
| Student promotion | Browser-only | `prime_ai/tests/Browser/Modules/Admission/PromotionBatch/PromotionBatchCrudTest.php` (Dusk). |
| Admission | Browser-only | 13 Dusk files under `prime_ai/tests/Browser/Modules/Admission/` (AdmissionCycle, TransferCertificate, BehaviorIncident, ...). |

---

## 4. Browser Suite Runnability (prime_testing)

- `tests/DuskTestCase.php` is well-built: runs Chrome **headless by default** (`--headless=new` unless disabled), self-starts chromedriver on port 9515, resolves Chrome binary, writes per-module screenshot/console/source artifacts.
- **But the repo is not turnkey-runnable:** no `.env` (missing entirely), no `phpunit.xml`/`phpunit.dusk.xml`, README is stock Laravel boilerplate with zero run instructions. Base URL comes from `DUSK_TENANT_URL`/`APP_URL` env — requires a live prime_ai server (Herd) + running MySQL + seeded data.
- **311 of 319 files use the suffix `*_TestCas.php`** — not discoverable by PHPUnit/Dusk (`*Test.php` required). Only 8 files (Employee module) are conventionally named. These are effectively manually-invoked scripts, not an automated suite.
- Not launched (needs live server + DB, per audit constraints). Requirements to run: create `.env` (APP_URL, DB creds), start MySQL + prime_ai under Herd, install Chrome/chromedriver, rename or map `_TestCas.php` files, add phpunit.dusk.xml.

## 5. Static Analysis

- **No PHPStan/Larastan anywhere**: no `phpstan.neon`/`phpstan.dist.neon` in prime_ai, `larastan/phpstan` absent from `composer.json` (dev deps are pest + dusk only), no `vendor/bin/phpstan`. Only Laravel Pint (code style) is installed. Could not run → **P2 gap**.

## 6. CI Gate

- Confirmed: **no CI** (`.github/workflows/` does not exist in prime_ai).

---

## Findings Register

| ID | Sev | Finding |
|---|---|---|
| **D6-P0-1** | **P0** | The canonical quality gate `php artisan test` **cannot complete**: it dies silently (exit 2, no summary) after 10 tests. Two independent fatal causes verified: (a) `tests/Unit/Central/ControllerAuthTest.php` silently terminates the Pest process; (b) `Modules/Library/tests/Feature/LibDigitalResourceGapFixesTest.php` extends non-existent `Tests\TenantTestCase` → fatal "Class not found" aborts any run that collects Modules paths. Zero of the module suites ever execute. |
| **D6-P1-1** | **P1** | Test-DB isolation is broken: stale `bootstrap/cache/config.php` (2026-05-21) pins tests to **live `prime_db` / `global_master`**, silently overriding phpunit.xml's `prime_test`/`global_master_test`. Feature tests were observed querying `prime_db` and depend on the live user `superadmin1@primeai.com`. Only the absence of a running MySQL server prevented tests from executing against live data. Fix: delete config cache, add `about --only=environment` guard / `RefreshDatabase` safety, or a `DatabaseNameGuard` that aborts if DB name lacks `_test`. |
| **D6-P1-2** | **P1** | Feature suite result: **0 passed / 26 failed (100%)** — every HTTP-layer test errors (`SQLSTATE[HY000] 2002 Connection refused`; no MySQL server exists on this machine). Effective executed feature coverage of the application today is **zero**. |
| **D6-P1-3** | **P1** | **Tenant creation / onboarding has no test of any kind** in either repo (money + tenancy criterion). |
| **D6-P1-4** | **P1** | **Payment (money) flow has zero executed coverage**: 11 unit + 2 feature tests exist in `Modules/Payment/tests/` but the module is not registered in phpunit.xml testsuites, so they are never run — and no suite completes regardless. |
| D6-P2-1 | P2 | 25 of 45 modules have zero PHPUnit-runnable tests; 4 modules (**Dashboard, EventEngine, Hostel, Notification**) have zero tests of any kind incl. browser. |
| D6-P2-2 | P2 | No static analysis: PHPStan/Larastan not installed or configured (only Pint). |
| D6-P2-3 | P2 | Browser suite (prime_testing, 319 files) is not an automated suite: no `.env`, no phpunit config, stock README, and 311/319 files named `*_TestCas.php` (undiscoverable); requires live server + MySQL + Chrome to run at all. |
| D6-P2-4 | P2 | phpunit.xml testsuite registration is stale: omits 7 modules that have tests (incl. Payment), includes empty dirs; `prime_ai/tests/Browser` (423 Dusk files) and `tests/Prime` are outside every suite. |
| D6-P2-5 | P2 | No CI pipeline exists — no automated gate runs on any push/PR (remediation spec below). |
| D6-P3-1 | P3 | Test hygiene: 3 failing DB-independent central unit tests (Central PolicyTest, ViewIntegrityTest, PermissionConfigTest — 1 each), plus risky/deprecated warnings; scratch files (`fix_test_classes.php`, `temp_write_test.txt`, `change_dashboard.html`) inside test trees. |
| D6-P3-2 | P3 | Exam marks entry, student promotion, admission, and login are covered only by browser tests that cannot run headlessly in CI today. |

---

## Remediation — Minimum Quality-Gate Pipeline (D6-P2-5)

Order of operations (gate is meaningless until P0/P1 are fixed):

1. **Unblock the suite (P0):** create `Tests\TenantTestCase` (or re-parent the Library test), fix/quarantine `tests/Unit/Central/ControllerAuthTest.php`, and confirm `php artisan test` prints a final summary locally.
2. **Restore isolation (P1):** `php artisan config:clear` and gitignore-verify `bootstrap/cache/config.php`; add a bootstrap guard that hard-fails any test run where `DB_DATABASE` does not end in `_test`; remove dependence on live-seeded `superadmin1@primeai.com` (use factories/seeders in `prime_test`).
3. **Minimum CI at `prime_ai/.github/workflows/tests.yml`** (per AI_Brain testing strategy):
   - Trigger: push to `main`/`develop`/feature branches + all PRs to `main`.
   - Job 1 — *Lint*: `vendor/bin/pint --test` (already installed).
   - Job 2 — *Static analysis*: `composer require --dev larastan/larastan`, `phpstan.neon` at level 1 (raise gradually), `vendor/bin/phpstan analyse`.
   - Job 3 — *Tests*: MySQL 8 service; create `prime_test`, `global_master_test`, one tenant test DB; migrate + seed global masters; run `php artisan test` (add `--coverage --min=60` once green; parallel later).
   - Merge blocked unless all three jobs pass; artifacts on failure.
4. **Register all module test dirs** in phpunit.xml (or glob them) so Payment and the other 6 orphaned modules execute; add a smoke `--group=security,regression` fast lane per AI_Brain strategy.
5. **Coverage debt:** author-first targets = tenant onboarding feature test, Payment gateway feature run, then the 25 zero-coverage modules starting with money/tenancy-adjacent ones (Billing depth, SchoolSetup, ParentPortal, Hostel).

---
*Run evidence retained in session scratchpad (`full_run.txt`, `all_modules.txt`). All test executions performed with MySQL down — zero risk to live data was confirmed before each run.*
