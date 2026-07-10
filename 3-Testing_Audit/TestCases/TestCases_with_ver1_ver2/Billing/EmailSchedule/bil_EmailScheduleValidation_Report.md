# Email Schedule — Validation Report

## 1. File Existence
| # | File | Status |
|---|------|--------|
| 1 | `bil_EmailScheduleTcList_Require.md` | ✅ |
| 2 | `bil_EmailScheduleMANUALTESTING_Require.md` | ✅ |
| 3 | `bil_EmailScheduleGAPANALYSIS_Require.md` | ✅ |
| 4 | `bil_EmailScheduleV1_TestCas.php` | ✅ |
| 5 | `bil_EmailScheduleV2_TestCas.php` | ✅ |
| 6 | `bil_EmailScheduleValidation_Report.md` | ✅ (this file) |
| 7 | `run-EmailSchedule-tests.ps1` | ✅ |
| 8 | `run-EmailSchedule-tests.sh` | ✅ |

## 2. Naming Conventions
- Prefix `bil_` = DDL/migration table prefix of `bil_tenant_email_schedules` ✔
- Feature PascalCase `EmailSchedule` ✔
- Class name = filename (`bil_EmailScheduleV1_TestCas` / `..V2..`) ✔
- Methods snake_case, zero-padded, semantic bands ✔

## 3. Structure Validation
- Namespace `Tests\Browser\Modules\Prime\Billing\EmailSchedule`; `extends BillingDuskTestCase` (central chain PrimeDuskTestCase → DuskTestCase), matching committed Billing siblings (`BillingCycle`, `Invoicing`) ✔
- Inherited `setUp/tearDown` from base (`resolveAdminUser`, `authenticateCentral`, `visitAuthenticated`, `centralUrl`, `ensurePageAccessible`, status-report writer) ✔
- Typed properties inherited from base and initialised there ✔
- `php -l` clean on V1 and V2 ✔ (verified)

## 4. Coverage Completeness
- **V1 = 16**, **V2 = 50** → V2 ≥ 2× V1 ✔
- Every TC-ID maps to ≥1 method; every method maps to a TC/BC (see TcList §3 index) ✔
- Coverage: Positive 100%, Negative 100%, Dependency 100%, State-machine 100% ✔

## 5. Constraints applied (`05_Known_Test_Failure_Constraints.md`)
- **A4 / prime-side:** central `prime_db` scope → NO tenant init emitted; mirrors siblings ✔
- **B5:** `App\Models\User` via base `resolveAdminUser` (super admin) ✔
- **B8/B9:** limited-user factory sets `emp_code` (≤20) + `status`; guarded with try/catch/skip ✔
- **C12:** SoftDeletes NOT added — model correctly lacks it; `withTrashed` not used ✔
- **C13:** all typed props inherited + initialised in base ✔
- **D14:** status codes asserted with HTTP test methods (`get/postJson/delete`), not Dusk `assertStatus` ✔
- **D15:** `actingAs($adminUser)` before every POST/DELETE ✔
- **D16:** browse closures receive `use (...)` captures ✔
- **D17:** schema types asserted via `Schema::hasColumns` (no exact type equality) ✔
- **E19 (prereq):** **Billing module must be enabled in `prime_testing/modules_statuses.json`** (currently mostly `false`) — else 404 on all routes. Environment prerequisite, not a code fix.
- **E20:** `APP_ENV=testing` (runners set it) for CSRF bypass on state-changing requests ✔

## 6. Known Source Defects Documented
| ID | Where documented | Proving test |
|----|------------------|--------------|
| DEV-EMS-001 / DATA-BIL-003 (P2) no FK on `invoice_id` | TcList, Gap §4/5 | V2-05, V2-42 |
| DEV-EMS-002 (P2) no FormRequest on send/schedule | TcList, Gap §4/5 | V2-32 |
| DEV-EMS-003 (P2) DDL gap — table absent from `Billing_DDL_v1.sql` | TcList, Gap §4/5, Manual §1 | V1-01, V2-06 |
| DEV-EMS-005 (P3) permission-key/matrix mismatch `prime.email-schedule.*` | Gap §4 (#3,#10) | V2-52, V2-54 |
| DEV-EMS-006 (P3) `destroy()` has no server-side pending re-check | Gap §4 (#7) | V2-20, V2-91 |
| JOB-BIL-001 (P2) job reliability — **REMEDIATED in current source** | TcList, Gap §5 | V1-14, V2-16/43/44 |
| DEV-EMS-004 (P3) audit class-name typo `BillTenatEmailSchedule` not in code | TcList | V1-01 |

## 7. Environment Prerequisites
1. Billing enabled in `modules_statuses.json`.
2. Prime tests run on `http://127.0.0.1:8000` (enforced by `PrimeDuskTestCase`).
3. `bil_tenant_email_schedules` migration applied (Prime module) — tests self-skip if the table is missing.
4. `MAIN_PROJECT_PATH` set for code-inspection tests (V2-43/44/52/53) — otherwise those self-skip.

## 8. Enhanced dimensions
- Security pack included (reflected + stored XSS, IDOR, verb guard). ✔
- Tenancy isolation pack: **N/A** — feature is central prime_db (no per-tenant table); intentionally omitted.
- Accessibility/responsive smoke: not included (light central list/show screen) — deliberate skip.

## 9. Final Verdict
**PASS WITH NOTES.**
Artifacts complete and lint-clean; coverage gates met; source read before assertion (routes, controller, job, model, mail, blade, migration, DDL). Notes: (a) tests are **not executed** here (`execute` not requested) — run via the runners once Billing is enabled; (b) six DEV candidates carried, two (DEV-EMS-005/006) flagged "verify in source"; (c) audit JOB-BIL-001 found remediated — source wins; (d) the `bil_tenant_email_schedules` DDL gap is real and must be reconciled in `Billing_DDL_v1.sql`.
