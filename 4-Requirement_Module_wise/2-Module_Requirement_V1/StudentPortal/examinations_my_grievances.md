# Examinations — My Grievances Tab Requirements

## 1. Functional Overview
Enables students to lodge complaints or disputes regarding online exam scores (e.g. marking errors, question errors, out-of-syllabus questions) and track their resolution status.

---

## 2. Page Structure & Parameters

### A. Grievance Tracking List
- Lists submitted grievances:
  - **Ticket ID**: Grievance ID.
  - **Exam Details**: Exam Name and Subject.
  - **Grievance Type**: Marking Error / Question Error / Out of Syllabus / Other.
  - **Status Badge**:
    - `OPEN` (Yellow)
    - `UNDER_REVIEW` (Orange)
    - `RESOLVED` (Green)
    - `REJECTED` (Red)
  - **Resolution Details**: Marks Changed (Old vs. New Marks), Resolution Remarks, and Date Resolved.

### B. File Grievance Form (Form Details)
- **Exam Result ID**: Auto-populated based on the selected result row.
- **Grievance Type**: Dropdown selection:
  - `MARKING_ERROR`
  - `QUESTION_ERROR`
  - `OUT_OF_SYLLABUS`
  - `OTHER`
- **Question Selection**: Optional dropdown listing all questions answered in that exam paper.
- **Description**: Textarea (min 20, max 2000 characters) to describe the issue.
- **Validations**: Limit of one grievance submission per exam result.

---

## 3. Database References
- **Model**: `Modules\StudentPortal\Models\ExamGrievance`
- **Table**: `lms_exam_grievances`
- **Fields**:
  - `exam_result_id`
  - `student_id`
  - `question_id`
  - `grievance_type`
  - `grievance_text`
  - `status`
  - `resolution_remarks`
  - `marks_changed`
  - `old_marks`
  - `new_marks`
  - `resolved_at`
