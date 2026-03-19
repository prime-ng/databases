# Real Bugs Found During Verification

These are actual runtime bugs discovered while cross-referencing Tarun's audit against the codebase. Some were in Tarun's report, some are new.

---

## CRITICAL — Will Crash at Runtime

### BUG-DDL-001: ClassWorkingDay Model Points to Wrong Table
- **Model:** `ClassWorkingDay.php` → `$table = 'tt_class_working_day_jnt'`
- **Migration creates:** `tt_class_working_days`
- **DDL has:** `tt_class_working_day_jnt`
- **Result:** Model queries `tt_class_working_day_jnt` which is the DDL name but migration created `tt_class_working_days`. If migration was run (which it was), the actual DB table is `tt_class_working_days`. Model will crash with "table not found".
- **Fix:** Change model `$table` to `tt_class_working_days` (matching migration)

### BUG-DDL-002: TeacherAvailabilityLog Model Points to Wrong Table
- **Model:** `TeacherAvailabilityLog.php` → `$table = 'tt_teacher_availability_details'`
- **Migration creates:** `tt_teacher_availability_logs`
- **DDL has:** `tt_teacher_availability_detail`
- **Result:** THREE different names — none match. Model queries `tt_teacher_availability_details` but DB has `tt_teacher_availability_logs`. Crash on any query.
- **Fix:** Change model `$table` to `tt_teacher_availability_logs` (matching migration)

### BUG-DDL-003: TimetableCell scopeForClass() Queries Non-Existent Columns
- **Model:** `TimetableCell.php` → `scopeForClass($query, $classId, $sectionId)`
- **Queries:** `->where('class_id', $classId)->where('section_id', $sectionId)`
- **Reality:** `tt_timetable_cells` has no `class_id` or `section_id` columns (neither DDL nor migration)
- **Result:** Runtime crash when filtering timetable cells by class/section
- **Fix:** Route through activity relationship: `->whereHas('activity', fn($q) => $q->where('class_id', $classId)->where('section_id', $sectionId))`

### BUG-DDL-004: 12 Phantom Models Referenced in Active Services
- **Services:** AnalyticsService, RefinementService, SubstitutionService, GenerateTimetableJob
- **Phantom tables:** `tt_analytics_daily_snapshots`, `tt_room_utilizations`, `tt_substitution_patterns`, `tt_substitution_recommendations`, `tt_conflict_resolution_sessions/options`, `tt_impact_analysis_sessions/details`, `tt_batch_operations/items`, `tt_constraint_target_types`, `tt_generation_queues`
- **Result:** Every P14-P17 feature will crash when it hits these models
- **Fix:** Create 12 migrations for these tables

### BUG-DDL-005: 10 DDL Tables Missing Migrations — Services Will Crash
- **Tables:** `tt_generation_strategy`, `tt_teacher_workloads`, `tt_constraint_violations`, `tt_change_logs`, `tt_teacher_absences`, `tt_substitution_logs`, `tt_room_availabilities`, `tt_room_availability_details`, `tt_priority_configs`, `tt_class_requirement_groups`
- **Result:** Analytics, Substitution, Refinement, and Room availability features all crash
- **Fix:** Create 10 migrations matching DDL column definitions (using plural table names)

---

## HIGH — Silent Data Loss / Wrong Results

### BUG-DDL-006: Model Fillable References Non-Existent Columns
- `Constraint` model: `apply_for_all_days` in `$fillable` — column doesn't exist in migration
- `ConstraintType` model: `conflict_detection_logic`, `validation_logic`, `resolution_priority` in `$fillable` — columns don't exist
- **Result:** `Model::create([...])` silently drops these values — data loss with no error
- **Fix:** Either add columns via migration or remove from `$fillable`

### BUG-DDL-007: Fix Migrations Create Dead Alias Columns
- Migration `2026_03_12_100002` adds 5 alias columns to `tt_constraints` (`academic_term_id`, `effective_from_date`, `effective_to_date`, `applicable_days_json`, `target_type_id`)
- **Nobody reads or writes these columns** — model uses original names
- **Result:** Dead columns in production DB; confusion during debugging
- **Fix:** Either wire model to use aliases or remove aliases via future migration

---

## MEDIUM — DDL Design Bugs

### BUG-DDL-008: DDL tt_activity References Undeclared Columns in INDEX/FK
- `tt_activity` DDL has `INDEX idx_class_group (class_group_id)` and `FOREIGN KEY (class_group_id)` but never declares `class_group_id` as a column
- Same for `class_subgroup_id`
- **Result:** DDL is invalid SQL — would fail if executed
- **Fix:** Either add column declarations or update index/FK references to match actual column names

### BUG-DDL-009: DDL Uses Singular Names, All Migrations Use Plural
- 28 out of 42 DDL tables use singular names while their corresponding migrations use plural
- **Result:** DDL cannot be used as reference without mental translation
- **Fix:** Update DDL to use plural names matching migrations

---

## Combined Impact Assessment

| Feature Area | Blocking Bugs | Can It Work Today? |
|---|---|---|
| Timetable Generation (core) | None | YES |
| Constraint Management CRUD | BUG-DDL-006 (silent data loss) | Partially |
| Analytics (P14) | BUG-DDL-004, BUG-DDL-005 | NO — crashes |
| Refinement (P15) | BUG-DDL-004, BUG-DDL-005 | NO — crashes |
| Substitution (P16) | BUG-DDL-004, BUG-DDL-005 | NO — crashes |
| API/Async Generation (P17) | BUG-DDL-004 | NO — crashes |
| Class Working Days | BUG-DDL-001 | NO — crashes |
| Teacher Availability Logs | BUG-DDL-002 | NO — crashes |

**Bottom line:** Core generation works. Everything added in P14-P17 will crash due to missing tables.
