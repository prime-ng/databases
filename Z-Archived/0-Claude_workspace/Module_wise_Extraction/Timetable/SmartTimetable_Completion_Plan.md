   # SmartTimetable Module — Completion Plan

## Context
The SmartTimetable module is an enterprise-grade constraint-based timetable generation system for schools. Core generation logic, CRUD operations, and views exist but the module has significant gaps: schema-vs-code naming mismatches, outdated generation algorithm (not aligned with recent schema changes), missing validation/reporting phases, no substitution management, and no manual refinement features. This plan covers all pending work to bring the module to production readiness.

## Current Status Summary

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 0 | Pre-Requisites Setup | 80% — tt_config seeder PENDING, validation report PENDING |
| Phase 1 | Academic Term & TT Type | 90% — validation report PENDING |
| Phase 2 | Requirement Generation | 100% DONE |
| Phase 3 | Resource Availability | 70% — Room/Constraint updates PENDING, scoring OUTDATED |
| Phase 4 | Validation Framework | 30% — Code OUTDATED, most sub-phases PENDING |
| Phase 5 | Activity Creation | 50% — Generation & scoring OUTDATED, sub-activities NOT IMPLEMENTED |
| Phase 6 | Timetable Generation | 40% — Algorithm OUTDATED (pre-schema-changes) |
| Phase 7 | Post-Generation Analytics | 0% — NOT STARTED |
| Phase 8 | Manual Refinement | 0% — NOT STARTED |
| Phase 9 | Publication & Approval | 90% DONE |
| Phase 10 | Substitution Management | 0% — NOT STARTED |

---

## Pre-Step: Branch Creation (FIRST — before any changes)

**Create new branch `Brijesh-timetable` in BOTH repos to preserve existing code:**

1. **databases repo** (`/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases`):
   - `git checkout -b Brijesh-timetable` (from current `Brijesh` branch)

2. **laravel repo** (`/Users/bkwork/Herd/laravel`):
   - `git checkout -b Brijesh-timetable` (from current branch)

3. **Save plan file** to `Working/0-Claude_workspace/Module_wise_Extraction/Timetable/SmartTimetable_Completion_Plan.md`

All changes will be made ONLY on the `Brijesh-timetable` branch. The existing `Brijesh`/`main` branches remain untouched.

---

## PART A: Schema Enhancements Required

### A1. CRITICAL — Resolve Singular vs Plural Naming (Laravel = Source of Truth)

Schema uses SINGULAR table names. Laravel models use PLURAL. **Decision: Laravel is source of truth — update schema DDL files to use PLURAL names.**

**28 tables to rename in schema** (update in `V5/0-timetable_ddl_v7.6.sql` and `tenant_db.sql`):

| Schema Table (CURRENT - Singular) | Correct Name (Laravel - Plural) |
|-----------------------------------|--------------------------------|
| `tt_activity` | `tt_activities` |
| `tt_activity_teacher` | `tt_activity_teachers` |
| `tt_change_log` | `tt_change_logs` |
| `tt_class_mode_rule` | `tt_class_mode_rules` |
| `tt_class_subgroup_member` | `tt_class_subgroup_members` |
| `tt_class_subgroup` | `tt_class_subject_subgroups` (also name differs) |
| `tt_constraint` | `tt_constraints` |
| `tt_constraint_type` | `tt_constraint_types` |
| `tt_constraint_violation` | `tt_constraint_violations` |
| `tt_day_type` | `tt_day_types` |
| `tt_generation_run` | `tt_generation_runs` |
| `tt_period_set` | `tt_period_sets` |
| `tt_period_type` | `tt_period_types` |
| `tt_room_unavailable` | `tt_room_unavailables` |
| `tt_shift` | `tt_shifts` |
| `tt_slot_requirement` | `tt_slot_requirements` |
| `tt_sub_activity` | `tt_sub_activities` |
| `tt_substitution_log` | `tt_substitution_logs` |
| `tt_teacher_absence` | `tt_teacher_absences` |
| `tt_teacher_assignment_role` | `tt_teacher_assignment_roles` |
| `tt_teacher_unavailable` | `tt_teacher_unavailables` |
| `tt_teacher_workload` | `tt_teacher_workloads` |
| `tt_timetable` | `tt_timetables` |
| `tt_timetable_cell` | `tt_timetable_cells` |
| `tt_timetable_cell_teacher` | `tt_timetable_cell_teachers` |
| `tt_timetable_type` | `tt_timetable_types` |
| `tt_conflict_detection` | `tt_conflict_detections` |
| `tt_resource_booking` | `tt_resource_bookings` |

Also rename all FK references, index names, and constraint names that reference these table names.

### A2. CRITICAL — Fix Wrong Table Prefixes

| Model File | Current $table (WRONG) | Correct $table |
|------------|----------------------|----------------|
| ClassWorkingDay.php | `class_working_days` | `tt_class_working_day_jnt` |
| TeacherAvailabilityLog.php | `teacher_availability_logs` | `tt_teacher_availability` |

### A3. Schema Tables Missing from Laravel (Need New Models)

| Schema Table | Purpose | Model to Create |
|-------------|---------|-----------------|
| `tt_class_requirement_groups` | Compulsory subject groups | ClassRequirementGroup.php |
| `tt_class_requirement_subgroups` | Elective subject subgroups | ClassRequirementSubgroup.php |
| `tt_class_working_day_jnt` | Class-specific calendar exceptions | ClassWorkingDay.php (fix existing) |
| `tt_class_timetable_type_jnt` | Class-to-timetable-type mapping | ClassTimetableType.php (verify existing) |
| `tt_activity_priority` | Activity priority scoring | ActivityPriority.php |
| `tt_generation_queue` | Async generation queue | GenerationQueue.php |
| `tt_algorithm_state` | Algorithm state snapshots | AlgorithmState.php |
| `tt_conflict_resolution` | Conflict resolution tracking | ConflictResolution.php |
| `tt_substitution_pattern` | Substitution pattern learning | SubstitutionPattern.php |
| `tt_substitution_recommendation` | AI substitution suggestions | SubstitutionRecommendation.php |
| `tt_analytics_daily_snapshot` | Daily analytics snapshots | AnalyticsDailySnapshot.php |
| `tt_performance_metrics` | Performance metrics tracking | PerformanceMetric.php |

### A4. Laravel Models With No Schema Table (Need Schema DDL)

| Model | Current $table | Action |
|-------|---------------|--------|
| TtConfig.php | `tt_config` | Already in v7.6 schema ✅ |
| TtGenerationStrategy.php | `tt_generation_strategy` | Already in v7.6 schema ✅ |
| ConstraintCategoryScope.php | `tt_constraint_category_scope` | Already in v7.6 schema ✅ |
| RequirementConsolidation.php | `tt_requirement_consolidations` | Schema will be updated to `tt_requirement_consolidations` ✅ |
| ClassSubjectGroup.php | `tt_class_subject_groups` | Schema will be updated to `tt_class_subject_groups` ✅ |

### A5. Merge Latest Schema (v7.6) into tenant_db.sql

File: `2-Tenant_Modules/8-Smart_Timetable/V5/0-timetable_ddl_v7.6.sql` (2,715 lines)
Currently NOT merged into `1-master_dbs/1-DDL_schema/tenant_db.sql`. The tenant_db.sql has an older version of tt_ tables.

---

## PART B: Gap Analysis — What's Built vs What's Needed

### Built & Working
1. Academic Term CRUD (Phase 1)
2. Timetable Type, Period Set, Period Type, Day Type CRUD
3. School Days, Working Days, Shifts management
4. Teacher Assignment Roles
5. Requirement Consolidation (Phase 2) — groups, subgroups, consolidation
6. Slot Requirements
7. Teacher Availability generation (Phase 3.1)
8. Constraint Type & Constraint CRUD (Phase 3.3)
9. Teacher/Room Unavailability CRUD
10. Activity CRUD + auto-generation from requirements (Phase 5)
11. Activity-Teacher & Activity-Room mapping (Phase 5.6-5.7)
12. Core timetable generation algorithm (ImprovedTimetableGenerator)
13. Constraint Manager + Factory + Hard/Soft constraint classes
14. Timetable Storage Service
15. Timetable preview grid view
16. Publication workflow (Phase 9)
17. 150+ Blade views for all CRUD operations
18. 26 active controllers with full CRUD
19. 41 models with relationships
20. Database seeders for master data

### Needs Updating (OUTDATED)
1. **tt_config seeder** — needs alignment with v7.6 schema parameters
2. **Room Availability** (Phase 3.2) — recent schema changes not reflected
3. **Constraint Application** (Phase 3.3) — needs update for new constraint types
4. **Resource Scoring** (Phase 3.4) — formula outdated
5. **Validation Framework** (Phase 4) — code exists but outdated
6. **Activity Generation** (Phase 5.1) — needs v7.6 fields
7. **Difficulty Score Calculation** (Phase 5.2) — formula outdated
8. **Priority Score Calculation** (Phase 5.3) — not fully implemented
9. **Generation Algorithm** (Phase 6) — core works but needs alignment with updated schema, multi-algorithm support, and queue-based execution

### Not Built (PENDING)
1. **Pre-requisite Validation Report** (Phase 0.3)
2. **Phase 1.6 Validation Report** — calendar/period set validation
3. **Phase 3.5 Availability Validation Report** — teacher/room coverage analysis
4. **Phase 4.4 Constraint Compatibility Check** — conflicting constraint detection
5. **Phase 4.6 Manual Intervention & Resolution** — validation overrides
6. **Phase 5.5 Sub-Activity Creation** — splitting multi-period activities
7. **Phase 6.1 Generation Queue** — async queue-based generation (Laravel Jobs)
8. **Phase 6.4-6.6 Advanced Algorithms** — Tabu Search, Simulated Annealing, Genetic Algorithm
9. **Phase 7 Post-Generation Analytics** — teacher workload, room utilization, constraint violations, daily snapshots, performance dashboard, reports
10. **Phase 8 Manual Refinement** — drag-and-drop editing, impact analysis, cell locking, batch operations, change tracking, undo/redo, conflict resolution workflow
11. **Phase 10 Substitution Management** — absence recording, substitute teacher finding, auto-assignment, pattern learning, notifications
12. **API Routes** — only basic REST endpoints exist; missing custom endpoints for generation, preview, validation, reports
13. **Export functionality** — PDF, CSV, Excel, XML timetable exports
14. **Standard Timetable Views** — 8 screen designs exist but no implementation

---

## PART C: Complete Task List

### Stage 1: Schema & Foundation (Priority: CRITICAL)

| # | Task | Files Affected |
|---|------|---------------|
| 1.1 | Update all 28 table names in schema DDL (v7.6 + tenant_db.sql) from singular to plural to match Laravel | `V5/0-timetable_ddl_v7.6.sql`, `tenant_db.sql` |
| 1.2 | Fix 2 models with wrong table prefix (`class_working_days` → `tt_class_working_day_jnt`, `teacher_availability_logs` → `tt_teacher_availability`) | `ClassWorkingDay.php`, `TeacherAvailabilityLog.php` |
| 1.3 | Create 12 new model files for schema tables without models | New files in `app/Models/` |
| 1.4 | Update model `$fillable` arrays to match v7.6 schema columns | All models where columns changed |
| 1.5 | Update model relationships to reflect v7.6 FK changes | Models with new/changed FKs |
| 1.6 | Merge v7.6 schema into `tenant_db.sql` | `1-master_dbs/1-DDL_schema/tenant_db.sql` |
| 1.7 | Clean up backup controller files (dated copies) | Remove `*_03_02_2026*.php` files |
| 1.8 | Update/create migrations for v7.6 schema changes | `database/migrations/` |

### Stage 2: Configuration & Seeders (Priority: HIGH)

| # | Task | Details |
|---|------|---------|
| 2.1 | Update `tt_config` seeder with v7.6 parameters | Add all config keys from schema |
| 2.2 | Create `tt_constraint_category_scope` seeder | 6 categories (TEACHER, CLASS, ACTIVITY, ROOM, STUDENT, GLOBAL) + 4 scopes |
| 2.3 | Create `tt_constraint_type` seeder | 24+ standard constraint types from Constraint_list.md |
| 2.4 | Create `tt_generation_strategy` seeder | RECURSIVE, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID |
| 2.5 | Update `tt_period_type` seeder | Add TEACHING, LAB, BREAK, LUNCH, ASSEMBLY, FREE_PERIOD with workload factors |

### Stage 3: Validation & Reporting (Priority: HIGH)

| # | Task | Phase |
|---|------|-------|
| 3.1 | Build Pre-requisite Validation Report (master data check) | Phase 0.3 |
| 3.2 | Build Calendar/Period Set Validation Report | Phase 1.6 |
| 3.3 | Build Teacher/Room Availability Validation Report | Phase 3.5 |
| 3.4 | Build Constraint Compatibility Check | Phase 4.4 |
| 3.5 | Build Validation Scoring & Decision engine | Phase 4.5 |
| 3.6 | Build Manual Intervention & Override UI | Phase 4.6 |

### Stage 4: Activity & Generation Updates (Priority: HIGH)

| # | Task | Phase |
|---|------|-------|
| 4.1 | Update Room Availability generation for v7.6 schema | Phase 3.2 |
| 4.2 | Update Constraint Application for new constraint types | Phase 3.3 |
| 4.3 | Update Resource Scoring with new formula | Phase 3.4 |
| 4.4 | Update Activity Generation for v7.6 fields | Phase 5.1 |
| 4.5 | Update Difficulty Score Calculation (5-component formula) | Phase 5.2 |
| 4.6 | Implement full Priority Score Calculation | Phase 5.3 |
| 4.7 | Implement Sub-Activity Creation | Phase 5.5 |
| 4.8 | Update ImprovedTimetableGenerator to align with v7.6 schema | Phase 6 |

### Stage 5: Advanced Generation Features (Priority: MEDIUM)

| # | Task | Phase |
|---|------|-------|
| 5.1 | Implement Generation Queue (Laravel Job) | Phase 6.1 |
| 5.2 | Implement Tabu Search conflict resolution | Phase 6.4 |
| 5.3 | Implement Simulated Annealing optimization | Phase 6.5 |
| 5.4 | Implement Genetic Algorithm (optional, for large schools) | Phase 6.6 |
| 5.5 | Implement Solution Evaluation scoring function | Phase 6.7 |
| 5.6 | Implement real-time Conflict Detection & Logging | Phase 6.8-6.9 |
| 5.7 | Implement Resource Booking recording | Phase 6.10 |

### Stage 6: Post-Generation & Reports (Priority: MEDIUM)

| # | Task | Phase |
|---|------|-------|
| 6.1 | Build Teacher Workload Analysis (dashboard + controller) | Phase 7.1 |
| 6.2 | Build Room Utilization Analysis | Phase 7.2 |
| 6.3 | Build Constraint Violation Analysis | Phase 7.3 |
| 6.4 | Build Daily Snapshot system | Phase 7.4 |
| 6.5 | Build Performance Metrics Dashboard | Phase 7.5 |
| 6.6 | Build Report Generation (Class/Teacher/Room views) | Phase 7.6 |
| 6.7 | Add export capabilities (PDF, CSV, Excel) | Phase 7.6 |

### Stage 7: Manual Refinement (Priority: MEDIUM)

| # | Task | Phase |
|---|------|-------|
| 7.1 | Build multi-view timetable display (Teacher/Class/Room/Subject/Day) | Phase 8.1 |
| 7.2 | Implement Cell Lock/Unlock management | Phase 8.2 |
| 7.3 | Implement Drag-and-Drop with Impact Analysis | Phase 8.3 |
| 7.4 | Implement Batch Operations (swap, move, substitute) | Phase 8.4 |
| 7.5 | Implement Change Tracking & Audit Log | Phase 8.5 |
| 7.6 | Build Conflict Resolution Workflow UI | Phase 8.6 |
| 7.7 | Implement Re-validation after manual changes | Phase 8.7 |

### Stage 8: Substitution Management (Priority: MEDIUM)

| # | Task | Phase |
|---|------|-------|
| 8.1 | Build Teacher Absence recording + approval workflow | Phase 10.1 |
| 8.2 | Build Affected Cell Identification | Phase 10.2 |
| 8.3 | Build Substitute Teacher Finder (auto-suggest) | Phase 10.3 |
| 8.4 | Build Substitution Assignment + notification | Phase 10.4 |
| 8.5 | Build Substitution Tracking dashboard | Phase 10.5 |

### Stage 9: API & Integration (Priority: LOW)

| # | Task | Details |
|---|------|---------|
| 9.1 | Add API endpoints for generation, preview, validation | `routes/api.php` |
| 9.2 | Add API endpoints for reports & analytics | `routes/api.php` |
| 9.3 | Add API endpoints for substitution management | `routes/api.php` |
| 9.4 | Implement Standard Timetable views (8 screens from design docs) | New Blade templates |

### Stage 10: Testing & Cleanup (Priority: LOW)

| # | Task | Details |
|---|------|---------|
| 10.1 | Remove debug methods from SmartTimetableController | `debugPlacementIssue()`, `debugPeriods()`, etc. |
| 10.2 | Remove backup controller/view files | `*_03_02_2026*` dated files |
| 10.3 | Add unit tests for generation algorithm | `tests/Feature/SmartTimetable/` |
| 10.4 | Add unit tests for constraint evaluation | `tests/Feature/SmartTimetable/` |
| 10.5 | Add form request validation classes for remaining controllers | `app/Http/Requests/` |

---

## PART D: Key Files Reference

**Schema (latest):** `databases/2-Tenant_Modules/8-Smart_Timetable/V5/0-timetable_ddl_v7.6.sql`
**Consolidated schema:** `databases/1-master_dbs/1-DDL_schema/tenant_db.sql`
**Laravel module:** `/Users/bkwork/Herd/laravel/Modules/SmartTimetable/`
**Controllers:** `Modules/SmartTimetable/app/Http/Controllers/`
**Models:** `Modules/SmartTimetable/app/Models/`
**Services:** `Modules/SmartTimetable/app/Services/`
**Views:** `Modules/SmartTimetable/resources/views/`
**Routes:** `Modules/SmartTimetable/routes/web.php`, `api.php`
**Design docs:** `databases/2-Tenant_Modules/8-Smart_Timetable/V5/`, `Input/`, `Design_docs/`
**Standard TT screens:** `databases/2-Tenant_Modules/8-Standard_Timetable/Design/Scr-*.md`
**Process flow status:** `databases/2-Tenant_Modules/8-Smart_Timetable/V5/1-Process_Flow_Status.md`

---

## Verification Plan

1. **After Stage 1:** Run `php artisan tinker` → verify all 41+ models can query their tables without error
2. **After Stage 2:** Verify seeders populate all master tables correctly via `php artisan db:seed`
3. **After Stage 3:** Run validation endpoints and confirm reports generate for test data
4. **After Stage 4:** Generate a test timetable with updated algorithm and verify placement success rate
5. **After Stage 5:** Queue a generation job and verify async completion
6. **After Stage 6:** Verify all report views render with generated timetable data
7. **After Stage 7:** Test drag-and-drop in browser, verify impact analysis and change logs
8. **After Stage 8:** Test full substitution workflow: absence → find substitute → assign → notify
9. **After Stage 9:** Test all API endpoints via Postman/Insomnia
10. **After Stage 10:** Run full test suite, verify no backup files remain
