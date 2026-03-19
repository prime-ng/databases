# P10 — Teacher Constraints (Category B)

**Phase:** 12 | **Priority:** P1 | **Effort:** 5 days
**Skill:** Backend + Schema | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P09 (Phase 11 — Constraint Architecture must be done)
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category B

---

## Pre-Requisites

Read these files before starting:
1. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — Category B section
2. `Modules/SmartTimetable/app/Services/Constraints/ConstraintRegistry.php` — built in P09
3. `Modules/SmartTimetable/app/Services/Constraints/ConstraintContext.php` — built in P09
4. `Modules/SmartTimetable/app/Services/Constraints/Hard/GenericHardConstraint.php` — base class
5. `Modules/SmartTimetable/app/Services/Constraints/Soft/GenericSoftConstraint.php` — base class
6. `Modules/SmartTimetable/app/Models/Activity.php` — teacher_ids field
7. Check `tt_teacher_availability` table structure for how teacher availability is stored

---

## Task 12.1 — Simple teacher constraints (1 day)

Create 5 constraint classes in `Modules/SmartTimetable/app/Services/Constraints/`:

### 12.1.1 — TeacherNoConsecutiveDaysConstraint (B1.8)

**File:** `Soft/TeacherNoConsecutiveDaysConstraint.php`
```php
<?php

namespace Modules\SmartTimetable\Services\Constraints\Soft;

use Modules\SmartTimetable\Services\Constraints\ConstraintContext;

class TeacherNoConsecutiveDaysConstraint extends GenericSoftConstraint
{
    public function isRelevant(ConstraintContext $context): bool
    {
        // Relevant if this constraint targets one of the activity's teachers
        $targetTeacherId = $this->constraintModel->target_id ?? null;
        return $targetTeacherId && in_array($targetTeacherId, $context->teacherIds);
    }

    public function passes(ConstraintContext $context): bool
    {
        $targetTeacherId = $this->constraintModel->target_id;
        $currentDayId = $context->dayId;

        // Get adjacent day IDs (previous and next)
        $adjacentDays = $this->getAdjacentDayIds($currentDayId);

        // Check if teacher has placements on adjacent days
        $solution = $context->get('solution');
        if (!$solution) return true;

        foreach ($adjacentDays as $adjDayId) {
            if ($solution->hasTeacherOnDay($targetTeacherId, $adjDayId)) {
                return false; // Teacher already works on adjacent day
            }
        }

        return true;
    }

    protected function getAdjacentDayIds(int $dayId): array
    {
        // This needs day ordering from context; use day_number or similar
        return [$dayId - 1, $dayId + 1]; // Simplified — adjust based on actual day model
    }
}
```

### 12.1.2 — TeacherMaxGapsPerDayConstraint (B1.9)

**File:** `Soft/TeacherMaxGapsPerDayConstraint.php`
- Count free periods between first and last teaching period for a teacher on the given day
- `$params = json_decode($this->constraintModel->params_json, true)`
- `$maxGaps = $params['max_gaps'] ?? 2`
- Pass if gap count <= maxGaps

### 12.1.3 — TeacherMaxGapsPerWeekConstraint (B1.10)

**File:** `Soft/TeacherMaxGapsPerWeekConstraint.php`
- Sum of daily gaps across all days for the teacher
- `$maxGapsWeek = $params['max_gaps_week'] ?? 10`

### 12.1.4 — TeacherMaxSpanPerDayConstraint (B1.12)

**File:** `Soft/TeacherMaxSpanPerDayConstraint.php`
- Span = last teaching period index - first teaching period index
- `$maxSpan = $params['max_span'] ?? 8`

### 12.1.5 — TeacherPreferredFreeDayConstraint (B1.21)

**File:** `Soft/TeacherPreferredFreeDayConstraint.php`
- Check if placing on this day would violate the teacher's preferred free day
- `$preferredDay = $params['day'] ?? null`
- If current day matches preferred free day, return false (soft penalty)

**Pattern for ALL simple teacher constraints:**
1. Extend `GenericSoftConstraint`
2. `isRelevant()` checks if `target_id` matches one of `$context->teacherIds`
3. `passes()` implements the rule logic using `$context` and solution state
4. Params are read from `$this->constraintModel->params_json`

---

## Task 12.2 — Study-format-aware teacher constraints (2 days)

These need study format resolution from `Activity → SubjectStudyFormat`:

### 12.2.1 — TeacherMaxConsecutiveStudyFormatConstraint (B1.15)

**File:** `Soft/TeacherMaxConsecutiveStudyFormatConstraint.php`
- `$params: study_format_id, max_consecutive`
- Check consecutive periods of the specified study format for the teacher
- Need to resolve activity's study format: `$activity->subjectStudyFormat->study_format_id`

### 12.2.2 — TeacherDailyStudyFormatConstraint (B1.16)

**File:** `Soft/TeacherDailyStudyFormatConstraint.php`
- `$params: study_format_id, min_periods, max_periods`
- Count periods of this study format for the teacher on the given day

### 12.2.3 — TeacherMaxStudyFormatsConstraint (B1.17)

**File:** `Soft/TeacherMaxStudyFormatsConstraint.php`
- `$params: study_format_ids[], max_count`
- Count distinct study formats from the set used by the teacher on the day

### 12.2.4 — TeacherStudyFormatGapConstraint (B1.18)

**File:** `Soft/TeacherStudyFormatGapConstraint.php`
- `$params: study_format_a_id, study_format_b_id, min_gap`
- If teacher has format A at period X and format B at period Y, ensure |X - Y| >= min_gap
- **HIGH complexity** — needs to check all placed activities for both formats

**Study format resolution helper** (add to base class or context):
```php
protected function getStudyFormatId($activity): ?int
{
    return $activity->subjectStudyFormat->study_format_id
        ?? $activity->study_format_id
        ?? null;
}
```

---

## Task 12.3 — Interval/time-window teacher constraints (1.5 days)

### 12.3.1 — TeacherGapsInSlotRangeConstraint (B1.11)

**File:** `Soft/TeacherGapsInSlotRangeConstraint.php`
- `$params: time_slot_start, time_slot_end, max_single_gaps`
- Count single-period gaps within the specified period range

### 12.3.2 — TeacherMutuallyExclusiveSlotsConstraint (B1.13)

**File:** `Soft/TeacherMutuallyExclusiveSlotsConstraint.php`
- `$params: slot_a {day, period}, slot_b {day, period}`
- If placing in slot_a, check teacher isn't already in slot_b (and vice versa)

### 12.3.3 — TeacherMaxHoursInIntervalConstraint (B1.14)

**File:** `Soft/TeacherMaxHoursInIntervalConstraint.php`
- `$params: interval_start, interval_end, max_periods`
- Count teacher's periods within the hour range on this day

### 12.3.4 — TeacherMaxDaysInIntervalConstraint (B1.19)

**File:** `Soft/TeacherMaxDaysInIntervalConstraint.php`
- `$params: interval_start, interval_end, max_days`
- Count how many days the teacher teaches within this period range across the week

### 12.3.5 — TeacherMinRestingHoursConstraint (B1.20)

**File:** `Soft/TeacherMinRestingHoursConstraint.php`
- `$params: min_rest_hours`
- Calculate time between last period of previous day and first period of this day
- **HIGH complexity** — needs period-to-clock-time mapping

### 12.3.6 — TeacherFreePeriodEachHalfConstraint (B1.22)

**File:** `Soft/TeacherFreePeriodEachHalfConstraint.php`
- `$params: first_half_end (period index), second_half_start (period index)`
- Teacher must have at least 1 free period in each half of the day
- **School Requirement #5**

---

## Task 12.4 — Global-teacher variants B2 (0.5 day)

For each B1.x constraint class created above:
- Same PHP class is used
- `isRelevant()` returns `true` for ALL teachers when:
  - `$this->constraintModel->target_id` is null (global scope)
  - OR constraint scope is GLOBAL
- Individual teacher overrides take precedence (checked by ConstraintManager: lower priority number wins)

**Implementation:** In each constraint's `isRelevant()`:
```php
public function isRelevant(ConstraintContext $context): bool
{
    $targetTeacherId = $this->constraintModel->target_id ?? null;

    // Global scope — applies to all teachers
    if (!$targetTeacherId) {
        return !empty($context->teacherIds);
    }

    // Individual scope — only for this teacher
    return in_array($targetTeacherId, $context->teacherIds);
}
```

---

## Task 12.5 — Register + seed types (2 hrs)

### 12.5.1 — Register in ConstraintRegistry

In `SmartTimetableServiceProvider::boot()`, add:
```php
ConstraintRegistry::registerMany([
    // ... existing entries ...
    'TEACHER_NO_CONSECUTIVE_DAYS' => Soft\TeacherNoConsecutiveDaysConstraint::class,
    'TEACHER_MAX_GAPS_PER_DAY' => Soft\TeacherMaxGapsPerDayConstraint::class,
    'TEACHER_MAX_GAPS_PER_WEEK' => Soft\TeacherMaxGapsPerWeekConstraint::class,
    'TEACHER_MAX_SPAN_PER_DAY' => Soft\TeacherMaxSpanPerDayConstraint::class,
    'TEACHER_PREFERRED_FREE_DAY' => Soft\TeacherPreferredFreeDayConstraint::class,
    // ... study format aware ...
    'TEACHER_MAX_CONSECUTIVE_STUDY_FORMAT' => Soft\TeacherMaxConsecutiveStudyFormatConstraint::class,
    'TEACHER_DAILY_STUDY_FORMAT' => Soft\TeacherDailyStudyFormatConstraint::class,
    'TEACHER_MAX_STUDY_FORMATS' => Soft\TeacherMaxStudyFormatsConstraint::class,
    'TEACHER_STUDY_FORMAT_GAP' => Soft\TeacherStudyFormatGapConstraint::class,
    // ... interval ...
    'TEACHER_GAPS_IN_SLOT_RANGE' => Soft\TeacherGapsInSlotRangeConstraint::class,
    'TEACHER_MUTUALLY_EXCLUSIVE_SLOTS' => Soft\TeacherMutuallyExclusiveSlotsConstraint::class,
    'TEACHER_MAX_HOURS_IN_INTERVAL' => Soft\TeacherMaxHoursInIntervalConstraint::class,
    'TEACHER_MAX_DAYS_IN_INTERVAL' => Soft\TeacherMaxDaysInIntervalConstraint::class,
    'TEACHER_MIN_RESTING_HOURS' => Soft\TeacherMinRestingHoursConstraint::class,
    'TEACHER_FREE_PERIOD_EACH_HALF' => Soft\TeacherFreePeriodEachHalfConstraint::class,
]);
```

### 12.5.2 — Seed ConstraintType records

Update `ConstraintTypeSeeder` — add entries for any B1 types not already seeded:
```php
// For each new constraint type:
ConstraintType::firstOrCreate(
    ['code' => 'TEACHER_NO_CONSECUTIVE_DAYS'],
    [
        'name' => 'Teacher No Two Consecutive Days',
        'description' => 'Teacher does not work on two consecutive days',
        'category_id' => $teacherCategory->id,
        'scope_id' => $individualScope->id,
        'is_hard_constraint' => false,
        'param_schema' => json_encode(['value' => ['type' => 'boolean']]),
        'is_active' => true,
        'created_by' => 1,
    ]
);
```

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/Constraints/Soft/`
2. Run: `/test SmartTimetable`
3. Count new constraint classes: `ls Modules/SmartTimetable/app/Services/Constraints/Soft/Teacher*.php | wc -l` — should be 15
4. Verify registration: `php artisan tinker --execute="dd(array_keys(Modules\SmartTimetable\Services\Constraints\ConstraintRegistry::all()));"` — should list all teacher constraint codes
5. Update AI Brain:
   - `progress.md` → Phase 12 done, 35 teacher constraint rules implemented
   - `known-issues.md` → Update Category B gap from "15 rules unimplemented" to "RESOLVED"
