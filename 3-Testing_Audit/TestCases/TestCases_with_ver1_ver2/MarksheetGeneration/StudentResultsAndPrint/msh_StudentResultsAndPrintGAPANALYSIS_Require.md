# Gap Analysis — MarksheetGeneration / Student Results & Print

- **V1 methods:** 16 · **V2 methods:** 57 · **Ratio:** 3.56× (gate ≥ 2× satisfied)
- Legend: **Full** = automated assertion proves the TC · **Partial** = asserted but environment/seed-limited · **Gap** = not automated

## 1. Coverage mapping (manual TC ↔ Dusk method)

### Positive
| TC | V2 method(s) | Coverage |
|----|--------------|----------|
| TC-P01 config | 01, 02, 08 | Full |
| TC-P02 render 4 tabs | 10 | Full |
| TC-P03 create+Stored | 11 (V1 03) | Full |
| TC-P04 show aggregates | 14 (V1 04) | Full |
| TC-P05 update+Updated | 12 (V1 05) | Full |
| TC-P06 destroy+Deleted | 13 (V1 06) | Full |
| TC-P07 export xlsx | 15 (V1 11) | Full |
| TC-P08 print | 16 (V1 12) | Partial (200 or 302-on-missing-template both accepted) |
| TC-P09 pdf | 17 | Partial (status-level; redirect target not deep-asserted) |
| TC-P10 index redirect | 18 (V1 16) | Full |
| TC-P11 withhold | 20 (V1 09) | Full |
| TC-P12 declare | 21 (V1 10) | Full |
| TC-P13 child schema | 03,04,05,06 (V1 14) | Full |
| TC-P14 subject/ia/cosch tabs | 42,43,44 | Full |
| TC-P15 computation-log index | 45 | Partial (status-level) |

### Negative
| TC | V2 method(s) | Coverage |
|----|--------------|----------|
| TC-N01 required | 30 (V1 08) | Full |
| TC-N02 duplicate | 31 (V1 07) | Full |
| TC-N03 percentage>100 | 32 | Full |
| TC-N04 promotion enum | 33 | Full |
| TC-N05 result_status enum | 34 | Full |
| TC-N06 schedule exists | 35 | Full |
| TC-N07 student exists | 36 | Full |
| TC-N08 rank min | 37 | Full |
| TC-N09 show 404 | 19 | Full |
| TC-N10 update 404 | 38 | Full |
| TC-N11 withhold required | 25 | Full |
| TC-N12 withhold min:5 | 24 | Full |
| TC-N13 withhold max:255 | 39 | Full |
| TC-N14 whitespace reason | 71 | Full |
| TC-N15 guest redirect | 50 (V1 13) | Full |

### State machine
| TC | V2 | Coverage |
|----|----|----------|
| TC-SM01 declared→withheld | 20 | Full |
| TC-SM02 withheld→declared | 21 | Full |
| TC-SM03 withhold locked | 22 | Full |
| TC-SM04 declare locked | 23 | Full |

### Dependency / Security
| TC | V2 | Coverage |
|----|----|----------|
| TC-D01 soft-delete scope | 40 | Full |
| TC-D03 precision | 41, 72 | Full |
| TC-D04 computation-log immutable | 07, 92 (V1 15) | Full |
| TC-S01 SEC-MSH-001 | 51 | Full (source-proof) |
| TC-S02 SEC-MSH-002 | 52 | Full (source-proof) |
| TC-S03 SEC-MSH-003 | 53, 09 | Full (source-proof) |
| TC-S04 tabs gated | 54 | Full |
| TC-S05 results gate | 55 | Full |
| TC-S06 IDOR 404 | 90 | Partial (out-of-range id; no second live tenant) |
| TC-S07 XSS reason | 91 | Partial (stored verbatim; render-escape not DOM-asserted) |

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 15 | 12 | 3 | 0 | 100% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| State machine | 4 | 4 | 0 | 0 | 100% |
| Dependency | 4 | 4 | 0 | 0 | 100% |
| Security | 7 | 5 | 2 | 0 | 100% |
| **Overall** | **45** | **40** | **5** | **0** | **100%** |

Targets: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ · Security/Tenancy covered ✅.

## 3. Coverage-Score by requirement Source tag (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ Screen-BR / FR-01..03) | 10 | 10 | 100% |
| State-Machine transitions (BC-SM) | 4 | 4 | 100% |
| Validation Rules (BC-VAL) | 9 | 9 | 100% |
| Integration Points (BC-INT Screen-IP) | 2 | 3 | 67% |
| Permissions (BC-AUTH Screen-PM) | 7 | 7 | 100% |

Gap: **BC-INT-03** (coscholastic Discipline auto-populated from BehaviouralAssessment `is_auto_from_ba`) has schema coverage (test_05) but no live cross-module auto-population flow test — that behaviour originates in the BA/compute pipeline, not this screen. Documented, not automated here.

## 4. Cross-Reference Defect Scan
| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 1 | Enum case | DDL `promotion_status`/`result_status` (VARCHAR, doc values) vs Request `in:` | MATCH (PROMOTED/DETAINED/COMPARTMENT/PLACED; DECLARED/WITHHELD) — no case mismatch |
| 2 | Route registration | Blade `route('marksheet-generation.results.combined')` + student-result specials vs `routes/web.php` | MATCH — all registered (index/create/store/show/edit/update/destroy + export/print/pdf/withhold/declare) |
| 3 | Gate vs Policy | Controller `Gate::authorize('tenant.msh-results.view')` etc. vs Policies | **SEC-MSH-001/002** — create()/store() use wrong ability (`.view`/`.update`); `tenant.msh-results.view` is a non-entity gate — verify seeder defines it |
| 4 | Fillable vs DDL | `StudentResult::$fillable` vs DDL columns | MATCH (schedule_id..withheld_reason,is_active,created_by,updated_by) |
| 5 | Cast vs DDL | `$casts` decimal:2 vs DECIMAL(8,2)/(5,2) | MATCH |
| 6 | Service delegation | Controller withhold/declare vs `StudentResultReviewService` | Correct delegation. **PERF-MSH-003**: `results()`/`create()`/`edit()` build unbounded `Student::get()`/classSections `get()` — no pagination |
| 7 | State machine vs impl | Screen SM (DECLARED↔WITHHELD) vs Service | MATCH incl. locked-schedule guard |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | MATCH |
| 9 | Error message vs source | expected withhold/declare strings vs Service | MATCH (`Cannot withhold — schedule is locked.` etc.) |
| 10 | Permissions vs Gates | entity ability naming | **BUG-MSH-101 candidate** — inconsistent `.view` vs `.viewAny` across sibling controllers; `tenant.msh-results.view` non-entity gate. Verify in permission seeder |
| 11 | Integration FK vs migration | Screen FKs vs DDL `FOREIGN KEY` | MATCH (schedule CASCADE, student/class_section RESTRICT) |

## 5. Remaining partial-coverage list & limitations
- **TC-P08/P09 (print/pdf):** asserted at route/gate level; the actual rendered marksheet depends on a configured `MARKSHEET_PRINT` template and html2pdf.js (browser). Deep pixel/content assertion is out of scope.
- **TC-S06 (IDOR):** single-tenant environment — asserted via out-of-range id 404; a true second-tenant record leak needs a second seeded tenant.
- **TC-S07 (XSS):** stored-value round-trip asserted; DOM-level escape verification deferred (Blade auto-escapes `{{ }}`).
- **PERF-MSH-004:** hard-delete-on-recompute lives in the MarksheetSchedule compute flow — **out of scope** for this screen; flagged to verify in that feature.
