# Budget — Business Requirements

## What This Screen Does

The Budget screen manages financial budget allocations. Each budget defines an expected amount for a specific combination of financial year, cost center, and ledger. It enables variance reporting by comparing budgeted amounts against actual voucher postings.

## When This Screen Is Used

- **At the start of a financial year** when setting departmental/ledger-wise budgets.
- **During the year** when monitoring actual vs budgeted spending.
- **At year-end** for budget variance analysis and reporting.

## Key Fields

- **Financial Year** (FK → acc_financial_years, RESTRICT) — Budget period
- **Cost Center** (FK → acc_cost_centers, RESTRICT) — Department/project
- **Ledger** (FK → acc_ledgers, RESTRICT) — Account head
- **Budget Amount** (decimal 15,2) — Allocated amount
- **Actual Amount** (computed) — Sum of voucher postings against this combo
- **Variance** (computed) — Budget Amount - Actual Amount
- **Is Active** (boolean)
- **Created By** (FK → sys_users, nullable)

## Business Rules

**Unique Combination:**
The combination of financial_year_id + cost_center_id + ledger_id must be unique. Enforced by UNIQUE key and form validation. Duplicate entries are rejected.

**Budget vs Actual Report:**
A variance report compares budgeted amounts to actual voucher totals for each unique combination. The actual amount is computed by summing voucher items for the given ledger, cost center, and FY.

**RESTRICT FKs:**
All three reference tables (financial years, cost centers, ledgers) have RESTRICT delete rules — they cannot be deleted if referenced by any budget record.

**Delete Guard:**
No additional delete guard beyond FK RESTRICT. Budgets can be deleted freely as long as there are no referential constraints blocking.

## Workflow

1. User navigates to Accounting → Transactions → Budgets.
2. Table shows: Financial Year, Cost Center, Ledger, Budget Amount, Actual Amount, Variance, Actions.
3. User creates a budget by selecting FY, cost center, ledger, and entering budget amount.
4. Duplicate FY+CC+Ledger combinations are rejected.
5. Variance report is accessible showing budget vs actual comparison.

## Requirements

- MUST display at `/accounting/budget?tab=budgets` as paginated table
- MUST authorize via `tenant.accounting.budget.*` policy gates
- MUST enforce unique FY + Cost Center + Ledger combination
- MUST compute actual amount from voucher postings for the combo
- MUST show variance (budget - actual) in the report
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
