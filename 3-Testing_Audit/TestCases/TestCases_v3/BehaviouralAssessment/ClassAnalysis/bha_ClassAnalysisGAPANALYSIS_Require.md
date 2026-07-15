# ClassAnalysis — Gap Analysis & Coverage

**Feature:** ClassAnalysis (Class-Section Behaviour Analysis) — LIGHT report
**Test file:** `bha_ClassAnalysis_TestCas.php` · **Methods:** 29 · **`php -l`:** clean

Legend: **Full** = TC fully automated; **Partial** = automated with an environment/data caveat; **Gap** = manual-only.

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MT-01 render | `_10` | Full |
| MT-02 filters render | `_04`, `_11` | Full |
| MT-03 period filter | `_12`, `_13` | Full |
| MT-04 BUG-BA-013 data correctness | `_14`, `_15`, `_16`, `_17`, `_72` | Full |
| MT-05 invalid ids | `_30`, `_31` | Full |
| MT-06 FK dependency | `_40`, `_41` | Full |
| MT-07 permissions | `_50`, `_51`, `_52`, `_53` | Full |
| MT-08 UI/UX | `_60`, `_61`, `_62` | Full |
| MT-09 export/gaps | `_70`, `_71` | Full |
| MT-10 tenancy/API/security | `_90`, `_91`, `_92` | Full |
| Schema/prefix/route truth | `_01`, `_02`, `_03` | Full |

## 2. Coverage Summary (by TC category)

| Category | Total | Full | Partial | Gap | % |
|----------|-------|------|---------|-----|---|
| Positive (render/filter/config/FK/UIX) | 14 | 14 | 0 | 0 | 100% |
| Negative (invalid id / auth / escape) | 6 | 6 | 0 | 0 | 100% |
| Dependency / defect-proving | 9 | 9 | 0 | 0 | 100% |
| **Total** | **29** | **29** | **0** | **0** | **100%** |

> Gates met: Negative 100% · Positive ≥ 90% (100%) · Dependency ≥ 90% (100%) · Tenancy 100% (P0/P1 items `_90`/`_91`).
> Data-availability caveat: render/filter tests (`_10`–`_13`,`_60`,`_61`,`_92`) and seed-based BUG-BA-013 proofs
> (`_14`,`_15`,`_72`) `markTestSkipped()` when no class-section / student / category / period rows exist — the
> **deterministic** BUG-BA-013 source proofs (`_16`,`_17`) and export/API/policy proofs (`_53`,`_70`,`_71`,`_91`)
> need no seed data and always execute.

## 3. Coverage-Score (by requirement Source area)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: render, class/section+period filter, ranking, category perf, at-risk) | 5 | 5 | 100% |
| Data-correctness vs computed_scores (`Screen-BR` chart data) | 1 | 1 | 100% |
| Validation Rules (`Screen-VR`: invalid id / unknown filter) | 3 | 3 | 100% |
| Integration Points (`Screen-IP`: FK RESTRICT, student/category scoping) | 2 | 2 | 100% |
| Permissions (`Screen-PM`: guest, view gate, policy strings, export gate) | 4 | 4 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC. No requirement item has 0 coverage.

## 4. Cross-Reference Defect Scan (11-check)

| # | Check | Compared layers | Finding | TC / status |
|---|-------|-----------------|---------|-------------|
| 1 | Enum case | n/a (no enum input on this GET report) | — | N/A |
| 2 | Route registration | blade `route('...reports.class')` vs web.php + api.php | web route registered; **api resource unregistered** (RSP maps only web.php) | `_03`,`_91` — **DEAD-BA-001** |
| 3 | Gate vs Policy | controller `Gate::authorize` vs `BaReportPolicy` | `export()` gates `reports.view`, Policy declares unused `reports.export` | `_53` — **VAL-BA-003** |
| 4 | Fillable vs DDL | `BaComputedScore::$fillable` vs DDL | consistent; **no `score` column** exists (root of #6) | `_01`,`_14` |
| 5 | Cast vs DDL | `$casts numeric_score/overall_score decimal` vs DDL `decimal(5,2)` | consistent | `_01` |
| 6 | Service/aggregation vs schema | `byClass()` aggregates `score` vs schema `numeric_score` | **reads non-existent `score`** → 0.00 everywhere, everyone at-risk | `_15`,`_16`,`_17`,`_72` — **BUG-BA-013** |
| 7 | State machine vs impl | n/a (report has no lifecycle) | — | N/A |
| 8 | Validation vs FormRequest | n/a (no FormRequest) | route-model binding only | `_30`,`_31` |
| 9 | Error message vs FormRequest | export abort message vs requirement | live `abort(501)` stub | `_70` — **BUG-BA-011** |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy + gates | `reports.{viewAny,view,export}` present; export gate weaker (see #3) | `_52`,`_53` |
| 11 | Integration FK vs migration | requirement FK vs migration `foreign()` | `std_students`/`ba_categories`/`ba_assessment_periods` RESTRICT | `_40` |

**Cross-reference findings raised:** BUG-BA-013 (P1 data-correctness, class-level path — this feature is the
buggy `byClass()` path), BUG-BA-011 (P2 stub), DEAD-BA-001 (P2 dead/unsafe API wiring), VAL-BA-003 (P3 gate
divergence), DOC-BA-001 (doc), CA-GAP-01 (requirement export unimplemented). All carry a proving test.

## 5. Remaining Partial/Gap list
None. All 29 methods are Full within their documented data-availability guards; no manual-only TC remains.
