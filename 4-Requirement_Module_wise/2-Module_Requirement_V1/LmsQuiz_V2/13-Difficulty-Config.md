# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Setup
### Screen: Difficulty Distribution Config

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Difficulty Distribution Config** screen allows academic planners to define rule-based templates for question selection (e.g., "A Standard Quiz must have 20% Easy, 50% Medium, and 30% Hard questions").

### 1.2 Why is this necessary? (Business Justification)
- **Automated Generation:** These configurations are mandatory if the system is allowed to auto-generate a quiz (`is_system_generated`).
- **Pedagogical Balance:** Ensures teachers do not manually create poorly balanced tests (e.g., 100% hard questions).

---

## 2. Document Scope
- **In-Scope:** Left-side General Settings and Right-side dynamic Distribution Rules table.
- **Out-of-Scope:** Executing the auto-generation (this happens in Quiz Creation).

---

## 3. User Personas
1. **Academic Head:** Defines standardized templates that teachers must adhere to.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: General Settings (Sidebar)
- **Fields:**
  - **Config Code & Name:** Identifiers.
  - **Question Usage Type:** Dropdown (`QUIZ`, `QUEST`, etc.).
  - **Description:** Textarea.
  - **System Generated Switch (`use_for_system_generated_quiz`):** If checked, this configuration can be picked by the AI to automatically build quizzes without human intervention.
  - **Active Status (`is_active`):** Toggle.

### FR-02: Distribution Rules (Dynamic Right Panel)
- **Action:** Add rows defining specific constraints.
- **Fields per Row:**
  - **Question Type:** Dropdown (e.g., MCQ_SINGLE).
  - **Complexity:** Dropdown (EASY, MEDIUM, DIFFICULT).
  - **Min % and Max %:** The required percentage boundary for this specific combination.
  - **Marks/Ques:** How many marks questions of this type/complexity carry.
  - **Advanced Filters (Row 2):** Bloom Taxonomy, Cognitive Skill, Question Type Specificity.
- **UI Logic:** Users can add multiple rules to build a complete 100% matrix.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: System Auto-Generation Setup
**As an** Academic Head,
**I want to** mark a config as "System Generated",
**So that** the LMS engine can use it to instantly build practice quizzes for students.

**Acceptance Criteria:**
- **Given** I check `use_for_system_generated_quiz`, **When** I save, **Then** this config becomes available in the auto-generation engine dropdown on the Quiz creation page.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `qbn_question_types`, `qbn_complexity_levels`, `qbn_bloom_taxonomies`.
- **Outgoing Dependencies:** `lms_quizzes` (A quiz can optionally lock itself to a specific difficulty config to enforce rules).
