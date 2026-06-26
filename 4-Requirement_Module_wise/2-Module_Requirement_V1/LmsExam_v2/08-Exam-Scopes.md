# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Creation & Allocation 
### Screen: Exam Scopes

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Exam Scopes** screen is a strict academic blueprint that dictates exactly *which lessons and topics* the exam questions must be sourced from. It establishes the pedagogical boundary of the paper.

### 1.2 Why is this necessary? (Business Justification)
- **Pedagogical Integrity:** Ensures that a teacher cannot accidentally include questions from "Chapter 10" if the midterm syllabus is strictly "Chapters 1 to 5".

---

## 2. Document Scope
- **In-Scope:** The complex dynamic table UI for defining target question quotas across a 4-level Topic hierarchy. Real-time Javascript validation against the parent Exam Paper's limits.
- **Out-of-Scope:** Linking actual questions (handled later).

---

## 3. User Personas
1. **Academic Coordinator / Subject Head:** Defines the scope matrix before teachers are allowed to select actual questions.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Parent Paper Context & Limits
- **Action:** Select an Exam Paper.
- **System Behavior (JS AJAX):** Upon selecting an Exam Paper, an AJAX call immediately fetches the `total_questions` and `total_marks` defined in that paper and locks them into read-only top header fields (Exam Total Questions / Exam Total Marks).

### FR-02: The Scope Matrix Table (Dynamic UI)
- **Action:** Add rows to define the syllabus scope.
- **Fields per Row:**
  - **Lesson:** Dropdown of lessons assigned to the paper's subject.
  - **Topic Hierarchy (4-Levels):** A single table cell containing 4 horizontally aligned dropdowns. Selecting "Topic Level 1" fetches and enables "Topic Level 2", and so on. The final deepest selected topic ID is captured.
  - **Question Type:** Optional filter (e.g., "Only MCQs from this topic").
  - **Target Qty:** Integer defining how many questions *must* come from this topic.
  - **Weightage (%):** Decimal indicating percentage importance.
  - **Active:** Boolean toggle.
  - **Delete Button:** Removes the row.

### FR-03: Real-Time Table Validation (JS Footer)
- **System Behavior:** As the user types into "Target Qty", a JavaScript function tallies the sum in the table footer (`tfoot`).
- **Constraint Check:** If the sum of all "Target Qty" exceeds the parent paper's `total_questions`, the form submit button is disabled, and a red validation message appears warning the user. The weightage total cannot exceed 100%.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Deep Topic Specification
**As an** Academic Coordinator,
**I want to** specify up to 4 levels of sub-topics,
**So that** I can mandate exactly 5 questions from the "Cell Division -> Mitosis -> Prophase" sub-topic.

**Acceptance Criteria:**
- **Given** I select a Lesson, **When** the Topic 1 dropdown appears and I select a topic, **Then** Topic 2 appears via AJAX, allowing me to drill down 4 levels deep before setting the Target Qty.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Target Qty** | Array validation. Sum of all quantities must be `<= total_questions` of the parent paper. |
| **Topic ID** | Extracted from the deepest active dropdown in the 4-level hierarchy. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exam_papers`, `sch_lessons`, `sch_topics`.
- **Outgoing Dependencies:** `lms_paper_set_questions`. This scope acts as a strict validation rule when the teacher later tries to add questions to the paper set.
