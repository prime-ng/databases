# Resources — Library: Browse Books Tab Requirements

## 1. Functional Overview
Enables students to browse the library catalog, request access to digital books, and reserve physical copies.

---

## 2. Directory Layout & Parameters

### A. Digital Books (E-Books Tab)
- Lists digital books.
- Displays Title, Category, Author, File Format, and License Type.
- **Action**: "Request Digital Access" (opens request modal).
  - Modal Form: Descriptive text area to enter the reason for request.
  - Submitting a request creates a pending access request for the librarian to review.

### B. Physical Books (Physical Books Tab)
- Lists physical books.
- Displays Title, Category, Author, Publisher, and available copies count.
- **Action**: "Reserve Copy" / "Notify Me" (adds to reservation queue, displays queue position).

---

## 3. Database References
- **Models**:
  - `Modules\Library\Models\LibBookMaster`
  - `Modules\Library\Models\LibDigitalAccessRequest`
  - `Modules\Library\Models\LibReservation`
- **Tables**:
  - `lib_books_master`
  - `lib_digital_access_requests`
  - `lib_reservations`
