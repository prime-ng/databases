# Business Requirements Document (BRD)
## Module: Standard Timetable
### Feature 01: Dashboard & Timetable Initialization

---

## 1. Executive Summary
The Standard Timetable module allows administrators to manually construct timetables without relying on the AI Generator. The initialization phase ensures that the manual grid inherits the correct period structures (Period Sets) and tracks its overall placement completion.

## 2. Core Components
- `StandardTimetableController.php` (Methods: `index`, `createTimetable`, `deleteTimetable`)
- Tables: `tt_timetables`, `tt_timetable_types`, `sch_academic_term`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Dashboard Statistics & Coverage
- The dashboard aggregates critical data:
  - Total count of DRAFT vs PUBLISHED timetables.
  - Coverage Matrix: Calculates exactly how many `cells` have been placed per timetable to give admins a visual completion status (e.g., Timetable #102 has 40 cells).

### FR-02: Manual Timetable Initialization
- **Action:** User creates a new timetable, providing `name`, `academic_term_id`, and `timetable_type_id`.
- **Validation (Period Set Check):** The system queries `ClassTimetableType` to ensure that a `PeriodSet` (the master grid layout) is attached to the selected Type and Term. If no Period Set is found, creation is strictly blocked with a `422` error.
- **Save State:** Generates a unique UUID and code (e.g., `MT_20260625_...`), explicitly flags `generation_method = 'MANUAL'`, and sets status to `DRAFT`.

### FR-03: Timetable Deletion Protection
- An admin can delete a manual timetable, but only if its status is **NOT** `PUBLISHED`.
- **Cascade Deletion:** Uses a Database Transaction to safely `forceDelete` all associated `tt_timetable_cell_teacher` pivot records, followed by the `TimetableCell` records, before dropping the main timetable.

---

## 4. Acceptance Criteria
- **Given** I am an admin, **When** I attempt to create a manual timetable for "Winter Term - Regular Type", **Then** the system checks if a Period Set exists for this combination. **If** it does not, **Then** creation fails with "No Period Set is configured".
