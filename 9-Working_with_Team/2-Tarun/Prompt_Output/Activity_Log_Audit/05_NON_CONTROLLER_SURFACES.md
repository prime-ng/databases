# 05 · Non-Controller Mutation Surfaces

> Controllers are not the only place data changes. This report covers observers, jobs, services, console commands, and raw mass-operations — the blind spots that controller-only auditing misses. All counts from read-only scans on 2026-07-02.

---

## Summary of blind spots

| Surface | Count | Log to `sys_activity_logs`? | Risk |
|---------|:---:|:---:|:---:|
| **Model Observers** | 4 | **0 of 4** | 🟠 events bypass controller logging |
| **Jobs (queued/async)** | 13 | **1 of 13** | 🟠 bulk/async mutations |
| **Services / Actions / Repositories** | 319 files | ~none centrally | 🔴 business logic that persists |
| **Console commands / cron** | 36 | unverified (assume ~none) | 🟠 scheduled mutations |
| **Raw mass-ops** (`Model::where()->update()/delete()`, `DB::table()`) | 502 files | bypass model events entirely | 🟠/🔴 |

---

## 1. Observers — none log
```
Modules/LmsHomework/app/Observers/SyllabusScheduleObserver.php
Modules/Prime/app/Observers/TenantPlanObserver.php
Modules/TimetableFoundation/app/Observers/SubActivityObserver.php
Modules/TimetableFoundation/app/Observers/ActivityObserver.php
```
**None call `activityLog()`.** These fire on model lifecycle events (created/updated/deleted). Any mutation routed through a model event — rather than an explicit controller call — is invisible to the audit trail. `TenantPlanObserver` (Prime) is notable: tenant-plan changes are billing/access-relevant.

> **Opportunity:** observers are actually the *best* place to centralize logging — a generic "loggable" observer on key models would close hundreds of controller gaps at once (see `06_REMEDIATION_PLAN.md`, Option B).

## 2. Jobs — 1 of 13 log
Only one job under `Modules/*/app/Jobs/` contains `activityLog()`. Async/bulk mutations (imports, batch generation, notifications) largely run without an audit entry. Bulk operations are exactly where a missing trail hurts most (one job can mutate thousands of rows).

## 3. Services / Actions / Repositories — the largest surface
**319 service files.** Business logic frequently persists data here while the calling controller only orchestrates. Central logging in this layer is essentially absent.
- **Confirmed:** `Modules/SyllabusBooks/.../BookFileService` — `attach()`, `markPrimary()`, `delete()` mutate book files with **no `activityLog()`**, and `BookFileController` delegates to it → the controller *looks* thin/clean but the mutation is unlogged.
- **Confirmed:** StudentPortal `PaymentService` — writes its own `ptm_*` rows but nothing to `sys_activity_logs`; exam/quiz/quest attempts write `AttemptActivityLog`/`AttemptCheckpoint` domain tables only.

## 4. Console commands / cron — 36 files
Scheduled mutations (e.g. auto status changes, LMS resource release, syllabus schedule locks — the codebase has background cron for these) run with **no user context** (`Auth::id()` is null in cron) and generally no logging. These need a system-actor logging convention.

## 5. Raw mass-operations — 502 files
502 files use `Model::where(...)->update()/delete()` or `DB::table()`. **These bypass Eloquent model events entirely**, so even an observer-based logging strategy won't catch them. Each is a place where data changes with neither a controller `activityLog()` nor a model-event hook.

---

## Why this matters for the coverage numbers

The controller matrix (`01_`) shows 947 missing controller calls — but that **understates** total unlogged mutations, because a "clean" controller that delegates to an unlogged service (like `BookFileController` → `BookFileService`) can appear *less* problematic than a fat controller, while actually logging nothing. **Coverage should be measured at the mutation, not the controller.**

## Recommendations (detail in `06_`)
1. Treat `sys_activity_logs` as the **single central audit source**; decide which domain tables (`ptm_*`, `AttemptActivityLog`) are complementary vs. duplicative.
2. Centralize via a **model-observer / trait** layer for event-driven coverage (catches services/observers that use Eloquent).
3. Add an explicit logging convention for **jobs and cron** (system actor when `Auth::id()` is null).
4. **Flag every `DB::table()`/mass-`update()` in 🔴 modules** for manual logging — they can't be caught automatically.
