# std_StudentReports — Gap Analysis

**Feature:** StudentReports (composite, read-only) · **Prefix:** `std_` · **Test file:** `std_StudentReports_TestCas.php` (38 methods)
**Type:** Read-focused report matrix (render / filters / export / permissions / empty-state / tenancy). No CRUD matrix by design.

---

## 1. Manual TC ↔ Dusk method coverage

### Schema / Config
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P01 | test_..._01 | Full |
| TC-P02 | test_..._02 | Full |
| TC-P03 | test_..._03 | Full |

### Render (business rules)
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P10 | test_..._10 | Full |
| TC-P11 | test_..._11 | Full |
| TC-P12 | test_..._12 | Full |
| TC-P13 | test_..._13 | Full |
| TC-P14 | test_..._14 | Full |
| TC-P15 | test_..._15 | Full |
| TC-P16 | test_..._16 | Full |

### Filters
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P30 | test_..._30 | Full |
| TC-P31 | test_..._31 | Full |
| TC-P32 | test_..._32 | Full |
| TC-N33 | test_..._33 | Full |

### Export / Integration
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-D40 | test_..._40 | Full |
| TC-D41 | test_..._41 | Full |
| TC-D42 | test_..._42 | Full |
| TC-D43 (PERF-STD-10) | test_..._43 | Full (source-truth) |
| TC-D44 | test_..._44 | Full |
| TC-D45 | test_..._45 | Full |

### Permissions
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-N50 | test_..._50 | Full |
| TC-P51 | test_..._51 | Full |
| TC-N52 | test_..._52 | Partial (defensive skip if no limited user) |
| TC-P53 | test_..._53 | Full |
| TC-P54 | test_..._54 | Partial (defensive skip if HTTP path blocked) |
| TC-P55 | test_..._55 | Full |

### UI / Empty-state / Edge / Tenancy / Security
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-P60 | test_..._60 | Full |
| TC-P61 | test_..._61 | Full |
| TC-P62 | test_..._62 | Full |
| TC-D63 (DEV-STD-R1) | test_..._63 | Full (source-truth) |
| TC-P64 | test_..._64 | Full |
| TC-N70 (DEV-STD-R2) | test_..._70 | Full (source-truth) |
| TC-N71 | test_..._71 | Full |
| TC-T90 | test_..._90 | Full |
| TC-T91 | test_..._91 | Full |
| TC-S92 | test_..._92 | Partial (skip if activity_logs absent) |
| TC-S93 | test_..._93 | Full |
| TC-T94 | test_..._94 | Full |

---

## 2. Coverage Summary
| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive (render/filter/auth/UI) | 21 | 19 | 2 | 0 | 100% |
| Negative (filter/auth/edge) | 5 | 4 | 1 | 0 | 100% |
| Dependency/Integration (export) | 7 | 7 | 0 | 0 | 100% |
| Tenancy/Security | 5 | 4 | 1 | 0 | 100% |
| **Total** | **38** | **34** | **4** | **0** | **100%** |

Targets met — Negative 100%, Positive ≥ 90%, Dependency ≥ 90%, Tenancy 100%. Read-only report → no create/edit/delete gaps.

---

## 3. Coverage-Score by requirement source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR: FR-18..FR-33 report rules) | 3 areas (strength/admission/medical) + scoping | 4 | 100% |
| Validation/Filter Rules (class/session/date) | 3 | 3 | 100% |
| Integration/Export (Screen-IP: export path) | 3 (queue xlsx/csv + sync pdf) | 3 | 100% |
| Permissions (Screen-PM: viewAny/export) | 2 | 2 | 100% |
| State-Machine | n/a (read-only) | 0 | — |

Dashboard/KPI (FR-01..FR-17), ID Card (FR-39..41), attendance-summary (FR-38), caste/age/RTE reports (FR-34..37) are **out of this feature's scope** (separate screens/controllers) and are intentionally not covered here.

---

## 4. Cross-Reference Findings (defect scan)
| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 2 | Route registration | Blade `route('complaint.reports.summary')` vs registered routes | **DEV-STD-R1** — route unregistered → 500 on report index render |
| 3 | Gate vs Policy | `Gate::authorize('tenant.student.viewAny')` | Gate string present; verify a Policy/permission definition backs it |
| 6 | Service delegation | Controller body | `combinedStudentReport` contains all report logic inline (no service) — note only |
| 7 | State machine | n/a | Read-only, none |
| 9 | Null-safety | `?? $currentSession->id` when no current session | **DEV-STD-R2** — null deref |
| — | Perf | Export path for large datasets | **PERF-STD-10** — PDF export synchronous inline (Excel/CSV queued) |
| — | Dead code | `StudentReportController@index` returns hardcoded placeholder `reportData` (Class 1/2, zeros); NOT wired to any route (both routes use `combinedStudentReport`) | Stub/dead method — note only |

**Legend:** Full = automated end-to-end or by source-truth assertion; Partial = automated but may `markTestSkipped` in a partial environment; Gap = not automated.
