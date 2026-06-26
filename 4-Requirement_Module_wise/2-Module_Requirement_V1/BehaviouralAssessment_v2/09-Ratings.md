# Ratings Grid — Business Requirements

## What This Screen Does

The Ratings Grid is the core data-entry screen where teachers score student behavior. It presents a spreadsheet-like matrix layout. The rows list all active students within the selected class and section, while the columns display the specific behavioral criteria mapped to that class level.

In each intersection cell, the teacher selects a grade level (e.g., A, B, C, D, E) or a numeric point from a dropdown or button group. The UI is designed for rapid entry, featuring complete keyboard navigation, status markers, and an automated background autosave system to guarantee no data loss.

---

## When This Screen Is Used

- **End-of-Term Evaluations**: Homeroom teachers open the grid to fill out ratings for all 30+ students across various behavioral criteria.
- **Continuous Grading**: Subject teachers update ratings for students over the course of a week as they observe class interactions.
- **Data Editing**: Modifying draft ratings based on updated observations before final submission.

---

## Key Fields & Grid Layout

### Header Filters (Locked when opened from "My Assessments")
- **Class & Section**: Read-only labels or selects.
- **Assessment Period**: The term active for grading.
- **Rating Scale Reference**: Information banner showing which grading scale is currently being enforced (e.g., `"Rating Scale: 5-Point Descriptive Scale"`).

### Dynamic Ratings Matrix
- **Row Header**: Student list showing Student Photo, Roll Number, and Name.
- **Columns**: Dynamic criteria headers (e.g., "Respects Peers," "Punctuality," "Organization"). Hovering over a header displays the criterion's full description.
- **Intersection Cells**: Selection dropdowns. The options listed are the `Level Names` from `ba_rating_levels` (e.g., *Always*, *Sometimes*, *Never*).
- **Row Summary Column**: **"Computed Average"** — A calculated cell showing the student's rolling average score in real-time as cells are populated.

---

## Business Rules and Conditions

**Dynamic Column Generation**
- The system queries `ba_class_category_jnt` for the class ID to fetch all mapped categories. It then queries `ba_criteria` to extract all active criteria. These criteria represent the columns of the grid. 

**Autosave Mechanics**
- To prevent loss of data from session timeouts or network drops, changing a dropdown cell value immediately triggers an asynchronous AJAX `POST` request to `save-rating`.
- A small green indicator at the top right flips from `"Saving..."` to `"All Changes Saved in Cloud"` to assure the teacher.

**Formula Calculations**
- When a level is selected, the system retrieves its `numeric_score` from `ba_rating_levels`.
- **Computed Average Formula**: Sum of (Criterion Numeric Score × Criterion Weightage) divided by 100.
- The average recalculates instantly on the client side using JavaScript, then persists to `ba_computed_scores` upon background save.

**Lock Constraints**
- If the corresponding `ba_assessments` record is in `Submitted` or `Approved` status, or the `ba_assessment_periods` lock date has passed, the entire grid disables. All dropdowns turn read-only, and the save endpoints reject requests.

---

## Workflow Steps

**Grading a Cohort**
1. Teacher clicks **Edit Ratings** on Mrs. Priya’s [My Assessments](./08-My-Assessments.md) dashboard.
2. The Ratings Grid loads. The columns render: `Respects Peers`, `Academic Honesty`, and `Punctuality`.
3. Teacher uses keyboard Arrow keys to navigate down to Roll Number 1: **Amit Sharma**.
4. In `Respects Peers`, Mrs. Priya hits `Enter`, selects **Consistently** (Value: 4.0), and hits `Tab`.
5. The cell background highlights in light green, the `"Saving..."` message flashes, and Amit’s rolling average updates to `4.0`.
6. Mrs. Priya tabs to `Academic Honesty`, selects **Exemplary** (Value: 5.0). Average instantly updates to `4.5`.
7. Mrs. Priya completes all rows. Once done, she clicks **Proceed to Remarks** to write narratives.

---

## Example Scenario

Teacher Mr. Khan is grading Class 10-A on "Team Collaboration" (Weight 50%) and "Conflict Resolution" (Weight 50%) under a standard 5-point scale:
- Student John receives **Exemplary** (5 points) in Collaboration and **Satisfactory** (3 points) in Conflict Resolution.
- John's computed average cell instantly displays: `(5 × 0.5) + (3 × 0.5) = 4.00`.
- The database writes John's individual scores to `ba_assessment_ratings` and his average `4.0` to `ba_computed_scores`.

---

## Related Screens

- [02-Rating-Scales.md](./02-Rating-Scales.md) — The scoring standards that fill the cells.
- [08-My-Assessments.md](./08-My-Assessments.md) — The launchpad dashboard.
- [10-Remarks.md](./10-Remarks.md) — Writing corresponding student narratives.
- [20-Student-Report.md](./20-Student-Report.md) — The final report card where these ratings display.
