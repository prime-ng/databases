# Account Module — Detailed Requirement Document v3

**Module:** Accounting | **Laravel Module:** `Modules/Accounting/` | **Prefix:** `acc_`
**Database:** tenant_db (dedicated per tenant — no tenant_id needed)
**Route:** `/accounting/*` | **RBS Module:** K — Finance & Accounting (70 sub-tasks)
**Inspired by:** Tally Prime | **Date:** 2026-03-19 | **Version:** 3.0

**Changes from v2:** 3 separate modules, Transport integration added, Tally ledger mapping mechanism, sch_employees reuse (not acc_employees), no tenant_id, updated prefixes

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

## 4. Entity List (Tables & Columns)

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

### 4.11 acc_recurring_templates + 4.12 acc_recurring_template_lines
*(Same as v2 — no changes)*

### 4.13 acc_bank_reconciliations + 4.14 acc_bank_statement_entries
*(Same as v2 — no changes)*

### 4.15 acc_asset_categories + 4.16 acc_fixed_assets + 4.17 acc_depreciation_entries
*(Same as v2 — no changes)*

### 4.18 acc_expense_claims + 4.19 acc_expense_claim_lines
*(Same as v2 — no changes, but `employee_id` FK → `sch_employees` not acc_employees)*

### 4.20 acc_tally_export_logs
*(Same as v2 — no changes)*

### 4.21 acc_tally_ledger_mappings (NEW)
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

**How Tally Mapping Works:**
1. **Seed:** During tenant provisioning, auto-create mappings for 28 standard Tally groups + default ledgers (mapping_type='auto')
2. **Configure:** School accountant maps custom ledgers via Settings → Tally Integration screen
3. **Export:** `TallyExportService` reads `acc_tally_ledger_mappings` to use correct Tally names in XML output
4. **Import (future):** Parse Tally XML and match to our ledgers via tally_ledger_name
5. **UI:** Two-column mapping screen: Our Ledger (dropdown) ↔ Tally Ledger Name (text input)

---

## 5. Entity Relationship Diagram

```
acc_account_groups (self-ref parent_id)
    │
    ├── acc_ledgers ────────────── acc_tally_ledger_mappings (1:1 Tally name mapping)
    │       │
    │       ├── std_students (student_id FK — auto-ledger for student debtors)
    │       ├── sch_employees (employee_id FK — auto-ledger for salary payable)
    │       ├── vnd_vendors (vendor_id FK — auto-ledger for vendor creditors)
    │       │
    │       ├── acc_voucher_items ──── acc_vouchers ──── acc_voucher_types
    │       │                              │
    │       │                              ├── acc_financial_years
    │       │                              ├── source_module (StudentFee|Payroll|Inventory|Transport|Manual)
    │       │                              └── source_type + source_id (polymorphic)
    │       │
    │       ├── acc_budgets ──── acc_financial_years + acc_cost_centers
    │       │
    │       ├── acc_ledger_mappings (→ Fees, HR, Vendor, Inventory, Transport, Payroll)
    │       │
    │       ├── acc_bank_reconciliations → acc_bank_statement_entries
    │       │
    │       └── acc_recurring_templates → acc_recurring_template_lines
    │
    └── acc_cost_centers (self-ref parent_id)

acc_asset_categories → acc_fixed_assets → acc_depreciation_entries → acc_vouchers

acc_expense_claims → acc_expense_claim_lines → acc_ledgers
   (employee_id → sch_employees)
   └── → acc_vouchers (on approval)

External Module References:
  StudentFee (fin_*)  ──event──→ Accounting (Receipt Voucher)
  Transport  (tpt_*)  ──event──→ Accounting (Receipt/Journal Voucher)
  Payroll    (prl_*)  ──event──→ Accounting (Payroll Journal Voucher)
  Inventory  (inv_*)  ──event──→ Accounting (Purchase/Stock Journal Voucher)
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

### Expense Claim Workflow
```
Draft → Submitted → Approved → Paid
                  → Rejected
```

### Financial Year Workflow
```
Active (is_locked=false) → Locked (is_locked=true)
```

*(Details same as v2)*

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
| **Payroll** | PayrollApproved | Payroll Journal (Dr Salary Expense, Cr PF/ESI/TDS/PT/Net Payable) | PAYROLL |
| **Inventory** | GrnAccepted | Purchase Voucher (Dr Stock-in-Hand, Cr Vendor Creditor) | PURCHASE |
| **Inventory** | StockIssued | Stock Journal (Dr Dept Consumption, Cr Stock-in-Hand) | STOCK_JOURNAL |
| **Inventory** | StockAdjustment | Journal (Dr/Cr Stock-in-Hand, Cr/Dr Adjustment A/c) | JOURNAL |

### Transport Module Integration Detail
```
When a student registers for transport from a specific stoppage:

1. Transport module creates transport fee assignment (tpt_fee_master → tpt_fee_collection)
2. Fires TransportFeeCharged event with:
   - student_id, route_id, stoppage_id, amount, academic_session
3. Accounting listener creates Sales Voucher:
   Dr  Student Debtor Ledger (auto-created under Sundry Debtors)  ₹Amount
   Cr  Transport Fee Income Ledger (mapped via acc_ledger_mappings, source_module='Transport')  ₹Amount

When transport fee is collected:
4. Fires TransportFeeCollected event
5. Creates Receipt Voucher:
   Dr  Bank/Cash A/c         ₹Amount
   Cr  Student Debtor Ledger  ₹Amount

When transport fine is charged:
6. Fires TransportFineCharged event
7. Creates Journal Voucher:
   Dr  Student Debtor Ledger  ₹Fine
   Cr  Fine Income Ledger     ₹Fine

Ledger Mapping:
   acc_ledger_mappings: source_module='Transport', source_type='Route', source_id=<route_id>
   acc_ledger_mappings: source_module='Transport', source_type='FineType', source_id=<fine_type_id>
```

### Outbound (Accounting → Other Modules)

| Target Module | Data Provided |
|--------------|---------------|
| Dashboard | Financial KPIs (Revenue MTD, Expenses MTD, Bank Balance, Outstanding) |
| StudentFee | Ledger balance for student (outstanding amount) |
| Vendor | Ledger balance for vendor (payable amount) |
| Transport | Student transport fee outstanding (from ledger) |
| Payroll | Employee salary payable balance (from ledger) |

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

## 12. Dependencies

| This Module Needs | From Module | Entities |
|-------------------|------------|----------|
| Students | StudentProfile | `std_students` (for auto-ledger creation) |
| Employees | SchoolSetup | `sch_employees` (for employee ledger, expense claims) |
| Teachers | SchoolSetup | `sch_teachers` (for payroll linkage via sch_employees) |
| Departments | SchoolSetup | `sch_departments` (for cost center mapping) |
| Fee Events | StudentFee | `FeePaymentReceived`, `FeeInvoiceGenerated` events |
| Transport Events | Transport | `TransportFeeCharged`, `TransportFeeCollected`, `TransportFineCharged` events |
| Vendors | Vendor | `vnd_vendors` (for vendor ledger linking) |
| Users | System | `sys_users` (created_by, approved_by) |

| Other Modules Need | From This Module | Use Case |
|--------------------|-----------------|----------|
| Payroll | VoucherServiceInterface | Post payroll journal voucher |
| Inventory | VoucherServiceInterface | Post purchase/stock journal vouchers |
| StudentFee | Ledger balance query | Student outstanding amount |
| Transport | Ledger balance query | Transport fee outstanding |
| Dashboard | KPI data | Financial widgets |

---

## 13. Controllers & Services Summary

### Controllers (18)
AccountGroupController, LedgerController, LedgerMappingController, FinancialYearController, VoucherTypeController, VoucherController, CostCenterController, BudgetController, TaxRateController, RecurringTemplateController, BankReconciliationController, AssetCategoryController, FixedAssetController, ExpenseClaimController, TallyExportController, TallyLedgerMappingController, AccReportController, AccDashboardController

### Services (9)
VoucherService (implements VoucherServiceInterface), AccountingService (balance calc), ReportService, ReconciliationService, DepreciationService, RecurringJournalService, TallyExportService, FeeIntegrationService, TransportIntegrationService

### Contracts (Shared)
VoucherServiceInterface — consumed by Payroll and Inventory modules

### FormRequests (~15)
Store/Update for: AccountGroup, Ledger, Voucher, CostCenter, Budget, TaxRate, RecurringTemplate, FinancialYear, FixedAsset, ExpenseClaim, TallyLedgerMapping

---

## 14. sch_employees Enhancement (for Payroll Integration)

The existing `sch_employees` table needs these additional columns for payroll support. These are added via an ALTER TABLE migration — the table is NOT recreated.

### Suggested New Columns on `sch_employees`
| Column | Type | Description |
|--------|------|-------------|
| ledger_id | BIGINT UNSIGNED NULL FK | FK → acc_ledgers (auto-created salary payable ledger) |
| salary_structure_id | BIGINT UNSIGNED NULL FK | FK → prl_salary_structures |
| bank_name | VARCHAR(100) NULL | Salary disbursement bank |
| bank_account_number | VARCHAR(50) NULL | Bank account number |
| bank_ifsc | VARCHAR(20) NULL | IFSC code |
| pf_number | VARCHAR(30) NULL | PF account number |
| esi_number | VARCHAR(30) NULL | ESI number |
| uan | VARCHAR(20) NULL | Universal Account Number |
| pan | VARCHAR(15) NULL | PAN card number |
| ctc_monthly | DECIMAL(15,2) NULL | Monthly CTC amount |
| date_of_leaving | DATE NULL | Relieving date |

> **Note:** These columns may already partially exist. The migration must check before adding (use `Schema::hasColumn()` guard).
