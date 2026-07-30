# Teacher Monthly Report — Business Requirements

## What This Screen Does

The Teacher Monthly Report shows a calendar-style view of what a teacher assigned each day of the month and how students responded. Think of it as a heatmap that answers:

- On March 5, how many students were assigned a quiz?
- How many attempted it?
- What was their average score?

This report helps principals and HODs evaluate:
- Teacher workload — Are they assigning enough assessments?
- Student engagement — Are students actually attempting what's assigned?
- Coverage — Are all sections getting equal attention?

---

## When This Screen Is Used

- **Monthly Performance Review** — Principals evaluate teacher assessment distribution
- **Workload Analysis** — HODs ensure even distribution across sections
- **Engagement Tracking** — Identify classes with low attempt rates

## Default Data Load

When the Reports page opens with `active_tab=teacher-monthly`:

- **First available teacher** is auto-selected (user with employee where is_teacher=true)
- **Date range** defaults to current month (start → end)
- Class, Section, Subject Group, Subject are optional filters
- Assessment Type defaults to QUIZ

---

## Filters Available

| Filter | Behavior |
|--------|----------|
| Teacher | Required — auto-selects first teacher if empty |
| Class | Optional — scopes allocations |
| Section | Optional — scopes by section |
| Subject Group | Optional |
| Subject | Optional |
| Assessment Type | QUIZ/QUEST/Both — default: QUIZ |
| Date Range | Default: current month |

---

## Complete Logic Flow — How the Report Works (Plain Language)

When a principal or HOD opens this report, the system builds a calendar grid showing what the teacher assigned each day and how students responded. Think of it like a weather forecast map — but for assessment activity.

### Step 1 — Read the Filters
The system reads who and what to analyze:
- **Teacher** (required) — Which teacher's activity to review (defaults to first available)
- **Date Range** — Which month to show (defaults to current month)
- **Class/Section/Subject** (optional) — Narrow down to specific classes
- **Assessment Type** — Quizzes, Quests, or Both (default: Quizzes)

### Step 2 — Build the Calendar
The system creates a list of every day in the selected month. For March 2026, that's 31 days. Each day is labeled with the day number and day name (e.g., March 1 = "1" + "Monday").

### Step 3 — Find What the Teacher Assigned
The system searches for every quiz and quest allocation this teacher created during the month:
- Only active allocations are considered
- An allocation counts if it was published during the month OR if its due date falls during the month, OR if it spans across the whole month

**Real Example:**
> Teacher Ravi assigned "Science Quiz 1" on March 1 (published_at) with a March 10 due date.
> He also assigned "Math Practice" on March 15 with a March 25 due date.
> The system finds both allocations.

### Step 4 — List All the Sections the Teacher Covers
From all those allocations, the system figures out which class-sections this teacher is responsible for:
- If Ravi assigned quizzes to Grade 10-A, 10-B, and 10-C, those are his target sections

### Step 5 — List All Students in Those Sections
The system finds every student enrolled in those sections. These are the students whose attempt data will be checked.

### Step 6 — Find All Student Attempts
The system fetches all submitted or timed-out attempts from those students within the date range. It organizes them by:
- **Assessment type** (quiz or quest)
- **Date** (when was it submitted?)
- **Subject** (which subject?)
- **Student** (which student?)

### Step 7 — Build the Calendar Grid (The Main Work)

Now the system assembles the grid. For **each** assessment type tab, **each** subject, **each** class-section, and **each** day:

**It asks:** "Was this class-section supposed to have an assessment on this day?"
- It checks: was there an active allocation where `published_at ≤ this day ≤ due_date`?

| If Active That Day | What the Cell Shows |
|--------------------|---------------------|
| **YES** | Three numbers: **Assigned** (total students in section), **Attempted** (who submitted), **Average Score** |
| **NO** | Empty cell — nothing was assigned |

**Real Example — One Cell:**
> March 5, Science, Grade 10-A:
> - Assigned: 45 (total students in 10-A)
> - Attempted: 40 (unique students who submitted on March 5)
> - Avg Score: 72%
>
> The cell shows: "45 / 40 / 72%"

### Step 8 — Compute "All Average" Row
For each day, the system calculates a school-wide average across all subjects. This row shows the big-picture engagement for that day.

### What the Report Looks Like
- **Two tabs** at the top: "Quiz - Homework" and "Assessment"
- **Within each tab**: Rows = Subjects, Columns = Class-Sections, Cells = Days of the month
- Each cell is a mini grid showing Assigned / Attempted / Average

**Real Example:**
> Principal opens March 2026 for Teacher Ravi:
> - **Quiz - Homework tab:**
>   - **Science row:**
>     - Grade 10-A column: Shows 31 mini-cells (one per day)
>     - March 1: 45 / 40 / 68% — Good engagement
>     - March 5: 45 / 42 / 75% — Better scores
>     - March 10-14: Empty — Spring break
>   - **Math row:**
>     - Grade 10-A: Similar daily grid
>   - **All Average row:** Per-day school average
> - Principal can see Ravi assigns quizzes most weekdays, attempt rates are 85-90%, average scores range from 65-78%

---

## Key Data Points

Each cell in the calendar grid shows THREE numbers:
1. **Assigned** — Total students in the class-section (e.g., "45")
2. **Attempted** — Unique students who attempted on that day (e.g., "38")
3. **Average Score** — Mean percentage (e.g., "72%")

The grid is organized as:
- Two assessment type tabs: "Quiz - Homework" and "Assessment"
- Within each tab: Subject rows → Class-section columns → Day cells

---

## Deep Walkthrough — A Principal's Full Day Using the Report

This section follows **Principal Mehta** through a complete real-world session — evaluating all teachers' assessment activity for March 2026.

---

### Morning: Monthly Teacher Review (First Week of April)

**It's Monday, April 3rd, 9:00 AM.** Principal Mehta sits down for her monthly teacher performance review. She opens the **Teacher Monthly Report** and selects:
- **Teacher:** Ravi Sharma (Grade 10 Science & Math)
- **Month:** March 2026
- **Assessment Type:** Both (Quizzes + Quests)

---

### Step 1: The Big Picture — Ravi's March Calendar

The system shows a calendar grid. Principal Mehta scans it:

**Quiz - Homework tab:**

```
           Grade 10-A          Grade 10-B          Grade 10-C
Science:   [31 daily cells]    [31 daily cells]    [31 daily cells]
Math:      [31 daily cells]    [31 daily cells]    [31 daily cells]
All Avg:   [31 daily cells]    [31 daily cells]    [31 daily cells]
```

**Each cell** shows "Assigned / Attempted / Avg Score." Let's zoom in on the Science row for Grade 10-A.

| March | 1 Mon | 2 Tue | 3 Wed | 4 Thu | 5 Fri | 6 Sat | 7 Sun | 8 Mon | 9 Tue | 10 Wed | ... |
|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|--------|-----|
| Science 10-A | 45/40/68% | 45/38/72% | 45/42/75% | — | 45/41/70% | — | — | 45/39/65% | 45/43/80% | 45/40/78% | ... |
| Math 10-A | — | — | — | 45/42/82% | — | — | — | — | — | — | ... |

**Principal Mehta observes:**

| Observation | Data Point | Interpretation |
|-------------|-----------|---------------|
| **Frequency** | Ravi assigns Science quizzes Mon-Wed-Fri pattern, Math on Thursdays | Consistent schedule — good |
| **Engagement** | Attempted ranges 38-43 out of 45 (84-95%) | High engagement — students are participating |
| **Weekend pattern** | Sat-Sun = empty cells | No weekend assignments — reasonable |
| **Gaps** | March 4 = empty for Science (was a test day) | Expected — school had an exam |
| **Score range** | 65-80% | Healthy variation |

**Principal Mehta thinks:** *"Ravi is consistent. He assigns quizzes 3 times a week in Science, once a week in Math. Engagement is high — over 85% attempt rate. Scores are in a healthy range. He's doing his job well."*

---

### Step 2: Spotting a Red Flag

Principal Mehta scrolls to the **All Average row** for March 10:

**March 10 — Science, Grade 10-A cell: 45/40/65%**

She notices: *"65% average on March 10 is noticeably lower than the 70-80% range for other days. Let me investigate."*

She clicks on that specific cell. A popup shows:

| Detail | Value |
|--------|-------|
| **Quiz** | "Motion — Chapter Test" |
| **Assigned** | 45 students |
| **Attempted** | 40 students |
| **Average Score** | 65% |
| **Score Distribution** | Outstanding: 3, Good: 10, Satisfactory: 18, Needs Attention: 7, Struggling: 2 |
| **Topic** | Science → Motion → Velocity Calculations |

**Principal Mehta thinks:** *"Ah — this was the Motion chapter test with the hard numerical problems. 65% makes sense. The topic was velocity calculations which students historically find difficult. This isn't a teacher quality issue — it's a topic difficulty issue. Good, nothing to flag."*

---

### Step 3: Comparing Teachers

Principal Mehta switches to **Teacher: Priya Mehta** (English teacher, Grade 10):

```
           Grade 10-A          Grade 10-B
English:   [31 daily cells]    [31 daily cells]
```

**March calendar for Priya:**

| March | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | ... | 31 |
|-------|---|---|---|---|---|---|---|---|---|---|----|-----|----|
| English 10-A | — | — | 45/20/62% | — | — | — | — | 45/18/58% | — | — | — | ... | — |
| English 10-B | — | — | 42/15/55% | — | — | — | — | 42/12/50% | — | — | — | ... | — |

**Principal Mehta's observations:**

| Observation | Data Point | Severity |
|-------------|-----------|----------|
| **Frequency** | Only 2 quizzes in the entire month | **RED FLAG** — compared to Ravi's 12+ |
| **Engagement (10-A)** | 20/45 (44%) attempt rate | **LOW** — half the class isn't trying |
| **Engagement (10-B)** | 15/42 (36%) and 12/42 (28%) | **CRITICAL** — less than a third are trying |
| **Scores** | 55-62% average | Below average but consistent with low engagement |
| **Consistency** | 10-B is worse than 10-A | Possible section-specific issue |

**Principal Mehta thinks:** *"This is a serious problem. Priya assigned only 2 quizzes in 31 days — that's not enough assessment. And the engagement rate is terrible — only 28-44% of students attempt her quizzes compared to Ravi's 85-95%. Either she's not motivating students, the quizzes are too hard, or there's a communication issue."*

**Action Plan for Priya:**
1. **Schedule a meeting** with Priya this week
2. **Ask:** Why only 2 quizzes in a month? Target: minimum 1 per week
3. **Ask:** Why low engagement? Are students aware of the quizzes? Are they too difficult?
4. **Recommend:** Set a fixed quiz day (e.g., every Wednesday) so students expect it
5. **Follow-up:** Check next month's report to see if engagement improves

---

### Step 4: Spotting an Oddity — NTA (Not Taught Assessed)

Principal Mehta checks **Teacher: Ananya Kapoor** (Physics teacher):

| March | 5 | 12 | 19 | 26 |
|-------|---|---|----|----|
| Physics 10-A | 45/30/75% | 45/28/70% | 45/32/72% | 45/0/— |

**March 26 cell shows:** Assigned 45, Attempted **0**, Avg **—** (no data)

**Principal Mehta thinks:** *"45 assigned but 0 attempted? That's very unusual. Either the quiz wasn't published properly, or there's a technical issue."*

She clicks the cell. Popup shows:
- **Quiz:** "Physics — Thermodynamics Quiz"
- **Published At:** March 26
- **Due Date:** April 2 (still open!)
- **Current Attempts:** 0 (none yet)

**Conclusion:** The quiz was just published today (March 26) and the due date is April 2. Students haven't taken it yet because it was just assigned. Zero attempts is expected.

**Lesson learned:** The report shows real-time data — a quiz published today will show 0 attempts until students start taking it. Don't panic about zero attempts on the publish date.

---

### Step 5: Checking Subject Group Performance

Principal Mehta wants to compare subject groups across the school. She uses the **Subject Group** filter to see:

| Subject Group | Teachers | Avg Assignments/Month | Avg Attempt Rate | Avg Score |
|--------------|----------|----------------------|-----------------|-----------|
| Sciences | Ravi, Ananya, Sameer | 10 | 88% | 72% |
| Mathematics | Ravi, Sunita | 8 | 82% | 76% |
| Languages | Priya, Amit | 3 | 40% | 60% |
| Social Studies | Kiran | 6 | 75% | 70% |

**Principal Mehta's analysis:**

| Finding | Implication | Action |
|---------|------------|--------|
| **Sciences** lead in frequency (10/month) and engagement (88%) | Best-performing department | Recognize Ravi and team as example |
| **Languages** lowest in everything (3/month, 40% engagement, 60% avg) | Systemic issue, not just one teacher | Department-wide review needed |
| **Math** has good scores (76%) but lower frequency (8 vs Sciences' 10) | Quality over quantity — acceptable | No action needed |
| **Social Studies** middle of the pack (6/month, 75%) | Adequate | Monitor monthly |

**Principal Mehta's end-of-month summary:**

| Teacher | Grade | Assessment Frequency | Engagement | Score Avg | Verdict |
|---------|-------|---------------------|------------|-----------|---------|
| Ravi Sharma | A+ | 12/mo | 88% | 72% | Excellent — consistent, high engagement |
| Ananya Kapoor | A | 8/mo | 85% | 75% | Good — steady performer |
| Priya Mehta | **C** | **2/mo** | **40%** | **60%** | **Needs improvement — schedule meeting** |
| Sunita Gupta | B+ | 8/mo | 82% | 76% | Good |
| Amit Verma | D | 3/mo | 38% | 58% | **Critical — follow up urgently** |
| Kiran Rao | B | 6/mo | 75% | 70% | Satisfactory |

---

### Additional Real-World Scenarios

**SC-004 — Teacher with Perfect Engagement (Non-Technical)**
Ravi's March data shows: for Science quiz days, attempted is always 40-43 out of 45 (89-95%). The 2-5 missing students are usually the same names (Dev, Rohit, Vikram — known late submitters). Principal notes this is an individual student issue, not a teacher issue.

**SC-005 — Holiday Week Impact (Non-Technical)**
March 10-14 was spring break. The calendar shows all cells empty for those days for ALL teachers. The "All Average" row shows 0 assigned. Principal confirms the break is correctly reflected in the data.

**SC-006 — Teacher with Too Many Assignments (Non-Technical)**
Another teacher assigned quizzes every single weekday in March — 22 quizzes in 31 days. The engagement rate dropped from 85% (week 1) to 40% (week 4). Students burned out. Principal counsels the teacher on optimal assessment frequency.

**SC-007 — Technical Glitch Detection (Non-Technical)**
For one teacher, the March 15 cell shows: "Assigned 45, Attempted 0, Avg —" but March 16 shows "45/44/78%." Principal realizes the published_at date was set to March 15 but students couldn't access it until March 16 (likely a timezone or scheduled-publish issue). She advises the teacher to verify publish dates.

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` (tab: `teacher-monthly`)
**Data Method:** `generateTeacherMonthlyData(Request)` — private method
**View:** `lmsquiz::reports.partials.teacher-monthly`
**Policy:** `tenant.teacher-monthly-report.view`

The report only loads data via AJAX. On initial page load, empty structure is returned.

---

## Dependencies

| Dependency | Details |
|-----------|---------|
| `lms_quiz_allocations` | Quiz assignment data per teacher |
| `lms_quest_allocations` (Quest module) | Quest assignment data per teacher |
| `lms_quiz_quest_attempts` | Student attempt records with percentages |
| `std_student_academic_sessions` | Student population per class-section |
| `sys_users` | Teacher identification (via employee relationship) |
| `sch_class_sections` | Class-section resolution |
| `sch_subject_groups` | Subject group filter |
