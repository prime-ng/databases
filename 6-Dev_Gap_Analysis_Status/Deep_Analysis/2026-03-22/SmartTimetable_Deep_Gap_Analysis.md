# SmartTimetable Module -- Deep Gap Analysis Report

**Date:** 2026-03-22
**Branch:** Brijesh_SmartTimetable
**Auditor:** Senior Laravel Architect (AI)
**Module Path:** `/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable/`

---

## EXECUTIVE SUMMARY

| Metric | Count |
|---|---|
| DDL Tables (tt_*) | 42 |
| Controllers | 14 (incl. API) |
| Models | 62 |
| Services | 22 (incl. Constraints) |
| FormRequests | 7 |
| Policies | 2 |
| Views (blade) | 50+ |
| Tests | 0 (found in codebase) |
| Routes | ~55 |

### Scorecard

| Category | Score | Grade |
|---|---|---|
| DB Integrity | 70% | C |
| Route Integrity | 65% | D |
| Controller Audit | 40% | F |
| Model Audit | 75% | C |
| Service Audit | 70% | C |
| FormRequest Audit | 30% | F |
| Policy/Auth Audit | 35% | F |
| Security Audit | 45% | F |
| Performance Audit | 50% | D |
| Architecture Audit | 45% | F |
| Test Coverage | 0% | F |
| **Overall** | **~48%** | **F** |

---

## SECTION 1: DATABASE INTEGRITY

### 1.1 DDL Tables Found (42 tables with tt_* prefix)
All 42 tables confirmed in `tenant_db_v2.sql` (lines 2815-4100).

### 1.2 Missing Standard Columns
All DDL tables have `id`, `is_active`, `created_at`, `updated_at`. Most have `deleted_at`. `created_by` is present on major tables (tt_timetable, tt_activity, tt_generation_run).

### 1.3 Issues
- **GAP-DB-001:** Several models reference tables without corresponding DDL entries: `tt_parallel_group_activity` (pivot), `tt_analytics_daily_snapshots`, `tt_substitution_patterns`, `tt_substitution_recommendations`. These may exist as migrations but are not in the canonical DDL.
- **GAP-DB-002:** `tt_timetable_cell_teachers` is referenced via raw `DB::table()` at `SmartTimetableController.php:777,983` instead of through a model, bypassing SoftDeletes and audit.
- **GAP-DB-003:** Models like `ApprovalDecision`, `ApprovalLevel`, `ApprovalNotification`, `ApprovalRequest`, `ApprovalWorkflow`, `BatchOperation`, `BatchOperationItem`, `EscalationLog`, `EscalationRule`, `FeatureImportance`, `MlModel`, `OptimizationIteration`, `OptimizationMove`, `OptimizationRun`, `PredictionLog`, `RevalidationSchedule`, `RevalidationTrigger`, `TrainingData`, `VersionComparison`, `VersionComparisonDetail`, `WhatIfScenario` exist in code but have NO corresponding DDL tables. These are phantom models -- 21 models with no database backing.

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Routes Defined
~55 routes under `smart-timetable.*` prefix in `tenant.php` (lines 1866-1939).

### 2.2 Issues
- **GAP-RT-001:** `EnsureTenantHasModule` middleware is NOT applied to any SmartTimetable route group. The import exists at `tenant.php:7` but is never used for this module. **SECURITY: any tenant can access SmartTimetable routes even without the module license.**
- **GAP-RT-002:** Route `smart-timetable-management.generate-for-class-section` at `tenant.php:1878` calls `SmartTimetableController::generateForClassSection()` which does NOT exist in the controller (3245 lines checked).
- **GAP-RT-003:** The `standard-timetable.*` route group at `tenant.php:2210-2212` is **completely empty** -- no routes registered at all.
- **GAP-RT-004:** Analytics, Refinement, and Substitution routes (lines 1902-1930) lack individual Gate authorization -- they rely on controller-level checks. No `{timetable}` parameter binding in the route prefix (design doc says routes should be `smart-timetable/analytics/{timetable}` but actual routes are just `smart-timetable/analytics/`).
- **GAP-RT-005:** Commented-out controller imports at `tenant.php:29-31,136` reference missing controllers: `ClassGroupRequirementController`, `ClassSubgroupController`, `DayController`.

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 God Controller: SmartTimetableController.php (3,245 lines)
**File:** `/Users/bkwork/Herd/prime_ai/Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`

- **GAP-CTRL-001 (P0):** 3,245-line god controller. Contains generation logic, storage, preview, 10+ menu methods, constraint management, diagnostics. Must be split into at least 5 controllers.
- **GAP-CTRL-002 (P0):** `storeTimetable()` (lines 513-825) uses inline `$request->validate()` instead of a FormRequest. 312 lines of business logic directly in the controller.
- **GAP-CTRL-003 (P0):** `generateWithFET()` method (~900 lines, starting ~line 2400) contains the entire FET generation orchestration with inline validation. No FormRequest.
- **GAP-CTRL-004:** `store()` at line 928 and `update()` at line 956 are **empty stubs** -- the resourceful route methods do nothing.
- **GAP-CTRL-005:** `Faker\Factory` imported at line 8 -- test dependency in production controller.
- **GAP-CTRL-006:** `Hash` facade imported at line 9 -- unused import.
- **GAP-CTRL-007:** `index()` method (lines 109-234) loads 15+ paginated collections in a single method call with no caching. N+1 risk on grouped activities.
- **GAP-CTRL-008:** `timetableOperation()` (lines 1054-1432) is ~378 lines -- another candidate for extraction.
- **GAP-CTRL-009:** `timetableMaster()` (line 1434+) is another massive view method.
- **GAP-CTRL-010:** `createConstraintManager()` (lines 270-319) has ALL constraints **commented out** -- returns an empty ConstraintManager. The constraint engine is effectively disabled.
- **GAP-CTRL-011:** `viewAndRefinement()` (lines 3144-3195) loads ALL timetable cells globally (`TimetableCell::...->get()`) without pagination or timetable filtering -- will OOM on production data.
- **GAP-CTRL-012:** `destroy()` (lines 964-1030) does hard delete on TimetableCell and GenerationRun via raw SQL, violating the soft-delete pattern.

### 3.2 Other Controllers
- **AnalyticsController:** Small, focused. No FormRequests for export.
- **RefinementController:** Uses inline `$request->validate()` (lines 21, 42, 68). No FormRequests.
- **SubstitutionController:** Uses inline `$request->validate()` (lines 34, 76, 106). No FormRequests.
- **ConstraintCategoryController, ConstraintScopeController, ConstraintTypeController:** Use inline validation throughout.
- **TeacherUnavailableController, RoomUnavailableController:** Use inline validation.
- **TtGenerationStrategyController:** Uses inline `$request->validate()` at lines 287, 322.
- **ParallelGroupController:** Uses inline `$request->validate()` at line 316 alongside FormRequests.
- **TimetableApiController:** Uses inline `$request->validate()` at line 99. API controller lacks rate limiting.

---

## SECTION 4: MODEL AUDIT

### 4.1 Issues
- **GAP-MDL-001:** 21 phantom models exist with no DDL tables (listed in GAP-DB-003).
- **GAP-MDL-002:** Most SmartTimetable models are backward-compatibility aliases extending TimetableFoundation models (e.g., `Activity extends \Modules\TimetableFoundation\Models\Activity`). This creates a fragile double-namespace that will cause confusion.
- **GAP-MDL-003:** `PerformanceSnapshot` model in Recommendation has `$fillable = []` -- completely empty, unusable.
- **GAP-MDL-004:** `Timetable` model at `TimetableFoundation/Models/Timetable.php:113` has `generationStrategy()` pointing to `GenerationRun::class` instead of `TtGenerationStrategy::class` -- wrong relationship target.

---

## SECTION 5: SERVICE AUDIT

### 5.1 Services (22 total)
- **Constraint System:** 5 core services + 27 Hard constraints + 41 Soft constraints = 73 constraint files. Well-structured with Strategy pattern.
- **Generator:** FETSolver (main), ImprovedTimetableGenerator, FETConstraintBridge.
- **Post-Generation:** RefinementService, SubstitutionService, ActivityScoreService, DatabaseConstraintService.
- **Solver:** Slot, SlotEvaluator, SlotGenerator, TimetableSolution.
- **Storage:** TimetableStorageService.

### 5.2 Issues
- **GAP-SVC-001:** `FETConstraintBridge` context is reportedly broken per known issues. The bridge between DB constraints and solver constraints is non-functional.
- **GAP-SVC-002:** The `createConstraintManager()` in SmartTimetableController returns an empty manager (all constraints commented out at lines 277-317). The solver runs without ANY constraints.
- **GAP-SVC-003:** `ImprovedTimetableGenerator` exists but is never used -- dead code.
- **GAP-SVC-004:** No service layer for the main controller operations (index data loading, timetable storage, generation orchestration). All business logic is in the 3245-line controller.

---

## SECTION 6: FORMREQUEST AUDIT

### 6.1 FormRequests Found (7)
1. `AddActivitiesToParallelGroupRequest.php`
2. `DayRequest.php`
3. `StoreConstraintRequest.php`
4. `StoreParallelGroupRequest.php`
5. `TimetableGenerationStrategyRequest.php`
6. `UpdateConstraintRequest.php`
7. `UpdateParallelGroupRequest.php`

### 6.2 Missing FormRequests (Critical)
- **GAP-FR-001:** `storeTimetable()` -- inline validation at line 517.
- **GAP-FR-002:** `generateWithFET()` -- inline validation at ~line 2426.
- **GAP-FR-003:** All RefinementController methods (swap, move, toggleLock).
- **GAP-FR-004:** All SubstitutionController methods (reportAbsence, assign, autoAssign).
- **GAP-FR-005:** ConstraintCategoryController store/update.
- **GAP-FR-006:** ConstraintScopeController store/update.
- **GAP-FR-007:** ConstraintTypeController store/update.
- **GAP-FR-008:** TeacherUnavailableController store/update.
- **GAP-FR-009:** RoomUnavailableController store/update.
- **GAP-FR-010:** TimetableApiController cell update.
- **GAP-FR-011:** TtGenerationStrategyController activate/deactivate (lines 287, 322).

**Only 7/18+ controller actions use FormRequests.**

---

## SECTION 7: POLICY/AUTHORIZATION AUDIT

### 7.1 Policies Found (2)
1. `SmartTimetablePolicy.php` -- 7 abilities (viewAny, view, create, update, delete, generate, export).
2. `TimetableGenerationStrategyPolicy.php`

### 7.2 Issues
- **GAP-POL-001 (P0):** Only 2 policies for 14 controllers. Missing policies for: AnalyticsController, RefinementController, SubstitutionController, ConstraintCategoryController, ConstraintScopeController, ConstraintController, ConstraintTypeController, ParallelGroupController, TeacherUnavailableController, RoomUnavailableController, TimetableApiController.
- **GAP-POL-002:** `SmartTimetablePolicy` does not accept a model parameter in methods -- `view(User $user)` should be `view(User $user, Timetable $timetable)` for object-level authorization.
- **GAP-POL-003:** Analytics, Refinement, and Substitution controllers have **zero** Gate::authorize calls -- completely unprotected.
- **GAP-POL-004:** The TimetableApiController (REST API) has no auth middleware beyond `auth:sanctum` -- no permission checks on individual endpoints.

---

## SECTION 8: VIEW AUDIT
Views exist in `resources/views/` with folders: smart-timetable, timetable, preview, constraint-management, pages, generation, analytics. Not deeply audited as focus is backend.

---

## SECTION 9: SECURITY AUDIT

| ID | Severity | Issue | Location |
|---|---|---|---|
| SEC-TT-001 | CRITICAL | No `EnsureTenantHasModule` middleware on route group | `tenant.php:1866` |
| SEC-TT-002 | CRITICAL | Analytics/Refinement/Substitution controllers have zero authorization | Multiple controllers |
| SEC-TT-003 | HIGH | `Faker\Factory` imported in production controller | `SmartTimetableController.php:8` |
| SEC-TT-004 | HIGH | Raw SQL deletes bypass SoftDeletes in `destroy()` | `SmartTimetableController.php:983-995` |
| SEC-TT-005 | HIGH | Session stores large timetable grid data (~MB) -- session fixation risk | `SmartTimetableController.php:2805-2855` |
| SEC-TT-006 | MEDIUM | `DB::table('tt_timetable_cell_teachers')` raw inserts bypass model validation | `SmartTimetableController.php:777` |
| SEC-TT-007 | MEDIUM | No rate limiting on generation endpoint -- CPU-intensive operation | `tenant.php:1872` |
| SEC-TT-008 | MEDIUM | Error messages expose internal details to users | `SmartTimetableController.php:823` |
| SEC-TT-009 | MEDIUM | API controller lacks per-endpoint authorization | `TimetableApiController.php` |
| SEC-TT-010 | LOW | Unused imports (Hash, Faker) could indicate code smell | Lines 8-9 |

---

## SECTION 10: PERFORMANCE AUDIT

| ID | Severity | Issue | Location |
|---|---|---|---|
| PERF-TT-001 | CRITICAL | `viewAndRefinement()` loads ALL timetable cells globally without pagination | `SmartTimetableController.php:3159-3171` |
| PERF-TT-002 | CRITICAL | `index()` performs 15+ separate queries with no caching | `SmartTimetableController.php:109-233` |
| PERF-TT-003 | HIGH | `timetableOperation()` loads entire RequirementConsolidation table then filters in PHP | `SmartTimetableController.php:1066-1096` |
| PERF-TT-004 | HIGH | Large session payloads storing timetable grids (can be 10-50MB per session) | `SmartTimetableController.php:2805` |
| PERF-TT-005 | HIGH | Bulk inserts at 500-row chunks without index optimization | `SmartTimetableController.php:714-716` |
| PERF-TT-006 | MEDIUM | No database indexes on frequently queried combination columns | Multiple tables |
| PERF-TT-007 | MEDIUM | `loadActivitiesForActiveClassSections()` loads ALL activities with 12 eager-load relations | `SmartTimetableController.php:854-875` |
| PERF-TT-008 | MEDIUM | FETSolver backtrack_timeout of 25s can block web request thread | `FETSolver.php:78` |
| PERF-TT-009 | LOW | No query caching for reference data (DayType, PeriodType, etc.) | Multiple locations |

---

## SECTION 11: ARCHITECTURE AUDIT

- **GAP-ARCH-001 (P0):** God controller pattern. SmartTimetableController at 3,245 lines violates Single Responsibility Principle.
- **GAP-ARCH-002:** No Service layer for controller-level operations. Generation, storage, and view data assembly are all in the controller.
- **GAP-ARCH-003:** Dual-module architecture (SmartTimetable + TimetableFoundation) with backward-compatibility alias models creates confusion and tight coupling.
- **GAP-ARCH-004:** Timetable generation runs synchronously in web request (no queue job used in the main flow, despite `GenerateTimetableJob` existing).
- **GAP-ARCH-005:** Session-based data passing between generate and store endpoints is fragile and not scalable for concurrent users.

---

## SECTION 12: TEST COVERAGE

- **0 tests found.** No unit tests, no feature tests, no integration tests in the SmartTimetable module or the global tests directory.
- Tests mentioned in MEMORY (ConstraintManagerTest, TeacherConflictConstraintTest, SlotTest) were NOT found in the codebase.

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

- **Generation:** FETSolver works with backtracking+greedy. Constraint engine is effectively disabled (all commented out in controller).
- **Storage:** Works but uses session-based data transfer.
- **Preview:** Functional but coupled to session data.
- **Analytics:** Controller exists, routes registered. Likely functional.
- **Refinement:** Controller exists with swap/move/lock. Uses inline validation.
- **Substitution:** Controller exists with absence/assign flow. No pattern learning in controller flow.
- **Standard Timetable:** Non-functional -- empty route group, single controller with one method.

---

## PRIORITY FIX PLAN

### P0 -- Critical (Must Fix Before Production)
1. Add `EnsureTenantHasModule` middleware to SmartTimetable route group
2. Add Gate::authorize to AnalyticsController, RefinementController, SubstitutionController
3. Split SmartTimetableController into TimetableGenerationController, TimetableConfigController, TimetableViewerController, TimetableMasterController, MenuNavigationController
4. Replace inline validation with FormRequests in storeTimetable and generateWithFET
5. Fix `viewAndRefinement()` to not load all cells globally
6. Remove `Faker\Factory` import from production controller

### P1 -- High Priority
7. Create policies for all 14 controllers
8. Replace raw `DB::table()` calls with model operations
9. Move generation to queue job (GenerateTimetableJob exists but unused)
10. Replace session-based data passing with database-based approach
11. Add FormRequests for all remaining inline validations (11 missing)
12. Fix Timetable::generationStrategy() relationship (points to wrong model)

### P2 -- Medium Priority
13. Remove 21 phantom models with no DDL tables
14. Add rate limiting to generation and API endpoints
15. Enable constraint engine (uncomment constraints or use DB-based loading)
16. Add comprehensive test suite (target: 60%+ coverage)
17. Add query caching for reference data

### P3 -- Low Priority
18. Clean up unused imports
19. Add database indexes for performance
20. Consolidate backward-compatibility alias models

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|---|---|---|
| P0 | 6 items | 40-50 hours |
| P1 | 6 items | 30-40 hours |
| P2 | 5 items | 25-35 hours |
| P3 | 3 items | 10-15 hours |
| **Total** | **20 items** | **105-140 hours** |
