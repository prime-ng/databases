# lms_OfflineUpload_TcList

## Module: LmsExam → Upload Tab → Offline Upload (Answer Sheet Upload for Offline Exams)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | LmsExam |
| Tab Group | Upload |
| Feature | Offline Upload — Answer Sheet Upload for Offline (Pen-and-Paper) Exams |
| URL(s) | `/lms-exam/upload` (parent tab), `GET /lms-exam/upload?active_tab=offline_upload` (sub-tab), `lms-exam.exam.question-wise.data` (AJAX GET – question-wise data), `lms-exam.exam.question-wise.save` (AJAX POST – save question-wise), `lms-exam.marks.bulk-upload` (AJAX POST – bulk upload), `lms-exam.exam.attemptDetail` (GET view), `lms-exam.exam.paper-set.view-questions` (GET), `lms-exam.exam.get-exams-by-class` (AJAX), `lms-exam.sections` (AJAX), `lms-exam.exam.get-subjects-by-class-section` (AJAX), `lms-exam.paper-sets` (AJAX), `lms-exam.students` (AJAX), `lms-exam.exam.get-papers-by-exam` (AJAX) |
| Controller | `Modules\LmsExam\Http\Controllers\LmsExamController` — methods: `uploadOnline()` (view data only), `getStudentsData()`, `getQuestionWiseData()`, `saveQuestionWiseMarks()`, `bulkUploadMarks()`, `questionWiseUploadMarks()`, `getQuestionWiseDataOffline()`, `saveQuestionWiseMarksOffline()`, `createOfflineAttempt()`, `getExamsByClass()`, `getSections()`, `getSubjectsByClassSection()`, `getStudents()`, `getPapersByExam()`, `getPaperSets()` |
| Model(s) | `OfflineExamUploadMark`, `OfflineExamUploadDetail`, `ExamAttempt`, `ExamAttemptAnswer`, `ExamPaper`, `ExamPaperSet`, `ExamAllocation`, `Exam`, `Student`, `SchoolClass`, `Section`, `Subject` |
| Validation (Bulk Upload) | Controller: file required and valid, student_id required, exam_paper_id required |
| Validation (Question-Wise Save) | Controller: question-wise data sent as FormData with student_id, exam_paper_id, exam_set_id, mode=OFFLINE |
| Permissions | `tenant.answer-sheet-offline-exam.view` (tab visibility), `tenant.offline-assessment.view` (gate) |
| Soft Deletes | N/A |
| Activity Log | Not directly logged |
| File Upload | PDF via `storageService->storeFile()`, stored in tenant-specific path `lms_exam_upload_path` |
| Pagination | 10 per page, `active_tab=offline_upload` appended to pagination links |
| Entry Modes | `BULK_TOTAL` (simple total marks), `QUESTION_WISE` (per-question grading with optional file upload). Mode set per paper in `lms_exam_papers.offline_entry_mode`. If `is_ques_wise_file_upload = 1`, question-wise modal used even for BULK_TOTAL papers |

---

## 2. Pre-conditions

- Required permissions: `tenant.answer-sheet-offline-exam.view`, `tenant.offline-assessment.view`
- Required seed data: At least one active `SchoolClass`, `Section`, `Subject`, `Exam` (mode=OFFLINE), `ExamPaper` (mode=OFFLINE), `ExamPaperSet`, `Student` allocated to the paper
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- At least one offline exam paper must have `offline_entry_mode` set to either `BULK_TOTAL` or `QUESTION_WISE`
- For bulk upload: Valid PDF file under 50MB
- For question-wise: MCQ and descriptive questions in paper set
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads, the `upload()` method (via `upload.blade.php`) renders both `online_upload` and `offline_upload` partials. The offline partial shows empty table until `active_tab=offline_upload` is present:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Shared: All Classes | LmsExamController@upload | SchoolClass::where('is_active',1)->orderBy('name') | is_active=1 | None |
| Shared: Sections | LmsExamController@upload | Section::all() | None | None |
| Shared: Subjects | LmsExamController@upload | Subject::all() | None | None |
| Shared: Exams | LmsExamController@upload | Exam::where('is_active',1)->orderBy('title') | is_active=1 | None |
| Students Data | getStudentsData() (AJAX) | Allocated students with attempt data: is_present_offline, is_evaluated, roll_no, student_name, admn_no, offline_attachment_data | class_id, section_id, subject_id, exam_id, exam_paper_id, exam_set_id, student_id | 10/page |
| Question-Wise Data | getQuestionWiseData() (AJAX) | MCQ/descriptive questions from paper set with options, attachment data | student_id, exam_paper_id, exam_set_id, mode=OFFLINE | None |

Page initially shows: "Please search to view offline data." — data loads only when `active_tab=offline_upload` is present.

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His') . random_int(100, 999)` for unique test data
- **Paper configuration**: Create papers with `mode=OFFLINE` and varying `offline_entry_mode` values (BULK_TOTAL, QUESTION_WISE)
- **Attempt creation**: For offline tests, attempts may not exist until first upload (bulk upload creates attempt via `firstOrCreate`)
- **Bulk upload test**: Create `OfflineExamUploadMark` records with valid `attachment_data` JSON
- **Question-wise test**: Create `OfflineExamUploadDetail` records linked to `OfflineExamUploadMark` via `exam_attempt_id`
- **Pre-test cleanup**: Delete created `OfflineExamUploadMark`, `OfflineExamUploadDetail`, and `ExamAttempt` records
- **File upload**: Valid PDF under 2MB; invalid files for negative tests
- **JSON fields**: `attachment_data` stored as JSON in both `OfflineExamUploadMark` and `OfflineExamUploadDetail`
- **MCQ options**: Use question options from `qns_question_options` with `is_correct` flag

---

## 5. Business Conditions

### 5.1 Database Schema — `lms_exam_papers` (Offline-related columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT PK | Auto-increment |
| BC-DB-02 | offline_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | DEFAULT 'BULK_TOTAL'; determines which modal opens |
| BC-DB-03 | is_ques_wise_file_upload | TINYINT(1) | DEFAULT 0; if 1, forces question-wise modal even for BULK_TOTAL |
| BC-DB-04 | total_marks | DECIMAL(8,2) | Default NULL; max marks for the paper |
| BC-DB-05 | mode | ENUM('ONLINE','OFFLINE') | Must be 'OFFLINE' for offline upload |

### 5.2 Database Schema — `lms_exam_attempts` (Offline-related columns)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-06 | id | BIGINT PK | Auto-increment |
| BC-DB-07 | student_id | BIGINT FK | NOT NULL, FK → `sch_students.id` |
| BC-DB-08 | exam_paper_id | BIGINT FK | NOT NULL, FK → `lms_exam_papers.id` |
| BC-DB-09 | paper_set_id | BIGINT FK | NULL, FK → `lms_exam_paper_sets.id` |
| BC-DB-10 | status | ENUM | 'NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED' |
| BC-DB-11 | is_present_offline | TINYINT(1) | NULL; 1=Present, 0=Absent, NULL=Not Marked |
| BC-DB-12 | attempt_mode | VARCHAR | 'OFFLINE' for offline uploads |
| BC-DB-13 | is_evaluated | TINYINT(1) | DEFAULT 0; derived from upload marks |
| BC-DB-14 | offline_paper_uploaded_path | JSON | NULL; deprecated, moved to upload marks table |

### 5.3 Database Schema — `lms_offline_exam_upload_marks`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-15 | id | BIGINT PK | Auto-increment |
| BC-DB-16 | exam_attempt_id | BIGINT FK | NOT NULL, FK → `lms_exam_attempts.id`, UNIQUE |
| BC-DB-17 | marks_entry_mode | ENUM('BULK_TOTAL','QUESTION_WISE') | NOT NULL; how marks were entered |
| BC-DB-18 | is_ques_wise_file_upload | TINYINT(1) | DEFAULT 0 |
| BC-DB-19 | is_sheet_uploaded | TINYINT(1) | DEFAULT 0; whether PDF was uploaded |
| BC-DB-20 | total_marks_obtained | DECIMAL(8,2) | DEFAULT 0; bulk total marks |
| BC-DB-21 | max_paper_marks | DECIMAL(8,2) | NULL; paper total marks snapshot |
| BC-DB-22 | attachment_data | JSON | NULL; file metadata (file_name, file_path) |
| BC-DB-23 | is_evaluated | TINYINT(1) | DEFAULT 0 |
| BC-DB-24 | evaluated_by | BIGINT | NULL; FK → users.id |
| BC-DB-25 | evaluated_at | TIMESTAMP | NULL |
| BC-DB-26 | upload_remarks | TEXT | NULL |
| BC-DB-27 | uploaded_by | BIGINT | NULL; FK → users.id |
| BC-DB-28 | uploaded_at | TIMESTAMP | NULL |
| BC-DB-29 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-30 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-31 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 5.4 Database Schema — `lms_offline_exam_upload_detail`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-32 | id | BIGINT PK | Auto-increment |
| BC-DB-33 | offline_upload_mark_id | BIGINT FK | NOT NULL, FK → `lms_offline_exam_upload_marks.id`, ON DELETE CASCADE |
| BC-DB-34 | question_id | BIGINT FK | NOT NULL, FK → `qns_questions_bank.id` |
| BC-DB-35 | selected_option_id | BIGINT FK | NULL; FK → `qns_question_options.id` |
| BC-DB-36 | selected_option_ids | JSON | NULL; multiple options for MSQ |
| BC-DB-37 | marks_obtained_for_question | DECIMAL(8,2) | NULL |
| BC-DB-38 | is_answer_correct | TINYINT(1) | NULL |
| BC-DB-39 | attachment_data | JSON | NULL; file metadata for question-level PDF |
| BC-DB-40 | evaluation_remarks | TEXT | NULL |
| BC-DB-41 | is_active | TINYINT(1) | DEFAULT 1 |
| BC-DB-42 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-43 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |

### 5.5 Validation Rules

| BC ID | Field/Scope | Rule | Error Message |
|-------|-------------|------|---------------|
| BC-VAL-01 | answer_sheet | required, file, mimes:pdf, max:50MB | "The answer sheet must be a valid PDF file" |
| BC-VAL-02 | student_id (bulk) | required, integer, exists:sch_students,id | "Student not found" |
| BC-VAL-03 | exam_paper_id (bulk) | required, integer, exists:lms_exam_papers,id | "Paper not found" |
| BC-VAL-04 | answer_sheet not uploaded | Server returns 400 if file not valid | "No valid file uploaded." |
| BC-VAL-05 | question-wise FormData | attachment file accepts PDF/images | accept="application/pdf,image/*" |
| BC-VAL-06 | student_id (question-wise) | required via JS FormData | Sent automatically |
| BC-VAL-07 | exam_paper_id (question-wise) | required via JS FormData | Sent automatically |

### 5.6 Authorization

| BC ID | Permission | Effect |
|-------|------------|--------|
| BC-AUTH-01 | tenant.answer-sheet-offline-exam.view | Controls visibility of offline_upload tab in upload.blade.php |
| BC-AUTH-02 | tenant.offline-assessment.view | Controller gate in uploadOffline() method |

### 5.7 Business Logic

| BC ID | Rule | Description |
|-------|------|-------------|
| BC-BIZ-01 | Entry Mode Routing | onClick handler checks `offline_entry_mode`. If `QUESTION_WISE` OR `is_ques_wise_file_upload=1` → opens question-wise modal; else opens bulk upload modal |
| BC-BIZ-02 | Attendance Tracking | `is_present_offline` in exam_attempts tracks attendance. Independent of marks entry. Values: 1=Present, 0=Absent, NULL=Not Marked |
| BC-BIZ-03 | Bulk Upload Auto-Create Attempt | `bulkUploadMarks()` calls `ExamAttempt::firstOrCreate()`; if attempt exists with NOT_STARTED, status upgraded to SUBMITTED; once created, sets `is_present_offline=1` |
| BC-BIZ-04 | Marks Entry Mode Persistence | `OfflineExamUploadMark::firstOrCreate(['exam_attempt_id' => $attempt->id])` prevents duplicate mark records per attempt |
| BC-BIZ-05 | Question-Wise Attempt Reuse | Question-wise save uses existing attempt; upload mark record created/updated with `firstOrCreate` |
| BC-BIZ-06 | JSON File Metadata | `attachment_data` stored as JSON with file_name, file_path, mime_type, size |
| BC-BIZ-07 | Bulk Upload Evaluated Flag | If `marks_obtained` is sent with the request, `is_evaluated=1` and `evaluated_by` set |
| BC-BIZ-08 | Paper Set Dependency | Question-wise data requires `paper_set_id` on attempt; questions loaded via `PaperSetQuestion` ordered by `ordinal` |
| BC-BIZ-09 | No Attempt Required for Bulk | Bulk upload can proceed without existing attempt; attempt created on the fly |
| BC-BIZ-10 | Cascading Dropdowns | Class→Section→Subject→Exam→Paper→Set→Student; each change fetches next level |

### 5.8 Referential Integrity

| BC ID | Constraint | Description |
|-------|------------|-------------|
| BC-REF-01 | offline_upload_mark_id → lms_offline_exam_upload_marks.id | ON DELETE CASCADE cascades question-wise details |
| BC-REF-02 | exam_attempt_id → lms_exam_attempts.id | Upload mark linked to attempt |
| BC-REF-03 | student_id → sch_students.id | Required for bulk upload |
| BC-REF-04 | exam_paper_id → lms_exam_papers.id | Required for bulk upload |
| BC-REF-05 | paper_set_id → lms_exam_paper_sets.id | Required for question-wise data |
| BC-REF-06 | question_id → qns_questions_bank.id | Required for question-wise details |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-P01 | Load offline upload tab with no search | Navigate to `/lms-exam/upload?active_tab=offline_upload` | Table shows "Please search to view offline data." (colspan=8) |
| TC-P02 | Search with only Class filter | Select Class, click Search | Table populated with students allocated to any offline exam paper for that class |
| TC-P03 | Search with full filter chain | Select Class→Section→Subject→Exam→Paper→Set→Search | Students filtered by all criteria; correct exam/paper/set names displayed |
| TC-P04 | Student-specific search | Select Class→Section→Subject→Exam→Paper→Set→Student→Search | Single student row shown |
| TC-P05 | Present attendance badge | Student has is_present_offline=1 | Badge shows "Present" (bg-success) |
| TC-P06 | Absent attendance badge | Student has is_present_offline=0 | Badge shows "Absent" (bg-danger) |
| TC-P07 | Not Marked attendance badge | Student has is_present_offline=NULL | Badge shows "Not Marked" (bg-secondary) |
| TC-P08 | Checked badge Yes | Student has is_evaluated=1 | Badge shows "Yes" (bg-success) |
| TC-P09 | Checked badge No | Student has is_evaluated=0 | Badge shows "No" (bg-warning) |
| TC-P10 | Bulk upload modal — open | Click Upload for paper with offline_entry_mode=BULK_TOTAL | Bulk Upload Modal opens with student_id, paper_id, set_id hidden fields |
| TC-P11 | Bulk upload modal — upload PDF | Select valid PDF, click Save | File stored; success toast "Answer sheet uploaded successfully."; page reloads |
| TC-P12 | Bulk upload modal — previous attachment visible | Student already has offline_attachment_data | Attachment preview shows "View Uploaded Sheet" link with filename |
| TC-P13 | Question-wise modal — open (QUESTION_WISE mode) | Click Upload for paper with offline_entry_mode=QUESTION_WISE | Question-Wise Modal opens with all questions from paper set |
| TC-P14 | Question-wise modal — MCQ radio option | Select one radio for single-correct MCQ | Checked option persisted; other options deselected |
| TC-P15 | Question-wise modal — Multi-select checkbox | Select multiple checkboxes for MSQ question | Multiple options can be checked simultaneously |
| TC-P16 | Question-wise modal — Existing attachment | Row has previous file upload | "View" link shown for existing attachment |
| TC-P17 | Question-wise modal — upload descriptive file | Select valid PDF/image for descriptive question | File selected; ready to submit |
| TC-P18 | Question-wise save — all question types | Fill MCQ options + attach files for descriptive, click Save Assessment | Success toast "Assessment recorded successfully."; page reloads; is_evaluated=1 |
| TC-P19 | Question-wise modal — single-correct radio pre-selected | Question already has selected_option_id | Correct radio button pre-checked |
| TC-P20 | Question-wise modal — multi-checkbox pre-selected | Question already has selected_option_ids | Correct checkboxes pre-checked |
| TC-P21 | Pagination links | 20+ students load; click page 2 | Page 2 loads; `active_tab=offline_upload` preserved in URL |
| TC-P22 | View Set Questions | Select Paper Set, click "View Questions" button | Opens new tab with set questions viewer |
| TC-P23 | Bulk upload without marks_obtained | Upload PDF without entering marks | File saved; is_evaluated=0 |
| TC-P24 | Bulk upload with marks_obtained | Upload PDF with marks_obtained field | File saved; is_evaluated=1; evaluated_by set |
| TC-P25 | Cancel bulk upload modal | Click Cancel button in bulk modal | Modal closes; no data saved |
| TC-P26 | Cancel question-wise modal | Click Cancel in question-wise modal | Modal closes; no data saved |
| TC-P27 | reset button | Click refresh icon after filtering | Filters reset; URL cleared to current page |
| TC-P28 | Select2 student dropdown | Open student dropdown for searchable list | Select2 with "All Students" placeholder; search works |
| TC-P29 | Attempt detail link | Student with existing attempt_id | Eye icon link visible; clicking opens attempt detail in new tab |
| TC-P30 | Cascading dropdown — class change triggers exams | Select a class | Exams dropdown loads with filtered data |
| TC-P31 | Cascading dropdown — class change triggers sections | Select a class | Sections dropdown loads with filtered data |
| TC-P32 | Cascading dropdown — class change triggers subjects | Select a class | Subjects dropdown loads with filtered data |
| TC-P33 | Cascading dropdown — class change triggers students | Select a class | Student dropdown loads with filtered data |
| TC-P34 | Cascading dropdown — section change filters subjects | Select a section | Subjects re-fetched with class_id + section_id |
| TC-P35 | Cascading dropdown — exam change filters papers | Select an exam | Papers dropdown loads with filtered data |
| TC-P36 | Cascading dropdown — paper change filters sets | Select a paper | Paper sets dropdown loads |
| TC-P37 | Question-wise modal — Swal loading indicator | Click Upload for QUESTION_WISE paper | Swal shows "Fetching Question Data..." with loading spinner |
| TC-P38 | Question-wise save — AJAX loading state | Click Save Assessment | Button disabled shows spinner; re-enabled after complete |
| TC-P39 | Bulk upload — AJAX loading state | Click Save | Button disabled shows "Saving..." spinner; re-enabled after complete |
| TC-P40 | Same student re-upload (bulk) | Upload PDF for same student twice | Second upload replaces first; single OfflineExamUploadMark record updated |
| TC-P41 | Bulk upload creates attempt | Non-existent attempt for student+paper | Attempt created with status=SUBMITTED, is_present_offline=1, attempt_mode=OFFLINE |
| TC-P42 | Bulk upload updates NOT_STARTED attempt | Attempt exists with status=NOT_STARTED | Status changed to SUBMITTED |
| TC-P43 | Question-wise marks with multiple question types | Paper has MCQ, MSQ, Short Answer, Long Answer | All types rendered correctly: radio for single, checkbox for multi, file input for descriptive |
| TC-P44 | is_ques_wise_file_upload=1 with BULK_TOTAL paper | Paper has offline_entry_mode=BULK_TOTAL, is_ques_wise_file_upload=1 | Question-wise modal opens (not bulk) |
| TC-P45 | Search with empty result | Select filters that match no students | "No students found for the selected criteria." with colspan=8 |

### 6.2 Negative Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-N01 | Submit bulk upload without file | Open bulk modal, click Save without selecting file | Error "No valid file uploaded." |
| TC-N02 | Submit bulk upload with invalid file type | Select .txt file, click Save | Server validation fails; error returned |
| TC-N03 | Submit bulk upload with oversized file | Select >50MB file, click Save | Browser/client-side validation blocks; or server returns error |
| TC-N04 | Submit bulk upload with non-existent student_id | Modify hidden field student_id to invalid value, click Save | Error "Student not found" |
| TC-N05 | Submit bulk upload with non-existent paper_id | Modify hidden field exam_paper_id to invalid value, click Save | Error "Paper not found" |
| TC-N06 | Question-wise save with no changes | Open modal, click Save Assessment without any changes | Success toast; no errors |
| TC-N07 | AJAX fail — question-wise data fetch | Disconnect network, click Upload for QUESTION_WISE paper | Swal error "Failed to fetch question data. Please try again." |
| TC-N08 | AJAX fail — bulk upload | Disconnect network, click Save | Swal error "Server communication error" |
| TC-N09 | Direct URL access without permission | Remove permission `tenant.answer-sheet-offline-exam.view`, access upload URL | Tab not rendered; or 403 |
| TC-N10 | No Class selected for cascading | Click Section dropdown without selecting class | Empty/disabled dropdown |
| TC-N11 | Missing subject_id validation | Form submit without subject | Depends on server-side: if subject required, validation error |
| TC-N12 | Paper set with no questions selected | Open question-wise modal for set with 0 questions | Empty table body; save does nothing |
| TC-N13 | Guest access to upload URL | Logout, access `/lms-exam/upload` | Redirected to /login |
| TC-N14 | Double-click Save (bulk) | Click Save twice rapidly | Second request handled gracefully; no duplicate records |
| TC-N15 | Double-click Save (question-wise) | Click Save Assessment twice rapidly | Second request handled gracefully; no duplicate detail records |
| TC-N16 | Invalid exam_set_id in question-wise | Modify hidden field exam_set_id to 99999 | Possibly no questions returned; empty modal |
| TC-N17 | File upload with same name twice | Upload file "sheet.pdf", then upload different "sheet.pdf" | Second upload overwrites; file_path updated |
| TC-N18 | AJAX error during cascading | Disconnect network, change class dropdown | Dependent dropdowns show failures; student select falls back to "All Students" |
| TC-N19 | Empty student select after class change | Class with no students | "All Students" shown; no student options |
| TC-N20 | Modify mode parameter in question-wise request | Send mode=INVALID instead of OFFLINE | Server handles gracefully; possibly returns error |

### 6.3 Dependency / Integration Test Cases

| TC ID | Scenario | Steps | Expected Result |
|-------|----------|-------|-----------------|
| TC-D01 | Upload tab — online_upload and offline_upload co-exist | Navigate to upload tab | Both tabs visible | 
| TC-D02 | offline_upload tab — switch from online_upload | Switch tabs from online to offline | offline_upload pane active; online upload pane hidden |
| TC-D03 | offline_upload tab — switch back | Switch from offline to online | online_upload pane active; offline hidden |
| TC-D04 | Assessment tab — check status after bulk upload | Bulk upload for student, navigate to assessment tab | Student shows as Checked in assessment offline summary |
| TC-D05 | Bulk create attempt → attempt detail | Upload file; attempt_id returned; navigate to attempt detail | Detail page shows offline attempt info |
| TC-D06 | Multiple students — bulk upload all | Upload PDF for 3 students consecutively | 3 OfflineExamUploadMark records created (one per attempt) |
| TC-D07 | Question-wise marks → student result | Save MCQ options for student; check result | Marks recorded; student result reflects offline marks |
| TC-D08 | Storage path structure | Upload file; check path | File stored in `{session_code}/{class_id}/{exam_paper_id}/{student_id}/{attempt_id}/uploader/` |
| TC-D09 | Cache — class section list dependency | Change class_section data; reload upload | List may be stale until cache (3600s) expires |
| TC-D10 | Offline exam paper with is_ques_wise_file_upload=1 | Create paper with BULK_TOTAL + is_ques_wise=1 | Upload button triggers question-wise modal |
| TC-D11 | Offline exam paper with QUESTION_WISE + is_ques_wise=0 | Create paper with QUESTION_WISE + is_ques_wise=0 | Upload button triggers question-wise modal (mode check takes precedence) |
| TC-D12 | Student not allocated to paper | Search for student allocated to different paper | Student not shown in results |
| TC-D13 | Paper set with mixed MCQ, MSQ, Descriptive | Create set with all three types | Modal renders radio, checkbox, file input respectively |
| TC-D14 | Tenant isolation — upload in Tenant A | Upload file in Tenant A | File stored in Tenant A's storage path; Tenant B cannot access |
| TC-D15 | Attempt status progression | Bulk upload creates attempt → marks entered → is_evaluated=1 | Attempt status remains SUBMITTED; evaluation tracked in marks table |
| TC-D16 | Question-wise save with marks_obtained null | Save question without awarding marks | marks_obtained_for_question = null in DB |
| TC-D17 | Bulk upload without marks — evaluate later | Upload file without marks_obtained, then separately update marks | Two-step process: first upload, then evaluate |
| TC-D18 | File preview link after bulk upload | Upload file; click "View Uploaded Sheet" link | File opens in new tab; valid PDF displayed |
| TC-D19 | Student name with special chars in modal | Student name: O'Brien & "Smith" | addslashes escapes; modal shows correct name |
| TC-D20 | Student group isolation | Student in Group A; search with Group B filter | Student not shown |
| TC-D21 | Empty class list | No active classes | "All Classes" dropdown empty |
| TC-D22 | Exam select — no exams for class | Class has no exams | "-- Select Exam --" shown |
| TC-D23 | Paper select — no papers for exam | Exam has no papers | "-- Select Paper --" shown |
| TC-D24 | Paper set select — no sets for paper | Paper has no sets | "-- No Paper Sets Available --" shown |
| TC-D25 | Multiple SELECT2 instances | Page has both online and offline select2 | Both initialized correctly |
| TC-D26 | Pagination with filters | Apply filters, navigate to page 2 | Filters preserved; query string has class_id, section_id, etc. |
| TC-D27 | Filters reset on nav-away | Navigate to different tab; return to upload | Tab state may reset (unless URL persists) |
| TC-D28 | Different mode papers in same set | Paper with BULK_TOTAL and QUESTION_WISE in same set | Each student's upload button routes to correct modal based on their paper's mode |

### 6.4 Code Review / Static Analysis

| TC ID | Scenario | Expected Observation |
|-------|----------|----------------------|
| TC-CR01 | Permission checks | `uploadOffline()`: `Gate::authorize('tenant.offline-assessment.view')` before returning view |
| TC-CR02 | View permission in blade | `@can('tenant.answer-sheet-offline-exam.view')` wraps `@include('lmsexam::tab_module.partials.offline_upload')` |
| TC-CR03 | Tab rendering | Nav tabs include `offline_upload` with label "Answer Sheet Upload (Offline Exam)" and icon `fa-solid fa-file-pdf` |
| TC-CR04 | JS — handleUploadClick routing | Compares mode to `'QUESTION_WISE'`, `'1'`, `1`, `true`, `'true'` — covers multiple truthy types |
| TC-CR05 | JS — escapeHtml function | Used for question_text, type, file_name in question-wise modal; protects against XSS |
| TC-CR06 | JS — addslashes in onclick | `addslashes($student->student_name)` used in onclick handler for student name |
| TC-CR07 | JS — Swal loading on question-wise fetch | `didOpen: () => Swal.showLoading()` shows loading state; `Swal.close()` called in success |
| TC-CR08 | JS — Swal error on AJAX fail | `.fail()` handler calls `Swal.fire('Error', ...)` and `console.error` |
| TC-CR09 | JS — FormData construction for question-wise | `.qw-single-opt:checked` and `.qw-multi-opt:checked` collected separately; files appended with `attachments[qid]` |
| TC-CR10 | JS — form reset on bulk modal open | `$('#bulkUploadForm')[0].reset()` called in `proceedToBulk()` |
| TC-CR11 | JS — select2 initialization | `if ($.fn.select2)` guard; `width: '100%'`, `placeholder: "All Students"`, `allowClear: true` |
| TC-CR12 | JS — cascading AJAX error handling | `.fail()` on student AJAX resets to `<option value="">All Students</option>` |
| TC-CR13 | JS — cascading loading states | All dependent dropdowns show "Loading..." during AJAX |
| TC-CR14 | Controller — uploadOffline() method | Returns view directly; no complex logic |
| TC-CR15 | Controller — bulkUploadMarks() | Uses DB::beginTransaction/commit/rollback; error logged |
| TC-CR16 | Controller — bulkUploadMarks() findsOrFail | Uses `Student::findOrFail()` and `ExamPaper::findOrFail()` — throws ModelNotFoundException |
| TC-CR17 | Controller — attempt firstOrCreate | `ExamAttempt::firstOrCreate()` with `student_id` + `exam_paper_id` as unique keys |
| TC-CR18 | Controller — offline mark firstOrCreate | `OfflineExamUploadMark::firstOrCreate(['exam_attempt_id' => $attempt->id])` — one mark per attempt |
| TC-CR19 | Controller — dynamic path building | `storageService->buildPath('lms_exam_upload_path', $pathParams)` with session, class, paper, student, attempt, uploader |
| TC-CR20 | Controller — getQuestionWiseDataOffline | Loads `PaperSetQuestion` with question, questionType, options; maps to response array |
| TC-CR21 | Controller — saveQuestionWiseMarksOffline | Uses `firstOrCreate` for upload mark; handles single option_id and array option_ids |
| TC-CR22 | CSS — modal custom styles | `#questionWiseModal` has gradient header; `#bulkUploadModal` has bg-success header |
| TC-CR23 | CSS — option label styling | Radio/checkbox options hidden; styled circle labels with checked state |
| TC-CR24 | View — hidden inputs for tab state | `<input type="hidden" name="active_tab" value="offline_upload">` and `name="tab" value="offline_upload"` |
| TC-CR25 | View — colspan=8 on empty/no data messages | Both "Please search to view offline data." and "No students found" have colspan=8 |
| TC-CR26 | View — pagination conditional | Pagination only shown when `method_exists($studentsData, 'links')` AND `active_tab === 'offline_upload'` |
| TC-CR27 | View — attempt detail link | Only shown when `$student->attempt_id` is set |
| TC-CR28 | View — attachment data JSON in data attribute | `data-attachment="{{ json_encode($student->offline_attachment_data) }}"` — JSON passed safely |
| TC-CR29 | JS — storageBase construction | Checks `function_exists('tenant_asset')` for multi-tenant support |
| TC-CR30 | Controller — bulkUploadMarks file handling | Checks `$file && $file->isValid()`; returns 400 if invalid |
| TC-CR31 | CR | Code Review | P1 | Controller — bulkUploadAnnotatedPdf Mutates Global Config | Line 2639: `config(['media-library.max_file_size' => ...])` changes global config per-request; may affect concurrent requests | — | — | ◌ |
| TC-CR32 | CR | Code Review | P1 | Controller — bulkUploadAnnotatedPdf Exposes Exception Message | Catch block returns 'Upload failed: ' . $e->getMessage(); internal error details exposed to client | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Load offline upload tab with no search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/upload` | Page loads with upload tabs |
| 2 | Click "Answer Sheet Upload (Offline Exam)" tab | Tab activates; URL updates with `?active_tab=offline_upload` |
| 3 | Observe table body | Single row with colspan=8 showing "Please search to view offline data." |

#### TC-P02: Search with only Class filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class from dropdown (e.g., "Class 10") | All other dropdowns load via cascading AJAX |
| 2 | Leave all other filters empty (default) | Section/Subject/Exam/Paper/Set show placeholder options |
| 3 | Click Search (magnifying glass button) | Form submits via GET with `active_tab=offline_upload&class_id=X` |
| 4 | Verify table data | Students allocated to any offline exam for Class X shown |
| 5 | Verify columns | Admn No, Student Name, Exam, Paper, Paper Set, Attendance, Checked, Action |

#### TC-P03: Search with full filter chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class → Section → Subject → Exam → Paper → Set | Each cascading call loads next level correctly |
| 2 | Click Search | Form submits with all filter params |
| 3 | Verify each row shows correct Exam, Paper, Paper Set names | Matches selected filters |
| 4 | Verify Action column | Upload button visible for each student |

#### TC-P04: Student-specific search

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class → Section → Subject → Exam → Paper → Set | Normal cascade |
| 2 | Open Student dropdown (Select2) | Searchable list shows students |
| 3 | Select specific student | Dropdown shows selected student |
| 4 | Click Search | Only that student's row appears |

#### TC-P05: Present attendance badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attempt with is_present_offline=1 | Student allocated to offline paper |
| 2 | Search for that student | Badge shows "Present" with bg-success |

#### TC-P06: Absent attendance badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create attempt with is_present_offline=0 | Student allocated |
| 2 | Search | Badge shows "Absent" with bg-danger |

#### TC-P07: Not Marked attendance badge

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No attempt exists or is_present_offline=NULL | Student in allocation |
| 2 | Search | Badge shows "Not Marked" with bg-secondary |

#### TC-P08: Checked badge Yes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | OfflineExamUploadMark exists with is_evaluated=1 | Checked badge shows "Yes" (bg-success) |

#### TC-P09: Checked badge No

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No upload mark or is_evaluated=0 | Checked badge shows "No" (bg-warning) |

#### TC-P10: Bulk upload modal — open for BULK_TOTAL paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select paper with offline_entry_mode=BULK_TOTAL | Paper selected |
| 2 | Click Upload button for a student | handleUploadClick fires with mode='0' |
| 3 | Verify modal | Bulk Upload Modal opens; header "Upload Answer Sheet" with bg-success |
| 4 | Verify hidden fields | student_id, exam_paper_id, exam_set_id populated |
| 5 | Verify file input | "Upload New Sheet (PDF)" label; accepts application/pdf |

#### TC-P11: Bulk upload modal — upload valid PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open bulk modal for student | Modal visible |
| 2 | Select a valid PDF file | File input shows filename |
| 3 | Click Save | AJAX POST to lms-exam.marks.bulk-upload |
| 4 | Wait for response | Button shows spinner "Saving..." |
| 5 | Verify success | Swal "Success!" → "Marks uploaded successfully!" |
| 6 | Verify page reload | Page reloads after 1500ms |

#### TC-P12: Bulk upload modal — previous attachment visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student already has attachment_data JSON | Data stored in offline_attachment_data |
| 2 | Open bulk modal | Attachment preview div visible (not d-none) |
| 3 | Verify preview | Filename shown; "View Uploaded Sheet" link with URL |
| 4 | Click "View Uploaded Sheet" | File opens in new tab |

#### TC-P13: Question-wise modal — open (QUESTION_WISE mode)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select paper with offline_entry_mode=QUESTION_WISE | Paper selected |
| 2 | Click Upload for a student | handleUploadClick fires with mode='1' |
| 3 | Verify loading | Swal shows "Fetching Question Data..." |
| 4 | Verify modal opens | Question-Wise Modal with gradient header; table with # Qn, Question Details, Response/Evidence |
| 5 | Verify student name | "Offline Assessment" subtitle shows student name |

#### TC-P14: Question-wise — MCQ single radio selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question-wise modal for set with MCQ | MCQ row shows radio circle labels A/B/C/D |
| 2 | Click option A (radio) | Option A selected; styled with green border/shadow |
| 3 | Click option B | Option B selected; A deselected |

#### TC-P15: Question-wise — Multi-select checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open modal with MSQ (multi-correct) question | Options show checkbox inputs |
| 2 | Click options A and C | Both selected simultaneously |
| 3 | Click A again | A deselected; C remains |

#### TC-P16: Question-wise — Existing attachment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Question has previous attachment_data | File preview card shows with PDF icon, filename, "View" button |
| 2 | Click "View" button | File URL opens in new tab |

#### TC-P17: Question-wise — upload descriptive file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open modal with descriptive question | File input shown with accept="application/pdf,image/*" |
| 2 | Select valid PDF/image | File input shows selected filename |
| 3 | Verify input shows file | Ready to submit |

#### TC-P18: Question-wise save — all types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select radio for MCQ Question 1 | Option selected |
| 2 | Select checkboxes for MSQ Question 2 | Options A, C checked |
| 3 | Attach PDF for descriptive Question 3 | File selected |
| 4 | Click "Save Assessment" | FormData constructed with options and attachments |
| 5 | Wait for AJAX response | Swal "Saving Assessment..." |
| 6 | Verify success | Swal "Saved!" → "Assessment recorded successfully." |
| 7 | Modal closes; page reloads | location.reload() called |

#### TC-P19: Question-wise — single-correct radio pre-selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload marks with option A selected | selected_option_id stored |
| 2 | Re-open question-wise modal | Radio A pre-checked with green styling |

#### TC-P20: Question-wise — multi-checkbox pre-selected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload marks with options A, C selected | selected_option_ids = ["1","3"] |
| 2 | Re-open modal | Checkboxes A and C pre-checked |

#### TC-P21: Pagination links

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Allocate 20+ students to paper | 3+ pages of data |
| 2 | Search | Page 1 shows 10 students |
| 3 | Click page 2 link | URL has `?active_tab=offline_upload&page=2`; next 10 students shown |

#### TC-P22: View Set Questions button

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Paper Set | Set selected |
| 2 | Click "View Questions" (info button with fa-file-lines) | New tab opens with paper set question viewer |
| 3 | Verify questions shown | All questions for that set displayed |

#### TC-P23: Bulk upload without marks_obtained

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload valid PDF | File saved |
| 2 | Check OfflineExamUploadMark | is_evaluated=0; is_sheet_uploaded=1; total_marks_obtained=0 |

#### TC-P24: Bulk upload with marks_obtained

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload PDF with marks_obtained=17.5 | File saved |
| 2 | Check OfflineExamUploadMark | is_evaluated=1; total_marks_obtained=17.50; evaluated_by set; evaluated_at set |

#### TC-P25: Cancel bulk modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open bulk modal | Modal visible |
| 2 | Click Cancel button | Modal closes; no AJAX call made |

#### TC-P26: Cancel question-wise modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question-wise modal | Modal visible; questions loaded |
| 2 | Click Cancel button | Modal closes; no data saved |

#### TC-P27: Reset button (refresh icon)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select filters and search | URL has query params |
| 2 | Click refresh (rotate-right) button | URL resets to `/lms-exam/upload`; filters cleared |

#### TC-P28: Select2 student dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open student dropdown | Select2 shows with search box |
| 2 | Type student name | Filtered results shown |
| 3 | Clear selection | "All Students" placeholder shown |

#### TC-P29: Attempt detail link

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student with attempt_id | Eye icon button (btn-outline-primary) visible |
| 2 | Click eye icon | New tab opens with route lms-exam.exam.attemptDetail |

#### TC-P30: Cascading — class change loads exams

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Exams dropdown shows "Loading..." then populated |
| 2 | Verify exams are for offline mode | Only offline exams shown |

#### TC-P31: Cascading — class change loads sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Sections dropdown loads via `getSections()` route |
| 2 | Verify sections shown | Section names populated |

#### TC-P32: Cascading — class change loads subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Subjects dropdown loads via `get-subjects-by-class-section` |
| 2 | Verify subjects shown | Subject names populated |

#### TC-P33: Cascading — class change loads students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Class | Student dropdown loads via `students` route |
| 2 | Verify students shown | Students in that class populated |

#### TC-P34: Cascading — section change filters subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class, then Select Section | Subjects re-fetched with class_id + section_id |
| 2 | Verify subject list updates | Subjects filtered by both class and section |

#### TC-P35: Cascading — exam change loads papers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select an Exam | Papers dropdown shows "Loading..." then populated |
| 2 | Verify papers for offline mode | Only offline papers shown |

#### TC-P36: Cascading — paper change loads sets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a Paper | Paper sets dropdown shows "Loading..." then populated |
| 2 | Verify sets shown | Set names populated |

#### TC-P37: Question-wise — Swal loading indicator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Upload for QUESTION_WISE paper | Swal fires with "Fetching Question Data..." and spinner |
| 2 | Wait for AJAX complete | Swal closes; modal opens |

#### TC-P38: Question-wise — Save button loading state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Save Assessment | Swal shows "Saving Assessment..." |
| 2 | Observe Save button | Button state remains; Swal overlay prevents interaction |

#### TC-P39: Bulk upload — Save button loading state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Save in bulk modal | Button disabled; text changes to `<i class="fa-solid fa-spinner fa-spin"></i> Saving...` |
| 2 | Wait for response | Button re-enabled with original text |

#### TC-P40: Same student re-upload (bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload file "first.pdf" | Saved with file_path for first.pdf |
| 2 | Upload file "second.pdf" for same student | OfflineUploadMark updated; attachment_data now references second.pdf |

#### TC-P41: Bulk upload creates attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has no attempt for paper | ExamAttempt record missing |
| 2 | Upload bulk PDF | ExamAttempt::firstOrCreate runs; attempt created with status=SUBMITTED, is_present_offline=1 |

#### TC-P42: Bulk upload updates NOT_STARTED attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has NOT_STARTED attempt | Status is NOT_STARTED |
| 2 | Upload bulk PDF | Attempt status changed to SUBMITTED |

#### TC-P43: Question-wise mixed question types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper set has MCQ, MSQ, Short Answer, Long Answer | Modal renders 4 rows |
| 2 | Verify MCQ row | Radio buttons (single) with A/B/C/D |
| 3 | Verify MSQ row | Checkboxes (multi) with A/B/C/D |
| 4 | Verify Short Answer row | File input |
| 5 | Verify Long Answer row | File input |

#### TC-P44: is_ques_wise_file_upload=1 forces question-wise

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper: offline_entry_mode=BULK_TOTAL, is_ques_wise_file_upload=1 | Paper selected |
| 2 | Click Upload | handleUploadClick receives mode='1' — opens question-wise modal |

#### TC-P45: Empty search results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class with no allocated students | No matches |
| 2 | Click Search | Table shows "No students found for the selected criteria." with colspan=8 |

### 7.2 Negative TC Steps

#### TC-N01: Bulk upload without file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open bulk modal | Modal shows file input |
| 2 | Click Save without selecting file | Server returns 400; "No valid file uploaded." |

#### TC-N02: Bulk upload with invalid file type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open bulk modal | File input visible |
| 2 | Select a .txt file | File input may reject (accept=application/pdf) |
| 3 | Click Save | If client bypassed, server returns error |

#### TC-N03: Bulk upload with oversized file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select >50MB file | Browser/client may block; or server returns error |
| 2 | Check response | Error message about file size |

#### TC-N04: Bulk upload with invalid student_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser dev tools | Modify hidden input #bulk_student_id to 99999 |
| 2 | Click Save | Server throws ModelNotFoundException or returns error "Student not found" |

#### TC-N05: Bulk upload with invalid paper_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Modify hidden input #bulk_paper_id to 99999 | Paper not found |
| 2 | Click Save | Error "Paper not found" |

#### TC-N06: Question-wise save with no changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open question-wise modal | Questions loaded |
| 2 | Click Save Assessment without making changes | Success toast; no data changed |

#### TC-N07: AJAX fail — question-wise data fetch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Disconnect network connection | Offline |
| 2 | Click Upload for QUESTION_WISE paper | Swal shows "Fetching Question Data..." |
| 3 | AJAX fails | Swal closes; error "Failed to fetch question data. Please try again." logged to console |

#### TC-N08: AJAX fail — bulk upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select file; disconnect network | Offline |
| 2 | Click Save | AJAX fails |
| 3 | Error Swal shown | "Server communication error" |

#### TC-N09: Direct URL without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Remove permission from role | User loses access |
| 2 | Refresh upload page | Offline tab not rendered; or 403 if gate fails |

#### TC-N10: No class selected — cascading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave "All Classes" selected | All dropdowns show placeholders |
| 2 | Try to select Section | Sections set to "-- Select Section --" |

#### TC-N11: Missing subject_id validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave subject_id empty (required field) | Subject dropdown has `required` attribute |
| 2 | Submit form | Browser validation blocks; or server returns error |

#### TC-N12: Paper set with no questions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select set with 0 PaperSetQuestion records | Open question-wise modal |
| 2 | Verify table body | Empty; "Save Assessment" does nothing meaningful |

#### TC-N13: Guest access redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout from application | Session cleared |
| 2 | Access `/lms-exam/upload` | Redirected to /login |

#### TC-N14: Double-click Save (bulk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select file; click Save twice rapidly | First request processes; button disabled during save (spinner) |
| 2 | Verify no duplicate | OfflineExamUploadMark::firstOrCreate prevents duplicate |

#### TC-N15: Double-click Save (question-wise)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Make selections; click Save Assessment twice | First request processes; Swal overlay prevents second |
| 2 | Verify no duplicates | firstOrCreate on upload mark prevents duplicates |

#### TC-N16: Invalid exam_set_id in question-wise

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Modify hidden field or data attribute | exam_set_id=99999 |
| 2 | Open question-wise modal | No questions found; empty modal or error |

#### TC-N17: File upload with same name twice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload "sheet.pdf" | Saved with file_path |
| 2 | Upload different "sheet.pdf" | Overwritten; file_path updated |

#### TC-N18: AJAX error during cascading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Disconnect network | Offline |
| 2 | Change class dropdown | Dependent dropdowns stuck on "Loading..." |
| 3 | Reconnect; change class again | Cascading works; dropdowns populate |

#### TC-N19: Empty student select

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Class with no students | Student dropdown shows "All Students" only |

#### TC-N20: Invalid mode parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send request with mode=INVALID | Server may return empty data or error; no crash |

### 7.3 Dependency TC Steps

#### TC-D01: Both tabs visible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/lms-exam/upload` | Two tabs: "Descriptive Ques (Online Exam)" and "Answer Sheet Upload (Offline Exam)" |

#### TC-D02: Switch to offline_upload from online

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click online_upload tab | Online pane active |
| 2 | Click offline_upload tab | offline_upload-pane active; online_upload-pane hidden |

#### TC-D03: Switch back

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click offline_upload tab | Offline visible |
| 2 | Click online_upload tab | Online visible; offline hidden |

#### TC-D04: Assessment tab reflects bulk upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Bulk upload for student | is_evaluated set |
| 2 | Navigate to Assessment tab → offline summary | Student paper shows in checked count |

#### TC-D05: Attempt detail after bulk create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Bulk upload creates new attempt | attempt_id returned |
| 2 | Navigate to attempt detail URL | Detail page shows attempt info |

#### TC-D06: Multiple students bulk upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload for Student 1 | Success |
| 2 | Upload for Student 2 | Success |
| 3 | Upload for Student 3 | Success |
| 4 | Check DB | 3 OfflineExamUploadMark records (one per attempt) |

#### TC-D07: Question-wise marks → result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save MCQ selection for student | Marks recorded in OfflineExamUploadDetail |
| 2 | Navigate to student result | Offline marks reflected in total |

#### TC-D08: Storage path structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload file | File stored in `{session_code}/{class_id}/{exam_paper_id}/{student_id}/{attempt_id}/uploader/` |

#### TC-D09: Cache — class section list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Modify class_section data | Cache may not reflect until 3600s expiry |
| 2 | Reload upload page | List may be stale |

#### TC-D10: is_ques_wise_file_upload=1 triggers question-wise

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper: BULK_TOTAL + is_ques_wise=1 | Upload click triggers question-wise modal |

#### TC-D11: QUESTION_WISE mode always question-wise

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper: QUESTION_WISE + is_ques_wise=0 | Upload click triggers question-wise modal |

#### TC-D12: Student not allocated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for non-allocated student | Empty results |

#### TC-D13: Mixed question types rendered

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set has MCQ, MSQ, Descriptive | MCQ → radio; MSQ → checkbox; Descriptive → file |

#### TC-D14: Tenant isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload in Tenant A | File in A's path |
| 2 | Check Tenant B | B cannot access A's file |

#### TC-D15: Attempt status progression

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No attempt → bulk upload | Attempt created; status=SUBMITTED |
| 2 | Upload marks for existing attempt | Status stays SUBMITTED |

#### TC-D16: Question-wise marks null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Save question-wise without awarding marks | marks_obtained_for_question=NULL |

#### TC-D17: Bulk upload then evaluate later

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload PDF without marks | is_evaluated=0 |
| 2 | Update marks separately | is_evaluated updated |

#### TC-D18: File preview after bulk upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload PDF | File saved |
| 2 | Re-open bulk modal | "View Uploaded Sheet" link visible |
| 3 | Click link | PDF opens in new tab |

#### TC-D19: Special characters in student name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student name: O'Brien & "Smith" Co. | addslashes escapes quotes |
| 2 | Open question-wise modal | Name displays correctly in header |

#### TC-D20: Student group isolation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student in Group A only | Filter by Group A → student shown |
| 2 | Filter by Group B → student not shown | Group isolation works |

#### TC-D21: Empty class list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Delete all active classes | "All Classes" dropdown has no options |

#### TC-D22: No exams for class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select class with no exams | Exam dropdown shows "-- Select Exam --" |

#### TC-D23: No papers for exam

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select exam with no papers | Paper dropdown shows "-- Select Paper --" |

#### TC-D24: No sets for paper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select paper with no sets | Set dropdown shows "-- No Paper Sets Available --" |

#### TC-D25: Multiple Select2 instances

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to upload tab | Both online and offline Select2 initialized |
| 2 | Switch tabs; test both | Both Select2 instances functional |

#### TC-D26: Pagination with filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply class_id=5, exam_id=10 filters | URL has query params |
| 2 | Click page 2 | URL has `?class_id=5&exam_id=10&active_tab=offline_upload&page=2` |

#### TC-D27: Tab state on navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set filters in offline_upload | URL has params |
| 2 | Navigate to another tab | Tab switches |
| 3 | Return to upload tab | Depends on URL persistence |

#### TC-D28: Different mode papers same set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Paper A: BULK_TOTAL; Paper B: QUESTION_WISE | Different papers in same set |
| 2 | Upload for Paper A student | Bulk modal opens |
| 3 | Upload for Paper B student | Question-wise modal opens |

### 7.4 Code Review TC Steps

#### TC-CR01: Permission checks in controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect uploadOffline() | Gate::authorize('tenant.offline-assessment.view') present |
| 2 | Inspect upload() parent method | No direct gate; permissions on individual tab partials via @can |

#### TC-CR02: View permission in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect upload.blade.php | `@can('tenant.answer-sheet-offline-exam.view')` wraps offline partial include |
| 2 | Verify @can/@endcan block | Properly closed |

#### TC-CR03: Tab rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect nav-tab component | Tab id='offline_upload', label='Answer Sheet Upload (Offline Exam)', icon='fa-solid fa-file-pdf' |

#### TC-CR04: JS handleUploadClick routing logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect handleUploadClick() | Checks `mode === 'QUESTION_WISE' || mode === '1' || mode === 1 || mode === true || mode === 'true'` |
| 2 | Truthy match → call proceedToQuestionWise() | Question-wise modal route |
| 3 | Falsy match → call proceedToBulk() | Bulk upload modal route |

#### TC-CR05: JS escapeHtml function

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect escapeHtml() | Replaces &, <, >, ", ' with HTML entities |
| 2 | Verify usage in question-wise rendering | Used for question_text, type, file_name |

#### TC-CR06: JS addslashes in onclick

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect blade onclick handler | `addslashes($student->student_name)` used |
| 2 | Verify PHP addslashes | Backslash-escapes single quotes, double quotes |

#### TC-CR07: JS Swal loading on question-wise fetch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect proceedToQuestionWise() | Swal.fire with title='Fetching Question Data...', didOpen: Swal.showLoading |
| 2 | Verify Swal.close() in success callback | Proper cleanup |

#### TC-CR08: JS Swal error on AJAX fail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect .fail() handler | Swal.close() then Swal.fire('Error', 'Failed to fetch...', 'error') |
| 2 | Verify console.error | Debug logging for status and error |

#### TC-CR09: JS FormData for question-wise

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect saveQuestionWise() | Collects .qw-single-opt:checked and .qw-multi-opt:checked separately |
| 2 | Verify attachment handling | .qw-file each loop appends files with key `attachments[qid]` |

#### TC-CR10: JS form reset on bulk open

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect proceedToBulk() | `$('#bulkUploadForm')[0].reset()` called |

#### TC-CR11: JS select2 initialization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect $(document).ready | `if ($.fn.select2)` guard used |
| 2 | Verify options | width='100%', placeholder="All Students", allowClear: true |

#### TC-CR12: JS cascading AJAX error fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect .fail() on student AJAX | Resets to `<option value="">All Students</option>` |
| 2 | Verify other cascading fail handlers | Not all have fail handlers; may show "Loading..." indefinitely |

#### TC-CR13: JS cascading loading states

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect class change handler | All dependent dropdowns reset to "Loading..." |
| 2 | Verify empty class clears all | Section/subject/exam reset to empty values |

#### TC-CR14: Controller uploadOffline()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect uploadOffline() | Single line: returns view('lmsexam::upload.offline') |
| 2 | Verify gate | authorize('tenant.offline-assessment.view') called first |

#### TC-CR15: Controller bulkUploadMarks()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulkUploadMarks() | DB::beginTransaction at start; DB::commit on success; DB::rollBack in catch |
| 2 | Verify error logging | Log::error with message and trace |

#### TC-CR16: Controller findOrFail usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulkUploadMarks() | Student::findOrFail(), ExamPaper::findOrFail() |
| 2 | Verify exception handling | ModelNotFoundException caught by generic catch |

#### TC-CR17: Controller attempt firstOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulkUploadMarks() | firstOrCreate on ['student_id','exam_paper_id'] |
| 2 | Verify created values | attempt_mode='OFFLINE', status='SUBMITTED', is_present_offline=1 |

#### TC-CR18: Controller offline mark firstOrCreate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect bulkUploadMarks() | OfflineExamUploadMark::firstOrCreate(['exam_attempt_id' => $attempt->id]) |
| 2 | Verify default values | marks_entry_mode='BULK_TOTAL', is_evaluated=0, total_marks_obtained=0 |

#### TC-CR19: Controller dynamic path building

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect pathParams array | session_code, class_id, exam_paper_id, student_id, attempt_id, uploader='teacher' |
| 2 | Verify storageService->buildPath | Uses config key 'lms_exam_upload_path' |

#### TC-CR20: Controller getQuestionWiseDataOffline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect method | Loads PaperSetQuestion with question, questionType, options |
| 2 | Verify mapping | Maps to response with ordinal, text, type, type_code, ans_options, maxMarks, awardedMarks, selected_option_id, file_url, remarks |

#### TC-CR21: Controller saveQuestionWiseMarksOffline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect method | Uses firstOrCreate for uploadMark; handles both single and array option_ids |
| 2 | Verify transaction | DB::beginTransaction/commit/rollback |

#### TC-CR22: CSS modal custom styles

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect question-wise modal CSS | Gradient header (4e73df → 224abe); styled table header |
| 2 | Inspect bulk modal CSS | bg-success header |

#### TC-CR23: CSS option label styling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect .qw-opt-input | Hidden (opacity:0); clickable via label |
| 2 | Inspect .ans-option-label | Circle border; checked state uses #1cc88a green |

#### TC-CR24: View hidden inputs for tab state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect search form HTML | Two hidden inputs: active_tab=offline_upload, tab=offline_upload |

#### TC-CR25: View colspan=8 for empty states

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect "Please search" message | colspan=8 (7 data columns + action) |
| 2 | Inspect "No students found" message | colspan=8 |

#### TC-CR26: View pagination conditional

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect pagination block | Only shown when method_exists($studentsData, 'links') && active_tab === 'offline_upload' |

#### TC-CR27: View attempt detail link

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect action column | Eye icon only rendered when `$student->attempt_id` is set |

#### TC-CR28: View attachment data JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect data-attribution | `data-attachment="{{ json_encode($student->offline_attachment_data) }}"` |

#### TC-CR29: JS storageBase construction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect storageBase | Uses ternary with function_exists('tenant_asset') |
| 2 | Verify trailing slash handling | Adds / if not present |

#### TC-CR30: Controller file validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect file check | `if (!$file || !$file->isValid())` returns 400 |
| 2 | Verify error response | JSON with success=false, message='No valid file uploaded.' |
