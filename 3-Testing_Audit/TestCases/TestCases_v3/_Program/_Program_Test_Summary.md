# Prime-AI — Program Test Summary

**Generated:** 2026-Jul-09 17-02 (report mode · program scope · roll-up from existing artifacts only)
**Scope:** all modules with a test-artifact set under `TestCases/` as of this run — **Billing** and **BehaviouralAssessment**. No new suites were generated; this aggregates what exists on disk.
**Companion:** `_Program_Defect_Register.md` (this folder).

---

## 1. Headline metrics

| Metric | Value |
|--------|-------|
| Modules with artifacts | **2** (Billing, BehaviouralAssessment) |
| Feature suites on disk | **15** (14 complete 8-artifact sets + 1 partial: BA `Intervention`, V1/V2 only) |
| Total automated test methods | **904** (V1 = 229, V2 = 675) |
| V2 : V1 ratio (program) | **2.95×** (gate ≥ 2× met on every generated feature) |
| `php -l` clean | **100%** (30/30 PHP files) |
| Static/design validation | **14 / 14** complete features = **PASS WITH NOTES** |
| Suites executed | **0** — execution pending module-enable in `modules_statuses.json` (E19) |
| Runtime pass rate | **Not yet measured** (generation-only per task scope) |

### % automated

- **Billing:** 9 / 9 canonical screens automated = **100%** of the module.
- **BehaviouralAssessment:** 6 / 24 canonical screens generated (5 complete + 1 partial) = **25%** of the module (21% fully complete).
- **Across the two in-scope modules:** 15 / 33 canonical screens = **45%** automated.

### % passing

- **Design gate:** 100% of complete features carry a **PASS WITH NOTES** verdict (all notes are the same class: module-enable prerequisite + generation-only, not test defects).
- **Runtime:** 0% executed. No suite has been run against a live app; all coverage is static (schema-truth asserts, `php -l`, cross-reference scans). Runtime green is unknown until Billing / BehaviouralAssessment are enabled in `prime_testing/modules_statuses.json`.

---

## 2. Per-module breakdown

| Module | Layer | Features | V1 | V2 | ×avg | php -l | Neg cov | Verdict |
|--------|-------|---------:|---:|---:|-----:|--------|---------|---------|
| Billing | `prime_db` central | 9 | 136 | 413 | 3.04× | ✅ 18/18 | 100% | 9/9 PASS w/ notes |
| BehaviouralAssessment | tenant (`ba_*`) | 6 | 93 | 262 | ~2.8× | ✅ 12/12 | 100% | 5/5 complete PASS w/ notes |
| **Program** | — | **15** | **229** | **675** | **2.95×** | **✅ 30/30** | **100%** | **14/14 PASS w/ notes** |

### Billing features (9)

| Feature | V1 | V2 | × | Type |
|---------|---:|---:|--:|------|
| BillingCycle | 13 | 36 | 2.77× | Full CRUD + soft-delete + toggle |
| Subscription | 16 | 43 | 2.69× | Read-only / report + AJAX + PDF |
| Invoicing | 14 | 37 | 2.64× | Composite: generate + list/detail |
| InvoicingPayment | 17 | 43 | 2.53× | Create + cumulative-paid + report |
| ConsolidatedPayment | 16 | 60 | 3.75× | Multi-invoice atomic pay + report |
| PaymentReconciliation | 14 | 41 | 2.93× | Toggle + report/PDF |
| InvoicingAuditLog | 16 | 61 | 3.81× | Append-only + notes + event-info |
| EmailSchedule | 16 | 50 | 3.13× | List/show/cancel + queued job |
| GatewayIntegration | 14 | 42 | 3.00× | Planned/not implemented (gap-focused) |

### BehaviouralAssessment features (6 of 24)

| Feature | V1 | V2 | × | Type | Notes |
|---------|---:|---:|--:|------|-------|
| RatingScale | 16 | 47 | 2.94× | CRUD-master (+ child levels) | complete |
| Category | 17 | 48 | 2.82× | CRUD-master (+ criteria/reorder) | complete |
| ClassMapping | 14 | 35 | 2.50× | Config (junction) | complete |
| Configuration | 15 | 47 | 3.13× | Config (default-scale + thresholds) | complete |
| AssessmentPeriod | 16 | 44 | 2.75× | CRUD-master (+ lock/unlock FSM) | complete; SM 100% |
| Intervention | 15 | 41 | 2.73× | CRUD-master | **partial** — V1/V2 only, no docs/runners |

**Not yet generated (18 BA screens):** Dashboard, MyAssessments, Rating, StudentRemark, ReviewQueue, Incident, Witness, InterventionApplied, ReportsHub, StudentScoresReport, CategorySummary, PeriodReport, AuditTrail, StudentReport, ClassAnalysis, PeriodProgress, CategoryPerformance, IncidentReport. These carry the module's transactional-workflow and reporting risk.

---

## 3. Category coverage (program)

| Category | Billing | BehaviouralAssessment | Program target | Status |
|----------|---------|-----------------------|----------------|--------|
| Negative (`TC-N`) | 100% | 100% | 100% | ✅ met (all generated features) |
| Positive (`TC-P`) | ≥90% (100% on most) | ≥90% | ≥90% | ✅ met |
| Dependency (`TC-D`) | ≥90% (100% on most) | ≥90% | ≥90% | ✅ met |
| State-machine (`BC-SM`) | 100% (EmailSchedule, Invoicing) | 100% (AssessmentPeriod) | 100% where applicable | ✅ met |
| Tenancy (`TC-T`) | N/A (central `prime_db`) | present (`ba_*` tenant) | 100% on P0/P1 tenant modules | ⚠️ verify at runtime |
| Security (`TC-S`) | XSS/IDOR/mass-assign packs present | present | as-applicable | ✅ authored (not run) |

**Semantic numbering bands (WP-G)** are used across the V2 suites (schema 01–09, biz 10–19, SM 20–29, validation 30–39, integration 40–49, auth 50–59, UI 60–69, edge 70–79, config 80–89, tenancy/security 90–99), so the ~675 V2 methods are self-documenting and traceable to their category.

---

## 4. Top program risks

1. **Nothing has been executed** — all 904 methods are static-validated only. The target modules are disabled in `prime_testing/modules_statuses.json` (only `Syllabus` is `true`); every route 404s until enabled (E19). Until a run happens, runtime green is unproven. **Highest program risk.**
2. **Billing P0 schema/data defects still live** — `MIG-BIL-001` (SoftDeletes/timestamps absent from DDL) and `DATA-BIL-001` (audit FK column `tenant_invoice_id` vs DDL `tenant_invoicing_id`) cause CRUD and audit-PDF 500s on a schema-correct prime_db. The dev DB is hand-patched, masking them.
3. **BehaviouralAssessment schema drift (`DOC-BA-001`)** — the consolidated DDL says `bha_*` but the running app uses `ba_*`; every BA suite compensates by asserting `ba_*` and flagging the drift. A DDL re-baseline is needed.
4. **BehaviouralAssessment workflow-integrity P1s** — `BUG-BA-001` (period lock never freezes ratings), `BUG-BA-002` (period FSM violated / `open→closed` unreachable), `SEC-BA-002` (all FormRequests `authorize()=true`), `VAL-BA-001` (core write paths lack FormRequests), `SEC-BA-001` (severe-incident parent notification absent).
5. **Coverage breadth is uneven** — Billing is 100% covered; BehaviouralAssessment is only 25% (6/24). The un-generated BA screens are exactly the highest-risk transactional/report surfaces (Incident, ReviewQueue, Rating, MyAssessments, report export). The 40+ other Prime-AI modules have **no artifacts at all**.
6. **Billing Jun-2026 audit is materially stale** — 9 P0/P1 items already remediated in current source; relying on the raw audit would over-state risk. The register re-baselines it (source-wins).
7. **Test-infra coupling** — Billing suites depend on `preload.php` `class_alias` (filename↔classname mismatch, `05_` #22) and prime host pinned to `127.0.0.1:8000` (`05_` #21); BA is tenant-side and needs tenant init + seeded language/user rows (`05_` #8–10). These are environment prerequisites, documented per feature, not test-code fixes.

---

## 5. Coverage-completeness snapshot

| Dimension | Status |
|-----------|--------|
| All complete features have all 8 artifacts | ✅ 14/14 (Intervention partial: 2/8) |
| Prefix verified against DDL `CREATE TABLE` | ✅ (Billing table-prefix table; BA `bha_` file / `ba_` assert per DOC-BA-001) |
| V2 ≥ 2× V1 | ✅ every generated feature |
| Every TC ↔ ≥1 method; every method ↔ TC/BC | ✅ per each Gap Analysis + V2 Method Index |
| Activity-log strings verbatim from source | ✅ (Billing `bil_..._audit_logs.action_type` + `sys_activity_logs`; BA `ba_audit_log`) |
| Known audit defects captured with proving tests | ✅ where owning feature generated; `Open — pending` otherwise |
| Runtime execution | ❌ not performed (0 suites run) |
| Module breadth | ⚠️ 2 of ~45 modules; BA 6 of 24 screens |

---

## 6. Recommendation

- **Unblock execution:** enable Billing + BehaviouralAssessment in `modules_statuses.json`, set `APP_ENV=testing`, pin the prime host to `127.0.0.1:8000`, seed the BA tenant prerequisites, then run all 15 suites to convert the design-gate PASS into a measured runtime pass rate.
- **Fix the two Billing P0s** (`MIG-BIL-001`, `DATA-BIL-001`) on the canonical DDL before treating Billing as deployable — the dev DB currently hides them.
- **Continue BA generation** through the transactional-workflow group (Incident, ReviewQueue, Rating, MyAssessments, Witness, InterventionApplied) to close the 5 `Open — pending` P1/P2 defects that currently have no proving test.
- **Re-baseline the Billing Jun-2026 audit** to reflect the 9 remediated items.
