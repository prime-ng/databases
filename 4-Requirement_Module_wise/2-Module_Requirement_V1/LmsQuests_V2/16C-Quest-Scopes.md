# Business Requirements Document (BRD)
## Module: LMS Quests
### Screen: Quest Scopes

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quest Scopes** screen defines the "Blueprint" or "Matrix" for a Quest. It strictly defines the quantity of questions that must be pulled from specific syllabus hierarchies (Lesson → Topic Levels).

### 1.2 Why is this necessary? (Business Justification)
- **Content Coverage:** It prevents teachers from randomly adding questions. If the Quest limit is 20 questions, the Scope guarantees (e.g.) 10 from Topic A and 10 from Topic B.

---

## 2. Document Scope
- **In-Scope:** Creation, updating, and validation of `lms_quest_scopes`. Dynamic 4-Level Topic Hierarchy cascading.
- **Out-of-Scope:** Actual question selection.

---

## 3. User Personas
1. **Teacher / Curriculum Designer:** Defines the blueprint for the assessment.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Quest Details Context
- **Action:** Select a Quest from the dropdown.
- **System Behavior:**
  - Triggers AJAX to `getQuestDetails`.
  - Fetches and locks the `Total Questions` and `Total Marks` limits from the parent Quest.
  - Loads the specific Lessons linked to the Quest's Class/Subject.

### FR-02: 4-Level Topic Hierarchy (AJAX)
- **System Behavior (`create.blade.php`):**
  - Selecting a Lesson loads `topic-level-1`.
  - Selecting `topic-level-1` loads `topic-level-2` (if children exist).
  - Cascades up to `topic-level-4`.
  - Topic ID is optional, but Lesson ID is mandatory per scope row.

### FR-03: Strict Quantity Validation (Frontend & Backend)
- **System Behavior:**
  - **Frontend:** Dynamically sums the `target_question_count` across all active rows. The "Create Scope" button is strictly `disabled` until `Sum of Row Targets == Parent Quest Total Questions`.
  - **Backend (`QuestScopeRequest`):** Ensures `target_question_count` is valid. Verifies max limits (e.g., maximum 20 scope rows per quest). Checks for duplicate scope configurations.

### FR-04: Bulk Store & Update Mechanism
- **System Behavior (`QuestScopeController`):**
  - Processes a multidimensional `scopes` array.
  - **Conflict Detection:** Checks internally to ensure no two rows in the same request have the exact same `lesson_id` + `topic_id`.
  - **Database Action:** Uses `updateOrCreate` to save records to `lms_quest_scopes`.
  - **Deletion:** During an update, if existing scope IDs are omitted from the request array, they are `forceDeleted`.

### FR-05: Modification Lock
- **System Behavior:**
  - `QuestScopeUsageCheckService` runs during `edit` and `update`.
  - If the scopes are already utilized in active allocations or attempts, editing is blocked.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Validating the Blueprint
**As a** Teacher,
**I want to** add scope rows to a Quest that requires 20 questions,
**So that** I can enforce the syllabus coverage.

**Acceptance Criteria:**
- **Given** my Quest requires 20 questions, **When** I add a scope row with 15 target questions, **Then** the Submit button remains disabled and UI shows "Total questions must be exactly 20. Currently: 15".

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quests` (Parent limits), `syl_lessons`, `syl_topics`, `syl_question_types`.
- **Outgoing Dependencies:** `lms_quest_scopes` acts as the strict validation barrier when adding physical questions in the next tab.
