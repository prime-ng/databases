# LMS Homework Submissions — Requirement Document

## 1. Screen Purpose & Overview

The **Homework Submission** screen is the interface where students upload their homework responses. Depending on the template configuration (`TEXT`, `FILE`, `HYBRID`), students can enter text replies and upload files. 

Upon submission, the system evaluates dates to mark late arrivals and locks the submission while it is under evaluation. If a teacher requests a resubmission, this screen allows students to update their content and resubmit, which increments the resubmission count.

---

## 2. Common Business Use Cases

1. **Submitting File-Based Homework:** A student uploads a scanned PDF copy of their math homework. The system logs it and matches it with their assignment record.
2. **Flagging Late Submissions:** A student submits their homework 2 hours past the deadline. The template allows late submissions, so the system flags `is_late = 1` and registers the submission.
3. **Preventing Late Submissions:** A student attempts to upload homework past the deadline, but the template blocks late submissions. The portal disables the upload interface.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `lms_homework_submissions`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)
*   **Unique Index**: `uq_hws_assignment` (`assignment_id`) - One active submission per student assignment.

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `assignment_id` | `int unsigned` | No | N/A | Foreign key to `lms_homework_assignment.id` (Cascade). |
| `homework_id` | `int unsigned` | No | N/A | Cached FK to parent template. |
| `student_id` | `int unsigned` | No | N/A | Cached FK to student model. |
| `submission_text` | `longtext` | Yes | `NULL` | Student's written answer text. |
| `sub_attachment_media_id`| `json` | Yes | `NULL` | Array of objects representing uploaded files, e.g. `[{"media_id": 12, "file_name": "hw1.pdf"}]`. |
| `submitted_at` | `datetime` | No | N/A | Timestamp of student submission. |
| `is_late` | `tinyint(1)` | No | `0` | Flag calculated at store time (0 = On-time, 1 = Late). |
| `resubmission_count` | `tinyint unsigned`| No | `0` | Increments each time a student re-submits after rejection. |
| `status_id` | `int unsigned` | No | N/A | FK to dropdown tables (`SUBMITTED`, `UNDER_REVIEW`, `GRADED`, `REJECTED`, `RESUBMIT_REQUESTED`). |
| `is_resubmission_requested`| `int unsigned` | No | `0` | Flag indicating if a resubmission has been requested. |
| `marks_obtained` | `decimal(5,2)` | Yes | `NULL` | Scored marks. |
| `teacher_feedback` | `text` | Yes | `NULL` | Evaluator feedback text. |
| `graded_by` | `int unsigned` | Yes | `NULL` | FK referencing the evaluating teacher (`sys_users.id`). |
| `graded_at` | `datetime` | Yes | `NULL` | Evaluation timestamp. |
| `score_published_at` | `datetime` | Yes | `NULL` | Timestamp when score was made visible to student. |
| `is_active` | `tinyint(1)` | No | `1` | Operational status. |
| `created_by` | `int unsigned` | Yes | `NULL` | Student user ID. |
| `updated_by` | `int unsigned` | Yes | `NULL` | Last updater user ID. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Response Text** | Rich Text Editor | Yes (if TEXT) | Mandatory if template type requires text response. | None |
| **Attachments** | File Uploader | Yes (if FILE) | Multiple file support. Total maximum upload size: 10MB. Allowed extensions: `.pdf`, `.docx`, `.png`, `.jpg`, `.zip`. | None |

---

## 5. Business Logic & Validation Policies

1. **Submission Type Constraints**:
   * If `submission_type_id` corresponds to `TEXT`, the system validates: `submission_text` must not be null.
   * If `submission_type_id` corresponds to `FILE`, `sub_attachment_media_id` JSON array must contain at least one uploaded file.
   * If `submission_type_id` corresponds to `HYBRID`, either `submission_text` or `sub_attachment_media_id` must be populated.
2. **Late Checking Logic**:
   * When a student submits, the system calculates `is_late` as follows:
     $$\text{is\_late} = \text{IF}(\text{submitted\_at} > \text{Effective Due Date}, 1, 0)$$
   * If $\text{is\_late} = 1$ and the assignment's effective $\text{allow\_late\_submission} = 0$, the server blocks the action and returns: *"Late submissions are not allowed for this homework."*
3. **Resubmission Flow**:
   * If `status_id = RESUBMIT_REQUESTED`, a student's upload updates the existing row instead of creating a new one. It increments `resubmission_count` by $1$, updates `submitted_at = NOW()`, recalculates `is_late`, and resets `status_id = SUBMITTED`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Student.
* Ensure an active, released assignment is available on the student dashboard.

### Scenario A: Happy Path Submission (On-time File)
1. Locate the assignment `Quadratic Equations Practice`.
2. Click **"Submit Homework"**.
3. Drag and drop a file named `math_homework.pdf` (size 2MB).
4. Click **"Upload & Submit"**.
5. **Expected Result**: Success alert displays. Assignment status changes to `SUBMITTED`. Database check: Row created in `lms_homework_submissions` with `is_late = 0`, `resubmission_count = 0`, and the media attachment registered in `sub_attachment_media_id`.

### Scenario B: Validating File Upload Limits
1. Navigate to the submission page for another homework.
2. Attempt to upload a file named `video_project.mp4` (size 15MB).
3. Click **"Submit"**.
4. **Expected Result**: Upload fails and displays validation messages:
   * *"The attachment file size must not exceed 10MB."*
   * *"The attachment file type must be one of: pdf, docx, png, jpg, zip."*

### Scenario C: Handling Resubmissions
1. Navigate to an assignment where the teacher has requested a resubmission (`status_id` is `RESUBMIT_REQUESTED`).
2. Click **"Update Submission"**.
3. Edit the text response block and upload a corrected file.
4. Click **"Resubmit"**.
5. **Expected Result**: Submission accepted. Database check: `resubmission_count` increments to `1`, `submitted_at` is updated, and status reverts to `SUBMITTED`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/student/homework/submit/{assignment_id}`

### 2. Submission Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->studentUser)
            ->visit('/student/homework/submit/' . $this->assignmentId)
            ->attach('attachment', __DIR__ . '/files/hw_upload.pdf')
            ->type('submission_text', 'Completed all exercises.')
            ->press('@submit-btn')
            ->assertPathIs('/student/homework/dashboard')
            ->assertSee('submitted successfully');
});
```

### 3. Blocked Late Submission Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    // Navigate to a late homework where allow_late_submission is disabled
    $browser->loginAs($this->studentUser)
            ->visit('/student/homework/submit/' . $this->pastDueAssignmentId)
            ->assertDisabled('@submit-btn')
            ->assertSee('Late submissions are not allowed');
});
```
