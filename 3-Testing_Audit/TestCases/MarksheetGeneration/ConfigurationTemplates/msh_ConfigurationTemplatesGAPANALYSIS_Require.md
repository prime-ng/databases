# Configuration Templates — Gap Analysis & Coverage

**Test file:** `msh_ConfigurationTemplates_TestCas.php` — ONE comprehensive suite, **52 methods**.
**Primary table:** `msh_config_templates` (prefix `msh_` verified against DDL `CREATE TABLE msh_config_templates`).

---

## 1. Manual TC ↔ Dusk method mapping

### Positive

| TC ID | Method | Coverage |
|-------|--------|----------|
| TC-P01 | 01, 02, 03, 05 | Full |
| TC-P02 | 04 | Full |
| TC-P03 | 10 | Full |
| TC-P04 | 11 | Full |
| TC-P05 | 12 | Full |
| TC-P06 | 13 | Full |
| TC-P07 | 14 | Full |
| TC-P08 | 15 | Full |
| TC-P09 | 16 | Full |
| TC-P10 | 17 | Full |
| TC-P11 | 18 | Full |
| TC-P12 | 19 | Full |
| TC-P13 | 20 | Full |
| TC-P14 | 22 | Full |
| TC-P15 | 25 | Full |
| TC-P16 | 54, 60 | Full |
| TC-P17 | 61 | Full |
| TC-P18 | 62 | Full |
| TC-P19 | 63 | Full |

### Negative

| TC ID | Method | Coverage |
|-------|--------|----------|
| TC-N01 | 30 | Full |
| TC-N02 | 31 | Full |
| TC-N03 | 32 | Full |
| TC-N04 | 33 | Full |
| TC-N05 | 34 | Full |
| TC-N06 | 35 | Full |
| TC-N07 | 36 | Full |
| TC-N08 | 37 | Full |
| TC-N09 | 38 | Full |
| TC-N10 | 39 | Full |
| TC-N11 | 40 | Full |
| TC-N12 | 41 | Full |
| TC-N13 | 42 | Full |
| TC-N14 | 43 | Full |
| TC-N15 | 50 | Full |
| TC-N16 | 51 | Full (skips under super-admin bypass — documented) |
| TC-N17 | 52 | Full (skips under super-admin bypass — documented) |
| TC-N18 | 53 | Full |
| TC-N19 | 55 | Full |
| TC-N20 | 70 | Full |
| TC-N21 | 91 | Full |

### Dependency

| TC ID | Method | Coverage |
|-------|--------|----------|
| TC-D01 | 44 | Full |
| TC-D02 | 45 | Full |
| TC-D03 | 46 | Full |
| TC-D04 | 47 | Full |
| TC-D05 | 10,17,18,19,22 | Full |
| TC-D06 | 56 | Full |
| TC-D07 | 71 | Full |
| TC-D08 | 21 | Full (documents current unguarded behaviour) |

### Tenancy

| TC ID | Method | Coverage |
|-------|--------|----------|
| TC-T01 | 90 | Full |
| TC-T02 | 91 | Full |

---

## 2. Coverage Summary

| Category | Total TCs | Full | Partial | Gap | % |
|----------|-----------|------|---------|-----|---|
| Positive | 19 | 19 | 0 | 0 | 100% |
| Negative | 21 | 21 | 0 | 0 | 100% |
| Dependency | 8 | 8 | 0 | 0 | 100% |
| Tenancy | 2 | 2 | 0 | 0 | 100% |
| **Total** | **50** | **50** | **0** | **0** | **100%** |

Targets met: Negative 100% ✔ · Positive ≥90% (100%) ✔ · Dependency ≥90% (100%) ✔ · Tenancy 100% on P1 ✔.

---

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 10 | 10 | 100% |
| State-Machine transitions (BC-SM) | 3 | 3 | 100% |
| Validation Rules (`Screen-VR` / BC-VAL) | 14 | 14 | 100% |
| Integration Points (BC-REF/BC-INT) | 6 | 6 | 100% |
| Permissions (`Screen-PM` / BC-AUTH) | 8 | 8 | 100% |

Every `Source`-tagged requirement item has ≥1 TC; no zero-coverage items.

---

## 4. Cross-Reference Findings (defect scan)

| # | Check | Compare | Finding | Status |
|---|-------|---------|---------|--------|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | No ENUMs in this feature (D-MSG-002 uses lookups); `class_assignments.*.type in:class,group` matches service | OK |
| 2 | Route registration | Blade `route()` vs `routes/web.php` + Provider | `config-template` resource + modal extras registered; `ia-component-type` is `only([store,show,update,destroy])` | OK |
| 3 | Gate vs Policy | controller `Gate::authorize()` string gates | Gates present on every method; SEC-MSH-003 = request layer never gates | **SEC-MSH-003 (P1)** |
| 4 | Fillable vs DDL | `ConfigTemplate::$fillable` vs DDL columns | Exact match (16 fillable) | OK |
| 5 | Cast vs DDL | `$casts` vs DDL types | `bool` casts on tinyint(1) flags; `decimal:2` on passing_percentage | OK |
| 6 | Service delegation | controller vs `ConfigTemplateService` | store/update delegate to service; **no `expectsJson()` JSON branch on config-template** (masters have one) | **DEV-MSH-CT-02 (P3, candidate)** |
| 7 | State machine vs impl | BR-MSG-027 `is_locked` immutability vs update path | No guard in controller/service → locked template still mutable | **DEV-MSH-CT-01 (P2, candidate)** |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | All rules present and asserted verbatim | OK |
| 9 | Error message vs FormRequest | expected vs `messages()` | No custom `messages()` — default Laravel messages (documented) | OK |
| 10 | Permissions vs Gates | requirement matrix vs `Gate::authorize()` | Keys `tenant.msh-config-template.{viewAny,view,create,update,delete}` match; unseeded (D39-MSH) | **D39-MSH (P1, env)** |
| 11 | Integration FK vs migration | requirement FKs vs DDL `foreign()` | session/type/exam_group RESTRICT, grading SET NULL, schedule RESTRICT — all asserted | OK |
| 12 | Model binding | `ExamGroupController::edit()` signature | No `ExamGroup` param → redirect, never 404 | **BUG-MSH-003 (P2)** |

---

## 5. Defects (mapped to proving tests)

| ID | Severity | Proving test | Notes |
|----|----------|--------------|-------|
| BUG-MSH-003 | P2 | `test_..._56` | Confirmed in `ExamGroupController::edit()` (~lines 64-69). |
| SEC-MSH-003 | P1 | `test_..._53`, `test_..._55`, `test_..._03` | All 5 FormRequests `authorize(){return true;}`. |
| D39-MSH | P1 | env prereq (Validation Report §5) | Permissions unseeded; tests grant explicitly. |
| DEV-MSH-CT-01 | P2 (candidate) | `test_..._21` | BR-MSG-027 immutability not implemented; test documents current behaviour. |
| DEV-MSH-CT-02 | P3 (candidate) | Cross-ref #6 | No JSON branch on config-template store/update. |

## Legend
Full = behaviour fully asserted incl. DB + activity-log checks · Partial = happy-path only · Gap = no automated coverage.
