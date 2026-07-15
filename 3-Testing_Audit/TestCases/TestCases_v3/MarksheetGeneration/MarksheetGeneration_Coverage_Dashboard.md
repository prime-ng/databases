# MarksheetGeneration (MSH) — Coverage Dashboard

**Generated:** 2026-Jul-10 · **Mode:** report · **Source:** the 5 per-feature Validation Reports + Gap Analyses in this run folder.
**Convention:** ONE comprehensive Dusk file per screen (coverage-gated, not V1/V2-ratio-gated).

## Per-feature coverage

| # | Feature | Type | Test methods | Negative | Positive | Dependency | Tenancy (P0/P1) | `php -l` | Verdict |
|---|---------|------|-------------:|:--------:|:--------:|:----------:|:---------------:|:--------:|---------|
| 1 | ConfigurationTemplates | Composite CRUD | 52 | 100% | 100% | 100% | 100% | clean | PASS (with env-prereq notes) |
| 2 | ComponentsAndWeightages | Composite CRUD | 51 | 100% | 100% | 100% | 100% | clean | PASS (with env-prereq notes) |
| 3 | SchedulingAndLifecycle | Transactional + FSM | 57 | 100% | 100% | 100% | 100% | clean | PASS (with env-prereq notes) |
| 4 | StudentResultsAndPrint | Transactional / results | 57 | 100% | 100% | 100% | 100% | clean | PASS (with env-prereq notes) |
| 5 | Dashboard | Composite / read-focused | 44 | 100%¹ | 100%¹ | 100%¹ | 100% | clean | PASS (composite — no CRUD matrix) |
| | **Module** | | **261** | **100%** | **≥90% met** | **≥90% met** | **100%** | **5/5 clean** | **PASS WITH NOTES** |

¹ Dashboard is a read-focused composite screen: percentages are over the applicable render/navigation/permission/guest/404/dead-API set (no create/edit/delete matrix by design).

## Coverage gate check (targets: Neg 100%, Pos ≥90%, Dep ≥90%, Tenancy 100% on P0/P1)

- Negative 100% — met on all 5.
- Positive ≥90% — met on all 5.
- Dependency ≥90% — met on all 5.
- Tenancy 100% on P0/P1 — met (MSH is P0-bearing; every suite carries tenancy isolation + guarded cross-module skips).
- Every `TC-ID` ↔ ≥1 method; every method ↔ a `TC/BC` with a `Source` tag — asserted in each Gap Analysis (Cross-Reference Findings + Coverage-Score tables present in all 5).

## State-machine coverage (SchedulingAndLifecycle)

`DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED` + UNLOCK. 5 legal transitions (compute/review/publish/lock/unlock) each have a positive test; 4 key illegal transitions (e.g. publish-from-DRAFT, review-from-DRAFT, compute-a-PUBLISHED) each have a negative test. `BC-SM` fully enumerated.

## Defect proof coverage (owned MSH defects)

| Severity | Count | All proven by ≥1 test? |
|----------|------:|------------------------|
| P0 | 1 (BUG-MSH-001) | Yes (3 angles) |
| P1 | 7 (SEC-001/002/003, PERF-001, BR-026/027, D39) | Yes (D39 = documented env prereq) |
| P2 | 5 (BUG-003, PERF-002/003, BR-050, DEP-001) | Yes |
| P3 | 3 (DOC-001, DOC-002, PERF-004) | DOC-001/002 documented; PERF-004 test_45; DOC-002 re-characterized |
| Discovered | 5 (BUG-MSH-101, DEV-C03/C04, REVIEW-GATE-GAP, DOC-003) | Yes |

## Execution status

Not executed in this run (no `execute` flag). Running requires: `MarksheetGeneration: true` in `prime_testing/modules_statuses.json`, `APP_ENV=testing`, a reachable tenant Dusk host, and seed data (active unlocked schedule, class-section, students, valid `sys_dropdown_table` status rows). Data-mutating tests `markTestSkipped()` when dependencies are absent, so partial environments stay green. Defect-proving tests assert **current (buggy) behaviour** with explicit guard messages so they flag rather than silently break once the source is fixed.

## Notable risks / open items

- **P0 dead API (BUG-MSH-001)** and **D39 unseeded permissions** block production per the audit — carried as environment/source facts, not test-code issues.
- **DOC-MSH-002 correction:** real table is `sys_dropdown_table` (rename migration is a no-op). Suites and this run are correct; the audit note and the prior Brijesh precedent are not.
- **SEC-MSH-001/002/003 proving tests assert the defect** and must be inverted when the gates/authorize() are fixed.
