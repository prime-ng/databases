# Module Knowledge — TTF: TimetableFoundation
**Seeded:** 2026-06-30 | **Agent:** Business Analyst
**Version:** 1.0

---

## Module Facts

| Attribute | Value |
|-----------|-------|
| Module Name | TimetableFoundation |
| Module Code | TTF |
| Table Prefix | `tt_*` (shared namespace with SmartTimetable and StandardTimetable) |
| Laravel Module Path | `Modules/TimetableFoundation/` |
| Namespace | `Modules\TimetableFoundation` |
| DB Layer | **Tenant** — `tenant_mysql` (per-school tenant database) |
| Domain Scope | Tenant — School Admin, Timetable Manager, Academic Coordinator, Principal |
| V2 Requirement | Exists: `TTF_TimetableFoundation_Requirement.md` (2026-03-26) |
| V1 Screen Specs | 12 files in `TimetableFoundation_v1/` |
| V2 Estimated Completion | ~68% (Grade C-) |
| Revised Estimate | ~68% — filesystem closely matches V2 picture; 4 systemic gaps remain |
| Role | **Infrastructure/foundation layer** — mandatory prerequisite for SmartTimetable generation |

### Verified File Counts (from `find Modules/TimetableFoundation -type f` — 2026-06-30)

| Component | Actual | V2 Said | Delta / Notes |
|-----------|--------|---------|---------------|
| Controllers | 26 | 24 | +2: PriorityConfigController, SubActivityDetailController |
| Models | 33 | 32 | +1: PeriodConfig model; TeacherAvailabilityLog model absent (V2 listed it, not found) |
| FormRequests | 4 | 4 | AcademicTermRequest, ConfigRequest, SchoolTimingProfileRequest, TimingProfileRequest — 22 controllers MISSING FormRequests |
| Policies | 23 | 24 | — |
| Services | 4 | 3 | +1: PriorityConfigService (new); SubActivityDetailSeeder misplaced in Services/ folder |
| Events | 1 | — | SpecialDayAssigned |
| Console Commands | 1 | — | BackfillSubActivityDetails |
| Exports | 2 | — | SheetExport, TimetableRequirementExport |
| Tests | 6 files | 7 | Feature: RouteAuthenticationTest; Unit: ControllerAuthTest, FormRequestValidationTest, ModelStructureTest, PolicyTest, ServiceTest; Pest.php (config) |
| V1 Screen Specs | 12 files | — | academic-terms, activity-management, class-subject-groups, config-settings, overview, period-configuration, requirements-consolidation, room-availability, school-days, teacher-availability, timetable-types, timing-profiles |

---

## Module Purpose — What TTF Does

TTF is the **mandatory configuration and master-data layer** that SmartTimetable and StandardTimetable consume before any timetable can be generated. It owns all `tt_*` tables and answers:

| Question | TTF's Answer |
|----------|-------------|
| What time does school happen? | Shifts (`tt_shift`), period sets (`tt_period_set` + slots) |
| What kind of day is it? | Day types (`tt_day_type`), working day calendar (`tt_working_day`) |
| What subjects need scheduling? | Requirement consolidation (`tt_requirement_consolidation`) |
| Who is available when? | Teacher availability (`tt_teacher_availabilities` + detail table) |
| What algorithm to use? | Generation strategy (`tt_generation_strategy`) |
| What are the rules? | Config catalog (`tt_config`), constraint types (`tt_constraint_type`) |

### Relationship with Consumer Modules

```
TimetableFoundation (TTF) ──────────────────────────── SmartTimetable (STT)
   tt_config                  ─reads→                  SmartTimetableController
   tt_period_set_period_jnt   ─reads→                  FET solver (time slots)
   tt_activity                ─reads→                  Placement engine
   tt_teacher_availabilities  ─reads→                  Constraint engine
   tt_generation_strategy     ─reads→                  Algorithm selection
   tt_constraint_type         ─seeds→                  ConstraintManager catalog
   tt_requirement_consolidation ─reads→                GenerateTimetableJob
```

---

## Seven Menu Pages Architecture

| # | Page | Route Suffix | Key Tabs |
|---|------|-------------|---------|
| 1 | Pre-Requisites Setup | `pre-requisites-setup` | Buildings, Room Types, Rooms, Teacher Profiles, Classes, Subjects (read-only from SchoolSetup) |
| 2 | Timetable Configuration | `timetable-configuration` | Config, Academic Terms, Generation Strategy |
| 3 | Timetable Masters | `timetable-masters` | Shift, Day Type, Period Type, Teacher Roles, School Days, Working Days, Class Working Days, Period Sets, Timetable Types, Class Timetables |
| 4 | Timetable Requirement | `timetable-requirement` | Slot Requirement, Requirement Groups, Requirement Sub-Groups, Requirement Consolidation |
| 5 | Resource Availability | `resource-availability` | Teacher Availability, Availability Log, Room Availability |
| 6 | Timetable Preparation | `timetable-preparation` | Activities, Sub-Activities, Activity Teacher Mapping |
| 7 | Reports & Logs | `reports-and-logs` | Class-wise, Teacher-wise, Room-wise, Workload, Utilization (reads SmartTimetable analytics) |

---

## DDL Table Inventory (~37 tables — all `tt_*` in tenant_db)

### 5.1 Master / Reference Tables (seeded, rarely changed)

| Table | Key Columns | Constraints |
|-------|-------------|------------|
| `tt_config` | key (UQ), value, value_type ENUM(STRING/NUMBER/BOOLEAN/DATE/TIME/DATETIME/JSON), tenant_can_modify, mandatory | UQ(key), UQ(ordinal) |
| `tt_generation_strategy` | code (UQ), algorithm_type ENUM(RECURSIVE/GENETIC/SIMULATED_ANNEALING/TABU_SEARCH/HYBRID), max_recursive_depth, tabu_size, cooling_rate, population_size, generations, activity_sorting_method, timeout_seconds, parameters_json, is_default | UQ(code) |
| `tt_shift` | code (UQ), name (UQ), ordinal (UQ), default_start_time, default_end_time | 3× UNIQUE keys |
| `tt_day_type` | code (UQ), name (UQ), ordinal (UQ), is_working_day, reduced_periods | 3× UNIQUE keys |
| `tt_period_type` | code (UQ), ordinal (UQ), is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period, color_code, icon, duration_minutes | 2× UNIQUE keys |
| `tt_teacher_assignment_role` | code (UQ), is_primary_instructor, counts_for_workload, allows_overlap, workload_factor DECIMAL(5,2) | UQ(code) |
| `tt_school_days` | code (UQ), day_of_week (UQ), ordinal, is_school_day | 2× UNIQUE keys |

### 5.2 Configuration Tables

| Table | Key Columns | Important Constraints |
|-------|-------------|----------------------|
| `tt_academic_terms` | academic_session_id, term_type ENUM(QUARTER/SEMESTER/ANNUAL/TRIMESTER), start_date, end_date, term_total_teaching/exam/working_days | — |
| `tt_period_set` | code (UQ), total/teaching/exam/free/assembly/short_break/lunch_break_periods, day_start_time, day_end_time, is_default | UQ(code) |
| `tt_period_set_period_jnt` | period_set_id, period_ord, code, period_type_id, start_time, end_time, **duration_minutes GENERATED STORED** | UQ(set_id, ord), UQ(set_id, code), CHECK(end_time > start_time) — duration_minutes must NOT be in $fillable |
| `tt_timetable_type` | code (UQ), shift_id, effective_from/to_date, school_start_time, school_end_time, has_exam, has_teaching, is_default | CHECK(school_end_time > school_start_time), CHECK(effective_from_date <= effective_to_date) |
| `tt_working_day` | date (UQ), academic_session_id, day_type1_id–day_type4_id, is_school_day | UQ(date); 4× FK → tt_day_type RESTRICT |
| `tt_class_timetable_type_jnt` | academic_term_id, timetable_type_id, class_id, section_id, period_set_id, applies_to_all_sections, has_teaching, has_exam, weekly_*_period_count | CHECK(section_id IS NULL ↔ applies_to_all_sections=1) |
| `tt_class_working_day_jnt` | academic_session_id, date, class_id, section_id, working_day_id, is_exam_day, is_ptm_day, is_half_day, is_holiday, is_study_day | UQ(class_id, working_day_id) |

### 5.3 Requirement Tables

| Table | Key Columns |
|-------|-------------|
| `tt_slot_requirement` | academic_term_id, timetable_type_id, class_timetable_type_id, class_id, section_id, weekly_total/teaching/exam/free_slots |
| `tt_class_requirement_groups` | code (UQ), class_group_id, class_id, section_id, subject_id, study_format_id, subject_type_id, student_count, eligible_teacher_count |
| `tt_class_requirement_subgroups` | code (UQ), class_id, section_id, subject_id, is_shared_across_sections, is_shared_across_classes |
| `tt_requirement_consolidation` | academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, required_weekly_periods |
| `tt_class_subject_groups` | — |
| `tt_class_subject_subgroups` | — |
| `tt_class_subgroup_members` | — |
| `tt_class_mode_rules` | Needs schema verification |

### 5.4 Availability Tables

| Table | Key Columns | Generated Columns |
|-------|-------------|-------------------|
| `tt_teacher_availabilities` | teacher_profile_id, requirement_consolidation_id, max/min_allocated_periods_weekly, allocation_strictness ENUM(Hard/Medium/Soft), priority_weight, scarcity_index, preferred_shift | `available_for_full_timetable_duration` STORED, `no_of_days_not_available` STORED — both must NOT be in $fillable |
| `tt_teacher_availability_details` | teacher_profile_id, day_number (1-7), period_number, can_be_assigned, availability_for_period ENUM | UQ(teacher_profile_id, day_number, period_number) |
| `tt_teacher_availability_logs` | teacher_profile_id, change_date, old/new_value | Audit trail |
| `tt_room_availabilities` | room_id, rooms_type_id | — |
| `tt_room_availability_details` | room_availability_id, day_number, period_number | Per-slot room availability |

### 5.5 Activity Tables (Core Scheduler Input)

| Table | Key Columns |
|-------|-------------|
| `tt_activities` | academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, required_weekly_periods |
| `tt_activity_teachers` | activity_id, teacher_id, assignment_role_id |
| `tt_sub_activities` | activity_id (parent ref) |
| `tt_activity_priorities` | activity_id, priority_level |

### 5.6 Timetable Tables (Managed by TTF, Populated by SmartTimetable)

| Table | Key Columns |
|-------|-------------|
| `tt_timetables` | academic_term_id, timetable_type_id, status ENUM(DRAFT/GENERATED/PUBLISHED/ARCHIVED), generation_run_id |
| `tt_timetable_cells` | timetable_id, day_number, period_number, class_id, section_id, subject_id, room_id |
| `tt_timetable_cell_teachers` | timetable_cell_id, teacher_id, is_substitute |

### 5.7 Tables in DDL but No Controllers Yet

| Table | Purpose | FR Status |
|-------|---------|-----------|
| `tt_teacher_unavailable` | Teacher absence records (sick leave, leave) | ❌ FR-TTF-20 not started |
| `tt_room_unavailable` | Room maintenance/booking unavailability | ❌ FR-TTF-20 not started |
| `tt_constraint_type` | Constraint type catalog for SmartTimetable | ❌ FR-TTF-19 not started; seeded by STT |

---

## Controller Inventory (26 confirmed)

| Controller | Page | FR | FormRequest? |
|-----------|------|-----|:-----------:|
| `TimetableFoundationController` | Hub (all 7 pages + generateClassGroups) | FR-TTF | No |
| `ConfigController` | Page 2 — Config | FR-TTF-01 | Yes (ConfigRequest) |
| `AcademicTermController` | Page 2 — Terms | FR-TTF-02 | Yes (AcademicTermRequest) |
| `SchoolShiftController` | Page 3 — Shift | FR-TTF-04 | No |
| `DayTypeController` | Page 3 — Day Type | FR-TTF-05 | No |
| `PeriodTypeController` | Page 3 — Period Type | FR-TTF-06 | No |
| `SchoolDayController` | Page 3 — School Days | FR-TTF-08 | No |
| `WorkingDayController` | Page 3 — Working Days (AJAX + calendar) | FR-TTF-08 | No |
| `ClassWorkingDayController` | Page 3 — Class Working Days | FR-TTF-08 | No |
| `PeriodSetController` | Page 3 — Period Sets | FR-TTF-07 | No |
| `PeriodSetPeriodController` | Page 3 — Period Slots | FR-TTF-07 | No |
| `PeriodConfigController` | Page 3 — Period Config | FR-TTF | No |
| `TimetableTypeController` | Page 3 — Timetable Types | FR-TTF-09 | No |
| `ClassTimetableTypeController` | Page 3 — Class Timetable Types | FR-TTF-09 | No |
| `TeacherAssignmentRoleController` | Page 3 — Assignment Roles | FR-TTF-16 | No |
| `TimingProfileController` | Page 3 — Timing Profile | FR-TTF-18 | Yes (TimingProfileRequest) |
| `SchoolTimingProfileController` | Page 3 — School Timing | FR-TTF-18 | Yes (SchoolTimingProfileRequest) |
| `SlotRequirementController` | Page 4 — Slot Requirement | FR-TTF-12 | No |
| `RequirementConsolidationController` | Page 4 — Requirement Consolidation | FR-TTF-14 | No |
| `ClassSubjectSubgroupController` | Page 4 — Subgroups | FR-TTF-13 | No |
| `TeacherAvailabilityController` | Page 5 — Teacher Availability | FR-TTF-10 | No |
| `RoomAvailabilityController` | Page 5 — Room Availability | FR-TTF-11 | No |
| `ActivityController` | Page 6 — Activities | FR-TTF-15 | No |
| `SubActivityDetailController` | Page 6 — Sub-Activity Detail | FR-TTF-15 | No (NEW post-V2) |
| `PriorityConfigController` | Page 6 — Priority Config | FR-TTF-15 | No (NEW post-V2) |
| `TimetableController` | Page 7 — Timetable Master | FR-TTF-17 | No |

> **Note:** `TtGenerationStrategyController` lives in `Modules\SmartTimetable\Http\Controllers` but is registered in TTF routes — cross-module controller usage. `ClassSubjectGroupController` (SchoolSetup) also appears in TTF routes. Double-registration risk with central `routes/tenant.php` lines 140–162.

---

## Model Inventory (33 confirmed, with key issues)

| Model | Table | Key Issue |
|-------|-------|-----------|
| `Config` | `tt_config` | **AUDITOR NOTE (2026-06-30): `scopeByStatus()` does NOT exist in current code. BA bug report refuted.** Config correctly uses `is_active` via `scopeActive()` and inline `when()` closures. |
| `AcademicTerm` | `tt_academic_terms` | — |
| `Activity` | `tt_activities` | Core model; 10+ BelongsTo relations |
| `ActivityTeacher` | `tt_activity_teachers` | Junction: activity + teacher + role |
| `ActivityPriority` | `tt_activity_priorities` | — |
| `ClassSubjectGroup` | `tt_class_subject_groups` | — |
| `ClassSubjectSubgroup` | `tt_class_subject_subgroups` | — |
| `ClassSubgroupMember` | `tt_class_subgroup_members` | — |
| `ClassModeRule` | `tt_class_mode_rules` | Needs schema verification |
| `ClassRequirementGroup` | `tt_class_requirement_groups` | — |
| `ClassRequirementSubgroup` | `tt_class_requirement_subgroups` | — |
| `ClassTimetableType` | `tt_class_timetable_types` | — |
| `ClassWorkingDay` | `tt_class_working_day_jnt` | — |
| `DayType` | `tt_day_type` | — |
| `PeriodConfig` | (unknown — needs verify) | Post-V2 addition |
| `PeriodSet` | `tt_period_sets` | — |
| `PeriodSetPeriod` | `tt_period_set_periods` | `duration_minutes` is GENERATED — must be in `$guarded`, not `$fillable` |
| `PeriodType` | `tt_period_types` | — |
| `RequirementConsolidation` | `tt_requirement_consolidations` | — |
| `RoomAvailability` | `tt_room_availabilities` | — |
| `RoomAvailabilityDetail` | `tt_room_availability_details` | — |
| `SchoolDay` | `tt_school_days` | — |
| `SchoolShift` | `tt_shift` | **Aliased as TimingProfile AND SchoolTimingProfile** in AppServiceProvider (lines 189-190) — workaround |
| `SlotRequirement` | `tt_slot_requirements` | — |
| `SubActivity` | `tt_sub_activities` | — |
| `SubActivityDetail` | (unknown — post-V2) | — |
| `TeacherAssignmentRole` | `tt_teacher_assignment_roles` | — |
| **`TeacherAvailablity`** | `tt_teacher_availabilities` | **TYPO** in class name and filename — missing 'i'; must be renamed `TeacherAvailability` across all references |
| `Timetable` | `tt_timetables` | — |
| `TimetableCell` | `tt_timetable_cells` | — |
| `TimetableCellTeacher` | `tt_timetable_cell_teachers` | — |
| `TimetableType` | `tt_timetable_types` | — |
| `WorkingDay` | `tt_working_days` | — |

**Missing model (in V2 list, not in files):** `TeacherAvailabilityLog` (for `tt_teacher_availability_logs`)

**Generated columns** that must NEVER appear in `$fillable`:
- `tt_period_set_period_jnt.duration_minutes` — GENERATED STORED
- `tt_teacher_availabilities.available_for_full_timetable_duration` — GENERATED STORED
- `tt_teacher_availabilities.no_of_days_not_available` — GENERATED STORED

---

## Feature Area Status (as of 2026-06-30)

| # | Feature Area | FR | Status | Notes |
|---|-----------|----|--------|-------|
| 1 | Timetable Configuration (Config CRUD) | FR-TTF-01 | 🟡 70% | `scopeByStatus()` bug; no caching; ConfigRequest exists |
| 2 | Academic Term Management | FR-TTF-02 | 🟡 75% | CRUD works; date overlap check missing |
| 3 | Generation Strategy | FR-TTF-03 | 🟡 85% | Controller in SmartTimetable; routes in TTF — cross-module coupling |
| 4 | Shift Management | FR-TTF-04 | ✅ 90% | CRUD complete; no FormRequest |
| 5 | Day Type Management | FR-TTF-05 | ✅ 90% | CRUD complete; no FormRequest |
| 6 | Period Type Management | FR-TTF-06 | ✅ 90% | CRUD complete; no FormRequest |
| 7 | Period Set Management | FR-TTF-07 | 🟡 85% | GENERATED column risk on duration_minutes; addPeriodToOrganization partial |
| 8 | Working Day Calendar | FR-TTF-08 | 🟡 80% | Calendar init + AJAX CRUD present; auto-update of term counters missing |
| 9 | Timetable Type & Class Assignment | FR-TTF-09 | 🟡 80% | Date overlap check missing; period set overlap check missing |
| 10 | Teacher Availability | FR-TTF-10 | 🟡 70% | Per-slot matrix UI completeness unknown; no FormRequest; typo in model name |
| 11 | Room Availability | FR-TTF-11 | 🟡 65% | Detail matrix completeness uncertain; no FormRequest |
| 12 | Slot Requirement | FR-TTF-12 | 🟡 65% | generateSlotRequirement exists |
| 13 | Requirement Groups & Subgroups | FR-TTF-13 | 🟡 60% | AJAX toggle-sharing present |
| 14 | Requirement Consolidation | FR-TTF-14 | 🟡 70% | Inline update + AJAX present; FormRequest missing |
| 15 | Activity Management | FR-TTF-15 | 🟡 75% | Batch generation + progress polling present; no rate limiting |
| 16 | Teacher Assignment Role | FR-TTF-16 | ✅ 90% | CRUD complete; no FormRequest |
| 17 | Timetable Master Records | FR-TTF-17 | 🟡 75% | Status lifecycle present; version management partial |
| 18 | Timing Profile | FR-TTF-18 | 🟡 60% | SchoolShift aliased as 2 models — workaround |
| 19 | Constraint Type Viewer | FR-TTF-19 | ❌ 0% | Table exists (seeded by STT); no controller |
| 20 | Temporary Unavailability | FR-TTF-20 | ❌ 0% | Tables exist in DDL; no controllers |
| 21 | Reports Page | FR-TTF-21 | 🟡 60% | Reads STT analytics; completeness unknown |

---

## Known Gaps & Open Issues

### P0 — Critical (Production Blockers)

| ID | Issue | Location |
|----|-------|---------|
| SEC-TTF-01 | `EnsureTenantHasModule` middleware absent from ALL ~138 routes — any authenticated tenant can access timetable configuration without a license | `Routes/web.php` — add single wrapping group |
| BUG-TTF-02 | `TeacherAvailablity` model has a typo (missing 'i') in both filename and class declaration — causes import errors in any module referencing this model | `Modules/TimetableFoundation/app/Models/TeacherAvailablity.php` |

### P1 — High

| ID | Issue | Location |
|----|-------|---------|
| GAP-TTF-03 | Only 4 of 26 controllers have FormRequests — 22 controllers accept raw $request input without validation: WorkingDayRequest, ActivityRequest, RequirementConsolidationRequest, TeacherAvailabilityRequest, PeriodSetRequest, PeriodSlotRequest are highest priority | FormRequests/ directory |
| GAP-TTF-04 | ~19 of 23 policies are NOT registered in AppServiceProvider — Gate::policy() never called; Gate::authorize() in controllers silently passes through | `Providers/TimetableFoundationServiceProvider.php` or AppServiceProvider |
| ~~BUG-TTF-05~~ | **REFUTED (2026-06-30 audit):** `Config::scopeByStatus()` does NOT exist. Config correctly uses `is_active`. This entry is invalid — do not investigate further. | — |
| BUG-TTF-06 | `PeriodSetPeriod::$fillable` may include `duration_minutes` (GENERATED STORED column) — Eloquent will attempt to write it; MySQL will reject silently or throw exception | `Models/PeriodSetPeriod.php` — verify $guarded |
| BUG-TTF-07 | `TeacherAvailablity::$fillable` may include `available_for_full_timetable_duration` and `no_of_days_not_available` (both GENERATED STORED) — same risk as above | `Models/TeacherAvailablity.php` |
| ARCH-TTF-08 | `SchoolShift` model aliased as both `TimingProfile` and `SchoolTimingProfile` in AppServiceProvider — architectural workaround; must create dedicated models | `app/Providers/AppServiceProvider.php` lines 189-190 |
| ARCH-TTF-09 | Double route registration: TTF module `Routes/web.php` AND central `routes/tenant.php` (lines 140-162) may register the same controllers via aliases — route collision risk | Routes |
| ARCH-TTF-10 | `TtGenerationStrategyController` lives in `Modules\SmartTimetable` but registered in TTF routes — cross-module controller dependency | `Routes/web.php` |

### P2 — Medium

| ID | Issue | Location |
|----|-------|---------|
| GAP-TTF-11 | Academic term date overlap not validated at application level (no DB constraint either) — two terms for the same session can overlap | `AcademicTermController::store()/update()` |
| GAP-TTF-12 | Timetable type school_start/end times not validated for overlap per shift at application level | `TimetableTypeController` |
| GAP-TTF-13 | `tt_academic_term.term_total_*_days` counters NOT auto-updated when working day type changes — manual counter maintenance required | WorkingDay model; no Observer defined |
| GAP-TTF-14 | No rate limiting on batch generation endpoints: `generateAllActivities`, `generateRequirements` | `Routes/web.php` |
| GAP-TTF-15 | `tt_config` read-heavy but no caching — every config access hits DB | `ConfigController`; needs Laravel cache wrapping |
| GAP-TTF-16 | `TeacherAvailabilityLog` model NOT found on filesystem even though V2 lists it and `tt_teacher_availability_logs` table exists | Models/ directory |
| GAP-TTF-17 | No `ConstraintTypeController` — `tt_constraint_type` table exists and is seeded by STT but TTF has no UI to view the constraint catalog | Routes/web.php |
| GAP-TTF-18 | No `TeacherUnavailableController` or `RoomUnavailableController` — `tt_teacher_unavailable` and `tt_room_unavailable` tables exist in DDL but no UI | FR-TTF-20 |
| GAP-TTF-19 | `SubActivityDetailSeeder` is in `app/Services/` folder — misplaced; should be in `database/seeders/` | `app/Services/SubActivityDetailSeeder.php` |

### P3 — Backlog

| ID | Issue |
|----|-------|
| GAP-TTF-20 | `TimingProfile` and `SchoolTimingProfile` need dedicated models; remove AppServiceProvider alias workaround |
| GAP-TTF-21 | `WorkingDayService`, `RequirementConsolidationService`, `ActivityGenerationService` should be extracted from controller logic |
| GAP-TTF-22 | All 33 models need audit: correct `$fillable`/`$casts`/`SoftDeletes`/DDL column name alignment |
| GAP-TTF-23 | Page 3 has 10 master-data sections; no eager loading verification — risk of N+1 on master-data tabs |
| GAP-TTF-24 | Route file is 280 lines — largest in project; consider splitting into per-page sub-route files |
| GAP-TTF-25 | Integration test for full TTF setup workflow (Steps 1-6 pre-generation checklist) is missing |

---

## Business Rules (Critical Ones)

| Rule | DB Enforcement | App Status |
|------|---------------|-----------|
| Period slot `end_time > start_time` | CHECK `chk_psp_time` on jnt table | FormRequest cross-field rule needed |
| `duration_minutes` is GENERATED STORED — never write | MySQL | Must not be in $fillable |
| `available_for_full_timetable_duration` GENERATED — never write | MySQL | Must not be in $fillable |
| `no_of_days_not_available` GENERATED — never write | MySQL | Must not be in $fillable |
| Class timetable: `section_id IS NULL ↔ applies_to_all_sections=1` | CHECK constraint | FormRequest conditional rule needed |
| Teacher availability slot UNIQUE (teacher, day_number, period_number) | UQ key | Handle DB duplicate gracefully |
| Academic terms must not overlap dates per session | None | Application-level check missing |
| Timetable type times must not overlap per shift | None | Application-level check missing |
| Only one `tt_generation_strategy.is_default=1` at a time | No DB constraint | Toggle logic in controller |
| `tt_config` with `tenant_can_modify=0` — tenants cannot edit | None | Gate check + read-only UI needed |
| `tt_shift` code/name/ordinal all UNIQUE — user-friendly error | DB UNIQUE keys | Catch duplicate key in controller |
| Working day change should update `tt_academic_term` counters | No DB trigger | Observer on WorkingDay — NOT implemented |

---

## Six-Step Pre-Generation Setup Workflow (TTF's Core Flow)

```
Step 1 (SchoolSetup): Buildings, Rooms, Classes, Subjects → prereqs
Step 2 (TTF Page 2): Configure tt_config, create Academic Terms, select Generation Strategy
Step 3 (TTF Page 3): Create Shifts, Day Types, Period Types, Period Sets, Timetable Types,
                      assign Class-Timetable-Types, initialise Working Day Calendar
Step 4 (TTF Page 4): Generate Slot Requirements → Generate Requirement Consolidation records
Step 5 (TTF Page 5): Generate Teacher Availability → edit per-slot matrix → set Room Availability
Step 6 (TTF Page 6): Generate Activities → assign Teachers to Activities

→ SmartTimetable can now generate
```

---

## Cross-Module Dependencies

### TTF Consumes From

| Source Module | Data | Tables Read |
|--------------|------|------------|
| SchoolSetup | Classes, Sections, Subjects, Study Formats, Rooms, Room Types, Buildings | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_rooms`, `sch_room_types` |
| StaffProfile | Teacher profiles | `sch_teachers` / staff profile table |
| GlobalMaster | Academic sessions | `sch_academic_sessions` |
| SmartTimetable | Generation strategy controller | Cross-module controller in TTF routes |

### TTF Provides To

| Consumer | Data Provided | Key Tables |
|----------|--------------|------------|
| SmartTimetable | All configuration for generation | All `tt_*` tables |
| StandardTimetable | Period set and type context | `tt_period_set`, `tt_period_type`, `tt_timetable_type` |
| TimetableApiController | REST API reads activities + availability | `tt_activities`, `tt_teacher_availabilities`, `tt_period_sets` |
| Syllabus | Academic term alignment | `tt_academic_terms` |
| MarksheetGeneration | Academic term context | `tt_academic_terms` |

---

## Route Summary

| Category | Approximate Count | EnsureTenantHasModule |
|----------|------------------|----------------------|
| Menu pages | 8 | ❌ All missing |
| Config | 5 | ❌ |
| Academic Term | 5 | ❌ |
| Timetable Masters (11 groups × ~5) | ~55 | ❌ All missing |
| Working Day (AJAX + resource) | ~10 | ❌ |
| Availability (teacher + room + log) | ~15 | ❌ |
| Requirement + Activity | ~18 | ❌ |
| Subgroups + Class Working Days | ~15 | ❌ |
| Cross-module (generation strategy, class groups) | ~7 | ❌ |
| **TOTAL** | **~138** | **0 protected** |

Required fix (single-line):
```php
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:TimetableFoundation'])
    ->prefix('timetable-foundation')
    ->name('timetable-foundation.')
    ->group(function () { /* existing 280 lines */ });
```

---

## V1 Screen Specs (12 files)

| File | Coverage |
|------|---------|
| `overview.md` | Module architecture, 7-page structure |
| `config-settings.md` | tt_config CRUD, value types, tenant_can_modify |
| `academic-terms.md` | Academic term CRUD, term types, date ranges |
| `timing-profiles.md` | Shift and timing profile management |
| `period-configuration.md` | Period set and period slot CRUD |
| `school-days.md` | School day reference + working day calendar |
| `timetable-types.md` | Timetable type and class-timetable assignment |
| `class-subject-groups.md` | Requirement groups and subgroups |
| `requirements-consolidation.md` | Consolidation generation workflow |
| `teacher-availability.md` | Teacher availability matrix, generation |
| `room-availability.md` | Room availability matrix |
| `activity-management.md` | Activity CRUD, batch generation, teacher mapping |

---

## Test Coverage Summary

| File | Type | Focus |
|------|------|-------|
| `Feature/RouteAuthenticationTest.php` | Feature | Routes require auth |
| `Unit/ControllerAuthTest.php` | Unit | Gate::authorize presence check |
| `Unit/FormRequestValidationTest.php` | Unit | 4 FormRequest rules (only 4/26 FRQs have coverage) |
| `Unit/ModelStructureTest.php` | Unit | Model fillable/casts/relationships |
| `Unit/PolicyTest.php` | Unit | Policy method existence |
| `Unit/ServiceTest.php` | Unit | Service method behavior |

**Priority Missing Tests (from V2):**
- TST-TTF-01: `EnsureTenantHasModule` blocks all 138 routes for unlicensed tenant
- TST-TTF-02: Period slot end>start DB constraint
- TST-TTF-03/04: GENERATED columns not writable
- TST-TTF-06: Teacher availability slot unique constraint handled gracefully
- TST-TTF-07: Academic term overlap detection
- TST-TTF-08: `tenant_can_modify=0` records blocked for tenants

---

## Services

| Service | Purpose |
|---------|---------|
| `AnalyticsService` | Timetable analytics for Reports page (reads from STT populated tt_timetable_cells) |
| `RoomAvailabilityService` | Room availability matrix management |
| `SubActivityService` | Sub-activity creation and management (split-class activities) |
| `PriorityConfigService` | Activity priority configuration — post-V2 addition |

---

## Lessons Learned

- [2026-06-30 | Business Analyst] TTF has ~138 routes with ZERO `EnsureTenantHasModule` protection — most severely affected module in the project from a licensing bypass perspective. Single-line fix in Routes/web.php would protect the entire module.
- [2026-06-30 | Business Analyst] `TeacherAvailablity` typo (missing 'i') in both filename AND class declaration is a latent P0 — any module that imports `Modules\TimetableFoundation\Models\TeacherAvailability` (correct spelling) gets a class-not-found error. Fix requires global search-and-replace.
- [2026-06-30 | Business Analyst] Three GENERATED STORED columns across two tables (`duration_minutes` on period slots; `available_for_full_timetable_duration` and `no_of_days_not_available` on teacher availability) must never appear in Eloquent `$fillable` arrays. MySQL silently ignores or throws on write attempts. Always grep for these column names in `$fillable` before any migration to these models.
- [2026-06-30 | Business Analyst] TTF routes include controllers from TWO other modules: `TtGenerationStrategyController` (SmartTimetable) and `ClassSubjectGroupController` (SchoolSetup). This means TTF module routes fail if STT or SchoolSetup are disabled. True modular architecture requires these controllers to be moved or replaced with API calls.
- [2026-06-30 | Business Analyst] The `tt_` table prefix is shared across TTF, SmartTimetable, and StandardTimetable. All three modules read/write the same prefix. TTF owns the schema (migrations); STT/TTS own the generation logic. This is by design but requires discipline — never create a `tt_*` table in STT migrations; always add to TTF migrations.
- [2026-06-30 | Business Analyst] V2 was accurate for TTF (~68% estimate is consistent with filesystem findings). Unlike SLK and SYS where V2 drastically understated scope, TTF's V2 document closely reflects the current codebase state.
- [2026-06-30 | Technical Auditor] **CROSS-LAYER SESSION CONTAMINATION (P0):** 6 controllers and 3 models import `Modules\Prime\Models\AcademicSession` (prime_db) for tenant operations. Confirmed files: `TimetableFoundationController.php`, `ActivityController.php`, `WorkingDayController.php`, `ClassWorkingDayController.php`, `RequirementConsolidationController.php`, `TimetableController.php`; models: `Timetable.php`, `ClassWorkingDay.php`, `ClassModeRule.php`. Correct replacement: `Modules\SchoolSetup\Models\OrganizationAcademicSession`.
- [2026-06-30 | Technical Auditor] **BIDIRECTIONAL STT DEPENDENCY (P1):** TTF imports SmartTimetable models in 3 models and 3 controllers. This inverts the intended dependency direction. `Timetable.php` imports `GenerationRun` and `TtGenerationStrategy`; `Activity.php` imports `ParallelGroup`; `TimetableCell.php` imports `GenerationRun`; `ActivityController` imports 5 STT models. If SmartTimetable is disabled, TTF core models fail to instantiate.
- [2026-06-30 | Technical Auditor] **API ROUTE IS COMPLETELY UNGUARDED (P0):** `routes/api.php` uses only `['auth:sanctum']`. No tenant initialization, no module gate. The apiResource of `TimetableFoundationController` runs in global DB context. Fix: add full tenancy middleware stack to the API group.
- [2026-06-30 | Technical Auditor] **19/23 POLICIES DEAD (P0):** `registerPolicies()` has only 5 Gate::policy() calls; duplicate `Gate::policy(SchoolShift::class, ...)` silently kills `TimingProfilePolicy`. 19 policy classes exist but are never mapped. Only `DayPolicy`, `PeriodPolicy`, `SchoolTimingProfilePolicy`, `TimetableConfigPolicy` are active.
- [2026-06-30 | Technical Auditor] **D36 PARTIAL (P2):** `tt_room_availability.available_for_full_timetable_duration` is plain boolean in migration; DDL specifies it as STORED generated. `tt_teacher_availabilities` columns ARE correctly generated. MIG-TT-001's `tt_period_set.total_periods` entry is incorrect (plain in both migration and DDL — consistent).

---

## Audit History

| Date | Mode | Auditor | Health Score | Report |
|------|------|---------|:---:|--------|
| 2026-06-30 | Mode X (A+B+C+G+scoped D) | pa-technical-auditor | **39/100** | `3-Audit_Reports/TimetableFoundation_Complete_Audit_2026-06-30.md` |

---

## Pending Next Steps

1. **P0**: Add `EnsureTenantHasModule:TimetableFoundation` to single Route group wrapping all routes
2. **P0**: Rename `TeacherAvailablity` → `TeacherAvailability` across both repos (global search-replace)
3. **P1**: Create 22 missing FormRequests — priority order: WorkingDayRequest, ActivityRequest, RequirementConsolidationRequest, TeacherAvailabilityRequest, PeriodSetRequest, PeriodSlotRequest (with end>start cross-field rule)
4. **P1**: Register all 23 policies in TimetableFoundationServiceProvider
5. **P1**: Fix `Config::scopeByStatus()` — change `status` to `is_active`
6. **P1**: Audit all 33 models for GENERATED columns in `$fillable`; move to `$guarded`
7. **P1**: Resolve AppServiceProvider SchoolShift alias (lines 189-190) — create dedicated TimingProfile and SchoolTimingProfile models
8. **P2**: Extract WorkingDayService, RequirementConsolidationService, ActivityGenerationService
9. **P2**: Add `tt_config` caching (read-heavy, write-rare)
10. **P2**: Implement WorkingDay Observer to auto-update `tt_academic_term` day counters

---

## FRD Summary

| Attribute | Value |
|-----------|-------|
| FRD File | `TTF_FRD_2026-06-30.md` (flat in `0-FRD_Documents/`) |
| Complete Analysis Pack | `TTF_FRD_Complete_2026-06-30.md` (same folder) |
| Conditions Catalog | `5-Requirement_Conditions/TTF_Conditions.md` |
| Date | 2026-06-30 |
| Total REQs | 22 (REQ-TTF-001 to REQ-TTF-022) |
| P0 Requirements | 13 |
| P1 Requirements | 7 |
| P2 Requirements | 2 |
| Total BRs | 15 (BR-TTF-001 to BR-TTF-015) |
| BR Implemented | 1 (BR-TTF-012) |
| BR Partial | 10 |
| BR Not Implemented | 4 (BR-TTF-002, BR-TTF-005, BR-TTF-006 partial, BR-TTF-015) |
| Total Reports (RPT-TTF-) | 5 |
| Total Enhancements (ENH-TTF-) | 4 |
| Total Workflows | 5 |
| User Stories (P0/P1) | 7 |
| Sprint Tasks | 27 tasks, ~70h total |
| Risk Register Entries | 12 |

### Post-FRD Gap-Analysis Handoffs
1. DDL Schema Gap Analysis → DB Architect / Technical Auditor (Mode A Layer 1–2): verify all `tt_*` table columns match model $fillable arrays, confirm GENERATED column exclusion
2. Application Code Gap → Technical Auditor (Mode B, FRD-driven): deep audit of 22 missing FormRequests, 19 unregistered policies, EnsureTenantHasModule absence, scopeByStatus() bug
3. Business Rule Enforcement → Technical Auditor (Mode C): BR-TTF-002, BR-TTF-005, BR-TTF-015 implementation verification
4. Completion Scoring (6-dim) → Status_Analyzer: current estimate ~68%; P0 gaps would drop functional score significantly
5. Test Coverage Gap → Testing Architect: 16 priority test scenarios defined in FRD §12; currently 7 test files covering ~4 FormRequests only

---

## Version History

| Version | Date | Agent | Changes |
|---------|------|-------|---------|
| 1.0 | 2026-06-30 | Business Analyst | Initial seed — V2 requirement (full read) + V1 screen specs (12 files) + filesystem verification + model/controller/policy counts confirmed |
| 1.1 | 2026-06-30 | Business Analyst | FRD generated and saved (`TTF_FRD_2026-06-30.md`); Complete Analysis Pack saved (`TTF_FRD_Complete_2026-06-30.md`); Conditions Catalog saved (`TTF_Conditions.md`); FRD Summary block added to module knowledge |
