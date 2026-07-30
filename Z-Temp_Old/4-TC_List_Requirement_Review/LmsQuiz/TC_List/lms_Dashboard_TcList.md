# lms_quiz_dashboard_TcList

## Module: LmsQuiz → Quiz Management → Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsQuiz |
| Tab Group | Quiz Management |
| Feature | Dashboard (quiz-dashboard tab) |
| URL(s) | `/lms-quize/quize` (index via tab, active_tab=quiz-dashboard) |
| Controller | `Modules\LmsQuiz\Http\Controllers\LmsQuizController@index()` (inline stats computation within tab view) |
| Model(s) | `Quiz`, `QuizQuestion`, `QuizAllocation`, `QuizQuestAttempt` (StudentPortal), `QuizQuestResult` (StudentPortal) |
| Validation | None (read-only dashboard — filter parameters only) |
| Permissions | `tenant.quiz.viewAny` (shared with entire Quiz Management index page — no separate dashboard permission) |
| Soft Deletes | N/A (dashboard is read-only, reads data from soft-deletable models; respects `is_active` filters) |
| Activity Log | N/A (dashboard is read-only) |
| Import | Not supported |

---

## 2. Pre-conditions

- Required permission: `tenant.quiz.viewAny` (shared with entire tab view)
- Required seed data: At least one Quiz, one QuizAllocation, one QuizQuestAttempt, one QuizQuestResult
- Test user must have `tenant.quiz.viewAny` permission (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the Dashboard tab loads via LmsQuizController@index() (GET /lms-quize/quize, active_tab=quiz-dashboard), the following data is computed via inline queries:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Total Quizzes | `Quiz::query()` | `->count()` | class_id (via class_section_id), subject_id, quiz_status, created_at date range | None |
| Published Quizzes | `Quiz::query()` | `->where('status','PUBLISHED')->count()` | class_id, subject_id | None |
| Total Questions | `QuizQuestion::whereHas('quiz')` | `->count()` | class_id, subject_id | None |
| Total Allocations | `QuizAllocation::whereHas('quiz')` | `->count()` | class_id, subject_id, published_at date range | None |
| Total Attempts | `QuizQuestAttempt::where('assessment_type','QUIZ')->whereHas('quiz')` | `->count()` | class_id, subject_id, created_at date range | None |
| In Progress Attempts | `QuizQuestAttempt::where('status','IN_PROGRESS')` | `->count()` | class_id, subject_id | None |
| Submitted Attempts | `QuizQuestAttempt::whereIn('status',['SUBMITTED','TIMEOUT'])` | `->count()` | class_id, subject_id, submitted_at date range | None |
| Average Score | `QuizQuestResult::where('assessment_type','QUIZ')->whereHas('quiz')` | `->avg('percentage')` | class_id, subject_id | None |
| Score Distribution | `QuizQuestResult::selectRaw(CASE/SUM)` | 5 bins: 0-20, 21-40, 41-60, 61-80, 81-100 | class_id, subject_id | None |
| Monthly Activity (Quizzes) | `Quiz::selectRaw("DATE_FORMAT(created_at,'%b %Y') as month")` | Grouped by month, last 6 months | class_id, subject_id | None |
| Monthly Activity (Allocations) | `QuizAllocation::selectRaw(...)` | Grouped by month, last 6 months | class_id, subject_id | None |
| Subject Breakdown | `Quiz::select('subject_id')->groupBy()` | Top 6 with quiz_count, total_q_sum, avg_marks | class_id, subject_id | Limit 6 |
| Status Breakdown | `Quiz::groupBy('status')` | 3 counts: DRAFT, PUBLISHED, ARCHIVED | class_id, subject_id | None |
| Recent Quizzes | `Quiz::with('class','subject')->withCount(questions,allocations,attempts)` | `->latest()->limit(8)` | class_id, subject_id | Limit 8 |

---

## 4. Test Data Strategy

- **Unique data**: Dashboard is read-only — uses existing data
- **Pre-test setup**: Create known datasets with specific counts/ranges
- **Date range**: Test with data both inside and outside filter date range
- **Class-section cascade**: Test with and without class-section filter; class_id derived from class_section_id
- **Performance note**: Dashboard executes 15+ separate queries; test with large datasets (>10K quizzes, >100K attempts) for performance
- **Empty state**: Test at start of academic year with no data

---

## 5. Business Conditions

### 5.1 Database Schema — Read-Only Sources

| BC ID | Table | Columns Referenced | Notes |
|-------|-------|--------------------|-------|
| BC-DB-01 | lms_quizzes | id, class_id, subject_id, status, total_questions, total_marks, created_at, is_active, deleted_at | Main quiz master |
| BC-DB-02 | lms_quiz_questions | id, quiz_id | Count only |
| BC-DB-03 | lms_quiz_allocations | id, quiz_id, published_at, created_at | Count + monthly trend |
| BC-DB-04 | lms_quiz_quest_attempts | id, quiz_id, student_id, status, assessment_type, submitted_at, created_at | StudentPortal module |
| BC-DB-05 | lms_quiz_quest_results | id, attempt_id, percentage, assessment_type | StudentPortal module |

### 5.2 Validation Rules

N/A — Dashboard has no validation; filter parameters are used with `when($request->filled(...))` guards. Invalid filters are silently ignored and no scope is applied.

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.quiz.viewAny | index() (entire method) | Without → 403 Forbidden (no separate dashboard permission) |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | No class-section filter | All metrics are school-wide (no class/subject filter) |
| BC-BIZ-02 | Class-section selected without subject | Metrics scoped to class_id derived from class_section_id |
| BC-BIZ-03 | Class-section + Subject both selected | Double-scoped: class_id + subject_id |
| BC-BIZ-04 | Date range filter set (date_from/date_to) | Attempts, allocations, quiz creation counts scoped by date |
| BC-BIZ-05 | Score distribution calculation | SUM with CASE for 5 fixed bins from QuizQuestResult.percentage |
| BC-BIZ-06 | Monthly activity — last 6 months | 6 calendar months always shown; empty months display as zero |
| BC-BIZ-07 | Subject breakdown — top 6 | Ordered by quiz_count descending, limited to 6 |
| BC-BIZ-08 | Recent quizzes — last 8 | Ordered by created_at descending, limited to 8 |
| BC-BIZ-09 | All metrics computed fresh | No caching — 15+ separate queries per page load |
| BC-BIZ-10 | Class-section to class_id mapping | class_id derived from `ClassSection::find($request->class_section_id)?->class_id` |
| BC-BIZ-11 | Subject cascade via SubjectGroup | Subjects loaded via SubjectGroup → SubjectGroupSubject → Subject chain for selected class |
| BC-BIZ-12 | No quiz data exists | All cards show 0; charts show empty labels; recent quizzes shows "No quizzes found" |
| BC-BIZ-13 | Avg score returns null | Rounded to 0.0 when no results exist |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | class_id (lms_quizzes) | sch_classes (id) | CASCADE |
| BC-REF-02 | subject_id (lms_quizzes) | sch_subjects (id) | CASCADE |
| BC-REF-03 | quiz_id (lms_quiz_questions) | lms_quizzes (id) | CASCADE |
| BC-REF-04 | quiz_id (lms_quiz_allocations) | lms_quizzes (id) | CASCADE |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Dashboard Loads With All UI Elements | All 9 stat cards rendered (total/published quizzes, questions, allocations, attempts, in-progress, submitted, avg score, score dist), 4 charts, recent quizzes table, filter bar | — | — | ⬜ |
| TC-P02 | Total Quizzes Count Matches DB | Count matches actual Quiz count for current filter scope | — | — | ⬜ |
| TC-P03 | Published Quizzes Count Correct | Count matches Quiz where status=PUBLISHED | — | — | ⬜ |
| TC-P04 | Total Questions Count Correct | Count matches QuizQuestion for quizzes in scope | — | — | ⬜ |
| TC-P05 | Total Allocations Count Correct | Count matches QuizAllocation for quizzes in scope | — | — | ⬜ |
| TC-P06 | Total Attempts Count Correct | Count matches QuizQuestAttempt where assessment_type=QUIZ | — | — | ⬜ |
| TC-P07 | In Progress Count Correct | Count matches attempts with status=IN_PROGRESS | — | — | ⬜ |
| TC-P08 | Submitted Count Correct | Count matches attempts with status=SUBMITTED or TIMEOUT | — | — | ⬜ |
| TC-P09 | Average Score Card Correct | Avg percentage matches QuizQuestResult.percentage avg | — | — | ⬜ |
| TC-P10 | Score Distribution Shows 5 Bins | Chart shows 0-20, 21-40, 41-60, 61-80, 81-100 with correct counts | — | — | ⬜ |
| TC-P11 | Monthly Activity Shows 6 Months | Charts show exactly 6 bars (last 6 calendar months); empty months show 0 | — | — | ⬜ |
| TC-P12 | Subject Breakdown Shows Top 6 | Chart shows max 6 subjects ordered by quiz count descending | — | — | ⬜ |
| TC-P13 | Status Breakdown Shows 3 Statuses | Pie/donut shows DRAFT, PUBLISHED, ARCHIVED counts | — | — | ⬜ |
| TC-P14 | Recent Quizzes Shows Last 8 | Table shows max 8 most recently created quizzes with title, class, subject, counts | — | — | ⬜ |
| TC-P15 | Filter by Class-Section | All cards update to show data scoped to selected class | — | — | ⬜ |
| TC-P16 | Filter by Class-Section + Subject | All cards update to show data scoped to class + subject | — | — | ⬜ |
| TC-P17 | Filter by Quiz Status | Quiz count updates to match selected status filter | — | — | ⬜ |
| TC-P18 | Filter by Date Range | Attempts, allocations, and related metrics update; total quiz count unaffected by date (only by class/subject) | — | — | ⬜ |
| TC-P19 | Subject Dropdown Cascades After Class Selection | Selecting a class-section populates subject dropdown with only subjects for that class | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No Permission — 403 | User without `tenant.quiz.viewAny` gets 403 for the entire page | — | — | ⬜ |
| TC-N02 | Invalid Class-Section ID | Filter silently ignored; no class_id scope applied | — | — | ⬜ |
| TC-N03 | Invalid Subject ID | Subject filter silently ignored; shows all subjects | — | — | ⬜ |
| TC-N04 | Invalid Status Value | Status filter silently ignored; shows all statuses | — | — | ⬜ |
| TC-N05 | Only Future Dates — No Data | All attempt-related cards show 0; quiz counts still show if quizzes exist | — | — | ⬜ |
| TC-N06 | Empty State — No Quizzes Exist | All cards show 0; charts show empty labels; recent quizzes shows empty | — | — | ⬜ |
| TC-N07 | Empty State — No Attempts Exist | Attempts/InProgress/Submitted show 0; avg score shows 0.0; quiz/alloc counts still show | — | — | ⬜ |
| TC-N08 | Guest Access Redirect | Redirected to /login for /lms-quize/quize route | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | UI | P1 | Dashboard — stat cards — filter cascade | class_id filter changes quiz count; subject_id further narrows | — | — | ⬜ |
| TC-D02 | B | UI | P1 | Dashboard — score distribution — five fixed bins | Bins 0-20/21-40/41-60/61-80/81-100; SUM matches total results count | — | — | ⬜ |
| TC-D03 | C | UI | P1 | Dashboard — monthly activity — last 6 months — empty months | Exactly 6 bars; months with 0 activity show 0 | — | — | ⬜ |
| TC-D04 | D | UI | P1 | Dashboard — subject breakdown — top 6 — ordering | Ordered by quiz_count DESC; max 6 subjects shown | — | — | ⬜ |
| TC-D05 | E | UI | P1 | Dashboard — recent quizzes — last 8 — ordering | Ordered by created_at DESC; max 8 quizzes shown | — | — | ⬜ |
| TC-D06 | F | UI | P1 | Dashboard — filter cascade — no filter selected | School-wide scope; includes all quizzes regardless of status | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|----------------|---------|---------|--------|
| TC-CR01 | CR | Code Review | P1 | Controller — index — permission gate check | `Gate::authorize('tenant.quiz.viewAny')` called at top before any data computation | — | — | ◌ |
| TC-CR02 | CR | Code Review | P1 | Controller — index — filter null safety | All filter parameters checked with `$request->filled()` or `when()` before use | — | — | ◌ |
| TC-CR03 | CR | Code Review | P1 | Controller — index — class_id from class_section_id | Uses `ClassSection::find($request->class_section_id)?->class_id` | — | — | ◌ |
| TC-CR04 | CR | Code Review | P1 | Controller — index — score distribution CASE/SUM | Uses `SUM(CASE WHEN percentage <= 20 THEN 1 ELSE 0 END)` pattern for 5 bins | — | — | ◌ |
| TC-CR05 | CR | Code Review | P1 | Controller — index — monthly activity last 6 months | Uses `for ($i = 5; $i >= 0; $i--)` loop, `DATE_FORMAT(created_at, '%b %Y')` grouping | — | — | ◌ |
| TC-CR06 | CR | Code Review | P1 | Controller — index — subject breakdown limit | Uses `->groupBy('subject_id')->orderByDesc('quiz_count')->limit(6)` | — | — | ◌ |
| TC-CR07 | CR | Code Review | P1 | Controller — index — recent quizzes limit | Uses `->latest()->limit(8)` with `withCount(...)` for question/alloc/attempt counts | — | — | ◌ |
| TC-CR08 | CR | Code Review | P1 | Controller — index — avg_score closure | Uses IIFE closure `(function () use (...) { ... })()` pattern for `$quizDashboardStats` | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Dashboard Loads With All UI Elements

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin, navigate to LmsQuiz → Dashboard tab | Page loads with quiz-dashboard tab active |
| 2 | Check stat cards (row 1) | Total Quizzes, Published Quizzes, Total Questions, Total Allocations visible |
| 3 | Check stat cards (row 2) | Total Attempts, In Progress, Submitted, Avg Score visible |
| 4 | Check charts | Score Distribution (bar), Monthly Activity (line), Subject Breakdown (bar), Status Breakdown (pie) visible |
| 5 | Check Recent Quizzes table | 8 most recent quizzes with title, class, subject, counts |
| 6 | Check filter bar | Class Section dropdown, Subject dropdown (cascaded), Status filter, Date Range visible |

#### TC-P02: Total Quizzes Count Matches DB

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run DB query: `SELECT COUNT(*) FROM lms_quizzes` | Count = X |
| 2 | Check Total Quizzes card | Shows X |

---

#### TC-P03: Published Quizzes Count Correct

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run DB query: `SELECT COUNT(*) FROM lms_quizzes WHERE status='PUBLISHED'` | Count = Y |
| 2 | Check Published Quizzes card | Shows Y |

---

#### TC-P04: Total Questions Count Correct

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run DB query: `SELECT COUNT(*) FROM lms_quiz_questions qq JOIN lms_quizzes q ON qq.quiz_id=q.id` | Count = Z |
| 2 | Check Total Questions card | Shows Z |

---

#### TC-P05: Total Allocations Count Correct

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count allocations via DB | Count = A |
| 2 | Check Total Allocations card | Shows A |

---

#### TC-P06: Total Attempts Count Correct

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Count attempts where assessment_type='QUIZ' | Count = B |
| 2 | Check Total Attempts card | Shows B |

---

#### TC-P09: Average Score Card Correct

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run DB: `SELECT AVG(percentage) FROM lms_quiz_quest_results WHERE assessment_type='QUIZ'` | Avg = C |
| 2 | Check Avg Score card | Shows C |

---

#### TC-P10: Score Distribution

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run DB query with CASE/SUM for 5 bins | Known bin counts |
| 2 | Check chart bins | 0-20, 21-40, 41-60, 61-80, 81-100 match DB counts |

#### TC-P11: Monthly Activity

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check monthly activity chart | Exactly 6 bars for last 6 months |
| 2 | Verify empty months show 0 | Months with no quizzes show 0 |

#### TC-P14: Recent Quizzes

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Run DB: `SELECT * FROM lms_quizzes ORDER BY created_at DESC LIMIT 8` | Know last 8 |
| 2 | Check Recent Quizzes table | Shows same 8 quizzes in same order |

#### TC-P15: Filter by Class-Section

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a class-section from dropdown | Subject dropdown populates |
| 2 | Check all stat cards | Values scoped to selected class_id |
| 3 | Check charts and recent quizzes | All scoped to class |

### 7.2 Negative TC Steps

#### TC-N01: No Permission

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as user without `tenant.quiz.viewAny` | User authenticated |
| 2 | Navigate to LmsQuiz module | 403 Forbidden |

#### TC-N06: Empty State — No Quizzes

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure no quizzes exist | Truncate or fresh tenant |
| 2 | Navigate to Dashboard | All cards show 0; charts show empty labels |

### 7.3 Dependency TC Steps

#### TC-D01: Filter Cascade

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select class-section with known quiz count X | Total Quizzes = X |
| 2 | Also select subject | Total Quizzes further narrows |

#### TC-D02: Date Range Filter

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set date_from = 30 days ago, date_to = today | Default range |
| 2 | Change to future-only range | Attempt cards show 0; quiz count unchanged |

---

## 8. Known Issues

| KI ID | Issue | Impact | Status |
|-------|-------|--------|--------|
| KI-01 | 15+ separate queries per page load | Performance issue with large datasets; no caching | Observed |
| KI-02 | No separate dashboard permission — shares `tenant.quiz.viewAny` | Any user with quiz list access sees dashboard | Confirmed (by design) |
| KI-03 | Published quizzes count does NOT filter by date range | Published count shown unfiltered even when date filter is applied | Observed |
| KI-04 | In Progress count ignores date range filter | Always counts all IN_PROGRESS regardless of date filter | Observed |
| KI-05 | No pass rate metric | Pass rate is not computed; only avg_score shown | Missing feature |

---

## 9. Route References

| Method | URL | Name | Controller |
|--------|-----|------|------------|
| GET | `/lms-quize/quize` (active_tab=quiz-dashboard) | `lms-quize.quize.index` | `LmsQuizController@index` |

---

## 10. Execution Status

| Total TCs | Positive | Negative | Dependency | Code Review | Executed | Passed | Failed | Blocked |
|-----------|----------|----------|------------|-------------|----------|--------|--------|---------|
| 41 | 19 | 8 | 6 | 8 | 0 | 0 | 0 | 0 |
