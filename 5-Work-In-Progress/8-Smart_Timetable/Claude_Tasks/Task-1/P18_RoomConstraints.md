# P18 — Room & Space Constraints (Category E)

**Phase:** 14 | **Priority:** P2 | **Effort:** 5 days
**Skill:** Backend | **Model:** Sonnet
**Branch:** Tarun_SmartTimetable
**Dependencies:** P07 (Phase 5 — Room Allocation) + P09 (Phase 11 — Constraint Architecture)
**Reference:** `2026Mar10_ConstraintList_and_Categories.md` Category E

---

## Pre-Requisites

Read before starting:
1. `Claude_Context/2026Mar10_ConstraintList_and_Categories.md` — Category E (E1-E4)
2. `Modules/SmartTimetable/app/Services/RoomAllocationPass.php` — built in P07
3. `Modules/SmartTimetable/app/Services/Constraints/ConstraintRegistry.php`

---

## Task 14.1 — Remaining room availability constraints E1 (0.5 day)

### E1.4 — RoomMaxUsagePerDayConstraint

**File:** `Hard/RoomMaxUsagePerDayConstraint.php`
- `$params: max_usage (int)` — max periods a room can be used per day
- Count room's placements on the day

### E1.5 — RoomMaxStudyFormatsConstraint

**File:** `Soft/RoomMaxStudyFormatsConstraint.php`
- `$params: max_study_formats (int)` — max distinct study formats in a room per day

### E1.6 — TeacherRoomUnavailableConstraint

**File:** `Hard/TeacherRoomUnavailableConstraint.php`
- Combined constraint: teacher + room both unavailable at specific times
- `$params: teacher_id, room_id, day_period_pairs[]`

---

## Task 14.2 — Teacher room preferences E2 (2 days)

**New service needed:** `RoomChangeTrackingService.php`

Post-generation evaluation that counts room/building changes per teacher per day/week.

**These are post-gen checks — cannot be evaluated during slot-by-slot generation** because room assignment happens after placement (in RoomAllocationPass).

| Rule | Implementation | File |
|------|---------------|------|
| E2.1-E2.2 Home room / room set | Soft scoring in `RoomAllocationPass::findBestRoom()` | Modify RoomAllocationPass |
| E2.3 Max room changes per day | Post-gen violation check | `RoomChangeTrackingService.php` |
| E2.4 Max room changes per week | Post-gen violation check | `RoomChangeTrackingService.php` |
| E2.5 Max room changes in interval | Post-gen violation check | `RoomChangeTrackingService.php` |
| E2.6 Min gap between room changes | Post-gen violation check | `RoomChangeTrackingService.php` |
| E2.7-E2.10 Building changes | Same as room but at building level | `RoomChangeTrackingService.php` |

---

## Task 14.3 — Student room preferences E3 (1 day)

Mirror of E2 applied to student-sets (class+section). Same `RoomChangeTrackingService` with student entity type parameter.

---

## Task 14.4 — Subject/StudyFormat room preferences E4 (1 day)

| Rule | Implementation |
|------|---------------|
| E4.1-E4.2 Subject preferred room/set | Soft scoring in RoomAllocationPass |
| E4.3-E4.4 Study format preferred room/set | Soft scoring in RoomAllocationPass |
| E4.5-E4.6 Subject+StudyFormat combo | Soft scoring in RoomAllocationPass |

---

## Task 14.5 — Seed constraint types + register classes (0.5 day)

Register all new room constraint classes in ConstraintRegistry. Seed ConstraintType records.

---

## Post-Execution Checklist

1. Run: `/lint` and `/test SmartTimetable`
2. Update AI Brain: `progress.md` → Phase 14 done, 26 room constraint rules
