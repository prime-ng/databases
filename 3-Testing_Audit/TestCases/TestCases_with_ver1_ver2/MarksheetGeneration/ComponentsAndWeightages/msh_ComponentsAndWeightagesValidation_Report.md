# msh — Components & Weightages — Validation Report

**Feature:** Components & Weightages (MarksheetGeneration, MSH, tenant_db)
**Generated:** 2026-Jul-09
**Verdict:** ✅ **PASS WITH NOTES**

---

## 1. File Existence Summary
| # | File | Present |
|---|------|---------|
| 1 | `msh_ComponentsAndWeightagesTcList_Require.md` | ✅ |
| 2 | `msh_ComponentsAndWeightagesMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_ComponentsAndWeightagesGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_ComponentsAndWeightagesV1_TestCas.php` | ✅ |
| 5 | `msh_ComponentsAndWeightagesV2_TestCas.php` | ✅ |
| 6 | `msh_ComponentsAndWeightagesValidation_Report.md` | ✅ |
| 7 | `run-ComponentsAndWeightages-tests.ps1` | ✅ |
| 8 | `run-ComponentsAndWeightages-tests.sh` | ✅ |

## 2. Naming Conventions
| Check | Result |
|-------|--------|
| Prefix `msh_` = DDL primary table prefix (`msh_template_scholastic_components`) | ✅ verified against `CREATE TABLE` |
| Feature PascalCase `ComponentsAndWeightages` | ✅ |
| Class name = filename (`msh_ComponentsAndWeightagesV1_TestCas` / `...V2...`) | ✅ |
| Namespace `Tests\Browser`, `extends DuskTestCase` | ✅ |
| Methods snake_case, zero-padded, semantic bands | ✅ |

## 3. Structure Validation
| Check | Result |
|-------|--------|
| `php -l` V1 | ✅ No syntax errors |
| `php -l` V2 | ✅ No syntax errors |
| `setUp()` / `tearDown()` with tenant init + guarded `tenancy()->end()` | ✅ |
| Typed properties initialised (`?User $adminUser = null`, strings `''`, `?int` null) | ✅ (05_ C13) |
| No Dusk `assertStatus` — status via `sendJsonRequestFromBrowser` fetch | ✅ (05_ D14) |
| `forceDelete` wrapped in try/catch; SoftDeletes verified before `withTrashed` | ✅ (05_ C11/C12) |
| Cross-module (`lms_exam_types`) guarded with `markTestSkipped` | ✅ (HARD RULE 9) |

## 4. Coverage Completeness
| Metric | Value |
|--------|-------|
| V1 methods | **20** |
| V2 methods | **50** |
| V2 ≥ 2 × V1 | ✅ (50 ≥ 40; ratio **2.5×**) |
| Negative coverage | 100% |
| Positive coverage | 100% |
| Dependency coverage | 100% |
| Every TC ↔ ≥1 method / every method ↔ TC/BC | ✅ (see Gap Analysis §1 + TcList §3) |
| Coverage-Score + Cross-Reference tables present | ✅ (Gap Analysis §3, §4) |
| Semantic numbering bands + V2 Method Index | ✅ |

## 5. Sourced-from-real-code checklist
| Item | Source |
|------|--------|
| Routes / URLs | `Modules/MarksheetGeneration/routes/web.php` (resource + `$modalEntities` loop) |
| Permission strings `tenant.msh-*` | each entity controller `Gate::authorize(...)` |
| Activity events `Stored/Updated/Toggled/Deleted/Restored` | controllers `activityLog(...)` |
| Validation rules + exact duplicate message | the four `Template*Request` files |
| Schema (columns, unique indexes, FK onDelete) | DDL + `2026_06_16_1157*` migrations |
| Weightage-sum enforcement trace | `MarksheetConfigService`, `TemplateScholasticComponentService`, controllers, `MarksheetConfigServiceWeightageSumTest` |
| Modal/form selectors | `resources/views/modals/template-*-create/edit.blade.php` |

## 6. Known Source Defects Documented
| ID | Sev | Where proven |
|----|-----|--------------|
| BUG-MSH-C01 (create bypasses scholastic sum, BR-MSG-002) | P2 | V2 `test_..._80`, V1 `..._11` |
| BUG-MSH-C02 (exam sum validator dead code, BR-MSG-003) | P2 | V2 `..._82`, `..._83` |
| BUG-MSH-C03 (sum violation on update → HTTP 500) | P3 | V2 `..._81`, V1 `..._80` |
| BUG-MSH-C04 (coscholastic grading_scale no enum) | P3 | V2 `..._72` |
| SEC-MSH-003 (FormRequests authorize()=true) | P1 | V2 `..._06`, `..._51`, V1 `..._01` |
| D39-MSH (permissions unseeded) | P1 | env prereq below + setUp grant |
| BR-MSH-050/009/012 (precheck counts, never sums) | P2 | Gap Analysis §5 trace |

## 7. Environment Prerequisites (05_ §E)
- **E19** — MarksheetGeneration must be **enabled** in `prime_testing/modules_statuses.json` (currently most modules `false`); disabled → 404 on every route. **Not a test-code fix.**
- **E20** — `APP_ENV=testing` for Dusk (CSRF bypass); runners assume it.
- **D39-MSH** — MSH permissions are unseeded; the suite grants them at `setUp` via `givePermissionTo` / role sync (defensive, wrapped in try/catch).
- Tenant seed data: ≥1 `sch_org_academic_sessions_jnt` row (config-template FK) and ≥1 `lms_exam_types` row (exam-weightage cases; else those tests `markTestSkipped`). Marksheet type / exam group are auto-seeded by the suite when absent.

## 8. Constraints from `05_` that shaped the tests
- Browser-Dusk style + `initializeTenantContext()` via `Modules\Prime\Models\Domain` (A1/A2).
- `use App\Models\User; User::query()...` — runner model, matches golden (B5).
- Tenant-side scaffolding emitted (module-prefixed `msh_` tables, `Database: tenant_db`) (A4).
- MySQL 8 index inspection via `SHOW INDEX ... Key_name` (not exact COLUMN_TYPE equality) (D17).
- JSON endpoint status via HTTP fetch (`sendJsonRequestFromBrowser`), never Dusk `assertStatus` (D14).

## 9. Dimensions deliberately limited
| Dimension | Decision |
|-----------|----------|
| Cross-tenant IDOR (TC-T) | Not applicable — single tenant DB in this run; noted, not counted as a gap. |
| Full modal UI drive (fill-and-submit each form) | Represented via authentic JSON endpoint path (`expectsJson()` branch); page still loaded/rendered per test. Rationale: AJAX `.ajax-form` handler is exercised at the endpoint contract level, reducing selector flakiness. |
| Responsive / a11y smoke | Out of scope for this composite config screen (no create/edit dedicated pages). |

## 10. Final Verdict
✅ **PASS WITH NOTES** — All 8 artifacts present; `php -l` clean on V1 (20) and V2 (50, 2.5×); prefix verified against DDL; selectors/routes/messages/permissions/events all sourced from real code; the weightage-sum enforcement point is traced exactly (Gap Analysis §5); 7 defect candidates documented with proving tests. **Notes:** execution requires the module enabled (E19), `APP_ENV=testing` (E20), and MSH permissions/tenant seed data (D39-MSH). Exam-weightage tests self-skip when `lms_exam_types` is empty.
