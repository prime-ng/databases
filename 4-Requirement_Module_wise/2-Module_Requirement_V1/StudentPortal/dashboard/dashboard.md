# Student Portal — Dashboard Tab Requirements

## 1. Functional Overview
The Dashboard serves as the central hub for the student, providing a high-level summary of active assignments, upcoming exams, attendance rates, finance status, and quick redirects to sub-modules.

---

## 2. Page Widgets & Components

### A. Stat Cards Block
- **Attendance Card**:
  - **Metric**: Present days / Total session days (converted to percentage).
  - **Logic**: Red if < 60% (critical), Orange if 60% - 75% (warning), Green if >= 75% (good).
  - **Redirect**: [My Attendance](file:///c:/laragon/www/prime_ai/Modules/StudentPortal/resources/views/attendance/index.blade.php).
- **Homework Pending Card**:
  - **Metric**: Count of released, active homework assignments not yet submitted.
  - **Redirect**: [My Learning](file:///c:/laragon/www/prime_ai/Modules/StudentPortal/resources/views/learning/index.blade.php).
- **Upcoming Exams Card**:
  - **Metric**: Count of allocated exams scheduled in the future.
  - **Redirect**: [Exam Schedule](file:///c:/laragon/www/prime_ai/Modules/StudentPortal/resources/views/exams/schedule.blade.php).
- **Fee Due Card**:
  - **Metric**: Total outstanding due amount.
  - **Logic**: Red if balance > 0, Green if balance == 0.
  - **Redirect**: [Fee Summary](file:///c:/laragon/www/prime_ai/Modules/StudentPortal/resources/views/fee/summary.blade.php).
- **Applied Leaves Card**:
  - **Metric**: Count of applied leaves and pending leaves awaiting teacher review.
  - **Redirect**: [Apply Leave](file:///c:/laragon/www/prime_ai/Modules/StudentPortal/resources/views/leave/index.blade.php).

### B. Today's Timetable Widget
- Displays a horizontal sliding list of classes scheduled for the current day.
- **Fields**: Time slot/Period name, Subject name, Teacher name, Room name.
- **Empty State**: Displays "No classes scheduled for today" if no active cells match the day code.

### C. Student Profile Card
- Displays student avatar, name, and role.
- Lists Class details (Class & Section name), Roll Number, and Academic Session.
- Includes a button linking to **Account Settings**.

### D. Quick Navigation Panel
- List items with colored icons for:
  - My Attendance
  - My Timetable
  - My Teachers
  - My Learning (shows pending counts)
  - Exam Schedule (shows upcoming counts)
  - My Results (shows total results count)
  - Fee & Payments (shows due amount)
  - Notifications

### E. Pending Homework Table
- Shows up to 5 pending homework entries.
- **Columns**: Subject (with color indicator dot), Homework Title, Due Date (marked red if overdue), Actions ("Submit" button).

### F. Upcoming Exams Table
- Shows up to 5 upcoming exam allocations.
- **Columns**: Exam Name, Subject, Date (with relative days countdown), Duration (minutes), Mode (Online/Offline badge).

### G. Recent Results List
- Displays up to 5 recent LMS Quiz, Quest, or Exam results.
- **Fields**: Assessment Type badge (Quiz/Quest/Exam), Title, Score/Max Score, Percentage, Pass/Fail status badge.

### I. Notifications & Notices
- Lists up to 5 recent notifications with read/unread indicators and relative time stamps.

---

## 3. Database Dependencies & Relationships
- **Timetable**: `TimetableCell` -> `activity.subject`, `activity.teachers`, `period`, `room`.
- **Homework**: `Homework` -> `subject`, filtered against submitted IDs in `HomeworkSubmission`.
- **Exams**: `ExamAllocation` -> `examPaper.exam`, `examPaper.subject`.
- **LMS Result Counts**: Querying counts from `lms_quiz_quest_results` and `lms_exam_results`.
- **Fee Summary**: `FeeInvoice` related to current student's `FeeAssignment`.
