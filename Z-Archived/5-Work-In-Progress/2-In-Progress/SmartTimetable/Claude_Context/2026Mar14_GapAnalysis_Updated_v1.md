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

## Risk Assessment

**Highest risk to production:**
1. `saveGeneratedTimetable()` can delete ALL timetables (BUG-B2) — data loss
2. Unprotected `truncate()` on 3 core tables (SEC-NEW-01) — data destruction
3. `set_time_limit` x 60 bug (BUG-B1) — 2-hour server hang
4. 17 controllers with zero auth (SEC-009) — any user can generate/delete timetables

**Highest risk to correctness:**
1. Activity-level constraints ignored (GAP-1) — preferences not respected
2. Room allocation missing (GAP-3) — room_id always NULL
3. `violatesNoConsecutiveRule()` blocks labs (BUG-B3) — multi-period activities forced-placed only

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
