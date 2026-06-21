# Library Tab 7: Circulation (Issue / Return / Renew / Reserve)

This tab handles the core library workflow — issuing books to members, receiving returns, processing renewals, and managing reservations. This is the most frequently used operational tab in the library system.

---

## How It Works

The tab is divided into four operational sections.

**Issuing a Book:** The librarian scans or enters the member's library card barcode or membership number. The system displays the member's details, current issued books, and eligibility status. The librarian then scans or enters the book copy's barcode or accession number. The system validates that the copy is available and the member is eligible. On confirmation, the transaction is created with status "Issued," the copy status changes to "Issued," and the due date is calculated based on the member's membership type loan period. If the member has already reached their maximum allowed books, the issue is blocked with a clear message.

**Returning a Book:** The librarian scans the book copy's barcode. The system finds the active transaction for that copy. The librarian selects the return condition from a dropdown. On confirmation, the transaction is updated with the return date, return condition, and status changes to "Returned." The copy status changes back to "Available." If there is a reservation queue for this book, the first member in the queue is notified that the book is now available.

**Renewing a Book:** If the member wants to keep a book longer, the librarian can renew it. The system checks that renewal is allowed for this member's type and that the maximum renewal count has not been exceeded. If there is a reservation queue for this book, renewal is blocked. On confirmation, the due date is extended by the loan period and the renewal count increments.

**Reservations:** If a book is currently issued out, a member can place a reservation. The librarian enters the member and book, and the system adds the member to the reservation queue. The `queue_position` is calculated based on existing reservations. When the book is returned, the system checks the queue and notifies the next member that the book is available. The member has a configurable pickup window (default 48 hours) to collect the book before the reservation expires.

**Quick Actions Panel:** The tab includes a quick actions panel for common operations — issue by barcode scan, return by barcode scan, and renew by transaction ID.

---

## Important Business Rules

- A book can only be issued if the copy status is "Available." Copies with status Issued, Reserved, Under Maintenance, Lost, or Withdrawn cannot be issued.
- A member can only borrow books if their membership is Active and not expired, and their current issued count is below their type's maximum.
- If a member has outstanding fines above the threshold (configurable, default ₹500), issuing is blocked until fines are cleared.
- The due date is calculated as `issue_date + membership_type.loan_period_days`. Grace period days are added if configured.
- Renewal extends the due date from the current date (not from the original due date). Maximum renewals is per-transaction, not total.
- If a book has pending reservations, renewal is blocked regardless of eligibility. The librarian sees: "This book is reserved by another member. Please ask the member to return it."
- When a reserved book is returned, the top member in the queue is notified. The reservation status changes to "Available." If the member does not pick up within the pickup window (default 48 hours), the reservation status changes to "Expired" and the next member in the queue is notified.
- Members can cancel their own reservations at any time through the student portal.
- If a book copy is lost, all active reservations for that book are notified that the copy is no longer available.
- Reference-only books cannot be issued. The system blocks the issue action with a clear message.

---

## Database Columns & Behavior

### `lib_transactions`

(Full column table documented in Tab 1 — Dashboard.)

### `lib_reservations`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| book_id | BIGINT UNSIGNED | `lib_books_master.id` | No | — | Reserved book |
| member_id | BIGINT UNSIGNED | `lib_members.id` | No | — | Who reserved |
| reservation_date | DATETIME | No | No | — | When reserved |
| expected_available_date | DATETIME | No | Yes | NULL | Estimated availability |
| notification_sent | TINYINT(1) | No | No | 0 | Was notification sent? |
| pickup_by_date | DATETIME | No | Yes | NULL | Last date to collect |
| status | ENUM | No | No | 'Pending' | Pending, Available, Picked_Up, Cancelled, Expired |
| queue_position | INT UNSIGNED | No | No | 0 | Position in queue |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

---

## Deep Analysis

### Business Workflows & State Machines

**Transaction Lifecycle:**
```
ISSUE: Copy(Available) + Member(Eligible) → Transaction(Issued) + Copy(Issued)
RETURN: Transaction(Issued/Overdue) → Transaction(Returned) + Copy(Available)
RENEW: Transaction(Issued) + Renewal Allowed → Transaction(Issued) with new due_date
LOST: Transaction(Issued) → Transaction(Lost) + Copy(Lost) + Fine calculated
```

**Reservation Queue Management:**
```
Member reserves book → queue_position = MAX(queue_position) + 1
Book returned → top Pending reservation → status = Available, notify member
Member picks up → create issue transaction → status = Picked_Up
48h no pickup → status = Expired → next in queue becomes Available
Member cancels → status = Cancelled → queue recalculated
```

**Due Date Calculation:**
```
due_date = issue_date + membership_type.loan_period_days
If renewal: due_date = NOW() + membership_type.loan_period_days
  (not from original due_date)
```

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Issue book | Copy must be Available | "This copy is currently {status} and cannot be issued" |
| Issue book | Member must be Active | "Member status is {status}. Cannot issue books." |
| Issue book | Member must not exceed max books | "Member has reached maximum borrow limit ({max})" |
| Issue book | Outstanding fines below threshold | "Member has outstanding fines of ₹{amount}. Clear fines before issuing." |
| Issue book | Book must not be reference-only | "This is a reference-only book and cannot be issued" |
| Return book | Transaction must be Issued/Overdue | "No active issue transaction found for this copy" |
| Renew book | Renewal must be allowed | "Renewal is not allowed for this membership type" |
| Renew book | Max renewals not exceeded | "Maximum renewals ({max}) reached for this transaction" |
| Renew book | No pending reservations | "This book is reserved by another member" |
| Reserve book | Member must not already have a pending reservation for this book | "You already have a pending reservation for this book" |

**Edge Cases:**
- If a book copy is marked as lost, any active transaction for that copy is auto-closed with status "Lost" and a fine is generated.
- If a member's membership expires while they have issued books, they can still return them but cannot issue new ones.
- Barcode scanning uses prefix detection — if the scanned code matches a member barcode, switch to member lookup; if it matches a copy barcode, switch to copy lookup.
- The issue/return workflow supports scanning multiple books in sequence for the same member (bulk check-out/check-in).

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Book Copies | `lib_book_copies` | `copy_id` | Copy status management |
| Members | `lib_members` | `member_id` | Eligibility check |
| Membership Types | `lib_membership_types` | (via member) | Loan period, max books |
| Fines | `lib_fines` | `transaction_id` | Fine generation on overdue/lost |
| Reservations | `lib_reservations` | `book_id`, `member_id` | Reservation queue |
| Book Conditions | `lib_book_conditions` | `issue_condition_id`, `return_condition_id` | Condition tracking |
| Notification | (via event) | — | Reservation available, due date reminders |

**Scheduled Jobs:**
- Daily overdue job: marks transactions as "Overdue" when due_date < NOW()
- Daily reservation expiry job: expires reservations past pickup_by_date

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Issue book | Librarian, Admin | `tenant.library.circulation.issue` |
| Return book | Librarian, Admin | `tenant.library.circulation.return` |
| Renew book | Librarian, Admin | `tenant.library.circulation.renew` |
| View transactions | Librarian, Supervisor, Admin | `tenant.library.circulation.view` |
| Create reservation | Librarian, Admin | `tenant.library.circulation.reserve` |
| Cancel reservation | Librarian, Admin | `tenant.library.circulation.cancelReservation` |
| Mark transaction as lost | Librarian, Admin | `tenant.library.circulation.markLost` |
| Bulk check-out/in | Librarian, Admin | `tenant.library.circulation.bulkProcess` |
| Override due date | Supervisor, Admin | `tenant.library.circulation.overrideDueDate` |

- Students can view their own transactions and create/cancel their own reservations through the student portal.
- Override due date requires a reason and is logged.
