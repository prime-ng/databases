# LMS Homework Paper Check — Requirement Document

## 1. Screen Purpose & Overview

The **Paper Check** screen is a grading interface for teachers. It provides an annotation canvas where teachers can view student text responses and uploaded PDF/image files. 

Teachers use this screen to enter evaluation details: scored marks, written feedback, and status resolutions (such as marking as `GRADED` or requesting a student correction by flagging it as a `RESUBMIT_REQUESTED`).

---

## 2. Common Business Use Cases

1. **Grading a Submission:** A teacher reviews a student's math PDF, adds annotations on the canvas, enters a score of $45.00$ out of $50.00$, types feedback, and saves.
2. **Requesting a Resubmission:** The teacher finds the student uploaded a blank or corrupt file, adds feedback asking for a clear scan, and clicks **"Request Resubmission"** to reset the assignment for the student.
3. **Reviewing Late Submissions:** The teacher evaluates a late submission, applying a penalization factor manually before saving the final grade.

---

## 3. Database Schema & Data Dictionary

*   **Table Name**: `lms_homework_submissions`
*   **Primary Key**: `id` (INT UNSIGNED, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `marks_obtained` | `decimal(5,2)` | Yes | `NULL` | Evaluation score awarded by teacher. |
| `teacher_feedback` | `text` | Yes | `NULL` | Written guidance feedback. |
| `graded_by` | `int unsigned` | Yes | `NULL` | Foreign key referencing evaluating teacher's `sys_users.id`. |
| `graded_at` | `datetime` | Yes | `NULL` | Evaluation timestamp. |
| `status_id` | `int unsigned` | No | N/A | Submission workflow status FK (`UNDER_REVIEW`, `GRADED`, `REJECTED`, `RESUBMIT_REQUESTED`). |
| `is_resubmission_requested`| `int unsigned` | No | `0` | Flag (0 = No request, 1 = Resubmission active). |
| `score_published_at` | `datetime` | Yes | `NULL` | Score release timestamp. |
| `updated_by` | `int unsigned` | Yes | `NULL` | FK referencing the teacher user who updated the evaluation. |
| `updated_at` | `timestamp` | Yes | `NULL` | Audit modification timestamp. |

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Marks Obtained** | Numeric Input | Yes (if Gradable) | Decimal. Must satisfy $0.00 \le \text{marks\_obtained} \le \text{lms\_homework.max\_marks}$. | None |
| **Teacher Feedback** | Text Area | No | Optional. Free text format. Max 2000 chars. | None |
| **Submission Action** | Buttons | Yes | `Grade & Complete` \| `Request Resubmission` \| `Reject`. | None |

---

## 5. Business Logic & Validation Policies

1. **Score Verification constraints**:
   * Scored marks must be non-negative and must not exceed the homework template's maximum allowed marks:
     $$0.00 \le \text{marks\_obtained} \le \text{max\_marks}$$
   * If a score exceeds the threshold, the server blocks the action and returns: *"Marks obtained cannot exceed maximum homework marks."*
2. **Resubmission Activation Logic**:
   * Requesting a resubmission updates the submission status to `RESUBMIT_REQUESTED` and sets the `is_resubmission_requested` flag to `1`.
   * This action updates `lms_homework_assignment.status_id` to `RESUBMIT_REQUESTED` to reopen the submission portal for the student.
3. **Score Publishing Policy**:
   * If the parent homework template has `auto_publish_score = 1`, saving the grade sets `score_published_at = NOW()` immediately.
   * If `auto_publish_score = 0`, the score remains hidden from the student portal until the teacher manually triggers a **"Publish Score"** action.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Teacher.
* Ensure a student submission exists in `SUBMITTED` or `UNDER_REVIEW` status.
* Open the homework detail page and click **"Evaluate Submission"** or navigate to `/home-works/{homework_id}/paper-check`.

### Scenario A: Grading Submission Happy Path
1. View the student's text response and uploaded file on the preview canvas.
2. Enter Marks Obtained: `42.50`. (Homework max marks is 50).
3. Type Feedback: `Excellent calculation steps. Watch your signs on question 4.`
4. Click **"Grade & Complete"**.
5. **Expected Result**: Page redirects back to the submission index with a success toast. The submission status changes to `GRADED`, and the assignment status also updates to `GRADED`.

### Scenario B: Enforcing Score Thresholds
1. Open a submission details page.
2. Enter Marks Obtained: `55.00` (exceeding maximum limit of 50).
3. Click **"Grade & Complete"**.
4. **Expected Result**: The action is blocked, displaying: *"Marks obtained cannot exceed maximum homework marks."*

### Scenario C: Initiating Resubmissions
1. Open a submission page where the upload is incorrect.
2. Type Feedback: `The uploaded image is blank. Please scan and upload again.`
3. Click **"Request Resubmission"**.
4. **Expected Result**: Dashboard updates. Submission status is now `RESUBMIT_REQUESTED`. The student portal is updated to show a resubmission request.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/lms-home-work/home-works/{id}/paper-check`

### 2. Grading Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/home-works/' . $this->homeworkId . '/paper-check')
            ->click('@submission-row-' . $this->submissionId)
            ->type('marks_obtained', '45')
            ->type('teacher_feedback', 'Good work')
            ->press('@grade-btn')
            ->assertSee('graded successfully');
});
```

### 3. Request Resubmission Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->teacherUser)
            ->visit('/lms-home-work/home-works/' . $this->homeworkId . '/paper-check')
            ->click('@submission-row-' . $this->submissionId)
            ->type('teacher_feedback', 'Please upload a clear scan.')
            ->press('@request-resubmission-btn')
            ->assertSee('Resubmission requested');
});
```
