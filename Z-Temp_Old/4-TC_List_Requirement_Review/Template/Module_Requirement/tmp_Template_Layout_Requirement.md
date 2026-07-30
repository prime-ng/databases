# Visual Template Designer — Business Requirements

## What This Screen Does

The Visual Template Designer is the main workspace where school administrators author document layouts — think marksheets, ID cards, certificates, report cards, and fee receipts. It serves as the heart of the Template module: layouts created here are what the rendering engine uses to produce the final printed or downloadable documents.

The screen presents an editor where administrators enter or paste raw HTML and CSS code with `{{placeholder}}` markers that get replaced with actual student or staff data at render time. A variable picker on the same screen lets administrators map registered data variables (like `{{student_name}}`, `{{roll_number}}`, `{{father_name}}`) to the layout and control their display order. Administrators can also upload a background image (school crest, border, letterhead), assign optional positional coordinates for future drag-and-drop editing, and preview how the layout will look with sample data.

The main list view shows all saved layouts with filters to narrow down by category (type), machine code, display name, and draft/active status. Administrators can create new layouts, edit existing ones, activate or deactivate them, preview rendered output, remove layouts from view, restore them, or permanently delete them.

---

## When This Screen Is Used

- **Creating a New Layout** — When a school needs a new document format (e.g., a half-yearly marksheet or a library ID card)
- **Editing HTML Content** — When an existing layout's design, placeholders, or styling need updates
- **Mapping Variables** — To assign which data fields appear on the document and in what order
- **Uploading Background Image** — To attach a school crest, letterhead, border, or watermark
- **Previewing the Layout** — To see how the document will look with actual data before activation
- **Activating a Layout** — To make a layout available for document generation (only possible after at least one variable is mapped)
- **Removing and Restoring** — To hide a layout from active use or bring it back from the trash
- **Permanently Deleting** — To erase a layout record entirely (only if no scope assignments exist)

---

## Who Can Access This Screen

- **School Admin** — Full access including create, edit, activate, deactivate, remove, restore, permanent delete, and background image upload
- **Academic Coordinator** — Can view and edit layouts for academic documents (marksheets, report cards)
- **Accounts Manager** — Can view and edit layouts for financial documents (fee receipts, invoices)
- **Principal** — Read-only access to view layouts and preview rendered output

The system checks the user's permissions before every action to ensure only authorised staff can perform each operation.

---

## How This Screen Works — Step by Step

### The Layout List

When an administrator opens the Visual Template Designer, the system shows a list of saved layouts (20 per page) with columns: #, Machine Code, Display Name, Category (Type), Status (Draft/Active), Last Modified, and Actions (View, Edit, Preview, Delete). A filter panel above the list lets administrators narrow down by Category (marksheet, ID card, certificate, report card, fee receipt), Machine Code (partial match), Display Name (partial match), and Status (Draft/Active/All).

The list shows all layouts by default, with draft layouts clearly marked. A separate "Trash" tab shows removed records.

### Creating a Layout

When the administrator clicks "Create Layout," they see a single-page workspace with the following sections:

**Layout Details:**
- Machine Code (required, must be unique across the school — a short system identifier in snake_case or kebab-case)
- Display Name (required, the human-readable name shown in selection lists)
- Category (required, chosen from a predefined list: marksheet, ID card, certificate, report card, fee receipt, other)
- Description (optional, up to 500 characters)

**HTML Editor:**
- A large text area where the administrator writes or pastes HTML and CSS code
- Placeholder markers follow the `{{variable_code}}` convention — the rendering engine replaces these with actual data at generation time
- The editor supports inline math formulas via an auto-normalizer (e.g., `{{marks_obtained}}/{{total_marks}}` renders as a fraction)

**Variable Picker:**
- A panel on the same screen that displays all registered variables for the selected category
- Each variable shows its variable code, display label, and data type
- The administrator selects variables and assigns them a display order number
- Selected variables appear in a list with drag handles for reordering
- The variable mapping is saved to the junction table linking layouts to variables

**Canvas JSON:**
- An optional field containing positional coordinates (x, y, width, height) for each placeholder
- Reserved for future use with a drag-and-drop visual editor
- If left empty, the rendering engine auto-positions content based on HTML flow

**Background Image:**
- An optional file upload for a branding image (school crest, border design, letterhead)
- Accepted formats: JPEG, PNG
- Maximum file size: 2MB
- The uploaded image is stored and linked to the layout

**Status:**
- Status defaults to "Draft"

When the administrator clicks "Save," the system checks all fields, validates the machine code uniqueness, stores the HTML content, saves the variable mappings, uploads the background image if provided, and creates the layout as a Draft. The system then returns to the list with a success message.

### Editing a Layout

The edit workspace opens with all existing values pre-filled. The administrator can modify any field including the HTML content, variable mappings, canvas JSON, and background image. The machine code uniqueness check ignores the layout being edited and also ignores deleted records.

When variables are added or removed, the junction table is synchronised — new variable mappings are inserted, removed ones are deleted, and display orders are updated in a single operation.

When the background image is changed, the old image file is deleted from storage and replaced with the new one. When the background image is removed, the old file is deleted.

### Previewing a Layout

The administrator can click "Preview" to see how the layout will render with sample data. The system pulls sample values for all mapped variables and renders the HTML content with placeholders replaced. The result is displayed in a modal or a new tab exactly as it would appear in the final document, including the background image.

### Activating a Layout

A layout can only be activated after at least one variable is mapped. When the administrator clicks "Activate," the system checks the variable count. If zero variables are mapped, activation is blocked with a warning. Otherwise, the status changes from "Draft" to "Active."

An active layout can be deactivated back to "Draft" at any time.

### Removing and Restoring

When an administrator removes a layout, the record is hidden but retained in the system (soft delete). Before removal, the system deactivates all scope assignments linked to this layout — any class-section-template assignments are set to inactive. The administrator can restore the layout from the Trash page; restoring reinstates the layout record but does not automatically reactivate scope assignments.

### Permanently Deleting

When an administrator permanently deletes a layout from the Trash, the system first checks if any scope assignments exist for this layout. If scope assignments exist, permanent deletion is blocked with a warning. If no scope assignments exist, the layout record, its variable mappings, its background image file, and all associated data are permanently removed. This action cannot be undone.

### Toggle Status

Administrators can toggle a layout between Draft and Active directly from the list view. The same variable-count check applies when activating from the list. Each change is saved with a timestamp.

---

## Validation Rules — What's Required Before Saving

### Layout Details:

| Field | Rule |
|-------|------|
| Machine Code | Required, up to 100 characters, must be unique across the school (ignores the layout being edited and deleted records), snake_case or kebab-case recommended |
| Display Name | Required, up to 200 characters |
| Category | Required, must be a valid option from the predefined list (marksheet, ID card, certificate, report card, fee receipt, other) |
| Description | Optional, up to 500 characters |

### HTML Content:

| Field | Rule |
|-------|------|
| HTML Content | Required, must contain valid HTML structure, can be empty `<html><body></body></html>` if placeholder is just being set up |

### Variable Mapping:

| Field | Rule |
|-------|------|
| Variables | Optional at save time, but at least one variable must be mapped before activation |
| Display Order | Must be a positive integer when provided, unique within the layout |

### Canvas JSON:

| Field | Rule |
|-------|------|
| Canvas JSON | Optional, must be valid JSON when provided |

### Background Image:

| Field | Rule |
|-------|------|
| Background Image | Optional, must be JPEG or PNG format, must not exceed 2MB |

### Status:

| Field | Rule |
|-------|------|
| Status | Optional — Draft by default, can be set to Active only if at least one variable is mapped |

---

## Business Rules and Conditions

### Rule BR-TMP-001: Machine Code Must Be Unique
The machine code is a system-level identifier and must be unique across all non-deleted layout records within the same school. When editing, the check ignores the layout's own machine code. Deleted records are also excluded, so a deleted layout's machine code can be reused.

### Rule BR-TMP-002: Category Must Be a Valid Option
The category (type) must come from the predefined list. If someone tries to delete a category option that is already in use by existing layouts, the system blocks the deletion to prevent broken references.

### Rule BR-TMP-003: Activation Requires at Least One Mapped Variable
A layout cannot be activated in Draft status if no variables are mapped to it. This ensures that every active layout is capable of producing a meaningful document. The variable count is checked at the time of activation, whether from the edit screen or the list toggle.

### Rule BR-TMP-004: Soft Delete Deactivates All Scope Assignments
When a layout is removed (soft deleted), all its scope assignments (class-section-template links) are automatically deactivated. Restoring the layout does not reactivate these assignments — the administrator must manually reassign them.

### Rule BR-TMP-005: Permanent Delete Blocked If Scope Assignments Exist
A layout cannot be permanently deleted if any scope assignments reference it. The administrator must first remove all scope assignments before permanent deletion is allowed.

### Rule BR-TMP-006: Background Image Must Be JPEG or PNG Under 2MB
Uploaded background images are restricted to JPEG and PNG formats. File size must not exceed 2 megabytes. Non-compliant uploads are rejected with an appropriate message.

### Rule BR-TMP-007: Old Background Image Cleaned Up on Change
When the background image is replaced with a new file, the old image file is permanently deleted from storage. When the background image is removed without replacement, the old file is also deleted.

### Rule BR-TMP-008: Variable Mappings Are Synced on Save
When a layout is saved with updated variable mappings, the junction table is synchronised: new mappings are inserted, removed mappings are deleted, and existing mappings have their display orders updated — all within a single atomic operation.

### Rule BR-TMP-009: Placeholder Format Convention
All placeholders in the HTML content must follow the `{{variable_code}}` convention. During rendering, the engine replaces these markers with actual data. Variables not mapped in the junction table are replaced with an empty string.

### Rule BR-TMP-010: All Changes Are Tracked
Every operation — create, edit, activate, deactivate, remove, restore, permanent delete, background image change — is recorded with a timestamp. Each entry captures who did it, what action was taken, and a description of the change.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-TMP-001 | Machine code must be unique across non-deleted records |
| BR-TMP-002 | Category must be from the predefined options |
| BR-TMP-003 | Activation blocked if zero variables are mapped |
| BR-TMP-004 | Soft delete deactivates all linked scope assignments |
| BR-TMP-005 | Permanent delete blocked if any scope assignments exist |
| BR-TMP-006 | Background image must be JPEG/PNG, max 2MB |
| BR-TMP-007 | Old background image deleted when replaced or removed |
| BR-TMP-008 | Variable mappings synchronised atomically on save |
| BR-TMP-009 | Placeholders use `{{variable_code}}` convention |
| BR-TMP-010 | All changes recorded with user and timestamp |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing machine code | "The machine code field is required." |
| Machine code too long | "The machine code must not exceed 100 characters." |
| Duplicate machine code | "The machine code has already been taken." |
| Missing display name | "The display name field is required." |
| Display name too long | "The display name must not exceed 200 characters." |
| Category not selected | "The category is required." |
| Invalid category | "The selected category is invalid." |
| Missing HTML content | "The HTML content field is required." |
| Invalid canvas JSON | "The canvas JSON must be a valid JSON string." |
| Invalid variable display order | "The display order must be a positive integer." |
| Activation with no variables | "Cannot activate this layout because no variables are mapped. Please map at least one variable first." |
| Background image wrong type | "The background image must be a file of type: jpeg, png." |
| Background image too large | "The background image must not exceed 2 MB." |
| Delete blocked — scope exists | "This layout cannot be deleted as it has active scope assignments. Please remove them first." |
| Permanent delete blocked — scope exists | "This layout cannot be permanently deleted as it has associated scope assignments. Use remove instead." |
| Toggle — record not found | "Template not found." |
| Background image upload failed | "The background image could not be uploaded. Please try again." |

---

## Success Scenarios

- An administrator creates a new layout: Machine Code = "halfyearly_marksheet_2025", Display Name = "Half-Yearly Marksheet 2025", Category = "Marksheet", Description = "Standard half-yearly exam marksheet with student photo and grade summary". The administrator writes HTML with placeholders like `{{student_name}}`, `{{roll_number}}`, `{{subject_1_marks}}`, `{{total_marks}}`, `{{percentage}}`, `{{grade}}`, and uploads the school crest as a background image. The system saves the layout as Draft, stores the background image, saves the variable mappings, and returns to the list with a success message.

- An administrator maps variables to an existing Draft layout. The variable picker shows 20 available variables for the Marksheet category. The administrator selects 8 variables: student_name (order 1), roll_number (order 2), father_name (order 3), subject_1_marks (order 4), subject_2_marks (order 5), total_marks (order 6), percentage (order 7), grade (order 8). The system syncs the junction table and the layout is now eligible for activation.

- An administrator activates a layout with 8 mapped variables. The system changes the status from Draft to Active. The layout now appears in selection lists across the system for document generation.

- An administrator previews an active layout. The system pulls sample student data, replaces all placeholders with actual values, and displays the rendered document including the background image.

---

## Failure Scenarios

- An administrator tries to create a layout with machine code "halfyearly_marksheet_2025" that already exists. The system rejects with "The machine code has already been taken."

- An administrator tries to activate a layout with no variables mapped. The system blocks activation and displays "Cannot activate this layout because no variables are mapped. Please map at least one variable first."

- An administrator tries to upload a PDF file as background image. The system rejects with "The background image must be a file of type: jpeg, png."

- An administrator tries to upload a 5MB JPEG file as background image. The system rejects with "The background image must not exceed 2 MB."

- An administrator tries to permanently delete a layout that has 5 class-section assignments. The system blocks deletion and displays "This layout cannot be permanently deleted as it has associated scope assignments. Use remove instead."

- An administrator enters an invalid JSON string in the Canvas JSON field. The system rejects with "The canvas JSON must be a valid JSON string."

- An administrator removes a layout that has 3 active scope assignments. The system performs the soft delete and automatically deactivates all 3 assignments. The layout moves to the Trash.

---

## Example Scenario

Mrs. Sharma, the School Admin of Green Valley Academy, needs to create a new marksheet layout for the upcoming half-yearly examinations.

She navigates to the Visual Template Designer and clicks "Create Layout":

1. **Layout Details:** She enters Machine Code = "hye_marksheet_2026", Display Name = "Half-Yearly Exam Marksheet 2026", selects Category = "Marksheet", and writes a brief Description: "Standard marksheet for half-yearly exams with student photo, subject-wise marks, total, percentage, grade, and rank."

2. **HTML Editor:** She pastes the HTML template she prepared. The content includes a table with rows for each subject, placeholders like `{{student_name}}`, `{{roll_number}}`, `{{class}}`, `{{section}}`, `{{subject_1_name}}`, `{{subject_1_marks}}`, `{{subject_1_grade}}`, and a summary row with `{{total_marks}}`, `{{percentage}}`, `{{overall_grade}}`, `{{rank}}`. She styles the table with inline CSS for borders, font sizes, and alignment.

3. **Variable Picker:** She opens the variable panel. For the Marksheet category, the system shows 25 registered variables. She selects 12 variables and assigns display order: student_name (1), roll_number (2), class (3), section (4), and so on through to rank (12). She drags them into the desired sequence.

4. **Background Image:** She uploads the school crest (PNG, 500KB) and a border design (JPEG, 800KB), selecting the crest as the main background.

5. **Canvas JSON:** She leaves this empty for now, relying on HTML flow for positioning.

6. She clicks "Save Draft." The system validates the machine code (unique), saves the HTML content, stores the background images, creates all 12 variable mappings, and returns to the list with a success message.

7. She sees the new layout in Draft status. She clicks "Activate." The system confirms 12 variables mapped and changes the status to Active.

8. She clicks "Preview" to verify. The system renders the layout with sample student data — all placeholders are replaced, the school crest appears, and the marksheet looks exactly as she designed it.

Two months later, the academic year ends. Mrs. Sharma removes the layout. The system deactivates all 5 class-section assignments linked to this layout. The layout moves to the Trash.

---

## Related Screens

- **Variable Master** — Where template variables are defined and registered for each category
- **Scope Assignment** — Where active layouts are assigned to specific classes and sections for document generation
- **Document Generation** — Where the rendering engine uses active layouts to produce final documents
- **Category Master** — Where template categories (marksheet, ID card, certificate, etc.) are managed

---

## How Other Parts of the System Depend on This Screen

| Area | What It Needs From Visual Template Designer |
|------|---------------------------------------------|
| **Layout records** | All layout definitions (HTML, variables, background) are stored and managed here |
| **System settings** | Template categories come from shared system settings; user information is used for activity tracking |
| **File storage** | Background images are stored and linked to layout records |
| **Variable mappings** | Junction table links layouts to registered variables with display order |
| **Change history** | All changes to layouts are recorded with timestamps |
| **Scope assignments** | Layouts are assigned to class-sections and checked before soft delete or permanent delete |
| **Document rendering** | The rendering engine reads layout HTML, variable mappings, and background images to produce final documents |
