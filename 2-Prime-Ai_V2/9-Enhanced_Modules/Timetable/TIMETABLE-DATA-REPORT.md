# Timetable Module — Data Flow Report (Before and After Generation)

**Prepared by:** Tarun Chauhan · **Date:** 7 October 2026 · **Status:** analysis, no code changed
**Scope:** `Modules/TimetableFoundation` + `Modules/SmartTimetable`, both generation engines
(Python engine and the PHP "Prime" engine). `StandardTimetable` (manual grid) is out of scope.
**Method:** static read of the code + read-only queries on the `test.localhost` tenant database
(`xyz_school_00000000000040008000_202627`). Row counts are exact `COUNT(*)` values taken on 7 Oct 2026.
**File references** are `Modules/...` paths inside `prime_ai/`, with line numbers as of today.
Re-check a line before relying on it; the code moves.

---

## 0. How to read this

The timetable splits into two halves:

```
 ┌───────────────────────── PART A: BEFORE GENERATION ─────────────────────────┐
 │  Master data (sch_*, std_*, tt_ config)                                      │
 │        │  read by                                                            │
 │        ▼                                                                     │
 │  Requirement pipeline (6 "Generate" buttons)  ──►  tt_ requirement tables    │
 │        │                                                                     │
 │        ▼  read by                                                            │
 │  Pre-generation reports (Readiness, Resource Availability, Preparation)      │
 └──────────────────────────────────────┬──────────────────────────────────────┘
                                        │  PART B: GENERATE (Python or PHP engine)
                                        ▼
 ┌───────────────────────── PART C: AFTER GENERATION ──────────────────────────┐
 │  tt_timetables · tt_generation_runs · tt_timetable_cells ·                   │
 │  tt_timetable_cell_teachers · tt_teacher_availability_details                │
 │        │  read by                                                            │
 │        ▼                                                                     │
 │  Post-generation reports, preview/workspace, substitution, portals           │
 └──────────────────────────────────────────────────────────────────────────────┘
   PART D: what deleting / regenerating does to all of the above
```

Your six questions map to these sections:

| # | Question | Section |
|---|---|---|
| 1 | Which tables we read from | §A1 (before), §B1/B2 (during) |
| 2 | Which tables we generate into, and the logic | §A2 (before), §B3 (during) |
| 3 | Pre-generation reports and their tables | §A3 |
| 4 | What generation fetches, from which tables | §B1, §B2 |
| 5 | Post-generation reports: where the data comes from, and the relations | §C1, §C2, §C3 |
| 6 | Tables whose deletion affects the timetable view | §D |

The **most important findings** are at the end, §E. Read §D and §E first if you are short of time.

---

# PART A — BEFORE GENERATION

## A1. Source tables (what the pipeline reads from)

### A1.1 School master data (owned by other modules)

| Table | Rows | Columns the timetable uses | Used for |
|---|---:|---|---|
| `sch_classes` | — | `id`, `name`, `short_name`, `code`, `ordinal`, `is_active` | class labels, ordering |
| `sch_sections` | — | `id`, `name`, `code` | section labels. ⚠ ids are **generic** (id 1 = "A" in every class); always pair with `class_id` |
| `sch_class_section_jnt` | 43 | `class_id`, `section_id`, `is_active`, `class_teacher_id` (**a `sys_users` id**, not a teacher id), `class_house_room_id`, `actual_total_student` | the unit the engine schedules (class-section), class teacher, home room, head-count |
| `sch_class_groups_jnt` | 613 | `class_id`, `section_id`, `subject_study_format_id`, `subject_type_id`, `required_weekly_periods`, `min/max_weekly_periods`, `min/max_daily_periods`, `min_gap_between_periods`, `allow_consecutive_periods`, `max_consecutive_periods`, `priority_score`, `has_multiple_options`, `compulsory_specific_room_type`, `required_room_type_id`, `required_room_id`, `is_active` | **Class Subject Requirements**: what each class must be taught and how much. The root of the whole pipeline |
| `sch_subjects` | 45 | `id`, `name`, `code`, `is_optional` | labels |
| `sch_subject_types` | 2 | `code` (`MAJ` = Major gets the early-period window) | subject placement priority |
| `sch_study_formats` | — | `id`, `name`, `code` | Theory / Practical / Lab … |
| `sch_subject_study_format_jnt` | 63 | `subject_id`, `study_format_id`, `subject_type_id`, `has_multiple_options`, `required_room_type_id` | the "subject + format" key everything points at |
| `sch_subject_study_format_options` | 15 | `id`, `subject_study_format_id`, `subject_id` (the real subject behind an option), `required_room_type_id`, `required_room_id`, option code/name | options of an optional subject (Games → Football/Cricket, XI elective → Economics/…) |
| `std_student_academic_sessions` | 9,724 | `class_section_id`, `is_current`, `count_for_timetable` | live head-count per section when the cached `actual_total_student` is 0 |
| `std_student_opted_subjects` | — | student → chosen option | head-count per option subgroup |
| `sch_rooms` | 72 | `id`, `name`, `room_type_id`, `capacity`, `is_active`, `deleted_at` | rooms the engine may use (capacity 0 = unknown, never ruled out) |
| `sch_rooms_type` | 19 | `id`, `name`, `code` | room-type demand |
| `sch_teachers` | 89 | `id`, `user_id` (**no `is_active` column**) | the teacher id stored on activities and cells |
| `sch_teacher_profile` | 89 | `id`, `user_id`, `is_active`, `max_available_periods_weekly` (**HARD weekly limit**), `min/max_allocated_periods_weekly` (soft band), `is_full_time`, `certified_for_lab`, … | who is an active teacher, and their limits. Join to `sch_teachers` on `user_id` |
| `sch_teacher_capabilities` | 521 | `teacher_profile_id`, `class_id`, `subject_study_format_id`, `proficiency_percentage`, `is_primary_subject`, `effective_from/to`, `is_active` | **who can teach what**, per class and per subject-format |
| `sch_academic_term` | 2 | `id`, `academic_session_id`, term dates | scope of requirements and activities |
| `sch_org_academic_sessions_jnt` | — | `id`, `is_current` | scope of timetables |
| `sys_users` | — | `id`, `name` | teacher display names |

### A1.2 Timetable configuration (tt_ masters, edited by hand on Timetable Masters / Configuration)

| Table | Rows | Key columns | Used for |
|---|---:|---|---|
| `tt_school_days` | 7 | `day_of_week`, `is_school_day`, `is_active` | the grid's columns. Test DB: Mon–Sat active, Sun off → **6 days** |
| `tt_period_types` | 9 | `counts_as_teaching`, `is_break`, `is_schedulable` | whether a period can hold a lesson |
| `tt_period_configs` | 9 | `slot_ord`, `start_time`, `end_time`, `is_teaching_slot`, `period_type_id` | one row per period of the day |
| `tt_period_sets` | 4 | `id`, `name`, `total_periods` | one "day shape" (Junior / Senior …) |
| `tt_period_set_periods_jnt` | 27 | `period_set_id`, `period_config_id`, `period_type_id`, `period_ord`, `is_active` | which periods a set has. Sets are matched on **`period_config_id`**, never on position |
| `tt_timetable_types` | 4 | `id`, `code`, `school_start_time`, `school_end_time`, `shift_id` | groups the classes timetabled together |
| `tt_class_timetable_types_jnt` | 344 | `class_id`, `section_id`, `timetable_type_id`, `period_set_id`, `academic_term_id`, `is_active` | **maps each class-section to a type and a period set**. Unmapped = not timetabled |
| `tt_shifts` | 2 | `code` | preferred shift on teacher availability |
| `tt_teacher_assignment_roles` | 5 | `code` (`PRIMARY`, `ASSISTANT`) | role on activity / cell teachers |
| `tt_configs` | 15 | `key`, `value` (e.g. `max_students_allowed_over_room_capacity`) | room-overflow allowance |
| `tt_constraints` | 6 | `constraint_type_id`, `target_type`, `target_id`, `is_hard`, `weight`, `params_json`, `academic_term_id` | user rules from Constraint Engine (teacher not available, break times, time windows, room limits, parallel periods) |
| `tt_constraint_types` / `tt_constraint_category_scopes` | 10 / 27 | `code`, `category_id`, `scope_id` | constraint catalogue |
| `tt_working_days` / `tt_class_working_days_jnt` | 365 / 4,620 | calendar dates per class | **not read by either engine** (only reports, ratio pages and Syllabus) |
| `tt_day_types` | 9 | | calendar day types |

---

## A2. Tables generated before the timetable, and the logic

There are **six Generate buttons**, run left to right on
`/timetable-foundation/timetable-requirement` (plus Room Availability on Resource Availability).
Each is a copy of the stage before it, not a live link: edit an earlier stage and you must
re-run every later one.

```
 sch_class_groups_jnt (613)          ← typed by hand: Class Subject Requirements
   │  [1] Generate Groups
   ▼
 tt_class_requirement_groups (539)   one per class-section × subject without options
 tt_class_requirement_subgroups (126) one per class-section × subject × OPTION
   │  [2] Generate Requirements
   ▼
 tt_requirement_consolidations (665) one per group / subgroup, with all the rules
   │  [3] Generate Teacher Availability       + sch_teacher_capabilities, sch_teacher_profile
   ▼
 tt_teacher_availabilities (1,077)   one per requirement × eligible teacher (candidate pool)
   │  [4] Generate Activities
   ▼
 tt_activities (597)  ── tt_activity_teachers (978)
                      ── tt_sub_activities (66) ── tt_sub_activity_members (126)
                                               ── tt_sub_activity_details (2,004)
   │  [5] Generate Slot Requirement
   ▼
 tt_slot_requirements (43)           one per class-section (weekly slot totals)
```

### ⛔ Every Generate button TRUNCATES its stage and every later stage

`RequirementTableTruncator::STAGES` (`TimetableFoundation/app/Services/RequirementTableTruncator.php:48`)
defines the order. `truncateFrom()` (`:121`) runs `TRUNCATE` with `FOREIGN_KEY_CHECKS=0`, outside
any transaction (so it cannot be rolled back, and FK cascades do **not** fire).

| Stage | Tables emptied (ids restart at 1) |
|---|---|
| `groups` | `tt_class_subgroup_members`, `tt_class_requirement_subgroups`, `tt_class_requirement_groups` |
| `consolidations` | `tt_requirement_consolidations` |
| `teacher_availability` | `tt_teacher_availabilities` |
| `activities` | `tt_activity_teachers`, `tt_activity_priorities`, `tt_sub_activity_members`, `tt_sub_activity_details`, `tt_sub_activities`, `tt_parallel_group_activity`, `tt_room_availability_details`, `tt_room_availabilities`, `tt_teacher_availability_details`, `tt_activities` |
| `timetable_cells` | **`tt_timetable_cell_teachers`, `tt_substitution_logs`, `tt_timetable_cells`** (every timetable, published included) |
| `slot_requirements` | `tt_slot_requirements` |
| `priority_configs` | `tt_priority_configs` |

So **Generate Groups, Generate Requirements, Generate Teacher Availability and Generate Activities
all wipe the generated timetable cells of every timetable.** Generate Slot Requirement does not.
"Reset All" (`TimetableFoundationController::resetRequirements`, `:1354`) truncates from `groups`.
See §D.

### [1] Generate Groups — `POST timetable-foundation/generate-class-groups`

`TimetableFoundationController::generateClassGroups()` (`TimetableFoundation/app/Http/Controllers/TimetableFoundationController.php:3508`)

- **Reads:** `sch_class_groups_jnt` (active) with `sch_classes`, `sch_sections`,
  `sch_subject_study_format_jnt` → `sch_subjects`, `sch_study_formats`, `sch_subject_types`;
  `sch_class_section_jnt` (`actual_total_student`, `class_house_room_id`);
  `std_student_academic_sessions` (live count where `is_current = 1 AND count_for_timetable = 1`, `:3581`);
  `tt_teacher_availabilities` (eligible teacher count, from the *previous* run);
  `sch_subject_study_format_options` + `std_student_opted_subjects` via `OptionalSubjectBreakdownService`.
- **Writes:** `tt_class_requirement_groups` or `tt_class_requirement_subgroups`.
- **Logic:**
  - Decided by `sch_class_groups_jnt.has_multiple_options` (`:3672`), **not** `is_compulsory`:
    no options → one **group** row; options → one **subgroup** row **per option that at least one
    student chose**, with that option's head-count.
  - `student_count` = `sch_class_section_jnt.actual_total_student` if > 0, else the live count.
  - `class_house_room_id` = the section's home room, else the first active room.
  - Code pattern: `{SUBJECT}-C{class:3}-S{section:2}[-{OPTION}]-{TYPE}-{FORMAT}`.
- **Column mapping (both tables):** `class_group_id` = `sch_class_groups_jnt.id` · `class_id`,
  `section_id`, `subject_id`, `study_format_id`, `subject_type_id`, `subject_study_format_id`
  copied · subgroup adds `subject_study_format_option_id`, `option_key`,
  `is_shared_across_sections`, `is_shared_across_classes`, `share_pool_json` (sharing set by hand
  on the Groups tab, and **wiped** by this button).

### [2] Generate Requirements — `POST timetable-foundation/requirement-consolidation/generate-requirements/generate`

`RequirementConsolidationController::generateRequirements()` (`.../RequirementConsolidationController.php:1181`)

- **Input:** `academic_term_id`, `timetable_type_id` chosen in the form.
- **Reads:** `tt_class_requirement_groups`, `tt_class_requirement_subgroups`, each with its parent
  `sch_class_groups_jnt` (the rules).
- **Writes:** `tt_requirement_consolidations` (upsert on
  `class_requirement_group_id, class_requirement_subgroup_id, academic_term_id, timetable_type_id`).
- **Column mapping** (`mapGroupToRequirement`, `:1452`; `mapSubgroupToRequirement`, `:1533`):

| `tt_requirement_consolidations` column | Comes from |
|---|---|
| `class_requirement_group_id` | ⚠ **`sch_class_groups_jnt.id`** (the FK points there, not at `tt_class_requirement_groups`) — set for group rows, NULL for subgroup rows |
| `class_requirement_subgroup_id` | `tt_class_requirement_subgroups.id` — subgroup rows only |
| `subject_study_format_option_id`, `is_shared_across_sections/classes` | subgroup |
| `class_id`, `section_id`, `subject_*`, `class_house_room_id`, `student_count` | group / subgroup |
| `required_weekly_periods`, `min/max_periods_required_per_week` | `sch_class_groups_jnt.required/min/max_weekly_periods` |
| `min_periods_required_per_day` | `min_daily_periods` |
| `max_periods_required_per_day` | `max_daily_periods`, made feasible for the weekly count |
| `min_gap_between_periods`, `allow_consecutive_periods`, `max_consecutive_periods` | same-named columns |
| `class_priority_score` | `priority_score` (default 50) |
| `compulsory_specific_room_type`, `required_room_type_id` (default 1), `required_room_id` | `sch_class_groups_jnt` |
| `eligible_teacher_count` | hard-coded 1 (TODO in code) |
| `academic_term_id`, `timetable_type_id` | the form |

  The user can edit these rows afterwards on the Requirement Consolidation tab. **Those edits are
  lost the next time this button (or any earlier one) runs.**

### [3] Generate Teacher Availability — `POST timetable-foundation/teacher-availability/generate`

`TeacherAvailabilityController::generateTeacherAvailability()` (`.../TeacherAvailabilityController.php:56`)

- **Reads:** `tt_requirement_consolidations`; `sch_teacher_capabilities` (`:216`) filtered by
  `class_id`, `subject_study_format_id`, `is_active`, today within `effective_from/to`, and an
  **active** `sch_teacher_profile`; `tt_shifts`; `sch_subject_study_format_options.subject_id`
  (an option is taught by whoever can teach its real subject, any format).
- **Writes:** `tt_teacher_availabilities`; also upserts `PRIMARY` and `ASSISTANT` rows in
  `tt_teacher_assignment_roles`.
- **Logic:** for each requirement, one row **per eligible teacher** (best first: primary subject,
  then proficiency). No eligible teacher → one row with `teacher_profile_id = NULL` (shows as
  "unassigned" in the readiness checks).
- **Column mapping:** `requirement_consolidation_id`, `class_id`, `section_id`,
  `subject_study_format_id`, `required_weekly_periods` from the requirement ·
  `teacher_profile_id` + every limit (`max/min_available_periods_weekly`,
  `max/min_allocated_periods_weekly`, `is_full_time`, `certified_for_lab`, …) **copied** from
  `sch_teacher_profile` · `proficiency_percentage`, `is_primary_subject`, `priority_order`, … copied
  from `sch_teacher_capabilities`. A teacher profile edited later is **not** seen until this is re-run.

### [4] Generate Activities — `POST timetable-foundation/requirements/generate-activities/all`

`ActivityController::generateActivities()` (`.../ActivityController.php:157`)

- **Reads:** current `sch_org_academic_sessions_jnt`; the first active `tt_timetable_types`;
  `tt_requirement_consolidations` with `sch_class_groups_jnt` / `tt_class_requirement_subgroups`;
  `tt_teacher_availabilities` (candidates); `sch_teacher_profile` + `sch_teachers` (profile →
  teacher id via `user_id`); `sch_rooms` / `sch_rooms_type` (capacity, for shared pools);
  `tt_constraints` (global count, for a difficulty score).
- **Writes:**

| Table | One row per | Key columns written |
|---|---|---|
| `tt_activities` | lesson stream: class-section × subject-format (or one shared pool) | `code` (`ACT-CG-{group code}-T{term}-TT{type}`, `:309`; shared `ACT-SAC-`/`ACT-SAS-`; subgroup `ACT-SG-`), `class_group_id` → **`sch_class_groups_jnt.id`**, `class_subgroup_id` → `tt_class_requirement_subgroups.id`, `class_id`, `section_id` (NULL on shared/option lessons), `subject_id`, `study_format_id`, `subject_study_format_id`, `subject_type_id`, `required_weekly_periods`, `weekly_periods`, `min/max_periods_per_week`, `min/max_per_day`, `min_gap_periods`, `allow_consecutive`, `max_consecutive`, `duration_periods`, `priority` (= `class_priority_score`), `required_room_type_id`, `required_room_id`, `preferred_room_ids` (NULL — hand edits are lost on regenerate), `academic_term_id`, `timetable_type_id` |
| `tt_activity_teachers` | activity × candidate teacher (`assignTeacherToActivity`, `:1403`) | `activity_id`, `teacher_id` → **`sch_teachers.id`**, `assignment_role_id`, `ordinal`, `is_required` |
| `tt_sub_activities` | student group of a shared / optional lesson (`:921`) | `parent_activity_id`, `class_requirement_subgroup_id`, `class_id`, `section_id`, `student_count`, `ordinal` |
| `tt_sub_activity_members` | cohort inside a group | `sub_activity_id`, `class_requirement_subgroup_id`, `class_id`, `section_id`, `student_count` |
| `tt_sub_activity_details` | weekly period of a sub-activity | written by `SubActivityObserver` → `SubActivityDetailSeeder` (`Services/SubActivityDetailSeeder.php:131`) |

- **Logic, in three steps:** STEP 2 one activity per class-group requirement; STEP 1.5 shared
  subject pools (subgroups flagged shared, grouped by `share_pool_json`) become **one** activity with
  sub-activity groups packed by `SubActivityGrouper` (fewest groups that fit the room, with the
  `tt_configs` overflow allowance); STEP 3 (`:974`) the remaining non-shared subgroups get their
  own `ACT-SG-` activities.

### [5] Generate Slot Requirement — `POST timetable-foundation/slot-requirement/generate`

`SlotRequirementController::generateSlotRequirement()` (`.../SlotRequirementController.php:60`)

- **Reads:** `tt_class_timetable_types_jnt`, `tt_period_sets` (teaching periods), `tt_school_days`,
  `sch_class_section_jnt`.
- **Writes:** `tt_slot_requirements` (`class_id`, `section_id`, `class_timetable_type_id`,
  `weekly_total_slots`, `weekly_teaching_slots`, `weekly_exam_slots`, `weekly_free_slots`,
  `class_house_room_id`).
- ⚠ **Neither engine reads this table.** Only the Slot Requirements tab, the ratio pages and the
  readiness pipeline count do (§E).

### [6] Room Availability — `POST timetable-foundation/room-availability/generate`

`RoomAvailabilityService::generate()` reads `sch_rooms`, `sch_class_section_jnt`, `tt_activities`
and writes `tt_room_availabilities`. **0 rows on the test DB** (never run there), and not read by
either engine.

---

## A3. Pre-generation reports and their tables

### A3.1 `/timetable-foundation/timetable-requirement` — 7 tabs (`timetableRequirement`, `:589`)

| Tab | Shows | Tables |
|---|---|---|
| Class Subject Requirements | the rows typed by hand + option breakdown + staffing per option | `sch_class_groups_jnt`, `sch_subject_study_format_options`, `std_student_opted_subjects`, `std_student_academic_sessions`, `tt_requirement_consolidations`, `tt_teacher_availabilities` (`OptionStaffingService`) |
| Generated Groups | groups + subgroups, sharing toggles, share pools, parallel-fit warnings | `tt_class_requirement_groups`, `tt_class_requirement_subgroups`, `sch_class_section_jnt`, `sch_rooms` |
| Requirement Consolidations | the rules per requirement | `tt_requirement_consolidations` + masters |
| Teacher Availability | candidate pool per requirement | `tt_teacher_availabilities`, `sch_teacher_profile` |
| Activities | activities + teachers + sub-activities | `tt_activities`, `tt_activity_teachers`, `tt_sub_activities`, `tt_sub_activity_members` |
| Slot Requirements | weekly slot grid per class-section | `tt_slot_requirements`, `tt_class_timetable_types_jnt`, `tt_period_sets`, `tt_period_set_periods_jnt`, `tt_period_configs`, `tt_period_types`, `tt_school_days`, `sch_academic_term` (`SlotRequirementGridService`) |
| **Pre-Generation Checks** | the readiness report (below) | see A3.2 |

### A3.2 Pre-Generation Checks = `GenerationReadinessReportService` (`Services/GenerationReadinessReportService.php:61`)

| Section | Tables | Logic |
|---|---|---|
| Pipeline (`pipeline()`, `:988`) | `sch_class_groups_jnt`, `tt_class_requirement_groups`, `tt_requirement_consolidations`, `tt_teacher_availabilities`, `tt_activities`, `tt_slot_requirements` | row count per stage; a 0 locks the later tabs |
| Grid pressure | `tt_school_days`, `tt_class_timetable_types_jnt`, `tt_period_sets`, `tt_activities`, `sch_rooms`, `ActiveTeachers` (active `sch_teacher_profile`) | demand (Σ `required_weekly_periods`) vs capacity (teaching periods × days); per-period teacher / room headroom |
| Subject teacher supply | `sch_teacher_capabilities`, `sch_teacher_profile`, `sch_subject_study_format_jnt`, `sch_subjects`, `tt_activities` | risk `none` / `over` / `single` / `tight` / `ok` |
| Class demand vs capacity | `tt_activities` + grid | per class-section |
| Room-type supply | `sch_rooms`, `sch_rooms_type`, `tt_activities` | per room type |
| Optional subjects in one period | **runs the full `ProblemExporter::exportForTerm()`** (`:520`) | option-block feasibility (waves, room clashes) |
| Class-teacher coverage | `sch_class_section_jnt`, `sch_teachers`, `sys_users`, `sch_teacher_profile`, `sch_teacher_capabilities`, `tt_activities`, `tt_activity_teachers` | flags `unassigned` / `no_teacher_row` / `no_capability` / `never_teaches` / `short` |
| Past runs | `tt_generation_runs` | last 6 runs (post-generation data shown on a pre page) |

⚠ Because it calls the exporter, **opening this tab writes `tt_activity_priorities`**
(`ProblemExporter.php:2060`). It is a "read" page with a side-effect.

### A3.3 `/timetable-foundation/resource-availability` — 6 tabs (`resourceAvailability`, `:2072`)

| Tab | Tables |
|---|---|
| Teacher Availability | `tt_teacher_availabilities`, `sch_teacher_profile`, `sch_classes`, `sch_sections` |
| Teacher Availability Ratio | `ResourceRatioService`: `tt_teacher_availabilities`, `tt_activities`, `sch_teacher_profile`, `sch_employees`, `sch_departments`, `sys_users`, `tt_slot_requirements`, `tt_working_days`, `tt_school_days`, `tt_period_set_periods_jnt`, `tt_period_types`, `tt_class_timetable_types_jnt` |
| Teacher Slot Matrix | `tt_teacher_availability_details` ⚠ **written by generation** (§B3), so empty until a timetable is generated |
| Room Availability | `tt_room_availabilities`, `sch_rooms`, buildings |
| Room Availability Ratio | `ResourceRatioService`: `sch_rooms`, `sch_rooms_type`, `tt_room_availabilities`, `tt_activities` |
| Room Slot Matrix | `tt_room_availability_details` — **always empty**: generation deliberately skips the room canvas (schema conflict, `TimetableStorageService.php:757`) |

### A3.4 `/timetable-foundation/timetable-preparation` — 4 tabs (`timetablePreparation`, `:2369`)

| Tab | Tables |
|---|---|
| Dashboard | `tt_activities`, `tt_activity_teachers`, `sch_teachers`, `tt_school_days`, `tt_period_sets`, `tt_class_timetable_types_jnt`, `sch_class_section_jnt`, `sch_rooms`, `tt_timetables` |
| Activities | `tt_activities` + masters |
| Activity Teachers | `tt_activity_teachers`, `sch_teachers`, locks via `ActivityLockService` (`sch_class_section_jnt`, `tt_activity_teachers`) |
| Generator Inputs | `tt_activities`, `tt_sub_activities`, `tt_sub_activity_details`, `tt_class_timetable_types_jnt`, period set periods |

### A3.5 `/smart-timetable/timetable-reports` — the planning parts (`TimetablePageController::timetableReports`, `:713`)

Two blocks of this page are **pre-generation data** even though the page is called Reports:
- **Class Coverage** (`:904`): `tt_activities` ⋈ `sch_classes` ⋈ `sch_sections`, Σ `required_weekly_periods` vs periods per week.
- **Activity Teacher Capacity**: `tt_activities` vs `tt_teacher_availabilities` ⋈ `sch_teacher_profile` ⋈ `sys_users`.

The rest of the page is post-generation (§C2).

---

# PART B — GENERATION

## B0. Entry points

| Engine | Route | Controller |
|---|---|---|
| Python (FET port) | `POST smart-timetable/python-timetable/generate` | `PythonTimetableController::generate()` (`SmartTimetable/app/Http/Controllers/PythonTimetableController.php:202`) |
| Python save | `POST smart-timetable/python-timetable/store` | `PythonTimetableController::store()` (`:3095`) |
| PHP "Prime" | `POST smart-timetable/generate/generate-prime` | `TimetableGenerationController::generateWithPrime()` (`.../TimetableGenerationController.php:538`) → `TimetableGenerationService::generate()` (`SmartTimetable/app/Services/TimetableGenerationService.php:39`) → `PrimeSolver` |
| PHP save | `POST smart-timetable/store` | `TimetableGenerationController::storeTimetable()` |
| Publish | `POST smart-timetable/timetable/{id}/publish` | `TimetablePublishController` → `TimetableStorageService::publishTimetable()` (`:874`) |

## B1. Python engine — what is fetched, from where

`ProblemExporter::exportForTerm($termId, $typeId, $slack)` (`TimetableFoundation/app/Services/ProblemExporter.php:75`)
is **the only reader** for the Python engine. It builds one self-contained JSON; Python never
touches the database.

| Payload part | Tables and columns |
|---|---|
| `timetable_type` | `tt_timetable_types` (`id`, `code`, `name`, `school_start_time`, `school_end_time`) |
| `days` | `tt_school_days` (active school days) |
| `hours` (master grid) | `tt_class_timetable_types_jnt` → `tt_period_sets` (the **widest** set) → `tt_period_set_periods_jnt` → `tt_period_configs` + `tt_period_types` (`counts_as_teaching`) |
| `class_sections` | `tt_class_timetable_types_jnt` × active `sch_class_section_jnt` × `sch_classes` × `sch_sections`; class teacher `sch_class_section_jnt.class_teacher_id` → `sch_teachers.user_id` → `sys_users`; per-class allowed periods from its own period set |
| teacher limits | `sch_teacher_profile.max_available_periods_weekly` (HARD) and `min/max_allocated_periods_weekly` (soft), joined to `sch_teachers` on `user_id` |
| `teachers` | `sch_teachers` ⋈ `sys_users` for every teacher on `tt_activity_teachers` |
| `rooms` | `sch_rooms` (active, not deleted): `id`, `room_type_id`, `capacity` |
| `activities` (`:562`) | `tt_activities` (active, this term) with class, section, subject, studyFormat, subjectType, **teachers** (`tt_activity_teachers`); `tt_sub_activities` + `tt_sub_activity_members`; `tt_class_requirement_subgroups` (cohort → `class_group_id`); option blocks from `sch_subject_study_format_options` + subgroups. One exported lesson **per weekly occurrence** |
| teacher choice | the exporter **picks one teacher per lesson** from the `tt_activity_teachers` pool, respecting the hard weekly limit and the class-teacher reservation (`ActivityLockService`: `sch_class_section_jnt`, `sch_teachers`, `tt_activity_teachers`). Lessons nobody can take go to `left_out_lessons` |
| priorities | `ActivityPriorityCalculator` → **written** to `tt_activity_priorities` (`:2060`) |
| `constraints` | `ConstraintCompiler::compile()` (`Services/ConstraintCompiler.php:103`): `tt_constraints` ⋈ `tt_constraint_types` (break times, teacher not available, free period per half, activity time window, room capacity limit) |
| `parallel_groups` | `tt_constraints` of the parallel-periods type, matched to activities by **code** |
| overflow allowance | `tt_configs.max_students_allowed_over_room_capacity` |
| "Keep locked from timetable" | `LockedCellPins` (`SmartTimetable/app/Services/Python/LockedCellPins.php:53`): locked `tt_timetable_cells` + `tt_timetable_cell_teachers` of the chosen earlier timetable, `tt_school_days` |

Then `PythonRunner` writes the payload to a file, runs the solver as a separate process and polls
it; live progress goes to the **cache**, not the DB (`GenerationProgress`). `SolutionAdapter`
turns the solver output into a `GenerationResult`.

## B2. PHP "Prime" engine — what is fetched, and how it differs

`TimetableGenerationService::generate()` reads the same families of tables directly, through
Eloquent:

| Step | Tables |
|---|---|
| ⚠ class-teacher auto-assign (`:59`, `ClassTeacherAutoAssigner`) | reads `sch_class_section_jnt`, `sch_teacher_capabilities`, `sch_teacher_profile`, `tt_activities`; **WRITES `tt_activity_teachers`** (replaces the primary teacher with the class teacher) — before generating |
| class sections, limits, windows | `sch_class_section_jnt`, `tt_class_timetable_types_jnt`, `tt_period_set_periods_jnt`, `tt_period_configs` |
| activities | `tt_activities` (term) + teachers + `tt_sub_activities` / members + `tt_class_requirement_subgroups` |
| days / periods | `tt_school_days` (school days), `tt_period_set_periods_jnt` |
| teacher caps | `tt_teacher_availabilities`, `sch_teacher_profile`, `sch_teachers` |
| constraints | `tt_constraints` via `DatabaseConstraintService` |
| rooms | `sch_rooms` + `sch_rooms_type` |
| roles | `tt_teacher_assignment_roles` |

Differences that matter: the PHP engine **mutates pre-generation data** (`tt_activity_teachers`)
while the Python engine does not; parallel groups are passed as an empty set; the PHP engine
derives its own daily caps and does **not** read `tt_slot_requirements` either.

## B3. Tables written by generation (both engines, via `TimetableStorageService`)

Both engines finish in `SmartTimetable/app/Services/Storage/TimetableStorageService.php`.

| Step | Table | What is written |
|---|---|---|
| `createSkeleton()` (`:50`) | `tt_timetables` | one row: `code` `TT_{date}_{rand}`, `name`, `academic_session_id`, `academic_term_id`, `timetable_type_id`, `period_set_id`, `effective_from`, `generation_method`, `status = GENERATING`, `is_active = 0` |
| | `tt_generation_runs` | one row: `timetable_id`, `run_number`, `started_at`, `status = RUNNING`, `algorithm_version`, `params_json`, `triggered_by` |
| `insertSkeletonCells()` (`:112`) | `tt_timetable_cells` | **one EMPTY cell per active day × teaching period × class_group / class_subgroup** in scope. Owners: every `class_group_id` on the term's activities, plus, for shared activities, the members' subgroups' `class_group_id`. Test DB: **29,812 cells per timetable** |
| `populateFromResult()` (`:273`) | `tt_timetable_cells` | the placed cell gets `activity_id`, `sub_activity_id`, `room_id`, `source`, `is_active = 1`. Force-placed cells: `is_active = 0`, `has_conflict = 1`, `conflict_details_json`. Test DB: **2,247 placed of 29,812** |
| | `tt_timetable_cell_teachers` | `cell_id`, `teacher_id` (→ `sch_teachers`), `assignment_role_id`, `is_substitute = 0` — clean placements only |
| | `tt_generation_runs` | `finished_at`, `status = COMPLETED`, `activities_total/placed/failed`, `hard/soft_violations`, `soft_score`, `stats_json` |
| | `tt_timetables` | `status = GENERATED`, `constraint_violations`, `soft_score`, `stats_json` (cells created, coverage %, placed, conflicts, diagnostics) |
| `rebuildAvailabilityCanvas()` (`:757`) | `tt_teacher_availability_details` | teacher × day × period grid marked with assigned class / subject (feeds Teacher Slot Matrix). Room canvas **skipped** |
| Lock carry-over | `tt_timetable_cells.is_locked` | on the new draft (`LockedCellPins::lockInDraft`) |
| Publish (`:874`) | `tt_timetables` | `status = PUBLISHED`, `is_active = 1`, `published_at/by`; other active timetables in the **same session + term + type + period set** → `ARCHIVED`. Writes **no** `tt_timetable_assignment` row |

Every generate keeps its draft (each run = a new `tt_timetables` row; 26 on the test DB, one run each).

### B4. The cell: how a cell finds its class, subject, teacher and room

`tt_timetable_cells` has **no `class_id`, `section_id` or `subject_id`**. Every reader resolves them:

```
 tt_timetable_cells
   ├─ timetable_id ───────────► tt_timetables (session, term, type, period_set, status)
   ├─ day_of_week ────────────► tt_school_days.day_of_week
   ├─ period_ord ─────────────► tt_period_set_periods_jnt.period_ord (of the timetable's / class's period set)
   │                               └─► tt_period_configs (start_time, end_time)
   ├─ activity_id ────────────► tt_activities ──► class_id, section_id, subject_id, study_format_id
   ├─ class_group_id ─────────► sch_class_groups_jnt ──► class_id, section_id, subject_study_format_id
   ├─ class_subgroup_id ──────► tt_class_requirement_subgroups ──► class_id, section_id, option
   ├─ sub_activity_id ────────► tt_sub_activities ──► tt_sub_activity_members (cohorts of a shared lesson)
   ├─ room_id ────────────────► sch_rooms ──► sch_rooms_type
   ├─ generation_run_id ──────► tt_generation_runs
   └─ id ◄── tt_timetable_cell_teachers.cell_id ──► teacher_id ──► sch_teachers ──► sys_users (name)
```

The cell's **owner** (which class-section it belongs to) is resolved by
`OptionCellResolver::owners()` (`TimetableFoundation/app/Services/OptionCellResolver.php:214`):
shared and option lessons carry `section_id = NULL` on the activity, so the owner falls back to
the cell's own `class_group_id` / `class_subgroup_id`. Reports that key only on the activity's
section pool those lessons under a phantom "class-0" row.

---

# PART C — AFTER GENERATION

## C1. Post-generation tables

| Table | Rows (test) | Meaning |
|---|---:|---|
| `tt_timetables` | 26 (23 GENERATED, 3 PUBLISHED) | one per generated draft |
| `tt_generation_runs` | 26 | one per run |
| `tt_timetable_cells` | 89,436 (3 timetables × 29,812) | skeleton + placements |
| `tt_timetable_cell_teachers` | 6,741 | teacher per placed cell (3 × 2,247) |
| `tt_teacher_availability_details` | 3,648 | teacher slot canvas from the latest run |
| `tt_activity_priorities` | 576 | priority scores from the latest export |
| `tt_change_logs` | 0 | manual edit audit (workspace) |
| `tt_substitution_logs`, `tt_teacher_absences` | 0 / 0 | substitution |
| `tt_constraint_violations`, `tt_conflict_detection`, `tt_teacher_workloads`, `tt_resource_bookings` | 0 | built, never written on this tenant |
| `tt_timetable_assignment` | 1 | which timetable a class-section sees on a date (set on the Assignment page, not by publish) |

## C2. Post-generation reports — where the data comes from

### C2.1 `/timetable-foundation/reports-and-logs` — 5 tabs (`reportsAndLogs`, `:3022`)

| Tab | Tables and joins | Notes |
|---|---|---|
| Timetables | `tt_timetables` ⋈ `sch_academic_term`, `tt_timetable_types` | list + filters |
| Class Reports | `tt_timetable_cells` (active, one timetable) → `tt_activities` (subject) and **owner** via `OptionCellResolver::owners()` (`:3117`) → `sch_class_section_jnt`, `sch_classes`, `sch_sections`, `sch_subjects`; weekly grid by `TimetableGridService` | periods counted as **distinct slots** per class-section |
| Teacher Reports | `tt_timetable_cells` ⋈ `tt_timetable_cell_teachers` (`COUNT(DISTINCT period_ord)` per teacher per day) → `sch_teachers` → `sys_users`; capabilities `sch_teachers` ⋈ `sch_teacher_profile` (`user_id`) ⋈ `sch_teacher_capabilities` | default timetable = first one that has cells |
| Room Reports | `tt_timetable_cells.room_id` → `sch_rooms` ⋈ buildings ⋈ `sch_rooms_type` | |
| Optimisation Report | `SchoolOptimisationReportService` (below) | salary-free tab; full version URL-only |

**Weekly grids** (`TimetableGridService`, `Services/TimetableGridService.php`): skeleton from
`tt_timetables` → `tt_period_set_periods_jnt` → `tt_period_configs` + `tt_period_types`,
`tt_school_days`; cells from `tt_timetable_cells` ⋈ `tt_activities` ⋈ `sch_subjects` /
`sch_classes` / `sch_sections` ⋈ `sch_rooms` ⋈ `tt_timetable_cell_teachers` ⋈ `sch_teachers` ⋈
`sys_users`; per-class period set from `tt_class_timetable_types_jnt`.

**Optimisation Report** (`Services/SchoolOptimisationReportService.php`) mixes the generated
timetable with **live** planning data:

| Section | Tables |
|---|---|
| timetable + grid shape | `tt_timetables`, `tt_timetable_cells`, `tt_timetable_cell_teachers`, `tt_activities`, `sch_subjects` |
| teachers + skills | `sch_teachers`, `sch_teacher_profile`, `sch_employees`, `sys_users`, `sch_teacher_capabilities`, `sch_subject_study_format_jnt`, `sch_subjects`, `sch_classes`, `sch_study_formats` |
| class windows | `tt_class_timetable_types_jnt`, `tt_period_sets`, `tt_period_set_periods_jnt`, `tt_period_types` |
| rooms / classes | `sch_rooms`, `sch_rooms_type`, `sch_class_section_jnt` |
| coverage | `tt_activities`, `tt_activity_teachers`, `tt_requirement_consolidations`, `tt_teacher_availabilities`, `sch_subject_study_format_options`, … |
| unplaced / options | `tt_activities`, `tt_sub_activities`, `tt_sub_activity_members` |
| school name | `sch_organizations` |

### C2.2 `/smart-timetable/timetable-reports` — post-generation parts (`TimetablePageController::timetableReports`, `:713`)

| Block | Tables | Logic |
|---|---|---|
| Summary / quality | `tt_timetables` (`quality_score`, `soft_score`, `room_utilization_score`, `constraint_violations`, `stats_json`) ⋈ type, term, session, period set | selected = `?timetable_id`, else latest PUBLISHED, else latest GENERATED |
| Teacher Load | `tt_timetable_cell_teachers` ⋈ `tt_timetable_cells` (selected timetable) → `sch_teachers` ⋈ `sys_users`, subjects | ratio vs `max_periods_per_week` (default 36) |
| Room Utilisation | `tt_timetable_cells.room_id` counts vs all active `sch_rooms` (first 50) | periods per week = active school days × teaching periods of the period set |

### C2.3 `/smart-timetable/analytics` (`AnalyticsService`)

All tabs (workload, utilisation, violations, distribution) read `tt_timetable_cells` with
`activity.subject`, `activity.class`, `activity.section`, `teachers.user`, and
`tt_timetables` → `periodSet.periods`. Distribution keys on the **activity's** section, so shared
and option lessons are not attributed to a class-section here.

### C2.4 Preview, workspace, manual edits

| Screen | Tables read | Tables written |
|---|---|---|
| `/smart-timetable/preview/{timetable}` (workspace) | `tt_timetable_cells`, `tt_timetable_cell_teachers`, `tt_activities`, `tt_period_set_periods_jnt`, `tt_class_timetable_types_jnt`, `sch_class_groups_jnt`, `tt_class_requirement_subgroups`, `sch_teachers`, `sch_teacher_profile`, `sys_users`, `sch_rooms` (`WorkspaceContext`) | — |
| `/smart-timetable/preview/{timetable}/all-classes` | `PreviewGridState` / `PreviewDerivedData`: cells, cell teachers, activities, sub-activities + members, subgroups | — |
| move / place / remove / lock cell | | `tt_timetable_cells`, `tt_timetable_cell_teachers` |

### C2.5 Substitution (`SubstitutionService`)

Reads the **live** timetable (`Timetable` published / assignment), `tt_timetable_cells`,
`tt_timetable_cell_teachers`, `tt_activities`, `sch_teacher_capabilities`, `sch_teacher_profile`,
`sch_teachers`, `sch_subject_study_format_jnt`, `sch_holidays`, `tt_school_days`. Writes
`tt_teacher_absences`, `tt_substitution_logs`, and substitute rows in `tt_timetable_cell_teachers`
(`is_substitute = 1`).

## C3. Other modules that read the generated timetable

`PublishedTimetable::idFor()` (`TimetableFoundation/app/Services/PublishedTimetable.php:137`)
decides **the one timetable** a class-section sees on a date: `tt_timetable_assignment`
(`ClassTimetableResolver`), else the published one in the student's session.

| Module | Reads |
|---|---|
| StudentPortal (web + mobile) | `PublishedTimetable` → `tt_timetable_cells` + teachers |
| ParentPortal (web + mobile) | same |
| TeacherPortal | `TeacherScheduleService`, `TeacherContext`: cells by `tt_timetable_cell_teachers.teacher_id` |
| SchoolSetup | `Teacher` / `Room` models, mobile admin timetable |
| Syllabus | `PeriodsAllocationService`: the published timetable's cells → lesson dates |
| Dashboard | `TimetableSuggestionService`: published timetable only |
| StandardTimetable | manual placement writes the same `tt_timetable_cells` |

---

# PART D — DELETE IMPACT

There are three ways data disappears: **(1) a master row is deleted** (FK cascade),
**(2) a Generate button truncates** (no cascade, no undo), **(3) a live table changes under an
old timetable** (nothing deleted, but the report reads differently).

## D1. Regeneration wipes generated timetables (the biggest risk)

| You press | Requirement tables emptied | Generated timetables |
|---|---|---|
| Generate Groups / Reset All | all six stages | **all cells of all timetables deleted** |
| Generate Requirements | consolidations onward | **all cells deleted** |
| Generate Teacher Availability | TA onward | **all cells deleted** |
| Generate Activities | activities onward | **all cells deleted** |
| Generate Slot Requirement | slot req + priority config | untouched |
| Room Availability | (upsert, no truncate) | untouched |

What survives: `tt_timetables` header rows (name, status, `stats_json`), `tt_generation_runs`,
`tt_change_logs` (with `cell_id` set to NULL by hand). What is lost: every cell, every cell teacher,
every substitution log. A PUBLISHED timetable stays PUBLISHED with **zero cells**: the student,
parent and teacher portals then show an empty week.

**Evidence on `test.localhost` today:** `tt_activities` was regenerated at 12:21:21. Timetables
created before that (ids 1–24, including **published timetables 4 and 17**) have **0 cells**;
only 25, 26 (published) and 27, generated afterwards, have their 29,812 cells. 23 of 26
timetables are empty headers.

## D2. Deleting master rows — FK cascades into the timetable

From the live FK definitions (`information_schema`, test DB). **CASCADE** = rows deleted with the
parent; **SET NULL** = link cut; **NO ACTION / RESTRICT** = the delete is refused while rows exist.

| Deleting a row in… | Effect on generated timetables | Effect on requirement data |
|---|---|---|
| `sch_class_groups_jnt` (a Class Subject Requirement) | **CASCADE: deletes its `tt_timetable_cells`** (`class_group_id`) in every timetable | CASCADE `tt_requirement_consolidations`; SET NULL `tt_activities.class_group_id`, `tt_class_requirement_subgroups.class_group_id`. ⚠ `tt_class_requirement_groups.class_group_id` has **no FK**, so its group rows are left pointing at a missing id |
| `tt_class_requirement_subgroups` | **CASCADE: deletes its cells** (`class_subgroup_id`) | CASCADE consolidations, `tt_class_subgroup_members`; SET NULL `tt_activities.class_subgroup_id` |
| `sch_subject_study_format_options` (an option) | indirect: CASCADE subgroups → their cells | CASCADE subgroups and consolidations |
| `sch_teachers` (a teacher) | **CASCADE: deletes its `tt_timetable_cell_teachers`** (cells stay, teacher-less), `tt_substitution_logs`, `tt_teacher_absences`, `tt_teacher_workloads` | CASCADE `tt_activity_teachers`; SET NULL `tt_activities.locked_teacher_id`; NO ACTION on `tt_teacher_unavailabilities`, `tt_resource_bookings` |
| `sch_teacher_profile` | — | SET NULL `tt_teacher_availabilities.teacher_profile_id` (becomes "unassigned"); NO ACTION on details |
| `sch_rooms` | SET NULL `tt_timetable_cells.room_id` (lesson keeps its slot, loses its room) | NO ACTION on class groups' required room, room availability; CASCADE `tt_room_unavailabilities` |
| `sch_rooms_type` | — | NO ACTION on groups, room availability; SET NULL `tt_activities.preferred_room_type_id` |
| `sch_classes` / `sch_sections` | — (refused while referenced) | NO ACTION almost everywhere; CASCADE only `tt_class_subgroup_members` |
| `sch_subjects`, `sch_study_formats` | — | SET NULL on `tt_activities` |
| `sch_subject_study_format_jnt` | — | NO ACTION (refused) |
| `sch_academic_term` | — | NO ACTION / RESTRICT on activities, constraints, mappings (refused); SET NULL on consolidations, assignment |
| `sch_org_academic_sessions_jnt` | **CASCADE: deletes `tt_timetables`** of that session → CASCADE cells, runs, violations, change logs | CASCADE `tt_teacher_workloads` |
| `tt_activities` | SET NULL `tt_timetable_cells.activity_id` (cell loses its subject; class grids drop it) | CASCADE activity teachers, sub-activities, details, parallel-group links; NO ACTION slot req / availability rows |
| `tt_sub_activities` | SET NULL `tt_timetable_cells.sub_activity_id` (shared lesson loses its cohort) | CASCADE members, details |
| `tt_timetables` | CASCADE cells (→ cell teachers, substitution logs), runs, violations, change logs; SET NULL workloads, children's `parent_timetable_id`; NO ACTION `tt_timetable_assignment`, `tt_conflict_detection` | — |
| `tt_period_sets` | — (refused: timetables and mappings reference it) | CASCADE its period rows |
| `tt_timetable_types` | — (refused) | SET NULL consolidations |
| `tt_constraints` | — | CASCADE violations, room unavailabilities; NO ACTION teacher unavailabilities |

⚠ Most models use **soft delete** (`deleted_at`), which fires no FK action at all: the row stays,
and readers filter it out. A soft-deleted `sch_class_groups_jnt` row keeps its cells in the
database but drops out of every report that filters `whereNull('deleted_at')` on the join.

## D3. Changing live tables under an old timetable (nothing deleted, report changes)

A cell stores ids only, so every post-generation report re-reads today's master and planning data:

| Change made after generating | What changes in the old timetable's reports |
|---|---|
| rename / re-type a subject, room, class or teacher | old timetable shows the new names |
| deactivate a room (`is_active = 0`) | Room Utilisation only lists active rooms; the cell keeps its `room_id` |
| change a period set / period config times | old grids show the new times; a removed period row hides its cells |
| set a school day inactive | grids drop that day's cells |
| deactivate a class-section / change `tt_class_timetable_types_jnt` | class grids lose or re-shape that section |
| regenerate activities, consolidations, availabilities | Optimisation Report coverage / unplaced / options sections read the **new** planning rows against the **old** cells (and the cells are gone anyway, D1) |
| delete an activity | cells keep the slot but lose subject and class (`activity_id` NULL) |
| edit `sch_teacher_profile` limits | Teacher Load % changes for old timetables |

There is **no snapshot** of a timetable's planning data. A per-timetable archive was planned
(v3, `prime_info/timetable-archive/00-PLAN.md`, 12 Sep 2026) but is not built.

## D4. Deleting a timetable

`SmartTimetableController::destroy()` (`:1009`) refuses a PUBLISHED timetable, then
**hard-purges** its children (`TimetableStorageService::purgeChildrenOf()`, `:718`: cells, cell
teachers, runs, conflict detections, change logs, workloads, violations) and soft-deletes the
header. Restoring it from Trash brings back an **empty** header. Force delete does the same and
removes the header.

## D5. Checklist — tables whose data the timetable view depends on

**Delete or regenerate these and generated timetables lose cells or meaning:**

| Group | Tables |
|---|---|
| Requirement pipeline (regenerating truncates cells) | `tt_class_requirement_groups`, `tt_class_requirement_subgroups`, `tt_class_subgroup_members`, `tt_requirement_consolidations`, `tt_teacher_availabilities`, `tt_activities`, `tt_activity_teachers`, `tt_sub_activities`, `tt_sub_activity_members`, `tt_sub_activity_details`, `tt_activity_priorities`, `tt_parallel_group_activity` |
| Requirement source (FK cascade to cells) | `sch_class_groups_jnt`, `sch_subject_study_format_options` |
| Grid (cells disappear from view) | `tt_school_days`, `tt_period_sets`, `tt_period_set_periods_jnt`, `tt_period_configs`, `tt_period_types`, `tt_class_timetable_types_jnt`, `tt_timetable_types` |
| Who / where (labels, teachers, rooms) | `sch_teachers` (cascade cell teachers), `sch_teacher_profile`, `sys_users`, `sch_rooms` (room cut), `sch_rooms_type`, `sch_class_section_jnt`, `sch_classes`, `sch_sections`, `sch_subjects`, `sch_study_formats`, `sch_subject_study_format_jnt` |
| Scope | `sch_academic_term`, `sch_org_academic_sessions_jnt` (cascade whole timetables) |
| The output itself | `tt_timetables`, `tt_timetable_cells`, `tt_timetable_cell_teachers`, `tt_generation_runs`, `tt_timetable_assignment` (which timetable a class sees) |

**Safe to delete / regenerate without touching a generated timetable:** `tt_slot_requirements`,
`tt_priority_configs`, `tt_room_availabilities`, `tt_room_availability_details`,
`tt_teacher_availability_details` (rebuilt by the next generation; only the Teacher Slot Matrix
tab empties), `tt_working_days`, `tt_class_working_days_jnt`, `tt_generation_strategies`,
`tt_constraint_violations`, `tt_conflict_detection`, `tt_teacher_workloads`.

---

# E. Findings worth discussing

1. **Regenerating any requirement stage up to Activities truncates every timetable's cells,
   published included** (D1). Published timetables 4 and 17 on the test DB are empty today, so
   portals scoped to them show nothing. Either block the regenerate while a published timetable
   exists, or build the planned snapshot.
2. **3 timetables are PUBLISHED and active at once** (4, 17, 26), all with the same session 7,
   term 1, type 1 and period set 3. `TimetableStorageService::publishTimetable()` archives every
   other active timetable of exactly that scope, so these were published through a path that
   skips the archive step (there are publish actions in `TimetablePublishController`,
   `SmartTimetableController` and the Python `store()`). Not traced further; worth checking.
3. **`tt_slot_requirements` is not read by either engine** (only by its tab, the ratio pages and
   the readiness count). The Slot Requirement step does not affect the generated timetable.
4. **The PHP engine rewrites `tt_activity_teachers`** at generate time (class-teacher auto-assign);
   the Python engine does not. The same requirement data can therefore show different Activity
   Teachers after a PHP run.
5. **Opening Pre-Generation Checks writes `tt_activity_priorities`** (it runs the full exporter).
6. **`tt_teacher_unavailabilities` is not read by the Python exporter.** Python reads teacher
   unavailability from `tt_constraints` (`ConstraintCompiler::teacherNotAvailable`).
   `tt_teacher_unavailabilities` is only used by the post-generation canvas. Same for room
   unavailability.
7. **Room Slot Matrix is always empty**: the room canvas is skipped because
   `tt_room_availability_details` needs a class and subject that a free slot cannot have.
   Teacher Slot Matrix fills only after a generation.
8. **`tt_requirement_consolidations.class_requirement_group_id` and `tt_activities.class_group_id`
   point at `sch_class_groups_jnt`**, not at `tt_class_requirement_groups`, despite the names. Any
   join that assumes otherwise gets wrong rows.
9. **Cells have no class / subject columns**; the owner must come from
   `OptionCellResolver::owners()`. Reports & Logs does this. Analytics Distribution
   (`AnalyticsService::getDistributionReport`) and the Class Coverage block of
   `/smart-timetable/timetable-reports` key on the activity's own class / section, so shared and
   option lessons (section NULL) land under a "Class -" row instead of their real sections.
10. Skeleton cells: 29,812 per timetable, of which 2,247 hold a lesson (7.5 %). Any count of
    `tt_timetable_cells` must filter `activity_id IS NOT NULL` (and `is_active = 1`), or it counts
    empty slots.
11. `OptionalSubjectBreakdownService`'s header says "display only", but `generateClassGroups()` now
    uses it to write subgroups and their head-counts. The comment is out of date.

---

## Appendix 1 — Row counts of every tt_ table (test.localhost, 7 Oct 2026)

| Table | Rows | Table | Rows |
|---|---:|---|---:|
| tt_activities | 597 | tt_period_types | 9 |
| tt_activity_priorities | 576 | tt_priority_configs | 0 |
| tt_activity_teachers | 978 | tt_requirement_consolidations | 665 |
| tt_change_logs | 0 | tt_resource_bookings | 0 |
| tt_class_requirement_groups | 539 | tt_room_availabilities | 0 |
| tt_class_requirement_subgroups | 126 | tt_room_availability_details | 0 |
| tt_class_subgroup_members | 0 | tt_room_unavailabilities | 0 |
| tt_class_timetable_types_jnt | 344 | tt_school_days | 7 |
| tt_class_working_days_jnt | 4,620 | tt_shifts | 2 |
| tt_configs | 15 | tt_slot_requirements | 43 |
| tt_conflict_detection | 0 | tt_sub_activities | 66 |
| tt_constraint_category_scopes | 27 | tt_sub_activity_details | 2,004 |
| tt_constraint_types | 10 | tt_sub_activity_members | 126 |
| tt_constraint_violations | 0 | tt_substitution_logs | 0 |
| tt_constraints | 6 | tt_teacher_absences | 0 |
| tt_day_types | 9 | tt_teacher_assignment_roles | 5 |
| tt_generation_runs | 26 | tt_teacher_availabilities | 1,077 |
| tt_generation_strategies | 0 | tt_teacher_availability_details | 3,648 |
| tt_parallel_group_activity | 0 | tt_teacher_unavailabilities | 0 |
| tt_parallel_groups | 0 | tt_teacher_workloads | 0 |
| tt_period_configs | 9 | tt_timetable_assignment | 1 |
| tt_period_set_periods_jnt | 27 | tt_timetable_cell_teachers | 6,741 |
| tt_period_sets | 4 | tt_timetable_cells | 89,436 |
| tt_timetable_types | 4 | tt_timetables | 26 |
| tt_working_days | 365 | | |

## Appendix 2 — How to re-measure

```sql
-- tenant DB of a domain
SELECT d.domain, JSON_UNQUOTE(JSON_EXTRACT(t.data,'$.tenancy_db_name'))
FROM prime_db.prm_tenant_domains d JOIN prime_db.prm_tenant t ON t.id = d.tenant_id;

-- cells per timetable (skeleton vs placed)
SELECT t.id, t.status, COUNT(c.id) AS cells, SUM(c.activity_id IS NOT NULL) AS placed
FROM tt_timetables t LEFT JOIN tt_timetable_cells c ON c.timetable_id = t.id
GROUP BY t.id ORDER BY t.id DESC;

-- FK graph with delete rules
SELECT k.table_name, k.column_name, k.referenced_table_name, r.delete_rule
FROM information_schema.key_column_usage k
JOIN information_schema.referential_constraints r
  ON r.constraint_schema = k.constraint_schema AND r.constraint_name = k.constraint_name
WHERE k.table_schema = DATABASE() AND k.table_name LIKE 'tt\_%' AND k.referenced_table_name IS NOT NULL;
```
