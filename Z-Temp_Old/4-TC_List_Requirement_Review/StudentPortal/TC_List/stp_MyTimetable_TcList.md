# stp_MyTimetable — Test Case List

## 1. Module Feature Information

| Field | Value |
|-------|-------|
| Module Code | STP |
| Module Name | StudentPortal |
| Feature Name | My Timetable |
| FRD Reference | REQ-STP-008, BR-STP-011, BR-STP-012, BR-STP-013 |
| Route | `student-portal.my-timetable` (GET `/student-portal/my-timetable`) |
| Controller | `StudentTimetableController@index` |
| View | `studentportal::timetable.index` |

## 2. Feature Overview

Renders a weekly day×period timetable grid for the student's class and section from published/active timetable cells. Includes weekly summary cards, subject-coloured cells with teacher/room info, break/free period handling, subject legend, and a today's schedule table.

## 3. Test Scope

### In Scope
- Weekly summary cards (day name, period count, subject count)
- Main timetable grid: headers, rows, cell content
- Subject colour coding (consistent per subject)
- Break period rendering (SBREAK/LUNCH/BREAK)
- Free period rendering
- Today highlight (column + row)
- Subject legend with colour dots
- Today's Schedule table
- Teacher names, room locations, study format badges
- Conflict badge and lock icon
- Empty states (no student, no class, no timetable)
- Activity logging

### Out of Scope
- Timetable creation/management
- Cross-week navigation

## 4. Test Environment / Pre-requisites

| Requirement | Details |
|-------------|---------|
| Backend | Laravel 12, PHP 8.2+ |
| Database | MySQL 8 — Tenant DB with `tmt_timetable_cells`, `tmt_school_days`, `tmt_periods`, `tmt_rooms` |
| Auth | Authenticated as Student user |
| Browser | Chrome/Firefox/Edge (latest), JavaScript optional (grid is server-rendered) |

## 5. Test Data Setup

- **Student A:** Class 5-A with published timetable: 6 days (Mon–Sat), 8 periods/day, 10 subjects
- **Student B:** Class 5-B with GENERATED timetable (not yet PUBLISHED)
- **Student C:** Class empty (no timetable cells)
- **Timetable includes:** Break periods (LUNCH, SBREAK), free periods, conflict flags, locked cells

## 6. Test Cases

| TC ID | Test Case | Pre-requisites | Test Steps | Expected Result | Status | CR |
|-------|-----------|----------------|------------|-----------------|--------|----|
| TC-TT-001 | Verify timetable page loads for valid student | Student A, published timetable exists | 1. Navigate to `/student-portal/my-timetable` | Page loads with breadcrumb "Home > My Timetable", title "My Timetable" | ⬜ | ◌ |
| TC-TT-002 | Verify info strip shows student details | Student A enrolled in Class 5-A | 1. Load page 2. Observe info strip | Shows student name, "Class 5 – A", roll number, today's date | ⬜ | ◌ |
| TC-TT-003 | Verify weekly summary cards for all school days | 6 school days (Mon–Sat) with 7 periods each | 1. Load page 2. Observe summary row | 6 cards: Mon, Tue, Wed, Thu, Fri, Sat each showing period count | ⬜ | ◌ |
| TC-TT-004 | Verify today's card highlighted | Today = Wednesday | 1. Load page on Wednesday 2. Observe cards | Wednesday card has purple top border + shadow; "(Today)" label | ⬜ | ◌ |
| TC-TT-005 | Verify grid period headers | Periods 1–8 with names, times, durations | 1. Load page 2. Observe grid header | 8 columns with period short name, time range (e.g. "9:00 AM – 9:45 AM"), duration (e.g. "45 min") | ⬜ | ◌ |
| TC-TT-006 | Verify each day row has correct periods | Monday has periods P1–P8 | 1. Load page 2. Observe Monday row | 8 cells under periods; subject/break/free as configured | ⬜ | ◌ |
| TC-TT-007 | Verify subject cells have coloured background | Mathematics cell (subject_id=1) | 1. Load page 2. Find Mathematics | Cell background = colour from palette[1 % 12] | ⬜ | ◌ |
| TC-TT-008 | Verify same subject gets same colour across days | Mathematics on Mon and Wed | 1. Load page 2. Compare both cells | Same colour on both days | ⬜ | ◌ |
| TC-TT-009 | Verify subject name displayed in cell | Mathematics in cell | 1. Hover over cell | "Mathematics" shown in bold white text | ⬜ | ◌ |
| TC-TT-010 | Verify study format badge | Practical format | 1. Load page 2. Find Practical cell | Shows "Practical" in semi-transparent badge | ⬜ | ◌ |
| TC-TT-011 | Verify teacher name(s) in cell | Mr. Sharma assigned to Mathematics | 1. Load page 2. Find Mathematics cell | Shows "Mr. Sharma" with user icon | ⬜ | ◌ |
| TC-TT-012 | Verify multiple teachers comma-separated | Subject with Mrs. Gupta and Mr. Verma | 1. Load page 2. Find cell | Shows "Mrs. Gupta, Mr. Verma" | ⬜ | ◌ |
| TC-TT-013 | Verify room name and type | Room "Lab 1" (Laboratory) | 1. Load page 2. Find cell | Shows "Lab 1 (Laboratory)" with map-marker icon | ⬜ | ◌ |
| TC-TT-014 | Verify break period rendering | LUNCH period code | 1. Load page 2. Find LUNCH column | Grey background, 🍽 emoji, "LUNCH", duration | ⬜ | ◌ |
| TC-TT-015 | Verify SBREAK period rendering | SBREAK period | 1. Load page 2. Find SBREAK column | Grey background, ☕ emoji, "SBREAK", duration | ⬜ | ◌ |
| TC-TT-016 | Verify free period shows "—" | Cell with is_free=true or no cell | 1. Load page 2. Find free cell | White background, centred "—" | ⬜ | ◌ |
| TC-TT-017 | Verify today's column highlighted | Today=Wednesday, column 3 | 1. Load page on Wednesday | Column 3 header has purple background `#eef2ff` | ⬜ | ◌ |
| TC-TT-018 | Verify today's row highlighted | Today=Wed, row 3 | 1. Load page on Wednesday | Wednesday row has light purple background | ⬜ | ◌ |
| TC-TT-019 | Verify conflict badge shown | Cell with has_conflict=true | 1. Load page 2. Find cell with conflict | Red "Conflict" badge top-right of cell | ⬜ | ◌ |
| TC-TT-020 | Verify lock icon shown | Cell with is_locked=true | 1. Load page 2. Find locked cell | 🔒 icon bottom-right | ⬜ | ◌ |
| TC-TT-021 | Verify subject legend | 10 unique subjects | 1. Scroll below grid 2. Observe legend | All 10 subjects listed with colour dot, name, code, weekly count (e.g. "4× / week") | ⬜ | ◌ |
| TC-TT-022 | Verify Today's Schedule section | Today has 6 non-break periods | 1. Scroll to "Today's Schedule" card | Table with 6 rows: Period, Time, Subject (coloured), Format, Teacher, Room | ⬜ | ◌ |
| TC-TT-023 | Verify Today's Schedule excludes breaks/free | Today has 2 breaks, 6 subjects | 1. Check Today's Schedule | Only 6 subject rows (break periods excluded) | ⬜ | ◌ |
| TC-TT-024 | Verify empty state: no student profile | User with no student relation | 1. Navigate to page | Empty state: "No Timetable Available — You are not enrolled in any class" | ⬜ | ◌ |
| TC-TT-025 | Verify empty state: no class section | Student with no class section | 1. Navigate to page | Empty state with noSession=true | ⬜ | ◌ |
| TC-TT-026 | Verify empty state: no timetable published | Student B with GENERATED but not PUBLISHED | 1. Navigate to page | Shows "Timetable Not Published — Your class timetable has not been published yet" | ⬜ | ◌ |
| TC-TT-027 | Verify timetable with DRAFT status excluded | Timetable status = DRAFT | 1. Load page 2. Check cells | No cells shown (DRAFT not in ACTIVE/GENERATED/PUBLISHED filter) | ⬜ | ◌ |
| TC-TT-028 | Verify Saturday shown when is_school_day=true | Saturday marked as school day | 1. Load page 2. Observe grid | Saturday row present with periods | ⬜ | ◌ |
| TC-TT-029 | Verify Sunday excluded | Sunday not in school days | 1. Load page 2. Observe grid | No Sunday row | ⬜ | ◌ |
| TC-TT-030 | Verify activity log recorded | Student A with valid timetable | 1. Navigate to page 2. Check activity_log | Entry: "Student viewed my timetable." with context | ⬜ | ◌ |
| TC-TT-031 | Verify page inaccessible without auth | No session | 1. Access page without login | Redirected to login | ⬜ | ◌ |

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
| GAP-TT-01 | No academic_session_id filter on timetable cells | Low | ⬜ |
| GAP-TT-02 | Break detection uses hardcoded codes (SBREAK/LUNCH/BREAK) | Medium | ⬜ |
| GAP-TT-04 | No week selector — only current timetable viewable | Low | ⬜ |
| GAP-TT-05 | Teacher names not hyperlinked to profile | Low | ⬜ |

## 9. Route Reference

| Method | Path | Route Name | Middleware |
|--------|------|------------|------------|
| GET | `/student-portal/my-timetable` | `student-portal.my-timetable` | `auth`, `verified` |

## 10. Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 31 | — |

---

*Test cases derived from controller code analysis, input requirement doc, and FRD cross-reference.*
