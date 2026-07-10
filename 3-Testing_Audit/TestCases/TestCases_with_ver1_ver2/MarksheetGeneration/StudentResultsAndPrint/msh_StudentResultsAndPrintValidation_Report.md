# Validation Report — MarksheetGeneration / Student Results & Print

## 1. File Existence Summary
| # | Artifact | Present |
|---|----------|---------|
| 1 | `msh_StudentResultsAndPrintTcList_Require.md` | ✅ |
| 2 | `msh_StudentResultsAndPrintMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_StudentResultsAndPrintGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_StudentResultsAndPrintV1_TestCas.php` | ✅ |
| 5 | `msh_StudentResultsAndPrintV2_TestCas.php` | ✅ |
| 6 | `msh_StudentResultsAndPrintValidation_Report.md` | ✅ (this file) |
| 7 | `run-StudentResultsAndPrint-tests.ps1` | ✅ |
| 8 | `run-StudentResultsAndPrint-tests.sh` | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix `msh_` = DDL table prefix of primary table `msh_student_results` | ✅ (verified in `MarksheetGeneration_DDL_v1.sql`, table 17) |
| Feature PascalCase `StudentResultsAndPrint` | ✅ |
| Class name = filename (`msh_StudentResultsAndPrintV1_TestCas` / `...V2_TestCas`) | ✅ |
| `namespace Tests\Browser;` | ✅ |
| Methods snake_case, zero-padded, semantic bands | ✅ |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| `extends DuskTestCase` | ✅ |
| Tenant-side scaffolding (`initializeTenantContext`/`Domain`, guarded `tearDown`) | ✅ (DB scope = tenant_db, prefix `msh_`) |
| Typed properties initialised (`?User $adminUser = null` etc.) | ✅ |
| `php -l` V1 | ✅ No syntax errors |
| `php -l` V2 | ✅ No syntax errors |
| Private helper library (screenshots, auth, tenancy, permissions, JSON-from-browser, activity assert) | ✅ |

## 4. Coverage Completeness
| Metric | Value |
|--------|-------|
| V1 method count | 16 |
| V2 method count | 57 |
| V2 ≥ 2× V1 | ✅ (57 ≥ 32; ratio 3.56×) |
| Every TC-ID ↔ ≥1 method | ✅ |
| Every method ↔ TC/BC | ✅ (V2 Method Index in TcList) |
| Negative coverage | 100% |
| Positive coverage | 100% (12 Full + 3 Partial of 15) |
| State-machine coverage (BC-SM) | 100% (2 legal + 2 illegal transitions) |
| Semantic bands + Method Index | ✅ |
| Coverage-Score + Cross-Reference tables in Gap Analysis | ✅ |

## 5. Known Source Defects Documented
| ID | Where documented | Proving test |
|----|------------------|--------------|
| SEC-MSH-001 (P1) — create() uses `.view` gate | TcList §2 / Gap §4 (#3) | V2 test_51 |
| SEC-MSH-002 (P1) — store() uses `.update` gate | TcList §2 / Gap §4 (#3) | V2 test_52 |
| SEC-MSH-003 / D39-MSH (P1) — FormRequest authorize()=true | TcList §2 / Gap §4 | V2 test_53, test_09 |
| PERF-MSH-003 (P2) — unbounded Student/Subject/classSection get() | Gap §4 (#6) | Documented (source-confirmed) |
| PERF-MSH-004 (P3) — recompute hard-deletes soft-deletable rows | Gap §5 | Cross-feature — verify in MarksheetSchedule compute |
| BUG-MSH-101 (candidate, P3) — inconsistent entity ability naming (`.view` vs `.viewAny`; non-entity `tenant.msh-results.view`) | Gap §4 (#10) | Verify in permission seeder |

## 6. Constraints applied (from `05_Known_Test_Failure_Constraints.md`)
- **A1/A2/A3** — tenant-side style: private `initializeTenantContext()` resolving `Modules\Prime\Models\Domain`; guarded `tearDown` `tenancy()->end()`.
- **A4** — DB scope determined tenant-side (DDL `Database: tenant_db`, prefix `msh_`) → tenancy scaffolding emitted.
- **B5/B7** — `use App\Models\User;` + factory-free resolution of the existing tenant admin (matches golden sibling); `password` handling not needed.
- **C11/C12** — cleanup `forceDelete()` wrapped in `try/catch`; SoftDeletes verified before `withTrashed()`. **ComputationLog has NO SoftDeletes and `msh_computation_logs` has NO `deleted_at`** — asserted explicitly (V1 test_15, V2 test_07 & test_92 prove `withTrashed()`/`onlyTrashed()` throw); no soft-delete trait added in tests.
- **C13** — typed props initialised.
- **D14** — status codes checked via the in-browser authenticated `fetch` helper (`sendJsonRequestFromBrowser`), not Dusk `assertStatus`.
- **D18** — ENUM/`in:` values cross-checked case-sensitively (PROMOTED/DETAINED/COMPARTMENT/PLACED; DECLARED/WITHHELD).
- **E19 (environment prerequisite)** — **MarksheetGeneration must be enabled in `prime_testing/modules_statuses.json`** (currently most modules `false` → disabled module returns 404 on all routes). This is an environment prerequisite, not a test-code fix.
- **E20** — runners set `APP_ENV=testing` (CSRF bypass; else 419 on state-changing requests).

Data prerequisites (guarded by `markTestSkipped`, not failures): an active **unlocked** `msh_marksheet_schedules` row, a `sch_class_section_jnt` row, and `std_students` rows in the tenant DB. Locked-schedule transition tests temporarily flip `is_locked` on the dependency schedule and restore it in a `finally` block.

## 7. Enhanced dimensions
- Tenancy/IDOR: test_90 (out-of-range id 404). Security: SEC source-proofs (51-53), XSS round-trip (91). Skipped (documented): deep print/pdf content rendering, second-tenant leak, DOM-level XSS escape, a11y/responsive smoke (composite read-heavy screen).

## 8. Final Verdict
**PASS WITH NOTES.**
- All 8 artifacts present; naming/structure/coverage gates satisfied; V1/V2 lint clean; V2 = 3.56× V1.
- Notes: (1) execution requires MarksheetGeneration enabled + seeded tenant result data (else skips, not failures); (2) SEC-MSH-001/002/003 are **proven-in-source** (documenting current buggy behaviour) rather than behavioural 403 assertions, because the runner admin holds all permissions; (3) PERF-MSH-004 is cross-feature (compute flow) and only referenced here; (4) BUG-MSH-101 permission-naming inconsistency is a candidate to verify against the module's permission seeder.
