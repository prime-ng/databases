# Book Reviews — Business Requirements

## What This Screen Does

The Book Reviews screen manages member-submitted ratings and reviews for library books. Members (students, faculty, staff) submit reviews through the Staff Library Portal, and librarians moderate them by approving or rejecting before they become publicly visible. The system tracks separate student and faculty ratings, which feed into the book's aggregated `student_rating` and `academic_rating` fields on the book master record. This screen is available both as a standalone index page and as a tab within the Library Operations hub.

---

## When This Screen Is Used

- When a member submits a review through the portal — it appears as pending moderation
- When the librarian wants to approve a pending review to make it publicly visible
- When the librarian needs to reject or delete inappropriate reviews
- When the librarian wants to view the full review history for a specific book or member
- When the system needs to recalculate a book's aggregated rating after a review is created, approved, or deleted

## Default Data Load

Standalone index loads all non-deleted reviews with eager-loaded `book`, `member.user`, and `approvedBy` relationships, ordered by latest first, paginated at 20 per page. Default filter shows all reviews. Status filter options: `approved` (is_approved = true), `pending` (is_approved = false). Search searches across book title, member name, and review text.

---

---

## Key Fields at a Glance

**Core Identity**
Every review belongs to one book and one member. The combination of book_id and member_id is unique — each member can submit only one review per book. The rating is a whole number from 1 to 5. The review text is optional, up to 5000 characters, allowing members to write detailed feedback.

**Moderation State**
The `is_approved` boolean controls visibility: approved reviews are publicly visible, while unapproved (pending or rejected) reviews are hidden. The `approved_by_id` and `approved_at` fields track who moderated the review and when. The `is_active` boolean provides an additional visibility toggle independent of approval status.

**Faculty vs Student**
The `is_faculty` flag distinguishes faculty reviews from student reviews. The system uses this flag when calculating separate aggregated ratings on the book master — `student_rating` is the average of non-faculty reviews, while `academic_rating` is the average of faculty reviews. Both are recalculated on every review create, update, approve, reject, or delete.

**Transaction Link**
An optional `transaction_id` FK links the review to the specific borrowing transaction that led to the review, enforcing the rule that only members who have borrowed or accessed a book can review it.

---

## Business Rules and Conditions

**Unique Constraint**
A member cannot submit more than one review for the same book. The unique key `uq_lib_bookReview_member_book` (`book_id`, `member_id`) enforces this at the database level.

**Transaction Requirement**
The `transaction_id` FK enforces that only members who have actually borrowed or accessed a book can leave a review. Reviews without a transaction are allowed for librarian override, but the FK references `lib_transactions.id` with `ON DELETE SET NULL`.

**Rating Recalculation**
Every create, update, approve, reject, delete, restore, and force-delete triggers the private `recalculateBookRating()` method, which computes separate student and faculty rating averages and updates `lib_books_master.student_rating`, `academic_rating`, and `rating_count`.

**Moderation Workflow**
Reviews created by members through the Staff Library Portal default to `is_approved = false` (pending). Librarians approve or reject via dedicated endpoints. Reviews created directly by librarians in the admin panel default to `is_approved = true`.

**Approval State Transitions**
- Pending (is_approved = false, approved_by_id = null) → Approved (is_approved = true, approved_by_id set, approved_at set)
- Pending → Rejected (is_approved = false, is_active = false, approved_by_id set, approved_at set)
- Approved → Rejected (possible via update with is_approved = false)
- Rejected → Approved (possible via approve method)

---

## Workflow Steps

**Submitting a Review (Member Portal)**
The member logs into the Staff Library Portal, finds a book they have borrowed or accessed, and submits a rating and optional review text. The system creates a review with `is_approved = false` (pending) and logs an engagement event of type `Add_Review`.

**Moderating a Review (Librarian)**
The librarian navigates to Book Reviews and sees pending reviews. They read the review text and rating, then click Approve (sets is_approved = true, is_active = true) or Reject (sets is_approved = false, is_active = false). The system recalculates the book's aggregated ratings after each action.

**Admin Creating a Review**
The librarian can also create reviews directly through the admin create form, selecting the member, book, rating, and optionally setting approval status. Reviews created by admins default to approved.

---

## Example Scenario

A Grade 11 student borrows "A Brief History of Time" from the library. After reading it, the student logs into the Staff Library Portal, rates the book 5 stars, and writes a review: "An incredible journey through cosmology — Stephen Hawking makes complex ideas accessible." The review appears in the Book Reviews screen as pending. The Librarian Admin reads the review, finds it appropriate, and clicks Approve. The system sets `is_approved = true`, updates `approved_by_id` and `approved_at`, recalculates the student rating average (now including this 5-star review), and the review becomes visible on the book's detail page. Later, a faculty member also submits a review with `is_faculty = true`, which updates the `academic_rating` separately.

---

## Related Screens

- **Books Master** — The `student_rating`, `academic_rating`, and `rating_count` fields are populated from approved reviews
- **Staff Library Portal** — Members submit reviews through the portal; reviews appear on book detail pages
- **Engagement Events** — Submitting a review logs an `Add_Review` engagement event
- **Transactions** — Reviews are optionally linked to borrowing transactions via `transaction_id`

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibBookReviewController`
**Model:** `Modules\Library\Models\LibBookReview` (table: `lib_book_reviews_ratings`)
**Requests:** Inline `$request->validate()` in store/update
**Policy:** `LibBookReviewPolicy` (permissions match `tenant.lib-book-reviews.*` group in permissionslist.php)
**Route:** Resource route `Route::resource('lib-book-reviews', LibBookReviewController::class)` + trashed/restore/forceDelete/toggleStatus/approve/reject

Key controller methods:
- `index()` — Lists reviews with search and status filter (approved/pending), paginated at 20 per page
- `create()` — Loads active books and members; returns create view
- `store(Request)` — Validates and creates review; recalculates book rating; logs activity
- `edit($id)` — Loads single review for editing
- `update(Request, $id)` — Validates and updates review; recalculates book rating
- `destroy($id)` — Soft-deletes review; recalculates book rating; supports AJAX response
- `trashed()` — Lists soft-deleted reviews
- `restore($id)` — Restores soft-deleted review; recalculates book rating
- `forceDelete($id)` — Permanently deletes; recalculates book rating
- `toggleStatus($id)` — Toggles `is_active` boolean via AJAX; uses `.update` permission; recalculates rating
- `approve($id)` — Sets is_approved=true, is_active=true, records who approved; logs activity; supports AJAX
- `reject($id)` — Sets is_approved=false, is_active=false, records who rejected; logs activity; supports AJAX
- `recalculateBookRating(int $bookId)` — Private method that computes separate student/faculty avg ratings and updates `lib_books_master`

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — all CRUD + approve/reject/toggle + trash |
| Librarian Admin | Approve, reject, delete, edit, create reviews |
| Librarian Operator | View and moderate reviews (approve/reject) |
| Librarian (view only) | View reviews only |

All access is gated by `Gate::authorize('tenant.lib-book-reviews.{action}')`. ToggleStatus uses `.update` permission.

---

## How This Screen Works — Logic Flow (Non-Technical)

The main Book Reviews screen shows a table of all reviews. Each row shows the member name, book title, rating (1–5 stars), a preview of the review text, and the moderation status (Approved/Pending/Rejected). The librarian can search by member name, book title, or review text, and filter by status. Each pending review has Approve and Reject buttons. Clicking Approve makes the review visible on the book's detail page and updates the book's average rating. Clicking Reject hides the review permanently. The librarian can also edit or delete reviews directly. Every moderation action (approve/reject/delete) triggers a recalculation of the book's student and faculty ratings to keep them accurate in real time.

---

## Validate Before Save

**Create / Update (`store()` and `update()` methods):**
1. **`book_id`:** required, must exist in `lib_books_master.id`
2. **`member_id`:** required, must exist in `lib_members.id`
3. **`rating`:** required, integer, min:1, max:5
4. **`review_text`:** nullable, string, max:5000
5. **`is_faculty`:** nullable, boolean
6. **`is_approved`:** nullable, boolean (defaults to `true` on admin create, `false` on portal submission)

**Unique Constraint (DB level):** The unique key `uq_lib_bookReview_member_book` (`book_id`, `member_id`) prevents duplicate reviews.

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Book not found | "The selected book is invalid." (from `exists` validation) |
| Member not found | "The selected member is invalid." |
| Duplicate review | "This member has already submitted a review for this book." (MySQL unique constraint) |
| Rating out of range | "Rating must be between 1 and 5." |
| Review text too long | "Review text cannot exceed 5000 characters." |
| Invalid action on deleted review | 404 error if review is soft-deleted and not found |

---

## Success Scenarios

1. A member submits a 4-star review for "To Kill a Mockingbird" through the portal. The review appears as pending in the Book Reviews screen. The librarian approves it, and the book's average rating is recalculated.
2. A librarian creates a review directly for a new book that hasn't been borrowed yet (no member review), setting the rating to 5 and marking it as faculty review. The book's `academic_rating` is updated.
3. A librarian deletes an inappropriate review via AJAX. The system soft-deletes it and recalculates the book's rating, removing that review's contribution.

---

## Failure Scenarios

1. A member tries to submit a second review for the same book. The database unique constraint rejects the duplicate, and the system returns a validation error.
2. A librarian tries to approve an already-deleted review. The model's `findOrFail` throws a 404 error.
3. The recalculation query fails due to a database connection issue. The review is created but the book's ratings are not updated; the system logs the error and the librarian must manually trigger recalculation.

---

## Dependencies module and tables

| Module | Tables |
|---|---|
| Library Core | `lib_book_reviews_ratings` (primary, soft-deletes via `deleted_at`) |
| Library Books | `lib_books_master` (FK `book_id` CASCADE; `student_rating`, `academic_rating`, `rating_count` updated on events) |
| Library Members | `lib_members` (FK `member_id` CASCADE) |
| Library Transactions | `lib_transactions` (FK `transaction_id` SET NULL) |
| User / Auth | `sys_users` (FK `approved_by_id` SET NULL) |
| Staff Portal | Member-facing review submission via `submitReview()` in `StaffLibraryController` |
