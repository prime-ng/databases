# Quiz Reports Page (6 Reports)

This is a separate page from the main quiz tabs, dedicated entirely to reports and analytics. There are six different report types, each designed to answer a specific question about student performance.

---

## Report 1: Class Performance Report

This report answers: "How did my class do on a specific quiz?"

The teacher selects a quiz and sees an overview — total students, how many attempted, how many passed, how many failed, the average score, and the highest and lowest scores. Below the overview is a list of every student with their score, percentage, pass/fail status, time taken, and rank.

The teacher can filter the list to show only students who passed or only those who failed. They can narrow by score range. They can search for a specific student by name. They can sort by score, name, or rank.

This report is useful for distributing results to students or parents, or for importing into a grade book. The teacher can export it as a CSV file.

---

## Report 2: Teacher Monthly Report

This report answers: "How many quizzes did I assign this month, and how did students perform?"

The teacher selects a month and sees a calendar view. Each day shows how many quizzes were assigned on that day. Hovering over a day shows the quiz titles, how many students attempted them, and the average score. Monthly totals are shown at the bottom.

The teacher can filter by class or subject to narrow the view. For example, they can see just their Science quizzes in January.

This report is useful for tracking workload and identifying busy or slow periods.

---

## Report 3: Student Performance Summary

This report answers: "How is a specific student doing across all quizzes in a subject?"

The teacher selects a student and a subject and sees a date-by-date matrix. For each quiz the student took, it shows the quiz name, score, and percentage. A trend line shows whether the student is improving, declining, or staying consistent. The student's average across all quizzes is compared to the class average.

This report is useful for parent-teacher meetings — it shows a student's trajectory over time, not just a single score.

---

## Report 4: Student Detailed Assessment

This report answers: "How is this student performing in detail?"

The teacher selects a student and sees each quiz they took, categorized by performance level. Outstanding (90% and above), Good (75-89%), Satisfactory (60-74%), Needs Attention (33-59%), or Struggling (below 33%). Each quiz shows the score, percentage, how many questions were answered correctly, and how long the student took.

This report is useful for identifying specific areas where a student needs help. If most of their quizzes are in the "Needs Attention" range, the teacher knows to intervene.

---

## Report 5: Periodic Detail Report

This report answers: "What happened with all quizzes in a given period?"

The teacher selects a class, subject, and date range and sees a comprehensive table. Each row is a quiz, showing how many students were allocated, how many attempted, how many completed, how many passed, and how many failed. Students who have not attempted each quiz are listed.

This report is useful for administrators and heads of department who want a broad view of assessment activity over a month or term.

---

## Report 6: Current Class Performance

This report answers: "How is my class performing on each topic?"

The teacher selects a class and subject and sees a list of all topics covered. Each topic shows the number of quizzes taken on it, the class average score, and how many students have been assessed. Topics are color-coded — red for topics where the class average is below 50% (needs attention), gray for topics that have not been quizzed yet, yellow for 50-74%, and green for 75% and above.

This report is useful for planning lessons — if a topic is in red, the teacher knows to re-teach it. If a topic is gray, they know they have not assessed it yet.

---

## Important Business Rules

- Reports only show data for classes and subjects the teacher has access to. Admins can see everything across the school. Students have their own simplified versions of the summary and detailed reports through the Student Portal.
- Each report can be printed or exported. The Class Performance and Periodic Detail reports support CSV export for data analysis.
- If no data matches the selected filters, the report shows "No data available for the selected filters." This is not an error — it just means nothing matches the criteria.
- The Teacher Monthly Report shows quizzes by the date they were assigned, not by the date they were taken. A quiz assigned in January but taken in February appears in January's report.
- The Student Performance Summary compares the student's average to the class average. The class average is recalculated each time the report is generated.
- Performance levels in the Student Detailed Assessment are based on hard-coded thresholds: 90%+ = Outstanding, 75-89% = Good, 60-74% = Satisfactory, 33-59% = Needs Attention, below 33% = Struggling. These thresholds are not configurable.
- The Current Class Performance report shows topics that have been quizzed at least once. Topics that exist in the curriculum but have not been quizzed appear in gray.
- All report exports include a generation timestamp and filter criteria in the file metadata or header.
- Reports with fewer than 5 students suppress percentile and rank calculations to prevent individual identification.

---

## Deep Analysis

### Business Workflows & State Machines

**Report Generation Workflow (all reports):**
1. Teacher navigates to Reports page.
2. Teacher selects a report type from the six available.
3. Teacher configures filters (quiz, student, class, subject, month, date range, etc.).
4. System queries relevant tables based on report type and filters.
5. Data is aggregated, computed, and rendered.
6. Teacher can export (CSV for Report 1 and Report 5) or print.
7. No data is written during report generation — purely read-only analytics.

**Report-Specific Data Pipelines:**

| Report # | Name | Primary Source Tables | Key Computations |
|---|---|---|---|
| 1 | Class Performance | `lms_quizzes`, `lms_quiz_allocations`, attempts/answers | Score, pass/fail, rank, percentile |
| 2 | Teacher Monthly | `lms_quizzes` (created_by, created_at) | Quiz count by day, attempt counts, avg scores |
| 3 | Student Performance Summary | `lms_quizzes`, attempts/answers | Per-quiz scores, trend, student avg vs class avg |
| 4 | Student Detailed Assessment | `lms_quizzes`, attempts/answers | Score bucket classification, per-quiz detail |
| 5 | Periodic Detail | `lms_quizzes`, `lms_quiz_allocations`, attempts | Allocated/attempted/completed/passed/failed counts |
| 6 | Current Class Performance | `lms_quizzes`, `slb_topics`, attempts | Topic-wise avg score, color coding |

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Report 1 – No Quiz Selected | Must select a quiz | "Please select a quiz to view the report." |
| Report 1 – No Attempts | Empty report | "No attempts yet for this quiz." |
| Report 2 – No Month Selected | Must select a month | "Please select a month." |
| Report 2 – No Quizzes in Month | Empty calendar | "No quizzes assigned in this month." |
| Report 3 – No Student Selected | Must select a student | "Please select a student." |
| Report 3 – No Subject Selected | Must select a subject | "Please select a subject." |
| Report 4 – No Student Selected | Must select a student | "Please select a student." |
| Report 5 – Date Range Invalid | Start must be before end | "Start date must be before end date." |
| Report 5 – No Data | Empty table | "No data available for the selected filters." |
| Report 6 – No Class/Subject | Must select both | "Please select a class and subject." |
| Report 6 – No Topics Quizzes | All topics gray | "No quizzes have been taken on any topic yet." |
| All Reports – < 5 Students | Percentile/rank suppressed | "Percentile and rank not shown for fewer than 5 students." |
| CSV Export – No Data | Empty file | "No data to export." |
| CSV Export – Header | Includes timestamp and filter criteria | Added automatically |
| Teacher Data Scope | Only teacher's own classes | No error; queries scoped by default |
| Admin Data Scope | All classes across school | No error; full access |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `id` | Base table for all reports |
| Quiz Allocations | `lms_quiz_allocations` | `quiz_id` → `lms_quizzes.id` | Student allocation counts |
| Quiz Questions | `lms_quiz_questions` | `quiz_id` → `lms_quizzes.id` | Question count per quiz |
| Student Attempts | (attempts table) | `quiz_id` → `lms_quizzes.id`, `student_id` | Core data for all performance reports |
| Students | `std_students` | `id` | Student name, class, section |
| Classes | `sch_classes` | `id` → `lms_quizzes.class_id` | Class-scoped reporting |
| Subjects | `sch_subjects` | `id` → `lms_quizzes.subject_id` | Subject-scoped reporting |
| Topics | `slb_topics` | `id` → `lms_quizzes.scope_topic_id` | Topic-level performance (Report 6) |
| Users | `sys_users` | `id` → `lms_quizzes.created_by` | Teacher identity (Report 2) |
| Academic Sessions | `glb_academic_sessions` | `id` → `lms_quizzes.academic_session_id` | Session-based filtering |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Reports Page | Teacher | `quiz.reports.view` |
| View Report 1 (Class Performance) | Teacher | `quiz.reports.class-performance` |
| View Report 2 (Teacher Monthly) | Teacher | `quiz.reports.teacher-monthly` |
| View Report 3 (Student Summary) | Teacher | `quiz.reports.student-summary` |
| View Report 4 (Student Detailed) | Teacher | `quiz.reports.student-detailed` |
| View Report 5 (Periodic Detail) | Teacher | `quiz.reports.periodic-detail` |
| View Report 6 (Class Performance by Topic) | Teacher | `quiz.reports.class-topic-performance` |
| Export CSV (Reports 1, 5) | Teacher | `quiz.reports.export-csv` |
| View All Reports – All Data | Admin | `quiz.reports.view.all` |

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
