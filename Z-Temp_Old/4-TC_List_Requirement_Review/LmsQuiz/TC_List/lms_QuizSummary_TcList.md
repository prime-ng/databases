# lms_quiz_summary_TcList

## Module: LmsQuiz → Quiz Management → Quiz Summary

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management |
| Feature | Quiz Summary (tab: quiz_summary) |
| URL(s) | `/lms-quize/quize` (tab: quiz_summary), `/lms-quize/quize/report/{id}` (per-quiz report), `/lms-quize/quize/attempt/{attempt_id}/detail` (attempt detail) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizController@index()` (quiz_summary query), `report()` (per-quiz), `attemptDetail()` (per-attempt) |
| Model(s) | `QuizAllocation` (main), `Quiz`, `QuizQuestAttempt`, `QuizQuestResult`, `StudentAcademicSession` |
| Validation | Request filters only (search, class_section_id, subject_id, date_from, date_to) |
| Permissions | `tenant.quiz.viewAny` (shared with entire index page — no separate summary permission) |
| Soft Deletes | N/A (reads data; `report()` method doesn't use `withTrashed()`) |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz.viewAny` (shared with entire tab view)
- At least one published allocation with student attempts
- Tenant context initialized

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Quiz Summary List (Level 1) | `QuizAllocation::with('quiz.subject','quiz.class','quiz.lesson')` | `->withCount(['attempts as submitted_count' => SUBMITTED/TIMEOUT/EVALUATED/RESULT_PUBLISHED, 'attempts as in_progress_count' => IN_PROGRESS, 'attempts as total_attempt_count'])` | search (quiz title/code), class_section_id → allocation_type mapping, subject_id, date_from/date_to (published_at) | 10 per page (summary_page) |
| Total Assigned Per Allocation | Computed via `match($allocation_type)` | CLASS=StudentAcademicSession count by class, SECTION=by section, STUDENT=1, GROUP=EntityGroupMember count | None | None |
| Per-Quiz Report (Level 2) | `LmsQuizController@report($quiz_id)` | `QuizQuestAttempt::with('student','result')->where('quiz_id',$id)->get()` + StudentAcademicSession for assigned students | search, status (NOT_STARTED/IN_PROGRESS/SUBMITTED) | 25 per page |
| Attempt Detail (Level 3) | `LmsQuizController@attemptDetail($attempt_id)` | `QuizQuestAttempt::with('student','result','answers','quiz.subject')` + QuizQuestion::where('quiz_id')->with('question.options') | By attempt_id | None (single record) |

---

## 4. Test Data Strategy

- **3-Level Drill-Down**: Level 1 = Quiz Allocation Summary list → Level 2 = Per-quiz student report → Level 3 = Per-attempt question detail
- **Multiple Attempts**: Create students with 1, 2, and max attempts to verify grouping
- **Ghost Rescue**: Report method does NOT use withTrashed — deleted quizzes show 404 on report page
- **Filtering**: Test class, subject, date range, and search filters

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from:
- `lms_quiz_allocations` — allocation info, allocation_type, target_id, published_at
- `lms_quizzes` — quiz metadata (via quiz_id FK)
- `lms_quiz_quest_attempts` — per-student attempt records (withCount)
- `lms_quiz_quest_results` — scores (via report method)
- `std_student_academic_sessions` — total assigned counts
- `sch_class_sections`, `sch_classes` — class/section resolution

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | class_section_id | nullable, exists:sch_class_sections,id | Maps to allocation_type (CLASS/SECTION/STUDENT) |
| BC-VAL-02 | subject_id | nullable, exists:sch_subjects,id | Filters quizzes by subject |
| BC-VAL-03 | search | nullable, string | Search quiz title or quiz_code |
| BC-VAL-04 | date_from | nullable, date with time | Filters published_at >= date_from startOfDay |
| BC-VAL-05 | date_to | nullable, date with time | Filters published_at <= date_to endOfDay |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior Without |
|-------|-----------|-------------------|-----------------|
| BC-AUTH-01 | tenant.quiz.viewAny | index() (quiz_summary tab) | 403 for entire page |
| BC-AUTH-02 | tenant.quiz.view | report(), attemptDetail() | 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Level 1 — Quiz Summary List | Shows QuizAllocation rows with quiz title, subject, class, lesson, withCount stats |
| BC-BIZ-02 | Level 1 — Total Assigned | Computed per allocation based on allocation_type (CLASS/SECTION/STUDENT/GROUP) |
| BC-BIZ-03 | Level 2 — Report page | Shows stat cards (total students, total attempts, status counts, score bins, avg score) + per-student table |
| BC-BIZ-04 | Level 2 — Status filter | NOT_STARTED/IN_PROGRESS/SUBMITTED filter for student list |
| BC-BIZ-05 | Level 2 — Score distribution | 5 bins: 0-20%, 21-40%, 41-60%, 61-80%, 81-100% |
| BC-BIZ-06 | Level 2 — Student search | Search by first_name, last_name, admission_no |
| BC-BIZ-07 | Level 3 — Attempt Detail | Question-by-question: text, options, selected option, correct answer, marks, explanation |
| BC-BIZ-08 | Level 3 — Score summary | marks_obtained, total_marks, percentage, is_pass, passing_marks, time_taken, correct/wrong/unattempted counts |
| BC-BIZ-09 | Level 3 — Question ordering | Ordered by `ordinal` column from QuizQuestion |
| BC-BIZ-10 | Filter by class_section_id | Routes allocation query through CLASS/SECTION/STUDENT allocation_type logic |
| BC-BIZ-11 | Filter by subject_id | Only allocations for quizzes in that subject shown |
| BC-BIZ-12 | Filter by date range | Only allocations with published_at in range shown |
| BC-BIZ-13 | Search by quiz title/code | Filters allocations by related quiz title or quiz_code |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | Notes |
|-------|-----------|------------------|-------|
| BC-REF-01 | quiz_allocation.quiz_id | lms_quizzes.id | CASCADE |
| BC-REF-02 | quiz_allocation.target_id | Varies by allocation_type | CLASS→sch_classes, SECTION→sch_class_sections, STUDENT→users |
| BC-REF-03 | attempt.quiz_id | lms_quizzes.id | CASCADE |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Level 1 — View Quiz Summary List | List shows QuizAllocation rows with quiz info, withCount stats, total_assigned | — | — | ⬜ |
| TC-P02 | Level 1 — withCount Stats | submitted_count, in_progress_count, total_attempt_count shown correctly | — | — | ⬜ |
| TC-P03 | Level 1 — Total Assigned (CLASS type) | Count matches students in class via StudentAcademicSession | — | — | ⬜ |
| TC-P04 | Level 1 — Total Assigned (SECTION type) | Count matches students in that section | — | — | ⬜ |
| TC-P05 | Level 1 — Total Assigned (STUDENT type) | Shows 1 | — | — | ⬜ |
| TC-P06 | Level 1 — Filter by class_section_id | Only allocations scoped to that class/section/students shown | — | — | ⬜ |
| TC-P07 | Level 1 — Filter by subject_id | Only allocations for quizzes in selected subject | — | — | ⬜ |
| TC-P08 | Level 1 — Filter by date range | Only allocations with published_at in range | — | — | ⬜ |
| TC-P09 | Level 1 — Search by quiz title | Filters by quiz title LIKE search | — | — | ⬜ |
| TC-P10 | Level 1 — Search by quiz_code | Filters by quiz_code LIKE search | — | — | ⬜ |
| TC-P11 | Level 1 — Pagination | Page 2 shows next 10 allocations | — | — | ⬜ |
| TC-P12 | Level 2 — View Per-Quiz Report | Stat cards (total, attempts, status counts, score bins, avg) + student table | — | — | ⬜ |
| TC-P13 | Level 2 — Status Counts | NOT_STARTED/IN_PROGRESS/SUBMITTED counts calculated from latest attempt per student | — | — | ⬜ |
| TC-P14 | Level 2 — Score Distribution | 5 bins match actual attempt percentages | — | — | ⬜ |
| TC-P15 | Level 2 — Average Score | Calculated from completed attempts | — | — | ⬜ |
| TC-P16 | Level 2 — Filter by Status | Only students matching selected status shown | — | — | ⬜ |
| TC-P17 | Level 2 — Search Student | Search by name or admission_no filters table | — | — | ⬜ |
| TC-P18 | Level 2 — Pagination (25/page) | Page 2 shows next 25 students | — | — | ⬜ |
| TC-P19 | Level 3 — View Attempt Detail | Question-by-question: text, options, selected, correct, marks, explanation | — | — | ⬜ |
| TC-P20 | Level 3 — Score Summary | marks_obtained, total_marks, percentage, is_pass, time_taken, counts correct | — | — | ⬜ |
| TC-P21 | Level 3 — Question Order | Questions ordered by `ordinal` column | — | — | ⬜ |
| TC-P22 | Level 3 — Correct/Wrong/Unattempted | Green/red/gray indicators match answers | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Allocations Exist — Empty Summary | Summary shows empty table or "No data available" | — | — | ⬜ |
| TC-N02 | No Attempts for Allocation | withCount shows submitted_count=0, in_progress_count=0, total_attempt_count=0 | — | — | ⬜ |
| TC-N03 | Invalid Quiz ID in Report URL | 404 Not Found (uses findOrFail) | — | — | ⬜ |
| TC-N04 | Invalid Attempt ID in Detail URL | 404 Not Found | — | — | ⬜ |
| TC-N05 | View Without Permission (Level 1) | 403 Forbidden (tenant.quiz.viewAny) | — | — | ⬜ |
| TC-N06 | View Without Permission (Level 2/3) | 403 Forbidden (tenant.quiz.view) | — | — | ⬜ |
| TC-N07 | Deleted Quiz — Report | 404 (report uses findOrFail, no withTrashed) | — | — | ⬜ |
| TC-N08 | Student with No Quiz Model on Attempt | Fallback works or 404 if quiz_id not set | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | 3-Level Drill-Down | P1 | Level 1 → click allocation → Level 2 → click student → Level 3 | All 3 levels render correctly; navigation works | — | — | ⬜ |
| TC-D02 | B | Score Bin Accuracy | P1 | Verify 5 bins match actual attempt percentages | Each bin count matches DB query result | — | — | ⬜ |
| TC-D03 | C | Status Count — Latest Attempt | P1 | Student with 2 attempts (first IN_PROGRESS, second SUBMITTED) | Counted as SUBMITTED (latest status used) | — | — | ⬜ |
| TC-D04 | D | Total Assigned — GROUP type | P1 | Allocation to group with 15 active members | Total assigned = 15 | — | — | ⬜ |
| TC-D05 | E | Class-Section Filter — Scope Logic | P1 | SECTION allocation_type + CLASS allocation_type | Filter matches both directly and via class_id scope | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — index — QuizSummary query withCount | Uses `withCount(['attempts as submitted_count' => ..., 'attempts as in_progress_count' => ..., 'attempts as total_attempt_count'])` | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — index — total_assigned transform | Uses `match($allocation->allocation_type)` to compute per-allocation count | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — report — status filter logic | NOT_STARTED excludes student IDs with ANY attempt; IN_PROGRESS/SUBMITTED filters by latest attempt status | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — report — score distribution | PHP loop with if/elseif chain for 5 score bins | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — attemptDetail — question ordering | Uses `QuizQuestion::where('quiz_id')->active()->orderBy('ordinal')->get()` | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — report — pagination | Manual LengthAwarePaginator with 25 per page | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps — Level 1 (Quiz Cards)

#### TC-P01: Level 1 Loads With All UI

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz → Quiz Summary tab | Page loads with quiz_summary tab active |
| 2 | Check filter bar | Class Section, Subject dropdowns visible |
| 3 | Check quiz cards | Each card shows: title, class, subject, total_assigned, submitted_count, in_progress_count, total_attempt_count |
| 4 | Check score distribution chart (5 bins) | <35, 35-49, 50-69, 70-84, 85-100 bins present |
| 5 | Check status count bar | SUBMITTED, IN_PROGRESS, NOT_STARTED counts |

#### TC-P02: Level 1 — withCount Stats

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Filter by class-section | Quiz cards scoped to class_id |

---

#### TC-P03: Level 1 — Total Assigned (CLASS type)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Filter by subject | Quiz cards scoped to subject_id |

---

#### TC-P04: Level 1 — Total Assigned (SECTION type)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click Score Distribution bin | Student table below filters to that bin |

---

#### TC-P05: Level 1 — Total Assigned (STUDENT type)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click Status filter | Student table below filters to that status |

---

#### TC-P06: Level 1 — Filter by class_section_id

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify total_assigned | Matches DB computed count via allocation_type |

---

#### TC-P07: Level 1 — Filter by subject_id

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify submitted_count | Matches withCount result for submissions |

---

#### TC-P08: Level 1 — Filter by date range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify in_progress_count | Matches withCount for IN_PROGRESS |

---

#### TC-P09: Level 1 — Search by quiz title

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify total_attempt_count | Matches total attempts withCount |

---

#### TC-P10: Level 1 — Search by quiz_code

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify score bin counts | Each bin matches PHP conditional counting loop |

---

#### TC-P11: Level 1 — Pagination

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify status bar counts | NOT_STARTED = total_assigned - any_attempt; others match |

### 7.2 Positive TC Steps — Level 2 (Student Table)

#### TC-P12: Navigate to Level 2

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click on a quiz card | URL changes to `/quize/report/{quiz_id}` |
| 2 | Check Level 2 UI | Quiz title, filter bar (student search, status, score bin), student table |
| 3 | Check table columns | Student Name, Admission No, Status, Score %, Category, Action (View) |

#### TC-P13: Level 2 — Status Counts

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Filter by status (SUBMITTED) | Only students with submitted attempt shown |

---

#### TC-P14: Level 2 — Score Distribution

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Filter by score bin (85-100) | Only students with percentage in that range |

---

#### TC-P15: Level 2 — Average Score

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set NOT_STARTED filter | Students with NO attempt at all shown (status = NOT_STARTED) |

---

#### TC-P16: Level 2 — Filter by Status

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Use combination filters | AND logic: status + score bin applied together |

---

#### TC-P17: Level 2 — Search Student

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Type in student search field | Table filters by name or admission_no match |

---

#### TC-P18: Level 2 — Pagination (25/page)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Paginate (26+ students) | Page 2 shows next 25 |

### 7.3 Positive TC Steps — Level 3 (Attempt Detail)

#### TC-P19: Navigate to Level 3

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click View on a Level 2 student row | Navigate to attempt detail page |
| 2 | Check score summary | marks_obtained, total_marks, percentage, is_pass, time_taken, correct/wrong/unattempted counts |
| 3 | Check questions list | Each question: text, options, selected answer, correct answer, marks, explanation |

#### TC-P20: Level 3 — Score Summary

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify percentage calculation | (marks_obtained/total_marks)*100 matches |

---

#### TC-P21: Level 3 — Question Order

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify question order | Questions ordered by `ordinal` column ascending |

---

#### TC-P22: Level 3 — Correct/Wrong/Unattempted

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check correct/wrong/unattempted indicators | Green for correct, red for wrong, gray for unattempted |

### 7.4 Negative TC Steps

#### TC-N01: No Allocations Exist — Empty Summary

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | No allocations exist | Summary shows empty table or "No data available" |

---

#### TC-N02: No Attempts for Allocation

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Allocations exist but no one attempted | submitted=0, in_progress=0, total_attempt=0 |

---

#### TC-N03: Invalid Quiz ID in Report URL

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Access report with invalid quiz_id | 404 Not Found |

---

#### TC-N04: Invalid Attempt ID in Detail URL

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Access detail with invalid attempt_id | 404 Not Found |

---

#### TC-N05: View Without Permission (Level 1)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User without `tenant.quiz.viewAny` | 403 Forbidden (Level 1) |

---

#### TC-N06: View Without Permission (Level 2/3)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User without `tenant.quiz.view` | 403 Forbidden (Level 2/3) |

---

#### TC-N07: Deleted Quiz — Report

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete quiz → access report URL | 404 (no withTrashed in findOrFail) |

---

#### TC-N08: Student with No Quiz Model on Attempt

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt with null quiz_id | Fallback logic attempted or 404 |

### 7.5 Dependency TC Steps

#### TC-D01: 3-Level Drill-Down

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Level 1 → click card → Level 2 → click student → Level 3 | All 3 levels render correctly; back navigation works |

---

#### TC-D02: Score Bin Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify 5 score bins match actual attempt % | Each bin count matches DB query result |

---

#### TC-D03: Status Count — Latest Attempt

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has 2 attempts: first IN_PROGRESS, second SUBMITTED | Counted as SUBMITTED (latest attempt status used) |

---

#### TC-D04: Total Assigned — GROUP type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | GROUP allocation with 15 members | total_assigned = 15 |

---

#### TC-D05: Class-Section Filter — Scope Logic

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | SECTION + CLASS allocation types | Both types matched via class_id scope |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | No ghost rescue for deleted quizzes in report/attemptDetail | Deleted quiz → 404; no "Deleted" label fallback | Observed |
| KI-02 | No separate summary permission — shares `tenant.quiz.viewAny` | Any user with quiz list access sees summary tab | Confirmed (by design) |
| KI-03 | Level 2 report uses quiz_id route parameter (NOT allocation_id) | Route name is misleading (`/quize/report/{id}` where id = quiz_id) | Observed |
| KI-04 | Level 2 student table only shows students from StudentAcademicSession | Students not in current academic session not listed | Observed |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quize` (active_tab=quiz_summary) | `lms-quize.quize.index` | `LmsQuizController@index` |
| GET | `/lms-quize/quize/report/{id}` | `lms-quize.quize.report` | `LmsQuizController@report` |
| GET | `/lms-quize/quize/attempt/{attempt_id}/detail` | `lms-quize.quize.attemptDetail` | `LmsQuizController@attemptDetail` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 41 | 22 | 8 | 5 | 6 | 0 | 0 | 0 | 0 |
