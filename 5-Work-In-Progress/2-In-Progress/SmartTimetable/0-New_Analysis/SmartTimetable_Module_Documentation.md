# SmartTimetable Module — Complete Technical Documentation

## Generated: 2026-03-31
## Source: /Users/bkwork/Herd/prime_ai_tarun/Modules/SmartTimetable
## DDL Reference: tt_timetable_ddl_v7.6.sql
## Application: Prime-AI ERP + LMS + LXP (Multi-Tenant SaaS for Indian K-12 Schools)
## Framework: PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0

---

## Summary of what was documented:
```
┌─────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Section │                                               Content                                                │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1       │ Module overview, terminology (30+ terms defined)                                                     │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2       │ Design intent from 19 design documents                                                               │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3       │ File inventory (449 files: 20 controllers, 63 models, 108 services, 176 views)                       │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 4       │ Route inventory (60+ web routes, 11 API endpoints, 26 permission resources)                          │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 5       │ End-to-end user workflow (11 phases)                                                                 │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 6       │ Screen-by-screen walkthrough (15 screens with UI elements, data variables, AJAX)                     │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 7       │ Database schema (43+ tables with columns, indexes, FKs)                                              │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 8       │ Data flow for 24 operations (trigger → processing → DB writes → response)                            │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 9       │ FET algorithm (complete pseudocode: backtracking, greedy, rescue, forced placement, parallel groups) │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 10      │ Constraint engine (24 hard + 60 soft constraint classes, evaluation pipeline)                        │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 11      │ Conflict detection & resolution                                                                      │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 12-18   │ Refinement, parallel groups, lifecycle, substitution, approval, ML stubs                             │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 19-26   │ Validation, resource booking, reports/exports, API, multi-tenancy, permissions                       │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 27-28   │ Configuration options, cross-module dependencies                                                     │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 29      │ Gap analysis (design vs implementation, ~60% complete, 125/155 constraints missing)                  │
├─────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 30-31   │ Method reference index, Table × Operation matrix                                                     │
└─────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
---

## 1. Module Overview & Terminology

### 1.1 Module Purpose

The SmartTimetable module is the **automatic timetable generation and management** subsystem of the Prime-AI platform. It enables Indian K-12 schools to:

1. **Define scheduling requirements** — period structures, shifts, day types, subject-class-teacher assignments
2. **Configure constraints** — 155+ hard and soft rules governing what constitutes a valid timetable
3. **Generate timetables automatically** — using an FET-inspired (Free Educational Timetabler) constraint satisfaction algorithm with recursive swapping, greedy fallback, rescue pass, and forced placement
4. **Preview, refine, and publish** — manual swap/move/lock operations with impact analysis
5. **Manage substitutions** — teacher absence recording, substitute candidate scoring, and pattern-based recommendations
6. **Analyze and report** — workload analysis, room utilization, constraint violations, and distribution metrics

The module is part of a **3-database multi-tenant architecture**:
- `global_db` — shared master data (boards, standards, subjects)
- `prime_db` — SaaS management (tenants, billing, plans)
- `tenant_db` — per-school isolated data (all `tt_*` tables reside here)

### 1.2 Module Identity

| Attribute | Value |
|-----------|-------|
| Module Name | SmartTimetable |
| Module Alias | smarttimetable |
| Namespace | `Modules\SmartTimetable` |
| Table Prefix | `tt_*` |
| Route Prefix | `/smart-timetable/*` |
| Route Name Prefix | `smart-timetable.` |
| Status | ~60% complete (as of 2026-03-14 gap analysis) |
| Laravel Module System | nwidart/laravel-modules v12.0 |

### 1.3 Module Statistics

| Category | Count |
|----------|-------|
| Controllers | 20 (18 main + 1 API + 1 base) |
| Models | 63 |
| Services | 108 (8 core + 92 constraints + 4 solver + 3 generator + 1 storage) |
| Form Requests | 7 |
| Policies | 2 |
| Providers | 3 |
| Exceptions | 1 |
| Jobs | 1 |
| Exports | 1 |
| Blade Views | 176 |
| Migrations | 0 (managed via TimetableFoundation module and app-level tenant migrations) |
| Seeders | 14 |
| Factories | 0 |
| Tests | 0 (in this module; some exist in tests/Unit/) |
| Documentation | 31 markdown files |
| Assets | 2 (JS + SCSS) |
| **Total Files** | **449** |

### 1.4 Key Terminology

#### Scheduling Concepts

| Term | Definition |
|------|-----------|
| **Activity** | The atomic scheduling unit: `(Class + Section) + Subject + StudyFormat + Duration + required_weekly_periods`. Example: "Class 10A Mathematics Lecture — 5 periods/week". Each activity requires a teacher, a room, and time slots. |
| **Sub-Activity** | A subdivision of an activity when class size exceeds room capacity or when batched lab/practical sessions are needed. Example: "Class 10A Math Lab — Batch A (30 students)" and "Batch B (30 students)". |
| **Slot** | A single cell in the timetable grid — one specific period on one specific day for one class. Weekly slots = `working_days × periods_per_day` (typically 5 × 8 = 40 slots per class). |
| **Period Set** | A template defining the number and types of periods in a day (e.g., "8-Period Day" with 6 teaching periods + 1 lunch + 1 assembly). Defined in `tt_period_set` and `tt_period_set_period_jnt`. |
| **Study Format** | The delivery method of a subject: Lecture, Lab, Practical, Seminar, Tutorial, Activity, etc. Defined in `sch_study_formats`. Different formats may require different room types and durations. |
| **Subject Type** | Classification of subjects: Major, Minor, Core, Optional, Skill, Co-curricular. Used for constraint evaluation (e.g., "max 2 minor subjects per day"). Defined in `sch_subject_types`. |
| **Shift** | A time block within the school day (Morning, Afternoon). Schools may operate single-shift or two-shift mode. Defined in `tt_shift`. |
| **Day Type** | Classification of days: Working, Holiday, Exam, Special. Defined in `tt_day_type`. |
| **Period Type** | Classification of periods: Theory, Practical, Break, Lunch, Assembly, Free, Zero Period, Exam. Defined in `tt_period_type`. |
| **Timetable Type** | A configuration combining shift + period set + max/min teacher weekly allocations. Multiple timetable types can coexist (e.g., "Regular" vs "Exam Schedule"). Defined in `tt_timetable_type`. |

#### Resource Concepts

| Term | Definition |
|------|-----------|
| **Teacher Availability** | A pre-computed snapshot of each teacher's capacity for each requirement — includes available periods, allocated periods, availability score, proficiency, scarcity index. Stored in `tt_teacher_availability`. |
| **Teacher Availability Ratio (TAR)** | `(allocated_periods / available_periods) × 100%`. Low TAR = flexible teacher; High TAR = heavily loaded. Used in priority scoring. |
| **Scarcity Index** | Measure of teacher supply for an activity: 1 teacher available = 10 (very scarce), 5+ teachers = 1 (abundant). Higher scarcity = scheduled earlier in generation. |
| **Room Availability** | Pre-computed room capacity and utilization snapshot per timetable type. Stored in `tt_room_availability`. |
| **Resource Booking** | Runtime allocation of rooms, labs, and equipment to specific timetable cells. Stored in `tt_resource_booking`. |

#### Constraint Concepts

| Term | Definition |
|------|-----------|
| **Hard Constraint** | A mandatory rule (weight = 100%) that **must never be violated**. Violation prevents valid timetable generation. Examples: no teacher double-booking, no class double-booking, no room double-booking, room capacity ≥ student count. |
| **Soft Constraint** | A preference rule (weight = 1-100%) that is **desired but can be relaxed**. Violations incur penalty scores. Examples: teacher max consecutive periods, balanced subject distribution, preferred rooms. |
| **Constraint Category** | High-level grouping: GLOBAL, TEACHER, CLASS_GROUP, ROOM, ACTIVITY, INTER_ACTIVITY. Stored in `tt_constraint_category_scope` (type=CATEGORY). |
| **Constraint Scope** | Applicability level: GLOBAL, PER_TEACHER, PER_CLASS, PER_ROOM, PER_ACTIVITY. Stored in `tt_constraint_category_scope` (type=SCOPE). |
| **Constraint Type** | A blueprint/template defining a constraint's parameters and validation logic. Has `parameter_schema` (JSON) and `is_hard` flag. Stored in `tt_constraint_type`. |
| **Constraint** | A concrete instance of a constraint type applied to a specific target (teacher, class, room, or globally). Contains `rule_json` with parameters. Stored in `tt_constraint`. |
| **Constraint Violation** | A logged instance where a soft constraint was violated during generation or detected post-generation. Stored in `tt_constraint_violation`. |

#### Algorithm Concepts

| Term | Definition |
|------|-----------|
| **FET Algorithm** | The core generation approach, inspired by the open-source FET (Free Educational Timetabler) software. Uses recursive swapping: sort activities by difficulty, place most difficult first, recursively swap conflicts. |
| **Recursive Swapping** | When no valid slot exists for an activity: find the slot with fewest conflicts, evict conflicting activities, place the current activity, recursively attempt to re-place evicted ones (max depth = 14). |
| **Backtracking** | When recursive swapping fails, undo placements and try alternative slots. Uses a tabu list to prevent infinite loops. |
| **Rescue Pass** | A secondary attempt to place activities that failed in the main pass, with relaxed soft constraints. |
| **Forced Placement** | Last-resort placement of remaining unplaced activities with minimal constraint checking, accepting violations. |
| **Tabu List** | A memory of recently tried (and failed) placements to prevent the algorithm from revisiting the same states. |
| **Priority Score** | A weighted composite score (12+ factors) determining the order in which activities are scheduled. Higher priority = scheduled first. Dynamically recalculated after each placement. |
| **Difficulty Score** | Number of hard + soft constraints on an activity, contributing to scheduling priority. |
| **Generation Run** | An audit record of one timetable generation attempt. Tracks algorithm, config, placement counts, duration, and outcome. Stored in `tt_generation_run`. |

#### Parallel Group Concepts

| Term | Definition |
|------|-----------|
| **Parallel Group** | A set of activities (typically same subject across different sections) that must be scheduled in the **same time slot** simultaneously by different teachers. Example: Classes 6A, 6B, 6C all do "Hobby" at the same period. |
| **Anchor Activity** | Within a parallel group, the designated "lead" activity that is placed first. Sibling activities are then forced into the same time slot. Marked by `is_anchor = 1` in `tt_parallel_group_activity`. |
| **Sibling Activity** | Non-anchor activities in a parallel group that follow the anchor's placement. |

#### Workflow Concepts

| Term | Definition |
|------|-----------|
| **Requirement Consolidation** | A flattened view of all class requirements (compulsory groups + optional subgroups) that serves as the single source of truth for activity creation. Stored in `tt_requirement_consolidation`. |
| **Class Requirement Group** | A compulsory subject requirement for a class+section (e.g., "Class 10A must have 5 periods of Mathematics per week"). Stored in `tt_class_requirement_groups`. |
| **Class Requirement Subgroup** | An optional/elective subject requirement (e.g., "Class 11A can choose Economics OR Psychology"). Stored in `tt_class_requirement_subgroups`. |
| **Refinement** | Manual post-generation adjustments: swapping two cells, moving a cell to an empty slot, locking/unlocking cells. Handled by `RefinementService`. |
| **Substitution** | When a teacher is absent, finding and assigning a substitute teacher. Uses scoring (subject match, availability, workload, past patterns). Handled by `SubstitutionService`. |

---

## 2. Intended Design (from Design Documents)

### 2.1 Design Document Inventory

The following design and requirement documents define the **intended** behavior of the SmartTimetable module, as envisioned before and during implementation:

| Document | Location | Purpose |
|----------|----------|---------|
| Timetable_Requirement_v2.md | Design_docs/ | Original requirement specification v2 |
| 0-tt_Requirement_v3.md | Input/ | Most recent requirement specification v3 — 155+ constraint rules, 14 menu items, FET algorithm spec |
| 3-Process_Flow_v3.md | Input/ | 12-step process flow for complete timetable generation lifecycle |
| 4-Process_execution_v1.md | Input/ | Teacher availability calculation with scoring formulas |
| 5-Constraints_v1.csv | Input/ | Full constraint inventory with priority ratings (1-10 scale) |
| 3-Process_Flow_v4.md | V6/ | Enhanced 5-phase process flow with sub-steps |
| 1-tt_Table_Detail.md | V6/ | Role and purpose of each database table |
| 2-tt_Generation_Flow.md | V6/ | 8-phase generation algorithm design intent |
| 4-tt_Validation.md | V6/ | Validation rules and health checks before generation |
| tt_Algoritham.md | Design_docs/ | Algorithm design document |
| Constraint_list.md | Design_docs/ | Full list of all constraints |
| Constraint_evaluation_engine.md | Design_docs/ | Constraint engine design |
| contraint_ProcessPoint.md | Design_docs/ | Constraint application process points |
| Priority_Config.md | Design_docs/ | Priority configuration design |
| tt_Checklist.md | Design_docs/ | Implementation checklist |
| 1-Current_App_Processflow.md | Design_docs/ | Current app process flow |
| 2026Mar10_GapAnalysis_and_CompletionPlan.md | Claude_Context/ | Initial gap analysis — module at 60% |
| 2026Mar14_GapAnalysis_Updated.md | Claude_Context/ | Updated gap analysis — parallel periods completed |
| tt_Constraint_detail.md | Claude_Context/ | Constraint architecture deep dive |

### 2.2 Intended Design Summary

#### 2.2.1 High-Level Workflow (As Designed)

The designers envisioned a **13-step end-to-end workflow** for a school administrator:

```
Step 0: PRE-REQUISITES
  - Academic session, terms, shifts, buildings, rooms, subjects, teachers, classes
  - Master data validated and imported

Step 1: TIMETABLE CONFIGURATION
  - Select academic_term + timetable_type
  - Configure period sets, school days, working days
  - Map timetable types to classes

Step 2: REQUIREMENT GENERATION
  - System auto-generates slot requirements per class
  - System auto-generates class requirement groups (compulsory) and subgroups (elective)
  - Admin reviews/edits preferred periods, avoid periods, spread-evenly flags

Step 3: RESOURCE AVAILABILITY
  - System calculates teacher availability scores (TAR, scarcity, proficiency)
  - System calculates room availability
  - Admin marks teacher/room unavailability periods
  - Admin sets primary/preferred teacher flags

Step 4: CONSTRAINT CONFIGURATION
  - Admin defines school-specific constraints
  - System loads 155+ constraint rules
  - Hard vs soft classification with weights

Step 5: ACTIVITY CREATION
  - System creates activities from consolidated requirements
  - Priority scores calculated using 12-metric formula
  - Activities sorted by difficulty (most constrained first)

Step 6: PRE-GENERATION VALIDATION
  - Slot capacity check: total_required ≤ total_available
  - Teacher period check: total_teacher_availability ≥ total_required
  - Room availability check: rooms_available ≥ rooms_required
  - Master data completeness checks

Step 7: TIMETABLE GENERATION (FET Algorithm)
  - Phase 1: Place fixed activities (assembly, breaks)
  - Phase 2: Main FET loop (recursive swapping with backtracking)
  - Phase 3: Rescue pass for unplaced activities
  - Phase 4: Forced placement (last resort)

Step 8: POST-GENERATION
  - Conflict detection and logging
  - Resource booking population
  - Analytics snapshot generation
  - Quality score calculation

Step 9: OPTIMIZATION
  - Tabu Search optimization pass
  - Simulated Annealing optimization pass
  - Teacher workload balancing
  - Room utilization optimization

Step 10: MANUAL REFINEMENT
  - Two-click swap pattern
  - Impact analysis before swap
  - Lock/unlock individual cells
  - Batch operations with rollback

Step 11: VALIDATION & APPROVAL
  - Re-validate after manual changes
  - Multi-level approval workflow
  - Escalation rules

Step 12: PUBLISH
  - Status transition: DRAFT → GENERATED → APPROVED → PUBLISHED
  - Lock all cells on publish
  - Enable standard timetable views (class/teacher/room)

Step 13: SUBSTITUTION & MAINTENANCE
  - Record teacher absence
  - Score substitute candidates
  - Pattern-based recommendation (ML)
  - Notify affected parties
```

#### 2.2.2 Algorithm Design Intent (FET-Inspired)

The designers chose an approach inspired by the open-source **FET (Free Educational Timetabler)** software:

1. **Sort activities by difficulty** (most constrained first — using 12-metric priority formula)
2. **For each activity, try to place it** in the best available slot (no hard violations, minimal soft violations)
3. **If no valid slot exists**, use **recursive swapping**:
   - For each occupied slot, identify which activities would need to be evicted
   - Choose the slot with the lowest eviction cost
   - Place the current activity, evict the conflicting ones
   - Recursively attempt to place evicted activities (max depth = 14)
4. **If recursive swapping fails**, use **backtracking** with a tabu list to prevent revisiting failed states
5. **Rescue pass**: Re-attempt unplaced activities with relaxed soft constraints
6. **Forced placement**: As a last resort, place remaining activities accepting violations

**Priority Score Formula (12+ factors, all configurable):**

```
Priority_Score =
    25 × Teacher_Scarcity_Score        (1/eligible_teachers — fewer options = higher priority)
  + 20 × Time_Window_Rigidity_Score    (1/allowed_slots — fewer valid times = higher priority)
  + 15 × Resource_Scarcity_Score       (required/available resources)
  + 10 × Weekly_Load_Ratio             (required_periods / total_slots)
  + 10 × (1 / Min_TAR)                (lowest teacher availability ratio)
  +  8 × Contiguity_Penalty           (consecutive period requirement: double=2, triple=3)
  +  7 × Teacher_Coupling             (count of activities sharing same teacher)
  +  5 × Section_Pressure             (total_required / total_slots for section)
```

**Key Design Decision**: Priority is **dynamically recalculated** after each placement because:
- TAR changes when a teacher gets busier
- Slot availability shrinks as the grid fills
- Teacher coupling impact increases as remaining slots overlap
- Historical feedback from backtracking boosts failed activities

#### 2.2.3 Constraint Design Intent (155+ Rules)

The design documents specify **155+ constraint rules** across 10 categories:

| Category | Count | Examples |
|----------|-------|---------|
| A — Hard Rules (Basic) | 5 | No teacher/class/room double-booking, room capacity |
| B1 — Teacher (per-teacher) | 22 | Unavailable periods, max/min periods/day/week, max consecutive, max span, preferred free day |
| B2 — Teacher (global) | 20 | Global max gaps, min resting hours, mutual exclusion |
| C1 — Class (per-class) | 18 | Max/min periods/day, weekly periods, consecutive required, min days spread |
| C2 — Class (global) | 15 | Balanced distribution, begins early, max minor subjects |
| D — Activity-Level | 22+ | Preferred times, consecutive/ordered/grouped activities, min/max days between |
| E — Room/Space | 26 | Room unavailable, max usage, exclusive use, preferred room, max building changes |
| F — DB-Configurable | 25 | Constraints stored in `tt_constraint` table with JSON parameters |
| G — Global Policy | 9 | Max teaching days, balanced distribution, prefer morning |
| H — Inter-Activity | 22 | **Parallel periods** (CRITICAL — completed), same day/hour, not overlapping |

**School-Specific Constraints (13 Additional):**
1. Maths (class 4T): periods 6-8 only
2. Class teachers: 1st period daily
3. Teachers may have >36 periods/week
4. Major subjects: scheduled every day
5. Free period in both halves (periods 1-4 and 5-8)
6. Max 2 minor subjects per day (Games/Library/Art/Hobby/Dance/Music not same day)
7. Optional subject practicals: parallel periods (IP=4, Economics=0, Hindi=0, PHE=2, Psychology=2)
8. Skill subjects: Banking(3), AI(4), Taxation(4), Yoga(4), Mass Media(3)
9. Consecutive periods: Hobby(6-9), Astro(3-8), Robotics(6-8), Practicals(11-12)
10. Parallel periods: Hobby (6-9 groups), Skill (11-12 groups), Optional (11-12)
11. 10+ hobby teachers for assignment
12. 7 optional + 6 skill subject teachers
13. Astro: Monday-Friday only (not Friday for classes 3-5); Wonder Brain: Friday only for classes 3-5

#### 2.2.4 Validation Design Intent

Pre-generation validation was designed as a blocking gate with both automatic and manual checks:

**Automatic System Checks:**
- `Total Weekly Required Periods ≤ Total Slots Available` (per class+section)
- `Total Teacher Availability ≥ Total Required Periods` (per subject+format)
- `Total Rooms in Category ≥ Required Rooms in Category` (by room type)
- At least 1 active academic session
- At least 1 academic term and shift defined
- Class teachers assigned for all class+section records
- `actual_total_student > 0` for all class-sections
- `max_allowed_student > 0` for all class-sections
- `class_house_room_id` NOT NULL for all records
- If `require_class_house_room = 1`, then `required_room_id` NOT NULL

**Manual Checks (User confirmation required):**
- Generation strategy configured?
- Timetable configuration set?
- All constraints reviewed and activated?

#### 2.2.5 Teacher Availability Scoring Design

The design specifies detailed formulas for teacher availability scoring:

```
max_allocated_periods_weekly = SUM(required_weekly_periods) for Class+Subject
min_allocated_periods_weekly = MAX(required_weekly_periods) for each Class+Subject

min_teacher_availability_score = (min_available_periods_weekly / min_allocated_periods_weekly) × 100
max_teacher_availability_score = (max_available_periods_weekly / max_allocated_periods_weekly) × 100

Example: Teacher with 36 min available, 48 max available, needing 30-40 periods
min_score = (36/30) × 100 = 120%
max_score = (48/40) × 100 = 120%
```

**Metrics computed per teacher-requirement pair:**
- `max_available_periods_weekly` — 6-8 periods/day × available_days
- `min_available_periods_weekly` — minimum load based on part-time status
- `proficiency_percentage` — from teacher capabilities
- `teaching_experience_months` — experience metric
- `competency_level` — Novice / Intermediate / Advanced / Expert
- `historical_success_ratio` — past allocation effectiveness
- `scarcity_index` — 1-10, supply scarcity for this requirement

### 2.3 Implementation Status vs Design (Summary)

As of the March 2026 gap analysis:

| Phase | Design Intent | Implementation Status | Key Gaps |
|-------|--------------|----------------------|----------|
| Phase 0 — Master Setup | Full CRUD for all master tables | 95% | Minor validation gaps |
| Phase 1 — Requirements | Auto-generation + user editing | 90% | Bulk regeneration partial |
| Phase 2 — Teacher Availability | Complex scoring with formulas | 85% | Scoring formulas partially implemented |
| Phase 3 — Activity Creation | Priority-scored activities | 80% | Teacher assignment partial |
| Phase 4 — Validation | Blocking pre-gen validation gate | 70% | Only basic checks implemented |
| Phase 5 — Generation | FET solver with all constraint types | 85% | ~30/155 constraints implemented |
| Phase 6 — Analytics | Post-gen analysis + reports | 15% | Mostly not started |
| Phase 7 — Publish & Refinement | Full refinement + approval workflow | 5% | Minimal |
| Phase 8 — Substitution | ML-based substitute recommendation | 0% | Not started |
| Security & Auth | Full authorization on all controllers | 30% | 17/28 controllers have ZERO authorization |
| API & Async | RESTful API + queued generation | 0% | Not started |

**Overall: ~60% complete**

---

## 3. File Inventory & Structure

### 3.1 Controllers

| # | Controller | File Path | Responsibility |
|---|-----------|-----------|---------------|
| 1 | AnalyticsController | `app/Http/Controllers/AnalyticsController.php` | Timetable analytics: workload, utilization, violations, distribution, exports |
| 2 | ConstraintCategoryController | `app/Http/Controllers/ConstraintCategoryController.php` | CRUD for constraint categories with soft delete, trash, restore, toggle-status |
| 3 | ConstraintController | `app/Http/Controllers/ConstraintController.php` | CRUD for constraint instances, category-specific create/edit views |
| 4 | ConstraintScopeController | `app/Http/Controllers/ConstraintScopeController.php` | CRUD for constraint scopes with soft delete management |
| 5 | ConstraintTypeController | `app/Http/Controllers/ConstraintTypeController.php` | CRUD for constraint type blueprints |
| 6 | ParallelGroupController | `app/Http/Controllers/ParallelGroupController.php` | Parallel group CRUD, auto-detect, add/remove activities, set anchor |
| 7 | RefinementController | `app/Http/Controllers/RefinementController.php` | Manual timetable adjustments: swap, move, lock/unlock, candidates, impact analysis |
| 8 | RoomUnavailableController | `app/Http/Controllers/RoomUnavailableController.php` | CRUD for room unavailability periods with soft delete |
| 9 | SmartTimetableController | `app/Http/Controllers/SmartTimetableController.php` | **God controller (~2,958+ lines)**: timetable CRUD, generation triggers, requirement management, teacher availability, activity creation, class subject groups. **SEC-009: ZERO authorization checks.** |
| 10 | SubstitutionController | `app/Http/Controllers/SubstitutionController.php` | Substitution management: absence reporting, candidate selection, assignment, history, approval |
| 11 | TeacherUnavailableController | `app/Http/Controllers/TeacherUnavailableController.php` | CRUD for teacher unavailability periods with soft delete |
| 12 | TimetableExportController | `app/Http/Controllers/TimetableExportController.php` | Export timetables: PDF (class + teacher views), Excel |
| 13 | TimetableGenerationController | `app/Http/Controllers/TimetableGenerationController.php` | Generation triggers: random, FET-based, per-class-section, store timetable |
| 14 | TimetableMenuController | `app/Http/Controllers/TimetableMenuController.php` | Navigation hub: 10 menu landing pages for different feature areas |
| 15 | TimetablePageController | `app/Http/Controllers/TimetablePageController.php` | Dashboard/tab views: operation, master, generation, reports, config, constraint management |
| 16 | TimetablePreviewController | `app/Http/Controllers/TimetablePreviewController.php` | Timetable preview grid, place/remove individual cells |
| 17 | TimetablePublishController | `app/Http/Controllers/TimetablePublishController.php` | Publish and unpublish timetable state transitions |
| 18 | TtGenerationStrategyController | `app/Http/Controllers/TtGenerationStrategyController.php` | CRUD for generation strategy configuration |
| 19 | TimetableApiController | `app/Http/Controllers/Api/TimetableApiController.php` | RESTful API: generate, status polling, view by class/teacher/room |

**Known Issues:**
- SmartTimetableController is a god controller (~2,958+ lines) that needs splitting
- 17/28 controllers have ZERO authorization checks (SEC-009)
- Unprotected `truncate()` calls on 3 core tables (Activities, TeacherAvailability, Requirements)
- Debug `test-seeder` route exposed
- Missing `EnsureTenantHasModule` middleware

### 3.2 Models (with Table Map)

| # | Model | Table | Key Relationships |
|---|-------|-------|-------------------|
| 1 | Activity | `tt_activity` | belongsTo: Timetable, RequirementConsolidation; hasMany: SubActivity, TimetableCell, ActivityTeacher; belongsToMany: ParallelGroup |
| 2 | AnalyticsDailySnapshot | `tt_analytics_daily_snapshot` | belongsTo: Timetable |
| 3 | ApprovalDecision | `tt_approval_decisions` | belongsTo: ApprovalRequest, ApprovalLevel |
| 4 | ApprovalLevel | `tt_approval_levels` | belongsTo: ApprovalWorkflow; hasMany: ApprovalDecision |
| 5 | ApprovalNotification | `tt_approval_notifications` | belongsTo: ApprovalRequest |
| 6 | ApprovalRequest | `tt_approval_requests` | belongsTo: ApprovalWorkflow; hasMany: ApprovalDecision, ApprovalNotification |
| 7 | ApprovalWorkflow | `tt_approval_workflows` | hasMany: ApprovalLevel, ApprovalRequest |
| 8 | BatchOperation | `tt_batch_operations` | hasMany: BatchOperationItem |
| 9 | BatchOperationItem | `tt_batch_operation_items` | belongsTo: BatchOperation |
| 10 | ChangeLog | `tt_change_log` | belongsTo: Timetable |
| 11 | ConflictDetection | `tt_conflict_detection` | belongsTo: Timetable, TimetableCell |
| 12 | ConflictResolutionOption | `tt_conflict_resolution_options` | belongsTo: ConflictResolutionSession |
| 13 | ConflictResolutionSession | `tt_conflict_resolution_sessions` | hasMany: ConflictResolutionOption |
| 14 | Constraint | `tt_constraints` | belongsTo: ConstraintType; polymorphic target (teacher/class/room/global) |
| 15 | ConstraintCategory | `tt_constraint_category_scope` | type=CATEGORY filter on unified table |
| 16 | ConstraintCategoryScope | `tt_constraint_category_scope` | Unified lookup for categories AND scopes, differentiated by `type` ENUM |
| 17 | ConstraintGroup | `tt_constraint_groups` | hasMany: ConstraintGroupMember |
| 18 | ConstraintGroupMember | `tt_constraint_group_members` | belongsTo: ConstraintGroup, Constraint |
| 19 | ConstraintScope | `tt_constraint_category_scope` | type=SCOPE filter on unified table |
| 20 | ConstraintTargetType | `tt_constraint_target_types` | Applicable entity types (TEACHER, CLASS, ROOM, etc.) |
| 21 | ConstraintTemplate | `tt_constraint_templates` | belongsTo: ConstraintType; reusable presets |
| 22 | ConstraintType | `tt_constraint_types` | belongsTo: ConstraintCategoryScope, ConstraintTargetType; hasMany: Constraint |
| 23 | ConstraintViolation | `tt_constraint_violations` | belongsTo: Constraint, Activity |
| 24 | EscalationLog | `tt_escalation_logs` | belongsTo: ApprovalRequest |
| 25 | EscalationRule | `tt_escalation_rules` | belongsTo: ApprovalWorkflow |
| 26 | FeatureImportance | `tt_feature_importance` | belongsTo: MlModel |
| 27 | GenerationQueue | `tt_generation_queues` | Queue management for generation jobs |
| 28 | GenerationRun | `tt_generation_runs` | belongsTo: Timetable; audit log for generation attempts |
| 29 | ImpactAnalysisDetail | `tt_impact_analysis_details` | belongsTo: ImpactAnalysisSession |
| 30 | ImpactAnalysisSession | `tt_impact_analysis_sessions` | hasMany: ImpactAnalysisDetail |
| 31 | MlModel | `tt_ml_models` | hasMany: FeatureImportance, PredictionLog |
| 32 | OptimizationIteration | `tt_optimization_iterations` | belongsTo: OptimizationRun |
| 33 | OptimizationMove | `tt_optimization_moves` | belongsTo: OptimizationIteration |
| 34 | OptimizationRun | `tt_optimization_runs` | hasMany: OptimizationIteration; belongsTo: Timetable |
| 35 | ParallelGroup | `tt_parallel_group` | hasMany: ParallelGroupActivity; belongsTo: Timetable |
| 36 | ParallelGroupActivity | `tt_parallel_group_activity` | belongsTo: ParallelGroup, Activity; has `is_anchor` flag |
| 37 | PatternResult | `tt_pattern_results` | belongsTo: SubstitutionPattern |
| 38 | PeriodSetPeriod | `tt_period_set_period_jnt` | belongsTo: PeriodSet, PeriodType |
| 39 | PredictionLog | `tt_prediction_logs` | belongsTo: MlModel |
| 40 | PriorityConfig | `tt_priority_config` | Configurable priority weights for activity scoring |
| 41 | ResourceBooking | `tt_resource_bookings` | belongsTo: TimetableCell |
| 42 | RevalidationSchedule | `tt_revalidation_schedules` | hasMany: RevalidationTrigger |
| 43 | RevalidationTrigger | `tt_revalidation_triggers` | belongsTo: RevalidationSchedule |
| 44 | RoomAvailability | `tt_room_availability` | hasMany: RoomAvailabilityDetail |
| 45 | RoomUnavailable | `tt_room_unavailable` | Room blackout periods |
| 46 | RoomUtilization | `tt_room_utilizations` | belongsTo: Timetable |
| 47 | SchoolDay | `tt_school_days` | Days of week lookup |
| 48 | SubActivity | `tt_sub_activity` | belongsTo: Activity |
| 49 | SubstitutionLog | `tt_substitution_log` | Teacher substitution records |
| 50 | SubstitutionPattern | `tt_substitution_patterns` | hasMany: PatternResult; ML pattern learning |
| 51 | SubstitutionRecommendation | `tt_substitution_recommendations` | Substitute teacher recommendations |
| 52 | TeacherAbsences | `tt_teacher_absence` | Teacher absence records |
| 53 | TeacherAvailablity | `tt_teacher_availability` | Teacher capacity snapshot (note: typo in filename) |
| 54 | TeacherAvailabilityDetail | `tt_teacher_availability_detail` | Per-day-per-period availability breakdown |
| 55 | TeacherUnavailable | `tt_teacher_unavailable` | Teacher blackout periods |
| 56 | TeacherWorkload | `tt_teacher_workload` | Post-generation workload summary |
| 57 | Timetable | `tt_timetable` | hasMany: TimetableCell, Activity, GenerationRun, ChangeLog |
| 58 | TimetableCell | `tt_timetable_cell` | belongsTo: Timetable, Activity; hasMany: TimetableCellTeacher, ResourceBooking |
| 59 | TimetableGenerationStrategy | `tt_generation_strategy` | Generation algorithm configuration |
| 60 | TrainingData | `tt_training_data` | ML training data |
| 61 | VersionComparison | `tt_version_comparisons` | hasMany: VersionComparisonDetail |
| 62 | VersionComparisonDetail | `tt_version_comparison_details` | belongsTo: VersionComparison |
| 63 | WhatIfScenario | `tt_what_if_scenarios` | What-if analysis scenarios |

**Critical Note:** `ConstraintCategory` and `ConstraintScope` both point to the SAME table `tt_constraint_category_scope` — differentiated by a `type` ENUM column. This is by design (Decision D16). Do NOT create separate tables.

### 3.3 Services

#### 3.3.1 Core Services (8 files)

| Service | File | Responsibility |
|---------|------|---------------|
| ActivityScoreService | `app/Services/ActivityScoreService.php` | Calculates priority and difficulty scores for activities |
| DatabaseConstraintService | `app/Services/DatabaseConstraintService.php` | Loads constraints from database, hydrates into PHP constraint objects |
| GenerationResult | `app/Services/GenerationResult.php` | Value object / DTO for generation results |
| RefinementService | `app/Services/RefinementService.php` | Manual timetable adjustments: swap, move, lock, batch operations, rollback |
| RoomAllocationPass | `app/Services/RoomAllocationPass.php` | Room assignment pass during/after generation |
| RoomChangeTrackingService | `app/Services/RoomChangeTrackingService.php` | Tracks room changes for constraint evaluation |
| SubstitutionService | `app/Services/SubstitutionService.php` | Teacher substitution: candidate scoring, pattern learning, recommendation |
| TimetableGenerationService | `app/Services/TimetableGenerationService.php` | Orchestrates the full generation pipeline |

#### 3.3.2 Constraint System (92 files)

**Base & Management (6 files):**

| Service | File | Responsibility |
|---------|------|---------------|
| TimetableConstraint | `app/Services/TimetableConstraint.php` | Abstract base class for all constraints |
| ConstraintContext | `app/Services/ConstraintContext.php` | Value object for slot+activity evaluation context |
| ConstraintEvaluator | `app/Services/ConstraintEvaluator.php` | Separated evaluation logic with caching |
| ConstraintFactory | `app/Services/ConstraintFactory.php` | Creates constraint PHP objects from DB records |
| ConstraintManager | `app/Services/ConstraintManager.php` | Orchestrates constraint checking: `checkHardConstraints()`, `evaluateSoftConstraints()` |
| ConstraintRegistry | `app/Services/ConstraintRegistry.php` | Plugin registration system for constraint classes |

**Hard Constraint Classes (24 files):**

| Constraint Class | Code | Purpose |
|-----------------|------|---------|
| HardConstraint | — | Abstract base for hard constraints |
| ActivityExcludedFromDayConstraint | ACTIVITY_EXCLUDED_DAY | Prevent activity on specific days |
| ActivityFixedToDayConstraint | ACTIVITY_FIXED_DAY | Force activity to specific days |
| ActivityFixedToPeriodRangeConstraint | ACTIVITY_FIXED_PERIOD_RANGE | Force activity to period range (e.g., Maths periods 6-8) |
| ClassConsecutiveRequiredConstraint | CLASS_CONSECUTIVE_REQUIRED | Require consecutive periods (labs, practicals) |
| ClassMaxPerDayConstraint | CLASS_MAX_PER_DAY | Max periods per day for a class |
| ClassWeeklyPeriodsConstraint | CLASS_WEEKLY_PERIODS | Exact weekly period count |
| ConsecutiveActivitiesConstraint | CONSECUTIVE_ACTIVITIES | Activities must be consecutive |
| ExamOnlyPeriodsConstraint | EXAM_ONLY_PERIODS | Periods reserved for exams only |
| GenericHardConstraint | — | Catch-all for DB-defined hard constraints |
| GlobalFixedPeriodConstraint | GLOBAL_FIXED_PERIOD | Global period locks (assembly, lunch) |
| GlobalHolidayConstraint | GLOBAL_HOLIDAY | Holiday blocking |
| NoTeachingAfterExamConstraint | NO_TEACHING_AFTER_EXAM | Block teaching after exam periods |
| NotOverlappingConstraint | NOT_OVERLAPPING | Activities must not overlap |
| OccupyExactSlotsConstraint | OCCUPY_EXACT_SLOTS | Activity fills exact number of slots |
| ParallelPeriodConstraint | PARALLEL_PERIODS | **Parallel group enforcement — CRITICAL** |
| RoomExclusiveUseConstraint | ROOM_EXCLUSIVE_USE | Room used by one activity at a time |
| RoomMaxUsagePerDayConstraint | ROOM_MAX_USAGE_PER_DAY | Room daily usage cap |
| SameStartingTimeConstraint | SAME_STARTING_TIME | Activities start at same time |
| TeacherConflictConstraint | TEACHER_CONFLICT | No teacher double-booking |
| TeacherMaxDailyConstraint | TEACHER_MAX_DAILY | Teacher daily period cap |
| TeacherMaxWeeklyConstraint | TEACHER_MAX_WEEKLY | Teacher weekly period cap |
| TeacherRoomUnavailableConstraint | TEACHER_ROOM_UNAVAILABLE | Room unavailable for teacher |
| TeacherUnavailablePeriodsConstraint | TEACHER_UNAVAILABLE_PERIODS | Teacher blackout periods |

**Soft Constraint Classes (61 files):**

*Class-level soft constraints (17 files):*

| Constraint Class | Purpose |
|-----------------|---------|
| ClassMajorSubjectsDailyConstraint | Major subjects should appear every day |
| ClassMaxConsecutiveStudyFormatConstraint | Max consecutive periods of same study format |
| ClassMaxContinuousConstraint | Max continuous teaching periods for a class |
| ClassMaxDaysInIntervalConstraint | Max days in interval for same subject |
| ClassMaxGapsPerWeekConstraint | Max free gaps per week |
| ClassMaxMinorSubjectsConstraint | Max minor subjects per day (e.g., max 2) |
| ClassMaxRoomChangesPerDayConstraint | Max room changes per day for a class |
| ClassMaxSpanConstraint | Max span of teaching time per day |
| ClassMaxStudyFormatHoursConstraint | Max hours with specific study format |
| ClassMinDailyHoursConstraint | Min teaching hours per day |
| ClassMinGapConstraint | Min gap between same-subject periods |
| ClassMinRestingHoursConstraint | Min rest between end of day and start of next |
| ClassMinStudyFormatHoursConstraint | Min hours with specific study format |
| ClassNotFirstPeriodConstraint | Subject not in first period |
| ClassNotLastPeriodConstraint | Subject not in last period |
| ClassStudyFormatGapConstraint | Min gap between different study formats |
| ClassTeacherFirstPeriodConstraint | Class teacher gets first period |

*Global soft constraints (4 files):*

| Constraint Class | Purpose |
|-----------------|---------|
| EndStudentsDayConstraint | Activity that ends the student day |
| GlobalBalancedDistributionConstraint | Balanced distribution across week |
| GlobalMaxTeachingDaysConstraint | Global max teaching days policy |
| GlobalPreferMorningConstraint | Prefer morning periods |

*Teacher-level soft constraints (22 files):*

| Constraint Class | Purpose |
|-----------------|---------|
| TeacherDailyStudyFormatConstraint | Max hours/day with specific study format |
| TeacherFreePeriodEachHalfConstraint | Free period in each half of day |
| TeacherGapsInSlotRangeConstraint | Gaps in specific slot ranges |
| TeacherHomeRoomConstraint | Teacher assigned to home room |
| TeacherMaxBuildingChangesPerDayConstraint | Max building changes per day |
| TeacherMaxConsecutiveDBConstraint | Max consecutive periods (DB-configured) |
| TeacherMaxConsecutiveStudyFormatConstraint | Max consecutive same study format |
| TeacherMaxDaysInIntervalConstraint | Max days in interval |
| TeacherMaxGapsPerDayConstraint | Max gaps per day |
| TeacherMaxGapsPerWeekConstraint | Max gaps per week |
| TeacherMaxHoursInIntervalConstraint | Max hours in interval |
| TeacherMaxRoomChangesPerDayConstraint | Max room changes per day |
| TeacherMaxRoomChangesPerWeekConstraint | Max room changes per week |
| TeacherMaxSpanPerDayConstraint | Max span per day |
| TeacherMaxStudyFormatsConstraint | Max different study formats per day |
| TeacherMinDailyConstraint | Min daily periods |
| TeacherMinGapBetweenRoomChangesConstraint | Min gap between room changes |
| TeacherMinRestingHoursConstraint | Min resting hours |
| TeacherMutuallyExclusiveSlotsConstraint | Two periods cannot both be used |
| TeacherNoConsecutiveDaysConstraint | No two consecutive working days |
| TeacherPreferredFreeDayConstraint | Preferred day off |
| TeacherStudyFormatGapConstraint | Min gap between study format pairs |

*Room/Activity/Inter-activity soft constraints (17 files):*

| Constraint Class | Purpose |
|-----------------|---------|
| MaxDaysBetweenConstraint | Max days between activity instances |
| MaxDifferentRoomsConstraint | Activity in max N different rooms |
| MinDaysBetweenConstraint | Min days between activity instances |
| MinGapsBetweenSetConstraint | Min gaps between activity sets |
| NonConcurrentMinorSubjectsConstraint | Minor subjects not simultaneous |
| OccupyMaxSlotsConstraint | Activity occupies max slots |
| OccupyMinSlotsConstraint | Activity occupies min slots |
| OrderedIfSameDayConstraint | Ordered activities on same day |
| PreferredSlotSelectionConstraint | Preferred time slot selection |
| PreferSameRoomConstraint | Prefer same room for consecutive |
| RoomMaxStudyFormatsConstraint | Room max study formats |
| SameDayConstraint | Activities on same day |
| SameHourConstraint | Activities at same hour |
| SameRoomIfConsecutiveConstraint | Same room if consecutive |
| StudyFormatPreferredRoomConstraint | Study format prefers room type |
| SubjectPreferredRoomConstraint | Subject prefers specific room |
| SubjectStudyFormatPreferredRoomConstraint | Subject+format prefers room |

#### 3.3.3 Generator & Solver Services (8 files)

| Service | File | Responsibility |
|---------|------|---------------|
| FETSolver | `app/Services/FETSolver.php` | **Core generation algorithm (~2,100+ lines)**: FET-inspired backtracking + greedy + rescue + forced placement |
| FETConstraintBridge | `app/Services/FETConstraintBridge.php` | Bridge between FETSolver and the constraint system |
| ImprovedTimetableGenerator | `app/Services/ImprovedTimetableGenerator.php` | Alternative/improved generation approach |
| Slot | `app/Services/Slot.php` | Value object representing a day+period slot |
| SlotEvaluator | `app/Services/SlotEvaluator.php` | Evaluates slot quality for activity placement |
| SlotGenerator | `app/Services/SlotGenerator.php` | Generates candidate slots for activities |
| TimetableSolution | `app/Services/TimetableSolution.php` | Value object representing a complete or partial solution |
| TimetableStorageService | `app/Services/TimetableStorageService.php` | Atomic DB transaction for saving generated timetable to database |

### 3.4 Jobs

| Job | File | Queue | Responsibility |
|-----|------|-------|---------------|
| GenerateTimetableJob | `app/Jobs/GenerateTimetableJob.php` | default | Queued timetable generation — dispatches FET solver as background job |

### 3.5 Form Requests

| # | Request | File | Purpose |
|---|---------|------|---------|
| 1 | AddActivitiesToParallelGroupRequest | `app/Http/Requests/AddActivitiesToParallelGroupRequest.php` | Validates activity IDs for parallel group |
| 2 | DayRequest | `app/Http/Requests/DayRequest.php` | Validates day selection |
| 3 | StoreConstraintRequest | `app/Http/Requests/StoreConstraintRequest.php` | Validates constraint creation |
| 4 | StoreParallelGroupRequest | `app/Http/Requests/StoreParallelGroupRequest.php` | Validates parallel group creation |
| 5 | TimetableGenerationStrategyRequest | `app/Http/Requests/TimetableGenerationStrategyRequest.php` | Validates generation strategy settings |
| 6 | UpdateConstraintRequest | `app/Http/Requests/UpdateConstraintRequest.php` | Validates constraint updates |
| 7 | UpdateParallelGroupRequest | `app/Http/Requests/UpdateParallelGroupRequest.php` | Validates parallel group updates |

**Note:** 16 controllers use inline validation instead of FormRequests (code quality issue).

### 3.6 Policies

| # | Policy | File | Notes |
|---|--------|------|-------|
| 1 | SmartTimetablePolicy | `app/Policies/SmartTimetablePolicy.php` | **EMPTY** — all methods return true or are stubs (SEC-009) |
| 2 | TimetableGenerationStrategyPolicy | `app/Policies/TimetableGenerationStrategyPolicy.php` | Generation strategy authorization |

### 3.7 Migrations (chronological)

**Module-level migrations: 0 files**

The SmartTimetable module has **no migrations in its own directory**. All `tt_*` table migrations are managed at the application level in `database/migrations/tenant/` or via the TimetableFoundation module.

### 3.8 Seeders

| # | Seeder | File | Purpose |
|---|--------|------|---------|
| 1 | SmartTimetableDatabaseSeeder | `database/seeders/SmartTimetableDatabaseSeeder.php` | Master seeder — orchestrates all others |
| 2 | ConstraintCategorySeeder | `database/seeders/ConstraintCategorySeeder.php` | Seeds constraint categories into `tt_constraint_category_scope` |
| 3 | ConstraintScopeSeeder | `database/seeders/ConstraintScopeSeeder.php` | Seeds constraint scopes into `tt_constraint_category_scope` |
| 4 | ConstraintTargetTypeSeeder | `database/seeders/ConstraintTargetTypeSeeder.php` | Seeds target types (TEACHER, CLASS, ROOM, etc.) |
| 5 | ConstraintTypeSeeder | `database/seeders/ConstraintTypeSeeder.php` | Seeds ~25 constraint type blueprints with parameter schemas |
| 6 | DaySeeder | `database/seeders/DaySeeder.php` | Seeds days of week (Monday-Sunday) |
| 7 | DayTypeSeeder | `database/seeders/DayTypeSeeder.php` | Seeds day types (Working, Holiday, Exam, Special) |
| 8 | GenerationStrategySeeder | `database/seeders/GenerationStrategySeeder.php` | Seeds generation algorithm strategies |
| 9 | PeriodSeeder | `database/seeders/PeriodSeeder.php` | Seeds period records |
| 10 | PeriodTypeSeeder | `database/seeders/PeriodTypeSeeder.php` | Seeds period types (Theory, Practical, Break, Lunch, etc.) |
| 11 | SchoolTimingProfileSeeder | `database/seeders/SchoolTimingProfileSeeder.php` | Seeds school timing profiles |
| 12 | SmartTimetablePermissionSeeder | `database/seeders/SmartTimetablePermissionSeeder.php` | Seeds permissions: `smart-timetable.{resource}.{action}` |
| 13 | TimingProfileSeeder | `database/seeders/TimingProfileSeeder.php` | Seeds timing profile templates |
| 14 | TtConfigSeeder | `database/seeders/TtConfigSeeder.php` | Seeds `tt_config` configuration records |

### 3.9 Views (Active)

**Total: 176 blade templates** organized by feature area:

#### Analytics Views (5 files)
- `analytics/index.blade.php` — Analytics dashboard
- `analytics/workload.blade.php` — Teacher workload analysis
- `analytics/utilization.blade.php` — Room utilization report
- `analytics/violations.blade.php` — Constraint violation report
- `analytics/distribution.blade.php` — Subject distribution analysis

#### Constraint Category Views (4 files)
- `constraint-category/{create,edit,show,trash}.blade.php` — Full CRUD + trash

#### Constraint Scope Views (4 files)
- `constraint-scope/{create,edit,show,trash}.blade.php` — Full CRUD + trash

#### Constraint Type Views (5 files)
- `constraint-type/{create,edit,index,show,trash}.blade.php` — Full CRUD + trash

#### Constraint Management Views (10 files + 8 partials)
- `constraint-management/index.blade.php` — Main constraint management hub
- Category-specific create/edit views: `class/`, `db/`, `global/`, `inter-activity/`, `room/`, `teacher/`
- 8 list partials for tabbed display: `activity-constraints`, `class-constraints`, `db-constraints`, `engine-rules`, `global-policies`, `inter-activity`, `room-constraints`, `teacher-constraints`

#### Constraint CRUD Views (5 files)
- `constraint/{create,edit,index,show,trash}.blade.php`

#### Export Views (2 files)
- `exports/timetable-pdf.blade.php` — Class timetable PDF
- `exports/teacher-pdf.blade.php` — Teacher timetable PDF

#### Generation Views (1 file)
- `generation/progress.blade.php` — Real-time generation progress display

#### Navigation Page Views (3+ files)
- `pages/constraint-engine.blade.php` — Constraint engine hub
- `pages/substitute-management.blade.php` — Substitution hub
- `pages/view-and-refinement.blade.php` — View and refinement hub

#### Page Partials (15 files)
- Constraint engine partials: `category-scope`, `constraint-category`, `constraint-scope`, `constraint-types`, `constraints`, `room-unavailability`, `teacher-unavailability` — each with `_list.blade.php`
- Substitution partials: `propose-approve`, `substitute-notifications`, `substitute-requirement`
- View & refinement partials: `lock-timetable`, `manual-refinement`, `publish-timetable`, `timetable-view`
- Generation history: `_list.blade.php`

#### Parallel Group Views (4 files)
- `parallel-group/{create,edit,index,show}.blade.php`

#### Preview Views (9+ files)
- `preview/index.blade.php` — Main timetable preview grid
- Partials: `_actions`, `_activities-summary`, `_class-section-heading`, `_conflicts-details`, `_health-report`, `_options`, `_placement-diagnostics`, `_timetable`

#### Refinement Views (1 file)
- `refinement/index.blade.php` — Manual refinement interface

#### Room Unavailable Views (5 files)
- `room-unavailable/{create,edit,index,show,trash}.blade.php`

#### Slot Availability Views (5 files)
- `slot-availability/{create,edit,index,show,trash}.blade.php`

#### SmartTimetable Main Views (5 files)
- `smart-timetable/{generation,index,master,operation,reports}.blade.php` — Tab-based dashboard views

#### SmartTimetable Partials (62+ files)
The largest group, organized by feature:
- `academic-term/_list` — Academic term management
- `activity/_list`, `activity/activity-table`, `activity/_partials/_activity-list` — Activity management
- `class-group-jnt/_list` — Class group junction
- `class-subject-requirement/_list` — Class subject requirements
- `class-timetable-type/_list` — Class timetable type mapping
- `constraint-type/_list`, `constraint/_list` — Inline constraint views
- `day-types/_list` — Day type management
- `generate-timetable/_actions`, `_main` — Generation UI (5 versions: `_1` through `_5`)
- `period-set/_list`, `period-set-period/_list` — Period set management
- `period-types/_list` — Period type management
- `reports/` — 7 report templates
- `requirement-consolidation/_list` + `_partials/_scripts`, `_styles` — Requirements with inline JS/CSS
- `room-unavailable/_list` — Room unavailability inline
- `school-days/_list` — School days
- `shifts/_list` — Shift management
- `slot-availability/_list` — Slot availability
- `subject-group-subject/_list` + `_partials/_scripts`, `_styles` — Subject groups
- `teacher-assignment-role/_list` — Teacher roles
- `teacher-availability/_list` + `_partials/` (5 sub-partials: `_generate`, `_scripts`, `_search-bar`, `_styles`, `_teacher-availability-list`) — Teacher availability management
- `teacher-unavailable/_list` — Teacher unavailability inline
- `teacher/_list` — Teacher management
- `timetable-type/_list` — Timetable type management
- `timetable/_list` + `_partials/` (4 sub-partials: `_scripts`, `_search-bar`, `_styles`, `_wizard`) — Timetable management with wizard
- `working-days/_list` + `partials/_scripts`, `_styles` — Working days

#### Substitution Views (2 files)
- `substitution/index.blade.php` — Substitution management
- `substitution/history.blade.php` — Substitution history

#### Teacher Unavailable Views (5 files)
- `teacher-unavailable/{create,edit,index,show,trash}.blade.php`

#### Timetable Generation Strategy Views (4 files)
- `timetable-generation-strategy/{create,edit,index,show,trash}.blade.php`

#### Validation Views (10 files)
- `validation/index.blade.php` — Validation dashboard
- Partials: `_actions`, `_activities`, `_alerts`, `_constraints`, `_header`, `_rooms`, `_statistics`, `_tabs`, `_teachers`

### 3.10 Views (Deprecated — `_old`)

No `_old` suffixed view files were found in the current module directory. However, the gap analysis notes that multiple views exist for the generation flow (`generate-timetable`, `generate-timetable_2`, `generate-timetable_3`, `generate-timetable_4`, `generate-timetable_5`) which appear to represent iterative versions of the same screen rather than proper deprecation.

### 3.11 Assets / JS

| File | Purpose |
|------|---------|
| `resources/assets/js/app.js` | Module JavaScript entry point |
| `resources/assets/sass/` | SCSS styling directory |
| `vite.config.js` | Vite build configuration for module assets |
| `package.json` | Node.js dependency configuration |

### 3.12 Tests

**Module-level: 0 test files**

The SmartTimetable module's `tests/` directory is empty. Some tests related to parallel periods (9 unit tests, 23 assertions) were added to `tests/Unit/` at the application level during the March 2026 parallel periods implementation.

### 3.13 Documentation (31 files)

#### Claude Context Docs (11 files in `Claude_Context/`)
| File | Purpose |
|------|---------|
| 2026Mar10_ActivityConstraints_Integration_Plan.md | Activity constraints integration plan |
| 2026Mar10_ConstraintArchitecture_Analysis.md | Constraint system architecture analysis |
| 2026Mar10_ConstraintList_and_Categories.md | Constraint list and categories |
| 2026Mar10_GapAnalysis_and_CompletionPlan.md | Initial gap analysis — module at 60% |
| 2026Mar10_GenerateWithFET_DeepAnalysis.md | FET generation deep analysis |
| 2026Mar10_SmartTimetable_Context.md | Module context overview |
| 2026Mar10_Step2_ActivityConstraints_SubTasks.md | Activity constraints sub-tasks |
| 2026Mar11_ParallelPeriod_Tasks.md | Parallel period implementation tasks |
| 2026Mar12_ParallelPeriod_SolverFix_Prompt.md | Parallel period solver fix prompt |
| Prompt.md | General prompt template |
| tt_Constraint_detail.md | Detailed constraint architecture analysis |

#### Module Documentation (19 files in `DOCS/`)
| File | Purpose |
|------|---------|
| API_AND_CONTROLLERS_GUIDE.md | API and controller reference |
| COMPREHENSIVE_ANALYSIS_generateActivities.md | Deep analysis of generateActivities method |
| CONSTRAINT_SYSTEM_GUIDE.md | Constraint system usage guide |
| data_for_seeder.md | Sample data for seeders |
| FET_GENERATION_ANALYSIS.md | FET generation analysis |
| FET_IMPROVEMENT_PLAN.md | FET solver improvement plan |
| FET_SOLVER_DETAILED_GUIDE.md | Detailed FET solver guide |
| FUNCTION_ANALYSIS_generateActivities.md | Function-level analysis of generateActivities |
| FUNCTION_ANALYSIS_generateClassSubjectGroups.md | Function-level analysis of generateClassSubjectGroups |
| HOW_TO_GUARANTEE_SUCCESS.md | Strategies for guaranteed generation success |
| MODELS_AND_DATA_STRUCTURE.md | Models and data structures |
| MODULE_ARCHITECTURE_OVERVIEW.md | Architecture overview |
| PLACEMENT_DIAGNOSTICS.md | Placement diagnostics guide |
| POST_PRODUCTION_GUIDE_AND_IMPROVEMENT_PROMPTS.md | Post-production guide |
| README_AND_INDEX.md | Module README and documentation index |
| TIMETABLE_GENERATION_FET_ANALYSIS_REPORT.md | FET analysis report |
| TIMETABLE_GENERATION_FET_FLOW_DIAGRAM.md | FET flow diagram |
| TIMETABLE_GENERATION_FET_QUICK_REFERENCE.md | FET quick reference |
| WHERE_TO_FIND_DIAGNOSTICS.md | Diagnostics location guide |

---

## 4. Menu & Navigation Map

### 4.1 Menu Structure

The SmartTimetable module provides **10 navigation hub pages** via `TimetableMenuController`, each serving as a landing page for a feature area:

| # | Menu Label | Route Name | URL | Controller@Method | Feature Area |
|---|-----------|------------|-----|-------------------|-------------|
| 1 | Pre-Requisites Setup | `smart-timetable.menu.preRequisitesSetup` | `/smart-timetable/pre-requisites-setup` | TimetableMenuController@preRequisitesSetup | Foundation data: shifts, day types, period types, roles, buildings, rooms, subjects, teachers |
| 2 | Timetable Configuration | `smart-timetable.menu.timetableConfiguration` | `/smart-timetable/timetable-configuration` | TimetableMenuController@timetableConfiguration | System settings: config, generation strategy |
| 3 | Timetable Masters | `smart-timetable.menu.timetableMasters` | `/smart-timetable/timetable-masters` | TimetableMenuController@timetableMasters | Lookup data: academic terms, timetable types, period sets |
| 4 | Timetable Requirement | `smart-timetable.menu.timetableRequirement` | `/smart-timetable/timetable-requirement` | TimetableMenuController@timetableRequirement | Curriculum: class groups, requirements, consolidation |
| 5 | Constraint Engine | `smart-timetable.menu.constraintEngine` | `/smart-timetable/constraint-engine` | TimetableMenuController@constraintEngine | Constraint management: categories, scopes, types, instances, unavailability |
| 6 | Resource Availability | `smart-timetable.menu.resourceAvailability` | `/smart-timetable/resource-availability` | TimetableMenuController@resourceAvailability | Teacher and room scheduling/availability |
| 7 | Timetable Preparation | `smart-timetable.menu.timetablePreparation` | `/smart-timetable/timetable-preparation` | TimetableMenuController@timetablePreparation | Activity creation, validation, generation setup |
| 8 | View and Refinement | `smart-timetable.menu.viewAndRefinement` | `/smart-timetable/view-and-refinement` | TimetableMenuController@viewAndRefinement | Timetable display, manual adjustments, locking, publishing |
| 9 | Reports and Logs | `smart-timetable.menu.reportsAndLogs` | `/smart-timetable/reports-and-logs` | TimetableMenuController@reportsAndLogs | Analytics, exports, generation history |
| 10 | Substitute Management | `smart-timetable.menu.substituteManagement` | `/smart-timetable/substitute-management` | TimetableMenuController@substituteManagement | Teacher absence and substitution |

### 4.2 Dashboard Tab Views

`TimetablePageController` provides **6 tab-based dashboard views** that aggregate multiple partials into tabbed interfaces:

| # | Tab View | Route Name | URL | Purpose | Partials Loaded |
|---|----------|------------|-----|---------|----------------|
| 1 | Timetable Operation | `smart-timetable.timetable.timetableOperation` | `/smart-timetable/timetable-opration` | Main operations dashboard | Activity list, timetable list, generation triggers |
| 2 | Timetable Master | `smart-timetable.timetable.timetableMaster` | `/smart-timetable/timetable-master` | Master data management tabs | Shifts, day types, period types, school days, working days, period sets |
| 3 | Timetable Generation | `smart-timetable.timetable.timetableGeneration` | `/smart-timetable/timetable-generation` | Generation interface | Generation wizard, progress, history |
| 4 | Timetable Reports | `smart-timetable.timetable.timetableReports` | `/smart-timetable/timetable-reports` | Reporting dashboard | 7 report partials |
| 5 | Timetable Config | `smart-timetable.timetable.timetableConfig` | `/smart-timetable/timetable-config` | Configuration settings | Config, generation strategy |
| 6 | Constraint Management | `smart-timetable.constraint-management.index` | `/smart-timetable/constraints` | Constraint management hub | 8 tabbed constraint views by category |

### 4.3 Complete Route Inventory

#### 4.3.1 Core Timetable Management (Resource)

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/smart-timetable-management` | `smart-timetable.smart-timetable-management.index` | SmartTimetableController@index |
| GET | `/smart-timetable/smart-timetable-management/create` | `smart-timetable.smart-timetable-management.create` | SmartTimetableController@create |
| POST | `/smart-timetable/smart-timetable-management` | `smart-timetable.smart-timetable-management.store` | SmartTimetableController@store |
| GET | `/smart-timetable/smart-timetable-management/{id}` | `smart-timetable.smart-timetable-management.show` | SmartTimetableController@show |
| GET | `/smart-timetable/smart-timetable-management/{id}/edit` | `smart-timetable.smart-timetable-management.edit` | SmartTimetableController@edit |
| PUT | `/smart-timetable/smart-timetable-management/{id}` | `smart-timetable.smart-timetable-management.update` | SmartTimetableController@update |
| DELETE | `/smart-timetable/smart-timetable-management/{id}` | `smart-timetable.smart-timetable-management.destroy` | SmartTimetableController@destroy |

#### 4.3.2 Generation Routes

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/generate/random` | `smart-timetable.smart-timetable-management.generate` | TimetableGenerationController@generate |
| POST | `/smart-timetable/generate/generate-fet` | `smart-timetable.smart-timetable-management.generate-fet` | TimetableGenerationController@generateWithFET |
| GET | `/smart-timetable/generate/generate-fet` | `smart-timetable.smart-timetable-management.generate-fet.get` | Redirect (shows error if GET) |
| GET | `/smart-timetable/generate/{class_id}/{section_id}/generate` | `smart-timetable.smart-timetable-management.generate-for-class-section` | TimetableGenerationController@generateForClassSection |
| POST | `/smart-timetable/store` | `smart-timetable.smart-timetable-management.store-timetable` | TimetableGenerationController@storeTimetable |

#### 4.3.3 Preview & Cell Operations

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/preview/{timetable}` | `smart-timetable.timetable.preview` | TimetablePreviewController@preview |
| POST | `/smart-timetable/place-cell` | `smart-timetable.timetable.placeCell` | TimetablePreviewController@placeCell |
| POST | `/smart-timetable/remove-cell` | `smart-timetable.timetable.removeCell` | TimetablePreviewController@removeCell |

#### 4.3.4 Publish/Unpublish

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| POST | `/smart-timetable/timetable/{id}/publish` | `smart-timetable.timetable.publish` | TimetablePublishController@publishTimetable |
| POST | `/smart-timetable/timetable/{id}/unpublish` | `smart-timetable.timetable.unpublish` | TimetablePublishController@unpublishTimetable |

#### 4.3.5 Refinement Routes

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| POST | `/smart-timetable/refinement/swap` | `smart-timetable.refinement.swap` | RefinementController@swap |
| POST | `/smart-timetable/refinement/move` | `smart-timetable.refinement.move` | RefinementController@move |
| POST | `/smart-timetable/refinement/lock` | `smart-timetable.refinement.toggleLock` | RefinementController@toggleLock |
| GET | `/smart-timetable/refinement/candidates/{cellId}` | `smart-timetable.refinement.candidates` | RefinementController@candidates |
| GET | `/smart-timetable/refinement/impact/{cellId}` | `smart-timetable.refinement.impact` | RefinementController@impact |

#### 4.3.6 Analytics Routes

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/analytics` | `smart-timetable.analytics.index` | AnalyticsController@index |
| GET | `/smart-timetable/analytics/workload` | `smart-timetable.analytics.workload` | AnalyticsController@workload |
| GET | `/smart-timetable/analytics/utilization` | `smart-timetable.analytics.utilization` | AnalyticsController@utilization |
| GET | `/smart-timetable/analytics/violations` | `smart-timetable.analytics.violations` | AnalyticsController@violations |
| GET | `/smart-timetable/analytics/distribution` | `smart-timetable.analytics.distribution` | AnalyticsController@distribution |
| GET | `/smart-timetable/analytics/export/{type}` | `smart-timetable.analytics.export` | AnalyticsController@export |

#### 4.3.7 Export Routes

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/export/pdf/{timetableId}` | `smart-timetable.export.pdf` | TimetableExportController@exportPdf |
| GET | `/smart-timetable/export/excel/{timetableId}` | `smart-timetable.export.excel` | TimetableExportController@exportExcel |
| GET | `/smart-timetable/export/teacher-pdf/{timetableId}` | `smart-timetable.export.teacherPdf` | TimetableExportController@exportTeacherPdf |

#### 4.3.8 Substitution Routes

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/substitution` | `smart-timetable.substitution.index` | SubstitutionController@index |
| POST | `/smart-timetable/substitution/absence` | `smart-timetable.substitution.reportAbsence` | SubstitutionController@reportAbsence |
| GET | `/smart-timetable/substitution/candidates/{cellId}/{date}` | `smart-timetable.substitution.candidates` | SubstitutionController@candidates |
| POST | `/smart-timetable/substitution/assign` | `smart-timetable.substitution.assign` | SubstitutionController@assign |
| POST | `/smart-timetable/substitution/auto-assign` | `smart-timetable.substitution.autoAssign` | SubstitutionController@autoAssign |
| GET | `/smart-timetable/substitution/history/{teacherId}` | `smart-timetable.substitution.history` | SubstitutionController@history |
| POST | `/smart-timetable/substitution/teacher-absence/{id}/approve` | `smart-timetable.teacher-absence.approve` | SubstitutionController@approveAbsence |
| POST | `/smart-timetable/substitution/teacher-absence/{id}/reject` | `smart-timetable.teacher-absence.reject` | SubstitutionController@rejectAbsence |
| POST | `/smart-timetable/substitution/substitution-log/{id}/notify` | `smart-timetable.substitution-log.notify` | SubstitutionController@markNotified |

#### 4.3.9 Constraint Management Routes

**Constraint Category** — Resource CRUD + soft delete (`/smart-timetable/constraint-category`)
**Constraint Scope** — Resource CRUD + soft delete (`/smart-timetable/constraint-scope`)
**Constraint Type** — Resource CRUD + soft delete (`/smart-timetable/constraint-type`)
**Constraints** — Resource CRUD + soft delete + category-specific views (`/smart-timetable/constraint`)
  - **CRITICAL**: `createByCategory` and `editByCategory` routes come BEFORE `Route::resource()` to avoid route conflicts
**Room Unavailable** — Resource CRUD + soft delete (`/smart-timetable/room-unavailable`)
**Teacher Unavailable** — Resource CRUD + soft delete (`/smart-timetable/teacher-unavailable`)

Each resource CRUD group includes:
- Standard resource methods: `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`
- Soft delete management: `trash/view`, `{id}/restore`, `{id}/force-delete`
- Status toggle: `{id}/toggle-status`

#### 4.3.10 Parallel Group Routes (Module-level)

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/smart-timetable/parallel-group` | `smart-timetable.parallel-group.index` | ParallelGroupController@index |
| GET | `/smart-timetable/parallel-group/create` | `smart-timetable.parallel-group.create` | ParallelGroupController@create |
| POST | `/smart-timetable/parallel-group` | `smart-timetable.parallel-group.store` | ParallelGroupController@store |
| POST | `/smart-timetable/parallel-group/auto-detect` | `smart-timetable.parallel-group.auto-detect` | ParallelGroupController@autoDetect |
| GET | `/smart-timetable/parallel-group/{parallelGroup}` | `smart-timetable.parallel-group.show` | ParallelGroupController@show |
| GET | `/smart-timetable/parallel-group/{parallelGroup}/edit` | `smart-timetable.parallel-group.edit` | ParallelGroupController@edit |
| PUT | `/smart-timetable/parallel-group/{parallelGroup}` | `smart-timetable.parallel-group.update` | ParallelGroupController@update |
| DELETE | `/smart-timetable/parallel-group/{parallelGroup}` | `smart-timetable.parallel-group.destroy` | ParallelGroupController@destroy |
| POST | `/smart-timetable/parallel-group/{parallelGroup}/add-activities` | `smart-timetable.parallel-group.add-activities` | ParallelGroupController@addActivities |
| DELETE | `/smart-timetable/parallel-group/{parallelGroup}/activity/{activity}` | `smart-timetable.parallel-group.remove-activity` | ParallelGroupController@removeActivity |
| POST | `/smart-timetable/parallel-group/{parallelGroup}/set-anchor/{activity}` | `smart-timetable.parallel-group.set-anchor` | ParallelGroupController@setAnchor |

#### 4.3.11 Class Subject Group Routes

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| POST | `/smart-timetable/class-subject-group/generate-class-groups` | `smart-timetable.class-subject-group.generateClassSubjectGroups` | ClassSubjectGroupController@generateClassSubjectGroups |
| POST | `/smart-timetable/class-subject-subgroup/update-sharing` | `smart-timetable.class-subject-group.updateSharing` | ClassSubjectGroupController@updateSharing |

#### 4.3.12 API Endpoints (auth:sanctum)

| Method | URL Pattern | Route Name | Controller@Method |
|--------|------------|------------|-------------------|
| GET | `/api/v1/smarttimetables` | `smarttimetable.index` | SmartTimetableController@index |
| POST | `/api/v1/smarttimetables` | `smarttimetable.store` | SmartTimetableController@store |
| GET | `/api/v1/smarttimetables/{id}` | `smarttimetable.show` | SmartTimetableController@show |
| PUT | `/api/v1/smarttimetables/{id}` | `smarttimetable.update` | SmartTimetableController@update |
| DELETE | `/api/v1/smarttimetables/{id}` | `smarttimetable.destroy` | SmartTimetableController@destroy |
| POST | `/api/v1/timetable/generate` | — | TimetableApiController@generate |
| GET | `/api/v1/timetable/generate/{runId}/status` | — | TimetableApiController@status |
| GET | `/api/v1/timetable/{id}` | — | TimetableApiController@show |
| GET | `/api/v1/timetable/{id}/class/{classId}` | — | TimetableApiController@byClass |
| GET | `/api/v1/timetable/{id}/teacher/{teacherId}` | — | TimetableApiController@byTeacher |
| GET | `/api/v1/timetable/{id}/room/{roomId}` | — | TimetableApiController@byRoom |

### 4.4 Permission Structure

**Permission Naming Convention:** `smart-timetable.{resource}.{action}`

**Resources with Permissions (26):**
`timetable`, `activity`, `constraint`, `parallel-group`, `teacher-availability`, `requirement`, `class-subject-subgroup`, `period-set`, `period-set-period`, `room-unavailable`, `slot-requirement`, `teacher-assignment-role`, `teacher-unavailable`, `timetable-type`, `working-day`, `school-day`, `school-shift`, `day-type`, `period-type`, `timing-profile`, `tt-config`, `generation-strategy`, `report`, `academic-term`, `config`, `validation`

**Standard Actions:** `viewAny`, `view`, `create`, `update`, `delete`

**Special Actions:**
- `timetable`: `generate`, `publish`, `store`
- `activity`: `generate`
- `requirement`: `generate`
- `teacher-availability`: `generate`
- `report`: `export`
- `teacher-assignment-role`, `timetable-type`, `room-unavailable`, `teacher-unavailable`: `restore`

### 4.5 Middleware

| Middleware | Applied To | Purpose |
|-----------|-----------|---------|
| `auth` | All web routes | Authentication required |
| `verified` | App-level SmartTimetable routes | Email verification required |
| `web` | Module-level routes | Web middleware group |
| `auth:sanctum` | API routes | API token authentication |
| `InitializeTenancyByDomain` | Via tenant middleware group | Tenant database resolution |
| `PreventAccessFromCentralDomains` | Via tenant middleware group | Block central domain access to tenant routes |

**Missing Middleware (Security Gap):**
- `EnsureTenantHasModule` — Not applied to SmartTimetable routes, meaning tenants without the module can access it

---

*End of Sections 1-4 — Run 1 Complete*

---

## 5. User Workflow (End-to-End Steps)

### 5.1 Complete Administrator Workflow

The following documents the intended end-to-end workflow a school administrator follows to create, generate, refine, and publish a timetable:

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 0: PRE-REQUISITES (One-time Setup)                       │
│  Screen: Pre-Requisites Setup                                   │
│  Route: smart-timetable.menu.preRequisitesSetup                 │
├─────────────────────────────────────────────────────────────────┤
│  Step 0.1: Configure Shifts (Morning, Afternoon, etc.)          │
│  Step 0.2: Configure Day Types (Working, Holiday, Exam, etc.)   │
│  Step 0.3: Configure Period Types (Theory, Practical, Break)    │
│  Step 0.4: Configure Teacher Assignment Roles                   │
│  Step 0.5: Configure School Days (Mon-Sat working days)         │
│  Step 0.6: Verify Buildings, Rooms, Subjects, Teachers exist    │
│            (managed by SchoolSetup module)                       │
│  Output: Master tables populated (tt_shift, tt_day_type,        │
│          tt_period_type, tt_teacher_assignment_role,             │
│          tt_school_days)                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: TIMETABLE CONFIGURATION                               │
│  Screen: Timetable Configuration                                │
│  Route: smart-timetable.menu.timetableConfiguration             │
├─────────────────────────────────────────────────────────────────┤
│  Step 1.1: Set tt_config parameters (batch size, timeouts)      │
│  Step 1.2: Create Generation Strategy (algorithm type,          │
│            recursion depth, sorting method)                      │
│  Output: tt_config rows, tt_generation_strategy rows            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: TIMETABLE MASTERS                                     │
│  Screen: Timetable Masters (13 tabs)                            │
│  Route: smart-timetable.menu.timetableMasters                   │
├─────────────────────────────────────────────────────────────────┤
│  Step 2.1: Create Academic Term (term dates, period counts)     │
│  Step 2.2: Create Period Sets (e.g., "Standard 8-Period Day")   │
│  Step 2.3: Define Period Set Periods (individual periods with   │
│            start/end times, types)                               │
│  Step 2.4: Create Timetable Types (Standard, Exam, Half Day)   │
│  Step 2.5: Map Timetable Types to Classes                       │
│            (tt_class_timetable_type_jnt)                        │
│  Step 2.6: Configure Working Days calendar                      │
│  Step 2.7: Define Teacher/Room Unavailability periods           │
│  Output: tt_period_set, tt_period_set_period_jnt,               │
│          tt_timetable_type, tt_class_timetable_type_jnt,        │
│          tt_working_day, tt_teacher_unavailable,                │
│          tt_room_unavailable                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 3: TIMETABLE REQUIREMENTS                                │
│  Screen: Timetable Requirement → Operation tab                  │
│  Route: smart-timetable.menu.timetableRequirement               │
├─────────────────────────────────────────────────────────────────┤
│  Step 3.1: Generate Slot Requirements (auto from class-         │
│            timetable-type mapping)                               │
│            → populates tt_slot_requirement                       │
│  Step 3.2: Generate Class Subject Groups (auto from             │
│            sch_class_groups_jnt)                                 │
│            → populates tt_class_requirement_groups,              │
│              tt_class_requirement_subgroups                      │
│  Step 3.3: Review/Edit Requirement Consolidation                │
│            → User adjusts preferred_periods_json,                │
│              avoid_periods_json, spread_evenly flags             │
│  Output: tt_slot_requirement, tt_class_requirement_groups,      │
│          tt_class_requirement_subgroups,                         │
│          tt_requirement_consolidation                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 4: CONSTRAINT ENGINE                                     │
│  Screen: Constraint Engine (6 tabs)                             │
│  Route: smart-timetable.menu.constraintEngine                   │
├─────────────────────────────────────────────────────────────────┤
│  Step 4.1: Review/Edit Constraint Categories & Scopes           │
│  Step 4.2: Review Constraint Types (seeded, ~25 types)          │
│  Step 4.3: Create/Edit Constraint Instances                     │
│            → Configure per-teacher, per-class, per-room,        │
│              global, and inter-activity constraints              │
│  Step 4.4: Configure Teacher Unavailability                     │
│  Step 4.5: Configure Room Unavailability                        │
│  Output: tt_constraint_category_scope, tt_constraint_type,      │
│          tt_constraint, tt_teacher_unavailable,                  │
│          tt_room_unavailable                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 5: RESOURCE AVAILABILITY                                  │
│  Screen: Resource Availability → Operation tab                  │
│  Route: smart-timetable.menu.resourceAvailability               │
├─────────────────────────────────────────────────────────────────┤
│  Step 5.1: Generate Teacher Availability (auto-calculated)      │
│            → Bulk INSERT from requirements + capabilities        │
│            → Calculate TAR scores, scarcity indexes              │
│  Step 5.2: User marks is_primary_teacher, is_preferred_teacher  │
│  Step 5.3: Generate Room Availability (auto from rooms)         │
│  Output: tt_teacher_availability,                                │
│          tt_teacher_availability_detail,                         │
│          tt_room_availability, tt_room_availability_detail       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 6: TIMETABLE PREPARATION                                 │
│  Screen: Timetable Preparation → Operation tab                  │
│  Route: smart-timetable.menu.timetablePreparation               │
├─────────────────────────────────────────────────────────────────┤
│  Step 6.1: Generate Activities (auto from consolidated reqs)    │
│            → Creates tt_activity records with priority scores    │
│  Step 6.2: Configure Parallel Groups                             │
│            → Define which activities run simultaneously          │
│            → Set anchor activities                               │
│  Step 6.3: Run Pre-Generation Validation                        │
│            → Slot capacity, teacher availability, room checks    │
│  Step 6.4: Create Timetable record (status = DRAFT)             │
│  Output: tt_activity, tt_parallel_group,                         │
│          tt_parallel_group_activity, tt_timetable               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 7: TIMETABLE GENERATION                                   │
│  Screen: Timetable Generation                                   │
│  Routes: smart-timetable.smart-timetable-management.generate-fet│
│          smart-timetable.timetable.timetableGeneration          │
├─────────────────────────────────────────────────────────────────┤
│  Step 7.1: User clicks "Generate with FET" button               │
│  Step 7.2: GenerateTimetableJob dispatched to queue              │
│  Step 7.3: FETSolver runs:                                       │
│            → Phase A: Place fixed activities (assembly, breaks)  │
│            → Phase B: Main loop (recursive swapping)             │
│            → Phase C: Rescue pass (relaxed constraints)          │
│            → Phase D: Forced placement (last resort)             │
│  Step 7.4: User monitors progress via polling                    │
│            (generation/progress.blade.php polls every 2s)        │
│  Step 7.5: On completion: timetable.status → GENERATED           │
│  Output: tt_timetable_cell, tt_timetable_cell_teacher,           │
│          tt_generation_run, tt_conflict_detection,               │
│          tt_resource_booking                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 8: VIEW & REFINEMENT                                     │
│  Screen: View and Refinement (4 tabs)                           │
│  Route: smart-timetable.menu.viewAndRefinement                  │
├─────────────────────────────────────────────────────────────────┤
│  Step 8.1: Preview generated timetable                           │
│            → Class-wise grid view (days × periods)               │
│            → Placement statistics (fully/partially/not placed)   │
│  Step 8.2: Manual Refinement                                     │
│            → Click cell A, click cell B to swap                  │
│            → Impact analysis modal shows constraint warnings     │
│            → Confirm swap or cancel                              │
│  Step 8.3: Lock/Unlock cells                                     │
│            → Locked cells cannot be swapped or moved             │
│  Step 8.4: Export to PDF/Excel                                   │
│            → Class timetable PDF, Teacher timetable PDF          │
│  Output: tt_change_log (audit trail of manual changes)           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 9: PUBLISH                                                │
│  Screen: View and Refinement → Publish tab                      │
│  Route: smart-timetable.timetable.publish                       │
├─────────────────────────────────────────────────────────────────┤
│  Step 9.1: User clicks "Publish Timetable"                       │
│  Step 9.2: timetable.status → PUBLISHED                          │
│  Step 9.3: published_at and published_by recorded                │
│  Step 9.4: Standard timetable views become available              │
│  Note: Can be unpublished via unpublish route                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 10: REPORTS & ANALYTICS                                   │
│  Screen: Reports and Logs                                        │
│  Route: smart-timetable.menu.reportsAndLogs                     │
├─────────────────────────────────────────────────────────────────┤
│  Step 10.1: View Teacher Workload Analysis                       │
│  Step 10.2: View Room Utilization Report                         │
│  Step 10.3: View Constraint Violations Report                    │
│  Step 10.4: View Subject Distribution Analysis                   │
│  Step 10.5: Export reports (CSV)                                  │
│  Output: Read-only analytics from generated data                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 11: SUBSTITUTION MANAGEMENT (Ongoing)                     │
│  Screen: Substitute Management (3 tabs)                          │
│  Route: smart-timetable.menu.substituteManagement               │
├─────────────────────────────────────────────────────────────────┤
│  Step 11.1: Record teacher absence                               │
│  Step 11.2: System finds substitute candidates (scored)          │
│  Step 11.3: Admin assigns substitute (manual or auto)            │
│  Step 11.4: Notifications sent                                   │
│  Step 11.5: Track substitution history                           │
│  Output: tt_teacher_absence, tt_substitution_log,                │
│          tt_substitution_pattern (learning)                      │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Timetable Lifecycle States

```
            ┌──────────┐
            │  DRAFT   │ ← Created by user
            └────┬─────┘
                 │ User triggers generation
                 ▼
          ┌──────────────┐
          │  GENERATING  │ ← FET solver running (background job)
          └──────┬───────┘
                 │ Generation completes successfully
                 ├──────────────────────────┐
                 ▼                          ▼
          ┌──────────────┐          ┌──────────┐
          │  GENERATED   │          │  FAILED  │ ← On error/timeout
          └──────┬───────┘          └──────────┘
                 │ User publishes
                 ▼
          ┌──────────────┐
          │  PUBLISHED   │ ← Visible to teachers/students
          └──────┬───────┘
                 │ User archives
                 ▼
          ┌──────────────┐
          │  ARCHIVED    │ ← Historical record
          └──────────────┘
```

**State Transitions:**
- `DRAFT → GENERATING`: User clicks "Generate with FET" or "Generate Random"
- `GENERATING → GENERATED`: GenerateTimetableJob completes successfully
- `GENERATING → FAILED`: Job fails, times out, or is cancelled
- `GENERATED → PUBLISHED`: User clicks "Publish" (via TimetablePublishController)
- `PUBLISHED → GENERATED`: User clicks "Unpublish" (reverts to editable state)
- `PUBLISHED → ARCHIVED`: User archives a published timetable
- Any state → `DRAFT`: Not directly supported; create new version instead

**What Changes at Each Transition:**
- **DRAFT → GENERATING**: `tt_generation_run` record created; job dispatched
- **GENERATING → GENERATED**: `tt_timetable_cell` records populated; `tt_resource_booking` created; `tt_conflict_detection` logged; quality scores calculated
- **GENERATED → PUBLISHED**: `published_at` and `published_by` set; standard views accessible
- **PUBLISHED → GENERATED**: `published_at` and `published_by` cleared; back to editable

---

## 6. Screen-by-Screen Walkthrough

### 6.1 Module Main Index — Timetable Config

```
SCREEN: Timetable Config
VIEW FILE: resources/views/index.blade.php
URL PATTERN: /smart-timetable
ROUTE NAME: smart-timetable.index
CONTROLLER: TimetablePageController (or module default)
PURPOSE: Top-level configuration hub with 3 tabs
```

**UI Elements:**
- Breadcrumb navigation
- **Tab 1: Timetable Config** (id: `tt-config`) — School-wide timetable settings from `tt_config`
- **Tab 2: School Academic Term** (id: `school-academic-term`) — Academic term management
- **Tab 3: Generation Strategy** (id: `tt-generation-strategy`) — Algorithm configuration

**Partials:** `timetable-config.index`, `school-academic-term.index`, `timetable-generation-strategy.index`

---

### 6.2 Timetable Master — 13-Tab Data Management

```
SCREEN: Timetable Master
VIEW FILE: resources/views/smart-timetable/master.blade.php
URL PATTERN: /smart-timetable/timetable-master
ROUTE NAME: smart-timetable.timetable.timetableMaster
CONTROLLER: TimetablePageController@timetableMaster
PURPOSE: Manage all master/lookup data in a single tabbed interface
```

**Tabs (13):**
1. School Days — `tt_school_days` CRUD
2. Shifts — `tt_shift` CRUD
3. Day Types — `tt_day_type` CRUD
4. Work Days — `tt_working_day` CRUD
5. Period Types — `tt_period_type` CRUD
6. Period Sets — `tt_period_set` CRUD
7. Period Set Periods — `tt_period_set_period_jnt` CRUD
8. Teacher Unavailable — `tt_teacher_unavailable` CRUD
9. Academic Term — `sch_academic_term` CRUD
10. Room Unavailable — `tt_room_unavailable` CRUD
11. Teacher Assignment Role — `tt_teacher_assignment_role` CRUD
12. Timetable Types — `tt_timetable_type` CRUD
13. Teacher — Teacher profile listing

**Data Variables:** Active tab from request (default: `school-day`)

---

### 6.3 Timetable Operation — 5-Tab Workflow

```
SCREEN: Timetable Operation
VIEW FILE: resources/views/smart-timetable/operation.blade.php
URL PATTERN: /smart-timetable/timetable-opration
ROUTE NAME: smart-timetable.timetable.timetableOperation
CONTROLLER: TimetablePageController@timetableOperation
PURPOSE: Core operational data management: subject groups, requirements, teacher availability, activities
```

**Tabs (5):**
1. **Subject Group** — Subject group and subject mapping (`sch_subject_groups`, `sch_subject_group_subject_jnt`)
2. **Class Subject Requirement** — Class requirement groups and subgroups
3. **Requirement Consolidation** — Consolidated view with editable fields (preferred periods, avoid periods, spread evenly)
4. **Teacher Availability** — Generated teacher availability with search, generate, and detail views
5. **Activity** — Generated activities with priority scores and constraint counts

---

### 6.4 Timetable Generation — Generation Workflow

```
SCREEN: Timetable Generation
VIEW FILE: resources/views/smart-timetable/generation.blade.php
URL PATTERN: /smart-timetable/timetable-generation
ROUTE NAME: smart-timetable.timetable.timetableGeneration
CONTROLLER: TimetableGenerationController@timetableGeneration
PURPOSE: Create timetable records, trigger generation, view history
```

**Tabs (2):**
1. **Timetable** — Timetable CRUD with wizard partial for creating new timetables
2. **Generation History** — List of past generation runs with status, duration, and results

---

### 6.5 Timetable Preview — Grid View

```
SCREEN: Timetable Preview / View Timetable
VIEW FILE: resources/views/preview/index.blade.php
URL PATTERN: /smart-timetable/preview/{timetable}
ROUTE NAME: smart-timetable.timetable.preview
CONTROLLER: TimetablePreviewController@preview
PURPOSE: Visual grid display of generated timetable with edit capabilities
```

**Key UI Elements:**

*Header Card:*
- Timetable name, code, type, academic term badges
- Status badge (color-coded: green=PUBLISHED, yellow=DRAFT, gray=ARCHIVED)
- Slot count and activity count

*Placement Summary (4 stat cards):*
- Fully Placed activities count
- Partially Placed activities count
- Not Placed activities count
- Coverage Percentage

*Action Bar (6 buttons):*
- Back, Edit (toggle edit mode), Print, Export, Fullscreen

*Class-Wise Tabs:*
- Dynamic tab per class-section (e.g., "6A", "6B", "10A")
- Each tab shows: activities count, filled/total slots, utilization %

*Timetable Grid (per class):*
- Rows = Periods (with time ranges)
- Columns = Days
- Break periods highlighted with coffee icon
- Activity cells display: Subject name, Study format badge, Teacher name, Room, Priority indicator, Difficulty score, Remaining periods counter

*Edit Mode Features:*
- Activity sidebar with search filter
- Drag-and-drop onto empty grid cells
- Color-coded activities for visual tracking

**Data Variables:** `$timetable`, `$classSections`, `$periods`, `$days`, `$schoolGrid` (3D array: `[$classKey][$dayOfWeek][$periodId]`), `$activitiesById`, `$selectedTeacherBySlot`, `$roomBySlot`, `$roomsById`, `$algorithm_stats`

**AJAX:** Cell placement/removal via POST to `placeCell`/`removeCell` endpoints

---

### 6.6 Generation Progress — Real-Time Polling

```
SCREEN: Generation Progress
VIEW FILE: resources/views/generation/progress.blade.php
URL PATTERN: /smart-timetable/generate/progress/{jobId}
CONTROLLER: TimetableGenerationController
PURPOSE: Real-time monitoring of timetable generation job
```

**UI Elements:**
- Dynamic status icon (Clock=PENDING, Spinning cog=RUNNING, Check=COMPLETED, X=FAILED)
- Current stage label (e.g., "Placing activities...", "Rescue pass...")
- Progress bar (30px height, color-coded by status)
- ETA timer (when running)
- Result summary on completion (activities placed, violations)
- Error display on failure with back button

**JavaScript (Alpine.js):** Polls `GET /api/v1/timetable/generate/{jobId}/status` every 2 seconds until COMPLETED or FAILED

---

### 6.7 Refinement — Manual Swap Interface

```
SCREEN: Timetable Refinement
VIEW FILE: resources/views/refinement/index.blade.php
URL PATTERN: /smart-timetable/refinement
ROUTE NAME: smart-timetable.refinement.index
CONTROLLER: RefinementController
PURPOSE: Two-click swap pattern for manual timetable adjustments
```

**Workflow:**
1. Click cell A → Selected cell info displayed with lock/unlock toggle
2. Click cell B → Impact analysis loaded via AJAX
3. Impact Preview Modal shows: current activity, teachers, constraint warnings
4. Confirm Swap or Cancel

**AJAX Endpoints:**
- `GET /smart-timetable/refinement/impact/{cellId}?action=swap` — Load impact analysis
- `POST /smart-timetable/refinement/swap` — Execute swap `{ cell_id_1, cell_id_2 }`
- `POST /smart-timetable/refinement/toggleLock` — Lock/unlock cell `{ cell_id, lock }`

**Feedback:** Toast notifications (bottom-right, green=success, red=error)

---

### 6.8 Reports & Analytics Dashboard

```
SCREEN: Timetable Reports & Analytics
VIEW FILE: resources/views/smart-timetable/reports.blade.php
URL PATTERN: /smart-timetable/timetable-reports
ROUTE NAME: smart-timetable.timetable.timetableReports
CONTROLLER: TimetablePageController@timetableReports
PURPOSE: Comprehensive reporting dashboard with charts and 7 detail tabs
```

**Timetable Selector:** Dropdown to choose active timetable (with status badge)

**Summary Cards (4):** Total Timetables, Active Classes, Avg Quality Score, Total Violations

**Performance Cards (3):** Teacher Satisfaction %, Room Utilization %, Room Utilization Score

**Charts (Chart.js):**
- Teacher Load Distribution (Bar chart, color: green/yellow/red)
- Room Utilization (Doughnut chart)

**Detail Tabs (7):**
1. Timetable Summary
2. Generation Quality
3. Teacher Load
4. Room Utilization
5. Class Coverage
6. Activity Teacher Capacity
7. Availability Logs

**Data Variables:** `$allTimetables`, `$selectedTimetable`, `$timetableStats`, `$teacherLoads`, `$roomUtilization`

---

### 6.9 Analytics Sub-Screens

#### 6.9.1 Teacher Workload

```
SCREEN: Teacher Workload
VIEW FILE: resources/views/analytics/workload.blade.php
ROUTE NAME: smart-timetable.analytics.workload
PURPOSE: Teacher-wise period distribution with subject breakdown
```

**Table columns:** #, Teacher (bold), Total Periods (badge), Subjects (badges with counts)
**Export:** CSV via analytics export endpoint

#### 6.9.2 Room Utilization

```
SCREEN: Room Utilization
VIEW FILE: resources/views/analytics/utilization.blade.php
ROUTE NAME: smart-timetable.analytics.utilization
PURPOSE: Room-wise slot usage with progress bars
```

**Summary Cards (3):** Overall Utilization %, Filled Slots, Total Slots
**Table:** Room, Used Slots, Utilization %, Progress bar (green ≥80%, yellow ≥50%, red <50%)

#### 6.9.3 Constraint Violations

```
SCREEN: Constraint Violations
VIEW FILE: resources/views/analytics/violations.blade.php
ROUTE NAME: smart-timetable.analytics.violations
PURPOSE: Violations report with severity breakdown
```

**Severity Cards:** Total, Critical (red), High (yellow), Medium (blue), Low (gray)
**Table:** Day, Period, Type, Severity (badge), Message

#### 6.9.4 Subject Distribution

```
SCREEN: Subject Distribution
VIEW FILE: resources/views/analytics/distribution.blade.php
ROUTE NAME: smart-timetable.analytics.distribution
PURPOSE: Per-class subject spread analysis across days
```

**Layout:** Accordion cards per class, each with subject table
**Table:** Subject, Days Spread (badge: green ≥4, yellow ≥2, red <2), Total Periods, Progress bar

---

### 6.10 Substitution Dashboard

```
SCREEN: Substitution Dashboard
VIEW FILE: resources/views/substitution/index.blade.php
URL PATTERN: /smart-timetable/substitution
ROUTE NAME: smart-timetable.substitution.index
CONTROLLER: SubstitutionController@index
PURPOSE: Complete substitution management — absence reporting, candidate selection, assignment
```

**Sections:**

1. **Date Picker** — Filter by date
2. **Summary Cards (3):** Total Absences, Pending Assignments, Unassigned Cells
3. **Report Absence Form:** Teacher ID, Date, Absence Type (FULL_DAY/PARTIAL), Reason
4. **Today's Absences Table:** Teacher, Date, Type, Status (PENDING/APPROVED/REJECTED), Actions (Auto-Assign, History)
5. **Unassigned Cells Table:** Period, Subject, Absent Teacher, Find Substitute button
6. **Pending Assignments Table:** Period, Absent Teacher, Substitute Teacher, Status

**Candidates Modal:** Fetched via AJAX — shows ranked substitute candidates with Score (color-coded: green ≥70, yellow ≥40, gray <40), Reason, Monthly Subs count, Assign button

**AJAX:** `GET /smart-timetable/substitution/candidates/{cellId}/{date}` returns scored candidates

---

### 6.11 Validation Dashboard

```
SCREEN: Timetable Validation
VIEW FILE: resources/views/validation/index.blade.php
ROUTE NAME: smart-timetable.validation.index
PURPOSE: Pre-generation validation checks
```

**Partials (4):** Header, Alerts, Tabs (with sub-sections: Activities, Teachers, Rooms, Constraints, Statistics), Action buttons

---

### 6.12 Constraint Management Hub

```
SCREEN: Constraint Management
VIEW FILE: resources/views/constraint-management/index.blade.php
URL PATTERN: /smart-timetable/constraints
ROUTE NAME: smart-timetable.constraint-management.index
CONTROLLER: TimetablePageController@constraintManagement
PURPOSE: 8-tab interface for all constraint configuration
```

**Tabs (8):**
1. Engine Rules — Core solver constraint rules
2. Teacher Constraints — Per-teacher time/load constraints
3. Class / Student Rules — Per-class period distribution rules
4. Activity Preferences — Activity-level preferences
5. Room & Space — Room allocation and movement constraints
6. DB-Driven Rules — Constraints loaded from database
7. Global Policies — School-wide policies
8. Inter-Activity — Cross-activity constraints (parallel, ordering)

Each tab renders a `_list.blade.php` partial with category-specific constraint management UI.

---

### 6.13 Parallel Groups Management

```
SCREEN: Parallel Groups
VIEW FILE: resources/views/parallel-group/index.blade.php
URL PATTERN: /smart-timetable/parallel-group
ROUTE NAME: smart-timetable.parallel-group.index
CONTROLLER: ParallelGroupController@index
PURPOSE: Manage parallel activity groups for simultaneous scheduling
```

**Filters:** Search (name/code), Group Type dropdown, Academic Term dropdown
**Table columns:** Code, Name, Type (badge), Coordination, Activities count, Constraint (Hard/Soft), Priority, Status, Actions (View/Edit/Delete)
**Pagination:** Laravel pagination links

**Create Form (create.blade.php):** Code, Name, Description, Academic Term, Group Type, Coordination Type, Priority (1-100), Weight (1-100), Hard Constraint toggle, Active toggle, Requires Same Teacher, Requires Same Room Type

---

### 6.14 Constraint Engine — 6-Tab Configuration

```
SCREEN: Constraint Engine
VIEW FILE: resources/views/pages/constraint-engine.blade.php
URL PATTERN: /smart-timetable/constraint-engine
ROUTE NAME: smart-timetable.menu.constraintEngine
CONTROLLER: TimetableMenuController@constraintEngine
PURPOSE: Manage constraint system infrastructure
```

**Tabs (6):**
1. Categories — `tt_constraint_category_scope` where type=CATEGORY
2. Scopes — `tt_constraint_category_scope` where type=SCOPE
3. Constraint Types — `tt_constraint_types` blueprints
4. Constraints — `tt_constraints` instances
5. Teacher Unavailability — `tt_teacher_unavailable` periods
6. Room Unavailability — `tt_room_unavailable` periods

---

### 6.15 PDF Export Templates

#### Class Timetable PDF
```
SCREEN: Class Timetable PDF Export
VIEW FILE: resources/views/exports/timetable-pdf.blade.php
PURPOSE: Landscape A4 PDF with class-wise grids
```

**Layout:** Header (timetable metadata) → One grid per class (page break between) → Footer (stats)
**Grid:** Days as columns, Periods as rows, Cells show Subject + Teacher + Room
**Data:** `$timetable`, `$classSections`, `$days`, `$periods`, `$generatedAt`, `$qualityScore`

#### Teacher Timetable PDF
```
SCREEN: Teacher Timetable PDF Export
VIEW FILE: resources/views/exports/teacher-pdf.blade.php
PURPOSE: Landscape A4 PDF with teacher-wise grids
```

**Layout:** Header → One grid per teacher (page break between) → Weekly periods count + Teaching days → Footer
**Grid:** Days as columns, Periods as rows, Cells show Subject + Class/Section + Room
**Data:** `$timetable`, `$teacherSchedules`, `$days`, `$periods`

---

## 7. Database Schema

### 7.1 Table Definitions

The SmartTimetable module uses **43+ tables** defined in `tt_timetable_ddl_v7.6.sql` plus additional tables from Laravel migrations. All `tt_*` tables reside in the **tenant database** (`tenant_db`), scoped per school.

#### 7.1.1 tt_config

```
TABLE: tt_config
DATABASE: tenant_db
PURPOSE: Timetable module configuration key-value settings
COLUMNS:
  - id             (SMALLINT UNSIGNED, PK, AUTO_INCREMENT)
  - ordinal        (INT UNSIGNED, NOT NULL, DEFAULT 1) — Display order
  - key            (VARCHAR(150), NOT NULL, UNIQUE) — Immutable config key
  - key_name       (VARCHAR(150), NOT NULL) — User-editable display name
  - value          (VARCHAR(512), NOT NULL) — Config value
  - value_type     (ENUM: STRING,NUMBER,BOOLEAN,DATE,TIME,DATETIME,JSON)
  - description    (VARCHAR(255), NOT NULL)
  - additional_info (JSON, NULL) — Extra metadata
  - tenant_can_modify (TINYINT(1), NOT NULL, DEFAULT 0)
  - mandatory      (TINYINT(1), NOT NULL, DEFAULT 1)
  - used_by_app    (TINYINT(1), NOT NULL, DEFAULT 1)
  - is_active      (TINYINT(1), NOT NULL, DEFAULT 1)
  - deleted_at     (TIMESTAMP, NULL)
  - created_at     (TIMESTAMP, NULL)
  - updated_at     (TIMESTAMP, NULL)
UNIQUE KEYS: uq_settings_ordinal (ordinal), uq_settings_key (key)
SOFT DELETES: Yes
```

#### 7.1.2 tt_generation_strategy

```
TABLE: tt_generation_strategy
DATABASE: tenant_db
PURPOSE: Algorithm configuration for timetable generation
COLUMNS:
  - id                    (SMALLINT UNSIGNED, PK, AUTO_INCREMENT)
  - code                  (VARCHAR(20), NOT NULL, UNIQUE)
  - name                  (VARCHAR(100), NOT NULL)
  - description           (VARCHAR(255), NULL)
  - algorithm_type        (ENUM: RECURSIVE,GENETIC,SIMULATED_ANNEALING,TABU_SEARCH,HYBRID, DEFAULT 'RECURSIVE')
  - max_recursive_depth   (INT UNSIGNED, DEFAULT 14) — FET recursion limit
  - max_placement_attempts (INT UNSIGNED, DEFAULT 2000)
  - tabu_size             (INT UNSIGNED, DEFAULT 100)
  - cooling_rate          (DECIMAL(5,2), DEFAULT 0.95)
  - population_size       (INT UNSIGNED, DEFAULT 50)
  - generations           (INT UNSIGNED, DEFAULT 100)
  - activity_sorting_method (ENUM: LESS_TEACHER_FIRST,DIFFICULTY_FIRST,CONSTRAINT_COUNT,DURATION_FIRST,RANDOM, DEFAULT 'LESS_TEACHER_FIRST')
  - timeout_seconds       (INT UNSIGNED, DEFAULT 300)
  - parameters_json       (JSON, NULL) — Additional algorithm parameters
  - is_default            (TINYINT(1), DEFAULT 0)
  - is_active             (TINYINT(1), DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
UNIQUE KEYS: uq_generation_strategy_code (code)
```

#### 7.1.3 tt_shift

```
TABLE: tt_shift
DATABASE: tenant_db
PURPOSE: School shift definitions (Morning, Afternoon, Evening)
COLUMNS:
  - id               (TINYINT UNSIGNED, PK, AUTO_INCREMENT)
  - code             (VARCHAR(20), NOT NULL, UNIQUE)
  - name             (VARCHAR(100), NOT NULL, UNIQUE)
  - description      (VARCHAR(255), NULL)
  - default_start_time (TIME, NULL)
  - default_end_time   (TIME, NULL)
  - ordinal          (TINYINT UNSIGNED, DEFAULT 1, UNIQUE)
  - is_active        (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at       (TIMESTAMP, NULL)
SOFT DELETES: Yes
```

#### 7.1.4 tt_day_type

```
TABLE: tt_day_type
DATABASE: tenant_db
PURPOSE: Day classification (Study, Holiday, Exam, Special, PTM, Sports, Annual)
COLUMNS:
  - id               (TINYINT UNSIGNED, PK, AUTO_INCREMENT)
  - code             (VARCHAR(20), NOT NULL, UNIQUE)
  - name             (VARCHAR(100), NOT NULL, UNIQUE)
  - description      (VARCHAR(255), NULL)
  - is_working_day   (TINYINT(1), NOT NULL, DEFAULT 1)
  - reduced_periods  (TINYINT(1), NOT NULL, DEFAULT 0)
  - ordinal          (TINYINT UNSIGNED, DEFAULT 1, UNIQUE)
  - is_active        (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at       (TIMESTAMP, NULL)
SOFT DELETES: Yes
```

#### 7.1.5 tt_period_type

```
TABLE: tt_period_type
DATABASE: tenant_db
PURPOSE: Period types (Theory, Teaching, Practical, Break, Lunch, Assembly, Exam, Recess, Free)
COLUMNS:
  - id                 (TINYINT UNSIGNED, PK, AUTO_INCREMENT)
  - code               (VARCHAR(30), NOT NULL, UNIQUE)
  - name               (VARCHAR(100), NOT NULL)
  - description        (VARCHAR(255), NULL)
  - color_code         (VARCHAR(10), NULL) — e.g., '#FF0000'
  - icon               (VARCHAR(50), NULL) — e.g., 'fa-solid fa-chalkboard'
  - is_schedulable     (TINYINT(1), NOT NULL, DEFAULT 1)
  - counts_as_teaching (TINYINT(1), NOT NULL, DEFAULT 0)
  - counts_as_workload (TINYINT(1), NOT NULL, DEFAULT 0)
  - is_break           (TINYINT(1), NOT NULL, DEFAULT 0)
  - is_free_period     (TINYINT(1), NOT NULL, DEFAULT 0)
  - ordinal            (TINYINT UNSIGNED, DEFAULT 1, UNIQUE)
  - duration_minutes   (INT UNSIGNED, DEFAULT 30)
  - is_active          (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at         (TIMESTAMP, NULL)
SOFT DELETES: Yes
```

#### 7.1.6 tt_school_days

```
TABLE: tt_school_days
DATABASE: tenant_db
PURPOSE: School week day configuration (Monday-Sunday)
COLUMNS:
  - id             (TINYINT UNSIGNED, PK, AUTO_INCREMENT)
  - code           (VARCHAR(10), NOT NULL, UNIQUE) — e.g., 'MON'
  - name           (VARCHAR(20), NOT NULL) — e.g., 'Monday'
  - short_name     (VARCHAR(5), NOT NULL) — e.g., 'Mon'
  - day_of_week    (TINYINT UNSIGNED, NOT NULL, UNIQUE) — 1-7 ISO
  - ordinal        (TINYINT UNSIGNED, NOT NULL) — Display order
  - is_school_day  (TINYINT(1), NOT NULL, DEFAULT 1)
  - is_active      (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at     (TIMESTAMP, NULL)
SOFT DELETES: Yes
```

#### 7.1.7 tt_period_set

```
TABLE: tt_period_set
DATABASE: tenant_db
PURPOSE: Period templates (e.g., "Standard 8-Period Day", "Exam 3-Period", "Half Day 4-Period")
COLUMNS:
  - id                   (INT UNSIGNED, PK, AUTO_INCREMENT)
  - code                 (VARCHAR(30), NOT NULL, UNIQUE)
  - name                 (VARCHAR(100), NOT NULL)
  - description          (VARCHAR(255), NULL)
  - total_periods        (TINYINT UNSIGNED, NOT NULL)
  - teaching_periods     (TINYINT UNSIGNED, NOT NULL)
  - exam_periods         (TINYINT UNSIGNED, NOT NULL)
  - free_periods         (TINYINT UNSIGNED, NOT NULL)
  - assembly_periods     (TINYINT UNSIGNED, NOT NULL)
  - short_break_periods  (TINYINT UNSIGNED, NOT NULL)
  - lunch_break_periods  (TINYINT UNSIGNED, NOT NULL)
  - day_start_time       (TIME, NOT NULL)
  - day_end_time         (TIME, NOT NULL)
  - is_default           (TINYINT(1), DEFAULT 0)
  - is_active            (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at           (TIMESTAMP, NULL)
SOFT DELETES: Yes
```

#### 7.1.8 tt_period_set_period_jnt

```
TABLE: tt_period_set_period_jnt
DATABASE: tenant_db
PURPOSE: Individual periods within a period set with timing
COLUMNS:
  - id               (INT UNSIGNED, PK, AUTO_INCREMENT)
  - period_set_id    (INT UNSIGNED, NOT NULL) — FK → tt_period_set(id) ON DELETE CASCADE
  - period_ord       (TINYINT UNSIGNED, NOT NULL) — 1-8 ordinal
  - code             (VARCHAR(20), NOT NULL) — e.g., 'P-1'
  - short_name       (VARCHAR(50), NOT NULL) — e.g., 'Period-1'
  - period_type_id   (INT UNSIGNED, NOT NULL) — FK → tt_period_type(id) ON DELETE RESTRICT
  - start_time       (TIME, NOT NULL)
  - end_time         (TIME, NOT NULL)
  - duration_minutes (SMALLINT UNSIGNED, GENERATED) — TIMESTAMPDIFF(MINUTE, start_time, end_time)
  - is_active        (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at       (TIMESTAMP, NULL)
UNIQUE KEYS: uq_psp_set_ord (period_set_id, period_ord), uq_psp_set_code (period_set_id, code)
CONSTRAINTS: CHK end_time > start_time
SOFT DELETES: Yes
```

#### 7.1.9 tt_timetable_type

```
TABLE: tt_timetable_type
DATABASE: tenant_db
PURPOSE: Timetable modes (Standard, Unit Test, Half Day, Exam)
COLUMNS:
  - id                 (INT UNSIGNED, PK, AUTO_INCREMENT)
  - code               (VARCHAR(30), NOT NULL, UNIQUE)
  - name               (VARCHAR(100), NOT NULL)
  - description        (VARCHAR(255), NULL)
  - shift_id           (INT UNSIGNED, NULL) — FK → tt_shift(id)
  - effective_from_date (DATE, NULL)
  - effective_to_date   (DATE, NULL)
  - school_start_time  (TIME, NULL)
  - school_end_time    (TIME, NULL)
  - has_exam           (TINYINT(1), NOT NULL, DEFAULT 0)
  - has_teaching       (TINYINT(1), NOT NULL, DEFAULT 1)
  - ordinal            (SMALLINT UNSIGNED, DEFAULT 1)
  - is_default         (TINYINT(1), DEFAULT 0)
  - is_active          (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at         (TIMESTAMP, NULL)
CONSTRAINTS: CHK school_end_time > school_start_time, effective_from_date <= effective_to_date
SOFT DELETES: Yes
```

#### 7.1.10 tt_timetable

```
TABLE: tt_timetable
DATABASE: tenant_db
PURPOSE: Main timetable record — one per generated schedule
COLUMNS:
  - id                      (INT UNSIGNED, PK, AUTO_INCREMENT)
  - code                    (VARCHAR(50), NOT NULL, UNIQUE)
  - name                    (VARCHAR(200), NOT NULL)
  - description             (TEXT, NULL)
  - academic_session_id     (INT UNSIGNED, NOT NULL) — FK → sch_org_academic_sessions_jnt(id)
  - academic_term_id        (INT UNSIGNED, NOT NULL) — FK → sch_academic_term(id)
  - timetable_type_id       (INT UNSIGNED, NOT NULL) — FK → tt_timetable_type(id)
  - period_set_id           (INT UNSIGNED, NOT NULL) — FK → tt_period_set(id)
  - effective_from          (DATE, NOT NULL)
  - effective_to            (DATE, NULL)
  - generation_method       (ENUM: MANUAL,SEMI_AUTO,FULL_AUTO, DEFAULT 'MANUAL')
  - version                 (SMALLINT UNSIGNED, NOT NULL, DEFAULT 1)
  - parent_timetable_id     (INT UNSIGNED, NULL) — FK → tt_timetable(id) (self-referencing for versions)
  - status                  (ENUM: DRAFT,GENERATING,GENERATED,PUBLISHED,ARCHIVED, DEFAULT 'DRAFT')
  - published_at            (TIMESTAMP, NULL)
  - published_by            (INT UNSIGNED, NULL) — FK → sys_users(id)
  - constraint_violations   (INT UNSIGNED, DEFAULT 0)
  - soft_score              (DECIMAL(8,2), NULL)
  - stats_json              (JSON, NULL)
  - generation_strategy_id  (INT UNSIGNED, NULL) — FK → tt_generation_strategy(id)
  - optimization_cycles     (INT UNSIGNED, DEFAULT 0)
  - last_optimized_at       (TIMESTAMP, NULL)
  - quality_score           (DECIMAL(5,2), NULL) — 0-100
  - teacher_satisfaction_score (DECIMAL(5,2), NULL)
  - room_utilization_score  (DECIMAL(5,2), NULL)
  - is_active               (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_by              (INT UNSIGNED, NULL) — FK → sys_users(id)
  - created_at, updated_at  (TIMESTAMP)
  - deleted_at              (TIMESTAMP, NULL)
INDEXES: idx_tt_session, idx_tt_type, idx_tt_status, idx_tt_effective
SOFT DELETES: Yes
```

#### 7.1.11 tt_timetable_cell

```
TABLE: tt_timetable_cell
DATABASE: tenant_db
PURPOSE: Individual time slots — one row per (timetable × day × period × class_group)
COLUMNS:
  - id                   (INT UNSIGNED, PK, AUTO_INCREMENT)
  - timetable_id         (INT UNSIGNED, NOT NULL) — FK → tt_timetable(id) ON DELETE CASCADE
  - generation_run_id    (INT UNSIGNED, NULL) — FK → tt_generation_run(id)
  - day_of_week          (TINYINT UNSIGNED, NOT NULL) — 1-7
  - period_ord           (TINYINT UNSIGNED, NOT NULL) — Period ordinal
  - cell_date            (DATE, NULL) — Specific date (optional)
  - class_group_id       (INT UNSIGNED, NULL) — FK → sch_class_groups_jnt(id)
  - class_subgroup_id    (INT UNSIGNED, NULL) — FK → tt_requirement_subgroups(id)
  - activity_id          (INT UNSIGNED, NULL) — FK → tt_activity(id)
  - sub_activity_id      (INT UNSIGNED, NULL) — FK → tt_sub_activity(id)
  - room_id              (INT UNSIGNED, NULL) — FK → sch_rooms(id)
  - source               (ENUM: AUTO,MANUAL,SWAP,LOCK, DEFAULT 'AUTO')
  - is_locked            (TINYINT(1), NOT NULL, DEFAULT 0)
  - locked_by            (INT UNSIGNED, NULL) — FK → sys_users(id)
  - locked_at            (TIMESTAMP, NULL)
  - has_conflict         (TINYINT(1), DEFAULT 0)
  - conflict_details_json (JSON, NULL)
  - is_active            (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at           (TIMESTAMP, NULL)
UNIQUE KEYS: uq_cell_tt_day_period_group (timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id)
CONSTRAINTS: CHK (class_group_id IS NOT NULL XOR class_subgroup_id IS NOT NULL)
INDEXES: idx_cell_tt, idx_cell_day_period, idx_cell_activity, idx_cell_room, idx_cell_date
SOFT DELETES: Yes
```

#### 7.1.12 tt_activity

```
TABLE: tt_activity
DATABASE: tenant_db
PURPOSE: Atomic scheduling unit — (Class+Section+Subject+StudyFormat)
COLUMNS:
  - id                          (INT UNSIGNED, PK, AUTO_INCREMENT)
  - code                        (VARCHAR(50), NOT NULL, UNIQUE)
  - name                        (VARCHAR(200), NOT NULL)
  - academic_term_id            (INT UNSIGNED, NOT NULL) — FK
  - timetable_type_id           (INT UNSIGNED, NOT NULL) — FK
  - activity_group_id           (INT UNSIGNED, NULL) — FK → sch_class_groups_jnt(id)
  - have_sub_activity           (TINYINT(1), NOT NULL, DEFAULT 0)
  - class_id                    (INT UNSIGNED, NOT NULL) — FK
  - section_id                  (INT UNSIGNED, NULL) — FK
  - subject_id                  (INT UNSIGNED, NOT NULL) — FK
  - study_format_id             (INT UNSIGNED, NOT NULL) — FK
  - subject_type_id             (INT UNSIGNED, NOT NULL) — FK
  - subject_study_format_id     (INT UNSIGNED, NOT NULL) — FK
  - required_weekly_periods     (TINYINT UNSIGNED, NOT NULL, DEFAULT 1)
  - min/max_periods_per_week    (TINYINT UNSIGNED, NULL)
  - max/min_per_day             (TINYINT UNSIGNED, NULL)
  - min_gap_periods             (TINYINT UNSIGNED, NULL)
  - allow_consecutive           (TINYINT(1), NOT NULL, DEFAULT 0)
  - max_consecutive             (TINYINT UNSIGNED, DEFAULT 2)
  - preferred_periods_json      (JSON, NULL) — User-editable preferred slots
  - avoid_periods_json          (JSON, NULL) — User-editable avoid slots
  - spread_evenly               (TINYINT(1), DEFAULT 1)
  - eligible_teacher_count      (INT UNSIGNED, NULL)
  - min/max_teacher_availability_score (DECIMAL(7,2), DEFAULT 1)
  - duration_periods            (TINYINT UNSIGNED, NOT NULL, DEFAULT 1) — 1=single, 2=double, 3=triple
  - weekly_periods              (TINYINT UNSIGNED, NOT NULL, DEFAULT 1)
  - total_periods               (SMALLINT UNSIGNED, GENERATED) — duration_periods × weekly_periods
  - split_allowed               (TINYINT(1), DEFAULT 0)
  - is_compulsory               (TINYINT(1), DEFAULT 1)
  - priority                    (TINYINT UNSIGNED, DEFAULT 50) — 0-100
  - difficulty_score            (TINYINT UNSIGNED, DEFAULT 50) — 0-100
  - compulsory_specific_room_type (TINYINT(1), NOT NULL, DEFAULT 0)
  - required_room_type_id       (INT UNSIGNED, NOT NULL) — FK
  - required_room_id            (INT UNSIGNED, NULL) — FK
  - requires_room               (TINYINT(1), DEFAULT 1)
  - preferred_room_type_id      (INT UNSIGNED, NULL) — FK
  - preferred_room_ids          (JSON, NULL)
  - status                      (ENUM: DRAFT,ACTIVE,LOCKED,ARCHIVED, DEFAULT 'ACTIVE')
  - is_active                   (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_by                  (INT UNSIGNED, NULL) — FK
  - created_at, updated_at      (TIMESTAMP)
  - deleted_at                  (TIMESTAMP, NULL)
INDEXES: idx_activity_difficulty, idx_activity_session, idx_activity_class_group, idx_activity_subject, idx_activity_status, idx_activity_generation (composite)
SOFT DELETES: Yes
```

#### 7.1.13 tt_constraint_category_scope

```
TABLE: tt_constraint_category_scope
DATABASE: tenant_db
PURPOSE: Unified lookup for constraint categories AND scopes, differentiated by type ENUM
COLUMNS:
  - id          (INT UNSIGNED, PK, AUTO_INCREMENT)
  - type        (ENUM: CATEGORY,SCOPE, NOT NULL)
  - code        (VARCHAR(30), NOT NULL) — Immutable
  - name        (VARCHAR(100), NOT NULL) — User-editable
  - description (VARCHAR(255), NULL)
  - is_active   (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at  (TIMESTAMP, NULL)
UNIQUE KEYS: uq_constraint_category_scope (type, code)
CRITICAL NOTE: ConstraintCategory and ConstraintScope models BOTH point to this table.
  ConstraintCategory applies global scope WHERE type = 'CATEGORY'.
  ConstraintScope applies global scope WHERE type = 'SCOPE'.
SOFT DELETES: Yes
```

#### 7.1.14 tt_constraint

```
TABLE: tt_constraint
DATABASE: tenant_db
PURPOSE: Concrete constraint instances — ONE table for ALL constraints (teacher, class, room, global)
COLUMNS:
  - id                  (INT UNSIGNED, PK, AUTO_INCREMENT)
  - constraint_type_id  (INT UNSIGNED, NOT NULL) — FK → tt_constraint_type(id)
  - name                (VARCHAR(200), NULL)
  - description         (VARCHAR(500), NULL)
  - academic_term_id    (INT UNSIGNED, NULL) — FK → sch_academic_term(id)
  - target_type         (INT UNSIGNED, NOT NULL) — FK → tt_constraint_category_scope(id)
  - target_id           (INT UNSIGNED, NULL) — NULL for global constraints
  - is_hard             (TINYINT(1), NOT NULL, DEFAULT 0)
  - weight              (TINYINT UNSIGNED, NOT NULL, DEFAULT 100) — 1-100
  - params_json         (JSON, NOT NULL) — Constraint parameters
  - effective_from      (DATE, NULL)
  - effective_to        (DATE, NULL)
  - apply_for_all_days  (TINYINT(1), NOT NULL, DEFAULT 1)
  - applicable_days     (JSON, NULL) — Day-specific application
  - impact_score        (TINYINT UNSIGNED, DEFAULT 50)
  - is_active           (TINYINT(1), NOT NULL, DEFAULT 1)
  - created_by          (INT UNSIGNED, NULL) — FK → sys_users(id)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at          (TIMESTAMP, NULL)
INDEXES: idx_constraint_type, idx_constraint_target (target_type, target_id)
DESIGN NOTE: All constraints stored in one table. New constraint types added via JSON params_json without schema changes.
SOFT DELETES: Yes
```

#### 7.1.15 tt_generation_run

```
TABLE: tt_generation_run
DATABASE: tenant_db
PURPOSE: Audit log for each timetable generation attempt
COLUMNS:
  - id                      (INT UNSIGNED, PK, AUTO_INCREMENT)
  - timetable_id            (INT UNSIGNED, NOT NULL) — FK → tt_timetable(id) ON DELETE CASCADE
  - run_number              (INT UNSIGNED, NOT NULL, DEFAULT 1)
  - started_at              (TIMESTAMP, NOT NULL)
  - finished_at             (TIMESTAMP, NULL)
  - status                  (ENUM: QUEUED,RUNNING,COMPLETED,FAILED,CANCELLED, DEFAULT 'QUEUED')
  - strategy_id             (INT UNSIGNED, NULL) — FK → tt_generation_strategy(id)
  - algorithm_version       (VARCHAR(20), NULL)
  - max_recursion_depth     (INT UNSIGNED, DEFAULT 14)
  - max_placement_attempts  (INT UNSIGNED, NULL)
  - retry_count             (TINYINT UNSIGNED, DEFAULT 0)
  - params_json             (JSON, NULL) — Generation parameters
  - activities_total        (INT UNSIGNED, DEFAULT 0)
  - activities_placed       (INT UNSIGNED, DEFAULT 0)
  - activities_failed       (INT UNSIGNED, DEFAULT 0)
  - hard_violations         (INT UNSIGNED, DEFAULT 0)
  - soft_violations         (INT UNSIGNED, DEFAULT 0)
  - soft_score              (DECIMAL(10,4), NULL)
  - stats_json              (JSON, NULL) — Detailed stats
  - error_message           (TEXT, NULL)
  - triggered_by            (INT UNSIGNED, NULL) — FK → sys_users(id)
  - created_at, updated_at  (TIMESTAMP)
  - deleted_at              (TIMESTAMP, NULL)
UNIQUE KEYS: uq_gr_tt_run (timetable_id, run_number)
INDEXES: idx_gr_status (status)
SOFT DELETES: Yes
```

#### 7.1.16 tt_teacher_availability

```
TABLE: tt_teacher_availability
DATABASE: tenant_db
PURPOSE: Pre-computed teacher capacity and eligibility for each requirement
COLUMNS:
  - id                              (INT UNSIGNED, PK, AUTO_INCREMENT)
  - requirement_consolidation_id    (INT UNSIGNED, NOT NULL) — FK
  - class_id, section_id            (INT UNSIGNED) — FK
  - subject_study_format_id         (INT UNSIGNED, NOT NULL) — FK
  - teacher_profile_id              (INT UNSIGNED, NOT NULL) — FK
  - required_weekly_periods         (TINYINT UNSIGNED, DEFAULT 1)
  - is_full_time                    (TINYINT(1), DEFAULT 1)
  - preferred_shift                 (INT UNSIGNED, NULL) — FK
  - capable_handling_multiple_classes (TINYINT(1), DEFAULT 0)
  - can_be_used_for_substitution    (TINYINT(1), DEFAULT 1)
  - certified_for_lab               (TINYINT(1), DEFAULT 0)
  - max/min_available_periods_weekly (TINYINT UNSIGNED, DEFAULT 48/36)
  - max/min_allocated_periods_weekly (TINYINT UNSIGNED, DEFAULT 1)
  - can_be_split_across_sections    (TINYINT(1), DEFAULT 0)
  - proficiency_percentage          (TINYINT UNSIGNED, NULL) — 1-100
  - teaching_experience_months      (SMALLINT UNSIGNED, NULL)
  - is_primary_subject              (TINYINT(1), DEFAULT 1)
  - competancy_level                (ENUM: Facilitator,Basic,Intermediate,Advanced,Expert, DEFAULT 'Basic')
  - priority_order, priority_weight (INT/TINYINT, NULL) — 1-10
  - scarcity_index                  (TINYINT UNSIGNED, NULL) — 1-10
  - is_hard_constraint              (TINYINT(1), DEFAULT 0)
  - allocation_strictness           (ENUM: Hard,Medium,Soft, DEFAULT 'Medium')
  - historical_success_ratio        (TINYINT UNSIGNED, NULL) — 1-100
  - is_primary_teacher, is_preferred_teacher (TINYINT(1))
  - preference_score                (TINYINT UNSIGNED, NULL) — 1-100
  - min/max_teacher_availability_score (DECIMAL(7,2), DEFAULT 1)
  - GENERATED columns: available_for_full_timetable_duration, no_of_days_not_available
  - activity_id                     (INT UNSIGNED, NULL) — FK
  - is_active                       (TINYINT(1), NOT NULL, DEFAULT 1)
UNIQUE KEYS: uq_ta_requirement_teacher (requirement_consolidation_id, teacher_profile_id)
```

#### 7.1.17 tt_parallel_group (Migration-only — not in DDL)

```
TABLE: tt_parallel_group
DATABASE: tenant_db
CREATED BY: 2026_03_12_000001_create_tt_parallel_group_table.php
PURPOSE: Groups of activities that must be scheduled simultaneously
COLUMNS:
  - id                    (BIGINT UNSIGNED, PK, AUTO_INCREMENT)
  - code                  (VARCHAR(60), NOT NULL, UNIQUE)
  - name                  (VARCHAR(150), NOT NULL)
  - description           (VARCHAR(255), NULL)
  - academic_term_id      (BIGINT UNSIGNED, NULL) — FK
  - group_type            (ENUM: PARALLEL_SECTION,PARALLEL_OPTIONAL,PARALLEL_SKILL,PARALLEL_HOBBY,PARALLEL_CUSTOM, DEFAULT 'PARALLEL_CUSTOM')
  - coordination_type     (ENUM: SAME_TIME,SAME_DAY,SAME_PERIOD_RANGE, DEFAULT 'SAME_TIME')
  - requires_same_teacher (BOOLEAN, DEFAULT FALSE)
  - requires_same_room_type (BOOLEAN, DEFAULT FALSE)
  - scheduling_priority   (TINYINT UNSIGNED, NOT NULL, DEFAULT 75)
  - is_hard_constraint    (BOOLEAN, NOT NULL, DEFAULT TRUE)
  - weight                (TINYINT UNSIGNED, NOT NULL, DEFAULT 100)
  - is_active             (BOOLEAN, NOT NULL, DEFAULT TRUE)
  - created_by            (BIGINT UNSIGNED, NULL)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at            (TIMESTAMP, NULL)
INDEXES: group_type, academic_term_id
SOFT DELETES: Yes
```

#### 7.1.18 tt_parallel_group_activity (Migration-only — not in DDL)

```
TABLE: tt_parallel_group_activity
DATABASE: tenant_db
CREATED BY: 2026_03_12_000002_create_tt_parallel_group_activity_table.php
PURPOSE: Links activities to parallel groups with anchor designation
COLUMNS:
  - id                (BIGINT UNSIGNED, PK, AUTO_INCREMENT)
  - parallel_group_id (BIGINT UNSIGNED, NOT NULL) — FK → tt_parallel_group(id) ON DELETE CASCADE
  - activity_id       (BIGINT UNSIGNED, NOT NULL) — FK → tt_activities(id) ON DELETE CASCADE
  - sequence_order    (TINYINT UNSIGNED, NOT NULL, DEFAULT 1)
  - is_anchor         (BOOLEAN, NOT NULL, DEFAULT FALSE) — Anchor is placed first, siblings follow
  - is_active         (BOOLEAN, NOT NULL, DEFAULT TRUE)
  - created_at, updated_at (TIMESTAMP)
  - deleted_at        (TIMESTAMP, NULL)
UNIQUE KEYS: uq_pga_group_activity (parallel_group_id, activity_id)
SOFT DELETES: Yes
```

### 7.2 Table Groups & Functional Areas

#### Group 1: Master / Configuration Tables (8 tables)
| Table | Purpose |
|-------|---------|
| `tt_config` | Key-value configuration settings |
| `tt_generation_strategy` | Algorithm configurations |
| `tt_shift` | School shifts |
| `tt_day_type` | Day classifications |
| `tt_period_type` | Period classifications |
| `tt_teacher_assignment_role` | Teacher roles |
| `tt_school_days` | Days of week |
| `tt_priority_config` | Priority weights for activity scoring |

#### Group 2: Calendar / Schedule Tables (3 tables)
| Table | Purpose |
|-------|---------|
| `tt_working_day` | Calendar with day types per date |
| `tt_class_working_day_jnt` | Class-specific day overrides |
| `tt_period_set` + `tt_period_set_period_jnt` | Period template definitions |

#### Group 3: Timetable Type & Class Mapping (2 tables)
| Table | Purpose |
|-------|---------|
| `tt_timetable_type` | Timetable mode definitions |
| `tt_class_timetable_type_jnt` | Maps timetable types to classes with period sets |

#### Group 4: Requirement Tables (4 tables)
| Table | Purpose |
|-------|---------|
| `tt_slot_requirement` | Weekly slot caps per class-section |
| `tt_class_requirement_groups` | Compulsory subject requirements |
| `tt_class_requirement_subgroups` | Optional/elective requirements |
| `tt_requirement_consolidation` | Flattened unified requirement view |

#### Group 5: Constraint Engine Tables (5 tables)
| Table | Purpose |
|-------|---------|
| `tt_constraint_category_scope` | Categories + Scopes (unified, type ENUM) |
| `tt_constraint_type` | Constraint blueprints with parameter schemas |
| `tt_constraint` | Concrete constraint instances |
| `tt_teacher_unavailable` | Teacher blackout periods |
| `tt_room_unavailable` | Room blackout periods |

#### Group 6: Resource Availability Tables (4 tables)
| Table | Purpose |
|-------|---------|
| `tt_teacher_availability` | Teacher capacity snapshot per requirement |
| `tt_teacher_availability_detail` | Per-day-per-period teacher availability |
| `tt_room_availability` | Room capacity snapshot |
| `tt_room_availability_detail` | Per-day-per-period room availability |

#### Group 7: Activity Tables (4 tables)
| Table | Purpose |
|-------|---------|
| `tt_activity` | Atomic scheduling units |
| `tt_sub_activity` | Sub-divisions for batched activities |
| `tt_activity_priority` | Calculated priority scores |
| `tt_activity_teacher` | Teacher-activity assignments |

#### Group 8: Parallel Group Tables (2 tables)
| Table | Purpose |
|-------|---------|
| `tt_parallel_group` | Parallel activity groups |
| `tt_parallel_group_activity` | Activity-group links with anchor flag |

#### Group 9: Timetable Output Tables (4 tables)
| Table | Purpose |
|-------|---------|
| `tt_timetable` | Main timetable records |
| `tt_timetable_cell` | Individual grid cells |
| `tt_timetable_cell_teacher` | Multi-teacher assignments per cell |
| `tt_resource_booking` | Resource allocations |

#### Group 10: Generation & Optimization Tables (5 tables)
| Table | Purpose |
|-------|---------|
| `tt_generation_run` | Generation attempt audit logs |
| `tt_generation_queue` | Job queue management |
| `tt_optimization_run` | Post-gen optimization runs |
| `tt_optimization_iteration` | Optimization iteration tracking |
| `tt_optimization_move` | Individual optimization moves |

#### Group 11: Conflict & Validation Tables (4 tables)
| Table | Purpose |
|-------|---------|
| `tt_conflict_detection` | Real-time/batch conflict events |
| `tt_constraint_violation` | Constraint violation logs |
| `tt_conflict_resolution_session` | Resolution workflow |
| `tt_conflict_resolution_option` | Resolution alternatives |

#### Group 12: Analytics Tables (3 tables)
| Table | Purpose |
|-------|---------|
| `tt_analytics_daily_snapshot` | Daily analytics snapshots |
| `tt_teacher_workload` | Teacher workload summaries |
| `tt_room_utilization` | Room utilization metrics |

#### Group 13: Change Management Tables (3 tables)
| Table | Purpose |
|-------|---------|
| `tt_change_log` | Audit trail for manual edits |
| `tt_batch_operation` | Batch operation tracking |
| `tt_batch_operation_item` | Individual batch items |

#### Group 14: Substitution & Absence Tables (5 tables)
| Table | Purpose |
|-------|---------|
| `tt_teacher_absence` | Teacher absence records |
| `tt_substitution_log` | Substitution assignments |
| `tt_substitution_pattern` | ML pattern learning |
| `tt_substitution_recommendation` | Ranked substitute recommendations |

#### Group 15: Approval Workflow Tables (5 tables)
| Table | Purpose |
|-------|---------|
| `tt_approval_workflow` | Workflow definitions |
| `tt_approval_level` | Multi-level approval hierarchy |
| `tt_approval_request` | Approval requests |
| `tt_approval_decision` | Per-level decisions |
| `tt_approval_notification` | Approval notifications |

#### Group 16: ML / Prediction Tables (4 tables)
| Table | Purpose |
|-------|---------|
| `tt_ml_model` | ML model registry |
| `tt_training_data` | Training datasets |
| `tt_feature_importance` | Feature rankings |
| `tt_prediction_log` | Prediction audit |

#### Group 17: Advanced Analysis Tables (6 tables)
| Table | Purpose |
|-------|---------|
| `tt_impact_analysis_session` | Impact analysis sessions |
| `tt_impact_analysis_detail` | Impact details |
| `tt_version_comparison` | Timetable version comparisons |
| `tt_version_comparison_detail` | Comparison details |
| `tt_what_if_scenario` | What-if scenarios |
| `tt_revalidation_schedule` + `tt_revalidation_trigger` | Automated revalidation |

#### Group 18: Escalation Tables (2 tables)
| Table | Purpose |
|-------|---------|
| `tt_escalation_rule` | Escalation rules |
| `tt_escalation_log` | Escalation events |

### 7.3 Entity-Relationship Summary

**Cross-Module Table Dependencies:**

| External Module | Tables Referenced | Used By SmartTimetable For |
|----------------|-------------------|---------------------------|
| **SchoolSetup** | `sch_classes`, `sch_sections`, `sch_class_section_jnt` | Class + Section identification, student counts, house rooms |
| **SchoolSetup** | `sch_subjects`, `sch_study_formats`, `sch_subject_study_format_jnt`, `sch_subject_types` | Subject + Study format + Type for requirement/activity definition |
| **SchoolSetup** | `sch_teacher_profile`, `sch_teacher_capabilities` | Teacher data, proficiency, experience, availability scores |
| **SchoolSetup** | `sch_rooms`, `sch_rooms_type`, `sch_buildings` | Room allocation, capacity checks, building movement constraints |
| **SchoolSetup** | `sch_employees` | Employee base records for teachers |
| **SchoolSetup** | `sch_class_groups_jnt` | Curriculum: subject groups per class |
| **SchoolSetup** | `sch_org_academic_sessions_jnt`, `sch_academic_term` | Academic session and term scoping |
| **Prime** | `prm_academic_sessions` | Academic session metadata |
| **SystemConfig** | `sys_users` | Audit trails (created_by, changed_by, published_by) |

### 7.4 Junction Tables

| Junction Table | Connects | Extra Columns | Population Method |
|---------------|----------|---------------|-------------------|
| `tt_period_set_period_jnt` | Period Set ↔ Period Type | period_ord, code, start/end_time, duration_minutes (GENERATED) | Manual CRUD |
| `tt_class_timetable_type_jnt` | Class ↔ Timetable Type | period_set_id, applies_to_all_sections, weekly period counts | Manual CRUD |
| `tt_class_working_day_jnt` | Class ↔ Working Day | is_exam_day, is_ptm_day, is_half_day, is_holiday | Auto-generated from calendar |
| `tt_activity_teacher` | Activity ↔ Teacher | assignment_role_id, is_required, ordinal | Auto from teacher availability |
| `tt_timetable_cell_teacher` | Timetable Cell ↔ Teacher | assignment_role_id, is_substitute | Auto during generation |
| `tt_parallel_group_activity` | Parallel Group ↔ Activity | sequence_order, is_anchor | Manual configuration |
| `tt_constraint_group_member` | Constraint Group ↔ Constraint | ordinal | Manual configuration |

### 7.5 Cross-Module Table Dependencies (ER Map)

```
                          ┌──────────────────┐
                          │  sch_academic_term│ ◄─── tt_activity, tt_timetable,
                          │  (SchoolSetup)    │      tt_requirement_consolidation,
                          └──────────────────┘      tt_constraint, tt_parallel_group
                                    │
                                    ▼
┌──────────┐   ┌──────────────┐   ┌──────────────────────┐
│sch_classes│──►│sch_class_    │──►│tt_class_requirement_  │
│           │   │section_jnt   │   │groups / subgroups     │
│sch_sections│  │(+room,students)│ └──────────┬───────────┘
└──────────┘   └──────────────┘              │
      │                                       ▼
      │         ┌──────────────┐   ┌──────────────────────┐
      │         │sch_subjects  │──►│tt_requirement_        │
      │         │sch_study_    │   │consolidation          │
      │         │formats       │   └──────────┬───────────┘
      │         │sch_subject_  │              │
      │         │types         │              ▼
      │         └──────────────┘   ┌──────────────────────┐
      │                            │   tt_activity          │◄── tt_parallel_group_activity
      │                            │   (scheduling unit)    │
      │                            └──────────┬───────────┘
      │                                       │
      │    ┌───────────────┐                  ▼
      │    │sch_teacher_   │──►  ┌──────────────────────┐
      └───►│profile        │    │tt_teacher_availability │
           │sch_teacher_   │    └──────────────────────┘
           │capabilities   │
           └───────────────┘
                                  ┌──────────────────────┐
  ┌──────────┐                    │   tt_timetable        │
  │sch_rooms │──► tt_room_avail ─►│   tt_timetable_cell   │
  │sch_rooms_│                    │   tt_resource_booking  │
  │type      │                    └──────────────────────┘
  └──────────┘
```

---

*End of Sections 5-7 — Run 2 Complete*

---

## 8. Data Flow — Operation by Operation

This section documents every significant operation that reads or writes data, tracing the complete flow from trigger to database.

### 8.1 Generate Timetable with FET

```
OPERATION: Generate Timetable (FET Algorithm)
TRIGGER: POST form submit from generation page → TimetableGenerationController::generateWithFET()
ROUTE: POST /smart-timetable/generate/generate-fet
AUTHORIZATION: smart-timetable.timetable.generate

INPUT SOURCE:
  - User Input: academic_term_id, timetable_type_id
  - User Options: use_existing_activities (bool), optimize_for_teachers (bool),
    optimize_for_students (bool), avoid_gaps (bool), class_teacher_first_lecture (bool),
    single_activity_once_per_day_until_overflow (bool), pin_activities_by_period (bool),
    max_generation_time (int, 1-300s), max_retry_attempts (int, 1-20)
  - Table: tt_class_timetable_type_jnt → period_set_id lookup
  - Table: tt_activities → All active activities for term+type
  - Table: tt_constraints → Active constraints
  - Table: tt_teacher_availability → Teacher capacity snapshots
  - Table: tt_room_availability → Room capacity snapshots
  - Table: tt_parallel_group + tt_parallel_group_activity → Parallel groups

PROCESSING:
  Step 1: Validate input (Laravel validation rules)
  Step 2: Acquire distributed lock (Cache::lock, 5min timeout) — prevents concurrent generation
  Step 3: Handle stale lock detection with force-release if needed
  Step 4: Set PHP max_execution_time
  Step 5: Call TimetableGenerationService::generate() which:
    5a: Loads all activities sorted by difficulty/priority
    5b: Loads all constraints (hard + soft) via DatabaseConstraintService
    5c: Builds slot matrix (days × periods)
    5d: Runs FETSolver::solve() — main algorithm
    5e: Returns GenerationResult with grid, stats, conflicts
  Step 6: Store result to session for preview
  Step 7: Build preview view data

OUTPUT TARGET:
  - Session storage: generated_timetable_grid, generated_activities, generated_days,
    generated_periods, generated_conflicts, generated_selected_teacher_by_slot,
    generated_room_by_slot, generated_forced_placements, generation_run_meta,
    generation_run_stats
  - No DB writes yet — result held in session until user confirms via storeTimetable

VALIDATION:
  - academic_term_id: required, exists in sch_academic_term
  - timetable_type_id: required, exists in tt_timetable_types
  - Lock acquisition: fails if another generation is running

ERROR HANDLING:
  - Validation failure: redirect back with errors
  - Lock failure: redirect back with "generation already in progress" message
  - Generation failure: redirect back with error details
  - Stale lock: force-release after timeout

RESPONSE: View smarttimetable::preview.index with generation results
```

### 8.2 Store Generated Timetable to Database

```
OPERATION: Store Generated Timetable (Persist to DB)
TRIGGER: POST form submit from preview page → TimetableGenerationController::storeTimetable()
ROUTE: POST /smart-timetable/store
AUTHORIZATION: smart-timetable.timetable.store

INPUT SOURCE:
  - User Input: timetable_name (required, max 200), academic_session_id (required),
    academic_term_id, timetable_type_id, period_set_id, effective_from (date),
    effective_to (date, nullable)
  - Session: generated_timetable_grid, generated_activities, generated_periods,
    generated_selected_teacher_by_slot, generated_room_by_slot,
    generated_forced_placements, generation_run_meta, generation_run_stats
  - Table: tt_activities → Reloaded with teacher relations
  - Table: tt_school_days → day_id → day_of_week lookup
  - Table: tt_teacher_assignment_role → Default role (is_primary_instructor=true)

PROCESSING:
  Step 1: Validate session data exists
  Step 2: Begin DB transaction
  Step 3: CREATE tt_timetable record
    - Generate UUID and code (TT_{TERM}_{TYPE}_{YYYYMMDD_HHMMSS})
    - Set status='GENERATED', generation_method='SEMI_AUTO'
    - Set quality scores from generation stats
  Step 4: CREATE tt_generation_run record
    - Store algorithm version, params, timing, placement counts
    - Store stats_json with detailed metrics
  Step 5: Build cell insert rows (Phase A)
    - Iterate grid: for each classKey → dayId → periodId → activityId
    - Build row: timetable_id, day_of_week, period_ord, class_group_id/class_subgroup_id,
      activity_id, room_id, source='AUTO', has_conflict flag
    - Track teacher data for each cell
  Step 6: BULK INSERT tt_timetable_cells in 500-record chunks (Phase B)
  Step 7: Reload inserted cells to get auto-increment IDs (Phase C)
  Step 8: Build and BULK INSERT tt_timetable_cell_teachers in 500-record chunks (Phase D)
  Step 9: UPDATE tt_timetable with stats_json
  Step 10: Commit transaction
  Step 11: Clear all generation session keys

OUTPUT TARGET:
  - Table: tt_timetables → 1 INSERT
  - Table: tt_generation_runs → 1 INSERT
  - Table: tt_timetable_cells → N INSERTs (bulk, 500/chunk) — one per placed activity-slot
  - Table: tt_timetable_cell_teachers → N INSERTs (bulk, 500/chunk) — teacher per cell

VALIDATION:
  - timetable_name: required, string, max 200
  - academic_session_id: required
  - effective_from: required, date
  - effective_to: nullable, date, after effective_from
  - Session data must exist

ERROR HANDLING:
  - Missing session data: redirect back with error
  - DB error: full transaction rollback
  - Any exception: rollback + redirect with error message

RESPONSE: Redirect to preview route with success message
```

### 8.3 Place Cell Manually (Preview Edit Mode)

```
OPERATION: Place Activity Cell (Manual Placement via Drag-Drop)
TRIGGER: POST AJAX from preview edit mode → TimetablePreviewController::placeCell()
ROUTE: POST /smart-timetable/place-cell
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input (JSON): timetable_id (int), activity_id (int), day_of_week (1-7), period_ord (int)
  - Table: tt_activities → Activity with subject, format, room, teachers

PROCESSING:
  Step 1: Validate input
  Step 2: Load activity with 5 relations (subject, studyFormat, subjectType, requiredRoom, teachers)
  Step 3: Check for existing cell at this slot
  Step 4: If existing cell found:
    - DELETE from tt_timetable_cell_teachers (for existing cell)
    - DELETE from tt_timetable_cells (existing cell)
  Step 5: INSERT into tt_timetable_cells:
    - timetable_id, day_of_week, period_ord, activity_id
    - class_group_id or class_subgroup_id (from activity)
    - room_id (from activity's required_room)
    - source='MANUAL'
  Step 6: INSERT into tt_timetable_cell_teachers:
    - cell_id, teacher_id (first teacher from activity)
    - assignment_role_id (default primary role)
  Step 7: Count placed cells for this activity

OUTPUT TARGET:
  - Table: tt_timetable_cells → 1 DELETE (optional) + 1 INSERT
  - Table: tt_timetable_cell_teachers → 1 DELETE (optional) + 1 INSERT

RESPONSE: JSON { cell_id, subject, study_format, priority, weekly_needed, placed_count,
  remaining, room, teacher, difficulty_score }
```

### 8.4 Remove Cell

```
OPERATION: Remove Activity Cell
TRIGGER: POST AJAX → TimetablePreviewController::removeCell()
ROUTE: POST /smart-timetable/remove-cell
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input (JSON): timetable_id, day_of_week, period_ord

PROCESSING:
  Step 1: Find cell at slot
  Step 2: Check if locked → error if locked
  Step 3: DELETE from tt_timetable_cell_teachers
  Step 4: DELETE from tt_timetable_cells
  Step 5: Recalculate placed_count and remaining

OUTPUT TARGET:
  - Table: tt_timetable_cell_teachers → DELETE
  - Table: tt_timetable_cells → DELETE

RESPONSE: JSON { activity_id, placed_count, weekly_needed, remaining }
```

### 8.5 Swap Two Cells (Refinement)

```
OPERATION: Swap Two Timetable Cells
TRIGGER: POST AJAX → RefinementController::swap()
ROUTE: POST /smart-timetable/refinement/swap
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input (JSON): cell_id_1 (int), cell_id_2 (int, different from cell_id_1)

PROCESSING:
  Step 1: Validate both cells exist
  Step 2: Delegate to RefinementService::swapActivities(cell_id_1, cell_id_2)
    - Load both cells with relations
    - Check neither is locked
    - Run impact analysis (constraint check)
    - Swap activity_id, room_id, teacher assignments
    - Log change to tt_change_logs
  Step 3: Return result

OUTPUT TARGET:
  - Table: tt_timetable_cells → 2 UPDATEs (swap activity_id, room_id)
  - Table: tt_timetable_cell_teachers → UPDATE teacher assignments
  - Table: tt_change_logs → 1 INSERT (audit trail with old/new values JSON)

RESPONSE: JSON or redirect with success/failure
```

### 8.6 Lock/Unlock Cell

```
OPERATION: Toggle Cell Lock
TRIGGER: POST AJAX → RefinementController::toggleLock()
ROUTE: POST /smart-timetable/refinement/lock
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input (JSON): cell_id (int), lock (boolean)

PROCESSING:
  Step 1: Validate cell exists
  Step 2: If lock=true: RefinementService::lockCell() → set is_locked=1, locked_by, locked_at
  Step 3: If lock=false: RefinementService::unlockCell() → set is_locked=0, clear locked_by/at
  Step 4: Log change

OUTPUT TARGET:
  - Table: tt_timetable_cells → 1 UPDATE (is_locked, locked_by, locked_at)
  - Table: tt_change_logs → 1 INSERT (type='LOCK' or 'UNLOCK')

RESPONSE: JSON result
```

### 8.7 Impact Analysis

```
OPERATION: Get Swap Impact Analysis
TRIGGER: GET AJAX → RefinementController::impact()
ROUTE: GET /smart-timetable/refinement/impact/{cellId}
AUTHORIZATION: smart-timetable.timetable.view

INPUT SOURCE:
  - Route param: cellId
  - Query param: action (default 'swap')

PROCESSING:
  Step 1: Load cell with activity, teachers
  Step 2: RefinementService::getImpactAnalysis(cellId, action)
    - Identify affected entities (teachers, rooms, classes)
    - Check constraint violations that would result from swap
    - Calculate impact severity
  Step 3: Return analysis

OUTPUT TARGET: None (read-only)

RESPONSE: JSON { warnings: [...], affected_entities: [...], severity: ... }
```

### 8.8 Publish Timetable

```
OPERATION: Publish Timetable
TRIGGER: POST AJAX → TimetablePublishController::publishTimetable()
ROUTE: POST /smart-timetable/timetable/{id}/publish
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - Route param: timetable id

PROCESSING:
  Step 1: Load timetable
  Step 2: Set status='PUBLISHED', published_at=now(), published_by=auth()->id()
  Step 3: Save

OUTPUT TARGET:
  - Table: tt_timetables → 1 UPDATE (status, published_at, published_by)

RESPONSE: JSON { success: true, message: 'Timetable published successfully.' }
```

### 8.9 Unpublish Timetable

```
OPERATION: Unpublish Timetable
TRIGGER: POST AJAX → TimetablePublishController::unpublishTimetable()
ROUTE: POST /smart-timetable/timetable/{id}/unpublish

PROCESSING:
  Step 1: Set status='DRAFT', published_at=null, published_by=null

OUTPUT TARGET:
  - Table: tt_timetables → 1 UPDATE (revert to DRAFT state)

RESPONSE: JSON { success: true, message: 'Timetable unpublished.' }
```

### 8.10 Report Teacher Absence

```
OPERATION: Report Teacher Absence
TRIGGER: POST form submit → SubstitutionController::reportAbsence()
ROUTE: POST /smart-timetable/substitution/absence
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input: teacher_id (exists in sch_teachers), date (date), reason (max 500),
    absence_type (LEAVE|SICK|TRAINING|OFFICIAL_DUTY|OTHER|FULL_DAY)

PROCESSING:
  Step 1: Validate input
  Step 2: SubstitutionService::reportAbsence()
    - Create TeacherAbsences record
    - Find affected timetable cells for this teacher on this date
    - Mark cells as needing substitution
  Step 3: Return affected_cells count

OUTPUT TARGET:
  - Table: tt_teacher_absences → 1 INSERT
  - Table: tt_timetable_cells → N UPDATEs (mark affected cells)

RESPONSE: JSON or redirect with affected_cells count
```

### 8.11 Find Substitute Candidates

```
OPERATION: Find Substitute Teacher Candidates
TRIGGER: GET AJAX → SubstitutionController::candidates()
ROUTE: GET /smart-timetable/substitution/candidates/{cellId}/{date}
AUTHORIZATION: smart-timetable.timetable.view

INPUT SOURCE:
  - Route params: cellId, date

PROCESSING:
  Step 1: SubstitutionService::findSubstitutes(cellId, date)
    - Load cell with activity, subject, teachers
    - Query available teachers for this period/day
    - Score each candidate:
      • Subject match (same subject competency)
      • Availability (not already assigned)
      • Workload (current daily/weekly load)
      • Past patterns (historical success from tt_substitution_patterns)
    - Rank by composite score
  Step 2: Return ranked candidates

OUTPUT TARGET: None (read-only)

RESPONSE: JSON array of { score, teacher_name, reason, monthly_subs, teacher_id }
```

### 8.12 Assign Substitute Teacher

```
OPERATION: Assign Substitute Teacher
TRIGGER: POST AJAX → SubstitutionController::assign()
ROUTE: POST /smart-timetable/substitution/assign
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input: cell_id (exists in tt_timetable_cells), substitute_teacher_id (exists in sch_teachers),
    date (date), absence_id (nullable int)

PROCESSING:
  Step 1: SubstitutionService::assignSubstitute()
    - Create SubstitutionLog record
    - Update cell teacher assignment
    - Update substitution patterns for learning

OUTPUT TARGET:
  - Table: tt_substitution_logs → 1 INSERT
  - Table: tt_timetable_cell_teachers → UPDATE (add substitute)
  - Table: tt_substitution_patterns → UPDATE (pattern learning)

RESPONSE: JSON { success: true, message: ... }
```

### 8.13 Auto-Assign Substitutes

```
OPERATION: Auto-Assign All Substitutes for Teacher/Date
TRIGGER: POST → SubstitutionController::autoAssign()
ROUTE: POST /smart-timetable/substitution/auto-assign
AUTHORIZATION: smart-timetable.timetable.update

INPUT SOURCE:
  - User Input: teacher_id (exists in sch_teachers), date (date)

PROCESSING:
  Step 1: SubstitutionService::autoAssign(teacher_id, date)
    - Find all unassigned cells for this teacher on date
    - For each cell: find best candidate and assign
    - Track assigned and failed counts

OUTPUT TARGET:
  - Table: tt_substitution_logs → N INSERTs
  - Table: tt_timetable_cell_teachers → N UPDATEs

RESPONSE: JSON { assigned: N, failed: N }
```

### 8.14 Create Constraint

```
OPERATION: Create Constraint Instance
TRIGGER: POST form submit → ConstraintController::store()
ROUTE: POST /smart-timetable/constraint
AUTHORIZATION: smart-timetable.constraint.create

INPUT SOURCE:
  - User Input: constraint_type_id, name, description, academic_session_id, target_type
    (TEACHER|CLASS|ROOM|GLOBAL|ACTIVITY|INTER_ACTIVITY), target_id, is_hard, weight (0-100),
    params_json (JSON string), effective_from, effective_to, status, is_active,
    category_code, scope (INDIVIDUAL|GLOBAL|PAIR|GROUP)

PROCESSING:
  Step 1: Validate via StoreConstraintRequest
    - GLOBAL: target_id must be NULL
    - Non-GLOBAL: target_id required
    - Hard constraints: weight forced to 100
    - params_json: validated as valid JSON
    - INTER_ACTIVITY: target_activity_id merged into params
  Step 2: Generate UUID
  Step 3: Resolve target_type to ConstraintCategoryScope ID
  Step 4: INSERT into tt_constraints
  Step 5: Log activity

OUTPUT TARGET:
  - Table: tt_constraints → 1 INSERT (uuid, all fields, params_json)

RESPONSE: Redirect with success or back with validation errors
```

### 8.15 Create Parallel Group

```
OPERATION: Create Parallel Activity Group
TRIGGER: POST form submit → ParallelGroupController::store()
ROUTE: POST /smart-timetable/parallel-group
AUTHORIZATION: smart-timetable.parallel-group.create

INPUT SOURCE:
  - User Input: code (unique, max 60), name, description, academic_term_id, group_type
    (PARALLEL_SECTION|OPTIONAL|SKILL|HOBBY|CUSTOM), coordination_type
    (SAME_TIME|SAME_DAY|SAME_PERIOD_RANGE), requires_same_teacher (bool),
    requires_same_room_type (bool), scheduling_priority (1-100), is_hard_constraint (bool),
    weight (1-100), is_active (bool)

PROCESSING:
  Step 1: Validate via StoreParallelGroupRequest
  Step 2: INSERT into tt_parallel_group with created_by = auth()->id()

OUTPUT TARGET:
  - Table: tt_parallel_group → 1 INSERT

RESPONSE: Redirect to show route with success message
```

### 8.16 Auto-Detect Parallel Groups

```
OPERATION: Auto-Detect Parallel Group Candidates
TRIGGER: POST AJAX → ParallelGroupController::autoDetect()
ROUTE: POST /smart-timetable/parallel-group/auto-detect
AUTHORIZATION: smart-timetable.parallel-group.create

INPUT SOURCE:
  - User Input: academic_term_id (required, exists in tt_academic_terms)
  - Table: tt_activities → Active activities for term with class, section, subject, study_format

PROCESSING:
  Step 1: Load all active activities for the term with relations
  Step 2: Group activities by (class_id + study_format_id)
  Step 3: Filter: keep only groups spanning 2+ sections
  Step 4: Build proposals with suggested names/codes for each group

OUTPUT TARGET: None (read-only)

RESPONSE: JSON { proposals: [...], total_proposals: N }
```

### 8.17 Set Anchor Activity in Parallel Group

```
OPERATION: Set Anchor Activity
TRIGGER: POST AJAX → ParallelGroupController::setAnchor()
ROUTE: POST /smart-timetable/parallel-group/{id}/set-anchor/{activityId}
AUTHORIZATION: smart-timetable.parallel-group.update

PROCESSING:
  Step 1: Load group and verify activity membership
  Step 2: UPDATE all tt_parallel_group_activity → is_anchor = false (for this group)
  Step 3: UPDATE specified activity → is_anchor = true

OUTPUT TARGET:
  - Table: tt_parallel_group_activity → N UPDATEs (clear all) + 1 UPDATE (set anchor)

RESPONSE: JSON { anchor_activity_id: N }
```

### 8.18 Export Timetable PDF

```
OPERATION: Export Class Timetable as PDF
TRIGGER: GET request → TimetableExportController::exportPdf()
ROUTE: GET /smart-timetable/export/pdf/{timetableId}
AUTHORIZATION: smart-timetable.timetable.view

INPUT SOURCE:
  - Route param: timetableId
  - Table: tt_timetables → with academicSession, term, type, periodSet+periods
  - Table: tt_timetable_cells → Active cells with 7 relations

PROCESSING:
  Step 1: Load timetable with 4 relations
  Step 2: Load all active cells with activity, teachers, room, day, period
  Step 3: Build class-section grid: [className][dayId][periodOrd] = {subject, teacher, room}
  Step 4: Extract unique days and periods
  Step 5: Generate PDF via DomPDF (landscape A4)

OUTPUT TARGET: None (read-only)

RESPONSE: PDF file download — filename: timetable_{name}_{date}.pdf
```

### 8.19 Analytics — Workload Report

```
OPERATION: Teacher Workload Report
TRIGGER: GET request → AnalyticsController::workload()
ROUTE: GET /smart-timetable/analytics/workload
AUTHORIZATION: smart-timetable.report.viewAny

INPUT SOURCE:
  - Query param: timetable_id (required)
  - Via AnalyticsService::getWorkloadReport(timetableId):
    - Table: tt_timetable_cells → cells for this timetable
    - Table: tt_timetable_cell_teachers → teacher assignments
    - Table: tt_activities → activity details (subject, class)

PROCESSING:
  Step 1: Query all cells for timetable with teacher and activity relations
  Step 2: Group by teacher
  Step 3: For each teacher: count total periods, group by subject with counts
  Step 4: Return structured report

OUTPUT TARGET: None (read-only)

RESPONSE: View smarttimetable::analytics.workload with report data
  Report structure: { teachers: [{ teacher_name, total_periods, subjects: { 'Math': 5, ... } }] }
```

### 8.20 Analytics — Export CSV

```
OPERATION: Export Analytics Report as CSV
TRIGGER: GET request → AnalyticsController::export()
ROUTE: GET /smart-timetable/analytics/export/{type}
AUTHORIZATION: smart-timetable.report.export

INPUT SOURCE:
  - Route param: type (workload|utilization|violations)
  - Query param: timetable_id

PROCESSING:
  Step 1: Load report data via AnalyticsService (based on type)
  Step 2: Format as CSV rows
  Step 3: Stream response with appropriate headers

OUTPUT TARGET: None (read-only)

RESPONSE: CSV file download with Content-Type: text/csv
```

### 8.21 API — Generate Timetable (Async)

```
OPERATION: API Generate Timetable (Queued)
TRIGGER: POST → TimetableApiController::generate()
ROUTE: POST /api/v1/timetable/generate
AUTHORIZATION: auth:sanctum middleware

INPUT SOURCE:
  - JSON body: academic_term_id, timetable_type_id, use_existing_activities, max_generation_time

PROCESSING:
  Step 1: Validate input
  Step 2: INSERT into tt_generation_runs (status='PENDING')
  Step 3: Dispatch GenerateTimetableJob to queue (async)
  Step 4: Return job reference immediately

OUTPUT TARGET:
  - Table: tt_generation_runs → 1 INSERT (status='PENDING')
  - Queue: GenerateTimetableJob dispatched

RESPONSE: JSON (HTTP 202 Accepted)
  { job_id, uuid, status: 'PENDING', poll_url: '/api/v1/timetable/generate/{runId}/status' }
```

### 8.22 API — Poll Generation Status

```
OPERATION: Poll Generation Job Status
TRIGGER: GET → TimetableApiController::status()
ROUTE: GET /api/v1/timetable/generate/{runId}/status
AUTHORIZATION: auth:sanctum middleware

INPUT SOURCE:
  - Route param: runId
  - Table: tt_generation_runs → current run status

PROCESSING:
  Step 1: Load GenerationRun record
  Step 2: Build status response with:
    - status (PENDING|RUNNING|COMPLETED|FAILED)
    - progress_pct (0-100)
    - current_stage label
    - ETA calculation (if running and progress > 0)
    - Result data (if COMPLETED: activities_placed, violations, timetable_id)
    - Error data (if FAILED: error_message)

OUTPUT TARGET: None (read-only)

RESPONSE: JSON { status, progress_pct, stage, started_at, elapsed_seconds, eta_seconds,
  result: { timetable_id, activities_placed, activities_failed, violations, quality_score } }
```

### 8.23 Constraint CRUD — Standard Pattern

All constraint-related entities (Category, Scope, Type, Constraint, RoomUnavailable, TeacherUnavailable) follow the same CRUD pattern:

```
PATTERN: Standard CRUD with Soft Delete Management

CREATE:
  - Load lookup data (related entities)
  - Validate via FormRequest or inline validation
  - INSERT record with activity log
  - Redirect to index/show

READ:
  - Load record with eager-loaded relations
  - Pass to view

UPDATE:
  - Load record and lookup data
  - Validate (with unique ignore for current record)
  - UPDATE record with activity log
  - Redirect with success

DELETE (Soft):
  - Set is_active = false
  - Call softDelete() → sets deleted_at
  - Activity log
  - Redirect with success

TRASH VIEW:
  - Query onlyTrashed() records
  - Paginate (10 per page)
  - Show with restore/force-delete options

RESTORE:
  - Call restore() → clears deleted_at
  - Set is_active = true
  - Activity log

FORCE DELETE:
  - Call forceDelete() → permanent removal
  - Activity log
  - Redirect to trash view

TOGGLE STATUS (AJAX):
  - Validate is_active (required boolean)
  - UPDATE is_active
  - Activity log
  - Return JSON { success, message, new_status }
```

**Resources using this pattern:**
- ConstraintCategoryController → `tt_constraint_category_scope` (type=CATEGORY)
- ConstraintScopeController → `tt_constraint_category_scope` (type=SCOPE)
- ConstraintTypeController → `tt_constraint_types` (with system type protection)
- RoomUnavailableController → `tt_room_unavailable` (with overlap detection)
- TeacherUnavailableController → `tt_teacher_unavailable` (with overlap detection)
- TtGenerationStrategyController → `tt_generation_strategies` (with default strategy logic)

### 8.24 Form Request Validation Summary

| Form Request | Target | Key Rules |
|-------------|--------|-----------|
| StoreConstraintRequest | tt_constraints | constraint_type_id (exists), target_type (IN enum), weight (0-100), params_json (valid JSON), effective_to (after effective_from) |
| UpdateConstraintRequest | tt_constraints | Same as Store |
| StoreParallelGroupRequest | tt_parallel_group | code (unique, max 60), group_type (IN enum), coordination_type (IN enum), scheduling_priority (1-100), weight (1-100) |
| UpdateParallelGroupRequest | tt_parallel_group | Same as Store with unique ignore |
| AddActivitiesToParallelGroupRequest | tt_parallel_group_activity | activity_ids (required array, each exists in tt_activities) |
| TimetableGenerationStrategyRequest | tt_generation_strategies | code (unique, max 20), algorithm_type (IN enum), conditional params by algorithm type, timeout_seconds (30-3600) |
| DayRequest | tt_days | label (unique, max 30), ordinal (unique, int) |

**Note:** All 7 form requests return `true` from `authorize()` — no policy checks at the request level.

---

*End of Section 8 — Run 3 Complete*

---

## 9. Timetable Generation Algorithm

This is the most critical section. The SmartTimetable module implements a **Constraint-based Backtracking Solver** inspired by FET (Free Educational Timetabler), with greedy fallback, rescue pass, and forced placement.

**Key Files:**
- `Services/Generator/FETSolver.php` (~2,830 lines) — Core algorithm
- `Services/TimetableGenerationService.php` — Orchestrator
- `Services/Solver/TimetableSolution.php` — Solution container
- `Services/Solver/Slot.php` — Slot value object
- `Services/GenerationResult.php` — Result DTO
- `Services/RoomAllocationPass.php` — Post-generation room assignment
- `Jobs/GenerateTimetableJob.php` — Queue wrapper

### 9.1 Algorithm Architecture & FET Influence

The algorithm is inspired by the open-source **FET (Free Educational Timetabler)** software but is a custom PHP implementation. Key FET concepts borrowed:

1. **Most-difficult-first ordering** — Activities sorted by difficulty score (most constrained first)
2. **Recursive swapping / backtracking** — When no slot is available, try evicting conflicting activities
3. **Tabu avoidance** — Track failed states to prevent infinite loops (via iteration/backtrack limits)

**Custom additions beyond FET:**
- Parallel group anchor/sibling synchronization
- Period pinning (same period across week)
- Relaxed pinning zone (last 2 periods after lunch)
- Daily activity cap with overflow logic
- Class teacher first-lecture enforcement
- Alternative teacher selection on conflict
- Multi-pass architecture (backtrack → greedy → rescue → forced)
- Room allocation as separate post-pass

### 9.2 Pre-Generation Setup

#### 9.2.1 Data Loading (`TimetableGenerationService::generate()`)

```
Step 1: Load ClassSections (with class teacher, assistance teacher)
Step 2: Load current AcademicSession
Step 3: Load Activities filtered by academic_term_id + timetable_type_id
         → Eager load: teachers, class, section, subject, studyFormat
Step 4: Load SchoolDays (all school days)
Step 5: Load PeriodSetPeriods for the period_set_id
         → Mark breaks: code IN ['SBREAK', 'LUNCH'] → is_break = true
Step 6: Load Constraints via DatabaseConstraintService
         → Active, within effective date range
         → Sorted: hard first, then by weight DESC
Step 7: Create ConstraintManager with generation context
Step 8: Initialize FETSolver with days, periods, constraintManager, options
```

**Validation:** If `activities.isEmpty()` → throw RuntimeException

#### 9.2.2 FETSolver Initialization

```
Constructor(days, periods, constraintManager, options):
  1. Store days, periods, constraintManager
  2. Extract options:
     - class_teacher_first_lecture (bool)
     - single_activity_once_per_day_until_overflow (bool)
     - pin_activities_by_period (bool)
     - parallel_groups (Collection)

  3. calculateTeachingPeriods():
     - teachingIndices = periods NOT in ['SBREAK', 'BREAK', 'LUNCH']
     - lunchPeriodIndex = index of first LUNCH/SBREAK period
     - relaxedPinningZoneIndices = last 2 teaching periods after lunch

  4. initializeParallelGroups():
     - parallelGroups: groupId → ParallelGroup
     - parallelGroupActivityIds: groupId → [activityId, ...]
     - parallelGroupAnchors: groupId → anchorActivityId
     - activityParallelMap: activityId → [groupId, ...]

  5. Initialize constraint context:
     context = {
       periods, occupied: {}, teacherOccupied: {},
       entries: [], activitiesById: {}, days,
       teachingIndices
     }

  6. If class_teacher_first_lecture:
     - Load class teachers from sch_class_section_jnt
     - Build classTeacherByClassKey mapping
     - Evaluate eligibility (teacher needs ≥6 periods, ≥ weekdays)
```

#### 9.2.3 Activity Expansion

Each activity's `required_weekly_periods` is expanded into separate instances:

```
expandActivitiesByWeeklyPeriods(activities):
  FOR EACH activity:
    FOR i = 1 TO activity.required_weekly_periods:
      instance = clone activity
      instance.instance_id = "{activity.id}-{i}"
      instance.instance_number = i
      instance.original_activity_id = activity.id

      // Select ONE teacher for ALL instances (prefer less-busy)
      IF NOT activityTeacherAssignments[activity.id]:
        activityTeacherAssignments[activity.id] = pickRandomTeacherAssignment(activity)
      instance.selected_teacher_id = activityTeacherAssignments[activity.id]['teacher_id']

  shuffle(expanded)  // Randomize to avoid ordering bias
  return expanded
```

### 9.3 Core Algorithm Step-by-Step

#### 9.3.1 Activity Ordering (Difficulty Scoring)

Activities are sorted **most difficult first** using a composite difficulty score:

```
orderActivitiesByDifficulty(expandedActivities):
  FOR EACH instance:
    score = activity.difficulty_score ?? 0

    // Parallel groups: HIGHEST PRIORITY (+20,000)
    IF in parallel_group:
      score += 20,000
      IF is anchor: score += 5,000  // Anchors before siblings

    // High-load activities (≥6 periods/week): +10,000
    IF required_weekly_periods >= 6: score += 10,000
    score += required_weekly_periods * 500

    // Multi-period activities (labs): +3 per duration period
    score += duration_periods * 3

    // Multi-teacher activities: +2 per teacher
    score += teachers.count() * 2

    // Compulsory subjects: +20
    IF is_compulsory: score += 20

    // Class teacher activities: +1,000 (if enforcement enabled)
    IF class_teacher_first_lecture && isClassTeacherActivity:
      score += 1,000 + priority * 20
    ELSE: score -= 150

  SORT BY score DESC
```

#### 9.3.2 Main Solving Pipeline

```
generateInitialSolution(expandedActivities, context):
  orderedActivities = orderActivitiesByDifficulty(expandedActivities)
  solution = new TimetableSolution()

  // ATTEMPT 1: BACKTRACKING (25-second timeout)
  IF backtrack(orderedActivities, 0, solution, context):
    return solution  // Perfect placement!

  // ATTEMPT 2: GREEDY FALLBACK
  return generateGreedySolution(orderedActivities, context)
```

#### 9.3.3 Backtracking Algorithm (Pseudocode)

```
backtrack(activities, index, solution, context) → bool:
  iterations++

  // TERMINATION CONDITIONS
  IF (now - startTime) > 25 seconds: return FALSE   // Timeout
  IF iterations > 50,000: return FALSE               // Iteration limit
  IF backtracks > 50,000: return FALSE               // Backtrack limit

  // BASE CASE: All placed
  IF index >= activities.length: return TRUE

  activity = activities[index]
  originalId = activity.original_activity_id

  // ─── PARALLEL GROUP: Non-Anchor Sibling ───
  nonAnchorGroupId = isNonAnchorParallelMember(originalId)
  IF nonAnchorGroupId != NULL:
    anchorSlot = findActivitySlotInContext(parallelGroupAnchors[nonAnchorGroupId])
    IF anchorSlot != NULL:
      // Force to anchor's slot (same day + period, different classKey)
      forcedSlot = Slot(getClassKey(activity), anchorSlot.dayId, anchorSlot.startIndex)
      IF isBasicSlotAvailable(activity, forcedSlot, context):
        IF solution.place(activity, forcedSlot):
          tempContext = simulatePlacement(activity, forcedSlot, context)
          IF backtrack(activities, index+1, solution, tempContext):
            return TRUE
          solution.remove(activity, forcedSlot)
          backtracks++
      return FALSE  // Cannot place sibling
    ELSE:
      return backtrack(activities, index+1, solution, context)  // Skip, anchor not ready

  // ─── NORMAL ACTIVITY ───
  possibleSlots = getPossibleSlots(activity, solution, context)
  IF possibleSlots.isEmpty(): return FALSE

  FOR EACH slot IN possibleSlots:
    IF canPlaceWithConstraints(activity, slot, context):
      tempContext = simulatePlacement(activity, slot, context)

      IF solution.place(activity, slot):
        // Record period affinity for pinning
        IF pinActivitiesByPeriod:
          activityPeriodAffinities[activity.id] ??= slot.startIndex

        // ─── PARALLEL: Place siblings immediately ───
        siblingSuccess = TRUE
        siblingSlots = []

        FOR EACH pgId IN activityParallelMap[originalId]:
          IF parallelGroupAnchors[pgId] == originalId:  // I'm the anchor
            FOR EACH siblingId IN parallelGroupActivityIds[pgId]:
              IF siblingId == originalId: CONTINUE
              siblingInstance = findUnplacedInstance(siblingId, activities, index+1)
              IF siblingInstance == NULL: CONTINUE

              sibSlot = Slot(getClassKey(siblingInstance), slot.dayId, slot.startIndex)
              IF isBasicSlotAvailable(siblingInstance, sibSlot, tempContext):
                IF solution.place(siblingInstance, sibSlot):
                  siblingSlots.push({siblingInstance, sibSlot})
                  tempContext = simulatePlacement(siblingInstance, sibSlot, tempContext)
                ELSE: siblingSuccess = FALSE; BREAK
              ELSE: siblingSuccess = FALSE; BREAK

        IF NOT siblingSuccess:
          // Undo all sibling placements
          FOR EACH {inst, sl} IN siblingSlots: solution.remove(inst, sl)
          solution.remove(activity, slot)
          backtracks++; CONTINUE

        // Recurse to next activity
        IF backtrack(activities, index+1, solution, tempContext):
          return TRUE

        // BACKTRACK: Undo everything
        FOR EACH {inst, sl} IN siblingSlots: solution.remove(inst, sl)
        solution.remove(activity, slot)
        constraintManager.clearCache()
        backtracks++

  return FALSE  // All slots exhausted
```

#### 9.3.4 Slot Generation & Selection

```
getPossibleSlots(activity, solution, context) → array<Slot>:
  slots = []
  classKey = getClassKey(activity)
  duration = activity.duration_periods

  FOR EACH day IN days:
    maxStart = count(teachingIndices) - duration
    FOR teachingStart = 0 TO maxStart:
      actualStart = teachingToActualIndex(teachingStart)
      IF NOT isTeachingSlot(actualStart, duration): CONTINUE

      slot = Slot(classKey, day.id, actualStart)
      IF isBasicSlotAvailable(activity, slot, context):
        IF solution.canPlace(activity, slot):
          slots.push(slot)

  // SORT by preference:
  //   1. Pinning affinity (if set)
  //   2. Class teacher first lecture (period 0)
  //   3. Soft constraint score
  //   4. Day order → period order
  sort(slots, by composite comparator)

  return slots
```

#### 9.3.5 Basic Slot Availability Check

```
isBasicSlotAvailable(activity, slot, context) → bool:
  // 1. Pinned period rule (keep same period across week)
  IF pinActivitiesByPeriod AND violatesPinnedPeriodRule(activity, slot): return FALSE

  // 2. Daily activity cap (1/day until overflow)
  IF singleActivityOncePerDayUntilOverflow AND violatesDailyActivityCap(activity, slot): return FALSE

  // 3. No consecutive rule (unless allow_consecutive=true)
  IF NOT activity.allow_consecutive AND hasAdjacentSameActivity(activity, slot): return FALSE

  // 4. Min gap between instances
  IF activity.min_gap_periods > 0 AND tooCloseToAnotherInstance(activity, slot): return FALSE

  // 5. Class teacher first lecture enforcement
  IF enforceClassTeacherFirstLecture AND isFirstPeriod(slot):
    IF NOT isClassTeacherActivity(activity): return FALSE

  // 6. Period bounds + occupancy check
  FOR i = 0 TO duration-1:
    periodIndex = slot.startIndex + i
    IF periodIndex >= periods.count(): return FALSE
    periodId = periods[periodIndex].id

    IF context.occupied[classKey][slot.dayId][periodId] EXISTS: return FALSE  // Class busy
    FOR EACH teacherId IN getSchedulingTeacherIds(activity):
      IF context.teacherOccupied[teacherId][slot.dayId][periodId] EXISTS: return FALSE  // Teacher busy

  return TRUE
```

#### 9.3.6 Full Constraint Check

```
canPlaceWithConstraints(activity, slot, context) → bool:
  // 1. Basic availability (fast)
  IF NOT isBasicSlotAvailable(activity, slot, context): return FALSE

  // 2. Inter-activity constraints (SAME_TIME, SAME_DAY, etc.)
  IF activity.id IN activityGroupMap:
    IF NOT checkInterActivityConstraints(activity, slot, context): return FALSE

  // 3. Hard constraints from ConstraintManager/DB
  return constraintManager.checkHardConstraints(slot, activity, context)
```

#### 9.3.7 Slot Scoring for Soft Preferences

```
scoreSlotForActivity(activity, slot, context) → int:
  score = 0

  // Preferred time slots (day+period match):    +40
  // Avoid time slots (day+period match):        -50
  // Preferred periods (period ordinal):          +20
  // Avoid periods (period ordinal):              -30
  // Spread evenly (unused day):                  +10
  // Spread evenly (already used day):            -15
  // Min per day encouragement:                   +15
  // Split not allowed (different day):           -100
  // Soft constraints from ConstraintManager:     +score * 0.5

  return score
```

### 9.4 Greedy Fallback

When backtracking fails (timeout/iteration limit), falls back to greedy:

```
generateGreedySolution(activities, context):
  solution = new TimetableSolution()

  FOR EACH activity IN activities (by difficulty):
    slots = getPossibleSlots(activity, solution, context)
    FOR EACH slot IN slots:
      IF canPlaceWithConstraints(activity, slot, context):
        solution.place(activity, slot)
        context = simulatePlacement(activity, slot, context)

        // Place parallel siblings immediately
        IF isAnchor(activity):
          FOR EACH sibling: force to same slot
        BREAK
      ELSE:
        // Try alternative teacher if conflict is teacher-based
        altTeacher = tryAlternativeTeacher(activity, slot, context)
        IF altTeacher: retry with new teacher

  // ─── RESCUE PASS (relaxed constraints) ───
  FOR EACH unplaced IN remaining:
    FOR EACH slot (all possible):
      IF canPlaceWithConstraints(activity, slot, context,
           ignorePinning=TRUE, ignoreDailyCap=TRUE,
           ignoreConsecutive=TRUE, ignoreClassTeacherFirst=TRUE):
        solution.place(activity, slot)
        BREAK

  // ─── FORCED PLACEMENT (last resort, 1-period activities only) ───
  FOR EACH unplaced IN remaining (where required_weekly_periods==1):
    FOR EACH slot:
      classFree = isClassSlotFree(slot)
      teacherFree = isTeacherSlotFree(slot)

      IF classFree AND teacherFree:
        solution.place(activity, slot); BREAK

      IF classFree AND NOT teacherFree:
        solution.forcePlace(activity, slot)  // Accept teacher conflict
        Record in forcedPlacementsWithConflicts
        BREAK

      // ABSOLUTE LAST RESORT: Class double-booking
      solution.forcePlace(activity, slot)
      Record conflict; BREAK

  return solution
```

### 9.5 Post-Generation Processing

#### 9.5.1 Solution to Entries Conversion

```
convertSolutionToEntries(solution, originalActivities):
  FOR EACH (instanceId, slots) IN solution.getPlacements():
    originalActivityId = extractOriginalId(instanceId)
    activity = activitiesById[originalActivityId]

    FOR EACH slot IN slots:
      FOR i = 0 TO activity.duration_periods - 1:
        entries.push({
          day_id, period_id, activity_id,
          class_id, section_id,
          teacher_id, assignment_role_id,
          has_conflict, conflict_type, conflict_details
        })
  return entries
```

#### 9.5.2 Room Allocation Pass

Room allocation runs as a **separate post-pass** after activity placement:

```
RoomAllocationPass::allocate(entries, activities, rooms):
  // Sort: hardest room requirements first
  sort(entries, by roomPriorityScore DESC):
    required_room_id: +100
    compulsory_specific_room_type: +80
    required_room_type_id: +60
    preferred_room_ids: +30
    preferred_room_type_id: +20

  FOR EACH entry:
    room = findBestRoom(activity, entry):
      1. HARD: specific required_room_id → exact match
      2. HARD: compulsory room type → first available of type
      3. SOFT: preferred_room_ids → first available
      4. SOFT: required_room_type_id → first available of type
      5. SOFT: preferred_room_type_id → first available of type
      6. FALLBACK: any available room

    IF room: roomOccupied[room.id][dayId][periodId] = entry
    ELSE: log room conflict
```

#### 9.5.3 School Grid Construction

```
buildSchoolGrid(entries):
  FOR EACH entry:
    classKey = className + '-' + sectionCode
    dayKey = dayOfWeek

    IF schoolGrid[classKey][dayKey][periodId] EXISTS:
      log double-booking conflict
    ELSE:
      schoolGrid[classKey][dayKey][periodId] = activityId
      selectedTeacherBySlot[classKey][dayKey][periodId] = {teacher_id, role_id}
      roomBySlot[classKey][dayKey][periodId] = roomId
```

### 9.6 Generation Statistics

```
Stats tracked during generation:
  - activities: total count
  - total_periods_needed: SUM(required_weekly_periods × duration_periods)
  - periods_placed: count of successfully placed periods
  - slot_evaluations: number of slot attempts
  - constraint_checks: number of constraint evaluations
  - constraint_violations: number of hard constraint failures
  - generation_time: elapsed seconds
  - coverage_percentage: (periods_placed / total_periods_needed) × 100
  - activities_fully_placed: count
  - activities_partially_placed: count
  - activities_with_no_slots: count
  - iterations: backtrack call count
  - backtracks: backtrack undo count
```

### 9.7 Parallel Group Handling (Critical)

```
ANCHOR PLACEMENT:
  1. Anchor activity is sorted with +25,000 difficulty score (placed first)
  2. When anchor is placed at a slot:
     - Immediately attempt to place ALL non-anchor siblings
     - Each sibling forced to SAME day + period (different classKey)
     - If ANY sibling fails → undo anchor + all siblings (backtrack)

SIBLING PLACEMENT:
  1. When backtrack encounters a non-anchor sibling:
     - Look up anchor's placed slot
     - If anchor placed: force sibling to identical slot
     - If anchor NOT placed: SKIP (not block) — allow other activities first

RESCUE PASS:
  - Non-anchor siblings with unplaced anchors: attempt with relaxed constraints
  - Force to anchor's slot ignoring soft constraints

KEY DESIGN DECISIONS:
  - Siblings SKIP (not block) when anchor isn't ready
  - Sibling classKey comes from SIBLING activity, not anchor
  - All parallel activities share same time slot but different class-sections
```

### 9.8 Configuration Options

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| `class_teacher_first_lecture` | bool | false | Reserve period 0 for class teacher's activity |
| `single_activity_once_per_day_until_overflow` | bool | false | Max 1 instance/day until > available days |
| `pin_activities_by_period` | bool | false | Keep same period across week (e.g., Math always period 3) |
| `parallel_groups` | Collection | empty | ParallelGroup instances to synchronize |
| `max_iterations` | int | 50,000 | Backtrack iteration limit |
| `max_backtracks` | int | 50,000 | Backtrack undo limit |
| `backtrack_timeout` | int | 25s | Per-attempt timeout |

---

## 10. Constraint Engine

### 10.1 Constraint Architecture

```
                    ┌─────────────────────────┐
                    │  ConstraintRegistry      │ — Maps type codes to PHP classes
                    └──────────┬──────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │  ConstraintFactory       │ — Creates constraint objects from DB
                    └──────────┬──────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │  DatabaseConstraintService│ — Loads constraints from tt_constraints
                    └──────────┬──────────────┘
                               │
              ┌────────────────▼────────────────┐
              │       ConstraintManager          │
              │  ┌───────────┐ ┌──────────────┐  │
              │  │   Hard    │ │    Soft      │  │
              │  │Constraints│ │ Constraints  │  │
              │  └───────────┘ └──────────────┘  │
              └────────────────┬────────────────┘
                               │
              ┌────────────────▼────────────────┐
              │      ConstraintEvaluator         │
              │  checkHard() → bool              │
              │  scoreSoft() → float             │
              │  getViolations() → array         │
              └──────────────────────────────────┘
```

**Dual Constraint System:**
1. **Hardcoded in FETSolver**: Fast, performance-critical checks (occupancy, period bounds, pinning, daily cap)
2. **DB-Driven via ConstraintManager**: Flexible, configurable constraints loaded from `tt_constraints`

### 10.2 Hard Constraints (Full List)

| # | Code | PHP Class | Enforcement | Description |
|---|------|-----------|-------------|-------------|
| 1 | — | (FETSolver native) | isBasicSlotAvailable | No class double-booking (same class, same slot) |
| 2 | — | (FETSolver native) | isBasicSlotAvailable | No teacher double-booking (same teacher, same slot) |
| 3 | PARALLEL_PERIODS | ParallelPeriodConstraint | FETSolver native | Parallel group activities at same time slot |
| 4 | TEACHER_CONFLICT | TeacherConflictConstraint | ConstraintManager | Teacher occupancy conflict detection |
| 5 | TEACHER_MAX_DAILY | TeacherMaxDailyConstraint | ConstraintManager | Teacher max periods per day (default 8) |
| 6 | TEACHER_MAX_WEEKLY | TeacherMaxWeeklyConstraint | ConstraintManager | Teacher max periods per week |
| 7 | TEACHER_UNAVAILABLE_PERIODS | TeacherUnavailablePeriodsConstraint | ConstraintManager | Teacher blackout periods |
| 8 | TEACHER_ROOM_UNAVAILABLE | TeacherRoomUnavailableConstraint | ConstraintManager | Room unavailable for teacher |
| 9 | CLASS_MAX_PER_DAY | ClassMaxPerDayConstraint | ConstraintManager | Class max periods per day (default 8) |
| 10 | CLASS_WEEKLY_PERIODS | ClassWeeklyPeriodsConstraint | ConstraintManager | Class exact weekly period count |
| 11 | CLASS_CONSECUTIVE_REQUIRED | ClassConsecutiveRequiredConstraint | ConstraintManager | Require consecutive periods (labs) |
| 12 | CONSECUTIVE_ACTIVITIES | ConsecutiveActivitiesConstraint | FETSolver (inter-activity) | Activities must be consecutive |
| 13 | NOT_OVERLAPPING | NotOverlappingConstraint | ConstraintManager | Activities must not overlap for same class |
| 14 | SAME_STARTING_TIME | SameStartingTimeConstraint | FETSolver (inter-activity) | Activities start at same time |
| 15 | ROOM_EXCLUSIVE_USE | RoomExclusiveUseConstraint | ConstraintManager | Room used by one activity at a time |
| 16 | ROOM_MAX_USAGE_PER_DAY | RoomMaxUsagePerDayConstraint | ConstraintManager | Room daily usage cap |
| 17 | GLOBAL_FIXED_PERIOD | GlobalFixedPeriodConstraint | ConstraintManager | Global period locks (assembly) |
| 18 | GLOBAL_HOLIDAY | GlobalHolidayConstraint | ConstraintManager | Holiday blocking |
| 19 | EXAM_ONLY_PERIODS | ExamOnlyPeriodsConstraint | ConstraintManager | Periods reserved for exams |
| 20 | NO_TEACHING_AFTER_EXAM | NoTeachingAfterExamConstraint | ConstraintManager | No teaching after exam periods |
| 21 | ACTIVITY_EXCLUDED_DAY | ActivityExcludedFromDayConstraint | ConstraintManager | Prevent activity on specific days |
| 22 | ACTIVITY_FIXED_DAY | ActivityFixedToDayConstraint | ConstraintManager | Force activity to specific days |
| 23 | ACTIVITY_FIXED_PERIOD_RANGE | ActivityFixedToPeriodRangeConstraint | ConstraintManager | Force activity to period range |
| 24 | OCCUPY_EXACT_SLOTS | OccupyExactSlotsConstraint | ConstraintManager | Activity fills exact slot count |

### 10.3 Soft Constraints (Full List)

#### Class-Level Soft Constraints (17)

| # | Code | PHP Class | Description |
|---|------|-----------|-------------|
| 1 | CLASS_TEACHER_FIRST_PERIOD | ClassTeacherFirstPeriodConstraint | Class teacher gets first period |
| 2 | CLASS_MAX_MINOR_SUBJECTS | ClassMaxMinorSubjectsConstraint | Max minor subjects/day (default 2) |
| 3 | CLASS_MAJOR_SUBJECTS_DAILY | ClassMajorSubjectsDailyConstraint | Major subjects appear every day |
| 4 | CLASS_MAX_CONSECUTIVE_STUDY_FORMAT | ClassMaxConsecutiveStudyFormatConstraint | Max consecutive same study format |
| 5 | CLASS_MAX_CONTINUOUS | ClassMaxContinuousConstraint | Max continuous teaching periods |
| 6 | CLASS_MAX_DAYS_IN_INTERVAL | ClassMaxDaysInIntervalConstraint | Max days in interval for subject |
| 7 | CLASS_MAX_GAPS_PER_WEEK | ClassMaxGapsPerWeekConstraint | Max free gaps per week |
| 8 | CLASS_MAX_ROOM_CHANGES_PER_DAY | ClassMaxRoomChangesPerDayConstraint | Max room changes per day |
| 9 | CLASS_MAX_SPAN | ClassMaxSpanConstraint | Max span of teaching time |
| 10 | CLASS_MAX_STUDY_FORMAT_HOURS | ClassMaxStudyFormatHoursConstraint | Max hours with study format |
| 11 | CLASS_MIN_DAILY_HOURS | ClassMinDailyHoursConstraint | Min teaching hours per day |
| 12 | CLASS_MIN_GAP | ClassMinGapConstraint | Min gap between same-subject |
| 13 | CLASS_MIN_RESTING_HOURS | ClassMinRestingHoursConstraint | Min rest between days |
| 14 | CLASS_MIN_STUDY_FORMAT_HOURS | ClassMinStudyFormatHoursConstraint | Min hours with study format |
| 15 | CLASS_NOT_FIRST_PERIOD | ClassNotFirstPeriodConstraint | Subject not in first period |
| 16 | CLASS_NOT_LAST_PERIOD | ClassNotLastPeriodConstraint | Subject not in last period |
| 17 | CLASS_STUDY_FORMAT_GAP | ClassStudyFormatGapConstraint | Min gap between formats |

#### Teacher-Level Soft Constraints (22)

| # | Code | PHP Class | Description |
|---|------|-----------|-------------|
| 1 | TEACHER_MAX_GAPS_PER_DAY | TeacherMaxGapsPerDayConstraint | Max gaps/day (default 2) |
| 2 | TEACHER_MAX_GAPS_PER_WEEK | TeacherMaxGapsPerWeekConstraint | Max gaps/week |
| 3 | TEACHER_FREE_PERIOD_EACH_HALF | TeacherFreePeriodEachHalfConstraint | Free period in each half of day |
| 4 | TEACHER_PREFERRED_FREE_DAY | TeacherPreferredFreeDayConstraint | Preferred day off |
| 5 | TEACHER_MAX_CONSECUTIVE_DB | TeacherMaxConsecutiveDBConstraint | Max consecutive (DB-configured) |
| 6 | TEACHER_MAX_SPAN_PER_DAY | TeacherMaxSpanPerDayConstraint | Max span per day |
| 7 | TEACHER_MIN_DAILY | TeacherMinDailyConstraint | Min daily periods |
| 8 | TEACHER_MIN_RESTING_HOURS | TeacherMinRestingHoursConstraint | Min resting hours |
| 9 | TEACHER_NO_CONSECUTIVE_DAYS | TeacherNoConsecutiveDaysConstraint | No two consecutive working days |
| 10 | TEACHER_MUTUALLY_EXCLUSIVE_SLOTS | TeacherMutuallyExclusiveSlotsConstraint | Two slots can't both be used |
| 11 | TEACHER_HOME_ROOM | TeacherHomeRoomConstraint | Teacher assigned to home room |
| 12 | TEACHER_MAX_ROOM_CHANGES_PER_DAY | TeacherMaxRoomChangesPerDayConstraint | Max room changes/day |
| 13 | TEACHER_MAX_ROOM_CHANGES_PER_WEEK | TeacherMaxRoomChangesPerWeekConstraint | Max room changes/week |
| 14 | TEACHER_MIN_GAP_BETWEEN_ROOM_CHANGES | TeacherMinGapBetweenRoomChangesConstraint | Min gap between room changes |
| 15 | TEACHER_MAX_BUILDING_CHANGES_PER_DAY | TeacherMaxBuildingChangesPerDayConstraint | Max building changes/day |
| 16 | TEACHER_DAILY_STUDY_FORMAT | TeacherDailyStudyFormatConstraint | Max hours/day with format |
| 17 | TEACHER_MAX_CONSECUTIVE_STUDY_FORMAT | TeacherMaxConsecutiveStudyFormatConstraint | Max consecutive same format |
| 18 | TEACHER_MAX_STUDY_FORMATS | TeacherMaxStudyFormatsConstraint | Max different formats/day |
| 19 | TEACHER_STUDY_FORMAT_GAP | TeacherStudyFormatGapConstraint | Min gap between formats |
| 20 | TEACHER_MAX_DAYS_IN_INTERVAL | TeacherMaxDaysInIntervalConstraint | Max days in interval |
| 21 | TEACHER_MAX_HOURS_IN_INTERVAL | TeacherMaxHoursInIntervalConstraint | Max hours in interval |
| 22 | TEACHER_GAPS_IN_SLOT_RANGE | TeacherGapsInSlotRangeConstraint | Gaps in slot ranges |

#### Global Soft Constraints (4)

| # | Code | PHP Class | Description |
|---|------|-----------|-------------|
| 1 | GLOBAL_BALANCED_DISTRIBUTION | GlobalBalancedDistributionConstraint | Even load across week |
| 2 | GLOBAL_MAX_TEACHING_DAYS | GlobalMaxTeachingDaysConstraint | Global max teaching days |
| 3 | GLOBAL_PREFER_MORNING | GlobalPreferMorningConstraint | Prefer morning periods |
| 4 | END_STUDENTS_DAY | EndStudentsDayConstraint | Activity that ends student day |

#### Room/Activity Soft Constraints (17)

| # | Code | PHP Class | Description |
|---|------|-----------|-------------|
| 1 | PREFERRED_SLOT_SELECTION | PreferredSlotSelectionConstraint | Preferred time slot |
| 2 | SUBJECT_PREFERRED_ROOM | SubjectPreferredRoomConstraint | Subject prefers room |
| 3 | STUDY_FORMAT_PREFERRED_ROOM | StudyFormatPreferredRoomConstraint | Format prefers room type |
| 4 | SUBJECT_STUDY_FORMAT_PREFERRED_ROOM | SubjectStudyFormatPreferredRoomConstraint | Subject+format room |
| 5 | SAME_ROOM_IF_CONSECUTIVE | SameRoomIfConsecutiveConstraint | Same room for consecutive |
| 6 | PREFER_SAME_ROOM | PreferSameRoomConstraint | Prefer same room |
| 7 | MAX_DIFFERENT_ROOMS | MaxDifferentRoomsConstraint | Activity max N rooms |
| 8 | ROOM_MAX_STUDY_FORMATS | RoomMaxStudyFormatsConstraint | Room max formats |
| 9 | SAME_DAY | SameDayConstraint | Activities on same day |
| 10 | SAME_HOUR | SameHourConstraint | Activities at same hour |
| 11 | ORDERED_IF_SAME_DAY | OrderedIfSameDayConstraint | Ordered on same day |
| 12 | MIN_DAYS_BETWEEN | MinDaysBetweenConstraint | Min days between instances |
| 13 | MAX_DAYS_BETWEEN | MaxDaysBetweenConstraint | Max days between instances |
| 14 | MIN_GAPS_BETWEEN_SET | MinGapsBetweenSetConstraint | Min gaps between sets |
| 15 | NON_CONCURRENT_MINOR_SUBJECTS | NonConcurrentMinorSubjectsConstraint | Minor subjects not simultaneous |
| 16 | OCCUPY_MAX_SLOTS | OccupyMaxSlotsConstraint | Activity max slots |
| 17 | OCCUPY_MIN_SLOTS | OccupyMinSlotsConstraint | Activity min slots |

### 10.4 Constraint Application Matrix

| Stage | Hardcoded (FETSolver) | DB-Driven (ConstraintManager) |
|-------|----------------------|------------------------------|
| **Slot Pre-filter** | Class occupancy, Teacher occupancy, Period bounds | — |
| **Basic Availability** | Pinning rule, Daily cap, No-consecutive, Min gap, Class teacher first | — |
| **Inter-Activity** | SAME_TIME, SAME_DAY, SAME_HOUR, NOT_OVERLAPPING, ORDERED | — |
| **Hard Check** | — | All hard constraints via checkHardConstraints() |
| **Soft Scoring** | Preferred/avoid slots, Spread evenly, Split penalty | All soft constraints via evaluateSoftConstraints() |
| **Post-Generation** | — | Violation detection, Analytics |

### 10.5 Constraint Interface

All constraints implement `TimetableConstraint`:

```php
interface TimetableConstraint {
    public function passes(Slot $slot, Activity $activity, $context): bool;
    public function getDescription(): string;
    public function getWeight(): float;
    public function isRelevant(Activity $activity): bool;
}
```

**Hard constraint behavior:** `passes()` returns false → slot rejected (activity cannot go here)
**Soft constraint behavior:** `passes()` returns false → penalty applied to slot score (reduces preference)

---

## 11. Conflict Detection & Resolution

### 11.1 Conflict Detection

`ConflictDetection` model (`tt_conflict_detections`) stores conflict events detected during or after generation.

**Detection Types:**
- `REAL_TIME` — Detected during manual edits
- `BATCH` — Detected during batch validation
- `VALIDATION` — Detected during pre-generation validation
- `GENERATION` — Detected during/after timetable generation

**Conflict Data Stored:**
```
{
  timetable_id,
  detection_type,
  detected_at,
  conflict_count,
  hard_conflicts,      // Count of hard constraint violations
  soft_conflicts,      // Count of soft constraint violations
  conflicts_json,      // Detailed conflict data
  resolution_suggestions_json,  // Suggested fixes
  resolved_at          // When resolved (NULL if unresolved)
}
```

**Key Model Methods:**
- `hasConflicts()` → bool
- `hasHardConflicts()` → bool
- `isResolved()` → bool

**Scopes:** `active()`, `unresolved()`, `withHardConflicts()`, `detectionType($type)`

### 11.2 Conflict Types Tracked

| Conflict Type | Source | Severity |
|--------------|--------|----------|
| TEACHER_CONFLICT | Forced placement | CRITICAL — teacher double-booked |
| CLASS_DOUBLE_BOOKING | Forced placement | CRITICAL — class slot occupied twice |
| ROOM_UNAVAILABLE | Room allocation pass | HIGH — required room not available |
| ROOM_TYPE_UNAVAILABLE | Room allocation pass | HIGH — no rooms of required type |
| CONSTRAINT_VIOLATION | ConstraintManager | MEDIUM/HIGH — depends on constraint |
| PARALLEL_VIOLATION | Parallel group check | HIGH — siblings not at anchor's slot |

### 11.3 Conflict Resolution

The module includes a **conflict resolution workflow** via `ConflictResolutionSession` and `ConflictResolutionOption` models:

```
ConflictResolutionSession:
  - uuid, timetable_id
  - conflict_type, conflict_description
  - affected_cells_json (array of cell IDs)
  - status: OPEN → IN_PROGRESS → RESOLVED / ESCALATED
  - priority: CRITICAL / HIGH / MEDIUM / LOW
  - assigned_to, resolved_by, resolved_at
  - resolution_notes

ConflictResolutionOption:
  - conflict_id (FK → session)
  - option_type, description
  - impact_summary
  - affected_entities_json
  - score_impact (decimal — how much it changes quality score)
  - is_recommended (bool)
  - is_selected (bool), selected_by, selected_at
  - execution_result_json
```

**Resolution Flow:**
1. Conflict detected → `ConflictResolutionSession` created (status=OPEN)
2. System generates resolution options (stored as `ConflictResolutionOption`)
3. Admin reviews options, selects one
4. Selected option executed → session marked RESOLVED
5. If not resolved within time limit → escalated via `EscalationRule`

### 11.4 Manual Refinement as Conflict Resolution

The `RefinementService` serves as the primary conflict resolution mechanism:

**`swapActivities(cellId1, cellId2)`:**
1. Load both cells with activity and teacher relationships
2. Verify neither is locked
3. Validate swap (check teacher conflicts after swap)
4. Execute swap in transaction: exchange activity_id, room_id, teacher assignments
5. Set source = 'MANUAL_SWAP'
6. Log change to audit trail

**`moveActivity(cellId, newDayId, newPeriodOrd)`:**
1. Load cell, verify not locked, has activity
2. Validate teacher conflicts at new slot
3. Move activity to new position
4. Set source = 'MANUAL_MOVE'
5. Log change

**`getSwapCandidates(cellId)`:**
- Returns all non-locked cells in same timetable with activities
- Provides: cell_id, day, period, activity_name, subject_name

**`getImpactAnalysis(cellId, action)`:**
- Returns current state + warnings
- Warns if cell is locked

**`lockCell(cellId)` / `unlockCell(cellId)`:**
- Set/clear is_locked, locked_by, locked_at
- Locked cells cannot be swapped or moved

### 11.5 Constraint Violation Tracking

`ConstraintViolation` model (`tt_constraint_violations`) logs individual constraint violations:

```
{
  timetable_id,
  generation_run_id,
  constraint_id,            // FK → tt_constraints
  violation_type: HARD/SOFT,
  violation_count,
  severity,
  day_of_week, period_ord,
  affected_entity_type, affected_entity_id,
  violation_details_json,
  suggested_resolution_json,
  resolved_at
}
```

### 11.6 Revalidation System

The module includes an automated revalidation system:

**`RevalidationSchedule`:** Defines when revalidation runs
- Schedule types: IMMEDIATE, DAILY, WEEKLY, ON_CHANGE
- Tracks: next_run_at, last_run_at, auto_fix_enabled, notification_enabled

**`RevalidationTrigger`:** Events that trigger revalidation
- Trigger types: MANUAL_CHANGE, CONSTRAINT_UPDATE, SUBSTITUTION, SCHEDULE_CHANGE
- Tracks affected entity type and ID

---

*End of Sections 9-11 — Run 4 Complete*

---

## 12. Manual Refinement & Drag-Drop Logic

See Section 11.4 for RefinementService details. Key operations:

- **Swap**: Two-click pattern — select cell A, then cell B → impact modal → confirm
- **Move**: Select cell → drag to empty slot (validates teacher conflicts)
- **Lock/Unlock**: Toggle cell lock state (prevents modifications)
- **Edit Mode**: Preview grid supports HTML5 drag-drop for activity placement

**AJAX Endpoints:**
- `POST /smart-timetable/refinement/swap` → `{ cell_id_1, cell_id_2 }`
- `POST /smart-timetable/refinement/move` → `{ cell_id, day_id, period_ord }`
- `POST /smart-timetable/refinement/lock` → `{ cell_id, lock }`
- `GET /smart-timetable/refinement/candidates/{cellId}` → swap candidates
- `GET /smart-timetable/refinement/impact/{cellId}` → impact analysis

**Audit Trail:** Every refinement operation is logged to `tt_change_logs` with old/new state JSON snapshots.

---

## 13. Parallel Group Handling

See Section 9.7 for algorithm-level parallel period handling. Summary:

**Configuration (UI):**
- Create parallel groups with: code, name, group_type, coordination_type
- Add activities to group (must be 2+ sections of same subject)
- Set one activity as anchor (`is_anchor = true`)
- Auto-detect feature scans for parallel group candidates

**Group Types:** PARALLEL_SECTION, PARALLEL_OPTIONAL, PARALLEL_SKILL, PARALLEL_HOBBY, PARALLEL_CUSTOM
**Coordination Types:** SAME_TIME (default), SAME_DAY, SAME_PERIOD_RANGE

**During Generation:**
- Anchor placed first (+25,000 difficulty score)
- Siblings forced to anchor's exact time slot
- If any sibling fails → entire group backtracks
- Non-anchor siblings SKIP (not block) when anchor hasn't been placed

**Tables:** `tt_parallel_group`, `tt_parallel_group_activity` (with `is_anchor` flag)

---

## 14. Timetable Lifecycle & States

See Section 5.2 for state diagram. States: DRAFT → GENERATING → GENERATED → PUBLISHED → ARCHIVED

**Key Transitions:**
- `DRAFT → GENERATING`: Background job dispatched
- `GENERATING → GENERATED`: Job completes, cells populated
- `GENERATED → PUBLISHED`: Admin clicks Publish (`published_at`, `published_by` set)
- `PUBLISHED → GENERATED`: Admin clicks Unpublish (clears publish fields, status reverts to DRAFT)

---

## 15. Generation Run Lifecycle & Job Queue

### 15.1 Synchronous Generation (Web)

```
1. User submits generation form → TimetableGenerationController::generateWithFET()
2. Acquire distributed lock (Cache::lock, 5min timeout)
3. Set PHP max_execution_time
4. Call TimetableGenerationService::generate() — runs synchronously
5. Store result to session
6. Return preview view
7. User reviews → clicks "Save" → storeTimetable() persists to DB
```

### 15.2 Asynchronous Generation (API)

```
1. POST /api/v1/timetable/generate → TimetableApiController::generate()
2. Create tt_generation_runs record (status='PENDING')
3. Dispatch GenerateTimetableJob to queue
4. Return HTTP 202 with job_id and poll_url
5. Client polls GET /api/v1/timetable/generate/{runId}/status every 2 seconds
6. Job runs FETSolver, updates generation_run record
7. On completion: status='COMPLETED', result available
8. On failure: status='FAILED', error_message stored
```

### 15.3 GenerateTimetableJob

```
JOB: GenerateTimetableJob
QUEUE: default
TIMEOUT: 300 seconds (5 minutes)
TRIES: 1
TRIGGERED BY: TimetableApiController::generate()
DOES: Runs TimetableGenerationService::generate() with parameters from generation_run
SUCCESS: Updates tt_generation_runs status='COMPLETED', stores stats
FAILURE: Updates tt_generation_runs status='FAILED', stores error_message + trace
```

### 15.4 Generation Queue (`tt_generation_queues`)

Separate from Laravel's queue system — tracks generation requests:
- `uuid`, `timetable_id`, `generation_strategy_id`
- `priority` (higher = processed first)
- `status`: PENDING → PROCESSING → COMPLETED / FAILED
- `attempts`, `max_attempts`
- `scheduled_at`, `started_at`, `completed_at`
- `queue_metadata` (JSON)

---

## 16. Substitution Management

### 16.1 Absence Recording

**Route:** POST `/smart-timetable/substitution/absence`
**Input:** teacher_id, date, reason, absence_type (LEAVE|SICK|TRAINING|OFFICIAL_DUTY|OTHER|FULL_DAY)

**Processing:**
1. Create `tt_teacher_absences` record (status=PENDING, substitution_required=true)
2. Find affected timetable cells (active cells for this teacher on this day)
3. Generate substitute recommendations (top 3 candidates per cell)
4. Store in `tt_substitution_recommendations`

### 16.2 Candidate Scoring

**Route:** GET `/smart-timetable/substitution/candidates/{cellId}/{date}`

**Scoring Formula:**

| Criterion | Points | Condition |
|-----------|--------|-----------|
| Subject Match | +40 | Teacher has active capability in this subject |
| Available | +30 | Not occupied at this slot (always applied) |
| Low Sub Load | +0 to +20 | Scaled: `max(0, 20 - (monthly_subs × 4))` |
| Department Match | +10 | Teacher in same department |

**Exclusions:**
- Original teachers on the cell
- Teachers occupied at the same slot
- Teachers with approved/pending absence on this date

### 16.3 Assignment

**Manual:** POST `/smart-timetable/substitution/assign` → assigns specific teacher
**Auto:** POST `/smart-timetable/substitution/auto-assign` → assigns best candidate for all cells

**On Assignment:**
1. Attach substitute to cell (pivot: `is_substitute=true`)
2. Create `tt_substitution_logs` record (method=MANUAL or AUTO, status=ASSIGNED)
3. Update recommendation status (ACCEPTED for chosen, SKIPPED for others)

### 16.4 Pattern Learning

`tt_substitution_patterns` tracks:
- Which substitute teacher works best for which subject/class combination
- Success count, total count, avg effectiveness rating
- Common reasons, best fit scenarios (JSON)
- Confidence score (increases with more data)

### 16.5 Absence Approval

- `POST .../teacher-absence/{id}/approve` → `TeacherAbsences::approve(auth()->id())`
- `POST .../teacher-absence/{id}/reject` → `TeacherAbsences::reject(auth()->id())`

---

## 17. Approval Workflow

The module includes a complete multi-level approval system (models exist, but feature is **~5% implemented**):

**Models:**
- `ApprovalWorkflow` — Workflow definition (name, entity_type, is_active)
- `ApprovalLevel` — Hierarchy levels (level_number, role_required, approval_type, time_limit_hours)
- `ApprovalRequest` — Individual requests (entity_type, entity_id, current_level, status)
- `ApprovalDecision` — Per-level decisions (decision, decided_by, comments)
- `ApprovalNotification` — Notifications (recipient_id, notification_type, is_read)

**Escalation:**
- `EscalationRule` — Rules for auto-escalation (conflict_type, severity, time_limit_minutes)
- `EscalationLog` — Escalation event records

**Status:** PENDING → APPROVED / REJECTED / ESCALATED

**Current Implementation Status:** Models and table schema exist. No controller methods actively use the approval workflow. Timetable publish is direct (no approval gate).

---

## 18. ML / Prediction Features

The module contains ML-related models, but **all are stubs** (0% implemented):

**Models:**
- `MlModel` — ML model registry (name, model_type, version, accuracy_score, model_parameters_json)
- `TrainingData` — Training datasets (feature_vector_json, label, prediction, confidence_score)
- `FeatureImportance` — Feature rankings per model (feature_name, importance_score, ranking)
- `PredictionLog` — Prediction audit (input_features_json, predicted_value, actual_value, was_correct)

**Tables:** `tt_ml_models`, `tt_training_data`, `tt_feature_importances`, `tt_prediction_logs`

**Intended Use (from design docs):**
- Substitute teacher recommendation (pattern-based)
- Constraint violation prediction
- Generation guidance (predict which activities will be hard to place)

**Current Status:** No training, no inference, no data pipeline. Models exist for future implementation.

---

## 19. Validation Service

Pre-generation validation is handled via the **validation dashboard** (`validation/index.blade.php`):

**Partials:**
- `_header` — Validation header with timetable selector
- `_alerts` — Warning/error messages
- `_tabs` — Tabbed interface with sub-sections:
  - `_activities` — Activity validation (all activities have teachers, rooms, periods)
  - `_teachers` — Teacher validation (availability scores, workload capacity)
  - `_rooms` — Room validation (capacity, type availability)
  - `_constraints` — Constraint compatibility check
  - `_statistics` — Summary statistics
- `_actions` — Action buttons (proceed to generation / fix issues)

**Validation Checks (from design docs):**
1. Total Weekly Required Periods ≤ Total Slots Available (per class+section)
2. Total Teacher Availability ≥ Total Required Periods (per subject+format)
3. Total Rooms in Category ≥ Required Rooms (by room type)
4. Active academic session exists
5. Academic term and shift defined
6. Class teachers assigned for all class+section records
7. `actual_total_student > 0` for all class-sections
8. `class_house_room_id` NOT NULL for all records

**Current Status:** Basic checks implemented (~70%). Comprehensive validation framework partially built.

---

## 20. Resource Booking Service

`ResourceBooking` model tracks lab/room/equipment allocations:

```
Fields: resource_type (ROOM|LAB|TEACHER|EQUIPMENT|SPORTS|SPECIAL),
  resource_id, booking_date, day_of_week, period_ord,
  start_time, end_time, booked_for_type (ACTIVITY|EXAM|EVENT|MAINTENANCE),
  booked_for_id, purpose, supervisor_id, status (BOOKED|IN_USE|COMPLETED|CANCELLED)
```

**When Created:** During `storeTimetable()` — room assignments from generation result are persisted as resource bookings.

**Scopes:** `active()`, `forResource(type, id)`, `forDate($date)`, `current()` (BOOKED or IN_USE)

---

## 21. Reporting & Exports

### 21.1 Analytics Reports

| Report | Route | Data Source | Output |
|--------|-------|-------------|--------|
| Teacher Workload | `smart-timetable.analytics.workload` | tt_timetable_cells + teachers | Table: teacher, total_periods, subjects{name: count} |
| Room Utilization | `smart-timetable.analytics.utilization` | tt_timetable_cells + rooms | Cards: overall %, filled/total slots. Table: room, used_slots, utilization % |
| Constraint Violations | `smart-timetable.analytics.violations` | tt_constraint_violations | Severity cards (CRITICAL/HIGH/MEDIUM/LOW). Table: day, period, type, severity, message |
| Subject Distribution | `smart-timetable.analytics.distribution` | tt_timetable_cells + activities | Per-class accordion: subject, days_spread, total_periods, progress bar |

### 21.2 Export Formats

| Export | Route | Format | Content |
|--------|-------|--------|---------|
| Class Timetable PDF | `smart-timetable.export.pdf` | Landscape A4 PDF (DomPDF) | One grid per class, days×periods, subject+teacher+room per cell |
| Teacher Timetable PDF | `smart-timetable.export.teacherPdf` | Landscape A4 PDF (DomPDF) | One grid per teacher, subject+class+room per cell |
| Timetable Excel | `smart-timetable.export.excel` | .xlsx (Laravel Excel) | Via `TimetableExport` class |
| Analytics CSV | `smart-timetable.analytics.export` | CSV | workload/utilization/violations data |

### 21.3 Reports Dashboard

The reports view (`smart-timetable/reports.blade.php`) provides:
- **Timetable Selector** dropdown with status badges
- **4 Summary Cards**: Total Timetables, Active Classes, Avg Quality Score, Total Violations
- **3 Performance Cards**: Teacher Satisfaction %, Room Utilization %, Score
- **2 Charts** (Chart.js): Teacher Load Distribution (bar), Room Utilization (doughnut)
- **7 Detail Tabs**: Summary, Quality, Teacher Load, Room Utilization, Class Coverage, Activity Teacher Capacity, Availability Logs

---

## 22. API Endpoints

| Method | URL | Purpose | Auth |
|--------|-----|---------|------|
| GET | `/api/v1/smarttimetables` | List timetables | auth:sanctum |
| POST | `/api/v1/smarttimetables` | Create timetable | auth:sanctum |
| GET | `/api/v1/smarttimetables/{id}` | View timetable | auth:sanctum |
| PUT | `/api/v1/smarttimetables/{id}` | Update timetable | auth:sanctum |
| DELETE | `/api/v1/smarttimetables/{id}` | Delete timetable | auth:sanctum |
| POST | `/api/v1/timetable/generate` | Trigger async generation → returns job_id | auth:sanctum |
| GET | `/api/v1/timetable/generate/{runId}/status` | Poll generation status | auth:sanctum |
| GET | `/api/v1/timetable/{id}` | Full timetable grid (JSON) | auth:sanctum |
| GET | `/api/v1/timetable/{id}/class/{classId}` | Class-filtered grid | auth:sanctum |
| GET | `/api/v1/timetable/{id}/teacher/{teacherId}` | Teacher-filtered grid | auth:sanctum |
| GET | `/api/v1/timetable/{id}/room/{roomId}` | Room-filtered grid | auth:sanctum |

**API Response Format (timetable grid):**
```json
{
  "success": true,
  "timetable": { "id", "name", "code", "status" },
  "grid": {
    "1": {           // day_of_week
      "1": {         // period_ord
        "activity_id", "subject", "class", "section",
        "room", "teachers": [{ "name", "role" }],
        "is_locked"
      }
    }
  }
}
```

---

## 23. Standard Timetable Views

Standard timetable views are provided via the TimetableFoundation module, not SmartTimetable directly. SmartTimetable routes to TimetableFoundation for:
- Pre-requisites setup
- Timetable masters
- Timetable requirements
- Resource availability
- Timetable preparation
- Reports and logs

SmartTimetable provides its own views for: Constraint Engine, View & Refinement, Substitution Management, Analytics.

---

## 24. Multi-Tenancy Enforcement

**Tenant Resolution:** Via `stancl/tenancy` v3.9 middleware stack:
- `InitializeTenancyByDomain` — Resolves tenant from domain
- `PreventAccessFromCentralDomains` — Blocks central domain access to tenant routes

**Database Isolation:** All `tt_*` tables reside in the **tenant database** (`tenant_db`). Each tenant (school) has its own isolated copy. There is NO `tenant_id` column on `tt_*` tables — isolation is by database, not by row.

**Connection:** Models use the default connection, which is switched to the tenant's database by the tenancy middleware. No explicit `connection` property needed on models.

**Cross-Tenant Protection:** Since each tenant has a separate database, cross-tenant access is architecturally impossible at the database level.

**Missing:** `EnsureTenantHasModule` middleware is NOT applied to SmartTimetable routes, meaning tenants without the SmartTimetable module subscription can still access these routes (security gap).

---

## 25. Role & Permission Matrix

**Permission Naming Convention:** `smart-timetable.{resource}.{action}`

| Role | View Timetables | Create/Edit | Generate | Publish | Manage Substitutions | Manage Constraints |
|------|----------------|-------------|----------|---------|---------------------|-------------------|
| Super Admin | All | All | Yes | Yes | Yes | Yes |
| School Admin | All | All | Yes | Yes | Yes | Yes |
| Vice Principal | All | Limited | No | No | Yes (view) | View only |
| Teacher | Own timetable | No | No | No | View own history | No |
| Student | Own class | No | No | No | No | No |

**26 Permission Resources** with standard actions (viewAny, view, create, update, delete):
timetable, activity, constraint, parallel-group, teacher-availability, requirement, class-subject-subgroup, period-set, period-set-period, room-unavailable, slot-requirement, teacher-assignment-role, teacher-unavailable, timetable-type, working-day, school-day, school-shift, day-type, period-type, timing-profile, tt-config, generation-strategy, report, academic-term, config, validation

**Special Actions:** timetable.generate, timetable.publish, timetable.store, activity.generate, requirement.generate, teacher-availability.generate, report.export

**Security Gap (SEC-009):** 17/28 controllers have ZERO authorization checks. SmartTimetablePolicy is empty (all methods return true).

---

## 26. Events, Jobs & Caching

### 26.1 Jobs

| Job | Queue | Timeout | Purpose |
|-----|-------|---------|---------|
| GenerateTimetableJob | default | 300s | Async timetable generation |

### 26.2 Events & Listeners

No custom Laravel events are currently dispatched. The `EventServiceProvider` exists but registers no listeners. Generation completion is tracked via database status polling, not events.

### 26.3 Caching

- **Distributed Lock:** `Cache::lock('timetable-generation', 300)` prevents concurrent generation
- **Constraint Cache:** `ConstraintEvaluator` caches evaluation results per slot+activity combination during generation
- **No Redis Cache Keys:** No persistent cache keys are used for timetable data

---

## 27. Configuration Options

### 27.1 Module Config (`config/config.php`)

```php
'max_attempts' => 1,           // Number of generation attempts
'max_total_time_seconds' => 300  // Total time limit
```

### 27.2 Database Config (`tt_config`)

Key-value configuration stored in `tt_config` table. Values seeded by `TtConfigSeeder`. Each entry has:
- `key` (immutable), `key_name` (user-editable), `value`, `value_type`
- `tenant_can_modify` flag, `mandatory` flag, `used_by_app` flag

### 27.3 Generation Strategy (`tt_generation_strategy`)

| Parameter | Type | Default | Range |
|-----------|------|---------|-------|
| algorithm_type | ENUM | RECURSIVE | RECURSIVE, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID |
| max_recursive_depth | INT | 14 | 1-100 |
| max_placement_attempts | INT | 2000 | 1-10000 |
| tabu_size | INT | 100 | 10-1000 |
| cooling_rate | DECIMAL | 0.95 | 0.01-0.99 |
| population_size | INT | 50 | 10-1000 |
| generations | INT | 100 | 10-10000 |
| activity_sorting_method | ENUM | LESS_TEACHER_FIRST | LESS_TEACHER_FIRST, DIFFICULTY_FIRST, CONSTRAINT_COUNT, DURATION_FIRST, RANDOM |
| timeout_seconds | INT | 300 | 30-3600 |
| parameters_json | JSON | null | Algorithm-specific extra params |

---

## 28. Cross-Module Dependencies

| Dependency Direction | Module | What SmartTimetable Uses |
|---------------------|--------|--------------------------|
| **SmartTimetable → SchoolSetup** | SchoolSetup | Classes, Sections, Subjects, StudyFormats, Teachers, Rooms, Buildings, AcademicTerms, ClassGroups, TeacherCapabilities |
| **SmartTimetable → TimetableFoundation** | TimetableFoundation | Activity, Timetable, TimetableCell, SubActivity, SchoolDay, PeriodSetPeriod, TeacherAvailablity, RoomAvailability, RequirementConsolidation (10 backward-compat aliases) |
| **SmartTimetable → Prime** | Prime | AcademicSession |
| **SmartTimetable → GlobalMaster** | GlobalMaster | AcademicSession (global) |
| **SmartTimetable → Core App** | App\Models | User (for audit trails) |

**Known Issue (ARCH-003):** SchoolSetup ↔ SmartTimetable circular dependency exists. SchoolSetup provides master data, but SmartTimetable's requirement generation reads back into SchoolSetup tables.

---

## 29. Gap Analysis: Design vs Implementation

### 29.1 Feature Implementation Status

| Feature | Design Doc | Status | Evidence | Gap |
|---------|-----------|--------|----------|-----|
| Master Setup (Phase 0) | Req v3, Process Flow v3 | 95% | Full CRUD for all master tables | Minor validation gaps |
| Requirement Consolidation (Phase 1) | Process Flow v3 | 90% | Core done | Bulk regeneration partial |
| Teacher Availability (Phase 2) | Process Execution v1 | 85% | Generation works | Scoring formulas partially implemented |
| Activity Creation (Phase 3) | Generation Flow v6 | 80% | CRUD done | Teacher assignment partial |
| Pre-Generation Validation (Phase 4) | Validation v6 | 70% | Basic checks only | 7+ validation checks not implemented |
| Timetable Generation (Phase 5) | Algorithm Design | 85% | FET solver + parallel periods done | ~30/155 constraints in solver |
| Analytics (Phase 6) | Req v3 | 15% | Post-gen checks added | Most analytics not started |
| Publish & Refinement (Phase 7) | Req v3 | 5% | Basic publish/unpublish | Approval workflow stub |
| Substitution (Phase 8) | Req v3 | 0% | Models exist, SubstitutionService exists | SubstitutionController has methods but not fully integrated |
| API & Async (Phase 9) | Req v3 | 0% | API controller exists | Not production-tested |
| Security & Authorization | — | 30% | 17/28 controllers unprotected | SEC-009 critical |
| ML / Prediction | Req v3 | 0% | Models exist only | No implementation |
| Approval Workflow | Req v3 | 5% | Models + tables exist | No controller integration |

### 29.2 Constraint Implementation Gap

| Category | Total Rules | Implemented | Gap |
|----------|------------|-------------|-----|
| A — Hard Rules (Basic) | 5 | 5 | 0 |
| B1 — Teacher (per-teacher) | 22 | ~7 | 15 |
| B2 — Teacher (global) | 20 | 0 | 20 |
| C1 — Class (per-class) | 18 | ~5 | 13 |
| C2 — Class (global) | 15 | 0 | 15 |
| D — Activity-Level | 22 | 7 | 15 |
| E — Room/Space | 26 | 3 | 23 |
| F — DB-Configurable | 25 | 12 | 13 |
| G — Global Policy | 9 | ~4 | 5 |
| H — Inter-Activity | 22 | 1 (Parallel) | 21 |
| **TOTAL** | **~155** | **~30** | **~125** |

### 29.3 Known Code Quality Issues

1. **SmartTimetableController**: ~3,378 lines — god controller needing split
2. **FETSolver**: ~2,830 lines — large but cohesive
3. **16 controllers** use inline validation instead of FormRequests
4. **Empty SmartTimetablePolicy** — all authorize methods return true
5. **0 module-level tests** — some exist at app level (9 tests, 23 assertions for parallel periods)
6. **0 factories** — no test data generation
7. **0 module-level migrations** — all managed at app/TimetableFoundation level
8. **10 backward-compatibility model aliases** — should be cleaned up
9. **5 generation view versions** (generate-timetable through generate-timetable_5) — iterative versions not cleaned up

### 29.4 Security Issues

1. **SEC-009**: 17/28 controllers have zero authorization checks
2. Unprotected `truncate()` on 3 core tables (Activities, TeacherAvailability, Requirements)
3. Missing `EnsureTenantHasModule` middleware
4. Empty SmartTimetablePolicy (all methods return true)
5. Request data logged to app log (potential sensitive data exposure)

---

## 30. Appendix A — Method Reference Index (Key Methods)

```
FETSolver::solve(Collection $activities): GenerationResult
FETSolver::backtrack(array $activities, int $index, TimetableSolution $solution, array $context): bool
FETSolver::generateGreedySolution(array $activities, array $context): TimetableSolution
FETSolver::getPossibleSlots(Activity $activity, TimetableSolution $solution, array $context): array
FETSolver::isBasicSlotAvailable(Activity $activity, Slot $slot, array $context): bool
FETSolver::canPlaceWithConstraints(Activity $activity, Slot $slot, array $context): bool
FETSolver::scoreSlotForActivity(Activity $activity, Slot $slot, array $context): int
FETSolver::orderActivitiesByDifficulty(array $activities): array
FETSolver::expandActivitiesByWeeklyPeriods(Collection $activities): array
FETSolver::convertSolutionToEntries(TimetableSolution $solution, Collection $activities): array
FETSolver::buildSchoolGrid(array $entries, Collection $activities, Collection $days): array

TimetableGenerationService::generate(int $termId, int $typeId, array $options): GenerationResult

ConstraintManager::checkHardConstraints(Slot $slot, Activity $activity, array $context): bool
ConstraintManager::evaluateSoftConstraints(Slot $slot, Activity $activity, array $context): float

ConstraintFactory::create(Constraint $constraint): TimetableConstraint
DatabaseConstraintService::loadConstraintsForGeneration(int $sessionId): ConstraintManager

RoomAllocationPass::allocate(array $entries, Collection $activities, Collection $rooms): array

RefinementService::swapActivities(int $cellId1, int $cellId2): array
RefinementService::moveActivity(int $cellId, int $newDayId, int $newPeriodOrd): array
RefinementService::lockCell(int $cellId): array
RefinementService::unlockCell(int $cellId): array
RefinementService::getSwapCandidates(int $cellId): array
RefinementService::getImpactAnalysis(int $cellId, string $action): array

SubstitutionService::getDashboard(string $date): array
SubstitutionService::reportAbsence(int $teacherId, string $date, ?string $reason, string $type): array
SubstitutionService::findSubstitutes(int $cellId, string $date): array
SubstitutionService::assignSubstitute(int $cellId, int $substituteTeacherId, string $date, ?int $absenceId): array
SubstitutionService::autoAssign(int $teacherId, string $date): array
SubstitutionService::getSubstitutionHistory(int $teacherId): array

TimetablePublishController::publishTimetable(int $id): JsonResponse
TimetablePublishController::unpublishTimetable(int $id): JsonResponse

TimetableExportController::exportPdf(Request $request, int $timetableId): Response
TimetableExportController::exportExcel(Request $request, int $timetableId): BinaryFileResponse
TimetableExportController::exportTeacherPdf(Request $request, int $timetableId): Response

AnalyticsController::workload(Request $request): View
AnalyticsController::utilization(Request $request): View
AnalyticsController::violations(Request $request): View
AnalyticsController::distribution(Request $request): View
AnalyticsController::export(Request $request, string $type): StreamedResponse
```

---

## 31. Appendix B — Table × Operation Matrix

| Table | Create | Read | Update | Delete | Bulk Insert |
|-------|--------|------|--------|--------|-------------|
| tt_config | Seeder | TimetableMenuController | CRUD | SoftDelete | — |
| tt_generation_strategy | CRUD | Multiple controllers | CRUD | SoftDelete | — |
| tt_shift | CRUD | SmartTimetableController | CRUD | SoftDelete | — |
| tt_day_type | CRUD | SmartTimetableController | CRUD | SoftDelete | — |
| tt_period_type | CRUD | SmartTimetableController | CRUD | SoftDelete | — |
| tt_school_days | Seeder | FETSolver, Preview | CRUD | SoftDelete | — |
| tt_period_set | CRUD | Multiple | CRUD | SoftDelete | — |
| tt_period_set_period_jnt | CRUD | FETSolver, Preview | CRUD | SoftDelete | — |
| tt_timetable_type | CRUD | Multiple | CRUD | SoftDelete | — |
| tt_class_timetable_type_jnt | CRUD | Generation | CRUD | SoftDelete | — |
| tt_slot_requirement | Auto-gen | Validation | Edit | Truncate | Yes |
| tt_class_requirement_groups | Auto-gen | Consolidation | Edit | Truncate | Yes |
| tt_class_requirement_subgroups | Auto-gen | Consolidation | Edit | Truncate | Yes |
| tt_requirement_consolidation | Auto-gen | Activity creation | Edit | Truncate | Yes |
| tt_constraint_category_scope | Seeder/CRUD | ConstraintController | CRUD | SoftDelete | — |
| tt_constraint_type | Seeder/CRUD | ConstraintController | CRUD | SoftDelete | — |
| tt_constraint | CRUD | FETSolver, ConstraintManager | CRUD | SoftDelete | — |
| tt_teacher_unavailable | CRUD | FETSolver | CRUD | SoftDelete | — |
| tt_room_unavailable | CRUD | RoomAllocation | CRUD | SoftDelete | — |
| tt_teacher_availability | Auto-gen | FETSolver | Edit | Truncate | Yes |
| tt_teacher_availability_detail | Auto-gen | FETSolver | — | — | Yes |
| tt_room_availability | Auto-gen | RoomAllocation | — | — | Yes |
| tt_activity | Auto-gen | FETSolver, Preview | Edit | Truncate | Yes |
| tt_parallel_group | CRUD | FETSolver | CRUD | SoftDelete | — |
| tt_parallel_group_activity | CRUD | FETSolver | Update anchor | SoftDelete | — |
| **tt_timetable** | **storeTimetable** | **Preview, Analytics** | **Publish/Unpublish** | **SoftDelete** | — |
| **tt_timetable_cell** | **storeTimetable** | **Preview, Refinement** | **Swap/Move/Lock** | **Remove** | **Yes (500/chunk)** |
| tt_timetable_cell_teacher | storeTimetable | Preview | Swap | Delete | Yes (500/chunk) |
| tt_generation_run | storeTimetable/API | Generation history | Status updates | SoftDelete | — |
| tt_conflict_detection | Post-generation | Analytics | Resolution | — | — |
| tt_constraint_violation | Post-generation | Violations report | Resolution | — | — |
| tt_resource_booking | Post-generation | Booking queries | Status updates | — | — |
| tt_teacher_workload | Post-generation | Workload report | Recalculate | SoftDelete | — |
| tt_change_log | Refinement ops | Audit trail | — | SoftDelete | — |
| tt_teacher_absence | SubstitutionService | Dashboard | Approve/Reject | SoftDelete | — |
| tt_substitution_log | SubstitutionService | History | Notify/Complete | SoftDelete | — |
| tt_substitution_pattern | SubstitutionService | Candidate scoring | Update counts | — | — |
| tt_substitution_recommendation | SubstitutionService | Recommendations | Accept/Skip | — | — |

---

*End of Complete Documentation — All Sections (1-31) Written*

**Document Statistics:**
- **Total Sections:** 31 (including 2 appendices)
- **Key Coverage:** Module overview, terminology, design intent, file inventory, routes, user workflow, screens, database schema, data flows, algorithm (FETSolver), constraints (60+ classes), conflict detection, refinement, substitution, approval workflow, ML stubs, validation, exports, API, multi-tenancy, permissions, gap analysis
- **Source Files Analyzed:** 449 files (20 controllers, 63 models, 108 services, 176 views, 14 seeders, 31 docs)
- **DDL Tables Documented:** 43+ tables from v7.6 DDL + migration-only tables
