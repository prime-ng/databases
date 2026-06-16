# P19 — Global Policy (Cat G) + DB Constraint PHP Classes (Cat F)

**Phase:** 16 + 17 | **Priority:** P2 | **Effort:** 6 days
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P09 (Phase 11 — Constraint Architecture)
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Categories G and F

---

## Pre-Requisites

Read before starting:
1. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — Categories F and G
2. `Modules/SmartTimetable/app/Services/Constraints/ConstraintFactory.php` — current CONSTRAINT_CLASS_MAP
3. `Modules/SmartTimetable/database/seeders/ConstraintTypeSeeder.php` — currently seeded types

---

## Part A: Phase 16 — Global Policy Constraints (3 days)

### Task 16.1 — Remaining global constraints G5-G9 (1.5 days)

| Rule | File | Complexity |
|------|------|-----------|
| G5 Max teaching days per week | `Soft/GlobalMaxTeachingDaysConstraint.php` | LOW — Count distinct days with teaching |
| G6 Fixed period (assembly/prayer) | `Hard/GlobalFixedPeriodConstraint.php` | LOW — Block specific periods for specific activities |
| G7 Holiday/no classes dates | `Hard/GlobalHolidayConstraint.php` | LOW — Block entire days |
| G8 Balanced distribution | `Soft/GlobalBalancedDistributionConstraint.php` | MED — Penalize uneven subject spread |
| G9 Prefer morning for core | `Soft/GlobalPreferMorningConstraint.php` | LOW — Score bonus for core subjects in morning |

Each class: extend GenericHardConstraint or GenericSoftConstraint, implement `isRelevant()` (always true for global), `passes()` with rule logic.

### Task 16.2 — Activity-level fields expansion in FETSolver (1.5 days)

**File:** `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
**Method:** `scoreSlotForActivity()`

Phase 3 (P05) covers 7 of 22 activity fields. Add scoring for remaining 15 fields:

```php
// In scoreSlotForActivity(), after P05 additions:

// avoid_time_slots_json (-50 exact match)
if ($activity->avoid_time_slots_json) {
    $avoidSlots = json_decode($activity->avoid_time_slots_json, true) ?? [];
    foreach ($avoidSlots as $slot) {
        if (($slot['day_id'] ?? null) == $dayId && ($slot['period_index'] ?? null) == $periodIndex) {
            $score -= 50;
        }
    }
}

// preferred_time_slots_json (+40 exact match)
if ($activity->preferred_time_slots_json) {
    $prefSlots = json_decode($activity->preferred_time_slots_json, true) ?? [];
    foreach ($prefSlots as $slot) {
        if (($slot['day_id'] ?? null) == $dayId && ($slot['period_index'] ?? null) == $periodIndex) {
            $score += 40;
        }
    }
}

// min_per_day — penalize if below minimum when day is used
if ($activity->min_per_day) {
    $currentOnDay = $this->solution->countActivityOnDay($activity, $dayId);
    if ($currentOnDay > 0 && $currentOnDay < $activity->min_per_day) {
        $score += 15; // Encourage placing more on this day to meet minimum
    }
}

// split_allowed — if false, enforce all weekly periods on same day
if ($activity->split_allowed === false) {
    $existingDays = $this->solution->getDaysUsedByActivity($activity);
    if (!empty($existingDays) && !in_array($dayId, $existingDays)) {
        $score -= 100; // Strong penalty for splitting
    }
}

// is_compulsory — used in rescue pass (never skip)
// Already handled in ordering/rescue logic
```

---

## Part B: Phase 17 — DB Constraint PHP Classes (3 days)

### Task 17.1 — Teacher DB constraint PHP classes (1 day)

Create PHP classes for seeded types F1-F7 that currently fall through to GenericHardConstraint/GenericSoftConstraint:

| Seeded Code | PHP Class | Notes |
|------------|-----------|-------|
| TEACHER_MAX_DAILY (F1) | `Hard/TeacherMaxDailyConstraint.php` | May overlap with B1.2 — check |
| TEACHER_MAX_WEEKLY (F2) | `Hard/TeacherMaxWeeklyConstraint.php` | May overlap with B1.4 |
| TEACHER_MAX_CONSECUTIVE (F3) | `Soft/TeacherMaxConsecutiveDBConstraint.php` | May overlap with B1.7 |
| TEACHER_NO_CONSECUTIVE (F4) | `Soft/TeacherNoConsecutiveDBConstraint.php` | Different from B1.8 |
| TEACHER_UNAVAILABLE_PERIODS (F5) | `Hard/TeacherUnavailablePeriodsConstraint.php` | May overlap with B1.1 |
| TEACHER_PREFERRED_FREE_DAY (F6) | `Soft/TeacherPreferredFreeDayDBConstraint.php` | May overlap with B1.21 |
| TEACHER_MIN_DAILY (F7) | `Soft/TeacherMinDailyConstraint.php` | May overlap with B1.3 |

**IMPORTANT:** Check for overlap with P10 (Teacher Constraints). If a B1.x class already handles the same logic, point the F code to the same class via ConstraintRegistry alias instead of creating a new one.

### Task 17.2 — Class DB constraint PHP classes (0.5 day)

| Seeded Code | PHP Class |
|------------|-----------|
| CLASS_MAX_PER_DAY (F8) | `Hard/ClassMaxPerDayConstraint.php` |
| CLASS_WEEKLY_PERIODS (F9) | `Hard/ClassWeeklyPeriodsConstraint.php` |
| CLASS_NOT_FIRST_PERIOD (F10) | `Soft/ClassNotFirstPeriodConstraint.php` |
| CLASS_NOT_LAST_PERIOD (F11) | `Soft/ClassNotLastPeriodConstraint.php` |
| CLASS_CONSECUTIVE_REQUIRED (F12) | `Hard/ClassConsecutiveRequiredConstraint.php` |
| CLASS_MIN_GAP (F13) | `Soft/ClassMinGapConstraint.php` |

### Task 17.3 — Room + Activity + Global DB constraint PHP classes (1 day)

| Seeded Code | PHP Class | Notes |
|------------|-----------|-------|
| ROOM_UNAVAILABLE (F14) | Already exists as ROOM_AVAILABILITY | Alias in Registry |
| ROOM_MAX_USAGE_PER_DAY (F15) | `Hard/RoomMaxUsageConstraint.php` | May exist from P18 |
| ROOM_EXCLUSIVE_USE (F16) | `Hard/RoomExclusiveUseConstraint.php` | New |
| ACTIVITY_EXAM_ONLY_PERIODS (F17) | `Hard/ExamOnlyPeriodsConstraint.php` | New |
| ACTIVITY_NO_TEACHING_AFTER_EXAM (F18) | `Hard/NoTeachingAfterExamConstraint.php` | New |
| ACTIVITY_EXAM_CUTOFF_TIME (F19) | `Hard/ExamCutoffTimeConstraint.php` | New |
| GLOBAL_FIXED_PERIOD (F20) | Already exists as FIXED_PERIOD_HIGH_PRIORITY | Alias |
| GLOBAL_NO_CLASSES_ON_DATE (F21) | `Hard/GlobalHolidayConstraint.php` | From Task 16.1 |
| GLOBAL_MAX_TEACHING_DAYS (F22) | `Soft/GlobalMaxTeachingDaysConstraint.php` | From Task 16.1 |
| OPT_PREFER_MORNING (F23) | Already exists as PREFERRED_TIME_OF_DAY | Alias |
| OPT_PREFER_SAME_ROOM (F24) | `Soft/PreferSameRoomConstraint.php` | New |
| OPT_BALANCED_DISTRIBUTION (F25) | Already exists as BALANCED_DAILY_SCHEDULE | Alias |

### Task 17.4 — Reconcile CONSTRAINT_CLASS_MAP duplicates (0.5 day)

Some seeded codes map to existing classes under different names. In ConstraintRegistry, register aliases:

```php
// Aliases — multiple codes pointing to same class
ConstraintRegistry::register('ROOM_UNAVAILABLE', Hard\RoomAvailabilityConstraint::class);
ConstraintRegistry::register('GLOBAL_FIXED_PERIOD', Hard\FixedPeriodForHighPriorityConstraint::class);
ConstraintRegistry::register('OPT_PREFER_MORNING', Soft\PreferredTimeOfDayConstraint::class);
ConstraintRegistry::register('OPT_BALANCED_DISTRIBUTION', Soft\BalancedDailyScheduleConstraint::class);
```

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/Constraints/`
2. Run: `/test SmartTimetable`
3. Verify all 25 seeded types now have PHP classes or aliases: `php artisan tinker` → check ConstraintRegistry covers all F codes
4. Update AI Brain:
   - `progress.md` → Phases 16+17 done
   - `known-issues.md` → Category F, G gaps RESOLVED
