# Business Requirements Document (BRD)
## Module: Dashboard
### Role: Principal (Management)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Principal Dashboard** is designed for school management. Unlike the IT Admin (who cares about system configuration), the Principal cares about **Business KPIs**: Attendance trends, Fee collections, Academic performance, and Staff availability.

### 1.2 Why is this necessary? (Business Justification)
- **Actionable Intelligence:** The Principal needs to immediately see "Red Flags" like low student attendance, fee defaulters, or teachers who are absent today so they can arrange substitutes.

---

## 2. Document Scope
- **In-Scope:** `PrincipalDashboardController.php`, covering Student Capacities, Attendance Trends, Financial KPIs, and Academic Backlogs.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Executive Overview Widgets
- Total Students Enrolled
- Student Attendance Today (%)
- Teacher Attendance Today (%)
- Fee Collection Rate (%)
- Open / Unresolved Complaints

### FR-02: Deep-Dive Tabs
1. **Students Tab:**
   - Shows Class Capacity (Enrolled vs Max allowed).
   - "Red Flag" counters: Low Attendance, Fee Defaulters, Pending Documents, Medical Flags.
   - Top 5 students with chronically low attendance.
2. **Attendance Tab:**
   - 7-Day Trend line chart for both Students and Teachers.
   - **Absent Teachers List:** Explicitly lists teachers who are absent today and what classes they were supposed to teach, aiding in substitute allocation.
   - Sections with today's attendance dropping below 80%.
3. **Finance Tab:**
   - Month-by-month fee collection bar chart (in Lakhs).
4. **Academics Tab:**
   - Tracks LMS/Exam bottlenecks: `exams_eval_backlog`, `homework_grading_backlog`, and `quizzes_engagement_pct`.
   - HPC Publication percentage (how many Holistic Progress Cards have been sent to parents).

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Managing Absent Teachers
**As a** Principal,
**I want to** immediately see a list of teachers who are absent today and their assigned classes,
**So that** I can assign substitute teachers before the first period begins.

**Acceptance Criteria:**
- **Given** I am on the Attendance tab of my dashboard, **When** I look at the "Absent Teachers" widget, **Then** I see the names of absent teachers alongside the sections (e.g., IX-A, X-B) they are scheduled to teach today.
