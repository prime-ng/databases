# Tax Rate — Business Requirements

## What This Screen Does

The Tax Rate screen manages the tax percentages used across the system (GST, VAT, TDS, etc.). Each tax rate has a name, code, percentage value, and optional effective date range.

## When This Screen Is Used

- **During accounting setup** when configuring applicable tax rates.
- **When tax rates change** due to government regulation updates.
- **When adding new tax types** for specific transaction categories.

## Key Fields

- **Name** (string 100) — Tax display name (e.g., "GST 18%")
- **Code** (string 20) — Short identifier (e.g., "GST18")
- **Rate** (decimal 5,2) — Tax percentage (e.g., 18.00)
- **Effective From** (date, nullable) — Start of applicability
- **Effective To** (date, nullable) — End of applicability
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Rate Validation:**
Rate must be between 0 and 100. Enforced at both form validation and database constraint expectation (though no DB CHECK constraint exists).

**Unique Code:**
Tax code must be unique (enforced by UNIQUE key composite with deleted_at).

**Effective Date Range:**
If `effective_from` is set, the tax rate applies only to transactions on or after that date. If `effective_to` is set, it applies only on or before that date. Both are optional — a tax rate with no date range is always applicable.

**No Delete Guard:**
There is no check for whether the tax rate is referenced by vouchers or other records. This creates orphan risk — deleting a tax rate that is in use could break existing financial records.

**No System Guard:**
There is no system protection flag. All tax rates can be edited and deleted regardless of usage.

**Soft Delete:**
Uses SoftDeletes. Trash view, restore, and forceDelete routes available.

## Workflow

1. User navigates to Accounting → Setup Masters → Tax Rate.
2. Table shows: Name, Code, Rate %, Effective From/To, Active toggle, Actions.
3. User creates a tax rate with name, code, rate, optional date range.
4. No delete guards — user can delete any tax rate even if used in transactions.

## Requirements

- MUST display at `/accounting/tax-rate?tab=tax-rates` as paginated table
- MUST authorize via `tenant.accounting.tax-rate.*` policy gates
- MUST validate rate between 0 and 100 inclusive
- MUST enforce unique tax code
- MUST support effective_from/effective_to date range filtering
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
- **SHOULD** add delete guard for tax rates referenced by vouchers (to prevent orphan data)
