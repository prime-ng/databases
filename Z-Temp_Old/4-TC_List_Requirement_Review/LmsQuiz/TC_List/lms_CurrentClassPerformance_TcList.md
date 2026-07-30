# lms_quiz_current_class_performance_TcList

## Module: LmsQuiz → Quiz Management → Reports → Current Class Performance

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management → Reports (quiz-reports) |
| Feature | Current Class Performance (tab: current-class) |
| URL(s) | `/lms-quize/quiz-reports` (active_tab=current-class, AJAX loads partial) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` → `generateCurrentClassData()` |
| Model(s) | `QuizQuestAttempt`, `QuizAllocation`, `QuestAllocation`, `StudentAcademicSession`, `Student` |
| Validation | Filter parameters only |
| Permissions | `tenant.quiz-dashboard.view` (shared with entire report page) |
| Soft Deletes | N/A (no explicit ghost rescue in generateCurrentClassData) |
| Default Date Range | Last 30 days |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-dashboard.view`
- Class-section filter is auto-selected (first active) if not provided
- Quiz/Quest activity exists for the selected class-section
- Students must be enrolled in the class-section via StudentAcademicSession

---

## 3. Default Data Load

| Data | Source | Query | Filters | Limit |
|------|--------|-------|---------|-------|
| Students | `StudentAcademicSession::with('student')` | `->where('is_current',1)->where('class_section_id',$csId)` | class_section_id | 50 |
| Attempts | `QuizQuestAttempt::with('quiz.lesson','quiz.topic','quest.scopes.topic.lesson')` | `->whereIn('student_id',$ids)->whereIn('status',['SUBMITTED','TIMEOUT'])` | class_section_id, subject_group_id, subject_id, lesson_id, topic_level_type_id, topic hierarchy, assessment_type, date_from, date_to | None |
| Allocations | `QuizAllocation::where('target_id',$csId)`, `QuestAllocation::where('target_id',$csId)` | Pluck quiz_id/quest_id for assigned check | class_section_id | None |
| Lesson/Topic Matrix | Grouped attempt collection by lesson→topic→student | Scores per student per topic; TNA (tried not attempted) / NTA (not tried at all) markers | Same as attempt filters | None |
| Stats | Computed from matrix | total_students, tna_count, nta_count, class_avg | None | None |

---

## 4. Test Data Strategy

- **Current class-section**: Create data for a specific class-section
- **Topic Matrix**: Multiple lessons, topics, and students to verify matrix display
- **TNA/NTA**: Test assigned vs unassigned quizzes for TNA and NTA classification
- **Empty State**: Class-section with no quiz activity
- **Large Class**: 50+ students to test 50-row limit

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from: `lms_quiz_quest_attempts`, `lms_quizzes`, `lms_quests`, `lms_quiz_allocations`, `lms_quest_allocations`, `std_student_academic_sessions`, `sch_class_sections`

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | class_section_id | nullable (auto-selects first active), integer, exists:sch_class_sections,id | |
| BC-VAL-02 | subject_id | nullable, integer | |
| BC-VAL-03 | date_from | nullable, date | Defaults to 30 days ago |
| BC-VAL-04 | date_to | nullable, date | Defaults to today |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz-dashboard.view | 403 Forbidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Class overview stats | total_students, tna_count, nta_count, class_avg shown |
| BC-BIZ-02 | Lesson/Topic matrix | Lessons as groups, topics within lessons, scores per student per topic |
| BC-BIZ-03 | Student score — attempted | Shows numeric score (percentage) for that topic/lesson |
| BC-BIZ-04 | Student score — TNA (assigned but not attempted) | Shows "TNA" for assigned quizzes where student has no attempt |
| BC-BIZ-05 | Student score — NTA (not assigned) | Shows "NTA" for quizzes NOT allocated to this class-section |
| BC-BIZ-06 | Lesson resolution for quiz | Quiz.lesson used; quest uses scopes[0].topic.lesson |
| BC-BIZ-07 | Topic resolution for quiz | Quiz.topic used; quest uses scopes[0].topic |
| BC-BIZ-08 | Latest attempt per student per topic | If multiple attempts, highest percentage used |
| BC-BIZ-09 | No class-section selected | Auto-selects first active ClassSection |
| BC-BIZ-10 | No data for class-section | Returns empty structure: students=[], lessons=[], stats=all zeros |
| BC-BIZ-11 | Student limit | Capped at 50 students (->take(50)) |

### 5.5 Referential Integrity

Same as parent Quiz/Quest and attempt tables. Allocations reference class-section via target_id.

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Current Class Performance | Lesson/topic matrix with student scores shown | — | — | ⬜ |
| TC-P02 | Stats — Total Students | Count matches students in class-section | — | — | ⬜ |
| TC-P03 | Stats — TNA Count | Count of assigned-but-not-attempted markers across matrix | — | — | ⬜ |
| TC-P04 | Stats — NTA Count | Count of not-assigned markers across matrix | — | — | ⬜ |
| TC-P05 | Stats — Class Average | Average of all numeric scores in matrix | — | — | ⬜ |
| TC-P06 | Lesson Grouping | Attempts grouped by lesson name correctly | — | — | ⬜ |
| TC-P07 | Topic Display | Topics shown within correct lesson groups | — | — | ⬜ |
| TC-P08 | Student Score — Numeric | Shows percentage for attempted topics | — | — | ⬜ |
| TC-P09 | Student Score — TNA | Shows "TNA" for allocated but not attempted | — | — | ⬜ |
| TC-P10 | Student Score — NTA | Shows "NTA" for not allocated | — | — | ⬜ |
| TC-P11 | Filter by Subject | Only data for selected subject shown | — | — | ⬜ |
| TC-P12 | Filter by Assessment Type | Both/QUIZ/QUEST filter applied | — | — | ⬜ |
| TC-P13 | Filter by Date Range | Only attempts within range included | — | — | ⬜ |
| TC-P14 | Filter by Lesson/Topic | Data scoped to selected lesson/topic hierarchy | — | — | ⬜ |
| TC-P15 | Multiple Lessons and Topics | Matrix renders correctly with 3+ lessons, 5+ topics | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Class-Section Available | Empty report; stats all zeros | — | — | ⬜ |
| TC-N02 | No Data for Filtered Scope | Matrix shows empty; stats show 0 | — | — | ⬜ |
| TC-N03 | All TNA — No Attempts | All student cells show "TNA"; stats show tna_count = total_students * topics | — | — | ⬜ |
| TC-N04 | All NTA — No Allocations | All student cells show "NTA"; stats show nta_count > 0 | — | — | ⬜ |
| TC-N05 | View Without Permission | 403 Forbidden | — | — | ⬜ |
| TC-N06 | Student Limit Exceeded (60+ students) | Only first 50 students included in matrix | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | TNA vs NTA Classification | P1 | Quiz allocated to class-section but student has no attempt → TNA | Cell shows "TNA" (tried not attempted) | — | — | ⬜ |
| TC-D02 | B | TNA vs NTA Classification | P1 | Quiz NOT allocated to class-section → NTA | Cell shows "NTA" (not tried at all) | — | — | ⬜ |
| TC-D03 | C | Latest Attempt per Topic | P1 | Student has 2 attempts on same topic, 80% and 60% | Score shows 80% (highest) | — | — | ⬜ |
| TC-D04 | D | Lesson Resolution — Quest | P1 | Quest with no direct lesson, resolved via scopes → topic → lesson | Lesson name resolved correctly | — | — | ⬜ |
| TC-D05 | E | Class Average Calculation | P1 | 3 students with scores 80, 60, TNA | Class average = 70 (TNA excluded from avg) | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — generateCurrentClassData — student limit | Uses `->take(50)` on StudentAcademicSession query | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateCurrentClassData — allocation check | Uses `QuizAllocation::where('target_id', $classSectionId)` and `QuestAllocation::where('target_id', $classSectionId)` for assigned check | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — generateCurrentClassData — lesson/topic resolution | Quiz uses `$model->lesson` and `$model->topic`; Quest uses `$model->scopes[0]->topic->lesson` | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — generateCurrentClassData — latest attempt score | Uses `$sAttempts->sortByDesc('percentage')->first()->percentage` for highest score | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — generateCurrentClassData — date defaults | Defaults to `Carbon::now()->subDays(30)` and `Carbon::now()` | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Matrix Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz Reports → Current Class tab | Page loads with current-class tab active |
| 2 | Check filter bar | Class Section, Subject, Topic Type, Date Range visible |
| 3 | Check metrics row | total_students, attempted_count, nta_count, tna_count, class_avg displayed |
| 4 | Check matrix | Rows = students (up to 50), Columns = topics/skills with scores |
| 5 | Verify AJAX loading | Only matrix container refreshes on filter change |

---

#### TC-P02: Stats — Total Students

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section → subject | Topics populate as column headers |

---

#### TC-P03: Stats — TNA Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has ONE submitted attempt with 75% | Cell shows "75%" |

---

#### TC-P04: Stats — NTA Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has multiple attempts on same topic | Cell shows highest score percentage |

---

#### TC-P05: Stats — Class Average

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has 0 submitted attempts but quiz allocated | Cell shows "TNA" (Tried Not Attempted) |

---

#### TC-P06: Lesson Grouping

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Quiz not allocated to this class-section/student | Cell shows "NTA" (Not Tried At All) |

---

#### TC-P07: Topic Display

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count total StudentAcademicSession for class | total_students matches DB |

---

#### TC-P08: Student Score — Numeric

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count students with ≥1 submitted attempt | attempted_count matches |

---

#### TC-P09: Student Score — TNA

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count cells showing "TNA" across all students × topics | tna_count matches |

---

#### TC-P10: Student Score — NTA

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count cells showing "NTA" across all students × topics | nta_count matches |

---

#### TC-P11: Filter by Subject

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Compute AVG of all non-TNA/NTA scores | class_avg matches |

---

#### TC-P12: Filter by Assessment Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select different class-section | Entire matrix reloads for that class |

---

#### TC-P13: Filter by Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select different subject | Column topics change to selected subject's topics |

---

#### TC-P14: Filter by Lesson/Topic

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select topic_type filter | Only columns matching that type visible |

---

### 7.2 Negative TC Steps

#### TC-N01: No Class-Section Available

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Use scenario with no active class-sections | Empty report; stats all zeros |

---

#### TC-N02: No Data for Filtered Scope

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with no quiz/quest data | Matrix empty; stats 0 |

---

#### TC-N03: All TNA — No Attempts

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | All students have allocations but no attempts | All cells show "TNA"; tna_count = total_students × topics |

---

#### TC-N04: All NTA — No Allocations

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | No allocations for any student | All cells show "NTA"; nta_count > 0 |

---

#### TC-N05: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as user without `tenant.quiz-dashboard.view` | 403 Forbidden |

---

#### TC-N06: Student Limit Exceeded

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Class-section with 60+ students | Matrix shows exactly 50 students |

---

### 7.3 Dependency TC Steps

#### TC-D01: TNA Classification

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Quiz allocated → student not attempted | Cell shows "TNA" |

---

#### TC-D02: NTA Classification

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Quiz NOT allocated → student never attempted | Cell shows "NTA" |

---

#### TC-D03: Latest Attempt per Topic

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student has 2 attempts: 80% and 60% on same topic | Cell shows "80%" (highest score used) |

---

#### TC-D04: Lesson Resolution — Quest

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Quest with scopes → topic → lesson chain | Lesson name resolved correctly via $model->scopes[0]->topic->lesson |

---

#### TC-D05: Class Average Calculation

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Students with scores 80, 60, TNA | Class avg = 70 (TNA excluded from calculation) |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | Student limit hardcoded to 50 | Class-sections with >50 students have incomplete matrix | Observed |
| KI-02 | No explicit ghost rescue — attempts with deleted quiz/quest may be excluded | Matrix may miss data for deleted content | Observed |
| KI-03 | No upcoming/active/past quiz timeline classification | Matrix only shows attempted/not-attempted; no lifecycle state | Missing feature |
| KI-04 | No at-risk/top-performer segmentation | No separate sections for struggling or top students | Missing feature |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quiz-reports` (active_tab=current-class) | `quiz-reports.index` | `LmsQuizReportController@index` |
| GET | `/lms-quize/quiz-reports/filter-dependencies` | `quiz-reports.filter-dependencies` | `LmsQuizReportController@getDependencies` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 31 | 15 | 6 | 5 | 5 | 0 | 0 | 0 | 0 |
