# Quiz Dashboard — Business Requirements

## What This Screen Does

The Quiz Dashboard is the first page users see when they open Quiz Management. It's like a car's dashboard — it shows everything at a glance: how many quizzes exist, how many are published, how many students have attempted them, what scores they're getting, and how activity has changed over the last 6 months.

The dashboard displays key performance indicators (KPIs), trend charts, and a quick-access list of recent quizzes. No data entry happens here — it's purely for monitoring and analysis.

---

## When This Screen Is Used

- **Daily Monitoring** — Academic coordinators check quiz creation and attempt volumes
- **Performance Review** — HODs evaluate class-level quiz engagement and score distribution
- **Gap Analysis** — Teachers see which subjects have active quizzes and which need more
- **Planning** — Identify coverage gaps across subjects and classes

## Default Data Load

The Dashboard loads when the user navigates to Quiz Management with `active_tab=quiz-dashboard`. All data is computed fresh on each page load via `LmsQuizController@index()` — NO caching.

**Filter bar at top:**
- Class-Section dropdown (cascades from active classes/sections)
- Subject dropdown (filtered by selected class-section)
- Quiz Status filter (DRAFT/PUBLISHED/ARCHIVED)
- Date Range filter

---

## Dashboard Components (Non-Technical)

### Filter Section
Users select a Class-Section → system loads available Subjects → select Subject → all dashboard widgets update to show data scoped to that selection.

### Stat Cards (7 KPIs)
Each card shows a key number:

| Card | What It Shows | Source Table |
|------|--------------|-------------|
| **Total Quizzes** | All quizzes matching filters | `lms_quizzes` |
| **Published Quizzes** | Quizzes with status=PUBLISHED | `lms_quizzes` |
| **Total Questions** | Count of all quiz-question links | `lms_quiz_questions` |
| **Total Allocations** | Count of all quiz allocations | `lms_quiz_allocations` |
| **Total Attempts** | All student quiz attempts | `lms_quiz_quest_attempts` |
| **In Progress** | Attempts currently being taken | `lms_quiz_quest_attempts` (status=IN_PROGRESS) |
| **Submitted** | Completed attempts | `lms_quiz_quest_attempts` (status=SUBMITTED/TIMEOUT) |
| **Average Score** | Mean percentage across all quiz results | `lms_quiz_quest_results` |

### Charts Section

**Score Distribution (Bar Chart)**
Shows how many students scored in each band: 0-20%, 21-40%, 41-60%, 61-80%, 81-100%. Helps teachers quickly see if most students are struggling (left-heavy) or excelling (right-heavy).

**Monthly Activity (Line/Bar Chart)**
Dual dataset: quizzes created per month AND allocations made per month for the last 6 calendar months. Shows trend — are more quizzes being created? Are more allocations happening?

**Subject Breakdown (Horizontal Bar)**
Top 6 subjects by quiz count. Each bar shows: quiz count, total questions across those quizzes, and average marks per quiz. Helps identify which subjects have the most/least assessment coverage.

**Status Breakdown (Pie/Donut)**
DRAFT vs PUBLISHED vs ARCHIVED — how many quizzes are in each state.

### Recent Quizzes
Table of the 8 most recently created quizzes. Each row shows: title, class, subject, question count, total allocations, total attempts, submitted count. Quick action links to View, Add Questions, Allocate.

---

## How Each Metric is Computed (Plain Language)

When the Dashboard loads, the system runs multiple calculations to fill all the cards and charts. Here's exactly how each number is determined.

### How Filters Affect Everything
- If a **Class-Section** is selected: All numbers are scoped to that class only
- If a **Subject** is also selected: Double-scoped — only that subject within that class
- If no filter is selected: Numbers show **across all classes and subjects** (school-wide)
- **Date Range** only affects: Attempts, Submissions, and Allocations — NOT total quiz count

### Stat Cards — What Each Number Represents

| Card | How It's Calculated | What It Excludes |
|------|-------------------|-----------------|
| **Total Quizzes** | Count every quiz matching the class + subject + status + date filters | Nothing — counts all matching |
| **Published Quizzes** | Same as Total Quizzes but only where status = PUBLISHED | Drafts and archived |
| **Total Questions** | Count every question-link across all matching quizzes | Questions from non-matching quizzes |
| **Total Allocations** | Count every allocation for matching quizzes within the date range | Allocations outside date range |
| **Total Attempts** | Count every student attempt on matching quizzes within date range | Quest attempts (this is QUIZ only) |
| **In Progress** | Same as Total Attempts but where status = IN_PROGRESS | Submitted/timeout attempts |
| **Submitted** | Same as Total Attempts but where status = SUBMITTED or TIMEOUT | In-progress attempts |
| **Average Score** | Average of ALL result percentages across matching quizzes | Students with no result record |

### Score Distribution (Bar Chart)
The system sorts every submitted attempt into one of five buckets:
- **0-20%** — Struggling (5 students)
- **21-40%** — Needs attention (10 students)
- **41-60%** — Satisfactory (20 students)
- **61-80%** — Good (35 students)
- **81-100%** — Outstanding (15 students)

The chart shows how many students fall into each bucket. If the bar chart is heavy on the left (0-40%), the class is struggling. Heavy on the right (61-100%), they're doing well.

### Monthly Activity (Line Chart)
Two lines shown side by side for the last 6 calendar months:
1. **Quizzes Created** — How many quizzes were added each month
2. **Allocations Made** — How many quizzes were assigned each month

If a month has zero activity, it still shows (as 0) — the chart always shows 6 months.

### Subject Breakdown (Horizontal Bar)
The system finds the top 6 subjects with the most quizzes and shows for each:
- **Quiz Count** — How many quizzes in this subject
- **Total Questions** — Sum of all questions across those quizzes
- **Average Marks** — Average total marks per quiz in this subject

### Status Breakdown (Pie Chart)
Three simple counts: How many quizzes are in each status:
- **DRAFT** — Not yet published
- **PUBLISHED** — Live and available
- **ARCHIVED** — Deactivated or historical

### Recent Quizzes (Table)
The 8 most recently created quizzes, showing: title, class, subject, question count, allocation count, attempt count, submitted count. Each row has quick links to common actions.

---

## Business Rules Summary

| # | Rule | Details |
|---|------|---------|
| 1 | All metrics filtered by class_id + subject_id | When class selected, subjects cascade via SubjectGroup |
| 2 | No caching — fresh compute every page load | 15+ separate queries, potential performance hit with large datasets |
| 3 | Score distribution uses fixed 20% bins | 0-20, 21-40, 41-60, 61-80, 81-100 |
| 4 | Monthly activity = last 6 calendar months | Jan-Jun or Jul-Dec — empty months = 0 |
| 5 | Subject breakdown = top 6 | Ordered by quiz count descending |
| 6 | Recent quizzes = last 8 | Ordered by created_at descending |
| 7 | Date range affects attempts/submitted/avg_score only | Total quizzes and published are unaffected by date |

---

## Workflow Steps (Non-Technical)

1. User opens Quiz Management → Dashboard tab loads by default
2. All stat cards show numbers (for all classes/subjects if no filter selected)
3. All charts render with data
4. User optionally selects:
   - **Class-Section** → Subject dropdown populates (only subjects available for that class+section appear)
   - **Subject** → all widgets update to show only that subject's data
   - **Status** → filter by quiz status
   - **Date Range** → filter by date
5. User clicks "Apply Filters" → page reloads with filtered data
6. User scrolls to Recent Quizzes table → clicks any quiz to navigate

---

## Example Scenarios (Non-Technical)

**SC-001 — Dashboard Loads Normally (Non-Technical)**
Ravi opens Quiz Management. The Dashboard shows:
- Total Quizzes: 25, Published: 18, Questions: 450
- Total Allocations: 12, Attempts: 340, In Progress: 15, Submitted: 300, Avg Score: 72%
- Score Distribution: Most students in 61-80% bin (good)
- Monthly Activity: 5 quizzes created this month (up from 2 last month)
- Subject Breakdown: Math (6 quizzes), Science (4), English (3)
- Status Breakdown: 18 PUBLISHED, 5 DRAFT, 2 ARCHIVED
- Recent Quizzes: Show 8 most recent quiz titles

**SC-002 — Filter by Class + Subject (Non-Technical)**
Ravi selects "Grade 10-A" from Class-Section dropdown → Subject dropdown shows "Science", "Math", "English". He selects "Science" and clicks Apply. All cards now show only Grade 10-A Science data:
- 3 quizzes, 2 published, 60 questions, 2 allocations
- 42 attempts, avg score 68%

**SC-003 — Empty State for New Session (Non-Technical)**
At the start of a new academic year with no quizzes yet. Dashboard shows all zeros:
- 0 quizzes, 0 published, 0 questions, 0 allocations, 0 attempts
- All charts show empty state with "No data available"
- Recent Quizzes shows "No quizzes found"

**SC-004 — Score Distribution Analysis (Non-Technical)**
Ravi sees the score distribution chart:
- 0-20%: 5 students (struggling)
- 21-40%: 10 students (need attention)
- 41-60%: 20 students (satisfactory)
- 61-80%: 35 students (good)
- 81-100%: 15 students (outstanding)
This tells Ravi that most students (50) are performing well (above 60%), but 15 students need intervention.

---

## Performance Note

The Dashboard executes 15+ separate database queries on every page load. With very large datasets (>10,000 quizzes, >100,000 attempts), page load may exceed 10 seconds. There is NO caching mechanism.

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizController@index()` (tab: `quiz-dashboard`)
**View:** `lmsquiz::dashboard.index` (included via `tab_module.tab`)
**Policy:** `tenant.quiz-dashboard.view`

**Data computed in `index()`:**
| Variable | Type | Description |
|----------|------|-------------|
| `$quizDashboardStats` | array | 11 metrics: total_quizzes, published_quizzes, total_questions, total_allocations, total_attempts, in_progress_attempts, submitted_attempts, avg_score, score_distribution, monthly_activity, monthly_allocations, subject_breakdown, status_breakdown |
| `$recentQuizzes` | Collection | Latest 8 quizzes with withCount (questions, allocations, attempts) |
| `$quizDashboardSubjectList` | Collection | Cascaded subjects from ClassSection → SubjectGroup chain |
| `$dashClassId` | int/null | Resolved class_id from class_section_id filter |

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_quizzes` | Primary | Quiz master — stat card, monthly activity, subject breakdown, status breakdown, recent |
| `lms_quiz_questions` | Junction | Total Questions count |
| `lms_quiz_allocations` | Related | Total Allocations, monthly allocations chart |
| `lms_quiz_quest_attempts` | StudentPortal | Total/InProgress/Submitted attempts |
| `lms_quiz_quest_results` | StudentPortal | Avg score, score distribution bins |
| `sch_classes` / `sch_class_sections` | SchoolSetup | Class-section filter dropdown |
| `sch_subject_groups` / `sch_subject_group_subjects_jnt` | SchoolSetup | Subject cascade |
| `lms_attempt_activity_event_types` | StudentPortal | Required for Activity Log tab (dependency) |
