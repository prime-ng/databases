# Initial Plan v3: Account + Payroll + Inventory — Parallel Module Build

**Date:** 2026-03-19 | **Author:** Claude (Architect Mode) | **Version:** 3.0
**Changes from v2:** 3 separate modules (not consolidated), updated prefixes, Transport integration, Tally mapping, sch_employees reuse, no tenant_id

---

## 1. Executive Summary

Three **separate, interconnected** Laravel modules for Prime-AI:

| Module | Laravel Module | RBS Code | Sub-Tasks | Table Prefix | Existing State |
|--------|---------------|----------|-----------|--------------|----------------|
| **Account** | `Modules/Accounting/` | K | 70 | `acc_` | DDL v2.0 exists (reference), zero Laravel code |
| **Payroll** | `Modules/Payroll/` | P | 46 | `prl_` + reuse `sch_` | SchoolSetup has Employee/Teacher; zero payroll code |
| **Inventory** | `Modules/Inventory/` | L | 50 | `inv_` | Zero code/DDL |

**Architecture:** Tally-Prime inspired — the **Accounting module** owns the Voucher Engine (double-entry). Payroll and Inventory are **separate modules** that consume the Voucher Engine via a shared `VoucherServiceInterface` to post their transactions into accounting.

**Key Principles:**
- **3 separate modules** — independent deployment, independent routes, own models/controllers
- **Shared voucher engine** — Accounting exposes `VoucherServiceInterface`; Payroll & Inventory consume it
- **No tenant_id** — dedicated database per tenant ensures complete data isolation
- **Reuse `sch_employees`** — enhance the existing table, never duplicate it
- **Tally mapping** — `acc_tally_ledger_mappings` table maps our ledgers to Tally ledger names

---

## 2. Architecture Overview

```
      CORE ACCOUNTING                   PAYROLL                      INVENTORY
┌──────────────────────────┐  ┌──────────────────────────┐  ┌───────────────────────────┐
│  Modules/Accounting/     │  │  Modules/Payroll/        │  │  Modules/Inventory/       │
│  Route: /accounting/*    │  │  Route: /payroll/*       │  │  Route: /inventory/*      │
│                          │  │                          │  │                           │
│  acc_account_groups      │  │  prl_pay_heads           │  │  inv_stock_groups         │
│  acc_ledgers             │  │  prl_salary_structures   │  │  inv_stock_items          │
│  acc_voucher_types       │  │  prl_payroll_runs        │  │  inv_godowns              │
│  acc_vouchers            │  │  prl_payroll_entries     │  │  inv_stock_entries        │
│  acc_voucher_items       │  │  prl_leave_applications  │  │  inv_purchase_orders      │
│  acc_cost_centers        │  │  prl_leave_balances      │  │  inv_goods_receipt_notes  │
│  acc_budgets             │  │  prl_attendance_logs     │  │  inv_purchase_reqs        │
│  acc_tax_rates           │  │  prl_appraisal_*         │  │  inv_issue_requests       │
│  acc_bank_recon          │  │  prl_training_*          │  │  inv_units_of_measure     │
│  acc_fixed_assets        │  │                          │  │                           │
│  acc_expense_claims      │  │  Reuses: sch_employees   │  │  Links: vnd_vendors       │
│  acc_tally_*             │  │  sch_employee_groups     │  │                           │
│                          │  │  sch_employee_attendance │  │                           │
│  ┌────────────────────┐  │  │                          │  │                           │
│  │   VOUCHER ENGINE   │◄─┼──┤  PayrollApproved event   │  │                           │
│  │   (Double-Entry)   │◄─┼──┤                          │◄─┼── GRN Accepted event      │
│  │   VoucherService   │  │  │                          │  │   Stock Issued event      │
│  └────────────────────┘  │  │                          │  │                           │
└─────────────┬────────────┘  └──────────────────────────┘  └───────────────────────────┘
              │
     ┌────────┴───────┬──────────────┬──────────────┐
     ▼                ▼              ▼              ▼
┌──────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐
│StudentFee│  │SchoolSetup│  │  Vendor  │  │Transport │
│ (fin_*)  │  │ (sch_*)   │  │ (vnd_*)  │  │ (tpt_*)  │
│Fee events│  │Employees  │  │Suppliers │  │Tpt fees  │
└──────────┘  └───────────┘  └──────────┘  └──────────┘
```

---

## 3. Database Schema Summary

### Module 1: Accounting (`acc_` prefix) — 20 tables

**Core Accounting (12 tables)**
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
| `acc_ledger_mappings` | Cross-module ledger links (Fees, HR, Vendor, Inventory, Transport) |
| `acc_recurring_templates` | Auto-posting templates |
| `acc_recurring_template_lines` | Template line items |

**Banking (2 tables)**
| Table | Purpose |
|-------|---------|
| `acc_bank_reconciliations` | Bank statement reconciliation sessions |
| `acc_bank_statement_entries` | Imported bank transactions |

**Fixed Assets (3 tables)**
| Table | Purpose |
|-------|---------|
| `acc_asset_categories` | Asset types with depreciation config |
| `acc_fixed_assets` | Individual asset register |
| `acc_depreciation_entries` | Monthly/yearly depreciation records |

**Expense Claims (2 tables)**
| Table | Purpose |
|-------|---------|
| `acc_expense_claims` | Staff expense claims with approval |
| `acc_expense_claim_lines` | Claim line items |

**Tally Integration (1 table)**
| Table | Purpose |
|-------|---------|
| `acc_tally_export_logs` | Tally XML export audit trail |

**Tally Ledger Mapping (1 table) — NEW**
| Table | Purpose |
|-------|---------|
| `acc_tally_ledger_mappings` | Maps our `acc_ledgers` to Tally ledger names for import/export sync |

### Module 2: Payroll (`prl_` prefix) — 7 new tables + 2 enhanced `sch_` tables

**New Payroll Tables (prefix `prl_`)**
| Table | Purpose |
|-------|---------|
| `prl_pay_heads` | Earnings/Deductions (Basic, HRA, PF, ESI, PT, TDS) |
| `prl_salary_structures` | Pay grade templates |
| `prl_salary_structure_items` | Template → pay head mapping |
| `prl_payroll_runs` | Monthly payroll batches |
| `prl_payroll_entries` | Individual employee salary details per run |
| `prl_leave_applications` | Leave request workflow |
| `prl_leave_balances` | Running leave balance per employee per type per year |
| `prl_attendance_logs` | Daily attendance (biometric/manual) |
| `prl_statutory_configs` | PF/ESI/PT/TDS rate configs |
| `prl_employee_statutory_details` | Per-employee PF/ESI/UAN/PAN |
| `prl_appraisal_templates` | KPI template definitions |
| `prl_appraisal_template_kpis_jnt` | Template KPI line items |
| `prl_appraisal_cycles` | Appraisal periods |
| `prl_appraisals` | Individual appraisals |
| `prl_appraisal_scores` | KPI-level scores |
| `prl_training_programs` | Training master |
| `prl_training_enrollments_jnt` | Employee enrollment + feedback |
| `sch_employee_groups` | Staff categories (Teaching, Non-Teaching, Contract) |
| `sch_employee_attendance` | Monthly attendance for LOP calc |

**Enhanced Existing Tables (prefix `sch_`) — NOT new, just add columns**
| Table | Enhancement |
|-------|------------|
| `sch_employees` | Add: `ledger_id`, `salary_structure_id`, `bank_name`, `bank_account_number`, `bank_ifsc`, `pf_number`, `esi_number`, `uan`, `pan`, `ctc_monthly`, `date_of_leaving` |
| `sch_employee_groups` | Add: `is_pf_applicable`, `is_esi_applicable`, `is_pt_applicable` (NEW table if doesn't exist, or add to `sch_categories`) |
| `sch_employee_attendance` | Monthly attendance summary: `employee_id`, `month`, `year`, `total_days`, `present_days`, `lwp_days`, `overtime_hours` |

### Module 3: Inventory (`inv_` prefix) — 19 new tables

| Table | Purpose |
|-------|---------|
| `inv_stock_groups` | Hierarchical stock categories |
| `inv_units_of_measure` | UOM master (Pcs, Kg, Box, etc.) |
| `inv_uom_conversions` | Conversion rules (1 Box = 10 Pcs) |
| `inv_stock_items` | Item master with valuation method, reorder levels |
| `inv_godowns` | Storage locations |
| `inv_stock_entries` | Inward/Outward/Transfer stock movements (always linked to voucher) |
| `inv_item_vendor_jnt` | Vendor-item linkage with rates |
| `inv_rate_contracts` | Vendor rate agreements |
| `inv_rate_contract_items_jnt` | Rate contract line items |
| `inv_purchase_requisitions` | PR master (approval workflow) |
| `inv_purchase_requisition_items` | PR line items |
| `inv_purchase_orders` | PO master (lifecycle management) |
| `inv_purchase_order_items` | PO line items |
| `inv_goods_receipt_notes` | GRN master with QC |
| `inv_grn_items` | GRN line items with batch/expiry |
| `inv_issue_requests` | Department issue requests |
| `inv_issue_request_items` | Issue request line items |
| `inv_stock_issues` | Stock issuance master |
| `inv_stock_issue_items` | Stock issuance line items |

**Grand Total: 20 (acc_) + 17 (prl_) + 19 (inv_) + 2-3 sch_ enhancements = ~58 tables**

---

## 4. Key Integration Points

### StudentFee → Accounting
```
Event: FeePaymentReceived
  → Creates Receipt Voucher:
       Dr  Bank/Cash A/c     ₹X
       Cr  Tuition Fee Income ₹Y
       Cr  Transport Fee      ₹Z
  → Auto-creates student ledger in Sundry Debtors
```

### Transport → Accounting
```
Event: TransportFeeCharged
  → When student registers for transport from a specific stoppage:
       Dr  Student Debtor (student ledger)     ₹Amount
       Cr  Transport Fee Income                ₹Amount
  → Transport fee collection follows same Receipt Voucher flow as StudentFee
  → acc_ledger_mappings: source_module='Transport', source_type='Route/Stoppage'
  → Transport fines also create Journal Voucher (Dr Student, Cr Fine Income)
```

### Payroll → Accounting
```
Event: PayrollApproved
  → Creates Payroll Journal Voucher:
       Dr  Salary Expense (by dept cost center) ₹Gross
       Dr  Employer PF Contribution             ₹PF_employer
       Dr  Employer ESI Contribution            ₹ESI_employer
       Cr  PF Payable                           ₹(PF_emp + PF_employer)
       Cr  ESI Payable                          ₹(ESI_emp + ESI_employer)
       Cr  TDS Payable                          ₹TDS
       Cr  PT Payable                           ₹PT
       Cr  Salary Payable (per employee)        ₹Net
```

### Inventory → Accounting
```
GRN Accepted: Creates Purchase Voucher
  Dr  Stock-in-Hand         ₹Cost
  Cr  Sundry Creditors      ₹Amount

Stock Issue: Creates Stock Journal
  Dr  Dept Consumption      ₹Cost (cost center tagged)
  Cr  Stock-in-Hand         ₹Cost

Stock Adjustment: Creates Journal
  Dr/Cr Stock-in-Hand       ₹Diff
  Cr/Dr Stock Adjustment A/c ₹Diff
```

### SchoolSetup → All Modules
```
sch_employees → used by Payroll (salary, attendance, leave)
sch_teachers  → linked via sch_employees.is_teacher
sch_departments → used for cost center mapping
sch_designations → used for employee designation
```

---

## 5. Tally Ledger Mapping Mechanism

### New Table: `acc_tally_ledger_mappings`

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT UNSIGNED PK | Primary key |
| ledger_id | BIGINT UNSIGNED FK | FK → acc_ledgers (our ledger) |
| tally_ledger_name | VARCHAR(200) | Exact Tally ledger name |
| tally_group_name | VARCHAR(200) NULL | Tally group name for context |
| tally_alias | VARCHAR(200) NULL | Tally alias if any |
| mapping_type | ENUM('auto','manual') | How mapped (auto during seed, manual by user) |
| is_active, created_by, created_at, updated_at, deleted_at | Standard | Standard |
| UNIQUE | (ledger_id, tally_ledger_name) | One mapping per pair |

### How It Works
1. **During tenant seed:** Auto-create mappings for the 28 standard Tally groups + default ledgers (Cash, Bank, P&L, etc.)
2. **User-managed:** School accountant can map custom ledgers (e.g., "School Bus Fee Income" ↔ Tally's "Transport Fee Income")
3. **On Tally Export:** `TallyExportService` reads mappings to use correct Tally names in XML
4. **On Tally Import:** (future) Parse Tally XML and match to our ledgers via this mapping table
5. **UI:** Mapping screen under Accounting → Settings → Tally Integration — two-column table (Our Ledger | Tally Ledger Name)

---

## 6. Key Business Rules

1. **Double-Entry:** Every voucher MUST balance (Total Debit = Total Credit)
2. **Financial Year Lock:** Locked FY prevents all edits to that year's data
3. **Voucher Numbering:** Auto-increment per type per FY, with configurable prefix
4. **Ledger Balance:** Real-time computed: opening + sum(Dr items) - sum(Cr items) — NEVER stored
5. **Payroll Posting:** Payroll run creates a single Journal Voucher in Accounting
6. **Stock Valuation:** Configurable per item (FIFO, Weighted Average, Last Purchase)
7. **Bank Recon:** Auto-match by amount + date proximity; manual link for exceptions
8. **Tenant Isolation:** Dedicated database per tenant — NO `tenant_id` columns anywhere
9. **Soft Deletes:** All tables support soft delete; cancelled vouchers kept for audit
10. **Cost Center:** Optional on every voucher item for department-wise P&L
11. **sch_employees Reuse:** Payroll module enhances existing `sch_employees` table with salary/bank columns — never recreates
12. **Transport Fee Integration:** Transport fee charges and fines flow through the voucher engine same as student fees

---

## 7. Module Structures (3 Separate Modules)

### Modules/Accounting/
```
Modules/Accounting/
├── app/
│   ├── Contracts/
│   │   └── VoucherServiceInterface.php    ← Shared interface for Payroll & Inventory
│   ├── Http/Controllers/ (17 controllers)
│   │   ├── AccountGroupController.php
│   │   ├── LedgerController.php
│   │   ├── LedgerMappingController.php
│   │   ├── FinancialYearController.php
│   │   ├── VoucherTypeController.php
│   │   ├── VoucherController.php
│   │   ├── CostCenterController.php
│   │   ├── BudgetController.php
│   │   ├── TaxRateController.php
│   │   ├── RecurringTemplateController.php
│   │   ├── BankReconciliationController.php
│   │   ├── AssetCategoryController.php
│   │   ├── FixedAssetController.php
│   │   ├── ExpenseClaimController.php
│   │   ├── TallyExportController.php
│   │   ├── TallyLedgerMappingController.php
│   │   ├── AccReportController.php
│   │   └── AccDashboardController.php
│   ├── Http/Requests/    (~15 FormRequests)
│   ├── Models/           (21 models — 1 per acc_ table)
│   ├── Services/         (9 services)
│   ├── Events/           (VoucherPosted, etc.)
│   ├── Listeners/        (PostFeeToAccounting, PostTransportFeeToAccounting)
│   └── Providers/        (AccountingServiceProvider, RouteServiceProvider, EventServiceProvider)
├── config/accounting.php
├── database/seeders/
├── resources/views/
├── routes/web.php + api.php
└── tests/
```

### Modules/Payroll/
```
Modules/Payroll/
├── app/
│   ├── Http/Controllers/ (11 controllers)
│   │   ├── PayHeadController.php
│   │   ├── SalaryStructureController.php
│   │   ├── EmployeeSalaryController.php
│   │   ├── PayrollController.php
│   │   ├── AttendanceController.php
│   │   ├── LeaveApplicationController.php
│   │   ├── StatutoryConfigController.php
│   │   ├── AppraisalController.php
│   │   ├── TrainingController.php
│   │   ├── PrlReportController.php
│   │   └── PrlDashboardController.php
│   ├── Http/Requests/    (~10 FormRequests)
│   ├── Models/           (17 models — 1 per prl_ table)
│   ├── Services/         (6 services)
│   │   ├── PayrollComputeService.php    ← Uses Accounting's VoucherServiceInterface
│   │   ├── StatutoryCalcService.php
│   │   ├── LeaveApplicationService.php
│   │   ├── AttendanceSyncService.php
│   │   ├── AppraisalService.php
│   │   └── PayslipPdfService.php
│   ├── Events/           (PayrollApproved, LeaveApproved)
│   └── Providers/
├── config/payroll.php    (PF/ESI/PT/TDS rates)
├── database/seeders/
├── resources/views/
├── routes/web.php + api.php
└── tests/
```

### Modules/Inventory/
```
Modules/Inventory/
├── app/
│   ├── Http/Controllers/ (14 controllers)
│   │   ├── StockGroupController.php
│   │   ├── UomController.php
│   │   ├── StockItemController.php
│   │   ├── GodownController.php
│   │   ├── StockEntryController.php
│   │   ├── ItemVendorController.php
│   │   ├── RateContractController.php
│   │   ├── PurchaseRequisitionController.php
│   │   ├── PurchaseOrderController.php
│   │   ├── GrnController.php
│   │   ├── IssueRequestController.php
│   │   ├── StockIssueController.php
│   │   ├── InvReportController.php
│   │   └── InvDashboardController.php
│   ├── Http/Requests/    (~12 FormRequests)
│   ├── Models/           (19 models — 1 per inv_ table)
│   ├── Services/         (6 services)
│   │   ├── StockLedgerService.php       ← Uses Accounting's VoucherServiceInterface
│   │   ├── PurchaseOrderService.php
│   │   ├── GrnPostingService.php
│   │   ├── ReorderAlertService.php
│   │   ├── StockValuationService.php
│   │   └── InventoryReportService.php
│   ├── Events/           (GrnAccepted, StockIssued, ReorderAlert)
│   └── Providers/
├── database/seeders/
├── resources/views/
├── routes/web.php + api.php
└── tests/
```

---

## 8. Implementation Phases

| Phase | Scope | Module | Tables | Controllers | Timeline |
|-------|-------|--------|--------|-------------|----------|
| **Phase 1** | Core Accounting + Tax + Recurring + Tally Mapping | Accounting | 14 | 12 | 4-5 weeks |
| **Phase 2** | Fee + Transport Integration + Extended Reports | Accounting | 0 | 2 | 2-3 weeks |
| **Phase 3** | Payroll Masters + Monthly Run | Payroll | 9 | 6 | 3-4 weeks |
| **Phase 4** | Leave + Attendance + Appraisals + Training | Payroll | 8 | 5 | 2-3 weeks |
| **Phase 5** | Inventory Masters + Procurement (PR/PO/GRN) | Inventory | 15 | 10 | 3-4 weeks |
| **Phase 6** | Stock Issue + Reports + Reorder | Inventory | 4 | 4 | 2-3 weeks |
| **Phase 7** | Banking + Fixed Assets + Expense Claims | Accounting | 6 | 4 | 2-3 weeks |
| **Phase 8** | Tally Export + UX Polish + Testing | All 3 | 1 | 1 | 2 weeks |
| **Total** | | **3 modules** | **~57** | **~44** | **20-27 weeks** |

**Parallel Opportunities:** Phases 3-4 (Payroll) and 5-6 (Inventory) can run in parallel after Phase 1 completes.

---

## 9. Deliverables

| # | File | Location |
|---|------|----------|
| 1 | **This Plan (v3)** | `20-Account/Claude_Plan/Initial_Plan_v3.md` |
| 2 | **Account Requirement (v3)** | `20-Account/Claude_Plan/Account_Requirement_v3.md` |
| 3 | **Payroll Requirement** | `21-Payroll/Payroll_Requirement.md` |
| 4 | **Inventory Requirement** | `22-Inventory/Inventory_Requirement.md` |

---

## 10. Next Steps (After Requirements Approved)

1. **DDL Review:** Read & validate existing DDL v1.0 `Account_ddl_v1.sql` against requirements
2. **DDL Creation:** Create corrected DDL files:
   - `20-Account/DDL/acc_tables_v2.sql` — all `acc_` tables
   - `21-Payroll/DDL/prl_tables_v1.sql` — all `prl_` tables
   - `22-Inventory/DDL/inv_tables_v1.sql` — all `inv_` tables
   - `sch_employees_enhancement.sql` — ALTER TABLE additions
3. **Screen Planning:** User decides tab layouts, form structures, dashboard widgets
4. **Module Scaffold:** Create 3 separate modules with models and providers
5. **Backend:** Controllers + FormRequests + Routes + Services
6. **Frontend:** Blade views following AdminLTE patterns
7. **Security:** Gate::authorize, EnsureTenantHasModule, PermissionSeeder
8. **Testing:** Pest 4.x unit + feature tests + Dusk Browser tests
9. **Deploy:** Migrate, seed, assign permissions, browser test
