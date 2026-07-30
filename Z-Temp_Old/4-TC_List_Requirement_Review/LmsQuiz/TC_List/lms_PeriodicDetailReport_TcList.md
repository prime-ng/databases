# lms_quiz_periodic_detail_report_TcList

## Module: LmsQuiz → Quiz Management → Reports → Periodic Detail Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management → Reports (quiz-reports) |
| Feature | Periodic Detail Report (tab: periodic-detail) |
| URL(s) | `/lms-quize/quiz-reports` (active_tab=periodic-detail, AJAX loads partial) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` → `generatePeriodicDetailData()` |
| Model(s) | `QuizQuestAttempt`, `QuizQuestResult`, `Quiz`, `Quest`, `QuizAllocation`, `QuestAllocation`, `StudentAcademicSession` |
| Validation | Filter parameters only |
| Permissions | `tenant.quiz-dashboard.view` (shared with entire report page) |
| Soft Deletes | Ghost rescue via `withTrashed()` for deleted quizzes, quests, and related models |
| Default Date Range | Last 30 days |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-dashboard.view`
- Student may be selected (defaults to first student with attempts in range, or first enrolled student)
- Class-section context available
- Quiz/Quest activity exists within selected date range

---

## 3. Default Data Load

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Attempt Rows (Attempted) | `QuizQuestAttempt::with('result','answers','quiz','quest','student')` | `->whereIn('status',['SUBMITTED','TIMEOUT'])->whereDate('submitted_at','>=',$from)->whereDate('submitted_at','<=',$to)` | student_id, assessment_type, subject_id, subject_group_id, lesson_id, topic_type_id, topic hierarchy | 15 per page |
| Unattempted Rows | `QuizAllocation::with('quiz')` + `QuestAllocation::with('quest')` | Filtered by student's class/section/student allocation types | student_id, subject_id | None |
| Metrics | Computed from all matching attempts | total_students, attempted, not_attempted, class_average, cat_counts (1-5 for 5 categories) | All filters | None |

---

## 4. Test Data Strategy

- **Flat attempt list**: This is NOT a period-grouped report; it shows all attempts as individual rows with attempted/unattempted status
- **Filter Variety**: Test with all filter combinations (student, subject, lesson, topic hierarchy, assessment type, topic type)
- **Attempted + Unattempted**: Verify both rows appear — attempted first, then unattempted
- **Ghost Rescue**: Delete a quiz after student attempt → verify report handles gracefully
- **Category Classification**: Verify outstanding/good/satisfactory/needs_attention/struggling classification

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from: `lms_quiz_quest_attempts`, `lms_quiz_quest_results`, `lms_quizzes`, `lms_quests`, `lms_quiz_allocations`, `lms_quest_allocations`, `sch_subjects`, `std_student_academic_sessions`

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | student_id | nullable, integer | Auto-selects first student with attempts |
| BC-VAL-02 | class_id | nullable, integer | Derived from student's academic session |
| BC-VAL-03 | section_id | nullable, integer | |
| BC-VAL-04 | assessment_type | nullable, string, in:Both,QUIZ,QUEST | Defaults to Both |
| BC-VAL-05 | subject_id | nullable, integer | |
| BC-VAL-06 | date_from | nullable, date | Defaults to 30 days ago |
| BC-VAL-07 | date_to | nullable, date | Defaults to today |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz-dashboard.view | 403 Forbidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Metrics card — total_students | Count of unique students with attempts (or 1 if student_id fixed) |
| BC-BIZ-02 | Metrics card — attempted/not_attempted | Count of students with/without attempts |
| BC-BIZ-03 | Metrics card — class_average | Average of per-student average percentages |
| BC-BIZ-04 | Metrics — cat_counts | Count of students in each of 5 categories (1=outstanding...5=struggling) |
| BC-BIZ-05 | Attempted row — student data | student_name, subject, lesson, topic, attempt_date, quiz_id, assign_date, "Yes", total_ques, correct, wrong, not_attempted, score, category |
| BC-BIZ-06 | Unattempted row — student data | Same structure with "No", 0 for scores, "-" for dates |
| BC-BIZ-07 | Sorting: attempted first | All "Yes" rows appear before "No" rows |
| BC-BIZ-08 | Subject/lesson/topic resolution | Resolved from Quiz/Quest model or topic hierarchy chain with fallback |
| BC-BIZ-09 | Ghost rescue — deleted model | If quiz/quest model null, rescues via `withTrashed()` lookup; shows "N/A"/"Deleted/Missing" for names |
| BC-BIZ-10 | No student selected | Auto-selects first student with SUBMITTED/TIMEOUT attempts in range, or first enrolled |
| BC-BIZ-11 | No data in range | Empty data table; metrics show 0 |
| BC-BIZ-12 | Subject filter | Attempts scoped to specific subject |
| BC-BIZ-13 | Correct/wrong fallback | If `correct_answers_count`=0 but percentage>0, recalculates from percentage × total_ques |

### 5.5 Referential Integrity

Same as parent attempt and allocation tables. Ghost rescue handles missing FK references.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Periodic Detail Report | Metrics card + attempt rows (attempted + unattempted) loaded | — | — | ⬜ |
| TC-P02 | Metrics — Total Students | Count matches unique students with attempts | — | — | ⬜ |
| TC-P03 | Metrics — Attempted Count | Count of students with ≥1 attempt | — | — | ⬜ |
| TC-P04 | Metrics — Not Attempted | Count of students with allocations but no attempts | — | — | ⬜ |
| TC-P05 | Metrics — Class Average | Average of per-student average percentages | — | — | ⬜ |
| TC-P06 | Metrics — Category Counts | Correct counts for each of 5 categories | — | — | ⬜ |
| TC-P07 | Attempted Row — All Fields | Shows date, student, subject, lesson, topic, quiz code, Yes, counts, score | — | — | ⬜ |
| TC-P08 | Unattempted Row — Shows "No" | Shows "No" for attempted, 0s for scores, "-" for dates | — | — | ⬜ |
| TC-P09 | Sorting — Attempted First | All attempted rows appear before unattempted rows | — | — | ⬜ |
| TC-P10 | Filter by Student | Only attempts/allocation rows for selected student shown | — | — | ⬜ |
| TC-P11 | Filter by Subject | Data scoped to subject | — | — | ⬜ |
| TC-P12 | Filter by Assessment Type | Both/QUIZ/QUEST filter applied | — | — | ⬜ |
| TC-P13 | Filter by Lesson/Topic Hierarchy | Data scoped to lesson, topic, sub-topic, mini-topic, micro-topic | — | — | ⬜ |
| TC-P14 | Filter by Topic Type | Data scoped by topic_level_type_id | — | — | ⬜ |
| TC-P15 | Filter by Date Range | Only attempts within range shown | — | — | ⬜ |
| TC-P16 | Pagination | Page 2 shows next set of 15 attempt rows | — | — | ⬜ |
| TC-P17 | Subject Group Filter | Data filtered by subject_group_id | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Student Selected | Auto-selects first student with attempts | — | — | ⬜ |
| TC-N02 | No Data in Date Range | "No data available" message; metrics show 0 | — | — | ⬜ |
| TC-N03 | Ghost — Deleted Quiz (soft-delete) | Shows "Deleted/Missing" for lesson; score data preserved | — | — | ⬜ |
| TC-N04 | Ghost — Deleted Student | Student name shows fallback; data still included | — | — | ⬜ |
| TC-N05 | View Without Permission | 403 Forbidden | — | — | ⬜ |
| TC-N06 | Invalid Student ID | Filter falls back to auto-selected student | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Attempted + Unattempted Mix | P1 | Student has 3 quiz attempts + 2 quiz allocations unattempted | 3 "Yes" rows + 2 "No" rows; Yes rows first | — | — | ⬜ |
| TC-D02 | B | Score Category Accuracy | P1 | Attempt with 90% → outstanding; 55% → satisfactory; 20% → struggling | Category classification matches 5-tier threshold | — | — | ⬜ |
| TC-D03 | C | Ghost — Delete and Rescue | P1 | Soft-delete quiz → verify report shows rescued data | Quiz data still appears with fallback labels | — | — | ⬜ |
| TC-D04 | D | Subject + Lesson + Topic Resolution | P1 | Quest with scopes → topic → lesson chain | All hierarchy labels resolved correctly | — | — | ⬜ |
| TC-D05 | E | Metrics — Per-Student Averaging | P1 | Student with 3 attempts: 80%, 60%, 70% | Per-student avg = 70%; class_avg = avg of all per-student avgs | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — generatePeriodicDetailData — ghost rescue | Pre-fetches `Quiz::withTrashed()` and `Quest::withTrashed()` for missing models | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generatePeriodicDetailData — data sorting | Sort: attempted (Yes) rows first, then unattempted (No) rows | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — generatePeriodicDetailData — category classification | Uses `getCategory()` with 5-tier thresholds | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — generatePeriodicDetailData — batch question counts | Pre-fetches quiz/quest question counts via `groupBy` to avoid N+1 | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — generatePeriodicDetailData — pagination | Uses `->latest('submitted_at')->paginate(15)` | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Report Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz Reports → Periodic Detail tab | Page loads with periodic-detail tab active |
| 2 | Check filter bar | Class Section, Subject, Topic Type, Student dropdown, Assessment Type, Date Range visible |
| 3 | Check metrics | Attempts count, avg score, best score, worst score displayed |
| 4 | Check table columns | Date, Quiz/Quest, Lesson, Topic, Attempted (Yes/No), Score %, Category |
| 5 | Verify data loads via AJAX | Only table/metrics container refreshes on filter change |

---

#### TC-P02: Metrics — Total Students

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section | Student dropdown populates with enrolled students |

---

#### TC-P03: Metrics — Attempted Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select student with known attempts | Table shows ONLY that student's attempts |

---

#### TC-P04: Metrics — Not Attempted

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify row for a student with submitted attempt | Row shows "Yes" with score |

---

#### TC-P05: Metrics — Class Average

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify row for allocation where no attempt exists | Row shows "No" with '—' for score |

---

#### TC-P06: Metrics — Category Counts

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student attempted Quiz only | Score % computed as (marks_obtained/total_marks)*100 |

---

#### TC-P07: Attempted Row — All Fields

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student attempted Quest only | Score based on percentage field |

---

#### TC-P08: Unattempted Row — Shows "No"

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify row for allocation with no corresponding attempt | Row shows "No" for attempted with '—' for score |

---

#### TC-P09: Sorting — Attempted First

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Load report with both attempted and unattempted data | All attempted ("Yes") rows appear before unattempted ("No") rows |

---

#### TC-P10: Filter by Student

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select different student from dropdown | All metrics + table reload for that student |

---

#### TC-P11: Filter by Subject

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a subject from the filter | Only data for selected subject shown |

---

#### TC-P12: Filter by Assessment Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Change assessment_type filter (Both/QUIZ/QUEST) | Only matching rows shown per filter |

---

#### TC-P13: Filter by Lesson/Topic Hierarchy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select lesson/topic filter | Only rows matching filter shown |

---

#### TC-P14: Filter by Topic Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select topic_type filter | Data scoped by topic_level_type_id |

---

#### TC-P15: Filter by Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date range | Only attempts within range shown |

---

#### TC-P16: Pagination

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Load report with 16+ attempt rows | Page 2 shows remaining rows |

---

#### TC-P17: Subject Group Filter

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select subject_group filter | Only subjects in selected group shown |

---

### 7.2 Negative TC Steps

#### TC-N01: No Student Selected

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Load report without explicitly selecting a student | Auto-selects first student with attempts in range |

---

#### TC-N02: No Data in Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select date range with no attempts | "No data available" message displayed; metrics show 0 |

---

#### TC-N03: Ghost — Deleted Quiz

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete quiz with existing attempt | Shows "Deleted/Missing" for lesson; score data preserved |

---

#### TC-N04: Ghost — Deleted Student

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete student with existing attempt | Student name shows fallback; data still included |

---

#### TC-N05: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-dashboard.view` | 403 Forbidden |

---

#### TC-N06: Invalid Student ID

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Pass invalid student_id in filter | Falls back to auto-selected student |

---

### 7.3 Dependency TC Steps

#### TC-D01: Attempted + Unattempted Mix

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has 3 attempts + 2 allocations unattempted | 3 "Yes" rows + 2 "No" rows; Yes rows appear first |

---

#### TC-D02: Score Category Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scores: 90%, 55%, 20% | Categories: outstanding, satisfactory, struggling |

---

#### TC-D03: Ghost — Delete and Rescue

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Soft-delete quiz → verify rescue | Quiz data appears with fallback labels |

---

#### TC-D04: Subject + Lesson + Topic Resolution

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Quest with scopes → topic → lesson chain | Hierarchy labels resolved correctly |

---

#### TC-D05: Metrics — Per-Student Averaging

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has 3 attempts: 80%, 60%, 70% | Per-student avg = 70%; class_avg = avg of all per-student avgs |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | No period_type grouping (weekly/monthly/quarterly) | Report is a flat attempt list, not bucketed by period | Confirmed (by design) |
| KI-02 | No period-over-period trend chart | No visual trend analysis | Missing feature |
| KI-03 | No drill-down to per-quiz detail within period | Each row IS the detail; no additional drill-down level | Confirmed (by design) |
| KI-04 | Unattempted rows based on allocations (not class-section) | Student must be selected; unattempted rows show only for that specific student | Observed |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quiz-reports` (active_tab=periodic-detail) | `quiz-reports.index` | `LmsQuizReportController@index` |
| GET | `/lms-quize/quiz-reports/filter-dependencies` | `quiz-reports.filter-dependencies` | `LmsQuizReportController@getDependencies` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 33 | 17 | 6 | 5 | 5 | 0 | 0 | 0 | 0 |
