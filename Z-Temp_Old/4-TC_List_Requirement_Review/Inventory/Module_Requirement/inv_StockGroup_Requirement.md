# Stock Groups — Business Requirements

## What This Screen Does

The Stock Groups screen defines hierarchical categories for inventory items. Each stock group can have a parent group (enabling a tree structure), a default unit of measure, and a display sequence. Groups are used to organize stock items by type (Stationery, IT Equipment, Furniture, etc.) for easier browsing, reporting, and procurement planning.

This is the first tab (`?tab=stock-groups`) of the Inventory Masters page at `/inventory/masters`.

The system ships with 10 seeded stock groups (marked `is_system = 1`) covering common school inventory categories. Users can create additional custom groups and organize them hierarchically.

## When This Screen Is Used

- **Item Categorization**: Defining groups to organize stock items by type
- **Hierarchy Management**: Creating parent-child group relationships
- **Default UOM Assignment**: Setting a default unit of measure for items in the group
- **Display Ordering**: Configuring the display sequence of groups

## Key Fields

- **Name** (required) — Group display name, max 100 characters
- **Code** (optional, unique) — Short identifier code, max 20 characters. Must be unique across all groups.
- **Alias** (optional) — Alternative name, max 100 characters
- **Parent Group** (optional) — Self-referencing FK for hierarchy. If set, this group becomes a sub-group of the selected parent.
- **Default UOM** (optional) — FK to `inv_units_of_measure`. Default unit for all items assigned to this group.
- **Sequence** (default 0) — Display ordering integer
- **Is System** (boolean) — Seeded groups marked as system groups (1 = cannot be deleted)
- **Is Active** (boolean) — Soft enable/disable

## Business Rules

**Delete Protection (Stock Items):** A stock group cannot be deleted if it has any stock items assigned to it (`stockItems()->exists()`). Attempting to delete such a group throws a `DomainException` which is caught by the controller and shown as a flash error message: "Stock group '{name}' cannot be deleted — it has stock items assigned."

**Delete Protection (Child Groups):** A stock group cannot be deleted if it has any child sub-groups (`children()->exists()`). This prevents orphaned groups and maintains tree integrity. The error message: "Stock group '{name}' cannot be deleted — it has sub-groups."

**System Groups:** Ten groups are seeded with `is_system = 1`: Stationery (STAT), IT Equipment (IT-EQP), Furniture (FURN), Electrical (ELEC), Plumbing (PLMB), Sports Equipment (SPORT), Medical Supplies (MED), Cleaning Materials (CLEAN), Lab Equipment (LAB), Books & Curriculum (BOOK). These use default UOMs (mostly "Pcs", with "Litre" for cleaning materials).

**Unique Code:** The `code` field has a UNIQUE constraint at the DB level. The validation request enforces this with a `unique:inv_stock_groups,code` rule, excluding the current record's ID on updates.

**Activity Logging:** All CRUD operations log activity via `activityLog()`:
- Create: `"Stock group '{name}' created."`
- Update: `"Stock group '{name}' updated."`
- Delete: `"Stock group '{name}' deleted."`
- Restore: `"Record restored successfully."`

**Toggle Status:** The toggle endpoint flips `is_active` and returns a JSON response with the new state.

**Self-Referencing Hierarchy:** The `parent_id` foreign key references `inv_stock_groups.id` with `ON DELETE SET NULL`, meaning deleting a parent group sets `parent_id = NULL` on child groups rather than cascading the deletion.

## Workflow

1. Staff navigates to Inventory → Masters → Stock Groups tab
2. Staff clicks "Create" to open the modal and fills in group details
3. Group appears in the card list with its code badge, parent, and default UOM
4. Staff can click a group name to view its details, sub-groups, and associated stock items
5. Staff can edit the group on a dedicated edit page
6. Staff can toggle active status directly from the list
7. Staff can delete a group only if it has no stock items and no sub-groups
8. Deleted groups appear in the trash for restore or permanent deletion

## Related Screens

- **Units of Measure** — Second tab; provides default UOM options for groups
- **Stock Items** — Items assigned to stock groups (visible on show page)
- **Godowns** — Third tab; storage locations
- **Asset Categories** — Fourth tab; asset classification

## Requirements

- MUST display paginated stock groups at `/inventory/masters?tab=stock-groups` as cards with search and status filter
- MUST authorize via `tenant.inventory.stock-group.*` policy gates
- MUST validate store with 6 rules (BC-VAL-01 through 06)
- MUST enforce unique code validation, excluding own ID on update
- MUST create group via StockGroupService with auth user and activity log
- MUST update group via StockGroupService with activity log
- MUST guard delete against groups with stock items (DomainException)
- MUST guard delete against groups with child sub-groups (DomainException)
- MUST support AJAX toggle-status returning JSON
- MUST support soft-delete lifecycle with restore/force-delete
- MUST show group details with sub-groups and stock items tabs on show page
- MUST exclude self from parent dropdown on edit page
- MUST seed 10 system stock groups with is_system=1
- MUST log all CRUD operations via activityLog()
