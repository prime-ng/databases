# Author — Business Requirements

## What This Screen Does

The Author screen is where the school registers people who write, compile, edit, or contribute to books. An author can be an individual (like a textbook writer) or an organisation (like NCERT). Once registered, authors can be linked to books with specific roles.

Think of this as the school's directory of book creators. Before a book can show "Written by..." or "Edited by...", the author must exist here.

---

## When This Screen Is Used

- A new textbook is added and its author needs to be registered
- Admin wants to update an author's qualification or biography
- Admin wants to see how many books an author has contributed to
- An author is no longer relevant and needs to be deactivated

---

## Key Fields at a Glance

**Name**
The author's full name. This must be unique — no two authors can have the exact same name. Example: "NCERT", "R.S. Aggarwal", "William Shakespeare".

**Qualification (Optional)**
A brief description of the author's credentials. Example: "PhD in Mathematics, 20 years teaching experience".

**Biography (Optional)**
A longer description of the author's background, notable works, or expertise.

**Status**
Each author can be Active (available for book assignments) or Inactive (no longer used).

---

## Business Rules

**Unique Name**
No two authors can share the same name. The system prevents duplicate registration.

**Soft Delete**
When an author is deleted, the record is soft-deleted (moved to trash). It can be restored. Permanent deletion removes all author-book links.

**Author-Book Relationship**
An author can be linked to multiple books. Each link includes a role (Primary Author, Co-Author, Editor, or Contributor) and an optional display order.

---

## What Shows in the List

| Column | Description |
|--------|-------------|
| Sr. No | Row number |
| Name | Author's full name |
| Qualification | Author's credentials |
| No. of Books | Count of books linked to this author |
| Status | Active/Inactive toggle |
| Action | View, Edit, Delete buttons |

---

## Workflow Steps

**Adding a New Author**
Admin clicks Add, enters the author's name, optionally adds qualification and biography, and submits. The author appears in the list with 0 books linked.

**Editing an Author**
Admin clicks Edit, modifies any field, and saves.

**Viewing an Author**
Admin clicks View to see full details including all books linked to this author.

**Toggling Status**
Admin clicks the status switch to activate or deactivate an author.

---

## Example Scenario

A school is adding the NCERT Mathematics textbook for Class 10. They register the author as "NCERT" with no specific qualification (it's an organisation). Later, they add "R.S. Aggarwal" as an author with qualification "Renowned Mathematics Educator". Both authors can now be linked to their respective books.

---

## Related Screens

- **Book** — Authors are linked to books during book creation/editing
