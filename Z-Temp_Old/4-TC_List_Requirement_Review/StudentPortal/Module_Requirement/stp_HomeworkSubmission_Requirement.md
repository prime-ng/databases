# STP — Homework Submission

## 1. Document Control

| Field | Value |
|-------|-------|
| **Module** | StudentPortal (STP) |
| **Feature ID** | STP-F012 |
| **Feature Name** | Homework + Submission |
| **REQ ID(s)** | REQ-STP-012 |
| **BR ID(s)** | BR-STP-001, BR-STP-019, BR-STP-022 |
| **Controller** | `StudentHomeworkController` (index, show, submit) |
| **Routes** | `GET /my-homework`, `GET /homework/{id}`, `POST /homework/{id}/submit` |
| **Views** | `studentportal::homework.index`, `studentportal::homework.show` |
| **Table Prefix** | `hmw_*`, `lms_*` (reads from LmsHomework module) |
| **DB Layer** | Tenant |
| **V1/V2** | — |
| **Status** | ⬜ |
| **CR** | ◌ |
| **Author** | OpenCode |
| **Date** | 2026-07-23 |

---

## 2. Feature Overview

Enables students to view their homework list, read detailed instructions with teacher-attached resources, and submit their work via online text or file attachments. Supports late submission gating, file upload validation, and single-submission enforcement.

---

## 3. Functional Requirements

### 3.1 Homework List (index)
- Lists all homework assignments for the authenticated student where:
  - `student_id` matches the authenticated student.
  - `is_released = true` and `is_active = true`.
- Each item shows: subject, title, max marks, assign date, due date, and derived status.
- Status derivation logic (in order of precedence):
  1. If `marks_obtained !== null` → `'graded'`
  2. If `submitted_at !== null` → `'submitted'`
  3. If `due_date` is in the past → `'overdue'`
  4. Otherwise → `'pending'`
- Status counts computed: `$pending`, `$overdue`, `$submitted`, `$graded`.
- Ordered by `id DESC` (most recent first).
- Includes latex submission flag: `allow_late` derived from `homework->allow_late_submission` or `assignment->allow_late_submission`.

### 3.2 Homework Detail (show)
- Shows full instructions for a single homework: subject, title, marks, assign date, due date, description, teacher-attached documents.
- Actions: submission form (if eligible) or read-only view (if not).
- Determines `$canSubmit`:
  - `true` if no submission exists OR `is_resubmission_requested = true`.
  - `false` if `$isLate === true` AND `allow_late_submission === false`.

### 3.3 Homework Submission (submit)
- Accepts POST with:
  - `submission_text` (nullable string, max 10,000 chars).
  - `attachments` (nullable array, max 5 files).
- File upload rules:
  - Max 5 files.
  - Each file max 2 MB (2048 KB).
  - Allowed MIME types: `pdf, doc, docx, jpg, jpeg, png, zip, txt`.
- Late submission guard:
  - If `$isLate` AND neither `$hw->allow_late_submission` nor `$assignment->allow_late_submission`:
    - Redirect with error: "The due date has passed and late submissions are not allowed for this homework."
- Duplicate submission guard:
  - If a submission with `submitted_at !== null` already exists → redirect with warning: "You have already submitted this homework."
- PHP silent file drop detection:
  - If `hasFile('attachments') === false` but `CONTENT_LENGTH > 0` and `$_FILES` is empty → redirect with error: "The uploaded file exceeds the server limit (2 MB). Please compress the file and try again."
- Content requirement:
  - If neither `submission_text` nor `attachments` provided → redirect with error: "Please provide a text answer or attach a file."
- Storage: Uses `LmsStorageService` to store files with path pattern: `{session_code}/{class_section_id}/{homework_id}/{student_id}/student/`.
- Creates `HomeworkSubmission` record with:
  - `assignment_id`, `homework_id`, `student_id` (std_students.id), `submitted_at`, `submission_text`, `sub_attachment_media_id` (JSON array), `status_id` (resolved from `sys_dropdown_table` where value = 'SUBMITTED'), `is_late` (boolean).
- On success: Redirect to `/my-homework` with success message.
  - If late: "Homework submitted (marked as late)."
  - If on time: "Homework submitted successfully!"

---

## 4. Non-Functional Requirements

| NFR-ID | Requirement | Threshold |
|--------|------------|-----------|
| NFR-STP-009 | File upload validation | MIME + size validated; max 5 files × 2 MB |
| NFR-STP-008 | Student-friendly error messages | No technical error codes |
| NFR-STP-013 | Error messages for upload failures | Clear messages about limits and types |

---

## 5. Business Rules

| Rule ID | Description | Enforcement |
|---------|-------------|-------------|
| BR-STP-001 | Data belongs to authenticated student | `HomeworkAssignment::where('student_id', $studentId)` |
| BR-STP-019 | Homework assignments scoped to student | `where('student_id', $studentId)` in all 3 methods |
| BR-STP-022 | Late submission gated by `restrict_late_submission` | `if ($isLate && !$allow_late) → redirect with error` |
| — | Single active submission per assignment | Check `$existing->submitted_at !== null` |
| — | Re-submission allowed only if `is_resubmission_requested = true` | `$canSubmit = !$sub->submitted_at OR $sub->is_resubmission_requested` |
| — | File upload limits: 5 files, 2 MB each | `max:5` array + `max:2048` per file |
| — | Allowed file types enforced | `mimes:pdf,doc,docx,jpg,jpeg,png,zip,txt` |
| — | At least one of text or file required | `if (!$submission_text && !$attachments) → error` |
| — | Status ID resolved from sys_dropdown_table | DB lookup with fallback to 253 |

---

## 6. User Interface / UX

- **Homework List Page** (`/my-homework`): Tabular layout with status badges (pending/overdue/submitted/graded), subject, title, due date. Filterable by status counts at top.
- **Homework Detail Page** (`/homework/{id}`): Shows instructions, teacher resources (downloadable), submission form with text editor + file uploader.
- **Submission Form**: Text area + file upload (drag-and-drop or browse). Submit button.
- **Read-only View**: If past due and late not allowed, or already submitted without resubmission — no form, just instructions.
- **Success/Error Messages**: Flash messages via `with('success')` / `with('error')`.

---

## 7. Data Dictionary

| Variable | Source | Type | Description |
|----------|--------|------|-------------|
| `assignments` | `HomeworkAssignment::where('student_id', ...)` | Collection | All active + released assignments |
| `items` | Mapped assignments | Collection | Augmented rows with derived status + display data |
| `hw` | `$assignment->homework` | Model | Homework definition (title, marks, subject, dates, files) |
| `sub` | `$assignment->submission` | Model | Student's submission (text, files, marks, feedback) |
| `dueDate` | `$assignment->due_date ?? $hw->due_date` | Date | Effective due date |
| `isLate` | Computed | bool | Due date in past |
| `canSubmit` | Computed | bool | Whether form is shown |
| `allow_late` | `$hw->allow_late_submission || $assignment->allow_late_submission` | bool | Whether late submission is permitted |

---

## 8. API / Controller Specifications

### `StudentHomeworkController@index()`

| Aspect | Detail |
|--------|--------|
| **Method** | `GET /my-homework` |
| **Auth** | Web `auth` |
| **Query** | `HomeworkAssignment::where('student_id', $id)->is_released->is_active->with('homework.subject', 'homework.status', 'submission')->orderByDesc('id')` |
| **Computed** | Status per item via `derivedStatus()`; 4 counter variables |

### `StudentHomeworkController@show(int $id)`

| Aspect | Detail |
|--------|--------|
| **Method** | `GET /homework/{id}` |
| **Auth** | Web `auth` |
| **Ownership** | `HomeworkAssignment::where('student_id', $studentId)->where('homework_id', $id)->firstOrFail()` |
| **Computed** | `$dueDate`, `$isLate`, `$canSubmit` |

### `StudentHomeworkController@submit(int $id, Request)`

| Aspect | Detail |
|--------|--------|
| **Method** | `POST /homework/{id}/submit` |
| **Auth** | Web `auth` |
| **Ownership** | Same as show |
| **Guards** | Late check → redirect; Duplicate check → redirect; Upload size check |
| **Validation** | `submission_text` (nullable, max 10000), `attachments` (nullable, array max 5, each max 2048, mimes) |
| **Storage** | `LmsStorageService::buildPath()` + `storeFile()` |
| **DB** | Transaction: create `HomeworkSubmission` with resolved status_id |
| **Redirect** | Success: `/my-homework`; Error: back with flash |

---

## 9. Validation Rules

### Submit Request

| Field | Rule | Error Message |
|-------|------|---------------|
| `submission_text` | nullable, string, max:10000 | Default Laravel validation |
| `attachments` | nullable, array, max:5 | — |
| `attachments.*` | file, max:2048, mimes:pdf,doc,docx,jpg,jpeg,png,zip,txt | "Each file must be under 2 MB." / "Allowed file types: PDF, DOC, DOCX, JPG, PNG, ZIP, TXT." / "One or more uploads are not valid files." |
| Business: content | At least text or files | "Please provide a text answer or attach a file." |
| Business: late | Not late OR allow_late = true | "The due date has passed and late submissions are not allowed for this homework." |
| Business: duplicate | No existing submitted_at record | "You have already submitted this homework." |

---

## 10. Error Handling & Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Student has no homework assignments | Empty list; status counters all 0 |
| Access homework detail for non-existent ID | `firstOrFail()` → 404 |
| Access homework detail for another student's homework | Ownership scoping → 404 (no matching assignment) |
| Submit after due date when late not allowed | Redirect to `/my-homework` with error message |
| Submit duplicate homework | Redirect with warning: already submitted |
| Upload 6 files (exceed max 5) | 422 validation error (no custom message — default array.max) |
| Upload file > 2 MB | 422 with custom message: "Each file must be under 2 MB." |
| Upload invalid file type (.exe) | 422 with custom message: "Allowed file types: PDF, DOC, DOCX, JPG, PNG, ZIP, TXT." |
| PHP max upload size exceeded (silent file drop) | Redirect with error: "The uploaded file exceeds the server limit (2 MB)." |
| Submit with neither text nor files | Redirect with error: "Please provide a text answer or attach a file." |
| Submit text only (no files) | Success — submission_text stored, no attachments |
| Submit files only (no text) | Success — files stored, sub_attachment_media_id populated |
| Submit with both text and files | Success — both stored |
| Submit exactly at due date boundary | `greaterThan` uses `Carbon::now()` — exact due date moment is borderline; if `now() > due_date` = true, marked late |
| Resubmission requested by teacher | `is_resubmission_requested = true` → `canSubmit = true` even if already submitted |
| Database failure during submission | Transaction rollback; redirect with error: "Submission failed: {message}" |
| Status ID lookup fails (sys_dropdown_table change) | Falls back to 253 |

---

## 11. Security & Compliance

| Concern | Status |
|---------|--------|
| **IDOR** | ✅ All queries scoped to `auth()->user()->student->id` through `HomeworkAssignment::where('student_id', $studentId)` |
| **Authentication** | ✅ Web auth middleware |
| **File Upload Validation** | ✅ MIME type + size validated |
| **PHP Silent Drop Detection** | ✅ Custom check for `upload_max_filesize` exceeded |
| **Authorization Gates** | ⚠️ No `Gate::authorize()` calls |
| **SQL Injection** | ✅ Prepared statements / Eloquent |
| **Input Sanitization** | ✅ `submission_text` stored as-is; rendered with Blade escaping |

---

## 12. Integration Points

| Module | Integration | Direction |
|--------|-------------|-----------|
| LmsHomework | `hmw_homework_assignments`, `hmw_homeworks`, `hmw_homework_submissions` | STP ← LmsHomework |
| LmsHomework | `LmsStorageService` — file upload and path building | STP → LmsHomework |
| StudentProfile (STD) | `std_students` — student identity, session | STP ← STD |
| SystemConfig | `sys_dropdown_table` — status ID resolution | STP ← SystemConfig |

---

## 13. Performance Considerations

- Homework list: Single query with eager loading (homework + subject + status + submission).
- Detail page: Single query with eager loading.
- Submission: Transaction with file storage — file upload size affects response time.
- File storage: Files stored on local/cloud disk via Spatie Media Library (through LmsStorageService).
- No caching.

---

## 14. Dependencies & Pre-requisites

| Dependency | Type | Status |
|-----------|------|--------|
| LmsHomework module | Module | Required |
| `hmw_homework_assignments` table with student records | Data | Required |
| `hmw_homework_submissions` table | Schema | Required |
| `sys_dropdown_table` with SUBMITTED status entry | Data | Required for status_id |
| `LmsStorageService` | Service | Required for file uploads |
| PHP `upload_max_filesize` ≥ 2 MB | Config | Required |
| PHP `post_max_size` ≥ 10 MB | Config | Required (5 files × 2 MB = 10 MB) |

---

## 15. Known Gaps & Issues

| Gap ID | Description | Severity | Status |
|--------|-------------|----------|--------|
| — | `status_id` resolution relies on `sys_dropdown_table` key matching — hardcoded fallback to 253 is fragile | Medium | ⬜ Open |
| — | No server-side check for `max:5` array validation — if more than 5 files uploaded, validation error is generic (not custom) | Low | ⬜ Open |
| — | Resubmission workflow requires teacher to set `is_resubmission_requested` — no student-initiated resubmission | Low | ⬜ Open |
| — | `php -l` file drop detection uses `$_SERVER['CONTENT_LENGTH']` — may not work on all server configurations | Medium | ⬜ Open |
| — | No `Gate::authorize()` policies | Low | ⬜ Open |
| — | Student ID usage inconsistent: `student_id` in submission uses `std_students.id` but controller comment notes ambiguity with `sys_users.id` | Low | ⬜ Open |

---

## 16. Traceability Matrix

| Artifact | Reference |
|----------|-----------|
| FRD | REQ-STP-012 |
| Business Rules | BR-STP-001, BR-STP-019, BR-STP-022 |
| Controller Methods | `index`, `show`, `submit` |
| Routes | `GET /my-homework`, `GET /homework/{id}`, `POST /homework/{id}/submit` |
| Views | `studentportal::homework.index`, `studentportal::homework.show` |
| Input Doc | `pgdatabase/Backup/4-Module_Requirement/StudentPortal/learning/homework_submission.md` |
