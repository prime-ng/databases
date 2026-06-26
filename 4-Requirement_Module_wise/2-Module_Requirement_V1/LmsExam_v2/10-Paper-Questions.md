# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Creation & Allocation 
### Screen: Paper Questions

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Paper Questions** screen is the most critical and complex interface in the Exam Module. It allows teachers to search the Central Question Bank, select questions, map them to specific Blueprint sections, and validate them against Scopes and Difficulty Matrices.

### 1.2 Why is this necessary? (Business Justification)
- **Pedagogical Compliance:** It physically restricts the teacher from adding too many questions, exceeding the maximum marks, violating the syllabus Scope blueprint, or breaking the Difficulty Distribution matrix.

---

## 2. Document Scope
- **In-Scope:** The massive 3-tab UI layout (Selection, Review, Validation). Advanced search filters, assigning questions to Paper Sets and Blueprints, and real-time frontend/backend rule validation.
- **Out-of-Scope:** Creating new questions in the Bank.

---

## 3. User Personas
1. **Teacher:** Searches the bank, selects questions, assigns them to a Set and Section, and saves.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Top Dashboard Configuration Strip
- **System Behavior:** Above the tabs, a fixed dashboard displays live tracking stats.
- **Selection Dropdowns:**
  - **Select Paper Set:** Filters the entire interface for a specific Set (e.g., Set A).
  - **Exam Blueprint:** Determines which section the selected questions will be assigned to (e.g., "Section A").
- **Live Stats Panel:** Shows Selected Questions vs Max Questions, and Selected Marks vs Max Marks for the current context.

### FR-02: Tab 1 - Question Selection (`#tab-selection`)
- **Action:** Browse and filter questions.
- **Left Sidebar - 3 Accordion Filters:**
  1. **Academic Details:** Filters by Class (auto-locked), Section, Subject Group, Subject, Lesson, and Topic.
  2. **Question Properties:** Filters by Question Type, Complexity, Bloom Level, Cognitive Skill, Recommendation Type, and Tags.
  3. **Usage & Settings:** Toggles to show `Only Unused` or `Only Authorised` questions. Checkboxes for usage context (`for_quiz`, `for_quest`, `for_exam`).
- **Right Content:** A paginated Datagrid displaying the filtered question bank. Users can check boxes to select questions. Rendered via MathJax for mathematical equations.

### FR-03: Tab 2 - Review Selected (`#tab-review`)
- **Action:** Review the list of questions currently added to the Paper Set.
- **System Behavior:**
  - Displays a datagrid of all selected questions.
  - **Inputs:** Users can modify the `Ordinal` (Order) and `Marks` for each question directly from this grid.
  - **Remove Action:** Teachers can select checkboxes and click the "Remove Selected" button to detach questions from the Set.

### FR-04: Tab 3 - Validation & Stats (`#tab-validation`)
- **Action:** Review pedagogical compliance before final save.
- **System Behavior:**
  - **Difficulty Distribution Rules Table:** If a difficulty config is applied to the Exam Paper, this table lists the required Easy/Medium/Hard percentages vs the actual added percentages, showing a live "Status" (Pass/Fail).
  - **Exam Blueprint Limits Table:** Shows required Marks and Questions per Blueprint Section vs Actuals.
  - **Exam Scope Limits Table:** If Scopes were defined, this table shows the required Topic quotas vs the actual added counts.

### FR-05: Real-Time Backend Validation
- **System Behavior (Crucial Step):** When the "Save" button is clicked:
  - **Rule 1:** Validates against the Blueprint Section limits.
  - **Rule 2:** Validates against the Topic Scope Limits.
  - **Rule 3:** If `ignore_difficulty_config` is false, it verifies Difficulty matrix percentages.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Validating Blueprint Context
**As a** Teacher,
**I want to** select "Section A" from the Blueprint dropdown,
**So that** all the questions I check in the grid are explicitly mapped to Section A.

**Acceptance Criteria:**
- **Given** I select a Paper Set and a Blueprint Section, **When** I check 5 questions in Tab 1 and hit save, **Then** those 5 questions are saved into `lms_paper_set_questions` referencing that specific blueprint ID.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `qbn_question_banks`, `lms_exam_paper_sets`, `lms_exam_blueprints`, `lms_exam_scopes`, `lms_difficulty_distribution_details`.
- **Outgoing Dependencies:** These questions render directly on the student's exam portal.
