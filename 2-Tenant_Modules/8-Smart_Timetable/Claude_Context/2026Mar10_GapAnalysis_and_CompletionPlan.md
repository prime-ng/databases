# SmartTimetable Module — Gap Analysis & Step-by-Step Completion Plan
**Date:** 2026-03-10
**Module Path:** `/Users/bkwork/Herd/laravel/Modules/SmartTimetable/`
**Related Context Files:**
- `2026Mar10_SmartTimetable_Context.md` — Full module context
- `2026Mar10_GenerateWithFET_DeepAnalysis.md` — Generator deep analysis
- `2026Mar10_ActivityConstraints_Integration_Plan.md` — Activity constraint integration

---

## TABLE OF CONTENTS

1. [Module Scope — What Should Exist (per Requirements)](#1-module-scope)
2. [Current State — What Actually Exists](#2-current-state)
3. [Gap Analysis — Phase by Phase](#3-gap-analysis)
4. [Broken / Dead Code Inventory](#4-broken--dead-code)
5. [Critical Bugs Summary](#5-critical-bugs)
6. [Step-by-Step Completion Plan](#6-step-by-step-completion-plan)
7. [Dependency Map](#7-dependency-map)

---

## 1. MODULE SCOPE

Based on input documents (`0-tt_Requirement_v3.md`, `3-Process_Flow_v3.md`, `5-Constraints_v1.csv`) and the process flow, the complete SmartTimetable module should cover **8 phases**:

| Phase | Name | Description |
|-------|------|-------------|
| 0 | Prerequisites & Master Setup | School days, shifts, periods, rooms, teachers, academic terms |
| 1 | Requirement Consolidation | Slot requirements, class-subject groups, requirement consolidation |
| 2 | Teacher Availability | Teacher availability calculation, unavailability management |
| 3 | Activity Creation | Generate activities from consolidated requirements |
| 4 | Validation | Pre-generation validation of data completeness |
| 5 | Timetable Generation | Core algorithm: FETSolver (backtracking + greedy + rescue) |
| 6 | Post-Generation | Analytics, reports, room allocation, manual refinement |
| 7 | Publish & Standard Views | Publish timetable, class/teacher/room standard views |
| 8 | Substitution & Maintenance | Teacher absence recording, substitute assignment, pattern learning |

Additionally, there should be:
- **API Layer** — REST endpoints for external consumption
- **Async Generation** — Queue-based generation for large schools
- **Constraint Engine** — DB-driven constraints integrated into generation
- **Room Allocation** — Automatic room assignment based on activity requirements

---

## 2. CURRENT STATE

### 2A. File Counts

| Category | Count | Notes |
|----------|-------|-------|
| Controllers | 27 files | +1 backup file (`SmartTimetableController_29_01_before_store.php`) |
| Models | 84 files | All present and functional |
| Services (active) | ~20 files | In Services/ and subdirectories |
| Services (archived) | 14 files | In `Services/EXTRA_delete_10_02/` |
| Views (blade) | ~178 files | Across 52 directories |
| Seeders | 13 files | For master data |
| Routes | ~75 route definitions | All in `routes/tenant.php` lines 1732-1952 |
| Tests | 0 files | No tests exist |
| DOCS | 13 markdown files | In `Modules/SmartTimetable/DOCS/` |

### 2B. Controllers Inventory

| # | Controller | Status | Key Methods |
|---|-----------|--------|-------------|
| 1 | SmartTimetableController.php | ✅ Active (2993 lines) | index, generate, generateWithFET, storeTimetable, preview, timetableConfig, timetableOperation, timetableMaster, timetableGeneration, timetableReports, timetableValidation, saveGeneratedTimetable + 5 debug methods |
| 2 | ActivityController.php | ✅ Active | index, generateActivities, store, assignTeacherToActivity, findBestTeacherForActivity |
| 3 | RequirementConsolidationController.php | ✅ Active | CRUD + consolidation logic |
| 4 | ConstraintController.php | ✅ Active | CRUD for constraints |
| 5 | ConstraintTypeController.php | ✅ Active | CRUD for constraint types |
| 6 | TimetableController.php | ✅ Active | CRUD for timetable records |
| 7 | TimetableTypeController.php | ✅ Active | CRUD |
| 8 | AcademicTermController.php | ✅ Active | CRUD |
| 9 | PeriodController.php | ✅ Active | CRUD |
| 10 | PeriodSetController.php | ✅ Active | CRUD |
| 11 | PeriodSetPeriodController.php | ✅ Active | CRUD |
| 12 | PeriodTypeController.php | ✅ Active | CRUD |
| 13 | SchoolDayController.php | ✅ Active | CRUD |
| 14 | SchoolShiftController.php | ✅ Active | CRUD |
| 15 | DayTypeController.php | ✅ Active | CRUD |
| 16 | WorkingDayController.php | ✅ Active | CRUD |
| 17 | TeacherAvailabilityController.php | ✅ Active | CRUD + generation |
| 18 | TeacherUnavailableController.php | ✅ Active | CRUD |
| 19 | TeacherAssignmentRoleController.php | ✅ Active | CRUD |
| 20 | RoomUnavailableController.php | ✅ Active | CRUD |
| 21 | SlotRequirementController.php | ✅ Active | CRUD |
| 22 | ClassSubjectSubgroupController.php | ✅ Active | CRUD |
| 23 | TimingProfileController.php | ✅ Active | CRUD |
| 24 | SchoolTimingProfileController.php | ✅ Active | CRUD |
| 25 | TtConfigController.php | ✅ Active | CRUD |
| 26 | TtGenerationStrategyController.php | ✅ Active | CRUD |
| 27 | SmartTimetableController_29_01_before_store.php | ❌ Backup | Should be deleted |

### 2C. Services Inventory

| # | Service | Status | Purpose |
|---|---------|--------|---------|
| 1 | Generator/FETSolver.php | ✅ Active (~2100 lines) | Core algorithm |
| 2 | Generator/ImprovedTimetableGenerator.php | ⚠️ Legacy | Referenced in debug methods only |
| 3 | Generator/FETConstraintBridge.php | ⚠️ Unknown | Needs verification |
| 4 | DatabaseConstraintService.php | ✅ Active | Loads constraints from DB |
| 5 | Constraints/ConstraintManager.php | ✅ Active | Evaluates constraints |
| 6 | Constraints/ConstraintFactory.php | ✅ Active | Creates constraint instances |
| 7 | Constraints/TimetableConstraint.php | ✅ Active | Interface |
| 8 | Constraints/Hard/GenericHardConstraint.php | ✅ Active | Generic hard implementation |
| 9 | Constraints/Hard/HardConstraint.php | ✅ Active | Interface |
| 10 | Constraints/Hard/TeacherConflictConstraint.php | ✅ Active | Teacher conflict check |
| 11 | Constraints/Soft/GenericSoftConstraint.php | ✅ Active | Generic soft (always returns true) |
| 12 | Constraints/Soft/SoftConstraint.php | ✅ Active | Interface |
| 13 | Solver/Slot.php | ✅ Active | Value object |
| 14 | Solver/SlotEvaluator.php | ⚠️ Unknown | Needs verification |
| 15 | Solver/SlotGenerator.php | ⚠️ Unknown | Needs verification |
| 16 | Solver/TimetableSolution.php | ✅ Active | Placement tracking |
| 17 | Storage/TimetableStorageService.php | ⚠️ Unknown | Needs verification |
| 18 | ActivityScoreService.php | ⚠️ Unknown | Needs verification |
| 19 | RoomAvailabilityService.php | ⚠️ Unknown | Needs verification |
| 20 | SubActivityService.php | ⚠️ Unknown | Needs verification |
| — | **EXTRA_delete_10_02/** (14 files) | ❌ Archived | Old constraint implementations, should be deleted |

### 2D. Missing Components (NOT in codebase)

| Component | Expected Location | Status |
|-----------|------------------|--------|
| AnalyticsController | Controllers/ | ❌ MISSING |
| AnalyticsService | Services/ | ❌ MISSING |
| RefinementController | Controllers/ | ❌ MISSING |
| RefinementService | Services/ | ❌ MISSING |
| SubstitutionController | Controllers/ | ❌ MISSING |
| SubstitutionService | Services/ | ❌ MISSING |
| TimetableApiController | Controllers/Api/ | ❌ MISSING |
| StandardTimetableController | Controllers/ | ❌ MISSING |
| GenerateTimetableJob | Jobs/ | ❌ MISSING |
| RoomAllocationPass/Service | Services/ | ❌ MISSING |
| ConflictDetectionService | Services/ | ❌ MISSING |
| ResourceBookingService | Services/ | ❌ MISSING |
| Form Request classes | Http/Requests/ | ❌ MISSING |
| Tests (Feature/Unit) | tests/ | ❌ MISSING |
| API routes | routes/api.php | ❌ MISSING |

---

## 3. GAP ANALYSIS — PHASE BY PHASE

### Phase 0: Prerequisites & Master Setup — ✅ 95% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| School Days CRUD | ✅ Done | SchoolDayController + views |
| Day Types CRUD | ✅ Done | DayTypeController + views |
| Working Days CRUD | ✅ Done | WorkingDayController + views |
| School Shifts CRUD | ✅ Done | SchoolShiftController + views |
| Period Types CRUD | ✅ Done | PeriodTypeController + views |
| Periods CRUD | ✅ Done | PeriodController + views |
| Period Sets CRUD | ✅ Done | PeriodSetController + PeriodSetPeriodController + views |
| Academic Terms CRUD | ✅ Done | AcademicTermController + views |
| Timetable Types CRUD | ✅ Done | TimetableTypeController + views |
| Constraint Types CRUD | ✅ Done | ConstraintTypeController + views |
| Constraints CRUD | ✅ Done | ConstraintController + views |
| Teacher Assignment Roles CRUD | ✅ Done | TeacherAssignmentRoleController + views |
| TT Config CRUD | ✅ Done | TtConfigController + views |
| Generation Strategies CRUD | ✅ Done | TtGenerationStrategyController + views |
| Timing Profiles CRUD | ✅ Done | TimingProfileController + SchoolTimingProfileController + views |
| Room Unavailable CRUD | ✅ Done | RoomUnavailableController + views |
| Teacher Unavailable CRUD | ✅ Done | TeacherUnavailableController + views |
| Seeders for master data | ✅ Done | 13 seeders |
| Master dashboard view | ✅ Done | `timetableMaster()` (line 1634) |
| **Gap:** Validation of seeded data completeness | ⚠️ Partial | `timetableValidation()` exists but only basic checks |

### Phase 1: Requirement Consolidation — ✅ 90% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Slot Requirements CRUD | ✅ Done | SlotRequirementController |
| Class Subject Subgroups CRUD | ✅ Done | ClassSubjectSubgroupController |
| Requirement Consolidation CRUD | ✅ Done | RequirementConsolidationController |
| Consolidation logic | ✅ Done | Generates consolidated requirements from class-subject groups |
| Requirements grouped by class | ✅ Done | Displayed in `timetableOperation()` view |
| **Gap:** Bulk regeneration of requirements | ⚠️ Partial | Route exists but controller methods need verification |

### Phase 2: Teacher Availability — ✅ 85% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Teacher Availability CRUD | ✅ Done | TeacherAvailabilityController |
| Availability generation from profiles | ✅ Done | Auto-calculates from teacher data |
| Teacher unavailability recording | ✅ Done | TeacherUnavailableController |
| Grouped availability display | ✅ Done | In `timetableOperation()` view |
| **Gap:** Teacher availability score calculation | ⚠️ Partial | Fields exist on Activity model but not auto-calculated during generation |
| **Gap:** Teacher workload optimization in generation | ⚠️ Partial | `pickRandomTeacherAssignment()` uses load-balancing but doesn't respect teacher unavailability periods |

### Phase 3: Activity Creation — ✅ 80% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Activity CRUD | ✅ Done | ActivityController + views |
| Generate activities from requirements | ✅ Done | `generateActivities()` method |
| Teacher assignment to activities | ✅ Done | `assignTeacherToActivity()`, `findBestTeacherForActivity()` |
| Activity grouping (Normal/SAC/SAS) | ✅ Done | Three-category display in `timetableOperation()` |
| Sub-activities for shared groups | ✅ Done | SubActivity model + relationships |
| **Gap:** Activity-level constraint fields not populated | ❌ Missing | `preferred_periods_json`, `avoid_periods_json`, `preferred_time_slots_json`, `avoid_time_slots_json` are never auto-populated during activity generation |
| **Gap:** `difficulty_score_calculated` never computed | ❌ Missing | Always defaults to 50 |
| **Gap:** `constraint_count` never computed | ❌ Missing | Always defaults to 0 |
| **Gap:** Bulk activity generation (all classes) | ⚠️ Route exists | `generateAllActivities` route defined, method in ActivityController needs verification |
| **Gap:** Batch generation progress tracking | ⚠️ Route exists | `getBatchGenerationProgress` route defined, needs verification |

### Phase 4: Validation — ✅ 70% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Validation dashboard | ✅ Done | `timetableValidation()` method + view with tabs |
| Activities validation tab | ✅ Done | Checks activity data completeness |
| Teachers validation tab | ✅ Done | Checks teacher availability |
| Constraints validation tab | ✅ Done | Lists active constraints |
| Rooms validation tab | ✅ Done | Checks room data |
| Statistics tab | ✅ Done | Shows counts and summary |
| **Gap:** Pass/Fail/Blocked scoring | ❌ Missing | Per requirements, validation should produce PASSED/FAILED/BLOCKED scores — currently just displays data |
| **Gap:** Blocking generation on critical failures | ❌ Missing | Generation proceeds even if validation fails |
| **Gap:** Teacher availability 5-step calculation | ❌ Missing | Defined in Process_Flow_v3.md but not implemented |

### Phase 5: Timetable Generation — ✅ 75% COMPLETE (Core Logic Done, Gaps in Features)

| Feature | Status | Notes |
|---------|--------|-------|
| FETSolver (backtracking + greedy) | ✅ Done | ~2100 lines, working |
| Activity expansion (weekly periods) | ✅ Done | `expandActivitiesByWeeklyPeriods()` |
| Difficulty-based ordering | ✅ Done | `orderActivitiesByDifficulty()` |
| Teacher conflict detection | ✅ Done | In `isBasicSlotAvailable()` |
| Class-teacher first lecture | ✅ Done | `enforceClassTeacherFirstLecture` flag |
| Period pinning (spread across days) | ✅ Done | `pinActivitiesByPeriod` flag |
| Daily activity cap | ✅ Done | `singleActivityOncePerDayUntilOverflow` |
| Consecutive period prevention | ✅ Done (buggy) | Has R6 bug — blocks ALL multi-period activities |
| Smart teacher selection | ✅ Done | Load-balanced random from top-3 least busy |
| Alternative teacher on conflict | ✅ Done | `tryAlternativeTeacher()` in greedy/rescue pass |
| Rescue pass (relaxed constraints) | ✅ Done | Relaxes pinning, daily cap, consecutive, class-teacher |
| Forced placement pass | ✅ Done | Last resort for 1-period activities |
| DB-driven constraints (ConstraintManager) | ✅ Done | Hard constraints checked via `checkHardConstraints()` |
| Session-based preview | ✅ Done | Stores grid in PHP session |
| Preview view | ✅ Done | `preview/index.blade.php` with 8 partials |
| Placement diagnostics | ✅ Done | `buildPlacementDiagnostics()` |
| Teacher audit trail | ✅ Done | Per-activity teacher usage tracking |
| Save to database (storeTimetable) | ✅ Done | With transaction, GenerationRun, TimetableCells |
| **Gap:** Activity-level soft constraints ignored | ❌ Missing | 22 fields on Activity model not used by FETSolver (see Constraints Integration Plan) |
| **Gap:** `evaluateSoftConstraints()` never called | ❌ Missing | Method exists in ConstraintManager but FETSolver doesn't invoke it |
| **Gap:** Room allocation during/after generation | ❌ Missing | `room_id` always NULL on TimetableCell |
| **Gap:** Per-activity `allow_consecutive` override | ❌ Missing | Global flag only |
| **Gap:** Per-activity `max_per_day` override | ❌ Missing | Uses formula, ignores activity field |
| **Gap:** `min_gap_periods` enforcement | ❌ Missing | Field exists, never checked |
| **Gap:** `set_time_limit` bug | 🐛 Bug | Multiplies seconds by 60 |
| **Gap:** `violatesNoConsecutiveRule` bug | 🐛 Bug | Blocks all multi-period activities |
| **Gap:** Async generation via queue | ❌ Missing | `GenerateTimetableJob` does not exist |
| **Gap:** Generation progress tracking | ❌ Missing | No real-time progress for user |
| **Gap:** Multi-attempt generation | ❌ Missing | Single attempt only, no retry with different strategies |

### Phase 6: Post-Generation Analytics — ❌ 10% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Reports view | ✅ Done | `timetableReports()` method + 7 report partials |
| Teacher workload display | ✅ Done | In `timetableMaster()` — counts optimal/high/overloaded |
| **Gap:** AnalyticsService | ❌ Missing | No service file exists |
| **Gap:** AnalyticsController | ❌ Missing | No controller exists |
| **Gap:** Teacher workload computation to DB | ❌ Missing | `tt_teacher_workloads` table exists in schema but never populated |
| **Gap:** Room utilization computation | ❌ Missing | `tt_room_utilizations` table exists but never populated |
| **Gap:** Constraint violation analysis | ❌ Missing | No post-generation constraint evaluation |
| **Gap:** Daily snapshots | ❌ Missing | `tt_analytics_daily_snapshots` never used |
| **Gap:** CSV export | ❌ Missing | No export functionality |
| **Gap:** Analytics dashboard with auto-compute | ❌ Missing | No analytics-specific dashboard |

### Phase 7: Publish, Standard Views & Manual Refinement — ❌ 5% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| Saved timetable preview | ✅ Done | `preview(Timetable $timetable)` method loads from DB |
| Timetable list view | ✅ Done | In `timetableGeneration()` |
| **Gap:** StandardTimetableController | ❌ Missing | No class/teacher/room standard views |
| **Gap:** Class-wise timetable view | ❌ Missing | "Show me Class 5A's timetable" |
| **Gap:** Teacher-wise timetable view | ❌ Missing | "Show me Teacher X's weekly schedule" |
| **Gap:** Room-wise timetable view | ❌ Missing | "Show me Lab-1's usage" |
| **Gap:** Publish workflow | ❌ Missing | Status change from GENERATED → PUBLISHED |
| **Gap:** RefinementController | ❌ Missing | No manual swap/move |
| **Gap:** RefinementService | ❌ Missing | No cell swap, lock/unlock, rollback |
| **Gap:** Cell swap impact analysis | ❌ Missing | No conflict preview before swap |
| **Gap:** Change log tracking | ❌ Missing | No audit trail for manual changes |

### Phase 8: Substitution Management — ❌ 0% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| **Gap:** SubstitutionController | ❌ Missing | Not created |
| **Gap:** SubstitutionService | ❌ Missing | Not created |
| **Gap:** Teacher absence recording | ❌ Missing | |
| **Gap:** Substitute recommendation engine | ❌ Missing | |
| **Gap:** Pattern learning (`tt_substitution_patterns`) | ❌ Missing | Table in schema, no code |
| **Gap:** Substitution history | ❌ Missing | |
| **Gap:** Substitution dashboard | ❌ Missing | |

### Cross-Cutting: API & Integration — ❌ 0% COMPLETE

| Feature | Status | Notes |
|---------|--------|-------|
| **Gap:** TimetableApiController | ❌ Missing | No REST API |
| **Gap:** API routes in `api.php` | ❌ Missing | No API route definitions |
| **Gap:** Sanctum authentication for API | ❌ Missing | |
| **Gap:** JSON response format standardization | ❌ Missing | |

---

## 4. BROKEN / DEAD CODE INVENTORY

### 4A. Files to Delete

| File | Reason |
|------|--------|
| `Controllers/SmartTimetableController_29_01_before_store.php` | Backup file, no longer needed |
| `Services/EXTRA_delete_10_02/` (14 files) | Archived constraint implementations, superseded by Generic/DB constraints |
| `Services/Generator/ImprovedTimetableGenerator.php` | Only referenced in debug methods |
| `views/class-group-requirement copy/` (5 files) | Duplicate directory with trailing " copy" |

### 4B. Dead Code in SmartTimetableController

| Method | Lines | Reason |
|--------|-------|--------|
| `debugPlacementIssue()` | 961-1063 | Debug method, references ImprovedTimetableGenerator |
| `debugPeriods()` | 1065-1087 | Debug method |
| `diagnoseLunchProblem()` | 1089-1253 | Debug method |
| `seederTest()` | 2988-2991 | Empty method |
| `saveGeneratedTimetable()` | 2828-2905 | Legacy save, dangerous (deletes all timetables for session) |
| `createConstraintManager()` | 245-294 | All constraints commented out, superseded by DB service |
| `createConstraintManagerFromDatabase()` | 299-322 | Superseded by DatabaseConstraintService |
| `resolveConstraintClass()` | 327-339 | Part of dead constraint mapping |

**Total dead code: ~550+ lines**

### 4C. Broken Routes (Route Exists, Method Missing)

| Route | Expected Controller Method | Status |
|-------|---------------------------|--------|
| `smart-timetable-management.generate-for-class-section` | `SmartTimetableController@generateForClassSection` | ❌ Method only exists in backup file |
| `class-group-requirements/generate-all` | `ActivityController@generateAllActivities` | ⚠️ Needs verification |
| `class-group-requirements/generation-progress` | `ActivityController@getBatchGenerationProgress` | ⚠️ Needs verification |

---

## 5. CRITICAL BUGS SUMMARY

| ID | Bug | Severity | Location | Fix Effort |
|----|-----|----------|----------|------------|
| B1 | `set_time_limit` multiplied by 60 — PHP can run 2 hours | CRITICAL | Controller:2591 | 1 min |
| B2 | `saveGeneratedTimetable()` deletes ALL timetables for academic session | CRITICAL | Controller:2843 | 5 min (disable/remove) |
| B3 | `violatesNoConsecutiveRule` blocks ALL multi-period activities (labs, hobbies) | HIGH | FETSolver:636-639 | 15 min |
| B4 | Session stores full Eloquent models (10-50MB serialized) | HIGH | Controller:2731 | 30 min |
| B5 | ConstraintManager cache not cleared during backtracking | MEDIUM | ConstraintManager:56-60 | 5 min |
| B6 | Forced placements tracked per originalActivityId, not instanceId (last wins) | LOW | FETSolver:1349 | 5 min |

---

## 6. STEP-BY-STEP COMPLETION PLAN

### STEP 1: Bug Fixes & Code Cleanup (Priority: IMMEDIATE)
**Estimated effort: 1 day**
**Dependencies: None**

Tasks:
1. **Fix B1** — `set_time_limit` bug (Controller:2591). Change `$validated['max_generation_time'] * 60` to `$maxTimeSeconds`.
2. **Fix B2** — Remove or comment out `saveGeneratedTimetable()` method. Verify no route points to it.
3. **Fix B3** — Rewrite `violatesNoConsecutiveRule()` for multi-period activities. A single multi-period block is NOT a consecutive violation; only two separate instances adjacent to each other should be flagged.
4. **Delete backup file** — `SmartTimetableController_29_01_before_store.php`
5. **Delete archived services** — `Services/EXTRA_delete_10_02/` directory
6. **Delete duplicate views** — `views/class-group-requirement copy/`
7. **Remove dead methods** — Move debug methods (`debugPlacementIssue`, `debugPeriods`, `diagnoseLunchProblem`, `seederTest`) and dead constraint methods (`createConstraintManager`, `createConstraintManagerFromDatabase`, `resolveConstraintClass`) from SmartTimetableController. Either move debug methods to a separate DebugController or delete entirely. (~550 lines removed)
8. **Fix broken route** — Either implement `generateForClassSection()` in SmartTimetableController or remove the route.

### STEP 2: Activity-Level Constraint Integration (Priority: HIGH)
**Estimated effort: 2 days**
**Dependencies: Step 1 (B3 fix)**
**Detailed plan:** See `2026Mar10_ActivityConstraints_Integration_Plan.md`

Tasks:
1. **Per-activity `allow_consecutive` override** — In `isBasicSlotAvailable()`, check `activity->allow_consecutive` before applying global consecutive rule.
2. **Per-activity `max_per_day` override** — In `violatesDailyActivityPlacementCap()`, use `activity->max_per_day` when set.
3. **Add `violatesMinGapRule()`** — New method in FETSolver for `min_gap_periods` enforcement.
4. **Add `scoreSlotForActivity()`** — New method scoring slots based on `preferred_periods_json`, `avoid_periods_json`, `preferred_time_slots_json`, `avoid_time_slots_json`, `spread_evenly`.
5. **Integrate scoring into `getPossibleSlots()`** — Sort slots by score before placement.
6. **Auto-populate activity constraint fields during generation** — When `ActivityController::generateActivities()` runs, compute `difficulty_score_calculated`, `constraint_count` from the activity's constraints and teacher data.

### STEP 3: Generation Performance & Reliability (Priority: HIGH)
**Estimated effort: 2 days**
**Dependencies: Step 1**

Tasks:
1. **Session storage optimization** — Convert Eloquent collections to plain arrays before storing in session. Only store IDs and essential scalar fields. Reload from DB on save.
2. **Batch insert in `storeTimetable()`** — Replace triple-nested loop of individual `TimetableCell::create()` with bulk `insert()`. Same for teacher pivot rows.
3. **Filter activities by academic_term_id** — `loadActivitiesForActiveClassSections()` should filter by the validated `academic_term_id`, not load all active activities.
4. **Add eager loading to `loadClassSections()`** — Add `->with(['class', 'section'])`.
5. **Defer view-only queries** — Move `academicSessions`, `timetableTypes`, `periodSets` loading to after solver returns.
6. **Gate verbose logging** — Add a config flag to control debug-level logging in FETSolver.
7. **Fix ConstraintManager cache** — Clear evaluation cache on each backtrack step.

### STEP 4: Room Allocation (Priority: MEDIUM-HIGH)
**Estimated effort: 3 days**
**Dependencies: Step 2**
**Detailed plan:** See `2026Mar10_ActivityConstraints_Integration_Plan.md` Section 6

Tasks:
1. **Create `RoomAllocationPass` service** — Post-generation room assignment based on activity room constraints (hard: `required_room_id` / `required_room_type_id`; soft: `preferred_room_type_id` / `preferred_room_ids`).
2. **Integrate into `generateWithFET()`** — Run after `solver->solve()`, before session storage.
3. **Update `storeTimetable()`** — Persist `room_id` from allocated entries.
4. **Add room conflict detection** — Flag when two activities need the same room at the same time.
5. **Display room assignments in preview** — Update preview partial to show room name per cell.

### STEP 5: Post-Generation Analytics (Priority: MEDIUM)
**Estimated effort: 4 days**
**Dependencies: Step 3**

Tasks:
1. **Create `AnalyticsService`** — Methods: `computeTeacherWorkload()`, `computeRoomUtilization()`, `computeConstraintViolations()`, `takeDailySnapshot()`, `getClassReport()`, `getTeacherReport()`, `getRoomReport()`.
2. **Create `AnalyticsController`** — Dashboard view, teacher workload view, room utilization view, violation view, CSV exports.
3. **Create analytics views** — Dashboard, teacher-workload, room-utilization, violations, reports (class/teacher/room) with shared `_grid` partial.
4. **Add analytics routes** — Prefix `smart-timetable/analytics/{timetable}`.
5. **Populate `tt_teacher_workloads`** — Calculate and store after generation.
6. **Populate `tt_room_utilizations`** — Calculate and store after generation.
7. **Wire reports tab** — Connect existing report partials to actual data from AnalyticsService.

### STEP 6: Standard Views & Publish (Priority: MEDIUM)
**Estimated effort: 3 days**
**Dependencies: Step 5**

Tasks:
1. **Create `StandardTimetableController`** — Methods: `hub()`, `classView()`, `teacherView()`, `roomView()`.
2. **Create standard views** — Class timetable (days × periods grid), Teacher weekly schedule, Room usage calendar.
3. **Implement publish workflow** — Status transition GENERATED → PUBLISHED with validation. PUBLISHED timetables are read-only.
4. **Add standard view routes** — `smart-timetable/standard/{timetable}/class/{id}`, etc.
5. **Reuse `_grid` partial from analytics** for consistent display.

### STEP 7: Manual Refinement (Priority: MEDIUM)
**Estimated effort: 4 days**
**Dependencies: Step 6**

Tasks:
1. **Create `RefinementService`** — Methods: `lockCell()`, `unlockCell()`, `analyseSwapImpact()`, `swapCells()`, `moveCell()`, `batchSwap()`, `rollbackBatch()`, `getChangeLogs()`, `revalidate()`.
2. **Create `RefinementController`** — Endpoints for swap, move, lock, unlock, impact analysis, change log.
3. **Create refinement views** — Grid with swap interaction (click source → click target → impact modal → confirm), change log table, conflict resolution view.
4. **Add refinement routes** — Prefix `smart-timetable/refinement/{timetable}`.
5. **Add change log tracking** — Record every manual change with before/after state, user, timestamp.

### STEP 8: Substitution Management (Priority: LOW-MEDIUM)
**Estimated effort: 5 days**
**Dependencies: Step 7**

Tasks:
1. **Create `SubstitutionService`** — Methods: `recordAbsence()`, `generateRecommendations()`, `scoreCandidate()`, `assignSubstitute()`, `completeSubstitution()`, `getHistory()`.
2. **Create `SubstitutionController`** — Dashboard, record absence form, recommendation display, assignment, history.
3. **Create substitution views** — Dashboard (today's absences), absence form, substitute recommendation list (scored), history/audit.
4. **Add substitution routes** — Prefix `smart-timetable/substitution/{timetable}`.
5. **Implement scoring** — Subject match (40pts), pattern confidence (25pts), day availability (20pts), workload balance (15pts).
6. **Implement pattern learning** — Update `tt_substitution_patterns` with running averages on completion.

### STEP 9: API Layer (Priority: LOW)
**Estimated effort: 3 days**
**Dependencies: Step 6**

Tasks:
1. **Create `TimetableApiController`** — REST endpoints: GET timetable, GET class schedule, GET teacher schedule, GET room schedule, POST trigger generation, GET generation status.
2. **Add API routes** — In `routes/api.php`, prefix `/api/v1/timetable`, auth via Sanctum.
3. **Standardize response format** — `{ success: true, data: {...} }` or `{ success: false, message: "..." }`.
4. **Create Form Request classes** — `CellSwapRequest`, `RecordAbsenceRequest`, `AssignSubstituteRequest`.

### STEP 10: Async Generation & Testing (Priority: LOW)
**Estimated effort: 4 days**
**Dependencies: Step 3**

Tasks:
1. **Create `GenerateTimetableJob`** — Queue job wrapping `FETSolver->solve()`. Tracks progress in `tt_generation_runs`.
2. **Add generation status polling** — Frontend polls `/generation-status/{run}` every 3s.
3. **Create status view** — Shows progress bar, current phase, estimated time.
4. **Write Feature tests** — ConstraintManager tests, FETSolver placement tests (Pest syntax).
5. **Write Unit tests** — Slot, TimetableSolution, scoring functions.

---

## 7. DEPENDENCY MAP

```
STEP 1: Bug Fixes & Cleanup
   │
   ├── STEP 2: Activity Constraints ──→ STEP 4: Room Allocation
   │                                          │
   ├── STEP 3: Performance ──────────→ STEP 5: Analytics ──→ STEP 6: Standard Views
   │                   │                                           │
   │                   └──→ STEP 10: Async & Tests                 │
   │                                                               │
   │                                                    STEP 7: Refinement
   │                                                               │
   │                                                    STEP 8: Substitution
   │
   └── STEP 9: API (can start after Step 6)
```

### Estimated Total Effort

| Step | Name | Effort |
|------|------|--------|
| 1 | Bug Fixes & Cleanup | 1 day |
| 2 | Activity Constraints | 2 days |
| 3 | Performance & Reliability | 2 days |
| 4 | Room Allocation | 3 days |
| 5 | Analytics | 4 days |
| 6 | Standard Views & Publish | 3 days |
| 7 | Manual Refinement | 4 days |
| 8 | Substitution | 5 days |
| 9 | API Layer | 3 days |
| 10 | Async & Testing | 4 days |
| **Total** | | **~31 working days** |

### Recommended Priority Order for Development

**Sprint 1 (Week 1):** Steps 1 + 2 + 3 — Fix bugs, integrate activity constraints, optimize performance
**Sprint 2 (Week 2):** Step 4 + Step 5 — Room allocation + analytics
**Sprint 3 (Week 3):** Step 6 + Step 7 — Standard views + manual refinement
**Sprint 4 (Week 4):** Step 8 + Step 9 — Substitution + API
**Sprint 5 (Week 5):** Step 10 — Async generation + testing + polish

---

## APPENDIX: Overall Completion Percentage

| Phase | Weight | Completion | Weighted |
|-------|--------|------------|----------|
| Phase 0: Master Setup | 10% | 95% | 9.5% |
| Phase 1: Requirements | 8% | 90% | 7.2% |
| Phase 2: Teacher Availability | 8% | 85% | 6.8% |
| Phase 3: Activity Creation | 10% | 80% | 8.0% |
| Phase 4: Validation | 5% | 70% | 3.5% |
| Phase 5: Generation | 25% | 75% | 18.75% |
| Phase 6: Analytics | 10% | 10% | 1.0% |
| Phase 7: Publish & Refine | 12% | 5% | 0.6% |
| Phase 8: Substitution | 7% | 0% | 0.0% |
| Cross-cutting: API | 5% | 0% | 0.0% |
| **TOTAL** | **100%** | — | **~55%** |

**The SmartTimetable module is approximately 55% complete.** The core generation engine works (Phase 5) and master setup/data entry is nearly done (Phases 0-3). The major gaps are in post-generation features: analytics, standard views, manual refinement, substitution, and API — which together represent ~45% of the total module scope.
