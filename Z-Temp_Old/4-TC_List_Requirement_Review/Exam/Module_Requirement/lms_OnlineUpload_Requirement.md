# Online Upload — Uploading Corrected Answer Sheets for Descriptive Questions in Online Exams

---

## What Does This Screen Do?

This screen is a dedicated workspace for teachers who need to manually review and upload corrected answer sheets for descriptive (subjective) questions from online exams. In a typical online exam, multiple-choice questions are graded automatically by the system the moment the student submits. But descriptive questions — short answers, long-form essays, numerical problem solutions, diagram-based answers — require a human teacher to read, evaluate, and assign marks.

The screen presents a table of all students who were allocated to a particular exam paper, showing who actually attempted the exam and whether their descriptive answers have been evaluated. For each student who submitted, the teacher can open a detailed modal window that lists only the descriptive questions (not the auto-graded MCQs). Inside this modal, the teacher can view what the student submitted for each question and upload a corrected or annotated version of the answer file.

This is not a grading screen per se — you do not enter marks here. You upload corrected files (annotated PDFs or images) as evidence of evaluation. The actual marks are entered through the separate Online Assessment / Paper Check interface.

## Real-Life Example

Imagine you are a computer science teacher who gave an online programming exam. The exam has 30 multiple-choice questions (auto-graded) and 3 programming problems where students had to write code and upload screenshots of their output.

After the exam closes, you open this screen. You select Class 12-A, Section Science, Subject Computer Science, choose "Midterm Practical Exam", select "Programming Paper", and pick "Set A". The system loads a list of 45 students.

You can immediately see:
- 42 students started the exam (green "Present" badge) and 3 never started ("Not Started" badge)
- 15 of the 42 have already been evaluated (green "Yes" badge), 27 are still pending (yellow "No" badge)

You start with the first pending student. Clicking the pen-and-file icon opens a modal titled "Online Descriptive Assessment: Rahul Sharma". The modal shows 3 descriptive questions. For question 1, Rahul uploaded a screenshot of his code output — you see a "View" link that opens his screenshot. Below it, you can upload your corrected version (perhaps a PDF with your comments and marks written on it). You upload the file and click "Save Assessment". The system confirms with "Descriptive marks updated successfully." and the page reloads. Now that student's "Checked" badge shows "Yes".

You repeat this process for all 27 pending students. At any point, you can click the eye icon next to a student to see their full attempt details in a new tab, or click the "View Set Questions" button to see the original question paper.

## How It Works

### Accessing the Screen

The Online Upload screen is one of two tabs under the "Answer Sheet Upload" page. The other tab is "Offline Upload". The page opens with the Online Upload tab active if you came from a link with `active_tab=online_upload`. Both tabs share the same underlying controller, which loads data for whichever tab is active.

### The Filter Bar

The screen initially shows an empty table with the message "Please search to view online data." Before you can see any students, you must select enough filters to identify a specific paper.

The filter bar contains these dropdowns (all loaded on page load with their full data):

1. **Class** — Lists all active classes. Selecting a class triggers four simultaneous AJAX calls:
   - Loads sections for that class (populates the Section dropdown)
   - Loads subjects for that class (populates the Subject dropdown)
   - Loads exams for that class (populates the Exam dropdown)
   - Loads students for that class (populates the Student dropdown)

2. **Section** — Pre-populated on page load with all active sections, but dynamically narrowed when a class is selected. Selecting a section triggers:
   - Reloads subjects filtered by both class and section
   - Reloads students filtered by both class and section

3. **Subject** — Marked as "required". Dynamically loaded based on class and section.

4. **Exam** — Marked as "required". Dynamically loaded based on class. Each option carries a `data-class-id` attribute. The dropdown name is "exam_id".

5. **Paper** — Marked as "required". Dynamically loaded based on the selected exam. Shows the paper name with its code, e.g., "Science Paper 1 (SCI-P1)".

6. **Paper Set** — Marked as "required". Dynamically loaded based on the selected paper. Shows the set name (e.g., "Set A", "Set B"). If no sets exist for the paper, the dropdown shows "-- No Paper Sets Available --".

7. **Student** (optional) — Uses a Select2 searchable dropdown with "All Students" as the default. You can type to search for a specific student by name or code.

Alongside the dropdowns are three buttons:
- **Search** (magnifying glass): Submits the form and loads student data
- **Reset** (circular arrow): Clears all filters and reloads the current page without query parameters
- **View Set Questions** (document icon): Opens the question paper for the selected paper set in a new browser tab. If no paper set is selected, a warning appears: "Please select a Paper Set first."

### The Student Table

When the form is submitted with valid filters, the system:
1. Validates that the selected paper belongs to the selected exam and subject, and that its mode is "ONLINE"
2. Validates that the selected set belongs to the selected paper
3. Resolves all allocated students through the allocation system (CLASS, SECTION, or STUDENT allocation types)
4. Paginates the results (10 per page)

The table displays these columns:

- **Admn No**: The student's admission number
- **Student Name**: Formatted as "Roll No: [number] — [full name]". If the student has no roll number, it shows a dash.
- **Exam**: Reads the exam title from the selected exam filter (or "-" if not selected)
- **Paper**: Shows the selected paper's title
- **Paper Set**: Shows the selected set's name
- **Attendance**: Two possibilities:
  - "Present" (green badge) if the student's attempt status is anything other than "NOT_STARTED"
  - "Not Started" (gray badge) if the student never began the exam (status is "NOT_STARTED" or no attempt record exists)
- **Checked**: Two possibilities:
  - "Yes" (green badge) if the student has been evaluated. The system considers a student evaluated if EITHER the offline marks record has `is_evaluated = 1` OR the attempt status is "EVALUATED"
  - "No" (yellow badge) if the student's descriptive answers have not been evaluated yet
- **Action**: Two possible states:
  - If the student has an `attempt_id` (they have an attempt record):
    - **Question-Wise Assessment** button (pen-and-file icon, blue): Opens the grading modal
    - **View Attempt Detail** button (eye icon, outlined): Opens the full attempt report in a new browser tab
  - If the student has NO attempt_id (never started):
    - A disabled "No Attempt" button (clock icon, gray)

The table footer shows pagination links when the student data has more than 10 entries. Pagination links include the current filter state via `withQueryString()`.

### The Question-Wise Assessment Modal

Clicking the Question-Wise Assessment button triggers an AJAX GET request to fetch questions for that specific student and paper. The request sends: `student_id`, `exam_paper_id`, `exam_set_id = 0` (for online mode, the set ID is always 0), and `mode = 'ONLINE'`.

A loading spinner ("Loading Questions...") appears while the data loads.

If the request fails, an error message is shown. If it succeeds, a large modal window titled "Online Descriptive Assessment: [Student Name]" appears, with a blue header.

Inside the modal:
1. A hint note: "Note: Only descriptive questions (Short/Long Ans) are shown here for manual grading and attachment upload."
2. A table with three columns:
   - **Qn**: Question number (centered)
   - **Qn. Type**: Shows the question type (e.g., "Short Answer", "Long Answer"). The text is styled in blue with an info circle icon. **Hovering** over it reveals a tooltip with the full question text — this is important because the column is narrow and cannot show the full question.
   - **Attached Data (Teacher)**: This column can contain:
     - If the student uploaded a file for this question: A blue "View" badge that links to the student's file (opens in a new tab). The system builds the file URL by prepending the storage base URL (tenant_asset or storage path) to the file path.
     - A file upload input (`<input type="file">`) that accepts only PDF files (`application/pdf`) and images (`image/*`). The input is small and styled within the cell.
3. Footer buttons: "Close" (secondary) and "Save Assessment" (blue info color).

If no descriptive questions are found for the student (e.g., the paper only had MCQs), the table body shows: "No descriptive questions found for this student."

The modal uses Bootstrap tooltips for the question text tooltips, initialized after the content is loaded.

### Saving the Assessment

When you click "Save Assessment":
1. A JavaScript function collects all files from the file inputs. Each file input has a `data-ansid` attribute (the answer ID from the database), and files are keyed by this answer ID — e.g., `attachments[42]`, `attachments[57]`.
2. The function also appends `student_id`, `exam_paper_id`, `exam_set_id = 0`, and `mode = 'ONLINE'` to a FormData object.
3. The CSRF token is included for security.
4. An AJAX POST request sends the data to the save route.
5. A loading spinner ("Saving...") appears during upload.
6. On success:
   - A success message appears: "Descriptive marks updated successfully."
   - The modal closes
   - The page reloads automatically so the teacher can see the updated "Checked" status
7. On failure:
   - If the server returns a failure response: Shows the server's error message
   - If the AJAX request itself fails (network error, server error): Shows "Server error"

### Edge Cases and Special Behaviors

**What happens if the teacher opens the modal but doesn't change anything?** The system still submits the form with no files attached. The save will succeed but no changes will be made.

**What happens if both the student and teacher have uploaded files?** The "View" badge always shows the most recently stored file. The teacher's upload replaces or adds to the student's data (depending on the server-side logic).

**What if the student never started the exam?** The Question-Wise Assessment button is disabled and shows "No Attempt". No modal can be opened for this student.

**What if the exam paper has no descriptive questions?** The modal will show "No descriptive questions found for this student." and the teacher cannot upload anything.

**What happens to pagination when the page reloads after saving?** The page reloads to the same URL with the same filters, preserving the current page number and filter state.

## Business Rules

| Rule | Details |
|------|---------|
| Access control | Requires `tenant.answer-sheet-online-exam.view` permission for tab visibility. Controller checks both `tenant.online-assessment.view` AND `tenant.offline-assessment.view` |
| Data loading trigger | Data loads only when BOTH `exam_paper_id` AND `exam_set_id` are present in the request |
| Paper validation | The selected paper must belong to the selected exam and subject, and have `mode = 'ONLINE'` |
| Set validation | The selected set must belong to the selected paper |
| Active tab check | The table body only renders when the URL parameter `active_tab` equals `online_upload` |
| Empty state — no search | Shows "Please search to view online data." when the tab is active but no search has been performed |
| Empty state — no results | Shows "No students found for the selected criteria." when a search was performed but no students match |
| Attendance determination | Based on attempt status: anything other than "NOT_STARTED" = Present; "NOT_STARTED" or null = Not Started |
| Evaluation determination | `is_evaluated = 1` if EITHER the offline marks record has `is_evaluated = 1` OR the attempt status is "EVALUATED" |
| Action button state | Question-Wise button is only clickable if the student has a non-null `attempt_id` |
| Modal: descriptive only | The system only returns questions that are NOT MCQ type. MCQ questions are excluded from the modal data |
| File upload MIME types | Only `application/pdf` and `image/*` are accepted |
| File storage keying | Files are stored keyed by answer ID (`ansid`), not question ID |
| Success behavior | Page reloads after successful save to refresh the evaluation status |
| View Set Questions | Requires that a paper set is currently selected in the filter bar. If not, a warning message is shown |
| View Attempt Detail | Opens in a new browser tab using `target="_blank"` |
| Pagination condition | Pagination only renders when `$studentsData` is a paginated collection (has a `links()` method) AND the active tab matches |
| Student filter | Uses Select2 jQuery plugin for searchable dropdown with "All Students" placeholder |
| CSS width | The section dropdown has a min-width of 250px; the Select2 student dropdown has min-width of 250px |
| XSS prevention | Student name is escaped using JS string escaping (`addslashes`) when passed into JavaScript click handlers |
| Filter persistence | All filter values are preserved in the HTML select options using `request('param_name')` comparisons |
| Reset button | Navigates to `url()->current()` which strips all query parameters |
| Cascading load on page load | If a class is pre-selected (from URL), its change event is triggered automatically to load dependent dropdowns. If a section is pre-selected, its change event fires after a 500ms delay |

## Validation & Error Messages

| Scenario | What happens / What the user sees |
|----------|----------------------------------|
| Opening page with no filters | Empty table shows "Please search to view online data." |
| Submitting search with no results | Table shows "No students found for the selected criteria." |
| Clicking "View Set Questions" without selecting a set | Warning alert: "Please select a Paper Set first." |
| Opening modal, questions load | "Loading Questions..." spinner |
| No descriptive questions exist for this student | Modal shows "No descriptive questions found for this student." |
| Questions loaded successfully | Modal appears with question table |
| AJAX failure loading questions | Error alert with server message or "Failed to load data" |
| Saving assessment | "Saving..." spinner |
| Save successful | Success alert: "Descriptive marks updated successfully." Page reloads |
| Server returns failure | Error alert with server message |
| AJAX/network error on save | Error alert: "Server error" |
| Opening View Attempt Detail | Opens in new browser tab |
| Class selected, no section/subject/exam/students loaded yet | Dropdowns show "Loading..." temporarily |
| No paper sets exist for a paper | Dropdown shows "-- No Paper Sets Available --" |

## Permissions

| Permission | What it controls |
|-----------|-----------------|
| `tenant.answer-sheet-online-exam.view` | Whether the Online Upload tab is visible on the page |
| `tenant.online-assessment.view` | Required by the controller to load data |
| `tenant.offline-assessment.view` | Also checked by the controller |

## Related Screens

| Screen | Relationship |
|--------|-------------|
| **Offline Upload** | The other tab on the same page, for uploading offline exam answer sheets |
| **Online Assessment** | The summary dashboard showing all online exam papers with evaluation progress counts (Assigned/Submitted/Checked) |
| **Paper Check (Online)** | The full grading interface where you actually enter marks for each question and annotate PDFs — a deeper level than this upload screen |
| **Attempt Detail** | Full report of a student's exam attempt, including timings, answers, and activity log. Opens in a new tab |
| **View Set Questions** | Shows all questions in a paper set in read-only format. Opens in a new tab |

---

## Detailed Interaction Flows — Step by Step

### Scenario 1: Grading a Fresh Exam (Normal Flow)

1. Teacher navigates to Answer Sheet Upload → the Online Upload tab is active
2. Screen shows "Please search to view online data." — the table is empty
3. Teacher selects Class (e.g., "10-A") from the first dropdown — this triggers four simultaneous AJAX calls that populate the Section, Subject, Exam, and Student dropdowns with relevant options
4. Teacher selects Section (e.g., "A"), Subject (e.g., "Science"), Exam (e.g., "Midterm"), Paper (e.g., "Science Paper 1"), and Paper Set (e.g., "Set A")
5. Optionally selects a specific Student if they want to focus on one child
6. Clicks the Search button (magnifying glass icon)
7. A brief loading period occurs while the server validates the selections, resolves allocations, and fetches student data
8. The table populates with students allocated to that paper/set combination
9. Teacher scans the "Checked" column looking for yellow "No" badges
10. For the first pending student: clicks the pen-and-file icon (Question-Wise Assessment)
11. A SweetAlert loading spinner says "Loading Questions..."
12. The modal appears: "Online Descriptive Assessment: [Student Name]"
13. Teacher sees only the descriptive questions — MCQs are completely excluded
14. For each descriptive question: views the student's uploaded file (if any) via the "View" badge link, then uploads a corrected/annotated version using the file input
15. Clicks "Save Assessment" — another spinner "Saving..."
16. Success message: "Descriptive marks updated successfully." — the modal closes
17. The page automatically reloads
18. The student's "Checked" badge now shows "Yes" in green
19. Teacher proceeds to the next student and repeats

### Scenario 2: Reviewing Previously Graded Work

1. Teacher navigates to the page — previously used filter values are pre-selected in the dropdowns because they are preserved in the URL query string
2. On page load, if a class is pre-selected, the cascading triggers fire automatically to load dependent dropdowns
3. The table loads showing all students with current evaluation statuses
4. Teacher sees which students are checked (green "Yes") and which are pending (yellow "No")
5. For already-checked students: the teacher can still open the modal to view or re-upload corrected files if needed
6. The eye icon button opens the student's full attempt details in a new tab for deeper review

### Scenario 3: Students Who Never Started

1. Teacher opens the table for a paper/set
2. Some students show "Not Started" (gray badge) in the Attendance column
3. For these students, the Action column shows a disabled gray button with a clock icon labeled "No Attempt"
4. Clicking this button does nothing — it is disabled
5. The teacher cannot open the assessment modal or view attempt details for these students
6. These students effectively have no evaluable work

### Scenario 4: Paper Has Only MCQs (No Descriptive Questions)

1. Teacher follows the normal flow and opens the assessment modal for a student
2. The AJAX request returns successfully, but the questions array is empty
3. The modal body shows: "No descriptive questions found for this student."
4. The Save Assessment button is still visible but there is nothing to upload
5. Teacher closes the modal — no change to the student's evaluation status
6. The teacher knows this paper had no descriptive component, so no manual upload is needed

### Scenario 5: Network Error During Question Load

1. Teacher clicks the Question-Wise Assessment button
2. The loading spinner appears
3. The AJAX GET request fails (network issue, server timeout, etc.)
4. An error alert appears: "Failed to load data" (or the server's error message if provided)
5. The modal does not open
6. Teacher can try again by clicking the button again

### Scenario 6: Server Error During Save

1. Teacher uploads files and clicks Save Assessment
2. The "Saving..." spinner appears
3. The AJAX POST request fails
4. If the server returns an error response: shows the server's error message
5. If the AJAX request itself fails (network): shows "Server error"
6. The modal remains open — teacher can try again or close and come back later

## Important UI Details and Behaviors

- The modal has a blue (info) header bar with white text and a white close button
- The modal is extra-large (modal-xl) and scrollable (modal-dialog-scrollable) to accommodate many questions
- File inputs are styled as small form controls (`form-control-sm`) to fit within table cells without taking too much space
- Existing file links use a "badge" style (blue info color) for a compact, badge-like appearance
- Question type labels are styled with an info circle icon and have a Bootstrap tooltip that shows the full question text on hover — important because the column is narrow
- The modal footer has a light gray background with a secondary Close button and an info-colored Save Assessment button
- The search form uses the GET method (filters are in the URL), while the file upload uses AJAX POST
- All AJAX requests include the CSRF token from the meta tag
- The student dropdown uses the Select2 jQuery plugin for type-to-search functionality
- The table has hover effects on rows for better readability
- The Action column has a fixed width of 120px to keep the buttons aligned
- The section dropdown has a minimum width of 250px to accommodate longer section names
- The reset button (circular arrow) strips all query parameters by navigating to `url()->current()`
- If a class is pre-selected on page load (from URL parameters), its change event fires automatically. If a section is also pre-selected, its change event fires after a 500ms delay to allow the section dropdown to populate first.

## Common Teacher Questions Answered

**Q: Can I grade MCQ questions here?**
A: No. Multiple-choice questions are graded automatically by the system as soon as the student submits the exam. This screen only displays descriptive questions (short answer, long answer, essay) that require human evaluation. If an exam paper has only MCQs, the modal will display a message: "No descriptive questions found for this student."

**Q: Do I enter marks in this screen?**
A: No. This screen is specifically for uploading corrected or annotated answer files as evidence of evaluation. The actual marks are entered through the Paper Check interface, which you can access from the Online Assessment summary tab by clicking the "Check" button for a paper.

**Q: What file formats are accepted for upload?**
A: Only PDF files (`application/pdf`) and image files (`image/*` — JPEG, PNG, GIF, etc.) are accepted. Other file types are filtered out by the browser's file picker.

**Q: Can I upload files for a student who never started the exam?**
A: No. The Question-Wise Assessment button is disabled and shows "No Attempt" for students without an attempt record. You can only upload files for students who actually began the exam.

**Q: What happens after I click Save Assessment?**
A: The page reloads automatically so that the updated evaluation status is reflected in the table. All your filter selections are preserved during the reload because they are part of the URL query string.

**Q: Can I view what the student originally submitted?**
A: Yes. If the student uploaded a file for a descriptive question, a blue "View" badge link appears in the modal. Clicking it opens the student's file in a new browser tab.

**Q: What if I uploaded the wrong file?**
A: You can reopen the modal at any time and upload a corrected file. The new upload replaces the previous one on the server side. There is no need to "delete" the old file first.

**Q: Do I need to save each question individually?**
A: No. The "Save Assessment" button uploads all files for all questions in a single request. You can upload files for some questions and leave others unchanged — only the questions where you selected a new file will be updated.

**Q: Can I see the full question paper while grading?**
A: Yes. Click the "View Set Questions" button (document icon) in the filter bar. It opens the question paper for the selected paper set in a new browser tab. You must have a paper set selected, otherwise a warning appears.

**Q: Why does the "Checked" status not change immediately?**
A: The "Checked" status (Yes/No) is determined by the `is_evaluated` field, which is set by the back-end logic during the save. If the save was successful and the page reloaded, the updated status should appear. If it still shows "No", the server-side evaluation logic may not have marked it as evaluated (this is determined by a combination of the offline marks record and the attempt status).
