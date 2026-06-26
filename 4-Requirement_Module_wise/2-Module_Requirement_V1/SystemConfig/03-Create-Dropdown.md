# Create Dropdown — Business Requirements

## What This Screen Does

The Create Dropdown screen lets an admin take a "dropdown need" and actually create or map dropdown values to it. If a dropdown need says "we need a blood_group dropdown," this is where the admin adds the actual values like A+, B+, O+, etc.

---

## When This Screen Is Used

- A new dropdown need has been created and needs values assigned to it
- Admin wants to add more values to an existing dropdown
- Admin needs to edit or delete specific values within a dropdown
- Admin wants to create a completely new dropdown key on the fly

---

## Key Features

**Add Single or Multiple Values**
The admin can add values one at a time or in bulk. Each value is a text entry that becomes one option in the dropdown list.

**Create New Key On-the-Fly**
If a dropdown key does not already exist, the admin can create one directly from this screen — no need to navigate elsewhere.

**Inline Editing**
Existing values can be edited directly. The admin clicks on a value, changes the text, and saves instantly.

**Delete with Confirmation**
Values can be removed from a dropdown. The system asks for confirmation before deleting to prevent accidental removal.

**Auto-Ordinal Assignment**
When new values are added, the system automatically assigns them the next available ordinal number to maintain their display order.

---

## Business Rules

**Unique Values Per Key**
Within the same dropdown key, no two values can have the same text. Duplicate values are prevented.

**Key Reference**
When creating a new key on-the-fly, the admin provides the key name and its type (String, Integer, etc.) so the system knows what kind of data this dropdown holds.

**Mapped to Needs**
Values created here are linked to the selected dropdown need via the junction table, so they appear only in the context where that dropdown need applies.

**Active by Default**
New values are always created as Active. The admin can deactivate them later if needed.
