# Functional Requirements Document (FRD)
# Module: Library
# Prime-AI School ERP Platform

| Field | Value |
|-------|-------|
| **Module Name** | Library |
| **Module Code** | LIB |
| **Document Version** | 1.0 |
| **Date** | 2026-06-25 |
| **Status** | Draft |
| **Prepared By** | Business Analysis — Prime-AI |
| **Reviewed By** | (Pending) |
| **Approved By** | (Pending) |

---

## Section 1 — Module Overview

### 1.1 Business Purpose

Indian school libraries manage hundreds to thousands of books, periodicals, and digital resources across student and staff populations. Without a digital system, schools rely on handwritten issue registers, manual fine calculations, and informal overdue follow-ups — all of which create lost revenue, unaccountable collections, and frustrated users. The Library module solves this by providing a complete digital library management system that covers the full resource lifecycle: from cataloging a new book and enrolling a member, to tracking who has what book, calculating late fines automatically, maintaining a reservation queue, and verifying physical stock through periodic audits. A school that does not have this module cannot hold library staff accountable, cannot recover fine revenue reliably, and cannot demonstrate collection health to management or accreditation bodies.

### 1.2 Business Value

- **Eliminates manual paper registers** — every issue, return, renewal, and fine is recorded in the system automatically, reducing errors and saving librarian time.
- **Automates fine calculation** — the slab-based fine engine calculates penalties instantly at return time using preconfigured day-range rates, removing the need for manual arithmetic.
- **Improves collection accountability** — inventory audit sessions allow librarians to scan the entire shelf against system records and immediately identify missing, misplaced, or damaged books.
- **Enables self-service holds** — the reservation queue gives members a fair, first-come-first-served position when all copies of a book are checked out.
- **Provides management visibility** — circulation, overdue, fine collection, and acquisition reports give principals and administrators a clear picture of library health without visiting the library counter.
- **Supports digital resources** — e-books and PDF resources with license date and concurrent-user controls extend the library's reach beyond physical shelf space.

### 1.3 Scope

#### In Scope
1. Library configuration — membership types, resource types, book conditions, shelf location hierarchy, fine type definitions, and fine slab rules
2. Book catalog management — titles, authors, publishers, categories, genres, keywords, and academic subject mapping
3. Physical book acquisition — purchase records, vendor linking, and individual copy registration with barcodes and accession numbers
4. Digital resource management — e-book and PDF uploads, license date control, role-based download restrictions, and access request workflow
5. Library member registration — enrollment of students, teachers, and staff as library members with membership type assignment
6. Book circulation — issue (checkout), return (check-in), renewal, and mark-as-lost operations
7. Reservation (hold) queue — members reserve currently-unavailable books and receive notification when their copy becomes available
8. Fine management — calculation, collection, partial payment, waiver, and receipt generation
9. Transaction history and audit trail — immutable log of every action taken on every transaction
10. Physical inventory audit — barcode and RFID scan sessions to verify stock against system records
11. Reporting and analytics — circulation, fine collection, overdue, acquisition, digital resource usage, and library dashboard reports

#### Out of Scope
1. Student fee integration — fine amounts charged to student fee accounts are managed by the Student Fee module
2. Syllabus book assignment — mapping of prescribed textbooks to class/subject is managed by the Syllabus Books module
3. Student self-service portal — students browsing the catalog and placing reservations independently is managed by the Student Portal module
4. Vendor management — registering and managing vendor profiles is handled by the Vendor module
5. General notifications dispatch — the notification delivery engine (SMS, email, push) is managed by the Notification module
6. Accounting journal entries — fine payment posting to general ledger is handled by the Accounting module

### 1.4 Key Terminology

| Business Term | Meaning |
|---------------|---------|
| Book Title / Catalog Record | The central record for a published work — its name, author, publisher, ISBN, category, and other descriptive information. One title may have many physical copies. |
| Book Copy | A single physical instance of a title, identified by a unique accession number and barcode. Each copy has its own condition, shelf location, and availability status. |
| Accession Number | A unique sequential number assigned to each copy when it is added to the library collection. It is the library's internal identifier for that copy. |
| Library Member | A school user (student, teacher, or staff) who has been registered for library membership and is eligible to borrow books under the rules of their membership type. |
| Membership Type | A configuration record that defines the borrowing rules for a category of members — how many books they can hold at once, how long they can keep them, whether they can renew, and what fine rates apply to them. |
| Loan Period | The number of days a member is permitted to keep a borrowed book before it is considered overdue. |
| Grace Period | A buffer of days after the due date during which no fine is charged. Fines begin accruing only after the grace period ends. |
| Fine Slab | A day-range rate table that defines how much a member is charged per day (or per period) for different stages of overdue delay. For example: Days 1–7 at ₹1/day, Days 8–30 at ₹2/day. |
| Reservation / Hold | A queue entry that a member places for a book whose all copies are currently checked out. The member receives a notification and a pickup deadline when their copy becomes available. |
| Queue Position | A number that records a member's place in the reservation queue for a given book. Lower numbers are served first. |
| Inventory Audit | A formal stock-count session during which a librarian scans every copy on the shelves using a barcode or RFID scanner. The system compares scan results against expected records to identify missing, misplaced, or damaged copies. |
| Digital Resource | An electronic file (e-book, PDF, audiobook) associated with a book title. Access may be restricted by license dates, role, or concurrent-user count. |
| Reference-Only Book | A book copy that may be consulted inside the library but cannot be borrowed or taken home. |

---

## Section 2 — User Roles & Access

### 2.1 Actor Definitions

| Role | Who They Are | Their Relationship to This Module |
|------|-------------|----------------------------------|
| Librarian | The designated library staff member responsible for day-to-day library operations | Full operational access — catalog, members, issue, return, fines, inventory audit |
| Library Supervisor | A senior librarian or library-in-charge with authority over financial decisions | All librarian actions plus the ability to waive fines and approve renewal requests |
| School Admin / Principal | The school's administrative head | Read-only access to reports and dashboard; can approve fine waivers upon escalation |
| Teacher | A teaching staff member registered as a library member | Can borrow books; views their own transaction history |
| Student | A student registered as a library member | Can view the catalog and place reservations (via Student Portal); cannot access back-office screens |
| System Administrator | The technical administrator responsible for platform setup | Configures membership types, fine slabs, shelf locations, and book conditions |

### 2.2 Role-Feature Access Matrix

| Feature | Librarian | Library Supervisor | School Admin / Principal | Teacher | Student |
|---------|-----------|-------------------|-------------------------|---------|---------|
| Book Catalog — View | Full Access | Full Access | View Only | View Only | View Only |
| Book Catalog — Add / Edit | Full Access | Full Access | No Access | No Access | No Access |
| Member Management | Full Access | Full Access | View Only | No Access | No Access |
| Book Issue / Return / Renewal | Full Access | Full Access | No Access | No Access | No Access |
| Reservations — Create | Full Access | Full Access | No Access | No Access | Self Only (via Portal) |
| Reservations — Manage | Full Access | Full Access | No Access | No Access | No Access |
| Fine Calculation & Collection | Full Access | Full Access | No Access | No Access | No Access |
| Fine Waiver | No Access | Full Access | Approval Only | No Access | No Access |
| Library Configuration | View Only | View Only | No Access | No Access | No Access |
| Library Configuration — Edit | No Access | No Access | No Access | No Access | No Access (System Admin only) |
| Inventory Audit | Full Access | Full Access | View Only | No Access | No Access |
| Reports & Dashboard | Full Access | Full Access | Full Access | No Access | No Access |

---

## Section 3 — Functional Requirements

### 3.1 Library Configuration Setup

**Requirement ID:** REQ-LIB-001
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION]

#### Business Description
Before the library can operate, a System Administrator must configure the foundational rules that govern how the library works. This includes defining what types of resources exist (physical books, e-books, audio), what conditions a book can be in (New, Good, Damaged), what categories of membership exist and what borrowing limits apply to each, where books are physically stored (building → zone → floor → aisle → rack → shelf), and what types of fines can be levied. These configurations act as the rules engine for all subsequent library operations. Without them, no books can be cataloged, no members enrolled, and no fines calculated.

#### Actors
- **Initiates:** System Administrator
- **Processes / Approves:** System Administrator
- **Views / Receives notification:** Librarian (uses these configurations daily)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-001 | A resource type must be marked as either physical, digital, or audio — and whether items of that type are borrowable. A non-borrowable resource type prevents any copy from being issued to a member. | Validation |
| BR-LIB-002 | A book condition marked as "not borrowable" prevents any copy in that condition from being checked out. Default system conditions (Good, Damaged, Lost) cannot be deleted. | Validation / Permission |
| BR-LIB-003 | A membership type must specify the maximum number of books a member may hold simultaneously, the standard loan period in days, and whether renewals are permitted. All three fields are required. | Validation |
| BR-LIB-004 | A shelf location is built hierarchically: a Building must exist before a Zone, a Zone before a Floor, a Floor before an Aisle, an Aisle before a Rack, and a Rack before a Shelf. You cannot create a lower level without a parent. | Workflow |
| BR-LIB-005 | A fine type (Late Return, Lost Book, Damaged Book, Processing Fee) is a system-level classification. Custom fine types may be added, but system fine types cannot be removed. | Permission |

#### Acceptance Criteria
This feature is considered complete when:
1. A System Administrator can add a new membership type with borrowing limits and the limits are enforced when a member attempts to check out more books than allowed.
2. A fine type is visible in the fine slab configuration screen once added here.
3. Attempting to delete a default book condition (Good, Damaged, Lost) is blocked with an explanatory message.
4. A new shelf location reference can be added at each level of the hierarchy and appears as a selection option when cataloging a book copy.

#### Integration with Other Modules
- Sends to: All other library features (every core library operation reads these configurations)
- Receives from: SchoolSetup (the building list used for shelf location setup comes from school buildings)

#### Enhancement Notes (Future)
- Allow membership types to specify a maximum outstanding fine balance above which new checkouts are blocked.
- Allow configuration of automatic membership renewal on academic year rollover.

---

### 3.2 Book Catalog Management

**Requirement ID:** REQ-LIB-002
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [CONFIGURATION]

#### Business Description
The catalog is the library's master list of all titles — every book, journal, e-book, and audio resource that the library owns or has access to. A Librarian adds a new title by entering its name, subtitle, author(s), publisher, year of publication, language, category, genre, subject relevance, and any ISBN or similar identifier. The system also supports ISBN auto-lookup: the librarian types the ISBN and the system retrieves basic title information from an external source, reducing manual data entry. Titles are searchable by name, author, subject, and keyword. Each title record is the parent record to which individual physical copies and digital files are attached.

#### Actors
- **Initiates:** Librarian
- **Processes / Approves:** Librarian
- **Views / Receives notification:** All library users (browse catalog)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-006 | A book title must have at least one author, one category, and one resource type selected before it can be saved. | Validation |
| BR-LIB-007 | An ISBN, once entered, must be unique across the library catalog. Two different titles cannot share the same ISBN. | Validation |
| BR-LIB-008 | A title marked as "reference only" cannot be issued to any member. It may be viewed in the library but cannot leave the premises. | Workflow / Validation |
| BR-LIB-009 | A book title cannot be deleted if it has any active physical copies or active digital resource files attached to it. The Librarian must first deactivate or remove those copies. | Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can add a new book title with all required fields and it appears in the catalog search results immediately.
2. Entering an ISBN and triggering the auto-lookup populates title, author, publisher, and year fields without additional manual entry.
3. Marking a title as reference-only prevents it from appearing as available for checkout in the book issue screen.
4. Attempting to delete a title that has active copies results in a block message, not deletion.

#### Integration with Other Modules
- Receives from: SchoolSetup (class and subject lists for academic subject mapping)
- Receives from: Vendor module (vendor names for book purchase records)

#### Enhancement Notes (Future)
- AI-generated title summary and keyword extraction when a new book is added.
- Curricular alignment screen — mapping a book's academic relevance score to specific class and subject combinations.

---

### 3.3 Book Acquisition & Physical Copy Registration

**Requirement ID:** REQ-LIB-003
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [WORKFLOW]

#### Business Description
When the school purchases physical books, the Librarian records the purchase — the vendor, invoice number, date, and the list of titles and quantities purchased. Each physical copy purchased is then individually registered in the system with a unique accession number (the library's sequential identifier), a scannable barcode, an optional RFID tag, the shelf location where it is to be stored, and its initial condition. This process creates the individual "copy" records that are tracked throughout their lifetime. Each copy has a status (Available, Issued, Reserved, Under Maintenance, Lost, or Withdrawn) that the system updates automatically as transactions occur.

#### Actors
- **Initiates:** Librarian
- **Processes / Approves:** Librarian
- **Views / Receives notification:** Librarian, Library Supervisor (for purchase cost reporting)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-010 | Each physical copy must have a unique accession number and a unique barcode within the school's library. No two copies may share either identifier. | Validation |
| BR-LIB-011 | A copy's condition history is recorded every time its condition changes — at purchase, at return, or during an audit. This history cannot be edited or deleted. | Workflow |
| BR-LIB-012 | A copy marked as Lost or Withdrawn cannot be issued to a member. It must be explicitly restored or replaced before it can re-enter circulation. | Validation |
| BR-LIB-013 | When a book purchase is recorded, the total invoice amount must equal the sum of the individual item amounts (price × quantity) plus tax. | Calculation |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can record a purchase from a vendor, add multiple book titles and quantities to that purchase, and the system creates the correct number of individual copy records automatically.
2. Each copy appears with its accession number, barcode, condition, and shelf location in the catalog copy list.
3. Attempting to save two copies with the same accession number or barcode results in a validation error.
4. A copy's condition history is visible in the copy detail view and cannot be edited.

#### Integration with Other Modules
- Receives from: Vendor module (vendor list for purchase record)
- Sends to: Accounting module (purchase event for journal voucher creation)

#### Enhancement Notes (Future)
- Barcode/QR label printing for newly registered copies directly from the purchase entry screen.
- Bulk copy import via spreadsheet for large acquisitions.

---

### 3.4 Library Member Registration & Management

**Requirement ID:** REQ-LIB-004
**Priority:** Core (P0)
**Category Tags:** [DATA_ENTRY] [CONFIGURATION]

#### Business Description
Before a student, teacher, or staff member can borrow a book, they must be registered as a library member. The Librarian links an existing school system user to a library membership record, assigns a membership type (which determines borrowing limits), generates a unique library membership number, and issues a library card barcode. The membership has an expiry date after which borrowing is not permitted unless the membership is renewed. Members can be suspended (temporarily blocked from borrowing, typically due to unpaid fines or misconduct) or deactivated. The module also tracks each member's lifetime borrowing statistics and their outstanding fine balance.

#### Actors
- **Initiates:** Librarian
- **Processes / Approves:** Librarian
- **Views / Receives notification:** Member (their own profile), Librarian, Library Supervisor

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-014 | Each school user can have only one active library membership. A user cannot be registered as a library member twice. | Validation |
| BR-LIB-015 | A membership cannot be deleted if the member has any outstanding fines or any currently issued books. | Validation |
| BR-LIB-016 | A member with Expired, Suspended, or Deactivated status cannot check out books until their status is corrected. | Workflow |
| BR-LIB-017 | The library card barcode must be unique across all members of the school. No two members may share a barcode. | Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can register a student as a library member, and the member's borrowing limit from their membership type is enforced when they attempt to issue more books than allowed.
2. Setting a member's status to Suspended immediately prevents new checkouts for that member.
3. A member's outstanding fine balance increases automatically when a fine is created against them, and decreases when a fine payment is recorded.
4. Attempting to register a user who is already a library member results in a block message.

#### Integration with Other Modules
- Receives from: StudentProfile, SchoolSetup (user list for member registration)
- Sends to: Student Portal (member status and outstanding fines visible to student)

#### Enhancement Notes (Future)
- Automatic membership expiry — system marks memberships as Expired when their expiry date passes without manual intervention.
- Academic year rollover renewal — one-click bulk renewal for all active student members at the start of a new academic year.

---

### 3.5 Book Issue (Checkout)

**Requirement ID:** REQ-LIB-005
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [DATA_ENTRY]

#### Business Description
Book Issue is the transaction that records a member taking a physical book out of the library. The Librarian scans (or types) the member's library card barcode and the book copy's barcode. The system validates that the member is eligible and the copy is available, then creates a transaction record capturing the issue date, the calculated due date, the copy's condition at the time of issue, and the librarian who processed it. The copy's status immediately changes to Issued. A member can issue multiple books in one session, subject to their borrowing limit.

#### Actors
- **Initiates:** Member (presents at the desk) / Librarian (processes the transaction)
- **Processes / Approves:** Librarian
- **Views / Receives notification:** Member (confirmation of due date)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-018 | A member must have Active status to check out a book. Members with Expired, Suspended, or Deactivated status are blocked. | Validation |
| BR-LIB-019 | A member cannot check out more books than their membership type's maximum simultaneous borrowing limit. The count includes all currently issued and overdue books. | Validation |
| BR-LIB-020 | A member with any currently overdue books is blocked from checking out additional books until all overdue items are returned or resolved. | Validation |
| BR-LIB-021 | A copy can only be issued if its status is Available. Copies with status Issued, Reserved, Lost, Under Maintenance, or Withdrawn cannot be checked out. | Validation |
| BR-LIB-022 | A copy whose condition is classified as "not borrowable" cannot be issued. | Validation |
| BR-LIB-023 | A title marked as reference-only cannot be issued, regardless of copy availability. | Validation |
| BR-LIB-024 | The due date is calculated as: Issue Date + the member's membership type loan period in days. | Calculation |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can scan a member barcode and a copy barcode and complete a checkout in under 30 seconds.
2. The correct due date is displayed on the transaction confirmation.
3. The copy's status changes to Issued immediately after the transaction is saved.
4. Attempting to check out when any of the six blocking conditions (BR-LIB-018 through BR-LIB-023) are met displays a clear block message and does not create a transaction.
5. The member's current issued book count is accurately reflected after the transaction.

#### Integration with Other Modules
- Receives from: Member registration (to verify member status and limits)
- Sends to: Notification module (due date reminder dispatch — future)

#### Enhancement Notes (Future)
- Scan-first workflow — librarian scans member card and book barcode using a physical scanner without typing.
- Block checkout if member's outstanding fine balance exceeds a configurable threshold.

---

### 3.6 Book Return (Check-In)

**Requirement ID:** REQ-LIB-006
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [DATA_ENTRY]

#### Business Description
Book Return records a member handing back a borrowed book. The Librarian locates the open transaction (by member name, barcode, or accession number), records the actual return date and the book's condition at return. If the return is after the due date and the grace period has elapsed, the system indicates that a fine is applicable and initiates the fine calculation process. If the book's return condition is worse than its issue condition, the Librarian can additionally apply a damage fine. Once the return is completed, the copy's status reverts to Available and any members on the reservation queue for that title are notified.

#### Actors
- **Initiates:** Member (returns book at the desk) / Librarian (processes the return)
- **Processes / Approves:** Librarian
- **Views / Receives notification:** Member (confirmation of return; fine amount if applicable), Next member in reservation queue (notified of availability)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-025 | The number of overdue days is calculated as: (Actual Return Date − Due Date) − Grace Period Days. If this value is zero or negative, no fine is charged. | Calculation |
| BR-LIB-026 | If the book's condition at return is worse than its condition at issue, the Librarian must decide whether to apply a damage fine in addition to any late fine. | Workflow |
| BR-LIB-027 | A fine record must be created before the Librarian can complete the return if the system determines overdue days exist. The fine may be paid immediately or left as a pending balance on the member's account. | Workflow |
| BR-LIB-028 | Once a return is recorded, the copy status becomes Available and the system checks for pending reservations for that title. The member with the lowest queue position is notified first. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. Returning a book on time results in a clean return with no fine and the copy status immediately set to Available.
2. Returning a book after the due date and grace period shows the overdue days and the calculated fine amount before the Librarian confirms the return.
3. Returning a book in a worse condition than it was issued in prompts the Librarian to assess a damage fine.
4. After a return, if there is a reservation queue for that title, the next member in queue is visible as the next notification target.

#### Integration with Other Modules
- Sends to: Fine management (fine creation triggered on overdue return)
- Sends to: Notification module (reservation queue notification — future)

#### Enhancement Notes (Future)
- Self-return kiosk integration — member scans their own book barcode to initiate return, Librarian confirms condition.

---

### 3.7 Book Renewal

**Requirement ID:** REQ-LIB-007
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW]

#### Business Description
A member who needs more time with a book can request a renewal before the due date. The Librarian processes the renewal request by extending the due date by the member's standard loan period. The system checks that the member's membership type permits renewals and that the member has not already renewed the book the maximum permitted number of times. A renewal can also be requested in advance by the member, pending Librarian approval.

#### Actors
- **Initiates:** Member (requests at the desk or via portal) / Librarian (processes)
- **Processes / Approves:** Librarian or Library Supervisor
- **Views / Receives notification:** Member (new due date confirmation)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-029 | Renewal is permitted only if the member's membership type has renewals enabled. If the membership type does not allow renewals, the renewal request is blocked. | Validation |
| BR-LIB-030 | Renewal is blocked if the member has already renewed the book the maximum number of times permitted by their membership type. | Validation |
| BR-LIB-031 | The new due date upon renewal is calculated as: Today's Date + the member's membership type loan period in days. | Calculation |
| BR-LIB-032 | A book that has been marked as Lost or has a pending reservation by another member cannot be renewed without Librarian override. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can renew a transaction and the new due date is immediately updated.
2. Attempting to renew beyond the maximum renewal count is blocked with a clear message.
3. Attempting to renew when the membership type does not permit renewals is blocked.
4. The renewal count on the transaction record increments with each renewal.

#### Integration with Other Modules
- None (self-contained within the library module)

#### Enhancement Notes (Future)
- Member self-service renewal via Student or Parent Portal, pending automatic validation.

---

### 3.8 Book Reservation (Hold Queue)

**Requirement ID:** REQ-LIB-008
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [NOTIFICATION]

#### Business Description
When all copies of a book are currently checked out, a member can place a reservation (hold). The system records the member's queue position — the first member to reserve is first in line. When any copy of that title is returned, the system marks the first-in-queue member's reservation as Available and starts a pickup deadline countdown. If the member does not collect the book by the pickup deadline, the reservation expires and the next member in the queue is notified. A member may also cancel their own reservation at any time.

#### Actors
- **Initiates:** Member or Librarian (places the reservation)
- **Processes / Approves:** Librarian (marks Available, Picked Up, or Cancelled)
- **Views / Receives notification:** Member (notified when copy becomes available and when pickup deadline is approaching)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-033 | A member cannot have more than one active reservation (Pending or Available status) for the same book title at the same time. | Validation |
| BR-LIB-034 | Queue position is assigned as the next sequential number among all active reservations for the same title. Lower position numbers are served first. | Workflow |
| BR-LIB-035 | When a copy is returned, the reservation with the lowest queue position for that title is automatically moved to Available status. The member is notified and given a pickup deadline. | Workflow |
| BR-LIB-036 | If a reservation in Available status is not collected by the pickup deadline, it expires automatically and the next member in queue receives the Available status. | Workflow |
| BR-LIB-037 | When a reservation is cancelled, all remaining members in the queue for that title move up one position to maintain a contiguous queue. | Workflow |

#### Acceptance Criteria
This feature is considered complete when:
1. A member can have a reservation placed and their queue position is correctly shown.
2. When a copy is returned, the first-in-queue member's reservation automatically changes to Available.
3. A member attempting to place a second reservation on the same title they already have a reservation for is blocked.
4. Cancelling a reservation correctly adjusts the queue positions of all remaining members for that title.

#### Integration with Other Modules
- Sends to: Notification module (availability and pickup deadline notifications — future)

#### Enhancement Notes (Future)
- Automated daily job to expire reservations past their pickup deadline without manual intervention.
- Member self-service cancellation of their own reservations via Student Portal.

---

### 3.9 Fine Calculation Setup

**Requirement ID:** REQ-LIB-009
**Priority:** Core (P0)
**Category Tags:** [CONFIGURATION]

#### Business Description
Before the library can levy fines, a System Administrator must configure the fine slab rules. A fine slab configuration links a fine type (Late Return, Lost Book, Damaged Book, or Processing Fee) to a specific membership category and/or resource type, and defines how much to charge across different overdue day ranges. For example: Days 1–7 at ₹1 per day, Days 8–30 at ₹2 per day, Days 31+ at ₹5 per day. A maximum fine cap may also be set so that no member is charged more than a specified amount for a single overdue incident. Multiple slab configurations can coexist, and a priority order determines which slab is applied when more than one could match a given situation.

#### Actors
- **Initiates:** System Administrator
- **Processes / Approves:** Library Supervisor (reviews before activation)
- **Views / Receives notification:** Librarian (uses slabs when calculating fines at return)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-038 | A fine slab configuration must have at least one day-range detail row with a rate and a calculation period (per day, per week, per month, per book). | Validation |
| BR-LIB-039 | Day ranges within a single slab configuration must not overlap. The "to day" of one range must be less than the "from day" of the next range. | Validation |
| BR-LIB-040 | When multiple slab configurations could apply to a single transaction, the configuration with the highest priority number is used first. | Workflow |
| BR-LIB-041 | A slab configuration set with a "Book Cost" cap type charges the member the replacement cost of the book, not a fixed fine amount. | Calculation |
| BR-LIB-042 | A fine slab configuration has an effective date range. Only slabs whose effective dates include the transaction's return date are eligible for selection. | Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. A System Administrator can add a fine slab with multiple day-range rows and the calculated fine at return time matches the expected amount based on those rows.
2. Overlapping day ranges within the same slab are blocked with a validation error.
3. The correct slab is applied when multiple slabs could match, based on priority order.
4. A slab whose effective date has expired is not used in fine calculations even if it would otherwise match.

#### Integration with Other Modules
- Sends to: Fine Collection (fine records use the configured slabs)
- Sends to: Accounting module (account entry configuration links fine types to ledger accounts)

#### Enhancement Notes (Future)
- Allow separate fine slab configurations for digital resource access overruns (when a member exceeds their digital access duration).

---

### 3.10 Fine Collection & Waiver

**Requirement ID:** REQ-LIB-010
**Priority:** Core (P0)
**Category Tags:** [WORKFLOW] [DATA_ENTRY] [APPROVAL]

#### Business Description
When a fine has been created (due to a late return, lost book, or damaged book), the Librarian collects payment from the member. The system accepts full or partial payments in cash, by card, or via online transfer. Each payment generates a unique receipt. A fine may also be waived (partially or fully) by a Library Supervisor when there are valid grounds — for example, if a book was returned late due to a school event. Waiver requires a written reason to be recorded. The member's outstanding fine balance on their membership record is updated automatically with every payment and waiver.

#### Actors
- **Initiates:** Member (pays at the desk) / Librarian (records payment)
- **Processes / Approves:** Librarian (payments), Library Supervisor (waivers)
- **Views / Receives notification:** Member (receipt), School Admin (fine collection reports)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-043 | A fine can only be paid or waived if it is in Pending status. Fines that are already Paid or Waived cannot be modified. | Validation |
| BR-LIB-044 | The amount paid in a single payment cannot exceed the remaining unpaid balance of the fine. | Validation |
| BR-LIB-045 | Every fine payment must generate a unique receipt number. No two payments may share the same receipt number. | Validation |
| BR-LIB-046 | If the total amount paid plus the total amount waived equals the full fine amount, the fine status automatically changes to Paid. | Workflow / Calculation |
| BR-LIB-047 | The member's outstanding fine balance decreases by the amount paid or waived at the time the payment or waiver is recorded. | Calculation |
| BR-LIB-048 | Only a Library Supervisor may waive a fine. A Librarian cannot waive fines. A waiver requires a written reason to be entered before it can be saved. | Permission / Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can collect a cash payment, and the member's outstanding fine balance decreases correctly.
2. Collecting a partial payment leaves the fine in Pending status with the remaining balance correctly shown.
3. A fine waiver by a Library Supervisor records the reason and updates the fine to Waived status.
4. A fine that is already Paid cannot be paid again — the Pay button is disabled.
5. Every successful payment produces a receipt with a unique receipt number.

#### Integration with Other Modules
- Sends to: Accounting module (fine payment event for journal entry — future)
- Sends to: Student Fee module (fine-to-fee transfer option — future)

#### Enhancement Notes (Future)
- "Transfer to Fee Account" payment method — adds the fine to the student's outstanding fee balance instead of collecting cash at the library counter.
- Bulk fine waiver for a specific member or event (e.g., waive all fines incurred during a school trip period).

---

### 3.11 Digital Resource Management

**Requirement ID:** REQ-LIB-011
**Priority:** Standard (P1)
**Category Tags:** [DATA_ENTRY] [WORKFLOW] [CONFIGURATION]

#### Business Description
In addition to physical books, the library manages digital files — e-books, PDFs, audio files — associated with book titles. A Librarian uploads a digital file and associates it with an existing book title. Each digital resource can have license controls: a start and end date for the license period, and optionally a limit on how many users may access it concurrently. Access can be restricted by role, department, or designation. Members request access to a digital resource, and the Librarian approves or rejects the request. Once approved, the member can view online or download the file (subject to download permissions). The system tracks how many times each resource has been viewed and downloaded.

#### Actors
- **Initiates:** Librarian (uploads resource and sets license terms), Member (requests access)
- **Processes / Approves:** Librarian or Library Supervisor (approves or rejects access requests)
- **Views / Receives notification:** Member (notified of request approval or rejection)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-049 | A digital resource with an expired license date cannot be accessed or downloaded. The system blocks access automatically without manual intervention. | Validation |
| BR-LIB-050 | If a digital resource has a concurrent license limit set, the number of active access grants at any moment cannot exceed that limit. If the limit is reached, new access requests are queued. | Validation / Workflow |
| BR-LIB-051 | A member who is restricted from a digital resource (via access restriction rules) cannot request or be granted access to that resource. | Permission |
| BR-LIB-052 | A suspended library member cannot request digital resource access. | Validation |
| BR-LIB-053 | A student can only download a digital resource if the resource is marked as "student download allowed". The same applies to teachers and staff. | Permission |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can upload a digital file, set license dates, and the resource appears as available to eligible members.
2. A member whose access request is approved can view or download the resource.
3. Attempting to access a resource whose license has expired results in an "access not available" message.
4. The download count for a resource increments each time a member downloads it.

#### Integration with Other Modules
- Receives from: Media management system (file storage)
- Sends to: Notification module (request approval/rejection notification — future)

#### Enhancement Notes (Future)
- Online reader for PDFs within the browser without download.
- Automatic access revocation when a license expires, with notification to affected members.

---

### 3.12 Physical Inventory Audit

**Requirement ID:** REQ-LIB-012
**Priority:** Standard (P1)
**Category Tags:** [WORKFLOW] [DATA_ENTRY]

#### Business Description
Periodically, the library conducts a physical stock count to verify that every copy the system believes is on the shelf is actually there. A Librarian starts an audit session, which records the expected total number of copies. The Librarian then walks the shelves scanning each copy's barcode or RFID tag. The system compares each scanned copy's expected shelf location against where it was scanned. Copies not scanned by the end of the audit are classified as missing. Copies found at a different shelf are classified as misplaced. Copies in a worse condition than recorded are classified as damaged. At the end, the audit is marked complete and a discrepancy report is available.

#### Actors
- **Initiates:** Librarian
- **Processes / Approves:** Librarian (scanning), Library Supervisor (reviewing and closing)
- **Views / Receives notification:** School Admin / Principal (final audit summary)

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-054 | Only one inventory audit session may be in progress at any time. A new audit cannot be started until the current one is completed or cancelled. | Validation |
| BR-LIB-055 | At audit initialization, the expected count is calculated from all active, non-withdrawn physical copies in the system. This count is locked at the time of initialization and does not change during the audit. | Calculation |
| BR-LIB-056 | A copy scanned during an audit at a different location than its recorded shelf location is classified as Misplaced, not Missing. | Workflow |
| BR-LIB-057 | A completed or cancelled audit session is locked and cannot be modified or restarted. | Permission |

#### Acceptance Criteria
This feature is considered complete when:
1. A Librarian can start a new audit session only when no other session is currently in progress.
2. Scanning a copy whose system-recorded location does not match where it was scanned classifies it as Misplaced.
3. At audit completion, a summary shows the total scanned, total expected, missing count, misplaced count, and damaged count.
4. A completed audit session cannot be edited or reopened.

#### Integration with Other Modules
- None (self-contained)

#### Enhancement Notes (Future)
- RFID wand scanning mode for bulk scanning entire shelves in one pass.
- Automatic condition update for copies classified as Damaged during the audit.

---

### 3.13 Reporting & Analytics

**Requirement ID:** REQ-LIB-013
**Priority:** Standard (P1)
**Category Tags:** [REPORT] [DASHBOARD]

#### Business Description
The Library module provides a set of reports and a dashboard giving management and library staff insight into library performance. The dashboard displays real-time KPI cards for collection utilization, active members, current checkouts, overdue count, and fine collection totals. Detailed reports cover: circulation trends (which books are borrowed most, at what times, by whom), overdue books (who has what and how long), fine collection (totals by type and status), book acquisitions (how much was spent and what was added), digital resource usage (downloads and views), and reading behavior analytics (student reading goals and genre diversity). All reports can be filtered by date range and most can be exported to PDF.

#### Actors
- **Initiates:** Librarian, Library Supervisor, School Admin, Principal
- **Processes / Approves:** N/A (read-only reports)
- **Views / Receives notification:** All authorized roles

#### Business Rules

| Rule ID | Business Rule | Rule Type |
|---------|--------------|-----------|
| BR-LIB-058 | All reports must be filtered to the current school tenant's data only. No cross-school data may appear in any report. | Permission / Data |
| BR-LIB-059 | Reading behavior analytics (genre diversity, reading consistency scores) are calculated by a background process overnight. The dashboard displays the time of the last calculation. Real-time calculation for these metrics is not required. | Workflow |
| BR-LIB-060 | A report exported to PDF must produce a formatted, print-ready document that includes the school name, report name, date range, and page numbers. | Validation |

#### Acceptance Criteria
This feature is considered complete when:
1. The library dashboard loads in under 3 seconds and shows accurate KPI figures.
2. The circulation report correctly identifies the top 10 most-borrowed books for the selected date range.
3. The overdue report lists all members with unreturned books past their due date, with the number of days overdue and the estimated fine.
4. Any report can be exported to PDF and the resulting file is legible and properly formatted.

#### Integration with Other Modules
- Receives from: All other library features (reports aggregate data from catalog, transactions, fines, members, and digital resources)

#### Enhancement Notes (Future)
- Predictive demand report — AI-based projection of which books will be in demand next month.
- Collection health score — automated metric showing collection age, utilization, and diversity.

---

## Section 4 — Business Rules Register

| Rule ID | Description | Feature | Rule Type | Priority |
|---------|-------------|---------|-----------|----------|
| BR-LIB-001 | Resource type must specify whether items are borrowable; non-borrowable type blocks all copies from issue | REQ-LIB-001 | Validation | P0 |
| BR-LIB-002 | Default book conditions cannot be deleted; "not borrowable" condition blocks issue | REQ-LIB-001 | Validation / Permission | P0 |
| BR-LIB-003 | Membership type requires max books, loan period, and renewal permission — all mandatory | REQ-LIB-001 | Validation | P0 |
| BR-LIB-004 | Shelf location hierarchy must be built top-down (building → zone → floor → aisle → rack → shelf) | REQ-LIB-001 | Workflow | P1 |
| BR-LIB-005 | System fine types cannot be removed; custom fine types may be added | REQ-LIB-001 | Permission | P0 |
| BR-LIB-006 | Book title requires at least one author, category, and resource type | REQ-LIB-002 | Validation | P0 |
| BR-LIB-007 | ISBN must be unique across the catalog | REQ-LIB-002 | Validation | P0 |
| BR-LIB-008 | Reference-only books cannot be issued | REQ-LIB-002 | Workflow / Validation | P0 |
| BR-LIB-009 | Book title with active copies cannot be deleted | REQ-LIB-002 | Validation | P0 |
| BR-LIB-010 | Each copy must have a unique accession number and unique barcode | REQ-LIB-003 | Validation | P0 |
| BR-LIB-011 | Copy condition history is immutable — cannot be edited or deleted | REQ-LIB-003 | Workflow | P1 |
| BR-LIB-012 | Lost or Withdrawn copies cannot be issued | REQ-LIB-003 | Validation | P0 |
| BR-LIB-013 | Purchase invoice total must equal sum of item amounts plus tax | REQ-LIB-003 | Calculation | P1 |
| BR-LIB-014 | One library membership per school user — duplicates blocked | REQ-LIB-004 | Validation | P0 |
| BR-LIB-015 | Membership with outstanding fines or active issues cannot be deleted | REQ-LIB-004 | Validation | P1 |
| BR-LIB-016 | Expired / Suspended / Deactivated member cannot borrow books | REQ-LIB-004 | Workflow | P0 |
| BR-LIB-017 | Library card barcode must be unique across all members | REQ-LIB-004 | Validation | P0 |
| BR-LIB-018 | Member must be Active to check out a book | REQ-LIB-005 | Validation | P0 |
| BR-LIB-019 | Member cannot exceed their simultaneous borrowing limit | REQ-LIB-005 | Validation | P0 |
| BR-LIB-020 | Member with any overdue book is blocked from new checkouts | REQ-LIB-005 | Validation | P0 |
| BR-LIB-021 | Only Available copies can be issued | REQ-LIB-005 | Validation | P0 |
| BR-LIB-022 | "Not borrowable" condition copies cannot be issued | REQ-LIB-005 | Validation | P0 |
| BR-LIB-023 | Reference-only title copies cannot be issued | REQ-LIB-005 | Validation | P0 |
| BR-LIB-024 | Due date = issue date + membership type loan period days | REQ-LIB-005 | Calculation | P0 |
| BR-LIB-025 | Overdue days = (return date − due date) − grace period. If ≤ 0, no fine. | REQ-LIB-006 | Calculation | P0 |
| BR-LIB-026 | Condition degraded at return triggers damage fine assessment | REQ-LIB-006 | Workflow | P1 |
| BR-LIB-027 | Fine must be created before return can be completed if overdue days exist | REQ-LIB-006 | Workflow | P0 |
| BR-LIB-028 | After return, first-in-queue reservation is moved to Available and notified | REQ-LIB-006 | Workflow | P1 |
| BR-LIB-029 | Renewal requires membership type "renewals allowed" flag to be enabled | REQ-LIB-007 | Validation | P1 |
| BR-LIB-030 | Renewal blocked when renewal count equals maximum renewals for membership type | REQ-LIB-007 | Validation | P1 |
| BR-LIB-031 | Renewed due date = today + loan period days | REQ-LIB-007 | Calculation | P1 |
| BR-LIB-032 | Lost book or book with active reservations cannot be renewed without override | REQ-LIB-007 | Workflow | P1 |
| BR-LIB-033 | Member cannot have two active reservations for the same title | REQ-LIB-008 | Validation | P1 |
| BR-LIB-034 | Queue position assigned as next sequential number among active reservations for title | REQ-LIB-008 | Workflow | P1 |
| BR-LIB-035 | On book return, first-in-queue reservation automatically becomes Available | REQ-LIB-008 | Workflow | P1 |
| BR-LIB-036 | Reservation expires if not collected by pickup deadline; next in queue notified | REQ-LIB-008 | Workflow | P1 |
| BR-LIB-037 | Reservation cancellation triggers queue position resequencing for remaining members | REQ-LIB-008 | Workflow | P1 |
| BR-LIB-038 | Fine slab config must have at least one day-range detail row | REQ-LIB-009 | Validation | P0 |
| BR-LIB-039 | Day ranges within a slab must not overlap | REQ-LIB-009 | Validation | P0 |
| BR-LIB-040 | Highest priority slab is evaluated first when multiple slabs match | REQ-LIB-009 | Workflow | P0 |
| BR-LIB-041 | "Book Cost" cap type charges replacement cost, not a fixed rate | REQ-LIB-009 | Calculation | P1 |
| BR-LIB-042 | Only slabs whose effective dates include the return date are eligible | REQ-LIB-009 | Validation | P0 |
| BR-LIB-043 | Fine payment and waiver only allowed on Pending fines | REQ-LIB-010 | Validation | P0 |
| BR-LIB-044 | Payment amount cannot exceed remaining unpaid fine balance | REQ-LIB-010 | Validation | P0 |
| BR-LIB-045 | Every fine payment generates a unique receipt number | REQ-LIB-010 | Validation | P0 |
| BR-LIB-046 | When paid + waived = total fine amount, status auto-changes to Paid | REQ-LIB-010 | Workflow / Calculation | P0 |
| BR-LIB-047 | Member outstanding fine balance decreases on every payment or waiver | REQ-LIB-010 | Calculation | P0 |
| BR-LIB-048 | Only Library Supervisor can waive fines; written reason is mandatory | REQ-LIB-010 | Permission / Validation | P0 |
| BR-LIB-049 | Expired license date blocks access to digital resource automatically | REQ-LIB-011 | Validation | P1 |
| BR-LIB-050 | Concurrent license limit enforced — no new grants beyond the limit | REQ-LIB-011 | Validation / Workflow | P1 |
| BR-LIB-051 | Restricted members cannot request access to restricted digital resources | REQ-LIB-011 | Permission | P1 |
| BR-LIB-052 | Suspended member cannot request digital resource access | REQ-LIB-011 | Validation | P1 |
| BR-LIB-053 | Download permission per member type (student/teacher/staff) enforced per resource | REQ-LIB-011 | Permission | P1 |
| BR-LIB-054 | Only one inventory audit may be in progress at a time | REQ-LIB-012 | Validation | P1 |
| BR-LIB-055 | Expected count locked at audit initialization from active non-withdrawn copies | REQ-LIB-012 | Calculation | P1 |
| BR-LIB-056 | Copy found at wrong shelf = Misplaced (not Missing) | REQ-LIB-012 | Workflow | P1 |
| BR-LIB-057 | Completed or cancelled audit is locked and uneditable | REQ-LIB-012 | Permission | P1 |
| BR-LIB-058 | All reports scoped to current school tenant only | REQ-LIB-013 | Permission / Data | P0 |
| BR-LIB-059 | Reading behavior analytics computed overnight; dashboard shows last-calculated timestamp | REQ-LIB-013 | Workflow | P2 |
| BR-LIB-060 | PDF exports must include school name, report name, date range, and page numbers | REQ-LIB-013 | Validation | P1 |

---

## Section 5 — Data Requirements

### 5.1 Book Title (Catalog Record)

**What it represents:** The authoritative record for one published work — a book, journal, e-book, or audio resource — that the library holds or provides access to.

**Key information captured:**
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Title | The full name of the work | Yes | Searchable |
| Subtitle | Additional title line | No | |
| ISBN | International Standard Book Number | No | Must be unique if provided |
| Author(s) | One or more authors linked to their author profiles | Yes | Many-to-many; one marked as primary |
| Publisher | The publishing company | Yes | Selected from publisher master |
| Publication Year | Year of publication | No | |
| Language | Language of the book | Yes | |
| Resource Type | Physical book, e-book, audio, etc. | Yes | Drives borrowing rules |
| Category | Hierarchical classification | Yes | Many-to-many |
| Genre | Literary genre tags | No | Many-to-many |
| Keywords | Searchable index tags | No | Many-to-many |
| Reference Only | Whether the book can be borrowed | No | Default: borrowable |
| Academic Subject Mapping | Class and subject the book is relevant to | No | Supports curriculum alignment |
| Cover Image | A photo or thumbnail of the book cover | No | |

**Relationships:**
- Contains: Book Copies (one title → many physical copies)
- Contains: Digital Resources (one title → many digital files)
- Connected to: Authors, Categories, Genres, Keywords, Publishers, Resource Types

**Data Retention:**
Book title records are retained indefinitely even if they have no active copies. Soft-deletion only — records can be restored. Titles with outstanding transactions are not deletable.

**Privacy Classification:** Internal

---

### 5.2 Book Copy

**What it represents:** A single physical instance of a book title, tracked individually from purchase through its entire lifecycle.

**Key information captured:**
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Accession Number | The library's unique sequential identifier for this copy | Yes | Unique; auto-generated or manual |
| Barcode | Scannable barcode for circulation desk use | Yes | Unique |
| RFID Tag | Radio-frequency identifier for scanner-based workflows | No | Unique if provided |
| Shelf Location | Where this copy is physically stored | No | Zone → Floor → Aisle → Rack → Shelf |
| Current Condition | The copy's current physical state | Yes | From book conditions master |
| Book Title | The title this copy belongs to | Yes | |
| Status | Current availability state | Yes | Available, Issued, Reserved, Under Maintenance, Lost, Withdrawn |
| Lost Flag | Whether this copy has been reported lost | No | Blocks issue when true |
| Withdrawn Flag | Whether this copy has been removed from circulation | No | Blocks issue when true |
| Purchase Link | Reference to the purchase order that brought this copy in | No | |

**Relationships:**
- Belongs to: Book Title
- Contains: Condition History records
- Connected to: Transactions (one copy → many transactions over time)

**Data Retention:**
Copy records are retained indefinitely for historical reporting. Lost or Withdrawn copies are soft-deleted, not removed.

**Privacy Classification:** Internal

---

### 5.3 Library Member

**What it represents:** A school system user who has been formally registered for library membership and is eligible to borrow books and access resources.

**Key information captured:**
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Linked User | The school system user this membership belongs to | Yes | One-to-one; unique |
| Membership Number | The library's unique identifier for this member | Yes | Auto-generated or manual |
| Library Card Barcode | The barcode on the member's physical library card | Yes | Used for scan-based checkout |
| Membership Type | Determines borrowing limits and fine rates | Yes | |
| Member Category | Student, Teacher, or Staff | Yes | |
| Registration Date | When membership was created | Yes | |
| Expiry Date | When membership expires | Yes | |
| Status | Active, Expired, Suspended, or Deactivated | Yes | |
| Outstanding Fine Balance | Total unpaid fine amount on this member's account | Yes | Updated automatically |
| Total Books Borrowed | Lifetime cumulative borrow count | No | Informational |

**Relationships:**
- Belongs to: School System User
- Belongs to: Membership Type
- Contains: Transactions (all borrow/return records for this member)
- Contains: Fines (all penalty records for this member)
- Contains: Reservations (all current and past holds for this member)

**Data Retention:**
Member records are retained indefinitely for audit purposes. Members with outstanding fines cannot be deleted.

**Privacy Classification:** Internal

---

### 5.4 Book Transaction (Circulation Record)

**What it represents:** A record of one borrowing event — a specific copy issued to a specific member on a specific date, tracking the full lifecycle from issue to return.

**Key information captured:**
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Book Title | The title borrowed | Yes | |
| Book Copy | The specific copy issued | Yes | |
| Member | The member who borrowed it | Yes | |
| Issue Date | When the book was handed out | Yes | |
| Due Date | When the book must be returned | Yes | Calculated from issue date + loan period |
| Return Date | When the book was actually returned | No | Blank until returned |
| Issued By | The librarian who processed the issue | Yes | |
| Received By | The librarian who processed the return | No | |
| Condition at Issue | Book's condition when it left the library | Yes | |
| Condition at Return | Book's condition when it came back | No | Used for damage fine assessment |
| Status | Issued, Returned, Overdue, or Lost | Yes | |
| Renewal Count | How many times this transaction has been renewed | No | |

**Relationships:**
- Belongs to: Book Copy, Book Title, Library Member
- Contains: Transaction History entries (immutable audit log)
- Connected to: Fines (a transaction may generate a fine on return)

**Data Retention:**
All transaction records are retained permanently. They form the primary audit trail of library operations.

**Privacy Classification:** Internal

---

### 5.5 Fine Record

**What it represents:** A financial penalty levied against a member for a late return, lost book, damaged book, or processing fee.

**Key information captured:**
| Information | What it stores | Required? | Notes |
|-------------|---------------|-----------|-------|
| Transaction | The borrowing event that triggered this fine | Yes (unless a direct charge) | |
| Member | The member being fined | Yes | |
| Fine Type | Late Return, Lost Book, Damaged Book, or Processing Fee | Yes | |
| Fine Amount | The total amount charged | Yes | Calculated by fine slab engine |
| Days Overdue | Number of overdue days used in the calculation | No | For late return fines |
| Calculation Breakdown | The detailed day-range calculation used to arrive at the amount | No | Stored for auditability |
| Status | Pending, Paid, Waived, or Overdue | Yes | |
| Waived Amount | Amount forgiven by Library Supervisor | No | |
| Waiver Reason | Written explanation for the waiver | No | Required if waived |

**Relationships:**
- Belongs to: Library Member, Transaction
- Contains: Fine Payments (one fine → many partial payments possible)

**Data Retention:**
Fine records are retained permanently. Payment receipts must be available for audit.

**Privacy Classification:** Confidential

---

## Section 6 — Workflows

### 6.1 Book Issue and Return Workflow

**Trigger:** A member arrives at the library counter with a book to borrow or return.
**End State:** The copy's status reflects the outcome (Issued after checkout; Available after return). Any applicable fine is on record.

#### Steps

1. **Member Verification**: Librarian scans the member's library card barcode.
   - System retrieves member profile, status, outstanding fines, and current borrow count.
   - Decision: If member is not Active, or has overdue books, or has exceeded their borrow limit → show block message; end workflow.

2. **Book Verification** (for issue): Librarian scans the book copy's barcode.
   - System retrieves copy status, title, and condition.
   - Decision: If copy is not Available, or is reference-only, or is in a non-borrowable condition → show block message; end workflow.

3. **Issue Processing**: Librarian confirms the issue.
   - System creates a transaction record (member, copy, issue date, due date, condition at issue).
   - Copy status changes to Issued.
   - Member's borrow count increases by one.

4. **Return Verification** (for return): Librarian scans the returning copy or locates the open transaction.
   - System displays transaction details, due date, and days overdue (if any).

5. **Return Condition Assessment**: Librarian selects the book's current condition.
   - Decision: If condition is worse than at issue → prompt Librarian to assess damage fine.

6. **Fine Assessment**: System calculates applicable fine using matching slab configuration.
   - Decision: If overdue days > 0 → system shows fine amount; Librarian confirms or adjusts.
   - Fine record created with Pending status; member's outstanding balance increases.

7. **Return Completion**: System records the return date, updates the transaction to Returned, and sets the copy status to Available.
   - System checks reservation queue for this title and flags the first-in-queue member's reservation as Available.

#### Exception Paths
- If the copy barcode is not found: Librarian is shown an error and must verify the accession number manually.
- If the member has an outstanding balance that blocks new issues: Librarian can choose to collect the fine first before processing the new issue.

#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| After Step 3 (Issue) | Member | Confirmation of issue with due date |
| After Step 7 (Return — if reservation exists) | Next member in reservation queue | "The book you reserved is now available. Please collect by [pickup deadline]." |

---

### 6.2 Fine Collection Workflow

**Trigger:** A member with a Pending fine arrives at the library counter or a Librarian initiates fine collection.
**End State:** The fine is fully paid (status: Paid) or partially paid (status: Pending with reduced balance).

#### Steps

1. **Fine Selection**: Librarian opens the member's fine record.
   - System shows fine type, total amount, amount already paid, amount waived, and remaining balance.

2. **Payment Entry**: Librarian enters the payment amount, selects payment method (Cash, Card, Online), and enters a reference number if Online.
   - Decision: If amount entered exceeds remaining balance → block with validation error.

3. **Payment Processing**: System creates a payment record with a unique auto-generated receipt number.
   - Member's outstanding fine balance decreases by the amount paid.
   - Decision: If total paid + total waived = full fine amount → fine status automatically changes to Paid.

4. **Receipt Generation**: System makes a receipt available for printing or sharing with the member.

#### Exception Paths
- If member disputes the fine amount: Librarian escalates to Library Supervisor for waiver consideration.
- If member cannot pay in full: Partial payment is accepted; fine remains Pending until the balance is cleared.

#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| After Step 4 | Member | Payment receipt confirmation with receipt number |

---

### 6.3 Reservation Queue Workflow

**Trigger:** A member requests a hold on a book title where all copies are currently checked out.
**End State:** The member either collects the book (status: Picked Up) or the reservation expires/is cancelled.

#### Steps

1. **Hold Request**: Member or Librarian places a reservation for a title.
   - System checks if the member already has an active reservation for the same title.
   - Decision: If duplicate → block with message "Member already has an active reservation for this title."
   - System assigns the next queue position number.

2. **Wait Period**: Reservation sits in Pending status. The member can see their queue position.

3. **Copy Becomes Available**: A copy of the reserved title is returned (see Section 6.1, Step 7).
   - System automatically changes the first-in-queue reservation to Available.
   - System sets a pickup deadline (configurable, default: 3 days from notification).
   - System sends notification to the member.

4. **Collection**: Member comes to the library and collects the book.
   - Librarian marks the reservation as Picked Up and processes the issue transaction.

5. **Pickup Deadline Expiry** (exception): If the pickup deadline passes without collection:
   - Reservation status changes to Expired automatically.
   - Next member in queue moves to position 1 and the process repeats from Step 3.

#### Exception Paths
- If member cancels reservation: Status changes to Cancelled; all members with higher queue positions move up by one.

#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| Step 3 | Reserved member | "Your reserved copy of [title] is now available. Please collect by [pickup deadline]." |
| Step 5 (expiry) | Next member in queue | "Your reserved copy of [title] is now available." |

---

### 6.4 Inventory Audit Workflow

**Trigger:** Library Supervisor or Librarian initiates a periodic physical stock count.
**End State:** Audit session is marked Complete with a full discrepancy report.

#### Steps

1. **Session Initialization**: Librarian starts a new audit session.
   - System verifies no other audit is currently in progress.
   - System calculates and locks the expected total count from all active non-withdrawn copies.

2. **Shelf Scanning**: Librarian walks the shelves scanning copy barcodes or RFID tags.
   - For each scan, the system retrieves the copy's expected shelf location.
   - If scanned location matches expected → copy classified as Found.
   - If scanned location differs → copy classified as Misplaced.
   - If condition is worse than recorded → copy classified as Damaged.

3. **Missing Identification**: At session completion, any copy not scanned is automatically classified as Missing.

4. **Audit Completion**: Librarian or Library Supervisor marks the session as Complete.
   - System generates a summary: total expected, total scanned, found, missing, misplaced, and damaged counts.

5. **Post-Audit Actions**: Library staff follow up on discrepancies — locate missing books, update misplaced copies' shelf records, and process damage fines for damaged copies.

#### Exception Paths
- If the audit session needs to be abandoned: It is Cancelled; its data is preserved for reference but no further scanning is permitted.

#### Notifications Triggered
| At Step | Who Receives | Message Summary |
|---------|-------------|-----------------|
| Step 4 (Complete) | Library Supervisor, School Admin | Summary report of audit discrepancies |

---

## Section 7 — Reporting & Analytics Requirements

### 7.1 Library Dashboard

**Report ID:** RPT-LIB-001
**Purpose:** Give Librarians, Library Supervisors, and School Administrators an at-a-glance view of library health without running individual reports.
**Primary Audience:** Librarian, School Admin / Principal
**Frequency of Use:** Daily

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Active Members | Total members with Active membership status |
| Books Currently Issued | Number of copies with Issued or Overdue status |
| Overdue Count | Number of transactions past their due date |
| Total Fines Pending | Sum of all pending (unpaid) fine amounts |
| Total Fines Collected (Today / This Month) | Fine payment totals for the selected period |
| Collection Utilization % | Percentage of total active copies currently out on loan |
| Reservations in Queue | Total active Pending reservations across all titles |
| New Acquisitions (This Month) | Number of new copies added in the current month |

#### Filters Available
- By Academic Year: Filter KPIs to the selected school year
- By Student Class: Filter member-related KPIs to a specific class

#### Export Options
- [x] Print (PDF)
- [ ] Download to Excel
- [x] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| Tenant isolation | All figures are scoped to the current school's data only |
| Reading analytics lag | Student reading behavior metrics (genre diversity, reading goals) are from the last overnight calculation run, not real-time |

---

### 7.2 Circulation Analysis Report

**Report ID:** RPT-LIB-002
**Purpose:** Understand how actively the library collection is being used — which books are most popular, which membership categories borrow most, and when peak usage occurs.
**Primary Audience:** Library Supervisor, School Admin
**Frequency of Use:** Weekly / Monthly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Total Issues | Number of checkout transactions in the period |
| Total Returns | Number of return transactions in the period |
| Average Loan Duration | Mean number of days books were held |
| Peak Borrowing Day | Day of the week with the highest checkout volume |
| Top 10 Most Borrowed Books | Book titles ranked by issue count |
| Issues by Membership Category | Breakdown of checkouts by Student vs Teacher vs Staff |
| Category-wise Analysis | Checkout volume grouped by book category |
| Monthly Trend (12 months) | Month-by-month issue and return counts |

#### Filters Available
- By Date Range: Default last 30 days; selectable start and end date
- By Membership Category: Student, Teacher, Staff, or All

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| Date range default | Default view is last 30 days |
| Large dataset warning | Reports covering more than 12 months with very high transaction volumes may take longer than 10 seconds to generate |

---

### 7.3 Overdue Report

**Report ID:** RPT-LIB-003
**Purpose:** Identify all members who have books past their due date so that the library can follow up and recover overdue items.
**Primary Audience:** Librarian, Library Supervisor
**Frequency of Use:** Daily

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Member Name | Name of the member holding the overdue book |
| Member Category | Student, Teacher, or Staff |
| Class (for students) | Student's class |
| Book Title | Title of the overdue book |
| Issue Date | When the book was checked out |
| Due Date | When it should have been returned |
| Days Overdue | Number of days past the due date |
| Estimated Fine | Fine amount if the book were returned today |

#### Filters Available
- By Number of Days Overdue: Show books overdue for more than N days
- By Membership Category: Student, Teacher, or All

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| Estimated fine | Calculated using the applicable fine slab but not yet recorded as a fine record |
| Real-time | Overdue list reflects current state at the time of report generation |

---

### 7.4 Fine Collection Report

**Report ID:** RPT-LIB-004
**Purpose:** Track how much fine revenue the library has collected, what is pending, and what has been waived in a given period.
**Primary Audience:** Library Supervisor, School Admin
**Frequency of Use:** Monthly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Total Fines Raised | Sum of all fines created in the period |
| Total Collected | Sum of fine payments received |
| Total Waived | Sum of fine amounts waived |
| Total Pending | Remaining uncollected fine balance |
| By Fine Type | Breakdown by Late Return, Lost Book, Damaged Book, Processing Fee |
| Top 10 Members by Outstanding Balance | Members with the highest unpaid fines |

#### Filters Available
- By Date Range: Report period start and end date
- By Fine Type: All, Late Return, Lost Book, Damaged Book, Processing Fee
- By Membership Category: Student, Teacher, Staff, or All

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| Waived amounts | Waivers appear as a reduction in collected revenue |
| Partial payments | Members with partial payments show the remaining balance under Pending |

---

### 7.5 Acquisition Report

**Report ID:** RPT-LIB-005
**Purpose:** Show what new books were added to the library collection in a period, how much was spent, and which categories were expanded.
**Primary Audience:** Library Supervisor, School Admin / Principal
**Frequency of Use:** Monthly / Quarterly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Total Titles Added | Count of new book titles entered in the catalog |
| Total Copies Added | Count of new physical copies registered |
| Total Amount Spent | Sum of all purchase invoice net amounts |
| Additions by Category | New titles grouped by category |
| Additions by Vendor | New copies grouped by the vendor they were purchased from |
| Month-wise Trend | Monthly acquisition spending for the period |

#### Filters Available
- By Date Range: Purchase bill date range
- By Category: Filter to a specific book category
- By Vendor: Filter to a specific vendor

#### Export Options
- [x] Print (PDF)
- [x] Download to Excel
- [x] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| Vendor link | Report shows vendor names from the vendor module's master data |

---

### 7.6 Digital Resource Usage Report

**Report ID:** RPT-LIB-006
**Purpose:** Show how digital resources are being used — which files are most accessed, how many downloads have occurred, and which licenses are expiring soon.
**Primary Audience:** Librarian, Library Supervisor
**Frequency of Use:** Monthly

#### Report Contents

| Column / KPI | What It Shows |
|--------------|---------------|
| Total Digital Resources | Count of active digital files in the library |
| Total Downloads | Cumulative download count across all resources |
| Total Online Views | Cumulative view count across all resources |
| Most Downloaded Resources | Top 10 digital files by download count |
| License Expiring Soon | Resources whose license end date is within the next 30 days |
| Licenses Already Expired | Resources whose license has already passed its end date |

#### Filters Available
- By Date Range: Filter download/view events to a period
- By Resource Type: E-book, PDF, Audio, or All
- By License Status: Active, Expiring Soon, Expired

#### Export Options
- [x] Print (PDF)
- [ ] Download to Excel
- [x] On-screen only

#### Business Rules for This Report
| Rule | Description |
|------|-------------|
| License expiry alert | Resources expiring within 30 days are highlighted in the report |

---

## Section 8 — Future Enhancement Log

| Enhancement ID | Requested Feature | Reason / Business Value | Requested By | Priority | Status |
|----------------|------------------|------------------------|--------------|----------|--------|
| ENH-LIB-001 | Add EnsureTenantHasModule security gate to library routes | Schools without Library license should be blocked from accessing library screens; currently any authenticated user can reach library pages | Technical Audit | P0 | Backlog |
| ENH-LIB-002 | Add authorization gates to 6 unprotected screens (hub, dashboard, reports, fine management) | Financial operations (fine waiver) are currently accessible to any authenticated user — this is a security risk | Technical Audit | P0 | Backlog |
| ENH-LIB-003 | Automated daily scheduled jobs — overdue reminder dispatch, reservation expiry, membership expiry | Currently all three of these rely on manual librarian action; automating them would ensure the system self-maintains | Technical Team | P1 | Backlog |
| ENH-LIB-004 | Barcode / QR scan-first checkout workflow | Currently the librarian types barcode numbers; a physical scanner workflow would allow scan-in, scan-book, press confirm — much faster at busy periods | Librarians | P1 | Backlog |
| ENH-LIB-005 | Student Portal integration — student can browse catalog and place reservations themselves | Currently only librarians can create reservations on behalf of students; self-service would reduce counter load | Students / Management | P1 | Backlog |
| ENH-LIB-006 | Grace period enforcement in fine calculation | The grace period days field exists in membership type configuration but is not yet subtracted from overdue days in the fine calculation engine | Technical Audit | P1 | Backlog |
| ENH-LIB-007 | Digital resource license enforcement (auto-block expired licenses) | Currently a resource with an expired license is still accessible; system should block access automatically at license end date | Technical Audit | P1 | Backlog |
| ENH-LIB-008 | Notification module wiring for reservation availability | The reservation queue correctly identifies the next member, but the actual SMS/email notification is not dispatched yet | Technical Audit | P1 | Backlog |
| ENH-LIB-009 | Member segment algorithm | The membership profile has fields for engagement score and member segment (High-Value, At-Risk, Inactive, New) but the algorithm to calculate these has not been implemented | Analytics Team | P2 | Backlog |
| ENH-LIB-010 | OPAC — open catalog search for students and staff | A public-facing catalog search where students can search for available books from any screen without full library access | Students | P2 | Backlog |
| ENH-LIB-011 | TransactionService, ReservationService, FineCalculationService | Business logic is embedded in screen controllers; extracting it to dedicated service classes would enable unit testing and improve maintainability | Technical Team | P2 | Backlog |
| ENH-LIB-012 | Syllabus Books module integration | The catalog already has academic subject mapping fields; wiring these to the Syllabus Books module would allow librarians to see which books are on this term's prescribed reading list | Teachers / Librarians | P2 | Backlog |
| ENH-LIB-013 | Reading behavior analytics — student reading goals, genre diversity scoring | A nightly background computation of each student's reading consistency and genre diversity index, visible on the dashboard | Management | P2 | Backlog |
| ENH-LIB-014 | Book popularity trend tracking | Daily automated tracking of which books are being requested, reserved, and borrowed most — feeds into acquisition recommendations | Management | P3 | Backlog |
| ENH-LIB-015 | AI metadata enrichment — auto-generated summaries and keyword extraction for new books | When a new book is added to the catalog, AI generates a summary and key concept tags to improve catalog discoverability | Technical Team | P3 | Backlog |

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance Expectations

| Requirement | Standard |
|-------------|---------|
| Library dashboard load time | Loads within 3 seconds for up to 500 concurrent school users |
| Catalog search results | Returns results within 2 seconds for a catalog of up to 10,000 titles |
| Book issue transaction | Completes and confirms within 1 second of submission |
| Standard report generation | Completes within 10 seconds for date ranges up to 6 months |
| Fine calculation (slab lookup) | Completes within 200 milliseconds |
| Inventory audit copy scan | Each barcode lookup returns within 500 milliseconds |
| ISBN auto-lookup | Returns title data within 3 seconds from external source; graceful error if unavailable |

### 9.2 Security Requirements (Business Language)

| Requirement | Rule |
|-------------|------|
| School license gate | Only schools that have the Library module included in their subscription plan may access library screens |
| Access control | Every screen must be accessible only to users with the correct assigned role and permission |
| Data isolation | School A's library data (books, members, transactions, fines) must never be visible to School B |
| Audit trail | Every book issue, return, renewal, fine creation, payment, and waiver must record who performed the action and when |
| Financial operations | Fine waiver is a financial operation and must require Library Supervisor authorization — not accessible to Librarians |
| Input validation | All data entered through library forms must be validated on the server before being saved — unvalidated input is not accepted |

### 9.3 Usability Requirements

| Requirement | Standard |
|-------------|---------|
| Mobile access | Librarian's circulation screens (issue, return) must function on tablet browsers used at the circulation desk |
| Language | All screen labels and messages in English; Hindi and regional language support is a future enhancement |
| Scan support | All barcode input fields must accept input from a standard USB barcode scanner (keyboard wedge mode) without special configuration |
| Offline resilience | If the ISBN lookup external service is unavailable, the system must allow manual entry of all fields without blocking the librarian |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Requirement Coverage Summary

| Requirement ID | Feature Name | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---------------|-------------|---------|------|------------------|---------------|------------|--------------------|--------------------|
| REQ-LIB-001 | Library Configuration Setup | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-LIB-002 | Book Catalog Management | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-LIB-003 | Book Acquisition & Copy Registration | P0 | DATA_ENTRY, WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-LIB-004 | Library Member Registration & Management | P0 | DATA_ENTRY, CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-LIB-005 | Book Issue (Checkout) | P0 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | Yes | Yes |
| REQ-LIB-006 | Book Return (Check-In) | P0 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | Yes | Yes |
| REQ-LIB-007 | Book Renewal | P1 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-LIB-008 | Book Reservation (Hold Queue) | P1 | WORKFLOW, NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-LIB-009 | Fine Calculation Setup | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-LIB-010 | Fine Collection & Waiver | P0 | WORKFLOW, DATA_ENTRY, APPROVAL | Yes | Yes | No | Yes | Yes |
| REQ-LIB-011 | Digital Resource Management | P1 | DATA_ENTRY, WORKFLOW, CONFIGURATION | Yes | Yes | No | Yes | Yes |
| REQ-LIB-012 | Physical Inventory Audit | P1 | WORKFLOW, DATA_ENTRY | Yes | Yes | No | Yes | Yes |
| REQ-LIB-013 | Reporting & Analytics | P1 | REPORT, DASHBOARD | No | Yes | No | No | Yes |

### 10.2 Business Rules Coverage Summary

| Rule ID | Rule Summary | Feature Ref | Validation Required | Data Check Required | Workflow Gate |
|---------|-------------|-------------|--------------------|--------------------|---------------|
| BR-LIB-001 | Non-borrowable resource type blocks issue | REQ-LIB-001 | Yes | Yes | Yes |
| BR-LIB-002 | Default conditions protected; not-borrowable blocks issue | REQ-LIB-001 | Yes | Yes | No |
| BR-LIB-003 | Membership type requires 3 mandatory fields | REQ-LIB-001 | Yes | No | No |
| BR-LIB-004 | Shelf hierarchy is top-down only | REQ-LIB-001 | Yes | Yes | No |
| BR-LIB-005 | System fine types cannot be deleted | REQ-LIB-001 | No | Yes | Yes |
| BR-LIB-006 | Book title requires author, category, resource type | REQ-LIB-002 | Yes | No | No |
| BR-LIB-007 | ISBN unique across catalog | REQ-LIB-002 | Yes | Yes | No |
| BR-LIB-008 | Reference-only blocks issue | REQ-LIB-002 | No | Yes | Yes |
| BR-LIB-009 | Title with active copies cannot be deleted | REQ-LIB-002 | No | Yes | Yes |
| BR-LIB-010 | Unique accession number and barcode per copy | REQ-LIB-003 | Yes | Yes | No |
| BR-LIB-011 | Copy condition history is immutable | REQ-LIB-003 | No | No | Yes |
| BR-LIB-012 | Lost/Withdrawn copies cannot be issued | REQ-LIB-003 | No | Yes | Yes |
| BR-LIB-013 | Purchase total = sum of line items + tax | REQ-LIB-003 | Yes | No | No |
| BR-LIB-014 | One membership per user | REQ-LIB-004 | Yes | Yes | No |
| BR-LIB-015 | Membership with active items/fines cannot be deleted | REQ-LIB-004 | No | Yes | Yes |
| BR-LIB-016 | Non-Active member cannot borrow | REQ-LIB-004 | No | Yes | Yes |
| BR-LIB-017 | Library card barcode unique per school | REQ-LIB-004 | Yes | Yes | No |
| BR-LIB-018 | Active status required for checkout | REQ-LIB-005 | Yes | Yes | Yes |
| BR-LIB-019 | Borrow limit enforced | REQ-LIB-005 | Yes | Yes | Yes |
| BR-LIB-020 | Overdue books block new checkouts | REQ-LIB-005 | No | Yes | Yes |
| BR-LIB-021 | Only Available copies can be issued | REQ-LIB-005 | No | Yes | Yes |
| BR-LIB-022 | Not-borrowable condition blocks issue | REQ-LIB-005 | No | Yes | Yes |
| BR-LIB-023 | Reference-only blocks issue | REQ-LIB-005 | No | Yes | Yes |
| BR-LIB-024 | Due date calculation | REQ-LIB-005 | Yes | No | No |
| BR-LIB-025 | Overdue days calculation with grace | REQ-LIB-006 | Yes | No | No |
| BR-LIB-026 | Condition change triggers damage fine | REQ-LIB-006 | No | Yes | Yes |
| BR-LIB-027 | Fine must be created before return completed | REQ-LIB-006 | No | Yes | Yes |
| BR-LIB-028 | After return, first reservation gets Available | REQ-LIB-006 | No | Yes | Yes |
| BR-LIB-029 | Renewals require membership type permission | REQ-LIB-007 | No | Yes | Yes |
| BR-LIB-030 | Max renewal count enforced | REQ-LIB-007 | No | Yes | Yes |
| BR-LIB-031 | Renewal due date calculation | REQ-LIB-007 | Yes | No | No |
| BR-LIB-032 | Lost/reserved book blocks renewal | REQ-LIB-007 | No | Yes | Yes |
| BR-LIB-033 | One active reservation per member per title | REQ-LIB-008 | Yes | Yes | No |
| BR-LIB-034 | Queue position sequential assignment | REQ-LIB-008 | No | Yes | No |
| BR-LIB-035 | First in queue gets Available on return | REQ-LIB-008 | No | Yes | Yes |
| BR-LIB-036 | Reservation expires if not collected by deadline | REQ-LIB-008 | No | Yes | Yes |
| BR-LIB-037 | Queue resequenced on cancellation | REQ-LIB-008 | No | Yes | Yes |
| BR-LIB-038 | Fine slab needs at least one day-range row | REQ-LIB-009 | Yes | No | No |
| BR-LIB-039 | Day ranges must not overlap | REQ-LIB-009 | Yes | No | No |
| BR-LIB-040 | Highest priority slab evaluated first | REQ-LIB-009 | No | Yes | Yes |
| BR-LIB-041 | Book Cost cap type uses replacement value | REQ-LIB-009 | No | Yes | Yes |
| BR-LIB-042 | Only slabs within effective dates are applied | REQ-LIB-009 | No | Yes | Yes |
| BR-LIB-043 | Payment/waiver only on Pending fines | REQ-LIB-010 | No | Yes | Yes |
| BR-LIB-044 | Payment amount ≤ remaining balance | REQ-LIB-010 | Yes | Yes | No |
| BR-LIB-045 | Unique receipt number per payment | REQ-LIB-010 | Yes | Yes | No |
| BR-LIB-046 | Fine auto-completes to Paid when balance reaches zero | REQ-LIB-010 | No | Yes | Yes |
| BR-LIB-047 | Member balance decreases on payment/waiver | REQ-LIB-010 | No | Yes | No |
| BR-LIB-048 | Only Supervisor can waive; reason required | REQ-LIB-010 | Yes | No | Yes |
| BR-LIB-049 | Expired license blocks digital access | REQ-LIB-011 | No | Yes | Yes |
| BR-LIB-050 | Concurrent license limit enforced | REQ-LIB-011 | No | Yes | Yes |
| BR-LIB-051 | Restricted members blocked from restricted resources | REQ-LIB-011 | No | Yes | Yes |
| BR-LIB-052 | Suspended member blocked from digital access | REQ-LIB-011 | No | Yes | Yes |
| BR-LIB-053 | Download permissions per member type | REQ-LIB-011 | No | Yes | Yes |
| BR-LIB-054 | One audit in progress at a time | REQ-LIB-012 | No | Yes | Yes |
| BR-LIB-055 | Expected count locked at initialization | REQ-LIB-012 | No | Yes | No |
| BR-LIB-056 | Wrong-shelf scan = Misplaced | REQ-LIB-012 | No | Yes | No |
| BR-LIB-057 | Completed/cancelled audit is read-only | REQ-LIB-012 | No | Yes | Yes |
| BR-LIB-058 | Reports scoped to current school only | REQ-LIB-013 | No | Yes | Yes |
| BR-LIB-059 | Reading analytics are overnight computed | REQ-LIB-013 | No | No | No |
| BR-LIB-060 | PDF exports require school name, dates, page numbers | REQ-LIB-013 | Yes | No | No |

### 10.3 Report Coverage Summary

| Report ID | Report Name | Priority | Filters Count | Export Needed |
|-----------|------------|---------|---------------|---------------|
| RPT-LIB-001 | Library Dashboard | P0 | 2 | Yes |
| RPT-LIB-002 | Circulation Analysis Report | P1 | 2 | Yes |
| RPT-LIB-003 | Overdue Report | P0 | 2 | Yes |
| RPT-LIB-004 | Fine Collection Report | P1 | 3 | Yes |
| RPT-LIB-005 | Acquisition Report | P1 | 3 | Yes |
| RPT-LIB-006 | Digital Resource Usage Report | P2 | 3 | Yes |

### 10.4 Total Scope Numbers

| Category | Count |
|----------|-------|
| Total Functional Requirements (REQ-) | 13 |
| Total Business Rules (BR-) | 60 |
| Total Workflows defined | 4 |
| Total Reports required | 6 |
| Total Enhancements logged | 15 |
| Total P0 (Core) Requirements | 6 |
| Total P1 (Standard) Requirements | 7 |
| Total P2 (Enhanced) Requirements | 0 |

---

## Document Control

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-06-25 | Initial draft — synthesized from preliminary requirements (31 screens), Library DDL v7 (35 tables), V2 technical requirement document, and overview architecture document | Business Analysis — Prime-AI |

---

*This FRD is the single source of truth for Library module requirements.*
*All gap analyses, completion scoring, and test coverage must reference this document.*
*For technical implementation details, refer to Library_DDL_v7.sql and the Library module source code.*
