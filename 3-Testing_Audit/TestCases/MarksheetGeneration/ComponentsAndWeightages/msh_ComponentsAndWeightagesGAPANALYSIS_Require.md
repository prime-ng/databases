# Components & Weightages — Gap Analysis

**Test file:** `msh_ComponentsAndWeightages_TestCas.php` (51 methods, browser Dusk) · **Prefix verified:** `msh_`

Legend: **Full** = TC fully automated · **Partial** = automated with a documented limitation · **Gap** = manual only.

---

## 1. Coverage mapping (manual TC ↔ Dusk method)

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 schema truth (4 tables) | 01,02,03,04 | Full |
| TC-P02 casts | 05 | Full |
| TC-P03 create scholastic + Stored | 10 | Full |
| TC-P04 create exam + Stored | 11 | Full |
| TC-P05 create IA + Stored | 12 | Full |
| TC-P06 create coscholastic + Stored | 13 | Full |
| TC-P07 max_marks nullable | 14 | Full |
| TC-P08 ba_linked default | 15 | Full |
| TC-P09 update keeps sum → Updated | 19 | Full |
| TC-P10 render/list/search | 60,61,62 | Full |
| TC-P11 independent pagination | 63 | Full (static assert on controller) |
| TC-P12 boundaries 0/100 | 70,71 | Full |
| TC-P13 show valid → 200 | 76 | Full |
| TC-P14 toggle/lifecycle | 90,91,92,93 | Full |

### Negative
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N01 required | 30 | Full |
| TC-N02 >100 | 31 | Full |
| TC-N03 negative | 32 | Full |
| TC-N04 non-numeric | 33 | Full |
| TC-N05 >2 decimals | 34 | Full |
| TC-N06 duplicate + message | 35 | Full |
| TC-N07 exam required/dup/range | 36 | Full |
| TC-N08 IA required/display_order | 37 | Full |
| TC-N09 coscholastic required | 38 | Full |
| TC-N10 coscholastic dup code | 39 | Full |
| TC-N11 invalid config_template | 40 | Full |
| TC-N12 invalid source_component | 41 | Full |
| TC-N13 invalid exam_type | 42 | Full |
| TC-N14 invalid ia_type | 43 | Full |
| TC-N15 code length 31 | 75 | Full |
| TC-N16 show invalid id 404 | 74 | Full |
| TC-N17 guest redirect | 50 | Full |
| TC-N18 stored XSS escaped | 73 | Full |

### Dependency
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-D01 CASCADE | 44 | Full |
| TC-D02 RESTRICT | 45 | Full |
| TC-D03 full lifecycle | 91 | Full |

### Defect-proving
| Manual TC | Defect | Method | Coverage |
|-----------|--------|--------|----------|
| TC-DEF01 | BR-MSH-050/009/012 (scholastic create) | 16 | Full |
| TC-DEF02 | BR-MSH-009/012 (exam create) | 17 | Full |
| TC-DEF03 | BR-MSH-009/012 (dead validator, static) | 18 | Full |
| TC-DEF04 | SEC-MSH-003 | 51 (+06) | Full |
| TC-DEF05 | controller gates present | 52 (+06) | Full |
| TC-DEF06 | DEV-MSH-C03 (update 500) | 80 | Full |
| TC-DEF07 | DEV-MSH-C04 (grading_scale enum) | 72 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 14 | 14 | 0 | 0 | 100% |
| Negative | 18 | 18 | 0 | 0 | 100% |
| Dependency | 3 | 3 | 0 | 0 | 100% |
| Defect-proving | 7 | 7 | 0 | 0 | 100% |
| **Total** | **42** | **42** | **0** | **0** | **100%** |

Gate targets: Negative 100% ✅ · Positive ≥90% (100%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy 100% on P0/P1 (see §4).

---

## 3. Cross-Reference Findings (source-defect scan)

| # | Check | Compare | Finding | Test |
|---|-------|---------|---------|------|
| 1 | Enum case | DDL `grading_scale` doc (3_POINT/5_POINT) vs Request | **DEV-MSH-C04** — no `in:` rule; arbitrary value accepted | 72 |
| 2 | Route registration | Blade `route('marksheet-generation.*')` vs `web.php` + `RouteServiceProvider` | OK — resource + modalEntities registered; `map()` calls only `mapWebRoutes()` (no api routes for these) | 60,63 |
| 3 | Gate vs Policy | Controller `Gate::authorize('tenant.msh-*')` vs Request authorize | **SEC-MSH-003** — Requests authorize()=true; gating only in controller | 06,51,52 |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | OK (all persisted columns fillable) | 01 |
| 5 | Cast vs DDL | Model `$casts` vs DDL type | OK (decimal:2/bool/integer match) | 05 |
| 6 | Service delegation | Controller `store()` vs Service `create()` | **BR-MSH-050** — store() bypasses `TemplateScholasticComponentService::create()`, so `validateScholasticWeightageSum()` never runs on create | 16 |
| 7 | State machine vs impl | Screen (no FSM) vs controller | N/A — no workflow beyond is_active toggle | 90 |
| 8 | Validation vs Request | Screen sum=100 rule vs `rules()` | **BR-MSH-050/009/012** — no sum rule in any FormRequest | 16,17 |
| 9 | Error message vs Request | expected vs `messages()`/closures | OK — scholastic duplicate message exact | 35 |
| 10 | Permissions vs Gates | Screen permission matrix vs `Gate::authorize` | **D39-MSH** — permission strings correct but unseeded (env) | 06,52 |
| 11 | Integration FK vs migration | Screen FKs vs migration `foreign()` | OK — CASCADE (config_template) + RESTRICT (source/exam_type/ia_type) present | 44,45 |
| 12 | Exam sum validator caller | `MarksheetConfigService::validateExamWeightageSum` vs callers | **BR-MSH-009/012** — dead code, zero callers | 17,18 |
| 13 | Error surface | Update sum break → exception handling | **DEV-MSH-C03** — DomainException uncaught → HTTP 500, not 422 | 80 |

---

## 4. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-FR` / weightage sum) | 3 | 3 | 100% |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | N/A (no FSM) |
| Validation Rules (`Screen-VR` / Request rules) | 8 | 8 | 100% |
| Integration Points (`Screen-IP` / FKs) | 2 | 2 | 100% |
| Permissions (`Screen-PM`) | 4 | 4 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No item at 0 coverage.

---

## 5. Owned defect register (this screen)

| ID | Severity | Title | Proving test | Current behaviour |
|----|----------|-------|--------------|-------------------|
| BR-MSH-050 | P2 | Scholastic weightage sum not validated at create | 16 | 40+40=80 accepted |
| BR-MSH-009 | P1 | Exam weightage sum not enforced | 17,18 | non-100 accepted; validator dead |
| BR-MSH-012 | P1 | Component weightage integrity gap (config side) | 16,17 | sum≠100 persists |
| SEC-MSH-003 | P1 | FormRequest authorize() returns true (no request gating) | 06,51 | confirmed |
| D39-MSH | P1 | Component permissions unseeded (env) | 06,52 | seeded defensively |
| DEV-MSH-C03 | P2 (discovered) | Update sum break → HTTP 500 not 422 | 80 | 500 + rollback |
| DEV-MSH-C04 | P3 (discovered) | grading_scale lacks `in:` enum | 72 | arbitrary value accepted |

> **Scope note:** this screen owns the **config-side** of the weightage-sum finding. The **compute-side** (marksheet computation ignoring a non-100 sum) belongs to the SchedulingAndLifecycle screen.
