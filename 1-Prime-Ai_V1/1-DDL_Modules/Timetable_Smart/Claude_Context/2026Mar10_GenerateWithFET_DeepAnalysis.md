# generateWithFET() — Deep Analysis & Improvement Plan
**Date:** 2026-03-10
**Scope:** Full pipeline analysis from controller entry to DB persistence
**Constraint:** NO renames of functions/files/models/variables. NO breaking changes.

---

## TABLE OF CONTENTS

1. [Architecture Summary](#1-architecture-summary)
2. [generateWithFET() Step-by-Step Analysis](#2-generatewithfet-step-by-step-analysis)
3. [FETSolver Deep Dive](#3-fetsolver-deep-dive)
4. [Data Flow Mapping](#4-data-flow-mapping)
5. [Performance Observations](#5-performance-observations)
6. [Query Optimization Recommendations](#6-query-optimization-recommendations)
7. [Code Quality Improvements](#7-code-quality-improvements)
8. [Risk Areas & Critical Bugs](#8-risk-areas--critical-bugs)
9. [Two Save Paths (storeTimetable vs saveGeneratedTimetable)](#9-two-save-paths)
10. [Prioritized Action Plan](#10-prioritized-action-plan)

---

## 1. ARCHITECTURE SUMMARY

### Pipeline Overview
```
HTTP Request (POST)
    │
    ▼
SmartTimetableController::generate() ─── wrapper, merges defaults
    │
    ▼
SmartTimetableController::generateWithFET()  ─── lines 2482-2823
    │
    ├── 1. Validate request inputs
    ├── 2. Load data: classSections, academicSessions, timetableTypes, periodSets, activities, days, periods
    ├── 3. Create DatabaseConstraintService → loads ConstraintManager from DB
    ├── 4. Create FETSolver(days, periods, constraintManager, options)
    ├── 5. solver.solve(activities) → entries[]
    ├── 6. Build schoolGrid[classKey][dayId][periodId] = activityId
    ├── 7. Build selectedTeacherBySlot, conflicts, diagnostics, teacherAudit
    ├── 8. Store EVERYTHING in PHP session
    └── 9. Return preview Blade view
         │
         ▼  (User clicks "Save")
    storeTimetable() ─── lines 486-761 (primary save, well-structured)
        OR
    saveGeneratedTimetable() ─── lines 2828-2905 (legacy save, broken)
```

### Key Components

| Component | File | Lines | Purpose |
|-----------|------|-------|---------|
| Controller | `SmartTimetableController.php` | 2993 | Orchestration, data loading, session management |
| FETSolver | `Services/Generator/FETSolver.php` | ~2100 | Core algorithm: backtracking → greedy → rescue → forced |
| ConstraintManager | `Services/Constraints/ConstraintManager.php` | 254 | Hard/soft constraint evaluation with caching |
| DatabaseConstraintService | `Services/DatabaseConstraintService.php` | 117 | Loads constraints from DB into ConstraintManager |
| ConstraintFactory | `Services/Constraints/ConstraintFactory.php` | ~242 | Maps DB constraint types to PHP classes |
| TimetableSolution | `Services/Solver/TimetableSolution.php` | — | In-memory placement tracking |
| Slot | `Services/Solver/Slot.php` | — | Value object: classKey + dayId + startIndex |

### Constraint Architecture (Dual System — Partially Connected)
There are TWO constraint systems:

1. **DatabaseConstraintService** (DB-driven): Loads `tt_constraints` → `ConstraintFactory` → creates `TimetableConstraint` objects → registered in `ConstraintManager`. Used by `checkHardConstraints()` / `evaluateSoftConstraints()`.

2. **FETSolver built-in rules** (hardcoded): `disallowConsecutivePeriods`, `singleActivityOncePerDayUntilOverflow`, `pinActivitiesByPeriod`, `enforceClassTeacherFirstLecture`. Checked in `isBasicSlotAvailable()` BEFORE the ConstraintManager is consulted.

**Critical insight**: The built-in rules are NOT registered in ConstraintManager. They run as pre-checks in `canPlaceWithConstraints()` via `isBasicSlotAvailable()`. If the DB has no constraints seeded, the algorithm still works because of these hardcoded rules.

### Algorithm Phases (Inside FETSolver.solve())
```
1. expandActivitiesByWeeklyPeriods() — activity × weekly_periods → expanded instances
2. orderActivitiesByDifficulty() — score-based sort (high weekly periods first)
3. generateInitialSolution()
   ├── Phase A: backtrack() — CSP with 25s timeout, 50K iteration limit
   │   └── On success → return solution
   └── Phase B: generateGreedySolution() — fallback if backtracking fails
       ├── Primary pass — try with constraints
       ├── Teacher shuffle — try alternative teachers on conflict
       ├── Rescue pass — relax pinning, daily cap, consecutive, class-teacher
       └── Forced placement — ignore ALL constraints, allow double-booking
4. convertSolutionToEntries() — solution → flat entry[] array
```

---

## 2. generateWithFET() STEP-BY-STEP ANALYSIS

### Line-by-Line Breakdown (SmartTimetableController.php:2482-2823)

#### Step 1: Validation (lines 2486-2498)
```php
$validated = $request->validate([
    'academic_term_id' => 'required|exists:sch_academic_term,id',
    'timetable_type_id' => 'required|exists:tt_timetable_types,id',
    // ... boolean toggles + max_generation_time + max_retry_attempts
]);
```
**Issue**: `max_retry_attempts` is validated but never used (single-attempt mode).

#### Step 2: Load Reference Data (lines 2522-2549)
```
$classSections     = loadClassSections()                    ← needed for filtering
$academicSessions  = AcademicSession::get()                 ← ONLY for view
$timetableTypes    = TimetableType::where(...)->get()       ← ONLY for view
$periodSets        = PeriodSet::where(...)->get()           ← ONLY for view
$academicSession   = AcademicSession::current()->firstOrFail() ← needed for constraints
$activities        = loadActivitiesForActiveClassSections() ← CORE DATA
$days              = loadSchoolDays()                       ← CORE DATA
$periods           = loadPeriodSet()                        ← CORE DATA
```
**Issue**: `academicSessions`, `timetableTypes`, `periodSets` are loaded before generation runs but only used for the preview view. These 3 queries should be deferred to after generation.

#### Step 3: Load Constraints (lines 2558-2587)
```php
$constraintService = new DatabaseConstraintService();
$constraintManager = $constraintService->loadConstraintsForGeneration($academicSession->id, [...]);
```
- Queries `tt_constraints` WHERE `is_active=1` AND within effective date range
- Each constraint row → `ConstraintFactory::createFromDatabase()` → concrete `TimetableConstraint` instance
- Registered in ConstraintManager as hard (is_hard=true) or soft

**Performance**: Each constraint logs an `\Log::info()` during load — N log writes for N constraints.

#### Step 4: set_time_limit Bug (line 2591)
```php
set_time_limit($validated['max_generation_time'] * 60);
```
**BUG**: `max_generation_time` is already in seconds (validated as `max:300`, default 120). Multiplying by 60 sets the limit to 120×60 = 7200 seconds (2 hours). Should be:
```php
set_time_limit($maxTimeSeconds);
```

#### Step 5: Create Solver & Generate (lines 2605-2616)
```php
$solver = new FETSolver($days, $periods, $constraintManager, $options);
$entries = $solver->solve($activities);
```
Single synchronous call. No timeout monitoring at this level. The 25-second backtrack timeout is internal to FETSolver.

#### Step 6: Build schoolGrid (lines 2636-2668)
```php
foreach ($entries as $entry) {
    $classKey = $activity->class->code . '-' . $activity->section->code;
    $schoolGrid[$classKey][$entry['day_id']][$entry['period_id']] = $entry['activity_id'];
    $selectedTeacherBySlot[$classKey][...] = ['teacher_id' => ..., 'assignment_role_id' => ...];
}
```
- Conflict detection here is grid-level: if two entries map to same [classKey][day][period], second one is skipped and recorded as conflict.
- `$classKey` is derived from `class->code` and `section->code` (loaded via eager load on activity).

#### Step 7: Session Storage (lines 2731-2778)
Stores 10 session keys:
- `generated_timetable_grid` — the schoolGrid array
- `generated_activities` — full Eloquent collection with relations
- `generated_days` / `generated_periods` — full Eloquent collections
- `generated_class_sections` — filtered
- `generated_conflicts` — conflict array
- `generated_selected_teacher_by_slot` — teacher assignments
- `generated_forced_placements` — forced placement details
- `generation_run_meta` — algorithm params, timing
- `generation_run_stats` — stats, diagnostics, teacher audit

**Issue**: Storing full Eloquent model collections (with loaded relations) in PHP session. For 300+ activities with eager-loaded relations, this can be 10-50MB of serialized data. Risk of session storage limits (file/Redis/database backends have size limits).

#### Step 8: Return Preview View (lines 2785-2803)
Returns `smarttimetable::preview.index` with all data passed directly to the view (not from session). View also receives `algorithm_stats`, `placement_diagnostics`, `forced_placements`.

---

## 3. FETSOLVER DEEP DIVE

### File: `Services/Generator/FETSolver.php` (~2100 lines)

### Constructor (lines 77-103)
Accepts: Collection $days, Collection $periods, ?ConstraintManager, array $options
- Extracts boolean flags from options
- Calls `calculateTeachingPeriods()` → builds `teachingIndices[]` (period array indices that are NOT break/lunch)
- Calculates `relaxedPinningZoneIndices` (last 2 teaching periods after lunch)

### solve() Method (lines 108-182) — Entry Point
1. Resets teacher assignment caches
2. `hydrateTeacherNameCache()` — pre-builds name cache from eager-loaded activity→teachers→teacher→user relationships
3. If `enforceClassTeacherFirstLecture`: queries `sch_class_section_jnt` for class_teacher_id, then `sch_teachers` for teacher IDs
4. `createConstraintContext()` → builds stdClass with occupied/teacherOccupied tracking arrays
5. `expandActivitiesByWeeklyPeriods()` → clones activities, assigns instance_ids ("activityId-N"), picks random teacher per original activity
6. **Single attempt**: `generateInitialSolution()` → backtrack or greedy
7. `convertSolutionToEntries()` → flat entry array
8. Calculates stats & returns

### expandActivitiesByWeeklyPeriods() (lines 206-246)
- Each activity with `required_weekly_periods=N` → N cloned instances
- Each clone gets: `instance_id`, `instance_number`, `original_activity_id`, `needs_placement`
- **Smart teacher selection**: `pickRandomTeacherAssignment()` — ranks eligible teachers by current load (number of already-assigned activities), takes top-3 least busy, picks random from those
- Final `shuffle()` on expanded array — IMPORTANT for avoiding systematic patterns

### orderActivitiesByDifficulty() (lines 1467-1521)
Scoring weights:
- `required_weekly_periods >= 6` → +10000
- `required_weekly_periods` × 500
- `duration_periods` × 3
- Teacher count × 2
- `is_compulsory` → +20
- Class teacher activity → +1000 + priority×20
- Non-class-teacher activity (when class has class teacher) → -150

Sorted descending (most difficult first).

### backtrack() (lines 363-432)
Standard CSP backtracking:
- Checks timeout (25s), iteration limit (50K), backtrack limit (50K)
- Gets possible slots → tries each → places → recurse → backtrack on failure
- `canPlaceWithConstraints()` called before each placement attempt

### generateGreedySolution() (lines 970-1462) — Multi-Pass
**Pass 1 (Primary)**: For each activity, try slots with full constraints. On teacher conflict, try `tryAlternativeTeacher()`.

**Pass 2 (Rescue)**: For unplaced activities, relax pinning + daily cap + consecutive + class-teacher-first. Still try alternative teachers.

**Pass 3 (Forced Placement)**: Only for 1-period activities. Three sub-passes:
  a. Try slots where class is free but ignore teacher conflicts → `solution.forcePlace()`
  b. If class has free slots but teacher busy → force-place with teacher conflict flag
  c. Last resort → force double-book (two activities same slot)

### canPlaceWithConstraints() (lines 437-470)
Two-layer check:
1. `isBasicSlotAvailable()` — built-in hardcoded rules (pinning, daily cap, consecutive, class-teacher-first, class occupied, teacher occupied)
2. `constraintManager.checkHardConstraints()` — DB-loaded constraints

### Built-in Hard Rules in isBasicSlotAvailable() (lines 475-534)
| Rule | Field | Logic |
|------|-------|-------|
| Pinned periods | `pinActivitiesByPeriod` | First placement sets affinity; subsequent must match (with overflow/relaxed zone exceptions) |
| Daily cap | `singleActivityOncePerDayUntilOverflow` | Max ceil(weeklyPeriods/days) per day; 1/day if weeklyPeriods ≤ days |
| No consecutive | `disallowConsecutivePeriods` | Same original activity can't occupy adjacent periods; multi-period blocks always rejected |
| Class-teacher first | `enforceClassTeacherFirstLecture` | First period reserved for class-teacher's activity (if eligible) |
| Class occupied | (always) | `context.occupied[classKey][dayId][periodId]` check |
| Teacher occupied | (always) | `context.teacherOccupied[teacherId][dayId][periodId]` check |

### Teacher Selection Strategy
- **Initial**: `pickRandomTeacherAssignment()` — load-balanced random from top-3 least busy
- **Greedy fallback**: `tryAlternativeTeacher()` — tries other eligible teachers when primary is occupied
- **One teacher per activity**: All expanded instances of same original activity share same teacher (set in `activityTeacherAssignments[activityId]`)
- **Instance override**: Greedy/rescue pass can override per-instance via `instanceTeacherAssignments[instanceId]`

---

## 4. DATA FLOW MAPPING

### Input → Processing → Output

```
┌──────────────────────────────────────────────────────────────┐
│ DATABASE READS (generateWithFET)                              │
├──────────────────────────────────────────────────────────────┤
│ sch_class_section_jnt (is_active) → classSections            │
│ sch_academic_session (all)        → academicSessions ★VIEW   │
│ tt_timetable_types (is_active)    → timetableTypes ★VIEW     │
│ tt_period_sets (is_active)        → periodSets ★VIEW         │
│ sch_academic_session (current)    → academicSession           │
│ tt_activities (is_active)         → activities [EAGER LOAD:   │
│   class, section, subject, studyFormat, subjectStudyFormat,  │
│   subjectType, teachers, classSubjectGroup,                  │
│   classSubjectSubgroup, requiredRoomType, preferredRoomType] │
│ tt_school_days (schoolDays scope) → days                     │
│ tt_period_set_periods (+periodType, is_active, ordered)→periods│
│ tt_constraints (active, in date range) → constraints          │
│                                                               │
│ IF class_teacher_first_lecture:                                │
│   sch_class_section_jnt (class_teacher_id) → class teachers  │
│   sch_teachers (by user_id)       → teacher IDs              │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ PROCESSING (FETSolver.solve)                                  │
├──────────────────────────────────────────────────────────────┤
│ activities → expand by weekly_periods → shuffled instances    │
│ instances → orderByDifficulty → sorted array                 │
│ sorted → backtrack(25s timeout)                              │
│   │ fail → greedy(primary→rescue→forced)                     │
│ solution → convertToEntries → entry[]                        │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ POST-PROCESSING (generateWithFET cont.)                       │
├──────────────────────────────────────────────────────────────┤
│ entries → schoolGrid[classKey][dayId][periodId]               │
│ entries → selectedTeacherBySlot[classKey][dayId][periodId]    │
│ entries → conflicts[] (grid-level duplicates)                 │
│ entries → diagnostics (unplaced/partial/conflict activities)  │
│ entries → selectedTeacherAudit (per-activity teacher usage)   │
│ classSections → filtered to only those IN schoolGrid          │
│                                                               │
│ ALL above → stored in PHP session (10 keys)                   │
│ ALL above → passed to preview.index Blade view                │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│ SAVE (storeTimetable — primary path)                          │
├──────────────────────────────────────────────────────────────┤
│ session → schoolGrid, activitiesById, periods,               │
│           selectedTeacherBySlot, forcedPlacements,            │
│           runMeta, runStats                                   │
│                                                               │
│ DB::beginTransaction()                                        │
│ 1. Create Timetable record                                    │
│ 2. Create GenerationRun record (full audit)                   │
│ 3. Loop: schoolGrid → TimetableCell::create() per slot       │
│    - Attach teacher via cell->teachers()->attach()            │
│ 4. Update timetable stats                                     │
│ DB::commit()                                                  │
│ Session cleanup (10 keys forgotten)                           │
└──────────────────────────────────────────────────────────────┘
```

### Data Types at Each Stage

| Stage | Data Shape | Estimated Size (20 class-sections, 400 activities) |
|-------|-----------|-----------------------------------------------------|
| Activities loaded | Collection<Activity> with 10 eager-loaded relations | ~5-10 MB serialized |
| Expanded instances | array of cloned Activity objects (~1200-1500 instances) | ~15-25 MB in memory |
| Solution (TimetableSolution) | placements[instanceId] → Slot[] | ~100 KB |
| Entries | flat array of ~1200 entry maps | ~500 KB |
| schoolGrid | nested array [class][day][period] = activityId | ~50 KB |
| Session storage | serialized PHP — ALL of above including full Eloquent models | ~10-50 MB |

---

## 5. PERFORMANCE OBSERVATIONS

### P1: Session Size — CRITICAL
**Location**: SmartTimetableController.php:2731-2778
**Issue**: Full Eloquent collections (activities with 10 eager-loaded relations) stored in session. For 400 activities × 10 relations, serialized size can reach 50MB.
**Impact**: File-based sessions may silently truncate. Redis/database sessions may fail or slow down.
**Fix**: Convert to plain arrays before storing. Only store IDs and essential fields. Reload from DB on save.

### P2: Expanded Activities Clone Overhead — HIGH
**Location**: FETSolver.php:206-246
**Issue**: `clone $activity` creates deep copies of Eloquent models with all relations. 400 activities × 5 weekly avg = 2000 clones × full model + relations.
**Impact**: Memory spike of 50-100MB during generation.
**Fix**: Create lightweight DTO objects for expanded instances instead of cloning full Eloquent models. Only copy fields needed: id, class_id, section_id, duration_periods, required_weekly_periods, teachers.

### P3: set_time_limit Bug — HIGH
**Location**: SmartTimetableController.php:2591
**Issue**: `set_time_limit($validated['max_generation_time'] * 60)` — input is already in seconds, multiplication gives 7200s default.
**Fix**: `set_time_limit($maxTimeSeconds)` (line 2595 already has `$maxTimeSeconds`).

### P4: Greedy isClassSlotFree/isTeacherSlotFree — O(N²) — MEDIUM
**Location**: FETSolver.php:1537-1607
**Issue**: In the forced placement pass, `isClassSlotFree()` and `isTeacherSlotFree()` iterate ALL placements (entire solution) for every slot check. With 1200 placements × 60 slots per day × 6 days = massive iterations.
**Fix**: These methods should use `context.occupied` and `context.teacherOccupied` dictionaries (which are already maintained), not iterate solution.getPlacements().

### P5: Duplicate Stat Calculation — LOW
**Location**: SmartTimetableController.php:2615+2670
**Issue**: `$stats = $solver->getStats()` called twice (line 2615 and 2670). Second call overwrites the first (which added generation_time). The stats object isn't copied, so this is just a redundant call, but line 2615-2616 adds `generation_time` and then line 2670-2671 replaces the whole `$stats` and re-adds it.
**Fix**: Remove the first `$stats` assignment at line 2615-2616.

### P6: Teacher Name Resolution — N+1 Database Queries — MEDIUM
**Location**: FETSolver.php:1697-1758
**Issue**: `getTeacherName()` does two DB queries per uncached teacher (one on `users`, one on `sys_users`). During forced placement pass logging, this can trigger dozens of queries.
**Fix**: Already partially mitigated by `hydrateTeacherNameCache()` at the start. But cache misses still hit DB. Consider pre-loading all teachers for the active activities at init time.

### P7: Excessive Logging — MEDIUM
**Location**: Throughout FETSolver.php
**Issue**: `\Log::debug()` on every constraint violation (line 453), every slot evaluation that fails, every rescue pass attempt. During backtracking with 50K iterations, this can generate thousands of log entries.
**Fix**: Gate debug logging behind a verbose flag or config option. Only log warnings and above by default.

### P8: academicSessions/timetableTypes/periodSets Pre-loaded Unnecessarily — LOW
**Location**: SmartTimetableController.php:2526-2532
**Issue**: Three queries fired before generation starts, but their results are only used in the view return (line 2796-2798).
**Fix**: Move these queries to after the solver returns, or lazy-load them.

---

## 6. QUERY OPTIMIZATION RECOMMENDATIONS

### Q1: storeTimetable N+1 on cell creation
**Location**: SmartTimetableController.php:647-713
**Current**: Triple-nested loop creates one `TimetableCell::create()` + one `cell->teachers()->attach()` per slot. For 1200 slots = 1200 INSERTs + 1200 pivot INSERTs.
**Fix**: Batch insert using `TimetableCell::insert([...])` for all cells, then batch insert pivot rows. Estimated: 2 queries instead of 2400.

```php
// Pseudocode for batch insert
$cellRows = [];
$pivotRows = [];
foreach ($schoolGrid as $classKey => $dayGrid) {
    foreach ($dayGrid as $dayOfWeek => $periodGrid) {
        foreach ($periodGrid as $periodId => $activityId) {
            $cellRows[] = [...]; // build cell data
        }
    }
}
TimetableCell::insert($cellRows);
// Then batch insert pivot rows with cell_ids
```

### Q2: loadActivitiesForActiveClassSections loads ALL active activities
**Location**: SmartTimetableController.php:790-811
**Current**: `Activity::where('is_active', true)->with([10 relations])->get()`. Loads ALL activities regardless of academic term or timetable type.
**Fix**: Filter by `academic_term_id` from the validated request to avoid loading activities from other terms.

### Q3: DatabaseConstraintService double-queries on getConstraintStatistics
**Location**: DatabaseConstraintService.php:93-105
**Issue**: `getConstraintStatistics()` calls `loadActiveConstraints()` which runs the same query as `loadConstraintsForGeneration()`. If both are called, the query runs twice.
**Note**: Currently not called in the generation path, but worth noting.

### Q4: ClassSection eager loading missing
**Location**: SmartTimetableController.php:824-827
**Current**: `ClassSection::where('is_active', true)->get()` — no eager loading of `class` or `section`.
**Impact**: When building classKey from `$classSection->class->code`, this triggers N+1 queries.
**Fix**: `ClassSection::with(['class', 'section'])->where('is_active', true)->get()`

---

## 7. CODE QUALITY IMPROVEMENTS

### CQ1: Two Save Methods — Confusing
**Location**: `storeTimetable()` (line 486) vs `saveGeneratedTimetable()` (line 2828)
**Issue**: Two completely different save implementations exist. `storeTimetable` is well-structured (transaction, GenerationRun, TimetableCell with teachers). `saveGeneratedTimetable` is legacy (no transaction, creates bare `Timetable` records without cells, deletes by academic_session_id blindly).
**Fix**: Remove or deprecate `saveGeneratedTimetable()`. Ensure all routes point to `storeTimetable()`.

### CQ2: Debug Methods Still Present (~330 lines)
**Location**: Lines 958-1250+ (`debugPlacementIssue`, `debugPeriods`, `diagnoseLunchProblem`, `debugActivityDurations`, `seederTest`)
**Fix**: Move to a separate `DebugController` or remove entirely. They reference `ImprovedTimetableGenerator` which may no longer exist.

### CQ3: Commented-Out Constraint Registration
**Location**: `createConstraintManager()` (lines 245-294) — ALL constraints are commented out.
**Issue**: This method is dead code. The active path uses `DatabaseConstraintService` instead.
**Fix**: Remove `createConstraintManager()` and `createConstraintManagerFromDatabase()` (lines 299-322) and `resolveConstraintClass()` (lines 327-339). These are superseded by `DatabaseConstraintService`.

### CQ4: createConstraintContext() passes mutable stdClass
**Location**: FETSolver.php:187-200
**Issue**: Context is a stdClass with `occupied`, `teacherOccupied`, `entries` arrays. Backtracking clones context via `clone $context` (line 403), but stdClass shallow-clone means nested arrays are NOT deep-copied. The `simulatePlacement()` mutates the cloned context, and since arrays are copy-on-write in PHP, this actually works correctly — but it's fragile and confusing.
**Risk**: If anyone changes arrays to objects or ArrayObject, the backtracking context isolation breaks.

### CQ5: ConstraintManager evaluationCache never cleared during generation
**Location**: ConstraintManager.php:236-238
**Issue**: Cache key is `type-classKey-dayId-startIndex-activityId`. During backtracking, placements change but the cache isn't invalidated. A slot that previously passed constraints may fail after backtracking changes the context.
**Impact**: Could lead to incorrect constraint evaluation during backtracking. However, the context is passed to `constraint.passes()` directly (not cached), so the cache may not cause issues if constraints don't use the cached result for decisions that depend on current placements.
**Fix**: Call `constraintManager.clearCache()` after each backtrack, or remove caching during backtracking mode.

### CQ6: Inconsistent activity field usage
**Location**: Throughout FETSolver
**Issue**: Expanded activities use dynamically added properties (`instance_id`, `original_activity_id`, `selected_teacher_id`, etc.) via PHP's magic `__set`. Since these are cloned Eloquent models, the properties work but are not type-safe and won't show up in IDE autocomplete.
**Fix**: Create a lightweight `ExpandedActivityDTO` class with typed properties.

### CQ7: No GenerationRun created in generateWithFET
**Location**: SmartTimetableController.php:2731-2778
**Issue**: The generation metadata is stored in session (`generation_run_meta`, `generation_run_stats`) but no `GenerationRun` database record is created until the user saves. If the user abandons the preview, no audit trail exists.
**Fix**: Create `GenerationRun` with status `PREVIEW` immediately after generation, update to `COMPLETED` on save. This also enables tracking abandoned generations.

---

## 8. RISK AREAS & CRITICAL BUGS

### R1: CRITICAL — set_time_limit multiplied by 60
**Location**: SmartTimetableController.php:2591
**Bug**: `set_time_limit($validated['max_generation_time'] * 60)` — default 120 seconds × 60 = 7200 seconds
**Impact**: PHP process can run for 2 hours instead of 2 minutes
**Severity**: HIGH — could block web server workers

### R2: CRITICAL — saveGeneratedTimetable deletes all timetables for session
**Location**: SmartTimetableController.php:2843
```php
Timetable::where('academic_session_id', $academicSessionId)->delete();
```
**Bug**: This deletes ALL timetables for the academic session, not just the one being replaced. If multiple timetables exist (different types, different terms), they're all destroyed.
**Impact**: DATA LOSS
**Fix**: This method should be removed or guarded. `storeTimetable()` is the correct save path.

### R3: HIGH — Session-based storage is unreliable
**Location**: SmartTimetableController.php:2731
**Risk**: PHP session storage backends have size limits:
- File: No hard limit but slow for large data
- Redis: 512MB default but serialization overhead
- Database: Column size limits (TEXT = 64KB, LONGTEXT = 4GB)
**Impact**: Silent data truncation → corrupt preview → save fails
**Fix**: Store in cache with TTL or a dedicated temp table.

### R4: HIGH — No concurrency protection
**Location**: generateWithFET + storeTimetable
**Risk**: Two users generating simultaneously → both write to same session keys → corrupt data. Or: user generates, another user generates for same academic session, first user saves → overwrites second user's generation.
**Fix**: Add `user_id` or UUID to session keys. Add optimistic locking on save.

### R5: MEDIUM — Backtracking cache invalidation (see CQ5)
**Risk**: ConstraintManager evaluation cache may return stale results during backtracking.

### R6: MEDIUM — violatesNoConsecutiveRule blocks ALL multi-period activities
**Location**: FETSolver.php:636-639
```php
if ($duration > 1) {
    return true; // Multi-period blocks are inherently consecutive
}
```
**Bug**: This means any activity with `duration_periods > 1` is ALWAYS considered a consecutive violation. Combined with `disallowConsecutivePeriods = true`, NO multi-period activities can ever be placed in the primary or backtracking pass. They only get placed in the rescue pass (which relaxes consecutive rule).
**Impact**: Multi-period activities (labs, hobby classes) are systematically deprioritized.
**Fix**: The consecutive rule should check if the SAME activity is in adjacent slots ACROSS different instances, not within a single multi-period block. Rewrite to:
```php
if ($duration > 1) {
    return false; // A single multi-period block is NOT a "consecutive" violation
}
```

### R7: LOW — Forced placements tracked per originalActivityId (not instance)
**Location**: FETSolver.php:1349-1351
**Issue**: `forcedPlacementsWithConflicts[$originalActivityId]` — if multiple instances of the same activity are force-placed, only the last one is tracked.
**Fix**: Key by `instanceId` instead.

---

## 9. TWO SAVE PATHS

### storeTimetable() — PRIMARY (lines 486-761)
- Uses `DB::beginTransaction()`
- Creates `Timetable` record with proper UUID, code, metadata
- Creates `GenerationRun` record with full audit data
- Creates `TimetableCell` per slot with:
  - `class_group_id` / `class_subgroup_id` properly resolved
  - `period_ord` conversion from period_id
  - Conflict details from forced placements
  - Teacher attachment via pivot table
- Updates timetable stats after all cells created
- Cleans up session on success
- **Route**: POST to `smart-timetable-management.store-timetable`

### saveGeneratedTimetable() — LEGACY (lines 2828-2905)
- NO transaction
- Deletes ALL existing timetables for academic_session_id (DANGEROUS)
- Creates `Timetable` records directly (not TimetableCell — uses wrong model!)
- No GenerationRun record
- No teacher attachment
- No conflict tracking
- **Should be deprecated/removed**

---

## 10. PRIORITIZED ACTION PLAN

### Phase 1: Critical Fixes (Do First)
| # | Issue | Location | Effort |
|---|-------|----------|--------|
| 1 | Fix set_time_limit ×60 bug | Controller:2591 | 1 min |
| 2 | Remove/disable `saveGeneratedTimetable()` | Controller:2828-2905 | 5 min |
| 3 | Fix `violatesNoConsecutiveRule` for multi-period | FETSolver:636-639 | 10 min |

### Phase 2: Performance (Do Next)
| # | Issue | Location | Effort |
|---|-------|----------|--------|
| 4 | Convert session storage to plain arrays | Controller:2731-2778 | 30 min |
| 5 | Replace isClassSlotFree/isTeacherSlotFree with context lookups | FETSolver:1537-1607 | 20 min |
| 6 | Batch-insert TimetableCell + pivot in storeTimetable | Controller:594-713 | 45 min |
| 7 | Add academic_term_id filter to loadActivitiesForActiveClassSections | Controller:790-811 | 5 min |
| 8 | Defer academicSessions/timetableTypes/periodSets loading | Controller:2526-2532 | 5 min |
| 9 | Add eager loading to loadClassSections | Controller:824-827 | 2 min |

### Phase 3: Code Quality (Do When Convenient)
| # | Issue | Location | Effort |
|---|-------|----------|--------|
| 10 | Remove debug methods to DebugController | Controller:958-1250 | 20 min |
| 11 | Remove dead constraint methods | Controller:245-339 | 5 min |
| 12 | Gate verbose logging behind config flag | FETSolver (throughout) | 30 min |
| 13 | Clear ConstraintManager cache on backtrack | FETSolver:420 | 5 min |
| 14 | Create GenerationRun on generate (not just save) | Controller:~2670 | 15 min |

### Phase 4: Architecture (Plan Carefully)
| # | Issue | Location | Effort |
|---|-------|----------|--------|
| 15 | Create ExpandedActivityDTO to replace Eloquent clone | FETSolver | 2 hrs |
| 16 | Add concurrency protection (user-scoped sessions + optimistic locking) | Controller | 2 hrs |
| 17 | Replace session with cache/temp table for generation results | Controller | 3 hrs |
| 18 | Async generation via queue job (for large schools) | Controller + new Job | 4 hrs |

---

## APPENDIX A: Key Method Signatures

```php
// SmartTimetableController
public function generate(Request $request)                    // line 212 — wrapper
public function generateWithFET(Request $request)             // line 2482 — main
public function storeTimetable(Request $request)              // line 486 — primary save
public function saveGeneratedTimetable(Request $request)      // line 2828 — LEGACY save
public function preview(Timetable $timetable)                 // line 341 — DB-based preview
private function loadActivities(int $classId, int $sectionId) // line 767
private function loadActivitiesForActiveClassSections()       // line 790
private function loadClassSections()                          // line 824
private function loadSchoolDays()                             // line 829
private function loadPeriodSet()                              // line 835
private function buildPlacementDiagnostics(...)               // line 2913

// FETSolver
public function solve(Collection $activities): array          // line 108
private function expandActivitiesByWeeklyPeriods(Collection)  // line 206
private function generateInitialSolution(array, $context)     // line 931
private function backtrack(array, int, TimetableSolution, $ctx) // line 363
private function generateGreedySolution(array, $context)      // line 970
private function canPlaceWithConstraints($act, Slot, $ctx, ...) // line 437
private function isBasicSlotAvailable($act, Slot, $ctx, ...)  // line 475
private function getPossibleSlots($act, Solution, $ctx)       // line 838
private function orderActivitiesByDifficulty(array): array    // line 1467
private function convertSolutionToEntries(Solution, Collection) // line 251
private function pickRandomTeacherAssignment($activity): ?array // line 2045
private function tryAlternativeTeacher($act, Slot, $ctx): ?array // (not shown in excerpt)

// DatabaseConstraintService
public function loadConstraintsForGeneration(int $academicSessionId, array $ctx): ConstraintManager

// ConstraintManager
public function checkHardConstraints(Slot, Activity, $context): bool
public function evaluateSoftConstraints(Slot, Activity, $context): float
```

## APPENDIX B: Configuration Defaults

| Config | Value | Location |
|--------|-------|----------|
| max_iterations | 50000 | FETSolver:66 |
| max_backtracks | 50000 | FETSolver:67 |
| backtrack_timeout | 25 seconds | FETSolver:68 |
| disallowConsecutivePeriods | true | FETSolver:72 |
| singleActivityOncePerDayUntilOverflow | true | FETSolver:74 |
| max_generation_time (request) | 120 seconds (max 300) | Controller:2496 |
| class_teacher_first_lecture | true (default) | Controller:2500 |
| pin_activities_by_period | true (default) | Controller:2502 |
| minPeriodsRequired for class-teacher | 6 | FETSolver:1953 |

## APPENDIX C: Files Referenced

```
SmartTimetableController.php  — /Users/bkwork/Herd/laravel/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php (2993 lines)
FETSolver.php                 — /Users/bkwork/Herd/laravel/Modules/SmartTimetable/app/Services/Generator/FETSolver.php (~2100 lines)
DatabaseConstraintService.php — /Users/bkwork/Herd/laravel/Modules/SmartTimetable/app/Services/DatabaseConstraintService.php (117 lines)
ConstraintManager.php         — /Users/bkwork/Herd/laravel/Modules/SmartTimetable/app/Services/Constraints/ConstraintManager.php (254 lines)
ConstraintFactory.php         — /Users/bkwork/Herd/laravel/Modules/SmartTimetable/app/Services/Constraints/ConstraintFactory.php (~242 lines)
TimetableConstraint.php       — /Users/bkwork/Herd/laravel/Modules/SmartTimetable/app/Services/Constraints/TimetableConstraint.php (33 lines)
```
