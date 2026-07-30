# Template Purpose Registry — Business Requirements

## What This Screen Does

The Template Purpose Registry is where school administrators manage the list of functional output purposes that a school's template system supports. Think of each purpose as a label that tells the system what a template is meant to produce — a report card, an ID card, a fee receipt, an admit card, or a merit certificate. Every template in the school must be assigned to a purpose, and the purpose determines where and how the template can be used.

The screen shows all purposes in a list view with a filter to narrow down by scope type (Class-Scoped or School-Wide). Administrators can create new custom purposes, edit existing ones, turn their active status on or off, and remove purposes they no longer need. Six standard purposes come pre-loaded with the system and are protected from deletion and certain edits.

---

## When This Screen Is Used

- **Creating a Custom Purpose** — When a school needs a new template category not covered by the built-in purposes (e.g., "LIBRARY_CARD" or "BUS_PASS")
- **Editing a Purpose** — When a purpose's display name, description, or display order needs to be updated
- **Viewing Purposes** — To review the full list of registered purposes and their scope types
- **Filtering by Scope Type** — To see only Class-Scoped or only School-Wide purposes
- **Removing a Purpose** — To soft-delete a custom purpose that is no longer needed
- **Activating or Deactivating a Purpose** — To turn a purpose on or off so it appears or disappears from dropdown lists across the system

---

## Who Can Access This Screen

- **School Admin** — Full access including create, edit, toggle status, and remove purposes
- **Principal** — Read-only access to view the purpose registry

The system checks the user's permissions before every action to ensure only authorised staff can perform each operation.

---

## How This Screen Works — Step by Step

### The Purpose List

When an administrator opens the Template Purpose Registry, the system shows a list of all purposes (20 per page) with columns: #, Purpose Code (machine-readable, unique identifier), Purpose Name (human-readable display name), Description, Scope Type (Class-Scoped or School-Wide), Display Order, Active toggle, and Actions (Edit, Delete). A filter panel above the list lets administrators narrow down by Scope Type (All / Class-Scoped / School-Wide).

The pre-loaded system purposes are visually distinguished (e.g., with a "System" badge) so administrators know which records are protected. The list sorts purposes by Display Order by default.

### Creating a Purpose

When the administrator clicks "Add Purpose," they see a single-page form with the following fields:

- **Purpose Code** (required) — A machine-readable identifier (e.g., `LIBRARY_CARD`). Must be unique across all purposes, including deleted ones. System-generated codes use uppercase letters and underscores only. Cannot be changed after creation.
- **Purpose Name** (required) — A human-readable display name (e.g., "Library Card"). Up to 100 characters.
- **Description** (optional) — A brief explanation of what this purpose is used for. Up to 255 characters.
- **Scope Type** (required) — Either "Class-Scoped" (templates target specific classes) or "School-Wide" (templates apply to the whole school). Defaults to School-Wide.
- **Display Order** (required, numeric) — Controls the sorting position in dropdown lists. System purposes occupy 1–6; custom purposes can be assigned any integer above 6.
- **Active** (toggle, defaults to On) — Whether the purpose is active and available for selection.

When the administrator clicks "Save," the system checks all fields, validates uniqueness of the code, creates the purpose record, and returns to the list with a success message.

### Editing a Purpose

The edit form opens with all existing values pre-filled. For system purposes, the Purpose Code and Scope Type fields are locked (greyed out) and cannot be changed. For custom purposes, all fields except Purpose Code are editable. The Purpose Code is never editable after creation. Every change is recorded with a timestamp.

### Toggle Active Status

Administrators can turn a purpose's active status on or off directly from the list view without reloading the page. When a purpose is deactivated, all templates assigned to that purpose remain in the system but the purpose does not appear in dropdown lists for new template assignments. Each change is saved with a timestamp.

### Removing a Purpose

When an administrator removes a purpose, the system checks whether it is a system purpose:

- **System Purposes** (MARKSHEET_PRINT, STUDENT_ID_CARD, STAFF_ID_CARD, FEE_RECEIPT, ADMIT_CARD, MERIT_CERTIFICATE) — Removal is blocked entirely. The administrator sees a message that system purposes cannot be removed.
- **Custom Purposes** — The purpose is soft-deleted (hidden from the active list but retained in the database). All scope assignments linked to this purpose are also soft-deleted (cascaded deactivation). The record can be restored from a Trash view if available.

### Permanently Deleting a Purpose

When an administrator permanently deletes a purpose from the Trash:
- **System Purposes** — Permanent deletion is blocked.
- **Custom Purposes** — The record and all its related scope assignments are permanently removed from the system. This action cannot be undone.

---

## Validation Rules — What's Required Before Saving

| Field | Rule |
|-------|------|
| Purpose Code | Required, uppercase letters and underscores only, 2–50 characters, must be unique across all purposes (including deleted records), cannot be changed after creation |
| Purpose Name | Required, up to 100 characters |
| Description | Optional, up to 255 characters |
| Scope Type | Required, must be either "Class-Scoped" or "School-Wide" |
| Display Order | Required, must be a positive integer |
| Active | Optional, can be Yes or No |

---

## Business Rules and Conditions

### Rule BR-TMP-001: Purpose Code Must Be Unique
Each purpose code must be unique across all purposes (both active and deleted). This check applies on create. The code cannot be changed after the purpose is created, so no uniqueness check is needed on edit.

### Rule BR-TMP-002: System Purposes Cannot Have Code or Scope Changed
The six pre-loaded system purposes — MARKSHEET_PRINT, STUDENT_ID_CARD, STAFF_ID_CARD, FEE_RECEIPT, ADMIT_CARD, MERIT_CERTIFICATE — have their Purpose Code and Scope Type permanently locked. Attempting to edit these fields is blocked; the edit form disables them.

### Rule BR-TMP-003: System Purposes Cannot Be Removed or Permanently Deleted
System purposes are protected from both soft-deletion and permanent deletion. Any attempt to remove or permanently delete a system purpose is blocked with a clear warning message.

### Rule BR-TMP-004: Deleting a Custom Purpose Cascades to Scope Assignments
When a custom purpose is soft-deleted, all template-purpose scope assignments linked to that purpose are also soft-deactivated. When a custom purpose is permanently deleted, all related scope assignments are permanently removed.

### Rule BR-TMP-005: Display Order Controls Sorting
Purposes are sorted by Display Order in ascending order in all dropdown lists and in the main list view. System purposes occupy display orders 1 through 6. Custom purposes can use any positive integer, typically above 6.

### Rule BR-TMP-006: Only Active Purposes Are Available for Use
When template screens show purpose dropdowns for new assignments, only active purposes are listed. Deactivated or soft-deleted purposes are excluded. Existing templates already assigned to a deactivated purpose continue to function normally.

### Rule BR-TMP-007: All Changes Are Tracked
Every operation — create, edit, toggle status, soft-delete, restore, permanent delete — is recorded with a timestamp. Each entry captures who did it, what action was taken, and a description of the change.

### Rule BR-TMP-008: Scope Type Determines Template Usability
Class-Scoped purposes are used for templates that need to target specific classes or sections. School-Wide purposes are used for templates that apply to the entire school. The scope type is set at purpose creation and influences how the template assignment screens behave elsewhere in the system.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-TMP-001 | Purpose code must be unique across all records; code is immutable after creation |
| BR-TMP-002 | System purpose code and scope type are locked from editing |
| BR-TMP-003 | System purposes cannot be removed or permanently deleted |
| BR-TMP-004 | Deleting a custom purpose cascades to deactivate/remove its scope assignments |
| BR-TMP-005 | Display order determines sort position in dropdowns and list view |
| BR-TMP-006 | Only active purposes appear in selection dropdowns |
| BR-TMP-007 | All changes recorded with user and timestamp |
| BR-TMP-008 | Scope type (Class-Scoped / School-Wide) controls template targeting behaviour |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing purpose code | "The purpose code field is required." |
| Invalid purpose code format | "The purpose code must contain only uppercase letters and underscores." |
| Duplicate purpose code | "The purpose code has already been taken." |
| Missing purpose name | "The purpose name field is required." |
| Purpose name too long | "The purpose name must not exceed 100 characters." |
| Invalid scope type | "The scope type must be either Class-Scoped or School-Wide." |
| Missing display order | "The display order field is required." |
| Invalid display order | "The display order must be a positive whole number." |
| Edit blocked — system purpose code | "The purpose code of a system purpose cannot be changed." |
| Edit blocked — system purpose scope | "The scope type of a system purpose cannot be changed." |
| Delete blocked — system purpose | "This purpose is a system purpose and cannot be removed." |
| Permanent delete blocked — system purpose | "System purposes cannot be permanently deleted." |
| Record not found | "Purpose not found." |

---

## Success Scenarios

- An administrator creates a new custom purpose: Purpose Code = "LIBRARY_CARD", Purpose Name = "Library Card", Description = "Used for generating library membership cards for students", Scope Type = "School-Wide", Display Order = 10, Active = On. The system saves the purpose record and returns to the list with the new purpose appearing at the correct display order position.

- An administrator edits an existing custom purpose's name from "Library Card" to "Library Membership Card" and changes Display Order from 10 to 7. The system saves the update and re-sorts the list accordingly.

- An administrator deactivates a custom purpose from the list toggle. The purpose is set to Inactive and disappears from all purpose selection dropdowns across the system. Existing templates already using this purpose continue to work. A timestamped record is created.

- An administrator removes a custom purpose that has scope assignments. The purpose is soft-deleted. All associated scope assignments are also deactivated. The purpose disappears from the active list but remains in the database.

---

## Failure Scenarios

- An administrator tries to create a purpose with code "library card" (lowercase and space). The system rejects with "The purpose code must contain only uppercase letters and underscores."

- An administrator tries to create a purpose with code "MARKSHEET_PRINT", which already exists as a system purpose. The system rejects with "The purpose code has already been taken."

- An administrator tries to remove the system purpose "MARKSHEET_PRINT". The system blocks with "This purpose is a system purpose and cannot be removed."

- An administrator tries to change the scope type of "STUDENT_ID_CARD" from School-Wide to Class-Scoped. The system blocks with "The scope type of a system purpose cannot be changed."

- An administrator tries to permanently delete a custom purpose from the Trash that has scope assignments. The system proceeds with permanent deletion, removing the purpose and all its scope assignments permanently.

---

## Example Scenario

Mrs. Mehta, the School Admin of Sunshine International School, needs to add a new purpose for library membership cards. The six standard purposes that came with the system do not include a library card option.

She navigates to Template Purpose Registry and clicks "Add Purpose":

1. **Purpose Code:** She enters "LIBRARY_CARD" (all uppercase, underscore between words).

2. **Purpose Name:** She enters "Library Card".

3. **Description:** She enters "Used for generating library membership cards for students".

4. **Scope Type:** She selects "School-Wide" because library cards are issued to all students regardless of class.

5. **Display Order:** She enters 10 (knowing the six system purposes occupy orders 1–6).

6. **Active:** She leaves the Active toggle ON.

7. She clicks "Save". The system validates the code is unique, checks all fields, creates the purpose, and returns to the list. "LIBRARY_CARD" now appears in the purpose list below the six system purposes, sorted by its display order of 10.

Three months later, the school decides to stop using physical library cards. Mrs. Mehta goes to the purpose list, finds "LIBRARY_CARD", and removes it. Since it is a custom purpose, the system soft-deletes it and cascades the deactivation to its scope assignments. The purpose disappears from the active list but remains recoverable if needed in the future.

---

## Related Screens

- **Template Master** — Where templates are created and assigned to purposes from this registry
- **Template-Purpose Scope Assignment** — Where specific class/section scopes are linked to purposes
- **Template Print/Generate** — Uses purposes to determine which templates can be used for which output

---

## How Other Parts of the System Depend on This Screen

| Area | What It Needs From Template Purpose Registry |
|------|---------------------------------------------|
| **Template Master** | Templates reference purposes from this registry; each template must be assigned to a valid, active purpose |
| **Scope Assignment** | Scope rules are linked to purposes; deactivating a purpose cascades to scope assignments |
| **Template Output Screens** | Purpose selection dropdowns display only active purposes sorted by display order |
| **System Setup** | The six seeded purposes are installed during school setup and cannot be removed |
| **Change History** | All changes to purposes are recorded with timestamps for audit trail |
