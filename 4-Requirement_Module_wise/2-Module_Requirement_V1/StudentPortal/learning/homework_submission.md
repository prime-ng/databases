# Learning — Homework Submission Requirements

## 1. Functional Overview
Enables students to view homework guidelines, download resources uploaded by teachers, type online answers, and attach submission documents.

---

## 2. Page Structure & Parameters

### A. Instructions View
- Displays subject, title, marks, assign date, due date, description instructions, and download links for documents attached by the teacher.

### B. Submission Form
- **Online Answer Textarea**: Text editor for typing answers.
- **Attachments Area**: File uploader (Max 5 files, 2MB per file limit; allowed formats: PDF, DOC, DOCX, JPG, PNG, ZIP, TXT).

### C. Validation & Late Rules
- Blocks submissions if the deadline has passed and `allow_late_submission` is false.
- Flags the submission as `is_late` if submitted after the due date and late submission is permitted.
- Limits submissions to one active submission (resubmission requires teacher request).

---

## 3. Database References
- **Model**: `Modules\LmsHomework\Models\HomeworkSubmission`
- **Table**: `lms_homework_submissions`
- **Fields**:
  - `assignment_id`
  - `homework_id`
  - `student_id`
  - `submitted_at`
  - `submission_text`
  - `sub_attachment_media_id` (JSON array of media IDs)
  - `status_id`
  - `is_late`
