# Learning — Online Exam Attempt Requirements

## 1. Functional Overview
A structured, proctored environment for attempting formal online exams, featuring section-wise questions, shuffle configurations, and gated result publishing.

---

## 2. Interactive Attempt Rules

### A. Exam Sections
- Displays questions grouped by section (e.g. Section A: MCQs, Section B: Descriptive).
- Supports question randomization within sections and option shuffling.

### B. Attempt Interface & Timer
- Displays remaining time. If the timer expires, the exam auto-submits.
- Enforces a 5-minute server-side grace period to allow submissions from slow network connections.
- Logs tab switches, keyboard shortcuts (e.g. copy-paste blocks), and camera violations.

### C. Submission & Evaluation
- Descriptive answers are marked as `EVALUATION_PENDING`.
- Results remain hidden until the teacher explicitly sets `is_result_published` to true on the parent exam model.

---

## 3. Database References
- **Models**:
  - `Modules\LmsExam\Models\ExamPaper`
  - `Modules\StudentPortal\Models\ExamAttempt`
  - `Modules\StudentPortal\Models\ExamAttemptAnswer`
- **Tables**:
  - `lms_exam_papers`
  - `lms_exam_attempts`
  - `lms_exam_attempt_answers`
