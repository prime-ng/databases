# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Advanced Reports
### Screen: Tab 1: HW Submission Tracker

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **HW Submission Tracker** provides an operational view of homework compliance. It tracks how many students were assigned a task, how many submitted it, how many were late, and how many are pending.

### 1.2 Why is this necessary? (Business Justification)
- **Accountability:** Teachers need a fast way to identify students who chronically miss homework deadlines without opening every individual assignment.

---

## 2. Document Scope
- **In-Scope:** Tracking assignment vs submission counts. Viewing late submissions and graded status.
- **Out-of-Scope:** Analyzing the actual marks obtained (this is handled in the Performance tab).

---

## 3. User Personas
1. **Teacher / Class Admin:** Uses the tracker to send reminders to students who haven't submitted their homework.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Filtering & Date Scope
- **Action:** Filter the report.
- **System Behavior:**
  - Standard filters: `Class`, `Section`, `Subject`, `Lesson`, `Topic`.
  - Date Range (`date_from` to `date_to`) filters based on the `assign_date` of the Homework.

### FR-02: Tracker Metrics & Data Grid
- **Action:** View the tracker data.
- **System Behavior:**
  - The controller (`generateHwSubmissionData`) calculates: `#asgnd`, `#subm`, `#late`, `#graded`, `#resubm`, `#pending`.
  - The data grid lists all homeworks matching the criteria and their respective counts.
  - Generates top-level KPI metrics: Total Assigned, Submitted, Pending, Late, and Average Submission Rate (%).

### FR-03: Visual Charts
- **System Behavior:**
  - Renders a Status Chart (Submitted vs Pending vs Late).
  - Renders a Trend Chart showing submissions over the last 10 homeworks.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Tracking Pending Homework
**As a** Math Teacher,
**I want to** filter by Math class for the last 7 days,
**So that** I can see exactly how many students have not yet submitted the Algebra assignment.

**Acceptance Criteria:**
- **Given** I select Math and Last 7 Days, **When** the report loads, **Then** I see the Algebra assignment row with "Pending: 5".

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** Reads from `lms_homeworks`, `lms_homework_assignments`, and `lms_homework_submissions`.
