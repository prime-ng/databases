# Scheduling & Lifecycle — Validation Report

## 1. File Existence Summary
| # | File | Present |
|---|------|---------|
| 1 | `msh_SchedulingAndLifecycleTcList_Require.md` | ✅ |
| 2 | `msh_SchedulingAndLifecycleMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_SchedulingAndLifecycleGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_SchedulingAndLifecycleV1_TestCas.php` | ✅ |
| 5 | `msh_SchedulingAndLifecycleV2_TestCas.php` | ✅ |
| 6 | `msh_SchedulingAndLifecycleValidation_Report.md` | ✅ |
| 7 | `run-SchedulingAndLifecycle-tests.ps1` | ✅ |
| 8 | `run-SchedulingAndLifecycle-tests.sh` | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix `msh_` = DDL prefix of primary table `msh_marksheet_schedules` | ✅ verified in DDL + migration |
| Feature PascalCase `SchedulingAndLifecycle` | ✅ |
| Class name = filename (`msh_SchedulingAndLifecycleV1_TestCas` / `…V2_TestCas`) | ✅ |
| `namespace Tests\Browser;` | ✅ |
| snake_case zero-padded methods `test_scheduling_NN_*` | ✅ |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| `extends DuskTestCase` | ✅ |
| `setUp()` / `tearDown()` with tenancy init/guarded end | ✅ (`initializeTenantContext`, `tenancy()->end()` guarded) |
| Typed properties initialised (`?User $adminUser = null`, `string = ''`, arrays `[]`) | ✅ |
| `php -l` clean | ✅ V1 and V2 both report "No syntax errors detected" |
| Private helper library (screenshots, JSON-from-browser, auth, tenancy, permissions, seeds) | ✅ mirrors golden reference |

## 4. Coverage Completeness
| Metric | Value |
|--------|-------|
| V1 method count | 18 |
| V2 method count | 56 |
| V2 ≥ 2×V1 | ✅ 56 ≥ 36 |
| Every TC-ID ↔ ≥1 method | ✅ (see Gap Analysis §1) |
| Every method ↔ TC/BC | ✅ (V2 Method Index in TcList §4) |
| Negative coverage | 100% |
| Positive coverage | 100% |
| Dependency coverage | 100% |
| State-machine: every legal + key illegal transition | ✅ (V2 21-28, V1 09-15) |
| Tenancy (P1 module) | ✅ present (V2 90; guarded on single-tenant envs) |
| Semantic numbering bands (esp. 20-29 state machine) | ✅ |
| Source tags on every BC/TC | ✅ |
| Coverage-Score + Cross-Reference tables in Gap Analysis | ✅ |

## 5. Known Source Defects Documented
| ID | Where documented | Proving test |
|----|------------------|--------------|
| BR-MSH-026 (P1) FSM gap in compute() | TcList §3, Gap §5 | V2 test_29 |
| BR-MSH-027 (P1) no concurrency guard | TcList §3 | V2 test_71 |
| PERF-MSH-001 (P1) precheck N+1 | TcList §3 | V2 test_74 (soft) |
| SEC-MSH-003 (P1) FormRequests authorize()=true | TcList §1 BC-AUTH-06 | V1 test_01 / V2 test_52 |
| D39-MSH (P1) permissions unseeded | This report §7 (env prereq) | V2 test_54 |
| BR-MSH-050 (P2) weightage sum not validated | TcList §3 | V2 test_72 |
| PERF-MSH-002 (P2) hasTable ×3 in loop | TcList §3 | V2 test_73 |
| DEP-MSH-001 (P2) cross-module precheck import | TcList §1 BC-INT-01 | V1 test_16 / V2 test_44 |
| DOC-MSH-002 (P3) sys_dropdown_table vs sys_dropdowns | TcList §1 BC-DB-07 | V1 test_01 / V2 test_02 |
| PERF-MSH-004 (P3) recompute hard-deletes | TcList §3 | V2 test_45 |
| **BUG-MSH-101 (NEW P1)** ScheduleClass missing SoftDeletes | TcList §3, Gap §4/§5 | V1 test_18 / V2 test_04, test_16 |

## 6. `05_` Constraints Applied
- A1/A2/A3 tenancy: `initializeTenantContext()` via `Modules\Prime\Models\Domain`; guarded `tenancy()->end()`. Tenant-side (prefix `msh_`, `Database: tenant_db`).
- B5/B7: `use App\Models\User;` + `User::factory()` (limited-user helper) matching the golden sibling; `password` treated as fillable.
- B8/B9: limited-user factory passes `emp_code` (`L_`+uniqid ≤ 20), `prefered_language`, `user_type='EMPLOYEE'` when the columns exist; all guarded by `Schema::hasColumn`.
- C11/C12: `forceDelete()` wrapped in try/catch; `withTrashed()`/`onlyTrashed()` used only on models that DO use SoftDeletes (`MarksheetSchedule`, `SubjectPracticalConfig`) — **never on `ScheduleClass`** (BUG-MSH-101; asserted via `class_uses_recursive`, not exercised).
- C13: all typed properties initialised.
- D14: Dusk `Browser` has no `assertStatus()` — lifecycle POSTs issued via `sendJsonRequestFromBrowser` (authenticated fetch) and asserted through DB + activity/computation-log side effects.
- D18: ENUM/dropdown values (`DRAFT..LOCKED`) matched case-sensitively against `sys_dropdowns`.
- E19: module-enabled prerequisite noted (below).
- E20: `APP_ENV=testing` set by both runners (bypasses CSRF).

## 7. Environment Prerequisites (not test-code fixes)
1. **Module enabled:** `prime_testing/modules_statuses.json` has `"MarksheetGeneration": false` → all routes 404. Set to `true` before running.
2. **Status dropdowns seeded:** `sys_dropdowns` rows for key `msh_marksheet_schedules.status_id` = DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED (tests `markTestSkipped` if absent).
3. **Seed data:** at least one active `msh_config_templates` row, one `sch_org_academic_sessions_jnt`, and (for practical/class-section tests) one `sch_classes`, `sch_subjects`, `sch_class_section_jnt`.
4. **D39-MSH:** MSH permissions are not seeded in `TenantRolePermissionSeeder`; suites best-effort grant them to the admin via Spatie (`givePermissionTo`/role sync). The 403 test (V2 51) requires a permission-less user; skipped if one cannot be provisioned.
5. **Queue driver:** compute uses `dispatchSync` when local or `queue.default=sync`; SM assertions rely on the always-written `ComputeDispatched` activity log so they hold under async drivers too.

## 8. Dimensions Deliberately Deferred (with reason)
- **Full N+1 query-count for precheck (PERF-MSH-001):** soft timing only — an exact `DB::enableQueryLog` count needs controller-internal instrumentation outside browser Dusk.
- **Accessibility/console SEVERE smoke:** not added (scheduling is server-rendered AdminLTE; not a P0 a11y surface) — candidate for a future pass.
- **Responsive viewport smoke:** deferred (combined page reuses the standard AdminLTE responsive shell already covered by sibling suites).
- **End-to-end recompute data-wipe (PERF-MSH-004):** asserted at source level to avoid destroying shared tenant seed rows.

## 9. Final Verdict
**PASS WITH NOTES.**

All 8 artifacts present and correctly named; both PHP suites are `php -l` clean; V2 (56) ≥ 2×V1 (18); every TC maps to ≥1 method and back; state machine fully covered (legal + illegal); all audit defects plus one newly-traced defect (**BUG-MSH-101**) are documented with proving tests. Notes: (a) runtime green depends on the environment prerequisites in §7 (module enabled, dropdowns + seed data, permissions); (b) BUG-MSH-101 should be fixed in source (`use SoftDeletes;` on `ScheduleClass`) — it currently breaks any schedule create/update that includes class sections and the schedule-class trash/restore/force-delete flows.
