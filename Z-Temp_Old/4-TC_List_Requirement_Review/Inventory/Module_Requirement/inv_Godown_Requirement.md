# Godowns / Storage Locations — Business Requirements

## What This Screen Does

The Godowns screen defines physical and logical storage locations used across the inventory system — main stores, departmental stores, lab stores, sub-locations, shelves, and more. Each godown has a name, optional code, address, and can be assigned an in-charge employee. Godowns form a **self-referencing hierarchy**: a godown can have a parent location, enabling multi-level storage structures (e.g., Main Store → Science Wing → Chemistry Lab Shelf).

This is the third tab (`?tab=godowns`) of the Inventory Masters page at `/inventory/masters`.

The system ships with 6 seeded system godowns (Main Store, Science Lab Store, Sports Store, Library Store, Stationery Store, Computer Lab Store). Additional custom godowns can be created as needed.

## When This Screen Is Used

- **Storage Setup**: Defining all physical locations where stock is kept (warehouses, rooms, shelves)
- **Location Hierarchy**: Organizing storage into parent-child hierarchies for granular tracking
- **In-Charge Assignment**: Assigning employee responsible for each storage location
- **Stock Balance Viewing**: Checking current stock quantities and values at any location
- **Sub-location Management**: Viewing child locations/shelves under a parent godown
- **Stock Transactions**: Godowns are referenced by stock entries, issues, adjustments, GRNs, asset movements, and stock balances

## Key Fields

- **Name** (required) — Display name, max 100 characters (e.g., "Main Store")
- **Code** (optional, unique) — Short identifier, max 20 characters (e.g., "MS-01"), seeded godowns use codes like "MAIN", "SCIENCE"
- **Parent Location** (optional) — Self-referencing FK to `inv_godowns.id`; selects a parent godown to create hierarchy
- **Address** (optional) — Physical location details, max 500 characters
- **In-Charge Employee** (optional) — FK to `sch_employees` (employees/user_type=EMPLOYEE), selects the person responsible
- **Is System** (boolean) — Seeded system godowns (6 built-in locations)
- **Is Active** (boolean) — Soft enable/disable

## Business Rules

**Self-Referencing Hierarchy:** The `parent_id` field references `inv_godowns.id` on the same table. When `parent_id` is NULL, the godown is a top-level location. The edit page excludes the current godown from the parent dropdown to prevent self-parenting. There is currently no circular reference detection (e.g., setting a child as its ancestor's parent).

**Delete Protection (Stock on Hand):** A godown cannot be deleted if any stock balance has `current_qty > 0` at that location. The `GodownService` checks `stockBalances()->where('current_qty', '>', 0)->exists()` and throws a `DomainException`: "Godown '{name}' cannot be deleted — it has stock on hand."

**Delete Protection (Sub-locations):** A godown cannot be deleted if it has child locations. The service checks `children()->exists()` and throws a `DomainException`: "Godown '{name}' cannot be deleted — it has sub-locations."

**Service Layer:** All CRUD operations go through `GodownService` which handles:
- Setting `created_by` / `updated_by` from the authenticated user
- Activity logging via `activityLog()` for Create, Update, Delete operations
- Delete guards (stock on hand + children)

**Code Uniqueness:** The `code` field is optional but when provided, must be unique across all godowns. The `StoreGodownRequest` validates with the `unique:inv_godowns,code` rule that ignores the current record on updates.

**Toggle Status:** The toggle endpoint flips `is_active` and returns JSON with the new state. This is used by the `<x-backend.table.status-switch>` Blade component directly from the card list.

**Seed Data:** Six system godowns are seeded with `is_system = 1`: Main Store (MAIN), Science Lab Store (SCIENCE), Sports Store (SPORTS), Library Store (LIBRARY), Stationery Store (STATIONERY), Computer Lab Store (COMP_LAB). These are intended to be protected from deletion, but the current delete guard only checks stock balances and children (no explicit `is_system` guard).

**In-Charge Employee:** References `sch_employees` via `in_charge_employee_id`. The edit view queries `User::where('user_type', 'EMPLOYEE')->where('is_active', true)` to populate the dropdown. The DDL FK constraint is commented out pending SchoolSetup module integration.

## Workflow

1. Staff navigates to Inventory → Masters → Godowns tab
2. Staff sees existing godowns as cards (name, code badge, parent, address, status toggle, actions)
3. Staff clicks "Add Godown" to open the modal and fills in name, code, parent, address, in-charge
4. Godown appears in the card list
5. Staff clicks a godown name to view details, stock balances, and sub-locations
6. Staff can edit godown details on the edit page
7. Staff can toggle active status directly from the list
8. Staff can delete godowns (blocked if stock or sub-locations exist)
9. Deleted godowns can be restored or force-deleted from the trash page

## Related Screens

- **Stock Groups** — First tab; groups categorize items but don't directly reference godowns
- **UOMs** — Second tab; units of measure independent of storage
- **Stock Items** — Items are stored in godowns via stock balances
- **Stock Balances** — Balances table (`inv_stock_balances`) references godown_id for quantity tracking
- **Stock Entries / Issues / Adjustments / GRNs** — All stock movement transactions reference a godown
- **Asset Categories / Assets** — Asset movements track from_godown_id and to_godown_id
- **Asset Moves** — Movement history records source and destination godowns

## Requirements

- MUST display paginated godowns at `/inventory/masters?tab=godowns` as cards with search and status filter
- MUST authorize via `tenant.inventory.godown.*` policy gates (5 gates: viewAny, create, view, update, delete)
- MUST validate godown store with 5 rules (name required max:100, code nullable unique max:20, parent_id exists, address max:500, in_charge_employee_id integer)
- MUST create godown with is_active=1 by default (hidden input in modal)
- MUST use GodownService for create/update/delete with activity logging
- MUST guard delete against godowns with stock on hand (current_qty > 0) — DomainException
- MUST guard delete against godowns with children (sub-locations) — DomainException
- MUST support AJAX toggle-status returning JSON
- MUST support soft-delete lifecycle with restore/force-delete
- MUST show godown detail page with two-column layout (details + tabs)
- MUST show Stock Balances on detail page with item name, SKU, quantity, values, grand total
- MUST show Sub-locations on detail page with name, code, address, status
- MUST seed 6 system godowns with is_system=1 and unique codes
- MUST log all CRUD operations via activityLog()
- MUST paginate trashed items on `/inventory/godowns/trash/view`
- MUST exclude current godown from parent dropdown on edit page
