# My Assessments — Gap Analysis (`bha_MyAssessmentsGAPANALYSIS_Require.md`)

**Feature:** My Assessments (`08-My-Assessments*`) · **Module:** BehaviouralAssessment
**Test file:** `bha_MyAssessments_TestCas.php` — **49** methods (single comprehensive Dusk suite)
**Legend:** Full = automated end-to-end · Partial = automated but environment-guarded / source-scan only · Gap = not automated.

---

## 1. Manual TC ↔ Dusk method mapping

### Config / Schema
| Manual TC | Method | Coverage | Note |
|-----------|--------|----------|------|
| TC-01 | `_01` | Full | schema + fillable + relations + request-string asserts |
| TC-02 | `_02` | Full | DOC-BA-001 (guarded `markTestSkipped` if schema introspection unavailable) |
| TC-03 | `_03` | Full | audit-log immutability |

### Business rules (positive)
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-10 | `_10` | Full |
| TC-11 | `_11` | Full |
| TC-13 | `_13` | Full |
| TC-14 | `_14` | Full (skips if deps absent) |
| TC-15 | `_15` | Full (skips if deps absent) |
| TC-16 | `_16` | Full (skips if deps absent) |
| TC-17 | `_17` | Full (skips if deps absent) |

### State machine
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-20 | `_20` | Full |
| TC-21 | `_21` | Full |
| TC-22 | `_22` | Full |
| TC-23 | `_23` | Full |
| TC-24 | `_24` | Full |
| TC-25 | `_25` | Full — proves VAL-BA-MYA-004 |
| TC-46 | `_46` | Full |

### Validation (negative)
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-12 | `_12` | Full |
| TC-30 | `_30` | Full |
| TC-31 | `_31` | Full |
| TC-32 | `_32` | Full |
| TC-33 | `_33` | Full |
| TC-34 | `_34` | Full |
| TC-35 | `_35` | Full — proves BUG-BA-MYA-005 |

### Dependency / FK / lifecycle
| Manual TC | Method | Coverage | Note |
|-----------|--------|----------|------|
| TC-40 | `_40` | Full |
| TC-41 | `_41` | Full |
| TC-42 | `_42` | Full |
| TC-43 | `_43` | Partial | MySQL-only FK metadata; `markTestSkipped` otherwise |
| TC-44 | `_44` | Partial | MySQL-only |
| TC-45 | `_45` | Partial | MySQL-only |
| TC-47 | `_47` | Full — proves BUG-BA-MYA-001 |

### Permissions
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-50 | `_50` | Full |
| TC-51 | `_51` | Full |
| TC-52 | `_52` | Full |
| TC-53 | `_53` | Full |
| TC-54 | `_54` | Partial | source-scan of Policy (skips if unreadable) |
| TC-55 | `_55` | Partial | source-scan of Controller — proves PERM-BA-MYA-003 |

### UI/UX
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-60 | `_60` | Full |
| TC-61 | `_61` | Full |
| TC-62 | `_62` | Full |
| TC-63 | `_63` | Full |

### Edge
| Manual TC | Method | Coverage |
|-----------|--------|----------|
| TC-70 | `_70` | Full |
| TC-71 | `_71` | Full |
| TC-72 | `_72` | Partial | MySQL-only enum introspection |

### Tenancy + Security
| Manual TC | Method | Coverage | Note |
|-----------|--------|----------|------|
| TC-90 | `_90` | Full |
| TC-91 | `_91` | Partial | needs ≥2 tenant domains; skips otherwise |
| TC-92 | `_92` | Partial | source-scan — proves SEC-BA-002 |
| TC-93 | `_93` | Full |
| TC-94 | `_94` | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Config/Schema | 3 | 3 | 0 | 0 | 100% |
| Positive (BIZ/UIX) | 7 | 7 | 0 | 0 | 100% |
| State machine | 7 | 7 | 0 | 0 | 100% |
| Negative (validation) | 7 | 7 | 0 | 0 | 100% |
| Dependency/FK/lifecycle | 8 | 5 | 3 | 0 | 100% |
| Permissions | 6 | 4 | 2 | 0 | 100% |
| UI/UX | 4 | 4 | 0 | 0 | 100% |
| Edge | 3 | 2 | 1 | 0 | 100% |
| Tenancy/Security | 5 | 3 | 2 | 0 | 100% |
| **Total** | **49** | **42** | **7** | **0** | **100%** |

**Gate check:** Negative **100%** (7/7), Positive **100%** (≥90% ✔), Dependency **100%** (≥90% ✔), Tenancy **100%** on P0/P1 ✔. No un-automated gaps. "Partial" entries are environment-guarded (MySQL-only FK/enum introspection, second-tenant availability, or source-scan) and degrade to `markTestSkipped` rather than failing in partial environments.

---

## 3. Coverage-Score (by requirement Source tag)

| Section | Covered | Total | % | Notes |
|---------|---------|-------|---|-------|
| Business Rules (Screen-BR) | 10 | 10 | 100% | BC-BIZ-01..10 each ≥1 TC |
| State-Machine transitions (Screen-SM) | 6 | 6 | 100% | BC-SM-01..06 (legal + illegal) |
| Validation Rules (Screen-VR) | 5 | 5 | 100% | BC-VAL-01..05 |
| Integration / FK points (Screen-IP) | 7 | 7 | 100% | BC-REF-01..04 + BC-INT-01..03 |
| Permissions (Screen-PM) | 8 | 8 | 100% | 8 policy abilities via `_50`–`_55` |

Every `Source`-tagged requirement item maps to ≥1 TC. No zero-coverage requirement items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `ENUM(draft,locked,reviewed,submitted)` vs Request `in:` | No case mismatch; enum asserted | — | `_72` |
| 2 | Route registration | Blade `route()` vs module routes | All CRUD/submit/restore/force-delete routes registered | — | `_13`,`_70`,`_71` |
| 3 | Gate vs Policy | Controller `Gate::authorize()` vs Policy abilities | **`restore()`/`forceDelete()` authorize `.delete`, not `.restore`/`.forceDelete`** | **PERM-BA-MYA-003** (P1) | `_55` |
| 4 | Fillable vs DDL | model `$fillable` vs DDL columns | Consistent (11 fillable cols) | — | `_01` |
| 5 | Cast vs DDL | `$casts` vs DDL type | `is_active` tinyint ↔ bool consistent | — | `_01` |
| 6 | Service delegation | Controller body vs Service | store/submit logic in controller; audit via `BaAuditLog::log` | — | `_10`,`_20` |
| 7 | State machine vs impl | Req transitions vs controller | **submit lacks 100%-completion gate** | **VAL-BA-MYA-004** (P1) | `_25` |
| 8 | Validation vs FormRequest | Req rules vs `rules()` | Rules present & asserted | — | `_30`–`_34` |
| 9 | Error message vs source | expected vs controller messages | Verbatim messages asserted | — | `_12`,`_22`,`_23`,`_24` |
| 10 | Permissions vs Policy/Gates | 8-ability matrix vs Policy | All 8 present | — | `_54` |
| 11 | Integration FK vs migration | Req FK relations vs migration `foreign()` | RESTRICT×3 + SET NULL asserted | — | `_43`,`_44`,`_45` |
| 12a | Missing `use` import | Controller `show()` references `BaStudentRemark` | **un-imported class → fatal 500** | **BUG-BA-MYA-001** (P0) | `_47` |
| 12b | Missing `use` import | Controller `bulkRate()` uses `DB` facade | **`DB` not imported** (source-scan) | **BUG-BA-MYA-002** (P1) | source-scan (noted `_92`) |
| 12c | firstOrCreate key vs unique key | `firstOrCreate(status:'draft')` vs `unique(teacher,cs,period)` | **submitted-triple collision → 500** | **BUG-BA-MYA-005** (P1) | `_35` |
| 13 | FormRequest authorize | `authorize()` body | **returns bare `true`** (mitigated by controller Gate) | **SEC-BA-002** (Info) | `_92` |
| 14 | Doc prefix vs runtime | DDL doc `bha_` vs live `ba_` | **prefix divergence** | **DOC-BA-001** (Doc) | `_02` |

---

## 5. Defect Register (this feature)

| ID | Sev | Status | Proving test |
|----|-----|--------|--------------|
| BUG-BA-MYA-001 | P0 | Open — proven | `_47` |
| BUG-BA-MYA-002 | P1 | Open — source-scanned | noted in `_92` (see BC-BIZ-09) |
| PERM-BA-MYA-003 | P1 | Open — proven | `_55` |
| VAL-BA-MYA-004 | P1 | Open — proven | `_25` |
| BUG-BA-MYA-005 | P1 | Open — proven | `_35` |
| DOC-BA-001 | Doc | Open | `_02` |
| SEC-BA-002 | Info | Documented | `_92` |

Each proving test is written to assert **current (defective) behaviour**, so a regression that "fixes" the source will flip the test red and surface the change (assertion messages call this out, e.g. "regression fixed?").
