# Student Quiz Experience (Student Portal)

This describes what students see and do when they take a quiz. Teachers do not see these screens directly, but understanding the student experience is important for knowing what the system does on the other side.

---

## Seeing Available Quizzes

When a student logs into their account and goes to "My Quizzes," they see a list of quizzes that have been allocated to them. Each quiz shows the title, subject, duration, number of questions, and the deadline. The status tells them whether they have not started, are in progress, or have completed it. If the quiz allows multiple attempts, it shows how many attempts remain.

A quiz only appears here if three things are all true. First, the teacher must have published it. Second, there must be an allocation that includes this student. Third, the current time must be within the quiz's schedule window. If any one of these is missing, the quiz is invisible to the student.

---

## Starting the Quiz

When the student clicks "Start Quiz," the system runs a series of checks. Is the quiz published? Is it within the schedule? Does the student have attempts remaining? Is there an unfinished attempt they should resume instead?

If all checks pass, the student sees an instructions page. This shows the quiz title, the teacher's instructions, the number of questions, the total marks, and the time limit. The student clicks "Begin" to start. The timer starts counting down, and the first question appears.

---

## Answering Questions

Students navigate through the quiz one question at a time. For each question, the input method depends on the type. MCQ Single shows radio buttons — the student clicks one option. MCQ Multi shows checkboxes — they can select multiple. True/False shows two radio buttons. Short Answer shows a text box where they type up to 500 characters. Long Answer shows a rich text editor for longer responses up to 5000 characters. Fill in the Blanks shows small text boxes embedded in the question. Matching lets them drag items to pair them correctly.

As the student works, every answer saves automatically. There is no "Save" button to click. When they select an option or type an answer, it is sent to the server immediately. A small "Saved" message appears briefly as confirmation. If the internet disconnects, the answers are saved locally and sync when the connection comes back.

The student can flag questions they want to review later. A question palette on the side shows all question numbers color-coded — green for answered, gray for unanswered, orange for flagged. The student can click any number to jump directly to that question.

---

## Timer and Submission

A countdown timer is always visible at the top of the screen. When 5 minutes remain, the timer turns yellow. At 1 minute, it turns red and flashes. When time runs out, the quiz submits automatically. Any unanswered questions are scored as zero.

The student can also submit manually by clicking the "Submit" button. The system shows a confirmation dialog: "You have X unanswered questions. Are you sure you want to submit?" If the student confirms, the quiz is submitted.

If the student closes the browser mid-quiz, the timer keeps running on the server. They can come back later and resume if time remains. If the timer expires while they are away, the quiz auto-submits with whatever answers were saved.

---

## Results

After submission, what the student sees depends on the teacher's settings. If "Show Result" was turned on, the student sees their score, percentage, pass or fail status, and their rank in the class. If "Show Answer Key" was also turned on, they see which questions they got right and wrong, with the correct answers displayed.

If "Show Result" was turned off, the student sees only: "Your quiz has been submitted successfully. Results will be available after the teacher reviews them." They must wait for the teacher to release results.

If the quiz had descriptive questions, the result shown after submission only includes the automatically scored parts. The final score updates after the teacher grades the written answers.

---

## Retaking the Quiz

If the teacher allowed multiple attempts, the student sees a "Retake" button after completing. Each retake starts a completely fresh attempt with re-shuffled questions and a reset timer. Previous attempts are preserved for reference. The quiz card shows the best score achieved across all attempts.

---

## Anti-Cheating Measures

While the student takes the quiz, the system watches for several things. If the student switches to another browser tab, the system logs it and shows a warning overlay. After three tab switches, the teacher is notified. Right-clicking is disabled. Copy and paste are disabled within the quiz page. The quiz attempts to go fullscreen — if the student exits fullscreen, that is also logged.

After the quiz, the system checks for suspicious patterns. Was the quiz completed too fast? Were all answers the same option? Did the student get easy questions wrong but hard ones right? These patterns are flagged in the teacher's report but do not automatically invalidate the quiz. The teacher reviews and decides.

---

## Remedial Quizzes

If the student fails the quiz and the assessment type supports remedial learning, a message appears on the result page: "A practice quiz has been created to help you improve." The student can start the remedial quiz immediately. It has a higher passing threshold — 70% instead of the usual 33% — and the answer key is always shown so the student can learn from their mistakes. They can retry the remedial quiz up to three times. If they fail all three attempts, a message says "Please contact your teacher for additional help."

---

## Important Business Rules

- A quiz appears in the student's list only if all three conditions are met: quiz is Published, student has an active allocation, and current time is within the schedule window. If any condition fails, the quiz is hidden entirely.
- Auto-save occurs on every answer change. There is no manual save button. If the internet disconnects, answers are stored in the browser's local storage and synced when the connection returns.
- The timer runs on the server side. Closing the browser does not pause the timer. When the student returns, the timer reflects the actual elapsed time.
- Auto-submission due to time expiry scores all unanswered questions as zero. There is no partial credit for unattempted questions.
- If "Show Answer Key" is enabled, students see correct answers only after the quiz window closes completely — not immediately after individual submission. This prevents answer sharing among students who take the quiz at different times.
- The remedial quiz passing threshold is fixed at 70%. This is not configurable. The standard quiz threshold defaults to 33% but can be set by the teacher during quiz creation.
- Multiple attempts are independent. Each attempt starts with fresh question randomization (if shuffling is enabled) and a reset timer. The best score across all attempts is shown on the quiz card.
- Anti-cheating measures are observational only. They log events and notify the teacher but do not automatically block or invalidate the quiz. The teacher reviews the evidence and decides on any action.
- The connection lost/restored event is logged with timestamps. This helps teachers verify student claims of internet issues during the quiz.
- Answer key visibility is governed by the teacher's settings and the quiz schedule. Even if "Show Answer Key" is enabled, answers are revealed only after the quiz's scheduled end time has passed.

---

## Deep Analysis

### Business Workflows & State Machines

**Student Quiz Attempt State Machine:**

| Current State | Transition | Trigger | Next State | Conditions |
|---|---|---|---|---|
| Not Started | View Quiz List | Student navigates to "My Quizzes" | Not Started | Quiz must be Published, allocated, and in schedule window |
| Not Started | Start Quiz | Student clicks "Start Quiz" | Instructions Page | Passes pre-checks (published, scheduled, attempts remaining, no unfinished attempt) |
| Instructions Page | Begin | Student clicks "Begin" | In Progress | Timer starts; question 1 displayed |
| In Progress | Answer Question | Student selects/enters answer | In Progress | Auto-saved immediately |
| In Progress | Navigate | Student jumps to another question | In Progress | Via question palette |
| In Progress | Flag Question | Student flags for review | In Progress | Visual marker only |
| In Progress | Submit Manually | Student clicks "Submit" | Submitted | Confirmation dialog shown |
| In Progress | Time Expires | Timer reaches 0 | Submitted (Auto) | Auto-submit; unanswered = 0 |
| In Progress | Browser Close | Student closes tab/window | In Progress (Paused) | Timer continues server-side; student can resume |
| In Progress | Resume | Student reopens and resumes | In Progress | Time remaining reflects elapsed time |
| Submitted | View Results | Student views result screen | Results | Depends on "Show Result" and "Show Answer Key" settings |
| Submitted | Retake | Student clicks "Retake" | Not Started (New Attempt) | Multiple attempts allowed; attempts remaining > 0 |
| Submitted | Remedial Trigger | System detects failure + type supports remedial | Remedial Quiz Created | System generates remedial quiz automatically |

**Visibility Decision Tree:**
```
Quiz Visible to Student?
├── Is quiz status = PUBLISHED? ─── NO → Hidden
├── Is there an active allocation for this student? ─── NO → Hidden
├── Is current time within any allocation's schedule? ─── NO → Hidden
└── All YES → Quiz Appears in "My Quizzes"
```

**Remedial Quiz Flow:**
1. Student fails quiz (score < passing_percentage).
2. System checks assessment type code (FORMATIVE, DIAGNOSTIC, UNIT_TEST, REVISION).
3. If match, system creates a remedial quiz using the configured difficulty distribution.
4. Remedial quiz: passing threshold = 70% (fixed), answer key always shown.
5. Student can retry up to 3 times.
6. After 3 failures: "Please contact your teacher for additional help."

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Start Quiz – Not Published | Quiz must be Published | "This quiz is not yet available." |
| Start Quiz – No Allocation | Student must be allocated | "You have not been assigned this quiz." |
| Start Quiz – Outside Schedule | Current time must be within window | "This quiz is not available at this time." |
| Start Quiz – No Attempts Remaining | Must have > 0 attempts left | "You have used all your attempts for this quiz." |
| Start Quiz – Unfinished Attempt | Must resume instead of starting new | "You have an unfinished attempt. Please resume it." |
| Auto-Save – Offline | Answers stored locally | Synced on reconnection |
| Submit – Unanswered Questions | Confirmation required | "You have X unanswered questions. Are you sure?" |
| Time Expiry – Unanswered | Scored as zero | No error; automatic |
| Retake – Max Attempts Reached | Cannot retry | "No attempts remaining." |
| Answer Key – Timing | Only shown after quiz window closes | "Answers will be available after the quiz ends." |
| Remedial – Passing Threshold | Fixed 70% | No error |
| Remedial – Max Retries | 3 attempts | "You have exhausted your remedial attempts." |
| Descriptive Answers – Final Score | Updated after teacher grades | "Your final score will be available after grading." |
| Show Result Off | No score shown | "Your quiz has been submitted successfully. Results will be available after the teacher reviews them." |
| Anti-Cheating – Tab Switch > 3 | Teacher notified | Warning overlay shown; quiz continues |
| Anti-Cheating – Right Click | Disabled | Prevented via JavaScript |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `id` | Quiz metadata, settings, schedule |
| Quiz Allocations | `lms_quiz_allocations` | `quiz_id` → `lms_quizzes.id`, `target_id` → student | Determine which quizzes a student can see |
| Quiz Questions | `lms_quiz_questions` | `quiz_id` → `lms_quizzes.id` | Questions for the quiz |
| Question Bank | `qns_questions_bank` | `id` → `lms_quiz_questions.question_id` | Question content, type, options, answers |
| Student Attempts | (attempts table) | `quiz_id`, `student_id` | Track attempt state, answers, score |
| Students | `std_students` | `id` | Student identity, class/section membership |
| Assessment Types | `lms_assessment_types` | `id` → `lms_quizzes.quiz_type_id` | Determine remedial behavior |
| Remedial Quiz | `lms_quizzes` (system-generated) | `is_system_generated = 1` | Auto-created remedial quizzes |
| Difficulty Config | `lms_difficulty_distribution_configs` | `use_for_system_generated_quiz = 1` | Rules for generating remedial quiz content |
| Activity Log | (log table) | `quiz_id`, `student_id`, `attempt_id` | Log all events during attempt |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Available Quizzes | Student | `student.quiz.view-list` |
| Start Quiz | Student | `student.quiz.start` |
| Answer Questions | Student | `student.quiz.answer` |
| Submit Quiz | Student | `student.quiz.submit` |
| Retake Quiz | Student | `student.quiz.retake` |
| View Results | Student | `student.quiz.view-results` |
| View Answer Key | Student | `student.quiz.view-answer-key` |
| View Remedial Quiz | Student | `student.quiz.remedial` |

---

## Database Columns & Behavior

### Table: `lms_quizzes`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `uuid` | BINARY(16) | No | No | — | Unique identifier for the quiz |
| `academic_session_id` | INT UNSIGNED | Yes → `glb_academic_sessions.id` | No | — | Links quiz to academic session |
| `class_id` | INT UNSIGNED | Yes → `sch_classes.id` | No | — | Links quiz to a class |
| `subject_id` | INT UNSIGNED | Yes → `sch_subjects.id` | No | — | Links quiz to a subject |
| `lesson_id` | INT UNSIGNED | Yes → `sch_lessons.id` | No | — | Links quiz to a lesson |
| `scope_topic_id` | INT UNSIGNED | Yes → `slb_topics.id` | Yes | NULL | Primary scope topic; if sub-topic, all child topics included |
| `quiz_type_id` | INT UNSIGNED | Yes → `lms_assessment_types.id` | No | — | Determines quiz behavior (Practice, Exam, etc.) |
| `quiz_code` | VARCHAR(50) | No | No | — | Auto-generated unique code (e.g. QUIZ_9TH_SCI_L01_...) |
| `title` | VARCHAR(100) | No | No | — | Quiz title, editable anytime |
| `description` | VARCHAR(255) | No | Yes | NULL | Optional quiz description |
| `instructions` | TEXT | No | Yes | NULL | Supports HTML/Markdown/JSON/LaTeX |
| `status` | VARCHAR(20) | No | No | 'DRAFT' | DRAFT, PUBLISHED, ARCHIVED |
| `duration_minutes` | TINYINT UNSIGNED | No | Yes | NULL | NULL = unlimited time |
| `total_marks` | DECIMAL(8,2) | No | No | 0.00 | Sum of question marks, recalculated |
| `total_questions` | INT UNSIGNED | No | No | 0 | Count of questions, recalculated |
| `passing_percentage` | DECIMAL(5,2) | No | No | 33.00 | Default 33% if not set |
| `allow_multiple_attempts` | TINYINT(1) | No | No | 0 | 0 = single attempt only |
| `max_attempts` | TINYINT UNSIGNED | No | No | 1 | Max attempts if multiple allowed |
| `negative_marks` | DECIMAL(4,2) | No | No | 0.00 | Per-question negative marking factor; 0 = disabled |
| `is_randomized` | TINYINT(1) | No | No | 0 | Randomize question order per student |
| `question_marks_shown` | TINYINT(1) | No | No | 0 | Show marks per question during attempt |
| `show_result_immediately` | TINYINT(1) | No | No | 0 | Show result to student right after submission |
| `auto_publish_result` | TINYINT(1) | No | No | 0 | Auto-publish results after due date |
| `timer_enforced` | TINYINT(1) | No | No | 1 | Show and enforce timer |
| `show_correct_answer` | TINYINT(1) | No | No | 0 | Show correct answers after quiz closes |
| `show_explanation` | TINYINT(1) | No | No | 0 | Show explanation for each answer |
| `difficulty_config_id` | INT UNSIGNED | Yes → `lms_difficulty_distribution_configs.id` | Yes | NULL | Linked difficulty distribution config |
| `ignore_difficulty_config` | TINYINT(1) | No | No | 0 | If 1, difficulty config is ignored |
| `is_system_generated` | TINYINT(1) | No | No | 0 | 1 = system-generated (remedial) quiz |
| `only_unused_questions` | TINYINT(1) | No | No | 0 | Only include questions not in usage log |
| `only_authorised_questions` | TINYINT(1) | No | No | 0 | Only include questions marked for quiz use |
| `created_by` | INT UNSIGNED | Yes → `sys_users.id` | Yes | NULL | Teacher/admin who created; NULL = system |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |

### Table: `lms_quiz_allocations`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `quiz_id` | INT UNSIGNED | Yes → `lms_quizzes.id` | No | — | FK to the quiz |
| `allocation_type` | ENUM('CLASS','SECTION','GROUP','STUDENT') | No | No | — | Type of target entity |
| `target_table_name` | VARCHAR(60) | No | No | — | Name of target table (e.g. sch_classes) |
| `target_id` | INT UNSIGNED | No | No | — | ID of target entity (FK enforced at app level) |
| `assigned_by` | INT UNSIGNED | Yes → `sys_users.id` | Yes | NULL | Teacher/admin who assigned |
| `published_at` | DATETIME | No | Yes | NULL | Visible from date/time |
| `due_date` | DATETIME | No | Yes | NULL | Due by date/time |
| `cut_off_date` | DATETIME | No | Yes | NULL | No submissions after this |
| `is_auto_publish_result` | TINYINT(1) | No | No | 0 | Overrides quiz-level auto_publish_result |
| `result_publish_date` | DATETIME | No | Yes | NULL | Results visible from date |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |

### Table: `lms_quiz_questions`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `quiz_id` | INT UNSIGNED | Yes → `lms_quizzes.id` | No | — | FK to the quiz |
| `question_id` | INT UNSIGNED | Yes → `qns_questions_bank.id` | No | — | FK to question bank |
| `ordinal` | INT UNSIGNED | No | No | 0 | Display order in quiz |
| `marks_override` | DECIMAL(5,2) | No | Yes | NULL | Override question's default marks; NULL = use bank default |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP ON UPDATE | Last update time |
| `deleted_at` | TIMESTAMP | No | Yes | NULL | Soft-delete timestamp |
