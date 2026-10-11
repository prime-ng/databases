# Prime-AI Accounting Module — Process Flow & Screen Design

**Document ID:** ACC-PFD-V1  
**Version:** 1.0  
**Governed by:** `Accounting_BRD_v2.md` & `Solution_Design_v2.md`  
**Realised by:** `Accounting_DDL_v4.8.sql` & `Dictionary_DDL_v4.8.md`  
**Aligned with:** `ScreenDesign_v2.1.md`  
**Status:** Approved UI/UX & Process Specification Document  
**Date:** 2026-09-16  

---

## 0. Document Control & Overview

This document specifies **all 35 screens** required to complete the Prime-AI Accounting Module. It bridges the gap between physical database tables (`Accounting_DDL_v4.8.sql`), technical solution design (`Solution_Design_v2.md`), and front-end interface implementation (`ScreenDesign_v2.1.md`).

Every screen specification details:
1. **Screen Identifier & Title**
2. **Purpose & Functional Objective**
3. **UI Layout, Components & Controls**
4. **Database Tables Covered** (Primary & Secondary Table Mappings)
5. **Business Rules, Constraints & Validation Logic**

---

## 1. Chart of Accounts & Master Management Screens

### SCR-01: Account Groups Tree & Master

- **Purpose & Objective:** Manage the multi-level hierarchical Chart of Accounts (COA) group structure (Assets, Liabilities, Equity, Income, Expenses) using a Materialized Path pattern (`path`, `depth`).
- **UI Layout & Components:**
  - **Left Panel:** Interactive tree view displaying group hierarchy with expand/collapse nodes, drag-and-drop re-parenting, and depth indicators.
  - **Right Panel (Detail/Form):** Group code, group name, nature dropdown (`Asset`, `Liability`, `Equity`, `Income`, `Expense`), parent group selector, and ordinal sequence.
  - **Action Controls:** "Add Sub-Group", "Edit Group", "Delete Group", "Rebuild Hierarchy Tree".
- **Database Tables Covered:**
  - `acc_account_groups` (Primary)
- **Business Rules & Validation Logic:**
  - `parent_id != id` (A group cannot be its own parent).
  - Parent group FK is `ON DELETE RESTRICT` (cannot delete a parent group containing child groups or active ledgers).
  - `group_nature` must inherit from its parent group.
  - Materialized `path` and `depth` must be auto-calculated upon insert/update.
  - System default groups (`is_system = 1`) cannot be deleted or renamed.

---

### SCR-02: Ledger Accounts Master

- **Purpose & Objective:** Create, edit, and configure individual general ledger accounts under specific account groups, establishing party linkages and tax settings.
- **UI Layout & Components:**
  - **Header Bar:** Filter by Account Group, Nature, Active Status, Search by Code/Name.
  - **Main Data Grid:** Ledger Code, Name, Account Group, Nature, Opening Balance, Party Type (`Student`, `Vendor`, `Employee`, `Parent`, etc.), Bank Account Flag, Reconciliation Flag, Active Status.
  - **Modal / Slide-Over Form:** Ledger Code, Name, Group FK, Party Association details, GST/TDS defaults, Currency selector.
- **Database Tables Covered:**
  - `acc_ledgers` (Primary)
  - `acc_account_groups` (Secondary)
  - `acc_ledger_mappings` (Secondary)
- **Business Rules & Validation Logic:**
  - **Rule R-05:** `acc_ledgers` contains **no stored closing balance column**. Balances are derived live or queried from `acc_ledger_period_balances`.
  - Unique constraint on `code` (`uq_acc_ledger_code`).
  - Deleting a ledger with posted entries is strictly prohibited (`ON DELETE RESTRICT`).
  - Ledgers tied to active event configurations (`acc_event_voucher_configs`) cannot be deactivated without re-mapping.

---

### SCR-03: Cost Centers & Cost Categories Master

- **Purpose & Objective:** Configure orthogonal cost centers (departments, projects, events) and cost categories for dimensional financial reporting.
- **UI Layout & Components:**
  - **Category Tab:** Cost Category Name, Description, Ordinal, Active Toggle.
  - **Cost Center Tab:** Category Dropdown, Cost Center Code, Name, Parent Cost Center (for sub-cost centers), Active Status.
  - **Allocation Rules Modal:** Default cost center assignment per department or ledger.
- **Database Tables Covered:**
  - `acc_cost_categories` (Primary)
  - `acc_cost_centers` (Primary)
- **Business Rules & Validation Logic:**
  - Cost Centers belong strictly to a valid Cost Category.
  - Unique key on `(category_id, code)`.
  - Cost centers cannot be deleted if associated with posted voucher lines (`acc_voucher_item_cost_centers`).

---

### SCR-04: Funds Master & Utilization Summary

- **Purpose & Objective:** Manage restricted and unrestricted funds (e.g. Building Fund, Scholarship Fund, Government Grant) and monitor live fund balances.
- **UI Layout & Components:**
  - **Fund Grid:** Fund Code, Fund Name, Category (`Restricted`, `Unrestricted`, `Endowment`), Sanctioned Amount, Opening Balance, Additions, Utilisation, Net Balance.
  - **Utilisation Summary Pill:** Real-time percentage of fund consumed.
  - **Fund Creation Form:** Code, Name, Category, Linked Asset/Bank Ledgers, Restriction Terms, Expiry Date.
- **Database Tables Covered:**
  - `acc_funds` (Primary)
  - `acc_fund_balances` (Secondary)
  - `acc_voucher_item_funds` (Secondary)
- **Business Rules & Validation Logic:**
  - **Fund Balance Formula:** $\text{Closing} = \text{Opening} + \text{Additions} - \text{Utilisation}$.
  - Over-utilization of restricted funds checks `fund.overspend_default_action` in `acc_settings` (`Block` or `Warn`).

---

### SCR-05: Campuses & Multi-Unit Setup

- **Purpose & Objective:** Define multi-campus/unit entities operating under a single tenant legal entity for campus-sliced reporting.
- **UI Layout & Components:**
  - **Campus Cards / Table:** Campus Code, Campus Name, Address, Contact Person, Tax Registration Number, Active Status.
  - **Campus Edit Modal:** General Info, Default Bank Account, Campus-specific Series Prefixes.
- **Database Tables Covered:**
  - `acc_campuses` (Primary)
- **Business Rules & Validation Logic:**
  - Unique code per campus (`uq_acc_campus_code`).
  - Campus deletion is blocked if vouchers or balance rows exist for that campus (`ON DELETE RESTRICT`).

---

### SCR-06: Currency & Tax Setup

- **Purpose & Objective:** Manage functional and foreign currencies, GST/Sales tax rates, and TDS statutory sections.
- **UI Layout & Components:**
  - **Currencies Tab:** Code (ISO 4217), Name, Symbol, Exchange Rate, Is Base Currency Toggle.
  - **Tax Rates Tab:** Tax Code, Tax Name, Rate (%), Component Breakdown (CGST, SGST, IGST), Payable Ledger, Receivable Ledger.
  - **TDS Sections Tab:** Section Code (e.g. 194C, 194J), Description, Threshold Limit, Rate (%), Payable Ledger.
- **Database Tables Covered:**
  - `acc_currencies` (Primary)
  - `acc_tax_rates` (Primary)
  - `acc_tds_sections` (Primary)
- **Business Rules & Validation Logic:**
  - Base currency exchange rate is fixed at `1.00000000`.
  - Effective date ranges (`effective_from`, `effective_to`) prevent rewriting historical tax rates.

---

## 2. Voucher Entry & Transaction Processing Screens

### SCR-07: Voucher Types & Numbering Series Configurator

- **Purpose & Objective:** Define accounting voucher types (Payment, Receipt, Journal, Contra, Sales, Purchase, etc.) and configure gapless auto-numbering sequences per financial year/period.
- **UI Layout & Components:**
  - **Voucher Types Table:** Code, Name, Nature (`Payment`, `Receipt`, `Journal`, `Contra`, `Sales`, `Purchase`), Default Series Prefix, Requires Approval Toggle, Active Status.
  - **Numbering Sequence Configurator:** Financial Year, Campus, Period Marker, Prefix, Suffix, Current Number, Padding Width, Restart Policy (`Financial_Year`, `Monthly`, `Never`).
- **Database Tables Covered:**
  - `acc_voucher_types` (Primary)
  - `acc_voucher_number_sequences` (Primary)
- **Business Rules & Validation Logic:**
  - Number sequence lock uses `SELECT FOR UPDATE` on `acc_voucher_number_sequences` during posting to prevent duplicate numbers under high concurrency.
  - `period_marker` generated column ensures null-safe unique keys.
  - Continuous gap watching (`numbering.gap_watch_enabled`) raises assertions if numbers jump.

---

### SCR-08: Universal Voucher Entry Screen

- **Purpose & Objective:** High-speed, keyboard-friendly universal grid for entering all voucher types (Payment, Receipt, Journal, Contra, Sales, Purchase, Memo) with line-level cost center, fund, and bill allocation sub-screens.
- **UI Layout & Components:**
  - **Header Controls:** Voucher Type Selector, Voucher Date, Ref No, Currency, Campus, Narration.
  - **Line Item Grid:** Line #, Dr/Cr Toggle, Ledger Account (Searchable dropdown with live balance pill), Debit Amount, Credit Amount, Cost Center Popup Button, Fund Popup Button, Bill Allocation Popup Button, Line Narration.
  - **Sub-Modals:**
    - *Cost Center Allocation Modal:* Category, Cost Center, Amount split.
    - *Fund Allocation Modal:* Fund Selector, Amount split.
    - *Bill Allocation Modal:* Bill Ref Selector (`Against_Ref`, `New_Ref`, `Advance`, `On_Account`), Amount.
  - **Footer Summary Bar:** Total Debit, Total Credit, Difference Indicator (Must be `0.00`), Save Draft Button, Submit / Post Button.
- **Database Tables Covered:**
  - `acc_vouchers` (Primary)
  - `acc_voucher_items` (Primary)
  - `acc_voucher_item_cost_centers` (Secondary)
  - `acc_voucher_item_funds` (Secondary)
  - `acc_voucher_attachments` (Secondary)
  - `acc_bill_references` & `acc_bill_allocations_jnt` (Secondary)
- **Business Rules & Validation Logic:**
  - **Double-Entry Constraint:** $\sum \text{Debit} = \sum \text{Credit}$ (Variance $\le \text{posting.rounding\_tolerance}$).
  - **Period Lock:** Entry blocked if date falls in a `Hard_Closed` period.
  - **Immutable Posted Records:** Once posted (`status = 'Posted'`), zero `UPDATE` or `DELETE` allowed. Edits require reversing vouchers.
  - **Cash Balance Guard:** Aborts if cash ledger balance goes negative and `posting.negative_cash_action = 'Block'`.

---

### SCR-09: Voucher Approval & Authorization Cockpit

- **Purpose & Objective:** Managerial dashboard for reviewing, approving, or rejecting submitted vouchers exceeding authorization thresholds.
- **UI Layout & Components:**
  - **Filter Bar:** Status (`Submitted`, `Approved`, `Rejected`), Voucher Type, Date Range, Minimum Amount.
  - **Approval Table:** Voucher No, Type, Date, Prepared By, Total Amount, Primary Ledgers, Action Buttons ("Approve", "Reject", "View Full Voucher").
  - **Rejection Reason Modal:** Mandated text box for explaining rejection.
- **Database Tables Covered:**
  - `acc_vouchers` (Primary)
  - `acc_voucher_approvals` (Primary)
- **Business Rules & Validation Logic:**
  - **Four-Eyes Principle (`approval.forbid_self = 1`):** A user CANNOT approve a voucher they prepared/submitted.
  - Approving a voucher triggers `PostingService` to assign the final display number and execute posting.

---

### SCR-10: Opening Balances Management

- **Purpose & Objective:** Key in or review initial opening ledger balances and party-wise opening bill references at system go-live or year-end carry forward.
- **UI Layout & Components:**
  - **Filter Bar:** Financial Year, Account Group, Ledger Type.
  - **Opening Balance Grid:** Ledger Code, Ledger Name, Opening Debit, Opening Credit, Opening Bill Breakdown Link (`acc_bill_references` where `bill_type = 'Opening'`).
  - **Footer Indicator:** Total Opening Dr vs Total Opening Cr, Difference (Transferred to Opening Balance Difference ledger if unbalanced).
- **Database Tables Covered:**
  - `acc_opening_balances` (Primary)
  - `acc_bill_references` (Secondary)
- **Business Rules & Validation Logic:**
  - Distinction between `Migration` (source_closing_balance_id is NULL) and `Carry_Forward` (linked to prior year closing balance row).
  - Finalizing opening balances creates a balanced system opening voucher (`is_opening = 1`).

---

## 3. Bill-Wise Accounting & Party Ledger Screens

### SCR-11: Bill Reference & Outstanding Allocation Cockpit

- **Purpose & Objective:** Track individual receivables/payables (Student Fee Demands, Vendor Bills) and allocate payment/receipt vouchers against open bill references.
- **UI Layout & Components:**
  - **Party Filter Bar:** Party Type (`Student`, `Vendor`, `Employee`), Ledger Account, Status (`Open`, `Partial`, `Settled`, `Disputed`), Ageing Bucket.
  - **Bill References Grid:** Bill Ref No, Ref Date, Due Date, Original Amount, Allocated Amount, Written-Off Amount, Net Outstanding, Days Overdue, Age Bucket, Action ("Allocate Payment", "Mark Disputed", "Write Off").
  - **Allocation Detail Sub-Grid:** Allocation Date, Payment Voucher No, Amount Allocated.
- **Database Tables Covered:**
  - `acc_bill_references` (Primary)
  - `acc_bill_allocations_jnt` (Primary)
  - `acc_bill_reference_balances` (Secondary Cache)
- **Business Rules & Validation Logic:**
  - $\text{Outstanding} = \text{Original} - \sum \text{Allocations} - \text{Written Off}$.
  - Allocation amount cannot exceed current outstanding amount.
  - Disputed bills (`is_disputed = 1`) remain visible in ageing but are excluded from automatic reminder routines.

---

### SCR-12: Credit Limit & Exposure Management

- **Purpose & Objective:** Monitor party credit limits, evaluate current financial exposure, and review/override credit limit breaches during voucher entry.
- **UI Layout & Components:**
  - **Exposure Dashboard Table:** Ledger Name, Party Type, Configured Credit Limit, Current Exposure (Open Bills), Attempted Voucher Amount, Excess Amount, Status (`Warned`, `Approved`, `Blocked`), Override Reason.
  - **Override Request Action Modal:** Authorize credit limit breach with supervisor sign-off and mandatory reason text.
- **Database Tables Covered:**
  - `acc_credit_limit_overrides` (Primary)
  - `acc_ledgers` (Secondary)
- **Business Rules & Validation Logic:**
  - `current_exposure` snapshotted at the exact moment of voucher attempt.
  - Mandatory supervisor authorization required to proceed when action is `Blocked`.

---

### SCR-13: Student Concession & Waiver Management

- **Purpose & Objective:** Record, approve, and track student fee concessions and scholarship waivers, ensuring explicit accounting entry rather than silent netting.
- **UI Layout & Components:**
  - **Concession Application Form:** Concession No, Student ID, Student Ledger, Financial Year, Category, Total Amount, Reason.
  - **Line Items Sub-Grid:** Fee Head Ledger, Original Demand Amount, Concession Amount, Net Receivable.
  - **Approval Bar:** Status (`Draft`, `Approved`, `Posted`, `Cancelled`), Approved By, Posting Journal Link.
- **Database Tables Covered:**
  - `acc_concessions` (Primary)
  - `acc_concession_items` (Primary)
  - `acc_vouchers` (Secondary)
- **Business Rules & Validation Logic:**
  - Concession creates a explicit Credit Note / Adjustment voucher (Debits Concession Expense Ledger, Credits Student Receivable Ledger). Silent netting is prohibited.

---

## 4. Banking & Reconciliation Screens

### SCR-14: Cheque Book & Leaf Management

- **Purpose & Objective:** Maintain physical cheque books, track individual leaf statuses (Available, Issued, Cleared, Stale, Stopped, Cancelled), and record cheque bounce charges.
- **UI Layout & Components:**
  - **Cheque Book Master Form:** Bank Ledger, Book Series/Name, Start Leaf No, End Leaf No, Total Leaves.
  - **Leaf Status Grid:** Leaf No, Status (`Available`, `Issued`, `Cleared`, `Bounced`, `Stopped`), Issue Date, Payee Name, Amount, Bounce Reason, Bounce Charge Voucher Link.
- **Database Tables Covered:**
  - `acc_cheque_books` (Primary)
  - `acc_cheque_leaves` (Primary)
  - `acc_cheque_transactions` (Primary)
- **Business Rules & Validation Logic:**
  - Unique constraint on `(bank_ledger_id, leaf_number)`.
  - Cheques older than `bank.cheque_stale_days` (default 90 days) are automatically flagged as `Stale`.
  - Bounced cheques require posting a reversal voucher and option to levy bounce charges.

---

### SCR-15: Bank Import Layout Configurator

- **Purpose & Objective:** Configure reusable machine-import parsing templates for bank statements (CSV, XLS, MT940, OFX) per bank account.
- **UI Layout & Components:**
  - **Layout Form:** Template Name, Bank Ledger, File Format, Header Row Index, Data Start/End Row Index, Date Format (`d/m/Y`, `Y-m-d`).
  - **Column Mapper Grid:** Map Date, Value Date, Description, Reference No, Debit Amount, Credit Amount, Balance to specific file column numbers.
- **Database Tables Covered:**
  - `acc_bank_import_configs` (Primary)
- **Business Rules & Validation Logic:**
  - Validates parser regex and date format strings before saving.
  - Supports both separate Dr/Cr columns and single amount column with Dr/Cr indicator.

---

### SCR-16: Bank Reconciliation Cockpit & Auto-Match Engine

- **Purpose & Objective:** Reconcile bank statement lines against internal bank ledger entries, executing automated confidence scoring and manual match confirmation.
- **UI Layout & Components:**
  - **Top Summary Card:** Bank Ledger, Statement Date, Book Balance, Unpresented Cheques, Uncredited Deposits, Other Adjustments, Computed Bank Balance, Statement Closing Balance, Difference Pill (MUST be `0.00` to complete).
  - **Split View:**
    - *Left Panel (Bank Statement Lines):* Date, Description, Ref #, Dr/Cr Amount, Match Status (`Unmatched`, `Proposed`, `Matched`, `Excluded`).
    - *Right Panel (Unreconciled Ledger Entries):* Date, Voucher No, Instrument No, Dr/Cr Amount.
  - **Action Controls:** "Run Auto-Match", "Confirm Proposed Match", "Manual Match Selected", "Exclude Line", "Post Adjustment Journal", "Final Sign-Off".
- **Database Tables Covered:**
  - `acc_bank_reconciliations` (Primary)
  - `acc_bank_statement_entries` (Primary)
  - `acc_bank_reconciliation_matches` (Primary)
- **Business Rules & Validation Logic:**
  - **Reconciliation Equation:** $\text{Bank Balance} = \text{Book Balance} + \text{Uncredited} - \text{Unpresented} + \text{Adjustments}$.
  - Machine import uses SHA-256 `row_hash` to prevent duplicate statement entry imports.
  - Final sign-off blocks changes unless reopened by an authorized user (`acc_bank_reconciliations.reopened_by`).

---

## 5. Fixed Asset Accounting Screens

### SCR-17: Asset Categories & Depreciation Policy Master

- **Purpose & Objective:** Define asset categories (Buildings, Machinery, Vehicles, Computers) and set depreciation methods (SLM, WDV) and rates.
- **UI Layout & Components:**
  - **Category Grid:** Category Code, Name, Depreciation Method (`SLM`, `WDV`, `None`), Annual Rate (%), Useful Life Years, Linked Asset Ledger, Accumulated Dep Ledger, Dep Expense Ledger.
  - **Edit Modal:** Form fields for category attributes and accounting ledger heads.
- **Database Tables Covered:**
  - `acc_asset_categories` (Primary)
- **Business Rules & Validation Logic:**
  - `depreciation_rate` constrained between `0.0000%` and `100.0000%`.
  - Requires all three ledger heads (Asset, Accum Dep, Dep Expense) for depreciation journal posting.

---

### SCR-18: Asset Register & Acquisition Screen

- **Purpose & Objective:** Register fixed assets, record purchase cost, salvage value, location, custodian, and put-to-use date.
- **UI Layout & Components:**
  - **Asset Register Table:** Asset Tag Code, Name, Category, Purchase Date, Put-to-Use Date, Purchase Cost, Salvage Value, Current WDV, Location, Custodian User, Status (`Active`, `Fully_Depreciated`, `Disposed`).
  - **Acquisition Entry Form:** General details, Purchase Voucher Link, Custodian assignment, Fund source.
- **Database Tables Covered:**
  - `acc_fixed_assets` (Primary)
  - `acc_asset_categories` (Secondary)
- **Business Rules & Validation Logic:**
  - Depreciation calculation starts strictly from `put_to_use_date`, not `purchase_date`.
  - Net Book Value = Purchase Cost - $\sum \text{Depreciation Entries}$.

---

### SCR-19: Asset Depreciation Run Execution

- **Purpose & Objective:** Periodically compute and post depreciation journals across all active fixed assets for a financial period.
- **UI Layout & Components:**
  - **Run Configuration Bar:** Financial Year, Period Selector, Depreciation Date, Computation Mode (`Preview`, `Post`).
  - **Depreciation Calculation Grid:** Asset Code, Name, Method, Rate Applied, Opening WDV, Days in Use (Pro-rata), Calculated Dep Amount, Closing WDV.
  - **Action Button:** "Generate & Post Depreciation Journal".
- **Database Tables Covered:**
  - `acc_depreciation_entries` (Primary)
  - `acc_vouchers` (Secondary)
- **Business Rules & Validation Logic:**
  - **Re-run Guard:** `UNIQUE(fixed_asset_id, period_id)` prevents posting duplicate depreciation for the same asset and period.
  - Applies SLM or WDV formula with exact pro-rata day count (`days_in_use`).

---

### SCR-20: Asset Disposal & Gain/Loss Management

- **Purpose & Objective:** Record fixed asset disposals (Sale, Scrap, Donation, Loss), calculate net book value, compute gain/loss, and post disposal journals.
- **UI Layout & Components:**
  - **Disposal Entry Form:** Asset Selector, Disposal Date, Disposal Type (`Sale`, `Scrap`, `Donation`, `Loss`), Buyer Ledger, Sale Proceeds, Disposal Costs.
  - **Gain/Loss Calculation Summary Card:** Cost at Disposal, Accumulated Depreciation to Date, Net Book Value (NBV), Net Proceeds, Calculated Gain / Loss Amount.
  - **Action Button:** "Approve & Post Disposal Journal".
- **Database Tables Covered:**
  - `acc_asset_disposals` (Primary)
  - `acc_fixed_assets` (Secondary)
- **Business Rules & Validation Logic:**
  - Asset status changes to `Disposed` upon posting. Asset row is NEVER deleted.
  - $\text{Gain/Loss} = \text{Proceeds} - \text{Disposal Costs} - \text{NBV}$. (Gain credited to Income; Loss debited to Expense).

---

## 6. Expense Claims & Reimbursements Screens

### SCR-21: Employee Expense Claim Submission

- **Purpose & Objective:** Portal for employees to submit out-of-pocket expense reimbursement claims with attached receipts.
- **UI Layout & Components:**
  - **Claim Header:** Claim No, Claim Date, Employee Selector/Pill, Purpose / Description, Advance Adjustment Link.
  - **Expense Lines Grid:** Expense Date, Reference/Receipt No, Ledger Head (e.g. Travel, Meals), Cost Center, Description, Amount, Tax Amount, Receipt Upload Button.
  - **Footer:** Total Claim Amount, Submit for Approval Button.
- **Database Tables Covered:**
  - `acc_expense_claims` (Primary)
  - `acc_expense_claim_lines` (Primary)
- **Business Rules & Validation Logic:**
  - Unique claim number generated upon draft creation.
  - Lines default to `line_status = 'Claimed'`. Receipts uploaded to `acc_media`.

---

### SCR-22: Expense Claim Approval & Disbursement Cockpit

- **Purpose & Objective:** Review employee expense claims, adjust/reduce line amounts, approve/reject claims, and disburse payment vouchers.
- **UI Layout & Components:**
  - **Claim Review Table:** Claim No, Employee, Date, Total Claimed, Total Approved, Status (`Submitted`, `Approved`, `Partially_Approved`, `Rejected`, `Paid`), Actions ("Review Lines", "Approve Claim", "Generate Payment").
  - **Line Audit Drawer:** Line Details, Receipt Viewer, Manager Approved Amount Input, Line Rejection Reason Input.
- **Database Tables Covered:**
  - `acc_expense_claims` (Primary)
  - `acc_expense_claim_lines` (Primary)
  - `acc_vouchers` (Secondary)
- **Business Rules & Validation Logic:**
  - Approved amount cannot exceed claimed line amount.
  - Generating payment creates a Payment Voucher debiting Employee Payable and crediting Bank/Cash.

---

## 7. Budgeting & Variance Screens

### SCR-23: Budget Definition & Revision Configurator

- **Purpose & Objective:** Define annual/periodical budgets per ledger and dimension slice, manage budget revisions and versions.
- **UI Layout & Components:**
  - **Budget Header:** Budget Name, Financial Year, Campus, Budget Type (`Original`, `Revised`, `Forecast`), Version, Supersedes Budget Selector, Breach Action (`None`, `Warn`, `Approve`, `Block`), Breach Tolerance %.
  - **Budget Lines Grid:** Account Group / Ledger, Period 1..12 Budget Amounts, Total Annual Budget.
- **Database Tables Covered:**
  - `acc_budgets` (Primary)
  - `acc_budget_lines` (Primary)
- **Business Rules & Validation Logic:**
  - Revisions create a new version (`supersedes_budget_id`) with mandatory `revision_reason`. Prior versions are preserved (`status = 'Superseded'`).
  - Unique key on `(budget_id, ledger_id, period_id, cc_marker, fund_marker, campus_marker)`.

---

### SCR-24: Budget Variance & Breach Monitoring Cockpit

- **Purpose & Objective:** Real-time dashboard monitoring budget vs actual expenditures, highlighting variances and budget breach alerts.
- **UI Layout & Components:**
  - **Filter Bar:** Financial Year, Period, Campus, Cost Center, Variance Filter (`Over Budget`, `Near Limit`, `Under Budget`).
  - **Variance Grid:** Ledger Name, Annual Budget, YTD Budget, YTD Actual, Variance Amount, Utilisation %, Status Pill (Green/Yellow/Red).
  - **Breach Log Panel:** Date, Voucher No, Ledger, Attempted Amount, Breach Action Taken (`Warned`, `Blocked`).
- **Database Tables Covered:**
  - `acc_budgets` (Primary)
  - `acc_budget_lines` (Primary)
  - `vw_budget_variance` (Secondary View)
- **Business Rules & Validation Logic:**
  - $\text{Variance} = \text{Actual} - \text{Budget}$. $\text{Utilisation \%} = (\text{Actual} / \text{Budget}) \times 100$.
  - Evaluated against `breach_tolerance_pct` during voucher entry.

---

## 8. Interest Computation Screens

### SCR-25: Interest Rules & Slabs Master

- **Purpose & Objective:** Configure automated interest rules for late fee demands or overdue vendor/loan balances, specifying day-count conventions and rate slabs.
- **UI Layout & Components:**
  - **Interest Rule Form:** Rule Code, Rule Name, Ledger / Party Type Target, Rate %, Basis (`Simple`, `Compound`), Compounding Frequency, Day Count Convention (`Actual_365`, `Actual_360`, `30_360`, `Actual_Actual`), Grace Days, Minimum Amount, Interest Income/Expense Ledger.
  - **Tiered Slabs Sub-Grid:** Overdue Days From, Overdue Days To, Rate %.
- **Database Tables Covered:**
  - `acc_interest_rules` (Primary)
  - `acc_interest_slabs` (Primary)
- **Business Rules & Validation Logic:**
  - Day count convention governs exact time fraction calculation ($t$).
  - Grace days ($D_{\text{grace}}$) delay interest accrual until overdue days exceed threshold.

---

### SCR-26: Interest Computation Proposal & Waiver Cockpit

- **Purpose & Objective:** Review background-calculated interest proposals, approve charges for posting, or record formal interest waivers.
- **UI Layout & Components:**
  - **Proposal Grid:** Computation ID, Party Name, Bill Ref No, Principal Overdue, Overdue Days, Rate Applied, Day Count Basis, Calculated Interest Amount, Status (`Proposed`, `Accepted`, `Waived`, `Posted`), Waive Reason.
  - **Bulk Action Bar:** "Approve Selected for Posting", "Waive Selected".
  - **Waiver Modal:** Text field for entering mandatory waiver justification.
- **Database Tables Covered:**
  - `acc_interest_computations` (Primary)
  - `acc_vouchers` (Secondary)
- **Business Rules & Validation Logic:**
  - Waived interest updates status to `Waived` with mandatory `waive_reason` for audit compliance. No voucher is posted.
  - Posting creates an Interest Journal debiting Party and crediting Interest Income.

---

## 9. Recurring Vouchers & Automation Screens

### SCR-27: Recurring Voucher Template Setup

- **Purpose & Objective:** Configure scheduled recurring transaction templates (e.g., monthly rent, recurring subscriptions, retainer fees).
- **UI Layout & Components:**
  - **Template Header:** Template Name, Code, Voucher Type, Frequency (`Daily`, `Weekly`, `Monthly`, `Quarterly`, `Yearly`, `Custom`), Month-End Policy (`Same_Day`, `Last_Day_Of_Month`), Start Date, End Date / Occurrence Limit, Auto-Post Toggle, Approval Required Toggle.
  - **Template Lines Grid:** Dr/Cr, Ledger Account, Amount, Cost Center, Fund, Line Narration.
- **Database Tables Covered:**
  - `acc_recurring_templates` (Primary)
  - `acc_recurring_template_lines` (Primary)
- **Business Rules & Validation Logic:**
  - Total line debits must equal total credits.
  - Auto-post flag (`auto_post = 1`) requires the user to possess `acc.recurring.autopost` permission at configuration time.

---

### SCR-28: Recurring Execution Log & Monitor

- **Purpose & Objective:** Monitor background execution history of recurring templates, review generated draft vouchers, and inspect execution failures.
- **UI Layout & Components:**
  - **Execution Log Table:** Run Date, Template Name, Scheduled Date, Occurrence No, Generated Voucher Link, Status (`Success`, `Draft_Created`, `Failed`, `Skipped`), Error Message.
  - **Action Button:** "Manually Trigger Template Run".
- **Database Tables Covered:**
  - `acc_recurring_transaction_log` (Primary)
  - `acc_recurring_templates` (Secondary)
- **Business Rules & Validation Logic:**
  - Scheduler recomputes `next_due_date` after each successful run.
  - Failed runs log full error trace in `acc_recurring_transaction_log` without breaking scheduler loop.

---

## 10. Cross-Module Event Integration Screens

### SCR-29: Module Events & Voucher Rules Configurator

- **Purpose & Objective:** Map domain events from external modules (Fees, Transport, Hostel, Payroll, Vendor, Library) to accounting voucher templates, establishing zero-direct-write event integration.
- **UI Layout & Components:**
  - **Module Events Registry Table:** Module Key (`FEE`, `TPT`, `HST`, `PAY`, `VND`, `LIB`), Event Code (e.g. `FEE_DEMAND_RAISED`), Event Name, Source Model, Active Toggle.
  - **Voucher Rule Mapping Form:** Event Selector, Generated Voucher Type, Auto-Post Flag, Description Template.
  - **Voucher Line Templates Sub-Grid:** Line #, Dr/Cr, Ledger Mapping Source (`Party_Ledger`, `Fixed_Ledger`, `Event_Payload_Ledger`), Amount Expression, Cost Center Mapping.
- **Database Tables Covered:**
  - `acc_module_events` (Primary)
  - `acc_event_voucher_configs` (Primary)
  - `acc_event_voucher_line_templates` (Primary)
  - `acc_ledger_mappings` (Secondary)
- **Business Rules & Validation Logic:**
  - Event payload handling is strictly idempotent (checked via unique event UUID in audit logs).
  - Unconfigured events emit integration exception alerts rather than failing silently.

---

## 11. Period Close & Financial Year Screens

### SCR-30: Month-End Close Cockpit & Checklist

- **Purpose & Objective:** Interactive operational cockpit for executing month-end period closure, validating blocking checklists, and freezing period balances.
- **UI Layout & Components:**
  - **Period Selector Header:** Financial Year, Period Name, Start Date, End Date, Current Status (`Open`, `Soft_Closed`, `Hard_Closed`).
  - **Blocking Checklist Table:** Item Name, Required/Warning Flag, Status (`Passed`, `Failed`, `Pending`), Action Button ("Run Check", "View Blockers").
    - *Checklist Items:* Fee Rec = 0, BRS Complete, Depreciation Posted, Unapproved Vouchers = 0, Exceptions Cleared.
  - **Action Controls:** "Soft-Close Period", "Freeze Balances & Hard-Close Period", "Reopen Period".
- **Database Tables Covered:**
  - `acc_accounting_periods` (Primary)
  - `acc_period_close_checklist` (Primary)
  - `acc_period_closing_balances` (Secondary Snapshot)
- **Business Rules & Validation Logic:**
  - **Hard Close Execution:** Writes immutable snapshot to `acc_period_closing_balances`.
  - Cannot hard-close a period if any `Blocking` checklist item is in `Failed` state (when `period.close_requires_all_blocking = 1`).
  - Reopening a hard-closed period requires `acc.period.reopen` authorization and creates a new audit trail entry.

---

### SCR-31: Financial Year-End Closure & Carry Forward

- **Purpose & Objective:** Execute annual financial year-end close, generate profit/loss transfer journals, and carry forward closing balances into the new year.
- **UI Layout & Components:**
  - **Year-End Wizard:**
    - *Step 1:* Verify all 12 periods are Hard-Closed.
    - *Step 2:* Review Year-End Adjustments & Depreciation.
    - *Step 3:* Compute Net Surplus/Deficit & Select Corpus/Accumulated Fund Equity Ledger.
    - *Step 4:* Preview New Year Opening Balances (Assets/Liabilities carried forward, Income/Expense reset to 0).
  - **Execute Action Button:** "Finalize Year-End Close & Initialize New FY".
- **Database Tables Covered:**
  - `acc_financial_years` (Primary)
  - `acc_opening_balances` (Secondary)
  - `acc_vouchers` (Secondary)
- **Business Rules & Validation Logic:**
  - Income and Expense ledger balances are transferred to Surplus/Deficit Equity ledger via an automated closing journal.
  - Generates `Carry_Forward` rows in `acc_opening_balances` linking `source_closing_balance_id` to the prior year period 12 closing balance.

---

## 12. Audit, Exceptions & System Settings Screens

### SCR-32: Immutable Audit Trail Inspector

- **Purpose & Objective:** Read-only compliance inspector to view, search, and audit every database write and transaction in the accounting module.
- **UI Layout & Components:**
  - **Filter Bar:** Date Range, Actor Type (`User`, `System`), User ID, Action (`Insert`, `Post`, `Approve`, `Void`), Entity Type, Search Text.
  - **Audit Log Table:** Log ID, Timestamp, Actor Name, IP Address, Entity Type, Entity ID, Action, Changed Fields / JSON Payload.
- **Database Tables Covered:**
  - `acc_audit_logs` (Primary)
- **Business Rules & Validation Logic:**
  - **Append-Only Table:** Application DB user holds ONLY `INSERT` and `SELECT` grants on `acc_audit_logs`. Zero `UPDATE` or `DELETE` path exists.

---

### SCR-33: Accounting Exception Management Cockpit

- **Purpose & Objective:** Operational dashboard identifying accounting anomalies (negative cash, aged suspense, unposted drafts, unreconciled items).
- **UI Layout & Components:**
  - **Exception Summary Cards:** Total Open Exceptions, Critical Count, Warning Count.
  - **Exception List Grid:** Exception Code, Rule Name, Severity (`Critical`, `Warning`), Record ID / Reference, Exception Message, Detected At, Status (`Open`, `In_Progress`, `Resolved`, `Ignored`), Resolution Remarks.
- **Database Tables Covered:**
  - `acc_exception_rules` (Primary)
  - `acc_exceptions` (Primary)
- **Business Rules & Validation Logic:**
  - Rule evaluation runs automatically via scheduled background worker.
  - Resolving an exception requires entering mandatory `resolution_notes`.

---

### SCR-34: Continuous Assertion Health Center

- **Purpose & Objective:** System health monitoring screen displaying hourly continuous assertion check results ($\sum \text{Dr} = \sum \text{Cr}$, cache vs voucher line agreement, gapless numbering).
- **UI Layout & Components:**
  - **Assertion Status Dashboard:** Assertion Code, Rule Name, Evaluation Frequency, Last Run Time, Status (`PASSED`, `FAILED`), Violation Count.
  - **Violation Details Drawer:** Specific failing record IDs, expected vs actual values, error trace.
- **Database Tables Covered:**
  - `acc_assertion_results` (Primary)
- **Business Rules & Validation Logic:**
  - An assertion failure sets `is_stale = 1` on affected balance cache tables and triggers immediate administrator alert.

---

### SCR-35: System Settings & Policy Administration

- **Purpose & Objective:** Configure global accounting module settings (rounding tolerance, backdate permissions, cash policies, ageing buckets, approval thresholds).
- **UI Layout & Components:**
  - **Settings Group Navigation:** Posting, Numbering, Period, Bill_Wise, Bank, Tax, Fund, Budget, Approval, Reporting, Integration, Security.
  - **Typed Setting Controls Grid:** Setting Key, Description, Value Field (String, Integer, Decimal, Boolean, Date, JSON editor), Default Value, School Editable Indicator, Four-Eyes Required Pill.
- **Database Tables Covered:**
  - `acc_settings` (Primary)
- **Business Rules & Validation Logic:**
  - Strongly-typed storage (`value_string`, `value_integer`, `value_decimal`, `value_boolean`, `value_json`).
  - Modifications to settings with `requires_four_eyes = 1` require a second user confirmation before taking effect.

---

## 13. Complete Database Table Coverage Index

This index confirms that **100% of all 50+ tables** in `Accounting_DDL_v4.8.sql` are mapped to their primary handling screens:

| Table Name | Primary Screen(s) | Table Name | Primary Screen(s) |
|---|---|---|---|
| `acc_account_groups` | **SCR-01** | `acc_cheque_books` | **SCR-14** |
| `acc_ledgers` | **SCR-02** | `acc_cheque_leaves` | **SCR-14** |
| `acc_ledger_mappings` | **SCR-02, SCR-29** | `acc_cheque_transactions` | **SCR-14** |
| `acc_cost_categories` | **SCR-03** | `acc_bank_import_configs` | **SCR-15** |
| `acc_cost_centers` | **SCR-03** | `acc_bank_reconciliations` | **SCR-16** |
| `acc_funds` | **SCR-04** | `acc_bank_statement_entries` | **SCR-16** |
| `acc_fund_balances` | **SCR-04** | `acc_bank_reconciliation_matches`| **SCR-16** |
| `acc_campuses` | **SCR-05** | `acc_asset_categories` | **SCR-17** |
| `acc_currencies` | **SCR-06** | `acc_fixed_assets` | **SCR-18** |
| `acc_tax_rates` | **SCR-06** | `acc_depreciation_entries` | **SCR-19** |
| `acc_tds_sections` | **SCR-06** | `acc_asset_disposals` | **SCR-20** |
| `acc_voucher_types` | **SCR-07** | `acc_expense_claims` | **SCR-21, SCR-22** |
| `acc_voucher_number_sequences` | **SCR-07** | `acc_expense_claim_lines` | **SCR-21, SCR-22** |
| `acc_vouchers` | **SCR-08, SCR-09** | `acc_budgets` | **SCR-23, SCR-24** |
| `acc_voucher_items` | **SCR-08** | `acc_budget_lines` | **SCR-23, SCR-24** |
| `acc_voucher_item_cost_centers` | **SCR-08** | `acc_interest_rules` | **SCR-25** |
| `acc_voucher_item_funds` | **SCR-08** | `acc_interest_slabs` | **SCR-25** |
| `acc_voucher_attachments` | **SCR-08** | `acc_interest_computations` | **SCR-26** |
| `acc_voucher_approvals` | **SCR-09** | `acc_recurring_templates` | **SCR-27, SCR-28** |
| `acc_opening_balances` | **SCR-10, SCR-31** | `acc_recurring_template_lines` | **SCR-27** |
| `acc_ledger_period_balances` | **SCR-02, SCR-30** | `acc_recurring_transaction_log` | **SCR-28** |
| `acc_bill_references` | **SCR-11** | `acc_module_events` | **SCR-29** |
| `acc_bill_allocations_jnt` | **SCR-11** | `acc_event_voucher_configs` | **SCR-29** |
| `acc_bill_reference_balances` | **SCR-11** | `acc_event_voucher_line_templates`| **SCR-29** |
| `acc_credit_limit_overrides` | **SCR-12** | `acc_accounting_periods` | **SCR-30** |
| `acc_concessions` | **SCR-13** | `acc_period_close_checklist` | **SCR-30** |
| `acc_concession_items` | **SCR-13** | `acc_period_closing_balances` | **SCR-30** |
| `acc_financial_years` | **SCR-31** | `acc_audit_logs` | **SCR-32** |
| `acc_exception_rules` | **SCR-33** | `acc_exceptions` | **SCR-33** |
| `acc_assertions` | **SCR-34** | `acc_settings` | **SCR-35** |

---
*End of Process Flow & Screen Design Document.*
