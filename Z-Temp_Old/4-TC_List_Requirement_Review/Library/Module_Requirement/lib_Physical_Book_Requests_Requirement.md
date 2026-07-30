# Physical Book Requests — Business Requirements

## What This Screen Does

Allows library members to request physical books for pickup and librarians to manage the request lifecycle from pending to available to picked up. Members submit requests for books that are currently checked out or held in the stacks. Librarians mark books as available when ready, then mark as picked up when the member collects them.

---

## When This Screen Is Used

- Members use it to place holds on physical books that are unavailable or need retrieval from stacks.
- Librarians use it to manage the request queue, set availability status, and confirm pickup.
- The screen is accessed from the Staff Library Portal and the Member Portal.

## Default Data Load

On initial load, the index page displays all non-cancelled requests ordered by request_date descending, paginated at 10 per page. Active tab defaults to "Pending" requests. Status filter defaults to show all statuses.

---

## Key Fields at a Glance

| Field | Type | Description |
|---|---|---|
| member_id | FK (lib_members) | The member who placed the request |
| book_id | FK (lib_book_masters) | The requested book |
| copy_id | FK (lib_book_copies) | The specific copy assigned when available |
| request_date | datetime | When the request was submitted |
| status | FK (lib_library_status_masters) | Current status: pending, available, picked_up, cancelled |
| notes | text | Librarian or member notes |

---

## Business Rules and Conditions

- A member can only have one pending request per book at a time.
- Only one copy can be marked as available per request.
- Status transitions: Pending → Available → Picked Up (creates LibTransaction). Pending → Cancelled.
- Once Picked Up, the request is closed and a LibTransaction record is created with issue_date = now.
- Members cannot cancel a request after it has been marked as Available.
- The system must prevent duplicate pending requests for the same member+book combination.
- When a request is marked Picked Up, the associated copy status must change to Issued.
- Only members with active library memberships can submit requests.

---

## Detailed Business Rules

### 1. Request Types
Two request types flow through this table:
- **Borrow/Reservation Request** (`is_renewal_request=0`): Book is currently with someone else — member reserves it. Notified when book is returned.
- **Renewal Request** (`is_renewal_request=1`): Book already issued to member — member wants to extend the due date.

### 2. Full Lifecycle Flow
```
Member Request → Pending
                   ├─ Librarian Approve → (Checks pass → LibTransaction create/update → tables updated → Book Issued)
                   ├─ Librarian Reject  → Status = Cancelled with reason
                   └─ Member Withdraw   → Status = Withdrawn with withdrawal_reason
```

### 3. Seven Validation Checks at Request Create Time

| # | Check | Source Table | Failure Behaviour |
|---|-------|-------------|-------------------|
| 1 | Member registered? | `lib_members` | "You are not registered" error |
| 2 | `renewal_allowed=1`? (renewal only) | `lib_membership_types` | "Renewal not allowed" error |
| 3 | `renewal_count < max_renewals`? (renewal only) | `lib_membership_types` → `lib_transactions` | "Maximum renewals (N) reached" |
| 4 | `current issued+overdue < max_books_allowed`? | `lib_membership_types` + `lib_transactions` count | "Reached Limit (N books)" |
| 5 | Book `is_reference_only=false`? | `lib_books_master` | "Reference book cannot be reserved" |
| 6 | Copy condition `is_borrowable=true`? | `lib_book_copies` → `lib_book_conditions` | "This copy is not borrowable" |
| 7 | **Member Type vs Resource Type Compatible?** | `lib_members.membership_type_id` → `lib_books_master.resource_type_id` → `lib_resource_types` | "Your membership type does not allow borrowing this resource type" |

**Condition 7 Detail — Member Type vs Resource Type Compatibility Matrix:**
Every membership type has resource limitations. This check ensures:
- If book `is_physical=1` → physical borrow flow allowed
- If book `is_digital=1` AND membership_type `digital_access_days=0` → digital access blocked (member must raise a digital access request)
- If membership_type `can_restricted_members_view_list=0` → restricted resources not accessible
- **NOTE:** This check is marked for future implementation in code. DDL has `lib_membership_types.digital_access_days` column but code uses it only in digital resource flow, not in physical issue flow.

### 4. APPROVE FLOW — Complete Table-by-Table Updates (CRITICAL)

When Librarian clicks "Approve", these tables update sequentially:

**Step 1: Pre-Approve Checks (Re-validate — Race Condition Prevention)**
- All 7 checks from request create time are re-run
- Extra check: `lib_book_copies` currently available? (for borrow) — no one else took it
- Extra check: `lib_members.expiry_date` still valid?
- Extra check: `lib_members.outstanding_fines < ₹500`?
- Extra check: `lib_members.status = Active`?

**Step 2: `lib_physical_book_requests` Update**

| Field | Normal Borrow Approve | Renewal Approve |
|-------|---------------------|-----------------|
| `status` | → Approved → Issued | → Issued (or stays approved) |
| `renewal_approved` | — | 1 |
| `renewal_approved_by_id` | — | `auth()->id()` (librarian) |
| `renewal_approved_at` | — | `now()` |
| `transaction_id` | → new transaction ID | → same transaction (updated) |

**Step 3: `lib_transactions` Update (Existing Row Updated)**

| Field | Normal Borrow | Renewal |
|-------|--------------|---------|
| `book_id` | `$request->book_id` | existing `book_id` |
| `copy_id` | selected available copy | existing `copy_id` |
| `member_id` | `$request->member_id` | same member |
| `issue_date` | `now()` | existing issue_date |
| `due_date` | `now() + loan_period_days` | `old_due_date + renewal_days_requested` (or `+ loan_period_days`) |
| `issued_by_id` | `auth()->id()` | existing |
| `issue_condition_id` | current copy condition | existing |
| `status` | Issued | Issued |
| `is_renewed` | 0 | 1 |
| `renewal_count` | 0 | old_count + 1 |

**Step 4: `lib_book_copies` Update (Book Copy Table)**

| Field | Normal Borrow | Renewal |
|-------|--------------|---------|
| `status` | → Issued | → Issued (already was) |
| `current_due_date` | → new due_date | → extended due_date |
| `current_borrower_id` | → member_id | — |

**Step 5: `lib_members` Update (Member Table)**

| Field | Normal Borrow | Renewal |
|-------|--------------|---------|
| `total_books_borrowed` | ++ (increment) | — (already counted) |
| `last_activity_date` | → `now()` | → `now()` |

**Step 6: `lib_transaction_history` Create (History Log)**

| Field | Normal Borrow | Renewal |
|-------|--------------|---------|
| `transaction_id` | new transaction ID | existing transaction ID |
| `action` | "Issued" | "Renewed" |
| `days_added` | `loan_period_days` | `renewal_days_requested` (or `loan_period_days`) |
| `performed_by_id` | `auth()->id()` | `auth()->id()` |

### 5. REJECT / CANCEL FLOW

- **Reject by Librarian:**
  - `lib_physical_book_requests.status` → Cancelled
  - `renewal_approved` = 0, `renewal_approved_by_id` = librarian, `renewal_approved_at` = now
  - If renewal request rejected → status Cancelled (renewal_approved=0 + approved_by set)
- **Withdraw by Member:**
  - `lib_physical_book_requests.status` → Withdrawn
  - `withdrawal_reason` → member's reason (required)

### 6. Notification Matrix (8 Events)

| Event | Trigger | Message | Sent To |
|-------|---------|---------|---------|
| Request Submitted | Member submits request | "Request Received" | Member |
| Request Approved (Borrow) | Librarian approves | "Your request is approved. Please collect the book by {pickup_by_date}" | Member |
| Request Approved (Renewal) | Librarian approves renewal | "Renewal Approved. New due date: {due_date}" | Member |
| Request Rejected | Librarian rejects | "Your request has been rejected." | Member |
| Request Withdrawn | Member withdraws | "Request Withdrawn" | Member |
| Book Available | Book returned OR new copy purchased | "Book {title} is now available. Please collect." | Next member(s) in queue |
| Renewal Rejected | Librarian rejects renewal | "Renewal Rejected. Reason: {withdrawal_reason or librarian note}" | Member |
| Book Overdue | Auto cron/scheduler | "Book {title} is overdue. Please return immediately." | Member (current borrower) |

### 7. Reservation Queue Logic (FCFS + Priority)

- When book is returned → check `lib_physical_book_requests` for Pending reservations
- **Order:** `priority_level DESC` (membership type) → `request_date ASC` (FIFO)
- **Example:**
  - Member A (priority 10) requested 10 May
  - Member B (priority 1) requested 10 May
  - Member C (priority 10) requested 12 May
  - **Order:** A → C → B (priority 10 first, both 10 May → FIFO, then priority 1)
- Notify: "Book Available" message to matched member
- `pickup_by_date` set — number of days to collect
- If not collected by `pickup_by_date` → request auto-cancelled → next member notified

### 8. Auto-Cleanup / Edge Cases

- **Pickup By Date Expired:** `pickup_by_date` passed → request auto-cancelled
- **Duplicate Prevention:** UNIQUE KEY `(book_id, member_id, status)` prevents duplicate requests
- **Race Condition:** At approve time, all checks re-run (max_books_allowed, copy availability, expiry)
- **Re-request:** If request cancelled/withdrawn, member can request again
- **Important Edge Case — Resource Type Restriction After Approval:**
  - Scenario: Member Type X (e.g., External Member) allowed only physical books. Book Y has `resource_type_id = EBOOK` (`is_physical=0`).
  - Blocked at Condition 7 at request time. If request somehow created, pre-approve check blocks at approve time.
  - If bug/race condition allows approval despite condition 7 failure: `lib_physical_book_requests` → Approved, `lib_transactions` → new row, `lib_book_copies` → Issued, `lib_members` → total_books_borrowed++, `lib_transaction_history` → entry. **This is incorrect.** Proper fix: implement Condition 7 everywhere (request time + approve time).

### 9. Gap Analysis

| # | Gap | Severity | Fix Status |
|---|-----|----------|-----------|
| 1 | No notification system | HIGH | ⏳ Future (8 events, zero code) |
| 2 | Pre-approve race guards | HIGH | ✅ `approveRenewal()` + `update()` re-checks all |
| 3 | Queue priority logic | HIGH | ✅ Already implemented + `queue_position` added |
| 4 | Condition #7 (Type compat) | MED | ✅ All 4 controllers have check |
| 5 | "Withdrawn" vs "Cancelled" | MED | ✅ `withdraw()` method + status DB entry |
| 6 | Auto-cleanup pickup_by_date | MED | ⏳ Future (cron needed) |
| 7 | Duplicate prevention | LOW | ✅ Admin store() check added |
| 8 | MD "new transaction" mismatch | LOW | ✅ MD corrected |
| 9 | Table rename | FIXED | ✅ `lib_reservations` → `lib_physical_book_requests` |

---

## Workflow Steps

1. Member browses catalogue and clicks "Request Book" on an unavailable book.
2. System creates LibPhysicalBookRequest with status = Pending.
3. Librarian reviews pending requests and retrieves a copy from stacks.
4. Librarian clicks "Mark Available" — status changes to Available, copy_id assigned.
5. Member is notified that book is ready for pickup.
6. Member visits library and collects the book.
7. Librarian clicks "Mark Picked Up" — status changes to Picked Up, LibTransaction created.
8. Alternative: Member cancels before availability — status changes to Cancelled.

---

## Example Scenario

Member John (ID: 45) requests "The Great Gatsby" which is currently checked out. Librarian sees the request in pending queue, finds a returned copy, marks it available. John gets an email notification, picks up the book. Librarian marks it picked up. A transaction is auto-created with issue_date = now and due_date = now + 14 days (based on John's membership plan).

---

## Related Screens

- Transactions (check-out auto-created on pickup)
- Book Catalogue (books browsed from catalogue feed into requests)
- Members (member details and borrowing history)
- Book Copies (copy assignment and status tracking)

---

## Requirements (technical: controller, model, validation, policy)

**Controller:** LibPhysicalBookRequestController
- Standard CRUD methods: index, create, store, show, edit, update, destroy, trashed, restore, forceDelete
- Extra methods: cancelPage, cancel, markAvailable, markPickedUp, approveRenewal, rejectRenewal
- cancel(): Validates request is in Pending status before cancelling. Sets status = Cancelled.
- markAvailable(): Assigns a copy_id from available copies. Sets status = Available.
- markPickedUp(): Validates status = Available. Creates LibTransaction with issue_date = now, due_date based on membership_type.loan_period_days. Sets status = Picked Up.
- approveRenewal/rejectRenewal: Handles renewal requests from members for already-picked-up books.
- Permissions: tenant.lib-physical-book-requests.*

**Model:** LibPhysicalBookRequest (table: lib_physical_book_requests)
- Fillable: member_id, book_id, copy_id, request_date, status, notes
- Casts: request_date → datetime
- Relations: member (belongsTo LibMember), book (belongsTo LibBookMaster), copy (belongsTo LibBookCopy), statusMaster (belongsTo LibLibraryStatusMaster, foreignKey: status)
- Scopes: pending(), available(), pickedUp(), cancelled(), byMember($memberId)

**FormRequest:** LibPhysicalBookRequestRequest
- Rules: member_id → required|exists:lib_members,id, book_id → required|exists:lib_book_masters,id, request_date → required|date
- Status transitions are enforced in the controller, not the FormRequest.

**Policy:** LibPhysicalBookRequestPolicy
- Gates match permissionslist.php group: lib-physical-book-requests
- Methods: viewAny, view, create, update, delete, restore, forceDelete

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — all actions |
| Librarian | Full CRUD + markAvailable, markPickedUp, approveRenewal, rejectRenewal |
| Library Staff | View + markAvailable, markPickedUp |
| Member | Create (submit request) + cancel own pending requests |

---

## How This Screen Works — Logic Flow (Non-Technical)

The screen shows a table of book requests grouped by status tabs (Pending, Available, Picked Up, Cancelled). Members see only their own requests. Librarians see all requests. The search bar allows filtering by member name or book title. Each row shows the member name, book title, request date, and status badge. Action buttons change based on status: Pending rows have "Cancel" (for members) and "Mark Available" (for librarians). Available rows have "Mark Picked Up". Status changes trigger notifications to the affected party.

---

## Validate Before Save

- member_id must reference an active member record.
- book_id must reference an existing book master record.
- request_date must be a valid date (cannot be future-dated beyond 30 days).
- Duplicate check: No existing Pending request for same member_id + book_id.
- Member must have active membership status (not expired, not suspended).

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Duplicate pending request | "You already have a pending request for this book." |
| Invalid member | "Selected member is not valid or inactive." |
| Invalid book | "Selected book does not exist." |
| Member membership inactive | "Member's library membership is not active." |
| Cannot cancel after available | "This request has already been marked as available and cannot be cancelled." |
| Cannot mark picked up from non-available | "Only requests with status 'Available' can be marked as picked up." |
| Copy already issued | "The selected copy is already issued to another member." |

---

## Success Scenarios

- Member submits request → "Your book request has been submitted successfully."
- Librarian marks available → "Book has been marked as available for pickup."
- Librarian marks picked up → "Book has been checked out to the member successfully. Transaction created."
- Member cancels request → "Your book request has been cancelled."
- Renewal approved → "Renewal request has been approved."

---

## Failure Scenarios

- Member tries to request a book they already have pending → Request rejected with duplicate error.
- Librarian tries to mark picked up without setting copy_id → System prevents action.
- Member tries to cancel an already-available request → Cancel button hidden, API returns 403.
- Database connection fails during pickup → Transaction not created, error logged, user shown "System error. Please try again."
- Copy not found when marking available → "No available copies of this book found."

---

## Dependencies module and tables

| Dependency | Type |
|---|---|
| lib_book_masters | Table — book catalog data |
| lib_book_copies | Table — copy assignment and status |
| lib_members | Table — member validation |
| lib_membership_types | Table — loan period days calculation |
| lib_library_status_masters | Table — status code management |
| lib_transactions | Table — auto-created on pickup |
| User/Role module | Module — authentication and permission checks |
| Notification module | Module — email/in-app notifications |
