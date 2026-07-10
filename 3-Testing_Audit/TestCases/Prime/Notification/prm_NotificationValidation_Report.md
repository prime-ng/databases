# Prime (PRM) — Notification — Validation Report

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `prm_NotificationTcList_Require.md` | ✅ |
| 2 | `prm_NotificationMANUALTESTING_Require.md` | ✅ |
| 3 | `prm_NotificationGAPANALYSIS_Require.md` | ✅ |
| 4 | `prm_Notification_TestCas.php` | ✅ (single file — no V1/V2) |
| 5 | `prm_NotificationValidation_Report.md` | ✅ (this file) |
| 6 | `run-Notification-tests.ps1` | ✅ |
| 7 | `run-Notification-tests.sh` | ✅ |

## 2. Naming Conventions

- Prefix `prm_` — matches the Prime module registry `PREFIX`. The morph sink is the framework `notifications` table (no `ntf_*` domain table involved); `prm_` correctly denotes the central Prime feature. ✅
- Feature PascalCase `Notification`. ✅
- Class name = filename `prm_Notification_TestCas`. ✅
- Methods snake_case, zero-padded, banded (`test_notification_NN_*`). ✅

## 3. Structure Validation

- Namespace `Tests\Browser\Modules\Prime\Notification`. ✅
- `use Tests\Browser\Modules\Prime\PrimeDuskTestCase;` + `extends PrimeDuskTestCase`. ✅ (central base — constraint #21; host asserted 127.0.0.1)
- `use App\Models\User;` (runner model — constraint #5). ✅
- Central auth/helpers implemented **locally** (mirrored from `prm_BillingDuskTestCase_TestCas`): `centralUrl`, `authenticateCentral`, `visitAuthenticated`, `ensurePageAccessible`, `sendJsonRequestFromBrowser`, screenshot/report helpers. ✅
- **No tenant scaffolding** (no `initializeTenantContext`, no `tenancy()->end()`) — correct for central feature (constraint #4, #22). ✅
- Typed properties initialised (`?User $adminUser = null`, strings `= ''`). ✅
- `php -l`: **No syntax errors detected.** ✅

## 4. Coverage Completeness

- **Total: 33 test methods.**
- Positive 100% · Negative 100% · Permissions 100% · Security/Config 100% · Integration/Ref 100%.
- Every TC-ID ↔ ≥ 1 method; every method ↔ a TC/BC (see Gap Analysis §1). No V1/V2 ratio.
- Numbering bands: 01–05 config; 10–13 biz; 30–31 negative/auth; 40–41 integration; 50–54 permissions; 60–63 UI; 70–73 actions/API; 80–82 env-guard; 90–93 security.

## 5. Known Source Defects Documented

| ID | Where documented | Proving test |
|----|------------------|--------------|
| SEC-PRM-002 (**REFUTED**) | TcList §4, Gap §4/§5, Manual TC-S80 | `test_..._80`, `_82` |
| DEV-PRM-NTF-001 | TcList §4, Gap §4/§5, Manual TC-A52 | `test_..._52`, `_05` |
| DEV-PRM-NTF-002 | TcList §4, Gap §4/§5, Manual §2 | `test_..._13` |

## 6. Constraints Applied (from `05_Known_Test_Failure_Constraints.md`)

- #21 Prime/central on `http://127.0.0.1:8000`; extend the module central base (via `PrimeDuskTestCase`); no `DUSK_TENANT_URL`. ✅
- #22 Filename↔classname mismatch resolved via preloader `class_alias`; `extends PrimeDuskTestCase` (short alias) verbatim like the sibling. ✅
- #4 Central `prm_*` feature → no tenant init. ✅
- #5 `App\Models\User` (runner). ✅
- #14 Dusk has no `assertStatus`/`.post` — JSON endpoint status/body obtained via in-page authenticated XHR (`sendJsonRequestFromBrowser`), not Dusk verbs. ✅
- #17 Schema type assertions use `str_contains` (UUID id may report `char(36)`), never `assertEquals`. ✅

## 7. Environment Prerequisites

- App served on `http://127.0.0.1:8000`; `APP_ENV=testing` (CSRF bypass + registers the env-guarded `test-notification` route; the runner sets it).
- **Prime module enabled** in `prime_testing/modules_statuses.json` (constraint #19) — else routes 404.
- A super-admin user (`is_super_admin=1`, generated `super_admin_flag`) must exist so gated routes (`viewAny`/`create`, and the undefined `delete`) pass via `Gate::before`; otherwise permission-gated browser flows (60–73) would 403.

## 8. Final Verdict

**PASS WITH NOTES.**

Notes:
1. **SEC-PRM-002 could not be reproduced** — the source already environment-guards the debug route at registration. The suite proves the mitigation exists (`test_..._80`) and records only the residual defense-in-depth gap (`test_..._82`). The brief's P1 severity does not hold against current source.
2. Two genuine, source-traced defects surfaced: **DEV-PRM-NTF-001** (undefined `prime.notification.delete` ability) and **DEV-PRM-NTF-002** (TestNotification ignores its ctor arg). Both have proving tests.
3. Browser action/API tests (60–73) require the live 127.0.0.1 server + a super-admin; config-truth, permission-source, route, schema, and env-guard tests (01–05, 40–41, 50–54, 80–92) are deterministic in-process assertions independent of the browser.
4. Nothing was appended to `05_Known_Test_Failure_Constraints.md` — no new *general* codebase/env constraint was discovered (findings are feature-specific defects, recorded here).
