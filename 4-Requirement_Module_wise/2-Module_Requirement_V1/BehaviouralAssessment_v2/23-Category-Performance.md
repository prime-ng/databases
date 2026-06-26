# Category Performance — Business Requirements

## What This Screen Does

The Category Performance dashboard is a standalone analytical interface designed for advanced behavioral analytics. While the [Category Summary Report](./17-Category-Summary.md) presents a simple flat table of class averages, the Category Performance screen provides deep statistical evaluations, such as **Standard Deviation / Score Spread curves (Bell Curves)**, **Gender-wise performance splits**, and **Academic Correlation Indexes**.

This page helps HODs and educational researchers evaluate if teacher grading is highly uniform (low standard deviation) or highly polarized (high standard deviation), and whether behavioral standards correlate directly with the school’s academic achievements.

---

## When This Screen Is Used

- **Academic Studies & Board Audits**: Presenting behavioral performance correlations during school board reviews.
- **Teacher Standardization Meetings**: HODs use this report to determine if teachers in Section A are grading significantly easier or harder than teachers in Section B (checking for grading bias).
- **Evaluating Demographics**: Reviewing if specific student demographics (e.g., gender, boarding vs. day scholar) show different behavioral patterns to direct school counseling initiatives.

---

## Key Widgets & Statistical Elements

### 1. Score Dispersion Curve (Standard Deviation Bell Curve)
- Illustrates how student scores are spread across the grading spectrum for the chosen category.
- **Low Standard Deviation Indicator**: A tall, narrow curve showing that teachers graded most students uniformly (e.g., almost everyone scored around 3.5).
- **High Standard Deviation Indicator**: A wide, flat curve showing polarized grading, where many students scored 5.0 and many scored 1.0, requiring HOD review for potential grading inconsistency.

### 2. Demographic Score Split (Bar Chart)
- **Gender-wise Comparison**: Bar chart comparing boys' average score vs. girls' average score in the category (e.g., Social EQ: Boys 3.6, Girls 4.1).
- **Enrolment Comparison**: Comparing boarding students vs. day scholars to check for different social development patterns.

### 3. Academic Correlation Matrix
- Plots a scatter diagram correlating a student's Behavioral Category average (X-Axis) against their Academic GPA (Y-Axis).
- Helps prove or disprove whether behavioral factors (e.g., Punctuality, Collaboration) directly influence a student's final academic exam scores.

---

## Business Rules and Conditions

**The Standardization Threshold**
- If the Standard Deviation for any category in a class exceeds **`1.20` on a 5-point scale**, the system highlights a warning icon next to the class name: `"High Grading Dispersal Detected. Review teacher grading patterns for consistency."`

**Anonymity Constraints**
- To maintain statistical objectivity and protect student privacy, this dashboard contains **no student-level identities**. It focuses entirely on cohort aggregates, statistical spreads, standard deviations, and correlation indexes.

---

## Workflow Steps

**Evaluating Grading Consistency**
1. HOD navigates to **Standalone Reports -> Category Performance**.
2. Selects Category: `Self-Discipline`, Period: `Term 1`, Class: `Grade 8`.
3. Clicks **Calculate Statistics**.
4. The dashboard renders:
   - **Class Average**: `3.22 / 5.00`
   - **Standard Deviation**: `1.45` (triggers a red warning banner: `"Polarized Grading Alert"`).
5. The HOD clicks the **Teacher Comparison** tab below.
6. The grid reveals that Mr. Roy graded 8-A with a standard deviation of `0.45` (very consistent), while Mr. Roy's co-teacher in 8-B graded with a standard deviation of `1.65` (highly inconsistent, with mostly 5s and 1s).
7. Mr. Jacob schedules a standardization alignment session for the Grade 8-B teacher.

---

## Example Scenario

The High School Principal wants to analyze the school's "Leadership & Initiative" category. They select the category and click analyze:
- **School-Wide average**: `3.60`
- **Gender Split**: Girls `3.92`, Boys `3.24` (revealing a significant development gap).
- **Academic Correlation**: `0.72` (a high positive correlation, proving that students with high leadership ratings are also scoring high academic grades).
- These insights are exported to PDF to include in the school's annual developmental journal.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Master categories definitions.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [17-Category-Summary.md](./17-Category-Summary.md) — The flat table summary report.
- [21-Class-Analysis.md](./21-Class-Analysis.md) — Comparative heatmaps.
