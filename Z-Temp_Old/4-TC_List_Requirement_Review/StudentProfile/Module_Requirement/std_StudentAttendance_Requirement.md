# std_StudentAttendance — Business Requirements

## What This Screen Does

The Student Attendance feature provides the school with a comprehensive daily attendance management system. It enables teachers and administrators to record, track, review, and report on student attendance across multiple dimensions — from bulk daily marking to individual student-wise logs, summarized class reports, reconciliation of missed marks, and import from external spreadsheets.

This feature is the operational backbone for attendance compliance, enabling the institution to monitor attendance thresholds, generate statutory reports, trigger notifications for low attendance, and maintain an auditable trail of every attendance transaction.

---

## When This Screen Is Used

- **Daily Roll Call** used every school day by class teachers to mark student attendance during the first period or at the start of the day
- **Period-wise Tracking** when the school requires attendance tracking per teaching period rather than just daily presence
- **Attendance Reconciliation** at the end of a week or month to fill in missed marks, auto-fill holidays, and correct discrepancies
- **Bulk Import** at the start of a term when attendance data needs to be loaded from external systems or CSV/XLSX exports
- **Attendance Review** by administrators or parents reviewing a student's attendance history within a date range
- **Report Generation** for compiling class-wise or school-wide attendance statistics, threshold breach alerts, and end-of-term reports
- **System Configuration** when the academic administrator sets attendance thresholds, late-coming grace minutes, and notification rules

## Default Data Load

This feature is accessible under the `/student-profile/student-attendance` URL prefix. When the user navigates to the Attendance Dashboard, AttendanceController@index loads a paginated list of attendance records filtered by the current academic session. Filters for class/section, date, and academic session are pre-populated. The default view shows today's date and the first class section assigned to the logged-in user (if any). Pagination defaults to 20 records per page.

---

---

## Key Fields at a Glance

**Student Identity**
The Student Name (linked to `std_students`), Admission/GR Number, and Class Section assignment are the primary identifiers used across all screens to associate attendance records with the correct student.

**Attendance Status**
Each attendance record carries a Status value from the controlled enum: Present, Absent, Leave, or Holiday. Optional Remarks provide a free-text field for additional context (e.g. "Medical appointment", "Family function"). The status determines how the system calculates attendance percentages and triggers notifications.

**Date and Period Context**
The Attendance Date records the calendar date of the attendance event. An optional Period Number (1–8) supports period-wise attendance tracking, while a period value of 0 indicates a full-day or daily attendance record.

**Audit Trail**
The Marked By field references `sys_users.id` (SET NULL on user deletion) to track who recorded the attendance. The Marked At timestamp captures when the record was created or last updated.

---

## Business Rules and Conditions

**Upsert Semantics for QR/Manual Scan**
When scanning a QR code or entering a manual attendance for the same student + date + period combination, the system must perform an upsert rather than create a duplicate. The existing record is updated with the new status, while the audit fields (marked_by, marked_at) reflect the most recent action.

**Bulk Marking Integrity**
The bulk attendance screen loads all students in a selected class section. Teachers can apply a bulk action (e.g. "Mark All Present") and then override individual rows. On submit, each row is upserted independently. The attendance_date and class_section_id are mandatory for the bulk store operation.

**Status Enum Constraint**
The attendance status must be strictly validated against the allowed enum values: Present, Absent, Leave, Holiday. Any value outside this set must be rejected at the validation layer.

**Attendance Threshold Enforcement**
The system tracks attendance percentages per student. If a student's attendance falls below the configured threshold (default 75%), the system must trigger a notification or alert. The threshold is configurable via the Attendance Settings screen.

**Reconciliation Rule**
The reconciliation screen allows bulk fixing of missed marks. When auto-fill holidays is selected, the system marks all non-teaching days (from the academic calendar) as Holiday for all students in the selected class section, only if no manual attendance record already exists for that date.

**Import Validation**
During CSV/XLSX import, the system validates that student identifiers (GR number or admission number) match existing records in the current tenant. Unknown identifiers are logged in an error report. Duplicate rows are handled via upsert — if a record for the same student + date + period already exists, it is updated rather than rejected.

---

## Workflow Steps

**Marking Daily Attendance (Bulk)**
This is the primary daily workflow performed by the class teacher. The teacher navigates to the Mark Attendance screen, selects the class section and date (defaults to today), and views the list of enrolled students. They can apply a bulk action like "Mark All Present" and then override specific students who are absent or on leave. After reviewing, they click Save. The system upserts each attendance record, logs the operation, and confirms with a success message.

**Scanning QR Code Attendance**
An alternative workflow where students scan their unique QR code at a terminal. The system resolves the student from the QR code, checks the current date and period, and performs an upsert. The teacher can verify scanned records on the dashboard in real-time.

**Running an Attendance Report**
The administrator navigates to the Attendance Report screen, selects a class section and date range, and views summary statistics including total days, days present, absent, leave, and the calculated attendance percentage. The report can be exported or printed.

**Reconciling Missed Marks**
At the end of the week, the administrator opens the Attendance Reconciliation screen for a class section. The system highlights dates where attendance was not marked. The administrator can auto-fill holidays (from calendar) or manually mark attendance for individual missing dates. All changes are logged.

---

## Example Scenario

During a monthly review in October, the School Administrator notices that Class 10A has 7 students whose attendance has fallen below the 75% threshold.

The Administrator navigates to the Attendance Dashboard, filters by Class 10A, and switches to the Attendance Report view for the current term. The report shows a bar chart with each student's attendance percentage. Three students are at exactly 74%, two at 68%, and two at 55%.

Drilling into one of the 55% students, the Administrator opens the Attendance Register (Screen 3) for that student for September. They discover that 8 days were marked "Absent" but the student's parent had submitted leave applications for those dates. The reconciliation screen allows the Administrator to bulk-reclassify those 8 days from Absent to Leave, which brings the student's attendance to 72% — just below the threshold.

The Administrator then triggers the attendance notification system (configured in Attendance Settings) to send automated SMS alerts to the parents of all 7 students below 75%, informing them of their child's attendance status and requesting corrective action.

---

## Related Screens

- **Student Master (`std_students`)** — The primary student data source; attendance records join on `student_id`
- **Class Section Junction (`sch_class_section_jnt`)** — Defines which students belong to which class sections
- **Academic Session** — Defines the current academic session used as a filter scope
- **Attendance Settings** — Configuration screen for thresholds, grace minutes, and notification rules
- **Attendance Reconciliation** — Bulk correction screen for missed marks and auto-fill holidays
- **Attendance Import** — CSV/XLSX bulk import screen
- **User & Permission Module** — `Gate::authorize()` checks `tenant.student-attendance.*` permissions

---

## Requirements

- The system MUST provide a paginated Attendance Dashboard at `GET /student-profile/student-attendance` (route: `student-attendance.index`) with filters for class section, date range, and academic session, paginated at 20 records per page.
- The system MUST provide a Bulk Mark Attendance screen at `GET /student-profile/student-attendance/mark` with a corresponding store endpoint at `POST /student-profile/student-attendance/mark/store`.
- The system MUST provide an Attendance Register (student-wise log) at `GET /student-profile/student-attendance/register` with date range filters.
- The system MUST provide an Attendance Report (class summary statistics) at `GET /student-profile/student-attendance/report`.
- The system MUST provide an Attendance Settings screen at `GET /student-profile/student-attendance/settings` for threshold, grace minutes, and notification configuration.
- The system MUST provide an Attendance Reconciliation screen at `GET /student-profile/student-attendance/reconciliation` with bulk fix and auto-fill holiday capabilities.
- The system MUST provide an Attendance Import screen at `GET /student-profile/student-attendance/import` supporting CSV and XLSX file uploads.
- The system MUST authorize all attendance endpoints via `Gate::authorize()` using `tenant.student-attendance.*` permissions.
- The system MUST enforce tenancy scoping — all attendance queries must be scoped to the current tenant.
- The system MUST validate attendance status against the allowed enum: `Present`, `Absent`, `Leave`, `Holiday`.
- The system MUST enforce upsert logic for QR/Manual entry based on `(student_id, attendance_date, period)` unique key.
- The system MUST require `attendance_date` and `class_section_id` for bulk store operations.
- The system MUST validate `class_section_id` exists in `sch_class_section_jnt` within the current tenant scope.
- The system MUST validate `student_id` exists in `std_students` within the current tenant scope.
- The system MUST sanitize `remarks` free-text input to prevent XSS — strip HTML tags before storage.
- The system MUST reject guest users with a redirect to `/login` for all attendance routes.
- The system MUST paginate the dashboard at 20 records per page by default.
- The system MUST order dashboard records by `attendance_date` descending by default.
- The system MUST log activities for: Attendance Marked (bulk), Attendance Updated, Attendance Imported, Attendance Reconciled.
- The system MUST support CSV and XLSX import with error reporting for unknown student identifiers.
- The system MUST allow configuration of attendance threshold percentage (default 75%) via the Settings screen.
- The system MUST allow configuration of late-coming grace minutes (default 15) via the Settings screen.
- The system MUST cascade delete attendance records when a student is deleted (ON DELETE CASCADE on `student_id`).
- The system MUST cascade delete attendance records when a class section is deleted (ON DELETE CASCADE on `class_section_id`).
- The system MUST SET NULL on `marked_by` when the referencing user is deleted.
- The system MUST redirect to `student-attendance.index` with the appropriate tab parameter after CRUD operations.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.student-attendance.*` (all permissions) | Full access — view, mark, edit, reconcile, import, configure settings |
| Admin | `tenant.student-attendance.*` (all permissions) | Full access — view, mark, edit, reconcile, import, configure settings |
| Class Teacher | `tenant.student-attendance.viewAny` + `.create` + `.update` | Mark attendance for assigned class sections, view dashboard and register |
| HOD | `tenant.student-attendance.viewAny` + `.view` | Read-only — can view attendance data and reports for classes under their department |
| Academic Director | `tenant.student-attendance.viewAny` + `.view` | Read-only — can view reports and analytics across all classes |
| Teacher (non-class) | No explicit permission | No access |
| Parent | `tenant.student-attendance.viewAny` (self — scoped to own children) | View attendance records for their linked children only |
| Guest | None | Redirected to `/login` |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user navigates to the Student Attendance module under `/student-profile/student-attendance`. The system checks authentication — unauthenticated users are redirected to `/login`.
2. `Gate::authorize()` verifies the user has the `tenant.student-attendance.viewAny` permission. If not, HTTP 403 is returned.
3. The Attendance Dashboard loads with default filters — today's date and the first class section assigned to the user. Records are fetched from `std_student_attendances` (scoped to the current tenant) and paginated at 20 per page, ordered by date descending.
4. The user selects filters (class section, date range, academic session) and clicks "Search" — the dashboard refreshes with matching records.
5. To mark attendance, the user clicks "Mark Attendance" → the Bulk Mark screen loads all students in the selected class section.
6. The user applies a bulk action (e.g. "Mark All Present") and/or overrides individual statuses via dropdown. Each row shows the student name, current status, and an optional remarks field.
7. On submit ("Save Attendance"), the system iterates over each student row and performs an upsert — if a record exists for that student + date + period, it updates; otherwise, it creates a new record. The marked_by field is set to the current user's ID.
8. For the Attendance Register, the user selects a student and date range. The system fetches daily attendance records for that student within the range, displayed in a calendar-like or list view showing each day's status.
9. For the Attendance Report, the user selects a class section and date range. The system computes summary statistics — total school days, days present, absent, on leave, holiday — and the attendance percentage per student, displayed in a sortable table with optional chart visualization.
10. The Reconciliation screen loads a grid of class-section + dates where attendance is missing or incomplete. The user can bulk-mark specific dates or auto-fill holidays from the academic calendar.
11. The Import screen accepts a CSV/XLSX file. The system parses the file, validates each row against the `std_students` table, and processes valid rows via upsert. A summary report is generated showing rows processed and any errors encountered.

---

## Validate Before Save (Multiple Conditions)

1. **Attendance Date Required** — `attendance_date` field must not be empty. Error: "Attendance date is required."
2. **Attendance Date Valid** — `attendance_date` must be a valid date. Error: "Attendance date must be a valid date."
3. **Attendance Date Not Future** — `attendance_date` must not be a future date beyond today. Error: "Attendance date cannot be a future date."
4. **Class Section Required (Bulk)** — `class_section_id` must not be empty for bulk operations. Error: "Class section is required."
5. **Class Section Exists** — `class_section_id` must exist in `sch_class_section_jnt` and belong to the current tenant. Error: "Selected class section is invalid."
6. **Student ID Required** — `student_id` must not be empty for manual/QR entry. Error: "Student is required."
7. **Student ID Exists** — `student_id` must exist in `std_students` and belong to the current tenant. Error: "Selected student is invalid."
8. **Status Required** — `status` field must not be empty. Error: "Attendance status is required."
9. **Status Valid Enum** — `status` must be one of: Present, Absent, Leave, Holiday. Error: "Attendance status must be one of: Present, Absent, Leave, Holiday."
10. **Period Valid Range** — `period` must be an integer between 0 and 8 (0 = full day). Error: "Period must be between 0 and 8."
11. **Remarks Max Length** — `remarks` must not exceed 500 characters. Error: "Remarks must not exceed 500 characters."
12. **Remarks XSS Sanitized** — `remarks` is automatically stripped of HTML tags before storage.
13. **Attendance Array Required (Bulk)** — `attendance` array must be provided for bulk store. Error: "Attendance data is required."
14. **Duplicate Prevention** — Combination `(student_id, attendance_date, period)` must be unique — upsert handles this automatically.
15. **Authorization** — `Gate::authorize()` checks the user has the required permission before any operation.
16. **Tenant Scope** — All queries and inserts must be scoped to the current tenant's database.

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Attendance date is empty | "Attendance date is required." | 422 |
| Attendance date is invalid | "Attendance date must be a valid date." | 422 |
| Attendance date is in the future | "Attendance date cannot be a future date." | 422 |
| Class section is empty (bulk) | "Class section is required." | 422 |
| Class section does not exist | "Selected class section is invalid." | 422 |
| Student ID is empty (manual/QR) | "Student is required." | 422 |
| Student ID does not exist | "Selected student is invalid." | 422 |
| Status is empty | "Attendance status is required." | 422 |
| Status is not in allowed enum | "Attendance status must be one of: Present, Absent, Leave, Holiday." | 422 |
| Period is out of 0–8 range | "Period must be between 0 and 8." | 422 |
| Remarks exceeds 500 characters | "Remarks must not exceed 500 characters." | 422 |
| Attendance array missing (bulk store) | "Attendance data is required." | 422 |
| Unknown QR code scanned | "Student not found for the scanned QR code." | 404 |
| No active academic session | "No active academic session found. Please activate a session first." | 400 |
| CSV/XLSX import — unknown student identifier | "Row X: Unknown student identifier 'YYY'." | 200 (with error report) |
| Unauthorized access (missing permission) | "This action is unauthorized." | 403 |
| Guest user (not authenticated) | Redirected to /login | 302 |
| Bulk store with empty attendance array | "At least one student attendance record is required." | 422 |

---

## Success Scenarios

**SC-001: Marking Daily Bulk Attendance**
1. Teacher navigates to Mark Attendance → selects Class 10A → date defaults to today.
2. List of 35 students loads. Teacher clicks "Mark All Present".
3. Teacher overrides 2 absent students by changing their status to "Absent" and adding remarks "Sick leave".
4. Teacher clicks "Save Attendance". System upserts all 35 records.
5. Activity log records "Attendance Marked (bulk)". Dashboard shows success toast: "Attendance saved successfully for 35 students."

**SC-002: Scanning QR Code Attendance**
1. Student presents QR code at the attendance terminal. Teacher scans via the QR scanner interface.
2. System resolves student from QR code, checks current date and period 1.
3. No prior record exists for this student + date + period 1 → system creates a new attendance record with status "Present".
4. Dashboard updates in real-time showing the student as marked present.

**SC-003: Generating Attendance Report**
1. Administrator selects Class 10A, date range 01-Jul-2026 to 15-Jul-2026.
2. System computes 11 school days in the range. Student John Doe: 9 Present, 1 Absent, 1 Leave = 81.82%.
3. Report displays a table with columns: Student Name, GR No., Total Days, Present, Absent, Leave, Holiday, Percentage.
4. Students below 75% threshold are highlighted in red. Administrator exports the report as PDF.

**SC-004: Reconciling Missing Attendance**
1. Administrator opens Reconciliation screen for Class 10A.
2. System shows 3 dates (5-Jul, 8-Jul, 12-Jul) where attendance was not marked for any student.
3. Administrator selects "Auto-fill Holidays" — system checks academic calendar: 8-Jul was a holiday → marks all students as "Holiday" for that date.
4. For 5-Jul and 12-Jul (regular school days), administrator bulk-marks all students as "Present".
5. Activity log records "Attendance Reconciled". All records are upserted.

**SC-005: Importing Attendance from CSV**
1. Administrator uploads `attendance_october.csv` via the Import screen.
2. File contains 500 rows with columns: GR_Number, Date, Status, Remarks.
3. System validates: 495 rows match valid students, 5 rows have unknown GR numbers.
4. Valid 495 rows are upserted. Error report shows: "Row 12: Unknown student identifier 'GR2026-999'. Row 45: Unknown student identifier 'GR2026-888'."
5. Success toast: "495 of 500 records imported successfully. 5 errors found."

---

## Failure Scenarios

**FC-001: Bulk Store with Missing Class Section**
1. Teacher navigates to Mark Attendance but no class section is selected.
2. Teacher clicks "Save Attendance" without selecting a class section or date.
3. System validation fails with error: "Class section is required." and "Attendance date is required."
4. Records are not saved. The form remains with entered data preserved.

**FC-002: Invalid Attendance Status Submitted**
1. Teacher manually edits the HTTP request (via browser dev tools) and submits status as "Unknown".
2. System validation rejects the request with error: "Attendance status must be one of: Present, Absent, Leave, Holiday."
3. HTTP 422 response returned. No records are modified.

**FC-003: Unknown Student QR Code**
1. A student presents a QR code that is not linked to any active student in the system (e.g. expired or fake QR).
2. System cannot resolve the student. Returns JSON error: "Student not found for the scanned QR code."
3. Attendance terminal displays error message. No record is created.

**FC-004: Unauthorized Access Attempt by Teacher (non-class)**
1. A Teacher with no class section assignments navigates to the Mark Attendance URL directly.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with message: "This action is unauthorized."

**FC-005: Import File with All Invalid Rows**
1. Administrator uploads a CSV file where none of the student identifiers match existing records.
2. System processes all 100 rows, finds 0 valid matches.
3. No records are upserted. Error report lists all 100 rows with "Unknown student identifier".
4. Warning toast: "0 of 100 records imported. All rows had errors. Please check the error report."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Primary Table | `std_student_attendances` | `id`, `student_id` BIGINT FK, `class_section_id` BIGINT FK, `attendance_date` DATE, `period` TINYINT(1) DEFAULT 0, `status` ENUM('Present','Absent','Leave','Holiday'), `remarks` TEXT NULL, `marked_by` BIGINT FK NULL, `marked_at` TIMESTAMP, `created_at`, `updated_at` |
| Related Table | `std_students` | FK `std_student_attendances.student_id` REFERENCES `std_students.id` ON DELETE CASCADE |
| Related Table | `sch_class_section_jnt` | FK `std_student_attendances.class_section_id` REFERENCES `sch_class_section_jnt.id` ON DELETE CASCADE |
| Related Table | `sys_users` | FK `std_student_attendances.marked_by` REFERENCES `sys_users.id` ON DELETE SET NULL |
| Related Table | `academic_sessions` | Used for scope filtering of attendance records by academic session |
| Module Dependency | StudentProfile Module | Core module where attendance is managed under `/student-profile/student-attendance` |
| Module Dependency | Class & Section Module | Provides class-section definitions and student-class mappings |
| Module Dependency | Academic Calendar Module | Consumed by reconciliation for auto-fill holidays |
| Module Dependency | User & Permission Module | `Gate::authorize()` checks `tenant.student-attendance.*` permissions |
