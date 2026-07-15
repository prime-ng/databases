# Behavioural Assessment — Class-Mapping — Validation Report

## Prerequisites

- Module `BehaviouralAssessment` enabled in `modules_statuses.json`.
- Tenant DB migrated & seeded; runtime table `ba_class_category_jnt` present in the tenant schema.
- At least one active `sch_classes` row and one active top-level `ba_categories` row (else dependency-gated methods `markTestSkipped`).
- Tenant admin/root user with all `tenant.behavioural-assessment.class-categories.*` + `tenant.behavioural-assessment.setup.viewAny` permissions.
- Chrome + matching ChromeDriver for Dusk; env `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` set for the tenant.
- MySQL connection for FK/unique-index inspection (SQLite degrades those 3 methods to skipped).

## 1. File Existence Summary

| File | Exists |
|------|--------|
| `bha_ClassMappingTcList_Require.md` | ✅ |
| `bha_ClassMappingMANUALTESTING_Require.md` | ✅ |
| `bha_ClassMappingGAPANALYSIS_Require.md` | ✅ |
| `bha_ClassMapping_TestCas.php` | ✅ (pre-existing, unmodified) |
| `bha_ClassMappingValidation_Report.md` | ✅ |
| `run-ClassMapping-tests.ps1` | ✅ |
| `run-ClassMapping-tests.sh` | ✅ |

> ONE comprehensive test file per screen (no V1/V2 split), per the current standard.

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Filename prefix `bha_` (artifact convention) | ✅ |
| Runtime table prefix `ba_` verified against DDL `CREATE TABLE ba_class_category_jnt` | ✅ (divergence tracked as DOC-BA-001) |
| PascalCase feature name `ClassMapping` | ✅ |
| PHP class name matches filename `bha_ClassMapping_TestCas` | ✅ |
| Test methods snake_case (`test_class_mapping_NN_*`) | ✅ |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| Extends `DuskTestCase` | ✅ |
| Namespace `Tests\Browser` | ✅ |
| `setUp()` initializes tenant context + resolves admin user | ✅ |
| `tearDown()` ends tenancy | ✅ |
| Typed properties initialized (`?User $adminUser = null`, etc.) | ✅ |
| `php -l` syntax check | ✅ No syntax errors detected |

## 4. Coverage Completeness

| Check | Result |
|-------|--------|
| Total test methods (single file) | **44** |
| Semantic numbering bands (01–09 config, 10–19 biz, 20–29 SM, 30–39 val, 40–49 FK, 50–59 auth, 60–69 UI, 70–79 edge, 90–99 tenancy/security) | ✅ |
| Every TcList TC-ID maps to ≥ 1 method | ✅ (44 TC ↔ 44 methods, 1:1) |
| Every method maps back to a TC/BC | ✅ |
| Negative coverage 100% | ✅ |
| Positive coverage ≥ 90% | ✅ (100%) |
| Dependency coverage ≥ 90% | ✅ (100%) |
| Tenancy coverage on P0/P1 | ✅ (TC-T01/TC-T02 present) |
| Source-traceability tags in TcList | ✅ |
| Coverage-Score + Cross-Reference Findings in Gap Analysis | ✅ |

Per-category coverage (Full+Partial): Config-truth 100%, Positive 100%, State-machine 100%, Negative 100%, Dependency 100%, Permissions 100%, Edge/security 100%, Tenancy 100%. The 7 Partial methods are environment-gated (`markTestSkipped`) by design.

## 5. Known Source Defects Documented

| ID | Description | Documented In | Proving test |
|----|-------------|---------------|--------------|
| DOC-BA-001 | DDL/registry prefix `bha_` diverges from live `ba_` | TcList, Gap Analysis | `test_..._02` |
| DATA-BA-CM-01 | Model omits `SoftDeletes` though migration adds `softDeletes()`; `destroy()` hard-deletes; dead Policy restore/forceDelete | TcList, Gap Analysis | `test_..._03`, `test_..._43` |
| VAL-BA-CM-02 | DB unique index lacks `deleted_at` scope vs request rule | TcList, Gap Analysis | `test_..._42` |
| SEC-BA-002 | FormRequest `authorize()` returns bare `true` (Gate-mitigated) | TcList, Gap Analysis | `test_..._92` |
| CM-GAP-03 | Dead non-POST FormRequest branch; no `update` route | TcList, Gap Analysis | `test_..._94` |

## 6. Final Verdict

**PASS WITH NOTES** — All 7 artifacts present; the pre-existing test file is `php -l` clean with 44 methods and was left unmodified. Documentation is fully consistent (1:1) with the suite's methods. Notes: (a) 5 documented source defects (DOC-BA-001, DATA-BA-CM-01, VAL-BA-CM-02, SEC-BA-002, CM-GAP-03) are proven-current-behaviour, not test failures; (b) 7 methods are environment-gated and will `markTestSkipped` on SQLite / single-tenant / single-class / single-category / no-polarity setups; (c) filenames keep the `bha_` convention while all runtime assertions correctly target the live `ba_` table.
