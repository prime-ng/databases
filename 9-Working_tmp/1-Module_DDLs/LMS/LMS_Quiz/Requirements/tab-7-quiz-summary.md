# Quiz Tab 7: Quiz Summary

This tab shows how students performed on each quiz. Teachers come here to see scores, pass and fail counts, and detailed per-student results. They can also grade descriptive answers — Short Answer and Long Answer questions that were not scored automatically.

---

## How It Works

When the teacher opens this tab, they first see a list of allocations. Each row shows a quiz, the target class or section, how many students were allocated, how many started, how many completed, how many passed, how many failed, and the average score.

Clicking on a specific quiz opens a detailed report. At the top, summary cards show the total students, average score, highest score, lowest score, pass rate, and fail rate. Below that is a list of every student — their rank, name, score, percentage, pass or fail status, time taken, and which attempt number it is.

The teacher can filter the list — show only students who passed, only those who failed, only those in a specific score range. They can sort by score, name, or rank. They can search for a specific student by name.

Clicking on a student's name opens their attempt details. This shows every question the student faced, their answer, the correct answer, whether they got it right or wrong, and how many marks they earned. For MCQ questions, the scoring is already done. For Short Answer and Long Answer questions, the teacher sees the student's typed response and a field to enter marks.

---

## Grading Descriptive Answers

When a quiz includes Short Answer or Long Answer questions, those are not scored automatically. The system marks them as "Pending Evaluation." The teacher opens each student's attempt, reads their written response, and assigns a score.

The score must be between 0 and the question's maximum marks. The teacher can give partial credit — for example, 3 out of 5 if the answer is partially correct. Once the teacher saves the grade, the student's total score is recalculated. If the new score changes the student from fail to pass, the system updates the pass/fail status. It also recalculates the student's rank and percentile.

The teacher can change a grade later if they change their mind. The system recalculates each time.

---

## Rank and Percentile

Students are ranked by their score, highest first. If two students have the same score, they get the same rank. For example, if two students tie for first place, both get Rank 1, and the next student gets Rank 3. This is called "dense ranking" and is standard for educational assessments.

Percentile tells each student what percentage of their classmates they scored better than. If a student is in the 80th percentile, they scored higher than 80% of their peers.

Ranks and percentiles are recalculated whenever a teacher changes a grade. So if a descriptive answer is re-scored, all students' ranks may shift.

---

## Important Business Rules

- The teacher can export the student list as a CSV file for import into a grade book or spreadsheet. They can also print the summary.
- Students who have not started the quiz are listed as "Not Attempted." They do not get a score or rank.
- If no student has taken the quiz yet, the summary shows "No attempts yet" with empty cards.
- Grading a descriptive answer automatically recalculates the student's total score, percentage, pass/fail status, rank, and percentile. This may affect other students' ranks.
- The teacher can change a descriptive answer grade at any time. Each change is logged with the previous and new score.
- Dense ranking means if two students tie for first, both are Rank 1. The next student is Rank 3, not Rank 2. This is the standard educational ranking system.
- Percentile is calculated as (number of students scored below / total number of students who attempted) * 100. A student who scored the lowest gets percentile 0. A student who scored the highest gets percentile 100.
- The summary only includes students who were allocated to the quiz and have attempted it. Allocated students who never started are marked as "Not Attempted" and are grouped at the bottom of the list.

---

## Deep Analysis

### Business Workflows & State Machines

**Summary View Workflow:**
1. Teacher selects a quiz from the allocation list.
2. System loads all student attempts for that quiz.
3. Summary cards computed: total students, avg/highest/lowest score, pass/fail rate.
4. Student list computed with rank, percentage, and percentile.
5. Teacher can filter (pass/fail/score range), sort, or search.
6. Teacher clicks a student → detailed attempt view with per-question results.
7. For descriptive questions, teacher enters a score (0 to max marks).
8. System recalculates: student total → percentage → pass/fail → rank → percentile (all students).
9. Grade change logged with old/new values.

**Grading State Machine:**

| Current State | Transition | Trigger | Next State | Conditions |
|---|---|---|---|---|
| Auto-Scored | — | System scores MCQ/TF/FIB | Graded | No teacher action needed |
| Pending Evaluation | Grade | Teacher enters score | Graded | Score between 0 and max marks |
| Graded | Re-grade | Teacher changes score | Graded | Always allowed; recalculates rank/percentile |
| Graded | — | — | Graded | Logged with previous and new score |

**Ranking Algorithm (Dense Ranking):**
1. Sort all students by score descending.
2. Assign rank = position in sorted order, but ties share the same rank.
3. Next distinct score after a tie gets rank = current_position + 1 (skipping the tied positions).
4. Example: Scores [95, 90, 90, 85] → Ranks [1, 2, 2, 4].

**Percentile Algorithm:**
- `percentile = (count_of_students_scored_below / total_attempted_students) * 100`
- Lowest scorer → percentile 0.
- Highest scorer → percentile 100.
- Ties: students with same score, count_below includes none of them.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Grade Descriptive – Score Range | Must be 0 to max marks | "Score must be between 0 and [max_marks]." |
| Grade Descriptive – Zero Marks | Allowed | No error; student gets 0 for that question |
| Grade Descriptive – Full Marks | Allowed | No error |
| Re-grade – Any Time | Always allowed | No error; change is logged |
| Student Not Attempted | No score, rank, or percentile | Listed as "Not Attempted" at bottom |
| No Attempts Yet | Empty cards | "No attempts yet" |
| Export CSV – No Data | Empty export | "No data to export." |
| Export CSV – With Data | CSV with generation timestamp and filter criteria | No error |
| Dense Ranking – Tie at Top | Both get Rank 1, next gets Rank 3 | No error — intentional |
| Dense Ranking – All Same Score | All get Rank 1 | No error |
| Percentile – Single Student | Percentile = 0 (scored same as themselves) | No error — formulated as rank-0 logic |
| Percentile – Only One Attempted | 0 for that student (no one below) | Handled correctly |
| Reports – < 5 Students | Percentile and rank suppressed | "Rank and percentile not shown for fewer than 5 students." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | `id` | Identify quiz, get passing_percentage, total_marks |
| Quiz Allocations | `lms_quiz_allocations` | `quiz_id` → `lms_quizzes.id` | List allocations for summary selection |
| Quiz Questions | `lms_quiz_questions` | `quiz_id` → `lms_quizzes.id` | Display per-question results in attempt detail |
| Question Bank | `qns_questions_bank` | `id` → `lms_quiz_questions.question_id` | Get question text, type, correct answer, max marks |
| Student Attempts | `lms_quiz_attempts` (or similar) | `quiz_id`, `student_id` | Store attempt-level data |
| Student Answers | `lms_quiz_answers` (or similar) | `attempt_id`, `question_id` | Store per-question student responses and scores |
| Students | `std_students` | `student_id` → `std_students.id` | Student name, details |
| Activity Log | (separate log table) | — | Log grade changes (previous score, new score) |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Summary | Teacher | `quiz.summary.view` |
| View Attempt Detail | Teacher | `quiz.summary.attempt-detail` |
| Grade Descriptive Answer | Teacher | `quiz.summary.grade-descriptive` |
| Re-grade Descriptive Answer | Teacher | `quiz.summary.regrade` |
| Export CSV | Teacher | `quiz.summary.export-csv` |
| View All Summaries | Admin | `quiz.summary.view.all` |

---

## Database Columns & Behavior

### Table: `lms_quizzes` (relevant columns only)

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `total_marks` | DECIMAL(8,2) | No | No | 0.00 | Used as denominator for percentage calculation |
| `total_questions` | INT UNSIGNED | No | No | 0 | Display purposes |
| `passing_percentage` | DECIMAL(5,2) | No | No | 33.00 | Threshold for pass/fail determination |
| `status` | VARCHAR(20) | No | No | 'DRAFT' | Must be PUBLISHED or beyond for results |

### Table: `lms_quiz_allocations`

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `quiz_id` | INT UNSIGNED | Yes → `lms_quizzes.id` | No | — | FK to the quiz |
| `allocation_type` | ENUM('CLASS','SECTION','GROUP','STUDENT') | No | No | — | Type of target entity |
| `target_table_name` | VARCHAR(60) | No | No | — | Name of target table |
| `target_id` | INT UNSIGNED | No | No | — | ID of target entity |
| `published_at` | DATETIME | No | Yes | NULL | Visible from date/time |
| `due_date` | DATETIME | No | Yes | NULL | Due by date/time |
| `cut_off_date` | DATETIME | No | Yes | NULL | No submissions after this |
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
