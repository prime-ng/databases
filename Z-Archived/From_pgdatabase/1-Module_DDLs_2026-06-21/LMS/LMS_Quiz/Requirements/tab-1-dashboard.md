# Quiz Tab 1: Dashboard

This is the first tab the teacher sees when they open the Quiz module. It gives a quick overview of everything happening with quizzes — summary numbers, charts, and recent activity — all in one place.

---

## How It Works

When the teacher opens this tab, they see several summary cards at the top. One card shows the total number of quizzes in the system. Another shows how many are currently published and available to students. A third shows the total questions assigned across all quizzes. A fourth shows how many students have been allocated to quizzes. And a fifth shows the total number of attempts made by students so far.

Below the summary cards, there are charts. One chart shows how student scores are distributed — how many students scored in each range from 0-20% up to 81-100%. Another shows quiz activity over the past year, month by month. A third breaks down quizzes by subject, so the teacher can see which subjects get the most assessment activity. A fourth shows quiz status breakdown — how many are in Draft, Published, Ongoing, or Completed.

At the bottom, there is a list of the most recently created or updated quizzes. Each entry shows the quiz title, its class and subject, its current status with a colored badge, and when it was created. The teacher can click any quiz title to go directly to that quiz's details.

Everything on this tab is read-only — it is designed for a quick visual check, not for taking actions. If the teacher wants to do something with a specific quiz, they click through to the relevant tab.

---

## Important Business Rules

- The data is always live — it queries the database in real time. For schools with many quizzes and students, the dashboard might take a moment to load. The summary cards appear one by one as the data comes in.
- If no quizzes exist yet, the cards all show zero and the charts are empty. A message appears: "Create your first quiz to see dashboard data."
- The dashboard only shows data for the teacher's own school. Admins see data across all schools in their system.
- All dashboard elements are read-only. No actions can be performed from this tab — it is purely informational.
- The recent quizzes list is limited to the 10 most recently updated quizzes. If the teacher needs to find an older quiz, they must use the Quiz Creation tab.
- Charts are rendered client-side using JavaScript charting libraries. Exporting charts requires using the browser's screenshot or print functionality.

---

## Deep Analysis

### Business Workflows & State Machines

The dashboard is a read-only aggregation view with no state transitions. It queries live data across multiple tables to render summary cards and charts. The workflow is:

1. Teacher navigates to Dashboard tab.
2. System fires parallel queries for: total quizzes, published quizzes, total questions assigned, total allocations, total attempts.
3. System fires additional queries for: score distribution bins, monthly activity counts, subject breakdown, status breakdown.
4. System fetches the 10 most recently updated quizzes with their metadata.
5. All data is rendered client-side. No write operations are triggered from this view.

There is no state machine for the dashboard itself — it is purely observational.

### Validation Rules & Edge Cases

| Scenario | Rule | Handling |
|---|---|---|
| No quizzes exist | All cards show 0, charts empty | Show placeholder: "Create your first quiz to see dashboard data." |
| Large dataset (many schools/quizzes) | Queries may be slow | Cards appear one-by-one as data arrives (lazy loading per card) |
| Teacher has no classes assigned | All counts show 0 | Dashboard still renders normally with zero values |
| Admin user | Bypass school-scoped filtering | Show data across all schools in the system |
| Score distribution with no attempts | All bins show 0 | Chart renders empty with no data point |
| Monthly chart — no activity in a month | That month shows 0 | Month still appears on the axis with zero bar |
| Subject breakdown — no quizzes for a subject | Subject omitted | Only subjects with at least one quiz appear |
| Recent quizzes list exceeds 10 | Only 10 most recent shown | Teacher must navigate to Tab 4 to find older quizzes |
| Real-time data — quiz status changes while viewing | Data may become stale | No auto-refresh; teacher must reload the tab |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | — | Count quizzes, group by status/subject, list recent |
| Quiz Questions | `lms_quiz_questions` | `quiz_id` → `lms_quizzes.id` | Count total questions assigned |
| Quiz Allocation | `lms_quiz_allocations` | `quiz_id` → `lms_quizzes.id` | Count allocations, derive student coverage |
| Subjects | `sch_subjects` | `subject_id` → `lms_quizzes.subject_id` | Subject breakdown chart |
| Classes | `sch_classes` | `class_id` → `lms_quizzes.class_id` | Class-scoped filtering |
| Student Attempts | `lms_quiz_attempts` (or similar) | `quiz_id` → `lms_quizzes.id` | Score distribution, attempt counts |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Dashboard | Teacher | `quiz.dashboard.view` |
| View Dashboard (all schools) | Admin | `quiz.dashboard.view.all` |
| Click through to quiz detail | Teacher | `quiz.dashboard.navigate` |

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
