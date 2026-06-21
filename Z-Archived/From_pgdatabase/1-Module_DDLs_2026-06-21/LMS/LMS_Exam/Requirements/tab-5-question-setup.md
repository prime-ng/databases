# LMS Exam Tab 5: Question Setup

This tab allows the user to link questions from the central Question Bank to each paper set. For each paper set, the user selects which questions appear, in what order, with how many marks, and whether the question is compulsory or optional. This is the final step before the paper is ready for student allocation.

---

## How It Works

The user first selects a paper and then a paper set (e.g., Set A). The screen shows a list of blueprint sections defined in Tab 4. Below each section, there is an "Add Questions" button that opens the Question Bank browser.

The Question Bank browser displays available questions filtered by subject, topic, lesson, difficulty, and question type. The user selects questions one by one or in bulk and adds them to the section. For each added question, the user can override the default marks (from the question bank), set negative marks if applicable, mark it as compulsory or optional, and set the ordinal (sequence number) for display order.

Once questions are assigned, the screen shows a full preview of the paper set with all sections and questions in order. The user can reorder questions by dragging, toggle compulsory flags, and adjust marks inline.

---

## Important Business Rules

- A question can appear only once per paper set. The same question can appear in different sets (e.g., Set A and Set B) of the same paper.
- If `only_unused_questions` is enabled on the paper, the browser filters out questions that have been used in any previous exam (checked via `qns_question_usage_log`).
- If `only_authorised_questions` is enabled, only questions with `for_quiz = 1` are shown.
- Override marks at the question level replace the question bank's default marks for this exam only. The question bank is unaffected.
- Ordinal values determine display order. If two questions share the same ordinal, they are ordered by insertion date.
- A question marked as non-compulsory (is_compulsory = 0) means students can choose to skip it without penalty beyond lost marks.
- The total marks of all questions in a paper set should match the paper's total_marks. A warning is shown if they differ, but it does not block saving.
- Questions linked to a paper set that is already allocated to students cannot be removed — only deactivated.

---

## Database Columns & Behavior

### lms_paper_set_questions
- `id` — INT UNSIGNED PK. Auto-increment.
- `paper_set_id` — INT UNSIGNED FK to lms_exam_paper_sets.id. Identifies the paper set.
- `question_id` — INT UNSIGNED FK to qns_questions_bank.id. The question from the bank.
- `section_name` — VARCHAR(50), default 'Section A'. Which blueprint section this question belongs to.
- `exam_blueprint_id` — INT UNSIGNED FK to lms_exam_blueprints.id, nullable. Direct link to the blueprint section.
- `ordinal` — INT UNSIGNED. Sequence number within the paper set.
- `override_marks` — DECIMAL(5,2). Marks awarded for this question in this exam.
- `negative_marks` — DECIMAL(5,2), default 0. Negative marking for wrong answer.
- `is_compulsory` — TINYINT(1), default 1. Whether the student must attempt this question.
- `is_active` — TINYINT(1), default 1. Soft delete / disable flag.
- `created_at`, `updated_at`, `deleted_at` — Standard audit timestamps.

---

## Deep Analysis

### Business Workflows & State Machines

Question setup is a linking workflow between the Question Bank (`qns_questions_bank`) and paper sets (`lms_exam_paper_sets`). The lifecycle for a paper set's question assignment is:

```
PENDING ──► IN_PROGRESS ──► COMPLETED ──► LOCKED (after allocation)
```

- **PENDING:** No questions assigned yet. Blueprint sections exist but are empty.
- **IN_PROGRESS:** Questions are being added/removed/reordered. Marks can be overridden.
- **COMPLETED:** All blueprint sections have at least the minimum required questions. Total marks match the paper's `total_marks` (warning if not).
- **LOCKED:** The paper set has been allocated to students (Tab 6). Questions cannot be removed — only deactivated (`is_active = 0`). Marks can still be adjusted until result computation begins.

The question selection respects the paper's `only_unused_questions` and `only_authorised_questions` flags as filters against the Question Bank.

### Validation Rules & Edge Cases

- **Duplicate question prevention:** The UNIQUE KEY on `(paper_set_id, question_id)` prevents the same question from appearing twice in the same set. A clear error message must be shown: "This question is already assigned to this paper set."
- **Cross-set allowance:** The same question CAN appear in different sets (Set A and Set B) of the same paper. No cross-set uniqueness constraint exists.
- **Unused questions filter:** When `only_unused_questions = 1`, the Question Bank browser queries `qns_question_usage_log` to exclude previously used questions. This can be expensive for large question banks — consider a cached exclusion list.
- **Authorised questions filter:** When `only_authorised_questions = 1`, only questions with `qns_questions_bank.for_quiz = 1` are shown.
- **Marks mismatch warning:** If the sum of `override_marks` across all assigned questions does not equal the paper's `total_marks`, a warning is shown but saving is not blocked. The warning text: "Total assigned marks (X) differ from paper total marks (Y)."
- **Ordinal collision:** If two questions share the same `ordinal`, they are ordered by `created_at` (insertion order) as a tiebreaker.
- **Compulsory vs. optional:** A question with `is_compulsory = 0` means the student can skip it. In online exams, the UI must allow skipping; in offline exams, it is a teacher-side flag only.
- **Edge case — no blueprint sections:** If no blueprint sections exist (unlikely if Tab 4 is completed), the UI should show a message to design the blueprint first.
- **Deactivation after allocation:** Removing a question from an allocated paper set is not allowed. The `is_active` flag should be set to 0 instead, which hides it from the student's view but preserves the link.

### Integration Points

- **FKs:** `paper_set_id` → `lms_exam_paper_sets.id`, `question_id` → `qns_questions_bank.id`, `exam_blueprint_id` → `lms_exam_blueprints.id`.
- **Module dependencies:** LMS (paper sets, blueprints), QNS (question bank, question usage log).
- **Events emitted:** Question assignment events for audit. Marks override events logged for compliance.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Assign questions to paper set | Teacher, Admin | `lms.exam.questions.assign` |
| Remove questions from paper set | Teacher, Admin | `lms.exam.questions.remove` |
| Override question marks | Teacher, Admin | `lms.exam.questions.marks.override` |
| Toggle compulsory flag | Teacher, Admin | `lms.exam.questions.compulsory.toggle` |
| Reorder questions | Teacher, Admin | `lms.exam.questions.reorder` |
| Browse question bank | Teacher, Admin | `lms.exam.questions.browse` |
| View question setup | Teacher, Admin, Principal | `lms.exam.questions.view` |
