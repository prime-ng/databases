# FAC — Finance & Accounting Module
## Requirement Document v1.0

**Module Code:** FAC
**Module Type:** Tenant Module (per-school)
**Table Prefix:** `fac_*`
**Proposed Module Path:** `Modules/FinanceAccounting`
**RBS Reference:** Module K — Finance & Accounting (sub-tasks K1–K13, 70 sub-tasks, lines 2844–3015)
**Development Status:** ❌ Not Started — Greenfield
**Document Date:** 2026-03-25
**Processing Mode:** RBS-ONLY

---

## 1. Executive Summary

### 1.1 Purpose

The Finance & Accounting (FAC) module is the school-level financial management layer of Prime-AI. It operates on top of the double-entry Accounting engine (`acc_*`) and provides school-specific financial workflows: budget preparation and cost-center management, non-fee income tracking (grants, donations, rental income), staff expense claims, petty cash management, bank account management and reconciliation, fixed asset register with depreciation, GST compliance (GSTIN configuration, GSTR-1/GSTR-3B, e-invoicing), financial reporting (Trial Balance, P&L, Balance Sheet), and accounting software integrations (Tally XML export, QuickBooks/Zoho sync).

**Architectural positioning:** The `acc_*` tables (`acc_account_groups`, `acc_ledgers`, `acc_journal_entries`, `acc_journal_entry_lines`, etc.) form the double-entry core. FAC creates high-level financial objects (budgets, bank accounts, petty cash books, fixed assets) and delegates all double-entry posting to the Accounting module via a `VoucherServiceInterface`. Student fees flow through the existing StudentFee module (`fin_*` / `acc_*` fee tables). Vendor invoices and payments flow through the Vendor module (`vnd_*`). FAC owns the **school's non-fee financial operations**.

### 1.2 Scope Summary

This module covers:
- Chart of Accounts management (account groups, ledgers, ledger mappings) — FAC layer over `acc_account_groups` and `acc_ledgers`
- Opening balance setup for ledgers, student receivables, and vendor payables
- Journal entry management (manual, bulk, recurring) with approval workflow
- Accounts Receivable: non-fee income tracking, AR aging, collections follow-up
- Accounts Payable: vendor bill entry, payment processing (distinct from Vendor module operational procurement)
- Bank account management with multi-bank support
- Bank reconciliation: CSV/MT940 import, auto-match, manual reconciliation
- Petty cash (imprest system): book management, receipts/payments, reimbursement
- Budget management: annual budget creation, department/cost-center allocation, budget tracking
- GST configuration: GSTIN, HSN/SAC codes, tax rules, e-invoicing with IRN/QR
- GSTR-1 and GSTR-3B report preparation
- Fixed asset register: asset tracking, depreciation (SLM/WDV), depreciation journal entries
- Financial reports: Trial Balance, Profit & Loss, Balance Sheet, Cash Flow, Ledger statements
- Finance dashboard: revenue vs expense, cash flow trends, budget vs actuals
- Tally XML export for journal vouchers and ledgers
- QuickBooks/Zoho Books API sync

### 1.3 Module Statistics (Projected)

| Metric | Projected Count |
|---|---|
| RBS Features (F.K*.*) | 26 |
| RBS Tasks | 35 |
| RBS Sub-tasks | 70 |
| DB Tables (`fac_*`) | 14 |
| acc_* Tables (owned by Accounting module, used via service) | 18 |
| Named Routes (estimated) | ~80 |
| Blade Views (estimated) | ~50 |
| Controllers (estimated) | 14 |
| Models (estimated) | 18 |
| Services (estimated) | 6 |
| Jobs (estimated) | 2 |
| FormRequests (estimated) | 14 |

### 1.4 Implementation Status

| Layer | Status |
|---|---|
| DB Schema / Migrations | ❌ Not Started |
| Models | ❌ Not Started |
| Controllers | ❌ Not Started |
| Services | ❌ Not Started |
| FormRequests | ❌ Not Started |
| Blade Views | ❌ Not Started |
| Routes | ❌ Not Started |
| Jobs | ❌ Not Started |
| Tests | ❌ Not Started |

**Overall Implementation: 0% — Greenfield**

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools operate as complex financial entities: they collect fees, pay staff, procure supplies, maintain buildings, manage grants and donations, and must comply with GST regulations and educational trust audit requirements. A principal-level finance person (Bursar, Accountant, or Finance Officer) typically manages these operations using a paper ledger or a basic spreadsheet.

Prime-AI FAC formalizes this entire operation:
- Multi-bank account tracking ensures every rupee is traceable to a bank transaction
- Budget management with cost-center granularity provides department-heads visibility into their spending limits
- Expense claims with approval workflows eliminate informal reimbursement requests
- GST compliance engine ensures schools registered under GST can generate compliant invoices and file returns
- Tally export ensures schools that use Tally for statutory reporting can sync data without double-entry

### 2.2 Key Features

1. Chart of accounts with hierarchical account groups (Assets/Liabilities/Income/Expense)
2. Multi-bank account management with balance tracking
3. Bank reconciliation: import bank statements, auto-match, manual reconciliation
4. Petty cash imprest system with reimbursement workflow
5. Annual budget creation with department/cost-center allocation
6. Budget tracking: commitments (POs) + actuals vs budget with variance alerts
7. Non-fee income tracking (donations, grants, rental income, events income)
8. Staff expense claim submission and approval
9. Vendor bill entry and payment processing (integration layer with Vendor module)
10. Journal entry with approval workflow and recurring templates
11. Fixed asset register with SLM/WDV depreciation engine
12. GST configuration: GSTIN, HSN/SAC codes, tax rates, CGST/SGST/IGST
13. E-invoicing: IRN generation and QR code attachment
14. GSTR-1 and GSTR-3B report generation
15. Standard financial reports: Trial Balance, P&L, Balance Sheet, Cash Flow
16. Finance dashboard with revenue/expense charts and KPI cards
17. Tally XML export for ledgers and journal vouchers
18. QuickBooks/Zoho Books API integration

### 2.3 Menu Path

`Finance > Accounting` or `Finance > [sub-menu items]`

### 2.4 Architecture

FAC is a **façade module** over the `acc_*` double-entry engine. It does not maintain its own journal entry records — instead it calls `VoucherServiceInterface` to post to `acc_journal_entries` + `acc_journal_entry_lines`. FAC's own tables (`fac_*`) represent school-finance business objects: bank accounts, petty cash books, budgets, fixed assets, GST configurations.

**Accounting module (`acc_*`) provides:**
- `acc_account_groups` — account group hierarchy
- `acc_ledgers` — individual ledger accounts
- `acc_journal_entries` + `acc_journal_entry_lines` — double-entry backbone
- `acc_recurring_journal_templates` — recurring JE templates
- `acc_fiscal_years` — fiscal year management
- `acc_cost_centers` — cost center master
- `acc_budgets` — budget line items per cost center / ledger
- `acc_expense_claims` + `acc_expense_claim_lines` — staff expense claims
- `acc_bank_reconciliations` + `acc_reconciliation_matches` — bank reconciliation
- `acc_fixed_assets` + `acc_asset_categories` + `acc_depreciation_entries` — asset register
- `acc_tax_rates` — tax rate master
- `acc_sales_invoices` + `acc_purchase_invoices` — invoice management
- `acc_tally_export_logs` — export audit

**FAC adds on top of this:**
- `fac_bank_accounts` — school's actual bank account master with IFSC, balance tracking
- `fac_bank_statement_imports` — imported bank statement files
- `fac_bank_statement_lines` — individual lines from imported statements
- `fac_petty_cash_books` — imprest petty cash book per custodian
- `fac_petty_cash_entries` — individual petty cash transactions
- `fac_income_records` — non-fee income records (donations, grants, etc.)
- `fac_budget_cost_centers` — FAC-level named cost centers (maps to `acc_cost_centers`)
- `fac_budget_plans` — annual budget plans (maps to `acc_budgets`)
- `fac_gst_configs` — school GST configuration (GSTIN, registration type)
- `fac_hsn_sac_codes` — HSN/SAC code master for goods and services
- `fac_gst_transactions` — GST transaction registry for GSTR filing
- `fac_e_invoices` — e-invoicing records with IRN and QR code
- `fac_tally_export_sessions` — user-initiated Tally export sessions
- `fac_integration_configs` — QuickBooks/Zoho integration credentials

**Integration with `acc_*`:**
All double-entry posting goes through `VoucherServiceInterface::post(VoucherDTO)`. FAC never writes directly to `acc_journal_entries`. This ensures the Accounting module remains the single source of truth for the general ledger.

---

## 3. Stakeholders & Actors

| Actor | Role |
|---|---|
| Finance Officer / Bursar | Daily financial operations: bank entries, petty cash, expense approval, bank reconciliation |
| School Accountant | Journal entries, ledger management, GST filing prep, financial reports |
| Principal / Management | Budget approval, expense approval (high-value), financial dashboard |
| Department Head | Views cost-center budget; submits budget requests |
| Staff Member | Submits expense claims |
| Auditor (external) | Read-only access to reports: Trial Balance, P&L, Balance Sheet, Ledger statements |
| System / Scheduler | Auto-posts recurring JEs, runs depreciation engine, sends budget-breach alerts |

---

## 4. Functional Requirements

### FR-FAC-001: Chart of Accounts Management
**RBS Reference:** K1 (Chart of Accounts), K2 (Opening Balances) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables (acc_*):** `acc_account_groups`, `acc_ledgers`, `acc_ledger_mappings`, `acc_fiscal_years`
**FAC Layer:** Management UI and validation layer; writes to `acc_*` tables via service

**Description:** Full management of the Chart of Accounts: hierarchical account groups (Assets → Current Assets → Cash & Bank) and individual ledger accounts. FAC provides the management UI over the `acc_*` tables. Account groups are typed as Assets/Liabilities/Income/Expense with Debit/Credit nature. Ledgers carry opening balance, reconciliation flag, and optional GST link. Ledger mappings link ledgers to source modules (Fees, Transport, HR, Vendor).

**Actors:** School Accountant, Finance Officer
**Input:**
- Account Group: `name`, `code` (UNIQUE), `parent_id` (nullable for top-level), `group_type` ENUM(Assets/Liabilities/Income/Expense), `nature` ENUM(Debit/Credit)
- Ledger: `name`, `code` (UNIQUE), `account_group_id`, `opening_balance`, `balance_type`, `as_of_date`, `allow_reconciliation`, `has_gst`, `gst_number`
- Fiscal Year: `name` (e.g., "2025-26"), `start_date` (1-Apr), `end_date` (31-Mar), `is_closed`

**Processing:**
- Account group code must be unique
- A ledger cannot be deleted if it has posted journal entries
- Fiscal year closure: validates all journal entries in the year are approved before closing
- Opening balance journal entry auto-created via `VoucherServiceInterface` when ledger is saved with non-zero opening balance

**Output:** Chart of accounts tree view; ledger balance statement

**Acceptance Criteria:**
- AC-001-01: Root-level groups only have parent_id = NULL; sub-groups must have a valid parent
- AC-001-02: Circular parent references blocked at application level
- AC-001-03: Ledger with posted entries cannot be deleted; soft delete only with confirmation
- AC-001-04: Fiscal year close blocked if any JE in that year is in Draft/Pending status

---

### FR-FAC-002: Opening Balances Setup
**RBS Reference:** K2 (Opening Balances) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables (acc_*):** `acc_ledgers`, `acc_journal_entries`, `acc_journal_entry_lines`

**Description:** One-time setup of opening balances when a school first onboards onto Prime-AI. Supports individual ledger opening balance entry and bulk import. Student outstanding fee balances import (CSV with student name, class, amount). Vendor outstanding payables mapping.

**Actors:** School Accountant
**Input:**
- Per ledger: `ledger_id`, `opening_balance` DECIMAL(15,2), `balance_type` ENUM(Debit/Credit), `as_of_date`
- Student outstanding: CSV upload (student_id, outstanding_amount)
- Vendor outstanding: `vendor_id`, `outstanding_amount`

**Processing:**
- Opening balance saved to `acc_ledgers.opening_balance` and creates a special opening-balance JE (entry_type = 'Journal', reference = 'OB')
- Student outstanding bulk import validates student_id existence before committing
- Fiscal year constraint: opening balances must be dated before first transaction date

**Output:** Opening balance confirmation report; JE reference

**Acceptance Criteria:**
- AC-002-01: Opening balance import is atomic — partial rows not committed on error
- AC-002-02: Opening JE cannot be edited after confirmation (locked journal entry)
- AC-002-03: Bulk student outstanding import returns row-level error report on validation failure

---

### FR-FAC-003: Journal Entry Management
**RBS Reference:** K3 (Journal Entry Management) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables (acc_*):** `acc_journal_entries`, `acc_journal_entry_lines`, `acc_recurring_journal_templates`, `acc_recurring_journal_template_lines`

**Description:** Manual journal entry creation and management with multi-line debit/credit support, narration, attachment uploads, and an approval workflow. Recurring journal template setup for periodic entries (monthly rent, salary accruals). Recurring templates auto-generate JEs on schedule via a Laravel scheduler command.

**Actors:** School Accountant, Finance Officer (create); Finance Officer / Principal (approve)
**Input:**
- JE header: `entry_date`, `fiscal_year_id`, `entry_type` ENUM(Manual/Sales/Purchase/Receipt/Payment/Contra/Journal), `narration`, `reference`
- JE lines: one or more `{ledger_id, debit, credit, narration}` pairs
- Recurring template: `name`, `start_date`, `end_date`, `frequency` ENUM(Daily/Weekly/Monthly/Quarterly/Yearly), `day_of_month`, template lines

**Processing:**
- Debit total must equal Credit total — enforced at both frontend and service layer
- Minimum 2 lines per JE (at least one debit, at least one credit)
- Approval workflow: `Draft → Pending Approval → Approved → (Rejected)`
- Approved JE cannot be edited; reversal JE must be created
- Recurring: scheduler runs daily, checks templates where next_run_date = today, auto-generates JE with status = Draft (or Approved if auto-approve flag set)

**Output:** JE list with status, ledger postings, approval trail

**Acceptance Criteria:**
- AC-003-01: Debit ≠ Credit → 422 validation error, JE not saved
- AC-003-02: Approved JE is immutable; edit button hidden; only "Reverse" action available
- AC-003-03: Recurring JE generation is logged in `sys_activity_logs`
- AC-003-04: Rejection reason is mandatory on reject action

---

### FR-FAC-004: Accounts Receivable — Non-Fee Income
**RBS Reference:** K4 (Accounts Receivable) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `fac_income_records`, `fac_income_categories`
**acc_* tables used:** `acc_journal_entries`, `acc_sales_invoices`

**Description:** Tracking of school income beyond student fees. Covers donations, government grants, rental income (hall/ground rental), event income, sponsorships, canteen lease income, interest income. Each income record is linked to an income ledger and auto-posts a JE via the Accounting module. AR aging report for outstanding receivables. Collection follow-up for overdue items.

**Actors:** Finance Officer, School Accountant
**Input:**
- Income category: `name`, `code`, `income_ledger_id` FK→acc_ledgers, `is_taxable`, `tax_rate_id`
- Income record: `income_category_id`, `income_date`, `payer_name`, `description`, `amount`, `received_amount`, `payment_mode`, `reference_no`, `bank_account_id`

**Processing:**
- On save: if `received_amount = amount` → status = Received; if partial → status = Partially Received
- Auto-post JE via `VoucherServiceInterface`: Dr Bank/Cash → Cr Income Ledger
- If taxable: include GST lines in JE
- AR Aging: group outstanding income records into 0-30/31-60/61-90/90+ day buckets
- Collection follow-up: send reminder notification to assigned follow-up officer

**Output:** Income register, AR aging report, income ledger balance

**Acceptance Criteria:**
- AC-004-01: JE is auto-created upon saving income record with received_amount > 0
- AC-004-02: Partial receipt creates a receivable balance tracked in AR aging
- AC-004-03: AR aging correctly classifies overdue records by date buckets
- AC-004-04: Collection reminder notification sent when record is 30+ days overdue

---

### FR-FAC-005: Accounts Payable & Vendor Bills
**RBS Reference:** K5 (Accounts Payable), K6 (Vendor Management — accounting layer only) | **Priority:** High | **Status:** 📐 Proposed
**Tables (acc_*):** `acc_purchase_invoices`, `acc_invoice_lines`, `acc_invoice_tax_lines`, `acc_payment_transactions`

**Description:** School-level AP management as an accounting integration layer over the Vendor module (`vnd_*`). Vendor bills received are formally recorded as purchase invoices in the accounting system. Payments are processed with bank account selection and payment mode, generating payment vouchers auto-posted via the Accounting module. Note: vendor operational management (RFQ, PO, vendor profiles, ratings) resides in the Vendor module. This FR covers the accounting side only.

**Actors:** Finance Officer, School Accountant
**Input:**
- Vendor bill: `vendor_id` FK→vnd_vendors, `invoice_number` (vendor's), `invoice_date`, `due_date`, lines with `{description, amount, ledger_id, tax_rate_id}`, attachment
- Payment: `purchase_invoice_id`, `payment_date`, `payment_mode` ENUM(cash/cheque/neft/upi/dd), `amount`, `bank_account_id`, `reference_no`

**Processing:**
- Purchase invoice auto-posts JE: Dr Expense Ledger(s) → Cr Vendor Payable
- Payment auto-posts JE: Dr Vendor Payable → Cr Bank/Cash
- Verify PO linkage: if vendor has a PO in Vendor module, link purchase invoice to PO
- Input tax credit: if GSTIN configured, extract GST input credit to ITC ledger

**Output:** Payables register, payment history, vendor ledger statement

**Acceptance Criteria:**
- AC-005-01: Duplicate vendor invoice number (same vendor) blocked with 422 error
- AC-005-02: Payment cannot exceed outstanding payable amount
- AC-005-03: ITC extraction creates separate JE lines to CGST/SGST Input ledgers
- AC-005-04: PO linkage validated — warning if bill amount exceeds PO amount by > 5%

---

### FR-FAC-006: Bank Account Management
**RBS Reference:** K8 (Bank & Cash Management) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables:** `fac_bank_accounts`

**Description:** Management of the school's multiple bank accounts. Each bank account record stores the bank name, account number, account type, branch, IFSC code, and current balance. The balance is maintained by summing all transactions linked to this account. Integration with ledgers: each bank account maps to a corresponding `acc_ledger` for double-entry purposes.

**Actors:** Finance Officer, School Accountant
**Input:**
- `bank_name`, `account_number` (UNIQUE), `account_type` ENUM(savings/current/fd/od), `branch`, `ifsc_code`, `opening_balance` DECIMAL(15,2), `ledger_id` FK→acc_ledgers, `is_primary`

**Processing:**
- IFSC code validated (11-character format: 4-letter bank code + 0 + 6-digit branch code)
- `ledger_id` must reference an account under Assets group (validated)
- `current_balance` computed column: `opening_balance + sum(credits) - sum(debits)` from JE lines linked to `ledger_id`
- Primary bank account: only one account can be `is_primary = 1` per tenant (enforced by generated unique index)

**Output:** Bank account list with current balances; bank statement view per account

**Acceptance Criteria:**
- AC-006-01: Duplicate account number blocked at DB level (UNIQUE KEY)
- AC-006-02: Account type FD/OD requires maturity_date (FD) or overdraft_limit (OD) — conditional fields
- AC-006-03: Ledger assigned must be under Assets group — validated at service layer
- AC-006-04: Deactivating a bank account blocks new transactions but preserves history

---

### FR-FAC-007: Bank Reconciliation
**RBS Reference:** K8 (Bank Reconciliation) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `fac_bank_statement_imports`, `fac_bank_statement_lines`
**acc_* tables used:** `acc_bank_reconciliations`, `acc_reconciliation_matches`

**Description:** Monthly bank reconciliation workflow. Finance officer uploads a bank statement (CSV or MT940 format). System auto-matches imported statement lines against posted JE lines in the corresponding ledger. Unmatched items are presented for manual matching or creating new JEs (for bank charges, interest credited, etc.). Reconciliation report shows book balance vs bank statement balance with unreconciled items.

**Actors:** Finance Officer, School Accountant
**Input:**
- Statement upload: `bank_account_id`, `statement_file` (CSV/MT940), `statement_date`, `closing_balance`
- Manual match: link `fac_bank_statement_line.id` to `acc_journal_entry_line.id`
- New JE from unmatched bank line: amount, description, ledger selection

**Processing:**
- Auto-match algorithm: match by amount + date (±3 days tolerance) + description keyword
- Match confidence score: exact amount + exact date = 100%; amount match only = 70%; amount + ±3 days = 85%
- Unmatched bank credits (interest, refunds) → prompt to create income JE
- Unmatched bank debits (charges, fees) → prompt to create expense JE
- Reconciliation complete when `book_balance = bank_statement_closing_balance`

**Output:** Reconciliation statement PDF with: book balance, outstanding deposits, outstanding cheques, adjusted balance, bank statement closing balance

**Acceptance Criteria:**
- AC-007-01: CSV import supports formats from major Indian banks (HDFC, SBI, ICICI, Axis, Kotak)
- AC-007-02: Auto-match correctly pairs ≥ 90% of standard salary/vendor payment transactions
- AC-007-03: Reconciliation cannot be completed if difference ≠ 0 (override requires Finance Officer level permission)
- AC-007-04: All manually created JEs from reconciliation carry `reference = reconciliation_[id]`

---

### FR-FAC-008: Petty Cash Management
**RBS Reference:** K8 (Cash Register, K7 Expense Claims overlay) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `fac_petty_cash_books`, `fac_petty_cash_entries`

**Description:** Imprest petty cash system. A petty cash book is assigned to a custodian (e.g., Office Manager) with a fixed imprest amount (e.g., ₹10,000). Expenditures are recorded as payments, receipts as reimbursements. When balance falls below a threshold, the custodian submits a reimbursement request, which on approval restores balance to the imprest level. All entries are auto-posted as JEs via the Accounting module.

**Actors:** Custodian (entries), Finance Officer (replenishment approval)
**Input:**
- Book: `custodian_id`, `imprest_amount` DECIMAL(15,2), `replenishment_threshold` DECIMAL(15,2), `ledger_id` FK→acc_ledgers, `academic_session_id`
- Entry: `book_id`, `entry_date`, `type` ENUM(receipt/payment), `amount`, `purpose`, `category_id`, `receipt_no`, `receipt_attachment`

**Processing:**
- `balance = imprest_amount + sum(receipts) - sum(payments)`
- Auto-alert to Finance Officer when `balance < replenishment_threshold`
- Replenishment: Finance Officer approves → JE posted: Dr Petty Cash → Cr Bank Account
- Payment entry posts JE: Dr Expense Ledger → Cr Petty Cash
- Receipt entry posts JE: Dr Petty Cash → Cr Income Ledger
- Monthly petty cash book report: opening balance + receipts - payments = closing balance

**Output:** Petty cash book register, replenishment report, monthly cash book

**Acceptance Criteria:**
- AC-008-01: Payment entry blocked when `amount > current balance`
- AC-008-02: Replenishment restores balance to exactly `imprest_amount`
- AC-008-03: Each petty cash entry creates a corresponding JE automatically
- AC-008-04: Monthly cash book PDF balances debit = credit

---

### FR-FAC-009: Budget Management
**RBS Reference:** K12 (Budget & Cost Center Management) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `fac_budget_plans`, `fac_budget_cost_centers`
**acc_* tables used:** `acc_cost_centers`, `acc_budgets`

**Description:** Annual budget planning and cost-center management. School defines the annual budget (total institutional budget), then allocates it to departments/cost centers (Academics, Sports, Admin, Labs, Library, etc.). Each allocation is linked to an expense/income ledger. Budget tracking compares commitments (approved POs from Vendor module) and actuals (posted JEs) against the budget. Variance reports and over-budget alerts.

**Actors:** Finance Officer / Accountant (create), Principal (approve)
**Input:**
- Cost center: `name`, `code` (UNIQUE), `department`, `responsible_person_id`
- Budget plan: `fiscal_year_id`, `name`, `total_amount`, `status` ENUM(draft/submitted/approved/active)
- Budget allocation: `budget_plan_id`, `cost_center_id`, `ledger_id` FK→acc_ledgers, `allocated_amount`, `notes`

**Processing:**
- Sum of all allocations must ≤ `budget_plan.total_amount` (warn if > total)
- Budget tracking: `actual_spend = sum(JE debit lines for ledger in fiscal year)` pulled from `acc_journal_entry_lines`
- `committed_spend = sum(approved PO amounts from vnd_purchase_orders for this cost center)`
- `available_balance = allocated_amount - committed_spend - actual_spend`
- Over-budget alert: fire notification to Finance Officer and Department Head when actual > 90% of allocation
- Budget variance report: allocated vs committed vs actual vs variance (amount + %)

**Output:** Budget dashboard per cost center, variance report, over-budget alert log

**Acceptance Criteria:**
- AC-009-01: Budget plan requires approval by Principal before status = active
- AC-009-02: Active budget plan blocks creation of another active plan for same fiscal year + cost center
- AC-009-03: Over-budget alert fired within 1 hour of variance threshold breach
- AC-009-04: Budget variance report exports correctly to PDF and Excel

---

### FR-FAC-010: GST Configuration & Compliance
**RBS Reference:** K13 (GST & Tax Compliance Engine) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** `fac_gst_configs`, `fac_hsn_sac_codes`, `fac_gst_transactions`, `fac_e_invoices`
**acc_* tables used:** `acc_tax_rates`, `acc_invoice_tax_lines`

**Description:** Complete GST compliance engine for schools registered under Goods and Services Tax. Covers GSTIN configuration, HSN/SAC code management for fee heads and services, CGST/SGST/IGST tax rule configuration (intra-state vs inter-state), GSTR-1 (outward supply) and GSTR-3B (summary return) report compilation, e-invoicing with IRN generation via the government portal (NIC), and QR code attachment to invoices.

Note: Schools providing educational services are largely exempt from GST (Section 9, CGST Act — educational services to students). However, schools may be registered for services like transportation, canteen, hiring of facilities, stationery sales, etc. This module handles those taxable activities.

**Actors:** School Accountant, Finance Officer
**Input:**
- GST Config: `gstin` VARCHAR(15), `legal_name`, `trade_name`, `registration_type` ENUM(regular/composition/exempt), `state_code`, `e_invoicing_applicable` TINYINT(1), `gst_return_frequency` ENUM(monthly/quarterly)
- HSN/SAC: `code`, `description`, `type` ENUM(HSN/SAC), `applicable_tax_rate_id`, `is_exempt`
- Tax Rules: configured via `acc_tax_rates` (CGST, SGST, IGST rates)

**Processing:**
- GSTIN validation: 15-character format (2-digit state code + 10-char PAN + 1-char entity + 1-char Z + 1 checksum)
- Tax calculation: `is_interstate = 1` → IGST only; `is_interstate = 0` → split CGST + SGST equally
- GSTR-1: compile all outward supply invoices in period, group by B2B/B2C/export, compute tax amounts
- GSTR-3B: summarize: outward tax liability, ITC available, net tax payable
- E-invoicing: POST to IRP (Invoice Registration Portal) API → receive IRN + signed JSON → generate QR code → attach to invoice
- GST transaction registry: all taxable transactions linked to `fac_gst_transactions`

**Output:** GSTR-1 report (downloadable JSON for portal upload), GSTR-3B summary, e-invoice with QR, tax payable summary

**Acceptance Criteria:**
- AC-010-01: GSTIN validation enforces 15-character format with state code check
- AC-010-02: GSTR-1 correctly classifies B2B (GSTIN available) vs B2C invoices
- AC-010-03: E-invoice IRN generation fails gracefully with error log — does not corrupt base invoice
- AC-010-04: CGST + SGST rates sum to IGST rate for equivalent transactions

---

### FR-FAC-011: Financial Reports
**RBS Reference:** K10 (Financial Reporting) | **Priority:** Critical | **Status:** 📐 Proposed
**Tables (acc_*):** All journal entry and ledger tables (read-only for FAC)

**Description:** Generation of standard financial reports from the `acc_*` double-entry data. Reports are real-time, computed on demand from posted journal entries. Supports date-range filtering, fiscal-year filter, and cost-center filter. All reports exportable to PDF and Excel.

**Actors:** School Accountant, Finance Officer, Principal, External Auditor (read-only)
**Reports:**

| Report | Description |
|---|---|
| Trial Balance | All ledgers with debit and credit totals; proves debit = credit |
| Profit & Loss | Income − Expense for the period; grouped by account group |
| Balance Sheet | Assets = Liabilities + Equity; as of specified date |
| Cash Flow Statement | Operating/Investing/Financing cash flows |
| Ledger Statement | All debit/credit entries for a specific ledger with running balance |
| Day Book | All JEs posted on a specific date |
| Cash Book | All cash/bank ledger entries with opening and closing balance |
| Accounts Receivable Aging | Outstanding receivables by age bucket |
| Accounts Payable Aging | Outstanding vendor payables by age bucket |

**Processing:**
- Trial Balance: group `acc_journal_entry_lines` by `ledger_id`, sum debits and credits, add opening balance
- P&L: filter Income and Expense group ledgers; compute net profit = total income − total expense
- Balance Sheet: Assets = liabilities + equity (retained earnings = cumulative P&L)
- Fiscal year filter applied to `acc_journal_entries.fiscal_year_id`

**Output:** Formatted HTML + PDF + Excel reports

**Acceptance Criteria:**
- AC-011-01: Trial Balance debit total = credit total (always — if not, log data integrity alert)
- AC-011-02: Balance Sheet Assets = Liabilities + Equity (validated before display)
- AC-011-03: All reports support export to PDF (via DomPDF) and Excel (via native fputcsv or Maatwebsite)
- AC-011-04: Reports for closed fiscal years show historical data (immutable after year-close)

---

### FR-FAC-012: Finance Dashboard
**RBS Reference:** K10 (Dashboards) | **Priority:** High | **Status:** 📐 Proposed
**Tables:** Read from `acc_*` and `fac_*` tables

**Description:** Real-time finance dashboard showing key financial KPIs. Revenue vs Expense bar/line chart. Cash flow trend. Outstanding receivables and payables. Budget utilization per cost center (gauges). Bank account balances. Recent journal entries. Alerts: over-budget warnings, unreconciled bank entries, pending approvals.

**Actors:** Principal, Finance Officer, School Accountant
**Widgets:**
- Total Income vs Total Expense (current fiscal year) — bar chart, monthly breakdown
- Net Surplus / Deficit — large KPI card
- Bank Account Balances — summary cards per bank account
- AR Outstanding — total receivable amount, breakdown by age
- AP Outstanding — total payable amount
- Budget Utilization — progress bars per cost center
- Pending Approvals — count of JEs, expense claims awaiting approval
- Cash Flow Trend — 12-month rolling chart

**Processing:**
- All data computed from `acc_journal_entries` (approved entries only) + `fac_*` tables
- Dashboard is lazy-computed on first load with 30-minute cache; invalidated on new JE approval
- Role-based widget visibility: Principal sees all widgets; Department Head sees only their cost center budget widget

**Output:** Interactive dashboard HTML page with Chart.js or similar

**Acceptance Criteria:**
- AC-012-01: Dashboard loads within 3 seconds (cached computation)
- AC-012-02: Over-budget alerts shown as red badges with cost center name and overage amount
- AC-012-03: Clicking bank account balance opens ledger statement for that account

---

### FR-FAC-013: Fixed Asset Register & Depreciation
**RBS Reference:** K9 (Asset Register & Depreciation) | **Priority:** Medium | **Status:** 📐 Proposed
**Tables (acc_*):** `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries`

**Description:** Management of the school's fixed asset register. Assets are categorized (Furniture, Computers, Vehicles, Lab Equipment, Building). Each asset has a purchase cost, acquisition JE, depreciation method (SLM = Straight Line Method; WDV = Written Down Value), useful life, and salvage value. The depreciation engine calculates and posts annual depreciation JEs. Asset disposal records sale/write-off.

**Actors:** Finance Officer, School Accountant
**Input:**
- Asset Category: `name`, `code`, `depreciation_method` ENUM(SLM/WDV), `depreciation_rate` DECIMAL(5,2), `useful_life_years`
- Fixed Asset: `name`, `asset_code` (UNIQUE), `asset_category_id`, `purchase_date`, `purchase_cost`, `salvage_value`, `current_value`, `location`, `vendor_id` (nullable), `asset_ledger_id`
- Depreciation run: `fiscal_year_id`, `depreciation_date`

**Processing:**
- SLM depreciation: `(purchase_cost - salvage_value) / useful_life_years` per year; prorated for partial years
- WDV depreciation: `current_value * depreciation_rate / 100` per year
- Depreciation JE auto-posted: Dr Depreciation Expense Ledger → Cr Accumulated Depreciation Ledger
- Asset disposal: Dr Accumulated Depreciation + Dr/Cr Gain/Loss on Disposal → Cr Asset Ledger
- `current_value` updated after each depreciation run

**Output:** Asset register list, depreciation schedule, depreciation JE, net block report

**Acceptance Criteria:**
- AC-013-01: Depreciation engine idempotent — re-running for same fiscal year replaces existing depreciation entries
- AC-013-02: SLM depreciation does not reduce current_value below salvage_value
- AC-013-03: Disposed assets are excluded from subsequent depreciation runs
- AC-013-04: Net block report shows: cost − accumulated depreciation = net book value (always balanced)

---

### FR-FAC-014: Tally & External Integration
**RBS Reference:** K11 (Integrations — Tally/QuickBooks) | **Priority:** Medium | **Status:** 📐 Proposed
**Tables:** `fac_tally_export_sessions`, `fac_integration_configs`
**acc_* tables used:** `acc_tally_export_logs`

**Description:** Data export and sync with external accounting software. Tally integration: export journal vouchers (JE/Receipt/Payment) in Tally XML format (TallyPrime-compatible). Export ledger master in Tally XML. QuickBooks/Zoho Books: API-based sync of chart of accounts and transaction records.

**Actors:** School Accountant, Finance Officer
**Input:**
- Tally export: date range (`from_date`, `to_date`), `export_type` ENUM(Ledgers/Journal_Vouchers/All)
- QuickBooks config: `client_id`, `client_secret`, `realm_id`, `access_token`, `refresh_token`
- Zoho Books config: `organization_id`, `client_id`, `client_secret`, `access_token`

**Processing (Tally):**
- Fetch all approved JEs in date range from `acc_journal_entries`
- Map ledger names to Tally group names using configurable mapping table
- Generate Tally XML using `<ENVELOPE><TALLYMESSAGE>` structure
- Download as `.xml` file
- Log export to `acc_tally_export_logs` with status, file name, row count

**Processing (QuickBooks/Zoho):**
- OAuth2 flow for initial authentication
- Sync COA: create/update accounts via API
- Sync transactions: push approved JEs as journal entries via API
- Pull bank transactions: import from connected bank feed

**Output:** Tally-compatible XML file download, integration sync status, error log

**Acceptance Criteria:**
- AC-014-01: Tally XML validates against TallyPrime import schema without errors for standard JEs
- AC-014-02: Export session stored in `fac_tally_export_sessions` with start/end timestamp and row count
- AC-014-03: QuickBooks OAuth token refresh handled automatically on expiry
- AC-014-04: Failed API sync records error in `fac_integration_configs.last_error` — does not corrupt local data

---

## 5. Proposed Database Tables

### 5.1 Bank Account Management Tables

**`fac_bank_accounts`** — School bank account master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `bank_name` | VARCHAR(100) NOT NULL | |
| `account_number` | VARCHAR(30) NOT NULL UNIQUE | |
| `account_type` | ENUM('savings','current','fd','od') NOT NULL | |
| `branch` | VARCHAR(100) NULL | |
| `ifsc_code` | VARCHAR(11) NULL | 4-char bank + 0 + 6-char branch |
| `opening_balance` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | linked Cash/Bank ledger |
| `maturity_date` | DATE NULL | FD only |
| `overdraft_limit` | DECIMAL(15,2) NULL | OD only |
| `is_primary` | TINYINT(1) NOT NULL DEFAULT 0 | only one primary allowed |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`fac_bank_statement_imports`** — Imported bank statement file records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `bank_account_id` | BIGINT UNSIGNED NOT NULL FK→fac_bank_accounts | |
| `statement_date` | DATE NOT NULL | end date of statement |
| `opening_balance` | DECIMAL(15,2) NOT NULL | as per bank statement |
| `closing_balance` | DECIMAL(15,2) NOT NULL | as per bank statement |
| `file_path` | VARCHAR(500) NULL | uploaded CSV/MT940 file |
| `import_status` | ENUM('pending','processing','completed','failed') NOT NULL DEFAULT 'pending' | |
| `total_lines` | INT UNSIGNED NOT NULL DEFAULT 0 | |
| `matched_lines` | INT UNSIGNED NOT NULL DEFAULT 0 | |
| `reconciliation_id` | BIGINT UNSIGNED NULL FK→acc_bank_reconciliations | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`fac_bank_statement_lines`** — Individual lines from imported bank statements

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `import_id` | BIGINT UNSIGNED NOT NULL FK→fac_bank_statement_imports | |
| `transaction_date` | DATE NOT NULL | |
| `description` | VARCHAR(500) NULL | bank narration |
| `reference` | VARCHAR(100) NULL | cheque no / UTR / NEFT ref |
| `credit_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `debit_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | |
| `balance` | DECIMAL(15,2) NULL | running balance from bank |
| `match_status` | ENUM('unmatched','auto_matched','manually_matched','unreconcilable') NOT NULL DEFAULT 'unmatched' | |
| `match_confidence` | TINYINT UNSIGNED NULL | 0-100 |
| `matched_je_line_id` | BIGINT UNSIGNED NULL FK→acc_journal_entry_lines | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.2 Petty Cash Tables

**`fac_petty_cash_books`** — Petty cash book per custodian

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `custodian_id` | BIGINT UNSIGNED NOT NULL FK→sys_users | |
| `academic_session_id` | BIGINT UNSIGNED NOT NULL FK→sch_academic_sessions | |
| `name` | VARCHAR(100) NOT NULL | e.g., "Admin Office Petty Cash" |
| `imprest_amount` | DECIMAL(15,2) NOT NULL | maximum balance to maintain |
| `replenishment_threshold` | DECIMAL(15,2) NOT NULL | alert when balance falls below this |
| `balance` | DECIMAL(15,2) NOT NULL DEFAULT 0 | computed running balance |
| `ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | Cash in Hand ledger |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`fac_petty_cash_entries`** — Individual petty cash transactions

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `book_id` | BIGINT UNSIGNED NOT NULL FK→fac_petty_cash_books | |
| `entry_date` | DATE NOT NULL | |
| `type` | ENUM('receipt','payment','replenishment') NOT NULL | |
| `amount` | DECIMAL(10,2) NOT NULL | |
| `purpose` | VARCHAR(255) NOT NULL | |
| `expense_ledger_id` | BIGINT UNSIGNED NULL FK→acc_ledgers | for payment entries |
| `income_ledger_id` | BIGINT UNSIGNED NULL FK→acc_ledgers | for receipt entries |
| `receipt_no` | VARCHAR(50) NULL | |
| `receipt_attachment` | VARCHAR(500) NULL | file path |
| `journal_entry_id` | BIGINT UNSIGNED NULL FK→acc_journal_entries | auto-created JE |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.3 Income Tracking Tables

**`fac_income_categories`** — Non-fee income category master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | e.g., Donation, Government Grant, Hall Rental |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `income_ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | |
| `is_taxable` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `tax_rate_id` | BIGINT UNSIGNED NULL FK→acc_tax_rates | |
| `sac_code_id` | BIGINT UNSIGNED NULL FK→fac_hsn_sac_codes | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`fac_income_records`** — Non-fee income transaction records

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `income_category_id` | BIGINT UNSIGNED NOT NULL FK→fac_income_categories | |
| `income_date` | DATE NOT NULL | |
| `payer_name` | VARCHAR(150) NOT NULL | |
| `payer_gstin` | VARCHAR(15) NULL | if payer is registered |
| `description` | TEXT NULL | |
| `amount` | DECIMAL(15,2) NOT NULL | total invoice amount |
| `received_amount` | DECIMAL(15,2) NOT NULL DEFAULT 0 | amount actually received |
| `payment_mode` | ENUM('cash','cheque','neft','upi','dd','other') NULL | |
| `reference_no` | VARCHAR(100) NULL | UTR / cheque no |
| `bank_account_id` | BIGINT UNSIGNED NULL FK→fac_bank_accounts | |
| `status` | ENUM('pending','partially_received','received','cancelled') NOT NULL DEFAULT 'pending' | |
| `journal_entry_id` | BIGINT UNSIGNED NULL FK→acc_journal_entries | |
| `gst_transaction_id` | BIGINT UNSIGNED NULL FK→fac_gst_transactions | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

---

### 5.4 Budget Management Tables

**`fac_budget_cost_centers`** — FAC cost center / department master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `name` | VARCHAR(100) NOT NULL | e.g., Academics Dept, Sports Dept |
| `code` | VARCHAR(20) NOT NULL UNIQUE | |
| `department` | VARCHAR(100) NULL | |
| `responsible_person_id` | BIGINT UNSIGNED NULL FK→sys_users | |
| `acc_cost_center_id` | BIGINT UNSIGNED NULL FK→acc_cost_centers | maps to acc module |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`fac_budget_plans`** — Annual budget plan header

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `fiscal_year_id` | BIGINT UNSIGNED NOT NULL FK→acc_fiscal_years | |
| `name` | VARCHAR(150) NOT NULL | e.g., "Annual Budget FY 2025-26" |
| `total_amount` | DECIMAL(15,2) NOT NULL | |
| `status` | ENUM('draft','submitted','approved','active','closed') NOT NULL DEFAULT 'draft' | |
| `approved_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `approved_at` | TIMESTAMP NULL | |
| `notes` | TEXT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| `deleted_at` | TIMESTAMP NULL | |

**`fac_budget_allocations`** — Line-level budget allocations per cost center / ledger

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `budget_plan_id` | BIGINT UNSIGNED NOT NULL FK→fac_budget_plans | |
| `cost_center_id` | BIGINT UNSIGNED NOT NULL FK→fac_budget_cost_centers | |
| `ledger_id` | BIGINT UNSIGNED NOT NULL FK→acc_ledgers | expense/income ledger |
| `allocated_amount` | DECIMAL(15,2) NOT NULL | |
| `notes` | VARCHAR(255) NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`budget_plan_id`, `cost_center_id`, `ledger_id`) | |

---

### 5.5 GST Compliance Tables

**`fac_gst_configs`** — School's GST registration configuration

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `gstin` | VARCHAR(15) NOT NULL UNIQUE | 15-char GST Identification Number |
| `legal_name` | VARCHAR(150) NOT NULL | as per GST registration |
| `trade_name` | VARCHAR(150) NULL | |
| `registration_type` | ENUM('regular','composition','exempt','nil') NOT NULL DEFAULT 'regular' | |
| `state_code` | VARCHAR(2) NOT NULL | e.g., 27 for Maharashtra |
| `address` | TEXT NULL | |
| `e_invoicing_applicable` | TINYINT(1) NOT NULL DEFAULT 0 | turnover > 5Cr threshold |
| `irp_username` | VARCHAR(100) NULL | Invoice Registration Portal credentials |
| `irp_password_encrypted` | TEXT NULL | |
| `gst_return_frequency` | ENUM('monthly','quarterly') NOT NULL DEFAULT 'monthly' | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`fac_hsn_sac_codes`** — HSN (goods) / SAC (services) code master

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `code` | VARCHAR(10) NOT NULL | 4-8 digit HSN or 6-digit SAC |
| `description` | VARCHAR(255) NOT NULL | |
| `type` | ENUM('HSN','SAC') NOT NULL | |
| `applicable_tax_rate_id` | BIGINT UNSIGNED NULL FK→acc_tax_rates | |
| `is_exempt` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |
| UNIQUE KEY | (`code`, `type`) | |

**`fac_gst_transactions`** — GST transaction registry for return filing

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `gst_config_id` | BIGINT UNSIGNED NOT NULL FK→fac_gst_configs | |
| `transaction_date` | DATE NOT NULL | |
| `transaction_type` | ENUM('outward_supply','inward_supply','credit_note','debit_note') NOT NULL | |
| `party_gstin` | VARCHAR(15) NULL | |
| `party_name` | VARCHAR(150) NULL | |
| `invoice_number` | VARCHAR(50) NOT NULL | |
| `taxable_amount` | DECIMAL(15,2) NOT NULL | |
| `cgst` | DECIMAL(12,2) NOT NULL DEFAULT 0 | |
| `sgst` | DECIMAL(12,2) NOT NULL DEFAULT 0 | |
| `igst` | DECIMAL(12,2) NOT NULL DEFAULT 0 | |
| `cess` | DECIMAL(12,2) NOT NULL DEFAULT 0 | |
| `total_tax` | DECIMAL(12,2) NOT NULL DEFAULT 0 | |
| `hsn_sac_id` | BIGINT UNSIGNED NULL FK→fac_hsn_sac_codes | |
| `journal_entry_id` | BIGINT UNSIGNED NULL FK→acc_journal_entries | |
| `return_period` | VARCHAR(7) NULL | MM-YYYY format |
| `is_included_in_gstr1` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_included_in_gstr3b` | TINYINT(1) NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`fac_e_invoices`** — E-invoicing records with IRN and QR code

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `gst_transaction_id` | BIGINT UNSIGNED NOT NULL FK→fac_gst_transactions | |
| `irn` | VARCHAR(64) NULL | Invoice Reference Number from NIC |
| `ack_no` | VARCHAR(20) NULL | Acknowledgement number |
| `ack_date` | TIMESTAMP NULL | |
| `signed_invoice` | LONGTEXT NULL | JSON returned by IRP |
| `qr_code_data` | TEXT NULL | Base64 QR code string |
| `qr_code_image_path` | VARCHAR(500) NULL | stored via sys_media |
| `status` | ENUM('pending','generated','failed','cancelled') NOT NULL DEFAULT 'pending' | |
| `error_message` | TEXT NULL | IRP error response |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.6 Integration Tables

**`fac_tally_export_sessions`** — Tally export session log

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `export_type` | ENUM('Ledgers','Journal_Vouchers','All') NOT NULL | |
| `from_date` | DATE NOT NULL | |
| `to_date` | DATE NOT NULL | |
| `file_name` | VARCHAR(255) NULL | |
| `file_path` | VARCHAR(500) NULL | |
| `total_records` | INT UNSIGNED NOT NULL DEFAULT 0 | |
| `status` | ENUM('processing','completed','failed') NOT NULL DEFAULT 'processing' | |
| `error_log` | TEXT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**`fac_integration_configs`** — External accounting software integration settings

| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT UNSIGNED PK AI | |
| `integration_type` | ENUM('quickbooks','zoho_books','busy','marg') NOT NULL | |
| `client_id` | VARCHAR(255) NULL | |
| `client_secret_encrypted` | TEXT NULL | AES encrypted |
| `access_token_encrypted` | TEXT NULL | |
| `refresh_token_encrypted` | TEXT NULL | |
| `token_expires_at` | TIMESTAMP NULL | |
| `realm_id` | VARCHAR(100) NULL | QuickBooks company ID |
| `organization_id` | VARCHAR(100) NULL | Zoho org ID |
| `last_sync_at` | TIMESTAMP NULL | |
| `last_error` | TEXT NULL | |
| `is_active` | TINYINT(1) NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED NULL FK→sys_users | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

## 6. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-FAC-001 | Performance | Financial reports (Trial Balance, P&L) must generate within 5 seconds for 10,000 JE lines |
| NFR-FAC-002 | Performance | Bank statement import (1,000 lines) and auto-match must complete within 30 seconds |
| NFR-FAC-003 | Performance | Finance dashboard loads within 3 seconds (server-side cache, 30-minute TTL) |
| NFR-FAC-004 | Security | Journal entry creation and approval require distinct permissions — the same user cannot both create and approve the same JE |
| NFR-FAC-005 | Security | Approved JEs are immutable — no edit/delete; reversal journal required |
| NFR-FAC-006 | Security | GST credentials (GSTIN, IRP password) stored encrypted at rest (AES-256) |
| NFR-FAC-007 | Security | External integration tokens encrypted; plain tokens never stored |
| NFR-FAC-008 | Compliance | All financial data tenant-isolated via stancl/tenancy |
| NFR-FAC-009 | Audit | Every JE creation, approval, and posting logged to `sys_activity_logs` |
| NFR-FAC-010 | Data Integrity | Double-entry balance constraint enforced at service layer before every JE post |
| NFR-FAC-011 | Reliability | Tally export job failure does not corrupt base JE data |
| NFR-FAC-012 | Scalability | Module supports up to 50,000 JE records per fiscal year per tenant |

---

## 7. Integration Points

| Module | Integration | Direction |
|---|---|---|
| Accounting (`acc_*`) | Double-entry engine: all JE posting via `VoucherServiceInterface` | FAC writes (via service) |
| StudentFee (`fin_*` / `acc_*`) | Fee invoices and payments already in `acc_*` — read for AR aging | FAC reads |
| Vendor (`vnd_*`) | Vendor bills linked to `vnd_vendors`, PO amounts pulled for budget commitment tracking | FAC reads |
| SchoolSetup (`sch_*`) | Academic sessions, school organization data | FAC reads |
| Staff / HR | Employee IDs for expense claims and custodian assignment | FAC reads |
| Notification | Over-budget alerts, reconciliation due reminders, approval notifications | FAC writes |
| sys_media | File attachments (receipts, vouchers, import files, PDF reports) | FAC writes |
| sys_activity_logs | Full audit trail for all financial actions | FAC writes |
| External: IRP (NIC) | E-invoice IRN generation API | FAC → external |
| External: Tally | XML file export | FAC → file |
| External: QuickBooks/Zoho | REST API sync | FAC ↔ external |

---

## 8. User Interface Requirements

### 8.1 Finance Dashboard
- KPI card strip: Total Income, Total Expense, Net Surplus, Cash Balance
- Revenue vs Expense bar chart (monthly breakdown for fiscal year)
- Cost center budget utilization gauges (one per active cost center)
- Pending approvals panel: JEs awaiting approval, expense claims, budget requests
- Quick links: New Journal Entry, Reconcile Bank, Run Depreciation

### 8.2 Chart of Accounts
- Tree view with expand/collapse per account group
- Inline balance display (Dr/Cr) per ledger
- Filter by group type (Assets/Liabilities/Income/Expense)

### 8.3 Journal Entry Form
- Multi-line grid: add/remove JE lines dynamically
- Real-time Dr/Cr totals with "Out of Balance: ₹X" warning
- Narration text with character counter
- File attachment drag-and-drop zone
- Submit for Approval / Save as Draft buttons

### 8.4 Bank Reconciliation Interface
- Two-panel layout: left = system JE lines (unmatched), right = bank statement lines (unmatched)
- Drag-to-match interaction (or checkbox + match button)
- Matched items collapse to middle "Matched" section
- Running reconciliation difference shown at top: "Difference: ₹0.00 — Balanced ✓"

### 8.5 Budget Tracker
- Table: Cost Center | Budget | Committed | Actuals | Available | % Used
- Color coding: green (< 80%), yellow (80–100%), red (> 100%)
- Drill-down: click cost center to see ledger-level breakdown

---

## 9. Financial Operations Workflow

```
[Year Setup]
Create Fiscal Year → Configure Chart of Accounts → Enter Opening Balances
    → Configure GST (if applicable) → Set Up Bank Accounts
    → Create Annual Budget → Get Budget Approved

[Daily Operations]
Bank Transactions → Record in bank accounts → Bank entries auto-JE or manual JE
Petty Cash Payments → Record in Petty Cash Book → Auto-JE created
Income Received → Record in Income Register → Auto-JE to income ledger
Vendor Bills Received → Enter Purchase Invoice → JE posted
Staff Expense Claims → Submit → Approve → JE posted

[Monthly Close]
Bank Reconciliation → Import Statement → Auto-match → Manual match → Complete
Review Pending JEs → Approve → Ledger balances updated
Run Budget Variance Report → Review over-budget items
GST GSTR-1 Preparation → Compile transactions → Generate JSON → Upload to portal
GST GSTR-3B Summary → Generate summary → Compute net liability

[Year-End]
Run Annual Depreciation → Depreciation JEs posted → Net block updated
Generate Trial Balance → Verify debit = credit
Generate P&L → Compute net surplus/deficit
Generate Balance Sheet → Verify assets = liabilities + equity
Export to Tally (if required) → Download XML → Import to Tally
Close Fiscal Year → All JEs locked → Year closed
```

---

## 10. Validation Rules

| Field | Rule |
|---|---|
| `fac_gst_configs.gstin` | 15-character format: 2-digit state + 10-char PAN + 1-char entity + Z + checksum |
| `fac_bank_accounts.ifsc_code` | 11-character: 4-alpha bank code + 0 + 6-alphanumeric branch |
| `fac_bank_accounts.account_number` | UNIQUE across tenant |
| `acc_journal_entries` debit/credit | sum(debit lines) = sum(credit lines) — enforced at service layer |
| `fac_petty_cash_entries` payment | `amount ≤ book.balance` |
| `fac_budget_plans.total_amount` | sum(allocations) should not exceed total (warn if > total) |
| `fac_e_invoices` — prerequisite | `fac_gst_configs.e_invoicing_applicable = 1` must be set |
| `acc_fiscal_years` close | No JE in Draft/Pending status before close |
| `fac_hsn_sac_codes.code` | 4-8 digits for HSN, 6 digits for SAC |
| `fac_budget_allocations` unique | One row per (budget_plan, cost_center, ledger) |

---

## 11. Security & Permissions

| Permission | Description |
|---|---|
| `fac.coa.view` | View Chart of Accounts |
| `fac.coa.manage` | Create/edit account groups and ledgers |
| `fac.fiscal_year.manage` | Create and close fiscal years |
| `fac.journal.create` | Create journal entries (draft/submit) |
| `fac.journal.approve` | Approve/reject pending journal entries |
| `fac.journal.reverse` | Create reversal JE for approved entry |
| `fac.bank.manage` | Add/edit bank accounts |
| `fac.reconciliation.manage` | Perform bank reconciliation |
| `fac.petty_cash.manage` | Manage petty cash books and entries |
| `fac.income.manage` | Record non-fee income entries |
| `fac.ap.manage` | Enter vendor bills and process payments |
| `fac.budget.create` | Create and edit budget plans |
| `fac.budget.approve` | Approve budget plans (Principal level) |
| `fac.budget.view` | View budget and variance reports |
| `fac.gst.configure` | Configure GST settings and HSN/SAC codes |
| `fac.gst.generate_returns` | Generate GSTR reports |
| `fac.asset.manage` | Add/edit fixed assets |
| `fac.depreciation.run` | Run depreciation engine |
| `fac.reports.view` | View standard financial reports |
| `fac.tally.export` | Generate and download Tally XML |
| `fac.integration.configure` | Configure QuickBooks/Zoho integration |

**Segregation of Duties:**
- A user cannot both create AND approve the same journal entry (enforced at Gate level: `approved_by != created_by`)
- Budget approval requires `fac.budget.approve` — separate from `fac.budget.create`
- GST credential configuration restricted to users with `fac.gst.configure` — Finance Officer or above

---

## 12. Reporting Requirements

| Report | Description | Export |
|---|---|---|
| Trial Balance | All ledgers with Dr/Cr totals; debit = credit verification | PDF, Excel |
| Profit & Loss Statement | Income − Expense by account group for period | PDF, Excel |
| Balance Sheet | Assets = Liabilities + Equity as of date | PDF, Excel |
| Cash Flow Statement | Operating/Investing/Financing activities | PDF, Excel |
| Ledger Statement | All entries for specific ledger with running balance | PDF, Excel |
| Day Book | All JEs posted on a date | PDF, Excel |
| Cash/Bank Book | All cash/bank entries with opening/closing balance | PDF, Excel |
| AR Aging | Outstanding income receivables by age bucket | PDF, Excel |
| AP Aging | Outstanding vendor payables by age bucket | PDF, Excel |
| Budget Variance | Allocated vs Actuals vs Variance by cost center | PDF, Excel |
| Petty Cash Book | Month-wise petty cash register | PDF |
| Bank Reconciliation Statement | Reconciled and unreconciled items | PDF |
| GST Tax Register | All taxable transactions in period | PDF, Excel, JSON |
| GSTR-1 | Outward supplies report for filing | JSON (portal format) |
| GSTR-3B | Summary return for filing | PDF, JSON |
| Fixed Asset Register | Asset list with cost, depreciation, net book value | PDF, Excel |
| Depreciation Schedule | Annual depreciation per asset | PDF, Excel |
| Tally Export Log | History of Tally export sessions | PDF |

---

## 13. Development Phases & Priority

| Phase | FRs | Priority | Estimated Effort |
|---|---|---|---|
| Phase 1 — COA & JE Foundation | FR-FAC-001, FR-FAC-002, FR-FAC-003 | Critical | 4 weeks |
| Phase 2 — Bank & Cash | FR-FAC-006, FR-FAC-007, FR-FAC-008 | Critical | 3 weeks |
| Phase 3 — AR & AP | FR-FAC-004, FR-FAC-005 | High | 3 weeks |
| Phase 4 — Budget Management | FR-FAC-009 | High | 2 weeks |
| Phase 5 — Reports & Dashboard | FR-FAC-011, FR-FAC-012 | Critical | 3 weeks |
| Phase 6 — GST Compliance | FR-FAC-010 | High | 3 weeks |
| Phase 7 — Fixed Assets | FR-FAC-013 | Medium | 2 weeks |
| Phase 8 — Integrations | FR-FAC-014 | Medium | 3 weeks |
| **Total** | | | **~23 weeks** |

---

## 14. Open Questions & Decisions Required

| ID | Question | Stakeholder | Impact |
|---|---|---|---|
| OQ-FAC-001 | Does FAC own `acc_account_groups` and `acc_ledgers` CRUD, or does the Accounting base module own them? If both have UI, there will be duplication. Recommendation: FAC owns the management UI; Accounting module owns the data model | Product Owner | Architecture — single COA management point |
| OQ-FAC-002 | E-invoicing integration: use third-party IRP service provider (ASP) or direct NIC API? Direct NIC requires digital certificate. Recommendation: integrate via ASP (e.g., Tally, ClearTax API) for Phase 1 | Compliance | E-invoice implementation complexity |
| OQ-FAC-003 | Vendor module handles vendor AP operations. Should FAC have its own purchase invoice entry or delegate entirely to Vendor module with accounting sync? Recommendation: Vendor module owns operational flow, FAC shows accounting view only | Product Owner | Module boundary clarity |
| OQ-FAC-004 | QuickBooks/Zoho sync: real-time push on JE approval, or scheduled batch export? Recommendation: scheduled (daily) batch for Phase 1, real-time webhook for Phase 2 | Product Owner | Integration complexity |
| OQ-FAC-005 | Should budget tracking include capital expenditure (asset purchases) separately from operational expenditure? | Finance Officer | Budget model complexity |
| OQ-FAC-006 | IRP credentials stored per tenant — encryption key management strategy (Laravel `encrypt()` uses `APP_KEY`). Is this sufficient for compliance or does FAC need a dedicated key vault? | Security Team | Credential security |
| OQ-FAC-007 | Fiscal year: April-March (standard India) or configurable? Some aided schools follow January-December. Recommendation: configurable per tenant, default April-March | School Admin | Fiscal year table design |

---

## 15. Appendix — RBS Traceability Matrix

| RBS Feature | RBS Sub-tasks | FR Coverage |
|---|---|---|
| F.K1.1 — Account Groups | ST.K1.1.1.1, ST.K1.1.1.2, ST.K1.1.2.1, ST.K1.1.2.2 | FR-FAC-001 |
| F.K1.2 — Ledger Management | ST.K1.2.1.1–ST.K1.2.2.2 | FR-FAC-001 |
| F.K2.1 — Ledger Opening | ST.K2.1.1.1, ST.K2.1.1.2 | FR-FAC-002 |
| F.K2.2 — Student & Vendor Opening | ST.K2.2.1.1, ST.K2.2.1.2 | FR-FAC-002 |
| F.K3.1 — Manual Journals | ST.K3.1.1.1–ST.K3.1.2.2 | FR-FAC-003 |
| F.K3.2 — Recurring Journals | ST.K3.2.1.1, ST.K3.2.1.2 | FR-FAC-003 |
| F.K4.1 — Student Receivables | ST.K4.1.1.1–ST.K4.1.2.2 | FR-FAC-004 (non-fee income AR) |
| F.K4.2 — Aging & Collections | ST.K4.2.1.1–ST.K4.2.2.2 | FR-FAC-004 |
| F.K5.1 — Vendor Bills | ST.K5.1.1.1, ST.K5.1.1.2 | FR-FAC-005 |
| F.K5.2 — Vendor Payments | ST.K5.2.1.1, ST.K5.2.1.2 | FR-FAC-005 |
| F.K6.1/K6.2 — Vendor Management | (Vendor module scope — FAC accounting layer only) | FR-FAC-005 |
| F.K7.1 — Purchase Orders | ST.K7.1.1.1, ST.K7.1.1.2 | FR-FAC-009 (commitment tracking) |
| F.K7.2 — Expense Claims | ST.K7.2.1.1, ST.K7.2.1.2 | FR-FAC-003 (via acc_expense_claims) |
| F.K8.1 — Bank Reconciliation | ST.K8.1.1.1–ST.K8.1.2.2 | FR-FAC-007 |
| F.K8.2 — Cash Register | ST.K8.2.1.1, ST.K8.2.1.2 | FR-FAC-008 |
| F.K9.1 — Asset Register | ST.K9.1.1.1, ST.K9.1.1.2 | FR-FAC-013 |
| F.K9.2 — Depreciation Engine | ST.K9.2.1.1, ST.K9.2.1.2 | FR-FAC-013 |
| F.K10.1 — Standard Reports | ST.K10.1.1.1–ST.K10.1.1.3 | FR-FAC-011 |
| F.K10.2 — Dashboards | ST.K10.2.1.1, ST.K10.2.1.2 | FR-FAC-012 |
| F.K11.1 — Tally Integration | ST.K11.1.1.1, ST.K11.1.1.2 | FR-FAC-014 |
| F.K11.2 — QuickBooks/Zoho | ST.K11.2.1.1, ST.K11.2.1.2 | FR-FAC-014 |
| F.K12.1 — Budget Creation | ST.K12.1.1.1–ST.K12.1.2.2 | FR-FAC-009 |
| F.K12.2 — Budget Reports | ST.K12.2.1.1, ST.K12.2.1.2 | FR-FAC-009, FR-FAC-012 |
| F.K13.1 — GST Configuration | ST.K13.1.1.1–ST.K13.1.2.2 | FR-FAC-010 |
| F.K13.2 — GST Return Preparation | ST.K13.2.1.1, ST.K13.2.1.2 | FR-FAC-010 |
| Bank Account Master (derived) | — | FR-FAC-006 |
| Non-Fee Income (derived from K4) | — | FR-FAC-004 |
