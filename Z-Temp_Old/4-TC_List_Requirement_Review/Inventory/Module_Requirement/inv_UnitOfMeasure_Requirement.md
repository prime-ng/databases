# Units of Measure — Business Requirements

## What This Screen Does

The Units of Measure (UOM) screen defines the measurement units used across the inventory system — pieces, kilograms, litres, boxes, metres, and more. Each UOM has a name, symbol, and decimal precision (0 = whole numbers, up to 4 decimal places). The screen also manages **UOM Conversions**, which define how one unit relates to another (e.g., 1 Box = 10 Pieces).

This is the second tab (`?tab=uoms`) of the Inventory Masters page at `/inventory/masters`.

The system ships with 10 seeded system UOMs (Pieces, Kilogram, Litre, Box, Carton, Metre, Square Metre, Cubic Metre, Dozen, Pack) and 6 common conversion factors. Additional custom UOMs and conversions can be created as needed.

## When This Screen Is Used

- **UOM Definition**: Creating units for inventory item quantities (pieces, weight, volume, length)
- **Precision Configuration**: Setting decimal precision per UOM (0 for whole items, 2 for kg, etc.)
- **Conversion Management**: Defining relationships between different UOMs for automatic quantity conversion
- **UOM Assignment**: Selecting UOMs when creating stock groups or stock items

## Key Fields

**Unit of Measure**
- **Name** (required) — Display name, max 50 characters (e.g., "Kilogram")
- **Symbol** (required) — Short symbol, max 10 characters (e.g., "kg")
- **Decimal Places** (required, 0-4) — Quantity precision: 0 = whole numbers, 2 = two decimals
- **Is System** (boolean) — Seeded system UOMs (10 built-in units)
- **Is Active** (boolean) — Soft enable/disable

**UOM Conversion**
- From UOM, To UOM — FK references to `inv_units_of_measure` (must be different)
- Conversion Factor — decimal(15,6), minimum 0.000001 (e.g., 1 Box = 10 Pcs → factor = 10)
- Effective From / To — optional date range for validity
- Unique composite: (from_uom_id, to_uom_id)

## Business Rules

**Decimal Precision Range:** The `decimal_places` field is validated as an integer between 0 and 4 (inclusive). This aligns with the DDL column defined as `TINYINT` with expected range 0-4. 0 = whole numbers (Pieces), 2 = two decimals (Kilograms).

**Delete Protection:** A UOM cannot be deleted if any stock items reference it (`stockItems()->exists()`). The controller checks this and returns a flash error: "Cannot delete a UOM that is assigned to stock items."

**No Dedicated Service Layer:** Unlike Stock Groups (which uses `StockGroupService`), the UOM controller handles all business logic inline without a service/repository layer.

**Conversion Unique Constraint:** The `(from_uom_id, to_uom_id)` composite key is unique at the DB level and validated in the request. This prevents duplicate conversion definitions between the same pair of UOMs.

**Conversion Validation Rules:**
- `from_uom_id` and `to_uom_id` must be different (enforced by `different:from_uom_id` rule AND a model boot `InvalidArgumentException`)
- `conversion_factor` must be ≥ 0.000001 (prevents zero or negative factors)
- `effective_to` must be ≥ `effective_from` when both provided (validated via `after_or_equal:effective_from`)

**Activity Logging:** All CRUD operations are logged via `activityLog()`:
- Create: UOM created
- Update: UOM updated
- Delete: UOM deleted
- Restore: Record restored

**Toggle Status:** The toggle endpoint flips `is_active` and returns JSON with the new state.

**System UOMs:** Ten UOMs are seeded with `is_system = 1`: Pieces (Pcs), Kilogram (kg), Litre (L), Box (Box), Carton (Ctn), Metre (m), Square Metre (sq.m), Cubic Metre (cu.m), Dozen (Doz), Pack (Pck). System UOMs are intended to be undeletable, but the current controller only guards against deletion when stock items exist (no explicit `is_system` guard).

## Workflow

1. Staff navigates to Inventory → Masters → UOMs tab
2. Staff clicks "Add Unit of Measure" to open the modal and fills in name, symbol, decimal places
3. UOM appears in the card list
4. Staff clicks a UOM name to view details, conversions, and associated stock items
5. Staff can define conversions between UOMs (e.g., 1 Box = 10 Pieces)
6. Staff can edit UOM details on the edit page
7. Staff can toggle active status directly from the list
8. Conversions appear in a dedicated section below the UOM list on the tab

## Related Screens

- **Stock Groups** — First tab; Stock Groups can set a default UOM referencing this UOM
- **Stock Items** — Each item has a primary UOM referencing this UOM
- **Purchase Orders / GRN** — Quantities use UOMs for ordering and receiving
- **Stock Balances** — Quantities tracked per UOM

## Requirements

- MUST display paginated UOMs at `/inventory/masters?tab=uoms` as cards with search and status filter
- MUST display UOM Conversions section below the UOM list
- MUST authorize via `tenant.inventory.uom.*` policy gates
- MUST validate UOM store with 3 rules (name max:50, symbol max:10, decimal_places 0-4)
- MUST validate conversion store with 5 rules (unique composite, different UOMs, factor ≥ 0.000001, date ordering)
- MUST create UOM with is_active=1 by default (hidden input in modal)
- MUST guard delete against UOMs referenced by stock items
- MUST support AJAX toggle-status returning JSON
- MUST support AJAX conversion delete returning JSON
- MUST support soft-delete lifecycle with restore/force-delete
- MUST show UOM detail with conversions (from/to tables) and stock items on show page
- MUST seed 10 system UOMs and 6 conversion factors
- MUST log all CRUD operations via activityLog()
