# Business Requirements Document (BRD)
## Module: Standard Timetable
### Feature 02: Drag & Drop Grid and Cross-Timetable Validation

---

## 1. Executive Summary
The core feature of the Standard Timetable is its interactive grid (`manualPlacement()`). It loads available activities on the sidebar and allows drag-and-drop plotting. The backend enforces strict validation, crucially spanning *across* all other active timetables in the school to prevent double-booking.

## 2. Core Components
- `StandardTimetableController.php` (Methods: `manualPlacement`, `placeCell`, `removeCell`, `checkConflicts`)
- Tables: `tt_timetable_cells`, `tt_timetable_cell_teacher`, `tt_activity`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Activity Sidebar State Management
- When a class-section is selected, the system loads its `Activity` records.
- For each activity, it calculates:
  - `weekly_needed`: Required weekly periods (e.g., 5).
  - `placed_count`: Number of times this activity is currently in `tt_timetable_cells` for this timetable.
  - `remaining`: `max(0, weekly_needed - placed_count)`.
- The UI reflects this dynamically. If `remaining <= 0`, the activity is marked `is_fully_placed`.

### FR-02: Intra & Cross-Timetable Conflict Engine (`checkConflicts()`)
When an activity is dropped onto a `day_of_week` and `period_ord` cell, the AJAX endpoint executes 5 strict checks before saving:
1. **Intra-Timetable Teacher Conflict:** Is the teacher assigned to another cell *within this same timetable* at this exact time? -> Returns `TEACHER_CONFLICT`.
2. **Cross-Timetable Teacher Conflict:** Is the teacher assigned to an active timetable belonging to *another class* at this exact time? -> Returns `TEACHER_CROSS_TT` (e.g., "Mr. Smith is busy in Class 9 Timetable").
3. **Intra-Timetable Room Conflict:** Is this room already booked in this timetable? -> Returns `ROOM_CONFLICT`.
4. **Cross-Timetable Room Conflict:** Is the Chemistry Lab booked by another class in their timetable? -> Returns `ROOM_CROSS_TT`.
5. **Class Double-Booking:** Is the admin dropping a new subject (e.g., Math) onto a cell that already holds Science? -> Returns `CLASS_DOUBLE_BOOKING` and replaces the old cell.

### FR-03: Cell Placement (`placeCell()`)
- Updates or Creates the `TimetableCell`.
- Explicitly deletes and re-inserts rows in the `tt_timetable_cell_teacher` pivot table based on the `ActivityTeacher` mapping (supporting multiple teachers per cell).

---

## 4. Acceptance Criteria
- **Given** Teacher A is assigned to Class 9-A on Monday Period 1 in Timetable X, **When** I build Timetable Y for Class 10-A and drag Teacher A onto Monday Period 1, **Then** the drop is rejected by `checkConflicts()` returning a `TEACHER_CROSS_TT` error, explicitly naming the conflicting timetable.
