# Question Statistics — Business Requirements

## What This Screen Does

The Question Statistics screen shows performance metrics for each question based on how students have answered it in assessments. Think of it as a report card for each question — it tells the teacher whether a question is too easy, too hard, or possibly mis-keyed (has the wrong answer marked as correct).

The screen displays these computed metrics:
- **Difficulty Index** — What percentage of students answered correctly (0-100). Low = hard question, High = easy question.
- **Discrimination Index** — How well the question separates top performers from bottom performers (-100 to +100). Negative values mean the question may be flawed.
- **Guessing Factor** — For MCQ questions only: the estimated percentage of correct answers due to random guessing.
- **Time Metrics** — Shortest, longest, and average time students took to answer.
- **Total Attempts** — How many students have answered this question.

These metrics are computed by a backend service that aggregates data from quiz, quest, and exam answer tables.

---

## When This Screen Is Used

- **Reviewing Question Quality** — To identify questions that are too easy, too hard, or mis-keyed
- **Identifying Flawed Questions** — A negative discrimination index flags a question that may need review
- **Preparing for Assessments** — To select questions with appropriate difficulty levels
- **Curriculum Improvement** — To understand which topics students struggle with

---

## Who Can Access This Screen

- **School Admin** — Can view and manage statistics
- **Head of Department** — Can view statistics for their department
- **Teacher** — Can view statistics for their questions
- **Academic Coordinator** — Full access

All access is controlled by permissions under the `tenant.question_bank.*` namespace (`viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `status`).

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Statistics List

The dedicated index route is disabled (returns 404). Listing statistics is available only through the QuestionBank tab module. Each record shows: the question title (linked to the question view), difficulty index, discrimination index, guessing factor, total attempts, and last computed date.

### Viewing Statistics Details

Clicking a record opens a detail view showing all metrics for that question with their computed values.

### Manual Computation

A `recalculate()` method exists in the controller but has no route registered in `web.php`. Its computation logic is commented out — only `last_computed_at` is updated. The action is currently non-functional.

### Bulk Sync

The "Sync" action triggers statistics computation for all questions at once. This is typically used after a batch of new answers has been collected.

### Automatic Computation

The statistics are designed to be computed by a scheduled background job (nightly), but no cron/scheduler entry exists. **Not implemented.**

### Computation Logic (Non-Technical)

When computing statistics for a question, the service:
1. Gathers all student answers from quiz, quest, and exam tables
2. Calculates Difficulty Index: (correct answers ÷ total attempts) × 100
3. Calculates Discrimination Index: Takes the top 27% of students by overall score and the bottom 27%, compares their correct-answer rates
4. Calculates Guessing Factor (MCQ only): If 30+ attempts exist, uses the bottom group's correct rate; otherwise, estimates based on number of options
5. Calculates time metrics (min, max, avg time taken in seconds)
6. Saves all metrics to the qns_question_statistics table

If there are fewer than 4 attempts per group, discrimination index and guessing factor are set to null (insufficient data).

---

## Validate Before Save

| Field | Rule |
|-------|------|
| question_bank_id | Required, must exist in questions bank, must be unique (one stats record per question) |
| difficulty_index | Optional, number, between 0 and 100 |
| discrimination_index | Optional, number, between -1 and 1 |
| guessing_factor | Optional, number, between 0 and 1 |
| min_time_taken_seconds | Optional, whole number, minimum 0 |
| max_time_taken_seconds | Optional, whole number, minimum 0 |
| avg_time_taken_seconds | Optional, whole number, minimum 0 |
| total_attempts | Optional, whole number, minimum 0 |
| is_active | Optional, yes/no |

---

## Business Rules and Conditions

### Rule 1: One Stats Record Per Question
Each question can have only one statistics record. The `question_bank_id` is unique in the `qns_question_statistics` table.

### Rule 2: Compute on Demand via Service
Statistics are computed by `QuestionStatisticsService::computeAndPersist()` which reads answer data from quiz, quest, and exam modules.

### Rule 3: Minimum Data Threshold
If fewer than 4 student attempts exist per group (top 27% / bottom 27%), the discrimination index and guessing factor are set to null (insufficient data).

### Rule 4: MCQ-Specific Guessing
The guessing factor is computed only for MCQ questions. For other question types, it is null.

### Rule 5: Performance Category Recommendations
Based on the computed difficulty index, discrimination index, and total attempts, the service automatically updates performance category recommendations (e.g., assigning REVISION, PRACTICE, or CHALLENGE recommendation types).

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| One Per Question | Each question has exactly one statistics record |
| Auto-Computed | Metrics are calculated from student answer data |
| Minimum Data | Fewer than 4 attempts per group → null values |
| MCQ Guessing | Guessing factor only applies to MCQ questions |
| Performance Sync | Stats update performance category recommendations |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Invalid question ID | "The selected question bank id is invalid." |
| Duplicate stats record | "The question bank id has already been taken." |
| Difficulty index out of range | "difficulty index must be between 0 and 100." |
| Invalid discrimination index | "discrimination index must be between -1 and 1." |

---

## Success Scenarios

- A teacher opens a question's statistics and sees: Difficulty Index = 62 (moderate), Discrimination Index = 0.45 (good), Guessing Factor = 0.25 (low guessing), Total Attempts = 120, Average Time = 45 seconds. The teacher knows the question is performing well.

---

## Failure Scenarios

- A teacher views statistics for a newly created question with only 2 student attempts. The system shows Difficulty Index = 50.0 but Discrimination Index = "Insufficient data (minimum 4 per group)."

---

## Example Scenario

The school admin notices that several students failed a particular question in the last quiz. They open the Question Statistics tab, find the question, and see:
- Difficulty Index = 12 (very hard)
- Discrimination Index = -0.30 (negative — something is wrong)
- Total Attempts = 85

The negative discrimination index suggests the question may be mis-keyed. The admin reviews the question and finds that the correct answer is actually marked on the wrong option. They fix the question, and after the next assessment, the Discrimination Index improves to 0.55.

---

## Related Screens

- **Question Bank** — Where the question's statistics can be viewed from the detail page
- **Question Review** — Where questions can be flagged for review based on statistics

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank Core | `qns_question_statistics` (primary table), `qns_questions_bank` (FK) |
| LmsQuiz | `quz_quiz_attempt_answers` (answer data source) |
| LmsQuests | `lms_quest_questions`, `sp_quiz_quest_attempts` (answer data source) |
| LmsExam | `exm_exam_attempt_answers` (answer data source) |
| Syllabus | `slb_performance_categories` (recommendation updates) |
