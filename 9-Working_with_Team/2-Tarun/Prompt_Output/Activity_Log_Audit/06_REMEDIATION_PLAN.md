# 06 · Remediation Plan (Recommendations Only)

> A phased plan to close the activity-log gaps. **Every item is a recommendation — nothing here has been applied.** Implementation is a separate, explicitly-approved effort.
> Baseline: 518 mutating controllers · 216 full / 129 partial / 173 zero · 947 missing controller calls (🔴 172 / 🟠 269 / 🟡 506) + large non-controller blind spots.

---

## Strategic choice first: per-method vs. structural

The reason 129 controllers are **partial** (log some mutations, miss others) is that logging is **manual and per-method** — it depends on every developer remembering. Two ways forward:

**Option A — Manual per-method (what exists today).** Add `activityLog()` to each missing method. Precise control over event/properties, but 947+ edits and it will drift again.

**Option B — Structural (recommended core).** Add a **generic logging layer** so coverage is automatic:
- A **model observer / `LogsActivity` trait** on audited models logs `created`/`updated`/`deleted` centrally (captures controllers, observers, and services that use Eloquent — closes the majority at once).
- Keep **manual** `activityLog()` only for custom domain events that model events can't express (e.g. `markAsPaid`, `approveAdmission`, `submitExam`) and to enrich `properties`.
- Add a **job/cron logging convention** (system actor when `Auth::id()` is null) for async/scheduled mutations.
- **Manually flag** the 502 raw `DB::table()`/mass-`update()` sites in 🔴 modules (these bypass model events and can't be auto-caught).

**Recommendation:** Option B for breadth + Option A for the 🔴 custom operations. This converts "coverage by discipline" into "coverage by architecture."

---

## Phased rollout

### Phase 0 — Harden the helper (days) — foundational
- Make `activityLog()` **not fail silently**: when `$subject === null`, log a warning (so C2 silent skips surface).
- Add a **PII/secret redaction guard** for `properties` (whitelist or key-denylist) — protects Admission/StudentProfile/StudentFee/Payment (finding C5).
- Publish a **fixed event-name enum** (`Stored/Updated/Trashed/Restored/Deleted/Toggled/...`) and a `system` actor constant for cron (finding C4).
*No behavior change to existing correct calls; purely additive safety.*

### Phase 1 — Close the 🔴 172 Critical gaps (weeks) — highest priority
Order:
1. **Payments & fees** — StudentPortal (web + mobile) payment endpoints, StudentFee, Accounting, Payment, Billing.
2. **Grades** — LmsExam, LmsQuiz, LmsQuests, Hpc, StudentPortal exam/quiz/quest `submit`. (Reconcile with existing `AttemptActivityLog`/`ptm_*` — decide central vs. domain.)
3. **Identity & access** — Admission, StudentProfile, HrStaff, Certificate, **Prime (roles/permissions)**.
Use `MarksheetGeneration` (0 missing) and `GlobalMaster/CityController` as the reference implementations.

### Phase 2 — Structural layer (weeks) — durable coverage
- Introduce the model-observer/trait logging layer on audited models.
- Retrofit the 4 existing observers + 13 jobs to log.
- Wire the `BookFileService`/`PaymentService`-style services to the central trail (or formally designate their domain tables as the source and cross-reference).

### Phase 3 — Close 🟠 269 High gaps (weeks)
- BehaviouralAssessment (0 fully-compliant today), SchoolSetup structure, timetabling, portals, complaints/feedback, academic content.
- Standardize `update()` on the **before/after diff** pattern (finding C1) as these are touched.

### Phase 4 — 🟡 506 Medium gaps + hardening
- Largely absorbed by the Phase-2 structural layer.
- Manually address the 🔴/🟠 subset of the 502 raw mass-ops sites.
- Add a **CI check / static rule**: new mutating controller method without `activityLog()` (or a loggable model) fails review — prevents regression.

---

## Verification (how to prove progress — read-only)
Re-run the deterministic scan after each phase and track:
- % of mutating controllers fully compliant (baseline **41.7%**).
- Count of 🔴 missing calls (baseline **172** → target 0).
- Zero-coverage mutating controllers (baseline **173**).
- Non-controller surfaces logging (observers 0/4, jobs 1/13 → target: all audited).

## Effort shape (indicative)
| Phase | Focus | Rough effort |
|-------|-------|:---:|
| 0 | Helper hardening | 1–2 days |
| 1 | 172 🔴 gaps | 2–3 weeks |
| 2 | Structural layer | 2–3 weeks |
| 3 | 269 🟠 gaps | 3–4 weeks |
| 4 | 🟡 + CI guard | 2 weeks |

**Bottom line:** fix the helper's silent-skip + PII risk first (cheap, foundational), close the 172 critical money/grade/identity gaps next (compliance essentials), then make coverage structural so it stops depending on per-method discipline. All work happens in the app repo under a separate approved change — this audit changed nothing.
