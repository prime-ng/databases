# slb_Author — Business Requirements

## What This Screen Does

The Author Master is a full CRUD feature for managing book authors within the Syllabus Books module. It provides a unified list view as a tab under `/syllabus-books?tab=author` with search/filter capabilities, inline status toggling, permission-gated action buttons (View, Edit, Delete), pagination (10 per page), and a dedicated trash management view for soft-deleted records. Each author record captures name (unique), qualification, bio, and active status, and is linked to books via a `slb_book_author_jnt` pivot table that includes role assignment (CONTRIBUTOR, CO_AUTHOR, EDITOR, PRIMARY) and ordinal ordering.

This screen is the first CRUD tab in the Syllabus Books module. Without author records, books cannot be associated with their writers, editors, or contributors. The feature ensures that author data is clean (unique name constraint, validated fields) and recoverable via soft-delete with full trash lifecycle (restore, force delete).

---

## When This Screen Is Used

- **New Author Registration** when a new author needs to be added to the system before associating them with books
- **Author Profile Update** when an author's qualification, bio, or active status needs to be modified
- **Author Deactivation** when an author should no longer be active but their historical book associations must be preserved
- **Author Cleanup** when an author record needs to be permanently removed from the system (force delete) — blocked if books are still linked
- **Trash Recovery** when a mistakenly deleted author needs to be restored along with their book associations

## Default Data Load

This screen is accessed via the route prefix `/syllabus-books/authors` and is served by `AuthorController` (resource controller with extra routes). The master tab view loads directly inside the Syllabus Books tabbed layout. The index loads with:
- All active and inactive authors ordered by `name ASC`
- `withCount('books')` for showing associated book counts
- Pagination (10 records per page)
- Search filters: name/bio (LIKE), qualification (LIKE), status (exact 0/1)
- Create form loads empty fields with a default active status switch

---

## Key Fields at a Glance

**`name`** (VARCHAR 150, NOT NULL, UNIQUE): The author's display name. Must be unique across all authors — duplicate names are caught either by the database unique index or validated via `AuthorRequest` with `ignore:self` on update.

**`qualification`** (VARCHAR 200, NULLABLE): The author's academic/professional qualification. Optional, max 200 characters.

**`bio`** (TEXT, NULLABLE): A biographical description of the author. Optional, free-text.

**`is_active`** (BOOLEAN, DEFAULT 1): Toggle controlling whether the author is available for book association. Controlled via a switch on the list view and a checkbox on the create/edit form. Forced to `0` via `prepareForValidation` when unchecked.

---

## Business Rules and Conditions

**Unique Name Constraint**
Each author must have a unique `name`. Duplicate detection is done both at the database level (unique index `uq_author_name`) and at the application level (QueryException 23000 caught in controller). On update, the rule ignores the current record.

**Soft Delete with Active Flag**
When an author is deleted (destroy), the record is soft-deleted (`deleted_at` timestamp set) AND `is_active` is forced to `false`. This ensures trashed authors are also inactive. Restoration sets `deleted_at = NULL` but does NOT automatically re-activate.

**Cascading Pivot Cleanup**
Force-deleting an author first removes all pivot rows in `slb_book_author_jnt` for that author, then performs a force delete. If the author is referenced by any books (FK constraint via pivot), the operation is caught by a QueryException 23000 and the user is redirected with an error message.

**Activity Logging**
Every CRUD operation logs an activity entry: Created, Updated, Trashed, Restored, Deleted (force delete), Toggled (status). This provides an audit trail for all author changes.

**Permission Gating**
Each controller method is individually gated:
- `index` → `tenant.author.viewAny`
- `create`/`store` → `tenant.author.create`
- `show` → `tenant.author.view`
- `edit`/`update`/`toggleStatus` → `tenant.author.update`
- `destroy` → `tenant.author.delete`
- `trashedAuthor`/`restore` → `tenant.author.restore`
- `forceDelete` → `tenant.author.forceDelete`

---

## Workflow Steps

**Creating an Author**
The user navigates to the Author tab and clicks "Add Author". The create form loads with fields for name, qualification, bio, and an active/inactive toggle. The user fills in the name (required), optionally adds qualification and bio, sets the active status, and submits. Validation runs via `AuthorRequest`. On success, the author is created, a "Created" activity is logged, and the user is redirected back to the author list with a success flash message. On duplicate name, the error is caught and displayed.

**Viewing an Author**
The user clicks the View button on any author row. The show page displays all author fields (name, qualification or hyphen, bio or hyphen, status badge, created/updated timestamps, and the number of associated books). The sidebar provides "Back to List" and "Edit Author" buttons (permission-gated).

**Editing an Author**
The user clicks Edit on an author row. The edit form pre-fills all fields with existing values. The user modifies fields and submits. Validation runs, duplicate names are caught (ignoring self), and on success the author is updated with an "Updated" activity log entry.

**Deleting an Author**
The user clicks Delete on an author row. The system soft-deletes the record (sets `deleted_at` and `is_active=false`), logs "Trashed", and redirects with a success message. The author disappears from the active list and appears in the trash view.

**Restoring an Author**
The user navigates to the Trash view and clicks Restore on a trashed author. The system restores the record (`deleted_at = NULL`), logs "Restored", and redirects to the trash view. The author reappears in the active list (though still with `is_active=false` until manually toggled).

**Force Deleting an Author**
The user clicks Force Delete on a trashed author. The system removes all pivot rows, then permanently deletes the author record. If books are still linked via the pivot table, the FK constraint blocks deletion and the user sees an error. On success, "Deleted" is logged and the record is gone permanently.

**Toggling Author Status**
The user clicks the status toggle switch on any author row. An AJAX POST flips `is_active` (0↔1), logs "Toggled", and returns a JSON `{success, is_active, message}` response. The UI updates the toggle and status indicator without a page reload.

---

## Example Scenario

The school librarian wants to add author "R.K. Narayan" to the system.

The librarian navigates to the Syllabus Books module and clicks the Author tab. They see the existing author list with search/filter options. They click "Add Author" and enter:
- Name: "R.K. Narayan"
- Qualification: "BA, MA in English Literature"
- Bio: "One of India's most celebrated authors, known for his works set in the fictional town of Malgudi."
- Status: Active

The system validates the data, creates the author record, logs the activity, and returns to the author list with a green success banner. The new author appears in the list sorted alphabetically with "1" associated books (none yet).

Later, when a book "Swami and Friends" is created, the librarian can select "R.K. Narayan" as the PRIMARY author from the author dropdown and add other authors (e.g., an editor) with different roles via the book create form.

---

## Related Screens

- **Book Create/Edit** — Authors are selected and assigned roles within the book create/edit form
- **Book Show** — Author names and roles are displayed on the book detail page
- **Author Trash** — Dedicated view for managing soft-deleted author records
- **Syllabus Books Dashboard** — The main tabbed interface that hosts the Author tab alongside Books, Notes, Note Ratings, and Settings tabs

---

## Requirements

- The system MUST expose a full RESTful resource controller for authors with 11 routes including index, create, store, show, edit, update, destroy, trash view, restore, force delete, and toggle status.
- The system MUST route all author endpoints under the URL prefix `/syllabus-books/authors` (module URL prefix `/syllabus-books`).
- The system MUST wrap all routes with `module:SYLLABUS_BOOKS` middleware — if the module is disabled, the system returns HTTP 404.
- The system MUST authorize each action via `Gate::authorize()`:
  - `index` → `tenant.author.viewAny`
  - `create`/`store` → `tenant.author.create`
  - `show` → `tenant.author.view`
  - `edit`/`update`/`toggleStatus` → `tenant.author.update`
  - `destroy` → `tenant.author.delete`
  - `trashedAuthor`/`restore` → `tenant.author.restore`
  - `forceDelete` → `tenant.author.forceDelete`
- The system MUST validate input via `AuthorRequest`:
  - `name`: required, string, max:150, unique:slb_book_authors (ignore self on update)
  - `qualification`: nullable, string, max:200
  - `bio`: nullable, string
  - `is_active`: required, boolean (forced via `prepareForValidation`: unchecked → 0)
- The system MUST catch duplicate name violations at the database level (QueryException with code 23000) and redirect back with a user-friendly error message.
- The system MUST enforce a unique index `uq_author_name` on the `name` column in `slb_book_authors`.
- The system MUST support soft deletes on `slb_book_authors` via the `SoftDeletes` trait.
- The system MUST set `is_active = false` when an author is soft-deleted (destroy).
- The system MUST cascade-delete pivot rows from `slb_book_author_jnt` when an author is force-deleted.
- The system MUST block force delete when the author is still referenced by books (FK constraint 23000), showing an error message.
- The system MUST support inline status toggling via AJAX POST that returns JSON `{success, is_active, message}`.
- The system MUST log activity entries for every CRUD operation (Created, Updated, Trashed, Restored, Deleted, Toggled).
- The system MUST paginate the active author list (10 per page) and the trash view (10 per page).
- The system MUST provide search/filter capabilities on the index view: name/bio (LIKE), qualification (LIKE), status (exact 0/1).
- The system MUST order the author list by `name ASC`.
- The system MUST display an empty state with the message "Not Data Found" when no records match the current filters.
- The system MUST display action buttons (View, Edit, Delete) permission-gated per row.
- The system MUST display a status toggle switch on every row (permission-gated).
- The system MUST display the count of associated books (`withCount('books')`) on each row.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | All `tenant.author.*` permissions | Full CRUD + Trash + Toggle |
| Librarian | `tenant.author.viewAny`, `tenant.author.create`, `tenant.author.update`, `tenant.author.view` | Create, Edit, View, Toggle |
| Academic Admin | `tenant.author.viewAny`, `tenant.author.view` | View only |
| Teacher | No explicit permission | No access |
| Guest (unauthenticated) | None | Redirected to `/login` |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. The user clicks the Author tab in the Syllabus Books module. The `module:SYLLABUS_BOOKS` middleware checks the module is enabled (404 if disabled). Authentication middleware redirects guests to login.
2. `Gate::authorize()` checks for `tenant.author.viewAny`. If missing, HTTP 403 is returned.
3. The index view loads all authors ordered by name, paginated (10 per page), with associated book counts and filter controls.
4. The user can search by name/bio (partial match), filter by qualification (partial match), and filter by status (active/inactive). Filters can be combined. A reset button clears all filters.
5. Each row shows the author name, qualification, book count, a status toggle switch, and action buttons (View, Edit, Delete).
6. Clicking "Add Author" navigates to the create form. Validation runs on submit. Success creates the record with a "Created" activity log entry and redirects to the list with a flash message.
7. Clicking View opens the author detail page showing all fields. Sidebar provides Back and Edit links.
8. Clicking Edit opens the pre-filled edit form. Submit triggers the update logic with duplicate name check (ignoring self).
9. Clicking Delete soft-deletes the record (sets `is_active=false` and `deleted_at`) and redirects with a success message.
10. The Trash view lists soft-deleted authors. Each row has Restore and Force Delete buttons (permission-gated).
11. Restore recovers the record. Force Delete permanently removes the author (after pivot cleanup), blocked by FK constraint if books are linked.

---

## Validate Before Save (Multiple Conditions)

1. **Name Required** — `name` must not be empty. Error: "The name field is required."
2. **Name Max Length** — `name` must not exceed 150 characters. Error: "The name must not be greater than 150 characters."
3. **Name Unique** — `name` must be unique in `slb_book_authors`. Error (store): redirect back with error "The name has already been taken." Error (update): "The name has already been taken."
4. **Qualification Max Length** — `qualification` must not exceed 200 characters. Error: "The qualification must not be greater than 200 characters."
5. **Is Active Boolean** — `is_active` must be a boolean value. Error: "The is active field must be true or false."
6. **Invalid Author ID** — Accessing show/edit/update/destroy with a non-existing ID returns HTTP 404.
7. **Soft-Deleted Author View** — show() on a soft-deleted author returns 404 (no `withTrashed`).
8. **Restore on Non-Trashed** — restore() on a non-trashed or non-existing ID returns 404.
9. **Force Delete Blocked** — forceDelete() on an author linked to books returns an error flash message "Cannot delete: Author is associated with one or more books."
10. **Unauthorized Access** — Missing permission returns HTTP 403 "This action is unauthorized."

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| name is empty | "The name field is required." | 422 |
| name exceeds 150 chars | "The name must not be greater than 150 characters." | 422 |
| duplicate name on store | "The name has already been taken." | Redirect with error |
| duplicate name on update | "The name has already been taken." | 422 |
| qualification exceeds 200 chars | "The qualification must not be greater than 200 characters." | 422 |
| is_active is not boolean | "The is active field must be true or false." | 422 |
| invalid/non-existing author ID | 404 Not Found | 404 |
| soft-deleted author viewed directly | 404 Not Found | 404 |
| restore on non-trashed author | 404 Not Found | 404 |
| force delete on author with books | "Cannot delete: Author is associated with one or more books." | Redirect with error |
| unauthorized (missing permission) | "This action is unauthorized." | 403 |
| module disabled | 404 Not Found | 404 |
| guest access | Redirect to /login | 302 |

---

## Success Scenarios

**SC-001: Create a New Author with All Fields**
1. Admin clicks "Add Author" on the Author tab.
2. Enters name "R.K. Narayan", qualification "MA English", bio "Acclaimed Indian author", status "Active".
3. Submits the form.
4. System validates, creates the author record, logs "Created" activity.
5. Redirects to author list with success flash. New author appears in the sorted list.

**SC-002: Toggle Author Status Active/Inactive**
1. Admin views the author list and clicks the toggle switch on an active author.
2. AJAX POST fires. System flips `is_active` from true to false.
3. JSON response returns `{success: true, is_active: false, message: "Status toggled successfully"}`.
4. Toggle UI updates immediately. Activity log records "Toggled".

**SC-003: Force Delete an Author with No Books**
1. Admin soft-deletes an author, then navigates to the Trash view.
2. Admin clicks "Force Delete" on the trashed author.
3. System removes pivot rows and permanently deletes the author.
4. Redirects to trash view with success flash. Author is gone permanently.

---

## Failure Scenarios

**FC-001: Duplicate Author Name Rejected**
1. Admin creates author "R.K. Narayan" successfully.
2. Admin attempts to create another author with the same name "R.K. Narayan".
3. System detects duplicate (either via validation or 23000 exception).
4. Redirects back with error message "The name has already been taken." Form preserves entered data.

**FC-002: Force Delete Blocked by Linked Books**
1. Author "R.K. Narayan" is associated with 3 books via the pivot table.
2. Admin soft-deletes the author, then attempts force delete.
3. System tries to delete pivot rows but FK constraint blocks due to remaining book references.
4. Redirects back with error "Cannot delete: Author is associated with one or more books."

**FC-003: Unauthorized Access by Invalid Role**
1. A Teacher (lacking `tenant.author.*` permissions) navigates to the Author tab.
2. `Gate::authorize()` throws an authorization exception.
3. System returns HTTP 403 with "This action is unauthorized."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Primary Table | `slb_book_authors` | `id` PK AI, `name` VARCHAR(150) UNIQUE, `qualification` VARCHAR(200) NULLABLE, `bio` TEXT NULLABLE, `is_active` BOOLEAN DEFAULT 1, `created_at`, `updated_at`, `deleted_at` |
| Pivot Table | `slb_book_author_jnt` | `book_id` FK→`slb_books.id`, `author_id` FK→`slb_book_authors.id`, `author_role` ENUM(PRIMARY,CO_AUTHOR,EDITOR,CONTRIBUTOR), `ordinal` TINYINT, COMPOSITE PK(book_id, author_id) |
| Related Table | `slb_books` | Books that reference authors via the pivot table |
| Module Dependency | SyllabusBooks Module | Core module providing the tabbed interface and all related book/note features |
| Module Dependency | User & Permission Module | Authentication, authorization (`sys_users`), and gates (`tenant.author.*`) |
| Module Dependency | Activity Log Module | Activity logging for all CRUD operations |
