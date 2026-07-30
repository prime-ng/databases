# Question Usage Type — Business Requirements

## What This Screen Does

The Question Usage Type screen is where administrators define the different types of assessments that can use questions from the question bank. By default, the system comes with four usage types: Quiz, Quest, Online Exam, and Offline Exam. These types control which questions appear in which assessment builder's question picker.

Each usage type has a unique code (e.g., QUIZ, QUEST, ONLINE_EXAM), a display name, and an optional description. Teachers see these names when they create questions and select which assessment types the question should be available for.

---

## When This Screen Is Used

- **Initial System Setup** — The four default types are pre-seeded in the database
- **Adding a New Assessment Type** — If a school introduces a new type of assessment
- **Editing an Existing Type** — To change the display name or description
- **Deactivating a Type** — To stop a type from being available for new questions
- **Soft-Deleting and Restoring** — To temporarily remove a type or bring it back

---

## Who Can Access This Screen

- **School Admin** — Full CRUD access
- **Head of Department** — Can view usage types
- **Teacher** — Read-only (types are used when creating questions)

All access is controlled by permissions like `tenant.question_bank.viewAny`, `tenant.question_bank.create`, `tenant.question_bank.update`, `tenant.question_bank.delete`, `tenant.question_bank.restore`, `tenant.question_bank.forceDelete`, `tenant.question_bank.view`.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Usage Type List

The dedicated index route is disabled (returns 404). Listing usage types is available only through the QuestionBank tab module via `getQuestionUsageTypeQuery()`.

### Creating a Usage Type

When the admin clicks "Add Usage Type," a form opens with:
- **Code** — A unique system code (e.g., "PRACTICE_TEST"), must be unique
- **Name** — Display name (e.g., "Practice Test"), must be unique
- **Description** — Optional explanation of the type

### Editing a Usage Type

When editing, the uniqueness checks for both code and name exclude the current record's own ID. The `is_active` field is handled manually via `$request->boolean('is_active')` in the controller's `update()` method, not through `$request->validated()`.

### Deleting

Usage types can be soft-deleted. Since they are referenced by `qns_question_usage_log` and the `for_quiz`, `for_quest`, `for_exam`, `for_offline_exam` flags on questions, deleting a type does not affect existing question flags but stops it from appearing in dropdowns.

---

## Validate Before Save

| Field | Rule |
|-------|------|
| code | Required, text, max 100 characters, must be unique |
| name | Required, text, max 255 characters, must be unique |
| description | Optional, text |

---

## Business Rules and Conditions

### Rule 1: Unique Code and Name
Each usage type must have a unique code and a unique name. On update, the current record's ID is excluded from both uniqueness checks.

### Rule 2: Pre-Seeded Defaults
The system comes with four pre-seeded usage types: QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM. These cannot be deleted if referenced by usage logs.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Unique Code | Each type has a unique system code |
| Unique Name | Each type has a unique display name |
| Pre-Seeded | Quiz, Quest, Online Exam, Offline Exam come pre-loaded |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing code | "The code field is required." |
| Duplicate code | "The code has already been taken." |
| Missing name | "The name field is required." |
| Duplicate name | "The name has already been taken." |

---

## Success Scenarios

- An admin creates a new usage type: Code = "PRACTICE_TEST", Name = "Practice Test", Description = "Low-stakes practice assessments". The type appears in the list and becomes available when creating questions.

---

## Related Screens

- **Question Bank** — Where questions have usage type checkboxes (for_quiz, for_quest, etc.)
- **Question Usage Log** — Where usage logs track which type used each question

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank | `qns_question_usage_type` (primary table) |
| Usage Log | `qns_question_usage_log` (FK to usage_type_id) |
