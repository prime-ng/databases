# ACC — Table Summary (21 Tables)

**Module:** Accounting | **Prefix:** `acc_` | **Date:** 2026-03-21

---

## Domain 1: Core Accounting (12 tables)

| # | Table | Purpose | Key FKs |
|---|-------|---------|---------|
| 1 | `acc_financial_years` | Fiscal year config with locking (April–March) | — |
| 2 | `acc_account_groups` | Hierarchical Chart of Accounts (Tally's 28 + custom) | self-ref parent_id |
| 3 | `acc_ledgers` | Individual accounts (bank, cash, student, employee, vendor) | account_group_id, student_id→std_students, employee_id→sch_employees, vendor_id→vnd_vendors |
| 4 | `acc_voucher_types` | Voucher type definitions (Payment, Receipt, Contra, Journal, Sales, Purchase, etc.) | — |
| 5 | `acc_vouchers` | **THE HEART** — every financial transaction is a voucher | voucher_type_id, financial_year_id, cost_center_id |
| 6 | `acc_voucher_items` | Debit/Credit line items per voucher | voucher_id (CASCADE), ledger_id, cost_center_id |
| 7 | `acc_cost_centers` | Department/activity-based P&L tracking | self-ref parent_id |
| 8 | `acc_budgets` | Fiscal year budget per cost center per ledger | financial_year_id, cost_center_id, ledger_id |
| 9 | `acc_tax_rates` | GST rate config (CGST/SGST/IGST/Cess) | — |
| 10 | `acc_ledger_mappings` | Cross-module ledger links (Fees, Transport, Vendor, Inventory, Payroll) | ledger_id |
| 11 | `acc_recurring_templates` | Auto-posting journal templates | voucher_type_id |
| 12 | `acc_recurring_template_lines` | Template Dr/Cr line items | recurring_template_id (CASCADE), ledger_id |

## Domain 2: Banking (2 tables)

| # | Table | Purpose | Key FKs |
|---|-------|---------|---------|
| 13 | `acc_bank_reconciliations` | Bank statement reconciliation sessions | ledger_id |
| 14 | `acc_bank_statement_entries` | Imported bank transactions for matching | reconciliation_id (CASCADE), matched_voucher_item_id |

## Domain 3: Fixed Assets (3 tables)

| # | Table | Purpose | Key FKs |
|---|-------|---------|---------|
| 15 | `acc_asset_categories` | Asset types with depreciation config (SLM/WDV) | — |
| 16 | `acc_fixed_assets` | Individual asset register | asset_category_id, vendor_id→vnd_vendors, voucher_id |
| 17 | `acc_depreciation_entries` | Depreciation records per period | fixed_asset_id (CASCADE), financial_year_id, voucher_id |

## Domain 4: Expense Claims (2 tables)

| # | Table | Purpose | Key FKs |
|---|-------|---------|---------|
| 18 | `acc_expense_claims` | Staff expense claims with approval workflow | employee_id→sch_employees, voucher_id |
| 19 | `acc_expense_claim_lines` | Claim line items with receipt uploads | expense_claim_id (CASCADE), ledger_id |

## Domain 5: Tally Integration (2 tables)

| # | Table | Purpose | Key FKs |
|---|-------|---------|---------|
| 20 | `acc_tally_export_logs` | Tally XML export audit trail | exported_by→sys_users |
| 21 | `acc_tally_ledger_mappings` | Our ledgers ↔ Tally ledger names | ledger_id (UNIQUE) |

## Existing Table Enhancement

| Table | Enhancement | Columns Added |
|-------|------------|---------------|
| `sch_employees` | ALTER TABLE — 14 payroll columns | is_active, created_by, staff_category_id, ledger_id, salary_structure_id, bank_name, bank_account_number, bank_ifsc, pf_number, esi_number, uan, pan, ctc_monthly, date_of_leaving |
