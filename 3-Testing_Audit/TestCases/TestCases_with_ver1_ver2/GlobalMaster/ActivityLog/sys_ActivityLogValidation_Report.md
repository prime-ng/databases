# Activity Log (Central Audit Viewer) — Validation Report

**Feature:** GlobalMaster / ActivityLog · **Prefix:** `sys_` · **Table:** `sys_activity_logs`
**Scope:** CENTRAL (prime_db) · **Style:** central browser Dusk (`extends PrimeDuskTestCase`) · **Screen type:** read-only audit viewer.

---

## 1. File Existence Summary

| # | Artifact | Status |
|---|----------|--------|
| 1 | sys_ActivityLogTcList_Require.md | ✅ |
| 2 | sys_ActivityLogMANUALTESTING_Require.md | ✅ |
| 3 | sys_ActivityLogGAPANALYSIS_Require.md | ✅ |
| 4 | sys_ActivityLogV1_TestCas.php | ✅ |
| 5 | sys_ActivityLogV2_TestCas.php | ✅ |
| 6 | sys_ActivityLogValidation_Report.md | ✅ (this file) |
| 7 | run-ActivityLog-tests.ps1 | ✅ |
| 8 | run-ActivityLog-tests.sh | ✅ |

## 2. Naming Conventions
- Prefix `sys_` = DDL prefix of primary table `sys_activity_logs` (verified in `_prime_db_v4.sql`, `CREATE TABLE sys_activity_logs`). ✅
- Feature PascalCase `ActivityLog`. ✅
- Class name = filename (`sys_ActivityLogV1_TestCas`, `sys_ActivityLogV2_TestCas`). ✅
- snake_case, zero-padded, banded methods `test_activitylog_NN_*`. ✅

## 3. Structure Validation
- `extends PrimeDuskTestCase` (central base, physical `prm_PrimeDuskTestCase_TestCas`; resolves via `tests/Browser/Modules/preload.php` alias). ✅
- Namespace `Tests\Browser\Modules\Prime\GlobalMaster`. ✅
- `setUp()`/`tearDown()` present; tenancy teardown guarded (`function_exists('tenancy') && tenancy()->initialized`). ✅
- Typed properties initialised (`?User $adminUser = null;` etc. — constraint C13). ✅
- Central helpers self-contained (centralUrl/authenticateCentral/visitAuthenticated/resolveAdminUser, mirroring Billing base) — no hard dependency on the Billing class. ✅
- `php -l`: **clean on both V1 and V2.** ✅

## 4. Coverage Completeness
- **V1 = 16 methods, V2 = 48 methods → 3.0× (≥ 2× gate satisfied).** ✅
- Every TC-ID maps to ≥1 method; every method maps back to a TC/BC (see TcList §4 Method Index + Gap Analysis §1). ✅
- Negative 100% · Positive 100% · Dependency 100% · Edge 100%. ✅
- Tenancy isolation: **N/A (central feature)** — deliberately skipped; instead the model's tenancy-aware `user()` switch is covered (test_05/test_90). Recorded here per HARD-RULE requirement to document skips.
- No CRUD create/edit/delete matrix — **deliberately omitted** (read-only audit viewer; controller store/edit/update/destroy are stubs). Recorded.

## 5. Known Source Defects Documented
| ID | Sev | Where proven |
|----|-----|--------------|
| BUG-GLB-ALOG-01 | High (SEC) — `search()` unguarded | V1 test_15, V2 test_53; Gap §4 #3 |
| BUG-GLB-ALOG-02 | Medium — card `view` vs index `viewAny` mismatch | V1 test_16, V2 test_55; Gap §4 #10 |
| BUG-GLB-ALOG-03 / RISK-GLB-008 | Medium (ARCH) — divergent sinks (`sys_central_activity_logs` vs `sys_activity_logs`) | V1 test_05, V2 test_42/43; Gap §4 #12 |
| MIG-GLB-001 | P2 — dead `activity_logs` migration | V2 test_44; Gap §4 #13 |
| BUG-GLB-005 | Not reproduced (central `search()` live) | V1 test_04/13, V2 test_09; Gap §4 #2 |

### Premise corrections (source wins — constraint 13)
- Task "index ungated (SEC)" → **corrected**: index IS gated by `prime.activity-log.viewAny` (only the GlobalMaster-specific gate line is commented). The real SEC hole is the unguarded `search()`.
- Task "search dead → 500" → **corrected**: Prime `search()` returns JSON. The GlobalMaster *module* controller lacks `search()`/route, a separate documented gap.

## 6. Constraints obeyed (05_Known_Test_Failure_Constraints)
- A4/E21: central/prime-side → **no tenant init**; extends central base, host `127.0.0.1:8000`. ✅
- B5: `App\Models\User` (matches Billing central sibling & base). ✅
- C12: model has **no SoftDeletes** → tests never call withTrashed/onlyTrashed/forceDelete; test_02/test_44 assert absence. ✅
- C13: typed props initialised. ✅
- D14: status codes via Laravel HTTP test methods (`$this->get(...)`), never `Browser::assertStatus`. ✅
- D17: MySQL8 type variance via `assertStringContainsString('int', ...)` / accepted-type arrays. ✅
- E19: **module-enabled prerequisite** — GlobalMaster + Prime are `false` in `modules_statuses.json`; all routes 404 until enabled. Browser/HTTP tests self-skip on 404 so partial env stays green. **This is an environment prerequisite, not a test-code fix.**
- E20: `APP_ENV=testing` (runners set it). ✅
- E22: preload alias for the filename↔classname-mismatched base class. ✅

## 7. Environment prerequisites (for the runner)
1. Enable `GlobalMaster` and `Prime` in `prime_testing/modules_statuses.json`.
2. Serve the app on `http://127.0.0.1:8000`.
3. `APP_ENV=testing`; ChromeDriver present (`--sync-db` runs `dusk:chrome-driver --detect`).
4. Central `sys_users` row available (super-admin) for FK-satisfying seed tests; otherwise those tests self-skip.
5. Place the test files under `tests/Browser/Modules/Prime/GlobalMaster/ActivityLog/` in `prime_testing` before running.

## 8. Final Verdict

**PASS WITH NOTES.**
All 8 artifacts present; naming/structure/coverage gates met; `php -l` clean; V2 = 3.0× V1. Notes: (a) browser/DB-seed tests are environment-gated and self-skip when the module is disabled or no central user exists — the schema/model/route/source-content backbone runs unconditionally; (b) two task premises (ungated index, dead search route) were corrected against verified source and re-encoded as the genuinely present defects (unguarded `search()`, divergent audit sinks).
