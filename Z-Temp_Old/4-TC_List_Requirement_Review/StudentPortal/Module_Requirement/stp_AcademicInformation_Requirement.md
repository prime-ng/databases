# StudentPortal Academic Information — Business Requirements

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Academic |
| **Feature** | Academic Information Hub — aggregated academic history, attendance, fee, marksheets |
| **URL(s)** | `GET /academic-information` |
| **Controller** | `StudentPortalController.academicInformation()` — single method |
| **View** | `studentportal::academic-information.details` |
| **FRD Refs** | REQ-STP-003, BR-STP-001 |
| **Priority** | P1 (Should) |
| **Code Status** | 🟡 Implemented (profile tab complete; certifications tab stub) |

---

## 2. What This Screen Does

The Academic Information Hub aggregates the student's complete academic data across all enrolled sessions. It presents published exam results grouped by academic session with per-exam aggregates (total marks, average percentage, pass/fail), summary attendance benchmarks for the current session (total days, present/absent/late counts, monthly trends), and a fee invoice overview showing the latest invoice and older invoices with amounts and payment status. This is the most data-intensive page in the portal, loading results from three separate modules.

---

## 3. When This Screen Is Used

- At the end of a term to review exam results and calculate overall performance
- During parent-teacher meetings to show attendance trends and fee status
- When students need a consolidated view of their academic history across multiple sessions
- To access marksheets for college applications or scholarship forms
- To verify fee payment history alongside academic records

---

## 4. Default Data Load

When the user navigates to the Academic Information page, `StudentPortalController@academicInformation()` executes the following data fetches:

### Eager Loads

| Data | Source | Relationships Loaded |
|------|--------|---------------------|
| User + Student | `auth()->user()` | `student`, `student.profile`, `student.addresses`, `student.studentGuardianJnts` |
| Academic Sessions | `student.sessions` | `classSection.class`, `classSection.section`, `academicSession` |
| Current Session | `student.currentSession` | `academicSession` |
| Health Profile | `student.healthProfile` | — |
| Previous Education | `student.previousEducations` | — |
| Fee Assignment | `student.feeAssignment`, `student.currentFeeAssignemnt` | `feeStructure.details.head`, `invoices` |

### Attendance Stats (Current Academic Session)

| Metric | Source | Calculation |
|--------|--------|-------------|
| Total Days | `std_student_attendance` | Count for student + current session |
| Present Days | `std_student_attendance` | Count where status IN (Present, Late, Half Day, Short Leave) |
| Absent Days | `std_student_attendance` | Count where status = Absent |
| Late Days | `std_student_attendance` | Count where status = Late |
| Percentage | — | `(Present / Total) * 100` rounded to 1 decimal |

### Monthly Attendance Trends

| Metric | Source | Detail |
|--------|--------|--------|
| Monthly Breakdown | `std_student_attendance` | Grouped by YEAR(attendance_date), MONTH(attendance_date), status |
| Monthly Percentage | — | `(Present / Total) * 100` per month |

### Recent Attendance (Last 30 Records)

| Field | Source |
|-------|--------|
| Attendance records | `std_student_attendance` | Ordered by `attendance_date DESC`, limit 30 |

### Published Exam Results (All Sessions)

| Data | Source | Detail |
|------|--------|--------|
| All Published Results | `lms_exam_results` | Where `student_id` matches, `is_published = true`, with `exam.academicSession`, `exam.examType`, `examPaper.subject` |
| Grouped by Session | Collection | Results grouped by `exam.academic_session_id`, sorted by session start date DESC |
| Per-Exam Aggregates | Collection | Sum of `total_marks_possible`, `total_marks_obtained`, average %, pass count, all-pass flag |
| Session Summary | Collection | Session total results, pass count, average %, best %, pass rate |

### Fee Invoices

| Data | Source | Detail |
|------|--------|--------|
| Latest Invoice | `currentFeeAssignemnt.invoices` | Sorted by `id DESC`, first record |
| Older Invoices | `currentFeeAssignemnt.invoices` | All invoices excluding the latest, sorted by `id DESC` |

---

## 5. UI Components / Screen Structure

| Component | Description |
|-----------|-------------|
| **Academic Stats Summary** | Session average %, best percentage, pass rate — displayed as KPI cards |
| **Session Results Archive** | Accordion selector for each academic session; per-exam results tables with subject, paper, marks, percentage, grade, status |
| **Attendance Trend Metrics** | Total days, present, absent, late counts and overall % for current session; monthly trend chart/table |
| **Fee Invoice Overview** | Latest invoice card + older invoices table with invoice number, description, total, paid, balance, actions |
| **Certifications Tab** | (Planned — stub only) Placeholder for certifications and achievements |

---

## 6. Data Tables / Fields Displayed

### Academic Stats Cards

| Metric | Formula |
|--------|---------|
| Session Average | Mean percentage across all published results in session |
| Best Percentage | Highest individual percentage achieved |
| Pass Rate | `(Passed results / Total results) * 100` |

### Exam Results Table (Per Exam)

| Column | Detail |
|--------|--------|
| Subject | `examPaper.subject.name` |
| Paper Name | `examPaper.title` |
| Max Marks | `total_marks_possible` |
| Obtained Marks | `total_marks_obtained` |
| Percentage | `percentage` (calculated) |
| Grade | `grade_obtained` |
| Status | PASS / FAIL badge |

### Session Summary Info

| Field | Detail |
|-------|--------|
| Total Papers | Count of results in session |
| Total Max Marks | Sum of all `total_marks_possible` |
| Total Obtained | Sum of all `total_marks_obtained` |
| Average % | `(Total Obtained / Total Max) * 100` |
| Best % | Highest result percentage |
| Pass Count | Number of results with PASS status |
| Pass Rate | `(Pass Count / Total Papers) * 100` |

### Attendance Statistics

| Metric | Value |
|--------|-------|
| Total Days | Count of attendance records |
| Present Days | Present + Late + Half Day + Short Leave |
| Absent Days | Status = Absent |
| Late Days | Status = Late |
| Percentage | `(Present / Total) * 100` rounded to 1 decimal |

### Fee Invoice Table

| Column | Detail |
|--------|--------|
| Invoice No | `invoice_no` |
| Description | `description` or fee head names |
| Total Amount | `total_amount` |
| Paid Amount | `paid_amount` |
| Balance | `balance_amount` |
| Status | Paid/Partially Paid/Overdue badge |
| Action | View Invoice link |

---

## 7. Business Rules and Conditions

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-STP-001 | All data must belong to the authenticated student | Data isolation through `auth()->user()->student` chain |
| — | Only published results shown | `is_published = true` filter on `ExamResult` query |
| — | Attendance includes Present, Late, Half Day, Short Leave as "present" | Present count aggregates multiple status values |
| — | Monthly attendance grouped by year-month | Raw SQL `YEAR(attendance_date)` and `MONTH(attendance_date)` grouping |
| — | Fee invoices sorted by ID descending (newest first) | `sortByDesc('id')` |
| — | Latest invoice separated from older invoices | First record = latest; all others = older |
| — | Results grouped by academic session | `groupBy('exam.academic_session_id')` |
| — | Sessions without results not shown | Only sessions containing published results appear |

---

## 8. Workflow Steps

**Typical Academic Information Session:**
1. Student navigates to Academic Information from the dashboard or navigation
2. System loads all published exam results, current-session attendance, and fee invoices
3. Student sees academic stats summary at the top (average, best, pass rate)
4. Student clicks on a session accordion to expand results for a specific academic year
5. Within a session, per-exam tables show subject-wise marks, percentages, and grades
6. Student reviews attendance trends — monthly breakdown and recent 30-day log
7. Student scrolls to fee invoice section to verify latest invoice and payment status

---

## 9. Example Scenario

Anika, a Class 10 student, opens Academic Information at the end of Term 1. She sees:
- **Academic Stats:** Session Average: 82.5%, Best: 95% (Mathematics), Pass Rate: 100%
- **Session 2025–2026:**
  - **Term 1 Exam:** 5 subjects — Mathematics 95/100 (A+), Science 88/100 (A), English 78/100 (B+), History 82/100 (A), Hindi 70/100 (B). Total: 413/500 (82.6%)
  - **Mid-Term:** 5 subjects — Total: 401/500 (80.2%)
- **Attendance:** Total 87 days, Present 78 (89.7%), Absent 6, Late 3
- **Fee Invoice:** INV-2025-001: ₹25,000 total, ₹25,000 paid (Fully Paid)

---

## 10. Related Screens

- **Dashboard** (`/dashboard`) — Summary stats for attendance, homework, exams
- **My Attendance** (`/my-attendance`) — Detailed attendance calendar
- **Results** (`/results`) — All exam/quiz/quest results in unified view
- **Fee Summary** (`/fee-summary`) — Detailed fee breakdown
- **Progress Card** (`/progress-card`) — HPC-generated progress report

---

## 11. Requirements (MUST)

- The system MUST display academic stats summary: session average %, best percentage, and pass rate
- The system MUST display published exam results grouped by academic session with per-exam tables
- The system MUST show per-exam aggregates: total max marks, total obtained, average %, pass count, all-pass flag
- The system MUST display session-level summary: total papers, pass count, pass rate, average %, best %
- The system MUST display attendance statistics for the current session: total days, present, absent, late, percentage
- The system MUST display monthly attendance trends with percentage per month
- The system MUST display the latest fee invoice with total, paid, and balance amounts
- The system MUST display older fee invoices in a list sorted by newest first
- The system MUST scope all data to the authenticated student (BR-STP-001)
- The system MUST only display published exam results (`is_published = true`)

---

## 12. Who Can Access This Screen

| Role | Access | Notes |
|------|--------|-------|
| Student | ✅ Full | Authenticated via standard auth guard |
| Parent | 🟡 Planned | Parent portal mode in development |
| Teacher/Admin | ❌ No | Separate academic reporting interfaces |

---

## 13. How This Screen Works — Logic Flow (Non-Technical)

When a student opens Academic Information, the system loads their user record along with all related student data, including their complete academic session history. It then performs three main data fetches:

1. **Exam Results:** The system looks up all published exam results for the student from `lms_exam_results`. It groups these results by academic session (school year). For each session, it further groups results by exam (e.g., Term 1, Mid-Term, Final). For each exam, it calculates total marks obtained, total possible marks, average percentage, and whether all papers were passed. Session-level summaries include overall pass rate and best percentage.

2. **Attendance:** The system counts attendance records for the current academic session, categorising them as Present (including Present, Late, Half Day, Short Leave), Absent, or Late. It also breaks attendance down by month to show trends. The most recent 30 attendance records are listed for quick review.

3. **Fee Invoices:** The system fetches the student's current fee assignment and its invoices. The most recent invoice is highlighted separately, while older invoices are listed below in descending order.

---

## 14. Validate Before Save

No data entry occurs on this screen. It is a read-only information hub with no forms to validate.

---

## 15. Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| No published results for any session | Academic stats show "No results published yet" | Informational |
| No attendance records for current session | Attendance section shows 0/0/0/0 with "No attendance data" | Informational |
| No fee assignment or invoices | Fee section shows "No fee invoices available" | Informational |
| Student has no current academic session | Attendance and fee sections show empty state | Informational |
| `currentFeeAssignemnt` returns null | Fee section falls back to empty state without error | System fallback |

---

## 16. Dependencies

### Source Tables Read

| Table | Module | Data Used |
|-------|--------|-----------|
| `std_students` | StudentProfile | Core student identity |
| `std_student_details` | StudentProfile | Personal details |
| `std_student_addresses` | StudentProfile | Addresses |
| `std_student_guardian_jnt` | StudentProfile | Guardian junctions |
| `std_student_academic_sessions` | StudentProfile | Academic session history |
| `std_student_health_profiles` | StudentProfile | Health profile (loaded for completeness) |
| `std_student_previous_educations` | StudentProfile | Previous school data |
| `std_student_attendance` | StudentProfile | Attendance records |
| `lms_exam_results` | LmsExam | Published exam results |
| `lms_exams` | LmsExam | Exam metadata (title, type, academic session) |
| `lms_exam_papers` | LmsExam | Paper metadata |
| `sch_subjects` | SchoolSetup | Subject names |
| `fee_invoices` | StudentFee | Fee invoices |
| `fee_student_assignments` | StudentFee | Fee assignment junction |
| `fee_structure_details` | StudentFee | Fee structure breakdown |
| `fee_heads` | StudentFee | Fee head names |

### Models/Relationships Used

- `auth()->user()->student` — Core student identity
- `student.currentSession()` — Current academic session resolver
- `student.currentFeeAssignemnt` — Fee assignment (typo in name)
- `ExamResult` — Published exam results with `exam.academicSession`, `exam.examType`, `examPaper.subject`
- `StudentAttendance` — Attendance records with status filtering
