# lms_quiz_teacher_monthly_report_TcList

## Module: LmsQuiz → Quiz Management → Reports → Teacher Monthly Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management → Reports (quiz-reports) |
| Feature | Teacher Monthly Report (tab: teacher-monthly) |
| URL(s) | `/lms-quize/quiz-reports` (active_tab=teacher-monthly, AJAX loads partial) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` → `generateTeacherMonthlyData()` |
| Model(s) | `Quiz`, `Quest`, `QuizAllocation`, `QuestAllocation`, `QuizQuestAttempt`, `User` (teacher), `StudentAcademicSession`, `ClassSection`, `Subject` |
| Validation | Filter parameters only |
| Permissions | `tenant.quiz-dashboard.view` (shared with entire report page) |
| Soft Deletes | N/A (no explicit ghost rescue) |
| Default Date Range | Current month (startOfMonth → endOfMonth) |
| Default Teacher | First teacher found (User whereHas employee.is_teacher) |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz-dashboard.view`
- Teacher selected (defaults to first teacher found)
- Defaults to current month date range
- Quiz/Quest activity exists for the selected teacher's allocations

---

## 3. Default Data Load

| Data | Source | Query | Filters |
|------|--------|-------|---------|
| Days Array | Generated from date_from → date_to | Each day: date, label (day number), day_name (Mon-Sun) | date_from, date_to |
| Quiz Allocations | `QuizAllocation::with('quiz.subject')->whereHas('quiz', $teacherFilter)` | Quiz created_by teacher OR allocation assigned_by teacher; class/subject/group; active; published_at/due_date overlaps range | teacher_id, class_id, subject_id, subject_group_id, section_id |
| Quest Allocations | `QuestAllocation::with('quest.subject')->whereHas('quest', $teacherFilter)` | Same scope for quests | Same |
| Attempts | `QuizQuestAttempt::with('quiz.subject','quest.subject','quiz.topic','quest.scopes.topic')` | `->whereIn('status',['SUBMITTED','TIMEOUT'])->whereBetween('submitted_at',[...])` scoped to teacher's students | teacher_id (via teacher's class-section student IDs), assessment_type, subject_id |
| Subject Data | Per-subject per-class-section matrix | assigned[], attempted[], average_score[] per day | Derived from allocations + attempts |

---

## 4. Test Data Strategy

- **Teacher Scope**: Test with different teachers to verify allocation scoping
- **Daily Matrix**: Verify correct per-day assigned/attempted/average_score for each subject and class-section
- **Date Range Boundary**: Test cross-month date ranges
- **Empty State**: Teacher with no allocated quizzes in date range
- **Both Types**: Test QUIZ and QUEST assessment types

---

## 5. Business Conditions

### 5.1 Database Schema

Reads from: `lms_quizzes`, `lms_quests`, `lms_quiz_allocations`, `lms_quest_allocations`, `lms_quiz_quest_attempts`, `sch_classes`, `sch_subjects`, `users` (teachers), `std_student_academic_sessions`

### 5.2 Validation Rules

| BC ID | Field | Rule | Notes |
|-------|-------|------|-------|
| BC-VAL-01 | teacher_id | nullable, integer | Auto-selects first teacher |
| BC-VAL-02 | assessment_type | nullable, string, in:QUIZ,QUEST,Bot | Defaults to QUIZ |
| BC-VAL-03 | class_id | nullable, integer | |
| BC-VAL-04 | section_id | nullable, integer | Maps to ClassSection IDs |
| BC-VAL-05 | subject_id | nullable, integer | |
| BC-VAL-06 | subject_group_id | nullable, integer | |
| BC-VAL-07 | date_from | nullable, date | Defaults to current month start |
| BC-VAL-08 | date_to | nullable, date | Defaults to current month end |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Behavior Without |
|-------|-----------|-----------------|
| BC-AUTH-01 | tenant.quiz-dashboard.view | 403 Forbidden |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Days array generated | Each day in range has date, label (day number), day_name |
| BC-BIZ-02 | Teacher allocation filter | Quiz allocated by teacher (created_by) or assigned by teacher (allocations.assigned_by) |
| BC-BIZ-03 | Allocation date overlap | Allocations with published_at/due_date overlapping the date range included |
| BC-BIZ-04 | Subject-class matrix | Per subject → per class-section → per day: assigned, attempted, average_score |
| BC-BIZ-05 | Assigned count | Number of students in class-section for that day |
| BC-BIZ-06 | Attempted count | Unique students from that class-section who attempted on that day |
| BC-BIZ-07 | Average score | Average percentage of attempted students from that class-section on that day |
| BC-BIZ-08 | Null days | Days with no assignment show null for all metrics |
| BC-BIZ-09 | Type categories | QUIZ → "Quiz - Homework"; QUEST → "Assessment" |
| BC-BIZ-10 | Both types | If assessment_type=Both, both QUIZ and QUEST sections shown |
| BC-BIZ-11 | No teacher selected | Auto-selects first teacher (User whereHas employee.is_teacher) |
| BC-BIZ-12 | Per-subject type label | Each type section has type_label and subjects array |
| BC-BIZ-13 | Cross-type average | `all_average` array computed per day across all subjects |
| BC-BIZ-14 | Section resolution | section_id maps to ClassSection IDs for allocation filtering |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | Notes |
|-------|-----------|------------------|-------|
| BC-REF-01 | quiz.created_by | users.id | Teacher relation |
| BC-REF-02 | allocation.assigned_by | users.id | Teacher assignment |
| BC-REF-03 | allocation.target_id | sch_class_sections.id | Via allocation_type SECTION |
| BC-REF-04 | allocation.quiz_id | lms_quizzes.id | |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | View Teacher Monthly Report | Day-by-day matrix with subject/class-section breakdown loaded | — | — | ⬜ |
| TC-P02 | Days Array Generated | All days from date_from to date_to with correct labels | — | — | ⬜ |
| TC-P03 | Subject Row — Assigned | Days with active allocation show assigned count (students in class-section) | — | — | ⬜ |
| TC-P04 | Subject Row — Attempted | Days with attempts show unique student count from that class-section | — | — | ⬜ |
| TC-P05 | Subject Row — Average Score | Days with attempts show average percentage for that class-section | — | — | ⬜ |
| TC-P06 | Null Days (Not Assigned) | Show null for assigned/attempted/average_score | — | — | ⬜ |
| TC-P07 | Multiple Subjects | Each subject shown as separate section with its class-section rows | — | — | ⬜ |
| TC-P08 | Multiple Class-Sections | Subject shows class-section breakdown | — | — | ⬜ |
| TC-P09 | Type — QUIZ | Shows "Quiz - Homework" section with subject data | — | — | ⬜ |
| TC-P10 | Type — QUEST | Shows "Assessment" section with subject data | — | — | ⬜ |
| TC-P11 | Filter by Assessment Type | Only QUIZ or QUEST shown | — | — | ⬜ |
| TC-P12 | Filter by Teacher | Only allocations for selected teacher shown | — | — | ⬜ |
| TC-P13 | Filter by Class | Only quizzes for selected class shown | — | — | ⬜ |
| TC-P14 | Filter by Subject | Only data for selected subject shown | — | — | ⬜ |
| TC-P15 | Filter by Date Range | Only days within range shown in matrix | — | — | ⬜ |
| TC-P16 | Filter by Section | Allocations scoped to section via ClassSection mapping | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Teacher Selected | Auto-selects first teacher found | — | — | ⬜ |
| TC-N02 | Teacher Has No Allocations | Returns empty subjects array; empty report | — | — | ⬜ |
| TC-N03 | No Activity in Date Range | All assigned=null, attempted=null, average_score=null for all days | — | — | ⬜ |
| TC-N04 | Invalid Teacher ID | Falls back to first teacher | — | — | ⬜ |
| TC-N05 | View Without Permission | 403 Forbidden | — | — | ⬜ |
| TC-N06 | No Teachers Exist | Default teacher auto-select fails; empty data returned | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Daily Assignment Flag | P1 | Allocation published_at=Jan 1, due_date=Jan 10 → days Jan 1-10 assigned, Jan 11+ null | Correct assigned/attempted/average per day | — | — | ⬜ |
| TC-D02 | B | Attempt Scoping — Teacher's Students | P1 | Student not in teacher's class-section attempts → not counted | Count only students belonging to teacher's class-sections via ClassSection → StudentAcademicSession | — | — | ⬜ |
| TC-D03 | C | Student Count Accuracy | P1 | Class-section has 25 students → assigned = 25 for active days | Assigned count matches StudentAcademicSession count | — | — | ⬜ |
| TC-D04 | D | Average Score Accuracy | P1 | 3 students score 80, 90, 100 on same day → average = 90 | Average_score = 90.00 | — | — | ⬜ |
| TC-D05 | E | Allocation Filter — created_by vs assigned_by | P1 | Teacher created quiz but didn't assign it → included; teacher assigned allocation but didn't create quiz → included | Both types of teacher ownership included | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — generateTeacherMonthlyData — teacher auto-select | Uses `User::whereHas('employee', fn($q)=>$q->where('is_teacher', true))->first()` | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — generateTeacherMonthlyData — teacher allocation filter | Quiz query: `where('created_by', $teacherId)->orWhereHas('allocations', fn($q)=>$q->where('assigned_by', $teacherId))` | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — generateTeacherMonthlyData — student scoping | Pre-fetches `StudentAcademicSession` for teacher's target class-sections; scopes attempts to those student IDs | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — generateTeacherMonthlyData — date range overlap | Allocation query: `whereBetween('published_at', [$from,$to]) OR whereBetween('due_date', [$from,$to]) OR (published_at <= $from AND due_date >= $to)` | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — generateTeacherMonthlyData — daily matrix computation | For each day: checks allocation date range overlap → assigned; counts unique students from class-section → attempted; avg of scores → average_score | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — generateTeacherMonthlyData — all_average | Computed per day as average of all class-section average_scores | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Matrix Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz Reports → Teacher Monthly tab | Page loads with teacher-monthly tab active |
| 2 | Check filter bar | Class Section, Subject, Subject Group, Teacher dropdown, Date Range visible |
| 3 | Check matrix header | Columns = subject names for teacher's allocations; Last column = All Subjects Average |
| 4 | Check matrix rows | Rows = dates within range; each cell = assigned_count, attempted_count, average_score or null |
| 5 | Verify AJAX loading | Matrix refreshes on filter change without full page reload |

#### TC-P02: Days Array Generated

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section | Matrix scoped to teacher's class-sections |

---

#### TC-P03: Subject Row — Assigned

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select teacher with known data | All assignments/attempts for that teacher's students shown |

---

#### TC-P04: Subject Row — Attempted

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with active allocation | assigned_count = number of students in class-section |

---

#### TC-P05: Subject Row — Average Score

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with submitted attempts | attempted_count = unique students who submitted; average_score computed |

---

#### TC-P06: Null Days (Not Assigned)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with allocation but no attempts | assigned_count > 0; attempted_count = 0; average_score = null |

---

#### TC-P07: Multiple Subjects

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Day with no allocation | assigned_count = null; attempted_count = null; average_score = null |

---

#### TC-P08: Multiple Class-Sections

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Teacher created quiz but didn't assign | Quiz included in subject columns |

---

#### TC-P09: Type — QUIZ

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Teacher assigned allocation but didn't create quiz | Allocation included in subject columns |

---

#### TC-P10: Type — QUEST

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify assigned_count per day | Matches DB StudentAcademicSession count for teacher's class-sections on that date |

---

#### TC-P11: Filter by Assessment Type

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify attempted_count per day | Matches unique students with submitted attempt in date range |

---

#### TC-P12: Filter by Teacher

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify average_score per day | Average of all attempt scores for that day |

---

#### TC-P13: Filter by Class

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Verify All Subjects Average | Average of all class-section averages for that day |

---

#### TC-P14: Filter by Subject

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select subject filter | Only columns for selected subject visible |

---

#### TC-P15: Filter by Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date range | Only days within range shown |

---

#### TC-P16: Filter by Section

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select section | Allocations scoped to that section via ClassSection mapping |

### 7.2 Negative TC Steps

#### TC-N01: No Teacher Selected

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | No teacher selected | Auto-selects first teacher found |

---

#### TC-N02: Teacher Has No Allocations

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Teacher has no allocations | Empty subjects array; empty report |

---

#### TC-N03: No Activity in Date Range

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | No activity in date range | All assigned=null, attempted=null, average_score=null |

---

#### TC-N04: Invalid Teacher ID

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Pass invalid teacher_id | Falls back to first teacher |

---

#### TC-N05: View Without Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | User without `tenant.quiz-dashboard.view` | 403 Forbidden |

---

#### TC-N06: No Teachers Exist

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | No teachers exist | Default teacher auto-select fails; empty data returned |

### 7.3 Dependency TC Steps

#### TC-D01: Daily Assignment Flag

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Allocation published_at=Jan 1, due_date=Jan 10 | Jan 1-10 assigned; Jan 11+ null |

---

#### TC-D02: Attempt Scoping — Teacher's Students

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Student outside teacher's class-section attempts | That attempt NOT counted in teacher's metrics |

---

#### TC-D03: Student Count Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Class-section has 25 students | assigned = 25 for active days |

---

#### TC-D04: Average Score Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | 3 students score 80, 90, 100 on same day | average_score = 90.00 |

---

#### TC-D05: Allocation Filter — created_by vs assigned_by

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Teacher created quiz (created_by) + assigned allocation (assigned_by) | Both types of ownership included |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | No overview card (total quizzes, attempts, avg score, completion rate) | Only daily matrix shown; no aggregated teacher summary metrics | Missing feature |
| KI-02 | No weekly breakdown section | Data shown day-by-day, not grouped into weeks | Confirmed (by design) |
| KI-03 | No top/bottom 5 students list | No per-student ranking within report | Missing feature |
| KI-04 | Null days (no assignment) may be confusing | Days with no assignment show null values instead of 0 | Observed |
| KI-05 | Ghost rescue for deleted quizzes/quests not implemented | Deleted quiz/quest may cause missing data in report | Observed |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quiz-reports` (active_tab=teacher-monthly) | `quiz-reports.index` | `LmsQuizReportController@index` |
| GET | `/lms-quize/quiz-reports/filter-dependencies` | `quiz-reports.filter-dependencies` | `LmsQuizReportController@getDependencies` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 33 | 16 | 6 | 5 | 6 | 0 | 0 | 0 | 0 |
