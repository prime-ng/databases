# Accounting (ACC) — Complete FRD & Analysis Pack | 2026-06-29
**Module:** Accounting | **Code:** ACC (legacy code: FAC) | **Prefix:** `acc_` | **Type:** Tenant | **Database:** `tenant_db`
**Author:** Business Analyst (AI_Brain) | **Status:** v1.0 — single source of truth for downstream technical audit
**Sources read:** V2 requirement (`FAC_FinanceAccounting_Requirement.md`, 2026-03-26) · DDL (`Accounting_DDL_v3.sql`, 28 tables) · Live code (`Modules/Accounting/` — 21 controllers, 25 models, 7 services, 141 views, 0 migrations) · V1 screen-spec folder (`Accounting_v1/`, 12 screens) · Module Knowledge file (`ACC_Accounting.md`)

> **ID contract:** the `REQ-/BR-/RPT-/ENH-/NFR-/RISK-` IDs assigned here are **stable**. The DB Architect, Technical Auditor, Status Analyzer, and Testing Architect MUST reuse these IDs and never renumber them.

---

## Section 0 — Index / Table of Contents

| # | Section | Register |
|---|---------|----------|
| 1 | Module Overview (Purpose, Value, Scope In/Out, Terminology) | Business |
| 2 | User Roles & Access (Actors, Role–Feature Matrix) | Business |
| 3 | Functional Requirements (REQ-ACC-001…022) | Business |
| 4 | Business Rules Register (BR-ACC-001…040) | Business |
| 5 | Data Requirements (business entities + privacy) | Business |
| 6 | Workflows (5 process flows + exception paths) | Business |
| 7 | Reporting & Analytics (RPT-ACC-001…014 + KPIs) | Business |
| 8 | Future Enhancement Log (ENH-ACC-001…006) | Business |
| 9 | Non-Functional Requirements (NFR-ACC-001…012) | Business |
| 10 | Gap Analysis Readiness Index (coverage flags + totals) | Mixed |
| 11 | Requirements Traceability Matrix (RTM) | Mixed |
| 12 | Requirement Conditions Catalog (keyed to BR-) | Business |
| 13 | Validation & Edge-Case Catalog | Business |
| 14 | State Machine (FSM) Catalog | Business |
| 15 | Data Dictionary — Business View | Business |
| 16 | Cross-Module Dependency Map | Mixed |
| 17 | Risk Register (RISK-ACC-001…008) | Business |
| 18 | Prioritization (MoSCoW) & Effort / Sprint Tasks | Mixed |
| 19 | User Stories + Acceptance Criteria (Gherkin) | Business |
| 20 | Technical Data Dictionary (table→column→model) | **Technical** |

---

## Section 1 — Module Overview

### 1.1 Purpose
The Accounting module is the school's complete book-keeping engine. It records every rupee that enters or leaves the school using a disciplined double-entry method — each financial transaction is captured as a balanced voucher (what was debited must equal what was credited). It maintains the school's chart of accounts, its bank and cash positions, its budgets, its fixed assets, and the statutory financial statements that management, trustees, and external auditors rely on. It also receives financial events from other school modules (fee collection, payroll, vendor purchases, transport fees) and turns them automatically into accounting entries, so the books stay current without manual re-keying.

### 1.2 Business Value
- **One trustworthy ledger:** every transaction — manual or system-generated — lands in a single, balanced set of books, eliminating reconciliation between parallel spreadsheets.
- **Audit-ready:** locked financial years, immutable posted entries, and a full audit trail make external audit and government inspection straightforward.
- **Automation:** fee receipts, salary journals, and vendor payments post themselves, freeing the accountant from repetitive data entry.
- **Statutory comfort:** Tally-compatible export lets the school's chartered accountant continue working in Tally; GST/TDS readiness keeps the school compliant.
- **Control:** budgets, cost-centre tracking, and over-spend alerts give management visibility into where money goes.

### 1.3 Scope

**In scope**
- Chart of Accounts: account groups (hierarchical) and ledger accounts, with opening balances.
- Financial year setup, locking, and unlocking.
- Voucher entry across eight transaction types, with a Draft → Posted → Locked lifecycle, approval, cancellation, reversal, duplication, and printing.
- Recurring voucher templates.
- Cost centres and annual budgets, with budget-vs-actual variance and over-budget alerts.
- Bank reconciliation: statement import, auto-matching, manual matching, and completion control.
- Fixed-asset register, asset categories, and depreciation (Straight-Line and Written-Down-Value).
- Staff expense claims with a submit → approve/reject → pay workflow.
- Tax-rate master (GST/TDS rate definitions).
- Cross-module ledger mappings and the generic cross-module event engine that auto-creates vouchers.
- Tally-compatible export of ledgers and vouchers, with an export log.
- Financial reports: Trial Balance, Profit & Loss, Balance Sheet, Day Book, Cash Book, Bank Book, Ledger Statement, Outstanding Receivables/Payables, Budget Variance, and a finance dashboard.
- Registry/configuration tables: status master, voucher source-module registry, and voucher category registry.

**Out of scope (this release)**
- Full GST return filing and e-invoicing (GSTR-1/3B, IRN/QR) — rate master exists, but the GST transaction registry table is not yet in the schema → see ENH-ACC-001.
- TDS deduction, remittance, and statutory forms (Form 26Q, Form 16) — no schema or screens yet → see ENH-ACC-002.
- Automated year-end closing wizard (P&L carry-forward, opening-balance roll-over, close audit trail) — manual lock/unlock exists, but the closing engine and audit table do not → see ENH-ACC-003.
- Payroll computation itself (owned by the HR/Payroll module; Accounting only records the resulting journal).
- Fee assessment and collection logic (owned by StudentFee; Accounting only records the receipt).
- Cross-tenant / consolidated multi-school accounting — each school's books are fully isolated (database-per-tenant).
- Foreign-currency / multi-currency accounting.

### 1.4 Terminology (Glossary)
| Term | Meaning (business) |
|------|--------------------|
| Voucher | A single recorded financial transaction made of two or more balanced lines. |
| Voucher Line (Item) | One debit or one credit within a voucher, posted against a ledger. |
| Debit / Credit | The two sides of every entry; total debits must equal total credits. |
| Ledger Account | An individual account (e.g., "HDFC Bank", "Tuition Fee Income", "Salaries"). |
| Account Group | A folder that groups ledgers under one of five natures (Asset, Liability, Equity, Income, Expense). |
| Financial Year | The school's accounting year, 1-April to 31-March. |
| Locked Year | A closed financial year whose entries can no longer be added or edited. |
| Chart of Accounts (COA) | The full hierarchy of account groups and ledgers. |
| Cost Centre | A department, wing, or activity to which spending is tagged for budgeting. |
| Budget | A planned spending limit for a cost-centre + ledger in a financial year. |
| Bank Reconciliation | Matching the school's recorded bank entries against the bank's own statement. |
| Depreciation | The yearly reduction in a fixed asset's book value. |
| Expense Claim | A staff request for reimbursement of money spent on the school's behalf. |
| Recurring Template | A saved voucher pattern that the system repeats on a schedule. |
| Cross-Module Event | A financial action in another module (fee paid, salary run) that triggers an automatic voucher here. |
| Voucher Status Master | The configurable list of statuses (Draft, Posted, etc.) the school can extend without code changes. |
| Reversal Voucher | An equal-and-opposite voucher used to cancel the effect of a posted voucher. |
| Trial Balance | A report listing every ledger's debit/credit balance; totals must match. |

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|-------|-------------|
| Finance Officer / Bursar | Day-to-day operator: creates and posts vouchers, runs bank reconciliation, approves expense claims, reverses locked-period entries. |
| School Accountant | Configures the chart of accounts, voucher types, tax rates, ledger mappings; runs depreciation; exports to Tally; locks the financial year. |
| Principal / Management | Approves budgets and high-value expense claims; views dashboards and reports. |
| Department Head | Views own cost-centre budgets and the dashboard for their area. |
| Staff Member | Submits and edits their own expense claims. |
| External Auditor | Read-only access to financial reports; no create/edit. |
| System / Scheduler | Background actor that posts recurring vouchers, runs monthly depreciation, and checks budget breaches (enhancement). |
| Cross-Module Source | Other modules (StudentFee, Payroll, Inventory, Transport) that send financial events service-to-service. |

> **Note on configurability:** roles map to permissions, and the school may extend statuses and categories (status master, voucher category) without developer involvement.

### 2.2 Role–Feature Matrix
| Feature | Finance Officer | Accountant | Principal | Dept Head | Staff | Auditor |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| View finance dashboard | Y | Y | Y | Y (own CC) | — | Y |
| Manage chart of accounts / ledgers | — | Y | — | — | — | — |
| Create / edit vouchers | Y | Y | — | — | — | — |
| Post / approve vouchers | Y | Y | — | — | — | — |
| Cancel posted vouchers | Y | Y | — | — | — | — |
| Reverse locked-period voucher | Y | — | — | — | — | — |
| Lock / unlock financial year | — | Y | — | — | — | — |
| Bank reconciliation | Y | Y | — | — | — | — |
| Create budget plan | Y | Y | — | — | — | — |
| Approve budget plan | — | — | Y | — | — | — |
| Submit expense claim | Y | Y | Y | Y | Y | — |
| Approve expense claim | Y | — | Y (high-value) | — | — | — |
| Manage fixed assets | Y | Y | — | — | — | — |
| Run depreciation | — | Y | — | — | — | — |
| Manage tax rates / Tally export | — | Y | — | — | — | — |
| Configure cross-module mappings & events | — | Y | — | — | — | — |
| View financial reports | Y | Y | Y | Y (own CC) | — | Y |

---

## Section 3 — Functional Requirements

> Format per requirement: **ID · Title · Priority · Tags · Description · Actors · BR refs · Acceptance Criteria · Integration**. Priority: Core (P0) / Standard (P1) / Enhanced (P2). Tags from the controlled vocabulary.

### REQ-ACC-001 — Account Group Management (Chart of Accounts hierarchy)
- **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Maintain a hierarchical chart of account groups. Each group has a name, unique code, an optional parent, and one of five natures (Asset, Liability, Equity, Income, Expense). System-seeded groups cannot be deleted. Supports soft-delete (trash) and restore.
- **Actors:** Initiates/Processes — Accountant · Views — Finance Officer, Auditor
- **BR refs:** BR-ACC-001, BR-ACC-002, BR-ACC-003, BR-ACC-031
- **Acceptance Criteria:**
  - A group can be created under a parent and appears nested in the tree view.
  - A group cannot be its own ancestor (circular parenting blocked).
  - A system group (e.g., Current Assets) cannot be deleted.
  - A group with child groups or ledgers cannot be hard-deleted.
- **Integration:** Foundation for REQ-ACC-002; reports (Section 7) roll up by nature.

### REQ-ACC-002 — Ledger Account Management
- **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Maintain individual ledger accounts under an account group, with name, optional code, opening balance and balance type (Dr/Cr), and flags for bank account, cash account, and reconciliation-enabled. Bank ledgers carry bank name, account number, and IFSC. Ledgers may be linked to a student, employee, or vendor to act as that party's sub-account. System ledgers cannot be deleted. Soft-delete + restore supported.
- **Actors:** Initiates/Processes — Accountant · Views — Finance Officer, Auditor
- **BR refs:** BR-ACC-004, BR-ACC-005, BR-ACC-006, BR-ACC-031
- **Acceptance Criteria:**
  - A ledger requires an account group and a balance type.
  - A ledger already used in any posted voucher line cannot be hard-deleted (soft-delete only).
  - Marking a ledger as bank/cash reveals the relevant bank fields and the reconciliation flag.
  - System ledgers (e.g., Cash, Profit & Loss) are protected from deletion.
- **Integration:** Used by every voucher line; entity-linked ledgers feed the cross-module event engine (REQ-ACC-017).

### REQ-ACC-003 — Ledger Statement
- **Priority:** Standard (P1) · **Tags:** [REPORT]
- **Description:** Display all debit/credit movements for a chosen ledger over a date range, with opening balance, running balance per line, and closing balance.
- **Actors:** Views — Finance Officer, Accountant, Auditor
- **BR refs:** BR-ACC-024, BR-ACC-025
- **Acceptance Criteria:**
  - Statement shows opening balance, every posted line, and a running balance that ends at the closing balance.
  - Cancelled and future-dated vouchers are excluded.
  - Filterable by financial year and date range.
- **Integration:** Reads posted vouchers; also surfaced as RPT-ACC-007.

### REQ-ACC-004 — Financial Year Management
- **Priority:** Core (P0) · **Tags:** [CONFIGURATION][WORKFLOW]
- **Description:** Create financial years (1-Apr to 31-Mar), mark one active, and lock/unlock a year. A locked year blocks all new, edited, or deleted vouchers in that year. Unlock is restricted.
- **Actors:** Initiates/Processes — Accountant · Views — all finance roles
- **BR refs:** BR-ACC-007, BR-ACC-008, BR-ACC-009, BR-ACC-010
- **Acceptance Criteria:**
  - New year start = 1-Apr and end = 31-Mar; date range must not overlap an existing year.
  - A year cannot be locked while it contains any Draft voucher.
  - When a year is locked, attempts to add/edit/delete its vouchers are refused.
  - Unlock requires the lock/unlock permission and is recorded.
- **Integration:** Governs voucher entry (REQ-ACC-006) and year-end closing (ENH-ACC-003).

### REQ-ACC-005 — Voucher Type Management
- **Priority:** Core (P0) · **Tags:** [CONFIGURATION]
- **Description:** Maintain the eight system voucher types (Receipt, Payment, Contra, Journal, Sales, Purchase, Credit Note, Debit Note) plus custom types. Each type has a code, an optional numbering prefix, auto-numbering on/off, a running counter, and is linked to a voucher category. System types cannot be deleted.
- **Actors:** Initiates/Processes — Accountant
- **BR refs:** BR-ACC-011, BR-ACC-012, BR-ACC-031
- **Acceptance Criteria:**
  - All eight system types are present and protected from deletion.
  - A custom type can be added with a unique code and a prefix.
  - Each type links to a voucher category (REQ-ACC-021).
- **Integration:** Drives auto-numbering in REQ-ACC-006.

### REQ-ACC-006 — Voucher Entry & Double-Entry Engine
- **Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW]
- **Description:** Record a voucher of any type with a date, narration, optional reference and cost centre, and two or more lines (at least one debit and one credit). The system enforces that total debits equal total credits before saving, auto-numbers the voucher per type and financial year, and snapshots the numbering prefix.
- **Actors:** Initiates/Processes — Finance Officer, Accountant
- **BR refs:** BR-ACC-013, BR-ACC-014, BR-ACC-015, BR-ACC-016, BR-ACC-017, BR-ACC-018
- **Acceptance Criteria:**
  - A voucher cannot be saved unless total debits equal total credits.
  - A voucher must have at least two lines, with at least one debit and one credit.
  - Voucher date must fall inside the selected financial year and the year must not be locked.
  - A Receipt has exactly one bank/cash ledger on the debit side; a Payment has exactly one bank/cash ledger on the credit side; a Contra has bank/cash ledgers on both sides.
  - The voucher number is generated automatically and is unique within type + financial year.
- **Integration:** Lines reference ledgers (REQ-ACC-002), types (REQ-ACC-005), years (REQ-ACC-004); feeds all reports.

### REQ-ACC-007 — Voucher Lifecycle Actions (post, approve, cancel, reverse, duplicate, print)
- **Priority:** Core (P0) · **Tags:** [WORKFLOW][APPROVAL]
- **Description:** Move a voucher through Draft → Posted → Locked. Posting includes the voucher in balances and reports; approval records the approver; cancellation marks the voucher cancelled and (for posted vouchers) auto-creates a reversal; locked-period vouchers can only be reversed; duplicate copies a voucher into a new Draft; print produces a PDF voucher.
- **Actors:** Initiates/Processes — Finance Officer, Accountant · Reverse — Finance Officer
- **BR refs:** BR-ACC-019, BR-ACC-020, BR-ACC-021, BR-ACC-022, BR-ACC-023
- **Acceptance Criteria:**
  - Posting a voucher with unequal debits/credits is refused.
  - Cancelling a posted voucher creates an automatic reversal and marks the original cancelled.
  - A voucher in a locked year cannot be edited, deleted, or cancelled — only reversed.
  - Duplicating a voucher creates a new Draft with a new number.
  - Print produces a PDF showing the school header, the Dr/Cr table, and an authorisation block.
- **Integration:** Status driven by the status master (REQ-ACC-022); reversal posts a new voucher (REQ-ACC-006).

### REQ-ACC-008 — Recurring Voucher Templates
- **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][SCHEDULED]
- **Description:** Define reusable voucher templates with a frequency (daily/weekly/monthly/quarterly/yearly), start/end dates, day-of-month, and balanced debit/credit lines. Templates can be posted on demand ("post now") and are intended to be posted automatically on schedule.
- **Actors:** Initiates/Processes — Finance Officer, Accountant · System (scheduled, enhancement)
- **BR refs:** BR-ACC-014, BR-ACC-026
- **Acceptance Criteria:**
  - A template's lines must balance (Dr = Cr) before it can be saved.
  - "Post now" generates a real voucher from the template and records the last-posted date.
  - A template with an end date stops generating after that date.
- **Integration:** Generates vouchers (REQ-ACC-006); scheduled posting tracked under ENH-ACC-004.

### REQ-ACC-009 — Cost Centre Management
- **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Maintain a hierarchy of cost centres (department / activity / project) with name, optional code, and parent. Cost centres can be tagged on vouchers and lines and are the unit of budgeting.
- **Actors:** Initiates/Processes — Accountant, Finance Officer · Views — Department Head
- **BR refs:** BR-ACC-027, BR-ACC-031
- **Acceptance Criteria:**
  - A cost centre can be nested under a parent.
  - A cost centre can be selected on a voucher header or line.
- **Integration:** Used by budgets (REQ-ACC-010) and the budget-variance report (RPT-ACC-010).

### REQ-ACC-010 — Budget Management & Variance
- **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][WORKFLOW][APPROVAL]
- **Description:** Allocate budget amounts per financial year + cost centre + ledger, route the plan through a draft → submitted → approved/active workflow, and compare allocated vs actual (and committed) spend. Raise an alert when utilisation crosses 90%.
- **Actors:** Initiates/Processes — Finance Officer/Accountant (create), Principal (approve) · Views — Department Head
- **BR refs:** BR-ACC-027, BR-ACC-028, BR-ACC-029, BR-ACC-030
- **Acceptance Criteria:**
  - Only one active budget per financial year + cost centre + ledger.
  - Actual spend = sum of approved/posted debit lines for the ledger in the year.
  - Available balance = allocated − committed − actual.
  - When utilisation exceeds 90%, a notification is raised to the Finance Officer and Department Head.
- **Integration:** Reads posted vouchers and cost centres; surfaced as RPT-ACC-010; alert via Notification module.

### REQ-ACC-011 — Bank Reconciliation
- **Priority:** Core (P0) · **Tags:** [WORKFLOW][INTEGRATION]
- **Description:** For a reconciliation-enabled bank ledger, create a reconciliation session (statement date + closing balance), import the bank statement (CSV), auto-match statement lines to recorded voucher lines by amount/date/narration, allow manual matching, create vouchers for unmatched bank items, and complete the session only when the book balance equals the bank closing balance.
- **Actors:** Initiates/Processes — Finance Officer, Accountant
- **BR refs:** BR-ACC-032, BR-ACC-033, BR-ACC-034, BR-ACC-035
- **Acceptance Criteria:**
  - Reconciliation can only be started on a ledger flagged reconciliation-enabled.
  - Imported statement lines appear and auto-match runs, flagging each line matched/unmatched.
  - An unmatched bank line can be manually matched or converted into a new voucher.
  - Completion is blocked unless the difference is zero, unless the Finance Officer applies an override.
- **Integration:** Matches against voucher lines (REQ-ACC-006); produces RPT-ACC-013.

### REQ-ACC-012 — Fixed Asset Register & Categories
- **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][CONFIGURATION]
- **Description:** Maintain asset categories (with depreciation method, rate, useful life) and a fixed-asset register (name, unique code, category, purchase date, cost, salvage value, current book value, accumulated depreciation, location, vendor, and the purchase voucher).
- **Actors:** Initiates/Processes — Finance Officer, Accountant
- **BR refs:** BR-ACC-036, BR-ACC-037, BR-ACC-031
- **Acceptance Criteria:**
  - An asset belongs to exactly one category and has a unique asset code.
  - Salvage value must be less than purchase cost.
  - Each category defines either SLM or WDV with a rate / useful life.
- **Integration:** Drives depreciation (REQ-ACC-013); links to vendor (Vendor module) and the purchase voucher (REQ-ACC-006).

### REQ-ACC-013 — Depreciation Engine (SLM / WDV)
- **Priority:** Standard (P1) · **Tags:** [WORKFLOW][SCHEDULED]
- **Description:** Run depreciation per asset per financial year using the category's method (Straight-Line = (cost − salvage) ÷ useful life, prorated; Written-Down-Value = current value × rate). Each run posts a depreciation journal (Dr Depreciation Expense, Cr Accumulated Depreciation) and updates the asset's current value and accumulated depreciation. Re-running for the same year replaces prior entries (idempotent).
- **Actors:** Initiates/Processes — Accountant · System (scheduled, enhancement)
- **BR refs:** BR-ACC-038, BR-ACC-039, BR-ACC-040
- **Acceptance Criteria:**
  - SLM book value never drops below salvage value.
  - Re-running depreciation for the same financial year replaces, never duplicates, entries.
  - Each run creates a balanced depreciation journal linked to the asset.
- **Integration:** Posts journals (REQ-ACC-006); feeds the Net Block report (RPT-ACC-012).

### REQ-ACC-014 — Expense Claims
- **Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][WORKFLOW][APPROVAL]
- **Description:** Let staff submit expense claims with line items (date, expense ledger, description, amount, tax, receipt attachment). Claims flow Draft → Submitted → Approved/Rejected → Paid; on approval a payment voucher is auto-created. Rejection requires a reason.
- **Actors:** Initiates — Staff · Approves — Finance Officer / Principal (high-value)
- **BR refs:** BR-ACC-041 (see Conditions), BR-ACC-021
- **Acceptance Criteria:**
  - A claimant can only create/edit their own claims.
  - Rejection requires a reason; approval auto-creates a payment voucher.
  - A claim total equals the sum of its line amounts (plus tax).
- **Integration:** Claimant links to employee (SchoolSetup); approval posts a payment voucher (REQ-ACC-006).

### REQ-ACC-015 — Tax Rate Master
- **Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
- **Description:** Maintain GST/TDS rate definitions (name, percentage rate, type CGST/SGST/IGST/Cess, HSN/SAC code, interstate flag) for use on taxable transactions.
- **Actors:** Initiates/Processes — Accountant
- **BR refs:** BR-ACC-031
- **Acceptance Criteria:**
  - A rate has a type and a percentage.
  - Rates can be activated/deactivated.
- **Integration:** Referenced by taxable voucher lines and the GST enhancement (ENH-ACC-001).

### REQ-ACC-016 — Cross-Module Ledger Mappings
- **Priority:** Standard (P1) · **Tags:** [CONFIGURATION][INTEGRATION]
- **Description:** Map a source module + source entity (e.g., a fee head, pay head, route) to the ledger that should be used when that source generates an accounting entry. Without a mapping the source event is skipped, never failed.
- **Actors:** Initiates/Processes — Accountant
- **BR refs:** BR-ACC-031
- **Acceptance Criteria:**
  - A mapping ties a source module/type/entity to one ledger.
  - The combination is unique.
- **Integration:** Consumed by the cross-module event engine (REQ-ACC-017) and integrations (Section 16).

### REQ-ACC-017 — Cross-Module Event Engine
- **Priority:** Core (P0) · **Tags:** [INTEGRATION][CONFIGURATION][WORKFLOW]
- **Description:** A configuration-driven engine that lets any module register a business event (e.g., "library late-return fine paid") and define how a voucher is created when that event fires: which voucher type, whether to auto-post or hold as draft, whether approval is required, a narration template, and the debit/credit line templates (each resolving its ledger as fixed / student / vendor / employee, and its amount from the source record / a fixed value / the event payload). Every received event is logged with its outcome (processed / failed / skipped) and a retry count.
- **Actors:** Initiates/Processes — Accountant (configures) · Cross-Module Source (fires events) · System (processes)
- **BR refs:** BR-ACC-042, BR-ACC-043, BR-ACC-044 (see Conditions)
- **Acceptance Criteria:**
  - A school must explicitly configure an event before any voucher is created for it (opt-in).
  - When an event fires with an active config, a balanced voucher is created per the line templates and logged as processed.
  - A duplicate or unconfigured event is logged as skipped, not failed.
  - A failed event is logged with the error and a retry count, without affecting the source module.
- **Integration:** Replaces the hardcoded listener design described in the V2 requirement; uses ledger mappings (REQ-ACC-016).

### REQ-ACC-018 — Tally Export & Ledger Mapping
- **Priority:** Standard (P1) · **Tags:** [REPORT][INTEGRATION]
- **Description:** Map each ledger to a Tally ledger/group name and export ledgers and vouchers (by date range) as TallyPrime-compatible XML. Each export is recorded in an export log (type, date range, record count, file, outcome) and the file can be re-downloaded.
- **Actors:** Initiates/Processes — Accountant
- **BR refs:** BR-ACC-031
- **Acceptance Criteria:**
  - A ledger can be mapped to a Tally ledger and group name.
  - Export produces a downloadable XML file and an export-log entry recording the outcome.
  - Voucher types map to their Tally equivalents (Receipt→Receipt, etc.).
- **Integration:** Reads ledgers and posted vouchers.

### REQ-ACC-019 — Financial Reporting
- **Priority:** Core (P0) · **Tags:** [REPORT]
- **Description:** Produce the statutory and operational financial reports listed in Section 7, all filtered by financial year and optional date range, excluding cancelled and future-dated vouchers, with PDF/Excel export.
- **Actors:** Views — Finance Officer, Accountant, Principal, Department Head, Auditor
- **BR refs:** BR-ACC-024, BR-ACC-025
- **Acceptance Criteria:**
  - Trial Balance total debits equal total credits (data-integrity alert otherwise).
  - Balance Sheet satisfies Assets = Liabilities + Equity.
  - Reports can be exported to PDF and Excel.
- **Integration:** See RPT-ACC-001…013.

### REQ-ACC-020 — Finance Dashboard
- **Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT]
- **Description:** A landing dashboard showing key indicators (net surplus/deficit, total income, total expense, bank balances), a monthly income-vs-expense chart, budget-utilisation bars per cost centre, a pending-approvals widget (vouchers + expense claims), and over-budget alert banners.
- **Actors:** Views — Finance Officer, Accountant, Principal, Department Head, Auditor
- **BR refs:** BR-ACC-030
- **Acceptance Criteria:**
  - KPI cards reflect the active financial year's posted data.
  - Pending-approvals widget counts vouchers and expense claims awaiting action.
  - Over-budget cost centres appear as alert banners.
- **Integration:** Aggregates vouchers, budgets, expense claims.

### REQ-ACC-021 — Voucher Source-Module & Category Registry
- **Priority:** Standard (P1) · **Tags:** [CONFIGURATION][INTEGRATION]
- **Description:** Maintain the registry of modules that can post vouchers into Accounting (code, name, table prefix, icon, display order) and the categories within each module (code, name, source table, default ledger). This drives the cross-module mapping and category selection.
- **Actors:** Initiates/Processes — Accountant / System (seeded)
- **BR refs:** BR-ACC-031
- **Acceptance Criteria:**
  - A source module can be registered with a unique code and prefix.
  - A category belongs to a source module and may point to a default ledger.
- **Integration:** Underpins REQ-ACC-005, REQ-ACC-016, REQ-ACC-017. *(Backed by tables that currently have no Eloquent model — see Section 20.)*

### REQ-ACC-022 — Status Master Configuration
- **Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
- **Description:** Maintain the configurable list of statuses used across the module — Voucher, Bank Reconciliation, Expense Claim, Tally Export, and Cross-Module Processing — so the school can extend statuses without code changes.
- **Actors:** Initiates/Processes — Accountant / System (seeded)
- **BR refs:** BR-ACC-031
- **Acceptance Criteria:**
  - Each status belongs to one status type and has a unique code within that type.
  - Adding a status requires no schema change.
- **Integration:** Referenced by vouchers, reconciliations, expense claims, exports, and the event log. *(Backed by a table with no Eloquent model — see Section 20.)*

---

## Section 4 — Business Rules Register

| BR-ID | Rule (business statement) | Type | Trigger | Enforcement Point | Priority |
|-------|---------------------------|------|---------|-------------------|----------|
| BR-ACC-001 | An account group must have one of five natures: Asset, Liability, Equity, Income, Expense. | Validation | Group save | Account Group form | P0 |
| BR-ACC-002 | A group cannot be made its own ancestor (no circular parenting). | Validation | Group save | Account Group form | P0 |
| BR-ACC-003 | A system-seeded account group cannot be deleted. | Workflow | Delete attempt | Account Group delete | P0 |
| BR-ACC-004 | A ledger must belong to an account group and have a balance type (Dr/Cr). | Validation | Ledger save | Ledger form | P0 |
| BR-ACC-005 | A ledger used in any posted voucher line cannot be hard-deleted (soft-delete only). | Workflow | Delete attempt | Ledger delete | P0 |
| BR-ACC-006 | A system ledger (e.g., Cash, P&L) cannot be deleted. | Workflow | Delete attempt | Ledger delete | P0 |
| BR-ACC-007 | A financial year's start must be 1-Apr and end 31-Mar of the next year. | Validation | Year save | Financial Year form | P0 |
| BR-ACC-008 | A new financial year's date range must not overlap an existing year. | Validation | Year save | Financial Year form | P0 |
| BR-ACC-009 | A financial year cannot be locked while it contains any Draft voucher. | Workflow | Lock action | Lock pre-check | P0 |
| BR-ACC-010 | Unlocking a financial year requires the lock/unlock permission and is recorded. | Permission | Unlock action | Unlock control | P1 |
| BR-ACC-011 | The eight system voucher types cannot be deleted. | Workflow | Delete attempt | Voucher Type delete | P0 |
| BR-ACC-012 | Every voucher type links to a voucher category. | Validation | Type save | Voucher Type form | P1 |
| BR-ACC-013 | Total debits must equal total credits in every voucher. | Calculation | Voucher save / post | Voucher service | P0 |
| BR-ACC-014 | A voucher (or recurring template) must have at least two lines: ≥1 debit and ≥1 credit. | Validation | Voucher/template save | Voucher service | P0 |
| BR-ACC-015 | A voucher's date must fall within the selected financial year. | Validation | Voucher save | Voucher form | P0 |
| BR-ACC-016 | No voucher may be added/edited/deleted in a locked financial year. | Workflow | Any voucher write | Voucher service | P0 |
| BR-ACC-017 | A Receipt has exactly one bank/cash ledger on the debit side; a Payment has exactly one on the credit side; a Contra uses bank/cash ledgers on both sides. | Validation | Voucher save | Voucher service | P1 |
| BR-ACC-018 | Voucher numbers are auto-generated and unique within voucher type + financial year. | Calculation | Voucher save | Voucher service | P0 |
| BR-ACC-019 | A Draft voucher is excluded from balances and reports; a Posted voucher is included. | Calculation | Posting | Report/Balance queries | P0 |
| BR-ACC-020 | Cancelling a Posted voucher auto-creates an equal-and-opposite reversal and marks the original cancelled. | Workflow | Cancel action | Voucher service | P0 |
| BR-ACC-021 | Cancelled vouchers are excluded from all balances and reports. | Calculation | Report/Balance queries | Report/Balance queries | P0 |
| BR-ACC-022 | A voucher in a locked year may only be reversed (not edited/deleted/cancelled). | Workflow | Locked-period write | Voucher service | P0 |
| BR-ACC-023 | Future-dated (post-dated) vouchers are excluded from reports until their date arrives. | Calculation | Report queries | Report queries | P1 |
| BR-ACC-024 | All reports filter by financial year and optional date range. | Calculation | Report run | Report service | P1 |
| BR-ACC-025 | Trial Balance total debits must equal total credits; otherwise a data-integrity alert is shown. | Validation | Report render | Report service | P0 |
| BR-ACC-026 | A recurring template's lines must balance (Dr = Cr) before it can be saved or posted. | Calculation | Template save / post | Recurring service | P1 |
| BR-ACC-027 | Only one active budget may exist per financial year + cost centre + ledger. | Validation | Budget save | Budget form | P1 |
| BR-ACC-028 | Actual spend = sum of posted debit lines for the ledger in the financial year. | Calculation | Variance calc | Report service | P1 |
| BR-ACC-029 | Available budget = allocated − committed − actual. | Calculation | Variance calc | Report service | P1 |
| BR-ACC-030 | When budget utilisation exceeds 90%, an over-budget alert is raised to Finance Officer and Department Head. | Workflow | Spend posting / scheduled check | Budget monitor + Notification | P1 |
| BR-ACC-031 | System-seeded master records (status, voucher type, voucher module/category, system groups/ledgers) cannot be deleted. | Workflow | Delete attempt | Respective delete control | P1 |
| BR-ACC-032 | Bank reconciliation can only be started on a ledger flagged reconciliation-enabled. | Validation | Recon create | Reconciliation form | P0 |
| BR-ACC-033 | Auto-match links a statement line to a voucher line by amount + date (±3 days) + narration keyword, with a confidence score. | Calculation | Auto-match | Reconciliation service | P1 |
| BR-ACC-034 | A reconciliation can only be completed when the difference is zero. | Validation | Complete action | Reconciliation service | P0 |
| BR-ACC-035 | Completing a reconciliation with a non-zero difference requires a Finance Officer override. | Permission | Complete action | Reconciliation service | P1 |
| BR-ACC-036 | An asset's salvage value must be less than its purchase cost. | Validation | Asset save | Fixed Asset form | P1 |
| BR-ACC-037 | An asset code must be unique. | Validation | Asset save | Fixed Asset form | P1 |
| BR-ACC-038 | Under SLM, an asset's book value never drops below its salvage value. | Calculation | Depreciation run | Depreciation service | P1 |
| BR-ACC-039 | Re-running depreciation for the same financial year replaces existing entries (idempotent), never duplicates. | Workflow | Depreciation run | Depreciation service | P1 |
| BR-ACC-040 | Each depreciation run posts a balanced journal (Dr Depreciation Expense, Cr Accumulated Depreciation). | Calculation | Depreciation run | Depreciation service | P1 |

> Expense-claim, event-engine, and cross-module conditions BR-ACC-041…044 are catalogued in Section 12 (Conditions) to keep the register focused on enforced rules.

---

## Section 5 — Data Requirements (Business Entities)

| Entity | Business meaning | Key attributes (business) | Privacy |
|--------|------------------|---------------------------|---------|
| Financial Year | The accounting year | Name, start, end, locked? | Internal |
| Account Group | COA folder | Name, code, parent, nature | Internal |
| Ledger Account | Individual account | Name, code, group, opening balance, bank/cash flags, party link | Confidential (bank details, party links) |
| Voucher Type | Transaction kind | Name, code, prefix, category | Internal |
| Voucher | A recorded transaction | Number, type, date, narration, total, status, source | Confidential |
| Voucher Line | One Dr/Cr leg | Ledger, debit/credit, amount, narration, cost centre | Confidential |
| Cost Centre | Department/activity for budgeting | Name, code, parent | Internal |
| Budget | Planned spend | Year, cost centre, ledger, amount, status | Internal |
| Tax Rate | GST/TDS rate | Name, rate, type, HSN/SAC | Internal |
| Bank Reconciliation | A reconciliation session | Bank ledger, statement date, closing balance, status | Confidential |
| Bank Statement Entry | A line from the bank statement | Date, description, debit, credit, matched? | Confidential |
| Fixed Asset | A capital asset | Name, code, category, cost, salvage, current value | Internal |
| Asset Category | Asset class + depreciation rule | Name, method, rate, life | Internal |
| Depreciation Entry | A yearly depreciation record | Asset, year, amount, journal | Internal |
| Expense Claim | Staff reimbursement request | Claimant, date, total, status | Confidential (staff financial data) |
| Expense Claim Line | One claimed expense | Date, ledger, description, amount, receipt | Confidential |
| Ledger Mapping | Source-entity → ledger link | Source module/type/id, ledger | Internal |
| Recurring Template | Repeating voucher pattern | Name, type, frequency, lines | Internal |
| Tally Ledger Mapping | Ledger → Tally name | Ledger, Tally ledger/group | Internal |
| Tally Export Log | Export audit record | Type, date range, count, file, outcome | Internal |
| Module Event | Registered cross-module event | Module code, event code, source table | Internal |
| Event Voucher Config | How an event posts a voucher | Voucher type, auto-post?, approval?, narration | Internal |
| Event Line Template | Dr/Cr template for an event | Side, ledger resolver, amount resolver | Internal |
| Event Processing Log | Audit of each received event | Source, payload, outcome, retries | Confidential (payload snapshot) |
| Status Master | Configurable status list | Status type, code, name | Internal |
| Voucher Module Registry | Modules that post vouchers | Code, name, prefix | Internal |
| Voucher Category | Categories per source module | Code, name, default ledger | Internal |

> **Multi-tenant scoping:** every entity above lives in the school's own tenant database; there is no cross-school data sharing (database-per-tenant). **Academic/financial-year scoping:** transactional entities are scoped to a financial year and must be filtered by it.

---

## Section 6 — Workflows

### Workflow 1 — Voucher Lifecycle
- **Trigger:** Finance Officer/Accountant creates a voucher · **End states:** Posted, Cancelled, Locked
- **Swimlanes:** Operator | System
- **Steps:** 1) Operator enters header + lines → 2) System checks Dr = Cr, ≥2 lines, date in unlocked year → 3) Save as Draft → 4) Operator posts → System includes in balances → 5) Year-lock later moves it to Locked.
- **Exception paths:** Dr ≠ Cr → save refused; locked year → write refused; cancel posted → reversal auto-posted.
- **Notifications:** | Step | Recipient | Channel | Message | → | Approval pending | Approver | In-app | "Voucher {number} awaiting approval" |

### Workflow 2 — Bank Reconciliation
- **Trigger:** Finance Officer starts a session · **End state:** Completed
- **Steps:** 1) Create session (bank ledger + closing balance) → 2) Import statement → 3) Auto-match → 4) Resolve unmatched (manual match or create voucher) → 5) Complete when difference = 0.
- **Exception paths:** Difference ≠ 0 → completion blocked unless Finance Officer override; non-reconcilable ledger → cannot start.
- **Notifications:** none mandatory.

### Workflow 3 — Expense Claim
- **Trigger:** Staff submits a claim · **End states:** Paid, Rejected
- **Swimlanes:** Staff | Finance Officer/Principal | System
- **Steps:** 1) Staff creates Draft → 2) Submit → 3) Approver approves or rejects (reason required) → 4) On approval, System auto-creates a payment voucher → status Paid.
- **Exception paths:** Reject → status Rejected with reason; staff editing another's claim → refused.
- **Notifications:** | Submitted | Approver | In-app | "Expense claim {number} submitted" | · | Approved/Rejected | Claimant | In-app | "Your claim {number} was {decision}" |

### Workflow 4 — Budget Approval
- **Trigger:** Finance Officer creates a budget plan · **End state:** Active
- **Steps:** 1) Create Draft → 2) Submit → 3) Principal approves (→ Active) or rejects (→ Draft).
- **Exception paths:** Duplicate active budget for the same year+cost centre+ledger → refused.
- **Notifications:** | 90% utilisation | Finance Officer + Dept Head | In-app | "Budget for {cost centre} is over 90% utilised" |

### Workflow 5 — Cross-Module Event → Auto-Voucher
- **Trigger:** Another module fires a registered event · **End states:** Processed, Skipped, Failed
- **Swimlanes:** Source Module | Accounting Engine
- **Steps:** 1) Source fires event with payload → 2) Engine looks up active config → 3) If none/duplicate → log Skipped → 4) Else resolve ledgers + amounts per line templates → 5) Create balanced voucher (auto-post or draft per config) → log Processed.
- **Exception paths:** Processing error → log Failed with message + retry count; the source module is never rolled back or blocked.
- **Notifications:** failure alert to Finance Officer (in-app).

---

## Section 7 — Reporting & Analytics

| RPT-ID | Report | Audience | Frequency | Contents | Filters | Export | Notes |
|--------|--------|----------|-----------|----------|---------|--------|-------|
| RPT-ACC-001 | Trial Balance | Accountant, Auditor | On demand | Every ledger's Dr/Cr balance + totals | FY, date range | PDF/Excel | Dr total must = Cr total (BR-ACC-025) |
| RPT-ACC-002 | Profit & Loss | Management, Auditor | On demand | Income vs expense, net surplus/deficit | FY, date range | PDF/Excel | |
| RPT-ACC-003 | Balance Sheet | Management, Auditor | On demand | Assets, Liabilities, Equity | FY, as-of date | PDF/Excel | Assets = Liab + Equity |
| RPT-ACC-004 | Day Book | Finance Officer | Daily | All vouchers for a date | Date | PDF/Excel | |
| RPT-ACC-005 | Cash Book | Finance Officer | Daily | Cash ledger movements + balance | FY, date range | PDF/Excel | |
| RPT-ACC-006 | Bank Book | Finance Officer | Daily | Bank ledger movements + balance | FY, date range, ledger | PDF/Excel | |
| RPT-ACC-007 | Ledger Statement | Finance, Auditor | On demand | One ledger's movements + running balance | FY, date range, ledger | PDF/Excel | = REQ-ACC-003 |
| RPT-ACC-008 | Outstanding Receivables | Finance Officer | On demand | Amounts owed to the school | FY, as-of date | PDF/Excel | |
| RPT-ACC-009 | Outstanding Payables | Finance Officer | On demand | Amounts the school owes | FY, as-of date | PDF/Excel | |
| RPT-ACC-010 | Budget Variance | Management, Dept Head | Monthly | Allocated vs committed vs actual vs variance | FY, cost centre | PDF/Excel | |
| RPT-ACC-011 | GST Summary | Accountant | Monthly | Output/input GST summary | FY, period | PDF/Excel | Depends on ENH-ACC-001 |
| RPT-ACC-012 | Net Block (Fixed Assets) | Accountant, Auditor | Yearly | Cost − accumulated depreciation per asset | FY | PDF/Excel | Depends on REQ-ACC-013 |
| RPT-ACC-013 | Bank Reconciliation Statement | Finance Officer | Per session | Book balance, outstanding items, adjusted balance | Session | PDF | |
| RPT-ACC-014 | Form 26Q (TDS) | Accountant | Quarterly | TDS deductions per vendor PAN | FY, quarter | Excel | Depends on ENH-ACC-002 |

**KPI / Metrics Catalog**
| KPI | Definition (business) | Source | Cadence |
|-----|-----------------------|--------|---------|
| Net Surplus/Deficit | Total income − total expense for the year | Posted vouchers | Live |
| Bank Balance(s) | Closing balance of each bank ledger | Posted vouchers | Live |
| Budget Utilisation % | Actual spend ÷ allocated budget | Budgets + vouchers | Live |
| Pending Approvals | Count of vouchers + claims awaiting action | Vouchers + claims | Live |
| Reconciliation Lag | Days since last completed bank reconciliation | Reconciliation sessions | Daily |

---

## Section 8 — Future Enhancement Log

| ENH-ID | Enhancement | Rationale | Schema/Build gap | On-approval becomes |
|--------|-------------|-----------|-------------------|---------------------|
| ENH-ACC-001 | GST Compliance (GSTR-1/3B, ITC, e-invoicing IRN/QR) | Statutory GST returns | `acc_gst_details` table absent; no GST service | New REQ-ACC-023+ |
| ENH-ACC-002 | TDS Management (deduction, remittance, Form 26Q/16) | Statutory TDS | `acc_tds_entries` table absent; no TDS controller/service | New REQ-ACC-024+ |
| ENH-ACC-003 | Year-End Closing Wizard (P&L carry-forward, OB roll-over, close audit) | One-click year close | `acc_year_end_closings` table absent; only manual lock/unlock built | New REQ-ACC-025+ |
| ENH-ACC-004 | Scheduled background jobs (auto-post recurring, monthly depreciation, budget-breach check) | Automation | No job/command files found | New REQ-ACC-026+ |
| ENH-ACC-005 | E-invoicing (IRP API → IRN + signed JSON + QR) | B2B invoicing compliance | Part of GST; depends on ENH-ACC-001 | sub-REQ |
| ENH-ACC-006 | Asset disposal & gain/loss accounting | Complete asset lifecycle | No disposal route/screen confirmed | New REQ |

---

## Section 9 — Non-Functional Requirements

| NFR-ID | Category | Requirement (measurable) | Acceptance threshold |
|--------|----------|--------------------------|----------------------|
| NFR-ACC-001 | Integrity | Every posted voucher balances (Dr = Cr) | 100% of posted vouchers |
| NFR-ACC-002 | Integrity | Trial Balance Dr total = Cr total | Always, else alert |
| NFR-ACC-003 | Security | Each financial action is permission-gated per the role matrix | No unauthorised write succeeds |
| NFR-ACC-004 | Security/Isolation | School books are fully isolated per tenant (database-per-tenant) | No cross-school read possible |
| NFR-ACC-005 | Auditability | Posted/locked entries are immutable; changes only via reversal; all writes carry created/approved-by | 100% traceable |
| NFR-ACC-006 | Reliability | Cross-module voucher failure never rolls back or blocks the source module | 0 source rollbacks on accounting failure |
| NFR-ACC-007 | Reliability | Failed cross-module events are retried up to a capped number of attempts | Retries capped + logged |
| NFR-ACC-008 | Performance | Trial Balance / P&L / Balance Sheet render within an acceptable time for a full-year dataset | ≤ 3 s typical year |
| NFR-ACC-009 | Performance | Finance dashboard uses caching to avoid recomputation on each load | ~30-min cache |
| NFR-ACC-010 | Usability | Voucher entry shows live Dr/Cr totals and disables Save on mismatch | Mismatch never saved |
| NFR-ACC-011 | Compatibility | Tally export validates against TallyPrime 3.x import schema | Imports cleanly |
| NFR-ACC-012 | Compliance | Depreciation methods follow ICAI/IT-Act conventions (SLM/WDV) | Method-correct values |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Table (downstream contract)
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|----------------|---------|----------|------|:---:|:---:|:---:|:---:|:---:|
| REQ-ACC-001 | Account Group Mgmt | P0 | DATA_ENTRY,CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-ACC-002 | Ledger Mgmt | P0 | DATA_ENTRY,CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-ACC-003 | Ledger Statement | P1 | REPORT | No | Yes | Yes | No | Yes |
| REQ-ACC-004 | Financial Year Mgmt | P0 | CONFIG,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-ACC-005 | Voucher Type Mgmt | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-ACC-006 | Voucher Entry & Engine | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-ACC-007 | Voucher Lifecycle | P0 | WORKFLOW,APPROVAL | Yes | Yes | Yes | Yes | Yes |
| REQ-ACC-008 | Recurring Templates | P1 | DATA_ENTRY,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-ACC-009 | Cost Centre Mgmt | P1 | DATA_ENTRY,CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-ACC-010 | Budget Mgmt & Variance | P1 | DATA_ENTRY,WORKFLOW,APPROVAL | Yes | Yes | Yes | Yes | Yes |
| REQ-ACC-011 | Bank Reconciliation | P0 | WORKFLOW,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-ACC-012 | Fixed Asset Register | P1 | DATA_ENTRY,CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-ACC-013 | Depreciation Engine | P1 | WORKFLOW,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-ACC-014 | Expense Claims | P1 | DATA_ENTRY,WORKFLOW,APPROVAL | Yes | Yes | Yes | Yes | Yes |
| REQ-ACC-015 | Tax Rate Master | P1 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-ACC-016 | Cross-Module Ledger Mappings | P1 | CONFIG,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-ACC-017 | Cross-Module Event Engine | P0 | INTEGRATION,CONFIG,WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-ACC-018 | Tally Export & Mapping | P1 | REPORT,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-ACC-019 | Financial Reporting | P0 | REPORT | No | Yes | Yes | No | Yes |
| REQ-ACC-020 | Finance Dashboard | P1 | DASHBOARD,REPORT | No | Yes | Yes | No | Yes |
| REQ-ACC-021 | Voucher Module/Category Registry | P1 | CONFIG,INTEGRATION | Yes | Yes | Yes | No | Yes |
| REQ-ACC-022 | Status Master Configuration | P1 | CONFIG | Yes | Yes | Yes | No | Yes |

### 10.2 Business-Rule Coverage
- 40 enforced business rules (BR-ACC-001…040) + 4 conditions (BR-ACC-041…044). Calculation rules (BR-ACC-013, 018, 028, 029, 038, 040) carry business-term formulas; Concurrency-sensitive resource = the per-type+FY voucher number counter (BR-ACC-018) and the active-budget uniqueness (BR-ACC-027).

### 10.3 Report Coverage
- 14 reports (RPT-ACC-001…014). RPT-ACC-011 and RPT-ACC-014 depend on enhancements (ENH-ACC-001/002).

### 10.4 Totals (reconciled)
| Artifact | Count | Priority split |
|----------|-------|----------------|
| Functional Requirements (REQ) | 22 | P0 = 9, P1 = 13, P2 = 0 |
| Business Rules (BR) | 40 enforced (+4 conditions) | — |
| Reports (RPT) | 14 | — |
| Enhancements (ENH) | 6 | — |
| Workflows | 5 | — |
| NFRs | 12 | — |
| Risks | 8 | — |

> **Priority recount note:** the 22 REQ split is P0 = 9 (001,002,004,005,006,007,011,017,019), P1 = 13 (003,008,009,010,012,013,014,015,016,018,020,021,022). No P2 REQ — lower-value items live in the Enhancement Log instead.

---

## Section 11 — Requirements Traceability Matrix (RTM)

| REQ-ID | BR refs | Screen(s) | Workflow | Report(s) | Code Status (BA view) | Gap |
|--------|---------|-----------|----------|-----------|------------------------|-----|
| REQ-ACC-001 | 001-003,031 | account-group | — | — | PARTIAL (ctrl+model+views) | logic completeness unverified |
| REQ-ACC-002 | 004-006,031 | ledger | — | RPT-007 | PARTIAL | as above |
| REQ-ACC-003 | 024,025 | ledger/statement | — | RPT-007 | PARTIAL | — |
| REQ-ACC-004 | 007-010 | financial-year | WF1 | — | PARTIAL (lock/unlock routes) | year-end engine = ENH-003 |
| REQ-ACC-005 | 011,012,031 | voucher-type | — | — | PARTIAL | — |
| REQ-ACC-006 | 013-018 | voucher | WF1 | all | PARTIAL (VoucherService present) | service-logic audit needed |
| REQ-ACC-007 | 019-023 | voucher | WF1 | — | PARTIAL | reversal logic audit |
| REQ-ACC-008 | 014,026 | recurring-template | — | — | PARTIAL (RecurringTemplateService) | scheduled posting = ENH-004 |
| REQ-ACC-009 | 027,031 | cost-center | — | RPT-010 | PARTIAL | — |
| REQ-ACC-010 | 027-030 | budget | WF4 | RPT-010 | PARTIAL | over-budget alert wiring |
| REQ-ACC-011 | 032-035 | bank-reconciliation | WF2 | RPT-013 | PARTIAL (ReconciliationService) | CSV parser audit |
| REQ-ACC-012 | 036,037,031 | fixed-asset, asset-category | — | RPT-012 | PARTIAL | disposal = ENH-006 |
| REQ-ACC-013 | 038-040 | fixed-asset (run) | — | RPT-012 | PARTIAL (DepreciationService) | idempotency audit |
| REQ-ACC-014 | 041,021 | expense-claim | WF3 | — | PARTIAL (ExpenseClaimService) | — |
| REQ-ACC-015 | 031 | tax-rate | — | RPT-011 | PARTIAL | GST usage = ENH-001 |
| REQ-ACC-016 | 031 | ledger-mapping | WF5 | — | PARTIAL | — |
| REQ-ACC-017 | 042-044 | event-mapping | WF5 | — | PARTIAL (ModuleEvent/EventVoucherConfig + RemoteEntryService) | engine integration audit |
| REQ-ACC-018 | 031 | tally-export, tally-mapping | — | — | PARTIAL (no separate service; logic in controller) | — |
| REQ-ACC-019 | 024,025 | report | — | RPT-001-010 | PARTIAL (ReportService) | report-math audit |
| REQ-ACC-020 | 030 | dashboard | — | KPIs | PARTIAL (AccDashboardController) | — |
| REQ-ACC-021 | 031 | event-mapping (registry) | WF5 | — | PARTIAL (no model — query/seed) | model-less tables |
| REQ-ACC-022 | 031 | (config/seed) | — | — | PARTIAL (no model — seed) | model-less table |

---

## Section 12 — Requirement Conditions Catalog (keyed to BR-)

| Condition ID | Entity/Field | Condition (business) | Type | Trigger | On-Violation Behaviour |
|--------------|--------------|----------------------|------|---------|------------------------|
| BR-ACC-013 | Voucher | Total debits = total credits | Calculation | Save/Post | Save refused, mismatch shown |
| BR-ACC-014 | Voucher/Template | ≥2 lines, ≥1 Dr + ≥1 Cr | Validation | Save | Save refused |
| BR-ACC-016 | Voucher | Year not locked | Workflow | Any write | Write refused |
| BR-ACC-017 | Voucher (RCT/PMT/CTR) | Correct bank/cash ledger placement | Validation | Save | Save refused |
| BR-ACC-027 | Budget | One active per FY+CC+ledger | Validation | Save | Save refused (duplicate) |
| BR-ACC-032 | Reconciliation | Bank ledger must allow reconciliation | Validation | Create | Cannot start |
| BR-ACC-034 | Reconciliation | Difference = 0 to complete | Validation | Complete | Blocked (unless override) |
| BR-ACC-036 | Fixed Asset | Salvage < purchase cost | Validation | Save | Save refused |
| BR-ACC-039 | Depreciation | Idempotent per FY | Workflow | Run | Prior entries replaced |
| BR-ACC-041 | Expense Claim | Claimant edits only own claims; rejection needs reason; approval auto-creates payment voucher | Permission/Workflow | Edit/Approve/Reject | Unauthorized edit refused; reject without reason refused |
| BR-ACC-042 | Event Config | Event must be configured before any voucher is created (opt-in) | Workflow | Event fired | Logged Skipped (no config) |
| BR-ACC-043 | Event Processing | Duplicate event for same source record → skip | Workflow | Event fired | Logged Skipped (duplicate guard) |
| BR-ACC-044 | Event Processing | Processing failure never rolls back/blocks the source module | Reliability | Event fired | Logged Failed + retry; source unaffected |

---

## Section 13 — Validation & Edge-Case Catalog

| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected behaviour |
|------------|-------|---------|----------|------------|-------------|--------------------|
| Voucher Dr=Cr | Dr 1000 = Cr 1000 | Dr 1000, Cr 900 | Dr 0.01 = Cr 0.01 | no lines | two posts of same draft | Save only when balanced; counter not double-issued |
| Voucher date | within FY | outside FY | exactly start/end date | empty | — | In-range accepted; out refused |
| Locked year write | unlocked year | locked year edit | lock at boundary date | — | lock while editing | Locked write refused |
| Ledger delete | unused ledger | ledger in posted voucher | first-use moment | — | delete + post race | Soft-delete only if used |
| Budget uniqueness | new FY+CC+ledger | second active duplicate | — | — | two concurrent saves | Only one active allowed |
| Reconciliation complete | diff = 0 | diff ≠ 0 | diff = 0.01 | — | — | Block unless override |
| Asset salvage | salvage < cost | salvage ≥ cost | salvage = cost | salvage null | — | Save refused if ≥ cost |
| Depreciation re-run | first run | — | book value at salvage floor | — | two runs same FY | Replace, never duplicate; SLM floored at salvage |
| Event amount resolve | from_source field present | source field missing | zero amount | null payload | duplicate event | Skip/fail-log gracefully; never block source |
| GSTIN (enh) | 15-char valid | wrong length/format | — | empty | — | Reject invalid (ENH-001) |

---

## Section 14 — State Machine (FSM) Catalog

### FSM 1 — Voucher *(states driven by `acc_accounting_status_masters`, status type "Voucher Status": draft, posted, approved, cancelled)*
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| (new) | create | Dr=Cr, ≥2 lines | Draft | voucher number issued |
| Draft | post | year unlocked | Posted | included in balances/reports |
| Draft | cancel | — | Cancelled | excluded from all |
| Posted | cancel | year unlocked | Cancelled | reversal voucher auto-posted |
| Posted | year lock | year locked | Locked | becomes immutable |
| Locked | reverse | Finance Officer permission | new Draft reversal | original untouched |
| Locked | edit/delete | — | — | BLOCKED |
**Terminal:** Cancelled, Locked. **Illegal:** edit/delete of Locked; post in locked year.

### FSM 2 — Bank Reconciliation *(status type "Bank Reconciliation Status": Pending, In Progress, Completed)*
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Pending | import + match | reconcilable ledger | In Progress | entries created/matched |
| In Progress | complete | difference = 0 (or override) | Completed | session frozen |
**Terminal:** Completed.

### FSM 3 — Expense Claim *(status type "Expence Claim Status": Draft, Submitted, Approved, Rejected, Paid)*
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Draft | submit | own claim | Submitted | approver notified |
| Submitted | approve | approver permission | Approved | payment voucher created → Paid |
| Submitted | reject | reason given | Rejected | claimant notified |
**Terminal:** Paid, Rejected.

### FSM 4 — Cross-Module Event *(status type "Cross-Module Data Processing Status": Pending, Processed, Failed, Skipped)*
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Pending | process | active config + not duplicate | Processed | voucher created + linked |
| Pending | process | no config / duplicate | Skipped | logged, no voucher |
| Pending | process | error | Failed | logged + retry_count++ |
| Failed | retry | retries < cap | Processed/Failed | re-attempt |
**Terminal:** Processed, Skipped.

### FSM 5 — Budget Plan
Draft → Submitted → Active (approve) / Draft (reject). Terminal: Active.

---

## Section 15 — Data Dictionary (Business View)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|----------------|---------|------|----------|----------------|------|
| Voucher Number | Unique per type + year | text | Yes (auto) | system-generated | No |
| Voucher Date | Transaction date | date | Yes | within FY | No |
| Voucher Type | Receipt/Payment/etc. | choice | Yes | 8 system + custom | No |
| Narration | Description | text | No | free text | No |
| Line Side | Debit or Credit | choice | Yes | Debit / Credit | No |
| Line Amount | Money on the line | money | Yes | > 0 | No |
| Ledger Balance Type | Opening side | choice | Yes | Dr / Cr | No |
| Bank Account Number | Bank a/c of a bank ledger | text | If bank | digits | Yes (Confidential) |
| IFSC | Bank branch code | text | If bank | IFSC format | No |
| Opening Balance | Ledger starting balance | money | No | ≥ 0 | No |
| Financial Year | Accounting year | choice | Yes | 1-Apr–31-Mar | No |
| Year Locked? | Closed flag | yes/no | Yes | Yes/No | No |
| Cost Centre | Department/activity | choice | No | configured list | No |
| Budget Amount | Planned spend | money | Yes | ≥ 0 | No |
| Depreciation Method | SLM / WDV | choice | Yes | SLM / WDV | No |
| Asset Code | Unique asset id | text | Yes | unique | No |
| Salvage Value | Residual value | money | Yes | < cost | No |
| Claim Status | Expense claim stage | choice | Yes | Draft…Paid | No |
| Receipt Attachment | Proof file | file | No | image/PDF | Yes (Confidential) |
| GSTIN | GST number | text | No | 15-char | Yes (Confidential) |
| PAN | Tax id | text | No | PAN format | Yes (Sensitive) |

> Privacy classes: Public / Internal / Confidential / Sensitive (PII). Bank details, party links, receipts, GSTIN, and PAN are Confidential/Sensitive and isolated per tenant.

---

## Section 16 — Cross-Module Dependency Map

**Inbound (Accounting reads from):**
| Source Module | Data/Entity | Why |
|---------------|-------------|-----|
| SchoolSetup | Employees (`sch_employees`) | Expense-claim claimant; salary ledgers |
| StudentProfile | Students | Student debtor sub-ledgers |
| Vendor | Vendors (`vnd_vendors`) | Vendor payable sub-ledgers; asset supplier |
| System Users | Users (`sys_users`) | created/approved/locked-by stamps |

**Outbound / event-driven (Accounting receives events and posts vouchers):**
| Partner Module | Mechanism | What |
|----------------|-----------|------|
| StudentFee | Event → cross-module engine | Fee payment → Receipt voucher |
| HR / Payroll | Event → engine | Salary processed → Journal voucher (with TDS/PF split) |
| Inventory | Event → engine | Purchase order paid → Purchase + Payment vouchers |
| Transport | Event → engine | Transport fee paid → Receipt voucher |
| Library / Hostel | Event → engine | Fines/fees → Receipt voucher |
| Notification | Service | Over-budget and approval alerts |
| Tally (external) | XML export | Ledgers + vouchers to TallyPrime |

> **Architecture note:** integration is config-driven via the generic event engine (REQ-ACC-017: `acc_module_events` → `acc_event_voucher_configs` → `acc_event_voucher_line_templates` + `acc_event_processing_log` + `RemoteEntryService`), not the hardcoded Laravel listeners the V2 requirement described.

---

## Section 17 — Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|----------|:---:|:---:|------------|-------|
| RISK-ACC-001 | Unbalanced/incorrect postings corrupt the books | Data integrity | M | H | Service-layer Dr=Cr enforcement + Trial Balance check (BR-013/025) | Accountant |
| RISK-ACC-002 | Controllers are stubs; routes/views exist but logic incomplete | Delivery | M | H | Technical audit per REQ-ID; prioritise P0 services | Tech Lead |
| RISK-ACC-003 | No migrations — schema lives only in tenant DDL; drift between DDL and models | Maintainability | M | M | Treat DDL as source of truth; reconcile models (done 2026-06-29) | DB Architect |
| RISK-ACC-004 | GST/TDS/Year-End tables absent → statutory features unbuildable | Compliance | H | M | Schedule ENH-001/002/003 schema in DDL v4 | DB Architect |
| RISK-ACC-005 | Cross-module event misconfiguration silently skips vouchers | Integration | M | M | Opt-in config + processing log + skip/fail visibility (BR-042/044) | Accountant |
| RISK-ACC-006 | Locked-year integrity bypass | Compliance/Audit | L | H | Hard block + reversal-only path (BR-016/022) | Finance Officer |
| RISK-ACC-007 | Depreciation re-run duplicates entries | Data integrity | L | M | Idempotent run (BR-039) — verify in audit | Accountant |
| RISK-ACC-008 | Bank reconciliation override misused to hide differences | Control | L | M | Permission-gated override + recon statement audit (BR-035) | Finance Officer |

---

## Section 18 — Prioritization (MoSCoW) & Effort / Sprint Tasks

**MoSCoW**
- **Must (P0):** REQ-ACC-001, 002, 004, 005, 006, 007, 011, 017, 019.
- **Should (P1):** REQ-ACC-003, 008, 009, 010, 012, 013, 014, 015, 016, 018, 020, 021, 022.
- **Could (P2 / next):** asset disposal (ENH-006), comparative reports.
- **Won't (this release):** GST returns/e-invoicing (ENH-001), TDS forms (ENH-002), automated year-end wizard (ENH-003), scheduled jobs (ENH-004) — deferred pending schema.

**Indicative Sprint Tasks** *(effort relative to comparable modules; assumes DDL exists, no migrations)*
| # | Task | Type | Effort | Depends on | Sprint |
|---|------|------|:---:|------------|:---:|
| 1 | Audit & complete VoucherService (Dr=Cr, numbering, reversal) | Backend | H | REQ-006/007 | 1 |
| 2 | Verify COA + Ledger CRUD logic & guards | Backend | M | REQ-001/002 | 1 |
| 3 | Financial-year lock pre-checks | Backend | M | REQ-004 | 1 |
| 4 | Reconciliation CSV parser + auto-match audit | Backend | M | REQ-011 | 2 |
| 5 | Report math (TB/P&L/BS) verification | Backend | M | REQ-019 | 2 |
| 6 | Event-engine integration (RemoteEntryService↔config) | Integration | M | REQ-017 | 3 |
| 7 | Budget variance + over-budget alert wiring | Backend | M | REQ-010 | 3 |
| 8 | Depreciation idempotency tests | Testing | M | REQ-013 | 4 |
| 9 | DDL v4 decision: add GST/TDS/YearEnd tables | Schema | M | ENH-001/002/003 | 5 |
| 10 | Test hardening + PDF reports | Testing | M | all | 5 |

---

## Section 19 — User Stories + Acceptance Criteria (P0/P1)

**US-ACC-001 (REQ-ACC-006, P0)** — As a Finance Officer, I want to record a balanced voucher so that the books stay accurate.
- Scenario: happy path — Given a draft with Dr 5000 and Cr 5000, When I save, Then the voucher is stored with an auto number.
- Scenario: boundary — Given Dr 5000 and Cr 4900, When I save, Then save is refused with a mismatch message.
- Scenario: permission denied — Given a user without voucher-create permission, When they open the form, Then access is refused.
- DoD: number issued; Dr=Cr enforced; year unlocked; audit stamp recorded.

**US-ACC-002 (REQ-ACC-007, P0)** — As a Finance Officer, I want to cancel a posted voucher so that an error is corrected without deleting history.
- Scenario: Given a posted voucher, When I cancel it, Then a reversal is auto-posted and the original is marked cancelled.
- Scenario: locked year — Given a voucher in a locked year, When I try to cancel, Then only reversal is offered.
- DoD: reversal balanced; original excluded from balances.

**US-ACC-003 (REQ-ACC-004, P0)** — As an Accountant, I want to lock a financial year so that closed books cannot change.
- Scenario: Given a year with no drafts, When I lock it, Then its vouchers become immutable.
- Scenario: Given a year with a draft, When I try to lock, Then locking is blocked with the draft list.
- DoD: lock recorded; writes refused post-lock.

**US-ACC-004 (REQ-ACC-011, P0)** — As a Finance Officer, I want to reconcile a bank account so that book and bank balances agree.
- Scenario: Given an imported statement, When auto-match runs, Then each line is flagged matched/unmatched.
- Scenario: Given a non-zero difference, When I complete, Then completion is blocked unless I have override.
- DoD: completion only at zero difference (or override); statement produced.

**US-ACC-005 (REQ-ACC-017, P0)** — As an Accountant, I want events from other modules to auto-create vouchers so that I don't re-key.
- Scenario: Given a configured fee-paid event, When it fires, Then a balanced Receipt voucher is created and logged Processed.
- Scenario: Given no config, When it fires, Then it is logged Skipped and the source module is unaffected.
- DoD: opt-in config; processing log written; source never blocked.

**US-ACC-006 (REQ-ACC-010, P1)** — As a Principal, I want to approve budgets and see over-spend alerts so that I control spending.
- Scenario: Given a submitted budget, When I approve, Then it becomes active.
- Scenario: Given 90%+ utilisation, When spend posts, Then an alert is raised.
- DoD: one active budget per FY+CC+ledger; alert fired.

**US-ACC-007 (REQ-ACC-013, P1)** — As an Accountant, I want depreciation to run safely so that asset values are correct.
- Scenario: Given a re-run for the same year, When I run it, Then prior entries are replaced, not duplicated.
- Scenario: Given an SLM asset at salvage floor, When I run, Then value does not drop below salvage.
- DoD: idempotent; balanced journal posted.

**US-ACC-008 (REQ-ACC-014, P1)** — As a Staff Member, I want to submit an expense claim so that I'm reimbursed.
- Scenario: Given my draft claim, When I submit, Then the approver is notified.
- Scenario: Given approval, When approved, Then a payment voucher is auto-created.
- Scenario: permission — Given another staff's claim, When I try to edit, Then it is refused.
- DoD: own-claim only; reject needs reason; approval posts payment voucher.

*(Stories for remaining P1 REQs follow the same pattern: REQ-001/002/003/005/008/009/012/015/016/018/020/021/022 each get happy-path + boundary + permission-denied + empty-state criteria.)*

---

## Section 20 — Technical Data Dictionary (TECHNICAL register)

> Reverse-mapping permitted in this section only. Schema source of truth = `Accounting_DDL_v3.sql` (28 tables; **0 migrations**). 25 tables have Eloquent models; 3 do not.

### 20.1 Table → Model map
| # | Table | Model | Domain |
|---|-------|-------|--------|
| 1 | `acc_accounting_status_masters` | *(none — query/seed)* | Infra/Status |
| 2 | `acc_voucher_modules` | *(none — query/seed)* | Infra/Registry |
| 3 | `acc_voucher_category` | *(none — query/seed)* | Infra/Registry |
| 4 | `acc_financial_years` | FinancialYear | Core |
| 5 | `acc_account_groups` | AccountGroup | Core |
| 6 | `acc_ledgers` | Ledger | Core |
| 7 | `acc_voucher_types` | VoucherType | Core |
| 8 | `acc_cost_centers` | CostCenter | Core |
| 9 | `acc_vouchers` | Voucher | Core |
| 10 | `acc_voucher_items` | VoucherItem | Core |
| 11 | `acc_budgets` | Budget | Core |
| 12 | `acc_tax_rates` | TaxRate | Core |
| 13 | `acc_ledger_mappings` | LedgerMapping | Core/Integration |
| 14 | `acc_recurring_templates` | RecurringTemplate | Core |
| 15 | `acc_recurring_template_lines` | RecurringTemplateLine | Core |
| 16 | `acc_bank_reconciliations` | BankReconciliation | Banking |
| 17 | `acc_bank_statement_entries` | BankStatementEntry | Banking |
| 18 | `acc_asset_categories` | AssetCategory | Fixed Assets |
| 19 | `acc_fixed_assets` | FixedAsset | Fixed Assets |
| 20 | `acc_depreciation_entries` | DepreciationEntry | Fixed Assets |
| 21 | `acc_expense_claims` | ExpenseClaim | Expense Claims |
| 22 | `acc_expense_claim_lines` | ExpenseClaimLine | Expense Claims |
| 23 | `acc_tally_export_logs` | TallyExportLog | Tally |
| 24 | `acc_tally_ledger_mappings` | TallyLedgerMapping | Tally |
| 25 | `acc_module_events` | ModuleEvent | Event Engine |
| 26 | `acc_event_voucher_configs` | EventVoucherConfig | Event Engine |
| 27 | `acc_event_voucher_line_templates` | EventVoucherLineTemplate | Event Engine |
| 28 | `acc_event_processing_log` | EventProcessingLog | Event Engine |

### 20.2 Key schema facts the audit must honour
- **Status pattern (D4/D29):** `acc_vouchers.status`, `acc_bank_reconciliations.status`, `acc_expense_claims.status`, `acc_tally_export_logs.status`, `acc_event_processing_log.status` are all **INT FK → `acc_accounting_status_masters.id`** — not ENUMs. The V2 §5 ENUMs are superseded.
- **Voucher line side:** `acc_voucher_items.type` = `ENUM('debit','credit')` (NOT `side` Dr/Cr).
- **Account nature:** `acc_account_groups.nature` = `ENUM('Asset','Liability','Equity','Income','Expense')` + `affects_gross_profit` flag.
- **Voucher categorisation:** `acc_voucher_types.voucher_category_id` and (per DDL change log) `acc_vouchers` reference `acc_voucher_category`; the old `category` ENUM was removed.
- **Voucher source tracing:** `acc_vouchers.source_module` (FK → `acc_voucher_modules`), `source_type`, `source_id`.
- **Ledger entity links:** `acc_ledgers.student_id` / `employee_id` / `vendor_id` enable party sub-ledgers used by the event engine's dynamic ledger resolvers.
- **Event line resolvers:** `acc_event_voucher_line_templates.ledger_resolver` ∈ {fixed, student_ledger, vendor_ledger, employee_ledger}; `amount_resolver` ∈ {from_source, fixed_amount, from_payload}.
- **Known DDL hygiene issues (flag to DB Architect):** stray typos in DDL v3 — `auto_numbering.` (period), `acc_voucher_category` FK references column `module_id` while the column is named `voucher_module_id`, `acc_voucher_types` index `idx_acc_vt_category` references removed `category` column, and `acc_financial_years.start_date` comment uses a bare string. These are schema-correctness items, not requirement gaps.
- **Absent tables (enhancements):** `acc_gst_details`, `acc_tds_entries`, `acc_year_end_closings` — required for ENH-ACC-001/002/003.

### 20.3 Code inventory (verified 2026-06-29)
Controllers 21 · Models 25 · Services 7 (`VoucherService`, `ReconciliationService`, `DepreciationService`, `ExpenseClaimService`, `RecurringTemplateService`, `ReportService`, `RemoteEntryService`) · FormRequests 17 · Policies 19 · Views 141 · Tests 21 (Unit+Feature) · Migrations 0 · Routes 87 named + 15 `Route::resource` (web.php, 220 lines) · api.php 8 lines/0 named routes.

---

*Document end. Complete Analysis Pack for Accounting (ACC). 22 REQ · 40 BR (+4 conditions) · 14 RPT · 6 ENH · 5 workflows · 12 NFR · 8 RISK · 8 user stories. IDs are stable — downstream agents reuse, never renumber.*
