# Quest Summary & Paper Check — Business Requirements

## What This Screen Does

The Quest Summary screen tracks the live progress of an assigned Quest. It shows teachers exactly how their class is performing — who has started, who has submitted, who needs to be graded, and what the overall scores look like.

The screen has two main parts:
1. **Summary Grid** — A table of all allocations showing real-time stats (in progress, submitted, checked counts)
2. **Paper Check Interface** — A dedicated page for teachers to manually grade subjective answers (essays, file uploads) and finalize results

Think of it like a teacher's grade book: the Summary gives the overview of all students in a class, and the Paper Check is where the teacher sits down with each student's paper to award marks and write feedback.

---

## When This Screen Is Used

- **Monitoring Live Progress** — During an assessment, teachers check who has started and who has submitted
- **Post-Assessment Grading** — After the due date, teachers use Paper Check to manually evaluate subjective questions
- **Finalizing Results** — Teachers grade submissions, compute percentages, and publish results
- **Checking Student Answers** — Teachers review individual student answers and provide feedback

---

## Default Data Load

The Summary tab loads within the main Quests `index()` method. When the summary tab is active, the system loads:

| What Loads | Source | Notes |
|------------|--------|-------|
| All Allocations (paginated) | `QuestAllocation::with(['quest', 'assigner'])` | With dynamic counts for each allocation |
| Submitted Count | `attempts` where status IN ('SUBMITTED','EVALUATED','RESULT_PUBLISHED','TIMEOUT') | via withCount |
| In Progress Count | `attempts` where status = 'IN_PROGRESS' | via withCount |
| Checked Count | `attempts` where `answers.evaluated_by IS NOT NULL` | via withCount + whereHas |
| Total Assigned | Dynamic: CLASS → count students in class, SECTION → count students in section, STUDENT → 1 | Calculated per allocation on the page |
| Filters | search, class_section_id, subject_id, date_from, date_to | Applied to quest → subject/class |

---

## Key Fields at a Glance

### Summary Grid (per allocation row)

| Column | What It Shows |
|--------|--------------|
| Quest | Title and code |
| Class / Section | Target group (resolved from allocation type) |
| Assigned To | How many students are in the target group |
| In Progress | How many students are currently attempting |
| Submitted | How many have completed (SUBMITTED, EVALUATED, RESULT_PUBLISHED, TIMEOUT) |
| Checked | How many have been graded (evaluated_by is not null) |
| Status | Active/Inactive toggle |
| Actions | View, Check Paper, etc. |

### Paper Check Per-Student View

When a teacher opens the Paper Check for a specific attempt, they see:
- **Student Info** — Name, class, section
- **Attempt Info** — Status (IN_PROGRESS, SUBMITTED, TIMEOUT, EVALUATED), time taken, submitted at
- **Question-by-Question Breakdown** — Each question shows:
  - Question number (ordinal)
  - Question text
  - Marks obtained / Max marks
  - Correct/incorrect flag
  - File attachment (if student uploaded a file)
- **Result Summary** — Total marks obtained, max marks, percentage, pass/fail, teacher remarks
- **Grading Controls** — Input fields for marks, dropdown for correct/incorrect/partial, comment box, publish toggle

---

## Business Rules and Conditions

### Rule 1: Summary Data Is Per-Allocation
The summary grid is structured around `lms_quest_allocations`, not individual students. Each row represents one allocation (e.g., "Physics Challenge → Class 10A"). Student counts are aggregated within each allocation.

### Rule 2: Assigned Count Depends on Allocation Type
- **CLASS**: Counts students in `std_student_academic_sessions` where class_id matches and is_current = 1
- **SECTION**: Counts students where class_section_id matches and is_current = 1
- **STUDENT**: Always 1 (individual student)

### Rule 3: Checked Count Uses Answer-Level Check
An attempt is considered "checked" if ANY of its answers have `evaluated_by IS NOT NULL`. This means partial grading (some questions graded, some not) still counts as checked.

### Rule 4: Marks Cannot Exceed Max Marks
When grading (via `gradeSubmission` or `saveAnswerGrade`), the system validates that `marks_obtained ≤ max_marks` for each question and for the overall submission.

### Rule 5: Percentage and Grade Letter Calculation
When a teacher grades a submission:
1. Percentage = `(total_marks_obtained / max_marks) * 100`
2. Grade letter is calculated based on percentage (using `calculateGrade()` method)
3. Pass/fail determined by comparing percentage to the Quest's `passing_percentage`
4. Attempt status updated to `EVALUATED`
5. Result record is upserted into `lms_quiz_quest_results`

### Rule 6: Result Publishing Triggers Events
When `is_published` is true during grading, two things happen:
1. The `QuizQuestResultPublished` event is dispatched (triggers the recommendation engine)
2. The result's `published_at` timestamp is set

### Rule 7: Answer Sync via JSON
The `gradeSubmission` endpoint accepts an `answers_json` field containing the complete grading state from the frontend. Each answer in this JSON is synced using `updateOrCreate` on `QuizQuestAttemptAnswer`, keyed by `attempt_id + question_id`.

### Rule 8: Annotated PDF Upload
Teachers can upload an annotated PDF when grading. The file is stored using the storage service's dynamic path builder:
`{session_code}/{class_id}-{section_id}/{quest_id}/{student_id}/teacher/`
The file URL is returned in the grading response.

### Rule 9: SECTION Filter Resolution for Summary
When filtering by class_section_id, allocations are matched using OR conditions:
- SECTION type → target_id matches the section
- CLASS type → target_id matches the section's parent class
- STUDENT type → target_id IN (students enrolled in the section)

### Rule 10: Paper Check Route Uses Quest ID, Not Allocation ID
The `questPaperCheck` method takes a Quest ID (not allocation ID) and shows ALL attempts for that Quest across all allocations. The teacher then selects a specific student to grade.

---

## Workflow Steps

### Viewing the Summary
1. Teacher navigates to Quests and clicks the "Quest Summary" tab
2. The grid shows all allocations with aggregated stats
3. Teacher can filter by Class/Section, Subject, or date range
4. Teacher can search by Quest title or code

### Using Paper Check
1. Teacher clicks "Check Paper" on an allocation from the Summary grid
2. The Paper Check page loads the Quest details and a student list with attempt statuses
3. Teacher selects a student from the list (or via student_id query parameter)
4. The system loads the student's attempt data via AJAX:
   - Attempt info (status, score, time taken)
   - Result info (if already graded)
   - All answers with marks, file URLs
5. Teacher reviews each question:
   - For subjective questions: views file attachment (if any), enters marks, selects status (correct/incorrect/partial), adds comments
   - For objective questions: marks may be auto-assigned already
6. Teacher can update individual question marks using `saveAnswerGrade` (AJAX)
7. Teacher clicks "Grade Submission" to finalize:
   - Enters total marks obtained (or uses the accumulated per-question marks from `answers_json`)
   - Optionally enters teacher remarks
   - Optionally uploads an annotated PDF
   - Optionally checks "Publish" to release results to the student
8. System validates marks ≤ max marks, calculates percentage, determines pass/fail, upserts result
9. Success response includes percentage, pass/fail status, and annotated PDF URL

### Grading a Single Question (AJAX)
1. Teacher changes marks for one question on the Paper Check page
2. AJAX request (`saveAnswerGrade`) sends attempt_id, marks_obtained, ordinal, optional question_id
3. System validates marks_obtained ≤ max_marks for that question
4. Updates or creates the `QuizQuestAttemptAnswer` record
5. Returns success response

---

## Example Scenario

Mrs. Sharma has allocated "Physics Challenge" to Class 10A with a due date of last Friday. She now wants to check progress and grade submissions.

She opens the Quest Summary tab and sees:
- **Physics Challenge → Class 10A**: 30 students assigned, 2 in progress, 25 submitted, 0 checked

She clicks "Check Paper" and sees a list of 30 students. She selects "Rahul Kumar" who has submitted.

The Paper Check interface loads:
- Rahul's attempt: Submitted, 3 minutes ago, 18/20 questions answered
- 2 file uploads (subjective questions)
- 18 auto-graded MCQ questions (scores shown)

Mrs. Sharma reviews the file uploads:
1. Question 7 (Essay, 5 marks): She reads Rahul's answer, enters 4 marks, marks as "partial", writes a comment ("Good explanation, missed one point")
2. Question 14 (Diagram, 10 marks): She views the uploaded image, enters 8 marks, marks as "correct"

She clicks "Grade Submission":
- Total marks: 82 / 100
- She adds teacher remarks: "Well done! Practice diagram labeling."
- She checks "Publish"
- The system saves, calculates 82%, marks as PASS, publishes the result
- Rahul can now see his grade on the student portal

---

## Related Screens

- **Quest Allocation** — Where Quests are deployed to students (creates the allocations shown in Summary)
- **Quest Dashboard** — Where aggregate metrics (including submission counts) are displayed
- **Student Portal** — Where students see their grades after publication
- **Activity Log** — Where suspicious behavior during attempts is tracked

---

## Requirements

**Controller Methods:** All within `Modules\LmsQuests\Http\Controllers\LmsQuestController`

- `index()` — Loads the Summary grid data within the main tabbed view (allocations with student counts)
- `questPaperCheck(Request, $id)` — Loads Paper Check page with Quest data, all attempts, and results
- `getStudentAttemptData(Request, $questId)` — AJAX: returns attempt details, result, and all answers for a student
- `gradeSubmission(Request, $questId)` — AJAX: grades entire submission, syncs answers, upserts result, dispatches event
- `saveAnswerGrade(Request, $questId)` — AJAX: grades a single question, validates marks

**Models Used:**
- `QuestAllocation` (summary grid source)
- `QuizQuestAttempt` (attempt tracking, status)
- `QuizQuestAttemptAnswer` (per-question grading)
- `QuizQuestResult` (final result with percentage)
- `QuestQuestion` (question/ordinal resolution)
- `Quest` (passing_percentage, quest details)

**Events:**
- `QuizQuestResultPublished` — Dispatched when result is published

**Dependencies:**
- `LmsStorageService` — For file URL resolution and annotated PDF storage
- `GradeLetter` calculation — Maps percentage to letter grade

---

## Who Can Access This Screen

- **Teacher** — Can view summary and grade their own allocations
- **Head of Department** — Can view and grade across their department
- **Academic Coordinator** — Full access to all summary data

Access gated by `tenant.quest.viewAny` (view summary) and `tenant.quest.update` (grade submissions).

---

## How This Screen Works — Logic Flow (Non-Technical)

### Summary Grid

The system queries all Quest Allocations and for each one, counts how many students are in the target group, how many have started (in progress), how many have submitted, and how many have been graded. These counts use a technique called "withCount" which calculates them in the database without making separate queries for each row.

The "Assigned To" count is the most complex: the system has to look up actual student enrollment data. For a CLASS allocation, it counts students in that class who are currently enrolled. For a SECTION allocation, it counts students in that specific section. For a STUDENT allocation, it's always 1.

The "Checked" count checks whether any teacher has marked any answer as evaluated. This means if a teacher has graded even one question of a student's attempt, that attempt counts as "checked."

### Paper Check Interface

When a teacher clicks "Check Paper," they see the Quest's questions (in order) and a list of students who were allocated this Quest. Selecting a student loads their attempt data: what they answered, how many marks they got for auto-graded questions, and any file attachments they uploaded for subjective questions.

The teacher reviews each answer. For file uploads, the system generates a secure URL so the teacher can view the file directly in the browser. The teacher enters marks for each subjective question, selects a status (correct/incorrect/partial), and optionally writes a comment.

The teacher can save individual question grades immediately via AJAX (each question is saved as a separate API call in the background). When all questions are graded, the teacher clicks "Grade Submission" to finalize the overall result.

At this point, the system:
1. Validates that marks don't exceed max marks
2. Calculates the percentage
3. Determines the grade letter
4. Checks if the student passed (percentage >= passing_percentage)
5. If publishing, marks the result as published and dispatches an event

The teacher can also upload an annotated PDF — a marked-up version of the student's work. This is stored in a structured folder path and a URL is returned so the teacher can view or share it.

---

## Validate Before Save

### `gradeSubmission` Validation
1. **attempt_id** — required, integer, must exist in `lms_quiz_quest_attempts`
2. **marks_obtained** — required, numeric, min:0
3. **max_marks** — required, numeric, min:0
4. **teacher_remarks** — nullable, string, max:2000
5. **is_published** — boolean
6. **annotated_pdf** — nullable, file, mimes:pdf, max:51200 (50MB)
7. **answers_json** — nullable, string (JSON)
8. **question_id** — nullable, integer
9. **ordinal** — nullable, integer, min:1

### `saveAnswerGrade` Validation
1. **attempt_id** — required, exists:lms_quiz_quest_attempts,id
2. **marks_obtained** — required, numeric, min:0
3. **ordinal** — required, integer
4. **evaluation_remarks** — nullable, string
5. **question_id** — nullable, integer (for resolving the quest question)

---

## Error Handling and Validation Messages

| Scenario | Error Message |
|----------|--------------|
| Marks exceed max (per question) | "Marks cannot exceed max marks for this question." |
| Marks exceed max (submission) | Validated before saving; generic exception on failure |
| No attempt found | "No attempt found." |
| Invalid attempt_id | Laravel validation "The selected attempt id is invalid." |
| File too large | "The annotated pdf must not be greater than 51200 kilobytes." |
| Invalid file type | "The annotated pdf must be a file of type: pdf." |

---

## Success Scenarios

- A teacher grades 30 student submissions for "Physics Challenge" — 25 auto-graded MCQs and 5 subjective questions. They review each student's file uploads, enter marks, and publish all results. All 30 students see their grades immediately.

- A teacher uses the per-question AJAX grading (`saveAnswerGrade`) to grade one essay question at a time across all students. After grading all questions, they finalize with `gradeSubmission`.

---

## Failure Scenarios

- A teacher enters 15 marks for a question worth 10 marks. The AJAX validation rejects with "Marks cannot exceed max marks for this question."

- A teacher tries to publish a result with `is_published = true` but the student's attempt is still IN_PROGRESS. The system allows this (no validation prevents grading an in-progress attempt), which could result in publishing a partially-completed assessment.

---

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| LmsQuests Core | `lms_quests`, `lms_quest_questions`, `lms_quest_allocations` |
| Student Portal | `sp_quiz_quest_attempts`, `sp_quiz_quest_attempt_answers`, `sp_quiz_quest_results` |
| Student Management | `std_students`, `std_student_academic_sessions` (for assigned counts) |
| Academic Setup | `sch_classes`, `sch_class_sections`, `sch_sections` |
| Prime Storage | `LmsStorageService` (for file URLs and annotated PDF storage) |
| Recommendations | `QuizQuestResultPublished` event (dispatched on publish) |
