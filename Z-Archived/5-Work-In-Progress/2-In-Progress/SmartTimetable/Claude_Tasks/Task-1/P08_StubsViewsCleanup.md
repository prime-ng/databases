# P08 — Stub Controllers, Missing Views & Dead Code Cleanup

**Phase:** 6 | **Priority:** P1 | **Effort:** 2 days
**Skill:** Backend + Frontend + Cleanup | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P04 (Phase 2 security must be done — auth is added first, then stubs implemented)

---

## Pre-Requisites

Read these files before starting:
1. `Modules/SmartTimetable/app/Http/Controllers/TimetableController.php`
2. `Modules/SmartTimetable/app/Http/Controllers/WorkingDayController.php`
3. `Modules/SmartTimetable/resources/views/` — list directory to see existing views
4. Reference a working controller like `SchoolDayController.php` for CRUD patterns

---

## Task 6.1 — Implement TimetableController (4 hrs)

**File:** `Modules/SmartTimetable/app/Http/Controllers/TimetableController.php`

Read the existing stub first. Implement `store()`, `update()`, `destroy()`:

```php
public function store(Request $request)
{
    Gate::authorize('smart-timetable.timetable.create');

    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'academic_session_id' => 'required|exists:sch_organization_academic_sessions,id',
        'timetable_type_id' => 'required|exists:tt_timetable_types,id',
        'description' => 'nullable|string|max:500',
        'is_active' => 'boolean',
    ]);

    $validated['created_by'] = auth()->id();

    $timetable = Timetable::create($validated);

    return redirect()
        ->route('smart-timetable.timetable.show', $timetable)
        ->with('success', 'Timetable created successfully.');
}

public function update(Request $request, Timetable $timetable)
{
    Gate::authorize('smart-timetable.timetable.update');

    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'timetable_type_id' => 'required|exists:tt_timetable_types,id',
        'description' => 'nullable|string|max:500',
        'is_active' => 'boolean',
    ]);

    $timetable->update($validated);

    return redirect()
        ->route('smart-timetable.timetable.index')
        ->with('success', 'Timetable updated successfully.');
}

public function destroy(Timetable $timetable)
{
    Gate::authorize('smart-timetable.timetable.delete');

    $timetable->delete();

    return redirect()
        ->route('smart-timetable.timetable.index')
        ->with('success', 'Timetable deleted successfully.');
}
```

Also implement `index()` and `show()` if they're stubs:
```php
public function index()
{
    Gate::authorize('smart-timetable.timetable.viewAny');

    $timetables = Timetable::with('timetableType')
        ->where('is_active', true)
        ->orderByDesc('created_at')
        ->paginate(15);

    return view('smarttimetable::timetable.index', compact('timetables'));
}

public function show(Timetable $timetable)
{
    Gate::authorize('smart-timetable.timetable.view');

    $timetable->load(['timetableType', 'cells.activity.subject', 'cells.activity.teacher']);

    return view('smarttimetable::timetable.show', compact('timetable'));
}
```

---

## Task 6.2 — Implement WorkingDayController stubs (2 hrs)

**File:** `Modules/SmartTimetable/app/Http/Controllers/WorkingDayController.php`

Read existing stub. Implement `store()`, `update()`, `destroy()`:

```php
public function store(Request $request)
{
    Gate::authorize('smart-timetable.working-day.create');

    $validated = $request->validate([
        'name' => 'required|string|max:100',
        'day_number' => 'required|integer|min:1|max:7',
        'is_active' => 'boolean',
    ]);

    $validated['created_by'] = auth()->id();

    WorkingDay::create($validated);

    return redirect()
        ->route('smart-timetable.working-day.index')
        ->with('success', 'Working day created.');
}

public function update(Request $request, WorkingDay $workingDay)
{
    Gate::authorize('smart-timetable.working-day.update');

    $validated = $request->validate([
        'name' => 'required|string|max:100',
        'day_number' => 'required|integer|min:1|max:7',
        'is_active' => 'boolean',
    ]);

    $workingDay->update($validated);

    return redirect()
        ->route('smart-timetable.working-day.index')
        ->with('success', 'Working day updated.');
}

public function destroy(WorkingDay $workingDay)
{
    Gate::authorize('smart-timetable.working-day.delete');

    $workingDay->delete();

    return redirect()
        ->route('smart-timetable.working-day.index')
        ->with('success', 'Working day deleted.');
}
```

---

## Task 6.3 — Create missing views (2 hrs)

**Skill: Frontend**

### 6.3.1 — `slot-requirement/show.blade.php`

**File:** `Modules/SmartTimetable/resources/views/slot-requirement/show.blade.php`

Check what data `SlotRequirementController::show()` passes. Create a basic show view:

```blade
@extends('smarttimetable::layouts.master')

@section('content')
<div class="card">
    <div class="card-header">
        <h3 class="card-title">Slot Requirement Details</h3>
        <div class="card-tools">
            <a href="{{ route('smart-timetable.slot-requirement.index') }}" class="btn btn-sm btn-secondary">Back</a>
        </div>
    </div>
    <div class="card-body">
        <table class="table table-bordered">
            <tr><th>Name</th><td>{{ $slotRequirement->name ?? '' }}</td></tr>
            <tr><th>Day</th><td>{{ $slotRequirement->schoolDay->name ?? '' }}</td></tr>
            <tr><th>Period</th><td>{{ $slotRequirement->period->name ?? '' }}</td></tr>
            <tr><th>Status</th><td>{!! $slotRequirement->is_active ? '<span class="badge bg-success">Active</span>' : '<span class="badge bg-danger">Inactive</span>' !!}</td></tr>
        </table>
    </div>
</div>
@endsection
```

### 6.3.2 — `shift/edit.blade.php`

**File:** `Modules/SmartTimetable/resources/views/shift/edit.blade.php`

Check if `shift/create.blade.php` exists and base the edit view on it:

```blade
@extends('smarttimetable::layouts.master')

@section('content')
<div class="card">
    <div class="card-header">
        <h3 class="card-title">Edit Shift</h3>
    </div>
    <div class="card-body">
        <form action="{{ route('smart-timetable.school-shift.update', $schoolShift) }}" method="POST">
            @csrf
            @method('PUT')
            <div class="form-group">
                <label for="name">Shift Name</label>
                <input type="text" class="form-control @error('name') is-invalid @enderror"
                    name="name" value="{{ old('name', $schoolShift->name) }}" required>
                @error('name') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
            <div class="form-group">
                <label for="start_time">Start Time</label>
                <input type="time" class="form-control" name="start_time"
                    value="{{ old('start_time', $schoolShift->start_time) }}">
            </div>
            <div class="form-group">
                <label for="end_time">End Time</label>
                <input type="time" class="form-control" name="end_time"
                    value="{{ old('end_time', $schoolShift->end_time) }}">
            </div>
            <button type="submit" class="btn btn-primary">Update</button>
            <a href="{{ route('smart-timetable.school-shift.index') }}" class="btn btn-secondary">Cancel</a>
        </form>
    </div>
</div>
@endsection
```

### 6.3.3 — Period views (if PeriodController is kept)

Only create these if P01 Task 1.6 decided to KEEP PeriodController. If PeriodController was deleted, skip this.

---

## Task 6.4 — Delete dead code (30 min)

**Skill: Cleanup**

### 6.4.1 — Delete backup controller

```bash
rm Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController_29_01_before_store.php
```

### 6.4.2 — Delete copy directory

```bash
rm -rf Modules/SmartTimetable/resources/views/class-group-requirement\ copy/
```

### 6.4.3 — Delete generate-timetable variant directories

```bash
rm -rf Modules/SmartTimetable/resources/views/partials/generate-timetable_2/
rm -rf Modules/SmartTimetable/resources/views/partials/generate-timetable_3/
rm -rf Modules/SmartTimetable/resources/views/partials/generate-timetable_4/
rm -rf Modules/SmartTimetable/resources/views/partials/generate-timetable_5/
```

**Before deleting:** Verify these directories exist and contain only dead/unused code by searching for any includes:
```bash
grep -r "generate-timetable_2\|generate-timetable_3\|generate-timetable_4\|generate-timetable_5" Modules/SmartTimetable/resources/views/
```

If any includes are found, do NOT delete that directory.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/` — all files pass
2. Run: `/test SmartTimetable` — all tests pass
3. Run: `php artisan route:list --path=smart-timetable` — no errors
4. Verify deleted files don't break anything: `php artisan view:cache` — no errors
5. Update AI Brain:
   - `known-issues.md` → Mark BUG-NEW-06 (TimetableController stubs), QUAL-NEW-05, QUAL-NEW-06 as RESOLVED
   - `progress.md` → Phase 6 done
