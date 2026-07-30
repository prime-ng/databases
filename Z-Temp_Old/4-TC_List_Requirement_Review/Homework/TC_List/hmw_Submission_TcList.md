# hmw_Submission_TcList

## Module: LmsHomework → Homework Master → Homework Submission

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsHomework |
| Tab Group | Homework Master |
| Feature | Homework Submission |
| URL(s) | `/lms-home-work/homework-submission` (resource), `/lms-home-work/homework-submission/trash/view` (trash), `/lms-home-work/homework-submission/{id}/restore` (restore), `/lms-home-work/homework-submission/{id}/force-delete` (forceDelete), `/lms-home-work/homework-submission/{id}/toggle-status` (toggleStatus), `/lms-home-work/homework-submission/review/{id}` (review), `/lms-home-work/homework-submission/download-bulk/{homework_id}` (bulkDownload) |
| Controller | `Modules\LmsHomework\Http\Controllers\HomeworkSubmissionController` |
| Model(s) | `Modules\LmsHomework\Models\HomeworkSubmission` (table: `lms_homework_submissions`) |
| Validation (Create) | `Modules\LmsHomework\Http\Requests\HomeworkSubmissionRequest` |
| Validation (Update) | `Modules\LmsHomework\Http\Requests\HomeworkSubmissionRequest` |
| Validation (Review) | `Modules\LmsHomework\Http\Requests\HomeworkReviewRequest` |
| Permissions | `tenant.home-work-submission.viewAny`, `tenant.home-work-submission.view`, `tenant.home-work-submission.create`, `tenant.home-work-submission.update`, `tenant.home-work-submission.delete`, `tenant.home-work-submission.restore`, `tenant.home-work-submission.forceDelete` |
| Soft Deletes | Yes (`HomeworkSubmission` uses `SoftDeletes` trait) |
| Activity Log | Events: Stored, Updated, Trashed, Restored, Deleted |
| Media | Spatie Media Library (`homework_submission_files` collection) + JSON-based `sub_attachment_media_id` |

---

## 2. Pre-conditions

- Required permissions: `tenant.home-work-submission.*`
- Required seed data: At least one published `Homework` with assignments created
- Required seed data: At least one `Student` enrolled in the target class
- Required seed data: Submission statuses in `sys_dropdown_table` with key `SUBMISSION_STATUS`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For file upload tests: Sample files (PDF, DOCX, JPG, ZIP, EXE) under/over 10MB
- For bulk download tests: At least one submission with file attachments

---

## 3. Default Data Load

When the Submission tab loads via `HomeworkSubmissionController@index()`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Submissions Grid | HomeworkSubmission | `with(homework, student, status)` | search(text, feedback, student name, homework title), homework_id, student_id, status_id, is_late, is_active, graded | 10/page |
| Shared: Homeworks | index() | `Homework::where('is_active', 1)->get()` | is_active=1 | None |
| Shared: Students | index() | `Student::get()` | None | None |
| Shared: Statuses | index() | `Dropdown::where('key', SUBMISSION_STATUS)->get()` | key=SUBMISSION_STATUS | None |

---

## 4. Test Data Strategy

- **Submission**: Create via student portal (simulated) or direct DB insert with valid assignment_id, homework_id, student_id
- **Assignment**: Must exist before creating submission (unique constraint on `assignment_id`)
- **Late detection**: Create submission with `submitted_at > due_date` to test `is_late` flag
- **Resubmission**: Set `is_resubmission_requested=true` on existing submission, then create new submission for same assignment
- **Grading**: Use `review()` method with marks, feedback, status_id
- **Files**: Upload via Spatie Media or JSON column; test allowed types and size limits
- **Pre-test cleanup**: Delete created submissions by ID after tests

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_homework_submissions`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | assignment_id | INT UNSIGNED FK | NOT NULL, UNIQUE (`uq_hws_assignment`) |
| BC-DB-03 | homework_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-04 | student_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-05 | submission_text | LONGTEXT | NULLABLE |
| BC-DB-06 | sub_attachment_media_id | JSON | NULLABLE |
| BC-DB-07 | submitted_at | DATETIME | NOT NULL |
| BC-DB-08 | is_late | BOOLEAN | DEFAULT false |
| BC-DB-09 | resubmission_count | TINYINT UNSIGNED NOT NULL DEFAULT 0 |
| BC-DB-10 | status_id | INT UNSIGNED FK | NOT NULL |
| BC-DB-11 | is_resubmission_requested | INT UNSIGNED NOT NULL |
| BC-DB-12 | marks_obtained | DECIMAL(5,2) | NULLABLE |
| BC-DB-13 | teacher_feedback | TEXT | NULLABLE |
| BC-DB-14 | graded_by | INT UNSIGNED FK | NULLABLE |
| BC-DB-15 | graded_at | DATETIME | NULLABLE |
| BC-DB-16 | score_published_at | DATETIME | NULLABLE |
| BC-DB-17 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-18 | created_at | TIMESTAMP NULL DEFAULT NULL |
| BC-DB-19 | updated_at | TIMESTAMP NULL DEFAULT NULL |
| BC-DB-20 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-21 | created_by | INT UNSIGNED DEFAULT NULL | FK → `sys_users.id` |
| BC-DB-22 | updated_by | INT UNSIGNED DEFAULT NULL | FK → `sys_users.id` |

### 5.2 Validation Rules — `HomeworkSubmissionRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | assignment_id | nullable, integer, exists:lms_homework_assignment,id + unique per assignment | "This assignment already has a submission." |
| BC-VAL-02 | homework_id | required, integer, exists:lms_homework,id where is_active=1 | — |
| BC-VAL-03 | student_id | required, integer | — |
| BC-VAL-04 | submission_text | nullable, string, max:5000, required_without_all:attachments,attachment_media_id | "Please provide submission text or upload an attachment." |
| BC-VAL-05 | attachments | nullable, array | — |
| BC-VAL-06 | attachments.* | file, max:10240, mimes:pdf,doc,docx,txt,jpg,jpeg,png,zip | "Each attachment must be a file of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." |
| BC-VAL-07 | is_active | nullable, boolean | — |

### 5.3 Validation Rules — `HomeworkReviewRequest` (Grading)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-R01 | status_id | required, integer | — |
| BC-VAL-R02 | marks_obtained | nullable, numeric, min:0, max:{homework.max_marks} | "Marks obtained cannot exceed the maximum marks of the homework." |
| BC-VAL-R03 | teacher_feedback | nullable, string, max:2000 | — |

### 5.4 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.home-work-submission.viewAny | index() | Without → 403 |
| BC-AUTH-02 | tenant.home-work-submission.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.home-work-submission.view | show() | Without → 403 |
| BC-AUTH-04 | tenant.home-work-submission.update | edit(), update() | Without → 403 |
| BC-AUTH-05 | tenant.home-work-submission.delete | destroy() | Without → 403 |
| BC-AUTH-06 | tenant.home-work-submission.restore | trashed(), restore() | Without → 403 |
| BC-AUTH-07 | tenant.home-work-submission.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-08 | tenant.home-work.update | review() | Without → 403 (uses home-work.update for grading) |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | One submission per assignment | `assignment_id` UNIQUE constraint; duplicate rejected |
| BC-BIZ-02 | Submission must have content | At least `submission_text` OR a file required |
| BC-BIZ-03 | Late detection automatic | `is_late` computed by comparing `submitted_at` vs effective due date |
| BC-BIZ-04 | Marks within range | 0 <= marks_obtained <= homework.max_marks |
| BC-BIZ-05 | Grading creates audit trail | `graded_by` = current user; `graded_at` = now |
| BC-BIZ-06 | Resubmission increments counter | `resubmission_count++` on each resubmit |
| BC-BIZ-07 | Resubmission refreshes timeline | `submitted_at` updated; `is_late` re-evaluated |
| BC-BIZ-08 | Auto-publish score visibility | If `auto_publish_score=true`, `score_published_at` set on grade |
| BC-BIZ-09 | Soft delete sets `is_active=false` | Controller flips before `delete()` |
| BC-BIZ-10 | Bulk download compiles ZIP | All submission files for a homework in one ZIP |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | assignment_id | lms_homework_assignment | CASCADE |
| BC-REF-02 | homework_id | lms_homework | CASCADE |
| BC-REF-03 | student_id | std_students | CASCADE |
| BC-REF-04 | status_id | sys_dropdown_table | RESTRICT |
| BC-REF-05 | graded_by | sys_users | SET NULL |
| BC-REF-06 | created_by | sys_users | SET NULL |
| BC-REF-07 | updated_by | sys_users | SET NULL |

### 5.7 DDL Conditions

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-CON-01 | assignment_id UNIQUE — one active submission per assignment | DB UNIQUE constraint prevents duplicate submissions for same assignment |
| BC-CON-02 | Teacher requests resubmission → status = RESUBMIT_REQUESTED | Student can update submission, resubmission_count increments, submitted_at updated, is_late re-evaluated |
| BC-CON-03 | score_published_at set on grading if auto_publish_score=1 | If homework.auto_publish_score=1 → score_published_at = graded_at; if 0 → set when teacher manually publishes |
| BC-CON-04 | attachments_json structure | Array of objects: { "media_id": INT, "file_name": STRING, "uploaded_at": DATETIME } |
| BC-CON-05 | attachments_json replaces single attachment_media_id from v2 | v2 used single FK; v3+ uses JSON array for multiple files |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Submission List Loads With All Filters | Page loads with search bar, homework filter, student filter, status filter, late flag filter, graded/ungraded filter | — | — | ⬜ |
| TC-P02 | Create Submission With Text Only | Submission with `submission_text` saved; `submitted_at` set | — | — | ⬜ |
| TC-P03 | Create Submission With File Only | Submission with file upload saved; file stored via Spatie/JSON | — | — | ⬜ |
| TC-P04 | Create Submission With Text + File (Hybrid) | Both text and file saved correctly | — | — | ⬜ |
| TC-P05 | On-Time Submission Detected | `submitted_at` <= due_date → `is_late=false` | — | — | ⬜ |
| TC-P06 | Late Submission Detected | `submitted_at` > due_date → `is_late=true` | — | — | ⬜ |
| TC-P07 | View Submission Details | Show page displays student info, homework context, submission text, files, timestamp, late flag, status, grading data | — | — | ⬜ |
| TC-P08 | Edit Submission Text | `submission_text` updated; `updated_at` refreshed | — | — | ⬜ |
| TC-P09 | Edit Submission — Add New Files | New files uploaded alongside existing ones | — | — | ⬜ |
| TC-P10 | Edit Submission — Remove Files | Existing files removed via `existing_attachments` array | — | — | ⬜ |
| TC-P11 | Review/Grade Submission With Marks and Feedback | `marks_obtained`, `teacher_feedback`, `graded_by`, `graded_at` saved; status updated | — | — | ⬜ |
| TC-P12 | Review — Set Status To Resubmit Requested | `is_resubmission_requested=true`; student can resubmit | — | — | ⬜ |
| TC-P13 | Review — Reject Submission | Status set to Rejected value | — | — | ⬜ |
| TC-P14 | Resubmission After Request | New submission for same assignment allowed; `resubmission_count` incremented | — | — | ⬜ |
| TC-P15 | Auto-Publish Score On Grading | If `auto_publish_score=true`, `score_published_at` set immediately | — | — | ⬜ |
| TC-P16 | Filter By Homework | Selecting specific homework shows only its submissions | — | — | ⬜ |
| TC-P17 | Filter By Student | Selecting student shows only that student's submissions | — | — | ⬜ |
| TC-P18 | Filter By Status | Selecting status (Submitted/Under Review/Graded/etc.) filters correctly | — | — | ⬜ |
| TC-P19 | Filter By Late Flag | True shows only late; False shows only on-time | — | — | ⬜ |
| TC-P20 | Filter Graded/Ungraded | Graded filter shows submissions with marks; Ungraded shows without | — | — | ⬜ |
| TC-P21 | Search By Student Name | Typing student name finds submission | — | — | ⬜ |
| TC-P22 | Search By Homework Title | Typing homework title finds submission | — | — | ⬜ |
| TC-P23 | Soft Delete Submission | `deleted_at` set; `is_active=false` | — | — | ⬜ |
| TC-P24 | Trash Page Lists Deleted Submissions | Trash shows soft-deleted submissions with restore + force delete | — | — | ⬜ |
| TC-P25 | Restore Submission | `deleted_at=NULL`; `is_active=true` | — | — | ⬜ |
| TC-P26 | Force Delete Submission | Record permanently removed | — | — | ⬜ |
| TC-P27 | Toggle Status Active/Inactive | AJAX toggle flips `is_active` | — | — | ⬜ |
| TC-P28 | Bulk Download All Files | ZIP file downloaded with all submission files named by student | — | — | ⬜ |
| TC-P29 | Empty State — No Submissions For Filter | "No records found" message | — | — | ⬜ |
| TC-P30 | Filter Submissions By Active/Inactive Status | Selecting Active/Inactive toggles grid to show matching submissions | — | — | ⬜ |
| TC-P31 | Search Submissions By Admission Number | Typing admission number finds matching student's submissions | — | — | ⬜ |
| TC-P32 | Search Submissions By Student Email | Typing student email finds matching submissions | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Empty Submission (No Text, No File) | "Please provide submission text or upload an attachment." | — | — | ⬜ |
| TC-N02 | Duplicate Submission For Same Assignment | "This assignment already has a submission." | — | — | ⬜ |
| TC-N03 | Marks Exceed Maximum Marks | "Marks obtained cannot exceed the maximum marks of the homework." | — | — | ⬜ |
| TC-N04 | Marks Negative Value | Validation fails on marks_obtained.min:0 | — | — | ⬜ |
| TC-N05 | Teacher Feedback Exceeds 2000 Characters | "Feedback is too long (max 2000 characters)." | — | — | ⬜ |
| TC-N06 | Invalid File Type (.exe) | "Each attachment must be a file of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." | — | — | ⬜ |
| TC-N07 | File Exceeds 10MB | "The file may not be greater than 10240 kilobytes." | — | — | ⬜ |
| TC-N08 | Non-Existent `homework_id` | Validation error on homework_id.exists | — | — | ⬜ |
| TC-N09 | Non-Existent `assignment_id` | Validation error on assignment_id.exists | — | — | ⬜ |
| TC-N10 | View Invalid Submission ID (404) | `/homework-submission/99999` returns HTTP 404 | — | — | ⬜ |
| TC-N11 | Edit Invalid Submission ID (404) | `/homework-submission/99999/edit` returns HTTP 404 | — | — | ⬜ |
| TC-N12 | Delete Non-Existent Submission | HTTP 404 | — | — | ⬜ |
| TC-N13 | Permission 403 — No Submission Permission | User without `tenant.home-work-submission.*` sees 403 | — | — | ⬜ |
| TC-N14 | Guest Access Redirect | Logged-out user redirected to /login | — | — | ⬜ |
| TC-N15 | Bulk Download — No Files Exist | "No submission files found for this homework." — HTTP 404/notice | — | — | ⬜ |
| TC-N16 | Graded At Required When Graded By Provided | "Graded at is required when graded by is provided." | — | — | ⬜ |
| TC-N17 | Graded By Required When Graded At Provided | "Graded by is required when graded at is provided." | — | — | ⬜ |
| TC-N18 | Restore Non-Deleted Submission | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N19 | Force Delete Non-Trashed Submission | `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N20 | Max Length — submission_text > 5000 Characters | Validation fails on submission_text.max:5000 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | `assignment_id` unique constraint enforced | Duplicate assignment_id → DB unique violation or validation error | — | — | ⬜ |
| TC-D02 | B | Late flag auto-computed on create | `is_late` set based on `submitted_at` vs assignment/homework `due_date` | — | — | ⬜ |
| TC-D03 | C | Resubmission counter increments | After resubmit, `resubmission_count` = previous + 1 | — | — | ⬜ |
| TC-D04 | D | Grading sets `graded_at` = now | `graded_at` = current timestamp when `review()` called with marks | — | — | ⬜ |
| TC-D05 | E | Score publish timestamp set when auto-publish enabled | `score_published_at` set on grade if homework.auto_publish_score=true | — | — | ⬜ |
| TC-D06 | F | Soft delete cascading — submission deleted → assignment status not changed | Assignment remains; submission can be restored | — | — | ⬜ |
| TC-D07 | G | `marks_obtained` decimal precision | Stored as DECIMAL(5,2); 99.99 saved correctly | — | — | ⬜ |
| TC-D08 | H | `submitted_at` cast as datetime | Model returns Carbon instance | — | — | ⬜ |
| TC-D09 | I | `findOrFail` — non-existent ID returns 404 | All CRUD methods return HTTP 404 for invalid ID | — | — | ⬜ |
| TC-D10 | J | `Gate::authorize` before controller actions | Each method gates appropriate permission string | — | — | ⬜ |
| TC-D11 | K | Activity log — all events tracked | Stored, Updated, Trashed, Restored, Deleted logged | — | — | ⬜ |
| TC-D12 | L | Create → created_by set to auth user | `created_by` = current authenticated user's ID after store | — | — | ⬜ |
| TC-D13 | M | Update → updated_by set to auth user | `updated_by` updated to current user's ID after update | — | — | ⬜ |
| TC-D14 | N | ON DELETE CASCADE — assignment deletion cascades to submissions | Delete assignment → related submission records auto-deleted | — | — | ⬜ |
| TC-D15 | O | ON DELETE CASCADE — homework deletion cascades to submissions | Force-delete homework → all related submissions auto-deleted | — | — | ⬜ |
| TC-D16 | P | ON DELETE RESTRICT — status parent delete rejected | Delete sys_dropdown_table row used by submission status_id → DB FK error | — | — | ⬜ |
| TC-D17 | Q | ON DELETE SET NULL — graded_by/created_by/updated_by set to NULL on user delete | Delete sys_user → submission.graded_by=NULL, created_by=NULL, updated_by=NULL | — | — | ⬜ |
| TC-D18 | R | DEFAULT values on insert | New submission has is_late=0, resubmission_count=0, is_active=1 by default | — | — | ⬜ |
| TC-D19 | S | INDEX exists for query performance | EXPLAIN on homework_id+student_id, status_id, submitted_at shows index usage | — | — | ⬜ |
| TC-D20 | T | BC-CON-04 — attachments_json structure validation | Submission with multiple files stores JSON array with media_id, file_name, uploaded_at per entry | — | — | ⬜ |
| TC-D21 | U | BC-CON-05 — backward compatibility: v2 single FK not used | New submissions use attachments_json; no single attachment_media_id FK column exists | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can directives for all CRUD buttons | Create, Edit, Delete, View, Restore, ForceDelete wrapped in @can | — | — | ◌ |
| TC-CR02 | CR | P1 | DB Transaction in store | `store()` uses `DB::transaction()`; `review()` does NOT use transaction | — | — | ◌ |
| TC-CR03 | CR | P1 | isset()/null-safe checks for student/homework relations | `$submission?->student?->first_name` used; no undefined errors | — | — | ◌ |
| TC-CR04 | CR | P1 | File type and size validation on server side | `attachments.*.mimes` and `attachments.*.max:10240` validated | — | — | ◌ |
| TC-CR05 | CR | P1 | Marks validation against homework max_marks | `HomeworkReviewRequest` computes max from homework relation | — | — | ◌ |
| TC-CR06 | CR | P1 | Hub page tab integration — permission-filtered tab | Tab only visible with `tenant.home-work-submission.viewAny`; direct URL returns 403 without permission | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-P02: Create Submission With Text Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to LMS → Homework → Submission tab | Submission list loads |
| 3 | Click "Add Submission" | Create form opens with homework, student dropdowns |
| 4 | Select homework from dropdown | Homework selected |
| 5 | Select student from dropdown | Student selected |
| 6 | Enter submission_text: "This is my homework answer" | Text entered |
| 7 | Leave file attachment empty | No file |
| 8 | Click "Save" | POST to store(); redirects; success message |
| 9 | DB check: `SELECT * FROM lms_homework_submissions WHERE student_id={id} AND homework_id={id}` | Record exists; `submitted_at` set; `is_late` computed |

#### TC-P01: Submission List Loads With All Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to LMS → Homework → Submission tab | Submission page loads with grid |
| 3 | Verify search bar is present | Search input visible |
| 4 | Verify homework filter dropdown | Dropdown with homework list visible |
| 5 | Verify student filter dropdown | Dropdown with student list visible |
| 6 | Verify status filter, late flag filter, graded/ungraded filter | All filter controls visible |
| 7 | Verify pagination is set to 10 per page | Pagination info shows 10 entries |

#### TC-P03: Create Submission With File Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Add Submission form | Form visible |
| 3 | Select homework and student | Required fields set |
| 4 | Leave submission_text empty | Text field empty |
| 5 | Upload a valid PDF file (under 10MB) | File attached; preview shown |
| 6 | Click "Save" | Submission created; success message |
| 7 | DB check: `SELECT sub_attachment_media_id FROM lms_homework_submissions WHERE id={id}` | File reference stored in JSON column or Spatie media |

#### TC-P04: Create Submission With Text + File (Hybrid)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Add Submission form | Form visible |
| 3 | Select homework and student | Required fields set |
| 4 | Enter submission_text: "My answer with supporting file" | Text entered |
| 5 | Upload a valid DOCX file | File attached |
| 6 | Click "Save" | Submission created; success message |
| 7 | DB check: query submission record | Both `submission_text` and file data saved |

#### TC-P05: On-Time Submission Detected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a homework with due_date = 20 July 2026 | Homework exists |
| 2 | Create assignment for student with same due_date | Assignment exists |
| 3 | Create submission with submitted_at = 19 July 2026 (before due) | Request succeeds |
| 4 | DB check: `SELECT is_late FROM lms_homework_submissions WHERE id={id}` | `is_late` = false (0) |

#### TC-P06: Late Submission Detected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a homework with due_date = 20 July 2026 | Homework exists |
| 2 | Create assignment for student with same due_date | Assignment exists |
| 3 | Create submission with submitted_at = 21 July 2026 (after due) | Request succeeds |
| 4 | DB check: `SELECT is_late FROM lms_homework_submissions WHERE id={id}` | `is_late` = true (1) |

#### TC-P07: View Submission Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid loads |
| 3 | Click on a submission row or "View" button | Show page opens |
| 4 | Verify student info displayed | Student name, class visible |
| 5 | Verify homework context displayed | Homework title, due date visible |
| 6 | Verify submission text, files, timestamp, late flag, status | All fields displayed correctly |
| 7 | If graded, verify grading data (marks, feedback, graded by, graded at) | Grading section visible |

#### TC-P08: Edit Submission Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid loads |
| 3 | Click "Edit" on an existing submission | Edit form pre-filled with current data |
| 4 | Modify submission_text to "Updated answer text" | Text updated in field |
| 5 | Click "Update" | PUT request; success message |
| 6 | DB check: `SELECT submission_text, updated_at FROM lms_homework_submissions WHERE id={id}` | `submission_text` changed; `updated_at` refreshed |

#### TC-P09: Edit Submission — Add New Files

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Edit form for a submission with existing files | Form shows current files |
| 3 | Upload a new JPG file | New file added to attachment list |
| 4 | Click "Update" | Update succeeds |
| 5 | Verify both original and new files present | Media library shows all files |

#### TC-P10: Edit Submission — Remove Files

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Edit form for a submission with existing files | Form shows current files |
| 3 | Remove/check one existing file for deletion via `existing_attachments` array | File marked for removal |
| 4 | Click "Update" | Update succeeds |
| 5 | Verify removed file no longer present | Media library shows remaining files only |

#### TC-P11: Review/Grade Submission With Marks and Feedback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid loads |
| 3 | Click "Review" on an ungraded submission | Review form opens |
| 4 | Select a status (e.g., Graded) | Status selected |
| 5 | Enter marks_obtained = 85 | Marks entered |
| 6 | Enter teacher_feedback: "Good work!" | Feedback entered |
| 7 | Click "Submit Review" | POST to review(); success message |
| 8 | DB check: query submission record | `marks_obtained`, `teacher_feedback`, `graded_by`, `graded_at` saved; status updated |

#### TC-P12: Review — Set Status To Resubmit Requested

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission | Review form visible |
| 3 | Set status to "Resubmit Requested" | Status selected |
| 4 | Optionally add feedback explaining resubmission reason | Feedback entered |
| 5 | Click "Submit Review" | Review saved |
| 6 | DB check: `SELECT is_resubmission_requested FROM lms_homework_submissions WHERE id={id}` | `is_resubmission_requested` = true (1) |

#### TC-P13: Review — Reject Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission | Review form visible |
| 3 | Set status to "Rejected" | Status selected |
| 4 | Provide feedback explaining rejection | Feedback entered |
| 5 | Click "Submit Review" | Review saved |
| 6 | DB check: `SELECT status_id FROM lms_homework_submissions WHERE id={id}` | Status points to Rejected dropdown value |

#### TC-P14: Resubmission After Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prerequisite: submission with `is_resubmission_requested=true` | Resubmission requested |
| 2 | Open Add Submission form for the same assignment_id | Form loads |
| 3 | Enter new submission_text and/or file | Content entered |
| 4 | Click "Save" | New submission saved (no duplicate error) |
| 5 | DB check: `SELECT resubmission_count FROM lms_homework_submissions WHERE id={new_id}` | `resubmission_count` = 1 (previous + 1) |
| 6 | DB check: `SELECT submitted_at, is_late FROM lms_homework_submissions WHERE id={new_id}` | `submitted_at` updated; `is_late` re-evaluated |

#### TC-P15: Auto-Publish Score On Grading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prerequisite: homework with `auto_publish_score=true` | Homework configured |
| 2 | Create submission for this homework | Submission exists |
| 3 | Open Review form and enter marks + feedback | Review data entered |
| 4 | Click "Submit Review" | Review saved |
| 5 | DB check: `SELECT score_published_at FROM lms_homework_submissions WHERE id={id}` | `score_published_at` set to current timestamp |
| 6 | Student view: student can see published score | Score visible in student portal |

#### TC-P16: Filter By Homework

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Select a specific homework from homework filter dropdown | Grid refreshes |
| 4 | Verify all displayed submissions belong to selected homework | Homework column matches filter for every row |

#### TC-P17: Filter By Student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Select a specific student from student filter dropdown | Grid refreshes |
| 4 | Verify all displayed submissions belong to selected student | Student column matches filter for every row |

#### TC-P18: Filter By Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Select a status (e.g., "Graded") from status filter dropdown | Grid refreshes |
| 4 | Verify all displayed submissions have the selected status | Status column matches filter for every row |

#### TC-P19: Filter By Late Flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Toggle late flag filter to "Late" | Grid refreshes showing only late submissions |
| 4 | Toggle late flag filter to "On-Time" | Grid refreshes showing only on-time submissions |

#### TC-P20: Filter Graded/Ungraded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Select "Graded" filter | Grid shows only submissions with marks_obtained NOT NULL |
| 4 | Select "Ungraded" filter | Grid shows only submissions with marks_obtained NULL |

#### TC-P21: Search By Student Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Type a partial student name in search bar | Grid refreshes |
| 4 | Verify displayed submissions match searched student name | Student name contains search term |

#### TC-P22: Search By Homework Title

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Type a partial homework title in search bar | Grid refreshes |
| 4 | Verify displayed submissions match searched homework title | Homework title contains search term |

#### TC-P23: Soft Delete Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid loads |
| 3 | Click "Delete" on an existing submission | Confirmation dialog appears |
| 4 | Confirm deletion | AJAX/DELETE request; success message; row disappears |
| 5 | DB check: `SELECT deleted_at, is_active FROM lms_homework_submissions WHERE id={id}` | `deleted_at` set to timestamp; `is_active` = false (0) |

#### TC-P24: Trash Page Lists Deleted Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Trash page (`/homework-submission/trash/view`) | Trash view loads |
| 3 | Verify soft-deleted submissions are listed | Deleted records visible with deleted_at timestamp |
| 4 | Verify "Restore" and "Force Delete" buttons present | Both action buttons visible for each trashed record |

#### TC-P25: Restore Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Trash page | Trash view with deleted submissions |
| 3 | Click "Restore" on a trashed submission | Confirmation dialog appears |
| 4 | Confirm restore | POST to restore(); success message |
| 5 | DB check: `SELECT deleted_at, is_active FROM lms_homework_submissions WHERE id={id}` | `deleted_at` = NULL; `is_active` = true (1) |

#### TC-P26: Force Delete Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Trash page | Trash view with deleted submissions |
| 3 | Click "Force Delete" on a trashed submission | Confirmation dialog appears |
| 4 | Confirm force delete | DELETE to forceDelete(); success message |
| 5 | DB check: `SELECT * FROM lms_homework_submissions WHERE id={id}` | Record permanently removed from database |

#### TC-P27: Toggle Status Active/Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid loads |
| 3 | Locate the toggle switch for a submission | Toggle shows current state |
| 4 | Click the toggle to flip status | AJAX request to toggleStatus(); status flips |
| 5 | Verify UI reflects new active/inactive state | Toggle position updated; badge changes |
| 6 | DB check: `SELECT is_active FROM lms_homework_submissions WHERE id={id}` | `is_active` flipped |

#### TC-P28: Bulk Download All Files

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Prerequisite: multiple submissions with file attachments for same homework | Files exist |
| 3 | Navigate to Submission list filtered by that homework | Submissions visible |
| 4 | Click "Bulk Download" | ZIP file download triggered |
| 5 | Open downloaded ZIP | ZIP contains all submission files, named by student |

#### TC-P29: Empty State — No Submissions For Filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid loads |
| 3 | Apply filter combination that matches no records (e.g., non-existent student) | Grid refreshes |
| 4 | Verify empty state message | "No records found" message displayed |

#### TC-P30: Filter Submissions By Active/Inactive Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Select "Active" from the active/inactive filter dropdown | Grid refreshes showing only active (is_active=1) submissions |
| 4 | Select "Inactive" from the active/inactive filter dropdown | Grid refreshes showing only inactive (is_active=0) submissions |
| 5 | Select "All" to clear filter | All submissions shown regardless of status |

#### TC-P31: Search Submissions By Admission Number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Type a known admission number in the search bar | Grid refreshes |
| 4 | Verify displayed submissions belong to the student with that admission number | Only matching student's submissions visible |

#### TC-P32: Search Submissions By Student Email

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Submission list | Grid shows all submissions |
| 3 | Type a student's email address in the search bar | Grid refreshes |
| 4 | Verify displayed submissions belong to the student with that email | Only matching submissions visible |

#### TC-N01: Required — Empty Submission (No Text, No File)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add Submission form | Form visible |
| 2 | Select homework and student | Required fields set |
| 3 | Leave submission_text empty | Empty |
| 4 | Leave attachments empty | Empty |
| 5 | Click "Save" | Validation error: "Please provide submission text or upload an attachment." |
| 6 | Type some text, save again | Succeeds |

#### TC-N02: Duplicate Submission For Same Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Create first submission for assignment_id = X | Submission created successfully |
| 3 | Open Add Submission form again | Form visible |
| 4 | Select same assignment (assignment_id = X) | Assignment selected |
| 5 | Enter submission_text and click "Save" | Validation error: "This assignment already has a submission." |
| 6 | DB check: only one record for assignment_id = X | Single submission exists |

#### TC-N03: Marks Exceed Maximum Marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission where homework.max_marks = 100 | Review form visible |
| 3 | Enter marks_obtained = 150 (exceeds max) | Marks entered |
| 4 | Click "Submit Review" | Validation error: "Marks obtained cannot exceed the maximum marks of the homework." |
| 5 | Correct marks to 90 and resubmit | Review succeeds |

#### TC-N04: Marks Negative Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission | Review form visible |
| 3 | Enter marks_obtained = -5 | Negative value entered |
| 4 | Click "Submit Review" | Validation error on marks_obtained.min:0 |
| 5 | Correct marks to 0 and resubmit | Review succeeds |

#### TC-N05: Teacher Feedback Exceeds 2000 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission | Review form visible |
| 3 | Enter teacher_feedback with 2500 characters | Feedback text exceeds limit |
| 4 | Click "Submit Review" | Validation error: "Feedback is too long (max 2000 characters)." |
| 5 | Trim feedback to under 2000 chars and resubmit | Review succeeds |

#### TC-N06: Invalid File Type (.exe)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Add Submission form | Form visible |
| 3 | Select homework and student | Required fields set |
| 4 | Upload an .exe file | File attached |
| 5 | Click "Save" | Validation error: "Each attachment must be a file of type: pdf, doc, docx, txt, jpg, jpeg, png, zip." |
| 6 | Remove .exe, upload a PDF and save | Succeeds |

#### TC-N07: File Exceeds 10MB

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Add Submission form | Form visible |
| 3 | Select homework and student | Required fields set |
| 4 | Upload a file larger than 10MB (e.g., 15MB PDF) | File attached |
| 5 | Click "Save" | Validation error: "The file may not be greater than 10240 kilobytes." |
| 6 | Upload file under 10MB and save | Succeeds |

#### TC-N08: Non-Existent `homework_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Send a POST request with invalid homework_id (e.g., 99999) | Validation error on homework_id.exists |
| 3 | Verify no record created in DB | No new submission row inserted |

#### TC-N09: Non-Existent `assignment_id`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Send a POST request with invalid assignment_id (e.g., 99999) | Validation error on assignment_id.exists |
| 3 | Verify no record created in DB | No new submission row inserted |

#### TC-N10: View Invalid Submission ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to `/lms-home-work/homework-submission/99999` | HTTP 404 page returned |
| 3 | Verify error message or "Not Found" page | 404 error displayed |

#### TC-N11: Edit Invalid Submission ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to `/lms-home-work/homework-submission/99999/edit` | HTTP 404 page returned |
| 3 | Verify error message or "Not Found" page | 404 error displayed |

#### TC-N12: Delete Non-Existent Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Send DELETE request to `/lms-home-work/homework-submission/99999` | HTTP 404 returned |
| 3 | Verify error message | 404 error displayed |

#### TC-N13: Permission 403 — No Submission Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as a user without `tenant.home-work-submission.*` permissions | Dashboard loads |
| 2 | Navigate to Submission tab URL directly | HTTP 403 Forbidden returned |
| 3 | Verify access denied message | 403 error displayed |

#### TC-N14: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Log out of the application | User is logged out |
| 2 | Navigate to `/lms-home-work/homework-submission` | Redirected to /login page |
| 3 | Verify login form is displayed | Login page loaded |

#### TC-N15: Bulk Download — No Files Exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Prerequisite: homework with submissions but no file attachments | Text-only submissions exist |
| 3 | Trigger bulk download for that homework | "No submission files found for this homework." message or HTTP 404 |
| 4 | No ZIP file is downloaded | Download not triggered |

#### TC-N16: Graded At Required When Graded By Provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission | Review form visible |
| 3 | Set graded_by to a user ID without setting graded_at | Field set |
| 4 | Submit review | Validation error: "Graded at is required when graded by is provided." |

#### TC-N17: Graded By Required When Graded At Provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form for a submission | Review form visible |
| 3 | Set graded_at to a timestamp without setting graded_by | Field set |
| 4 | Submit review | Validation error: "Graded by is required when graded at is provided." |

#### TC-N18: Restore Non-Deleted Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Send POST to `/lms-home-work/homework-submission/{id}/restore` where submission is NOT soft-deleted | HTTP 404 returned |
| 3 | Verify `onlyTrashed()->find()` returns null | Record not found in trash |

#### TC-N19: Force Delete Non-Trashed Submission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Send DELETE to `/lms-home-work/homework-submission/{id}/force-delete` where submission is NOT soft-deleted | HTTP 404 returned |
| 3 | Verify `onlyTrashed()->find()` returns null | Record not found in trash |

#### TC-N20: Max Length — submission_text > 5000 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Add Submission form | Form visible |
| 3 | Select homework and student | Required fields set |
| 4 | Enter submission_text with 5001 characters | Text exceeds max length |
| 5 | Click "Save" | Validation error on submission_text.max:5000 |
| 6 | Trim text to 5000 characters and save | Submission created successfully |

#### TC-D01: `assignment_id` Unique Constraint Enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert first submission row with assignment_id = X via DB or UI | Row created |
| 2 | Attempt to insert second submission with same assignment_id = X | DB unique violation error or validation error |
| 3 | Verify the unique constraint `uq_hws_assignment` is enforced | Duplicate rejected; no second row |

#### TC-D02: Late Flag Auto-Computed On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework with due_date = 15 July | Homework exists |
| 2 | Create assignment for student with due_date = 15 July | Assignment exists |
| 3 | Create submission with submitted_at = 14 July (before due) | `is_late` = false |
| 4 | Create another submission with submitted_at = 16 July (after due) | `is_late` = true |
| 5 | DB check: `SELECT is_late FROM lms_homework_submissions WHERE id={id}` | Correct for each |

#### TC-D03: Resubmission Counter Increments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prerequisite: submission with `is_resubmission_requested=true` | Resubmission requested |
| 2 | Note current `resubmission_count` = N | Counter recorded |
| 3 | Create a new submission for the same assignment | Resubmission saved |
| 4 | DB check: `SELECT resubmission_count FROM lms_homework_submissions WHERE id={new_id}` | `resubmission_count` = N + 1 |

#### TC-D04: Grading Sets `graded_at` = Now

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form and grade a submission with marks | Review submitted |
| 3 | DB check: `SELECT graded_at, graded_by FROM lms_homework_submissions WHERE id={id}` | `graded_at` = current server timestamp; `graded_by` = current user ID |
| 4 | Verify timestamp is within seconds of the review action | Timestamp accurate |

#### TC-D05: Score Publish Timestamp Set When Auto-Publish Enabled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prerequisite: homework with `auto_publish_score=true` | Homework configured |
| 2 | Grade a submission for this homework via Review form | Review submitted |
| 3 | DB check: `SELECT score_published_at FROM lms_homework_submissions WHERE id={id}` | `score_published_at` set to current timestamp |
| 4 | For homework with `auto_publish_score=false`, repeat grading | `score_published_at` remains NULL |

#### TC-D06: Soft Delete Cascading — Submission Deleted, Assignment Unchanged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prerequisite: submission linked to assignment_id = X | Submission and assignment exist |
| 2 | Soft delete the submission | `deleted_at` set |
| 3 | DB check: `SELECT * FROM lms_homework_assignments WHERE id = X` | Assignment record still exists, unchanged |
| 4 | Restore the submission | Submission restored |
| 5 | Verify submission reassociated with same assignment | `assignment_id` = X still valid |

#### TC-D07: `marks_obtained` Decimal Precision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Review form and enter marks_obtained = 99.99 | Marks entered |
| 3 | Submit review | Review saved |
| 4 | DB check: `SELECT marks_obtained FROM lms_homework_submissions WHERE id={id}` | Value = 99.99 (DECIMAL(5,2) precision preserved) |

#### TC-D08: `submitted_at` Cast As Datetime

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a submission via controller | Submission created |
| 2 | In debug/tinker, retrieve the model: `HomeworkSubmission::find($id)` | Model loaded |
| 3 | Check type of `submitted_at` attribute | Returns Carbon instance (not string) |
| 4 | Verify `submitted_at->format('Y-m-d H:i:s')` works | Formatted date string returned |

#### TC-D09: `findOrFail` — Non-Existent ID Returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request show/edit/update/destroy for ID = 99999 | HTTP 404 for each action |
| 2 | Verify `findOrFail` exception is thrown | `ModelNotFoundException` results in 404 response |
| 3 | Check each CRUD endpoint returns 404 consistently | Show, Edit, Update, Delete all return 404 |

#### TC-D10: `Gate::authorize` Before Controller Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller code for `HomeworkSubmissionController` | File inspected |
| 2 | Locate `__construct()` or individual method gates | Each method calls `Gate::authorize()` or `$this->authorize()` |
| 3 | Verify index gates `viewAny`, create gates `create`, store gates `create`, show gates `view`, edit/update gates `update`, destroy gates `delete`, restore gates `restore`, forceDelete gates `forceDelete`, review gates `home-work.update` | Correct permission string for each method |

#### TC-D11: Activity Log — All Events Tracked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a submission | "Stored" activity logged |
| 2 | Update the submission | "Updated" activity logged |
| 3 | Soft delete the submission | "Trashed" activity logged |
| 4 | Restore the submission | "Restored" activity logged |
| 5 | Force delete the submission | "Deleted" activity logged |
| 6 | DB check: `SELECT * FROM activity_log WHERE subject_type = 'HomeworkSubmission' AND subject_id = {id}` | All five events recorded with correct description and causer |

#### TC-D12: Create → `created_by` Set To Auth User

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin (user ID = 1) | Dashboard loads |
| 2 | Create a new submission via the form | Submission created |
| 3 | DB check: `SELECT created_by FROM lms_homework_submissions WHERE id={id}` | `created_by` = 1 (authenticated user's ID) |
| 4 | Repeat with another user | `created_by` matches that user's ID |

#### TC-D13: Update → `updated_by` Set To Auth User

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin (user ID = 1) | Dashboard loads |
| 2 | Edit an existing submission and update | Update saved |
| 3 | DB check: `SELECT updated_by FROM lms_homework_submissions WHERE id={id}` | `updated_by` = 1 (authenticated user's ID) |
| 4 | Verify `updated_by` differs from `created_by` if different user performed update | `updated_by` reflects current user |

#### TC-CR01: Blade @can Directives For All CRUD Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the index blade file for homework submission | Blade file loaded |
| 2 | Search for `@can('tenant.home-work-submission.create')` around Create/Add button | Create button wrapped in @can |
| 3 | Search for `@can('tenant.home-work-submission.update')` around Edit button | Edit button wrapped in @can |
| 4 | Search for `@can('tenant.home-work-submission.delete')` around Delete button | Delete button wrapped in @can |
| 5 | Search for `@can('tenant.home-work-submission.view')` around View button | View button wrapped in @can |
| 6 | Search for `@can('tenant.home-work-submission.restore')` around Restore button | Restore button wrapped in @can |
| 7 | Search for `@can('tenant.home-work-submission.forceDelete')` around Force Delete button | Force Delete button wrapped in @can |

#### TC-CR02: DB Transaction In Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `HomeworkSubmissionController@store()` method | Controller file loaded |
| 2 | Verify `store()` method wraps logic in `DB::transaction()` | `DB::transaction()` or `\DB::beginTransaction()` present |
| 3 | Open `HomeworkSubmissionController@review()` method | Controller file loaded |
| 4 | Verify `review()` method does NOT use `DB::transaction()` | No transaction wrapper in review method |

#### TC-CR03: isset()/Null-Safe Checks For Student/Homework Relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade files and controller files that access `student` and `homework` relations | Files inspected |
| 2 | Search for `$submission->student` access patterns | Null-safe operator `?->` or `isset()` check used |
| 3 | Search for `$submission->homework` access patterns | Null-safe operator `?->` or `isset()` check used |
| 4 | Verify no undefined property errors possible when relation is null | Safe access patterns used throughout |

#### TC-CR04: File Type And Size Validation On Server Side

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `HomeworkSubmissionRequest` validation rules | Request file loaded |
| 2 | Locate `attachments.*` validation rules | `mimes:pdf,doc,docx,txt,jpg,jpeg,png,zip` present |
| 3 | Verify `max:10240` rule for file size | `max:10240` (10MB) present |
| 4 | Verify no other file types are allowed silently | Only listed mimes accepted |

#### TC-CR05: Marks Validation Against Homework max_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `HomeworkReviewRequest` | Request file loaded |
| 2 | Locate `marks_obtained` validation rule | Rule includes `max:{homework.max_marks}` or dynamic max |
| 3 | Verify the rule computes `max` from the homework relationship | Controller/Request fetches homework and passes max_marks |
| 4 | Confirm rule prevents marks > homework.max_marks | Validation rejects excess marks |

#### TC-CR06: Hub Page Tab Integration — Permission-Filtered Tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open the Hub page blade file that renders Homework tabs | Hub blade file loaded |
| 2 | Locate the Submission tab rendering code | Tab rendered with `@can('tenant.home-work-submission.viewAny')` check |
| 3 | Verify tab is hidden for users without the permission | Tab not rendered when permission absent |
| 4 | Login as user with permission and navigate to submission URL | Page loads normally |
| 5 | Login as user without permission and navigate to same URL | HTTP 403 Forbidden returned |

#### TC-D14: ON DELETE CASCADE — Assignment Deletion Cascades to Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish, student submits | Submission record exists |
| 2 | Delete the assignment record | Assignment removed |
| 3 | DB check: SELECT COUNT(*) FROM lms_homework_submissions WHERE assignment_id={id} | 0 rows (cascaded) |

#### TC-D15: ON DELETE CASCADE — Homework Deletion Cascades to Submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create homework, publish, student submits | Submission exists linked to homework |
| 2 | Force-delete the homework | Homework permanently removed |
| 3 | DB check: SELECT COUNT(*) FROM lms_homework_submissions WHERE homework_id={id} | 0 rows (cascaded) |

#### TC-D16: ON DELETE RESTRICT — Status Parent Delete Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find submission with status_id referencing sys_dropdown_table row | Status FK exists |
| 2 | Attempt DELETE on that sys_dropdown_table row | DB throws FK RESTRICT error |

#### TC-D17: ON DELETE SET NULL — Graded By/Created By/Updated By Set to NULL on User Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find graded submission with graded_by=UserA, created_by=UserB, updated_by=UserC | All FKs populated |
| 2 | Delete UserA, UserB, UserC from sys_users | graded_by=NULL, created_by=NULL, updated_by=NULL |

#### TC-D18: DEFAULT Values on Insert

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student submits homework | Submission record created |
| 2 | DB check: is_late=0, resubmission_count=0, is_active=1 | All defaults applied |

#### TC-D19: INDEX Exists for Query Performance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run EXPLAIN SELECT on lms_homework_submissions WHERE homework_id=? AND student_id=? | Uses idx_hws_homework_student |
| 2 | Run EXPLAIN on status_id filter | Uses idx_hws_status |
| 3 | Run EXPLAIN on submitted_at range query | Uses idx_hws_submitted_at |

#### TC-D20: BC-CON-04 — attachments_json Structure Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Open Add Submission form and select homework + student | Form ready |
| 3 | Upload two valid files (PDF and DOCX) | Files attached |
| 4 | Enter submission_text and click "Save" | Submission created; success message |
| 5 | DB check: `SELECT sub_attachment_media_id FROM lms_homework_submissions WHERE id={id}` | Column contains valid JSON array |
| 6 | Parse the JSON and verify each entry | Each entry has `media_id` (INT), `file_name` (STRING), `uploaded_at` (DATETIME) |
| 7 | Verify array contains exactly 2 entries matching uploaded files | Both files represented in JSON array |

#### TC-D21: BC-CON-05 — Backward Compatibility: v2 Single FK Not Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the DDL for `lms_homework_submissions` table | Table definition loaded |
| 2 | Confirm no `attachment_media_id` INT FK column exists | Column absent; `sub_attachment_media_id` JSON column used instead |
| 3 | Create a submission via the UI with file attachment | Submission created |
| 4 | DB check: `SELECT sub_attachment_media_id FROM lms_homework_submissions WHERE id={id}` | File stored in JSON column, not a single FK |
| 5 | Verify no v2-style `attachment_media_id` column referenced in code or DB | Backward incompatible — v2 FK fully replaced by JSON |
