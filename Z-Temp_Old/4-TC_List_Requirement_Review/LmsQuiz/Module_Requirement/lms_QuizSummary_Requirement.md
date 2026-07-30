# Quiz Summary — Business Requirements

## What This Screen Does

The Quiz Summary screen shows a complete picture of student engagement with a quiz. For each quiz allocation, it shows: how many students were assigned, how many have submitted, how many are still working, and how many haven't started yet.

Think of it as a class attendance sheet for quizzes — at a glance, a teacher can see:
- 45 students assigned → 38 submitted, 2 in progress, 5 not started

From here, teachers can click into a detailed report for any allocation, and then drill into any individual student's attempt to review their answers.

---

## When This Screen Is Used

- **Monitoring Quiz Progress** — See which students have started/submitted during the quiz window
- **Post-Deadline Review** — Check completion rates after the due date
- **Before Evaluation** — Identify which attempts need manual grading
- **Student Follow-Up** — Find non-starters who need reminders

## Default Data Load

This screen is the "Quiz Summary" tab within Quiz Management (`active_tab=quiz_summary`). It loads a paginated list of allocations (10 per page) with attempt counts pre-computed.

Each row shows:
- Quiz title, Class-Section, Subject
- **Total Assigned** students (computed dynamically per allocation type)
- **Submitted Count** → status = SUBMITTED, TIMEOUT, EVALUATED, RESULT_PUBLISHED
- **In Progress Count** → status = IN_PROGRESS
- **Total Attempt Count** → all statuses
- Action button → "View Report"

**Filters available:**
- `search` — By quiz title or quiz_code
- `class_section_id` — Filters allocations for this section (including CLASS/SECTION/STUDENT types)
- `subject_id` — By quiz subject
- `date_range` — By allocation's published_at

---

## Complete Logic Flow

This section explains — in plain language — how the Quiz Summary screen figures out what to show. There are three levels of detail: the main list (all quizzes at a glance), the per-quiz report (deep dive into one quiz), and the per-student detail (every answer a student gave).

---

### Level 1: The Main Summary List

When a teacher opens the Quiz Summary tab, the system builds a table showing every quiz allocation and how many students have started, submitted, or not touched it yet.

**Step 1 — Load All Allocations**
The system reads every quiz allocation record, along with each allocation's quiz details (title, subject, class, lesson).

**Step 2 — Count Attempts by Status**
For each allocation, the system counts three things by looking at student attempts:
- **Submitted Count** — Students who finished the quiz (status = SUBMITTED, TIMEOUT — ran out of time, EVALUATED — graded, or RESULT_PUBLISHED — results visible to student)
- **In Progress Count** — Students currently taking the quiz (status = IN_PROGRESS)
- **Total Attempt Count** — Every student who started, regardless of where they are

**Step 3 — Apply Filters (if any)**
If the teacher uses the filter controls:
- **Search by title/code** → System filters to only matching quizzes
- **Class-Section filter** → System figures out which allocations belong to that section. This is tricky because allocations can target a whole CLASS, a single SECTION, or a single STUDENT. The system handles all three cases
- **Subject filter** → Only show quiz allocations for that subject
- **Date range** → Only show allocations published within those dates

**Step 4 — Compute "Total Assigned" Per Allocation**
For each allocation, the system counts how many students were assigned:

| Allocation Type | How the System Counts |
|----------------|----------------------|
| **CLASS** (e.g., "Grade 10") | Counts ALL students in ALL sections of that class (Grade 10-A, 10-B, 10-C together) |
| **SECTION** (e.g., "Grade 10-A") | Counts only students in that specific section |
| **STUDENT** (e.g., "Aarav Sharma") | Always 1 — it's a single student |
| **GROUP** (e.g., "Remedial Batch") | Counts active members of that group |

**Step 5 — Show the Results**
System displays 10 allocations per page, each showing: quiz title, class-section, assigned count, submitted count, in-progress count, and a "View Report" button.

**Real Example:**
> Ravi opens Quiz Summary and sees:
> | Quiz | Class | Assigned | Submitted | In Progress |
> |------|-------|----------|-----------|-------------|
> | Science Quiz 1 | Grade 10-A | 45 | 38 | 2 |
> | Math Practice 1 | Grade 10-A | 45 | 40 | 0 |
>
> Ravi knows 5 students haven't started Science Quiz 1 (45 − 38 − 2 = 5). He clicks "View Report" to find out who.

---

### Level 2: The Per-Quiz Allocation Report

When a teacher clicks "View Report" on a specific quiz, the system builds a detailed screen with stat cards, score distribution, average score, and a student-by-student table.

**Step 1 — Find the Quiz and Its Allocations**
The system loads the quiz and ALL allocations pointing to it. A quiz might be allocated to multiple targets (e.g., Grade 10-A AND Grade 10-B as separate allocations).

**Step 2 — Build the Master List of Assigned Students**
The system collects EVERY student who was assigned across ALL allocations. This means combining students from:
- CLASS allocations (all students in every section of that class)
- SECTION allocations (just that section's students)
- STUDENT allocations (individual)
- GROUP allocations (group members)

**Step 3 — Fetch All Attempts**
The system gets every student attempt record for this quiz, removing duplicates (if a student took the quiz twice, only the latest attempt matters for status).

**Step 4 — Determine Each Student's Status**
For each student in the assigned list:

| Status | Meaning | How System Knows |
|--------|---------|-----------------|
| **NOT STARTED** | Student hasn't opened the quiz yet | Student is in assigned list but has NO attempt record at all |
| **IN PROGRESS** | Student is currently taking it | Latest attempt shows status = IN_PROGRESS |
| **SUBMITTED** | Student has finished | Latest attempt status is SUBMITTED, TIMEOUT, EVALUATED, or RESULT_PUBLISHED |

**Step 5 — Calculate Score Distribution**
The system sorts submitted students into score bands:
- 0-20% — Struggling
- 21-40% — Below average
- 41-60% — Average
- 61-80% — Good
- 81-100% — Outstanding

**Step 6 — Calculate Average Score**
The system adds up all submitted scores and divides by the number of submitted students.

**Step 7 — Build the Student Table**
The final table shows every assigned student with: name, admission number, status, score (if submitted), percentage, time taken. Teachers can:
- Search by student name or admission number
- Filter by status (show only "Not Started" to find non-starters)
- Click a student to see their full attempt detail

**Real Example:**
> Ravi clicks "View Report" on Science Quiz 1:
> - **Stat cards:** 45 assigned, 38 submitted, 5 not started, 2 in progress
> - **Average Score:** 72%
> - **Distribution:** Most students in 61-80% band
> - He filters by "Not Started" → sees 5 student names he needs to remind
> - He searches for "Priya" → finds her submitted attempt with her score

---

### Level 3: Individual Student Attempt Detail

When a teacher clicks on a specific student's attempt, the system shows the full picture of how that student performed.

**Step 1 — Load the Attempt**
The system loads the student's attempt record along with:
- Student info (name, photo, class-section)
- Result data (score, percentage, pass/fail)
- Per-question answers
- Quiz details

**Step 2 — Load the Quiz Questions**
The system gets ALL active questions for this quiz, along with their options (active options only — disabled options are hidden).

**Step 3 — Match Answers to Questions**
For each question, the system finds what the student answered. If the student didn't answer a question, it's marked as unattempted.

**Step 4 — Build the Review Display**
The system prepares:
- **Result Summary:** Marks obtained, total marks, percentage, pass/fail, correct count, wrong count, unattempted count, time taken (in minutes and seconds), attempt number, submission time
- **Per-Question Review:** Each question shown with:
  - The question text
  - All options (with correct answer highlighted)
  - The student's selected answer (marked)
  - Explanation (if enabled for this quiz)

**Real Example:**
> Ravi clicks on Priya's attempt for Science Quiz 1:
> - **Result:** 15/20 (75%) — PASS
> - **Breakdown:** 15 correct, 3 wrong, 2 unattempted
> - **Time Taken:** 18 min 30 sec
> - Ravi scrolls through questions:
>   - Q7: Priya answered "A" but correct was "C" — wrong
>   - Q12: Priya left blank — unattempted
> - Ravi notes the topics where Priya struggled and plans a review session

---

## Workflow Steps (Non-Technical)

### Viewing Quiz Summary
1. Go to Quiz Management → "Quiz Summary" tab
2. System shows allocation table with attempt counts
3. Optionally filter by:
   - **Search**: Type quiz title or code
   - **Class-Section**: Select a specific section
   - **Subject**: Filter by subject
   - **Date Range**: Filter by publish date
4. Each row shows: quiz name, total assigned, submitted, in-progress counts
5. Click "View Report" on any row

### Viewing Allocation Report
1. Report page loads with:
   - Stat cards: Total Assigned, Total Attempts, Not Started, In Progress, Submitted
   - Score distribution: % of students in each score band
   - Average score
   - Student table with: name, admission number, attempt status, score, percentage, time taken
2. Optionally filter students by status (Not Started / In Progress / Submitted)
3. Search for a specific student by name or admission number
4. Click a student's name → view their attempt detail

### Viewing Student Attempt Detail
1. Attempt detail shows:
   - **Student Info**: Name, photo, class-section
   - **Result Summary**: Marks obtained / total marks, percentage, pass/fail, correct/wrong/unattempted counts, time taken
   - **Per-Question Review**: Each question displayed with:
     - Question text and options
     - Student's selected answer (marked)
     - Correct answer (highlighted)
     - Explanation (if enabled)
2. Teacher can scroll through all questions

---

## Deep Walkthrough — A Teacher's Full Day Using the Quiz Summary

This section follows **Ravi, a Grade 10 Science teacher**, through a complete real-world scenario — from morning check to post-deadline investigation. Every step shows exactly what Ravi sees, what he thinks, and what he does next.

---

### Morning: Checking Quiz Progress (The Summary Tab)

**It's Monday morning, 8:30 AM.** The due date for "Science Quiz 1" was Sunday midnight. Ravi wants to see how many students actually submitted on time.

Ravi opens Quiz Management → clicks the **Quiz Summary** tab. The system shows the main list:

| Quiz | Class | Assigned | Submitted | In Progress | Total Attempts |
|------|-------|----------|-----------|-------------|----------------|
| Science Quiz 1 | Grade 10-A | 45 | 38 | 2 | 40 |
| Math Practice 1 | Grade 10-A | 45 | 40 | 0 | 40 |
| Science Remedial | Grade 10-A (Group) | 8 | 4 | 1 | 5 |

**Ravi thinks:**
- *"Science Quiz 1: 45 assigned, only 38 submitted. Plus 2 are still in progress — that means 5 students haven't even started! It's past the due date. I need to find those 5."*
- *"Math Practice 1: 40 out of 45 submitted. 5 haven't started that one either."*
- *"Science Remedial (my extra help group): Only 4 out of 8 submitted. I specifically created this for struggling students and half haven't attempted it."*

**Ravi's action:** He clicks **"View Report"** on Science Quiz 1 to get the full picture.

---

### Mid-Morning: Investigating the Numbers (Allocation Report)

The report page loads with four sections:

#### Section 1 — Stat Cards (At a Glance)

| Stat Card | Number | What It Means |
|-----------|--------|---------------|
| Total Assigned | 45 | All students in Grade 10-A |
| Total Attempts | 40 | 40 students started the quiz |
| Not Started | 5 | 5 students never opened the quiz |
| In Progress | 2 | 2 students are still taking it (past deadline!) |
| Submitted | 38 | 38 students finished and submitted |
| Average Score | 72% | Class average — decent but not great |

**Ravi thinks:** *"2 students are still in progress past the deadline — either they started late or their internet crashed. 5 students never started at all. That's 7 students I need to talk to."*

#### Section 2 — Score Distribution (Bar Chart)

Ravi looks at the bar chart showing how students performed:

```
Number of Students
    ^
 14 |    ██
 12 |    ██  ██
 10 |    ██  ██  ██
  8 |    ██  ██  ██  ██
  6 | ██ ██  ██  ██  ██
  4 | ██ ██  ██  ██  ██  ██
  2 | ██ ██  ██  ██  ██  ██
    +--------------------------------→ Score %
     0-20% 21-40% 41-60% 61-80% 81-100%
            (2)    (8)   (12)   (10)   (6)
```

Breakdown:
- **0-20% (Struggling):** 2 students — scored very low, need urgent help
- **21-40% (Needs Attention):** 8 students — below average, need intervention
- **41-60% (Satisfactory):** 12 students — average, room for improvement
- **61-80% (Good):** 10 students — doing well
- **81-100% (Outstanding):** 6 students — excellent

**Ravi thinks:** *"10 students scored below 40% — that's a quarter of the class. The quiz was on Motion and Velocity. Either the questions were too hard, or these students didn't study. Let me check who these students are."*

#### Section 3 — Student Table

The student table shows all 45 students. Ravi can filter and search.

**Filtering by "NOT STARTED" — Ravi finds the 5 non-starters:**

| Student Name | Admission No | Status | Score | Time Taken |
|-------------|-------------|--------|-------|------------|
| Aarav Sharma | STD-2024-012 | Not Started | — | — |
| Dev Patel | STD-2024-015 | Not Started | — | — |
| Karan Singh | STD-2024-023 | Not Started | — | — |
| Meera Joshi | STD-2024-031 | Not Started | — | — |
| Vikram Raj | STD-2024-042 | Not Started | — | — |

**Ravi thinks:** *"Aarav and Meera are usually good students. I wonder why they didn't attempt. Dev and Karan often miss deadlines. Vikram was absent last week — he probably didn't even know the quiz was assigned."*

**Ravi's action:** He writes down the 5 names and plans to send a message to all of them through the system.

**Filtering by "IN PROGRESS" — Ravi finds the 2 late takers:**

| Student Name | Admission No | Status | Score | Time Taken |
|-------------|-------------|--------|-------|------------|
| Neha Gupta | STD-2024-033 | In Progress | — | 28 min |
| Rohit Verma | STD-2024-039 | In Progress | — | 15 min |

**Ravi thinks:** *"Neha has been working for 28 minutes — maybe she started late. Rohit is 15 minutes in. Both are past the due date. I'll give them until end of day and then force-close if needed."*

**Filtering to see low performers — Ravi sets score range to 0-40%:**

| Student Name | Status | Score | Category | Time Taken |
|-------------|--------|-------|----------|------------|
| Ananya Iyer | Submitted | 4/20 (20%) | Struggling | 8 min |
| Farhan Qureshi | Submitted | 5/20 (25%) | Struggling | 12 min |
| Ishaan Thakur | Submitted | 6/20 (30%) | Needs Attention | 45 min |
| Kavya Nair | Submitted | 7/20 (35%) | Needs Attention | 22 min |
| *(plus 6 more below 40%)* | | | | |

**Ravi thinks:** *"Ananya only spent 8 minutes and scored 20% — she rushed through it. Farhan spent 12 minutes and got 25%. But Ishaan spent 45 minutes and only got 30% — he actually tried but still struggled. That means Ishaan genuinely doesn't understand the topic. Kavya spent 22 minutes and got 35% — she's borderline."*

**Ravi's action:** He notes Ananya, Farhan, Ishaan, and Kavya for follow-up. He clicks on Ishaan's name to see his attempt detail.

---

### Afternoon: Individual Student Review (Attempt Detail)

The system loads Ishaan's attempt. Ravi sees:

#### Student Info Card
- **Name:** Ishaan Thakur
- **Class:** Grade 10-A
- **Quiz:** Science Quiz 1 — Motion & Velocity
- **Status:** Submitted
- **Attempt Number:** 1 of 1 (only one attempt allowed)

#### Result Summary
| Metric | Value |
|--------|-------|
| **Marks** | 6 out of 20 |
| **Percentage** | 30% |
| **Result** | **FAIL** (passing is 33%) |
| **Correct Answers** | 4 |
| **Wrong Answers** | 10 |
| **Unattempted** | 6 |
| **Time Taken** | 45 minutes |
| **Submitted At** | Sunday, 10:15 PM (just before midnight deadline) |

**Ravi thinks:** *"Ishaan submitted at 10:15 PM — last minute. He spent 45 minutes which is a reasonable amount of time. He wasn't rushing. He just didn't know the answers. 6 questions completely blank — he probably ran out of time or gave up on the hard ones."*

#### Per-Question Review

Ravi scrolls through all 20 questions. Here's what he sees:

**Question 1:** What is the SI unit of velocity?
- A) m/s ← Ishaan answered this (INCORRECT)
- B) m/s² **← Correct answer**
- C) km/h
- D) m/min
- *Ishaan got this wrong. This is a basic unit conversion question.*

**Question 2:** A car travels 100 meters in 20 seconds. What is its speed?
- A) 2 m/s
- B) 5 m/s **← Correct answer**
- C) 20 m/s ← Ishaan answered this (INCORRECT)
- D) 200 m/s
- *Ishaan divided wrong — he should know speed = distance ÷ time.*

**Question 5:** What does the slope of a distance-time graph represent?
- A) Acceleration
- B) Velocity ← Ishaan answered this (INCORRECT)
- C) Speed **← Correct answer**
- D) Displacement
- *Ishaan confused speed with velocity. Common misconception.*

**Question 8:** A ball is thrown upward. At its highest point, what is its velocity?
- A) 9.8 m/s²
- B) 0 m/s **← Correct answer**
- C) -9.8 m/s²
- D) Depends on mass ← Ishaan answered this (INCORRECT)
- *This is a conceptual question. Ishaan doesn't understand that velocity is zero at the highest point.*

**Question 12:** Blank — Ishaan didn't attempt this question at all.
- *Skipped — probably timer warning appeared and he moved on.*

**Question 15:** Blank — Ishaan didn't attempt this question either.
- *Another skip. This was a numerical problem about relative velocity.*

**Question 18:** A train passes a platform in 30 seconds. If its length is 150m and platform is 250m...
- A) 15 m/s ← Ishaan answered this (INCORRECT)
- B) 13.33 m/s **← Correct answer**
- C) 5 m/s
- D) 8.33 m/s
- *Complex numerical — Ishaan attempted it but got the calculation wrong.*

**Ravi's analysis after reviewing all 20 questions:**

| Category | Count | Observation |
|----------|-------|-------------|
| **Basic recall wrong** | 3 questions | Ishaan doesn't remember fundamental formulas (speed = distance/time) |
| **Concept misunderstanding** | 4 questions | Confuses speed vs velocity, doesn't understand zero velocity at peak |
| **Numerical errors** | 3 questions | Attempted but wrong calculation |
| **Skipped (blank)** | 6 questions | Ran out of time or gave up |
| **Correct** | 4 questions | Only got the easiest ones right |

**Ravi's conclusion:** *"Ishaan has fundamental gaps. He doesn't understand basic formulas and confuses key concepts. The 6 skipped questions suggest he panicked under time pressure. He needs more practice with basic numerical problems before moving to complex ones."*

**Ravi's action plan:**
1. Assign Ishaan to the **"Remedial Science Batch"** group
2. Send him the **"Velocity Basics"** practice quiz (5 questions, unlimited attempts)
3. Schedule a 15-minute one-on-one after school on Wednesday
4. Mark Ishaan for the "Motion — Extra Practice" recommendation

---

### End of Day: Ravi's Summary Report

At the end of the day, Ravi has taken these actions based on the Quiz Summary:

| Issue Found | How He Found It | Action Taken |
|------------|----------------|--------------|
| 5 students never started | Summary tab → Not Started filter | Sent reminder messages via the system |
| 2 students still in progress | Summary tab → In Progress filter | Extended deadline by 1 day |
| Ananya & Farhan scored 20-25% in <12 min | Report tab → Scored filtered by <40% | Flagged for "rushed attempt — not serious" |
| Ishaan scored 30% with genuine effort | Attempt detail → Reviewed all 20 questions | Scheduled one-on-one help + remedial quiz |
| 8 students in Needs Attention (21-40%) | Score distribution chart → Identified trend | Will review the quiz questions — maybe too hard |
| Science Remedial group has 50% no-show | Summary tab → Saw Remedial row | Will talk to the group during class |

**Ravi's overall feeling:** *"The Quiz Summary saved me hours. Instead of manually checking each student, I found all the issues in 30 minutes and have a clear action plan for tomorrow."*

---

### Additional Real-World Scenarios

**SC-004 — CLASS vs SECTION Allocation Resolution (Non-Technical)**
Coordinator allocated a quiz to CLASS "Grade 10" (all 3 sections: A, B, C). The total_assigned for this allocation = count of all current students across Grade 10-A, 10-B, 10-C = 135 students. The report shows all 135 students in the table.

**SC-005 — Two Allocations for the Same Quiz (Non-Technical)**
Ravi created "Science Quiz 1" and allocated it to Grade 10-A AND Grade 10-B as separate allocations. The Summary tab shows two rows — one for each allocation. When Ravi clicks "View Report" on either row, the system combines BOTH allocations' students into one report. So if 10-A has 45 students and 10-B has 42, the report shows all 87 students.

**SC-006 — Multiple Attempts Allowed (Non-Technical)**
Ravi created a "Practice — Motion" quiz with 3 attempts allowed. Student Priya attempted it 3 times:
- Attempt 1: 5/20 (25%) — Failed
- Attempt 2: 12/20 (60%) — Passed
- Attempt 3: 18/20 (90%) — Excellent

In the Summary tab, the system shows "1 student, 3 total attempts." In the Report, Priya's latest status is "Submitted" and her score shows 90% (the latest attempt's score). Ravi can click into Priya's attempt detail to see all 3 attempts separately.

**SC-007 — Group Allocation for Remedial Batch (Non-Technical)**
Ravi created a "Remedial Science Batch" group with 8 struggling students and allocated a "Velocity Basics" quiz. The Summary tab shows:
| Quiz | Target | Assigned | Submitted | In Progress |
|------|--------|----------|-----------|-------------|
| Velocity Basics | Remedial Batch | 8 | 4 | 1 |

Ravi sees 3 out of 8 remedial students haven't started. He sets up an in-class supervised session for them.

---

## How Total Assigned is Computed

| Allocation Type | Computation |
|----------------|-------------|
| CLASS | `StudentAcademicSession::whereHas('classSection', fn($q) => $q->where('class_id', target_id))->where('is_current', 1)->count()` |
| SECTION | `StudentAcademicSession::where('class_section_id', target_id)->where('is_current', 1)->count()` |
| STUDENT | 1 |
| GROUP | `EntityGroupMember::where('entity_group_id', target_id)->where('is_active', 1)->count()` |

---

## Score Categories (for performance bands)

| Category | Score % | Label |
|----------|---------|-------|
| Outstanding | ≥85% | Top performers |
| Good | 70-84% | Above average |
| Satisfactory | 50-69% | Average |
| Needs Attention | 35-49% | Below average |
| Struggling | <35% | Needs intervention |

---

## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizController`
- `index()` — quiz_summary tab logic
- `report($quiz_id)` — allocation report
- `attemptDetail($attemptId)` — student attempt detail

**Views:** `lmsquiz::summary.index`, `lmsquiz::summary.report`, `lmsquiz::summary.student_result`
**Policies:** `tenant.quiz-summary.view` (summary tab), `tenant.quiz.view` (report + attempt detail)

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_quiz_allocations` | Primary | Allocation records with attempt withCount |
| `lms_quizzes` | FK | Quiz master with subject/class/lesson relations |
| `lms_quiz_quest_attempts` | StudentPortal | Student attempt records (assessment_type=QUIZ) |
| `lms_quiz_quest_attempt_answers` | StudentPortal | Per-question answers with is_correct flag |
| `lms_quiz_quest_results` | StudentPortal | Evaluated results with percentage |
| `lms_quiz_questions` | Module | Question count per quiz + question detail |
| `std_student_academic_sessions` | StudentProfile | Student population per class/section |
| `std_students` | StudentProfile | Student personal details |
| `sch_class_sections` | SchoolSetup | Class-section resolution |
| `sch_entity_groups` / `sch_entity_group_members` | SchoolSetup | Group allocation resolution |
