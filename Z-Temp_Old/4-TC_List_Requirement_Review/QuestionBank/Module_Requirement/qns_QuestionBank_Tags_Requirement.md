# Question Tags — Business Requirements

## What This Screen Does

The Question Tags screen is where teachers manage tag labels that can be attached to questions for better organisation and filtering. Think of tags like sticky labels — a question about "Photosynthesis" might have the tag "Biology-Chapter-3" or "Important-Concept". Tags make it easier to find questions by topic keywords later.

This screen shows a simple list of all tags with their short code and display name. Teachers can create new tags, edit existing ones, view details, and toggle them active/inactive. Deleted tags go to a Trash view where they can be restored or permanently deleted.

---

## When This Screen Is Used

- **Creating a New Tag** — When a teacher needs a new label for categorising questions
- **Editing a Tag** — To change a tag's short code or display name
- **Viewing Tag Details** — To see tag metadata; soft-deleted tags remain viewable (`show()` uses `withTrashed()`)
- **Deactivating a Tag** — Uses `toggleStatus()` which returns a JSON response with the new active state
- **Soft-Deleting and Restoring** — To temporarily remove a tag or bring it back

---

## Who Can Access This Screen

Access is controlled by Laravel Gates using `tenant.question_bank.viewAny`, `tenant.question_bank.create`, `tenant.question_bank.view`, `tenant.question_bank.update`, `tenant.question_bank.delete`, `tenant.question_bank.restore`, and `tenant.question_bank.forceDelete`. The `toggleStatus()` action uses the `.update` gate (no separate `.status` gate).

---

## How This Screen Works — Logic Flow (Non-Technical)

### The Tag List

The tag list is displayed within the Question Bank module (the dedicated `index()` route returns 404). The list shows columns for Short Name, Name, Active status toggle, and Action buttons (View, Edit, Delete). Search and filtering are NOT implemented.

### Creating a Tag

When the teacher clicks "Add Tag," a form opens with two fields:
- **Short Code** — A unique abbreviation for the tag (e.g., "BIO-CH3")
- **Display Name** — The full tag name visible to teachers (e.g., "Biology Chapter 3")

The short code must be unique across all tags. On save, the controller creates an activity log entry and redirects to the Question Bank index. The `is_active` column is mass-assignable (in `$fillable`) but has no validation rule in the Request.

### Editing a Tag

When editing, the form pre-fills the existing short code and name. The short code uniqueness check excludes the current tag's own ID. On save, an activity log entry is created and the user is redirected to the Question Bank index.

### Soft-Deleting and Restoring

When a teacher deletes a tag, the controller first sets `is_active = false`, saves, then calls `delete()` (soft-delete). The teacher can restore it from the Trash page. Note: `restore()` does NOT revert `is_active` to `true` — use `toggleStatus()` for that. Force-deleting permanently removes the tag from the database (no cascade cleanup of junction records). All these actions create an activity log entry and redirect to the Question Bank index.

### Toggling Active Status

The `toggleStatus()` action flips the `is_active` boolean. It uses the `tenant.question_bank.update` gate and returns a JSON response:
```json
{
  "success": true,
  "is_active": true,
  "message": "Status updated successfully."
}
```

---

## Validate Before Save

| Field | Rule |
|-------|------|
| short_name | Required, text, max 100 characters, must be unique |
| name | Required, text, max 255 characters |

---

## Business Rules and Conditions

### Rule 1: Unique Short Code
Each tag must have a unique short code. On update, the current tag's ID is excluded from the uniqueness check.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Unique Short Code | No two tags can have the same short code |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing short name | "Short name is required." |
| Duplicate short code | "This short name already exists." |
| Missing display name | "Name is required." |

---

## Success Scenarios

- A teacher creates a new tag: Short Code = "PHY-MOTION", Name = "Physics Motion Questions". The tag appears in the list.

---

## Failure Scenarios

- A teacher tries to create a tag with short code "PHY-MOTION" that already exists. The system rejects with "This short name already exists."

---

## Example Scenario

Mr. Patel wants to tag all his Physics questions about Motion so he can find them easily later. He opens the Question Tags tab, clicks "Add Tag", enters Short Code = "PHY-MOTION" and Name = "Physics — Motion Concepts", and saves. The tag is now available for use.

---

## Related Screens

- **Question Bank** — Where tags are attached to questions during creation/editing
- **Question Versions** — Read-only version history
- **Question Statistics** — Question performance metrics

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank | `qns_question_tags` (primary table), `qns_question_questiontag_jnt` (junction with questions) |
