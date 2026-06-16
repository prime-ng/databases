# P12 — Inter-Activity Constraints Part 1 (H1-H7, H20-H22)

**Phase:** 15 (Tasks 15.1–15.5) | **Priority:** P1 | **Effort:** 5 days
**Skill:** Backend | **Model:** Opus (complex solver changes)
**Branch:** Tarun_SmartTimetable
**Dependencies:** P09 (Phase 11 — Constraint Architecture)
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category H
**WARNING:** These require solver-level changes in FETSolver, similar to how Parallel Periods (H8) was implemented

---

## Pre-Requisites

Read ALL before starting:
1. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — Category H (all 22 rules)
2. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php` — understand backtrack(), generateGreedySolution(), parallel group handling
3. `Modules/SmartTimetable/app/Services/Constraints/Hard/ParallelPeriodConstraint.php` — reference for H8 pattern
4. `Modules/SmartTimetable/app/Services/Solver/TimetableSolution.php` — placement tracking
5. `Modules/SmartTimetable/app/Models/Activity.php` — check for group relationships

---

## Task 15.1 — Activity group infrastructure in FETSolver (1 day)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`

Extend the existing parallel group infrastructure to support ALL inter-activity relationship types.

**New data structures:**
```php
// Add to FETSolver properties:
protected array $activityGroupMap = [];    // activityId => [{group_id, group_type, relationship_type}]
protected array $activityGroups = [];       // groupId => {type, members: [activityIds]}

// Load from DB in initialize() or constructor:
protected function loadActivityGroups(): void
{
    // Load from tt_parallel_group (existing) + any new activity group table
    // OR extend tt_parallel_group to support more relationship types

    // For now, use tt_parallel_group with a 'group_type' field:
    // PARALLEL (H8 — existing), SAME_TIME (H1), SAME_DAY (H2), SAME_HOUR (H3),
    // NOT_OVERLAPPING (H4), CONSECUTIVE (H5), ORDERED (H6), GROUPED (H7)

    $groups = ParallelGroup::with('activities.activity')
        ->where('is_active', true)
        ->get();

    foreach ($groups as $group) {
        $this->activityGroups[$group->id] = [
            'type' => $group->group_type ?? 'PARALLEL',
            'members' => $group->activities->pluck('activity_id')->toArray(),
        ];

        foreach ($group->activities as $ga) {
            $this->activityGroupMap[$ga->activity_id][] = [
                'group_id' => $group->id,
                'group_type' => $group->group_type ?? 'PARALLEL',
                'is_anchor' => $ga->is_anchor ?? false,
            ];
        }
    }
}
```

**Helper method:**
```php
protected function getGroupConstraintForActivity(int $activityId, string $groupType): ?array
{
    $groups = $this->activityGroupMap[$activityId] ?? [];
    foreach ($groups as $g) {
        if ($g['group_type'] === $groupType) {
            return $this->activityGroups[$g['group_id']] ?? null;
        }
    }
    return null;
}
```

**Schema consideration:** If `tt_parallel_group` doesn't have a `group_type` column, create an additive migration to add it:
```php
Schema::table('tt_parallel_group', function (Blueprint $table) {
    $table->string('group_type', 30)->default('PARALLEL')->after('name');
});
```

---

## Task 15.2 — Same-time / same-day / same-hour H1-H3 (1.5 days)

### H1 — Same Starting Time (HARD/SOFT)

**Solver change:** When placing an activity that belongs to a SAME_TIME group:
```php
// In backtrack() or wherever placement decisions are made:
$sameTimeGroup = $this->getGroupConstraintForActivity($activity->id, 'SAME_TIME');
if ($sameTimeGroup) {
    // Check if other members are already placed
    foreach ($sameTimeGroup['members'] as $memberId) {
        if ($memberId === $activity->id) continue;
        $memberPlacement = $this->solution->getPlacement($memberId);
        if ($memberPlacement) {
            // Restrict this activity to same starting time
            if ($periodIndex !== $memberPlacement['periodIndex']) {
                continue; // Skip this slot
            }
        }
    }
}
```

### H2 — Same Day

Same pattern but only enforce `$dayId === $memberPlacement['dayId']`.

### H3 — Same Hour

Same pattern but only enforce `$periodIndex === $memberPlacement['periodIndex']`.

**Create constraint classes for the ConstraintManager too:**
- `Hard/SameStartingTimeConstraint.php`
- `Soft/SameDayConstraint.php`
- `Soft/SameHourConstraint.php`

---

## Task 15.3 — Consecutive / ordered / grouped H5-H7 (2 days)

### H5 — Consecutive (ordered)

**Solver change:** Block-placement logic — after placing activity A, force activity B to adjacent slot:
```php
// When activity A is placed at (dayId, periodIndex):
$consecutiveGroup = $this->getGroupConstraintForActivity($activity->id, 'CONSECUTIVE');
if ($consecutiveGroup) {
    $members = $consecutiveGroup['members'];
    $myIndex = array_search($activity->id, $members);

    if ($myIndex !== false && isset($members[$myIndex + 1])) {
        $nextActivityId = $members[$myIndex + 1];
        $nextActivity = $this->getActivityById($nextActivityId);

        // Try to place next activity at adjacent period
        $nextSlot = $periodIndex + ($activity->duration ?? 1);
        if ($this->canPlaceAt($nextActivity, $dayId, $nextSlot)) {
            $this->solution->place($nextActivity, $dayId, $nextSlot);
        }
    }
}
```

### H6 — Ordered if Same Day

Only enforce A before B when both are on the same day:
```php
if ($dayId === $otherDayId) {
    // A must come before B
    if ($activity === $activityA && $periodIndex >= $otherPeriodIndex) {
        return false; // A must be before B
    }
}
```

### H7 — Grouped Block (2-3 activities as contiguous block)

Similar to multi-period duration but across different activities. Treat the group as one "super activity" for placement purposes.

---

## Task 15.4 — Not-overlapping H4 (0.5 day)

**Simpler constraint:** Check that two activities in a NOT_OVERLAPPING group don't share any period on any day.

```php
// In constraint check:
$notOverlapGroup = $this->getGroupConstraintForActivity($activity->id, 'NOT_OVERLAPPING');
if ($notOverlapGroup) {
    foreach ($notOverlapGroup['members'] as $memberId) {
        if ($memberId === $activity->id) continue;
        $memberPlacement = $this->solution->getPlacement($memberId);
        if ($memberPlacement && $memberPlacement['dayId'] === $dayId) {
            $memberStart = $memberPlacement['periodIndex'];
            $memberEnd = $memberStart + ($memberPlacement['duration'] ?? 1);
            $myEnd = $periodIndex + ($activity->duration ?? 1);

            // Check for overlap
            if ($periodIndex < $memberEnd && $myEnd > $memberStart) {
                return false; // Overlapping
            }
        }
    }
}
```

---

## Task 15.5 — Day/period pinning and exclusion H20-H22 (1 day)

These are simpler — filter candidate slots before scoring.

### H20 — Activity Fixed to Specific Day (HARD/SOFT) — School Req #14

**File:** `Hard/ActivityFixedToDayConstraint.php`
```php
public function passes(ConstraintContext $context): bool
{
    $params = json_decode($this->constraintModel->params_json, true);
    $fixedDayId = $params['day_id'] ?? null;
    if (!$fixedDayId) return true;
    return $context->dayId == $fixedDayId;
}
```

### H21 — Activity Excluded from Day

```php
$excludedDayId = $params['day_id'] ?? null;
return $context->dayId != $excludedDayId;
```

### H22 — Activity Fixed to Period Range — School Req #1

```php
$periodStart = $params['period_start'] ?? 0;
$periodEnd = $params['period_end'] ?? 999;
return $context->periodIndex >= $periodStart && $context->periodIndex <= $periodEnd;
```

**Register all three** in ConstraintRegistry + seed ConstraintTypes.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/`
2. Run: `/test SmartTimetable`
3. If migration was added: `php artisan tenants:migrate` on test tenant
4. Update AI Brain:
   - `progress.md` → Phase 15 Part 1 done
   - `known-issues.md` → Category H gap reduced from 21 to 12 rules
   - `decisions.md` → Add decision about activity group infrastructure pattern
