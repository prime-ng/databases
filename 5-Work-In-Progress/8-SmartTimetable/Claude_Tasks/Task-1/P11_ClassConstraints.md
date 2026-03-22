# P11 — Class/Student Constraints (Category C)

**Phase:** 13 | **Priority:** P1 | **Effort:** 4 days
**Skill:** Backend + Schema | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P09 (Phase 11 — Constraint Architecture)
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category C

---

## Pre-Requisites

Read before starting:
1. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — Category C section (C1.6–C1.18)
2. Teacher constraints (P10) for pattern reference — same structure, different entity
3. `Modules/SmartTimetable/app/Services/Constraints/ConstraintContext.php`

---

## Task 13.1 — Simple class constraints (1 day)

Create in `Modules/SmartTimetable/app/Services/Constraints/Soft/`:

| # | File | Rule | Params |
|---|------|------|--------|
| C1.6 | `ClassMaxGapsPerWeekConstraint.php` | Max gaps across all days | `max_gaps_week (int)` |
| C1.7 | `ClassMaxContinuousConstraint.php` | Max consecutive teaching periods | `max_consecutive (int)` |
| C1.8 | `ClassMaxSpanConstraint.php` | Max first-to-last period span | `max_span (int)` |
| C1.9 | `ClassMinDailyHoursConstraint.php` | Min periods per day if school in session | `min_periods (int)` |
| C1.18 | `ClassTeacherFirstPeriodConstraint.php` | Class teacher gets first period | None — **School Req #2** |

**Pattern for class constraints:**
- `isRelevant()` checks if `target_id` matches `$context->classSectionId` or `$context->classId`
- `passes()` uses solution state to count/check for the target class
- C1.18 is special: checks if the class teacher's activity is placed in period 0

---

## Task 13.2 — Study-format-aware class constraints (1.5 days)

| # | File | Rule | Params | Complexity |
|---|------|------|--------|-----------|
| C1.10 | `ClassMaxStudyFormatHoursConstraint.php` | Max periods of study format per day | `study_format_id, max_periods` | MED |
| C1.11 | `ClassMinStudyFormatHoursConstraint.php` | Min periods of study format per day | `study_format_id, min_periods` | MED |
| C1.12 | `ClassMaxConsecutiveStudyFormatConstraint.php` | Max consecutive of study format | `study_format_id, max_consecutive` | MED |
| C1.13 | `ClassStudyFormatGapConstraint.php` | Min gap between ordered study format pair | `study_format_a_id, study_format_b_id, min_gap` | HIGH |
| C1.14 | `ClassMaxDaysInIntervalConstraint.php` | Max days with teaching in time range | `interval_start, interval_end, max_days` | MED |
| C1.15 | `ClassMinRestingHoursConstraint.php` | Min rest between last/first period across days | `min_rest_hours` | HIGH |

Same pattern as teacher study-format constraints (P10 Task 12.2) but checking class entity instead of teacher.

---

## Task 13.3 — School-specific class constraints (1 day)

### C1.16 — ClassMaxMinorSubjectsConstraint — **School Requirement #6**

**File:** `Soft/ClassMaxMinorSubjectsConstraint.php`
- `$params: max_minor_per_day (int), minor_subject_ids[] (array)`
- Count how many minor subjects (Games, Library, Art, Hobby, Dance, Music) are scheduled for this class on this day
- If placing this activity would exceed max_minor_per_day, return false

### C1.17 — ClassMajorSubjectsDailyConstraint — **School Requirement #4**

**File:** `Soft/ClassMajorSubjectsDailyConstraint.php`
- `$params: major_subject_ids[] (array)`
- Major subjects (Maths, Science, English, Hindi, Social Studies) must appear every day
- Check: after placing this activity, are there still enough slots remaining on this day to fit any missing major subjects?
- **Warning:** This is a complex forward-looking constraint — may need to be soft (scoring) rather than hard (blocking)

---

## Task 13.4 — Global-class variants C2 + seed types (0.5 day)

Same pattern as P10 Task 12.4:
- Reuse same PHP classes
- `isRelevant()` returns true for ALL classes when `target_id` is null
- Individual class overrides take precedence

**Seed ConstraintType records** for C1.6–C1.18 in `ConstraintTypeSeeder`.
**Register** all new classes in `ConstraintRegistry`.

---

## Post-Execution Checklist

1. Run: `/lint Modules/SmartTimetable/app/Services/Constraints/Soft/Class*.php`
2. Run: `/test SmartTimetable`
3. Count: `ls Modules/SmartTimetable/app/Services/Constraints/Soft/Class*.php | wc -l` — should be 13
4. Update AI Brain:
   - `progress.md` → Phase 13 done, 28 class constraint rules implemented
   - `known-issues.md` → Category C gap RESOLVED
