# Resource Types Master — Business Requirements

## What This Screen Does

The Resource Types Master screen defines the classification of all resource formats available in the library — for example, "Physical Book", "E-Book", "Magazine", "Journal", "Newspaper", "DVD", "Audio Book". Each resource type has a unique business code, display name, and four boolean flags that determine its behavior: whether it represents a physical item, a digital item, an audio book, and whether it can be borrowed. Resource types are referenced by `lib_books_master.resource_type_id` and `lib_fine_slab_config.resource_type_id`, making them foundational to how resources are cataloged, circulated, and fined.

---

## When This Screen Is Used

- During initial library setup when defining what kinds of media the library stocks
- When adding a new resource format (e.g., "E-Reader Device", "Interactive CD-ROM")
- When modifying flags on existing resource types (e.g., changing a type from borrowable to reference-only)
- When configuring fine slabs that apply differently to different resource types

## Default Data Load

This screen renders as the **Resource Type** tab within the Library Masters hub (`library.mgt/masters`). When the user navigates to Library → Library Mgt → Masters and selects the Resource Type tab, `LibraryController@tabIndex` loads all resource types ordered by latest first, paginated at 15 rows per page (`resource_types_page`). Search and status filters only apply when the active tab is `resource-type`.

---

---

## Key Fields at a Glance

**Core Identity**
Each resource type has a unique business code (e.g., "PHY_BOOK", "EBOOK", "AUDIO_BK") limited to 30 characters, and a display name (e.g., "Physical Book", "E-Book", "Audio Book") limited to 100 characters. The code is globally unique.

**Behavioral Flags**
Four boolean flags control how the resource type behaves in the system:
- **is_physical** (default: 1) — Marks the type as a physical/tangible resource. When set to 1, physical copies must be tracked with barcodes and assigned to specific shelf locations.
- **is_digital** (default: 0) — Marks the type as a digital/electronic resource. When set to 1, the associated digital file (PDF, EPUB, etc.) must be managed with appropriate download and view permissions.
- **is_audio_books** (default: 0) — Marks the type specifically as an audio book format
- **is_borrowable** (default: 1) — Controls whether resources of this type can be checked out (circulated). Setting to 0 makes them in-library-use-only.

A resource type can have both `is_physical` and `is_digital` set to 1 if appropriate (e.g., a book with both print and digital formats), or all flags could be 0 for non-borrowable reference materials.

---

## Business Rules and Conditions

**Unique Constraints**
The `code` column has a UNIQUE constraint at the database level. No two resource types can share the same code.

**Borrowing Restriction**
When `is_borrowable` = 0, resources of this type cannot be issued to any library member, regardless of the book's own `is_reference_only` flag.

**Physical Resource Handling**
When `is_physical` = 1, every copy of a book with this resource type must be tracked with a unique barcode and assigned to a specific shelf location for physical retrieval.

**Digital Resource Handling**
When `is_digital` = 1, the associated digital file (PDF, EPUB, audio, video) must be managed with appropriate download and view permissions. Access controls (student/teacher/staff download flags) and license management apply automatically based on the digital resource configuration.

**Inactive Restriction**
When `is_active` = 0, the resource type cannot be selected while creating or editing a Book Master record or a Fine Slab Config. Existing books referencing an inactive type retain their reference, but the type is hidden from new selections.

**Deletion Restrictions**
The controller's `destroy()` method does not explicitly check for associated books before soft-deletion. However, the database has FK constraints on `lib_books_master.resource_type_id` and `lib_fine_slab_config.resource_type_id`. The `forceDelete()` method catches foreign key constraint violations and displays a generic dependency error.

**Soft Deletes and Restore**
All deletions are soft (`deleted_at` timestamp). Trashed records are accessible via the dedicated Trash view. Restore sets `deleted_at` to null.

---

## Workflow Steps

**Adding a New Resource Type**
The librarian navigates to Library → Library Mgt → Masters and selects the Resource Type tab. They click "Add Resource Type". They enter a unique code (e.g., "DVD") and name (e.g., "DVD Video"). They set the behavioral flags appropriately — whether this type is physical, digital, audio book, and borrowable. The Active toggle defaults to ON. On Save, the system validates the code uniqueness and persists the record.

**Editing a Resource Type**
The librarian clicks the Edit icon on any row. All fields, including the behavioral flags, can be modified. The system re-validates code uniqueness, ignoring the current record.

**Deleting a Resource Type**
Clicking Delete soft-deletes the record. If the resource type is referenced by any book or fine slab config, the database FK constraint prevents permanent deletion during force-delete.

---

## Example Scenario

The school library starts stocking audio books for the first time. The librarian goes to Resource Types, clicks Add Resource Type, enters code "AUDIO_BK" and name "Audio Book", sets `is_audio_books=Yes`, `is_physical=No`, `is_digital=Yes`, `is_borrowable=Yes`, and saves. Now when cataloging audio book titles, the librarian selects "Audio Book" as the resource type. The system will correctly classify the resource as digital and borrowable, and apply appropriate circulation rules.

---

## Related Screens

- **Books Master** — Where the resource type is assigned to each book
- **Fine Slab Config** — Where resource type can be used as a filter for fine slab applicability
- **Book Purchase Items** — Where resource type determines whether a purchase item creates a physical copy or a digital resource

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibResourceTypeController`
**Model:** `Modules\Library\Models\LibResourceType` (table: `lib_resource_types`)
**Requests:** `LibResourceTypeRequest` (validates create and update)
**Policy:** `LibResourceTypePolicy` (permissions: `tenant.lib-resource-types.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`)
**Route:** Resource route `Route::resource('lib-resource-types', LibResourceTypeController::class)` under library prefix plus restore/forceDelete/toggleStatus extras
**Tab:** `resource-type` under `library.tabIndex`

Key controller methods:
- `index()` — Redirects to `library.tabIndex` with `tab=resource-type`
- `create()` — Returns create view
- `store(LibResourceTypeRequest)` — Creates resource type in DB transaction, logs activity
- `show($id)` — Loads resource type
- `edit($id)` — Returns edit view
- `update(LibResourceTypeRequest, $id)` — Updates resource type in DB transaction; computes changed attributes for activity log
- `destroy($id)` — Soft-deletes without explicit book check; logs activity
- `trashed()` — Lists soft-deleted resource types, paginated at 15
- `restore($id)` — Restores soft-deleted resource type in DB transaction
- `forceDelete($id)` — Force-deletes with `QueryException('23000')` catch for FK violations
- `toggleStatus($id)` — Toggles `is_active` boolean; uses `Gate::authorize('tenant.lib-resource-types.update')`; supports both AJAX and non-AJAX response

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-resource-types.*` | Full CRUD + restore + forceDelete |
| Librarian Admin | `tenant.lib-resource-types.*` | Full CRUD + restore + forceDelete |
| Librarian (view only) | `tenant.lib-resource-types.viewAny`, `.view` | Read-only access to list and detail views |

All access is gated by `LibResourceTypePolicy` methods which map to `tenant.lib-resource-types.*` permissions.

---

## How This Screen Works — Logic Flow (Non-Technical)

The user navigates to Library → Library Mgt → Masters and selects the Resource Type tab. The system loads all resource types, 15 per page. The user can search by code or name, or filter by status. To add a new type, the user clicks Add Resource Type, enters a unique code and name, sets the four behavioral flags (is it physical? digital? audio book? borrowable?), and saves. The system validates the code is unique. To edit, the user clicks the edit icon. To delete, the system soft-deletes the record. If the resource type is in use by any book or configuration, the database prevents permanent deletion.

---

## Validate Before Save

**Create/Update (`LibResourceTypeRequest`):**
1. **code:** required, string, max:30, unique on `lib_resource_types.code` (ignoring self on update)
2. **name:** required, string, max:100
3. **is_physical:** boolean (default: 0 via `prepareForValidation` — checkbox unchecked maps to 0)
4. **is_digital:** boolean (default: 0)
5. **is_audio_books:** boolean (default: 0)
6. **is_borrowable:** boolean (default: 0)
7. **is_active:** boolean (default: true via `prepareForValidation`)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Missing code | "The resource type code is required." | 422 |
| Duplicate code | "This resource type code is already taken." | 422 |
| Code too long | "The resource type code must not exceed 30 characters." | 422 |
| Missing name | "The resource type name is required." | 422 |
| Name too long | "The resource type name must not exceed 100 characters." | 422 |
| Force delete with dependencies | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." | 302 (redirect back) |

---

## Success Scenarios

- A librarian adds a new resource type "Audio Book" with code "AUDIO_BK" and appropriate flags. The system saves and displays "Resource type created successfully."
- A librarian updates a resource type to change `is_borrowable` from Yes to No, making it reference-only. The system logs the change and displays "Resource type updated successfully."
- A librarian deletes a resource type that is not used by any book or config. The system soft-deletes and displays "Resource type moved to trash."

---

## Failure Scenarios

- A librarian tries to create "E-Book" with code "EBOOK" but that code already exists. The system returns "This resource type code is already taken."
- A librarian tries to force-delete "Physical Book" from trash, but 200 books reference this type. The database FK constraint fires and the system shows "Cannot delete this record: it is referenced by other records. Remove all dependencies first."

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_resource_types` | Primary table with `code VARCHAR(30) UNIQUE`, `name VARCHAR(100) NOT NULL`, four boolean flags, soft-deletes via `deleted_at` |
| FK Reference | `lib_books_master` | `resource_type_id` FK referencing `lib_resource_types.id` — restricts deletion if books exist |
| FK Reference | `lib_fine_slab_config` | `resource_type_id` FK (nullable) referencing `lib_resource_types.id` |
| FK Reference | `lib_book_purchases_items` | `resource_type_id` FK referencing `lib_resource_types.id` — restricts deletion if purchase items exist |
