# SmartTimetable — BUG-P1 + BUG-P2 Status & Next Prompts

**Last updated:** 2026-03-13
**Module:** SmartTimetable
**Original bug file:** `2026Mar12_BugFix_Backtrack_NonAnchor_AlreadyPlaced.md`

---

## ✅ STATUS: BUG-P1 AND BUG-P2 ARE ALREADY IMPLEMENTED

As of 2026-03-13, all 4 changes described in the original prompt files have been
verified as already present in the code:

| Change | File | Lines | Status |
|--------|------|-------|--------|
| `isPlaced(string $instanceKey): bool` | `TimetableSolution.php` | 199–203 | ✅ Done |
| Guard in `backtrack()` non-anchor block | `FETSolver.php` | 533–537 | ✅ Done |
| Rescue pass Case B — non-anchor sibling forced to anchor slot | `FETSolver.php` | 1487–1524 | ✅ Done |
| Rescue pass Case A — anchor rescued → siblings placed at same slot | `FETSolver.php` | 1644–1675 | ✅ Done |
| Rescue pass Case A (teacher-shuffled path) | `FETSolver.php` | 1588–1619 | ✅ Done |

**Move the original prompt files to `2-Claude_Prompt_Done/`.**

---

## NEXT PROMPT 1 — Wire `evaluateSoftConstraints()` into FETSolver

```
# Claude Prompt — SmartTimetable: Wire evaluateSoftConstraints() into FETSolver

**Date:** 2026-03-13
**Module:** SmartTimetable
**Laravel path:** `/home/tarun/Desktop/Apps/laravel/`
**Primary file:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Supporting file:** `Modules/SmartTimetable/app/Services/ConstraintManager.php`

---

## Context

Prime-AI SmartTimetable uses a 3-phase solver (backtrack → greedy → rescue).
The `ConstraintManager` service has a fully implemented `evaluateSoftConstraints()`
method that scores a placement against soft/preference constraints. It is never
called anywhere in `FETSolver.php`. As a result, soft constraints (teacher
preferences, room preferences, preferred time slots) have zero effect on the
generated timetable.

---

## Pre-Read (mandatory before coding)

Read these files in full before making any changes:

1. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — Focus on:
   - `getPossibleSlots()` method — where slots are scored and sorted
   - `scoreSlotForActivity()` method — current scoring logic
   - Any existing call sites for `constraintManager` (search `$this->constraintManager`)
2. `Modules/SmartTimetable/app/Services/ConstraintManager.php` — Focus on:
   - `evaluateSoftConstraints($slot, $activity, $context): float` — understand return
     value (higher = better), parameters, and what constraints it covers
   - `checkHardConstraints($slot, $activity, $context): bool` — already wired in
     `canPlaceWithConstraints()`, understand the pattern used there
3. `Modules/SmartTimetable/Claude_Context/` — Read any file describing soft
   constraints and scoring to understand what weight they should carry

---

## Problem

`FETSolver::scoreSlotForActivity()` returns a numeric score used to rank candidate
slots. Currently it only considers internal FETSolver preferences (period affinity,
teacher balance, distribution). It never calls
`$this->constraintManager->evaluateSoftConstraints()`.

`getPossibleSlots()` sorts by `scoreSlotForActivity()`. Since soft constraint scores
are never included, teacher/room/time preferences are silently ignored.

---

## The Fix

### Step 1 — Understand ConstraintManager::evaluateSoftConstraints()

Read the method signature and return value. Determine:
- Does it return a positive float (higher = better) or a penalty (lower = worse)?
- Can it throw exceptions? Does it need try/catch?
- Does it mutate any state?

### Step 2 — Add soft constraint score to scoreSlotForActivity()

In `FETSolver::scoreSlotForActivity($activity, Slot $slot, $context)`,
after the existing scoring logic, add the soft constraint score:

```php
// Add soft constraint preferences from ConstraintManager
try {
    $softScore = $this->constraintManager->evaluateSoftConstraints($slot, $activity, $context);
    $score += $softScore;
} catch (\Throwable $e) {
    \Log::warning('FET: evaluateSoftConstraints threw exception', [
        'activity_id' => $activity->original_activity_id ?? $activity->id ?? 'unknown',
        'slot' => ['day' => $slot->dayId, 'start' => $slot->startIndex],
        'error' => $e->getMessage(),
    ]);
}
```

Weight calibration: After reading `evaluateSoftConstraints()`, check if its
return values are in the same numeric range as existing `$score` values. If
`evaluateSoftConstraints()` returns values in [0–1] but existing scores are in
[0–10000], multiply by an appropriate weight (e.g., 500) so soft constraints
influence but don't dominate. Document the weight choice with a comment.

### Step 3 — Add verbose logging

```php
if ($this->verboseLogging) {
    \Log::debug('FET: Soft constraint score', [
        'activity_id' => $activity->original_activity_id ?? $activity->id,
        'slot' => ['day' => $slot->dayId, 'period' => $slot->startIndex],
        'soft_score' => $softScore ?? 0,
        'total_score' => $score,
    ]);
}
```

---

## Rules

1. Do NOT call `evaluateSoftConstraints()` in the rescue pass — rescue pass ignores
   all soft constraints by design.
2. Do NOT call `evaluateSoftConstraints()` inside `backtrack()` — only in scoring
   (which feeds `getPossibleSlots()`).
3. Do NOT change the signature of `scoreSlotForActivity()`.
4. Do NOT change `evaluateSoftConstraints()` in ConstraintManager — read only.
5. Wrap in try/catch — soft constraint failures must never crash the solver.
6. Do NOT extract into a new method — add inline in `scoreSlotForActivity()`.

---

## Verification

After the fix:
- Run timetable generation with `verboseLogging = true`
- Logs should show `FET: Soft constraint score` entries with non-zero `soft_score`
  for activities that have teacher/room/time preferences configured
- The generated timetable should respect preferred periods for teachers who have
  preferences set in the DB

---

## Summary of Changes

| # | File | Change | Location |
|---|------|--------|----------|
| 1 | `FETSolver.php` | Call `constraintManager->evaluateSoftConstraints()` and add result to score | Inside `scoreSlotForActivity()`, after existing scoring logic |
```

---

## NEXT PROMPT 2 — Parallel Group Feature: Pest 4.x Unit Tests

```
# Claude Prompt — SmartTimetable: Parallel Period Feature Tests (Pest 4.x)

**Date:** 2026-03-13
**Module:** SmartTimetable
**Laravel path:** `/home/tarun/Desktop/Apps/laravel/`
**Test framework:** Pest 4.x — use `it()` / `test()` syntax only, no PHPUnit classes
**Test path:** `tests/Unit/SmartTimetable/`

---

## Context

The parallel period feature is fully implemented in `FETSolver.php` and
`TimetableSolution.php`. The key behaviors that must be verified are:

1. `TimetableSolution::isPlaced()` correctly identifies placed/unplaced instances
2. Backtrack: when a non-anchor sibling is already placed, it is skipped (not backtracks)
3. Backtrack: when anchor is placed, all siblings are forced to the same slot
4. Rescue pass Case B: non-anchor sibling is forced to anchor's slot when anchor is placed
5. Rescue pass Case A: when anchor is rescued, all siblings are placed at same slot
6. Rescue pass: non-anchor sibling is skipped when anchor has NOT been placed yet

These are unit tests — no DB, no HTTP, no tenancy context.

---

## Pre-Read (mandatory before coding)

Read these files in full before writing any tests:

1. `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php` —
   Understand `place()`, `remove()`, `isPlaced()`, `getPlacements()`, `canPlace()`
2. `Modules/SmartTimetable/app/Services/Solver/Slot.php` — constructor signature
3. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` —
   Read `backtrack()` (~lines 493–645), rescue pass (~lines 1486–1525),
   `isNonAnchorParallelMember()`, `isAnchorActivity()`, `findActivitySlotInContext()`
4. `Modules/SmartTimetable/app/Models/Activity.php` — fields used in tests:
   `id`, `instance_id`, `original_activity_id`, `duration_periods`, `selected_teacher_id`
5. `tests/Pest.php` — confirm that Unit tests extend `Tests\TestCase` correctly
6. Any existing test in `tests/Unit/SmartTimetable/` — follow the same naming pattern

---

## Tests to Write

### File 1: `tests/Unit/SmartTimetable/TimetableSolutionIsPlacedTest.php`

Tests for `TimetableSolution::isPlaced()`:

- `it('returns false when instance has not been placed')`
- `it('returns true after a successful place() call')`
- `it('returns false after placement is removed via remove()')`
- `it('uses instance_id as the placement key, not raw activity id')`

### File 2: `tests/Unit/SmartTimetable/ParallelGroupBacktrackTest.php`

Tests for parallel group behavior in backtrack and rescue pass:

- `it('skips a non-anchor sibling that was already placed by its anchor')`
  Verify: when backtrack() index reaches a non-anchor sibling that isPlaced(),
  the solver advances to index+1 instead of returning false.

- `it('force-places non-anchor sibling at anchor slot when anchor is placed')`
  Verify: non-anchor sibling ends up at same day+period as anchor.

- `it('skips non-anchor sibling when anchor has not been placed yet')`
  Verify: solver advances index (does not return false) when anchor is absent.

- `it('places all siblings at same slot when anchor is placed in rescue pass')`
  Verify: after anchor rescue placement, siblings appear in getPlacements()
  at the same dayId + startIndex.

- `it('forces non-anchor sibling to anchor slot in rescue pass')`
  Verify: rescue pass Case B places sibling at anchor's exact slot.

---

## Activity Mock Helper

Since Activity is an Eloquent model, use stdClass mocks:

```php
function makeActivityInstance(int $id, string $instanceId, int $originalId, int $duration = 1): object
{
    $act = new \stdClass();
    $act->id = $id;
    $act->instance_id = $instanceId;
    $act->original_activity_id = $originalId;
    $act->duration_periods = $duration;
    $act->selected_teacher_id = null;
    $act->teachers = collect([]);
    return $act;
}
```

For TimetableSolution tests use the real class directly — it has no DB dependency,
only takes `Collection $days` and `Collection $periods`.

For FETSolver tests: if FETSolver cannot be instantiated without DB (check constructor),
create a minimal test subclass or test only TimetableSolution directly and verify
isPlaced() behavior is the single source of truth for the guard logic.

---

## Rules

1. No database calls — TimetableSolution is a pure in-memory class.
2. No RefreshDatabase — these are unit tests.
3. Use Pest 4.x `it()` syntax exclusively — no `class FooTest extends TestCase`.
4. Each `it()` block must test exactly ONE behavior.
5. Name test files with `Test.php` suffix.
6. Run with: `./vendor/bin/pest tests/Unit/SmartTimetable/`
7. If a test fails and it reveals a real bug → fix the app code, not the test.

---

## Summary

| # | File | Tests |
|---|------|-------|
| 1 | `TimetableSolutionIsPlacedTest.php` | 4 tests for `isPlaced()` |
| 2 | `ParallelGroupBacktrackTest.php` | 5 tests for parallel backtrack + rescue logic |
```
