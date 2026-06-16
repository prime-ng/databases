# Quest Tab 6: Quest Summary

This tab shows the overall results and performance data for a completed or ongoing quest. It is the teacher's main reporting tool within the quest module, giving them a bird's-eye view of how students performed.

---

## How It Works

When the teacher opens this tab, they first select a quest from a dropdown. They then see a results table that lists every student who was allocated to the quest, along with their performance data.

For each student, the table shows their name and roll number, their total score and percentage, whether they passed or failed (shown as a colored badge), how many questions they answered correctly and incorrectly, how many they left unanswered, and how long they took to complete the quest. The table is sortable by any column and searchable by student name.

At the top of the tab, summary statistics are displayed. These show the class average score, the highest and lowest scores, the pass rate (percentage of students who passed), and the total number of submissions. Below that, there is a score distribution chart showing how students are spread across score ranges.

---

## Actions on This Tab

The teacher can click on any student's row to view their detailed result page. They can also export the summary data to Excel or PDF. The export includes all columns shown in the table plus additional details like per-scope-type breakdown.

For quests that allow multiple attempts, the table shows the best score by default. The teacher can toggle to view the latest attempt or all attempts for each student.

If a quest requires manual paper checking, the summary shows a "Pending Check" badge for students whose answers have not yet been evaluated. The teacher can click through to the Paper Check tab from here.

---

## Important Business Rules

- The summary is read-only — the teacher cannot modify scores or results from this tab. Any score corrections must be done through the Paper Check tab or by overriding individual question scores.
- If no students have submitted yet, the table is empty and a message appears: "No submissions yet for this quest."
- The summary only includes students who were actually allocated to the quest. Students who were never allocated do not appear, even if they somehow accessed the quest.
- For multi-attempt quests, the default view shows the best score across all attempts. The teacher can switch to view the latest attempt or a complete list of all attempts per student.
- The "Pending Check" badge only appears for quests that contain subjective questions requiring manual evaluation. Fully auto-graded quests never show this badge.
- Exported reports include a timestamp and the teacher's name for audit purposes.
- The score distribution chart groups scores into buckets: 0-20%, 21-40%, 41-60%, 61-80%, and 81-100%. If a quest has fewer than 10 students, the chart may not be shown to avoid privacy concerns.
- The pass/fail badge is calculated based on the passing marks set during quest creation. If the passing marks were later changed, the badge reflects the current passing threshold.

---

## Deep Analysis

### Business Workflows & State Machines

**Summary Data Flow:**
```
Student submits quest → Score calculated → Summary table updated → Dashboard reflects
                                                        │
                                          ┌─────────────┴─────────────┐
                                          ▼                           ▼
                                   PASS/FAIL badge              Percentile rank
                                   (based on passing%)          (if ranking enabled)
```

**Score Calculation:**
- For each question: check `marks_override` from `lms_quest_questions` if set, otherwise use question bank default marks.
- Negative marking: if enabled, wrong answers deduct `negative_marks` points per question. Unanswered = 0 (no penalty).
- Total = SUM(correct question marks) - SUM(wrong question penalties)
- Percentage = (Total / MAX(quest total_marks, sum of all question marks)) × 100

**Multi-Attempt Display:**
| Display Mode | Logic |
|-------------|-------|
| Best score (default) | Highest percentage across all attempts |
| Latest attempt | Most recent submission |
| All attempts | List all attempts chronologically |

### Validation Rules & Edge Cases

| Scenario | Handling |
|----------|----------|
| No submissions yet | Show empty table with "No submissions yet for this quest" |
| Quest with 0 total_marks | Auto-calculated from question marks. If still 0, percentage shows as 0% |
| Score override triggers recalculation | Total, percentage, pass/fail, rank all recalculated immediately |
| Fewer than 10 students | Score distribution chart hidden (privacy concern) |
| Quest with subjective questions | Shows "Pending Check" badge for unchecked students |

**Edge Cases:**
- If `passing_percentage` is changed after some students have already passed/failed, existing badges update retroactively.
- If a student hasn't submitted but the due date has passed, they appear as "Absent" rather than failed.
- Percentile ranks are calculated only among students who actually submitted. Absent students are excluded.
- The summary excludes students who were allocated but never attempted the quest.

### Integration Points

| Module | Table(s) | Purpose |
|--------|----------|---------|
| Student | `std_students` | Student metadata (name, roll number) |
| Quest (self) | `lms_quests`, `lms_quest_allocations` | Quest settings, allocation data |
| (Attempt tables) | Student attempt records | Scores, submission data |

**Events:** None triggered from summary view. It is entirely read-only.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View summary | Teacher (own class), Admin | `tenant.lms.quest.results.view` |
| Export to Excel | Teacher, Admin | `tenant.lms.quest.results.export` |
| Export to PDF | Teacher, Admin | `tenant.lms.quest.results.export` |
| View multi-attempt detail | Teacher, Admin | `tenant.lms.quest.results.view` |

- Teachers see only students from their own classes. Admins see all students.
- Students cannot access this tab.
