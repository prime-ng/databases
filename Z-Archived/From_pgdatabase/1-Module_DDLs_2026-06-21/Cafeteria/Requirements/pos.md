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
- Only ONE active (non-closed) session per staff member per day.
- When opened: `closed_at` is NULL.
- POS transactions require an active session. If none: "No active POS session. Please open a session first."
- Close guard: session must not already be closed.
- On close:
  1. Sets `closed_at = now()`.
  2. Recalculates totals from actual POS transactions linked to this session (overwrites stored values).
  3. Discrepancy between stored and computed totals logged in `notes`.
- Closed sessions cannot accept new POS transactions.

**No Soft Delete:** No `deleted_at`. Cannot be deleted. Can be deactivated (`is_active = 0`).

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

**Immutability:** No `is_active`, no `deleted_at`. Once saved, cannot be modified or deleted.
- Mistakes corrected via Adjustment transaction on meal card (if card was used). Original transaction stands.

**Payment Mode Rules:**
- **MealCard:** `student_id` and `meal_card_id` required. `balance_after` stores post-deduction balance. Card balance deducted atomically within same DB transaction.
- **Cash:** `student_id` optional (anonymous allowed). `meal_card_id` and `balance_after` are NULL.
- Cannot mix modes.

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

**Receipt:** After success, digital receipt can be sent. `receipt_sent = 1` after dispatch.

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

- No `is_active`, no `deleted_at`: transactional log.
- `payroll_deduction_flag = 1` signals PAY module. CAF never writes to `pay_*` tables.
- `items_json`: same structure as POS transaction `items_json`. Immutable.

## Permissions

| Operation | Permission Key |
|---|---|
| POS — Open/Close session | `tenant.cafeteria.pos-session.*` |
| POS — Process transactions | `tenant.cafeteria.pos-transaction.process` |
| Staff Meal Logs — CRUD | `tenant.cafeteria.staff-meal-log.*` |
