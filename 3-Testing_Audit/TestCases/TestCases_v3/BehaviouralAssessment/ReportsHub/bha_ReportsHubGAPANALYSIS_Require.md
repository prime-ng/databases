# Reports Hub — Gap Analysis (`bha_ReportsHub`)

**Feature:** ReportsHub · **Type:** REPORT/navigation hub (LIGHT depth) · **Test file:** `bha_ReportsHub_TestCas.php` · **Methods:** 27

Coverage targets for a read-focused report screen: render/links Full, permission gating 100% of gated paths, empty-state covered, known defects proven. No CRUD/negative-validation matrix applies (the hub takes no user input).

---

## 1. Manual TC ↔ Dusk method mapping

### Render / composition
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MT-01 hub render | `_10`,`_11`,`_12`,`_13` | Full |
| MT-05 trend empty-state | `_60` | Full |
| MT-05 sub-report breadcrumbs | `_61` | Full |

### Links / integration
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MT-02 incidents link+target | `_40` | Full |
| MT-02 categories link+target | `_41` | Full |
| MT-02 period target | `_42` | Full (defensive skip if no period) |
| MT-02 reports-page legacy | `_43` | Full |
| MT-02 student/class routes + tab | `_44` | Full |

### Permissions
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MT-03 guest redirect | `_50` | Full |
| MT-03 no viewAny → 403 hub | `_51` | Full |
| MT-03 no view → 403 incidents | `_52` | Full |
| MT-03 policy strings | `_53` | Full |
| MT-03 export gated before 501 | `_54` | Full |

### Edge / defects
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MT-04 invalid id 404 | `_70` | Full |
| MT-04 export 501 stub (BUG-BA-011) | `_45`,`_71` | Full |
| MT-04 dead api route (DEAD-BA-001) | `_46` | Full |
| MT-05 reflected XSS escaped | `_92` | Full |

### Requirement gaps / config
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MT-06 filter panel absent (HUB-GAP-01/03) | `_80` | Full |
| MT-06 synced label absent (HUB-GAP-02) | `_81` | Full |

### Tenancy
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| MT-07 tenant init | `_90` | Full |
| MT-07 cross-tenant isolation | `_91` | Partial (defensive; needs 2nd tenant) |

### Config truth
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| Schema+route+gate config | `_01` | Full |
| Prefix divergence DOC-BA-001 | `_02` | Full |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|---------|------|---------|-----|--------|
| Positive (render/links/tenancy) | 14 | 13 | 1 (`_91`) | 0 | 93% |
| Negative (auth/edge/defect/security) | 12 | 12 | 0 | 0 | 100% |
| Dependency/Tenancy | 1 | 0 | 1 | 0 | Partial (defensive) |
| **Overall** | **27** | **25** | **2** | **0** | **93%** |

- Negative coverage: **100%** (all gated paths, edge 404s, both defects, reflected XSS).
- No coverage gaps. The two partials are intentional defensive skips (`_42` needs a period row; `_91` needs a second tenant).

---

## 3. Coverage-Score (by requirement Source tag)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules — render/composition (Screen-BR) | 5 | 5 | 100% |
| Integration Points — report links (Screen-IP-1..5) | 5 | 5 | 100% |
| Permissions (Screen-PM: reports.viewAny/view/export + reports-page) | 4 | 4 | 100% |
| Requirement features NOT implemented (Screen filter panel / export / freshness) | 3 | 3 | 100% (proven ABSENT) |
| State-Machine (Screen-SM) | — | 0 | N/A (no workflow on hub) |

Every Source-tagged requirement item has ≥1 TC. The requirement's export/filter/queue features are covered as **proven-absent** gap tests, not as functional coverage.

---

## 4. Cross-Reference Defect Scan (11-check)
| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | — | N/A (hub has no enum inputs) |
| 2 | Route registration | Blade `route()` vs `routes/*.php` + RSP | **DEAD-BA-001** — `routes/api.php` apiResource never registered (RSP maps web only). Firing → `_46`. |
| 3 | Gate vs Policy | `Gate::authorize('tenant….reports.viewAny')` vs `BaReportPolicy` | Consistent — controller uses full permission strings; policy methods delegate to the same `can()` strings. No defect. `_01`,`_53` |
| 4 | Fillable vs DDL | — | N/A (read-only) |
| 5 | Cast vs DDL | — | N/A |
| 6 | Service delegation | controller body vs Service | No BehaviouralScoreService delegation on the hub (all inline aggregate queries). Note only. |
| 7 | State machine vs impl | — | N/A |
| 8 | Validation vs FormRequest | — | N/A (no FormRequest — hub takes no input) |
| 9 | Error message vs FormRequest | — | N/A |
| 10 | Permissions vs Policy/Gates | requirement RBAC (Teacher-restricted cohorts) vs impl | **REQ-GAP** — requirement's role-based cohort restriction (teachers see only their sections) is NOT enforced on the hub; only coarse view/viewAny gates exist. Documented, not asserted (no cohort scoping surface on the hub itself). |
| 11 | Integration FK vs migration | requirement FKs (org_academic_sessions, ba_assessment_periods) vs schema | Backing tables exist and resolve; `_01` asserts presence. No FK defect on the hub. |

### Confirmed defects (proven by tests)
| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| BUG-BA-011 | High | `reports.export` is a live `abort(501)` stub — the requirement's core CSV/Excel export engine does not exist | `_45`, `_71` |
| DEAD-BA-001 | Medium | Module `routes/api.php` apiResource has no tenancy middleware AND is unregistered (web-only `map()`) → dead route | `_46` |
| DOC-BA-001 | Doc | DDL doc prefix `bha_` vs live `ba_` | `_02` |

### Requirement-vs-implementation gaps (proven ABSENT)
| ID | Description | Proving test |
|----|-------------|--------------|
| HUB-GAP-01/03 | Filter panel (Session/Period/Class/Section/Format radio), Generate Preview, Export Report, >1000-row async-queue banner — none implemented | `_80` |
| HUB-GAP-02 | "Data last synced" freshness label absent | `_81` |
| HUB-GAP-04 (note) | Requirement "Available Reports Menu" (Student Scores/Category Summary/Period Report/Audit Trail/Incident Summary) only partially matches the actual cards; Audit Trail lives behind the legacy `reports-page` tab | documented (not asserted) |

---

## 5. Legend
Full = behaviour asserted end-to-end. Partial = asserted with a defensive skip when an optional dependency (period row / second tenant) is absent. Gap = no automated coverage (none here).
