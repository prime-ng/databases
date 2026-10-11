# Activity-Level Constraints — Analysis & Integration Plan
**Date:** 2026-03-10
**Scope:** Integrate activity-level soft constraints into FETSolver slot evaluation
**Constraint:** NO renames. NO breaking changes. Constraints act as soft preferences, NOT hard blockers.

---

## TABLE OF CONTENTS

1. [Activity Model Constraint Fields](#1-activity-model-constraint-fields)
2. [Current Generator Gap Analysis](#2-current-generator-gap-analysis)
3. [Intended Scheduling Behavior](#3-intended-scheduling-behavior)
4. [Integration Design](#4-integration-design)
5. [Pseudocode & Code Suggestions](#5-pseudocode--code-suggestions)
6. [Room Constraint Integration](#6-room-constraint-integration)
7. [Implementation Order](#7-implementation-order)

---

## 1. ACTIVITY MODEL CONSTRAINT FIELDS

**File:** `Modules/SmartTimetable/app/Models/Activity.php` (457 lines)
**Table:** `tt_activities` (DDL in `1-tt_timetable_ddl_v7.6.sql` line 946)

### 1A. Time-Slot Constraint Fields

| Field | DB Type | Cast | Expected JSON Structure | Purpose |
|-------|---------|------|-------------------------|---------|
| `preferred_periods_json` | JSON | `array` | `[3, 4, 5]` — array of period_ord values | Periods where this activity performs best (e.g., Maths in morning) |
| `avoid_periods_json` | JSON | `array` | `[1, 8]` — array of period_ord values | Periods to avoid (e.g., no PE in period 1) |
| `preferred_time_slots_json` | JSON | `array` | `[{"day_id": 1, "period_ord": 3}, ...]` — day+period combos | Specific day+period slots preferred |
| `avoid_time_slots_json` | JSON | `array` | `[{"day_id": 5, "period_ord": 7}, ...]` — day+period combos | Specific day+period slots to avoid |

### 1B. Scheduling Behavior Fields

| Field | DB Type | Cast | Default | Purpose |
|-------|---------|------|---------|---------|
| `max_per_day` | TINYINT UNSIGNED | `integer` | NULL | Maximum periods of this activity in one day |
| `min_per_day` | TINYINT UNSIGNED | `integer` | NULL | Minimum periods per day (when scheduled on that day) |
| `min_gap_periods` | TINYINT UNSIGNED | `integer` | NULL | Minimum gap between two instances on same day |
| `allow_consecutive` | TINYINT(1) | `boolean` | 0 | Whether consecutive periods are explicitly allowed |
| `max_consecutive` | TINYINT UNSIGNED | `integer` | 2 | Max consecutive periods (relevant when allow_consecutive=true) |
| `spread_evenly` | TINYINT(1) | `boolean` | 1 | Whether periods should be spread across all days evenly |
| `min_periods_per_week` | TINYINT UNSIGNED | `integer` | NULL | Minimum periods per week |
| `max_periods_per_week` | TINYINT UNSIGNED | `integer` | NULL | Maximum periods per week |

### 1C. Room Constraint Fields

| Field | DB Type | Cast | Purpose |
|-------|---------|------|---------|
| `requires_room` | TINYINT(1) | `boolean` | Whether this activity needs a room at all |
| `compulsory_specific_room_type` | TINYINT(1) | `boolean` | If TRUE, room type is MANDATORY (hard constraint) |
| `required_room_type_id` | INT UNSIGNED | `integer` | FK to `sch_room_types` — MUST have this room type |
| `required_room_id` | INT UNSIGNED | `integer` | FK to `sch_rooms` — specific room required |
| `preferred_room_type_id` | INT UNSIGNED | `integer` | FK to `sch_room_types` — preferred but not required |
| `preferred_room_ids` | JSON | `array` | `[12, 15, 23]` — list of preferred room IDs |

### 1D. Scoring / Metadata Fields

| Field | DB Type | Cast | Purpose |
|-------|---------|------|---------|
| `constraint_count` | SMALLINT UNSIGNED | `integer` | Number of constraints affecting this activity |
| `difficulty_score` | TINYINT UNSIGNED | `integer` | Manual difficulty (0-100, higher = harder to schedule) |
| `difficulty_score_calculated` | TINYINT UNSIGNED | `integer` | Auto-calculated difficulty based on constraints |
| `teacher_availability_score` | TINYINT UNSIGNED | `integer` | % of available teachers |
| `room_availability_score` | TINYINT UNSIGNED | `integer` | % of available rooms |
| `priority` | TINYINT UNSIGNED | `integer` | Scheduling priority (0-100) |

### 1E. Relationship for Room Types
```php
public function requiredRoomType(): BelongsTo  // → RoomType via required_room_type_id
public function preferredRoomType(): BelongsTo  // → RoomType via preferred_room_type_id
```

---

## 2. CURRENT GENERATOR GAP ANALYSIS

### What FETSolver Currently Uses from Activity

| Activity Field | Used In FETSolver? | Where |
|---------------|-------------------|-------|
| `required_weekly_periods` | ✅ YES | `expandActivitiesByWeeklyPeriods()` |
| `duration_periods` | ✅ YES | `expandActivitiesByWeeklyPeriods()`, slot duration check |
| `is_compulsory` | ✅ YES | `orderActivitiesByDifficulty()` scoring |
| `priority` | ✅ YES | `orderActivitiesByDifficulty()` scoring |
| `teachers` (relation) | ✅ YES | Teacher conflict checking, assignment |
| `class_id`, `section_id` | ✅ YES | Class key derivation |
| `subject` (relation) | ✅ YES | Logging/diagnostics |
| `class`, `section` (relations) | ✅ YES | Class key from codes |
| **preferred_periods_json** | ❌ NO | — |
| **avoid_periods_json** | ❌ NO | — |
| **preferred_time_slots_json** | ❌ NO | — |
| **avoid_time_slots_json** | ❌ NO | — |
| **max_per_day** | ❌ NO | FETSolver has its OWN `violatesDailyActivityPlacementCap()` that uses `ceil(weeklyPeriods/days)` |
| **min_per_day** | ❌ NO | — |
| **min_gap_periods** | ❌ NO | — |
| **allow_consecutive** | ❌ NO | FETSolver hardcodes `disallowConsecutivePeriods = true` globally |
| **max_consecutive** | ❌ NO | — |
| **spread_evenly** | ❌ NO | Pinning logic partly addresses this, but doesn't use the flag |
| **requires_room** | ❌ NO | — |
| **required_room_type_id** | ❌ NO | — |
| **required_room_id** | ❌ NO | — |
| **preferred_room_type_id** | ❌ NO | — |
| **preferred_room_ids** | ❌ NO | — |
| **constraint_count** | ❌ NO | — |
| **difficulty_score** | ❌ NO | `orderActivitiesByDifficulty()` uses its own scoring, ignores this field |

### Why These Are Ignored

1. **FETSolver was built as a standalone engine** with hardcoded rules (`disallowConsecutivePeriods`, `singleActivityOncePerDayUntilOverflow`, `pinActivitiesByPeriod`). These were simple, effective, and didn't need per-activity configuration.

2. **ConstraintManager.evaluateSoftConstraints() exists but is NEVER CALLED** in FETSolver. The method is implemented in ConstraintManager (line 95), accepts a Slot + Activity + context, and returns a float score — but no code in FETSolver invokes it.

3. **No slot scoring mechanism exists** in FETSolver. The current algorithm uses a boolean pass/fail approach:
   - `getPossibleSlots()` → filters available slots
   - `canPlaceWithConstraints()` → boolean yes/no
   - First valid slot is taken (backtracking) or first in sorted order (greedy)
   - There is NO scoring/ranking of slots by quality

4. **Room allocation is not part of generation** at all. Rooms are intended to be assigned post-generation (the DDL has `tt_room_availability` and related tables, but FETSolver doesn't interact with them).

---

## 3. INTENDED SCHEDULING BEHAVIOR

### 3A. Time Preference Fields

#### `preferred_periods_json` — e.g. `[1, 2, 3]`
**Intent:** "This activity works best in periods 1-3 (morning)."
**Scheduling effect:** When multiple valid slots exist, prefer slots whose `period_ord` is in this list.
**Score bonus:** +20 points per matching slot.

#### `avoid_periods_json` — e.g. `[7, 8]`
**Intent:** "Avoid scheduling this activity in periods 7-8 (last periods)."
**Scheduling effect:** When multiple valid slots exist, penalize slots whose `period_ord` is in this list.
**Score penalty:** -30 points per matching slot. (Penalty > bonus to make avoidance stronger)

#### `preferred_time_slots_json` — e.g. `[{"day_id": 1, "period_ord": 3}, {"day_id": 3, "period_ord": 3}]`
**Intent:** "This activity ideally goes in Monday period 3 and Wednesday period 3."
**Scheduling effect:** Strongly prefer these exact day+period combinations.
**Score bonus:** +40 points (strongest preference — more specific than period-only).

#### `avoid_time_slots_json` — e.g. `[{"day_id": 5, "period_ord": 8}]`
**Intent:** "Never put this activity in Friday period 8."
**Scheduling effect:** Strongly penalize these exact day+period combinations.
**Score penalty:** -50 points (strongest avoidance).

### 3B. Scheduling Behavior Fields

#### `max_per_day` — e.g. `2`
**Intent:** "This activity can have at most 2 instances on the same day."
**Current partial implementation:** `violatesDailyActivityPlacementCap()` in FETSolver calculates `ceil(weeklyPeriods/days)` dynamically. It does NOT read `max_per_day` from the activity.
**Improvement:** Use `activity->max_per_day` when set; fall back to current formula when NULL.

#### `min_per_day` — e.g. `1`
**Intent:** "If this activity is scheduled on a day, it should have at least 1 period."
**Effect:** Soft preference — not a hard blocker since the solver might not be able to guarantee it.

#### `allow_consecutive` — `true/false`
**Intent:** Per-activity override for the global `disallowConsecutivePeriods` rule.
**Current behavior:** FETSolver uses a GLOBAL `disallowConsecutivePeriods = true` for ALL activities. This means lab activities that NEED consecutive periods (Physics Lab = 2 consecutive) are blocked.
**Improvement:** Check `activity->allow_consecutive` before applying the consecutive rule. If `true`, skip the consecutive check for that activity.

#### `max_consecutive` — e.g. `2`
**Intent:** "This activity can have at most 2 consecutive periods."
**Effect:** When `allow_consecutive = true`, cap at this value.

#### `min_gap_periods` — e.g. `1`
**Intent:** "There should be at least 1 period gap between two instances of this activity on the same day."
**Effect:** After placing an instance, the next instance on the same day must be ≥ `min_gap_periods` slots away.

#### `spread_evenly` — `true/false`
**Intent:** "Spread instances across different days rather than clustering."
**Current partial implementation:** `pinActivitiesByPeriod` and `singleActivityOncePerDayUntilOverflow` partly achieve this but are global, not per-activity.
**Improvement:** When `spread_evenly = true`, apply day-spreading bonus; when `false`, don't penalize day clustering.

### 3C. Room Constraint Fields

#### `requires_room` — `true/false`
**Intent:** Whether this activity needs a room assigned at all.
**Scheduling effect:** If `false`, skip room allocation entirely.

#### `compulsory_specific_room_type` + `required_room_type_id`
**Intent:** "This activity MUST use a room of type X (e.g., Computer Lab)."
**Scheduling effect:** HARD constraint — during room allocation phase, only rooms of this type are eligible.

#### `required_room_id`
**Intent:** "This activity MUST use this specific room."
**Scheduling effect:** HARD constraint — only this room is eligible. Creates a room-conflict check (two activities can't share the same room at the same time).

#### `preferred_room_type_id` + `preferred_room_ids`
**Intent:** "This activity prefers rooms of type Y, ideally rooms [12, 15, 23]."
**Scheduling effect:** SOFT constraint — when allocating rooms, prefer these; fall back to any available room if preferred rooms are occupied.

---

## 4. INTEGRATION DESIGN

### 4A. Architecture: Where to Integrate

The integration should happen at **two levels**:

#### Level 1: Inside FETSolver (Activity-Level Soft Scoring)
- **Where:** `getPossibleSlots()` — after collecting valid slots, score them
- **How:** Add a `scoreSlot()` method that evaluates activity-level preferences and returns a numeric score
- **Why here:** This is where slot ordering happens. Currently slots are shuffled (when no special mode) or sorted by class-teacher/pinning. Adding a scoring layer here integrates naturally.

#### Level 2: Inside FETSolver (Activity-Level Hard Overrides)
- **Where:** `isBasicSlotAvailable()` — add per-activity overrides for global rules
- **How:** Check `activity->allow_consecutive` before applying the consecutive rule. Check `activity->max_per_day` before applying the daily cap.
- **Why here:** These are binary go/no-go decisions that should respect per-activity configuration.

#### NOT at Level 3 (ConstraintManager)
The activity-level fields are NOT stored in `tt_constraints` — they're directly on the `tt_activities` table. Routing them through DatabaseConstraintService → ConstraintFactory → ConstraintManager would be over-engineered. The activity model already carries these fields.

### 4B. Scoring Framework

Introduce a `scoreSlotForActivity()` method in FETSolver that returns a numeric score:

```
Base score: 0

+40  if slot matches preferred_time_slots_json (exact day+period match)
+20  if slot's period_ord is in preferred_periods_json
-30  if slot's period_ord is in avoid_periods_json
-50  if slot matches avoid_time_slots_json (exact day+period match)
+10  if spread_evenly=true AND this day has fewest placements for this activity
-15  if spread_evenly=true AND this day already has ≥1 instance
```

Slot selection then sorts by score (descending) before trying placements.

### 4C. Hard Override Integration

Modify `isBasicSlotAvailable()`:

| Current Global Rule | Change |
|---------------------|--------|
| `disallowConsecutivePeriods` (always true) | Check `activity->allow_consecutive`. If `true`, skip consecutive check. Cap at `activity->max_consecutive`. |
| `violatesDailyActivityPlacementCap()` | Use `activity->max_per_day` when set; fall back to `ceil(weeklyPeriods/days)` when NULL. |

### 4D. Room Integration Point

Room allocation is a separate phase that should happen AFTER slot placement, not during it. The FETSolver determines **when** (day+period) each activity runs. Room assignment determines **where** (which room).

**Recommended approach:** After `generateWithFET()` produces the `schoolGrid`, add a `RoomAllocationPass` that:
1. Groups cells by their activity's room requirements
2. Hard-assigns rooms for `required_room_id` activities
3. Type-matches rooms for `required_room_type_id` activities
4. Preference-scores rooms for `preferred_room_type_id`/`preferred_room_ids`
5. Detects room conflicts (two activities needing same room at same time)

This is described in detail in [Section 6](#6-room-constraint-integration).

---

## 5. PSEUDOCODE & CODE SUGGESTIONS

### 5A. New Method: `scoreSlotForActivity()` in FETSolver

```php
/**
 * Score a slot based on activity-level soft preferences.
 * Higher score = better slot for this activity.
 * Returns 0 if no preferences are set.
 */
private function scoreSlotForActivity($activity, Slot $slot, $context): int
{
    $score = 0;
    $periodIndex = $slot->startIndex;
    $dayId = $slot->dayId;

    // Resolve period_ord for this slot
    $period = $this->periods[$periodIndex] ?? null;
    if (!$period) {
        return $score;
    }
    $periodOrd = $period->period_ord ?? ($periodIndex + 1);

    // --- preferred_time_slots_json (strongest positive: +40) ---
    $preferredTimeSlots = $activity->preferred_time_slots_json ?? [];
    if (!empty($preferredTimeSlots)) {
        foreach ($preferredTimeSlots as $pref) {
            $prefDay = $pref['day_id'] ?? null;
            $prefPeriod = $pref['period_ord'] ?? null;
            if ($prefDay == $dayId && $prefPeriod == $periodOrd) {
                $score += 40;
                break;
            }
        }
    }

    // --- avoid_time_slots_json (strongest negative: -50) ---
    $avoidTimeSlots = $activity->avoid_time_slots_json ?? [];
    if (!empty($avoidTimeSlots)) {
        foreach ($avoidTimeSlots as $avoid) {
            $avoidDay = $avoid['day_id'] ?? null;
            $avoidPeriod = $avoid['period_ord'] ?? null;
            if ($avoidDay == $dayId && $avoidPeriod == $periodOrd) {
                $score -= 50;
                break;
            }
        }
    }

    // --- preferred_periods_json (+20) ---
    $preferredPeriods = $activity->preferred_periods_json ?? [];
    if (!empty($preferredPeriods) && in_array($periodOrd, $preferredPeriods)) {
        $score += 20;
    }

    // --- avoid_periods_json (-30) ---
    $avoidPeriods = $activity->avoid_periods_json ?? [];
    if (!empty($avoidPeriods) && in_array($periodOrd, $avoidPeriods)) {
        $score -= 30;
    }

    // --- spread_evenly bonus (+10 for least-used day, -15 for already-used day) ---
    $spreadEvenly = $activity->spread_evenly ?? true;
    if ($spreadEvenly) {
        $classKey = $slot->classKey;
        $dailyCount = $this->getDailyPlacementCountForActivity($activity, $classKey, $dayId, $context);
        if ($dailyCount === 0) {
            $score += 10; // Reward unused day
        } else {
            $score -= 15; // Penalize clustering
        }
    }

    return $score;
}
```

### 5B. Modify `getPossibleSlots()` — Add Score-Based Sorting

In `FETSolver::getPossibleSlots()` (currently around line 838), after collecting valid slots, add scoring:

```php
private function getPossibleSlots($activity, TimetableSolution $solution, $context): array
{
    $slots = [];
    // ... existing slot collection logic (unchanged) ...

    // NEW: Score slots based on activity-level preferences
    $hasPreferences = !empty($activity->preferred_time_slots_json)
        || !empty($activity->avoid_time_slots_json)
        || !empty($activity->preferred_periods_json)
        || !empty($activity->avoid_periods_json);

    if ($hasPreferences || ($activity->spread_evenly ?? false)) {
        // Build scored slots
        $scoredSlots = [];
        foreach ($slots as $slot) {
            $scoredSlots[] = [
                'slot' => $slot,
                'score' => $this->scoreSlotForActivity($activity, $slot, $context),
            ];
        }

        // Sort by score descending (best slots first)
        usort($scoredSlots, function ($a, $b) {
            if ($b['score'] !== $a['score']) {
                return $b['score'] <=> $a['score'];
            }
            // Tie-break: shuffle for randomness
            return random_int(-1, 1);
        });

        $slots = array_column($scoredSlots, 'slot');
    }

    // ... existing class-teacher/pinning sort logic (unchanged) ...
    // NOTE: The existing usort for class-teacher-first and pinning should
    // take PRIORITY over soft scoring. So the order should be:
    // 1. Apply soft scoring sort
    // 2. THEN apply class-teacher/pinning sort (which is a stable re-sort on top)
    // OR: Merge both sort criteria into a single comparator.

    return $slots;
}
```

**Important:** The existing `usort` for class-teacher-first and pinning (lines 876-923) should be merged with the scoring sort. One approach:

```php
// Combined sort that respects both hard ordering and soft scoring
usort($slots, function (Slot $a, Slot $b) use ($activity, $context, ...) {
    // Priority 1: Class-teacher first lecture (if applicable)
    // ... existing class-teacher logic ...

    // Priority 2: Pinning affinity (if applicable)
    // ... existing pinning logic ...

    // Priority 3: Activity-level soft score
    $scoreA = $this->scoreSlotForActivity($activity, $a, $context);
    $scoreB = $this->scoreSlotForActivity($activity, $b, $context);
    if ($scoreA !== $scoreB) {
        return $scoreB <=> $scoreA;
    }

    // Priority 4: Day spread then random
    return random_int(-1, 1);
});
```

### 5C. Modify `isBasicSlotAvailable()` — Per-Activity Overrides

#### Override 1: `allow_consecutive` per activity

In `isBasicSlotAvailable()` (FETSolver line 475), change the consecutive check:

```php
// CURRENT (line 492-494):
if (!$ignoreConsecutive && $this->disallowConsecutivePeriods
    && $this->violatesNoConsecutiveRule($activity, $slot, $duration, $classKey, $context)) {
    return false;
}

// PROPOSED:
$activityAllowsConsecutive = (bool) ($activity->allow_consecutive ?? false);
if (!$ignoreConsecutive
    && $this->disallowConsecutivePeriods
    && !$activityAllowsConsecutive  // NEW: skip check if activity explicitly allows
    && $this->violatesNoConsecutiveRule($activity, $slot, $duration, $classKey, $context)) {
    return false;
}
```

#### Override 2: `max_per_day` per activity

In `violatesDailyActivityPlacementCap()` (FETSolver line 679), use the activity's field:

```php
// CURRENT (line 686-689):
$maxPerDay = max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));
if ($requiredWeeklyPeriods <= $daysCount) {
    $maxPerDay = 1;
}

// PROPOSED:
$activityMaxPerDay = $activity->max_per_day ?? null;
if ($activityMaxPerDay !== null) {
    $maxPerDay = (int) $activityMaxPerDay;
} else {
    // Fall back to current dynamic calculation
    $maxPerDay = max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));
    if ($requiredWeeklyPeriods <= $daysCount) {
        $maxPerDay = 1;
    }
}
```

#### Override 3: `min_gap_periods` per activity

Add a new check in `isBasicSlotAvailable()` after the consecutive check:

```php
// NEW: min_gap_periods check
$minGap = (int) ($activity->min_gap_periods ?? 0);
if (!$ignoreConsecutive && $minGap > 0) {
    if ($this->violatesMinGapRule($activity, $slot, $minGap, $classKey, $context)) {
        return false;
    }
}
```

With the helper:

```php
private function violatesMinGapRule($activity, Slot $slot, int $minGap, string $classKey, $context): bool
{
    $occupiedForDay = $context->occupied[$classKey][$slot->dayId] ?? [];
    $currentActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');

    foreach ($occupiedForDay as $periodId => $token) {
        if ($this->extractOriginalActivityIdFromToken($token) !== $currentActivityId) {
            continue;
        }

        // Find the period index of the occupied slot
        $occupiedIndex = null;
        foreach ($this->periods as $idx => $period) {
            if ($period->id == $periodId) {
                $occupiedIndex = $idx;
                break;
            }
        }

        if ($occupiedIndex === null) {
            continue;
        }

        // Check if the gap is less than required
        $gap = abs($slot->startIndex - $occupiedIndex);
        if ($gap > 0 && $gap <= $minGap) {
            return true; // Too close
        }
    }

    return false;
}
```

### 5D. Fix `violatesNoConsecutiveRule` for Multi-Period Activities

This is the R6 bug from the deep analysis. Currently:

```php
// CURRENT (FETSolver line 636-639):
if ($duration > 1) {
    return true; // Multi-period blocks are inherently consecutive — THIS IS WRONG
}
```

This should be:

```php
// PROPOSED:
// A single multi-period block (e.g., Lab = 2 consecutive periods) is NOT a
// "consecutive violation". The rule prevents placing TWO SEPARATE INSTANCES
// of the same activity adjacent to each other on the same day.
// Multi-period blocks are one instance spanning multiple periods — they're fine.
if ($duration > 1) {
    // For multi-period activities, check if ANOTHER instance of the same activity
    // is adjacent to this block's start or end
    $blockStart = $slot->startIndex;
    $blockEnd = $blockStart + $duration - 1;
    $currentOriginalActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');

    // Check period before block start
    if ($blockStart > 0) {
        $prevPeriodId = $this->periods[$blockStart - 1]->id ?? null;
        if ($prevPeriodId !== null && isset($context->occupied[$classKey][$slot->dayId][$prevPeriodId])) {
            $prevToken = $context->occupied[$classKey][$slot->dayId][$prevPeriodId];
            if ($this->extractOriginalActivityIdFromToken($prevToken) === $currentOriginalActivityId) {
                return true;
            }
        }
    }

    // Check period after block end
    $afterEnd = $blockEnd + 1;
    if ($afterEnd < $this->periods->count()) {
        $nextPeriodId = $this->periods[$afterEnd]->id ?? null;
        if ($nextPeriodId !== null && isset($context->occupied[$classKey][$slot->dayId][$nextPeriodId])) {
            $nextToken = $context->occupied[$classKey][$slot->dayId][$nextPeriodId];
            if ($this->extractOriginalActivityIdFromToken($nextToken) === $currentOriginalActivityId) {
                return true;
            }
        }
    }

    return false; // Multi-period block with no adjacent same-activity instance is OK
}
```

---

## 6. ROOM CONSTRAINT INTEGRATION

### 6A. Current State

Room allocation does NOT happen during generation. FETSolver produces a grid of `[classKey][dayId][periodId] = activityId`. The `room_id` field on `TimetableCell` is always `NULL` when created by `storeTimetable()` (line 658: `'room_id' => null`).

### 6B. Recommended Integration Point

**After generation, before save.** Add a `RoomAllocationPass` that runs between `solver->solve()` and the session storage in `generateWithFET()`.

```
solver->solve()
    ↓
entries[] (day, period, activity — no rooms)
    ↓
RoomAllocationPass::allocate(entries, activities) ← NEW
    ↓
entries[] (day, period, activity, room_id) ← room_id populated
    ↓
session storage + preview
```

### 6C. Room Allocation Algorithm

```php
class RoomAllocationPass
{
    /**
     * Allocate rooms to entries based on activity room constraints.
     * Returns modified entries with room_id populated where applicable.
     */
    public function allocate(array $entries, Collection $activities, Collection $rooms): array
    {
        // Track room occupancy: roomOccupied[room_id][day_id][period_ord] = activity_id
        $roomOccupied = [];

        // Sort entries by constraint strictness (hard room requirements first)
        $sorted = $this->sortByRoomPriority($entries, $activities);

        foreach ($sorted as &$entry) {
            $activity = $activities[$entry['activity_id']] ?? null;
            if (!$activity || !($activity->requires_room ?? true)) {
                continue;
            }

            $room = $this->findBestRoom($activity, $entry, $rooms, $roomOccupied);
            if ($room) {
                $entry['room_id'] = $room->id;
                $roomOccupied[$room->id][$entry['day_id']][$entry['period_id']] = $entry['activity_id'];
            }
        }

        return $sorted;
    }

    private function findBestRoom($activity, array $entry, Collection $rooms, array $roomOccupied): ?object
    {
        $dayId = $entry['day_id'];
        $periodId = $entry['period_id'];

        // Step 1: HARD — specific required room
        if ($activity->required_room_id) {
            $room = $rooms->firstWhere('id', $activity->required_room_id);
            if ($room && !isset($roomOccupied[$room->id][$dayId][$periodId])) {
                return $room;
            }
            // Hard requirement can't be met — log conflict, continue
            return null;
        }

        // Step 2: HARD — required room type
        if ($activity->compulsory_specific_room_type && $activity->required_room_type_id) {
            $eligible = $rooms->where('room_type_id', $activity->required_room_type_id);
            foreach ($eligible as $room) {
                if (!isset($roomOccupied[$room->id][$dayId][$periodId])) {
                    return $room;
                }
            }
            return null; // No room of required type available
        }

        // Step 3: SOFT — preferred room IDs
        $preferredIds = $activity->preferred_room_ids ?? [];
        if (!empty($preferredIds)) {
            foreach ($preferredIds as $roomId) {
                if (!isset($roomOccupied[$roomId][$dayId][$periodId])) {
                    return $rooms->firstWhere('id', $roomId);
                }
            }
        }

        // Step 4: SOFT — preferred room type
        if ($activity->preferred_room_type_id) {
            $preferred = $rooms->where('room_type_id', $activity->preferred_room_type_id);
            foreach ($preferred as $room) {
                if (!isset($roomOccupied[$room->id][$dayId][$periodId])) {
                    return $room;
                }
            }
        }

        // Step 5: FALLBACK — any available room
        foreach ($rooms as $room) {
            if (!isset($roomOccupied[$room->id][$dayId][$periodId])) {
                return $room;
            }
        }

        return null; // No rooms available at this time
    }

    private function sortByRoomPriority(array $entries, Collection $activities): array
    {
        usort($entries, function ($a, $b) use ($activities) {
            $actA = $activities[$a['activity_id']] ?? null;
            $actB = $activities[$b['activity_id']] ?? null;

            $priorityA = $this->roomPriorityScore($actA);
            $priorityB = $this->roomPriorityScore($actB);

            return $priorityB <=> $priorityA; // Higher priority first
        });

        return $entries;
    }

    private function roomPriorityScore($activity): int
    {
        if (!$activity) return 0;
        $score = 0;
        if ($activity->required_room_id) $score += 100;        // Specific room = highest
        if ($activity->compulsory_specific_room_type) $score += 80;  // Required type
        if ($activity->required_room_type_id) $score += 60;    // Required type (non-compulsory)
        if (!empty($activity->preferred_room_ids)) $score += 30;    // Preferred rooms
        if ($activity->preferred_room_type_id) $score += 20;   // Preferred type
        return $score;
    }
}
```

### 6D. Integration in generateWithFET()

After `$entries = $solver->solve($activities)` (line 2613), add:

```php
// Room allocation pass (after slot generation)
if ($this->shouldAllocateRooms($activities)) {
    $rooms = \Modules\SchoolSetup\Models\Room::where('is_active', true)->get();
    $roomAllocator = new RoomAllocationPass();
    $entries = $roomAllocator->allocate($entries, $activities, $rooms);
}
```

And in `storeTimetable()`, use the `room_id` from entries:

```php
// Line 658 change:
'room_id' => $entry['room_id'] ?? null,  // Was hardcoded null
```

---

## 7. IMPLEMENTATION ORDER

### Phase 1: Quick Wins (Low Risk, High Value)

| # | Change | File | Effort | Impact |
|---|--------|------|--------|--------|
| 1 | Fix `violatesNoConsecutiveRule` for multi-period (R6 bug) | FETSolver:636 | 15 min | HIGH — unblocks labs/hobby |
| 2 | Use `activity->allow_consecutive` in `isBasicSlotAvailable()` | FETSolver:492 | 5 min | HIGH — per-activity consecutive control |
| 3 | Use `activity->max_per_day` in `violatesDailyActivityPlacementCap()` | FETSolver:686 | 5 min | MEDIUM — per-activity daily cap |

### Phase 2: Soft Scoring (Medium Effort, High Value)

| # | Change | File | Effort | Impact |
|---|--------|------|--------|--------|
| 4 | Add `scoreSlotForActivity()` method | FETSolver (new method) | 30 min | HIGH — enables all time preferences |
| 5 | Integrate scoring into `getPossibleSlots()` sort | FETSolver:838 | 30 min | HIGH — slots now ranked by quality |
| 6 | Add `violatesMinGapRule()` | FETSolver (new method) | 15 min | MEDIUM — gap enforcement |

### Phase 3: Room Allocation (Separate Feature)

| # | Change | File | Effort | Impact |
|---|--------|------|--------|--------|
| 7 | Create `RoomAllocationPass` service | New file | 1 hr | HIGH — enables room assignment |
| 8 | Integrate into `generateWithFET()` | Controller:~2613 | 15 min | — |
| 9 | Update `storeTimetable()` to persist room_id | Controller:658 | 5 min | — |
| 10 | Add room conflict display to preview view | Blade template | 30 min | — |

### Phase 4: Advanced (Future)

| # | Change | Effort | Impact |
|---|--------|--------|--------|
| 11 | Wire `ConstraintManager.evaluateSoftConstraints()` into FETSolver for DB-defined soft constraints | 1 hr | Enables admin-configurable soft constraints |
| 12 | Use `spread_evenly` flag per activity (not global pinning) | 30 min | Finer control |
| 13 | Add `min_per_day` enforcement as soft penalty | 15 min | Better minimum guarantees |
| 14 | Integrate `constraint_count` and `difficulty_score` into `orderActivitiesByDifficulty()` | 10 min | Better ordering |

---

## APPENDIX: Score Weight Summary

| Constraint Field | Score Effect | Weight | Type |
|-----------------|-------------|--------|------|
| `preferred_time_slots_json` match | Bonus | +40 | Soft |
| `avoid_time_slots_json` match | Penalty | -50 | Soft |
| `preferred_periods_json` match | Bonus | +20 | Soft |
| `avoid_periods_json` match | Penalty | -30 | Soft |
| `spread_evenly` (unused day) | Bonus | +10 | Soft |
| `spread_evenly` (already-used day) | Penalty | -15 | Soft |
| `allow_consecutive` | Override | binary | Hard override |
| `max_per_day` | Override | binary | Hard override |
| `min_gap_periods` | Override | binary | Hard override |
| `required_room_id` | Room hard | — | Hard (room phase) |
| `required_room_type_id` + compulsory | Room hard | — | Hard (room phase) |
| `preferred_room_type_id` | Room soft | — | Soft (room phase) |
| `preferred_room_ids` | Room soft | — | Soft (room phase) |

> **Design rationale for weights:** Penalties are stronger than bonuses because avoiding a bad slot is more important than finding a perfect slot. Specific day+period preferences/avoidances are stronger than period-only preferences because they carry more user intent.
