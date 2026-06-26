# Period Report — Business Requirements

## What This Screen Does

The Period Report is a comparative analytical dashboard designed to track longitudinal performance changes. Instead of showing scores for a single isolated term, this report compares student-wise or cohort-wide averages across multiple consecutive **Assessment Periods** (e.g., comparing "Term 1" vs. "Term 2", or plotting progress month-by-month).

It highlights developmental progression, showing which students are showing improvement in their behavioral averages, who has remained stable, and who is experiencing a sharp decline in conduct or self-discipline.

---

## When This Screen Is Used

- **Year-End Progress Reviews**: Teachers open the comparison grid to evaluate a student's year-long behavioral trajectory.
- **Intervention Audits**: Counsellors review this report to verify if a student’s scores improved after an [Intervention](./14-Interventions-Applied.md) was completed.
- **Parent meetings (Report Cards)**: Providing parents with a clear visual chart showing their child’s progress across distinct quarters.

---

## Key Fields & Grid Layout

### Filters
- **Academic Session**: Dropdown select.
- **Class & Section**: Dropdown select.
- **Compare Periods**: Multi-select dropdown (allows choosing two or more periods, e.g., "Term 1" and "Term 2").

### Period Comparison Data Table
For the selected cohort, the grid displays:
| Roll No | Student Name | Period 1 Average | Period 2 Average | Score Delta | Incidents (P1) | Incidents (P2) | Trend Indicator |
|---------|--------------|------------------|------------------|-------------|----------------|----------------|-----------------|
| 1 | Amit Sharma | `4.2` | `4.7` | `+0.5` | 0 | 0 | ↗️ Upward (Green) |
| 2 | John Doe | `3.1` | `2.5` | `-0.6` | 1 | 3 | ↘️ Downward (Red) |
| 3 | Ajay Kumar | `3.8` | `3.8` | `0.0` | 0 | 0 | ➡️ Stable (Blue) |

---

## Business Rules and Conditions

**The Delta (Score Change) Formula**
- `Score Delta = Period (N) Average - Period (N-1) Average`.
- If the delta is positive (e.g., `+0.30` or higher), the trend cell displays a green up-arrow.
- If the delta is negative (e.g., `-0.30` or lower), the trend cell displays a red down-arrow.
- A small change within `0.20` displays a blue horizontal flat arrow, representing stability.

**Dynamic Period Mapping**
- If categories or criteria mappings changed between Period 1 and Period 2 (which is discouraged but possible), the comparison engine calculates the delta *only* across categories that were active in **both** periods. This prevents skewed calculations from mismatched grading rubrics.

---

## Workflow Steps

**Reviewing Progress Trends**
1. Coordinator navigates to **Reports -> Period Report**.
2. Selects Class: `Grade 8`, Section: `8-A`.
3. In "Compare Periods", checks **Quarter 1** and **Quarter 2**.
4. Clicks **Generate Comparison**.
5. The comparison table renders roll numbers 1 to 30.
6. The coordinator filters the table by the "Score Delta" column in ascending order to instantly push students with declining scores to the top.
7. Sees John Doe has a delta of `-0.60` and his incident count spiked from `1` to `3`.
8. Coordinator flags John’s profile for a counselor review.

---

## Example Scenario

The school counsellor wants to check if counselling helped John. They open the Period Report for Grade 10:
- Q1 (Before counselling): John Doe average was `2.1` with 4 incidents.
- Q2 (After counselling): John Doe average is `3.8` with 0 incidents.
- Delta: `+1.7` (Green Upward Trend).
- This confirms that the behavior support plan was highly successful.

---

## Related Screens

- [06-Periods.md](./06-Periods.md) — Master periods configuration.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — Central reports dashboard.
- [20-Student-Report.md](./20-Student-Report.md) — The individual card printing these trend comparisons.
- [22-Period-Progress.md](./22-Period-Progress.md) — Standalone analytical page showing trend line charts.
