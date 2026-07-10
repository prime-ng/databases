# Configuration Templates — Validation Report

**Module:** MarksheetGeneration (MSH) · **Feature:** Configuration Templates · **Date:** 2026-Jul-09
**Prefix (verified against DDL `CREATE TABLE msh_config_templates`):** `msh_`

## 1. File Existence Summary

| # | File | Present |
|---|------|---------|
| 1 | `msh_ConfigurationTemplatesTcList_Require.md` | ✅ |
| 2 | `msh_ConfigurationTemplatesMANUALTESTING_Require.md` | ✅ |
| 3 | `msh_ConfigurationTemplatesGAPANALYSIS_Require.md` | ✅ |
| 4 | `msh_ConfigurationTemplatesV1_TestCas.php` | ✅ |
| 5 | `msh_ConfigurationTemplatesV2_TestCas.php` | ✅ |
| 6 | `msh_ConfigurationTemplatesValidation_Report.md` | ✅ (this file) |
| 7 | `run-ConfigurationTemplates-tests.ps1` | ✅ |
| 8 | `run-ConfigurationTemplates-tests.sh` | ✅ |

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| Prefix matches DDL primary table (`msh_config_templates` → `msh_`) | ✅ |
| Feature PascalCase (`ConfigurationTemplates`) | ✅ |
| PHP class name = filename (`msh_ConfigurationTemplatesV1_TestCas` / `...V2...`) | ✅ |
| Namespace `Tests\Browser` | ✅ |
| snake_case zero-padded methods `test_config_template_NN_*` | ✅ |

## 3. Structure Validation

| Check | Result |
|-------|--------|
| `extends DuskTestCase` | ✅ both suites |
| `setUp()`/`tearDown()` present; tenancy init + guarded end | ✅ |
| Typed properties initialised (`?User = null`, strings `= ''`) | ✅ |
| `php -l` clean (V1) | ✅ No syntax errors |
| `php -l` clean (V2) | ✅ No syntax errors |
| `test_01` asserts schema truth (`Schema::hasTable/hasColumns`, index inspect, request/controller file contents, model config) | ✅ |
| Activity events asserted verbatim (`Stored/Updated/Toggled/Deleted/Restored`) | ✅ (real source — not the golden `Stored/ToggelStatus` set) |
| Activity table `sys_activity_logs`, issuer `user_id` | ✅ |

## 4. Coverage Completeness

| Metric | Value |
|--------|-------|
| V1 method count | **16** |
| V2 method count | **47** |
| V2 ≥ 2× V1 | ✅ (2.94×) |
| Every TC-ID ↔ ≥1 method | ✅ (see Gap §1 + TcList §3 Index) |
| Every method ↔ TC/BC | ✅ |
| Negative coverage | 100% |
| Positive coverage | 100% |
| Dependency coverage | 100% |
| Tenancy coverage (P1) | 100% |
| Coverage-Score table present | ✅ (Gap §3) |
| Cross-Reference Findings table present | ✅ (Gap §4) |
| Semantic numbering bands + V2 Method Index | ✅ |

## 5. Known Source Defects Documented

| ID | Where documented | Proving test |
|----|------------------|--------------|
| BUG-MSH-003 (ExamGroup edit no model binding) | TcList §1, Gap §4, Manual TC-D06 | V1 `_16`, V2 `_56` |
| SEC-MSH-003 (FormRequest authorize()=true) | TcList BC-AUTH-07, Gap §4, Manual TC-N18 | V1 `_01`, V2 `_53` |
| D39-MSH (MSH permissions unseeded) | This report §6, Manual prereqs, Gap §4 #10 | (env prereq — grant in tests) |
| DEV-MSH-CT-01 candidate (`is_locked` not enforced — BR-MSG-027) | TcList, Gap §4 #7, Manual TC-D08 | V2 `_21` |
| DEV-MSH-CT-02 candidate (store/update no `expectsJson` JSON branch) | TcList, Gap §4 #6 | (documented; observable via 302 on AJAX) |

## 6. Environment Prerequisites (constraints 05_ §E)

- **E19 — Module enabled:** `MarksheetGeneration` must be `true` in `prime_testing/modules_statuses.json` (disabled → 404 on all routes).
- **E20 — `APP_ENV=testing`** for Dusk runs (CSRF bypass; else 419 on state-changing requests). Runners set/expect it.
- **D39-MSH — permissions unseeded:** grant `tenant.msh-config-template.*` + `tenant.msh-configuration.view` to the Dusk admin. Suites call `grantConfigPermissions()` (firstOrCreate permission/role, assign) defensively.
- **Seed data:** ≥1 active academic session (`sch_org_academic_sessions_jnt`); `msh_marksheet_types` / `msh_exam_groups` are created by the suites. `sch_classes`, `sys_dropdown_table`, a 2nd session, and the Spatie factory are optional — dependent tests `markTestSkipped` when absent.
- **Tenant-side scaffolding:** feature lives in `tenant_db` (all `msh_*`); suites use `initializeTenantContext()` via `Modules\Prime\Models\Domain` + guarded `tearDown` (05_ §A).

## 7. Constraints Applied (05_)

- A1–A4 tenancy (tenant-side init, `Domain` resolution, guarded teardown). 
- B5–B10 `App\Models\User` + factory; limited user uses `emp_code` ≤ 20 (`'L'.substr(uniqid(),-12)`), `prefered_language` from `glb_languages`, `user_type='EMPLOYEE'` when column present.
- C11–C13 `forceDelete` wrapped in try/catch; `withTrashed/onlyTrashed` only on `SoftDeletes` model (verified); typed props initialised.
- D14–D18 no Dusk `assertStatus` (uses `sendJsonRequestFromBrowser`); authenticated before mutations; MySQL8 type asserts via `assertStringContainsString`; ENUM/`in:` case (`class`/`group`) matches source.
- E19–E20 documented above.

## 8. Dimensions deliberately limited

- Component-weightage matrix (tables 9–12) excluded — belongs to the **Components** screen.
- Responsive/console-error smoke not added (browser Dusk render smoke covered by combined-page + create-page tests).
- 403 gate tests skip under super-admin/broad-seed bypass (env-dependent); reflection assert in `_53` still proves the gate is the sole enforcer.

## 9. Final Verdict

**PASS WITH NOTES.**

All 8 artifacts present with correct names; both PHP suites `php -l` clean; V2 (47) ≥ 2× V1 (16); every TC mapped; activity events, routes, selectors, permissions, and validation rules sourced from real code. Notes: (1) live execution requires the environment prerequisites in §6 (module enabled, permissions granted, tenant seed) — until then dependent methods `markTestSkipped` rather than fail; (2) two candidate source defects (`DEV-MSH-CT-01` is_locked guard, `DEV-MSH-CT-02` missing JSON branch) are reported as "verify in source" with documenting tests, not asserted as confirmed bugs.
