# Transactions — Business Requirements

## What This Screen Does

Manages the complete check-out and check-in lifecycle of physical library books. Handles issuing books to members, recording returns, calculating overdue fines, managing renewals, and tracking lost books. This is the core operational screen of the library management system.

---

## When This Screen Is Used

- During member check-out at the library counter.
- During book return/check-in at the library counter.
- When members request renewal of borrowed books.
- When books are reported lost by members.
- For viewing borrowing history of members or books.

## Default Data Load

Index loads all transactions ordered by issue_date descending, paginated at 15 per page. Default filter shows only currently issued transactions (status = issued). Date range defaults to current month. Member and book search inputs are empty.

---

## Key Fields at a Glance

| Field | Type | Description |
|---|---|---|
| member_id | FK (lib_members) | The borrowing member |
| copy_id | FK (lib_book_copies) | The specific copy issued |
| issue_date | datetime | When the book was checked out |
| due_date | datetime | Expected return date |
| return_date | datetime (nullable) | Actual return date |
| status | FK (lib_library_status_masters) | issued, returned, overdue, lost |
| fine_amount | decimal(10,2) | Calculated fine if overdue |
| notes | text | Additional notes |

---

## Business Rules and Conditions

- Issue date is always set to NOW when a transaction is created.
- Due date is calculated as NOW + loan_period_days from the member's membership_type.
- A member cannot borrow if they have reached their max_books_allowed limit.
- A member with overdue books cannot borrow new books.
- Fine is calculated as overdue_days * fine_per_day from the associated fine_type.
- Renewal extends due_date by the same loan_period_days from current due_date.
- A book can only be renewed once per issue cycle unless overridden by librarian.
- Marking a book as Lost immediately creates a fine record for the full replacement cost.
- When a book is returned, the copy status reverts to Available.
- Returns must be processed at the library counter with staff verification.
- The system enforces that only one active transaction can exist per copy at any time.

---

## Detailed Business Rules

### 1. Transaction Types

| Type | Description |
|------|-------------|
| **Issue (Borrow)** | Book physically given to member |
| **Return** | Book received back at counter |
| **Renew** | Due date extended (transaction status remains Issued) |
| **Mark Lost** | Book reported missing by member |
| **Mark Damaged** | Condition degraded on return |

### 2. Status Lifecycle

```
Issued → Returned (normal)
Issued → Overdue (auto when due_date passes)
Issued → Lost (admin manually)
Issued → Renewed (status = Issued, due_date extended)
```

### 3. Issue Flow — Checks Before Issue

| # | Check | Failure Behaviour |
|---|-------|-------------------|
| 1 | `max_books_allowed` — current issued+overdue count < limit? | "Member has reached the maximum borrowing limit" |
| 2 | `expiry_date` — membership not expired | "Member's library membership has expired" |
| 3 | `outstanding_fines` — < ₹500 | "Outstanding fines exceed ₹500. Please clear fines first." |
| 4 | `is_reference_only` — reference books cannot be issued | "Reference books cannot be issued" |
| 5 | Copy condition `is_borrowable` = true | "This copy is not in borrowable condition" |
| 6 | Member status = Active | "Member's library access is suspended" |

### 3b. Issue Flow — Auto Updates After Issue

| # | Auto Update | Target Table |
|---|-------------|-------------|
| 1 | `total_books_borrowed++` | `lib_members` |
| 2 | `last_activity_date` = now | `lib_members` |
| 3 | `lib_book_copies.status` → Issued | `lib_book_copies` |
| 4 | `lib_book_copies.current_due_date` → set | `lib_book_copies` |
| 5 | If pending reservation exists → `markPickedUp(transaction_id)` called | `lib_physical_book_requests` |

### 4. Return Flow — Condition Comparison + Overdue Fine Calculation

**Condition Check:**
- Compare `issue_condition_id` (condition at issue time) vs `return_condition_id` (condition at return)
- If condition degraded → `is_fine_applicable=1` (damage fine applied)

**Overdue Fine Calculation (Grace Period):**
- `grace_period_days` from membership type
- `billable_days = actual_overdue_days - grace_period_days`
- Fine calculated via **Fine Slab Config** (not `fine_rate_per_day` — deprecated)
- Formula: `fine_amount = slab_config.calculate(billable_days)`

**Auto Updates After Return:**

| # | Auto Update | Target Table |
|---|-------------|-------------|
| 1 | `outstanding_fines += fine_amount` | `lib_members` |
| 2 | `last_activity_date` = now | `lib_members` |
| 3 | `lib_book_copies.status` → Available | `lib_book_copies` |
| 4 | `lib_book_copies.current_due_date` → NULL | `lib_book_copies` |
| 5 | Queue notification: check pending reservations for this book | `lib_physical_book_requests` |

**Queue Notification on Return:**
- Check if any pending reservation exists on this book
- If yes → notify next member in queue
- Queue order: FCFS (First Come First Serve) by `request_date`

### 5. Renewal Flow

**Pre-conditions:**
- `renewal_allowed=1` on membership type
- `renewal_count < max_renewals` on membership type
- Transaction must be in Issued status

**Auto Updates:**
- `due_date += loan_period_days` (or `renewal_days_requested` if specified)
- `renewal_count++`
- `is_renewed = 1`
- `last_activity_date` = now (member table)

### 6. Lost Flow

**Auto Updates when Marked Lost:**
- `lib_book_copies.status` → Lost
- `outstanding_fines += replacement_cost + overdue_fine`
  - `replacement_cost` from book copy record
  - `overdue_fine` calculated via slab config for days overdue up to current date
- `last_activity_date` = now

### 7. Fine Calculation System

- ⚠️ `membership_type.fine_rate_per_day` is **deprecated** — no longer used
- Fine Slab Config system calculates fines (see Section 3.3 of Library DDL)
- Grace period: `billable_days = raw_overdue_days - grace_period_days`
- If billable_days ≤ 0 → no fine

### 8. Key Auto-Update Fields (Code-Driven)

| # | Field | Trigger | Direction |
|---|-------|---------|-----------|
| 1 | `total_books_borrowed` | Auto increment on issue | member ++ |
| 2 | `total_fines_paid` | Auto increment on payment | member ++ |
| 3 | `outstanding_fines` | Auto inc/dec on fine/payment/return/lost | member +/- |
| 4 | `last_activity_date` | 19+ flows auto update | member = now |
| 5 | `lib_book_copies.status` | Sync with transaction status | copy = Issued/Available/Lost |
| 6 | `lib_book_copies.current_due_date` | Set on issue, clear on return | copy = due_date/null |
| 7 | `lib_book_copies.current_borrower_id` | Set on issue | copy = member_id |
| 8 | `lib_book_copies.issue_count` | Increment on each issue | copy ++ |

### 9. Audit Gaps (Found Jun 17, 2026)

| Gap | Severity | Description | Fix Status |
|-----|----------|-------------|-----------|
| **GAP-10** | MEDIUM | **`lib_book_copies.current_due_date` never set/cleared** | ✅ **FIXED** — Set on issue (= `due_date`), cleared to `null` on return in `LibTransactionController` |
| **GAP-11** | LOW | **Lost flow missing overdue fine** — only replacement cost added | ✅ **FIXED** — `markLost()` now calculates overdue fine via slab config + adds to `outstanding_fines` alongside replacement cost |

---

## Workflow Steps

1. Member brings books to check-out counter.
2. Librarian scans member barcode → member details loaded.
3. Librarian scans each book barcode → book copy validated.
4. System checks borrowing limits and overdue status.
5. Librarian confirms check-out → transaction created with issue_date=now, due_date calculated.
6. Copy status updated to Issued. Member's borrowed count incremented.
7. On due date (or before), member returns books.
8. Librarian scans returning books → system checks if overdue.
9. If overdue, fine calculated and displayed. Fine may be collected immediately.
10. Transaction status updated to Returned. Copy status updated to Available.
11. If book is lost, librarian marks as Lost → fine for replacement cost created.

---

## Example Scenario

Member Sarah (membership: Premium, loan_period_days=21, max_books=5) borrows 3 books. Each transaction is created with due_date = today + 21 days. After 25 days, Sarah returns 2 books. System calculates 4 overdue days for each. Fine = 4 * $0.50 = $2.00 per book. Sarah pays the fine. The third book is reported lost — system creates a fine of $25.00 (replacement cost).

---

## Related Screens

- Physical Book Requests (requests convert to transactions on pickup)
- Fines (fines auto-created for overdue and lost books)
- Members (member borrowing limits and history)
- Book Copies (copy status tracking)
- Fine Reports (fine collection analytics)
- Digital Access Transactions (parallel for digital resources)

---

## Requirements (technical: controller, model, validation, policy)

**Controller:** LibTransactionController
- Standard CRUD: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete
- Extra methods: returnBook, renew, markLost, receive, history, getDetails, getFineCalculation, calculateFine
- returnBook(): Sets return_date = now, calculates fine if overdue via calculateFine(), updates copy status to Available, updates member stats.
- renew(): Validates renewal eligibility (max once per cycle), extends due_date by loan_period_days, logs renewal.
- markLost(): Sets status = Lost, creates LibFine with replacement cost from fine type.
- history(): Returns paginated transaction history for a specific member or book.
- getDetails(): AJAX endpoint returning transaction details for modal display.
- getFineCalculation(): AJAX endpoint previewing fine amount before confirmation.
- calculateFine(): Private method computing overdue fine = overdue_days * fine_per_day.
- Permissions: tenant.lib-transactions.*

**Model:** LibTransaction (table: lib_transactions)
- Fillable: member_id, copy_id, issue_date, due_date, return_date, status, fine_amount, notes
- Casts: issue_date → datetime, due_date → datetime, return_date → datetime, fine_amount → decimal:2
- Relations: member (belongsTo LibMember), copy (belongsTo LibBookCopy), fine (hasOne LibFine)
- Scopes: issued(), returned(), overdue(), lost(), byMember($memberId), overdueAsOf($date)
- Accessors: isOverdue → bool (due_date < now AND status = issued), daysOverdue → int

**DB Triggers:**
1. update_member_borrowed_count (AFTER INSERT): Increments member.total_books_borrowed, updates member.last_activity_date.
2. update_copy_status_on_issue (AFTER INSERT): Updates lib_book_copies.status = 'Issued'.
3. update_copy_status_on_return (AFTER UPDATE): When return_date IS NOT NULL, updates lib_book_copies.status = 'Available'.
4. auto_calculate_fines (EVENT daily): Queries all issued transactions where due_date < NOW(), creates pending LibFine records for each.

**FormRequest:** LibTransactionRequest
- Store rules: member_id → required|exists:lib_members,id, copy_id → required|exists:lib_book_copies,id|unique:lib_transactions,copy_id,NULL,id,status,issued
- Update rules: status → required|exists:lib_library_status_masters,id

**Policy:** LibTransactionPolicy
- Gates match permissionslist.php group: lib-transactions

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — all actions |
| Librarian | Full CRUD + returnBook, renew, markLost, history |
| Library Staff | Check-out (create), check-in (returnBook), view |
| Member | View own transaction history only (history with member_id filter) |

---

## How This Screen Works — Logic Flow (Non-Technical)

The main transactions screen shows a table of all book check-outs. Librarians use the top search bar to find transactions by member name, book title, or barcode. Tabs filter by status: Issued (currently borrowed), Returned (history), Overdue (past due), Lost. The check-out flow uses a two-step modal: first scan member card, then scan books. Each scanned book appears in a list with title, barcode, and due date. The check-in flow is simpler — scan a book barcode and the system looks up the active transaction, calculates any fine, and processes the return. Renewal is a single-click action on an issued transaction row. The history view shows all past transactions for audit purposes.

---

## Validate Before Save

- member_id must reference an active member with valid membership.
- copy_id must reference a copy with status = Available (for new check-outs).
- Member must not have reached max_books_allowed on their membership type.
- Member must not have any overdue books (unless overridden by librarian permission).
- copy_id must not have another active issued transaction.
- For renewals: transaction must be in issued status, must not have been renewed already this cycle.

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Copy not available | "This book copy is currently issued to another member." |
| Member at max books | "Member has reached the maximum borrowing limit." |
| Member has overdue books | "Member has overdue books. Please return them before issuing new ones." |
| Invalid barcode | "No book found with this barcode." |
| Member not found | "No member found with this ID or barcode." |
| Renewal limit reached | "This book has already been renewed once. Further renewal requires librarian override." |
| Transaction not found for return | "No active issued transaction found for this copy." |
| Copy already returned | "This book has already been returned." |

---

## Success Scenarios

- Book checked out → "Book issued successfully. Due date: {date}."
- Book returned on time → "Book returned successfully. No fines due."
- Book returned overdue → "Book returned successfully. Fine of ${amount} has been applied."
- Book renewed → "Book renewal successful. New due date: {date}."
- Book marked lost → "Book marked as lost. Replacement fine of ${amount} has been created."
- Bulk check-out completed → "{count} books issued to {member} successfully."

---

## Failure Scenarios

- Check-out attempted when member is suspended → "Member's library access is suspended. Cannot issue books."
- Check-out of a reserved book to wrong member → System warns "This copy is reserved for another member."
- Network failure during check-out → Transaction partially saved, admin must reconcile via audit log.
- Scanner malfunction → Manual barcode entry fallback available.
- Fine calculation discrepancy → System logs calculation details for audit, allows manual fine adjustment.
- Database constraint violation on trigger → Transaction rolled back, error logged with full context.

---

## Dependencies module and tables

| Dependency | Type |
|---|---|
| lib_members | Table — member validation and limits check |
| lib_book_copies | Table — copy status management |
| lib_book_masters | Table — book catalog reference |
| lib_membership_types | Table — loan_period_days, max_books_allowed |
| lib_library_status_masters | Table — transaction status codes |
| lib_fines | Table — auto-created for overdue/lost |
| lib_fine_types | Table — fine rate configuration |
| lib_physical_book_requests | Table — pickup creates transaction |
| lib_fine_payments | Table — fine payment records |
| User/Role module | Module — authentication and permissions |
