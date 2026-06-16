# P05 — Activity Constraint Integration

**Phase:** 3 | **Priority:** P1 | **Effort:** 2 days
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P01 (Phase 1 bug fixes must be done first)
**Reference:** `2026Mar10_Step2_ActivityConstraints_SubTasks.md`

---

## Pre-Requisites

Read these files before starting:
1. `AI_Brain/rules/smart-timetable.md`
2. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — focus on `scoreSlotForActivity()`, `isBasicSlotAvailable()`, `violatesNoConsecutiveRule()`
3. `Modules/SmartTimetable/app/Models/Activity.php` — check available fields
4. `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`

---

## Task 3.1 — Fix multi-period consecutive bug (15 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Line:** ~634 (inside `violatesNoConsecutiveRule()`)

**Change:** Rewrite to check if ANOTHER instance of the same activity is adjacent, not if `duration > 1`.

```php
protected function violatesNoConsecutiveRule($activity, $dayId, $periodIndex, $context): bool
{
    // Get the activity's subject+class key for comparison
    $activityKey = $activity->subject_id . '_' . ($activity->class_section_id ?? $activity->class_id);

    // Check adjacent periods (before and after the activity's full span)
    $checkPeriods = [$periodIndex - 1, $periodIndex + ($activity->duration ?? 1)];

    foreach ($checkPeriods as $adjPeriod) {
        if ($adjPeriod < 0) continue;

        $adjSlotKey = "{$dayId}_{$adjPeriod}";
        $placedActivity = $this->solution->getActivityAt($adjSlotKey);

        if ($placedActivity) {
            $placedKey = $placedActivity->subject_id . '_' . ($placedActivity->class_section_id ?? $placedActivity->class_id);
            if ($placedKey === $activityKey && $placedActivity->id !== $activity->id) {
                return true; // Another instance of same subject+class is adjacent
            }
        }
    }

    return false;
}
```

**Note:** This duplicates Task 1.3 from P01 — skip if already done.

---

## Task 3.2 — Per-activity consecutive override (10 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Line:** ~492 (where `violatesNoConsecutiveRule()` is called)

**Change:** Check `$activity->allow_consecutive` before applying the rule:

```php
// Before calling violatesNoConsecutiveRule:
if (!($activity->allow_consecutive ?? false) && $this->violatesNoConsecutiveRule($activity, $dayId, $periodIndex, $context)) {
    return false; // Slot not available
}
```

**Why:** Labs and practicals need consecutive periods. The `allow_consecutive` field on Activity lets individual activities opt out of the consecutive rule.

---

## Task 3.3 — Per-activity daily cap override (10 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Line:** ~679 (where daily cap is checked)

**Change:** Use `$activity->max_per_day` instead of hardcoded daily cap when the field is set:

```php
$maxPerDay = $activity->max_per_day ?? $this->defaultMaxPerDay ?? 2;
// Use $maxPerDay instead of hardcoded value
```

**Why:** Some subjects need 3 periods/day while others should be max 1.

---

## Task 3.4 — Min-gap enforcement (20 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`

**Change:** Add new method and wire it:

```php
protected function violatesMinGapRule($activity, $dayId, $periodIndex, $context): bool
{
    $minGap = $activity->min_gap_periods ?? 0;
    if ($minGap <= 0) return false;

    $activityKey = $activity->subject_id . '_' . ($activity->class_section_id ?? $activity->class_id);

    // Check all placed activities for same subject+class on same day
    $placedOnDay = $this->solution->getPlacementsForDay($dayId);

    foreach ($placedOnDay as $placed) {
        $placedKey = $placed->subject_id . '_' . ($placed->class_section_id ?? $placed->class_id);
        if ($placedKey === $activityKey && $placed->id !== $activity->id) {
            $placedPeriod = $placed->placed_period_index; // however period is tracked
            $gap = abs($periodIndex - $placedPeriod) - 1;
            if ($gap < $minGap) {
                return true; // Too close
            }
        }
    }

    return false;
}
```

Wire into `isBasicSlotAvailable()`:
```php
if ($this->violatesMinGapRule($activity, $dayId, $periodIndex, $context)) {
    return false;
}
```

---

## Task 3.5 — Soft constraint slot scoring (30 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Method:** `scoreSlotForActivity()`

**Change:** Add scoring for activity-level preference fields:

```php
// After existing scoring logic, before return $score:

// Preferred periods scoring
if ($activity->preferred_periods_json) {
    $preferred = json_decode($activity->preferred_periods_json, true) ?? [];
    foreach ($preferred as $pref) {
        if (($pref['day_id'] ?? null) == $dayId && ($pref['period_index'] ?? null) == $periodIndex) {
            $score += 40; // Exact match
        } elseif (($pref['period_index'] ?? null) == $periodIndex) {
            $score += 20; // Period match (any day)
        }
    }
}

// Avoid periods scoring
if ($activity->avoid_periods_json) {
    $avoid = json_decode($activity->avoid_periods_json, true) ?? [];
    foreach ($avoid as $avd) {
        if (($avd['day_id'] ?? null) == $dayId && ($avd['period_index'] ?? null) == $periodIndex) {
            $score -= 50; // Exact match penalty
        } elseif (($avd['period_index'] ?? null) == $periodIndex) {
            $score -= 30; // Period match penalty (any day)
        }
    }
}

// Day spread bonus
$daysUsed = $this->solution->getDaysUsedByActivity($activity);
if (!in_array($dayId, $daysUsed)) {
    $score += 10; // Bonus for spreading to unused day
} else {
    $score -= 15; // Penalty for same day (encourages spread)
}
```

**Note:** D18 already wired `evaluateSoftConstraints()` from ConstraintManager. This task adds activity-level field scoring ON TOP of that.

---

## Task 3.6 — Integrate scoring into getPossibleSlots (20 min)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Line:** ~838

**Change:** Ensure `scoreSlotForActivity()` is called for each candidate slot and results are sorted by score descending:

```php
// In getPossibleSlots() or equivalent:
$scored = [];
foreach ($candidateSlots as $slot) {
    $score = $this->scoreSlotForActivity($activity, $slot->dayId, $slot->periodIndex, $context);
    $scored[] = ['slot' => $slot, 'score' => $score];
}

// Sort by score descending
usort($scored, fn($a, $b) => $b['score'] <=> $a['score']);

return array_map(fn($s) => $s['slot'], $scored);
```

**Verify:** Check that this doesn't duplicate existing scoring logic. If `scoreSlotForActivity()` is already called and sorted, just ensure Tasks 3.2-3.5 additions are included in the score.

---

## Task 3.7 — Auto-populate constraint fields on Activity (30 min)

**File:** `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`

**Change:** When activities are generated (in the `generate()` or similar method), auto-populate activity-level constraint fields from subject/teacher defaults:

```php
// After creating/updating each activity:
$activity->max_per_day = $activity->max_per_day ?? (int) ceil(($activity->weekly_periods ?? 5) / 5);
$activity->min_gap_periods = $activity->min_gap_periods ?? 0;
$activity->allow_consecutive = $activity->allow_consecutive ?? $this->isLabOrPractical($activity);
// Save if changed
```

Add helper:
```php
private function isLabOrPractical($activity): bool
{
    // Check study format or subject type
    $studyFormat = $activity->subjectStudyFormat->studyFormat ?? null;
    if ($studyFormat) {
        return in_array(strtolower($studyFormat->name), ['lab', 'practical', 'workshop']);
    }
    return ($activity->duration ?? 1) > 1;
}
```

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
2. Run: `/lint Modules/SmartTimetable/app/Http/Controllers/ActivityController.php`
3. Run: `/test SmartTimetable` — all tests pass
4. Update AI Brain:
   - `known-issues.md` → Mark GAP-1 as RESOLVED
   - `progress.md` → Phase 3 done, Activity Constraints integrated
   - `decisions.md` → No new decisions (extends D18 soft constraint wiring)
