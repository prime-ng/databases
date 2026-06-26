# Category Summary Report — Business Requirements

## What This Screen Does

The Category Summary Report provides HODs, Principals, and counsellors with high-level curriculum analytics. Rather than listing individual students, this report aggregates score statistics to summarize performance across broad behavioral categories (e.g., "Personal Integrity," "Digital Literacy," "Social Responsibility").

It highlights which behavioral categories are strengths for a particular class or grade level, and which domains represent widespread struggles (e.g., identifying that Class 8-A averages an excellent `4.6 / 5.0` in Peer Collaboration but averages a concerning `2.4 / 5.0` in Classroom Focus).

---

## When This Screen Is Used

- **Curriculum Planning Meetings**: The school leadership HOD reviews behavioral category averages to decide if the school needs to dedicate more focus to digital ethics or basic hygiene.
- **Section Comparative Analysis**: Comparing the performance of Section A vs. Section B to see if teaching styles or section distributions affect student behavioral scores.
- **School Quality Inspections**: Exporting aggregated category statistics for educational accreditation reviews.

---

## Key Fields & Report Layout

### Filters
- **Assessment Period**: Dropdown select.
- **Class**: Dropdown select (Optional. If empty, aggregates school-wide).
- **Section**: Dropdown select (Optional. Enabled only when Class is selected).

### Category Summary Grid
For the selected cohort, the report displays:
| Field Header | Description |
|--------------|-------------|
| **Category Name** | The behavioral category (e.g., "Collaboration"). |
| **Students Count** | Total number of students evaluated in this cohort. |
| **Category Average**| The average score of all students under this category (e.g., `3.82`). |
| **Top Criterion** | The specific criterion that received the highest class average (e.g., "Works well in teams" - Average `4.2`). |
| **Lowest Criterion**| The specific criterion that received the lowest class average (e.g., "Resolves conflicts" - Average `3.1`). |
| **Cohort Distribution** | A small inline bar chart showing the split of students in grading buckets (e.g., Exemplary: 40%, Proficient: 50%, Developing: 10%). |

---

## Business Rules and Conditions

**Anonymized Reporting**
- Unlike the [Student Scores Report](./16-Student-Scores-Report.md), the Category Summary Report is **fully anonymized**. It lists no individual student names or IDs, only counts and averages. This allows teachers to share these reports during general grade-level staff briefings without violating student privacy.

**Weighted Category Aggregations**
- Averages are calculated using the formula:
  - `Category Average = Sum of (Student Computed Category Average) / Total Students`.
  - Inactive criteria weights are excluded from calculations dynamically based on historical mapping entries in `ba_class_category_jnt`.

**Download Formats**
- Supports exports to **PDF** (which embeds a professional distribution chart) and **CSV** for spreadsheet compilation.

---

## Workflow Steps

**Reviewing Category Averages**
1. HOD navigates to **Reports Hub** and clicks **Category Summary**.
2. Selects Period: `Term 1`, Class: `Grade 8`, Section: `All Sections`.
3. Clicks **Generate Report**.
4. The screen loads three rows: `Social Quotient`, `Self-Discipline`, and `Responsibility`.
5. Under `Self-Discipline`, Mr. Jacob notices the Class Average is `2.9` (Amber warning badge).
6. Under the "Lowest Criterion" column, the cell reads: `"Punctual Submission of Assignments (Average: 2.1)"`.
7. This indicates that assignment submission, specifically, is pulling down the self-discipline averages across the grade level.
8. Mr. Jacob schedules a staff meeting to discuss homework policies and logs out.

---

## Example Scenario

The High School Principal pulls a school-wide Category Summary Report for the Mid-Term Period:
- **School-Wide Average**: `3.90 / 5.00`
- **Highest Performing Category**: `Collaboration & Sharing` (Average: `4.52`)
- **Lowest Performing Category**: `Digital Ethics` (Average: `2.10`)
- The Principal notices a school-wide drop in digital ethics and organizes a cyber-safety workshop for high school students in November.

---

## Related Screens

- [03-Categories.md](./03-Categories.md) — Master categories definitions.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
- [16-Student-Scores-Report.md](./16-Student-Scores-Report.md) — Detailed student-wise scores.
- [23-Category-Performance.md](./23-Category-Performance.md) — Standalone analytical page showing category standard deviations.
