# Fixed Asset — Business Requirements

## What This Screen Does

The Fixed Asset screen manages the organization's capital assets. Each fixed asset belongs to an asset category and tracks purchase details, depreciation method/rate, current book value, and salvage value. Depreciation entries are generated against assets over their useful life.

## When This Screen Is Used

- **When purchasing new capital assets** (buildings, vehicles, equipment, furniture).
- **At period-end** when running depreciation for all assets.
- **When tracking asset book value** over time.
- **When disposing or retiring assets.**

## Key Fields

- **Name** (string 200) — Asset display name
- **Asset Code** (string 50, unique) — Unique asset identifier
- **Asset Category** (FK → acc_asset_categories, RESTRICT) — Classification
- **Purchase Date** (date) — Date of acquisition
- **Purchase Cost** (decimal 15,2) — Acquisition cost
- **Salvage Value** (decimal 15,2) — Estimated residual value
- **Current Book Value** (decimal 15,2) — Cost minus accumulated depreciation
- **Depreciation Method** (enum: SLM/WDV) — Inherited or overridden from category
- **Depreciation Rate** (decimal 5,2) — Rate percentage
- **Useful Life Years** (integer, nullable) — Expected life
- **Purchase Description** (text, nullable)
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Initial Book Value:**
On creation, `current_book_value` is set equal to `purchase_cost`. Depreciation reduces this value over time.

**Depreciation Calculation:**
SLM: Annual depreciation = (cost - salvage) / useful_life
WDV: Annual depreciation = current_book_value × rate%

**Depreciation Entries:**
Depreciation runs generate `DepreciationEntry` records against each asset. These entries are RESTRICT FK — cannot delete asset with existing depreciation entries.

**Delete Guard:**
An asset cannot be deleted if it has depreciation entries (`isDeletable()` checks `$this->depreciationEntries()->count() === 0`).

**Unique Asset Code:**
Asset code must be unique (enforced by UNIQUE key composite with deleted_at).

**Purchase Date Validation:**
Purchase date must not be in the future.

## Workflow

1. User navigates to Accounting → Assets & Integration → Fixed Assets.
2. Table shows: Name, Code, Category, Purchase Cost, Current Book Value, Depreciation Method, Active toggle, Actions.
3. User creates an asset: selects category, enters purchase details, sets depreciation params.
4. Book value initialized to purchase cost on creation.
5. Depreciation entries accumulate over time, reducing book value.
6. Asset with depreciation entries cannot be deleted.

## Requirements

- MUST display at `/accounting/fixed-asset?tab=fixed-assets` as paginated table
- MUST authorize via `tenant.accounting.fixed-asset.*` policy gates
- MUST set current_book_value = purchase_cost on creation
- MUST prevent purchase_date in the future
- MUST enforce unique asset code
- MUST prevent deletion if depreciation entries exist
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
