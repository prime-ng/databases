# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Creation
### Screen: Quiz Questions

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quiz Questions** screen is a massive, multi-tabbed interface where teachers search the Central Question Bank, select specific questions, review their marks/ordering, and validate them against the Quiz's overarching limits and Difficulty Configuration.

### 1.2 Why is this necessary? (Business Justification)
- **Pedagogical Compliance:** Ensures the teacher does not add 15 questions to a Quiz that was configured for only 10 questions. It also enforces the Difficulty Matrix (e.g., preventing a teacher from adding all 'Hard' questions if the template requires 50% 'Easy').

---

## 2. Document Scope
- **In-Scope:** The 3-Tab UI (Selection, Review, Validation). Left-sidebar accordion filters. Top dashboard limit counters. Real-time MathJax rendering.
- **Out-of-Scope:** Creating new questions.

---

## 3. User Personas
1. **Teacher:** Manually curates the question list for their quiz.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Quiz Selection & Live Dashboard
- **Select Quiz Dropdown:** Picking a quiz populates the Top Dashboard.
- **Top Dashboard:** Displays 4 critical live metrics:
  1. Selected Questions
  2. Selected Marks
  3. Max Questions (Inherited from Quiz config)
  4. Max Marks (Inherited from Quiz config)

### FR-02: Tab 1 - Question Selection
- **Left Sidebar - 3 Accordion Filters:**
  1. **Academic Details:** Class (locked to Quiz's class), Section, Subject Group, Subject, Lesson, Topic.
  2. **Question Properties:** Type, Complexity, Bloom Level, Cognitive Skill, Specificity, Recommendation Type, Performance Category, Tags, Priority.
  3. **Usage & Settings:** `Only Unused`, `Only Authorised`, `For Quiz` (checked by default), `For Quest`, `For Exam`.
- **Right Content:** Paginated Datagrid of questions. Rendered via MathJax. Checkboxes for selection.

### FR-03: Tab 2 - Review Selected
- **Action:** Review and override default values.
- **System Behavior:** Displays a table of all checked questions. The teacher can manually edit the `Ordinal` (sorting order) and the `Marks` for each question directly in this grid. They can also select questions to remove them from the Quiz.

### FR-04: Tab 3 - Validation & Stats
- **Action:** Pre-save compliance check.
- **System Behavior:** 
  - **Difficulty Limits Table:** Compares the selected questions against the Quiz's linked `Difficulty Configuration`. Shows a live Pass/Fail status for constraints like "Min 20% Easy Questions".
  - **Overall Limits:** Ensures Total Questions and Total Marks do not exceed the Max Limits shown in the top dashboard.

### FR-05: Real-Time Backend Validation
- **System Behavior:** Upon clicking "Save", the controller strictly validates the selected counts against the Quiz's `total_questions`, `total_marks`, and linked `difficulty_config_id` (unless `ignore_difficulty_config` was checked).

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Enforcing Quiz Limits
**As a** Teacher,
**I want the** system to block me from adding too many questions,
**So that** I don't accidentally create a 12-question quiz when the syllabus plan dictates 10.

**Acceptance Criteria:**
- **Given** my Quiz has `total_questions = 10`, **When** I check 11 questions in Tab 1 and hit Save, **Then** the request is aborted and a validation error is returned.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quizzes`, `qbn_question_banks`, `lms_difficulty_distribution_configs`.
- **Outgoing Dependencies:** `lms_quiz_allocations` (The allocated students will see exactly these selected questions).
