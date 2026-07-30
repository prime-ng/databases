# lms_quiz_class_performance_report_TcList

## Module: LmsQuiz → Quiz Management → Reports → Class Performance Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management → Reports (quiz-reports) |
| Feature | Class Performance Report (tab: class-performance) |
| URL(s) | `/lms-quize/quiz-reports` (active_tab=class-performance, AJAX loads partial) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` → `generateReportData()` |
| Model(s) | `QuizQuestAttempt`, `QuizQuestResult`, `Quiz`, `QuizAllocation`, `StudentAcademicSession` |
| Validation | Filter parameters only (class_section_id, subject_id, date range, etc.) |
| Permissions | `tenant.quiz-dashboard.view` (shared with entire report page) |
| Soft Deletes | Ghost rescue: handles deleted quizzes/students with `withTrashed()` |
| Default Date Range | Last 30 days (prevents unbounded ALL-time query) |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-dashboard.view`
- Class-section filter must be applied (report is scoped to a class-section; first active auto-selected)
- At least one quiz with student attempts must exist for the selected class-section
- Tenant context initialized

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Class Metrics | `QuizQuestAttempt::with('result')` | Aggregated per-student: attempted, correct, wrong, score, category | class_section_id, subject_group_id, subject_id, quiz_type, quiz_id, assessment_type, lesson_id, topic hierarchy, date_from, date_to | None (top-level aggregates) |
| Student Rows | Collection built from attempts grouped by student_id | Each row: date, student_name, type (Homework/Assessment), quiz_id, quiz_title, attempted (Yes/No), total_ques, correct, wrong, not_attempted, score (0-100), category | Same as above | 15 per page |
| Score Categories | `getCategory(float $score): string` | >=85 outstanding, >=70 good, >=50 satisfactory, >=35 needs_attention, <35 struggling | Computed from score | None |

---

## 4. Test Data Strategy

- **Data Volume**: Test with 1 class-section, 5+ quizzes, 30+ students, multiple attempts each
- **Subject Filters**: Test subject-specific performance
- **Assessment Type**: Test Both/QUIZ/QUEST filtering
- **Date Range**: Test performance within specific date windows
- **Empty State**: Test class with no quiz attempts
- **Ghost Data**: Soft-delete quiz or student → verify report shows gracefully

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from: `lms_quiz_quest_attempts`, `lms_quiz_quest_results`, `lms_quizzes`, `std_student_academic_sessions`, `sch_class_sections`, `sch_classes`, `sch_subjects`

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | class_section_id | nullable (auto-selects first active), integer, exists:sch_class_sections,id | |
| BC-VAL-02 | subject_group_id | nullable, integer | |
| BC-VAL-03 | subject_id | nullable, integer | |
| BC-VAL-04 | quiz_type | nullable, integer | Maps to quiz_type_id |
| BC-VAL-05 | quiz_id | nullable, integer | |
| BC-VAL-06 | assessment_type | nullable, string, in:Both,QUIZ,QUEST | Defaults to Both |
| BC-VAL-07 | date_from | nullable, date | Defaults to 30 days ago |
| BC-VAL-08 | date_to | nullable, date | Defaults to today |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz-dashboard.view | Entire report page returns 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Report loads — metrics card | total_students, attempted, not_attempted, class_average, highest_score, lowest_score shown |
| BC-BIZ-02 | Report loads — aggregated totals | total_questions, total_correct, total_wrong, total_not_attempted_qs shown |
| BC-BIZ-03 | Score category counts | outstanding, good, satisfactory, needs_attention, struggling counts shown |
| BC-BIZ-04 | Per-student row — attempted | Shows date, student_name, type, quiz_id, quiz_title, attempt counts, score |
| BC-BIZ-05 | Per-student row — not attempted | Shows "No" for attempted, 0 for scores, slash for date/type |
| BC-BIZ-06 | Class-section + subject filter | Data scoped to specific subject within the class-section |
| BC-BIZ-07 | Assessment type filter | Both shows all; QUIZ shows only homework; QUEST shows only assessments |
| BC-BIZ-08 | Ghost rescue — deleted quiz | Quiz title/code from `QuizQuestAttempt` relationship; if model null, shows "Unknown" |
| BC-BIZ-09 | Ghost rescue — deleted student | Student name from `student->full_name`; if null shows "Unknown" |
| BC-BIZ-10 | No data — empty class-section | All metrics show 0; empty data table |
| BC-BIZ-11 | Date range filter | Only attempts with `submitted_at` within range included |
| BC-BIZ-12 | No class-section selected | Auto-selects first active ClassSection |
| BC-BIZ-13 | Attempt uses latest per student | If student has multiple attempts, only latest (by submitted_at) used for report row |
| BC-BIZ-14 | Score fallback for zero percentage | If percentage=0 but correct>0 and total>0, recalculates as (correct/total)*100 |

### 5.5 Referential Integrity

Same as parent Quiz and QuizQuestAttempt tables. StudentAcademicSession references std_student_academic_sessions for student-to-class mapping.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Class Performance Report — All Data | Metrics card + student data table loaded with correct values | — | — | ⬜ |
| TC-P02 | Metrics — Total Students | Count matches students in class-section (from StudentAcademicSession) | — | — | ⬜ |
| TC-P03 | Metrics — Attempted Count | Count matches students with at least one SUBMITTED/TIMEOUT attempt | — | — | ⬜ |
| TC-P04 | Metrics — Not Attempted Count | Count matches students with no attempts in scope | — | — | ⬜ |
| TC-P05 | Metrics — Class Average | Calculated average across all attempted student scores | — | — | ⬜ |
| TC-P06 | Metrics — Highest/Lowest Score | Correct min and max score from attempted rows | — | — | ⬜ |
| TC-P07 | Metrics — Total Questions/Correct/Wrong | Aggregated sums across all student rows | — | — | ⬜ |
| TC-P08 | Score Categories — Correct Counts | Each category (outstanding/good/satisfactory/needs_attention/struggling) count matches | — | — | ⬜ |
| TC-P09 | Student Row — Attempted Student | Shows date, name, type, quiz code, title, Yes, counts, score, category | — | — | ⬜ |
| TC-P10 | Student Row — Not Attempted Student | Shows "No", 0 for counts, "-" for date/type, 0 score | — | — | ⬜ |
| TC-P11 | Filter by Subject | Only data for selected subject shown | — | — | ⬜ |
| TC-P12 | Filter by Assessment Type (Both/QUIZ/QUEST) | Data filtered by assessment_type | — | — | ⬜ |
| TC-P13 | Filter by Quiz | Only data for selected quiz shown | — | — | ⬜ |
| TC-P14 | Filter by Date Range | Attempts outside range excluded | — | — | ⬜ |
| TC-P15 | Pagination | Page 2 shows next set of 15 student rows | — | — | ⬜ |
| TC-P16 | Hierarchy Topic Filters (lesson/topic/sub-topic) | Data filtered by topic hierarchy | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Class-Section Available | Auto-selects first active; if none, empty report | — | — | ⬜ |
| TC-N02 | No Quiz Attempts in Class | Metrics show 0s; table empty or shows "No data available" | — | — | ⬜ |
| TC-N03 | All Students Not Attempted | attempted=0, not_attempted=total_students; all scores 0 | — | — | ⬜ |
| TC-N04 | Ghost — Deleted Quiz (soft-delete) | Quiz title shows "-" or "Unknown"; attempt data still counted | — | — | ⬜ |
| TC-N05 | Ghost — Deleted Student (soft-delete) | Student name shows "Unknown" but row still appears | — | — | ⬜ |
| TC-N06 | View Without Permission | 403 Forbidden | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Score Categories | P1 | Student with 90% → outstanding; 75% → good; 55% → satisfactory; 40% → needs_attention; 20% → struggling | Category classification matches threshold: >=85, >=70, >=50, >=35, <35 | — | — | ⬜ |
| TC-D02 | B | Latest Attempt Only | P1 | Student with 2 attempts on same quiz | Only latest attempt (by submitted_at DESC) used for report row | — | — | ⬜ |
| TC-D03 | C | Assessment Type Split | P1 | Student has Both quiz and quest attempts | With assessment_type=Both, both types shown; with QUIZ, only homework rows | — | — | ⬜ |
| TC-D04 | D | Pagination Accuracy | P1 | 32 students → 3 pages (15+15+2) | Page 1 = 15, Page 2 = 15, Page 3 = 2 | — | — | ⬜ |
| TC-D05 | E | Date Range Boundary | P1 | Attempt on date_from exactly | Included; attempt on date_from-1 day excluded | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — generateReportData — ghost rescue | Queries check `$attempt->student?->full_name` with null coalescing; no `withTrashed()` used (relies on relationship null check) | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateReportData — pagination | Uses `LengthAwarePaginator` with 15 per page, manual slice from collection | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — generateReportData — score categories | Uses `getCategory()` helper with hardcoded thresholds: >=85, >=70, >=50, >=35 | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — generateReportData — metrics aggregation | Metrics computed from `$reportData` collection using `sum()` and `where('attempted','Yes')->avg('score')` | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — generateReportData — date defaults | If `date_from`/`date_to` not provided, defaults to `Carbon::now()->subDays(30)` and `Carbon::now()` | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — index — lazy loading | Report data only generated on AJAX request (`$request->ajax()` guard) | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Report Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz Reports → Class Performance tab | Page loads with class-performance tab active |
| 2 | Check filter bar | Class Section, Subject (cascaded), Assessment Type (Both/QUIZ/QUEST), Date Range visible |
| 3 | Check metrics row | total_students, attempted_count, not_attempted_count, class_avg displayed |
| 4 | Check table columns | Student Name, Quiz Count, Max Score, Avg Score, Min Score, Category, Attempted/Not |
| 5 | Verify data loads via AJAX | Only table/metrics container refreshes on filter change |

---

#### TC-P02: Metrics — Total Students

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with known data | total_students count matches StudentAcademicSession count for that class-section |

---

#### TC-P03: Metrics — Attempted Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section where students have submitted attempts | attempted_count matches count of students with ≥1 SUBMITTED/TIMEOUT attempt |

---

#### TC-P04: Metrics — Not Attempted Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with mixed attempted/unattempted students | not_attempted = total_students - attempted_count |

---

#### TC-P05: Metrics — Class Average

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with attempted students | class_average equals AVG of all attempted student scores |

---

#### TC-P06: Metrics — Highest/Lowest Score

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with varied student scores | highest_score and lowest_score match correct min and max from attempted rows |

---

#### TC-P07: Metrics — Total Questions/Correct/Wrong

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with attempt data | Aggregated totals (total_questions, total_correct, total_wrong, total_not_attempted_qs) displayed correctly |

---

#### TC-P08: Score Categories — Correct Counts

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Switch assessment_type through Both→QUIZ→QUEST | Category counts (outstanding/good/satisfactory/needs_attention/struggling) update per filter |

---

#### TC-P09: Student Row — Attempted Student

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View student row for a student who attempted | Row shows date, student_name, type, quiz_id, quiz_title, "Yes", total_ques, correct, wrong, not_attempted, score, category |

---

#### TC-P10: Student Row — Not Attempted Student

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View student row for a student who did not attempt | Row shows "No" for attempted, 0 for counts, "-" for date/type, 0 score |

---

#### TC-P11: Filter by Subject

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a subject from the filter dropdown | Metrics and table data scoped to selected subject only |

---

#### TC-P12: Filter by Assessment Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Cycle assessment_type through Both→QUIZ→QUEST | Both: all data shown; QUIZ: only homework rows; QUEST: only assessment rows |

---

#### TC-P13: Filter by Quiz

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a specific quiz from the filter | Only data for selected quiz shown in metrics and table |

---

#### TC-P14: Filter by Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date range and apply filter | Only attempts with submitted_at within range included |

---

#### TC-P15: Pagination

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Load class-section with 16+ student rows | Page 1 shows 15 rows; Page 2 renders remaining rows |

---

#### TC-P16: Hierarchy Topic Filters

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select lesson/topic/sub-topic hierarchy filter | Data scoped to selected topic hierarchy level |

---

#### TC-P17: Outstanding Score Category

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Locate student with avg_score >= 85 | Category displayed as "outstanding" |

---

#### TC-P18: Good Score Category

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Locate student with avg_score 70–84.99 | Category displayed as "good" |
| 2 | Locate student with avg_score 50–69.99 | Category displayed as "satisfactory" |
| 3 | Locate student with avg_score 35–49.99 | Category displayed as "needs_attention" |
| 4 | Locate student with avg_score < 35 | Category displayed as "struggling" |

---

#### TC-P19: Total Students Metric

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count distinct students with attempts in class-section | total_students matches DB count |

---

#### TC-P20: Attempted Count Metric

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count students with at least 1 submitted attempt | attempted_count matches |

---

#### TC-P21: Not Attempted Count Metric

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count students with 0 submitted attempts | not_attempted = total - attempted |

---

#### TC-P22: Class Average Metric

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Compute AVG of per-student avg_score via DB | class_avg matches report value |

---

### 7.2 Negative TC Steps

#### TC-N01: No Class-Section Available

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Use class-section with no active StudentAcademicSession | Auto-selects first active; if none, metrics show 0s |

---

#### TC-N02: No Quiz Attempts in Class

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with no quiz attempts | All metrics show 0; table displays "No data available" |

---

#### TC-N03: All Students Not Attempted

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | All students have allocations but no one attempted | attempted=0, not_attempted=total_students |

---

#### TC-N04: Ghost — Deleted Quiz

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete a quiz that has attempts | Quiz title shows "-" or "Unknown"; attempt data still counted |

---

#### TC-N05: Ghost — Deleted Student

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete a student who has attempts | Student name shows fallback; row still present |

---

#### TC-N06: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-dashboard.view` | 403 Forbidden |

---

### 7.3 Dependency TC Steps

#### TC-D01: Score Categories

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check student with avg 90%, 75%, 55%, 40%, 20% | Categories: outstanding, good, satisfactory, needs_attention, struggling |

---

#### TC-D02: Latest Attempt Only

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create 2 attempts (60% then 80%) for same student on same quiz | Report uses 80% (latest by submitted_at DESC) |

---

#### TC-D03: Assessment Type Split

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has both QUIZ and QUEST attempts; filter = Both | Both attempt types shown in table |

---

#### TC-D04: Pagination Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Load class-section with 32 students | Page 1 = 15 rows, Page 2 = 15 rows, Page 3 = 2 rows |

---

#### TC-D05: Date Range Boundary

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attempt submitted on date_from exactly | Attempt included in results |
| 2 | Attempt submitted on date_from - 1 day | Attempt excluded from results |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | No pass/fail threshold; uses 5-category score system instead | No "pass rate" metric; uses fixed categories (outstanding/good/satisfactory/needs_attention/struggling) | Confirmed (by design) |
| KI-02 | No per-quiz breakdown table — only per-student rows | Cannot see aggregate per-quiz performance; only student-level data | Observed |
| KI-03 | Student data limited to class-section via StudentAcademicSession | Students not in current academic session for this class-section not shown | Observed |
| KI-04 | No export (CSV/PDF) functionality | Report only available as HTML view | Missing feature |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quiz-reports` (active_tab=class-performance) | `quiz-reports.index` | `LmsQuizReportController@index` |
| GET | `/lms-quize/quiz-reports/filter-dependencies` | `quiz-reports.filter-dependencies` | `LmsQuizReportController@getDependencies` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 33 | 16 | 6 | 5 | 6 | 0 | 0 | 0 | 0 |
