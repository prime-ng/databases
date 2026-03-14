# P01 — Critical Bug Fixes

**Phase:** 1 | **Priority:** P0 | **Effort:** 0.5 day
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** None — DO THIS FIRST

---

## Pre-Requisites

Read these files before starting:
1. `AI_Brain/rules/smart-timetable.md`
2. `AI_Brain/lessons/known-issues.md`
3. `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
4. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`

---

## Task 1.1 — Fix `set_time_limit` bug (1 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Line:** ~2591
**Change:** Find `set_time_limit($request->input('timeout', 120) * 60)` and change to:
```php
set_time_limit($request->input('timeout', 120));
```
**Why:** Currently multiplies by 60, allowing 2-hour PHP execution that can hang the server.
**Verify:** Search for `set_time_limit` — should NOT have `* 60`.

---

## Task 1.2 — Remove `saveGeneratedTimetable()` (5 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
**Line:** ~2843
**Change:**
1. Delete the entire `saveGeneratedTimetable()` method
2. Find its route in `routes/tenant.php` and remove it
3. Verify `storeTimetable()` is the sole save path

**Why:** This method deletes ALL timetables for the academic session before saving — data loss risk.
**Verify:** `grep -r "saveGeneratedTimetable" Modules/SmartTimetable/` returns 0 results.

---

## Task 1.3 — Fix `violatesNoConsecutiveRule()` for multi-period (15 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Line:** ~636-639
**Change:** Rewrite the method to check if ANOTHER instance of the same activity is adjacent, not if the current activity has `duration > 1`.

Current (broken):
```php
// Blocks all multi-period activities
if ($activity->duration > 1) return true;
```

Should be:
```php
// Check if another instance of same subject+class is in adjacent period
$adjacentPeriods = [$periodIndex - 1, $periodIndex + $activity->duration];
foreach ($adjacentPeriods as $adjPeriod) {
    $adjKey = "{$dayId}_{$adjPeriod}";
    // Check if same subject+class occupies adjacent slot
    // Only block if it's a DIFFERENT instance of the same activity type
}
```

**Why:** Labs, hobbies, practicals (duration > 1) are never placed in primary/greedy pass because they're incorrectly flagged as consecutive violations.
**Verify:** Run `/test --filter="consecutive"` if tests exist, or manually verify multi-period activities can be placed.

---

## Task 1.4 — Fix `Shift` model reference (2 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/TimetableTypeController.php`
**Lines:** 11, 29, 181
**Change:**
```php
// FROM:
use Modules\SmartTimetable\Models\Shift;
// TO:
use Modules\SmartTimetable\Models\SchoolShift;
```
Update all usages of `Shift::` to `SchoolShift::` in this file.

**Why:** `Shift` model doesn't exist — causes fatal class-not-found on create/edit pages.
**Verify:** Run `/lint Modules/SmartTimetable/app/Http/Controllers/TimetableTypeController.php`

---

## Task 1.5 — Fix `SchoolShiftController::edit()` view reference (1 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/SchoolShiftController.php`
**Line:** ~66
**Change:**
```php
// FROM:
return view('smarttimetable::School.edit', ...);
// TO:
return view('smarttimetable::shift.edit', ...);
```

**Why:** View `School.edit` doesn't exist — fatal ViewNotFound on shift edit page.
**Verify:** Check that `Modules/SmartTimetable/resources/views/shift/edit.blade.php` exists.

---

## Task 1.6 — Fix or remove `PeriodController` (10 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/PeriodController.php`
**Decision:**
- Check if `Period` model exists. It likely doesn't — the correct model is `PeriodSetPeriod`.
- If NOT needed: Delete `PeriodController.php` and remove its routes from `tenant.php`
- If needed: Create a thin wrapper model or alias to `PeriodSetPeriod`

**Why:** Entire controller crashes — missing model + missing views.
**Verify:** `php artisan route:list --path=smart-timetable/period` — no errors.

---

## Task 1.7 — Remove duplicate route registrations (5 min)

**File:** `routes/tenant.php`
**Lines:** ~1846 and ~1864
**Change:** Remove the SECOND `Route::resource('period', ...)` and second `Route::resource('school-timing-profile', ...)`.
- Keep the first occurrence of each
- Delete the duplicate

**Why:** Silent route conflicts — second registration silently overrides first.
**Verify:** `php artisan route:list --path=smart-timetable | grep -c "period"` — count should be 5 (standard resource) not 10.

---

## Task 1.8 — Remove `test-seeder` debug route (2 min)

**File 1:** `routes/tenant.php` line ~1767
**File 2:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` lines ~3091-3094

**Change:**
1. Remove route: `Route::get('test-seeder', ...)` from tenant.php
2. Remove method: `testSeeder()` from SmartTimetableController

**Why:** Dead endpoint accessible in production without any auth.
**Verify:** `grep -r "test-seeder" routes/tenant.php` returns 0 results.

---

## Task 1.9 — Fix `FETConstraintBridge` references (5 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETConstraintBridge.php`
**Change:**
1. Remove `use App\Services\Timetable\Constraints\ConstraintApplication;`
2. Remove `use \App\Models\TtActivity;`
3. Replace with correct imports or mark as TODO with safe fallback:
```php
use Modules\SmartTimetable\Models\Activity;
// TODO: Wire ConstraintApplication when DatabaseConstraintService is integrated
```

**Why:** References 2 non-existent classes — fatal if ever instantiated.
**Verify:** Run `/lint Modules/SmartTimetable/app/Services/Generator/FETConstraintBridge.php`

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/` — all files should pass
2. Run: `/test SmartTimetable` — existing 9 tests should still pass
3. Run: `php artisan route:list --path=smart-timetable` — no errors
4. Update AI Brain:
   - `progress.md` → Mark Phase 1 tasks as done
   - `known-issues.md` → Mark BUG-B1, BUG-B2, BUG-B3, BUG-NEW-01 through BUG-NEW-06 as RESOLVED
