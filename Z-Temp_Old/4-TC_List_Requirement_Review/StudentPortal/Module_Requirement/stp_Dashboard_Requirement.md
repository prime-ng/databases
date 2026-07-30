# StudentPortal Dashboard — Business Requirements

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | StudentPortal (STP) |
| **Tab Group** | Dashboard |
| **Feature** | Student Dashboard — central hub for academic, financial, and activity overview |
| **URL(s)** | `GET /dashboard` |
| **Controller** | `StudentPortalController.dashboard()` — single method, ~230 lines |
| **View** | `studentportal::dashboard.index` |
| **FRD Refs** | REQ-STP-002, BR-STP-001, BR-STP-019, BR-STP-021 |
| **Priority** | P0 (Must) |
| **Code Status** | ✅ Implemented |

---

## 2. What This Screen Does

The Dashboard serves as the central landing page for the StudentPortal. It provides a high-level summary of the student's active academic session, attendance rate, pending homework, upcoming exams, fee status, leave counts, today's timetable, recent LMS results, and a feed of notifications. The dashboard also includes a profile card, quick-navigation panel, and contextual action links to sub-modules.

---

## 3. When This Screen Is Used

- Every time a student logs into the portal — the dashboard is the default landing page
- Throughout the school day to check today's timetable, pending homework, and upcoming exams
- To get a quick snapshot of attendance percentage, fee due amount, and leave status
- To access all portal sub-modules via the quick-navigation panel

---

## 4. Default Data Load

When the user navigates to the Dashboard, `StudentPortalController@dashboard()` executes the following data fetches (all scoped to `auth()->user()->student`):

### Stat Cards (7 KPIs)

| Stat | Database Source | Calculation |
|------|----------------|-------------|
| Attendance % | `std_student_attendance` | `(Present count / Total count) * 100` for current academic session |
| Pending Homework Count | `hmw_homeworks` filtered against `hmw_homework_submissions` | Count of PUBLISHED homework for class-section not yet submitted by student |
| Upcoming Exams Count | `lms_exam_allocations` | Count of future-dated allocations matching CLASS/SECTION/STUDENT type |
| Fee Due Amount | `fee_invoices` via `currentFeeAssignemnt` | Sum of `balance_amount` across unpaid invoices |
| Fee Paid Amount | `fee_invoices` | Sum of `paid_amount` |
| Fee Total | `fee_invoices` | Sum of `total_amount` |
| Pending Quiz Count | `lms_quiz_allocations` vs `lms_quiz_quest_results` | Allocated quizzes not yet completed |
| Pending Quest Count | `lms_quest_allocations` vs `lms_quiz_quest_results` | Allocated quests not yet completed |
| Total LMS Results | `lms_quiz_quest_results` + `lms_exam_results` | Combined result count |
| Leave Count | `std_leave_applications` | Submitted leave applications (excluding Draft/Cancelled) |
| Pending Leave Count | `std_leave_applications` | Leave apps in Submitted/Under Review/Info Requested/Doc Requested |

### Data Widgets

| Widget | Source | Display Limit |
|--------|--------|---------------|
| Today's Timetable | `TimetableCell` filtered by day-of-week, class-section, `is_break = false` | All today cells ordered by `period_ord` |
| Pending Homework Table | `Homework` PUBLISHED, due-date ordered, excluding submitted IDs | Up to 5 entries |
| Upcoming Exams Table | `ExamAllocation` future-dated, sorted by scheduled date | Up to 5 entries |
| Recent LMS Results | `lms_quiz_quest_results` + `lms_exam_results`, published, ordered by created_at DESC | Up to 6 entries |
| Pending Online Exams List | `ExamAllocation` not yet attempted, future-dated | Up to 5 entries |
| Notifications Feed | `auth()->user()->notifications()` | Paginated 10 per page |

### Profile Card

| Field | Source |
|-------|--------|
| Student avatar/name | `auth()->user()` / `auth()->user()->student` |
| Class & Section | `student.currentSession()->classSection` |
| Roll Number | `student` record |
| Academic Session | `student.currentSession()->academicSession` |

---

## 5. UI Components / Screen Structure

| Component | Description |
|-----------|-------------|
| **Student Profile Card** | Avatar, name, class-section, roll number, session with "Account Settings" link |
| **Stat Cards Block** | 7 stat cards in a responsive grid: Attendance %, Pending Homework, Upcoming Exams, Fee Due, Leaves Applied, Pending Leaves, Pending Quizzes/Quests |
| **Quick Navigation Panel** | Icon-list links: My Attendance, My Timetable, My Teachers, My Learning, Exam Schedule, My Results, Fee & Payments, Notifications |
| **Today's Timetable Widget** | Horizontal list of today's periods: time slot, subject, teacher, room |
| **Pending Homework Table** | Up to 5 rows: Subject (color dot), Title, Due Date (red if overdue), Submit button |
| **Upcoming Exams Table** | Up to 5 rows: Exam Name, Subject, Date (countdown), Duration (min), Mode badge |
| **Recent Results List** | Up to 6 items: Assessment Type badge, Title, Score/Max, %, Pass/Fail badge |
| **Notifications Feed** | Recent notifications with read/unread indicator and relative timestamps |

---

## 6. Data Tables / Fields Displayed

### Stat Card Color Logic

| Stat | Thresholds | Colors |
|------|-----------|--------|
| Attendance % | < 60% / 60–75% / ≥ 75% | Red / Orange / Green |
| Fee Due | balance > 0 / balance == 0 | Red / Green |
| Homework Due Date | past due date | Red date text |

### Timetable Cell Fields

| Field | Source |
|-------|--------|
| Time Slot / Period Name | `period` relationship |
| Subject Name | `activity.subject.name` |
| Teacher Name | `activity.teachers.teacher.user.name` or `teachers.user.name` |
| Room Name | `room.name` |

### Pending Homework Columns

| Column | Detail |
|--------|--------|
| Subject | Subject name with color indicator dot |
| Homework Title | `homework.title` |
| Due Date | `homework.due_date` (red if overdue) |
| Actions | "Submit" button linking to homework detail |

### Upcoming Exams Columns

| Column | Detail |
|--------|--------|
| Exam Name | `examPaper.exam.title` |
| Subject | `examPaper.subject.name` |
| Date | `scheduled_date` with relative countdown |
| Duration (min) | `examPaper.duration_minutes` or `examPaper.exam.duration` |
| Mode | Badge: Online/Offline |

### Recent Results Fields

| Field | Detail |
|-------|--------|
| Assessment Type | Badge: Quiz (#6c5ce7) / Quest (#0984e3) / Exam (#00b894) |
| Title | Quiz/Quest title or "Exam Title — Paper Title" |
| Score | `obtained / max` |
| Percentage | `percentage` |
| Status | Pass/Fail badge |

---

## 7. Business Rules and Conditions

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-STP-001 | All data must belong to the authenticated student | Data isolation through `auth()->user()->student` chain |
| BR-STP-019 | Dashboard must show pending homework count | Count of PUBLISHED homework for class-section minus submitted IDs |
| BR-STP-021 | Dashboard must show upcoming exam count | Count of future-dated active exam allocations for student's class-section |
| — | Today's timetable excludes break periods | `is_break = true` cells filtered out |
| — | Attendance % rounded to nearest integer | `round(($present / $total) * 100)` |
| — | Quiz/Quest completion checked via results table | `lms_quiz_quest_results` with matching assessment_type |
| — | Fee data sourced from `currentFeeAssignemnt` invoices | Falls back to zeros if no assignment exists |
| — | Notifications paginated at 10 per page | `latest()->paginate(10)` |

---

## 8. Workflow Steps

**Typical Dashboard Session:**
1. Student logs in → redirected to `/dashboard`
2. System resolves student's current academic session (`std_student_academic_sessions`)
3. System loads all stat cards, widgets, and notifications in a single request
4. Student scans stat cards for attendance %, pending homework, upcoming exams, fee due
5. Student checks today's timetable to plan their day
6. Student clicks a pending homework "Submit" button → navigates to homework detail
7. Student clicks an upcoming exam → navigates to exam schedule
8. Student clicks quick-navigation → navigates to sub-module

**Empty State:**
- If the student has no active academic session, all session-scoped widgets display empty states
- Stat cards show 0 / `—` where no data exists
- Today's timetable shows "No classes scheduled for today"

---

## 9. Example Scenario

Ravi, a Class 10-B student at Sunshine International School, logs into the StudentPortal. The dashboard shows:
- **Profile Card:** Ravi Sharma, Class 10 - Section B, Roll No. 25, Session 2025–2026
- **Attendance:** 87% (green — good)
- **Pending Homework:** 3 (Mathematics, Science, English)
- **Upcoming Exams:** 2 (Mid-Term Science on 15 Aug — in 3 days, Math Pre-Board on 22 Aug)
- **Fee Due:** ₹2,500 (red indicator)
- **Leave Applied:** 1 (Pending approval)
- **Today's Timetable:** 8 periods — Physics, Chemistry, Math, Lunch, English, History, PE, Library
- **Notifications:** "Your Science homework has been graded" (2 hours ago)

Ravi notices a pending homework for Mathematics due today. He clicks "Submit" and navigates to the homework detail page to upload his assignment.

---

## 10. Related Screens

- **My Attendance** (`/my-attendance`) — Detailed attendance calendar and monthly trends
- **My Timetable** (`/my-timetable`) — Full weekly timetable view
- **My Learning** (`/my-learning`) — LMS quizzes, quests, and learning content
- **Exam Schedule** (`/exam-schedule`) — Full exam schedule with upcoming/today/concluded/ongoing tabs
- **My Results** (`/results`) — All published exam/quiz/quest results
- **Fee Summary** (`/fee-summary`) — Detailed fee invoice breakdown
- **Apply Leave** (`/apply-leave`) — Full leave application history and creation
- **Account Settings** (`/account`) — Profile and account management

---

## 11. Requirements (MUST)

- The system MUST display the student's profile card with avatar, name, class-section, roll number, and academic session
- The system MUST calculate and display attendance percentage for the current academic session with color-coded thresholds (Red < 60%, Orange 60–75%, Green ≥ 75%)
- The system MUST display the count of pending homework assignments not yet submitted by the student
- The system MUST display the count of upcoming exams scheduled for the student's class-section
- The system MUST display fee due amount (sum of invoice balances) with red/green indicator
- The system MUST display leave counts (total applied and pending approval)
- The system MUST render today's timetable showing time slots, subjects, teachers, and rooms (excluding break periods)
- The system MUST display a pending homework table (up to 5 entries) with subject, title, due date, and submit action
- The system MUST display an upcoming exams table (up to 5 entries) with exam name, subject, date countdown, duration, and mode
- The system MUST display recent LMS results (up to 6) with assessment type badge, title, score, percentage, and pass/fail status
- The system MUST display a notifications feed with read/unread indicators and relative timestamps
- The system MUST provide a quick-navigation panel linking to all major portal sub-modules with contextual counts

---

## 12. Who Can Access This Screen

| Role | Access | Notes |
|------|--------|-------|
| Student | ✅ Full | Authenticated via standard auth guard |
| Parent | 🟡 Limited | Parent portal mode in development — child context required |
| Teacher/Admin | ❌ No | Not applicable — teacher and admin have separate dashboards |

**Note:** `EnsureTenantHasModule` middleware is not applied to this route (P0 gap).

---

## 13. How This Screen Works — Logic Flow (Non-Technical)

When a student opens the dashboard, the system first identifies the student's current academic session (the active school year and class-section they are enrolled in). Using this session as a filter, the system runs several database queries:

- Counts attendance records where the status is "Present", "P", or "present" vs total records → calculates percentage
- Counts homework assignments published for the student's class-section that the student hasn't submitted yet
- Counts exam allocations with future dates assigned to the student's class, section, or directly to the student
- Sums up fee invoice totals, paid amounts, and remaining balances from the student's current fee assignment
- Counts leave applications that are submitted and pending
- Fetches today's timetable cells (non-break periods) with subject, teacher, and room details
- Fetches the 5 most urgent pending homework items
- Fetches the 5 nearest upcoming exams
- Fetches the 6 most recent LMS results (quiz, quest, exam) with scores and pass/fail status
- Fetches the student's recent notifications

All this data is compiled into a single page view. If the student has no active session, most widgets show empty states gracefully.

---

## 14. Validate Before Save

No data entry occurs on this screen. It is a read-only dashboard with no forms to validate.

---

## 15. Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Student has no active academic session | Widgets display empty state with "No active session" | Informational |
| No timetable cells for today | "No classes scheduled for today" | Empty state |
| No pending homework | Pending homework section shows empty state | Informational |
| No upcoming exams | Upcoming exams section shows empty state | Informational |
| No recent results | Recent results section shows empty state | Informational |
| No fee assignment | Fee stat card shows 0/— | Informational |
| Database query failure | Generic system error (handled by global exception handler) | System error |

---

## 16. Dependencies

### Source Tables Read

| Table | Module | Data Used |
|-------|--------|-----------|
| `std_student_academic_sessions` | StudentProfile | Current session resolution |
| `std_student_attendance` | StudentProfile | Attendance stats |
| `tt_timetable_cells` | TimetableFoundation | Today's timetable |
| `hmw_homeworks` | LmsHomework | Pending homework |
| `hmw_homework_submissions` | LmsHomework | Submitted homework IDs |
| `lms_exam_allocations` | LmsExam | Upcoming exams |
| `lms_exam_results` | LmsExam | Recent exam results |
| `lms_quiz_quest_results` | LmsQuiz/LmsQuests | Quiz/Quest results |
| `lms_quiz_allocations` | LmsQuiz | Quiz allocations |
| `lms_quest_allocations` | LmsQuests | Quest allocations |
| `fee_invoices` | StudentFee | Fee summary |
| `std_leave_applications` | StudentProfile | Leave counts |
| `sys_notifications` | Notification | Notifications feed |

### Models/Relationships Used

- `auth()->user()->student` — Core student identity
- `student.currentSession()` — Academic session resolver
- `student.currentFeeAssignemnt` — Fee assignment (typo in name)
- `ExamAllocation` — Exam allocations with `examPaper.exam`, `examPaper.subject`
- `Homework` — Homework with `subject`, `status`
- `HomeworkSubmission` — Student submissions
- `TimetableCell` — Timetable with `activity`, `period`, `room`, `teachers`
- `LeaveApplication` — Leave applications with status constants
- `StudentAttendance` — Attendance records
