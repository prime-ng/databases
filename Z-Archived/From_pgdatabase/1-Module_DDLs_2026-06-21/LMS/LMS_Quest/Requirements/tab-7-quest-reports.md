# Quest Tab 7: Quest Reports

This tab provides detailed, exportable reports about quest results. While the Summary tab gives a quick overview, this tab is for in-depth analysis with more filtering options, comparative views, and richer export formats.

---

## How It Works

When the teacher opens this tab, they first select a quest from a dropdown. They then choose what type of report they want to generate.

**Student Performance Report:** This shows each student's performance broken down by scope type. For each student, the teacher can see how many questions they got right, wrong, or unanswered within each scope type. This helps identify which topic areas a student is strong or weak in. For example, a student might score 90% on Mechanics questions but only 40% on Thermodynamics.

**Question Analysis Report:** This shows how the class performed on each individual question. For each question, the teacher can see how many students got it right, how many got it wrong, and how many skipped it. The difficulty index is calculated — if 80% of students got a question right, it was easy. If only 20% got it right, it was hard. The discrimination index is also shown, which measures how well a question distinguishes between high-performing and low-performing students.

**Scope Analysis Report:** This aggregates results by scope type. The teacher can see the average score across all students for each scope type, the total marks available per scope, and which scope types had the highest and lowest performance.

---

## Exporting Reports

Every report can be exported to Excel or PDF. The export includes all the data visible on screen, plus metadata like the school name, class, subject, quest title, and the date range of the report.

Exports are generated with clean formatting suited for printing or sharing with parents and administrators. The teacher can choose to include charts in the PDF export or exclude them for a more compact file.

---

## Important Business Rules

- Reports are read-only. The teacher cannot modify any data from this tab.
- Report data may take a moment to generate for large quests with hundreds of students. The system shows a loading indicator while computing the data.
- The teacher can only generate reports for quests that belong to their own class. Admin users can generate reports for any quest across the school.
- The difficulty index is calculated as the percentage of students who answered the question correctly. A value above 80% means the question was too easy, below 30% means it was too hard.
- The discrimination index measures how well a question separates high performers from low performers. It ranges from -1 to +1. A positive value above 0.3 is considered good. A negative value means the question was problematic — low-performing students answered it correctly more often than high-performing students.
- Reports include only students who have submitted their quest. Allocated students who have not yet attempted the quest are excluded from report calculations.
- PDF exports are optimized for printing on A4 paper. Excel exports use a flat table format suitable for further analysis in spreadsheet software.
- The scope analysis report is only available if the quest has at least two scope types defined. A quest with a single scope type uses the Student Performance Report instead.

---

## Deep Analysis

### Business Workflows & State Machines

**Report Generation Flow:**
```
Select Quest → Choose Report Type → System Computes Data → Render View / Export
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                    ▼                    ▼
           Student Performance    Question Analysis     Scope Analysis
           (per-student scope     (per-question stats,  (per-scope averages,
            breakdown)              difficulty index)     total marks)
```

**Report Types Available:**

| Report | Purpose | Key Metrics |
|--------|---------|-------------|
| Student Performance | Per-student breakdown by scope | Correct/Wrong/Unanswered per scope, scope-wise percentage |
| Question Analysis | Per-question class performance | Right/Wrong/Skip counts, Difficulty Index, Discrimination Index |
| Scope Analysis | Aggregated by scope (≥2 scopes required) | Average score, total marks, highest/lowest scope |

**Difficulty Index Calculation:**
- DI = (Number of students who answered correctly) / (Total students who attempted the question) × 100
- >80% = Too easy, <30% = Too hard

**Discrimination Index Calculation:**
- DIsc = (Correct in top 27% - Correct in bottom 27%) / (Size of top 27% group)
- Range: -1 to +1. >0.3 = Good, 0.1-0.3 = Fair, <0.1 = Poor, Negative = Problematic

### Validation Rules & Edge Cases

| Scenario | Handling |
|----------|----------|
| Quest has fewer than 10 students | Question Analysis report still generates but discrimination index may be unreliable |
| Quest with only auto-graded questions | All three reports available |
| Quest with subjective questions | Paper Check tab data feeds into reports after evaluation is complete |
| Student with multiple attempts | Best attempt used by default, teacher can toggle attempt |
| Quest with zero submissions | Reports show "No data available for this quest" |
| Export for large quest (500+ students) | May take 5-10 seconds. Show loading indicator with progress bar |

**Edge Cases:**
- If a question is removed from the Quest Bank after being used in a quest, it still appears in reports but shows "(Deleted Question)".
- Discrimination index requires at least 30 students for statistical significance. For smaller classes, a warning is displayed.
- The scope analysis report hides if only 1 scope exists. Fall back to Student Performance Report.
- PDF exports include a timestamp, school logo, and teacher name as header/footer.

### Integration Points

| Module | Table(s) | Purpose |
|--------|----------|---------|
| Student | `std_students` | Student identity for per-student reports |
| QuestionBank | `qns_questions_bank` | Question metadata for analysis |
| Quest (self) | `lms_quests`, `lms_quest_scopes`, `lms_quest_questions` | Quest structure data |
| (Attempt tables) | Student responses | Answer data for computation |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View reports | Teacher (own class), Admin | `tenant.lms.quest.reports.view` |
| Export report (Excel) | Teacher, Admin | `tenant.lms.quest.reports.export` |
| Export report (PDF) | Teacher, Admin | `tenant.lms.quest.reports.export` |
| View question analysis | Teacher, Admin | `tenant.lms.quest.reports.view` |
| View scope analysis | Teacher, Admin | `tenant.lms.quest.reports.view` |

- Reports scoped to teacher's own classes unless user has admin role.
- Export permissions are separate from view permissions.
