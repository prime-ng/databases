# SmartTimetable Module — Complete Claude Context
**Date:** 2026-03-10
**Branch:** `Brijesh`
**Laravel path:** `/Users/bkwork/Herd/laravel/`
**Databases repo:** `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/`

---

## 1. PURPOSE OF THIS DOCUMENT

This document is a complete, self-contained context file. Reading this single file should restore full working knowledge of the SmartTimetable module — its architecture, current implementation state, what is complete, what is pending, all known issues, file locations, algorithm details, route structure, model mappings, and the gap between requirements and actual code.

---

## 2. MODULE OVERVIEW

### What It Is
The SmartTimetable module is a **constraint-based automatic timetable generation engine** for Indian schools built on PHP/Laravel. It takes curriculum requirements (what subjects need to be taught, by whom, how many periods per week) and automatically produces a conflict-free weekly timetable for all classes, sections, teachers, and rooms.

### Location
```
Laravel Module:   /Users/bkwork/Herd/laravel/Modules/SmartTimetable/
Input Docs:       databases/2-Tenant_Modules/8-Smart_Timetable/Input/
Design Docs:      databases/2-Tenant_Modules/8-Smart_Timetable/Design_docs/
V6 Docs:          databases/2-Tenant_Modules/8-Smart_Timetable/V6/
Module DOCS:      /Users/bkwork/Herd/laravel/Modules/SmartTimetable/DOCS/
Routes:           /Users/bkwork/Herd/laravel/routes/tenant.php  (lines ~1732–2060)
```

### Module Stats
| Category | Count |
|----------|-------|
| Controllers | 27 (+ 1 backup file) |
| Models | 84 |
| Services | ~20 active + 13 archived |
| Views (blade) | ~212 |
| Seeders | 13 |
| Migrations | 0 (uses tenant_db.sql directly) |
| Tests | 0 |
| DOCS files | 13 markdown files |

---

## 3. INPUT / REQUIREMENTS DOCUMENTS

All requirement & design files are in `databases/2-Tenant_Modules/8-Smart_Timetable/`:

### `Input/0-tt_Requirement_v3.md`
Full requirements. Key points:
- FET-inspired algorithm (recursive swapping / ejection chain)
- Max recursion depth: 14
- Max recursive calls: 2 × nInternalActivities
- 4 hard constraints: teacher double-booking, class double-booking, room double-booking, room capacity exceeded
- 70+ soft constraints across Teacher, Class, Activity, Room, Student categories
- School-specific requirements: Maths of 4T in periods 6–8, class teachers get period 1, major subjects every day, max 2 minor subjects per day, consecutive periods for Hobby/Astro/Robotics/Practicals, parallel periods for Hobby/Skill/Optional subjects across sections, lab resource constraints
- Import/export CSV; output HTML/XML/CSV

### `Input/1-tt_timetable_ddl_v7.6.sql`
Complete DDL for all `tt_*` tables. This is the **authoritative schema** (v7.6). Defines 12 sections:
1. Configuration (tt_config, sch_academic_term)
2. Timetable Config (tt_timetable_type, tt_period_set, tt_period_set_period_jnt)
3. Timetable Masters (tt_shift, tt_day_type, tt_period_type, tt_teacher_assignment_role, tt_school_days, tt_working_day, tt_class_working_day_jnt)
4. Timetable Requirement (tt_slot_requirement, tt_class_requirement_groups, tt_class_requirement_subgroups, tt_requirement_consolidation)
5. Constraint Engine (tt_constraint_category_scope, tt_constraint_type, tt_constraint, tt_teacher_unavailable, tt_room_unavailable)
6. Resource Availability (tt_teacher_availability, tt_teacher_availability_details, tt_room_availability)
7. Timetable Preparation (tt_activity, tt_sub_activity, tt_priority_config, tt_activity_teacher)
8. Timetable Generation (tt_generation_run, tt_constraint_violation, tt_conflict_detection, tt_resource_booking)
9. Timetable View & Refinement (tt_timetable, tt_timetable_cell, tt_timetable_cell_teacher, tt_change_log)
10. Reports & Logs (tt_teacher_workload, tt_room_utilization, tt_analytics_daily_snapshot)
11. Substitution (tt_teacher_absence, tt_substitution_recommendation, tt_substitution_log, tt_substitution_pattern)
12. Additional (tt_generation_strategy, tt_class_timetable_type_jnt, tt_class_working_day_jnt)

### `Input/3-Process_flow_v1.md` — High-Level 8-Phase Flow
```
Phase 0: Prerequisites Setup (tt_config, masters)
Phase 1: Academic Term & Timetable Type Setup
Phase 2: Requirement Generation (tt_slot_requirement, tt_class_requirement_groups/subgroups, tt_requirement_consolidation)
Phase 3: Resource Availability Preparation (tt_teacher_availability, tt_room_availability, constraints)
Phase 4: Validation (teacher coverage, room coverage, constraint compatibility)
Phase 5: Activity Creation & Prioritization (tt_activity, difficulty_score, priority_score)
Phase 6: Timetable Generation (FET recursive swapping, tt_timetable_cell)
Phase 7: Post-Generation Processing (analytics, manual refinement, publication)
Phase 8: Substitution Management (absence → finder → pattern learning)
```

### `Input/3-Process_Flow_v3.md` — Enhanced Detailed Process (80KB)
Highly detailed v3.0 expansion of each phase. Key additions over v1:
- Phase 0.2: Master data validation with batch checks
- Phase 1.5: Class Timetable Type Mapping (tt_class_timetable_type_jnt)
- Phase 2.2: Class Requirement Groups/Subgroups — exact UPDATE SQL for student_count and eligible_teacher_count
- Phase 2.3: Requirement Consolidation with DB transactions
- Phase 3.1: Teacher Availability — 5-step process with window functions for score calculation
- Phase 4: Validation with PASSED/PASSED_WITH_WARNINGS/FAILED/BLOCKED scoring
- Phase 5.2: Enhanced difficulty scoring (5 components with weights: 35/20/15/15/15)
- Phase 6: Multi-algorithm (CSP → Tabu Search → Simulated Annealing → Genetic Algorithm)
- Phase 7: Full analytics dashboard + daily snapshots
- Phase 8: Substitution with ML pattern learning

### `Input/4-Process_execution_v1.md` — Exact SQL/PHP Code
Step-by-step implementation with actual SQL queries for:
- `generateSlotRequirement` (Steps 1–2 with loops)
- `generateClassSubjectGroups` (Steps 1–8 with UPDATE SQL)
- `generateRequirementConsolidation` (Steps 1–3 with PHP DB transactions)
- `generateTeacherAvailability` (Steps 1–9 with LEFT JOIN INSERT and UPDATE SQL)

### `Input/5-Constraints_v1.csv`
~70 constraints with priority ratings (1–10), target (Teacher/Class/Activity/Room/Student), applicability. Key high-priority (10) constraints:
- Major subjects scheduled every day
- Max 2 minor subjects per day per class
- Class teachers get period 1
- Parallel scheduling for Hobby/Skill/Optional subjects across sections
- Consecutive periods for Hobby (cl 6–9), Astro (cl 3–8), Robotics (cl 6–8), Practicals (cl 11–12)
- Lab resource allocation (Computer Lab, Senior Lab, Robotics Lab, Bio/Chem Lab)

### `Design_docs/tt_Checklist.md`
Checklist — mostly unchecked. Schema verification, data entry, process flow verification tasks.

### `Design_docs/tt_Algoritham.md`
PHP/Laravel algorithm explanation in plain language (step-by-step without Python). Explains grouped activities, parallel sections, room assignment strategy.

---

## 4. ALGORITHM IMPLEMENTATION (ACTUAL vs DESIGNED)

### What Was Designed (Input docs)
Full multi-phase hybrid algorithm:
1. **Phase 1 — CSP Backtracking** (recursive swapping, max depth 14, tabu list to avoid cycles)
2. **Phase 2 — Tabu Search** (if conflicts remain after Phase 1, iterative improvement with tabu list, max iterations, aspiration criteria)
3. **Phase 3 — Simulated Annealing** (optimization pass, temperature cooling from 100 to 1.0, cooling rate 0.95)
4. **Phase 4 — Genetic Algorithm** (if activity_count > 1000 or improvement < 5%, population of 50, tournament selection, order-based crossover)

Strategy selector:
- activity_count < 500 → RECURSIVE_FAST
- 500–1000 → HYBRID_BALANCED
- > 1000 → GENETIC_THOROUGH
- complex_constraints > 50 → TABU_OPTIMIZED

### What Was Actually Built (current code)
**FETSolver.php** (`app/Services/Generator/FETSolver.php`, 2,233 lines):
- **Phase 1: Backtracking algorithm** — depth-first CSP search with conflict detection, max 25 second timeout (upgraded from 5s in March 2026)
- **Phase 2: Greedy fallback** — sequential placement if backtracking times out, takes ~70 seconds, achieves 99%+
- NO Tabu Search, NO Simulated Annealing, NO Genetic Algorithm implemented
- `TtGenerationStrategy` model and seeders exist but are NOT wired to different algorithm implementations

**March 2026 improvements applied to FETSolver:**
1. `backtrack_timeout` increased from 5s → 25s
2. Smart teacher assignment: sort by workload, pick from top 3 least-busy (not pure random)
3. Timeout monitoring/tracking added
4. Constraint checking optimization (~6,000 checks vs 8,400 previously)
5. Enhanced placement diagnostics

**Performance benchmarks:**
| Scenario | Gen Time | Coverage | Success Rate |
|----------|----------|----------|--------------|
| Backtracking succeeds | 30–40s | 100% | 80%+ |
| Greedy fallback needed | 70–80s | 99%+ | remaining 15–20% |
| Small school (100 students) | 10–15s | 100% | 95%+ |
| Large school (500+ students) | 60–90s | 99%+ | 60%+ |

**Key algorithm flow:**
```
generateWithFET(Request) → SmartTimetableController
  → loadActivities() + loadConstraints()
  → FETSolver::solve(Collection $activities)
      → expandActivitiesByWeeklyPeriods()
      → backtracking algorithm
          → for each activity: validatePlacement(activity, dayIdx, periodIdx)
          → ConstraintManager::check(hard constraints)
          → if no slot: backtrack
          → timeout → greedy fallback
      → TimetableStorageService: create TimetableCell records
  → storeTimetable() → preview()
```

---

## 5. COMPLETE FILE STRUCTURE

### Controllers (`app/Http/Controllers/`)
```
SmartTimetableController.php          (2,993 lines) — main orchestration
SmartTimetableController_29_01_before_store.php  ← BACKUP FILE, should be deleted
ActivityController.php                (1,758 lines) — activity CRUD + generation
AcademicTermController.php
ClassSubjectSubgroupController.php
ConstraintController.php
ConstraintTypeController.php
DayTypeController.php
PeriodController.php
PeriodSetController.php
PeriodSetPeriodController.php
PeriodTypeController.php
RequirementConsolidationController.php
RoomUnavailableController.php
SchoolDayController.php
SchoolShiftController.php
SchoolTimingProfileController.php
SlotRequirementController.php
TeacherAssignmentRoleController.php
TeacherAvailabilityController.php
TeacherUnavailableController.php
TimetableController.php
TimetableTypeController.php
TimingProfileController.php
TtConfigController.php
TtGenerationStrategyController.php
WorkingDayController.php
```

**MISSING controllers (referenced in routes but files do not exist):**
- `ClassSubjectGroupController` — used for `generateClassSubjectGroups()` and `updateSharing()`
- `ClassSubgroupController` — used for old `class-subgroup` resource routes
- `ClassGroupRequirementController` — imported in tenant.php but no routes reference it

**MISSING methods in existing controllers (referenced in routes but not in code):**
- `ActivityController::generateAllActivities()` → route `class-group-requirements.generate-all`
- `ActivityController::getBatchGenerationProgress()` → route `class-group-requirements.generation-progress`
- `SmartTimetableController::generateForClassSection()` → route `generate-for-class-section`

**Methods in SmartTimetableController that should be cleaned up:**
- `seederTest()` (line 2988) — test/debug, should be removed
- `debugPlacementIssue()` (line 961)
- `debugPeriods()` (line 1065)
- `diagnoseLunchProblem()` (line 1194)
- `debugActivityDurations()` (line 1194)

### Services (`app/Services/`)
```
Generator/
  FETSolver.php              (2,233 lines) — CORE: backtracking + greedy
  ImprovedTimetableGenerator.php
  FETConstraintBridge.php
Constraints/
  ConstraintManager.php      — orchestrates all constraint checking
  ConstraintFactory.php      — factory for creating constraint instances
  DatabaseConstraintService.php
  TimetableConstraint.php    — base constraint class
  Hard/
    HardConstraint.php
    GenericHardConstraint.php
    TeacherConflictConstraint.php
  Soft/
    SoftConstraint.php
    GenericSoftConstraint.php
Solver/
  Slot.php
  SlotEvaluator.php
  SlotGenerator.php
  TimetableSolution.php
Storage/
  TimetableStorageService.php
ActivityScoreService.php
RoomAvailabilityService.php
SubActivityService.php
EXTRA_delete_10_02/          (13 archived files — old constraint implementations)
```

**Hard constraints currently implemented:**
1. TeacherConflictConstraint — same teacher can't be double-booked
2. RoomAvailabilityConstraint
3. BreakConstraint
4. LunchBreakConstraint
5. ShortBreakConstraint
6. MaximumDailyLoadConstraint — max activities per day per class
7. NoSameSubjectSameDayConstraint — same subject max once per day
8. HighPriorityFixedPeriodConstraint
9. DailySpreadConstraint
10. FixedPeriodForHighPriorityConstraint
11. GenericHardConstraint (for DB-loaded constraints)

**Soft constraints implemented:**
1. PreferredTimeOfDayConstraint
2. GenericSoftConstraint (for DB-loaded constraints)

### Models (`app/Models/`) — All 84 with Table Names

**Core Scheduling:**
| Model | Table |
|-------|-------|
| Activity | tt_activities |
| SubActivity | tt_sub_activities |
| Timetable | tt_timetables |
| TimetableCell | tt_timetable_cells |
| TimetableCellTeacher | tt_timetable_cell_teachers |
| ActivityTeacher | tt_activity_teachers |
| PriorityConfig | tt_priority_configs |
| ActivityPriority | tt_activity_priorities |

**Requirements & Configuration:**
| Model | Table |
|-------|-------|
| RequirementConsolidation | tt_requirement_consolidations |
| ClassSubjectGroup | tt_class_subject_groups |
| ClassSubjectSubgroup | tt_class_subject_subgroups |
| ClassSubgroupMember | tt_class_subgroup_members |
| ClassRequirementGroup | tt_class_requirement_groups |
| ClassRequirementSubgroup | tt_class_requirement_subgroups |
| SlotRequirement | tt_slot_requirements |
| ClassTimetableType | tt_class_timetable_type_jnt |
| ClassWorkingDay | tt_class_working_day_jnt ← MISSING tt_ prefix in $table |
| AcademicTerm | sch_academic_term (shared with SchoolSetup) |
| TimetableType | tt_timetable_types |
| PeriodSet | tt_period_sets |
| PeriodSetPeriod | tt_period_set_period_jnt |
| SchoolDay | tt_school_days |
| SchoolShift | tt_shifts |
| WorkingDay | tt_working_day |
| DayType | tt_day_types |
| PeriodType | tt_period_types |
| TeacherAssignmentRole | tt_teacher_assignment_roles |
| TtConfig | tt_config |
| TtGenerationStrategy | tt_generation_strategy |
| ClassModeRule | tt_class_mode_rules |

**Constraints & Validation:**
| Model | Table |
|-------|-------|
| Constraint | tt_constraints |
| ConstraintType | tt_constraint_types |
| ConstraintCategory | tt_constraint_categories |
| ConstraintCategoryScope | tt_constraint_category_scope |
| ConstraintScope | tt_constraint_scopes |
| ConstraintTargetType | tt_constraint_target_types |
| ConstraintGroup | tt_constraint_groups |
| ConstraintGroupMember | tt_constraint_group_members |
| ConstraintTemplate | tt_constraint_templates |
| ConstraintViolation | tt_constraint_violations |
| TeacherUnavailable | tt_teacher_unavailables |
| RoomUnavailable | tt_room_unavailables |
| ConflictDetection | tt_conflict_detections |
| ConflictResolutionOption | tt_conflict_resolution_options |
| ConflictResolutionSession | tt_conflict_resolution_sessions |

**Resource Availability:**
| Model | Table |
|-------|-------|
| TeacherAvailablity | tt_teacher_availabilities |
| TeacherAvailabilityLog | tt_teacher_availability_details ← MISSING tt_ prefix? |
| RoomAvailability | tt_room_availabilities |
| RoomAvailabilityDetail | tt_room_availability_details |

**Generation & Runs:**
| Model | Table |
|-------|-------|
| GenerationRun | tt_generation_runs |
| GenerationQueue | tt_generation_queues |
| ResourceBooking | tt_resource_bookings |
| OptimizationRun | tt_optimization_runs |
| OptimizationIteration | tt_optimization_iterations |
| OptimizationMove | tt_optimization_moves |

**Analytics & Reporting:**
| Model | Table |
|-------|-------|
| AnalyticsDailySnapshot | tt_analytics_daily_snapshots |
| TeacherWorkload | tt_teacher_workloads |
| RoomUtilization | tt_room_utilizations |
| ChangeLog | tt_change_logs |
| BatchOperation | tt_batch_operations |
| BatchOperationItem | tt_batch_operation_items |

**Approval Workflow:**
| Model | Table |
|-------|-------|
| ApprovalWorkflow | tt_approval_workflows |
| ApprovalRequest | tt_approval_requests |
| ApprovalLevel | tt_approval_levels |
| ApprovalDecision | tt_approval_decisions |
| ApprovalNotification | tt_approval_notifications |
| EscalationRule | tt_escalation_rules |
| EscalationLog | tt_escalation_logs |
| RevalidationSchedule | tt_revalidation_schedules |
| RevalidationTrigger | tt_revalidation_triggers |

**Substitution:**
| Model | Table |
|-------|-------|
| TeacherAbsences | tt_teacher_absences |
| SubstitutionLog | tt_substitution_logs |
| SubstitutionPattern | tt_substitution_patterns |
| SubstitutionRecommendation | tt_substitution_recommendations |

**Advanced / ML:**
| Model | Table |
|-------|-------|
| WhatIfScenario | tt_what_if_scenarios |
| ImpactAnalysisSession | tt_impact_analysis_sessions |
| ImpactAnalysisDetail | tt_impact_analysis_details |
| VersionComparison | tt_version_comparisons |
| VersionComparisonDetail | tt_version_comparison_details |
| MlModel | tt_ml_models |
| TrainingData | tt_training_data |
| FeatureImportance | tt_feature_importances |
| PredictionLog | tt_prediction_logs |
| PatternResult | tt_pattern_results |

---

## 6. SCHEMA NAMING ISSUES (Critical — from schema_vs_laravel_crossref.md)

The `schema_vs_laravel_crossref.md` document in `databases/_docs/ai/knowledge/` identifies a **CRITICAL** systematic issue:

**Schema (DDL) uses SINGULAR table names; Laravel models use PLURAL.**

Examples:
| Schema Table (correct) | Laravel $table (wrong) |
|------------------------|------------------------|
| tt_activity | tt_activities |
| tt_timetable | tt_timetables |
| tt_timetable_cell | tt_timetable_cells |
| tt_generation_run | tt_generation_runs |
| tt_constraint | tt_constraints |
| tt_teacher_workload | tt_teacher_workloads |
| tt_substitution_log | tt_substitution_logs |

This affects 20+ tables. Decision needed: update schema to plural OR update all Laravel `$table` definitions to singular. **Schema should be source of truth.**

**Tables in Laravel with missing `tt_` prefix:**
- `ClassWorkingDay` → `class_working_days` (should be `tt_class_working_days`)
- `TeacherAvailabilityLog` → `teacher_availability_logs` (should be `tt_teacher_availability_logs`)

**Laravel tables NOT in any schema file (need to be added):**
- `tt_config` (TtConfig)
- `tt_generation_strategy` (TtGenerationStrategy)
- `tt_conflict_detections` (ConflictDetection)
- `tt_requirement_consolidations` (RequirementConsolidation)
- `tt_resource_bookings` (ResourceBooking)
- `tt_slot_requirements` (SlotRequirement)
- `tt_constraint_category_scope` (ConstraintCategoryScope)
- `tt_class_subject_groups` (ClassSubjectGroup)

---

## 7. ROUTES STRUCTURE

All SmartTimetable routes are in `/Users/bkwork/Herd/laravel/routes/tenant.php` starting at **line 1732**.

```php
Route::middleware(['auth', 'verified'])
    ->prefix('smart-timetable')
    ->name('smart-timetable.')
    ->group(function () { ... });
```

### Main Timetable Routes (SmartTimetableController)
| Route | Method | Controller Method | Name |
|-------|--------|-------------------|------|
| smart-timetable/test-seeder | GET | seederTest | — |
| smart-timetable-management | resource | CRUD | smart-timetable-management.* |
| smart-timetable/generate/random | GET | generate | smart-timetable-management.generate |
| smart-timetable/generate/generate-fet | POST | generateWithFET | smart-timetable-management.generate-fet |
| smart-timetable/generate/{class}/{section}/generate | GET | generateForClassSection ❌ MISSING | smart-timetable-management.generate-for-class-section |
| smart-timetable/store | POST | storeTimetable | smart-timetable-management.store-timetable |
| smart-timetable/preview/{timetable} | GET | preview | timetable.preview |
| smart-timetable/timetable-opration | GET | timetableOperation | timetable.timetableOperation |
| smart-timetable/timetable-master | GET | timetableMaster | timetable.timetableMaster |
| smart-timetable/timetable-generation | GET | timetableGeneration | timetable.timetableGeneration |
| smart-timetable/timetable-reports | GET | timetableReports | timetable.timetableReports |
| smart-timetable/timetable-config | GET | timetableConfig | timetable.timetableConfig |
| smart-timetable/validation | GET | timetableValidation | timetable.validation |

### Sub-Routes (other controllers)
| Prefix | Controller |
|--------|-----------|
| class-subject-group/generate-class-groups | ClassSubjectGroupController ❌ MISSING |
| class-subject-subgroup/update/sharing | ClassSubjectGroupController ❌ MISSING |
| class-subgroup (resource) | ClassSubgroupController ❌ MISSING |
| school-day (resource + extras) | SchoolDayController |
| slot-requirement (resource + generate) | SlotRequirementController |
| teacher-availabilty (resource + generate) | TeacherAvailabilityController |
| shift (resource + extras) | SchoolShiftController |
| day-type (resource + extras) | DayTypeController |
| working-day (resource + ajax) | WorkingDayController |
| period-type (resource + extras) | PeriodTypeController |
| period (resource + extras) | PeriodController |
| period-set-period (resource + extras) | PeriodSetPeriodController |
| period-set (resource + extras) | PeriodSetController |
| constraint-type (resource + extras) | ConstraintTypeController |
| constraint (resource + extras) | ConstraintController |
| teacher-unavailable (resource + extras) | TeacherUnavailableController |
| room-unavailable (resource + extras) | RoomUnavailableController |
| teacher-assignment-role (resource + extras) | TeacherAssignmentRoleController |
| class-subject-subgroup (resource + sections ajax) | ClassSubjectSubgroupController |
| requirement-consolidation (resource + generate) | RequirementConsolidationController |
| timing-profile (resource + extras) | TimingProfileController |
| activity (resource + generate-activities + bulk) | ActivityController |
| timetable-type (resource + extras) | TimetableTypeController |
| timetable (resource + extras) | TimetableController |
| school-timing-profile (resource + extras) | SchoolTimingProfileController |
| tt-config (resource + extras) | TtConfigController |
| academic-term (resource + extras) | AcademicTermController |
| generation-strategies (resource + toggle-default) | TtGenerationStrategyController |

---

## 8. SMARTTIMETABLECONTROLLER — KEY METHODS

File: `app/Http/Controllers/SmartTimetableController.php` (2,993 lines)

| Method | Line | Purpose |
|--------|------|---------|
| `index()` | 88 | List timetables |
| `generate(Request)` | 212 | Basic generation |
| `generateWithFET(Request)` | 2482 | **MAIN generation endpoint — calls FETSolver** |
| `storeTimetable(Request)` | 486 | Saves generated timetable to DB |
| `preview(Timetable)` | 341 | Preview generated timetable |
| `timetableConfig()` | 1255 | Config page |
| `timetableOperation()` | 1276 | Operations page |
| `timetableMaster()` | 1634 | Masters page |
| `timetableGeneration()` | 1709 | Generation page |
| `timetableReports(Request)` | 1733 | Reports page |
| `timetableValidation()` | 2094 | Validation page |
| `saveGeneratedTimetable(Request)` | 2828 | Save with full records |
| `buildPlacementDiagnostics(...)` | 2913 | Build diagnostics data (private) |
| `createConstraintManager(...)` | 245 | Build ConstraintManager (private) |
| `createConstraintManagerFromDatabase()` | 299 | Load constraints from DB (private) |
| `loadActivities(...)` | 767 | Load activities (private) |
| `loadActivitiesForActiveClassSections()` | 790 | Load for active sections (private) |
| `seederTest()` | 2988 | **DEBUG — should be removed** |
| `debugPlacementIssue()` | 961 | **DEBUG — should be removed** |
| `debugPeriods()` | 1065 | **DEBUG — should be removed** |
| `diagnoseLunchProblem()` | 1194 | **DEBUG — should be removed** |
| `debugActivityDurations()` | 1194 | **DEBUG — should be removed** |

---

## 9. ACTIVITYCONTROLLER — KEY METHODS

File: `app/Http/Controllers/ActivityController.php` (1,758 lines)

| Method | Line | Purpose |
|--------|------|---------|
| `index()` | 37 | List activities |
| `generateActivities()` | 49 | **MAIN: generates all tt_activity records from requirements** |
| `store(Request)` | 970 | Manual activity creation |
| `show($id)` | 1140 | View activity |
| `edit($id)` | 1148 | Edit form |
| `update(Request, $id)` | 1156 | Update activity |
| `destroy($id)` | 1341 | Soft delete |
| `trashedActivity()` | 1390 | List trashed |
| `forceDelete($id)` | 1401 | Hard delete |
| `restore($id)` | 1425 | Restore deleted |
| `toggleStatus(Request, Activity)` | 1447 | Toggle active/inactive |
| `getRoomCapacity(...)` | 1501 | Private: get room capacity |
| `calculateGroupsNeeded(...)` | 1559 | Private: calculate groups |
| `assignTeacherToActivity(...)` | 1579 | Private: teacher assignment |
| `findBestTeacherForActivity(...)` | 1682 | Private: smart teacher selection |

**Known issues with `generateActivities()`** (from DOCS):
1. TRUNCATES tt_activity without transaction — data loss if subsequent steps fail
2. N+1 query problem — can generate 1000+ queries for large datasets
3. No input validation before truncation
4. Teacher assignment partially random (improved in March 2026 but still some randomness)
5. Does not handle SubActivities for shared groups properly in all cases

---

## 10. IMPLEMENTATION STATUS BY PROCESS PHASE

### Phase 0 — Prerequisites Setup
| Component | Status | Notes |
|-----------|--------|-------|
| tt_config CRUD | ✅ Done | TtConfigController |
| tt_shift CRUD | ✅ Done | SchoolShiftController |
| tt_day_type CRUD | ✅ Done | DayTypeController |
| tt_period_type CRUD | ✅ Done | PeriodTypeController |
| tt_teacher_assignment_role CRUD | ✅ Done | TeacherAssignmentRoleController |
| Seeders for all the above | ✅ Done | 13 seeders |

### Phase 1 — Academic Term & Timetable Type Setup
| Component | Status | Notes |
|-----------|--------|-------|
| sch_academic_term CRUD | ✅ Done | AcademicTermController (shared with SchoolSetup) |
| tt_timetable_type CRUD | ✅ Done | TimetableTypeController |
| tt_period_set CRUD | ✅ Done | PeriodSetController |
| tt_period_set_period_jnt CRUD | ✅ Done | PeriodSetPeriodController |
| tt_school_days CRUD | ✅ Done | SchoolDayController |
| tt_working_day CRUD + ajax init | ✅ Done | WorkingDayController |
| tt_class_timetable_type_jnt | ⚠️ Partial | ClassTimetableType model exists; no dedicated controller found |

### Phase 2 — Requirement Generation
| Component | Status | Notes |
|-----------|--------|-------|
| tt_slot_requirement CRUD + generate | ✅ Done | SlotRequirementController::generateSlotRequirement() |
| tt_class_requirement_groups | ⚠️ Partial | ClassRequirementGroup model exists; no dedicated CRUD controller |
| tt_class_requirement_subgroups | ⚠️ Partial | ClassRequirementSubgroup model exists; ClassSubjectSubgroupController handles partially |
| tt_requirement_consolidation CRUD + generate | ✅ Done | RequirementConsolidationController::generateRequirements() |
| ClassSubjectGroup generation | ❌ Missing | ClassSubjectGroupController does NOT exist (referenced in routes) |
| User-editable preferred_periods_json, avoid_periods_json | ⚠️ Partial | updateRequirement() and updatePeriods() routes exist |

### Phase 3 — Resource Availability
| Component | Status | Notes |
|-----------|--------|-------|
| tt_teacher_availability CRUD + generate | ✅ Done | TeacherAvailabilityController::generateTeacherAvailability() |
| tt_teacher_unavailable CRUD | ✅ Done | TeacherUnavailableController |
| tt_room_unavailable CRUD | ✅ Done | RoomUnavailableController |
| tt_room_availability | ⚠️ Partial | Model exists; no dedicated controller; full generation logic unclear |
| Teacher availability score calculation (Steps 3–9 from Process_execution) | ⚠️ Unclear | SQL logic from Process_execution_v1 may not be fully in generateTeacherAvailability() |

### Phase 4 — Validation
| Component | Status | Notes |
|-----------|--------|-------|
| Validation page | ✅ Done | timetableValidation() → views/validation/ |
| Teacher coverage validation | ⚠️ Partial | Basic checks exist in pre-generation logic |
| Room coverage validation | ⚠️ Partial | Basic checks |
| PASSED/FAILED/BLOCKED scoring framework | ❌ Not implemented | Process_Flow_v3 describes detailed scoring; not in code |
| Constraint compatibility matrix | ❌ Not implemented | |

### Phase 5 — Activity Creation
| Component | Status | Notes |
|-----------|--------|-------|
| tt_activity generation | ✅ Done | ActivityController::generateActivities() (970+ lines) |
| Difficulty score calculation | ✅ Done | ActivityScoreService |
| Priority score calculation | ✅ Done | In generateActivities() |
| tt_sub_activity creation | ⚠️ Partial | SubActivityService exists; integration with generateActivities() partial |
| tt_activity_teacher mapping | ✅ Done | assignTeacherToActivity() + ActivityTeacher model |
| Batch generation (generateAllActivities) | ❌ Missing | Method not in controller; route exists |

### Phase 6 — Timetable Generation
| Component | Status | Notes |
|-----------|--------|-------|
| FETSolver (backtracking + greedy) | ✅ Done | FETSolver.php (2,233 lines) |
| generateWithFET() endpoint | ✅ Done | SmartTimetableController line 2482 |
| storeTimetable() / saveGeneratedTimetable() | ✅ Done | Creates TimetableCell + TimetableCellTeacher records |
| tt_conflict_detection recording | ✅ Done | During solver execution |
| tt_resource_booking recording | ⚠️ Partial | ResourceBooking model exists; full recording may be partial |
| Tabu Search optimization | ❌ Not implemented | |
| Simulated Annealing optimization | ❌ Not implemented | |
| Genetic Algorithm optimization | ❌ Not implemented | |
| Generation strategy selector | ❌ Not implemented | TtGenerationStrategy model/seeder exist but not wired |
| Queue-based async generation | ❌ Not implemented | No Jobs; generation is synchronous |

### Phase 7 — Post-Generation Processing
| Component | Status | Notes |
|-----------|--------|-------|
| Timetable preview view | ✅ Done | preview() → views/preview/ |
| timetableReports() page | ✅ Done | Multiple sub-views in reports/ |
| TeacherWorkload calculation | ⚠️ Partial | Model exists; full computation from AnalyticsService unclear |
| RoomUtilization calculation | ⚠️ Partial | Model exists; computation unclear |
| AnalyticsDailySnapshot | ⚠️ Partial | Model exists |
| Approval workflow (full multi-level) | ⚠️ Partial | Models (ApprovalWorkflow etc.) exist; UI/workflow implementation unclear |
| Manual refinement (cell lock/unlock) | ⚠️ Partial | ChangeLog model + views; full drag-drop UI unclear |
| What-If scenarios | ⚠️ Partial | WhatIfScenario model exists; full implementation unclear |
| Timetable publication | ⚠️ Partial | TimetableController exists; publish workflow unclear |

### Phase 8 — Substitution Management
| Component | Status | Notes |
|-----------|--------|-------|
| Models (TeacherAbsences, SubstitutionLog, Pattern, Recommendation) | ✅ Done | All 4 models exist |
| Full substitution finder UI | ❌ Unclear | No dedicated SubstitutionController found |
| Pattern learning | ❌ Unclear | SubstitutionPattern model exists; computation unclear |

---

## 11. SEEDERS (13 Total)

Location: `database/seeders/`

| Seeder | Seeds |
|--------|-------|
| TtConfigSeeder | tt_config: defaults (8 periods/day, 6 days/week, etc.) |
| ConstraintCategorySeeder | tt_constraint_categories |
| ConstraintScopeSeeder | tt_constraint_scopes |
| ConstraintTargetTypeSeeder | tt_constraint_target_types |
| ConstraintTypeSeeder | tt_constraint_types (~50+ types) |
| DaySeeder | Basic day data |
| DayTypeSeeder | STUDY_DAY, EXAM_DAY, HOLIDAY, PTM_DAY, SPORTS_DAY |
| GenerationStrategySeeder | RECURSIVE_FAST, HYBRID_BALANCED, GENETIC_THOROUGH, TABU_OPTIMIZED |
| PeriodSeeder | Period definitions |
| PeriodTypeSeeder | TEACHING, BREAK, LUNCH, ASSEMBLY, FREE |
| SchoolTimingProfileSeeder | School timing profiles |
| TimingProfileSeeder | Timing profiles |
| SmartTimetableDatabaseSeeder | Master seeder calling all above |

---

## 12. VIEWS STRUCTURE

Location: `resources/views/`

Key view directories:
- `smart-timetable/partials/` — 23+ subdirectories covering all sub-sections
- `generate-timetable/` through `generate-timetable_5/` — multiple versions of generation UI
- `validation/` — validation views with partials
- `preview/` — timetable preview
- `activity/`, `constraint/`, `requirement-consolidation/` etc. — each sub-system has dedicated views
- `components/layouts/` — reusable layout components

---

## 13. KNOWN ISSUES & TECHNICAL DEBT

### Critical (data integrity risks)
1. **`generateActivities()` has no transaction** — if step 3 fails after TRUNCATE, all activity data is lost
2. **N+1 query problem in `generateActivities()`** — loads teacher capabilities in a loop; with 300 activities can generate 1000+ queries
3. **No input validation before truncation** — calling generateActivities() with wrong academic_term_id silently destroys data
4. **`ClassSubjectGroupController` is missing** — routes calling it will throw 500 errors

### High (functional gaps)
5. **3 missing controllers** cause broken routes: ClassSubjectGroupController, ClassSubgroupController (old routes), ClassGroupRequirementController
6. **3 missing methods** cause broken routes: generateAllActivities, getBatchGenerationProgress, generateForClassSection
7. **Schema naming mismatch** (singular DDL vs plural Laravel) — will cause issues when running fresh migrations
8. **No DB migrations** — only raw DDL; cannot use `php artisan migrate`

### Medium (code quality)
9. **Backup file** `SmartTimetableController_29_01_before_store.php` still in controllers folder
10. **5 debug methods** still in SmartTimetableController (`seederTest`, `debugPlacementIssue`, `debugPeriods`, `diagnoseLunchProblem`, `debugActivityDurations`)
11. **Algorithm is simpler than designed** — no Tabu/SA/Genetic implemented despite TtGenerationStrategy model/seeders existing for them
12. **`generateActivities()` teacher assignment** — improved in March 2026 but still partially random; can produce different results on successive runs

### Low (cleanup)
13. Duplicate route registrations in tenant.php (period resource registered twice, school-timing-profile resource registered twice)
14. Route typo: `timetable-opration` (missing 'e') — may cause UI confusion

---

## 14. MODULE CONFIGURATION

### `config/config.php`
```php
return [
    'name' => 'SmartTimetable',
    'fet_solver' => [
        'max_attempts' => 1,
        'max_total_time_seconds' => 300,
    ],
];
```

### Algorithm Config (within FETSolver / SmartTimetableController)
```php
'solver' => [
    'backtrack_timeout' => 25,    // seconds — upgraded from 5 in March 2026
    'max_iterations' => 50000,
    'max_backtracks' => 2000,
],
'features' => [
    'class_teacher_first_lecture' => false,
    'single_activity_once_per_day' => true,
    'pin_activities_by_period' => false,
    'enable_what_if' => true,
    'enable_approval_workflow' => true,
],
```

### .env variables
```
TIMETABLE_GENERATION_TIMEOUT=600
TIMETABLE_MAX_COVERAGE_PERCENTAGE=95
TIMETABLE_LOG_DIAGNOSTICS=true
TIMETABLE_ENABLE_WHAT_IF=true
```

---

## 15. DATA FLOW (COMPLETE)

```
SchoolSetup Module (source data)
  sch_classes, sch_sections, sch_class_section_jnt
  sch_subjects, sch_study_formats, sch_subject_study_format_jnt
  sch_teacher_profile, sch_teacher_capabilities
  sch_buildings, sch_rooms_type, sch_rooms
  sch_class_groups_jnt (subject groups per class)
        ↓
[Phase 2] Requirement Generation
  tt_slot_requirement (what slots each class+section needs)
  tt_class_requirement_groups (compulsory subjects)
  tt_class_requirement_subgroups (optional/shared subjects)
  tt_requirement_consolidation (merged, with user editable overrides)
        ↓
[Phase 3] Resource Availability
  tt_teacher_availability (teacher→requirement mapping with scores)
  tt_room_availability (room→requirement mapping)
  tt_constraint (active constraints from DB)
        ↓
[Phase 5] Activity Creation
  tt_activity (each row = 1 Class+Section+Subject+StudyFormat combo)
  tt_sub_activity (for split/parallel activities)
  tt_activity_teacher (eligible teachers per activity)
        ↓
[Phase 6] FETSolver::solve()
  Expands activities × weekly_periods → activity instances
  Backtracking CSP placement with constraint checking
  Creates: tt_timetable (header)
           tt_timetable_cell (one per placed period: day+period+class+room)
           tt_timetable_cell_teacher (teacher assigned to each cell)
           tt_conflict_detection (unplaced activities with reasons)
        ↓
[Phase 7] Preview → Approve → Publish
  tt_approval_request (workflow)
  tt_teacher_workload, tt_room_utilization (analytics)
  tt_analytics_daily_snapshot
        ↓
[Phase 8] Substitution
  tt_teacher_absence → tt_substitution_recommendation → tt_substitution_log
```

---

## 16. EXTERNAL DEPENDENCIES

| Module | What SmartTimetable Uses |
|--------|--------------------------|
| SchoolSetup | sch_classes, sch_sections, sch_class_section_jnt, sch_subjects, sch_study_formats, sch_subject_study_format_jnt, sch_teacher_profile, sch_teacher_capabilities, sch_buildings, sch_rooms, sch_class_groups_jnt |
| StudentProfile | std_student_academic_sessions (for student counts in sections) |
| Prime | Authentication, AcademicSession |
| Notification | Email/SMS for approval notifications |

---

## 17. DOCS FILES — WHAT EACH ONE COVERS

All in `/Users/bkwork/Herd/laravel/Modules/SmartTimetable/DOCS/`:

| File | Key Contents |
|------|-------------|
| `README_AND_INDEX.md` | Navigation index, March 2026 improvements summary, performance stats, common workflows, troubleshooting guide, FAQ |
| `MODULE_ARCHITECTURE_OVERVIEW.md` | Full architecture diagram, data flow, component descriptions, dependencies |
| `FET_SOLVER_DETAILED_GUIDE.md` | Backtracking algorithm details, greedy fallback, configuration options, statistics, performance comparison |
| `CONSTRAINT_SYSTEM_GUIDE.md` | All 13+ hard constraints, 1 soft constraint, ConstraintManager internals, impact analysis |
| `MODELS_AND_DATA_STRUCTURE.md` | 85+ model docs with relationships, schema, usage examples |
| `API_AND_CONTROLLERS_GUIDE.md` | REST endpoints, controller documentation, request/response examples, error handling |
| `PLACEMENT_DIAGNOSTICS.md` | Failure reason categories (6 types), how diagnostics data is structured, debugging tips |
| `FET_GENERATION_ANALYSIS.md` | 4 complete generation cycle comparisons, greedy vs backtracking, why Attempt 4 got 100% |
| `FET_IMPROVEMENT_PLAN.md` | Phase 1–3 roadmap: quick wins, structural improvements, advanced features (Tabu/SA/Genetic) |
| `HOW_TO_GUARANTEE_SUCCESS.md` | 3 critical improvements implemented (timeout, smart teacher, monitoring), testing scripts |
| `COMPREHENSIVE_ANALYSIS_generateActivities.md` | Deep dependency analysis of generateActivities(), 15+ critical findings, performance analysis |
| `FUNCTION_ANALYSIS_generateActivities.md` | 14 specific issues in generateActivities(), improved version skeleton |
| `FUNCTION_ANALYSIS_generateClassSubjectGroups.md` | Issues in generateClassSubjectGroups(), improvements, before/after metrics |

---

## 18. NEXT STEPS / WHAT NEEDS TO BE DONE

Based on the gap analysis, these are the pending work items in priority order:

### Priority 1 — Fix Broken Routes (Critical)
1. Create `ClassSubjectGroupController` with methods: `generateClassSubjectGroups()`, `updateSharing()`
2. Verify if `ClassSubgroupController` routes should point to `ClassSubjectSubgroupController` (likely rename/redirect)
3. Add `generateAllActivities()` and `getBatchGenerationProgress()` to `ActivityController`
4. Add `generateForClassSection()` to `SmartTimetableController`

### Priority 2 — Code Cleanup
5. Delete `SmartTimetableController_29_01_before_store.php`
6. Remove debug methods from `SmartTimetableController`: `seederTest`, `debugPlacementIssue`, `debugPeriods`, `diagnoseLunchProblem`, `debugActivityDurations`
7. Fix duplicate route registrations (period and school-timing-profile registered twice)
8. Fix route typo `timetable-opration` → `timetable-operation`

### Priority 3 — Core Logic Improvements
9. Wrap `generateActivities()` in a DB transaction with proper rollback
10. Fix N+1 query problem in `generateActivities()` (batch load teacher capabilities)
11. Add input validation before TRUNCATE operations in generation methods
12. Complete `generateTeacherAvailability()` Steps 3–9 from `4-Process_execution_v1.md`

### Priority 4 — Process Flow Alignment
13. Implement proper Phase 4 Validation framework (PASSED/FAILED/BLOCKED scoring)
14. Complete Phase 7 Analytics pipeline (TeacherWorkload, RoomUtilization computation)
15. Complete Phase 7 Approval workflow UI
16. Complete Phase 8 Substitution management UI

### Priority 5 — Algorithm Enhancement
17. Implement Tabu Search optimization layer (Phase 2 of generation)
18. Wire `TtGenerationStrategy` to actual different algorithm implementations
19. Consider async Queue-based generation for large schools

### Priority 6 — Schema Alignment
20. Decide: update schema to plural OR update all Laravel `$table` to singular
21. Add missing tables to DDL (`tt_config`, `tt_generation_strategy`, etc.)
22. Fix `tt_` prefix on `ClassWorkingDay` and `TeacherAvailabilityLog`
23. Create DB migrations from DDL files

---

## 19. GENERATION MENU STRUCTURE (from DDL & Process Execution)

The module's UI menu (from `1-tt_timetable_ddl_v7.6.sql` comments):
```
Smart Timetable (Top Menu)
├── 1. Pre-Requisites Setup
│   ├── 1.1 Buildings (from SchoolSetup)
│   ├── 1.2 Room Types (from SchoolSetup)
│   ├── 1.3 Rooms (from SchoolSetup)
│   ├── 1.4 Teacher Profile (from SchoolSetup)
│   ├── 1.5 Class & Section (from SchoolSetup)
│   ├── 1.6 Subject & Study Format (from SchoolSetup)
│   └── 1.7 School Class Group (from SchoolSetup)
├── 2. Timetable Configuration
│   ├── 2.1 Timetable Config
│   ├── 2.2 Academic Terms
│   └── 2.3 Timetable Generation Strategy
├── 3. Timetable Masters
│   ├── 3.1 Shift
│   ├── 3.2 Day Type
│   ├── 3.3 Period Type
│   ├── 3.4 Teacher Roles
│   ├── 3.5 School Days
│   ├── 3.6 Working Days
│   ├── 3.7 Class Working days
│   ├── 3.8 Period Set (tt_period_set + tt_period_set_period_jnt)
│   ├── 3.9 Timetable Type
│   └── 3.10 Class Timetable
├── 4. Timetable Requirement
│   ├── 4.1 Slot Requirement
│   ├── 4.2 Class Requirement Group
│   ├── 4.3 Class Requirement Sub-Group
│   └── 4.4 Class Requirement Consolidation
├── 5. Timetable Constraint Engine
│   ├── 5.1 Constraint Category & Scope
│   ├── 5.2 Constraint Type
│   ├── 5.3 Constraint Creation
│   ├── 5.4 Teacher Unavailability
│   └── 5.5 Room Unavailability
├── 6. Timetable Resource Availability
│   ├── 6.1 Teachers Availability
│   ├── 6.2 Teachers Availability Log
│   └── 6.3 Rooms Availability
├── 7. Timetable Preparation
│   ├── 7.1 Activity
│   ├── 7.2 Sub Activity
│   ├── 7.3 Priority Config
│   └── 7.4 Activity Teacher Mapping
├── 8. Timetable Generation
│   ├── 8.1 Timetable Generation (tt_generation_run)
│   ├── 8.2 Conflict Management
│   ├── 8.3 Resource Allocation (tt_resource_booking)
│   ├── 8.4 TT Generation Log
│   └── 8.5 TT Generation Summary
├── 9. Timetable View & Refinement
│   ├── 9.1 Timetable View (Teacher/Class/Room/Subject/Day wise)
│   ├── 9.2 Manual Refinement (tt_timetable_cell)
│   ├── 9.3 Lock Timetable
│   └── 9.4 Publish Timetable
├── 10. Report & Logs
│   ├── 10.1 Class wise Timetable Report
│   ├── 10.2 Teacher wise Timetable Report
│   ├── 10.3 Room wise Timetable Report
│   ├── 10.4 Teacher Workload Analysis
│   ├── 10.5 Rooms Utilization Analysis
│   └── 10.6 Teacher Requirement Analysis
└── 11. Substitute Management
    ├── 11.1 Substitute Requirement
    ├── 11.2 Propose & Approve Substitute
    └── 11.3 Notification for Substitute
```

---

## 20. QUICK REFERENCE — KEY SQL OPERATIONS

### Generate Slot Requirement
```sql
-- Step 1: Direct insert for specific sections
INSERT INTO tt_slot_requirement
SELECT ... FROM tt_class_timetable_type_jnt
WHERE academic_term_id = $id AND timetable_type_id = $id AND applies_to_all_sections = 0;

-- Step 2: Expand to all sections
FOR each class in (SELECT * FROM tt_class_timetable_type_jnt WHERE applies_to_all_sections = 1):
  FOR each section in (SELECT * FROM sch_class_section_jnt WHERE class_id = class.class_id):
    INSERT INTO tt_slot_requirement ...
```

### Update Student Count
```sql
UPDATE sch_class_section_jnt cst
SET cst.actual_total_student = (
    SELECT COUNT(sas.id) FROM std_student_academic_sessions sas
    WHERE sas.academic_session_id = $academic_session_id
      AND sas.class_id = cst.class_id AND sas.section_id = cst.section_id
      AND sas.is_active = 1
);
```

### Teacher Availability Score
```
min_teacher_availability_score = (min_available_periods_weekly / min_allocated_periods_weekly) * 100
max_teacher_availability_score = (max_available_periods_weekly / max_allocated_periods_weekly) * 100
```

### Difficulty Score Formula
```
FINAL_DIFFICULTY =
  (teacher_scarcity * 0.35) +    -- eligible_teacher_count component
  (is_compulsory * 0.20) +       -- compulsory flag
  (workload * 0.15) +            -- required_weekly_periods
  (room_requirement * 0.15) +    -- specific room type needed
  (constraint_count * 0.15)      -- constraints on this activity
```

### Priority Score Formula
```
FINAL_PRIORITY = (
  (resource_scarcity * 25) +     -- room scarcity
  (teacher_scarcity * 25) +      -- teacher scarcity
  ((1 - rigidity_score) * 20) +  -- how many slot options exist
  (workload_balance * 15) +      -- current teacher load
  (subject_difficulty_index * 15)-- subject difficulty from master
) / 100
```

---

**Document created:** 2026-03-10
**Status when created:** Module is functional (generation works at 80%+ success) but has significant gaps vs original design spec
**Next session:** Start with Priority 1 items — fix broken routes (missing controllers/methods)
