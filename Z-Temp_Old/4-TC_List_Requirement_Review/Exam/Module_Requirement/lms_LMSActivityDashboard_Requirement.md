# LMS Activity Dashboard — Business Requirements

---

## What Does This Screen Do?

This screen gives administrators a bird's-eye view of platform activity by combining Homework and Exam data side by side. Think of it as a "health dashboard" for the entire LMS — you can see how many homeworks were assigned versus exams conducted, what percentage of students participated, and what the average scores were for each module. No data is created or edited here; it is purely a read-only analytical report.

---

## Real-Life Example

Imagine you are the principal of a school. You want to know: "Over the last month, did teachers assign more homework or conduct more exams? Did students participate more in homework submission or in exam attendance? Which module had better average scores?" This screen answers all of these in one place — two summary cards (one for Homework, one for Exam), two charts (a donut showing volume split, an area chart showing activity by day of week), and a detailed audit table listing every homework and exam activity with participation and performance metrics.

---

## How the Report Works

The report pulls data from two separate sources:
- **Homework module**: each homework's assigned student count (from class-section actual totals), submission count, and average score.
- **Exam module**: each exam's total enrolled student count, attendance count (non-absent), and average percentage score.

These two datasets are merged into a single chronological list sorted by activity date. Aggregated summaries are computed per module type, and chart data is prepared for visualization.

---

## Filters Available

| Filter | Options | What It Does | Is It Implemented in Code? |
|--------|---------|-------------|---------------------------|
| **Platform Filter** | All Activities, Homework Only, Exams Only | Shows activities of selected type only | **NOT IMPLEMENTED** — the dropdown exists in the UI but the controller always returns both Homework and Exam data regardless of this selection |
| **Audit Timeline** | Date range picker with presets: Today, Last 30 Days, This Month | Limits data to activities within the selected date range | ✓ Implemented — filters homework by `assign_date` and exams by `start_date` |

**IMPORTANT MISSING FEATURE**: The "Platform Filter" dropdown on screen has three options (All Activities, Homework Only, Exams Only), but the backend controller does not read or apply this filter. If a user selects "Homework Only" or "Exams Only", the report will still show both types. This is a known gap that needs to be fixed in code.

---

## Widgets and Charts

### 1. Summary Cards (2 cards)

Two large cards sit at the top, one for Homework (purple left border, book icon) and one for Exam (amber left border, graduation cap icon). Each card shows:

| Card Element | What It Displays |
|-------------|------------------|
| **Module type label** | HOMEWORK VOLUME or EXAM VOLUME |
| **Total Count** | How many homework assignments or exams fell within the selected date range |
| **Participation Rate** | Average participation/completion rate across all activities of that type. For homework: average of (submissions / assigned students). For exam: average of (non-absent / total enrolled) |
| **Avg Score** | Average score percentage across all activities of that type. For homework: average of submission marks. For exam: average of result percentages |

### 2. Activity Volume Distribution (Donut Chart)

- A donut/ring chart showing the proportion of Homework vs Exam activities.
- Homework slice is purple (#6366f1), Exam slice is green (#10b981).
- Center of the donut shows "TOTAL" with the combined count.
- Helps you quickly see which module is more actively used.

### 3. Platform Engagement Trend (Area Chart)

- An area chart intended to show activity frequency across days of the week (Monday through Sunday).
- **IMPORTANT: This chart currently shows HARDCODED dummy data** `[15, 32, 28, 45, 38, 12, 8]` rather than real calculated values from the database. This is placeholder/fake data that must be replaced with actual daily activity counts before this report can be considered accurate.

### 4. Activity Audit Table

A detailed table listing every activity (homework or exam) as a separate row:

| Column | What It Shows |
|--------|--------------|
| **#** | Sequential row number |
| **Activity Heading / Meta** | Title of the homework or exam, plus metadata line showing class and subject (for homework) or "Public Examination" (for exam) |
| **Category** | Badge showing HOMEWORK (book icon) or EXAM (graduation cap icon) |
| **Assigned** | Number of students assigned to this activity. For homework: sum of `actual_total_student` from class-sections matching the homework's class (and section if applicable). For exam: total number of exam result records |
| **Attempted** | Number of students who submitted (homework) or attended (exam — non-absent) |
| **Participation %** | Completion rate as a progress bar. Green if >=80%, blue if >=50%, red if <50% |
| **Avg Performance** | Average score percentage. Green if >=75%, blue if >=50%, red if <50% |

At the bottom of the table (when data exists), a summary row shows:
- **Modules Activated**: total count of activities listed
- **Participation Avg**: average of all completion percentages
- **Global Performance**: average of all average scores

### 5. Table Behavior and Color Coding

The table has an Excel-style design with orange header ("Modular Participation & Activity Audit") and a blue secondary header ("Comprehensive Pulse Analysis of Platform Engagement"). Column headers use a light blue background (#ddebf7). The Avg Performance column has a light green background (#e2f0d9) to distinguish it visually.

Each row shows:
- The activity title in bold dark text with metadata below it in small grey text
- A category badge with appropriate icon and text
- Completion percentage shown both as a progress bar (6px height, rounded) and as a numeric percentage beside it
- Average performance score with color-coded text (green >= 75%, blue >= 50%, red < 50%)

When no activities exist, a centered empty state is displayed with a gauge icon, the message "No activity logs found for the selected timeline.", and no data rows.

### 6. Platform Pulse Summary Footer

Below the table, a summary grid appears when activities exist:
- **Modules Act**: Total count of all homework + exam activities listed
- **Participation Avg**: Average of all completion percentages across all activities (computed dynamically)
- **Global Performance**: Average of all average scores across all activities (computed dynamically)

This summary is rendered in a blue-accented box with three columns, followed by a decorative orange bar at the very bottom.

---

## Business Rules & Filters

### Date Range Behavior
- If no date range is selected, the system defaults to the **last 30 days** (from current date backwards).
- The date range picker presets are: Today, Last 30 Days, This Month.
- Homework is filtered by `assign_date`. Exam is filtered by `start_date`.

### Homework Assigned Count Calculation
The number of "assigned" students for a homework is NOT simply the number of homework assignment records. Instead, it is calculated by:
1. Looking up all `ClassSection` records that match the homework's `class_id`.
2. If the homework has a specific `section_id`, only class-sections matching that section are included.
3. Summing the `actual_total_student` field from those class-section records.
4. If the sum is zero, it defaults to 1 (to avoid division by zero).

This means: if a homework is assigned to an entire class (no specific section), it counts ALL students across ALL sections in that class. If assigned to a specific section, it counts only students in that section.

### Exam Assigned Count Calculation
For exams, the "assigned" count is simply the total number of `ExamResult` records associated with that exam. "Attempted" (completed) is the count of results where the status is NOT "ABSENT".

### Homework Average Score Calculation
The average score for homework activities is calculated by averaging the `marks_obtained` field across all submissions for that homework. This is a simple average (sum of marks / count of submissions), NOT a weighted average or percentage-based average. If a homework has no submissions, the average defaults to 0.

### Exam Average Score Calculation
For exams, the average score is calculated by averaging the `percentage` field across all `ExamResult` records for that exam. The percentage is taken from the stored result, not recalculated from obtained marks.

### Aggregation Across Module Types
After all individual activities are processed, the system groups them by type (HOMEWORK vs EXAM) and computes:
- **Total count**: number of activities of that type
- **Average score**: average of all individual activity average scores for that type
- **Participation rate**: average of all individual activity completion percentages for that type

These aggregates are displayed in the two summary cards at the top. The cards do NOT overlap — homework metrics go in the purple Homework card, exam metrics go in the amber Exam card.

### Data Merge Order
Activities from both modules are merged into a single flat array in the order they are processed: first all homework activities (in date-descending order), then all exam activities (in query order). They are NOT interleaved or sorted by date in the final array. The row numbering in the table reflects this order — homework rows appear first, then exam rows.

### Activity Type Not Filtered
As noted above, the Platform Filter dropdown does NOT actually filter data. The code always returns all activities of both types. This is a confirmed missing implementation.

### Engagement Trend Data is Placeholder
The day-of-week engagement chart uses hardcoded sample data and does not reflect real student activity patterns. This must be wired to actual database queries in a future release.

### Participation Rate vs Completion Rate Terminology
Throughout this screen, "participation rate" and "completion rate" are used interchangeably. They both refer to the same calculation: `(students who submitted or attended / total students assigned) × 100`. For homework this is submission rate. For exams this is attendance rate.

---

## Error Scenarios

| Scenario | What Happens |
|----------|-------------|
| No activities found in date range | Table shows "No activity logs found for the selected timeline." Summary cards show 0 for total count, 0% for participation rate, and 0% for average score |
| Homework has no class-section record | `actual_total_student` defaults to 1, so completion rate becomes `submissions / 1 × 100`, which may be 100% even though the real enrollment is unknown |
| Homework class_id is null | `ClassSection::where('class_id', null)` returns zero records → actual_total_student sum = 0 → defaults to 1 |
| Exam has zero result records | Assigned count becomes 0 but is treated as 1 for percentage calculation (to avoid division by zero), so completion rate becomes 0% |
| Date range is invalid (e.g., end before start, badly formatted string) | The `parseDateRange()` method wraps parsing in a try-catch. On failure it silently falls back to default 30-day range. No error message is shown to the user |
| JavaScript fails to render charts | Both ApexCharts initializations are wrapped in a try-catch block. On failure, a console warning "Activity Pulse Charts Fail" is logged but the page continues to display the table and summary |
| Homework has null section_id AND a section filter is applied | Section filter is NOT applied to homework queries in `generateLmsActivityData()` — there is no section filter in this report at all |
| Homework has no submissions (submissions collection is empty) | `$hw->submissions->count()` returns 0. `avg('marks_obtained')` returns null, which defaults to 0 via the `?: 0` operator |
| Selected date range has homework but no exams (or vice versa) | Only the module type with activities shows in the table. The other module type card shows 0 count. The donut chart will show 100% for the type that has activities |
| ClassSection `actual_total_student` contains null values | MySQL SUM ignores nulls, so the sum will be the total of non-null values. If ALL values are null, the sum is 0 and defaults to 1 |
| Chart container element not found in DOM | The JavaScript checks `document.querySelector("#activityDonutChart")` and `document.querySelector("#engagementAreaWaveChart")` before rendering. If either is null, the chart is skipped silently |

---

## JavaScript & Chart Rendering Details

### Date Range Picker Behavior
The date range picker is initialized with three presets: Today, Last 30 Days, This Month. It uses the moment.js library for date manipulation. The display format is DD/MM/YYYY (e.g., "15/01/2026 - 14/02/2026"). Hidden input fields `date_from` and `date_to` store the actual values in YYYY-MM-DD format for form submission.

When the user clicks "Apply" on the date picker:
1. The display field shows the formatted range.
2. The hidden `date_from` and `date_to` fields are set to YYYY-MM-DD format.
3. The form must be submitted manually via the "Dashboard Pulse" button.

When the user clicks "Clear" (cancel):
1. Both hidden fields are cleared.
2. The display field is cleared.
3. On submission, no date filter is applied, so the system defaults to the last 30 days.

If the hidden date fields already have values on page load (from a previous submission), the display field is populated with the formatted date range.

### Chart Initialization Delay
Both ApexCharts are initialized inside a `setTimeout` of 500ms to ensure the DOM is fully rendered and the chart container divs exist. This prevents the common "container not found" error that can occur with dynamic tab content.

### Donut Chart Configuration
The donut chart uses no stroke (border) on the segments. The size is 75% of the container, leaving a thin ring. The legend is positioned at the bottom. The center shows "TOTAL" with the combined count.

### Area Chart Configuration
The area chart uses a smooth curve (stroke width 3) with gradient fill (opacity 0.4 at top, 0.1 at bottom). The X-axis shows abbreviated day labels. Toolbar (download, zoom, etc.) is hidden. Small markers (size 4) appear at each data point.

### CSS Styling Notes
- Filter card: White background with blur effect (`backdrop-filter: blur(10px)`), rounded corners (12px), light shadow.
- Summary cards: Left colored border, shadow, rounded corners (12px).
- Chart cards: Larger rounded corners (16px), shadow, transparent header.
- Table: No rounded corners (border-radius: 0), thin double border (border-width: 2), Excel-style appearance.
- Table header: Light orange background (#fce4d6) for title row, light blue (#ddebf7) for column headers.
- Body text uses a monospace context (no custom font explicitly set on table).
- Empty state icons are semi-transparent (opacity 0.25).

---

## Permissions

- **Required Permission**: `tenant.lms-exam-report.viewAny`
- This is enforced via a `Gate::authorize()` call at the top of the controller's `index()` method.
- All six report tabs share the same permission gate.
- The index view also wraps the includes in `@can('tenant.lms-exam-report.viewAny')` as a secondary check.

---

## Related Screens

- **HW Submission Tracker** — Drill-down into individual homework submission details
- **HW Performance Analysis** — Per-student homework performance matrix with color-coded scores
- **Exam Result Report** — Detailed exam results with pass/fail, grades, ranks
- **Student Exam History** — Individual student's performance trajectory across exams
- **Exam Subject Comparison** — Side-by-side comparison of subject-wise exam performance

---

## Known Gaps Between Requirements and Code

1. **Platform Filter Not Applied** — The dropdown for "All Activities / Homework Only / Exams Only" sends an `activity` parameter but `generateLmsActivityData()` never reads it. The filter is cosmetic only.

2. **Engagement Trend Chart is Fake Data** — The day-of-week chart plots hardcoded values `[15, 32, 28, 45, 38, 12, 8]` instead of computing real daily activity counts from the database.

3. **Homework "Assigned" is an Estimate** — The count uses `actual_total_student` from class-section records, not the actual number of homework assignment records. If actual student counts differ from the class-section's stored total, the participation rate will be off.

4. **Exam "Assigned" is Redundant** — The count uses total exam results, which means every student with a result record is counted as "assigned." This may not reflect the actual enrollment.

5. **No Teacher or Subject Filter Available** — Unlike other reports, this dashboard has no class, subject, section, or teacher filters. The only filter is date range (plus the non-functional platform filter).
