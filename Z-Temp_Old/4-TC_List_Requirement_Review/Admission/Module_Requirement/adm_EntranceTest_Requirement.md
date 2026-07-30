# Entrance Tests — Business Requirements

## What This Screen Does

The Entrance Tests screen manages the scheduling, candidate registration, and marks entry for admission entrance examinations. Each test is associated with a specific admission cycle and class, with configurable maximum marks, passing marks, and subjects. The system supports importing shortlisted applications as test candidates and provides inline marks entry with automatic Pass/Fail result calculation.

The Entrance Tests tab is the first of two tabs in the Assessment page (`/admission/assessment?tab=entrance-tests`). The second tab shows Merit Lists. The assessment page provides a unified view of the testing and ranking pipeline.

Candidates are linked to applications via the `adm_entrance_test_candidates` pivot table with a unique constraint on `(entrance_test_id, application_id)` to prevent duplicate registrations.

## When This Screen Is Used

- **Test Scheduling**: Creating entrance tests with date, time, venue, and scoring criteria
- **Candidate Registration**: Importing shortlisted/waitlisted applications as test candidates
- **Marks Entry**: Recording marks for each candidate with automatic Pass/Fail determination
- **Result Management**: Viewing test results and candidate performance
- **Test Lifecycle**: Marking tests as Completed or Cancelled as needed
- **Merit List Preparation**: Entrance test scores feed into the merit list computation

## Key Fields

**Test Information**
- Test Name (required) — e.g., "Entrance Examination 2026"
- Admission Cycle (required) — the admission cycle this test belongs to
- Class (required) — target class for this test

**Schedule**
- Test Date (required)
- Start Time (required, must be before End Time)
- End Time (required, must be after Start Time)
- Venue

**Scoring**
- Max Marks (required, minimum 1)
- Passing Marks (nullable, must be ≤ Max Marks)
- Subjects (comma-separated, stored as JSON array)

**Status**
- Scheduled (default), Completed, Cancelled
- Displayed as color-coded badges (Scheduled=primary, Completed=success, Cancelled=danger)

**Candidate Fields**
- Roll No (auto-assigned on import)
- Marks Obtained (decimal, nullable)
- Result: Pass, Fail, Absent, Pending
- Subject-wise marks (JSON, nullable)

## Business Rules

**Time Validation:** The `StoreEntranceTestRequest` enforces `start_time` must be before `end_time` (`before:end_time`) and `end_time` must be after `start_time` (`after:start_time`). Equal times fail validation.

**Passing Marks Constraint:** `passing_marks` must be ≤ `max_marks` (enforced via `lte:max_marks` rule). If `passing_marks` is null, no automatic Pass/Fail calculation occurs and the result remains "Pending".

**Subjects Storage:** The subjects field is submitted as a comma-separated string which the controller converts to an array before storing in the `subjects_json` JSON column. On retrieval, it's cast to an array for display.

**Candidate Import:** The `importCandidates()` method queries applications with status `Shortlisted` or `Waitlisted` for the same admission cycle. For each qualifying application, it creates an `EntranceTestCandidate` record with `result=Pending` and an auto-assigned roll number. Due to the unique constraint on `(entrance_test_id, application_id)`, duplicate imports are silently skipped.

**Marks Update (Auto Result):** The `updateMarks()` endpoint saves `marks_obtained` and optionally `subject_marks_json`. If `passing_marks` is defined and `marks_obtained` is provided, the system auto-calculates:
- `marks_obtained >= passing_marks` → result = Pass
- `marks_obtained < passing_marks` → result = Fail
- If `passing_marks` is null → result stays Pending

**Mark as Completed:** The show page provides a "Mark as Completed" button when the test status is "Scheduled". This changes the status to "Completed".

**Soft Delete Lifecycle:** Tests support soft-delete, restore, and force-delete. Deleting a test does not cascade delete candidates (candidates remain for audit purposes).

**Serialization:** Marks are stored as `DECIMAL(6,2)` supporting up to 9999.99 with 2 decimal places.

## Workflow

1. Admin schedules an entrance test with name, date/time, venue, max/passing marks, and subjects
2. System defaults status to "Scheduled"
3. Once shortlisted/waitlisted applications are identified, admin imports them as candidates
4. On test day, exam is conducted; admin enters marks for each candidate via inline editing
5. System auto-calculates Pass/Fail based on passing marks
6. When all candidates have been evaluated, admin marks the test as "Completed"
7. Test scores feed into the MeritListService for composite score computation

## Related Screens

- **Merit Lists** — Second tab in Assessment; computes rankings using entrance test scores
- **Applications** — Candidate applications linked via EntranceTestCandidate
- **Admission Cycles** — Tests scoped to admission cycles
- **Show Page** — Detail view with candidate marks table and inline editing

## Requirements

- MUST display paginated entrance tests at `/admission/assessment?tab=entrance-tests` with search by test_name
- MUST authorize via `tenant.adm-entrance-test.*` policy gates (14 permissions)
- MUST validate store with 12 rules (BC-VAL-01 through 12), including start/end time ordering
- MUST enforce `passing_marks ≤ max_marks` validation
- MUST store subjects as JSON array in `subjects_json` column
- MUST default status=Scheduled, is_active=true on create
- MUST support soft-delete, restore, force-delete lifecycle
- MUST provide AJAX toggle-status endpoint returning JSON
- MUST import shortlisted/waitlisted applications as candidates (skipping duplicates via unique constraint)
- MUST auto-assign roll numbers on candidate import
- MUST provide AJAX marks update endpoint with auto Pass/Fail result calculation
- MUST keep result as Pending when passing_marks is null
- MUST show candidate table with inline marks editing on show page
- MUST provide "Mark as Completed" button when status=Scheduled
- MUST load candidates with application relation on show page
- MUST log all CRUD operations via activityLog()
