# Wishlist — Business Requirements

## What This Screen Does

The Wishlist feature allows library members to save books they want to read in the future. It is a member-facing feature embedded within the Staff Library Portal — members can add books to their wishlist from the Browse Library section (both E-Books and Physical Books) and view their saved items under My Books → Wishlist. The wishlist is a simple toggle mechanism: clicking the wishlist icon on a book card adds it to or removes it from the user's wishlist. There is no dedicated admin management screen — wishlist data is visible only through the member's portal view.

The feature is backed by the `lib_wishlist` table with unique constraint per member-book pair, ensuring a member can only save each book once. Soft deletes are supported, so removing a book from the wishlist soft-deletes the record, and adding it back restores the soft-deleted record rather than creating a duplicate.

---

## When This Screen Is Used

- When a member finds a book they are interested in but not ready to borrow yet — they click the heart/wishlist icon to save it for later
- When a member wants to view all books they have saved in their personal wishlist
- When a member decides to remove a book from their wishlist — they click the heart icon again to remove it
- When a previously removed book is added back — the system restores the soft-deleted record
- When the librarian reviews popular wishlist items to inform purchase decisions (via reports or manual review)

## Default Data Load

Wishlist data is loaded as part of the Staff Library Portal's `index()` method. The member's active wishlist items (`where('is_active', true)`) are eager-loaded with their associated book data including authors, publisher, categories, and resource type. The `wishlistedBookIds` collection (plucked `book_id` values) is computed alongside and passed to the portal view to toggle the wishlist icon state (filled vs outline) for each book card. The dedicated wishlist page (`myWishlist()`) loads the full wishlist with the same eager-loaded relationships, ordered by most recently added.

---

---

## Key Fields at a Glance

**Wishlist Entry Structure**
Each wishlist record is a simple link between a `member_id` (FK to `lib_members.id`) and a `book_id` (FK to `lib_books_master.id`), with an `is_active` boolean, an optional `notes` field (varchar 255), and a `priority` level (TINYINT, default 1). The `created_at` timestamp records when the book was added to the wishlist.

**Display in Portal**
The wishlist display shows book title, cover image (via `sys_media` relationship), authors, publisher, categories, resource type, and date added. Each entry has a remove button. Soft-deleted books (where `deleted_at` is not null on the book record) still appear in the wishlist — the portal uses `withTrashed()` when loading the book relationship.

---

## Business Rules and Conditions

1. **One Wishlist Entry Per Book Per Member** — The unique constraint `uq_lib_wishlist_member_book` on (`member_id`, `book_id`) ensures a member cannot add the same book twice. If a duplicate is attempted, the system catches the `QueryException` with code `23000` and returns a 409 Conflict response.

2. **Toggle Behavior** — Adding a book that is already in the wishlist removes it (soft delete). Removing a book that was previously wishlisted and then removed restores the soft-deleted record. This ensures the unique constraint is never violated.

3. **Membership Required** — Only registered library members can use the wishlist. If `LibMember::where('user_id', auth()->id())` returns null, the system returns a 403 error: "You are not registered as a library member."

4. **Soft Deleted Books Still Visible** — The book relationship is loaded with `withTrashed()`, meaning books that have been soft-deleted from the master list still appear in the member's wishlist.

5. **Priority Field** — Each wishlist entry has a `priority` field (default 1) that members could potentially use to prioritize their reading list, though the portal currently does not expose this for editing.

6. **Activity Logging** — Every wishlist action (Create, Restore, Delete) is logged via `activityLog()` with the event type and book_id. Engagement events are also recorded using the `LibEngagementLogger` trait with event type `Save_To_Wishlist`.

7. **Database Triggers** — The FK constraint on `lib_wishlist.book_id` is `ON DELETE CASCADE`, meaning if a book is permanently deleted (force delete), all associated wishlist entries are automatically removed.

8. **Authorization** — The `toggleWishlist()` endpoint performs no explicit `Gate::authorize()` call (it relies on the membership check). The `myWishlist()` method in StaffLibraryController uses `Gate::authorize('tenant.lib-books-master.view')`.

---

## Workflow Steps

1. Member logs into the Staff Library Portal and browses books
2. Member sees a heart/wishlist icon on each book card
3. Member clicks the icon — AJAX POST to `/lib-wishlist/toggle` with `book_id`
4. System checks if the user is a registered library member
5. System checks if the book exists
6. If the book is already wishlisted (and not deleted), the record is soft-deleted
7. If the book was previously wishlisted but deleted, the record is restored
8. If no existing record, a new wishlist entry is created
9. Activity log and engagement event are recorded
10. JSON response returns success with `is_wishlisted` boolean and message
11. Portal UI toggles the heart icon (filled/outline) based on the response

---

## Example Scenario

Ms. Sharma, a Grade 9 Science teacher, logs into the Staff Library Portal. She browses Physical Books and finds a book titled "Concepts of Physics" by H.C. Verma. She clicks the heart icon — it fills in red, and a toast message says "Added to wishlist!" Later, she navigates to My Books → Wishlist and sees this book along with two others she had previously saved. She decides she no longer needs one of them, clicks the heart icon, and it is removed from the wishlist with a confirmation message. The next day, she changes her mind and adds it back — the system restores the previous entry.

---

## Related Screens

- **Staff Library Portal** — The member-facing portal where the wishlist is managed (Browse Library tab and My Books → Wishlist sub-tab)
- **Books Master** — The book catalog that wishlist entries reference
- **Members** — Member management (wishlist is member-scoped)
- **Physical Book Requests** — Members can reserve books from their wishlist
- **Digital Access Requests** — Members can request digital access from their wishlist

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibWishlistController`
**Model:** `Modules\Library\Models\LibWishlist` (table: `lib_wishlist`, uses `SoftDeletes`)
**Trait:** `LibEngagementLogger` — logs engagement events for wishlist actions
**Route:** `POST /lib-wishlist/toggle` named `lib-wishlist.toggle`
**Permission:** `tenant.lib-wishlist` (CRUD supported, but only toggle endpoint exposed)

Key controller methods:
- `toggleWishlist(Request)` — Validates `book_id` (required|integer), checks membership, creates/restores/deletes wishlist entry, logs activity, returns JSON

No dedicated index, create, edit, show, or admin management screens — wishlist functionality is entirely embedded within the Staff Library Portal.

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Registered Library Member (Teacher/Staff) | N/A (membership-gated, not permission-gated) | Use wishlist via Staff Library Portal |
| Registered Library Member (Student) | N/A (membership-gated) | Use wishlist via Student Portal (if applicable) |
| Non-Member User | N/A | Cannot access — 403 "not registered" |

---

## How This Screen Works — Logic Flow (Non-Technical)

When a member clicks the heart icon on any book in the Staff Library Portal, the system sends a quiet request to add or remove that book from the member's personal saved list. The system first checks that the person is a registered member of the library — if not, it shows a message asking them to contact the librarian. Then it checks whether this book is already in the member's saved list. If it is already there, clicking removes it. If it was removed before, clicking adds it back. If it was never saved before, a new entry is created. Each action is logged for tracking purposes, and the heart icon changes appearance immediately to show the new saved or unsaved state.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | book_id | required, integer | The book field is required. |
| 2 | book_id | exists in lib_books_master | Selected book not found. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| User is not a library member | You are not registered as a library member. | 403 |
| Book not found | Book not found. | 404 |
| Duplicate entry (race condition) | This book is already in your wishlist. | 409 |
| Database error occurred | A database error occurred. | 500 |
| General exception | Something went wrong. Please try again. | 500 |
| Add to wishlist success | Added to wishlist! | 200 |
| Remove from wishlist success | Removed from wishlist. | 200 |
| Restore to wishlist success | Added back to wishlist! | 200 |

---

## Success Scenarios

**SS-001: Add a book to wishlist**
1. Member clicks heart icon on a book card
2. System verifies member, finds no existing wishlist record
3. Creates new `LibWishlist` record with `member_id`, `book_id`, `is_active=true`
4. Logs activity "Added book to wishlist"
5. Logs engagement event `Save_To_Wishlist` with outcome "added"
6. Returns JSON: `{ status: true, is_wishlisted: true, message: "Added to wishlist!" }`
7. Heart icon fills in red on the UI

**SS-002: Remove a book from wishlist**
1. Member clicks filled heart icon on a wishlisted book
2. System finds existing active record
3. Soft-deletes the record
4. Logs activity "Removed book from wishlist"
5. Returns JSON: `{ status: true, is_wishlisted: false, message: "Removed from wishlist." }`
6. Heart icon becomes outline on the UI

**SS-003: Re-add a previously removed book**
1. Member clicks heart icon on a book they removed earlier
2. System finds existing soft-deleted record
3. Restores the record and sets `is_active=true`
4. Logs activity "Added book back to wishlist"
5. Returns JSON: `{ status: true, is_wishlisted: true, message: "Added back to wishlist!" }`

--- 

## Failure Scenarios

**FS-001: Non-member tries to add to wishlist**
1. Unregistered user clicks heart icon
2. `LibMember::where('user_id', auth()->id())` returns null
3. System returns 403: "You are not registered as a library member."
4. Heart icon does not change

**FS-002: Duplicate entry due to concurrent requests**
1. Member clicks heart icon twice rapidly
2. First request creates the record, second request tries to create another
3. Database throws `QueryException` with code 23000 (duplicate key)
4. System catches exception, returns 409: "This book is already in your wishlist."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `lib_wishlist` | Wishlist entries with member_id, book_id, notes, priority, is_active |
| FK | `member_id` | References `lib_members.id` ON DELETE CASCADE |
| FK | `book_id` | References `lib_books_master.id` ON DELETE CASCADE |
| Module | Staff Library Portal | Member-facing interface for wishlist management |
| Module | Library Members | Membership validation (must be registered) |
| Module | Library Books Master | Book catalog that wishlist entries reference |
| Trait | `LibEngagementLogger` | Engagement event logging for wishlist actions |
