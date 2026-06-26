# Period Progress — Business Requirements

## What This Screen Does

The Period Progress dashboard is a standalone data visualization screen designed to illustrate change over time. While the [Period Report](./18-Period-Report.md) displays comparative scores in a flat tabular format, this screen renders **longitudinal trend line charts** and area graphs, plotting a student's or section's behavioral performance over consecutive terms or months.

This visual representation makes it extremely easy to spot behavior cycles (e.g., scores dipping in winter terms, or showing a massive upward trajectory after a counselor-led intervention plan starts).

---

## When This Screen Is Used

- **Counseling Intake Meetings**: School psychologists open this trend dashboard to review a student's historical behavioral graph before beginning therapy.
- **Academic Board Reviews**: Presenting year-over-year behavioral progress metrics to the school's board of directors.
- **Individual Student Counseling**: Showing students their own progress graph visually as a positive motivational tool.

---

## Key Widgets & Visual Elements

### 1. Trend Line Chart (Main Widget)
- **X-Axis**: Lists the consecutive assessment periods in chronological order (e.g., Month-1, Month-2, Month-3 or Q1, Q2, Q3, Q4).
- **Y-Axis**: The scoring range (e.g., `1.0` to `5.0`).
- **Plot Lines**:
  - *Composite Score Trend Line*: A bold blue line showing the student's overall weighted average.
  - *Category Trend Lines*: Optional thinner dotted lines plotted in different colors (e.g., Green for "Social EQ", Purple for "Self-Discipline") that can be toggled on/off using chart legends.

### 2. Milestone Event Markers (Chronological Overlay)
- Interactive flags overlaid directly onto the line chart.
- A red flag marker displays on a specific date when a High Severity incident was logged.
- A green flag marker displays on the date when an [Intervention Applied](./14-Interventions-Applied.md) was completed.
- Hovering over a flag displays a tooltip summarizing the event (e.g., `"Dec 5: Completed Anger Management Plan"`). This shows the direct correlation between active interventions and score improvements.

### 3. Progress KPI Summary Cards
- **Starting Score**: The score in the earliest chosen period.
- **Ending Score**: The score in the latest period.
- **Total Progress Delta**: Score change percentage (e.g., `+18% Improvement` or `-5% Decline`).

---

## Business Rules and Conditions

**Continuous Data Interpolation**
- If a student was absent or had no grades recorded for a specific middle period (e.g., missed Q2 due to medical leave), the chart line interpolates across the missing period with a dashed line, preventing a broken or disjointed chart layout.

**Multi-Line Chart Limits**
- To prevent chart clutter, users can plot a maximum of **5 categories** simultaneously. Selecting more than 5 categories prompts an alert requesting the user to uncheck a category before plotting another.

---

## Workflow Steps

**Reviewing Student Trend Graphs**
1. User navigates to **Standalone Reports -> Period Progress**.
2. Selects Target Scope: `Student`.
3. Type student name: `John Doe` (Grade 10).
4. The system queries `ba_computed_scores` for John across all active terms in the current session.
5. The **Trend Line Chart** renders John’s behavioral performance.
6. The user notices John’s line starts low in Q1 (`2.1`), dips further in Q2 (`1.9`), but spikes dramatically in Q3 (`3.8`).
7. The user notices a green milestone flag on the line at the start of Q3.
8. Hovering over the green flag displays: `"Completed Mentor Coaching Intervention led by Mr. Roy on Oct 10"`.
9. The user exports this progress chart to PDF to attach to the final term progress folder.

---

## Example Scenario

At the end of the year, HOD Mr. Jacob wants to check the overall behavior progress of Class 8-A. He selects Scope: `Class Section`, Class: `Grade 8`, Section: `8-A`. The dashboard plots a single line representing the section's class average over 4 quarters. The line starts at `3.4`, remains stable at `3.5` and `3.5`, and climbs to `3.9` in Q4, representing a year-over-year improvement of `+14.7%` across the cohort.

---

## Related Screens

- [06-Periods.md](./06-Periods.md) — The date-bound evaluation terms.
- [14-Interventions-Applied.md](./14-Interventions-Applied.md) — Interventions that generate milestone flags.
- [18-Period-Report.md](./18-Period-Report.md) — The flat table comparison report.
- [20-Student-Report.md](./20-Student-Report.md) — Individual student dossiers.
