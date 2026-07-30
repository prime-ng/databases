# HW Submission Tracker — Business Requirements

---

## What Does This Screen Do?

This report helps teachers track homework submission status across all their classes. It answers questions like: "Which homeworks have low submission rates? Which students are consistently late? How many submissions have I graded versus how many are still pending?" Teachers get a table of every homework assignment with submission counts, plus a detail modal showing individual student submission records for each homework.

---

## Real-Life Example

Mr. Verma teaches Class 8 Mathematics. He assigned homework on Monday — 10 problems on Algebra. By Wednesday, he logs into this tracker, selects Class 8, Subject Maths, and sees that out of 40 students, only 28 have submitted, 5 are late, and 15 are still pending. He clicks the "eye" button next to that homework and a modal pops up listing all 40 students — green badges for on-time submissions, red badges for late, and "Pending" status for those who haven't submitted yet. He can see who specifically hasn't submitted and follow up with those students directly.

---

## How the Report Works

1. The system queries all homework assignments matching the selected filters (class, section, subject, lesson, topic, date range).
2. For each homework, it loads all related assignment records and their associated submissions.
3. For each homework, it counts: total assignments, total submissions, late submissions, graded submissions, resubmission requests, and pending submissions.
4. These counts are displayed in a paginated table (15 homeworks per page).
5. Clicking the "eye" icon opens a modal showing each student's individual submission details, with its own pagination (10 students per page within the modal).

---

## Filters Available

| Filter | Options | What It Does |
|--------|---------|-------------|
| **Class** | All Classes or a specific class | Narrows homeworks by class |
| **Section** | All Sections or a specific section | Filters by section. **Special behavior**: homeworks assigned to the entire class (null section) are also included when a section is selected — this prevents class-wide assignments from disappearing from the report |
| **Subject** | All Subjects or a specific subject | Filters homeworks by subject |
| **Lesson** | All Lessons or a specific lesson | Filters by syllabus lesson |
| **Topic** | All Topics or a specific topic | Filters by topic within a lesson |
| **Date Range** | Date picker with presets: Today, Last 7 Days, Last 30 Days, This Month | Limits to homeworks assigned within the specified date range. If no dates are selected, defaults to the last 30 days |

**Cascading Behavior**: All dropdowns cascade via AJAX. Selecting a class loads its sections and subjects. Selecting a subject loads its lessons. Selecting a lesson loads its topics. Sections and subjects are disabled until a class is selected. Lessons are disabled until a subject is selected. Topics are disabled until a lesson is selected.

---

## Widgets and Charts

### 1. Summary Metrics (5 cards)

| Card | What It Shows | How It Is Calculated |
|------|--------------|---------------------|
| **Assignments** | Total number of individual student-homework assignments across all filtered homeworks | Sum of `assignments.count()` for every homework in the filtered set — this is the total count of "expected submissions" |
| **Submissions** | Total number of submissions received | Sum of submission records across all homeworks |
| **Pending** | Total number of assignments not yet submitted | Total assignments minus total submissions |
| **Late Items** | Total number of submissions that were turned in after the due date | Count of submissions where `is_late = true` |
| **Compliance** | Overall submission rate percentage | `(total submissions / total assignments) × 100`. Displayed with one decimal place, e.g., "72.5%" |

### 2. Submission Status (Donut Chart)

- A donut/ring chart showing three segments:
  - **Submitted** (green, #188038): submissions that were turned in on time or late
  - **Pending** (amber, #f29900): assignments with no submission record
  - **Late** (red, #d93025): submissions marked as late
- The center of the donut displays the overall **Completion** rate percentage (same as the Compliance card).
- A legend below the chart identifies each segment.

### 3. Engagement Trend (Area Chart)

- An area chart showing submission counts for the **last 10 homework assignments** (or fewer if there are fewer than 10).
- The X-axis shows homework titles.
- The Y-axis shows the number of submissions for each homework.
- A single data series (blue line, #1a73e8) with a gradient fill shows how submission volume has changed over time.
- Helps teachers visually identify which homeworks had low submission engagement.

### 4. Homework Submission Ledger Table

The main data table listing every homework that matches the filters:

| Column | What It Shows |
|--------|--------------|
| **#** | Row number (accounts for pagination, so page 2 starts at 16) |
| **Homework Item** | Homework title in bold, with a system ID below in grey (formatted as 5-digit zero-padded, e.g., #00042) |
| **Class** | Class name as a light badge |
| **Subject** | Subject name as a light badge |
| **Assign Date** | Date the homework was assigned (formatted as DD-Mon-YY, e.g., "15-Jan-26") |
| **Due Date** | Submission deadline (same date format) |
| **Assigned** | Number of students this homework was assigned to |
| **Subm.** | Number of submissions received (green text) |
| **Late** | Count of late submissions — shown as a red badge if > 0, or a neutral grey badge if 0 |
| **Graded** | Count of submissions that have been graded (marks_obtained is not null) |
| **Pending** | Count of assignments not yet submitted — shown as a yellow badge if > 0, or a green badge if 0 (indicating complete) |
| **Action** | Eye icon button that opens the student submission detail modal |

**Pagination**: The table shows 15 homework records per page. A Bootstrap pagination component is rendered at the bottom.

### 5. Student Submission Detail Modal

Clicking the eye icon on any homework row opens a large modal dialog showing individual student submission details:

| Column | What It Shows |
|--------|--------------|
| **#** | Row number within modal |
| **Student** | Student name with an avatar circle showing the first letter of their name, on a light primary background |
| **Submitted At** | Date and time the submission was made (formatted as DD-Mon-YY HH:MM), or "—" if not submitted |
| **Status** | One of four possible statuses (see **Submission Status Labels** below) |
| **Timing** | Green "On Time" badge or Red "Late" badge |
| **Marks** | Marks obtained (if graded) or "—" if not yet graded |
| **Feedback** | Teacher's feedback text, truncated to 50 characters with "..." if longer, or "—" if no feedback |

**Submission Status Labels**:
| Status | When It Appears |
|--------|----------------|
| **Pending** | No submission record exists for this student |
| **Submitted** | Submission exists but has not been graded yet (marks_obtained is null) |
| **Graded** | Submission exists AND marks have been given (marks_obtained is not null) |
| **Resubmission Requested** | Submission has `is_resubmission_requested = true` |

**Modal Pagination**: The modal has its own client-side pagination:
- 10 records per page
- Shows "Showing X-Y of Z students"
- Page navigation with first/prev/page numbers/next/last controls
- Ellipsis (...) for large page sets (more than 7 pages, only nearby pages shown)

---

## Business Rules & Filters

### Date Range Default
If the user does not select a date range, the system defaults to the last 30 days (`now() - 30 days` to `now()`). Both start and end dates are inclusive — the start date is set to beginning of day (00:00:00) and the end date to end of day (23:59:59).

### Date Range Presets
The date range picker offers four presets:
- **Today**: From current date 00:00:00 to current date 23:59:59
- **Last 7 Days**: From 6 days ago to today
- **Last 30 Days**: From 29 days ago to today (default when no dates selected)
- **This Month**: From 1st of current month to end of current month

### Section Filter Logic
When a section is selected, the query includes homeworks that match the section OR have a null section ID. This is because homeworks can be assigned to an entire class (no specific section), and those should still appear when filtering by a specific section within that class. The query uses: `WHERE section_id = X OR section_id IS NULL`. This ensures class-wide homeworks are not lost when drilling into a specific section.

### Class, Subject, Lesson, Topic Cascade
All dropdowns are dependent on their parent:
- Class is independent.
- Section and Subject depend on Class. They are disabled until a class is selected.
- Lesson depends on Subject. Disabled until subject is selected.
- Topic depends on Lesson. Disabled until lesson is selected.

When Class changes, Section and Subject reload via AJAX. Lesson and Topic reset to "All" placeholder.

When Subject changes, Lesson reloads via AJAX. Topic resets to "All" placeholder.

When Lesson changes, Topic reloads via AJAX.

### Resubmission Tracking
The code counts resubmission requests (`is_resubmission_requested = true`) but this count is **not displayed** anywhere in the table or modal. This is a calculated metric (`#resubm`) that is stored in the data structure but not rendered in the view. The original requirement does not mention resubmission tracking.

### Status Priority
When determining a submission's status label, the code checks in this order:
1. If no submission exists → "Pending"
2. If `is_resubmission_requested` is true → "Resubmission Requested"
3. If `marks_obtained` is not null → "Graded"
4. Otherwise → "Submitted"

This means a "Resubmission Requested" label takes precedence over "Graded" even if marks have been assigned. A submission that has both marks and a resubmission flag will show "Resubmission Requested", not "Graded".

### Late vs. On Time
The "Timing" column in the modal is determined by the `is_late` boolean flag on the submission record. This flag must be set when the submission is recorded or updated — it is not automatically calculated based on the due date and submission timestamp. If `is_late` is null or false, the submission is considered "On Time". If true, it shows "Late" with a red badge.

### Graded Count
A submission is considered "graded" if `marks_obtained` is not null. This means a submission can have `marks_obtained = 0` and still be considered graded (the teacher may have given zero marks). There is no way to distinguish between "graded with zero marks" and "submitted but not yet graded" in the current implementation.

### Compliance Rate Calculation
The compliance rate shown in the metric card and donut chart center is calculated as:
`(total submissions across all homeworks / total assignments across all homeworks) × 100`
This is labeled as "avg_rate" in the data. If no assignments exist, the rate is 0.

### Pagination Behaviors
**Main table**: 15 homework records per page. Uses Laravel's `LengthAwarePaginator`. The page number is read from the `page` query parameter in the URL. Pagination links use Bootstrap 4 style.

**Detail modal**: 10 student records per page. This is client-side pagination using pure JavaScript (no framework). The pagination state is stored in a global `window.hwPagin` object, keyed by homework ID, to support multiple modals on the same page. Each modal instance has its own independent pagination state.

---

## Error Scenarios

| Scenario | What Happens |
|----------|-------------|
| No homeworks match filters | A centered card appears with "No Submission Data Found" message, a clipboard icon, and a "Clear Filters" button. No metrics, charts, or table are rendered |
| Homework has no assignments | Shows 0 for Assigned, Subm., Late, Graded, Pending columns. Chart data includes it but with zero values |
| Homework has no submissions for a specific student | Modal shows that student with "Pending" status, "—" for submitted date, "—" for marks, and "—" for feedback |
| Modal has many students (e.g., 100+) | Client-side JavaScript pagination handles 10 records per page with ellipsis navigation for large page sets |
| Student name is missing/null | Shows "—" in the modal student name field. Avatar initial falls back to "?" |
| Feedback text is very long | Truncated to 50 characters with "..." appended. The full text is not available via tooltip or expand — it is permanently truncated in the modal view |
| Date range picker cancelled | Clears both hidden date fields and the display field. On form submission, no date range is sent, so the controller defaults to the last 30 days |
| AJAX dependency call fails (class→sections/subjects) | jQuery.ajax error handler logs a console error. The affected dropdowns remain in loading state or show stale placeholder options. User must refresh the page to retry |
| AJAX dependency call fails (subject→lessons) | Same behavior — console error logged, lesson dropdown stays disabled |
| AJAX dependency call fails (lesson→topics) | Topic dropdown stays disabled or shows placeholder |
| Homework ID is very large | Displayed as 5-digit zero-padded ID (e.g., #00042). If ID exceeds 99999, the padding still works but the number will have more than 5 digits |
| Submission has is_late = null | Treated as "not late" (falsey). The modal shows "On Time" badge |
| Submission has marks_obtained = 0 | Treated as graded (since marks_obtained is not null). Shows "0" in marks column with "Graded" status. This is ambiguous — the student may have genuinely scored 0 or the submission may not have been graded yet |
| Submission has is_resubmission_requested = true AND marks_obtained is not null | Status shows "Resubmission Requested" (takes priority over "Graded") |
| All students submitted on time for a homework | Late count is 0 — badge shows grey neutral style. Pending count is 0 — badge shows green ("complete") style |
| Some students are pending but none are late | Donut chart still shows three segments: Submitted (green), Pending (amber), Late (red) with late = 0. The Late segment may be invisible (zero-height) but still present in the chart data |

---

## Permissions

- **Required Permission**: `tenant.lms-exam-report.viewAny`
- Same permission covers all six report tabs
- The index controller method gates this permission at the entry point

---

## Related Screens

- **HW Performance Analysis** — Shows per-student performance scores (not submission status) across homeworks in a color-coded matrix
- **LMS Activity Dashboard** — High-level count comparison of homework vs exam activities
- **Exam Result Report** — The exam equivalent of this tracker, showing pass/fail and grades

---

## Known Gaps Between Requirements and Code

1. **Resubmission Count Not Displayed** — The code calculates `#resubm` (resubmission requests) for each homework, and this data is part of the `totals` structure. However, the view's table does NOT include a "Resubmission" column, and the original requirement does not mention resubmission tracking at all. This means resubmission data is computed but invisible to the user.

2. **"Assignments" Metric Label Is Misleading** — The first metric card is labeled "Assignments" with subtitle "Audited Units," but the value shown is `total_students` which is actually the sum of assignment counts (total expected submissions), not the count of homework assignments. The card labeled "Assignments" should probably be named "Expected Submissions" or similar for clarity.

3. **No Resubmission Filter** — There is no filter or indicator to show homeworks that have resubmission requests pending.

4. **Late Badge Color Logic** — The `#late` column in the table shows a red badge only if late count > 0, grey otherwise. However, the requirement does not specify this conditional coloring behavior.

5. **No "Submitted On Time" Metric** — The donut chart combines on-time and late into a single "Submitted" slice, and has a separate "Late" slice. There is no way to see how many submissions were on time vs late in a single metric — you must subtract Late from Submitted mentally.

6. **"Graded" is a Binary Check** — The code considers a submission "graded" if `marks_obtained !== null`. This includes scores of 0, which could represent a genuine zero score or an ungraded submission where the field defaults to 0. There is no distinction between "graded with zero marks" and "not yet graded."
