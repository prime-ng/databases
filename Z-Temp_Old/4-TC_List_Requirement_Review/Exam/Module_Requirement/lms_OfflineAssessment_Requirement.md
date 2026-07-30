# Offline Assessment — Evaluation Summary and Paper Check Workspaces for Offline Exams

---

## What Does This Screen Do?

This screen is the teacher's complete command center for managing the evaluation of offline (traditional pen-and-paper) exams. It has two distinct layers:

**Layer 1 — The Summary Dashboard**: A table showing all offline exam papers with real-time statistics — how many students were assigned, how many have been processed, and how many are fully checked. This gives the teacher an instant overview of evaluation progress across all offline exams.

**Layer 2 — Two Grading Workspaces**: Depending on how the exam paper was configured, clicking "Check" leads to one of two completely different interfaces:

   **The Question-Wise Offline Check** — A full three-column workspace (Marks List, PDF Viewer, Tools) for grading exams where each question is marked individually. This is nearly identical to the Online Paper Check interface, with per-question marks entry, PDF annotation with stamps and comments, and a detailed grade modal.

   **The Bulk Total Check** — A simpler, two-panel layout for exams where only a single total mark is assigned per student. A student list with radio-button selection sits on the left, the PDF viewer in the center, and tools on the right. The grade modal is shorter — just status, marks, and feedback — because there's no per-question breakdown.

The screen bridges the gap between the physical world (paper answer sheets) and the digital system, allowing teachers to record grades, annotate scanned answer sheets, and publish results — all from one place.

## Real-Life Example

**Summary view**: You are a history teacher. You administered two offline exams — "History MCQs" (50 auto-graded questions on a bubble sheet, bulk entry) and "History Essays" (3 long-form essays, question-wise grading).

You open the Offline Assessment tab and see two rows:
- "History MCQs" — 60 assigned, 60 submitted (answer sheets scanned), 40 checked. You still have 20 to go.
- "History Essays" — 60 assigned, 55 answer sheets uploaded, 5 checked. You have 50 essays to grade.

**Bulk Check scenario**: You click "Check" for "History MCQs". The Bulk Check interface opens. On the left is a list of 60 students. The first student, Aarav Sharma, is auto-selected. His scanned answer sheet PDF appears in the center viewer. On the right, you see the page controls and annotation toolbar. You scroll through his bubble sheet, stamp a green checkmark on the completed sections, enter "42" in the marks field, and click Save. The student list updates to show "42" as his mark. You click the next student, and repeat.

**Question-Wise scenario**: You click "Check" for "History Essays". The system auto-creates attempt records for all 60 students who were allocated (even if they haven't submitted a digital file). The Question-Wise Offline Check opens with the same three-column layout as online. You select the first student, their scanned essay PDF loads. On the left, you see 3 essay questions with marks fields. You read each essay, enter marks per question, stamp correct/wrong indicators, add comments, then click "Final Review" to submit the grade with feedback.

## How It Works — Layer 1: The Summary Dashboard

### Accessing the Summary

The Offline Assessment tab sits alongside the Online Assessment tab on the "Assessment & Marks" page. Both tabs share the same controller method (`LmsExamController@assessment()`), which loads data for BOTH tabs in a single database query and then splits the results by mode.

The controller checks BOTH permissions: `tenant.online-assessment.view` AND `tenant.offline-assessment.view`.

### Filters

The filter bar on the Offline Assessment tab is nearly identical to the Online Assessment tab:

1. **Class/Section** (class_section_id): A combined class-section dropdown. Select triggers loading of subjects.
2. **Subject** (subject_id): Dynamically loaded.
3. **Exam** (exam_id): Lists active exams. Triggers paper loading.
4. **Paper** (exam_paper_id): Dynamically loaded.
5. **Paper Set** (exam_set_id): Dynamically loaded from paper.
6. **Date Range**: Auto-submitting daterangepicker with presets. Filters by exam start_date.
7. **Search**: Text search across paper title, paper code, and exam title.

Hidden inputs: `data_type = 'SUMMARY'`, `active_tab = 'offline_assessment'`, `mode = 'OFFLINE'`.

### The Summary Table

The offline summary query takes the same base query as online (from `lms_exam_papers` with related data) and applies a `where('mode', 'OFFLINE')` filter. The same `withCount()` sub-queries calculate:
- **total_assigned**: Count of allocations
- **total_submitted**: Count of attempts with status in (SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED)
- **total_checked**: Count of attempts with status in (EVALUATED, RESULT_PUBLISHED)
- **total_evaluated**: Count of results

Results are paginated (10 per page).

**Table columns**: Same structure as online — Exam Title, Class/Section/Subject, Mode, Exam Date, Assigned, Submitted, Checked, Action.

**Mode column**: Shows "Offline" badge (gray) with a sub-badge indicating the entry mode:
- If `is_ques_wise_file_upload == 1` → "Question Wise"
- Otherwise → "Bulk"
Note: The summary uses `is_ques_wise_file_upload`, NOT `offline_entry_mode`, to determine the sub-badge text.

**Action column**:
- **Report** button (bar chart icon, outlined primary): Always shown. Opens the detailed per-student result report for that paper.
- **Check** button: Two different buttons based on the same `is_ques_wise_file_upload` flag:
  - If `is_ques_wise_file_upload == 1`: Opens the Question-Wise Offline Check route (`lms-exam.exam.paper-check-offline`). Button is outlined info with file-alt icon.
  - Otherwise (Bulk): Opens the Bulk Paper Check route (`lms-exam.exam.paper-check.bulk`). Button is outlined warning with list-ol icon.

The labels and icons differ slightly to help teachers visually distinguish between the two modes.

### Empty State

"No exams found for the selected filters." appears when no offline papers match the current filter criteria.

## How It Works — Layer 2a: Question-Wise Offline Check

### Loading the Interface

When you click "Check" for a question-wise offline paper, the `examPaperCheckOffline()` controller method runs:

1. **Finds the paper** with related exam, class, subject, and paper sets
2. **Auto-creates attempt stubs**: Iterates through every allocation for this paper. For each allocated student who does NOT already have an attempt record, the system creates an `ExamAttempt` with:
   - `status = 'EVALUATION_PENDING'`
   - `attempt_mode = 'OFFLINE'`
   - `paper_set_id` = the first active set found for this paper
   - `is_active = true`
   - `created_by` = the current logged-in user
   
   This ensures every allocated student appears in the student selector dropdown, even if they never submitted anything digitally.
3. **Loads attempts**: Fetches all attempts for this paper with status in EVALUATION_PENDING, SUBMITTED, EVALUATED, or RESULT_PUBLISHED.
4. **Returns the view**: Renders the `paper-check.offline-check` blade template.

### The Three-Column Layout

The layout is structurally identical to the Online Paper Check:

**Left Panel — Marks List**:
- Header with "Marks" title and running total badge (e.g., "0 / 100")
- Table of questions (Q#, Max marks, Marks input, Action)
- Questions are loaded via a dedicated offline route (`lms-exam.exam.question-wise.data-offline`) which returns questions from the paper set with existing answers

**Center Panel — PDF Viewer**:
- pdf.js renders the student's submitted answer sheet PDF
- Page navigation (prev/next, page indicator)
- Zoom controls (in/out, percentage, reset)
- Rotate button
- Annotation layer for placing stamps, marks, and comments
- "Drop to delete" zone for removing annotations by drag-and-drop

**Right Panel — Tools**:
- **Student Selector**: Dropdown of all attempts (thanks to auto-creation, ALL allocated students appear)
- **Document Selector**: Switch between multiple uploaded documents per student
- **Question Paper button**: Opens paper set in new tab (uses student's set ID with fallback)
- **Solutions button**: Shows model answers
- **UFM flag** (yellow warning triangle): Mark as Unfair Means
- **Reject flag** (red ban symbol): Reject the submission
- **Final Review** (green checkmark): Opens Grade modal for final evaluation
- **Open Annotated PDF / Reset Session**
- **Page navigation and zoom controls**
- **Annotation Toolbar**: Same 9 tools as online check:
  - Marks (right-click context menu, default)
  - Correct (green checkmark stamp)
  - Wrong (red X stamp)
  - Repeat (circular arrows)
  - Blank (file with minus)
  - View (eye icon)
  - Comment (chat bubble)
  - Text (font icon, text box)
  - Pen (pen icon, freehand drawing)

### Dedicated Routes

The Question-Wise Offline Check uses a separate set of API routes from the online version:
- `lms-exam.exam.question-wise.data-offline` — Fetch questions and existing answers
- `lms-exam.exam.question-wise.save-offline` — Save marks for a question
- `lms-exam.exam.paper-check.submit-grade-offline` — Submit final grade
- `lms-exam.exam.paper-check.get-attachment-offline` — Get student attachments

### The Grade Modal (Question-Wise)

Identical to the Online Paper Check grade modal:
- **Left**: Submission Information (student name, exam paper), Evaluation Summary
- **Right**: Grading Status dropdown (Checked/Needs Revision/Excellent/Pass/Fail), Marks Obtained input, Teacher Feedback text area, Publish Result toggle (default ON)
- Submit via HTTP PUT

## How It Works — Layer 2b: Bulk Total Check

### Loading the Interface

When you click "Check" for a bulk total paper, the `examPaperCheckBulk()` controller method runs:

1. **Finds the paper** with related data
2. **Redirect guard**: If the paper is actually ONLINE or has QUESTION_WISE mode or `is_ques_wise_file_upload == 1`, it redirects to the appropriate check route
3. **Resolves allocated students**: Iterates through allocations (CLASS, SECTION, STUDENT types) to determine which students belong to this paper
4. **Maps student data**: For each unique student, creates a row containing:
   - `student_id`, `student_name`
   - `marks_obtained` from the attempt's result record (or null if not yet graded)
   - `teacher_feedback` from the result record
   - `attempt_id` (or null)
   - `status` (or "NOT_STARTED" if no attempt)
   - `paper_set_id`
   - `documents` — file payload from the attempt's uploaded answer sheet
5. **Returns the view**: Renders the `paper-check.bulk` blade template

Note: The Bulk Check does NOT auto-create attempt stubs. Students without attempts will show "NOT_STARTED" status and no marks.

### The Two-Column Layout (Simpler than Question-Wise)

**Left Panel — Student List**:
- Header shows a badge with the paper's total marks (e.g., "50 Max Marks")
- A table with three columns:
  - **Student**: Student name with a user icon
  - **Given Mark**: Current mark (green text) if already entered, or a dash "-" (gray) if pending
  - **Select**: A radio button
- The **first student** in the list is auto-selected (their row is highlighted in blue)
- Clicking anywhere on a row selects that student's radio button via JavaScript
- Each row carries data attributes: `data-student-id`, `data-attempt-id`, `data-paper-set-id`, `data-marks`
- Pagination is handled within the view (the allocation rows are pre-computed in the controller)

**Center Panel — PDF Viewer**:
- Automatically loads the selected student's uploaded answer sheet PDF
- Same rendering engine (pdf.js) with page navigation, zoom, rotate, reset
- Annotation layer with the same drag-and-drop and delete zone features
- When no document is available, shows placeholder: "Select a document to view"

**Right Panel — Tools**:
Simpler than the question-wise version:
- **Question Paper button** (file icon): Opens paper set in new tab. Uses selected student's `data-paper-set-id` attribute; falls back to paper's first active set.
- **Summary button** (lightbulb): Shows a summary view
- **UFM flag** (yellow warning triangle)
- **Reject flag** (red ban symbol)
- **Save button** (floppy disk icon): Saves current marks and annotations
- **Open Document button** (printer icon): Opens annotated PDF
- **Reset button** (counter-clockwise arrow): Clears session
- **Page navigation and zoom controls**
- **Annotation Toolbar**: 8 tools (same as question-wise but without the "Repeat" and "Blank" tools in some versions — the code shows: Mark, View, Correct, Wrong, Repeat, Blank, Comment, Text, Pen)

There is NO "Final Review" button in bulk mode — the Save button serves this purpose.

### The Grade Modal (Bulk)

A simpler version of the question-wise grade modal:
- **Left**: Submission Info card (Student name, Paper title), Submission Notes area
- **Right**: 
  - **Status dropdown**: Checked (default, value 1), Excellent (3), Pass (4), Fail (5). **No "Needs Revision" option.**
  - **Marks input**: Numeric field with step 0.01 and max set to the paper's total marks
  - **Feedback**: Multi-line text area (4 rows)
  - **No "Publish Result" toggle** — results are automatically published when saved
- Hidden input stores the attempt ID

### Save Flow (Bulk)

The Bulk Check saves marks via the `lms-exam.exam.paper-check.bulk-save` route. The save:
1. Creates or updates the `ExamAttempt` record (sets status to EVALUATED, records attendance)
2. Creates or updates the `ExamResult` record (calculates percentage, grade, pass/fail)
3. Creates or updates the `OfflineExamUploadMark` record for consistency
4. Returns success/failure

There is also a separate route for uploading annotated PDFs (`lms-exam.exam.paper-check.bulk-upload-pdf`) which handles file uploads with validation (must be PDF, max 50MB).

## Key Features (Summary)

- Summary table showing offline exam evaluation progress
- Cascading filters including auto-submitting date range picker
- Two distinct grading interfaces: Question-Wise (full featured) and Bulk (simplified)
- Question-Wise: Three-column layout with per-question marks, PDF annotation, and grade modal
- Bulk: Student list with radio selection, auto-loading PDF, annotation tools, and simple grade modal
- Auto-creation of attempt stubs for question-wise offline grading
- Nine annotation tools (question-wise) or eight tools (bulk) for PDF markup
- UFM and Reject flags for flagging suspicious or invalid submissions
- View question paper and solutions
- Open annotated PDF and print
- Responsive mobile layout with collapsible panels
- Pagination on summary table with filter persistence

## Business Rules

| Rule | Details |
|------|---------|
| Permissions | Summary requires BOTH `tenant.online-assessment.view` AND `tenant.offline-assessment.view`. Paper Check requires `tenant.exam.viewAny` |
| Mode filtering | Offline tab only shows papers with `mode = 'OFFLINE'` |
| Action routing | Based on `is_ques_wise_file_upload`: 1 → question-wise check route; otherwise → bulk check route |
| Mode display | Uses `is_ques_wise_file_upload` for sub-badge text, not `offline_entry_mode` |
| Auto-creation (question-wise) | Creates EVALUATION_PENDING attempts for all allocated students without existing attempts, using the paper's first active set |
| No auto-creation (bulk) | Bulk check does NOT create attempt stubs; students without attempts show "NOT_STARTED" |
| Redirect guard (bulk) | If bulk check is opened for an online or question-wise paper, redirects to appropriate route |
| Redirect guard (online route) | If the shared `examPaperCheck` method encounters an offline bulk paper, it redirects to bulk check |
| Count: Submitted | Attempts with status SUBMITTED, EVALUATION_PENDING, EVALUATED, RESULT_PUBLISHED |
| Count: Checked | Attempts with status EVALUATED, RESULT_PUBLISHED |
| Pagination | Summary: 10 per page with filter persistence via `appends(['active_tab' => ...])` |
| Bulk: first student selected | First student row has radio button checked and blue highlight |
| Bulk: row click | Clicking any part of a row selects its radio button |
| Bulk: auto-load PDF | When a student is selected, their uploaded PDF loads automatically in the viewer |
| Bulk: grade modal statuses | Checked (1), Excellent (3), Pass (4), Fail (5) — no Needs Revision |
| Bulk: no publish toggle | Results are always published when saved |
| Bulk: marks validation | Marks must be numeric, max set to paper's total marks |
| Bulk: PDF upload | Separate route, PDF only, max 50MB |
| Bulk: save creates records | Saves/updates attempt, result, and offline marks records |
| Question-wise: grade modal | Identical to online: Checked/Needs Revision/Excellent/Pass/Fail + Publish toggle |
| Question-wise: data routes | Uses dedicated offline routes (data-offline, save-offline, submit-grade-offline) |
| Question-wise: student scope | Shows all allocated students (due to auto-creation) |
| View Question Paper | Uses selected student's paper_set_id; falls back to paper's first active set. If no valid set, shows error |
| Class section filter | Resolves to class_id via ClassSection lookup |
| Date range filter | Filters by exam start_date, auto-submits on apply and cancel |
| Search | Searches paper title, paper code, and exam title |
| Cascading dropdowns | Class/Section → Subject; Exam → Paper → Set |
| Class section cache | Cached for 3600 seconds |

## Validation & Error Messages

| Scenario | What the user sees |
|----------|-------------------|
| No exams match filters | "No exams found for the selected filters." |
| Bulk: no allocations | "No allocations found." |
| Bulk: PDF loading | "Loading document, please wait..." |
| Bulk: no document | Placeholder: "Select a document to view" with large PDF icon |
| Question-wise: View Question Paper — no set | Error: "No active question set found for this paper." |
| Question-wise: PDF loading | Spinner: "Loading PDF, please wait…" |
| Question-wise: grade submitted | Toast notification |
| Bulk: save successful | Success notification — student row updates with new mark |
| Bulk: save fails | Error message from server |
| Bulk: PDF upload fails | Error: "No attempt found for this student." (if no attempt) or file validation error |
| Date range selected/cleared | Form auto-submits |
| Mobile view | Tab buttons: Viewer, Questions, Tools |

## Permissions

| Permission | What it controls |
|-----------|-----------------|
| `tenant.offline-assessment.view` | View the Offline Assessment tab |
| `tenant.online-assessment.view` | Also required by the controller |
| `tenant.exam.viewAny` | Access to both Bulk and Question-Wise Paper Check interfaces |

## Related Screens

| Screen | Relationship |
|--------|-------------|
| **Online Assessment** | The sibling tab on the same page, showing online exam evaluation progress |
| **Offline Upload** | Where teachers upload scanned answer sheet PDFs for offline exams |
| **Detailed Report** | Per-student result report (Report button in summary) |
| **View Set Questions** | Question paper view in new tab |
| **Online Paper Check** | The equivalent grading interface for online exams |
| **Bulk Paper Check** | The specific interface for bulk total offline grading (covered in Layer 2b above) |
| **Question-Wise Offline Check** | The specific interface for question-wise offline grading (covered in Layer 2a above) |
