# Module Knowledge — STT: SmartTimetable
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | SmartTimetable |
| Module Code | STT |
| Table Prefix | `tt_*` (shared across SmartTimetable + TimetableFoundation + StandardTimetable — distinguish by table name, not prefix alone) |
| Laravel Module Path | `Modules/SmartTimetable/` |
| Namespace | `Modules\SmartTimetable` |
| DB Layer | **Tenant** — tenant_db (no `tenant_id` column; isolated by DB connection) |
| Domain Scope | Tenant — Timetable Coordinator / School Admin / Principal / Teacher / Parent / Student (read-only) |
| V2 Requirement | `STT_SmartTimetable_Requirement.md` (2026-03-26); overall completion ~48% (Grade F) |
| V1 Screen Specs | 7 files in `SmartTimetable_V2/` folder |
| RBS Reference | Not confirmed in paths.md — check `PrimeAI_RBS_Menu_Mapping_v2.0.md` |
| Key Dependency | **TimetableFoundation (TTF)** — foundation masters (shifts, periods, working days, availability) live in TTF; STT is the AI generation engine built on top |
| Policy Registration | Module's own `SmartTimetableServiceProvider` (NOT central AppServiceProvider) |
| V2 Scorecard Overall | ~48% / Grade F |

---

### Verified File Counts (from `find Modules/SmartTimetable -type f` — 2026-06-30)

| Component | Actual | V2 Said | Notes |
|-----------|--------|---------|-------|
| Web Controllers | 17 | 19 | V2 overcounted by 2; those 2 proposed controllers (TimetableConfigController, TimetableMasterController) do not exist yet — see Section 6.2 of V2 |
| API Controllers | 1 | 1 | TimetableApiController (auth:sanctum, 16 endpoints) |
| Models | 62 | 62 | Matches; 21 are phantom models with no DDL backing (see Phantom Models section below) |
| Policies | 2 | 2 | SmartTimetablePolicy (Timetable), TimetableGenerationStrategyPolicy (TtGenerationStrategy) |
| FormRequests | 13 | 7 | V2 was outdated — 6 additional FormRequests added since V2 was written; still 9+ missing |
| Services (total files) | 111 | ~22 | V2's "~22" counted only non-constraint-class files; 86 of the 111 are individual constraint PHP classes (24 Hard + 62 Soft) |
| Services (non-constraint) | ~25 | ~22 | Root services (11) + Constraint infrastructure (6) + Generator (3) + Solver (4) + Storage (1) = 25 |
| Hard Constraint Classes | 24 | 24 | PHP Strategy pattern, implement TimetableConstraint interface |
| Soft Constraint Classes | 62 | 62 | Matches |
| Jobs | 1 | 1 | GenerateTimetableJob |
| Exceptions | 1 | — | HardConstraintViolationException |
| Exports | 1 | — | TimetableExport |
| Tests | 3 Unit | 7 | V2 listed 7 projected tests that do NOT match actual files; actual 3 are in `tests/Unit/` (not `tests/Unit/SmartTimetable/`) |
| Seeders | 10 | 9 | V2 listed 9 required; 10 found |
| Views (Blade) | 177 | 50+ | Significant growth since V2 was written |

### Actual Test Files Found (3 — different from V2's projected list)

| File | Type |
|------|------|
| `tests/Unit/ClassTeacherAutoAssignerTest.php` | Unit |
| `tests/Unit/MandatoryFillAuditorTest.php` | Unit |
| `tests/Unit/PreplaceClassTeacherFirstSlotsTest.php` | Unit |

V2 projected 7 different test files (ActivityControllerTest, ActivityModelTest, ConstraintClassesTest, ConstraintEvaluatorTest, FETSolverScoringTest, ParallelGroupBacktrackTest, TimetableSolutionIsPlacedTest) — none of these exist in the codebase. The actual tests cover different service classes.

---

## Module Score Summary (V2 Gap Analysis 2026-03-26)

| Category | Score | Grade | V2 Target |
|----------|-------|-------|-----------|
| DB Integrity | 70% | C | 90% |
| Route Integrity | 65% | D | 95% |
| Controller Audit | 40% | F | 85% |
| Model Audit | 75% | C | 95% |
| Service Audit | 70% | C | 90% |
| FormRequest Audit | 30% | F | 100% |
| Policy / Auth Audit | 35% | F | 95% |
| Security Audit | 45% | F | 95% |
| Performance Audit | 50% | D | 80% |
| Architecture | 45% | F | 85% |
| Test Coverage | 0% | F | 60% |
| **Overall** | **~48%** | **F** | **88%** |

---

## DDL Table Inventory

**CRITICAL OWNERSHIP NOTE:** All tables use the `tt_*` prefix. Ownership is determined by which module's controllers manage the data, not by prefix alone.

### STT-Owned Tables (28 total: 24 DDL-backed + 4 migration-only)

#### Configuration & Generation Core (2)

| Table | Migration Confirmed | Key Fields | Notes |
|-------|:------------------:|-----------|-------|
| `tt_generation_strategies` | YES | code, name, algorithm_type ENUM(GENETIC/HYBRID/RECURSIVE/SIMULATED_ANNEALING/TABU_SEARCH), max_recursive_depth, max_placement_attempts, tabu_size, cooling_rate, population_size, generations, activity_sorting_method ENUM, timeout_seconds, parameters_json, is_default, is_active | Table name in migration is `tt_generation_strategies` (plural — V2 doc says `tt_generation_strategy`) |
| `tt_generation_runs` | YES | run_number, started_at, finished_at, status ENUM(CANCELLED/COMPLETED/FAILED/QUEUED/RUNNING), strategy_id (nullable per 2026-06-25 migration), algorithm_version, activities_total/placed/failed, hard_violations, soft_violations, soft_score, stats_json, error_message | UNIQUE(timetable_id, run_number). FK to tt_timetables + sys_users |

#### Constraint Engine (5)

| Table | Notes |
|-------|-------|
| `tt_constraint_category_scope` | type ENUM('CATEGORY','SCOPE') — seeded; both categories and scopes live in this table |
| `tt_constraint_type` | System-defined constraint types; school can enable/disable; param_schema JSON drives dynamic forms |
| `tt_constraint` | Per-instance constraint records; is_hard flag overrides constraint_type.is_hard_constraint; weight 1–100; effective_date_range + applicable_days_json |
| `tt_teacher_unavailable` | UI-layer records backed by tt_constraint; recurring + date-range patterns |
| `tt_room_unavailable` | UI-layer records backed by tt_constraint |

#### Activity & Parallel Groups (7, including 1 migration-only)

| Table | Generated Columns | Notes |
|-------|:-----------------:|-------|
| `tt_activity` | `total_periods` = duration_periods × weekly_periods (STORED) — **NEVER put in `$fillable`** | status ENUM(DRAFT/ACTIVE/LOCKED/ARCHIVED); requires_room, required/preferred room fields |
| `tt_sub_activity` | — | same_day_as_parent, consecutive_with_previous flags |
| `tt_activity_teacher` | — | assignment_role_id FK, is_required, ordinal |
| `tt_activity_priority` | — | priority_score 0.00–100.00 |
| `tt_priority_config` | — | Scoring factor weights (scarcity, load_ratio, TAR, rigidity, resource_scarcity, difficulty) |
| `tt_parallel_group` | — | **⚠ DAT-TT-001 P0: NO MIGRATION EXISTS** — table never created on fresh tenant; all parallel-group CRUD crashes with SQLSTATE[42S02] |
| `tt_parallel_group_activity` | — | **⚠ DAT-TT-001 P0: NO MIGRATION EXISTS** — previously misclassified as "migration-only"; confirmed 2026-06-30 audit: no migration file anywhere in codebase |

#### Core Timetable Grid (8)

| Table | Notes |
|-------|-------|
| `tt_timetables` | Root timetable document; status ENUM(DRAFT/GENERATING/GENERATED/PUBLISHED/ARCHIVED); parent_timetable_id for versioning |
| `tt_timetable_cells` | Grid cells; UNIQUE(timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id); is_locked |
| `tt_timetable_cell_teachers` | Teachers per cell; UNIQUE(cell_id, teacher_id); is_substitute flag |
| `tt_conflict_detection` | Conflict scan results; detection_type, conflicts_json, resolution_suggestions_json |
| `tt_constraint_violations` | Per-constraint violations; violation_type HARD/SOFT |
| `tt_resource_bookings` | Resource reservations; resource_type ENUM, status ENUM |
| `tt_change_logs` | Audit trail for all cell modifications; change_type ENUM; old/new_values_json |

Note: Actual table names (plural vs singular) need verification against migrations — V2 uses singular forms (`tt_timetable`, `tt_timetable_cell`, etc.); confirmed migrations use `tt_generation_strategies` and `tt_generation_runs` (plural).

#### Analytics (3, including 1 migration-only)

| Table | Notes |
|-------|-------|
| `tt_teacher_workload` | Computed per teacher per timetable; UNIQUE(teacher+session+timetable); utilization%, gap_periods, consecutive_max, daily_distribution_json |
| `tt_room_utilizations` | Computed room utilization per timetable |
| `tt_analytics_daily_snapshots` | **MIGRATION-ONLY** — daily snapshot (upsert by date) (GAP-DB-001) |

#### Substitution (4, including 3 migration-only)

| Table | Notes |
|-------|-------|
| `tt_teacher_absences` | Absence records; status PENDING/APPROVED/REJECTED/CANCELLED |
| `tt_substitution_logs` | Assignment records; status ASSIGNED/COMPLETED/CANCELLED |
| `tt_substitution_patterns` | **MIGRATION-ONLY** — ML pattern; teacher+day+subject success_rate (running exponential average) (GAP-DB-001) |
| `tt_substitution_recommendations` | **MIGRATION-ONLY** — Auto-generated substitute suggestions per cell (GAP-DB-001) |

---

### TTF-Owned Tables (20 tables — SmartTimetable reads these but does NOT own them)

SmartTimetable depends heavily on these tables from TimetableFoundation module. Their controllers were originally in SmartTimetable and "MOVED to TimetableFoundation" (confirmed by commented-out imports at the top of `routes/tenant.php`).

| Table | Generated Columns | Key Notes |
|-------|:-----------------:|-----------|
| `tt_config` | — | 14 system keys; tenant_can_modify flag |
| `tt_shift` | — | School shift definitions |
| `tt_day_type` | — | STUDY/HOLIDAY/EXAM/SPECIAL/PTM_DAY/SPORTS_DAY/ANNUAL_DAY |
| `tt_period_type` | — | is_schedulable, counts_as_teaching, is_break flags |
| `tt_teacher_assignment_role` | — | PRIMARY/ASSISTANT/CO_TEACHER/SUBSTITUTE/TRAINEE; workload_factor |
| `tt_school_days` | — | day_of_week 1–7; is_school_day |
| `tt_working_day` | — | Date-level calendar; day_type1-4_id |
| `tt_class_working_day_jnt` | — | Per-class day overrides; is_exam_day, is_ptm_day |
| `tt_period_set` | — | Period set template; total/teaching/exam/free period counts |
| `tt_period_set_period_jnt` | `duration_minutes` (STORED) | Per-period start/end_time; **NEVER put `duration_minutes` in `$fillable`** |
| `tt_timetable_type` | — | shift_id, effective_from/to; non-overlapping constraint |
| `tt_class_timetable_type_jnt` | — | period_set assignment per class/section/term |
| `tt_slot_requirement` | — | Weekly slot budget per class/section/term |
| `tt_class_requirement_groups` | — | class+section+subject+study_format combination |
| `tt_class_requirement_subgroups` | — | is_shared_across_sections/classes |
| `tt_requirement_consolidation` | — | CHECK: group_id XOR subgroup_id; full scheduling params |
| `tt_teacher_availability` | `available_for_full_timetable_duration` (STORED), `no_of_days_not_available` (STORED) | Two GENERATED STORED columns — **NEVER put either in `$fillable`** |
| `tt_teacher_availability_detail` | — | Per day+period; availability_for_period ENUM(Available/Unavailable/Assigned/Free Period) |
| `tt_room_availability` | `available_for_full_timetable_duration` (possibly STORED — verify) | Room aggregate availability |
| `tt_room_availability_detail` | — | Per day+period room availability |

---

### Phantom Models in SmartTimetable (21 models with NO DDL backing)

These models exist as PHP classes but have no corresponding database tables. Must either add DDL migrations or remove the classes (V2 recommendation: remove non-ML models; defer ML models to a future ML phase).

`ApprovalDecision`, `ApprovalLevel`, `ApprovalNotification`, `ApprovalRequest`, `ApprovalWorkflow`, `BatchOperation`, `BatchOperationItem`, `EscalationLog`, `EscalationRule`, `FeatureImportance`, `MlModel`, `OptimizationIteration`, `OptimizationMove`, `OptimizationRun`, `PredictionLog`, `RevalidationSchedule`, `RevalidationTrigger`, `TrainingData`, `VersionComparison`, `VersionComparisonDetail`, `WhatIfScenario`

---

## Known Gaps & Open Issues

### P0 — Critical (Security / Production Blockers)

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| SEC-STT-01 | **EnsureTenantHasModule absent from both route groups** (SEC-PLATFORM-003) | `routes/web.php` lines 21, 36 | Add `EnsureTenantHasModule::class.':smart-timetable'` to both middleware stacks |
| SEC-STT-02 | ~~Zero Gate::authorize on AnalyticsController, RefinementController, SubstitutionController~~ **RESOLVED 2026-06-30** — all three controllers confirmed to have Gate::authorize calls on every method | — | — |
| SEC-TT-004 | **API routes (`routes/api.php`) missing ALL tenancy middleware** — mapApiRoutes() only applies `'api'`; all 7 endpoints run in central prime_db context | `app/Providers/RouteServiceProvider.php:57` | Add InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive to mapApiRoutes() |
| DAT-TT-001 | **tt_parallel_groups + tt_parallel_group_activity have NO migration** — confirmed zero migration files anywhere in codebase; parallel-group CRUD crashes with SQLSTATE[42S02] on every tenant | `ParallelGroup.php`, `ParallelGroupActivity.php` models | Create two tenant migrations; see known-issues.md DAT-TT-001 for column specs |
| JOB-TT-001 | **GenerateTimetableJob has no tenancy re-initialization** — no QueueTenancyBootstrapper registered; job queries tenant models in wrong DB context | `app/Jobs/GenerateTimetableJob.php:36+` | Register QueueTenancyBootstrapper; add explicit tenancy init in handle() |
| BUG-STT-03 | **SmartTimetableController is 3,245 lines (god-class)** — 12 specific code-level issues documented within it (GAP-CTRL-001 through GAP-CTRL-012). Resource store() and update() methods are empty stubs | `app/Http/Controllers/SmartTimetableController.php` | Extract TimetableGenerationController (exists), TimetableConfigController (missing), TimetableViewerController (missing), TimetableMasterController (missing) |
| BUG-STT-04 | **`createConstraintManager()` in SmartTimetableController returns empty ConstraintManager** — all constraint loading is commented out at lines 277–317. Generation runs with zero DB constraints enforced (only inline hardcoded constraints in the solver) | `app/Http/Controllers/SmartTimetableController.php` lines 277–317 | Uncomment and implement constraint loading from `tt_constraint` table via ConstraintManager |
| BUG-STT-05 | **PrimeConstraintBridge broken** — PHP constraint classes not wired to PrimeSolver. Generation runs but ignores all constraints defined in the DB (BR-STT-005 violated: hard constraints not enforced from DB). V2 calls this "FETConstraintBridge" — actual code is `PrimeConstraintBridge.php` | `app/Services/Generator/PrimeConstraintBridge.php` | Fix context initialization order; inject ConstraintManager into PrimeSolver |
| PERF-STT-06 | **viewAndRefinement() loads ALL timetable cells globally** — `TimetableCell::all()` on a large school can trigger OOM in production | `app/Http/Controllers/SmartTimetableController.php` (viewAndRefinement method) | Replace with paginated, timetable-scoped query: `TimetableCell::where('timetable_id', $timetable->id)->paginate(100)` |
| SEC-STT-07 | **`Faker\Factory` imported in production controller** — development library in production code is a security and deployment risk | `app/Http/Controllers/SmartTimetableController.php` (top use statements) | Remove Faker import and any code that uses it |

### P1 — High Priority

| ID | Issue | Location |
|----|-------|---------|
| GAP-STT-08 | Route `generateForClassSection` registered in routes/web.php (line 57) but the controller method does not exist in `TimetableGenerationController` | `Modules/SmartTimetable/routes/web.php` line 57 |
| GAP-STT-09 | `standard-timetable.*` route group in `tenant.php` is completely empty — Standard Timetable views (class/teacher/room) are not built at all (FR-STT-16 entirely missing) | `routes/tenant.php` standard-timetable group |
| BUG-STT-10 | `destroy()` method uses raw SQL hard-delete on TimetableCell and GenerationRun, bypassing SoftDeletes. Pattern: `DB::table('tt_timetable_cells')->where(...)->delete()` | `SmartTimetableController::destroy()` |
| BUG-STT-11 | `Timetable::generationStrategy()` relationship (BelongsTo) points to `GenerationRun::class` instead of `TtGenerationStrategy::class` — wrong model; relationship returns wrong data | `app/Models/Timetable.php` generationStrategy() method |
| GAP-STT-12 | Missing FormRequests for: `storeTimetable()` (currently 312 lines inline), `generateWithFET()` (~900 lines inline), `RefinementController` swap/move/toggleLock, `SubstitutionController` reportAbsence/assign/autoAssign, `TimetableApiController` cell update | 11 controllers |
| GAP-STT-13 | 12 missing policies: AnalyticsController, RefinementController, SubstitutionController, ConstraintCategoryScopeController, ConstraintTypeController, ParallelGroupController, TeacherUnavailableController, RoomUnavailableController, TimetableApiController, and 3 more | `app/Policies/` — only 2 of 14 needed policies exist |
| GAP-STT-14 | Parallel group routes/web.php uses middleware `['web', 'auth']` — missing `verified` middleware (inconsistent with main group) | `Modules/SmartTimetable/routes/web.php` line 21 |
| BUG-STT-15 | Session-based grid data transfer (10–50MB per session) — session fixation / memory risk; timetable data should be stored in DB (`tt_generation_run.stats_json`) instead of PHP session | `SmartTimetableController` (session storage in generation flow) |
| GAP-STT-16 | Timetable approval UI not built: approval/reject buttons and confirmation modal missing; Gate::authorize('smart-timetable.approve') missing on approval action (FR-STT-11.4–11.6) | `app/Http/Controllers/TimetablePublishController.php` |
| GAP-STT-17 | Generation must run fully async via queue — sync path also present in code (GAP-ARCH-004). Web thread must never block during 25s–600s generation | `SmartTimetableController` / `TimetableGenerationController` |
| GAP-STT-18 | `destroy()` uses raw SQL hard-delete on tt_timetable_cell_teachers: `DB::table('tt_timetable_cell_teachers')->where(...)->delete()` instead of model soft-delete | `SmartTimetableController::destroy()` |

### P2 — Medium Priority

| ID | Issue | Location |
|----|-------|---------|
| GAP-STT-19 | 4 migration-only tables need DDL: tt_parallel_group_activity, tt_analytics_daily_snapshots, tt_substitution_patterns, tt_substitution_recommendations | `database/migrations/tenant/` — migrations exist, DDL not in canonical schema |
| GAP-STT-20 | 21 phantom models need resolution (remove or add DDL) | `app/Models/` — list in Phantom Models section |
| SEC-STT-21 | No rate limiting on generation endpoint (CPU-intensive) or TimetableApiController | `routes/web.php`, `Modules/SmartTimetable/routes/web.php` |
| GAP-STT-22 | `ImprovedTimetableGenerator` exists in `Services/Generator/` but is never called — dead code | `app/Services/Generator/ImprovedTimetableGenerator.php` |
| GAP-STT-23 | TimetableFoundation alias models used in SmartTimetable create fragile double-namespace dependency | All TTF model references within STT code |
| PERF-STT-24 | Reference data (DayType, PeriodType) not cached in index() — 15+ queries on each page load (PERF-TT-002) | `SmartTimetableController::index()` |
| PERF-STT-25 | Missing composite indexes on `(timetable_id, day_of_week, period_ord)` and `(timetable_id, class_group_id)` — needed for grid queries | DDL for tt_timetable_cells |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-STT-26 | Zero test coverage for generation pipeline, constraint enforcement, timetable status flow, substitution flow, API auth — 10 new test files needed for 60% target |
| GAP-STT-27 | iCal export scaffolded only in `TimetableApiController::exportIcal()` — not implemented |
| GAP-STT-28 | What-If scenario UI not built (WhatIfScenario model exists but no controller/views) |
| GAP-STT-29 | Version comparison diff view not built (VersionComparison model exists but no controller/views) |
| GAP-STT-30 | PDF export not implemented (V2 suggests DomPDF pattern from HPC module) |
| GAP-STT-31 | Substitution notification to substitute teacher (via Notification module) — not confirmed implemented |
| GAP-STT-32 | activityLog() helper calls for state-changing operations — partially implemented; systematic coverage not confirmed |

---

## Feature Area Status (as of 2026-06-30)

| # | Feature Area | FR | Status | Notes |
|---|-------------|----|---------|----|
| 1 | Foundation Masters Setup | FR-STT-01 | ✅ 95% | **Implemented in TTF module** — shifts, days, periods, period sets, working day calendar |
| 2 | Timetable Requirement Definition | FR-STT-02 | ✅ 90% | **Implemented in TTF module** — slot requirements, class groups, subgroups, consolidation |
| 3 | Constraint Engine (classes) | FR-STT-03 | 🟡 60% | 24 Hard + 62 Soft constraint classes exist; FETConstraintBridge broken; createConstraintManager() commented out |
| 4 | Teacher & Room Availability | FR-STT-04 | ✅ 85% | **Implemented in TTF module** — GENERATED columns in tt_teacher_availability must not be in $fillable |
| 5 | Activity Management | FR-STT-05 | ✅ 90% | CRUD, batch generation, scoring implemented; total_periods GENERATED column |
| 6 | Parallel Period Groups | FR-STT-06 | ✅ 85% | CRUD + anchor + auto-detect implemented; pivot table migration-only (GAP-DB-001) |
| 7 | Generation Strategy Config | FR-STT-07 | 🟡 75% | CRUD works; StrategyActivationRequest missing (GAP-FR-011); routes registered in TTF not STT |
| 8 | Timetable Creation / Pre-Gen Validation | FR-STT-08 | 🟡 65% | storeTimetable() inline 312-line validation (no FormRequest); ValidationService works |
| 9 | Generation Engine (FET/Prime Solver) | FR-STT-09 | 🟡 55% | PrimeSolver runs but constraints not wired (BUG-STT-05); sync path exists (GAP-STT-17) |
| 10 | Generation Monitoring | FR-STT-10 | ✅ 90% | tt_generation_run, status polling, live progress view implemented |
| 11 | Timetable Approval Workflow | FR-STT-11 | ❌ 30% | Status transitions partially done; approval UI not built; no Gate::authorize on approval |
| 12 | Timetable Publishing | FR-STT-12 | 🟡 50% | TimetablePublishController exists; publish/unpublish routes wired; archive/parent versioning incomplete |
| 13 | Post-Generation Analytics | FR-STT-13 | ✅ 85% | computeTeacherWorkload/RoomUtilization/ConstraintViolations/DailySnapshot all implemented; ZERO auth (SEC-STT-02) |
| 14 | Manual Refinement (Swap/Move/Lock) | FR-STT-14 | 🟡 65% | Swap/move/lock implemented; FormRequests missing; no Gate::authorize; pagination bug (PERF-STT-06) |
| 15 | Substitution Management | FR-STT-15 | 🟡 65% | Core flow implemented; FormRequests missing; no Gate::authorize; notification to substitute not confirmed |
| 16 | Standard Timetable View | FR-STT-16 | ❌ 0% | Route group in tenant.php is completely empty; no controller, views, or routes exist |
| 17 | REST API (16 endpoints) | FR-STT-17 | 🟡 70% | Endpoints exist with auth:sanctum; per-endpoint Gate::authorize missing; no rate limiting |
| 18 | EnsureTenantHasModule | — | ❌ 0% | Not applied to any route group (SEC-STT-01 — P0) |
| 19 | Policy Coverage | — | ❌ 14% | 2 of 14 needed policies exist; 12 missing (GAP-STT-13) |
| 20 | FormRequest Coverage | — | 🟡 45% | 13 of ~24 needed FormRequests exist; 11+ missing |
| 21 | Test Coverage | — | ❌ ~5% | 3 Unit tests covering ClassTeacherAutoAssigner, MandatoryFillAuditor, PreplaceClassTeacherFirstSlots only |

---

## Generation Algorithm (PrimeSolver / FET-Inspired CSP Engine)

### Algorithm Architecture

SmartTimetable uses a **FET-inspired Constraint Satisfaction Problem (CSP)** solver implemented in `PrimeSolver.php` (V2 documentation calls it "FETSolver" — the actual code file is `PrimeSolver.php` in `Services/Generator/`).

### 10-Step Generation Pipeline (runs inside GenerateTimetableJob — async)

1. **Pre-generation validation** (`ValidationService`) — checks activities exist, teachers available, constraints valid, rooms available
2. **Activity scoring** (`ActivityScoreService`) — 6 factors: scarcity_index + load_ratio + TAR + rigidity + resource_scarcity + difficulty_score
3. **Room allocation pass** (`RoomAllocationPass`) — pre-assigns rooms before placement
4. **Sub-activity generation** (`SubActivityService`) — splits multi-period activities
5. **PrimeSolver CSP backtracking** — activity-first, hardest (fewest eligible teachers) placed first; 50,000 max iterations, 25s per-run timeout (configurable via `tt_generation_strategies`)
6. **Post-solver optimization** — TabuSearchOptimizer or SimulatedAnnealingOptimizer (configurable via strategy `algorithm_type`)
7. **SolutionEvaluator** — computes hard_violations, soft_violations, soft_score
8. **Atomic DB storage** (`TimetableStorageService`) — single transaction; all cells + cell_teachers stored
9. **ResourceBookingService** — creates `tt_resource_booking` records for ROOM and TEACHER resources
10. **ConflictDetectionService.detectFromGrid()** — post-storage conflict scan

### Activity Placement Algorithm

- **Sorting strategy:** `activity_sorting_method` in `tt_generation_strategies` (default: `LESS_TEACHER_FIRST` — places activities with fewest eligible teachers first to reduce backtracking)
- **Placement check per slot:** teacher conflict + student group conflict + room availability + teacher unavailability + max daily load + parallel group anchor enforcement
- **Backtracking:** on conflict, undo placement and try next available slot
- **Parallel group rule:** first activity placed defines anchor (day_of_week, period_ord); all group members forced to anchor slot via `ParallelPeriodConstraint`

### Constraint Strategy Pattern (86 PHP classes)

All constraints implement the `TimetableConstraint` interface. Registered in `ConstraintRegistry` via `SmartTimetableServiceProvider::registerConstraints()`. **CRITICAL BUG:** `PrimeConstraintBridge` context initialization is broken — DB-defined constraint instances are NOT loaded into the solver, so only hardcoded inline checks in PrimeSolver are enforced during generation.

| Layer | Files | Registration |
|-------|-------|-------------|
| Hard constraints | 24 PHP classes in `Services/Constraints/Hard/` | ConstraintRegistry::registerMany() |
| Soft constraints | 62 PHP classes in `Services/Constraints/Soft/` | ConstraintRegistry::registerMany() |
| Infrastructure | `ConstraintManager`, `ConstraintEvaluator`, `ConstraintFactory`, `ConstraintContext`, `ConstraintRegistry`, `TimetableConstraint` interface | — |

### Optimization Algorithms (configurable per strategy)

| Algorithm | Implementation | Key Parameters |
|-----------|---------------|----------------|
| `RECURSIVE` (default) | Backtracking + greedy in PrimeSolver | max_recursive_depth (default 14), max_placement_attempts (default 2000) |
| `TABU_SEARCH` | `TabuSearchOptimizer` — within-class swaps; hard violations ×1000 weight | tabu_size (default 100) |
| `SIMULATED_ANNEALING` | `SimulatedAnnealingOptimizer` — temperature-based acceptance | cooling_rate (default 0.95) |
| `GENETIC` | Not confirmed implemented (population_size + generations params exist in schema) | — |
| `HYBRID` | Post-recursive optimization via Tabu or SA | Configurable |

### Substitution Scoring (4-factor, 100 points)

| Factor | Weight | Description |
|--------|--------|-------------|
| Subject match | 40 pts | Substitute teaches the same subject as original teacher |
| Pattern × confidence | 25 pts | tt_substitution_patterns: historical success_rate for teacher+day+subject |
| Day availability | 20 pts | Teacher available (not already assigned) for the period |
| Workload balance | 15 pts | Balances total periods across substitutes |

---

## Cross-Module Dependencies

### STT Consumes From (Inbound)

| Source Module | Data / Entity | Usage |
|---------------|--------------|-------|
| TimetableFoundation (TTF) | Foundation masters: tt_shift, tt_period_set, tt_school_days, tt_working_day, tt_teacher_availability, tt_requirement_consolidation, tt_slot_requirement, tt_class_requirement_groups, tt_class_timetable_type_jnt, tt_config | ALL generation prerequisites — STT cannot generate without TTF setup being complete |
| SchoolSetup (SCH) | sch_classes, sch_sections, sch_rooms, sch_teachers, sch_subjects, sch_buildings | Core entities for activity definition and room allocation |
| StudentProfile (STD) | std_students | Student count in requirement groups |
| SyllabusModule (SLB) | Subjects and study formats | Activity subject+study_format definition |
| SystemConfig (SYS) | sys_users | triggered_by FK on tt_generation_runs; published_by on tt_timetables |
| Notification (NTF) | Notification module | Substitution notification to assigned substitute teacher (not confirmed implemented) |

### STT Provides To (Outbound)

| Consumer | Mechanism | What STT Provides |
|----------|-----------|------------------|
| Teachers / Parents / Students | REST API (auth:sanctum, 16 endpoints) | Published timetable grid; teacher/room/class filtered views |
| StandardTimetable views | Planned — AnalyticsService report methods | Published grid data for standard (non-AI) timetable views |
| TimetableFoundation (TTF) | Shared `tt_timetable` record | TTF reads published timetable for display |

### Cross-Module Route Registration (Known Overlap)

`TtGenerationStrategyController` resides in **SmartTimetable** (`Modules/SmartTimetable/app/Http/Controllers/TtGenerationStrategyController.php`) but is registered in **TimetableFoundation** routes (`Modules/TimetableFoundation/routes/web.php` lines 304–309):

```php
// In Modules/TimetableFoundation/routes/web.php:
use Modules\SmartTimetable\Http\Controllers\TtGenerationStrategyController;
// ...
Route::resource('generation-strategies', TtGenerationStrategyController::class);
Route::post('/{generation_strategy}/toggle-default', [TtGenerationStrategyController::class, 'toggleDefault'])
    ->name('generation-strategies.toggleDefault');
```

This means generation strategy CRUD is accessible under the `timetable-foundation.*` route prefix, not `smart-timetable.*`. This creates confusion about which module "owns" the strategy concept.

---

## Permission Architecture

### Registered Policies (2 — registered in SmartTimetableServiceProvider, NOT AppServiceProvider)

| Policy | Model | Permission Prefix |
|--------|-------|------------------|
| `SmartTimetablePolicy` | `Timetable` | `tenant.smart-timetable.*` |
| `TimetableGenerationStrategyPolicy` | `TtGenerationStrategy` | `tenant.generation-strategy.*` (verify exact prefix) |

> Both are registered via `SmartTimetableServiceProvider::registerPolicies()`. The central `AppServiceProvider` has comments at lines 121 and 147 pointing to this service provider.

### Missing Policies (12 — P1 gap)

AnalyticsController, RefinementController, SubstitutionController, ConstraintCategoryScopeController, ConstraintController, ConstraintTypeController, ParallelGroupController, TeacherUnavailableController, RoomUnavailableController, TimetableApiController, and 2 more for the proposed split controllers.

### Role-Based Access Target

| Role | Access Level |
|------|-------------|
| School Admin / Timetable Coordinator | Full lifecycle: configure, generate, approve, publish, substitute |
| Principal | Approve timetable, view analytics |
| Teacher | View own schedule (standard view + REST API) |
| Parent / Student | View published timetable (REST API / portal, read-only) |
| System (Queue) | GenerateTimetableJob internal execution |

### Required Middleware Stack for All STT Routes

```php
Route::middleware([
    'web',
    'auth',
    'verified',
    EnsureTenantHasModule::class . ':smart-timetable',  // MISSING — SEC-STT-01
])->prefix('smart-timetable')->name('smart-timetable.')->group(function () {
    // all routes
});
```

---

## Route Registration Pattern

**Route registration:** All SmartTimetable routes are in `Modules/SmartTimetable/routes/web.php` (NOT in central `routes/tenant.php`). The central file has a comment at line 219: `// SmartTimetable routes → Modules/SmartTimetable/routes/web.php`.

**Two route groups in `Modules/SmartTimetable/routes/web.php`:**

| Group | Prefix | Middleware | Issue |
|-------|--------|-----------|-------|
| Parallel Group | `smart-timetable/parallel-group` | `['web', 'auth']` | Missing `verified` AND `EnsureTenantHasModule` |
| Main Group | `smart-timetable` | `['web', 'auth', 'verified']` | Missing `EnsureTenantHasModule` |

**`standard-timetable` route group:** Defined in `routes/tenant.php` (lines ~234–238) with `middleware(['auth', 'verified'])` and prefix `standard-timetable` — but the group closure is **completely empty** (GAP-STT-09 / BUG-TT-007). No routes registered.

**TtGenerationStrategyController cross-module registration:**
- Controller file: `Modules/SmartTimetable/app/Http/Controllers/TtGenerationStrategyController.php`
- Registered in: `Modules/TimetableFoundation/routes/web.php` lines 304–309
- Route names: `generation-strategies.*` (under TTF prefix)

**API Routes (16 endpoints):**
- Prefix: `/api/v1/timetable`
- Auth: `auth:sanctum`
- No rate limiting (SEC-STT-21 P2)
- No per-endpoint Gate::authorize (GAP-STT-02)
- Registered in: confirm in TimetableFoundation or SmartTimetable API route file

---

## V1 Screen Spec Inventory (7 files)

| File | Coverage |
|------|---------|
| `01-Foundation-and-Masters.md` | Shifts, Day Types, Period Types, School Days, Working Day Calendar, Period Sets, Timetable Types |
| `02-Requirements-and-Preparation.md` | Slot Requirements, Class Requirement Groups, Subgroups, Requirement Consolidation |
| `03-Constraint-Engine-and-Availability.md` | Constraint Categories/Scopes/Types, Constraint instances, Teacher/Room unavailability |
| `04-Generation-and-Conflict-Management.md` | Timetable creation, validation, generation dispatch, monitoring |
| `05-Refinement-View-and-Publish.md` | Preview grid, swap/move/lock cells, publishing workflow |
| `06-Analytics-and-Substitution.md` | Analytics dashboard, workload, utilization, substitution flow |
| `07-Smart-Dashboard-and-Workload.md` | Dashboard KPIs, workload summary |

---

## Design Decisions Made

| Decision | Detail | Source |
|----------|--------|--------|
| FET-inspired CSP approach | Uses backtracking + greedy (not pure FET), with optional post-solver Tabu Search or Simulated Annealing optimization. Activity-first placement (hardest first). | V2 Architecture |
| Solver renamed from FET to Prime | V2 documentation calls the solver "FETSolver" and bridge "FETConstraintBridge", but actual code is `PrimeSolver.php` and `PrimeConstraintBridge.php` in `Services/Generator/`. When reading V2 docs, mentally substitute FET → Prime | Code scan 2026-06-30 |
| `tt_activity.total_periods` as GENERATED STORED | `duration_periods × weekly_periods` auto-computed by MySQL. Cannot be written from PHP. Must not appear in `Activity::$fillable` | DDL / V2 FR-STT-05.9 |
| `tt_period_set_period_jnt.duration_minutes` as GENERATED STORED | TTF-owned GENERATED column. Developers working with PeriodSetPeriod model must never include this in $fillable | DDL |
| `tt_teacher_availability` has two GENERATED STORED columns | `available_for_full_timetable_duration` and `no_of_days_not_available` are both STORED computed columns. Must not appear in TeacherAvailability::$fillable | DDL / V2 FR-STT-04.3 |
| Substitution pattern learning via running average | `tt_substitution_patterns` stores `success_rate` updated as exponential running average on each `completeSubstitution()` call. This is the ML seed for future substitution AI | V2 FR-STT-15.7 |
| Constraint scope hierarchy | GLOBAL > CLASS > TEACHER > ROOM > ACTIVITY (BR-STT-006) | V2 Business Rules |
| Async generation mandatory | GenerateTimetableJob dispatched to queue; web thread must NOT block. 25s PrimeSolver timeout, 600s Laravel job timeout | V2 BR-STT-016 |
| Timetable status FSM | DRAFT → GENERATING → GENERATED → APPROVED → PUBLISHED → ARCHIVED. Revert GENERATED→DRAFT allowed. Hard constraint violations: warn but admin can override with reason | V2 §9.1 |
| TtGenerationStrategyController in TTF routes | Generation strategy CRUD is in STT module but registered under TTF routes for navigation/menu consistency. This is a known design debt. | Code + V2 §6.1 comment |
| Policies in module ServiceProvider | SmartTimetable registers its own policies in `SmartTimetableServiceProvider::registerPolicies()` instead of central AppServiceProvider — follows module-first pattern | SmartTimetableServiceProvider.php |
| 4 migration-only tables | tt_parallel_group_activity, tt_analytics_daily_snapshots, tt_substitution_patterns, tt_substitution_recommendations have Laravel migrations but are NOT in the canonical DDL schema file — must add to DDL in Phase 7 | V2 GAP-DB-001 |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] V2 documentation for STT uses "FETSolver" and "FETConstraintBridge" throughout, but the actual code files are `PrimeSolver.php` and `PrimeConstraintBridge.php` in `Services/Generator/`. Always verify V2 class name references against the actual filesystem — names were likely renamed from FET to Prime branding at some point after V2 was written.
- [2026-06-30 | Business Analyst] V2 listed 7 test files and said they were "confirmed present" via a Bash scan. Actual filesystem scan found only 3 test files with DIFFERENT names than V2's list. V2's test list was likely projected/planned test files that were never actually created. Always run `find ... tests -name "*.php"` and compare against V2's claim.
- [2026-06-30 | Business Analyst] STT's policies are registered in `SmartTimetableServiceProvider` (module-level), NOT in the central `AppServiceProvider`. The central AppServiceProvider has comments at lines 121 and 147 pointing to SmartTimetableServiceProvider. This differs from VND (Vendor) module which registers in AppServiceProvider directly — check each module's own ServiceProvider before assuming central registration.
- [2026-06-30 | Business Analyst] The `tt_*` table prefix is shared across THREE modules: SmartTimetable (28 tables), TimetableFoundation (20 tables), and StandardTimetable. Never assume a `tt_*` table belongs to SmartTimetable — determine ownership by which module's controllers manage it.
- [2026-06-30 | Business Analyst] `SmartTimetableController` has GENERATED STORED columns (`tt_activity.total_periods`) that must not be in `$fillable`. The TTF models also have generated columns (`duration_minutes`, `available_for_full_timetable_duration`, `no_of_days_not_available`). Always grep new STT-area models for `AS (` or `GENERATED` in DDL migrations before editing `$fillable`.
- [2026-06-30 | Business Analyst] The STT module has the most complex algorithm architecture of any seeded module: 86 constraint PHP classes, multiple optimization algorithms, 10-step async generation pipeline, and a CSP solver. The FRD and any gap analysis must acknowledge that "constraint not enforced" (BUG-STT-05) makes the current solver produce unconstrained outputs — this is the highest-impact architectural bug in the entire platform.
- [2026-06-30 | Business Analyst] FormRequest count was V2: 7, Actual: 13. Additional FormRequests were added AFTER V2 was written (StoreTeacherUnavailableRequest, UpdateTeacherUnavailableRequest, StoreRoomUnavailableRequest, UpdateRoomUnavailableRequest, ConstraintCategoryScopeRequest, ConstraintTypeRequest, DayRequest, UpdateParallelGroupRequest). Always verify FormRequest count against filesystem — V2 gap analyses capture a snapshot in time.
- [2026-06-30 | Technical Auditor] SEC-STT-02 (zero auth on Analytics/Refinement/Substitution) from BA analysis was WRONG — all three controllers confirmed to have Gate::authorize on every method as of the live code scan. Module-knowledge snapshots can be stale. Always re-verify auth claims by grepping live controllers.
- [2026-06-30 | Technical Auditor] The module-knowledge v1.0 (BA seeded) classified tt_parallel_groups as "DDL-backed" and tt_parallel_group_activity as "migration-only". Both turned out to have NO migration anywhere in the codebase — confirmed by exhaustive grep across all 49 tt_ migrations. This is DAT-TT-001 (P0). Knowledge file snapshots about migration status must always be verified with `find database/migrations -name "*.php" | xargs grep -l "<table_name>"` before trusting them.
- [2026-06-30 | Technical Auditor] API route group (routes/api.php) is loaded by mapApiRoutes() with ONLY `'api'` middleware — no tenancy stack. This is a recurring pattern across modules (also confirmed in TTF: SEC-TTF-004). For any module with an api.php, always check mapApiRoutes() in the module RSP for InitializeTenancyByDomain before clearing Layer 6.
- [2026-06-30 | Technical Auditor] GenerateTimetableJob has tries=1, timeout=600 — BUT no tenancy initialization. The earlier shell scan `grep -ci 'tenan|initialize|Tenant::'` returned 1 match, which led to tentative "tenancy=1" reading. That 1 match was a false positive (likely from a comment or import alias). Always read the full handle() method before marking a job as tenancy-safe.
- [2026-06-30 | Technical Auditor] STT has ZERO ->enum() calls in its 49 migrations — one of only a few modules to be completely clean on D29. The platform baseline is ~476 ENUMs. STT's constraint/strategy tables instead use string status columns — good pattern to follow.
- [2026-06-30 | Technical Auditor] TimetableCell, Activity, Timetable in STT are backward-compat alias classes extending TTF counterparts. Any audit finding on these must be traced to the actual TTF model, not the STT alias. BUG-STT-11 (wrong generationStrategy() relationship) — if Timetable.php is `class Timetable extends \Modules\TimetableFoundation\Models\Timetable {}`, the relationship bug is in the TTF model, not the STT alias.

---

## Pending Next Steps (Updated 2026-06-30 — Mode X Audit)

**New P0 (confirmed 2026-06-30 audit — fix before any other work):**
1. **SEC-TT-004**: Add tenancy middleware stack to `mapApiRoutes()` in RouteServiceProvider.php
2. **DAT-TT-001**: Create two tenant migrations for `tt_parallel_groups` and `tt_parallel_group_activity` — see known-issues.md for column specs
3. **JOB-TT-001**: Register `QueueTenancyBootstrapper`; add explicit tenancy init in `GenerateTimetableJob::handle()`
4. **SEC-PLATFORM-003**: Add `EnsureTenantHasModule::class.':smart-timetable'` to both route groups in routes/web.php

**From BA v1.0 analysis — still open P0/P1:**
5. **BUG-STT-05**: Fix PrimeConstraintBridge — wire DB constraint records into PrimeSolver (BR-STT-006 PARTIAL)
6. **BUG-TT-004**: Add `generateForClassSection()` method to TimetableGenerationController
7. **DEAD-TT-004**: Convert closure route at web.php:52 to named controller method
8. **SEC-TT-005**: Standardize permission prefix in TtGenerationStrategyController (tenant.* vs smart-timetable.*)

**Quality sprint (P1/P2):**
9. Fix `Schema::getColumnListing()` in TimetableMenuController with hardcoded constant (PERF-TT-017)
10. Replace `AcademicTerm::all()` with scoped+cached query in ConstraintController x4 (PERF-TT-018)
11. Add `JSON_HEX_*` flags or `@json` to chart data in reports.blade.php (FE-TT-001)
12. Add boolean casts to 12 active models missing them (ORM-TT-002)
13. Audit and delete/migrate 21 phantom models (MIG-TT-002)
14. Build Timetable Approval UI — REQ-STT-011, BR-020 (MISSING)
15. Add pagination to AnalyticsController workload/room queries (PERF-TT-019)

**Test priority (P3):** GenerationPipelineTest, ConstraintManagerTest, TimetableStatusFlowTest, SubstitutionFlowTest, ApiEndpointAuthTest, TenantModuleMiddlewareTest — 10 new test files for 60% coverage target (30h)

**Total estimated remediation effort (Mode X updated):** ~175 hours (prior 159h + 4 new P0s + P1/P2 additions)

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read, 1,205 lines), V1 screen specs (7 files enumerated), filesystem verification (find + wc -l per component type), routes/web.php full read, migration files for tt_generation_strategies + tt_generation_runs read, SmartTimetableServiceProvider full read, TimetableFoundation routes grep confirming TtGenerationStrategyController cross-module registration. Key findings: FETSolver renamed PrimeSolver, 3 actual test files vs 7 V2-projected, 13 FormRequests vs 7 V2-claimed, policies in module ServiceProvider not central AppServiceProvider, standard-timetable route group empty, 28 STT-owned + 20 TTF-owned tt_* tables |
