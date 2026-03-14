# Bug Fix: Backtrack Non-Anchor Already-Placed Sibling Causes Unnecessary Backtrack

**Date:** 2026-03-12
**Type:** Bug Fix
**Module:** SmartTimetable
**Severity:** High — causes unnecessary backtracking, degrades solver performance
**Files to modify:** `FETSolver.php`, `TimetableSolution.php`
**Extracted from:** `2026Mar12_ParallelPeriod_SolverFix_Prompt.md` (BUG 1)

---

## Task

Fix a bug in `FETSolver::backtrack()` where a non-anchor parallel member that was **already placed** by its anchor's simultaneous-placement logic triggers an unnecessary backtrack when the solver's index pointer reaches it later in the activity ordering.

---

## Pre-Read (mandatory before coding)

Read these files **in full** before making any changes:

1. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — Focus on `backtrack()` method (lines 493-639), specifically the non-anchor handling block at lines 523-553.
2. `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php` — Full file (295 lines). Note that `getPlacements()` is at line 192.

---

## Problem

The parallel period system uses an **anchor-based** placement pattern:

1. Activity ordering (`orderActivitiesByDifficulty()`) boosts anchors +25000 and siblings +20000, so anchors appear first.
2. When `backtrack()` places an anchor (e.g., activity 101-1 at Day3/Period5), it **immediately** places all siblings (102-1, 103-1) at the same Day3/Period5 via the simultaneous-placement block at lines 577-634.
3. Later, the backtrack index pointer reaches sibling 102-1 in the sorted array.

At step 3, the non-anchor handling block (lines 527-553) runs:
- `isNonAnchorParallelMember(102)` returns the groupId
- `findActivitySlotInContext(101, $context)` finds the anchor is placed
- Constructs `$forcedSlot` = (6B classKey, Day3, Period5)
- Calls `isBasicSlotAvailable(...)` which returns **false** because `context->occupied[6B][Day3][Period5]` is already set to `102-1`
- Returns `false` — triggering a full backtrack cascade

**The sibling was already correctly placed. It should be skipped, not trigger a backtrack.**

---

## Fix: Two Changes

### Change 1 — Add `isPlaced()` to TimetableSolution.php

**File:** `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php`
**Where:** After the `getPlacements()` method (line 192)

Add this method:

```php
/**
 * Check if an activity instance is already placed in the solution.
 */
public function isPlaced(string $instanceKey): bool
{
    return isset($this->placements[$instanceKey]);
}
```

### Change 2 — Guard check in backtrack() non-anchor block

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Where:** Inside the `if ($anchorPlacedSlot !== null)` block at line 532, BEFORE the force-placement logic at line 534.

Add this check immediately after line 532 (`if ($anchorPlacedSlot !== null) {`):

```php
// If this instance was already placed by anchor's simultaneous placement, skip it
$instanceKey = $activity->instance_id ?? $activity->id;
if ($solution->isPlaced($instanceKey)) {
    return $this->backtrack($activities, $index + 1, $solution, $context);
}
```

This goes BEFORE the existing line `$classKey = $this->getClassKey($activity);` (line 534).

---

## Rules

1. Do NOT rename any existing methods or properties.
2. Do NOT change method signatures.
3. Do NOT modify the anchor simultaneous-placement block (lines 577-634) — it is correct.
4. Do NOT modify `isAnchorActivity()`, `isNonAnchorParallelMember()`, `findActivitySlotInContext()`, or `findInstanceForOriginalActivity()`.
5. Do NOT touch anything outside `FETSolver.php` and `TimetableSolution.php`.

---

## Verification

After the fix, when backtracking encounters a non-anchor sibling that was already placed by the anchor's simultaneous-placement, the log should show it was skipped (no backtrack). The solver should produce the same correct timetable but faster (fewer unnecessary backtracks).

**Expected log pattern:**
```
Backtrack encounters 102-1 at index i → ALREADY PLACED → skip (not backtrack)
Backtrack encounters 103-1 at index j → ALREADY PLACED → skip (not backtrack)
```

---

## Summary of Changes

| # | File | Change | Location |
|---|------|--------|----------|
| 1 | `TimetableSolution.php` | Add `isPlaced(string $instanceKey): bool` method | After `getPlacements()` (line 192) |
| 2 | `FETSolver.php` | Add `$solution->isPlaced()` guard before force-placing non-anchor in `backtrack()` | Inside `if ($anchorPlacedSlot !== null)` block, before line 534 |
