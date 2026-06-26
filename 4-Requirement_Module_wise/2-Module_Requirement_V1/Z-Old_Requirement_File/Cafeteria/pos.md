# POS Sessions — Requirements

## Parent Tab: Orders & Attendance

## What It Does
POS shift management — open/close model per staff per day. An active session is required to process counter transactions. Tracks cash collected, card amounts debited, and transaction counts for end-of-day reconciliation.

## Tables Covered

1. `caf_pos_sessions` — POS shift sessions
2. `caf_pos_transactions` — Individual POS counter sales
3. `caf_staff_meal_logs` — Staff meal tracking with payroll deduction signal

---

## Entity: POS Sessions (`caf_pos_sessions`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `session_date` | DATE | Required. |
| `opened_by` | INT UNSIGNED FK → sys_users | Required. Staff who opened. |
| `opened_at` | TIMESTAMP | Required. Session open timestamp. |
| `closed_at` | TIMESTAMP | Nullable. NULL = still active. |
| `total_cash_collected` | DECIMAL(10,2) | Default 0.00. For end-of-day reconciliation. |
| `total_card_debited` | DECIMAL(10,2) | Default 0.00. |
| `total_transactions` | INT UNSIGNED | Default 0. |
| `notes` | TEXT | Nullable. Closing/discrepancy notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

**Session Lifecycle (BR-CAF-013):**
- A staff member can have only one active (non-closed) session per day.
- When a session is opened, it has no closing time yet.
- POS transactions can only be processed when a session is active. If no active session exists, the system shows: "No active POS session. Please open a session first."
- A session can only be closed if it is currently open. The system will not allow closing a session that is already closed.
- When a session is closed:
  1. The current time is recorded as the closing time.
  2. The system recalculates totals from the actual POS transactions linked to this session and overwrites any previously stored values.
  3. If there is a discrepancy between the stored totals and the computed totals, the difference is noted in the session notes.
- Once closed, a session cannot accept any new POS transactions.

**Deactivating a Session:** POS sessions cannot be deleted. Instead, they can be deactivated, which hides them from active use while keeping the record for auditing purposes.

---

## Entity: POS Transactions (`caf_pos_transactions`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `pos_session_id` | INT UNSIGNED FK → caf_pos_sessions | Required. ON DELETE RESTRICT. |
| `student_id` | INT UNSIGNED FK → std_students | Nullable. NULL for anonymous/cash sales. |
| `staff_id` | INT UNSIGNED FK → sys_users | Nullable. NULL for student transactions. |
| `meal_card_id` | INT UNSIGNED FK → caf_meal_cards | Nullable. NULL for cash. ON DELETE SET NULL. |
| `items_json` | JSON | Required. Immutable snapshot. |
| `total_amount` | DECIMAL(10,2) | Required. |
| `payment_mode` | ENUM('MealCard','Cash') | Required. |
| `balance_after` | DECIMAL(10,2) | Nullable. MealCard mode only. |
| `dietary_flags_json` | JSON | Nullable. Snapshot at scan time. |
| `receipt_sent` | TINYINT(1) | Default 0. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

**Immutability:** POS transactions are permanent records. Once saved, they cannot be edited or deleted.
- If a mistake is made (for example, the wrong amount was deducted from a meal card), it is corrected by adding an Adjustment transaction on the meal card rather than changing the original record.

**Payment Mode Rules:**
- **MealCard:** The student must be identified and linked to their card. The resulting balance is recorded, and the deduction happens atomically when the transaction is saved.
- **Cash:** Anonymous sales are allowed — the student does not need to be identified. No card balance tracking applies.
- Each transaction uses only one payment method — never both.

**JSON Structures:**

`items_json` (immutable snapshot):
```json
[
  {"menu_item_id": 1, "name": "Idli", "qty": 2, "price": 15.00},
  {"menu_item_id": 5, "name": "Sambhar", "qty": 1, "price": 10.00}
]
```

`dietary_flags_json` (snapshot at scan time):
```json
{
  "food_preference": "Veg",
  "is_nut_allergy": true,
  "is_no_onion_garlic": false
}
```

Invalid JSON: "The items/dietary flags format is invalid."

**Receipt:** After a successful transaction, a digital receipt can be sent. The system marks the receipt as sent after dispatch.

---

## Entity: Staff Meal Logs (`caf_staff_meal_logs`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `staff_id` | INT UNSIGNED FK → sys_users | Required. |
| `meal_date` | DATE | Required. |
| `meal_category_id` | INT UNSIGNED FK → caf_menu_categories | Required. ON DELETE RESTRICT. |
| `items_json` | JSON | Nullable. Immutable snapshot. |
| `amount` | DECIMAL(8,2) | Default 0.00. |
| `payment_mode` | ENUM('Subscription','Cash','CardDeduction') | Required. |
| `payroll_deduction_flag` | TINYINT(1) | Default 0. 1 = PAY module should deduct. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

- Staff meal logs are permanent records — they cannot be edited or deleted after creation.
- When flagged for payroll deduction, it signals the payroll (PAY) module that this amount should be deducted from the staff member's salary. The cafeteria module never writes directly to payroll tables.
- The items data uses the same format as POS transaction items and is also an unchangeable snapshot.

## Permissions

| Operation | Permission Key |
|---|---|
| POS — Open/Close session | `tenant.cafeteria.pos-session.*` |
| POS — Process transactions | `tenant.cafeteria.pos-transaction.process` |
| Staff Meal Logs — CRUD | `tenant.cafeteria.staff-meal-log.*` |
