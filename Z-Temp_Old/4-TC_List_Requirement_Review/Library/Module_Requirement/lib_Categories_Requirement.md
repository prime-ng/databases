# Lib Category — Business Requirements

## What This Screen Does

The Library Categories screen provides a hierarchical classification system for organizing library books into parent-child category structures. Categories form the backbone of the library's organizational taxonomy, enabling users to browse books by subject matter, literary form, or thematic grouping through a nested tree interface. The system supports unlimited depth via parent-child relationships, with each category assigned a calculated level and display order for proper tree rendering.

This screen serves as a master data management interface within the Library module hub, appearing as a tab alongside other library configurations such as Genres, Authors, and Publishers. It handles both flat listing and drag-and-drop tree reordering, allowing administrators to restructure the entire category hierarchy visually. The batch reorder functionality (updateOrder) and tree drag-drop (updateTree) methods provide flexible organization management without requiring individual category edits.

The importance of this screen extends to all book cataloging workflows — every book must be assigned to at least one category via the `lib_book_category_jnt` junction table. Without properly configured categories, the library's browsing, searching, and reporting capabilities would lack meaningful structural organization.

---

## When This Screen Is Used

- When setting up the library module for the first time and defining the book classification hierarchy
- When adding new subject categories to organize incoming book acquisitions
- When restructuring the category tree through drag-and-drop or batch reorder operations
- When editing existing category names, descriptions, or parent-child relationships
- When deactivating or soft-deleting categories that are no longer in use
- When reviewing the full category hierarchy with active/inactive status indicators
- When restoring previously deleted categories from the trash

## Default Data Load

The Categories screen opens as a tab pane within the Library Configuration hub page (`lib.config.index`). The controller's `index()` method redirects to the hub tab view. When the tab is active, the private query helper loads all categories ordered by `display_order` and paginated (10 per page, `categories_page` paginator name). The search bar supports filtering by `code`, `name`, and `status`. The active tab parameter (`tab=category`) is appended to all pagination and filter URLs to maintain tab state.

---

## Key Fields at a Glance

### Basic Information

**Code** — A unique VARCHAR(30) identifier for the category, used as a shorthand reference. Must be unique across all categories. **Name** — The full display name of the category (max 100 characters). **Description** — An optional VARCHAR(255) field providing contextual details about the category's scope and intended use.

### Hierarchy and Ordering

**Parent Category** — A nullable self-referencing foreign key to `lib_categories.id`. Determines the category's position in the tree hierarchy. Top-level categories have `NULL` parent. **Level** — A TINYINT UNSIGNED auto-calculated value: top-level categories = 1, children = parent level + 1. **Display Order** — A TINYINT UNSIGNED value controlling sibling sort order within the same parent group.

### Status

**Is Active** — A boolean toggle controlling whether the category appears in selection dropdowns and browse interfaces. Inactive categories retain their data and hierarchy position but are excluded from active book assignment workflows.

---

## Business Rules and Conditions

1. **Unique Code Validation** — Category codes must be unique across all records, including soft-deleted ones. The FormRequest uses `Rule::unique('lib_categories')->ignore($this->route('id'))->whereNull('deleted_at')` to enforce this on update while excluding the current record.

2. **Self-Reference Restriction** — A category cannot be set as its own parent. The system blocks this at both the UI level (parent dropdown excludes the current record) and the validation level (`parent_category_id` must be different from the record's own `id`).

3. **Level Auto-Calculation on Create** — When storing a new category without a `parent_category_id`, the level defaults to 1. When a parent is specified, the controller calculates `level = parent->level + 1`. The `display_order` defaults to the next available order within the same parent group.

4. **Level Recalculation on Reparent** — When updating a category's `parent_category_id`, the controller recursively recalculates the level for the category and all its descendants. This ensures the tree depth remains accurate after structural changes.

5. **Delete Protection with Children** — The `destroy()` method checks if the category has child categories (`$category->children->isNotEmpty()`). If children exist, deletion is blocked with an error flash message: "Cannot delete category with subcategories."

6. **Delete Protection with Books** — The `destroy()` method also checks if books are associated via the junction table. If books exist, deletion is blocked: "Cannot delete category with books."

7. **Soft Delete Cascade Prevention** — On soft delete, only the category record itself is marked as deleted. Child categories and book associations remain intact in the database but become inaccessible through active queries.

8. **Force Delete Safety** — The `forceDelete()` method uses a try-catch block to catch foreign key constraint violations. If the category is referenced by child categories or book junction records, the exception is caught and the user is redirected with an error message: "Cannot delete category: it is linked to existing records."

9. **Batch Reorder (updateOrder)** — Accepts an array of `{id, display_order}` pairs and updates each record in a single transaction. Used for programmatic reordering without drag-drop.

10. **Tree Drag-Drop (updateTree)** — Accepts a nested tree structure and updates parent-child relationships and display order atomically within a transaction.

---

## Book-Category Junction (`lib_book_category_jnt`)

The junction table links books to categories in a many-to-many relationship. A book can belong to multiple categories (e.g., "Fiction" and "Science Fiction"), enabling flexible browsing and filtering.

### Junction Table Fields

- **`book_id`** (FK → `lib_books_master.id`, ON DELETE CASCADE) — The book being categorized.
- **`category_id`** (FK → `lib_categories.id`, ON DELETE CASCADE) — The category assigned to the book. Dropdown filter: Only active categories are shown in the category selection. Indexed: `idx_lib_bookCategoryJnt_categoryId` for efficient filtering by category.
- **Unique Key:** `(book_id, category_id)` — prevents the same category from being assigned to the same book more than once.

### Junction Table Business Rules

1. **Cascade Delete on Book Removal** — If a book is deleted, all its category junction records are automatically removed (ON DELETE CASCADE).
2. **Cascade Delete on Category Removal** — If a category is deleted, all its book junction records are automatically removed (ON DELETE CASCADE).
3. **Duplicate Prevention** — The same category cannot be assigned to the same book more than once (enforced by composite unique key).
4. **Active Category Filtering** — Only active categories (`is_active = 1`) appear in the category selection dropdown when categorizing books.

## Workflow Steps

1. Navigate to Library Configuration hub and select the Categories tab
2. View the existing category tree with active/inactive status badges
3. Click "Add Category" to open the create form with parent category dropdown
4. Fill in code, name, description, select parent (optional), and set active status
5. System auto-calculates level and display_order on save
6. Edit a category by clicking the edit icon — update name, description, or reparent
7. Toggle active status via the status switch (AJAX, no page reload)
8. Reorder categories using drag-drop or batch reorder controls
9. Delete a category (moves to trash) — system validates no children or books attached
10. Restore from trash or permanently delete with FK safety checks

---

## Example Scenario

A school librarian is setting up the library classification system for the first time. They create top-level categories: "Fiction," "Non-Fiction," "Reference," and "Periodicals." Under "Fiction," they add sub-categories: "Science Fiction," "Fantasy," "Mystery," and "Historical Fiction." Each sub-category is automatically assigned level = 2 and an incremental display_order. Later, they realize "Fantasy" should also appear under a "Young Adult" section. They edit the "Fantasy" category to reparent it, and the system recalculates all descendant levels automatically. After a year, the "Periodicals" category is discontinued — the librarian deactivates it (rather than deleting) to preserve historical book associations.

---

## Related Screens

- Library Genres (lib-genres) — complementary classification used alongside categories
- Library Authors (lib-authors) — authors are linked to books via junction table
- Library Books Master (lib-books-master) — books inherit category assignments
- Library Configuration Hub (lib.config.index) — parent hub containing the Categories tab

---

## Requirements

**Controller Methods:** `LibCategoryController` — index (redirects to tab), create, store (auto-calculates level/display_order), show, edit, update (recalculates level on reparent), destroy (checks children + books), trashed, restore, forceDelete (catches FK exceptions), toggleStatus (AJAX), updateOrder (batch reorder), updateTree (drag-drop reorder)

**FormRequest Rules:** `code` → required|string|max:30|unique:lib_categories,code (ignore self on update with `whereNull('deleted_at')`). `name` → required|string|max:100. `parent_category_id` → nullable|exists:lib_categories,id. `description` → nullable|string|max:255. `level` → nullable|integer|min:0. `display_order` → nullable|integer|min:0. `is_active` → boolean. `prepareForValidation()` normalizes `is_active` to 0/1.

**ActivityLog Events:** Stored, Viewed, Updated (with changes array), Trashed, Restored, Deleted, Toggled, updateOrder, updateTree

**Model Events:** `LibCategory` uses `SoftDeletes` trait. On `creating`, calculates level and display_order defaults if not provided.

**Policy Permissions:** `tenant.lib-categories.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete`

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-categories.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-categories.*` | Full CRUD + tree management |
| Librarian | `tenant.lib-categories.viewAny`, `.view`, `.create`, `.update` | View, add, edit categories |
| Library Assistant | `tenant.lib-categories.viewAny`, `.view` | Read-only access |

---

## How This Screen Works — Logic Flow (Non-Technical)

1. User opens the Library Configuration page and clicks the Categories tab
2. The system loads all categories from the database, grouped by parent, and displays them in a paginated table with active/inactive badges
3. User clicks "Add Category" — the system shows a form with fields for code, name, description, parent selection, and active status
4. When saving a new category with a parent, the system automatically figures out the correct depth level and position among siblings
5. The user can click any category to view its details in read-only mode
6. Clicking the edit icon opens the same form pre-filled with existing values — changing the parent triggers automatic level recalculation for the category and all its children
7. The status toggle button sends a quick AJAX request to activate/deactivate without reloading the page
8. To delete, the system first checks if any sub-categories or books are linked — if so, deletion is blocked with a clear message
9. Deleted categories go to the Trash tab — from there they can be restored or permanently deleted (the system checks for foreign key constraints before permanent deletion)
10. Drag-drop reordering sends the new tree structure to the server, which updates all parent-child relationships and display orders in a single database transaction

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | code | Required | The code field is required. |
| 2 | code | Max:30 | The code must not exceed 30 characters. |
| 3 | code | Unique | The code has already been taken. |
| 4 | name | Required | The name field is required. |
| 5 | name | Max:100 | The name must not exceed 100 characters. |
| 6 | parent_category_id | Exists | The selected parent category is invalid. |
| 7 | description | Max:255 | The description must not exceed 255 characters. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails (view) | This action is unauthorized. | 403 |
| Gate authorization fails (create) | This action is unauthorized. | 403 |
| Delete blocked — has children | Cannot delete category with subcategories. | 422 (redirect with flash) |
| Delete blocked — has books | Cannot delete category with books. | 422 (redirect with flash) |
| Force delete — FK constraint | Cannot delete category: it is linked to existing records. | 422 (redirect with flash) |
| Model not found | No category found with this ID. | 404 |
| AJAX toggle fails | Failed to update status. Please try again. | 500 |

---

## Success Scenarios

**SC-001: Create a new top-level category**
1. User clicks "Add Category" and fills in code=REF, name="Reference Materials", leaves parent empty
2. System calculates level=1, display_order=next available
3. Record saved with is_active=true
4. Success flash: "Category created successfully."
5. Category appears in the active list with correct level and order

**SC-002: Reparent a category with level recalculation**
1. User edits "Fantasy" category, changes parent from "Fiction" (level=2) to "Young Adult" (level=1)
2. System recalculates "Fantasy" to level=2
3. All child categories under "Fantasy" are recursively recalculated
4. Success flash: "Category updated successfully."
5. Tree structure reflects new hierarchy

**SC-003: Batch reorder categories**
1. User drags categories to new positions in the tree
2. AJAX sends `updateTree` payload with new parent/order structure
3. All affected records updated in a single transaction
4. Success flash response
5. Tree renders with new ordering

---

## Failure Scenarios

**FC-001: Delete category with existing children**
1. User clicks delete on "Fiction" which has sub-categories "Sci-Fi" and "Fantasy"
2. Controller checks `$category->children->isNotEmpty()` → true
3. Deletion blocked, error flash: "Cannot delete category with subcategories."
4. Category remains active in the tree
5. User must reassign or delete children first

**FC-002: Force delete category with book associations**
1. User navigates to Trash tab and clicks force-delete on a category that has books
2. Controller's `forceDelete()` runs inside try-catch
3. Database throws foreign key constraint violation
4. Catch block redirects with error: "Cannot delete category: it is linked to existing records."
5. Category remains in trash

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_categories | Main category table with self-referencing FK |
| Table | lib_book_category_jnt | Junction table linking categories to books |
| Module | Library Books Master | Consumes category assignments for book cataloging |
| Module | Library Configuration Hub | Parent hub containing the Category tab |
