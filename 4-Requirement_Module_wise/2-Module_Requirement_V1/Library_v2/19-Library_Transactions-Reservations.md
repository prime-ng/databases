# Book Reservations — Requirement Document

## 1. Screen Purpose & Overview
This screen manages book reservations (holds) placed by members on cataloged items that are currently checked out or unavailable. It manages the hold request queue, tracks estimated return dates, notifies patrons when a copy becomes available, sets pickup deadlines, and updates queue priorities when a hold is cancelled or expired.

---

## 2. Common Business Use Cases
1. **Placing a Hold Request:** Creating a reservation for a book when all physical copies are currently checked out.
2. **Releasing to Hold Shelf:** Toggling status to `Available` once the copy is checked in, calculating the pickup deadline, and sending an email notice to the patron.
3. **Queue Promotion on Cancellation:** Removing a member from a queue and automatically advancing the next member in line.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_reservations`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `book_id` | `bigint` | No | N/A | FK to `lib_books_master.id`. Cascades on delete. |
| `member_id` | `bigint` | No | N/A | FK to `lib_members.id`. Cascades on delete. |
| `reservation_date` | `datetime` | No | N/A | Timestamp when the hold was placed. |
| `expected_available_date`| `date` | No | N/A | Estimated arrival date based on current active due dates. |
| `notification_sent` | `boolean` | No | `0` | Flag showing if pickup email/SMS has been sent. |
| `notification_sent_at`| `datetime` | Yes | `NULL` | Timestamp of notification dispatch. |
| `pickup_by_date` | `date` | Yes | `NULL` | Deadline for member to pick up the book (e.g. `notified_date + 3 days`). |
| `status` | `enum` | No | `'Pending'` | Values: `'Pending'`, `'Available'`, `'Picked_Up'`, `'Cancelled'`, `'Expired'`. |
| `queue_position` | `unsigned int` | No | `1` | Order position for pending titles. |
| `cancellation_reason`| `text` | Yes | `NULL` | Required if status is updated to `'Cancelled'`. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation date. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification date. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Book Title** | Dropdown / Search | Yes | Must select an active record from `lib_books_master`. | None |
| **Member Link** | Dropdown / Search | Yes | Must select an active record from `lib_members`. | None |
| **Pickup By Date** | Date Picker | Conditional| Required only if **Status** is `'Available'`. Must be $\ge$ today's date. | Today + 3 Days |
| **Status** | Dropdown | Yes | Choice of `'Pending'`, `'Available'`, `'Picked_Up'`, `'Cancelled'`, `'Expired'`. | `'Pending'` |
| **Cancellation Reason**| Text Area | Conditional| Required only if **Status** is set to `'Cancelled'`. Max 500 chars. | None |

---

## 5. Business Logic & Validation Policies
1. **Single Active Hold Policy:** A member cannot place multiple active holds on the same title. This is enforced at the database level:
   $$\text{uk\_active\_reservation} = (\text{book\_id}, \text{member\_id}, \text{status})$$
2. **Queue Position Calculation:** When a new hold is placed, its queue position is calculated sequentially:
   $$\text{Queue Position}_{\text{new}} = \text{Count}(\text{lib\_reservations where book\_id} = B \text{ and status = 'Pending'}) + 1$$
3. **Queue Promotion on Cancellation:** If a hold request is set to `'Cancelled'` or `'Expired'`, the system must run an automatic database trigger/event to update the queue for all subsequent pending holds:
   $$\forall R \in \text{Pending Holds} \text{ where } \text{position} > \text{position}_{\text{cancelled}}, \quad \text{position}_{\text{new}} = \text{position}_{\text{old}} - 1$$
4. **Hold Pickup Timeout:** When a book copy is checked in, the first pending reservation is updated to `'Available'`, and the pickup deadline is generated. If `today > pickup_by_date` and status is still `'Available'`, the hold is marked `'Expired'`, and the next member in the queue is notified.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Reservations tab at `/library-mgt/transactions`.

### Scenario A: Happy Path Create Hold
1. Click **"Add Reservation"**.
2. Select Book: *The Hobbit*.
3. Select Member: *Jane Doe*.
4. Verify Reservation Date defaults to today and Status defaults to "Pending".
5. Click **"Save"**.
6. **Expected Result**: Hold is registered, success banner displays, and Jane Doe is placed at Queue Position `1` in the listings.

### Scenario B: Duplicate Active Hold Block
1. Click **"Add Reservation"**.
2. Select Book: *The Hobbit* (Matches Scenario A).
3. Select Member: *Jane Doe* (Matches Scenario A).
4. Click **"Save"**.
5. **Expected Result**: Validation fails, displaying: *"Member already has an active reservation for this book."*

### Scenario C: Queue Reordering on Cancellation
1. Set up 3 reservations on *The Hobbit* (Jane Doe position 1, John Smith position 2, Bill Adams position 3).
2. Edit Jane Doe's reservation, change status to `'Cancelled'`, enter reason *"Student requested cancellation"*, and click **"Save"**.
3. **Expected Result**: Jane's hold status updates. John Smith is promoted to Queue Position `1`, and Bill Adams is promoted to Queue Position `2`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Reservations Tab)
* **Tab Selector**: `@reservations-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@reservations-tab')
            ->click('@add-reservation-btn')
            ->select('book_id', $this->hobbitBookMaster->id)
            ->select('member_id', $this->studentMember->id)
            ->press('@save-btn')
            ->assertSee('saved successfully')
            ->assertSee('Pending');
});
```

### 3. Duplicate Block Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@reservations-tab')
            ->click('@add-reservation-btn')
            ->select('book_id', $this->hobbitBookMaster->id)
            ->select('member_id', $this->studentMember->id) // Duplicate hold
            ->press('@save-btn')
            ->assertSee('Member already has an active reservation');
});
```
