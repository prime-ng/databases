# LMS Exam Tab 7: Exam Scheduling

This tab provides a consolidated calendar and timetable view of all scheduled exam sessions across papers, classes, and sections. It allows the user to view, adjust, and finalize the exam timetable — including dates, time slots, rooms, and invigilator assignments.

---

## How It Works

The screen opens with a calendar view showing the exam date range at the top. Below is a timetable grid with columns for Date, Time Slot, Class-Section, Subject, Paper Set, Room, and Invigilator/Proctor. Each row represents one scheduled allocation.

The user can click any scheduled slot to edit its details — change the date, start/end time, or room. They can also bulk-reschedule by selecting multiple allocations and applying a time shift.

A "Conflicts" panel on the right side highlights scheduling issues such as a room being double-booked, a student being assigned to two papers at the same time, or an invigilator assigned to two rooms simultaneously.

Once the schedule is finalized, the user can publish the timetable, which makes it visible to students in their portal.

---

## Important Business Rules

- A room can host only one exam session at any given time slot. The system prevents double-booking.
- A student can be scheduled for only one paper in any given time slot.
- Scheduled time must respect the paper's duration_minutes — the difference between start and end time must be at least equal to the duration.
- The scheduled date must fall within the exam's start_date and end_date range.
- If `conducted_in_school` is 0, the room field is hidden and location becomes a free-text field.
- Invigilator/proctor assignment is tracked via a separate proctor mapping table (not part of this module's DDL — extendable).
- Publishing the timetable is a separate action from publishing the exam. The timetable can be updated and republished as needed.
- If the exam mode is ONLINE, scheduling primarily defines availability windows; the actual proctoring setup is handled separately.

---

## Database Columns & Behavior

### lms_exam_allocations (scheduling columns)
- `scheduled_date` — DATE, nullable. The specific date this allocation's exam takes place. NULL means TBD.
- `scheduled_start_time` — TIME. The start time of the exam session.
- `scheduled_end_time` — TIME. The end time of the exam session.
- `conducted_in_school` — TINYINT(1), default 1. Determines venue type.
- `room_id` — INT UNSIGNED FK to sch_rooms.id, nullable. Physical room for offline exams.
- `location` — VARCHAR(100), nullable. Used when conducted_in_school is 0.

### lms_exam_papers (referenced for duration constraints)
- `duration_minutes` — INT UNSIGNED, nullable. Used to validate that scheduled end_time - start_time >= duration_minutes.
- `mode` — ENUM('ONLINE','OFFLINE'). Determines whether room/location is relevant.

---

## Deep Analysis

### Business Workflows & State Machines

The scheduling workflow is a calendar-driven lifecycle for time, room, and invigilator assignment. The state machine for a scheduled slot is:

```
UNSCHEDULED ──► SCHEDULED ──► FINALIZED ──► PUBLISHED
                                         │
                                    (timetable visible to students)
```

- **UNSCHEDULED:** Allocation exists but `scheduled_date` is NULL. The slot appears in the calendar as "TBD."
- **SCHEDULED:** Date and time are set. Edits allowed. Conflicts are flagged but not enforced.
- **FINALIZED:** Schedule is locked by an authorized user. No further bulk edits. Individual overrides still possible.
- **PUBLISHED:** Timetable is visible to students in their portal. Unpublishing clears visibility but retains the data.

The conflict detection system runs in real-time as the user edits slots, checking: room double-booking, student time overlap, and invigilator assignment conflicts.

### Validation Rules & Edge Cases

- **Room double-booking:** A room cannot host more than one exam session at the same time slot. The conflict check compares `scheduled_date`, `scheduled_start_time`, `scheduled_end_time`, and `room_id` across all allocations. Overlapping time ranges are flagged.
- **Student scheduling conflict:** A student cannot be in two exams at the same time. Detected by joining allocations through student/group membership and checking overlapping date-time ranges.
- **Duration compliance:** `scheduled_end_time - scheduled_start_time >= duration_minutes` (from `lms_exam_papers`). If the paper has no duration set (`NULL`), this validation is skipped.
- **Date range boundary:** `scheduled_date` must be >= exam's `start_date` and <= exam's `end_date`. Cross-date scheduling is rejected.
- **Offline vs. online scheduling:** For OFFLINE papers, room is mandatory if `conducted_in_school = 1`. For ONLINE papers, room is irrelevant — the scheduling defines an availability window only.
- **Bulk time shift:** When bulk-rescheduling, the system applies a delta to all selected allocations. Each individual allocation must still pass all validation rules after the shift. If any fail, the entire bulk operation is rolled back.
- **Invigilator assignment:** Not tracked in this DDL — an extension table (`lms_exam_proctors`) is expected. The conflict panel should still check proctor assignments for time overlaps.
- **Edge case — no conflicts:** If no conflicts exist, the Conflicts panel shows a green "No conflicts detected" message.

### Integration Points

- **FKs:** `lms_exam_allocations.scheduled_date/scheduled_start_time/scheduled_end_time` — columns only (no direct FK); `room_id` → `sch_rooms.id`; `exam_paper_id` → `lms_exam_papers.id` (for `duration_minutes` and `mode`).
- **Module dependencies:** LMS (allocations, papers), SCH (rooms).
- **Events emitted:** Schedule finalized/published events for student portal notification. Conflict detection results are UI-only and not persisted.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View timetable | Teacher, Admin, Principal | `lms.exam.schedule.view` |
| Edit scheduled slot | Admin | `lms.exam.schedule.edit` |
| Bulk reschedule | Admin | `lms.exam.schedule.bulk.edit` |
| Finalize schedule | Admin, Principal | `lms.exam.schedule.finalize` |
| Publish timetable | Admin, Principal | `lms.exam.schedule.publish` |
| Unpublish timetable | Admin | `lms.exam.schedule.unpublish` |
| View conflicts | Teacher, Admin, Principal | `lms.exam.schedule.conflicts.view` |
| Assign invigilator | Admin | `lms.exam.schedule.invigilator.assign` |
