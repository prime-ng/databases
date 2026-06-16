# SmartTimetable Module — Updated Gap Analysis

**Date:** 2026-03-14
**Audited by:** Claude Code (Opus 4.6, deep audit)
**Branch:** Tarun_SmartTimetable
**Previous analysis:** 2026-03-10 (`2026Mar10_GapAnalysis_and_CompletionPlan.md`)
**Code location:** `/Users/bkwork/Herd/prime_ai_tarun/Modules/SmartTimetable/`

---

## Module Stats (Audited)

| Metric | Mar-10 | Mar-14 | Change |
|--------|--------|--------|--------|
| Controllers | 27 | 28 (+1 ParallelGroupController) | +1 |
| Models | 84 | 86 (+ParallelGroup, ParallelGroupActivity) | +2 |
| Services | 35* | 22 (actual .php files) | corrected |
| Views | ~200 | 237 | +37 |
| Seeders | 12 | 13 (+ConstraintTypeSeeder updated) | +1 |
| Test files | 0 | 3 (9 tests, 23 assertions) | +3 |
| Routes (tenant.php) | ~75 | 80+ | +5 |
| Form Requests | 10 | 12 | +2 |

---

## Overall Completion: ~60% (was ~55% on Mar-10)

| Phase | Mar-10 | Mar-14 | Notes |
|-------|--------|--------|-------|
| 0 — Master Setup | 95% | 95% | No change |
| 1 — Requirement Consolidation | 90% | 90% | No change |
| 2 — Teacher Availability | 85% | 85% | No change |
| 3 — Activity Creation | 80% | 80% | No change |
| 4 — Validation | 70% | 70% | No change |
| 5 — Generation | 75% | 85% | Parallel periods solver done, soft constraints wired |
| 6 — Analytics | 10% | 15% | Post-gen parallel violation check added |
| 7 — Publish & Refinement | 5% | 5% | No change |
| 8 — Substitution | 0% | 0% | Not started |
| API/Async | 0% | 0% | Not started |
| **Security & Code Quality** | n/a | **30%** | New category: 17/28 controllers have zero auth |

---

## What Changed Since Mar-10

### Completed (Steps 4-9 of Parallel Periods)

| Item | Status | Details |
|------|--------|---------|
| GAP-2: Parallel Period Scheduling | **DONE** | Schema, models, UI, solver (anchor/sibling backtrack + rescue pass), constraint engine, pre/post-gen validation, 9 unit tests |
| `TimetableSolution::isPlaced()` method | **DONE** | Added for backtrack guard |
| `TimetableSolution::remove()` bug | **FIXED** | Key mismatch — used `$activity->id` instead of `instance_id ?? id` |
| `ParallelPeriodConstraint.php` | **DONE** | New hard constraint, registered in ConstraintFactory |
| `ConstraintTypeSeeder` — PARALLEL_PERIODS | **DONE** | New constraint type entry |
| `evaluateSoftConstraints()` wired into FETSolver | **DONE** | D18: 0.5x weight multiplier in `scoreSlotForActivity()` |
| Pre-gen validation in SmartTimetableController | **DONE** | Anchor count, duration, teacher conflict checks |
| Post-gen verification in SmartTimetableController | **DONE** | Parallel violation detection + session key |
| Unit tests: `TimetableSolutionIsPlacedTest.php` | **DONE** | 4 tests |
| Unit tests: `ParallelGroupBacktrackTest.php` | **DONE** | 5 tests |

### Still Pending from Mar-10 Analysis

| Item | Priority | Effort | Status |
|------|----------|--------|--------|
| BUG-B1: `set_time_limit` x 60 | CRITICAL | 1 min | PENDING |
| BUG-B2: `saveGeneratedTimetable()` deletes all timetables | CRITICAL | 5 min | PENDING |
| BUG-B3: `violatesNoConsecutiveRule()` blocks multi-period activities | HIGH | 15 min | PENDING |
| BUG-B4: Session stores 10-50MB Eloquent models | HIGH | 30 min | PENDING |
| GAP-1: Activity-level constraints ignored by FETSolver | HIGH | 2.25 hrs | PENDING (7 sub-tasks) |
| GAP-3: Room allocation (room_id always NULL) | HIGH | 3 days | PENDING |
| GAP-4: Post-generation analytics | MEDIUM | 5 days | PENDING |
| GAP-5: Manual refinement/swaps | MEDIUM | 4 days | PENDING |
| GAP-6: Substitution management | MEDIUM | 5 days | PENDING |
| GAP-8: Concurrent generation protection | MEDIUM | 1 day | PENDING |
| GAP-9: Constraint PHP classes (12/38 done) | LOW | 5 days | PENDING |
| GAP-10: Dead code cleanup | LOW | 2 hrs | PENDING |

---

## NEW Issues Found (Mar-14 Deep Audit)

### CRITICAL — Runtime Crashes

| ID | Issue | File | Impact |
|----|-------|------|--------|
| BUG-NEW-01 | `Shift` model doesn't exist — TimetableTypeController crashes | `TimetableTypeController.php:11,29,181` | Fatal: create/edit pages throw class-not-found |
| BUG-NEW-02 | `Period` model doesn't exist — PeriodController crashes | `PeriodController.php` | Fatal: entire controller non-functional, views missing |
| BUG-NEW-03 | `FETConstraintBridge` references 2 non-existent classes | `FETConstraintBridge.php` | Fatal if instantiated; currently dead code |
| BUG-NEW-04 | Duplicate route registrations (`period`, `school-timing-profile`) | `tenant.php:1846,1864` | Silent route conflicts |
| BUG-NEW-05 | `SchoolShiftController::edit()` references non-existent view `School.edit` | `SchoolShiftController.php:66` | Fatal ViewNotFound |
| BUG-NEW-06 | `TimetableController` entirely stub (store/update/destroy empty) | `TimetableController.php` | Silent null responses |

### CRITICAL — Security

| ID | Issue | File | Impact |
|----|-------|------|--------|
| SEC-009 (expanded) | **17 of 28 controllers have ZERO authorization** | Multiple | Any authenticated user can perform any action |
| SEC-NEW-01 | Unprotected `truncate()` on 3 tables with `FK_CHECKS=0` | `ActivityController:73`, `TeacherAvailabilityController:74`, `RequirementConsolidationController:848` | Any user can wipe all activities/availability/requirements |
| SEC-NEW-02 | Debug `test-seeder` route exposed in production | `tenant.php:1767` | Dead endpoint accessible without auth |
| SEC-NEW-03 | Missing `EnsureTenantHasModule` middleware | `tenant.php:1766` | Tenants without module can access all ST routes |
| SEC-NEW-04 | `SmartTimetablePolicy` is empty and unregistered | `SmartTimetablePolicy.php` | No policy enforcement possible |

### HIGH — Performance

| ID | Issue | File | Impact |
|----|-------|------|--------|
| PERF-NEW-01 | `SmartTimetableController::index()` fires 12+ unbounded `::all()` queries | `SmartTimetableController.php:93-100` | Slow page loads, memory pressure |
| PERF-NEW-02 | `TeacherAvailabilityController::generateTeacherAvailability()` — `updateOrCreate` in 2 nested loops | `TeacherAvailabilityController.php:101-261` | 500+ individual queries for 50 subjects x 5 teachers |
| PERF-NEW-03 | `ActivityController` — `updateOrCreate` in loops at 6 separate call sites | `ActivityController.php:225,464,548,746,831,1117` | Hundreds of individual queries per generation |

### HIGH — Code Quality

| ID | Issue | File | Impact |
|----|-------|------|--------|
| QUAL-NEW-01 | SmartTimetableController is 3,160 lines — god controller | `SmartTimetableController.php` | Unmaintainable, untestable |
| QUAL-NEW-02 | 16 controllers use inline validation instead of FormRequests | Multiple | Inconsistent validation pattern |
| QUAL-NEW-03 | `$request->all()` logged to app log (2 controllers) | `ClassSubjectSubgroupController:203`, `SmartTimetableController:2998` | Sensitive data in logs |
| QUAL-NEW-05 | Backup controller committed to codebase | `SmartTimetableController_29_01_before_store.php` | Namespace pollution |
| QUAL-NEW-06 | Leftover `class-group-requirement copy` views directory | `resources/views/` | Dead code |

### MEDIUM — Models & Services

| ID | Issue | File | Impact |
|----|-------|------|--------|
| MODEL-NEW-01 | 40 models lack `SoftDeletes` trait | Multiple | Violates project rules; no recovery from deletes |
| MODEL-NEW-02 | `AcademicTerm` uses `sch_` prefix (SchoolSetup table) | `AcademicTerm.php` | Cross-module ownership conflict (ARCH-003) |
| SVC-NEW-01 | `FETConstraintBridge::canPlaceActivity()` always returns empty | `FETConstraintBridge.php:29-34` | DB constraints never reach solver |
| SEED-NEW-01 | `DaySeeder` and `PeriodSeeder` are placeholders | `SmartTimetableDatabaseSeeder.php` | Blocks automated tenant provisioning |

### LOW — Cleanup

| ID | Issue | File | Impact |
|----|-------|------|--------|
| ROUTE-LOW-01 | Module `web.php` routes lack tenancy middleware | `routes/web.php` | Redundant with tenant.php |
| VIEW-LOW-01 | 5 generate-timetable partial variant directories | `resources/views/partials/` | Dead code from iterations |
| VIEW-LOW-02 | `slot-requirement/show` view missing | `SlotRequirementController.php:116` | Minor — show page broken |

---

## Controller Authorization Audit (28 controllers)

### Have Gate::authorize() (11 controllers)

| Controller | Auth Pattern |
|-----------|-------------|
| TtConfigController | `Gate::authorize()` on all methods |
| TtGenerationStrategyController | `Gate::authorize()` on all methods |
| TimingProfileController | `Gate::authorize()` on all methods |
| AcademicTermController | `Gate::authorize()` on all methods |
| SchoolDayController | `Gate::authorize()` on all methods |
| DayTypeController | `Gate::authorize()` on all methods |
| PeriodTypeController | `Gate::authorize()` on all methods |
| PeriodSetController | `Gate::authorize()` on all methods |
| SchoolShiftController | `Gate::authorize()` on all methods |
| SchoolTimingProfileController | `Gate::authorize()` on all methods |
| ConstraintController | Uses FormRequests (no Gate, but validated) |

### Have FormRequests but NO Gate (2 controllers)

| Controller | FormRequests Used |
|-----------|------------------|
| ParallelGroupController | Store/Update/AddActivities requests |
| ConstraintTypeController | StoreConstraintTypeRequest |

### ZERO Auth + ZERO FormRequests (15 controllers)

| Controller | Risk Level | Notes |
|-----------|-----------|-------|
| **SmartTimetableController** | CRITICAL | 3,160 lines, generate/store/preview fully exposed |
| **ActivityController** | CRITICAL | `truncate()` with FK_CHECKS=0 fully exposed |
| **TeacherAvailabilityController** | CRITICAL | `truncate()` fully exposed |
| **RequirementConsolidationController** | CRITICAL | `truncate()` fully exposed |
| ClassSubjectSubgroupController | HIGH | CRUD exposed |
| PeriodSetPeriodController | MEDIUM | CRUD exposed |
| RoomUnavailableController | MEDIUM | CRUD exposed |
| SlotRequirementController | MEDIUM | CRUD exposed |
| TeacherAssignmentRoleController | MEDIUM | CRUD exposed |
| TeacherUnavailableController | MEDIUM | CRUD exposed |
| TimetableController | LOW | All stubs (empty methods) |
| TimetableTypeController | LOW | Crashes (missing Shift model) |
| PeriodController | LOW | Crashes (missing Period model) |
| WorkingDayController | LOW | store/update stubs |
| ConstraintController | LOW | Has FormRequests |

---

## Consolidated Gap Summary

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| Bugs (runtime crashes) | 6 | 0 | 0 | 0 | 6 |
| Security | 5 | 0 | 1 | 0 | 6 |
| Performance | 0 | 3 | 0 | 0 | 3 |
| Missing Features | 0 | 3 | 4 | 1 | 8 |
| Code Quality | 0 | 6 | 3 | 3 | 12 |
| **Total** | **11** | **12** | **8** | **4** | **35** |

---

## Constraint System Gap — 155+ Rule Inventory

> **Source:** `2026Mar10_ConstraintArchitecture_Analysis.md` + `2026Mar10_ConstraintList_and_Categories.md`
> These two files define 155+ constraint rules across 8 categories (A-H).
> The constraint system architecture is sound (10 models, lifecycle, plug-and-play design),
> but only ~30 of 155+ rules are actually enforced during generation.

### Category-by-Category Implementation Status

| Cat | Name | Total Rules | Implemented | Gap | Effort to Close |
|-----|------|-------------|-------------|-----|-----------------|
| **A** | Engine Hard Rules | 5 | 5 ✅ | 0 | — |
| **B1** | Teacher (per-teacher) | 22 | ~7 partial | **15 rules** | 5 days |
| **B2** | Teacher (global/all) | 20 | 0 | **20 rules** | 2 days (reuse B1 classes) |
| **C1** | Class (per-class) | 18 | ~5 partial | **13 rules** | 4 days |
| **C2** | Class (global/all) | 15 | 0 | **15 rules** | 1 day (reuse C1 classes) |
| **D** | Activity-Level | 22 fields exist | 7 scored by solver | **15 fields ignored** | 2 days |
| **E1** | Room Availability | 6 | 3 (basic alloc) | **3 rules** | 1 day |
| **E2** | Teacher Room Prefs | 10 | 0 | **10 rules** | 3 days |
| **E3** | Student Room Prefs | 10 | 0 | **10 rules** | 2 days (mirror E2) |
| **E4** | Subject Room Prefs | 6 | 0 (partially via D17-D20) | **6 rules** | 1 day |
| **F** | DB-Configurable | 25 seeded, 12 PHP classes | 12 PHP classes | **13 types without PHP class** | 3 days |
| **G** | Global Policy | 9 | ~4 via settings | **5 rules** | 2 days |
| **H** | Inter-Activity | 22 | 1 (H8 Parallel Periods ✅) | **21 rules** | 8 days |
| | **TOTAL** | **~155** | **~30** | **~125 rules** | **~34 days** |

### Category B — Teacher Constraints: Detailed Gap

**Implemented (B1.1–B1.7):** Unavailable times, max/min daily periods, max weekly, min/max days, max consecutive

**NOT implemented (B1.8–B1.22):**

| # | Constraint | Complexity | Notes |
|---|-----------|-----------|-------|
| B1.8 | No two consecutive working days | LOW | Boolean check |
| B1.9 | Max gaps per day | LOW | Count free periods between first/last |
| B1.10 | Max gaps per week | LOW | Sum of daily gaps |
| B1.11 | Max single gaps in selected slots | MED | Time-range filtering needed |
| B1.12 | Max span per day | LOW | Last - first period |
| B1.13 | Mutually exclusive time slots | MED | Pair-based constraint |
| B1.14 | Max hours in hourly interval | MED | Window-based counting |
| B1.15 | Max consecutive with study format | MED | Study format awareness needed |
| B1.16 | Min/max daily with study format | MED | Study format filtering |
| B1.17 | Max study formats per day | MED | Set counting |
| B1.18 | Min gap between study format pair | HIGH | Ordered pair + gap tracking |
| B1.19 | Max days in hourly interval | MED | Cross-day interval tracking |
| B1.20 | Min resting hours | HIGH | Cross-day period calculation |
| B1.21 | Preferred free day | LOW | Soft scoring |
| B1.22 | Free period in each half | MED | Half-day split logic |

### Category C — Class/Student Constraints: Detailed Gap

**NOT implemented (C1.6–C1.18):**

| # | Constraint | School Requirement | Complexity |
|---|-----------|-------------------|-----------|
| C1.6 | Max gaps per week | General | LOW |
| C1.7 | Max hours continuously | General | LOW |
| C1.8 | Max span per day | General | LOW |
| C1.9 | Min hours daily | General | LOW |
| C1.10 | Max hours with study format | General | MED |
| C1.11 | Min hours with study format | General | MED |
| C1.12 | Max consecutive with study format | General | MED |
| C1.13 | Min gap between study format pair | General | HIGH |
| C1.14 | Max days in hourly interval | General | MED |
| C1.15 | Min resting hours | General | HIGH |
| C1.16 | Max minor subjects per day | **School #6** | MED |
| C1.17 | Major subjects must fall every day | **School #4** | MED |
| C1.18 | Class teacher first period | **School #2** | LOW |

### Category E — Room & Space Constraints: Detailed Gap

**26 unimplemented rules across 3 sub-categories:**
- **E2 (Teacher Room):** Home room, max room/building changes per day/week/interval, min gaps between changes — 10 rules
- **E3 (Student Room):** Mirror of E2 for student-sets — 10 rules
- **E4 (Subject Room):** Subject/StudyFormat preferred room/room-set — 6 rules (partially handled by Activity D17-D20 fields)

### Category H — Inter-Activity Constraints: Detailed Gap

**21 unimplemented rules — these require solver-level changes (like parallel periods H8 required):**

| # | Constraint | Hard/Soft | Solver Change Needed | School Req |
|---|-----------|-----------|---------------------|-----------|
| H1 | Same starting time | HARD/SOFT | Activity group sync (like H8 but simpler) | — |
| H2 | Same day | HARD/SOFT | Day matching in backtrack | — |
| H3 | Same hour | HARD/SOFT | Period matching in backtrack | — |
| H4 | Not overlapping | HARD | Overlap check | — |
| H5 | Consecutive (ordered) | HARD/SOFT | Adjacent slot enforcement | — |
| H6 | Ordered if same day | HARD/SOFT | Sequence enforcement | — |
| H7 | Grouped (2-3 activities block) | HARD | Block placement | — |
| H9 | Min days between | SOFT | Calendar gap check | — |
| H10 | Max days between | SOFT | Calendar gap check | — |
| H11 | End students day | SOFT | Last-period enforcement | — |
| H12-H15 | Occupy min/max slots from selection | SOFT | Slot-set counting | — |
| H16 | Min gaps between activity set | SOFT | Gap enforcement | — |
| H17 | Same room if consecutive | SOFT | Room consistency | — |
| H18 | Max different rooms for set | SOFT | Room counting | — |
| H19 | Non-concurrent minor subjects | SOFT | Day exclusion | **School #6** |
| H20 | Activity fixed to specific day | HARD/SOFT | Day pinning | **School #14** |
| H21 | Activity excluded from specific day | HARD/SOFT | Day exclusion | **School #14** |
| H22 | Activity fixed to period range | HARD/SOFT | Period range enforcement | **School #1** |

### Constraint Architecture Gaps

**3 proposed architectural components NOT yet implemented:**

| Component | Purpose | Status | Source |
|-----------|---------|--------|--------|
| `ConstraintRegistry` | Plugin registration system — replaces hardcoded `CONSTRAINT_CLASS_MAP` | NOT BUILT | ConstraintArchitecture_Analysis §3.2 |
| `ConstraintEvaluator` | Separated evaluation logic with caching — decouples from ConstraintManager | NOT BUILT | ConstraintArchitecture_Analysis §3.3 |
| `ConstraintContext` | Value object for slot+activity context — replaces ad-hoc array building | NOT BUILT | ConstraintArchitecture_Analysis §3.4 |

**Constraint Group evaluation NOT wired:**
- `ConstraintGroup` model supports MUTEX/CONCURRENT/ORDERED/PREFERRED semantics
- `ConstraintGroupMember` bridge table exists
- `ConstraintManager` does NOT evaluate group logic — groups are ignored during generation
- Impact: Cannot express "at most one of these constraints should apply" (MUTEX) or "all must apply together" (CONCURRENT)

### Constraint Class Map — Current vs Required

**Currently registered in `ConstraintFactory::CONSTRAINT_CLASS_MAP` (13 entries including PARALLEL_PERIODS):**

| Code | PHP Class | Type |
|------|-----------|------|
| PARALLEL_PERIODS | ParallelPeriodConstraint | Hard |
| LUNCH_BREAK | LunchBreakConstraint | Hard |
| SHORT_BREAK | ShortBreakConstraint | Hard |
| BREAK_PERIOD | BreakConstraint | Hard |
| TEACHER_CONFLICT | TeacherConflictConstraint | Hard |
| ROOM_AVAILABILITY | RoomAvailabilityConstraint | Hard |
| MAX_DAILY_LOAD | MaximumDailyLoadConstraint | Hard |
| NO_SAME_SUBJECT_SAME_DAY | NoSameSubjectSameDayConstraint | Hard |
| FIXED_PERIOD_HIGH_PRIORITY | FixedPeriodForHighPriorityConstraint | Hard |
| HIGH_PRIORITY_FIXED_PERIOD | HighPriorityFixedPeriodConstraint | Hard |
| DAILY_SPREAD | DailySpreadConstraint | Hard |
| PREFERRED_TIME_OF_DAY | PreferredTimeOfDayConstraint | Soft |
| BALANCED_DAILY_SCHEDULE | BalancedDailyScheduleConstraint | Soft |

**25 seeded ConstraintTypes WITHOUT PHP class (fall through to Generic):**
F1–F7 (teacher), F8–F13 (class), F14–F16 (room), F17–F19 (activity), F20–F25 (global/optimization)

---

## Risk Assessment

**Highest risk to production:**
1. `saveGeneratedTimetable()` can delete ALL timetables (BUG-B2) — data loss
2. Unprotected `truncate()` on 3 core tables (SEC-NEW-01) — data destruction
3. `set_time_limit` x 60 bug (BUG-B1) — 2-hour server hang
4. 17 controllers with zero auth (SEC-009) — any user can generate/delete timetables

**Highest risk to correctness:**
1. 125+ constraint rules not enforced — timetable ignores most school preferences
2. Activity-level constraints ignored (GAP-1) — preferences not respected
3. Room allocation missing (GAP-3) — room_id always NULL
4. `violatesNoConsecutiveRule()` blocks labs (BUG-B3) — multi-period activities forced-placed only
5. Inter-activity constraints (H1-H22 except H8) — activity group relationships not enforced

**Lowest risk (deferred):**
1. Substitution management (GAP-6) — not needed for initial deployment
2. API/Async (GAP-API) — not needed for initial deployment
3. Dead code cleanup (GAP-10) — cosmetic

---

## Appendix: File Inventory

### Controllers (28)
```
AcademicTermController.php           ParallelGroupController.php
ActivityController.php               PeriodController.php
ClassSubjectSubgroupController.php   PeriodSetController.php
ConstraintController.php             PeriodSetPeriodController.php
ConstraintTypeController.php         PeriodTypeController.php
DayTypeController.php                RequirementConsolidationController.php
ParallelGroupController.php          RoomUnavailableController.php
SchoolDayController.php              SchoolShiftController.php
SchoolTimingProfileController.php    SlotRequirementController.php
SmartTimetableController.php         TeacherAssignmentRoleController.php
SmartTimetableController_29_01_*.php TeacherAvailabilityController.php
TeacherUnavailableController.php     TimetableController.php
TimetableTypeController.php          TimingProfileController.php
TtConfigController.php               TtGenerationStrategyController.php
WorkingDayController.php
```

### Services (22)
```
ActivityScoreService.php
Constraints/ConstraintFactory.php
Constraints/ConstraintManager.php
Constraints/Hard/GenericHardConstraint.php
Constraints/Hard/HardConstraint.php
Constraints/Hard/ParallelPeriodConstraint.php
Constraints/Hard/TeacherConflictConstraint.php
Constraints/Soft/GenericSoftConstraint.php
Constraints/Soft/SoftConstraint.php
Constraints/TimetableConstraint.php
DatabaseConstraintService.php
Generator/FETConstraintBridge.php
Generator/FETSolver.php (2,790 lines)
Generator/ImprovedTimetableGenerator.php
RoomAllocationPass.php
RoomAvailabilityService.php
Solver/Slot.php
Solver/SlotEvaluator.php
Solver/SlotGenerator.php
Solver/TimetableSolution.php
Storage/TimetableStorageService.php
SubActivityService.php
```

### Tests (3 files — in tests/Unit/SmartTimetable/)
```
ActivityModelTest.php
ParallelGroupBacktrackTest.php (5 tests)
TimetableSolutionIsPlacedTest.php (4 tests)
```
