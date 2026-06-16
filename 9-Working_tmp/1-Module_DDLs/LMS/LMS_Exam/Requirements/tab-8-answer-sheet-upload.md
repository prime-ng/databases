# LMS Exam Tab 8: Answer Sheet Upload (Offline Exams)

This tab is used exclusively for offline exams. It allows teachers to upload scanned answer sheets, enter marks manually, or upload marks in bulk via Excel. The screen supports two modes depending on the paper's configuration — question-wise entry or bulk total entry.

---

## How It Works

The teacher first selects the class, section, subject, exam, paper, and paper set from the filter bar at the top. The screen then loads a list of all allocated students for that paper set. Each row shows the admission number, student name, attendance status (Present/Absent), and a "Checked" indicator.

The teacher marks each student as Present or Absent. For absent students, no further action is needed — they are recorded as Absent in the system.

### Mode 1: Question-Wise Entry
If the paper is configured with `offline_entry_mode = QUESTION_WISE`, clicking "Enter Marks" for a student opens a detailed form showing each question from the paper set. For each question, the teacher can upload a scanned answer sheet file (PDF/image) and/or enter the marks obtained. For MCQ questions, the teacher can enter the selected option. For descriptive questions, they can upload the answer file and later enter evaluated marks.

### Mode 2: Bulk Total Entry
If the paper is configured with `offline_entry_mode = BULK_TOTAL`, the teacher uploads a single answer sheet PDF per student and enters only the total marks obtained. Optionally, if `is_ques_wise_file_upload` is enabled, the teacher can still upload question-wise answer sheets but enters only the total marks.

The teacher can also use an "Upload Excel" button to batch-import marks for all students at once using a predefined Excel template.

---

## Important Business Rules

- Attendance must be marked before marks can be entered. Absent students are marked with zero marks and skipped in evaluation.
- Once marks are saved for a student, the "Checked" indicator turns green. Partial saves are allowed — the teacher can come back later.
- For question-wise mode, the sum of per-question marks must not exceed the paper's total_marks. A warning is shown if it exceeds.
- Uploaded answer sheet files are stored in the document management system; the database stores the file path reference.
- If marks are imported via Excel, the system validates the file against the paper set structure before accepting it.
- Marks once saved can be edited until the paper's result is published. After publication, changes require a grievance/override process.
- The screen design includes a "Question Paper" button to let the teacher view the original question paper for reference.
- This tab is hidden entirely for online exams.

---

## Database Columns & Behavior

### lms_exam_papers (configuration)
- `offline_entry_mode` — ENUM('BULK_TOTAL','QUESTION_WISE'), default 'QUESTION_WISE'. Determines the data entry UI.
- `is_ques_wise_file_upload` — TINYINT(1), nullable. Allows optional per-question file upload even in BULK_TOTAL mode.

### lms_exam_allocations (student listing)
- `student_id` — INT UNSIGNED FK to std_students.id. Used to load the student list for mark entry.

### lms_exam_paper_sets (question listing)
- Links to `lms_paper_set_questions` to show per-question mark entry fields.

### lms_paper_set_questions
- `question_id` — INT UNSIGNED FK to qns_questions_bank.id. Identifies the question for per-question mark entry.
- `override_marks` — DECIMAL(5,2). Used as the maximum marks for this question entry.
- `is_compulsory` — TINYINT(1). Determines if skipping this question is allowed.

---

## Deep Analysis

### Business Workflows & State Machines

The answer sheet upload workflow is exclusive to OFFLINE exams and follows this lifecycle per paper:

```
NOT_STARTED ──► IN_PROGRESS ──► EVALUATED ──► RESULT_PUBLISHED
                                           │
                                      (locked for edits)
```

- **NOT_STARTED:** No marks entered for any student. Attendance is unmarked.
- **IN_PROGRESS:** Attendance being marked and marks entered progressively. Partial saves are allowed — the teacher can leave and resume later.
- **EVALUATED:** All non-absent students have been marked. The paper is ready for result computation (Tab 9).
- **RESULT_PUBLISHED:** Marks are locked. Edits require a grievance/override process with audit logging.

Two parallel modes exist: **QUESTION_WISE** (per-question marks with optional file uploads) and **BULK_TOTAL** (single total marks per student, optional per-question file upload). The mode is set at the paper level via `offline_entry_mode`.

### Validation Rules & Edge Cases

- **Attendance prerequisite:** Marks cannot be entered for a student unless attendance (Present/Absent) is marked first. Absent students auto-receive zero marks and are skipped in evaluation.
- **Marks threshold check (question-wise):** The sum of per-question marks must not exceed the paper's `total_marks`. A warning is shown on excess — saving is allowed but flagged. The system should enforce: `SUM(marks) <= total_marks`.
- **Excel bulk import:** The uploaded Excel file must be validated against the paper set structure: column headers must match question ordinals/section names, row count must match allocated students, and all marks must be numeric. Invalid rows are reported with specific error messages.
- **File upload constraints:** Answer sheet files (PDF/images) are stored in the document management system (DMS); the DB stores only the file path. File size, format, and naming conventions follow DMS rules (not enforced here).
- **Post-publication lock:** After `is_result_published = 1` on the parent exam, marks in this paper become read-only. Any edit requires a grievance ticket and is logged as an override in `lms_exam_status_events`.
- **Edge case — all students absent:** If all students are marked Absent, the paper can still be moved to EVALUATED. Result computation will show zero scores for all students.
- **Tab visibility:** This tab is entirely hidden from the UI for ONLINE exams (`mode = ONLINE`). The router/frontend must check the exam type before rendering.

### Integration Points

- **FKs / References:** `lms_exam_papers.offline_entry_mode` — column read; `lms_exam_allocations.student_id` → `std_students.id` (student list); `lms_paper_set_questions.question_id` → `qns_questions_bank.id` (per-question entry fields).
- **Module dependencies:** LMS (papers, allocations, paper sets, paper set questions), STD (students), QNS (question bank).
- **Events emitted:** Marks saved events for audit trail. Paper status transition (→ EVALUATED) triggers a notification to Tab 9 for result readiness.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Mark attendance | Teacher | `lms.exam.attendance.mark` |
| Enter marks (question-wise) | Teacher | `lms.exam.marks.enter.questions` |
| Enter marks (bulk total) | Teacher | `lms.exam.marks.enter.bulk` |
| Upload marks via Excel | Teacher, Admin | `lms.exam.marks.upload.excel` |
| Upload answer sheet files | Teacher | `lms.exam.answersheet.upload` |
| Edit marks (before publish) | Teacher | `lms.exam.marks.edit` |
| Override marks (after publish) | Admin | `lms.exam.marks.override` |
| View marks | Teacher, Admin, Principal | `lms.exam.marks.view` |
| Mark paper as evaluated | Teacher, Admin | `lms.exam.paper.evaluate` |
