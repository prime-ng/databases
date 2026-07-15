# Incident Report — Gap Analysis & Coverage

**Feature:** IncidentReport · **Controller:** `BaReportController::incidents()` · **Test file:** `bha_IncidentReport_TestCas.php` (38 methods)
**Screen type:** Report (LIGHT, read-focused). No CRUD matrix — coverage targeted at render, aggregate correctness, filters, export, permissions, empty-state, tenancy, and requirement-vs-implementation gaps.

---

## 1. Manual TC ↔ Dusk Method Mapping

### Positive
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| TC-P01 schema/model | `_01` | Full |
| TC-P02 join tables | `_02` | Full |
| TC-P03 routes | `_03` | Full |
| TC-P04 view sections | `_04` | Full |
| TC-P05 filter set + defaults + paginate(25) | `_06`, `_63` | Full |
| TC-P06 authorized render | `_10` | Full |
| TC-P07 KPI cards | `_11` | Full |
| TC-P08 negative=total−positive | `_12` | Full |
| TC-P09 seeded data in log | `_13` | Full |
| TC-P10 analytics widgets | `_14` | Full |
| TC-P11 usage junction join | `_15` | Full |
| TC-P12 filter form | `_60` | Full |
| TC-P13 reset link | `_61` | Full |
| TC-P14 pagination | `_63` | Full |

### Negative
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| TC-N01 unknown category | `_30` | Full |
| TC-N02 garbage date | `_31` | Full (documents behaviour) |
| TC-N03 valid severity | `_32` | Full |
| TC-N04 valid type | `_33` | Full |
| TC-N05 guest redirect | `_50` | Full |
| TC-N06 limited 403 | `_51` | Full |
| TC-N07 empty state | `_62` | Full |

### Dependency / Tenancy / Security
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| TC-D01 incident FK | `_40` | Full |
| TC-D02 intervention junction FK | `_41` | Full |
| TC-D03 witness junction FK | `_42` | Full |
| TC-D04 policy strings | `_52` | Full |
| TC-D05 tenant context | `_90` | Full |
| TC-D06 web tenancy stack | `_92` | Full |
| TC-T01 DEAD-BA-001 | `_91` | Full |
| TC-S01 output escaping | `_93` | Full |

### Defects / Gaps
| Finding | Dusk method | Coverage |
|---------|-------------|----------|
| BUG-BA-011 export 501 | `_70` | Full |
| BUG-BA-013 N/A here | `_71` | Full (isolation proven) |
| DEAD-BA-001 | `_91` | Full |
| DOC-BA-001 | `_05` | Full |
| VAL-BA-003 | `_53` | Full |
| RPT-GAP-INC-01 | `_72` | Full |
| RPT-GAP-INC-02 | `_73` | Full |
| RPT-GAP-INC-03 | `_74` | Full |
| RPT-GAP-INC-04 | `_75` | Full |
| DOC-BA-006 | `_76` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 14 | 14 | 0 | 0 | 100% |
| Negative | 7 | 7 | 0 | 0 | 100% |
| Dependency | 6 | 6 | 0 | 0 | 100% |
| Security/Tenancy | 2 | 2 | 0 | 0 | 100% |
| Defects/Gaps | 10 | 10 | 0 | 0 | 100% |
| **Total** | **39** | **39** | **0** | **0** | **100%** |

Report-screen coverage gates (LIGHT): Negative 100% ✅ · Positive 100% (≥90% ✅) · Dependency 100% (≥90% ✅) · Tenancy 100% on P0/P1 ✅.

---

## 3. Coverage-Score (by requirement Source tag — Screen `24-Incident-Report.md`)

| Section | Covered | Total | % | Notes |
|---------|---------|-------|---|-------|
| Business Rules (Screen-BR: escalation link, export privacy) | 2 | 2 | 100% | Escalation join proven (`_15`); export privacy proven *unimplemented* (`_74`) |
| Filters (Screen-FR: date/type/severity/class/student) | 3 | 5 | 60% | date/type/severity covered (`_06/_32/_33/_60`); class & student **absent in impl** → gap proven (`_72`) |
| Analytics/Charts (Screen-CH: weekly line, success donut, top-3 bar) | 0 | 3 | 0% | Rendered as tables/monthly; gap proven (`_73`) — no chart to positively verify |
| Grid columns (Screen-GR: incl. Witness Count, Intervention Status) | 1 | 2 | 50% | Log grid + interventions proven (`_13/_15`); Witness Count absent (`_75`) |
| Permissions (Screen-PM: reports.view/export) | 2 | 2 | 100% | view gate enforced (`_51`); export ability divergence (`_53`) |
| Workflow (Screen-WF: generate report, filter drill-down) | 1 | 1 | 100% | Filter → render flow covered (`_06/_30/_62`) |

Every Source-tagged requirement item has ≥1 TC. Items scoring <100% are **implementation gaps**, not test gaps — each is proven by a dedicated failing-behaviour test (RPT-GAP-INC-01/02, RPT-GAP-INC-04). These are logged as defects, not coverage holes.

---

## 4. Cross-Reference Defect Scan (11 checks)

| # | Check | Compare | Finding | Verdict |
|---|-------|---------|---------|---------|
| 1 | Enum case | DDL ENUM vs blade `value=` | severity minor/moderate/major/critical match DDL & blade; incident_type matches | OK |
| 1b | Enum vocabulary | Screen-24 (Info/Low/Medium/High) vs DDL/blade | **DOC-BA-006** — requirement severity vocabulary diverges from live ENUM | Confirmed (`_76`) |
| 2 | Route registration | blade `route()` vs routes/web.php + RSP | `reports.incidents`/`reports.export` registered; **api `behaviouralassessment.*` never registered (RSP maps only web.php)** | DEAD-BA-001 (`_91`) |
| 3 | Gate vs Policy | controller `Gate::authorize` vs BaReportPolicy | incidents() gates `reports.view`; policy declares view/viewAny/export | OK / see #10 |
| 4 | Fillable vs DDL | BaIncident $fillable vs ba_incidents cols | fillable covers all report-read columns | OK |
| 5 | Cast vs DDL | model $casts vs DDL types | incident_date=date, is_*=boolean match TINYINT/DATE | OK |
| 6 | Service delegation | controller vs Service | report reads inline (no service) — acceptable for read-only aggregation | OK |
| 7 | State machine vs impl | n/a (report has no lifecycle) | — | N/A |
| 8 | Validation vs FormRequest | Screen-24 filters vs impl | **RPT-GAP-INC-01** — class/section + student filters absent | Confirmed (`_72`) |
| 9 | Error message | export message vs impl | `abort(501,'Export feature coming soon.')` verbatim | BUG-BA-011 (`_70`) |
| 10 | Permissions vs Policy | export gate vs policy `export` ability | **VAL-BA-003** — export() gates `reports.view`, not `reports.export` | Confirmed (`_53`) |
| 11 | Integration FK vs migration | Screen-24 escalation joins vs DDL FKs | ba_incidents RESTRICT/SET NULL + junctions CASCADE/RESTRICT verified | OK (`_40/_41/_42`) |
| + | Chart contract | Screen-24 charts vs blade | **RPT-GAP-INC-02** — charts are tables; trend monthly not weekly; no `<canvas>` | Confirmed (`_73`) |
| + | Grid contract | Screen-24 grid vs blade/controller | **RPT-GAP-INC-04** — Witness Count column absent (witnesses not loaded) | Confirmed (`_75`) |
| + | Privacy contract | Screen-24 export privacy vs impl | **RPT-GAP-INC-03** — no roll-number export / STUDENT-SHA anonymisation (501 stub) | Confirmed (`_74`) |
| + | Prefix drift | DDL `bha_` vs live `ba_` | **DOC-BA-001** — runtime uses `ba_` | Confirmed (`_05`) |
| + | BUG-BA-013 applicability | student/class report bug vs incidents() | Not applicable — incidents() never touches computed_scores/`score` | Documented N/A (`_71`) |

---

## 5. Legend
- **Full** — behaviour asserted directly (render, DB/FK metadata, source-contract, HTTP status).
- **Documented N/A** — a module-level defect verified as not firing on this screen (BUG-BA-013).
- Gap findings are **implementation** gaps proven by tests, not missing coverage.
