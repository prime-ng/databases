# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Creation & Allocation 
### Screen: Exam Blueprints

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Exam Blueprint** screen defines the structural sections of the physical/digital exam paper (e.g., Section A: 10 MCQs, Section B: 5 Long Answers). It dictates the layout and marks distribution.

### 1.2 Why is this necessary? (Business Justification)
- **Standardized Formats:** CBSE/ICSE board papers require strict sectioning. The blueprint ensures the final paper generates exactly matching these sections.

---

## 2. Document Scope
- **In-Scope:** The dynamic UI table for creating structural sections, assigning marks per question, and validating against the parent paper's overall capacity.
- **Out-of-Scope:** Assigning topics (that is Scope) and adding questions (that is Paper Questions).

---

## 3. User Personas
1. **Subject Teacher:** Defines the format of the exam paper.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Parent Paper Context
- **Action:** Select an Exam Paper.
- **System Behavior (JS AJAX):** Similar to Scopes, selecting a paper fetches the `total_questions` and `total_marks` and displays them as hard limits at the top of the form.

### FR-02: Blueprint Configuration Table
- **Action:** Add section rows.
- **Fields per Row:**
  - **Section Name:** E.g., `Section A - MCQs`.
  - **Question Type:** Dropdown (e.g., Multiple Choice).
  - **Total Q:** Number of questions in this section.
  - **Marks/Q:** Marks awarded per question.
  - **Total Marks:** Auto-calculated via JS (`Total Q * Marks/Q`).
  - **Seq (Ordinal):** The order in which the section appears on the final paper.
  - **Instruction Text:** Textarea for specific section rules (e.g., "Attempt any 4").
  - **Active:** Boolean switch.

### FR-03: Strict Real-Time Rule Validation (JS Footer)
- **System Behavior:** As the user types in `Total Q` and `Marks/Q`, JS recalculates the footer sums.
- **Strict Equality Rules:**
  - The Sum of all `Total Q` across all rows MUST exactly equal the paper's `total_questions`.
  - The Sum of all `Total Marks` across all rows MUST exactly equal the paper's `total_marks`.
- **Enforcement:** If either rule fails, the footer text turns red (`text-danger`) and the "Create Blueprints" submit button is entirely disabled (`prop('disabled', true)`).

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Strict Blueprint Validation
**As an** Admin,
**I want to** force teachers to make their blueprint totals match the paper totals,
**So that** we don't accidentally print a 50-mark blueprint for an 80-mark exam.

**Acceptance Criteria:**
- **Given** the Paper is set to 80 marks, **When** I build sections that only add up to 75 marks, **Then** the "Create Blueprints" button remains disabled and a red warning message displays the discrepancy.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Marks/Q & Total Marks** | Decimals. Auto-calculated on frontend, validated strictly on backend. |
| **Sum Validations** | `sum(total_questions) == paper.total_questions`. `sum(total_marks) == paper.total_marks`. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exam_papers`, `qbn_question_types`.
- **Outgoing Dependencies:** `lms_paper_set_questions`. Every question added to the paper MUST belong to one of these defined blueprint sections.
