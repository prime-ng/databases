# Business Requirements Document (BRD)
## Module: LMS Quests
### Screen: Quest Questions

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quest Questions** screen is a complex, 3-tab interface where teachers search the Central Question Bank, select questions, and validate them against the parent Quest's rules (Marks, Limits, Scopes, and Difficulty constraints).

### 1.2 Why is this necessary? (Business Justification)
- **Pedagogical Compliance:** It physically restricts the teacher from adding too many questions, exceeding the maximum marks, violating the syllabus Scope blueprint, or breaking the Difficulty Distribution matrix.

---

## 2. Document Scope
- **In-Scope:** The 3-tab UI layout (Selection, Review, Validation). Advanced search filters, question selection, removing selected questions, and real-time backend/frontend rule validation.
- **Out-of-Scope:** Creating new questions in the Bank.

---

## 3. User Personas
1. **Teacher:** Searches the bank, selects questions, reviews them, and saves the final list to the Quest.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Top Dashboard Strip
- **System Behavior:** Above the tabs, a fixed dashboard displays live tracking stats:
  - **Selected Questions** vs **Max Questions**
  - **Selected Marks** vs **Max Marks**

### FR-02: Tab 1 - Question Selection (`#tab-selection`)
- **Action:** Browse and filter questions.
- **Left Sidebar - 3 Accordion Filters:**
  1. **Academic Details:** Filters by Class (auto-locked to the Quest), Section, Subject Group, Subject, Lesson, and Topic.
  2. **Question Properties:** Filters by Question Type, Complexity, Bloom Level, Cognitive Skill, Type Specificity, Recommendation Type, Performance Category, and Question Tags.
  3. **Usage & Settings:** Toggles to show `Only Unused` or `Only Authorised` questions. Checkboxes for usage context (`for_quiz`, `for_quest`, `for_exam`).
- **Right Content:** A paginated Datagrid displaying the filtered question bank. Users can check boxes to select questions.

### FR-03: Tab 2 - Review Selected (`#tab-review`)
- **Action:** Review the list of questions currently added to the Quest.
- **System Behavior:**
  - Displays a datagrid of all selected questions.
  - Teachers can view the Order (Ordinal), Title, Type, Complexity, and Marks of each question.
  - **Remove Action:** Teachers can select checkboxes and click the "Remove Selected" button to detach questions from the Quest.

### FR-04: Tab 3 - Validation & Stats (`#tab-validation`)
- **Action:** Review pedagogical compliance before final save.
- **System Behavior:**
  - **Summary Stats Panel:** Displays a progress bar showing Completion % (Questions Added vs Limit).
  - **Difficulty Distribution Rules Table:** If a difficulty config is applied to the Quest, this table lists the required Easy/Medium/Hard percentages vs the actual added percentages, showing a live "Status" (Pass/Fail).
  - **Quest Scope Limits Table:** If Scopes were defined in the previous module, this table shows the required Topic quotas vs the actual added counts from those Topics.

### FR-05: Real-Time Rule Validation (Backend - `QuestQuestionRequest`)
- **System Behavior (Crucial Step):** When the "Save Quest to Database" button is clicked, a custom `withValidator` hook runs on the backend:
  - **Rule 1 (Capacity Check):** If `Added Questions > Quest->total_questions`, it blocks the save.
  - **Rule 2 (Marks Limit Check):** If `Sum of Marks > Quest->total_marks`, it blocks the save.
  - **Rule 3 (Difficulty Check):** If `ignore_difficulty_config` is false, it verifies that the questions don't violate the `lms_difficulty_distribution_details` percentage limits.
  - **Rule 4 (Scope Check):** Verifies that the questions match the exact Topic breakdown defined in `lms_quest_scopes`.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Validating the Selection
**As a** Teacher,
**I want to** check the Validation & Stats tab,
**So that** I know if I have met my syllabus and difficulty requirements before saving.

**Acceptance Criteria:**
- **Given** my Quest requires 10 questions from Topic A, **When** I go to Tab 3, **Then** the "Quest Scope Limits" table should display 10 required, and the "Added" column should show exactly how many Topic A questions I have selected.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `qbn_question_banks`, `lms_quests`, `lms_quest_scopes`, `lms_difficulty_distribution_details`.
- **Outgoing Dependencies:** `lms_quest_questions` dictates what the student sees during the attempt.
