# Fixed Assets & Depreciation — Business Requirements

## Business Need
Schools own significant fixed assets — furniture, IT equipment, vehicles, electrical installations, buildings — that depreciate over time. Proper asset tracking is needed for insurance valuation, budget planning for replacements, and accurate financial reporting. Depreciation must be calculated systematically and recorded as journal entries.

## Business Objectives
- Maintain a complete fixed asset register with purchase details
- Categorize assets by type (Furniture, IT Equipment, Vehicles, etc.)
- Calculate depreciation using Straight Line Method (SLM) or Written Down Value (WDV)
- Auto-generate depreciation journal entries through the voucher engine
- Track accumulated depreciation and current book value per asset
- Link asset purchases to their original purchase vouchers

## User Stories

**As School Accountant,** I want to:
- Define asset categories (e.g., Furniture, IT Equipment) with depreciation method and rate
- Add individual assets with purchase date, cost, and location details
- Record the supplier/vendor from whom the asset was purchased
- Link an asset to its original purchase voucher
- Run monthly or annual depreciation for all assets
- View the current book value and accumulated depreciation for each asset
- Review the depreciation journal entries created automatically

**As School Admin / Bursar,** I want to:
- View the complete asset register for insurance and audit purposes
- Know when assets are fully depreciated
- Plan replacement budgets based on asset age and condition

## Key Business Rules

**Asset Categories**
- Each category defines a depreciation method (SLM or WDV) and annual rate
- Categories are configurable — schools can add their own
- Example: IT Equipment at 40% WDV, Furniture at 10% SLM

**Depreciation Calculation**
- **Straight Line Method (SLM):** `Annual = (Purchase Cost − Salvage Value) ÷ Useful Life Years`
- **Written Down Value (WDV):** `Annual = Current Value × (Rate ÷ 100)`
- Depreciation can be run monthly or annually
- Each run creates a Journal Voucher: Dr Depreciation Expense, Cr Accumulated Depreciation

**Asset Rules**
- Purchase cost must be greater than salvage value
- Current book value = Purchase Cost − Accumulated Depreciation
- Each asset has a unique identification code
- Assets can be linked to their purchase voucher for audit trail

## Seeded Asset Categories

| Category | Method | Rate | Useful Life |
|---|---|---|---|
| Furniture & Fixtures | SLM | 10% | 10 years |
| IT Equipment | WDV | 40% | 5 years |
| Electrical Installations | SLM | 15% | 7 years |
| Office Equipment | WDV | 15% | 7 years |
| Vehicles | SLM | 20% | 5 years |

## Business Workflow

1. **Setup:** Accountant configures asset categories with depreciation methods and rates
2. **Purchase Recording:** When a new asset is purchased, it's added to the register with full details
3. **Depreciation Run:** Accountant (or scheduled job) runs depreciation monthly/annually
4. **Voucher Creation:** System creates a Journal Voucher (Dr Depreciation Expense, Cr Accumulated Depreciation)
5. **Reporting:** Asset register and depreciation schedule are available for audit and planning

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Manages asset register, runs depreciation |
| School Admin / Bursar | Reviews asset value for insurance, budgets for replacements |
| Auditor | Verifies asset register and depreciation calculations |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access to asset management |
| Accountant | Create/edit assets, run depreciation |
| Auditor | View-only access to asset register |
