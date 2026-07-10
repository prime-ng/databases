# Prime-AI — Testing Strategy Report

**Version:** 1.0
**Date:** 2026-07-09
**Author:** Testing Architecture
**Scope:** End-to-end functional and non-functional test coverage for all 45 modules of the Prime-AI school-management platform, delivered as reproducible artifacts via the `prime_testing` Laravel Dusk runner.
**Companion docs:** `00_..._Conventions.md` (conventions), `02_Testing_Plan.md` (execution), `03_..._Agent_Prompt.md` (automation).

---

## 1. Executive Summary

Prime-AI is a large, multi-tenant (per-school), module-based Laravel application (45 modules, hundreds of CRUD features, deep cross-module referential integrity). Manual testing at this scale is not repeatable and does not survive refactors. Our strategy is to **generate a complete, traceable, self-verifying test artifact set per feature**, driven by an AI agent (`Testcase_Creator`) that consumes the existing knowledge base (Requirements, FRDs, DDLs, Audit reports, and application code) and emits browser-level Dusk tests plus their supporting documentation.

The proven pattern already exists: the **`Class&SubjectMgmt/Classes`** feature (golden reference) and the **23 `HrStaff` features** demonstrate the 8-artifact model achieving **~96% traceable coverage** (78 automated methods against 81 manual test cases for a single feature). This report formalises that pattern into a repeatable strategy and extends it with additional test dimensions and reporting.

---

## 2. Goals & Non-Goals

**Goals**
1. **Traceable coverage** — every requirement/FRD line and every DDL constraint maps to at least one executable assertion.
2. **Repeatability** — any engineer (or CI) can regenerate and re-run a feature's suite deterministically.
3. **Self-verification** — each feature ships a Validation Report that gates its own quality.
4. **Defect surfacing** — tests document (not hide) known source defects from the audit reports as `DEV-###` items.
5. **Scale** — a single agent invocation produces a full feature suite; a module is a batch of invocations.

**Non-Goals (this phase)**
- Unit-level testing of pure helpers (covered opportunistically inside V1 config tests, not a separate suite).
- Performance/load benchmarking at production scale (we do lightweight smoke timing only — §6.7).
- Visual pixel-diff regression (screenshots are captured as evidence, not asserted pixel-by-pixel).

---

## 3. Test Pyramid & Where We Invest

```
          ┌─────────────────────────────┐
          │  E2E Browser (Dusk V2)      │  ← PRIMARY investment: full UX + integration + cross-module
          ├─────────────────────────────┤
          │  Integration (Dusk V1)      │  ← schema/model/request config + endpoint + core CRUD
          ├─────────────────────────────┤
          │  Contract/API assertions    │  ← JSON endpoints, status codes, payload shape (inside V1/V2)
          ├─────────────────────────────┤
          │  Static/config assertions   │  ← migration content, fillable, soft-deletes, indexes (test_01)
          └─────────────────────────────┘
```

Because the app is UI-heavy (modal + AJAX CRUD), **the browser layer is where behaviour actually lives**, so it is where we invest. V1 is the fast, foundational guard (schema truth + core flows); V2 is the exhaustive behavioural suite.

---

## 4. Coverage Model — the Two-Tier V1/V2 Split

| Tier | Role | Typical size | Content |
|------|------|-------------|---------|
| **V1** | Foundation / smoke | 15–20 methods | `test_01` = migration + model + FormRequest config truth; then core create/edit/delete/toggle/view, key validations, JSON endpoints, breadcrumbs, activity-log issued-by checks |
| **V2** | Comprehensive | ≥ 2 × V1 (commonly 70+) | Every `TC-P##`, `TC-N##`, `TC-D##`; full negative matrix; all FK integrity paths; cross-module auto-updates; lifecycle; concurrency/race; button-visibility per permission; guest redirect; XSS/whitespace |

**Why two tiers:** V1 gives a cheap, fast confidence gate suitable for pre-commit / CI-lite. V2 is the release gate. The Gap Analysis document reconciles the two against the manual test list and reports a coverage percentage per category.

---

## 5. Test Dimensions (the "what we assert")

Each feature is attacked along these dimensions, sourced from the BC taxonomy (§6 of the Conventions doc):

1. **Schema truth** — table exists, columns/types, unique indexes, soft-deletes, FK onDelete behaviour (from DDL).
2. **Validation** — required/format/max-length/range/uniqueness/cross-field rules + exact error messages (from FormRequest).
3. **Authorization** — permission gate per controller method; 403 for missing permission; button visibility per role; guest → login redirect.
4. **Business logic** — auto-ordinal, auto-name generation, default flags, checkbox normalisation, status toggle, drag-reorder, modal reset, toast/SweetAlert flows.
5. **Persistence & audit** — DB row assertions after each mutation; activity-log event + `issued_by`/user_id correctness (incl. the `ToggelStatus` typo).
6. **Referential integrity** — RESTRICT blocks, SET NULL nullifies, restore does not recover SET NULL, force-delete cascade.
7. **Cross-module** — model-event auto-updates (e.g. student count), impact on dropdowns/timetable/subject-groups; defensively skipped when the dependency module is absent.
8. **Lifecycle & concurrency** — full CRUD lifecycle in one flow; rapid toggle race; concurrent edit last-write-wins.

---

## 6. Additions Beyond the Sample (Strategy Enhancements)

The golden reference is strong on functional coverage. This strategy **adds** the following dimensions and artifacts to make application testing complete. These are opt-in per feature (the agent adds a dedicated section/method block when applicable):

### 6.1 Tenancy Isolation Suite (HIGH PRIORITY — app-critical)
Because the app is multi-tenant, the highest-severity latent bug class is **cross-tenant data leakage**. Add a `TC-T##` (Tenancy) category:
- Records created in Tenant A are invisible to Tenant B (index, search, direct `view/{id}`).
- Direct-ID access across tenants returns 404, not another tenant's data (IDOR guard).
- Unique constraints are scoped per tenant (same code allowed in two tenants).
- Permission/role resolution is tenant-scoped.

### 6.2 Security Test Pack (`TC-S##`)
Extend beyond the sample's single XSS case:
- **XSS** (stored + reflected) in every free-text field; assert Blade `{{ }}` escaping.
- **IDOR / authorization bypass** — access another user's/tenant's resource by ID.
- **Mass-assignment** — post unexpected fields (e.g. `is_active`, `id`, FK columns) and assert they're ignored (fillable guard).
- **CSRF** — state-changing endpoints reject missing/invalid token.
- **SQL-injection-shaped input** in search/filter params — assert parameterised safety (no 500, no leak).
- **File-upload** (where applicable) — type/size/extension validation, path traversal in filename.

### 6.3 API / Contract Assertions (formalised)
Where a feature exposes JSON endpoints (`show`, reorder, toggle, dropdown data), assert **status code + payload shape + required keys** explicitly, so a controller refactor that changes the contract fails a test. (Already partially present in V1 `show` tests; make it a consistent block.)

### 6.4 Accessibility & UX Smoke (`TC-A##`, lightweight)
- Form labels/`for` associations present; required fields marked; primary action reachable by keyboard.
- Table has header row; empty-state ("No Data Found") renders.
- No console JS errors during the happy path (Dusk captures console logs already — assert none at `SEVERE`).

### 6.5 Responsive Smoke
- Render index + create modal at a mobile viewport (e.g. 390×844) and assert the primary controls are present/interactive (not a full visual audit — a "does it break" guard).

### 6.6 Regression Tagging & Suites
- Tag methods by category via method-name prefix (already implicit) so runners can filter `--filter` by category (positive/negative/dependency/security/tenancy/smoke).
- A **module-level smoke suite** (V1 only) for fast CI; a **full suite** (V1+V2) for release.

### 6.7 Non-Functional Smoke Timing
- Capture wall-clock for index load and create round-trip; log (not hard-assert) with a soft threshold so gross regressions are visible in the proof file.

### 6.8 Reporting Artifacts (new, roll-up level)
Beyond per-feature files, produce module- and program-level roll-ups (see §8):
- **Module Coverage Dashboard** — per feature: #V1, #V2, coverage %, pass/fail, open DEV-### defects.
- **Requirement Traceability Matrix (RTM)** — Requirement/FRD ID → BC → TC → method → status.
- **Defect Register** — consolidated `DEV-###` from audit reports + newly discovered, with severity and the test that proves them.
- **Program Test Summary** — one page: total features, % automated, % passing, top risks.

---

## 7. Risk-Based Prioritisation

Not all modules carry equal risk. Prioritise generation/execution by a simple risk score = **(data-sensitivity × cross-module-fan-out × change-frequency)**:

| Tier | Modules (examples) | Rationale |
|------|--------------------|-----------|
| **P0 — Money & Identity** | Accounting, Billing, Payment, StudentFee, HrStaff/Payroll | Financial correctness + audit/compliance; highest blast radius |
| **P1 — Core academic spine** | SchoolSetup (Class/Section/Subject), StudentProfile, Admission, Timetable(s), LmsExam, MarksheetGeneration | Everything else references these; FK RESTRICT/SET NULL hotspots |
| **P2 — Engagement & ops** | LmsHomework/Quiz/Quests, Library, Hostel, Transport, Inventory, Cafeteria, PTM, Complaint, Notification | High feature count, moderate blast radius |
| **P3 — Supporting / read-mostly** | Dashboard, Feedback, Documentation, ParentPortal, StudentPortal, GlobalMaster, SystemConfig | Lower risk or largely composite/read views |

Audit reports (`AUDIT_REPORT_DIR`) feed this: any module with documented `DEV-###` defects is escalated so the tests **prove the defect** and later prove the fix.

---

## 8. Reporting & Metrics

**Per feature (in the 8 artifacts):** coverage % by category (Gap Analysis), pass/fail (runner proof file), self-validation verdict (Validation Report).

**Roll-ups (produced by the agent in `report` mode, §6.8):**
- **Coverage Dashboard** (`_MODULE_Coverage_Dashboard.md`) per module.
- **RTM** (`_MODULE_RTM.md`) per module.
- **Defect Register** (`_Program_Defect_Register.md`) program-wide.
- **Program Test Summary** (`_Program_Test_Summary.md`).

**Key metrics tracked over time:**
- Features with full 8-artifact set / total features.
- Automated methods count; V2/V1 ratio compliance.
- Category coverage % (target: Positive ≥ 90%, Negative = 100%, Dependency ≥ 90%, Tenancy = 100% on P0/P1).
- Pass rate; open vs proven-and-fixed DEV defects.

---

## 9. Test Environment & Data Strategy

- **Isolation:** dedicated `test_runner_db`; tenancy initialised/ended per test (`initializeTenantContext()` / `tenancy()->end()`), so tests never touch dev data.
- **Data:** self-seeding via typed builder helpers (`createXSeed()`, `buildValidStorePayload()`), **unique-suffix generators** (`uniqueClassCode()`, `uniqueSuffix()`) to avoid collisions across parallel runs; force-delete cleanup of seeds in the same test.
- **Determinism:** no reliance on pre-existing tenant data beyond the admin user; dependencies resolved or the test is `markTestSkipped()`.
- **Evidence:** per-feature `dusk-report/{screenshots,console,source}` auto-captured on pass and failure via base-class routing; runner writes a timestamped `proof/dusk_run_*.txt`.
- **Browser:** headless Chrome via managed ChromeDriver; runner can auto-start the PHP dev server on the tenant port.

---

## 10. Tooling & Automation

- **`Testcase_Creator` agent** (see `03_`): the primary generator. Input = a module/feature + the knowledge-base paths; output = the 8 artifacts (+ roll-ups in report mode).
- **Runners:** `run-{Feature}-tests.ps1` (Windows) and `run-{Feature}-tests.sh` (Linux/WSL) — filtered Dusk execution, result parsing, proof capture.
- **CI hook (recommended):** V1 suites on every PR (fast gate); full V1+V2 nightly per module; roll-up dashboards published as build artifacts.
- **Self-check:** Validation Report + `php -l` syntax lint as a pre-merge gate for generated PHP.

---

## 11. Definition of Done (per feature)

A feature is "test-complete" when **all** hold:
1. All 8 artifacts exist and pass the Validation Report checklist.
2. `php -l` passes on both PHP files; both extend `DuskTestCase`, namespace `Tests\Browser`.
3. V2 count ≥ 2 × V1; every TC-ID maps to a method and vice-versa.
4. Negative coverage = 100%; Positive ≥ 90%; Dependency ≥ 90%.
5. Tenancy suite present & passing (P0/P1 modules).
6. Known audit defects captured as `DEV-###` in TcList + Gap Analysis, each with the test that exercises them.
7. A green (or documented-known-fail) runner proof file exists.

---

## 12. Risks to the Strategy & Mitigations

| Risk | Mitigation |
|------|-----------|
| Source code drift vs generated tests | Regenerate on refactor; `test_01` config assertions fail fast when schema/request change |
| Flaky browser tests (timing) | Explicit waits in helpers, unique data, headless stability flags already in `DuskTestCase` |
| Missing dependency modules in env | Defensive `try/catch + markTestSkipped()` for cross-module paths |
| Agent hallucinating selectors/routes | Agent MUST read actual controller/route/Blade in `APP_CODE_DIR` before asserting; never invent selectors |
| Prefix/schema guesswork | Prefix resolved from actual DDL `CREATE TABLE`, not the registry table alone |
| Volume (45 modules) overwhelming review | Risk-tiered rollout (§7) + per-feature Validation Report as the review unit |
```
