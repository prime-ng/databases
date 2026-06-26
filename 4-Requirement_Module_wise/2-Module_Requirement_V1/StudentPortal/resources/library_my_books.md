# Resources — Library: My Issued Books Tab Requirements

## 1. Functional Overview
Displays the student's active borrowings, overdue books, outstanding fines, borrowing history, and digital request statuses.

---

## 2. Directory Layout & Parameters

### A. Borrowing Stats Summary
- Displays active issues count, overdue books count, and outstanding fines.

### B. Active Issues Table
- Lists currently borrowed physical books.
- **Columns**: Title, Copy ID, Issue Date, Due Date.

### C. Overdue Table
- Highlighted section listing overdue physical books.
- **Columns**: Title, Due Date, Days Overdue, Accrued Fine.

### D. Digital Requests & Physical Reservations List
- Lists active digital access requests (Pending/Approved) and physical book reservation queue positions.

### E. History logs
- Chronological list of returned or lost books.
- **Columns**: Title, Issue Date, Return Date, Status, Paid Fines.

---

## 3. Database References
- **Models**:
  - `Modules\Library\Models\LibMember`
  - `Modules\Library\Models\LibTransaction`
- **Tables**:
  - `lib_members`
  - `lib_transactions`
