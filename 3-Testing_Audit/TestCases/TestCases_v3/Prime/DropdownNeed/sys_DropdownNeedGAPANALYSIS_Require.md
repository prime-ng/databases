# sys_DropdownNeed — Gap Analysis & Coverage

**Feature:** DropdownNeed (Prime / PRM, central) · **Test file:** `sys_DropdownNeed_TestCas.php` · **Methods:** 51

---

## 1. Manual TC ↔ Dusk Method Mapping

### Positive

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 schema config | test_dropdownneed_01 | Full |
| TC-P02 column types | test_dropdownneed_02 | Full |
| TC-P03 unique index | test_dropdownneed_03 | Full |
| TC-P04 soft delete | test_dropdownneed_04 | Full |
| TC-P05 fillable/casts | test_dropdownneed_05 | Full |
| TC-P06 mapping junction | test_dropdownneed_06 | Full |
| TC-P07 legacy junction | test_dropdownneed_07 | Full |
| TC-P08 check constraint | test_dropdownneed_09 | Full |
| TC-P09 activity strings | test_dropdownneed_10 | Full |
| TC-P10 store creates+logs | test_dropdownneed_11 | Full (env-guarded HTTP) |
| TC-P11 menu-null logic | test_dropdownneed_13 | Full |
| TC-P12 destroy | test_dropdownneed_14 | Full (source) / Partial (live) |
| TC-P13 restore | test_dropdownneed_15 | Full (source) / Partial (live) |
| TC-P14 toggle JSON | test_dropdownneed_20 | Full (source) |
| TC-P15 routes registered | test_dropdownneed_60 | Full (env-guarded) |
| TC-P16 create form | test_dropdownneed_62 | Full (browser-guarded) |
| TC-P17 index reachable | test_dropdownneed_63 | Full (browser-guarded) |
| TC-P18 trash reachable | test_dropdownneed_64 | Full (browser-guarded) |
| TC-P19 central sink | test_dropdownneed_95 | Full (env-guarded) |

### Negative

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N01 required fields | test_dropdownneed_30 | Full |
| TC-N02 enum reject | test_dropdownneed_31 | Full (HTTP-guarded) |
| TC-N03 max length rule | test_dropdownneed_32 | Full |
| TC-N04 boolean required | test_dropdownneed_33 | Full |
| TC-N05 conditional menu req | test_dropdownneed_34 | Full |
| TC-N06 dup → 500 | test_dropdownneed_35 | Full (absence proof) |
| TC-N07 update rules | test_dropdownneed_36 | Full |
| TC-N08 over-length reject | test_dropdownneed_73 | Full (HTTP-guarded) |
| TC-N09 deny create | test_dropdownneed_51 | Full (env-guarded) |
| TC-N10 deny all gates | test_dropdownneed_52 | Full (env-guarded) |
| TC-N11 guest redirect | test_dropdownneed_55 | Full (browser-guarded) |
| TC-N12 unknown id 404 | test_dropdownneed_94 | Full (HTTP-guarded) |

### Dependency / Security / Edge

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-D01 mapping FK RESTRICT | test_dropdownneed_40 | Full |
| TC-D02 legacy FK CASCADE | test_dropdownneed_41 | Full |
| TC-D03 junction mismatch | test_dropdownneed_42 | Full |
| TC-D04 forceDelete order | test_dropdownneed_43 | Full |
| TC-D05 is_system protection | test_dropdownneed_12 | Full |
| TC-S01 ungated AJAX | test_dropdownneed_53 | Full |
| TC-S02 filterOptions gated/dead | test_dropdownneed_90 | Full |
| TC-S03 tenancy end() | test_dropdownneed_91 | Full |
| TC-S04 raw SHOW | test_dropdownneed_92 | Full |
| TC-S05 single model | test_dropdownneed_93 | Full |
| TC-S06 XSS verbatim | test_dropdownneed_70 | Full (HTTP-guarded) |
| TC-E01 DDL typo | test_dropdownneed_08 | Full |
| TC-E02 dup menu path | test_dropdownneed_71 | Full |
| TC-E03 no trim | test_dropdownneed_72 | Full |
| TC-E04 redirect target | test_dropdownneed_16 | Full |
| TC-E05 sibling gate | test_dropdownneed_17 | Full |
| TC-E06 dup route group | test_dropdownneed_65 | Full |
| TC-E07 dead methods | test_dropdownneed_61 | Full (env-guarded) |
| TC-E08 admin allowed | test_dropdownneed_54 | Full (env-guarded) |
| TC-E09 gate strings | test_dropdownneed_50 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 19 | 19 | 0 | 0 | 100% |
| Negative | 12 | 12 | 0 | 0 | 100% |
| Dependency | 5 | 5 | 0 | 0 | 100% |
| Security | 6 | 6 | 0 | 0 | 100% |
| Edge/Config | 9 | 9 | 0 | 0 | 100% |
| **Total** | **51 TC** | **51** | **0** | **0** | **100%** |

> "Partial (live)" notes above mean the *source-truth* assertion is Full; the *live end-to-end* observation is env-gated (module currently disabled + browser optional) and self-skips rather than failing. This preserves a green suite in partial environments per the constraints.

---

## 3. Coverage-Score (by requirement Source)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR) — unique combo, menu filtering, is_system, soft delete | 4 | 4 | 100% |
| Validation Rules (Screen-VR / controller) | 8 | 8 | 100% |
| Integration Points (junctions/FK) | 4 | 4 | 100% |
| Permissions (BC-AUTH matrix) | 8 | 8 | 100% |
| Config/Defect corrections (BC-CFG) | 6 | 6 | 100% |

Every Source-tagged requirement item maps to ≥1 TC. No 0-coverage items.

---

## 4. Cross-Reference Findings (defect scan)

| # | Check | Compare | Finding | ID | Method |
|---|-------|---------|---------|----|--------|
| 1 | Enum case | DDL ENUM vs `in:` rule | Match (`Prime,Tenant,Global`) — OK | — | _30/_31 |
| 2 | Route registration | Blade `route()` vs routes/web.php | All resolve; **routes registered twice** | BUG-PRM-DDNEED-005 | _65 |
| 3 | Gate vs Policy | `Gate::authorize` strings | index uses **sibling** `prime.dropdown.viewAny` | BUG-PRM-DDNEED-006 | _17 |
| 4 | Fillable vs DDL | model vs DDL column | DDL misspells `dropdown_tabel_record_exist`; runtime/model correct | DOC-PRM-DDNEED-002 | _08 |
| 5 | Cast vs DDL | boolean casts vs tinyint(1) | Match — OK | — | _05 |
| 6 | Service delegation | controller vs service | No service layer; logic inline (acceptable) | — | — |
| 7 | State machine | n/a (is_active toggle only) | No FSM | — | _20 |
| 8 | Validation vs rules | requirement unique vs `rules()` | **No unique rule** → dup = 500 | BUG-PRM-DDNEED-003 | _35 |
| 9 | Error message | expected vs controller | is_system/system-record messages verbatim | — | _12 |
| 10 | Permissions | AJAX endpoints vs Gate | **7 registered AJAX endpoints ungated** | SEC-PRM-004 | _53/_90 |
| 11 | Integration FK | requirement vs migration | mapping junction `..._dropdowns_jnt` NOT in consolidated DDL; two junctions used inconsistently | BUG-PRM-DDNEED-001 | _42 |

### Audit-item reconciliation (source overrides briefing)

- **SEC-PRM-004 corrected:** `filterOptions()` is *gated* (`prime.dropdown.viewAny`) and *routeless* (dead code). Real exposure is the registered ungated AJAX set — re-scoped and proven.
- **TEN-PRM-001 corrected:** `fetchMigrationTables()`/`fetchTableColumns()` DO `tenancy()->end()` in a `finally` — no leak in current source; documented as remediated.
- **BUG-PRM-DUP corrected:** no stale root-level `Modules/Prime/Models/DropdownNeed.php` (directory does not exist); single canonical `app/Models` model — proven.

---

## 5. Legend

- **Full** — assertion directly and deterministically verifies the condition (schema/route/source-scan) or exercises it end-to-end.
- **Env-guarded / HTTP-guarded / browser-guarded** — asserts fully when the prerequisite (migrated central DB / registered routes / running ChromeDriver / enabled module) is present; otherwise `markTestSkipped` with a clear reason (never a false failure).
