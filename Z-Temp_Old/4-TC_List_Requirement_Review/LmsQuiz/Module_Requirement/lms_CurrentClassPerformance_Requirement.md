# Current Class Performance — Business Requirements

## What This Screen Does

The Current Class Performance report shows a lesson-by-lesson breakdown of how a class is performing. For each lesson, it shows:

- Which students attempted the quiz
- What scores they got
- **TNA (Taught Not Assessed)** — Students who completed the lesson but haven't attempted the quiz
- **NTA (Not Taught Assessed)** — Students who attempted the quiz but haven't marked the lesson as complete

Think of this as the teacher's "at-a-glance" dashboard during a term — it helps answer: "Are my students keeping up with the lessons? Are they attempting the quizzes?"

---

## When This Screen Is Used

- **Daily Monitoring** — Teachers check which lessons have active quizzes
- **Pre-Class Prep** — Identify which students are falling behind
- **Intervention Planning** — Target specific lessons with low attempt rates
- **Weekly Review** — HODs monitor class-level engagement

## Default Data Load

When the Reports page opens with `active_tab=current-class`:

- **First available class-section** is auto-selected
- **Date range** defaults to last 30 days
- Subject Group and Subject are optional filters
- If no class_section_id provided → first active ClassSection is used
- Students limited to 50 per query (performance safeguard)

---

## Filters Available

| Filter | Behavior |
|--------|----------|
| Class-Section | Required — auto-selects first available |
| Subject Group | Optional |
| Subject | Optional |
| Lesson | Optional |
| Topic Level Type | Optional |
| Topic cascade (4 levels) | Optional |
| Assessment Type | QUIZ/QUEST/Both — default: Both |
| Date Range | Default: last 30 days |

---

## Complete Logic Flow — How the Report Works (Plain Language)

When a teacher opens this report, the system builds a lesson-by-lesson view showing which students attempted which assessments and their scores. The most unique feature is **TNA (Taught Not Assessed)** and **NTA (Not Taught Assessed)** tracking. Think of this as the teacher's at-a-glance dashboard during the term.

### Step 1 — Read the Filters
The system reads what to analyze:
- **Class-Section** (required) — Which class to look at (e.g., "Grade 10-A")
- **Date Range** — Defaults to last 30 days
- **Subject / Lesson / Topic** (optional) — Focus on specific content
- **Assessment Type** — Quizzes, Quests, or Both

### Step 2 — List Students in the Class
The system finds every student currently enrolled in the selected class-section. For performance reasons, it limits to **50 students maximum**.

### Step 3 — Find All Submitted Attempts
The system searches for every quiz and quest attempt from these students that was submitted or timed out within the date range. Each attempt is loaded with its quiz/quest details to determine which lesson and topic it belongs to.

### Step 4 — Find What Was Allocated
The system checks all allocations targeting this class-section. These are the assessments that were SUPPOSED to be attempted.

### Step 5 — Group Attempts by Lesson and Topic
The system organizes all attempts into groups:
- **By lesson** (e.g., "Motion", "Force", "Energy")
- **Within each lesson**, by **topic** (e.g., "Velocity", "Acceleration")
- **Within each topic**, by **student**

This creates a hierarchy: Lessons → Topics → Students → Attempts

### Step 6 — For Each Student, Determine Their Status

For every combination of (Lesson × Student), the system asks:

**"Did this student attempt ANY assessment for this topic?"**

| If the Student... | Then the System... |
|------------------|-------------------|
| **HAS an attempt** | Records their **BEST score** (highest percentage if multiple attempts). Shows the score number (e.g., 85%) |
| **Has NO attempt BUT an assessment was allocated** | Marks them as **TNA — Taught Not Assessed**. The student completed the lesson but didn't take the quiz |
| **Has NO attempt AND no assessment was allocated** | Marks them as **NTA — Not Taught Assessed**. The student took an assessment for a lesson they haven't completed |

### What TNA and NTA Mean (The Key Insight)

| Status | Full Form | Meaning | What Teacher Should Do |
|--------|-----------|---------|----------------------|
| **TNA** | **T**aught **N**ot **A**ssessed | Student completed the lesson but hasn't taken the quiz | Send a reminder to attempt the quiz |
| **NTA** | **N**ot **T**aught **A**ssessed | Student took the quiz but the lesson isn't marked complete | Investigate — did they skip the lesson content? |
| **Score %** | Numeric score | Student attempted AND has a score | Normal — student is on track |

**Real Example:**
> Ravi opens Current Class Performance for Grade 10-A.
> The report shows:
> | Lesson | Arjun | Priya | Aarav | Ravi (student) | Average |
> |--------|-------|-------|-------|-----------------|---------|
> | **Motion** | 85% | 72% | 65% | TNA | 74% |
> | **Force** | 88% | TNA | TNA | 55% | 71% |
> | **Energy** | TNA | TNA | TNA | TNA | — |
>
> Ravi can see:
> - Motion: Most students attempted, good scores. But "Ravi" the student hasn't taken it yet (TNA)
> - Force: Fewer attempted, lower average. Priya and Aarav haven't taken it (TNA)
> - Energy: No one has attempted yet (quiz was just allocated)

### Step 7 — Calculate Summary Stats

| Stat | How It's Calculated |
|------|-------------------|
| **Total Students** | Count of students in the class |
| **TNA Count** | Total number of "Taught Not Assessed" marks across all lessons |
| **NTA Count** | Total number of "Not Taught Assessed" marks |
| **Class Average** | Average of all numeric scores across all lessons and students |

### Step 8 — Best Score Selection
Some students may have attempted the same quiz multiple times. The system always uses the **highest score** for the cell display. This gives the student the benefit of the doubt and shows their best performance.

**Real Example:**
> Aarav attempted "Motion Quiz" twice:
> - First attempt: 65%
> - Second attempt: 90%
> The cell shows **90%** (highest score).

---

## TNA vs NTA Explained

| Status | Meaning | Example |
|--------|---------|---------|
| **TNA** (Taught Not Assessed) | Lesson was completed by student BUT quiz was NOT attempted | Student completed "Motion" lesson but didn't take "Motion Quiz" |
| **NTA** (Not Taught Assessed) | Student attempted the quiz BUT lesson was NOT completed | Student took "Algebra Quiz" but hasn't finished "Algebra" lesson |
| **Score %** | Student attempted AND got a score | Student scored 85% |

---

## Deep Walkthrough — A Teacher's Full Day Using the Report

This section follows **Ravi, a Grade 10 Science teacher**, through a complete real-world session — using the Current Class Performance report to plan his weekly lessons and identify students who need intervention.

---

### Morning: Weekly Lesson Planning (45 Minutes)

**It's Monday morning, March 27th, 7:30 AM.** Ravi is planning this week's lessons for Grade 10-A. He's taught three lessons this term: **Motion** (completed), **Force** (completed), and **Energy** (just started). He opens the **Current Class Performance** report to see how his class is tracking with the assessments.

Ravi selects:
- **Class-Section:** Grade 10-A
- **Date Range:** Last 30 days
- **Subject:** Science
- **Assessment Type:** Quiz

---

### Step 1: The Lesson-by-Lesson Grid Loads

The system shows a table: rows = Lessons, columns = Students, cells = Score or TNA or NTA.

| Lesson | Arjun | Priya | Aarav | Ishaan | Neha | Ananya | Farhan | Kavya | Dev | Rohit | ... (35 more) | **Average** |
|--------|-------|-------|-------|--------|------|--------|--------|-------|-----|-------|--------------|-----------|
| **Motion** | 85% | 72% | 65% | 30% | 95% | TNA | 20% | 42% | 88% | TNA | ... | **67%** |
| **Force** | 88% | TNA | 55% | TNA | 92% | TNA | TNA | TNA | TNA | TNA | ... | **71%** |
| **Energy** | TNA | TNA | TNA | TNA | TNA | TNA | TNA | TNA | TNA | TNA | ... | **—** |

**Ravi's initial reactions:**

| Lesson | Summary |
|--------|---------|
| **Motion** | Mixed — some excellent (Neha 95%, Dev 88%, Arjun 85%), some struggling (Farhan 20%, Ishaan 30%), some didn't attempt (Ananya TNA, Rohit TNA). Average: 67% |
| **Force** | Fewer attempts overall. Many TNAs (Priya, Ishaan, Ananya, Farhan, Kavya, Dev, Rohit — 7 students). Average: 71% (but based on only a few students) |
| **Energy** | 100% TNA — the quiz was just published, no one has attempted yet. Normal. |

---

### Step 2: Understanding TNA vs NTA

**Motion Lesson — Ravi sees 3 "TNA" and 2 "NTA" marks:**

| Student | Status | What It Means |
|---------|--------|---------------|
| Ananya Iyer | **TNA** | Completed Motion lesson but didn't take the quiz |
| Rohit Verma | **TNA** | Completed Motion lesson but didn't take the quiz |
| Vikram Raj | **TNA** | Completed Motion lesson but didn't take the quiz |
| Kavya Nair | **NTA** | Took the quiz but lesson isn't marked complete |
| Farhan Qureshi | **NTA** | Took the quiz but lesson isn't marked complete |

**Ravi thinks:** *"3 TNAs — these students finished the lesson but skipped the quiz. I need to remind them. 2 NTAs — they took the quiz but the lesson isn't marked complete. Either they're behind on lesson content, or there's a tracking issue."*

**Force Lesson — Most students are TNA:**

| Student | Status | What It Means |
|---------|--------|---------------|
| Priya Sharma | TNA | Completed Force lesson, didn't take quiz |
| Ishaan Thakur | TNA | Completed Force lesson, didn't take quiz |
| Ananya Iyer | TNA | Completed Force lesson, didn't take quiz |
| Farhan Qureshi | TNA | Completed Force lesson, didn't take quiz |
| Kavya Nair | TNA | Completed Force lesson, didn't take quiz |
| Dev Patel | TNA | Completed Force lesson, didn't take quiz |
| Rohit Verma | TNA | Completed Force lesson, didn't take quiz |

**Ravi thinks:** *"7 students are TNA for Force lesson — that's a lot. The Force quiz was published 10 days ago. Most students just haven't attempted it yet. I need to send a class-wide reminder."*

---

### Step 3: Analyzing Individual Student Performance

Ravi focuses on specific students:

**Student: Neha Gupta**
| Lesson | Score |
|--------|-------|
| Motion | 95% |
| Force | 92% |
| Energy | — (quiz not yet attempted) |

**Ravi thinks:** *"Neha is consistently excellent — 95% and 92%. She's clearly understanding the material. No action needed — just keep encouraging her."*

---

**Student: Farhan Qureshi**
| Lesson | Score | Status |
|--------|-------|--------|
| Motion | **20%** | Attempted — very low score |
| Force | **—** | TNA — didn't attempt |

**Ravi thinks:** *"Farhan scored only 20% on Motion and didn't even attempt Force at all. This is a red flag. He's either completely lost or disengaged. I need to talk to him today."*

---

**Student: Ishaan Thakur**
| Lesson | Score | Status |
|--------|-------|--------|
| Motion | **30%** | Attempted — low score |
| Force | **—** | TNA — didn't attempt |

**Ravi thinks:** *"Ishaan scored 30% on Motion and is now skipping Force. He's given up. When I reviewed his attempt detail yesterday (in Quiz Summary), I saw he genuinely tried but doesn't understand the concepts. He's not just lazy — he's struggling. I had already planned to assign him remedial work. This confirms my plan."*

---

**Student: Dev Patel**
| Lesson | Score | Status |
|--------|-------|--------|
| Motion | **88%** | Good score |
| Force | **TNA** | Didn't attempt |

**Ravi thinks:** *"Dev scored 88% on Motion — he clearly understands the material. But he's TNA for Force. This isn't a capability issue — he just hasn't gotten around to it. A simple reminder should work."*

---

### Step 4: Class-Wide Patterns

Ravi looks at the **Average row** and **summary stats**:

| Stat | Value | Interpretation |
|------|-------|---------------|
| **Total Students** | 45 | All of Grade 10-A |
| **TNA Count** | 23 | 23 "Taught Not Assessed" marks across all lessons |
| **NTA Count** | 5 | 5 "Not Taught Assessed" marks |
| **Class Average** | 67% | Average of all numeric scores |

**Ravi draws conclusions:**

| Pattern | Evidence | Action |
|---------|----------|--------|
| **TNA is high for Force (7 students)** | Force row has many TNAs | Send class-wide reminder about Force quiz |
| **Some students are TNA across MULTIPLE lessons** | Ananya, Farhan, Rohit are TNA for BOTH Motion and Force | These students need personal follow-up — they're falling behind systematically |
| **Low scorers on Motion also skipped Force** | Farhan (20%) and Ishaan (30%) are both TNA for Force | Low confidence → avoidance cycle. Need intervention, not just reminders |
| **High scorers who skipped** | Dev (88%) is TNA for Force | Just needs a reminder — different approach than struggling students |

---

### Step 5: Ravi's Action Plan

After 30 minutes of analysis, Ravi creates his action list:

| Priority | Student | Issue | Action |
|----------|---------|-------|--------|
| **🔴 High** | **Farhan Qureshi** | 20% on Motion + skipped Force | Personal meeting today. Check if he needs help beyond Science (tutoring?). |
| **🔴 High** | **Ishaan Thakur** | 30% on Motion + skipped Force | Already in progress — assign remedial Velocity quiz |
| **🟡 Medium** | **Ananya Iyer** | TNA on BOTH Motion and Force | Check why she's avoiding all assessments |
| **🟡 Medium** | **Rohit Verma** | TNA on BOTH Motion and Force | Known for missing deadlines — send firm reminder |
| **🟢 Low** | **Dev Patel** | TNA on Force only (scored 88% on Motion) | Just a reminder — capable student |
| **🟢 Low** | **Priya, Kavya, others** | TNA on Force only | Send class-wide reminder today |
| **ℹ️ Info** | **Entire class: Energy** | 100% TNA — newly published | Will remind in class on Wednesday |
| **ℹ️ Monitor** | **2 NTA students** | Kavya, Farhan — took quiz but lesson incomplete | Ask if they need help with lesson content |

---

### Step 6: The Best Score Selection Feature

Ravi notices something interesting. Aarav has **90%** for Motion. But Ravi remembers Aarav took the Motion quiz twice:

- **Attempt 1:** 65% (first try, didn't understand)
- **Attempt 2:** 90% (second try after studying)

The system shows **90%** (the highest score). Ravi thinks: *"The system uses the best score — that's fair. It shows Aarav's true capability after he had a chance to learn from his mistakes. If it showed 65%, I might mistakenly think he's still struggling. This gives me the most accurate picture of their best performance."*

---

### End of Day: Ravi's Summary Report

After teaching his classes, Ravi has taken these actions:

| Time | Action Taken | Based On |
|------|-------------|----------|
| 7:30 AM | Analyzed Current Class Performance report | Full TNA/NTA grid analysis |
| 8:00 AM | Planned weekly lesson adjustments | Identified Force as low-engagement lesson |
| 9:00 AM | Sent class-wide reminder about Force quiz | 7 students TNA for Force |
| 10:30 AM | One-on-one with Farhan Qureshi | He's TNA for Force AND scored 20% on Motion |
| 12:00 PM | Assigned remedial Velocity quiz to Ishaan | Confirmed from report + prior attempt review |
| 3:00 PM | Scheduled catch-up session for Ananya, Rohit | Both are TNA across multiple lessons |

---

### Additional Real-World Scenarios

**SC-005 — Multiple Sections Comparison (Non-Technical)**
Ravi teaches both Grade 10-A and 10-B. He compares:

| Metric | 10-A | 10-B |
|--------|------|------|
| Motion Average | 67% | 75% |
| Force Average | 71% | 68% |
| TNA Count | 23 | 15 |
| NTA Count | 5 | 8 |

**Insight:** 10-B performed better on Motion (75% vs 67%) but has more NTAs (8 vs 5) — meaning 10-B students are attempting quizzes before completing lessons. Ravi might need to emphasize completing lesson content first for 10-B.

**SC-006 — End of Term Review (Non-Technical)**
At term end, Ravi opens the report with a 3-month date range. He sees the full picture:
- Lessons taught: 12
- Each lesson shows student-by-student performance
- TNA/NTA across the entire term
- **Strategic view:** Which lessons had good engagement? Which topics need re-teaching next term?

**SC-007 — Identifying Lesson Gaps (Non-Technical)**
Ravi sees that Lesson "Thermodynamics" has:
- Average: 52% (lowest of all lessons)
- TNA Count: 12 (highest of all lessons)
- **Conclusion:** Thermodynamics was hard — students scored low AND many skipped it. Ravi decides to re-teach this lesson next week with a different approach.

**SC-008 — Spotting NTA anomalies (Non-Technical)**
Ravi sees that for Lesson "Motion", 3 students are marked NTA. But these 3 students have high scores (80-85%). He checks: did they skip the lesson content because they already knew it? Or is there a tracking glitch? He asks the students: "Did you complete the Motion lesson before taking the quiz?"

**SC-009 — Five-Lesson Overview for Principal (Non-Technical)**
Principal Mehta opens the report to check overall class engagement:
- 5 lessons taught this term
- Average TNA rate: 25% (acceptable)
- Average NTA rate: 5% (low — good)
- Average score: 70%
- **Verdict:** Ravi's class is on track. Normal TNA/NTA patterns. No red flags.

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` (tab: `current-class`)
**Data Method:** `generateCurrentClassData(Request)` — private method
**View:** `lmsquiz::reports.partials.current-class`
**Policy:** `tenant.current-class-performance.view`

---

## Dependencies

| Dependency | Details |
|-----------|---------|
| `lms_quiz_quest_attempts` | Student attempt data with scores |
| `lms_quizzes` / `lms_quests` | Assessment-to-lesson mapping via scope_topic_id |
| `lms_quiz_allocations` / `lms_quest_allocations` | Allocation lookup for TNA/NTA resolution |
| `slb_lessons` | Lesson definitions |
| `slb_topics` | Topic hierarchy (lesson → topic link) |
| `std_student_academic_sessions` | Student population per class-section |
| `sch_class_sections` | Class-section filter |
| `sch_subject_groups` | Subject group filter |
