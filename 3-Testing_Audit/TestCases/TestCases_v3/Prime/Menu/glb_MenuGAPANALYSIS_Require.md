# Menu (PRM / Central) — Gap Analysis & Coverage

Single test file: `glb_Menu_TestCas.php` — **52 test methods**. Prefix `glb_` (DDL-verified; registry PRM `prm_` mismatch flagged).

## 1. Manual TC ↔ Dusk Method Mapping

### Positive
| TC | Method | Coverage |
|----|--------|----------|
| TC-P01 | test_menu_01 | Full |
| TC-P02 | test_menu_02 | Full |
| TC-P10 | test_menu_10 | Full |
| TC-P11/P12 | test_menu_11/12 | Full |
| TC-P13 | test_menu_13 | Full (DB write; skips if env lacks central write) |
| TC-P14/P15/P16 | test_menu_14/15/16 | Full |
| TC-P20/P21 | test_menu_20/21 | Full |
| TC-P60–P66 | test_menu_60..66 | Full |

### Negative
| TC | Method | Coverage |
|----|--------|----------|
| TC-N22/N23 | test_menu_22/23 | Full |
| TC-N30 | test_menu_30 | Full |
| TC-N31 | test_menu_31 | Full |
| TC-N32–N36 | test_menu_32..36 | Full (rule-source assertion) |
| TC-N37/N38/N39 | test_menu_37/38/39 | Full |
| TC-N50/N51 | test_menu_50/51 | Full |
| TC-N57/N58/N59 | test_menu_57/58/59 | Full |
| TC-N70/N71/N72 | test_menu_70/71/72 | Full |
| TC-N73/N74 | test_menu_73/74 | Full (defect-proving) |

### Dependency / Tenancy / Security
| TC | Method | Coverage |
|----|--------|----------|
| TC-D24 | test_menu_24 | Full |
| TC-D40 | test_menu_40 | Full |
| TC-D41–D44 | test_menu_41..44 | Full |
| TC-D45/D46 | test_menu_45/46 | Full |
| TC-T90/T91 | test_menu_90/91 | Full |
| TC-S92/S93 | test_menu_92/93 | Full |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 18 | 18 | 0 | 0 | 100% |
| Negative | 22 | 22 | 0 | 0 | 100% |
| Dependency | 8 | 8 | 0 | 0 | 100% |
| Tenancy/Security | 4 | 4 | 0 | 0 | 100% |
| **Total** | **52** | **52** | **0** | **0** | **100%** |

Gates: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy (central) covered ✅.

## 3. Coverage-Score by Requirement Source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 10 | 10 | 100% |
| State-Machine (BC-SM) | 4 | 4 | 100% |
| Validation Rules (Screen-VR) | 8 | 8 | 100% |
| Integration Points (BC-INT/REF) | 4 | 4 | 100% |
| Permissions (Screen-PM) | 7 | 7 | 100% |

Every Source-tagged requirement item has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 1 | Enum case | DDL vs FormRequest | `menu_for in:prime,tenant` — no ENUM in DDL (`menu_for` column absent → DEV-PRM-MENU-003). No case bug. |
| 2 | Route registration | Blade `route()` vs web.php | All `central.system-config.menu.*` registered. But **3 duplicate `system-config` groups** register menu routes (DUP-PRM-001). |
| 3 | Gate vs Policy | controller `Gate::authorize` vs `PrimeMenuPolicy` | Aligned (`prime.menu.*`). Policy type-hints `Modules\Prime\Models\User`. |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | `menu_for`, `permission` fillable but **not in consolidated DDL** → DEV-PRM-MENU-003 (schema drift). |
| 5 | Cast vs DDL | model `$casts` vs DDL | booleans/int casts match tinyint/int. OK. |
| 6 | Service delegation | controller vs service | No service layer; logic in controller (acceptable for this screen). |
| 7 | State machine vs impl | transitions vs controller | toggle/trash/restore/forceDelete all implemented. OK. |
| 8 | Validation vs FormRequest | rules vs `rules()` | route conditional inverted for categories → DEV-PRM-MENU-004. |
| 9 | Error message vs FormRequest | expected vs messages | No custom `messages()`; defaults + flash. OK. |
| 10 | Permissions vs Policy | matrix vs Policy+gates | Full 1:1. OK. |
| 11 | Integration FK vs migration | FK vs DDL | `parent_id` RESTRICT verified; `translations`→CASCADE; junction `glb_menu_module_jnt`. OK. |
| + | Route-model binding | route param vs controller hint | `toggleStatus` `{user}` ≠ `Menu $menu` → **DEV-PRM-MENU-001**. |
| + | Unique scope | DDL unique vs FormRequest | global `uq_glb_menus_code` vs scoped-by-`menu_for` validation → **DEV-PRM-MENU-002**. |
| + | Dead field | FormRequest vs model/DDL | `is_direct_link` validated, never persisted → DEV-PRM-MENU-005. |
| + | Performance | Navbar component | `resolveActiveMainMenu()` `Menu::find()` in `while` loop → **PERF-PRM-002** (N+1). DEAD-PRM-001: it is a Blade Component (`App\View\Components\Backend\Partials\Navbar`), not a route — static-only finding, no runtime route test. |

## 5. Documented Defects (with proving tests)
| ID | Sev | Proving test | Notes |
|----|-----|--------------|-------|
| DEV-PRM-MENU-001 | P2 | test_menu_73 | Broken implicit binding on toggleStatus. |
| DEV-PRM-MENU-002 | P2 | test_menu_74 | Global unique code vs scoped validation. |
| DEV-PRM-MENU-003 | P3 | test_menu_01 (fail-soft) | menu_for/permission DDL drift. |
| DEV-PRM-MENU-004 | P3 | test_menu_38 | Inverted conditional route rule. |
| DEV-PRM-MENU-005 | P4 | (static, this doc) | is_direct_link non-persisted. |
| PERF-PRM-002 | P2 | (static, this doc) | Navbar N+1 loop; Blade component (DEAD-PRM-001). |
| DUP-PRM-001 | P4 | test_menu_02 context | Triplicate route group registration. |

## 6. Known Limitations
- DB-mutation tests (create/toggle/reorder/lifecycle/FK) run against the live central `global_master` DB and `markTestSkipped()` when the environment cannot write, keeping partial environments green (idiom + Constraint #9).
- JSON endpoint status is read via a synchronous in-page XHR (`sendJsonRequestFromBrowser`) because Dusk `Browser` lacks `assertStatus()`/`->post()` (Constraint #14) and central routes are domain-scoped (Constraint #21) so external `getJson()` would miss the `central.` domain.
- Permission-gate tests create a non-super-admin user; if the super-admin `Gate::before` bypass exists in this env, `markTestSkipped` may fire — documented, not a test defect.

## Legend
Full = behaviour asserted end-to-end (or at the authoritative source layer for config truths). Partial = asserted indirectly. Gap = no coverage. None here.
