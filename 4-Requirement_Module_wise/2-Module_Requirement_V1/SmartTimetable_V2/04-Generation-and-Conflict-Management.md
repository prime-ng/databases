# Business Requirements Document (BRD)
## Module: Smart Timetable
### Feature 04: Generation Engine & Memory State

---

## 1. Executive Summary
Generating a timetable for an entire school is computationally expensive. The system utilizes advanced solver algorithms (`PrimeSolver` and `ImprovedTimetableGenerator`) to run permutations in memory before writing anything to the database.

## 2. Core Components
- `TimetableGenerationController.php`
- `PrimeSolver.php` / `ImprovedTimetableGenerator.php`
- PHP Native Sessions (In-Memory Grid)

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Algorithm Invocation (`generateWithPrime`)
- **Flags:** The admin can toggle behavior before generation:
  - `optimize_for_teachers`
  - `optimize_for_students`
  - `avoid_gaps`
  - `class_teacher_first_lecture` (Forces the class teacher to take the 1st period for attendance/homeroom).
  - `strict_no_conflicts`
- The Controller passes all `Activity` objects and the `ConstraintManager` into the `ImprovedTimetableGenerator`.

### FR-02: In-Memory Preview Storage
- The algorithm does **not** instantly write 50,000 rows to `tt_timetable_cells`.
- It returns a `GenerationResult` object.
- The controller temporarily stores the successfully generated 2D grid in the user's PHP Session: `session('generated_timetable_grid')`.
- It also stores a skeleton ID `session('generation_skeleton_timetable_id')`.
- The admin is shown a "Preview" UI built from the session data.

### FR-03: Atomic Commit (`storeTimetable`)
- If the admin approves the preview, they click "Save".
- The `storeTimetable()` method retrieves the grid from `session('generated_timetable_grid')`.
- It executes a massive bulk-insert into `tt_timetable_cells` using database transactions.
- Updates the main `tt_timetables` record status to `PUBLISHED` and drops the temporary session variables.
- **Fail-Safe:** If the user's session expires between generating and saving, the system catches the missing session data and forces the user to regenerate, preventing corrupted partial saves.

---

## 4. Acceptance Criteria
- **Given** I click "Generate", **When** the AI successfully builds a timetable, **Then** my database is NOT immediately altered. I am shown a visual preview. **When** I click "Save", **Then** the controller reads the grid from memory and safely executes bulk inserts to finalize the timetable.
