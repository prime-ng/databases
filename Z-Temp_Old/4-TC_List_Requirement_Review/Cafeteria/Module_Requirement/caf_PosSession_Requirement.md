# POS Sessions — Business Requirements

## What This Screen Does

The POS Sessions tab manages counter-sale point-of-service sessions. A **POS session** represents a cashier shift — opened at the start of a meal service period and closed at the end. During an active session, staff can process **transactions** (counter sales) where students pay via **MealCard** or **Cash** for individual menu items.

Only one active session can exist at a time (`is_active = true`). Opening a new session auto-closes any existing active session. Each transaction logs which items were sold, the total amount, the payment method, and optionally the student (if MealCard payment, it also deducts from the student's meal card and auto-logs meal attendance).

The POS flow includes a **service override** feature (for system users to discount/give free items), **receipt printing**, and a **transaction log** per session.

## When This Screen Is Used

- **Counter Sales**: Students purchasing meals at the counter (not pre-ordered)
- **Cashier Shift Management**: Opening/closing daily counter shift
- **Transaction Processing**: Quick add-item → checkout flow during a meal period
- **Service Override**: Authorized staff overriding prices or giving free meals
- **End-of-Day Reconciliation**: Closing session with total count vs opening balance

## Key Fields (PosSession)

- **Session Date** (date) — Calendar date of the service shift
- **Is Active** (boolean) — Only one session can be active at a time
- **Opened By** (FK → `sys_users`) — Staff who opened the session
- **Closed At** (timestamp, nullable) — When session was closed
- **Notes** (text, nullable) — Shift notes

### Key Fields (PosTransaction)
- **Session** (FK → `caf_pos_sessions`)
- **Student** (FK → `std_students`, nullable) — For MealCard payments
- **Staff** (FK → `sys_users`, nullable) — For staff purchases
- **Payment Mode** (enum) — `MealCard`, `Cash`
- **Total Amount** (decimal 10,2) — Sum of items total
- **Subtotal** (decimal 10,2) — Before service charge
- **Service Charge** (decimal 10,2, nullable)
- **Override By** (FK → `sys_users`, nullable) — If service override applied
- **Override Reason** (varchar 255, nullable)
- **Items** (JSON) — Array of `{menu_item_id, name, quantity, price, line_total}`
- **Receipt Printed** (boolean)

### Menu Items (transaction items)
- Each transaction has multiple items via JSON column `items`
- Each item: `menu_item_id`, `name`, `quantity`, `price`, `line_total`

## Business Rules

**Single Active Session:** `PosService::openSession()` checks for existing active session; if found, auto-closes it (sets is_active=0, closed_at=now). Then creates a new session with is_active=1.

**Close Session:** `PosService::closeSession()` sets is_active=0 and closed_at=now. Throws if session already closed.

**Process Transaction (PosService::processTransaction()):**
1. Validates session is active
2. For MealCard payments: uses `lockForUpdate` on session row, deducts from student's meal card
3. Creates PosTransaction record with items JSON
4. If transaction has a meal_category_id, auto-creates MealAttendance (scan_method=pos)

**Service Override:** `processTransaction()` accepts optional `override_by` and `override_reason`. If provided, the override_by user ID is stored on the transaction. This allows authorized staff to discount or comp items.

**Receipt Printing:** `printReceipt()` method generates a printable receipt view. Each transaction has `receipt_printed` boolean flag.

**Soft Delete:** Neither PosSession nor PosTransaction uses SoftDeletes. PosSession is trashed by closing (is_active→0). There is no delete route for sessions.

**Activity Logging:**
- Open Session: `"POS session opened."`
- Close Session: `"POS session closed."`
- Transaction: `"POS transaction {id} processed - ₹{total} via {payment_mode}."`

## Workflow

1. Staff navigates to Cafeteria → Orders & Attendance → POS Sessions tab
2. If no active session exists, staff sees "Open Session" button with date picker
3. Staff clicks "Open Session" → new active session created
4. Active session shows transaction counter, total collected, and "Close Session" button
5. Staff can process transactions (add items, select payment mode, optionally link student)
6. Transaction modal: item search/select, quantity, payment mode (MealCard/Cash), student lookup (optional)
7. Staff submits transaction → items added, card deducted if MealCard, attendance logged
8. Staff can re-open a closed session (re-activate) via Reopen action
9. Staff closes session at end of shift

## Related Screens

- **Orders** — First tab; pre-orders vs counter sales
- **Meal Attendance** — Second tab; POS auto-logs attendance
- **Meal Cards** — Students' balance deducted for MealCard transactions

## Requirements

- MUST display POS sessions at `/cafeteria/orders-attendance?tab=pos` with active session highlighted
- MUST authorize via `cafeteria.pos.*` policy gates
- MUST enforce single active session (open auto-closes previous)
- MUST support open/close/reopen session lifecycle
- MUST process transactions with MealCard (deduct) or Cash (no deduction)
- MUST support service override with bypass reason
- MUST auto-log meal attendance for MealCard transactions with meal_category
- MUST print receipts with receipt_printed flag tracking
- MUST validate session is active before processing transactions
- MUST log session opens, closes, and transactions via activityLog()
