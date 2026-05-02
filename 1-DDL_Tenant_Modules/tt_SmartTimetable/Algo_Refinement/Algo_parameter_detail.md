# SmartTimetable — Algorithm Refinement: Parameter Catalog & Priority Sequence

> **Author:** Claude (Enterprise Architect role)
> **Date:** 2026-05-01
> **Scope:** Definitive catalog of every parameter that can be used to prioritise (a) Teacher+Period placement and (b) Room placement onto an Activity = (Class + Section + Subject + Study_Format).
> **Companion docs:**
> - `tt_brain/SmartTimetable_Deep_Understanding_v1.md` — full module deep-dive
> - `Z-Timetable/Algo_Detail/Timetable_Process_Detail_v2.md` — current pipeline reference
> - DDL: `tt_timetable_ddl_v7.8.sql`
>
> **How to read this:** §1 lists every parameter. §2 gives formulas (User-provided values flagged). §3 proposes the optimal priority sequence (current vs recommended). §4 maps the sequence onto the existing solver phases. §5 closes with concrete refinement actions.

---

## Reading legend

- **`USER_PROVIDED`** — value set by school staff via the UI (a stored field, not computed).
- **`COMPUTED`** — derived by application code from other DB rows.
- **`SOLVER_DERIVED`** — computed transiently inside the solver loop from running state (occupancy grids, day counts).
- **`PRIME_SEEDED`** — set by Prime/SaaS admin, not by the school.
- **`HARD`** — failure rejects placement.
- **`SOFT`** — failure adjusts score, not rejection.
- Source notation: **table.column** (DDL v7.8 line refs in parentheses where useful).

---

## Section 1A — Parameters for Teacher + Period placement on an Activity

> An "Activity" in v7.8 = one row in `tt_activity` keyed by (academic_term × timetable_type × class+{section} × subject+study_format). Each Activity is exploded into N instances by the solver where N = `required_weekly_periods`. Each instance is placed onto a **(day_id, period_ord, teacher_id)** triple.
>
> Parameters that can drive that placement decision come from **6 groups**:

### Group A — Activity-intrinsic parameters (from `tt_activity`)

| # | Parameter | Type | Source (table.column) | Used today? | Purpose |
|---|---|---|---|---|---|
| A1 | `is_compulsory` | USER_PROVIDED bool | tt_activity.is_compulsory | Yes (difficulty +20) | Mandatory subjects placed first |
| A2 | `priority` | USER_PROVIDED 0–100 | tt_activity.priority | Yes (× 20 in class-teacher rule) | Manual school priority |
| A3 | `difficulty_score` | USER_PROVIDED 0–100 | tt_activity.difficulty_score | Yes (fallback) | Scheduling hardness override |
| A4 | `difficulty_score_calculated` | COMPUTED 0–100 | tt_activity.difficulty_score_calculated | Yes (primary) | Auto-difficulty (see §2) |
| A5 | `required_weekly_periods` | USER_PROVIDED int | tt_activity.required_weekly_periods | Yes (× 500 in difficulty) | Higher load → harder |
| A6 | `min_periods_per_week` | USER_PROVIDED int | tt_activity.min_periods_per_week | Partial | Floor for partial coverage |
| A7 | `max_periods_per_week` | USER_PROVIDED int | tt_activity.max_periods_per_week | Partial | Ceiling |
| A8 | `min_per_day` | USER_PROVIDED int | tt_activity.min_per_day | Yes (+15 if not met) | Daily floor |
| A9 | `max_per_day` | USER_PROVIDED int | tt_activity.max_per_day | Yes (hard cap) | Daily ceiling |
| A10 | `min_gap_periods` | USER_PROVIDED int | tt_activity.min_gap_periods | Partial | Min gap between same-activity periods |
| A11 | `allow_consecutive` | USER_PROVIDED bool | tt_activity.allow_consecutive | Yes (built-in check) | Back-to-back permitted |
| A12 | `max_consecutive` | USER_PROVIDED int | tt_activity.max_consecutive | Partial | Cap on consecutive same activity |
| A13 | `duration_periods` | USER_PROVIDED int | tt_activity.duration_periods | Yes (× 3 in difficulty) | Block size (1 normal, 2 lab) |
| A14 | `weekly_periods` | USER_PROVIDED int | tt_activity.weekly_periods | Yes | Repetitions/week |
| A15 | `total_periods` | COMPUTED (generated col) | tt_activity.total_periods | Yes | duration × weekly |
| A16 | `preferred_periods_json` | USER_PROVIDED int[] | tt_activity.preferred_periods_json | Yes (+20) | Per-day-pos preference |
| A17 | `avoid_periods_json` | USER_PROVIDED int[] | tt_activity.avoid_periods_json | Yes (−30) | Per-day-pos avoidance |
| A18 | `preferred_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.preferred_time_slots_json | Yes (+40) | Exact (day,period) preference |
| A19 | `avoid_time_slots_json` | USER_PROVIDED [{day,period_ord},…] | tt_activity.avoid_time_slots_json | Yes (−50) | Exact avoidance |
| A20 | `spread_evenly` | USER_PROVIDED bool | tt_activity.spread_evenly | Yes (+10 / −15) | Day-balance preference |
| A21 | `split_allowed` | USER_PROVIDED bool | tt_activity.split_allowed | Yes (−100 if violated) | Multi-day split permitted |
| A22 | `subject_type_id` (MAJOR/MINOR/OPT) | USER_PROVIDED FK | tt_activity.subject_type_id → sch_subject_types | Yes (constraints C1.16, C1.17) | Major must appear daily; minor caps |
| A23 | `study_format_id` | USER_PROVIDED FK | tt_activity.study_format_id → sch_study_formats | Yes (~12 study-format constraints) | LECTURE/LAB/TUTORIAL semantics |
| A24 | `eligible_teacher_count` | COMPUTED int | tt_activity.eligible_teacher_count | Yes (drives teacher_availability_score) | Inverse → scarcity |
| A25 | `min_teacher_availability_score` | COMPUTED 0–100 | tt_activity.min_teacher_availability_score | Yes | Floor of teacher pool % |
| A26 | `max_teacher_availability_score` | COMPUTED 0–100 | tt_activity.max_teacher_availability_score | Yes | Ceil of teacher pool % |
| A27 | `teacher_availability_score` | COMPUTED 0–100 | tt_activity.teacher_availability_score | Yes (in difficulty) | % of teachers actually available |
| A28 | `constraint_count` | COMPUTED int | tt_activity.constraint_count | Yes | Number of constraints touching this activity |
| A29 | `is_class_teacher_activity` | USER_PROVIDED bool | (custom field; verify in DDL — drift Q-13) | Yes (+1000) | First-period bonus |
| A30 | `status` | USER_PROVIDED enum | tt_activity.status (DRAFT/ACTIVE/LOCKED/ARCHIVED) | Yes (filter ACTIVE only) | Lifecycle gate |
| A31 | `activity_group_id` | USER_PROVIDED FK | tt_activity.activity_group_id | Yes | Parent class-group mapping |
| A32 | `is_in_parallel_group` | COMPUTED bool | tt_parallel_group_activity (drift D-org-1) | Yes (+20000 difficulty) | Forces solver to place anchor first |
| A33 | `is_anchor_in_group` | USER_PROVIDED bool | tt_parallel_group_activity.is_anchor | Yes (+5000) | Anchor placement leads siblings |

### Group B — Teacher-intrinsic parameters (from `tt_teacher_availability`, `sch_teacher_profile`, `sch_teacher_capabilities`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| B1 | `is_full_time` | USER_PROVIDED bool | sch_teacher_profile.is_full_time → tt_teacher_availability.is_full_time | Partial | Full-time prefer over part-time |
| B2 | `preferred_shift` | USER_PROVIDED FK | tt_teacher_availability.preferred_shift | No (potential) | Shift-aware ranking |
| B3 | `capable_handling_multiple_classes` | USER_PROVIDED bool | tt_teacher_availability.capable_handling_multiple_classes | No (potential) | Allow split assignments |
| B4 | `can_be_used_for_substitution` | USER_PROVIDED bool | tt_teacher_availability.can_be_used_for_substitution | Yes (substitution only) | Sub eligibility |
| B5 | `certified_for_lab` | USER_PROVIDED bool | tt_teacher_availability.certified_for_lab | Partial | Lab certification gate |
| B6 | `max_available_periods_weekly` | USER_PROVIDED int | tt_teacher_availability.max_available_periods_weekly | **Yes — F2 hard cap** | Weekly ceiling (→ teacher_weekly_caps map) |
| B7 | `min_available_periods_weekly` | USER_PROVIDED int | tt_teacher_availability.min_available_periods_weekly | Partial | Weekly floor (under-utilization warning) |
| B8 | `max_allocated_periods_weekly` | USER_PROVIDED int | tt_teacher_availability.max_allocated_periods_weekly | Partial | Per-activity ceiling |
| B9 | `min_allocated_periods_weekly` | USER_PROVIDED int | tt_teacher_availability.min_allocated_periods_weekly | Partial | Per-activity floor |
| B10 | `can_be_split_across_sections` | USER_PROVIDED bool | tt_teacher_availability.can_be_split_across_sections | No | Cross-section split allowed |
| B11 | `proficiency_percentage` | USER_PROVIDED 0–100 | sch_teacher_capabilities.proficiency_percentage → tt_teacher_availability.proficiency_percentage | Partial (substitution ranking) | Subject mastery |
| B12 | `teaching_experience_months` | COMPUTED | sch_teacher_capabilities | Partial | Tenure ranking |
| B13 | `is_primary_subject` | USER_PROVIDED bool | tt_teacher_availability.is_primary_subject | No (potential) | Subject is teacher's primary |
| B14 | `competancy_level` | USER_PROVIDED enum | tt_teacher_availability.competancy_level (Facilitator/Basic/Intermediate/Advanced/Expert) | No (potential) | Skill tier |
| B15 | `priority_order` | USER_PROVIDED int | tt_teacher_availability.priority_order | No (potential) | Manual order |
| B16 | `priority_weight` | USER_PROVIDED 1–10 | tt_teacher_availability.priority_weight | No (potential) | Activity-importance (inverse) |
| B17 | `scarcity_index` | COMPUTED 1–10 | tt_teacher_availability.scarcity_index | Yes (in difficulty) | 10 = sole eligible teacher |
| B18 | `is_hard_constraint` (per row) | USER_PROVIDED bool | tt_teacher_availability.is_hard_constraint | No (potential) | "Must be this teacher" lock |
| B19 | `allocation_strictness` | USER_PROVIDED enum | tt_teacher_availability.allocation_strictness (Hard/Medium/Soft) | No (potential) | Hard = unbreakable preference |
| B20 | `override_priority` | USER_PROVIDED 1–10 | tt_teacher_availability.override_priority | No (potential) | Manual override |
| B21 | `override_reason` | USER_PROVIDED text | tt_teacher_availability.override_reason | No | Audit trail |
| B22 | `historical_success_ratio` | COMPUTED 1–100 | tt_teacher_availability.historical_success_ratio | No (potential) | (sessions_no_change / total) × 100 |
| B23 | `last_allocation_score` | COMPUTED 1–100 | tt_teacher_availability.last_allocation_score | No | Prior run's score |
| B24 | `is_primary_teacher` | USER_PROVIDED bool | tt_teacher_availability.is_primary_teacher | No (potential) | School-marked primary |
| B25 | `is_preferred_teacher` | USER_PROVIDED bool | tt_teacher_availability.is_preferred_teacher | Yes (substitution scoring) | School-preferred for subject |
| B26 | `preference_score` | USER_PROVIDED 1–100 | tt_teacher_availability.preference_score | Yes (substitution) | Numeric preference |
| B27 | `available_for_full_timetable_duration` | COMPUTED bool (generated stored) | tt_teacher_availability.available_for_full_timetable_duration | Partial | Date-window check |
| B28 | `no_of_days_not_available` | COMPUTED int (generated stored) | tt_teacher_availability.no_of_days_not_available | No | Late-joining gap |
| B29 | `teacher_weekly_load_running` | SOLVER_DERIVED int | (in-memory `teacherWeeklyLoad[teacherId]`) | Yes | LPT smoothing |
| B30 | `teacher_occupied_running` | SOLVER_DERIVED bool | `context->teacherOccupied[tid][dayId][periodId]` | Yes (HARD: TeacherConflictConstraint) | Already-busy check |
| B31 | `assignment_role_id` | USER_PROVIDED FK | tt_activity_teacher.assignment_role_id → tt_teacher_assignment_role | Yes | PRIMARY vs ASSIST vs SUB |
| B32 | `allows_overlap` (role) | PRIME_SEEDED bool | tt_teacher_assignment_role.allows_overlap | Yes (B-bucket force-place) | False conflict ignore |
| B33 | `is_required` | USER_PROVIDED bool | tt_activity_teacher.is_required | Partial | Mandatory teacher |
| B34 | `ordinal` | USER_PROVIDED int | tt_activity_teacher.ordinal | No | Pick order if multiple eligible |

### Group C — Class & Requirement parameters (from `tt_requirement_consolidation`, `sch_class_section_jnt`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| C1 | `class_priority_score` | USER_PROVIDED int | tt_requirement_consolidation.class_priority_score | No (potential) | Per-class priority |
| C2 | `student_count` | COMPUTED int | tt_requirement_consolidation.student_count | Yes (priority_config) | Bigger class → bigger impact |
| C3 | `eligible_teacher_count` (req-level) | COMPUTED int | tt_requirement_consolidation.eligible_teacher_count | Yes | Inverse scarcity |
| C4 | `is_compulsory` (req-level) | USER_PROVIDED bool | tt_requirement_consolidation.is_compulsory | Yes | Cascades to tt_activity |
| C5 | `min_periods_required_per_week` | USER_PROVIDED int | tt_requirement_consolidation.min_periods_required_per_week | Partial | Floor enforcement |
| C6 | `max_periods_required_per_week` | USER_PROVIDED int | tt_requirement_consolidation.max_periods_required_per_week | Partial | Ceiling |
| C7 | `min/max_periods_required_per_day` | USER_PROVIDED int | tt_requirement_consolidation.min/max_periods_required_per_day | Yes (cap) | Daily bounds |
| C8 | `required_consecutive_periods` | USER_PROVIDED int | tt_requirement_consolidation.required_consecutive_periods | Partial (lab) | "Must run 2 in a row" |
| C9 | `min_required_consecutive_periods` | USER_PROVIDED int | tt_requirement_consolidation.min_required_consecutive_periods | Partial | Min consecutive |
| C10 | `is_shared_across_sections` | USER_PROVIDED bool | tt_requirement_consolidation.is_shared_across_sections | Yes | Routes through tt_class_requirement_subgroups |
| C11 | `is_shared_across_classes` | USER_PROVIDED bool | tt_requirement_consolidation.is_shared_across_classes | Yes | Cross-class subgroup |
| C12 | `class_house_room_id` | COMPUTED FK | tt_requirement_consolidation.class_house_room_id ← sch_class_section_jnt.class_house_room_id | Yes (room fallback) | Default homeroom |
| C13 | `class_daily_floor` (per class, per term) | SOLVER_DERIVED int | computed in `loadClassDailyTargets()` | Yes (+25/−10/−1000 in score) | Day-balance |
| C14 | `class_daily_ceil` (per class, per term) | SOLVER_DERIVED int | same | Yes (HARD daily cap) | Daily reject if exceeded |
| C15 | `class_teaching_window` | SOLVER_DERIVED int[] | from `tt_class_timetable_type_jnt.from/to_period_ord` (v7.7) | Yes (HARD) | Allowed master-grid indices |
| C16 | `class_occupied_running` | SOLVER_DERIVED grid | `context->occupied[classKey][dayId][periodId]` | Yes (HARD) | Class double-booking |

### Group D — Period-intrinsic parameters (from `tt_period_config`, `tt_period_set`, `tt_period_set_period_jnt`, `tt_period_type`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| D1 | `slot_ord` (master grid index) | PRIME_SEEDED int | tt_period_config.slot_ord | Yes | Master-grid position |
| D2 | `start_time` / `end_time` | USER_PROVIDED time | tt_period_config.start_time/end_time | Yes (display) | Wall-clock |
| D3 | `is_teaching_slot` | USER_PROVIDED bool | tt_period_config.is_teaching_slot | Yes (HARD: filter) | Only TEACHING slots eligible |
| D4 | `period_type_id` | USER_PROVIDED FK | tt_period_config.period_type_id → tt_period_type | Yes | TEACHING/BREAK/LUNCH/etc. |
| D5 | `is_break` | USER_PROVIDED bool | tt_period_type.is_break | Yes (HARD: skip) | Solver excludes |
| D6 | `is_free_period` | USER_PROVIDED bool | tt_period_type.is_free_period | Yes (HARD: skip) | Free-period exclusion |
| D7 | `counts_as_teaching` | USER_PROVIDED bool | tt_period_type.counts_as_teaching | Yes | Workload accounting |
| D8 | `counts_as_workload` | USER_PROVIDED bool | tt_period_type.counts_as_workload | Yes | Workload accounting |
| D9 | `duration_minutes` | COMPUTED (generated) | tt_period_config.duration_minutes | Yes | UI |
| D10 | `period_ord` (set-local) | USER_PROVIDED int | tt_period_set_period_jnt.period_ord | Yes | Per-set sequence |
| D11 | `from_period_ord`/`to_period_ord` | USER_PROVIDED int | tt_period_set.from_period_ord/to_period_ord | Yes (HARD: window) | Class teaching window |
| D12 | `total_periods` | USER_PROVIDED int | tt_period_set.total_periods | Yes | Per-set count |
| D13 | `teaching_periods` | USER_PROVIDED int | tt_period_set.teaching_periods | Yes | Per-set teaching count |
| D14 | `exam_periods` / `free_periods` | USER_PROVIDED int | tt_period_set.exam_periods/free_periods | Yes | Per-set bookkeeping |

### Group E — Calendar / day parameters (from `tt_school_days`, `tt_working_day`, `tt_class_working_day_jnt`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| E1 | `is_school_day` | USER_PROVIDED bool | tt_school_days.is_school_day | Yes (filter) | Working day vs weekend |
| E2 | `day_of_week` | PRIME_SEEDED int | tt_school_days.day_of_week (1–7) | Yes | Day enumeration |
| E3 | `day_type` | USER_PROVIDED FK | tt_working_day.day_type1..4_id → tt_day_type | No (potential) | EXAM/PTM/HOLIDAY override |
| E4 | `reduced_periods` (day-type) | USER_PROVIDED bool | tt_day_type.reduced_periods | No (potential) | Half-day flag |
| E5 | `is_exam_day` (per class) | USER_PROVIDED bool | tt_class_working_day_jnt.is_exam_day | No | Class-specific exam |
| E6 | `is_half_day` (per class) | USER_PROVIDED bool | tt_class_working_day_jnt.is_half_day | No | Class-specific half-day |
| E7 | `working_days_count` | SOLVER_DERIVED int | derived from tt_school_days | Yes (per-class daily targets) | Denominator in daily floor/ceil |

### Group F — Constraint-driven parameters (from `tt_constraints`, `tt_teacher_unavailable`, `tt_room_unavailable`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| F1 | `is_hard` | USER_PROVIDED bool | tt_constraints.is_hard | Yes | HARD vs SOFT classification |
| F2 | `weight` | USER_PROVIDED 0–100 | tt_constraints.weight | Yes (× 0.5 multiplier) | Soft score contribution |
| F3 | `params_json` | USER_PROVIDED json | tt_constraints.params_json | Yes | Per-constraint config |
| F4 | `effective_from`/`to` | USER_PROVIDED date | tt_constraints.effective_from/to | Yes | Date-window filter |
| F5 | `apply_for_all_days` | USER_PROVIDED bool | tt_constraints.apply_for_all_days | Yes | Day-scope toggle |
| F6 | `applicable_days` | USER_PROVIDED int[] | tt_constraints.applicable_days | Yes | Per-day applicability |
| F7 | `target_type` / `target_id` | USER_PROVIDED morph | tt_constraints.target_type/id | Yes | TEACHER / CLASS / ROOM / ACTIVITY scoping |
| F8 | `impact_score` | USER_PROVIDED 1–100 | tt_constraints.impact_score | Partial | Estimated difficulty bump |
| F9 | `tt_teacher_unavailable.day_of_week + period_no` | USER_PROVIDED | tt_teacher_unavailable | Yes (HARD) | Teacher off-period |
| F10 | `tt_teacher_unavailable.is_recurring` | USER_PROVIDED bool | tt_teacher_unavailable.is_recurring | Yes | Repeat vs one-off |
| F11 | `tt_room_unavailable.day_of_week + period_from/to` | USER_PROVIDED | tt_room_unavailable | Yes (HARD) | Room off-period |
| F12 | All 86 constraint classes (Hard/* + Soft/*) | varies | (see deliverable Appendix C) | Yes (24 hard + 62 soft active) | DSL of preferences |

### Group G — Pre-computed priority indices (from `tt_priority_config`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| G1 | `tot_students` | COMPUTED | tt_priority_config.tot_students ← tt_requirement_consolidation.student_count | Yes | Higher = bigger blast radius |
| G2 | `teacher_scarcity_index` | COMPUTED | tt_priority_config.teacher_scarcity_index | Yes | Inverse of `eligible_teacher_count` |
| G3 | `weekly_load_ratio` | COMPUTED | tt_priority_config.weekly_load_ratio | Yes | required_weekly / total_weekly |
| G4 | `average_teacher_availability_ratio` | COMPUTED | tt_priority_config.average_teacher_availability_ratio | Yes | Mean TAR |
| G5 | `rigidity_score` | COMPUTED | tt_priority_config.rigidity_score | Yes | (allowed_slots / total_slots)⁻¹ |
| G6 | `resource_scarcity` | COMPUTED | tt_priority_config.resource_scarcity | Yes | Inverse room availability |
| G7 | `subject_difficulty_index` | USER_PROVIDED | tt_priority_config.subject_difficulty_index | Yes | School's subject hardness |

### Group H — Solver options (per-run knobs from generation request)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| H1 | `class_teacher_first_lecture` | USER_PROVIDED bool | options | Yes | Reserve P1 for class teacher |
| H2 | `single_activity_once_per_day_until_overflow` | USER_PROVIDED bool | options | Yes | Spread across week |
| H3 | `pin_activities_by_period` | USER_PROVIDED bool | options | Yes | Same activity → same period across days |
| H4 | `auto_relax_daily_cap_on_overflow` | USER_PROVIDED bool | options | Yes | Relax under demand pressure |
| H5 | `allow_consecutive_periods` | USER_PROVIDED bool | options | Yes | Back-to-back activities |
| H6 | `even_daily_distribution` | USER_PROVIDED bool | options | Yes | Day-balance toggle |
| H7 | `strict_no_conflicts` | USER_PROVIDED bool | options | Yes | Skip Phase 3 force-place |
| H8 | `acknowledge_capacity_warnings` | USER_PROVIDED bool | options | Yes | Bypass pinned-overload guard |
| H9 | `optimize_for_teachers` / `optimize_for_students` / `avoid_gaps` | USER_PROVIDED bool | options | Partial | Soft-bias toggles |
| H10 | `max_generation_time` | USER_PROVIDED int | options | Yes | PHP exec ceiling (max 300 s) |

> **Total Teacher+Period parameter universe: ~120 distinct fields.** The solver actively reads ~50 of these today; the rest are present in the schema but not yet wired into scoring/decision paths.

---

## Section 1B — Parameters for Room placement on an Activity

> Room placement runs as a **separate post-solver pass** (`RoomAllocationPass::allocate`). Activities are sorted by room-priority-score, then `findBestRoom()` walks a HARD→SOFT cascade. Parameters come from **4 groups**:

### Group R1 — Activity room requirements (from `tt_activity`, `tt_requirement_consolidation`)

| # | Parameter | Type | Source | Used today? | Cascade tier |
|---|---|---|---|---|---|
| R1.1 | `requires_room` | USER_PROVIDED bool | tt_activity.requires_room | Yes | Gate (skip if false) |
| R1.2 | `required_room_id` | USER_PROVIDED FK | tt_activity.required_room_id | Yes | **HARD-1** (specific room) |
| R1.3 | `compulsory_specific_room_type` | USER_PROVIDED bool | tt_activity.compulsory_specific_room_type | Yes | **HARD-2** flag |
| R1.4 | `required_room_type_id` | USER_PROVIDED FK | tt_activity.required_room_type_id | Yes | **HARD-2** if compulsory else SOFT-4a |
| R1.5 | `preferred_room_ids` | USER_PROVIDED FK[] (json) | tt_activity.preferred_room_ids | Yes | **SOFT-3** |
| R1.6 | `preferred_room_type_id` | USER_PROVIDED FK | tt_activity.preferred_room_type_id | Yes | **SOFT-4b** |
| R1.7 | `compulsory_specific_room_type` (req-level) | USER_PROVIDED bool | tt_requirement_consolidation.compulsory_specific_room_type | Yes (cascade source) | Same as R1.3 |
| R1.8 | `required_room_type_id` (req-level) | USER_PROVIDED FK | tt_requirement_consolidation.required_room_type_id | Yes | Same as R1.4 |
| R1.9 | `required_room_id` (req-level) | USER_PROVIDED FK | tt_requirement_consolidation.required_room_id | Yes | Same as R1.2 |
| R1.10 | `class_house_room_id` | COMPUTED FK | tt_requirement_consolidation.class_house_room_id | Partial | **SOFT-5 candidate** (homeroom) |

### Group R2 — Room-intrinsic parameters (from `sch_rooms`, `sch_rooms_type`, `sch_buildings`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| R2.1 | `room_type_id` | PRIME_SEEDED FK | sch_rooms.room_type_id | Yes | Match against required_room_type_id |
| R2.2 | `building_id` | PRIME_SEEDED FK | sch_rooms.building_id | Yes (TeacherMaxBuildingChanges) | Building-change minimization |
| R2.3 | `capacity` | USER_PROVIDED int | sch_rooms.capacity | Partial | Seating |
| R2.4 | `max_limit` | USER_PROVIDED int | sch_rooms.max_limit | Partial | Hard cap incl. overflow |
| R2.5 | `is_active` | USER_PROVIDED bool | sch_rooms.is_active | Yes (filter) | Active rooms only |
| R2.6 | `floor` / `wing` | USER_PROVIDED | sch_rooms.* | No | Locality scoring |
| R2.7 | `room_count_in_category` | COMPUTED int | sch_rooms_type.room_count_in_category | Yes | Cascading scarcity |

### Group R3 — Room availability (from `tt_room_availability`, `tt_room_availability_detail`, `tt_room_unavailable`)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| R3.1 | `can_be_assigned` | USER_PROVIDED bool | tt_room_availability.can_be_assigned | Yes (filter) | Mark off-limits |
| R3.2 | `overall_availability_status` | USER_PROVIDED enum | tt_room_availability.overall_availability_status (Available/Unavailable/Partially/Assigned) | Yes | Coarse filter |
| R3.3 | `available_for_full_timetable_duration` | COMPUTED bool | tt_room_availability.available_for_full_timetable_duration | Yes | Date-window |
| R3.4 | `is_class_house_room` | USER_PROVIDED bool | tt_room_availability.is_class_house_room | Yes | Homeroom flag |
| R3.5 | `house_room_class_id` / `house_room_section_id` | USER_PROVIDED FK | tt_room_availability.house_room_class_id/section_id | Yes | Which class owns this homeroom |
| R3.6 | `can_be_assigned_for_lecture/practical/exam/activity/sports` | USER_PROVIDED bool | tt_room_availability.* | Yes | Capability filter |
| R3.7 | `timetable_start_time` / `timetable_end_time` | COMPUTED time | tt_room_availability.* | Yes | Date scope |
| R3.8 | `availability_for_period` | USER_PROVIDED enum | tt_room_availability_detail.availability_for_period (Available/Unavailable/Assigned) | Yes (HARD) | Per-(day, period) state |
| R3.9 | `tt_room_unavailable.day_of_week` + period range + dates | USER_PROVIDED | tt_room_unavailable.* | Yes (HARD) | Off-period rules |
| R3.10 | `tt_room_unavailable.is_recurring` | USER_PROVIDED bool | tt_room_unavailable.is_recurring | Yes | Repeat vs one-off |
| R3.11 | `room_occupied_running` | SOLVER_DERIVED bool | RoomAllocationPass `roomOccupied[room][day][period]` | Yes (HARD) | Already-claimed |

### Group R4 — Cross-cutting room scoring (room-aware constraints)

| # | Parameter | Type | Source | Used today? | Purpose |
|---|---|---|---|---|---|
| R4.1 | `eligible_room_count` | COMPUTED int | tt_activity.eligible_room_count (via RoomAvailabilityService) | Yes (in difficulty) | Inverse scarcity |
| R4.2 | `room_availability_score` | COMPUTED 0–100 | tt_activity.room_availability_score | Yes | % of rooms eligible |
| R4.3 | `subject_id` (subject-room preference) | USER_PROVIDED FK | tt_activity.subject_id → SubjectPreferredRoomConstraint params | Yes (E4.1) | Subject-room affinity |
| R4.4 | `study_format_id` (format-room preference) | USER_PROVIDED FK | tt_activity.study_format_id → StudyFormatPreferredRoomConstraint | Yes (E4.3) | Format-room affinity |
| R4.5 | `(subject + study_format) preferred room` | USER_PROVIDED | SubjectStudyFormatPreferredRoomConstraint | Yes (E4.5) | Composite affinity |
| R4.6 | `teacher_home_room_id` | USER_PROVIDED FK | sch_teacher_profile or tt_teacher constraint | Partial | Teacher's preferred room |
| R4.7 | `room_max_usage_per_day` | USER_PROVIDED int | RoomMaxUsagePerDayConstraint params | Yes (HARD) | Cap per-room daily load |
| R4.8 | `room_max_study_formats` | USER_PROVIDED int | RoomMaxStudyFormatsConstraint params | Yes (SOFT) | Variety cap |
| R4.9 | `same_room_if_consecutive` | USER_PROVIDED bool | SameRoomIfConsecutiveConstraint params | Yes (SOFT) | Adjacency persistence |
| R4.10 | `max_different_rooms` | USER_PROVIDED int | MaxDifferentRoomsConstraint params | Yes (SOFT) | Limit room sprawl per activity |
| R4.11 | `class_max_room_changes_per_day` | USER_PROVIDED int | ClassMaxRoomChangesPerDayConstraint | Yes (SOFT) | Stable for students |
| R4.12 | `teacher_max_room_changes_per_day/week` | USER_PROVIDED int | TeacherMaxRoomChanges* | Yes (SOFT) | Stable for teachers |
| R4.13 | `teacher_max_building_changes_per_day` | USER_PROVIDED int | TeacherMaxBuildingChanges* | Yes (SOFT) | No building hopping |
| R4.14 | `teacher_min_gap_between_room_changes` | USER_PROVIDED int | TeacherMinGapBetweenRoomChanges | Yes (SOFT) | Adjustable buffer |
| R4.15 | `room_exclusive_use_for_activity` | USER_PROVIDED FK | RoomExclusiveUseConstraint params | Yes (HARD F16) | "Lab-2 is reserved for Activity X" |
| R4.16 | `prefer_same_room` (per activity) | USER_PROVIDED | PreferSameRoomConstraint (OPT_PREFER_SAME_ROOM) | Yes (SOFT F24) | Continuity |

> **Total Room-placement parameter universe: ~52 distinct fields.** The current pass uses ~30 actively in HARD/SOFT cascade; ~12 more are available in the schema for future scoring.

---

## Section 2 — Formulas (current + recommended)

> Where a parameter is `USER_PROVIDED`, the formula is "pass-through from DB." Computed/derived parameters get formulas below.

### 2.1 Activity-level computed scores (run by `ActivityScoreService`)

#### `difficulty_score_calculated` (0–100)
```
DIFFICULTY = TEACHER_SCARCITY_COMPONENT (max 30)
           + ROOM_SCARCITY_COMPONENT    (max 20)
           + CONSTRAINT_BURDEN_COMPONENT(max 20)
           + PERIOD_DEMAND_COMPONENT    (max 20)
           + CONSECUTIVE_GAP_COMPONENT  (max 10)
           = max 100
```

| Sub-component | Formula |
|---|---|
| TEACHER_SCARCITY | `max(0, 30 - (eligible_teacher_count × 5))` (0 teachers → 30, 6+ teachers → 0) |
| ROOM_SCARCITY | `max(0, 20 - (eligible_room_count × 2.5))` |
| CONSTRAINT_BURDEN | `min(20, constraint_count × 2)` |
| PERIOD_DEMAND | `min(20, required_weekly_periods × 2.5)` |
| CONSECUTIVE_GAP | `(allow_consecutive ? 0 : 5) + (min_gap_periods > 0 ? 5 : 0)` |

`difficulty_score` (User-provided fallback) is used only when `difficulty_score_calculated IS NULL`.

#### `calculated_priority` (0–100)
```
PRIORITY = (override_priority × 10)            (USER_PROVIDED — force-to-top)
         + (is_compulsory ? 20 : 0)
         + (difficulty_score_calculated × 0.4)
         + TEACHER_SCARCITY_BONUS              (0–10)
         + PERIOD_DEMAND_BONUS                 (0–10)
         capped at 100
```

#### `eligible_teacher_count`
```
eligible_teacher_count = COUNT(*) FROM tt_teacher_availability
  WHERE is_active = 1
    AND class_id = activity.class_id
    AND section_id = activity.section_id
    AND subject_study_format_id = activity.subject_study_format_id
    AND available_for_full_timetable_duration = 1
```

#### `teacher_availability_score` (0–100)
```
teacher_availability_score = (eligible_teacher_count / required_teacher_count) × 100
  capped at 100
where required_teacher_count = max(1, required_weekly_periods × duration_periods / max_available_periods_weekly_avg)
```

#### `eligible_room_count` (RoomAvailabilityService bucket)
```
eligible_room_count = COUNT(*) FROM tt_room_availability
  WHERE is_active = 1
    AND can_be_assigned = 1
    AND (room_id = activity.required_room_id  OR
         (room_type_id = activity.required_room_type_id AND activity.compulsory_specific_room_type = 1) OR
         room_id IN activity.preferred_room_ids OR
         room_type_id = activity.preferred_room_type_id OR
         (activity.required_room_id IS NULL AND
          activity.required_room_type_id IS NULL AND
          activity.preferred_room_type_id IS NULL))   -- fallback: any room
```
Bucket score: 0 rooms→0, 1→20, 2-3→50, 4-7→75, 8+→100.

#### `room_availability_score` (0–100)
```
room_availability_score = bucket(eligible_room_count) above
```

### 2.2 Priority-config indices (run by `PriorityConfigService::recalculate`)

#### `tot_students`
```
tot_students = tt_requirement_consolidation.student_count    (USER_PROVIDED rolled up)
```

#### `teacher_scarcity_index` (1–10)
```
teacher_scarcity_index = clamp(10 - eligible_teacher_count + 1, 1, 10)
  (1 = abundant, 10 = sole eligible teacher)
```

#### `weekly_load_ratio` (0.00–1.00)
```
weekly_load_ratio = required_weekly_periods / total_periods_in_week
where total_periods_in_week = working_days × teaching_periods_per_day
```

#### `average_teacher_availability_ratio` (0.00–1.00)
```
TAR_per_teacher = (Total weekly assigned periods) / (Total weekly available periods) × 100
average_TAR     = AVG(TAR_per_teacher) over eligible teachers
```

#### `rigidity_score` (0.00–1.00)  *(higher = more rigid / less flexible)*
```
rigidity_score = 1 - (allowed_slots / total_slots)
where
  allowed_slots = COUNT of (day, period) ∈ class_teaching_window
                  AND ∈ activity.preferred_periods_json (if non-empty, else all)
                  AND ∉ activity.avoid_periods_json
                  AND ∉ teacher_unavailable_slots (any eligible teacher)
                  AND ∉ room_unavailable_slots (any eligible room)
```

#### `resource_scarcity` (0.00–1.00)  *(higher = scarcer)*
```
resource_scarcity = required_resource_count / available_resource_count
where required_resource_count = required_weekly_periods (one room slot per period)
      available_resource_count = eligible_room_count × working_days × teaching_periods_per_day
```

#### `subject_difficulty_index` (0.00–1.00) — **USER_PROVIDED**
School sets per-subject difficulty (e.g., Physics 0.9, Music 0.3).

### 2.3 Per-class derived numbers (in `loadClassDailyTargets`)

```
weeklyDemand = Σ over class's activities of (required_weekly_periods × duration_periods)
workingDays  = COUNT(tt_school_days WHERE is_school_day = 1)
slotsPerDay  = COUNT of teaching slots in class's window
floor_per_day = floor(weeklyDemand / workingDays)
ceil_per_day  = min(ceil(weeklyDemand / workingDays), slotsPerDay)
```

### 2.4 Activity ordering (in `orderActivitiesByDifficulty`)

```
ORDER_SCORE = difficulty_score_calculated ?? difficulty_score ?? 0
            + (required_weekly_periods >= 6 ? 10000 : 0)        // heavy load gate
            + required_weekly_periods × 500
            + duration_periods × 3
            + activity.teachers.count × 2
            + (is_compulsory ? 20 : 0)
            + (enforceClassTeacherFirstLecture && is_class_teacher_activity
                ? 1000 + priority × 20 : 0)
            + (in_parallel_group ? 20000 : 0)
            + (is_anchor ? 5000 : 0)
sort DESC by ORDER_SCORE
```

### 2.5 Per-slot soft scoring (in `scoreSlotForActivity` — current numbers)

```
SLOT_SCORE = 0

  // Activity preference
  if matches preferred_time_slots_json (day, period_ord) exact:    +40
  if matches avoid_time_slots_json (day, period_ord) exact:        −50
  if matches preferred_periods_json (period_ord any day):          +20
  if matches avoid_periods_json (period_ord any day):              −30

  // Spread
  if spread_evenly && this day has 0 placements of this activity:  +10
  if spread_evenly && this day already has ≥1 placement:           −15

  // Day-balance (per class, post-place count)
  if post-place count < floor_per_day:                             +25
  if floor_per_day ≤ post-place count < ceil_per_day:              −10
  if post-place count would exceed ceil_per_day:                   −1000  // effectively reject

  // Per-day floor enforcement
  if min_per_day not met yet on this day:                          +15
  if split_allowed = false && this lands on a NEW day for activity: −100

  // DB constraint score
  for each soft constraint that passes:  SLOT_SCORE += constraint.weight × 0.5

return SLOT_SCORE
```

### 2.6 Teacher pick (LPT smoothing) — **proposed formula**

Currently `pickRandomTeacherAssignment()` uses LPT (longest-processing-time first) with random tie-breaks. **Recommended formula:**

```
TEACHER_SCORE_per_eligible = 0
  + (is_required ? 1000 : 0)                                      // Mandatory
  + (allocation_strictness = 'Hard' ? 800 : 0)
  + (is_hard_constraint ? 500 : 0)
  + (override_priority × 30)                                       // 1–10 → up to 300
  + (is_primary_teacher ? 100 : 0)
  + (is_preferred_teacher ? 80 : 0)
  + (preference_score × 0.6)                                       // 1–100 → up to 60
  + (is_primary_subject ? 40 : 0)
  + (proficiency_percentage × 0.3)                                 // 1–100 → up to 30
  + (competancy_level_numeric × 5)                                 // Facilitator=1..Expert=5 → 5..25
  + (allocation_strictness = 'Medium' ? 15 : 0)
  − (running_weekly_load × 4)                                      // LPT smoothing
  − (running_weekly_load > max_available_periods_weekly ? 10000 : 0) // Hard cap
  + (historical_success_ratio × 0.2)                               // 1–100 → up to 20
  + (last_allocation_score × 0.1)                                  // 1–100 → up to 10
  + (is_full_time ? 10 : 0)
  + (capable_handling_multiple_classes ? 5 : 0)
  − (no_of_days_not_available × 2)                                 // Penalize partial-window
  − (priority_order > 0 ? priority_order : 0)                      // 1 = top, 10 = bottom

pick teacher with highest TEACHER_SCORE among teachers passing HARD checks
```

`competancy_level_numeric`: Facilitator=1, Basic=2, Intermediate=3, Advanced=4, Expert=5.

### 2.7 Room scoring — proposed `findBestRoom` weighted formula

Today the function is a strict cascade (HARD-1 → HARD-2 → SOFT-3 → SOFT-4a → SOFT-4b → fallback). **Recommended:** convert SOFT tiers to a weighted score so a sub-optimal type-match can lose to a better building/capacity match.

```
ROOM_SCORE_per_candidate = 0
  + (room.id = activity.required_room_id ? 10000 : 0)              // HARD-1 (mandatory)
  + (compulsory_specific_room_type = 1 &&
     room.room_type_id = activity.required_room_type_id ? 5000 : 0) // HARD-2
  + (room.id ∈ activity.preferred_room_ids ? 200 : 0)               // SOFT-3
  + (compulsory_specific_room_type = 0 &&
     room.room_type_id = activity.required_room_type_id ? 150 : 0)  // SOFT-4a
  + (room.room_type_id = activity.preferred_room_type_id ? 100 : 0) // SOFT-4b
  + (room.id = class_house_room_id ? 80 : 0)                        // SOFT-5: homeroom
  + (room.id = teacher_home_room_id ? 60 : 0)                       // E2.1
  − (room.building_id ≠ teacher's_prior_cell_building ? 30 : 0)     // E2.7 (building changes)
  − (room.id ≠ teacher's_prior_cell_room ? 20 : 0)                  // E2.3
  − (room.id ≠ class's_prior_cell_room ? 15 : 0)                    // E3
  + (subject_preferred_room match ? 25 : 0)                         // E4.1
  + (study_format_preferred_room match ? 25 : 0)                    // E4.3
  + (subject_study_format_preferred_room match ? 40 : 0)            // E4.5 (composite)
  + (room.capacity ≥ student_count ? 0 : −1000)                     // HARD: capacity
  + (room.capacity = student_count ? 50 :
     room.capacity − student_count < 5 ? 30 :
     0)                                                             // tight-fit bonus
  − (already-occupied[room][day][period] ? 10000 : 0)               // HARD: not free
  − (availability_for_period = 'Unavailable' ? 10000 : 0)           // HARD: unavailable
  − (capability_for_purpose = 0 ? 10000 : 0)                        // HARD: can_be_assigned_for_lecture/practical/etc.
  − (in tt_room_unavailable matching day/period/date ? 10000 : 0)   // HARD: explicit unavail.
  + (room_max_usage_per_day not yet exceeded ? 0 : −1000)           // F16
  + (same_room_as_prior_consecutive ? 35 : 0)                       // SameRoomIfConsecutive
  + (room.id = class_house_room_id && activity.has_no_specific_requirement ? 100 : 0)

pick room with highest ROOM_SCORE; if score ≤ 0 → record roomConflict
```

---

## Section 3 — Recommended Priority Sequence

> **Goal:** "Perfect placement" = (a) every activity gets a feasible (day, period, teacher, room) tuple, (b) hard constraints are never violated, (c) soft preferences are respected in priority order, (d) the same outcome reproduces on a re-run.
>
> The sequence below is the **proposed canonical order**. It supersedes the implicit ordering in today's `orderActivitiesByDifficulty` + `scoreSlotForActivity` + `findBestRoom`.

### 3.1 Tier 1 — HARD GATES (any failure = reject placement)

> Apply in this order; cheapest first so the solver fails fast.

| Order | Gate | Source / Backing | Purpose |
|---|---|---|---|
| H-01 | Activity status = ACTIVE | tt_activity.status | Skip drafts/locked/archived |
| H-02 | Slot ∈ class_teaching_window (v7.7) | tt_period_set.from/to_period_ord | Class can't attend out-of-window |
| H-03 | Slot is teaching (`is_teaching_slot=1`, `is_break=0`, `is_free_period=0`) | tt_period_config + tt_period_type | Don't place in lunch/break |
| H-04 | Day is school day (`is_school_day=1`) | tt_school_days | Skip weekends |
| H-05 | Day type isn't HOLIDAY/EXAM (per `tt_working_day` overlay) | tt_working_day → tt_day_type | Calendar overrides |
| H-06 | Class slot free in `occupied[classKey][day][period]` | solver state | No double-booking class |
| H-07 | All assigned teachers free in `teacherOccupied[tid][day][period]` | solver state + tt_activity_teacher | TeacherConflictConstraint |
| H-08 | Each teacher's day/period not in `tt_teacher_unavailable` | tt_teacher_unavailable | TeacherUnavailablePeriodsConstraint (F5) |
| H-09 | Each teacher's running weekly load < `max_available_periods_weekly` | tt_teacher_availability + state | TeacherMaxWeeklyConstraint (F2) |
| H-10 | Each teacher's running daily load < `max_periods_per_day` (constraint F1) | tt_constraint params + state | TeacherMaxDailyConstraint |
| H-11 | Class daily count + duration ≤ `ceil_per_day` | derived | Daily ceiling |
| H-12 | Class daily count + duration ≤ `max_periods_required_per_day` | tt_requirement_consolidation | Per-class cap |
| H-13 | If `allow_consecutive=0`: no same-activity back-to-back | tt_activity.allow_consecutive | Built-in check |
| H-14 | If `single_activity_once_per_day_until_overflow=true`: one per day until overflow | option | Spread |
| H-15 | All inter-activity hard constraints pass (SAME_TIME, NOT_OVERLAPPING, CONSECUTIVE_ACTIVITIES, ACTIVITY_FIXED_TO_DAY/PERIOD_RANGE, OCCUPY_EXACT_SLOTS, ACTIVITY_EXCLUDED_FROM_DAY) | tt_constraints | DSL |
| H-16 | All resource hard constraints pass (RoomMaxUsagePerDay, RoomExclusiveUse, ExamOnlyPeriods, NoTeachingAfterExam, GlobalFixedPeriod, GlobalHoliday, ParallelPeriod, ClassConsecutiveRequired, ClassMaxPerDay, ClassWeeklyPeriods) | tt_constraints | Resource caps |
| H-17 | If activity is in parallel group: anchor placed first OR siblings being force-placed | tt_parallel_group_activity | ParallelPeriodConstraint |

### 3.2 Tier 2 — ACTIVITY ORDERING (which activity does the solver tackle first?)

The solver places activities one at a time. Order matters because hard activities should grab their few feasible slots before easy ones eat them.

| Rank | Tier | Why first |
|---|---|---|
| 1 | **Parallel-group anchors** | Sibling slots depend on anchor (+25,000 score) |
| 2 | **Parallel-group siblings (non-anchor)** | Pulled in by anchor (+20,000) |
| 3 | **Heavy load (`required_weekly_periods ≥ 6`)** | Eats the most space (+10,000) |
| 4 | **Compulsory + class-teacher first lecture** | Special placement rule (+1,000) |
| 5 | **Multi-period (`duration_periods > 1`)** | Block placement constrained (×3 weight) |
| 6 | **High `difficulty_score_calculated`** | Auto-difficulty (continuous) |
| 7 | **High teacher scarcity (`scarcity_index ≥ 7`)** | Few teachers — protect them |
| 8 | **High `weekly_load_ratio`** (more than 20% of week) | Substantial chunk |
| 9 | **High `rigidity_score`** (few feasible slots) | Pinned/constrained |
| 10 | **Compulsory** (`is_compulsory=1`) | Cannot be skipped (+20) |
| 11 | **High `subject_difficulty_index`** (USER_PROVIDED) | Domain difficulty |
| 12 | **Fewer eligible teachers** (`eligible_teacher_count` ascending) | Multi-teacher = more options |
| 13 | **Soft / optional / library / PT** | Easy to slot last |

(Today: this is approximated by `orderActivitiesByDifficulty`. Recommend tightening to match this 13-rank order.)

### 3.3 Tier 3 — DAY/PERIOD SELECTION (within a slot's feasibility, which slot wins?)

Once HARD gates have culled the candidate slots, sort survivors by:

| Rank | Soft factor | Source | Direction |
|---|---|---|---|
| 1 | Pinned-period affinity (same period as prior placement of this activity) | `pin_activities_by_period` option + memory | high |
| 2 | Class-teacher first lecture rule (P1 wins for class-teacher activity) | option | high |
| 3 | Activity `preferred_time_slots_json` exact match | tt_activity | high (+40) |
| 4 | Activity `avoid_time_slots_json` exact match | tt_activity | low (−50) |
| 5 | Activity `preferred_periods_json` (period match any day) | tt_activity | high (+20) |
| 6 | Activity `avoid_periods_json` | tt_activity | low (−30) |
| 7 | `spread_evenly` and day has 0 placements of activity | tt_activity | high (+10) |
| 8 | `spread_evenly` and day has ≥1 placement of activity | tt_activity | low (−15) |
| 9 | Day-balance: post-place count < `floor_per_day` | derived | high (+25) |
| 10 | Day-balance: post-place count between floor & ceil | derived | low (−10) |
| 11 | `min_per_day` not met yet on this day | tt_activity | high (+15) |
| 12 | `split_allowed=false` and lands on new day | tt_activity | low (−100) |
| 13 | GlobalPreferMorning (compulsory subjects before period N) | constraint G9 | high |
| 14 | EndStudentsDay (last teaching period of day) | constraint | situational |
| 15 | All other soft constraint scores summed × 0.5 | tt_constraints | varies |
| 16 | `class_priority_score` (USER_PROVIDED) | tt_requirement_consolidation | tie-break |

### 3.4 Tier 4 — TEACHER SELECTION (when activity has multiple eligible teachers)

Apply per Section 2.6 formula. Priority sequence in plain English:

| Rank | Factor | Type |
|---|---|---|
| 1 | Activity-Teacher row marked `is_required=1` | USER_PROVIDED |
| 2 | `tt_teacher_availability.is_hard_constraint=1` (locked teacher) | USER_PROVIDED |
| 3 | `allocation_strictness=Hard` | USER_PROVIDED |
| 4 | `override_priority` (1 wins, manual override) | USER_PROVIDED |
| 5 | `is_primary_teacher=1` for this (class, subject, study_format) | USER_PROVIDED |
| 6 | `is_preferred_teacher=1` | USER_PROVIDED |
| 7 | Higher `preference_score` | USER_PROVIDED |
| 8 | `is_primary_subject=1` (their primary subject) | USER_PROVIDED |
| 9 | Higher `proficiency_percentage` | USER_PROVIDED |
| 10 | Higher `competancy_level` (Expert > Advanced > Intermediate > Basic > Facilitator) | USER_PROVIDED |
| 11 | `allocation_strictness=Medium` over Soft | USER_PROVIDED |
| 12 | LPT smoothing — lower `running_weekly_load` | SOLVER_DERIVED |
| 13 | Higher `historical_success_ratio` | COMPUTED |
| 14 | Higher `last_allocation_score` | COMPUTED |
| 15 | `is_full_time=1` over part-time | USER_PROVIDED |
| 16 | `capable_handling_multiple_classes=1` | USER_PROVIDED |
| 17 | Lower `no_of_days_not_available` | COMPUTED |
| 18 | Lower `priority_order` (manual rank) | USER_PROVIDED |
| 19 | Random tie-break | – |

Reject any candidate whose `running_weekly_load + (weekly_periods × duration_periods)` would exceed `max_available_periods_weekly`.

### 3.5 Tier 5 — ROOM SELECTION (after solver places day/period/teacher)

Apply per Section 2.7 formula. Priority sequence:

| Rank | Factor | Tier |
|---|---|---|
| 1 | `required_room_id` (specific room — must) | HARD |
| 2 | `compulsory_specific_room_type=1` + `required_room_type_id` (must match type) | HARD |
| 3 | Room capacity ≥ student_count | HARD |
| 4 | Room capability flag (`can_be_assigned_for_lecture/practical/exam/activity/sports`) matches activity type | HARD |
| 5 | Room not in `tt_room_unavailable` for this day/period | HARD |
| 6 | `availability_for_period ≠ 'Unavailable'` | HARD |
| 7 | Not already-occupied at (day, period) | HARD |
| 8 | Room ∈ `preferred_room_ids` | SOFT |
| 9 | Non-compulsory `required_room_type_id` match | SOFT |
| 10 | `preferred_room_type_id` match | SOFT |
| 11 | `class_house_room_id` (homeroom — natural fallback) | SOFT |
| 12 | Subject+study_format preferred room (E4.5) | SOFT |
| 13 | Subject preferred room (E4.1) | SOFT |
| 14 | Study format preferred room (E4.3) | SOFT |
| 15 | Same room as prior consecutive period (SameRoomIfConsecutive) | SOFT |
| 16 | Same building as teacher's prior cell (TeacherMaxBuildingChanges) | SOFT |
| 17 | Same room as teacher's prior cell (TeacherMaxRoomChanges) | SOFT |
| 18 | Same room as class's prior cell (ClassMaxRoomChanges) | SOFT |
| 19 | Teacher home room (E2.1) | SOFT |
| 20 | Tight-fit capacity (`capacity − student_count < 5`) | SOFT bonus |
| 21 | `RoomMaxUsagePerDay` not yet exceeded | HARD F16 |
| 22 | `MaxDifferentRooms` for this activity not exceeded | SOFT |
| 23 | `RoomMaxStudyFormats` not exceeded | SOFT |
| 24 | Random fallback | – |

If no candidate scores > 0 → record `roomConflict` with `conflict_type` and `has_conflict=true`.

### 3.6 Tier 6 — POST-PLACEMENT VALIDATION (run once after all activities placed)

| Check | Source | Action on fail |
|---|---|---|
| Parallel-group sibling alignment | `verifyParallelCompliance` | parallelViolations[] |
| Class daily ceiling not breached | derived | placement_diagnostics |
| Teacher weekly cap not breached | derived | placement_diagnostics |
| Room conflict-cells flagged | RoomAllocationPass | roomConflicts[] |
| Force-placement bucketed (A/B/C/D) | bucketForcedPlacements | stats.force_placement_buckets |
| Soft scores totalled & per-class | per-cell summation | timetable.soft_score |
| Quality score calculated | aggregate | timetable.quality_score |

---

## Section 4 — Mapping the recommended sequence onto solver phases

| Phase | What runs | Tier touched |
|---|---|---|
| **0. Pre-flight** (orchestrator) | auditTeacherCapacity (B6 sum vs activity demand), validateParallelGroups | (gate before solver) |
| **1. Pre-solve transforms** (PrimeSolver constructor) | calculateTeachingPeriods, initializeParallelGroups, buildClassAllowedTeachingIndices, build teacher_weekly_caps | Tier 1 H-02, H-03 |
| **2. Activity expansion + teacher pre-pick** | expandActivitiesByWeeklyPeriods, pickRandomTeacherAssignment (LPT) | Tier 4 (per activity) |
| **3. Activity ordering** | orderActivitiesByDifficulty | Tier 2 (13-rank) |
| **4. Phase-1 Backtracking** | backtrack(): for each activity → getPossibleSlots → score → canPlaceWithConstraints | Tier 1 + Tier 3 |
| **5. Phase-2 Greedy** (timeout) | generateGreedySolution + tryAlternativeTeacher | Tier 1 + Tier 3 + Tier 4 (re-pick) |
| **6. Phase-3 Rescue + Force-Place** | relax pinning/consecutive/daily cap; force into anchor slot or accept conflict | Tier 1 partial relax |
| **7. Room allocation** | RoomAllocationPass.allocate (HARD→SOFT cascade) | Tier 5 |
| **8. Post-placement** | verifyParallelCompliance + buildPlacementDiagnostics + bucketForcedPlacements | Tier 6 |

### 4.1 Where current code matches — and where it diverges

| Concern | Current behavior | Recommended | Gap |
|---|---|---|---|
| Activity ordering | Sorts by `difficulty_score_calculated + weekly×500 + duration×3 + teachers×2 + compulsory×20 + class-teacher×1000 + parallel×20000 + anchor×5000` | Same idea but explicit 13-rank tiers | **Minor** — formula approximates the 13 ranks but the priorities aren't documented; document them in code comments |
| Per-slot scoring | `+40/−50/+20/−30/+10/−15/+25/−10/−1000/+15/−100` plus DB soft × 0.5 | Same numbers ✅ | **None** — scoring is solid |
| Teacher pick | LPT + random tie-break; no use of preference_score, override_priority, allocation_strictness, etc. | Full 19-rank scoring (Section 2.6) | **MAJOR GAP** — only ~25% of teacher-preference fields used today |
| Room selection | Strict cascade HARD-1 → HARD-2 → SOFT-3 → SOFT-4a → SOFT-4b → fallback (first-fit per tier) | Weighted score so good capacity/building match can beat marginal type match | **MEDIUM GAP** — first-fit ignores capacity, building proximity, prior-cell continuity within each tier |
| Parallel group anchor selection | First sibling marked `is_anchor=1` | Same ✅ | **None** |
| Day-of-day balance | `floor_per_day`/`ceil_per_day` enforcement | Same ✅ | **None** |
| Date-overlay (working_day, class_working_day_jnt) | Not consumed | Tier 1 H-05 | **GAP** — date-aware generation not implemented |
| Capacity vs students | Not checked | Tier 5 ranks 3, 20 | **GAP** — solver places activities in rooms too small for the section |
| Building-change minimization | Constraint exists (TeacherMaxBuildingChanges) but evaluated post-allocation only | Tier 5 rank 16 (during room pick) | **GAP** — preventive vs reactive |

### 4.2 Refinement quick-wins

1. **Wire 30 unused teacher-preference fields** into `pickRandomTeacherAssignment` (Section 2.6 formula). Saves 60–70% of the manual re-shuffles teachers do post-generation.
2. **Convert `findBestRoom` to weighted scoring.** Even keeping the HARD tiers as gates, scoring SOFT tiers improves room utilization and reduces "Math in Lab-2" mishaps.
3. **Date-overlay support.** Read `tt_working_day` (and per-class `tt_class_working_day_jnt`) before placement so the solver respects exam days, holidays, and half-days within the term.
4. **Capacity hard-check.** Reject any room whose `capacity < student_count` outright. This is missing today.
5. **Pinned-period memory tightening.** Currently `pin_activities_by_period` only remembers the most recent placement. Recommend memo per activity: `{period_ord: count}` so we prefer the most-frequent period, not the last one.

---

## Section 5 — Concrete refinement actions (P0 → P3)

### P0 — Foundational fixes (1–2 days)

- **F-01.** Add ParallelGroup tables to canonical DDL v7.9 (drift D-org-1).
- **F-02.** Fix DDL v7.8 syntax errors (D-01..D-23 from deep-understanding §5.5).
- **F-03.** Standardize singular vs plural table-name convention across DDL + models (drift D-24..D-40).

### P1 — Algorithm depth (3–5 days each)

- **A-01. Teacher-pick scoring upgrade** — implement Section 2.6 formula. Reads ~30 currently-unused fields from `tt_teacher_availability` and `tt_activity_teacher`. Backwards compatible (default weights match current behaviour).
- **A-02. Room weighted scoring** — implement Section 2.7 formula in `RoomAllocationPass::findBestRoom`. Add capacity hard-check.
- **A-03. Date-aware solver** — extend `loadSchoolDays` to read `tt_working_day` overlay; respect `is_exam_day`/`is_half_day`/`day_type` per-date. Pass into solver as `dayMaskByDate`.
- **A-04. Pinned-period memo refinement** — track period-frequency per activity, not just last-placed.

### P2 — Coverage / soft polish (1–3 days each)

- **A-05. Make `class_priority_score` consumable** — currently in DDL but not read.
- **A-06. Wire `class_house_room_id` as Tier 5 SOFT-5** — homeroom should beat random fallback.
- **A-07. Implement TeacherMaxStudyFormatsConstraint properly** (currently TODO).
- **A-08. Activate `subject_difficulty_index`** — already in tt_priority_config; bring into difficulty score computation.

### P3 — Future / nice-to-have

- **A-09. Genetic + Tabu solver variants** — `tt_generation_strategy` already supports them; PrimeSolver only implements RECURSIVE.
- **A-10. ML-based difficulty learning** — train MlModel on past `tt_generation_runs` outcomes; predict difficulty per (term, type) better than the 5-component formula.
- **A-11. What-if scenarios consumable** — DDL/model exists for `tt_what_if_scenarios`; build the comparison engine.

---

## Section 6 — Quick reference cards

### Card 1 — "What does Activity X need?" — single query

```sql
SELECT a.id, a.name,
       a.required_weekly_periods, a.duration_periods, a.is_compulsory,
       a.priority, a.difficulty_score, a.difficulty_score_calculated,
       a.preferred_time_slots_json, a.avoid_time_slots_json,
       a.compulsory_specific_room_type, a.required_room_type_id,
       a.required_room_id, a.preferred_room_ids,
       a.eligible_teacher_count, a.teacher_availability_score,
       a.eligible_room_count, a.room_availability_score, a.constraint_count,
       pc.tot_students, pc.teacher_scarcity_index, pc.weekly_load_ratio,
       pc.rigidity_score, pc.resource_scarcity, pc.subject_difficulty_index,
       (SELECT COUNT(*) FROM tt_activity_teacher
        WHERE activity_id = a.id AND is_active = 1) AS teacher_count
FROM tt_activity a
LEFT JOIN tt_priority_config pc
  ON pc.requirement_consolidation_id = a.activity_group_id
WHERE a.id = X;
```

### Card 2 — "What's blocking Activity X from being placed?" — diagnostic

```sql
-- Hard blockers
SELECT 'TEACHER UNAVAILABLE' AS reason, COUNT(*) AS slots_blocked
FROM tt_teacher_unavailable tu
JOIN tt_activity_teacher at ON at.teacher_id = tu.teacher_id
WHERE at.activity_id = X AND tu.is_active = 1
UNION ALL
SELECT 'ROOM UNAVAILABLE', COUNT(*)
FROM tt_room_unavailable WHERE is_active = 1
UNION ALL
SELECT 'CONSTRAINT TYPE', COUNT(*)
FROM tt_constraint c
WHERE c.is_active = 1 AND c.is_hard = 1
  AND (c.target_id = X OR c.target_id IS NULL);
```

### Card 3 — Weight tuning matrix (today vs proposed)

| Decision | Today's weight | Proposed weight | Change |
|---|---|---|---|
| Activity in parallel group | +20,000 | +20,000 | – |
| Activity is anchor | +5,000 | +5,000 | – |
| Compulsory + class-teacher first | +1,000 + priority×20 | unchanged | – |
| `required_weekly_periods ≥ 6` | +10,000 | unchanged | – |
| `required_weekly_periods` per unit | +500 | unchanged | – |
| `duration_periods` per unit | +3 | +5 | tighten |
| Teacher count per unit | +2 | +2 | – |
| `is_compulsory` | +20 | +20 | – |
| Teacher pick: `is_required` | (not used) | +1,000 | NEW |
| Teacher pick: `allocation_strictness=Hard` | (not used) | +800 | NEW |
| Teacher pick: `override_priority×10` | (not used) | up to +300 | NEW |
| Teacher pick: `proficiency_percentage` | (not used) | up to +30 | NEW |
| Teacher pick: LPT smoothing | random | −running_load×4 | TIGHTEN |
| Room: `required_room_id` match | strict cascade | +10,000 (gate) | unify |
| Room: capacity ≥ students | (not used) | gate (−1,000 if fail) | NEW |
| Room: building-change penalty | post-eval only | −30 in pick | EARLY |
| Room: prior-cell continuity | post-eval only | +20 in pick | EARLY |

---

## Section 7 — Glossary (terms used above)

- **Activity** = one row in `tt_activity` keyed by (academic_term × timetable_type × class+{section} × subject+study_format).
- **Instance** = one of N expanded clones of an activity, where N = `required_weekly_periods`.
- **classKey** = `"{class.code}-{section.code}"`, the composite identifier used everywhere.
- **Slot** = `{classKey, dayId, startIndex}` — a candidate placement position.
- **Teaching window** = the per-class subset of master-grid period indices the class is allowed to attend (v7.7).
- **floor_per_day / ceil_per_day** = derived per-class daily target driving the day-balance bonus.
- **LPT (Longest Processing Time first)** = scheduling heuristic where we pick the eligible teacher with the lowest running load, breaking ties with secondary criteria.
- **Tier 1..6** = the priority groups defined in §3.
- **Force-placement** = Phase 3 placement made despite a real conflict; surfaces in red in preview.
- **A/B/C/D buckets** = force-placement categorization (A=parallel-sibling false conflict, B=role-overlap, C=real teacher conflict, D=class capacity).
- **PRIME_SEEDED** = field set by Prime/SaaS admin (not editable by school).
- **USER_PROVIDED** = field set by school staff via the UI.
- **COMPUTED** = derived by application code from other DB rows.
- **SOLVER_DERIVED** = computed transiently inside the solver from running state.

---

## Section 8 — Open questions for the refinement work

1. Are `tt_teacher_availability.allocation_strictness`, `is_hard_constraint`, `override_priority`, `is_primary_teacher`, `is_preferred_teacher`, `preference_score` populated reliably today, or are they expected to be once we wire them?
2. Should the recommended Section 2.6 teacher-pick formula coexist with LPT (i.e., LPT as the last tie-break), or replace it?
3. Should the room-selection move from cascade to weighted score behind a feature flag (gradual rollout)?
4. Does the school want capacity to be a hard reject or a soft penalty? (DDL allows both; today it's neither.)
5. For the `class_house_room_id` SOFT-5 rule: if a class has a homeroom, should activities default to it for "regular" lessons (no specific type required)?
6. For pinned-period memo: should we expose the memo state to the operator for inspection/override?
7. Are `tt_priority_config` indices recomputed automatically before each generation, or does the operator need to click "Recalculate" first?
8. For `subject_difficulty_index`: do we want a Prime-seeded default (e.g., Physics=0.9, Music=0.3) that schools can override, or pure school-provided?

---

*End of v1 — Algo_parameter_detail.md. Companion to the deep-understanding doc; intended to be the launch pad for the algorithm refinement workstream.*
