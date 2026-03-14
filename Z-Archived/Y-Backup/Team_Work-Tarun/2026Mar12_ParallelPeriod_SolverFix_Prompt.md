# Claude Max Prompt — FETSolver Parallel Period Logic: Bug Fix & Rescue Pass

**Date:** 2026-03-12
**Module:** SmartTimetable
**Laravel path:** `/home/tarun/Desktop/Apps/laravel/`
**Primary file:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` (2,656 lines)

---

## CONTEXT — WHO YOU ARE AND WHAT THIS IS

You are working on **Prime-AI**, a multi-tenant SaaS School ERP built on Laravel 12 / PHP 8.2. The SmartTimetable module is a constraint-based automatic timetable generation engine that schedules subjects, teachers, and classes for an entire school week.

The core solver is `FETSolver.php`. It uses three phases:
1. **Backtracking** — pure constraint-satisfaction, tries and reverts placements
2. **Greedy fallback** — forward-only pass when backtracking times out
3. **Rescue pass** — relaxed-constraints pass for anything still unplaced after greedy

---

## CONTEXT — PARALLEL PERIODS FEATURE

A **Parallel Group** is a set of activities across different class sections that MUST be scheduled at the **same day + same period**. Example:

- Class 6A — Hobby (Painting) → Activity ID 101
- Class 6B — Hobby (Dance) → Activity ID 102
- Class 6C — Hobby (Music) → Activity ID 103

These three activities belong to a "Class 6 Hobby" parallel group. All three must land on the same day+period every week (e.g., every Wednesday period 5), even though each goes to a different class with a different teacher.

One activity in the group is designated the **anchor**. The anchor is placed first. All other activities (siblings) are forced to match the anchor's day+period.

---

## CONTEXT — WHAT HAS ALREADY BEEN IMPLEMENTED ✅

All of the following is **already working** in the current FETSolver.php. Do NOT re-implement these:

### Data Structures (lines 33–37)
```php
private array $parallelGroups = [];           // group_id => ParallelGroup object
private array $activityParallelMap = [];      // activity_id => [group_id, ...]
private array $parallelGroupActivityIds = []; // group_id => [activity_id, ...]
private array $parallelGroupAnchors = [];     // group_id => anchor_activity_id
```

### Constructor (lines 103–106)
Calls `initializeParallelGroups($options['parallel_groups'])` which populates all data structures from the loaded `ParallelGroup` Eloquent models.

### Helper Methods (lines 161–231)
- `isAnchorActivity(int $activityId): bool` — returns true if this activity is an anchor for any group
- `isNonAnchorParallelMember(int $activityId): ?int` — returns group_id if non-anchor member, null otherwise
- `findActivitySlotInContext(int $activityId, $context): ?Slot` — searches context->occupied for where an activity has been placed
- `findInstanceForOriginalActivity(int $originalActivityId, array $activities, int $fromIndex): ?object` — finds first unplaced instance of an original activity from given index onward

### Activity Ordering (lines 1923–1930 in `orderActivitiesByDifficulty()`)
```php
if (isset($this->activityParallelMap[$originalActivityId])) {
    $score += 20000; // Parallel group activities placed first
    if ($this->isAnchorActivity($originalActivityId)) {
        $score += 5000; // Anchors placed before siblings
    }
}
```
This ensures ordering: anchor instances → sibling instances → regular activities.

### Backtrack Phase — Parallel Logic (lines 523–634 in `backtrack()`)

**Non-anchor handling (lines 523–552):**
```php
$nonAnchorGroupId = $this->isNonAnchorParallelMember($originalActivityId);
if ($nonAnchorGroupId !== null) {
    $anchorId = $this->parallelGroupAnchors[$nonAnchorGroupId];
    $anchorPlacedSlot = $this->findActivitySlotInContext($anchorId, $context);

    if ($anchorPlacedSlot !== null) {
        // Anchor is placed — force this activity to SAME day+period
        $classKey = $this->getClassKey($activity);
        $forcedSlot = new Slot($classKey, $anchorPlacedSlot->dayId, $anchorPlacedSlot->startIndex);
        if ($this->isBasicSlotAvailable($activity, $forcedSlot, $context, true, true, true, true)) {
            if ($solution->place($activity, $forcedSlot)) {
                $tempContext = $this->simulatePlacement($activity, $forcedSlot, clone $context);
                if ($this->backtrack($activities, $index + 1, $solution, $tempContext)) {
                    return true;
                }
                $solution->remove($activity, $forcedSlot);
            }
        }
        return false;
    }
    // Anchor not placed yet — skip this activity
    return $this->backtrack($activities, $index + 1, $solution, $context);
}
```

**Anchor simultaneous-placement (lines 577–634):**
When anchor is placed, immediately force all siblings to same slot:
```php
if (isset($this->activityParallelMap[$originalActivityId])) {
    foreach ($this->activityParallelMap[$originalActivityId] as $pgId) {
        if (($this->parallelGroupAnchors[$pgId] ?? null) === $originalActivityId) {
            foreach ($this->parallelGroupActivityIds[$pgId] as $siblingId) {
                if ($siblingId === $originalActivityId) continue;
                $siblingInstance = $this->findInstanceForOriginalActivity($siblingId, $activities, $index + 1);
                if ($siblingInstance === null) continue;
                $siblingClassKey = $this->getClassKey($siblingInstance);
                $siblingSlot = new Slot($siblingClassKey, $slot->dayId, $slot->startIndex);
                if ($this->isBasicSlotAvailable($siblingInstance, $siblingSlot, $tempContext, true, true, true, true)
                    && $solution->place($siblingInstance, $siblingSlot)) {
                    $parallelSiblingSlots[] = ['instance' => $siblingInstance, 'slot' => $siblingSlot];
                    $tempContext = $this->simulatePlacement($siblingInstance, $siblingSlot, $tempContext);
                } else {
                    $parallelSiblingPlaced = false; break;
                }
            }
        }
    }
}
// If any sibling failed → undo all sibling placements + anchor, try next slot
```

### Greedy Phase — Parallel Logic (lines 1376–1401 in `generateGreedySolution()`)
When anchor is placed in greedy pass, siblings are immediately placed at same slot.

### Score/Sort/Constraint methods
All fully implemented: `scoreSlotForActivity()`, `violatesNoConsecutiveRule()` (fixed for multi-period), `violatesMinGapRule()`, `resolveMaxPerDay()` (respects `activity->max_per_day`), `getPossibleSlots()` with soft scoring.

---

## THE TWO BUGS TO FIX

### BUG 1 — Backtrack: Non-Anchor Already-Placed Sibling Causes Unnecessary Backtrack

**File:** `FETSolver.php` — `backtrack()` method, lines 523–552

**The problem:**

When anchor instance #1 (e.g., `101-1`) is placed at slot (Day3, Period5), the code immediately places sibling instance `102-1` (6B Hobby) at the same slot.

Later, when backtracking advances its index pointer and reaches `102-1` in the sorted activities array, it enters the non-anchor branch:
- `isNonAnchorParallelMember(102)` → returns groupId (correct)
- `findActivitySlotInContext(101, $context)` → finds anchor is placed (correct)
- `forcedSlot` = (6B classKey, Day3, Period5) — the same slot where 102-1 was already placed
- `isBasicSlotAvailable(...)` → returns **false** because `context->occupied[6B][Day3][Period5]` is already set to `102-1`
- → returns `false` → **UNNECESSARY BACKTRACK**

**The fix:**

Before trying to force-place a non-anchor sibling, check if it's already placed in the solution:

```php
// In backtrack(), non-anchor handling block (around line 527)
if ($nonAnchorGroupId !== null) {
    $anchorId = $this->parallelGroupAnchors[$nonAnchorGroupId];
    $anchorPlacedSlot = $this->findActivitySlotInContext($anchorId, $context);

    if ($anchorPlacedSlot !== null) {
        // ← ADD THIS CHECK: if this instance was already placed by anchor's simultaneous placement, skip it
        $instanceKey = $activity->instance_id ?? $activity->id;
        $alreadyPlaced = $solution->isPlaced($instanceKey);   // ← need isPlaced() method on TimetableSolution
        if ($alreadyPlaced) {
            return $this->backtrack($activities, $index + 1, $solution, $context);
        }

        // ... rest of force-placement logic unchanged ...
    }
    // ...
}
```

**TimetableSolution needs `isPlaced()` method.** Check `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php` (294 lines). It already has `getPlacements()`. Add:
```php
public function isPlaced(string $instanceKey): bool
{
    return isset($this->placements[$instanceKey]);
}
```

---

### BUG 2 — Rescue Pass: No Parallel Group Handling

**File:** `FETSolver.php` — `generateGreedySolution()`, rescue pass loop starting around line 1480

**The problem:**

The rescue pass iterates over unplaced activity instances and tries to place them in any free slot. It has NO parallel group logic. This means:

1. When an **anchor** is rescued, its siblings are not simultaneously placed at the same slot.
2. When a **non-anchor sibling** is rescued, it's placed independently (at whatever free slot, not forced to match the anchor).

This produces incorrect timetables where parallel group members end up at different times.

**The fix:**

In the rescue pass loop (inside `foreach ($unplacedActivities as $activity)`), after successfully placing an activity:

**Case A: Rescue pass places an anchor**
After `$solution->place($activity, $slot)` succeeds for an anchor, immediately try to place all its siblings at the same slot:

```php
// After successful anchor placement in rescue pass:
$rescuedOrigActId = (int) ($activity->original_activity_id ?? $activity->id ?? 0);
if (isset($this->activityParallelMap[$rescuedOrigActId])) {
    foreach ($this->activityParallelMap[$rescuedOrigActId] as $pgId) {
        if (($this->parallelGroupAnchors[$pgId] ?? null) !== $rescuedOrigActId) continue;
        foreach ($this->parallelGroupActivityIds[$pgId] as $sibId) {
            if ($sibId === $rescuedOrigActId) continue;
            // Find the next unplaced instance of this sibling
            foreach ($unplacedActivities as $sibActivity) {
                $sibOrigId = (int) ($sibActivity->original_activity_id ?? $sibActivity->id ?? 0);
                if ($sibOrigId !== $sibId) continue;
                $sibInstanceKey = $sibActivity->instance_id ?? $sibActivity->id;
                $placements = $solution->getPlacements();
                if (isset($placements[$sibInstanceKey])) continue; // already placed
                $sibClassKey = $this->getClassKey($sibActivity);
                $sibSlot = new Slot($sibClassKey, $slot->dayId, $slot->startIndex);
                if ($this->isBasicSlotAvailable($sibActivity, $sibSlot, $context, true, true, true, true)
                    && $solution->place($sibActivity, $sibSlot)) {
                    $context = $this->simulatePlacement($sibActivity, $sibSlot, $context);
                    $rescued++;
                    $placed++;
                    \Log::info('Rescue pass: Placed parallel sibling with anchor', [
                        'group_id' => $pgId, 'sibling_id' => $sibId,
                        'slot' => ['day' => $slot->dayId, 'period' => $slot->startIndex],
                    ]);
                }
                break; // Only place one instance of this sibling per anchor instance
            }
        }
    }
}
```

**Case B: Rescue pass encounters a non-anchor sibling**
Before the main rescue loop tries to place a non-anchor sibling at any free slot, check if its anchor is already placed, and force it to the anchor's slot instead:

```php
// At the TOP of the rescue pass foreach loop, before the day/period iteration:
$rescueOrigActId = (int) ($activity->original_activity_id ?? $activity->id ?? 0);
$rescueNonAnchorGroupId = $this->isNonAnchorParallelMember($rescueOrigActId);
if ($rescueNonAnchorGroupId !== null) {
    $anchorId = $this->parallelGroupAnchors[$rescueNonAnchorGroupId];
    $anchorSlot = $this->findActivitySlotInContext($anchorId, $context);
    if ($anchorSlot !== null) {
        // Force to anchor's slot
        $classKey = $this->getClassKey($activity);
        $forcedSlot = new Slot($classKey, $anchorSlot->dayId, $anchorSlot->startIndex);
        if ($this->isBasicSlotAvailable($activity, $forcedSlot, $context, true, true, true, true)
            && $solution->place($activity, $forcedSlot)) {
            $context = $this->simulatePlacement($activity, $forcedSlot, $context);
            $rescued++;
            $placed++;
            \Log::info('Rescue pass: Non-anchor sibling forced to anchor slot', [
                'group_id' => $rescueNonAnchorGroupId,
                'activity_id' => $rescueOrigActId,
                'slot' => ['day' => $anchorSlot->dayId, 'period' => $anchorSlot->startIndex],
            ]);
        } else {
            \Log::warning('Rescue pass: Cannot force non-anchor sibling to anchor slot', [
                'group_id' => $rescueNonAnchorGroupId, 'activity_id' => $rescueOrigActId,
            ]);
        }
        continue; // Skip the normal free-slot search for this sibling
    }
    // Anchor not placed yet — skip this sibling (cannot place without anchor)
    \Log::warning('Rescue pass: Non-anchor sibling skipped — anchor not placed', [
        'group_id' => $rescueNonAnchorGroupId, 'activity_id' => $rescueOrigActId,
    ]);
    continue;
}
```

---

## FILES TO READ BEFORE CODING

Read these files in full before making changes:

1. **`Modules/SmartTimetable/app/Services/Generator/FETSolver.php`** — the file to modify (2,656 lines). Read the full `backtrack()` method, `generateGreedySolution()`, and the rescue pass section carefully.

2. **`Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php`** (294 lines) — need to add `isPlaced()` method here.

3. **`Modules/SmartTimetable/app/Models/ParallelGroup.php`** (146 lines) — understand the model structure (fields: `id`, `is_hard_constraint`, `coordination_type`, `group_type`).

4. **`Modules/SmartTimetable/app/Models/ParallelGroupActivity.php`** (40 lines) — pivot model with `is_anchor` field.

5. **`Modules/SmartTimetable/Claude_Context/2026Mar11_ParallelPeriod_Tasks.md`** — original task specification for full context on what parallel groups are and why.

---

## KEY DATA STRUCTURES TO UNDERSTAND

### The `$context` object (stdClass)
```php
$context->occupied[$classKey][$dayId][$periodId] = $instanceId;  // e.g., "101-1"
$context->teacherOccupied[$teacherId][$dayId][$periodId] = $instanceId;
$context->periods = Collection of PeriodSetPeriod
$context->days = Collection of SchoolDay
$context->activitiesById = array of Activity models keyed by id
```

### Activity instance fields (set in `expandActivitiesByWeeklyPeriods()`)
```php
$instance->instance_id = "101-2"  // original_activity_id-instance_number
$instance->instance_number = 2
$instance->original_activity_id = 101  // original Activity model ID
$instance->selected_teacher_id = 45
```

### Token format in context->occupied
Tokens are `$activity->instance_id ?? $activity->id` (e.g., `"101-1"` or just `101`).
`extractOriginalActivityIdFromToken("101-1")` returns `"101"`.

### TimetableSolution->getPlacements()
Returns `array[$instanceId => [$slot1, $slot2, ...]]` — an array of Slot objects per instance.

---

## RULES / CONSTRAINTS FOR YOUR IMPLEMENTATION

1. **Do NOT rename any existing methods or properties.** All names are final.
2. **Do NOT change method signatures** of existing methods.
3. **Do NOT modify the backtracking timeout logic** (25 seconds, lines ~497–507).
4. **`isBasicSlotAvailable()` with all four `true` flags** ignores pinning, daily cap, consecutive rule, and class-teacher-first. This is the correct way to call it for parallel siblings (they bypass soft rules).
5. **Parallel group constraints are always HARD** (`is_hard_constraint = true` in DB). Non-anchor members MUST follow anchor or fail.
6. **`findInstanceForOriginalActivity($siblingId, $activities, $index + 1)`** only searches forward. For rescue pass, search the full `$unplacedActivities` array from index 0.
7. **Log every parallel group decision** with `\Log::info()` or `\Log::warning()`. The log format should include `group_id`, `activity_id`, `slot` (day + period).
8. **Do not extract this logic into a separate service class.** Keep all changes inside FETSolver.php and TimetableSolution.php.

---

## EXACT LOCATION OF RESCUE PASS IN FETSolver.php

The rescue pass is in `generateGreedySolution()`. It starts around line **1450**:
```php
// Final rescue pass:
if ($placed < count($activities)) {
    $placements = $solution->getPlacements();
    $unplacedActivities = array_values(array_filter($activities, function ($activity) use ($placements) {
        $instanceKey = $activity->instance_id ?? $activity->id;
        return !isset($placements[$instanceKey]);
    }));
    $rescued = 0;
    // ...
    foreach ($unplacedActivities as $activity) {
        // ... day/period search loop
    }
}
```

The non-anchor sibling handling (Case B) goes at the **very top** of `foreach ($unplacedActivities as $activity)`, before the `foreach ($this->days as $day)` loop.

The anchor sibling placement (Case A) goes **immediately after** `$solution->place($activity, $slot)` succeeds in the rescue loop.

---

## SUMMARY OF ALL CHANGES NEEDED

| # | File | Change | Where |
|---|------|--------|-------|
| 1 | `TimetableSolution.php` | Add `isPlaced(string $instanceKey): bool` | After `getPlacements()` method |
| 2 | `FETSolver.php` | In `backtrack()` non-anchor block: check `$solution->isPlaced($instanceKey)` before trying to force-place | Lines ~527–552 |
| 3 | `FETSolver.php` | In rescue pass: at top of `foreach ($unplacedActivities as $activity)`, add non-anchor sibling detection + force-to-anchor-slot logic | Lines ~1480 |
| 4 | `FETSolver.php` | In rescue pass: after successful anchor placement, add sibling simultaneous placement | Lines ~1560 (after `$solution->place()` succeeds) |

---

## WHAT CORRECT BEHAVIOR LOOKS LIKE (FOR VERIFICATION)

After the fix, for a school with a "Class 6 Hobby" parallel group (activities 101, 102, 103 with 3 weekly periods each):

**Generation logs should show:**
```
Parallel group initialized: group_id=5, activities=[101,102,103], anchor=101
Activities expanded: 9 instances total (101-1, 101-2, 101-3, 102-1, 102-2, 102-3, 103-1, 103-2, 103-3)

Backtracking:
- Placing 101-1 at (Day2, Period5)
- Placed parallel sibling 102-1 at (Day2, Period5)
- Placed parallel sibling 103-1 at (Day2, Period5)
- Placing 101-2 at (Day4, Period5)
- Placed parallel sibling 102-2 at (Day4, Period5)
- Placed parallel sibling 103-2 at (Day4, Period5)
- Placing 101-3 at (Day5, Period5)
- Placed parallel sibling 102-3 at (Day5, Period5)
- Placed parallel sibling 103-3 at (Day5, Period5)
- Backtrack encounters 102-1 at index i → ALREADY PLACED → skip (not backtrack)
- Backtrack encounters 102-2 at index j → ALREADY PLACED → skip (not backtrack)
```

**Final timetable:** 101, 102, 103 all appear in the SAME time slots across the week. No parallel group member is at a different time than its anchor.

---

## ADDITIONAL CONTEXT: PARALLEL GROUP MODEL

```php
// ParallelGroup fields (tt_parallel_group table):
$group->id                   // int
$group->name                 // "Class 6 Hobby Group"
$group->group_type           // PARALLEL_HOBBY | PARALLEL_SKILL | PARALLEL_OPTIONAL | PARALLEL_SECTION
$group->coordination_type    // SAME_TIME | SAME_DAY | SAME_PERIOD_RANGE
$group->is_hard_constraint   // true (always treat as hard)
$group->weight               // 100

// Activities relationship with pivot:
$group->activities           // Collection of Activity models
$activity->pivot->is_anchor  // bool — true for anchor
$activity->pivot->sequence_order // int — ordering within group
```

---

## WHAT NOT TO CHANGE

- Do NOT change `initializeParallelGroups()` — it's correct.
- Do NOT change `isAnchorActivity()`, `isNonAnchorParallelMember()`, `findActivitySlotInContext()`, `findInstanceForOriginalActivity()` — they're correct.
- Do NOT change the anchor simultaneous-placement in the main backtrack loop (lines 577–634) — it's correct.
- Do NOT change the ordering boost in `orderActivitiesByDifficulty()` — it's correct.
- Do NOT change the parallel group handling in the greedy pass (lines 1376–1401) — it's correct.
- Do NOT touch anything outside FETSolver.php and TimetableSolution.php.
