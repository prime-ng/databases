
# Module Requirement: stp_Library (Browse + My Books)

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Library Integration — Browse Catalogue + My Books |
| **FRD Reference** | REQ-STP-018, BR-STP-001, BR-STP-033, BR-STP-034 |
| **Table Prefix** | `lib_*` (Library module), `stp_*` (StudentPortal) |
| **DB Layer** | Tenant (tenant_{uuid}) |
| **Controller** | `Modules\StudentPortal\Http\Controllers\StudentLibraryController` |
| **Route Prefix** | `/library` |
| **Associated Views** | `studentportal::library.*` (index, my-books, show, partials) |

---

## 2. Directory Layout

### 2.1 Route Map

| Method | URI | Controller Method | Name | Purpose |
|--------|-----|-------------------|------|---------|
| GET | `/library` | `index` | `library` | Library catalogue home — 3 tabs (E-Books, Physical, Suggested) |
| GET | `/library/book/{id}` | `showBook` | `library.book.show` | Single book detail page |
| GET | `/library/my-books` | `myBooks` | `library.my-books` | Student's borrowed books, requests, history |
| GET | `/library/physical/search` | `physicalSearch` | `library.physical.search` | AJAX search for physical books |
| POST | `/library/physical/reserve` | `reservePhysical` | `library.physical.reserve` | Reserve a physical book |
| POST | `/library/digital/request` | `requestDigitalAccess` | `library.digital.request` | Request digital access to a book |
| GET | `/library/digital/{resource}/download` | `downloadResource` | `library.digital.download` | Download a digital resource |
| GET | `/library/digital/{resource}/view` | `viewResource` | `library.digital.view` | View/stream a digital resource online |
| POST | `/library/request/{id}/cancel` | `cancelRequest` | `library.request.cancel` | Cancel a digital request or physical reservation |
| POST | `/library/renew/{id}` | `renewBook` | `library.renew` | Request renewal of a borrowed book |
| POST | `/library/wishlist/toggle` | `LibWishlistController@toggleWishlist` | `library.wishlist.toggle` | Add/remove from wishlist (hard-coupled) |
| POST | `/library/submit-review` | `submitReview` | `library.submit-review` | Submit a book review/rating |

---

## 3. Data / Entities

### 3.1 Primary Tables (Library Module — Consumed)

| Table | Purpose |
|-------|---------|
| `lib_books_master` | Main book catalogue — title, ISBN, publisher, resource type, availability |
| `lib_book_subject_jnt` | Book-class-subject junction for class-scoped filtering |
| `lib_categories` | Book categories (hierarchical, parent_category_id) |
| `lib_authors` | Book authors |
| `lib_members` | Library memberships — linked to sys_users |
| `lib_transactions` | Borrow/return transactions (issue, return, lost) |
| `lib_physical_book_requests` | Reservation and renewal requests for physical books |
| `lib_digital_access_requests` | Access requests for digital resources |
| `lib_digital_resources` | Digital resource files linked to books |
| `lib_digital_resource_access_restrictions` | Per-user/role/department restrictions on digital resources |
| `lib_digital_access_request_types` | Types of digital access (Download, View Online, etc.) |
| `lib_digital_access_transactions` | Audit trail for digital access (download/view tracking) |
| `lib_library_status_masters` | Status lookup (transaction status, reservation status, digital resource status) |
| `lib_book_reviews` | Book reviews with ratings |
| `lib_wishlists` | User wishlist items |
| `lib_engagement_events` | User engagement tracking (search, browse, download, etc.) |
| `lib_membership_types` | Membership types with rules (max books, renewals, digital access days) |

### 3.2 Key Model Relationships

```
User (sys_users)
  └── LibMember (lib_members) ── LibMembershipType
        ├── LibTransaction (lib_transactions) ── LibBookCopy ── LibBookMaster
        ├── LibPhysicalBookRequest (lib_physical_book_requests) ── LibBookMaster
        ├── LibDigitalAccessRequest (lib_digital_access_requests) ── LibBookMaster ── LibDigitalResource
        ├── LibBookReview (lib_book_reviews) ── LibBookMaster
        └── LibWishlist (lib_wishlists) ── LibBookMaster

Student (std_students) ── currentAcademicSession ── classSection ── class_id
  └── class_id → LibBookSubjectJnt → book_id → LibBookMaster
```

---

## 4. Business Rules

### BR-STP-001 (Data Ownership)
- All data displayed must belong to the authenticated student's library member profile.
- Non-member users see a restricted message and empty state; they cannot browse catalogue.

### BR-STP-033 (Library Membership Requirement)
- Student must be a library member (`LibMember` exists for this user) to:
  - View book catalogue (non-members see error state).
  - Reserve physical books.
  - Request digital access.
  - Download/view digital resources.
  - Submit reviews.

### BR-STP-034 (Membership Type Restriction)
- If the student's `LibMembershipType.can_restricted_members_view_list = 0`, restricted members can view the book list.
- If `can_restricted_members_view_list = 1`, the student CANNOT view the book list (database-level exclusion via `whereRaw('0=1')`).

### Additional Rules (Controller-Enforced)
- **Reference-only books**: `is_reference_only = true` books cannot be reserved.
- **Max borrow limit**: Current issued + overdue count must be less than `membershipType.max_books_allowed`.
- **Suspended members**: `is_suspended = true` blocks digital access requests.
- **Duplicate reservation prevention**: Active reservation for same book_id blocks new reservation.
- **Duplicate digital request prevention**: Active digital access request for same book_id blocks new request.
- **Renewal rules**: Only issued/overdue transactions can be renewed; `renewal_allowed` flag on membership type; `max_renewals` limit; pending reservations by others block renewal.
- **Digital access expiry**: Access expires after `membershipType.digital_access_days` from `reviewed_at`.
- **License concurrency**: Digital resources with `license_count` limit concurrent active access transactions.
- **Review uniqueness**: One review per member per book.
- **Class-level filtering**: Books are filtered to the student's class via `LibBookSubjectJnt`.
- **Digital resource permission**: `can_student_download` on digital resource must be true for download.
- **Access restrictions**: `LibDigitalResourceAccessRestriction` checked against user_id, role_id, designation_id, department_id.

---

## 5. Business Logic / Conditions

| Condition | Trigger | On-Violation |
|-----------|---------|-------------|
| User has no `LibMember` | Any library action | Error message: "You are not authorized to view the library" |
| Member is suspended | Reserve / digital request | 403: "Your library membership is suspended" |
| `can_restricted_members_view_list = 0` | Catalogue view | Book list hidden (empty) |
| Book is `is_reference_only` | Reserve | 400: "This is a reference-only book" |
| Max borrow limit reached | Reserve | 400: "Maximum borrow limit reached" |
| Active reservation exists | Reserve | 409: "Already have an active reservation" |
| Active digital request exists | Request digital access | 409: "Already have an active request" |
| `digital_access_days == 0` | Request digital access | 403: "Membership type does not allow digital access" |
| Resource not active | Download/View | 403: "Resource no longer available" |
| No approved access request | Download/View | 403: "No approved access" |
| Wrong request type (View only for Download) | Download | 403: "Only permits reading online" |
| License not started / expired | Download/View | Error back with detail |
| License concurrency limit reached | Download/View | Error back with detail |
| Renewal not allowed by membership | Renew | 400: "Renewal not allowed" |
| Max renewals reached | Renew | 400: "Maximum renewals reached" |
| Pending reservation by others | Renew | 400: "Another member has reserved this book" |
| Pending renewal already exists | Renew | 400: "Renewal request already pending" |
| Book not in issued/overdue status | Renew | 400: "Only issued or overdue books can be renewed" |
| Existing review found | Submit review | 422: "Already reviewed this book" |
| Digital resource not downloadable | Download | Back with "Download is restricted" |
| Access restriction not satisfied | Download/View/Request | 403: "You are restricted from accessing" |

---

## 6. Access Control / Permissions

- **Authentication**: All routes require `auth` middleware (implicitly via route group).
- **Authorization Model**: No explicit `Gate::authorize()` calls. Membership checks are done inline in each controller method.
- **Library Membership**: The `LibMember` model serves as the implicit authorization gate for all library operations. Non-members receive error states/403s.
- **Data Scoping**: All queries include `where('member_id', $member->id)` to enforce data ownership.
- **Hard Coupling**: The wishlist toggle route directly references `LibWishlistController` (cross-module hard coupling — flagged as ARCH-STP risk).

---

## 7. States / Statuses

### Physical Book Reservation FSM

| Status | Meaning |
|--------|---------|
| Pending | Reservation request submitted, awaiting processing |
| Available | Book set aside by librarian for pick-up |
| Approved | Request approved |
| Picked_Up | Student has collected the book (becomes a transaction) |
| Withdrawn/Cancelled | Reservation cancelled (by student or system) |
| Completed | Book returned, reservation cycle done |

### Digital Access Request FSM

| Status | Meaning |
|--------|---------|
| Pending | Request submitted, awaiting librarian review |
| Approved | Access granted |
| Withdrawn | Cancelled by student |
| Rejected | Denied by librarian |

### Transaction Status (Borrowed Books)

| Status | Meaning |
|--------|---------|
| Issued | Book currently borrowed |
| Returned | Book returned on time |
| Overdue | Past due date |
| Lost | Book reported lost |

---

## 8. Notifications / Alerts

| Event | Trigger | Notification Event Code | Description |
|-------|---------|------------------------|-------------|
| Digital Access Requested | POST `/library/digital/request` | `LIBRARY_DIGITAL_ACCESS_REQUESTED` | "Your digital access request for {book} has been received" |
| Digital Access Withdrawn | POST `/library/request/{id}/cancel` | `LIBRARY_DIGITAL_ACCESS_WITHDRAWN` | "Your digital access request for {book} has been withdrawn" |

Notifications are created in the `Notifications` module (`sys_notifications`). Non-critical errors are logged but do not block the main flow.

---

## 9. UI / UX Spec

### Library Index (Catalogue)
- **Three-tab layout**: E-Books (default), Physical Books, Suggested Books
- **E-Books tab**: Cards showing title, category, author, file format, license type, download/request status. Filterable by category dropdown and search bar. Paginated (12 per page).
- **Physical Books tab**: Cards showing title, category, author, publisher, availability. Filterable by search. Paginated (12 per page). "Available" filter toggle.
- **Suggested Books tab**: Curricular-aligned physical book suggestions based on the student's class and the current academic year.
- **Non-member state**: Error banner and all sections rendered empty.
- **Restricted member state**: No books visible if `can_restricted_members_view_list = 0`.

### Book Detail Page (`/library/book/{id}`)
- Full book info: title, authors, categories, publisher, ISBN, edition, language, description.
- Copies section: total copies, available copies, shelf location, condition.
- Digital resources: download/view buttons (requires approved access).
- My request status or "Request Digital Access" / "Reserve" buttons.
- Book reviews section with star rating and review text.
- "Submit Review" button (one per member).
- Related books section (same categories).

### My Books Page (`/library/my-books`)
- **Tabs**: Issued (default), Overdue, History, Requests, Reservations, Wishlist, Renewal Requests
- **Stats summary**: Total issued, active, overdue, outstanding fines.
- **Issued tab**: Table with title, copy ID, issue date, due date. "Renew" action button.
- **Overdue tab**: Highlighted table with title, due date, days overdue, accrued fine.
- **History tab**: Paginated list of returned/lost books with dates and status.
- **Requests tab**: Digital access requests with status (Pending/Approved/Withdrawn).
- **Reservations tab**: Physical book reservations with queue position.
- **Wishlist tab**: Saved books with option to remove.
- **Renewal Requests tab**: Submitted renewal requests with approval status.
- **Non-member state**: Error banner and empty sections.

### Engagement Tracking
- All browse, search, category filter, view detail, download, view online, reserve, cancel, renew, and review actions are logged to `lib_engagement_events` and `lib_digital_access_transactions`.

---

## 10. Error / Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Not a library member | Error banner on catalogue; 403 on all POST actions |
| Suspended membership | 403 on reserve/digital request actions |
| Restricted membership type | Books hidden from catalogue |
| No active academic session | Empty suggested books; no class filter applied |
| Book not found (show) | 404 via `findOrFail` |
| Digital resource file missing | Back with error: "The digital resource file is missing" |
| Concurrent license limit hit | Back with error: "Concurrent license limit reached" |
| Access request type mismatch | For download: "Only permits reading online" |
| Expired digital access | Back with error mentioning expiry period |
| Duplicate request (race condition) | DB UNIQUE constraint → 409 |
| Download of non-downloadable resource | Back with error: "Download is restricted" |

---

## 11. Performance / NFR

- **Pagination**: E-Books, Physical Books, Suggested Books all paginated at 12 per page with query string preservation.
- **Eager Loading**: All queries use `with()` for relationships. No N+1 in main flows.
- **AJAX Search**: Physical book search is AJAX-based with pagination.
- **Engagement Logging**: Wrapped in try-catch — failures are logged but do not block the user flow.

---

## 12. Dependencies (Cross-Module)

| Dependency | Type | Details |
|-----------|------|---------|
| `Modules\Library\Models\*` | Hard | All models imported directly from Library module |
| `Modules\Library\Http\Controllers\LibWishlistController` | Hard (coupling) | Direct class reference in route: `library.wishlist.toggle` |
| `Modules\SchoolSetup\Models\OrganizationAcademicSession` | Hard | Used to find current academic year for suggested books |
| `Modules\StudentProfile\Models\Student` | Hard | Student record to derive class_id |
| `Modules\Notification\Models\Notification` | Hard | Notification creation for request events |

---

## 13. Test Scenarios Summary

**Positive:**
- Library member views catalogue with all 3 tabs populated
- Student searches + filters e-books by category
- Student reserves a physical book (success path)
- Student requests digital access (success path)
- Student downloads/view approved digital resource
- Student renews an issued book
- Student cancels a reservation/request
- Student toggles wishlist
- Student submits a book review
- Student views My Books with all tabs populated

**Negative:**
- Non-member tries to access any library page → error/403
- Suspended member tries to reserve → 403
- Restricted member tries to view catalogue → empty
- Reference-only book reserve attempt → 400
- Duplicate reservation → 409
- Max borrow limit reached → 400
- No approved access → 403 on download
- Expired digital access → error
- License concurrency limit → error
- Max renewals reached → 400
- Duplicate review → 422

---

## 14. FRD Traceability

| FRD ID | Requirement | Status |
|--------|-------------|--------|
| REQ-STP-018 | Library Integration — Browse catalogue, request physical/digital, My Books view | ✅ |
| BR-STP-001 | Data ownership — student only sees own data | ✅ |
| BR-STP-033 | Library membership required for book actions | ✅ |
| BR-STP-034 | Membership type restriction on view list | ✅ |

---

## 15. Known Gaps / Issues

| Gap ID | Issue | Severity |
|--------|-------|----------|
| ARCH-STP | Library wishlist route hard-coupled to `LibWishlistController` — module rename/disable breaks route | Medium |
| GAP-STP-N/A | No `Gate::authorize()` calls — all auth is implicit via membership checks | Low |
| GAP-STP-N/A | `cancelRequest` uses `request()->get('type')` — digital vs physical | Low |

---

## 16. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| V1 | 2026-07-23 | OpenCode | Initial requirement document |
