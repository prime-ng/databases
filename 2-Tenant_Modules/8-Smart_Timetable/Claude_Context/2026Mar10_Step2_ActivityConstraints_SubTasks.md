# Step 2: Activity-Level Constraint Integration — Sub-Task Breakdown
**Date:** 2026-03-10
**Parent Plan:** `2026Mar10_GapAnalysis_and_CompletionPlan.md` → Step 2
**Reference:** `2026Mar10_ActivityConstraints_Integration_Plan.md` (full design)
**Files to change:**
- `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
- `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`

---

## Overview

The `Activity` model carries 22 fields that describe per-activity scheduling preferences and constraints (e.g. preferred periods, avoid periods, max periods per day, allow consecutive, room requirements). Currently **FETSolver ignores every one of these fields** — it uses only global hardcoded flags that apply uniformly to all activities.

Step 2 makes FETSolver respect per-activity configuration. The changes are split into **7 sub-tasks** ordered by dependency. Sub-tasks 1–4 modify hard rules (binary pass/fail). Sub-tasks 5–6 introduce soft scoring (prefer better slots). Sub-task 7 auto-populates the data that drives scoring.

---

## Sub-Task Overview Table

| # | Name | File | Method(s) | Type | Effort |
|---|------|------|-----------|------|--------|
| 2.1 | Fix multi-period consecutive bug | FETSolver | `violatesNoConsecutiveRule()` | Bug fix | 15 min |
| 2.2 | Per-activity consecutive override | FETSolver | `isBasicSlotAvailable()` | Hard rule | 10 min |
| 2.3 | Per-activity daily cap override | FETSolver | `violatesDailyActivityPlacementCap()`, `getMaxPlacementsPerDay()` | Hard rule | 10 min |
| 2.4 | Min-gap enforcement | FETSolver | new `violatesMinGapRule()`, `isBasicSlotAvailable()` | Hard rule | 20 min |
| 2.5 | Slot scoring method | FETSolver | new `scoreSlotForActivity()` | Soft scoring | 30 min |
| 2.6 | Integrate scoring into slot selection | FETSolver | `getPossibleSlots()` | Soft scoring | 20 min |
| 2.7 | Auto-populate activity constraint fields | ActivityController | `generateActivities()` or `store()` | Data setup | 30 min |

**Total estimated effort: ~2 hours 15 minutes**

---

## Sub-Task 2.1 — Fix Multi-Period Consecutive Bug

### What & Why
**Bug B3** from the gap analysis. The method `violatesNoConsecutiveRule()` has this code:

```php
// FETSolver.php line 637-638
if ($duration > 1) {
    return true; // Any multi-period block is inherently consecutive
}
```

This means **any activity requiring 2+ consecutive periods (Lab, Hobby, Robotics, Astro, Physics practical)** always returns "violates consecutive rule = true" in the primary backtracking pass and greedy pass. These activities can only land in the **forced/rescue pass** which ignores consecutive checks — but by then constraints are relaxed and placement quality is poor.

**Example impact:** A Physics Lab needing 2 consecutive periods for Class 11A is systematically prevented from being placed in the best slots just because `duration=2`. It ends up force-placed in whatever slot remains.

### What the fix does
Rewrite the `duration > 1` early-return so that:
- A **single multi-period block** (one instance occupying periods 3+4) is **NOT** a consecutive violation — it's intentional and expected.
- A **consecutive violation** is when two **separate instances** of the same activity end up adjacent — e.g. instance-1 in period 3 and instance-2 in period 4 on the same day.
- For `duration > 1`, check whether the adjacent period **before block start** or **after block end** is occupied by another instance of the same activity.

### File & Lines
`FETSolver.php` — `violatesNoConsecutiveRule()` starting at line 634.

### Current Code
```php
private function violatesNoConsecutiveRule($activity, Slot $slot, int $duration, string $classKey, $context): bool
{
    // Any multi-period block for same activity is inherently consecutive.
    if ($duration > 1) {
        return true;
    }
    // ... rest of method
```

### New Code
```php
private function violatesNoConsecutiveRule($activity, Slot $slot, int $duration, string $classKey, $context): bool
{
    $currentOriginalActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');

    if ($duration > 1) {
        // A multi-period block (e.g. Lab = periods 3+4) is one intended unit — NOT a violation.
        // Only flag it if ANOTHER instance of the same activity is directly adjacent
        // to the block's start or end on the same day.
        $blockStart = $slot->startIndex;
        $blockEnd   = $blockStart + $duration - 1;

        // Check the period immediately before the block
        if ($blockStart > 0) {
            $prevPeriodId = $this->periods[$blockStart - 1]->id ?? null;
            if ($prevPeriodId && isset($context->occupied[$classKey][$slot->dayId][$prevPeriodId])) {
                $prevToken = $context->occupied[$classKey][$slot->dayId][$prevPeriodId];
                if ($this->extractOriginalActivityIdFromToken($prevToken) === $currentOriginalActivityId) {
                    return true;
                }
            }
        }

        // Check the period immediately after the block
        $afterEnd = $blockEnd + 1;
        if ($afterEnd < $this->periods->count()) {
            $nextPeriodId = $this->periods[$afterEnd]->id ?? null;
            if ($nextPeriodId && isset($context->occupied[$classKey][$slot->dayId][$nextPeriodId])) {
                $nextToken = $context->occupied[$classKey][$slot->dayId][$nextPeriodId];
                if ($this->extractOriginalActivityIdFromToken($nextToken) === $currentOriginalActivityId) {
                    return true;
                }
            }
        }

        return false; // Multi-period block with no adjacent same-activity instance is fine
    }

    $periodIndex = $slot->startIndex;

    // Previous slot on same day
    if ($periodIndex > 0) {
        $previousPeriodId = $this->periods[$periodIndex - 1]->id ?? null;
        if ($previousPeriodId !== null && isset($context->occupied[$classKey][$slot->dayId][$previousPeriodId])) {
            $previousToken = $context->occupied[$classKey][$slot->dayId][$previousPeriodId];
            if ($this->extractOriginalActivityIdFromToken($previousToken) === $currentOriginalActivityId) {
                return true;
            }
        }
    }

    // Next slot on same day
    $nextIndex = $periodIndex + 1;
    if ($nextIndex < $this->periods->count()) {
        $nextPeriodId = $this->periods[$nextIndex]->id ?? null;
        if ($nextPeriodId !== null && isset($context->occupied[$classKey][$slot->dayId][$nextPeriodId])) {
            $nextToken = $context->occupied[$classKey][$slot->dayId][$nextPeriodId];
            if ($this->extractOriginalActivityIdFromToken($nextToken) === $currentOriginalActivityId) {
                return true;
            }
        }
    }

    return false;
}
```

### Benefit
Lab, Hobby, Astro, Robotics, Physics/Chemistry/Biology practicals — all activities requiring `duration_periods > 1` — will now be placed in the primary backtracking/greedy pass at their best available slots instead of being punted to the forced placement pass.

---

## Sub-Task 2.2 — Per-Activity `allow_consecutive` Override

### What & Why
`FETSolver` has a global flag `$disallowConsecutivePeriods = true` (line 72) that applies to every activity equally. However, the `Activity` model has a field `allow_consecutive` (boolean, default `0`) that is supposed to allow specific activities to have multiple instances back-to-back.

**Use case:** Some schools allow back-to-back periods for certain subjects (e.g. English with 6 periods/week might run periods 1+2 on Monday to cover essay writing). When the activity has `allow_consecutive = true`, the consecutive check should be skipped entirely for that activity.

### What the fix does
In `isBasicSlotAvailable()`, before applying the global consecutive check, read `activity->allow_consecutive`. If it is `true`, skip the call to `violatesNoConsecutiveRule()`.

### File & Lines
`FETSolver.php` — `isBasicSlotAvailable()` at line 492.

### Current Code
```php
if (!$ignoreConsecutive && $this->disallowConsecutivePeriods && $this->violatesNoConsecutiveRule($activity, $slot, $duration, $classKey, $context)) {
    return false;
}
```

### New Code
```php
$activityAllowsConsecutive = (bool) ($activity->allow_consecutive ?? false);

if (
    !$ignoreConsecutive
    && $this->disallowConsecutivePeriods
    && !$activityAllowsConsecutive
    && $this->violatesNoConsecutiveRule($activity, $slot, $duration, $classKey, $context)
) {
    return false;
}
```

### Benefit
Activities explicitly configured with `allow_consecutive = true` bypass the consecutive rule. All others still respect the global `$disallowConsecutivePeriods` flag. No global behaviour change — purely additive.

---

## Sub-Task 2.3 — Per-Activity `max_per_day` Override

### What & Why
`violatesDailyActivityPlacementCap()` (line 679) calculates the maximum instances of an activity per day using a formula: `ceil(weeklyPeriods / daysCount)`. This formula is fine as a fallback but ignores the `max_per_day` field on the `Activity` model.

**Use case:** A school may want Maths (6 periods/week, 6 days) placed at most 1 per day, not 2. Or PE (2 periods/week) should have at most 1 per day. Currently the formula gives `ceil(6/6) = 1` and `ceil(2/6) = 1` — both happen to be right, but for activities with 9 periods/week the formula gives `ceil(9/6) = 2`, which may be wrong if the school wants max 1 per day.

Setting `max_per_day = 1` on an activity explicitly limits it to one slot per day regardless of the formula result.

### What the fix does
In **both** `violatesDailyActivityPlacementCap()` and `getMaxPlacementsPerDay()`: check `activity->max_per_day` first. If it is set (not null), use it. Otherwise fall back to the formula.

### File & Lines
`FETSolver.php` — `violatesDailyActivityPlacementCap()` at line 679, `getMaxPlacementsPerDay()` at line 623.

### Current Code (violatesDailyActivityPlacementCap)
```php
private function violatesDailyActivityPlacementCap($activity, Slot $slot, string $classKey, $context): bool
{
    $daysCount = max(1, $this->days->count());
    $requiredWeeklyPeriods = (int) ($activity->required_weekly_periods ?? 0);
    $currentDayCount = $this->getDailyPlacementCountForActivity($activity, $classKey, $slot->dayId, $context);

    $maxPerDay = max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));
    if ($requiredWeeklyPeriods <= $daysCount) {
        $maxPerDay = 1;
    }

    return $currentDayCount >= $maxPerDay;
}
```

### Current Code (getMaxPlacementsPerDay)
```php
private function getMaxPlacementsPerDay($activity): int
{
    $daysCount = max(1, $this->days->count());
    $requiredWeeklyPeriods = (int) ($activity->required_weekly_periods ?? 0);
    $maxPerDay = max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));
    if ($requiredWeeklyPeriods <= $daysCount) {
        $maxPerDay = 1;
    }
    return $maxPerDay;
}
```

### New Code (both methods use same resolution logic)
Extract to a helper that both methods call:

```php
private function resolveMaxPerDay($activity): int
{
    // Respect explicit activity-level cap if set
    $activityCap = isset($activity->max_per_day) ? (int) $activity->max_per_day : null;
    if ($activityCap !== null && $activityCap > 0) {
        return $activityCap;
    }

    // Fallback: dynamic formula based on weekly demand
    $daysCount = max(1, $this->days->count());
    $requiredWeeklyPeriods = (int) ($activity->required_weekly_periods ?? 0);

    if ($requiredWeeklyPeriods <= $daysCount) {
        return 1;
    }

    return max(1, (int) ceil($requiredWeeklyPeriods / $daysCount));
}
```

Then update both callers:
```php
// violatesDailyActivityPlacementCap — replace the formula lines:
$maxPerDay = $this->resolveMaxPerDay($activity);
return $currentDayCount >= $maxPerDay;

// getMaxPlacementsPerDay — replace entire body:
return $this->resolveMaxPerDay($activity);
```

### Benefit
Schools can configure exactly how many times a subject appears per day, and the generator will respect it. Falls back safely to formula when `max_per_day` is not set.

---

## Sub-Task 2.4 — Min-Gap Enforcement (`min_gap_periods`)

### What & Why
The `Activity` model has a `min_gap_periods` field (TINYINT, default NULL). It means: "after placing one instance of this activity on a day, the next instance on the same day must be at least N periods away."

**Use case:** A teacher finds it exhausting to teach the same subject twice in a row, even with a break between. A school might set `min_gap_periods = 3` on an activity to ensure the second instance happens well after the first. Currently this field is never checked — two instances of the same activity could end up 1 period apart (technically non-consecutive but too close).

### What the fix does
1. Add a new private method `violatesMinGapRule()` that checks the occupied context for existing placements of the same activity on the same day and measures the period distance.
2. Call it from `isBasicSlotAvailable()` after the consecutive check — only when `min_gap_periods` is set on the activity.

### File & Lines
`FETSolver.php` — new method added after `violatesNoConsecutiveRule()` (around line 668); `isBasicSlotAvailable()` at line 492.

### New Method
```php
private function violatesMinGapRule($activity, Slot $slot, int $minGap, string $classKey, $context): bool
{
    $occupiedForDay = $context->occupied[$classKey][$slot->dayId] ?? [];
    $currentActivityId = (string) ($activity->original_activity_id ?? $activity->id ?? '');

    foreach ($occupiedForDay as $periodId => $token) {
        if ($this->extractOriginalActivityIdFromToken($token) !== $currentActivityId) {
            continue;
        }

        // Find the period index of the already-placed instance
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

        // Gap must be strictly greater than minGap
        $gap = abs($slot->startIndex - $occupiedIndex);
        if ($gap > 0 && $gap <= $minGap) {
            return true; // Too close to an existing instance
        }
    }

    return false;
}
```

### Addition to `isBasicSlotAvailable()` — after the consecutive check block:
```php
// Per-activity minimum gap between instances on same day
$minGap = (int) ($activity->min_gap_periods ?? 0);
if (!$ignoreConsecutive && $minGap > 0) {
    if ($this->violatesMinGapRule($activity, $slot, $minGap, $classKey, $context)) {
        return false;
    }
}
```

Note: uses `$ignoreConsecutive` flag since rescue/forced passes pass `true` for this, meaning gap is also relaxed in last-resort placement.

### Benefit
When data operators set `min_gap_periods = 2` on an activity, the solver will not place two instances within 2 periods of each other on the same day. This produces more evenly distributed schedules for high-frequency subjects.

---

## Sub-Task 2.5 — Slot Scoring Method (`scoreSlotForActivity`)

### What & Why
Currently `getPossibleSlots()` either shuffles slots (random order) or sorts by pinning/class-teacher priority. There is **no quality scoring** — the algorithm picks the first available slot, not the best one.

The `Activity` model has four JSON fields that express timing preferences:
- `preferred_time_slots_json` — specific day+period combos the activity prefers (strongest)
- `avoid_time_slots_json` — specific day+period combos to avoid (strongest negative)
- `preferred_periods_json` — period ordinals preferred across all days (medium)
- `avoid_periods_json` — period ordinals to avoid across all days (medium negative)
- `spread_evenly` (boolean) — whether instances should be spread across different days

These fields are **set by data operators** when configuring activities (e.g. "Maths for Class 4T should only be in periods 6-8"). Without scoring, the solver ignores them entirely. With scoring, the solver tries preferred slots first and avoids bad slots.

### What the fix does
Add a new private method `scoreSlotForActivity()` that:
1. Resolves the `period_ord` for the slot's `startIndex`
2. Checks all 5 preference fields and returns a numeric score
3. Higher score = better slot for this activity

**Score weights (designed so avoidance beats preference):**
| Check | Points |
|-------|--------|
| Matches `preferred_time_slots_json` (day+period exact) | +40 |
| Matches `preferred_periods_json` (period only) | +20 |
| Matches `avoid_time_slots_json` (day+period exact) | -50 |
| Matches `avoid_periods_json` (period only) | -30 |
| `spread_evenly=true` AND this day has 0 placements so far | +10 |
| `spread_evenly=true` AND this day already has ≥1 placement | -15 |

### File & Lines
`FETSolver.php` — new method added after `simulatePlacement()` (around line 830), before `getPossibleSlots()`.

### New Method
```php
/**
 * Score a slot based on activity-level soft preferences.
 * Higher score = better slot for this activity.
 * Returns 0 if no preferences are set on the activity.
 */
private function scoreSlotForActivity($activity, Slot $slot, $context): int
{
    $score = 0;
    $periodIndex = $slot->startIndex;
    $dayId = $slot->dayId;

    // Resolve period_ord for this slot index
    $period = $this->periods[$periodIndex] ?? null;
    if (!$period) {
        return 0;
    }
    $periodOrd = (int) ($period->period_ord ?? ($periodIndex + 1));

    // --- preferred_time_slots_json: exact day+period match (+40) ---
    $preferredTimeSlots = $activity->preferred_time_slots_json ?? [];
    if (!empty($preferredTimeSlots)) {
        foreach ($preferredTimeSlots as $pref) {
            if (($pref['day_id'] ?? null) == $dayId && ($pref['period_ord'] ?? null) == $periodOrd) {
                $score += 40;
                break;
            }
        }
    }

    // --- avoid_time_slots_json: exact day+period match (-50) ---
    $avoidTimeSlots = $activity->avoid_time_slots_json ?? [];
    if (!empty($avoidTimeSlots)) {
        foreach ($avoidTimeSlots as $avoid) {
            if (($avoid['day_id'] ?? null) == $dayId && ($avoid['period_ord'] ?? null) == $periodOrd) {
                $score -= 50;
                break;
            }
        }
    }

    // --- preferred_periods_json: period ordinal match (+20) ---
    $preferredPeriods = $activity->preferred_periods_json ?? [];
    if (!empty($preferredPeriods) && in_array($periodOrd, $preferredPeriods, true)) {
        $score += 20;
    }

    // --- avoid_periods_json: period ordinal match (-30) ---
    $avoidPeriods = $activity->avoid_periods_json ?? [];
    if (!empty($avoidPeriods) && in_array($periodOrd, $avoidPeriods, true)) {
        $score -= 30;
    }

    // --- spread_evenly: reward unused days, penalise already-used days ---
    $spreadEvenly = (bool) ($activity->spread_evenly ?? true);
    if ($spreadEvenly) {
        $classKey = $slot->classKey;
        $dailyCount = $this->getDailyPlacementCountForActivity($activity, $classKey, $dayId, $context);
        if ($dailyCount === 0) {
            $score += 10;
        } elseif ($dailyCount >= 1) {
            $score -= 15;
        }
    }

    return $score;
}
```

### Benefit
Slot scoring is now possible. Activities with no preferences set return 0 — no behaviour change. Activities with preferences set get their preferred slots bubbled to the front of the candidate list, giving the solver a much higher chance of satisfying school-specific constraints.

---

## Sub-Task 2.6 — Integrate Scoring into `getPossibleSlots()`

### What & Why
`scoreSlotForActivity()` (Sub-Task 2.5) does nothing on its own — it must be called from `getPossibleSlots()` to actually influence which slots get tried first.

Currently `getPossibleSlots()` (line 838) ends with either:
- A `usort()` sorting by class-teacher-first / pinning affinity
- A `shuffle()` when no special mode is active

The soft scoring needs to be layered **into** the sort comparator as a **lower-priority tiebreaker** after class-teacher-first and pinning. The existing high-priority sorts (structural constraints) must NOT be overridden by soft preferences.

### What the fix does
After collecting valid `$slots[]`, check whether the activity has any preference fields set. If yes, compute a score for each slot and fold that score into the existing `usort` comparator as the lowest-priority criterion.

**Sort priority order (highest to lowest):**
1. Pinning affinity match (existing)
2. Class-teacher first lecture (existing)
3. Activity soft score from `scoreSlotForActivity()` ← **NEW**
4. Day order (existing fallback)

### File & Lines
`FETSolver.php` — `getPossibleSlots()` starting at line 838. Specifically the `usort()` block (line 887) and the `else { shuffle($slots); }` block (line 920-923).

### Current Code (the usort comparator, simplified)
```php
usort($slots, function (Slot $a, Slot $b) use (...) {
    // 1. Pinning affinity
    // 2. Class-teacher first
    // 3. Day order fallback
    return $a->startIndex <=> $b->startIndex;
});
```
And when no special modes:
```php
} else {
    shuffle($slots);
}
```

### New Code

**Inside the existing `usort` comparator**, add soft scoring BEFORE the final day-order fallback:
```php
usort($slots, function (Slot $a, Slot $b) use ($activity, $context, $isClassTeacherActivity, $classHasClassTeacherActivities, $shouldEnforceForThisClass, $preferredPeriodIndex) {
    // Priority 1: Pinning affinity (unchanged)
    if ($this->pinActivitiesByPeriod && $preferredPeriodIndex !== null) {
        $aMatchesAffinity = ($a->startIndex === $preferredPeriodIndex);
        $bMatchesAffinity = ($b->startIndex === $preferredPeriodIndex);
        if ($aMatchesAffinity !== $bMatchesAffinity) {
            return $aMatchesAffinity ? -1 : 1;
        }
    }

    // Priority 2: Class-teacher first lecture (unchanged)
    $aIsFirst = $this->isFirstLectureSlot($a);
    $bIsFirst = $this->isFirstLectureSlot($b);
    if ($shouldEnforceForThisClass && $aIsFirst !== $bIsFirst) {
        if ($classHasClassTeacherActivities && $isClassTeacherActivity) {
            return $aIsFirst ? -1 : 1;
        }
        if ($classHasClassTeacherActivities) {
            return $aIsFirst ? 1 : -1;
        }
        return 0;
    }

    // Priority 3: Activity-level soft score (NEW)
    $scoreA = $this->scoreSlotForActivity($activity, $a, $context);
    $scoreB = $this->scoreSlotForActivity($activity, $b, $context);
    if ($scoreA !== $scoreB) {
        return $scoreB <=> $scoreA; // Higher score first
    }

    // Priority 4: Day order (unchanged fallback)
    if ($a->dayId !== $b->dayId) {
        return $a->dayId <=> $b->dayId;
    }
    return $a->startIndex <=> $b->startIndex;
});
```

**Replace the `else { shuffle($slots); }` block** to also apply scoring when no structural mode is active:
```php
} else {
    $hasPreferences = !empty($activity->preferred_time_slots_json)
        || !empty($activity->avoid_time_slots_json)
        || !empty($activity->preferred_periods_json)
        || !empty($activity->avoid_periods_json);

    if ($hasPreferences) {
        usort($slots, function (Slot $a, Slot $b) use ($activity, $context) {
            $scoreA = $this->scoreSlotForActivity($activity, $a, $context);
            $scoreB = $this->scoreSlotForActivity($activity, $b, $context);
            if ($scoreA !== $scoreB) {
                return $scoreB <=> $scoreA;
            }
            return random_int(-1, 1);
        });
    } else {
        shuffle($slots); // No preferences — keep original random behaviour
    }
}
```

### Benefit
Preferred slots are now tried before neutral slots, and avoided slots are tried last. The structural constraints (class-teacher first, pinning) still take absolute priority. Activities with no preferences set fall back to the original shuffle/sort behaviour — **zero regression risk** for existing behaviour.

---

## Sub-Task 2.7 — Auto-Populate Activity Constraint Fields

### What & Why
Sub-tasks 2.3–2.6 all read from `activity->max_per_day`, `activity->allow_consecutive`, `activity->preferred_periods_json`, etc. These fields are correctly defined in the model and schema, but they are **never automatically populated** during activity generation. They stay at their database defaults (NULL or 0) unless a data operator manually edits each activity record.

Two fields are particularly important for the generator's **ordering logic**:
- `difficulty_score_calculated` — always defaults to 50 (not computed)
- `constraint_count` — always defaults to 0 (not counted)

These two fields are used in `schedulingScore()` on the Activity model but ignored in `orderActivitiesByDifficulty()` in FETSolver.

### What the fix does

**Part A — In `ActivityController`**: When `generateActivities()` creates or updates an activity, compute and store:
- `difficulty_score_calculated` — based on: number of constraints affecting this activity, teacher availability score, room requirement strictness, weekly period count
- `constraint_count` — count of active `tt_constraints` records that target this activity's class, section, or subject

**Part B — In `FETSolver::orderActivitiesByDifficulty()`**: Use `activity->difficulty_score_calculated` (when > 0) in place of the manual difficulty score, so the pre-computed data drives ordering.

### File & Lines
- `ActivityController.php` — inside `generateActivities()` or `store()` / `update()` — add calculation before `Activity::create()`
- `FETSolver.php` — `orderActivitiesByDifficulty()` at line 1467

### Calculation Logic (Part A — ActivityController)

```php
// After determining the activity's parameters, before create/update:
$constraintCount = \Modules\SmartTimetable\Models\Constraint::query()
    ->where('is_active', true)
    ->where(function ($q) use ($activity) {
        $q->whereNull('class_id')->orWhere('class_id', $activity['class_id']);
    })
    ->count();

$difficultyScore = 50; // baseline
$difficultyScore += min(30, $constraintCount * 5);          // more constraints = harder
$difficultyScore += ($activity['required_weekly_periods'] >= 6) ? 20 : 0; // high demand
$difficultyScore += ($activity['duration_periods'] > 1) ? 10 : 0;          // multi-period
$difficultyScore -= min(20, (int) ($activity['eligible_teacher_count'] ?? 0) * 5); // more teachers = easier
$difficultyScore = max(10, min(100, $difficultyScore));      // clamp 10–100

// Store computed fields:
$activity['difficulty_score_calculated'] = $difficultyScore;
$activity['constraint_count'] = $constraintCount;
```

### Score Usage (Part B — FETSolver)

In `orderActivitiesByDifficulty()`, replace the `$score` seed:
```php
// Current: $score = 0;
// New: seed with pre-calculated difficulty if available
$score = (int) ($activity->difficulty_score_calculated ?? 0);
if ($score === 0) {
    $score = (int) ($activity->difficulty_score ?? 0);
}
```

### Benefit
- `difficulty_score_calculated` drives better activity ordering (hardest-to-place first), leading to higher coverage rates.
- `constraint_count` makes the computed difficulty responsive to how many constraints an activity carries.
- Data operators no longer need to manually set these fields — they're computed automatically on each activity generation run.

---

## Execution Order

```
2.1 (Bug fix — multi-period) ──→ 2.2 (allow_consecutive) ──→ 2.3 (max_per_day)
                                                                    │
                                                               2.4 (min_gap)
                                                                    │
                                                    2.5 (scoreSlotForActivity) ──→ 2.6 (integrate into getPossibleSlots)

2.7 (auto-populate fields) — can be done in parallel, independent of 2.1–2.6
```

Sub-tasks 2.1–2.4 are purely **in `isBasicSlotAvailable()` and `violatesNoConsecutiveRule()`** — they are hard rule changes.
Sub-tasks 2.5–2.6 are purely **in `getPossibleSlots()`** — they are soft scoring additions.
Sub-task 2.7 is **in `ActivityController`** and `orderActivitiesByDifficulty()` — independent of the others.

All changes are **backwards compatible** — when the activity fields are NULL/0/false/empty, the code falls back to existing behaviour exactly.

---

## Testing Checklist (after all sub-tasks done)

- [ ] Activity with `duration_periods = 2` (Lab) gets placed in backtracking pass, not forced pass
- [ ] Activity with `allow_consecutive = true` can have two instances in adjacent periods
- [ ] Activity with `allow_consecutive = false` (default) still prevents adjacent same-activity periods
- [ ] Activity with `max_per_day = 1` never appears twice on same day, even if formula would allow 2
- [ ] Activity with `min_gap_periods = 3` has at least 3 periods between instances on same day
- [ ] Activity with `preferred_periods_json = [3, 4]` gets placed in period 3 or 4 more often than other periods
- [ ] Activity with `avoid_time_slots_json = [{"day_id": 5, "period_ord": 8}]` is never placed in Friday period 8 (unless it's the only option)
- [ ] Activity with no preference fields set behaves identically to before — no regression
- [ ] `difficulty_score_calculated` is non-zero after running `generateActivities()`
