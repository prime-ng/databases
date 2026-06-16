# Accounting Module — Requirements Overview

**Module:** Accounting | **Laravel Module:** `Modules/Accounting/` | **Prefix:** `acc_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/accounting/*` | **RBS Module:** K — Finance & Accounting (70 sub-tasks)
**Inspired by:** Tally Prime | **Version:** 4.0

## Module Overview

The Accounting module implements a **Tally-Prime inspired double-entry bookkeeping system** for Indian K-12 schools. Every financial transaction flows through a unified **Voucher Engine** as Dr/Cr pairs, ensuring the accounting equation (Assets = Liabilities + Equity) always holds.

**Core Principle:** The Accounting module owns the Voucher Engine. **Payroll** and **Inventory** are separate modules that consume the engine via a shared `VoucherServiceInterface` contract.

**Indian School Context:**
- Schools operate as Trusts/Societies (Income & Expenditure model)
- Financial year: April 1 to March 31
- Statutory deductions: PF, ESI, Professional Tax, TDS
- Tally integration for CA filing

## Requirements by Domain

| # | File | Domain | Tables |
|---|------|--------|--------|
| 1 | `Requirements/chart-of-accounts.md` | Chart of Accounts | Account Groups, Ledgers, Ledger Mappings |
| 2 | `Requirements/vouchers.md` | Voucher Engine | Voucher Types, Vouchers, Voucher Items |
| 3 | `Requirements/financial-years.md` | Financial Years | Financial Years |
| 4 | `Requirements/cost-centers-budgets.md` | Cost Centers & Budgets | Cost Centers, Budgets |
| 5 | `Requirements/tax-configuration.md` | Tax Configuration | Tax Rates |
| 6 | `Requirements/bank-reconciliation.md` | Bank Reconciliation | Bank Reconciliations, Bank Statement Entries |
| 7 | `Requirements/fixed-assets.md` | Fixed Assets & Depreciation | Asset Categories, Fixed Assets, Depreciation Entries |
| 8 | `Requirements/expense-claims.md` | Expense Claims | Expense Claims, Expense Claim Lines |
| 9 | `Requirements/recurring-templates.md` | Recurring Templates | Recurring Templates, Recurring Template Lines |
| 10 | `Requirements/tally-integration.md` | Tally Integration | Tally Export Logs, Tally Ledger Mappings |
| 11 | `Requirements/event-mapping.md` | Cross-Module Event Mapping | Module Events, Event Voucher Configs, Event Line Templates, Event Processing Log |
| 12 | `Requirements/reports-dashboard.md` | Reports & Dashboard | — (computed from voucher data) |

## Core Concepts

**Double-Entry Balance:** Every voucher MUST have `sum(debit items) = sum(credit items)`.

**Ledger Balance Computation:** Balance = `opening_balance ± sum(voucher_items)` — NEVER stored, always computed.

**Financial Year Lock:** Locked FY prevents all voucher edits.

**Voucher Number Immutability:** Once assigned, `voucher_number` can NEVER be changed or reused.

**System Entity Protection:** Records with `is_system = true` cannot be deleted.

**No tenant_id:** Dedicated database per tenant — data isolation at DB level.

## Table Summary

| # | Table | Domain |
|---|-------|--------|
| 1 | `acc_financial_years` | Core |
| 2 | `acc_account_groups` | Core |
| 3 | `acc_ledgers` | Core |
| 4 | `acc_voucher_types` | Core |
| 5 | `acc_vouchers` | Core (Heart) |
| 6 | `acc_voucher_items` | Core |
| 7 | `acc_cost_centers` | Core |
| 8 | `acc_budgets` | Core |
| 9 | `acc_tax_rates` | Core |
| 10 | `acc_ledger_mappings` | Core |
| 11 | `acc_recurring_templates` | Core |
| 12 | `acc_recurring_template_lines` | Core |
| 13 | `acc_bank_reconciliations` | Banking |
| 14 | `acc_bank_statement_entries` | Banking |
| 15 | `acc_asset_categories` | Assets |
| 16 | `acc_fixed_assets` | Assets |
| 17 | `acc_depreciation_entries` | Assets |
| 18 | `acc_expense_claims` | Expense |
| 19 | `acc_expense_claim_lines` | Expense |
| 20 | `acc_tally_export_logs` | Tally |
| 21 | `acc_tally_ledger_mappings` | Tally |
| 22 | `acc_module_events` | Event Mapping |
| 23 | `acc_event_voucher_configs` | Event Mapping |
| 24 | `acc_event_voucher_line_templates` | Event Mapping |
| 25 | `acc_event_processing_log` | Event Mapping |

## Existing Table Enhancement

| Table | Change | Purpose |
|-------|--------|---------|
| `sch_employees` | ALTER TABLE — add 14 columns | Payroll integration fields (ledger_id, bank details, statutory IDs, CTC) |

## Role Permissions

| Role | Access |
|------|--------|
| School Admin | Full access |
| Accountant | Vouchers, ledgers, reports, bank recon, budgets, Tally mapping |
| Cashier | Receipt/Payment vouchers, cash/bank book only |
| Auditor | Read-only access to all reports and vouchers |

## Integration Points

| Source Module | Accounting Action |
|--------------|-------------------|
| StudentFee | Receipt Voucher (Dr Bank, Cr Fee Income) |
| Transport | Sales/Receipt Voucher for transport fees |
| Payroll | Payroll Journal Voucher (Dr Salary Expense, Cr Payables) |
| Inventory | Purchase Voucher (GRN), Stock Journal (Stock Issue) |

## Related Files

- Full detailed specification: `Design/Account_Requirement_v4.md`
- DDL: `DDL/ACC_DDL_v2.sql`
- Remote entry enhancement: `DDL/ACC_Remote_Entry_ddl.sql`
- Employee enhancement: `DDL/ACC_SchEmployees_Enhancement.sql`
- Table summary: `Design/ACC_TableSummary.md`
- Initial architecture plan: `Design/Initial_Plan_v4.md`
