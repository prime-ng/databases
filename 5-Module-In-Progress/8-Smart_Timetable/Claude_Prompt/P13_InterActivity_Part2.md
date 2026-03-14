# P13 — Inter-Activity Constraints Part 2 (H9-H19)

**Phase:** 15 (Tasks 15.6–15.8) | **Priority:** P1 | **Effort:** 3 days
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P12 (Phase 15 Part 1 — group infrastructure)

---

## Pre-Requisites

Read before starting:
1. P12 output — verify activity group infrastructure is working
2. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — Category H (H9-H19)

---

## Task 15.6 — Gap and scheduling relationship rules H9-H16 (1.5 days)

**Mostly soft scoring constraints.**

### H9 — Min Days Between Activities

**File:** `Soft/MinDaysBetweenConstraint.php`
- `$params: min_days (int)`
- Check calendar distance between placed instances of activities in the group
- If activity A is on day 1 and B is on day 3, gap = 2 days

### H10 — Max Days Between Activities

**File:** `Soft/MaxDaysBetweenConstraint.php`
- Inverse of H9 — penalize if gap exceeds max_days

### H11 — End Students Day

**File:** `Soft/EndStudentsDayConstraint.php`
- Soft bonus for placing the activity in the last teaching period
- `$score += 30` if this is the last period, `$score -= 20` otherwise

### H12-H15 — Occupy Min/Max Slots from Selection

**Files:**
- `Soft/OccupyMinSlotsConstraint.php` (H12)
- `Soft/OccupyMaxSlotsConstraint.php` (H13)
- `Hard/OccupyExactSlotsConstraint.php` (H14)
- `Soft/PreferredSlotSelectionConstraint.php` (H15)

- `$params: slot_selection[] (array of {day_id, period_index}), min_count/max_count`
- Count how many slots from the selection set are occupied by the activity group

### H16 — Min Gaps Between Activity Set

**File:** `Soft/MinGapsBetweenSetConstraint.php`
- `$params: min_gap (int)`
- For all pairs of activities in the set, ensure period gap >= min_gap on same day

---

## Task 15.7 — Room-related inter-activity rules H17-H18 (0.5 day)

**These are post-generation evaluation rules** (room is allocated after placement):

### H17 — Same Room if Consecutive

**File:** `Soft/SameRoomIfConsecutiveConstraint.php`
- Applied in RoomAllocationPass, not FETSolver
- If two activities from the same group are consecutive, prefer same room
- Implementation: scoring preference in `RoomAllocationPass::findBestRoom()`

### H18 — Max Different Rooms for Activity Set

**File:** `Soft/MaxDifferentRoomsConstraint.php`
- Post-gen violation check
- Count distinct rooms used by activities in the set
- Report as violation if exceeds max_rooms

---

## Task 15.8 — School-specific inter-activity rule H19 (0.5 day)

### H19 — Non-Concurrent Minor Subjects — School Req #6

**File:** `Soft/NonConcurrentMinorSubjectsConstraint.php`

**Rule:** Games, Library, Art, Hobby, Dance, Music should NOT be scheduled on the same day for a class.

```php
public function passes(ConstraintContext $context): bool
{
    $params = json_decode($this->constraintModel->params_json, true);
    $minorSubjectIds = $params['minor_subject_ids'] ?? [];

    if (!in_array($context->subjectId, $minorSubjectIds)) {
        return true; // Not a minor subject
    }

    // Check if another minor subject is already placed on this day for this class
    $solution = $context->get('solution');
    if (!$solution) return true;

    $placedOnDay = $solution->getPlacementsForDayAndClass($context->dayId, $context->classKey);

    foreach ($placedOnDay as $placed) {
        if (in_array($placed->subject_id, $minorSubjectIds) && $placed->subject_id !== $context->subjectId) {
            return false; // Another minor subject already on this day
        }
    }

    return true;
}
```

**Register all** in ConstraintRegistry + seed ConstraintTypes.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/Constraints/`
2. Run: `/test SmartTimetable`
3. Update AI Brain:
   - `progress.md` → Phase 15 fully done, 21 inter-activity rules implemented
   - `known-issues.md` → Category H gap fully RESOLVED (except H8 already done)
