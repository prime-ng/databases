# FinanceAccounting Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** FAC  |  **Module Path:** `Modules/Accounting/`
**Module Type:** Tenant  |  **Database:** `tenant_db`
**Table Prefix:** `acc_*`  |  **Processing Mode:** RBS_ONLY
**RBS Reference:** Finance & Accounting (Tally-inspired voucher engine)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/FAC_FinanceAccounting_Requirement.md`
**Gap Analysis:** N/A (Partial code at ~30%)
**Generation Batch:** 8/10

---

## Section 1 — Executive Summary

### 1.1 Purpose

The FinanceAccounting (FAC) module is the complete double-entry accounting engine for Prime-AI tenant schools. Unlike the V1 design (which positioned `fac_*` as a façade over a separate `acc_*` layer), V2 consolidates everything under `Modules/Accounting/` with the `acc_*` table prefix. The existing ~30% partial code confirms this unified architecture.

The engine is Tally-inspired: every financial transaction is a voucher with balanced Dr/Cr lines. Eight voucher types cover all school financial operations. Cross-module events (StudentFee, Payroll, Inventory, Transport) auto-create vouchers via event listeners, ensuring the general ledger stays current without manual entry.

### 1.2 Scope

| Sub-Module | Coverage |
|---|---|
| FAC1 — Chart of Accounts | Account groups (hierarchical) + ledger master + opening balances |
| FAC2 — Voucher Management | 8 voucher types, Dr/Cr posting, approval workflow, recurring templates |
| FAC3 — Bank & Cash Management | Bank account master, cash books, bank reconciliation (CSV/MT940) |
| FAC4 — Financial Reports | Trial Balance, P&L, Balance Sheet, Cash Flow, Day Book, Ledger Statement |
| FAC5 — Budget Management | Department/cost-center budgets, actual vs budget variance |
| FAC6 — Tally Integration | Ledger mapping, XML export (TallyPrime-compatible) |
| FAC7 — GST Compliance | GSTIN, CGST/SGST/IGST, GSTR-1/3B, e-invoicing (IRN) |
| FAC8 — TDS Management | TDS deduction on vendor payments, Form 16, Form 26Q |
| FAC9 — Fixed Assets | Asset register, SLM/WDV depreciation per IT Act rates |
| FAC10 — Year-End Closing | Period lock, P&L carry-forward, next-year opening balances |

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| Sub-modules (FAC1–FAC10) | 10 |
| `acc_*` tables (existing + proposed) | 21 |
| Named routes (existing in web.php) | ~65 |
| Controllers (existing) | 18 |
| Models (existing) | 21 |
| Migrations (existing) | 0 confirmed (not yet created) |
| Services (proposed) | 6 |
| FormRequests (proposed) | 12 |
| Jobs (proposed) | 3 |

### 1.4 Implementation Status

| Layer | Status | Detail |
|---|---|---|
| Routes | 🟡 Exists | `web.php` — 18 controllers registered, ~65 routes |
| Controllers | 🟡 Exists | 18 controllers (stubs/partial) |
| Models | 🟡 Exists | 21 models with `acc_*` table mapping |
| DB Migrations | 📐 Proposed | No migration files found |
| Services | 📐 Proposed | None found |
| FormRequests | 📐 Proposed | None found |
| Blade Views | 📐 Proposed | Not confirmed |
| Jobs | 📐 Proposed | None found |
| Tests | 📐 Proposed | None found |

**Overall: ~30% — routes + models + controller stubs present; logic, migrations, views absent**

---

## Section 2 — Architecture & Design Decisions

### 2.1 Decision D21 — Tally-Inspired Double-Entry Engine

Every financial event creates a **Voucher** (`acc_vouchers`) with one or more **VoucherItems** (`acc_voucher_items`). The invariant is:

```
SUM(debit_amount WHERE side='Dr') = SUM(credit_amount WHERE side='Cr')
```

This is enforced at the service layer before persistence and cannot be bypassed.

### 2.2 Voucher Types

| Code | Name | Typical Use |
|---|---|---|
| RCT | Receipt | Fee collection, donation receipt, grant receipt |
| PMT | Payment | Vendor payment, salary disbursement, utility bills |
| CTR | Contra | Bank↔Cash transfers, inter-bank transfers |
| JNL | Journal | Adjustment entries, depreciation, year-end accruals |
| SLS | Sales | Non-fee income invoices (hall rental, canteen lease) |
| PUR | Purchase | Vendor bills / purchase invoices |
| CRN | Credit Note | Reversals of sales, refunds to payers |
| DBN | Debit Note | Reversals of purchases, vendor debit notes |

### 2.3 Cross-Module Auto-Voucher Creation

| Source Module | Event | Voucher Type Created | Dr | Cr |
|---|---|---|---|---|
| StudentFee (FIN) | Fee payment received | Receipt (RCT) | Bank/Cash Ledger | Fee Income Ledger |
| HR/Payroll | Salary processed | Journal (JNL) | Salary Expense Ledger | Salary Payable Ledger |
| Inventory (INV) | Purchase order paid | Purchase (PUR) | Purchase/Expense Ledger | Vendor Payable |
| Transport (TPT) | Transport fee collected | Receipt (RCT) | Bank/Cash Ledger | Transport Income Ledger |

### 2.4 Table Architecture

The `Modules/Accounting/` module owns all `acc_*` tables directly. There is no separate `fac_*` layer. The V1 FAC/ACC split is superseded by this unified design.

**Core tables (confirmed from models):**

| Table | Model | Purpose |
|---|---|---|
| `acc_account_groups` | AccountGroup | Hierarchical COA groups |
| `acc_ledgers` | Ledger | Individual ledger accounts |
| `acc_voucher_types` | VoucherType | 8 voucher type definitions |
| `acc_vouchers` | Voucher | Voucher header |
| `acc_voucher_items` | VoucherItem | Dr/Cr line items |
| `acc_financial_years` | FinancialYear | Fiscal year master + lock status |
| `acc_cost_centers` | CostCenter | Department cost centers |
| `acc_budgets` | Budget | Budget allocations |
| `acc_bank_reconciliations` | BankReconciliation | Reconciliation sessions |
| `acc_bank_statement_entries` | BankStatementEntry | Imported statement lines |
| `acc_expense_claims` | ExpenseClaim | Staff expense claim header |
| `acc_expense_claim_lines` | ExpenseClaimLine | Expense claim line items |
| `acc_fixed_assets` | FixedAsset | Asset register |
| `acc_asset_categories` | AssetCategory | Asset category + depreciation method |
| `acc_depreciation_entries` | DepreciationEntry | Depreciation run records |
| `acc_ledger_mappings` | LedgerMapping | Module-to-ledger mappings |
| `acc_recurring_templates` | RecurringTemplate | Recurring voucher templates |
| `acc_recurring_template_lines` | RecurringTemplateLine | Template line items |
| `acc_tally_ledger_mappings` | TallyLedgerMapping | Prime ledger → Tally group name |
| `acc_tally_export_logs` | TallyExportLog | Export audit trail |
| `acc_tax_rates` | TaxRate | GST/TDS tax rate master |

**Proposed additional tables (📐):**

| Table | Purpose |
|---|---|
| `acc_gst_details` | GST transaction registry (GSTR-1/3B source) |
| `acc_tds_entries` | TDS deduction records (Form 26Q source) |
| `acc_year_end_closings` | Year-end close audit trail |

---

## Section 3 — Stakeholders & Actors

| Actor | Primary Screens | Permissions |
|---|---|---|
| Finance Officer / Bursar | Voucher entry, bank reconciliation, expense claim approval, cash book | Create/Edit/Approve vouchers; reconcile bank |
| School Accountant | COA mgmt, JE posting, reports, Tally export, GST | Full access except financial year lock |
| Principal / Management | Budget approval, finance dashboard, high-value expense approval | Approve budgets + expense claims; view-only reports |
| Department Head | Cost-center budget view, budget request submission | View own cost-center budget |
| Staff Member | Expense claim submission | Create/edit own claims only |
| External Auditor | Read-only reports (TB, P&L, BS, Ledger) | View-only; no create/edit |
| System (Scheduler) | Recurring voucher posting, depreciation run, TDS calculation | Background service |
| Cross-Module Events | StudentFee, Payroll, Inventory, Transport auto-voucher | Service-to-service only |

---

## Section 4 — Sub-Module Functional Requirements

### FAC1 — Chart of Accounts

**Status:** 🟡 Controllers + Models exist (AccountGroupController, LedgerController, FinancialYearController)

| Requirement | Detail | Priority |
|---|---|---|
| FAC1-01 | Hierarchical account groups: Assets / Liabilities / Income / Expense (root types, immutable) | Critical |
| FAC1-02 | Sub-groups under root types, unlimited depth; circular reference blocked | Critical |
| FAC1-03 | Ledger master: name, code (UNIQUE), group, opening balance, balance type (Dr/Cr), reconciliation flag | Critical |
| FAC1-04 | Financial year management: start/end dates (Apr-Mar), lock/unlock; locked year blocks new vouchers | Critical |
| FAC1-05 | Ledger with posted voucher items cannot be hard-deleted (soft delete only) | High |
| FAC1-06 | Opening balance entry: special JNL voucher type `OB`, immutable after confirmation | High |
| FAC1-07 | Bulk opening balance import via CSV with row-level error report | Medium |
| FAC1-08 | Ledger statement view: all Dr/Cr entries with running balance | High |

**Business Rules:**
- Account group `nature` (Dr/Cr) must be consistent with group type (Assets/Expense = Dr nature; Liabilities/Income = Cr nature)
- A ledger code, once used in a voucher item, is permanently reserved even after soft delete
- Financial year dates: start = 1-Apr, end = 31-Mar; overlap with existing year blocked

---

### FAC2 — Voucher Management

**Status:** 🟡 VoucherController, VoucherTypeController, VoucherItem model exist

| Requirement | Detail | Priority |
|---|---|---|
| FAC2-01 | Support all 8 voucher types (RCT/PMT/CTR/JNL/SLS/PUR/CRN/DBN) | Critical |
| FAC2-02 | Dr/Cr balance enforcement: SUM(Dr) = SUM(Cr) — validated at service layer before save | Critical |
| FAC2-03 | Minimum 2 voucher items per voucher (at least 1 Dr, 1 Cr) | Critical |
| FAC2-04 | Auto-numbering per voucher type: prefix + financial-year suffix + sequence | High |
| FAC2-05 | Voucher lifecycle: Draft → Posted → Locked (see Section 9 FSM) | Critical |
| FAC2-06 | Approve action available to Finance Officer role only | High |
| FAC2-07 | Locked-period voucher: no edit/delete/cancel; reversal voucher only | Critical |
| FAC2-08 | Post-dated vouchers: `is_post_dated=1`; excluded from reports until posting date | Medium |
| FAC2-09 | Voucher duplication: copy header + items, new number, status = Draft | Medium |
| FAC2-10 | Printable voucher view (PDF via DomPDF) with school header, Dr/Cr table, authorisation | High |
| FAC2-11 | Cost center tagging on voucher (optional): links spend to budget | High |
| FAC2-12 | Source module tracking: `source_module`, `source_type`, `source_id` for cross-module vouchers | Critical |
| FAC2-13 | Recurring template management: frequency, day_of_month, template items; auto-run via scheduler | Medium |
| FAC2-14 | Cancel voucher: sets `is_cancelled=1`; posts reversal automatically | High |

**Business Rules:**
- Receipt vouchers: exactly one bank/cash ledger in Dr lines
- Payment vouchers: exactly one bank/cash ledger in Cr lines
- Contra vouchers: both Dr and Cr must be bank/cash type ledgers
- Cancelled voucher items are excluded from all reports and balances

---

### FAC3 — Bank & Cash Management

**Status:** 🟡 BankReconciliationController, BankStatementEntry model exist

| Requirement | Detail | Priority |
|---|---|---|
| FAC3-01 | Bank account master: bank name, account number (UNIQUE), account type, branch, IFSC | Critical |
| FAC3-02 | Each bank account linked to an `acc_ledger` under Assets group | Critical |
| FAC3-03 | Primary bank account flag (only one per tenant; generated UNIQUE index) | High |
| FAC3-04 | Account types: savings / current / FD (needs maturity_date) / OD (needs overdraft_limit) | High |
| FAC3-05 | Bank statement import: CSV upload (HDFC/SBI/ICICI/Axis formats) | High |
| FAC3-06 | Auto-match: compare statement lines to voucher items by amount + date(±3 days) + narration keyword | High |
| FAC3-07 | Match confidence scoring: exact amount+date=100%; amount+±3days=85%; amount-only=70% | Medium |
| FAC3-08 | Manual match: link unmatched statement line to existing voucher item | High |
| FAC3-09 | Unmatched bank credit → create Receipt voucher; unmatched debit → create Payment voucher | High |
| FAC3-10 | Reconciliation complete only when book balance = bank statement closing balance | Critical |
| FAC3-11 | Override reconciliation completion (difference ≠ 0) requires Finance Officer permission | Medium |
| FAC3-12 | Reconciliation statement PDF: book balance + outstanding items + adjusted balance | High |
| FAC3-13 | Cash book report: all cash ledger entries with opening/closing balance for date range | High |

---

### FAC4 — Financial Reports

**Status:** 🟡 AccReportController exists (11 report endpoints in routes)

| Report | Route | Priority |
|---|---|---|
| Trial Balance | `report.trial-balance` | Critical |
| Profit & Loss | `report.profit-and-loss` | Critical |
| Balance Sheet | `report.balance-sheet` | Critical |
| Day Book | `report.day-book` | High |
| Cash Book | `report.cash-book` | High |
| Bank Book | `report.bank-book` | High |
| Ledger Statement | `report.ledger-report` | High |
| Outstanding Receivables | `report.outstanding-receivables` | High |
| Outstanding Payables | `report.outstanding-payables` | High |
| Budget Variance | `report.budget-variance` | Medium |
| GST Summary | `report.gst-summary` | Medium |

**Business Rules for Reports:**
- All reports filter by `financial_year_id` + optional date range
- Trial Balance: SUM(all Dr items) = SUM(all Cr items) — if not equal, display data integrity alert
- Balance Sheet: Assets = Liabilities + Equity (validated before render)
- Closed fiscal year data is immutable and served from historical snapshot
- PDF export via DomPDF; Excel via `fputcsv` to `php://temp` (no external package)
- Cancelled and post-dated (future) vouchers excluded from all report calculations

---

### FAC5 — Budget Management

**Status:** 🟡 BudgetController, CostCenterController, Budget/CostCenter models exist

| Requirement | Detail | Priority |
|---|---|---|
| FAC5-01 | Cost center master: name, code (UNIQUE), department, responsible person | High |
| FAC5-02 | Annual budget plan: fiscal year, total amount, status (draft/submitted/approved/active) | High |
| FAC5-03 | Budget allocation per cost center + ledger with allocated amount | High |
| FAC5-04 | Budget approval workflow: Finance Officer submits → Principal approves | High |
| FAC5-05 | Only one active budget per fiscal year per cost center (UNIQUE constraint) | High |
| FAC5-06 | Actual spend: SUM(Dr voucher items for ledger in fiscal year, approved vouchers only) | High |
| FAC5-07 | Committed spend: SUM(approved PO amounts from `vnd_purchase_orders` for cost center) | Medium |
| FAC5-08 | Available balance = allocated − committed − actual | High |
| FAC5-09 | Over-budget alert (>90% utilised): notification to Finance Officer + Department Head | High |
| FAC5-10 | Budget variance report: allocated vs committed vs actual vs variance (amount + %) | High |

---

### FAC6 — Tally Integration

**Status:** 🟡 TallyExportController, TallyLedgerMappingController, TallyExportLog, TallyLedgerMapping models exist

| Requirement | Detail | Priority |
|---|---|---|
| FAC6-01 | Ledger mapping table: Prime ledger → Tally group name + Tally ledger name | High |
| FAC6-02 | Export ledgers: generate `<ENVELOPE><TALLYMESSAGE>` XML with all mapped ledgers | High |
| FAC6-03 | Export vouchers: date-range filter; map voucher type to Tally voucher type | High |
| FAC6-04 | Tally XML validates against TallyPrime 3.x import schema | High |
| FAC6-05 | Export log: each session recorded in `acc_tally_export_logs` (date, rows, file name) | Medium |
| FAC6-06 | Download generated XML file from export log entry | Medium |
| FAC6-07 | Tally voucher type mapping: RCT→Receipt, PMT→Payment, CTR→Contra, JNL→Journal | High |

---

### FAC7 — GST Compliance

**Status:** 📐 Proposed (TaxRate model exists; GST-specific tables not confirmed)

| Requirement | Detail | Priority |
|---|---|---|
| FAC7-01 | GSTIN configuration: 15-char validation (state code + PAN + entity + Z + checksum) | High |
| FAC7-02 | Tax rate master: CGST/SGST/IGST rates; linked to voucher items on taxable transactions | High |
| FAC7-03 | Intra-state: split CGST + SGST equally; inter-state: IGST only | High |
| FAC7-04 | GSTR-1 report: group outward supplies B2B/B2C, compute tax amounts by HSN/SAC | High |
| FAC7-05 | GSTR-3B summary: outward liability, ITC available, net payable | High |
| FAC7-06 | E-invoicing: POST to IRP → receive IRN + signed JSON → generate QR code | Medium |
| FAC7-07 | GST transaction registry (`acc_gst_details`): all taxable vouchers linked | High |
| FAC7-08 | ITC tracking: GST paid on purchases credited to ITC Input ledger | High |

---

### FAC8 — TDS Management

**Status:** 📐 Proposed

| Requirement | Detail | Priority |
|---|---|---|
| FAC8-01 | TDS configuration: TDS sections (194C, 194J, 194I etc.), threshold, rate | Medium |
| FAC8-02 | TDS deduction on vendor payments: auto-calculate when vendor crosses threshold | Medium |
| FAC8-03 | TDS voucher entry: Dr Vendor Payable, Cr TDS Payable (separate from net payment) | Medium |
| FAC8-04 | TDS remittance tracking: TDS payable ledger cleared on government remittance | Medium |
| FAC8-05 | Form 26Q data compilation: quarterly TDS deduction details per vendor PAN | Medium |
| FAC8-06 | Form 16 generation (for staff salary TDS): deduction + certificate details | Low |
| FAC8-07 | TDS entries stored in `acc_tds_entries` with section, rate, amount, vendor/employee | Medium |

---

### FAC9 — Fixed Assets

**Status:** 🟡 FixedAssetController, AssetCategoryController, FixedAsset/AssetCategory/DepreciationEntry models exist

| Requirement | Detail | Priority |
|---|---|---|
| FAC9-01 | Asset category: name, depreciation method (SLM/WDV), depreciation rate, useful life | High |
| FAC9-02 | Fixed asset register: name, code (UNIQUE), category, purchase date, cost, salvage value | High |
| FAC9-03 | Asset acquisition: creates Purchase voucher (Dr Asset Ledger → Cr Bank/Vendor Payable) | High |
| FAC9-04 | SLM depreciation: `(cost − salvage) / useful_life`; prorated for partial year | High |
| FAC9-05 | WDV depreciation: `current_value × rate / 100` per year | High |
| FAC9-06 | Depreciation run: idempotent — re-run for same fiscal year replaces existing entries | High |
| FAC9-07 | Depreciation JE: Dr Depreciation Expense → Cr Accumulated Depreciation | High |
| FAC9-08 | Asset disposal: Dr Accum. Depreciation + Dr/Cr Gain/Loss → Cr Asset Ledger | Medium |
| FAC9-09 | SLM: current_value never goes below salvage_value | High |
| FAC9-10 | Net block report: cost − accumulated depreciation = net book value per asset | Medium |

---

### FAC10 — Year-End Closing

**Status:** 🟡 FinancialYearController has lock/unlock endpoints

| Requirement | Detail | Priority |
|---|---|---|
| FAC10-01 | Period lock: lock financial year — blocks all new/edit/delete vouchers for that year | Critical |
| FAC10-02 | Pre-lock validation: all vouchers in year must be Posted/Cancelled (no Drafts) | Critical |
| FAC10-03 | P&L carry-forward: net surplus/deficit journalised to Retained Earnings ledger | High |
| FAC10-04 | Opening balance carry-forward: all Balance Sheet ledger closing balances become next year's OB | High |
| FAC10-05 | Year-end close audit trail: recorded in `acc_year_end_closings` with user + timestamp | High |
| FAC10-06 | Unlock financial year: requires superadmin permission; creates audit log entry | High |
| FAC10-07 | Comparative reports: two-year comparison (current vs prior) for P&L and Balance Sheet | Medium |

---

## Section 5 — Database Schema

### 5.1 Core Voucher Tables

**`acc_voucher_types`** — 8 system + custom voucher type definitions

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | Receipt, Payment, Contra, etc. |
| `code` | VARCHAR(10) NOT NULL UNIQUE | RCT, PMT, CTR, JNL, SLS, PUR, CRN, DBN |
| `category` | VARCHAR(50) NOT NULL | cash/bank/journal/sales/purchase |
| `prefix` | VARCHAR(10) NULL | Auto-number prefix (e.g., RCT/) |
| `auto_numbering` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `last_number` | INT UNSIGNED NOT NULL DEFAULT 0 | |
| `is_system` | TINYINT(1) NOT NULL DEFAULT 0 | System types cannot be deleted |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`acc_vouchers`** — Voucher header (confirmed from Voucher model)

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `voucher_number` | VARCHAR(50) NOT NULL | Auto-generated per type |
| `voucher_type_id` | BIGINT UNSIGNED NOT NULL FK→acc_voucher_types | |
| `financial_year_id` | BIGINT UNSIGNED NOT NULL FK→acc_financial_years | |
| `date` | DATE NOT NULL | |
| `reference_number` | VARCHAR(100) NULL | Cheque/UTR/invoice ref |
| `reference_date` | DATE NULL | |
| `narration` | TEXT NULL | |
| `total_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | Sum of Dr side |
| `is_post_dated` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_optional` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_cancelled` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `cancelled_reason` | TEXT NULL | |
| `cost_center_id` | BIGINT UNSIGNED NULL FK→acc_cost_centers | |
| `source_module` | VARCHAR(50) NULL | fin, hr, inv, tpt (cross-module) |
| `source_type` | VARCHAR(100) NULL | Model class name |
| `source_id` | BIGINT UNSIGNED NULL | Source record ID |
| `status` | ENUM('draft','posted','locked') NOT NULL DEFAULT 'draft' | |
| `approved_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**Indexes:** `(financial_year_id, date)`, `(status)`, `(source_module, source_type, source_id)`

**`acc_voucher_items`** — Dr/Cr line items (confirmed from VoucherItem model)

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `voucher_id` | BIGINT UNSIGNED NOT NULL FK→acc_vouchers | |
| `ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | |
| `side` | ENUM('Dr','Cr') NOT NULL | |
| `amount` | DECIMAL(15,2) NOT NULL | |
| `cost_center_id` | BIGINT UNSIGNED NULL FK→acc_cost_centers | Line-level cost center |
| `narration` | VARCHAR(500) NULL | Line narration |
| `tax_rate_id` | BIGINT UNSIGNED NULL FK→acc_tax_rates | GST/TDS rate link |
| `sort_order` | TINYINT UNSIGNED NOT NULL DEFAULT 0 | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**Constraint (service-level):** `SUM(amount WHERE side='Dr') = SUM(amount WHERE side='Cr')` per voucher

---

### 5.2 Chart of Accounts Tables

**`acc_account_groups`** — Hierarchical COA groups

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(150) NOT NULL | |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `parent_id` | BIGINT UNSIGNED NULL FK→acc_account_groups(id) | NULL = root group |
| `group_type` | ENUM('Assets','Liabilities','Income','Expense') NOT NULL | |
| `nature` | ENUM('Dr','Cr') NOT NULL | Assets/Expense=Dr; Liab/Income=Cr |
| `is_primary` | TINYINT(1) NOT NULL DEFAULT 0 | Root-level primary groups |
| `sort_order` | INT UNSIGNED NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`acc_ledgers`** — Individual ledger accounts

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(150) NOT NULL | |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `account_group_id` | BIGINT UNSIGNED NOT NULL FK→acc_account_groups | |
| `opening_balance` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `balance_type` | ENUM('Dr','Cr') NOT NULL DEFAULT 'Dr' | |
| `as_of_date` | DATE NULL | Opening balance date |
| `allow_reconciliation` | TINYINT(1) NOT NULL DEFAULT 0 | Bank/cash ledgers |
| `has_gst` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `gst_number` | VARCHAR(15) NULL | GSTIN if applicable |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`acc_financial_years`** — Fiscal year master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(20) NOT NULL | e.g., 2025-26 |
| `start_date` | DATE NOT NULL | 1-Apr |
| `end_date` | DATE NOT NULL | 31-Mar |
| `is_locked` | TINYINT(1) NOT NULL DEFAULT 0 | Year-end close status |
| `locked_at` | TIMESTAMP NULL | |
| `locked_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.3 Bank & Reconciliation Tables

**`acc_bank_reconciliations`** — Reconciliation sessions

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | Bank ledger |
| `statement_date` | DATE NOT NULL | End date of statement |
| `opening_balance` | DECIMAL(15,2) NOT NULL | As per bank statement |
| `closing_balance` | DECIMAL(15,2) NOT NULL | As per bank statement |
| `book_balance` | DECIMAL(15,2) NULL | Computed from ledger |
| `difference` | DECIMAL(15,2) GENERATED AS `closing_balance - book_balance` | |
| `status` | ENUM('open','completed') NOT NULL DEFAULT 'open' | |
| `file_path` | VARCHAR(500) NULL | Imported statement file |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`acc_bank_statement_entries`** — Imported statement lines

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `reconciliation_id` | BIGINT UNSIGNED NOT NULL FK→acc_bank_reconciliations | |
| `transaction_date` | DATE NOT NULL | |
| `description` | VARCHAR(500) NULL | Bank narration |
| `reference` | VARCHAR(100) NULL | Cheque/UTR/NEFT ref |
| `credit_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `debit_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `balance` | DECIMAL(15,2) NULL | Running balance from bank |
| `match_status` | ENUM('unmatched','auto_matched','manually_matched','unreconcilable') NOT NULL DEFAULT 'unmatched' | |
| `match_confidence` | TINYINT UNSIGNED NULL | 0-100 score |
| `matched_voucher_item_id` | BIGINT UNSIGNED NULL FK→acc_voucher_items | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.4 Budget & Cost Center Tables

**`acc_cost_centers`**

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `department` | VARCHAR(100) NULL | |
| `responsible_person_id` | BIGINT UNSIGNED NULL FK→sys_users | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP NULL | |

**`acc_budgets`**

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `financial_year_id` | BIGINT UNSIGNED NOT NULL FK→acc_financial_years | |
| `cost_center_id` | BIGINT UNSIGNED NOT NULL FK→acc_cost_centers | |
| `ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | |
| `name` | VARCHAR(150) NOT NULL | Budget plan name |
| `total_amount` | DECIMAL(15,2) NOT NULL | |
| `allocated_amount` | DECIMAL(15,2) NOT NULL | |
| `status` | ENUM('draft','submitted','approved','active') NOT NULL DEFAULT 'draft' | |
| `approved_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `notes` | TEXT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` / `updated_at` / `deleted_at` | TIMESTAMP NULL | |

**UNIQUE KEY:** `(financial_year_id, cost_center_id, ledger_id, status='active')`  — enforced via generated column

---

### 5.5 Proposed Additional Tables (📐)

**`acc_gst_details`** — GST transaction registry

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `voucher_id` | BIGINT UNSIGNED NOT NULL FK→acc_vouchers | |
| `gstin` | VARCHAR(15) NULL | Payer/Payee GSTIN |
| `hsn_sac_code` | VARCHAR(10) NULL | |
| `taxable_amount` | DECIMAL(15,2) NOT NULL | |
| `cgst_rate` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `sgst_rate` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `igst_rate` | DECIMAL(5,2) NOT NULL DEFAULT 0 | |
| `cgst_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `sgst_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `igst_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `is_interstate` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `irn` | VARCHAR(64) NULL | E-invoice IRN |
| `irn_status` | ENUM('pending','generated','cancelled') NULL | |
| `created_at` / `updated_at` | TIMESTAMP NULL | |

**`acc_tds_entries`** — TDS deduction records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `voucher_id` | BIGINT UNSIGNED NOT NULL FK→acc_vouchers | |
| `deductee_type` | ENUM('vendor','employee') NOT NULL | |
| `deductee_id` | BIGINT UNSIGNED NOT NULL | Polymorphic |
| `tds_section` | VARCHAR(10) NOT NULL | 194C, 194J, etc. |
| `gross_amount` | DECIMAL(15,2) NOT NULL | |
| `tds_rate` | DECIMAL(5,2) NOT NULL | |
| `tds_amount` | DECIMAL(15,2) NOT NULL | |
| `pan` | VARCHAR(10) NULL | |
| `quarter` | TINYINT UNSIGNED NOT NULL | 1-4 |
| `financial_year_id` | BIGINT UNSIGNED NOT NULL FK→acc_financial_years | |
| `remittance_date` | DATE NULL | Date TDS paid to govt |
| `challan_number` | VARCHAR(50) NULL | |
| `created_at` / `updated_at` | TIMESTAMP NULL | |

**`acc_year_end_closings`** — Year-end close audit trail

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `financial_year_id` | BIGINT UNSIGNED NOT NULL FK→acc_financial_years | |
| `closed_by` | BIGINT UNSIGNED NOT NULL FK→sys_users | |
| `closed_at` | TIMESTAMP NOT NULL | |
| `pl_voucher_id` | BIGINT UNSIGNED NULL FK→acc_vouchers | P&L transfer JNL |
| `ob_voucher_id` | BIGINT UNSIGNED NULL FK→acc_vouchers | Opening balance JNL |
| `notes` | TEXT NULL | |
| `created_at` / `updated_at` | TIMESTAMP NULL | |

---

## Section 6 — API & Route Inventory

### 6.1 Existing Routes (🟡 from web.php)

| Group | Route Name | Method | Controller Action |
|---|---|---|---|
| Dashboard | `accounting.dashboard` | GET | AccDashboardController@index |
| Financial Year | `accounting.financial-year.*` | CRUD | FinancialYearController |
| Financial Year | `accounting.financial-year.lock` | POST | FinancialYearController@lock |
| Financial Year | `accounting.financial-year.unlock` | POST | FinancialYearController@unlock |
| Account Groups | `accounting.account-group.*` | CRUD + trash/restore | AccountGroupController |
| Ledgers | `accounting.ledger.*` | CRUD + trash/restore | LedgerController |
| Ledgers | `accounting.ledger.statement` | GET | LedgerController@statement |
| Voucher Types | `accounting.voucher-type.*` | CRUD | VoucherTypeController |
| Vouchers | `accounting.voucher.*` | CRUD | VoucherController |
| Vouchers | `accounting.voucher.post` | POST | VoucherController@post |
| Vouchers | `accounting.voucher.approve` | POST | VoucherController@approve |
| Vouchers | `accounting.voucher.cancel` | POST | VoucherController@cancel |
| Vouchers | `accounting.voucher.print` | GET | VoucherController@print |
| Vouchers | `accounting.voucher.duplicate` | GET | VoucherController@duplicate |
| Cost Centers | `accounting.cost-center.*` | CRUD | CostCenterController |
| Budgets | `accounting.budget.*` | CRUD | BudgetController |
| Tax Rates | `accounting.tax-rate.*` | CRUD | TaxRateController |
| Ledger Mappings | `accounting.ledger-mapping.*` | CRUD | LedgerMappingController |
| Recurring Templates | `accounting.recurring-template.*` | CRUD | RecurringTemplateController |
| Recurring Templates | `accounting.recurring-template.postNow` | POST | RecurringTemplateController@postNow |
| Bank Reconciliation | `accounting.bank-reconciliation.*` | CRUD | BankReconciliationController |
| Bank Reconciliation | `accounting.bank-reconciliation.import` | POST | BankReconciliationController@importStatement |
| Bank Reconciliation | `accounting.bank-reconciliation.autoMatch` | POST | BankReconciliationController@autoMatch |
| Bank Reconciliation | `accounting.bank-reconciliation.complete` | POST | BankReconciliationController@complete |
| Bank Reconciliation | `accounting.bank-reconciliation.matchEntry` | POST | BankReconciliationController@matchEntry |
| Asset Categories | `accounting.asset-category.*` | CRUD | AssetCategoryController |
| Fixed Assets | `accounting.fixed-asset.*` | CRUD | FixedAssetController |
| Fixed Assets | `accounting.fixed-asset.runDepreciation` | POST | FixedAssetController@runDepreciation |
| Expense Claims | `accounting.expense-claim.*` | CRUD | ExpenseClaimController |
| Expense Claims | `accounting.expense-claim.submit/approve/reject` | POST | ExpenseClaimController |
| Tally Export | `accounting.tally-export.*` | GET/POST | TallyExportController |
| Tally Mappings | `accounting.tally-mapping.*` | CRUD | TallyLedgerMappingController |
| Reports | `accounting.report.trial-balance` | GET | AccReportController@trialBalance |
| Reports | `accounting.report.profit-and-loss` | GET | AccReportController@profitAndLoss |
| Reports | `accounting.report.balance-sheet` | GET | AccReportController@balanceSheet |
| Reports | `accounting.report.day-book` | GET | AccReportController@dayBook |
| Reports | `accounting.report.cash-book` | GET | AccReportController@cashBook |
| Reports | `accounting.report.bank-book` | GET | AccReportController@bankBook |
| Reports | `accounting.report.ledger-report` | GET | AccReportController@ledgerReport |
| Reports | `accounting.report.outstanding-receivables` | GET | AccReportController@outstandingReceivables |
| Reports | `accounting.report.outstanding-payables` | GET | AccReportController@outstandingPayables |
| Reports | `accounting.report.budget-variance` | GET | AccReportController@budgetVariance |
| Reports | `accounting.report.gst-summary` | GET | AccReportController@gstSummary |
| AJAX | `accounting.ajax.ledgers-by-group` | GET | LedgerController@byGroup |
| AJAX | `accounting.ajax.ledger-search` | GET | LedgerController@search |
| AJAX | `accounting.ajax.ledger-balance` | GET | LedgerController@balance |

### 6.2 Proposed Additional Routes (📐)

| Route Name | Method | Purpose |
|---|---|---|
| `accounting.gst.config` | GET/POST | GST configuration setup |
| `accounting.gst.gstr1` | GET | GSTR-1 report |
| `accounting.gst.gstr3b` | GET | GSTR-3B report |
| `accounting.tds.entries` | GET | TDS entry list |
| `accounting.tds.form26q` | GET | Form 26Q compilation |
| `accounting.year-end.close` | POST | Year-end close action |
| `accounting.year-end.index` | GET | Year-end close status |
| `accounting.voucher.balance-check` | GET | AJAX Dr=Cr check |

---

## Section 7 — Services Architecture (📐 Proposed)

| Service | Responsibility |
|---|---|
| `VoucherService` | Create/post/cancel/reverse vouchers; enforce Dr=Cr; auto-number |
| `LedgerService` | Balance computation, ledger statement, opening balance |
| `BankReconciliationService` | CSV import, auto-match algorithm, completion validation |
| `DepreciationService` | SLM/WDV calculation, idempotent depreciation run, net block |
| `GstService` | GST calculation, GSTR-1/3B compilation, IRP API call for IRN |
| `TallyExportService` | XML generation, ledger mapping, export log |

### 7.1 VoucherService — Core Interface

```php
// Key public methods (proposed)
VoucherService::createVoucher(VoucherDTO $dto): Voucher
VoucherService::postVoucher(int $voucherId, int $approvedBy): bool
VoucherService::cancelVoucher(int $voucherId, string $reason): bool
VoucherService::reverseVoucher(int $voucherId, string $narration): Voucher
VoucherService::createFromEvent(string $sourceModule, string $sourceType, int $sourceId, VoucherDTO $dto): Voucher
```

### 7.2 Cross-Module Event Listeners (📐 Proposed)

| Event Class | Listener | Action |
|---|---|---|
| `FeePaid` (from FIN module) | `CreateReceiptVoucherListener` | Auto-create RCT voucher |
| `SalaryProcessed` (from HR module) | `CreatePayrollVoucherListener` | Auto-create JNL voucher |
| `PurchaseOrderPaid` (from INV module) | `CreatePurchaseVoucherListener` | Auto-create PUR voucher |
| `TransportFeePaid` (from TPT module) | `CreateTransportReceiptListener` | Auto-create RCT voucher |

### 7.3 Jobs (📐 Proposed)

| Job | Schedule | Action |
|---|---|---|
| `ProcessRecurringVouchersJob` | Daily at 00:01 | Post recurring templates where next_run_date = today |
| `RunMonthlyDepreciationJob` | 1st of month, 01:00 | Run depreciation for all active assets |
| `CheckBudgetBreachJob` | Daily at 08:00 | Check actuals vs budget; fire over-budget notifications |

---

## Section 8 — Models Summary

### 8.1 Existing Models (🟡)

| Model | Table | Key Relationships |
|---|---|---|
| `AccountGroup` | `acc_account_groups` | `parent()` self-ref BelongsTo, `children()` HasMany, `ledgers()` HasMany |
| `Ledger` | `acc_ledgers` | `accountGroup()` BelongsTo, `voucherItems()` HasMany, `mapping()` HasOne |
| `VoucherType` | `acc_voucher_types` | `vouchers()` HasMany, `recurringTemplates()` HasMany |
| `Voucher` | `acc_vouchers` | `voucherType()` BelongsTo, `items()` HasMany, `financialYear()` BelongsTo, `costCenter()` BelongsTo |
| `VoucherItem` | `acc_voucher_items` | `voucher()` BelongsTo, `ledger()` BelongsTo, `taxRate()` BelongsTo |
| `FinancialYear` | `acc_financial_years` | `vouchers()` HasMany, `budgets()` HasMany |
| `CostCenter` | `acc_cost_centers` | `budgets()` HasMany, `vouchers()` HasMany |
| `Budget` | `acc_budgets` | `financialYear()` BelongsTo, `costCenter()` BelongsTo, `ledger()` BelongsTo |
| `BankReconciliation` | `acc_bank_reconciliations` | `entries()` HasMany, `ledger()` BelongsTo |
| `BankStatementEntry` | `acc_bank_statement_entries` | `reconciliation()` BelongsTo, `matchedVoucherItem()` BelongsTo |
| `ExpenseClaim` | `acc_expense_claims` | `lines()` HasMany, `claimant()` BelongsTo |
| `ExpenseClaimLine` | `acc_expense_claim_lines` | `claim()` BelongsTo, `ledger()` BelongsTo |
| `FixedAsset` | `acc_fixed_assets` | `category()` BelongsTo, `depreciationEntries()` HasMany |
| `AssetCategory` | `acc_asset_categories` | `assets()` HasMany |
| `DepreciationEntry` | `acc_depreciation_entries` | `asset()` BelongsTo, `financialYear()` BelongsTo, `voucher()` BelongsTo |
| `LedgerMapping` | `acc_ledger_mappings` | `ledger()` BelongsTo |
| `RecurringTemplate` | `acc_recurring_templates` | `lines()` HasMany, `voucherType()` BelongsTo |
| `RecurringTemplateLine` | `acc_recurring_template_lines` | `template()` BelongsTo, `ledger()` BelongsTo |
| `TallyLedgerMapping` | `acc_tally_ledger_mappings` | `ledger()` BelongsTo |
| `TallyExportLog` | `acc_tally_export_logs` | — |
| `TaxRate` | `acc_tax_rates` | `voucherItems()` HasMany |

### 8.2 Proposed Additional Models (📐)

| Model | Table | Purpose |
|---|---|---|
| `GstDetail` | `acc_gst_details` | GST transaction registry |
| `TdsEntry` | `acc_tds_entries` | TDS deduction records |
| `YearEndClosing` | `acc_year_end_closings` | Year-end close audit |

---

## Section 9 — State Machines & Workflows

### 9.1 Voucher Lifecycle FSM

```
                  ┌─────────────────────────────────────────────┐
                  │               VOUCHER LIFECYCLE              │
                  └─────────────────────────────────────────────┘

  [New Entry]
       │
       ▼
  ┌─────────┐   post()     ┌──────────┐   [period lock]   ┌──────────┐
  │  DRAFT  │ ──────────►  │  POSTED  │ ─────────────────► │  LOCKED  │
  └─────────┘              └──────────┘                    └──────────┘
       │                       │    ▲                           │
       │ cancel()              │    │ reversal                  │ cannot
       │                       │    │ voucher                   │ edit/delete
       ▼                       ▼    │                           │
  ┌───────────┐            ┌──────────────┐                     ▼
  │ CANCELLED │            │  CANCELLED   │              [REVERSAL JNL only]
  └───────────┘            │  (posted→)   │
                           └──────────────┘
```

**State Transition Rules:**

| From | Action | To | Guard |
|---|---|---|---|
| DRAFT | `post()` | POSTED | Dr = Cr; financial year not locked; at least 2 items |
| DRAFT | `cancel()` | CANCELLED | No guard |
| POSTED | `cancel()` | CANCELLED | Financial year not locked; posts reversal voucher automatically |
| POSTED | period lock | LOCKED | Admin locks financial year |
| LOCKED | (any edit) | — | BLOCKED — 422 error |
| LOCKED | `reverse()` | Creates new DRAFT reversal | Finance Officer permission required |

**Key business rules by state:**
- DRAFT: fully editable; excluded from balance/report calculations
- POSTED: included in all ledger balances and reports; editable only by reversal
- LOCKED: `acc_financial_years.is_locked = 1`; all vouchers in year become LOCKED automatically
- Cancelled vouchers: `is_cancelled = 1`; excluded from all balance calculations; reversal not needed
- Cross-module auto-vouchers (from events): created as DRAFT, auto-posted by `VoucherService::createFromEvent()`

---

### 9.2 Bank Reconciliation Workflow

```
  [Finance Officer]
        │
        ▼
  ┌──────────────────────────┐
  │  1. Create Reconciliation │  — select bank ledger + statement date + closing balance
  └──────────────────────────┘
        │
        ▼
  ┌──────────────────────────┐
  │  2. Import Bank Statement │  — upload CSV (HDFC/SBI/ICICI/Axis/Kotak format)
  └──────────────────────────┘    BankReconciliationService parses → acc_bank_statement_entries
        │
        ▼
  ┌──────────────────────────┐
  │  3. Auto-Match           │  — match by amount + date(±3 days) + narration keyword
  └──────────────────────────┘    match_confidence scored 0-100
        │
        ├─── Matched (confidence ≥ 70%) → status = auto_matched
        │
        └─── Unmatched → present to user
                    │
                    ├─── Manual match to existing voucher item
                    │
                    └─── Create new voucher (bank charge/interest) → auto-matches
        │
        ▼
  ┌──────────────────────────┐
  │  4. Review & Confirm     │  — book_balance = bank_closing_balance?
  └──────────────────────────┘
        │
        ├─── difference = 0 → complete()  → status = 'completed'
        │
        └─── difference ≠ 0 → block complete (Finance Officer override = permission-gated)
```

**Reconciliation Status Table:**

| Status | Meaning |
|---|---|
| `open` | In progress; entries still unmatched |
| `completed` | Book balance = bank statement; no outstanding difference |

---

### 9.3 Expense Claim Workflow

```
  Staff Member         Finance Officer         Principal
       │                     │                     │
  [Submit Claim]             │                     │
       │                     │                     │
       ▼                     │                     │
  DRAFT ─── submit() ──► PENDING ─── approve() ──► APPROVED
                              │                     │
                              └── reject() ──► REJECTED   [reason mandatory]
                                                          │
                                               [Approved]─► Payment Voucher auto-created
```

---

### 9.4 Budget Approval Workflow

```
  Finance Officer          Principal
       │                       │
  [Create Budget Plan]         │
  status = 'draft'             │
       │                       │
       ▼                       │
  submit() → 'submitted' ───► approve() → 'active'
                                │
                                └── reject() → back to 'draft'

  [Once 'active']
  - Allocations are enforced
  - Over-budget alerts fire at 90% utilisation
  - Only one 'active' plan per fiscal_year + cost_center
```

---

## Section 10 — Validation Rules

### 10.1 Voucher Validation

| Field | Rule |
|---|---|
| `voucher_type_id` | Required; must reference active voucher type |
| `financial_year_id` | Required; financial year must not be locked |
| `date` | Required; must fall within financial year date range |
| `items` | Min 2 items; must contain at least 1 Dr and 1 Cr line |
| `items[].amount` | > 0 DECIMAL; max 15 digits, 2 decimal places |
| `items[].ledger_id` | Must reference active ledger |
| `SUM(Dr) = SUM(Cr)` | Enforced at service layer; 422 on failure |
| `narration` | Optional; max 1000 chars |
| `reference_number` | Optional; max 100 chars |

### 10.2 Ledger Validation

| Field | Rule |
|---|---|
| `code` | UNIQUE per tenant; alphanumeric + hyphen; max 20 chars |
| `name` | Required; max 150 chars |
| `account_group_id` | Required; must reference active group |
| `opening_balance` | Numeric; >= 0 |
| `balance_type` | Dr/Cr; default Dr for Assets/Expense groups |

### 10.3 Bank Reconciliation Validation

| Field | Rule |
|---|---|
| `ledger_id` | Must have `allow_reconciliation = 1` |
| `closing_balance` | Required; numeric |
| `statement_file` | Required for import; CSV or MT940; max 10MB |
| Reconciliation complete | `difference` must be 0.00 (or Finance Officer override) |

### 10.4 Fixed Asset Validation

| Field | Rule |
|---|---|
| `asset_code` | UNIQUE per tenant |
| `purchase_cost` | > 0 |
| `salvage_value` | >= 0; must be < purchase_cost |
| `depreciation_rate` | 0-100 percent; required for WDV method |
| `useful_life_years` | > 0 integer; required for SLM method |
| Depreciation re-run | Idempotent — existing entries for fiscal year replaced, not duplicated |

### 10.5 GSTIN Validation

| Rule | Pattern |
|---|---|
| Length | Exactly 15 characters |
| Format | `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$` |
| State code | First 2 digits must be valid Indian state code (01–38) |
| PAN embedded | Chars 3–12 must be valid PAN format |

### 10.6 Financial Year Validation

| Rule | Detail |
|---|---|
| Date range | start_date must be 1-Apr; end_date must be 31-Mar next year |
| No overlap | New financial year date range must not overlap with existing years |
| Lock pre-check | No DRAFT vouchers may exist in year before lock |
| Unlock | Requires `accounting.unlock-year` permission (superadmin only) |

---

## Section 11 — Cross-Module Integration

### 11.1 Overview

The Accounting module integrates with 4 source modules via Laravel events. Each integration follows the same pattern: source module fires an event → AccountingServiceProvider-registered listener calls `VoucherService::createFromEvent()`.

```
Source Module              Event                    Accounting Listener
─────────────────────────────────────────────────────────────────────────
StudentFee (FIN)      FeePaid                  CreateReceiptVoucherListener
HR/Payroll            SalaryProcessed          CreatePayrollVoucherListener
Inventory (INV)       PurchaseOrderPaid        CreatePurchaseVoucherListener
Transport (TPT)       TransportFeePaid         CreateTransportReceiptListener
```

All cross-module vouchers carry: `source_module`, `source_type`, `source_id` on `acc_vouchers` for traceability. Cross-module vouchers are created as POSTED (not DRAFT) since the source module has already validated the transaction.

---

### 11.2 Integration 1 — StudentFee → Receipt Voucher

**Trigger:** `Modules\Finance\Events\FeePaid` fired by StudentFee module on successful fee payment

**Event Payload:**
```
FeePaid {
    studentId: int,
    paymentId: int,
    amount: decimal,
    paymentMode: string,       // cash | online | cheque | upi
    bankAccountLedgerId: int,  // ledger for the bank/cash account
    feeLedgerId: int,          // income ledger for fee head
    financialYearId: int,
    narration: string          // e.g., "Fee: Term 1 2025-26, Rahul Sharma"
}
```

**Voucher Created:**
| Side | Ledger | Amount |
|---|---|---|
| Dr | Bank/Cash Ledger (`bankAccountLedgerId`) | fee amount |
| Cr | Fee Income Ledger (`feeLedgerId`) | fee amount |

- Voucher Type: Receipt (RCT)
- Status: POSTED
- `source_module = 'fin'`, `source_type = 'FeePayment'`, `source_id = paymentId`

**Failure Handling:** If voucher creation fails, event is retried up to 3 times; failure logged to `sys_activity_logs` with alert to Finance Officer. Source payment record is NOT rolled back (financial transaction already committed).

---

### 11.3 Integration 2 — Payroll → Journal Voucher

**Trigger:** `Modules\HR\Events\SalaryProcessed` fired after salary batch approval

**Event Payload:**
```
SalaryProcessed {
    payrollRunId: int,
    month: int,
    year: int,
    grossSalary: decimal,
    tdsAmount: decimal,
    pfAmount: decimal,
    netPayable: decimal,
    salaryExpenseLedgerId: int,
    salaryPayableLedgerId: int,
    tdsPayableLedgerId: int,
    pfPayableLedgerId: int,
    financialYearId: int
}
```

**Voucher Created (Journal — JNL):**
| Side | Ledger | Amount |
|---|---|---|
| Dr | Salary Expense Ledger | gross salary |
| Cr | TDS Payable Ledger | TDS amount |
| Cr | PF Payable Ledger | PF amount |
| Cr | Salary Payable Ledger | net payable |

- `source_module = 'hr'`, `source_type = 'PayrollRun'`, `source_id = payrollRunId`
- TDS amount also creates record in `acc_tds_entries` for Form 26Q

---

### 11.4 Integration 3 — Inventory → Purchase Voucher

**Trigger:** `Modules\Inventory\Events\PurchaseOrderPaid` fired when vendor payment is approved

**Event Payload:**
```
PurchaseOrderPaid {
    purchaseOrderId: int,
    vendorId: int,
    expenseLedgerId: int,        // cost/expense ledger
    vendorPayableLedgerId: int,
    bankLedgerId: int,
    invoiceAmount: decimal,
    paidAmount: decimal,
    gstAmount: decimal,          // if applicable
    financialYearId: int
}
```

**Two Vouchers Created:**
1. Purchase (PUR): Dr Expense/Asset Ledger + Dr GST Input Ledger → Cr Vendor Payable
2. Payment (PMT): Dr Vendor Payable → Cr Bank Ledger

- `source_module = 'inv'`, `source_type = 'PurchaseOrder'`, `source_id = purchaseOrderId`
- If GST applicable: `acc_gst_details` record created for ITC tracking

---

### 11.5 Integration 4 — Transport → Receipt Voucher

**Trigger:** `Modules\Transport\Events\TransportFeePaid` fired on transport fee collection

**Event Payload:**
```
TransportFeePaid {
    transportPaymentId: int,
    studentId: int,
    amount: decimal,
    bankLedgerId: int,
    transportIncomeLedgerId: int,
    financialYearId: int,
    narration: string
}
```

**Voucher Created:**
| Side | Ledger | Amount |
|---|---|---|
| Dr | Bank/Cash Ledger | transport fee amount |
| Cr | Transport Income Ledger | transport fee amount |

- Voucher Type: Receipt (RCT)
- `source_module = 'tpt'`, `source_type = 'TransportPayment'`, `source_id = transportPaymentId`

---

### 11.6 Ledger Mapping Configuration

For cross-module integrations to work, the school accountant must configure ledger mappings in `acc_ledger_mappings`:

| `module_code` | `mapping_key` | `ledger_id` | Purpose |
|---|---|---|---|
| `fin` | `fee_income` | → acc_ledgers | Default fee income ledger |
| `fin` | `bank_default` | → acc_ledgers | Default bank/cash receipt ledger |
| `hr` | `salary_expense` | → acc_ledgers | Salary expense ledger |
| `hr` | `salary_payable` | → acc_ledgers | Salary payable liability ledger |
| `hr` | `tds_payable` | → acc_ledgers | TDS payable liability ledger |
| `inv` | `purchase_expense` | → acc_ledgers | Purchase/expense ledger |
| `inv` | `vendor_payable` | → acc_ledgers | Accounts payable ledger |
| `tpt` | `transport_income` | → acc_ledgers | Transport income ledger |

If a required mapping is absent, the event listener logs a warning and skips voucher creation (does not throw — source module must not fail due to accounting misconfiguration).

---

## Section 12 — Permissions & Role Matrix

### 12.1 Permission Groups

| Permission Code | Description |
|---|---|
| `acc.dashboard.view` | View finance dashboard |
| `acc.voucher.create` | Create vouchers |
| `acc.voucher.post` | Post/approve vouchers |
| `acc.voucher.cancel` | Cancel posted vouchers |
| `acc.voucher.reverse` | Reverse locked-period vouchers |
| `acc.ledger.manage` | Create/edit ledgers and account groups |
| `acc.financial-year.lock` | Lock/unlock financial years |
| `acc.bank.reconcile` | Perform bank reconciliation |
| `acc.budget.create` | Create budget plans |
| `acc.budget.approve` | Approve budget plans |
| `acc.expense-claim.approve` | Approve expense claims |
| `acc.fixed-asset.manage` | Manage fixed assets |
| `acc.depreciation.run` | Run depreciation engine |
| `acc.tally.export` | Export Tally XML |
| `acc.gst.manage` | GST configuration and reports |
| `acc.tds.manage` | TDS entries and Form 26Q |
| `acc.report.view` | View all financial reports |
| `acc.year-end.close` | Execute year-end closing |
| `acc.year-end.unlock` | Unlock closed year (superadmin) |

### 12.2 Role-Permission Matrix

| Permission | Finance Officer | Accountant | Principal | Dept Head | Staff | Auditor |
|---|---|---|---|---|---|---|
| `acc.dashboard.view` | Y | Y | Y | Y (own CC) | — | Y |
| `acc.voucher.create` | Y | Y | — | — | — | — |
| `acc.voucher.post` | Y | Y | — | — | — | — |
| `acc.voucher.cancel` | Y | Y | — | — | — | — |
| `acc.voucher.reverse` | Y | — | — | — | — | — |
| `acc.ledger.manage` | — | Y | — | — | — | — |
| `acc.financial-year.lock` | — | Y | — | — | — | — |
| `acc.bank.reconcile` | Y | Y | — | — | — | — |
| `acc.budget.create` | Y | Y | — | — | — | — |
| `acc.budget.approve` | — | — | Y | — | — | — |
| `acc.expense-claim.approve` | Y | — | Y (high-value) | — | — | — |
| `acc.fixed-asset.manage` | Y | Y | — | — | — | — |
| `acc.depreciation.run` | — | Y | — | — | — | — |
| `acc.tally.export` | — | Y | — | — | — | — |
| `acc.gst.manage` | — | Y | — | — | — | — |
| `acc.tds.manage` | — | Y | — | — | — | — |
| `acc.report.view` | Y | Y | Y | Y (own CC) | — | Y |
| `acc.year-end.close` | — | Y | — | — | — | — |
| `acc.year-end.unlock` | — | — | — | — | — | — |

Note: `acc.year-end.unlock` reserved for tenant superadmin only.

---

## Section 13 — UI/UX Screens

### 13.1 Screen Inventory

| Screen ID | Screen Name | Route | Status |
|---|---|---|---|
| ACC-SCR-01 | Finance Dashboard | `accounting.dashboard` | 🟡 Route exists |
| ACC-SCR-02 | Chart of Accounts (Tree View) | `accounting.account-group.index` | 🟡 Route exists |
| ACC-SCR-03 | Ledger Master List + Form | `accounting.ledger.*` | 🟡 Route exists |
| ACC-SCR-04 | Ledger Statement | `accounting.ledger.statement` | 🟡 Route exists |
| ACC-SCR-05 | Financial Year Management | `accounting.financial-year.*` | 🟡 Route exists |
| ACC-SCR-06 | Voucher List (filter by type/date) | `accounting.voucher.index` | 🟡 Route exists |
| ACC-SCR-07 | Voucher Create/Edit Form | `accounting.voucher.create` | 🟡 Route exists |
| ACC-SCR-08 | Voucher Print (PDF) | `accounting.voucher.print` | 🟡 Route exists |
| ACC-SCR-09 | Cost Center Management | `accounting.cost-center.*` | 🟡 Route exists |
| ACC-SCR-10 | Budget Plan Management | `accounting.budget.*` | 🟡 Route exists |
| ACC-SCR-11 | Bank Reconciliation List | `accounting.bank-reconciliation.*` | 🟡 Route exists |
| ACC-SCR-12 | Reconciliation Matching Screen | (within reconciliation show) | 📐 Proposed |
| ACC-SCR-13 | Fixed Asset Register | `accounting.fixed-asset.*` | 🟡 Route exists |
| ACC-SCR-14 | Asset Category Management | `accounting.asset-category.*` | 🟡 Route exists |
| ACC-SCR-15 | Expense Claim List + Form | `accounting.expense-claim.*` | 🟡 Route exists |
| ACC-SCR-16 | Recurring Template Management | `accounting.recurring-template.*` | 🟡 Route exists |
| ACC-SCR-17 | Tally Export Screen | `accounting.tally-export.*` | 🟡 Route exists |
| ACC-SCR-18 | Tally Ledger Mapping | `accounting.tally-mapping.*` | 🟡 Route exists |
| ACC-SCR-19 | Trial Balance Report | `accounting.report.trial-balance` | 🟡 Route exists |
| ACC-SCR-20 | P&L Report | `accounting.report.profit-and-loss` | 🟡 Route exists |
| ACC-SCR-21 | Balance Sheet Report | `accounting.report.balance-sheet` | 🟡 Route exists |
| ACC-SCR-22 | Day Book / Cash Book / Bank Book | `accounting.report.*` | 🟡 Route exists |
| ACC-SCR-23 | Budget Variance Report | `accounting.report.budget-variance` | 🟡 Route exists |
| ACC-SCR-24 | GST Summary Report | `accounting.report.gst-summary` | 🟡 Route exists |
| ACC-SCR-25 | GST Configuration | `accounting.gst.config` | 📐 Proposed |
| ACC-SCR-26 | GSTR-1 Report | `accounting.gst.gstr1` | 📐 Proposed |
| ACC-SCR-27 | GSTR-3B Report | `accounting.gst.gstr3b` | 📐 Proposed |
| ACC-SCR-28 | TDS Entry Management | `accounting.tds.entries` | 📐 Proposed |
| ACC-SCR-29 | Year-End Closing Wizard | `accounting.year-end.*` | 📐 Proposed |

### 13.2 Key UI Requirements

**Voucher Entry Screen (ACC-SCR-07):**
- Dynamic Dr/Cr table: add/remove rows; running Dr total + Cr total shown; red highlight when totals don't match
- AJAX ledger search typeahead (min 2 chars; route `accounting.ajax.ledger-search`)
- Dr=Cr live check: "Save" button disabled when totals mismatch
- Cost center dropdown (optional per line or header-level)
- File attachment upload (max 5 files, 5MB each)
- Voucher type selector filters available ledger groups (e.g., Contra type: only bank/cash ledgers)

**Bank Reconciliation Matching Screen (ACC-SCR-12):**
- Split view: left = bank statement lines; right = unmatched voucher items
- Drag-and-drop or checkbox match
- Confidence score badge: green ≥85%; amber 70-84%
- "Create Voucher" button for unmatched bank lines (opens voucher mini-form in modal)
- Running difference counter (must reach ₹0.00 to enable "Complete" button)

**Finance Dashboard (ACC-SCR-01):**
- KPI cards: Net Surplus/Deficit, Total Income, Total Expense, Bank Balance(s)
- Revenue vs Expense bar chart (monthly, current fiscal year)
- Budget utilization horizontal bar charts per cost center
- Pending approvals widget: vouchers + expense claims count
- Over-budget alerts as dismissible red banners
- 30-minute cache; Cache-Control header for browser

---

## Section 14 — Testing Requirements

### 14.1 Unit Tests (📐 Proposed)

| Test Class | What to Test |
|---|---|
| `VoucherServiceTest` | Dr=Cr enforcement (pass/fail), auto-numbering, reversal creation |
| `LedgerBalanceTest` | Opening balance + voucher items = correct running balance |
| `DepreciationServiceTest` | SLM calculation (full year, partial year), WDV calculation, idempotency |
| `BankReconciliationServiceTest` | Auto-match algorithm: exact match, ±3 day tolerance, no false match |
| `GstServiceTest` | CGST+SGST split vs IGST selection, GSTIN format validation |
| `TallyExportServiceTest` | XML structure, ledger mapping, voucher type mapping |
| `BudgetVarianceTest` | Actual + committed + available calculation correctness |

### 14.2 Feature Tests (📐 Proposed)

| Scenario | Expected Result |
|---|---|
| POST voucher with Dr ≠ Cr | 422 response; voucher not saved |
| POST voucher on locked financial year | 403 response; voucher not saved |
| Cancel posted voucher | Reversal voucher auto-created; original `is_cancelled=1` |
| Import CSV bank statement | Entries parsed; auto-match runs; unmatched entries identified |
| Complete reconciliation with difference ≠ 0 | 422 response unless Finance Officer override permission |
| Run depreciation for same fiscal year twice | Second run replaces first; no duplicate entries |
| Close financial year with Draft vouchers | 422 response; list of Draft vouchers returned |
| Cross-module FeePaid event | Receipt voucher created; Dr/Cr correct; source_id set |
| Budget over-budget at 90% | Notification fired; alert visible on dashboard |

### 14.3 Acceptance Criteria Summary

| Code | Criterion |
|---|---|
| AC-FAC-01 | Every posted voucher: SUM(Dr items) = SUM(Cr items) — verified by DB trigger or service assertion |
| AC-FAC-02 | Locked year vouchers: edit/delete/cancel returns 403; reversal is the only allowed action |
| AC-FAC-03 | Trial Balance: total Dr = total Cr (data integrity alert if not) |
| AC-FAC-04 | Balance Sheet: Assets = Liabilities + Equity (validated before render) |
| AC-FAC-05 | Depreciation engine is idempotent: re-run same year replaces entries, does not duplicate |
| AC-FAC-06 | Bank reconciliation completion blocked unless difference = ₹0.00 |
| AC-FAC-07 | Cross-module voucher failure does not roll back source transaction; logged to activity log |
| AC-FAC-08 | GSTIN stored with 15-char validation; invalid GSTIN rejected at form level |
| AC-FAC-09 | Tally XML download produces valid TallyPrime 3.x-importable XML |
| AC-FAC-10 | Year-end close: P&L carry-forward JNL created; all BS ledger OBs seeded for new year |

---

## Section 15 — Implementation Gaps & Priorities

### 15.1 What Exists (🟡)

| Component | Assessment |
|---|---|
| 18 controllers | Present as files; likely stub-level (no view output confirmed) |
| 21 models | Present with correct table names and fillable arrays (Voucher model verified) |
| Route file | Complete — all major routes defined including AJAX endpoints |
| VoucherType model | Confirmed: `acc_voucher_types`, category/prefix/auto_numbering fields present |
| Voucher model | Confirmed: `acc_vouchers`, status enum, source_module/source_type/source_id tracing |

### 15.2 What Is Missing (📐) — Priority Order

| Priority | Gap | Effort |
|---|---|---|
| P1 | DB Migrations — no migration files found; all tables need creation | High |
| P1 | VoucherService — Dr=Cr enforcement, auto-numbering, posting logic | High |
| P1 | Controller business logic — all 18 controllers are stubs | High |
| P1 | Blade views — no views confirmed; all 29 screens need building | High |
| P2 | BankReconciliationService — CSV parser, auto-match algorithm | Medium |
| P2 | DepreciationService — SLM/WDV engine, idempotent run | Medium |
| P2 | FormRequest classes — input validation for all 12+ forms | Medium |
| P2 | LedgerService — balance computation, statement generation | Medium |
| P2 | Cross-module event listeners — 4 integrations (FIN/HR/INV/TPT) | Medium |
| P3 | GstService — GST calculation, GSTR compilation, IRP API | Medium |
| P3 | TallyExportService — XML generation (routes exist but service missing) | Medium |
| P3 | TDS management — acc_tds_entries table + Form 26Q | Low |
| P3 | Year-end closing wizard — period lock + carry-forward JNL | Medium |
| P3 | Jobs — recurring voucher, depreciation, budget breach monitoring | Low |

### 15.3 Development Sequence Recommendation

```
Sprint 1: Migrations + COA (FAC1) + Financial Year (FAC10-01/02)
Sprint 2: VoucherService + Voucher CRUD + Dr=Cr engine (FAC2)
Sprint 3: Bank accounts + Reconciliation service (FAC3)
Sprint 4: Reports — Trial Balance, P&L, Balance Sheet (FAC4)
Sprint 5: Budget management + cost centers (FAC5)
Sprint 6: Cross-module event integrations x4 (Section 11)
Sprint 7: Fixed Assets + Depreciation engine (FAC9)
Sprint 8: Tally export service (FAC6) + GST compliance (FAC7)
Sprint 9: TDS management (FAC8) + Year-end closing (FAC10)
Sprint 10: Testing, hardening, PDF reports
```

---

## Section 16 — Appendix

### 16.1 Indian Accounting Standard References

| Standard | Relevance |
|---|---|
| AS-6 (ICAI) | Depreciation accounting — SLM/WDV definitions |
| Income Tax Act Schedule XIV | WDV depreciation rates for asset classes |
| CGST Act 2017 | GST applicability for educational services |
| GST Notification 12/2017 | Educational service exemptions |
| TDS Sections 192/194C/194J/194I | Staff salary TDS + vendor TDS |
| Companies Act 2013 Schedule II | Useful life of assets for SLM depreciation |

### 16.2 Tally XML Export Structure

```xml
<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>All Masters</REPORTNAME>
        <STATICVARIABLES>
          <SVCURRENTCOMPANY>{{school_name}}</SVCURRENTCOMPANY>
        </STATICVARIABLES>
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <!-- Ledger master entries -->
          <LEDGER NAME="{{ledger_name}}" ACTION="Create">
            <PARENT>{{tally_group_name}}</PARENT>
            <OPENINGBALANCE>{{opening_balance}}</OPENINGBALANCE>
          </LEDGER>
        </TALLYMESSAGE>
        <TALLYMESSAGE>
          <!-- Voucher entries -->
          <VOUCHER VCHTYPE="{{tally_voucher_type}}" ACTION="Create">
            <DATE>{{yyyymmdd}}</DATE>
            <NARRATION>{{narration}}</NARRATION>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>{{dr_ledger}}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-{{amount}}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>{{cr_ledger}}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>
              <AMOUNT>{{amount}}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
          </VOUCHER>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>
```

### 16.3 Voucher Type → Tally Mapping

| Prime Voucher Type | Tally Voucher Type | Notes |
|---|---|---|
| Receipt (RCT) | Receipt | |
| Payment (PMT) | Payment | |
| Contra (CTR) | Contra | |
| Journal (JNL) | Journal | |
| Sales (SLS) | Sales | |
| Purchase (PUR) | Purchase | |
| Credit Note (CRN) | Credit Note | |
| Debit Note (DBN) | Debit Note | |

### 16.4 Default Seeded Data

The following data should be seeded on module installation:

**Account Groups (root level — cannot delete):**
- Assets (Dr nature)
  - Fixed Assets
  - Current Assets → Bank Accounts / Cash in Hand / Receivables
- Liabilities (Cr nature)
  - Long-Term Liabilities
  - Current Liabilities → Payables / TDS Payable / GST Payable
- Income (Cr nature)
  - Fee Income
  - Other Income
- Expense (Dr nature)
  - Staff Expenses
  - Administrative Expenses
  - Depreciation

**Voucher Types (system — cannot delete):**
- Receipt (RCT), Payment (PMT), Contra (CTR), Journal (JNL)
- Sales (SLS), Purchase (PUR), Credit Note (CRN), Debit Note (DBN)

**Financial Year:**
- Auto-create current fiscal year on first login (e.g., 2025-26: 01-Apr-2025 to 31-Mar-2026)

### 16.5 V1 → V2 Key Changes

| Aspect | V1 (Greenfield design) | V2 (Actual implementation) |
|---|---|---|
| Table prefix | `fac_*` (proposed) | `acc_*` (implemented) |
| Module path | `Modules/FinanceAccounting` | `Modules/Accounting/` |
| Architecture | FAC façade over acc_* | Unified acc_* module |
| Status | 0% — Greenfield | ~30% — routes/models/stubs exist |
| Journal entries | `acc_journal_entries` + `acc_journal_entry_lines` | `acc_vouchers` + `acc_voucher_items` (Tally-style) |
| Voucher engine | VoucherServiceInterface (proposed) | VoucherService (to build) |
| External integrations | QuickBooks/Zoho | Tally XML export (implemented in routes) |

---

*Document end. Total sections: 16. Generated: 2026-03-26.*
