# SmartTimetable Module — Development Plan for Pending Work

**Date:** 2026-03-14
**Based on:** `2026Mar14_GapAnalysis_Updated.md`
**Module completion:** ~60% → target 95%+
**Total estimated effort:** ~40 working days

---

## Priority Legend

| Priority | Meaning | When to do |
|----------|---------|-----------|
| P0 | Data loss / security exploit / runtime crash | Before ANY testing or demo |
| P1 | Feature blocker / correctness issue | Before school deployment |
| P2 | Missing feature (analytics, refinement, substitution) | Before GA release |
| P3 | Code quality / optimization / cleanup | Ongoing |

---

## PHASE 1 — CRITICAL BUG FIXES (P0)

**Effort:** 0.5 day | **Prerequisite for all other work**

### Task 1.1 — Fix `set_time_limit` bug (1 min)
**File:** `SmartTimetableController.php:2591`
**Change:** `set_time_limit($request->input('timeout', 120) * 60)` → `set_time_limit($request->input('timeout', 120))`
**Why:** Currently allows 2-hour PHP execution, can hang server.

### Task 1.2 — Remove `saveGeneratedTimetable()` (5 min)
**File:** `SmartTimetableController.php:2843`
**Change:** Delete the method entirely. Remove its route from `tenant.php`. Ensure `storeTimetable()` is the sole save path.
**Why:** This method deletes ALL timetables for the academic session before saving — data loss risk.

### Task 1.3 — Fix `violatesNoConsecutiveRule()` for multi-period activities (15 min)
**File:** `FETSolver.php:636-639`
**Change:** Rewrite to check if ANOTHER instance of the same activity is adjacent, not if the current activity has `duration > 1`.
**Why:** Labs, hobbies, practicals (duration > 1) are never placed in primary/greedy pass.

### Task 1.4 — Fix `Shift` model reference in TimetableTypeController (2 min)
**File:** `TimetableTypeController.php:11,29,181`
**Change:** `use Modules\SmartTimetable\Models\Shift` → `use Modules\SmartTimetable\Models\SchoolShift`
**Why:** Fatal class-not-found on create/edit pages.

### Task 1.5 — Fix `SchoolShiftController::edit()` view reference (1 min)
**File:** `SchoolShiftController.php:66`
**Change:** `'smarttimetable::School.edit'` → `'smarttimetable::shift.edit'`
**Why:** Fatal ViewNotFound on shift edit.

### Task 1.6 — Fix or remove `PeriodController` (10 min)
**File:** `PeriodController.php`
**Change:** If `Period` model is needed → create it wrapping `PeriodSetPeriod`. If not → delete controller and its routes.
**Why:** Entire controller crashes — missing model + missing views.

### Task 1.7 — Remove duplicate route registrations (5 min)
**File:** `tenant.php:1846,1864`
**Change:** Remove the second `Route::resource('period', ...)` and second `Route::resource('school-timing-profile', ...)`.
**Why:** Silent route conflicts.

### Task 1.8 — Remove `test-seeder` debug route (2 min)
**File:** `tenant.php:1767` + `SmartTimetableController.php:3091-3094`
**Change:** Delete route and empty method.
**Why:** Dead endpoint accessible in production.

### Task 1.9 — Fix `FETConstraintBridge` non-existent class references (5 min)
**File:** `FETConstraintBridge.php`
**Change:** Remove references to `App\Services\Timetable\Constraints\ConstraintApplication` and `\App\Models\TtActivity`. Replace with correct classes or mark as TODO with safe fallback.
**Why:** Fatal if ever instantiated.

---

## PHASE 2 — SECURITY HARDENING (P0)

**Effort:** 3 days | **Must complete before any deployment**

### Task 2.1 — Add `EnsureTenantHasModule` middleware (15 min)
**File:** `tenant.php:1766`
**Change:** Add `'module:SmartTimetable'` to the middleware array on the SmartTimetable route group.
**Also:** Verify the middleware exists and is registered in `app/Http/Kernel.php`.

### Task 2.2 — Protect destructive `truncate()` operations (30 min)
**Files:** `ActivityController.php:73`, `TeacherAvailabilityController.php:74`, `RequirementConsolidationController.php:848`
**Change:** Add `Gate::authorize('smart-timetable.{resource}.generate')` before each `truncate()` block. Add confirmation step.

### Task 2.3 — Add authorization to SmartTimetableController (2 hrs)
**File:** `SmartTimetableController.php` (3,160 lines)
**Change:** Add `Gate::authorize()` to every public method. Key methods to protect:
- `generateWithFET()` — `smart-timetable.timetable.generate`
- `storeTimetable()` — `smart-timetable.timetable.store`
- `previewTimetable()` — `smart-timetable.timetable.view`
- `timetableMaster()` — `smart-timetable.timetable.viewAny`
- `constraintManagement()` — `smart-timetable.constraint.viewAny`
- All tab index methods — `smart-timetable.{resource}.viewAny`

### Task 2.4 — Add authorization to remaining 14 unprotected controllers (3 hrs)
**Files:** All controllers listed in gap analysis under "ZERO Auth + ZERO FormRequests"
**Change:** Add `Gate::authorize()` to every public method following the pattern:
```php
Gate::authorize('smart-timetable.{resource-name}.{action}');
```
**Permission naming convention:** `smart-timetable.activity.viewAny`, `smart-timetable.activity.create`, etc.

### Task 2.5 — Implement SmartTimetablePolicy (1 hr)
**File:** `app/Policies/SmartTimetablePolicy.php`
**Change:** Implement all standard methods (`viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`). Register in `AppServiceProvider`.

### Task 2.6 — Register permissions in seeder (1 hr)
**Change:** Create a permission seeder that registers all `smart-timetable.*` permissions for the RBAC system.

### Task 2.7 — Remove `$request->all()` from log statements (15 min)
**Files:** `ClassSubjectSubgroupController.php:203`, `SmartTimetableController.php:2998`
**Change:** Log only specific fields, not entire request payload.

---

## PHASE 3 — ACTIVITY CONSTRAINT INTEGRATION (P1)

**Effort:** 2 days | **Required for correct timetable generation**
**Reference:** `2026Mar10_Step2_ActivityConstraints_SubTasks.md`

### Task 3.1 — Fix multi-period consecutive bug (15 min)
**File:** `FETSolver.php:634`
**Change:** Rewrite `violatesNoConsecutiveRule()` to check if ANOTHER instance is adjacent, not if `duration > 1`.

### Task 3.2 — Per-activity consecutive override (10 min)
**File:** `FETSolver.php:492`
**Change:** Check `$activity->allow_consecutive` before applying the consecutive rule. If `true`, skip the check.

### Task 3.3 — Per-activity daily cap override (10 min)
**File:** `FETSolver.php:679`
**Change:** Use `$activity->max_per_day` instead of hardcoded daily cap when the field is set.

### Task 3.4 — Min-gap enforcement (20 min)
**File:** `FETSolver.php` (new method)
**Change:** Add `violatesMinGapRule($activity, $slot, $context)` that checks `$activity->min_gap_periods`. Wire into `isBasicSlotAvailable()`.

### Task 3.5 — Soft constraint slot scoring (30 min)
**File:** `FETSolver.php::scoreSlotForActivity()`
**Change:** Add scoring for `preferred_periods_json` (+40 exact match, +20 period match), `avoid_periods_json` (-50 exact match, -30 period match), and day-spread (+10 unused day, -15 already-used day).

### Task 3.6 — Integrate scoring into getPossibleSlots (20 min)
**File:** `FETSolver.php:838`
**Change:** Ensure `scoreSlotForActivity()` is called for each candidate slot and results are sorted.
**Note:** `evaluateSoftConstraints()` is already wired (D18). This task adds the activity-level field scoring ON TOP of the ConstraintManager soft scoring.

### Task 3.7 — Auto-populate constraint fields on Activity (30 min)
**File:** `ActivityController.php`
**Change:** When activities are generated, auto-populate `max_per_day`, `min_gap_periods`, `allow_consecutive` from subject/teacher defaults. Use sensible defaults: `max_per_day = ceil(weekly_periods / 5)`, `min_gap_periods = 0`, `allow_consecutive = false` for regular subjects, `true` for labs.

---

## PHASE 4 — PERFORMANCE OPTIMIZATION (P1)

**Effort:** 2 days

### Task 4.1 — Convert session storage to plain arrays (30 min)
**File:** `SmartTimetableController.php`
**Change:** Before storing in session, convert Eloquent collections to `->toArray()`. Reduces 10-50MB to ~1-2MB.

### Task 4.2 — Batch `updateOrCreate` calls in TeacherAvailabilityController (1 hr)
**File:** `TeacherAvailabilityController.php:101-261`
**Change:** Collect all rows first, then use `TeacherAvailablity::upsert($rows, [...uniqueKeys], [...updateColumns])` instead of per-row `updateOrCreate`.

### Task 4.3 — Batch `updateOrCreate` calls in ActivityController (1 hr)
**File:** `ActivityController.php` (6 call sites)
**Change:** Same pattern — collect rows, use `upsert()` or `insert()` instead of per-row writes.

### Task 4.4 — Replace `::all()` with scoped queries in index methods (30 min)
**File:** `SmartTimetableController.php:93-100`
**Change:** Replace `SchoolDay::all()`, `SchoolShift::all()`, etc. with `->where('is_active', true)->select('id', 'name')->get()`. Cache with `Cache::remember()`.

### Task 4.5 — Gate excessive logging behind config flag (15 min)
**File:** `FETSolver.php`
**Change:** Wrap all `\Log::info()` calls inside constraint checking with `if ($this->verboseLogging)`. Already done for some — apply consistently.

### Task 4.6 — Concurrent generation protection (2 hrs)
**File:** `SmartTimetableController.php::generateWithFET()`
**Change:** Add a `Cache::lock("timetable-gen-{$academicSessionId}", 300)` at the start. If lock is held, return `back()->with('error', 'Generation already in progress')`.

---

## PHASE 5 — ROOM ALLOCATION (P1)

**Effort:** 3 days
**Reference:** `2026Mar10_ActivityConstraints_Integration_Plan.md` Section 6

### Task 5.1 — Implement RoomAllocationPass service (4 hrs)
**File:** `Services/RoomAllocationPass.php` (already exists — skeleton)
**Change:** Implement:
- Load activities with `required_room_type_id` and `preferred_room_ids`
- For each placed activity, find best available room (match type → match preferred → fallback)
- Update `TimetableCell.room_id`
- Return allocation report (assigned, unassigned, conflicts)

### Task 5.2 — Wire RoomAllocationPass into generateWithFET() (30 min)
**File:** `SmartTimetableController.php`
**Change:** After `$entries = $solver->solve()`, call `RoomAllocationPass::allocate($entries, $rooms)` before `TimetableStorageService::storeGeneratedTimetable()`.

### Task 5.3 — Show room assignments in timetable views (1 day)
**Files:** Timetable preview views
**Change:** Display room name in each cell alongside subject/teacher.

### Task 5.4 — Room conflict detection (4 hrs)
**Change:** Add room double-booking check in post-gen verification (extend existing parallel violation check).

---

## PHASE 6 — STUB CONTROLLERS & MISSING VIEWS (P1)

**Effort:** 2 days

### Task 6.1 — Implement TimetableController (4 hrs)
**File:** `TimetableController.php`
**Change:** Implement `store()`, `update()`, `destroy()` with proper validation, auth, and Eloquent operations. Wire to views.

### Task 6.2 — Implement WorkingDayController stubs (2 hrs)
**File:** `WorkingDayController.php`
**Change:** Implement `store()`, `update()`, `destroy()`.

### Task 6.3 — Create missing views (2 hrs)
**Views to create:**
- `slot-requirement/show.blade.php`
- `shift/edit.blade.php` (or fix reference)
- `period/` views (if PeriodController is kept)

### Task 6.4 — Delete dead code (30 min)
**Files to delete:**
- `SmartTimetableController_29_01_before_store.php`
- `resources/views/class-group-requirement copy/` directory
- `generate-timetable_2` through `generate-timetable_5` variant directories

---

## PHASE 7 — POST-GENERATION ANALYTICS (P2)

**Effort:** 5 days
**Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-4

### Task 7.1 — Create AnalyticsService (2 days)
**Methods:**
- `getWorkloadReport($timetableId)` — hours per teacher, subject, class
- `getUtilizationReport($timetableId)` — room/period utilization %
- `getViolationReport($timetableId)` — constraint violations summary
- `getDistributionReport($timetableId)` — subject spread across week
- `getConflictReport($timetableId)` — double-bookings, gaps
- `getComparisonReport($timetableId1, $timetableId2)` — diff between generations
- `exportToCSV($report)` — CSV export

### Task 7.2 — Create AnalyticsController (1 day)
**Endpoints:**
- `GET /analytics` → overview dashboard
- `GET /analytics/workload` → teacher workload
- `GET /analytics/utilization` → room utilization
- `GET /analytics/violations` → constraint violations
- `GET /analytics/export/{type}` → CSV download

### Task 7.3 — Create analytics views (2 days)
- Dashboard with charts (Chart.js or Alpine.js)
- Workload table with heatmap
- Violation list with severity badges
- Export buttons

---

## PHASE 8 — MANUAL REFINEMENT (P2)

**Effort:** 4 days
**Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-5

### Task 8.1 — Create RefinementService (2 days)
**Methods:**
- `swapActivities($cellId1, $cellId2)` — swap two activities
- `moveActivity($cellId, $newDayId, $newPeriodId)` — move to new slot
- `lockCell($cellId)` — prevent changes during next regeneration
- `unlockCell($cellId)` — remove lock
- `getSwapCandidates($cellId)` — find valid swap targets
- `validateMove($cellId, $newSlot)` — check constraints before move
- `getImpactAnalysis($cellId, $action)` — show what would change
- `logChange($cellId, $action, $oldState, $newState)` — audit trail

### Task 8.2 — Create RefinementController (1 day)
**Endpoints:**
- `POST /refinement/swap` → swap two cells
- `POST /refinement/move` → move a cell
- `POST /refinement/lock` → lock a cell
- `GET /refinement/candidates/{cellId}` → get swap candidates
- `GET /refinement/impact/{cellId}` → preview impact

### Task 8.3 — Create refinement UI (1 day)
- Drag-and-drop on timetable grid
- Right-click context menu (swap, move, lock)
- Impact preview modal

---

## PHASE 9 — SUBSTITUTION MANAGEMENT (P2)

**Effort:** 5 days
**Reference:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` GAP-6

### Task 9.1 — Create SubstitutionService (3 days)
**Methods:**
- `reportAbsence($teacherId, $date, $reason)` — mark teacher absent
- `findSubstitutes($activityId, $date)` — eligible teacher list with scoring
- `assignSubstitute($activityId, $teacherId, $date)` — assign sub
- `autoAssign($teacherId, $date)` — auto-find and assign for all activities
- `getSubstitutionHistory($teacherId)` — view past substitutions
- `learnPatterns()` — analyze substitution patterns for recommendations

### Task 9.2 — Create SubstitutionController (1 day)
**Endpoints:**
- `GET /substitution` → dashboard (today's absences, pending assignments)
- `POST /substitution/absence` → report absence
- `GET /substitution/candidates/{activityId}/{date}` → find substitutes
- `POST /substitution/assign` → assign substitute

### Task 9.3 — Create substitution views (1 day)
- Absence reporting form
- Substitute recommendation list
- Daily substitution board

---

## PHASE 10 — API & ASYNC GENERATION (P2)

**Effort:** 3 days

### Task 10.1 — Create TimetableApiController (1 day)
**Endpoints (REST):**
- `GET /api/v1/timetable/{id}` → timetable data
- `GET /api/v1/timetable/{id}/class/{classId}` → class timetable
- `GET /api/v1/timetable/{id}/teacher/{teacherId}` → teacher timetable
- `GET /api/v1/timetable/{id}/room/{roomId}` → room timetable
- `POST /api/v1/timetable/generate` → trigger async generation
- `GET /api/v1/timetable/generate/{jobId}/status` → poll status

### Task 10.2 — Create GenerateTimetableJob (1 day)
**File:** `Jobs/GenerateTimetableJob.php`
**Change:** Move generation logic from controller to a queueable job. Store progress in `tt_generation_runs.progress_json`.

### Task 10.3 — Status polling endpoint (0.5 day)
**Change:** Return `GenerationRun` status + progress % + ETA.

### Task 10.4 — Frontend progress indicator (0.5 day)
**Change:** Alpine.js polling component that shows generation progress bar.

---

## PHASE 11 — CONSTRAINT SYSTEM EXPANSION (P3)

**Effort:** 5 days

### Task 11.1 — Implement remaining constraint PHP classes (4 days)
**Current:** 12/38 constraint types have dedicated PHP classes.
**Target:** Create classes for the 26 remaining types. Most can extend `GenericHardConstraint` or `GenericSoftConstraint` with type-specific `passes()` logic.
**Priority order:**
1. Teacher constraints (B category) — most frequently needed
2. Room constraints (E category) — needed after room allocation
3. Inter-activity constraints (H category) — for activity group rules
4. Global policy constraints (G category) — for school-wide rules

### Task 11.2 — Wire FETConstraintBridge to DatabaseConstraintService (1 day)
**File:** `FETConstraintBridge.php`
**Change:** Load constraints from `tt_constraints` via `DatabaseConstraintService` and pass to `ConstraintManager`. Replace the TODO with actual implementation.

---

## PHASE 12 — TESTING (P3)

**Effort:** 4 days

### Task 12.1 — Unit tests for FETSolver (2 days)
**Tests needed:**
- `scoreSlotForActivity()` — verify score ranges
- `violatesNoConsecutiveRule()` — multi-period fix verified
- `violatesMinGapRule()` — new method
- `resolveMaxPerDay()` — per-activity cap
- `orderActivitiesByDifficulty()` — ordering correctness
- Parallel group anchor/sibling placement (already have 5 tests)

### Task 12.2 — Unit tests for ConstraintManager (1 day)
**Tests needed:**
- `checkHardConstraints()` — returns bool correctly
- `evaluateSoftConstraints()` — returns score in expected range
- Constraint loading and caching

### Task 12.3 — Feature tests for key controllers (1 day)
**Tests needed:**
- `SmartTimetableController::generateWithFET()` — generation workflow
- `ParallelGroupController` — CRUD operations
- `ConstraintController` — create/edit/delete constraints

---

## PHASE 13 — CODE QUALITY & CLEANUP (P3)

**Effort:** 3 days

### Task 13.1 — Split SmartTimetableController (2 days)
**Extract into:**
- `GenerationController` — generateWithFET, storeTimetable, previewTimetable
- `TimetableMasterController` — timetableMaster, tab views
- `ConstraintManagementController` — constraintManagement, related views
- `ReportController` — reports, exports
- Keep `SmartTimetableController` as a thin index-only controller

### Task 13.2 — Convert inline validation to FormRequests (0.5 day)
**Files:** 16 controllers using `$request->validate()`
**Change:** Create FormRequest classes for each store/update method.

### Task 13.3 — Add SoftDeletes to 40 models (0.5 day)
**Change:** Add `use SoftDeletes;` and `'deleted_at'` to `$dates` on each model.

### Task 13.4 — Delete dead code and cleanup (2 hrs)
- Delete `SmartTimetableController_29_01_before_store.php`
- Delete `class-group-requirement copy/` directory
- Delete `generate-timetable_2` through `_5` directories
- Remove debug methods from SmartTimetableController (~550 lines)

---

## Timeline Summary

| Phase | Description | Priority | Effort | Dependency |
|-------|------------|----------|--------|-----------|
| 1 | Critical Bug Fixes | P0 | 0.5 day | None |
| 2 | Security Hardening | P0 | 3 days | None |
| 3 | Activity Constraints | P1 | 2 days | Phase 1 |
| 4 | Performance Optimization | P1 | 2 days | None |
| 5 | Room Allocation | P1 | 3 days | Phase 1 |
| 6 | Stub Controllers & Views | P1 | 2 days | Phase 2 |
| 7 | Analytics | P2 | 5 days | Phase 5 |
| 8 | Refinement | P2 | 4 days | Phase 5 |
| 9 | Substitution | P2 | 5 days | Phase 5 |
| 10 | API & Async | P2 | 3 days | Phase 5 |
| 11 | Constraint Expansion | P3 | 5 days | Phase 3 |
| 12 | Testing | P3 | 4 days | Phase 3, 5 |
| 13 | Code Quality | P3 | 3 days | Phase 6 |
| **Total** | | | **~41.5 days** | |

### Suggested Execution Order (Critical Path)

```
Week 1:  Phase 1 (bugs) + Phase 2 (security) — MUST DO FIRST
Week 2:  Phase 3 (activity constraints) + Phase 4 (performance)
Week 3:  Phase 5 (room allocation) + Phase 6 (stubs/views)
Week 4:  Phase 7 (analytics)
Week 5:  Phase 8 (refinement) + Phase 10 (API)
Week 6:  Phase 9 (substitution)
Week 7:  Phase 11 (constraints) + Phase 12 (testing)
Week 8:  Phase 13 (code quality) + buffer
```

### Minimum Viable for School Deployment (Phases 1-6)

**Effort:** ~12.5 days (~2.5 weeks)
**Result:** Generation works correctly with authorization, activity constraints, room allocation, no crashes.

### Full Feature Complete (Phases 1-13)

**Effort:** ~41.5 days (~8-9 weeks)
**Result:** Full analytics, refinement, substitution, API, testing, clean code.

---

## Quick Reference: Most Impactful Tasks (Effort vs Value)

| Task | Effort | Value | ROI |
|------|--------|-------|-----|
| Phase 1 (all bug fixes) | 0.5 day | Prevents data loss + crashes | **Highest** |
| Task 2.1 (EnsureTenantHasModule) | 15 min | Blocks unpaid tenants | **Highest** |
| Task 2.3 (auth on SmartTimetableController) | 2 hrs | Protects generation/storage | **Highest** |
| Task 3.5 (soft constraint scoring) | 30 min | Better timetable quality | **Very High** |
| Task 4.1 (session storage fix) | 30 min | Prevents server memory issues | **Very High** |
| Task 5.1-5.2 (room allocation) | 4.5 hrs | Rooms assigned automatically | **High** |
| Task 4.6 (concurrent gen protection) | 2 hrs | Prevents data corruption | **High** |
