# bha_PeriodReport — Gap Analysis & Coverage

**Feature:** PeriodReport ("Teacher Progress Report") · **Test file:** `bha_PeriodReport_TestCas.php` (32 methods)
**Screen type:** Report — LIGHT / read-focused. No CRUD matrix (no create/edit/delete/restore/force-delete/toggle exist).

---

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| TC-M01 Render valid period | `_11`, `_12`, `_13`, `_04` | Full |
| TC-M02 Workflow counts reflect data | `_12`, `_15`, `_16` | Full (render + seeded smoke + source) |
| TC-M03 computed_scores NOT used | `_14` | Full |
| TC-M04 Invalid period id → 404 | `_30`, `_31` | Full |
| TC-M05 Guest & limited-user authZ | `_50`, `_51`, `_52` | Full |
| TC-M06 Period selector non-functional | `_62` | Full |
| TC-M07 Export 501 stub | `_70`, `_73` | Full |
| TC-M08 Comparison grid missing | `_71`, `_72` | Full |
| TC-M09 FK integrity | `_40` | Full |
| TC-M10 Tenancy & dead API | `_90`, `_91`, `_92` | Full |
| (schema truth) | `_01`, `_02`, `_03`, `_20`, `_21` | Full |
| (security smoke) | `_93` | Full |
| (cross-module render) | `_41` | Full |

Every Dusk method maps back to a TC/BC; every manual TC maps to ≥1 method.

---

## 2. Coverage Summary (by TC category)

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive / render / aggregate (TC-P) | 15 | 15 | 0 | 0 | 100% |
| Negative (TC-N) | 5 | 5 | 0 | 0 | 100% |
| Dependency (TC-D) | 3 | 3 | 0 | 0 | 100% |
| Edge / defect (TC-E) | 6 | 6 | 0 | 0 | 100% |
| Tenancy / API (TC-T) | 3 | 3 | 0 | 0 | 100% |
| **Total** | **32** | **32** | **0** | **0** | **100%** |

Gates: Negative 100% (met), Positive ≥ 90% (100%), Dependency ≥ 90% (100%), Tenancy 100% on P0/P1 (met).

> **Aggregate-correctness note.** `_15` (seeded workflow counts) is a *guarded smoke* — it `markTestSkipped`s when
> cross-module FKs (`sch_employees`, `sch_class_section_jnt`) are unavailable in a partial environment. The exact
> numeric equivalence of every rendered card vs SQL is documented as a **manual** step (TC-M02 steps 1–2); the
> automated layer proves the aggregation *reads the right tables* (`_16`) and *renders without error over seeded
> data* (`_15`). This is intentional for a read-only report where seeding a full cross-module fixture is brittle.

---

## 3. Coverage-Score (by requirement Source tag)

| Section | Covered | Total | % | Notes |
|---------|---------|-------|---|-------|
| Business Rules (`Screen-BR`) | 1 | 3 | 33% | Only the *implemented* teacher-progress behaviour is testable. The two spec rules (Delta formula, Dynamic Period Mapping) are **unimplemented** — covered as *documented gaps* (`_72`), not as passing behaviour. |
| State-Machine surfaced (`Screen-SM`) | 2 | 2 | 100% | Assessment FSM (`_20`) + period lifecycle (`_21`). Read-only — no transitions triggered. |
| Validation Rules (`Screen-VR`) | 3 | 3 | 100% | Route-id 404, non-numeric id, ignored query param. |
| Integration Points (`Screen-IP`) | 4 | 4 | 100% | period/teacher/section FKs (`_40`) + defensive eager-load (`_41`). |
| Permissions (`Screen-PM`) | 5 | 5 | 100% | gate/guest/limited/policy/export-divergence. |

> **Requirement items with 0 passing implementation (explicit coverage gaps, proven as defects):**
> - `Screen-BR` "Score Delta = Period(N)avg − Period(N-1)avg" → **RPT-GAP-PRD-02** (no impl; `_72`).
> - `Screen-BR` "Dynamic Period Mapping" (delta only across categories active in both periods) → **RPT-GAP-PRD-02** (`_72`).
> - `Screen` comparison grid (Roll No / Period-N averages / Trend Indicator / Compare Periods filter) → **RPT-GAP-PRD-01** (`_71`).
> - `Screen` report-card/chart export → **RPT-GAP-PRD-03** (`_73`).
> These are requirement-vs-implementation gaps: the implemented `period()` is a *different* report than screen-18
> specifies. The tests lock in current behaviour AND flag the divergence.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `ENUM` vs migration | `ba_assessments.status` = draft/submitted/reviewed/locked; period = open/closed/locked — consistent | — (clean) | `_01`, `_20`, `_21` |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | `reports.period`, `reports.index`, `reports.export` all registered | — (clean) | `_03` |
| 3 | Gate vs Policy | `period()` gate vs `BaReportPolicy` | `period()` gates `reports.view`; policy has `view` — consistent | — (clean) | `_52` |
| 3b | Gate vs Policy (export) | `export()` gate vs Policy `export` | `export()` gates `reports.view` NOT `reports.export`; Policy declares an unused `export` ability | **VAL-BA-003** | `_53` |
| 4 | Fillable vs DDL | model `$fillable` vs DDL | `ba_computed_scores` has `numeric_score`, no bare `score` — the report *should* use numeric_score if it read scores | **BUG-BA-013 (root)** — but **not in this path** | `_14` |
| 5 | Cast vs DDL | model casts vs DDL types | `status` string, `is_active` boolean/tinyint — consistent | — (clean) | `_01` |
| 6 | Service delegation | controller vs Service | `period()` contains its aggregation inline (no `BehaviouralScoreService`); acceptable for a read report | — (noted) | `_14`, `_16` |
| 7 | State machine vs impl | screen FSM vs controller | Report surfaces FSM but the **comparison/delta engine specified by screen-18 is absent** | **RPT-GAP-PRD-01/02** | `_71`, `_72` |
| 8 | Validation vs FormRequest | requirement filters vs impl | Screen specifies Session + Class/Section + multi-period filters; impl has only a (broken) single-period dropdown | **RPT-GAP-PRD-01**, **UI-BA-PRD-01** | `_62`, `_71` |
| 9 | Error message vs source | export message | `abort(501, 'Export feature coming soon.')` — matches BUG-BA-011 | **BUG-BA-011** | `_70` |
| 10 | Permissions vs Policy | perm matrix vs Policy/Gates | export gate weaker than Policy ability (see 3b) | **VAL-BA-003** | `_53` |
| 11 | Integration FK vs migration | requirement FKs vs migration | `ba_assessments` FKs to period/teacher/section present & RESTRICT | — (clean) | `_40` |
| 12 | Tenancy middleware | api.php vs web RSP | api resource lacks tenancy AND unregistered | **DEAD-BA-001** | `_91` |
| 13 | Prefix | DDL doc vs runtime | DDL doc `bha_`, runtime `ba_` | **DOC-BA-001** | `_02` |

---

## 5. Discovered / confirmed defects

| ID | Severity | Status | Proving test |
|----|----------|--------|--------------|
| BUG-BA-011 | High | Confirmed (audit) | `_70` |
| DEAD-BA-001 | Medium | Confirmed (audit + constraint #23) | `_91` |
| DOC-BA-001 | Doc | Confirmed | `_02` |
| VAL-BA-003 | Low | Confirmed | `_53` |
| RPT-GAP-PRD-01 | High | **New (this run)** — comparison grid unimplemented | `_71` |
| RPT-GAP-PRD-02 | Medium | **New (this run)** — delta + dynamic mapping rules unimplemented | `_72` |
| RPT-GAP-PRD-03 | Medium | **New (this run)** — report-card export unimplemented | `_73` |
| UI-BA-PRD-01 | Medium | **New (this run)** — period selector non-functional | `_62` |
| BUG-BA-013 | n/a here | **Proven NOT-applicable** to `period()` (contrast) | `_14` |

---

## 6. Legend

- **Full** — behaviour or defect fully exercised/proven by ≥1 automated method.
- **Partial** — some aspect deferred to a manual step (documented).
- **Gap** — requirement item with no passing implementation; captured as a defect with a proving test.
- **(clean)** — cross-reference check fired no defect.
