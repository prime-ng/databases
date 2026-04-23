# SlotRequirement Daily Cap Enforcement — Implementation Guide
 
## Problem Summary
 
`tt_slot_requirements` and `SlotRequirement` model exist and are populated via the Foundation
module UI, but **the timetable generator (FETSolver) never reads or enforces them**.
 
The `daily_slots_distribution_json` column is declared in the model's `$fillable` and `$casts`
but **has no migration** (not in the DB yet) and **is never saved or checked anywhere**.
 
This is the only mechanism in the system for encoding per-class, per-day slot caps.
Until enforced in FETSolver, those caps are dead configuration.
 
---
 
## Data Model Facts
 
### `tt_slot_requirements` columns (from migrations):
| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT UNSIGNED PK | |
| `academic_term_id` | INT UNSIGNED FK → `sch_academic_term.id` | Term scoping |
| `timetable_type_id` | INT UNSIGNED FK → `tt_timetable_types.id` | |
| `class_timetable_type_id` | INT UNSIGNED FK → `tt_class_timetable_type_jnt.id` | |
| `class_id` | INT UNSIGNED FK → `sch_classes.id` | |
| `section_id` | INT UNSIGNED FK → `sch_sections.id` | |
| `class_house_room_id` | INT UNSIGNED nullable | |
| `weekly_total_slots` | TINYINT UNSIGNED | |
| `weekly_teaching_slots` | TINYINT UNSIGNED | |
| `weekly_exam_slots` | TINYINT UNSIGNED | |
| `weekly_free_slots` | TINYINT UNSIGNED | |
| `activity_id` | INT UNSIGNED nullable | |
| `is_active` | BOOLEAN default 1 | |
| `daily_slots_distribution_json` | **MISSING — not in any migration** | Per-day slot caps |
 
### `daily_slots_distribution_json` intended structure:
```json
{
  "Monday": 8,
  "Tuesday": 8,
  "Wednesday": 6,
  "Thursday": 8,
  "Friday": 6
}
```
Keys are `SchoolDay->name` values (from `tt_school_days.name`).
Values are the maximum number of teaching slots allowed for that class on that day.
 
---
 
## classKey Format (critical for mapping)
 
FETSolver uses `classKey` = `class->code . '-' . section->code`
(e.g., `"10A-A"`, `"9B-B"`)
 
`tt_slot_requirements` stores `class_id` (INT) and `section_id` (INT).
 
When pre-loading slot requirements, you MUST join to `sch_classes` and `sch_sections`
to get `code` values for building the matching classKey.
 
---
 
## Current State of FETSolver
 
**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
 
- `SlotRequirement` is **NOT imported** anywhere in FETSolver
- `tt_slot_requirements` is **NEVER queried** during generation
- `isBasicSlotAvailable()` (lines 824–898) has 8 checks but **no daily cap check from SlotRequirement**
- Data pre-loading in `solve()` (lines 417–468) loads teacher names, class-teacher maps, and
  constraint context — **no slot requirement loading**
 
**Existing checks in `isBasicSlotAvailable()` for reference:**
1. Pinned period rule
2. Daily activity placement cap (single-activity-once-per-day)
3. No-consecutive rule
4. Min gap rule
5. Class-teacher first lecture
6. Period bounds check
7. Class occupancy (`context->occupied[classKey][dayId][periodId]`)
8. Teacher occupancy (`context->teacherOccupied[teacherId][dayId][periodId]`)
**⑨ Daily cap from SlotRequirement → MISSING (TODO)**
 
---
 
## Where `generateWithFET` Creates the Solver
 
**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Lines:** 2694–2703
 
```php
$solver = new FETSolver($days, $periods, $constraintManager, [
    'class_teacher_first_lecture' => $classTeacherFirstLectureEnabled,
    'single_activity_once_per_day_until_overflow' => $singleActivityOncePerDayUntilOverflow,
    'pin_activities_by_period' => $pinActivitiesByPeriod,
    'parallel_groups' => $parallelGroups,
]);
// ...
$entries = $solver->solve($activities);
```
 
Options are passed as array in 4th constructor param. FETSolver reads them in `__construct`.
Follow the same pattern to pass `slot_requirements_map` — consistent with `parallel_groups`.
 
---
 
## Full Implementation Plan (4 steps)
 
### Step 1 — Migration: Add `daily_slots_distribution_json` column
 
Create a **tenant migration** (path: `database/migrations/tenant/`):
 
```php
Schema::table('tt_slot_requirements', function (Blueprint $table) {
    if (!Schema::hasColumn('tt_slot_requirements', 'daily_slots_distribution_json')) {
        $table->json('daily_slots_distribution_json')->nullable()->after('weekly_free_slots');
    }
});
```
 
Run: `php artisan tenants:migrate`
 
---
 
### Step 2 — Controller/Form: Save the JSON
 
In `Modules/TimetableFoundation/app/Http/Controllers/SlotRequirementController.php`:
 
Add to `$request->validate()`:
```php
'daily_slots_distribution_json' => 'nullable|array',
'daily_slots_distribution_json.*' => 'nullable|integer|min:0|max:20',
```
 
The form should post `daily_slots_distribution_json[Monday]=8`, etc. — one input per school day.
In the view, loop `SchoolDay::schoolDays()->ordered()->get()` to render the day inputs dynamically.
 
---
 
### Step 3 — Pre-load slot requirements in `generateWithFET`
 
In `SmartTimetableController::generateWithFET()`, after `$parallelGroups` is loaded and before
`new FETSolver(...)` is called, add:
 
```php
// Pre-load daily slot caps keyed by classKey → [dayName => cap]
$slotReqMap = SlotRequirement::with(['class', 'section'])
    ->where('academic_term_id', $validated['academic_term_id'])
    ->where('timetable_type_id', $validated['timetable_type_id'])
    ->where('is_active', true)
    ->whereNotNull('daily_slots_distribution_json')
    ->get()
    ->mapWithKeys(function ($sr) {
        $classKey = ($sr->class->code ?? 'unknown') . '-' . ($sr->section->code ?? 'unknown');
        return [$classKey => $sr->daily_slots_distribution_json];
    })
    ->all();
```
 
Pass it to the solver options:
```php
$solver = new FETSolver($days, $periods, $constraintManager, [
    // ... existing options ...
    'slot_requirements_map' => $slotReqMap,   // add this
]);
```
 
---
 
### Step 4 — FETSolver: Pre-load in constructor + enforce in `isBasicSlotAvailable`
 
#### 4a. Add property and load in constructor
 
In `FETSolver::__construct()`:
```php
// Add to constructor options reading (alongside other option reads):
$this->dailySlotCapByClassKey = $options['slot_requirements_map'] ?? [];
 
// Add a day-id-to-name lookup map from the $days collection:
$this->dayIdToName = $days->keyBy('id')->map(fn($d) => $d->name)->all();
```
 
Declare as class properties:
```php
private array $dailySlotCapByClassKey = [];
private array $dayIdToName = [];
```
 
#### 4b. Add check ⑨ in `isBasicSlotAvailable()` (lines 824–898)
 
Insert AFTER the class-teacher-first check (line ~870) and BEFORE the period loop (line ~872):
 
```php
// ⑨ Daily cap from SlotRequirement.daily_slots_distribution_json
if (!empty($this->dailySlotCapByClassKey[$classKey])) {
    $dayName = $this->dayIdToName[$slot->dayId] ?? null;
    if ($dayName !== null) {
        $cap = $this->dailySlotCapByClassKey[$classKey][$dayName] ?? null;
        if ($cap !== null) {
            $alreadyPlaced = count($context->occupied[$classKey][$slot->dayId] ?? []);
            if ($alreadyPlaced >= $cap) {
                return false;
            }
        }
    }
}
```
 
**Note:** `$context->occupied[$classKey][$slot->dayId]` is a map of `[periodId => token]` for
every period already assigned to this class on this day. `count()` gives total periods placed.
For multi-period activities (`duration_periods > 1`), the cap check should use the count
of placed period slots (not activities). This correctly hard-blocks oversaturation.
 
---
 
## Key Mapping Reference
 
| FETSolver concept | Source |
|-------------------|--------|
| `classKey` | `class->code . '-' . section->code` (e.g. `"9A-A"`) |
| `$slot->dayId` | `tt_school_days.id` |
| Day name for JSON key | `tt_school_days.name` (e.g. "Monday") |
| Cap value | `daily_slots_distribution_json["Monday"]` (int) |
| Occupancy counter | `count($context->occupied[$classKey][$slot->dayId] ?? [])` |
 
---
 
## Validation Notes
 
- If a `SlotRequirement` row exists for a class-section but `daily_slots_distribution_json`
  is null/empty, the cap is simply **not enforced** (fallback = no limit).
- If a class has no `SlotRequirement` row at all, the cap is also **not enforced**.
- This is a **hard block** — not a soft constraint — because it returns `false` from
  `isBasicSlotAvailable()`.
 
---
 
## Files to Touch (in order)
 
1. `database/migrations/tenant/YYYY_MM_DD_add_daily_slots_json_to_tt_slot_requirements.php` — create
2. `Modules/TimetableFoundation/app/Http/Controllers/SlotRequirementController.php` — validate + save JSON
3. `Modules/TimetableFoundation/resources/views/slot-requirement/` — add day inputs to form
4. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` — pre-load map, pass to solver
5. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — add property, read option, add check ⑨