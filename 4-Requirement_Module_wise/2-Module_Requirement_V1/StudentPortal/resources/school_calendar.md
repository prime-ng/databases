# Resources — School Calendar Tab Requirements

## 1. Functional Overview
An interactive calendar grid displaying working days, reduced periods, holidays, and school events.

---

## 2. Calendar Components & Parameters

### A. Academic Session Dates
- Displays start and end dates of the active academic session.

### B. Monthly Grid Layout
- Renders monthly grids color-coded by day type:
  - **Regular School Days**: Normal hours.
  - **Holidays**: School closed.
  - **Reduced Period Days**: Half-days.
- Selecting a day details modal displays scheduled school events or activities.

### C. Attendance/Day Counters
- Shows total session days, total school days, holidays, and half-days.

---

## 3. Database References
- **Model**: `Modules\TimetableFoundation\Models\WorkingDay`
- **Table**: `tmt_working_days`
- **Fields**:
  - `academic_session_id`
  - `date`
  - `is_school_day`
  - `day_type_id`
  - `day_type2_id`
  - `day_type3_id`
  - `day_type4_id`
