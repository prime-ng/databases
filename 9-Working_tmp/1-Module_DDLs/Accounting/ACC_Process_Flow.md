# Accounting Module — Process Flow & Architecture

**Version:** 1.0 — 2026-05-21
**Module:** `Modules/Accounting/` | **Prefix:** `acc_` | **Route:** `/accounting/*`
**Database:** tenant_db (DB per tenant) | **Inspired by:** Tally Prime

---

## Table of Contents

1. [How It's Made — Architecture](#1-how-its-made--architecture)
2. [How It Should Work — Designed Flow](#2-how-it-should-work--designed-flow)
3. [How It Currently Works — Implementation Status](#3-how-it-currently-works--implementation-status)
4. [DDL vs Code Gaps](#4-ddl-vs-code-gaps)
5. [Complete Data Flow Diagrams](#5-complete-data-flow-diagrams)
6. [Services Layer Deep-Dive](#6-services-layer-deep-dive)
7. [Cross-Module Integration](#7-cross-module-integration)
8. [Key Business Rules](#8-key-business-rules)

---

## 1. How It's Made — Architecture

### 1.1 Directory Structure

```
Modules/Accounting/
├── app/
│   ├── Http/
│   │   └── Controllers/    (20 controllers)
│   ├── Models/             (25 models)
│   └── Services/           (7 services)
├── config/
├── database/
│   └── migrations/         (EMPTY — only .gitkeep)
├── resources/
│   └── views/              (~60+ Blade views)
├── routes/
│   ├── web.php             (Full route definitions)
│   └── api.php
└── tests/                  (Feature + Unit tests)
```

### 1.2 Database Domains (25 tables)

| Domain | Tables | Description |
|--------|--------|-------------|
| **Core Accounting** (12) | `acc_financial_years`, `acc_account_groups`, `acc_ledgers`, `acc_voucher_types`, `acc_vouchers`, `acc_voucher_items`, `acc_cost_centers`, `acc_budgets`, `acc_tax_rates`, `acc_ledger_mappings`, `acc_recurring_templates`, `acc_recurring_template_lines` | Chart of Accounts, Voucher Engine, Budgeting |
| **Banking** (2) | `acc_bank_reconciliations`, `acc_bank_statement_entries` | Statement import, auto-matching |
| **Fixed Assets** (3) | `acc_asset_categories`, `acc_fixed_assets`, `acc_depreciation_entries` | SLM/WDV depreciation |
| **Expense Claims** (2) | `acc_expense_claims`, `acc_expense_claim_lines` | Staff expense workflow |
| **Tally Integration** (2) | `acc_tally_export_logs`, `acc_tally_ledger_mappings` | XML export for CA filing |
| **Event Mapping** (4) | `acc_module_events`, `acc_event_voucher_configs`, `acc_event_voucher_line_templates`, `acc_event_processing_log` | Cross-module auto-accounting |

### 1.3 Controllers (20)

| Controller | Purpose | CRUD + Workflow Routes |
|-----------|---------|----------------------|
| `FinancialYearController` | FY management | resource + lock/unlock + toggleStatus + trash/restore/forceDelete |
| `AccountGroupController` | Chart of Accounts groups | resource + toggleStatus + trash/restore/forceDelete |
| `LedgerController` | Individual ledgers | resource + toggleStatus + statement + byGroup + search + balance |
| `VoucherTypeController` | Voucher type definitions | resource + toggleStatus + trash/restore/forceDelete |
| `VoucherController` | **THE HEART** — all transactions | resource + post/approve/cancel + print + duplicate + trash/restore/forceDelete |
| `CostCenterController` | Department/wing tracking | resource + toggleStatus + trash/restore/forceDelete |
| `BudgetController` | FY budgets | resource + toggleStatus + trash/restore/forceDelete |
| `TaxRateController` | GST rate config | resource + toggleStatus + trash/restore/forceDelete |
| `LedgerMappingController` | Cross-module ledger links | resource + toggleStatus + trash/restore/forceDelete |
| `RecurringTemplateController` | Auto-posting templates | resource + toggleStatus + postNow + trash/restore/forceDelete |
| `BankReconciliationController` | Bank statement matching | resource + import/validate/autoMatch/complete + matchEntry/unmatchEntry |
| `AssetCategoryController` | Asset types with depreciation | resource + toggleStatus + trash/restore/forceDelete |
| `FixedAssetController` | Individual assets | resource + toggleStatus + runDepreciation + trash/restore/forceDelete |
| `ExpenseClaimController` | Staff claims | resource + submit/approve/reject/markPaid + trash/restore/forceDelete |
| `TallyExportController` | Tally XML export | index + exportLedgers/exportVouchers + download + trash/restore/forceDelete |
| `TallyLedgerMappingController` | Ledger ↔ Tally mapping | resource + toggleStatus + trash/restore/forceDelete |
| `ModuleEventController` | Event registry | index + create/store + edit/update + destroy + toggleStatus + trash/restore/forceDelete |
| `EventVoucherConfigController` | Per-event voucher config | create/store + edit/update + destroy |
| `AccReportController` | Financial reports | trialBalance, profitAndLoss, balanceSheet, dayBook, cashBook, bankBook, ledgerReport, outstandingReceivables, outstandingPayables, budgetVariance, gstSummary |
| `AccDashboardController` | Dashboard & menu pages | index, setupMasters, transactions, assetsIntegration, reports |

### 1.4 Models (25)

All 25 `acc_*` tables have corresponding models with SoftDeletes, relationships, scopes, and helpers.

### 1.5 Services (7)

| Service | Key Methods | Purpose |
|---------|------------|---------|
| `VoucherService` | create, update, post, cancel, duplicate, generateVoucherNumber | Voucher engine — Dr/Cr balancing, ledger balance updates, number generation |
| `ReportService` | trialBalance, profitAndLoss, balanceSheet, dayBook, cashBook, bankBook, ledgerReport, outstandingReceivables, outstandingPayables, budgetVariance, gstSummary | All financial reports with running balances |
| `RemoteEntryService` | processEvent, createVoucherFromConfig | Cross-module event → voucher processing |
| `RecurringTemplateService` | postNow, postScheduled | Auto-posting recurring journals |
| `ReconciliationService` | importStatement, autoMatch, matchEntry, unmatchEntry | Bank reconciliation matching engine |
| `ExpenseClaimService` | submit, approve, reject, markPaid | Expense claim workflow + voucher creation |
| `DepreciationService` | runDepreciation | SLM/WDV calculation + journal voucher creation |

---

## 2. How It Should Work — Designed Flow

### 2.1 Voucher Lifecycle (THE CORE)

```
                    ┌──────────────────────────────────────────────┐
                    │              VOUCHER LIFECYCLE               │
                    └──────────────────────────────────────────────┘

  ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────────┐
  │  DRAFT   │────▶│  POSTED  │────▶│ APPROVED │────▶│  CANCELLED   │
  │          │     │          │     │          │     │              │
  │ Can edit │     │ Affects  │     │ Read-only│     │ Soft-deleted │
  │ No ledg. │     │ ledgers  │     │ Final    │     │ Balances     │
  │ effect   │     │ balances │     │ status   │     │ reversed     │
  └──────────┘     └──────────┘     └──────────┘     └──────────────┘
        │                                                  ▲
        └─────── (can delete) ────────────────────────────┘
```

**Voucher Types (10 seeded):**
| Code | Category | Description |
|------|----------|-------------|
| PAYMENT | accounting | Dr Expense/Creditor, Cr Bank/Cash |
| RECEIPT | accounting | Dr Bank/Cash, Cr Income/Debtor |
| CONTRA | accounting | Dr Bank1, Cr Bank2 OR Dr Cash, Cr Bank |
| JOURNAL | accounting | Any Dr/Cr combination (adjustments) |
| SALES | accounting | Dr Debtor, Cr Income |
| PURCHASE | accounting | Dr Stock/Expense, Cr Creditor |
| CREDIT_NOTE | accounting | Dr Income, Cr Debtor (sales return) |
| DEBIT_NOTE | accounting | Dr Creditor, Cr Stock/Expense (purchase return) |
| STOCK_JOURNAL | inventory | Dr Consumption, Cr Stock |
| PAYROLL | payroll | Dr Salary Expense, Cr Payables |

### 2.2 Voucher Numbering

```
Format:   [PREFIX][YYYY]-[NNNNNN]
Example:  RCV-2026-000001

PREFIX:   From acc_voucher_types.prefix (snapshot at creation)
YYYY:     From voucher date's year
NNNNNN:   Lock-guarded sequential number per type per FY

Rules:
- NEVER reuse or change a voucher number
- LockForUpdate on voucher type to prevent duplicates
- Skip numbers already taken (soft-deleted reservations)
```

### 2.3 Double-Entry Validation

```
EVERY voucher MUST satisfy:
    SUM(debit items) == SUM(credit items)

Validation enforced at:
- FormRequest level (before store/update)
- VoucherService::create() / update()
- Voucher model has isBalanced() helper
```

### 2.4 Ledger Balance Computation

```
Ledger Balance = opening_balance ± sum(voucher_items)

DESIGN INTENT (from requirements):
  Balance = opening_balance ± sum(voucher_items)
  NEVER stored — always computed at query time.

CURRENT CODE REALITY:
  Balance is stored in current_balance column on acc_ledgers.
  Updated on Voucher post/cancel:
    - Dr items: current_balance += amount
    - Cr items: current_balance -= amount
  This creates a DATA INTEGRITY RISK if any update fails.
```

### 2.5 Financial Year Lock

```
Active FY:  is_locked = false → can create/edit/delete vouchers
Locked FY:  is_locked = true  → ALL voucher operations blocked
Lock is one-way by default (unlock requires Super Admin)
On lock: auto-calculate closing balances, carry forward
```

### 2.6 Cross-Module Event Flow (Remote Entry)

```
  [Library]         [Transport]       [Fees]          [Payroll]
      │                  │               │                │
      │ fire event with  │               │                │
      │ (module_code,    │               │                │
      │  event_code,     │               │                │
      │  source_id,      │               │                │
      │  payload)        │               │                │
      ▼                  ▼               ▼                ▼
  ┌───────────────────────────────────────────────────────────┐
  │                 RemoteEntryService                         │
  │                                                           │
  │  1. Lookup ModuleEvent (is it known & active?)            │
  │  2. Lookup EventVoucherConfig (how to post?)              │
  │  3. Resolve ledgers (fixed / student / vendor / employee) │
  │  4. Resolve amounts (from_source / fixed / from_payload)  │
  │  5. Create Voucher + VoucherItems                         │
  │  6. Log to EventProcessingLog                             │
  └───────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │ acc_vouchers         │
                    │ acc_voucher_items    │
                    │ acc_event_processing_log
                    └─────────────────────┘
```

### 2.7 Financial Reports

| Report | Data Source | Computation |
|--------|-------------|-------------|
| **Trial Balance** | Posted voucher items | `SUM(debit) - SUM(credit)` per ledger |
| **P&L (Income & Expenditure)** | Posted items where group.nature in (income, expense) | For Income: `SUM(credit) - SUM(debit)`, For Expense: `SUM(debit) - SUM(credit)` |
| **Balance Sheet** | Posted items where group.nature in (asset, liability) | Net balance per ledger |
| **Day Book** | All vouchers by date | Raw listing |
| **Cash/Bank Book** | Voucher items where ledger.is_cash_account or is_bank_account | Running balance |
| **Ledger Report** | All items for one ledger | Opening + periodic transactions + closing |
| **Outstanding Receivables** | Ledgers with student_id | Current balance of student debtor ledgers |
| **Outstanding Payables** | Ledgers with vendor_id | Current balance of vendor creditor ledgers |
| **Budget vs Actual** | Budgets vs posted items | Variance % per cost center per ledger |
| **GST Summary** | Tax rates × voucher items | CGST/SGST/IGST collection and payment |

### 2.8 Expense Claim Workflow

```
Draft → Submitted → Approved → Paid
                  → Rejected

On APPROVED:  Auto-creates Payment Voucher (Dr Expense Ledger, Cr Bank/Cash)
On PAID:      Payment voucher posted and approved
```

### 2.9 Depreciation Flow

```
1. Admin runs "Run Depreciation" (scheduled or manual)
2. DepreciationService reads acc_fixed_assets
3. For each asset, calculate period depreciation:
   - SLM: (purchase_cost - salvage_value) / useful_life_years / 12
   - WDV: (current_value × depreciation_rate / 100) / 12
4. Creates Journal Voucher:
   - Dr Depreciation Expense ledger
   - Cr Accumulated Depreciation ledger
5. Updates acc_fixed_assets.current_value and accumulated_depreciation
6. Records acc_depreciation_entries
```

### 2.10 Bank Reconciliation Flow

```
1. Create Bank Reconciliation session (select bank ledger)
2. Upload bank statement CSV/MT940 → parsed into acc_bank_statement_entries
3. Auto-match: matches statement entries to voucher items by:
   - Amount match
   - Date proximity
   - Reference match
4. Manual match/unmatch for exceptions
5. Complete reconciliation → status = Completed
```

---

## 3. How It Currently Works — Implementation Status

### 3.1 What's BUILT (code exists)

| Area | Status | Details |
|------|--------|---------|
| **Controllers** | ✅ 20/20 | All CRUD + workflow methods implemented |
| **Models** | ✅ 25/25 | All tables mapped with relationships, scopes, helpers |
| **Services** | ✅ 7/7 | VoucherService, ReportService, RemoteEntryService, RecurringTemplateService, ReconciliationService, ExpenseClaimService, DepreciationService |
| **Routes** | ✅ 221 lines | Full route file with all CRUD + workflow + AJAX routes |
| **Views** | ✅ ~60+ | CRUD views (index, show, create, edit, trash) + report views + partials |
| **Tests** | ✅ 13+ test files | Feature tests for all 7 services + unit tests for models/policies/auth |
| **Module registration** | ✅ module.json | Registered with ServiceProvider |

### 3.2 What's MISSING

| Area | Status | Impact |
|------|--------|--------|
| **Migrations** | ❌ EMPTY | `database/migrations/` has only `.gitkeep`. The `ACC_Migration.php` in `Design/` is a stub — NOT actually in Laravel's migration system. **Tables don't exist in DB.** |
| **Seeders** | ❌ Not created | No seeders for: 32 Account Groups, 11 Default Ledgers, 10 Voucher Types, 5 Tax Rates, 10 Cost Centers, 40 Tally Mappings, 7 Module Events |
| **ACC_Remote_Entry tables** | ❌ Not in migration | 4 event mapping tables (acc_module_events, acc_event_voucher_configs, acc_event_voucher_line_templates, acc_event_processing_log) are NOT included in ACC_Migration.php — only defined in the separate SQL file |
| **current_balance column** | ❌ Missing from DDL | Code uses `current_balance` and `current_balance_type` on `acc_ledgers` but DDL/migration doesn't define them. This will crash on migration. |
| **sch_employees enhancement** | ⚠️ Partial | Migration stub has Schema::hasColumn() guards but ALTER TABLE may fail if table doesn't exist yet |
| **VoucherServiceInterface** | ❌ Not created | The contract for Payroll & Inventory modules is mentioned in requirements but not implemented as a shared interface |
| **FeeIntegrationService** | ❌ Not created | Requirements mention this but it's not in services |
| **TransportIntegrationService** | ❌ Not created | Requirements mention this but it's not in services |

### 3.3 Key Code Implementation Details

**VoucherService::post()** — Updates `current_balance` on `acc_ledgers`:
```php
// When posting:
//   Dr items: current_balance += amount  (debit increases Dr balance)
//   Cr items: current_balance -= amount  (credit decreases Dr balance)
// When cancelling (direction = -1):
//   All items are reversed
```

**VoucherService::generateVoucherNumber()** — Lock-guarded sequence:
```php
// Uses VoucherType::lockForUpdate() to prevent race conditions
// Skips any numbers already taken (handles last_number drift)
// Updates VoucherType.last_number atomically
```

**ReportService** — Report queries are comprehensive:
- trialBalance: 44 lines SQL with group by ledger
- profitAndLoss: filters by group.nature in (income, expense)
- balanceSheet: filters by group.nature in (asset, liability)
- All reports filter by `v.status = 'posted'` (only posted vouchers affect reports)

---

## 4. DDL vs Code Gaps

### Gap 1: `current_balance` / `current_balance_type` on acc_ledgers

| Source | Has these columns? |
|--------|-------------------|
| `ACC_DDL_v2.sql` | ❌ NO — only defines `opening_balance` and `opening_balance_type` |
| `ACC_Migration.php` | ❌ NO — does not define them |
| `Ledger.php` model | ✅ YES — in `$fillable` and `$casts` |
| `VoucherService.php` | ✅ YES — writes to `current_balance` |
| `RemoteEntryService.php` | ✅ YES — uses `increment('current_balance')` |
| Tests | ✅ YES — all test ledgers created with `current_balance => 0` |

**Fix Required:** Add both columns to `ACC_DDL_v2.sql` and `ACC_Migration.php`.

### Gap 2: ACC_Remote_Entry tables not in Migration

| Table | In ACC_DDL_v2.sql? | In ACC_Remote_Entry_ddl.sql? | In ACC_Migration.php? |
|-------|-------------------|---------------------------|---------------------|
| `acc_module_events` | ❌ | ✅ | ❌ |
| `acc_event_voucher_configs` | ❌ | ✅ | ❌ |
| `acc_event_voucher_line_templates` | ❌ | ✅ | ❌ |
| `acc_event_processing_log` | ❌ | ✅ | ❌ |

**Fix Required:** Add all 4 tables to `ACC_Migration.php` and update `ACC_DDL_v2.sql`.

### Gap 3: DDL prefix mismatch

In `ACC_DDL_v2.sql`, `acc_voucher_types.prefix` is `VARCHAR(5)`.
In `VoucherService`, prefix logic allows up to 5 chars from the code. This is consistent.

### Gap 4: `acc_ledgers` missing vendor_id FK in Migration

The `ACC_Migration.php` does NOT define FKs for `vendor_id`, `employee_id`, `student_id` on `acc_ledgers` (only `account_group_id` FK). The DDL defines them. This is acceptable (soft FK through application logic) but should be documented.

---

## 5. Complete Data Flow Diagrams

### 5.1 Voucher Creation Flow

```
User fills voucher form
        │
        ▼
VoucherController::store()
        │
        ├── StoreVoucherRequest validation
        │     ├── voucer_type_id exists?
        │     ├── financial_year_id exists & unlocked?
        │     ├── date within FY range?
        │     ├── Items not empty?
        │     ├── SUM(debit) == SUM(credit)?
        │     └── All ledger_id exist?
        │
        ▼
VoucherService::create($data, $items)
        │
        ├── BEGIN TRANSACTION
        │
        ├── generateVoucherNumber(voucherTypeId, fyId)
        │     ├── VoucherType::lockForUpdate()
        │     ├── Find next number (skip taken)
        │     └── Update VoucherType.last_number
        │
        ├── Voucher::create($data)
        │     ├── voucher_number, voucher_prefix
        │     ├── financial_year_id, voucher_type_id
        │     ├── date, narration, total_amount
        │     ├── source_module, source_type, source_id
        │     └── status = 'draft', created_by = auth user
        │
        ├── foreach item:
        │     └── VoucherItem::create()
        │           ├── voucher_id, ledger_id
        │           ├── type (debit/credit), amount
        │           └── cost_center_id, bill_reference
        │
        ├── COMMIT TRANSACTION
        │
        ▼
  Return Voucher with formatted number
        │
        ▼
Redirect to voucher.show with success flash
```

### 5.2 Voucher Posting Flow

```
User clicks "Post" on a draft voucher
        │
        ▼
VoucherController::post($voucher)
        │
        ├── Gate::authorize('accounting.voucher.update')
        │
        ▼
VoucherService::post($voucher)
        │
        ├── Throw if status !== 'draft'
        │
        ├── BEGIN TRANSACTION
        │
        ├── Load items relationship
        │
        ├── foreach item:
        │     ├── Dr item: current_balance += amount
        │     └── Cr item: current_balance -= amount
        │
        ├── Update voucher: status = 'posted'
        │
        ├── COMMIT TRANSACTION
        │
        ▼
Redirect back with success
```

### 5.3 Expense Claim → Payment Voucher Flow

```
Employee submits expense claim
        │
        ▼
ExpenseClaimController::submit()
        │
        ▼
ExpenseClaimService::submit()
        │
        ├── status = Draft → Submitted
        │
        ▼
Approver clicks "Approve"
        │
        ▼
ExpenseClaimController::approve()
        │
        ▼
ExpenseClaimService::approve()
        │
        ├── BEGIN TRANSACTION
        │
        ├── Create Payment Voucher via VoucherService:
        │     ├── Dr: Claim lines' expense ledgers (total amount)
        │     └── Cr: Employee payable ledger or Bank/Cash
        │
        ├── Update ExpenseClaim: status = Approved, approved_by, approved_at
        ├── Link voucher_id
        │
        ├── COMMIT TRANSACTION
        │
        ▼
Cashier clicks "Mark Paid"
        │
        ▼
ExpenseClaimController::markPaid()
        │
        ▼
ExpenseClaimService::markPaid()
        │
        ├── Post the payment voucher
        ├── Update ExpenseClaim: status = Paid
        │
        ▼
Done — employee receives payment
```

### 5.4 Cross-Module Event Processing Flow

```
[Library module] fines a student for late return
        │
        ├── Creates lib_fines record
        ├── Calls RemoteEntryService::processEvent(
        │       moduleCode: 'LIBRARY',
        │       eventCode:  'LIB_LATE_RETURN_FINE',
        │       sourceId:   lib_fines.id,
        │       payload:    ['student_id' => $studentId, 'amount' => $fine->amount, ...]
        │   )
        │
        ▼
RemoteEntryService::processEvent()
        │
        ├── Step 1: Find ModuleEvent
        │     WHERE module_code = 'LIBRARY' AND event_code = 'LIB_LATE_RETURN_FINE'
        │
        ├── Step 2: Not found? → throw InvalidArgumentException
        │
        ├── Step 3: Find EventVoucherConfig
        │     WHERE module_event_id = $event->id AND is_active = true
        │
        ├── Step 4: No config? → Log 'Skipped' to EventProcessingLog
        │
        ├── Step 5: BEGIN TRANSACTION
        │
        ├── Step 6: For each EventVoucherLineTemplate (ordered by sequence):
        │     ├── Resolve ledger:
        │     │     fixed          → use template.ledger_id
        │     │     student_ledger → SELECT id FROM acc_ledgers WHERE student_id = payload.student_id
        │     │     vendor_ledger  → SELECT id FROM acc_ledgers WHERE vendor_id = payload.vendor_id
        │     │     employee_ledger→ SELECT id FROM acc_ledgers WHERE employee_id = payload.employee_id
        │     │
        │     └── Resolve amount:
        │           from_source  → read payload.source_amount_field
        │           fixed_amount → use template.fixed_amount
        │           from_payload → use payload.amount
        │
        ├── Step 7: Create Voucher via VoucherService
        │     ├── voucher_type_id from config
        │     ├── cost_center_id from config
        │     ├── narration from template (with placeholders replaced)
        │     ├── items from Step 6
        │     └── auto_post = config.is_auto_post
        │
        ├── Step 8: Log to EventProcessingLog:
        │     status = 'Processed', voucher_id = $voucher->id
        │
        ├── COMMIT TRANSACTION
        │
        ▼
Return EventProcessingLog record
```

### 5.5 Recurring Template Auto-Post Flow

```
Scheduled Job runs (daily)
        │
        ▼
RecurringTemplateService::postScheduled()
        │
        ├── Query all active templates WHERE:
        │     start_date <= today AND (end_date IS NULL OR end_date >= today)
        │     AND (last_posted_date IS NULL OR next_due_date <= today)
        │
        ├── foreach template:
        │     ├── Should I post today? (check frequency + day_of_month)
        │     │
        │     ├── If YES:
        │     │     ├── Create Journal Voucher via VoucherService
        │     │     │     ├── Dr/Cr lines from template lines
        │     │     │     └── Auto-post if configured
        │     │     │
        │     │     └── Update template.last_posted_date
        │     │
        │     └── If NO → skip
        │
        ▼
Done
```

---

## 6. Services Layer Deep-Dive

### 6.1 VoucherService (172 lines)

| Method | Transaction | Key Logic |
|--------|-------------|-----------|
| `create()` | ✅ | Generates number, creates voucher + items, verifies Dr=Cr |
| `update()` | ✅ | Deletes old items + re-creates, updates total_amount |
| `post()` | ✅ | Status check (draft only), applies items to ledger balances |
| `cancel()` | ✅ | Reverses ledger balances if posted, marks cancelled |
| `duplicate()` | ✅ | Replicates voucher with new number, draft status |
| `generateVoucherNumber()` | ✅ (lockForUpdate) | Atomic sequence per type+FY |

### 6.2 ReportService (559 lines)

| Report | Lines | Key Columns | Filters |
|--------|-------|-------------|---------|
| trialBalance | 44 | account_group, ledger_name, debit, credit | date range, posted status |
| profitAndLoss | 48 | nature, account_group, particulars, amount | date range, income/expense only |
| balanceSheet | ~60 | nature, account_group, ledger, balance | as-on date, asset/liability only |
| dayBook | ~30 | voucher fields + type | date, voucher type |
| cashBook | ~35 | ledger, date, particulars, debit, credit, balance | date range, cash ledgers |
| bankBook | ~35 | Same as cashBook | date range, bank ledgers |
| ledgerReport | ~50 | date, particulars, debit, credit, balance | ledger, date range |
| outstandingReceivables | ~40 | student, ledger, balance |—|
| outstandingPayables | ~40 | vendor, ledger, balance |—|
| budgetVariance | ~60 | cost_center, ledger, budgeted, actual, variance | financial year |
| gstSummary | ~50 | tax_type, rate, taxable_value, tax_amount | month/quarter |

**All reports compute running balance in PHP (not SQL):**
```php
$runningBalance = $openingBalance;
foreach ($entries as $entry) {
    $runningBalance += $entry->debit - $entry->credit;
    $entry->balance = $runningBalance;
}
```

### 6.3 RemoteEntryService (309 lines)

| Method | Lines | Purpose |
|--------|-------|---------|
| `processEvent()` | 80 | Public entry point — orchestrates full flow |
| `processEventAsync()` | ~30 | Queues event for async processing |
| `createVoucherFromConfig()` | ~80 | Core logic: resolved ledgers/amounts → creates voucher |
| `resolveLedger()` | ~40 | Dynamic ledger resolution (student/vendor/employee) |
| `resolveAmount()` | ~30 | Amount resolution (from_source/fixed/ftom_payload) |
| `replacePlaceholders()` | ~20 | Narration template variable substitution |

### 6.4 DepreciationService (~150 lines)

| Method | Purpose |
|--------|---------|
| `runDepreciation()` | Entry point — processes all assets for a period |
| `calculateSLM()` | Straight Line Method: (cost - salvage) / useful_life / 12 |
| `calculateWDV()` | Written Down Value: current_value × rate% / 12 |
| `createDepreciationVoucher()` | Creates Journal Voucher via VoucherService |

---

## 7. Cross-Module Integration

### 7.1 Inbound Events (Other → Accounting)

| Module | Event | Accounting Action |
|--------|-------|-------------------|
| StudentFee | Fee payment received | Receipt Voucher |
| StudentFee | Fee invoice generated | Sales Voucher |
| Transport | Fee charged | Sales/Receipt Voucher |
| Transport | Pickup change | Journal Voucher (adjustment) |
| Payroll | Payroll approved | Payroll Journal Voucher |
| Inventory | GRN accepted | Purchase Voucher |
| Inventory | Stock issued | Stock Journal |

### 7.2 Ledger Mapping Pattern

```
acc_ledger_mappings:
  ledger_id     → The accounting ledger (e.g., "Tuition Fee Income")
  source_module → 'Fees'
  source_type   → 'FeeHead'
  source_id     → FeeHead ID

When StudentFee module collects fees:
  1. Reads acc_ledger_mappings WHERE source_module='Fees' AND source_type='FeeHead' AND source_id=?
  2. Gets the income ledger for each fee head
  3. Calls RemoteEntryService or creates Receipt Voucher directly
```

### 7.3 Tally Integration Flow

```
User clicks "Export Vouchers"
        │
        ▼
TallyExportController::exportVouchers()
        │
        ├── Fetch posted vouchers in date range
        ├── For each voucher item, look up TallyLedgerMapping
        ├── Generate XML in Tally-compatible format:
        │
        │   <VOUCHER>
        │     <VOUCHERTYPENAME>Receipt</VOUCHERTYPENAME>
        │     <DATE>20260401</DATE>
        │     <PARTYLEDGERNAME>Student Fee A/c</PARTYLEDGERNAME>
        │     <ALLLEDGERENTRIES.LIST>
        │       <LEDGERNAME>Bank A/c</LEDGERNAME>
        │       <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
        │       <AMOUNT>5000.00</AMOUNT>
        │     </ALLLEDGERENTRIES.LIST>
        │   </VOUCHER>
        │
        ├── Save XML file
        ├── Create TallyExportLog record
        │
        ▼
Downloadable XML file for CA/Tally import
```

---

## 8. Key Business Rules

| # | Rule | Enforced In |
|---|------|-------------|
| 1 | SUM(debit) = SUM(credit) for every voucher | FormRequest + VoucherService |
| 2 | Locked FY blocks all voucher operations | FinancialYearController + VoucherService |
| 3 | Voucher number IMMUTABLE once assigned | VoucherService::generateVoucherNumber |
| 4 | Ledger balance COMPUTED, never stored (DESIGN) vs stored in current_balance (CODE) | Gap — see section 4 |
| 5 | System entities (is_system=1) cannot be deleted | Controller destroy() methods |
| 6 | Cancelled voucher needs reason, soft-delete, balances reversed | VoucherService::cancel() |
| 7 | Only draft vouchers can be edited | Voucher->isEditable() |
| 8 | Recurring template must balance Dr=Cr | RecurringTemplateService |
| 9 | Bank reconciliation only for ledgers with allow_reconciliation=true | BankReconciliationController |
| 10 | All 28 Tally groups seeded as account groups (is_system=1) | Seeder (NOT YET CREATED) |
| 11 | `is_subledger` groups cannot have child groups | AccountGroupController |
| 12 | One Tally mapping per ledger (UNIQUE constraint) | Database + TallyLedgerMappingController |
| 13 | Expense claim: Approved → creates Payment Voucher | ExpenseClaimService::approve() |
| 14 | Depreciation entries create Journal Vouchers | DepreciationService |

---

## Critical Action Items

### Must Fix Before Production

1. **Add `current_balance` + `current_balance_type` to DDL + Migration** — otherwise posting vouchers crashes
2. **Copy ACC_Migration.php into `database/migrations/`** — with proper timestamp filename
3. **Add 4 event mapping tables to Migration** — currently only in separate SQL file
4. **Create all seeders** — 32 account groups, 11 ledgers, 10 voucher types, 5 tax rates, 10 cost centers, 40 tally mappings, 7 module events

### Nice to Have

5. Extract `VoucherServiceInterface` as shared contract for Payroll/Inventory
6. Create `FeeIntegrationService` + `TransportIntegrationService`
7. Consider switching `current_balance` to computed-at-query-time (design intent) vs stored (current code)
8. Add EnsureTenantHasModule middleware to all route groups
