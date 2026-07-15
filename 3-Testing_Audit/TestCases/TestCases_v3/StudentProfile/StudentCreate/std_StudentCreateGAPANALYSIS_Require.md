# std_StudentCreate — Gap Analysis & Coverage

**Test file:** `std_StudentCreate_TestCas.php` (37 methods, one file) · **Style:** Browser Dusk · **Scope:** TENANT-side.

## 1. Manual TC ↔ Dusk method mapping

| TC | Method(s) | Coverage |
|----|-----------|----------|
| TC-P01/02/03 | test_01, test_02, test_03 | Full |
| TC-P10/11 | test_10, test_11 | Full |
| TC-P12 | test_12 | Full |
| TC-P13 | test_13 | Full |
| TC-P14/15/16 | test_14, test_15, test_16 | Full |
| TC-P18 | test_18 | Full (defensive) |
| TC-N06 | test_06 | Full |
| TC-N30/31/32/33 | test_30–33 | Full |
| TC-N34/35 | test_34, test_35 | Full |
| TC-N36/37 | test_36, test_37 | Full |
| TC-N38 | test_38 | Full (source-level proof) |
| TC-N40 | test_40 | Full |
| TC-N50 | test_50 | Full |
| TC-D04 | test_04 | Full |
| TC-S05 | test_05 | Full |
| TC-D07 | test_07 | Full |
| TC-D08 | test_08 | Full |
| TC-S09 | test_09 | Full |
| TC-D17 | test_17 | Partial (accepts 200/302/422 — controller payload shape variance) |
| TC-D41/42 | test_41, test_42 | Full |
| TC-AUTH51 | test_51 | Full |
| TC-T90/91 | test_90, test_91 | Full / Env-gated |
| TC-S92/93/94 | test_92, test_93, test_94 | Full |

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Negative | 12 | 12 | 0 | 0 | **100%** |
| Positive | 11 | 10 | 1 | 0 | **100%** (≥90 gate met) |
| Dependency | 6 | 5 | 1 | 0 | **100%** (≥90 gate met) |
| Security/Tenancy | 8 | 7 | 1 | 0 | **100%** (Tenancy 100%) |

Gate check: Negative 100% ✅ · Positive ≥90% ✅ · Dependency ≥90% ✅ · Tenancy 100% ✅.

## 3. Partial-coverage notes / limitations
- **TC-D17 (existing-guardian link):** `createParentDetails` reads `relationships[$tab].guardian_source` + `guardians.$tab.type`; the exact junction write depends on live guardian data, so the test asserts an accepted status set and cleans up rather than asserting a specific row. Deep assertion belongs to a dedicated Parents feature file.
- **TC-T91 (cross-tenant):** requires ≥2 tenants; skips in single-tenant envs.
- **Browser bands (10–18, 30–50, 90/92/94):** require the STUDENT module enabled and a running Chrome/Dusk stack; schema/reflection/source bands (01–09, 38, 41, 42, 51, 93) run without a browser given DB access.

## 4. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 4 | 4 | 100% |
| Validation Rules (BC-VAL) | 7 | 7 | 100% |
| Integration/FK (BC-INT/REF) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 4 | 4 | 100% |
| DB/Schema (BC-DB) | 5 | 5 | 100% |

## 5. Cross-Reference Defect Scan

| # | Check | Compared | Finding | Test |
|---|-------|----------|---------|------|
| 1 | Enum case | DDL `blood_group` ENUM vs `in:` rule | Match (case-correct) | test_36 |
| 2 | Route registration | Blade/route names vs `routes/web.php` | All create routes registered under `student-profile.*` | test_09 |
| 3 | Gate vs prefix | Controller `Gate::authorize` | `tenant.student.create` / `tenant.guardian.create` — SEC-STD-02 **fixed** | test_09, test_51 |
| 4 | Fillable vs DDL | `Student::$fillable` vs DDL | Aligned | test_03 |
| 5 | Cast vs PII | `Student::$casts` | `aadhar_id => encrypted` present — SEC-STD-03 **fixed** | test_05 |
| 6 | Mass-assignment | login endpoint | `is_super_admin` not whitelisted — SEC-STD-01 **fixed** in controller | test_92 |
| 7 | UI residual | `_student-login.blade.php` | is_super_admin toggle **still rendered** (residual) | test_93 |
| 8 | Validation vs column | `first_name` max:100 vs `VARCHAR(50)` | **DEV-STD-CRE-01** truncation risk | test_38 |
| 9 | FormRequest presence | Requests dir | Only `StudentLeaveTypeRequest` — GAP-STD-05 **confirmed** | test_06 |
| 10 | Generated column | migration vs DDL spec | `current_flag` plain INT — BUG-STD-11 **confirmed** | test_07 |
| 11 | Soft-delete | migration vs model trait | column present, trait absent — DDL-STD-12 **residual** | test_04 |
| 12 | Reverse coupling | Student imports | downstream modules imported — ARCH-STD-13 **confirmed** | test_08 |

## 6. Legend
Full = assertion(s) directly verify the condition · Partial = accepted-status/defensive assertion · Gap = no coverage.

## 7. Discovered / documented defects
| ID | Severity | Status | Note |
|----|----------|--------|------|
| SEC-STD-01 | P0 | Controller fixed / UI residual | Remove toggle from `_student-login.blade.php` |
| SEC-STD-02 | P0 | Fixed | — |
| SEC-STD-03 | P1 | Fixed | encrypted cast + blind index |
| GAP-STD-05 | P1 | Open | inline validation, no FormRequest |
| BUG-STD-11 | P2 | Open | current_flag not GENERATED |
| ARCH-STD-13 | P2 | Open | reverse module coupling |
| DDL-STD-12 | P2 | Table fixed / model residual | add SoftDeletes trait to 3 models |
| DEV-STD-CRE-01 | P3 | Open (new) | first_name max:100 vs VARCHAR(50) |
