# Academics — My Timetable Tab Requirements

## 1. Functional Overview
Renders a weekly scheduling matrix showing class periods, study formats, classroom locations, and teachers for each school day.

---

## 2. Matrix Structure & Layout Details
- **Grid Axis**:
  - **Horizontal Header**: Days of the week (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday).
  - **Vertical Header**: Period Name/No. (ordinal slots) and duration timings.
- **Timetable Cell Data**:
  - Subject Name.
  - Study Format (Lecture / Practical / Lab).
  - Teacher Name (hyperlink to teacher summary).
  - Room Number / Class location.
- **Special Configurations**:
  - Highlights break slots (e.g. Lunch Recess) dynamically across all days.
  - Flags offline vs. online class allocations.

---

## 3. Database References
- **Models**:
  - `Modules\TimetableFoundation\Models\TimetableCell`
  - `Modules\TimetableFoundation\Models\SchoolDay`
- **Tables**:
  - `tmt_timetable_cells`
  - `tmt_school_days`
