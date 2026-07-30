# Online Assessment — Evaluation Summary Dashboard and Paper Check Grading Workspace for Online Exams

---

## What Does This Screen Do?

This screen serves two distinct but connected purposes, arranged in two layers:

**Layer 1 — The Summary Dashboard**: This is a table-based overview that shows every online exam paper along with real-time evaluation statistics. You can see at a glance how many students were assigned to each paper, how many have submitted their work, and how many have been fully checked. From here, you can navigate to a detailed per-student report or dive into the grading workspace.

**Layer 2 — The Paper Check Workspace**: This is an advanced, full-screen grading environment with three panels. On the left, you see a list of questions and their marks. In the center, the student's submitted PDF answer sheet is rendered with an interactive annotation layer. On the right, you have tools to select students, annotate the PDF, mark malpractice, and submit final grades. This is where the actual evaluation happens — you read each student's answers, assign marks per question with a right-click context menu, stamp correct/wrong indicators directly on the PDF, add comments, and finalize the grade.

The screen is designed to give teachers both a high-level progress view (Layer 1) and a detailed, hands-on grading tool (Layer 2) in one seamless workflow.

## Real-Life Example

**Layer 1 scenario**: You are a mathematics teacher who gave an online exam to 120 students across two sections. The exam has 20 auto-graded MCQs and 5 long-answer problems you need to grade manually.

You open the Online Assessment tab. The summary table shows two rows — one for Section A's paper and one for Section B's. For Section A: 60 assigned, 58 submitted, 12 checked. For Section B: 60 assigned, 55 submitted, 8 checked. You have 93 papers still to grade. The progress overview helps you plan your workload.

**Layer 2 scenario**: You click the "Check" button for Section A's paper. The Paper Check interface opens. You select the first student from the dropdown. Their PDF answer sheet appears in the center viewer. On the left, you see the 5 long-answer questions listed with marks fields. You right-click on the student's answer to problem 1, a small menu pops up, you enter "4" out of 5 marks. The total at the top updates from "0/25" to "4/25". You stamp a green checkmark on a correct calculation. For problem 3 where the student made an error, you stamp a red X and add a comment explaining the mistake. Finally, you click "Final Review" and submit the grade with feedback.

## How It Works — Layer 1: The Summary Dashboard

### Accessing the Summary

The Online Assessment tab is part of the "Assessment & Marks" page, alongside the Offline Assessment tab. The page loads at the route `lms-exam.assessment.index`. Both tabs use the same controller method (`LmsExamController@assessment()`) which loads data for both online and offline summaries in a single request.

The controller checks BOTH permissions: `tenant.online-assessment.view` AND `tenant.offline-assessment.view` — if the user lacks either, access is denied.

### Filtering the Summary

The filter bar provides these options:

1. **Class/Section** (class_section_id): A single combined dropdown of all active class-section pairs. When selected, it triggers a cascading AJAX call to load subjects for that class.

2. **Subject** (subject_id): Dynamically loaded when a class/section is selected. Lists all active subjects.

3. **Exam** (exam_id): Lists all active exams. Also triggers cascading for papers.

4. **Paper** (exam_paper_id): Dynamically loaded when an exam is selected. Shows paper names.

5. **Paper Set** (exam_set_id): Dynamically loaded when a paper is selected. Shows set names. Behind the scenes, filtering by set uses a `whereHas('paperSets')` relationship check.

6. **Date Range**: A daterangepicker widget. When you select a date range, it auto-submits the filter form immediately. The same happens when you clear the date range. The picker offers preset ranges: Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month. The dates are stored in hidden inputs (`date_from`, `date_to`) in YYYY-MM-DD format. The filter checks the exam's `start_date` field, not submission date.

7. **Search**: A text input that searches across three fields: paper title, paper code, and parent exam title. Uses a `LIKE %search%` query.

There are also two hidden inputs:
- `data_type`: Always set to "SUMMARY" by default
- `mode`: Set to "ONLINE" for the online assessment tab (used for routing purposes)

The Search button and Reset button (circular arrow) complete the filter bar.

### The Summary Table

The query behind the table starts from the `lms_exam_papers` table with related exam, class, subject, and status data. It applies the common filters (class_section → class_id, subject_id, exam_id, paper_id, set_id, date range, search) and then adds three sub-queries via `withCount()`:

- **total_assigned**: Count of related allocations records
- **total_submitted**: Count of related attempts whose status is in: SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED
- **total_checked**: Count of related attempts whose status is in: EVALUATED, RESULT_PUBLISHED
- **total_evaluated**: Count of related results records

The results are paginated (10 per page) with query string persistence.

**Table columns**:

| Column | Content |
|--------|---------|
| **Exam Title** | Paper title (bold), paper code and parent exam title (small gray text below) |
| **Class/Section/Subject** | Class name (blue badge), Section name (light badge, or "Mixed" if multiple sections), Subject name (small gray text) |
| **Mode** | "Online" blue badge |
| **Exam Date** | Exam start date formatted as "d M, Y" (e.g., "23 Jul, 2026") |
| **Assigned** | Blue badge with count |
| **Submitted** | Blue badge with count |
| **Checked** | Green badge with count |
| **Action** | Two buttons: Report (opens detailed result report) and Check (opens Paper Check interface) |

The Check button always routes to `lms-exam.exam.paper-check` for online papers. However, if the paper's mode is OFFLINE and it is handled through the Online Assessment tab route, the `examPaperCheck()` controller method checks the paper's mode and redirects to the appropriate offline or bulk check route if needed.

### Empty State

If no papers match the current filters, the table shows a centered message: "No exams found for the selected filters."

### Page Information

Above the table, a badge shows the total number of exam papers found: `{total} exams`.

## How It Works — Layer 2: The Paper Check Workspace

When you click the "Check" button for a paper, the Paper Check interface opens as a full-page view.

### Loading the Workspace

The controller method `examPaperCheck()` does the following:

1. **Finds the paper** and loads its related exam, class, subject, and paper sets
2. **Checks if it should redirect**: If the paper is OFFLINE with BULK_TOTAL mode (and `is_ques_wise_file_upload != 1`), it redirects to the bulk check route. If it's OFFLINE but question-wise, it loads the offline question-wise check view instead.
3. **For ONLINE mode**: Loads all attempts for this paper with status in SUBMITTED, EVALUATED, RESULT_PUBLISHED, or EVALUATION_PENDING. These populate the student selector dropdown.
4. **For OFFLINE mode** (when reached through this route): Auto-creates EVALUATION_PENDING attempt stubs for every allocated student who doesn't already have an attempt. This ensures every student appears in the dropdown even if they never submitted anything digitally.

### The Three-Column Layout

#### Left Panel: Marks List

This panel shows a table of all questions from the paper set. Each row has:
- **Q#**: Question number
- **Max**: Maximum marks for the question
- **Marks**: An input field where the teacher enters awarded marks
- **Action**: Linked to the annotation system

Above the table, a badge shows the running total: "0 / [total_marks]" (e.g., "0 / 100"). As you enter marks per question, this total updates automatically.

Below the table, there is a hidden marking list and page list used by the JavaScript system to track annotations.

On mobile screens, this panel collapses into a tab accessible via a "Questions" button.

#### Center Panel: PDF Viewer

This is the heart of the grading interface. It uses **pdf.js** (version 3.11.174) to render the student's uploaded answer sheet PDF.

**When no student is selected**: A placeholder shows a large PDF icon and text: "Right click on answer area to open Marks Menu."

**When a student is selected**: The PDF is rendered page by page on an HTML5 canvas. The viewer supports:
- **Page navigation**: Previous/Next buttons, page indicator ("Page X / Y")
- **Zoom**: Zoom in (+), Zoom out (-), percentage indicator, reset view
- **Rotation**: Rotate 90 degrees clockwise
- **Page rendering**: The canvas is wrapped in a styled container with a drop shadow

**The Annotation Layer**: An absolutely positioned `<div>` sits on top of the canvas. This is where annotation items (correct stamps, wrong stamps, marks, comments, etc.) are rendered as positioned elements. Annotations can be:
- **Dragged** to reposition them on the PDF
- **Deleted** individually by clicking the delete annotation button
- **Batch-deleted** by dragging them to the "Drop to delete" zone at the top of the panel

The annotation items have hover effects (scale up, show active border) and a minimum size for usability.

A "Drop to delete" zone is visible at the top of the panel header. When an annotation is being dragged, the zone changes appearance (red background, red border) to signal it's active.

**Loading state**: A full-screen spinner overlay with "Loading PDF, please wait…" message appears during PDF rendering.

**MathJax support**: MathJax is loaded to render any mathematical equations in the questions or answers.

On mobile screens, this panel is the default visible tab ("Viewer").

#### Right Panel: Tools

This panel contains all the teacher's controls:

**Student Selector**: A dropdown listing all students who have attempts for this paper. Each option shows: "Student Name (STATUS)". The option carries data attributes: `data-submission-id`, `data-student-id`, `data-paper-set-id`, `data-has-submission`.

**Document Selector**: If a student has uploaded multiple documents, this dropdown lets you switch between them. Initially shows "- No Student -" until a student is selected.

**Action Buttons**:
- **Question Paper** (file icon): Opens the paper's question set in a new tab. Uses the selected student's `data-paper-set-id` attribute; falls back to the paper's first active set if unavailable. If no valid set is found, shows an error: "No active question set found for this paper."
- **Solutions** (lightbulb icon): Intended to display model answers
- **UFM — Unfair Means** (warning triangle, yellow): Flags the student's attempt as potentially fraudulent
- **Reject** (ban symbol, red): Marks the attempt as rejected entirely
- **Final Review** (checkmark, green): Opens the Grade modal to finalize evaluation
- **Open Annotated PDF** (printer icon): Generates a print-ready annotated PDF
- **Reset Session** (counter-clockwise arrow, red): Clears all unsaved changes

**Page Controls**: Buttons for previous page, next page, zoom out, zoom in, rotate, reset view, and delete selected annotation.

**Annotation Toolbar**: Nine tools arranged as icon buttons:
1. **Marks** (123 icon, default tool): Click on the PDF, then right-click to open a marks context menu where you enter a score for a question
2. **Correct** (green checkmark): Stamp a correct indicator on the answer
3. **Wrong** (red X): Stamp a wrong indicator
4. **Repeat** (circular arrows): Mark an answer as a repeat/duplicate submission
5. **Blank** (file with minus): Mark a section as blank (no answer given)
6. **View** (eye icon): Mark that you have reviewed this portion
7. **Comment** (chat bubble): Place a text comment on the PDF
8. **Text** (font icon): Insert a free-form text box
9. **Pen** (pen icon): Freehand drawing tool for circling, underlining, etc.

The active tool is displayed at the bottom of the PDF viewer panel. The right panel shows the active tool name in a badge.

### The Grade Modal (Final Review)

Clicking "Final Review" opens a modal with two columns:

**Left Column — Submission Details**:
- **Submission Information** card: Student Name (bold) and Exam Paper title in two columns
- **Evaluation Summary**: A scrollable text area for evaluation notes

**Right Column — Grading Form**:
- **Grading Status**: A required dropdown with options:
  - (blank — must select)
  - Checked (value 1)
  - Needs Revision (value 2)
  - Excellent (value 3)
  - Pass (value 4)
  - Fail (value 5)
- **Marks Obtained**: A numeric input (accepts decimals, step 0.01). Below the input shows the denominator: "/ [total_marks]"
- **Teacher Feedback**: A multi-line text area (5 rows) with placeholder "Provide constructive feedback..."
- **Publish Result**: A toggle switch (default ON, checked). When enabled, the result is immediately visible to the student. When disabled, the grade is saved but remains hidden from the student.

A hidden input stores the attempt ID.

**Submission**: The form uses HTTP PUT method and submits to the `submit_grade` route. On success, a toast notification appears. On failure, an error is shown.

### Additional Modals

- **Confirm Submission Modal**: Appears when certain actions need confirmation before proceeding
- **Info Modal**: A large scrollable modal for displaying detailed information (e.g., annotation summaries)

### Mobile Responsiveness

On screens narrower than 992px (tablets, phones), the three-column layout collapses into tabbed panels. A navigation bar with three buttons — Viewer, Questions, Tools — lets you switch between the panels. The panel heights adjust to auto-height on mobile.

### Print Support

The interface has a built-in print mode. When printing, the annotation toolbar, navigation, and other UI elements are hidden via `.d-print-none` classes, and a dedicated print report section becomes visible via `.d-print-block`.

## Business Rules

| Rule | Details |
|------|---------|
| Permissions | Requires BOTH `tenant.online-assessment.view` AND `tenant.offline-assessment.view` for the summary. Paper Check requires `tenant.exam.viewAny` |
| Mode filtering | Online tab only shows papers with `mode = 'ONLINE'` |
| Count: Assigned | Uses `withCount('allocations')` |
| Count: Submitted | Uses `withCount` with status filter: SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED |
| Count: Checked | Uses `withCount` with status filter: EVALUATED, RESULT_PUBLISHED |
| Pagination | 10 per page, filter state preserved via `appends(['active_tab' => ...])` |
| Class/Section filter | Looks up ClassSection record to get class_id, then filters papers by that class_id |
| Date range filter | Filters on exam's `start_date`, not submission date. Auto-submits on apply and on cancel (clear) |
| Search scope | Searches paper title, paper code, and parent exam title |
| Cascading: Class→Subject | Changes to class_section_id triggers AJAX load of subjects for that class |
| Cascading: Exam→Paper | Changes to exam_id triggers AJAX load of papers for that exam |
| Cascading: Paper→Set | Changes to exam_paper_id triggers AJAX load of sets for that paper |
| Class section cache | ClassSection list is cached for 3600 seconds |
| Paper Check: auto-redirect | If an ONLINE paper check is requested for an OFFLINE bulk paper, redirects to bulk check |
| Paper Check: offline stub creation | For OFFLINE papers reached through this route, auto-creates EVALUATION_PENDING attempts for all allocated students without an attempt |
| Paper Check: online attempt scope | Only loads attempts with status SUBMITTED, EVALUATED, RESULT_PUBLISHED, or EVALUATION_PENDING |
| Student selector | Shows all attempts with student name and status |
| View Question Paper | Uses selected student's paper set ID; falls back to paper's first active set |
| Grade modal: method | HTTP PUT |
| Grade modal: publish toggle | Default ON. When ON, student can see result immediately. When OFF, grades are saved privately |
| Grade modal: status values | Checked (1), Needs Revision (2), Excellent (3), Pass (4), Fail (5) |
| Grade modal: marks | Numeric with decimal support, step 0.01 |
| Annotation: default tool | Marks tool (right-click to assign marks) |
| Annotation: tools | 9 tools: mark, correct, wrong, repeat, blank, view, comment, text, pen |
| Annotation: deletion | Drag to "Drop to delete" zone or use delete button |
| Annotation: positioning | Annotations are placed at the cursor position on the PDF canvas and stored as xRatio/yRatio for responsive positioning |
| Printing | UI elements hidden via `d-print-none` during print; dedicated print report shown via `d-print-block` |
| Mobile breakpoint | 991.98px — below this, panels switch to tabbed layout |
| External libraries | pdf.js 3.11.174, jspdf 2.5.2, MathJax 2, Bootstrap Icons, SweetAlert2, daterangepicker |

## Validation & Error Messages

| Scenario | What the user sees |
|----------|-------------------|
| No exams match filters | "No exams found for the selected filters." in the table body |
| PDF loading | Spinner overlay: "Loading PDF, please wait…" |
| No student selected in Paper Check | Placeholder: "Right click on answer area to open Marks Menu." and large PDF icon |
| View Question Paper — no set | Error: "No active question set found for this paper." |
| Grade submitted successfully | Toast notification (bottom-right) |
| Annotation dragged to delete zone | Zone turns red with visual feedback |
| Date range selected/cleared | Form auto-submits |
| Mobile view | Three tab buttons appear: Viewer, Questions, Tools |

## Permissions

| Permission | What it controls |
|-----------|-----------------|
| `tenant.online-assessment.view` | View the Online Assessment summary tab |
| `tenant.offline-assessment.view` | Also required alongside online view |
| `tenant.exam.viewAny` | Access to the Paper Check grading interface |

## Related Screens

| Screen | Relationship |
|--------|-------------|
| **Offline Assessment** | The sibling tab on the same page, showing offline exam evaluation progress |
| **Online Upload** | Where teachers upload corrected answer sheets for descriptive questions (pre-grading step) |
| **Detailed Report** | Per-student result report for a specific paper (Report button) |
| **View Set Questions** | Opens the question paper in a new tab |
| **Paper Check (Offline)** | The equivalent grading interface for offline question-wise exams |
| **Bulk Paper Check** | Simplified grading interface for offline bulk-total exams |
