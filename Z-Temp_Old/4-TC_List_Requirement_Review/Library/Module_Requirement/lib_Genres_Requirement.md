# Lib Genre — Business Requirements

## What This Screen Does

The Library Genres screen manages a flat (non-hierarchical) list of literary genres used to classify books by style, form, or subject matter. Genres complement the category system by providing a secondary classification dimension — while categories define structural organization (e.g., "Fiction > Science Fiction"), genres define literary characteristics (e.g., "Dystopian," "Cyberpunk," "Space Opera"). A book can be assigned multiple genres through the `lib_book_genre_jnt` junction table.

This screen operates as a tab within the Library Configuration hub, providing standard CRUD operations plus trash management and AJAX status toggling. The interface presents a simple list with code, name, description, and active status columns. The design emphasizes simplicity since genres are flat reference data without parent-child relationships or ordering concerns.

Genre data is referenced by the Author master (each author can have a primary genre) and by book cataloging (each book can have multiple genres). Proper genre configuration ensures consistent classification across the library's catalog, enabling genre-based browsing, filtering, and reporting.

---

## When This Screen Is Used

- When initializing library master data and defining the complete genre taxonomy
- When adding new literary genres to accommodate diverse book collections
- When editing genre names or descriptions to better reflect classification standards
- When deactivating genres that are no longer relevant to the collection
- When restoring accidentally deleted genres from the trash
- When permanently removing obsolete genres (after ensuring no books are associated)

## Default Data Load

The Genres screen opens as a tab pane within the Library Configuration hub. The `index()` method redirects to the hub tab view. When the `tab=genre` parameter is active, the private query helper loads genres paginated (10 per page, `genres_page` paginator name) with optional search filtering by code or name, and status filtering. All pagination links append `tab=genre` to maintain tab context.

---

## Key Fields at a Glance

### Basic Information

**Code** — A unique VARCHAR(30) identifier serving as the genre's shorthand reference code. Must be unique across all genres including soft-deleted records. **Name** — The display name of the genre (max 100 characters), e.g., "Science Fiction," "Mystery," "Biography." **Description** — An optional VARCHAR(255) field for describing the genre's scope and characteristics.

### Status

**Is Active** — A boolean toggle controlling whether the genre appears in selection dropdowns across the system. Inactive genres are excluded from new assignments but retain their existing book associations.

---

## Business Rules and Conditions

1. **Search Filter Availability** — Active genres are available as search filters in both staff and student book search interfaces. Only genres with `is_active = 1` appear in the genre filter dropdowns on catalog search pages.

2. **Unique Code Validation** — Genre codes must be unique using `Rule::unique('lib_genres')->ignore($id)->whereNull('deleted_at')` to exclude the current record on updates.

3. **Transaction-Wrapped Store** — The `store()` method wraps the create operation in a DB transaction to ensure atomicity. If the activityLog call fails after record creation, the transaction rolls back.

4. **Delete Protection with Books** — The `destroy()` method checks `$genre->books()->exists()` before proceeding. If books are associated with the genre, deletion is blocked with: "Cannot delete genre: it is linked to books."

5. **Status Permission Separation** — Unlike most modules that use `.update` permission for status toggling, `toggleStatus()` uses `.status` permission (`tenant.lib-genres.status`). This allows finer-grained access control where status management can be delegated separately.

6. **Soft Delete Behavior** — Soft-deleted genres retain their junction table associations. Restoring a genre restores its access without requiring reassignment to previously linked books.

---

## Book-Genre Junction (`lib_book_genre_jnt`)

The junction table links books to literary genres in a many-to-many relationship. Enables genre-based browsing and powers the recommendation engine.

### Junction Table Fields

- **`book_id`** (FK → `lib_books_master.id`, ON DELETE CASCADE) — The book being tagged with a genre.
- **`genre_id`** (FK → `lib_genres.id`, ON DELETE CASCADE) — The genre assigned to the book. Dropdown filter: Only active genres are shown in the genre selection. Indexed: `idx_genre_book` for efficient genre-based searches.
- **Unique Key:** `(book_id, genre_id)` — prevents duplicate genre assignment per book.

### Junction Table Business Rules

1. **Cascade Delete on Book Removal** — If a book is deleted, all its genre junction records are automatically removed (ON DELETE CASCADE).
2. **Cascade Delete on Genre Removal** — If a genre is deleted, all its book junction records are automatically removed (ON DELETE CASCADE).
3. **Duplicate Prevention** — The same genre cannot be assigned to the same book more than once (enforced by composite unique key).
4. **Active Genre Filtering** — Only active genres (`is_active = 1`) appear in the genre selection dropdown when assigning genres to books.

## Workflow Steps

1. Navigate to Library Configuration hub and select the Genres tab
2. Review the list of existing genres with active/inactive status badges
3. Click "Add Genre" to open the create form
4. Enter code, name, description, and set active status
5. Submit to save — system validates uniqueness and required fields
6. Edit any genre by clicking the edit icon to modify its details
7. Toggle active status via the status switch (AJAX, uses `.status` permission)
8. Delete a genre — system verifies no books are linked
9. Restore from trash or force-delete permanently

---

## Example Scenario

A library is cataloging a large donation of graphic novels. The existing genres — "Fiction," "Non-Fiction," "Reference" — don't adequately describe the collection. The librarian adds new genres: "Graphic Novel," "Manga," "Comics," and "Graphic Memoir." Each genre gets a unique code (e.g., "GRPH_NOVL") and a brief description. The librarian also deactivates the outdated "Pamphlets" genre that no longer applies to any current holdings. Months later, a colleague accidentally deletes "Comics" — the librarian restores it from the trash without losing any book associations.

---

## Related Screens

- Library Categories (lib-categories) — hierarchical classification companion
- Library Authors (lib-authors) — authors reference a primary genre
- Library Books Master (lib-books-master) — books consume genre assignments
- Library Configuration Hub (lib.config.index) — parent hub containing the Genres tab

---

## Requirements

**Controller Methods:** `LibGenreController` — index (redirects to tab), create, store (DB transaction), show, edit, update, destroy (checks books), trashed, restore, forceDelete, toggleStatus (uses `.status` permission)

**FormRequest Rules:** `code` → required|string|max:30|unique:lib_genres,code (ignore self). `name` → required|string|max:100. `description` → nullable|string|max:250. `is_active` → boolean. `prepareForValidation()` normalizes `is_active`.

**ActivityLog Events:** Stored, Viewed, Updated (with changes), Trashed, Restored, Deleted, Toggled

**Model Relations:** `LibGenre` has `books()` → belongsToMany via `lib_book_genre_jnt`.

**Policy Permissions:** `tenant.lib-genres.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status`

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-genres.*` | Full access |
| Library Admin | `tenant.lib-genres.*` | Full CRUD + status management |
| Librarian | `tenant.lib-genres.viewAny`, `.view`, `.create`, `.update` | View, add, edit genres |
| Cataloging Assistant | `tenant.lib-genres.viewAny`, `.view` | Read-only genre reference |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. User opens Library Configuration and clicks the Genres tab
2. The system loads all genres in a paginated list, showing code, name, and active status
3. Clicking "Add Genre" opens a simple form with code, name, description, and active toggle
4. On save, the system checks that the code hasn't been used before (even by deleted records)
5. The edit form pre-fills existing values — users can change any field
6. The status toggle button uses AJAX to instantly switch active/inactive without page reload
7. When deleting a genre, the system checks if any books are currently using it — if yes, deletion is blocked
8. Deleted genres appear in the trash tab for restoration or permanent deletion
9. The `.status` permission allows administrators to grant status-toggling rights separately from edit rights

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | code | Required | The code field is required. |
| 2 | code | Max:30 | The code must not exceed 30 characters. |
| 3 | code | Unique | The code has already been taken. |
| 4 | name | Required | The name field is required. |
| 5 | name | Max:100 | The name must not exceed 100 characters. |
| 6 | description | Max:250 | The description must not exceed 250 characters. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Validation fails | (per-field messages) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Delete blocked — has books | Cannot delete genre: it is linked to books. | 422 (redirect flash) |
| Model not found | No genre found with this ID. | 404 |
| Store transaction failure | Failed to create genre. Please try again. | 500 |

---

## Success Scenarios

**SC-001: Create a new genre**
1. User fills in code="SCIFI", name="Science Fiction", description="Fiction based on imagined future scientific advances"
2. System validates uniqueness and required fields
3. Record created with is_active=true inside a DB transaction
4. ActivityLog records "Stored" event
5. Success flash: "Genre created successfully."
6. New genre appears in the list and in all genre dropdowns

**SC-002: Toggle genre status**
1. User clicks status switch on "Pamphlets" genre to deactivate
2. AJAX request with `is_active=0` sent to toggleStatus endpoint
3. Gate checks `.status` permission
4. Record updated, ActivityLog records "Toggled"
5. JSON response confirms success
6. Badge updates from green (Active) to red (Inactive) without page reload

---

## Failure Scenarios

**FC-001: Delete genre linked to books**
1. User clicks delete on "Science Fiction" which has 15 books assigned
2. `destroy()` checks `$genre->books()->exists()` → true
3. Deletion blocked, error flash: "Cannot delete genre: it is linked to books."
4. Genre remains active in the list
5. User must reassign books to different genres before deleting

**FC-002: Create genre with duplicate code**
1. User enters code="SCIFI" which already exists
2. FormRequest unique validation fails
3. Validation error returned: "The code has already been taken."
4. Form re-displays with error message and previously entered values
5. No database operation performed

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_genres | Main genre reference table |
| Table | lib_book_genre_jnt | Junction table linking genres to books |
| Table | lib_authors | Authors reference `primary_genre_id` FK to lib_genres |
| Module | Library Authors | Consumes genre data as primary genre reference |
| Module | Library Books Master | Consumes genre assignments for book classification |
