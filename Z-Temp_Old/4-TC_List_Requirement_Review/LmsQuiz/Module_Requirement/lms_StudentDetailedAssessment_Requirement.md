# Student Detailed Assessment — Business Requirements

## What This Screen Does

The Student Detailed Assessment shows a complete list of every assessment a student has attempted, organized by performance categories. Think of it as the student's full assessment portfolio — every quiz and quest they've taken, with scores, subjects, lessons, and time taken.

The report groups attempts into categories:
- **Outstanding** (≥85%) — Top performers
- **Good** (70-84%) — Above average
- **Satisfactory** (50-69%) — Meets expectations
- **Needs Attention** (35-49%) — Below average
- **Struggling** (<35%) — Needs intervention

---

## When This Screen Is Used

- **Detailed Student Evaluation** — Before parent meetings, get a complete picture
- **Remedial Planning** — Identify specific weak areas across subjects
- **Academic Intervention** — Counselors review at-risk students
- **Portfolio Building** — Compile a student's assessment history

## Default Data Load

When the Reports page opens with `active_tab=student-detailed`:

- **First active student** is auto-selected
- **Date range** defaults to last 30 days
- **Class** is auto-resolved from student's current academic session
- Section, Subject, Subject Group, Lesson, Topic cascade are optional filters

---

## Filters Available

| Filter | Behavior |
|--------|----------|
| Student | Required — auto-selects first active student |
| Date Range | Default: last 30 days |
| Assessment Type | QUIZ/QUEST/Both — default: Both |
| Subject Group | Optional |
| Subject | Optional |
| Lesson | Optional |
| Topic Type | Optional (by topic_level_type_id) |
| Topic cascade (4 levels) | Optional |
| Search | By assessment title or subject |

---

## Complete Logic Flow — How the Report Works (Plain Language)

When a teacher opens this report, the system builds the student's complete assessment portfolio — every quiz and quest they've taken, sorted by performance category. Think of it as the student's full report card showing how they did on each individual assessment.

### Step 1 — Read the Filters
The system reads who and what to look at:
- **Student** (required) — Which student's portfolio to show
- **Date Range** — How far back to look (defaults to last 30 days)
- **Subject / Lesson / Topic** (optional) — Focus on specific content
- **Assessment Type** — Quizzes, Quests, or Both

### Step 2 — Find All of the Student's Attempts
The system searches for every quiz and quest this student has submitted or timed out on. For each attempt, it loads:
- The **result** (score, percentage)
- The **answers** (to count correct/wrong)
- The **quiz or quest details** (title, subject, lesson, topic)

### Step 3 — Apply Filters
If the teacher selected specific subjects, lessons, or topics, the system limits results to matching attempts only.

### Step 4 — Two Separate Data Sets
The system does TWO queries:

1. **Paginated** (first 15 attempts for the table) — Shows in a scrollable table
2. **All attempts** (unlimited) — Used to calculate the category distribution cards at the top

### Step 5 — Calculate Class Averages
For each unique quiz or quest, the system calculates the **class average** (the average score of ALL students who took that assessment). This lets the teacher compare: "Did this student do better or worse than the rest of the class?"

**Real Example:**
> Student Aarav scored 90% on "Science Quiz 1"
> The class average for "Science Quiz 1" was 72%
> Aarav scored 18 points above class average → He's excelling in this topic

### Step 6 — Ghost Rescue (Handle Deleted Content)
Sometimes a quiz or quest was deleted from the database but the student's attempt still exists. The system pre-fetches any trashed/deleted quizzes or quests so it can still show:
- **Subject:** "Unassigned" (if it can't be determined from remaining data)
- **Lesson:** "N/A"
- **Topic:** "Ghost / Missing Content"
- **Score:** Still shown (attempt data is preserved)

### Step 7 — Sort Every Attempt Into a Performance Category
The system goes through every attempt and assigns it to one of five buckets:

| Category | Score % | Meaning | What Teacher Does |
|----------|---------|---------|-------------------|
| **Outstanding** | ≥85% | Student excelled | Praise and challenge further |
| **Good** | 70-84% | Above average | Keep up the good work |
| **Satisfactory** | 50-69% | Meets expectations | Room for improvement |
| **Needs Attention** | 35-49% | Below average | Schedule intervention |
| **Struggling** | <35% | Needs help | Urgent remediation needed |

**Real Example:**
> Student Arjun's portfolio:
> - **Outstanding (≥85%):** 5 attempts — Science Quiz (92%), Math Quest (88%), etc.
> - **Good (70-84%):** 8 attempts
> - **Satisfactory (50-69%):** 4 attempts
> - **Needs Attention (35-49%):** 2 attempts — English Quiz (42%), History Quest (38%)
> - **Struggling (<35%):** 1 attempt — Physics Quest (22%)

### Step 8 — The Detailed Table
Each row in the paginated table shows:

| Column | Example |
|--------|---------|
| **Date** | Mar 15, 2026 |
| **Type** | Quiz |
| **Assessment Title** | "Motion - Chapter Quiz" |
| **Subject / Lesson / Topic** | Science / Motion / Velocity |
| **Marks** | 18/20 (90%) |
| **Category** | Outstanding |
| **Class Average** | 72% |
| **Time Taken** | 25 min |

**Real Example of Using the Report:**
> Teacher opens Detailed Assessment for Arjun for last 30 days.
> *Category Cards:* 5 Outstanding, 8 Good, 4 Satisfactory, 2 Needs Attention, 1 Struggling
> *Table:* Lists all 20 attempts.
> Teacher sees Arjun scored 90% on Science Quiz (class avg 72%) but only 22% on Physics Quest.
> Teacher plans: give Arjun extra Physics practice materials.

---

## Deep Walkthrough — A Teacher's Full Day Using the Report

This section follows **Ravi, a Grade 10 Science teacher**, through a complete real-world session — building a complete student portfolio for parent-teacher meetings.

---

### Morning: Preparing for Parent-Teacher Meetings (1 Hour)

**It's Friday, March 31st, 8:00 AM.** Parent-teacher meetings are next week. Ravi needs to prepare a complete assessment portfolio for each of his 45 students. He starts with **Arjun Verma**, a student who has been inconsistent lately.

Ravi opens the **Student Detailed Assessment** and selects:
- **Student:** Arjun Verma (Grade 10-A)
- **Date Range:** Last 30 days
- **Assessment Type:** Both

---

### Step 1: The Category Cards Load

At the top of the page, Ravi sees five colored cards showing how Arjun's attempts are distributed:

| Category | Count | Score Range | Visual |
|----------|-------|-------------|--------|
| 🟢 **Outstanding** | 5 | ≥85% | ████████ |
| 🔵 **Good** | 8 | 70-84% | ██████████████ |
| 🟡 **Satisfactory** | 4 | 50-69% | ████████ |
| 🟠 **Needs Attention** | 2 | 35-49% | ████ |
| 🔴 **Struggling** | 1 | <35% | ██ |

**Ravi's first impression:** *"Out of 20 attempts, 13 are in the top two categories (Good + Outstanding). That's good. But 3 attempts are in the bottom two categories (Needs Attention + Struggling) — those are the ones I need to understand. Let me look at the details."*

---

### Step 2: Examining the Struggling Attempt

Ravi clicks on the 🔴 **Struggling** card to filter the table to show only that attempt:

| Date | Type | Assessment | Subject | Lesson | Topic | Marks | Category | Class Avg | Time |
|------|------|-----------|---------|--------|-------|-------|----------|-----------|------|
| Mar 18 | Quest | "Physics — Thermodynamics" | Physics | Thermodynamics | Heat Transfer | 22% (4.4/20) | Struggling | 58% | 15 min |

**Ravi thinks:** *"Arjun scored 22% on a Physics quest about Thermodynamics. The class average was 58%, so he scored 36 points below average. He only spent 15 minutes on it — that's very short for a quest. And this is Physics, not even my Science subject (which is Biology/Chemistry focused)."*

**Ravi clicks the row** to see full detail:

| Detail | Value |
|--------|-------|
| **Assessment** | "Physics — Thermodynamics Quest" |
| **Type** | Quest (project-based, not quiz) |
| **Teacher** | Ms. Ananya Kapoor (Physics) |
| **Arjun's Score** | 4.4 out of 20 (22%) |
| **Class Average** | 58% (11.6/20) |
| **Time Taken** | 15 minutes |
| **Status** | SUBMITTED |
| **Correct Answers** | 2 out of 10 questions |
| **Wrong Answers** | 6 |
| **Unattempted** | 2 |

**Ravi's analysis:** *"This isn't my subject — it's Physics. But as Arjun's homeroom teacher, I should still be aware. He scored 22%, spent only 15 minutes, and left 2 questions blank. He either gave up or didn't understand the material. I'll mention this to Ms. Kapoor."*

---

### Step 3: Examining the "Needs Attention" Attempts

Ravi clicks the 🟠 **Needs Attention** card:

| Date | Type | Assessment | Subject | Lesson | Topic | Marks | Category | Class Avg | Time |
|------|------|-----------|---------|--------|-------|-------|----------|-----------|------|
| Mar 10 | Quiz | "English Grammar — Tenses" | English | Grammar | Tenses | 42% (8.4/20) | Needs Attention | 65% | 20 min |
| Mar 22 | Quiz | "History — Ancient Civilizations" | History | Ancient Civilizations | Indus Valley | 38% (7.6/20) | Needs Attention | 60% | 18 min |

**Ravi thinks:** *"Two 'Needs Attention' attempts — one in English, one in History. Both are below class average. He spent reasonable time (18-20 min) but still scored low. This suggests he doesn't have a strong foundation in these subjects, not that he rushed."*

---

### Step 4: The Outstanding Performances

Ravi clicks 🟢 **Outstanding** to see Arjun's best work:

| Date | Type | Assessment | Subject | Lesson | Topic | Marks | Class Avg | Diff | Time |
|------|------|-----------|---------|--------|-------|-------|-----------|------|------|
| Mar 5 | Quiz | "Motion — Basics" | Science | Motion | Distance & Speed | 92% (18.4/20) | 72% | **+20%** | 28 min |
| Mar 8 | Quest | "Math — Algebra Project" | Math | Algebra | Linear Equations | 88% (17.6/20) | 74% | **+14%** | 45 min |
| Mar 15 | Quiz | "Motion — Velocity" | Science | Motion | Velocity | 90% (18/20) | 65% | **+25%** | 30 min |
| Mar 20 | Quiz | "Math — Quadratics" | Math | Algebra | Quadratic Eqns | 85% (17/20) | 70% | **+15%** | 25 min |
| Mar 28 | Quiz | "Science — Acceleration" | Science | Motion | Acceleration | 91% (18.2/20) | 75% | **+16%** | 32 min |

**Ravi's observation:** *"Arjun consistently scores 15-25% ABOVE class average in Science and Math. His Science scores are especially strong — 90-92% on Motion topics. He clearly has a strength in analytical subjects."*

**Ravi's comparison (Science only):**

| Topic | Arjun | Class Avg | Gap |
|-------|-------|-----------|-----|
| Motion — Basics | 92% | 72% | +20% |
| Motion — Velocity | 90% | 65% | +25% |
| Science — Acceleration | 91% | 75% | +16% |

**Ravi thinks:** *"Arjun is one of the top Science students. He scored 90% on the Velocity Calculations quiz where the class averaged only 65% — that's 25 points above the class. He clearly understands the material well."*

---

### Step 5: The "Good" Performances — 8 Attempts in the Middle

Ravi scrolls through the 8 "Good" attempts quickly. These are scores between 70-84%. He looks for patterns:

| Subject | Count in Good | Notes |
|---------|--------------|-------|
| Science | 2 | Lower than usual for Arjun (78%, 82%) |
| Math | 2 | Slightly below his standards (80%, 83%) |
| English | 2 | His best English scores (75%, 78%) |
| History | 1 | 72% |
| Physics | 1 | 70% |

**Ravi's insight:** *"Arjun's 'Good' category still contains scores in the 70-84% range — that's above the class average for most subjects. Even his weaker attempts in English (75%) are decent. The real outliers are the one Stuggling (22% in Physics) and the two Needs Attention (38-42%). Those are the exceptions, not the rule."*

---

### Step 6: Class Average Comparison — The Key Insight

Ravi sorts the table by "Difference from Class Average" to see where Arjun is above and below his peers:

| Assessment | Arjun | Class Avg | Diff | Verdict |
|-----------|-------|-----------|------|---------|
| Physics — Thermodynamics Quest | **22%** | 58% | **−36%** | 🔴 Major gap |
| History — Ancient Civilizations | **38%** | 60% | **−22%** | 🟠 Gap |
| English Grammar — Tenses | **42%** | 65% | **−23%** | 🟠 Gap |
| English — Active/Passive Voice | 75% | 68% | **+7%** | ✅ Slightly above |
| History — Medieval Period | 72% | 63% | **+9%** | ✅ Above average |
| Math — Linear Equations Quest | 88% | 74% | **+14%** | ✅ Strong |
| Science — Acceleration | 91% | 75% | **+16%** | ✅ Strong |
| Science — Velocity | 90% | 65% | **+25%** | ✅ Very strong |
| Motion — Basics | 92% | 72% | **+20%** | ✅ Very strong |

**Ravi's conclusion:**

| Strength Area | Weakness Area |
|--------------|--------------|
| Science (90-92%) — excels | Physics (22%) — major gap |
| Math (85-88%) — strong | English Grammar (42%) — below average |
| English application (75%) — okay | History concepts (38-72%) — inconsistent |

**Ravi's action plan for Arjun:**
1. **Recognize:** Praise Arjun's Science performance — he's a top performer
2. **Coordinate:** Talk to Physics teacher (Ms. Kapoor) about the 22% — does Arjun need extra help?
3. **Monitor:** English and History need attention — encourage Arjun to allocate more study time
4. **Parent meeting talking points:**
   - *"Arjun is excellent in Science and Math — consistently 15-25% above class average"*
   - *"We need to address a low score in Physics (22%) — coordinating with Ms. Kapoor"*
   - *"English and History need more attention — he's scoring below average"*
   - *"Overall, 13 out of 20 attempts are Good or Outstanding — he's a capable student"*

---

### Step 7: Ghost Rescue Discovery

While reviewing, Ravi notices an entry at the bottom of the table:

| Date | Assessment | Subject | Marks | Category |
|------|-----------|---------|-------|----------|
| Mar 12 | **(Deleted)** | Unassigned | 12/20 (60%) | Satisfactory |

**What happened:** This quiz was deleted from the database by an admin (perhaps it was a duplicate or had errors). But Arjun's attempt still exists. The system shows what it can: the score (60%) and marks (12/20), but subject and lesson show "Unassigned" because the original quiz data is gone.

**Ravi's note:** *"This is useful — the system preserves the score even if the quiz was deleted. I can see Arjun scored 60% on something, but I can't tell what it was. Better than losing the data entirely."*

---

### End of Day: Ravi's Complete Portfolio Notes

After 45 minutes, Ravi has documented notes for his 5 most important cases:

| Student | Key Finding | Parent Meeting Talking Point |
|---------|------------|------------------------------|
| **Arjun Verma** | Science superstar (90-92%), Physics gap (22%) | *"Science is outstanding. We're addressing the Physics issue."* |
| **Priya Sharma** | Math strong (88%), English weak (55-60%) | *"Math is excellent. English needs a tutor."* |
| **Aarav Kapoor** | Consistent across all subjects (70-80%) | *"Steady performer. Room for growth in History."* |
| **Ananya Iyer** | Only 3 attempts in 30 days, all below 30% | *"Serious concern. Low engagement + low scores."* |
| **Neha Gupta** | 95-100% in everything | *"Exceptional. Suggest enrichment programs."* |

---

### Additional Real-World Scenarios

**SC-005 — Portfolio for a Struggling Student (Non-Technical)**
Teacher opens Detailed Assessment for Ananya Iyer:
- **Outstanding:** 0
- **Good:** 0
- **Satisfactory:** 1 (52% on a Math quiz)
- **Needs Attention:** 1 (38%)
- **Struggling:** 2 (15%, 22%)
- **Conclusion:** 4 out of 5 attempts are below 40%. Ananya is struggling across ALL subjects. This is a systemic issue, not subject-specific. Refer to school counselor.

**SC-006 — Single Subject Deep Dive (Non-Technical)**
Teacher filters by Subject: **Science**, Lesson: **Motion**. Portfolio now shows only Science/Motion attempts:
- 5 attempts, scores: 92%, 90%, 82%, 78%, 68%
- Sorted by date: improvement trend upward
- **Insight:** Student started weak in Motion (68%) but improved to 92% by end of month — shows learning progress

**SC-007 — Filter by Category (Non-Technical)**
Teacher clicks the 🟢 **Outstanding** card. The table filters to show ONLY outstanding attempts (≥85%). Teacher can quickly see all the assessments where the student excelled, without scrolling through the full list.

**SC-008 — Multiple Pages of Data (Non-Technical)**
Teacher has a student with 40+ attempts in 30 days. The table shows 15 per page. Teacher clicks page 2, page 3 to see all attempts. The category cards at the top always show the TOTAL counts (not just page 1), so the overview is always accurate.

**SC-009 — Quest vs Quiz Difference (Non-Technical)**
Teacher notices a pattern: the student performs better on Quizzes (avg 78%) than on Quests (avg 62%). Insight: Quizzes are timed, closed-book tests. Quests are project-based with extended time. The student might perform better under structured quiz conditions than open-ended project work.

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizReportController@index()` (tab: `student-detailed`)
**Data Method:** `generateStudentDetailedData(Request)` — private method
**View:** `lmsquiz::reports.partials.student-detailed`
**Policy:** `tenant.student-detailed-assessment.view`

---

## Dependencies

| Dependency | Details |
|-----------|---------|
| `lms_quiz_quest_attempts` | All attempt records per student |
| `lms_quiz_quest_attempt_answers` | withCount for correct/wrong counts |
| `lms_quiz_quest_results` | Result percentages |
| `lms_quizzes` / `lms_quests` | Assessment titles and metadata (withTrashed for ghost rescue) |
| `lms_quiz_questions` / `lms_quest_questions` | Question count per assessment |
| `std_students` | Student identity |
| `sch_subjects` / `slb_lessons` / `slb_topics` | Content hierarchy for display |
