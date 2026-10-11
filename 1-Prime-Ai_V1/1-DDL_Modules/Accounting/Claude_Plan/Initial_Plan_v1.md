# Initial Plan: Account + Payroll + Inventory — Parallel Module Build

**Date:** 2026-03-19 | **Author:** Claude (Architect Mode) | **Status:** Planning

---

## 1. Executive Summary

Three interconnected modules for Prime-AI (multi-tenant SaaS ERP for Indian K-12 schools):

| Module | RBS Code | Sub-Tasks | Prefix | Existing State |
|--------|----------|-----------|--------|----------------|
| **Account** | K | 70 | `acc_` | DDL v2.0 exists (31 tables), reference architecture ready, zero Laravel code |
| **Payroll** | P | 46 | `acc_` (payroll domain) | SchoolSetup has Employee/Teacher models; zero payroll code |
| **Inventory** | L | 50 | `acc_` (inventory domain) | Zero code/DDL |

**Architecture:** Tally-Prime inspired — all three are **domains** within a unified **Voucher Engine**. Every financial transaction (payment, receipt, salary, stock movement) flows through `acc_vouchers` + `acc_voucher_items` as double-entry Dr/Cr pairs.

---

## 2. Architecture Overview

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
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   BANKING    │  │ FIXED ASSETS │  │  EXPENSE     │        │
│  │ Reconcile    │  │ Depreciation │  │  CLAIMS      │        │
│  │ Import Stmt  │  │ Asset Reg.   │  │  Approval    │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└──────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │  StudentFee  │  │ SchoolSetup  │  │   Vendor     │
  │  Module      │  │  Module      │  │   Module     │
  │ (Fee events) │  │ (Teachers)   │  │ (Suppliers)  │
  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## 3. Database Schema Summary

### Domain 1: Core Accounting (10 tables)
| Table | Purpose |
|-------|---------|
| `acc_financial_years` | Fiscal year config with locking |
| `acc_account_groups` | Hierarchical COA (Tally's 28 groups + custom) |
| `acc_ledgers` | Individual accounts (bank, cash, student, employee) |
| `acc_voucher_types` | Payment, Receipt, Contra, Journal, Sales, Purchase, etc. |
| `acc_vouchers` | THE heart — every transaction is a voucher |
| `acc_voucher_items` | Dr/Cr line items per voucher |
| `acc_cost_centers` | Department/activity-based tracking |
| `acc_budgets` | Fiscal year budget allocation per cost center per ledger |
| `acc_tax_rates` | CGST/SGST/IGST/Cess rates |
| `acc_ledger_mappings` | Cross-module ledger links (Fees, HR, Vendor, Inventory) |
| `acc_recurring_templates` | Auto-posting templates |
| `acc_recurring_template_lines` | Template line items |

### Domain 2: Payroll (8 tables)
| Table | Purpose |
|-------|---------|
| `acc_employee_groups` | Staff categories (Teaching, Non-Teaching, Contract) |
| `acc_employees` | Employee master linked to sch_teachers + acc_ledgers |
| `acc_pay_heads` | Earnings/Deductions (Basic, HRA, PF, ESI, PT, TDS) |
| `acc_salary_structures` | Pay grade templates |
| `acc_salary_structure_items` | Template → pay head mapping |
| `acc_employee_attendance` | Monthly attendance for LOP calc |
| `acc_payroll_runs` | Monthly payroll batches |
| `acc_payroll_entries` | Individual employee salary details per run |

### Domain 3: Inventory (5 tables)
| Table | Purpose |
|-------|---------|
| `acc_stock_groups` | Hierarchical stock categories |
| `acc_units_of_measure` | UOM master (Pcs, Kg, Box, etc.) |
| `acc_stock_items` | Item master with valuation method |
| `acc_godowns` | Storage locations |
| `acc_stock_entries` | Inward/Outward/Transfer stock movements |

### Domain 4: Banking (2 tables)
| Table | Purpose |
|-------|---------|
| `acc_bank_reconciliations` | Bank statement reconciliation sessions |
| `acc_bank_statement_entries` | Imported bank transactions |

### Domain 5: Fixed Assets (3 tables)
| Table | Purpose |
|-------|---------|
| `acc_asset_categories` | Asset types with depreciation config |
| `acc_fixed_assets` | Individual asset register |
| `acc_depreciation_entries` | Monthly/yearly depreciation records |

### Domain 6: Expense Claims (2 tables)
| Table | Purpose |
|-------|---------|
| `acc_expense_claims` | Staff expense claims with approval |
| `acc_expense_claim_lines` | Claim line items |

### Domain 7: Export (1 table)
| Table | Purpose |
|-------|---------|
| `acc_tally_export_logs` | Tally XML export audit trail |

**Total: 31 tables**

---

## 4. Implementation Phases

| Phase | Scope | Tables | Controllers | Services | Timeline |
|-------|-------|--------|-------------|----------|----------|
| **Phase 1** | Core Accounting + Tax + Recurring | 12 | 10 | 3 | 4-6 weeks |
| **Phase 2** | Fee Integration + Extended Reports | 0 | 1 | 2 | 2-3 weeks |
| **Phase 3** | Payroll + Expense Claims | 10 | 7 | 2 | 3-4 weeks |
| **Phase 4** | Inventory | 5 | 4 | 1 | 2-3 weeks |
| **Phase 5** | Banking + Tally Export | 3 | 2 | 1 | 2-3 weeks |
| **Phase 6** | Fixed Assets + Depreciation | 3 | 2 | 1 | 1-2 weeks |
| **Phase 7** | UX Polish + Testing | 0 | 0 | 0 | 2 weeks |
| **Total** | | **33** | **26** | **10** | **17-23 weeks** |

---

## 5. Key Integration Points

### StudentFee → Accounting
```
Event: FeePaymentReceived
  → Creates Receipt Voucher:
       Dr  Bank/Cash A/c     ₹X
       Cr  Tuition Fee Income ₹Y
       Cr  Transport Fee      ₹Z
  → Auto-creates student ledger in Sundry Debtors
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

### Inventory → Accounting
```
Purchase: Creates Purchase Voucher
  Dr  Stock-in-Hand         ₹Cost
  Cr  Sundry Creditors      ₹Amount

Stock Issue: Creates Stock Journal
  Dr  Dept Consumption      ₹Cost
  Cr  Stock-in-Hand         ₹Cost
```

### SchoolSetup → Accounting
```
sch_teachers → acc_employees (teacher_id FK)
  → Teachers auto-linked to employee records
  → Department, designation inherited
```

---

## 6. Key Business Rules

1. **Double-Entry:** Every voucher MUST balance (Total Debit = Total Credit)
2. **Financial Year Lock:** Locked FY prevents all edits to that year's data
3. **Voucher Numbering:** Auto-increment per type per FY, with configurable prefix
4. **Ledger Balance:** Real-time computed: opening + sum(Dr items) - sum(Cr items) — never stored
5. **Payroll Posting:** Payroll run creates a single Journal Voucher in accounting
6. **Stock Valuation:** Configurable per item (FIFO, Weighted Average, Last Purchase)
7. **Bank Recon:** Auto-match by amount + date proximity; manual link for exceptions
8. **Tenant Isolation:** All tables tenant-scoped; COA seeded per tenant
9. **Soft Deletes:** All tables support soft delete; cancelled vouchers kept for audit
10. **Cost Center:** Optional on every voucher item for department-wise P&L

---

## 7. Module Structure

```
Modules/Accounting/
├── app/
│   ├── Http/Controllers/ (26 controllers)
│   ├── Http/Requests/    (~20 FormRequests)
│   ├── Models/           (31 models)
│   ├── Services/         (10 services)
│   ├── Policies/         (~15 policies)
│   ├── Events/           (3 events)
│   ├── Listeners/        (2 listeners)
│   └── Providers/        (3 providers)
├── config/accounting.php
├── database/seeders/     (5 seeders)
├── resources/views/      (~60 Blade files)
├── routes/web.php + api.php
└── tests/
```

---

## 8. Deliverables Created

| # | File | Location |
|---|------|----------|
| 1 | **This Plan** | `20-Account/Initial_Plan.md` |
| 2 | **Account Requirement** | `20-Account/Account_Requirement.md` |
| 3 | **Payroll Requirement** | `21-Payroll/Payroll_Requirement.md` |
| 4 | **Inventory Requirement** | `22-Inventory/Inventory_Requirement.md` |

---

## 9. Next Steps (After Requirements Approved)

1. **DDL Review:** Validate the existing DDL v2.0 against requirements, fix any gaps
2. **Screen Planning:** User decides tab layouts, form structures, dashboard widgets
3. **Module Scaffold:** Create Modules/Accounting/ with all models and providers
4. **Backend:** Controllers + FormRequests + Routes + Services
5. **Frontend:** Blade views following AdminLTE patterns
6. **Security:** Gate::authorize, EnsureTenantHasModule, PermissionSeeder
7. **Testing:** Pest 4.x unit + feature tests
8. **Deploy:** Migrate, seed, assign permissions, browser test
