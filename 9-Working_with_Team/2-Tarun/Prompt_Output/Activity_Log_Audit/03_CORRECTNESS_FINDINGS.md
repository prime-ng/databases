# 03 · Correctness Findings — Quality of Existing `activityLog()` Calls

> Presence ≠ correctness. This report covers calls that **do** exist but are weak, wrong, or fragile. Where the app's dominant failure mode is total absence (see `02_MISSING_CALLS.md`), these are the "⚠️ present-but-imperfect" cases.
> **Scope honesty:** the deterministic presence scan covered all 730 controllers. The line-by-line correctness review below is based on the **canonical pattern + sampled high-risk modules** (StudentPortal, StudentFee, SyllabusBooks, GlobalMaster, Accounting, MarksheetGeneration) because several audit sub-agents were interrupted by service rate/session limits. Treat these as representative patterns to grep for, and re-run a full correctness pass as the top follow-up.

---

## The helper contract (what "correct" means)

`activityLog($subject, string $event, array $properties = [])` — from `app/Helpers/activityLog.php`:
- `$subject` **must be the actual mutated Eloquent model** (it calls `get_class($subject)` and `$subject->getKey()`).
- **If `$subject` is `null`, it returns `null` and writes nothing** — silently.
- Captures `user_id` (`Auth::id()`), `event`, `properties`, `ip`, `user_agent` → `sys_activity_logs`.

The canonical correct implementation is `Modules/GlobalMaster/app/Http/Controllers/CityController.php` (and `DistrictController.php`).

---

## Finding classes

### C1 — `update()` logs without a before/after diff  🟠 Common
Many `update()` methods that *do* call `activityLog()` pass only a static `message` and omit the `getOriginal()`/`getChanges()` diff that the `CityController` pattern captures. Result: the log says "X was updated" but not **what** changed — the single most valuable piece of audit data for disputes.
- **Pattern to grep:** `activityLog($model, 'Updated', ['message' => ...])` with no `changes` key.
- **Fix (recommendation):** adopt the `changedAttributes` before/after block from `CityController::update()` everywhere.

### C2 — Silent null-subject skips  🔴 Latent
Any call whose first argument can be `null` (e.g. `firstOrNew`, a `find()` that may miss, a conditional model) will **log nothing and raise no error**. These are invisible in a presence scan (the token `activityLog(` is there) yet produce zero audit rows at runtime.
- **Where to look:** controllers that `find()` then act, `updateOrCreate` results, soft-deleted lookups.
- **Fix:** guard-log or make the helper emit a warning when `$subject === null`.

### C3 — Downstream-only logging (controller delegates, service doesn't log centrally)  🔴 Confirmed
Some controllers correctly delegate mutation to a service/job, but the service writes only its **own domain table**, never `sys_activity_logs`. The central audit trail then has a hole even though "an audit exists."
- **Confirmed:** `Modules/SyllabusBooks/.../BookFileService` (`attach`/`markPrimary`/`delete`) mutates with no `activityLog()`; `BookFileController` delegates to it.
- **Confirmed:** StudentPortal `PaymentService` writes `ptm_*` rows and exam attempts write `AttemptActivityLog`/`AttemptCheckpoint` — domain trails, but nothing in `sys_activity_logs`.
- **Fix:** decide whether `sys_activity_logs` is the single source of truth; if so, log in the service/observer layer (see `05_NON_CONTROLLER_SURFACES.md`).

### C4 — Event-name inconsistency  🟡 Minor
The vocabulary drifts (`'Stored'` vs `'Created'`, `'Trashed'` vs `'Deleted'`, `'Toggled'` vs `'StatusUpdated'`). Correct-but-inconsistent event strings make querying/reporting the audit log harder.
- **Example:** StudentPortal's one correct call uses `'Created'` while the GlobalMaster convention is `'Stored'`.
- **Fix:** publish a fixed event enum and lint for it.

### C5 — PII / secrets risk in `properties`  🔴 Privacy (audit-for)
`properties` is stored as JSON. In identity/financial modules (Admission, StudentProfile, StudentFee, Payment), passing `$request->all()` or full model attributes into `properties` risks persisting passwords, tokens, card/UPI/Aadhaar data into the audit table.
- **Where to look:** any `activityLog($m, $e, $request->all())` or `->getAttributes()` spread in these modules.
- **Fix:** whitelist logged fields; redact sensitive keys in the helper.

### C6 — Placement inside transactions / after redirect  🟡
Calls must run **after** a successful persist and **inside** the committed transaction path. Watch for logs placed before `save()` succeeds, or after an early `return`/`redirect` (dead code). Sampled modules were mostly fine here, but it needs the full pass.

---

## What's genuinely correct (calibration)

- **`GlobalMaster/CityController` + `DistrictController`** — the gold standard: correct subject, before/after diff on update, correct events across store/update/destroy/restore/forceDelete/toggleStatus.
- **`MarksheetGeneration`** — 17/21 fully compliant, 0 missing; strongest large module.
- **`StudentPortal/StudentLibraryController::submitReview()`** — the one web call in that module is correct (real `LibBookReview` model, benign properties).
- **Accounting / Cafeteria / Recommendation / Ptm** — high full-compliance, calls follow the pattern.

---

## Recommended correctness follow-up (read-only)
1. Grep all `'Updated'` logs lacking a `changes`/`getChanges` sibling → C1 candidates.
2. Grep `activityLog(` calls whose first arg is a variable that is assigned via `find`/`firstOrNew`/`updateOrCreate` → C2 candidates.
3. Grep `activityLog(.*request()->all()` and `.*getAttributes()` in 🔴 modules → C5 candidates.
4. List distinct event strings used → C4 normalization.
5. Re-run the interrupted per-module correctness pass to convert the presence matrix's ✅ into verified-✅.
