# Dashboard — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Dashboard |
| **Feature** | Student Dashboard — central hub for academic, financial, and activity overview |
| **URL(s)** | `GET /dashboard` |
| **Controller** | `StudentPortalController.dashboard()` |
| **View** | `studentportal::dashboard.index` |
| **FRD Refs** | REQ-STP-002, BR-STP-001, BR-STP-019, BR-STP-021 |
| **Priority** | P0 (Must) |
| **Code Status** | ✅ Implemented |
| **DB Tables** | `std_students`, `std_student_academic_sessions`, `std_student_attendance`, `tt_timetable_cells`, `hmw_homeworks`, `hmw_homework_submissions`, `lms_exam_allocations`, `lms_exam_results`, `lms_quiz_quest_results`, `lms_quiz_allocations`, `lms_quest_allocations`, `fee_invoices`, `std_leave_applications`, `sys_notifications` |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | Student must be authenticated via the standard `auth` guard |
| PC-02 | Student must have a linked `std_students` record via `auth()->user()->student` |
| PC-03 | Student must have at least one active academic session (`std_student_academic_sessions` with `is_current = 1`) for full data display |
| PC-04 | Timetable cells must exist for today's day-of-week for the student's class-section (optional — empty state) |
| PC-05 | Homework records with `status = 'PUBLISHED'` must exist for the student's class-section (optional — empty state) |
| PC-06 | Exam allocations with future `scheduled_date` must exist for the student's class/section/student (optional — empty state) |
| PC-07 | Fee assignment (`currentFeeAssignemnt`) must exist on the student record for fee data (optional — zero fallback) |
| PC-08 | Student must have attendance records for the current academic session (optional — zero fallback) |
| PC-09 | Notifications must exist for the user via Laravel Notifiable (optional — empty state) |
| PC-10 | Leave applications must exist for the student in the current session (optional — zero fallback) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Student identity loaded via `auth()->user()` with `student` relationship | `dashboard():59` |
| DL-02 | Current academic session resolved via `student.currentSession()` with `classSection.class`, `classSection.section`, `academicSession` | `dashboard():81-83` |
| DL-03 | Attendance stats: total count + present count for current academic session | `dashboard():87-96` |
| DL-04 | Today's timetable cells: `TimetableCell` filtered by class-section, day-of-week, `is_break=false`, ordered by `period_ord` | `dashboard():104-117` |
| DL-05 | Pending homework: `Homework` PUBLISHED for class-section, excluding submitted IDs, ordered by `due_date`, limit 5 | `dashboard():120-129` |
| DL-06 | Upcoming exams: `ExamAllocation` active, future-dated, CLASS/SECTION/STUDENT allocation types, with `examPaper`, limit 5 | `dashboard():132-145` |
| DL-07 | Quiz/Quest counts: pending quiz count, pending quest count, total LMS results count | `dashboard():148-160` |
| DL-08 | Recent LMS results: `lms_quiz_quest_results` + `lms_exam_results` published, ordered by `created_at DESC`, limit 6 | `dashboard():185-232` |
| DL-09 | Pending online exams list: `ExamAllocation` not yet attempted, limit 5 | `dashboard():163-181` |
| DL-10 | Leave counts: total submitted + pending approval for current academic session | `dashboard():235-253` |
| DL-11 | Fee summary: total/paid/due from `currentFeeAssignemnt` invoices | `dashboard():256-263` |
| DL-12 | Notifications: `auth()->user()->notifications()->latest()->paginate(10)` | `dashboard():56` |
| DL-13 | Activity log entry created on dashboard view | `dashboard():266-274` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Student with complete data** | Has active session, attendance records, published homework, future exams, fee assignment with invoices, submitted leaves, and notifications |
| TD-02 | **Student with no academic session** | `currentSession()` returns null — all session-scoped widgets fallback to defaults |
| TD-03 | **Student with no attendance records** | Attendance stat shows 0% (neutral/grey) |
| TD-04 | **Student with no pending homework** | Homework section shows empty state |
| TD-05 | **Student with no upcoming exams** | Exams section shows empty state |
| TD-06 | **Student with no fee assignment** | Fee stat shows 0/— with no invoice data |
| TD-07 | **Student with no leave applications** | Leave counts show 0/0 |
| TD-08 | **Student with no notifications** | Notifications feed shows empty state |
| TD-09 | **Student with no timetable cells today** | Timetable widget shows "No classes scheduled for today" |
| TD-10 | **Student with attendance < 60%** | Red color on attendance stat card |
| TD-11 | **Student with attendance 60–75%** | Orange color on attendance stat card |
| TD-12 | **Student with attendance ≥ 75%** | Green color on attendance stat card |
| TD-13 | **Student with fee balance > 0** | Red color on fee due stat card |
| TD-14 | **Student with fee balance = 0** | Green color on fee due stat card |
| TD-15 | **Student with overdue homework** | Due date displayed in red for past-due homeworks |
| TD-16 | **Multiple academic sessions** | Only current session data displayed |
| TD-17 | **Student with only online exams** | Upcoming exams list shows Online badge |
| TD-18 | **Student with only offline exams** | Upcoming exams list shows Offline badge |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| BC ID | Column/Field | Type | Constraints |
|-------|-------------|------|-------------|
| BC-DB-01 | `std_students.id` | INT UNSIGNED | PK, NOT NULL |
| BC-DB-02 | `std_student_academic_sessions.is_current` | BOOLEAN/TINYINT | 0 or 1 |
| BC-DB-03 | `std_student_attendance.status` | VARCHAR | Values: Present, Absent, Late, Half Day, Short Leave, P |
| BC-DB-04 | `hmw_homeworks.due_date` | DATE | Can be past, today, or future |
| BC-DB-05 | `lms_exam_allocations.is_active` | BOOLEAN | 0 or 1 |
| BC-DB-06 | `lms_exam_allocations.scheduled_date` | DATE | Nullable |
| BC-DB-07 | `fee_invoices.balance_amount` | DECIMAL(10,2) | 0.00 or positive |
| BC-DB-08 | `fee_invoices.paid_amount` | DECIMAL(10,2) | 0.00 or positive |
| BC-DB-09 | `fee_invoices.total_amount` | DECIMAL(10,2) | Positive |
| BC-DB-10 | `fee_invoices.status` | VARCHAR | Values: paid, PAID, Paid, Published, Partially Paid, Overdue, etc. |
| BC-DB-11 | `tt_timetable_cells.is_break` | BOOLEAN | 0 = regular period, 1 = break |
| BC-DB-12 | `tt_timetable_cells.day_of_week` | INT UNSIGNED | 0–6 (Sunday–Saturday) |
| BC-DB-13 | `std_leave_applications.status` | VARCHAR | draft, cancelled, submitted, under_review, info_requested, doc_requested, approved, rejected |
| BC-DB-14 | `lms_exam_results.is_published` | BOOLEAN | 0 or 1 |
| BC-DB-15 | `lms_quiz_quest_results.is_published` | BOOLEAN | 0 or 1 |

### BC-UI: UI Display Conditions

| BC ID | Condition | UI Behaviour |
|-------|-----------|-------------|
| BC-UI-01 | Attendance < 60% | Stat card background/text: Red |
| BC-UI-02 | Attendance 60–75% | Stat card background/text: Orange |
| BC-UI-03 | Attendance ≥ 75% | Stat card background/text: Green |
| BC-UI-04 | Fee balance > 0 | Fee due stat card: Red |
| BC-UI-05 | Fee balance = 0 | Fee due stat card: Green |
| BC-UI-06 | Homework due_date < today | Due date text: Red |
| BC-UI-07 | No session | All session widgets: "No active session" message |
| BC-UI-08 | No timetable today | "No classes scheduled for today" |
| BC-UI-09 | No pending homework | Homework table: empty state |
| BC-UI-10 | No upcoming exams | Exams table: empty state |
| BC-UI-11 | No recent results | Results list: empty state |
| BC-UI-12 | No notifications | Notifications feed: empty state |

---

## 6. Test Cases

| TC ID | Test Case | Pre-condition | Test Data | Test Steps | Expected Result | Status |
|-------|-----------|---------------|-----------|------------|----------------|--------|
| TC-DASH-001 | Dashboard loads with all data for a student with complete profile | PC-01 to PC-10 all satisfied | TD-01 | 1. Login as student with complete data<br>2. Navigate to `/dashboard` | Dashboard renders with all stat cards, timetable, homework, exams, results, leaves, fee, and notifications populated | ⬜ |
| TC-DASH-002 | Dashboard loads for student with no active academic session | PC-01, PC-02 satisfied; PC-03 fails | TD-02 | 1. Login as student with no current session<br>2. Navigate to `/dashboard` | Profile card shows student info; all session-scoped widgets show "No active session" empty state; stat cards show 0/fallback | ⬜ |
| TC-DASH-003 | Attendance percentage displays correct value and color | PC-03 satisfied | TD-01 (attendance 87%) | 1. Navigate to dashboard<br>2. Check attendance stat card | Shows "87%" with green color (≥ 75%) | ⬜ |
| TC-DASH-004 | Attendance below 60% shows red indicator | PC-03 satisfied | TD-10 (attendance 45%) | 1. Set attendance to 45%<br>2. Navigate to dashboard | Attendance card shows "45%" in red | ⬜ |
| TC-DASH-005 | Attendance 60-75% shows orange indicator | PC-03 satisfied | TD-11 (attendance 68%) | 1. Set attendance to 68%<br>2. Navigate to dashboard | Attendance card shows "68%" in orange | ⬜ |
| TC-DASH-006 | Pending homework count shows correct value | PC-05 satisfied | TD-01 (3 pending homeworks) | 1. Navigate to dashboard<br>2. Check homework stat card | Stat card shows "3" | ⬜ |
| TC-DASH-007 | Pending homework table shows up to 5 entries with correct columns | PC-05 satisfied | TD-01 | 1. Navigate to dashboard<br>2. Check homework table | Shows up to 5 rows with Subject, Title, Due Date, Submit button | ⬜ |
| TC-DASH-008 | Overdue homework shows red due date | PC-05 satisfied | TD-15 (due date in past) | 1. Navigate to dashboard<br>2. Check overdue homework row | Due date text displayed in red | ⬜ |
| TC-DASH-009 | Upcoming exams count shows correct value | PC-06 satisfied | TD-01 (2 upcoming exams) | 1. Navigate to dashboard<br>2. Check exams stat card | Stat card shows "2" | ⬜ |
| TC-DASH-010 | Upcoming exams table shows up to 5 entries with correct columns | PC-06 satisfied | TD-01 | 1. Navigate to dashboard<br>2. Check exams table | Shows up to 5 rows with Exam Name, Subject, Date countdown, Duration, Mode badge | ⬜ |
| TC-DASH-011 | Online exam shows Online badge, offline shows Offline badge | PC-06 satisfied | TD-17 (online), TD-18 (offline) | 1. Navigate to dashboard<br>2. Check mode column | Online exams show "Online" badge; offline show "Offline" badge | ⬜ |
| TC-DASH-012 | Fee summary shows correct total/paid/due amounts | PC-07 satisfied | TD-01 (total 10000, paid 7500, due 2500) | 1. Navigate to dashboard<br>2. Check fee stat card | Shows Total: 10000, Paid: 7500, Due: 2500; Due amount in red | ⬜ |
| TC-DASH-013 | Fee due of zero shows green indicator | PC-07 satisfied | TD-14 (balance = 0) | 1. Set fee balance to 0<br>2. Navigate to dashboard | Fee due shows "0" in green | ⬜ |
| TC-DASH-014 | Today's timetable renders all non-break periods for current day | PC-04 satisfied | TD-01 | 1. Navigate to dashboard<br>2. Check timetable widget | Shows all periods with time slot, subject, teacher, room; break periods excluded | ⬜ |
| TC-DASH-015 | No timetable for today shows empty state | PC-04 fails | TD-09 | 1. Navigate to dashboard<br>2. Check timetable widget | Shows "No classes scheduled for today" | ⬜ |
| TC-DASH-016 | Recent results shows up to 6 combined quiz/quest/exam results | PC-03 satisfied | TD-01 (4 results) | 1. Navigate to dashboard<br>2. Check results list | Shows up to 6 results with correct type badges (Quiz/Quest/Exam), scores, percentages, pass/fail | ⬜ |
| TC-DASH-017 | Pass/fail status correctly displayed for each result | PC-03 satisfied | TD-01 (mix of pass/fail) | 1. Navigate to dashboard<br>2. Check results pass/fail badges | Pass results show green "Pass" badge; fail results show red "Fail" badge | ⬜ |
| TC-DASH-018 | Leave counts show total applied and pending approval | PC-09 satisfied | TD-01 (3 total, 1 pending) | 1. Navigate to dashboard<br>2. Check leave stat card | Shows "3" applied, "1" pending | ⬜ |
| TC-DASH-019 | Notifications feed loads with pagination | PC-09 satisfied | TD-01 | 1. Navigate to dashboard<br>2. Check notifications feed | Shows notifications with read/unread indicators, relative timestamps; pagination controls visible if >10 | ⬜ |
| TC-DASH-020 | Quick navigation panel links to all sub-modules | Any | Any | 1. Navigate to dashboard<br>2. Click each quick-nav link | Each link navigates to the correct sub-module route | ⬜ |
| TC-DASH-021 | Profile card shows correct student details | PC-02 satisfied | TD-01 | 1. Navigate to dashboard<br>2. Check profile card | Shows avatar, name, class-section, roll number, academic session | ⬜ |
| TC-DASH-022 | Activity log entry created on dashboard view | PC-01, PC-02 satisfied | Any | 1. Navigate to dashboard<br>2. Check activity_logs table | Entry exists with `message = 'Student viewed the dashboard.'` and correct context | ⬜ |
| TC-DASH-023 | Dashboard accessible only to authenticated users | Varies | — | 1. Logout<br>2. Attempt to access `/dashboard` | Redirected to login page | ⬜ |
| TC-DASH-024 | Student without student record sees fallback | PC-01 satisfied; PC-02 fails | auth user not linked to student | 1. Login as user with no student record<br>2. Navigate to `/dashboard` | Page loads with all variables defaulting to 0/empty/collect(); no call to student-dependent queries | ⬜ |

---

## 7. Edge Cases

| # | Edge Case | Expected Behaviour |
|---|-----------|-------------------|
| EC-01 | Student has attendance records with NULL status | NULL → displayed as "Not Marked"; not counted in present/total |
| EC-02 | Student has homework with no submission records | All PUBLISHED homework counted as pending |
| EC-03 | Exam allocation scheduled_date is NULL | Filtered by `examPaper.exam.start_date` instead |
| EC-04 | Student has fee assignment but no invoices | Fee stat shows 0 total, 0 paid, 0 due |
| EC-05 | Student has 100% attendance | Shows "100%" in green |
| EC-06 | Student has 0% attendance | Shows "0%" in red |
| EC-07 | Multiple homework submissions for same homework | Only counted as submitted (one submission per homework) |
| EC-08 | Today is a holiday with no timetable cells | Shows "No classes scheduled for today" |
| EC-09 | Student has more than 10 notifications | Pagination controls shown at bottom of notifications feed |
| EC-10 | `currentFeeAssignemnt` relationship returns null | Fee stat falls back to zero values without error |

---

## 8. Test Execution Notes

| # | Note |
|---|------|
| TN-01 | Dashboard is read-only — no forms to submit; testing focuses on data accuracy, conditional display, and empty states |
| TN-02 | Attendance colours (red/orange/green) must be verified for boundary values (59%, 60%, 75%, 76%) |
| TN-03 | Timetable widget excludes `is_break = true` cells — verify with a day that has mixed regular and break periods |
| TN-04 | Pending homework query excludes IDs present in `hmw_homework_submissions` — verify with a mix of submitted and unsubmitted homework |
| TN-05 | Fee summary derived from `currentFeeAssignemnt.invoices` — verify with invoices in different statuses (paid, unpaid, overdue) |

---

## 9. Test Data Setup Requirements

| # | Setup Requirement |
|---|-------------------|
| TDS-01 | Create a student with complete profile, active academic session, attendance records (mix of Present/Absent/Late), published homework, future exam allocations, fee assignment with invoices, leave applications, and notifications |
| TDS-02 | Create a student with no active academic session |
| TDS-03 | Create attendance data at each threshold (<60%, 60-75%, ≥75%) |
| TDS-04 | Create homework records with due dates in past, today, and future |
| TDS-05 | Create exam allocations with Online and Offline modes |
| TDS-06 | Create fee invoices with different balance amounts (zero and non-zero) |
| TDS-07 | Create timetable cells for today with mix of regular and break periods |
| TDS-08 | Create lms_quiz_quest_results and lms_exam_results with mix of pass/fail |

---

## 10. Traceability Matrix

| TC ID | Maps To (FRD/BR) | Requirement |
|-------|-----------------|-------------|
| TC-DASH-001 | REQ-STP-002 | Dashboard loads with all data |
| TC-DASH-002 | REQ-STP-002 | Dashboard handles no-session state |
| TC-DASH-003 to 005 | REQ-STP-002 | Attendance display with color thresholds |
| TC-DASH-006 to 008 | REQ-STP-002, BR-STP-019 | Pending homework display |
| TC-DASH-009 to 011 | REQ-STP-002, BR-STP-021 | Upcoming exams display |
| TC-DASH-012 to 013 | REQ-STP-002 | Fee summary display |
| TC-DASH-014 to 015 | REQ-STP-002 | Today's timetable display |
| TC-DASH-016 to 017 | REQ-STP-002 | Recent results display |
| TC-DASH-018 | REQ-STP-002 | Leave counts display |
| TC-DASH-019 | REQ-STP-002 | Notifications feed |
| TC-DASH-020 | REQ-STP-002 | Quick navigation |
| TC-DASH-021 | REQ-STP-002 | Profile card |
| TC-DASH-022 | REQ-STP-002 | Activity logging |
| TC-DASH-023 | REQ-STP-001 | Authentication guard |
| TC-DASH-024 | BR-STP-001 | Student-less user fallback |
