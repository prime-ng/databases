# Class Performance Report — Business Requirements

## What This Screen Does

The Class Performance Report shows how every student in a class performed on quizzes and assessments over a date range. It's the main tool for teachers and coordinators to see:

- Which students attempted the assessment vs who didn't
- Each student's score and performance category (Outstanding/Good/Satisfactory/Needs Attention/Struggling)
- Class averages, highest/lowest scores, and correct/wrong answer totals

Think of it as a class report card that summarizes all quiz and quest activity for a selected period.

---

## When This Screen Is Used

- **End-of-Term Review** — HODs evaluate class-level performance
- **Weekly Monitoring** — Coordinators track engagement rates
- **Parent-Teacher Meeting Prep** — Generate class-wide performance summaries
- **Intervention Planning** — Identify struggling students across a class

## Default Data Load

This screen loads when the Reports page opens with `active_tab=class-performance`:

- **First available class-section** is auto-selected
- **Date range** defaults to last 30 days
- Data loads via AJAX when the tab becomes active
- If no `class_section_id` in the request, the first active ClassSection is auto-selected
- If no `date_from`, defaults to 30 days ago
- If no `date_to`, defaults to today

---

## Filters Available

| Filter | Source | Behavior |
|--------|--------|----------|
| Class-Section | ClassSection dropdown | Required — scopes students |
| Subject Group | SubjectGroup for class | Optional |
| Subject | Via SubjectStudyFormat | Optional — cascaded from class |
| Assessment Type | QUIZ/QUEST/Both | Default: Both |
| Quiz | Specific quiz dropdown | Optional |
| Lesson | Cascaded from subject | Optional |
| Topic cascade (4 levels) | Topic hierarchy | Optional |
| Date Range | Date picker | Default: last 30 days |

---

## Complete Logic Flow — How the Report Works (Plain Language)

When a teacher selects a class and clicks "Generate Report," the system follows this process to build every number you see.

### Step 1 — Read the Teacher's Filter Choices
The system reads what the teacher selected:
- **Class-Section** (required) — Which class to look at (e.g., "Grade 10-A")
- **Date Range** — Which dates to cover (defaults to last 30 days)
- **Subject / Lesson / Topic** (optional) — Limit to specific subjects or topics
- **Assessment Type** (optional) — Show only quizzes, only quests, or both

### Step 2 — List Out All Students in That Class
The system finds every student currently enrolled in the selected class-section. These are the students whose performance we're about to check.

**Real Example:**
> Ravi selects "Grade 10-A" → System finds 45 students enrolled in Grade 10-A

### Step 3 — Find All Submitted Attempts
The system searches for every student attempt (quiz or quest) that:
- Was **submitted** or **timed out** (not "in progress" — those are incomplete)
- Was submitted **within the date range**
- Belongs to one of the 45 students
- Matches the optional filters (subject, lesson, topic, etc.)

For each attempt, the system also counts: how many answers were given, and how many were correct.

### Step 4 — Apply Optional Filters
If the teacher selected additional filters, the system narrows down:

| If Teacher Selected... | System Does... |
|------------------------|---------------|
| Subject = "Science" | Only shows attempts on Science quizzes/quests |
| Lesson = "Motion" | Only shows attempts on Motion-related assessments |
| Topic = "Velocity" | Only shows attempts scoped to the Velocity topic |
| Quiz = "Science Quiz 1" | Only shows attempts on that specific quiz |

### Step 5 — Group Attempts by Student
The system organizes all the attempt data by student. Each student can have multiple attempts, but for the summary report, the system works with their **latest** attempt.

### Step 6 — For Each Student, Record Their Performance
The system goes through the list of 45 students one by one:

**If a student has NO attempts:**
→ Shows "No" for attempted, all scores are 0, category is "Struggling"

**If a student HAS attempts:**
→ Uses their **latest attempt** (most recent submission)
→ Calculates:
  - **Correct answers** — How many questions they got right
  - **Wrong answers** — How many they got wrong
  - **Not attempted** — How many they left blank
  - **Score percentage** — Their final score (e.g., 85%)
→ Assigns a **Category**:
  - **Outstanding** (≥85%) — Excellent
  - **Good** (70-84%) — Above average
  - **Satisfactory** (50-69%) — Meets expectations
  - **Needs Attention** (35-49%) — Below average
  - **Struggling** (<35%) — Needs help

### Step 7 — Calculate Class-Wide Numbers
After processing every student, the system computes the "big picture" numbers:

| Metric | How It's Calculated |
|--------|-------------------|
| **Total Students** | Count of all 45 students |
| **Attempted** | Students with at least one attempt |
| **Not Attempted** | Students with zero attempts (45 − attempted) |
| **Class Average** | Average score of all students who attempted |
| **Highest Score** | Best score in the class |
| **Lowest Score** | Worst score in the class |
| **Category Counts** | How many students in each category (e.g., 8 Outstanding, 12 Good, etc.) |

### Step 8 — Show Results
The system displays:
- **Metric Cards** at the top — Quick overview numbers
- **Student Table** below — One row per student, sorted by name, 15 per page
- Each row shows: student name, whether they attempted, their score, correct/wrong/unattempted counts, and category

**Real Example:**
> Ravi generates the report for Grade 10-A (last 30 days):
> - Total Students: 45, Attempted: 38, Not Attempted: 7
> - Class Average: 72%, Highest: 98%, Lowest: 15%
> - Total Questions: 760, Correct: 580, Wrong: 120, Not Attempted: 60
> - 8 Outstanding, 12 Good, 12 Satisfactory, 4 Needs Attention, 2 Struggling
>
> Ravi scrolls the student table and finds 7 students with "No" in attempted column. He can click any student's name to drill into their detailed attempt.

---

## Metric Cards Explained

| Metric | How It's Computed |
|--------|-------------------|
| **Total Students** | Students in class-section (or total attempters if no class selected) |
| **Attempted** | Rows where attempted=Yes |
| **Not Attempted** | Rows where attempted=No |
| **Class Average** | Avg of all attempted student scores |
| **Highest Score** | Max score among attempted students |
| **Lowest Score** | Min score among attempted students |
| **Total Questions** | Sum of total_ques across all rows |
| **Total Correct/Wrong/Not Attempted** | Sum across all rows |

---

## Deep Walkthrough — A Teacher's Full Day Using the Report

This section follows **Ravi, a Grade 10 Science teacher**, through a complete real-world session — from opening the report to taking action on specific students.

---

### Morning: Class Performance Review (30 Minutes Before Class)

**It's Tuesday morning, 7:45 AM.** Ravi has a free period before his first class. He wants to check how Grade 10-A is performing overall before planning this week's lessons.

Ravi opens the Reports page → selects **Class Performance Report** tab → picks:
- **Class-Section:** Grade 10-A
- **Date Range:** Last 30 days
- **Assessment Type:** Both (Quizzes + Quests)

The system loads the report.

---

### Step 1: Reading the Metric Cards

At the top of the page, Ravi sees six stat cards:

| Metric Card | Value | What It Tells Ravi |
|-------------|-------|-------------------|
| **Total Students** | 45 | All students in Grade 10-A |
| **Attempted** | 38 | 38 out of 45 submitted at least one assessment |
| **Not Attempted** | 7 | 7 students have ZERO submissions in 30 days |
| **Class Average** | 72% | Decent — but room for improvement |
| **Highest Score** | 98% | Someone (probably Arjun or Priya) aced everything |
| **Lowest Score** | 15% | Someone is struggling badly |

**Ravi thinks:** *"72% average is okay but not great. Last term it was 78%. 7 students haven't attempted anything in 30 days — that's a red flag. And someone scored 15% — that student needs immediate help."*

---

### Step 2: Analyzing the Score Distribution

Ravi looks at the bar chart:

```
Students
  ^
12 |    ██
10 |    ██  ██
 8 |    ██  ██  ██
 6 | ██ ██  ██  ██  ██
 4 | ██ ██  ██  ██  ██
 2 | ██ ██  ██  ██  ██  ██
   +--------------------------------→
    0-20% 21-40% 41-60% 61-80% 81-100%
```

Breakdown:
| Category | Count | Score % | Ravi's Interpretation |
|----------|-------|---------|----------------------|
| **Outstanding** | 8 | ≥85% | Top students — Arjun, Priya, Neha are here |
| **Good** | 12 | 70-84% | Solid performers — on track |
| **Satisfactory** | 12 | 50-69% | Average — could improve with more practice |
| **Needs Attention** | 4 | 35-49% | Below average — these students need intervention |
| **Struggling** | 2 | <35% | Critical — these students need immediate help |

**Ravi thinks:** *"The chart is right-heavy — most students are in Good + Satisfactory. That's good. But 6 students below 40% is concerning. Let me find out who they are."*

---

### Step 3: Finding the Struggling Students

Ravi scrolls down to the student table and looks at the 2 "Struggling" students:

| Student | Score | Correct | Wrong | Unattempted | Time Taken |
|---------|-------|---------|-------|-------------|------------|
| Ananya Iyer | 15% | 3 | 12 | 5 | 7 min |
| Farhan Qureshi | 20% | 4 | 11 | 5 | 10 min |

**Ravi thinks:** *"Ananya scored 15% and spent only 7 minutes — she rushed through without trying. Farhan spent 10 minutes and got 20% — slightly better but still terrible. Both left 5 questions blank."*

**Ravi's action:** He clicks Ananya's name to view her attempt detail. The system shows:
- **Quiz:** Science Quiz 1 (Motion)
- **Score:** 3/20 — only 3 correct answers
- **Time:** 7 minutes for a 20-question quiz (that's 21 seconds per question!)
- **Answers:** She selected random options — almost all wrong

**Ravi's conclusion:** *"Ananya didn't even try. She clicked through randomly. I need to talk to her separately. Farhan at least spent 10 minutes — he attempted more questions but doesn't know the material."*

---

### Step 4: Finding the Non-Starters

Ravi filters the student table by "Not Attempted." The system shows 7 students:

| Student | Status | Notes |
|---------|--------|-------|
| Aarav Sharma | Not Attempted | Usually a good student — surprised |
| Dev Patel | Not Attempted | Known for missing deadlines |
| Kavya Nair | Not Attempted | Was absent for 2 weeks (medical) |
| Meera Joshi | Not Attempted | Usually responsible — possible issue |
| Rohit Verma | Not Attempted | Always late |
| Sneha Kapoor | Not Attempted | Transferred in mid-month |
| Vikram Raj | Not Attempted | Was on school trip |

**Ravi categorizes them:**
| Priority | Students | Action |
|----------|----------|--------|
| **Urgent — investigate** | Aarav, Meera | These are normally good students. Something might be wrong |
| **Expected** | Dev, Rohit, Vikram | Known issues — just send reminders |
| **Excused** | Kavya (medical), Sneha (new) | Special circumstances — will follow up separately |

**Ravi's action:** He sends a message to all 7: *"Science Quiz 1 deadline has passed. Please submit by end of week or speak to me."* He makes a mental note to check on Aarav personally.

---

### Step 5: Filtering by Subject — Deep Dive into "Motion"

Ravi wants to understand how the class performed on the **Motion** chapter specifically. He applies filters:
- **Subject:** Science
- **Lesson:** Motion

The report reloads:

| Metric | Before (All) | After (Motion Only) | Change |
|--------|-------------|--------------------|--------|
| Total Students | 45 | 45 | Same |
| Attempted | 38 | 32 | 6 students attempted other subjects but not Motion |
| Class Average | 72% | **65%** | **Dropped 7 points** |
| Highest | 98% | 92% | Still good |
| Lowest | 15% | 15% | Same struggling student |

**Score Distribution for Motion only:**

| Category | Count | Change from Overall |
|----------|-------|-------------------|
| Outstanding | 4 | Down from 8 — fewer top scores |
| Good | 8 | Down from 12 |
| Satisfactory | 14 | Up from 12 — more students bunched here |
| Needs Attention | 4 | Same |
| Struggling | 2 | Same |

**Ravi thinks:** *"The class average dropped from 72% to 65% for Motion. That's significant. More students are in the 'Satisfactory' range — they got the basics but not the hard questions. The Motion chapter has numerical problems (speed, velocity, acceleration calculations) that are harder than the theory questions in other chapters."*

**Ravi's conclusion:** *"I need to spend extra time on Motion this week. Specifically, I should go over velocity-time graph problems and relative velocity calculations — those were clearly the hard spots."*

---

### Step 6: Topic Cascade Drill-Down

Ravi wants to pinpoint exactly which sub-topic caused the problem. He drills into:
**Topic: Motion → Sub-Topic: Velocity → Micro-Topic: Calculations**

New average for **Velocity - Calculations only**: **58%**

| Category | Count |
|----------|-------|
| Outstanding | 2 |
| Good | 5 |
| Satisfactory | 15 |
| Needs Attention | 8 |
| Struggling | 2 |

**Ravi thinks:** *"58% average for velocity calculations — that's the problem area. 10 students scored below 50% on calculation questions specifically. The theory questions (definition of velocity, units) were fine. But when they had to actually calculate speed from distance/time graphs, they struggled."*

**Ravi's action plan:**
1. **Tomorrow's class:** 20-minute refresher on velocity-time graphs
2. **Create a practice quiz:** "Velocity Calculations Practice" — 5 numerical problems, unlimited attempts
3. **Assign the practice quiz** to all 10 students who scored below 50%
4. **One-on-one:** Schedule Ananya and Farhan for after-school help

---

### Step 7: Checking Subject Group Performance

Ravi's school has subject groups. He wants to compare Science with other subjects:

He selects **Subject Group: Sciences** (includes Physics, Chemistry, Biology):

| Subject | Students | Attempted | Avg Score |
|---------|----------|-----------|-----------|
| Physics (Science) | 45 | 38 | 68% |
| Chemistry | 42 | 35 | 74% |
| Biology | 42 | 40 | 78% |

**Ravi thinks:** *"Physics has the lowest average at 68%. Biology is highest at 78%. That makes sense — Biology is more memorization, Physics requires problem-solving. But 68% is lower than I'd like. I need to focus on the numerical problem-solving aspect."*

---

### End of Day: Ravi's Full Summary

After 45 minutes of analysis, Ravi has:

| Issue Found | How He Found It | Action Taken |
|-------------|----------------|--------------|
| 7 students with zero attempts in 30 days | Metric Cards → Not Attempted count | Sent reminder message |
| Aarav & Meera (good students) among non-starters | Sorted Not Attempted table | Will talk to them personally |
| Ananya scored 15% in 7 min (random clicks) | Clicked her name → attempt detail | Schedule after-school meeting |
| Farhan scored 20% in 10 min (tried but failed) | Clicked his name → attempt detail | Assign remedial practice quiz |
| Motion chapter avg dropped to 65% | Filtered by Lesson = Motion | Plan revision class on Thursday |
| Velocity Calculations avg dropped to 58% | Drilled into Topic cascade | Create "Velocity Calculations Practice" quiz |
| Physics has lowest avg (68%) vs Biology (78%) | Subject Group filter | Focus more class time on numerical problems |

**Ravi's overall feeling:** *"The Class Performance Report showed me exactly where to focus. Instead of guessing why the class average dropped, I found the root cause in 45 minutes: Velocity Calculations. Tomorrow I have a clear plan."*

---

### Additional Real-World Scenarios

**SC-005 — Multiple Assessment Types (Non-Technical)**
Ravi selects **Assessment Type: Quests Only** (the project-based assessments, not quizzes). The report shows only Quest data:
- Attempted: 12 students (out of 45)
- Average: 82%
- Ravi realizes quizzes have higher engagement (38/45) than quests (12/45). He needs to remind students about pending quest assignments.

**SC-006 — Date Range Comparison (Non-Technical)**
Ravi compares two periods:
- **Last 30 days:** 72% average, 38/45 attempted
- **Previous 30 days:** 78% average, 42/45 attempted
- The class is declining in both engagement and scores. Ravi investigates what changed.

**SC-007 — Empty State (Start of Term)**
At the beginning of the term, Ravi opens the report and sees:
- All metrics show 0 or empty
- Score distribution chart shows "No data available"
- Student table is empty
- **Reason:** No quizzes or quests have been assigned yet this term. The report needs data to display.

**SC-008 — Class Without Filter**
Ravi doesn't select any class-section. The system auto-selects the first available class. If Ravi has access to multiple classes (e.g., Grade 10-A and 10-B), he can switch between them using the Class-Section filter to compare performance across his classes.

---

## Performance Category Thresholds

| Category | Score % | Meaning |
|----------|---------|---------|
| Outstanding | ≥85 | Student excelled |
| Good | 70-84 | Above average |
| Satisfactory | 50-69 | Meets expectations |
| Needs Attention | 35-49 | Below average |
| Struggling | <35 | Requires intervention |

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` (tab: `class-performance`)
**Data Method:** `generateReportData(Request)` — private method
**View:** `lmsquiz::reports.partials.class-performance`
**Policy:** `tenant.class-performance-report.view`

The report only loads data via AJAX. On initial page load, empty metrics are shown (all zeros, empty paginator).

---

## Dependencies

| Dependency | Details |
|-----------|---------|
| `lms_quiz_quest_attempts` | Primary — attempt records with status, submitted_at, percentage |
| `lms_quiz_quest_attempt_answers` | withCount for correct/wrong counts |
| `lms_quiz_questions` | Question count per quiz |
| `std_student_academic_sessions` | Student population by class-section |
| `sch_class_sections` | Class-section filter + cascade |
| `sch_subject_groups` | Subject group filter |
| `slb_lessons` / `slb_topics` | Topic hierarchy filter |
| `lms_quizzes` / `lms_quests` | Assessment metadata (subject_id, scope_topic_id) |
