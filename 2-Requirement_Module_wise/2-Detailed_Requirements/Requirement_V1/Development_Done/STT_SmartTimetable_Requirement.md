# SmartTimetable Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** STT | **Module Path:** `Modules/SmartTimetable`
**Module Type:** Tenant Module | **Database:** `tenant_{uuid}`
**Table Prefix:** `tt_` | **Processing Mode:** FULL
**RBS Reference:** Module G — Advanced Timetable Management (lines 2360–2473)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The SmartTimetable module is the AI-assisted, constraint-based timetable generation engine for Prime-AI. It automates the entire school scheduling process — from academic structure mapping through activity definition, constraint configuration, FET-solver-based generation, analytics, manual refinement, and daily substitution management — eliminating weeks of manual scheduling effort for Indian K-12 school administrators.

### 1.2 Scope

SmartTimetable covers: (a) timetable foundation setup (shifts, day types, period types, period sets, school days, working days, timetable types), (b) requirement definition (slot requirements, class requirement groups, subgroups, and requirement consolidation), (c) constraint engine (22 hard + 63 soft constraint PHP classes), (d) resource availability (teacher and room availability grids), (e) activity preparation (activities, sub-activities, priority scoring), (f) FET-solver-based batch and per-class generation with asynchronous job execution, (g) generation monitoring and approval workflow, (h) post-generation analytics (teacher workload, room utilization, violations), (i) manual refinement (swap/move/lock cells), (j) substitution management (absence recording, candidate scoring, assignment), (k) REST API for external integration, and (l) parallel period group management for shared elective activities.

### 1.3 Module Statistics

| Item | Count |
|---|---|
| Controllers (web) | 12 (`SmartTimetableController`, `AnalyticsController`, `ConstraintCategoryController`, `ConstraintController`, `ConstraintScopeController`, `ConstraintTypeController`, `ParallelGroupController`, `RefinementController`, `RoomUnavailableController`, `SubstitutionController`, `TeacherUnavailableController`, `TtGenerationStrategyController`) |
| Controllers (API) | 1 (`TimetableApiController`) |
| Models | 62 |
| Services (total) | 106 (organized across root, Constraints/Hard, Constraints/Soft, Generator, Solver, Storage sub-namespaces) |
| FormRequests | 7 |
| Tests | 7 (1 Feature, 6 Unit) |
| Views | 80+ (partial listing; includes analytics, generation, refinement, validation, constraint-management, parallel-group, preview) |
| Web Routes | 100+ (in `tenant.php` under prefix `smart-timetable`) |
| API Routes | 16 (in `api.php` under prefix `/api/v1/timetable`, auth:sanctum) |
| Migrations | Multiple (managed via nwidart module migrations) |
| Seeders | 9 (TtConfig, ConstraintCategory, ConstraintScope, ConstraintTargetType, ConstraintType, GenerationStrategy, PeriodType, DayType, Day) |

### 1.4 Implementation Status

| Area | Status | Notes |
|---|---|---|
| Foundation masters (shifts, days, period sets, etc.) | Done | Full CRUD + soft delete + toggle-status for all foundation entities |
| Constraint engine (PHP classes) | Done | 22 hard + 63 soft constraint classes; FETConstraintBridge BUG-TT-002 broken |
| Teacher & room unavailability | Done | CRUD + toggle; linked to tt_constraint |
| Teacher & room availability grids | Done | Generator + detail-level day/period grid |
| Requirement consolidation | Done | generateRequirements(), updatePeriods() |
| Activity generation | Done | generateActivities(), generateAllActivities(), getBatchGenerationProgress() |
| Priority scoring (ActivityScoreService) | Done | 6-factor scoring: scarcity, load ratio, TAR, rigidity, resource scarcity, difficulty |
| FET Solver generation | Partial (~70%) | Core FETSolver works; FETConstraintBridge broken (BUG-TT-002); 12 known bugs |
| Generation monitoring | Done | Job (GenerateTimetableJob), status view, polling |
| Approval workflow | Partial | Status transitions exist in model; approval UI incomplete |
| Timetable publishing | Partial | Status field exists; publish action needs UI wiring |
| Post-generation analytics | Done | AnalyticsService, AnalyticsController, 5 views + reports, CSV export |
| Manual refinement | Done | RefinementService, RefinementController, swap/move/lock, change log |
| Substitution management | Done | SubstitutionService, SubstitutionController, candidate scoring, pattern learning |
| Parallel period groups | Done | ParallelGroupController + anchor mechanism + ParallelPeriodConstraint |
| REST API | Done | TimetableApiController, 16 endpoints, auth:sanctum |
| God controller refactoring | Not done | SmartTimetableController: ~3,245 lines (target: split into sub-controllers) |
| BUG-TT-002 (FETConstraintBridge) | Not fixed | Context broken; constraints not wired to solver |

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian K-12 school scheduling is extremely complex: 30–50 teachers, 20–40 class-sections, 600–1200 subjects-per-week slots, lab sharing constraints, teacher availability restrictions, PTM days, exam days, parallel elective groups, and shift differences all need simultaneous satisfaction. Manual scheduling takes 2–4 weeks and produces conflict-prone outputs. SmartTimetable automates this using a FET-inspired CSP (Constraint Satisfaction Problem) backtracking solver with heuristic scoring, Tabu Search optimization, and Simulated Annealing post-processing.

### 2.2 User Personas

| Persona | Primary Actions |
|---|---|
| School Admin / Timetable Coordinator | Full module access: configure, generate, approve, publish, manage substitutions |
| Principal | Approve timetable, view analytics |
| Teacher | View own timetable (via API/Standard view), accept substitution assignments |
| System (Automated) | GenerateTimetableJob, pattern learning, analytics computation |

### 2.3 Key Design Principles

- Activity-based scheduling: the fundamental unit is an Activity (class + section + subject + study_format + required_weekly_periods)
- Constraint-first: hard constraints are never violated; soft constraints minimized via scoring
- Parallel group anchor mechanism: elective/hobby activities across sections pinned to the same time slot
- Atomic DB storage: entire generation solution stored in a single database transaction
- Soft delete on all tables via `is_active` + `deleted_at`
- Audit trail via `tt_change_log` + `sys_activity_logs`

---

## 3. BUSINESS RULES

### 3.1 Foundation Rules

**BR-STT-001:** A school must have at least one active Shift, at least 5 active school days, at least one Period Set with at least 6 periods, and one TimetableType before generation is allowed.

**BR-STT-002:** `tt_period_set_period_jnt.duration_minutes` is a generated column computed from `end_time - start_time`; it cannot be manually set.

**BR-STT-003:** `tt_timetable_type` effective_from and effective_to must be non-overlapping for the same shift. Application enforces this.

**BR-STT-004:** Class Working Days (`tt_class_working_day_jnt`) override the global working day calendar for a specific class/section. Exam days reduce available teaching slots for that class.

### 3.2 Constraint Rules

**BR-STT-005:** Hard constraints are never violated during generation. If satisfaction is impossible, the generation run fails with FAILED status and an error message.

**BR-STT-006:** Each constraint instance is scoped: GLOBAL (applies to all), TEACHER (specific teacher), ROOM (specific room), ACTIVITY (specific activity), CLASS, CLASS+SECTION, etc.

**BR-STT-007:** `tt_constraint.is_hard` overrides `tt_constraint_type.is_hard_constraint` — an admin can escalate a soft constraint to hard for a specific scope.

**BR-STT-008:** `tt_teacher_unavailable` and `tt_room_unavailable` are the simplified UI-level unavailability records. They are backed by corresponding `tt_constraint` records.

### 3.3 Activity Rules

**BR-STT-009:** An Activity must reference either a `class_group_id` or a `class_subgroup_id` — never both (enforced by CHECK constraint).

**BR-STT-010:** `tt_activity.total_periods` = `duration_periods` × `weekly_periods` (generated column).

**BR-STT-011:** When `have_sub_activity = 1`, the solver must split the activity across multiple `tt_sub_activity` records, each potentially assigned to a different class section.

**BR-STT-012:** Parallel group activities must be pinned to the same `(day_of_week, period_ord)` slot. The first activity placed becomes the anchor; subsequent parallel activities are assigned the anchor slot.

### 3.4 Generation Rules

**BR-STT-013:** Activities are scored and sorted before placement: hardest (highest difficulty_score + fewest eligible teachers) are placed first (LESS_TEACHER_FIRST strategy).

**BR-STT-014:** FET Solver runs up to 50,000 iterations with a 25-second timeout (configurable via `tt_generation_strategy`). Partial solutions are accepted and flagged.

**BR-STT-015:** A new `tt_generation_run` record is created per run. Multiple runs per `tt_timetable` are allowed (run_number increments).

**BR-STT-016:** Generation is asynchronous via `GenerateTimetableJob` dispatched to Laravel queue. Frontend polls `/generation-status/{run}` every 3 seconds.

### 3.5 Approval and Publishing Rules

**BR-STT-017:** Timetable status flow: `DRAFT` → `GENERATING` (on job dispatch) → `GENERATED` (on success) → `APPROVED` (admin action) → `PUBLISHED`. Reversal to DRAFT is allowed only from GENERATED.

**BR-STT-018:** Only a PUBLISHED timetable is visible to teachers and students via the Standard Timetable views and REST API.

**BR-STT-019:** Once PUBLISHED, cells cannot be moved or swapped — only substitutions are allowed. Refinement requires reverting to APPROVED.

### 3.6 Substitution Rules

**BR-STT-020:** A substitute teacher record sets `tt_timetable_cell_teacher.is_substitute = 1`. The original teacher record remains; the substitute is an additional record.

**BR-STT-021:** Candidate scoring formula: Subject match (40 pts) + Pattern × confidence (25 pts) + Day availability (20 pts) + Workload balance (15 pts).

**BR-STT-022:** Pattern learning triggers only on `completeSubstitution()` — updates `tt_substitution_patterns` with a running average.

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-STT-001: Activity Management

**FR-STT-001.1** The system must allow generating activities automatically from requirement consolidation records via the `generateActivities()` and `generateAllActivities()` methods.

**FR-STT-001.2** The system must allow manual CRUD on activities (create, edit, soft-delete, restore, toggle-status) via `FoundationActivityController`.

**FR-STT-001.3** Each activity must capture: academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, subject_type_id, subject_study_format_id, required_weekly_periods, duration_periods, allow_consecutive, max_consecutive, preferred_periods_json, avoid_periods_json, spread_evenly, compulsory_specific_room_type, required_room_type_id.

**FR-STT-001.4** The system must support batch activity generation with async progress polling via `getBatchGenerationProgress()`.

**FR-STT-001.5** Activities with `have_sub_activity = 1` must have at least one `tt_sub_activity` child record defining same_day_as_parent and consecutive_with_previous constraints.

**FR-STT-001.6** The system must map teachers to activities via `tt_activity_teacher` records (assignment_role_id, is_required, ordinal).

### FR-STT-002: Constraint Configuration

**FR-STT-002.1** The system must provide CRUD management for Constraint Categories and Scopes (seeded by Prime, name-editable by school).

**FR-STT-002.2** The system must provide CRUD management for Constraint Types (system-defined, school can enable/disable).

**FR-STT-002.3** The system must allow creating Constraint instances via `ConstraintController.createByCategory()` — category-specific forms rendered from `tt_constraint_type.param_schema`.

**FR-STT-002.4** Each constraint must support: target_type (scope), target_id (individual entity), is_hard flag, weight (1–100), params_json, effective date range, applicable_days_json.

**FR-STT-002.5** The system must support 22 hard constraint classes:

| Constraint | Description |
|---|---|
| TeacherConflictConstraint | No teacher double-booking |
| NotOverlappingConstraint | No student group double-booking |
| RoomExclusiveUseConstraint | No room double-booking |
| TeacherUnavailablePeriodsConstraint | Respect teacher unavailability records |
| TeacherRoomUnavailableConstraint | Combined teacher+room unavailability |
| TeacherMaxDailyConstraint | Max teaching periods per day per teacher |
| TeacherMaxWeeklyConstraint | Max teaching periods per week per teacher |
| ClassMaxPerDayConstraint | Max periods per day for a class group |
| ClassWeeklyPeriodsConstraint | Exactly required_weekly_periods placed per week |
| ClassConsecutiveRequiredConstraint | Min consecutive periods when required |
| ActivityFixedToDayConstraint | Pin activity to a specific day |
| ActivityFixedToPeriodRangeConstraint | Pin activity to a period range |
| ActivityExcludedFromDayConstraint | Exclude activity from a specific day |
| OccupyExactSlotsConstraint | Activity must occupy exactly N slots |
| SameStartingTimeConstraint | Two activities must start at same time |
| ConsecutiveActivitiesConstraint | Two activities must be consecutive |
| ParallelPeriodConstraint | Parallel group activities pinned to anchor slot |
| GlobalFixedPeriodConstraint | School-wide period reservation (assembly, etc.) |
| GlobalHolidayConstraint | No activities on holidays |
| ExamOnlyPeriodsConstraint | Exam periods reserved for exams only |
| NoTeachingAfterExamConstraint | No teaching after exam period on same day |
| RoomMaxUsagePerDayConstraint | Room usage cap per day |

**FR-STT-002.6** The system must support 63 soft constraint classes organized into teacher-scope, class-scope, room-scope, and global-scope categories (see Section 5 for list).

**FR-STT-002.7** A constraint management dashboard (`constraint-management/index.blade.php`) must display constraints grouped by category: Teacher, Class, Room, Activity, Inter-Activity, Global Policies, DB Constraints.

### FR-STT-003: Teacher Availability Management

**FR-STT-003.1** The system must generate teacher availability records from requirement consolidation via `generateTeacherAvailability()`.

**FR-STT-003.2** Teacher availability must capture: is_full_time, preferred_shift, capable_handling_multiple_classes, can_be_used_for_substitution, certified_for_lab, max/min_available_periods_weekly, max/min_allocated_periods_weekly, proficiency_percentage, teaching_experience_months, competency_level, priority_order, priority_weight, scarcity_index, allocation_strictness (Hard/Medium/Soft).

**FR-STT-003.3** The system must generate a day-by-period detail grid (`tt_teacher_availability_detail`) showing Available/Unavailable/Assigned/Free Period status for each teacher×day×period slot.

**FR-STT-003.4** Teacher availability must expose two computed columns: `available_for_full_timetable_duration` (STORED generated) and `no_of_days_not_available` (STORED generated).

**FR-STT-003.5** The system must support recording specific teacher unavailability via `TeacherUnavailableController` (recurring or date-range, day-of-week + period_no).

**FR-STT-003.6** Teachers can record availability logs via the availability log controller (edit/update/soft-delete).

### FR-STT-004: Timetable Generation (FET Solver Pipeline)

**FR-STT-004.1** Generation is initiated via `POST /smart-timetable/generate/generate-fet` which dispatches `GenerateTimetableJob` to queue.

**FR-STT-004.2** The generation pipeline must execute in this sequence:
1. Pre-generation validation (ValidationService) — check activities exist, teacher availability set, constraints valid
2. Activity scoring (ActivityScoreService) — compute difficulty_score for all activities
3. Room allocation pass (RoomAllocationPass) — pre-assign rooms where possible
4. Sub-activity generation (SubActivityService) — split multi-period activities
5. FET Solver (FETSolver) — CSP backtracking with 50K iterations, 25s timeout
6. Post-solver optimization (TabuSearchOptimizer or SimulatedAnnealingOptimizer)
7. Solution evaluation (SolutionEvaluator) — compute hard/soft violation counts
8. Atomic DB storage (TimetableStorageService) — store cells + teacher assignments in transaction
9. Resource booking (ResourceBookingService) — create tt_resource_booking records
10. Conflict detection (ConflictDetectionService.detectFromGrid())
11. Update tt_generation_run status to COMPLETED or FAILED

**FR-STT-004.3** The FET Solver must implement activity-first placement: score + sort activities, then for each activity attempt slot placement respecting all active hard constraints.

**FR-STT-004.4** For each activity placement, the solver must check: teacher conflict, student group conflict, room availability, teacher unavailability, max daily load, parallel group anchoring.

**FR-STT-004.5** The system must support generation for a single class-section via `GET /smart-timetable/generate/{class_id}/{section_id}/generate`.

**FR-STT-004.6** Generation strategy parameters (algorithm_type, max_recursive_depth, max_placement_attempts, tabu_size, cooling_rate, population_size, timeout_seconds) must be configurable via `TtGenerationStrategyController`.

### FR-STT-005: Generation Status and Monitoring

**FR-STT-005.1** The system must maintain a `tt_generation_run` record per run with fields: started_at, finished_at, status (QUEUED/RUNNING/COMPLETED/FAILED/CANCELLED), activities_total, activities_placed, activities_failed, hard_violations, soft_violations, soft_score, error_message.

**FR-STT-005.2** A generation progress view (`generation/progress.blade.php`) must poll `/generation-status/{run}` every 3 seconds and display live placement counts and status.

**FR-STT-005.3** If generation fails, the run status must be set to FAILED with an error_message, and the timetable status must revert to DRAFT.

**FR-STT-005.4** The system must support cancellation of a QUEUED or RUNNING job, setting status to CANCELLED.

**FR-STT-005.5** The generation log must record all placement events, constraint violations encountered, and solver iteration summary in `stats_json`.

### FR-STT-006: Timetable Approval Workflow

**FR-STT-006.1** After successful generation, a timetable enters GENERATED status. An authorized user must explicitly move it to APPROVED.

**FR-STT-006.2** The approval action must trigger re-computation of analytics (AnalyticsService).

**FR-STT-006.3** The system must provide a preview view (`preview/index.blade.php`) showing the generated grid, activities summary, health report, conflicts details, and placement diagnostics before approval.

**FR-STT-006.4** If hard constraint violations exist, the system must warn the approver but allow override with reason (Admin-only).

### FR-STT-007: Timetable Publishing

**FR-STT-007.1** An APPROVED timetable can be published by setting status = PUBLISHED, recording published_at and published_by.

**FR-STT-007.2** Once published, the timetable becomes visible to teachers and students through Standard Timetable views and the REST API.

**FR-STT-007.3** A previously published timetable can be superseded by publishing a new version (`parent_timetable_id` links the chain); the old timetable moves to ARCHIVED.

**FR-STT-007.4** The system must support exporting the published timetable as CSV (via AnalyticsService export endpoints).

### FR-STT-008: Post-Generation Analytics

**FR-STT-008.1** The AnalyticsService must compute teacher workload (`computeTeacherWorkload()`), upserted into `tt_teacher_workload` (weekly_periods_assigned, utilization_percent, gap_periods_total, consecutive_max, daily_distribution_json, subjects_assigned_json, classes_assigned_json).

**FR-STT-008.2** The AnalyticsService must compute room utilization, upserted into `tt_room_utilizations`.

**FR-STT-008.3** The AnalyticsService must compute constraint violations from the latest `tt_conflict_detection` record via `computeConstraintViolations()`.

**FR-STT-008.4** The system must support daily snapshots via `takeDailySnapshot()` — upserted into `tt_analytics_daily_snapshots` by date.

**FR-STT-008.5** The analytics dashboard must auto-lazy-compute: if tables are empty on first GET, trigger computation before rendering.

**FR-STT-008.6** Analytics views required: `analytics/index.blade.php` (dashboard), `analytics/workload.blade.php`, `analytics/utilization.blade.php`, `analytics/violations.blade.php`, `analytics/distribution.blade.php`.

**FR-STT-008.7** Report views required: class-wise, teacher-wise, room-wise reports — all sharing the `analytics/reports/_grid.blade.php` partial (days × periods grid).

**FR-STT-008.8** CSV export must be available for workload, utilization, and distribution reports via `GET /smart-timetable/analytics/export/{type}` using `fputcsv()` to `php://temp`.

### FR-STT-009: Manual Refinement (Swap/Move/Lock)

**FR-STT-009.1** The RefinementService must support `swapCells()` — exchange two cells' activities + rooms, with full impact analysis beforehand.

**FR-STT-009.2** The RefinementService must support `moveCell()` — move one cell's activity to an empty target slot.

**FR-STT-009.3** The RefinementService must support `lockCell()` / `unlockCell()` — pin a cell to prevent auto-overwrite; `lockAll()` and `unlockAll()` for batch operations.

**FR-STT-009.4** The system must provide `analyseSwapImpact()` as a JSON endpoint (`POST /smart-timetable/refinement/swap`) called via `fetch()` before showing the swap confirmation modal.

**FR-STT-009.5** The system must support batch swap operations via `batchSwap()` and `rollbackBatch()`.

**FR-STT-009.6** The refinement index view must implement a two-click cell selection pattern: first cell-click selects source; second cell-click triggers impact analysis + opens swap modal.

**FR-STT-009.7** Every cell change must be recorded in `tt_change_log` (change_type, old_values_json, new_values_json, reason, changed_by).

**FR-STT-009.8** Conflict resolution sessions (`openResolutionSession()`, `applyResolutionOption()`, `escalateSession()`) must be supported for detected conflicts.

**FR-STT-009.9** After manual changes, `revalidate()` must be called — which runs ConflictDetectionService.detectFromCells() + AnalyticsService.computeConstraintViolations().

### FR-STT-010: Substitution Management

**FR-STT-010.1** The system must allow recording teacher absence via `POST /smart-timetable/substitution/absence` (teacher_id, absence_date, absence_type, start_period, end_period, reason, substitution_required).

**FR-STT-010.2** Upon absence approval, the system must auto-generate substitute recommendations per affected cell.

**FR-STT-010.3** The system must score substitute candidates via: Subject match (40 pts) + Pattern × confidence (25 pts) + Day availability (20 pts) + Workload balance (15 pts).

**FR-STT-010.4** Substitute candidates must be retrieved via `GET /smart-timetable/substitution/candidates/{cellId}/{date}`.

**FR-STT-010.5** Substitutes may be assigned manually (`POST /substitution/assign`) or automatically (`POST /substitution/auto-assign`).

**FR-STT-010.6** On assignment, `tt_timetable_cell_teacher` must get a new row with `is_substitute = 1`. The original teacher row is preserved.

**FR-STT-010.7** Pattern learning triggers only on `completeSubstitution()` — updates `tt_substitution_patterns` with a running exponential average of (teacher_id, day_of_week, subject_id, success_rate, confidence).

**FR-STT-010.8** Substitution history must be viewable per teacher via `GET /smart-timetable/substitution/history/{teacherId}`.

**FR-STT-010.9** The substitution dashboard must show today's absences, pending assignments, and today's substitutions.

### FR-STT-011: API Access for External Integration

**FR-STT-011.1** All API endpoints must be authenticated via `auth:sanctum`.

**FR-STT-011.2** API response format: `{ "success": true, "data": {...} }` for success, `{ "success": false, "message": "..." }` for errors.

**FR-STT-011.3** Required API endpoints (prefix `/api/v1/timetable`):

| Method | URI | Description |
|---|---|---|
| GET | `/{id}` | Full timetable JSON with grid grouped by day → period |
| GET | `/{id}/class/{classId}` | Class-filtered timetable cells |
| GET | `/{id}/teacher/{teacherId}` | Teacher-filtered timetable cells |
| GET | `/{id}/room/{roomId}` | Room-filtered timetable cells |
| GET | `/{id}/day/{dayOfWeek}` | Day-filtered timetable cells |
| GET | `/{id}/period/{periodOrd}` | Period-filtered timetable cells |
| GET | `/{id}/activities` | All activities for a timetable |
| GET | `/{id}/teachers` | All teachers and their schedules |
| GET | `/{id}/rooms` | All rooms and their schedules |
| GET | `/{id}/conflicts` | Active conflicts |
| GET | `/{id}/stats` | Timetable quality statistics |
| GET | `/{id}/substitutions` | Active substitutions |
| GET | `/{id}/export/json` | Full JSON export |
| GET | `/{id}/export/ical` | iCal calendar export |
| GET | `/generation-run/{runId}/status` | Generation run status |
| GET | `/latest` | Latest PUBLISHED timetable |

### FR-STT-012: Parallel Period Management

**FR-STT-012.1** The system must allow creating parallel groups (`tt_parallel_group`) representing sets of activities that must occur simultaneously (hobby, skill, optional elective classes).

**FR-STT-012.2** Activities must be added to a parallel group via `POST /smart-timetable/class-subject-group/add-activities` through `ParallelGroupController`.

**FR-STT-012.3** The ParallelPeriodConstraint (hard) must pin all activities in a group to the anchor slot: the first activity placed in a run defines the anchor `(day_of_week, period_ord)`; subsequent activities in the group are forced to that slot.

**FR-STT-012.4** If anchor placement fails for the anchor activity, the entire parallel group is retried in a different slot.

**FR-STT-012.5** Parallel groups must be viewable with full CRUD via `ParallelGroupController` and `parallel-group/index.blade.php`.

---

## 5. DATA MODEL

### 5.1 Section 0 — Configuration Tables

**`sch_academic_term`** (shown in timetable module; owned by SchoolSetup)
- Key fields: `academic_session_id`, `term_code`, `term_name`, `term_start_date`, `term_end_date`, `term_total_teaching_days`, `term_total_exam_days`, `term_week_start_day`, `term_total_periods_per_day`, `term_total_teaching_periods_per_day`, `term_min/max_resting_periods_per_day`, `is_current`
- Unique: one current term enforced by generated column `current_flag`

**`tt_config`**
- Key fields: `ordinal`, `key` (system, immutable), `key_name` (editable), `value`, `value_type` (STRING/NUMBER/BOOLEAN/DATE/TIME/DATETIME/JSON), `description`, `tenant_can_modify`, `mandatory`
- Pre-seeded with 14 configuration keys (periods_per_day, open_days_per_week, week_start_day, etc.)

**`tt_generation_strategy`**
- Key fields: `code`, `name`, `algorithm_type` (RECURSIVE/GENETIC/SIMULATED_ANNEALING/TABU_SEARCH/HYBRID), `max_recursive_depth`, `max_placement_attempts`, `tabu_size`, `cooling_rate`, `population_size`, `generations`, `activity_sorting_method`, `timeout_seconds`, `is_default`

### 5.2 Section 1 — Master Tables

**`tt_shift`**
- Key fields: `code`, `name`, `default_start_time`, `default_end_time`, `ordinal`

**`tt_day_type`**
- Key fields: `code`, `name`, `is_working_day`, `reduced_periods`, `ordinal`
- Example codes: STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY

**`tt_period_type`**
- Key fields: `code`, `name`, `color_code`, `icon`, `is_schedulable`, `counts_as_teaching`, `counts_as_workload`, `is_break`, `is_free_period`, `ordinal`, `duration_minutes`
- Example codes: THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE

**`tt_teacher_assignment_role`**
- Key fields: `code`, `name`, `is_primary_instructor`, `counts_for_workload`, `allows_overlap`, `workload_factor`, `ordinal`, `is_system`
- Example codes: PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE

**`tt_school_days`**
- Key fields: `code`, `name`, `short_name`, `day_of_week`, `ordinal`, `is_school_day`

**`tt_working_day`**
- Key fields: `academic_session_id`, `date`, `day_type1_id` through `day_type4_id` (multiple day types per date), `is_school_day`, `remarks`
- Unique: one record per calendar date

**`tt_class_working_day_jnt`**
- Key fields: `academic_session_id`, `date`, `class_id`, `section_id`, `working_day_id`, `is_exam_day`, `is_ptm_day`, `is_half_day`, `is_holiday`, `is_study_day`

**`tt_period_set`**
- Key fields: `code`, `name`, `total_periods`, `teaching_periods`, `exam_periods`, `free_periods`, `assembly_periods`, `short_break_periods`, `lunch_break_periods`, `day_start_time`, `day_end_time`, `is_default`

**`tt_period_set_period_jnt`**
- Key fields: `period_set_id`, `period_ord`, `code`, `short_name`, `period_type_id`, `start_time`, `end_time`
- `duration_minutes`: STORED generated column from `TIMESTAMPDIFF(MINUTE, start_time, end_time)`

**`tt_timetable_type`**
- Key fields: `code`, `name`, `shift_id`, `effective_from_date`, `effective_to_date`, `school_start_time`, `school_end_time`, `has_exam`, `has_teaching`, `ordinal`, `is_default`

**`tt_class_timetable_type_jnt`**
- Key fields: `academic_term_id`, `timetable_type_id`, `class_id`, `section_id`, `period_set_id`, `applies_to_all_sections`, `has_teaching`, `has_exam`, `weekly_exam_period_count`, `weekly_teaching_period_count`, `weekly_free_period_count`, `effective_from`, `effective_to`

### 5.3 Section 2 — Timetable Requirement Tables

**`tt_slot_requirement`**
- Key fields: `academic_term_id`, `timetable_type_id`, `class_timetable_type_id`, `class_id`, `section_id`, `class_house_room_id`, `weekly_total_slots`, `weekly_teaching_slots`, `weekly_exam_slots`, `weekly_free_slots`, `activity_id`

**`tt_class_requirement_groups`**
- Key fields: `code`, `name`, `class_group_id`, `class_id`, `section_id`, `subject_id`, `study_format_id`, `subject_type_id`, `subject_study_format_id`, `class_house_room_id`, `student_count`, `eligible_teacher_count`

**`tt_class_requirement_subgroups`**
- Key fields: same as groups plus `is_shared_across_sections`, `is_shared_across_classes`

**`tt_requirement_consolidation`**
- Key fields: `academic_term_id`, `timetable_type_id`, `class_requirement_group_id`, `class_requirement_subgroup_id` (one must be null — CHECK constraint), `class_id`, `section_id`, `subject_id`, `study_format_id`, `subject_type_id`, `subject_study_format_id`, `class_house_room_id`, `student_count`, `eligible_teacher_count`, `is_compulsory`, `required_weekly_periods`, `min/max_periods_required_per_week`, `min/max_periods_required_per_day`, `min_gap_between_periods`, `required_consecutive_periods`, `allow_consecutive_periods`, `max_consecutive_periods`, `class_priority_score`, `preferred_periods_json`, `avoid_periods_json`, `spread_evenly`, `is_shared_across_sections`, `is_shared_across_classes`, `compulsory_specific_room_type`, `required_room_type_id`, `required_room_id`

### 5.4 Section 3 — Constraint Engine Tables

**`tt_constraint_category_scope`**
- `type` ENUM('CATEGORY','SCOPE'), `code`, `name`, `description`
- Categories: PERIOD, ROOM, TEACHER, CLASS, CLASS+SECTION, SUBJECT, STUDY_FORMAT, SUBJECT_STUDY_FORMAT, SUBJECT_TYPE, ACTIVITY
- Scopes: GLOBAL, TEACHER, ROOM, ACTIVITY, CLASS, CLASS+SECTION, CLASS+SUBJECT+STUDY_FORMAT, SUBJECT+STUDY_FORMAT, SUBJECT, CLASS_GROUP, CLASS_SUBGROUP

**`tt_constraint_type`**
- Key fields: `code`, `name`, `description`, `category_id`, `applicable_to` (ALL/SPECIFIC), `scope_id`, `target_id_required`, `default_weight`, `is_hard_constraint`, `param_schema` (JSON), `is_system`

**`tt_constraint`**
- Key fields: `constraint_type_id`, `name`, `description`, `academic_term_id`, `target_type`, `target_id`, `is_hard`, `weight`, `params_json`, `effective_from`, `effective_to`, `apply_for_all_days`, `applicable_days` (JSON), `impact_score`, `created_by`

**`tt_teacher_unavailable`**
- Key fields: `teacher_id`, `constraint_id`, `unavailable_for_all_days`, `day_of_week`, `unavailable_for_all_periods`, `period_no`, `is_recurring`, `recurring_frequency`, `start_date`, `end_date`, `reason`

**`tt_room_unavailable`**
- Key fields: `room_id`, `constraint_id`, `day_of_week`, `period_ord`, `start_date`, `end_date`, `reason`, `is_recurring`

### 5.5 Section 4 — Resource Availability Tables

**`tt_teacher_availability`**
- Key fields: `requirement_consolidation_id`, `class_id`, `section_id`, `subject_study_format_id`, `teacher_profile_id`, `required_weekly_periods`, `is_full_time`, `preferred_shift`, `capable_handling_multiple_classes`, `can_be_used_for_substitution`, `certified_for_lab`, `max/min_available_periods_weekly`, `max/min_allocated_periods_weekly`, `can_be_split_across_sections`, `proficiency_percentage`, `teaching_experience_months`, `is_primary_subject`, `competency_level`, `priority_order`, `priority_weight`, `scarcity_index`, `is_hard_constraint`, `allocation_strictness`
- Generated columns: `available_for_full_timetable_duration` (STORED), `no_of_days_not_available` (STORED)

**`tt_teacher_availability_detail`**
- Key fields: `teacher_availability_id`, `teacher_profile_id`, `day_number` (1–7), `day_name`, `period_number` (1–8), `can_be_assigned`, `availability_for_period` (Available/Unavailable/Assigned/Free Period), `assigned_class_id`, `assigned_section_id`, `assigned_subject_study_format_id`, `teacher_available_from_date`, `activity_id`

**`tt_room_availability`**
- Key fields: `room_id`, `rooms_type_id`, `total_rooms_in_category`, `can_be_assigned`, `overall_availability_status`, `available_for_full_timetable_duration`, `is_class_house_room`, `house_room_class_id`, `house_room_section_id`, `capacity`, `max_limit`, `can_be_assigned_for_lecture/practical/exam/activity/sports`, `timetable_start_time`, `timetable_end_time`

**`tt_room_availability_detail`**
- Key fields: `room_availability_id`, `room_id`, `room_type_id`, `day_number`, `day_name`, `period_number`, `availability_for_period` (Available/Unavailable/Assigned), `assigned_class_id`, `assigned_section_id`, `assigned_subject_study_format_id`, `room_available_from_date`, `activity_id`

### 5.6 Section 5 — Activity Preparation Tables

**`tt_priority_config`**
- Key fields: `requirement_consolidation_id`, `tot_students`, `teacher_scarcity_index`, `weekly_load_ratio`, `average_teacher_availability_ratio`, `rigidity_score`, `resource_scarcity`, `subject_difficulty_index`

**`tt_activity`** (central scheduling entity)
- Key fields: `code`, `name`, `academic_term_id`, `timetable_type_id`, `activity_group_id`, `have_sub_activity`, `class_id`, `section_id`, `subject_id`, `study_format_id`, `subject_type_id`, `subject_study_format_id`, `required_weekly_periods`, `min/max_periods_per_week`, `min/max_per_day`, `min_gap_periods`, `allow_consecutive`, `max_consecutive`, `preferred_periods_json`, `avoid_periods_json`, `spread_evenly`, `eligible_teacher_count`, `min/max_teacher_availability_score`, `duration_periods`, `weekly_periods`
- Generated: `total_periods` = `duration_periods` × `weekly_periods` (STORED)
- Scoring: `difficulty_score`, `difficulty_score_calculated`, `teacher_availability_score`, `room_availability_score`, `constraint_count`, `preferred_time_slots_json`, `avoid_time_slots_json`
- Status: ENUM('DRAFT','ACTIVE','LOCKED','ARCHIVED')
- Room: `compulsory_specific_room_type`, `required_room_type_id`, `required_room_id`, `requires_room`, `preferred_room_type_id`, `preferred_room_ids`

**`tt_sub_activity`**
- Key fields: `parent_activity_id`, `class_requirement_subgroups` (FK to tt_class_requirement_subgroups.id), `ordinal`, `class_id`, `section_id`, `duration_periods`, `same_day_as_parent`, `consecutive_with_previous`

**`tt_activity_priority`**
- Key fields: `activity_id`, `priority_score` (0.00–100.00), `priority_reason`

**`tt_activity_teacher`** (junction)
- Key fields: `activity_id`, `teacher_id`, `assignment_role_id`, `is_required`, `ordinal`

### 5.7 Section 6 — Timetable Core Tables

**`tt_timetable`** (root document)
- Key fields: `code`, `name`, `description`, `academic_session_id`, `academic_term_id`, `timetable_type_id`, `period_set_id`, `effective_from`, `effective_to`, `generation_method` (MANUAL/SEMI_AUTO/FULL_AUTO), `version`, `parent_timetable_id`, `status` (DRAFT/GENERATING/GENERATED/PUBLISHED/ARCHIVED), `published_at`, `published_by`, `constraint_violations`, `soft_score`, `generation_strategy_id`, `optimization_cycles`, `last_optimized_at`, `quality_score`, `teacher_satisfaction_score`, `room_utilization_score`, `stats_json`, `created_by`

**`tt_conflict_detection`**
- Key fields: `timetable_id`, `detection_type` (REAL_TIME/BATCH/VALIDATION/GENERATION), `detected_at`, `conflict_count`, `hard_conflicts`, `soft_conflicts`, `conflicts_json`, `resolution_suggestions_json`, `resolved_at`

**`tt_resource_booking`**
- Key fields: `resource_type` (ROOM/LAB/TEACHER/EQUIPMENT/SPORTS/SPECIAL), `resource_id`, `booking_date`, `day_of_week`, `period_ord`, `start_time`, `end_time`, `booked_for_type` (ACTIVITY/EXAM/EVENT/MAINTENANCE), `booked_for_id`, `purpose`, `supervisor_id`, `status` (BOOKED/IN_USE/COMPLETED/CANCELLED)

**`tt_generation_run`**
- Key fields: `timetable_id`, `run_number`, `started_at`, `finished_at`, `status` (QUEUED/RUNNING/COMPLETED/FAILED/CANCELLED), `strategy_id`, `algorithm_version`, `max_recursion_depth`, `max_placement_attempts`, `retry_count`, `params_json`, `activities_total`, `activities_placed`, `activities_failed`, `hard_violations`, `soft_violations`, `soft_score`, `stats_json`, `error_message`, `triggered_by`
- Unique: `(timetable_id, run_number)`

**`tt_constraint_violation`**
- Key fields: `timetable_id`, `constraint_id`, `violation_type` (HARD/SOFT), `violation_count`, `violation_details` (JSON)

**`tt_timetable_cell`** (grid cells)
- Key fields: `timetable_id`, `generation_run_id`, `day_of_week`, `period_ord`, `cell_date`, `class_group_id`, `class_subgroup_id` (one must be null), `activity_id`, `sub_activity_id`, `room_id`, `source` (AUTO/MANUAL/SWAP/LOCK), `is_locked`, `locked_by`, `locked_at`, `has_conflict`, `conflict_details_json`
- Unique: `(timetable_id, day_of_week, period_ord, class_group_id, class_subgroup_id)`

**`tt_timetable_cell_teacher`** (many teachers per cell)
- Key fields: `cell_id`, `teacher_id`, `assignment_role_id`, `is_substitute`
- Unique: `(cell_id, teacher_id)`

### 5.8 Section 8 — Analytics Tables

**`tt_teacher_workload`**
- Key fields: `teacher_id`, `academic_session_id`, `timetable_id`, `weekly_periods_assigned`, `weekly_periods_max`, `weekly_periods_min`, `daily_distribution_json`, `subjects_assigned_json`, `classes_assigned_json`, `utilization_percent`, `gap_periods_total`, `consecutive_max`, `last_calculated_at`
- Unique: `(teacher_id, academic_session_id, timetable_id)`

### 5.9 Section 9 — Audit and History

**`tt_change_log`**
- Key fields: `timetable_id`, `cell_id`, `change_type` (CREATE/UPDATE/DELETE/LOCK/UNLOCK/SWAP/SUBSTITUTE), `change_date`, `old_values_json`, `new_values_json`, `reason`, `changed_by`

### 5.10 Section 10 — Substitution Tables

**`tt_teacher_absence`**
- Key fields: `teacher_id`, `absence_date`, `absence_type` (LEAVE/SICK/TRAINING/OFFICIAL_DUTY/OTHER), `start_period`, `end_period`, `reason`, `status` (PENDING/APPROVED/REJECTED/CANCELLED), `approved_by`, `approved_at`, `substitution_required`, `substitution_completed`, `created_by`

**`tt_substitution_log`**
- Key fields: `teacher_absence_id`, `cell_id`, `substitution_date`, `absent_teacher_id`, `substitute_teacher_id`, `assignment_method` (AUTO/MANUAL/SWAP), `reason`, `status` (ASSIGNED/COMPLETED/CANCELLED), `notified_at`, `accepted_at`, `completed_at`, `feedback`, `assigned_by`

### 5.11 Models in SmartTimetable Module (62 total)

Core: `Activity`, `SubActivity`, `Timetable`, `TimetableCell`, `TimetableCellTeacher`, `GenerationRun`, `ResourceBooking`, `ConflictDetection`, `ConstraintViolation`

Constraint system: `Constraint`, `ConstraintType`, `ConstraintCategory`, `ConstraintScope`, `ConstraintCategoryScope`, `ConstraintTargetType`, `ConstraintGroup`, `ConstraintGroupMember`, `ConstraintTemplate`, `ConstraintViolation`

Availability: `TeacherAvailablity` (sic), `TeacherUnavailable`, `RoomAvailability`, `RoomUnavailable`

Scheduling: `SchoolDay`, `PeriodSetPeriod`, `ParallelGroup`, `ParallelGroupActivity`, `SubActivity`, `TtGenerationStrategy`

Analytics: `TeacherWorkload`, `RoomUtilization`, `AnalyticsDailySnapshot`

Substitution: `TeacherAbsences`, `SubstitutionLog`, `SubstitutionPattern`, `SubstitutionRecommendation`

Refinement: `ChangeLog`, `ImpactAnalysisSession`, `ImpactAnalysisDetail`, `ConflictResolutionSession`, `ConflictResolutionOption`, `BatchOperation`, `BatchOperationItem`, `RevalidationSchedule`, `RevalidationTrigger`, `EscalationLog`, `EscalationRule`

Optimization: `OptimizationRun`, `OptimizationIteration`, `OptimizationMove`

ML/AI (planned): `MlModel`, `TrainingData`, `FeatureImportance`, `PredictionLog`, `PatternResult`

Approval: `ApprovalWorkflow`, `ApprovalLevel`, `ApprovalRequest`, `ApprovalDecision`, `ApprovalNotification`

Other: `PriorityConfig`, `WhatIfScenario`, `VersionComparison`, `VersionComparisonDetail`, `GenerationQueue`

---

## 6. CONSTRAINT CLASSES

### 6.1 Hard Constraints (22 classes)

| Class | Scope | Description |
|---|---|---|
| `TeacherConflictConstraint` | TEACHER | No teacher assigned to two activities at same time |
| `NotOverlappingConstraint` | CLASS | No student group double-booked |
| `RoomExclusiveUseConstraint` | ROOM | No room double-booked |
| `TeacherUnavailablePeriodsConstraint` | TEACHER | Enforces tt_teacher_unavailable records |
| `TeacherRoomUnavailableConstraint` | TEACHER+ROOM | Combined unavailability |
| `TeacherMaxDailyConstraint` | TEACHER | Max teaching periods per day |
| `TeacherMaxWeeklyConstraint` | TEACHER | Max teaching periods per week |
| `ClassMaxPerDayConstraint` | CLASS | Max periods for a class per day |
| `ClassWeeklyPeriodsConstraint` | CLASS | Exactly required_weekly_periods placed |
| `ClassConsecutiveRequiredConstraint` | CLASS | Enforce min consecutive periods |
| `ActivityFixedToDayConstraint` | ACTIVITY | Pin activity to specific day |
| `ActivityFixedToPeriodRangeConstraint` | ACTIVITY | Pin to period range |
| `ActivityExcludedFromDayConstraint` | ACTIVITY | Exclude from specific day |
| `OccupyExactSlotsConstraint` | ACTIVITY | Exactly N slots required |
| `SameStartingTimeConstraint` | ACTIVITY | Two activities must start simultaneously |
| `ConsecutiveActivitiesConstraint` | ACTIVITY | Two activities must be consecutive |
| `ParallelPeriodConstraint` | GROUP | Parallel group anchor enforcement |
| `GlobalFixedPeriodConstraint` | GLOBAL | School-wide period reservation |
| `GlobalHolidayConstraint` | GLOBAL | No activities on holidays |
| `ExamOnlyPeriodsConstraint` | GLOBAL | Exam periods reserved for exams |
| `NoTeachingAfterExamConstraint` | GLOBAL | No teaching after exam on same day |
| `RoomMaxUsagePerDayConstraint` | ROOM | Room usage cap per day |

### 6.2 Soft Constraints (63 classes, grouped)

**Teacher-scope (24):** TeacherDailyStudyFormatConstraint, TeacherFreePeriodEachHalfConstraint, TeacherGapsInSlotRangeConstraint, TeacherHomeRoomConstraint, TeacherMaxBuildingChangesPerDayConstraint, TeacherMaxConsecutiveDBConstraint, TeacherMaxConsecutiveStudyFormatConstraint, TeacherMaxDaysInIntervalConstraint, TeacherMaxGapsPerDayConstraint, TeacherMaxGapsPerWeekConstraint, TeacherMaxHoursInIntervalConstraint, TeacherMaxRoomChangesPerDayConstraint, TeacherMaxRoomChangesPerWeekConstraint, TeacherMaxSpanPerDayConstraint, TeacherMaxStudyFormatsConstraint, TeacherMinDailyConstraint, TeacherMinGapBetweenRoomChangesConstraint, TeacherMinRestingHoursConstraint, TeacherMutuallyExclusiveSlotsConstraint, TeacherNoConsecutiveDaysConstraint, TeacherPreferredFreeDayConstraint, TeacherStudyFormatGapConstraint, GlobalMaxTeachingDaysConstraint, PreferredSlotSelectionConstraint

**Class-scope (14):** ClassMajorSubjectsDailyConstraint, ClassMaxConsecutiveStudyFormatConstraint, ClassMaxContinuousConstraint, ClassMaxDaysInIntervalConstraint, ClassMaxGapsPerWeekConstraint, ClassMaxMinorSubjectsConstraint, ClassMaxRoomChangesPerDayConstraint, ClassMaxSpanConstraint, ClassMaxStudyFormatHoursConstraint, ClassMinDailyHoursConstraint, ClassMinGapConstraint, ClassMinRestingHoursConstraint, ClassMinStudyFormatHoursConstraint, ClassStudyFormatGapConstraint, ClassNotFirstPeriodConstraint, ClassNotLastPeriodConstraint, ClassTeacherFirstPeriodConstraint, EndStudentsDayConstraint

**Room-scope (5):** MaxDifferentRoomsConstraint, PreferSameRoomConstraint, RoomMaxStudyFormatsConstraint, SameRoomIfConsecutiveConstraint, StudyFormatPreferredRoomConstraint, SubjectPreferredRoomConstraint, SubjectStudyFormatPreferredRoomConstraint

**Inter-activity (7):** MaxDaysBetweenConstraint, MinDaysBetweenConstraint, MinGapsBetweenSetConstraint, NonConcurrentMinorSubjectsConstraint, OccupyMaxSlotsConstraint, OccupyMinSlotsConstraint, OrderedIfSameDayConstraint, SameDayConstraint, SameHourConstraint

**Global (4):** GlobalBalancedDistributionConstraint, GlobalPreferMorningConstraint, GenericSoftConstraint

---

## 7. UI/UX REQUIREMENTS

### 7.1 Navigation Structure (Menu)

All screens are under the `Smart Timetable` module navigation, organized into 10 sub-menu groups:

1. **Pre-Requisites Setup** — buildings, room types, rooms, teacher profiles, classes/sections, subjects/study formats, class groups
2. **Timetable Configuration** — TT config, academic terms, generation strategy
3. **Timetable Masters** — shift, day type, period type, teacher roles, school days, working days, class working days, period sets, timetable types, class timetable
4. **Timetable Requirement** — slot requirement, class requirement groups, subgroups, requirement consolidation
5. **Constraint Engine** — constraint categories/scopes, constraint types, constraint instances, teacher unavailability, room unavailability
6. **Resource Availability** — teacher availability, availability logs, room availability
7. **Timetable Preparation** — activities, priority config, teacher mapping
8. **View and Refinement** — generation status, timetable preview, manual refinement grid
9. **Reports and Logs** — analytics dashboard, workload, utilization, violations, distribution, class/teacher/room reports
10. **Substitute Management** — absence recording, candidate selection, substitution dashboard

### 7.2 Key Screen Behaviors

- **Constraint forms** are dynamically rendered from `param_schema` JSON per constraint type
- **Activity generation** shows a batch progress bar with polling
- **Generation status** auto-polls every 3 seconds
- **Refinement grid** uses two-click cell selection with modal confirmation
- **Impact analysis** is a pre-swap JSON fetch returning conflict/score details
- **Validation screen** uses tabbed layout (Statistics, Teachers, Rooms, Activities, Constraints, Alerts)

---

## 8. INTEGRATION REQUIREMENTS

### 8.1 Internal Dependencies

| Module | How Used |
|---|---|
| SchoolSetup | sch_classes, sch_sections, sch_rooms, sch_teachers, sch_subjects, sch_study_formats, sch_buildings — all read-only in STT |
| StudentProfile | std_students — for student count in requirement groups |
| SyllabusModule | Subjects and study formats for activity definition |
| Notification | Substitution notifications (SMS/Email/In-app) |
| Audit | sys_activity_logs for all state-changing operations |

### 8.2 External Integrations

- **Laravel Queue** — GenerateTimetableJob dispatched via `dispatch()`, runs in background worker
- **Sanctum** — API authentication for REST endpoints
- **iCal export** — TimetableApiController exports iCal format for calendar apps

---

## 9. WORKFLOW DIAGRAMS

### 9.1 Timetable Generation Pipeline

```
Pre-Requisite Setup
  → Requirement Consolidation
  → Activity Generation
  → Teacher Availability Grid
  → Room Availability Grid
  → Constraint Configuration
  → Pre-Generation Validation (ValidationService)
    ├── FAIL: Show validation errors → Stop
    └── PASS
        → Activity Scoring (ActivityScoreService)
        → Room Allocation Pass
        → Sub-Activity Generation
        → Dispatch GenerateTimetableJob (async)
            → FET Solver (CSP backtracking, 50K iter, 25s)
            → Tabu Search / SA Optimizer (optional)
            → Solution Evaluation
            → Atomic DB Storage (TimetableStorageService)
            → Resource Booking
            → Conflict Detection
            → Update tt_generation_run status
        → Poll generation-status (3s interval)
        → COMPLETED: Timetable → GENERATED status
        → FAILED: Timetable → DRAFT; show error
```

### 9.2 Approval and Publishing Workflow

```
DRAFT
  → [Dispatch Job] → GENERATING
  → [Job Complete] → GENERATED
    → [Admin Preview + Approve] → APPROVED
      → [Admin Publish] → PUBLISHED
        → [Superseded by new version] → ARCHIVED
  → [Job Failed / Admin Revert] → DRAFT
```

### 9.3 Substitution Workflow

```
Teacher Absence Report (POST /substitution/absence)
  → Create tt_teacher_absence (PENDING)
  → [Admin/Coordinator Approve]
    → tt_teacher_absence.status = APPROVED
    → Auto-generate substitute recommendations per affected cell
    → Score candidates (SubstitutionService.scoreCandidate())
  → Display ranked candidates to coordinator
  → [Assign substitute] (manual or auto)
    → Add tt_timetable_cell_teacher row (is_substitute=1)
    → Create tt_substitution_log (ASSIGNED)
    → Send notification to substitute teacher
  → [Substitute confirms / Class occurs]
    → tt_substitution_log.status = COMPLETED
    → completeSubstitution()
      → Update tt_substitution_patterns (running average)
```

---

## 10. SECURITY AND AUTHORIZATION

### 10.1 Permission Gates

All controller methods check `Gate::authorize('smart-timetable.*')` where `*` is the action (viewAny, view, create, update, delete, etc.).

### 10.2 Role Permissions Required

| Action | Minimum Role |
|---|---|
| View timetable | Teacher (own), Staff, Admin |
| Generate timetable | Timetable Coordinator, Admin |
| Approve timetable | Principal, Admin |
| Publish timetable | Admin |
| Add constraints | Timetable Coordinator, Admin |
| Record absence | Teacher, Coordinator, Admin |
| Assign substitute | Coordinator, Admin |
| API access | Sanctum token (any authenticated user) |

### 10.3 Data Isolation

All `tt_*` tables reside in the `tenant_{uuid}` database, enforced by stancl/tenancy v3.9 at application boot. No cross-tenant data access is possible.

---

## 11. DEPENDENCIES AND CONSTRAINTS

### 11.1 Technical Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| PHP | 8.2+ | Runtime |
| Laravel | 12 | Framework |
| nwidart/laravel-modules | v12 | Module system |
| stancl/tenancy | v3.9 | Multi-tenancy |
| MySQL | 8.x InnoDB | Supports generated columns, JSON, CHECK constraints |
| Laravel Queue | — | Async generation job |
| Sanctum | — | API token auth |

### 11.2 Known Bugs

| Bug ID | Description | Impact |
|---|---|---|
| BUG-TT-001 | SmartTimetableController god-class (3,245 lines) | Maintainability; no functional impact |
| BUG-TT-002 | FETConstraintBridge context broken | Constraints NOT wired to FET solver during generation |
| BUG-TT-003 through BUG-TT-012 | Various (see context doc) | Varying severity |

---

## 12. ERROR HANDLING

### 12.1 Generation Errors

- `HardConstraintViolationException` — caught in FETSolver; increments hard_violations; if unresolvable → FAILED
- Queue job timeout (600s) — job marked FAILED; `error_message` = "Generation timeout exceeded"
- DB transaction failure during storage — full rollback; job FAILED

### 12.2 Validation Errors

- Pre-generation validation failures are returned as structured JSON with category (activities, teachers, rooms, constraints) and detailed messages

### 12.3 API Errors

- 404: `{ "success": false, "message": "Timetable not found" }`
- 422: `{ "success": false, "message": "...", "errors": {...} }`
- 500: `{ "success": false, "message": "Internal server error" }`

---

## 13. PERFORMANCE REQUIREMENTS

| Metric | Requirement |
|---|---|
| FET Solver max runtime | 25 seconds (configurable via strategy.timeout_seconds) |
| Generation job max runtime | 600 seconds (Laravel job $timeout) |
| Generation job tries | 1 ($tries = 1; no retry on failure) |
| Analytics computation | < 5 seconds for 50-teacher school |
| API response time | < 200ms for single timetable GET |
| Swap impact analysis | < 500ms |
| Conflict detection (batch) | < 2 seconds |

---

## 14. TESTING REQUIREMENTS

### 14.1 Existing Tests

| File | Type | Tests |
|---|---|---|
| `tests/Feature/SmartTimetable/ActivityControllerTest.php` | Feature (Pest) | Activity CRUD via HTTP |
| `tests/Unit/SmartTimetable/ActivityModelTest.php` | Unit | Model relationships and computed fields |
| `tests/Unit/SmartTimetable/ConstraintClassesTest.php` | Unit | Individual constraint evaluate() methods |
| `tests/Unit/SmartTimetable/ConstraintEvaluatorTest.php` | Unit | ConstraintEvaluator with mock activities |
| `tests/Unit/SmartTimetable/FETSolverScoringTest.php` | Unit | Solver activity scoring |
| `tests/Unit/SmartTimetable/ParallelGroupBacktrackTest.php` | Unit | Parallel group anchor backtracking |
| `tests/Unit/SmartTimetable/TimetableSolutionIsPlacedTest.php` | Unit | TimetableSolution placement flags |

### 14.2 Test Patterns

- Feature tests: Pest syntax, `Tests\TestCase` with `RefreshDatabase`
- Unit tests: PHPUnit syntax (no Laravel app boot for most)
- In-memory model fixtures: `Activity::make([...])` + `setRelation('teachers', collect([...]))`

---

## 15. OPEN ISSUES AND FUTURE ENHANCEMENTS

### 15.1 Open Issues (Must Fix)

1. **BUG-TT-002:** FETConstraintBridge broken — constraint PHP classes not connected to FET solver. Must be fixed before generation can enforce all configured constraints.
2. **God Controller:** SmartTimetableController (~3,245 lines) must be refactored into sub-controllers (FoundationController, RequirementController, GenerationController, etc.).
3. **Approval UI:** Approval workflow exists at model level but approval/reject UI screens are incomplete.
4. **Publish UI:** Publish button action and confirmation modal not yet wired.

### 15.2 Future Enhancements

1. **ML-based constraint suggestion** — `MlModel`, `TrainingData`, `FeatureImportance`, `PredictionLog` models exist as placeholders for future ML pipeline
2. **What-If scenarios** — `WhatIfScenario` model exists; UI not built
3. **Version comparison** — `VersionComparison`, `VersionComparisonDetail` models exist; diff view not built
4. **PDF timetable export** — planned via DomPDF (used in HPC module)
5. **ICS calendar export** — `TimetableApiController.exportIcal()` scaffolded; full implementation pending
6. **Behavioral/attendance feed** — substitution patterns can be enriched with actual attendance data once behavioral module is complete

---

*Document generated from code inspection on 2026-03-25.*
*Source files: `Modules/SmartTimetable/`, `routes/tenant.php`, `routes/api.php`, DDL `tt_timetable_ddl_v7.6.sql`, RBS lines 2360–2473.*
