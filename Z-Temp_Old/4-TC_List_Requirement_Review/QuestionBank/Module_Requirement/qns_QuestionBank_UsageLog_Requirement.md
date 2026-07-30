# Question Usage Log — Business Requirements

## What This Screen Does

The Question Usage Log screen tracks which assessments have used which questions. Every time a question is included in a quiz, quest, or exam, a usage log entry is created. This helps teachers understand how often a question has been deployed and in which contexts.

Each usage log entry records: the question used, the type of assessment (Quiz, Quest, Online Exam, or Offline Exam — from the usage type master), the specific assessment's ID, and when it was used.

---

## When This Screen Is Used

- **Tracking Question Usage** — To see which questions have been used in which assessments
- **Checking Unused Questions** — To find questions that have never been deployed
- **Audit Trail** — To maintain a record of question deployment for quality assurance
- **Unused Question Filter** — The "Only Unused Questions" toggle in assessment builders checks this log to exclude already-used questions

---

## Who Can Access This Screen

- **Teacher** — Can view usage logs for their questions
- **Head of Department** — Full access
- **School Admin** — Full access
- **Principal** — Read-only

Access: the usage log tab is part of the Question Bank index page (gated by `tenant.question-bank.viewAny`), and the status toggle uses `tenant.question-bank.update`. There are no dedicated `question-usage-log.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Usage Log List

The Question Usage Log is a tab within the Question Bank index page (no dedicated controller or CRUD routes). When selected, the system shows a paginated list of all usage log entries. Each row shows: the question title (linked to the question view), usage type (Quiz, Quest, Online Exam, Offline Exam), context ID (the specific assessment's ID), when it was used, and an Active status toggle.

### Automatic Logging

Usage log entries are created automatically when questions are included in assessments by the consuming modules (LmsQuiz, LmsQuests, LmsExam). The log records which question, which type of assessment, and which specific assessment instance.

### Status Toggle

Teachers can toggle the active status of a usage log entry, though this is primarily a display-level control and does not affect the actual usage tracking for the "unused questions" filter.

---

## Business Rules and Conditions

### Rule 1: Automatic Logging
Usage log entries are created by consuming modules (Quiz, Quest, Exam) when a question is included in an assessment. The teacher does not manually create log entries from this screen.

### Rule 2: Context Tracking
Each log entry tracks the specific assessment context (quiz_id, quest_id, or exam_id) so teachers can trace exactly where a question was used.

### Rule 3: Cascade on Question Delete
When a question is force-deleted, its usage log entries are also deleted (CASCADE from the foreign key).

### Rule 4: `scopeContext()` Filter Mismatch (Known Gap)
The `scopeContext($query, $context)` scope filters by `question_usage_type_id`, expecting an ID. However, the blade UI sends usage type *codes* (e.g., `quiz`, `quest`), creating a type mismatch that breaks filtering. This must be resolved either by resolving codes to IDs before calling the scope, or by modifying the scope to accept codes.

### Rule 5: `scopeActive()` Scope
The model provides `scopeActive($query)` which filters `WHERE is_active = true`. This is used internally but not exposed in the current tab UI.

### Rule 6: `scopeForContextId()` Scope
The model provides `scopeForContextId($query, int $contextId)` to filter by a specific assessment context ID (quiz_id, quest_id, or exam_id).

### Rule 7: `resolveUsageTypeId()` Helper
The static method `resolveUsageTypeId(string $code): ?int` converts a usage type code (e.g., `quiz`) to its corresponding `question_usage_type_id`. This can fix the scopeContext mismatch in Rule 4.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Auto-Logging | Consuming modules create log entries automatically |
| Context Tracking | Each entry records which specific assessment used the question |
| Cascade | Force-deleting a question removes its usage logs |
| scopeContext Mismatch | Blades sends codes, scope expects IDs — broken filter |
| scopeActive | `WHERE is_active = true` convenience scope |
| scopeForContextId | Filter logs by a specific assessment context ID |
| resolveUsageTypeId | Converts usage type codes to IDs |

---

## Success Scenarios

- A teacher opens the Question Usage Log and sees that question #102 (Photosynthesis) has been used in: Quiz "Science Quiz 1" (QUIZ type, 2 times) and Quest "Biology Practice" (QUEST type, 1 time).

---

## Related Screens

- **Question Bank** — Where question usage is summarised in the detail view
- **Question Usage Type** — Where the usage type master data is managed

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank Core | `qns_question_usage_log` (primary table) |
| Usage Type | `qns_question_usage_type` (FK → question_usage_type_id) |
| LmsQuiz | `quz_quizzes` (context source) |
| LmsQuests | `lms_quests` (context source) |
| LmsExam | `exm_exams` (context source) |
