# Question Versions — Business Requirements

## What This Screen Does

The Question Versions screen shows the history of changes made to a question. Whenever a teacher edits a question's content, options, marks, negative marks, or question type, the system automatically saves a full snapshot of the question's previous state before applying the changes. This allows teachers to see what changed, when it changed, and who made the change.

Each version record contains a complete JSON snapshot of the question (question text, options, marks, metadata), the version number, who created the version, and an optional change reason.

---

## When This Screen Is Used

- **Tracking Changes** — To see what was modified in a question over time
- **Audit Trail** — To review who changed a question and why
- **Rollback Reference** — To understand the previous state before deciding to revert (rollback is not directly implemented — the snapshot serves as reference)
- **Compliance** — To maintain a history of question changes for quality assurance

Version snapshots are created automatically on every content edit. Pure status changes (e.g., DRAFT → IN_REVIEW) do not trigger a snapshot.

---

## Who Can Access This Screen

- **Teacher** — Can view version history for questions they have access to
- **Head of Department** — Full access
- **School Admin** — Full access

All access is controlled by permissions under the `tenant.question_bank.*` namespace (`viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`) since versions are tied to question viewing. The server checks these permissions on every action.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Version List

The dedicated index route is disabled (returns 404). Listing versions is available only through the QuestionBank tab module. Each record shows: the question title (linked to the question view), version number, change reason (if provided), who created the version, and when it was created.

### Viewing Version Details

Clicking a version record opens a detail view showing the full JSON snapshot of the question state at that version. This includes all question fields, options data, and metadata captured at the time of the snapshot.

### Automatic Snapshot Creation

When a teacher saves an edit that changes any content field (question_content, content_format, marks, negative_marks, question_type_id, or any option text/correct-answer/explanation), the system:
1. Reads the current state of the question and all its options
2. Serialises the full data into JSON
3. Creates a new record in `qns_question_versions` with incremented version number
4. Then applies the edit to the question

If the edit only changes the status field (e.g., DRAFT → IN_REVIEW), no snapshot is created.

---

## Validate Before Save

Version records are created automatically by the system, not through a user form. When creating via the API/FormRequest:

| Field | Rule |
|-------|------|
| question_bank_id | Required, must exist in the questions bank table |
| version | Required, whole number, minimum 1 |
| data | Required, must be valid JSON |
| version_created_by | Optional, must exist in users table |
| change_reason | Optional, text, max 255 characters |
| is_active | Optional, yes/no |

---

## Business Rules and Conditions

### Rule 1: Automatic Snapshot on Content Change
A version snapshot is created before any edit that modifies question_content, content_format, marks, negative_marks, question_type_id, or any option (text, is_correct, explanation). Pure status changes do not trigger a snapshot.

### Rule 2: Version Number Increment
Each new snapshot for the same question increments the version number by 1. The combination of question_bank_id + version is unique.

### Rule 3: Full CRUD Available
Version records expose full CRUD (create, edit, update, soft-delete, restore, force-delete, toggle-status) via dedicated routes. The version data is not immutable.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Auto Snapshot | Content edits auto-save a before-state snapshot |
| Version Increment | Each edit increases version by 1 |
| CRUD Available | Version records can be created, edited, and deleted via the UI |
| Status Change Only | No snapshot created for pure status changes |

---

## Success Scenarios

- A teacher edits a question's marks from 4.00 to 5.00 and changes the content. Before the save, the system creates version 2 with the full previous state (marks = 4.00, original content, all options). The teacher can later view version 2 to see what the question looked like before the edit.

---

## Example Scenario

Mr. Khan creates a question with ID = 205. The system creates it with current_version = 1. Later, he edits the question to fix a typo in the question content. The system takes a snapshot of version 1 (the state before the edit), saves it as version 1 in the versions table, then applies the edit. The question now has current_version = 2. Mr. Khan opens the Question Versions tab, sees version 1 with its snapshot, and can view the original question content.

---

## Related Screens

- **Question Bank** — Where question edits trigger version snapshots
- **Question Review** — Where review decisions are logged separately

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank | `qns_questions_bank` (FK → question_bank_id), `qns_question_versions` (primary table), `qns_question_options` (option data included in snapshot) |
