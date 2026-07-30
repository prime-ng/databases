# STP — Homework Submission: Test Case List

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F012 |
| **Feature Name** | Homework + Submission |
| **REQ ID(s)** | REQ-STP-012 |
| **BR ID(s)** | BR-STP-001, BR-STP-019, BR-STP-022 |
| **Controller** | `StudentHomeworkController` |
| **Routes** | `GET /my-homework`, `GET /homework/{id}`, `POST /homework/{id}/submit` |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| **Backend** | Laravel 12, PHP 8.2+ |
| **Database** | MySQL 8 (Tenant DB) — requires LmsHomework module tables |
| **File Storage** | Local disk (public/uploads/lms-homework/) |
| **Auth** | Authenticated web session (student role) |
| **Browser** | Chrome/Firefox/Safari |
| **PHP Config** | `upload_max_filesize >= 2M`, `post_max_size >= 10M` |
| **Test Data** | Seeded student with homework assignments in various states (pending, overdue, submitted, graded) |

---

## 3. Test Approach

- **Level**: Functional / System / Security
- **Type**: Positive, Negative, Boundary, File Upload, Security (IDOR)
- **Method**: Manual + Automated (Pest)
- **Data Setup**: Requires `hmw_homeworks`, `hmw_homework_assignments`, `hmw_homework_submissions` tables with varied data
- **Key Focus Areas**: Homework listing with correct statuses, detail view with submission form, file upload validation, late submission gating, duplicate prevention, IDOR

---

## 4. Test Scope

### In Scope
- Homework list — all assignments shown with correct derived statuses
- Status counters (pending, overdue, submitted, graded)
- Homework detail — instructions, resources, submission form visibility
- Submission — text only, files only, both
- File upload validation — MIME types, size limits, count limits
- Late submission — gated by allow_late_submission flag
- Duplicate submission prevention
- Content requirement (text or files)
- PHP silent file drop detection
- IDOR — cannot view/submit another student's homework
- Activity logging

### Out of Scope
- Teacher-side homework creation/grading (LmsHomework admin)
- Email/push notifications for submission
- Plagiarism detection
- Homework deletion/cancellation

---

## 5. Test Cases

| TC ID | Test Case | Pre-condition | Test Steps | Expected Result | Priority | Automation |
|-------|-----------|---------------|------------|----------------|----------|------------|
| TC-HW-001 | Verify homework list loads for student with assignments | Student A has 5 active assignments | 1. Login as Student A<br>2. Navigate to `/my-homework` | 5 items displayed with subject, title, due date, status badge | P1 | Yes |
| TC-HW-002 | Verify status: pending | Assignment exists, no submission, due date in future | 1. Login as Student A<br>2. View homework list | Status = "pending" | P1 | Yes |
| TC-HW-003 | Verify status: submitted | Assignment has submission with submitted_at, no marks | 1. Login as Student A<br>2. View homework list | Status = "submitted" | P1 | Yes |
| TC-HW-004 | Verify status: graded | Assignment has submission with marks_obtained | 1. Login as Student A<br>2. View homework list | Status = "graded" | P1 | Yes |
| TC-HW-005 | Verify status: overdue | No submission, due date in past, late not allowed | 1. Login as Student A<br>2. View homework list | Status = "overdue" | P1 | Yes |
| TC-HW-006 | Verify status counters match displayed items | Student A: 2 pending, 1 submitted, 1 graded, 1 overdue | 1. Login as Student A<br>2. View homework list | Counters show: pending=2, submitted=1, graded=1, overdue=1 | P1 | Yes |
| TC-HW-007 | Verify homework list ordered by id DESC | Homework created in order: HW1 (id=1), HW2 (id=2), HW3 (id=3) | 1. Login as Student A<br>2. View homework list | Order: HW3, HW2, HW1 | P2 | Yes |
| TC-HW-008 | Verify empty homework list | Student A has no assignments | 1. Login as Student A<br>2. Navigate to `/my-homework` | Empty list; counters all 0 | P1 | Yes |
| TC-HW-009 | Verify homework detail page loads | Student A has homework ID 5 | 1. Login as Student A<br>2. Navigate to `/homework/5` | Instructions page shows subject, title, marks, dates, description; teacher attachments listed | P1 | Yes |
| TC-HW-010 | Verify submission form visible for pending homework | Homework is pending, due date in future | 1. Login as Student A<br>2. View homework detail | Submission form shown with text editor and file upload | P1 | Yes |
| TC-HW-011 | Verify submission form hidden after due date (late not allowed) | Homework due date passed, allow_late = false | 1. Login as Student A<br>2. View homework detail | Submission form not shown; cannot submit | P1 | Yes |
| TC-HW-012 | Verify submission form shown after due date (late allowed) | Homework due date passed, allow_late = true | 1. Login as Student A<br>2. View homework detail | Submission form shown; `canSubmit = true` | P1 | Yes |
| TC-HW-013 | Verify submission form hidden after already submitted | Student A already submitted homework with no resubmission request | 1. Login as Student A<br>2. View already-submitted homework | Submission form hidden; existing submission shown (text, files, status) | P1 | Yes |
| TC-HW-014 | Verify submission form shown when resubmission requested | Student A submitted, teacher set is_resubmission_requested = true | 1. Login as Student A<br>2. View homework detail | Submission form shown again; `canSubmit = true` | P1 | Yes |
| TC-HW-015 | Verify submit — text only | Student submits homework with text answer | 1. Login as Student A<br>2. Navigate to homework detail<br>3. Enter text in submission_text<br>4. Click Submit | Redirected to `/my-homework` with success message; submission record created with text | P1 | Yes |
| TC-HW-016 | Verify submit — file only | Student submits homework with 1 PDF file | 1. Login as Student A<br>2. Navigate to homework detail<br>3. Upload 1 PDF file<br>4. Click Submit | Redirected with success; file stored; sub_attachment_media_id populated | P1 | Yes |
| TC-HW-017 | Verify submit — text + multiple files | Student submits with text + 3 files (PDF, DOCX, JPG) | 1. Login as Student A<br>2. Upload 3 valid files + enter text<br>3. Click Submit | Redirected with success; all 3 files stored; text saved | P1 | Yes |
| TC-HW-018 | Verify submit — same moment as due date (borderline) | Due date = now, student submits | 1. Set due date to 1 second ago<br>2. Submit homework | If `now() > due_date` → marked as `is_late = true`; if `now() <= due_date` → on time | P2 | Yes |
| TC-HW-019 | Verify late submission flag | Homework submitted after due date with late allowed | 1. Set allow_late = true<br>2. Submit after due date | Success message: "Homework submitted (marked as late)."; `is_late = true` in record | P1 | Yes |
| TC-HW-020 | Verify late submission blocked | Homework due date passed, allow_late = false | 1. Login as Student A<br>2. Submit homework after due date | Redirected to `/my-homework` with error: "The due date has passed and late submissions are not allowed for this homework." | P1 | Yes |
| TC-HW-021 | Verify duplicate submission blocked | Student A already submitted this homework | 1. Login as Student A<br>2. POST submit again | Redirected with warning: "You have already submitted this homework." | P1 | Yes |
| TC-HW-022 | Verify submit with neither text nor files | Student clicks Submit with empty form | 1. Login as Student A<br>2. Click Submit without entering anything | Redirected back with error: "Please provide a text answer or attach a file." | P1 | Yes |
| TC-HW-023 | Verify file upload — exceeds 2 MB | Student uploads a 3 MB file | 1. Upload file > 2 MB<br>2. Click Submit | 422 validation error: "Each file must be under 2 MB." | P1 | Yes |
| TC-HW-024 | Verify file upload — invalid MIME type | Student uploads .exe file | 1. Upload .exe file<br>2. Click Submit | 422 validation error: "Allowed file types: PDF, DOC, DOCX, JPG, PNG, ZIP, TXT." | P1 | Yes |
| TC-HW-025 | Verify file upload — more than 5 files | Student uploads 6 files | 1. Upload 6 valid files<br>2. Click Submit | 422 validation error (array.max) | P2 | Yes |
| TC-HW-026 | Verify file upload — exactly 5 files (boundary) | Student uploads 5 files (2 MB each) | 1. Upload 5 valid files<br>2. Click Submit | Submission succeeds; all 5 files stored | P2 | Yes |
| TC-HW-027 | Verify PHP silent file drop detection | Student uploads file > upload_max_filesize | 1. Simulate POST with CONTENT_LENGTH > 0 but empty $_FILES<br>2. Submit | Redirected back with error: "The uploaded file exceeds the server limit (2 MB)." | P1 | Yes |
| TC-HW-028 | Verify submission_text max length (10000 chars) | Student enters 10001 characters | 1. Enter > 10000 chars in submission_text<br>2. Click Submit | 422 validation error (max:10000) | P2 | Yes |
| TC-HW-029 | Verify submission_text exactly 10000 chars (boundary) | Student enters 10000 characters | 1. Enter exactly 10000 chars<br>2. Click Submit | Submission succeeds | P2 | Yes |
| TC-HW-030 | Verify IDOR — cannot view another student's homework detail | Homework ID 5 belongs to Student B | 1. Login as Student A<br>2. Navigate to `/homework/5` | 404 Not Found | P1 | Yes |
| TC-HW-031 | Verify IDOR — cannot submit another student's homework | Homework ID 5 belongs to Student B | 1. Login as Student A<br>2. POST to `/homework/5/submit` | 404 Not Found (firstOrFail on assignment) | P1 | Yes |
| TC-HW-032 | Verify non-existent homework ID | Homework ID 9999 does not exist | 1. Login as Student A<br>2. Navigate to `/homework/9999` | 404 Not Found | P2 | Yes |
| TC-HW-033 | Verify activity log — homework list view | Student A views list | 1. Login as Student A<br>2. Navigate to `/my-homework` | Activity log records 'Viewed' | P3 | No |
| TC-HW-034 | Verify activity log — homework detail view | Student A views detail | 1. Login as Student A<br>2. Navigate to `/homework/{id}` | Activity log records 'Viewed' with homework_id | P3 | No |
| TC-HW-035 | Verify activity log — homework submission | Student A submits | 1. Login as Student A<br>2. Submit homework | Activity log records 'Submitted' with homework_id, status, is_late | P3 | No |
| TC-HW-036 | Verify homework detail — teacher attachments displayed | Homework has 2 attached files | 1. Login as Student A<br>2. View homework/{id} | Downloadable links for teacher's attachments visible | P2 | Yes |
| TC-HW-037 | Verify submission success redirect | Student A submits successfully | 1. Submit homework<br>2. Check redirect | Redirected to `/my-homework` with flash success message | P1 | Yes |
| TC-HW-038 | Verify override: assignment-level allow_late_submission | Homework allow_late=false, Assignment allow_late=true | 1. Submit after due date | Submission allowed (assignment-level override) | P2 | Yes |
| TC-HW-039 | Verify override: assignment-level due_date | Homework has due_date X, Assignment has due_date Y | 1. View homework detail | `$dueDate` = assignment's due_date (Y), not homework's | P2 | Yes |

---

## 6. Regression Impact

| Area | Impact | Suggested Tests |
|------|--------|----------------|
| LmsHomework module | Schema/status changes affect listing + submission | Verify homework list + submission after schema changes |
| LmsStorageService | Storage path/build changes could break file uploads | Verify file store and retrieval after storage changes |
| SystemConfig | `sys_dropdown_table` changes could break status_id resolution | Verify submission record created with correct status_id |
| PHP config | `upload_max_filesize` changes affect silent drop detection | Verify TC-HW-027 behaviour after server config change |

---

## 7. Known Gaps & Issues

| Gap ID | Description | Impact on Testing |
|--------|-------------|-------------------|
| — | `status_id` resolved from `sys_dropdown_table` with hardcoded fallback 253 | If DB changes, fallback may be wrong — test TC-HW-015 through TC-HW-017 verify record creation |
| — | PHP silent file drop detection using `$_SERVER['CONTENT_LENGTH']` | May not work on all hosts — TC-HW-027 may give false pass/fail |
| — | Resubmission requires teacher action (`is_resubmission_requested`) | TC-HW-014 tests this; cannot test student-initiated resubmission |
| — | No `Gate::authorize()` policies | All security relies on query scoping |
| — | `max:5` on array validation gives generic error | If custom message needed, view must handle it |

---

## 8. Sign-off Criteria

| Criteria | Target |
|----------|--------|
| P1 Test Cases Passed | 100% |
| P2 Test Cases Passed | 100% |
| File upload validation (MIME, size, count) | All pass |
| Late submission gating | TC-HW-019, TC-HW-020 pass |
| Duplicate prevention | TC-HW-021 pass |
| IDOR (detail + submit) | TC-HW-030, TC-HW-031 pass |
| Content requirement | TC-HW-022 pass |

---

## 9. Appendices

### A. Test Data Requirements
- Student A with 6 homework assignments in varied states:
  - 1 pending (future due date, no submission)
  - 1 submitted (has submission, no marks)
  - 1 graded (has submission with marks_obtained)
  - 1 overdue (past due date, no submission, late not allowed)
  - 1 overdue with late allowed
  - 1 with resubmission requested
- Homework with teacher-attached files (2+)
- Student B with separate assignments (for IDOR)
- File samples: valid PDF (1 MB, 2.5 MB), DOCX, JPG, PNG, ZIP, TXT, invalid .exe
- PHP config: upload_max_filesize = 2M, post_max_size = 12M

### B. Related Routes
```
GET  /my-homework          → StudentHomeworkController@index
GET  /homework/{id}        → StudentHomeworkController@show
POST /homework/{id}/submit → StudentHomeworkController@submit
```

### C. File Upload Test Matrix
| File | Size | Type | Expected |
|------|------|------|----------|
| sample.pdf | 1 MB | application/pdf | ✅ Accepted |
| sample.pdf | 2.5 MB | application/pdf | ❌ Rejected (> 2 MB) |
| sample.docx | 500 KB | application/vnd.openxmlformats-officedocument.wordprocessingml.document | ✅ Accepted |
| sample.exe | 100 KB | application/x-msdownload | ❌ Rejected (MIME not allowed) |
| sample.zip | 1 MB | application/zip | ✅ Accepted |
| sample.png | 1.5 MB | image/png | ✅ Accepted |

---

## 10. Traceability

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-012 |
| Business Rules | BR-STP-001, BR-STP-019, BR-STP-022 |
| Requirement Doc | `stp_HomeworkSubmission_Requirement.md` |
| Controller | `StudentHomeworkController` (index, show, submit) |
| Views | `studentportal::homework.index`, `studentportal::homework.show` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/homework_submission.md` |
