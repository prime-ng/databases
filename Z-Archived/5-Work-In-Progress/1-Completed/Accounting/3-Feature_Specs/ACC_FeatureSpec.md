# ACC — Accounting Module Feature Specification

**Module:** Accounting | **Code:** ACC | **Prefix:** `acc_`
**Laravel Module:** `Modules/Accounting/` | **Route:** `/accounting/*`
**Database:** tenant_db (dedicated per tenant — no tenant_id)
**Developer:** Brijesh | **Branch:** Brijesh_Finance
**Date:** 2026-03-21 | **Phase:** 1 — Requirements

---

## 1. Entity List (21 Tables)

### 1.1 Core Accounting (12 tables)

| # | Table | Purpose | Key Columns |
|---|-------|---------|-------------|
| 1 | `acc_financial_years` | Fiscal year configuration with locking | name, start_date, end_date, is_locked |
| 2 | `acc_account_groups` | Hierarchical Chart of Accounts (Tally's 28 groups + custom) | name, code, alias, parent_id (self-ref), nature (asset/liability/income/expense), affects_gross_profit, is_system, is_subledger, sequence |
| 3 | `acc_ledgers` | Individual accounts (bank, cash, student, employee, vendor) | name, code, alias, account_group_id FK, opening_balance, opening_balance_type (Dr/Cr), is_bank_account, bank_name, bank_account_number, ifsc_code, is_cash_account, allow_reconciliation, is_system, student_id FK→std_students, employee_id FK→sch_employees, vendor_id FK→vnd_vendors, gst_registration_type, gstin, pan, address |
| 4 | `acc_voucher_types` | Voucher type definitions (Payment, Receipt, Contra, Journal, Sales, Purchase, Credit Note, Debit Note, Stock Journal, Payroll) | name, code (UNIQUE), category (accounting/inventory/payroll/order), prefix, auto_numbering, last_number, is_system |
| 5 | `acc_vouchers` | **THE HEART** — every financial transaction is a voucher | voucher_number (unique per FY), voucher_type_id FK, financial_year_id FK, date, reference_number, reference_date, narration, total_amount, is_post_dated, is_optional, is_cancelled, cancelled_reason, cost_center_id FK, source_module, source_type (polymorphic), source_id, status (draft/posted/approved/cancelled), approved_by |
| 6 | `acc_voucher_items` | Debit/Credit line items per voucher | voucher_id FK (CASCADE), ledger_id FK, type (debit/credit), amount, narration, cost_center_id FK, bill_reference |
| 7 | `acc_cost_centers` | Department/activity-based tracking (hierarchical) | name, code, parent_id (self-ref), category (Department/Activity/Project) |
| 8 | `acc_budgets` | Fiscal year budget allocation per cost center per ledger | financial_year_id FK, cost_center_id FK, ledger_id FK, budgeted_amount; UNIQUE (fy, cc, ledger) |
| 9 | `acc_tax_rates` | GST rate configuration | name, rate, type (CGST/SGST/IGST/Cess), hsn_sac_code, is_interstate |
| 10 | `acc_ledger_mappings` | Cross-module ledger links | ledger_id FK, source_module (Fees/Library/Transport/HR/Vendor/Inventory/Payroll), source_type, source_id, description; UNIQUE combo |
| 11 | `acc_recurring_templates` | Auto-posting journal templates | name, voucher_type_id FK, frequency (Daily/Weekly/Monthly/Quarterly/Yearly), start_date, end_date, day_of_month, narration, total_amount, last_posted_date |
| 12 | `acc_recurring_template_lines` | Template Dr/Cr line items | recurring_template_id FK (CASCADE), ledger_id FK, type (debit/credit), amount, narration |

### 1.2 Banking (2 tables)

| # | Table | Purpose | Key Columns |
|---|-------|---------|-------------|
| 13 | `acc_bank_reconciliations` | Bank statement reconciliation sessions | ledger_id FK, statement_date, closing_balance, statement_path, status (In Progress/Completed) |
| 14 | `acc_bank_statement_entries` | Imported bank transactions for matching | reconciliation_id FK (CASCADE), transaction_date, description, reference, debit, credit, balance, is_matched, matched_voucher_item_id FK→acc_voucher_items, matched_at, matched_by |

### 1.3 Fixed Assets (3 tables)

| # | Table | Purpose | Key Columns |
|---|-------|---------|-------------|
| 15 | `acc_asset_categories` | Asset types with depreciation config | name, code (UNIQUE), depreciation_method (SLM/WDV), depreciation_rate, useful_life_years |
| 16 | `acc_fixed_assets` | Individual asset register | name, asset_code (UNIQUE), asset_category_id FK, purchase_date, purchase_cost, salvage_value, current_value, accumulated_depreciation, location, vendor_id FK→vnd_vendors, voucher_id FK→acc_vouchers |
| 17 | `acc_depreciation_entries` | Depreciation records per period | fixed_asset_id FK (CASCADE), financial_year_id FK→acc_financial_years, depreciation_date, depreciation_amount, voucher_id FK→acc_vouchers |

### 1.4 Expense Claims (2 tables)

| # | Table | Purpose | Key Columns |
|---|-------|---------|-------------|
| 18 | `acc_expense_claims` | Staff expense claims with approval workflow | claim_number (UNIQUE), employee_id FK→sch_employees, claim_date, total_amount, status (Draft/Submitted/Approved/Rejected/Paid), approved_by, approved_at, voucher_id FK→acc_vouchers |
| 19 | `acc_expense_claim_lines` | Claim line items with receipt uploads | expense_claim_id FK (CASCADE), expense_date, ledger_id FK→acc_ledgers, description, amount, tax_amount, receipt_path |

### 1.5 Tally Integration (2 tables)

| # | Table | Purpose | Key Columns |
|---|-------|---------|-------------|
| 20 | `acc_tally_export_logs` | Tally XML export audit trail | export_type (Ledgers/Vouchers/Inventory), export_date, file_name, exported_by FK, start_date, end_date, record_count, status (Success/Failed/Partial), error_log |
| 21 | `acc_tally_ledger_mappings` | Our ledgers ↔ Tally ledger names for export/import | ledger_id FK (UNIQUE), tally_ledger_name, tally_group_name, tally_alias, mapping_type (auto/manual), sync_direction (export_only/import_only/bidirectional), last_synced_at |

### 1.6 Existing Table Enhancement (ALTER TABLE — NOT new)

| Table | Enhancement |
|-------|------------|
| `sch_employees` | ADD: is_active, created_by, staff_category_id FK→sch_categories, ledger_id FK→acc_ledgers, salary_structure_id FK→prl_salary_structures, bank_name, bank_account_number, bank_ifsc, pf_number, esi_number, uan, pan, ctc_monthly, date_of_leaving |

**Standard columns on ALL 21 tables:** `id` (BIGINT UNSIGNED PK AUTO_INCREMENT), `is_active` (TINYINT(1) DEFAULT 1), `created_by` (BIGINT UNSIGNED NULL), `created_at` (TIMESTAMP), `updated_at` (TIMESTAMP), `deleted_at` (TIMESTAMP NULL)

---

## 2. Entity Relationship Diagram

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
    │       │       │                      │
    │       │       │                      ├── acc_financial_years
    │       │       │                      └── source_module + source_type + source_id (polymorphic)
    │       │       │
    │       │       └── acc_bank_statement_entries.matched_voucher_item_id
    │       │
    │       ├── acc_budgets ──── acc_financial_years
    │       │                    acc_cost_centers
    │       │
    │       ├── acc_ledger_mappings (→ Fees, Vendor, Transport, Inventory, Payroll)
    │       │
    │       ├── acc_bank_reconciliations → acc_bank_statement_entries
    │       │
    │       ├── acc_recurring_templates → acc_recurring_template_lines
    │       │
    │       └── acc_expense_claim_lines.ledger_id
    │
    └── acc_cost_centers (self-ref parent_id)
            │
            ├── acc_vouchers.cost_center_id
            ├── acc_voucher_items.cost_center_id
            └── acc_budgets.cost_center_id

acc_asset_categories → acc_fixed_assets → acc_depreciation_entries
                            │                    │
                            ├── vnd_vendors      ├── acc_financial_years
                            └── acc_vouchers     └── acc_vouchers

acc_expense_claims ──── acc_expense_claim_lines
    │                        └── acc_ledgers
    ├── sch_employees (employee_id)
    ├── sys_users (approved_by)
    └── acc_vouchers (voucher_id — on approval)

EXTERNAL MODULE REFERENCES:
  StudentFee (fin_*) ──event──→ acc_vouchers (Receipt/Sales)
  Transport (tpt_*)  ──event──→ acc_vouchers (Receipt/Sales/Journal)
  Payroll (prl_*)    ──event──→ acc_vouchers (Payroll Journal)
  Inventory (inv_*)  ──event──→ acc_vouchers (Purchase/Stock Journal)
```

---

## 3. Business Rules

### 3.1 Critical Rules (Hard — Must Never Be Violated)

| # | Rule | Implementation |
|---|------|---------------|
| BR-01 | **Double-Entry Balance** — every voucher MUST have sum(debit items) = sum(credit items) | VoucherService validates before save; reject on imbalance |
| BR-02 | **Financial Year Lock** — locked FY prevents all create/edit/delete of vouchers | Check `acc_financial_years.is_locked` in VoucherService |
| BR-03 | **Voucher Number Immutability** — once assigned, never changed or reused | DB UNIQUE constraint + application guard |
| BR-04 | **Ledger Balance = Computed** — balance = opening ± sum(voucher_items). NEVER stored | Always compute via query; no balance column on acc_ledgers |
| BR-05 | **System Entity Protection** — records with `is_system = true` cannot be deleted | Policy + model event guard |
| BR-06 | **Fiscal Year Continuity** — closing balance of FY(n) = opening balance of FY(n+1) | Auto-carried forward on FY close |
| BR-07 | **Cancelled Voucher Retention** — cancelled vouchers soft-deleted with reason, never hard-deleted | `is_cancelled` + `cancelled_reason` + `deleted_at` |
| BR-08 | **Stock Entry Linkage** — every inv_stock_entries record requires a voucher_id | FK NOT NULL in Inventory module |

### 3.2 Validation Rules (Soft — FormRequest enforced)

| Entity | Rule |
|--------|------|
| Voucher | Date must fall within an unlocked financial year |
| Voucher | At least 2 voucher_items (minimum 1 Dr + 1 Cr) |
| Voucher | total_amount must equal sum of Dr items (and sum of Cr items) |
| Ledger | Code unique within active (non-deleted) records |
| Account Group | Code unique within active records |
| Budget | Amount >= 0 |
| Tax Rate | Rate between 0 and 100 |
| Fixed Asset | purchase_cost > salvage_value |
| Expense Claim | Total must equal sum of claim lines |
| Tally Mapping | tally_ledger_name unique within active mappings |
| Recurring Template | Template sum(Dr lines) must = sum(Cr lines) |
| Bank Recon | Only ledgers with `allow_reconciliation = true` |

### 3.3 Cascade Behaviors

| Parent Entity | Child | On Delete |
|--------------|-------|-----------|
| acc_vouchers | acc_voucher_items | CASCADE |
| acc_recurring_templates | acc_recurring_template_lines | CASCADE |
| acc_bank_reconciliations | acc_bank_statement_entries | CASCADE |
| acc_expense_claims | acc_expense_claim_lines | CASCADE |
| acc_fixed_assets | acc_depreciation_entries | CASCADE |
| acc_account_groups | acc_account_groups (children) | SET NULL (parent_id) |
| acc_account_groups | acc_ledgers | RESTRICT (cannot delete group with ledgers) |
| acc_ledgers | acc_voucher_items | RESTRICT (cannot delete ledger with transactions) |

---

## 4. Status Workflows

### 4.1 Voucher Workflow
```
Draft → Posted → Approved → [Cancelled]
  │                            │
  └── (can edit freely)        └── (reason required, balances reversed, soft-deleted)
```
- **Draft:** Created but not finalized. Editable. Does NOT affect ledger balances.
- **Posted:** Finalized. Affects ledger balances. Requires unlock to edit.
- **Approved:** Verified by authorized user. Read-only. Immutable.
- **Cancelled:** Soft-deleted with reason. Reversed from balances.

### 4.2 Expense Claim Workflow
```
Draft → Submitted → Approved → Paid
                  → Rejected
```
- **Approved:** Creates Payment Voucher (Dr Expense Ledger, Cr Bank/Cash)
- **Paid:** Payment voucher posted and approved

### 4.3 Financial Year Workflow
```
Active (is_locked=false) → Locked (is_locked=true)
```
- Locking is one-way by default (unlocking requires Super Admin)
- On lock: Auto-calculate closing balances, carry forward to next FY

### 4.4 Bank Reconciliation Workflow
```
In Progress → Completed
```

---

## 5. Permission List

### 5.1 Gate Permissions (format: `accounting.resource.action`)

| Resource | Permissions |
|----------|-----------|
| financial-year | viewAny, create, update, lock |
| account-group | viewAny, create, update, delete |
| ledger | viewAny, create, update, delete |
| voucher | viewAny, create, update, approve, cancel |
| voucher-type | viewAny, create, update |
| cost-center | viewAny, create, update, delete |
| budget | viewAny, create, update, delete |
| tax-rate | viewAny, create, update, delete |
| ledger-mapping | viewAny, create, update, delete |
| recurring-template | viewAny, create, update, delete |
| bank-reconciliation | viewAny, create, reconcile, complete |
| asset-category | viewAny, create, update, delete |
| fixed-asset | viewAny, create, update, delete, depreciate |
| expense-claim | viewAny, create, update, approve, reject, pay |
| tally-export | viewAny, export |
| tally-mapping | viewAny, create, update, delete |
| report | view |
| dashboard | view |

**Total: 18 resources × avg 4 actions = ~65 permissions**

### 5.2 Role → Permission Mapping

| Role | Scope |
|------|-------|
| School Admin | All accounting permissions |
| Accountant | Vouchers, ledgers, reports, bank recon, budgets, tally mapping, expense claims |
| Cashier | Receipt/Payment vouchers only, cash/bank book |
| Auditor | Read-only access to all reports and vouchers (viewAny + report.view only) |

---

## 6. Dependencies (Cross-Module)

### 6.1 Existing Tables USED (read-only FK references)

| Table | Module | Used For | Verified |
|-------|--------|----------|----------|
| `sch_employees` | SchoolSetup | Employee ledger auto-creation, expense claims | Line 955 in DDL |
| `sch_department` | SchoolSetup | Cost center mapping (SINGULAR name) | Line 476 |
| `sch_categories` | SchoolSetup | Staff grouping | Line 584 |
| `std_students` | StudentProfile | Student debtor ledger auto-creation | Line 4618 |
| `vnd_vendors` | Vendor | Vendor creditor ledger auto-creation | Line 1810 |
| `sys_users` | System | created_by, approved_by | Line 87 |

### 6.2 Cross-Module Integration Events

| Source Module | Event | Accounting Action | Voucher Type | Dr | Cr |
|-------------|-------|-------------------|--------------|----|----|
| **StudentFee** | FeePaymentReceived | Create Receipt Voucher | RECEIPT | Bank/Cash A/c | Fee Income (per head) |
| **StudentFee** | FeeInvoiceGenerated | Create Sales Voucher | SALES | Student Debtor | Fee Income |
| **Transport** | TransportFeeCharged | Create Sales Voucher | SALES | Student Debtor | Transport Fee Income |
| **Transport** | TransportFeeCollected | Create Receipt Voucher | RECEIPT | Bank/Cash A/c | Student Debtor |
| **Transport** | TransportFineCharged | Create Journal Voucher | JOURNAL | Student Debtor | Fine Income |
| **Payroll** | PayrollApproved | Create Payroll Journal | PAYROLL | Salary Expense (dept), Employer PF, Employer ESI | PF Payable, ESI Payable, TDS Payable, PT Payable, Salary Payable (per employee) |
| **Inventory** | GrnAccepted | Create Purchase Voucher | PURCHASE | Stock-in-Hand | Vendor Creditor |
| **Inventory** | StockIssued | Create Stock Journal | STOCK_JOURNAL | Dept Consumption (cost center) | Stock-in-Hand |
| **Inventory** | StockAdjustment | Create Journal | JOURNAL | Stock-in-Hand / Stock Adjustment A/c | Stock Adjustment A/c / Stock-in-Hand |

### 6.3 Shared Contract

```php
// Modules/Accounting/app/Contracts/VoucherServiceInterface.php
interface VoucherServiceInterface {
    public function createVoucher(array $data): Voucher;
    // $data: voucher_type_code, date, narration, financial_year_id,
    //        source_module, source_type, source_id, cost_center_id,
    //        items: [{ledger_id, type(debit/credit), amount, narration}]

    public function cancelVoucher(int $voucherId, string $reason): Voucher;

    public function getNextVoucherNumber(string $typeCode, int $financialYearId): string;

    public function getLedgerBalance(int $ledgerId, ?Carbon $asOfDate = null): array;
    // returns: ['opening' => X, 'debit' => Y, 'credit' => Z, 'closing' => W, 'type' => 'Dr'|'Cr']
}
```

This interface is consumed by:
- `Modules/Payroll/` — PayrollComputeService calls `createVoucher()` on payroll approval
- `Modules/Inventory/` — GrnPostingService + StockLedgerService call `createVoucher()` on GRN accept / stock issue

---

## 7. Controllers & Services Summary

### 7.1 Controllers (18)

| Controller | Entity/Domain | Key Non-CRUD Methods |
|-----------|--------------|---------------------|
| FinancialYearController | acc_financial_years | lock(), unlock() |
| AccountGroupController | acc_account_groups | tree() (hierarchical view), reorder() |
| LedgerController | acc_ledgers | balanceSheet(), openingBalances() |
| VoucherTypeController | acc_voucher_types | — |
| VoucherController | acc_vouchers + acc_voucher_items | approve(), cancel(), duplicate() |
| CostCenterController | acc_cost_centers | — |
| BudgetController | acc_budgets | varianceReport() |
| TaxRateController | acc_tax_rates | — |
| LedgerMappingController | acc_ledger_mappings | mapModule() |
| RecurringTemplateController | acc_recurring_templates + lines | generatePending() |
| BankReconciliationController | acc_bank_reconciliations + entries | importStatement(), autoMatch(), complete() |
| AssetCategoryController | acc_asset_categories | — |
| FixedAssetController | acc_fixed_assets | — |
| ExpenseClaimController | acc_expense_claims + lines | approve(), reject(), pay() |
| TallyExportController | acc_tally_export_logs | exportLedgers(), exportVouchers() |
| TallyLedgerMappingController | acc_tally_ledger_mappings | autoMap(), syncStatus() |
| AccReportController | (virtual — queries) | trialBalance(), profitAndLoss(), balanceSheet(), dayBook(), cashBook(), bankBook(), ledgerReport(), outstandingReceivables(), outstandingPayables(), budgetVariance(), gstSummary() |
| AccDashboardController | (virtual — queries) | index() with KPI cards + charts |

### 7.2 Services (9)

| Service | Purpose |
|---------|---------|
| VoucherService | **THE critical service** — implements VoucherServiceInterface. Creates/cancels vouchers, validates Dr=Cr balance, auto-generates voucher numbers |
| AccountingService | Ledger balance computation, trial balance calculation, opening balance management |
| ReportService | Trial Balance, P&L, Balance Sheet, Day Book, Cash/Bank Book, Ledger Report, Outstanding Aging, Budget Variance, GST Summary |
| ReconciliationService | Bank statement CSV/Excel import (Maatwebsite), auto-match by amount+date, BRS report |
| DepreciationService | SLM/WDV calculations, bulk depreciation run for all active assets, creates depreciation Journal Vouchers |
| RecurringJournalService | Scheduled job — auto-generates vouchers from templates per frequency settings |
| TallyExportService | XML generation in Tally Prime format, ledger + voucher export |
| FeeIntegrationService | Listener for StudentFee events → creates Receipt/Sales Vouchers |
| TransportIntegrationService | Listener for Transport events → creates Sales/Receipt/Journal Vouchers |

### 7.3 FormRequests (~30)

Store + Update for each: FinancialYear, AccountGroup, Ledger, VoucherType, Voucher, CostCenter, Budget, TaxRate, LedgerMapping, RecurringTemplate, FixedAsset, AssetCategory, ExpenseClaim, TallyLedgerMapping, BankReconciliation

---

## 8. Reports

| # | Report | Description | Parameters | Service Method |
|---|--------|-------------|------------|---------------|
| 1 | Trial Balance | Group-wise Dr/Cr totals with drill-down | From date, To date | trialBalance() |
| 2 | Profit & Loss | Income vs Expense (Income & Expenditure for trusts) | From date, To date | profitAndLoss() |
| 3 | Balance Sheet | Assets vs Liabilities as on date | As on date | balanceSheet() |
| 4 | Day Book | All vouchers for a date/range | Date, Voucher type | dayBook() |
| 5 | Cash Book | Cash account transactions with running balance | Date range | cashBook() |
| 6 | Bank Book | Bank account transactions with running balance | Ledger, Date range | bankBook() |
| 7 | Ledger Report | Individual account history with opening/closing | Ledger, Date range | ledgerReport() |
| 8 | Outstanding Receivables | Student-wise fee dues (30/60/90 aging) | As on date | outstandingReceivables() |
| 9 | Outstanding Payables | Vendor-wise pending payments | As on date | outstandingPayables() |
| 10 | Transport Fee Outstanding | Student-wise transport fee dues | As on date | transportOutstanding() |
| 11 | Budget vs Actual | Variance analysis per cost center per ledger | Financial year | budgetVariance() |
| 12 | GST Summary | CGST/SGST/IGST collection and payment | Month/Quarter | gstSummary() |

---

## 9. Dashboard Widgets

| Widget | Type | Data Source |
|--------|------|-------------|
| Fee Collected MTD | KPI Card | Sum of Receipt vouchers (source_module='StudentFee') this month |
| Expenses MTD | KPI Card | Sum of Payment/Purchase vouchers this month |
| Bank Balance | KPI Card | Computed balance of all bank ledgers |
| Outstanding Receivables | KPI Card | Sum of student debtor ledger balances |
| Transport Fee Outstanding | KPI Card | Sum of transport-related debtor balances |
| Income vs Expense | Chart (Bar) | Monthly totals for income/expense groups (Chart.js) |
| Cashflow Trend | Chart (Line) | Cash + Bank balance over last 6 months |
| Recent Vouchers | Table | Last 10 vouchers with type, date, amount, status |
| Budget Utilization | Gauge | Top 5 cost centers — % of budget consumed |
| Quick Actions | Buttons | New Voucher, Day Book, Trial Balance, Bank Recon |

---

## 10. Seed Data Requirements

| Seed | Records | Details |
|------|---------|---------|
| Account Groups | 32 | Tally's 28 standard + Fee Income, Transport Fee Income, Teaching Staff Expenses, Non-Teaching Staff Expenses, Administrative Expenses, Infrastructure & Maintenance |
| Default Ledgers | 11 | Cash A/c, Petty Cash, GST Payable, TDS Payable, PF Payable, ESI Payable, PT Payable, Salary Payable, Transport Fee Income, Fine Income, Profit & Loss A/c |
| Voucher Types | 10 | Payment (PAY-), Receipt (RCV-), Contra (CNT-), Journal (JRN-), Sales (SAL-), Purchase (PUR-), Credit Note (CN-), Debit Note (DN-), Stock Journal (STJ-), Payroll (PRL-) |
| Tax Rates | 5 | CGST 9%, SGST 9%, IGST 18%, CGST 2.5%, SGST 2.5% |
| Cost Centers | 10 | Primary Wing, Middle Wing, Senior Wing, Administration, Transport, Sports, Library, Science Lab, Computer Lab, Hostel |
| Tally Mappings | ~40 | Auto-mapped: 28 groups + 11 default ledgers → Tally names (mapping_type='auto') |
| Asset Categories | 5 | Furniture (SLM 10%), IT Equipment (WDV 40%), Vehicles (WDV 15%), Building (SLM 5%), Lab Equipment (SLM 15%) |

---

## 11. RBS Coverage Matrix

| RBS Section | Sub-Tasks | Tables Covered | Status |
|-------------|-----------|---------------|--------|
| K1 — Chart of Accounts | 9 | acc_account_groups, acc_ledgers, acc_ledger_mappings | Covered |
| K2 — Opening Balances | 4 | acc_ledgers (opening_balance, opening_balance_type) | Covered |
| K3 — Journal Entry | 6 | acc_vouchers, acc_voucher_items, acc_recurring_templates | Covered |
| K4 — Accounts Receivable | 8 | acc_vouchers (Receipt), acc_ledger_mappings, ReportService | 6 Covered, 2 Phase 2 |
| K5 — Accounts Payable | 4 | acc_vouchers (Purchase/Payment), VoucherService | Covered |
| K6 — Vendor Management | 4 | acc_ledgers (vendor_id FK) | 1 Covered, 3 Out of scope (Vendor module) |
| K7 — Purchase & Expense | 4 | acc_vouchers, acc_expense_claims + lines | Covered |
| K8 — Bank & Cash | 6 | acc_bank_reconciliations, acc_bank_statement_entries | Covered |
| K9 — Asset & Depreciation | 4 | acc_asset_categories, acc_fixed_assets, acc_depreciation_entries | Covered |
| K10 — Financial Reporting | 5 | ReportService (5 reports), Dashboard | Covered |
| K11 — Integrations | 4 | acc_tally_export_logs, acc_tally_ledger_mappings | 3 Covered, 1 Stub |
| K12 — Budget & Cost Center | 6 | acc_cost_centers, acc_budgets, ReportService | Covered |
| K13 — GST & Tax | 6 | acc_tax_rates, GSTComplianceService | 4 Covered, 2 Stub |
| **TOTAL** | **70** | **21 tables** | **62 Covered, 5 Phase 2/Stub, 3 Out of scope** |
