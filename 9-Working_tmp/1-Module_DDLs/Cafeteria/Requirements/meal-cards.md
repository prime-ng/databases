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
- UNIQUE KEY on `student_id`: at most one meal card per student.
- Lost/damaged: soft-delete old card → issue new one → transfer balance via Adjustment transaction.
- `card_number` globally unique (UNIQUE KEY).

**Atomic Balance Updates:**
Every balance-changing operation follows this flow within a DB transaction:
1. `BEGIN TRANSACTION`
2. `SELECT * FROM caf_meal_cards WHERE id = X FOR UPDATE`
3. Calculate new balance: `current_balance ± amount`
4. Guard (debit only): new balance must not go below 0. Error: "Insufficient meal card balance. Available: ₹{balance}, Required: ₹{amount}."
5. `UPDATE caf_meal_cards SET current_balance = new_balance`
6. `INSERT INTO caf_meal_card_transactions` (type, amount, balance_after)
7. `COMMIT`

**Ledger Integrity:**
- `current_balance` MUST equal `total_credited - total_debited`.
- If mismatch: critical error log "Meal card #{id} ledger integrity check failed. Balance: {cb}, Expected: {tc - td}."

**Expiry:**
- `valid_to_date` defaults to end of current academic year.
- Expired cards: "Meal card has expired on {valid_to_date}." Cannot be used for POS.
- Remaining balance NOT forfeited automatically — admin handles via refund or re-issuance.

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
- No `is_active`, no `deleted_at`. Once created, cannot be modified or deleted.
- Corrections via 'Adjustment' transaction only. `notes` required explaining reason.
- Sequential consistency: transactions ordered by `created_at` must have `balance_after = previous.balance_after ± amount`.

**Razorpay Idempotency (BR-CAF-011):**
- `razorpay_payment_id` has UNIQUE KEY. Multiple NULLs allowed (MySQL behavior).
- Duplicate webhook: return existing record. Error if DIFFERENT transaction has same ID: "Duplicate Razorpay payment ID detected."

**Transaction Types:**
- **Credit:** Adding funds. `payment_mode` required (Online/Cash/Wallet/Free).
- **Debit:** Deducting funds. `reference_type`/`reference_id` link to source.
- **Refund:** Reversing a debit. Reference original transaction in `notes`.
- **Adjustment:** Admin correction. `notes` required.

## Permissions

| Operation | Permission Key |
|---|---|
| Issue/Edit/Manage | `tenant.cafeteria.meal-card.*` |
| View transactions | `tenant.cafeteria.meal-card-transaction.viewAny` |
