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

## PHASE 11 — CONSTRAINT ARCHITECTURE FOUNDATION (P1)

**Effort:** 3 days | **Prerequisite for all constraint phases below**
**Reference:** `2026Mar10_ConstraintArchitecture_Analysis.md` §3

### Task 11.1 — Create ConstraintRegistry (plugin system) (4 hrs)
**File:** `Services/Constraints/ConstraintRegistry.php` (NEW)
**What:** Replace hardcoded `CONSTRAINT_CLASS_MAP` array in `ConstraintFactory` with a dynamic registry.
```
ConstraintRegistry::register('TEACHER_LUNCH_BREAK', TeacherLunchBreakConstraint::class);
```
**Why:** Adding new constraint types currently requires editing ConstraintFactory. Registry makes it plug-and-play.
**Wire:** Update `ConstraintFactory::createFromModel()` to use Registry. Register all existing 13 classes in `SmartTimetableServiceProvider::boot()`.

### Task 11.2 — Create ConstraintContext value object (2 hrs)
**File:** `Services/Constraints/ConstraintContext.php` (NEW)
**What:** Typed value object replacing ad-hoc array building in `ConstraintManager::checkHardConstraints()` and `evaluateSoftConstraints()`. Properties: `slot`, `activity`, `dayId`, `periodIndex`, `classKey`, `teacherIds`, `subjectId`, `roomTypeId`, `classId`, `sectionId`.
**Why:** Eliminates repeated context-array construction; makes constraint `passes()` signatures cleaner.

### Task 11.3 — Create ConstraintEvaluator (separated logic) (4 hrs)
**File:** `Services/Constraints/ConstraintEvaluator.php` (NEW)
**What:** Extract evaluation+caching logic from `ConstraintManager` into a dedicated class. `checkHard()` and `scoreSoft()` with cache.
**Why:** ConstraintManager currently handles loading, storage, AND evaluation. Separation allows independent testing.

### Task 11.4 — Wire Constraint Group evaluation into ConstraintManager (1 day)
**Models involved:** `ConstraintGroup`, `ConstraintGroupMember`
**Change:** Add `evaluateGroups()` method to ConstraintManager/ConstraintEvaluator:
- **MUTEX:** At most one member constraint can pass for a slot
- **CONCURRENT:** All members must pass together
- **ORDERED:** Evaluate in `sequence_order`, short-circuit on first fail
- **PREFERRED:** Sum weights of passing members (soft scoring)
**Why:** Constraint groups exist in DB but are completely ignored during generation.

### Task 11.5 — Wire FETConstraintBridge to DatabaseConstraintService (4 hrs)
**File:** `FETConstraintBridge.php`
**Change:** Replace TODO with actual constraint loading from `tt_constraints` via `DatabaseConstraintService`. Pass loaded constraints to `ConstraintManager`.
**Why:** DB constraints in `tt_constraints` table never reach the solver's constraint check bridge.

### Task 11.6 — Add priority-ordered constraint evaluation (2 hrs)
**File:** `ConstraintManager.php` or `ConstraintEvaluator.php`
**Change:** Sort constraints by `priority` field before evaluation. Higher-priority constraints checked first → combined with fail-fast, rejects bad slots faster.

---

## PHASE 12 — TEACHER CONSTRAINTS (Cat B) (P1)

**Effort:** 5 days
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category B
**Scope:** 15 unimplemented per-teacher rules (B1.8–B1.22) + 20 global-teacher variants (B2)

### Task 12.1 — Simple teacher constraints (1 day)
Create PHP classes extending `GenericHardConstraint` or `GenericSoftConstraint`:

| Rule | Class | Complexity |
|------|-------|-----------|
| B1.8 No two consecutive working days | `TeacherNoConsecutiveDaysConstraint` | LOW |
| B1.9 Max gaps per day | `TeacherMaxGapsPerDayConstraint` | LOW |
| B1.10 Max gaps per week | `TeacherMaxGapsPerWeekConstraint` | LOW |
| B1.12 Max span per day | `TeacherMaxSpanPerDayConstraint` | LOW |
| B1.21 Preferred free day | `TeacherPreferredFreeDayConstraint` | LOW |

### Task 12.2 — Study-format-aware teacher constraints (2 days)
These need study format resolution from `Activity → SubjectStudyFormat`:

| Rule | Class | Complexity |
|------|-------|-----------|
| B1.15 Max consecutive with study format | `TeacherMaxConsecutiveStudyFormatConstraint` | MED |
| B1.16 Min/max daily with study format | `TeacherDailyStudyFormatConstraint` | MED |
| B1.17 Max study formats per day | `TeacherMaxStudyFormatsConstraint` | MED |
| B1.18 Min gap between study format pair | `TeacherStudyFormatGapConstraint` | HIGH |

### Task 12.3 — Interval/time-window teacher constraints (1.5 days)
These need period-range filtering:

| Rule | Class | Complexity |
|------|-------|-----------|
| B1.11 Max single gaps in selected slots | `TeacherGapsInSlotRangeConstraint` | MED |
| B1.13 Mutually exclusive time slots | `TeacherMutuallyExclusiveSlotsConstraint` | MED |
| B1.14 Max hours in hourly interval | `TeacherMaxHoursInIntervalConstraint` | MED |
| B1.19 Max days in hourly interval | `TeacherMaxDaysInIntervalConstraint` | MED |
| B1.20 Min resting hours | `TeacherMinRestingHoursConstraint` | HIGH |
| B1.22 Free period in each half | `TeacherFreePeriodEachHalfConstraint` | MED |

### Task 12.4 — Global-teacher variants B2 (0.5 day)
For each B1.x constraint, register a global-scope variant. Implementation: same PHP class but `isRelevant()` returns `true` for ALL teachers when `target_id` is null and scope is GLOBAL. Individual teacher overrides take precedence (lower priority number wins).

### Task 12.5 — Register all new classes in ConstraintRegistry + seed types (2 hrs)
Seed new `ConstraintType` records in `ConstraintTypeSeeder` for any B1 types not already seeded. Register all new PHP classes in `ConstraintRegistry`.

---

## PHASE 13 — CLASS/STUDENT CONSTRAINTS (Cat C) (P1)

**Effort:** 4 days
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category C
**Scope:** 13 unimplemented per-class rules (C1.6–C1.18) + 15 global-class variants (C2)

### Task 13.1 — Simple class constraints (1 day)

| Rule | Class | Complexity |
|------|-------|-----------|
| C1.6 Max gaps per week | `ClassMaxGapsPerWeekConstraint` | LOW |
| C1.7 Max hours continuously | `ClassMaxContinuousConstraint` | LOW |
| C1.8 Max span per day | `ClassMaxSpanConstraint` | LOW |
| C1.9 Min hours daily | `ClassMinDailyHoursConstraint` | LOW |
| C1.18 Class teacher first period | `ClassTeacherFirstPeriodConstraint` | LOW — **School Req #2** |

### Task 13.2 — Study-format-aware class constraints (1.5 days)

| Rule | Class | Complexity |
|------|-------|-----------|
| C1.10 Max hours with study format | `ClassMaxStudyFormatHoursConstraint` | MED |
| C1.11 Min hours with study format | `ClassMinStudyFormatHoursConstraint` | MED |
| C1.12 Max consecutive with study format | `ClassMaxConsecutiveStudyFormatConstraint` | MED |
| C1.13 Min gap between study format pair | `ClassStudyFormatGapConstraint` | HIGH |
| C1.14 Max days in hourly interval | `ClassMaxDaysInIntervalConstraint` | MED |
| C1.15 Min resting hours | `ClassMinRestingHoursConstraint` | HIGH |

### Task 13.3 — School-specific class constraints (1 day)

| Rule | Class | School Req | Complexity |
|------|-------|-----------|-----------|
| C1.16 Max minor subjects per day | `ClassMaxMinorSubjectsConstraint` | **#6** | MED |
| C1.17 Major subjects must fall every day | `ClassMajorSubjectsDailyConstraint` | **#4** | MED |

### Task 13.4 — Global-class variants C2 (0.5 day)
Same pattern as B2 — global scope variants of C1 rules. Seed types + register classes.

---

## PHASE 14 — ROOM & SPACE CONSTRAINTS (Cat E) (P2)

**Effort:** 5 days
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category E
**Dependency:** Phase 5 (Room Allocation) must be done first

### Task 14.1 — Remaining room availability constraints (0.5 day)

| Rule | Class | Complexity |
|------|-------|-----------|
| E1.4 Room max usage per day | `RoomMaxUsagePerDayConstraint` | LOW |
| E1.5 Room max study formats per day | `RoomMaxStudyFormatsConstraint` | MED |
| E1.6 Teacher+room not available times | `TeacherRoomUnavailableConstraint` | MED |

### Task 14.2 — Teacher room preferences E2 (2 days)
**New service needed:** `RoomChangeTrackingService` — post-generation evaluation that counts room/building changes per teacher/day/week. These constraints cannot be evaluated during slot-by-slot generation (room assignment happens after placement). They must be post-gen checks that feed into the violation/refinement cycle.

| Rule | Implementation | Complexity |
|------|---------------|-----------|
| E2.1-E2.2 Home room / room set | Soft scoring in RoomAllocationPass | LOW |
| E2.3-E2.6 Max room changes per day/week/interval, min gaps | Post-gen evaluation | MED |
| E2.7-E2.10 Max building changes per day/week/interval, min gaps | Post-gen evaluation | MED |

### Task 14.3 — Student room preferences E3 (1 day)
Mirror of E2 applied to student-sets (class+section). Same `RoomChangeTrackingService` with student entity type.

### Task 14.4 — Subject/StudyFormat room preferences E4 (1 day)

| Rule | Implementation | Complexity |
|------|---------------|-----------|
| E4.1-E4.2 Subject preferred room/set | Soft scoring in RoomAllocationPass | LOW |
| E4.3-E4.4 Study format preferred room/set | Soft scoring in RoomAllocationPass | LOW |
| E4.5-E4.6 Subject+StudyFormat combo preferred room/set | Soft scoring | LOW |

### Task 14.5 — Seed constraint types + register classes (0.5 day)

---

## PHASE 15 — INTER-ACTIVITY CONSTRAINTS (Cat H) (P1)

**Effort:** 8 days
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category H
**Scope:** 21 rules (H1-H7, H9-H22) — H8 (Parallel Periods) already done
**WARNING:** These require solver-level changes in FETSolver, similar to how H8 was implemented

### Task 15.1 — Activity group infrastructure in FETSolver (1 day)
**What:** Extend the existing `activityParallelMap` / `parallelGroupActivityIds` pattern to support all group types. Create:
- `activityGroupMap[$activityId]` → `[{group_id, group_type, relationship_type}]`
- Load from `tt_activity_group` + `tt_activity_group_member` (or extend `tt_parallel_group`)
- `getGroupConstraintForActivity($activityId, $groupType)` helper

### Task 15.2 — Same-time / same-day / same-hour constraints H1-H3 (1.5 days)
**Solver change:** When placing an activity that belongs to a SAME_TIME/SAME_DAY/SAME_HOUR group, enforce the constraint against other placed members.
- H1 (same starting time): Like H8 but without forcing slot — just check startIndex matches
- H2 (same day): Check dayId matches other placed members
- H3 (same hour): Check periodIndex matches

### Task 15.3 — Consecutive / ordered / grouped H5-H7 (2 days)
**Solver change:** Block-placement logic:
- H5 (consecutive): After placing activity A, force activity B to adjacent slot
- H6 (ordered if same day): If A and B on same day, enforce A.startIndex < B.startIndex
- H7 (grouped block): Place 2-3 activities as a contiguous block (extend duration logic)

### Task 15.4 — Not-overlapping H4 (0.5 day)
**Solver change:** Simpler than same-time — check that two activities in a NOT_OVERLAPPING group don't share any period on any day. Also works for study format pairs.

### Task 15.5 — Day/period pinning and exclusion H20-H22 (1 day)
**Solver change:** These are simpler — filter candidate slots before scoring:
- H20 (fixed to day): Only generate slots for the specified day
- H21 (excluded from day): Filter out slots on the specified day
- H22 (fixed to period range): Only generate slots within period_start–period_end

### Task 15.6 — Gap and scheduling relationship rules H9-H16 (1.5 days)
**Mostly soft scoring:**
- H9-H10 (min/max days between): Check calendar distance between placed instances
- H11 (end students day): Soft bonus for last period
- H12-H15 (occupy min/max slots from selection): Set counting
- H16 (min gaps between activity set): Gap enforcement across set members

### Task 15.7 — Room-related inter-activity rules H17-H18 (0.5 day)
**Post-gen evaluation (room allocated after placement):**
- H17 (same room if consecutive): RoomAllocationPass preference
- H18 (max different rooms for set): Post-gen violation check

### Task 15.8 — School-specific inter-activity rules H19 (0.5 day)
- H19 (non-concurrent minor subjects): Games, Library, Art, Hobby, Dance, Music not on same day — **School Req #6**. Implemented as a soft constraint that penalizes day overlap between minor subject activities.

---

## PHASE 16 — GLOBAL POLICY & ACTIVITY-LEVEL EXPANSION (Cat G + D) (P2)

**Effort:** 3 days
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Categories G and D

### Task 16.1 — Remaining global policy constraints G (1.5 days)

| Rule | Implementation | Complexity |
|------|---------------|-----------|
| G5 Max teaching days per week | `GlobalMaxTeachingDaysConstraint` — already seeded as F22 | LOW |
| G6 Fixed period (assembly/prayer) | `GlobalFixedPeriodConstraint` — already seeded as F20 | LOW |
| G7 Holiday/no classes dates | `GlobalHolidayConstraint` — already seeded as F21 | LOW |
| G8 Balanced distribution | `GlobalBalancedDistributionConstraint` — already seeded as F25 | MED |
| G9 Prefer morning for core | `GlobalPreferMorningConstraint` — already seeded as F23 | LOW |

### Task 16.2 — Activity-level fields expansion in FETSolver (1.5 days)
**Reference:** `2026Mar10_Step2_ActivityConstraints_SubTasks.md`
Phase 3 covers 7 of 22 activity fields. Remaining 15 fields to score in `scoreSlotForActivity()`:

| Field | Scoring Logic | Complexity |
|-------|-------------|-----------|
| `avoid_time_slots_json` | -50 for exact match | LOW |
| `preferred_time_slots_json` | +40 for exact match | LOW |
| `min_per_day` | Penalize if below min when day is used | MED |
| `min_periods_per_week` / `max_periods_per_week` | Track running total | MED |
| `split_allowed` | If false, enforce all weekly periods on same day | MED |
| `priority` | Higher priority → placed earlier (already in ordering) | Already done |
| `is_compulsory` | If true, never skip in rescue pass | LOW |
| `required_room_type_id` / `required_room_id` | Hard check in RoomAllocationPass | Phase 5 covers |
| `preferred_room_type_id` / `preferred_room_ids` | Soft scoring in RoomAllocationPass | Phase 5 covers |
| `difficulty_score` | Auto-calculated, used in ordering | Already done |
| `constraint_count` | Auto-calculated | Already done |

---

## PHASE 17 — DB-CONFIGURABLE CONSTRAINT PHP CLASSES (Cat F remaining) (P2)

**Effort:** 3 days
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category F
**Scope:** 25 seeded types, 13 currently registered, 12 remaining without PHP class

### Task 17.1 — Teacher DB constraint PHP classes (1 day)

| Seeded Code | PHP Class |
|------------|-----------|
| TEACHER_MAX_DAILY (F1) | `TeacherMaxDailyConstraint` |
| TEACHER_MAX_WEEKLY (F2) | `TeacherMaxWeeklyConstraint` |
| TEACHER_MAX_CONSECUTIVE (F3) | `TeacherMaxConsecutiveDBConstraint` |
| TEACHER_NO_CONSECUTIVE (F4) | `TeacherNoConsecutiveDBConstraint` |
| TEACHER_UNAVAILABLE_PERIODS (F5) | `TeacherUnavailablePeriodsConstraint` |
| TEACHER_PREFERRED_FREE_DAY (F6) | `TeacherPreferredFreeDayDBConstraint` |
| TEACHER_MIN_DAILY (F7) | `TeacherMinDailyConstraint` |

### Task 17.2 — Class DB constraint PHP classes (0.5 day)

| Seeded Code | PHP Class |
|------------|-----------|
| CLASS_MAX_PER_DAY (F8) | `ClassMaxPerDayConstraint` |
| CLASS_WEEKLY_PERIODS (F9) | `ClassWeeklyPeriodsConstraint` |
| CLASS_NOT_FIRST_PERIOD (F10) | `ClassNotFirstPeriodConstraint` |
| CLASS_NOT_LAST_PERIOD (F11) | `ClassNotLastPeriodConstraint` |
| CLASS_CONSECUTIVE_REQUIRED (F12) | `ClassConsecutiveRequiredConstraint` |
| CLASS_MIN_GAP (F13) | `ClassMinGapConstraint` |

### Task 17.3 — Room + Activity + Global DB constraint PHP classes (1 day)

| Seeded Code | PHP Class |
|------------|-----------|
| ROOM_UNAVAILABLE (F14) | Already exists in CONSTRAINT_CLASS_MAP as ROOM_AVAILABILITY |
| ROOM_MAX_USAGE_PER_DAY (F15) | `RoomMaxUsageConstraint` |
| ROOM_EXCLUSIVE_USE (F16) | `RoomExclusiveUseConstraint` |
| ACTIVITY_EXAM_ONLY_PERIODS (F17) | `ExamOnlyPeriodsConstraint` |
| ACTIVITY_NO_TEACHING_AFTER_EXAM (F18) | `NoTeachingAfterExamConstraint` |
| ACTIVITY_EXAM_CUTOFF_TIME (F19) | `ExamCutoffTimeConstraint` |
| GLOBAL_FIXED_PERIOD (F20) | Already exists as FIXED_PERIOD_HIGH_PRIORITY |
| GLOBAL_NO_CLASSES_ON_DATE (F21) | `GlobalHolidayConstraint` |
| GLOBAL_MAX_TEACHING_DAYS (F22) | `GlobalMaxTeachingDaysConstraint` |
| OPT_PREFER_MORNING (F23) | Already exists as PREFERRED_TIME_OF_DAY |
| OPT_PREFER_SAME_ROOM (F24) | `PreferSameRoomConstraint` |
| OPT_BALANCED_DISTRIBUTION (F25) | Already exists as BALANCED_DAILY_SCHEDULE |

### Task 17.4 — Reconcile CONSTRAINT_CLASS_MAP duplicates (0.5 day)
Some seeded codes map to existing classes under different names (e.g. F14/ROOM_UNAVAILABLE → ROOM_AVAILABILITY, F20 → FIXED_PERIOD_HIGH_PRIORITY). Create aliases in ConstraintRegistry or merge into canonical names.

---

## PHASE 18 — TESTING (P3)

**Effort:** 5 days

### Task 18.1 — Unit tests for FETSolver (2 days)
- `scoreSlotForActivity()` — verify score ranges
- `violatesNoConsecutiveRule()` — multi-period fix verified
- `violatesMinGapRule()` — new method
- `resolveMaxPerDay()` — per-activity cap
- `orderActivitiesByDifficulty()` — ordering correctness
- Parallel group anchor/sibling placement (already have 5 tests)

### Task 18.2 — Unit tests for ConstraintManager + ConstraintEvaluator (1.5 days)
- `checkHardConstraints()` — returns bool correctly
- `evaluateSoftConstraints()` — returns score in expected range
- Constraint loading, caching, and priority ordering
- Group evaluation (MUTEX, CONCURRENT)
- `ConstraintContext` value object construction

### Task 18.3 — Unit tests for new constraint PHP classes (1 day)
For each category (B, C, E, H), write at least 2 representative tests:
- One constraint that passes, one that fails
- Verify `isRelevant()` correctly skips non-applicable activities

### Task 18.4 — Feature tests for key controllers (0.5 day)
- `SmartTimetableController::generateWithFET()` — generation workflow
- `ParallelGroupController` — CRUD operations
- `ConstraintController` — create/edit/delete constraints

---

## PHASE 19 — CODE QUALITY & CLEANUP (P3)

**Effort:** 3 days

### Task 19.1 — Split SmartTimetableController (2 days)
**Extract into:**
- `GenerationController` — generateWithFET, storeTimetable, previewTimetable
- `TimetableMasterController` — timetableMaster, tab views
- `ConstraintManagementController` — constraintManagement, related views
- `ReportController` — reports, exports
- Keep `SmartTimetableController` as a thin index-only controller

### Task 19.2 — Convert inline validation to FormRequests (0.5 day)
**Files:** 16 controllers using `$request->validate()`
**Change:** Create FormRequest classes for each store/update method.

### Task 19.3 — Add SoftDeletes to 40 models (0.5 day)
**Change:** Add `use SoftDeletes;` and `'deleted_at'` to `$dates` on each model.

### Task 19.4 — Delete dead code and cleanup (2 hrs)
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
| 3 | Activity Constraints (7 sub-tasks) | P1 | 2 days | Phase 1 |
| 4 | Performance Optimization | P1 | 2 days | None |
| 5 | Room Allocation | P1 | 3 days | Phase 1 |
| 6 | Stub Controllers & Views | P1 | 2 days | Phase 2 |
| 7 | Analytics | P2 | 5 days | Phase 5 |
| 8 | Refinement | P2 | 4 days | Phase 5 |
| 9 | Substitution | P2 | 5 days | Phase 5 |
| 10 | API & Async | P2 | 3 days | Phase 5 |
| **11** | **Constraint Architecture Foundation** | **P1** | **3 days** | Phase 3 |
| **12** | **Teacher Constraints (Cat B: 35 rules)** | **P1** | **5 days** | Phase 11 |
| **13** | **Class/Student Constraints (Cat C: 28 rules)** | **P1** | **4 days** | Phase 11 |
| **14** | **Room & Space Constraints (Cat E: 26 rules)** | **P2** | **5 days** | Phase 5, 11 |
| **15** | **Inter-Activity Constraints (Cat H: 21 rules)** | **P1** | **8 days** | Phase 11 |
| **16** | **Global Policy + Activity Expansion (Cat G+D)** | **P2** | **3 days** | Phase 11 |
| **17** | **DB-Configurable PHP Classes (Cat F)** | **P2** | **3 days** | Phase 11 |
| 18 | Testing | P3 | 5 days | Phase 12-17 |
| 19 | Code Quality | P3 | 3 days | Phase 6 |
| **Total** | | | **~69 days** | |

### Constraint Phases Subtotal: 31 days (was 5 days)

| Constraint Phase | Rules Covered | Effort |
|-----------------|--------------|--------|
| Phase 11: Architecture | Foundation for all | 3 days |
| Phase 12: Teacher (B) | 35 rules | 5 days |
| Phase 13: Class (C) | 28 rules | 4 days |
| Phase 14: Room (E) | 26 rules | 5 days |
| Phase 15: Inter-Activity (H) | 21 rules | 8 days |
| Phase 16: Global + Activity (G+D) | 14 rules | 3 days |
| Phase 17: DB Classes (F) | ~12 rules | 3 days |
| **Subtotal** | **~136 rules** | **31 days** |

### Suggested Execution Order (Critical Path)

```
Week 1:   Phase 1 (bugs) + Phase 2 (security) — MUST DO FIRST
Week 2:   Phase 3 (activity constraints) + Phase 4 (performance)
Week 3:   Phase 5 (room allocation) + Phase 6 (stubs/views)
Week 4:   Phase 11 (constraint architecture) + Phase 15 Tasks 15.1, 15.5 (inter-activity foundation + day/period pinning)
Week 5:   Phase 12 (teacher constraints B)
Week 6:   Phase 13 (class constraints C) + Phase 15 Tasks 15.2-15.4 (same-time, consecutive, not-overlapping)
Week 7:   Phase 15 Tasks 15.6-15.8 (remaining inter-activity) + Phase 16 (global + activity expansion)
Week 8:   Phase 7 (analytics) + Phase 17 (DB constraint classes)
Week 9:   Phase 8 (refinement) + Phase 14 (room constraints)
Week 10:  Phase 9 (substitution) + Phase 10 (API)
Week 11:  Phase 18 (testing)
Week 12:  Phase 19 (code quality) + buffer
```

### Minimum Viable for School Deployment (Phases 1-6 + 11 + 15.5)

**Effort:** ~16 days (~3+ weeks)
**Result:** Generation works with auth, activity constraints, room allocation, day/period pinning (School Reqs #1, #14), no crashes.
**Constraint coverage:** ~45 rules (A + basic D + basic F + H8 + H20-H22)

### School-Ready with Core Constraints (add Phases 12-13 + 15)

**Effort:** ~33 days (~7 weeks)
**Result:** Above + teacher limits/preferences + class rules + school-specific requirements (#2, #4, #6) + inter-activity relationships
**Constraint coverage:** ~110 rules

### Full Feature Complete (Phases 1-19)

**Effort:** ~69 days (~14 weeks)
**Result:** Full analytics, refinement, substitution, API, 136+ constraint rules, comprehensive testing.
**Constraint coverage:** ~155 rules (100%)

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
| Phase 11 (constraint architecture) | 3 days | Unlocks all constraint phases | **High** |
| Task 15.5 (day/period pinning H20-H22) | 1 day | School Reqs #1, #14 met | **High** |
| Task 13.3 (school-specific constraints) | 1 day | School Reqs #2, #4, #6 met | **High** |
