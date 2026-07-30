# Asset Category — Business Requirements

## What This Screen Does

The Asset Category screen manages the classification categories for fixed assets. Each category defines the depreciation method (SLM or WDV), depreciation rate, and useful life in years. Categories are referenced by fixed assets and determine how depreciation is calculated.

## When This Screen Is Used

- **During accounting setup** when configuring fixed asset categories (e.g., Buildings, Vehicles, Furniture, Computers).
- **When adding new asset categories** for new types of capital purchases.
- **When updating depreciation rates** due to accounting policy changes.

## Key Fields

- **Name** (string 100) — Category display name
- **Code** (string 20, unique) — Short identifier
- **Depreciation Method** (enum: SLM/WDV) — Straight Line Method or Written Down Value
- **Depreciation Rate** (decimal 5,2) — Rate percentage (0–100)
- **Useful Life Years** (integer, nullable) — Expected useful life
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Depreciation Method:**
Two methods supported: SLM (Straight Line Method — equal depreciation each year) and WDV (Written Down Value — reducing balance method). The method, combined with rate, determines yearly depreciation.

**Missing Ledger IDs:**
The `depreciation_expense_ledger_id` and `accumulated_depreciation_ledger_id` fields are used by `DepreciationService` but are missing from the DDL. When depreciation runs, the service will throw a `DomainException` because it cannot find these ledger references on the category. This is a critical blocker.

**Rate Validation:**
Rate must be between 0 and 100. No DB-level CHECK constraint exists — enforced only at the application layer.

**Delete Guard:**
A category cannot be deleted if it has fixed assets referencing it. The `isDeletable()` model helper checks `$this->fixedAssets()->count() === 0`.

**Unique Code:**
Category code must be unique (enforced by UNIQUE key composite with deleted_at).

## Workflow

1. User navigates to Accounting → Assets & Integration → Asset Categories.
2. Table shows: Name, Code, Depreciation Method badge, Rate %, Useful Life, Active toggle, Actions.
3. User creates a category: name, code, method (SLM/WDV), rate, optional useful life.
4. Category linked to fixed assets cannot be deleted.

## Requirements

- MUST display at `/accounting/asset-category?tab=asset-categories` as paginated table
- MUST authorize via `tenant.accounting.asset-category.*` policy gates
- MUST support SLM and WDV depreciation methods
- MUST validate rate between 0 and 100
- MUST enforce unique category code
- MUST prevent deletion of category with existing fixed assets
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **CRITICAL:** Add `depreciation_expense_ledger_id` and `accumulated_depreciation_ledger_id` columns to DDL
