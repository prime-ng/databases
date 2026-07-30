# hmw_PaperCheck_TcList

## Module: LmsHomework → Homework Master → Paper Check

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsHomework |
| Tab Group | Homework Master |
| Feature | Paper Check (Grading Workspace) |
| URL(s) | `/lms-home-work/home-works/{id}/paper-check` (workspace), `/lms-home-work/home-works/{homeworkId}/check-data/{submissionId}` (AJAX detail), `/lms-home-work/home-works/{homeworkId}/get-files/{studentId}` (AJAX files), `/lms-home-work/home-works/check/save/{submissionId}` (AJAX save) |
| Controller | `Modules\LmsHomework\Http\Controllers\LmsHomeworkController` |
| Method(s) | `paperCheck()`, `getCheckData()`, `getSubmissionFiles()`, `saveCheck()` |
| Model(s) | `Homework`, `HomeworkAssignment`, `HomeworkSubmission` |
| Permissions | `tenant.home-work.viewAny` (access), `tenant.home-work.update` (grading) |
| Views | `lmshomework::paper-check.index`, `lmshomework::paper-check.evaluator-js` |

---

## 2. Pre-conditions

- Required permissions: `tenant.home-work.viewAny` (access) + `tenant.home-work.update` (grading)
- Required seed data: At least one published `Homework` with assignments and submissions
- Required seed data: Students enrolled in the target class with varied submission statuses (Not Submitted, Submitted, Graded)
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For annotated file tests: Sample PDF for download and re-upload

---

## 3. Default Data Load

When `paperCheck($homeworkId)` loads:

| Data | Source | Query | Order |
|------|--------|-------|-------|
| Homework Context | Homework | `with(subject, class, section, topic)->findOrFail($homeworkId)` | — |
| All Assignments | HomeworkAssignment | `with(student, submission, submission.status, status)->where('homework_id', $homeworkId)` | `orderBy('student_id')` |

---

## 4. Test Data Strategy

- **Homework**: Must be published with assignments created for all enrolled students
- **Submissions**: Create with varied statuses (Submitted, Under Review, Graded, Resubmit Requested)
- **Some students without submissions**: To test "Not Submitted" state
- **Files**: For annotated file tests, use PDF files with allowlist types
- **Pre-test cleanup**: Delete created homework by ID after tests

---

## 5. Business Conditions

### 5.1 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Paper Check shows ALL students (not just submitters) | Students without submission show "Not Submitted" status |
| BC-BIZ-02 | Marks must be within range | 0 <= marks_obtained <= homework.max_marks |
| BC-BIZ-03 | Grading is audited | `graded_by` = current user ID; `graded_at` = now |
| BC-BIZ-04 | Finalize locks grade | Submission status = Graded; locked from further changes |
| BC-BIZ-05 | Re-check clears grade data | Marks, feedback, grader, timestamp cleared; status = Under Review |
| BC-BIZ-06 | Auto-publish controls score visibility | If `auto_publish_score=true`, `score_published_at` set on finalize |
| BC-BIZ-07 | Annotated file is optional | Teacher can grade with marks+feedback only, no file required |
| BC-BIZ-08 | Save without Finalize | Marks saved but status not changed to Graded (remains Under Review) |
| BC-BIZ-09 | AJAX save — page does not reload | `saveCheck()` returns JSON; row updates dynamically |

### 5.2 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.home-work.viewAny | paperCheck(), getCheckData(), getSubmissionFiles() | Without → 403 |
| BC-AUTH-02 | tenant.home-work.update | saveCheck() | Without → 403 |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Paper Check Page Loads With All Students | Banner shows homework context; table lists ALL assigned students (including those without submissions) | — | — | ⬜ |
| TC-P02 | Student Without Submission Shows "Not Submitted" | Row shows grey "Not Submitted" badge; no files/marks displayed | — | — | ⬜ |
| TC-P03 | Student With Submission Shows Submitted Work | Row shows submission text/files, timestamp, late flag | — | — | ⬜ |
| TC-P04 | Student With Graded Submission Shows Marks | Row shows marks_obtained, teacher_feedback, graded timestamp | — | — | ⬜ |
| TC-P05 | Save Marks and Feedback (Without Finalize) | AJAX POST to `saveCheck()`; marks saved; status = Under Review; JSON 200 | — | — | ⬜ |
| TC-P06 | Finalize Grade — Locks Submission | Status changes to Graded; `graded_at` set; student can see score if auto-publish | — | — | ⬜ |
| TC-P07 | Re-check Unlocks Grade | Grade data cleared; status = Under Review; teacher can re-enter marks | — | — | ⬜ |
| TC-P08 | Annotated File Upload | Teacher uploads annotated PDF; file stored and linked to submission | — | — | ⬜ |
| TC-P09 | Marks Validation — Within Range | Marks between 0 and max_marks accepted | — | — | ⬜ |
| TC-P10 | AJAX Success Response | JSON `{success: true, message: "..."}` returned after save | — | — | ⬜ |
| TC-P11 | Page Updates Dynamically After AJAX Save | Student row updates to show new marks/status without page reload | — | — | ⬜ |
| TC-P12 | Resubmit Requested Status Badge Displayed Correctly | Student with `is_resubmission_requested=true` shows orange/amber "Resubmit Requested" badge | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Marks Exceed Maximum Marks | "Marks cannot exceed maximum marks." — validation error | — | — | ⬜ |
| TC-N02 | Marks Negative Value | Validation fails (min:0) | — | — | ⬜ |
| TC-N03 | Invalid File Type For Annotated Upload | "File must be of type: pdf, doc, docx, txt, jpg, jpeg, png." | — | — | ⬜ |
| TC-N04 | Annotated File Exceeds 10MB | "File may not be greater than 10240 kilobytes." | — | — | ⬜ |
| TC-N05 | Teacher Feedback Exceeds 2000 Characters | "Feedback is too long (max 2000 characters)." | — | — | ⬜ |
| TC-N06 | Non-Existent Homework ID (404) | `/lms-home-work/home-works/99999/paper-check` returns HTTP 404 | — | — | ⬜ |
| TC-N07 | Non-Existent Submission ID for Save | AJAX returns 404; "Submission not found" | — | — | ⬜ |
| TC-N08 | Server Error During Save | "Failed to save check. Please try again." — HTTP 500 | — | — | ⬜ |
| TC-N09 | Permission 403 — No viewAny | User without `tenant.home-work.viewAny` sees 403 | — | — | ⬜ |
| TC-N10 | Permission 403 — No update for saveCheck | User with viewAny but without `tenant.home-work.update` sees 403 on save | — | — | ⬜ |
| TC-N11 | Guest Access Redirect | Logged-out user redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | All assigned students shown regardless of submission | Count of rows = count of assignments for this homework | — | — | ⬜ |
| TC-D02 | B | Grading via Paper Check updates submission table | `marks_obtained`, `graded_by`, `graded_at` saved in `lms_homework_submissions` | — | — | ⬜ |
| TC-D03 | C | Grading via Paper Check updates assignment tracking | Assignment's status_id updated in `lms_homework_assignment` | — | — | ⬜ |
| TC-D04 | D | Finalize → `score_published_at` set if auto-publish enabled | `score_published_at` = now when auto_publish_score = true | — | — | ⬜ |
| TC-D05 | E | Re-check clears grade data completely | `marks_obtained=null`, `graded_by=null`, `graded_at=null`, `teacher_feedback=null` | — | — | ⬜ |
| TC-D06 | F | Student order consistent | Rows ordered by `student_id` ASC | — | — | ⬜ |
| TC-D07 | G | Activity Log — Grade saved | Activity logged with "Graded" / "Updated" event | — | — | ⬜ |
| TC-D08 | H | SaveCheck → updated_by set on submission | `updated_by` on `lms_homework_submissions` set to current user ID on grade save | — | — | ⬜ |
| TC-D09 | I | getCheckData() AJAX Returns Submission Details | GET `/lms-home-work/home-works/{homeworkId}/check-data/{submissionId}` returns JSON with marks, feedback, files, and status | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can for grading actions | Save/Finalize buttons wrapped in `@can('tenant.home-work.update')` | — | — | ◌ |
| TC-CR02 | CR | P1 | AJAX error handling | saveCheck returns JSON with success=false and message on failure | — | — | ◌ |
| TC-CR03 | CR | P1 | isset()/null-safe checks for submission/student relations | `$assignment?->submission?->marks_obtained` used; no undefined errors | — | — | ◌ |
| TC-CR04 | CR | P1 | Marks validation on server + client | Both JS and PHP validate marks range; double validation | — | — | ◌ |
| TC-CR05 | CR | P1 | Hub page tab integration — permission-filtered route | PaperCheck route protected by `tenant.home-work.viewAny`; direct URL returns 403 without permission | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-P01: Paper Check Page Loads With All Students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to LMS → Homework → Homework tab | Homework list loads |
| 3 | Click "Paper Check" button on a homework with 35 students | Navigates to `/lms-home-work/home-works/{id}/paper-check` |
| 4 | Check context banner at top | Shows homework title, subject, class/section, topic |
| 5 | Check student roster table | 35 rows (one per student) regardless of submission status |
| 6 | Verify students with submissions show work | Submitted text/files visible |
| 7 | Verify students without submissions show "Not Submitted" | Grey badge shown |

#### TC-P06: Finalize Grade — Locks Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Paper Check for a homework with ungraded submission | Find ungraded student |
| 2 | Enter marks: 15, feedback: "Good work" | Fields filled |
| 3 | Click "Finalize" button | AJAX POST to saveCheck() |
| 4 | Check JSON response | `success: true` |
| 5 | Check row updates | Status badge = "Graded" (green); marks displayed |
| 6 | DB check: `SELECT marks_obtained, graded_by, graded_at, status_id FROM lms_homework_submissions WHERE id={id}` | marks=15, graded_by=current user, graded_at=now, status=Graded |

#### TC-N01: Marks Exceed Maximum Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Paper Check for homework with max_marks=20 | Grade input visible |
| 2 | Enter marks: 25 (exceeds max) | Value entered |
| 3 | Click Save/Finalize | Validation error: "Marks cannot exceed maximum marks." |
| 4 | DB check: marks_obtained unchanged | Still null or previous value |

#### TC-D02: Grading Via Paper Check Updates Submission Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Grade a submission via Paper Check (marks=18, feedback="Excellent") | AJAX success |
| 2 | Navigate to Submission tab | Submission shows marks=18, feedback="Excellent" |
| 3 | DB check: `SELECT * FROM lms_homework_submissions WHERE id={id}` | marks_obtained=18.00, graded_by={user_id}, graded_at=timestamp |

#### TC-P02: Student Without Submission Shows "Not Submitted"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for a homework where some students have not submitted | Page loads |
| 3 | Locate a student row with no submission | Row displays grey "Not Submitted" badge |
| 4 | Verify no marks, feedback, or files shown for that student | Fields are empty or N/A |
| 5 | Check that the student is not selectable for grading | Input fields disabled or hidden |

#### TC-P03: Student With Submission Shows Submitted Work

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for a homework with submitted assignments | Page loads |
| 3 | Locate a student with "Submitted" status | Row shows submitted work |
| 4 | Verify submission text is visible | Student's answer text displayed |
| 5 | Verify uploaded files are listed | File names with download links shown |
| 6 | Check timestamp shows submission date | "Submitted on {date}" visible |
| 7 | Verify late flag if applicable | "Late" badge shown if past due date |

#### TC-P04: Student With Graded Submission Shows Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for a homework with graded submissions | Page loads |
| 3 | Locate a student with "Graded" status | Row shows existing marks |
| 4 | Verify marks_obtained displayed | Marks visible (e.g. "15/20") |
| 5 | Verify teacher_feedback displayed | Feedback text shown |
| 6 | Verify graded timestamp displayed | "Graded on {date}" visible |

#### TC-P05: Save Marks and Feedback (Without Finalize)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for a homework with an Under Review submission | Page loads |
| 3 | Enter marks: 14, feedback: "Needs improvement" | Fields filled |
| 4 | Click "Save" (not Finalize) | AJAX POST to `saveCheck()` |
| 5 | Verify JSON response | `{success: true, message: "..."}` returned |
| 6 | Verify status remains "Under Review" | Status not changed to "Graded" |
| 7 | DB check: `SELECT marks_obtained, status_id FROM lms_homework_submissions WHERE id={id}` | marks=14.00, status=Under Review |

#### TC-P07: Re-check Unlocks Grade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for a graded submission | Graded row visible |
| 3 | Click "Re-check" button | Confirmation prompt appears |
| 4 | Confirm re-check | AJAX call clears grade data |
| 5 | Verify JSON response | `success: true` |
| 6 | Verify row now editable | Marks/feedback fields enabled |
| 7 | DB check: `SELECT marks_obtained, graded_by, graded_at, teacher_feedback FROM lms_homework_submissions WHERE id={id}` | All null |

#### TC-P08: Annotated File Upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an Under Review submission | Page loads |
| 3 | Click file upload / annotated file input | File browser opens |
| 4 | Select a valid PDF (annotated version) | File selected |
| 5 | Enter marks: 16, feedback: "See annotations" | Fields filled |
| 6 | Click Save | AJAX POST with file + data |
| 7 | Verify JSON response | `success: true` |
| 8 | DB check: `SELECT annotated_file FROM lms_homework_submissions WHERE id={id}` | File path stored |

#### TC-P09: Marks Validation — Within Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for homework with max_marks=20 | Page loads |
| 3 | Enter marks: 0 | Value accepted; no validation error |
| 4 | Click Save | AJAX success |
| 5 | Change marks to 20 | Value accepted |
| 6 | Click Save | AJAX success |
| 7 | Verify both values persisted | marks_obtained set to 0 then 20 in DB |

#### TC-P10: AJAX Success Response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an editable submission | Page loads |
| 3 | Enter marks: 12, feedback: "OK" | Fields filled |
| 4 | Click Save | AJAX POST to `saveCheck()` |
| 5 | Inspect network/XHR response | Status 200 |
| 6 | Verify response body | `{success: true, message: "Check saved successfully"}` |

#### TC-P11: Page Updates Dynamically After AJAX Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an editable submission | Page loads |
| 3 | Enter marks: 17, feedback: "Great" | Fields filled |
| 4 | Click Save (without page reload) | AJAX request sent |
| 5 | Observe student row without refreshing page | Row updates: marks shown in-place, status badge updates |
| 6 | Verify no full page reload occurred | Network tab shows only XHR, no document reload |

#### TC-N02: Marks Negative Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for homework with max_marks=20 | Page loads |
| 3 | Enter marks: -5 | Value entered |
| 4 | Click Save/Finalize | Validation error: "Marks cannot be negative" or similar |
| 5 | DB check: marks_obtained unchanged | Still null or previous value |

#### TC-N03: Invalid File Type For Annotated Upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an editable submission | Page loads |
| 3 | Click annotated file upload | File browser opens |
| 4 | Select a .exe or .zip file | File selected (invalid type) |
| 5 | Click Save | Validation error: "File must be of type: pdf, doc, docx, txt, jpg, jpeg, png." |
| 6 | Verify file not saved | Annotated file field remains null in DB |

#### TC-N04: Annotated File Exceeds 10MB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an editable submission | Page loads |
| 3 | Click annotated file upload | File browser opens |
| 4 | Select a file > 10MB (e.g. 15MB PDF) | File selected |
| 5 | Click Save | Validation error: "File may not be greater than 10240 kilobytes." |
| 6 | Verify file not saved | Annotated file field remains null in DB |

#### TC-N05: Teacher Feedback Exceeds 2000 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an editable submission | Page loads |
| 3 | Enter marks: 10 | Marks filled |
| 4 | Paste feedback text of 2500 characters | Text entered |
| 5 | Click Save | Validation error: "Feedback is too long (max 2000 characters)." |
| 6 | Verify feedback not saved | teacher_feedback unchanged in DB |

#### TC-N06: Non-Existent Homework ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to `/lms-home-work/home-works/99999/paper-check` | HTTP 404 page displayed |
| 3 | Verify error message | "Homework not found" or similar |

#### TC-N07: Non-Existent Submission ID for Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Using browser dev tools, manually POST to `/lms-home-work/home-works/check/save/99999` | AJAX returns 404 |
| 3 | Verify JSON response | `{success: false, message: "Submission not found"}` |

#### TC-N08: Server Error During Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for an editable submission | Page loads |
| 3 | Temporarily break DB connection (e.g. stop MySQL) | Connection lost |
| 4 | Enter marks: 10, feedback: "Test" | Fields filled |
| 5 | Click Save | HTTP 500 error returned |
| 6 | Verify JSON response | `{success: false, message: "Failed to save check. Please try again."}` |
| 7 | Restore DB connection | Connection restored |

#### TC-N09: Permission 403 — No viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.home-work.viewAny` permission | Dashboard loads |
| 2 | Navigate to Paper Check URL `/lms-home-work/home-works/{id}/paper-check` | HTTP 403 Forbidden |
| 3 | Verify 403 error page | "Forbidden" or "Unauthorized" message displayed |

#### TC-N10: Permission 403 — No update for saveCheck

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITH `tenant.home-work.viewAny` but WITHOUT `tenant.home-work.update` | Dashboard loads |
| 2 | Navigate to Paper Check URL | Page loads (read-only) |
| 3 | Verify Save/Finalize buttons are hidden | No grading controls visible |
| 4 | Using dev tools, manually POST to `saveCheck()` | HTTP 403 returned |
| 5 | Verify JSON response | `{success: false, message: "Forbidden"}` |

#### TC-N11: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (ensure no session) | Redirected to login page |
| 2 | Navigate to Paper Check URL `/lms-home-work/home-works/{id}/paper-check` | Redirected to `/login` |
| 3 | Verify login form displayed | Login page rendered |

#### TC-D01: All Assigned Students Shown Regardless of Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | DB check: `SELECT COUNT(*) FROM lms_homework_assignments WHERE homework_id={id}` | Get total assignment count (e.g. 35) |
| 3 | Navigate to Paper Check for that homework | Page loads |
| 4 | Count rows in student roster table | Row count matches assignment count |
| 5 | Verify submitters and non-submitters both present | Mix of "Submitted" and "Not Submitted" rows |

#### TC-D03: Grading Via Paper Check Updates Assignment Tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Note current assignment status_id for a student: `SELECT status_id FROM lms_homework_assignment WHERE id={assignmentId}` | Current status recorded |
| 3 | Grade the student's submission via Paper Check | AJAX success |
| 4 | DB check: `SELECT status_id FROM lms_homework_assignment WHERE id={assignmentId}` | status_id updated to reflect Graded status |

#### TC-D04: Finalize → score_published_at Set If Auto-publish Enabled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Ensure homework has `auto_publish_score = true` | Setting verified in DB |
| 3 | Navigate to Paper Check and finalize a grade | AJAX success |
| 4 | DB check: `SELECT score_published_at FROM lms_homework_submissions WHERE id={id}` | `score_published_at` = current timestamp |
| 5 | Repeat with `auto_publish_score = false` | `score_published_at` remains null |

#### TC-D05: Re-check Clears Grade Data Completely

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Locate a graded submission and record its grade data | marks_obtained, graded_by, graded_at, teacher_feedback all populated |
| 3 | Click "Re-check" and confirm | Grade data cleared |
| 4 | DB check: `SELECT marks_obtained, graded_by, graded_at, teacher_feedback FROM lms_homework_submissions WHERE id={id}` | All four fields = null |

#### TC-D06: Student Order Consistent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check | Page loads |
| 3 | Inspect student rows top to bottom | Student IDs sorted ascending |
| 4 | DB check: `SELECT student_id FROM lms_homework_assignments WHERE homework_id={id} ORDER BY student_id ASC` | Row order matches DB query order |

#### TC-D07: Activity Log — Grade Saved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Note current activity log count for the homework | Baseline recorded |
| 3 | Grade a submission via Paper Check | AJAX success |
| 4 | Navigate to Activity Log for this homework | New entry created |
| 5 | Verify log details | Event = "Graded" / "Updated"; user = current teacher; timestamp matches |

#### TC-D08: SaveCheck → updated_by Set On Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Note current `updated_by` for a submission: `SELECT updated_by FROM lms_homework_submissions WHERE id={id}` | Current value recorded |
| 3 | Grade the submission via Paper Check (Save or Finalize) | AJAX success |
| 4 | DB check: `SELECT updated_by FROM lms_homework_submissions WHERE id={id}` | updated_by = current teacher's user ID |

#### TC-CR01: Blade @can For Grading Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `paper-check/index.blade.php` in source | File loaded |
| 2 | Search for Save/Finalize buttons in blade | Wrapped in `@can('tenant.home-work.update')` directive |
| 3 | Verify `@can` / `@endcan` encloses grading controls | Save, Finalize, Re-check, file upload all gated |
| 4 | Verify `@else` or `@cannot` not used around read-only display | Student info/submission data outside @can block (accessible with viewAny only) |

#### TC-CR02: AJAX Error Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `LmsHomeworkController.php` in source | File loaded |
| 2 | Locate `saveCheck()` method | Method found |
| 3 | Inspect try-catch or error handling blocks | On exception/failure, returns `{success: false, message: "..."}` JSON |
| 4 | Verify no raw exception thrown | All paths return JSON, never HTML error page |
| 5 | Verify HTTP status code on error | Returns 400/500-level status with JSON body |

#### TC-CR03: isset()/null-safe Checks For Submission/Student Relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller and/or blade files in source | Files loaded |
| 2 | Search for `$assignment->submission` usage | Uses `$assignment?->submission?->marks_obtained` (null-safe) or `isset($assignment->submission)` |
| 3 | Verify no direct `$assignment->submission->marks_obtained` without null check | No undefined property / null access errors possible |
| 4 | Verify student relation similarly guarded | `$assignment?->student?->name` pattern used |

#### TC-CR04: Marks Validation On Server + Client

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `paper-check/evaluator-js.blade.php` in source | File loaded |
| 2 | Search for client-side marks validation | JS checks marks >= 0 and marks <= max_marks before submitting |
| 3 | Open `LmsHomeworkController.php` in source | File loaded |
| 4 | Locate validation rules in `saveCheck()` | PHP validation with `min:0` and `max:max_marks` or rule object |
| 5 | Verify both validations exist | Double validation: client-side (UX) + server-side (security) |

#### TC-CR05: Hub Page Tab Integration — Permission-Filtered Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open route file (e.g. `web.php` or `api.php`) in source | File loaded |
| 2 | Find Paper Check routes | Routes defined under `lms-homework` prefix |
| 3 | Verify middleware/permission gate on `paperCheck()` | Route uses `middleware('can:tenant.home-work.viewAny')` or equivalent gate |
| 4 | Open Hub page blade or controller that generates tabs | Paper Check tab link present |
| 5 | Verify tab link also gated with `@can('tenant.home-work.viewAny')` | Tab hidden for users without permission |

#### TC-P12: Resubmit Requested Status Badge Displayed Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Navigate to Paper Check for a homework with submissions | Page loads |
| 3 | Locate a student where `is_resubmission_requested = true` (Resubmit Requested status) | Student row visible |
| 4 | Verify the status badge displays "Resubmit Requested" in orange/amber color | Correct badge text and color shown |
| 5 | Verify the row shows the original submission data (marks/feedback are cleared or marked for resubmission) | Teacher can see the original submission context |
| 6 | Verify the status in the grading UI matches `is_resubmission_requested` flag in DB | Status badge consistent with `lms_homework_submissions.is_resubmission_requested` |

#### TC-D09: getCheckData() AJAX Returns Submission Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as teacher | Dashboard loads |
| 2 | Open browser DevTools → Network tab | Network monitoring active |
| 3 | Navigate to Paper Check for a homework with a submission | Page loads; XHR requests visible |
| 4 | Identify the XHR GET to `/lms-home-work/home-works/{homeworkId}/check-data/{submissionId}` | AJAX call fired |
| 5 | Inspect JSON response | `{success: true, data: {marks_obtained, teacher_feedback, status, files, ...}}` |
| 6 | Verify response includes submission marks, feedback text, file URLs, and current status | All relevant submission detail fields present |
| 7 | Test with an invalid submissionId | Returns `{success: false, message: "Submission not found"}` (404) |
