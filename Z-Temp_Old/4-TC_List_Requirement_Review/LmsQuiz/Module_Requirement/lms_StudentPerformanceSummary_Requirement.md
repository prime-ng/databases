# Student Performance Summary — Business Requirements

## What This Screen Does

The Student Performance Summary shows a personalized calendar view of one student's performance across all subjects and assessment types over a selected date range. Think of it as the student's personal scoreboard — for each day of the month, it shows what score they got in each subject.

This helps teachers, parents, and students themselves to:
- See daily assessment activity at a glance
- Identify subjects where the student is strong or weak
- Track improvement or decline over time

---

## When This Screen Is Used

- **Parent-Teacher Meetings** — Show parents their child's progress visually
- **Self-Assessment** — Students track their own performance trends
- **Intervention Planning** — Identify subjects where a student is struggling
- **Weekly Monitoring** — Academic counselors track at-risk students

## Default Data Load

When the Reports page opens with `active_tab=student-summary`:

- **First student with attempts** in the date range is auto-selected (fallback: first enrolled student)
- **Date range** defaults to current month
- **Assessment Type** defaults to Both (QUIZ + QUEST)
- Subject and Subject Group are optional filters

---

## Filters Available

| Filter | Behavior |
|--------|----------|
| Student | Auto-selected (first with attempts) |
| Date Range | Default: current month |
| Assessment Type | QUIZ/QUEST/Both — default: Both |
| Subject | Optional — filter by subject |
| Subject Group | Optional — filter by group |

---

## Complete Logic Flow — How the Report Works (Plain Language)

When a teacher or parent opens this report, the system builds a personalized calendar showing one student's daily performance in every subject. Think of it as the student's personal scoreboard for the month.

### Step 1 — Read the Filters
The system reads who and what to look at:
- **Student** (required) — Which student's report to show (defaults to first student with attempts)
- **Date Range** — Which month to show (defaults to current month)
- **Assessment Type** — Quizzes, Quests, or Both (default: Both)
- **Subject** (optional) — Focus on a specific subject

### Step 2 — Build the Calendar
The system creates a list of every day in the selected month. Each day is labeled (e.g., March 1, March 2, etc.).

### Step 3 — Find What Subjects This Student Studies
The system loads all active subjects available to this student. These will become the rows in the calendar grid.

### Step 4 — Find All of the Student's Attempts
The system searches for every quiz and quest this student has submitted or timed out on during the month:
- Loads each attempt with the full details: which quiz/quest, which subject, what answers were given, what was correct/wrong
- Also loads the actual quiz/quest data (title, lesson, topic)

### Step 5 — Find What Was Assigned to This Student
The system checks all allocations that target this student:
- **CLASS allocations** — Any quiz assigned to the student's entire class (e.g., "Grade 10-A")
- **SECTION allocations** — Any quiz assigned to the student's specific section
- **STUDENT allocations** — Any quiz assigned directly to this student

This helps determine: "Was this subject supposed to have an assessment on this day?"

### Step 6 — Build the Calendar Grid (The Main Work)

Now the system assembles the grid. For **each** assessment type tab, **each** subject, and **each** day:

**It asks:** "Was this subject assigned to the student on this day?"
- Check: Did any allocation exist where `published_at ≤ this day ≤ due_date` for this subject?

| Scenario | What Happens |
|----------|-------------|
| Subject was assigned AND student attempted | Show score, correct/wrong/unattempted counts |
| Subject was assigned BUT student didn't attempt | Show 0 — student missed it |
| Subject was NOT assigned that day | Show nothing — no assessment existed |

**Real Example — One Subject Row:**
> Subject: Science
> - March 2: Score 75% (attempted)
> - March 9: Score 82% (attempted)
> - March 14: 0 (assigned but didn't attempt)
> - March 16: Nothing (no assignment that day)
> - March 21: Score 68% (attempted)

### Step 7 — Ghost Rescue (Handle Deleted Content)
Sometimes a quiz or quest gets deleted from the database but the student's attempt record still exists. The system catches these and shows them in a special row labeled **"Ghost / Deleted Content"** — the score is still visible even if the original assessment is gone.

### Step 8 — Compute Daily Averages
For each day, the system calculates the student's average score across all subjects. This gives at-a-glance trend: "Is the student improving or declining?"

### What the Report Looks Like
- **Two tabs** at the top: "Quiz - Homework" and "Assessment"
- **Within each tab**: Rows = Subjects, Columns = Days of the month
- Each cell shows one of: Score %, "0" (missed), or empty (not assigned)
- Bottom row shows **daily average**

**Real Example:**
> Teacher opens March 2026 for student Priya:
> - **Quiz - Homework tab:**
>   - **Science row:** Mar 2: 75%, Mar 9: 82%, Mar 16: 68% — steady performance
>   - **Math row:** Mar 4: 90%, Mar 11: 85% — strong
>   - **English row:** Mar 6: 55%, Mar 13: 60% — needs improvement
> - **Assessment tab:**
>   - **Science row:** Mar 10: 78%
> - **Overall Average row:** 74%
>
> Teacher can see Priya is strong in Math (85-90%) but struggling in English (55-60%).

---

## The Matrix Helper: `calculateStudentMatrixRow()`

For a given subject + assessment type combination:

```
For EACH day:
  1. Is the subject assigned? (check allocations for date range overlap)
  2. If assigned → 1, else → 0
  3. Find attempts for this day + subject + type
  4. If attempts exist:
     - total_ques = sum of all question counts
     - correct = sum of correct answers
     - wrong = total_answers - correct
     - not_attempted = max(0, total_ques - total_answers)
     - score = mean of percentages (divided by 100)
  5. If no attempts → all zeros
```

---

## Deep Walkthrough — A Teacher's Full Day Using the Report

This section follows **Ravi, a Grade 10 Science teacher**, through a complete real-world session — reviewing a struggling student's performance to plan intervention.

---

### Morning: Checking a Student's Monthly Progress (15 Minutes)

**It's Wednesday morning, 8:00 AM.** Ravi is concerned about **Priya Sharma**. She's been quiet in class lately, and her last quiz score was low. He opens the **Student Performance Summary** and selects:
- **Student:** Priya Sharma (Grade 10-A)
- **Month:** March 2026
- **Assessment Type:** Both

---

### Step 1: The Calendar Grid Loads

The system shows a color-coded calendar with rows for each subject and columns for each day of March.

**Quiz - Homework tab:**

```
              Mar 1  Mar 2  Mar 3  Mar 4  Mar 5  Mar 6  Mar 7  Mar 8  Mar 9  Mar 10  Mar 11  Mar 12 ...
              Mon    Tue    Wed    Thu    Fri    Sat    Sun    Mon    Tue    Wed     Thu     Fri
Science       75%            82%           68%                                       78%
Math                       90%                             85%
English                          55%                                      60%
History                                                                                            45%
All Avg       75%     —     86%    82%    68%     —      —     85%    60%     78%     —       45%
```

(Empty = no assessment assigned that day, 0% = assigned but not attempted)

**Ravi's first impression:** *"Priya is doing well in Math (85-90%), okay in Science (68-82%), but struggling in English (55-60%). History she only attempted once. Let me dig deeper."*

---

### Step 2: Analyzing the Science Row

Ravi focuses on **Science** since that's his subject:

| Day | Score | What Happened |
|-----|-------|--------------|
| Mar 2 (Mon) | **75%** | "Motion — Basics" quiz. 15/20. Good start |
| Mar 4 (Wed) | **82%** | "Motion — Graphs" quiz. 16.5/20. Improving |
| Mar 6 (Fri) | **68%** | "Velocity — Calculations" quiz. 13.6/20. Dropped! |
| Mar 10 (Tue) | **78%** | "Acceleration" quiz. 15.6/20. Recovered somewhat |

**Ravi's observation:** *"Priya's Science scores trended: 75% → 82% → 68% → 78%. She dropped on the Velocity Calculations quiz (68%). That's the same topic where the whole class struggled. But she recovered on Acceleration (78%). She's capable — she just had trouble with that one topic."*

**Ravi clicks on March 6 cell** to see more detail:

| Detail | Value |
|--------|-------|
| **Quiz** | "Velocity — Calculations" |
| **Score** | 68% (13.6/20) |
| **Correct** | 7 out of 10 questions |
| **Wrong** | 2 |
| **Unattempted** | 1 |
| **Time Taken** | 22 min |

**Ravi thinks:** *"She got 7 out of 10 correct. The 3 she missed were the numerical problems (speed = distance/time calculations). She got the theory questions right. So she understands the concept but struggles with the math. That's a specific, fixable problem."*

---

### Step 3: Comparing Subjects — Spotting the Real Problem

Ravi looks at the **Math row:**

| Day | Score | Assessment |
|-----|-------|-----------|
| Mar 4 (Wed) | **90%** | "Algebra — Linear Equations" |
| Mar 11 (Wed) | **85%** | "Algebra — Quadratic Equations" |

**Ravi thinks:** *"Math scores are 85-90%. Priya is clearly strong in Math. She can do calculations. So her struggle with Velocity Calculations isn't a math problem — it's a physics problem. She doesn't understand the physics concepts enough to apply the math correctly."*

Now Ravi looks at the **English row:**

| Day | Score | Assessment |
|-----|-------|-----------|
| Mar 6 (Fri) | **55%** | "Grammar — Tenses" |
| Mar 13 (Fri) | **60%** | "Grammar — Active/Passive Voice" |

**Ravi thinks:** *"English is consistently low — 55-60%. This isn't a one-time issue. She's struggling with English Grammar specifically. And her English scores are trending slightly up (55% → 60%), so she might be improving."*

---

### Step 4: Checking the "Assessment" Tab

Ravi switches to the **Assessment tab** (this shows project-based quests, not quizzes):

```
              Mar 10
Science       78%
```

**Ravi thinks:** *"Only one quest assessment in Science — 78%. That's consistent with her quiz performance. She attempted it, which is good."*

---

### Step 5: The Overall Average Trend

Ravi looks at the **All Avg row** across the month:

| Week 1 | Week 2 | Week 3 | Week 4 |
|--------|--------|--------|--------|
| 75% | 82% | 68% | 78% |

**Ravi's conclusion:** *"The overall trend is relatively stable (68-82%). There's no sharp decline. The 68% dip in Week 3 was the Velocity Calculations quiz which was hard for everyone. Priya recovered in Week 4. She's not in crisis — she just needs targeted help on application-based problems."*

---

### Step 6: Ghost Content Discovery

Ravi notices a row at the bottom:

```
Ghost / Deleted Content
    Mar 15: Score 45% — Subject: N/A, Lesson: N/A
```

**Ravi thinks:** *"What's this? A 45% score but no subject or lesson name?"*

He clicks the cell. A popup explains: *"This attempt was linked to a quiz that has been deleted from the system. The attempt data (score, answers) is preserved, but the quiz title and subject information are no longer available."*

**Ravi's conclusion:** *"This must be an old quiz from last term that got cleaned up. Priya scored 45% on it. Since I can't tell what subject it was for, I'll record it but not act on it. Good to know the system preserves historical data even after cleanup."*

---

### Step 7: Ravi's Full Assessment of Priya

After 15 minutes of analysis, Ravi has a complete picture:

| Subject | Strength | Weakness | Trend | Action |
|---------|----------|----------|-------|--------|
| **Science** | Theory questions (75-82%) | Numerical/calculation problems (68%) | Stable → improving | Assign "Velocity Calculations Practice" quiz |
| **Math** | Strong (85-90%) | — | Excellent | Challenge with harder problems |
| **English** | — | Grammar (55-60%) | Slowly improving | Coordinate with English teacher |
| **History** | Only 1 attempt (45%) | Lack of engagement | Unknown | Check if she's keeping up |
| **Ghost** | N/A | N/A | N/A | Ignore — old data |

**Ravi's action plan for Priya:**
1. **Tomorrow:** Give Priya the "Velocity Calculations Practice" quiz (5 questions, unlimited attempts) during free period
2. **This week:** Check her score, if still below 70%, schedule a 10-minute one-on-one
3. **Coordinate:** Email the English teacher about Priya's grammar struggles
4. **Next month:** Re-run this report to see if scores improved

**Ravi documents his notes:** *"Priya Sharma — March Summary: Capable student (Math 85-90%), Science is good but needs practice with numerical application. English is a concern. Will provide targeted velocity practice and check back in April."*

---

### Additional Real-World Scenarios

**SC-004 — Student in Decline (Non-Technical)**
Teacher checks student "Arjun" and sees:
- Week 1: 92%, Week 2: 85%, Week 3: 70%, Week 4: 55%
- **Trend:** Sharp decline across all subjects
- **Action:** Immediate parent-teacher conference — something is wrong at home or with health

**SC-005 — Student Missing Multiple Assessments (Non-Technical)**
Teacher checks student "Rohit" for March:
- March 2: 0% (assigned, didn't attempt)
- March 5: 0%
- March 9: 0%
- March 12: 45%
- March 16: 0%
- **Pattern:** Rohit attempted only 1 out of 5 assigned quizzes
- **Action:** Find out why — is he aware of assignments? Technical issues? Personal problems?

**SC-006 — Student with Perfect Attendance (Non-Technical)**
Teacher checks student "Neha" for March:
- Every assigned cell has a score (no 0% cells)
- Scores range from 78% to 95%
- **Conclusion:** Neha is consistent, hardworking, and performing well across subjects
- **Action:** Recognize her effort, consider enrichment material

**SC-007 — Subject Filter Drill-Down (Non-Technical)**
Teacher filters by **Subject: Science only, Assessment Type: Quiz**. The grid now shows ONLY the Science row. This helps focus on one subject without distraction. Teacher sees the student attempted 4 Science quizzes, scored 68-82%, and the struggling topic is Velocity Calculations.

**SC-008 — Comparing Two Students Side by Side (Non-Technical)**
Teacher opens Priya's report, notes her scores. Then changes to Aarav. Comparison:
- **Priya:** Science avg 76%, Math 88%, English 58%
- **Aarav:** Science avg 90%, Math 82%, English 75%
- **Insight:** Priya is stronger in Math, Aarav is stronger in Science. Both have different strengths. Teacher can pair them as study buddies.

**SC-009 — End-of-Month Summary (Non-Technical)**
Teacher runs report for all students one by one before parent-teacher meetings. For each student, notes:
- Overall average
- Subjects above/below average
- Trends (improving/declining/stable)
- Action items
- This becomes the data pack for parent conversations

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` (tab: `student-summary`)
**Data Method:** `generateStudentSummaryData(Request)` — private method
**Helper:** `calculateStudentMatrixRow()` — builds daily metrics per subject
**View:** `lmsquiz::reports.partials.student-summary`
**Policy:** `tenant.student-performance-summary.view`

---

## Dependencies

| Dependency | Details |
|-----------|---------|
| `lms_quiz_quest_attempts` | Student attempt records |
| `lms_quiz_quest_attempt_answers` | Per-question correct/wrong counts |
| `lms_quiz_allocations` / `lms_quest_allocations` | Allocation resolution per student |
| `std_student_academic_sessions` | Student class-section context |
| `lms_quiz_questions` / `lms_quest_questions` | Question count per assessment |
| `sch_subjects` | Subject definitions for matrix rows |
| `sch_subject_groups` | Subject group filter |
