# Business Requirements Document (BRD)
## Module: Smart Timetable
### Feature 03: Constraint Engine & Availability (Deep Technical)

---

## 1. Executive Summary
The AI Timetable Generator relies entirely on the `ConstraintManager`. Constraints are divided into "Hard" constraints (mathematically impossible to break without invalidating the timetable) and "Soft" constraints (preferences that the engine attempts to optimize but can break if necessary).

## 2. Core Components
- `TimetableGenerationController.php`
- `ConstraintManager.php`
- Hard Constraints Namespace: `Modules\SmartTimetable\Services\Constraints\Hard\`
- Soft Constraints Namespace: `Modules\SmartTimetable\Services\Constraints\Soft\`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Hard Constraints
Hard constraints cause the algorithm to instantly reject a permutation and backtrack.
1. **`TeacherConflictConstraint`**: A teacher cannot be scheduled to teach two different classes at the exact same Day and Period.
2. **`RoomAvailabilityConstraint`**: A room (e.g., Computer Lab) cannot host two different activities at the same time.
3. **`MaximumDailyLoadConstraint`**: Prevents a specific class or teacher from having more than a specified maximum periods per day (e.g., max 6 periods).
4. **`NoSameSubjectSameDayConstraint`**: Ensures Class 10 doesn't get 3 Math periods on Monday and 0 for the rest of the week. Distributes the subject across unique days.
5. **`FixedPeriodForHighPriorityConstraint`**: Forces high-priority subjects (like Mathematics) to be scheduled in the morning (e.g., Periods 1 to 4) when student retention is highest.
6. **`ShortBreakConstraint` & `LunchBreakConstraint`**: Explicitly reserves the Recess and Lunch periods based on the master `tt_period_configs`, ensuring no activity is scheduled during this time.

### FR-02: Soft Constraints
The engine calculates a "fitness score" based on how many soft constraints are satisfied.
1. **`PreferredTimeOfDayConstraint`**: Matches subject types to preferred times (e.g., Physical Education is preferred in the afternoon/post-lunch, not Period 1).
2. **`BalancedDailyScheduleConstraint`**: Tries to ensure a mix of heavy subjects (Math/Physics) and light subjects (Art/PE) in a single day.
3. **`ConsecutiveLabPeriodsConstraint`**: If Physics Lab requires 2 periods, the algorithm attempts to schedule them back-to-back (e.g., Period 3 and 4) rather than split them.
4. **`CompactScheduleConstraint`**: Avoids gaps in a teacher's schedule. If a teacher has Period 1 and Period 5, but is free in 2, 3, and 4, the engine penalizes this permutation to avoid keeping the teacher idle.

### FR-03: Dynamic DB Constraints (`DatabaseConstraintService`)
- The controller uses `createConstraintManagerFromDatabase()` to dynamically load constraints from the `tt_constraints` table.
- A constraint record defines its `type`, `parameters` (as JSON), and the boolean `is_hard`. It automatically resolves to the correct PHP Class using `resolveConstraintClass()`.

---

## 4. Acceptance Criteria
- **Given** the database defines a Hard Constraint `MaximumDailyLoadConstraint` set to 2 for Science, **When** the `PrimeSolver` generates the grid, **Then** it must guarantee that no class has 3 Science periods on a single day. If mathematically impossible to satisfy, the generator must fail and alert the admin.
