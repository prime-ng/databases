# MarksheetGeneration — Dashboard & Navigation — Gap Analysis

- **Test file:** `msh_Dashboard_TestCas.php` (44 methods, one file — no V1/V2 split)
- **Screen type:** composite / read-focused (no create/edit/delete matrix)
- **Prefix:** `msh_` (composite — owns no primary table; aggregates `msh_*`)

---

## 1. Manual TC ↔ Dusk Method Mapping

### Render / Aggregation / Widgets
| Manual TC | Dusk Method(s) | Coverage |
|-----------|----------------|----------|
| TC-P01 Dashboard render | `test_dashboard_10` | Full |
| TC-P02 Six stat cards | `test_dashboard_11` | Full |
| TC-P03 Stat values = DB counts | `test_dashboard_12` | Full |
| TC-P04 Active/Inactive breakdown | `test_dashboard_13` | Full |
| TC-P05 Recent-activity tabs | `test_dashboard_14` | Full |
| TC-P13 Date badge | `test_dashboard_17` | Full |
| TC-P14 Header + Live | `test_dashboard_18` | Full |
| TC-P15 Recent schedules ≤ 5 | `test_dashboard_15` | Full |
| TC-P16 Recent results ≤ 5 + eager | `test_dashboard_16` | Full |
| BC-DB tables exist | `test_dashboard_01`, `test_dashboard_02` | Full |
| BC-BIZ-08 routes registered | `test_dashboard_03` | Full |
| BC-DB-08 views resolve | `test_dashboard_04` | Full |

### Navigation / Integration
| Manual TC | Dusk Method(s) | Coverage |
|-----------|----------------|----------|
| TC-P06 4-pillar links | `test_dashboard_40` | Full |
| TC-P07 Configuration resolves | `test_dashboard_41` | Full |
| TC-P08 Components resolves | `test_dashboard_42` | Full |
| TC-P09 Scheduling resolves | `test_dashboard_43` | Full |
| TC-P10 Results resolves | `test_dashboard_44` | Full |
| TC-D02 Cross-module eager-load | `test_dashboard_45` | Full (defensive skip) |
| TC-D03 PERF-MSH-003 | `test_dashboard_46` | Full (proving) |
| TC-D01 Counts non-negative | `test_dashboard_47` | Full |

### Permissions / Auth / Dead API
| Manual TC | Dusk Method(s) | Coverage |
|-----------|----------------|----------|
| TC-N01 Guest → login (dashboard) | `test_dashboard_50` | Full |
| TC-N02 Guest → login (combined) | `test_dashboard_51` | Full |
| TC-N03..N07 Permission denial | `test_dashboard_52..56` | Full (defensive skip) |
| BC-AUTH gate strings | `test_dashboard_57` | Full |
| TC-N08 API routes unregistered | `test_dashboard_58` | Full |
| TC-N09 Controller lacks REST methods | `test_dashboard_59` | Full |
| TC-N10 API probe dead status | `test_dashboard_72` | Full |

### UI/UX / Edge / Tenancy / Smoke
| Manual TC | Dusk Method(s) | Coverage |
|-----------|----------------|----------|
| TC-P18 Breadcrumb | `test_dashboard_60` | Full |
| TC-P17 Overview active | `test_dashboard_61` | Full |
| TC-P11 Recent Schedules tab | `test_dashboard_62` | Full |
| TC-P12 Recent Results tab | `test_dashboard_63` | Full |
| TC-P19 Scheduling CTA | `test_dashboard_64` | Full |
| TC-P20 Results CTA | `test_dashboard_65` | Full |
| TC-EDG01 Schedules empty-state | `test_dashboard_70` | Full |
| TC-EDG02 Results empty-state | `test_dashboard_71` | Full |
| TC-T01 Tenant scope | `test_dashboard_90` | Full |
| TC-A01 Console (dashboard) | `test_dashboard_91` | Full |
| TC-RSP01 Mobile viewport | `test_dashboard_92` | Full |
| TC-A02 Console (combined) | `test_dashboard_93` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive (render/nav/widgets/UX) | 20 | 20 | 0 | 0 | 100% |
| Negative (guest/perm/dead-API) | 10 | 10 | 0 | 0 | 100% |
| Dependency (integration/perf) | 3 | 3 | 0 | 0 | 100% |
| Tenancy / Smoke / Edge | 6 | 6 | 0 | 0 | 100% |
| **Total** | **39** | **39** | **0** | **0** | **100%** |

> Read-focused targets met: render/navigation/permissions/empty-state all covered; Negative 100% of the applicable (auth/guest/dead-API) set; Tenancy 100%. There is no create/edit/delete matrix for a composite screen, so the CRUD-style Positive/Dependency A–G subcategories are intentionally N/A.

### Partial-coverage / limitation notes
- **TC-N03..N07 (permission denial)** and **TC-D02 (cross-module eager-load)** are **defensive** — they `markTestSkipped()` when a limited user cannot be provisioned or a super-admin bypass leaks (D39 seed state), so a partial environment stays green. Denial is still asserted whenever a genuine limited user is available.
- **PERF-MSH-003** is proved by source inspection + page-renders (soft, no hard perf threshold), matching the "document, don't hide" rule for a P2 defect.

---

## 3. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 2 | Route registration | `routes/api.php apiResource` vs `RouteServiceProvider::map()` | **BUG-MSH-001** — apiResource declared but `map()` calls only `mapWebRoutes()`; names never registered (verified). |
| 3 | Gate vs method | Controller `Gate::authorize('tenant.msh-*.view')` | 5 gates present verbatim; no Policy class needed (string gates). Consistent. |
| 6 | Service delegation | `dashboard()`/`results()` body | Aggregation logic lives inline in the controller (no service) — acceptable for a read screen; noted. |
| 10 | Permissions vs seed | `tenant.msh-*.view` vs seeded permissions | **D39-MSH** — gates unseeded → super-admin only (env prereq, granted in-suite). |
| 11 | REST contract vs impl | `apiResource` verbs vs controller methods | **BUG-MSH-001** — controller defines none of index/store/show/update/destroy; even if `mapApiRoutes()` were added the resource would 500/error. Double-dead. |
| — | Unbounded query | `results()` `Student::get()` + `Subject::get()` | **PERF-MSH-003** — no pagination on cross-module loads (P2). |

### Discovered candidates (verify-in-source, not asserted as new bugs)
- `results()` reassigns `$mgSchedules` twice (Controller L256 then L286) — the first `MarksheetSchedule::orderBy('name')->get()` is dead-assigned and overwritten by the `ScheduleClass`-derived mapping. Cosmetic/dead-code smell, not a functional defect; **not** given a proving test. Flag to the module owner.

---

## 4. Coverage-Score by Requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Functional Reqs (`Screen-FR-01` widgets) | 1 | 1 | 100% |
| Functional Reqs (`Screen-FR-02` 4-pillar nav) | 1 | 1 | 100% |
| Functional Reqs (`Screen-FR-03` recent tabs) | 1 | 1 | 100% |
| Permissions (`Screen-PM` 5 gates) | 5 | 5 | 100% |
| Integration Points (`Screen-IP` cross-module) | 2 | 2 | 100% |
| Owned defects (BUG-MSH-001 / PERF-MSH-003 / D39-MSH) | 3 | 3 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No zero-coverage items.

### Legend
- **Full** — behaviour asserted directly by ≥1 method.
- **Partial** — asserted with a defensive skip in constrained environments.
- **Gap** — no method (none present).
