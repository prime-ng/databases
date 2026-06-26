# Learning — Quiz Attempt Requirements

## 1. Functional Overview
Manages the online quiz attempt interface, proctoring metrics, dynamic timers, and instant auto-grading features.

---

## 2. Interactive Attempt Rules & Details

### A. Gate Checks
- Verifies that the student has an active class/section/student allocation.
- Checks that the current time is before the cutoff date.
- Confirms that the attempts used count is less than the max attempts allowed.

### B. Attempt Interface
- **Timer Header**: Displays a live countdown timer. Triggering the cutoff time auto-submits all answered questions.
- **MCQ Questions**: Single or multiple choice selection options.
- **Asynchronous Checkpointing**:
  - Automatically saves student answers via AJAX calls to `lms_attempt_checkpoints` to prevent data loss.
- **Focus Tracking (Proctoring)**:
  - Detects focus switching (e.g. `blur` events when changing tabs) and logs activity violations. Exceeding violation limits flags the attempt for admin review.

### C. Auto-Grading & Remedial Logic
- Grades answers instantly upon submission.
- Supports negative marking values.
- **Remedial trigger**: If the student's score falls below the passing percentage, the system automatically creates and assigns a personalized remedial quiz.

---

## 3. Database References
- **Tables**:
  - `lms_quiz_allocations`
  - `lms_quiz_quest_attempts`
  - `lms_quiz_quest_attempt_answers`
  - `lms_attempt_checkpoints`
  - `lms_quiz_quest_results`
