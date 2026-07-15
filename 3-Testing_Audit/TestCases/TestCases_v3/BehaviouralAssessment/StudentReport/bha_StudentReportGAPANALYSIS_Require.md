# Student Report — Gap Analysis & Coverage

**Feature:** StudentReport · **Test file:** `bha_StudentReport_TestCas.php` (33 methods) · **Depth:** LIGHT (report)
**Controller:** `BaReportController::student()` · **Live tables:** `ba_computed_scores`, `ba_incidents`, `ba_student_remarks`

---

## 1. Manual TC ↔ Dusk Method Mapping

### Schema / Config
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P01 (computed_scores schema) | `_01` | Full |
| TC-P02 (incidents schema + ENUMs) | `_02` | Full |
| TC-P03 (student_remarks schema) | `_03` | Full |
| TC-P04 (method + route) | `_04` | Full |
| TC-P05 (view zones) | `_05` | Full |
| TC-P06 (ba_ prefix) | `_06` | Full |

### Render / Data correctness
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P07 (authorized render) | `_10` | Full |
| TC-P08 (numeric_score overall+rank) | `_11` | Full |
| TC-P09 (KPI badges) | `_12` | Full |
| TC-P10 (class-rank no-500) | `_13` | Full |
| TC-P11 (incident timeline) | `_14` | Full |
| TC-P12 (teacher remarks) | `_15` | Full |

### Negative / Filters
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N01 (invalid id 404) | `_30` | Full |
| TC-N02 (unknown period graceful) | `_31` | Full |
| TC-P13 (valid period filter) | `_32` | Full |

### Dependency (FK)
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-D01 (computed_scores RESTRICT) | `_40` | Full |
| TC-D02 (incidents RESTRICT/SET NULL) | `_41` | Full |
| TC-D03 (remarks CASCADE/RESTRICT) | `_42` | Full |
| TC-D04 (tenant context) | `_90` | Full |

### Permissions / Policy
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N03 (guest redirect) | `_50` | Full |
| TC-N04 (limited 403) | `_51` | Full |
| TC-S01 (policy strings) | `_52` | Full |
| TC-S02 (VAL-BA-003 export gate) | `_53` | Full |

### UI/UX
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P14 (empty state) | `_60` | Full |
| TC-P15 (period selector) | `_61` | Full |
| TC-P16 (back link) | `_62` | Full |

### Edge / Defect proofs
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| BUG-BA-013 (score column) | `_11`, `_70` | Full |
| BUG-BA-011 (501 export) | `_71` | Full |
| RPT-GAP-STU-01 (grade lockdown) | `_72` | Full |
| RPT-GAP-STU-02 (Download PDF) | `_73` | Full |
| DEAD-BA-001 (API dead) | `_91` | Full |
| BC-INT-03 (tenancy stack) | `_92` | Full |
| TC-N05 (XSS escape) | `_93` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|:--------:|:----:|:-------:|:---:|:------:|
| Positive (render + data) | 16 | 16 | 0 | 0 | 100% |
| Negative | 5 | 5 | 0 | 0 | 100% |
| Dependency (FK/tenancy) | 4 | 4 | 0 | 0 | 100% |
| Permissions / Policy | 2 | 2 | 0 | 0 | 100% |
| Defect proofs | 7 | 7 | 0 | 0 | 100% |
| **Total** | **34** | **34** | **0** | **0** | **100%** |

> LIGHT report screen — no create/edit/delete/toggle matrix (read-only). Coverage gates for a report screen
> (render, data-correctness, filters, permissions, empty state, tenancy) are all met at 100%.

---

## 3. Coverage-Score (by requirement Source tag)

| Section | Covered | Total | % |
|---------|:-------:|:-----:|:-:|
| Business Rules (Screen-20 §Widgets/Rules) — 4 zones + lockdown + PDF | 6 | 6 | 100% |
| State-Machine transitions (Screen-SM) | 0 | 0 | n/a (report is read-only) |
| Validation Rules (Screen-VR) | 0 | 0 | n/a (no form input beyond route id) |
| Integration Points (Screen-IP) — computed_scores / incidents / remarks / tenancy | 4 | 4 | 100% |
| Permissions (Screen-PM) — reports.view / viewAny / export | 3 | 3 | 100% |

Every Source-tagged requirement item maps to ≥1 TC. No 0-coverage items.

---

## 4. Cross-Reference Defect Scan (11 checks)

| # | Check | Compared | Finding | ID | Proving method |
|---|-------|----------|---------|----|----|
| 1 | Enum case | DDL `incident_type/severity` ENUM vs blade usage | Match (`positive_reinforcement`, `minor`…`critical`) | — | `_02`, `_14` |
| 2 | Route registration | blade `route('...reports.student')` vs web.php | Registered | — | `_04` |
| 3 | Gate vs Policy | controller `Gate::authorize('...reports.view')` vs `BaReportPolicy::view` | Present, consistent for view | — | `_52` |
| 4 | Fillable vs DDL | `BaComputedScore::$fillable` vs DDL columns; **no `score`** | Model has `numeric_score`, no `score` | **BUG-BA-013** | `_01`, `_70` |
| 5 | Cast vs DDL | `numeric_score` decimal cast vs `DECIMAL(5,2)` | Match | — | `_01` |
| 6 | Service delegation | student() body vs any Service | Logic inline in controller (no service); reads real column | — | `_11` |
| 7 | State machine vs impl | Screen-20 Grade Lockdown (draft→hidden) vs controller/blade | **Lockdown NOT implemented** | **RPT-GAP-STU-01** | `_72` |
| 8 | Requirement widget vs impl | Screen-20 "Download PDF" vs blade | **Button absent** | **RPT-GAP-STU-02** | `_73` |
| 9 | Feature completeness vs stub | Screen-20 export vs `export()` | **abort(501) stub** | **BUG-BA-011** | `_71` |
| 10 | Permissions vs Policy | `export()` gate `reports.view` vs Policy `reports.export` | **Weaker gate; dead policy ability** | **VAL-BA-003** | `_53` |
| 11 | Integration FK vs migration | Screen-20 sources (scores/incidents/remarks) vs FK on-delete | RESTRICT/SET NULL/CASCADE as specified | — | `_40`–`_42` |
| + | View-vs-controller column | blade `$cs->score` vs controller `avg('numeric_score')` | **Split: KPI correct, grid broken** | **BUG-BA-013** | `_11`, `_70` |
| + | API tenancy | api.php apiResource vs RSP::map + tenancy middleware | **Dead + no tenancy** | **DEAD-BA-001** | `_91` |
| + | Runtime prefix | DDL-doc `bha_` vs live `ba_` | **Doc diverges** | **DOC-BA-001** | `_06` |

### Discovered / confirmed defects (feature-scoped)
- **BUG-BA-013 (this screen — NEW nuance):** confirmed the bug reaches `student.blade.php`. The per-student
  Category-Wise Scores grid reads `$cs->score` (lines 149/162/197), a non-existent column, so it renders
  `0.00` for every category — *even though* the controller's overall-KPI and class-rank aggregate correctly on
  `numeric_score`. This is a **split firing**: the StudentScoresReport sibling found `byClass()`/`categories()`
  fully broken and `student()` (controller) correct; this screen shows the blade layer of `student()` is *also*
  affected. Recommended fix: change the blade to `$cs->numeric_score` (3 sites) + the header badge.
- **RPT-GAP-STU-01:** Grade Lockdown Rule (draft-hiding + "Show Drafts" + progress message) unimplemented.
- **RPT-GAP-STU-02 / BUG-BA-011:** "Download PDF" button absent; only the 501 export stub exists.
- **VAL-BA-003:** `export()` authorizes `reports.view`, not the Policy's `reports.export` ability.
- **DEAD-BA-001 / DOC-BA-001:** carried from the module audit; proven here for regression tracking.

---

## 5. Legend
- **Full** — automated method(s) fully assert the manual TC's expected result.
- **Partial** — asserted with environmental fallbacks (`markTestSkipped` when data/source absent).
- **Gap** — no automated coverage.
- Source-text checks resolve the app repo via reflection (constraints #29/#32) and fail-soft when unreadable.
