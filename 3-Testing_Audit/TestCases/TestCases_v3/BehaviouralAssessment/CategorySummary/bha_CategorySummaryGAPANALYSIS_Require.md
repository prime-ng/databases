# bha_CategorySummary — Gap Analysis & Coverage

**Feature:** CategorySummary (Category Summary Report) · **Controller:** `BaReportController::categories()`
**Test file:** `bha_CategorySummary_TestCas.php` · **Methods:** 32 · **`php -l`:** clean
**Screen type:** Report (LIGHT / read-focused) — coverage targets are render, aggregate correctness, filters, export, permissions, empty state, plus proving BUG-BA-013.

---

## 1. Manual TC ↔ Dusk Method Mapping

### Schema / Config (Band 01–09)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M01 schema truth | `_01`, `_02`, `_03`, `_04` | Full |

### Business rules / aggregate correctness (Band 10–19)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M02 BUG-BA-013 DB | `_11` | Full |
| TC-M03 BUG-BA-013 route | `_12` | Full (graceful-skip when module disabled) |
| TC-M04 source confirm | `_13`, `_15` | Full |
| TC-M04b data confirm | `_14` | Full |
| TC-M04c bottom-10 correct | `_16` | Full |
| TC-M05 anonymization | `_17` | Full |
| TC-M06 hub render | `_10` | Full |

### Validation / negative (Band 30–39)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M08 period filter / bug unconditional | `_30`, `_31` | Full |
| Injection-shaped params | `_32` | Full |

### Integration / FK (Band 40–49)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M11 FK RESTRICT + deps | `_40`, `_41` | Full |

### Permissions (Band 50–59)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M07 guest / 403 / policy / VAL-BA-003 | `_50`, `_51`, `_52`, `_53` | Full |

### UI/UX (Band 60–69)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M06/M08 empty state, filter, nav | `_60`, `_61`, `_62` | Full |

### Edge / requirement gaps (Band 70–79)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M09 export stub / RPT-GAP-12 | `_70`, `_72` | Full |
| TC-M10 RPT-GAP-11 / DOC-BA-002 | `_71`, `_73` | Full |

### Tenancy / Security (Band 90–99)
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-M12 tenancy, API deadness, escaping | `_90`, `_91`, `_92`, `_93` | Full |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|---------:|-----:|--------:|----:|-------:|
| Positive (render / correctness / config) | 14 | 14 | 0 | 0 | 100% |
| Negative (bug / validation / auth) | 10 | 10 | 0 | 0 | 100% |
| Dependency / Security / Tenancy | 7 | 7 | 0 | 0 | 100% |
| Requirement-gap | 3 | 3 | 0 | 0 | 100% |
| **Total** | **34** | **34** | **0** | **0** | **100%** |

Gate check (report/light screen): Negative 100% ✅ · Positive ≥ 90% → 100% ✅ · Dependency ≥ 90% → 100% ✅ · Tenancy (P1 module) 100% ✅.

> No create/edit/delete/toggle matrix — this is a read-only report screen (per §"adapt depth to screen type"). Lifecycle/state-machine bands are intentionally absent (no workflow on this screen).

---

## 3. Coverage-Score by Requirement Source (WP-F)
| Section | Covered | Total | % |
|---------|--------:|------:|--:|
| Business Rules (`Screen-17-BR`: aggregation formula, anonymization, download formats) | 3 | 3 | 100% |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | n/a (no workflow) |
| Validation Rules (`Screen-VR`) | 0 | 0 | n/a (read-only report) |
| Integration Points (`Screen-IP`: computed_scores, criteria, class-mapping, classes) | 4 | 4 | 100% |
| Permissions (`Screen-PM`: reports.view / export) | 2 | 2 | 100% |
| Filters (`Screen-17` Filters: Period / Class / Section) | 1 | 3 | 33% — **Class & Section filters unimplemented (RPT-GAP-11)** |
| Grid columns (`Screen-17` grid) | 4 | 6 | 67% — **Top/Lowest Criterion + Cohort Distribution unimplemented (RPT-GAP-12)** |
| Download formats (PDF/CSV) | 0 | 1 | 0% — **only the 501 export stub exists (BUG-BA-011 / RPT-GAP-12)** |

Every implemented `Source`-tagged requirement item has ≥1 TC. The 0/partial rows above are **implementation gaps**, each captured by a proving test (`_71`, `_72`), not test-coverage gaps.

---

## 4. Cross-Reference Defect Scan
| # | Check | Compared | Finding | Proving test | ID |
|---|-------|----------|---------|--------------|----|
| 1 | Enum case | DDL ENUM vs FormRequest | n/a (no form on this read-only screen) | — | — |
| 2 | Route registration | Blade `route()` vs routes + RSP | `reports.categories` registered (web); api resource NOT registered | `_03`, `_91` | DEAD-BA-001 |
| 3 | Gate vs Policy | controller `Gate::authorize` vs Policy | `export()` uses `reports.view`; Policy exposes unused `reports.export` | `_53` | VAL-BA-003 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL | consistent; **no `score`** in either → aggregation target invalid | `_01`, `_14` | BUG-BA-013 |
| 5 | Cast vs DDL | `numeric_score` decimal cast vs DECIMAL(5,2) | consistent | `_01` | — |
| 6 | Service delegation | controller vs Service | report logic lives in controller (no service) — noted, no defect | — | — |
| 7 | State machine vs impl | n/a (no workflow) | — | — | — |
| 8 | Validation vs FormRequest | n/a (read-only) | — | — | — |
| 9 | Error message vs FormRequest | n/a | — | — | — |
| 10 | Permissions vs Policy/Gates | requirement (HOD/Principal/counsellor view) vs `reports.view` gate | gate present & correct | `_51`, `_52` | — |
| 11 | Integration FK vs migration | requirement FK relationships vs migration | FKs present + RESTRICT | `_40` | — |
| **★** | **Aggregate column vs schema** | **`categories()` `AVG(score)` vs `ba_computed_scores` columns** | **`score` does not exist → SQL error → HARD 500** | `_11`, `_12`, `_13` | **BUG-BA-013** |
| ★ | Export impl vs requirement | requirement PDF/CSV vs `abort(501)` | export unimplemented stub | `_70`, `_72` | BUG-BA-011 / RPT-GAP-12 |
| ★ | Filter set vs requirement | requirement Class/Section vs view | only period filter | `_71` | RPT-GAP-11 |
| ★ | Screen vs impl identity | screens 17 & 23 vs single route/view | one shared implementation | `_73` | DOC-BA-002 |

---

## 5. Discovered / Confirmed Defects
| ID | Severity | Summary | Status |
|----|----------|---------|--------|
| **BUG-BA-013** | **P1** | Category Summary aggregates raw SQL `AVG/MIN/MAX(score)` on a non-existent column → page HARD-500s. One-word fix: `score`→`numeric_score`. Distinct from `byClass()` which silently yields 0.00 (Collection avg). | **Open — proven `_11/_12/_13/_14`** |
| BUG-BA-011 | P2 | `reports/export` live `abort(501)` stub; requirement PDF/CSV export unavailable | Open — proven `_70/_72` |
| DEAD-BA-001 | P2 | api `behaviouralassessments` resource: no tenancy + unregistered | Open — proven `_91` |
| RPT-GAP-11 | P2 | Class + Section filters unimplemented | Open — proven `_71` |
| RPT-GAP-12 | P2 | Top/Lowest Criterion, Cohort Distribution columns + PDF/CSV export unimplemented | Open — proven `_72` |
| VAL-BA-003 | P3 | `export()` gates `reports.view` not `reports.export` | Open — proven `_53` |
| DOC-BA-001 | P3 | DDL doc prefix `bha_` vs live `ba_` | Open — proven `_02` |
| DOC-BA-002 | P3 | Screens 17 & 23 share one implementation | Open — proven `_73` |

---

## 6. Legend
Full = every assertion of the manual TC is automated · Partial = automated with a documented limitation · Gap = no automated coverage.
Report/light screen → no CRUD/state-machine bands. `★` rows in the Cross-Reference scan are proactive layer-compare findings beyond the 11 standard checks.
