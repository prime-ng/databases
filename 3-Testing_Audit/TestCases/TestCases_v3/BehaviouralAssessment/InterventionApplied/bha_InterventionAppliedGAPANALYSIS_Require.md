# Interventions Applied — Gap Analysis

**Module:** BehaviouralAssessment  •  **Feature:** InterventionApplied
**Test file:** `bha_InterventionApplied_TestCas.php` — 48 methods
**Legend:** Full = fully automated · Partial = automated with an environment-dependent skip path · Gap = not automated

---

## 1. Coverage Mapping (manual TC ↔ test method)

### Configuration / Schema
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-C01 | test_ia_01 | Full |
| TC-C02 | test_ia_02 | Full (schema-inspection skip fallback) |
| TC-C03 | test_ia_03 | Full (skips only if no incident/intervention seedable) |

### Positive (business rules)
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-P01 | test_ia_10 | Full |
| TC-P02 | test_ia_11 | Full |
| TC-P03 | test_ia_12 | Partial (skips if incident dependency unbuildable) |
| TC-P04 | test_ia_13 | Partial (skips if update payload unbuildable) |
| TC-P05 | test_ia_14 | Full |
| TC-P06 | test_ia_15 | Full |
| TC-P07 | test_ia_16 | Full |
| TC-P08 | test_ia_17 | Full |
| TC-P09 | test_ia_46 | Full |
| TC-P10 | test_ia_47 | Full |
| TC-P11 | test_ia_74 | Full |

### Requirement-gap defects
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-G01 | test_ia_20 | Full |
| TC-G02 | test_ia_21 | Full |

### Negative (validation)
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-N01 | test_ia_30 | Full |
| TC-N02 | test_ia_31 | Full |
| TC-N03 | test_ia_32 | Full |
| TC-N04 | test_ia_33 | Full |
| TC-N05 | test_ia_34 | Partial (skips if incident payload unbuildable) |
| TC-N06 | test_ia_35 | Partial (skips if incident payload unbuildable) |

### Dependency (FK / referential)
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-D01 | test_ia_40 | Full (MySQL; skips on non-MySQL) |
| TC-D02 | test_ia_41 | Full (MySQL; skips on non-MySQL) |
| TC-D03 | test_ia_42 | Partial (skips if incident unseedable) |
| TC-D04 | test_ia_43 | Partial (skips if incident unseedable) |
| TC-D05 | test_ia_44 | Partial (MySQL + incident required) |
| TC-D06 | test_ia_45 | Full |

### Authorization
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-A01 | test_ia_50 | Full |
| TC-A02 | test_ia_51 | Full |
| TC-A03 | test_ia_52 | Full |
| TC-A04 | test_ia_53 | Full |
| TC-A05 | test_ia_54 | Full (source-read) |
| TC-A06 | test_ia_55 | Full (source-read) |

### UI / UX
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-U01 | test_ia_60 | Partial (skips if linked incident has no student name) |
| TC-U02 | test_ia_61 | Full |
| TC-U03 | test_ia_62 | Full |
| TC-U04 | test_ia_63 | Full |
| TC-U05 | test_ia_64 | Full |

### Edge cases
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-E01 | test_ia_70 | Full |
| TC-E02 | test_ia_71 | Full |
| TC-E03 | test_ia_72 | Full |
| TC-E04 | test_ia_73 | Full |

### Tenancy + Security
| Manual TC | Test Method | Coverage |
|-----------|-------------|----------|
| TC-T01 | test_ia_90 | Full |
| TC-T02 | test_ia_91 | Partial (skips if single-tenant environment) |
| TC-S01 | test_ia_92 | Full |
| TC-S02 | test_ia_93 | Full |
| TC-S03 | test_ia_94 | Full (source-read) |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Configuration | 3 | 3 | 0 | 0 | 100% |
| Positive | 11 | 9 | 2 | 0 | 100% |
| Requirement-gap | 2 | 2 | 0 | 0 | 100% |
| Negative | 6 | 4 | 2 | 0 | 100% |
| Dependency | 6 | 2 | 4 | 0 | 100% |
| Authorization | 6 | 6 | 0 | 0 | 100% |
| UI/UX | 5 | 4 | 1 | 0 | 100% |
| Edge | 4 | 4 | 0 | 0 | 100% |
| Tenancy/Security | 5 | 4 | 1 | 0 | 100% |
| **Total** | **48** | **38** | **10** | **0** | **100%** |

**Gate check:** Negative 100% ✅ · Positive 100% (≥90) ✅ · Dependency 100% (≥90) ✅ · Tenancy 100% on P0/P1 ✅. The 10 "Partial" cases self-skip only when an optional dependency (seedable incident, second tenant, MySQL FK metadata) is absent — they never fail a partial environment.

---

## 3. Coverage-Score (by requirement Source)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 11 | 11 | 100% |
| State-Machine transitions (`Screen-SM`) | 0 | 0 | n/a (junction is stateless — no lifecycle FSM implemented; VAL-BA-IA-01) |
| Validation Rules (`Screen-VR` / BC-VAL) | 6 | 6 | 100% |
| Integration Points (`Screen-IP` / BC-REF/INT) | 8 | 8 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 6 | 6 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. The specced lifecycle FSM has 0 transitions to cover because the implementation exposes none — captured as defect VAL-BA-IA-01 rather than a coverage gap.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | Status | Proving test |
|---|-------|----------|---------|--------|--------------|
| 1 | Enum case | DDL enum vs FormRequest `in:` | No enum on the junction (only `notes` + `is_active`) | No issue | — |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | `interventions.add`/`.remove` registered; no `interventions.toggle` for `is_active` | **INFO-BA-IA-02** | test_ia_21 |
| 3 | Gate vs Policy | controller `Gate::authorize` vs `BaIncidentPolicy` | `incidents.update` gate string maps to a Policy method | No issue | test_ia_54, test_ia_55 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | `deleted_at` in DDL, model has no `SoftDeletes` → `deleted_at` is a dead column | **DATA-BA-IA-01** | test_ia_03, test_ia_46 |
| 5 | Cast vs DDL | `$casts` vs DDL type | `is_active` boolean-cast over `tinyint` — correct | No issue | test_ia_01 |
| 6 | Service delegation | controller vs Service | junction logic lives in the controller (`firstOrCreate`/`delete`), no service leakage | No issue | — |
| 7 | State machine vs impl | Screen-14 lifecycle vs controller | Status/Scheduled/Assigned-To/Completion/Progress-Notes specced but not implemented | **VAL-BA-IA-01** | test_ia_20 |
| 8 | Validation vs FormRequest | requirement rules vs `rules()` | inline add rules + `BaIncidentRequest` interventions rules present and complete | No issue | test_ia_30–35 |
| 9 | Error message vs FormRequest | expected vs `messages()` | standard Laravel messages; tests assert on 422 + error key (locale-tolerant) | No issue | test_ia_30–35 |
| 10 | Permissions vs Policy/Gates | matrix vs Policy + `Gate::authorize` | add/remove reuse `incidents.update`; no dedicated junction permission | Noted (by design) | test_ia_55 |
| 11 | Integration FK vs migration | requirement FK vs migration `foreign()` | `incident_id` CASCADE, `intervention_id` RESTRICT; `BaIntervention::booted()` detaches on forceDelete, bypassing RESTRICT | **INT-OBS-01** | test_ia_44 |
| — | Doc vs runtime table name | DDL doc `bha_` vs runtime `ba_` | live table is `ba_`, `bha_` absent | **DOC-BA-001** | test_ia_02 |
| — | FormRequest authorize | `authorize()` body | returns bare `true` (mitigated by controller Gate) | **SEC-BA-002** | test_ia_94 |

### Documented defects (audit-equivalent)
| Defect ID | Severity | Description | Proving test | Status |
|-----------|----------|-------------|--------------|--------|
| DOC-BA-001 | Low (doc) | DDL doc uses stale `bha_` prefix; runtime table is `ba_` | test_ia_02 | Documented |
| DATA-BA-IA-01 | Medium | `softDeletes()` column with no `SoftDeletes` trait — dead `deleted_at`, `->delete()` hard-deletes | test_ia_03, test_ia_46 | Documented |
| VAL-BA-IA-01 | Medium | Specced intervention lifecycle (status/dates/assignee/progress notes) not implemented | test_ia_20 | Documented |
| INFO-BA-IA-02 | Low | `is_active` column has no toggle endpoint | test_ia_21 | Documented |
| SEC-BA-002 | Low (mitigated) | `BaIncidentRequest::authorize()` returns bare `true` | test_ia_94 | Documented |
| INT-OBS-01 | Info | `BaIntervention::booted()` detaches junction rows on forceDelete, bypassing DB RESTRICT | test_ia_44 | Documented |

---

## 5. Remaining Partial-Coverage Notes
- FK/cascade tests (D03–D05) and bulk-attach (P03/P04, N05/N06) require a seedable incident (needs a `std_students` + `sch_employees` pair or an existing `ba_incidents` row); they `markTestSkipped` cleanly otherwise.
- Cross-tenant isolation (T02) requires a second tenant domain; skips in single-tenant environments.
- FK DELETE_RULE inspection (D01/D02/D05) is MySQL-specific; skips on other drivers.
- U01 (student-name search) skips when the linked incident has no resolvable student name.

No true coverage gaps: every manual TC maps to a method, and every method maps back to a TC/BC.
