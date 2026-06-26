# Accounting Module — Architecture Document

**Module:** Accounting | **Prefix:** `acc_` | **Type:** Tenant | **Route:** `/accounting/*`
**Inspired by:** Tally Prime | **Status:** Planning

---

## 1. System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    ACCOUNTING MODULE                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐      │
│  │    CORE      │  │   PAYROLL    │  │   INVENTORY    │      │
│  │  ACCOUNTING  │  │              │  │                │      │
│  │              │  │ Employees    │  │ Stock Groups   │      │
│  │ Ledgers      │  │ Pay Heads    │  │ Stock Items    │      │
│  │ Vouchers     │  │ Salary Str.  │  │ Godowns        │      │
│  │ Groups       │  │ Payroll Runs │  │ Stock Entries  │      │
│  │ Cost Centers │  │ Attendance   │  │ UoM            │      │
│  │ Budgets      │  │ Payslips     │  │                │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬─────────┘      │
│         │                 │                 │                │
│  ┌──────┴─────────────────┴─────────────────┴───────┐        │
│  │            VOUCHER ENGINE (Double-Entry)         │        │
│  │     Every transaction = Debit + Credit entries   │        │
│  └──────────────────────┬───────────────────────────┘        │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────┐        │
│  │              REPORTING ENGINE                    │        │
│  │  Trial Balance | P&L | Balance Sheet | Day Book  │        │
│  │  Cash Flow | Ledger Reports | Budget vs Actual   │        │
│  │  Outstanding | Aging | Payroll Statements        │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ┌──────────────┐                                            │
│  │   BANKING    │                                            │
│  │ Reconcile    │                                            │
│  │ Import Stmt  │                                            │
│  │ Auto-Match   │                                            │
│  └──────────────┘                                            │
└──────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │  StudentFee  │  │ SchoolSetup  │  │   Payment    │
  │  Module      │  │  Module      │  │   Module     │
  │ (Fee events) │  │ (Teachers)   │  │ (Razorpay)   │
  └──────────────┘  └──────────────┘  └──────────────┘
```

## 2. Database Schema Overview

**33 tables across 7 domains:**

| Domain | Tables | Purpose |
|--------|--------|---------|
| Core Accounting | 8 | Financial years, groups, ledgers, voucher types, vouchers, voucher items, cost centers, budgets |
| Payroll | 8 | Employee groups, employees, pay heads, salary structures, structure items, payroll runs, payroll entries, attendance |
| Inventory | 5 | Stock groups, units of measure, stock items, godowns, stock entries |
| Banking | 2 | Bank reconciliations, bank statement imports |
| Fixed Assets | 3 | Asset categories, fixed assets, depreciation entries |
| Expense Claims | 2 | Claims, claim lines |
| Supporting | 5 | Tax rates, ledger mappings, recurring templates + lines, tally export logs |

> **Note:** Incorporates features from `Account_ddl_v1.sql` (pgdatabase). Fee management tables are intentionally excluded — handled by the existing StudentFee module (`fin_*` prefix).

See `accounting_module_ddl.sql` for complete DDL.

## 3. Entity Relationship Diagram

```
acc_account_groups (self-ref parent_id)
    │
    ├── acc_ledgers
    │       │
    │       ├── acc_voucher_items ──── acc_vouchers ──── acc_voucher_types
    │       │       │                      │
    │       │       ├── acc_bank_reconciliations
    │       │       └── acc_bank_statement_entries
    │       │
    │       ├── acc_budgets ──── acc_financial_years
    │       └── acc_employees (ledger_id)
    │
    └── acc_cost_centers (self-ref)

acc_employee_groups (self-ref)
    │
    └── acc_employees
            │
            ├── acc_employee_attendance
            └── acc_payroll_entries ──── acc_payroll_runs ──── acc_vouchers
                    │
                    └── acc_pay_heads ──── acc_salary_structure_items ──── acc_salary_structures

acc_stock_groups (self-ref)
    │
    └── acc_stock_items ──── acc_units_of_measure
            │
            └── acc_stock_entries ──── acc_godowns (self-ref)
                    │
                    └── acc_vouchers
```

## 4. Module Structure

```
Modules/Accounting/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── DashboardController.php          # Gateway dashboard
│   │   │   ├── AccountGroupController.php       # Chart of Accounts CRUD
│   │   │   ├── LedgerController.php             # Ledger CRUD
│   │   │   ├── VoucherController.php            # Voucher entry (Payment/Receipt/etc.)
│   │   │   ├── VoucherTypeController.php        # Voucher type management
│   │   │   ├── CostCenterController.php         # Cost center CRUD
│   │   │   ├── BudgetController.php             # Budget management
│   │   │   ├── FinancialYearController.php      # FY management
│   │   │   ├── ReportController.php             # All financial reports
│   │   │   ├── EmployeeController.php           # Employee master
│   │   │   ├── EmployeeGroupController.php      # Employee groups
│   │   │   ├── PayHeadController.php            # Pay head definitions
│   │   │   ├── SalaryStructureController.php    # Salary structure templates
│   │   │   ├── PayrollController.php            # Payroll processing + payslips
│   │   │   ├── AttendanceController.php         # Monthly attendance
│   │   │   ├── StockGroupController.php         # Stock group CRUD
│   │   │   ├── StockItemController.php          # Stock item CRUD
│   │   │   ├── GodownController.php             # Godown/location CRUD
│   │   │   ├── StockEntryController.php         # Stock issue/receive/transfer
│   │   │   └── BankReconciliationController.php # Bank recon + statement import
│   │   └── Requests/
│   │       ├── StoreVoucherRequest.php
│   │       ├── UpdateVoucherRequest.php
│   │       ├── StoreLedgerRequest.php
│   │       ├── StoreEmployeeRequest.php
│   │       ├── ProcessPayrollRequest.php
│   │       ├── StoreStockItemRequest.php
│   │       └── ... (Store/Update for each entity)
│   ├── Models/                                  # 23 models (1 per table)
│   ├── Services/
│   │   ├── AccountingService.php                # Chart of Accounts, balance calc
│   │   ├── VoucherService.php                   # Voucher creation, validation, numbering
│   │   ├── ReportService.php                    # Trial balance, P&L, Balance Sheet
│   │   ├── PayrollService.php                   # Salary computation engine
│   │   ├── TaxService.php                       # PF/ESI/PT/TDS calculations
│   │   ├── InventoryService.php                 # Stock valuation, reorder alerts
│   │   ├── ReconciliationService.php            # Bank statement import + matching
│   │   └── FeeIntegrationService.php            # StudentFee event listener
│   ├── Policies/
│   │   ├── VoucherPolicy.php
│   │   ├── LedgerPolicy.php
│   │   ├── EmployeePolicy.php
│   │   ├── PayrollPolicy.php
│   │   └── ... (1 per model)
│   ├── Events/
│   │   ├── VoucherPosted.php
│   │   ├── PayrollProcessed.php
│   │   └── StockMovement.php
│   ├── Listeners/
│   │   ├── PostFeeToAccounting.php              # Listens to StudentFee events
│   │   └── UpdateLedgerBalance.php
│   └── Providers/
│       └── AccountingServiceProvider.php
├── config/
│   └── accounting.php                           # Tax rates, PF/ESI limits, defaults
├── database/
│   ├── seeders/
│   │   ├── AccountGroupSeeder.php               # 28 Tally groups
│   │   ├── VoucherTypeSeeder.php                # 10 voucher types
│   │   └── UnitOfMeasureSeeder.php              # Standard UoMs
│   └── factories/
├── resources/
│   └── views/accounting/
│       ├── dashboard.blade.php
│       ├── voucher/
│       │   ├── index.blade.php                  # Day Book / Voucher list
│       │   ├── create.blade.php                 # Voucher entry (Dr/Cr grid)
│       │   └── show.blade.php                   # Voucher detail + print
│       ├── ledger/
│       ├── group/
│       ├── report/
│       │   ├── trial-balance.blade.php
│       │   ├── profit-loss.blade.php
│       │   ├── balance-sheet.blade.php
│       │   └── day-book.blade.php
│       ├── payroll/
│       │   ├── process.blade.php
│       │   ├── payslip.blade.php
│       │   └── payslip_pdf.blade.php
│       ├── inventory/
│       └── bank/
├── routes/
│   ├── web.php
│   └── api.php
└── tests/
    ├── Unit/
    │   ├── VoucherBalanceTest.php
    │   ├── PayrollCalculationTest.php
    │   └── StockValuationTest.php
    └── Feature/
        ├── VoucherCrudTest.php
        ├── ReportGenerationTest.php
        └── PayrollProcessingTest.php
```

## 5. Integration Points

### StudentFee Module → Accounting
```
Event: FeePaymentReceived
  → PostFeeToAccounting listener
  → Creates Receipt Voucher:
       Dr  Bank/Cash A/c     ₹X
       Cr  Tuition Fee Income ₹Y
       Cr  Transport Fee      ₹Z
  → Auto-creates student ledger in Sundry Debtors if not exists
```

### Payroll → Accounting
```
Event: PayrollProcessed
  → Creates Payroll Journal Voucher:
       Dr  Salary Expense (by dept)  ₹Gross
       Cr  PF Payable               ₹PF
       Cr  ESI Payable              ₹ESI
       Cr  TDS Payable              ₹TDS
       Cr  PT Payable               ₹PT
       Cr  Salary Payable           ₹Net
```

### SchoolSetup → Accounting
```
sch_teachers → acc_employees (teacher_id FK)
  → Teachers auto-linked to employee records
  → Designation, department inherited
```

## 6. User Roles & Permissions

| Role | Scope |
|------|-------|
| School Admin | Full access to all accounting |
| Accountant | Vouchers, ledgers, reports, bank recon |
| Cashier | Receipt/Payment vouchers, cash/bank book |
| Payroll Manager | Employee master, salary, payroll processing |
| Store Keeper | Inventory master, stock entries, stock reports |
| Auditor | Read-only access to all reports |

Permission strings: `accounting.voucher.create`, `accounting.payroll.process`, `accounting.report.view`, etc.

## 7. Key Business Rules

1. **Double-Entry:** Every voucher MUST balance (Total Debit = Total Credit)
2. **Financial Year Lock:** Locked FY prevents all edits to that year's data
3. **Voucher Numbering:** Auto-increment per type per FY, with configurable prefix
4. **Ledger Balance:** Real-time computed from opening + sum(voucher_items)
5. **Payroll Posting:** Payroll run creates a single Journal Voucher in accounting
6. **Stock Valuation:** Configurable per item (FIFO, Weighted Average, Last Purchase)
7. **Bank Recon:** Auto-match by amount + date proximity; manual link for exceptions
8. **Tenant Isolation:** All tables tenant-scoped; Chart of Accounts seeded per tenant
9. **Soft Deletes:** All tables support soft delete; cancelled vouchers kept for audit
10. **Cost Center:** Optional on every voucher item for department-wise P&L
