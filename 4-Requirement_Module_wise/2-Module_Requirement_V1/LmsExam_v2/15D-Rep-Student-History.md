# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Advanced Reports
### Screen: Tab 4: Student Exam History

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Student Exam History** report is an individualized dossier. Instead of looking at a class, it isolates a single student and visualizes their academic journey over time across all exams and subjects.

### 1.2 Why is this necessary? (Business Justification)
- **Parent-Teacher Meetings (PTM):** This is the ultimate tool for a teacher to show a parent. "Here is how John's performance is trending over the last 6 months, and here is a Radar chart showing he is strong in Science but weak in Math."

---

## 2. Document Scope
- **In-Scope:** Individual student progress tracking, subject strength/weakness radar charts.
- **Out-of-Scope:** Class-wide analytics.

---

## 3. User Personas
1. **Teacher / Parent (via proxy):** Uses the visual graphs to understand a single student's trajectory.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Student Data Aggregation
- **Action:** Select a specific student.
- **System Behavior:**
  - Queries `lms_exam_results` for the specific `student_id`.
  - Calculates the student's `Avg Pct`, `Highest Score`, and identifies their `Best Subject`.

### FR-02: Progress Line Chart (Benchmarking)
- **Action:** Render the progress chart.
- **System Behavior:**
  - Plots the student's chronological exam percentages on a line chart.
  - **Crucial Feature:** Overlays a second line showing the **Class Average** for each of those exact same exams. This proves if the student is performing above or below the class norm.

### FR-03: Subject Radar Chart
- **Action:** Render the radar chart.
- **System Behavior:**
  - Groups results by Subject Name.
  - Calculates the average score for each subject and plots it on a Radar (Spider) chart to visually highlight strengths and weaknesses.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Visualizing Strengths
**As a** Teacher,
**I want to** load John's Exam History,
**So that** I can show his parents the Radar chart proving he needs a tutor for Mathematics.

**Acceptance Criteria:**
- **Given** I select John, **When** the page loads, **Then** the radar chart accurately plots his average Math score vs his Science and English scores.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exam_results`, `student_academic_sessions` (to determine current class/section).
