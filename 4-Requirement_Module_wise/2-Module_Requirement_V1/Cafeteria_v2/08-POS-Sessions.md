# POS Sessions — Business Requirements

## What This Screen Does

The POS Sessions screen manages the cafeteria's point-of-sale shift operations. Staff open a session at shift start, process counter transactions, and close with reconciled totals. Also covers staff meal logging with payroll deduction signal.

---

## When This Screen Is Used

- Cafeteria staff starts their shift and opens a new POS session
- A student scans their QR code to collect a pre-ordered meal
- A student makes a counter purchase (e.g., buying snacks from Tuck Shop)
- A staff member gets a meal logged for payroll deduction
- The shift ends and the cashier closes the session with reconciled totals

---

## Key Fields at a Glance

**Session**

**Session Date**
Date of the shift. One open session per staff per day.

**Opened By / Opened At**
Staff member who opened and the exact time.

**Closed At**
NULL = active. Closed sessions cannot accept new transactions.

**Totals (Auto-Calculated on Close)**
Cash Collected, Card Debited, Transaction Count. Recalculated from actual transaction records.

**Notes**
Closing notes for discrepancies.

**POS Transaction**

**Student / Staff**
Who made the purchase. Student via QR scan, staff via search.

**Items Snapshot**
Immutable record: [{menu_item_id, name, qty, price}].

**Payment Mode**
MealCard (deduct from wallet) or Cash.

**Balance After**
Card balance after deduction (MealCard only).

**Dietary Flags Snapshot**
Student's dietary flags at scan time — preserves what cashier saw.

**Staff Meal Log**

**Staff Member**
Who had the meal.

**Meal Details**
Category, date, items snapshot, amount.

**Payment Mode**
Subscription, Cash, or CardDeduction.

**Payroll Deduction Flag**
1 = signal PAY module for salary deduction. CAF never writes to pay_* tables.

---

## Business Rules and Conditions

**One Active Session Per Staff Per Day (BR-CAF-013)**
Only one open session per staff per day. Previous session must be closed first.

**Transactions Require Active Session**
"No active POS session. Please open a session first."

**Session Close Reconciliation**
Totals recalculated from actual transaction records on close. Discrepancies logged in notes.

**No Soft Delete**
Sessions are permanent records. Cannot be deleted. Can be deactivated.

**Transaction Immutability**
Once processed, cannot be modified or deleted. Corrections via Adjustment on meal card.

**MealCard Payment Flow**
Scan QR → read balance + dietary flags → add items → confirm → deduct balance atomically → create transaction → auto-create attendance.

---

## Workflow Steps

**Open Session:** Staff clicks "Open Session" at shift start.

**Process Sale:** Student scans QR → system shows balance + dietary alerts → cashier adds items → selects payment → confirms → receipt optional.

**Log Staff Meal:** Select staff → choose meal category → add items → set payment mode → optionally set payroll flag → submit.

**Close Session:** System shows reconciliation → staff adds notes → confirms closure.

---

## Example Scenario

Cashier Sunita opens session at 7:00 AM.
- 7:30 AM: Student A scans QR for breakfast (MealCard ₹25). Attendance recorded.
- 7:35 AM: Student B pays cash for breakfast (₹25). Attendance recorded.
- 12:00 PM: Student A scans for lunch (MealCard ₹50).
- 12:30 PM: Teacher Mr. Sharma logs breakfast (Staff Meal, ₹25, Subscription).
- 2:00 PM: Sunita closes session. Totals: 4 transactions, Cash ₹25, Card ₹75, Staff 1.

---

## Related Screens

- **Orders** — Counter orders processed within active POS session
- **Meal Attendance** — Auto-created for MealCard transactions
- **Meal Cards** — Card balances deducted during POS transactions
- **Dietary Profiles** — Flags displayed as warnings during transactions
