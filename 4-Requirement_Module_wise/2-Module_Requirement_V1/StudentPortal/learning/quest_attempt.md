# Learning — Quest Attempt Requirements

## 1. Functional Overview
Manages the quest attempt interface, which supports descriptive answers, file uploads, and a combination of auto-grading and teacher evaluation.

---

## 2. Interactive Attempt Rules

### A. Question Formats
- **MCQ Portion**: Treated and graded instantly using the auto-grading engine.
- **Descriptive Portion**: SHORT_ANSWER and LONG_ANSWER questions. Provides a text area for typing answers and a file uploader (Max 5MB PDF/JPG/PNG) to attach written work.

### B. Verification & Auto-save
- Options selected and text entered are periodically saved to `lms_attempt_checkpoints` via AJAX.

### C. Post-Submission Status
- If the quest contains descriptive questions, it is marked as `EVALUATION_PENDING` and must be manually evaluated by a teacher before results are released.

---

## 3. Database References
- **Models**:
  - `Modules\LmsQuests\Models\Quest`
  - `Modules\StudentPortal\Models\QuizQuestAttemptAnswer`
- **Tables**:
  - `lms_quests`
  - `lms_quiz_quest_attempts`
  - `lms_quiz_quest_attempt_answers`
