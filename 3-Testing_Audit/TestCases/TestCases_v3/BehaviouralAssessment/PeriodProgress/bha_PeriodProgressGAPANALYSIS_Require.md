# bha_PeriodProgress — Gap Analysis & Coverage

**Feature:** PeriodProgress (screen 22 — Longitudinal Trend Dashboard) · **Test file:** `bha_PeriodProgress_TestCas.php` (26 methods)
**Screen type:** Report / data-viz — LIGHT / read-focused. **Primary finding:** the screen is specified-but-unbuilt (RPT-GAP-PROG-01).

---

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Description | Method(s) | Coverage |
|-----------|-------------|-----------|----------|
| TC-P01 | Computed-scores schema/model truth | `_01` | Full |
| TC-P02 | Runtime prefix vs DDL doc (DOC-BA-001) | `_02` | Full |
| TC-P03 | Hub renders for admin | `_10` | Full |
| TC-P04 | Nearest computed-scores surface renders | `_12` | Full |
| TC-P05 | Trend source + axis keys present | `_13` | Full |
| TC-P06 | Computed-scores FKs RESTRICT | `_40` | Full |
| TC-P07 | Unique (student,category,period) key | `_41` | Full |
| TC-P08 | Policy maps permission strings | `_52` | Full |
| TC-P09 | Tenant context initialized | `_90` | Full |
| TC-P10 | Web routes carry tenancy stack | `_92` | Full |
| TC-N01 | `/reports/progress` → 404 | `_30` | Full |
| TC-N02 | Invalid student id → 404 | `_31` | Full |
| TC-N03 | Guest → login | `_50` | Full |
| TC-N04 | Limited user → 403 | `_51` | Full |
| TC-N05 | Output escaping smoke | `_93` | Full |
| TC-D01 | No progress() action | `_03` | Full |
| TC-D02 | No progress route | `_04` | Full |
| TC-D03 | No progress view / widgets | `_05` | Full |
| TC-D04 | Hub does not link progress | `_11` | Full |
| TC-D05 | Export = 501 stub (BUG-BA-011) | `_70` | Full |
| TC-D06 | Trend widgets unimplemented (source) | `_71` | Full |
| TC-D07 | Deterministic BUG-BA-013 (0.00) | `_72` | Full |
| TC-D08 | Source BUG-BA-013 + student() contrast | `_73` | Full |
| TC-D09 | Multi-line/interpolation/KPI rules absent | `_74` | Full |
| TC-D10 | api resource dead + no tenancy (DEAD-BA-001) | `_91` | Full |
| TC-D11 | Export gate divergence (VAL-BA-003) | `_53` | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % |
|----------|-------|------|---------|-----|---|
| Positive | 10 | 10 | 0 | 0 | 100% |
| Negative | 5 | 5 | 0 | 0 | 100% |
| Dependency / Defect | 11 | 11 | 0 | 0 | 100% |
| **Overall** | **26** | **26** | **0** | **0** | **100%** |

Gates: Negative 100% ✅ · Positive ≥ 90% ✅ (100%) · Dependency ≥ 90% ✅ (100%) · Tenancy 100% ✅.

> **Note on "coverage" for an unbuilt screen.** Because the screen has no route/view/controller action, the
> positive matrix is intentionally read/config/data-source oriented (schema truth of the specified data source,
> nearest implemented surface render, permission plumbing, tenancy). The functional trend-dashboard behaviours
> (trend-line render, milestone tooltips, KPI deltas) are un-testable-because-unimplemented and are recorded as
> requirement gaps (RPT-GAP-PROG-01/02), not as automation gaps.

---

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % | Notes |
|---------|---------|-------|---|-------|
| Business Rules (`Screen-BR`) | 2 | 2 | 100% | Both proven UNIMPLEMENTED (`_74`): max-5 multi-line, continuous interpolation |
| Visual Widgets (`Screen-Widget`) | 3 | 3 | 100% | Trend line, milestone flags, KPI cards — all proven absent (`_05`,`_71`) |
| State-Machine (`Screen-SM`) | 0 | 0 | n/a | Read-only viz — no lifecycle (documented absence) |
| Validation (`Screen-VR`) | 2 | 2 | 100% | Missing-route 404 (`_30`), invalid-id 404 (`_31`) |
| Integration Points (`Screen-IP`) | 3 | 3 | 100% | 3 computed-scores FKs (`_40`); cross-module student surface (`_12`) |
| Permissions (`Screen-PM`) | 3 | 3 | 100% | viewAny/view/export gates, guest, limited-403 (`_50`–`_53`) |
| Data source (`Screen-DS`) | 1 | 1 | 100% | `ba_computed_scores` schema + axis keys (`_01`,`_13`) |

Every `Source`-tagged requirement item maps to ≥1 TC. Items with 0 implementation are covered by a proving-gap
test rather than a functional test (explicitly by design — see note above).

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | Proving method |
|---|-------|----------|---------|----------------|
| 1 | Enum case | ba_computed_scores has no ENUM feeding this screen | N/A | — |
| 2 | Route registration | Screen-22 URL vs `routes/web.php` + RSP | **RPT-GAP-PROG-02** — `reports/progress` never registered | `_04`,`_30` |
| 3 | Gate vs Policy | `export()` gate vs `BaReportPolicy::export` | **VAL-BA-003** — controller gates `reports.view`, policy declares `reports.export` | `_53` |
| 4 | Fillable vs DDL | `BaComputedScore::$fillable` vs `ba_computed_scores` | Match; **no `score`** fillable/column (BUG-BA-013 root) | `_01`,`_72` |
| 5 | Cast vs DDL | `numeric_score` decimal:5,2 / `overall_score` decimal:2 vs DDL | Consistent | `_01` |
| 6 | Service delegation | Report reads inline in controller (no service) | Consistent with siblings | `_73` |
| 7 | Requirement widgets vs impl | Screen-22 trend/milestone/KPI vs controller/view | **RPT-GAP-PROG-01** — zero implementation | `_03`,`_05`,`_71` |
| 8 | Aggregation column vs schema | `AVG(score)`/`avg('score')` vs live `numeric_score` | **BUG-BA-013** — categories() hard-500, byClass() 0.00; student() correct | `_72`,`_73` |
| 9 | Error/stub message | Export behaviour | **BUG-BA-011** — `abort(501)` stub on live route | `_70` |
| 10 | Permissions vs Policy/Gates | reports gate strings vs Policy | Consistent (`viewAny/view/export`) | `_52` |
| 11 | API tenancy vs middleware | `routes/api.php` vs RSP::map | **DEAD-BA-001** — apiResource no tenancy + unregistered | `_91` |

> All defect candidates were traced to current source before assertion. RPT-GAP-PROG-01/02 are requirement-vs-
> implementation gaps (whole screen missing); BUG-BA-013/011, DEAD-BA-001, VAL-BA-003, DOC-BA-001 are pre-existing
> module defects re-proven from the PeriodProgress vantage point.

---

## 5. Legend
- **Full** — behaviour asserted deterministically or via source-truth.
- **Gap (requirement)** — specified behaviour has no implementation to test; recorded as RPT-GAP-PROG-*.
- **Defect** — proven current-behaviour test locking in a source bug (BUG-/DEAD-/VAL-/DOC-BA-*).
