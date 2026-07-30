# Template Category — Business Requirements

## What This Screen Does

The Template Category screen lets school administrators create and manage categories that group document layouts by document kind — think of them as labelled folders for organising templates. Six categories come pre-installed (Marksheet, ID Card, Fee Receipt, Admit Card, Certificate, Standard Timetable) and are protected from accidental deletion. Administrators can add custom categories to suit their school's unique document needs.

The main list view shows all categories in a table with columns for the category name, description, a count of how many templates use that category, an Active/Inactive status badge, and action buttons (Edit, Toggle Status, Delete). A search field at the top lets administrators locate a category by typing its name. The list is paginated, showing a default number of categories per page, with page controls at the bottom.

Each category row displays a template count badge — this tells the administrator how many templates (including those in the trash) are currently assigned to that category. This count updates automatically when templates are created, edited, or removed.

---

## When This Screen Is Used

- **Setting Up Template Categories** — When a school first starts using the system, they review the six pre-installed categories and may create additional ones
- **Adding a New Document Type** — When the school needs a new kind of document layout (e.g., "Library Card" or "Transport Route Pass")
- **Editing a Category** — When a category's name or description needs updating
- **Turning a Category Inactive** — When a category should no longer appear as an option when creating new templates (existing templates are not affected)
- **Deleting a Category** — When a custom category is no longer needed (only if no templates currently use it)

---

## Who Can Access This Screen

- **School Admin** — Full access: create, edit, view, toggle active/inactive status, and delete custom categories
- **Principal** — Read-only access: can view the category list and see which categories exist

The system checks the user's permissions before every action to ensure only authorised staff can perform each operation.

---

## How This Screen Works — Step by Step

### The Category List

When an authorised user opens the Template Category screen, the system shows a list of all categories in a table. Each row shows the category name, its description (if any), how many templates are assigned to it, an Active/Inactive indicator, and action buttons. A search box at the top lets the user filter the list by typing part of the category name. As the user types, the list updates to show only matching categories.

The six pre-installed categories are clearly marked and cannot be deleted — their delete button is hidden or disabled. The template count next to each category helps the user understand whether a category is in use before attempting any changes. Categories are listed in the order they were created, with the most recently added category appearing toward the bottom.

### Creating a Category

When the administrator clicks "Add Category," a form slides in or opens as a dialog with the following fields:

**Category Details:**
- Category Name (required, maximum 30 characters, must be unique — cannot match another active or inactive category name, case-insensitive check)
- Description (optional, up to 255 characters, a simple text area)
- Active (optional toggle, defaults to Active; the administrator can switch it to Inactive if the category should not yet be available for use)

When the administrator clicks "Save," the system checks that the name is unique (case-insensitive), validates that the name does not exceed 30 characters and the description does not exceed 255 characters, creates the category record, and returns to the list with a success message. If the validation fails, the form stays open and shows the relevant error message next to the field.

The "Cancel" button discards any unsaved changes and returns the administrator to the category list.

### Searching and Filtering

The search box at the top of the category list allows administrators to find a category quickly by typing any part of its name. The search is case-insensitive and works in real time — the list updates as the administrator types. For example, typing "card" will show both "ID Card" and "Library Card". Clearing the search box returns the full list.

### Editing a Category

The edit form opens with the current values pre-filled. The administrator can change the name, description, or active status. The uniqueness check for the category name ignores the category being edited, so the administrator can save the form without changing the name. Inactive categories can still be edited — editing does not automatically reactivate them.

If the administrator changes the name to one that already exists (other than the current name), the system rejects the change with a duplicate name error message.

### Turning a Category Inactive

Administrators can toggle a category between Active and Inactive status directly from the list view by clicking the toggle switch or button on the category row. Each toggle action is immediately applied without reloading the page.

When a category is set to Inactive, it is hidden from the category dropdown in the Template Designer screen. This means staff creating new templates will not see inactive categories as an option. Existing templates that already use this category remain completely unchanged — they continue to work normally and still display the category name on their template card.

The administrator can turn an inactive category back to Active at any time by clicking the toggle again. This restores the category to the Template Designer dropdown immediately.

### Deleting a Category

When an administrator clicks "Delete" on a category, the system performs two checks before allowing the deletion:

1. **Is it a pre-installed category?** — The six seeded categories (Marksheet, ID Card, Fee Receipt, Admit Card, Certificate, Standard Timetable) cannot be deleted. The system blocks the action and shows a message.

2. **Does any template use this category?** — If any template, whether active or in the trash (soft-deleted), is assigned to this category, the system blocks the deletion and shows a count of how many templates are using it.

If both checks pass (custom category with no templates), the category is permanently deleted from the system. The list updates to remove the deleted category, and a success message confirms the action.

There is no soft-delete or trash for categories — deletion is immediate and permanent. The administrator does not need to confirm the deletion a second time after the initial click; however, the system always performs the two checks before honouring the request.

---

## Validation Rules — What's Required Before Saving

| Field | Rule |
|-------|------|
| Category Name | Required, up to 30 characters, must be unique (case-insensitive across all categories including inactive ones; ignores the category being edited) |
| Description | Optional, up to 255 characters |
| Active | Optional, defaults to Active (Yes) |

---

## Business Rules and Conditions

### Rule BR-TCT-001: Category Name Must Be Unique (Case-Insensitive)
Every category name must be unique across the school. The check ignores letter case, so "Marksheet" and "marksheet" are treated as the same name. When editing, the check excludes the category being edited so the administrator can save without changes.

### Rule BR-TCT-002: Six Pre-Installed Categories Are Protected
The following six categories are seeded by the system and cannot be deleted or permanently removed: Marksheet, ID Card, Fee Receipt, Admit Card, Certificate, Standard Timetable. Their delete controls are hidden or disabled.

### Rule BR-TCT-003: Block Delete If Templates Are Using the Category
A category cannot be deleted if any template records (whether active or in the trash) reference it. The system counts all templates assigned to the category and blocks deletion if the count is greater than zero. The administrator must reassign or remove those templates before the category can be deleted.

### Rule BR-TCT-004: Inactive Status Hides Category From Selection Lists
When a category is set to Inactive, it no longer appears in the category dropdown on the Template Designer screen. Existing templates that already use this category are unaffected — they continue to display the category name and function normally.

### Rule BR-TCT-005: Each Category Shows a Template Count
The list view displays a count of how many templates (including those in trash) are assigned to each category. This helps administrators know at a glance whether a category is in use before attempting to delete it.

### Rule BR-TCT-006: Category Names Are Stored as Entered
The category name is saved exactly as typed by the administrator. The uniqueness check uses case-insensitive comparison, but the stored value preserves the original capitalisation. So "library card", "Library Card", and "LIBRARY CARD" would all be rejected as duplicates, but whichever variation was entered first remains stored in its original form.

### Rule BR-TCT-007: Description Is Purely Informational
The description field has no functional impact on the system. It is for the administrator's reference only and does not affect template behaviour, filtering, or selection lists.

### Rule BR-TCT-008: Active Status Change Is Immediate and Independent
Toggling a category's active status takes effect immediately without requiring a page refresh. The change does not trigger any cascade updates to existing templates — template records retain their category assignment regardless of the category's active status.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-TCT-001 | Category name must be unique (case-insensitive) |
| BR-TCT-002 | Six seeded categories cannot be deleted |
| BR-TCT-003 | Cannot delete a category if any templates use it |
| BR-TCT-004 | Inactive categories are hidden from template creation dropdowns |
| BR-TCT-005 | Template count is shown next to each category in the list |
| BR-TCT-006 | Category name preserves its original capitalisation |
| BR-TCT-007 | Description is for reference only — no functional impact |
| BR-TCT-008 | Active status toggle is immediate and does not cascade to templates |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Category name is missing | "The category name field is required." |
| Category name exceeds 30 characters | "The category name must not exceed 30 characters." |
| Duplicate category name | "The category name has already been taken." |
| Description exceeds 255 characters | "The description must not exceed 255 characters." |
| Delete blocked — category is pre-installed | "This category cannot be deleted because it is a system-defined category." |
| Delete blocked — templates are using this category | "This category cannot be deleted because {count} template(s) are using it." |
| Toggle — record not found | "Category not found." |
| No matching categories found | "No categories found." |

---

## Success Scenarios

- An administrator creates a new category: Category Name = "Library Card", Description = "For library membership cards and borrower passes", Active = Yes. The system saves the category, it appears in the list with a template count of 0, and it becomes available in the Template Designer category dropdown.

- An administrator edits the category "Library Card" to change the description to "Library membership and borrower pass cards". The system updates the description and returns to the list with a success message.

- An administrator toggles "Old Report Format" from Active to Inactive. The category remains in the list with an Inactive badge. It disappears from the Template Designer dropdown but existing templates that use this category continue to work.

- An administrator deletes a custom category "Test Category" that has no templates assigned. The category is permanently removed from the system and disappears from the list.

- An administrator searches for "card" in the search box. The list filters to show "ID Card", "Library Card", and any other categories containing "card" in their name. Clearing the search restores the full list.

- An administrator creates a category while leaving the Description field blank. The system saves the category successfully with no description, treating the field as optional.

---

## Failure Scenarios

- An administrator tries to create a category named "Marksheet" (which already exists as a pre-installed category). The system rejects with "The category name has already been taken."

- An administrator tries to delete the pre-installed "ID Card" category. The system blocks the action and displays "This category cannot be deleted because it is a system-defined category."

- An administrator tries to delete "Fee Receipt" which has 12 active templates and 2 trashed templates assigned to it. The system blocks the deletion and displays "This category cannot be deleted because 14 template(s) are using it."

- An administrator tries to enter a category name that is 45 characters long. The system rejects with "The category name must not exceed 30 characters."

- An administrator tries to create a category named "marksheet" (lowercase) when "Marksheet" already exists. The system rejects with "The category name has already been taken." because the uniqueness check is case-insensitive.

- An administrator tries to toggle a category that was deleted by another user in the meantime. The system shows "Category not found." and refreshes the list.

---

## Example Scenario

Mrs. Sharma, the School Admin of Green Valley Academy, wants to introduce a library membership card for students.

She navigates to Template Category and clicks "Add Category":

1. She enters Category Name = "Library Card" and Description = "For library membership cards and borrower passes". She leaves the Active toggle ON.
2. She clicks "Save". The system checks that "Library Card" is unique (no existing category has this name), validates all fields, creates the category, and returns to the list. The new "Library Card" entry appears with a template count of 0 and an Active badge.
3. She then goes to the Template Designer screen to create the actual library card layout. In the category dropdown, she sees "Library Card" listed alongside the six system categories. She selects it and designs the layout.
4. The Template Designer now shows "Library Card" as a category on the template card, helping other staff members identify what this layout is used for.

A year later, the school stops issuing physical library cards. Mrs. Sharma returns to the Template Category screen, finds "Library Card" in the list, and clicks the toggle to set it to Inactive. The category badge changes to Inactive immediately. When she later opens the Template Designer to create a new timetable layout, the "Library Card" category no longer appears in the category dropdown — only the six system categories and any other active custom categories are shown. The two existing library card templates continue to work normally and still display "Library Card" as their category on the template cards.

Two years later, the school decides to reintroduce library cards. Mrs. Sharma toggles "Library Card" back to Active. The category reappears in the Template Designer dropdown, and staff can once again select it when creating new templates.

---

## Related Screens

- **Template Designer** — Where the actual template layouts are created and edited; uses the active category list from this screen for the category dropdown when creating or editing templates
- **Template Category (Groups tab)** — Manages the grouping of categories into higher-level groups; categories created here can be assigned to groups there
- **Template List** — Displays templates organised by their assigned category; uses category names as filter criteria and display labels
- **Role & Permission Settings** — Controls which user roles (School Admin, Principal) can access this screen and what actions they can perform

---

## How Other Parts of the System Depend on This Screen

| Area | What It Needs From Template Category |
|------|--------------------------------------|
| **Template Designer** | Reads the active category list for the category dropdown when creating/editing templates; category names are displayed on template cards |
| **Template rendering** | Uses the category association to identify which layout to apply for a given document type |
| **Template list views** | Filters and organises templates by their assigned category |
| **Form settings** | Uses category names as selectable options when configuring which document type a particular form should use |
| **Print and download workflows** | Routes document generation based on the template category to determine the correct layout |
| **Template reports** | Groups and counts templates by category for usage and audit reports |
| **Category groups (Groups tab)** | Reads categories from this screen to allow grouping into higher-level collections |
