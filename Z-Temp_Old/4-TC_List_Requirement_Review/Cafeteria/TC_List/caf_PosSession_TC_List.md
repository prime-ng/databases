# caf_PosSession — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** POS Sessions (Counter Sales + Open/Close Shift + MealCard + Cash + Service Override)
**DB scope:** TENANT-side (`caf_pos_sessions`, `caf_pos_transactions`) · **Test style:** Browser Dusk + API
**Primary table:** `caf_pos_sessions` · **Module URL prefix:** `/cafeteria/orders-attendance?tab=pos`
**Test file:** `caf_PosSession_TestCas.php`
**Tab:** POS Sessions (fourth tab of Orders & Attendance)

Controllers:
- `PosController` — index, openSession (POST), closeSession (POST), reopenSession (POST), processTransaction (POST), printReceipt (GET)
- `CafeteriaController::ordersAttendance()` — loads POS sessions for tabbed page

Service:
- `PosService` — openSession, closeSession, processTransaction, getActiveSession, getSessionTransactions

Routes (`cafeteria.` prefix):
- `GET /cafeteria/orders-attendance` — tabbed page (pos tab)
- `POST /cafeteria/pos/sessions/open` — open new session
- `POST /cafeteria/pos/sessions/{session}/close` — close session
- `POST /cafeteria/pos/sessions/{session}/reopen` — reopen closed session
- `POST /cafeteria/pos/sessions/{session}/transactions` — process transaction
- `GET /cafeteria/pos/transactions/{transaction}/print` — print receipt

**DDL reference:** caf_pos_sessions, caf_pos_transactions (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_pos_sessions`: id (INT UNSIGNED PK AI), session_date (DATE NOT NULL), is_active (TINYINT 1 DEFAULT 1), opened_by (INT UNSIGNED FK → sys_users.id ON DELETE RESTRICT), opened_at (TIMESTAMP NULL), closed_at (TIMESTAMP NULL), closed_by (INT UNSIGNED NULL FK → sys_users.id ON DELETE RESTRICT), notes (TEXT NULL), total_cash_collected (DECIMAL 10,2 DEFAULT 0), total_card_debited (DECIMAL 10,2 DEFAULT 0), total_transactions (INT DEFAULT 0), created_at, updated_at. Indexes: idx_caf_ps_date, idx_caf_ps_active | DDL |
| BC-DB-02 | Table `caf_pos_transactions`: id (INT UNSIGNED PK AI), session_id (INT UNSIGNED NOT NULL FK → caf_pos_sessions.id ON DELETE CASCADE), student_id (INT UNSIGNED NULL FK → std_students.id ON DELETE SET NULL), staff_id (INT UNSIGNED NULL FK → sys_users.id ON DELETE SET NULL), meal_card_id (INT UNSIGNED NULL FK → caf_meal_cards.id), payment_mode (ENUM('MealCard','Cash') NOT NULL), total_amount (DECIMAL 10,2 NOT NULL), balance_after (DECIMAL 10,2 NULL), subtotal (DECIMAL 10,2 DEFAULT 0), service_charge (DECIMAL 10,2 NULL), override_by (INT UNSIGNED NULL FK → sys_users.id ON DELETE SET NULL), override_reason (VARCHAR 255 NULL), items_json (JSON NOT NULL), dietary_flags_json (JSON NULL), receipt_sent (TINYINT 1 DEFAULT 0), created_by (INT UNSIGNED NOT NULL), created_at, updated_at. Indexes: idx_caf_pt_session, idx_caf_pt_student | DDL |
| BC-DB-03 | Model `PosSession`: table caf_pos_sessions, fillable 3 fields, casts: session_date→date, is_active→boolean, closed_at→datetime. Relations: opener() belongsTo User, closer() belongsTo User, transactions() hasMany PosTransaction | Model |
| BC-DB-04 | Model `PosTransaction`: table caf_pos_transactions, fillable 8 fields, casts: total_amount→decimal:2, items→array, receipt_printed→boolean. Relations: session() belongsTo PosSession, student() belongsTo Student, staff() belongsTo User, overrideBy() belongsTo User | Model |

### BC-VAL — Validation (StorePosTransactionRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` nullable integer exists:std_students,id | FR |
| BC-VAL-02 | `staff_id` nullable integer exists:sys_users,id | FR |
| BC-VAL-03 | `payment_mode` required in:MealCard,Cash | FR |
| BC-VAL-04 | `items` required array min:1 | FR |
| BC-VAL-05 | `items.*.menu_item_id` required integer exists:caf_menu_items,id | FR |
| BC-VAL-06 | `items.*.quantity` required integer min:1 | FR |

### BC-AUTH — Authorization (PosSessionPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.pos` (viewAny) | View (note: permission uses `cafeteria.pos.*` pattern) |
| BC-AUTH-02 | open/create gate `cafeteria.pos.create` | Policy (note: permission uses `cafeteria.pos.*`) |
| BC-AUTH-03 | transaction/create gate `cafeteria.pos.transaction.create` | View (note: permission uses `cafeteria.pos.*`) |
| BC-AUTH-04 | close/update gate `cafeteria.pos.close` | View (note: permission uses `cafeteria.pos.*`) |
| BC-AUTH-05 | reopen gate `cafeteria.pos.reopen` | View (note: permission uses `cafeteria.pos.*`) |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | POS tab: active session card (green header) with "Open Session" button if none active | View |
| BC-BIZ-02 | Active session card shows: transaction count, total collected, "Close Session" + "New Transaction" buttons | View |
| BC-BIZ-03 | Closed sessions listed below active, each with "Reopen" action | View |
| BC-BIZ-04 | Open session: POST/sessions/open → auto-closes previous active, creates new is_active=1 | Service |
| BC-BIZ-05 | Close session: POST/sessions/{id}/close → is_active=0, closed_at=now | Service |
| BC-BIZ-06 | Reopen session: POST/sessions/{id}/reopen → is_active=1, closed_at=null | Ctrl |
| BC-BIZ-07 | Process transaction: validates session active, creates PosTransaction | Service |
| BC-BIZ-08 | MealCard: deducts from student's meal card via lockForUpdate | Service |
| BC-BIZ-09 | Cash: no card deduction, no student required | Service |
| BC-BIZ-10 | If transaction has meal_category_id → auto-create MealAttendance (scan_method=pos) | Service |
| BC-BIZ-11 | Service override: stores override_by + override_reason on transaction | Service |
| BC-BIZ-12 | Items stored as JSON array with menu_item_id, name, quantity, price, line_total | Service |
| BC-BIZ-13 | Print receipt: GET/print → generates receipt view | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Open session when one already active → auto-closes old, creates new | Service |
| BC-EDG-02 | Close already-closed session → DomainException | Service |
| BC-EDG-03 | Process transaction on closed session → DomainException | Service |
| BC-EDG-04 | MealCard transaction with invalid student_id → validation error | Val |
| BC-EDG-05 | MealCard transaction with insufficient balance → DomainException | Service (implied from MealCardService) |
| BC-EDG-06 | Empty items array → min:1 validation error | Val |
| BC-EDG-07 | Reopen freshly opened session with transactions → edge case (POS session reuse) | Ctrl |

---

## 2. Test Case List

### Screen 1: POS Sessions Tab (GET /cafeteria/orders-attendance?tab=pos)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P10 | Positive | View | POS tab: "Open Session" button visible when no active session | Button | test_caf_ps_10 | Automated |
| TC-CAFPS-P11 | Positive | View | Active session card: green header, transaction count, total collected, Close + New Transaction buttons | Card | test_caf_ps_11 | Automated |
| TC-CAFPS-P12 | Positive | View | Closed sessions listed with Reopen action | List | test_caf_ps_12 | Automated |
| TC-CAFPS-P13 | Positive | View | New Transaction modal: item search+select, qty input, payment_mode radio (MealCard/Cash), student lookup | Modal | test_caf_ps_13 | Automated |

### Screen 2: Open Session (POST /cafeteria/pos/sessions/open)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P30 | Positive | Ctrl | Open session when none active → created, is_active=1, activity logged | Created | test_caf_ps_30 | Automated |
| TC-CAFPS-P31 | Positive | Ctrl | Open session when one active → old auto-closed, new active session | Auto-close | test_caf_ps_31 | Automated |

### Screen 3: Close Session (POST /cafeteria/pos/sessions/{session}/close)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P50 | Positive | Ctrl | Close active session → is_active=0, closed_at set, activity logged | Closed | test_caf_ps_50 | Automated |
| TC-CAFPS-N51 | Negative | Ctrl | Close already-closed session → DomainException | Blocked | test_caf_ps_51 | Automated |

### Screen 4: Reopen Session (POST /cafeteria/pos/sessions/{session}/reopen)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P70 | Positive | Ctrl | Reopen closed session → is_active=1, closed_at=null | Reopened | test_caf_ps_70 | Automated |

### Screen 5: Process Transaction (POST /cafeteria/pos/sessions/{session}/transactions)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P90 | Positive | Service | Cash transaction → created, no card deduction, no attendance | Created | test_caf_ps_90 | Automated |
| TC-CAFPS-P91 | Positive | Service | MealCard transaction → created, card deducted, attendance auto-logged | Created+Deducted | test_caf_ps_91 | Automated |
| TC-CAFPS-P92 | Positive | Service | Transaction with service override → override_by+override_reason stored | Overridden | test_caf_ps_92 | Automated |
| TC-CAFPS-P93 | Positive | Service | Transaction with multiple items → JSON items stored correctly | Items saved | test_caf_ps_93 | Automated |
| TC-CAFPS-N94 | Negative | Service | Transaction on closed session → DomainException | Blocked | test_caf_ps_94 | Automated |
| TC-CAFPS-N95 | Negative | Val | Transaction with empty items → min:1 validation error | Error | test_caf_ps_95 | Automated |
| TC-CAFPS-N96 | Negative | Val | Transaction with invalid menu_item_id → exists validation error | Error | test_caf_ps_96 | Automated |
| TC-CAFPS-N97 | Negative | Service | Transaction with MealCard + insufficient balance → DomainException | Blocked | test_caf_ps_97 | Automated |
| TC-CAFPS-N98 | Negative | Service | Transaction with invalid student_id → exists validation error | Error | test_caf_ps_98 | Automated |

### Screen 6: Print Receipt (GET /cafeteria/pos/transactions/{transaction}/print)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P110 | Positive | Ctrl | Print receipt → receipt view rendered, receipt_printed=1 | Printed | test_caf_ps_110 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFPS-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_ps_200 | Automated |
| TC-CAFPS-N201 | Negative | Auth | Without viewAny → tab hidden, index 403 | 403 | test_caf_ps_201 | Automated |
| TC-CAFPS-N202 | Negative | Auth | Without create → 403 on open session | 403 | test_caf_ps_202 | Automated |
| TC-CAFPS-N203 | Negative | Auth | Without update → 403 on close/reopen | 403 | test_caf_ps_203 | Automated |
