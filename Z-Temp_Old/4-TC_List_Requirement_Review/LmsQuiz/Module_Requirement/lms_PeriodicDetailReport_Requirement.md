# Periodic Detail Report — Business Requirements

## What This Screen Does

The Periodic Detail Report shows a matrix of students vs assessments over a date range. Each cell shows whether a student attempted a specific assessment and what score they got.

Think of it as a spreadsheet where:
- **Rows** = Students
- **Columns** = Assessments (quizzes and quests)
- **Each Cell** = Score % or status (Submitted, In Progress, Not Started)

This report is designed for generating periodic progress summaries for parent-teacher meetings, academic reviews, and board reporting requirements.

---

## When This Screen Is Used

- **End-of-Term Progress Reporting** — Generate class-wide assessment coverage reports
- **Parent-Teacher Meeting Prep** — Show individual student status across all assessments
- **Board Compliance** — Demonstrate assessment coverage
- **Gap Analysis** — Identify students missing multiple assessments

## Default Data Load

When the Reports page opens with `active_tab=periodic-detail`:

- **First student** is auto-selected (if no student_id provided)
- **Date range** defaults to last 30 days
- Class, Section, Subject Group, Subject, Assessment Type filters available
- Topic hierarchy cascade available

---

## Filters Available

| Filter | Behavior |
|--------|----------|
| Student | Auto-selected (first active) — scopes all data |
| Class | Optional — resolved from student's current session |
| Section | Optional |
| Subject Group | Optional |
| Subject | Optional |
| Assessment Type | QUIZ/QUEST/Both — default: Both |
| Lesson | Optional — cascaded from subject |
| Topic Type | Optional — filters by topic_level_type_id |
| Topic cascade (4 levels) | Optional |
| Date Range | Default: last 30 days |

---

## Complete Logic Flow — How the Report Works (Plain Language)

When a coordinator opens this report, the system builds a matrix table showing which assessments each student attempted and what scores they got. Think of it as a mark sheet spreadsheet — rows are students, columns are assessments, cells are scores.

### Step 1 — Read the Filters
The system reads who and what to look at:
- **Student** — Usually a single student is selected (for one student's detail view)
- **Date Range** — How far back to look (defaults to last 30 days)
- **Subject / Lesson / Topic** (optional) — Focus on specific content
- **Assessment Type** — Quizzes, Quests, or Both

### Step 2 — Find All Student Attempts
The system searches for every quiz and quest the student has submitted or timed out on. For each attempt, it counts:
- How many answers the student gave
- How many were correct
- The score percentage

Results are paginated — 15 per page.

### Step 3 — Find What Was Assigned But Not Attempted
This is the key feature of this report. The system also figures out: "What assessments was this student given but never attempted?"

It does this by finding all allocations (CLASS, SECTION, or STUDENT type) that target this student, then cross-referencing with actual attempts. If an allocation exists but there's no attempt → that's an **unattempted assessment**.

### Step 4 — Process Attempted Rows
For each attempt found, the system builds a row showing:

| Column | Example |
|--------|---------|
| **Assessment Title** | "Science Quiz 1" |
| **Date** | Mar 5, 2026 |
| **Subject** | Science |
| **Lesson** | Motion |
| **Topic** | Velocity |
| **Attempted?** | Yes |
| **Score** | 85% |
| **Correct/Wrong/Unattempted** | 8/1/1 (out of 10 questions) |
| **Category** | Outstanding |

### Step 5 — Process Unattempted Rows
For each allocation where the student has NO attempt, the system adds a row showing:

| Column | Example |
|--------|---------|
| **Assessment Title** | "English Grammar Quest" |
| **Date** | (none — not submitted) |
| **Subject/Lesson** | English / Grammar |
| **Attempted?** | No |
| **Score** | 0% |
| **Category** | Struggling (by default) |

**Why show unattempted rows?** So teachers can see which assignments the student is missing — not just what they attempted.

### Step 6 — Ghost Rescue
If a quiz or quest was deleted from the database, the system still shows the attempt but marks the missing data:
- **Subject:** "N/A" or "Unassigned"
- **Lesson:** "Deleted/Missing"
- **Topic:** "Assessment ID: 42"
- **Score:** Still shown (attempt data preserved)

### Step 7 — Calculate Summary Metrics
| Metric | How It's Calculated |
|--------|-------------------|
| **Total Assigned** | Count of all allocations for this student |
| **Attempted** | How many were attempted |
| **Not Attempted** | How many were skipped |
| **Average Score** | Average across all attempted assessments |
| **Category Counts** | How many Outstanding, Good, etc. |

### Step 8 — Sort and Display
Rows are sorted with **attempted first**, then **unattempted**. This way teachers see the completed work before the missing work.

### What the Report Looks Like

| Assessment | Date | Subject | Lesson | Score | Status |
|-----------|------|---------|--------|-------|--------|
| Science Quiz 1 | Mar 5 | Science | Motion | 85% | ✅ Attempted |
| Math Practice | Mar 8 | Math | Algebra | 72% | ✅ Attempted |
| English Quest | — | English | Grammar | 0% | ❌ Not Started |
| History Quiz | Mar 15 | History | Ancient | 45% | ✅ Attempted |

**Real Example:**
> Coordinator opens Periodic Detail Report for student Aarav (March 2026):
> - 4 assessments found: 3 attempted, 1 not started
> - Average: 67%
> - The 1 unattempted (English Grammar Quest) is shown at the bottom
> - Coordinator can remind Aarav about the pending English assignment

---

## Cell Value Mapping

| Display | Meaning | Condition |
|---------|---------|-----------|
| Score % (e.g., 75%) | Student submitted and got a score | Has result with percentage |
| "NS" | Not Started | Student was allocated but has no attempt |
| "IP" | In Progress | Attempt status = IN_PROGRESS |
| "S" | Submitted (pending eval) | Submitted but no result yet |
| "A" | Absent | For offline exams only |

---

## Deep Walkthrough — A Coordinator's Full Day Using the Report

This section follows **Shail, the Academic Coordinator**, through a complete real-world session — auditing a student's assessment coverage before a parent meeting.

---

### Morning: Pre-Meeting Student Audit (30 Minutes)

**It's Thursday, April 6th, 9:00 AM.** Shail has a parent meeting for **Aarav Sharma** tomorrow. Aarav's parents requested the meeting because they're worried about his grades. Shail needs a complete picture before the conversation.

Shail opens the **Periodic Detail Report** and selects:
- **Student:** Aarav Sharma (Grade 10-A)
- **Date Range:** March 2026
- **Assessment Type:** Both

---

### Step 1: The Full Table Loads

The system shows a table with ALL assessments — both attempted and not attempted:

| # | Assessment | Date | Type | Subject | Lesson | Topic | Score | Status |
|---|-----------|------|------|---------|--------|-------|-------|--------|
| 1 | Science Quiz 1 | Mar 5 | Quiz | Science | Motion | Distance & Speed | **85%** | ✅ Attempted |
| 2 | Math Practice | Mar 8 | Quiz | Math | Algebra | Linear Equations | **72%** | ✅ Attempted |
| 3 | English Grammar Quest | Mar 10 | Quest | English | Grammar | Tenses | **—** | ❌ **Not Started** |
| 4 | History Quiz | Mar 12 | Quiz | History | Ancient Civilizations | Indus Valley | **45%** | ✅ Attempted |
| 5 | Science Velocity Quiz | Mar 15 | Quiz | Science | Motion | Velocity | **90%** | ✅ Attempted |
| 6 | Math Quadratics Quiz | Mar 18 | Quiz | Math | Algebra | Quadratic Eqns | **—** | ❌ **Not Started** |
| 7 | English — Active/Passive | Mar 20 | Quiz | English | Grammar | Voice | **—** | ❌ **Not Started** |
| 8 | Physics Thermodynamics | Mar 22 | Quest | Physics | Thermodynamics | Heat Transfer | **—** | ❌ **Not Started** |
| 9 | Science Acceleration | Mar 25 | Quiz | Science | Motion | Acceleration | **78%** | ✅ Attempted |
| 10 | History Medieval Quest | Mar 28 | Quest | History | Medieval Period | Feudalism | **62%** | ✅ Attempted |

**Summary Metrics at the top:**
| Metric | Value |
|--------|-------|
| **Total Assigned** | 10 assessments |
| **Attempted** | 6 |
| **Not Attempted** | 4 |
| **Average Score** | 72% (across 6 attempted) |
| **Category Breakdown** | Outstanding: 1, Good: 2, Satisfactory: 2, Needs Attention: 1, Struggling: 0 |

---

### Step 2: Analyzing the Pattern — 4 Unattempted Assessments

Shail focuses on the 4 **Not Started** items first. This is the critical information that other reports don't show:

| # | Assessment | Subject | Type | Due Date | Days Overdue | Why Might Aarav Have Skipped? |
|---|-----------|---------|------|----------|-------------|------------------------------|
| 3 | English Grammar Quest | English | Quest | Mar 12 | Past due | English is his weakest subject |
| 6 | Math Quadratics Quiz | Math | Quiz | Mar 20 | Past due | Was he sick that week? |
| 7 | English — Active/Passive | English | Quiz | Mar 22 | Past due | Second English skip — pattern |
| 8 | Physics Thermodynamics | Physics | Quest | Mar 25 | Past due | New subject — might feel overwhelmed |

**Shail's observations:**

1. **English — skipped BOTH assessments (Quest + Quiz):** Aarav has not attempted ANY English work in March. This is a clear pattern — he's actively avoiding English.

2. **Math — skipped the Quadratics quiz:** But he DID attempt the earlier Linear Equations quiz (72%). What changed? Maybe Quadratics is harder and he felt unprepared.

3. **Physics — skipped the quest:** This was a new topic (Thermodynamics). Aarav might not have understood the material and gave up.

**Pattern across subjects:**

| Subject | Attempted | Not Attempted | Rate |
|---------|-----------|---------------|------|
| **Science** | 3 of 3 | 0 | **100%** ✅ |
| **Math** | 1 of 2 | 1 | **50%** ⚠️ |
| **History** | 2 of 2 | 0 | **100%** ✅ |
| **English** | **0 of 2** | **2** | **0%** 🔴 |
| **Physics** | **0 of 1** | **1** | **0%** 🔴 |

**Shail's conclusion:** *"Aarav has a 100% attempt rate in Science and History — those are his strong subjects. But 0% in English and Physics — he's actively avoiding those. This isn't laziness — it's subject-specific avoidance. He probably doesn't feel confident in English and Physics."*

---

### Step 3: Examining the Attempted Scores in Detail

Shail looks at the 6 attempted assessments:

| # | Assessment | Score | Class Avg | Difference | Analysis |
|---|-----------|-------|-----------|------------|----------|
| 1 | Science Quiz 1 | 85% | 72% | **+13%** | ✅ Above average — strong |
| 5 | Science Velocity Quiz | 90% | 65% | **+25%** | ✅ Well above average — excellent |
| 9 | Science Acceleration | 78% | 75% | **+3%** | ✅ Slightly above average |
| 2 | Math Linear Equations | 72% | 74% | **−2%** | ⚠️ At par with class |
| 4 | History Indus Valley | 45% | 60% | **−15%** | 🔴 Below average |
| 10 | History Feudalism Quest | 62% | 63% | **−1%** | ✅ At par with class |

**Shail's subject-level analysis:**

**Science (Strength):**
| Attempt | Score | Analysis |
|---------|-------|----------|
| Science Quiz 1 | 85% | Strong start |
| Velocity Quiz | 90% | Excellent — scored 25% above class avg |
| Acceleration | 78% | Good — still above average |
| **Science Average** | **84%** | **Strong subject** |

**History (Mixed):**
| Attempt | Score | Analysis |
|---------|-------|----------|
| Indus Valley | 45% | Below class average by 15% |
| Feudalism Quest | 62% | At par with class |
| **History Average** | **54%** | **Needs improvement** |

**Math (Decent but incomplete):**
| Attempt | Score | Analysis |
|---------|-------|----------|
| Linear Equations | 72% | Class average — acceptable |
| Quadratics | **Skipped** | First skipped Math — concerning |
| **Math Average** | **72%** | **Okay but incomplete** |

**English — Zero Attempts:**
| Attempt | Score | Analysis |
|---------|-------|----------|
| Grammar Quest | Skipped | |
| Active/Passive Quiz | Skipped | |
| **English Average** | **N/A** | **Critical — no engagement** |

**Physics — Zero Attempts:**
| Attempt | Score | Analysis |
|---------|-------|----------|
| Thermodynamics Quest | Skipped | |
| **Physics Average** | **N/A** | **No engagement** |

---

### Step 4: Shail's Full Assessment

After 30 minutes, Shail has a complete picture:

| Subject | Attempt Rate | Avg Score | Verdict |
|---------|-------------|-----------|---------|
| **Science** | 3/3 (100%) | 84% | ✅ **Strength** — consistent, high-performing |
| **Math** | 1/2 (50%) | 72% | ⚠️ **Incomplete** — needs to catch up on Quadratics |
| **History** | 2/2 (100%) | 54% | 🟡 **Improving** — first attempt low (45%), second better (62%) |
| **English** | **0/2 (0%)** | **N/A** | **🔴 CRITICAL** — zero engagement, active avoidance |
| **Physics** | **0/1 (0%)** | **N/A** | **🔴 NEW** — first Physics assignment, already skipping |

**Key insight — The "Why":**
Shail notices something important: Aarav attempts subjects where he scored well initially, and avoids subjects where he scored poorly or feels unfamiliar. This is a confidence issue, not a capability issue. He needs encouragement in English and Physics.

---

### Step 5: The Ghost Rescue Recovery

While reviewing, Shail notices a peculiar entry:

| Assessment | Date | Subject | Lesson | Score | Status |
|-----------|------|---------|--------|-------|--------|
| **(Deleted — ID: 42)** | Mar 30 | Unassigned | Deleted/Missing | 55% | ✅ Attempted |

**Shail thinks:** *"What's this? A deleted quiz with a 55% score?"*

She clicks for details. The system explains:
> *"This assessment was deleted from the system. The student's attempt data is preserved. Subject and lesson information cannot be determined."*

**Shail's conclusion:** *"An old quiz was cleaned up but Aarav's attempt still exists. We can see he scored 55% on something, but we can't tell what subject. Useful to know the attempt happened, but not actionable."*

---

### Step 6: Preparing for the Parent Meeting

Shail writes her notes for tomorrow's meeting:

| Topic | What to Tell Parents |
|-------|---------------------|
| **Overall** | "Aarav is a capable student. He averages 72% across 6 attempted assessments. His main issue is not capability — it's selective engagement." |
| **Science (Strength)** | "Aarav is excelling in Science — 84% average, 25% above class. He clearly enjoys it and puts in effort." |
| **Math** | "He did well on Linear Equations (72%) but skipped Quadratics. We need to make sure he catches up." |
| **History** | "Mixed performance — 45% on one, 62% on another. Improving trend. We'll monitor." |
| **English (Concern)** | "Aarav did NOT attempt ANY English assessments in March — 2 were assigned, both skipped. This is our main concern." |
| **Physics (New)** | "This is a new subject and he skipped the first assignment. We need to address this early before it becomes a pattern." |
| **Ghost Data** | "One deleted quiz with 55% score — not useful for planning but preserved for completeness." |

**Recommended Action Plan:**
1. **English:** Schedule a meeting with the English teacher. Assign make-up work. Consider a tutor.
2. **Math Quadratics:** Give Aarav a 2-day extension with a reminder.
3. **Physics:** Check in with Aarav — does he understand the material? Offer extra help session.
4. **Science:** Continue what's working — praise his performance, consider enrichment.
5. **Follow-up:** Re-run this report in 2 weeks to check if engagement improves.

---

### Additional Real-World Scenarios

**SC-004 — Student with Perfect Attendance (Non-Technical)**
Teacher opens report for Neha Gupta:
- **Total Assigned:** 8 assessments
- **Attempted:** 8 out of 8 (100%)
- **Average Score:** 92%
- **Not Started:** 0
- **Conclusion:** Neha is a model student — 100% attempt rate and excellent scores. Nothing to address — praise and enrichment.

**SC-005 — Student with Many Unattempted (Non-Technical)**
Teacher opens report for Rohit Verma:
- **Total Assigned:** 12 assessments
- **Attempted:** 2 out of 12 (17%)
- **Not Started:** 10
- **Conclusion:** Rohit has attempted only 2 of 12 assigned assessments. This is a serious engagement problem. Need immediate intervention — call parents, check for barriers (no device? no internet? personal issues?).

**SC-006 — Quest vs Quiz Completion Rate (Non-Technical)**
Teacher notices a student has:
- Quiz attempt rate: 8/10 (80%)
- Quest attempt rate: 1/5 (20%)
- **Insight:** The student does well with shorter, timed quizzes but avoids longer project-based quests. Possible reason: time management issues or finds extended work overwhelming.
- **Action:** Discuss time management strategies with the student.

**SC-007 — Filtering by Date Range (Non-Technical)**
Shail changes the date range from "Last 30 days" to "This Week" to see only current, urgent items. The table shows 3 assessments assigned this week: 1 attempted, 2 not started. She sends reminders for the 2.

**SC-008 — Filtering by Single Subject (Non-Technical)**
Shail filters by Subject: **English**. The table now shows ONLY English assessments:
- English Grammar Quest (Mar 10) — Not Started
- English Active/Passive Quiz (Mar 20) — Not Started
- **Clear picture:** Aarav has 2 pending English assignments. This focused view helps Shail prepare specifically for the English discussion in the parent meeting.

**SC-009 — Sorting by Due Date (Non-Technical)**
Shail sorts the table by Due Date (ascending). The most overdue items appear first:
1. English Grammar Quest (due Mar 12) — 25 days overdue 🔴
2. Math Quadratics Quiz (due Mar 20) — 17 days overdue 🟠
3. English Active/Passive (due Mar 22) — 15 days overdue 🟠
4. Physics Thermodynamics (due Mar 25) — 12 days overdue 🟡
- **Priority:** English assignments are most urgent — both significantly overdue.

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` (tab: `periodic-detail`)
**Data Method:** `generatePeriodicDetailData(Request)` — private method
**View:** `lmsquiz::reports.partials.periodic-detail`
**Policy:** `tenant.periodic-detail-report.view`

---

## Dependencies

| Dependency | Details |
|-----------|---------|
| `lms_quiz_quest_attempts` | All attempt records with status and percentage |
| `lms_quiz_quest_results` | Score/evaluation data |
| `lms_quiz_allocations` / `lms_quest_allocations` | Assessment assignments (for unattempted detection) |
| `lms_quiz_questions` / `lms_quest_questions` | Question counts |
| `std_student_academic_sessions` | Student population |
| `std_students` | Student identity |
| `sch_class_sections` | Class-section resolution |
| `sch_subjects` / `slb_lessons` / `slb_topics` | Content hierarchy |
