# Quest Tab 9: Student Result Details

This tab shows the complete result for a single student on a single quest. It is accessed by clicking on a student's row in the Summary or Reports tab. It is the most detailed view available — every answer, every score, and every action the student took during the quest.

---

## How It Works

The tab is divided into two main sections: the header and the answer details.

**Header Section:** At the top, the student's name, roll number, class, and the quest title are displayed. Below that, summary statistics for this student: their total score and percentage, a pass or fail badge, the time they spent on the quest, their rank among all allocated students (if ranking is enabled), and whether this was their first attempt or a subsequent one.

**Answer Details:** Below the header, every question from the quest is listed with the student's response. For each question, the teacher sees the question text, the scope type it belongs to, the student's selected or written answer, the correct answer, whether the student's answer was correct or incorrect, the marks awarded out of the maximum, and how long the student spent on that question.

For subjective questions that required manual checking, the teacher also sees the evaluator's comments. For auto-graded questions, the system displays the auto-evaluation result.

**Activity Timeline:** At the bottom, there is a chronological timeline of the student's quest session. It shows when they started, when they submitted, and significant events like tab switches (if proctoring was enabled), pauses and resumes, and auto-submissions due to time expiry.

---

## Score Override

If the teacher finds a discrepancy, they can override the score for an individual question. This is done by clicking on the question's score field and entering a new value. The teacher must provide a reason for the override. The original score is preserved in the audit log.

Score overrides trigger a recalculation of the student's total score and percentage. The pass or fail status may also change as a result.

---

## Important Business Rules

- This tab is read-only unless the teacher is performing a score override. All other data — answers, timing, submission time — is historical and cannot be changed.
- The teacher can only view students from their own class. Admin users can view any student's result.
- Score overrides are logged with the teacher's name, the original score, the new score, the reason provided, and the timestamp. These logs are visible to school administrators.
- If the quest has multiple attempts enabled, the teacher can switch between attempts using a dropdown. Each attempt's data is shown independently.
- Overriding a question's score triggers a full recalculation of the student's total score, percentage, pass/fail status, rank, and percentile. This may affect other students' ranks as well.
- The activity timeline shows events in chronological order with timestamps. Events include: quest started, question answered (per question), tab switch events, pause/resume actions, and submission.
- If proctoring was not enabled for this quest, tab switch events do not appear in the timeline.
- The teacher can print the student's result details directly from the browser. There is no dedicated export for this view.
- If the student was auto-submitted due to time expiry, the timeline shows "Auto-submitted (time expired)" as the submission event.

---

## Deep Analysis

### Business Workflows & State Machines

**Result Detail Data Flow:**
```
Student Result Page Load
         │
         ├──→ Header Section: student info, quest info, summary stats
         ├──→ Answer Details: every question with response, score, time spent
         └──→ Activity Timeline: chronological session events
```

**Score Override Flow:**
```
Teacher clicks score field → Enters new value → Provides reason → System validates
         │
         ▼
Original score preserved in audit_log
         │
         ▼
Total score recalculated
         │
         ▼
Percentage, pass/fail, rank updated (may affect other students' ranks)
```

**Multi-Attempt Switching:**
```
Attempt 1 (best) ← default view
Attempt 2
Attempt 3
...
→ Dropdown selects which attempt's data to display
→ Each attempt has independent: answers, scores, timeline
```

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Score override | New value ≥ 0 and ≤ question's max marks | "Override score must be between 0 and the question's maximum marks" |
| Score override reason | Required, max 500 chars | "A reason is required for score overrides" |
| View other class student | Teacher must teach that class | "You do not have access to this student's results" |
| Multiple attempts toggle | Must be a valid attempt number | Validation handled by dropdown |

**Edge Cases:**
- Overriding a question's score triggers full recalculation: total, percentage, pass/fail, rank, percentile. All allocated students' ranks may shift.
- If proctoring was not enabled, the activity timeline shows no tab-switch events — only start, answer, and submit events.
- The timeline shows auto-submission on time expiry distinctly from manual submission.
- Score overrides are logged with immutable audit trail: `original_score`, `new_score`, `overridden_by`, `overridden_at`, `reason`.
- If a question was removed from the bank after the student attempted it, it still appears here with all its data preserved.
- Printing from browser: No dedicated print CSS, but the layout is designed to be print-friendly.

### Integration Points

| Module | Table(s) | Purpose |
|--------|----------|---------|
| Student | `std_students` | Student identity |
| Quest (self) | `lms_quests`, `lms_quest_questions` | Quest and question metadata |
| QuestionBank | `qns_questions_bank` | Question text, answer key, marks |
| (Attempt tables) | Student responses, scores | Answer and score data |
| User | `sys_users` | Override author identity |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View student result | Teacher (own class), Admin | `tenant.lms.quest.results.view` |
| View other class result | Admin, HOD | `tenant.lms.quest.results.viewAny` |
| Override question score | Teacher (own class), Admin | `tenant.lms.quest.results.override` |
| View override history | Teacher, Admin | `tenant.lms.quest.results.view` |
| Print result | Teacher, Admin | N/A (browser print) |

- Score override requires explicit permission. Not all teachers may have it.
- Override history is visible to administrators regardless of class assignment.
