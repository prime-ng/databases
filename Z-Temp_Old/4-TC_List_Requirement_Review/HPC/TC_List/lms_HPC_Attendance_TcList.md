# TC List – HPC Attendance Management

## 1. Feature Information

| Field | Value |
|---|---|
| **Module** | HPC (Higher Purpose Curriculum) |
| **Tab Group** | Attendance Management |
| **Feature** | Attendance Management – Working days configuration, attendance calculation, summary |
| **Controller(s)** | `Modules\Hpc\Http\Controllers\HpcAttendanceController` |
| **Model(s)** | None specific to HPC – uses Student attendance records from StudentProfile module; working days config stored in system settings (key-value) |
| **URL(s)** | `hpc/attendance`, `hpc/attendance/config`, `hpc/attendance/config.save`, `hpc/attendance/summary` |
| **Validation** | Working days: required, integer, min 0, max 31 per month; attendance data integrity |
| **Permission(s)** | `tenant.hpc.viewAny` (view attendance), `tenant.hpc.update` (save config), `tenant.hpc.view` (view summary) |
| **Soft Deletes** | No |
| **Activity Log** | None |

---

## 2. Pre-conditions

1. HPC module is installed and active.
2. StudentProfile module is installed and has attendance records.
3. Admin/Teacher user is authenticated with `tenant.hpc.viewAny`, `tenant.hpc.update`, `tenant.hpc.view` permissions.
4. System settings table exists and supports key-value storage for working days configuration.
5. Students are enrolled and have at least one month of attendance records.
6. Academic year is configured as April–March (not calendar year).
7. HpcAttendanceService class exists with compute logic for attendance percentage.

---

## 3. Default Data Load

| # | Table | Records Expected |
|---|---|---|
| 1 | `system_settings` (or equivalent) | Working days key-value pairs for 12 months (April–March) |
| 2 | Student attendance records (StudentProfile) | ≥ 3 students with ≥ 3 months of daily attendance data |
| 3 | `users` | Admin user with attendance permissions |
| 4 | `permissions` | `tenant.hpc.viewAny`, `tenant.hpc.update`, `tenant.hpc.view` assigned |

---

## 4. Test Data Strategy

| Data Type | Source | Approach |
|---|---|---|
| Working days config | System settings factory | Pre-seeded with known values for all 12 months |
| Attendance records | StudentProfile factory | Daily attendance with known present/absent for each student |
| Student data | User factory | Students with consistent enrollment across academic year |
| Permission roles | Spatie role factory | Controlled roles for permission testing |

---

## 5. Business Conditions

### BC-DB – Database Conditions

| ID | Condition | Description |
|---|---|---|
| BC-DB-01 | Working days stored in system settings | Key-value store: key = `hpc_working_days_YYYY_MM`, value = integer |
| BC-DB-02 | No dedicated DB table for HPC attendance | Attendance data lives in StudentProfile module tables |
| BC-DB-03 | Attendance records in StudentProfile | `student_attendances` or similar table with student_id, date, status |
| BC-DB-04 | System settings table structure | Key (string, unique), value (text), context/tenant_id columns |

### BC-VAL – Validation Conditions

| ID | Condition | Description |
|---|---|---|
| BC-VAL-01 | Working days per month: required | All 12 months must have a value when saving |
| BC-VAL-02 | Working days: must be integer | Non-numeric values rejected |
| BC-VAL-03 | Working days: min 0 | Negative values rejected |
| BC-VAL-04 | Working days: max 31 | Values > 31 rejected |
| BC-VAL-05 | Attendance percentage: computed value | 0–100 range enforced |

### BC-AUTH – Authorisation Conditions

| ID | Condition | Description |
|---|---|---|
| BC-AUTH-01 | `tenant.hpc.viewAny` required | View attendance config page |
| BC-AUTH-02 | `tenant.hpc.update` required | Save attendance config |
| BC-AUTH-03 | `tenant.hpc.view` required | View attendance summary |
| BC-AUTH-04 | Guest redirect to login | Unauthenticated user redirected |
| BC-AUTH-05 | Permission denied → 403 | Authenticated user without proper permission denied |

### BC-BIZ – Business Logic Conditions

| ID | Condition | Description |
|---|---|---|
| BC-BIZ-01 | 12-month working days (April–March) | Config page shows April to March, not January to December |
| BC-BIZ-02 | Working days stored as system settings | Key-value, not dedicated table |
| BC-BIZ-03 | Attendance % = present_days / working_days * 100 | Formula: (present / working) × 100 |
| BC-BIZ-04 | Attendance computed at card load | Every time HPC form loads, attendance is recalculated |
| BC-BIZ-05 | Attendance computed at PDF generation | PDF uses latest attendance data |
| BC-BIZ-06 | Attendance summary: per-student per-month aggregation | Summary table grouped by student and month |
| BC-BIZ-07 | Dynamic table on teacher card | Teacher can add/remove rows (students) and columns (months) |
| BC-BIZ-08 | Academic year: April–March | Not calendar year; query logic uses April as month 1 |

### BC-REF – Reference Conditions

| ID | Condition | Description |
|---|---|---|
| BC-REF-01 | Working days key pattern | `hpc_working_days_{year}_{month}` e.g., `hpc_working_days_2026_04` |
| BC-REF-02 | Academic year months | April (4) → March (3) of next calendar year |
| BC-REF-03 | Attendance formula | `round((present_days / working_days) * 100, 0)` |

---

## 6. Test Case List – Attendance Management

### TC-P (Positive Test Cases)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-P-001 | Config page loads with 12 input fields (April–March) | Page renders with 12 labelled inputs in academic year order | Tester A | Tester B | ⬜ |
| TC-P-002 | Admin enters working days for each month and saves | All 12 months accepted; success message displayed | Tester A | Tester B | ⬜ |
| TC-P-003 | Saved working days values reload correctly on page revisit | Previously saved values pre-populated in each input | Tester A | Tester B | ⬜ |
| TC-P-004 | Change working days for one month – percentage recalculates | Attendance percentage updates on next card load | Tester A | Tester B | ⬜ |
| TC-P-005 | Attendance summary page shows student list | All students listed with per-month attendance | Tester A | Tester B | ⬜ |
| TC-P-006 | Card attendance table renders correctly on teacher card view | Table columns = months (April–March), rows = students, cells = percentage | Tester A | Tester B | ⬜ |
| TC-P-007 | Card re-load shows updated percentages | After config change, reload reflects new calculations | Tester A | Tester B | ⬜ |
| TC-P-008 | PDF generation uses latest attendance data | Generated PDF shows current attendance numbers | Tester A | Tester B | ⬜ |
| TC-P-009 | Dynamic table – add row for a new student | New row appears; attendance data populates | Tester A | Tester B | ⬜ |
| TC-P-010 | Dynamic table – remove row for a student | Row removed; other data unaffected | Tester A | Tester B | ⬜ |
| TC-P-011 | Dynamic table – add column for additional month | New column added | Tester A | Tester B | ⬜ |
| TC-P-012 | Dynamic table – remove column for a month | Column removed; data preserved in DB | Tester A | Tester B | ⬜ |
| TC-P-013 | Attendance percentage displays correctly for 100% attendance | 100% shown for student with all days present | Tester A | Tester B | ⬜ |
| TC-P-014 | Attendance percentage displays correctly for 0% attendance | 0% shown for student with no days present | Tester A | Tester B | ⬜ |
| TC-P-015 | Attendance percentage displays correctly for fractional values | e.g., 15/20 = 75%; 13/22 = 59% | Tester A | Tester B | ⬜ |
| TC-P-016 | Academic year April–March ordering maintained across interface | April always first column, March always last | Tester A | Tester B | ⬜ |
| TC-P-017 | Year rollover (March→April) shows correct new academic year | After March, April data starts fresh academic year | Tester A | Tester B | ⬜ |
| TC-P-018 | Save config with different values – verify persistence across page loads | Values stored in system settings; survive refresh | Tester A | Tester B | ⬜ |
| TC-P-019 | Config page shows current academic year label | e.g., "Academic Year 2026–27" displayed | Tester A | Tester B | ⬜ |
| TC-P-020 | Attendance summary can be filtered by student name/class | Search/filter narrows list; matching students shown | Tester A | Tester B | ⬜ |
| TC-P-021 | Year-to-date total column shown in summary | Summary includes YTD average column | Tester A | Tester B | ⬜ |

### TC-N (Negative Test Cases)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-N-001 | Empty/0 working days for all months | Accepted (0 is valid) but percentage = N/A or 0% | Tester A | Tester B | ⬜ |
| TC-N-002 | Negative working day value (−5) rejected | Validation error "Minimum value is 0" | Tester A | Tester B | ⬜ |
| TC-N-003 | Non-numeric input (text) rejected | Validation error "Must be a number" | Tester A | Tester B | ⬜ |
| TC-N-004 | Save without making any changes (no-op) | Success message; no error; DB unchanged | Tester A | Tester B | ⬜ |
| TC-N-005 | Save with some months empty | Validation error "All months are required" | Tester A | Tester B | ⬜ |
| TCN-006 | Unauthenticated guest user → login redirect | 302 redirect to /login | Tester A | Tester B | ⬜ |
| TC-N-007 | Permission denied for user without `tenant.hpc.viewAny` → 403 | 403 on attendance config page | Tester A | Tester B | ⬜ |
| TC-N-008 | Permission denied for user without `tenant.hpc.update` → 403 on save | 403 on config.save endpoint | Tester A | Tester B | ⬜ |
| TC-N-009 | Permission denied for user without `tenant.hpc.view` → 403 on summary | 403 on attendance summary page | Tester A | Tester B | ⬜ |
| TC-N-010 | Working day value > 31 (e.g., 32) rejected | Validation error "Maximum value is 31" | Tester A | Tester B | ⬜ |
| TC-N-011 | Decimal value (2.5) rejected | Validation error; integer required | Tester A | Tester B | ⬜ |
| TC-N-012 | Save with extremely large value (9999) rejected | Validation error "Maximum value is 31" | Tester A | Tester B | ⬜ |
| TC-N-013 | Config page accessed after midnight on March 31 – academic year boundary | Page still loads; year label may show new academic year if logic uses date-based detection | Tester A | Tester B | ⬜ |
| TC-N-014 | Student has no attendance records – table shows zero/empty | Empty cell or 0% displayed; no error | Tester A | Tester B | ⬜ |

### TC-D (Design / Deep-Dive Test Cases)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-D-001 | Attendance calculation timing: card load vs PDF generation | Both paths call same HpcAttendanceService method; results consistent | Tester A | Tester B | ⬜ |
| TC-D-002 | Year rollover April–March – correct academic year mapping | Attendance data grouped by academic year (Apr–Mar), not calendar | Tester A | Tester B | ⬜ |
| TC-D-003 | Config change mid-year affects recalculations | Changing March working days from 22 to 20 recalculates percentages | Tester A | Tester B | ⬜ |
| TC-D-004 | No attendance records → empty table | Table renders with headers but empty data rows; no error | Tester A | Tester B | ⬜ |
| TC-D-005 | Student re-classed – attendance follows student | Student ID remains same; past attendance records still visible | Tester A | Tester B | ⬜ |
| TC-D-006 | Config storage in system settings (key-value) | Working days NOT in dedicated table; stored with key pattern | Tester A | Tester B | ⬜ |
| TC-D-007 | HpcAttendanceService compute logic | Service method takes student_id, month, year; returns percentage | Tester A | Tester B | ⬜ |
| TC-D-008 | Multiple tenants – working days isolated per tenant | Changing config in Tenant A does not affect Tenant B | Tester A | Tester B | ⬜ |
| TC-D-009 | Working days config has context/tenant scope | Settings query includes tenant_id in WHERE clause | Tester A | Tester B | ⬜ |
| TC-D-010 | Present days query performance with large dataset | 1000 students × 12 months loads within acceptable time | Tester A | Tester B | ⬜ |
| TC-D-011 | Attendance data caching – stale data not served | Cache invalidated on config save or new attendance record | Tester A | Tester B | ⬜ |
| TC-D-012 | Percentage rounding behaviour | 66.666...% rounds to 67%; 66.333...% rounds to 66% | Tester A | Tester B | ⬜ |
| TC-D-013 | Division by zero guard – working_days = 0 | Returns 0 or N/A; no DivisionByZeroError | Tester A | Tester B | ⬜ |
| TC-D-014 | Student unenrolled mid-year – attendance stops accumulating | Attendance records exist up to unenrolment date; after that no new records | Tester A | Tester B | ⬜ |
| TC-D-015 | Academic year auto-detection logic | System determines current academic year from date (April–March boundary) | Tester A | Tester B | ⬜ |
| TC-D-016 | Dynamic table row add – student not yet in system | Add row selects from existing students; cannot add non-existent student | Tester A | Tester B | ⬜ |
| TC-D-017 | Dynamic table column order preserved after add/remove | Columns maintain April–March sort order; no gaps | Tester A | Tester B | ⬜ |

---

## 7. Detailed Test Steps

### TC-P-001: Config page loads with 12 input fields (April–March)

**Prerequisites:** Admin logged in with `tenant.hpc.viewAny`.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/attendance/config` | Config page loads |
| 2 | Count input fields | 12 input fields visible |
| 3 | Check month labels | Labels read: April, May, June, July, August, September, October, November, December, January, February, March (in that order) |
| 4 | Check for academic year heading | "Academic Year 2026–27" or appropriate year |

### TC-P-002: Admin enters working days for each month and saves

**Prerequisites:** All 12 inputs empty or pre-filled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter values: April=22, May=21, June=22, July=23, August=22, September=22, October=23, November=21, December=20, January=22, February=20, March=22 | All inputs populated |
| 2 | Click Save button | Success message "Working days saved successfully" |
| 3 | Check system settings DB | 12 records created with keys: `hpc_working_days_2026_04` through `hpc_working_days_2027_03` and matching values |

### TC-P-003: Saved working days values reload correctly on page revisit

**Prerequisites:** Config saved in TC-P-002.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate away from config page | Different page loaded |
| 2 | Navigate back to `hpc/attendance/config` | All 12 inputs show previously saved values |
| 3 | Compare values | Each input matches the DB-stored value |

### TC-P-004: Change working days for one month – percentage recalculates

**Prerequisites:** Working days configured; student has attendance records.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note current attendance % for a student | e.g., 85% (17/20 for a given month) |
| 2 | Change working days for that month from 20 to 25 | Save config |
| 3 | Load teacher card for that student | Attendance recalculates: 17/25 = 68% |
| 4 | Verify percentage changed | 68% displayed (not 85%) |

### TC-P-005: Attendance summary page shows student list

**Prerequisites:** Multiple students with attendance records.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `hpc/attendance/summary` | Summary page loads |
| 2 | Check student list | All enrolled students listed |
| 3 | Verify per-month columns | 12 month columns (April–March) plus total |
| 4 | Verify data cells | Each cell shows attendance percentage for that student×month |

### TC-P-006: Card attendance table renders correctly on teacher card view

**Prerequisites:** Teacher card with attendance table enabled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open teacher card for a student | Card page loads |
| 2 | Locate attendance table | Table rendered in card body |
| 3 | Check columns | Headers: April through March (academic year order) |
| 4 | Check rows | Student row(s) present with percentage data |

### TC-P-007: Card re-load shows updated percentages

**Prerequisites:** Config changed after initial card load.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Load card initially | Values based on current config |
| 2 | Change working days config | Config updated |
| 3 | Reload card | Percentage values updated |
| 4 | Verify consistency with direct DB calculation | Card matches computed value |

### TC-P-008: PDF generation uses latest attendance data

**Prerequisites:** Student card with attendance.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Generate PDF for student card | PDF downloads |
| 2 | Open PDF | Attendance table in PDF |
| 3 | Verify percentages | Match current config and attendance records |
| 4 | Change working days, regenerate PDF | New PDF has updated percentages |

### TC-P-009: Dynamic table – add row for a new student

**Prerequisites:** Teacher card with dynamic table.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click "Add Row" button | Row added to table |
| 2 | Select student from dropdown | Student selected |
| 3 | Save table | Row persists; attendance data populated |
| 4 | Verify new row data | Percentages calculated and displayed |

### TC-P-010: Dynamic table – remove row for a student

**Prerequisites:** Table has at least one student row.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click remove/delete icon on a row | Row removed from display |
| 2 | Confirm removal | Row disappears |
| 3 | Save table | Change persisted |
| 4 | Reload card | Row still absent |
| 5 | Check DB | Row configuration removed (attendance data preserved) |

### TC-P-011: Dynamic table – add column for additional month

**Prerequisites:** Table visible.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click "Add Column" button | Column selector appears |
| 2 | Select month (e.g., "April 2025") | Column added |
| 3 | Verify column position | Inserted in correct chronological position |
| 4 | Verify data populates | Percentages calculated for new column |

### TC-P-012: Dynamic table – remove column for a month

**Prerequisites:** Table has multiple month columns.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click remove on a month column | Column removed from table |
| 2 | Confirm removal | Column disappears |
| 3 | Save table | Change persisted |
| 4 | Reload card | Column still absent |

### TC-P-013: Attendance percentage displays correctly for 100% attendance

**Prerequisites:** Student with working_days=22 and present_days=22.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note student attendance record | 22 present out of 22 working days |
| 2 | Open card/summary | Percentage shows 100% |
| 3 | Verify formula | (22/22) × 100 = 100% |

### TC-P-014: Attendance percentage displays correctly for 0% attendance

**Prerequisites:** Student with present_days=0.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Note student attendance record | 0 present out of any working days |
| 2 | Open card/summary | Percentage shows 0% |

### TC-P-015: Attendance percentage displays correctly for fractional values

**Prerequisites:** Known present/working values.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Set present=15, working=20 | Percentage = 75% |
| 2 | Set present=13, working=22 | Percentage = 59% (13/22 = 59.09 → rounds to 59%) |
| 3 | Set present=7, working=23 | Percentage = 30% (7/23 = 30.43 → rounds to 30%) |

### TC-P-016: Academic year April–March ordering maintained across interface

**Prerequisites:** Config page and summary page both open.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open config page | Months: Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec, Jan, Feb, Mar |
| 2 | Open summary page | Same column order |
| 3 | Open card with table | Same column order |

### TC-P-017: Year rollover (March→April) shows correct new academic year

**Prerequisites:** System date is April 1, 2026.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open config page | Heading: "Academic Year 2026–27" |
| 2 | Check working days keys | Loads settings for 2026_04 through 2027_03 |
| 3 | Verify no leftover from previous year | 2025–26 data not mixed in |

### TC-P-018: Save config with different values – verify persistence across page loads

**Prerequisites:** Config saved.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Change April from 22 to 24 | Save |
| 2 | Refresh page | April shows 24 |
| 3 | Close browser, reopen | April still shows 24 |
| 4 | Check DB | Value = 24 in system_settings |

### TC-P-019: Config page shows current academic year label

**Prerequisites:** Date is July 2026.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open config page | Header: "Working Days Configuration – Academic Year 2026–27" |

### TC-P-020: Attendance summary can be filtered by student name/class

**Prerequisites:** Summary page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Type student name in search box | Table filters to matching student(s) |
| 2 | Clear search | All students shown again |
| 3 | Filter by class/grade | Only students in that class shown |

### TC-P-021: Year-to-date total column shown in summary

**Prerequisites:** Summary has data for multiple months.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open summary page | Last column = "YTD Total" or "Average" |
| 2 | Verify YTD calculation | Average of all months for each student |
| 3 | Verify only completed months counted | Future months excluded from YTD |

### TC-N-001: Empty/0 working days for all months

**Prerequisites:** Config page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Set all months to 0 | All inputs show 0 |
| 2 | Save | Success message (0 is valid) |
| 3 | Check attendance display | Percentages show 0% or "N/A" |

### TC-N-002: Negative working day value (−5) rejected

**Prerequisites:** Config page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter −5 in April field | Input accepts but may show warning |
| 2 | Attempt to save | Validation error: "The April working days must be at least 0" |
| 3 | Verify DB not updated | Previous value preserved |

### TC-N-003: Non-numeric input (text) rejected

**Prerequisites:** Config page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter "abc" in May field | Input may show as invalid |
| 2 | Attempt to save | Validation error: "The May working days must be an integer" |
| 3 | Verify no save | DB unchanged |

### TC-N-004: Save without making any changes (no-op)

**Prerequisites:** Config page with existing saved values.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open config page | Values pre-filled |
| 2 | Click Save without changing anything | Success message; no DB write necessary |
| 3 | Verify log | No unnecessary DB writes |

### TC-N-005: Save with some months empty

**Prerequisites:** One or more fields left empty.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Clear June field | June empty |
| 2 | Attempt to save | Validation error: "All months are required" |
| 3 | Verify partial save did not occur | DB unchanged for any month |

### TC-N-006: Unauthenticated guest user → login redirect

**Prerequisites:** Not logged in.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/attendance/config` | 302 redirect to /login |
| 2 | Access `hpc/attendance/summary` | 302 redirect to /login |

### TC-N-007: Permission denied for user without `tenant.hpc.viewAny` → 403

**Prerequisites:** Authenticated but lacks `tenant.hpc.viewAny`.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/attendance/config` | 403 Forbidden |
| 2 | Verify error | "You do not have permission to view this page" |

### TC-N-008: Permission denied for user without `tenant.hpc.update` → 403 on save

**Prerequisites:** User has viewAny but not update.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access config page | Page loads (viewAny OK) |
| 2 | Click Save | 403 Forbidden |

### TC-N-009: Permission denied for user without `tenant.hpc.view` → 403 on summary

**Prerequisites:** User lacks `tenant.hpc.view`.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access `hpc/attendance/summary` | 403 Forbidden |

### TC-N-010: Working day value > 31 (e.g., 32) rejected

**Prerequisites:** Config page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter 32 in July field | Value entered |
| 2 | Attempt to save | Validation error: "Maximum value is 31" |

### TC-N-011: Decimal value (2.5) rejected

**Prerequisites:** Config page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter 2.5 in August field | Value entered |
| 2 | Attempt to save | Validation error: "Must be an integer" |

### TC-N-012: Save with extremely large value (9999) rejected

**Prerequisites:** Config page loaded.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Enter 9999 in September field | Value entered |
| 2 | Attempt to save | Validation error: "Maximum value is 31" |

### TC-N-013: Config page accessed after midnight on March 31 – academic year boundary

**Prerequisites:** System date/time is April 1, 2026 00:05.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Access config page | Heading shows "Academic Year 2026–27" |
| 2 | Check April field | Empty or carries forward from previous year (depending on spec) |

### TC-N-014: Student has no attendance records – table shows zero/empty

**Prerequisites:** Student enrolled but has zero attendance records.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open summary page | Student listed |
| 2 | Check cells for that student | Empty or 0% across all months |
| 3 | Verify no error | No exception or error displayed |

### TC-D-001: Attendance calculation timing: card load vs PDF generation

**Prerequisites:** Student with attendance data; config saved.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Load teacher card | Attendance calculated via HpcAttendanceService |
| 2 | Generate PDF for same student | PDF also calls HpcAttendanceService |
| 3 | Compare values | Both return identical percentage |
| 4 | Change config, repeat | Both update identically |

### TC-D-002: Year rollover April–March – correct academic year mapping

**Prerequisites:** Date is February 2026.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Query system for current academic year | Returns "2025–26" (since April 2025 is start) |
| 2 | Check month mapping | Month 1 = April 2025, Month 12 = March 2026 |
| 3 | Verify calendar months mapped correctly | January 2026 = month 10, February 2026 = month 11, March 2026 = month 12 |

### TC-D-003: Config change mid-year affects recalculations

**Prerequisites:** Working days set for all months; attendance records exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Initial: March working_days = 22 | Current % = X |
| 2 | Change March working_days to 20 | Save |
| 3 | Trigger recalculation (load card) | New % = present_days / 20 × 100 |
| 4 | Compare old vs new | Percentage increased (same present, fewer working days) |

### TC-D-004: No attendance records → empty table

**Prerequisites:** Student with zero attendance records.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open summary page | Student row present |
| 2 | Look at data cells | All cells show "—" or "0%" |
| 3 | Open card with table | Table renders with empty cells; no error |

### TC-D-005: Student re-classed – attendance follows student

**Prerequisites:** Student moves from Grade 10 to Grade 11.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Student re-classed in system | Student ID unchanged; class/grade updated |
| 2 | Open attendance summary | All past attendance still visible under same student |
| 3 | Verify continuity | Attendance data not reset |

### TC-D-006: Config storage in system settings (key-value)

**Prerequisites:** Admin can access system settings store.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Save config with April = 22 | System setting created: key = `hpc_working_days_2026_04`, value = "22" |
| 2 | Query system_settings table | Record exists with matching tenant context |
| 3 | Verify no dedicated DB table | No `hpc_working_days` table exists |

### TC-D-007: HpcAttendanceService compute logic

**Prerequisites:** Service class exists.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Call `HpcAttendanceService::calculateAttendance($studentId, $month, $year)` | Returns integer percentage |
| 2 | Verify input params | Accepts student_id, month (int 1–12 or name), year |
| 3 | Verify return type | Integer (0–100) |
| 4 | Test with known data | present=17, working=22 → returns 77 (77.27 rounded) |

### TC-D-008: Multiple tenants – working days isolated

**Prerequisites:** Two tenants (A and B) exist.

| Step | Action | Expected Result |
|---|---|---|
| 1 | In Tenant A: set April = 22 | Saved in Tenant A scope |
| 2 | In Tenant B: set April = 20 | Saved in Tenant B scope |
| 3 | Load config in Tenant A | Shows April = 22 |
| 4 | Load config in Tenant B | Shows April = 20 |

### TC-D-009: Working days config has context/tenant scope

**Prerequisites:** Multi-tenant system.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Query system_settings without tenant filter | Returns multiple rows for different tenants |
| 2 | Query with tenant_id filter | Only current tenant settings returned |
| 3 | Verify controller scopes queries | WHERE tenant_id = current_tenant |

### TC-D-010: Present days query performance with large dataset

**Prerequisites:** 1000+ students with daily attendance.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Load attendance summary page | Page loads within acceptable time (< 5 seconds) |
| 2 | Check DB query log | Optimized queries (no N+1, proper indexing) |
| 3 | Verify no memory exhaustion | Server memory stays within limits |

### TC-D-011: Attendance data caching – stale data not served

**Prerequisites:** Caching enabled.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Load card | Attendance cached |
| 2 | Add new attendance record | Cache invalidated or TTL expired |
| 3 | Reload card | Shows updated attendance |
| 4 | Verify cache clear on config save | Config change also clears cache |

### TC-D-012: Percentage rounding behaviour

**Prerequisites:** Known present/working values.

| Step | Action | Expected Result |
|---|---|---|
| 1 | present=20, working=30 | 66.666... → 67% |
| 2 | present=19, working=30 | 63.333... → 63% |
| 3 | present=1, working=3 | 33.333... → 33% |
| 4 | present=2, working=3 | 66.666... → 67% |
| 5 | Verify rounding mode | Round half up (standard) or as specified |

### TC-D-013: Division by zero guard – working_days = 0

**Prerequisites:** Month with working_days = 0.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Set April working_days = 0 | Config saved |
| 2 | Load any page showing April attendance | Shows 0% or "N/A" |
| 3 | Check logs | No DivisionByZeroError |

### TC-D-014: Student unenrolled mid-year – attendance stops accumulating

**Prerequisites:** Student unenrolled on 15 November 2026.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Check attendance summary for this student | Data shown up to November 2026 |
| 2 | Verify December onwards | Empty or 0% for remaining months |
| 3 | Verify no records after unenrollment date | Attendance table has no entries past Nov 15 |

### TC-D-015: Academic year auto-detection logic

**Prerequisites:** System date varies.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Set system date to April 1, 2026 | Academic year detected: 2026–27 |
| 2 | Set system date to March 31, 2026 | Academic year detected: 2025–26 |
| 3 | Set system date to December 25, 2026 | Academic year detected: 2026–27 |
| 4 | Verify logic: April–March boundary | Correct year mapping in all cases |

### TC-D-016: Dynamic table row add – student not yet in system

**Prerequisites:** Table row add dialog.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Click "Add Row" | Student selector dropdown opens |
| 2 | Verify options | Only existing students listed |
| 3 | Attempt to type non-existent student name | No match; cannot add |
| 4 | Verify student must exist | Row addition requires valid student_id |

### TC-D-017: Dynamic table column order preserved after add/remove

**Prerequisites:** Table with columns Apr, May, Jun, Jul.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Remove "May" column | May removed |
| 2 | Add "May" column back | Column inserted between Apr and Jun |
| 3 | Verify order | Apr, May, Jun, Jul (chronological) |
| 4 | Add "August" column | Appended after Jul |

---

*Document generated for HPC Attendance Management testing. Status column uses ⬜ (pending), 🟢 (pass), 🔴 (fail), 🟡 (blocked).*

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcAttendanceController (Line 26)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcAttendanceController.php:28` | `Gate::authorize('tenant.hpc.viewAny')` |
| 2 | `HpcAttendanceController.php:30-32` | Gets `class_id`, `section_id` from request |
| 3 | `HpcAttendanceController.php:34` | Computes `startYear` from current academic session |
| 4 | `HpcAttendanceController.php:36` | `attendanceService->getWorkingDaysPerMonth($startYear)` � loads working days config from `sys_settings` |
| 5 | `HpcAttendanceController.php:38-48` | Filters `Student` by class/section via `currentAcademicSession` |
| 6 | `HpcAttendanceController.php:50-58` | Batch loads yearly attendance per student via `attendanceService->getYearlyAttendance()` |
| 7 | `HpcAttendanceController.php:60-64` | Loads `SchoolClass::active()`, `Section::active()` for filters |
| 8 | `HpcAttendanceController.php:66-71` | Returns `hpc::attendance.index` view |

### CODE-TRACE-02: `config()` � HpcAttendanceController (Line 77)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcAttendanceController.php:79` | `Gate::authorize('tenant.hpc.update')` |
| 2 | `HpcAttendanceController.php:81` | Gets working days config |
| 3 | `HpcAttendanceController.php:83-87` | Returns `hpc::attendance.config` view |

### CODE-TRACE-03: `saveConfig()` � HpcAttendanceController (Line 93)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcAttendanceController.php:95` | `Gate::authorize('tenant.hpc.update')` |
| 2 | `HpcAttendanceController.php:97-101` | Validates `working_days` array (0-31 per month) |
| 3 | `HpcAttendanceController.php:104-108` | Upserts to `sys_settings` table with key `hpc_working_days_per_month` (JSON value) |
| 4 | `HpcAttendanceController.php:110-119` | Returns JSON success |

### CODE-TRACE-04: `summary()` � HpcAttendanceController (Line 125)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcAttendanceController.php:127` | `Gate::authorize('tenant.hpc.view')` |
| 2 | `HpcAttendanceController.php:129-131` | Validates `student_id` |
| 3 | `HpcAttendanceController.php:134` | `attendanceService->getYearlyAttendance($studentId, $startYear)` |
| 4 | `HpcAttendanceController.php:136-145` | Returns JSON with attendance data |

---
