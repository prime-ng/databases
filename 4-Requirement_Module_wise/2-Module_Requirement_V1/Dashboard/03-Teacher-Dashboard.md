# Business Requirements Document (BRD)
## Module: Dashboard
### Role: Teacher

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Teacher Dashboard** is an operational day-planner. It focuses entirely on what the teacher needs to do *today*: Classes to teach, attendance to mark, and homework/exams to grade.

### 1.2 Why is this necessary? (Business Justification)
- **Daily Productivity:** Teachers don't need to see school-wide fee collections. They need to see their personal timetable and be alerted if they forgot to mark period attendance or have a massive grading backlog.

---

## 2. Document Scope
- **In-Scope:** `TeacherDashboardController.php`, covering My Schedule, My Attendance, My Students, and Academics (Grading).

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Today's Overview
- **Metrics:** Periods Today, Students Taught Today, Grading Backlog count, Pending Evaluations count, and Personal Leave Balance.
- **Mini-Schedule:** A chronological list of today's periods (e.g., 1st Period, 08:00, Class VI-A, Room 12) with real-time status (Completed, Current, Upcoming, Free).

### FR-02: Actionable Tabs
1. **Schedule Tab:**
   - Shows the full weekly grid (Mon-Sat x 8 Periods) mapping classes and subjects.
2. **Attendance Tab:**
   - Shows Period-wise attendance marking status.
   - **Alert:** Highlights periods where the teacher's status is "Pending" (they forgot to mark attendance in the app).
   - 7-Day history of their own attendance marking compliance.
3. **Students Tab:**
   - A list of all students taught by the teacher, grouped by Class Section tabs.
   - Highlights student specific flags (e.g., "low-attendance" tag next to a student's name).
4. **Academics (Grading Backlog) Tab:**
   - Lists active Homeworks with due dates and the count of `grading_pending`.
   - Lists active Exams with total papers, evaluated count, pending evaluations, and open grievances specifically assigned to this teacher.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Attendance Compliance Reminder
**As a** Teacher,
**I want to** see which periods I still need to mark attendance for today,
**So that** I don't get reprimanded by the Principal for missing data.

**Acceptance Criteria:**
- **Given** I am on the Teacher Dashboard -> Attendance Tab, **When** I look at today's periods, **Then** any period that has passed but lacks attendance data shows a "Pending" status badge in red.
