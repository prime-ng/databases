# Student Scores Report — Gap Analysis & Coverage

**Feature:** StudentScoresReport (screen 16) · **Module:** BehaviouralAssessment
**Test file:** `bha_StudentScoresReport_TestCas.php` — 33 methods · **Type:** Report (LIGHT, read-focused)

Legend: **Full** = TC fully automated · **Partial** = automated with an environmental/data caveat (defensive `markTestSkipped`) · **Gap** = not automated.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | Method(s) | Coverage | Note |
|-----------|-----------|----------|------|
| TC-P01 schema/model | `_01` | Full | |
| TC-P02 ba_ prefix / bha_ absent | `_02` | Full | |
| TC-P03 controller+routes | `_03` | Full | |
| TC-P04 views+partial exist | `_04` | Partial | source-read; skips if app repo unreadable |
| TC-P05 hub renders | `_10` | Full | |
| TC-P06 tab + filters render | `_11` | Full | |
| TC-P07 by-class grid | `_12` | Partial | needs a class-section; else skip |
| TC-P08 student report renders | `_13` | Partial | needs a student; else skip |
| TC-P09 student uses numeric_score | `_15` | Partial | source-read |
| TC-P10 tab reads assessments | `_41` | Partial | source-read |
| TC-P11 policy strings | `_54` | Partial | source-read |
| TC-P12 hub links to tab | `_62` | Full | |
| TC-P13 web tenancy stack | `_92` | Partial | source-read |
| TC-P14 tenant initialized | `_90` | Full | |

### Negative
| Manual TC | Method(s) | Coverage | Note |
|-----------|-----------|----------|------|
| TC-N01 unknown student → 404 | `_30` | Full | |
| TC-N02 unknown class-section → 404 | `_31` | Full | |
| TC-N03 unknown period degrade | `_32` | Partial | needs a class-section; else skip |
| TC-N04 tab filter params | `_33` | Full | |
| TC-N05 guest → login | `_50` | Full | |
| TC-N06 limited → hub 403 | `_51` | Full | |
| TC-N07 limited → class 403 | `_52` | Full | |
| TC-N08 limited → student 403 | `_53` | Full | |
| TC-N09 output escaping | `_93` | Partial | needs a class-section; else skip |

### Dependency / State
| Manual TC | Method(s) | Coverage | Note |
|-----------|-----------|----------|------|
| TC-D01 FK RESTRICT | `_40` | Full | MySQL metadata |
| TC-D02 tab reads assessments | `_41` | Partial | source-read |
| TC-D03 dead API + no tenancy | `_91` | Full | |
| TC-SM01 reviewed/locked only | `_41` | Partial | source-read |

### Defect-proving
| Manual TC | Method | Coverage | Note |
|-----------|--------|----------|------|
| TC-DEF01 BUG-BA-011 export 501 | `_70` | Full | |
| TC-DEF02 DEAD-BA-001 | `_91` | Full | |
| TC-DEF03 DOC-BA-001 | `_02` | Full | |
| TC-DEF04 BUG-BA-013 | `_14` | Full | runtime + source (runtime seed skips if no FK targets) |
| TC-DEF05 RPT-GAP-01 | `_71` | Partial | source-read |
| TC-DEF06 RPT-GAP-02 | `_72` | Partial | source-read |
| TC-DEF07 SEC-BA-003 | `_55` | Partial | source-read |
| TC-DEF08 VAL-BA-003 | `_56` | Partial | source-read |

### UI/UX
| Manual TC | Method | Coverage | Note |
|-----------|--------|----------|------|
| TC-U01 by-class empty state | `_60` | Partial | needs a class-section |
| TC-U02 tab empty-state text | `_61` | Partial | source-read |

---

## 2. Coverage Summary (by TC category)

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|-------------------|
| Positive | 14 | 6 | 8 | 0 | 100% |
| Negative | 9 | 6 | 3 | 0 | 100% |
| Dependency + State | 4 | 2 | 2 | 0 | 100% |
| Defect-proving | 8 | 5 | 3 | 0 | 100% |
| UI/UX | 2 | 0 | 2 | 0 | 100% |
| **Total** | **37** | **19** | **18** | **0** | **100%** |

> Gates: **Negative 100% ✅**, Positive ≥ 90% ✅ (100%), Dependency ≥ 90% ✅ (100%), Tenancy 100% on P0/P1 ✅. "Partial" here means data/source-dependent with a defensive skip — not a coverage hole. As a read-focused report screen there is no create/edit/delete matrix to cover.

---

## 3. Coverage-Score (by requirement Source area)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: hub render, tab+filters, grid, per-student, name-link) | 5 | 5 | 100% |
| State/Status (`Screen-Status`: reviewed/locked listing, status terminology) | 2 | 2 | 100% |
| Filters/Validation (`Screen-Filters`: period, class/section, invalid-id, degrade) | 4 | 4 | 100% |
| Integration Points (`Screen-IP`: std_students FK, ba_assessments source, dead API) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: viewAny, view, export, guest, gate divergences) | 6 | 6 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. **Explicit requirement items NOT implemented in the app** (covered by defect-proving TCs, not coverage gaps in the tests): Roll No / Admission No / dynamic per-student category columns / Grading Teacher / Status columns / draft-approval banner (RPT-GAP-01, `_71`); CSV export (RPT-GAP-02, `_72`); Academic Year filter (present in requirement, absent in `by-class.blade` — noted, gated by `_71`'s column scan).

---

## 4. Cross-Reference Defect Scan (11-check)

| # | Check | Compared | Finding | ID | Proving method |
|---|-------|----------|---------|----|-----------------|
| 1 | Enum case | DDL `ba_assessments.status ENUM('draft','submitted','reviewed','locked')` vs requirement "Approved" | Requirement uses "Approved"; no such enum value — terminology only | (note) | `_41` |
| 2 | Route registration | Blade `route('behavioural-assessment.reports.*')` + `reports-page` vs `routes/web.php` | All web report routes registered ✅ | — | `_03` |
| 3 | Route registration (API) | `routes/api.php` apiResource vs `RouteServiceProvider::map()` | **api.php never loaded → resource unregistered** | DEAD-BA-001 | `_91` |
| 4 | Gate vs Policy | `export()` `Gate::authorize('…reports.view')` vs `BaReportPolicy::export` (`…reports.export`) | Controller uses weaker `reports.view`; policy `export` ability is dead | **VAL-BA-003** | `_56` |
| 5 | Gate key consistency | tab-nav `reports.viewAny` vs `reportsPage()` `reports-page.viewAny` | Divergent permission keys for the same tab | **SEC-BA-003** | `_55` |
| 6 | Column vs model/DDL | `byClass()`/`categories()`/`by-class.blade` `score` vs `ba_computed_scores.numeric_score` | **Reads a non-existent `score` column → all scores 0.00, all at-risk** | **BUG-BA-013** | `_14` (`_15` contrast) |
| 7 | Cast vs DDL | model `$casts` `numeric_score decimal:5,2`, `overall_score decimal:2`, `is_active boolean` vs DDL | Consistent ✅ | — | `_01` |
| 8 | Service delegation | report logic in controller vs a service | No service; aggregation inline in controller (acceptable for read report) | (note) | `_14` |
| 9 | Feature vs impl | screen-16 grid (Roll/Admission/category cols/teacher/status/banner) vs `by-class.blade` | Grid columns + draft banner unimplemented | **RPT-GAP-01** | `_71` |
| 10 | Export contract | screen-16 CSV export vs `export()` | `abort(501)` stub; no CSV writer | **BUG-BA-011 / RPT-GAP-02** | `_70`,`_72` |
| 11 | Integration FK | requirement FK relationships vs migration `foreign()` | student/category/period FKs present, all RESTRICT ✅ | — | `_40` |

**Doc divergence:** DDL doc prefix `bha_computed_scores` vs live `ba_computed_scores` — **DOC-BA-001** (`_02`).

---

## 5. Discovered defects (file into the module register)

| ID | Severity | Summary | Proving method | Status |
|----|----------|---------|----------------|--------|
| **BUG-BA-013** | P2 — data-correctness | `byClass()`/`categories()` + `by-class.blade` aggregate a non-existent `score` column; every overall score renders `0.00` and every student is flagged at-risk. `student()` correctly uses `numeric_score`. Fix: rename to `numeric_score` (and derive a true overall). | `_14`, `_15` | New — proven |
| SEC-BA-003 | P3 | tab-nav gate (`reports.viewAny`) ≠ controller gate (`reports-page.viewAny`) — tab may show yet 403 on open, or vice-versa. | `_55` | New — proven |
| VAL-BA-003 | P3 | `export()` gates `reports.view`; `BaReportPolicy::export` (`reports.export`) is never used. | `_56` | New — proven |
| RPT-GAP-01 | Gap | screen-16 grid columns + draft banner + Academic Year filter unimplemented. | `_71` | New — proven |
| RPT-GAP-02 | Gap | screen-16 CSV export unimplemented (only 501 stub). | `_72` | New — proven |
| BUG-BA-011 | P2 | export 501 stub (audit-confirmed). | `_70` | Audit — proven |
| DEAD-BA-001 | P2 | dead API resource, no tenancy, unregistered (audit + constraint #23). | `_91` | Audit — proven |
| DOC-BA-001 | Doc | DDL `bha_` vs live `ba_`. | `_02` | Audit — proven |
