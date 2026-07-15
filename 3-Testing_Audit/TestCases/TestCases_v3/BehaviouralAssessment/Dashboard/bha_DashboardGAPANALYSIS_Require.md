# Behavioural Assessment — Dashboard — Gap Analysis & Coverage

**Feature:** Dashboard · **Test file:** `bha_Dashboard_TestCas.php` (37 methods) · **Type:** LIGHT / read-focused
**Prefix note:** filename `bha_`; assertions target live `ba_` tables (DOC-BA-001).

---

## 1. Manual TC ↔ Dusk method mapping

### Render / KPI / widgets
| Manual TC | Dusk method | Coverage |
|-----------|-------------|----------|
| MT-01 (render) | `test_dashboard_10` | Full |
| MT-02 KPI Total Assessments | `test_dashboard_11` | Full |
| MT-02 KPI Total Incidents | `test_dashboard_12` (seeds +1) | Full |
| MT-02 KPI Open Periods | `test_dashboard_13` | Full |
| MT-02 KPI Students Assessed | `test_dashboard_14` | Full |
| MT-03 Recent Incidents (surface) | `test_dashboard_15` | Full |
| MT-03 Recent Incidents (order/limit) | `test_dashboard_16` | Full (source-verified) |
| MT-04 charts present | `test_dashboard_17/18/19` | Full |
| MT-04 empty chart placeholder | `test_dashboard_62` (data-conditional) | Partial (env-dependent) |

### State-machine / period scoping
| Manual TC | Dusk method | Coverage |
|-----------|-------------|----------|
| MT-05 latest locked period name | `test_dashboard_20` | Full |
| MT-05 bottom-5 derivation | `test_dashboard_21` (source-verified) | Full |
| MT-05 revert to empty state | `test_dashboard_63` | Full (data-conditional) |
| period status enum | `test_dashboard_22` | Full |

### Permissions
| Manual TC | Dusk method | Coverage |
|-----------|-------------|----------|
| MT-07 guest redirect | `test_dashboard_50` | Full |
| MT-08 limited user 403 | `test_dashboard_51` | Full |
| MT-08 admin 200 | `test_dashboard_53` | Full |
| gate string enforced | `test_dashboard_52` | Full |
| policy maps abilities | `test_dashboard_04` | Full |

### UI / robustness / edge / security
| Manual TC | Dusk method | Coverage |
|-----------|-------------|----------|
| MT-06 quick links | `test_dashboard_60` | Full |
| MT-06 view-all link | `test_dashboard_61` | Full |
| MT-09 junk params | `test_dashboard_30` | Full |
| MT-10 no crash without locked period | `test_dashboard_70` | Full |
| MT-10 empty incidents placeholder | `test_dashboard_62` | Partial (env-dependent skip) |
| MT-10 attention card hidden | `test_dashboard_63` | Partial (env-dependent skip) |
| MT-11 stored XSS | `test_dashboard_93` | Full |
| MT-12 gaps | `test_dashboard_31/71/92` | Full |

### Schema / route / integration / tenancy
| Manual TC | Dusk method | Coverage |
|-----------|-------------|----------|
| tables/columns | `test_dashboard_01` | Full |
| ba_ vs bha_ | `test_dashboard_02` | Full |
| route + controller | `test_dashboard_03` | Full |
| trend aggregation | `test_dashboard_40` | Full (source-verified) |
| computed_score FK | `test_dashboard_41` | Full |
| bottom-student join | `test_dashboard_42` | Full (defensive) |
| tenant init | `test_dashboard_90` | Full |
| cross-tenant | `test_dashboard_91` | Partial (single-tenant skip) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|:--------:|:----:|:-------:|:---:|:------:|
| Positive / Render / Widget | 17 | 15 | 2 | 0 | 88% |
| Negative / Robustness / Empty | 7 | 5 | 2 | 0 | 71% (100% incl. partial) |
| Dependency / Integration | 2 | 2 | 0 | 0 | 100% |
| Config / Schema / Route / Gate | 6 | 6 | 0 | 0 | 100% |
| Gap-proving | 3 | 3 | 0 | 0 | 100% |
| Tenancy / Security | 3 | 2 | 1 | 0 | 67% (100% incl. partial) |
| **Total** | **38** | **33** | **5** | **0** | **87% Full / 100% incl. partial** |

**Partial-coverage items (all are environment-conditional, not logic gaps):**
- `test_dashboard_62` / `_63` — empty-state assertions self-skip when the tenant already has incidents / locked scores (non-destructive design; validated on a clean tenant).
- `test_dashboard_91` — cross-tenant IDOR needs a second tenant domain; self-skips otherwise.
- `test_dashboard_04`/`_16`/`_20`/`_21`/`_31`/`_40`/`_52`/`_71`/`_72`/`_92` use app-repo source reads (constraint #29/#32); self-skip if the source file is unreadable in a partial checkout.

> Read/dashboard screen targets met: **no create/edit/delete matrix required**; render + widget/aggregate correctness + permissions + empty-state all covered. Negative-class robustness (auth 403, guest redirect, junk-param, XSS) = 100%.

---

## 3. Coverage-Score by requirement source (WP-F)

| Section | Covered | Total | % |
|---------|:-------:|:-----:|:-:|
| Business Rules (`Screen-BR`: KPIs, trend, category avg, recent incidents, attention list, quick links) | 6 | 6 | 100% |
| State-Machine / period scoping (`Screen-SM`: locked-period selection, conditional cards) | 3 | 3 | 100% |
| Validation Rules (`Screen-VR`) | n/a | 0 | — (read-only screen, no write validation) |
| Integration Points (`Screen-IP`: std_students, ba_computed_scores, ba_rating_levels) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: viewAny gate, guest, limited, admin) | 4 | 4 | 100% |
| Requirement widgets NOT implemented (documented gaps) | 4 | 4 | 100% (proven as gaps) |

Every `Source`-tagged requirement item maps to ≥1 TC. Requirement widgets that the implementation omits
(role scope, "Assessments Completed %", "Active Interventions", severity=critical styling, counsellor alert list,
deadline banner) are captured as **DASH-GAP** findings with proving tests rather than left as silent gaps.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Test | Status |
|---|-------|---------|---------|------|--------|
| 1 | Enum case | DDL `severity ENUM('critical','major','minor','moderate')` vs blade branches | Blade maps only major/moderate/minor; `critical` → em-dash | `test_dashboard_71` | **DASH-GAP-04 (verified)** |
| 2 | Route registration | Blade `route('behavioural-assessment.*')` vs `routes/web.php` + RouteServiceProvider | All quick-link + dashboard routes registered under `behavioural-assessment.` name/prefix | `test_dashboard_03/60` | OK |
| 3 | Gate vs Policy | Controller `Gate::authorize('...dashboard.viewAny')` vs `BaDashboardPolicy` | Gate string + policy method both present; `view` ability declared but unused by any action | `test_dashboard_04/52` | OK (minor: unused `view`) |
| 4 | Fillable vs DDL | n/a (read-only screen; no writes) | — | — | n/a |
| 5 | Cast vs DDL | `numeric_score` decimal(5,2) vs model cast `decimal:5,2` | Consistent | `test_dashboard_41` | OK |
| 6 | Service delegation | `index()` body vs `BehaviouralScoreService` | Dashboard aggregates inline in controller (no service delegation) — acceptable for read-only; note PERF-BA N+1 risk on other actions | source | OK (note) |
| 7 | State machine vs impl | Requirement "active period near deadline banner" vs controller | Deadline warning banner NOT implemented (requirement §Workflow 4) | `test_dashboard_92` (KPI divergence) | **DASH-GAP-01 (verified)** |
| 8 | Validation vs FormRequest | n/a (no FormRequest) | Read-only screen | — | n/a |
| 9 | Error message vs FormRequest | n/a | — | — | n/a |
| 10 | Permissions vs Policy/Gates | Requirement role scope (Admin/Counsellor/Teacher) vs controller | No role-scoped data; single `viewAny` gate for all | `test_dashboard_31` | **DASH-GAP-03 (verified)** |
| 11 | Integration FK vs migration | Requirement "aggregates from `ba_computed_scores`" vs controller | Controller reads `ba_computed_scores`/`std_students` with real FKs; matches | `test_dashboard_41/42` | OK |

**Verified findings (feature-scoped, proven by tests):**
- **DASH-GAP-01** — implemented KPI set diverges from the requirement's four KPI cards + no deadline banner. (`_92`)
- **DASH-GAP-02** — no server-side filters/drilldowns; query params ignored. (`_30`)
- **DASH-GAP-03** — role-based data visibility not implemented (school-wide for all viewers). (`_31`)
- **DASH-GAP-04** — `severity='critical'` unmapped in the Recent-Incidents blade. (`_71`)
- **DOC-BA-001** (inherited) — DDL doc `bha_` vs live `ba_`. (`_02`)

**Not asserted as defects (candidates, verify in source before filing):** the requirement's "Counsellor Alert List"
(students with >3 infractions in 30 days) and the "Active Interventions" KPI are absent from `index()` — treated as
scope-not-built (DASH-GAP-01 umbrella), not regressions.

---

## 5. Legend
- **Full** — behaviour or source fact directly asserted.
- **Partial** — asserted but self-skips in constrained environments (single tenant / already-populated tenant / partial source checkout); not a logic gap.
- **Gap** — no coverage (none in this suite).
- **DASH-GAP-##** — feature-scoped requirement-vs-implementation divergence, asserted against ACTUAL behaviour.
