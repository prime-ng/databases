# FrontOffice → Circular — AGENTS.md Gold Standard Review

> **Review date:** 2026-07-15
> **Scope:** `tests/Created_by_Brijesh/Version-2/FrontOffice/Circular/` (5 files)
> **Reference:** StockItem V2 Gold Standard (`caf_StockItemV2_TestCas.php`, 841 lines, 36 methods, 35 TCs)

---

## 1. File Structure

| Artifact | Present | Notes |
|----------|---------|-------|
| `fof_CircularTcList_Require.md` | ✅ | Combined spec (Feature Info + BC + TC list + Method Index + Manual Steps + Defects) |
| `fof_CircularGAPANALYSIS_Require.md` | ✅ | Coverage traceability by category |
| `fof_CircularValidation_Report.md` | ✅ | Structure, naming, env prereqs, verdict |
| `fof_Circular_TestCas.php` | ✅ | 1195 lines, 42 test methods |
| `run-Circular-tests.php` | ✅ | Cross-platform PHP runner |
| **Total: 5 artifacts** | ✅ | Complete file set |

### ❌ File Placement Issue

- **Current:** `tests/Created_by_Brijesh/Version-2/FrontOffice/Circular/`
- **Standard:** `tests/Browser/Modules/FrontOffice/Circular/`
- **Namespace in code:** `Tests\Browser\Modules\FrontOffice\Circular` ✅ (matches standard path, not current path)

---

## 2. PHP Syntax

| Check | Result |
|-------|--------|
| `php -l fof_Circular_TestCas.php` | ✅ PASS |

---

## 3. Source Code Verification

| Item | Path | Status |
|------|------|--------|
| Controller | `Modules/FrontOffice/Http/Controllers/CircularController.php` | ✅ Exists (220 lines, 13 methods) |
| Model | `Modules/FrontOffice/Models/Circular.php` | ✅ Exists (SoftDeletes + InteractsWithMedia) |
| Service | `Modules/FrontOffice/Services/CircularService.php` | ✅ Exists (251 lines, full lifecycle) |
| Policy | `Modules/FrontOffice/Policies/CircularPolicy.php` | ✅ Exists (9 gate methods) |
| Routes | `Modules/FrontOffice/routes/web.php` | ✅ Exists (14 circular routes) |
| DDL | `pgdatabase/.../FrontOffice_DDL_v1.sql` | ✅ `fof_circulars` + `fof_circular_distributions` defined |
| Views | `resources/views/fof/circulars/*.blade.php` | ✅ 5 Blade files |
| Module enabled | `modules_statuses.json` → `FrontOffice: false` | ❌ **Must be `true` to run Dusk** |

---

## 4. TcList Structure — 12-Section Compliance

| # | Section | Status | Details |
|---|---------|--------|---------|
| 1 | Feature Information | ✅ | Module, URL, Controller, Model, Validation, Permissions |
| 2 | Pre-conditions | ❌ **Missing** | Required permissions, seed data, related records |
| 3 | Test Data Strategy | ❌ **Missing** | Unique suffix, ENUM values, cleanup strategy |
| 4.1 | Database Schema (table format) | ⚠️ Partial | Listed as ID→Fact→TC, not standard BC-ID/Column/Type/Constraints/Covered By table |
| 4.2 | Indexes | ❌ **Missing** | No index table |
| 4.3 | Foreign Keys | ⚠️ Partial | Listed in BC-REF/BC-INT but not in standard table format |
| 4.4 | Validation Rules | ⚠️ Partial | Listed as ID→Rule→TC, not standard Field/Rule/Error Message/Covered By |
| 4.5 | Authorization | ⚠️ Partial | Listed as ID→Fact→TC, not standard Permission/Method/Behavior/Covered By |
| 4.6 | Business Logic | ⚠️ Partial | Listed as ID→Fact→TC, not standard Condition/Expected/Covered By |
| 4.7 | Routes | ❌ **Missing** | No route reference table |
| 5 | Test Case List | ✅ | Positive + Negative + Dependency with TC IDs |
| 6 | Detailed Test Steps | ❌ **Missing** | Has "Manual Test Steps" for 3 workflows only, no per-TC step-by-step tables |
| 7 | V2 Test Method Index | ✅ | 42 methods mapped to TC IDs (sequential bands) |
| 8 | Coverage Summary | ❌ **Missing from TcList** | Present in GapAnalysis but not in TcList itself |
| 9 | Route Reference | ❌ **Missing** | No route table with Method/URI/Name/Gate |
| 10 | Development Issues Found | ⚠️ Partial | 5 defects listed in §6 but not in standard ID/Area/Issue/Severity table |
| 11 | Known Issues Summary | ❌ **Missing** | No remaining open issues section |
| 12 | Execution Status | ❌ **Missing** | No TC tracking table with Status/Date/Tester |

---

## 5. TestCas — Phase 3 Coverage Checklist

### 5.1 Schema Tests (3 required)

| # | Test | Status |
|---|------|--------|
| 1 | Migration + Model + Request configuration | ✅ test_01 |
| 2 | DB required fields reject missing values (loop NOT NULL) | ✅ test_03 |
| 3 | DB nullable fields accept null | ✅ test_04 |

### 5.2 Positive Tests (16 minimum)

| # | Test Type | Status | Method | Notes |
|---|-----------|--------|--------|-------|
| 1 | Page/tab loads with UI elements | ✅ | test_60 | Index loads + sees circular number |
| 2 | Create page loads with form fields | ✅ | test_63 | Asserts title/subject/body/audience/date present |
| 3 | Create with all fields | ✅ | test_10 | Service create with full payload |
| 4 | Create with required only (defaults) | ✅ | test_04 | Status=Draft, is_active=1 verified |
| 5 | Show page / detail view | ✅ | test_64 | Displays circular_number |
| 6 | **Edit page prefills existing values** | ❌ **Missing** | — | No test loads edit page and verifies prefill |
| 7 | **Update fields (non-locked)** | ❌ **Missing** | — | test_12 only tests LOCKED (Approved) update; no Draft update flow |
| 8 | **Toggle status via AJAX (positive)** | ❌ **Missing** | — | test_73 is negative-only (proves no activity log); no positive toggle+verify |
| 9 | Soft delete | ✅ | test_70 | Soft deleted, moves to trash |
| 10 | Restore | ✅ | test_71 | Restored + activity log verified |
| 11 | Force delete | ✅ | test_72 | Force delete + activity log verified |
| 12 | Search by name/text | ✅ | test_62 | Search by title returns match |
| 13 | Filter by status | ✅ | test_61 | ?status=Draft shows draft row |
| 14 | Child record creation | ✅ | test_13 | Distribute creates distribution rows |
| 15 | Empty trash state | ✅ | test_65 | Trash view lists soft-deleted items |
| 16 | **Status-specific banner/alert** | ❌ **Missing** | — | No test for state-based UI indicators |

**Positive coverage: 13/16 = 81%** (3 missing)

### 5.3 Negative Tests (12 minimum)

| # | Test Type | Status | Method | Notes |
|---|-----------|--------|--------|-------|
| 1 | Required name/text validation | ✅ | test_30 | All required fields missing |
| 2 | **Required category/select validation** | ❌ **Missing** | — | audience required but tested only in bulk test_30 |
| 3 | **Required unit/other field validation** | ❌ **Missing** | — | No isolated single-field test (e.g., body alone) |
| 4 | Invalid ENUM value | ✅ | test_33 | audience=All rejected (ENUM divergence) |
| 5 | Negative/min violation | ✅ | test_32 | expires_on < effective_date |
| 6 | **Negative/min violation (different field)** | ❌ **Missing** | — | Only one date boundary test |
| 7 | Guest access → /login | ✅ | test_50 | Browser redirect to /login |
| 8 | No permission → 403 | ✅ | test_51-55 | 5 permission tests (view/create/approve/distribute/delete) |
| 9 | 404 on non-existent show | ✅ | test_91 | Unknown ID returns 404/403/302 |
| 10 | **404 on non-existent edit** | ❌ **Missing** | — | No edit-404 test |
| 11 | **404 on non-existent delete** | ❌ **Missing** | — | No destroy-404 test |
| 12 | **404 on non-existent toggle** | ❌ **Missing** | — | No toggle-404 test |

**Negative coverage: 8/12 = 67%** (4 missing)

### 5.4 Dependency Tests (4 minimum)

| # | Test Type | Status | Method | Notes |
|---|-----------|--------|--------|-------|
| 1 | Create → child → verify parent | ✅ | test_13 | Distribute creates distribution rows |
| 2 | Full lifecycle (create→view→edit→toggle→delete→restore→forceDelete) | ⚠️ Partial | test_20→21→22 | State machine lifecycle tested; no single CRUD lifecycle from one test |
| 3 | **FK restrict: cannot force delete when child records exist** | ❌ **Missing** | — | test_41 tests child FK restrict (insert bogus FK), not parent forceDelete |
| 4 | **Scope verification** (scopeActive, etc.) | ❌ **Missing** | — | No scope/is_active index filter test |

**Dependency coverage: 2/4 = 50%** (2 missing)

---

## 6. Phase 4 Critical Quality Rules

| # | Rule | Status | Evidence |
|---|------|--------|----------|
| 1 | Permission strings match Gate::authorize() | ✅ | Verified against controller and routes |
| 2 | ENUM values from DDL only | ✅ | DDL ENUM values used; `All` divergence documented as DEV-FOF-C02 |
| 3 | Method naming convention | ✅ | `test_circular_{NN}_{descriptive_name}` |
| 4 | **`browseWithFailureScreenshot()` wrapper** | ❌ **Missing** | Uses raw `$this->browse()` — no screenshot-on-fail capture |
| 5 | Activity log verification | ✅ | Present in create/approve/distribute/restore/forceDelete |
| 6 | Cleanup via try/finally | ✅ | `hardDelete()` in finally blocks |
| 7 | FK cleanup order (children first) | ⚠️ Partial | test_13 deletes distributions before parent; others use hardDelete which handles forceDelete |
| 8 | Unique data suffix | ✅ | `suffix()` method returns `His` + `random_int` |
| 9 | Permission 403 + forgetCachedPermissions | ✅ | Restricted user + syncPermissions + forgetCachedPermissions |
| 10 | `hasCast()` not `isCasted()` | ❌ | Uses `$model->getCasts()[]` instead of `hasCast()` |
| 11 | `->refresh()` after `->create()` | ✅ | Used in test_04, test_05 |
| 12 | `assertGreaterThanOrEqual` for seed counts | N/A | No seed count assertion needed |
| 13 | Real route URL from `route:list` | ✅ | Constants match routes/web.php |
| 14 | All user required fields (emp_code, short_name, prefered_language) | ✅ | `makeRestrictedUser()` includes all required fields |
| 15 | CSRF + X-Requested-With in AJAX | N/A | Uses `actingAs()` for HTTP tests, not browser AJAX |
| 16 | No mixing actingAs + browse | ✅ | Separate: permission tests use HTTP actingAs, UI tests use browse |
| 17 | Always `addToAssertionCount(1)` | ✅ **NOT used** | Every method has real assertions |

---

## 7. Overall Coverage Summary

| Category | Total Required | Covered | Missing | Coverage % |
|----------|---------------|---------|---------|------------|
| Schema | 3 | 3 | 0 | **100%** |
| Positive | 16 | 13 | 3 | **81%** |
| Negative | 12 | 8 | 4 | **67%** |
| Dependency | 4 | 2 | 2 | **50%** |
| **Test methods** | **35 min** | **42** | **—** | **—** |
| **TcList 12-sections** | **12** | **4** | **8** | **33%** |
| **Quality rules** | **15** | **11** | **4** | **73%** |

---

## 8. Key Gaps to Fix

### TestCas — Top Priority

| # | Missing Test | Reason |
|---|-------------|--------|
| 1 | **Edit prefill** — load `/circulars/{id}/edit`, verify fields show existing values | Standard CRUD completeness |
| 2 | **Update (Draft)** — submit PUT on Draft, verify fields changed + `circular_updated` logged | Core CRUD missing |
| 3 | **Toggle status (positive)** — POST toggle-status, verify is_active flips, response JSON | Core functionality |
| 4 | **404 on edit/delete/toggle** — invalid ID returns 404 | Security/IDOR coverage |
| 5 | **FK restrict (forceDelete)** — soft delete + create child → forceDelete blocked | Data integrity |
| 6 | **Scope/is_active test** — active vs inactive filter | Schema coverage |
| 7 | **`browseWithFailureScreenshot()`** wrapper on all `browse()` calls | CI debugging |

### TcList — Top Priority

| # | Missing Section | Reason |
|---|----------------|--------|
| 1 | §2 Pre-conditions | Required per Gold Standard |
| 2 | §3 Test Data Strategy | Required per Gold Standard |
| 3 | §4.1–4.7 Standard BC tables | Traceability per Gold Standard |
| 4 | §6 Detailed Test Steps (per-TC) | Step-by-step automation guide |
| 5 | §8 Coverage Summary in TcList | Self-contained document |
| 6 | §9 Route Reference | All gates documented |

### Infra

| # | Issue | Fix |
|---|-------|-----|
| 1 | Module disabled | Set `"FrontOffice": true` in `modules_statuses.json` |
| 2 | File placement | Move to `tests/Browser/Modules/FrontOffice/Circular/` or update namespace to match path |

---

## 9. Strengths

- **State machine coverage** is excellent (all 7 transitions, legal + illegal)
- **Bug documentation** — 5 DEV-FOF-C0x defects with proving tests
- **Activity log** verified for every lifecycle event
- **Permission 403** tests for all 5 gate types
- **Validation report** thoroughly documents env prerequisites
- **Reliable cleanup** with try/finally + hardDelete
- **Unique data** via suffix() to avoid collisions
- **XSS escape** test (test_74)
- **Guest redirect** test (test_50)
- **Error message assertions** for DomainException transitions

---

*Generated against AGENTS.md Gold Standard (StockItem V2) and Phase 3/4/5 checklists.*
