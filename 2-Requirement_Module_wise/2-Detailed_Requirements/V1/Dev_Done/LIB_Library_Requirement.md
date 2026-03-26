# Library Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** LIB | **Module Path:** `Modules/Library`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `lib_*` (Note: RBS reference uses `bok_*` prefix; actual DDL and code use `lib_*`)
**Processing Mode:** FULL
**RBS Reference:** Module M — Library Management

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Database Schema](#6-database-schema)
7. [API and Routes](#7-api-and-routes)
8. [Business Rules](#8-business-rules)
9. [Authorization and RBAC](#9-authorization-and-rbac)
10. [Service Layer Architecture](#10-service-layer-architecture)
11. [Integration Points](#11-integration-points)
12. [Test Coverage](#12-test-coverage)
13. [Implementation Status](#13-implementation-status)
14. [Known Issues and Technical Debt](#14-known-issues-and-technical-debt)
15. [Development Priorities and Recommendations](#15-development-priorities-and-recommendations)

---

## 1. Module Overview

The Library module is a comprehensive school library management system for Indian K-12 schools operating on the Prime-AI SaaS ERP platform. It manages the complete lifecycle of physical and digital library resources — from catalog management and member enrollment to book circulation, fine collection, inventory auditing, and analytics reporting.

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Library |
| Module Code | LIB |
| nwidart Module Namespace | `Modules\Library` |
| Module Path | `Modules/Library` |
| Route Prefix | `library/` |
| Route Name Prefix | `library.` |
| DB Table Prefix | `lib_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` (lines 2920–3170) |
| Module routes/web.php | All routes commented out — superseded by tenant.php registration |

### 1.2 Module Scale

| Metric | Count |
|---|---|
| Controllers | 27 (26 domain + 1 base LibraryController hub) |
| Models | 35 |
| Services | 9 |
| FormRequests | 19 |
| Policies | 21 |
| Browser Tests | 15 |
| DDL Tables | 34 |
| Views | ~120 Blade templates |

---

## 2. Business Context

### 2.1 Business Purpose

Indian school libraries are a central academic resource — managing thousands of physical books, periodicals, reference materials, and increasingly digital resources. The Library module solves the following operational problems:

1. **Physical Catalog Management**: Schools maintain hundreds to thousands of books across categories, subjects, and authors. Manual tracking is error-prone and slow.
2. **Circulation Tracking**: Tracking who has which book, when it is due, and whether it has been returned is the core daily operation of a school library.
3. **Fine Recovery**: Overdue books and lost/damaged materials result in financial liability. Automated fine calculation and waiver workflows are required.
4. **Reservation Queue**: When a popular book is checked out, students need a waitlist mechanism.
5. **Inventory Accountability**: Physical stock verification ensures that books logged in the system match physical reality.
6. **Digital Resource Access**: E-books, PDFs, and licensed digital content need controlled access with license management.
7. **Analytics and Reporting**: Librarians and principals need data on circulation trends, overdue rates, popular books, and collection health to make acquisition decisions.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| Librarian | Full module access — catalog, issue, return, fine, audit |
| Library Supervisor | All librarian actions + reports + fine waivers |
| Student | View available books, place reservations (portal — not yet built) |
| Teacher | Issue books, place reservations |
| School Admin | View reports, approve fine waivers |

### 2.3 Indian School Context

- Fine amounts are denominated in INR.
- Book languages include English, Hindi, and regional languages (Gujarati, Marathi, Tamil, etc.).
- Membership types reflect Indian school staff designations: Students (Class I–XII), Teachers, Non-Teaching Staff.
- Academic year influences borrowing records and analytics segmentation.
- NCERT/CBSE/ICSE/State Board curricular alignment is tracked in `lib_curricular_alignment`.

---

## 3. Scope and Boundaries

### 3.1 In-Scope Features

- Book catalog management (master records + physical copies)
- Author, Publisher, Category (hierarchical), Genre, Keyword, Resource Type masters
- Shelf location management with building/aisle/shelf/zone mapping
- Book condition tracking
- Digital resource management with license controls
- Library member registration and membership type management
- Book issue/return/renew/mark-lost transactions
- Reservation queue management with queue position tracking
- Fine calculation (slab-based), collection, waiver, and payment receipt
- Inventory audit (scan-based physical stock verification)
- Transaction history and audit trail
- Reporting: Circulation analysis, Fine collection, Overdue, Acquisition, Digital resource usage, Dashboard
- PDF export of all reports via DomPDF
- ISBN lookup integration (Open Library API + Google Books API)
- AI-enriched book metadata (ai_summary, key_concepts, tags stored in DDL; not yet implemented in UI)
- Advanced analytics tables in DDL (reading behavior, popularity trends, collection health, predictive analytics, curricular alignment, engagement events — schema exists, UI not built)

### 3.2 Out of Scope

- Student/Parent portal for self-service book reservation (planned, not built)
- RFID scanner hardware integration (RFID tag field exists in `lib_book_copies` but no hardware bridge)
- Barcode scanner hardware integration (barcode fields exist; UI supports manual entry; no hardware bridge service)
- Integration with external library systems (KOHA, MARC21 import)
- Inter-school or district library network
- Peer-to-peer book lending
- Book procurement/purchase order flow (Vendor module is referenced for purchase records only)

---

## 4. Functional Requirements

### 4.1 M1 — Book and Resource Master (F.M1.1)

#### 4.1.1 Book Catalog Management

**RBS Ref:** F.M1.1 — Book Catalog (Tasks T.M1.1.1, T.M1.1.2)

**FR-LIB-001: Add New Book**
- Librarian can create a new book record by entering:
  - Title (required, max 500 chars)
  - Subtitle (optional)
  - Edition (optional, max 50 chars)
  - ISBN (optional, globally unique, 10 or 13 digits)
  - ISSN (optional, for periodicals)
  - DOI (optional, for digital objects)
  - Publication Year (optional, numeric)
  - Publisher (FK to `lib_publishers`)
  - Resource Type (required, FK to `lib_resource_types`)
  - Language (default: English)
  - Page Count (optional, positive integer)
  - Summary / Table of Contents (optional, text)
  - Cover Image URL (optional)
  - Reference Only flag (boolean; if true, book cannot be borrowed)
  - Lexile Level / Reading Age Range (optional, analytics)
  - Awards / Series Name / Series Position (optional)
  - Tags, AI Summary, Key Concepts (optional JSON fields for AI enrichment)
- Many-to-many relationships: Authors (with primary/order), Categories (hierarchical), Genres, Keywords
- Quick-create inline: Authors, Publishers, Categories can be created without leaving the book form (AJAX endpoints)

**FR-LIB-002: ISBN Lookup**
- Librarian can enter an ISBN and auto-fill book metadata from:
  - Open Library API (`https://openlibrary.org/api/books`)
  - Google Books API (`https://www.googleapis.com/books/v1/volumes`)
- Provider selectable: `openlibrary` (default) or `googlebooks`
- Fields auto-filled: title, subtitle, edition, authors, publisher, publication year, page count, language, summary, cover image, categories, series info
- ISBN must be 10 or 13 digits (non-numeric characters stripped)

**FR-LIB-003: Book Copy Management**
- Each book master can have one or more physical copies (1:N relationship)
- Each copy record includes:
  - Accession Number (unique, required)
  - Barcode (unique, required)
  - RFID Tag (unique, required per DDL — may be auto-generated for schools without RFID)
  - Shelf Location (FK to `lib_shelf_locations`, optional)
  - Current Condition (FK to `lib_book_conditions`, required)
  - Purchase Date / Purchase Price / Vendor (FK to `vnd_vendors`)
  - Status: `available`, `issued`, `reserved`, `under_maintenance`, `lost`, `withdrawn`
  - Flags: `is_lost`, `is_damaged`, `is_withdrawn`, `withdrawal_reason`
- Status transitions: available → issued (on transaction create), issued → available (on return), available → reserved (on reservation), any → lost, any → withdrawn
- Actions: mark-lost, mark-damaged, update-status, toggle active

#### 4.1.2 Reference Masters

**FR-LIB-004: Author Management**
- CRUD with soft-delete
- Fields: author name, short name, country, primary genre, notes
- Unique constraints on both short_name and author_name
- Search: by name or short name

**FR-LIB-005: Publisher Management**
- CRUD with soft-delete
- Fields: code (unique), name, address, contact, email, phone, website
- Search: by name, code, email, contact

**FR-LIB-006: Category Management (Hierarchical)**
- Multi-level category tree supporting parent-child relationships
- Fields: code (unique), name, description, level, display_order, parent_category_id
- Tree display with drag-and-drop ordering (routes: `update-order`, `update-tree`)
- Recursive tree rendering via Blade partials

**FR-LIB-007: Genre Management**
- CRUD with soft-delete
- Fields: code (unique), name, description

**FR-LIB-008: Keyword Management**
- CRUD with soft-delete
- Fields: code (unique), name

**FR-LIB-009: Book Condition Management**
- CRUD with soft-delete
- Fields: code (unique), name, description, `is_borrowable` flag
- `is_borrowable = false` prevents book copies in this condition from being issued

**FR-LIB-010: Resource Type Management**
- CRUD with soft-delete
- Fields: code (unique), name, `is_physical`, `is_digital`, `is_audio_books`, `is_borrowable`
- Drives fine slab applicability filtering

**FR-LIB-011: Shelf Location Management**
- CRUD with soft-delete
- Fields: code (unique), aisle number, shelf number, rack number, floor number, building, zone, description
- Unique constraint on (aisle, shelf, rack) combination
- Filter by building and zone

### 4.2 M1.2 — Digital Resources (F.M1.2)

**RBS Ref:** F.M1.2 — Digital Resources (Tasks T.M1.2.1, T.M1.2.2)

**FR-LIB-012: Digital Resource Management**
- Each book can have one or more digital resources (1:N)
- Fields: file name, file path, file size (bytes), MIME type, file format, download count, view count
- License Management:
  - License key, license type, license start/end dates
  - Access restriction (JSON — defines user roles, IP ranges, access rules)
  - Scope: `withinLicense()` scope filters to currently valid licenses
- File associated with `sys_media` via `file_media_id`
- Actions: increment-download, increment-view, toggle-status
- Filter: by book, file format, license type, license validity (yes/no)

**FR-LIB-013: Digital Resource Tag Management**
- Tags associated with each digital resource (1:N)
- Fields: tag_name
- Bulk operations: create tags, delete individual tags by ID
- Accessed via nested routes under digital resource

### 4.3 M2 — Library Member Management (F.M2.1)

**RBS Ref:** F.M2.1 — Member Profiles (Tasks T.M2.1.1, T.M2.1.2)

**FR-LIB-014: Member Registration**
- Each library member links to a system User (`sys_users`/`users` table) via `user_id` (1:1)
- Fields:
  - Membership Number (auto or manual, unique)
  - Library Card Barcode (unique)
  - Membership Type (FK to `lib_membership_types`)
  - Registration Date / Expiry Date
  - Auto-renew flag
  - Status: `active`, `expired`, `suspended`, `deactivated`
  - Suspension reason, notes
  - Reading level: Beginner, Intermediate, Advanced, Expert
  - Preferred notification channel: Email, SMS, Push, InApp
- Analytics fields (computed, not user-entered):
  - member_segment (e.g., High-Value, At-Risk, Inactive, New)
  - engagement_score, churn_risk_score, lifetime_value
  - reading_goal_annual, reading_progress_ytd
- `calculateSegment()` action triggers segment recalculation

**FR-LIB-015: Membership Type Configuration**
- CRUD with soft-delete
- Fields: code (unique), name, max_books_allowed (int >= 0), loan_period_days (int >= 1), renewal_allowed (bool), max_renewals (int), fine_rate_per_day (decimal), grace_period_days (int), priority_level
- Membership types drive loan duration, renewal limits, and fallback fine rates
- Filter/sort by priority_level

**FR-LIB-016: Member Status Actions**
- `update-status` endpoint allows direct status change (active/expired/suspended/deactivated)
- `toggle-status` (is_active) for soft activation/deactivation
- Expiry-based auto-expiration is a business rule but no scheduled job is built yet

### 4.4 M3 — Book Issue and Return (F.M3.1, F.M3.2)

**RBS Ref:** F.M3.1 — Issue Process, F.M3.2 — Return Process

**FR-LIB-017: Book Issue (Check-Out)**
- A transaction is created linking: book copy, member, issue date, due date, issuing librarian, and initial condition
- Due date auto-calculated from `membership_type.loan_period_days`
- Pre-issue validation:
  - Member must be active and not expired
  - Book copy must be in `available` status
  - Book condition must have `is_borrowable = true`
  - Member must not have exceeded `max_books_allowed`
- On issue: copy status → `issued`, transaction history record created
- Transaction statuses: `Issued`, `Returned`, `Overdue`, `Lost`

**FR-LIB-018: Book Return (Check-In)**
- Return action via `POST /library/lib-transactions/{id}/return`
- Sets return_date, updates copy status → `available`
- Return condition recorded (can differ from issue condition)
- Overdue detection: if `return_date > due_date`, transaction is overdue and fine may be generated
- `receive` action provides an alternative return path

**FR-LIB-019: Book Renewal**
- Action: `POST /library/lib-transactions/{id}/renew`
- Checks `membership_type.renewal_allowed` and `renewal_count < max_renewals`
- On success: extends due_date by `loan_period_days`, increments renewal_count, sets `is_renewed = true`
- Returns `false` (or error) if renewal limits exceeded

**FR-LIB-020: Mark Transaction as Lost**
- Action: `POST /library/lib-transactions/{id}/mark-lost`
- Sets transaction status → `Lost`
- Sets copy flags: `is_lost = true`, `status = 'lost'`
- Optional notes appended to transaction notes field

**FR-LIB-021: Fine Calculation (Inline)**
- `GET /library/lib-transactions/{id}/fine-calculation` and `GET /library/lib-fines/calculate/{transaction}`
- Returns: days_overdue, calculated_from, calculated_to, fine amount, slab breakdown
- Slab lookup logic:
  1. Find active `lib_fine_slab_config` matching membership_type_id and resource_type_id for fine_type = 'Late Fee'
  2. Find matching `lib_fine_slab_details` row by (from_day <= days_overdue <= to_day)
  3. Apply rate_per_day, check max_fine_amount cap
  4. Fallback: use `membership_type.fine_rate_per_day` if no slab config found

**FR-LIB-022: Transaction History**
- All create/update/return/renew/mark-lost actions log to `lib_transaction_history`
- Action types: issued, returned, renewed, marked_lost, condition_updated
- Fields: old_value (JSON), new_value (JSON), performed_by_id, performed_at, notes
- Viewable at `GET /library/lib-transactions/history`

### 4.5 M4 — Reservations and Hold Requests (F.M4.1)

**RBS Ref:** F.M4.1 — Reservation (Tasks T.M4.1.1, T.M4.1.2)

**FR-LIB-023: Place Reservation**
- Member can reserve a book (not a specific copy)
- Queue position auto-assigned: max(queue_position) + 1 for active reservations on same book
- Fields: book_id, member_id, reservation_date, expected_available_date, pickup_by_date
- Status flow: `Pending` → `Available` → `Picked_Up` or `Cancelled` or `Expired`
- Unique constraint: one active reservation per (book, member, status) combination

**FR-LIB-024: Reservation Workflow**
- `mark-available`: librarian marks book available for pickup (sets status = Available, notification_sent = true, notification_sent_at = now)
- `mark-picked-up`: member collected the book (status = Picked_Up)
- `cancel`: cancellation with optional reason (status = Cancelled)
- Notification integration: notification_sent flag tracked; SMS/email integration via sys_notification module (not yet wired to Library)

**FR-LIB-025: Reservation Expiry**
- Auto-cancel if not collected by `pickup_by_date` — business rule; no scheduler built yet
- Expired status set manually or via future scheduler

### 4.6 M5 — Inventory and Stock Audit (F.M5.1, F.M5.2)

**RBS Ref:** F.M5.1 — Physical Stock Verification, F.M5.2 — Shelf Management

**FR-LIB-026: Inventory Audit Session**
- Create audit session: `POST /library/lib-inventory-audit`
- Fields: audit_date, performed_by_id, total_scanned (updated in real-time), total_expected, missing_copies, misplaced_copies, damaged_copies, status (In Progress / Completed / Cancelled), completed_at, notes, UUID
- Audit lifecycle: Initialize → scan copies (real-time) → Complete or Cancel
- `initialize`: creates audit record, calculates total_expected from active copies in system
- `storeWithDetails`: creates audit + bulk detail records in one transaction
- `complete`: sets status = Completed, completed_at = now
- `checkCopy`: `GET /library/lib-inventory-audit/check-copy/{identifier}` — scan barcode/accession/RFID, returns copy status
- `getBookDetails`: `GET /library/lib-inventory-audit/book-details/{copyId}` — returns detailed copy info

**FR-LIB-027: Audit Detail Records**
- Each scanned copy creates/updates an `lib_inventory_audit_details` record
- Fields: audit_id, copy_id, expected_location_id, actual_location_id, scanned_at, condition_id, status (found/missing/misplaced/damaged), notes
- Bulk store: `POST /library/lib-inventory-audit-details/bulk` — for batch scanning
- View by audit: `GET /library/lib-inventory-audit-details/by-audit/{auditId}`
- Result classifications: found (copy at expected location), missing (not scanned), misplaced (found at different shelf), damaged (condition downgraded on scan)

### 4.7 M6 — Fines, Penalties, and Payments (F.M6.1, F.M6.2)

**RBS Ref:** F.M6.1 — Fine Calculation, F.M6.2 — Fine Payment

**FR-LIB-028: Fine Slab Configuration**
- Admins configure fine slabs: `lib_fine_slab_config` + `lib_fine_slab_details`
- Config fields: name, membership_type_id (nullable = all types), resource_type_id (nullable = all types), fine_type (enum), max_fine_amount, max_fine_type (Fixed/BookCost/Unlimited), effective_from/to, priority
- Detail rows define day ranges: from_day, to_day, rate_per_day, rate_type (Fixed/Percentage)
- Priority ordering: higher priority slabs evaluated first
- Bulk CRUD: bulkStore, bulkUpdate, bulkDelete for slab detail rows
- UI: `getSlabDetails` AJAX endpoint for dynamic slab preview in config form

**FR-LIB-029: Fine Record Creation**
- Fine types: Late Return, Lost Book, Damaged Book, Processing Fee
- Manual fine creation form with auto-calculate via AJAX (`lib-fines/calculate/{transaction}`)
- Fine fields: transaction_id, member_id, fine_type, amount, days_overdue, calculated_from, calculated_to, fine_slab_config_id, calculation_breakdown (JSON), notes, status
- On create: member.outstanding_fines incremented

**FR-LIB-030: Fine Collection**
- `mark-paid` action: sets fine status → Paid, calls `markPaid()` on LibFine model
- Payment record: `lib_fine_payments` — stores amount_paid, payment_method (Cash/Card/Online/Waiver), payment_reference, payment_date, receipt_number (unique), received_by_id
- Payment methods supported: Cash, Card, Online, Waiver

**FR-LIB-031: Fine Waiver**
- `waive-page`: displays waiver form with fine details
- `waive`: accepts waived_amount, waived_reason, records waived_by_id and waived_at
- Status → Waived after waiver
- LibFineWaiveRequest validates waived_amount and waived_reason

### 4.8 M7 — Library Reports and Analytics (F.M7.1, F.M7.2)

**RBS Ref:** F.M7.1 — Reports, F.M7.2 — Analytics

**FR-LIB-032: Circulation Analysis Report**
- Route: `GET /library/reports/circulation-analysis`
- Data sections:
  - Executive summary: total issues, returns, renewals, active members, avg loan days, overdue count, avg daily, peak day
  - Circulation by day of week
  - Circulation by membership type (issues, returns, renewals, overdue per type)
  - Top 10 circulating books with avg loan days
  - Category-wise analysis: titles, copies, issues, turnover rate, utilization %
  - Hourly circulation pattern (8 AM – 8 PM)
  - 12-month trend analysis
  - Automated recommendations (overdue rate, low-activity days, peak hour staffing)
- Date range filter (default: last 30 days)
- PDF export via DomPDF

**FR-LIB-033: Fine Collection Report**
- Route: `GET /library/reports/fine-collection`
- Data: fine totals by type, pending/paid/waived breakdown, overdue fines by member, fine trend over time
- Filter: start/end date, membership type, fine type
- Export: PDF and Excel/CSV
- Refresh endpoint: `POST /library/reports/fine-collection/refresh`

**FR-LIB-034: Overdue Report**
- Route: `GET /library/reports/overdue`
- Lists all overdue transactions with member details, book details, days overdue, estimated fine
- Filter: date range
- PDF export

**FR-LIB-035: Acquisition Report**
- Route: `GET /library/reports/acquisition`
- Tracks new additions to collection by category, date range, vendor, and cost
- `LibAcquisitionReportService` provides data

**FR-LIB-036: Digital Resource Report**
- Route: `GET /library/reports/digital`
- Tracks digital resource downloads and views, license expiry status
- `LibDigitalReportService` provides data

**FR-LIB-037: Master Dashboard (Library)**
- Route: `GET /library/dashboard`
- `MasterDashboardService` computes KPI cards and summary charts
- `LibDashboardReportService` for dashboard data aggregation
- Reports dashboard index: `GET /library/reportIndex`

**FR-LIB-038: PDF Report Print**
- `LibReportPrintController` handles PDF generation for all report types
- PDF templates: `lib-reports/pdf/templates/{report}.blade.php`
- Layout: `lib-reports/pdf/layout.blade.php`
- `ReportPrintHelper` helper class for shared print utilities

---

## 5. Non-Functional Requirements

### 5.1 Performance

| Requirement | Target |
|---|---|
| Book catalog list page load | < 2 seconds for up to 10,000 titles |
| Transaction create (issue) | < 1 second |
| Report generation | < 10 seconds for 12-month circulation report |
| ISBN lookup | < 3 seconds (external API call) |
| Inventory audit scan | < 500ms per barcode check |

### 5.2 Scalability

- Per-tenant database isolation ensures one school's library data does not affect another
- Pagination at 15 records per page on all listing pages
- FULLTEXT index on `lib_books_master` (title, subtitle, summary) for efficient search
- Composite indexes on `lib_transactions` for date-range queries
- Partial index on `lib_transactions(status, due_date)` for overdue lookups

### 5.3 Data Integrity

- All tables use soft deletes (`deleted_at`) with restore capability
- Cascade deletes on junction tables (e.g., deleting a book cascades to `lib_book_author_jnt`, `lib_book_category_jnt`, etc.)
- Unique constraints enforce: ISBN uniqueness, member-per-user uniqueness, active reservation uniqueness per (book, member, status)
- Fine amounts: `CHECK (amount >= 0)`, `CHECK (outstanding_fines >= 0)`
- DB-level ENUM constraints on transaction status, fine status, reservation status

### 5.4 Security

- All routes are registered inside `Route::middleware(['auth', 'verified'])` group in tenant.php
- Tenant isolation via `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive` middleware chain
- Gate-based authorization on all major controller actions (see Section 9)
- CSRF protection via Laravel's `web` middleware on all form submissions
- File download for digital resources should validate license dates before serving (currently not enforced in controller — see Section 14)

---

## 6. Database Schema

### 6.1 Reference / Master Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `lib_membership_types` | Borrowing rules per member category | code, max_books_allowed, loan_period_days, renewal_allowed, max_renewals, fine_rate_per_day, grace_period_days, priority_level |
| `lib_categories` | Hierarchical book classification | parent_category_id (self-ref FK), code, name, level, display_order |
| `lib_genres` | Literary genre tags | code, name, description |
| `lib_publishers` | Publisher master | code, name, address, contact, email, phone, website |
| `lib_resource_types` | Format classification (physical/digital/audio) | code, name, is_physical, is_digital, is_audio_books, is_borrowable |
| `lib_shelf_locations` | Physical library location mapping | code, aisle_number, shelf_number, rack_number, floor_number, building, zone |
| `lib_book_conditions` | Standardized condition states | code, name, is_borrowable |
| `lib_keywords` | Searchable keyword tags | code, name |

### 6.2 Book Catalog Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `lib_books_master` | Central book/resource catalog | title, isbn (unique), resource_type_id, publisher_id, is_reference_only, lexile_level, tags (JSON), ai_summary, key_concepts (JSON), curricular_relevance_score |
| `lib_authors` | Author master | author_name, short_name, country, primary_genre_id |
| `lib_book_author_jnt` | Book-author M:N | book_id, author_id, author_order, is_primary |
| `lib_book_category_jnt` | Book-category M:N | book_id, category_id |
| `lib_book_genre_jnt` | Book-genre M:N | book_id, genre_id |
| `lib_book_subject_jnt` | Book-curriculum mapping | book_id, class_id (→ sch_classes), subject_id (→ sch_subjects) |
| `lib_book_keyword_jnt` | Book-keyword M:N | book_id, keyword_id |
| `lib_book_condition_jnt` | Book condition history | date, book_id, condition_id, note |
| `lib_book_copies` | Individual physical copy tracking | accession_number (unique), barcode (unique), rfid_tag (unique), shelf_location_id, current_condition_id, purchase_date, purchase_price, vendor_id, status (ENUM), is_lost, is_damaged, is_withdrawn |
| `lib_digital_resources` | Digital file records per book | book_id, file_name, file_media_id (→ sys_media), file_path, file_size_bytes, mime_type, file_format, download_count, view_count, license_key, license_type, license_start_date, license_end_date, access_restriction (JSON) |
| `lib_digital_resource_tags` | Tags for digital resources | digital_resource_id, tag_name |

### 6.3 Member and Transaction Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `lib_members` | Library member profiles | user_id (unique, → users), membership_type_id, membership_number (unique), library_card_barcode (unique), registration_date, expiry_date, status (ENUM: active/expired/suspended/deactivated), outstanding_fines, member_segment, engagement_score |
| `lib_transactions` | Book issue/return records | copy_id, member_id, issue_date, due_date, return_date, issued_by_id, received_by_id, issue_condition_id, return_condition_id, is_renewed, renewal_count, status (ENUM: Issued/Returned/Overdue/Lost) |
| `lib_reservations` | Book hold/reservation queue | book_id, member_id, reservation_date, expected_available_date, notification_sent, pickup_by_date, status (ENUM: Pending/Available/Picked_Up/Cancelled/Expired), queue_position |
| `lib_transaction_history` | Audit trail for transactions | transaction_id, action_type (ENUM: issued/returned/renewed/marked_lost/condition_updated), old_value (JSON), new_value (JSON), performed_by_id, performed_at |

### 6.4 Fine Management Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `lib_fines` | Fine records | transaction_id, member_id, fine_type (ENUM), amount, days_overdue, calculated_from, calculated_to, fine_slab_config_id, calculation_breakdown (JSON), waived_amount, waived_by_id, waived_reason, waived_at, status (ENUM: Pending/Paid/Waived/Overdue) |
| `lib_fine_payments` | Payment records for fines | fine_id, amount_paid, payment_method (ENUM: Cash/Card/Online/Waiver), payment_reference, payment_date, received_by_id, receipt_number (unique) |
| `lib_fine_slab_config` | Fine rule configuration | name, membership_type_id, resource_type_id, fine_type (ENUM), max_fine_amount, max_fine_type (ENUM), effective_from, effective_to, priority |
| `lib_fine_slab_details` | Day-range rates within a slab | fine_slab_config_id, from_day, to_day, rate_per_day, rate_type (Fixed/Percentage) |

### 6.5 Inventory Audit Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `lib_inventory_audit` | Audit session header | uuid, audit_date, performed_by_id, total_scanned, total_expected, missing_copies, misplaced_copies, damaged_copies, status (ENUM: In Progress/Completed/Cancelled), completed_at |
| `lib_inventory_audit_details` | Per-copy scan records | audit_id, copy_id, expected_location_id, actual_location_id, scanned_at, condition_id, status (ENUM: found/missing/misplaced/damaged) |

### 6.6 Advanced Analytics Tables (DDL Exists — UI Not Built)

| Table | Purpose |
|---|---|
| `lib_reading_behavior_analytics` | Per-member reading pattern metrics (total books read, preferred genre/category, reading consistency score, diversity index) |
| `lib_book_popularity_trends` | Daily popularity tracking per book (requests, issues, reservations, digital views, popularity score, trend direction) |
| `lib_collection_health_metrics` | Collection-level metrics (utilization rate, turnover rate, age, diversity score, digital penetration) |
| `lib_predictive_analytics` | Model outputs: demand forecast, member churn, acquisition recommendations, budget projections |
| `lib_curricular_alignment` | Book-to-curriculum linkage (class_id, subject_id, alignment_score, recommended_by_faculty, faculty_rating, exam_reference_count) |
| `lib_engagement_events` | Granular user interaction events (search, browse, view, reserve, digital-view, rate, wishlist) |

### 6.7 Schema Issues (DDL Inconsistencies)

The following DDL issues were identified during analysis and require correction before production deployment:

1. **Duplicate `lib_fines` table**: The DDL file defines `lib_fines` twice — once at line 8295 (without fine_slab_config_id, with NOT NULL on waived fields) and again at line 8386 (enhanced version with nullable waived fields and fine_slab_config_id). The second definition is the correct one; the first is a legacy draft that should be removed.

2. **Stale FK references**: Several FK references in the DDL still use legacy column names (e.g., `publisher_id` referenced as `lib_publishers.publisher_id` but the column is named `id`; same for `lib_resource_types.resource_type_id` etc.). All PKs are `id` in the Laravel models.

3. **`lib_publishers` index references `is_deleted`**: `INDEX idx_publisher_active (is_active, is_deleted)` — the column `is_deleted` does not exist in the table definition (soft deletes use `deleted_at`). Must be corrected.

4. **`lib_transaction_history` FK**: references `performed_by` but the column is `performed_by_id`.

5. **`lib_inventory_audit` FK**: references `performed_by` but the column is `performed_by_id`.

6. **`lib_books_master` FK**: references `lib_publishers.publisher_id` and `lib_resource_types.resource_type_id` — should be `.id`.

7. **`lib_digital_resources` FK**: references `media_files` table but sys_media is used in the application.

8. **`lib_book_category_jnt` dual PK**: Defines both `id` AUTO_INCREMENT and `PRIMARY KEY (book_id, category_id)` — conflicts. Only one PK is permitted.

---

## 7. API and Routes

### 7.1 Route Registration Summary

The Library module routes are registered in `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 2920–3170. The module's own `routes/web.php` has all routes commented out (this was intentional — tenant.php supersedes it).

Base URL: `{tenant-domain}/library/`
Route Name Prefix: `library.`

### 7.2 Master / Reference Routes

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `library/lib-categories` | GET | LibCategoryController | index |
| `library/lib-categories` | POST | LibCategoryController | store |
| `library/lib-categories/{id}` | GET | LibCategoryController | show |
| `library/lib-categories/{id}` | PUT | LibCategoryController | update |
| `library/lib-categories/{id}` | DELETE | LibCategoryController | destroy |
| `library/lib-categories/trash/view` | GET | LibCategoryController | trashed |
| `library/lib-categories/{id}/restore` | GET | LibCategoryController | restore |
| `library/lib-categories/{id}/force-delete` | DELETE | LibCategoryController | forceDelete |
| `library/lib-categories/{id}/toggle-status` | POST | LibCategoryController | toggleStatus |
| `library/lib-categories/update-order` | POST | LibCategoryController | updateOrder |
| `library/lib-categories/update-tree` | POST | LibCategoryController | updateTree |

Standard CRUD + soft-delete + toggle-status pattern applies to all reference entities:
`lib-authors`, `lib-genres`, `lib-keywords`, `lib-publishers`, `lib-resource-types`, `lib-book-conditions`, `lib-membership-types`, `lib-shelf-locations`

### 7.3 Book Catalog Routes

| Route Pattern | Method | Note |
|---|---|---|
| `library/lib-books-master/lookup-isbn` | GET | ISBN lookup AJAX |
| `library/lib-books-master/quick-create-author` | POST | Inline author create |
| `library/lib-books-master/quick-create-publisher` | POST | Inline publisher create |
| `library/lib-books-master/quick-create-category` | POST | Inline category create |
| `library/lib-books-master` | Resource (GET/POST/PUT/DELETE) | CRUD |
| `library/lib-book-copies` | Resource + extras | mark-lost, mark-damaged, update-status |
| `library/lib-digital-resources` | Resource + extras | increment-download, increment-view |
| `library/lib-digital-resources/{resource}/tags` | GET/POST/DELETE | Tag management |

### 7.4 Operations Routes

| Route Pattern | Method | Note |
|---|---|---|
| `library/lib-members` | Resource + update-status + calculate-segment | Member management |
| `library/lib-transactions` | Resource | CRUD |
| `library/lib-transactions/{id}/return` | POST | Book return |
| `library/lib-transactions/{id}/renew` | POST | Renewal |
| `library/lib-transactions/{id}/mark-lost` | POST | Mark lost |
| `library/lib-transactions/{id}/receive` | POST | Alternative return |
| `library/lib-transactions/history` | GET | Transaction history view |
| `library/lib-transactions/{id}/fine-calculation` | GET | Ajax fine calculation |
| `library/lib-fines/calculate/{transaction}` | GET | Slab-based fine calc |
| `library/lib-reservations` | Resource + cancel + mark-available + mark-picked-up | Reservation flow |
| `library/lib-fines` | Resource + mark-paid + waive + payment | Fine management |
| `library/lib-inventory-audit` | Resource + initialize + complete + check-copy + store-with-details | Audit flow |
| `library/lib-inventory-audit-details` | Resource + bulk + by-audit | Audit scan details |
| `library/lib-fine-slab-config` | Resource + getSlabDetails + update-priority + bulk CRUD | Fine config |
| `library/lib-fine-slab-details` | Resource | Slab day ranges |

### 7.5 Report Routes

| Route Pattern | Method | Note |
|---|---|---|
| `library/reports/fine-collection` | GET | Fine collection report |
| `library/reports/fine-collection/export/{format}` | GET | Export (PDF/Excel) |
| `library/reports/fine-collection/refresh` | POST | Refresh report data |
| `library/reports/circulation-analysis` | GET | Circulation analysis |
| `library/reports/overdue` | GET | Overdue books |
| `library/reports/acquisition` | GET | New acquisitions |
| `library/reports/digital` | GET | Digital resource usage |
| `library/reports/dashboard` | GET | Report dashboard |
| `library/reports/print/{type}` | GET/POST | PDF print via DomPDF |

### 7.6 Hub / Tab Views

| Route | Description |
|---|---|
| `library/library-mgt/masters` (library.tabIndex) | Mega-tabbed view loading all master data |
| `library/library-mgt/transactions` (library.transactionsIndex) | Transaction management hub |
| `library/library-mgt/history` (library.historyIndex) | History/audit trail hub |
| `library/dashboard` (library.dashboard.master) | Master dashboard |

---

## 8. Business Rules

### 8.1 Membership and Borrowing Rules

| Rule ID | Rule Description |
|---|---|
| BR-LIB-001 | A member cannot borrow more books simultaneously than `membership_type.max_books_allowed` |
| BR-LIB-002 | Due date is calculated as: `issue_date + membership_type.loan_period_days` |
| BR-LIB-003 | A book marked `is_reference_only = true` cannot be issued |
| BR-LIB-004 | A book copy with a condition where `is_borrowable = false` cannot be issued |
| BR-LIB-005 | A suspended or deactivated member cannot borrow books |
| BR-LIB-006 | A member with `status = expired` cannot borrow until membership is renewed |
| BR-LIB-007 | Renewals are permitted only if `renewal_allowed = true` AND `renewal_count < max_renewals` |
| BR-LIB-008 | Renewed due date = current date + membership_type.loan_period_days |

### 8.2 Fine Calculation Rules

| Rule ID | Rule Description |
|---|---|
| BR-LIB-009 | Fine begins accruing on the day after the due date (grace period handled by `grace_period_days` in membership type — but no enforcement logic in current code) |
| BR-LIB-010 | Fine amount = `days_overdue * rate_per_day` per matching slab detail row |
| BR-LIB-011 | If a matching slab config has `max_fine_amount`, the total fine is capped at that amount |
| BR-LIB-012 | Slab config lookup order: higher priority config evaluated first |
| BR-LIB-013 | If no slab config matches, fallback to `membership_type.fine_rate_per_day * days_overdue` |
| BR-LIB-014 | Only `Pending` fines can be marked paid or waived |
| BR-LIB-015 | Only `Pending` fines can receive payment (via `lib_fine_payments`) |
| BR-LIB-016 | When a fine is created, `lib_members.outstanding_fines` is incremented by fine amount |
| BR-LIB-017 | When a fine is paid/waived, outstanding_fines should be decremented (NOTE: `markPaid()` logic in LibFine model must handle this — current implementation in model needs verification) |

### 8.3 Reservation Rules

| Rule ID | Rule Description |
|---|---|
| BR-LIB-018 | A member cannot have two active reservations (Pending or Available) for the same book simultaneously |
| BR-LIB-019 | Queue position is assigned as `max(queue_position) + 1` for the given book's active reservations |
| BR-LIB-020 | When a book becomes available, the system marks the first-in-queue reservation as Available |
| BR-LIB-021 | If a reservation is not picked up by `pickup_by_date`, it should be auto-expired (scheduled job not yet built) |
| BR-LIB-022 | Notification (SMS/email) is expected when reservation status changes to Available — currently only the flag is set; notification dispatch not implemented |

### 8.4 Inventory Audit Rules

| Rule ID | Rule Description |
|---|---|
| BR-LIB-023 | Only one audit session can be `In Progress` at a time (business rule; not enforced at DB level currently) |
| BR-LIB-024 | A book copy scanned at a location different from its registered `shelf_location_id` is classified as `misplaced` |
| BR-LIB-025 | A book copy not scanned at all during an audit is classified as `missing` in the audit results |
| BR-LIB-026 | Audit `total_expected` is calculated at session initialization from all active, non-withdrawn copies |

### 8.5 Digital Resource Rules

| Rule ID | Rule Description |
|---|---|
| BR-LIB-027 | Access to a digital resource should be denied if `license_end_date < today` or `license_start_date > today` |
| BR-LIB-028 | Download and view counts should be incremented atomically |
| BR-LIB-029 | `access_restriction` JSON field should be evaluated before serving download links — not currently enforced in controller (see Section 14) |

---

## 9. Authorization and RBAC

### 9.1 Gate Permissions in Use

Authorization is implemented via `Gate::authorize()` calls in controllers. The permission naming convention follows the pattern: `tenant.{resource}.{action}`.

| Permission | Controller | Actions Protected |
|---|---|---|
| `tenant.lib-book-master.viewAny` | LibBookMasterController | index |
| `tenant.lib-book-master.view` | LibBookMasterController | show |
| `tenant.lib-book-master.create` | LibBookMasterController | create, store |
| `tenant.lib-book-master.update` | LibBookMasterController | edit, update, toggleStatus |
| `tenant.lib-book-master.delete` | LibBookMasterController | destroy, forceDelete |
| `tenant.lib-book-master.restore` | LibBookMasterController | trashed, restore |
| `tenant.lib-reservation.viewAny` | LibReservationController | index |
| `tenant.lib-reservation.view` | LibReservationController | show |
| `tenant.lib-reservation.create` | LibReservationController | create, store |
| `tenant.lib-reservation.update` | LibReservationController | edit, update, toggleStatus |
| `tenant.lib-reservation.delete` | LibReservationController | destroy |
| `tenant.lib-reservation.restore` | LibReservationController | trashed, restore |
| `tenant.lib-reservation.forceDelete` | LibReservationController | forceDelete |

Similar Gate patterns exist on: LibCategoryController, LibAuthorController, LibGenreController, LibKeywordController, LibPublisherController, LibResourceTypeController, LibShelfLocationController, LibBookConditionController, LibBookCopyController, LibMemberController, LibMembershipTypeController, LibDigitalResourceController, LibTransactionController, LibFineSlabConfigController, LibFineSlabDetailController, LibInventoryAuditController, LibInventoryAuditDetailController.

### 9.2 Policies

21 Policy classes are defined in `Modules/Library/app/Policies/`:
`LibAuthorPolicy`, `LibBookConditionPolicy`, `LibBookCopyPolicy`, `LibBookMasterPolicy`, `LibCategoryPolicy`, `LibDigitalResourcePolicy`, `LibDigitalResourceTagPolicy`, `LibFinePolicy`, `LibFineSlabConfigPolicy`, `LibFineSlabDetailPolicy`, `LibGenrePolicy`, `LibInventoryAuditDetailPolicy`, `LibInventoryAuditPolicy`, `LibKeywordPolicy`, `LibMemberPolicy`, `LibMembershipTypePolicy`, `LibPublisherPolicy`, `LibReservationPolicy`, `LibResourceTypePolicy`, `LibShelfLocationPolicy`, `LibTransactionHistoryPolicy`, `LibTransactionPolicy`.

### 9.3 Controllers Without Authorization (Security Risk)

The following 8 controllers/actions have no Gate::authorize() calls and are accessible to any authenticated user:

| Controller | Missing Authorization Coverage |
|---|---|
| `LibFineController` | All actions (create, store, update, destroy, markPaid, waive, payment, calculate) |
| `LibCirculationReportController` | All actions (report generation, export) |
| `LibFineReportController` | All actions |
| `LibReportPrintController` | All actions (PDF generation) |
| `LibraryController` (hub) | tabIndex, transactionIndex, historyIndex |
| `MasterDashboardController` | index |
| `LibDigitalResourceTagController` | All tag management actions |
| `LibInventoryAuditDetailController` | All actions (partial — some may have authorization) |

**Risk Level: HIGH** — LibFineController's waive action especially represents a financial operation that should require explicit authorization.

---

## 10. Service Layer Architecture

### 10.1 Service Inventory

| Service | Responsibility |
|---|---|
| `IsbnLookupService` | External API calls to Open Library and Google Books for book metadata auto-fill |
| `LibCirculationReportService` | Circulation analysis: executive summary, by-day, by-membership, top books, category analysis, hourly pattern, 12-month trends, recommendations |
| `LibFineReportService` | Fine collection report data: totals by type, pending/paid/waived, member breakdown, trend |
| `LibDashboardReportService` | Dashboard KPI aggregation |
| `LibChartService` | Prepares Chart.js-compatible data arrays for circulation and fine charts |
| `LibAcquisitionReportService` | Acquisition report data (new books by date/category/vendor) |
| `LibDigitalReportService` | Digital resource usage report data |
| `LibOverdueReportService` | Overdue books report data |
| `MasterDashboardService` | Dashboard aggregation for the master dashboard view |

### 10.2 Service Design Patterns

- Services are injected via constructor DI in controllers
- Services use collection-based processing (in-memory aggregation after DB fetch) rather than complex SQL aggregations — this is a performance concern for large datasets (see Section 14)
- `LibCirculationReportService::getReport()` returns all sections in one call; date parsing is handled via `parseDates()` helper returning Carbon instances

---

## 11. Integration Points

### 11.1 Internal Module Dependencies

| Dependency | How Used |
|---|---|
| `Modules\Vendor\Models\Vendor` | Referenced in LibBookCopy (purchase vendor) and passed to views — `Vendor::active()->get()` |
| `App\Models\User` | Library members link to `users` table via user_id |
| `sch_classes` (via `lib_book_subject_jnt`) | Curricular alignment links books to school classes |
| `sch_subjects` (via `lib_book_subject_jnt`) | Curricular alignment links books to school subjects |
| `sys_media` (via `lib_digital_resources.file_media_id`) | Digital file storage using the platform's media system |

### 11.2 External API Dependencies

| Service | Endpoint | Purpose |
|---|---|---|
| Open Library | `https://openlibrary.org/api/books` | ISBN lookup for book metadata |
| Google Books | `https://www.googleapis.com/books/v1/volumes` | ISBN lookup fallback |

Note: Both APIs are called without authentication keys. Google Books has a rate limit without an API key. For production, a Google Books API key should be configured.

### 11.3 Missing Integration (Gap)

| Expected Integration | Status | Impact |
|---|---|---|
| Notification Module (`sys_notifications`) | Not wired | Reservation availability notifications, overdue reminders not sent |
| Fee Module (`fin_*`) | Not connected | Library fines are tracked in `lib_fines` but not linked to student fee accounts |
| Student Module (`std_*`) | Not connected | Members are linked to `users` table, not directly to `std_students` — student enrollment number not available in library member context |
| Academic Session / Academic Year | No cross-module link | Reading behavior analytics uses academic_year as VARCHAR; not linked to `sch_org_academic_sessions_jnt` |

---

## 12. Test Coverage

### 12.1 Browser Tests (Dusk)

15 browser test files exist at `/Users/bkwork/Herd/prime_ai/tests/Browser/Modules/Library/`:

| Test File | Entity Covered |
|---|---|
| `Authors/LibAuthorCrudTest.php` | Author CRUD |
| `BookConditions/LibBookConditionCrudTest.php` | Book Condition CRUD |
| `BookCopies/LibBookCopyCrudTest.php` | Book Copy CRUD |
| `BookMaster/LibBookMasterCrudTest.php` | Book Master CRUD |
| `DigitalResources/LibDigitalResourceCrudTest.php` | Digital Resource CRUD |
| `FineMaster/LibFineMasterCrudTest.php` | Fine CRUD |
| `Genres/LibGenreCreateTest.php` | Genre Create |
| `Keywords/LibKeywordCrudTest.php` | Keyword CRUD |
| `Members/LibMemberCrudTest.php` | Member CRUD |
| `MembershipTypes/LibMembershipTypeCrudTest.php` | Membership Type CRUD |
| `Publishers/LibPublisherCrudTest.php` | Publisher CRUD |
| `Reservations/LibReservationCrudTest.php` | Reservation CRUD |
| `ResourceTypes/LibResourceTypeCrudTest.php` | Resource Type CRUD |
| `ShelfLocations/LibShelfLocationCrudTest.php` | Shelf Location CRUD |
| `Transactions/LibTransactionCrudTest.php` | Transaction CRUD |

### 12.2 Test Coverage Gaps

The following functional areas have no browser tests:
- Inventory Audit flow (scan, initialize, complete)
- Fine calculation (slab-based)
- Fine waiver and payment
- Renewal logic
- Reservation status transitions (mark-available, mark-picked-up, cancel)
- Report generation (all 6 reports)
- ISBN lookup
- Category tree reordering
- Digital resource license validation

### 12.3 Unit/Feature Test Coverage

No Unit or Feature tests exist for this module. All coverage is browser-level Dusk tests.

---

## 13. Implementation Status

### 13.1 Overall Completion: ~45%

| Feature Area | Status | Notes |
|---|---|---|
| Reference Masters (author, publisher, category, genre, keyword, condition, shelf, resource type) | 95% | All CRUD complete, views built, routes registered |
| Book Catalog (master + copies) | 90% | Full CRUD, ISBN lookup, quick-create working; some view layout issues |
| Digital Resources | 80% | CRUD complete; license enforcement in download not implemented |
| Membership Types | 95% | Complete |
| Member Management | 85% | CRUD done; segment calculation stub needs full implementation |
| Transactions (issue/return/renew/lost) | 80% | Core flow works; grace period logic and some edge cases unverified |
| Reservations | 80% | Workflow complete; notification dispatch not wired |
| Fine Management | 75% | Fine creation, collection, waiver built; outstanding_fines decrement on payment needs verification |
| Fine Slab Configuration | 85% | Config + detail CRUD complete; slab calculation logic in controller tested |
| Inventory Audit | 70% | CRUD and scan endpoints built; barcode/RFID hardware integration not built |
| Reports (Circulation, Fine, Overdue) | 60% | Services built, views built; export tested manually; no automated tests |
| Reports (Acquisition, Digital, Dashboard) | 50% | Services and views built; data accuracy not fully verified |
| PDF Print | 65% | Templates exist; layout tested; not all reports have templates |
| Advanced Analytics Tables | 10% | DDL exists, models created; no UI, no seeder, no service |
| Curricular Alignment | 5% | DDL and model exist only |
| Notification Integration | 0% | Not started |
| Scheduled Jobs (overdue, expiry) | 0% | Not started |

### 13.2 What Is Working

- All CRUD operations for all 34 master and transactional entities
- Book issue, return, renewal, mark-lost workflows
- Fine calculation (slab-based) with breakdown detail
- Fine waiver and payment recording
- Reservation queue management
- Inventory audit session management with real-time scan
- Circulation and fine report generation
- PDF export for key reports
- ISBN lookup from Open Library and Google Books
- Tab-based hub views (tabIndex, transactionIndex)
- All 15 browser tests (CRUD scenarios)

---

## 14. Known Issues and Technical Debt

### 14.1 P0 — Blocking Issues (Must Fix Before Production)

| Issue ID | Severity | Description | Location |
|---|---|---|---|
| LIB-P0-001 | CRITICAL | **Module routing conflict**: `routes/web.php` has all routes commented out AND the RouteServiceProvider registers it as `Route::middleware('web')->group(module_path('Library', '/routes/web.php'))`. The web.php routes are empty (all commented), so module routing entirely depends on tenant.php inclusion. If the module's RouteServiceProvider fires, it registers an empty web.php — no conflict but confirms web.php is dead code. Routes DO exist and work via tenant.php (lines 2920–3170). This is architectural confusion, not a routing failure. However, web.php needs cleanup. | `Modules/Library/routes/web.php`, `RouteServiceProvider.php` |
| LIB-P0-002 | HIGH | **8 controllers with zero authorization** — LibFineController (all actions), LibCirculationReportController, LibFineReportController, LibReportPrintController, LibraryController (hub), MasterDashboardController, LibDigitalResourceTagController, LibInventoryAuditDetailController (partial). Fine waivers, report access, and dashboard accessible by any authenticated tenant user. | Multiple controllers |
| LIB-P0-003 | HIGH | **DDL has duplicate `lib_fines` table definition** — two `CREATE TABLE lib_fines` statements in tenant_db_v2.sql (lines 8295 and 8386). First is a stale draft; only the second is correct. Running the DDL will fail or produce wrong structure. | `tenant_db_v2.sql` lines 8295 and 8386 |
| LIB-P0-004 | HIGH | **DDL FK column name mismatches** — 7 FK references use legacy column names (`publisher_id`, `resource_type_id`, `category_id` instead of `id`; `performed_by` instead of `performed_by_id`). Migrations generated from DDL will fail. | `tenant_db_v2.sql` multiple tables |

### 14.2 P1 — High Priority Issues

| Issue ID | Severity | Description | Location |
|---|---|---|---|
| LIB-P1-001 | HIGH | **`$request->all()` in 8 controller update methods** — Uses unvalidated request data for model updates. Affected: LibFineController::update(), LibReservationController::update(), LibTransactionController (multiple), LibFineSlabDetailController::update(), LibReportPrintController, LibInventoryAuditDetailController, LibCirculationReportController, LibBookMasterController (error log). Should use `$request->validated()` or `$request->safe()->only([...])`. | Multiple controllers |
| LIB-P1-002 | HIGH | **Digital resource license not enforced on download** — `LibDigitalResourceController::incrementDownload()` increments the counter but does not check `license_start_date <= today <= license_end_date` before granting access. Licensed content can be downloaded after license expiry. | `LibDigitalResourceController.php` |
| LIB-P1-003 | MEDIUM | **`outstanding_fines` decrement not verified** — When a fine is paid (`markPaid()`) or waived, `lib_members.outstanding_fines` should be decremented. The increment on fine creation is correct, but the corresponding decrement in `LibFine::markPaid()` and `waive()` model methods needs verification. | `LibFine.php` model |
| LIB-P1-004 | MEDIUM | **Grace period not enforced** — `lib_membership_types.grace_period_days` exists in DDL and is in the FormRequest, but no code subtracts it from fine calculation. Fine starts accruing the day after due date regardless of grace period. | `LibFineController::calculate()`, `LibTransaction::getDaysOverdueAttribute()` |
| LIB-P1-005 | MEDIUM | **Reservation availability notification not wired** — When `markAvailable()` is called, `notification_sent = true` is set, but no notification is dispatched to the member via the Notification module. | `LibReservation::markAvailable()` or controller |

### 14.3 P2 — Medium Priority Issues

| Issue ID | Description |
|---|---|
| LIB-P2-001 | `LibBookMaster::$table = 'lib_books_master'` — note the table is named `lib_books_master` (plural "books") while other tables follow singular pattern. Consistent, but developers must be aware. |
| LIB-P2-002 | `LibTransactionController::logHistory()` maps `'create'` → `'issued'` but `'update'` → `'condition_updated'` which is misleading. A generic update action should have its own type or pass the specific type. |
| LIB-P2-003 | Multiple controllers (LibFineController, LibReservationController, LibTransactionController) have identical boilerplate in `index()` — loading all 15+ models regardless of the current tab view. This is an N+1 query risk that should be profiled with Laravel Debugbar. |
| LIB-P2-004 | `LibCirculationReportService` processes all transactions in memory (collection-based). For schools with 5,000+ transaction records, this will hit memory limits. DB-level aggregation via `selectRaw`/`groupBy` should replace in-memory iteration. |
| LIB-P2-005 | `lib_book_copies.rfid_tag` is `NOT NULL` in DDL but schools without RFID hardware cannot enter this field. The constraint should be `NULL` with a unique constraint that ignores NULLs (or a generated placeholder should be provided on create). |
| LIB-P2-006 | The `lib_book_category_jnt` table has both `id AUTO_INCREMENT` and `PRIMARY KEY (book_id, category_id)` — two primary keys. This is a DDL error (MySQL allows only one PK per table). |
| LIB-P2-007 | `IsbnLookupService` calls Google Books API without an API key. Without a key, the API has strict daily rate limits and will fail silently for schools making many ISBN lookups. |
| LIB-P2-008 | No scheduled Artisan command exists for: overdue reminders, reservation expiry, membership expiry. These business rules exist in documentation but have no automated execution. |

### 14.4 P3 — Low Priority / Future Improvements

| Issue ID | Description |
|---|---|
| LIB-P3-001 | Advanced analytics tables (`lib_reading_behavior_analytics`, `lib_book_popularity_trends`, etc.) are fully designed in DDL and have Eloquent models but no seeder, service, or UI. These represent a major unrealized investment. |
| LIB-P3-002 | `lib_curricular_alignment` table links books to `sch_classes` and `sch_subjects` — a powerful curriculum integration feature. No UI or service built. |
| LIB-P3-003 | AI book metadata fields (`ai_summary`, `key_concepts`, `tags`) are in the DDL but no AI processing pipeline exists. |
| LIB-P3-004 | `lib_engagement_events` table exists for gamification/portal use cases but no data is written to it. |
| LIB-P3-005 | `lib_members.member_segment` and `calculateSegment()` endpoint exist but no actual segmentation algorithm is implemented. |

---

## 15. Development Priorities and Recommendations

### 15.1 Immediate Actions (Sprint 1 — Before Any Production Deployment)

1. **Fix DDL**: Remove duplicate `lib_fines` table definition, fix all FK column name mismatches, fix `lib_publishers` index referencing non-existent `is_deleted` column, fix `lib_book_category_jnt` dual PK.

2. **Add authorization to 8 controllers**: At minimum, LibFineController waive/payment actions require `tenant.lib-fine.waive` and `tenant.lib-fine.payment` gates. LibCirculationReportController and LibFineReportController need `tenant.lib-reports.view` gate. MasterDashboardController needs `tenant.library.dashboard.view`.

3. **Replace `$request->all()` with validated data**: In all 8 affected controller methods.

4. **Clean up `routes/web.php`**: Either delete it or document clearly that it is superseded by tenant.php. Consider removing the RouteServiceProvider's `mapWebRoutes()` call since web.php is empty.

### 15.2 Short-Term Actions (Sprint 2–3)

5. **Enforce digital resource license check**: Add license date validation in `LibDigitalResourceController` before serving download/view.

6. **Verify and fix `outstanding_fines` decrement**: Audit `LibFine::markPaid()` and `waive()` to confirm member's outstanding_fines is correctly decremented.

7. **Implement grace period in fine calculation**: Subtract `membership_type.grace_period_days` from days_overdue before applying fine rate.

8. **Wire notification dispatch for reservations**: Call Notification module when reservation `markAvailable()` fires.

9. **Fix RFID Not Null constraint**: Change `lib_book_copies.rfid_tag` to `VARCHAR(100) NULL` and generate a UUID placeholder on create if no hardware is available.

### 15.3 Medium-Term Actions (Sprint 4–6)

10. **Refactor report services to use DB aggregation**: Replace collection-based iteration in `LibCirculationReportService` with SQL `GROUP BY` + `selectRaw` queries for performance.

11. **Add Google Books API key configuration**: Add `GOOGLE_BOOKS_API_KEY` to `.env` and configure in `IsbnLookupService`.

12. **Build scheduled commands**:
    - `library:send-overdue-reminders` — notify members with overdue books
    - `library:expire-reservations` — auto-expire reservations past `pickup_by_date`
    - `library:expire-memberships` — mark expired memberships

13. **Add Feature/Unit test coverage**: Prioritize fine calculation slab logic, renewal limit checks, and queue position assignment.

### 15.4 Long-Term Roadmap

14. **Build curricular alignment UI**: Allow librarians to map books to classes/subjects with priority levels.

15. **Implement reading behavior analytics**: Build scheduled computation for `lib_reading_behavior_analytics` from transaction history.

16. **Build Student/Parent Portal**: Self-service book search, reservation placement, fine viewing.

17. **Barcode scanner integration**: USB/bluetooth barcode scanner support for browser-based scanning via Web Serial API or dedicated scan endpoint.

18. **AI book metadata enrichment**: Pipeline to generate `ai_summary`, `key_concepts`, and `tags` using LLM for newly added books.

---

## Appendix A: File Reference

### A.1 Key Source Files

| File Path | Purpose |
|---|---|
| `/Users/bkwork/Herd/prime_ai/Modules/Library/` | Module root |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/routes/web.php` | Module web routes (all commented — superseded by tenant.php) |
| `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 2920–3170 | Active route registration for Library module |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/LibraryController.php` | Hub controller — tabIndex, transactionIndex, historyIndex |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/LibBookMasterController.php` | Book catalog + ISBN lookup + quick-create |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/LibTransactionController.php` | Issue/return/renew/lost/fine-calculation |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/LibFineController.php` | Fine CRUD + waiver + payment |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/LibReservationController.php` | Reservation queue management |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/LibInventoryAuditController.php` | Audit session management + scan |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Services/IsbnLookupService.php` | Open Library + Google Books API integration |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Services/LibCirculationReportService.php` | Circulation analytics service |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Models/LibBookMaster.php` | Book master model (table: lib_books_master) |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Models/LibTransaction.php` | Transaction model + overdue logic + renew() |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Models/LibMember.php` | Member model + scopes |
| `/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase/1-Master_DDLs/tenant_db_v2.sql` lines 7825–8680 | Library DDL (34 tables) |
| `/Users/bkwork/Herd/prime_ai/tests/Browser/Modules/Library/` | 15 browser test files |

### A.2 Table Prefix Clarification

The RBS document (Module M) uses the prefix `bok_*` as the planned prefix. The actual implementation uses `lib_*` for all 34 tables. This discrepancy exists because the module was built by a developer who used `lib_` instead of `bok_`. The RBS document should be updated to reflect `lib_*` as the actual prefix.

---

*Document generated by automated code analysis — 2026-03-25*
*Sources: RBS lines 3147–3237, tenant_db_v2.sql lines 7825–8680, Modules/Library source code (109 PHP files), tenant.php lines 2920–3170, 15 browser test files*
