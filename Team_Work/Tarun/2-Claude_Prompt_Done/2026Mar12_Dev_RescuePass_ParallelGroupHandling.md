# Development: Add Parallel Group Handling to Rescue Pass

**Date:** 2026-03-12
**Type:** Development (new feature in existing solver)
**Module:** SmartTimetable
**Priority:** High — without this, rescue pass breaks parallel group synchronization
**File to modify:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Depends on:** BUG 1 fix must be applied first (`TimetableSolution::isPlaced()` method must exist)
**Extracted from:** `2026Mar12_ParallelPeriod_SolverFix_Prompt.md` (BUG 2)

---

## Task

Add parallel group awareness to the **rescue pass** inside `generateGreedySolution()`. Currently, the rescue pass (lines 1450-1594) iterates over unplaced activities and places them in any free slot — but has **zero** parallel group logic. This means:

1. When an **anchor** is rescued, its siblings are NOT simultaneously placed at the same slot.
2. When a **non-anchor sibling** is rescued, it gets placed at any free slot independently, breaking the parallel group's same-time requirement.

The greedy main loop (lines 1376-1401) already handles parallel sibling placement correctly. The rescue pass needs the same treatment.

---

## Pre-Read (mandatory before coding)

Read these files **in full** before making any changes:

1. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — Focus on:
   - `generateGreedySolution()` method (lines 1351-1869)
   - Greedy main loop parallel handling (lines 1376-1401) — use as **reference pattern**
   - Rescue pass loop (lines 1458-1594) — this is where changes go
2. `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php` — For `isPlaced()` and `getPlacements()` methods.

---

## Context: How the Rescue Pass Works Currently

```
Line 1458: if ($placed < count($activities))     ← enters rescue if activities remain unplaced
Line 1459-1462: Build $unplacedActivities array   ← filters out already-placed instances
Line 1465: $rescued = 0
Line 1480: foreach ($unplacedActivities as $activity)  ← main rescue loop
Line 1486:     foreach ($this->days as $day)            ← try each day
Line 1492:         for ($teachingStart = ...)           ← try each period slot
Line 1560:             if ($solution->place(...))       ← successful placement
Line 1585: end foreach
```

The rescue pass has NO concept of parallel groups, anchors, or siblings.

---

## Implementation: Two Additions to the Rescue Pass

### Addition 1 — Non-anchor sibling detection (Case B)

**Where:** At the **very top** of `foreach ($unplacedActivities as $activity)` (line 1480), BEFORE the existing `$classKey = $this->getClassKey($activity);` at line 1481.

**Logic:** Before the rescue pass tries to find any free slot for this activity, check if it's a non-anchor parallel member. If so, force it to the anchor's slot (if anchor is placed) or skip it entirely (if anchor is not placed).

```php
// ── PARALLEL GROUP: Non-anchor sibling handling in rescue pass ──
$rescueOrigActId = (int) ($activity->original_activity_id ?? $activity->id ?? 0);
$rescueNonAnchorGroupId = $this->isNonAnchorParallelMember($rescueOrigActId);
if ($rescueNonAnchorGroupId !== null) {
    $anchorId = $this->parallelGroupAnchors[$rescueNonAnchorGroupId];
    $anchorSlot = $this->findActivitySlotInContext($anchorId, $context);
    if ($anchorSlot !== null) {
        // Force to anchor's slot
        $sibClassKey = $this->getClassKey($activity);
        $forcedSlot = new Slot($sibClassKey, $anchorSlot->dayId, $anchorSlot->startIndex);
        if ($this->isBasicSlotAvailable($activity, $forcedSlot, $context, true, true, true, true)
            && $solution->place($activity, $forcedSlot)) {
            $context = $this->simulatePlacement($activity, $forcedSlot, $context);
            $rescued++;
            $placed++;
            \Log::info('Rescue pass: Non-anchor sibling forced to anchor slot', [
                'group_id' => $rescueNonAnchorGroupId,
                'activity_id' => $rescueOrigActId,
                'instance' => $activity->instance_id ?? null,
                'slot' => ['day' => $anchorSlot->dayId, 'period' => $anchorSlot->startIndex],
            ]);
        } else {
            \Log::warning('Rescue pass: Cannot force non-anchor sibling to anchor slot', [
                'group_id' => $rescueNonAnchorGroupId,
                'activity_id' => $rescueOrigActId,
                'instance' => $activity->instance_id ?? null,
            ]);
        }
        continue; // Skip the normal free-slot search — sibling must follow anchor
    }
    // Anchor not placed yet — skip this sibling entirely
    \Log::warning('Rescue pass: Non-anchor sibling skipped — anchor not placed', [
        'group_id' => $rescueNonAnchorGroupId,
        'activity_id' => $rescueOrigActId,
        'instance' => $activity->instance_id ?? null,
    ]);
    continue;
}
// ── END PARALLEL GROUP non-anchor handling ──
```

This block ends with `continue;` in all branches, so the normal day/period search loop is completely skipped for non-anchor siblings.

### Addition 2 — Anchor sibling placement (Case A)

**Where:** Immediately after a successful placement in the rescue pass. There are **two** placement success points:

1. **Teacher-shuffled placement** (line 1528-1533): After `$solution->place($activity, $slot)` succeeds with an alternative teacher.
2. **Normal placement** (line 1560-1566): After `$solution->place($activity, $slot)` succeeds normally.

Add the same sibling-placement block after BOTH success points, right after the `$placed++; $rescued++;` lines and BEFORE the `break;` statement.

```php
// ── PARALLEL GROUP: If anchor was rescued, place siblings at same slot ──
$rescuedOrigActId = (int) ($activity->original_activity_id ?? $activity->id ?? 0);
if (isset($this->activityParallelMap[$rescuedOrigActId])) {
    foreach ($this->activityParallelMap[$rescuedOrigActId] as $pgId) {
        if (($this->parallelGroupAnchors[$pgId] ?? null) !== $rescuedOrigActId) continue;
        foreach ($this->parallelGroupActivityIds[$pgId] as $sibId) {
            if ($sibId === $rescuedOrigActId) continue;
            // Find unplaced instance of this sibling in the unplaced list
            foreach ($unplacedActivities as $sibActivity) {
                $sibOrigId = (int) ($sibActivity->original_activity_id ?? $sibActivity->id ?? 0);
                if ($sibOrigId !== $sibId) continue;
                $sibInstanceKey = $sibActivity->instance_id ?? $sibActivity->id;
                if ($solution->isPlaced($sibInstanceKey)) continue; // already placed
                $sibClassKey = $this->getClassKey($sibActivity);
                $sibSlot = new Slot($sibClassKey, $slot->dayId, $slot->startIndex);
                if ($this->isBasicSlotAvailable($sibActivity, $sibSlot, $context, true, true, true, true)
                    && $solution->place($sibActivity, $sibSlot)) {
                    $context = $this->simulatePlacement($sibActivity, $sibSlot, $context);
                    $rescued++;
                    $placed++;
                    \Log::info('Rescue pass: Placed parallel sibling with anchor', [
                        'group_id' => $pgId,
                        'sibling_id' => $sibId,
                        'instance' => $sibActivity->instance_id ?? null,
                        'slot' => ['day' => $slot->dayId, 'period' => $slot->startIndex],
                    ]);
                }
                break; // Only place one instance of this sibling per anchor instance
            }
        }
    }
}
// ── END PARALLEL GROUP anchor sibling placement ──
```

**Important:** This block must appear in BOTH placement-success branches (teacher-shuffled at ~line 1533 and normal at ~line 1565), before the `break;` that exits the period loop.

---

## Rules

1. Do NOT rename any existing methods or properties.
2. Do NOT change method signatures.
3. Do NOT modify the greedy main loop parallel handling (lines 1376-1401) — it is correct.
4. Do NOT modify `initializeParallelGroups()`, `isAnchorActivity()`, `isNonAnchorParallelMember()`, `findActivitySlotInContext()`, or `findInstanceForOriginalActivity()`.
5. Do NOT extract this logic into a separate service class. Keep all changes inside FETSolver.php.
6. `isBasicSlotAvailable()` with all four `true` flags is the correct call for parallel siblings (bypasses soft rules).
7. Log every parallel group decision with `\Log::info()` or `\Log::warning()`.
8. Only modify `generateGreedySolution()` — do NOT touch `backtrack()` (that is handled in the separate bug fix prompt).

---

## Verification

After implementation, for a school with a "Class 6 Hobby" parallel group (activities 101, 102, 103):

**If anchor 101-3 reaches the rescue pass:**
```
Rescue pass: Placing 101-3 at (Day5, Period5)
Rescue pass: Placed parallel sibling with anchor — group_id=5, sibling_id=102, slot=(Day5, Period5)
Rescue pass: Placed parallel sibling with anchor — group_id=5, sibling_id=103, slot=(Day5, Period5)
```

**If non-anchor 102-2 reaches rescue pass and anchor 101-2 is already placed at (Day4, Period5):**
```
Rescue pass: Non-anchor sibling forced to anchor slot — group_id=5, activity_id=102, slot=(Day4, Period5)
```

**If non-anchor 103-1 reaches rescue pass but anchor 101-1 is NOT placed:**
```
Rescue pass: Non-anchor sibling skipped — anchor not placed — group_id=5, activity_id=103
```

**Final timetable:** All parallel group members (101, 102, 103) appear in the SAME time slots. No member is at a different day/period than its anchor.

---

## Summary of Changes

| # | File | Change | Location |
|---|------|--------|----------|
| 1 | `FETSolver.php` | Non-anchor sibling detection + force-to-anchor at top of rescue loop | `generateGreedySolution()`, inside `foreach ($unplacedActivities ...)`, before line 1481 |
| 2 | `FETSolver.php` | Anchor sibling simultaneous placement after teacher-shuffled rescue success | After line ~1533, before `break;` |
| 3 | `FETSolver.php` | Anchor sibling simultaneous placement after normal rescue success | After line ~1565, before `break;` |
