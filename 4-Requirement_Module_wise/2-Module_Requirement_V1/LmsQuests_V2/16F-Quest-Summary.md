# Business Requirements Document (BRD)
## Module: LMS Quests
### Screen: Quest Summary & Paper Check

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quest Summary** screen tracks the live progress of an assigned Quest. It calculates real-time participation metrics and provides a dedicated "Paper Check" interface for teachers to manually evaluate subjective (essay/file upload) answers.

### 1.2 Why is this necessary? (Business Justification)
- **Hybrid Evaluation:** While MCQs are auto-graded by the system, subjective questions require a human to review text/attachments, assign marks, and provide qualitative feedback before final results are published.

---

## 2. Document Scope
- **In-Scope:** Tracking `lms_quest_allocations`, viewing student attempt lists, Manual Paper Checking, grading submissions, computing final percentages.
- **Out-of-Scope:** Auto-evaluation engine (handled during the actual student submission pipeline).

---

## 3. User Personas
1. **Teacher:** Reviews student submissions, grades subjective answers, and finalizes the assessment.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Summary Datagrid & Metric Projection
- **System Behavior (`LmsQuestController::index`):**
  - Queries `lms_quest_allocations` and uses Eloquent `withCount` to dynamically calculate state-based metrics without N+1 queries.
  - **In Progress Count:** Counts attempts where status is `IN_PROGRESS`.
  - **Submitted Count:** Counts attempts where status is `SUBMITTED`, `EVALUATED`, `RESULT_PUBLISHED`, or `TIMEOUT`.
  - **Checked Count:** Counts attempts where the related `answers` table has `evaluated_by IS NOT NULL`.
  - **Total Assigned Count:** Dynamically calculates the cohort size. If assigned to a CLASS, counts active students in that class. If SECTION, counts students in that section.

### FR-02: Paper Checking Interface (`questPaperCheck`)
- **Action:** Click "Check Paper" for a student's attempt.
- **System Behavior (`getStudentAttemptData` AJAX):**
  - Loads the student's `lms_quiz_quest_attempts`.
  - Loads the related `lms_quiz_quest_attempt_answers`.
  - Parses JSON attachment data (if any) and converts it to tenant-aware secure file URLs via `LmsStorageService`.
  - Compares `marks_obtained` vs `max_marks`.

### FR-03: Finalizing Grades (`gradeSubmission`)
- **Action:** Input marks and click "Grade Submission".
- **System Behavior:**
  - Validates `marks_obtained` <= `max_marks`.
  - Calculates final `percentage = (obtained / max) * 100`.
  - Computes `GradeLetter` based on percentage.
  - Evaluates passing criteria based on `passing_percentage` from the Quest configuration.
  - Updates the attempt status to `EVALUATED`.
  - Upserts a record into `lms_quiz_quest_results`.
  - Emits the `QuizQuestResultPublished` event.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Manual Evaluation
**As a** Teacher,
**I want to** review a student's file upload answer,
**So that** I can award them 4 out of 5 marks and finalize their result.

**Acceptance Criteria:**
- **Given** I open the Paper Check UI, **When** I input 4 marks and click Save, **Then** the `lms_quiz_quest_attempt_answers` table is updated with `marks_obtained = 4`, the total percentage is recalculated, and the result is published.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quest_allocations`, `lms_quiz_quest_attempts`, `lms_quiz_quest_attempt_answers`.
- **Outgoing Dependencies:** `lms_quiz_quest_results` (Finalized grades), `QuizQuestResultPublished` Event.
