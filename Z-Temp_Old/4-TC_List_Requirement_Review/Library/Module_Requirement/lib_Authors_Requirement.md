# Authors Master — Business Requirements

## What This Screen Does

The Authors Master screen maintains the master list of all book authors used across the library catalog. Each author record stores a short identifier (pen name), full legal name, country of origin, primary literary genre, and optional notes. Authors are linked to books through a many-to-many junction table (`lib_book_author_jnt`), where each link includes the author's display order and whether they are the primary author. This screen ensures that every book in the catalog is correctly attributed to its author(s), enabling accurate search, filtering, and reporting by author name.

---

## When This Screen Is Used

- When adding a new book whose author is not yet registered in the system
- When correcting or updating author details (name change, country correction, etc.)
- When searching the catalog for all books by a specific author
- When the librarian needs to review or audit author records for data quality

## Default Data Load

This screen renders as the **Authors** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Authors tab, `LibraryController@tabIndex` loads all authors with their related country and primary genre, paginated at 15 rows per page (`authors_page`). Search and status filters only apply when the active tab is `authors`. The countries and genres reference dropdowns are fetched as active records with no pagination.

---

---

## Key Fields at a Glance

**Core Identity**
Every author must have a short name (e.g., "J.K. Rowling") that serves as the public-facing identifier. This field is globally unique across the system. The full author name (e.g., "Joanne Kathleen Rowling") is also captured and must be globally unique. A system-generated auto-increment ID is used internally as the primary key.

**Relational Mapping**
Each author is linked to a country via `country_id` (FK to `glb_countries.id`) and a primary genre via `primary_genre_id` (FK to `lib_genres.id`). These two references determine the author's geographic and literary classification for catalog search facets and analytical reports. The notes field stores free-text biographical or reference information.

---

## Business Rules and Conditions

**Unique Constraints**
The system enforces global uniqueness on both `short_name` and `author_name` columns. No two authors can share the same pen name or full name. The `is_active` boolean defaults to true and can be toggled via the status switch.

**Country & Genre Required**
Every author must be associated with a valid country (`country_id` FK to `glb_countries`) and a primary genre (`primary_genre_id` FK to `lib_genres`). Both are required fields — an author cannot be saved without both references.

**Inactive Restriction**
When `is_active` = 0, the author cannot be selected while creating or editing a book. The author dropdown in book create/edit forms filters out inactive authors.

**Author Order Maintenance**
When multiple authors are linked to a book, their display order is maintained through the `author_order` column in the junction table (`lib_book_author_jnt`). Authors are displayed in ascending order of this value. The first author (order = 1) is displayed as the primary author in citations and search results.

**Deletion Restrictions**
An author cannot be soft-deleted (moved to trash) if they have associated books in the `lib_book_author_jnt` junction table. The system checks `$author->books()->exists()` before deletion and returns an error listing up to three example book titles. The user must reassign or delete the books first. Force-deletion from trash catches foreign key constraint violations and displays a generic dependency error.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view. Restore sets `deleted_at` to null without modifying other fields.

---

## Book-Author Junction (`lib_book_author_jnt`)

The junction table links books to authors in a many-to-many relationship. Supports multiple authors per book with ordering and primary author designation. Each row represents one author assignment for one book.

### Junction Table Fields

- **`book_id`** (FK → `lib_books_master.id`, ON DELETE CASCADE) — The book being linked to an author.
- **`author_id`** (FK → `lib_authors.id`, ON DELETE CASCADE) — The author being linked to the book. Dropdown filter: Only active authors are shown in book create/edit author selection.
- **`author_order`** (INT NOT NULL DEFAULT 1) — Display order of authors (1 = first author). Authors are displayed in ascending order. The first author (order = 1) is typically displayed as the primary author in citations and search results, even if `is_primary` is not set.
- **`is_primary`** (TINYINT(1) NOT NULL DEFAULT 0) — Whether this is the primary author. Only one author per book should be marked as primary. Used in shortened citations and search snippets (e.g., "Introduction to Algorithms (Cormen et al.)").
- **Unique Key:** `(book_id, author_id, author_order)` — prevents the same author from appearing at the same position for the same book.
- Supports soft delete via `deleted_at`.

### Junction Table Business Rules

1. **Cascade Delete on Book Removal** — If a book is deleted, all its author junction records are automatically removed (ON DELETE CASCADE).
2. **Cascade Delete on Author Removal** — If an author is deleted, all their book junction records are automatically removed (ON DELETE CASCADE).
3. **Duplicate Prevention** — The same author cannot appear more than once at the same display position for the same book (enforced by composite unique key).
4. **Active Author Filtering** — Only active authors (`is_active = 1`) appear in the author selection dropdown when linking authors to books.
5. **Primary Author Designation** — Only one author per book should be marked as `is_primary = 1`. The primary author's name is used in shortened citations and card displays.
6. **Author Order Enforcement** — Authors are displayed in ascending order of `author_order`. When adding multiple authors, the system should auto-assign sequential order values.

## Workflow Steps

**Adding a New Author**
The librarian navigates to Library → Library Mgt → Masters and selects the Authors tab. They click "Add Author", which opens a create form. They enter the short name (pen name) and full author name. They select the country from a searchable dropdown of active countries and the primary genre from the active genres list. Optional notes can be added. The Active toggle defaults to ON. On click of Save, the system validates uniqueness of both name fields, checks that the country and genre references exist, and persists the record. A success message is shown.

**Editing an Author**
The librarian clicks the Edit icon on any row. The form pre-populates with the existing values. Any fields can be modified. On Update, the system re-validates uniqueness (ignoring the current record's own values) and logs attribute changes.

**Deleting an Author**
If the author has no linked books, clicking Delete soft-deletes the record and moves it to the Trash view. If linked books exist, the system blocks deletion and shows an error message listing example book titles.

---

## Example Scenario

The school library acquires a new set of books by "Ruskin Bond". The librarian checks the Authors tab, searches for "Ruskin Bond", and finds the author is not yet registered. They click Add Author, enter "Ruskin Bond" as the short name and "Ruskin Bond" as the full name, select "India" as the country and "Fiction" as the primary genre, and save. The new author is now available in the author dropdown when cataloging the new books.

---

## Related Screens

- **Books Master** — Where authors are assigned to books via the author selection interface
- **Genres** — Provides the `primary_genre_id` reference used by this screen
- **Countries** (Global Master) — Provides the `country_id` reference used by this screen

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibAuthorController`
**Model:** `Modules\Library\Models\LibAuthor` (table: `lib_authors`)
**Requests:** `LibAuthorRequest` (validates create and update)
**Policy:** `LibAuthorPolicy` (permissions: `tenant.lib-authors.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-authors', LibAuthorController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `authors` under `library.tabIndex`

Key controller methods:
- `index()` — Redirects to `library.tabIndex` with `tab=authors`
- `create()` — Returns create view with active countries and genres
- `store(LibAuthorRequest)` — Creates author in DB transaction, logs activity
- `show($id)` — Loads author with country, primaryGenre, and books relations; logs view activity
- `edit($id)` — Returns edit view with active countries and genres
- `update(LibAuthorRequest, $id)` — Updates author in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Checks for associated books before deletion; blocks if books exist; soft-deletes if safe
- `trashed()` — Lists soft-deleted authors with country and genre, paginated at 15
- `restore($id)` — Restores soft-deleted author in DB transaction
- `forceDelete($id)` — Force-deletes with `QueryException('23000')` catch for FK violations
- `toggleStatus($id)` — Toggles `is_active` boolean via AJAX; uses `Gate::authorize('tenant.lib-authors.update')`

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-authors.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-authors.*` | Full CRUD + restore + forceDelete |
| Librarian (view only) | `tenant.lib-authors.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibAuthorPolicy` methods which map to `tenant.lib-authors.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Authors tab. The system loads the list of all authors with their country and genre information, showing 15 records per page. The user can search by author name or short name, or filter by active/inactive status. To add a new author, the user clicks Add Author, fills in the short name and full name, selects a country and primary genre from dropdowns, and saves. The system checks that no other author has the same short name or full name, then saves the record. To edit, the user clicks the edit icon, changes any field, and updates. To delete, the system first checks if the author is linked to any books. If linked, deletion is blocked with a message showing which books. If not linked, the author is moved to the trash, from where it can be restored or permanently deleted.

---

## Validate Before Save

**Create/Update (`LibAuthorRequest`):**
1. **short_name:** required, string, max:50, unique on `lib_authors.short_name` (ignoring self on update)
2. **author_name:** required, string, max:200, unique on `lib_authors.author_name` (ignoring self on update)
3. **country_id:** required, exists on `glb_countries.id`
4. **primary_genre_id:** required, exists on `lib_genres.id`
5. **notes:** nullable, string
6. **is_active:** boolean (default: true via `prepareForValidation` — checkbox unchecked maps to 0)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Duplicate short name | "This short name is already taken." | 422 |
| Duplicate author name | "This author name already exists." | 422 |
| Missing author name | "Author name is required." | 422 |
| Invalid country | "Selected country is invalid." | 422 |
| Invalid genre | "Selected genre is invalid." | 422 |
| Delete author with books | "Cannot delete author '[name]' because they have [N] associated books. Example books: [titles]... Please reassign or delete these books first." | 302 (redirect back) |
| Force delete with FK dependency | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." | 302 (redirect back) |

---

## Success Scenarios

- A librarian adds a new author "Ruskin Bond" with country "India" and genre "Fiction". The system validates uniqueness, saves the record, and displays "Author created successfully."
- A librarian edits an author's country from "USA" to "United Kingdom". The system detects the change, logs the attribute change in the activity log, and displays "Author updated successfully."
- A librarian deletes an author with no linked books. The system soft-deletes the record, moves it to trash, and displays "Author moved to trash successfully."

---

## Failure Scenarios

- A librarian tries to create an author with short name "J.K. Rowling" but another author already has that short name. The system returns a validation error: "This short name is already taken."
- A librarian tries to delete "J.K. Rowling" who is linked to 5 books. The system blocks the deletion and shows "Cannot delete author 'J.K. Rowling' because they have 5 associated books. Example books: Harry Potter and the Philosopher's Stone, Harry Potter and the Chamber of Secrets, Harry Potter and the Prisoner of Azkaban... Please reassign or delete these books first."
- A librarian tries to force-delete an author from trash who still has junction records. The system catches the FK constraint violation and shows "Cannot delete this record: it is referenced by other records. Remove all dependencies first."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_authors` | Primary table with `short_name VARCHAR(50) UNIQUE`, `author_name VARCHAR(200) UNIQUE`, soft-deletes via `deleted_at` |
| Junction | `lib_book_author_jnt` | Many-to-many link to `lib_books_master` with `author_order` and `is_primary` |
| FK Reference | `glb_countries` | Country selection via `country_id` FK |
| FK Reference | `lib_genres` | Primary genre selection via `primary_genre_id` FK |
