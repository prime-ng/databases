# P06 — Performance Optimization

**Phase:** 4 | **Priority:** P1 | **Effort:** 2 days
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** None (can run in parallel with P05)

---

## Pre-Requisites

Read these files before starting:
1. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` — focus on `index()` (~line 93-100) and `generateWithFET()`
2. `Modules/SmartTimetable/app/Http/Controllers/TeacherAvailabilityController.php` — `generateTeacherAvailability()` method
3. `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php` — all `updateOrCreate` call sites
4. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — Log statements

---

## Task 4.1 — Convert session storage to plain arrays (30 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`

**Problem:** Eloquent collections stored in session serialize to 10-50MB.

**Find all** `session()->put(...)` or `session([...])` calls that store Eloquent models/collections.

**Change each to:**
```php
// BEFORE:
session()->put('activities', $activities);

// AFTER:
session()->put('activities', $activities->map(fn($a) => $a->only([
    'id', 'name', 'subject_id', 'class_section_id', 'teacher_ids',
    'weekly_periods', 'duration', 'priority'
]))->toArray());
```

Or if using `session([])`:
```php
// BEFORE:
session(['timetable_data' => $timetableData]);

// AFTER:
session(['timetable_data' => $timetableData->toArray()]);
```

**Rule:** Never store Eloquent models or collections in session. Always convert to `->toArray()` or `->only([...])`.

---

## Task 4.2 — Batch `updateOrCreate` in TeacherAvailabilityController (1 hr)

**File:** `Modules/SmartTimetable/app/Http/Controllers/TeacherAvailabilityController.php`
**Lines:** ~101-261

**Problem:** `updateOrCreate` inside 2 nested loops → 500+ individual queries for 50 subjects x 5 teachers.

**Change:** Collect all rows first, then use `upsert()`:

```php
// BEFORE (pseudocode):
foreach ($subjects as $subject) {
    foreach ($days as $day) {
        TeacherAvailablity::updateOrCreate(
            ['teacher_id' => ..., 'day_id' => ..., 'subject_id' => ...],
            ['is_available' => ..., ...]
        );
    }
}

// AFTER:
$rows = [];
foreach ($subjects as $subject) {
    foreach ($days as $day) {
        $rows[] = [
            'teacher_id' => $teacherId,
            'day_id' => $day->id,
            'subject_id' => $subject->id,
            'is_available' => $value,
            'academic_session_id' => $sessionId,
            'created_by' => auth()->id(),
            'created_at' => now(),
            'updated_at' => now(),
        ];
    }
}

TeacherAvailablity::upsert(
    $rows,
    ['teacher_id', 'day_id', 'subject_id', 'academic_session_id'], // unique keys
    ['is_available', 'updated_at'] // columns to update on conflict
);
```

**Note:** Check the actual unique constraint on the `tt_teacher_availability` table before setting the unique keys array.

---

## Task 4.3 — Batch `updateOrCreate` in ActivityController (1 hr)

**File:** `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`
**6 call sites:** Lines ~225, 464, 548, 746, 831, 1117

**Same pattern as Task 4.2.** For each call site:
1. Identify the loop containing `updateOrCreate`
2. Collect rows into an array
3. Replace with `Activity::upsert($rows, $uniqueKeys, $updateColumns)`

**Example transformation:**
```php
// BEFORE:
foreach ($classSubjectSubgroups as $css) {
    Activity::updateOrCreate(
        ['class_subject_subgroup_id' => $css->id, 'academic_session_id' => $sessionId],
        ['name' => ..., 'weekly_periods' => ..., ...]
    );
}

// AFTER:
$rows = collect($classSubjectSubgroups)->map(fn($css) => [
    'class_subject_subgroup_id' => $css->id,
    'academic_session_id' => $sessionId,
    'name' => "...",
    'weekly_periods' => $css->weekly_periods ?? 1,
    'created_by' => auth()->id(),
    'created_at' => now(),
    'updated_at' => now(),
])->all();

Activity::upsert($rows, ['class_subject_subgroup_id', 'academic_session_id'], ['name', 'weekly_periods', 'updated_at']);
```

---

## Task 4.4 — Replace `::all()` with scoped queries (30 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Lines:** ~93-100

**Find:** All `Model::all()` calls in `index()` and other methods.

**Change each to:**
```php
// BEFORE:
$schoolDays = SchoolDay::all();
$schoolShifts = SchoolShift::all();
$periodTypes = PeriodType::all();

// AFTER:
$schoolDays = Cache::remember('st_school_days_' . tenant('id'), 3600, fn() =>
    SchoolDay::where('is_active', true)->select('id', 'name', 'day_code')->get()
);

$schoolShifts = Cache::remember('st_school_shifts_' . tenant('id'), 3600, fn() =>
    SchoolShift::where('is_active', true)->select('id', 'name')->get()
);

$periodTypes = Cache::remember('st_period_types_' . tenant('id'), 3600, fn() =>
    PeriodType::where('is_active', true)->select('id', 'name', 'code')->get()
);
```

Add import: `use Illuminate\Support\Facades\Cache;`

**Rule:** Never use `::all()` — always scope with `where('is_active', true)` and `select()`.

---

## Task 4.5 — Gate excessive logging behind config flag (15 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`

**Change:** Ensure ALL `\Log::info()` calls during constraint checking are gated:

```php
// Check: is $this->verboseLogging already used?
// If yes, ensure ALL log calls use it
// If no, add the property and gate all logs

if ($this->verboseLogging) {
    \Log::info("Constraint check for activity {$activity->id}: ...");
}
```

**Find all ungated Log calls:**
```bash
grep -n "\\\\Log::" FETSolver.php | grep -v "verboseLogging"
```

Each one found should be wrapped in `if ($this->verboseLogging)`.

---

## Task 4.6 — Concurrent generation protection (2 hrs)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Method:** `generateWithFET()`

**Change:** Add a cache-based lock at the start of generation:

```php
public function generateWithFET(Request $request)
{
    Gate::authorize('smart-timetable.timetable.generate');

    $academicSessionId = $request->input('academic_session_id');
    $lockKey = "timetable-gen-" . tenant('id') . "-{$academicSessionId}";

    $lock = Cache::lock($lockKey, 300); // 5-minute lock

    if (!$lock->get()) {
        return back()->with('error', 'Timetable generation is already in progress. Please wait.');
    }

    try {
        // ... existing generation code ...
    } finally {
        $lock->release();
    }
}
```

Add import: `use Illuminate\Support\Facades\Cache;`

**Why:** Without this, two users can trigger generation simultaneously, causing race conditions and corrupted data.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/` — all files pass
2. Run: `/test SmartTimetable` — all tests pass
3. Verify no `::all()` remains in SmartTimetableController: `grep -n "::all()" SmartTimetableController.php`
4. Verify no ungated Log calls in FETSolver: `grep -n "Log::" FETSolver.php | grep -v verboseLogging`
5. Update AI Brain:
   - `known-issues.md` → Mark BUG-B4 (session storage), PERF-NEW-01, PERF-NEW-02, PERF-NEW-03 as RESOLVED
   - `progress.md` → Phase 4 done
