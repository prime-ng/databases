# Meal Card Ledger — Business Requirements

## What This Screen Does

The Meal Card Ledger is the complete financial transaction history for every meal card. Every rupee loaded, spent, refunded, or adjusted is recorded as an immutable ledger entry. This provides full financial transparency and audit trail for all meal card operations.

---

## When This Screen Is Used

- A parent wants to see their child's complete meal card transaction history
- Admin needs to investigate a balance discrepancy
- Finance team needs to audit meal card transactions for a period
- A refund or adjustment needs to be documented
- Monthly statements need to be generated for parents

---

## Key Fields at a Glance

**Meal Card**
The card this transaction belongs to. References the card number and student name.

**Transaction Type**
- **Credit:** Adding funds (top-up via Online/Cash/Wallet/Free)
- **Debit:** Spending funds (purchase via POS or pre-order)
- **Refund:** Reversing a previous debit (cancelled order)
- **Adjustment:** Admin correction (requires notes explaining reason)

**Amount**
Transaction amount in INR. Credits are positive, debits are negative for balance calculation.

**Balance After**
The card balance AFTER this transaction was applied. This creates a sequential chain — each entry's balance must equal the previous balance ± amount.

**Reference Type / Reference ID**
What caused this transaction — Order, POS, TopUp, Refund, or Adjustment. Reference ID links back to the source record.

**Payment Mode**
For Credits: Online (Razorpay), Cash, Wallet, or Free.

**Razorpay Payment ID**
For online top-ups — the Razorpay payment ID. Used for idempotency (prevents double-crediting).

**Notes**
Transaction description or notes. Required for Adjustments.

**Created At**
Timestamp of the transaction.

---

## Business Rules and Conditions

**Immutability**
Ledger entries cannot be modified or deleted. Once created, they remain permanently. This ensures a tamper-proof audit trail.

**Sequential Consistency**
Transactions ordered by created_at must have balance_after = previous.balance_after ± amount. A mismatch indicates a ledger integrity issue.

**Razorpay Idempotency (BR-CAF-011)**
Each Razorpay payment ID is UNIQUE. Duplicate webhook calls return the existing record instead of double-crediting.

**No Deleted At**
Financial ledger — no soft delete, no is_active. Permanently immutable.

**Adjustment Requirements**
Adjustment transactions require mandatory notes explaining the reason. Example: "Balance correction — ₹50 added to fix rounding error from transaction #1234."

---

## Workflow Steps

**Viewing Card Statement**
Search for a meal card → open the card's show page → see the complete transaction ledger sorted by date.

**Filtering Transactions**
Filter by date range, transaction type (Credit/Debit/Refund/Adjustment), or reference type (Order/POS/TopUp).

**Exporting Statements**
Export transaction history for a date range as PDF for parent communication or financial reporting.

---

## Example Scenario

**Meal Card CAF-CARD-0000152 (Student: Ravi) — Transaction History:**

| Date | Type | Amount | Balance After | Reference | Notes |
|------|------|--------|---------------|-----------|-------|
| Jun 1 | Credit | +₹500 | ₹500 | TopUp (Online) | Razorpay: pay_ABC123 |
| Jun 1 | Debit | -₹90 | ₹410 | Order #42 | Lunch — Veg Biryani x2 + Raita |
| Jun 2 | Debit | -₹25 | ₹385 | Order #48 | Breakfast — Poha |
| Jun 2 | Debit | -₹90 | ₹295 | Order #49 | Lunch — Veg Thali |
| Jun 3 | Refund | +₹90 | ₹385 | Order #49 | Cancelled — student was absent |
| Jun 5 | Adjustment | +₹10 | ₹395 | — | Correction — overcharged on Jun 1 |

Ledger integrity check: ₹395 (balance) = ₹500 (total credited: 500+90+10) - ₹195 (total debited: 90+25+90). ✓

---

## Related Screens

- **Meal Cards** — Card master with current balance and lifetime totals
- **Orders** — Order references appear in ledger for MealCard transactions
- **POS Sessions** — POS transaction references appear in ledger
- **Daily Sales** — Aggregated sales data from ledger entries
