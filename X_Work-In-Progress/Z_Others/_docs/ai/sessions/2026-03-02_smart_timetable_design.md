# Session Archive — SmartTimetable Module Stage 4 & 5 Design
**Date:** 2026-03-02
**Branch:** `Brijesh-timetable` (databases + laravel repos)
**Module:** `Modules/SmartTimetable`

---

## Objective

Continue the SmartTimetable module completion plan through Stages 4 and 5:

- **Stage 4:** Fix all v7.6 schema column/relationship renames across Services, Controllers, and Models so the timetable generation engine aligns with the current database schema.
- **Stage 5:** Implement Advanced Generation Features — async Generation Queue (Laravel Job), Tabu Search optimizer, Simulated Annealing optimizer, Solution Evaluator, Conflict Detection Service, and Resource Booking Service.

---

## Prompts Used

1. *(Session continuation from previous compressed context — Stages 1–3 done, Stage 4 partially in progress)*
2. `continue` — resume Stage 4 completion
3. `continue with Stage 5` — implement advanced generation features

---

## AI Response Summary

### Stage 4 — v7.6 Schema Alignment

Systematic audit and fix of all files referencing renamed columns and relationships from the v7.6 schema migration. Key renames applied:

| Old Reference | New Reference | Files Affected |
|---|---|---|
| `->weekly_periods` | `->required_weekly_periods` | ImprovedTimetableGenerator, FETSolver, SmartTimetableController |
| `->classGroupJnt->class->code` | `->class->code` | ImprovedTimetableGenerator, FETSolver, ConstraintManager, GenericHardConstraint |
| `->classGroupJnt->section->code` | `->section->code` | Same as above |
| `->activityTeachers` | `->teachers` | TeacherConflictConstraint, TimetableSolution, ActivityController, SmartTimetableController |
| `class_group_jnt_id` (entry key) | `class_id` + `section_id` | ImprovedTimetableGenerator, FETSolver, FETConstraintBridge, SmartTimetableController |
| `effective_from/to` (Constraint) | `effective_from_date/to_date` | ConstraintFactory |
| `applies_to_days_json` | `applicable_days_json` | ConstraintFactory |
| `constraint_level` (on Constraint) | `is_hard` (boolean) | DatabaseConstraintService, ValidationService |
| `competancy_level` | `competency_level` | TeacherAvailabilityController |
| `effective_from/to` (TeacherAvailablity) | `teacher_available_from_date/timetable_end_date` | TeacherAvailabilityController |
| `min/max_teacher_availability_score` | `min/max_availability_score` | TeacherAvailabilityController |
| `activity.classGroupJnt.subjectStudyFormat` | `activity.subjectStudyFormat` | TimetableStorageService, SmartTimetableController |
| `SchRoom::class` | `Room::class` | RoomAvailability model |

**Important distinction preserved:** `ConstraintType.constraint_level` is a legitimate column (metadata about the type's default level) — NOT changed.

### New Services Created (Stage 4)

**`SubActivityService.php`** — Task 4.7
- Splits multi-period activities into sub-activities (`tt_sub_activities`)
- Uses `parent_activity_id`, `ordinal`, `consecutive_with_previous` (true for ordinal > 1)
- Methods: `generateForTerm()`, `generateForActivity()`, `clearForTerm()`

**`RoomAvailabilityService.php`** — Task 4.1
- Generates `tt_room_availabilities` records from `sch_rooms`
- Scores `room_availability_score` per activity based on subject/class requirements
- Methods: `generate()`, `updateEligibleRoomCount()`, `updateEligibleRoomCountForTerm()`

### Activity Model Fix (Critical)
Added missing `teachers(): HasMany` relationship to `Activity.php`:
```php
public function teachers(): HasMany
{
    return $this->hasMany(ActivityTeacher::class, 'activity_id');
}
```
This relationship was referenced throughout the codebase but never defined on the model.

### Stage 5 — Advanced Generation Features (Infrastructure Read)

Explored infrastructure before implementation:

- **GenerationRun** (`tt_generation_runs`): Has `markRunning()`, `markCompleted()`, `markFailed()`, STATUS constants
- **ConflictDetection** (`tt_conflict_detections`): `detection_type` ENUM (REAL_TIME/BATCH/VALIDATION/GENERATION)
- **ResourceBooking** (`tt_resource_bookings`): `resource_type` ENUM (ROOM/LAB/TEACHER/EQUIPMENT)
- **GenerationQueue** (`tt_generation_queues`): Has `priority`, `status`, `attempts` fields
- **TtGenerationStrategy**: Algorithm parameters — `tabu_size`, `tabu_tenure`, `cooling_rate`, `initial_temperature`, `population_size`, `generations`, `max_iterations`, `timeout_seconds`
- **Queue driver:** `database` — tables `jobs`, `failed_jobs`, `job_batches` ready
- **Current generate() method:** Uses `AcademicSession::current()` (legacy), stores results in session — Job must persist via `TimetableStorageService`

---

## Decisions Taken

1. **Laravel is source of truth for table names** — Schema DDL updated to use plural table names matching Laravel models (Part A1 of plan).

2. **Activity.teachers() is HasMany to ActivityTeacher** — Not BelongsToMany to Teacher. The pivot table `tt_activity_teachers` is accessed via ActivityTeacher model directly.

3. **ConstraintType.constraint_level is NOT a bug** — It stores the type's default constraint level metadata. Only `Constraint.is_hard` needed fixing.

4. **SubActivity uses ordinal-based splitting** — Parent activity with duration > 1 gets N sub-activities with `ordinal` 1..N, `consecutive_with_previous=true` for ordinal > 1.

5. **Stage 5 Job will replicate load logic from SmartTimetableController** — Private methods (`loadActivitiesForActiveClassSections`, `loadSchoolDays`, `loadPeriodSet`, `loadClassSections`) will be extracted or reproduced in the Job/a shared service.

6. **Generation algorithms to implement:** `RECURSIVE` (exists), `TABU_SEARCH` (Stage 5.2), `SIMULATED_ANNEALING` (Stage 5.3), `GENETIC` (optional/low priority).

---

## Files Modified

### Laravel Repo (`/Users/bkwork/Herd/laravel/`)

| File | Change |
|------|--------|
| `Modules/SmartTimetable/app/Models/Activity.php` | Added `teachers(): HasMany` relationship |
| `Modules/SmartTimetable/app/Models/RoomAvailability.php` | Fixed `SchRoom::class` → `Room::class` |
| `Modules/SmartTimetable/app/Models/TimetableCell.php` | Fixed `getSubjectNameAttribute()`, `getClassSectionAttribute()` to use direct `class`/`section` |
| `Modules/SmartTimetable/app/Http/Controllers/TeacherAvailabilityController.php` | Fixed column names for writing TeacherAvailablity records |
| `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php` | `activityTeachers()` → `teachers()` |
| `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` | Multiple v7.6 renames across generate(), preview, and load methods |
| `Modules/SmartTimetable/app/Services/Generator/ImprovedTimetableGenerator.php` | `weekly_periods`, `classGroupJnt`, `activityTeachers`, `class_group_jnt_id` all fixed |
| `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` | Same fixes as ImprovedTimetableGenerator |
| `Modules/SmartTimetable/app/Services/Generator/FETConstraintBridge.php` | `class_group_jnt_id` → `class_id`/`section_id` |
| `Modules/SmartTimetable/app/Services/Generator/TimetableSolution.php` | `activityTeachers` → `teachers` (replace_all) |
| `Modules/SmartTimetable/app/Services/Constraints/ConstraintManager.php` | `buildContextArray()` — removed classGroupJnt, added direct class_id/section_id/subject |
| `Modules/SmartTimetable/app/Services/Constraints/GenericHardConstraint.php` | Same context building fix |
| `Modules/SmartTimetable/app/Services/Constraints/TeacherConflictConstraint.php` | `activityTeachers` → `teachers` (replace_all) |
| `Modules/SmartTimetable/app/Services/Constraints/ConstraintFactory.php` | `effective_from/to` → `effective_from_date/to_date`, `applies_to_days_json` → `applicable_days_json` |
| `Modules/SmartTimetable/app/Services/DatabaseConstraintService.php` | `constraint_level` → `is_hard`, ordering and stats fixed |
| `Modules/SmartTimetable/app/Services/ValidationService.php` | `constraint_level` → `is_hard` (3 references) |
| `Modules/SmartTimetable/app/Services/TimetableStorageService.php` | Removed stale `classGroupJnt` from eager load chain |

### New Files Created (Laravel Repo)

| File | Purpose |
|------|---------|
| `Modules/SmartTimetable/app/Services/SubActivityService.php` | Split multi-period activities into sub-activities (Stage 4.7) |
| `Modules/SmartTimetable/app/Services/RoomAvailabilityService.php` | Generate and score room availability records (Stage 4.1) |

### Databases Repo (`/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/`)

*(Schema changes were part of Stages 1–3 in previous sessions — see prior session archives)*

---

## Git Commit

**Branch:** `Brijesh-timetable`

Suggested commit message for Laravel repo:
```
Stage 4: Fix v7.6 schema renames across SmartTimetable generation engine

- Replace all classGroupJnt references with direct class/section relationships
- Replace activityTeachers with teachers() HasMany on Activity model
- Fix weekly_periods → required_weekly_periods across all generators
- Fix constraint is_hard, effective dates, applicable_days_json in ConstraintFactory/DatabaseConstraintService/ValidationService
- Fix TeacherAvailabilityController column mappings for v7.6 fields
- Fix RoomAvailability SchRoom → Room class reference
- Add SubActivityService (splits multi-period activities)
- Add RoomAvailabilityService (generates and scores room availability)
```

**Status:** Stage 4 complete. Stage 5 infrastructure explored — implementation pending next session.

---

## Next Steps (Stage 5)

Files to create in priority order:

1. `app/Services/SolutionEvaluator.php` — Scores complete timetable solution
2. `app/Jobs/GenerateTimetableJob.php` — Laravel Job for async queue dispatch
3. `app/Services/Generator/TabuSearchOptimizer.php` — Tabu Search post-generation optimizer
4. `app/Services/Generator/SimulatedAnnealingOptimizer.php` — SA optimizer
5. `app/Services/ConflictDetectionService.php` — Detect and log conflicts to `tt_conflict_detections`
6. `app/Services/ResourceBookingService.php` — Create `tt_resource_bookings` from timetable cells
7. Routes + controller methods: `dispatchGeneration`, `generationStatus`

**Key implementation notes:**
- Job must use `TimetableStorageService` (not session) to persist results
- Job updates `GenerationRun` status via `markRunning()`, `markCompleted()`, `markFailed()`
- `TtGenerationStrategy` provides all algorithm-specific parameters
- Queue driver is `database` — no additional config needed
