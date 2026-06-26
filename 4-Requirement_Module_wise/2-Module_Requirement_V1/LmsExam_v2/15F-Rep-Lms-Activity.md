# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Advanced Reports
### Screen: Tab 6: LMS Activity Dashboard

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **LMS Activity Dashboard** is a macro-level engagement tracker. It mixes both Homework and Exam data to show the overall "Pulse" and utilization of the LMS platform by the student body over a date range.

### 1.2 Why is this necessary? (Business Justification)
- **System ROI:** School management pays for the LMS. They want to know: "Are teachers actually assigning homework and exams? Are students actually logging in and participating?"

---

## 2. Document Scope
- **In-Scope:** High-level volume and engagement metrics combining `Homework` and `Exam` data.
- **Out-of-Scope:** Micro-level score analysis.

---

## 3. User Personas
1. **School Administrator / System Owner:** Monitors overall platform adoption and engagement rates.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Macro Data Collection
- **Action:** Select a broad date range (e.g., This Month).
- **System Behavior (`generateLmsActivityData`):**
  - Queries `lms_homeworks` and counts total submissions vs assigned.
  - Queries `lms_exams` and counts total attended vs assigned.
  - Creates a unified array of "Activities".

### FR-02: KPI Cards
- **System Behavior:**
  - Generates top-level cards for Homeworks and Exams showing:
    - Total Count (Volume of activities created).
    - Average Score (Macro academic health).
    - Participation Rate % (Engagement).

### FR-03: Engagement Charts
- **System Behavior:**
  - Renders a Volume chart (Homework vs Exam ratio).
  - Renders an Engagement Timeline (simulated or real day-by-day activity spikes) to show when the LMS is used most heavily.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Proving System Utilization
**As an** IT Administrator,
**I want to** look at the LMS Activity Dashboard for October,
**So that** I can report to the board that we had 95% student participation across 40 homeworks and 5 exams.

**Acceptance Criteria:**
- **Given** I select October, **When** the dashboard loads, **Then** the Homework and Exam KPI cards accurately aggregate the total assigned vs completed ratios.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** Cross-module dependency. Reads from `LmsHomework` (Homework, Assignments, Submissions) and `LmsExam` (Exams, Results).
