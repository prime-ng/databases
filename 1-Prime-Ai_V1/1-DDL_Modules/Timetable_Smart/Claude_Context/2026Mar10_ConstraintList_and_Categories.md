# Complete Constraint List — Categorized by Implementation & Input Method

**Date:** 2026-03-10
**Source:** `0-tt_Requirement_v3.md` (Requirements Document)
**Purpose:** Master list of all constraints extracted from requirements, categorized by how they are implemented in code and how user input is captured in the UI.

---

## Constraint Categories (By Implementation & Input Method)

| Cat ID | Category Code | Category Name | Implementation Approach | User Input Method |
|--------|---------------|---------------|------------------------|-------------------|
| A | `HARDCODED_ENGINE`     | Engine-Level Hard Rules | Hardcoded in FETSolver — always enforced, no DB record needed | No UI — system-enforced automatically |
| B | `TEACHER_AVAILABILITY` | Teacher Availability & Limits | Per-teacher configuration via Teacher Availability screen | Teacher Setup form — day/period picker, numeric inputs |
| C | `STUDENT_CLASS_RULES`  | Student/Class Time Rules | Per-class or per-student-set configuration | Class Setup form — day/period picker, numeric inputs |
| D | `ACTIVITY_LEVEL`       | Activity-Level Preferences | Stored on `tt_activities` table directly (22+ fields) | Activity creation/edit form — dropdowns, multi-select, toggles |
| E | `ROOM_SPACE`           | Room & Space Constraints | Room configuration + post-generation RoomAllocationPass | Room Setup form — availability picker, capacity fields |
| F | `DB_CONSTRAINT_RECORD` | DB-Driven Configurable Rules | Stored in `tt_constraint` table, loaded by ConstraintFactory, evaluated by ConstraintManager | Constraint Management UI — type selector, target picker, JSON params form |
| G | `GLOBAL_POLICY` | Global/Institution Policies | Global settings or `tt_constraint` with scope=GLOBAL | Settings/Config screen — simple toggles, numeric inputs |
| H | `INTER_ACTIVITY` | Inter-Activity Relationships | Activity Group relationships + solver logic | Activity Group setup — link activities, set relationship type |

---

## CATEGORY A: Engine-Level Hard Rules (Hardcoded in FETSolver)

These are **always enforced**, cannot be turned off, and require no user configuration. They are fundamental to a valid timetable.

| # | Constraint | Hard/Soft | Implementation Location | Req Reference |
|---|-----------|-----------|------------------------|---------------|
| A1 | **Teacher No Simultaneous Assignment** — One teacher cannot be assigned to more than one activity at the same time | HARD (100%) | `FETSolver::isBasicSlotAvailable()` — `isTeacherOccupied()` array check | Req: Basic Hard Constraint (i) |
| A2 | **Class No Simultaneous Assignment** — One class+section cannot have two activities at the same time | HARD (100%) | `FETSolver::isBasicSlotAvailable()` — `isClassOccupied()` array check | Req: Basic Hard Constraint (ii) |
| A3 | **Room No Simultaneous Assignment** — One room cannot host two activities at the same time | HARD (100%) | `RoomAllocationPass::findBestRoom()` — `$roomOccupied` tracking | Req: Basic Hard Constraint (Space-i) |
| A4 | **Activity Cannot Be in Break Time** — No activity may be placed in a break/interval slot | HARD (100%) | `FETSolver` — break period exclusion in slot generation | Req: Basic Hard Constraint (iii) |
| A5 | **Duration Must Fit** — Multi-period activities must have enough consecutive slots within the day | HARD (100%) | `FETSolver::isBasicSlotAvailable()` — duration boundary check | Implicit requirement |

---

## CATEGORY B: Teacher Availability & Limits

User input captured via **Teacher Setup / Teacher Availability** screens. These apply per-teacher or globally to all teachers.

### B1. Per-Teacher Constraints (Scope: INDIVIDUAL)

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| B1.1 | **Teacher Not Available Times** — Specific day+period slots where teacher cannot teach | HARD | `days[]`, `periods[]` — Day-Period grid picker | Req: Teacher (a) line 1 |
| B1.2 | **Teacher Max Daily Periods** — Maximum periods a teacher can teach per day | HARD/SOFT | `max_periods_per_day` (int 1-12) | Req: "Max & Minimum hours daily" |
| B1.3 | **Teacher Min Daily Periods** — Minimum periods a teacher should teach per day (if teaching that day) | SOFT | `min_periods_per_day` (int 0-12) | Req: "Min hours daily" |
| B1.4 | **Teacher Max Weekly Periods** — Maximum total periods per week | HARD/SOFT | `max_periods_per_week` (int 1-60) | Req: "Few teachers may have more than 36 periods in a week" |
| B1.5 | **Teacher Min Days Per Week** — Minimum working days per week | SOFT | `min_days` (int 1-7) | Req: "Min days per week" |
| B1.6 | **Teacher Max Days Per Week** — Maximum working days per week | HARD/SOFT | `max_days` (int 1-7) | Req: "Max days per week" |
| B1.7 | **Teacher Max Consecutive Periods** — Maximum continuous teaching periods without a break | SOFT | `max_consecutive` (int 1-8) | Req: "Max hours continuously" |
| B1.8 | **Teacher No Two Consecutive Days** — Teacher does not work 2 consecutive days | SOFT | `value` (boolean) | Req: "A teacher does not work 2 consecutive days" |
| B1.9 | **Teacher Max Gaps Per Day** — Maximum idle/free periods between first and last teaching period in a day | SOFT | `max_gaps` (int 0-6) | Req: "Max gaps per day" |
| B1.10 | **Teacher Max Gaps Per Week** — Maximum total gaps across all days | SOFT | `max_gaps_week` (int 0-30) | Req: "Max gaps per week" |
| B1.11 | **Teacher Max Single Gaps in Selected Slots** — Max single-period gaps in selected time ranges | SOFT | `time_slot_start`, `time_slot_end`, `max_single_gaps` | Req: "Max single gaps in selected time slots" |
| B1.12 | **Teacher Max Span Per Day** — Maximum time span (first to last period) per day | SOFT | `max_span` (int 1-12) | Req: "Max span per day" |
| B1.13 | **Teacher Mutually Exclusive Time Slots** — Two time slots that cannot both be assigned to the same teacher | SOFT | `slot_a: {day, period}`, `slot_b: {day, period}` | Req: "A pair of mutually exclusive time slots" |
| B1.14 | **Teacher Max Hours in Hourly Interval** — Max periods within a specific hourly window | SOFT | `interval_start`, `interval_end`, `max_periods` | Req: "Max hours daily in an hourly interval" |
| B1.15 | **Teacher Max Consecutive with Study Format** — Max continuous periods of a specific study format | SOFT | `study_format_id`, `max_consecutive` | Req: "Max hours continuously with a Study Format" |
| B1.16 | **Teacher Min/Max Daily with Study Format** — Min/Max periods of a specific study format per day | SOFT | `study_format_id`, `min_periods`, `max_periods` | Req: "Min & Max hours daily with a Study Format" |
| B1.17 | **Teacher Max Study Formats Per Day** — Max different study format types from a set per day | SOFT | `study_format_ids[]`, `max_count` | Req: "Max Study Format from a set per day" |
| B1.18 | **Teacher Min Gap Between Study Format Pair** — Minimum gap between an ordered pair of study formats | SOFT | `study_format_a_id`, `study_format_b_id`, `min_gap` | Req: "Min Gap between an ordered pair of Study Format" |
| B1.19 | **Teacher Max Days in Hourly Interval** — Max days per week working in a specific hourly interval | SOFT | `interval_start`, `interval_end`, `max_days` | Req: "Works in an hourly interval max days per week" |
| B1.20 | **Teacher Min Resting Hours** — Minimum rest hours between last period of one day and first of next | SOFT | `min_rest_hours` (int) | Req: "Min resting hours" |
| B1.21 | **Teacher Preferred Free Day** — Teacher prefers a specific day off | SOFT | `day` (enum MON-SUN) | Req: Implied by "Min days per week" |
| B1.22 | **Teacher Free Period in Each Half** — At least one free period in first half and one in second half | SOFT | `first_half_end` (period), `second_half_start` (period) | Req (School): #5 — "atleast one free period in first half and second half" |

### B2. All-Teachers Constraints (Scope: GLOBAL, applied to every teacher)

These have the **same parameters** as B1.1–B1.20 but apply globally. Implementation: single `tt_constraint` record with `scope=GLOBAL` + `target_type=TEACHER` (no specific `target_id`).

| # | Constraint | Note |
|---|-----------|------|
| B2.1–B2.20 | All-Teachers versions of B1.1–B1.20 | Same params; acts as default. Individual teacher overrides take precedence. |

---

## CATEGORY C: Student/Class Time Rules

User input captured via **Class/Section Setup** screens or **Student-Set Configuration**.

### C1. Per-Class/Section Constraints

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| C1.1 | **Class Not Available Times** — Day+period slots where no teaching for this class | HARD | `days[]`, `periods[]` — grid picker | Req: Student "Not available periods" |
| C1.2 | **Class Max Periods Per Day** — Maximum teaching periods per day for a class | HARD | `max_periods_per_day` (int) | Req: Student "Max hours daily" |
| C1.3 | **Class Max Days Per Week** — Maximum school days per week | HARD/SOFT | `max_days` (int 1-7) | Req: Student "Max days per week" |
| C1.4 | **Class Begins Early** — Max allowed late starts (beginnings at 2nd hour) | SOFT | `max_late_starts` (int) | Req: Student "Begins early" |
| C1.5 | **Class Max Gaps Per Day** — Maximum free-period gaps in a class's day | SOFT | `max_gaps` (int) | Req: Student "Max gaps per day" |
| C1.6 | **Class Max Gaps Per Week** — Maximum total gaps across the week | SOFT | `max_gaps_week` (int) | Req: Student "Max gaps per week" |
| C1.7 | **Class Max Hours Continuously** — Maximum consecutive teaching periods | SOFT | `max_consecutive` (int) | Req: Student "Max hours continuously" |
| C1.8 | **Class Max Span Per Day** — Maximum time span from first to last period | SOFT | `max_span` (int) | Req: Student "Max span per day" |
| C1.9 | **Class Min Hours Daily** — Minimum periods per day if school is in session | SOFT | `min_periods` (int) | Req: Student "Min hours daily" |
| C1.10 | **Class Max Hours with Study Format** — Max periods of a study format per day | SOFT | `study_format_id`, `max_periods` | Req: Student "Max hours daily with Study Format" |
| C1.11 | **Class Min Hours with Study Format** — Min periods of a study format per day | SOFT | `study_format_id`, `min_periods` | Req: Student "Min hours daily with Study Format" |
| C1.12 | **Class Max Consecutive with Study Format** — Max consecutive periods of a study format | SOFT | `study_format_id`, `max_consecutive` | Req: Student "Max hours continuously with Study Format" |
| C1.13 | **Class Min Gap Between Study Format Pair** — Min gap between ordered study format pair | SOFT | `study_format_a_id`, `study_format_b_id`, `min_gap` | Req: Student "Min gaps between an ordered pair of Study Format" |
| C1.14 | **Class Max Days in Hourly Interval** — Max days with teaching in a specific time range | SOFT | `interval_start`, `interval_end`, `max_days` | Req: Student "Working in an hourly interval max days per week" |
| C1.15 | **Class Min Resting Hours** — Min rest between last period of one day and first of next | SOFT | `min_rest_hours` (int) | Req: Student "Min resting hours" |
| C1.16 | **Class Max Minor Subjects Per Day** — Max minor/non-core subject periods per day | SOFT | `subject_type_ids[]`, `max_count` (default 2) | Req (School): #6 — "Maximum 2 minor periods in a day" |
| C1.17 | **Major Subjects Must Fall Every Day** — Core subjects scheduled daily | SOFT | `subject_ids[]` (list of major subjects) | Req (School): #4 — "Major Subjects should fall every day" |
| C1.18 | **Class Teacher First Period** — Class teacher gets first period | SOFT | `teacher_id`, `period` (1) | Req (School): #2 — "Class Teachers should be given first period" |

### C2. All-Students Constraints (Scope: GLOBAL)

Same as C1.1–C1.15 but applied globally as defaults for all classes. Individual class overrides take precedence.

---

## CATEGORY D: Activity-Level Preferences (Stored on `tt_activities`)

User input captured via **Activity Creation/Edit** form. These are stored directly on the Activity record, not in `tt_constraint` table.

| # | Constraint | Field(s) on `tt_activities` | UI Input Type | Req Reference |
|---|-----------|---------------------------|---------------|---------------|
| D1 | **Preferred Time Slots** — Activity prefers specific day+period combinations | `preferred_time_slots_json` | Day-Period multi-select grid | Req: "A set of preferred time slots" |
| D2 | **Avoid Time Slots** — Activity should avoid specific day+period combinations | `avoid_time_slots_json` | Day-Period multi-select grid | Req: "Not available periods" variant |
| D3 | **Preferred Periods** — Activity prefers specific period ordinals (any day) | `preferred_periods_json` | Period multi-select (1-12) | Req: "A set of preferred starting times" |
| D4 | **Avoid Periods** — Activity should avoid specific period ordinals | `avoid_periods_json` | Period multi-select | Req: Implied |
| D5 | **Max Per Day** — Maximum times this activity can appear per day | `max_per_day` | Integer input (1-8) | Req: Activity scheduling control |
| D6 | **Min Per Day** — Minimum times per day (if scheduled that day) | `min_per_day` | Integer input | Req: Implied |
| D7 | **Required Weekly Periods** — How many times per week this activity must occur | `required_weekly_periods` | Integer input | Req: Core activity requirement |
| D8 | **Min/Max Periods Per Week** — Bounds on weekly occurrences | `min_periods_per_week`, `max_periods_per_week` | Integer inputs | Req: Flexibility range |
| D9 | **Duration (Multi-Period)** — Activity spans multiple consecutive periods | `duration_periods` | Integer input (1-6) | Req: "Consecutive two periods for Hobby, Astro, Robotics, Practicals" |
| D10 | **Allow Consecutive** — Whether same activity can be placed in adjacent slots | `allow_consecutive` | Toggle (boolean) | Req: Activity scheduling |
| D11 | **Max Consecutive** — Maximum consecutive placements of same activity | `max_consecutive` | Integer input | Req: Consecutive control |
| D12 | **Min Gap Periods** — Minimum gap between two instances of same activity in a day | `min_gap_periods` | Integer input (0-5) | Req: "Min gaps between a set of activities" |
| D13 | **Spread Evenly** — Distribute activity evenly across the week | `spread_evenly` | Toggle (boolean) | Req: "Spread the activity evenly over the week" |
| D14 | **Priority** — Scheduling priority (higher = placed first) | `priority` | Integer input (1-100) | Req: Activity ordering |
| D15 | **Is Compulsory** — Must be scheduled (cannot be dropped) | `is_compulsory` | Toggle (boolean) | Req: Core subjects |
| D16 | **Split Allowed** — Whether weekly periods can be split across days | `split_allowed` | Toggle (boolean) | Req: Activity flexibility |
| D17 | **Required Room Type** — Must be in a specific room type | `required_room_type_id`, `compulsory_specific_room_type` | Room-type dropdown + toggle | Req (School): Resource Allocation — Labs |
| D18 | **Required Specific Room** — Must be in a specific room | `required_room_id` | Room dropdown | Req (School): Specific lab allocation |
| D19 | **Preferred Room Type** — Soft preference for room type | `preferred_room_type_id` | Room-type dropdown | Req: "A Study Format has a preferred room" |
| D20 | **Preferred Rooms** — Soft preference for specific room(s) | `preferred_room_ids` | Room multi-select | Req: "An Activity has a set of preferred rooms" |
| D21 | **Difficulty Score** — Pre-calculated scheduling difficulty | `difficulty_score`, `difficulty_score_calculated` | Auto-calculated (read-only) | Internal |
| D22 | **Constraint Count** — Number of constraints affecting this activity | `constraint_count` | Auto-calculated (read-only) | Internal |

---

## CATEGORY E: Room & Space Constraints

User input captured via **Room/Building Setup** screens and **Teacher/Student room preferences**.

### E1. Room Availability

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| E1.1 | **Room Not Available Times** — Specific day+period slots where room is unavailable | HARD | `days[]`, `periods[]` — grid picker | Req: "A room's not available Times" |
| E1.2 | **Room Capacity** — Activity's student count must not exceed room capacity | HARD | `capacity` (on `sch_rooms` table) | Req: "Activities with more students than room capacity" |
| E1.3 | **Room Exclusive Use** — Room cannot host overlapping activities | HARD | (built into RoomAllocationPass) | Req: Basic Hard Space Constraint |
| E1.4 | **Room Max Usage Per Day** — Maximum periods a room can be used per day | SOFT | `max_periods_per_day` (int) | Implied from room wear/availability |
| E1.5 | **Room Max Study Formats Per Day** — Max different study formats in a room per day | SOFT | `study_format_ids[]`, `max_count`, `period` (day/week) | Req: "Max Study Format from a set per day & per week for a room" |
| E1.6 | **Teacher+Room Not Available** — Specific teacher+room combination unavailable at times | SOFT | `teacher_id`, `room_id`, `days[]`, `periods[]` | Req: "A teacher + a room's not available times" |

### E2. Teacher Room Preferences (Per Teacher & All Teachers)

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| E2.1 | **Teacher Home Room** — Teacher has a preferred/assigned home room | SOFT | `room_id` | Req: "A teacher has a home room" |
| E2.2 | **Teacher Set of Home Rooms** — Teacher has multiple acceptable rooms | SOFT | `room_ids[]` | Req: "A teacher has a set of home rooms" |
| E2.3 | **Teacher Max Room Changes Per Day** — Limit room switches in a day | SOFT | `max_changes` (int) | Req: "Max room changes per day for a teacher" |
| E2.4 | **Teacher Max Room Changes Per Week** — Limit total room switches per week | SOFT | `max_changes_week` (int) | Req: "Max room changes per week for a teacher" |
| E2.5 | **Teacher Max Room Changes in Interval** — Max room changes in a specific hourly interval | SOFT | `interval_start`, `interval_end`, `max_changes` | Req: "Max room changes per day in an hourly interval" |
| E2.6 | **Teacher Min Gaps Between Room Changes** — Min periods between consecutive room switches | SOFT | `min_gap` (int) | Req: "Min gaps between room changes for a teacher" |
| E2.7 | **Teacher Max Building Changes Per Day** — Limit building switches per day | SOFT | `max_changes` (int) | Req: "Max building changes per day for a teacher" |
| E2.8 | **Teacher Max Building Changes Per Week** — Limit building switches per week | SOFT | `max_changes_week` (int) | Req: "Max building changes per week for a teacher" |
| E2.9 | **Teacher Max Building Changes in Interval** — Max building changes in hourly interval | SOFT | `interval_start`, `interval_end`, `max_changes` | Req: "Max building changes in an hourly interval" |
| E2.10 | **Teacher Min Gaps Between Building Changes** — Min periods between building switches | SOFT | `min_gap` (int) | Req: "Min gaps between building changes for a teacher" |

### E3. Student Room Preferences (Per Student-Set & All Students)

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| E3.1 | **Students Home Room** — A student set (class+section) has a home room | SOFT | `room_id` | Req: "A set of students has a home room" |
| E3.2 | **Students Set of Home Rooms** — Multiple acceptable rooms | SOFT | `room_ids[]` | Req: "A set of students has a set of home rooms" |
| E3.3 | **Students Max Room Changes Per Day** | SOFT | `max_changes` (int) | Req: "Max room changes per day for a students set" |
| E3.4 | **Students Max Room Changes Per Week** | SOFT | `max_changes_week` (int) | Req: "Max room changes per week" |
| E3.5 | **Students Max Room Changes in Interval** | SOFT | `interval_start`, `interval_end`, `max_changes` | Req: "Max room changes in hourly interval" |
| E3.6 | **Students Min Gaps Between Room Changes** | SOFT | `min_gap` (int) | Req: "Min gaps between room changes" |
| E3.7 | **Students Max Building Changes Per Day** | SOFT | `max_changes` (int) | Req: "Max building changes per day" |
| E3.8 | **Students Max Building Changes Per Week** | SOFT | `max_changes_week` (int) | Req: "Max building changes per week" |
| E3.9 | **Students Max Building Changes in Interval** | SOFT | `interval_start`, `interval_end`, `max_changes` | Req: "Max building changes in hourly interval" |
| E3.10 | **Students Min Gaps Between Building Changes** | SOFT | `min_gap` (int) | Req: "Min gaps between building changes" |

### E4. Subject/StudyFormat Room Preferences

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| E4.1 | **Subject Preferred Room** — A subject prefers a specific room | SOFT | `subject_id`, `room_id` | Req: "A Subject has a preferred room" |
| E4.2 | **Subject Preferred Room Set** — A subject has multiple preferred rooms | SOFT | `subject_id`, `room_ids[]` | Req: "A Subject has a set of preferred rooms" |
| E4.3 | **Study Format Preferred Room** — A study format prefers a specific room | SOFT | `study_format_id`, `room_id` | Req: "A Study Format has a preferred room" |
| E4.4 | **Study Format Preferred Room Set** — Multiple preferred rooms for study format | SOFT | `study_format_id`, `room_ids[]` | Req: "A Study Format has a set of preferred rooms" |
| E4.5 | **Subject+StudyFormat Preferred Room** — Specific combination prefers a room | SOFT | `subject_id`, `study_format_id`, `room_id` | Req: "A Subject + Study Format have a preferred room" |
| E4.6 | **Subject+StudyFormat Preferred Room Set** — Combination has multiple preferred rooms | SOFT | `subject_id`, `study_format_id`, `room_ids[]` | Req: "A Subject + Study Format has a set of preferred rooms" |

---

## CATEGORY F: DB-Driven Configurable Rules (via `tt_constraint` table)

These constraints are stored in the `tt_constraint` table, loaded by `DatabaseConstraintService`, instantiated by `ConstraintFactory`, and evaluated by `ConstraintManager` during generation. This is the **plug-and-play** category.

### Currently Seeded Constraint Types (38 in ConstraintTypeSeeder)

| # | Code | Name | Category | Level | Key Parameters |
|---|------|------|----------|-------|----------------|
| F1 | `TEACHER_MAX_DAILY` | Teacher Maximum Daily Periods | TEACHER | HARD | `max_periods_per_day` |
| F2 | `TEACHER_MAX_WEEKLY` | Teacher Maximum Weekly Periods | TEACHER | HARD/SOFT | `max_periods_per_week` |
| F3 | `TEACHER_MAX_CONSECUTIVE` | Teacher Max Consecutive Periods | TEACHER | SOFT | `max_consecutive` |
| F4 | `TEACHER_NO_CONSECUTIVE` | Teacher No Consecutive Periods | TEACHER | SOFT | `value` (bool) |
| F5 | `TEACHER_UNAVAILABLE_PERIODS` | Teacher Unavailable Periods | TEACHER | HARD | `days[]`, `periods[]` |
| F6 | `TEACHER_PREFERRED_FREE_DAY` | Teacher Preferred Free Day | TEACHER | SOFT | `day` (enum) |
| F7 | `TEACHER_MIN_DAILY` | Teacher Minimum Daily Periods | TEACHER | SOFT | `min_periods_per_day` |
| F8 | `CLASS_MAX_PER_DAY` | Class Maximum Periods Per Day | CLASS | HARD | `max_periods_per_day` |
| F9 | `CLASS_WEEKLY_PERIODS` | Class Weekly Period Target | CLASS | HARD | `value` (int) |
| F10 | `CLASS_NOT_FIRST_PERIOD` | Not Scheduled in First Period | CLASS | SOFT | `value` (bool) |
| F11 | `CLASS_NOT_LAST_PERIOD` | Not Scheduled in Last Period | CLASS | SOFT | `value` (bool) |
| F12 | `CLASS_CONSECUTIVE_REQUIRED` | Consecutive Periods Required | CLASS | HARD | `count` (int) |
| F13 | `CLASS_MIN_GAP` | Min Gap Between Same Subject | CLASS | SOFT | `value` (int) |
| F14 | `ROOM_UNAVAILABLE` | Room Unavailable | ROOM | HARD | `dates[]`, `periods[]` |
| F15 | `ROOM_MAX_USAGE_PER_DAY` | Room Max Usage Per Day | ROOM | SOFT | `value` (int) |
| F16 | `ROOM_EXCLUSIVE_USE` | Room Exclusive Use | ROOM | HARD | `value` (bool) |
| F17 | `ACTIVITY_EXAM_ONLY_PERIODS` | Exam Only Periods | ACTIVITY | HARD | `periods[]` |
| F18 | `ACTIVITY_NO_TEACHING_AFTER_EXAM` | No Teaching After Exam | ACTIVITY | HARD | `value` (bool) |
| F19 | `ACTIVITY_EXAM_CUTOFF_TIME` | Exam Cutoff Time | ACTIVITY | HARD | `value` (time) |
| F20 | `GLOBAL_FIXED_PERIOD` | Fixed Period (Assembly/Prayer) | GLOBAL | HARD | `day`, `period` |
| F21 | `GLOBAL_NO_CLASSES_ON_DATE` | No Classes on Date (Holiday) | GLOBAL | HARD | `date` |
| F22 | `GLOBAL_MAX_TEACHING_DAYS` | Max Teaching Days per Week | GLOBAL | HARD | `value` (int) |
| F23 | `OPT_PREFER_MORNING` | Prefer Morning Classes | CLASS | SOFT | (none) |
| F24 | `OPT_PREFER_SAME_ROOM` | Prefer Same Room for Class | ROOM | SOFT | (none) |
| F25 | `OPT_BALANCED_DISTRIBUTION` | Balanced Distribution Across Week | GLOBAL | SOFT | (none) |

### Currently Registered in ConstraintFactory::CONSTRAINT_CLASS_MAP (12 PHP classes)

| Code | PHP Class |
|------|-----------|
| `LUNCH_BREAK` | `Hard\LunchBreakConstraint` |
| `SHORT_BREAK` | `Hard\ShortBreakConstraint` |
| `BREAK_PERIOD` | `Hard\BreakConstraint` |
| `TEACHER_CONFLICT` | `Hard\TeacherConflictConstraint` |
| `ROOM_AVAILABILITY` | `Hard\RoomAvailabilityConstraint` |
| `MAX_DAILY_LOAD` | `Hard\MaximumDailyLoadConstraint` |
| `NO_SAME_SUBJECT_SAME_DAY` | `Hard\NoSameSubjectSameDayConstraint` |
| `FIXED_PERIOD_HIGH_PRIORITY` | `Hard\FixedPeriodForHighPriorityConstraint` |
| `HIGH_PRIORITY_FIXED_PERIOD` | `Hard\HighPriorityFixedPeriodConstraint` |
| `DAILY_SPREAD` | `Hard\DailySpreadConstraint` |
| `PREFERRED_TIME_OF_DAY` | `Soft\PreferredTimeOfDayConstraint` |
| `BALANCED_DAILY_SCHEDULE` | `Soft\BalancedDailyScheduleConstraint` |

---

## CATEGORY G: Global/Institution Policies

User input captured via **School Settings / Timetable Configuration** screens.

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| G1 | **Break Time Configuration** — Define break/interval slots per day | HARD | Day-Period grid marking break slots | Req: "Set Break Time" |
| G2 | **School Operating Days** — Which days of the week school operates | HARD | Day checkboxes (MON-SUN) | Req: "Days & Hours" |
| G3 | **Periods Per Day** — Number of teaching periods per day | HARD | Integer per day (or uniform) | Req: "How many hours per day" |
| G4 | **Shift Configuration** — Single/Double shift, morning/afternoon | HARD | Shift mode dropdown + time ranges | Req: "Single Shift / Two Shifts" |
| G5 | **Maximum Teaching Days Per Week** — Global max working days | HARD | Integer input (1-7) | Req: `GLOBAL_MAX_TEACHING_DAYS` |
| G6 | **Fixed Period (Assembly/Prayer)** — Globally blocked slots for school events | HARD | Day+Period picker | Req: `GLOBAL_FIXED_PERIOD` |
| G7 | **Holiday/No Classes Dates** — Specific dates with no classes | HARD | Date picker | Req: `GLOBAL_NO_CLASSES_ON_DATE` |
| G8 | **Balanced Distribution** — Spread subjects evenly across week | SOFT | Toggle (boolean) | Req: "Spread activity evenly" |
| G9 | **Prefer Morning for Core Subjects** — Core/major subjects in early periods | SOFT | Toggle + subject selection | Req: `OPT_PREFER_MORNING` |

---

## CATEGORY H: Inter-Activity Relationships

User input captured via **Activity Group Management** and **Parallel Period Configuration** screens. These govern relationships between multiple activities.

| # | Constraint | Hard/Soft | Params / Input Fields | Req Reference |
|---|-----------|-----------|----------------------|---------------|
| H1 | **Activities Same Starting Time** — Multiple activities must start at the same period | HARD/SOFT | Activity group linking | Req: "Same starting time" |
| H2 | **Activities Same Day** — Must be on the same day | HARD/SOFT | Activity group linking | Req: "Same day" |
| H3 | **Activities Same Hour** — Must be at the same period | HARD/SOFT | Activity group linking | Req: "Same hour" |
| H4 | **Activities Not Overlapping** — Must not overlap in time (also for Study Format) | HARD | Activity group linking | Req: "Not overlapping" |
| H5 | **Activities Consecutive** — Must be placed in adjacent periods | HARD/SOFT | Activity group with `type=CONSECUTIVE` | Req: "Consecutive, ordered" |
| H6 | **Activities Ordered** — Must be in a specific sequence within a day | HARD/SOFT | Activity group with `type=ORDERED` + sequence | Req: "Ordered if same day" |
| H7 | **Activities Grouped (2 or 3)** — Group of 2-3 activities treated as a block | HARD | Activity group with `type=GROUPED` | Req: "Grouped for 2 or 3 activities" |
| H8 | **Parallel Periods** — Activities across sections must run simultaneously | HARD | Activity group with `type=PARALLEL` + linked class-sections | Req (School): #10 — Hobby/Skill/Optional parallel periods |
| H9 | **Min Days Between Activities** — Minimum calendar days between instances | SOFT | `min_days` (int) | Req: "Min days between them" |
| H10 | **Max Days Between Activities** — Maximum calendar days between instances | SOFT | `max_days` (int) | Req: "Max days between them" |
| H11 | **Activities End Students Day** — Activity must be last of the day | SOFT | Toggle per activity | Req: "End(s) students day" |
| H12 | **Occupy Max Time Slots from Selection** — From a selected set of slots, max to use | SOFT | `slot_selection[]`, `max_count` | Req: "Occupy max time slots from selection" |
| H13 | **Occupy Min Time Slots from Selection** — From a selected set, min to use | SOFT | `slot_selection[]`, `min_count` | Req: "Occupy min time slots from selection" |
| H14 | **Max Simultaneous in Selected Slots** — Max activities from a set that can run simultaneously | SOFT | `activity_ids[]`, `slot_selection[]`, `max_count` | Req: "Max simultaneous in selected time slots" |
| H15 | **Min Simultaneous in Selected Slots** — Min activities from a set running simultaneously | SOFT | `activity_ids[]`, `slot_selection[]`, `min_count` | Req: "Min simultaneous in selected time slots" |
| H16 | **Min Gaps Between Activity Set** — Min gap between activities in a set | SOFT | `activity_ids[]`, `min_gap` | Req: "Min gaps between a set of activities" |
| H17 | **Same Room If Consecutive** — Activities use same room if placed consecutively | SOFT | Activity group linking | Req: "Same room if consecutive" |
| H18 | **Max Different Rooms for Activity Set** — Activities in a set use at most N rooms | SOFT | `activity_ids[]`, `max_rooms` | Req: "Occupies max different rooms" |
| H19 | **Non-Concurrent Minor Subjects** — Games, Library, Art, Hobby, Dance, Music not same day | SOFT | `subject_ids[]` (minor subjects) | Req (School): #6 — "Should not be on same day" |
| H20 | **Activity Fixed to Specific Day** — Activity must fall on a specific day | HARD/SOFT | `day` (enum) | Req (School): #14 — "Wonder Brain comes on Friday" |
| H21 | **Activity Excluded from Specific Day** — Activity must NOT fall on a specific day | HARD/SOFT | `day` (enum) | Req (School): #14 — "Astro should not fall on Friday in classes 3-5" |
| H22 | **Activity Fixed to Period Range** — Activity must fall within specific period range | HARD/SOFT | `period_start`, `period_end` | Req (School): #1 — "Maths of 4T allotted period 6 to 8" |

---

## Summary Statistics

| Category | Code | Count | Implementation |
|----------|------|-------|----------------|
| A — Engine Hard Rules | `HARDCODED_ENGINE` | 5 | FETSolver code (no DB) |
| B — Teacher Availability | `TEACHER_AVAILABILITY` | 22 per-teacher + 20 all-teacher | Teacher setup UI → `tt_constraint` |
| C — Student/Class Rules | `STUDENT_CLASS_RULES` | 18 per-class + 15 all-student | Class setup UI → `tt_constraint` |
| D — Activity Level | `ACTIVITY_LEVEL` | 22 | Activity form → `tt_activities` columns |
| E — Room & Space | `ROOM_SPACE` | 6 room + 10 teacher-room + 10 student-room + 6 subject-room = 32 | Room/Teacher/Class setup → `tt_constraint` |
| F — DB Configurable | `DB_CONSTRAINT_RECORD` | 25 seeded types, 12 PHP classes | Constraint UI → `tt_constraint` → `ConstraintFactory` |
| G — Global Policy | `GLOBAL_POLICY` | 9 | Settings screen → `tt_config` / `tt_constraint` |
| H — Inter-Activity | `INTER_ACTIVITY` | 22 | Activity Group UI → `tt_activity_group` / `tt_constraint` |

**Total Unique Constraint Rules: ~155** (many have per-entity + all-entity variants)

---

## Gap Analysis: Requirements vs Current Implementation

### Fully Implemented (in FETSolver or Activity fields)
- A1-A5 (engine hard rules)
- D1-D22 (activity-level fields + `scoreSlotForActivity()`)
- F1-F7, F8-F13 (teacher + class constraint types seeded)
- Basic room allocation (RoomAllocationPass 5-step)

### Partially Implemented (seeded in DB but missing PHP class or not wired)
- F14-F25 (seeded constraint types without matching PHP classes in CONSTRAINT_CLASS_MAP)
- B1.7-B1.22 (teacher constraints beyond basic daily/weekly/unavailable)
- E2.1-E2.10 (teacher room change tracking — needs post-generation evaluation)
- E3.1-E3.10 (student room change tracking — needs post-generation evaluation)

### Not Yet Implemented
- B1.11, B1.13, B1.14, B1.18, B1.19 (complex teacher interval/study-format constraints)
- C1.10-C1.18 (class study-format and school-specific constraints)
- E1.5, E1.6 (room study format limits, teacher+room combos)
- E4.1-E4.6 (subject/study-format room preferences — partially handled by Activity D17-D20)
- H1-H22 (inter-activity relationships — `tt_activity_group` exists but solver doesn't evaluate group constraints)
- All "All Teachers" / "All Students" global-scope variants (B2, C2)
