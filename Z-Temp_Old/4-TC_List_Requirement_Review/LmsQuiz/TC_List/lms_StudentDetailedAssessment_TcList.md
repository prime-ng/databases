# lms_quiz_student_detailed_assessment_TcList

## Module: LmsQuiz → Quiz Management → Student Detailed Assessment

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management → Quiz Summary → Attempt Detail |
| Feature | Student Detailed Assessment (per-attempt question-by-question view) |
| URL(s) | `/lms-quize/quize/attempt/{attempt_id}/detail` |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizController@attemptDetail()` |
| Model(s) | `QuizQuestAttempt`, `QuizQuestResult`, `QuizQuestion`, `Quiz`, `QuestionBank` |
| Validation | Route parameter: attempt_id (auto findOrFail) |
| Permissions | `tenant.quiz.view` |
| Soft Deletes | Ghost rescue: `QuizQuestion::active()` filters by `is_active`; QuestionBank loaded with `->active()` scope |
| Activity Log | Not supported |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz.view`
- A specific quiz attempt must exist with the given attempt_id
- Attempt must be in SUBMITTED, TIMEOUT, EVALUATED, or RESULT_PUBLISHED status (though any status can load)
- Quiz model must exist (fallback uses `Quiz::find($attempt->quiz_id)`)

---

## 3. Default Data Load

| Data | Source | Query |
|------|--------|-------|
| Attempt Header | `QuizQuestAttempt::with('student','result','answers','quiz.subject')` | `->findOrFail($attemptId)` |
| Questions | `QuizQuestion::where('quiz_id',$quizId)->active()->with('question.options')` | `->orderBy('ordinal')` |
| Result | `$attempt->result` (loaded via with) | marks_obtained, total_marks, percentage, is_pass, passing_marks |
| Answers Map | `$attempt->answers->keyBy('question_id')` | Maps question_id → selected_option_id |
| Student Info | `$attempt->student` | Name, etc. |
| Quiz Info | `$attempt->quiz` (or fallback `Quiz::find($attempt->quiz_id)`) | Title, subject, passing_percentage, show_correct_answer, show_explanation |

---

## 4. Test Data Strategy

- **Full Correct**: Student answered all questions correctly
- **Partial Correct**: Mix of correct/wrong/unanswered
- **Timed Out vs Submitted**: Verify duration display different
- **Ghost Question**: Question soft-deleted after attempt (QuizQuestion with is_active=0 filtered out)
- **MCQ Display**: Options listed with selected/correct indicators

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from:
- `lms_quiz_quest_attempts` — attempt header (student_id, quiz_id, status, percentage, time_taken_seconds, submitted_at, attempt_number)
- `lms_quiz_quest_results` — result record (total_marks_obtained, max_marks, percentage, is_passed)
- `lms_quiz_quest_attempt_answers` — per-question answers (question_id, selected_option_id, is_correct)
- `lms_quiz_questions` — junction (quiz_id, question_id, ordinal, marks_override, is_active)
- `question_bank` — question content (question_content, ques_title, marks)
- `question_bank_options` — MCQ options (option_text, is_correct, is_active)

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | attempt_id | route parameter, required, integer | Uses `findOrFail` |
| BC-VAL-02 | quiz existence | Fallback check | If quiz not found via relationship, 404 returned |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz.view | 403 Forbidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Attempt header info | Student name, quiz title, subject, submitted_at |
| BC-BIZ-02 | Result card | marks_obtained, total_marks, percentage, is_pass, passing_marks, correct/wrong/unattempted counts |
| BC-BIZ-03 | Time display | Formatted as "X min Y sec" or "X sec" |
| BC-BIZ-04 | Question list — question text | Shows `question_content` or fallback `ques_title` |
| BC-BIZ-05 | Question list — marks | Shows `marks_override` from QuizQuestion or question->marks |
| BC-BIZ-06 | Question options — MCQ | Options listed; selected highlighted; correct marked |
| BC-BIZ-07 | Correct/Incorrect indicators | Green for correct, red for wrong (based on `is_correct` in answers) |
| BC-BIZ-08 | Unanswered questions | Gray/no selection indicator |
| BC-BIZ-09 | Question ordering | Ordered by `ordinal` column |
| BC-BIZ-10 | Show correct answer flag | Always true for admin report view |
| BC-BIZ-11 | Show explanation flag | Always true for admin report view |
| BC-BIZ-12 | Attempt number display | Shows which attempt number (1, 2, 3...) |
| BC-BIZ-13 | Color palette | Subject color computed via `$palette[$subject_id % count($palette)]` |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | Notes |
|-------|-----------|------------------|-------|
| BC-REF-01 | attempt.quiz_id | lms_quizzes.id | Fallback if relationship null |
| BC-REF-02 | quiz_question.quiz_id | lms_quizzes.id | |
| BC-REF-03 | quiz_question.question_id | question_bank.id | |
| BC-REF-04 | answer.question_id | question_bank.id | |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Detailed Assessment — Full Correct | Header + result card + all questions green; score = 100% | — | — | ⬜ |
| TC-P02 | View Detailed Assessment — Mix Correct/Wrong | Green/red indicators correct; counts match | — | — | ⬜ |
| TC-P03 | View Detailed Assessment — Some Unanswered | Unanswered shown with no selection; counts reflect unattempted | — | — | ⬜ |
| TC-P04 | MCQ Question Display | Options listed; student's selected answer highlighted; correct answer marked | — | — | ⬜ |
| TC-P05 | Result Card — Correct Count | Count = answers where is_correct=true | — | — | ⬜ |
| TC-P06 | Result Card — Wrong Count | Count = answers where is_correct=false AND selected_option_id IS NOT NULL | — | — | ⬜ |
| TC-P07 | Result Card — Unattempted Count | Count = answers where selected_option_id IS NULL | — | — | ⬜ |
| TC-P08 | Result Card — Percentage | (total_marks_obtained / max_marks) * 100 | — | — | ⬜ |
| TC-P09 | Result Card — Pass/Fail | Based on passing_percentage threshold from quiz | — | — | ⬜ |
| TC-P10 | Time Display — Submitted | Shows duration from time_taken_seconds formatted as "X min Y sec" | — | — | ⬜ |
| TC-P11 | Time Display — Timeout | Same format; duration = max allowed time | — | — | ⬜ |
| TC-P12 | Question Order | Questions displayed in ordinal sequence | — | — | ⬜ |
| TC-P13 | Attempt Number Display | Shows attempt number (e.g., "Attempt 1") | — | — | ⬜ |
| TC-P14 | Marks Override | If QuizQuestion has marks_override, that value shown instead of question->marks | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Invalid attempt_id | 404 Not Found (findOrFail) | — | — | ⬜ |
| TC-N02 | Quiz Not Found (deleted, no fallback) | 404 "Quiz not found for this attempt." | — | — | ⬜ |
| TC-N03 | View Without Permission | 403 Forbidden | — | — | ⬜ |
| TC-N04 | Deleted Question (QuizQuestion is_active=0) | Question not shown in list (filtered by active() scope) | — | — | ⬜ |
| TC-N05 | No Result Record | Result card shows null data or fallback values | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Marks Override | P1 | QuizQuestion has marks_override=5, question.marks=10 | Displayed marks = 5 (override used) | — | — | ⬜ |
| TC-D02 | B | Explanation Display | P1 | Question has teacher_explanation | Explanation visible below question | — | — | ⬜ |
| TC-D03 | C | Duration Format | P1 | time_taken_seconds = 125 | Shows "2 min 5 sec" | — | — | ⬜ |
| TC-D04 | D | Duration Format | P1 | time_taken_seconds = 45 | Shows "45 sec" | — | — | ⬜ |
| TC-D05 | E | Subject Color | P1 | subject_id=3 → color from palette[3%8] | Color applied to subject badge | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — attemptDetail — quiz fallback | If `$attempt->quiz` is null, uses `Quiz::find($attempt->quiz_id)` as fallback | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — attemptDetail — question loading | Uses `QuizQuestion::where('quiz_id',$id)->active()->with('question.options')->orderBy('ordinal')` | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — attemptDetail — answers map | Uses `$attempt->answers->keyBy('question_id')->map(fn($r)=>$r->selected_option_id)` | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — attemptDetail — question text fallback | Uses `$q->question_content ?: $q->ques_title` | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — attemptDetail — correct/wrong/unattempted | Counts: `where('is_correct',true)->count()`, `where('is_correct',false)->whereNotNull('selected_option_id')->count()`, `whereNull('selected_option_id')->count()` | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — formatSeconds helper | Uses `intdiv($seconds, 60)` for minutes; conditional format | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Page Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to attempt detail URL with valid attempt_id | Page loads |
| 2 | Check score summary card | marks_obtained, total_marks, percentage, duration, attempts, correct/wrong/unattempted counts |
| 3 | Check questions list | Each question: question text, options (A/B/C/D), selected option highlighted, correct option marked, explanation if present |
| 4 | Check subject badge | Subject name with color applied |

#### TC-P02: View Detailed Assessment — Mix Correct/Wrong

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User selected correct option | Option highlighted green with checkmark |

---

#### TC-P03: View Detailed Assessment — Some Unanswered

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User selected wrong option | Selected option highlighted red; correct option highlighted green |

---

#### TC-P04: MCQ Question Display

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User did not select any option | All options shown in gray; marked as "Unattempted" |

---

#### TC-P05: Result Card — Correct Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify question count | Total questions matches QuizQuestion count for quiz_id |

---

#### TC-P06: Result Card — Wrong Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify question order | Questions ordered by `ordinal` column ascending |

---

#### TC-P07: Result Card — Unattempted Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check is_correct criteria | is_correct=0 vs 1; selected_option_id matches question.correct_option_id |

---

#### TC-P08: Result Card — Percentage

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify percentage from result | (marks_obtained / total_marks) × 100 equals displayed % |

---

#### TC-P09: Result Card — Pass/Fail

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify correct/wrong/unattempted counts | Match DB aggregation on result records |

---

#### TC-P10: Time Display — Submitted

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify correct/wrong/unattempted counts | Match DB aggregation on result records |

---

#### TC-P11: Time Display — Timeout

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify correct/wrong/unattempted counts | Match DB aggregation on result records |

---

#### TC-P12: Question Order

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify correct/wrong/unattempted counts | Match DB aggregation on result records |

---

#### TC-P13: Attempt Number Display

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify correct/wrong/unattempted counts | Match DB aggregation on result records |

---

#### TC-P14: Marks Override

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check marks_override | If QuizQuestion.marks_override set, that value displayed instead of question->marks |

### 7.2 Negative TC Steps

#### TC-N01: Invalid attempt_id

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Access with invalid attempt_id | 404 Not Found |

---

#### TC-N02: Quiz Not Found

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt's quiz is deleted and fallback Quiz::find() fails | 404 "Quiz not found for this attempt." |

---

#### TC-N03: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User without `tenant.quiz.view` permission | 403 Forbidden |

---

#### TC-N04: Deleted Question

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Quiz question with is_active=0 | Question not shown (filtered by active() scope) |

---

#### TC-N05: No Result Record

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt has no result records | Result card shows null values or fallback |

### 7.3 Dependency TC Steps

#### TC-D01: Marks Override

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | QuizQuestion marks_override=5, question.marks=10 | Displayed marks = 5 (override takes precedence) |

---

#### TC-D02: Explanation Display

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Question has teacher_explanation | Explanation text visible below question |

---

#### TC-D03: Duration Format

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | time_taken_seconds = 125 | Shows "2 min 5 sec" |

---

#### TC-D04: Duration Format

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | time_taken_seconds = 45 | Shows "45 sec" |

---

#### TC-D05: Subject Color

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | subject_id=3 → palette[3%8] | Color applied to subject badge |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | Deactivated questions (is_active=0) silently excluded | User sees fewer questions than expected; no "Question Deleted" placeholder | Observed |
| KI-02 | Subject color palette limited to 8 colors | subject_id > 7 wraps around; may have color collisions | Observed |
| KI-03 | No ghost rescue for deleted Quiz model | If both relationship and fallback Quiz::find() fail, returns 404 | Observed |
| KI-04 | Result card percentages may differ from attempt.percentage | Result record percentage used, not attempt-level percentage | Observed |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quize/attempt/{attempt_id}/detail` | `lms-quize.quize.attemptDetail` | `LmsQuizController@attemptDetail` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 30 | 14 | 5 | 5 | 6 | 0 | 0 | 0 | 0 |
