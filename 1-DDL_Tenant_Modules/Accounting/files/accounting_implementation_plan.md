# Accounting Module — Implementation Plan

**Date:** 2026-03-17 | **Module:** Accounting (`acc_*`) | **Type:** Tenant Module

---

## Phase Overview

| Phase | Scope | Tables | Controllers | Services | Est. Effort |
|-------|-------|--------|-------------|----------|-------------|
| **Phase 1** | Core Accounting + Tax + Mappings + Recurring | 12 | 10 | 3 | 4-6 weeks |
| **Phase 2** | Fee Integration + Reports | 0 | 1 (extend) | 2 | 2-3 weeks |
| **Phase 3** | Payroll + Expense Claims | 10 | 7 | 2 | 3-4 weeks |
| **Phase 4** | Inventory | 5 | 4 | 1 | 2-3 weeks |
| **Phase 5** | Banking + Tally Export | 3 | 2 | 1 | 2-3 weeks |
| **Phase 6** | Fixed Assets + Depreciation | 3 | 2 | 1 | 1-2 weeks |
| **Phase 7** | UX Polish + Testing | 0 | 0 | 0 | 2 weeks |
| **Total** | | **33** | **26** | **10** | **17-23 weeks** |

---

## Phase 1: Core Accounting (4-6 weeks)

### Week 1-2: Foundation

**Migrations (in `database/migrations/tenant/`):**
- `create_acc_financial_years_table.php`
- `create_acc_account_groups_table.php`
- `create_acc_ledgers_table.php`
- `create_acc_cost_centers_table.php`
- `create_acc_voucher_types_table.php`
- `create_acc_vouchers_table.php`
- `create_acc_voucher_items_table.php`
- `create_acc_budgets_table.php`
- `create_acc_tax_rates_table.php` *(from v1)*
- `create_acc_ledger_mappings_table.php` *(from v1)*
- `create_acc_recurring_templates_table.php` *(from v1)*
- `create_acc_recurring_template_lines_table.php` *(from v1)*

**Models (12):**
- `FinancialYear`, `AccountGroup`, `Ledger`, `CostCenter`
- `VoucherType`, `Voucher`, `VoucherItem`, `Budget`
- `TaxRate`, `LedgerMapping`, `RecurringTemplate`, `RecurringTemplateLine`

**Seeders:**
- `AccountGroupSeeder` — 28 Tally groups + 4 school-specific (Capital, Current Assets, Bank Accounts, etc.)
- `VoucherTypeSeeder` — 10 types (Payment, Receipt, Contra, Journal, Sales, Purchase, Credit Note, Debit Note, Stock Journal, Payroll)
- `TaxRateSeeder` — CGST 9%, SGST 9%, IGST 18%, CGST 2.5%, SGST 2.5%

### Week 2-3: Masters CRUD

**Controllers + Form Requests + Policies + Views:**
- `FinancialYearController` — FY create/lock/activate
- `AccountGroupController` — Tree view CRUD (self-referencing parent)
- `LedgerController` — List + slide-out create/edit panel
- `CostCenterController` — Hierarchical cost center CRUD
- `VoucherTypeController` — Voucher type management

### Week 3-5: Voucher Engine (Most Critical)

**`VoucherController`** — The heart of the module:
- Create/Edit voucher with dynamic Dr/Cr line items
- Voucher type tabs (Payment/Receipt/Contra/Journal)
- Type-ahead ledger search with balance display
- Real-time debit/credit balance validation
- Auto voucher numbering per type per FY
- Narration field

**`VoucherService`:**
- `createVoucher(data)` — Validate balance, generate number, save with items
- `cancelVoucher(voucher)` — Mark cancelled, record reason
- `getNextVoucherNumber(type, fy)` — Auto-increment logic

### Week 5-6: Basic Reports + Dashboard

**`ReportService`:**
- `trialBalance(fromDate, toDate)` — Group-wise Dr/Cr with drill-down
- `profitAndLoss(fromDate, toDate)` — Income vs Expense
- `balanceSheet(asOnDate)` — Assets vs Liabilities
- `dayBook(date, voucherType)` — Transaction register

**`ReportController`:**
- Trial Balance (hierarchical, drillable)
- Profit & Loss / Income & Expenditure
- Balance Sheet
- Day Book
- Ledger Report (individual account history)
- Cash/Bank Book

**`DashboardController`:**
- KPI cards (Fee Collected MTD, Expenses MTD, Bank Balance, Outstanding)
- Income vs Expense chart (Chart.js)
- Recent vouchers table
- Quick action buttons

### Deliverables at Phase 1 End:
- [ ] Chart of Accounts with 28 seeded groups
- [ ] Ledger CRUD with bank/cash account support
- [ ] Voucher entry (Payment, Receipt, Contra, Journal)
- [ ] Double-entry validation (Dr = Cr)
- [ ] Auto voucher numbering
- [ ] Trial Balance, P&L, Balance Sheet, Day Book
- [ ] Dashboard with KPI cards
- [ ] Cost center allocation
- [ ] Financial year management with locking

---

## Phase 2: Fee Integration + Reports (2-3 weeks)

### Event-Driven Fee Posting

**`FeeIntegrationService`:**
- Listen to `FeePaymentReceived` event from StudentFee module
- Auto-create Receipt Voucher:
  - Dr Bank/Cash A/c → amount received
  - Cr Fee Income A/c → by fee head (Tuition, Transport, Lab, etc.)
- Auto-create student ledger in Sundry Debtors on first payment

**`PostFeeToAccounting` (Listener):**
```php
public function handle(FeePaymentReceived $event)
{
    $this->feeIntegrationService->postFeeReceipt(
        $event->payment,
        $event->feeHeads,
        $event->student
    );
}
```

### Extended Reports

- Outstanding Receivables (student-wise fee dues)
- Outstanding Payables (vendor pending payments)
- Cash/Bank Book with running balance
- Ledger reports with drill-down to voucher
- Budget vs Actual variance report

---

## Phase 3: Payroll (3-4 weeks)

### Week 1: Masters

**Migrations:**
- `create_acc_employee_groups_table.php`
- `create_acc_employees_table.php`
- `create_acc_pay_heads_table.php`
- `create_acc_salary_structures_table.php`
- `create_acc_salary_structure_items_table.php`
- `create_acc_employee_attendance_table.php`
- `create_acc_payroll_runs_table.php`
- `create_acc_payroll_entries_table.php`

**Controllers:**
- `EmployeeGroupController` — Group CRUD with statutory defaults
- `EmployeeController` — Employee master with tabs (Personal, Statutory, Bank, Salary)
- `PayHeadController` — Pay head definitions (earnings/deductions)
- `SalaryStructureController` — Template management with pay head items

### Week 2-3: Payroll Engine

**`PayrollService`:**
- `processPayroll(month, year)` — Bulk salary computation
  1. Load active employees with salary structures
  2. Calculate each pay head (flat, percentage, attendance-based)
  3. Apply PF/ESI/PT/TDS via `TaxService`
  4. Store in `acc_payroll_entries`
  5. Update `acc_payroll_runs` totals

**`TaxService`:**
- `calculatePF(basicDA, isApplicable)` — 12% of Basic + DA (ceiling ₹15,000)
- `calculateESI(gross, isApplicable)` — 0.75% employee / 3.25% employer (ceiling ₹21,000)
- `calculatePT(gross, state)` — State-wise slab (HP: ₹200/month)
- `calculateTDS(annualIncome, declarations)` — Income tax computation

**`PayrollController`:**
- Step 1: Select month/year, view attendance summary
- Step 2: Process payroll (queued job for large staff)
- Step 3: Review — employee-wise gross/deductions/net
- Step 4: Approve & Post (creates Journal Voucher)
- Generate payslip PDF (DomPDF)
- Generate bank transfer CSV

### Week 3: Expense Claims (from v1)

**Migrations:**
- `create_acc_expense_claims_table.php`
- `create_acc_expense_claim_lines_table.php`

**`ExpenseClaimController`:**
- Employee submits claim with line items + receipt uploads
- Approval workflow (draft → submitted → approved → paid)
- On approval: creates Payment Voucher (Dr Expense Ledger, Cr Bank/Cash)

### Week 3-4: Attendance + Payslips

**`AttendanceController`:**
- Bulk monthly attendance grid
- Present days, LWP, overtime

**Payslip PDF:**
- A5 printable payslip (DomPDF, inline styles, tables only — same as HPC pattern D13)
- Earnings table (left) | Deductions table (right)
- Employee details, net pay, YTD summary

---

## Phase 4: Inventory (2-3 weeks)

### Masters + Stock Movements

**Migrations:**
- `create_acc_stock_groups_table.php`
- `create_acc_units_of_measure_table.php`
- `create_acc_stock_items_table.php`
- `create_acc_godowns_table.php`
- `create_acc_stock_entries_table.php`

**Controllers:**
- `StockGroupController` — Hierarchical group CRUD
- `StockItemController` — Item master with valuation method
- `GodownController` — Storage location CRUD
- `StockEntryController` — Issue/Receive/Transfer
  - Each stock movement creates a voucher (Purchase/Stock Journal)
  - Updates stock quantity via `InventoryService`

**`InventoryService`:**
- `getCurrentStock(itemId, godownId)` — Real-time stock from entries
- `getStockValuation(itemId, method)` — FIFO / Weighted Avg / Last Purchase
- `getReorderAlerts()` — Items below reorder level
- `issueStock(items, issuedTo)` — Create outward entries + voucher
- `receiveStock(items, supplier)` — Create inward entries + voucher

**Seeder:**
- `UnitOfMeasureSeeder` — Pcs, Kg, Ltr, Box, Ream, Set, Btl, Pair

---

## Phase 5: Banking (2-3 weeks)

### Bank Reconciliation

**Migrations:**
- `create_acc_bank_reconciliations_table.php`
- `create_acc_bank_statement_entries_table.php`

**`BankReconciliationController`:**
- Dual-pane view (Book entries vs Bank statement)
- Import bank statement (CSV/Excel via Maatwebsite)
- Auto-match by amount + date proximity
- Manual link/unlink
- BRS report generation

**`ReconciliationService`:**
- `importStatement(file, ledgerId)` — Parse CSV/Excel, store entries
- `autoMatch(ledgerId)` — Match by amount ± date window
- `reconcile(voucherItemId, bankDate)` — Mark as reconciled
- `getBRSReport(ledgerId, asOnDate)` — Balance comparison

### Tally Export (from v1)

**Migration:**
- `create_acc_tally_export_logs_table.php`

**`TallyExportController`:**
- Export ledgers, vouchers, inventory, payroll to Tally-compatible XML/CSV
- Track export history in `acc_tally_export_logs`
- Date range filtering, partial export support

---

## Phase 6: Fixed Assets + Depreciation (1-2 weeks)

> *Tables from Account_ddl_v1.sql — school-relevant asset management*

**Migrations:**
- `create_acc_asset_categories_table.php`
- `create_acc_fixed_assets_table.php`
- `create_acc_depreciation_entries_table.php`

**Controllers:**
- `AssetCategoryController` — Category CRUD with depreciation method/rate
- `FixedAssetController` — Asset register, purchase linking, location tracking

**`DepreciationService`:**
- `calculateSLM(asset)` — Straight Line Method: `(cost - salvage) / useful_life`
- `calculateWDV(asset)` — Written Down Value: `current_value * rate%`
- `runDepreciation(financialYear)` — Bulk depreciation for all active assets
- Creates Journal Voucher: Dr Depreciation Expense, Cr Accumulated Depreciation

**Seeder:**
- `AssetCategorySeeder` — Furniture (SLM 10%), IT Equipment (WDV 40%), Vehicles (WDV 15%), Building (SLM 5%), Lab Equipment (SLM 15%)

---

## Phase 7: UX Polish + Testing (2 weeks)

### Keyboard Shortcuts
```
F4 → Contra    F5 → Payment    F6 → Receipt    F7 → Journal
F8 → Sales     F9 → Purchase   Alt+G → Go To   Alt+C → Quick Create
Ctrl+A → Save  Ctrl+H → Change Mode  Ctrl+P → Print  Esc → Cancel
```

### Testing (Pest 4.x)

**Unit Tests:**
- Voucher balance validation (Dr must equal Cr)
- Payroll calculation (PF/ESI/PT/TDS)
- Stock valuation (FIFO, Weighted Avg)
- Auto voucher numbering

**Feature Tests:**
- Voucher CRUD (all 10 types)
- Report generation (Trial Balance, P&L, Balance Sheet)
- Payroll processing end-to-end
- Bank reconciliation flow
- Authorization (each role's access)

---

## Critical Rules for This Module

1. **Double-entry MUST balance** — reject voucher if Dr ≠ Cr
2. **Financial year locking** — no edits to locked FY data
3. **Voucher numbers are immutable** — never reuse or reassign
4. **All monetary values: `DECIMAL(15,2)`** — never use float
5. **Ledger balance = opening + sum(Dr items) - sum(Cr items)** — computed, never stored
6. **Payroll creates a single Journal Voucher** — atomic transaction
7. **Stock entries ALWAYS link to a voucher** — no orphan stock movements
8. **Migrations in `database/migrations/tenant/`** — never in module directory
9. **Gate::authorize() on every controller method** — no SEC-009 repeat
10. **Additive-only migrations** — never modify existing migrations

---

## Dependencies

| This Module Needs | From Module | Entities |
|-------------------|------------|----------|
| Students | StudentProfile | `std_students` (for auto-ledger) |
| Teachers | SchoolSetup | `sch_teachers` (for employee linking) |
| Fee Events | StudentFee | `FeePaymentReceived` event |
| Users | System | `sys_users` (created_by, approved_by) |

| Other Modules Need | From This Module | Use Case |
|--------------------|-----------------|----------|
| StudentFee | Accounting | Fee payment auto-posts to accounting |
| Dashboard | Accounting | Financial KPIs on school dashboard |
