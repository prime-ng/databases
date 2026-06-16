# Initial Plan v4: Account + Payroll + Inventory — Parallel Module Build

**Date:** 2026-03-19 | **Author:** Claude (Architect Mode) | **Version:** 4.0
**Changes from v3:** Verified ALL tables against `0-DDL_Masters/tenant_db_v2.sql`. Fixed incorrect "existing" claims. Corrected table name singulars. Resolved `sch_categories` vs `sch_employee_groups` duplication. Documented old DDL migration.

---

## 1. Executive Summary

Three **separate, interconnected** Laravel modules:

| Module | Laravel Module | RBS | Prefix | New Tables | Existing State |
|--------|---------------|-----|--------|-----------|----------------|
| **Account** | `Modules/Accounting/` | K (70) | `acc_` | 21 new (voucher-based) | Old acc_* DDL is UNUSED draft (zero dev) — **create fresh from scratch** |
| **Payroll** | `Modules/Payroll/` | P (46) | `prl_` | 17 new | SchoolSetup has Employee model; zero payroll code |
| **Inventory** | `Modules/Inventory/` | L (50) | `inv_` | 19 new | Zero code/DDL |

---

## 2. DDL VERIFICATION — What Actually Exists in `tenant_db_v2.sql`

### Tables Correctly Referenced as Existing
| Table | Line # | Notes |
|-------|--------|-------|
| `sch_employees` | 955 | Employee master. Missing `is_active`, `created_by`. Needs payroll column enhancements. |
| `sch_employees_profile` | 984 | Role, department, skills. No changes needed. |
| `sch_leave_types` | 564 | code, name, `is_paid`, `requires_approval`, `allow_half_day` |
| `sch_leave_config` | 602 | academic_year, `staff_category_id`→sch_categories, `leave_type_id`→sch_leave_types, `total_allowed`, `carry_forward`, `max_carry_forward` |
| `sch_categories` | 584 | code, name, `applicable_for`(STUDENT/STAFF/BOTH) — **serves as employee grouping** |
| `sch_department` | 476 | **SINGULAR** name (not `sch_departments`) |
| `sch_designation` | 486 | **SINGULAR** name (not `sch_designations`) |
| `sch_teacher_profile` | 1035 | **SINGULAR** name (not `sch_teacher_profiles`) |
| `sch_teacher_capabilities` | 1088 | Subject-teacher competency |
| `sch_attendance_types` | 543 | code (P/A/L/H), `applicable_for`(STUDENT/STAFF/BOTH) |

### Tables INCORRECTLY Claimed as Existing (v2/v3 error — NOW FIXED)
| Table Claimed | Reality | Fix |
|--------------|---------|-----|
| `sch_employee_groups` | **DOES NOT EXIST** | Use existing `sch_categories` + new `prl_category_statutory_config` |
| `sch_employee_attendance` | **DOES NOT EXIST** | Create as new `prl_monthly_attendance` |
| `sch_teachers` | **DOES NOT EXIST** as separate table | Use `sch_employees` where `is_teacher=1` + `sch_teacher_profile` |
| `sch_departments` | Wrong name | Correct: `sch_department` (SINGULAR) |
| `sch_designations` | Wrong name | Correct: `sch_designation` (SINGULAR) |
| `sch_teacher_profiles` | Wrong name | Correct: `sch_teacher_profile` (SINGULAR) |

### Key Insight: `sch_categories` = Employee Groups
`sch_categories` already serves as staff categorization. `sch_leave_config` uses `staff_category_id` FK → `sch_categories`. Creating a separate `sch_employee_groups` would DUPLICATE this. Instead, Payroll creates `prl_category_statutory_config` that extends `sch_categories` with PF/ESI/PT flags.

### Existing acc_* Tables — OLD Schema (Journal-Based) → REPLACED by Voucher-Based

The current `tenant_db_v2.sql` contains 31 `acc_*` tables using a journal-entry model. These are **unused initial drafts with zero development** done on them. Our new Tally-inspired design **replaces them entirely** with a fresh voucher-based schema:

| Old Table (to be removed/replaced) | New Table (voucher-based) |
|-------------------------------------|--------------------------|
| `acc_journal_entries` + `acc_journal_entry_lines` | `acc_vouchers` + `acc_voucher_items` |
| `acc_sales_invoices` | Handled via voucher type=SALES |
| `acc_purchase_invoices` | Handled via voucher type=PURCHASE |
| `acc_invoice_tax_lines` + `acc_invoice_lines` | Voucher items with ledger references |
| `acc_payment_transactions` + `acc_receipts` | Handled via voucher type=RECEIPT/PAYMENT |
| `acc_recurring_journal_templates` + lines | `acc_recurring_templates` + `acc_recurring_template_lines` |
| `acc_fee_heads/structures/lines/discount_types/concessions` | **EXCLUDED** — fee managed by StudentFee module |

**Tables KEPT (compatible with new design):**
`acc_account_groups`, `acc_ledgers` (restructured), `acc_tax_rates`, `acc_ledger_mappings` (expanded), `acc_cost_centers`, `acc_budgets`, `acc_expense_claims` + lines, `acc_bank_reconciliations` + matches (restructured), `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries`, `acc_tally_export_logs`

**Migration approach:** Since old DDL is completely unused (zero development), simply delete the old `acc_*` section from `tenant_db_v2.sql` and replace with the new voucher-based DDL. No data migration needed.

---

## 3. Architecture Overview

```
      CORE ACCOUNTING                   PAYROLL                      INVENTORY
┌──────────────────────────┐  ┌──────────────────────────┐  ┌───────────────────────────┐
│  Modules/Accounting/     │  │  Modules/Payroll/        │  │  Modules/Inventory/       │
│  Route: /accounting/*    │  │  Route: /payroll/*       │  │  Route: /inventory/*      │
│                          │  │                          │  │                           │
│  acc_financial_years     │  │  prl_pay_heads           │  │  inv_stock_groups         │
│  acc_account_groups      │  │  prl_salary_structures   │  │  inv_stock_items          │
│  acc_ledgers             │  │  prl_payroll_runs        │  │  inv_godowns              │
│  acc_voucher_types       │  │  prl_payroll_entries     │  │  inv_stock_entries        │
│  acc_vouchers            │  │  prl_leave_applications  │  │  inv_purchase_orders      │
│  acc_voucher_items       │  │  prl_leave_balances      │  │  inv_goods_receipt_notes  │
│  acc_cost_centers        │  │  prl_attendance_logs     │  │  inv_purchase_reqs        │
│  acc_budgets             │  │  prl_monthly_attendance  │  │  inv_issue_requests       │
│  acc_tax_rates           │  │  prl_statutory_configs   │  │  inv_units_of_measure     │
│  acc_bank_recon          │  │  prl_category_stat_cfg   │  │                           │
│  acc_fixed_assets        │  │  prl_appraisal_*         │  │  Links: vnd_vendors       │
│  acc_expense_claims      │  │  prl_training_*          │  │         sch_department    │
│  acc_tally_*             │  │                          │  │         sch_employees     │
│                          │  │  Reuses: sch_employees   │  │                           │
│  ┌────────────────────┐  │  │  sch_categories          │  │                           │
│  │   VOUCHER ENGINE   │◄─┼──┤  sch_leave_types         │  │                           │
│  │   (Double-Entry)   │◄─┼──┤  sch_leave_config        │  │                           │
│  │   VoucherService   │  │  │                          │◄─┼── GRN/Issue events        │
│  └────────────────────┘  │  │                          │  │                           │
└─────────────┬────────────┘  └──────────────────────────┘  └───────────────────────────┘
              │
     ┌────────┴───────┬──────────────┬──────────────┐
     ▼                ▼              ▼              ▼
┌──────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐
│StudentFee│  │SchoolSetup│  │  Vendor  │  │Transport │
│ (fin_*)  │  │ (sch_*)   │  │ (vnd_*)  │  │ (tpt_*)  │
└──────────┘  └───────────┘  └──────────┘  └──────────┘
```

---

## 4. Database Schema Summary

### Module 1: Accounting (`acc_` prefix) — 21 NEW tables
| Table | Purpose |
|-------|---------|
| `acc_financial_years` | Fiscal year config with locking |
| `acc_account_groups` | Hierarchical COA (Tally's 28 groups + custom) |
| `acc_ledgers` | Individual accounts (bank, cash, student, employee, vendor) |
| `acc_voucher_types` | Payment, Receipt, Contra, Journal, Sales, Purchase, etc. |
| `acc_vouchers` | THE heart — every transaction is a voucher |
| `acc_voucher_items` | Dr/Cr line items per voucher |
| `acc_cost_centers` | Department/activity-based tracking |
| `acc_budgets` | Fiscal year budget per cost center per ledger |
| `acc_tax_rates` | CGST/SGST/IGST/Cess rates |
| `acc_ledger_mappings` | Cross-module ledger links (Fees, Vendor, Transport, Inventory, Payroll) |
| `acc_recurring_templates` | Auto-posting templates |
| `acc_recurring_template_lines` | Template line items |
| `acc_bank_reconciliations` | Bank statement reconciliation |
| `acc_bank_statement_entries` | Imported bank transactions |
| `acc_asset_categories` | Asset types with depreciation config |
| `acc_fixed_assets` | Individual asset register |
| `acc_depreciation_entries` | Depreciation records |
| `acc_expense_claims` | Staff expense claims (employee_id → sch_employees) |
| `acc_expense_claim_lines` | Claim line items |
| `acc_tally_export_logs` | Tally XML export audit |
| `acc_tally_ledger_mappings` | Our ledgers ↔ Tally ledger names |

### Module 2: Payroll (`prl_` prefix) — 17 NEW tables
| Table | Purpose |
|-------|---------|
| `prl_pay_heads` | Earnings/Deductions (Basic, HRA, PF, ESI, PT, TDS) |
| `prl_salary_structures` | Pay grade templates |
| `prl_salary_structure_items` | Template → pay head mapping |
| `prl_payroll_runs` | Monthly payroll batches |
| `prl_payroll_entries` | Individual employee salary per run |
| `prl_leave_applications` | Leave request workflow |
| `prl_leave_balances` | Running balance per employee/type/year |
| `prl_attendance_logs` | Daily check-in/out |
| `prl_monthly_attendance` | Monthly summary for payroll LOP calc (**NEW — was incorrectly claimed as existing**) |
| `prl_statutory_configs` | PF/ESI/PT/TDS rate configs |
| `prl_employee_statutory_details` | Per-employee PF/ESI/UAN/PAN |
| `prl_category_statutory_config` | Maps `sch_categories` → PF/ESI/PT applicability (**REPLACES non-existent sch_employee_groups**) |
| `prl_appraisal_templates` | KPI templates |
| `prl_appraisal_template_kpis_jnt` | Template KPI lines |
| `prl_appraisal_cycles` | Appraisal periods |
| `prl_appraisals` | Individual appraisals |
| `prl_appraisal_scores` | KPI-level scores |
| `prl_training_programs` | Training master |
| `prl_training_enrollments_jnt` | Enrollment + feedback |

### Enhanced Existing Table (ALTER TABLE only)
| Table | Enhancement |
|-------|------------|
| `sch_employees` | Add: `is_active`, `created_by`, `ledger_id`, `salary_structure_id`, `staff_category_id`, `bank_name`, `bank_account_number`, `bank_ifsc`, `pf_number`, `esi_number`, `uan`, `pan`, `ctc_monthly`, `date_of_leaving` |

> **Only `sch_employees` is enhanced.** `sch_employee_groups` and `sch_employee_attendance` do NOT exist — replaced by `prl_category_statutory_config` and `prl_monthly_attendance`.

### Existing Tables REUSED (no changes)
| Table | Used By |
|-------|---------|
| `sch_categories` | Payroll (staff grouping via `applicable_for='STAFF'`) |
| `sch_leave_types` | Payroll (leave type definitions) |
| `sch_leave_config` | Payroll (annual leave allocation per category) |
| `sch_department` | All 3 modules (cost center mapping) |
| `sch_designation` | Payroll (employee title) |
| `sch_attendance_types` | Payroll (P/A/L/H codes) |
| `sch_teacher_profile` | Payroll (teacher-specific data) |
| `sch_teacher_capabilities` | Payroll (subject competency) |

### Module 3: Inventory (`inv_` prefix) — 19 NEW tables
*(Same as v3 — no changes needed)*

### Table Totals
| Category | Count |
|----------|-------|
| Accounting (new `acc_`) | 21 |
| Payroll (new `prl_`) | 19 |
| Inventory (new `inv_`) | 19 |
| `sch_employees` ALTER | 1 |
| Existing tables reused | 8 |
| Old `acc_*` tables REPLACED | 31 removed, 21 new |
| **Net new tables** | **59** |

---

## 5. Key Integration Points

### StudentFee → Accounting
```
Event: FeePaymentReceived → Receipt Voucher (Dr Bank/Cash, Cr Fee Income)
```

### Transport → Accounting
```
Event: TransportFeeCharged → Sales Voucher (Dr Student Debtor, Cr Transport Fee Income)
Event: TransportFeeCollected → Receipt Voucher (Dr Bank/Cash, Cr Student Debtor)
```

### Payroll → Accounting
```
Event: PayrollApproved → Payroll Journal Voucher (Dr Salary Expense, Cr PF/ESI/TDS/PT/Net Payable)
```

### Inventory → Accounting
```
Event: GrnAccepted → Purchase Voucher (Dr Stock-in-Hand, Cr Vendor Creditor)
Event: StockIssued → Stock Journal (Dr Dept Consumption, Cr Stock-in-Hand)
```

### Leave Config Flow
```
sch_categories (staff groups) → sch_leave_config (allocation per category per year)
                              → prl_category_statutory_config (PF/ESI/PT flags per category)
                              → prl_leave_balances (runtime balance per employee per type)
```

---

## 6. Key Business Rules

1. **Double-Entry:** Every voucher MUST balance (Total Debit = Total Credit)
2. **Financial Year Lock:** Locked FY prevents all edits
3. **Voucher Numbering:** Auto-increment per type per FY, configurable prefix
4. **Ledger Balance:** NEVER stored — always computed from voucher items
5. **Payroll Posting:** One Journal Voucher per payroll run via VoucherServiceInterface
6. **Stock Valuation:** Configurable per item (FIFO, Weighted Average, Last Purchase)
7. **Tenant Isolation:** Dedicated DB per tenant — NO `tenant_id` columns
8. **sch_employees Reuse:** Enhance via ALTER TABLE, never duplicate
9. **sch_categories = Employee Groups:** Use existing category system, extend with `prl_category_statutory_config`
10. **Leave Allocation:** `prl_leave_balances.total_allocated` sourced from `sch_leave_config.total_allowed`
11. **`is_teacher` flag:** No separate `sch_teachers` table — use `sch_employees.is_teacher = 1`

---

## 7. Module Structures (3 Separate Modules)

### Modules/Accounting/ — 18 controllers, 9 services, 21 models
### Modules/Payroll/ — 11 controllers, 6 services, 19 models
### Modules/Inventory/ — 14 controllers, 6 services, 19 models

---

## 8. Next Steps

1. **Create DDL files:**
   - `20-Account/DDL/acc_voucher_schema_v1.sql` — 21 new tables (replaces old journal-based acc_*)
   - `21-Payroll/DDL/prl_tables_v1.sql` — 19 new tables
   - `22-Inventory/DDL/inv_tables_v1.sql` — 19 new tables
   - `sch_employees_enhancement.sql` — ALTER TABLE additions
2. **Document migration:** Old acc_* DDL → New voucher-based DDL migration script
3. **Screen Planning → Module Scaffold → Backend → Frontend → Security → Testing → Deploy**
