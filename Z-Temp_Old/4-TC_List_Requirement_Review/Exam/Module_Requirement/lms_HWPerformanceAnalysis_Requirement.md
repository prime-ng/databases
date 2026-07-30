# HW Performance Analysis — Business Requirements

---

## What Does This Screen Do?

This report creates a color-coded performance matrix that lets teachers see, at a glance, how every student performed on every homework assignment. It is like an Excel spreadsheet where rows are students, columns are homework assignments, and each cell is color-coded green-to-red based on the student's percentage score. Teachers can spot struggling students (lots of red cells), identify which homework was hardest for the class (a whole column of orange/red), and track overall performance trends over time.

---

## Real-Life Example

Ms. Sharma teaches Class 10 Science. Over the past month, she assigned 6 homework assignments: one on Photosynthesis, one on Human Eye, one on Electricity, and so on. She opens this report, selects Class 10 and Subject Science, and a matrix appears. She sees that Ravi has green cells for the first 3 homeworks but orange/red for the last 3 — that tells her Ravi is slipping and needs attention. She also sees that the "Electricity" homework column is mostly yellow/orange across all students — that tells her the whole class found that topic difficult and she should re-teach it.

---

## How the Report Works

1. The system fetches all homework assignments matching the selected filters (class, section, subject, lesson, topic, date range, gradable status).
2. It fetches all students enrolled in the selected class and section (from their current academic session records).
3. For every combination of student × homework, it looks up the submission (if any) and calculates the percentage score: `(marks_obtained / max_marks) × 100`.
4. A matrix table is built with color-coded cells based on the percentage ranges.
5. Aggregated metrics and charts are computed from the underlying submission data.

---

## Filters Available

| Filter | Options | What It Does |
|--------|---------|-------------|
| **Target Class** | Select a specific class (required for meaningful data) | Narrows the report to one class. If no class is selected, the matrix will be empty because students cannot be determined without a class |
| **Section** | All Sections or a specific section | Further narrows within the selected class. Also handles homeworks assigned to the entire class (null section) |
| **Subject** | All Subjects or a specific subject | Filters homeworks by subject |
| **Performance Horizon** | Date range picker with presets: Last 7 Days, Last 30 Days, This Month, Last Month | Limits to homeworks assigned within the date range |
| **Lesson Filter** | All Lessons or a specific lesson | Filters homeworks by syllabus lesson/unit |
| **Topic Filter** | All Topics or a specific topic | Filters homeworks by topic within a lesson |
| **Format** | All Units, Gradable Only, Non-Gradable | Filters by whether the homework is marked as gradable (`Yes` = graded, `No` = not graded, `Both` = all) |

**Filter Behavior**:
- All dropdowns cascade dynamically: selecting a Class loads its Sections and Subjects; selecting a Subject loads its Lessons; selecting a Lesson loads its Topics.
- Section filter is special: it matches homeworks where the section matches OR where section is null (homework assigned to whole class). This ensures that class-wide homeworks are not excluded when a specific section is selected.

---

## Widgets and Charts

### 1. Summary Cards (4 cards)

| Card | What It Shows | How It Is Calculated |
|------|--------------|---------------------|
| **Assignments Audited** | Total number of homework assignments included in the analysis after applying all filters | Count of homework records matching all filters |
| **Avg Completion Rate** | What percentage of students submitted homework across all assignments | `(total submissions / (total students × total homeworks)) × 100`. A submission is counted if a `HomeworkSubmission` record exists |
| **Avg Score Marks** | Average percentage score across all submissions where marks were given | Average of all individual percentage scores (each student's obtained/max converted to %) |
| **Top Bracket (90%+)** | How many individual student-homework scores were 90% or higher | Count of all percentage scores across the matrix that are >= 90 |

**Additional metrics computed but NOT displayed as cards** (these appear in the summary footer below the matrix):
- **Highest**: The single highest percentage score achieved by any student on any homework
- **Lowest**: The single lowest percentage score recorded

### 2. Class Performance Timeline (Area Chart)

- An area chart where each data point is the **class average percentage for one homework assignment**, plotted in chronological order by assignment date.
- The X-axis shows homework titles with their assignment dates (e.g., "Photosynthesis HW (05 Jan)").
- The Y-axis goes from 0 to 100%.
- Each data point label shows the percentage value.
- A smooth gradient fill under the line gives a visual sense of performance trends.
- Teachers can see at a glance whether class performance is improving, declining, or staying steady over time.

### 3. Scoring Distribution (Bar Chart)

- A bar chart showing how many individual scores fall into each of five performance brackets:

| Bracket | Range | Color | Label |
|---------|-------|-------|-------|
| Struggling | Less than 35% | Red (#ea4335) | Student scored very low, needs significant intervention |
| Attention | 35% to 49% | Yellow/Orange (#fbbc04) | Student is below satisfactory, needs attention |
| Satisfactory | 50% to 69% | Green (#34a853) | Student is meeting minimum expectations |
| Good | 70% to 84% | Blue (#4285f4) | Student is performing well |
| Outstanding | 85% and above | Purple (#673ab7) | Student is excelling |

- Each bar shows the count of scores in that bracket, with the number displayed above the bar.
- This is NOT a count of unique students — a single student may contribute multiple scores (one per homework). So it reflects overall score distribution, not student-level distribution.

### 4. Performance Matrix Table

This is the main and most important element of the screen — an Excel-style matrix:

**Structure**:
- **Rows**: Each student in the selected class/section (sorted alphabetically by name)
- **Columns**: Each homework assignment meeting the filter criteria (sorted by assignment date ascending)
- **Cells**: The student's percentage score for that homework, color-coded:

| Score Range | Background Color | Text Color | Meaning |
|-------------|-----------------|------------|---------|
| < 35% | Light red (#fecaca) | Dark red (#991b1b) | Struggling |
| 35% to 49% | Light orange (#fed7aa) | Dark orange (#9a3412) | Needs Attention |
| 50% to 69% | Light yellow (#fef08a) | Dark yellow (#854d0e) | Satisfactory |
| 70% to 84% | Light green (#d9f99d) | Dark green (#3f6212) | Good |
| 85%+ | Dark green (#a7f3d0) | Very dark green (#065f46) | Outstanding |

**Special Cell Markers**:
- **"NS"** (Not Submitted): Shown when the student has no submission record for that homework
- **Red dot badge**: A small red circle appears in the cell if the submission was marked as **late**
- **Score format**: If submitted and graded, the cell shows the percentage (e.g., "75%"). If not submitted, it shows "NS"

**Last Column (Aggregate)**:
- Shows the student's overall percentage across all homeworks: `(total marks obtained across all homeworks / total max marks across all homeworks) × 100`
- This total percentage is color-coded using a different scheme:
  - >= 85%: Green (success)
  - >= 70%: Blue (primary)
  - >= 50%: Light blue (info)
  - >= 33%: Yellow (warning)
  - < 33%: Red (danger)
- Next to the percentage, a grade badge is shown using letter grades

**Last Row (Footer — Class Average Per Homework)**:
- Shows the class average percentage for each homework in its respective column
- The final cell of this row shows the overall class average percentage with a blue/primary background
- The footer is sticky at the bottom of the scrollable table

**Scroll Behavior**:
- The matrix is enclosed in a scrollable container with a maximum height of 600px
- The header row (student names and homework headings) is sticky (stays visible while scrolling vertically)
- The first two columns (# and Student Name) are sticky horizontally (stay visible while scrolling horizontally)

---

## Business Rules & Filters

### Grade Calculation
The system calculates letter grades based on the aggregate percentage as follows:
- **A+**: 90% and above
- **A**: 80% to 89.9%
- **B+**: 70% to 79.9%
- **B**: 60% to 69.9%
- **C+**: 50% to 59.9%
- **C**: 40% to 49.9%
- **D**: 33% to 39.9%
- **F**: Below 33%

### Division Calculation (used by other reports, included here for consistency)
- **Division I**: 60% and above
- **Division II**: 45% to 59.9%
- **Division III**: 33% to 44.9%

### Student Selection Logic
Students are identified by querying `StudentAcademicSession` records where `is_current = 1` (the current academic session). Only students who have a class-section matching the selected class (and optionally section) are included. This means:
- Students who have changed sections or classes mid-year but whose current session still reflects the old class will NOT appear.
- Students are deduplicated by `student_id` (a student may have multiple academic session records).

### Homework Selection Logic
- Only homeworks that have at least one matching student in the selected class/section will appear as columns.
- Homeworks are sorted by `assign_date` in ascending order (oldest first).
- If no homeworks match the filters, an empty matrix with a message is shown.
- If no students match the class/section, an empty matrix is shown.

### Gradable Filter
- `gradable` parameter accepts: `'Yes'` (only gradable homeworks), `'No'` (only non-gradable), `'Both'` (all — default).
- In code, these are mapped as: `'Yes'` → `is_gradable = true`, `'No'` → `is_gradable = false`.

### Empty State
When no homeworks are found OR no students are found, the screen shows:
- All metric cards show 0
- The performance timeline chart shows no data
- The distribution chart shows all brackets as zero
- The matrix table shows a placeholder row: "Select Class and Subject to generate the performance matrix."

### Late Submission Marker
If a submission has `is_late = true`, a small red circle (5×5 px) badge appears in the top-right of the percentage cell. This is a subtle indicator, not a prominent alert.

---

## Error Scenarios

| Scenario | What Happens |
|----------|-------------|
| No class selected | Matrix shows placeholder message. All cards and charts show zeros |
| Selected class has no students enrolled | Metrics show 0 students, 0 homeworks. Matrix is empty |
| Selected class/section has homeworks but no submissions | All cells show "NS". Completion rate is 0%. Avg score is 0% |
| Homework has max_marks = 0 | Percentage calculation skips this homework for all students (returns null) to avoid division by zero |
| Date range with no homeworks | Empty state with zero metrics |
| Invalid date range | Falls back to last 30 days default (silently, no error message shown) |
| AJAX dependency loading fails | JavaScript logs a console error. Dropdowns remain disabled or show "Loading..." |

---

## Permissions

- **Required Permission**: `tenant.lms-exam-report.viewAny`
- Same single permission gate is used for all six advanced report tabs
- Both controller-level Gate authorization and view-level `@can` directive are in place

---

## Related Screens

- **HW Submission Tracker** — Tracks submission status (submitted/pending/late) for each homework, complementary to this performance analysis
- **LMS Activity Dashboard** — High-level overview of HW vs Exam platform activity
- **Exam Result Report** — Similar matrix and analytics but for exams instead of homework

---

## Known Gaps Between Requirements and Code

1. **Subtitle Labels Inconsistency** — The card "Assignments Audited" subtitle says "Across Lessons" but it actually counts all homeworks matching filters, not just those linked to lessons.

2. **Top Bracket Label Mismatch** — The card label says "Top Bracket (90%+)" but the code counts scores >= 90% (not students whose aggregate is >= 90%). This means a single student who submitted 5 homeworks and scored 90%+ on each would be counted 5 times, not once. The label suggests it counts students, but the code counts individual scores.

3. **Highest/Lowest Not Displayed as Cards** — The controller calculates `highest` and `lowest` metrics but they only appear in the summary footer below the matrix, not as stand-alone metric cards at the top.

4. **Late Indicator Not Documented** — The red dot badge for late submissions exists in the code and view but is not mentioned in the original requirement document.

5. **No Teacher Filter** — Unlike some other reports, there is no filter to narrow by the teacher who assigned the homework.

6. **Scoring Distribution Counts Scores, Not Students** — The distribution bar chart counts individual percentage scores across all student-homework combinations, not the number of unique students in each bracket. This could be misleading if interpreted as "5 students are outstanding" when it actually means "5 scores were outstanding."
