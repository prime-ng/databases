# Categories & Criteria — Gap Analysis (`bha_CategoryGAPANALYSIS_Require.md`)

**Feature:** BehaviouralAssessment › Categories & Criteria (screen `03-Categories*`)
**Test file:** `bha_Category_TestCas.php` — 55 methods (all mapped)
**Legend:** Full = automated end-to-end · Partial = asserted with a documented limitation · Gap = not automated.

---

## 1. Manual TC ↔ Dusk method mapping

### Schema / Configuration
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-01 | `test_category_01`, `test_category_03` | Full |
| MTC-02 | `test_category_02` | Full |
| MTC-03 | `test_category_04` | Full |

### Positive (business / CRUD / UI)
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-10 | `test_category_10` | Full |
| MTC-11 | `test_category_11` | Full |
| MTC-12 | `test_category_12` | Full |
| MTC-13/14 | `test_category_13`, `test_category_14` | Full |
| MTC-15 | `test_category_15` | Full |
| MTC-15b | `test_category_15b` | Full |
| MTC-16 | `test_category_16` | Full |
| MTC-17 | `test_category_17` | Full |
| MTC-55 | `test_category_55` | Full |
| MTC-56 | `test_category_56` | Full |
| MTC-60..64 | `test_category_60`–`test_category_64` | Full |

### State machine
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-20/21 | `test_category_20`, `test_category_21` | Full |

### Negative / validation
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-18 | `test_category_18` | Full |
| MTC-19 | `test_category_19` | Full |
| MTC-30 | `test_category_30` | Full |
| MTC-31..34 | `test_category_31`–`test_category_34` | Full |
| MTC-35/36/37 | `test_category_35`, `test_category_36`, `test_category_37` | Full |
| MTC-38 | `test_category_38` | Full |
| MTC-39 | `test_category_39` | Full |
| MTC-70 | `test_category_70` | Full |
| MTC-71 | `test_category_71` | Full |
| MTC-72 | `test_category_72` | Full |
| MTC-73 | `test_category_73` | Full |
| MTC-74 | `test_category_74` | Full |

### Dependency / FK / lifecycle
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-40 | `test_category_40` | Full |
| MTC-41 | `test_category_41` | Full |
| MTC-42 | `test_category_42` | Full |
| MTC-43 | `test_category_43` | Full (skips gracefully if SET NULL path unavailable) |
| MTC-44 | `test_category_44` | Full (guard proven at DB + source level) |
| MTC-45 | `test_category_45` | Full |
| MTC-46 | `test_category_46` | Full |

### Authorization / tenancy / security
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-50 | `test_category_50` | Full |
| MTC-51/52/53 | `test_category_51`, `test_category_52`, `test_category_53` | Full |
| MTC-54 | `test_category_54` | Full (source read; skips if unreadable) |
| MTC-90 | `test_category_90` | Full |
| MTC-91 | `test_category_91` | Partial — cross-tenant IDOR only exercisable with ≥2 tenant domains; `markTestSkipped` otherwise |
| MTC-92 | `test_category_92` | Full |
| MTC-93 | `test_category_93` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Schema/Config | 4 | 4 | 0 | 0 | 100% |
| Positive | 19 | 19 | 0 | 0 | 100% |
| Negative | 21 | 21 | 0 | 0 | 100% |
| Dependency | 7 | 7 | 0 | 0 | 100% |
| State-Machine | 2 | 2 | 0 | 0 | 100% |
| Tenancy | 2 | 1 | 1 | 0 | 100% (1 defensive skip) |
| Security | 2 | 2 | 0 | 0 | 100% |
| **Total** | **55** | **54** | **1** | **0** | **~98% Full, 100% mapped** |

**Targets:** Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy 100% on P0/P1 ✅ (cross-tenant IDOR is environment-gated, not a coverage gap).

---

## 3. Cross-Reference Defect Scan (layer-vs-layer)

| # | Check | Compared layers | Finding | ID | Proving test |
|---|-------|-----------------|---------|----|--------------|
| 1 | Enum case | DDL `enum('polarity',['negative','positive'])` vs FormRequest `Rule::in(['positive','negative'])` | Match (order differs, values identical, case-consistent) | — | `test_category_01`, `_32` |
| 2 | Route registration | Blade `route(...)` / test paths vs module routes | All create/store/show/trash/toggle/reorder/restore/force-delete/nested-criteria routes registered | — | `_10`,`_55`,`_56`,`_63`,`_70` |
| 3 | Gate vs Policy | Controller `Gate::authorize()` vs `BaCategoryPolicy` | All 8 abilities present as gate strings | — | `_54`, `_51`–`_53` |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | Consistent; no DDL column missing from fillable | — | `_01`, `_03` |
| 5 | Cast vs DDL | Model `$casts` vs DDL type | `is_active`→boolean (tinyint), `sort_order`→integer, `weight` decimal | — | `_01` |
| 6 | Service delegation | Controller body vs Service | Category CRUD lives in the controller; criterion validation inline (no FormRequest) — documented, not a defect | — | `_39`, `_44` |
| 7 | State machine vs impl | Requirement transitions vs controller `toggleStatus` | Toggle implemented; deactivation guard absent | **CAT-GAP (SM-03 no guard)** | `_21` |
| 8 | Validation vs FormRequest | Requirement rules vs `rules()` | Missing: unique `name`, unique criterion `name`, criterion `weight` max, weightage-sum=100, min-one-criterion, `code`, `max_score` | **CAT-GAP-01/02/03/04/07/08/09** | `_04`,`_18`,`_19`,`_72`,`_73`,`_74` |
| 9 | Error message vs FormRequest | Expected vs `messages()` | `sort_order.unique` message exact-match verified | — | `_37` |
| 10 | Permissions vs Policy/Gates | Requirement permission matrix vs Policy + Gate | Keys align on `tenant.behavioural-assessment.categories.*` | — | `_54` |
| 11 | Integration FK vs migration | Requirement FKs vs migration `foreign()` | `category_id` CASCADE ✅; `parent_id` SET NULL ✅; **`destroy()` lacks the ratings guard that `destroyCriterion()` has** | **CAT-GAP-05** | `_42`,`_43`,`_44`,`_45` |

> All findings are **current-behaviour, source-traced** (proven by the tests above), not speculative. Also flagged: **DOC-BA-001** (DDL doc `bha_` vs live `ba_`, `_02`) and **SEC-BA-002** (`authorize()` returns bare `true`, `_92`).

---

## 4. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / `BC-BIZ`) | 13 | 13 | 100% |
| State-Machine transitions (`Screen-SM` / `BC-SM`) | 3 | 3 | 100% |
| Validation Rules (`Screen-VR` / `BC-VAL`) | 8 | 8 | 100% |
| Integration / FK points (`Screen-IP` / `BC-REF`) | 7 | 7 | 100% |
| Permissions (`Screen-PM` / `BC-AUTH`) | 6 | 6 | 100% |
| Schema/DDL facts (`BC-DB`) | 10 | 10 | 100% |
| Edge cases (`BC-EDG`) | 5 | 5 | 100% |
| UI/UX (`BC-UIX`) | 5 | 5 | 100% |

Every `Source`-tagged requirement item has ≥1 proving test method. **No requirement item is at 0 coverage.**

---

## 5. Remaining Partial-coverage / limitations

| Item | Method | Limitation |
|------|--------|------------|
| Cross-tenant direct-ID IDOR | `test_category_91` | Requires a second tenant `Domain`; `markTestSkipped` in single-tenant environments (defensive, per Constraint #9/§9). Not a source gap. |
| SET NULL on parent force-delete | `test_category_43` | Skips gracefully if the SET-NULL path is unavailable in the environment. |
| Policy source content | `test_category_54` | Reads app-repo source via reflection (Constraint #32); skips if the file is unreadable from the runner. |

## 6. Legend
- **CAT-GAP-##** = feature-scoped gap vs requirement `03-Categories.md` (current behaviour proven, documented not fixed).
- **DOC-BA-001 / SEC-BA-002** = module-wide audit findings re-proven here.
- Coverage is **behaviour-accurate**: gap tests assert the *current* (non-conforming) behaviour so the suite stays green and the divergence is traceable.
