# Voucher Engine — Business Requirements

## Business Need
Every financial transaction in a school — fee collection, vendor payment, salary disbursement, cash transfer, expense reimbursement — must be recorded with strict accuracy. Without a proper double-entry system, transactions can be entered incorrectly, the books won't balance, and financial reports become unreliable. Schools need a structured "voucher" system (the standard accounting term) with proper debit/credit entries, narration, reference numbers, and a complete audit trail.

## Business Objectives
- Record ALL financial transactions through a unified voucher system
- Enforce double-entry accounting: every transaction must balance (Total Debits = Total Credits)
- Support 10 voucher types covering all school transaction scenarios
- Auto-generate sequential voucher numbers per type per financial year
- Provide a clear lifecycle: Draft → Posted → Approved → Cancelled
- Enable voucher search, printing, and duplication
- Allow other modules (Payroll, Inventory) to create vouchers programmatically

## Voucher Types (Business Context)

| Type | When to Use | Example |
|------|-------------|---------|
| **Payment** | Paying someone | Vendor bill payment, staff expense reimbursement |
| **Receipt** | Receiving money | Fee collection, donation received |
| **Contra** | Transfer between own accounts | Cash deposited to bank, bank to cash withdrawal |
| **Journal** | Adjustments, accruals, corrections | Depreciation entry, provision for bad debts |
| **Sales** | Selling goods/services | Sale of old furniture, canteen sales |
| **Purchase** | Buying goods/services | Stationery purchase, lab equipment |
| **Credit Note** | Reducing a sale/income | Fee concession, sales return |
| **Debit Note** | Reducing a purchase/expense | Purchase return to vendor |
| **Stock Journal** | Inventory adjustments | Stock consumption, stock transfer |
| **Payroll** | Salary processing | Monthly salary disbursement |

## User Stories

**As School Accountant,** I want to:
- Create a payment voucher when paying a vendor (Dr: Expense/Creditor, Cr: Bank/Cash)
- Create a receipt voucher when collecting fees (Dr: Bank/Cash, Cr: Fee Income)
- Create a contra voucher when transferring cash to bank
- Create a journal voucher for adjusting entries
- Enter debit and credit line items for each voucher with narration
- Save vouchers as "Draft" and complete them later
- Post a draft voucher so it affects ledger balances
- Print a voucher in a standard Tally-like format
- Duplicate an existing voucher to create a similar one quickly
- Search vouchers by date, type, ledger, amount, or narration
- Attach reference numbers (cheque number, receipt number) to vouchers
- Handle post-dated cheques separately

**As School Admin / Bursar,** I want to:
- Approve posted vouchers to finalize them
- Cancel a voucher with a reason (which reverses its ledger impact)
- Review the audit trail: who created, posted, approved, or cancelled each voucher

**As Cashier,** I want to:
- Create only Payment and Receipt vouchers (restricted by permissions)
- View cash and bank book reports to track daily transactions

**As Payroll Module,** I want to:
- Create a Payroll Voucher automatically when salary is processed (Dr: Salary Expense, Cr: Salary Payable)

## Key Business Rules

**Double-Entry Balance**
- Every voucher MUST have equal debits and credits. The system rejects unbalanced entries.

**Voucher Numbering**
- Format: `[PREFIX][YYYY]-[NNNNNN]` (e.g., `RCV-2026-000001`)
- Sequential per voucher type per financial year
- NEVER reused or changed once assigned
- Lock-guarded to prevent duplicates under concurrent creation

**Financial Year Validation**
- Voucher date must fall within its assigned financial year's date range
- If the financial year is locked, no voucher operations are allowed

**Voucher Lifecycle**
- **Draft:** Being prepared, editable, does NOT affect ledger balances
- **Posted:** Finalized, affects ledger balances
- **Approved:** Verified by authorized person, read-only
- **Cancelled:** Voided with reason, ledger impact reversed, soft-deleted

**VoucherServiceInterface (Shared Contract)**
- Payroll and Inventory modules can create vouchers programmatically
- No direct database access — they use this shared interface
- Methods: create a voucher, post it, cancel it, retrieve it

## Seeded Data
10 voucher types seeded (Payment, Receipt, Contra, Journal, Sales, Purchase, Credit Note, Debit Note, Stock Journal, Payroll) with prefixes and numbering rules.

## Stakeholders

| Stakeholder | Interest |
|---|---|
| School Accountant | Primary user — creates, posts, manages all voucher types |
| Cashier | Creates payment/receipt vouchers |
| School Admin / Bursar | Approves and cancels vouchers |
| Auditor | Reviews voucher trail for compliance |
| Payroll Module | Creates payroll vouchers automatically |
| Inventory Module | Creates purchase and stock vouchers automatically |

## Permissions

| Role | Access |
|---|---|
| School Admin | Full access — all voucher operations including approval |
| Accountant | Create, update, post, cancel vouchers |
| Cashier | Create payment/receipt vouchers only |
| Auditor | Read-only access |
