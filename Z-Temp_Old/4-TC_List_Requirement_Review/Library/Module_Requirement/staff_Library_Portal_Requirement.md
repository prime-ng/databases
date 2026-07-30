# Staff Library Portal — Business Requirements

## What This Screen Does

The Staff Library Portal is the member-facing self-service interface for library members (teachers, staff, employees, admin) to browse the collection, borrow physical books, access digital resources, track issued items, manage reservations, submit renewal requests, write reviews, and maintain a personal wishlist. It is **not** an admin CRUD panel — every action is user-initiated and self-service, with librarian approval required for most fulfillment steps (issuing, renewal approval, digital access approval).

The portal is gated by library membership: a user must be registered as a `LibMember` with an active `membership_type_id` in `lib_members`. If no member record exists, the portal renders a blocked state with "You are not authorized to view the library. Please contact the librarian to become a member." Additionally, the portal only serves logged-in users whose `user_type` is one of: `teacher`, `faculty`, `staff`, `employee`, `admin`, `super-admin`. All other user types (e.g., `student`, `guardian`) receive a 403 on all POST actions.

The portal consists of two main tabs — **Browse Library** (E-books + Physical Books sub-tabs) and **My Books** (Currently Issued, Overdue, Borrowing History, Reservations, Digital Requests, Wishlist) — plus a **Book Details** view, a **Wishlist** page, and **Review** submission. Every browsing action logs engagement via `LibEngagementLogger`.

---

## When This Screen Is Used

- When a teacher wants to search and browse available books (physical or digital) by title, author, ISBN, or category
- When a staff member wants to reserve a physical book for pickup
- When a teacher wants to request access to view or download an e-book
- When a member wants to see currently borrowed books, due dates, and overdue items
- When a member wants to submit a renewal request for an issued book
- When a member wants to cancel a pending digital access request or physical reservation
- When a member wants to view/download an approved digital resource (with license and access restriction checks)
- When a member wants to write a book review (requires librarian approval before public visibility)
- When a member wants to add/remove books from their personal wishlist

## Default Data Load

The portal opens at `library/staff-library` with `tab=library` and `sub=ebooks` as defaults. The `StaffLibraryController@index()` loads all data in a single request:

- **Member check**: `LibMember::where('user_id', auth()->id())` — if null, all collections are empty paginators and the view shows a "not a member" message
- **Categories**: Top-level active categories for filter dropdown (`parent_category_id IS NULL`, ordered by `display_order`, then `name`)
- **E-Books**: `LibBookMaster` with `resourceType.is_digital = true`, filtered by active status, access restrictions (`LibDigitalResourceAccessRestriction`), search query (`?q=`), and category filter (`?cat=`). Paginated 12 per page with paginator name `ep`. Restricted members (`can_restricted_members_view_list = 1`) see no books (`WHERE 0=1`)
- **Physical Books**: `LibBookMaster` with `resourceType.is_physical = true`, same restriction logic, paginated 12 per page with paginator name `pp`
- **My Access Requests**: Active digital access requests for the member, mapped by `book_id => status`
- **My Reservations**: Active physical book requests for the member (statuses: pending, available, Picked_Up, Approved)
- **Issued Books**: `LibTransaction` where `status = issued` for the member, ordered by `due_date`
- **Overdue**: Issued transactions where `due_date < now()`
- **History**: Returned/lost transactions, paginated 10 per page with paginator name `page`
- **Stats**: `total_books_borrowed`, `active` (currently issued count), `overdue` count, `outstanding_fines` amount
- **Renewal Requests**: Physical book requests where `is_renewal_request = true`
- **Wishlist**: Active wishlist items with book relations

The `showBook($id)` method loads a single book with authors, categories, publisher, resource type, language, digital resources, physical copies (with shelf location, condition, status), approved reviews, related books (same category, limit 6), and the member's existing review/access request/reservation for that book.

---

## Key Fields at a Glance

### Member Identity and Membership
The portal identifies the user via `auth()->id()` and looks up their `LibMember` record. The member record ties to a `LibMembershipType` which governs all borrowing rules: `max_books_allowed` (maximum simultaneously issued), `loan_period_days` (standard loan duration), `renewal_allowed` (boolean), `max_renewals` (limit), `digital_access_days` (digital access validity period after approval), `can_restricted_members_view_list` (whether the member sees the book list), `grace_period_days`, and `priority_level` (for reservation queuing). The member's `is_suspended` flag and `outstanding_fines` balance are checked on every action.

### Book Representation
Every book (physical or digital) is stored in `LibBookMaster` with `is_active`, `is_available`, and `is_reference_only` flags. Books are classified by `LibResourceType` which has `is_physical` and `is_digital` booleans determining which tab they appear in. Physical books have associated `LibBookCopy` records (each with `status`, `shelfLocation`, `current_condition`). Digital books have associated `LibDigitalResource` records with `file_name`, `file_path`, `mime_type`, `license_type`, `license_count` (concurrent user limit), `license_start_date`, `license_end_date`, and download permission booleans (`can_teacher_download`, `can_staff_download`).

### Reservation and Request Tracking
Physical reservations are stored in `LibPhysicalBookRequest` with fields: `book_id`, `member_id`, `request_date`, `status` (FK to `LibLibraryStatusMaster` — values: pending, available, Picked_Up, cancelled, withdrawn, expired), `queue_position` (auto-calculated), `is_renewal_request` flag, `renewal_days_requested`, and `withdrawal_reason`. Digital access requests are in `LibDigitalAccessRequest` with statuses: pending, approved, rejected, withdrawn, and `request_type` FK to `LibDigitalAccessRequestType` (codes: Download, View_Online, Stream, Offline, Extended).

### Issue and Transaction Details
`LibTransaction` tracks all physical book issues: `book_id`, `copy_id`, `member_id`, `issue_date`, `due_date`, `return_date`, `status` (issued, returned, overdue, lost), `is_renewed`, `renewal_count`, and `is_fine_applicable`. Overdue status is computed from comparing `due_date` against `now()`. `LibTransactionHistory` logs every state change with `old_value_json` and `new_value_json`.

---

## Business Rules and Conditions

### Membership Validation Chain (All Actions)
1. User must have a `LibMember` record for the authenticated `user_id` — checked via `getMember()` in every method
2. Member must have a valid `membershipType` relation — if null, action is blocked
3. Member's `is_suspended` flag must be false — `requestDigitalAccess()` checks this explicitly
4. Member's user type must be teacher, faculty, staff, employee, admin, or super-admin — `abort_unless()` check on all POST actions
5. Member's `membershipType.can_restricted_members_view_list = 1` hides the book list entirely (`WHERE 0=1` applied to queries when `memberCanViewList` is false)
6. Member's `membershipType.digital_access_days == 0` blocks all digital access requests

### Physical Book Reservation Rules (`reservePhysical`)
- Book must not be `is_reference_only` — reference-only books cannot be reserved
- Current issued + overdue count must be less than `membershipType.max_books_allowed` — if reached, "You have reached the maximum borrow limit"
- No duplicate active reservation allowed on the same book
- Resource type compatibility: if the book's resource type is digital-only with `digital_access_days == 0`, the reservation is blocked
- Queue position is auto-calculated as count of existing pending reservations + 1
- `expected_available_date` is set to `now()->addDays(30)` as a default estimate

### Digital Access Request Rules (`requestDigitalAccess`)
- Digital resource must exist and be active (`is_active = true`)
- Member-type download permission checked via `can_teacher_download` / `can_staff_download` match on the user_type
- Access restrictions (`LibDigitalResourceAccessRestriction`) checked if present — user must match on user_id, role_id, designation_id, or department_id
- Resource type compatibility: physical-only books cannot have digital access requests; if the book is digital-only but `membershipType.digital_access_days == 0`, access is blocked
- No duplicate active request allowed — checked via DB unique constraint and explicit query
- Request type defaults to 'Download' if not specified, falling back to any active type or ID 1
- On success, a `LIBRARY_DIGITAL_ACCESS_REQUESTED` notification is created

### Renewal Rules (`renewBook`)
- Transaction must belong to the authenticated member
- Transaction status must be 'issued' or 'overdue' — returned/lost books cannot be renewed
- Book must be available (`is_available = true`)
- Membership type must allow renewal (`renewal_allowed = true`)
- `renewal_count` must be less than `membershipType.max_renewals`
- No pending reservations from other members on the same book — if another member is waiting, renewal is blocked
- No existing pending renewal request on the same transaction — duplicate prevention
- Days requested defaults to `membershipType.loan_period_days`, clamped between 1 and `membershipType.loan_period_days`
- A `LibPhysicalBookRequest` with `is_renewal_request = true` is created with `status = pending`
- `LibTransactionHistory` is created logging the old and new state with `action = 'renewal_requested'`

### Digital Resource Access (Download/View) Rules (`downloadResource`, `viewResource`)
- Member must have an approved `LibDigitalAccessRequest` for the book
- The approved request's `mapRequestTypeToAccessType()` must return 'Download' (for download) or 'Read_Online' (for view)
- `digital_access_days` expiry is computed from `reviewed_at + digital_access_days` — if expired, access is denied
- License period checked: `license_start_date` must be ≤ today and `license_end_date` must be ≥ today
- Access restrictions re-checked against the specific digital resource
- Concurrent license limit checked: if `license_count` is not null, count active `LibDigitalAccessTransaction` records — if >= license_count, "Concurrent license limit reached"
- File resolved from `media->getPath()` or `file_path` in storage — if missing, returns error
- View count and download count incremented; `trackDigitalAccess()` creates/updates `LibDigitalAccessTransaction`

### Book Review Rules (`submitReview`)
- One review per book per member — duplicate blocked with "You have already reviewed this book"
- Rating is required, integer 1-5
- Review text is optional, max 5000 characters
- Review is created with `is_faculty = true` and `is_approved = false` — requires librarian approval before appearing publicly
- Activity logged via `activityLog()`

### Cancel Request Rules (`cancelRequest`)
- Supports two types: `type=digital` (cancels `LibDigitalAccessRequest`) and `type=physical` (cancels `LibPhysicalBookRequest`)
- Digital requests must be in 'pending' status to cancel — status changed to 'withdrawn'
- Physical requests use `withdraw('Cancelled by staff')` — status changed to 'withdrawn'
- A notification (`LIBRARY_DIGITAL_ACCESS_WITHDRAWN`) is created for digital cancellations

### Wishlist Rules
- Toggle via `LibWishlistController@toggleWishlist` (separate route `/lib-wishlist/toggle`)
- Active wishlist items (`is_active = true`) are displayed
- Book relations include soft-deleted books (`withTrashed()`)

### Engagement Logging
- Every major action logs via `LibEngagementLogger` trait: `logEngagement('Browse')`, `logEngagement('View_Details', $bookId)`, `logEngagement('Search', null, null, $query)`, `logEngagement('Digital_View', $bookId, $resourceId)`, `logEngagement('Add_Reservation', $bookId)`, `logEngagement('Renew_Online', $bookId)`, `logEngagement('Cancel_Reservation', $bookId)`, `logEngagement('Download', $bookId, $resourceId)`, `logEngagement('View_Online', $bookId, $resourceId)`, `logEngagement('Add_Review', $bookId)`

---

## Workflow Steps

**Browsing and Filtering**
1. User navigates to Library → Staff Library Portal
2. System checks LibMember record — if absent, shows "not a member" message and stops
3. System loads Browse Library tab (default) with E-Books sub-tab active
4. User can switch to Physical Books sub-tab
5. User can type a search query, select a category filter, or click "Available Only" (physical search)
6. System sends AJAX search via `physicalSearch()` for physical books, returning HTML card partials
7. Each book card shows title, author(s), category, cover image, availability badge, and action buttons (Reserve, Request Access, View Details)

**Reserving a Physical Book**
1. User clicks "Reserve" on a physical book card
2. System validates membership, max books limit, duplicate reservation, reference-only flag, and resource type compatibility
3. System creates `LibPhysicalBookRequest` with `status = pending`, auto-calculates `queue_position`
4. System logs engagement and returns success JSON: "You will be notified when this book becomes available."
5. Librarian processes the reservation via admin interface — marks as available when copy is ready

**Requesting Digital Access**
1. User clicks "Request Access" on an e-book card
2. System validates membership, suspended status, restricted member flag, digital_access_days, resource type compatibility, download permissions, and access restrictions
3. User enters a reason (required, max 500 chars) and optionally selects request type
4. System creates `LibDigitalAccessRequest` with `status = pending`
5. System creates `LIBRARY_DIGITAL_ACCESS_REQUESTED` notification
6. Librarian approves or rejects via admin interface
7. If approved, user can view or download from the approved request

**Renewing a Book**
1. User goes to My Books → Currently Issued
2. User clicks "Renew" on an issued or overdue book
3. System validates membership type renewal settings, renewal count limit, and pending reservations from other members
4. System creates a renewal `LibPhysicalBookRequest` with `is_renewal_request = true`
5. System logs transaction history with old/new state
6. Librarian approves or rejects the renewal request via admin interface

**Writing a Review**
1. User opens a book's detail page (from Browse Library)
2. User clicks "Write Review"
3. User selects a rating (1-5 stars) and optionally writes review text
4. System validates no existing review from this member on this book
5. System creates `LibBookReview` with `is_faculty = true`, `is_approved = false`
6. Librarian approves or rejects the review before it appears publicly

**Cancelling a Request**
1. User goes to My Books → Digital Requests or Reservations
2. User clicks "Cancel" on a pending request
3. For digital: status changes to 'withdrawn', notification created
4. For physical: `withdraw('Cancelled by staff')` called, status changes to 'withdrawn'

**Viewing/Downloading a Digital Resource**
1. User clicks "View" or "Download" on an approved digital access item
2. System verifies approved access request, expiry date, license period, access restrictions, and concurrent license limit
3. System increments view/download count and tracks via `LibDigitalAccessTransaction`
4. File is served inline (view) or as download attachment

---

## Example Scenario

Ms. Sharma, a Grade 10 Science teacher, has been a library member for two years with a "Premium Staff" membership type (max 8 books, 30-day loan period, 3 renewals allowed, 90-day digital access). She logs into the Staff Library Portal to find resources for her upcoming unit on Climate Change.

She searches "climate change" in the Browse Library tab. The system shows 12 e-books and 6 physical books. She spots "Climate Change: A Comprehensive Guide" — a physical book with 1 of 3 copies available. She clicks Reserve. The system checks that she currently has only 2 books issued (below her 8-book limit), finds no existing reservation for this book, and creates a pending reservation at queue position 1. She sees the success message.

She also finds an e-book "Global Warming Science" and clicks Request Access, writing "Need this for lesson planning next week". The system verifies her membership allows digital access (90 days), her user type (teacher) has download permission, and no restrictions apply. The request is submitted as pending.

Two days later, the librarian approves her digital request. Ms. Sharma receives an in-app notification. She goes to My Books → Digital Access, clicks Download, and the system verifies the license period is valid (the school's site license allows unlimited concurrent access), then serves the PDF.

Meanwhile, her renewal request for "Physics Textbook Vol 1" (due in 3 days) is still pending — another teacher has reserved it, so the renewal will be rejected. She sees this in My Books → Currently Issued.

---

## Related Screens

- **Library Members** (`lib-members`) — Admin screen where members are registered; portal requires a LibMember record to function
- **Library Books Master** (`lib-books-master`) — Admin CRUD for book catalog; portal consumes book data for browsing
- **Library Digital Resources** (`lib-digital-resources`) — Admin upload/manage of digital files; portal serves view/download
- **Library Digital Access Requests** (`lib-digital-access-requests`) — Admin approval/rejection of access requests submitted via portal
- **Library Physical Book Requests** (`lib-physical-book-requests`) — Admin management of reservations and renewal requests
- **Library Transactions** (`lib-transactions`) — Admin issue/return processing; portal reads issued book status
- **Library Book Reviews** (`lib-book-reviews`) — Admin approval of reviews submitted via portal
- **Library Wishlist** (`lib-wishlist`) — Toggle endpoint for wishlist items
- **Library Membership Types** (`lib-membership-types`) — Configures rules (max books, loan period, renewals, digital access days)
- **Library Digital Resource Access Restrictions** (`lib-digital-resource-access-restrictions`) — Defines role/user/designation/department level restrictions on digital resources

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\StaffLibraryController` (1146 lines, 12 public methods + `trackDigitalAccess` private helper)

**Model(s):**
- `LibMember` (`lib_members`) — member identity, membership type, suspension, fines, engagement stats
- `LibBookMaster` (`lib_books_master`) — book catalog with `is_reference_only`, `is_available`, `is_active`
- `LibBookCopy` (`lib_book_copies`) — physical copies with status, shelf location, condition
- `LibDigitalResource` (`lib_digital_resources`) — digital files with license, permissions, access restrictions
- `LibPhysicalBookRequest` (`lib_physical_book_requests`) — reservations and renewal requests
- `LibDigitalAccessRequest` (`lib_digital_access_requests`) — digital access requests with request type mapping
- `LibDigitalAccessRequestType` (`lib_digital_access_request_types`) — codes: Download, View_Online, Stream, Offline, Extended
- `LibTransaction` (`lib_transactions`) — issue/return records with status, due dates, renewal count
- `LibTransactionHistory` (`lib_transaction_histories`) — audit log of transaction state changes
- `LibDigitalAccessTransaction` (`lib_digital_access_transactions`) — tracks active digital access sessions with download/view history
- `LibDigitalResourceAccessRestriction` (`lib_digital_resource_access_restrictions`) — per-user/role/designation/department restrictions
- `LibBookReview` (`lib_book_reviews`) — member reviews with `is_approved`, `is_faculty` flags
- `LibWishlist` (`lib_wishlists`) — member wishlist items with `is_active` flag
- `LibMembershipType` (`lib_membership_types`) — policy rules (max_books, loan_period, renewals, digital access days)
- `LibCategory` (`lib_categories`) — hierarchical categories for filter dropdown
- `LibLibraryStatusMaster` (`lib_library_status_masters`) — dynamic status codes for all entity statuses
- `LibEngagementEvent` (`lib_engagement_events`) — engagement log entries

**Route Group:** `Route::prefix('staff-library')->name('staff-library.')` under module prefix — 12 routes total:
- `GET /` → `index` (main portal)
- `GET /my-issues` → `myIssues` (redirects to `tab=my-books`)
- `GET /book/{id}` → `showBook`
- `GET /physical/search` → `physicalSearch` (AJAX)
- `POST /digital/request` → `requestDigitalAccess` (AJAX)
- `POST /reserve` → `reservePhysical` (AJAX)
- `POST /renew/{id}` → `renewBook` (AJAX)
- `POST /request/{id}/cancel` → `cancelRequest` (AJAX)
- `GET /digital/{resource}/download` → `downloadResource`
- `GET /digital/{resource}/view` → `viewResource`
- `GET /my-wishlist` → `myWishlist`
- `POST /submit-review` → `submitReview` (AJAX)

**Permissions Required (per method):**
| Method | Permission |
|---|---|
| `index()` | `tenant.lib-books-master.viewAny` |
| `myIssues()` | `tenant.lib-books-master.viewAny` |
| `showBook()` | `tenant.lib-books-master.view` |
| `physicalSearch()` | `tenant.lib-books-master.view` |
| `requestDigitalAccess()` | `tenant.lib-digital-access-requests.create` |
| `reservePhysical()` | `tenant.lib-physical-book-requests.create` |
| `renewBook()` | `tenant.lib-transactions.update` |
| `cancelRequest()` | `tenant.lib-physical-book-requests.update` |
| `downloadResource()` | `tenant.lib-digital-resources.view` |
| `viewResource()` | `tenant.lib-digital-resources.view` |
| `myWishlist()` | `tenant.lib-books-master.view` |
| `submitReview()` | `tenant.lib-book-reviews.create` |

**Validation Rules (per action):**

`requestDigitalAccess()`:
- `book_id` → required, integer, exists:lib_books_master,id
- `digital_resource_id` → nullable, integer, exists:lib_digital_resources,id
- `reason` → required, string, max:500
- `request_type` → nullable, integer, exists:lib_digital_access_request_types,id

`reservePhysical()`:
- `book_id` → required, integer, exists:lib_books_master,id
- `type` → required, in:reserve,notify

`renewBook()`:
- `days` → optional, integer (min:1, max:membershipType.loan_period_days via server-side clamp)

`submitReview()`:
- `book_id` → required, exists:lib_books_master,id
- `rating` → required, integer, min:1, max:5
- `review_text` → nullable, string, max:5000

**ActivityLog Events:**
- `submitReview()` → `activityLog($review, 'Created', ['message' => 'Staff submitted a book review.', ...])`

**Engagement Logging:** All methods except `myWishlist()` and `myIssues()` call `$this->logEngagement()` with action type: Browse, View_Details, Search, Browse, Digital_View, Add_Reservation, Renew_Online, Cancel_Reservation, Download, View_Online, Add_Review

---

## Who Can Access This Screen

| Role | Permission(s) | Access Level |
|---|---|---|
| Teacher (registered member) | `tenant.lib-books-master.viewAny`, `.view` + action-specific permissions | Full portal access — browse, reserve, request digital, renew, review, wishlist |
| Staff (registered member) | Same as Teacher | Full portal access — same capabilities |
| Employee (registered member) | Same as Teacher | Full portal access — same capabilities |
| Admin / Super Admin (registered member) | Same as Teacher + bypass all policy gates via `Gate::before` | Full portal access + override restrictions |
| Librarian / Library Admin (registered member) | Same as Teacher | Full portal access |
| Unregistered user (no LibMember record) | N/A | Blocked — "You are not authorized to view the library" message displayed |
| Student | N/A | Blocked at POST level — `abort_unless()` checks user_type; excluded from portal by design |
| Guardian / Other user types | N/A | Cannot access portal |
| Restricted member (`can_restricted_members_view_list = 1`) | Same as Teacher but `memberCanViewList = false` | Can access portal but sees empty book lists — card grid shows no results |

---

## How This Screen Works — Logic Flow (Non-Technical)

When a teacher opens the Staff Library Portal, the system first checks whether they are registered as a library member. If not, a message asks them to visit the librarian. If they are a member, the system loads two parallel views: the **Browse Library** section showing e-books and physical books in card grids, and the **My Books** section summarizing their borrowing activity. The Browse Library tab displays a category filter dropdown (top-level categories only) and a search box. As the teacher types, the physical books are searched via AJAX without reloading the page. E-books and physical books each have 12 items per page with pagination. Each book card shows the cover, title, author(s), and action buttons. Clicking a book opens a full detail page showing publisher, categories, all physical copies with shelf locations and availability, related books from the same category, approved reviews, and the member's reservation/access status. From the detail page or card, the teacher can reserve a physical book (which creates a pending request in the queue), request digital access (which sends a request to the librarian), add to wishlist, or write a review (which awaits librarian approval). The My Books tab shows live counts of currently issued books, overdue items, and outstanding fines. Each sub-tab lists the relevant records with action buttons — renew on issued books, cancel on pending reservations/requests, view/download on approved digital access items. The system enforces all borrowing rules at the moment of each action: max books limit, renewal limits, duplicate prevention, license concurrency, access restrictions, and membership validity.

---

## Validate Before Save

| # | Action | Field | Rule | Error Message |
|---|---|---|---|---|
| 1 | Digital Access Request | book_id | Required, exists:lib_books_master,id | The book ID is required and must exist. |
| 2 | Digital Access Request | digital_resource_id | Nullable, exists:lib_digital_resources,id | The selected digital resource is invalid. |
| 3 | Digital Access Request | reason | Required, string, max:500 | Reason is required and must not exceed 500 characters. |
| 4 | Digital Access Request | request_type | Nullable, exists:lib_digital_access_request_types,id | The selected request type is invalid. |
| 5 | Reserve Physical | book_id | Required, exists:lib_books_master,id | The book ID is required and must exist. |
| 6 | Reserve Physical | type | Required, in:reserve,notify | The reservation type must be either reserve or notify. |
| 7 | Submit Review | book_id | Required, exists:lib_books_master,id | The book ID is required and must exist. |
| 8 | Submit Review | rating | Required, integer, min:1, max:5 | Rating must be between 1 and 5. |
| 9 | Submit Review | review_text | Nullable, string, max:5000 | Review text must not exceed 5000 characters. |

Additionally, server-side validation checks (not in FormRequest but inline in controller):
- Members must have an active LibMember record
- Member must not be suspended
- Member must have a valid membershipType relation
- Current issued count must be < max_books_allowed
- No duplicate active reservation/request on same book
- Book must not be reference-only
- Resource type must match (physical vs digital)
- Digital download permission must be granted for user's user_type
- Access restrictions must be satisfied
- License period must be valid
- Concurrent license limit must not be exceeded

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Not a library member (any action) | You are not registered as a library member. Please contact the librarian. | 403 (abort) or flash message on index |
| User type not authorized (POST actions) | Unauthorized access to staff portal. | 403 (abort) |
| No membership type assigned | No membership type assigned. Please contact the librarian. | 403 (JSON) |
| Member suspended | Your library membership is suspended. You cannot request digital access. | 403 (JSON) |
| Restricted member cannot view list | (Books query returns empty — cards not rendered) | — |
| Digital access not allowed by membership type | Your membership type does not allow digital access. | 403 (JSON) |
| Digital access days = 0 for digital resource | Your membership type ({name}) does not allow accessing {resource_type} resources. | 403 (JSON) |
| Max books limit reached | You have reached the maximum borrow limit. Cannot reserve more books. | 400 (JSON) |
| Duplicate reservation | You already have an active reservation for this book. | 409 (JSON) |
| Duplicate digital request | You already have an active request for this book. | 409 (JSON) |
| Reference-only book | This is a reference-only book and cannot be reserved. | 400 (JSON) |
| Resource type mismatch | This book ({title}) is a physical-only resource. Digital access requests are not applicable. | 400 (JSON) |
| No digital resources available | No digital resources are currently available for this book. | 404 (JSON) |
| Digital resource inactive | Selected digital resource is not available. | 403 (JSON) |
| Download permission denied | Your member type does not have permission to access this resource. | 403 (JSON) |
| Access restriction denied | You are restricted from accessing this digital resource. Please contact the librarian for assistance. | 403 (JSON) |
| Digital access expired | Your digital access has expired ({days} days from approval). Please request access again. | 302 (redirect with flash) |
| License not started | The license for this digital resource has not started yet. | 302 (redirect with flash) |
| License expired | The license for this digital resource has expired. | 302 (redirect with flash) |
| Concurrent license limit | Concurrent license limit reached ({count} concurrent users). | 302 (redirect with flash) |
| Book unavailable for renewal | This book is currently marked as unavailable. Renewal cannot be processed. | 400 (JSON) |
| Transaction not found or wrong member | Transaction not found. | 404 (JSON) |
| Only issued/overdue can renew | Only issued or overdue books can be renewed. | 400 (JSON) |
| Renewal not allowed by membership | Renewal is not allowed for your membership type. | 400 (JSON) |
| Max renewals reached | Maximum renewals ({max}) reached for this book. | 400 (JSON) |
| Another member has pending reservation | Another member has reserved this book. Renewal is not possible. | 400 (JSON) |
| Duplicate renewal request | A renewal request is already pending for this book. Please wait for librarian approval. | 400 (JSON) |
| Request not found for cancellation | Request not found or cannot be cancelled. | 404 (JSON) |
| Duplicate review | You have already reviewed this book. | 422 (JSON) |
| File missing from server | The digital resource file is missing from the server. Please contact the librarian. | 302 (redirect with flash) |
| Digital resource not found (download/view) | 404 abort | 404 |

---

## Success Scenarios

**SC-001: Member browses, reserves, and accesses a digital book**
1. Ms. Sharma logs in and opens the Staff Library Portal
2. System checks her LibMember record (Premium Staff, 8 books max, 30-day loan, 3 renewals, 90-day digital access, not suspended)
3. She sees the Browse Library tab with 22 e-books and 14 physical books in card grids
4. She searches "climate change" — the system filters both e-books and physical books
5. She clicks "Climate Science Today" e-book and clicks "Request Access" with reason "Need for lesson planning"
6. System validates membership, digital access days (90 > 0), download permission (can_teacher_download = true), no access restrictions — creates pending request
7. System returns success: "Access request submitted. The librarian will review and notify you."
8. She also reserves "Climate Change: A Comprehensive Guide" physical book
9. System validates max books (2 current + 1 = 3 < 8), no duplicate, not reference-only — creates reservation at queue position 1
10. System returns success: "You will be notified when this book becomes available."

**SC-002: Member renews an issued book**
1. Mr. Patel has "Introduction to Physics" issued, due in 5 days, with 1 renewal remaining
2. He goes to My Books → Currently Issued and clicks Renew
3. System checks membership renewal_allowed = true, renewal_count (1) < max_renewals (3), no pending reservations from others
4. System creates a renewal request with `is_renewal_request = true`, `renewal_days_requested = 14` (default loan period)
5. System logs transaction history
6. Returns success: "Renewal request submitted! A librarian will review it. (14 days requested)"

**SC-003: Member views/downloads an approved digital resource**
1. Ms. Sharma's digital access request was approved 2 days ago (90-day digital access period)
2. She goes to My Books → Digital Access and clicks Download on "Climate Science Today"
3. System verifies approval, checks access expiry (88 days remaining), license period (valid), no restrictions, unlimited concurrent license
4. System increments download count, tracks via LibDigitalAccessTransaction
5. File is served as download attachment

**SC-004: Member writes a book review**
1. Mr. Patel opens "Introduction to Physics" detail page
2. He clicks "Write Review", selects 4 stars, writes "Excellent textbook for Grade 11"
3. System checks no existing review from this member on this book
4. System creates LibBookReview with is_faculty = true, is_approved = false
5. Activity logged: "Staff submitted a book review."
6. Returns success: "Review submitted successfully!"

**SC-005: Member cancels a pending reservation**
1. Ms. Sharma goes to My Books → Reservations
2. She sees "Climate Change: A Comprehensive Guide" with status "Pending"
3. She clicks Cancel
4. System finds the active reservation belonging to her, calls `withdraw('Cancelled by staff')`
5. Status changed to 'withdrawn'
6. Returns success: "Cancelled successfully."

---

## Failure Scenarios

**FC-001: Unregistered user tries to access portal**
1. A teacher who has never registered as a library member navigates to Library → Staff Library Portal
2. `StaffLibraryController@index()` calls `getMember()` — returns null
3. All data collections are set to empty paginators
4. View renders with "You are not registered as a library member. Please contact the librarian" message
5. No action buttons are available; all POST endpoints will also fail with 403

**FC-002: Member exceeds max books limit**
1. Mr. Patel currently has 8 books issued (his max_books_allowed = 8, all are within due date)
2. He tries to reserve a new physical book
3. `reservePhysical()` counts current issued+overdue transactions = 8
4. Comparison: 8 >= 8 → condition triggers
5. Returns JSON 400: "You have reached the maximum borrow limit. Cannot reserve more books."
6. Reservation is not created

**FC-003: Member tries to renew but another member has reserved the book**
1. Mr. Patel tries to renew "Physics Textbook Vol 1" 
2. System checks for pending reservations from other members on the same book
3. `LibPhysicalBookRequest::where('book_id', $transaction->book_id)->where('status', $pendingResId)->where('member_id', '!=', $member->id)->exists()` = true
4. Returns JSON 400: "Another member has reserved this book. Renewal is not possible."

**FC-004: Member tries to request digital access for a physical-only book**
1. Ms. Sharma clicks Request Access on a physical book "Hardcover Encyclopedia" (resource_type = Physical Book, is_physical = 1, is_digital = 0)
2. `requestDigitalAccess()` checks resource type compatibility
3. `$rt->is_physical && !$rt->is_digital` = true
4. Returns JSON 400: "This book (Hardcover Encyclopedia) is a physical-only resource (Physical Book). Digital access requests are not applicable."

**FC-005: Suspended member tries any action**
1. Mr. Patel's library membership has been suspended (is_suspended = true) due to overdue fines
2. He tries to request digital access
3. `requestDigitalAccess()` checks `$member->is_suspended` — true
4. Returns JSON 403: "Your library membership is suspended. You cannot request digital access."

**FC-006: Member reaches concurrent license limit on digital resource**
1. Ms. Sharma's approved digital resource "Premium Video Library" has `license_count = 5` (5 concurrent users)
2. Currently 5 active digital access transactions exist for this resource
3. She clicks View on the resource
4. `viewResource()` counts active transactions: activeCount = 5, license_count = 5
5. 5 >= 5 → blocks access
6. Redirects back with error: "Concurrent license limit reached (5 concurrent users)."

**FC-007: Member tries to submit duplicate review**
1. Ms. Sharma already reviewed "Climate Science Today" with 4 stars
2. She tries to submit another review for the same book
3. `submitReview()` checks `LibBookReview::where('book_id', ...)->where('member_id', ...)->first()` — finds existing
4. Returns JSON 422: "You have already reviewed this book."

**FC-008: Digital access has expired**
1. Mr. Patel's digital access was approved 95 days ago (digital_access_days = 90)
2. He clicks Download on the approved resource
3. `downloadResource()` computes: reviewed_at + 90 days < now() → expired
4. Redirects back with error: "Your digital access has expired (90 days from approval). Please request access again."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `lib_members` | Member identity, user_id FK, membership_type_id FK, is_suspended, outstanding_fines, expiry_date |
| Table | `lib_membership_types` | max_books_allowed, loan_period_days, renewal_allowed, max_renewals, digital_access_days, can_restricted_members_view_list |
| Table | `lib_books_master` | Book catalog, is_active, is_available, is_reference_only, resource_type_id |
| Table | `lib_book_copies` | Physical copies, shelf_location_id, status FK, current_condition_id |
| Table | `lib_digital_resources` | Digital files, license_type, license_count, license_start_date, license_end_date, can_teacher_download, can_staff_download |
| Table | `lib_digital_resource_access_restrictions` | user_id, role_id, designation_id, department_id based restrictions |
| Table | `lib_digital_access_request_types` | Codes: Download, View_Online, Stream, Offline, Extended |
| Table | `lib_digital_access_requests` | member_id, book_id, digital_resource_id, request_type, status, reviewed_at |
| Table | `lib_digital_access_transactions` | member_id, digital_resource_id, access_request_id, download/view history, revoked_at |
| Table | `lib_physical_book_requests` | Reservations + renewal requests, queue_position, is_renewal_request, renewal_days_requested, transaction_id |
| Table | `lib_transactions` | book_id, copy_id, member_id, issue_date, due_date, return_date, status, renewal_count |
| Table | `lib_transaction_histories` | transaction_id, old_value_json, new_value_json, physical_book_action_type |
| Table | `lib_book_reviews` | book_id, member_id, rating, review_text, is_approved, is_faculty |
| Table | `lib_wishlists` | member_id, book_id, is_active |
| Table | `lib_categories` | Book category hierarchy (top-level for filter dropdown) |
| Table | `lib_resource_types` | is_physical, is_digital booleans determining tab placement |
| Table | `lib_library_status_masters` | Dynamic status codes for Book Status, Member Status, Transaction Status, Reservation Status, Digital Access Request Status |
| Table | `lib_engagement_events` | Engagement tracking log |
| Table | `sys_users` | User authentication, user_type, role assignments |
| Table | `sys_media` | File storage for digital resource media files |
| Module | Notification | `LIBRARY_DIGITAL_ACCESS_REQUESTED` and `LIBRARY_DIGITAL_ACCESS_WITHDRAWN` notification events |
