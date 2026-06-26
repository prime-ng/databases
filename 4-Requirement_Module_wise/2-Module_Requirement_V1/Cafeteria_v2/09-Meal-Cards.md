# Meal Cards — Business Requirements

## What This Screen Does

The Meal Cards screen manages the student prepaid meal wallet system. Each student can have one meal card that acts like a digital wallet for cafeteria purchases. Parents or students can add funds (top-up), and the balance is deducted when meals are purchased via POS or pre-orders.

Think of this as a digital lunch box. Instead of carrying cash to school, students have a prepaid card that parents can reload online.

---

## When This Screen Is Used

- A new student joins and needs a meal card to be issued
- A parent wants to add funds to their child's meal card (top-up)
- A student's card is lost/damaged and needs replacement
- A card needs to be suspended or deactivated
- Admin needs to check a student's current balance

---

## Key Fields at a Glance

**Card Number**
Auto-generated unique identifier: CAF-CARD-XXXXXXXX.

**Student**
The card owner. One active card per student.

**Current Balance**
Updated atomically with DB-level locks (SELECT...FOR UPDATE).

**Total Credited**
Lifetime sum of all top-ups, refunds, and adjustments.

**Total Debited**
Lifetime sum of all purchases and adjustments.

**Validity Period**
Valid From (start date) to Valid To (typically end of academic year).

**Status**
Active (usable) or Inactive (suspended, balance preserved).

---

## Business Rules and Conditions

**One Active Card Per Student (BR-CAF-004)**
UNIQUE on student_id. Lost/damaged: soft-delete old card → issue new → transfer balance via Adjustment.

**Atomic Balance Updates**
LOCK record → calculate new balance → guard for insufficient funds (debits) → UPDATE → INSERT ledger entry → COMMIT. Prevents race conditions.

**Ledger Integrity**
current_balance MUST equal total_credited - total_debited. Mismatch triggers critical error log.

**Card Expiry**
Expired cards cannot be used. Balance not forfeited — admin handles refund or re-issuance.

---

## Workflow Steps

**Issuing a Card**
Search student → card number auto-generated → set validity dates (today to end of academic year) → card issued with ₹0 balance.

**Topping Up**
Online: Parent adds funds via Razorpay → credited immediately.
Cash: Parent gives cash to admin → admin records Cash top-up → balance updated.

**Viewing Card Statement**
Show page displays complete transaction ledger with dates, amounts, balance after each, and reference descriptions.

**Replacing a Lost Card**
Soft-delete old card → issue new card → Adjustment transaction transfers balance.

**Suspending a Card**
Deactivate card. Stops working at POS. Balance preserved for refund or reactivation.

---

## Example Scenario

Student Ravi's card: CAF-CARD-0000152.
- Initial: ₹0 balance, valid Jun 1, 2026 to Mar 31, 2027.
- Top-up: ₹500 via Razorpay. Balance: ₹500.
- Day 1: Lunch (₹90). Balance: ₹410.
- Day 2: Breakfast (₹25) + Lunch (₹90). Balance: ₹295.
- Day 3: Cancel lunch → ₹90 refunded. Balance: ₹385.

---

## Related Screens

- **Meal Card Ledger** — Full transaction history for each card
- **POS Sessions** — Card balance deducted during POS transactions
- **Orders** — MealCard payment mode deducts from card balance
- **Subscription Plans** — Plan fees can be charged to meal card
