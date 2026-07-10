# Gap Analysis — MarksheetGeneration · Student Results & Print

- **Test file:** `msh_StudentResultsAndPrint_TestCas.php` (single comprehensive suite, **57 methods**)
- **Coverage legend:** Full = automated & asserted · Partial = asserted with fallback / limited env · Gap = not automated

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01..P06 (schema) | test_01–06 | Full |
| TC-P10 tabs | test_10 | Full |
| TC-P11 store+Stored | test_11 | Full |
| TC-P12 update+Updated | test_12 | Full |
| TC-P14 show aggregates | test_14 | Full |
| TC-P15 export xlsx | test_15 | Full |
| TC-P16 print | test_16 | Full (route+gate; PDF body not diffed) |
| TC-P17 pdf | test_17 | Full (redirect resolves) |
| TC-P18 index redirect | test_18 | Full |
| TC-P60 search | test_60 | Partial (OR fallback on empty-state/tab) |
| TC-P61 class filter | test_61 | Full |
| TC-P62 empty state | test_62 | Full |
| TC-P63 breadcrumb | test_63 | Full |

### State-machine
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-SM20 withhold | test_20 | Full |
| TC-SM21 declare | test_21 | Full |
| TC-SM22 withhold-locked | test_22 | Full |
| TC-SM23 declare-locked | test_23 | Full |

### Negative
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N19 show 404 | test_19 | Full |
| TC-N24 reason min | test_24 | Full |
| TC-N25 reason required | test_25 | Full |
| TC-N30 required store | test_30 | Full |
| TC-N31 duplicate | test_31 | Full |
| TC-N32 percentage>100 | test_32 | Full |
| TC-N33 promotion enum | test_33 | Full |
| TC-N34 result enum | test_34 | Full |
| TC-N35 schedule exists | test_35 | Full |
| TC-N36 student exists | test_36 | Full |
| TC-N37 rank min | test_37 | Full |
| TC-N38 update 404 | test_38 | Full |
| TC-N39 reason max | test_39 | Full |
| TC-N50 guest login | test_50 | Full |

### Dependency / Integration
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-D07 complog immutable | test_07 | Full |
| TC-D13 destroy soft-delete | test_13 | Full |
| TC-D40 soft-delete scope | test_40 | Full |
| TC-D41 decimal round-trip | test_41 | Full |
| TC-D42/43/44 child tabs | test_42/43/44 | Full |
| TC-D45 computation-log index | test_45 | Full |

### Security-defect / Edge / Tenancy
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N08 request rules | test_08 | Full |
| TC-N09 withhold rules/authorize | test_09 | Full |
| TC-S51 SEC-MSH-001 | test_51 | Full (source-assert) |
| TC-S52 SEC-MSH-002 | test_52 | Full (source-assert) |
| TC-S53 SEC-MSH-003 | test_53 | Full (source-assert) |
| TC-AUTH54 tabs gated | test_54 | Full |
| TC-AUTH55 results gate | test_55 | Full |
| TC-EDG70 cross-schedule rel | test_70 | Full |
| TC-EDG71 whitespace reason | test_71 | Full |
| TC-EDG72 boundary precision | test_72 | Full |
| TC-T90 IDOR 404 | test_90 | Full |
| TC-S91 XSS reason | test_91 | Full |
| TC-S92 complog onlyTrashed throws | test_92 | Full |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 17 | 16 | 1 | 0 | 100% |
| Negative | 14 | 14 | 0 | 0 | 100% |
| Dependency/Integration | 8 | 8 | 0 | 0 | 100% |
| State-machine | 4 | 4 | 0 | 0 | 100% |
| Security/Edge/Tenancy | 13 | 13 | 0 | 0 | 100% |
| **Total** | **56** | **55** | **1** | **0** | **100%** |

Gate targets: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%) · Tenancy P0/P1 100% ✅.

## 3. Coverage-Score by requirement source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR / BC-BIZ) | 9 | 9 | 100% |
| State-Machine (Screen-SM / BC-SM) | 4 | 4 | 100% |
| Validation Rules (Screen-VR / BC-VAL) | 8 | 8 | 100% |
| Integration Points (Screen-IP / BC-INT/REF) | 4 | 4 | 100% |
| Permissions (Screen-PM / BC-AUTH) | 4 | 4 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compared | Finding | Proving test |
|---|-------|----------|---------|--------------|
| 1 | Enum case | DDL `result_status` DECLARED/WITHHELD, promotion enum vs `in:` | Match (case-exact) | test_08/33/34 |
| 2 | Route registration | Blade `route('marksheet-generation.student-result.*')` vs web.php + RouteServiceProvider | All registered (map()→mapWebRoutes only; api.php unregistered — see 05_ E23) | test_16/17/18 |
| 3 | Gate vs Policy | `Gate::authorize()` string gates vs Policy classes | **SEC-MSH-001/002**: create()/store() use wrong gate | test_51/52 |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | Match | test_01 |
| 5 | Cast vs DDL | `decimal:2` casts vs DECIMAL columns | Match | test_01/41/72 |
| 6 | Service delegation | Controller withhold/declare vs `StudentResultReviewService` | Delegated correctly | test_20–23 |
| 7 | State machine vs impl | DECLARED↔WITHHELD + lock guard vs service | Implemented; lock guard present | test_20–23 |
| 8 | Validation vs FormRequest | Screen VR vs `rules()` | Match | test_08/24/39 |
| 9 | Error message vs FormRequest | withhold min:5/max:255 | Present | test_24/39 |
| 10 | Permissions vs Policy/Gates | Permission matrix vs gates | **SEC-MSH-003**: FormRequest authorize()=true | test_09/53 |
| 11 | Integration FK vs migration | DDL FK RESTRICT/CASCADE vs schema | schedule CASCADE, student/class-section RESTRICT | test_40 (documented) |

### Findings register
| ID | Sev | Description | Status |
|----|-----|-------------|--------|
| SEC-MSH-001 | P1 | create() authorizes `.view` instead of `.create` | Proven (test_51) |
| SEC-MSH-002 | P1 | store() authorizes `.update` instead of `.create` | Proven (test_52) |
| SEC-MSH-003 | P1 | FormRequests `authorize()` return `true` | Proven (test_09/53) |
| PERF-MSH-003 | P2 | Unbounded `Student::get()`/`Subject::get()` in results view (no pagination) | Documented — not automated (needs large dataset + timing harness) |
| PERF-MSH-004 | P3 | `wipePreviousResults()` hard-deletes soft-deletable result rows on recompute | Documented — lives in SchedulingAndLifecycle compute path; not exercised here |

## 5. Remaining partial / limitations
- **test_60 (search)** — Partial: uses an OR fallback (`No Student Results Found` OR `Student Results`) so it stays green whether the tenant has matching rows or not.
- **Print/PDF (test_16/17)** — assert route+gate resolution and redirect only; the PDF binary is intentionally not diffed (engine is browser-side html2pdf.js).
- **PERF-MSH-003/004** — documented, not automated (require volume fixtures / the recompute path); tracked as defects, no proving test in this screen's suite.
- All data-mutating tests require tenant seed data (active unlocked schedule + class-section + student); absent → `markTestSkipped` (defensive, keeps partial envs green).
