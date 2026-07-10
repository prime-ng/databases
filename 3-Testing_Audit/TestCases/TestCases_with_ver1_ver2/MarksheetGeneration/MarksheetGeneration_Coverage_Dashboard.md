# MarksheetGeneration (MSH) — Coverage Dashboard

**Generated:** 2026-Jul-09 · **Mode:** report (module roll-up) · **Run folder:** `TestCases/MarksheetGeneration/`
**Registry:** MODULE_NAME=MarksheetGeneration · CODE=MSH · PREFIX=`msh_` · FOLDER_NAME=MarksheetGeneration · DDL=`MarksheetGeneration_DDL_v1.sql`
**Style:** browser-Dusk (golden `Class` fallback — no committed MSH sibling) · **DB scope:** tenant-side (`Database: tenant_db`, all `msh_*`)

## Per-feature coverage

| Feature | Screen file | Primary table | #V1 | #V2 | V2:V1 | Neg | Pos | Dep | SM | Verdict | php -l |
|---------|-------------|---------------|-----|-----|-------|-----|-----|-----|----|---------| ------ |
| ConfigurationTemplates | 02-Configuration-Templates.md | `msh_config_templates` | 16 | 47 | 2.94× | 100% | 100% | 100% | n/a | PASS w/ notes | clean |
| ComponentsAndWeightages | 03-Components-and-Weightages.md | `msh_template_scholastic_components` | 20 | 50 | 2.50× | 100% | 100% | 100% | n/a | PASS w/ notes | clean |
| SchedulingAndLifecycle | 04-Scheduling-and-Lifecycle.md | `msh_marksheet_schedules` | 18 | 56 | 3.11× | 100% | 100% | 100% | 100% | PASS w/ notes | clean |
| StudentResultsAndPrint | 05-Student-Results-and-Print.md | `msh_student_results` | 16 | 57 | 3.56× | 100% | 100% | 100% | 100% | PASS w/ notes | clean |
| Dashboard | 01-Dashboard-and-Navigation.md | (aggregates `msh_*`) | 17 | 44 | 2.59× | 100% | 100% | 100% | n/a | PASS w/ notes | clean |
| **TOTAL** | **5 screens** | — | **87** | **254** | **2.92× avg** | **100%** | **100%** | **100%** | **100%** | **5× PASS w/ notes** | **10/10 clean** |

Coverage targets met on all features: Negative 100%, Positive ≥ 90% (100%), Dependency ≥ 90% (100%), Tenancy 100% (P1 module). Every feature's Gap Analysis carries a Coverage-Score table + the 11-check Cross-Reference Findings scan; every BC/TC carries a Source tag; V2 methods follow the semantic numbering bands.

## Quality-gate summary (all features)

- [x] 8 artifacts per feature (40 files total) + module Feature Inventory + this Dashboard + RTM.
- [x] Prefix `msh_` verified against DDL `CREATE TABLE` for every primary table.
- [x] `php -l` clean on all 10 PHP suites (V1+V2 × 5).
- [x] V2 ≥ 2× V1 on every feature (min 2.50×, max 3.56×).
- [x] Activity-log event strings taken verbatim from real source (per feature — see note below).
- [x] Cross-module paths guarded with `markTestSkipped` (StudentPortal precheck import, lms_exam_types, seed data).
- [x] Audit defects mapped as proving tests; new candidates flagged "verify in source".
- [x] `05_` constraints obeyed; one new rule (#23) appended (see Program note).

## Environment prerequisites (documented in every Validation Report — NOT test-code fixes)

1. **MarksheetGeneration must be enabled** in `prime_testing/modules_statuses.json` (currently `false` → all routes 404). (E19)
2. **`APP_ENV=testing`** for Dusk runs (CSRF bypass; the runners set it). (E20)
3. **D39-MSH:** MSH permissions are NOT seeded in `TenantRolePermissionSeeder` — all 18 policy-protected resources are super-admin-only. Gate tests grant `tenant.msh-*` explicitly in `setUp`; live runs need the seeder fixed.
4. Tenant seed data (status dropdowns in `sys_dropdowns`, config-template / academic-session / class / section / subject / student rows) — dependency tests `markTestSkipped` when absent.

## Per-module activity-log / gate note (verified in source, varies by controller)

The workers asserted the **real** strings from each controller/service — do not assume uniformity:
- CRUD masters: `activityLog($m, 'Stored'|'Updated'|'Deleted'|'Toggled'|'Restored', ...)`.
- StudentResult adds `Withheld` / `Declared`; MarksheetSchedule lifecycle adds `Reviewed` / `Published` / `Unlocked` / `Locked` / `ComputeDispatched`, plus `msh_computation_logs.action` ∈ `COMPUTE/REVIEW/PUBLISH/UNLOCK/LOCK`.
- Combined-page gates are non-entity: `tenant.msh-{dashboard|configuration|components|scheduling|results}.view`.
- Entity gates: `tenant.msh-{entity}.{viewAny|view|create|update|delete|restore|forceDelete}`.

## Open defects (audit-confirmed + newly discovered) — see Defect Register below in RTM

| Code | Sev | Status | Owning feature | Proving test |
|------|-----|--------|----------------|--------------|
| BUG-MSH-001 | P0 | audit-confirmed | Dashboard | V1 test_13; V2 test_58/59/72 |
| SEC-MSH-001 | P1 | audit-confirmed | StudentResultsAndPrint | V2 test_51 |
| SEC-MSH-002 | P1 | audit-confirmed | StudentResultsAndPrint | V2 test_52 |
| SEC-MSH-003 | P1 | audit-confirmed (systemic 19/19) | ALL | per-feature FormRequest tests |
| PERF-MSH-001 | P1 | audit-confirmed | SchedulingAndLifecycle | V2 test_74 (soft) |
| BR-MSH-026 | P1 | audit-confirmed | SchedulingAndLifecycle | V2 test_29 |
| BR-MSH-027 | P1 | audit-confirmed | SchedulingAndLifecycle | V2 test_71 |
| D39-MSH | P1 | audit-confirmed (env) | ALL | documented + explicit grant |
| BUG-MSH-003 | P2 | audit-confirmed | ConfigurationTemplates | V1 test_16; V2 test_56 |
| PERF-MSH-002 | P2 | audit-confirmed | SchedulingAndLifecycle | V2 test_73 |
| PERF-MSH-003 | P2 | audit-confirmed | StudentResults / Dashboard | V2 test_46 |
| BR-MSH-050 | P2 | audit-confirmed | Components / Scheduling | V2 test_72 |
| DEP-MSH-001 | P2 | audit-confirmed | SchedulingAndLifecycle | V1 test_16 / V2 test_44 (guarded) |
| DOC-MSH-002 | P3 | audit-confirmed | SchedulingAndLifecycle | V1 test_01 / V2 test_02 |
| PERF-MSH-004 | P3 | audit-confirmed | StudentResults / Scheduling | V2 test_45 |
| **BUG-MSH-101** | **P1** | **NEW — verify in source** | **SchedulingAndLifecycle** | V1 test_18; V2 test_04/16 — `ScheduleClass` model omits `SoftDeletes` though migration declares `softDeletes()` and controller/service call `withTrashed()/restore()` → `BadMethodCallException` on schedule create/update with class-sections (audit D38 missed this) |
| **DEV-MSH-CT-01** | **P2** | **NEW — verify in source** | **ConfigurationTemplates** | V2 test_21 — BR-MSG-027 `is_locked` immutability guard not implemented; locked config-template still mutable |
| **BUG-MSH-C01** | **P2** | **NEW — verify in source** | **ComponentsAndWeightages** | V2 test_80 — scholastic `store()` bypasses weightage-sum service (BR-MSG-002 unenforced on create) |
| **BUG-MSH-C02** | **P2** | **NEW — verify in source** | **ComponentsAndWeightages** | V2 test_82/83 — `validateExamWeightageSum()` is dead code (BR-MSG-003 never enforced) |
| **BUG-MSH-C03** | **P3** | **NEW — verify in source** | **ComponentsAndWeightages** | V2 test_81 — weightage-sum violation → uncaught `DomainException` → HTTP 500 (not 422) |
| **BUG-MSH-C04** | **P3** | **NEW — verify in source** | **ComponentsAndWeightages** | V2 test_72 — coscholastic `grading_scale` has no `in:` enum rule; arbitrary values accepted |
| **DEV-MSH-CT-02** | **P3** | **NEW — verify in source** | **ConfigurationTemplates** | Gap §4 — ConfigTemplate store/update lack `expectsJson()` branch (AJAX gets 302, never JSON) |
| **BUG-MSH-101 (SR)** | **P3** | **NEW — verify in source** | **StudentResultsAndPrint** | inconsistent index ability naming across sibling controllers (`.viewAny` vs `.view`); verify seeder defines all |

> All NEW items are flagged **"verify in source"** with a documenting/proving test asserting current behaviour — none are asserted as confirmed bugs. They should be confirmed by a source owner before promotion to registered defects.
