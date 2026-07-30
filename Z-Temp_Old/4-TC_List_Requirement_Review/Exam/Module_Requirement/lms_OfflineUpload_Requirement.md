# Offline Upload — Recording Marks and Uploading Answer Sheets for Offline Exams

---

## What Does This Screen Do?

This screen is designed for teachers who conducted traditional pen-and-paper exams (offline mode). Unlike online exams where answers are submitted digitally, offline exams produce physical answer sheets that the teacher must grade by hand and then record in the system. This screen is the entry point for that process.

The screen shows a table of all students allocated to a selected offline exam paper. For each student, the teacher can see their attendance status (whether they physically appeared for the exam), whether their answers have been evaluated, and an action button to upload scanned answer sheets or record marks.

The key distinction is that offline exams come in two flavors, determined by the paper's configuration:

**Bulk Total Mode**: The teacher assigns a single overall mark to each student. This is used for simple exams where per-question breakdown is not needed. The upload modal only asks for a PDF file (the scanned answer sheet), and marks are entered later through the Bulk Paper Check screen.

**Question Wise Mode**: The teacher grades each question individually. This is used for detailed exams with a specific marking scheme. The upload modal shows every question from the paper set, allows the teacher to select correct MCQ options (A/B/C/D with radio buttons or checkboxes), and upload scanned answer files for descriptive questions.

## Real-Life Example

You are a geography teacher who just finished a 50-question multiple-choice exam on paper. The exam was set up as "Bulk Total" — you only need to enter final marks per student.

You sit at your computer and open the Offline Upload tab. You filter: Class 9-A, Section Geography, Subject Geography, Exam "Quarterly Exam", Paper "Geography MCQs", Set A. The filter cascading helps you narrow down quickly.

The table shows 38 students. You see:
- 35 marked "Present" (they appeared for the exam), 2 "Absent", 1 "Not Marked"
- 10 students have been checked (green "Yes"), 28 are pending (yellow "No")

For each pending student, you click the Upload button. Since this paper is configured for Bulk Total, a simple modal opens showing any previously uploaded answer sheet PDF with a "View Uploaded Sheet" link and a new file upload field. You upload the scanned answer sheet for each student (you already graded them physically).

Later, you open the Bulk Paper Check screen to actually enter the marks.

But for a different exam — "Geography Essay" — the configuration is Question Wise. Now when you click Upload, a larger modal opens showing each essay question with radio buttons to indicate correctness and file upload fields to attach scanned essays. This is where you do the actual per-question evaluation.

## How It Works

### The Student List

The screen is a tab on the "Answer Sheet Upload" page (sibling to the Online Upload tab).

**Initial State**: The table is empty with the message "Please search to view offline data."

**Filter Bar**: Identical to the Online Upload filter bar:
- Class (triggers cascading load of Sections, Subjects, Exams, and Students)
- Section (refines Subjects and Students when changed)
- Subject (required)
- Exam (required, loads Papers)
- Paper (required, loads Sets)
- Paper Set (required)
- Student (optional, searchable Select2 dropdown)
- Three buttons: Search (submit), Reset (clear filters), View Set Questions (open question paper in new tab)

**Data Loading**: When you click Search, the system:
1. Validates the paper belongs to the selected exam, subject, and has mode = "OFFLINE"
2. Validates the set belongs to the selected paper
3. Resolves allocated students through the allocation system
4. Paginates results (10 per page)

**Table Columns**:
- **Admn No**: Admission number
- **Student Name**: "Roll No: X — Full Name"
- **Exam**: Exam title from filter
- **Paper**: Paper title from filter
- **Paper Set**: Set name from filter
- **Attendance**: Three possible states based on `is_present_offline`:
  - `is_present_offline = 1` → "Present" (green badge)
  - `is_present_offline = 0` → "Absent" (red badge)
  - `is_present_offline` is null → "Not Marked" (gray badge)
- **Checked**: 
  - `is_evaluated` is truthy → "Yes" (green)
  - Otherwise → "No" (yellow)
- **Action**: 
  - **Upload** button (upload icon, primary blue): Opens the appropriate marks entry modal
  - **Attempt Detail** (eye icon, outlined): Only appears if the student has an attempt_id; opens full attempt report in new tab

The Upload button carries data attributes including the student's offline attachment data (JSON) so the modal can show previously uploaded files.

### Two Modes of Marks Entry

The system determines which modal to open based on the paper's configuration. The button's click handler checks:

```
if (offline_entry_mode == 'QUESTION_WISE' OR is_ques_wise_file_upload == 1) {
    open Question-Wise Modal
} else {
    open Bulk Total Modal
}
```

Note: The comparison accepts `'QUESTION_WISE'`, `'1'`, `1`, `true`, and `'true'` — multiple truthy values to handle various data formats from the database.

#### Mode 1: Bulk Total Upload Modal

A simple, clean modal titled "Upload Answer Sheet" with a green header.

**Fields**:
- Three hidden inputs: `student_id`, `exam_paper_id`, `exam_set_id`
- **Existing file preview** (dynamic, hidden if absent):
  - Shows the previously uploaded file name
  - Shows a "View Uploaded Sheet" link that opens the file
  - File URL is built from the storage base path (handles both tenant_asset and regular storage)
- **New file upload**: A file input accepting only PDF files (`application/pdf`)
- A hint text: "Marks can be entered later after checking the paper."
- **Buttons**: Cancel and "Save" (with upload icon)

**Save Flow**:
1. The form data is collected via FormData from the upload form
2. AJAX POST to the bulk upload route (`lms-exam.marks.bulk-upload`)
3. The Save button is disabled and shows "Saving..." during upload
4. On success: "Marks uploaded successfully!" alert → modal closes → page reloads after 1.5 seconds
5. On failure: Shows the server error message or "Something went wrong!" with a generic fallback

This modal does NOT have any marks input field — it is strictly for uploading the scanned answer sheet PDF. Marks are entered separately on the Bulk Paper Check screen.

#### Mode 2: Question-Wise Upload Modal

A larger, more sophisticated modal with a blue-purple gradient header. The title shows "Offline Assessment" as a subtitle and the student's name prominently.

The modal body contains a table with three columns:
- **# Qn**: Question number in a circular badge
- **Question Details**: Shows the question type badge (e.g., "MCQ", "SHORT_ANSWER"), and the question text (truncated with a max-width)
- **Response / Evidence**: This column adapts based on question type:

  **For MCQ-type questions** (identified by `type_code` containing "MCQ"):
  - **Single-correct MCQs** (type_code does not contain "MULTIPLE" or "MSQ"): Shows circular radio buttons labeled A, B, C, D (alphabetically based on option order). Only one can be selected.
  - **Multi-correct MCQs / MSQ** (type_code contains "MULTIPLE" or "MSQ"): Shows square checkbox toggles labeled A, B, C, D. Multiple can be selected.
  - Previously selected options are pre-checked when re-opening the modal (checked against `selected_option_id` for single or `selected_option_ids` for multi).
  - Each option circle/checkbox has a hover effect (border color change) and a checked state (green fill with shadow).
  - The option labels are positioned on top of invisible input elements for accessibility.

  **For descriptive questions** (non-MCQ):
  - If a file was previously uploaded: Shows the file name with a "View" eye icon link (opens in new tab). The link is styled as a small button within a compact card.
  - A file upload input that accepts PDF (`application/pdf`) and images (`image/*`). The input is compact (small height, small font size) to fit within the table cell.

The modal is scrollable (large modal with `.modal-dialog-scrollable`).

**Save Flow**:
1. JavaScript collects all data:
   - Single-select radio options: Reads each checked `qw-single-opt` input. Stores keyed by question ID as `questions[qid][option_id]`.
   - Multi-select checkbox options: Reads each checked `qw-multi-opt` input. Stores keyed by question ID as `questions[qid][option_id][]` (array).
   - File attachments: Reads the `qw-file` inputs. Keys files by question ID (`attachments[qid]`).
2. Sends via AJAX POST with `mode: 'OFFLINE'` parameter
3. On success: "Assessment recorded successfully." → modal closes → page reloads
4. On failure: Shows error message

**XSS Prevention**: All question text, type names, and student names are passed through an `escapeHtml()` JavaScript function that replaces `&`, `<`, `>`, `"`, and `'` with their HTML entities before insertion into the DOM.

### Data Integrity and Security

The system enforces several back-end checks:
- The selected paper must match the selected exam, subject, AND mode (OFFLINE)
- The selected set must belong to the selected paper
- The allocation system resolves which students can see (CLASS/SECTION/STUDENT allocation types)
- Student data is limited to only the logged-in user's authorized scope

### Pagination

The student table renders pagination links when there are more than 10 students. Pagination is conditioned on two checks:
1. The `$studentsData` variable is a paginated collection (has a `links()` method)
2. The URL parameter `active_tab` equals `offline_upload`

All filter parameters are preserved across pagination pages.

### The View Set Questions Button

Located in the filter bar next to the Search and Reset buttons. When clicked, it:
1. Looks for the currently selected Paper Set value in the filter bar
2. If no set is selected: Shows a warning "Please select a Paper Set first."
3. If a set is selected: Opens the route `lms-exam.exam.paper-set.view-questions/:id` in a new browser tab, where `:id` is the selected set's ID

### Reset Button Behavior

The reset button navigates to `url()->current()`, which is the base URL without any query parameters. This effectively clears all filters and returns the page to its initial empty state.

## Business Rules

| Rule | Details |
|------|---------|
| Access control | Tab visibility requires `tenant.answer-sheet-offline-exam.view`. Controller checks both `tenant.online-assessment.view` AND `tenant.offline-assessment.view` |
| Data trigger | Data loads only when BOTH `exam_paper_id` AND `exam_set_id` are present in the request |
| Paper validation | Validates: paper belongs to selected exam, selected subject, and has `mode = 'OFFLINE'` |
| Set validation | Validates: set belongs to selected paper |
| Active tab check | Table renders only when `active_tab = 'offline_upload'` |
| No-search state | "Please search to view offline data." |
| No-results state | "No students found for the selected criteria." |
| Attendance mapping | `is_present_offline = 1` → Present (green); `= 0` → Absent (red); `null` → Not Marked (gray) |
| Evaluation mapping | Truthy `is_evaluated` → Checked Yes; otherwise → Checked No |
| Modal selection logic | Opens QW modal if `offline_entry_mode == 'QUESTION_WISE'` OR `is_ques_wise_file_upload == 1`; otherwise opens Bulk modal |
| Bulk modal: marks | No marks input — only PDF upload. Marks are entered via Bulk Paper Check screen |
| Bulk modal: file type | Accepts only `application/pdf` |
| Bulk modal: existing file | Shows preview with "View Uploaded Sheet" link |
| QW modal: MCQ detection | Based on `type_code` containing "MCQ". Multi-select if type_code contains "MULTIPLE" or "MSQ" |
| QW modal: option labels | Labels are A, B, C, D... derived from array index (65 + index) |
| QW modal: pre-selection | Checks `selected_option_id` (single) or `selected_option_ids` (multi) from previous saves |
| QW modal: file uploads | Accepts `application/pdf` and `image/*` |
| QW modal: save (single) | Sends `questions[qid][option_id]` = single value |
| QW modal: save (multi) | Sends `questions[qid][option_id][]` = array of values |
| QW modal: save (files) | Sends `attachments[qid]` = file object |
| QW modal: data fetch | Uses `mode: 'OFFLINE'` parameter in AJAX GET |
| Save success: Bulk | "Marks uploaded successfully!" → modal closes → page reloads after 1.5s |
| Save success: QW | "Assessment recorded successfully." → modal closes → page reloads immediately |
| Save failure | Shows error message from server or generic "Server error" / "Server communication error" |
| Attempt Detail | Eye button only renders if student has a non-null `attempt_id` |
| Download Question Paper | Opens a separate download URL for the selected paper |
| View Set Questions | Requires a selected paper set; else shows warning |
| XSS protection | `escapeHtml()` function sanitizes all dynamic text before DOM insertion |
| Student dropdown | Uses Select2 with search, "All Students" placeholder, and allowClear |
| Section dropdown | Has `min-width: 250px` |
| Pagination | Only renders when `$studentsData` has `links()` method AND `active_tab = 'offline_upload'` |
| Reset button | Strips all query parameters |
| Autoload on page load | Pre-selected class triggers its change event; pre-selected section triggers after 500ms delay |

## Validation & Error Messages

| Scenario | What the user sees |
|----------|-------------------|
| Page loads with no filters | "Please search to view offline data." |
| Search with no matching students | "No students found for the selected criteria." |
| View Set Questions with no set selected | Warning: "Please select a Paper Set first." |
| Bulk upload successful | "Marks uploaded successfully!" |
| Bulk upload server error | Server error message |
| Bulk upload AJAX error | "Server error!" |
| QW modal loading questions | "Fetching Question Data..." spinner |
| QW modal load fails | "Failed to load data" or "Failed to fetch question data. Please try again." |
| QW save successful | "Assessment recorded successfully." |
| QW save fails | "Failed to save" or "Server communication error" |
| No paper sets for selected paper | Dropdown shows "-- No Paper Sets Available --" |
| During bulk upload save | Save button shows "Saving..." and is disabled |

## Permissions

| Permission | What it controls |
|-----------|-----------------|
| `tenant.answer-sheet-offline-exam.view` | Visibility of the Offline Upload tab |
| `tenant.online-assessment.view` | Controller-level access |
| `tenant.offline-assessment.view` | Controller-level access |

## Related Screens

| Screen | Relationship |
|--------|-------------|
| **Online Upload** | The sibling tab on the same page, for uploading online exam corrected answer sheets |
| **Offline Assessment (Summary)** | Dashboard showing all offline exam papers with evaluation progress counts |
| **Bulk Paper Check** | The marks entry screen for Bulk Total offline exams — where the actual marks are entered after PDF upload |
| **Offline Paper Check (Question-Wise)** | The full grading interface for Question Wise offline exams with PDF annotation |
| **Attempt Detail** | Full student attempt report (new tab) |
| **View Set Questions** | Question paper read-only view (new tab) |

---

## Detailed Interaction Flows — Step by Step

### Scenario 1: Bulk Total Paper — First-Time Marks Entry

1. Teacher navigates to Answer Sheet Upload → Offline Upload tab
2. Screen shows empty table with "Please search to view offline data."
3. Teacher selects Class → Section → Subject → Exam → Paper → Paper Set via cascading dropdowns
4. Clicks Search — table populates with allocated students
5. Attendance column shows "Present" (green), "Absent" (red), or "Not Marked" (gray) for each student
6. For a student with "Not Marked" attendance, teacher clicks the Upload button
7. The system checks the paper's configuration — since it's BULK_TOTAL, the Bulk Upload modal opens
8. If the student already has a previously uploaded answer sheet: the modal shows a preview with "View Uploaded Sheet" link
9. Teacher uploads a new PDF of the scanned answer sheet
10. Clicks Save — the file uploads, a success message appears, the page reloads
11. Teacher repeats for each student. Later, they go to the Bulk Paper Check screen to enter the actual marks

### Scenario 2: Question Wise Paper — Per-Question Grading

1. Teacher filters and searches as above
2. Clicks Upload for a student — since `offline_entry_mode` is 'QUESTION_WISE' or `is_ques_wise_file_upload == 1`, the Question-Wise modal opens
3. A loading spinner appears while the system fetches all questions from the paper set
4. The modal shows a table with every question
5. For MCQ questions: radio buttons (single-correct) or checkboxes (multi-correct) labeled A/B/C/D appear. Previously selected options are pre-checked.
6. For descriptive questions: existing file preview (if any) and file upload input appear
7. Teacher selects the correct MCQ options and/or uploads scanned answer files for descriptive questions
8. Clicks "Save Assessment" — all data is sent in one AJAX request
9. Success message appears, modal closes, page reloads

### Scenario 3: No Paper Sets Available

1. Teacher selects a Paper in the filter bar
2. The Paper Set dropdown loads and shows "-- No Paper Sets Available --"
3. The Search button is effectively unusable because Paper Set is required for data loading
4. Teacher must select a different paper that has sets configured

### Scenario 4: Bulk Modal — Existing File Preview

1. Teacher clicks Upload for a student who already has an uploaded answer sheet
2. The Bulk Upload modal shows the previously uploaded file name and a "View Uploaded Sheet" link
3. Teacher can click the link to view the existing file in a new tab
4. Teacher can upload a new file to replace the old one — the old file remains on the server but the new one becomes the current version

### Scenario 5: Network Failure During Question-Wise Load

1. Teacher clicks Upload for a student (question-wise paper)
2. "Fetching Question Data..." spinner appears
3. The AJAX request fails
4. Error message: "Failed to fetch question data. Please try again."
5. The error is also logged to the browser console for debugging
6. Teacher can try again by clicking the Upload button again

## Important UI Details

- The Bulk Upload modal has a green success-colored header
- The Question-Wise modal has a blue-purple gradient header
- MCQ option circles have hover effects (border color change) and a green fill when selected with a shadow effect
- File attachment rows in the QW modal show the file name with a truncation (max 150px) and a small eye icon button to view
- File upload inputs in the QW modal are compact (24px height, small font) to fit neatly in table cells
- The QW modal table has custom styling with uppercase headers, colored text, and row hover effects
- Each question row has a circular number badge on the left
- The XSS prevention `escapeHtml()` function is used before inserting any dynamic text into the DOM
- The storage base URL is pre-computed in JavaScript to handle both tenant_asset and regular storage paths
- The section dropdown has a wider style (min-width: 250px)
- The student dropdown uses Select2 for searchability
- Pagination uses Bootstrap-style links
- The "View Set Questions" button is positioned in the filter bar alongside Search and Reset

## Common Teacher Questions

**Q: Why did the Upload button open the Bulk modal instead of the Question-Wise modal?**
A: The modal type is determined by the paper's configuration. If the paper has `offline_entry_mode = 'BULK_TOTAL'` AND `is_ques_wise_file_upload != 1`, the Bulk modal opens. If either `offline_entry_mode = 'QUESTION_WISE'` OR `is_ques_wise_file_upload = 1`, the Question-Wise modal opens.

**Q: Can I enter marks in the Bulk Upload modal?**
A: No. The Bulk Upload modal only accepts a PDF file upload. Marks are entered separately through the Bulk Paper Check screen (accessible from the Offline Assessment summary).

**Q: What if I need to change the MCQ options I selected?**
A: Reopen the modal by clicking Upload again. Previously selected options are pre-checked. You can change them and save again. The new selections overwrite the old ones.

**Q: Why does the page reload after every save?**
A: The page reloads to refresh the evaluation status ("Checked" badge) for all students. This ensures the table reflects the most up-to-date data from the server.
