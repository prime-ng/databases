# STT — Smart Timetable
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** STT | **Scope:** Tenant | **Table Prefix:** `tt_` (shared with TimetableFoundation)
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x + stancl/tenancy v3.9 + nwidart/laravel-modules v12

---

## 1. Executive Summary

The SmartTimetable module is Prime-AI's AI-assisted, constraint-based school scheduling engine. It automates the entire timetable lifecycle — from academic structure mapping and activity definition through FET-inspired CSP generation, post-generation analytics, manual refinement, and daily substitution management — eliminating 2–4 weeks of manual scheduling effort for Indian K-12 schools.

**Current overall completion: ~48% (Grade F — critical gaps in security, architecture, and test coverage)**

### 1.1 Key Statistics

| Item | Count |
|---|---|
| DDL Tables (tt_*) | 42 confirmed + ~4 migration-only tables |
| Controllers (web) | 19 (SmartTimetableController + 18 others including 7 new split controllers) |
| Controllers (API) | 1 (TimetableApiController) |
| Models | 62 (21 are phantom — no DDL backing) |
| Services (total) | ~22 files across root/Constraints/Generator/Solver/Storage sub-namespaces |
| Hard Constraint Classes | 24 (PHP strategy pattern) |
| Soft Constraint Classes | 62 (PHP strategy pattern) |
| FormRequests | 7 (11+ missing) |
| Policies | 2 (12 missing) |
| Views (Blade) | 50+ |
| Web Routes | ~55 registered (standard-timetable group empty) |
| API Routes | 16 (prefix `/api/v1/timetable`, auth:sanctum) |
| Tests | 7 files (Feature: 1, Unit: 6) — 0 currently passing per gap analysis |
| Seeders | 9 |

### 1.2 Scorecard

| Category | Score | Grade | V2 Target |
|---|---|---|---|
| DB Integrity | 70% | C | 90% |
| Route Integrity | 65% | D | 95% |
| Controller Audit | 40% | F | 85% |
| Model Audit | 75% | C | 95% |
| Service Audit | 70% | C | 90% |
| FormRequest Audit | 30% | F | 100% |
| Policy/Auth Audit | 35% | F | 95% |
| Security Audit | 45% | F | 95% |
| Performance Audit | 50% | D | 80% |
| Architecture | 45% | F | 85% |
| Test Coverage | 0% | F | 60% |
| **Overall** | **~48%** | **F** | **88%** |

---

## 2. Module Overview

### 2.1 Architecture Overview (FET-inspired Constraint Solver)

SmartTimetable uses a **FET-inspired Constraint Satisfaction Problem (CSP)** solver:

```
┌─────────────────────────────────────────────────────────────────┐
│  CONFIGURATION LAYER                                            │
│  tt_config · tt_generation_strategy · tt_timetable_type        │
│  tt_period_set · tt_school_days · tt_working_day               │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│  REQUIREMENT LAYER                                              │
│  tt_slot_requirement · tt_class_requirement_groups             │
│  tt_class_requirement_subgroups · tt_requirement_consolidation │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│  CONSTRAINT ENGINE                                              │
│  tt_constraint_category_scope · tt_constraint_type             │
│  tt_constraint · 24 Hard + 62 Soft PHP classes                 │
│  FETConstraintBridge (BUG-TT-002 broken)                       │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│  ACTIVITY PREPARATION LAYER                                     │
│  tt_activity · tt_sub_activity · tt_activity_teacher           │
│  tt_priority_config · ActivityScoreService (6-factor scoring)  │
│  tt_teacher_availability · tt_room_availability                │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│  GENERATION ENGINE (async Queue Job)                            │
│  FETSolver (backtracking+greedy, 50K iter, 25s timeout)        │
│  TabuSearchOptimizer · SimulatedAnnealingOptimizer             │
│  SolutionEvaluator · TimetableStorageService                   │
│  ResourceBookingService · ConflictDetectionService             │
└────────────────────┬────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────────┐
│  POST-GENERATION LAYER                                          │
│  tt_timetable_cell · tt_timetable_cell_teacher                 │
│  AnalyticsService · RefinementService · SubstitutionService    │
│  TimetableApiController (REST, Sanctum)                        │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Generation Pipeline (High Level FSM)

```
DRAFT ──[dispatch job]──► GENERATING ──[job complete]──► GENERATED
  ▲                                          │ [job fail]
  │                                          ▼
  └──────[admin revert]────────────────► DRAFT
                                    │
                               [admin approve]
                                    ▼
                                APPROVED ──[admin publish]──► PUBLISHED
                                                                   │
                               [new version published]             ▼
                                                             ARCHIVED
```

**Generation Sub-Pipeline (inside GenerateTimetableJob):**
1. Pre-generation validation (ValidationService)
2. Activity scoring (ActivityScoreService — 6 factors)
3. Room allocation pass (RoomAllocationPass)
4. Sub-activity split (SubActivityService)
5. FETSolver CSP backtracking (50K iter, 25s per-run timeout)
6. Post-solver optimization (TabuSearch or SimulatedAnnealing — configurable)
7. SolutionEvaluator (hard/soft violation counts, soft_score)
8. Atomic DB storage — TimetableStorageService (single transaction)
9. ResourceBookingService — tt_resource_booking records
10. ConflictDetectionService.detectFromGrid()
11. Update tt_generation_run.status → COMPLETED / FAILED

---

## 3. Stakeholders & Roles

| Stakeholder | Primary Actions | Min Permission |
|---|---|---|
| School Admin / Timetable Coordinator | Full lifecycle: configure, generate, approve, publish, substitute | `smart-timetable.manage` |
| Principal | Approve timetable, view analytics | `smart-timetable.approve` |
| Teacher | View own schedule (standard view + API), accept substitution | `smart-timetable.view` |
| Parent/Student | View published timetable (API/portal, read-only) | `smart-timetable.view.public` |
| System (Queue) | GenerateTimetableJob, analytics computation, pattern learning | Internal |

---

## 4. Functional Requirements

### FR-STT-01: Foundation Masters Setup
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-01.1 | CRUD for Shift (code, name, start_time, end_time, ordinal) | ✅ |
| FR-STT-01.2 | CRUD for DayType (STUDY/HOLIDAY/EXAM/SPECIAL/PTM_DAY/SPORTS_DAY/ANNUAL_DAY) | ✅ |
| FR-STT-01.3 | CRUD for PeriodType (THEORY/PRACTICAL/BREAK/LUNCH/ASSEMBLY/EXAM/FREE, is_schedulable, counts_as_teaching, is_break flags) | ✅ |
| FR-STT-01.4 | CRUD for SchoolDays (day_of_week, ordinal, is_school_day) | ✅ |
| FR-STT-01.5 | CRUD for WorkingDay calendar (date-level day type assignments) | ✅ |
| FR-STT-01.6 | CRUD for ClassWorkingDay junction (per-class overrides, exam/PTM/half-day flags) | ✅ |
| FR-STT-01.7 | CRUD for PeriodSet + PeriodSetPeriod (start/end_time per period, duration_minutes generated column) | ✅ |
| FR-STT-01.8 | CRUD for TimetableType (shift, effective dates, non-overlapping enforcement) | ✅ |
| FR-STT-01.9 | CRUD for ClassTimetableType junction (period set assignment per class/section/term) | ✅ |
| FR-STT-01.10 | CRUD for TeacherAssignmentRole (PRIMARY/ASSISTANT/CO_TEACHER/SUBSTITUTE/TRAINEE, workload_factor) | ✅ |
| FR-STT-01.11 | CRUD for TtConfig (14 system keys; tenant can modify non-locked keys) | ✅ |
| FR-STT-01.12 | Soft delete + toggle-status on all foundation entities | ✅ |

**Business Rule:** A school must have ≥1 active Shift, ≥5 active school days, ≥1 PeriodSet with ≥6 periods, and ≥1 TimetableType before generation is allowed (BR-STT-001).

---

### FR-STT-02: Timetable Requirement Definition
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-02.1 | CRUD for ClassRequirementGroups (class+section+subject+study_format combination) | ✅ |
| FR-STT-02.2 | CRUD for ClassRequirementSubgroups (shared across sections/classes flag) | ✅ |
| FR-STT-02.3 | CRUD for RequirementConsolidation — combined record per academic term with full scheduling parameters (required_weekly_periods, min/max per day, consecutive rules, room type, spread_evenly) | ✅ |
| FR-STT-02.4 | CRUD for SlotRequirement (weekly slot budget per class/section) | ✅ |
| FR-STT-02.5 | generateRequirements() — auto-generate consolidation from groups/subgroups | ✅ |
| FR-STT-02.6 | updatePeriods() — recalculate slot budgets after term change | ✅ |
| FR-STT-02.7 | CHECK constraint: RequirementConsolidation.class_requirement_group_id XOR class_requirement_subgroup_id (one must be NULL) | ✅ |

---

### FR-STT-03: Constraint Engine
**Status:** 🟡 Partial (classes exist; FETConstraintBridge broken — BUG-TT-002; createConstraintManager() returns empty manager — GAP-CTRL-010)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-03.1 | CRUD for ConstraintCategoryScope (CATEGORY and SCOPE type records, seeded) | ✅ |
| FR-STT-03.2 | CRUD for ConstraintType (system-defined; school can enable/disable; stores param_schema JSON) | ✅ |
| FR-STT-03.3 | CRUD for Constraint instances — category-specific forms rendered from param_schema | ✅ |
| FR-STT-03.4 | Constraint scope support: GLOBAL / TEACHER / ROOM / ACTIVITY / CLASS / CLASS+SECTION / subject variants | ✅ |
| FR-STT-03.5 | is_hard flag per constraint instance overrides constraint_type.is_hard_constraint (per-instance escalation) | ✅ |
| FR-STT-03.6 | 24 hard constraint PHP classes (Strategy pattern, implement TimetableConstraint) | ✅ |
| FR-STT-03.7 | 62 soft constraint PHP classes (teacher/class/room/inter-activity/global scopes) | ✅ |
| FR-STT-03.8 | FETConstraintBridge — maps DB constraint records to PHP constraint objects for FETSolver | ❌ BUG-TT-002 |
| FR-STT-03.9 | createConstraintManager() must load all active constraints from DB into ConstraintManager | ❌ GAP-CTRL-010: all commented out |
| FR-STT-03.10 | ConstraintManager dashboard view — constraints grouped by category with enable/disable toggle | ✅ |
| FR-STT-03.11 | Effective date range + applicable_days_json per constraint | ✅ |
| FR-STT-03.12 | FormRequests for all constraint CRUD operations (StoreConstraintRequest, UpdateConstraintRequest exist; Category/Scope/Type controllers missing) | 🟡 |

**CRITICAL BUGS:**
- **BUG-TT-002:** FETConstraintBridge context broken — PHP constraint classes not wired to FET solver. Generation runs with zero constraints enforced (except those hardcoded inline in FETSolver).
- **GAP-CTRL-010:** `createConstraintManager()` in SmartTimetableController has all constraint loading commented out at lines 277–317.

---

### FR-STT-04: Teacher & Room Availability
**Status:** ✅ Implemented (with minor gaps)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-04.1 | generateTeacherAvailability() — auto-generate from RequirementConsolidation | ✅ |
| FR-STT-04.2 | TeacherAvailability record: full_time, preferred_shift, can_sub, certified_lab, max/min weekly periods, proficiency%, experience, competency_level, scarcity_index, allocation_strictness (Hard/Medium/Soft) | ✅ |
| FR-STT-04.3 | Generated columns: available_for_full_timetable_duration (STORED), no_of_days_not_available (STORED) | ✅ |
| FR-STT-04.4 | TeacherAvailabilityDetail grid: per (teacher × day × period) with status = Available/Unavailable/Assigned/Free Period | ✅ |
| FR-STT-04.5 | TeacherUnavailable CRUD (recurring + date-range, day_of_week + period_no) — backed by tt_constraint record | ✅ |
| FR-STT-04.6 | RoomAvailability and RoomAvailabilityDetail grid (same structure as teacher side) | ✅ |
| FR-STT-04.7 | RoomUnavailable CRUD | ✅ |
| FR-STT-04.8 | FormRequests for TeacherUnavailable store/update | ❌ GAP-FR-008 |
| FR-STT-04.9 | FormRequests for RoomUnavailable store/update | ❌ GAP-FR-009 |

---

### FR-STT-05: Activity Management
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-05.1 | CRUD for Activities (class+section+subject+study_format+weekly_periods combination) | ✅ |
| FR-STT-05.2 | generateActivities() — auto-generate from RequirementConsolidation per term | ✅ |
| FR-STT-05.3 | generateAllActivities() — batch generate for all class-sections | ✅ |
| FR-STT-05.4 | getBatchGenerationProgress() — async polling endpoint | ✅ |
| FR-STT-05.5 | Sub-activity support (have_sub_activity=1): tt_sub_activity records with same_day_as_parent, consecutive_with_previous | ✅ |
| FR-STT-05.6 | Teacher-to-activity mapping via tt_activity_teacher (assignment_role_id, is_required, ordinal) | ✅ |
| FR-STT-05.7 | Activity scoring (ActivityScoreService): scarcity_index + load_ratio + TAR + rigidity + resource_scarcity + difficulty = difficulty_score | ✅ |
| FR-STT-05.8 | Priority config (tt_priority_config): per-activity weights for scoring factors | ✅ |
| FR-STT-05.9 | total_periods = duration_periods × weekly_periods (STORED generated column) | ✅ |
| FR-STT-05.10 | Activity status ENUM: DRAFT / ACTIVE / LOCKED / ARCHIVED | ✅ |
| FR-STT-05.11 | Room preference fields: requires_room, required_room_type_id, required_room_id, preferred_room_type_id, preferred_room_ids | ✅ |

---

### FR-STT-06: Parallel Period Group Management
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-06.1 | CRUD for ParallelGroup (groups of activities that must run simultaneously — electives, hobbies) | ✅ |
| FR-STT-06.2 | Add/remove activities to group via ParallelGroupController | ✅ |
| FR-STT-06.3 | Auto-detect parallel groups from RequirementConsolidation | ✅ |
| FR-STT-06.4 | Set anchor activity in group (setAnchor endpoint) | ✅ |
| FR-STT-06.5 | ParallelPeriodConstraint (hard): first activity placed defines anchor (day_of_week, period_ord); all group members forced to anchor slot | ✅ |
| FR-STT-06.6 | If anchor placement fails, entire group retried in next available slot | ✅ |

---

### FR-STT-07: Generation Strategy Configuration
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-07.1 | CRUD for TtGenerationStrategy (algorithm_type, max_recursive_depth, max_placement_attempts, tabu_size, cooling_rate, population_size, generations, timeout_seconds, activity_sorting_method) | ✅ |
| FR-STT-07.2 | algorithm_type ENUM: RECURSIVE / GENETIC / SIMULATED_ANNEALING / TABU_SEARCH / HYBRID | ✅ |
| FR-STT-07.3 | Activate/deactivate strategy (one default active at a time) | 🟡 inline validation (GAP-FR-011) |
| FR-STT-07.4 | Default strategy auto-selected if none specified at generation time | ✅ |

---

### FR-STT-08: Timetable Creation & Pre-Generation Validation
**Status:** 🟡 Partial

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-08.1 | Create Timetable record (code, name, academic_term_id, timetable_type_id, period_set_id, effective_from/to, generation_method) | ✅ |
| FR-STT-08.2 | storeTimetable() must use FormRequest (not 312-line inline validation) | ❌ GAP-FR-001 |
| FR-STT-08.3 | Pre-generation validation via ValidationService — checks: activities exist, teacher availability set, constraints valid, rooms available | ✅ |
| FR-STT-08.4 | Validation result view (tabbed: Statistics / Teachers / Rooms / Activities / Constraints / Alerts) | ✅ |
| FR-STT-08.5 | Validation errors returned as structured JSON per category | ✅ |
| FR-STT-08.6 | Timetable initial status = DRAFT | ✅ |

---

### FR-STT-09: Timetable Generation (FET Solver Pipeline)
**Status:** 🟡 Partial (~70% — solver runs but constraints not wired)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-09.1 | POST /smart-timetable/generate/generate-fet dispatches GenerateTimetableJob to queue | ✅ |
| FR-STT-09.2 | generateWithFET() must use FormRequest (not ~900-line inline validation) | ❌ GAP-FR-002 |
| FR-STT-09.3 | FETSolver: activity-first placement — score+sort activities; hardest (fewest eligible teachers) placed first | ✅ |
| FR-STT-09.4 | FETSolver checks per placement: teacher conflict, student group conflict, room availability, teacher unavailability, max daily load, parallel group anchor | ✅ (inline only; DB constraints not wired) |
| FR-STT-09.5 | FETSolver: 50,000 max iterations, 25s timeout, configurable via strategy | ✅ |
| FR-STT-09.6 | TabuSearchOptimizer: within-class swaps, hard violations ×1000 weight vs soft score | ✅ |
| FR-STT-09.7 | SimulatedAnnealingOptimizer: temperature-based acceptance, configurable cooling_rate | ✅ |
| FR-STT-09.8 | SolutionEvaluator: compute hard_violations, soft_violations, soft_score | ✅ |
| FR-STT-09.9 | TimetableStorageService: atomic transaction storage of all cells + cell_teachers | ✅ |
| FR-STT-09.10 | ResourceBookingService: create tt_resource_booking for ROOM and TEACHER resources | ✅ |
| FR-STT-09.11 | ConflictDetectionService.detectFromGrid() after storage | ✅ |
| FR-STT-09.12 | Per-class-section generation: GET /smart-timetable/generate/{class_id}/{section_id}/generate | 🟡 route exists; controller method missing (GAP-RT-002) |
| FR-STT-09.13 | DB constraints wired to FETSolver via FETConstraintBridge | ❌ BUG-TT-002 |
| FR-STT-09.14 | Generation must run async via queue — NOT in web request thread | 🟡 Job exists but sync path also present (GAP-ARCH-004) |
| FR-STT-09.15 | Rate limiting on generation endpoint (CPU-intensive) | ❌ SEC-TT-007 |

---

### FR-STT-10: Generation Monitoring
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-10.1 | tt_generation_run per run: status QUEUED/RUNNING/COMPLETED/FAILED/CANCELLED, activities_total/placed/failed, hard/soft violations, soft_score, error_message, stats_json | ✅ |
| FR-STT-10.2 | GET /generation-status/{run} — JSON status polling endpoint | ✅ |
| FR-STT-10.3 | generation/progress.blade.php — polls every 3 seconds, shows live placement counts | ✅ |
| FR-STT-10.4 | Job failure: run status = FAILED, error_message set, timetable reverts to DRAFT | ✅ |
| FR-STT-10.5 | Job timeout (600s Laravel $timeout, $tries=1): status = FAILED | ✅ |
| FR-STT-10.6 | Cancellation: QUEUED/RUNNING job → CANCELLED status | 🟡 model support exists; UI not confirmed |

---

### FR-STT-11: Timetable Approval Workflow
**Status:** 🟡 Partial (model-level status transitions done; approval UI incomplete)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-11.1 | GENERATED timetable requires explicit admin action to move to APPROVED | 🟡 |
| FR-STT-11.2 | Approval triggers AnalyticsService re-computation | 🟡 |
| FR-STT-11.3 | Preview view: grid + activities summary + health report + conflicts + placement diagnostics | ✅ |
| FR-STT-11.4 | If hard constraint violations exist: warn approver; admin-only override with reason | ❌ UI not built |
| FR-STT-11.5 | Approval/reject UI screens (buttons, confirmation modal) | ❌ not built |
| FR-STT-11.6 | Gate::authorize('smart-timetable.approve') on approval action | ❌ GAP-POL-003 |

---

### FR-STT-12: Timetable Publishing
**Status:** 🟡 Partial (status field exists; publish action not fully wired)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-12.1 | TimetablePublishController: APPROVED → PUBLISHED, record published_at + published_by | 🟡 controller exists; route wiring not confirmed |
| FR-STT-12.2 | PUBLISHED timetable visible to teachers/students via Standard views and REST API | 🟡 |
| FR-STT-12.3 | New version publication: old timetable → ARCHIVED, linked via parent_timetable_id | 🟡 |
| FR-STT-12.4 | Once PUBLISHED: cells cannot be swapped/moved; only substitutions allowed | 🟡 enforcement needs verification |
| FR-STT-12.5 | Refinement on PUBLISHED requires revert to APPROVED first | 🟡 |
| FR-STT-12.6 | TimetableExportController: CSV export of published timetable | 🟡 controller exists |

---

### FR-STT-13: Post-Generation Analytics
**Status:** ✅ Implemented

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-13.1 | computeTeacherWorkload() → tt_teacher_workload (utilization%, gap_periods, consecutive_max, daily_distribution_json, subjects_json, classes_json) | ✅ |
| FR-STT-13.2 | computeRoomUtilization() → tt_room_utilizations | ✅ |
| FR-STT-13.3 | computeConstraintViolations() from latest tt_conflict_detection record | ✅ |
| FR-STT-13.4 | takeDailySnapshot() → tt_analytics_daily_snapshots (upsert by date) | ✅ |
| FR-STT-13.5 | Auto-lazy-compute: if analytics tables empty on first GET, trigger computation | ✅ |
| FR-STT-13.6 | Analytics dashboard (index), workload, utilization, violations, distribution views | ✅ |
| FR-STT-13.7 | Class/teacher/room report views sharing _grid.blade.php partial (days × periods) | ✅ |
| FR-STT-13.8 | CSV export via fputcsv() → php://temp for workload, utilization, distribution | ✅ |
| FR-STT-13.9 | AnalyticsController Gate::authorize calls | ❌ GAP-POL-003 |

---

### FR-STT-14: Manual Refinement (Swap / Move / Lock)
**Status:** ✅ Implemented (with missing FormRequests and authorization)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-14.1 | swapCells(): exchange two cells' activities + rooms; full impact analysis beforehand | ✅ |
| FR-STT-14.2 | moveCell(): move activity to empty target slot | ✅ |
| FR-STT-14.3 | lockCell() / unlockCell() / lockAll() / unlockAll() | ✅ |
| FR-STT-14.4 | analyseSwapImpact() — JSON endpoint called via fetch() before swap modal | ✅ |
| FR-STT-14.5 | batchSwap() and rollbackBatch() | ✅ |
| FR-STT-14.6 | Two-click cell selection UI pattern (source → trigger impact analysis → modal) | ✅ |
| FR-STT-14.7 | All changes recorded in tt_change_log (change_type, old/new_values_json, reason) | ✅ |
| FR-STT-14.8 | Conflict resolution sessions: openResolutionSession(), applyResolutionOption(), escalateSession() | ✅ (stub) |
| FR-STT-14.9 | revalidate() after manual changes: ConflictDetectionService.detectFromCells() + AnalyticsService.computeConstraintViolations() | ✅ |
| FR-STT-14.10 | FormRequests for all RefinementController methods (swap, move, toggleLock) | ❌ GAP-FR-003 |
| FR-STT-14.11 | RefinementController Gate::authorize calls | ❌ GAP-POL-003 |
| FR-STT-14.12 | viewAndRefinement() must paginate cells — NOT load ALL cells globally | ❌ PERF-TT-001 / BUG-TT-011 |

---

### FR-STT-15: Substitution Management
**Status:** ✅ Implemented (with missing FormRequests and authorization)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-15.1 | POST /substitution/absence: create tt_teacher_absence (PENDING) | ✅ |
| FR-STT-15.2 | Absence approval → auto-generate substitute recommendations per affected cell | ✅ |
| FR-STT-15.3 | Candidate scoring: Subject match (40 pts) + Pattern × confidence (25 pts) + Day availability (20 pts) + Workload balance (15 pts) | ✅ |
| FR-STT-15.4 | GET /substitution/candidates/{cellId}/{date} — ranked candidates | ✅ |
| FR-STT-15.5 | Manual assign (POST /substitution/assign) and auto-assign (POST /substitution/auto-assign) | ✅ |
| FR-STT-15.6 | Assignment: new tt_timetable_cell_teacher row (is_substitute=1); original teacher row preserved | ✅ |
| FR-STT-15.7 | completeSubstitution() → update tt_substitution_patterns (running exponential average of teacher+day+subject success_rate) | ✅ |
| FR-STT-15.8 | GET /substitution/history/{teacherId} — substitution history | ✅ |
| FR-STT-15.9 | Substitution dashboard: today's absences, pending assignments, today's substitutions | ✅ |
| FR-STT-15.10 | FormRequests for all SubstitutionController methods | ❌ GAP-FR-004 |
| FR-STT-15.11 | SubstitutionController Gate::authorize calls | ❌ GAP-POL-003 |
| FR-STT-15.12 | Notification to substitute teacher on assignment (via Notification module) | 🟡 not confirmed |

---

### FR-STT-16: Standard Timetable View
**Status:** ❌ Non-functional (empty route group — GAP-RT-003)

| Sub-ID | Requirement | Status |
|---|---|---|
| FR-STT-16.1 | Class timetable view: grid of published timetable for a class/section | ❌ |
| FR-STT-16.2 | Teacher timetable view: published timetable filtered by teacher | ❌ |
| FR-STT-16.3 | Room timetable view: published timetable filtered by room | ❌ |
| FR-STT-16.4 | StandardTimetableController: hub + class + teacher + room views | ❌ route group empty (GAP-RT-003) |
| FR-STT-16.5 | Reuse AnalyticsService::getClassReport/getTeacherReport/getRoomReport + _grid partial | 📐 Proposed |
| FR-STT-16.6 | Only PUBLISHED timetables visible in standard views | 📐 |

---

### FR-STT-17: REST API for External Integration
**Status:** 🟡 Partial (endpoints exist; per-endpoint authorization missing)

| Method | URI | Description | Status |
|---|---|---|---|
| GET | `/api/v1/timetable/{id}` | Full timetable JSON (grid by day→period) | ✅ |
| GET | `/api/v1/timetable/{id}/class/{classId}` | Class-filtered cells | ✅ |
| GET | `/api/v1/timetable/{id}/teacher/{teacherId}` | Teacher-filtered cells | ✅ |
| GET | `/api/v1/timetable/{id}/room/{roomId}` | Room-filtered cells | ✅ |
| GET | `/api/v1/timetable/{id}/day/{dayOfWeek}` | Day-filtered cells | ✅ |
| GET | `/api/v1/timetable/{id}/period/{periodOrd}` | Period-filtered cells | ✅ |
| GET | `/api/v1/timetable/{id}/activities` | All activities | ✅ |
| GET | `/api/v1/timetable/{id}/teachers` | All teachers + schedules | ✅ |
| GET | `/api/v1/timetable/{id}/rooms` | All rooms + schedules | ✅ |
| GET | `/api/v1/timetable/{id}/conflicts` | Active conflicts | ✅ |
| GET | `/api/v1/timetable/{id}/stats` | Quality stats | ✅ |
| GET | `/api/v1/timetable/{id}/substitutions` | Active substitutions | ✅ |
| GET | `/api/v1/timetable/{id}/export/json` | Full JSON export | ✅ |
| GET | `/api/v1/timetable/{id}/export/ical` | iCal export | 🟡 scaffolded only |
| GET | `/api/v1/timetable/generation-run/{runId}/status` | Generation run status | ✅ |
| GET | `/api/v1/timetable/latest` | Latest PUBLISHED timetable | ✅ |

**API Issues:**
- Response format: `{ "success": true, "data": {...} }` / `{ "success": false, "message": "..." }` ✅
- auth:sanctum on all endpoints ✅
- Per-endpoint Gate::authorize calls | ❌ GAP-POL-004
- Rate limiting on TimetableApiController | ❌ SEC-TT-009
- Cell update inline validation in TimetableApiController | ❌ GAP-FR-010

---

## 5. Data Model

### 5.1 Configuration Tables

| Table | Purpose | Key Fields |
|---|---|---|
| `tt_config` | 14 system config keys | key, value, value_type, tenant_can_modify |
| `tt_generation_strategy` | Solver algorithm parameters | algorithm_type ENUM, max_recursive_depth, tabu_size, cooling_rate, timeout_seconds |

### 5.2 Foundation Master Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `tt_shift` | School shift definitions | code, name, default_start_time, default_end_time |
| `tt_day_type` | Day classification | code, is_working_day, reduced_periods |
| `tt_period_type` | Period classification | code, is_schedulable, counts_as_teaching, is_break |
| `tt_teacher_assignment_role` | Teacher role in activity | code, workload_factor, allows_overlap |
| `tt_school_days` | Named school days | day_of_week (1–7), is_school_day |
| `tt_working_day` | Date-level calendar | date, day_type1-4_id, is_school_day |
| `tt_class_working_day_jnt` | Per-class day overrides | date, class_id, section_id, is_exam_day, is_ptm_day |
| `tt_period_set` | Period set template | total/teaching/exam/free periods, day_start/end_time |
| `tt_period_set_period_jnt` | Individual periods | period_ord, period_type_id, start_time, end_time, duration_minutes (GENERATED) |
| `tt_timetable_type` | Timetable type per shift | shift_id, effective_from/to, has_exam, has_teaching |
| `tt_class_timetable_type_jnt` | Assignment of period set to class | academic_term_id, class_id, section_id, period_set_id |

### 5.3 Requirement Tables

| Table | Purpose | Key Constraint |
|---|---|---|
| `tt_slot_requirement` | Weekly slot budget | Per class/section/term |
| `tt_class_requirement_groups` | Subject-class grouping | class_id + section_id + subject + study_format |
| `tt_class_requirement_subgroups` | Shared-group variants | is_shared_across_sections/classes flags |
| `tt_requirement_consolidation` | Master requirement record | CHECK: group_id XOR subgroup_id; full scheduling params |

### 5.4 Constraint Engine Tables

| Table | Purpose | Notes |
|---|---|---|
| `tt_constraint_category_scope` | Category + Scope master | type ENUM('CATEGORY','SCOPE') |
| `tt_constraint_type` | Constraint type definitions | param_schema JSON for dynamic forms |
| `tt_constraint` | Constraint instances | is_hard overrides type default; weight 1–100 |
| `tt_teacher_unavailable` | Teacher unavailability | backed by tt_constraint record |
| `tt_room_unavailable` | Room unavailability | backed by tt_constraint record |

### 5.5 Availability Tables

| Table | Purpose | Generated Columns |
|---|---|---|
| `tt_teacher_availability` | Teacher aggregate availability | available_for_full_timetable_duration, no_of_days_not_available (both STORED) |
| `tt_teacher_availability_detail` | Per day+period availability | availability_for_period ENUM(Available/Unavailable/Assigned/Free Period) |
| `tt_room_availability` | Room aggregate availability | available_for_full_timetable_duration |
| `tt_room_availability_detail` | Per day+period room availability | availability_for_period ENUM(Available/Unavailable/Assigned) |

### 5.6 Activity Tables

| Table | Purpose | Notes |
|---|---|---|
| `tt_activity` | Core scheduling entity | total_periods = duration_periods × weekly_periods (STORED); status ENUM |
| `tt_sub_activity` | Multi-period activity parts | same_day_as_parent, consecutive_with_previous |
| `tt_activity_teacher` | Teacher-activity mapping | assignment_role_id, is_required, ordinal |
| `tt_activity_priority` | Priority score record | priority_score 0.00–100.00 |
| `tt_priority_config` | Scoring factor weights | scarcity, load_ratio, TAR, rigidity, resource_scarcity, difficulty |
| `tt_parallel_group` | Parallel activity groups | anchor activity + member activities |
| `tt_parallel_group_activity` | Pivot: group ↔ activity | (migration-only; not in canonical DDL — GAP-DB-001) |

### 5.7 Core Timetable Tables

| Table | Purpose | Key Constraints |
|---|---|---|
| `tt_timetable` | Root timetable document | status ENUM(DRAFT/GENERATING/GENERATED/PUBLISHED/ARCHIVED), parent_timetable_id for versioning |
| `tt_generation_run` | Per-run metadata | UNIQUE(timetable_id, run_number); status ENUM |
| `tt_timetable_cell` | Grid cells | UNIQUE(timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id); is_locked |
| `tt_timetable_cell_teacher` | Teachers per cell | UNIQUE(cell_id, teacher_id); is_substitute flag |
| `tt_conflict_detection` | Conflict scan results | detection_type, conflicts_json, resolution_suggestions_json |
| `tt_constraint_violation` | Per-constraint violations | violation_type HARD/SOFT |
| `tt_resource_booking` | Resource reservations | resource_type ENUM, status ENUM |
| `tt_change_log` | Audit trail | change_type ENUM; old/new_values_json |

### 5.8 Analytics Tables

| Table | Purpose |
|---|---|
| `tt_teacher_workload` | Computed workload per teacher per timetable (UNIQUE: teacher+session+timetable) |
| `tt_room_utilizations` | Computed room utilization per timetable |
| `tt_analytics_daily_snapshots` | Daily snapshot (upsert by date) — migration-only (GAP-DB-001) |

### 5.9 Substitution Tables

| Table | Purpose |
|---|---|
| `tt_teacher_absence` | Absence records (status: PENDING/APPROVED/REJECTED/CANCELLED) |
| `tt_substitution_log` | Assignment records (status: ASSIGNED/COMPLETED/CANCELLED) |
| `tt_substitution_patterns` | ML pattern: teacher+day+subject success_rate (running avg) — migration-only (GAP-DB-001) |
| `tt_substitution_recommendations` | Auto-generated substitute suggestions per cell — migration-only (GAP-DB-001) |

### 5.10 Phantom Models (No DDL — Must Clean Up)

21 models exist in code with no backing DDL tables (GAP-DB-003 / GAP-MDL-001). These must either have DDL created or be removed:

`ApprovalDecision`, `ApprovalLevel`, `ApprovalNotification`, `ApprovalRequest`, `ApprovalWorkflow`, `BatchOperation`, `BatchOperationItem`, `EscalationLog`, `EscalationRule`, `FeatureImportance`, `MlModel`, `OptimizationIteration`, `OptimizationMove`, `OptimizationRun`, `PredictionLog`, `RevalidationSchedule`, `RevalidationTrigger`, `TrainingData`, `VersionComparison`, `VersionComparisonDetail`, `WhatIfScenario`

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (registered in `tenant.php`, prefix `smart-timetable`)

| Group | Route Name Prefix | Status |
|---|---|---|
| Foundation masters (shift, day, period, etc.) | `smart-timetable.*` | ✅ |
| Constraint management | `smart-timetable.constraint*` | ✅ |
| Activity management | `smart-timetable.activity.*` | ✅ |
| Parallel groups | `smart-timetable.parallel-group.*` | ✅ (web.php) |
| Generation | `smart-timetable-management.*` | 🟡 `generateForClassSection` missing (GAP-RT-002) |
| Analytics | `smart-timetable.analytics.*` | ✅ (no {timetable} param — GAP-RT-004) |
| Refinement | `smart-timetable.refinement.*` | ✅ (no {timetable} param — GAP-RT-004) |
| Substitution | `smart-timetable.substitution.*` | ✅ |
| Standard timetable | `standard-timetable.*` | ❌ Empty group (GAP-RT-003) |
| REST API | `/api/v1/timetable/*` | ✅ (16 endpoints, auth:sanctum) |

**CRITICAL MISSING:** `EnsureTenantHasModule` middleware NOT applied to any SmartTimetable route group (SEC-TT-001).

### 6.2 New Controllers (Split from God Controller — 📐 Proposed)

| Proposed Controller | Responsibility |
|---|---|
| `TimetableGenerationController` | generateWithFET, generateForClassSection, generation status |
| `TimetableConfigController` | config keys, generation strategy, timetable CRUD |
| `TimetableViewerController` | viewAndRefinement, preview (paginated) |
| `TimetableMasterController` | storeTimetable, timetableOperation |
| `TimetableMenuController` | Navigation/menu methods |

Note: `TimetableGenerationController`, `TimetableMenuController`, `TimetablePageController`, `TimetablePreviewController`, `TimetablePublishController` already exist as split controllers — verify if they are wired to routes.

---

## 7. UI Screens

### 7.1 Navigation Menu Structure (10 Groups)

| # | Menu Group | Screens |
|---|---|---|
| 1 | Pre-Requisites Setup | Buildings, Room Types, Rooms, Teacher Profiles, Classes/Sections, Subjects/Study Formats |
| 2 | Timetable Configuration | TT Config (14 keys), Academic Terms, Generation Strategy |
| 3 | Timetable Masters | Shift, DayType, PeriodType, TeacherRoles, SchoolDays, WorkingDay, ClassWorkingDay, PeriodSet, TimetableType, ClassTimetable |
| 4 | Timetable Requirement | SlotRequirement, ClassRequirementGroups, Subgroups, RequirementConsolidation |
| 5 | Constraint Engine | Categories/Scopes, ConstraintTypes, Constraints (per-category form), TeacherUnavailability, RoomUnavailability |
| 6 | Resource Availability | TeacherAvailability, AvailabilityLogs, RoomAvailability |
| 7 | Timetable Preparation | Activities (CRUD + batch gen), PriorityConfig, TeacherMapping |
| 8 | View & Refinement | Generation Status (polling), Preview, Manual Refinement Grid |
| 9 | Reports & Logs | Analytics Dashboard, Workload, Utilization, Violations, Distribution, Class/Teacher/Room Reports |
| 10 | Substitute Management | Absence Recording, Candidate Selection, Substitution Dashboard |

### 7.2 Key Screen Behaviors

| Screen | Behavior | Status |
|---|---|---|
| Constraint form | Dynamically rendered from constraint_type.param_schema JSON | ✅ |
| Activity batch generation | Progress bar with 3s polling | ✅ |
| Generation status | Auto-polls GET /generation-status/{run} every 3s | ✅ |
| Validation view | Tabbed layout: Statistics / Teachers / Rooms / Activities / Constraints / Alerts | ✅ |
| Refinement grid | Two-click selection: source → impact analysis JSON fetch → swap modal | ✅ |
| Analytics dashboard | Auto-lazy-compute if tables empty | ✅ |
| Standard timetable | Class / Teacher / Room views using _grid partial | ❌ not built (GAP-RT-003) |

---

## 8. Business Rules

### 8.1 Foundation Rules

| Rule | Description |
|---|---|
| BR-STT-001 | Generation prerequisite: ≥1 Shift, ≥5 school days, ≥1 PeriodSet with ≥6 periods, ≥1 TimetableType |
| BR-STT-002 | tt_period_set_period_jnt.duration_minutes is a STORED generated column — cannot be manually set |
| BR-STT-003 | TimetableType effective dates must not overlap for the same shift |
| BR-STT-004 | ClassWorkingDay overrides global calendar; exam days reduce teaching slots for that class |

### 8.2 Constraint Rules

| Rule | Description |
|---|---|
| BR-STT-005 | Hard constraints are NEVER violated. If satisfaction impossible → FAILED status |
| BR-STT-006 | Constraint scope hierarchy: GLOBAL > CLASS > TEACHER > ROOM > ACTIVITY |
| BR-STT-007 | tt_constraint.is_hard overrides tt_constraint_type.is_hard_constraint (per-instance escalation) |
| BR-STT-008 | tt_teacher_unavailable and tt_room_unavailable are UI-layer records backed by tt_constraint records |

### 8.3 Activity Rules

| Rule | Description |
|---|---|
| BR-STT-009 | Activity must reference class_group_id OR class_subgroup_id — never both (CHECK constraint) |
| BR-STT-010 | tt_activity.total_periods = duration_periods × weekly_periods (STORED generated column) |
| BR-STT-011 | have_sub_activity=1 activities must have ≥1 tt_sub_activity child records |
| BR-STT-012 | Parallel group: first activity placed defines anchor (day_of_week, period_ord); all members forced to anchor |

### 8.4 Generation Rules

| Rule | Description |
|---|---|
| BR-STT-013 | Activity placement order: highest difficulty_score first (LESS_TEACHER_FIRST strategy) |
| BR-STT-014 | FETSolver max: 50K iterations, 25s timeout (configurable); partial solutions accepted and flagged |
| BR-STT-015 | New tt_generation_run per run; multiple runs per tt_timetable allowed (run_number increments) |
| BR-STT-016 | Generation MUST be async via GenerateTimetableJob; web thread must not block |

### 8.5 Approval & Publishing Rules

| Rule | Description |
|---|---|
| BR-STT-017 | Status flow: DRAFT → GENERATING → GENERATED → APPROVED → PUBLISHED; revert GENERATED→DRAFT allowed |
| BR-STT-018 | Only PUBLISHED timetable visible to teachers/students via Standard Views and REST API |
| BR-STT-019 | PUBLISHED timetable: swap/move cells disabled; only substitutions allowed; refinement requires APPROVED revert |

### 8.6 Substitution Rules

| Rule | Description |
|---|---|
| BR-STT-020 | Substitute: tt_timetable_cell_teacher row with is_substitute=1; original teacher row preserved |
| BR-STT-021 | Scoring: Subject match (40 pts) + Pattern × confidence (25 pts) + Day availability (20 pts) + Workload balance (15 pts) |
| BR-STT-022 | Pattern learning triggers ONLY on completeSubstitution() — running exponential average |

---

## 9. Workflows / Generation Pipeline FSM

### 9.1 Full Generation Lifecycle

```
[Admin: Create Timetable] ─────────────────────► DRAFT
       │
       ▼ [Admin: Validate]
ValidationService ──── FAIL ──► Show validation report (tabbed view)
       │ PASS
       ▼ [Admin: Generate]
POST /generate-fet ──► Dispatch GenerateTimetableJob ──► GENERATING
       │
       ▼ (async worker)
  1. ActivityScoreService.scoreAll()
  2. RoomAllocationPass.run()
  3. SubActivityService.generate()
  4. FETSolver.solve() [50K iter, 25s, backtracking+greedy]
  5. TabuSearch / SimAnnealing optimizer
  6. SolutionEvaluator.evaluate()
  7. TimetableStorageService.store() [transaction]
  8. ResourceBookingService.book()
  9. ConflictDetectionService.detectFromGrid()
 10. GenerationRun.status = COMPLETED / FAILED
       │
   COMPLETED ──► GENERATED ──► [Frontend poll returns COMPLETED]
   FAILED    ──► DRAFT     ──► [Frontend shows error_message]
       │
       ▼ [Admin: Preview + Approve]
  AnalyticsService.computeAll()  ──► APPROVED
       │
       ▼ [Admin: Publish]
  Timetable.published_at = now() ──► PUBLISHED
       │
       ▼ [New version replaces this]
  Timetable.status = ARCHIVED
```

### 9.2 Substitution Workflow

```
[Teacher / Coordinator: Report Absence]
  POST /substitution/absence ──► tt_teacher_absence (PENDING)
       │
       ▼ [Coordinator: Approve]
  absence.status = APPROVED
  SubstitutionService.generateRecommendations(absenceId)
    ─ Score each eligible teacher per affected cell
    ─ Store to tt_substitution_recommendations
       │
       ▼ [Coordinator: View candidates]
  GET /substitution/candidates/{cellId}/{date}
  Returns ranked list (40+25+20+15 scoring)
       │
       ┌──────────────┬────────────────┐
       ▼ manual        ▼ auto
  POST /assign    POST /auto-assign
       │
       ▼ [Either path]
  tt_timetable_cell_teacher: INSERT (is_substitute=1)
  tt_substitution_log: status = ASSIGNED
  Notify substitute teacher
       │
       ▼ [Class occurs / Substitute confirms]
  tt_substitution_log.status = COMPLETED
  completeSubstitution() ──► update tt_substitution_patterns (running avg)
```

### 9.3 Manual Refinement Workflow

```
[Coordinator: Open Refinement Grid]
GET /smart-timetable/refinement/{timetable}
  ── Load cells PAGINATED (fix PERF-TT-001)
  ── Render interactive grid
       │
       ▼ [Click Cell A (source)]
  UI: highlight Cell A, "Select target cell"
       │
       ▼ [Click Cell B (target)]
  fetch POST /analyse-impact ──► JSON (conflicts, score delta)
  Show swap confirmation modal with impact details
       │
       ▼ [Confirm]
  POST /swap ──► RefinementService.swapCells()
    ─ Swap activity + room in transaction
    ─ Record tt_change_log (SWAP)
    ─ ConflictDetectionService.detectFromCells()
    ─ AnalyticsService.computeConstraintViolations()
  Reload grid
```

---

## 10. Non-Functional Requirements (NFRs)

### 10.1 Performance Targets

| Metric | Target | Current Issue |
|---|---|---|
| FETSolver max runtime | 25s (configurable) | Blocking web thread if run sync (GAP-ARCH-004) |
| Generation job max runtime | 600s (Laravel $timeout) | OK |
| Analytics computation | < 5s for 50-teacher school | OK |
| API single timetable GET | < 200ms | OK |
| Swap impact analysis | < 500ms | OK |
| Conflict detection (batch) | < 2s | OK |
| Index page query load | < 500ms | ❌ 15+ queries, no cache (PERF-TT-002) |
| Refinement cell load | Paginated (≤100 per page) | ❌ loads ALL globally (PERF-TT-001) |

### 10.2 Security Requirements

| ID | Severity | Requirement | Status |
|---|---|---|---|
| SEC-TT-001 | CRITICAL | EnsureTenantHasModule middleware on all SmartTimetable routes | ❌ |
| SEC-TT-002 | CRITICAL | Gate::authorize on Analytics, Refinement, Substitution controllers | ❌ |
| SEC-TT-003 | HIGH | Remove Faker\Factory import from production controller | ❌ |
| SEC-TT-004 | HIGH | Replace raw SQL deletes with soft-delete model operations in destroy() | ❌ |
| SEC-TT-005 | HIGH | Replace session-based grid data (10–50MB per session) with DB approach | ❌ |
| SEC-TT-006 | MEDIUM | Replace DB::table('tt_timetable_cell_teachers') raw inserts with model | ❌ |
| SEC-TT-007 | MEDIUM | Add rate limiting to generation and API endpoints | ❌ |
| SEC-TT-008 | MEDIUM | Sanitize error messages (do not expose internals to users) | ❌ |
| SEC-TT-009 | MEDIUM | Per-endpoint authorization on TimetableApiController | ❌ |

### 10.3 Architecture Requirements

| ID | Requirement | Priority |
|---|---|---|
| ARCH-001 | Split SmartTimetableController (3,245 lines) into ≥5 controllers | P0 |
| ARCH-002 | Create TimetableGenerationService, TimetableConfigService for controller ops | P1 |
| ARCH-003 | Move all generation to queue — eliminate synchronous generation path | P1 |
| ARCH-004 | Replace session-based data transfer with DB-based approach | P1 |
| ARCH-005 | Consolidate TimetableFoundation alias models (fragile double-namespace) | P2 |

### 10.3A FormRequest Coverage (Current vs Required)

| Controller | Action | FormRequest | Status |
|---|---|---|---|
| SmartTimetableController | storeTimetable() | StoreTimetableRequest | ❌ GAP-FR-001 |
| SmartTimetableController | generateWithFET() | GenerateTimetableRequest | ❌ GAP-FR-002 |
| RefinementController | swap() | CellSwapRequest | ❌ GAP-FR-003 |
| RefinementController | move() | CellMoveRequest | ❌ GAP-FR-003 |
| RefinementController | toggleLock() | ToggleLockRequest | ❌ GAP-FR-003 |
| SubstitutionController | reportAbsence() | RecordAbsenceRequest | ❌ GAP-FR-004 |
| SubstitutionController | assign() | AssignSubstituteRequest | ❌ GAP-FR-004 |
| SubstitutionController | autoAssign() | AutoAssignRequest | ❌ GAP-FR-004 |
| ConstraintCategoryController | store(), update() | StoreConstraintCategoryRequest | ❌ GAP-FR-005 |
| ConstraintScopeController | store(), update() | StoreConstraintScopeRequest | ❌ GAP-FR-006 |
| ConstraintTypeController | store(), update() | StoreConstraintTypeRequest | ❌ GAP-FR-007 |
| TeacherUnavailableController | store(), update() | StoreTeacherUnavailableRequest | ❌ GAP-FR-008 |
| RoomUnavailableController | store(), update() | StoreRoomUnavailableRequest | ❌ GAP-FR-009 |
| TimetableApiController | cell update | UpdateCellRequest | ❌ GAP-FR-010 |
| TtGenerationStrategyController | activate(), deactivate() | StrategyActivationRequest | ❌ GAP-FR-011 |
| ParallelGroupController | store(), update() | StoreParallelGroupRequest | ✅ |
| ParallelGroupController | addActivities() | AddActivitiesToParallelGroupRequest | ✅ |
| ConstraintController | store() | StoreConstraintRequest | ✅ |
| ConstraintController | update() | UpdateConstraintRequest | ✅ |
| TtGenerationStrategyController | store(), update() | TimetableGenerationStrategyRequest | ✅ |

**Summary: 7 FormRequests exist, 15+ missing across 11 controllers.**

### 10.4 Data Integrity Requirements

| Requirement | Status |
|---|---|
| All tt_* tables: is_active + deleted_at (soft delete) | ✅ |
| Audit trail: sys_activity_logs for all state-changing operations | 🟡 |
| tt_change_log for all cell modifications | ✅ |
| Generated columns enforce computed fields (total_periods, duration_minutes) | ✅ |
| CHECK constraints on mutual exclusion (group XOR subgroup) | ✅ |

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Module | Type | What STT Uses |
|---|---|---|
| SchoolSetup (SCH) | Read-only | sch_classes, sch_sections, sch_rooms, sch_teachers, sch_subjects, sch_buildings |
| TimetableFoundation (TTF) | Shared models | Foundation models extended via backward-compat aliases (GAP-MDL-002) |
| StudentProfile (STD) | Read-only | std_students — student count in requirement groups |
| SyllabusModule (SLB) | Read-only | Subjects and study formats for activity definition |
| Notification (NTF) | Publish | Substitution notifications (SMS/Email/In-app) |
| Audit (SYS) | Publish | sys_activity_logs for all state-changing operations |

### 11.2 Technical Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| PHP | 8.2+ | Runtime |
| Laravel | 12 | Framework |
| nwidart/laravel-modules | v12 | Module system |
| stancl/tenancy | v3.9 | Multi-tenancy (all tt_* in tenant_{uuid} DB) |
| MySQL | 8.x InnoDB | Generated columns, JSON, CHECK constraints |
| Laravel Queue | — | Async GenerateTimetableJob |
| Laravel Sanctum | — | REST API token auth |

### 11.2A Module Middleware Stack (Required)

All SmartTimetable routes in `tenant.php` must be wrapped with this middleware stack:

```php
Route::middleware([
    'web',
    'auth',
    InitializeTenancyByDomain::class,
    PreventAccessFromCentralDomains::class,
    EnsureTenantHasModule::class.':smart-timetable',  // ❌ MISSING — SEC-TT-001
])->prefix('smart-timetable')->name('smart-timetable.')->group(function () {
    // all route definitions
});
```

Without `EnsureTenantHasModule`, any authenticated user at any tenant can access SmartTimetable even if the tenant has not purchased the module license.

### 11.3 Seeder Dependencies (must run before module use)

9 seeders required: `TtConfigSeeder`, `ConstraintCategorySeeder`, `ConstraintScopeSeeder`, `ConstraintTargetTypeSeeder`, `ConstraintTypeSeeder`, `GenerationStrategySeeder`, `PeriodTypeSeeder`, `DayTypeSeeder`, `DaySeeder`

---

## 12. Test Scenarios

### 12.1 Existing Tests

| File | Type | Tests |
|---|---|---|
| `tests/Feature/SmartTimetable/ActivityControllerTest.php` | Feature (Pest, RefreshDatabase) | Activity CRUD via HTTP |
| `tests/Unit/SmartTimetable/ActivityModelTest.php` | Unit (PHPUnit) | Model relationships + computed fields |
| `tests/Unit/SmartTimetable/ConstraintClassesTest.php` | Unit | Individual constraint evaluate() methods |
| `tests/Unit/SmartTimetable/ConstraintEvaluatorTest.php` | Unit | ConstraintEvaluator with mock activities |
| `tests/Unit/SmartTimetable/FETSolverScoringTest.php` | Unit | Solver activity scoring |
| `tests/Unit/SmartTimetable/ParallelGroupBacktrackTest.php` | Unit | Parallel group anchor backtracking |
| `tests/Unit/SmartTimetable/TimetableSolutionIsPlacedTest.php` | Unit | TimetableSolution placement flags |

Note: Gap analysis (2026-03-22) reported 0 tests found in codebase at that point; the above 7 files were listed in V1 and confirmed present in the `tests/Feature/SmartTimetable/` and `tests/Unit/SmartTimetable/` directories per current Bash scan. Whether all tests pass is unverified.

### 12.1A Test Pattern Details

| Pattern | Implementation |
|---|---|
| Feature test bootstrap | `uses(Tests\TestCase::class, Illuminate\Foundation\Testing\RefreshDatabase::class)` (Pest) |
| Unit test bootstrap | `use PHPUnit\Framework\TestCase;` — bare PHPUnit, no Laravel app boot |
| In-memory model fixtures | `Activity::make([...])` with `$activity->setRelation('teachers', collect([...]))` |
| Queue assertions | `Queue::fake(); ... Queue::assertPushed(GenerateTimetableJob::class)` |
| Sanctum API tests | `$user = User::factory()->create(); $this->actingAs($user, 'sanctum')` |
| Tenant context | `$tenant->run(fn() => ...)` wrapping all tenant DB assertions |

### 12.2 Required New Tests (📐 V2 Target: 60% coverage)

| Test File | Type | Key Scenarios |
|---|---|---|
| `GenerationPipelineTest` | Feature | Full async generation: valid config → COMPLETED status |
| `ConstraintManagerTest` | Unit | createConstraintManager() loads DB constraints; FETConstraintBridge maps correctly |
| `FETSolverConstraintTest` | Unit | Hard constraint violations cause FAILED; soft violations scored |
| `TimetableStatusFlowTest` | Feature | DRAFT→GENERATING→GENERATED→APPROVED→PUBLISHED state machine |
| `SubstitutionFlowTest` | Feature | Absence→Approval→CandidateRanking→Assignment→Complete |
| `RefinementSwapTest` | Feature | Swap cells; impact analysis returns conflict data; change log created |
| `AnalyticsComputeTest` | Unit | TeacherWorkload, RoomUtilization compute correctly |
| `ParallelGroupAnchorTest` | Unit | Anchor pinning forces all group members to same slot |
| `ApiEndpointAuthTest` | Feature | All 16 API endpoints require Sanctum token |
| `TenantModuleMiddlewareTest` | Feature | Routes reject access without EnsureTenantHasModule |

### 12.3 Test Patterns

- Feature tests: Pest syntax, `Tests\TestCase` with `RefreshDatabase`
- Unit tests: bare PHPUnit (no Laravel app boot) where possible
- Model fixtures: `Activity::make([...])` + `setRelation('teachers', collect([...]))`
- Mock queue: `Queue::fake()` for generation job dispatch tests

---

## 12A. Bug Tracker (Cross-Reference)

All 12 documented BUG-TT-NNN bugs from project context, mapped to gap analysis IDs:

| Bug ID | Gap Analysis ID | Description | Severity | Fix Status |
|---|---|---|---|---|
| BUG-TT-001 | GAP-CTRL-001 | SmartTimetableController 3,245 lines — god-class | P0 | ❌ Open |
| BUG-TT-002 | GAP-SVC-001 | FETConstraintBridge broken — constraints not wired to solver | P0 | ❌ Open |
| BUG-TT-003 | GAP-CTRL-010 | createConstraintManager() returns empty ConstraintManager (all commented out at lines 277–317) | P0 | ❌ Open |
| BUG-TT-004 | GAP-RT-001 / SEC-TT-001 | No EnsureTenantHasModule middleware on route group | P0 | ❌ Open |
| BUG-TT-005 | GAP-POL-003 / SEC-TT-002 | Analytics, Refinement, Substitution controllers have zero Gate::authorize calls | P0 | ❌ Open |
| BUG-TT-006 | GAP-RT-002 | Route `generateForClassSection` registered but controller method does not exist | P1 | ❌ Open |
| BUG-TT-007 | GAP-RT-003 | standard-timetable.* route group is completely empty — no routes registered | P1 | ❌ Open |
| BUG-TT-008 | PERF-TT-001 | viewAndRefinement() loads ALL timetable cells globally — OOM on production | P0 | ❌ Open |
| BUG-TT-009 | GAP-CTRL-012 | destroy() uses raw SQL hard-delete on TimetableCell and GenerationRun, bypassing SoftDeletes | P1 | ❌ Open |
| BUG-TT-010 | GAP-MDL-004 | Timetable::generationStrategy() BelongsTo points to GenerationRun::class instead of TtGenerationStrategy::class | P2 | ❌ Open |
| BUG-TT-011 | GAP-CTRL-004 | resourceful store() and update() methods in SmartTimetableController are empty stubs | P1 | ❌ Open |
| BUG-TT-012 | SEC-TT-005 | Session stores large timetable grid data (10–50MB) — session fixation / memory risk | P1 | ❌ Open |

---

## 12B. Error Handling Requirements

### 12B.1 Generation Errors

| Error | Handling | Status |
|---|---|---|
| HardConstraintViolationException in FETSolver | Increment hard_violations; if unresolvable → run FAILED | ✅ |
| Queue job timeout (600s $timeout, $tries=1) | Run FAILED, error_message = "Generation timeout exceeded" | ✅ |
| DB transaction failure during storage | Full rollback; run FAILED | ✅ |
| Activity placement fails for all slots | activities_failed incremented; partial solution stored with flag | 🟡 |
| Pre-validation failure | Return structured JSON per category; generation blocked | ✅ |

### 12B.2 API Error Responses

| Code | Format | Example |
|---|---|---|
| 404 | `{ "success": false, "message": "Timetable not found" }` | Unknown timetable ID |
| 403 | `{ "success": false, "message": "Unauthorized" }` | Sanctum token lacks permission |
| 422 | `{ "success": false, "message": "...", "errors": {...} }` | Validation failure |
| 429 | `{ "success": false, "message": "Too Many Requests" }` | Rate limit exceeded (pending implementation) |
| 500 | `{ "success": false, "message": "Internal server error" }` | Unexpected exception |

### 12B.3 Refinement Errors

| Error | Handling |
|---|---|
| Swap would create hard constraint violation | analyseSwapImpact() returns conflict list; modal shows warning; admin can override |
| Target cell is locked | Swap rejected with 422: "Target cell is locked" |
| Batch swap partial failure | rollbackBatch() reverts all; change log records rollback |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Activity | Core scheduling entity: one class+section+subject+study_format+weekly_periods combination |
| Anchor | First activity placed in a parallel group; defines (day_of_week, period_ord) for all group members |
| Backtracking | FETSolver strategy: place activity; if conflict detected, undo and try next slot |
| Cell | One slot in the timetable grid: (timetable_id, day_of_week, period_ord, class_group_id) |
| CSP | Constraint Satisfaction Problem — mathematical framework used by FET solver |
| FET | Free Timetabling Software — open-source CSP timetabling system that inspired Prime-AI's solver |
| FETConstraintBridge | Service that maps DB constraint records to PHP constraint objects for FETSolver |
| GenerationRun | One execution of the generation job for a timetable; multiple runs per timetable allowed |
| Hard Constraint | Constraint that must NEVER be violated; violation causes FAILED generation |
| Parallel Group | Set of activities across sections that must be scheduled simultaneously |
| Period Set | Template defining all periods in a day (with types, times, durations) |
| SA | Simulated Annealing — optimization algorithm using probabilistic acceptance |
| Soft Constraint | Constraint whose violation is scored but does not cause failure |
| Sub-Activity | Part of a multi-period activity; can be assigned to different class sections |
| Substitution Pattern | ML record of teacher's historical substitution success (running average) |
| Tabu Search | Optimization algorithm that maintains a tabu list to avoid revisiting solutions |
| Working Day | Calendar date with assigned DayType; drives slot availability |

---

## 14. Suggestions & Refactoring Priorities

### P0 — Critical (Must Fix Before Production)

| # | Issue ID | Action | Effort |
|---|---|---|---|
| 1 | SEC-TT-001 | Add `EnsureTenantHasModule` middleware to ALL SmartTimetable route groups in tenant.php | 2h |
| 2 | GAP-POL-003 | Add `Gate::authorize()` to AnalyticsController, RefinementController, SubstitutionController — at minimum check `smart-timetable.manage` | 4h |
| 3 | GAP-CTRL-001 / ARCH-001 | Extract from SmartTimetableController: TimetableGenerationController, TimetableConfigController, TimetableViewerController, TimetableMasterController | 20h |
| 4 | GAP-FR-001 / GAP-FR-002 | Replace inline validation in storeTimetable() (312 lines) and generateWithFET() (~900 lines) with FormRequests | 8h |
| 5 | PERF-TT-001 | Fix viewAndRefinement(): replace `TimetableCell::all()` with paginated, timetable-scoped query | 3h |
| 6 | SEC-TT-003 | Remove `Faker\Factory` import from SmartTimetableController | 1h |

### P1 — High Priority

| # | Issue ID | Action | Effort |
|---|---|---|---|
| 7 | BUG-TT-002 | Fix FETConstraintBridge — wire DB constraint records to PHP solver constraint objects | 16h |
| 8 | GAP-CTRL-010 | Uncomment/implement createConstraintManager() to load active DB constraints | 8h |
| 9 | GAP-POL-001 | Create policies for: AnalyticsController, RefinementController, SubstitutionController, ConstraintCategoryController, ConstraintScopeController, ConstraintController, ConstraintTypeController, ParallelGroupController, TeacherUnavailableController, RoomUnavailableController, TimetableApiController | 12h |
| 10 | GAP-RT-003 | Build and wire StandardTimetableController (hub + class + teacher + room views) | 8h |
| 11 | GAP-ARCH-004 | Ensure generation always goes through queue — remove/guard synchronous path | 4h |
| 12 | SEC-TT-004 | Replace raw SQL hard-delete in destroy() with soft-delete model operations | 3h |
| 13 | GAP-FR-003–011 | Add FormRequests for all 11 remaining missing validation locations | 12h |
| 14 | PERF-TT-002 | Cache reference data (DayType, PeriodType) in index() — use remember() with 10min TTL | 4h |

### P2 — Medium Priority

| # | Issue ID | Action | Effort |
|---|---|---|---|
| 15 | GAP-DB-001 | Add DDL for 4 migration-only tables: tt_parallel_group_activity, tt_analytics_daily_snapshots, tt_substitution_patterns, tt_substitution_recommendations | 4h |
| 16 | GAP-DB-003 / GAP-MDL-001 | Remove or add DDL for 21 phantom models | 8h |
| 17 | SEC-TT-007 | Add throttle:5,1 rate limiting to generation endpoint and TimetableApiController | 2h |
| 18 | GAP-MDL-004 | Fix Timetable::generationStrategy() relationship (points to GenerationRun instead of TtGenerationStrategy) | 1h |
| 19 | ARCH-005 | Consolidate TimetableFoundation alias models — eliminate fragile double-namespace | 12h |
| 20 | test coverage | Implement 10 new test files targeting 60%+ coverage | 30h |

### P3 — Low Priority

| # | Issue ID | Action | Effort |
|---|---|---|---|
| 21 | SEC-TT-010 | Remove unused imports (Hash, Faker) | 1h |
| 22 | PERF-TT-006 | Add composite indexes on (timetable_id, day_of_week, period_ord) and (timetable_id, class_group_id) | 2h |
| 23 | future | PDF export via DomPDF (pattern from HPC module) | 8h |
| 24 | future | iCal export complete implementation in exportIcal() | 4h |
| 25 | future | What-If scenario UI (WhatIfScenario model exists) | 20h |
| 26 | future | Version comparison diff view (VersionComparison model exists) | 12h |

**Total estimated remediation effort: 105–140 hours** (from gap analysis)

---

## 15. Appendices

### 15.1 Hard Constraint Classes (24)

| Class | Scope | Description |
|---|---|---|
| `TeacherConflictConstraint` | TEACHER | No teacher double-booked at same time |
| `NotOverlappingConstraint` | CLASS | No student group double-booked |
| `RoomExclusiveUseConstraint` | ROOM | No room double-booked |
| `TeacherUnavailablePeriodsConstraint` | TEACHER | Enforce tt_teacher_unavailable records |
| `TeacherRoomUnavailableConstraint` | TEACHER+ROOM | Combined unavailability |
| `TeacherMaxDailyConstraint` | TEACHER | Max teaching periods per day |
| `TeacherMaxWeeklyConstraint` | TEACHER | Max teaching periods per week |
| `ClassMaxPerDayConstraint` | CLASS | Max periods for class per day |
| `ClassWeeklyPeriodsConstraint` | CLASS | Exactly required_weekly_periods placed |
| `ClassConsecutiveRequiredConstraint` | CLASS | Min consecutive periods enforced |
| `ActivityFixedToDayConstraint` | ACTIVITY | Pin activity to specific day |
| `ActivityFixedToPeriodRangeConstraint` | ACTIVITY | Pin activity to period range |
| `ActivityExcludedFromDayConstraint` | ACTIVITY | Exclude activity from specific day |
| `OccupyExactSlotsConstraint` | ACTIVITY | Exactly N slots required |
| `SameStartingTimeConstraint` | ACTIVITY | Two activities start simultaneously |
| `ConsecutiveActivitiesConstraint` | ACTIVITY | Two activities must be consecutive |
| `ParallelPeriodConstraint` | GROUP | Parallel group anchor enforcement |
| `GlobalFixedPeriodConstraint` | GLOBAL | School-wide period reservation |
| `GlobalHolidayConstraint` | GLOBAL | No activities on holidays |
| `ExamOnlyPeriodsConstraint` | GLOBAL | Exam periods reserved for exams |
| `NoTeachingAfterExamConstraint` | GLOBAL | No teaching after exam on same day |
| `RoomMaxUsagePerDayConstraint` | ROOM | Room usage cap per day |
| *(2 additional in code — verify names)* | | |

### 15.2 Soft Constraint Classes (62)

**Teacher-scope (24):** TeacherDailyStudyFormatConstraint, TeacherFreePeriodEachHalfConstraint, TeacherGapsInSlotRangeConstraint, TeacherHomeRoomConstraint, TeacherMaxBuildingChangesPerDayConstraint, TeacherMaxConsecutiveDBConstraint, TeacherMaxConsecutiveStudyFormatConstraint, TeacherMaxDaysInIntervalConstraint, TeacherMaxGapsPerDayConstraint, TeacherMaxGapsPerWeekConstraint, TeacherMaxHoursInIntervalConstraint, TeacherMaxRoomChangesPerDayConstraint, TeacherMaxRoomChangesPerWeekConstraint, TeacherMaxSpanPerDayConstraint, TeacherMaxStudyFormatsConstraint, TeacherMinDailyConstraint, TeacherMinGapBetweenRoomChangesConstraint, TeacherMinRestingHoursConstraint, TeacherMutuallyExclusiveSlotsConstraint, TeacherNoConsecutiveDaysConstraint, TeacherPreferredFreeDayConstraint, TeacherStudyFormatGapConstraint, GlobalMaxTeachingDaysConstraint, PreferredSlotSelectionConstraint

**Class-scope (18):** ClassMajorSubjectsDailyConstraint, ClassMaxConsecutiveStudyFormatConstraint, ClassMaxContinuousConstraint, ClassMaxDaysInIntervalConstraint, ClassMaxGapsPerWeekConstraint, ClassMaxMinorSubjectsConstraint, ClassMaxRoomChangesPerDayConstraint, ClassMaxSpanConstraint, ClassMaxStudyFormatHoursConstraint, ClassMinDailyHoursConstraint, ClassMinGapConstraint, ClassMinRestingHoursConstraint, ClassMinStudyFormatHoursConstraint, ClassStudyFormatGapConstraint, ClassNotFirstPeriodConstraint, ClassNotLastPeriodConstraint, ClassTeacherFirstPeriodConstraint, EndStudentsDayConstraint

**Room-scope (7):** MaxDifferentRoomsConstraint, PreferSameRoomConstraint, RoomMaxStudyFormatsConstraint, SameRoomIfConsecutiveConstraint, StudyFormatPreferredRoomConstraint, SubjectPreferredRoomConstraint, SubjectStudyFormatPreferredRoomConstraint

**Inter-activity (9):** MaxDaysBetweenConstraint, MinDaysBetweenConstraint, MinGapsBetweenSetConstraint, NonConcurrentMinorSubjectsConstraint, OccupyMaxSlotsConstraint, OccupyMinSlotsConstraint, OrderedIfSameDayConstraint, SameDayConstraint, SameHourConstraint

**Global (4):** GlobalBalancedDistributionConstraint, GlobalPreferMorningConstraint, GenericSoftConstraint, *(1 more)*

### 15.3 Known Bugs Summary

| Bug ID | Severity | Description | Fix Priority |
|---|---|---|---|
| BUG-TT-001 / GAP-CTRL-001 | CRITICAL | SmartTimetableController is 3,245 lines (god-class) | P0 |
| BUG-TT-002 / GAP-SVC-001 | CRITICAL | FETConstraintBridge broken — constraints not wired to solver | P1 |
| GAP-CTRL-010 | CRITICAL | createConstraintManager() returns empty manager (all commented out) | P1 |
| GAP-RT-001 / SEC-TT-001 | CRITICAL | No EnsureTenantHasModule on route group | P0 |
| GAP-POL-003 / SEC-TT-002 | CRITICAL | Zero authorization on Analytics/Refinement/Substitution controllers | P0 |
| GAP-RT-002 | HIGH | generateForClassSection route exists; controller method missing | P1 |
| GAP-RT-003 | HIGH | standard-timetable route group completely empty | P1 |
| PERF-TT-001 | HIGH | viewAndRefinement() loads ALL cells globally — OOM risk | P0 |
| GAP-CTRL-012 | HIGH | destroy() uses hard-delete raw SQL, bypassing soft-delete | P1 |
| GAP-MDL-001 | MEDIUM | 21 phantom models with no DDL tables | P2 |
| GAP-MDL-004 | MEDIUM | Timetable::generationStrategy() points to wrong model class | P2 |
| GAP-SVC-003 | LOW | ImprovedTimetableGenerator exists but never used — dead code | P3 |

---

## 16. V1 → V2 Delta

### 16.1 New in V2

| Item | Description |
|---|---|
| 🆕 Section 2 Architecture diagram | FET-inspired layered architecture diagram |
| 🆕 Scorecard table | Quantified category scores with V2 targets |
| 🆕 Controller list updated | 19 controllers including 7 new split controllers observed in codebase |
| 🆕 GAP-DB-001–003 documented | 4 migration-only tables, 21 phantom models explicitly listed |
| 🆕 GAP-RT-001–005 documented | Missing middleware, broken route, empty route group |
| 🆕 GAP-CTRL-001–012 documented | God controller: 12 specific code-level issues |
| 🆕 SEC-TT-001–009 documented | 9 security issues with severity and location |
| 🆕 PERF-TT-001–009 documented | 9 performance issues |
| 🆕 FR-STT-16 Standard Timetable | Marked ❌ — non-functional (empty route group) |
| 🆕 Section 14 Refactoring priorities | P0/P1/P2/P3 priority grid with effort estimates |
| 🆕 Section 12.2 New tests required | 10 test files needed to reach 60% coverage |
| 📐 Section 6.2 Controller split plan | Proposed extraction of 5 controllers from god controller |

### 16.2 Status Changes from V1

| FR | V1 Status | V2 Status | Reason |
|---|---|---|---|
| Constraint wiring to solver | Partial | ❌ BUG-TT-002 | Gap analysis confirmed FETConstraintBridge broken AND createConstraintManager() all commented out |
| Standard Timetable | Done | ❌ | Gap analysis confirmed route group completely empty |
| Tests | 7 files listed | 0 confirmed | Gap analysis found 0 tests in codebase; V1 listed were projected not present |
| Security (all areas) | Not assessed | ❌ multiple P0 | Gap analysis revealed critical security gaps |
| God controller refactoring | Not done | P0 (3,245 lines) | Confirmed; 7 additional split controllers now exist in codebase |

### 16.3 Preserved from V1 (Unchanged)

- All FR-STT-01 through FR-STT-15 functional requirements (refined in V2 with status markers)
- All business rules BR-STT-001 through BR-STT-022
- Full data model (42 tables) with column-level detail
- All 24 hard constraint classes and 62 soft constraint classes
- Generation pipeline FSM and substitution workflow
- API endpoint table (16 endpoints)
- NFR performance targets
- Glossary

---

### 16.4 Open Architecture Decisions (📐 Requires Team Decision)

| Decision | Options | Recommendation |
|---|---|---|
| Session vs DB for generation data | (A) Keep session, (B) Store to tt_generation_run.stats_json, (C) Redis cache | Recommend (B) — aligns with existing stats_json column; eliminates 10–50MB session payloads |
| God controller split strategy | (A) New controllers in SmartTimetable module, (B) Move to TimetableFoundation | Recommend (A) — keep STT module self-contained; reuse only models from TTF |
| Constraint loading in FETSolver | (A) Fix FETConstraintBridge, (B) Inject ConstraintManager directly | Recommend (A) — Bridge pattern is correct design; root cause is context initialization order |
| Phantom model cleanup | (A) Add DDL for all 21, (B) Remove unused, (C) Defer to ML phase | Recommend (B) for non-ML models; (C) for ML/AI models (MlModel, TrainingData, FeatureImportance) |
| Standard Timetable views | (A) New controller, (B) Reuse AnalyticsController report views | Recommend (A) StandardTimetableController with dedicated views; reuse _grid partial |
| TimetableFoundation alias models | (A) Keep backward-compat aliases, (B) Consolidate to single namespace | Recommend (B) long-term; (A) acceptable short-term to avoid regressions |

### 16.5 Migration Plan (Phased Delivery)

| Phase | Scope | Items | Est. Hours |
|---|---|---|---|
| Phase 1 — Security Hardening | P0 security + auth | SEC-TT-001, SEC-TT-002, GAP-POL-003, PERF-TT-001 | 15h |
| Phase 2 — Architecture | God controller split | GAP-CTRL-001, GAP-CTRL-002, GAP-CTRL-003, ARCH-001 | 25h |
| Phase 3 — Constraint Engine Fix | BUG-TT-002, GAP-CTRL-010 | Fix FETConstraintBridge + createConstraintManager() | 24h |
| Phase 4 — Missing Features | Standard Timetable, missing routes, publish flow | GAP-RT-003, FR-STT-16, FR-STT-11, FR-STT-12 | 20h |
| Phase 5 — FormRequests + Policies | Complete 11 missing FormRequests, 12 missing policies | GAP-FR-003–011, GAP-POL-001 | 20h |
| Phase 6 — Test Suite | 10 new test files, 60% coverage target | Section 12.2 | 30h |
| Phase 7 — Performance + DDL cleanup | Pagination, caching, phantom models, indexes | P2/P3 items | 25h |
| **Total** | | | **159h** |

---

*Document generated from: V1 requirement, deep gap analysis (2026-03-22), DDL inspection, live code scan.*
*Controllers confirmed: 19 (web) + 1 (API). Services: 22 files across 5 sub-namespaces.*
*Hard constraints: 24 PHP files. Soft constraints: 62 PHP files.*
