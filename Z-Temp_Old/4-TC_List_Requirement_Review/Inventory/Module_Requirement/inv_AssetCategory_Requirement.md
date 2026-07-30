# Asset Categories — Business Requirements

## What This Screen Does

The Asset Categories screen defines the classification taxonomy for fixed assets (Computers, Furniture, Vehicles, etc.). Each category carries a **useful life** (years) and **annual depreciation rate** (%) that drives accounting depreciation schedules. Categories appear as the fourth tab of the Inventory Masters page at `/inventory/masters?tab=asset-categories`.

## When This Screen Is Used

- **Asset Classification**: Grouping assets by type for reporting and accounting
- **Depreciation Configuration**: Setting useful life and depreciation rate per category (used by Accounting module for `acc_fixed_assets` entries)
- **Depreciation Rate Limits**: Capping depreciation rate at 100% max with 0.01% step precision

## Key Fields

- **Name** (required) — Category display name, max 100 characters
- **Code** (optional) — Short identifier code, max 20 characters
- **Useful Life (Years)** (optional) — Integer or half-year increments (0.5 step), displayed as "X yrs" on cards
- **Annual Depreciation Rate %** (optional) — Decimal with 0.01% step, 0–100 range, displayed as "X%" on cards
- **Assets Count** (computed) — Number of assets currently assigned to this category, shown as a badge on the card
- **Is Active** (boolean) — Soft enable/disable via toggle-status

## Business Rules

**Toggle Status:** The toggle endpoint flips `is_active` and returns a JSON response with the new state.

**Activity Logging:** All CRUD operations log activity via `activityLog()`:
- Create: `"Asset category '{name}' created."`
- Update: `"Asset category '{name}' updated."`
- Delete: `"Asset category '{name}' deleted."`
- Restore: `"Record restored successfully."`

**Asset Category Service:** `AssetCategoryService` handles CRUD with auth user + activity logging. Exposes `create()`, `update()` and `delete()`.

## Workflow

1. Staff navigates to Inventory → Masters → Asset Categories tab
2. Staff clicks "Add Asset Category" to open the modal, fills in name (required), code, useful life, depreciation rate
3. Category appears in the card list with code badge, useful life, depreciation rate, asset count
4. Staff can toggle active status directly from the list
5. Staff can view/edit/delete via the actions dropdown
6. Staff can search by name and filter by status (All/Active/Inactive)

## Related Screens

- **Assets** — Assets are linked to these categories (`inv_assets.category_id`)
- **Stock Groups** — First tab of Masters; sibling tab
- **Accounting** — Depreciation data syncs to `acc_fixed_assets`

## Requirements

- MUST display paginated asset categories at `/inventory/masters?tab=asset-categories` as cards with search and status filter
- MUST authorize via `tenant.inventory.asset-category.*` policy gates
- MUST validate store with 5 rules (name required, code nullable, useful_life_years nullable numeric min:0 step:0.5, depreciation_rate nullable numeric min:0 max:100 step:0.01)
- MUST create category via AssetCategoryService with auth user and activity log
- MUST update category via AssetCategoryService with activity log
- MUST support AJAX toggle-status returning JSON
- MUST support soft-delete lifecycle with restore/force-delete
- MUST display computed `assets_count` badge on each card
- MUST log all CRUD operations via activityLog()
