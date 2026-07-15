# Interventions — Validation Report (`bha_InterventionValidation_Report.md`)

**Feature:** Intervention (BehaviouralAssessment) · **Generated:** 2026-Jul-11
**Test file:** `bha_Intervention_TestCas.php` (single comprehensive Dusk suite, **48 methods**)

---

## 1. File Existence Summary

| # | Artifact | Present |
|---|----------|---------|
| 1 | `bha_InterventionTcList_Require.md` | ✅ |
| 2 | `bha_InterventionMANUALTESTING_Require.md` | ✅ |
| 3 | `bha_InterventionGAPANALYSIS_Require.md` | ✅ |
| 4 | `bha_Intervention_TestCas.php` | ✅ (pre-existing, unmodified) |
| 5 | `bha_InterventionValidation_Report.md` | ✅ (this file) |
| 6 | `run-Intervention-tests.ps1` | ✅ |
| 7 | `run-Intervention-tests.sh` | ✅ |

All 7 artifacts present in `TestCases/BehaviouralAssessment/Intervention/`. Exactly ONE `.php` test file (no V1/V2 split).

---

## 2. Naming Conventions

| Check | Result |
|-------|--------|
| File prefix `bha_` (filename convention) | ✅ — retained per instruction; **note:** the live runtime table is `ba_interventions` (`ba_` prefix). The DDL doc uses `bha_`; divergence is **DOC-BA-001**, proven by `_02`. |
| Feature name PascalCase (`Intervention`) | ✅ |
| Class = filename (`bha_Intervention_TestCas`) | ✅ |
| snake_case, banded method names (`test_intervention_NN_*`) | ✅ |
| Namespace `Tests\Browser` | ✅ |

---

## 3. Structure Validation

| Check | Result |
|-------|--------|
| `extends DuskTestCase` | ✅ |
| `setUp()` / `tearDown()` with tenancy init/guarded end | ✅ (`initializeTenantContext()`; `tenancy()->end()` guarded) |
| Typed properties initialized (`?User $adminUser = null`, string defaults) | ✅ |
| Private helper library (screenshots, browser JSON shim, seed/cleanup, auth/tenancy, source resolution) | ✅ |
| `php -l` syntax | ✅ clean (file pre-verified; not modified by this run) |

---

## 4. Coverage Completeness

- **Total methods:** 48.
- **Per category:** Config 3 · Positive 13 · Negative 17 · Dependency 8 · State-machine 2 · Tenancy 2 · Security 3 (overlap where a method proves both a rule and a documented defect).
- **Coverage gates:** Negative **100%** · Positive **100%** (≥ 90%) · Dependency **100%** (≥ 90%) · Tenancy **100% mapped** (isolation `_91` env-gated skip) on this P1 tenant feature.
- **Traceability:** every TC-ID ↔ ≥1 method; every method ↔ a TC/BC (see TcList §3 and Gap Analysis §1). No V1/V2 ratio to satisfy.
- **Semantic bands:** methods follow the 01–09/10–19/20–29/30–39/40–49/50–59/60–69/70–79/90–99 scheme; Test Method Index records each band.

---

## 5. Known Source Defects Documented

Documented in TcList §2 and Gap Analysis §4 with proving methods:
DOC-BA-001 (`_02`), INT-GAP-01 (`_03`), INT-GAP-02 (`_01`/`_32`), INT-GAP-03 (`_03`), BUG-BA-010 (`_16`), VAL-BA-003 (`_39`), DATA-BA-002 (`_21`), BUG-BA-005 (`_43`), INT-OBS-01 (`_45`), SEC-BA-002 (`_92`).

---

## 6. Environment Prerequisites (must hold before running)

1. **BehaviouralAssessment module ENABLED** in `prime_testing/modules_statuses.json` (currently most modules are `false`; a disabled module returns **404 on every route** — this is an environment prerequisite, NOT a test-code fix — constraint E19).
2. `APP_ENV=testing` so Dusk bypasses CSRF (else 419 on state-changing requests — constraint E20). The runners set this.
3. Tenant domain resolvable from `DUSK_TENANT_URL` (`http://test.localhost:8000`) with admin `DUSK_ADMIN_EMAIL`/`DUSK_ADMIN_PASSWORD` (`root@tenant.com` / `password`).
4. `prime_ai` cloned alongside `prime_testing` with `MAIN_PROJECT_PATH` set (source-text asserts in `_01`/`_03`/`_54`/`_92` resolve the app repo via reflection and fail-soft `markTestSkipped` if unreadable — constraint #29/#32).
5. A valid `glb_languages` row for the `prefered_language` FK used when building the limited authorization user (constraint #10).
6. Cross-module paths (`ba_incidents`, junction) may be absent → those methods self-skip (constraint 9).

---

## 7. Constraints That Shaped the Tests

- Tenant-side scaffolding only (`ba_` prefix, `tenant_db`) — A1–A4.
- `App\Models\User` + `User::factory()` for the limited user, with `user_type`/`emp_code` set conditionally and `is_super_admin`/`super_admin_flag` cleared + roles/permissions synced empty so the negative-auth tests don't false-pass via `Gate::before` (constraints B5–B9, #31).
- MySQL 8 `COLUMN_TYPE` variance → `assertStringContainsString` on schema types; ENUM asserted case-sensitively (#17/#18).
- `Browser` has no `assertStatus()` → status codes obtained via an in-page authenticated `fetch()` shim (`sendJsonRequestFromBrowser`) (#14).
- `forceDelete()` cleanup wrapped in `try/catch`; junction rows detached first to avoid RESTRICT blocking cleanup (#11/#12).
- App source text asserted via `ReflectionClass(BaIntervention::class)` path resolution, fail-soft when unreadable (#29/#32).

---

## 8. Final Verdict

**PASS WITH NOTES.**

- All 7 artifacts present; the pre-existing `.php` (48 methods) was left **unmodified** and is `php -l` clean.
- Docs are consistent 1:1 with the 48 methods.
- Notes: (a) filename prefix `bha_` is intentionally retained though the live table is `ba_` (DOC-BA-001); (b) `_91` cross-tenant isolation and the junction-dependent methods self-skip in partial environments by design; (c) the feature emits no activity log — asserted as a documented absence, not a gap; (d) module must be enabled in `modules_statuses.json` before execution.
