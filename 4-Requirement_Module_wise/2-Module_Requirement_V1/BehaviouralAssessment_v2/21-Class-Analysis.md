# Class Analysis — Business Requirements

## What This Screen Does

The Class Analysis dashboard is a standalone analytical workspace designed for school leaders and HODs. While the [Student Scores Report](./16-Student-Scores-Report.md) displays a simple flat data grid, the Class Analysis screen uses advanced data visualization (heatmaps, cohort distribution charts, and outlier detectors) to provide a comprehensive behavioral diagnostic of an entire class section.

This dashboard helps coordinators identify macro trends across sections, compare section averages, and instantly isolate student outliers—both high-achievers who deserve recognition and at-risk students who need counselling before behavioral issues escalate.

---

## When This Screen Is Used

- **Inter-Section Audits**: The HOD compares Class 8-A vs. Class 8-B to see why one section has significantly lower discipline averages.
- **Isolating At-Risk Cohorts**: Quickly identifying the bottom 10% of students across a grade level to organize targeted group therapy.
- **Academic Counsel Preparation**: Reviewing macro-level class behavior to discuss in weekly teacher alignment meetings.

---

## Key Widgets & Visual Analytics

### 1. Cohort Score Distribution (Donut / Bar Chart)
- Displays the headcount and percentage of students falling into distinct behavioral brackets (e.g., Exemplary: `8 Students`, Proficient: `15 Students`, Developing: `5 Students`, Critical: `2 Students`).

### 2. Behavioral Heatmap Grid
A visual matrix grid:
- **Rows**: Students listed by name.
- **Columns**: Mapped behavioral categories (e.g., "Collaboration," "Ethics," "Focus").
- **Cells**: Instead of text numbers, cells are filled with shaded gradient colors based on scores (e.g., Deep Emerald Green for `5.0` fading down to Deep Rose Red for `1.0`).
- This layout allows a coordinator to scan 35 students in a split second and instantly spot red or amber blocks representing struggling students.

### 3. Outlier Lists (The Extremes Panel)
- **Top Performers (Positives)**: Lists the top 5 students in the class with the highest composite score averages and positive incident counts.
- **At-Risk Alert (Negatives)**: Automatically surfaces the bottom 5 students with the lowest composite score averages or highest negative incident frequencies.

---

## Business Rules and Conditions

**Strict Threshold Triggers**
- The **At-Risk Alert** list automatically flags any student whose composite rolling average falls below `2.5 / 5.0` OR who has accumulated `2 or more` negative incidents during the active term, regardless of their average score.

**Data Aggregation Speed**
- Heatmaps use heavy database matrix queries. To maintain page responsiveness, heatmap data is compiled asynchronously in the background using JavaScript and stored in a browser local storage cache. If no changes are detected in `ba_assessment_ratings`, the grid loads instantly from cache.

---

## Workflow Steps

**Investigating Class Outliers**
1. Coordinator navigates to **Standalone Reports -> Class Analysis**.
2. Selects Class: `Grade 8`, Section: `8-A`, Period: `Term 1`.
3. Clicks **Analyze Cohort**.
4. The dashboard renders. The distribution chart shows: `Exemplary: 30%, Proficient: 50%, Developing: 15%, Critical: 5%`.
5. Mr. Jacob scans the **Behavioral Heatmap**. He spots a dark red cell in the row for student **John Doe** under the "Focus" column.
6. Jacob hovers over the cell. A tooltip displays: `"John Doe - Focus Score: 1.50 / 5.00"`.
7. Jacob reviews the "At-Risk Alert" panel. John is listed at the top.
8. Jacob clicks John’s name, opening his [Student Report](./20-Student-Report.md) to inspect the specific teacher remarks.

---

## Example Scenario

During a grade level review, HOD Mr. Jacob opens the Class Analysis for Grade 8-A:
- **Section Average**: `3.80 / 5.00`
- **Heatmap Scan**: The column `Digital Citizenship` is almost entirely light green and yellow, averaging `2.8` class-wide, whereas `Collaboration` is deep emerald green (`4.5` class-wide).
- This alerts Jacob that the entire section is struggling with digital safety and phone protocols, indicating a need for a targeted class-wide intervention rather than individual disciplinary actions.

---

## Related Screens

- [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) — The transactional scores list.
- [17-Category-Summary.md](./17-Category-Summary.md) — Category-level summaries.
- [20-Student-Report.md](./20-Student-Report.md) — Student detailed reports.
- [22-Period-Progress.md](./22-Period-Progress.md) — Longitudinal trend tracking.
