# Academics — My Teachers Tab Requirements

## 1. Functional Overview
Lists all teachers conducting classes for the student's section, showing their contact emails, subjects taught, and schedule grids.

---

## 2. Page Structure & Parameters

### A. Teacher Directory List
- Card profiles for each teacher:
  - Teacher Profile Picture.
  - Teacher Full Name.
  - Primary Contact Email.
  - List of subjects delivered to this section.
  - Active days (days of the week this teacher is scheduled).

### B. Teacher Schedule Matrix
- Mini timetable grid per teacher:
  - Shows days of the week (Mon-Sat) and the specific period numbers when they teach this class.

---

## 3. Database References
- **Model**: `Modules\TimetableFoundation\Models\TimetableCell`
- **Logic**: Filters timetable cells matching the student's current `class_id` and `section_id`, groups by `teacher_id`, and pulls teachers' user details.
