# Activity-Log Audit — Executive Summary

> **App:** Prime AI (multi-tenant K-12 ERP/LMS/LXP) · **Scope:** all `Modules/*/app/Http/Controllers/**/*Controller.php` · **Date:** 2026-07-02
> **Method:** deterministic per-method scan of all 730 controllers (brace-matched method bodies checked for `activityLog(`), cross-validated against grep baselines, enriched with targeted read-only sub-audits of high-risk modules.
> ⛔ **Read-only run.** No code, DDL, migration, or config was changed. Every finding is a recommendation. All reports live in this folder.

---

## 1. Headline

**Activity-log coverage is roughly half-built and heavily skewed away from the highest-risk areas.** The `activityLog()` helper exists and is used correctly in the best modules (GlobalMaster, MarksheetGeneration, Accounting, Cafeteria), but **more than a third of all data-mutating controllers write no audit trail at all**, and the gaps concentrate in exactly the places that matter most for a school ERP: **fees/payments, exam & quiz grades, admissions, and student identity**.

| Metric | Value |
|--------|------:|
| Total controllers scanned | **730** |
| Controllers with mutating methods | **518** (212 are read-only only) |
| Controllers with ≥1 `activityLog()` call | **362** |
| **Fully compliant** (all mutating methods logged) | **216** — 41.7% of mutating controllers |
| **Partially compliant** | **129** |
| **Zero coverage** (mutating, but no logging) | **173** — 33.4% of mutating controllers |
| **Total missing `activityLog()` calls** | **947** |
| — of which 🔴 Critical (money/grades/identity) | **172** |
| — of which 🟠 High (student records/portals/bulk) | **269** |
| — of which 🟡 Medium (operational/master data) | **506** |

> The V1 prompt's "~365 with / ~365 without" was directionally right at the *file* level (362 have at least one call). But counting at the **method** level reveals the real gap: **947 individual mutations go unlogged**, because "partial" controllers (129 of them) log some operations and silently skip others. (Counts reflect standard CRUD methods plus custom methods whose bodies actually persist data; pure helper methods are excluded.)

---

## 2. Compliance Leaderboard

**Best (log everything they mutate):**
| Module | Ctrls | Full | Missing |
|--------|:---:|:---:|:---:|
| MarksheetGeneration | 21 | 17 | **0** |
| Cafeteria | 16 | 11 | **0** |
| EventEngine | 4 | 3 | 0 |
| Ptm | 11 | 8 | 1 |
| Recommendation | 10 | 7 | 3 |
| Accounting | 21 | 15 | 6 |
| StudentFee | 15 | 9 | 10 |
| Transport | 31 | 14 | 14 |

**Worst (large surface, little/no logging):**
| Module | Ctrls | Zero-coverage | Missing calls |
|--------|:---:|:---:|:---:|
| SchoolSetup | 60 | 24 | **131** |
| Hostel | 53 | 16 | **112** |
| Inventory | 22 | 15 | **79** (0 fully compliant) |
| FrontOffice | 21 | 3 | **59** |
| BehaviouralAssessment | 12 | 8 | **49** (0 fully compliant) |
| Library | 42 | 8 | 49 |
| TimetableFoundation | 26 | 4 | 40 |
| Notification | 12 | 7 | 38 |
| Prime | 22 | 6 | 34 (roles/identity) |
| Certificate | 10 | 7 | 28 (0 fully compliant) |

---

## 3. The Ten Most Important Gaps (🔴 Critical)

1. **StudentPortal — payments & grades entirely unlogged.** Web layer has **1** `activityLog()` call in 41 mutating methods (~2.4%); mobile layer has **0** in 19 controllers. Razorpay fee `initiate`/`callback` and exam/quiz/quest `submit` (grade writers) produce **no central audit entry**. *(Partial mitigation: `PaymentService` writes `ptm_*` rows; attempts write domain `AttemptActivityLog` tables — but nothing reaches `sys_activity_logs`.)*
2. **StudentFee** — 10 missing calls incl. invoice/payment deletes and adjustments; financial mutations must be fully traceable.
3. **Accounting** — 6 missing incl. a zero-coverage controller posting/altering ledger data (otherwise strong — 15/21 full).
4. **LmsExam / LmsQuiz / LmsQuests** — grade and attempt mutations with missing/partial logging (13 + 3 + 5 missing); plus the StudentPortal `submit` grade-writers below.
5. **Admission** — 33 missing across 18 controllers; admitting/rejecting/enrolling students (identity + eligibility) largely unlogged.
6. **StudentProfile** — 11 missing, **0 fully compliant controllers**; identity/PII record edits and deletes.
7. **Certificate** — 28 missing, **0 fully compliant**; credential issuance/revocation unlogged.
8. **BehaviouralAssessment** — 49 missing, **0 fully compliant controllers**; sensitive student behavioural data.
9. **Prime / HrStaff** — role/permission/staff-identity mutations (34 + 10 missing) — **access-control changes with no audit trail**.
10. **Inventory** — 79 missing, **0 fully compliant** (operational, but a large unlogged surface). *(Note: Hpc, previously suspected, is actually mostly compliant — 4 full / 3 missing.)*

Full ranked list in `04_SENSITIVE_OPERATIONS.md`; every individual gap in `02_MISSING_CALLS.md`.

---

## 4. Correctness (not just presence)

Where calls *do* exist, they are mostly **structurally correct** (the codebase follows the canonical `CityController` pattern — correct model subject, sensible event name). The dominant failure mode across the app is **total absence, not misuse**. However, three correctness/design risks recur and are detailed in `03_CORRECTNESS_FINDINGS.md`:
- **`update()` without before/after diff** — many `update()` methods that *do* log pass only a static `message`, losing the "what changed" value the `CityController` pattern captures via `getOriginal()`/`getChanges()`.
- **Silent null-subject skips** — the helper returns `null` and logs nothing if `$subject` is null; any call whose subject can be null is a latent silent gap.
- **Downstream-only logging** — some controllers delegate mutation to services/jobs that keep their *own* domain tables but never write `sys_activity_logs`, so the central audit trail has holes even where "an audit exists somewhere."

> **Scope honesty:** a full line-by-line correctness pass on all 362 controllers that already log was **not** completed for every module (audit sub-agents were interrupted by service limits). The presence matrix (§1, `01_`, `02_`) is complete and deterministic; the correctness findings (`03_`) are based on the canonical pattern + sampled high-risk modules and should be treated as representative, not exhaustive. Re-running the correctness pass is the top follow-up.

---

## 5. Non-Controller Surfaces

Data also mutates outside controllers, and those paths are largely unlogged — see `05_NON_CONTROLLER_SURFACES.md`. Confirmed example: **`SyllabusBooks\BookFileService`** (`attach`/`markPrimary`/`delete`) mutates files with no `activityLog()`, and its controller delegates to it. Model observers, jobs, console commands (cron status changes), and raw `DB::`/mass-Eloquent updates are the blind spots that controller-only auditing misses.

---

## 6. Five Headline Recommendations (detail in `06_REMEDIATION_PLAN.md`)

1. **Close the 🔴 172 critical gaps first** — fees, payments, grades, admissions, identity, roles. These are compliance-and-forensics essentials.
2. **Adopt a base-controller / trait or model-observer logging layer** so coverage is structural, not per-method discipline (the reason 129 controllers are "partial").
3. **Standardize `update()` logging on the `CityController` before/after-diff pattern.**
4. **Harden the helper** against silent null-subject skips (log a warning) and add a PII redaction guard for `properties`.
5. **Extend logging to non-controller mutation surfaces** (services, jobs, observers, cron).

---

## 7. Report Index
- `01_COVERAGE_BY_MODULE.md` — per-module coverage matrix (every controller × method).
- `02_MISSING_CALLS.md` — all 947 missing calls, risk-tiered.
- `03_CORRECTNESS_FINDINGS.md` — quality issues in existing calls.
- `04_SENSITIVE_OPERATIONS.md` — 🔴/🟠 gaps ranked by blast radius.
- `05_NON_CONTROLLER_SURFACES.md` — observers/jobs/services/cron gaps.
- `06_REMEDIATION_PLAN.md` — phased, recommendation-only fix plan.

*Deterministic scan complete for all 730 controllers. Read-only — no application code was modified.*
