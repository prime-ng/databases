# Account Module — Detailed Requirement Document v4

**Module:** Accounting | **Laravel Module:** `Modules/Accounting/` | **Prefix:** `acc_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/accounting/*` | **RBS Module:** K — Finance & Accounting (70 sub-tasks)
**Inspired by:** Tally Prime | **Date:** 2026-03-20 | **Version:** 4.0

**Changes from v3:** Completely independent file — all "Same as v2" removed. All SQL DDL converted to markdown table format. Fixed FK references in asset/expense/tally tables (old `journal_entries` → new `acc_vouchers`). Fixed `acc_bank_statement_entries` stray FK. Fixed section numbering. Added missing `created_by`/`deleted_at` columns. Old `Account_ddl_v1.sql` is unused and can be replaced entirely.

---

## 1. Module Overview & Purpose

The Accounting module implements a **Tally-Prime inspired double-entry bookkeeping system** for Indian K-12 schools. Every financial transaction (fee collection, salary payment, stock purchase, transport fee, expense) flows through a unified **Voucher Engine** as Dr/Cr pairs, ensuring the accounting equation (Assets = Liabilities + Equity) always holds.

**Core Principle:** The Accounting module owns the Voucher Engine. **Payroll** (`Modules/Payroll/`) and **Inventory** (`Modules/Inventory/`) are separate modules that consume the Voucher Engine via a shared `VoucherServiceInterface` contract.

**Indian School Context:**
- Schools are typically registered as Trusts or Societies (Income & Expenditure model, not P&L)
- GST applicable on some services (transport, canteen), exempt on tuition
- Statutory deductions: PF, ESI, Professional Tax, TDS
- Financial year: April 1 to March 31
- Common accounting software: Tally Prime — our UI/UX mirrors its concepts
- **Tally Mapping:** Schools often export data to Tally for CA filing — our module provides bidirectional ledger mapping

**Multi-Tenancy:**
- Dedicated database per tenant ensures complete data isolation
- NO `tenant_id` column in any table
- Chart of Accounts seeded during tenant provisioning
- Tally ledger mappings seeded with defaults, customizable per tenant

---

## 2. Scope & Boundaries

### In Scope
- Chart of Accounts (Hierarchical account groups + ledgers)
- Voucher Engine (Payment, Receipt, Contra, Journal, Sales, Purchase, Credit Note, Debit Note)
- VoucherServiceInterface — shared contract for Payroll & Inventory modules
- Financial Year management with locking
- Cost Center allocation (department-wise P&L)
- Budget management (allocation + variance tracking)
- Financial reports (Trial Balance, P&L, Balance Sheet, Day Book, Cash/Bank Book)
- GST & Tax configuration
- Bank reconciliation (statement import, auto-match)
- Fixed asset management with depreciation (SLM/WDV)
- Expense claim workflow
- Tally XML export with ledger mapping
- Tally Ledger Mapping (bidirectional sync mechanism)
- Recurring journal templates
- Cross-module integration (StudentFee, Vendor, Payroll, Inventory, **Transport**)

### Out of Scope (Handled by Other Modules)
- Fee structure creation, student fee assignment, fee invoice generation → **StudentFee module** (`fin_*`)
- Vendor master, agreements, vendor invoices → **Vendor module** (`vnd_*`)
- Payment gateway (Razorpay) → **Payment module** (`pmt_*`)
- Employee/Teacher profiles → **SchoolSetup module** (`sch_*`)
- Transport fee & fine management → **Transport module** (`tpt_*`)
- Salary structures, payroll runs, payslips → **Payroll module** (`prl_*`)
- Stock items, purchase orders, GRN, stock issues → **Inventory module** (`inv_*`)

### Boundary Decisions
1. **StudentFee Bridge:** `acc_ledger_mappings` (source_module='Fees') bridges fee heads to income ledgers. No `acc_fee_*` tables.
2. **Transport Bridge:** `acc_ledger_mappings` (source_module='Transport') bridges transport routes/stoppages to transport fee income ledgers.
3. **Payroll Bridge:** Payroll module fires `PayrollApproved` event → Accounting creates Journal Voucher via VoucherService.
4. **Inventory Bridge:** Inventory module fires `GrnAccepted`/`StockIssued` events → Accounting creates corresponding vouchers.
5. **sch_employees:** Existing table enhanced with payroll columns (ledger_id, bank details, statutory IDs) — NOT recreated as `acc_employees`.

---

## 3. RBS Mapping (Module K — 70 Sub-Tasks)

### K1 — Chart of Accounts (9 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K1.1.1.1 | Define primary group (Assets/Liabilities/Income/Expense) | `acc_account_groups.nature` ENUM | Covered |
| ST.K1.1.1.2 | Assign accounting nature (Debit/Credit) | Derived from `nature` (Asset/Expense=Dr, Liability/Income=Cr) | Covered |
| ST.K1.1.2.1 | Create hierarchical sub-groups | `acc_account_groups.parent_id` (self-ref) | Covered |
| ST.K1.1.2.2 | Set posting permissions | `acc_account_groups.is_subledger` + policy | Covered |
| ST.K1.2.1.1 | Define ledger name & code | `acc_ledgers.name`, `acc_ledgers.code` | Covered |
| ST.K1.2.1.2 | Assign parent account group | `acc_ledgers.account_group_id` FK | Covered |
| ST.K1.2.1.3 | Link GST/TAX configuration | `acc_ledgers.gstin`, `acc_ledgers.gst_registration_type` | Covered |
| ST.K1.2.2.1 | Enable reconciliation | `acc_ledgers.allow_reconciliation` | Covered |
| ST.K1.2.2.2 | Set allowed modules for ledger usage | `acc_ledger_mappings.source_module` | Covered |

### K2 — Opening Balances (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K2.1.1.1 | Enter debit/credit opening balance | `acc_ledgers.opening_balance`, `opening_balance_type` | Covered |
| ST.K2.1.1.2 | Validate fiscal year constraints | Business rule: opening set only for active FY | Covered |
| ST.K2.2.1.1 | Upload outstanding fee CSV | Import service + `acc_ledgers` (student sub-ledgers) | Covered |
| ST.K2.2.1.2 | Map vendor outstanding balances | Import service + `acc_ledgers` (vendor sub-ledgers) | Covered |

### K3 — Journal Entry Management (6 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K3.1.1.1 | Select debit/credit ledgers | `acc_voucher_items.ledger_id`, `type` (debit/credit) | Covered |
| ST.K3.1.1.2 | Add narration & attachments | `acc_vouchers.narration` + Spatie Media | Covered |
| ST.K3.1.2.1 | Submit JE for approval | `acc_vouchers.status` (draft→posted→approved) | Covered |
| ST.K3.1.2.2 | Track approval history | `acc_vouchers.approved_by`, `sys_activity_logs` | Covered |
| ST.K3.2.1.1 | Define recurrence cycle | `acc_recurring_templates.frequency` | Covered |
| ST.K3.2.1.2 | Auto-post according to period | RecurringJournalService (scheduled job) | Covered |

### K4 — Accounts Receivable (8 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K4.1.1.1 | Generate fee JE automatically | FeeIntegrationService → Receipt Voucher | Covered |
| ST.K4.1.1.2 | Map fee heads to income ledgers | `acc_ledger_mappings` (source_module='Fees') | Covered |
| ST.K4.1.2.1 | Accept multi-mode payments | Voucher with bank/cash ledger selection | Covered |
| ST.K4.1.2.2 | Auto-send receipt to parent | Handled by StudentFee module | Out of scope |
| ST.K4.2.1.1 | Produce 30/60/90-day aging | ReportService.outstandingAging() | Covered |
| ST.K4.2.1.2 | Identify high-risk accounts | ReportService with threshold config | Covered |
| ST.K4.2.2.1 | Send due reminders | Notification module integration | Phase 2 |
| ST.K4.2.2.2 | Escalate chronic defaulters | Dashboard alert + report | Phase 2 |

### K5 — Accounts Payable (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K5.1.1.1 | Attach bill copy | Purchase Voucher + Spatie Media | Covered |
| ST.K5.1.1.2 | Verify purchase order linkage | `acc_vouchers.source_type`='PurchaseOrder' | Covered |
| ST.K5.2.1.1 | Select payment mode | Voucher: Dr Vendor Ledger, Cr Bank/Cash | Covered |
| ST.K5.2.1.2 | Auto-generate payment voucher | VoucherService.createPaymentVoucher() | Covered |

### K6 — Vendor Management (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K6.1.1.1 | Capture vendor GST/PAN | `acc_ledgers.gstin`, `pan` (vendor ledger) | Covered |
| ST.K6.1.1.2 | Store contract terms | Handled by Vendor module (`vnd_agreements`) | Out of scope |
| ST.K6.2.1.1 | Rate quality & delivery time | Handled by Vendor module | Out of scope |
| ST.K6.2.1.2 | Update rating based on performance | Handled by Vendor module | Out of scope |

### K7 — Purchase & Expense Management (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K7.1.1.1 | Select vendor & items | Purchase Voucher with inventory integration | Covered |
| ST.K7.1.1.2 | Apply tax & discount rules | `acc_tax_rates` + voucher item amounts | Covered |
| ST.K7.2.1.1 | Upload claim receipts | `acc_expense_claim_lines` + Spatie Media | Covered |
| ST.K7.2.1.2 | Approve/Reject staff claims | `acc_expense_claims.status` workflow | Covered |

### K8 — Bank & Cash Management (6 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K8.1.1.1 | Upload CSV/MT940 | ReconciliationService.importStatement() | Covered |
| ST.K8.1.1.2 | Auto-match transactions | ReconciliationService.autoMatch() | Covered |
| ST.K8.1.2.1 | Mark matched items | `acc_bank_statement_entries.is_matched` | Covered |
| ST.K8.1.2.2 | Identify mismatches | BRS report (unreconciled items) | Covered |
| ST.K8.2.1.1 | Record cash inflow/outflow | Receipt/Payment vouchers via Cash A/c ledger | Covered |
| ST.K8.2.1.2 | Track daily cash balance | ReportService.cashBook() with running balance | Covered |

### K9 — Asset Register & Depreciation (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K9.1.1.1 | Enter asset details | `acc_fixed_assets` (name, code, purchase_date, cost, etc.) | Covered |
| ST.K9.1.1.2 | Assign asset category | `acc_fixed_assets.asset_category_id` FK | Covered |
| ST.K9.2.1.1 | Apply SLM/WDV methods | `acc_asset_categories.depreciation_method` (SLM/WDV) | Covered |
| ST.K9.2.1.2 | Generate depreciation JE | DepreciationService → Journal Voucher | Covered |

### K10 — Financial Reporting (5 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K10.1.1.1 | Trial Balance | ReportService.trialBalance(fromDate, toDate) | Covered |
| ST.K10.1.1.2 | Profit & Loss | ReportService.profitAndLoss(fromDate, toDate) | Covered |
| ST.K10.1.1.3 | Balance Sheet | ReportService.balanceSheet(asOnDate) | Covered |
| ST.K10.2.1.1 | Revenue vs Expense analysis | Dashboard chart (Income vs Expense by month) | Covered |
| ST.K10.2.1.2 | Cashflow trend visualization | Dashboard chart (Cash/Bank balance trend) | Covered |

### K11 — Integrations / Tally (4 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K11.1.1.1 | Export JE/Receipts in XML | TallyExportService.exportVouchers() | Covered |
| ST.K11.1.1.2 | Download Tally-compatible files | `acc_tally_export_logs` + download | Covered |
| ST.K11.2.1.1 | Synchronize ledgers | `acc_tally_ledger_mappings` + TallyExportService | Covered |
| ST.K11.2.1.2 | Sync transactions via API | Stub — defer QuickBooks/Zoho API to later | Stub |

### K12 — Budget & Cost Center Management (6 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K12.1.1.1 | Set overall institutional budget | `acc_budgets` per fiscal_year + cost_center + ledger | Covered |
| ST.K12.1.1.2 | Allocate budgets to departments/cost centers | `acc_budgets.cost_center_id` FK | Covered |
| ST.K12.1.2.1 | Record commitments and actual expenditures | Computed from voucher_items against budget ledgers | Covered |
| ST.K12.1.2.2 | Calculate available balance per cost center | BudgetService.getAvailableBalance() | Covered |
| ST.K12.2.1.1 | Show budget vs. actual with variance % | ReportService.budgetVariance() | Covered |
| ST.K12.2.1.2 | Highlight departments exceeding thresholds | Dashboard alert cards | Covered |

### K13 — GST & Tax Compliance (6 sub-tasks)

| RBS ID | Sub-Task | Entity/Column | Status |
|--------|----------|---------------|--------|
| ST.K13.1.1.1 | Define HSN/SAC codes for fee heads | `acc_tax_rates.hsn_sac_code` | Covered |
| ST.K13.1.1.2 | Configure tax rates per location | `acc_tax_rates` (CGST/SGST/IGST/Cess) | Covered |
| ST.K13.1.2.1 | Generate IRN via government portal | Stub — defer e-invoicing to later | Stub |
| ST.K13.1.2.2 | Attach QR code to invoices | Stub — defer to later | Stub |
| ST.K13.2.1.1 | Compile data for GSTR-1 | GSTComplianceService.getGSTR1Data() | Covered |
| ST.K13.2.1.2 | Compile data for GSTR-3B | GSTComplianceService.getGSTR3BData() | Covered |

---

## 4. Entity List — VERIFIED against `tenant_db_v2.sql`

### Existing Tables REUSED (verified as present in DDL)

| Table | Line # | Used For | Changes Needed |
|-------|--------|----------|----------------|
| `sch_employees` | 955 | Employee ledger auto-creation, expense claims | **ALTER TABLE** — add payroll columns (see Section 14) |
| `sch_department` | 476 | Cost center mapping (**SINGULAR name**) | None |
| `sch_designation` | 486 | Employee title (**SINGULAR name**) | None |
| `sch_categories` | 584 | Staff grouping (used by `sch_leave_config`) | None |
| `std_students` | 4618 | Student debtor ledger auto-creation | None |
| `vnd_vendors` | 1810 | Vendor creditor ledger auto-creation | None |
| `sys_users` | 87 | created_by, approved_by | None |

> **CRITICAL:** `sch_teachers` does NOT exist as a separate table. Use `sch_employees` where `is_teacher = 1` + `sch_teacher_profile` for teacher-specific data. The `acc_ledgers.employee_id` FK points to `sch_employees.id`.

### Old acc_* Tables in tenant_db_v2.sql — REPLACED by Voucher-Based Schema

The current DDL (lines 9631-10258) contains 31 `acc_*` tables using a journal-entry model. Our new Tally-inspired design **replaces** these with 21 voucher-based tables:

**Tables REMOVED (old model):**
- `acc_journal_entries`, `acc_journal_entry_lines` → replaced by `acc_vouchers` + `acc_voucher_items`
- `acc_sales_invoices`, `acc_purchase_invoices` → handled via voucher type=SALES/PURCHASE
- `acc_invoice_tax_lines`, `acc_invoice_lines` → voucher items with ledger references
- `acc_payment_transactions`, `acc_receipts` → voucher type=RECEIPT/PAYMENT
- `acc_fee_heads`, `acc_fee_structures`, `acc_fee_structure_lines`, `acc_discount_types`, `acc_student_fee_concessions` → **EXCLUDED** (fee managed by StudentFee `fin_*`)
- `acc_recurring_journal_templates` + lines → renamed to `acc_recurring_templates` + lines
- `acc_reconciliation_matches` → restructured as `acc_bank_statement_entries`

**Tables KEPT (restructured for voucher model):**
- `acc_account_groups` — enhanced with `alias`, `affects_gross_profit`, `is_system`, `is_subledger`, `sequence`
- `acc_ledgers` — enhanced with bank fields, `student_id`, `employee_id`, `vendor_id`
- `acc_tax_rates` — enhanced with `hsn_sac_code`
- `acc_ledger_mappings` — expanded `source_module` enum
- `acc_cost_centers` — enhanced with `parent_id`, `category`
- `acc_budgets` — kept
- `acc_expense_claims` + lines — kept (employee_id → `sch_employees`)
- `acc_bank_reconciliations` — restructured
- `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries` — kept
- `acc_tally_export_logs` — kept

**Tables ADDED (new):**
- `acc_financial_years` — FY config with locking
- `acc_voucher_types` — Payment, Receipt, Contra, Journal, Sales, Purchase, etc.
- `acc_vouchers` — THE heart of double-entry
- `acc_voucher_items` — Dr/Cr line items
- `acc_bank_statement_entries` — imported bank transactions
- `acc_tally_ledger_mappings` — our ledgers ↔ Tally names

### New Accounting Tables (21 total)

### 4.1 acc_financial_years
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(50) | e.g., "2025-26" |
| start_date | DATE | April 1 |
| end_date | DATE | March 31 |
| is_locked | TINYINT(1) | Prevents edits when locked |
| is_active | TINYINT(1) | Soft active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.2 acc_account_groups
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | Group name |
| code | VARCHAR(20) UNIQUE | Unique group code (A01, L02) |
| alias | VARCHAR(100) NULL | Alternative display name |
| parent_id | BIGINT UNSIGNED NULL | Self-referencing hierarchy |
| nature | ENUM('asset','liability','income','expense') | Account nature |
| affects_gross_profit | TINYINT(1) | Direct vs Indirect classification |
| is_system | TINYINT(1) | true = seeded, cannot delete |
| is_subledger | TINYINT(1) | Behaves as sub-ledger |
| sequence | INT | Display order in reports |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.3 acc_ledgers
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(150) | Ledger name |
| code | VARCHAR(20) NULL | Unique ledger code |
| alias | VARCHAR(150) NULL | Alternative name |
| account_group_id | BIGINT UNSIGNED FK | FK → acc_account_groups |
| opening_balance | DECIMAL(15,2) | Opening balance amount |
| opening_balance_type | ENUM('Dr','Cr') NULL | Debit or Credit opening |
| is_bank_account | TINYINT(1) | Bank account flag |
| bank_name | VARCHAR(100) NULL | Bank details |
| bank_account_number | VARCHAR(50) NULL | Account number |
| ifsc_code | VARCHAR(20) NULL | IFSC code |
| is_cash_account | TINYINT(1) | Cash account flag |
| allow_reconciliation | TINYINT(1) | Enable bank reconciliation |
| is_system | TINYINT(1) | P&L A/c, Cash A/c etc. — cannot delete |
| student_id | BIGINT UNSIGNED NULL | FK → std_students (auto-ledger for student debtors) |
| employee_id | BIGINT UNSIGNED NULL | FK → **sch_employees** (auto-ledger for salary payable) |
| vendor_id | BIGINT UNSIGNED NULL | FK → vnd_vendors (auto-ledger for vendor creditors) |
| gst_registration_type | VARCHAR(30) NULL | Regular, Composition, etc. |
| gstin | VARCHAR(20) NULL | GST number |
| pan | VARCHAR(15) NULL | PAN number |
| address | TEXT NULL | Ledger address |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

> **Note:** `employee_id` references `sch_employees` (existing SchoolSetup table), NOT a new `acc_employees` table.

### 4.4 acc_voucher_types
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(80) | e.g., "Payment Voucher" |
| code | VARCHAR(20) UNIQUE | PAYMENT, RECEIPT, CONTRA, JOURNAL, etc. |
| category | ENUM('accounting','inventory','payroll','order') | Domain |
| prefix | VARCHAR(20) NULL | Voucher number prefix (PAY-, RCV-) |
| auto_numbering | TINYINT(1) | Auto-increment enabled |
| last_number | INT | Current counter |
| is_system | TINYINT(1) | Cannot delete |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.5 acc_vouchers (THE HEART)
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| voucher_number | VARCHAR(50) | Auto-generated, unique per FY |
| voucher_type_id | BIGINT UNSIGNED FK | FK → acc_voucher_types |
| financial_year_id | BIGINT UNSIGNED FK | FK → acc_financial_years |
| date | DATE | Transaction date |
| reference_number | VARCHAR(100) NULL | Cheque no, receipt no |
| reference_date | DATE NULL | Cheque date |
| narration | TEXT NULL | Transaction description |
| total_amount | DECIMAL(15,2) | Total voucher amount |
| is_post_dated | TINYINT(1) | Post-dated cheque flag |
| is_optional | TINYINT(1) | Memorandum voucher |
| is_cancelled | TINYINT(1) | Cancelled flag |
| cancelled_reason | TEXT NULL | Cancellation reason |
| cost_center_id | BIGINT UNSIGNED NULL FK | FK → acc_cost_centers |
| source_module | VARCHAR(50) NULL | 'StudentFee', 'Payroll', 'Inventory', 'Transport', 'Manual' |
| source_type | VARCHAR(100) NULL | Polymorphic model: 'PayrollRun', 'FeeTransaction', 'GRN', etc. |
| source_id | BIGINT UNSIGNED NULL | Polymorphic source ID |
| status | ENUM('draft','posted','approved','cancelled') | Workflow status |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |
| UNIQUE | (voucher_number, financial_year_id, deleted_at) | Unique per FY |

### 4.6 acc_voucher_items
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| voucher_id | BIGINT UNSIGNED FK | FK → acc_vouchers (CASCADE) |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers |
| type | ENUM('debit','credit') | Dr or Cr |
| amount | DECIMAL(15,2) | Line amount |
| narration | VARCHAR(500) NULL | Per-ledger narration |
| cost_center_id | BIGINT UNSIGNED NULL FK | FK → acc_cost_centers |
| bill_reference | VARCHAR(100) NULL | Against invoice/bill |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.7 acc_cost_centers
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "Primary Wing", "Transport" |
| code | VARCHAR(20) NULL | Cost center code |
| parent_id | BIGINT UNSIGNED NULL | Self-referencing hierarchy |
| category | VARCHAR(50) NULL | Department, Activity, Project |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.8 acc_budgets
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| financial_year_id | BIGINT UNSIGNED FK | FK → acc_financial_years |
| cost_center_id | BIGINT UNSIGNED FK | FK → acc_cost_centers |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers |
| budgeted_amount | DECIMAL(15,2) | Allocated budget |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |
| UNIQUE | (financial_year_id, cost_center_id, ledger_id) | One budget per combo |

### 4.9 acc_tax_rates
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | e.g., "CGST 9%" |
| rate | DECIMAL(5,2) | Tax rate percentage |
| type | ENUM('CGST','SGST','IGST','Cess') | Tax type |
| hsn_sac_code | VARCHAR(20) NULL | HSN/SAC code |
| is_interstate | TINYINT(1) | Interstate supply flag |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.10 acc_ledger_mappings
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers |
| source_module | ENUM('Fees','Library','Transport','HR','Vendor','Inventory','Payroll') | Source module |
| source_type | VARCHAR(100) NULL | e.g., 'FeeHead', 'PayHead', 'Route', 'Stoppage' |
| source_id | BIGINT UNSIGNED | Source entity ID |
| description | VARCHAR(255) NULL | Human-readable mapping description |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |
| UNIQUE | (ledger_id, source_module, source_type, source_id) | One mapping per combination |

### 4.11 acc_recurring_templates
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(150) | Template name |
| voucher_type_id | BIGINT UNSIGNED FK | FK → acc_voucher_types |
| frequency | ENUM('Daily','Weekly','Monthly','Quarterly','Yearly') | Recurrence |
| start_date | DATE | Start posting from |
| end_date | DATE NULL | Stop posting after |
| day_of_month | TINYINT NULL | Day to post (for monthly) |
| narration | TEXT NULL | Default narration |
| total_amount | DECIMAL(15,2) | Template total |
| last_posted_date | DATE NULL | Last auto-post date |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.12 acc_recurring_template_lines
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| recurring_template_id | BIGINT UNSIGNED FK | FK → acc_recurring_templates (CASCADE) |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers |
| type | ENUM('debit','credit') | Dr or Cr |
| amount | DECIMAL(15,2) | Line amount |
| narration | VARCHAR(500) NULL | Per-line narration |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |

### 4.13 acc_bank_reconciliations
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers (bank account ledger) |
| statement_date | DATE | Bank statement date |
| closing_balance | DECIMAL(15,2) | Closing balance per bank statement |
| statement_path | VARCHAR(255) NULL | Uploaded statement file path |
| status | ENUM('In Progress','Completed') DEFAULT 'In Progress' | Reconciliation status |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.14 acc_bank_statement_entries
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| reconciliation_id | BIGINT UNSIGNED FK | FK → acc_bank_reconciliations (CASCADE) |
| transaction_date | DATE | Bank transaction date |
| description | VARCHAR(500) NULL | Transaction description from bank |
| reference | VARCHAR(255) NULL | Bank reference number |
| debit | DECIMAL(15,2) DEFAULT 0.00 | Debit amount (withdrawal) |
| credit | DECIMAL(15,2) DEFAULT 0.00 | Credit amount (deposit) |
| balance | DECIMAL(15,2) NULL | Running balance per statement |
| is_matched | TINYINT(1) DEFAULT 0 | Whether matched to a voucher item |
| matched_voucher_item_id | BIGINT UNSIGNED NULL FK | FK → acc_voucher_items (matched entry) |
| matched_at | TIMESTAMP NULL | When the match was made |
| matched_by | BIGINT UNSIGNED NULL | FK → sys_users (who matched) |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.15 acc_asset_categories
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(100) | Category name (e.g., "Furniture", "IT Equipment") |
| code | VARCHAR(20) UNIQUE | Category code |
| depreciation_method | ENUM('SLM','WDV') | Straight Line / Written Down Value |
| depreciation_rate | DECIMAL(5,2) | Annual depreciation rate % |
| useful_life_years | INT NULL | Useful life in years |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.16 acc_fixed_assets
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| name | VARCHAR(150) | Asset name |
| asset_code | VARCHAR(50) UNIQUE | Asset identification code |
| asset_category_id | BIGINT UNSIGNED FK | FK → acc_asset_categories |
| purchase_date | DATE | Date of purchase |
| purchase_cost | DECIMAL(15,2) | Original purchase cost |
| salvage_value | DECIMAL(15,2) DEFAULT 0.00 | Estimated residual value |
| current_value | DECIMAL(15,2) | Current book value |
| accumulated_depreciation | DECIMAL(15,2) DEFAULT 0.00 | Total depreciation to date |
| location | VARCHAR(100) NULL | Physical location of asset |
| vendor_id | BIGINT UNSIGNED NULL FK | FK → vnd_vendors (supplier) |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → **acc_vouchers** (purchase voucher) |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.17 acc_depreciation_entries
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| fixed_asset_id | BIGINT UNSIGNED FK | FK → acc_fixed_assets (CASCADE) |
| financial_year_id | BIGINT UNSIGNED FK | FK → **acc_financial_years** |
| depreciation_date | DATE | Date of depreciation entry |
| depreciation_amount | DECIMAL(15,2) | Depreciation amount for this period |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → **acc_vouchers** (depreciation journal voucher) |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.18 acc_expense_claims
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| claim_number | VARCHAR(50) UNIQUE | Auto-generated claim number |
| employee_id | BIGINT UNSIGNED FK | FK → **sch_employees** (existing, not acc_employees) |
| claim_date | DATE | Date of claim submission |
| total_amount | DECIMAL(15,2) | Total claim amount |
| status | ENUM('Draft','Submitted','Approved','Rejected','Paid') | Claim workflow status |
| approved_by | BIGINT UNSIGNED NULL | FK → sys_users |
| approved_at | TIMESTAMP NULL | Approval timestamp |
| voucher_id | BIGINT UNSIGNED NULL FK | FK → **acc_vouchers** (payment voucher on approval) |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.19 acc_expense_claim_lines
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| expense_claim_id | BIGINT UNSIGNED FK | FK → acc_expense_claims (CASCADE) |
| expense_date | DATE | Date of expense |
| ledger_id | BIGINT UNSIGNED FK | FK → **acc_ledgers** (expense category ledger) |
| description | VARCHAR(255) | Expense description |
| amount | DECIMAL(15,2) | Expense amount |
| tax_amount | DECIMAL(15,2) DEFAULT 0.00 | Tax on expense |
| receipt_path | VARCHAR(255) NULL | Uploaded receipt file path |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.20 acc_tally_export_logs
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| export_type | ENUM('Ledgers','Vouchers','Inventory') | What was exported |
| export_date | DATETIME | When export was run |
| file_name | VARCHAR(255) | Generated file name |
| exported_by | BIGINT UNSIGNED FK | FK → sys_users |
| start_date | DATE NULL | Export date range start |
| end_date | DATE NULL | Export date range end |
| record_count | INT NULL | Number of records exported |
| status | ENUM('Success','Failed','Partial') | Export result |
| error_log | TEXT NULL | Error details if failed |
| is_active | TINYINT(1) DEFAULT 1 | Active flag |
| created_by | BIGINT UNSIGNED NULL | FK → sys_users |
| created_at, updated_at, deleted_at | TIMESTAMP | Standard columns |

### 4.21 acc_tally_ledger_mappings
| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers (our application ledger) |
| tally_ledger_name | VARCHAR(200) | Exact Tally ledger name for export/import |
| tally_group_name | VARCHAR(200) NULL | Tally parent group name |
| tally_alias | VARCHAR(200) NULL | Tally alias if any |
| mapping_type | ENUM('auto','manual') | Auto (seeded) or manual (user-configured) |
| sync_direction | ENUM('export_only','import_only','bidirectional') DEFAULT 'export_only' | Sync direction |
| last_synced_at | TIMESTAMP NULL | Last successful sync timestamp |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard columns |
| UNIQUE | (ledger_id) | One Tally mapping per ledger |

---

**Key correction in acc_ledgers:**
- `employee_id` → FK to **`sch_employees`** (not `acc_employees` — that table doesn't exist)
- `vendor_id` → FK to **`vnd_vendors`**
- `student_id` → FK to **`std_students`**

**Key correction in acc_ledger_mappings:**
- `source_module` ENUM includes: `'Fees','Library','Transport','HR','Vendor','Inventory','Payroll'`

**Key correction in acc_expense_claims:**
- `employee_id` → FK to **`sch_employees`** (not `acc_employees`)

---

## 5. Entity Relationship Diagram

```
acc_account_groups (self-ref parent_id)
    │
    ├── acc_ledgers ──── acc_tally_ledger_mappings (1:1 Tally name)
    │       │
    │       ├── std_students (student_id FK — student debtor auto-ledger)
    │       ├── sch_employees (employee_id FK — salary payable auto-ledger)
    │       ├── vnd_vendors (vendor_id FK — vendor creditor auto-ledger)
    │       │
    │       ├── acc_voucher_items ──── acc_vouchers ──── acc_voucher_types
    │       │                              │
    │       │                              ├── acc_financial_years
    │       │                              └── source_module + source_type + source_id (polymorphic)
    │       │
    │       ├── acc_budgets ──── acc_financial_years + acc_cost_centers
    │       ├── acc_ledger_mappings (→ Fees, Vendor, Transport, Inventory, Payroll)
    │       ├── acc_bank_reconciliations → acc_bank_statement_entries
    │       └── acc_recurring_templates → acc_recurring_template_lines
    │
    └── acc_cost_centers (self-ref parent_id)

acc_asset_categories → acc_fixed_assets → acc_depreciation_entries → acc_vouchers
acc_expense_claims (employee_id → sch_employees) → acc_expense_claim_lines → acc_ledgers

External References:
  StudentFee (fin_*) ──event──→ Receipt/Sales Voucher
  Transport (tpt_*)  ──event──→ Receipt/Sales/Journal Voucher
  Payroll (prl_*)    ──event──→ Payroll Journal Voucher
  Inventory (inv_*)  ──event──→ Purchase/Stock Journal Voucher
```

---

## 6. Business Rules & Validation

### Critical Rules
1. **Double-Entry Balance:** Every voucher MUST have sum(debit items) = sum(credit items). Reject on imbalance.
2. **Financial Year Lock:** When `is_locked = true`, reject any voucher create/edit/delete for that FY.
3. **Voucher Number Immutability:** Once assigned, voucher_number can NEVER be changed or reused.
4. **Ledger Balance Computation:** Balance = `opening_balance ± sum(voucher_items for this ledger)`. NEVER stored — always computed.
5. **System Entity Protection:** Records with `is_system = true` cannot be deleted.
6. **Fiscal Year Continuity:** Closing balance of FY(n) = Opening balance of FY(n+1).
7. **Cost Center Optional:** Optional on voucher items. Enables department-wise P&L.
8. **Cancelled Voucher Retention:** Soft-deleted with reason. Never hard-delete.
9. **Recurring Template Balance:** Template sum(Dr) must = sum(Cr).
10. **Bank Reconciliation:** Only ledgers with `allow_reconciliation = true` can be reconciled.
11. **No tenant_id:** Dedicated database per tenant — data isolation at DB level.
12. **sch_employees Reuse:** Employee ledger FK points to `sch_employees.id`, not a new table.
13. **Tally Mapping Integrity:** Every ledger can have at most one Tally mapping. Mapping is optional.

### Validation Rules
- Voucher date must fall within an unlocked financial year
- Ledger code unique within active records
- Account group code unique within active records
- Budget amount >= 0
- Tax rate between 0 and 100
- Asset purchase_cost > salvage_value
- Expense claim total = sum of claim lines
- Tally ledger name unique within active mappings

---

## 7. Workflows & Status Transitions

### Voucher Workflow
```
Draft → Posted → Approved → [Cancelled]
  │                            │
  └── (can edit)               └── (reason required, soft-delete)
```
- **Draft:** Created but not finalized. Can edit freely.
- **Posted:** Finalized, affects ledger balances. Requires unlock to edit.
- **Approved:** Verified by authorized user. Read-only.
- **Cancelled:** Soft-deleted with reason. Balances reversed.

### Expense Claim Workflow
```
Draft → Submitted → Approved → Paid
                  → Rejected
```
- **Approved:** Creates Payment Voucher (Dr Expense Ledger, Cr Bank/Cash)
- **Paid:** Payment voucher posted and approved

### Financial Year Workflow
```
Active (is_locked=false) → Locked (is_locked=true)
```
- Locking is one-way by default (unlocking requires Super Admin)
- On lock: Auto-calculate closing balances, carry forward to next FY

---

## 8. Integration Points

### Inbound (Other Modules → Accounting)

| Source Module | Event/Trigger | Accounting Action | Voucher Type |
|-------------|--------------|-------------------|--------------|
| **StudentFee** | FeePaymentReceived | Receipt Voucher (Dr Bank/Cash, Cr Fee Income per head) | RECEIPT |
| **StudentFee** | FeeInvoiceGenerated | Sales Voucher (Dr Student Debtor, Cr Fee Income) | SALES |
| **Transport** | TransportFeeCharged | Sales Voucher (Dr Student Debtor, Cr Transport Fee Income) | SALES |
| **Transport** | TransportFeeCollected | Receipt Voucher (Dr Bank/Cash, Cr Student Debtor) | RECEIPT |
| **Transport** | TransportFineCharged | Journal Voucher (Dr Student Debtor, Cr Fine Income) | JOURNAL |
| **Payroll** | PayrollApproved | Payroll Journal (Dr Salary Expense, Cr PF/ESI/TDS/PT/Net) | PAYROLL |
| **Inventory** | GrnAccepted | Purchase Voucher (Dr Stock-in-Hand, Cr Vendor Creditor) | PURCHASE |
| **Inventory** | StockIssued | Stock Journal (Dr Dept Consumption, Cr Stock-in-Hand) | STOCK_JOURNAL |
| **Inventory** | StockAdjustment | Journal (Dr/Cr Stock-in-Hand, Cr/Dr Adjustment A/c) | JOURNAL |

### Outbound (Accounting → Other Modules)

| Target Module | Data Provided |
|--------------|---------------|
| Dashboard | Financial KPIs |
| StudentFee | Student outstanding (ledger balance) |
| Vendor | Vendor payable (ledger balance) |
| Transport | Transport fee outstanding (ledger balance) |
| Payroll | Employee salary payable (ledger balance) |

---

## 9. User Roles & Permissions
| Role | Permissions |
|------|------------|
| School Admin | Full access: all accounting features |
| Accountant | Vouchers, ledgers, reports, bank recon, budgets, Tally mapping |
| Cashier | Receipt/Payment vouchers, cash/bank book only |
| Auditor | Read-only access to all reports and vouchers |

**Permission strings:**
```
accounting.financial-year.viewAny/create/update/lock
accounting.account-group.viewAny/create/update/delete
accounting.ledger.viewAny/create/update/delete
accounting.voucher.viewAny/create/update/approve/cancel
accounting.budget.viewAny/create/update
accounting.report.view
accounting.bank-reconciliation.viewAny/create/reconcile
accounting.asset.viewAny/create/update/depreciate
accounting.expense-claim.viewAny/create/approve/reject
accounting.tally-export.export
accounting.tally-mapping.viewAny/create/update
```

---

## 10. Reports & Dashboards

### Financial Reports
| Report | Description | Parameters |
|--------|-------------|------------|
| Trial Balance | Group-wise Dr/Cr totals with drill-down | From date, To date |
| Profit & Loss | Income vs Expense (Income & Expenditure for trusts) | From date, To date |
| Balance Sheet | Assets vs Liabilities as on date | As on date |
| Day Book | All vouchers for a date/range | Date, Voucher type |
| Cash Book | Cash account transactions with running balance | Date range |
| Bank Book | Bank account transactions with running balance | Ledger, Date range |
| Ledger Report | Individual account history with opening/closing | Ledger, Date range |
| Outstanding Receivables | Student-wise fee dues (30/60/90 aging) | As on date |
| Outstanding Payables | Vendor-wise pending payments | As on date |
| Transport Fee Outstanding | Student-wise transport fee dues | As on date |
| Budget vs Actual | Variance analysis per cost center per ledger | Financial year |
| GST Summary | CGST/SGST/IGST collection and payment | Month/Quarter |

### Dashboard Widgets
- KPI Cards: Fee Collected MTD, Expenses MTD, Bank Balance, Outstanding Receivables, Transport Fee Outstanding
- Income vs Expense chart (monthly trend, Chart.js)
- Recent vouchers table (last 10)
- Budget utilization gauge
- Quick action buttons (New Voucher, Day Book, Trial Balance)

---

## 11. Seed Data Requirements

### Account Groups (32 records)
Tally's 28 standard groups + school-specific:
- Fee Income (under Direct Income)
- Transport Fee Income (under Direct Income)
- Teaching Staff Expenses (under Direct Expenses)
- Non-Teaching Staff Expenses (under Indirect Expenses)
- Administrative Expenses (under Indirect Expenses)
- Infrastructure & Maintenance (under Indirect Expenses)

### Default Ledgers (11 records)
Cash A/c, Petty Cash, GST Payable, TDS Payable, PF Payable, ESI Payable, PT Payable, Salary Payable, Transport Fee Income, Fine Income, Profit & Loss A/c

### Voucher Types (10 records)
Payment, Receipt, Contra, Journal, Sales, Purchase, Credit Note, Debit Note, Stock Journal, Payroll

### Tax Rates (5 records)
CGST 9%, SGST 9%, IGST 18%, CGST 2.5%, SGST 2.5%

### Cost Centers (10 records)
Primary Wing, Middle Wing, Senior Wing, Administration, Transport, Sports, Library, Science Lab, Computer Lab, Hostel

### Tally Ledger Mappings (~40 records)
Auto-mapped during seed: 28 Tally groups → our account groups + 11 default ledgers → Tally ledger names. All with `mapping_type='auto'`.

---

## 12. Dependencies — VERIFIED

| This Module Needs | From Module | Correct Table Name | Verified |
|-------------------|------------|-------------------|----------|
| Students | StudentProfile | `std_students` | Line 4618 |
| Employees | SchoolSetup | `sch_employees` (enhanced) | Line 955 |
| Departments | SchoolSetup | **`sch_department`** (SINGULAR) | Line 476 |
| Fee Events | StudentFee | Events (no table dependency) | N/A |
| Transport Events | Transport | Events (no table dependency) | N/A |
| Vendors | Vendor | `vnd_vendors` | Line 1810 |
| Users | System | `sys_users` | Line 87 |

> **Does NOT depend on:** `sch_teachers` (doesn't exist), `sch_employee_groups` (doesn't exist), `sch_employee_attendance` (doesn't exist)

---

## 13. Controllers & Services

### Controllers (18)
AccountGroupController, LedgerController, LedgerMappingController, FinancialYearController, VoucherTypeController, VoucherController, CostCenterController, BudgetController, TaxRateController, RecurringTemplateController, BankReconciliationController, AssetCategoryController, FixedAssetController, ExpenseClaimController, TallyExportController, TallyLedgerMappingController, AccReportController, AccDashboardController

### Services (9)
VoucherService (implements VoucherServiceInterface), AccountingService (balance calc), ReportService, ReconciliationService, DepreciationService, RecurringJournalService, TallyExportService, FeeIntegrationService, TransportIntegrationService

### Contracts (Shared)
VoucherServiceInterface — consumed by Payroll and Inventory modules

### FormRequests (~15)
Store/Update for: AccountGroup, Ledger, Voucher, CostCenter, Budget, TaxRate, RecurringTemplate, FinancialYear, FixedAsset, ExpenseClaim, TallyLedgerMapping

---

## 14. sch_employees Enhancement

The **only** existing table being enhanced. Migration uses `Schema::hasColumn()` guard.

| New Column | Type | Description |
|------------|------|-------------|
| is_active | TINYINT(1) DEFAULT 1 | Missing from current DDL |
| created_by | BIGINT UNSIGNED NULL | Missing from current DDL |
| staff_category_id | INT UNSIGNED NULL FK | FK → `sch_categories` (for payroll grouping) |
| ledger_id | BIGINT UNSIGNED NULL FK | FK → `acc_ledgers` (salary payable auto-ledger) |
| salary_structure_id | BIGINT UNSIGNED NULL FK | FK → `prl_salary_structures` |
| bank_name | VARCHAR(100) NULL | Salary bank |
| bank_account_number | VARCHAR(50) NULL | Bank account |
| bank_ifsc | VARCHAR(20) NULL | IFSC code |
| pf_number | VARCHAR(30) NULL | PF account number |
| esi_number | VARCHAR(30) NULL | ESI number |
| uan | VARCHAR(20) NULL | Universal Account Number |
| pan | VARCHAR(15) NULL | PAN number |
| ctc_monthly | DECIMAL(15,2) NULL | Monthly CTC |
| date_of_leaving | DATE NULL | Relieving date |

---

## 15. Duplication Check — CLEAN

| Check | Result |
|-------|--------|
| Any new `acc_` table duplicates existing `acc_` in DDL? | No — old acc_* tables REPLACED (different schema model) |
| Any new `acc_` table duplicates `fin_*` tables? | No — fee management excluded |
| Any new `acc_` table duplicates `prl_*` or `inv_*`? | No — each module has distinct prefix |
| `acc_expense_claims` duplicates anything? | No — unique to accounting |
| `acc_tally_ledger_mappings` duplicates `acc_ledger_mappings`? | No — different purpose (Tally names vs module bridges) |

---

## 16. Table Summary

| # | Table | Type | Status |
|---|-------|------|--------|
| 1 | acc_financial_years | Core | New |
| 2 | acc_account_groups | Core | New (replaces old) |
| 3 | acc_ledgers | Core | New (replaces old) |
| 4 | acc_voucher_types | Core | New |
| 5 | acc_vouchers | Core | New (replaces acc_journal_entries) |
| 6 | acc_voucher_items | Core | New (replaces acc_journal_entry_lines) |
| 7 | acc_cost_centers | Core | New (replaces old) |
| 8 | acc_budgets | Core | New (replaces old) |
| 9 | acc_tax_rates | Core | New (replaces old) |
| 10 | acc_ledger_mappings | Core | New (replaces old) |
| 11 | acc_recurring_templates | Core | New (replaces acc_recurring_journal_templates) |
| 12 | acc_recurring_template_lines | Core | New (replaces acc_recurring_journal_template_lines) |
| 13 | acc_bank_reconciliations | Banking | New (replaces old) |
| 14 | acc_bank_statement_entries | Banking | New (replaces acc_reconciliation_matches) |
| 15 | acc_asset_categories | Assets | New (replaces old) |
| 16 | acc_fixed_assets | Assets | New (replaces old) |
| 17 | acc_depreciation_entries | Assets | New (replaces old) |
| 18 | acc_expense_claims | Expense | New (replaces old) |
| 19 | acc_expense_claim_lines | Expense | New (replaces old) |
| 20 | acc_tally_export_logs | Export | New (replaces old) |
| 21 | acc_tally_ledger_mappings | Tally | New |
| — | sch_employees | SchoolSetup | Existing — ALTER TABLE (14 cols) |
| **Total** | **21 new acc_ tables** | | **Old DDL is UNUSED — replace entirely** |
