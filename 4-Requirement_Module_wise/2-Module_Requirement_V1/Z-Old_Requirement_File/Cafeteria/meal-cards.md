# Meal Cards — Requirements

## Parent Tab: Meal Cards

## What It Does
Student prepaid meal wallet system — one active card per student. Supports top-ups, POS deductions, and adjustments with atomic balance updates and full transaction ledger.

## Tables Covered

1. `caf_meal_cards` — Card master with balance
2. `caf_meal_card_transactions` — Credit/Debit/Refund/Adjustment ledger

---

## Entity: Meal Cards (`caf_meal_cards`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `student_id` | INT UNSIGNED FK → std_students | Required. Unique. One active card per student. |
| `card_number` | VARCHAR(20) | Required. Unique. Auto-generated: `CAF-CARD-XXXXXXXX`. |
| `current_balance` | DECIMAL(10,2) | Default 0.00. Updated atomically via SELECT...FOR UPDATE. |
| `total_credited` | DECIMAL(10,2) | Default 0.00. Lifetime top-up total. |
| `total_debited` | DECIMAL(10,2) | Default 0.00. Lifetime spend total. |
| `valid_from_date` | DATE | Required. Card validity start. |
| `valid_to_date` | DATE | Nullable. Card expiry (typically end of academic year). |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. Who issued the card. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### Business Rules

**One Active Card Per Student (BR-CAF-004):**
- Each student can have at most one meal card at a time. The system enforces this so no duplicate cards are created for the same student.
- If a card is lost or damaged, the old card is retired (hidden from active use) and a new one is issued. Any remaining balance is transferred to the new card using an Adjustment transaction.
- Every card number is unique across the system — no two cards can share the same number.

**Atomic Balance Updates:**
When money is added or deducted from a meal card, the system follows these steps to ensure accuracy and prevent errors:
1. Locks the card record so no other process can change it at the same time.
2. Calculates the new balance — adding for credits, subtracting for debits.
3. For deductions: checks that the new balance is not negative. If the balance would go below zero, the transaction is rejected with: "Insufficient meal card balance. Available: ₹{balance}, Required: ₹{amount}."
4. Saves the new balance on the card.
5. Records the transaction in the ledger with the type, amount, and resulting balance.
6. All these steps happen together — if any step fails, the entire operation is rolled back and nothing is saved.

**Ledger Integrity:**
- The current balance must always equal the total amount credited minus the total amount debited.
- If a mismatch is detected, the system logs a critical error: "Meal card #{id} ledger integrity check failed. Balance: {cb}, Expected: {tc - td}."

**Expiry:**
- A card's validity period defaults to the end of the current academic year.
- Expired cards cannot be used for POS purchases. The system shows: "Meal card has expired on {valid_to_date}."
- Any remaining balance on an expired card is not forfeited automatically — an administrator handles it by issuing a refund or re-issuing the balance to a new card.

**List View:**
- Controller: MealCardController@index. Gate: `tenant.cafeteria.meal-card.viewAny`.
- Columns: Card Number, Student Name, Current Balance, Total Credited, Total Debited, Valid Till, Status, Actions.
- Actions: Show (statement), Top-Up, Suspend.

---

## Entity: Meal Card Transactions (`caf_meal_card_transactions`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `meal_card_id` | INT UNSIGNED FK → caf_meal_cards | Required. ON DELETE RESTRICT. |
| `student_id` | INT UNSIGNED FK → std_students | Required. Denormalized for efficient queries. |
| `transaction_type` | ENUM('Credit','Debit','Refund','Adjustment') | Required. |
| `amount` | DECIMAL(10,2) | Required. |
| `balance_after` | DECIMAL(10,2) | Required. Balance snapshot AFTER this transaction. |
| `reference_type` | VARCHAR(50) | Nullable. Source context: Order, POS, TopUp, Refund, Adjustment. |
| `reference_id` | INT UNSIGNED | Nullable. Polymorphic FK. |
| `payment_mode` | ENUM('Online','Cash','Wallet','Free') | Nullable. For Credit (top-up) transactions. |
| `razorpay_payment_id` | VARCHAR(100) | Nullable. Unique. Razorpay ID for idempotency. |
| `notes` | TEXT | Nullable. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

**Immutable Ledger:**
- Transaction records are permanent. Once saved, they cannot be edited, deleted, or hidden.
- If a mistake is made, it cannot be corrected by changing the transaction. Instead, an "Adjustment" transaction must be added with a note explaining the reason.
- The system ensures transaction history is consistent — each transaction's balance must correctly follow from the previous one.

**Razorpay Idempotency (BR-CAF-011):**
- Each online payment through Razorpay is identified by a unique payment ID. The system prevents the same payment from being processed twice.
- If a duplicate payment notification is received, the system returns the existing transaction record. If a different transaction tries to use the same payment ID, the system shows: "Duplicate Razorpay payment ID detected."

**Transaction Types:**
- **Credit:** Adding funds to the card. Supported payment methods are Online, Cash, Wallet, or Free.
- **Debit:** Deducting funds from the card. The transaction links back to the original source (e.g., a POS order).
- **Refund:** Reversing a previous debit. The notes should reference the original transaction.
- **Adjustment:** An administrator correcting the balance. A note must explain the reason for the correction.

## Permissions

| Operation | Permission Key |
|---|---|
| Issue/Edit/Manage | `tenant.cafeteria.meal-card.*` |
| View transactions | `tenant.cafeteria.meal-card-transaction.viewAny` |
