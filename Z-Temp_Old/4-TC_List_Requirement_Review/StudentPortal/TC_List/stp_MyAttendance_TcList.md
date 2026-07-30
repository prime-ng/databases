# stp_MyAttendance — Test Case List

## 1. Module Feature Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Attendance |
| FRD Reference | REQ-STP-007, BR-STP-001, BR-STP-014, BR-STP-015 |
| Route | `student-portal.my-attendance` (GET `/student-portal/my-attendance`) |
| Controller | `StudentProgressController@attendance` |
| View | `studentportal::attendance.index` |

## 2. Feature Overview

Displays the authenticated student's attendance records for the current academic session with summary vitals (present, absent, late, leave counts, percentage) and month-wise grouped logs presented in both calendar grid and list views.

## 3. Test Scope

### In Scope
- Attendance summary computation (total, present, absent, late, leave, percentage)
- Month grouping and accordion functionality
- Calendar view colour-coded day cells
- List view with status badges
- View toggle (Calendar ↔ List)
- Empty states (no student, no session, no records)
- Status normalization logic
- Activity logging on page view
- Data ownership (only own attendance shown)

### Out of Scope
- Attendance data creation (handled by StudentAttendance module)
- Cross-student data access (security boundary)
- PDF export of attendance

## 4. Test Environment / Pre-requisites

| Requirement | Details |
|-------------|---------|
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8 — Tenant DB with `std_student_attendance`, `std_students`, `std_academic_sessions` tables |
| Auth | Authenticated as Student user with `student` relation |
| Browser | Chrome/Firefox/Edge (latest), JavaScript enabled for view toggle |
| Test data | Student enrolled in academic session with attendance records |

## 5. Test Data Setup

- **Student A:** Has `student` relation, assigned to `class_section_id=1`, `academic_session_id=2025`, has 50 attendance records with mixed statuses (Present, Absent, Late, Leave, P, A, L — to test normalization)
- **Student B:** Has `student` relation but no attendance records for current session
- **Student C:** Has `student` relation with null `status` in some records
- **User D:** Authenticated user with no `student` relation

## 6. Test Cases

| TC ID | Test Case | Pre-requisites | Test Steps | Expected Result | Status | CR |
|-------|-----------|----------------|------------|-----------------|--------|----|
| TC-ATT-001 | Verify attendance page loads for valid student | Student A logged in, has session + records | 1. Navigate to `/student-portal/my-attendance` | Page loads with breadcrumb "Home > My Attendance", title "My Attendance" | ⬜ | ◌ |
| TC-ATT-002 | Verify summary cards display correct counts | Student A has 50 records: 30 Present, 10 Absent, 5 Late, 5 Leave | 1. Load attendance page 2. Observe 4 summary cards | Card 1: Present = 30; Card 2: Absent = 10; Card 3: Late/Leave = 10 (5+5); Card 4: Percentage = 60.0% | ⬜ | ◌ |
| TC-ATT-003 | Verify percentage calculation accuracy | Student A: 30 present out of 50 total | 1. Load page 2. Observe percentage card | Percentage = (30/50) × 100 = 60.0% (orange colour, label "Borderline") | ⬜ | ◌ |
| TC-ATT-004 | Verify present threshold styling | ≥75% present (30/40 = 75%) | 1. Create scenario with 75% 2. Load page | Percentage card green (#00b894), label "Good standing" | ⬜ | ◌ |
| TC-ATT-005 | Verify borderline threshold styling | ≥60% and <75% present (30/50 = 60%) | 1. Create scenario with 60% 2. Load page | Percentage card orange (#e17055), label "Borderline" | ⬜ | ◌ |
| TC-ATT-006 | Verify below-minimum threshold styling | <60% present (25/50 = 50%) | 1. Create scenario with 50% 2. Load page | Percentage card red (#d63031), label "Below minimum (75%)" | ⬜ | ◌ |
| TC-ATT-007 | Verify attendance records grouped by month | Student A has records across Jan 2026, Feb 2026, Mar 2026 | 1. Load page 2. Observe month accordion | Records grouped under "January 2026", "February 2026", "March 2026" cards | ⬜ | ◌ |
| TC-ATT-008 | Verify latest month opens expanded by default | Records exist in multiple months, latest = March 2026 | 1. Load page 2. Observe accordion | March 2026 card body visible; earlier months collapsed | ⬜ | ◌ |
| TC-ATT-009 | Verify month accordion toggle | Month card in collapsed state | 1. Click collapsed month header 2. Observe body | Month body expands; chevron rotates 180° | ⬜ | ◌ |
| TC-ATT-010 | Verify calendar view displays correct day colours | Student A: 5 Present, 2 Absent, 1 Late in March 2026 | 1. Load page (Calendar view default) 2. Scroll to March 2026 calendar | Present days = green cells; Absent days = red cells; Late day = yellow cell | ⬜ | ◌ |
| TC-ATT-011 | Verify weekend cells rendered light grey | Saturday/Sunday in calendar | 1. Load page 2. Observe calendar for a month | Weekend cells show light grey (#f1f3f5) with no status label | ⬜ | ◌ |
| TC-ATT-012 | Verify future date cells rendered faint | Current month, dates after today | 1. Load page 2. Observe current month calendar | Future day cells show #f8f9fa background, no status | ⬜ | ◌ |
| TC-ATT-013 | Verify today highlighted with ring | Today's date in calendar | 1. Load page 2. Observe today's cell | Today's cell has purple outline ring (`outline:2px solid #6c5ce7`) | ⬜ | ◌ |
| TC-ATT-014 | Verify calendar cell hover tooltip | Hover over a Present day cell | 1. Hover over a coloured cell 2. Observe tooltip | Tooltip shows "DayName, dd Mmm YYYY: Present — remarks" | ⬜ | ◌ |
| TC-ATT-015 | Verify toggle to List view | Any month with records | 1. Click "List" toggle button 2. Observe | Calendar views hidden; list tables visible; button becomes active | ⬜ | ◌ |
| TC-ATT-016 | Verify toggle back to Calendar view | Currently on List view | 1. Click "Calendar" toggle button 2. Observe | List views hidden; calendar views visible; button becomes active | ⬜ | ◌ |
| TC-ATT-017 | Verify list view table columns | Month with attendance records | 1. Switch to List view 2. Observe table | Columns: Date, Day, Status (with badge), Remarks | ⬜ | ◌ |
| TC-ATT-018 | Verify status badges in list view | Records with Present, Absent, Late, Leave | 1. Switch to List view 2. Observe status column | Present → green badge with check icon; Absent → red badge with times icon; Late → orange badge with clock icon; Leave → blue badge with calendar icon | ⬜ | ◌ |
| TC-ATT-019 | Verify empty state when no student relation | User D (no student profile) logged in | 1. Navigate to `/student-portal/my-attendance` | Empty state: "No active session found. Attendance will appear once you are enrolled in a class." | ⬜ | ◌ |
| TC-ATT-020 | Verify empty state when no session | Student B enrolled but no current session | 1. Navigate to `/student-portal/my-attendance` | Empty state: "No active session found." | ⬜ | ◌ |
| TC-ATT-021 | Verify empty state when no records | Student B with session but zero attendance records | 1. Navigate to `/student-portal/my-attendance` | Empty state: "No attendance records found for the current session." | ⬜ | ◌ |
| TC-ATT-022 | Verify status normalization for variant values | Records with "P", "A", "L", "On Leave" statuses | 1. Load page 2. Observe summary | "P" counted as Present; "A" counted as Absent; "L" counted as Late; "On Leave" counted as Leave | ⬜ | ◌ |
| TC-ATT-023 | Verify "Half Day" status not counted in any summary | Record with status "Half Day" | 1. Load page 2. Observe summary counts | Half Day not included in present/absent/late/leave; displayed in list view as-is | ⬜ | ◌ |
| TC-ATT-024 | Verify unknown status value displayed as-is | Record with status "UNKNOWN_CODE" | 1. Load page 2. Observe list/calendar | Calendar cell: grey (#b2bec3) with "?" label; List: secondary badge with "Unknown_code" | ⬜ | ◌ |
| TC-ATT-025 | Verify null status handled gracefully | Record with null status | 1. Load page 2. Observe | Calendar cell: default grey; List: "—" displayed | ⬜ | ◌ |
| TC-ATT-026 | Verify remarks column shows teacher comment | Record with remarks="Medical leave" | 1. Load page 2. Hover calendar cell and check list | Tooltip shows remarks; list row shows "Medical leave" | ⬜ | ◌ |
| TC-ATT-027 | Verify activity log recorded on page view | Student A with valid session | 1. Navigate to page 2. Check activity_log table | Entry created with message "Student viewed my attendance.", context includes student_id, student_name, module, route | ⬜ | ◌ |
| TC-ATT-028 | Verify page is inaccessible without authentication | User not logged in | 1. Access `/student-portal/my-attendance` without session | Redirected to login page | ⬜ | ◌ |
| TC-ATT-029 | Verify no cross-student data leakage | Student A logged in | 1. Load page 2. Check attendance records | Only Student A's records shown; cannot access another student's data via any parameter | ⬜ | ◌ |
| TC-ATT-030 | Verify attendance_period column hides when all zero | No records have attendance_period > 0 | 1. Load page 2. Switch to List view | "Period" column not rendered in table header | ⬜ | ◌ |
| TC-ATT-031 | Verify attendance_period column shows when any record has value | At least one record has attendance_period=3 | 1. Load page 2. Switch to List view | "Period" column rendered, shows period number for that record, "—" for others | ⬜ | ◌ |

## 7. Test Summary

| Metric | Count |
|--------|-------|
| Total Test Cases | 31 |
| Automated | — |
| Manual | 31 |
| Pass | — |
| Fail | — |
| Blocked | — |
| Not Executed | 31 |

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|----------|-------------|----------|--------|
| GAP-ATT-01 | BR-STP-015 normalization incomplete: raw values (P, A, L) rendered directly in UI | Medium | ⬜ |
| GAP-ATT-02 | "Half Day" status not counted in any summary bucket | Medium | ⬜ |
| GAP-ATT-03 | No pagination — all session records loaded at once | Low | ⬜ |
| GAP-ATT-04 | `attendance_period` conditional — inconsistent across months | Low | ⬜ |

## 9. Route Reference

| Method | Path | Route Name | Middleware |
|--------|------|------------|------------|
| GET | `/student-portal/my-attendance` | `student-portal.my-attendance` | `auth`, `verified` |

## 10. Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 31 | — |

---

*Test cases derived from controller code analysis, input requirement doc, and FRD cross-reference.*
