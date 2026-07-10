# MarksheetGeneration — Dashboard & Navigation — Gap Analysis

**Feature:** Dashboard & Navigation (read-focused / composite) · **Prefix:** `msh_`
**V1:** 17 methods · **V2:** 44 methods · **Ratio:** 2.59× (≥ 2× PASS)
**Style:** browser Dusk · **DB scope:** tenant-side

Read-focused screen → coverage is measured on render / navigation / aggregation / permission / empty-state / console / responsive dimensions (no create/edit/delete matrix).

---

## 1. Manual TC ↔ Dusk method mapping

### Render / Aggregation
| Manual TC | V1 method | V2 method(s) | Coverage |
|-----------|-----------|--------------|----------|
| TC-P01 Dashboard renders + breadcrumb | test_03 | test_10, test_60 | Full |
| TC-P02 Six stat cards | test_04 | test_11 | Full |
| TC-P03 Values match DB counts | test_05 | test_12, test_47 | Full |
| TC-P04 Active/Inactive breakdown | — | test_13 | Full |
| TC-P05 Recent-activity tabs | test_06 | test_14 | Full |
| TC-P13 Date badge | test_16 | test_17 | Full |
| TC-P14 Header + Live | — | test_18 | Full |
| TC-P15 Overview active | — | test_61 | Full |
| BC-BIZ-04/05 recent capped at 5 | — | test_15, test_16 | Full |

### Navigation
| Manual TC | V1 method | V2 method(s) | Coverage |
|-----------|-----------|--------------|----------|
| TC-P06 4-pillar links | test_07 | test_40 | Full |
| TC-P07 Configuration resolves | test_08 | test_41 | Full |
| TC-P08 Components resolves | test_09 | test_42 | Full |
| TC-P09 Scheduling resolves | test_10 | test_43 | Full |
| TC-P10 Results resolves | test_11 | test_44, test_46 | Full |
| TC-P16 View-all / empty CTAs | — | test_64, test_65 | Full |

### Permissions / Auth / Dead-API
| Manual TC | V1 method | V2 method(s) | Coverage |
|-----------|-----------|--------------|----------|
| TC-N01 Guest redirect (dashboard) | test_12 | test_50 | Full |
| TC-N02 Guest redirect (combined) | — | test_51 | Full |
| TC-N03..N07 Gate denial (D39) | — | test_52–56 | Full (defensive skip if super-admin bypass) |
| BC-AUTH gate strings | test_01, test_16 | test_57 | Full |
| TC-N08 API routes unregistered | test_13 | test_58 | Full |
| TC-N09 Controller missing methods | test_13 | test_59 | Full |
| TC-N10 API getJson dead status | test_13 | test_72 | Full |

### Empty-state / Edge / Integration / Enhanced
| Manual TC | V1 method | V2 method(s) | Coverage |
|-----------|-----------|--------------|----------|
| TC-P11 Schedules table/empty | test_14 | test_62, test_70 | Full |
| TC-P12 Results table/empty | test_15 | test_63, test_71 | Full |
| TC-D01 Cross-module eager load | — | test_45 | Full (defensive) |
| TC-D02 Counts non-negative | — | test_47 | Full |
| TC-D03 Results unbounded (PERF-MSH-003) | test_11 | test_46 | Full (proving) |
| TC-T01 Tenant-scoped counts | — | test_90 | Partial (smoke; no 2nd-tenant fixture) |
| TC-A01 Console (dashboard) | test_17 | test_91 | Full |
| TC-A02 Console (combined) | — | test_93 | Full |
| TC-RSP01 Mobile viewport | — | test_92 | Full |
| Wiring (routes/views/tables) | test_01, test_02 | test_01–04 | Full |

---

## 2. Coverage Summary
| Dimension | Total TC | Full | Partial | Gap | % Full |
|-----------|----------|------|---------|-----|--------|
| Positive (render/nav/aggregation) | 16 | 16 | 0 | 0 | 100% |
| Negative / Auth / Dead-API | 10 | 10 | 0 | 0 | 100% |
| Dependency / Integration | 3 | 3 | 0 | 0 | 100% |
| Empty-state / Edge | 2 | 2 | 0 | 0 | 100% |
| Tenancy / Console / Responsive | 4 | 3 | 1 | 0 | 75% |
| **Total** | **35** | **34** | **1** | **0** | **97%** |

Targets: Negative 100% ✅ · Positive ≥ 90% (100%) ✅ · Dependency ≥ 90% (100%) ✅.

### Remaining partial coverage
- **TC-T01** — tenant isolation is a single-tenant smoke (counts ≥ 0 under the initialized tenant). A true cross-tenant invisibility test needs a second seeded tenant; deferred as an enhancement (dashboard is read-only, low IDOR surface).

---

## 3. Coverage-Score (by requirement Source tag)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-FR-01/03`, BC-BIZ) | 7 | 7 | 100% |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | N/A (no workflow) |
| Validation Rules (`Screen-VR`) | 0 | 0 | N/A (read-only) |
| Integration Points (BC-INT) | 3 | 3 | 100% |
| Permissions (`Screen-PM`, BC-AUTH) | 6 | 6 | 100% |
| Edge/Empty-state (BC-EDG) | 2 | 2 | 100% |

Every `Source`-tagged requirement item has ≥ 1 TC. No zero-coverage items.

---

## 4. Cross-Reference Findings (source-defect scan)

| # | Check | Compared | Finding | Status |
|---|-------|----------|---------|--------|
| 2 | Route registration | `routes/api.php` apiResource vs `RouteServiceProvider::map()` | **map() only calls `mapWebRoutes()`** — module `api.php` is never loaded, so `marksheetgeneration.*` API routes are unregistered | **BUG-MSH-001 (P0) — confirmed** |
| 3 | Gate vs Policy | controller `Gate::authorize('tenant.msh-*.view')` vs seeded permissions | Gate strings valid; permissions **unseeded** (super-admin-only) | **D39-MSH (P1) — confirmed** |
| 6 | Service delegation | `results()` inline query vs a paginator/service | `Student::...->get()` + `Subject::...->get()` unbounded inline in the controller | **PERF-MSH-003 (P2) — confirmed** |
| 2b | Controller method presence | apiResource actions vs controller methods | Controller lacks `index/store/show/update/destroy` entirely | **BUG-MSH-001 (P0) — confirmed** |
| 1/5/8/9/11 | Enum/cast/validation/message/FK | — | N/A on a read-only dashboard (no FormRequest, no writes) | No finding |
| 7 | State machine vs impl | requirement vs controller | No workflow on this screen | No finding |
| 10 | Permissions vs matrix | Screen-PM vs `Gate::authorize` | Matches (5 gates) | OK |

### Defect register (this feature)
| ID | Severity | Description | Proving test | Doc'd in |
|----|----------|-------------|--------------|----------|
| **BUG-MSH-001** | **P0** | API resource for marksheetgenerations is dead: controller has no REST methods AND module api.php is never registered by `RouteServiceProvider::map()`. | V1 test_13; V2 test_58/59/72 | Gap + Validation |
| **PERF-MSH-003** | P2 | `results()` unbounded `Student::get()` / `Subject::get()` (no pagination). | V1 test_11; V2 test_46 | Gap + Validation |
| **D39-MSH** | P1 | msh permissions unseeded (super-admin-only) — env prereq; gates granted explicitly in tests. | V2 test_52–56 | Gap + Validation |

**New candidates (verify in source):** none beyond the three above — the dashboard/combined controller surface is otherwise consistent (routes registered, views exist, gate strings match `MsgMenuController` permission keys pattern `tenant.msh-*`).

---

## 5. Legend
- **Full** — automated assertion(s) cover the manual expectation.
- **Partial** — covered by a smoke/defensive assertion; a deeper fixture would strengthen it.
- **Gap** — no automated coverage.
- **Proving test** — asserts *current (defective)* behaviour so the defect is detected if it regresses/changes.
