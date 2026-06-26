# Business Requirements Document (BRD)
## Module: Smart Timetable Ecosystem
### Feature 06: Analytics & Substitute Management

---

## 1. Executive Summary
On a daily basis, teachers call in sick. The school needs an operational interface to instantly assign Substitute teachers without breaking the published timetable. Additionally, admins need analytics on teacher workloads.

## 2. Core Components
- `SmartTimetable` Module
- Controllers: `AnalyticsController`, `SubstitutionController`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Workload Analytics (`AnalyticsController`)
- Analyzes `tt_timetable_cells` and Activities to produce reports:
  - **Teacher Workload Analysis:** Shows which teachers are overworked (e.g., 35 periods/week) vs under-utilized (e.g., 10 periods/week).
  - **Room Utilization:** Identifies bottleneck rooms (e.g., Chemistry lab is at 98% capacity).

### FR-02: Substitute Management (`SubstitutionController`)
- **Daily Operations:** When a teacher is marked absent in HR/Attendance, the system flags their scheduled periods for the day as "Uncovered".
- **Substitute Proposal:** The engine suggests available teachers for those specific periods. It filters out teachers who are already teaching, and prioritizes teachers who teach the same subject or have a low workload that day.
- **Approval & Notification:** Once the admin assigns a substitute, the substitute teacher receives a Push Notification / Dashboard Alert.

---

## 4. Acceptance Criteria
- **Given** Teacher A (Math) is absent on Tuesday, **When** I open the Substitute Management dashboard, **Then** the system lists Teacher A's 4 periods as pending coverage. **When** I click to assign a sub for Period 1, **Then** the dropdown only shows teachers who have Period 1 completely free on Tuesday.
