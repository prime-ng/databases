# lms_quiz_student_performance_summary_TcList

## Module: LmsQuiz → Quiz Management → Reports → Student Performance Summary

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management → Reports (quiz-reports) |
| Feature | Student Performance Summary (tab: student-summary) |
| URL(s) | `/lms-quize/quiz-reports` (active_tab=student-summary, AJAX loads partial) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` → `generateStudentSummaryData()` |
| Model(s) | `QuizQuestAttempt`, `QuizAllocation`, `QuestAllocation`, `Quiz`, `Quest`, `Subject`, `QuizQuestion`, `QuestQuestion` |
| Validation | Filter parameters only |
| Permissions | `tenant.quiz-dashboard.view` (shared with entire report page) |
| Soft Deletes | Ghost rescue: deleted quizzes/quests handled via model fallback null checks; Subject fetched from DB |
| Default Date Range | Current month (startOfMonth → endOfMonth) |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-dashboard.view`
- Student selected (defaults to first student with attempts in range, or first enrolled student)
- Student must have at least one quiz attempt in date range
- Class-section context auto-derived from student's current academic session

---

## 3. Default Data Load

| Data | Source | Query | Filters |
|------|--------|-------|---------|
| Day Matrix | Days array from date_from → date_to | Each day: date, label, day_name | date_from, date_to |
| Attempts | `QuizQuestAttempt::with('answers','quiz','quest','quiz.subject','quest.subject','quiz.topic','quest.scopes.topic')` | `->where('student_id',$id)->whereIn('status',['SUBMITTED','TIMEOUT'])` | student_id, assessment_type, subject_id, subject_group_id, date_from, date_to |
| Allocations | `QuizAllocation::with('quiz')` + `QuestAllocation::with('quest')` | Scope by student's class/section/student allocation types | student_id, subject_id |
| Subject Data | Per-subject matrix row | assigned[], attempted[], total_ques[], correct[], wrong[], not_attempted[], score[] (0-1 decimal) | subject_id |
| Ghost Rescue | Attempts with no subject or deleted quiz/quest | Grouped into "Ghost / Deleted Content" subject | None |
| Daily Averages | Computed from all subject score arrays | Per-day average score across all subjects | None |

---

## 4. Test Data Strategy

- **Single Student**: Create student with attempts across multiple subjects in date range
- **Multiple Subjects**: Verify subject-wise matrix display
- **Daily Breakdown**: Verify correct per-day assignment/attempt data
- **Ghost Rescue**: Delete a quiz after student attempt → verify ghost subject row appears
- **Empty State**: Student with no attempts in date range

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from: `lms_quiz_quest_attempts`, `lms_quiz_quest_results`, `lms_quizzes`, `lms_quests`, `lms_quiz_allocations`, `lms_quest_allocations`, `sch_subjects`, `sch_classes`, `std_student_academic_sessions`

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | student_id | nullable, integer | Auto-selects first student with attempts |
| BC-VAL-02 | assessment_type | nullable, string, in:Both,QUIZ,QUEST | Defaults to Both |
| BC-VAL-03 | subject_id | nullable, integer | |
| BC-VAL-04 | subject_group_id | nullable, integer | |
| BC-VAL-05 | date_from | nullable, date | Defaults to current month start |
| BC-VAL-06 | date_to | nullable, date | Defaults to current month end |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz-dashboard.view | 403 Forbidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Subject matrix — per subject row | Shows subject name with daily assigned/attempted/total_ques/correct/wrong/not_attempted/score |
| BC-BIZ-02 | Assigned flag | 1 if allocation covers that day (published_at <= day <= due_date), else 0 |
| BC-BIZ-03 | Attempted flag | 1 if student attempted on that day, else 0 |
| BC-BIZ-04 | Daily score | 0-1 decimal score for the day's attempts |
| BC-BIZ-05 | Type categories | QUIZ → "Quiz - Homework"; QUEST → "Assessment" |
| BC-BIZ-06 | Both types | Shows both QUIZ and QUEST as separate type groups with their own subjects |
| BC-BIZ-07 | Ghost rescue — deleted content | Shows "Ghost / Deleted Content" subject row for orphaned attempts |
| BC-BIZ-08 | Subject ordering | Sorted by total questions descending, then alphabetically |
| BC-BIZ-09 | Daily average line | Per-day average across all subjects computed from score arrays |
| BC-BIZ-10 | No student selected | Auto-selects first student with attempts in range, or first enrolled |
| BC-BIZ-11 | Subject group filtering | Only subjects in selected group shown |
| BC-BIZ-12 | Score fallback | If percentage=0 but correct>0, recalculates as (correct/total)*100 |

### 5.5 Referential Integrity

Same as parent attempt and allocation tables. Ghost rescue handles missing FK references.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Student Performance Summary | Subject matrix with daily assigned/attempted/score data | — | — | ⬜ |
| TC-P02 | Subject Row — Assigned Days | 1 for days with allocation covering that date, else 0 | — | — | ⬜ |
| TC-P03 | Subject Row — Attempted Days | 1 for days with attempt submitted, else 0 | — | — | ⬜ |
| TC-P04 | Subject Row — Daily Totals | total_ques, correct, wrong, not_attempted for each day | — | — | ⬜ |
| TC-P05 | Subject Row — Daily Score | 0-1 score decimal for each day's attempts | — | — | ⬜ |
| TC-P06 | Multiple Subjects | Each subject shown as separate row in matrix | — | — | ⬜ |
| TC-P07 | Type Categories — QUIZ | Shows "Quiz - Homework" with subject rows | — | — | ⬜ |
| TC-P08 | Type Categories — QUEST | Shows "Assessment" with subject rows | — | — | ⬜ |
| TC-P09 | Type Categories — Both | Both sections shown in order: QUIZ first, then QUEST | — | — | ⬜ |
| TC-P10 | Daily Average Row | Per-day average score across all subjects shown | — | — | ⬜ |
| TC-P11 | Filter by Assessment Type | Only QUIZ or QUEST data shown | — | — | ⬜ |
| TC-P12 | Filter by Subject | Only data for selected subject shown | — | — | ⬜ |
| TC-P13 | Filter by Date Range | Only days within range shown in matrix | — | — | ⬜ |
| TC-P14 | Filter by Subject Group | Only subjects in selected group shown | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Student Selected | Auto-selects first student with attempts in range | — | — | ⬜ |
| TC-N02 | Student With No Attempts | Returns empty days/type_groups; no data shown | — | — | ⬜ |
| TC-N03 | Ghost — Deleted Quiz | Attempt appears under "Ghost / Deleted Content" row | — | — | ⬜ |
| TC-N04 | Subject Not in active() scope | Attempts with deleted subject go to ghost row | — | — | ⬜ |
| TC-N05 | View Without Permission | 403 Forbidden | — | — | ⬜ |
| TC-N06 | Invalid Student ID | Falls back to auto-selected student | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Daily Assignment Check | P1 | Allocation published_at=Jan 1, due_date=Jan 5 → Jan 1-5 assigned=1, Jan 6 assigned=0 | Correct assigned flags per day | — | — | ⬜ |
| TC-D02 | B | Attempt Counts Accuracy | P1 | Student has 3 attempts on Jan 3 (2 correct, 1 wrong, 5 total ques) | total_ques=5, correct=2, wrong=1, not_attempted=3 | — | — | ⬜ |
| TC-D03 | C | Ghost — Deleted Content | P1 | Soft-delete quiz → attempt still in DB but quiz.subject_id null | Row shown as "Ghost / Deleted Content" | — | — | ⬜ |
| TC-D04 | D | Score Decimal Range | P1 | 80% → score=0.80; 45% → score=0.45 | Scores always in 0.00-1.00 range | — | — | ⬜ |
| TC-D05 | E | Subject Sorting | P1 | Math has 10 total questions, Science has 5, Art has 8 | Order: Math, Art, Science (by total ques DESC) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — generateStudentSummaryData — student auto-select | First tries student with attempts in range, then first enrolled via StudentAcademicSession | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateStudentSummaryData — allocation scoping | QuizAllocation scoped by allocation_type (CLASS/SECTION/STUDENT) matching student's class/section/id | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — generateStudentSummaryData — daily matrix computation | For each day: checks allocation date range → assigned flag; checks attempts by date → attempted flag, counts, score | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — generateStudentSummaryData — ghost rescue | Filters attempts where subject_id is null or subject not in active list; groups into "Ghost / Deleted Content" | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — generateStudentSummaryData — subject sorting | Uses `usort` with comparison on total_questions DESC, then name ASC | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — generateStudentSummaryData — batch question counts | Pre-fetches question counts via `groupBy('quiz_id')->pluck('count','quiz_id')` to avoid N+1 | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — generateStudentSummaryData — daily average | Average computed across all subjects' score arrays per day index | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Matrix Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz Reports → Student Summary tab | Page loads with student-summary tab active |
| 2 | Check filter bar | Class Section, Subject, Subject Group, Student dropdown, Date Range visible |
| 3 | Check matrix header | Columns = subject names sorted by total_questions DESC then name ASC; Last column = Daily Average |
| 4 | Check matrix rows | Rows = dates within range; each cell = score (0.00-1.00) or null |
| 5 | Check ghost row | "Ghost / Deleted Content" row at bottom if any deleted content exists |

#### TC-P02: Subject Row — Assigned Days

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section | Student dropdown populates |

---

#### TC-P03: Subject Row — Attempted Days

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select student with known attempts | Matrix shows that student's daily data |

---

#### TC-P04: Subject Row — Daily Totals

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with attempt submitted | Cell shows score as 0.00-1.00 decimal |

---

#### TC-P05: Subject Row — Daily Score

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with allocation but no attempt | Cell shows null (no score) |

---

#### TC-P06: Multiple Subjects

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with no allocation | Cell shows null |

---

#### TC-P07: Type Categories — QUIZ

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify total_questions per subject | Column total_questions matches DB count |

---

#### TC-P08: Type Categories — QUEST

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify correct count per subject | Matches DB WHERE is_correct=true for that subject/day |

---

#### TC-P09: Type Categories — Both

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify wrong count per subject | Matches DB WHERE is_correct=false AND selected_option_id NOT NULL |

---

#### TC-P10: Daily Average Row

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify not_attempted count per subject | Matches DB WHERE selected_option_id IS NULL |

---

#### TC-P11: Filter by Assessment Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify daily average | Average of all subject scores for that day |

---

#### TC-P12: Filter by Subject

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select different student | Matrix reloads for selected student |

---

#### TC-P13: Filter by Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date range | Only days within range shown |

---

#### TC-P14: Filter by Subject Group

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select subject group | Only subjects in selected group shown |

### 7.2 Negative TC Steps

#### TC-N01: No Student Selected

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | No student explicitly selected | Auto-selects first student with attempts in range |

---

#### TC-N02: Student With No Attempts

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has zero attempts | Empty days/type_groups; no data shown |

---

#### TC-N03: Ghost — Deleted Quiz

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete quiz → student still has attempt | Row appears as "Ghost / Deleted Content" |

---

#### TC-N04: Subject Not in active() Scope

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Subject soft-deleted (not in active()) | Attempt row goes to "Ghost / Deleted Content" |

---

#### TC-N05: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User without `tenant.quiz-dashboard.view` | 403 Forbidden |

---

#### TC-N06: Invalid Student ID

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Pass invalid student_id | Falls back to auto-selected student |

### 7.3 Dependency TC Steps

#### TC-D01: Daily Assignment Check

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Allocation published_at=Jan 1, due_date=Jan 5 | Jan 1-5 assigned=1; Jan 6 assigned=0 |

---

#### TC-D02: Attempt Counts Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student 3 attempts on Jan 3: 2 correct, 1 wrong, 5 total ques | total_ques=5, correct=2, wrong=1, not_attempted=3 |

---

#### TC-D03: Ghost — Deleted Content

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete quiz → attempt remains in DB | Row shown as "Ghost / Deleted Content" |

---

#### TC-D04: Score Decimal Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | 80% → score=0.80; 45% → score=0.45 | Scores always in 0.00-1.00 range |

---

#### TC-D05: Subject Sorting

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Math 10 ques, Science 5, Art 8 | Column order: Math, Art, Science (by total ques DESC) |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | No overview card (total quizzes, avg score, best score, pass rate) | Only daily matrix shown; no summary stats | Missing feature |
| KI-02 | No per-quiz breakdown list | Matrix shows daily aggregation, not per-quiz listing | Confirmed (by design) |
| KI-03 | No subject-wise or monthly trend chart | No visual charts; only tabular matrix | Missing feature |
| KI-04 | Score displayed as 0-1 decimal (not percentage) | Confusing if expecting 0-100 range; scores like 0.80 mean 80% | Observed |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quiz-reports` (active_tab=student-summary) | `quiz-reports.index` | `LmsQuizReportController@index` |
| GET | `/lms-quize/quiz-reports/filter-dependencies` | `quiz-reports.filter-dependencies` | `LmsQuizReportController@getDependencies` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 32 | 14 | 6 | 5 | 7 | 0 | 0 | 0 | 0 |
