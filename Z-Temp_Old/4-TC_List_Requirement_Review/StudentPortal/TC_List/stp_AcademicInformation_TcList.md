# Academic Information — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Academic |
| **Feature** | Academic Information Hub — aggregated exam results, attendance, fee history |
| **URL(s)** | `GET /academic-information` |
| **Controller** | `StudentPortalController.academicInformation()` |
| **View** | `studentportal::academic-information.details` |
| **FRD Refs** | REQ-STP-003, BR-STP-001 |
| **Priority** | P1 (Should) |
| **Code Status** | 🟡 Implemented (profile tab complete; certifications tab stub) |
| **DB Tables** | `std_students`, `std_student_academic_sessions`, `std_student_attendance`, `lms_exam_results`, `lms_exams`, `lms_exam_papers`, `sch_subjects`, `fee_invoices`, `fee_student_assignments`, `fee_structure_details`, `fee_heads` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | Student must be authenticated via the standard `auth` guard |
| PC-02 | Student must have a linked `std_students` record |
| PC-03 | Student must have at least one `std_student_academic_sessions` record |
| PC-04 | Student must have at least one published `lms_exam_result` (optional — empty state) |
| PC-05 | Student must have attendance records for the current session (optional — zero fallback) |
| PC-06 | Student must have a `currentFeeAssignemnt` with invoices (optional — empty state) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | User loaded with `student`, `student.profile`, `student.addresses`, `student.studentGuardianJnts`, `student.sessions.classSection.class/section`, `student.sessions.academicSession`, `student.currentSession.academicSession`, `student.healthProfile`, `student.previousEducations`, `student.feeAssignment`, `student.currentFeeAssignemnt.feeStructure.details.head`, `student.currentFeeAssignemnt.invoices` | `academicInformation():336-350` |
| DL-02 | Attendance stats: total, present, absent, late, percentage for current academic session | `academicInformation():356-375` |
| DL-03 | Monthly attendance: grouped by year-month with status counts | `academicInformation():377-401` |
| DL-04 | Recent attendance: last 30 records ordered by date DESC | `academicInformation():397-401` |
| DL-05 | Published exam results: `ExamResult` where `is_published = true` with `exam.academicSession`, `exam.examType`, `examPaper.subject` | `academicInformation():404-412` |
| DL-06 | Results grouped by academic session with per-exam aggregates | `academicInformation():415-458` |
| DL-07 | Latest fee invoice: first record from invoices sorted by ID DESC | `academicInformation():462-466` |
| DL-08 | Older invoices: all invoices excluding latest, sorted by ID DESC | `academicInformation():465-466` |
| DL-09 | Activity log entry created on academic info view | `academicInformation():468-476` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Student with results in multiple sessions** | Published results in 2+ academic sessions with varying pass/fail mix |
| TD-02 | **Student with single session results** | Published results in only 1 session |
| TD-03 | **Student with no published results** | All results exist but none published |
| TD-04 | **Student with all-pass results** | Every result status = PASS |
| TD-05 | **Student with mixed pass/fail** | Some PASS, some FAIL results |
| TD-06 | **Student with attendance for current session** | Mix of Present, Absent, Late, Half Day, Short Leave |
| TD-07 | **Student with no attendance records** | `attendanceStats` defaults to all zeros |
| TD-08 | **Student with no fee assignment** | `currentFeeAssignemnt` returns null — empty fee section |
| TD-09 | **Student with paid invoices only** | All invoices status = Paid |
| TD-10 | **Student with mix of paid/unpaid invoices** | Multiple invoices with varying statuses |
| TD-11 | **Student with no current academic session** | `currentSession()` returns null — attendance section empty |
| TD-12 | **Multiple exams within one session** | 2+ distinct exam_ids within same academic session |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column/Field | Type | Constraints |
|-------|-------------|------|-------------|
| BC-DB-01 | `lms_exam_results.is_published` | BOOLEAN | 0 or 1 |
| BC-DB-02 | `lms_exam_results.result_status` | VARCHAR | PASS, FAIL |
| BC-DB-03 | `lms_exam_results.total_marks_possible` | DECIMAL | Positive |
| BC-DB-04 | `lms_exam_results.total_marks_obtained` | DECIMAL | Non-negative |
| BC-DB-05 | `lms_exam_results.percentage` | DECIMAL | 0–100 |
| BC-DB-06 | `std_student_attendance.status` | VARCHAR | Present, Absent, Late, Half Day, Short Leave |
| BC-DB-07 | `fee_invoices.status` | VARCHAR | paid, PAID, Paid, Published, Partially Paid, Overdue, Cancelled |

### BC-UI: UI Display Conditions

| BC ID | Condition | UI Behaviour |
|-------|-----------|-------------|
| BC-UI-01 | No published results | Academic stats show "No results published yet" |
| BC-UI-02 | All results PASS | Pass rate shows 100%; all green status badges |
| BC-UI-03 | Mixed pass/fail | Pass rate < 100%; some red FAIL badges |
| BC-UI-04 | No attendance records | Attendance shows 0/0/0/0 with "No attendance data" |
| BC-UI-05 | No fee assignment | Fee section shows "No fee invoices available" |
| BC-UI-06 | Invoice fully paid | Green "Paid" badge |
| BC-UI-07 | Invoice partially paid | Orange/Yellow "Partially Paid" badge |
| BC-UI-08 | Invoice overdue | Red "Overdue" badge |

---

## 6. Test Cases

| TC ID | Test Case | Pre-condition | Test Data | Test Steps | Expected Result | Status |
|-------|-----------|---------------|-----------|------------|----------------|--------|
| TC-ACA-001 | Academic info loads with results across multiple sessions | PC-01 to PC-06 satisfied | TD-01 | 1. Login as student with multi-session results<br>2. Navigate to `/academic-information` | All sessions shown in accordion; academic stats (avg, best, pass rate) calculated correctly | ⬜ |
| TC-ACA-002 | Academic stats calculated correctly (average, best, pass rate) | PC-04 satisfied | TD-01 | 1. Navigate to `/academic-information`<br>2. Check academic stats cards | Average % = mean of all result percentages; Best % = max percentage; Pass rate = (pass/total)*100 | ⬜ |
| TC-ACA-003 | Per-exam aggregates show correct totals and averages | PC-04 satisfied | TD-12 (multiple exams in one session) | 1. Navigate to `/academic-information`<br>2. Expand a session<br>3. Check each exam group | Each exam shows sum of max marks, sum of obtained, avg %, pass count, all-pass flag | ⬜ |
| TC-ACA-004 | Exam results table shows correct columns and data | PC-04 satisfied | TD-01 | 1. Navigate to `/academic-information`<br>2. Expand a session<br>3. Click an exam result table | Shows Subject, Paper Name, Max Marks, Obtained Marks, Percentage, Grade, PASS/FAIL status | ⬜ |
| TC-ACA-005 | Session summary shows correct totals | PC-04 satisfied | TD-01 | 1. Navigate to `/academic-information`<br>2. Expand a session<br>3. Check session summary | Shows total papers, total max, total obtained, avg %, best %, pass count, pass rate | ⬜ |
| TC-ACA-006 | Results with 100% pass rate show green indicators | PC-04 satisfied | TD-04 (all pass) | 1. Navigate to `/academic-information`<br>2. Check results section | All status badges green "PASS"; pass rate = 100% | ⬜ |
| TC-ACA-007 | Results with FAIL status show red indicators | PC-04 satisfied | TD-05 (mixed pass/fail) | 1. Navigate to `/academic-information`<br>2. Check results section | FAIL status badges shown in red | ⬜ |
| TC-ACA-008 | Attendance statistics display correct values | PC-05 satisfied | TD-06 | 1. Navigate to `/academic-information`<br>2. Check attendance section | Shows total days, present, absent, late, percentage rounded to 1 decimal | ⬜ |
| TC-ACA-009 | Monthly attendance trends displayed correctly | PC-05 satisfied | TD-06 | 1. Navigate to `/academic-information`<br>2. Check monthly attendance | Each month shows label (e.g., "Jan 2026"), total, present, percentage | ⬜ |
| TC-ACA-010 | Recent 30 attendance records listed correctly | PC-05 satisfied | TD-06 | 1. Navigate to `/academic-information`<br>2. Check recent attendance | Shows up to 30 records ordered by date descending | ⬜ |
| TC-ACA-011 | Latest invoice highlighted as separate card | PC-06 satisfied | TD-09 or TD-10 | 1. Navigate to `/academic-information`<br>2. Check fee section | Latest invoice shown first/prominent; older invoices listed below | ⬜ |
| TC-ACA-012 | Older invoices list shows correct descending order | PC-06 satisfied | TD-10 (3+ invoices) | 1. Navigate to `/academic-information`<br>2. Check older invoices list | Invoices sorted by ID descending (newest first among older) | ⬜ |
| TC-ACA-013 | No published results shows empty state | PC-04 fails | TD-03 | 1. Navigate to `/academic-information`<br>2. Check results section | Shows "No results published yet" or similar empty state | ⬜ |
| TC-ACA-014 | No attendance data shows empty state | PC-05 fails | TD-07 | 1. Navigate to `/academic-information`<br>2. Check attendance section | Shows 0/0/0/0 with "No attendance data" | ⬜ |
| TC-ACA-015 | No fee assignment shows empty state | PC-06 fails | TD-08 | 1. Navigate to `/academic-information`<br>2. Check fee section | Shows "No fee invoices available" | ⬜ |
| TC-ACA-016 | No current academic session shows empty state for session-scoped data | PC-03 fails | TD-11 | 1. Navigate to `/academic-information`<br>2. Check attendance and fee sections | Attendance and fee sections show appropriate empty states; exam results (cross-session) still shown | ⬜ |
| TC-ACA-017 | Activity log entry created on academic info view | PC-01, PC-02 satisfied | Any | 1. Navigate to `/academic-information`<br>2. Check activity_logs table | Entry exists with `message = 'Student viewed academic information.'` and correct context | ⬜ |
| TC-ACA-018 | Academic info accessible only to authenticated users | Varies | — | 1. Logout<br>2. Attempt to access `/academic-information` | Redirected to login page | ⬜ |
| TC-ACA-019 | Unpublished results not shown in results list | PC-04 satisfied | Mix of published + unpublished | 1. Navigate to `/academic-information`<br>2. Check results section | Only `is_published = true` results appear | ⬜ |
| TC-ACA-020 | Invoice paid/partially paid/overdue badges displayed correctly | PC-06 satisfied | TD-10 | 1. Navigate to `/academic-information`<br>2. Check fee section | Each invoice shows correct status badge: Paid (green), Partially Paid (orange), Overdue (red) | ⬜ |

---

## 7. Edge Cases

| # | Edge Case | Expected Behaviour |
|---|-----------|-------------------|
| EC-01 | Student has results but exam relationship is null (deleted exam) | Result row still shown with "Exam deleted" or similar placeholder |
| EC-02 | Exam result percentage is 0% or 100% | Displayed correctly as 0% or 100% |
| EC-03 | Attendance status has unexpected value (e.g., "PRS") | Displayed as "Unknown"; not counted in present/absent totals |
| EC-04 | Monthly attendance has month with 0 records | Month not shown in monthly trends |
| EC-05 | Fee invoice has null `paid_amount` or `balance_amount` | Treated as 0 for calculations |
| EC-06 | Student has 100+ attendance records | Recent attendance shows only last 30 records |
| EC-07 | Current session attendance has 0 total days | Attendance percentage shows 0% (division by zero guard) |
| EC-08 | `currentFeeAssignemnt` returns null due to typo in relationship name | Fee section gracefully shows empty state; no error thrown |

---

## 8. Test Execution Notes

| # | Note |
|---|------|
| TN-01 | This is a read-only screen — no forms to submit |
| TN-02 | Exam results are loaded from a dedicated `ExamResult` model (not from raw `lms_exam_results` table) — verify model scope |
| TN-03 | Attendance present count includes Present, Late, Half Day, and Short Leave — verify each status is counted correctly |
| TN-04 | Monthly attendance grouping uses raw SQL `YEAR(attendance_date)`, `MONTH(attendance_date)` — verify month boundaries (e.g., records spanning Dec–Jan across years) |
| TN-05 | Results grouped by session, then by exam — verify nested collection structure is correct |
| TN-06 | Session ordering: `sortKeysDesc` on session ID — not by date; verify this produces the correct order |

---

## 9. Test Data Setup Requirements

| # | Setup Requirement |
|---|-------------------|
| TDS-01 | Create a student with academic sessions in 2+ different school years |
| TDS-02 | Create published `lms_exam_results` across multiple sessions with mix of PASS and FAIL |
| TDS-03 | Create unpublished `lms_exam_results` (is_published = false) to verify exclusion |
| TDS-04 | Create `std_student_attendance` records with various statuses across multiple months |
| TDS-05 | Create `fee_invoices` linked to `fee_student_assignments` with varying payment statuses |
| TDS-06 | Create test data with zero records for each section (results, attendance, fee) |

---

## 10. Traceability Matrix

| TC ID | Maps To (FRD/BR) | Requirement |
|-------|-----------------|-------------|
| TC-ACA-001 to 007 | REQ-STP-003, BR-STP-001 | Exam results display and calculations |
| TC-ACA-008 to 010 | REQ-STP-003 | Attendance statistics display |
| TC-ACA-011 to 012 | REQ-STP-003 | Fee invoice display |
| TC-ACA-013 to 016 | REQ-STP-003 | Empty state handling |
| TC-ACA-017 | REQ-STP-003 | Activity logging |
| TC-ACA-018 | REQ-STP-001 | Authentication guard |
| TC-ACA-019 | REQ-STP-003 | Published-only results filter |
| TC-ACA-020 | REQ-STP-003 | Invoice status badges |
