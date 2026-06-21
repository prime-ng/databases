# Quiz Tab 4: Quiz Creation

This is the main tab where teachers create, view, and manage quizzes. Building a quiz happens in stages — first setting up the structure and rules, then adding questions, then assigning students, and finally publishing.

---

## Section 1: Creating a New Quiz

When the teacher clicks "Create New Quiz," they are taken to a form where they set up everything about the quiz.

**Basic Information:** The teacher gives the quiz a title and picks an assessment type — Practice, Formative, Summative, etc. This choice determines some behaviors later (like whether failing students get remedial quizzes). The type cannot be changed after saving. The teacher picks a class, subject, lesson, and topic. These also become locked after saving — they determine which questions from the Question Bank will be available when the teacher reaches the question selection step.

**Duration and Attempt Settings:** The teacher sets how long students have to complete the quiz, in minutes. If they enter 0, there is no time limit at all. They set passing marks — if left blank, the default is 33% of the total. They can enable negative marking, which deducts points for wrong answers based on each question's negative marks value.

The teacher decides whether to shuffle questions so each student sees them in a different order, and whether to shuffle the answer options within each question. They can choose whether students see results immediately after submitting, and whether the answer key is shown. They set how many attempts each student gets — 1 by default, up to 10, or 0 for unlimited.

Several toggle switches control additional features. The teacher can let students pause and resume the quiz (the timer pauses too), provide an in-browser calculator or formula sheet, and enable basic proctoring that tracks when a student switches to another browser tab.

**Schedule:** The teacher sets when the quiz is available. "Now" means it becomes available immediately after publishing. "Schedule" means it is available daily between two times — for example, 9 AM to 10 AM every day. "Date Range" means it is available only between specific dates and times — for example, March 20 at 9 AM to March 25 at 5 PM.

The teacher can also write instructions that students will see before starting the quiz.

When they click Save, the quiz is created in Draft status. They still need to add questions and assign students before it is ready.

---

## Section 2: How a Quiz Lives Through Its States

A quiz moves through several states during its life. Draft means the teacher is still building it. Pending means questions have been added but the quiz is not yet published. Published means students can see it and take it (according to the schedule). Ongoing means students are actively taking it. Completed means the quiz window has closed. Cancelled means the teacher took it down. Archived means it has been retired for record-keeping.

The teacher publishes the quiz when it is ready. At that point, students who have been allocated can see it. Once a student starts the quiz, most settings become locked. The teacher can no longer cancel the quiz, change the assessment type, add or remove questions, or change the class or subject. They can still adjust the duration, passing marks, and some toggle settings.

If the teacher needs to make changes after publishing, they are limited by the quiz's current state. During Ongoing, only duration and passing marks can be changed. During Completed, nothing can be changed at all.

---

## Section 3: Editing and Deleting

Editing is allowed freely while the quiz is in Draft or Pending. Once published, the restrictions kick in. The class, subject, lesson, and topic are locked at creation — they cannot be changed later at all.

If the teacher deletes a quiz, what happens depends on the state. A Draft quiz can be deleted entirely. A quiz with student attempts can only be soft-deleted — hidden but preserved for historical records. A quiz that is currently being taken cannot be deleted at all.

When a quiz is deleted, its question assignments and allocations are also removed. But student attempt data is preserved — those records exist independently and are not deleted.

---

## Important Business Rules

- The assessment type, class, subject, lesson, and topic are locked once the quiz is saved for the first time. They cannot be changed later under any circumstances.
- A quiz with zero duration means no time limit. The student can take as long as they need, but the quiz still records the total time spent.
- The passing marks default to 33% of the total quiz marks if left blank. This default is calculated dynamically based on the questions added later.
- If negative marking is enabled, each wrong answer deducts the negative marks value set on that specific question. Unanswered questions are not penalized — they simply get zero.
- The quiz title can be changed at any time, even after publishing. Only the core settings (type, class, subject, lesson, topic) are locked.
- Publishing requires at least one question to be added and at least one student to be allocated. If either is missing, the publish action is blocked with a clear error message.
- Soft-deleted quizzes are hidden from the main list but still exist in the system. They can be restored by an administrator if needed.
- The schedule uses the school's configured timezone. Daylight saving changes are handled automatically by the system.
- Once a student has started the quiz, the teacher can only modify the duration and passing marks. No changes to questions, allocations, or settings are allowed.
- The "Show Result" and "Show Answer Key" settings can be toggled on or off even after the quiz is published. Changes apply to future views — students who already submitted see results based on the settings at their time of submission.

---

## Deep Analysis

### Business Workflows & State Machines

**Quiz Lifecycle State Machine:**

| Current State | Transition | Trigger | Next State | Conditions / Actions |
|---|---|---|---|---|
| Draft | Save | Teacher creates new quiz | Draft | Core fields locked (type, class, subject, lesson, topic) |
| Draft | Add Questions | Teacher adds ≥1 question | Pending | Questions added to `lms_quiz_questions` |
| Draft | Publish | Teacher clicks Publish | Published | **Blocked** if no questions or no allocations exist |
| Pending | Add/Remove Questions | Teacher modifies questions | Pending | State unchanged |
| Pending | Publish | Teacher clicks Publish | Published | Must have ≥1 question and ≥1 allocation |
| Published | Student Starts | First student begins | Ongoing | Timer starts; most settings lock |
| Published | Cancel | Teacher clicks Cancel | Cancelled | Allowed only if no student has started |
| Ongoing | All Students Complete / Time Window Closes | Last student submits or due date passes | Completed | Auto-transition |
| Ongoing | Cancel | Teacher clicks Cancel | Cancelled | **Blocked** if any student has started |
| Ongoing | Modify Duration | Teacher edits | Ongoing | Only duration and passing marks editable |
| Completed | Archive | Teacher or system archives | Archived | Record-keeping state |
| Completed | — | — | Completed | No modifications allowed |
| Cancelled | — | — | Cancelled | No modifications allowed |
| Archived | Restore | Admin restores | Published | Admin-only action |
| Draft | Delete | Teacher deletes | Deleted | Hard delete allowed |
| Published/Ongoing | Delete | Teacher deletes | Soft-deleted | Soft delete (preserves attempts); **blocked** if actively being taken |
| Completed/Cancelled | Delete | Teacher deletes | Soft-deleted | Soft delete only |

**Schedule Evaluation Flow:**
1. Quiz saved with schedule type: Now, Schedule (daily window), or Date Range.
2. Schedule stored in `lms_quizzes` (or related schedule table if separated).
3. At runtime, system evaluates: `is_published AND current_time BETWEEN schedule_start AND schedule_end`.
4. If no schedule is set, quiz is available immediately after publishing.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Title | Required, max 100 chars | "Quiz title is required." |
| Assessment Type | Required; locked after save | "Assessment type cannot be changed after saving." |
| Class/Subject/Lesson/Topic | Required; locked after save | "Class, subject, lesson, and topic cannot be changed after saving." |
| Duration | 0 = no limit; must be ≥ 0 | "Duration must be 0 (unlimited) or a positive number." |
| Passing % | If blank, defaults to 33% | No error; default applied dynamically |
| Negative Marks | Per-question value; 0 = disabled | No error |
| Max Attempts | 0 = unlimited, 1–10 = limited | "Max attempts must be between 0 and 10." |
| Publish – No Questions | Quiz must have ≥ 1 question | "Cannot publish. Add at least one question first." |
| Publish – No Allocations | Quiz must have ≥ 1 allocation | "Cannot publish. Allocate at least one student first." |
| Publish – Published Already | Cannot publish twice | "Quiz is already published." |
| Delete – Active Attempts | Cannot delete while students taking | "Cannot delete quiz while students are taking it." |
| Cancel – Active Attempts | Cannot cancel while students taking | "Cannot cancel quiz while students are taking it." |
| Edit – Ongoing | Only duration and passing marks | "Only duration and passing marks can be changed while quiz is ongoing." |
| Edit – Completed | No changes allowed | "No changes allowed after quiz is completed." |
| Schedule – Invalid Date Range | Start must be before end | "Schedule start date must be before end date." |
| Instructions – Format | Supports HTML/Markdown/JSON/LaTeX | No validation on content |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Assessment Types | `lms_assessment_types` | `quiz_type_id` → `lms_assessment_types.id` | Determines quiz behavioral type |
| Academic Sessions | `glb_academic_sessions` | `academic_session_id` → `glb_academic_sessions.id` | Links quiz to current academic session |
| Classes | `sch_classes` | `class_id` → `sch_classes.id` | Scope: which class this quiz is for |
| Subjects | `sch_subjects` | `subject_id` → `sch_subjects.id` | Scope: which subject this quiz covers |
| Lessons | `sch_lessons` | `lesson_id` → `sch_lessons.id` | Scope: which lesson this quiz covers |
| Topics | `slb_topics` | `scope_topic_id` → `slb_topics.id` | Scope: which topic (or sub-topic) this quiz covers |
| Difficulty Config | `lms_difficulty_distribution_configs` | `difficulty_config_id` → `lms_difficulty_distribution_configs.id` | Links optional difficulty distribution rules |
| Question Bank | `qns_questions_bank` | Via `lms_quiz_questions.question_id` | Source of questions for the quiz |
| Quiz Questions | `lms_quiz_questions` | `quiz_id` → `lms_quizzes.id` | Junction for questions assigned to this quiz |
| Quiz Allocations | `lms_quiz_allocations` | `quiz_id` → `lms_quizzes.id` | Students/groups assigned to this quiz |
| Users | `sys_users` | `created_by` → `sys_users.id` | Tracks who created the quiz |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Quiz List | Teacher | `quiz.creation.view` |
| Create Quiz | Teacher | `quiz.creation.create` |
| Edit Quiz (Draft/Pending) | Teacher | `quiz.creation.edit` |
| Edit Quiz (Ongoing) | Teacher | `quiz.creation.edit-ongoing` |
| Edit Quiz (Completed) | — | Not allowed |
| Delete Quiz (Draft) | Teacher | `quiz.creation.delete` |
| Delete Quiz (Soft) | Teacher | `quiz.creation.soft-delete` |
| Publish Quiz | Teacher | `quiz.creation.publish` |
| Cancel Quiz | Teacher | `quiz.creation.cancel` |
| Archive Quiz | Admin | `quiz.creation.archive` |
| Restore Quiz | Admin | `quiz.creation.restore` |
| View All Quizzes | Admin | `quiz.creation.view.all` |

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
