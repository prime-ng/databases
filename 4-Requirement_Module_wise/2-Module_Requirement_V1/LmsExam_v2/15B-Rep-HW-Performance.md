# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Advanced Reports
### Screen: Tab 2: HW Performance Analysis

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **HW Performance Analysis** report shifts focus from *compliance* (did they submit?) to *competence* (how well did they do?). It presents a classic gradebook matrix for homework scores.

### 1.2 Why is this necessary? (Business Justification)
- **Academic Intervention:** Helps teachers identify struggling students ("Struggling" band) or consistently high performers across a series of assignments.

---

## 2. Document Scope
- **In-Scope:** Gradebook matrix (Students as Rows, Homeworks as Columns). Grading bands and class averages.
- **Out-of-Scope:** Non-gradable homeworks (unless explicitly filtered).

---

## 3. User Personas
1. **Teacher / Academic Coordinator:** Looks at the matrix to spot trends (e.g., "John got 90% on HW1, but 40% on HW2 and HW3. I need to talk to him.").

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Performance Matrix Generation
- **Action:** Generate the matrix.
- **System Behavior:**
  - Fetches all students for the selected class/section.
  - Fetches all homeworks matching the criteria.
  - **Cross-Tabulation (`generateHwPerformanceData`):** Loops through students and maps their percentage score for each homework. 
  - Calculates a `total_pct` for the student across all selected homeworks and assigns a Color Code (Success, Primary, Info, Warning, Danger) based on percentage thresholds.

### FR-02: KPI Metrics & Averages
- **System Behavior:**
  - Calculates Class Average, Highest Score, Lowest Score, and High Performers count (>= 90%).

### FR-03: Banding Distribution
- **System Behavior:**
  - Categorizes all scores into bands: Struggling (<35%), Attention (35-49%), Satisfactory (50-69%), Good (70-84%), Outstanding (85%+).
  - Displays this distribution as a chart.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Spotting a struggling student
**As an** Academic Coordinator,
**I want to** view the performance matrix for Section A,
**So that** I can see which students are falling into the red "Danger" zone (<33%) across multiple assignments.

**Acceptance Criteria:**
- **Given** the matrix loads, **When** a student's total average is below 33%, **Then** their row highlight color is explicitly rendered as 'danger' (red).

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** Relies heavily on `marks_obtained` and `max_marks` from `lms_homework_submissions` and `lms_homeworks`.
