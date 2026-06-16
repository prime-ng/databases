# P20 — Testing (Pest 4.x)

**Phase:** 18 | **Priority:** P3 | **Effort:** 5 days
**Skill:** Testing | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P10–P13, P19 (constraint phases should be done first)

---

## Pre-Requisites

Read before starting:
1. `AI_Brain/rules/testing.md` — Pest 4.x rules, no PHPUnit classes
2. Existing tests: `tests/Unit/SmartTimetable/` — 3 files, 9 tests, use as pattern reference
3. `Modules/SmartTimetable/app/Services/Generator/FETSolver.php`
4. `Modules/SmartTimetable/app/Services/Constraints/ConstraintManager.php`
5. `Modules/SmartTimetable/app/Services/Constraints/ConstraintEvaluator.php` (built in P09)

---

## Task 18.1 — Unit tests for FETSolver (2 days)

**File:** `tests/Unit/SmartTimetable/FETSolverTest.php`

Write Pest tests using `it()` or `test()` syntax:

```php
<?php

use Modules\SmartTimetable\Services\Generator\FETSolver;
// ... imports

it('scores preferred periods with positive bonus', function () {
    // Create mock activity with preferred_periods_json
    // Call scoreSlotForActivity()
    // Assert score includes +40 for exact match
});

it('penalizes avoid periods with negative score', function () {
    // Create mock activity with avoid_periods_json
    // Call scoreSlotForActivity()
    // Assert score includes -50 for exact match
});

it('correctly identifies consecutive violation for different instances', function () {
    // Place activity A (subject=Math, class=5A) at day1_period2
    // Check violatesNoConsecutiveRule for same subject+class at day1_period3
    // Should return true (violation)
});

it('allows consecutive for activities with allow_consecutive=true', function () {
    // Activity with allow_consecutive=true (lab)
    // Should not be blocked by consecutive rule
});

it('respects per-activity max_per_day cap', function () {
    // Activity with max_per_day=1, already placed once today
    // Second placement on same day should be blocked
});

it('enforces min_gap_periods between same subject instances', function () {
    // Activity with min_gap_periods=2
    // Place instance at period 1
    // Period 2 should violate (gap=0), period 4 should pass (gap=2)
});

it('orders activities by difficulty correctly', function () {
    // Parallel group members should be boosted
    // Higher constraint_count should rank higher
});

it('spreads activities across unused days', function () {
    // Score should be higher for unused days (+10)
    // Score should be lower for already-used days (-15)
});
```

---

## Task 18.2 — Unit tests for ConstraintManager + ConstraintEvaluator (1.5 days)

**File:** `tests/Unit/SmartTimetable/ConstraintEvaluatorTest.php`

```php
it('returns true when all hard constraints pass', function () {
    // Create ConstraintEvaluator with passing constraints
    // checkHard() returns true
});

it('returns false on first failing hard constraint (fail-fast)', function () {
    // Create ConstraintEvaluator with one failing constraint
    // checkHard() returns false
});

it('scores soft constraints as sum of weights', function () {
    // Two soft constraints with weight 30 and 20
    // Both pass → score = 50
});

it('handles constraint evaluation errors gracefully', function () {
    // Soft constraint that throws exception
    // Should log warning, not crash, return partial score
});

it('respects priority ordering in evaluation', function () {
    // High-priority constraint checked first
    // Verify through evaluation order tracking
});

it('evaluates MUTEX groups correctly (at most one passes)', function () {
    // Create group with 3 constraints, 2 pass → should fail
});

it('evaluates CONCURRENT groups correctly (all must pass)', function () {
    // Create group with 3 constraints, 1 fails → should fail
});

it('builds ConstraintContext correctly from activity and slot', function () {
    // ConstraintContext::fromActivityAndSlot()
    // Verify all fields populated correctly
});
```

---

## Task 18.3 — Unit tests for new constraint PHP classes (1 day)

**File:** `tests/Unit/SmartTimetable/ConstraintClassesTest.php`

For each category (B, C, E, H), write at least 2 representative tests:

```php
// Teacher constraints
it('teacher max gaps per day constraint passes within limit', function () {
    // Teacher has 1 gap, max_gaps=2 → passes
});

it('teacher max gaps per day constraint fails over limit', function () {
    // Teacher has 3 gaps, max_gaps=2 → fails
});

// Class constraints
it('class max minor subjects per day constraint passes', function () {
    // 1 minor subject placed, max=2 → passes
});

it('class teacher first period constraint requires class teacher in period 0', function () {
    // Class teacher not in period 0 → fails
});

// Room constraints
it('room max usage per day constraint limits room periods', function () {
    // Room used 8 times, max_usage=8 → passes; 9th → fails
});

// Inter-activity constraints
it('same-time constraint enforces matching start period', function () {
    // Activity A at period 2, Activity B must also be at period 2
});

it('not-overlapping constraint prevents time overlap', function () {
    // Two activities in group cannot share same period on same day
});

it('day pinning constraint restricts to specific day', function () {
    // Activity fixed to Monday → passes for Monday, fails for Tuesday
});
```

**Pattern:** Always test `isRelevant()` returning false for non-applicable activities.

---

## Task 18.4 — Feature tests for key controllers (0.5 day)

**File:** `tests/Feature/SmartTimetable/` (or `Modules/SmartTimetable/tests/Feature/`)

**Note:** Feature tests need tenant context. Use `TenantTestCase` if available.

```php
it('returns 403 for unauthorized generation attempt', function () {
    // User without smart-timetable.timetable.generate permission
    // POST /smart-timetable/generate → 403
});

it('parallel group CRUD operations work with proper auth', function () {
    // Create, read, update, delete parallel group
    // Verify response status and database state
});

it('constraint management page loads with data', function () {
    // GET /smart-timetable/constraint-management → 200
    // Response contains constraint tabs
});
```

---

## Running Tests

```bash
# Run all SmartTimetable tests
./vendor/bin/pest tests/Unit/SmartTimetable/

# Run specific test file
./vendor/bin/pest tests/Unit/SmartTimetable/FETSolverTest.php

# Run with filter
./vendor/bin/pest --filter="teacher max gaps"
```

---

## Post-Execution Checklist

1. Run: `/test SmartTimetable` — ALL tests should pass
2. Count total tests: should be 30+ (9 existing + 20+ new)
3. Update AI Brain:
   - `progress.md` → Phase 18 done, Testing complete
