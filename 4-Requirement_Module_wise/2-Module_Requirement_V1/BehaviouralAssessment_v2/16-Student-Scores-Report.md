# Student Scores Report — Business Requirements

## What This Screen Does

The Student Scores Report is a tabular dashboard displaying final composite and category-level behavioral scores for every student in a selected cohort (Class and Section). Instead of looking at individual criteria, this report aggregates ratings to show broad student performance across core behavioral domains (e.g., Social Skills, Responsibility, Personal Hygiene) alongside their overall weighted average score.

This screen acts as the primary reference grid for teachers and HODs during report card preparation, allowing them to instantly identify students with exceptional behavioral ratings or those showing serious warning signs.

---

## When This Screen Is Used

- **End-of-Term Grading Review**: Teachers open the report to inspect final calculated scores before sending report cards to print.
- **Academic Performance Correlation**: The HOD compares this report with academic grade books to identify if behavioral patterns are affecting classroom learning.
- **Exporting Data**: Exporting structured tabular scores for third-party school information system (SIS) integrations.

---

## Key Columns & Fields

The screen consists of search parameters followed by a wide data table.

### Search and Filters
- **Academic Year**: Dropdown select.
- **Assessment Period**: Dropdown select.
- **Class & Section**: Dropdown selects.

### Scores Data Grid
For the selected section (e.g., Class 8-A), the grid displays:
| Column Header | Source Table | Description |
|---------------|--------------|-------------|
| **Roll No** | `std_students` | Student's school roll number. |
| **Admission No** | `std_students` | Unique school admission code. |
| **Student Name** | `std_students` | Student’s full name. Links to [Student Report](./20-Student-Report.md). |
| **Category Averages** | `ba_computed_scores` | Dynamic columns for each mapped category. Displays the student's calculated average score (e.g., "Collaboration: 4.5", "Hygiene: 3.2"). |
| **Overall Average** | `ba_computed_scores` | The final weighted average score across all categories (e.g., `4.12 / 5.00`). |
| **Grading Teacher** | `sch_employees` | The Class Teacher who completed the evaluation. |
| **Status** | `ba_assessments` | `Draft`, `Submitted`, or `Approved` (Locked). |

---

## Business Rules and Conditions

**Dynamic Category Columns**
- The table columns are generated dynamically on load by querying `ba_class_category_jnt` for the chosen class. If the class only has 3 mapped categories, the table renders exactly 3 category-average columns, ensuring the grid remains compact and readable.

**Score Highlighting (Color-Coded Badges)**
- To aid rapid scannability, cells are color-coded based on average score thresholds:
  - **4.5 to 5.0**: Bright Green (Exemplary)
  - **3.0 to 4.4**: Soft Green/Blue (Proficient)
  - **2.0 to 2.9**: Amber (Developing - Warning)
  - **1.0 to 1.9**: Red (Needs Intervention - Critical)

**Unfinished Grading Protection**
- If a section's progress status is still in `Draft` or `Submitted` (not yet locked by the HOD), a warning banner appears at the top: `"Alert: Grades for this section are not yet approved. Listed scores are drafts and subject to change."`

---

## Workflow Steps

**Reviewing and Filtering Scores**
1. User navigates to **Reports Hub** and selects **Student Scores Report**.
2. Selects Period: `Term 1`, Class: `Grade 8`, Section: `8-A`.
3. The system queries the joint and computed score tables, loads student profiles, and renders the grid.
4. The user notices that Amit Sharma has a red badge in `Responsibility (1.8 / 5.0)`.
5. The user clicks on Amit’s name.
6. The system triggers a redirection, opening Amit’s full [Student Report](./20-Student-Report.md) in a new browser tab to inspect individual criteria scores and written remarks.

---

## Example Scenario

Teacher Mrs. Priya reviews the scores report for Class 8-A:
- The columns display: `Roll No`, `Name`, `Social EQ`, `Self-Discipline`, `Overall Average`, `Status`.
- Student Amit Sharma shows: `Social EQ: 4.80`, `Self-Discipline: 4.60`, `Overall: 4.70` (Green Badge).
- Student Ajay Kumar shows: `Social EQ: 3.00`, `Self-Discipline: 2.10`, `Overall: 2.55` (Amber Badge).
- Mrs. Priya exports this table to CSV for reference in preparation for upcoming parent-teacher conferences.

---

## Related Screens

- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [17-Category-Summary.md](./17-Category-Summary.md) — Showing category aggregates rather than student-wise listings.
- [20-Student-Report.md](./20-Student-Report.md) — The individual profile report opened by clicking a student's name.
