# Quest Dashboard — Business Requirements

## What This Screen Does

The Quest Dashboard is the main landing page for the Quests module. It gives teachers and academic administrators a bird's-eye view of everything happening with Quests across the school. Think of it like a car dashboard: you see key metrics (total quests, questions, allocations, submissions), visual charts (monthly activity, score distribution), and a list of the most recently created Quests.

This screen is part of a larger tabbed interface. The tabs along the top let teachers switch between:
- **Dashboard** (KPI metrics and charts)
- **Quest List** (manage Quest master records)
- **Quest Scopes**
- **Quest Questions**
- **Quest Allocations**
- **Quest Summary** (per-allocation student tracking)
- **Activity Log** (student behavior audit trail)

---

## When This Screen Is Used

- **Daily Check-In** — Teachers start their day by looking at the Dashboard to see recent Quest activity
- **Monthly/Weekly Reporting** — Academic Coordinators use the KPIs and charts for adoption and performance reporting
- **Filtering by Class/Subject** — To see metrics for a specific class or subject only
- **Tracking Engagement** — Viewing total submissions vs total allocations to see how many students are participating

---

## Default Data Load

The Dashboard is part of the main `index()` method of `LmsQuestController`, which loads data for ALL tabs simultaneously. The dashboard-specific data includes:

| What Loads | Source | Notes |
|------------|--------|-------|
| Global Filters | Class/Section, Subject, Date Range | Applied to all metrics |
| Total Quests | `Quest::count()` | Filtered by class/subject |
| Total Questions | `QuestQuestion::count()` | Joined to quests, filtered |
| Total Allocations | `QuestAllocation::count()` | Filtered by class/subject/date |
| Total Submissions | `QuizQuestAttempt::count()` | Status = SUBMITTED/TIMEOUT |
| Total Checked | `QuizQuestResult::count()` | Assessment type = QUEST |
| Average Score | `QuizQuestResult::avg('percentage')` | Rounded to 1 decimal |
| Status Breakdown | `Quest::groupBy('status')` | DRAFT, PUBLISHED, ARCHIVED counts |
| Monthly Activity | `Quest::groupBy month` | Last 6 months, created vs allocated |
| Score Distribution | `QuizQuestResult::percentage` | Binned into 5 ranges |
| Subject Breakdown | `Quest::groupBy subject` | Top 6 subjects by quest count |
| Class Breakdown | `Quest::groupBy class` | Top 6 classes by quest count |
| Recent Quests | `Quest::latest()->limit(8)` | With question/attempt/allocation counts |

---

## Key Dashboard Metrics

### Top-Level KPIs

| Metric | Calculation | What It Shows |
|--------|------------|---------------|
| Total Quests | `COUNT(lms_quests.id)` | How many Quests exist (filtered) |
| Total Questions | `COUNT(lms_quest_questions.id)` | Total questions across all filtered Quests |
| Total Allocations | `COUNT(lms_quest_allocations.id)` | How many times Quests have been deployed |
| Total Submissions | `COUNT(sp_quiz_quest_attempts.id)` WHERE status IN ('SUBMITTED','TIMEOUT') | How many students have completed |
| Total Checked | `COUNT(sp_quiz_quest_results.id)` WHERE assessment_type='QUEST' | How many have been graded/evaluated |
| Average Score | `AVG(sp_quiz_quest_results.percentage)` | Overall average performance |

### Charts

**Monthly Activity (Bar Chart)** — Shows Quest creation vs Allocation creation over the last 6 months. Each month shows two bars: Quests Created and Allocations Created.

**Score Distribution (Donut Chart)** — Bins all student percentages into 5 ranges:
- 0–20% (very low)
- 21–40% (low)
- 41–60% (average)
- 61–80% (good)
- 81–100% (excellent)

**Subject Breakdown** — Top 6 subjects by number of Quests, showing quest count, sum of total_questions, and average total_marks.

**Class Breakdown** — Top 6 classes by number of Quests.

### Status Breakdown

Simple counts of Quests in each status:
- **DRAFT** — Created but not yet published
- **PUBLISHED** — Active and available
- **ARCHIVED** — No longer in use

### Recent Quests Grid

Displays the 8 most recently created Quests with real-time stats per row:
- Questions Count (via `questQuestions` relationship)
- Allocations Count (via `allocations` relationship, using `total_alloc` withCount)
- Submitted Count (via `attempts` relationship filtered to SUBMITTED/TIMEOUT)
- Checked Count (via `results` relationship, using `total_evaluated` withCount)

Dynamic percentages are calculated per row:
- `(Submitted / Allocations) * 100` — submission rate
- `(Checked / Submitted) * 100` — evaluation rate

---

## Business Rules and Conditions

### Rule 1: Global Filters Apply to All Metrics
All KPI calculations respect the selected filters:
- **Class/Section** — Filters quests by class_id; allocations are filtered by SECTION/CLASS/STUDENT target resolution
- **Subject** — Filters quests by subject_id
- **Date Range** — Filters by `published_at` for allocations, `created_at` for quests, `submitted_at` for attempts, `created_at` for results

### Rule 2: SECTION Filter Uses Complex Resolution
When a class section is selected, allocations are matched using three OR conditions:
- Allocation type = SECTION AND target_id = selected section
- Allocation type = CLASS AND target_id = selected section's class
- Allocation type = STUDENT AND target_id IN (students enrolled in that section)

### Rule 3: Monthly Activity Is Last 6 Months
The monthly activity chart always shows exactly 6 months (current month plus 5 previous months). Empty months show as 0.

### Rule 4: Score Distribution Is Calculated from All Results
The score distribution bins include ALL QuizQuestResult records where assessment_type = 'QUEST', filtered by the global filters.

### Rule 5: Recent Quests Limited to 8
The recent quests grid shows at most 8 quests, ordered by latest `created_at`.

### Rule 6: Data Loads for All Tabs Simultaneously
The `index()` method loads data for all 6 tabs (Dashboard, Quest List, Scopes, Questions, Allocations, Summary, Activity Log) in a single request. This means the page loads slower initially but tab switching is instant.

---

## Workflow Steps

### Viewing the Dashboard
1. Teacher navigates to the Quests module
2. The Dashboard tab is the default active tab
3. Global filters are shown at the top: Class/Section (dropdown), Subject (dropdown, populated via AJAX based on Class selection), Date Range (daterangepicker)
4. Below the filters, 6 KPI cards show total numbers
5. Charts render below the KPIs:
   - Monthly Activity (bar chart)
   - Score Distribution (donut chart)
   - Subject and Class breakdowns
6. The Recent Quests grid shows at the bottom

### Applying Filters
1. Teacher selects a Class/Section from the dropdown
2. Subjects are loaded via AJAX (`getSubjectsByClass`)
3. Teacher optionally selects a Subject
4. Teacher optionally sets a date range
5. The page reloads with the filters applied to all metrics

### Switching Tabs
1. Teacher clicks on any other tab (Quest List, Scopes, etc.)
2. The tab content is already loaded (rendered in the same response)
3. The URL updates with `?active_tab=quest_summary` (or similar)
4. Pagination within each tab is independent (each has its own page parameter)

---

## Example Scenario

Mr. Khanna, the Academic Coordinator, wants to check how the Quests feature is being used this month.

He opens the Quests module and sees the Dashboard:
- **Total Quests**: 45 (12 Draft, 28 Published, 5 Archived)
- **Total Questions**: 890
- **Total Allocations**: 120
- **Total Submissions**: 85 (71% submission rate)
- **Total Checked**: 62 (73% evaluation rate)
- **Average Score**: 67.3%

He scrolls down to the Monthly Activity chart and sees that Quest creation peaked in August (15 created) but allocations peaked in September (30 allocated). The Score Distribution chart shows most students scored between 41-60%.

He selects Class = 10, Section = A from the filters. The metrics update to show only Grade 10, Section A data: 8 Quests, 160 questions, 25 allocations, 20 submissions.

---

## Related Screens

- **Quest Creation** — Where new Quests are created (counted in Total Quests)
- **Quest Questions** — Where questions are added (counted in Total Questions)
- **Quest Allocation** — Where Quests are deployed (counted in Total Allocations)
- **Quest Summary** — Where per-allocation tracking is viewed
- **Quest Paper Check** — Where grading happens (counted in Total Checked)

---

## Requirements

**Controller:** Dashboard data is loaded within `Modules\LmsQuests\Http\Controllers\LmsQuestController::index()` (1602 lines total, ~400 lines dedicated to dashboard metrics)
**Models Used:** `Quest`, `QuestQuestion`, `QuestAllocation`, `QuizQuestAttempt`, `QuizQuestResult`
**Route:** Default tab of `Route::resource('quest', LmsQuestController::class)`

Key dashboard calculations (all within `index()`):
- `dashboardStats['total_quests']` — Quest count with class/subject filter
- `dashboardStats['total_questions']` — QuestQuestion count through relationship, with filters
- `dashboardStats['total_allocations']` — QuestAllocation count with complex section/class/student resolution
- `dashboardStats['total_submissions']` / `dashboardStats['total_submitted']` — QuizQuestAttempt counts with status filters
- `dashboardStats['total_checked']` / `dashboardStats['total_evaluated']` — QuizQuestResult counts
- `dashboardStats['avg_score']` — Average percentage from results
- `dashboardStats['status_breakdown']` — DRAFT/PUBLISHED/ARCHIVED counts
- `dashboardStats['monthly_activity']` — Last 6 months quest creation
- `dashboardStats['monthly_allocations']` — Last 6 months allocation creation
- `dashboardStats['score_distribution']` — 5-bin distribution
- `dashboardStats['subject_breakdown']` — Top 6 subjects
- `dashboardStats['class_breakdown']` — Top 6 classes
- `$recentQuests` — Last 8 quests with withCount relationships

---

## Who Can Access This Screen

- **Teacher** — Can view dashboard (sees their own class data)
- **Head of Department** — Can view dashboard for their department
- **Academic Coordinator** — Full view across all classes
- **Principal** — Read-only view

All access gated by `tenant.quest.viewAny` permission.

---

## How This Screen Works — Logic Flow (Non-Technical)

When a teacher navigates to the Quests module, the system runs many database queries at once to gather all the data needed for every tab. This is done in a single page load so that switching between tabs feels instant.

For the Dashboard specifically, the system:
1. Counts all Quests in the database (filtered by any selected class or subject)
2. Counts all questions attached to those Quests
3. Counts all allocations made for those Quests
4. Counts how many students have submitted (completed) the Quests
5. Counts how many have been graded by teachers
6. Calculates the average score across all graded Quests
7. Breaks down Quests by their status (Draft, Published, Archived)
8. Groups Quest creation and allocation by month for the last 6 months
9. Groups student scores into 5 ranges (0-20%, 21-40%, etc.)
10. Finds the top 6 subjects and classes by Quest count
11. Loads the 8 most recently created Quests with their question/attempt/allocation counts

The global filters (class/section, subject, date range) are applied to ALL calculations uniformly. Changing a filter reloads the entire page with the filter applied.

---

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| LmsQuests Core | `lms_quests`, `lms_quest_questions`, `lms_quest_allocations` |
| Student Portal | `sp_quiz_quest_attempts` (submission counts), `sp_quiz_quest_results` (score distribution, evaluation counts) |
| Academic Setup | `sch_class_sections`, `sch_classes`, `sch_subjects` (for filters and breakdowns) |
| School Setup | `sch_subject_groups` (subject-by-class resolution via AJAX) |
