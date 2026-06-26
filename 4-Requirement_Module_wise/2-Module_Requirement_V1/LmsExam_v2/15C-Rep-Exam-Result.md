# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Advanced Reports
### Screen: Tab 3: Exam Result Report (Ledger)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Exam Result Report** is the definitive "Result Ledger" for a specific exam or paper. It ranks students and provides pass/fail analytics.

### 1.2 Why is this necessary? (Business Justification)
- **Official Ledger:** Schools require a printable, ranked ledger of how the entire class performed in a specific summative assessment (e.g., Mid-Term Math Exam).

---

## 2. Document Scope
- **In-Scope:** Student ranking, percentage calculation, grade assignment, pass/fail ratios.
- **Out-of-Scope:** Historical comparison across multiple exams.

---

## 3. User Personas
1. **Principal / Class Teacher:** Prints the ledger for the parent-teacher meeting.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Ledger Data Processing
- **Action:** Query the results.
- **System Behavior:**
  - Fetches `lms_exam_results`.
  - **Ranking Logic (`generateExamResultData`):** Sorts all results descending by `percentage`. Iterates through to assign an absolute `rank` to each student.
  - Dynamically calculates Grades (A+, A, B+, B, C, D, F) and Divisions (I, II, III) if not already explicitly saved in the DB.

### FR-02: KPI Summary
- **System Behavior:**
  - Calculates Total Students, Present, Absent, Passed, Failed, Pass %, Class Avg, Highest, Lowest.

### FR-03: Visual Analytics
- **System Behavior:**
  - Renders a Pass Rate Chart and a Grade Profile Distribution Chart (Count of A+ vs A vs B, etc.).

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Generating the Class Rank List
**As a** Class Teacher,
**I want to** filter by the Final Exam and Math Paper,
**So that** I can see exactly who ranked 1st, 2nd, and 3rd in my class.

**Acceptance Criteria:**
- **Given** I select the exam and paper, **When** the report loads, **Then** the students are strictly ordered by percentage, and the `rank` integer is accurately assigned.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** Direct dependency on `lms_exam_results` being fully processed (Evaluation must be complete).
