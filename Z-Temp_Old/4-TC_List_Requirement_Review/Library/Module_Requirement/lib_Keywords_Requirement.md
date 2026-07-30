# Keywords Master — Business Requirements

## What This Screen Does

The Keywords Master screen manages searchable tags that can be attached to books to improve discoverability in the library catalog. Keywords are short, descriptive terms like "exam preparation", "competitive exams", "grammar", "worksheet", or "science project" that help students and staff find relevant books through search and filtering. Each keyword has a unique business code and a display name. Keywords are linked to books through a many-to-many junction table (`lib_book_keyword_jnt`), enabling flexible tagging where one book can have many keywords and one keyword can tag many books.

---

## When This Screen Is Used

- When setting up the library catalog and defining search tags for the first time
- When adding new keywords to improve book discoverability based on student search trends
- When updating or correcting existing keyword names or codes

## Default Data Load

This screen renders as the **Keywords** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Keywords tab, `LibraryController@tabIndex` loads all keywords ordered by latest first, paginated at 15 rows per page (`keywords_page`). Search and status filters only apply when the active tab is `keywords`.

---

---

## Key Fields at a Glance

**Core Identity**
Each keyword has a unique business code (e.g., "EXAM_PREP", "GRAMMAR") that serves as the system identifier, and a display name (e.g., "Exam Preparation", "Grammar") that appears in the user interface. The code must be globally unique across all keywords and is limited to 30 characters. The name is required and limited to 100 characters.

**Usage Context**
Keywords are not hierarchical and have no parent-child relationships. They function purely as flat tags. The `is_active` boolean controls whether the keyword appears in selection dropdowns and is available for tagging new books. Inactive keywords remain linked to existing books but cannot be selected for new assignments.

---

## Business Rules and Conditions

**Unique Constraints**
The `code` column has a UNIQUE constraint at the database level. No two keywords can share the same code. There is no uniqueness constraint on the `name` column, but the UI should encourage unique names to avoid confusion.

**Search Filter**
Only active keywords (`is_active = 1`) are suggested in search filters for book discovery. Inactive keywords are excluded from search suggestion dropdowns in both staff and student search interfaces.

**Inactive Restriction**
When `is_active` = 0, the keyword cannot be selected while creating or editing a book. The keyword selection interface in book create/edit forms filters out inactive keywords.

**Deletion Restrictions**
A keyword cannot be soft-deleted if it has associated books in the `lib_book_keyword_jnt` junction table. The system checks `$keyword->books()->exists()` before deletion and returns an error listing up to three example book titles. The user must remove the keyword from all books first.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view. Restore sets `deleted_at` to null. Force-deletion from trash catches foreign key constraint violations.

---

## Book-Keyword Junction (`lib_book_keyword_jnt`)

The junction table links books to searchable keywords in a many-to-many relationship. Keywords are free-form tags that enhance search discovery. Unlike the `tags_json` field on Book Master (which is AI-generated), these keywords are manually assigned by librarians.

### Junction Table Fields

- **`book_id`** (FK → `lib_books_master.id`, ON DELETE CASCADE) — The book being tagged with a keyword.
- **`keyword_id`** (FK → `lib_keywords.id`, ON DELETE CASCADE) — The keyword assigned to the book. Dropdown filter: Only active keywords are shown in keyword selection.
- **Unique Key:** `(book_id, keyword_id)` — prevents duplicate keyword assignment per book.
- **Index:** `idx_bookKeywordJnt_keyword` — efficient keyword-based searches.

### Junction Table Business Rules

1. **Cascade Delete on Book Removal** — If a book is deleted, all its keyword junction records are automatically removed (ON DELETE CASCADE).
2. **Cascade Delete on Keyword Removal** — If a keyword is deleted, all its book junction records are automatically removed (ON DELETE CASCADE).
3. **Duplicate Prevention** — The same keyword cannot be assigned to the same book more than once (enforced by composite unique key).
4. **Active Keyword Filtering** — Only active keywords (`is_active = 1`) appear in the keyword selection dropdown when assigning keywords to books.

## Workflow Steps

**Adding a New Keyword**
The librarian navigates to Library → Library Mgt → Masters and selects the Keywords tab. They click "Add Keyword". They enter a unique code (e.g., "SCIENCE_PROJ") and the display name (e.g., "Science Project"). The Active toggle defaults to ON. On Save, the system validates the code uniqueness and persists the record.

**Editing a Keyword**
The librarian clicks the Edit icon on any row. The code and name can be modified. The system re-validates code uniqueness, ignoring the current record. The Active status can also be toggled.

**Deleting a Keyword**
If the keyword has no linked books, clicking Delete soft-deletes the record. If linked books exist, deletion is blocked with an error message.

---

## Example Scenario

The school librarian notices that students often search for "competitive exam preparation" books. The librarian goes to the Keywords tab, clicks Add Keyword, enters the code "COMP_EXAM" and name "Competitive Exam", and saves. Later, when cataloging a new book titled "Guide to IIT-JEE", the librarian can select this keyword from the keyword assignment interface. When a student searches "competitive exam" in the catalog, this book appears in the results.

---

## Related Screens

- **Books Master** — Where keywords are assigned to books via the keyword selection interface

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibKeywordController`
**Model:** `Modules\Library\Models\LibKeyword` (table: `lib_keywords`)
**Requests:** `LibKeywordRequest` (validates create and update)
**Policy:** `LibKeywordPolicy` (permissions: `tenant.lib-keywords.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-keywords', LibKeywordController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `keywords` under `library.tabIndex`

Key controller methods:
- `index()` — Redirects to `library.tabIndex` with `tab=keywords`
- `create()` — Returns create view
- `store(LibKeywordRequest)` — Creates keyword in DB transaction, logs activity
- `show($id)` — Loads keyword with books relation; logs view activity
- `edit($id)` — Returns edit view
- `update(LibKeywordRequest, $id)` — Updates keyword in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Checks for associated books before deletion; blocks if books exist; soft-deletes if safe
- `trashed()` — Lists soft-deleted keywords, paginated at 15
- `restore($id)` — Restores soft-deleted keyword in DB transaction
- `forceDelete($id)` — Force-deletes with `QueryException('23000')` catch for FK violations
- `toggleStatus($id)` — Toggles `is_active` boolean; uses `Gate::authorize('tenant.lib-keywords.status')` — supports both AJAX and non-AJAX response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-keywords.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-keywords.*` | Full CRUD + restore + forceDelete |
| Librarian (view only) | `tenant.lib-keywords.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibKeywordPolicy` methods which map to `tenant.lib-keywords.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Keywords tab. The system loads the list of all keywords, 15 per page. The user can search by keyword name or code, or filter by status. To add a new keyword, the user clicks Add Keyword, enters a unique code and name, and saves. The system checks that the code is not already taken. To edit, the user clicks the edit icon and modifies the fields. To delete, the system first checks if any books use this keyword. If books are tagged with it, deletion is blocked. Otherwise, the keyword is moved to trash.

---

## Validate Before Save

**Create/Update (`LibKeywordRequest`):**
1. **code:** required, string, max:30, unique on `lib_keywords.code` (ignoring self on update)
2. **name:** required, string, max:100
3. **is_active:** boolean (default: true via `prepareForValidation`)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Duplicate code | "The code has already been taken." (default Laravel unique message) | 422 |
| Missing code | "The code field is required." | 422 |
| Missing name | "The name field is required." | 422 |
| Delete keyword with books | "Cannot delete keyword '[name]' because it has [N] associated books. Example books: [titles]... Please reassign or delete these books first." | 302 (redirect back) |
| Force delete with FK dependency | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." | 302 (redirect back) |

---

## Success Scenarios

- A librarian adds a new keyword with code "GRAMMAR" and name "Grammar". The system validates, saves, and displays "Keyword created successfully."
- A librarian edits a keyword to change its name from "Test Prep" to "Exam Preparation". The system logs the change and displays "Keyword updated successfully."
- A librarian deletes a keyword that no book is tagged with. The system soft-deletes it and displays "Keyword moved to trash successfully."

---

## Failure Scenarios

- A librarian tries to create a keyword with code "EXAM_PREP" but that code already exists. The system returns "The code has already been taken."
- A librarian tries to delete the keyword "Grammar" which is tagged to 12 books. The system blocks deletion and shows "Cannot delete keyword 'Grammar' because it has 12 associated books. Example books: English Grammar Handbook, ... Please reassign or delete these books first."
- A librarian tries to force-delete a keyword from trash that still has junction records. The system catches the FK violation and shows the generic dependency error.

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_keywords` | Primary table with `code VARCHAR(30) UNIQUE`, `name VARCHAR(100) NOT NULL`, soft-deletes via `deleted_at` |
| Junction | `lib_book_keyword_jnt` | Many-to-many link to `lib_books_master` with `book_id` and `keyword_id` FK |
