
# Test Case List: stp_Library

## 1. Module / Feature Overview

| Field | Value |
|-------|-------|
| **Module Code** | STP |
| **Feature Name** | Library Integration — Browse Catalogue + My Books |
| **FRD Reference** | REQ-STP-018, BR-STP-001, BR-STP-033, BR-STP-034 |
| **Controller** | `StudentLibraryController` |
| **Total Test Cases** | 48 |

---

## 2. Test Case Summary

### 2.1 Library Catalogue (Index)

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-001 | Verify library catalogue loads with all 3 tabs for a valid library member | Student is logged in AND is a library member | 1. Login as student library member<br>2. Navigate to /library | 3 tabs visible (E-Books, Physical, Suggested). E-Books tab active by default. E-Books paginated | ✅ | — | ⬜ | ◌ |
| TC-LIB-002 | Verify e-books tab shows only digital resources for student's class | Student has class-linked books with digital resources | 1. Login as library member<br>2. Navigate to /library<br>3. Observe E-Books tab | Only books matching student's class via `LibBookSubjectJnt` are shown. Books have digital resources with `can_student_download = true` | ✅ | — | ⬜ | ◌ |
| TC-LIB-003 | Verify e-books tab paginates at 12 per page | Student has >12 e-books assigned | 1. Login as library member<br>2. Navigate to /library<br>3. Count e-books on page 1 | Exactly 12 e-books shown. Pagination controls visible. URL param `ep=2` loads next page | ✅ | — | ⬜ | ◌ |
| TC-LIB-004 | Verify e-book cards display title, category, author, file format, license type | Student has at least 1 e-book | 1. Login as library member<br>2. View e-books tab | Each card shows: title, category name(s), author name(s), file format label, license type | ✅ | — | ⬜ | ◌ |
| TC-LIB-005 | Verify category filter filters e-books | Library has multiple categories with books | 1. View library<br>2. Select a category from dropdown<br>3. Wait for page reload | URL contains `?cat={id}`. Only e-books in selected category shown | ✅ | — | ⬜ | ◌ |
| TC-LIB-006 | Verify search filters e-books by title | Library has books with searchable titles | 1. View library<br>2. Enter search term in search bar<br>3. Submit search | URL contains `?q={term}`. E-books with matching title shown. Engagement event logged | ✅ | — | ⬜ | ◌ |
| TC-LIB-007 | Verify search filters e-books by author name | Library has books with searchable authors | 1. View library<br>2. Search by author's name | Matching books shown where author_name like search term | ✅ | — | ⬜ | ◌ |
| TC-LIB-008 | Verify physical books tab shows only physical resources | Library has physical books for student's class | 1. Login as library member<br>2. Click "Physical Books" tab | Shows physical books filtered by class. Title, category, author, publisher, available copies shown | ✅ | — | ⬜ | ◌ |
| TC-LIB-009 | Verify physical books tab paginates | Student has >12 physical books assigned | 1. Click Physical Books tab<br>2. Observe pagination | 12 per page. URL param `pp` controls page | ✅ | — | ⬜ | ◌ |
| TC-LIB-010 | Verify suggested books tab shows curricular-aligned books | Student has class + current academic year set | 1. Login as library member<br>2. Click "Suggested Books" tab | Shows physical books with `curricularAlignments` matching student's class + current academic year. `is_reference_only = false` books only | ✅ | — | ⬜ | ◌ |
| TC-LIB-011 | Verify non-member sees error banner and empty catalogue | User is logged in BUT not a library member | 1. Login as user without LibMember record<br>2. Navigate to /library | Error banner: "You are not authorized to view the library. Please contact the librarian to become a member." All sections show empty paginators/collections | ✅ | — | ⬜ | ◌ |
| TC-LIB-012 | Verify restricted member sees empty book list | Member has `can_restricted_members_view_list = 0` | 1. Login as member with restricted membership<br>2. Navigate to /library | All book sections show no results (database excluded via `whereRaw('0=1')`) | ✅ | — | ⬜ | ◌ |
| TC-LIB-013 | Verify student without active academic session sees no class-filtered books | Student has no `currentAcademicSession` | 1. Login as member student with no active session<br>2. View library | No class filtering applied — all queries with `whereIn('id', $classBookIds)` receive empty collection → no books shown | ✅ | — | ⬜ | ◌ |
| TC-LIB-014 | Verify digital resources respect `LibDigitalResourceAccessRestriction` | Some e-books have access restrictions| 1. Login as member who is NOT in the allowed users/roles/designations<br>2. View e-books tab | Restricted books excluded. Only unrestricted + books where user is explicitly allowed shown | ✅ | — | ⬜ | ◌ |
| TC-LIB-015 | Verify library home logs engagement `Page_View` | User is library member | 1. Login as member<br>2. View /library | `LibEngagementEvent` created with `event_type = Browse`, mapped from `Page_View` | ✅ | — | ⬜ | ◌ |

### 2.2 Physical Book Search (AJAX)

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-016 | Verify AJAX physical search returns JSON with rendered HTML | Library has physical books | 1. Login as member<br>2. Send GET `/library/physical/search?q=test` | Returns JSON `{status: true, html: "..."}` with rendered card view | ✅ | — | ⬜ | ◌ |
| TC-LIB-017 | Verify AJAX search filters by title, ISBN, and author | Matching books exist | 1. Send GET `/library/physical/search?q=isbn_value` | Results matching ISBN; also title and author search work | ✅ | — | ⬜ | ◌ |
| TC-LIB-018 | Verify AJAX search `filter=available` | Some books available, some not | 1. Send GET `/library/physical/search?filter=available` | Only books with `is_available = true` returned | ✅ | — | ⬜ | ◌ |
| TC-LIB-019 | Verify AJAX search paginates | Many results | 1. Send GET `/library/physical/search?q=a&page=2` | Paginated results returned | ✅ | — | ⬜ | ◌ |
| TC-LIB-020 | Verify AJAX search respects restricted member view | Member has restriction | 1. Login as restricted member<br>2. Send AJAX search | Empty results (0 rows) due to `whereRaw('0=1')` | ✅ | — | ⬜ | ◌ |

### 2.3 Book Detail (Show)

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-021 | Verify book detail page shows full book information | Book exists and active | 1. Navigate to `/library/book/{id}` | Shows: title, authors, categories, publisher, ISBN, edition, language, description, total copies, available copies, shelf location, condition | ✅ | — | ⬜ | ◌ |
| TC-LIB-022 | Verify book detail shows digital resource download/view buttons | Book has digital resources AND student has approved access | 1. Have approved digital access<br>2. View book detail | "Download" and/or "View Online" buttons visible depending on request type | ✅ | — | ⬜ | ◌ |
| TC-LIB-023 | Verify book detail shows "Request Digital Access" button | Book has digital resources BUT student has no approved access | 1. View book detail for a digital book without approved access | "Request Digital Access" button visible | ✅ | — | ⬜ | ◌ |
| TC-LIB-024 | Verify book detail shows "Reserve" button for physical books | Book is physical and not reference-only | 1. View detail of a physical book | "Reserve Copy" button visible | ✅ | — | ⬜ | ◌ |
| TC-LIB-025 | Verify book detail shows related books from same categories | Book has categories | 1. View book detail | "Related Books" section shown with up to 6 books from matching categories | ✅ | — | ⬜ | ◌ |
| TC-LIB-026 | Verify book detail shows approved reviews | Reviews exist | 1. View book detail | Reviews section with `is_approved = true` reviews shown | ✅ | — | ⬜ | ◌ |
| TC-LIB-027 | Verify 404 for non-existent book | ID does not exist | 1. Navigate to `/library/book/99999` | 404 Not Found | ✅ | — | ⬜ | ◌ |

### 2.4 Reserve Physical Book

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-028 | Verify student can reserve an available physical book | Student is member, book is physical, not reference-only, borrow limit not reached | 1. POST `/library/physical/reserve` with `book_id` and `type=reserve` | 201. `LibPhysicalBookRequest` created with status 'pending', `queue_position` calculated, `expected_available_date` set. JSON: `{status: true, message: "You will be notified"}` | ✅ | — | ⬜ | ◌ |
| TC-LIB-029 | Verify reference-only book cannot be reserved | Book has `is_reference_only = true` | 1. POST reserve with reference-only book_id | 400: "This is a reference-only book and cannot be reserved" | ✅ | — | ⬜ | ◌ |
| TC-LIB-030 | Verify non-member cannot reserve | User has no LibMember | 1. POST reserve as non-member | 403: "You are not registered as a library member" | ✅ | — | ⬜ | ◌ |
| TC-LIB-031 | Verify max borrow limit blocks reservation | Student has `currentIssued >= max_books_allowed` | 1. POST reserve | 400: "You have reached the maximum borrow limit" | ✅ | — | ⬜ | ◌ |
| TC-LIB-032 | Verify duplicate reservation is blocked | Student already has active reservation for same book | 1. POST reserve for same book again | 409: "You already have an active reservation for this book" | ✅ | — | ⬜ | ◌ |

### 2.5 Request Digital Access

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-033 | Verify student can request digital access | Member is not suspended, membership allows digital, no duplicate | 1. POST `/library/digital/request` with `book_id`, `reason`, optional `digital_resource_id` | 201. `LibDigitalAccessRequest` created. JSON: `{status: true, message: "Access request submitted"}`. Notification created | ✅ | — | ⬜ | ◌ |
| TC-LIB-034 | Verify suspended member cannot request | Member `is_suspended = true` | 1. POST digital request | 403: "Your library membership is suspended" | ✅ | — | ⬜ | ◌ |
| TC-LIB-035 | Verify membership type with `digital_access_days = 0` cannot request | Membership type has digital_access_days = 0 | 1. POST digital request | 403: "Your membership type does not allow digital access" | ✅ | — | ⬜ | ◌ |
| TC-LIB-036 | Verify physical-only book cannot get digital request | Book resource type is physical-only | 1. POST digital request for physical-only book | 400: "This book is a physical-only resource" | ✅ | — | ⬜ | ◌ |
| TC-LIB-037 | Verify duplicate digital request blocked | Active request already exists | 1. POST duplicate digital request | 409: "You already have an active request for this book" | ✅ | — | ⬜ | ◌ |
| TC-LIB-038 | Verify access restriction check on digital request | Resource has restrictions user does not satisfy | 1. POST digital request for restricted resource | 403: "You are restricted from accessing this digital resource" | ✅ | — | ⬜ | ◌ |

### 2.6 Digital Resource Download & View

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-039 | Verify download of approved digital resource | Approved access with 'Download' type | 1. GET `/library/digital/{resource}/download` | File downloads. `download_count` incremented on resource. `LibDigitalAccessTransaction` updated with download history | ✅ | — | ⬜ | ◌ |
| TC-LIB-040 | Verify view (inline stream) of digital resource | Approved access with 'View Online' or 'Download' type | 1. GET `/library/digital/{resource}/view` | File streams inline. `view_count` incremented. Transaction updated | ✅ | — | ⬜ | ◌ |
| TC-LIB-041 | Verify download blocked without approved access | No approved access request | 1. GET download route for unapproved resource | 403: "You do not have approved access" | ✅ | — | ⬜ | ◌ |
| TC-LIB-042 | Verify download blocked for 'View Only' request type | Access request type = 'View Online' only | 1. GET download route | 403: "Your access request only permits reading online, not downloading" | ✅ | — | ⬜ | ◌ |
| TC-LIB-043 | Verify download blocked when digital access has expired | `reviewed_at + digital_access_days` is in the past | 1. GET download route | Redirect back with error: "Your digital access has expired" | ✅ | — | ⬜ | ◌ |
| TC-LIB-044 | Verify download blocked when license not started | `license_start_date` is in the future | 1. GET download route | Back with error: "license has not started yet" | ✅ | — | ⬜ | ◌ |
| TC-LIB-045 | Verify download blocked when license expired | `license_end_date` is in the past | 1. GET download route | Back with error: "license has expired" | ✅ | — | ⬜ | ◌ |
| TC-LIB-046 | Verify concurrent license limit blocks download | `activeCount >= license_count` | 1. GET download route | Back with error: "Concurrent license limit reached" | ✅ | — | ⬜ | ◌ |
| TC-LIB-047 | Verify download blocked when `can_student_download = false` | Resource exists but download flag is false | 1. GET download route | Back with error: "Download is restricted" | ✅ | — | ⬜ | ◌ |

### 2.7 Renew, Cancel, Review, Wishlist

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-048 | Verify student can renew an issued book | Transaction is 'issued' or 'overdue', renewal allowed, no pending reservation by others | 1. POST `/library/renew/{transaction_id}` with optional days | 201. Renewal request created as `LibPhysicalBookRequest` with `is_renewal_request = true`. JSON: `{status: true, message: "Renewal request submitted!"}` | ✅ | — | ⬜ | ◌ |
| TC-LIB-049 | Verify renewal blocked for ineligible transaction | Transaction status is not issued/overdue | 1. POST renew for returned transaction | 400: "Only issued or overdue books can be renewed" | ✅ | — | ⬜ | ◌ |
| TC-LIB-050 | Verify renewal blocked when `renewal_allowed = false` | Membership type does not allow renewal | 1. POST renew | 400: "Renewal is not allowed for your membership type" | ✅ | — | ⬜ | ◌ |
| TC-LIB-051 | Verify renewal blocked when max renewals reached | `renewal_count >= max_renewals` | 1. POST renew | 400: "Maximum renewals reached" | ✅ | — | ⬜ | ◌ |
| TC-LIB-052 | Verify renewal blocked when another member has pending reservation | Other member has pending reservation for same book | 1. POST renew | 400: "Another member has reserved this book" | ✅ | — | ⬜ | ◌ |
| TC-LIB-053 | Verify duplicate renewal request blocked | Pending renewal already exists | 1. POST renew again | 400: "A renewal request is already pending" | ✅ | — | ⬜ | ◌ |
| TC-LIB-054 | Verify student can cancel a digital access request | Own pending digital request | 1. POST `/library/request/{id}/cancel` with `type=digital` | Request status changed to 'withdrawn'. Notification: "Digital Access Request Withdrawn". JSON success | ✅ | — | ⬜ | ◌ |
| TC-LIB-055 | Verify student can cancel a physical reservation | Own active physical reservation | 1. POST `/library/request/{id}/cancel` with `type=physical` | Reservation withdrawn. JSON success | ✅ | — | ⬜ | ◌ |
| TC-LIB-056 | Verify cancel blocked for another student's request | Request belongs to different member | 1. POST cancel with another student's request ID | 404: "Request not found" (because member_id filter excludes) | ✅ | — | ⬜ | ◌ |
| TC-LIB-057 | Verify student can submit a book review | Has not already reviewed this book | 1. POST `/library/submit-review` with `book_id`, `rating`, optional `review_text` | 201. Review created with `is_approved = false`. JSON: `{status: true, message: "Review submitted successfully!"}` | ✅ | — | ⬜ | ◌ |
| TC-LIB-058 | Verify duplicate review blocked | Already reviewed this book | 1. POST submit-review again for same book | 422: "You have already reviewed this book" | ✅ | — | ⬜ | ◌ |
| TC-LIB-059 | Verify review requires valid rating (1-5) | Invalid rating | 1. POST with rating = 0 or 6 | 422 validation error | ✅ | — | ⬜ | ◌ |
| TC-LIB-060 | Verify non-member cannot submit review | No LibMember | 1. POST submit-review as non-member | 403: "You must be a library member to submit a review" | ✅ | — | ⬜ | ◌ |
| TC-LIB-061 | Verify wishlist toggle works (hard-coupled route) | Book exists, member exists | 1. POST `/library/wishlist/toggle` with `book_id` | Wishlist item toggled. Depends on LibWishlistController implementation | ✅ | — | ⬜ | ◌ |

### 2.8 My Books

| TC# | Test Case | Prerequisite | Steps | Expected Result | V1 | V2 | Status | CR |
|-----|-----------|-------------|-------|-----------------|----|----|--------|----|
| TC-LIB-062 | Verify My Books page loads with stats summary | Student is library member with transactions | 1. Navigate to `/library/my-books` | Stats shown: total_issued, active, overdue, fines. Tabs: Issued (default), Overdue, History, Requests, Reservations, Wishlist, Renewal Requests | ✅ | — | ⬜ | ◌ |
| TC-LIB-063 | Verify Issued tab shows currently borrowed books | Member has issued books | 1. View My Books, Issued tab | Books listed with title, copy ID, issue date, due date. Ordered by due_date ASC | ✅ | — | ⬜ | ◌ |
| TC-LIB-064 | Verify Overdue tab highlights overdue books | Member has overdue books | 1. View My Books, Overdue tab | Overdue books shown with title, due date, days overdue, accrued fines. Highlighted section | ✅ | — | ⬜ | ◌ |
| TC-LIB-065 | Verify History tab shows returned/lost books | Member has return history | 1. View My Books, History tab | Paginated list of returned/lost books with issue date, return date, status, paid fines | ✅ | — | ⬜ | ◌ |
| TC-LIB-066 | Verify Requests tab shows digital access requests | Member has digital requests | 1. View My Books, Requests tab | Digital access requests listed with status | ✅ | — | ⬜ | ◌ |
| TC-LIB-067 | Verify Reservations tab shows physical reservations | Member has physical reservations | 1. View My Books, Reservations tab | Reservations listed with queue position, status | ✅ | — | ⬜ | ◌ |
| TC-LIB-068 | Verify Wishlist tab shows saved books | Member has wishlist items | 1. View My Books, Wishlist tab | Saved books shown with details (authors, publisher, categories, resource type) | ✅ | — | ⬜ | ◌ |
| TC-LIB-069 | Verify non-member sees error on My Books | User not a library member | 1. Navigate to `/library/my-books` as non-member | Error: "You are not registered as a library member". All sections empty | ✅ | — | ⬜ | ◌ |
