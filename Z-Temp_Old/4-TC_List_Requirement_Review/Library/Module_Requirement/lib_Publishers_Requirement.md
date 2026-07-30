# Publishers Master — Business Requirements

## What This Screen Does

The Publishers Master screen maintains the master list of all book publishers referenced in the library catalog. Each publisher record stores a unique business code, full name, contact information (contact person, email, phone), physical address, and website URL. Publishers are linked to books via the `publisher_id` foreign key on `lib_books_master`, establishing a one-to-many relationship where one publisher can publish many books. This screen ensures accurate attribution and enables filtering and reporting by publisher.

---

## When This Screen Is Used

- When adding a new book from a publisher not yet registered in the system
- When updating publisher contact details (address, phone, email changes)
- When adding a new publishing house to the school's approved vendor list
- When searching the catalog for all books by a specific publisher

## Default Data Load

This screen renders as the **Publishers** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Publishers tab, `LibraryController@tabIndex` loads all publishers ordered by latest first, paginated at 15 rows per page (`publishers_page`). Search and status filters only apply when the active tab is `publishers`.

---

---

## Key Fields at a Glance

**Core Identity**
Every publisher has a unique business code (e.g., "OUP", "PENGUIN") limited to 30 characters, and a full name (e.g., "Oxford University Press", "Penguin Random House") limited to 200 characters. The code serves as the system identifier and is globally unique.

**Contact and Address Details**
Optional fields capture the primary contact person's name, email address, phone number, website URL, and physical address. These details are used for procurement communication and vendor management. The email is validated as a proper email format, and the website is validated as a proper URL format.

---

## Business Rules and Conditions

**Unique Constraints**
The `code` column has a UNIQUE constraint at the database level. No two publishers can share the same business code. The `name` column does not have a uniqueness constraint, but the UI should encourage unique names.

**Inactive Restriction**
When `is_active` = 0, the publisher cannot be selected while creating or editing a book or purchase order. Existing books referencing an inactive publisher retain their reference, but the publisher is hidden from new selections and dropdowns.

**Deletion Restrictions**
The controller's `destroy()` method does not explicitly check for associated books before soft-deletion. However, the database has a FK constraint (`fk_lib_booksM_publisherId`) on `lib_books_master.publisher_id` referencing `lib_publishers.id`. The `forceDelete()` method catches foreign key constraint exceptions and displays a message if books are still linked.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view. Restore sets `deleted_at` to null.

---

## Workflow Steps

**Adding a New Publisher**
The librarian navigates to Library → Library Mgt → Masters and selects the Publishers tab. They click "Add Publisher". They enter a unique code (e.g., "SCHOLASTIC") and the full publisher name (e.g., "Scholastic India Pvt. Ltd."). Optional fields include contact person, email, phone, address, and website. The Active toggle defaults to ON. On Save, the system validates the code uniqueness and persists the record.

**Editing a Publisher**
The librarian clicks the Edit icon on any row. All fields can be modified. The system re-validates code uniqueness, ignoring the current record.

**Deleting a Publisher**
Clicking Delete soft-deletes the record. If the publisher has associated books, the database FK constraint prevents deletion. During force-delete from trash, the system catches the constraint violation and shows an error message.

---

## Example Scenario

The school acquires a new set of textbooks published by "Cambridge University Press". The librarian checks the Publishers tab and confirms "Cambridge University Press" is not yet registered. They click Add Publisher, enter code "CUP", name "Cambridge University Press", contact person "John Smith", email "contact@cambridge.org", and website "https://www.cambridge.org". They save. The new publisher is now available in the publisher dropdown when cataloging the new textbooks.

---

## Related Screens

- **Books Master** — Where the publisher is assigned to each book via `publisher_id`

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibPublisherController`
**Model:** `Modules\Library\Models\LibPublisher` (table: `lib_publishers`)
**Requests:** `LibPublisherRequest` (validates create and update)
**Policy:** `LibPublisherPolicy` (permissions: `tenant.lib-publishers.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-publishers', LibPublisherController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `publishers` under `library.tabIndex`

Key controller methods:
- `index()` — Redirects to `library.tabIndex` with `tab=publishers`
- `create()` — Returns create view
- `store(LibPublisherRequest)` — Creates publisher in DB transaction, logs activity
- `show($id)` — Loads publisher; logs view activity
- `edit($id)` — Returns edit view
- `update(LibPublisherRequest, $id)` — Updates publisher in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Soft-deletes publisher without explicit book check; logs activity
- `trashed()` — Lists soft-deleted publishers, paginated at 15
- `restore($id)` — Restores soft-deleted publisher in DB transaction
- `forceDelete($id)` — Force-deletes with try/catch for FK constraint violations; checks for "foreign key constraint fails" in error message
- `toggleStatus($id)` — Toggles `is_active` boolean; uses `Gate::authorize('tenant.lib-publishers.update')`; supports both AJAX and non-AJAX response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-publishers.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-publishers.*` | Full CRUD + restore + forceDelete |
| Librarian (view only) | `tenant.lib-publishers.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibPublisherPolicy` methods which map to `tenant.lib-publishers.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Publishers tab. The system loads all publishers, 15 per page. The user can search by name, code, email, or contact person, or filter by active/inactive status. To add a publisher, the user clicks Add Publisher, enters the required code and name along with optional contact details, and saves. The system validates the code is unique. To edit, the user clicks the edit icon and modifies any field. To delete, the system immediately soft-deletes the record. If the publisher has books linked in the catalog, the database prevents permanent deletion during force-delete, and the system shows an appropriate error message.

---

## Validate Before Save

**Create/Update (`LibPublisherRequest`):**
1. **code:** required, string, max:30, unique on `lib_publishers.code` (ignoring self on update)
2. **name:** required, string, max:200
3. **address:** nullable, string
4. **contact:** nullable, string, max:100
5. **email:** nullable, email, max:100
6. **phone:** nullable, string, max:20
7. **website:** nullable, url, max:255
8. **is_active:** boolean (default: true via `prepareForValidation`)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Missing code | "The publisher code is required." | 422 |
| Duplicate code | "This publisher code is already taken." | 422 |
| Code too long | "The publisher code must not exceed 30 characters." | 422 |
| Missing name | "The publisher name is required." | 422 |
| Name too long | "The publisher name must not exceed 200 characters." | 422 |
| Invalid email | "Please enter a valid email address." | 422 |
| Invalid website URL | "Please enter a valid website URL (e.g., https://www.example.com)." | 422 |
| Force delete with books | "Cannot delete publisher '[name]' because it has associated books. Please delete or reassign books first." | 302 (redirect back) |
| Force delete other error | "Failed to delete publisher. Error: [message]" | 302 (redirect back) |

---

## Success Scenarios

- A librarian adds "Oxford University Press" with code "OUP" and contact details. The system saves and displays "Publisher created successfully."
- A librarian updates a publisher's phone number. The system logs the change and displays "Publisher updated successfully."
- A librarian deletes a publisher with no associated books. The system soft-deletes and displays "Publisher moved to trash."

---

## Failure Scenarios

- A librarian tries to create a publisher with code "OUP" but that code already exists. The system returns "This publisher code is already taken."
- A librarian tries to force-delete "Oxford University Press" from trash, but 25 books are linked to this publisher. The database FK constraint fires, and the system catches it, displaying "Cannot delete publisher 'Oxford University Press' because it has associated books. Please delete or reassign books first."
- A librarian enters an invalid website URL like "www-oup-com". The system returns "Please enter a valid website URL (e.g., https://www.example.com)."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_publishers` | Primary table with `code VARCHAR(30) UNIQUE`, `name VARCHAR(200) NOT NULL`, soft-deletes via `deleted_at` |
| FK Reference | `lib_books_master` | `publisher_id` FK referencing `lib_publishers.id` — restricts deletion if books exist |
