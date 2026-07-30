# Voucher — Business Requirements

## What This Screen Does

The Voucher screen is the core transaction entry interface. It handles the complete lifecycle of financial vouchers — create as draft, post to ledger, approve, cancel/void, print, and duplicate. Vouchers record debit and credit entries (voucher items) that update ledger balances, and can be filtered by voucher type, financial year, date range, and status.

## When This Screen Is Used

- **Daily accounting** when entering all financial transactions (payments, receipts, contra, journal, sales, purchases, credit/debit notes).
- **At month-end** when reviewing and approving pending vouchers.
- **When correcting errors** by reversing or canceling posted vouchers.
- **For audit purposes** when viewing voucher history and approval trail.
- **For printing** physical voucher copies.

## Key Fields

- **Voucher Number** (string 50) — Auto/manual number, unique per type+F Y
- **Voucher Type** (FK → acc_voucher_types) — Payment/Receipt/Contra/Journal/etc.
- **Voucher Date** (date) — Transaction date
- **Financial Year** (FK → acc_financial_years, nullable) — Accounting period
- **Ledger** (FK → acc_ledgers, for single-entry forms)
- **Narration** (text, nullable)
- **Status** (enum: draft/posted/approved/cancelled/void) — Lifecycle state
- **Approved By** (FK → sys_users, nullable)
- **Approved At** (timestamp, nullable)
- **Cancelled By** (FK → sys_users, nullable)
- **Total Amount** (decimal 15,2) — Sum of items
- **Is Active** (boolean)

**Voucher Items (Child):**
- **Ledger ID** (FK → acc_ledgers) — Account to debit/credit
- **Debit Amount** (decimal 15,2)
- **Credit Amount** (decimal 15,2)
- **Narration** (text, nullable)

## Business Rules

**Lifecycle States:**
Draft → Post → Approve (with approval workflow). Posted vouchers cannot be edited. Cancelled/void vouchers cannot be re-posted.

**Ledger Balance Effects:**
Posting a voucher increases/decreases ledger balances: Debit increases asset/expense ledgers, Credit increases liability/income ledgers.

**Number Generation:**
Voucher numbers are generated as `{prefix}{number}` per voucher type per financial year. Concurrency handled via DB-level lock or unique constraint.

**Validation:**
- Debits must equal credits (balance check)
- Voucher date must fall within the selected financial year
- Voucher date must not be in a locked financial year
- At least one voucher item required
- Each item must have a valid ledger and non-zero amount

**Duplicate:**
A posted voucher can be duplicated — creates a new draft with same items but new voucher number.

**Print:**
Renders a print-friendly view of the voucher with all details, company header, and signatures.

**Restore from Cancel:**
Cancelled vouchers can potentially be restored (reinstate to posted/draft status, depending on workflow).

**Approval Workflow:**
Configurable — some tenants require approval for all vouchers, others only above a threshold. Approved vouchers are locked.

## Workflow

1. User navigates to Accounting → Transactions → Vouchers.
2. Tab filters: All, Draft, Posted, Approved, Cancelled (sub-tabs by voucher type category).
3. User creates a voucher: selects type, date, FY, adds items with ledger + debit/credit amounts.
4. On save as draft: voucher is created but not posted. On post: ledger balances update.
5. Posted vouchers can be sent for approval. Approver reviews and approves/rejects.
6. Vouchers can be cancelled with reason, printed, or duplicated.

## Requirements

- MUST display at `/accounting/voucher?tab=vouchers` with sub-tabs by voucher type category
- MUST authorize via `tenant.accounting.voucher.*` policy gates
- MUST enforce debit = credit balance check before posting
- MUST validate voucher date within financial year range
- MUST prevent posting to a locked financial year
- MUST auto-generate voucher number as `{prefix}{number}` per type per FY
- MUST handle concurrent number generation safely
- MUST track lifecycle: draft → posted → approved → cancelled/void
- MUST update ledger balances on post, reverse on cancel
- MUST support voucher duplication (copy with new number)
- MUST support print view with company header
- MUST track approval trail (approved_by, approved_at)
- MUST support is_active toggle via Ajax
- MUST support soft delete with trash view, restore, forceDelete
