# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Creation
### Screen: Quiz Basic Info & Configuration

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quiz Creation** screen defines the pedagogical metadata, syllabus mapping, scoring rules, and behavioral settings (like timers and retries) for a single quiz. It uses a 2-Tab layout to separate syllabus definitions from behavioral toggles.

### 1.2 Why is this necessary? (Business Justification)
- **Micro-Assessments:** Unlike heavy Exams, Quizzes require rapid creation with flexible, granular topic-level targeting.

---

## 2. Document Scope
- **In-Scope:** The 2-Tab Wizard UI. AJAX-driven Topic Hierarchy mapping. Difficulty Config locking. 10 Advanced behavioral switches.
- **Out-of-Scope:** Assigning actual questions (handled in Quiz Questions).

---

## 3. User Personas
1. **Teacher:** Creates a quiz for their class.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Tab 1 - Basic Information (Syllabus Mapping)
- **Academic Context:** Class -> Subject -> Lesson (AJAX dependent).
- **Topic Hierarchy (Dynamic Selection):**
  - **Topic Level:** Dropdown selecting how deep the quiz goes (Level 1 to 4).
  - **Topic Dropdowns:** Based on the selected level, the `topic_1`, `topic_2`, `topic_3`, and `topic_4` dropdowns are sequentially enabled via AJAX. This allows a quiz to be mapped directly to a specific "Micro Topic".
- **Metadata:** Quiz Title, Assessment Type (`quiz_type_id`), Status (`DRAFT`, `PUBLISHED`, `ARCHIVED`).

### FR-02: Tab 2 - Configuration (Behavioral Rules)
- **Numerical Rules:** Duration (Min), Total Marks, Total Questions, Passing %, Negative Marks, Max Attempts.
- **Difficulty Linkage:**
  - **Difficulty Configuration ID:** Dropdown linking the quiz to a predefined Difficulty Matrix template.
  - **Ignore Difficulty Config:** A boolean toggle. If checked, the system will not enforce the difficulty matrix during question selection.
- **10 Advanced Behavioral Switches:**
  1. `allow_multiple_attempts`
  2. `is_randomized` (Shuffles question order for each student)
  3. `question_marks_shown`
  4. `is_system_generated` (Triggers AI auto-population based on Difficulty Config)
  5. `auto_publish_result`
  6. `timer_enforced`
  7. `show_correct_answer` (Post-quiz review)
  8. `show_explanation` (Post-quiz review)
  9. `only_unused_questions` (Restricts question bank to untouched questions)
  10. `only_authorised_questions`

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Deep Topic Targeting
**As a** Teacher,
**I want to** select "Level 3" in the Topic Level,
**So that** I can create a highly specific quiz targeting just a "Mini Topic" without bleeding into the broader lesson.

**Acceptance Criteria:**
- **Given** I select Level 3, **When** I do so, **Then** the `topic_1`, `topic_2`, and `topic_3` dropdowns become enabled via AJAX, while `topic_4` remains disabled.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Total Marks & Questions** | Integers > 0. Validated strictly on backend. |
| **Negative Marks** | Stored as a positive decimal (e.g., 0.25). Backend handles subtraction. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `sch_classes`, `sch_subjects`, `sch_lessons`, `sch_topics`, `lms_assessment_types`, `lms_difficulty_distribution_configs`.
- **Outgoing Dependencies:** `lms_quiz_questions`, `lms_quiz_allocations`.
