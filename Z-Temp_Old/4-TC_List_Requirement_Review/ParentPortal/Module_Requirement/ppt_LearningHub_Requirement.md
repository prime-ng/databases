# My Learning Hub — Parent Portal (Read-Only, P2)

## What This Screen Does

The My Learning Hub screen gives parents an aggregated, read-only overview of their active child's digital learning activity across the LMS ecosystem — quizzes attempted, quests completed, and online exams assigned. It is designed as a monitoring dashboard for parents to understand their child's engagement with digital assessments and self-paced learning content.

---

## When This Screen Is Used

- **Weekly Engagement Check:** A parent wants to see how many quizzes their child has attempted this week and whether any online exams are pending.
- **Learning Activity Review:** A parent checks which quests the child has completed and their scores to identify strengths and weaknesses.
- **Pending Online Exams:** A parent sees that an online exam is allocated but not yet attempted and reminds the child to complete it before the cut-off date.

---

## Default Data Load

When the parent navigates to the Learning Hub, the system loads the active child's data in three sections:

1. **Quizzes** (default tab) — All `QuizAllocation` records that are:
   - Published (`published()` scope)
   - Active (`is_active = true`)
   - Within cut-off date (null or future)
   - Matching the child's class, section, or student ID
   - Joined with the quiz model (published, active, with subject)
   - Each enriched with attempt count and last attempt details from `lms_quiz_quest_attempts`

2. **Quests** — Same allocation logic as quizzes but using `QuestAllocation` model and `lms_quests`. Enriched with quest-specific attempt data.

3. **Online Exams** — All `ExamAllocation` records that are:
   - Active (`is_active = true`)
   - Matching class, section, or student ID
   - Joined with `examPaper`, `exam`, and `subject`
   - Filtered so both paper and exam are active

A tab count badge shows how many items are in each section. Data is only loaded if the child has a current session with a class and section defined; otherwise, empty collections are returned.

---

## Key Fields at a Glance

**Quiz / Quest Title** — The assessment title (e.g., "Science Quiz: Chapter 3 — Plant Kingdom").

**Subject** — The subject the quiz/quest/exam belongs to, shown with a subject colour badge.

**Attempts Used** — How many times the child has attempted the quiz/quest. If zero, the quiz is "Not Attempted."

**Last Attempt Score** — The score and max score from the most recent attempt (e.g., "8/10"). For online exams, the attempt status is shown (Not Attempted, In Progress, Submitted).

**Status Badges** — Each allocation shows a visual status:
- **New** (blue): Quiz/quest has attempts available, not yet attempted
- **Attempted** (amber): At least one attempt, result pending or published
- **Passed** (green): Last attempt passed threshold
- **Failed** (red): Last attempt did not pass
- **Expired** (grey): Cut-off date has passed

**Cut-Off Date** — The last date the quiz/quest is available for attempts. Shown as a countdown (e.g., "3 days left").

---

## Business Rules and Conditions

**P2 Priority Feature**
This feature is classified as P2 (Enhanced) in the FRD. It is not a core requirement and may be deferred to a later release. The controller and view are fully implemented but untested.

**Allocation-Based Visibility**
Only allocations that are published and active are shown. For quizzes/quests, allocations match by CLASS, SECTION, or STUDENT type. For online exams, allocations match by class_id, section_id, or student_id. If the child does not have a current session (no class+section), all three sections return empty collections.

**Read-Only**
No actions are available from this screen — the parent cannot attempt quizzes, submit quests, or start exams on behalf of the child. All actions must be taken by the child through their Student Portal.

**Attempt Enrichment**
Each quiz and quest allocation is enriched by querying `lms_quiz_quest_attempts` for the child's attempt history. The last attempt (by `attempt_number` descending) provides the current score and status. Online exams load the `attempt` relationship from `ExamAllocation`.

**Graceful Empty State**
If LMS modules (LmsQuiz, LmsQuests, LmsExam) are not active for the school, or if no allocations exist for the child, each section shows a graceful empty state — not a 500 error.

---

## Workflow Steps

**Viewing the Learning Hub**
The parent navigates to "My Learning" from the sidebar. `ParentLearningController::index()` resolves the active child and loads quizzes, quests, and online exams. The Quizzes tab is active by default.

**Switching Between Tabs**
The parent clicks a tab (Quizzes, Quests, or Exams). Tab switching is rendered server-side on the initial load. All three data sets are passed to the view; the view uses JavaScript to show/hide sections.

**Viewing Assessment Details**
The parent cannot drill into individual quizzes or quests from this screen — the learning hub is a summary overview. Each item shows title, subject, attempt count, and score. The parent must navigate to the Results or Homework screens for detailed results.

---

## Example Scenario

**Scenario: Weekly Learning Check**

Mrs. Verma logs into the Parent Portal to check her son Rohan's learning activity for the week. She clicks "My Learning."

**Quizzes Tab (4 items):**
1. "Science Quiz: Plant Kingdom" — Subject: Science — 1 attempt — 8/10 — Passed ✅
2. "Math Quiz: Fractions" — Subject: Mathematics — 2 attempts — 6/10, 9/10 — Passed ✅
3. "English Grammar: Tenses" — Subject: English — 0 attempts — Not Attempted ❌ — Cut-off: 30 Jul (5 days)
4. "History Quiz: Mughal Empire" — Subject: History — 1 attempt — 5/10 — Failed ❌

**Quests Tab (2 items):**
1. "Algebra Challenge" — Subject: Mathematics — Completed — Score: 85% ✅
2. "Scientific Method Quest" — Subject: Science — Not Started — Cut-off: 28 Jul (3 days)

**Online Exams Tab (1 item):**
1. "Unit Test 2 — Mathematics" — Subject: Mathematics — Not Attempted — Due: 25 Jul

Mrs. Verma notes that Rohan has two pending items: the English quiz (not attempted) and the online exam (due in 2 days). She reminds him to complete both before the deadlines.

---

## Related Screens

- **Parent Dashboard** (no direct widget for learning hub in current implementation)
- **Results Page** (detailed quiz, quest, and exam results with marks and grades)
- **Homework Page** (assignments that may be linked to learning activities)

---

## Business Conditions

### 5.1 Database Schema — `lms_quiz_quest_attempts` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-03 | assessment_type | ENUM(QUIZ,QUEST) | NOT NULL |
| BC-DB-04 | assessment_id | INT UNSIGNED | NOT NULL |
| BC-DB-05 | attempt_number | INT | NOT NULL |
| BC-DB-06 | status | VARCHAR(50) | NOT NULL |
| BC-DB-07 | score_obtained | DECIMAL(8,2) | NULL |
| BC-DB-08 | max_score | DECIMAL(8,2) | NULL |
| BC-DB-09 | percentage | DECIMAL(5,2) | NULL |
| BC-DB-10 | is_passed | TINYINT(1) | NULL |
| BC-DB-11 | submitted_at | DATETIME | NULL |
| BC-DB-12 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Authorization

| BC ID | Rule | Behavior |
|-------|------|----------|
| BC-AUTH-01 | Parent authenticated | Unauthenticated → redirect to login |
| BC-AUTH-02 | Child ownership | `resolveChild()` enforces guardian→child linkage |
| BC-AUTH-03 | Published allocations only | Quiz/quest use `published()` scope |
| BC-AUTH-04 | Module active check | Empty collections if class/section not found (graceful) |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | No class/session for child | All three sections return empty collections |
| BC-BIZ-02 | Cut-off date passed | Allocation excluded from results (cut_off_date >= now()) |
| BC-BIZ-03 | Null cut-off date | Allocation always included (no expiry) |
| BC-BIZ-04 | Allocation type matching | Class, Section, and Student types are all checked (OR logic) |
| BC-BIZ-05 | Quiz/quest relation null | Allocation filtered out (where quiz/quest !== null) |
| BC-BIZ-06 | Attempt query by type | `assessment_type` distinguishes QUIZ vs QUEST |
| BC-BIZ-07 | Activity logging | Every `index()` call logged |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | quiz_id | lms_quizzes | CASCADE |
| BC-REF-02 | quest_id | lms_quests | CASCADE |
| BC-REF-03 | exam_paper_id | lms_exam_papers | CASCADE |
| BC-REF-04 | student_id | std_students | CASCADE |

---

## Validation Rules

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | tab (query) | in:quizzes,quests,exams | Server passes raw to view |

---

## V1/V2 Gaps

| Gap | Type | Description | Impact |
|-----|------|-------------|--------|
| P2 Priority — not in scope for initial release | Priority | Feature classified as P2, may not be tested or QA'd | Low — feature exists but may have undiscovered issues |
| No drill-down to individual quiz/quest | UX Gap | Parent cannot click through to see question-level detail | Intended — summary only |
| No caching | Performance | Each page load queries allocations + attempts (up to 6 DB queries) | Acceptable for low-volume usage |

---

## Module Integration

| Integration | Direction | Details |
|-------------|-----------|---------|
| LmsQuiz | Read | `QuizAllocation`, `lms_quiz_quest_attempts` |
| LmsQuests | Read | `QuestAllocation`, `lms_quiz_quest_attempts` |
| LmsExam | Read | `ExamAllocation`, `examPaper` |
| ParentContextService | Read | Child resolution |
| sys_activity_logs | Write | Audit log |

---

## Known Limitations

- No ability to launch or attempt assessments from the portal
- No search or filter controls
- No performance trend charts or visualizations
- All three data sets loaded on every page load — no lazy loading

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-23 | AI | Initial requirement doc from live code audit + FRD analysis |

---

*End of ppt_LearningHub_Requirement.md*
