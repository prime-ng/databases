# LIB — Library Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Platform:** Prime-AI Academic Intelligence Platform (Laravel 12 + PHP 8.2 + MySQL 8.x)
**Module Code:** LIB | **Namespace:** `Modules\Library` | **Type:** Tenant | **Table Prefix:** `lib_*`
**V1 Date:** 2026-03-25 | **Gap Analysis Date:** 2026-03-22

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Roles](#3-stakeholders--roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API Endpoints & Routes](#6-api-endpoints--routes)
7. [UI Screens](#7-ui-screens)
8. [Business Rules](#8-business-rules)
9. [Workflows](#9-workflows)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Dependencies](#11-dependencies)
12. [Test Scenarios](#12-test-scenarios)
13. [Glossary](#13-glossary)
14. [Suggestions & Roadmap](#14-suggestions--roadmap)
15. [Appendices](#15-appendices)
16. [V1 → V2 Delta](#16-v1--v2-delta)

---

## 1. Executive Summary

The Library module is a comprehensive school library management system for Indian K-12 schools on the Prime-AI SaaS ERP platform. It manages the full lifecycle of physical and digital library resources — from catalogue management, member enrollment, and book circulation through fine collection, inventory auditing, and analytics reporting.

**Current Completion: ~55%** (revised upward from V1's 45% after gap analysis confirmed all business-logic flows are implemented).

### 1.1 Key Findings from Gap Analysis (2026-03-22)

| Category | Finding | Severity |
|---|---|---|
| Routing | Module IS wired in tenant.php (lines 2719–2967) — V1 claim "not wired" was incorrect | INFO (corrected) |
| Module Middleware | `EnsureTenantHasModule` middleware MISSING from library route group | P0 |
| Authorization | 6 controllers have zero `Gate::authorize()` calls | P0/P1 |
| Cross-layer Import | 22 controllers import `Modules\Vendor\Models\Vendor` (unused cross-module dependency) | P1 |
| Permission Prefix | Inconsistency: some use `tenant.lib-*`, others use `library.lib-*` | P1 |
| DDL | Duplicate `lib_fines` table definition (lines 8293 and 8384 in DDL) | P1 |
| Unvalidated Input | `$request->all()` in multiple controller update methods | P1 |
| Missing Service Layer | No TransactionService, ReservationService, or FineCalculationService | P2 |
| No Tests | Zero unit/feature tests in module; 15 browser (Dusk) tests exist only | P1 |

### 1.2 Module Metrics

| Metric | Count |
|---|---|
| Controllers | 26 (25 domain + 1 hub LibraryController) |
| Models | 35 |
| Services | 9 (all report/analytics services) |
| FormRequests | 19 |
| Policies | 23 |
| Browser (Dusk) Tests | 15 |
| DDL Tables | 35 (33 in Library DDL v1 + analytics tables) |
| Views | ~120 Blade templates |
| Routes in tenant.php | ~120+ (lines 2719–2967) |

---

## 2. Module Overview

### 2.1 Identity

| Property | Value |
|---|---|
| Module Name | Library |
| Module Code | LIB |
| nwidart Namespace | `Modules\Library` |
| Module Path | `Modules/Library/` |
| Route Prefix | `library/` |
| Route Name Prefix | `library.` |
| DB Table Prefix | `lib_*` |
| Module Type | Tenant (per-school DB isolation via stancl/tenancy v3.9) |
| Route Registration | `routes/tenant.php` lines 2719–2967 |
| Module web.php | Commented-out duplicate routes — dead code |
| Note on Prefix | RBS used `bok_*` as planned prefix; actual implementation uses `lib_*` throughout |

### 2.2 Business Purpose

Indian school libraries manage hundreds to thousands of physical books, periodicals, and digital resources. The Library module solves:

1. **Physical Catalogue Management** — title, author, publisher, ISBN, category, genre, copy tracking
2. **Accession Register** — barcode + accession number per physical copy
3. **Circulation Tracking** — who has which book, due date, overdue detection
4. **Fine Recovery** — automated slab-based fine calculation, collection, and waiver
5. **Reservation Queue** — waitlist for popular books with position tracking
6. **Inventory Accountability** — physical stock verification via barcode/RFID scan
7. **Digital Resource Access** — e-books/PDFs with license management
8. **OPAC Functionality** — catalogue search by title/author/subject/ISBN (partially built)
9. **Analytics and Reporting** — circulation trends, overdue rates, popular books, collection health

### 2.3 Indian School Context

- Fine amounts denominated in INR
- Book languages: English, Hindi, and regional languages (Gujarati, Marathi, Tamil, etc.)
- Membership types reflect Indian designations: Students (Class I–XII), Teachers, Non-Teaching Staff
- Academic year alignment (VARCHAR field; not FK to `sch_org_academic_sessions_jnt`)
- NCERT/CBSE/ICSE/State Board curricular alignment tracked via `lib_curricular_alignment`

---

## 3. Stakeholders & Roles

| Role | Primary Responsibilities | Authorization Level |
|---|---|---|
| Librarian | Full daily operations — issue, return, fine, audit, catalogue entry | All `tenant.lib-*` permissions |
| Library Supervisor | All librarian actions + fine waivers + report generation | All `tenant.lib-*` + waiver gate |
| School Admin / Principal | View reports, approve fine waivers, dashboard access | `tenant.library.dashboard.view`, `tenant.lib-reports.view` |
| Teacher | Check out books, view own transactions | `tenant.lib-transactions.create`, `tenant.lib-transactions.view` |
| Student | View catalogue, place reservations (portal — planned) | `tenant.lib-reservation.create` (Student Portal only) |
| System Admin | Configuration — fine slabs, membership types, shelf setup | All gates |

---

## 4. Functional Requirements

Status notation: ✅ Implemented | 🟡 Partial | ❌ Not Started | 📐 Proposed

---

### 4.1 Book Catalogue — Masters (FR-LIB-M1)

**FR-LIB-001: Add New Book** ✅
- Librarian creates a book record with: title (required, max 500), subtitle, edition (max 50), ISBN (unique, 10 or 13 digit), ISSN, DOI, publication year, publisher (FK `lib_publishers`), resource type (FK `lib_resource_types`), language, page count, summary, TOC, cover image URL
- Reference-only flag (`is_reference_only`) prevents borrowing
- Lexile level, reading age range, awards, series name, series position
- JSON fields: tags, ai_summary (stored; AI pipeline not built), key_concepts
- Many-to-many: authors (with `is_primary`, `author_order`), categories, genres, keywords
- Quick-create inline (AJAX): author, publisher, category without leaving book form

**FR-LIB-002: ISBN Auto-Fill Lookup** ✅
- Librarian enters ISBN; system queries Open Library API or Google Books API
- Provider selectable: `openlibrary` (default) | `googlebooks`
- Fields auto-filled: title, subtitle, edition, authors, publisher, year, pages, language, summary, cover, categories, series
- Non-numeric characters stripped; 10- or 13-digit validation enforced
- 🟡 Gap: Google Books called without API key — rate-limited; no timeout handling in `IsbnLookupService`

**FR-LIB-003: Book Copy Management (Accession Register)** ✅
- Each book master has 1:N physical copies
- Per-copy fields: accession number (unique), barcode (unique), RFID tag (unique — see gap below), shelf location (FK `lib_shelf_locations`), current condition (FK `lib_book_conditions`), purchase date, purchase price, vendor (FK `vnd_vendors`)
- Copy status enum: `available | issued | reserved | under_maintenance | lost | withdrawn`
- Flags: `is_lost`, `is_damaged`, `is_withdrawn`, `withdrawal_reason`
- Actions: mark-lost, mark-damaged, update-status, toggle-active
- 🟡 Gap: `rfid_tag` is `NOT NULL` in DDL but schools without RFID hardware cannot supply this

**FR-LIB-004: Author Management** ✅
- CRUD + soft-delete; fields: author name, short name, country, primary genre, notes
- Unique constraints on `short_name` and `author_name`

**FR-LIB-005: Publisher Management** ✅
- CRUD + soft-delete; fields: code (unique), name, address, contact, email, phone, website

**FR-LIB-006: Category Management (Hierarchical)** ✅
- Multi-level tree (self-referencing `parent_category_id`)
- Fields: code, name, description, level, display_order
- Drag-and-drop ordering via `update-order` and `update-tree` endpoints

**FR-LIB-007: Genre Management** ✅
- CRUD + soft-delete; fields: code, name, description

**FR-LIB-008: Keyword Management** ✅
- CRUD + soft-delete; fields: code, name

**FR-LIB-009: Book Condition Management** ✅
- CRUD + soft-delete; `is_borrowable` flag prevents issue of copies in poor condition

**FR-LIB-010: Resource Type Management** ✅
- CRUD + soft-delete; flags: `is_physical`, `is_digital`, `is_audio_books`, `is_borrowable`
- Controls fine slab applicability filtering

**FR-LIB-011: Shelf Location Management** ✅
- CRUD + soft-delete; fields: code, aisle, shelf, rack, floor, building, zone
- Unique constraint on (aisle, shelf, rack) combination

---

### 4.2 Digital Resources (FR-LIB-M2)

**FR-LIB-012: Digital Resource Management** ✅
- Each book has 1:N digital resources
- Fields: file name, file path, file size (bytes), MIME type, file format, download count, view count
- License: key, type, start/end dates, access restriction (JSON)
- `withinLicense()` scope filters valid resources by date range
- Actions: increment-download, increment-view, toggle-status
- 🟡 Gap: license date NOT enforced in `incrementDownload()` — expired licenses still downloadable

**FR-LIB-013: Digital Resource Tag Management** ✅
- Tags per digital resource (1:N); CRUD + bulk-delete
- Accessed via nested routes under digital resource
- ❌ Gap: `LibDigitalResourceTagController` has zero `Gate::authorize()` calls

---

### 4.3 Library Member Management (FR-LIB-M3)

**FR-LIB-014: Member Registration** ✅
- Links to system user (`users.id`) via `user_id` (1:1 unique)
- Fields: membership number (auto or manual, unique), library card barcode (unique), membership type (FK `lib_membership_types`), registration date, expiry date, auto-renew flag
- Status enum: `active | expired | suspended | deactivated`
- Suspension reason, notes, reading level (Beginner / Intermediate / Advanced / Expert)
- Preferred notification channel: Email / SMS / Push / InApp
- Analytics fields: `member_segment`, `engagement_score`, `churn_risk_score`, `lifetime_value`, `reading_goal_annual`, `reading_progress_ytd`
- 🟡 Gap: `calculateSegment()` action endpoint exists but no actual segmentation algorithm implemented

**FR-LIB-015: Membership Type Configuration** ✅
- CRUD + soft-delete
- Fields: code, name, `max_books_allowed`, `loan_period_days`, `renewal_allowed`, `max_renewals`, `fine_rate_per_day`, `grace_period_days`, `priority_level`
- Drives loan duration, renewal limits, and fallback fine rates

**FR-LIB-016: Member Status Management** ✅
- `update-status` endpoint: direct status change (active/expired/suspended/deactivated)
- `toggle-status` (is_active) for soft activation/deactivation
- ❌ Gap: No scheduled job to auto-expire memberships past `expiry_date`

---

### 4.4 Book Issue and Return (FR-LIB-M4)

**FR-LIB-017: Book Issue (Check-Out)** ✅
- Creates `lib_transactions` record linking: copy, member, issue date, due date, issuing librarian, initial condition
- Due date = `issue_date + membership_type.loan_period_days`
- Pre-issue validation: member must be active + not expired, copy must be `available`, condition `is_borrowable = true`, member has not exceeded `max_books_allowed`
- On issue: copy status → `issued`; transaction history record created
- Transaction status enum: `Issued | Returned | Overdue | Lost`

**FR-LIB-018: Book Return (Check-In)** ✅
- `POST /library/lib-transactions/{id}/return` — sets `return_date`, copy status → `available`
- Return condition recorded (may differ from issue condition)
- Overdue detection: if `return_date > due_date`, fine may be generated
- `receive` action: alternative return path (same outcome)

**FR-LIB-019: Book Renewal** ✅
- `POST /library/lib-transactions/{id}/renew`
- Checks `renewal_allowed = true` AND `renewal_count < max_renewals`
- On success: extends due_date by `loan_period_days`, increments `renewal_count`, sets `is_renewed = true`

**FR-LIB-020: Mark Transaction as Lost** ✅
- `POST /library/lib-transactions/{id}/mark-lost`
- Transaction status → `Lost`; copy flags: `is_lost = true`, `status = 'lost'`
- Optional notes appended

**FR-LIB-021: Fine Calculation (Inline)** 🟡
- Two endpoints: `GET /library/lib-transactions/{id}/fine-calculation` and `GET /library/lib-fines/calculate/{transaction}`
- Returns: days_overdue, calculated_from, calculated_to, fine amount, slab breakdown
- Slab lookup: find `lib_fine_slab_config` by membership_type + resource_type + fine_type; apply `lib_fine_slab_details` day-range; cap at `max_fine_amount`; fallback to `membership_type.fine_rate_per_day`
- 🟡 Gap: `grace_period_days` from membership type NOT subtracted before fine starts accruing

**FR-LIB-022: Transaction History Audit Trail** ✅
- All create/update/return/renew/mark-lost actions log to `lib_transaction_history`
- Action types: `issued | returned | renewed | marked_lost | condition_updated`
- Fields: old_value (JSON), new_value (JSON), performed_by_id, performed_at, notes

---

### 4.5 Reservations / Holds (FR-LIB-M5)

**FR-LIB-023: Place Reservation** ✅
- Member reserves a book (not a specific copy)
- Queue position = `max(queue_position) + 1` for active reservations on same book
- Fields: book_id, member_id, reservation_date, expected_available_date, pickup_by_date
- Status flow: `Pending → Available → Picked_Up | Cancelled | Expired`
- Unique constraint: one active reservation per (book, member, status)

**FR-LIB-024: Reservation Workflow** ✅
- `mark-available`: sets status = Available, `notification_sent = true` — but no notification dispatched
- `mark-picked-up`: member collected; status = Picked_Up
- `cancel`: reason recorded; status = Cancelled
- 🟡 Gap: Notification module not wired — `notification_sent` flag is set but no SMS/email dispatched

**FR-LIB-025: Reservation Expiry** ❌
- Business rule: auto-cancel if not collected by `pickup_by_date`
- No scheduled Artisan command exists; must be set manually

---

### 4.6 Inventory and Stock Audit (FR-LIB-M6)

**FR-LIB-026: Inventory Audit Session** ✅
- Create audit session: initialize → scan → complete or cancel
- `initialize`: creates record, calculates `total_expected` from active non-withdrawn copies
- `storeWithDetails`: creates audit + bulk detail records in one DB transaction
- `complete`: status = Completed, `completed_at = now()`
- `cancel`: status = Cancelled
- `checkCopy`: `GET /library/lib-inventory-audit/check-copy/{identifier}` — scan barcode/accession/RFID
- `getBookDetails`: returns detailed copy info for scanned copy
- Business rule: only one audit session `In Progress` at a time (not enforced at DB level)

**FR-LIB-027: Audit Detail Records** ✅
- Per-copy scan records in `lib_inventory_audit_details`
- Classifications: found (at expected shelf), missing (not scanned), misplaced (wrong shelf), damaged (condition downgraded)
- `bulk` endpoint for batch scanning; `by-audit/{auditId}` for viewing session results

---

### 4.7 Fines, Penalties, and Payments (FR-LIB-M7)

**FR-LIB-028: Fine Slab Configuration** ✅
- `lib_fine_slab_config`: name, membership_type_id (NULL = all), resource_type_id (NULL = all), fine_type enum, max_fine_amount, max_fine_type (Fixed/BookCost/Unlimited), effective_from/to, priority
- `lib_fine_slab_details`: day-range rows (from_day, to_day, rate_per_day, rate_type)
- Priority ordering: higher priority evaluated first
- Bulk CRUD: bulkStore, bulkUpdate, bulkDelete for detail rows
- AJAX: `getSlabDetails` endpoint for dynamic preview

**FR-LIB-029: Fine Record Creation** 🟡
- Fine types: `Late Return | Lost Book | Damaged Book | Processing Fee`
- Manual creation + auto-calculate via AJAX
- Fields: transaction_id, member_id, fine_type, amount, days_overdue, calculated_from, calculated_to, fine_slab_config_id, calculation_breakdown (JSON), notes, status
- On create: `lib_members.outstanding_fines` incremented
- ❌ Gap: `LibFineController` has zero `Gate::authorize()` calls — any authenticated user can create/waive fines

**FR-LIB-030: Fine Collection** 🟡
- `mark-paid` → fine status = Paid; `lib_fine_payments` record created
- Payment fields: amount_paid, payment_method (Cash/Card/Online/Waiver), payment_reference, payment_date, receipt_number (unique), received_by_id
- 🟡 Gap: `outstanding_fines` decrement on payment needs verification in `LibFine::markPaid()`

**FR-LIB-031: Fine Waiver** 🟡
- `waive-page`: form with fine details; `waive`: records waived_amount, waived_reason, waived_by_id, waived_at
- Status → Waived
- ❌ Risk: no authorization gate on waiver action (HIGH — financial operation)

---

### 4.8 Reports and Analytics (FR-LIB-M8)

**FR-LIB-032: Circulation Analysis Report** ✅
- Route: `GET /library/reports/circulation`
- Sections: executive summary (totals, avg loan days, overdue count, peak day), by day-of-week, by membership type, top 10 circulating books, category-wise analysis, hourly pattern (8 AM–8 PM), 12-month trend, automated recommendations
- Filter: date range (default: last 30 days)
- PDF export via DomPDF
- 🟡 Gap: service uses in-memory collection iteration — performance risk for large datasets

**FR-LIB-033: Fine Collection Report** ✅
- Route: `GET /library/reports/fine-collection`
- Data: fine totals by type, pending/paid/waived breakdown, overdue fines by member, trend over time
- Filter: start/end date, membership type, fine type
- Export: PDF and CSV; refresh endpoint

**FR-LIB-034: Overdue Report** ✅
- Route: `GET /library/reports/overdue` (via `LibOverdueReportService`)
- Lists all overdue transactions with member details, book details, days overdue, estimated fine
- PDF export

**FR-LIB-035: Acquisition Report** ✅
- Route: `GET /library/reports/acquisition`
- New additions by category, date range, vendor, and cost
- `LibAcquisitionReportService`

**FR-LIB-036: Digital Resource Report** ✅
- Route: `GET /library/reports/digital`
- Download/view counts, license expiry status
- `LibDigitalReportService`

**FR-LIB-037: Library Dashboard** ✅
- Route: `GET /library/dashboard`
- `MasterDashboardService` + `LibDashboardReportService` for KPI cards and summary charts
- ❌ Gap: `MasterDashboardController` has zero `Gate::authorize()` — any authenticated user can view

**FR-LIB-038: PDF Report Print** ✅
- `LibReportPrintController`: PDF generation for all report types via DomPDF
- Templates: `lib-reports/pdf/templates/{report}.blade.php`
- ❌ Gap: `LibReportPrintController` has zero `Gate::authorize()`

---

### 4.9 Proposed / New in V2 (FR-LIB-M9) 📐

**FR-LIB-039: EnsureTenantHasModule Middleware** 📐
- Add `EnsureTenantHasModule:Library` to the library route group in tenant.php
- Prevents schools without the Library module license from accessing library routes
- Fix: change line 2719 from `['auth', 'verified']` to `['auth', 'verified', 'tenant.module:Library']`

**FR-LIB-040: Standardize Permission Prefix** 📐
- All library gates must use `tenant.lib-*` prefix consistently
- `LibTransactionController` incorrectly uses `library.lib-transactions.*`; standardize to `tenant.lib-transactions.*`
- Update AppServiceProvider policy registrations accordingly

**FR-LIB-041: Scheduled Commands** 📐
- `library:send-overdue-reminders` — notify members with overdue books (daily)
- `library:expire-reservations` — auto-expire reservations past `pickup_by_date` (daily)
- `library:expire-memberships` — mark `expired` for memberships past `expiry_date` (daily)

**FR-LIB-042: OPAC — Catalogue Search for Students/Staff** 📐
- Search endpoint: `GET /library/catalogue/search?q={query}&type={title|author|isbn|subject}`
- Returns: book records with availability status (copies available/total)
- Accessible without full librarian access for browse-only
- Integration point for Student Portal (STP module)

**FR-LIB-043: Barcode/QR Scanning for Issue/Return** 📐
- `GET /library/scan/book/{barcode}` — resolve barcode to copy details
- `GET /library/scan/member/{barcode}` — resolve library card barcode to member
- Enables scan-first workflow: librarian scans member card, then book barcode to issue
- Current: accession number entered manually; barcode field exists but no scan-first UI

**FR-LIB-044: SLK Module Integration** 📐
- Link syllabus books (`bok_syllabus_books`) to library catalogue (`lib_books_master`) via ISBN or title match
- `lib_book_subject_jnt` already supports class/subject mapping — wire to SLK module
- Allows librarians to see which books are on this term's syllabus

**FR-LIB-045: Notification Dispatch for Reservation Availability** 📐
- Wire `LibReservation::markAvailable()` to dispatch a Notification via the NTF module
- Notification channels: SMS, email, in-app
- Template: "Your reserved book '{title}' is now available. Collect by {pickup_by_date}."

**FR-LIB-046: Grace Period Enforcement in Fine Calculation** 📐
- `days_overdue = max(0, (return_date - due_date) - grace_period_days)`
- Subtract `membership_type.grace_period_days` before applying fine rate
- Fix in `LibTransactionController::getFineCalculation()` and `LibFine::calculateFineAmount()`

**FR-LIB-047: TransactionService, ReservationService, FineCalculationService** 📐
- Extract issue/return/renew logic from `LibTransactionController` into `TransactionService`
- Extract workflow logic from `LibReservationController` into `ReservationService`
- Extract fine calculation from `LibFineController` / `LibTransactionController` into `FineCalculationService`
- Enables unit testing of business logic independent of HTTP layer

---

## 5. Data Model

### 5.1 Reference / Master Tables

| Table | Purpose | Key Columns | Status |
|---|---|---|---|
| `lib_membership_types` | Borrowing rules per member category | code, max_books_allowed, loan_period_days, renewal_allowed, max_renewals, fine_rate_per_day, grace_period_days, priority_level | ✅ |
| `lib_categories` | Hierarchical book classification | parent_category_id (self-ref), code, name, level, display_order | ✅ |
| `lib_genres` | Literary genre tags | code, name, description | ✅ |
| `lib_publishers` | Publisher master | code, name, address, contact, email, phone, website | ✅ |
| `lib_resource_types` | Format classification | code, is_physical, is_digital, is_audio_books, is_borrowable | ✅ |
| `lib_shelf_locations` | Physical library location | code, aisle_number, shelf_number, rack_number, floor_number, building, zone | ✅ |
| `lib_book_conditions` | Standardized condition states | code, name, is_borrowable | ✅ |
| `lib_keywords` | Searchable keyword tags | code, name | ✅ |

### 5.2 Book Catalogue Tables

| Table | Purpose | Key Columns | Status |
|---|---|---|---|
| `lib_books_master` | Central book/resource catalogue | title, isbn (unique), resource_type_id, publisher_id, is_reference_only, lexile_level, tags (JSON), ai_summary, key_concepts (JSON), curricular_relevance_score | ✅ |
| `lib_authors` | Author master | author_name, short_name, country, primary_genre_id | ✅ |
| `lib_book_author_jnt` | Book–author M:N | book_id, author_id, author_order, is_primary | ✅ |
| `lib_book_category_jnt` | Book–category M:N | book_id, category_id | ✅ DDL issue: dual PK |
| `lib_book_genre_jnt` | Book–genre M:N | book_id, genre_id | ✅ |
| `lib_book_subject_jnt` | Book–curriculum mapping | book_id, class_id (→ sch_classes), subject_id (→ sch_subjects) | 🟡 DDL exists; no UI |
| `lib_book_keyword_jnt` | Book–keyword M:N | book_id, keyword_id | ✅ |
| `lib_book_condition_jnt` | Book condition history | date, book_id, condition_id, note | ✅ |
| `lib_book_copies` | Physical copy tracking | accession_number (unique), barcode (unique), rfid_tag (unique NOT NULL — issue), shelf_location_id, current_condition_id, purchase_date, purchase_price, vendor_id, status ENUM, is_lost, is_damaged, is_withdrawn | ✅ |
| `lib_digital_resources` | Digital file records | book_id, file_name, file_media_id (→ sys_media), file_path, file_size_bytes, mime_type, file_format, download_count, view_count, license_key, license_type, license_start_date, license_end_date, access_restriction (JSON) | 🟡 |
| `lib_digital_resource_tags` | Tags for digital resources | digital_resource_id, tag_name | ✅ |

### 5.3 Member and Transaction Tables

| Table | Purpose | Key Columns | Status |
|---|---|---|---|
| `lib_members` | Library member profiles | user_id (unique), membership_type_id, membership_number (unique), library_card_barcode (unique), registration_date, expiry_date, status ENUM, outstanding_fines, member_segment, engagement_score | ✅ |
| `lib_transactions` | Book issue/return records | copy_id, member_id, issue_date, due_date, return_date, issued_by_id, received_by_id, issue_condition_id, return_condition_id, is_renewed, renewal_count, status ENUM | ✅ |
| `lib_reservations` | Book hold/reservation queue | book_id, member_id, reservation_date, expected_available_date, notification_sent, pickup_by_date, status ENUM, queue_position | 🟡 notification not dispatched |
| `lib_transaction_history` | Audit trail per transaction event | transaction_id, action_type ENUM, old_value (JSON), new_value (JSON), performed_by_id, performed_at | ✅ |

### 5.4 Fine Management Tables

| Table | Purpose | Key Columns | Status |
|---|---|---|---|
| `lib_fines` | Fine records | transaction_id, member_id, fine_type ENUM, amount, days_overdue, calculated_from, calculated_to, fine_slab_config_id, calculation_breakdown (JSON), waived_amount, waived_by_id, waived_reason, waived_at, status ENUM | 🟡 |
| `lib_fine_payments` | Payment records | fine_id, amount_paid, payment_method ENUM, payment_reference, payment_date, received_by_id, receipt_number (unique) | 🟡 |
| `lib_fine_slab_config` | Fine rule configuration | name, membership_type_id, resource_type_id, fine_type ENUM, max_fine_amount, max_fine_type ENUM, effective_from, effective_to, priority | ✅ |
| `lib_fine_slab_details` | Day-range rates within a slab | fine_slab_config_id, from_day, to_day, rate_per_day, rate_type (Fixed/Percentage) | ✅ |

### 5.5 Inventory Audit Tables

| Table | Purpose | Key Columns | Status |
|---|---|---|---|
| `lib_inventory_audit` | Audit session header | uuid, audit_date, performed_by_id, total_scanned, total_expected, missing_copies, misplaced_copies, damaged_copies, status ENUM, completed_at | ✅ |
| `lib_inventory_audit_details` | Per-copy scan records | audit_id, copy_id, expected_location_id, actual_location_id, scanned_at, condition_id, status ENUM (found/missing/misplaced/damaged) | ✅ |

### 5.6 Advanced Analytics Tables (Schema Exists — UI Not Built)

| Table | Purpose | Status |
|---|---|---|
| `lib_reading_behavior_analytics` | Per-member reading patterns (total books, preferred genre/category, reading consistency score, diversity index) | ❌ No service/UI |
| `lib_book_popularity_trends` | Daily popularity tracking per book (requests, issues, reservations, views, popularity score, trend direction) | ❌ No service/UI |
| `lib_collection_health_metrics` | Collection-level metrics (utilization, turnover, age, diversity, digital penetration) | ❌ No service/UI |
| `lib_predictive_analytics` | Model outputs: demand forecast, member churn, acquisition recommendations, budget projections | ❌ No service/UI |
| `lib_curricular_alignment` | Book-to-curriculum linkage (class_id, subject_id, alignment_score, recommended_by_faculty, exam_reference_count) | ❌ No service/UI |
| `lib_engagement_events` | Granular interaction events (search, browse, view, reserve, digital-view, rate, wishlist) | ❌ No service/UI |

### 5.7 DDL Issues (Must Fix Before Production)

| # | Severity | Issue | Location |
|---|---|---|---|
| DDL-001 | P1 | Duplicate `lib_fines` table — two `CREATE TABLE lib_fines` in DDL (lines 8293 and 8384). First is stale draft; second is correct. Running DDL will fail. | tenant_db DDL |
| DDL-002 | P1 | `lib_book_category_jnt` has both `id AUTO_INCREMENT` and `PRIMARY KEY (book_id, category_id)` — MySQL allows only one PK | DDL |
| DDL-003 | P2 | `lib_book_copies.rfid_tag` is `NOT NULL` — schools without RFID hardware cannot provide this value | DDL |
| DDL-004 | P2 | `lib_publishers` index references `is_deleted` column which does not exist (soft deletes use `deleted_at`) | DDL |
| DDL-005 | P2 | FK references use legacy column names: `lib_publishers.publisher_id`, `lib_resource_types.resource_type_id` — should be `.id` | DDL |
| DDL-006 | P2 | `lib_transaction_history` FK references `performed_by` but column is `performed_by_id` | DDL |
| DDL-007 | P2 | `lib_inventory_audit` FK references `performed_by` but column is `performed_by_id` | DDL |
| DDL-008 | P2 | `lib_digital_resources` FK references `media_files` table; application uses `sys_media` | DDL |

---

## 6. API Endpoints & Routes

### 6.1 Route Registration

**Status:** Wired in `routes/tenant.php` lines 2719–2967.
**Correction from V1:** V1 incorrectly stated the module was "NOT wired into tenant.php". Gap analysis (2026-03-22) confirmed it IS registered at line 2719.

**Current middleware:** `['auth', 'verified']`
**Missing middleware:** `EnsureTenantHasModule` — not applied to library route group

**Required fix (FR-LIB-039):**
```php
// tenant.php line 2719 — CURRENT
Route::middleware(['auth', 'verified'])->prefix('library')->name('library.')->group(function () {

// REQUIRED CHANGE
Route::middleware(['auth', 'verified', 'tenant.module:Library'])->prefix('library')->name('library.')->group(function () {
```

**Note on dead code:** `Modules/Library/routes/web.php` has all routes commented out and is superseded by tenant.php. The `RouteServiceProvider.php` still loads it but registers nothing. Should be cleaned up.

### 6.2 Hub / Tab View Routes

| Method | Route | Controller::Method | Name | Auth |
|---|---|---|---|---|
| GET | `/library/library-mgt/masters` | LibraryController::tabIndex | `library.tabIndex` | ❌ No Gate |
| GET | `/library/library-mgt/transactions` | LibraryController::transactionIndex | `library.transactionsIndex` | ❌ No Gate |
| GET | `/library/library-mgt/history` | LibraryController::historyIndex | `library.historyIndex` | ❌ No Gate |
| GET | `/library/dashboard` | MasterDashboardController::index | `library.dashboard.master` | ❌ No Gate |

### 6.3 Reference Master Routes (Standard Pattern)

All reference masters follow this 11-route pattern. Applied to: `lib-categories`, `lib-authors`, `lib-genres`, `lib-keywords`, `lib-publishers`, `lib-resource-types`, `lib-book-conditions`, `lib-membership-types`, `lib-shelf-locations`.

| Method | Route | Action |
|---|---|---|
| GET/POST/PUT/DELETE | `/{resource}` resource | index, create, store, show, edit, update, destroy |
| GET | `/{resource}/trash/view` | trashed |
| GET | `/{resource}/{id}/restore` | restore |
| DELETE | `/{resource}/{id}/force-delete` | forceDelete |
| POST | `/{resource}/{id}/toggle-status` | toggleStatus |
| POST | `/{resource}/update-order` | updateOrder (categories only) |
| POST | `/{resource}/update-tree` | updateTree (categories only) |

### 6.4 Book Catalogue Routes

| Method | Route | Controller::Method | Name |
|---|---|---|---|
| GET | `lib-books-master/lookup-isbn` | LibBookMasterController::lookupIsbn | `library.lib-books-master.lookup-isbn` |
| POST | `lib-books-master/quick-create-author` | ::quickCreateAuthor | `library.lib-books-master.quick-create-author` |
| POST | `lib-books-master/quick-create-publisher` | ::quickCreatePublisher | `library.lib-books-master.quick-create-publisher` |
| POST | `lib-books-master/quick-create-category` | ::quickCreateCategory | `library.lib-books-master.quick-create-category` |
| Resource | `lib-books-master` | LibBookMasterController | Full CRUD |
| Resource + extras | `lib-book-copies` | LibBookCopyController | CRUD + mark-lost, mark-damaged, update-status |
| Resource + extras | `lib-digital-resources` | LibDigitalResourceController | CRUD + increment-download, increment-view |
| GET/POST/DELETE | `lib-digital-resources/{resource}/tags` | LibDigitalResourceTagController | Tag CRUD |

### 6.5 Member and Transaction Routes

| Method | Route | Controller::Method | Name |
|---|---|---|---|
| Resource+extras | `lib-members` | LibMemberController | CRUD + update-status, calculate-segment |
| Resource+extras | `lib-transactions` | LibTransactionController | CRUD + history |
| POST | `lib-transactions/{id}/return` | ::returnBook | `library.lib-transactions.return` |
| POST | `lib-transactions/{id}/renew` | ::renew | `library.lib-transactions.renew` |
| POST | `lib-transactions/{id}/mark-lost` | ::markLost | `library.lib-transactions.markLost` |
| POST | `lib-transactions/{id}/receive` | ::receive | `library.lib-transactions.receive` |
| GET | `lib-transactions/history` | ::history | `library.lib-transactions.history` |
| GET | `lib-transactions/{id}/fine-calculation` | ::getFineCalculation | `library.lib-transactions.fine-calculation` |
| POST | `lib-transactions/calculate-fine` | ::calculateFine | `library.lib-transactions.calculate-fine` |
| Resource+extras | `lib-reservations` | LibReservationController | CRUD + cancel, mark-available, mark-picked-up |
| GET | `lib-fines/calculate/{transaction}` | LibFineController::calculate | `library.lib-fines.calculate` |
| Resource+extras | `lib-fines` | LibFineController | CRUD + mark-paid, waive, payment |

### 6.6 Inventory Audit Routes

| Method | Route | Controller::Method | Name |
|---|---|---|---|
| Resource | `lib-inventory-audit` | LibInventoryAuditController | CRUD |
| POST | `lib-inventory-audit/{id}/mark-completed` | ::markCompleted | `library.lib-inventory-audit.mark-completed` |
| POST | `lib-inventory-audit/{id}/cancel` | ::cancel | `library.lib-inventory-audit.cancel` |
| POST | `lib-inventory-audit/store-with-details` | ::storeWithDetails | `library.lib-inventory-audit.store-with-details` |
| POST | `lib-inventory-audit/initialize` | ::initialize | `library.lib-inventory-audit.initialize` |
| POST | `lib-inventory-audit/complete` | ::complete | `library.lib-inventory-audit.complete` |
| GET | `lib-inventory-audit/check-copy/{identifier}` | ::checkCopy | `library.lib-inventory-audit.check-copy` |
| GET | `lib-inventory-audit/{id}/data` | ::getAuditData | `library.lib-inventory-audit.data` |
| GET | `lib-inventory-audit/book-details/{copyId}` | ::getBookDetails | `library.lib-inventory-audit.book-details` |
| Resource + bulk + by-audit | `lib-inventory-audit-details` | LibInventoryAuditDetailController | Details CRUD |

### 6.7 Fine Configuration Routes

| Method | Route | Controller::Method | Name |
|---|---|---|---|
| Resource + extras | `lib-fine-slab-config` | LibFineSlabConfigController | CRUD |
| GET | `lib-fine-slab-config/{configId}/slab-details` | ::getSlabDetails | `library.lib-fine-slab-config.slab-details` |
| POST | `lib-fine-slab-config/update-priority` | ::updatePriority | (unnamed) |
| POST | `lib-fine-slab-details/bulk-store` | ::bulkStore | `library.lib-fine-slab-details.bulk-store` |
| POST | `lib-fine-slab-details/bulk-update` | ::bulkUpdate | `library.lib-fine-slab-details.bulk-update` |
| POST | `lib-fine-slab-details/bulk-delete` | ::bulkDelete | `library.lib-fine-slab-details.bulk-delete` |
| Resource | `lib-fine-slab-details` | LibFineSlabDetailController | Detail CRUD |

### 6.8 Report Routes

| Method | Route | Controller::Method | Name | Auth |
|---|---|---|---|---|
| GET | `reports/fine-collection` | LibFineReportController::index | `library.reports.fine-collection` | ❌ No Gate |
| GET | `reports/fine-collection/export/{format}` | ::export | `library.reports.fine-collection.export` | ❌ No Gate |
| POST | `reports/fine-collection/refresh` | ::refresh | `library.reports.fine-collection.refresh` | ❌ No Gate |
| GET | `reports/circulation` | LibCirculationReportController::index | `library.reports.circulation` | ❌ No Gate |
| POST | `reports/circulation/refresh` | ::refresh | `library.reports.circulation.refresh` | ❌ No Gate |
| GET | `reports/print/{reportType}` | LibReportPrintController::print | `library.reports.print` | ❌ No Gate |
| GET | `reports/print/circulation` | ::printCirculation | `library.reports.print.circulation` | ❌ No Gate |
| GET | `reports/print/acquisition` | ::printAcquisition | `library.reports.print.acquisition` | ❌ No Gate |
| GET | `reports/print/digital` | ::printDigital | `library.reports.print.digital` | ❌ No Gate |
| GET | `reports/print/overdue` | ::printOverdue | `library.reports.print.overdue` | ❌ No Gate |
| GET | `reports/print/fine` | ::printFine | `library.reports.print.fine` | ❌ No Gate |

---

## 7. UI Screens

### 7.1 Hub and Dashboard

| Screen | Route | Status |
|---|---|---|
| SCR-LIB-01: Library Masters Hub (mega-tab view) | `library.tabIndex` | ✅ |
| SCR-LIB-02: Transaction Management Hub | `library.transactionsIndex` | ✅ |
| SCR-LIB-03: History / Audit Trail Hub | `library.historyIndex` | ✅ |
| SCR-LIB-04: Master Dashboard (KPI cards + charts) | `library.dashboard.master` | ✅ |
| SCR-LIB-05: Report Index | `library.reportIndex` | ✅ |

### 7.2 Reference Master Screens (11 entities)

Each entity has: index list (paginated), create form, edit form, show detail, trash/restore view.
Entities: Categories (with tree view), Authors, Genres, Keywords, Publishers, Resource Types, Book Conditions, Membership Types, Shelf Locations.

### 7.3 Book Catalogue Screens

| Screen | Status |
|---|---|
| SCR-LIB-10: Book Master List (title, ISBN, resource type, copies count, availability) | ✅ |
| SCR-LIB-11: Book Create/Edit Form (with inline author/publisher/category quick-create) | ✅ |
| SCR-LIB-12: Book Detail View (copies list, digital resources, curricular alignment) | ✅ |
| SCR-LIB-13: Book Copy List + Status Indicators | ✅ |
| SCR-LIB-14: Book Copy Create/Edit (accession, barcode, RFID, shelf, condition, vendor) | ✅ |
| SCR-LIB-15: Digital Resource List + License Status | ✅ |
| SCR-LIB-16: Digital Resource Create/Edit + Tag Management | ✅ |
| SCR-LIB-17: ISBN Lookup Modal (AJAX auto-fill) | ✅ |

### 7.4 Member and Transaction Screens

| Screen | Status |
|---|---|
| SCR-LIB-20: Member List (with status badges, outstanding fines indicator) | ✅ |
| SCR-LIB-21: Member Create/Edit (link to user, membership type, card barcode) | ✅ |
| SCR-LIB-22: Transaction List (issue/return/overdue status) | ✅ |
| SCR-LIB-23: Transaction Create (issue book — member + copy lookup) | ✅ |
| SCR-LIB-24: Transaction Detail (return/renew/mark-lost actions) | ✅ |
| SCR-LIB-25: Transaction History List | ✅ |
| SCR-LIB-26: Fine Calculation Detail (slab breakdown, AJAX) | ✅ |
| SCR-LIB-27: Reservation List (queue position, status) | ✅ |
| SCR-LIB-28: Reservation Create/Edit | ✅ |
| SCR-LIB-29: Reservation Cancel Form | ✅ |

### 7.5 Fine Management Screens

| Screen | Status |
|---|---|
| SCR-LIB-30: Fine List (pending/paid/waived with amounts) | ✅ |
| SCR-LIB-31: Fine Create Form (with auto-calculate AJAX) | ✅ |
| SCR-LIB-32: Fine Payment Form | ✅ |
| SCR-LIB-33: Fine Waiver Form (waived_amount, reason) | ✅ |
| SCR-LIB-34: Fine Slab Config List + Priority Order | ✅ |
| SCR-LIB-35: Fine Slab Detail (day-range rate table) | ✅ |

### 7.6 Inventory Audit Screens

| Screen | Status |
|---|---|
| SCR-LIB-40: Audit Session List | ✅ |
| SCR-LIB-41: Audit Initialize Form (date, expected count preview) | ✅ |
| SCR-LIB-42: Real-Time Scan Interface (barcode/RFID input, running totals) | ✅ |
| SCR-LIB-43: Audit Detail View (found/missing/misplaced/damaged breakdown) | ✅ |

### 7.7 Report Screens

| Screen | Status |
|---|---|
| SCR-LIB-50: Circulation Analysis Report (charts + tables) | ✅ |
| SCR-LIB-51: Fine Collection Report (summary + member breakdown) | ✅ |
| SCR-LIB-52: Overdue Report (list with estimated fines) | ✅ |
| SCR-LIB-53: Acquisition Report | ✅ |
| SCR-LIB-54: Digital Resource Usage Report | ✅ |
| SCR-LIB-55: PDF Export (print-ready layout, DomPDF) | ✅ |
| SCR-LIB-56: OPAC Catalogue Search (proposed) | 📐 |
| SCR-LIB-57: Reading Analytics Dashboard (proposed) | 📐 |

---

## 8. Business Rules

### 8.1 Membership and Borrowing

| Rule ID | Description | Status |
|---|---|---|
| BR-LIB-001 | Member cannot borrow more books than `membership_type.max_books_allowed` simultaneously | ✅ enforced in issue pre-validation |
| BR-LIB-002 | Due date = `issue_date + membership_type.loan_period_days` | ✅ |
| BR-LIB-003 | Book with `is_reference_only = true` cannot be issued | ✅ |
| BR-LIB-004 | Book copy with condition where `is_borrowable = false` cannot be issued | ✅ |
| BR-LIB-005 | Member with `status = suspended` or `status = deactivated` cannot borrow | ✅ |
| BR-LIB-006 | Member with `status = expired` cannot borrow until renewed | ✅ |
| BR-LIB-007 | Renewal permitted only if `renewal_allowed = true` AND `renewal_count < max_renewals` | ✅ |
| BR-LIB-008 | Renewed due date = `today + membership_type.loan_period_days` | ✅ |
| BR-LIB-009 | Member with outstanding fines above threshold may be blocked from new issues | 📐 Proposed — threshold configurable |

### 8.2 Fine Calculation

| Rule ID | Description | Status |
|---|---|---|
| BR-LIB-010 | Fine begins accruing after due date (grace period deduction not yet implemented) | 🟡 |
| BR-LIB-011 | `days_overdue = return_date - due_date - grace_period_days` (proposed enforcement) | 📐 |
| BR-LIB-012 | Fine = `days_overdue × rate_per_day` per matching slab detail row | ✅ |
| BR-LIB-013 | Total fine capped at `max_fine_amount` if configured | ✅ |
| BR-LIB-014 | Slab config lookup order: higher priority number evaluated first | ✅ |
| BR-LIB-015 | Fallback: `membership_type.fine_rate_per_day × days_overdue` if no slab matches | ✅ |
| BR-LIB-016 | Only `Pending` fines can be marked paid or waived | ✅ |
| BR-LIB-017 | Fine creation increments `lib_members.outstanding_fines` | ✅ |
| BR-LIB-018 | Fine payment/waiver should decrement `lib_members.outstanding_fines` | 🟡 Needs verification |

### 8.3 Reservation Queue

| Rule ID | Description | Status |
|---|---|---|
| BR-LIB-019 | Member cannot have two active (Pending or Available) reservations for the same book | ✅ unique constraint |
| BR-LIB-020 | Queue position = `max(queue_position) + 1` for active reservations on same book | ✅ |
| BR-LIB-021 | When book becomes available, first-in-queue reservation is marked Available | ✅ |
| BR-LIB-022 | If not collected by `pickup_by_date`, reservation should auto-expire | ❌ No scheduler |
| BR-LIB-023 | SMS/email notification sent when reservation status → Available | ❌ Flag set; not dispatched |

### 8.4 Inventory Audit

| Rule ID | Description | Status |
|---|---|---|
| BR-LIB-024 | Only one audit session `In Progress` at a time | 🟡 Business rule; no DB enforcement |
| BR-LIB-025 | Copy scanned at different shelf = misplaced | ✅ |
| BR-LIB-026 | Copy not scanned = missing | ✅ |
| BR-LIB-027 | `total_expected` = all active, non-withdrawn copies at session initialization | ✅ |

### 8.5 Digital Resources

| Rule ID | Description | Status |
|---|---|---|
| BR-LIB-028 | Access denied if `license_end_date < today` or `license_start_date > today` | ❌ Not enforced in controller |
| BR-LIB-029 | Download and view counts incremented atomically | ✅ |
| BR-LIB-030 | `access_restriction` JSON evaluated before serving download | ❌ Not implemented |

---

## 9. Workflows

### 9.1 Book Issue FSM

```
[Book Available] + [Member Active] + [Quota OK]
        |
        v
  Create Transaction (status: Issued)
  Copy status → issued
  LogHistory (action: issued)
        |
        v
[Due Date Approaches] ──── (scheduled reminder: not built) ────▶ Notify Member
        |
   Due Date Passed
        |
        v
  Mark Overdue (manual or via scheduled job — not built)
        |
      / | \
     /  |  \
    v   v   v
 Return  Lost  Renew
    |          |
    v          v
Returned   Due Date Extended
Copy → available  renewal_count++
LogHistory   LogHistory
(returned)   (renewed)
```

### 9.2 Fine Lifecycle FSM

```
[Transaction Overdue]
        |
        v
  Create Fine (status: Pending)
  member.outstanding_fines += amount
        |
      / | \
     /  |  \
    v   v   v
  Pay Waive  (remains Pending)
   |    |
   v    v
 Paid  Waived
member.outstanding_fines -= amount (needs verification)
Create lib_fine_payments
```

### 9.3 Reservation FSM

```
[Member places hold on book]
        |
        v
  Reservation (status: Pending, queue_position=N)
        |
        v
[Book returned / becomes available]
  Mark first-in-queue → Available
  notification_sent = true (SMS/email not dispatched — gap)
        |
      / | \
     /  |  \
    v   v   v
Picked_Up Cancel Expired (past pickup_by_date — no scheduler)
```

### 9.4 Inventory Audit Workflow

```
Librarian: Initialize Audit
        |
        v
  Session Created (status: In Progress)
  total_expected calculated
        |
        v
Scan Loop: scan barcode/accession/RFID
  checkCopy → returns copy status
  storeWithDetails / bulkStore → creates detail records
  Classifications: found | misplaced | missing | damaged
        |
        v
  Complete Audit → status: Completed
  OR Cancel → status: Cancelled
```

---

## 10. Non-Functional Requirements

### 10.1 Performance Targets

| Requirement | Target | Current Status |
|---|---|---|
| Book catalogue list page load (10,000 titles) | < 2 seconds | ✅ Paginated at 15/page + FULLTEXT index |
| Transaction create (issue) | < 1 second | ✅ |
| Report generation (12-month circulation) | < 10 seconds | 🟡 In-memory service — risk at 5,000+ records |
| ISBN lookup (external API) | < 3 seconds | 🟡 No timeout configured |
| Inventory audit scan per barcode | < 500ms | ✅ |
| Fine calculation (slab lookup) | < 200ms | ✅ |

### 10.2 Scalability

- Per-tenant DB isolation ensures no cross-school data contamination
- `paginate(15)` on all list pages
- FULLTEXT index on `lib_books_master` (title, subtitle, summary) for search
- Composite indexes on `lib_transactions` for date-range queries
- Partial index on `lib_transactions(status, due_date)` for overdue lookups
- 📐 Report services should migrate from in-memory iteration to SQL `GROUP BY`/`selectRaw` aggregation

### 10.3 Security

| Requirement | Status |
|---|---|
| `auth` + `verified` middleware on all routes | ✅ Applied at route group |
| `EnsureTenantHasModule` middleware | ❌ Missing — P0 fix required |
| `Gate::authorize()` on all destructive/financial actions | ❌ 6 controllers missing — P0/P1 fix |
| CSRF protection (web middleware) | ✅ Inherited |
| `$request->validated()` for all form submissions | 🟡 Multiple controllers use `$request->all()` |
| Digital resource license validation before download | ❌ Not enforced |
| File upload type/size validation (digital resources, book covers) | 🟡 Needs audit |
| External API timeout (IsbnLookupService) | ❌ No timeout configured |

### 10.4 Data Integrity

- All 35 models use `SoftDeletes` — restore capability maintained
- Cascade deletes on junction tables (book_author_jnt, book_category_jnt, etc.)
- Unique constraints: ISBN, membership_number, library_card_barcode, accession_number, barcode, receipt_number
- DB-level ENUM constraints on status fields
- `CHECK (amount >= 0)`, `CHECK (outstanding_fines >= 0)` constraints on fine tables

### 10.5 Compatibility

- MySQL 8.x, InnoDB, UTF8MB4
- Laravel 12 + PHP 8.2
- nwidart/laravel-modules v12
- stancl/tenancy v3.9 (InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive)
- DomPDF for PDF generation (synchronous — potential timeout for large reports)

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Module | Dependency | Usage | Status |
|---|---|---|---|
| `sys_users` / `App\Models\User` | `lib_members.user_id` FK | Member-to-user link | ✅ |
| `sys_media` | `lib_digital_resources.file_media_id` | Digital file storage | ✅ |
| Vendor Module (`Modules\Vendor\Models\Vendor`) | `lib_book_copies.vendor_id` | Purchase vendor reference | 🟡 Cross-layer import: 22 controllers import Vendor unnecessarily |
| `sch_classes` | `lib_book_subject_jnt.class_id` | Curricular alignment | ❌ UI not built |
| `sch_subjects` | `lib_book_subject_jnt.subject_id` | Curricular alignment | ❌ UI not built |
| SLK Module (SyllabusBooks) | `lib_book_subject_jnt` linking | Syllabus-library bridge | 📐 Proposed (FR-LIB-044) |
| NTF Module (Notifications) | Reservation availability, overdue reminders | Dispatch notifications | ❌ Not wired |
| FIN Module (StudentFee) | `lib_fines` to student fee account | Fine-to-fee linkage | ❌ Not connected |
| STD Module (Student) | `std_students` to member profile | Student enrollment context | ❌ Members link to `users` only |

### 11.2 External API Dependencies

| Service | Endpoint | Purpose | Status |
|---|---|---|---|
| Open Library | `https://openlibrary.org/api/books` | ISBN metadata lookup | ✅ No API key needed |
| Google Books | `https://www.googleapis.com/books/v1/volumes` | ISBN lookup fallback | 🟡 No API key — rate limited |

### 11.3 Cross-Layer Import Issue (P1)

22 controllers import `Modules\Vendor\Models\Vendor` — this is a cross-module dependency. The Vendor model is likely used only to populate a vendor dropdown in book copy create/edit forms. This import should be:
1. Removed from all controllers that do not directly use vendor data
2. In `LibBookCopyController`, replaced with a lightweight data transfer approach (e.g., via a shared service or a JSON endpoint) rather than a direct cross-module Model import

---

## 12. Test Scenarios

### 12.1 Existing Browser (Dusk) Tests

| Test File | Coverage |
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

### 12.2 Proposed Unit Test Scenarios (Priority: High)

| Test ID | Scenario | Test Type | Priority |
|---|---|---|---|
| TST-LIB-001 | Fine calculation: slab lookup with priority ordering | Unit (FineCalculationService) | P0 |
| TST-LIB-002 | Fine calculation: fallback to membership_type rate when no slab | Unit | P0 |
| TST-LIB-003 | Fine calculation: max_fine_amount cap applied | Unit | P0 |
| TST-LIB-004 | Fine grace period subtracted from days_overdue | Unit | P1 |
| TST-LIB-005 | Renewal: blocked when `renewal_allowed = false` | Unit | P0 |
| TST-LIB-006 | Renewal: blocked when `renewal_count >= max_renewals` | Unit | P0 |
| TST-LIB-007 | Issue: blocked when member quota exceeded | Unit | P0 |
| TST-LIB-008 | Issue: blocked when `is_reference_only = true` | Unit | P1 |
| TST-LIB-009 | Issue: blocked when copy condition `is_borrowable = false` | Unit | P1 |
| TST-LIB-010 | Reservation queue position assignment | Unit | P1 |
| TST-LIB-011 | `outstanding_fines` incremented on fine creation | Feature | P0 |
| TST-LIB-012 | `outstanding_fines` decremented on fine payment | Feature | P0 |
| TST-LIB-013 | Copy status transitions: available → issued → available | Feature | P1 |
| TST-LIB-014 | Duplicate `lib_fines` DDL does not block migration | Integration | P0 |
| TST-LIB-015 | EnsureTenantHasModule blocks access when Library not licensed | Feature | P0 (after FR-LIB-039) |
| TST-LIB-016 | LibFineController::waive requires authorization | Feature | P0 (after auth fix) |
| TST-LIB-017 | Digital resource download blocked after license expiry | Feature | P1 (after FR-LIB-012 fix) |
| TST-LIB-018 | ISBN lookup populates book form fields from Open Library | Feature | P2 |
| TST-LIB-019 | Circulation report data matches transaction count in DB | Feature | P2 |
| TST-LIB-020 | Inventory audit: misplaced classification when actual_location != expected | Unit | P1 |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Accession Number | Unique sequential number assigned to each physical book copy when added to library collection |
| OPAC | Online Public Access Catalogue — the public-facing catalogue search interface for students and staff |
| Membership Type | Configuration record defining borrowing limits, loan duration, and fine rates for a member category |
| Loan Period | Number of days a member may keep a borrowed book before it is overdue |
| Grace Period | Additional days after the due date before fines begin accruing (`grace_period_days` in `lib_membership_types`) |
| Fine Slab | A configurable rate table defining per-day fine amounts for different day ranges (e.g., Day 1–7: ₹1/day, Day 8–30: ₹2/day) |
| Book Copy | A single physical instance of a book title, identified by accession number and barcode |
| Reservation / Hold | A queue entry for a member waiting for a checked-out book to become available |
| Queue Position | Numeric position in the reservation queue for a given book; lower number = higher priority |
| Inventory Audit | A formal physical stock count to reconcile system records with actual shelf inventory |
| Digital Resource | An e-book, PDF, or audio file associated with a book master record; governed by license dates |
| Member Segment | Computed classification of member engagement: High-Value, At-Risk, Inactive, New |
| Curricular Alignment | Linkage between a library book and a school class/subject in the curriculum |

---

## 14. Suggestions & Roadmap

### 14.1 P0 — Critical (Fix Before Production)

1. **Add `EnsureTenantHasModule` middleware** (FR-LIB-039): one-line change in tenant.php line 2719. Prevents unlicensed schools from accessing library routes.

2. **Add `Gate::authorize()` to 6 zero-auth controllers**:
   - `LibraryController` (tabIndex, transactionIndex, historyIndex) → `tenant.library.access`
   - `MasterDashboardController` (index) → `tenant.library.dashboard.view`
   - `LibFineController` (all methods) → `tenant.lib-fines.*` — especially `waive` is a HIGH-RISK financial operation
   - `LibCirculationReportController` → `tenant.lib-reports.circulation`
   - `LibFineReportController` → `tenant.lib-reports.fine`
   - `LibReportPrintController` → `tenant.lib-reports.print`

3. **Fix DDL duplicate `lib_fines`**: Remove the first definition (line 8293); keep the second (line 8384).

### 14.2 P1 — High Priority (Current Sprint)

4. **Standardize permission prefix**: Choose `tenant.lib-*` throughout. `LibTransactionController` currently uses `library.lib-transactions.*`. Update AppServiceProvider policy bindings.

5. **Replace `$request->all()` with `$request->validated()`**: In `LibFineController::update()`, `LibReservationController::update()`, `LibTransactionController` (multiple methods), `LibFineSlabDetailController::update()`, `LibReportPrintController`, `LibInventoryAuditDetailController`.

6. **Remove unused Vendor model imports**: From 22 controllers — keep only in `LibBookCopyController` where vendor dropdown is actually needed.

7. **Add `FormRequest` for LibReservation**: Currently uses inline validation or `$request->all()`.

8. **Add feature tests for critical business logic** (see TST-LIB-001 through TST-LIB-016).

9. **Fix `lib_book_category_jnt` dual PK**: Remove `id AUTO_INCREMENT` column; use `PRIMARY KEY (book_id, category_id)` only.

### 14.3 P2 — Medium Priority (Next Sprint)

10. **Enforce digital resource license check** (FR-LIB-012): Add `license_start_date <= today <= license_end_date` validation before serving download in `LibDigitalResourceController`.

11. **Verify `outstanding_fines` decrement**: Audit `LibFine::markPaid()` and `LibFine::waive()` to confirm member's outstanding_fines is correctly decremented.

12. **Implement grace period** (FR-LIB-046): Subtract `membership_type.grace_period_days` from days_overdue in `LibTransactionController::getFineCalculation()`.

13. **Extract service layer** (FR-LIB-047): Create `TransactionService`, `ReservationService`, `FineCalculationService`.

14. **Wire notification dispatch** (FR-LIB-045): Dispatch notification when reservation `markAvailable()` is called.

15. **Fix `lib_book_copies.rfid_tag` NOT NULL**: Change to `VARCHAR(100) NULL` with UNIQUE ignoring NULLs, or generate UUID placeholder for schools without RFID hardware.

16. **Add Google Books API key**: Configure `GOOGLE_BOOKS_API_KEY` in `.env` and `config/services.php`; pass in `IsbnLookupService`.

17. **Add timeout/error handling to `IsbnLookupService`**: HTTP client timeout (3s), fallback behavior on API failure.

18. **Policy for `LibFinePayment`**: Currently no policy class exists.

19. **Remove Hindi debug comment**: `MasterDashboardController.php` line 24 contains debug comment in Hindi.

### 14.4 P3 — Long-Term Roadmap

20. **Scheduled Artisan commands** (FR-LIB-041):
    - `library:send-overdue-reminders` — daily notification to members with overdue books
    - `library:expire-reservations` — auto-expire reservations past `pickup_by_date`
    - `library:expire-memberships` — mark expired memberships at `expiry_date`

21. **OPAC Catalogue Search** (FR-LIB-042): Public-facing search for students/staff — title, author, ISBN, subject.

22. **Barcode/QR scan-first workflow** (FR-LIB-043): `scan/book/{barcode}` + `scan/member/{barcode}` endpoints for streamlined issue/return.

23. **SLK module integration** (FR-LIB-044): Link `lib_books_master` to `bok_syllabus_books` via ISBN/title.

24. **Refactor report services to DB aggregation**: Replace in-memory `LibCirculationReportService` collection iteration with SQL `GROUP BY`/`selectRaw` for schools with 5,000+ records.

25. **Reading behavior analytics**: Build `AnalyticsScheduleService` to compute `lib_reading_behavior_analytics` from transaction history (schema + models exist).

26. **Book popularity trends**: Build service to compute `lib_book_popularity_trends` daily.

27. **Curricular alignment UI**: Allow librarians to map books to classes/subjects with alignment scores.

28. **AI metadata enrichment**: Pipeline to generate `ai_summary`, `key_concepts`, `tags` for newly added books using LLM.

29. **Member segment algorithm**: Implement actual High-Value/At-Risk/Inactive/New segmentation in `calculateSegment()` action.

30. **Student/Parent Portal integration**: Self-service book search, reservation, fine viewing via STP module.

---

## 15. Appendices

### 15.1 Controller Audit Summary

| Controller | Gate::authorize | $request->all() | Vendor Import | FormRequest |
|---|---|---|---|---|
| LibCategoryController | ✅ (13 calls) | No | Yes (unused) | LibCategoryRequest |
| LibAuthorController | ✅ | No | Yes (unused) | LibAuthorRequest |
| LibGenreController | ✅ | No | Yes (unused) | LibGenreRequest |
| LibKeywordController | ✅ | No | Yes (unused) | LibKeywordRequest |
| LibPublisherController | ✅ | No | Yes (unused) | LibPublisherRequest |
| LibResourceTypeController | ✅ | No | Yes (unused) | LibResourceTypeRequest |
| LibBookConditionController | ✅ | No | Yes (unused) | LibBookConditionRequest |
| LibMembershipTypeController | ✅ | No | Yes (unused) | LibMembershipTypeRequest |
| LibShelfLocationController | ✅ | No | Yes (unused) | LibShelfLocationRequest |
| LibBookMasterController | ✅ (11 calls) | Partial | Yes | LibBookMasterRequest |
| LibBookCopyController | ✅ | No | Yes (needed) | LibBookCopyRequest |
| LibDigitalResourceController | ✅ | No | Yes (unused) | LibDigitalResourceRequest |
| LibDigitalResourceTagController | ❌ Zero | No | Yes (unused) | None |
| LibMemberController | ✅ | No | Yes (unused) | LibMemberRequest |
| LibTransactionController | ✅ (10 calls) | Yes (multiple) | Yes (unused) | LibTransactionRequest |
| LibReservationController | ✅ (11 calls) | Yes | Yes (unused) | None |
| LibFineController | ❌ Zero | Yes | Yes (unused) | LibFineRequest |
| LibFineSlabConfigController | ✅ | No | Yes (unused) | LibFineSlabConfigRequest |
| LibFineSlabDetailController | ✅ | Yes | Yes (unused) | LibFineSlabDetailRequest |
| LibInventoryAuditController | ✅ | No | Yes (unused) | LibInventoryAuditRequest |
| LibInventoryAuditDetailController | Partial | Yes | Yes (unused) | None |
| LibraryController (hub) | ❌ Zero | No | Yes (unused) | None |
| MasterDashboardController | ❌ Zero | No | No | None |
| LibCirculationReportController | ❌ Zero | Yes | No | None |
| LibFineReportController | ❌ Zero | No | No | None |
| LibReportPrintController | ❌ Zero | Yes | No | None |

### 15.2 Model Inventory (35 Models)

LibAuthor, LibBookAuthorJnt, LibBookCategoryJnt, LibBookCondition, LibBookConditionJnt, LibBookCopy, LibBookGenreJnt, LibBookKeywordJnt, LibBookMaster, LibBookPopularityTrend, LibBookSubjectJnt, LibCategory, LibCollectionHealthMetric, LibCurricularAlignment, LibDigitalResource, LibDigitalResourceTag, LibEngagementEvent, LibFine, LibFinePayment, LibFineSlabConfig, LibFineSlabDetail, LibGenre, LibInventoryAudit, LibInventoryAuditDetail, LibKeyword, LibMember, LibMembershipType, LibPredictiveAnalytic, LibPublisher, LibReadingBehaviorAnalytics, LibReservation, LibResourceType, LibShelfLocation, LibTransaction, LibTransactionHistory.

All 35 models have `SoftDeletes` trait — excellent compliance.

### 15.3 Service Inventory (9 Services)

| Service | Responsibility |
|---|---|
| `IsbnLookupService` | Open Library + Google Books API for ISBN auto-fill |
| `LibCirculationReportService` | Circulation analysis (in-memory — performance risk) |
| `LibFineReportService` | Fine collection report data |
| `LibDashboardReportService` | Dashboard KPI aggregation |
| `LibChartService` | Chart.js-compatible data arrays |
| `LibAcquisitionReportService` | New book additions report |
| `LibDigitalReportService` | Digital resource usage report |
| `LibOverdueReportService` | Overdue books report |
| `MasterDashboardService` | Master dashboard aggregation |

Missing services (proposed): `TransactionService`, `ReservationService`, `FineCalculationService`, `MemberService`.

### 15.4 Key File Paths

| File | Purpose |
|---|---|
| `/Users/bkwork/Herd/prime_ai/Modules/Library/` | Module root |
| `/Users/bkwork/Herd/prime_ai/routes/tenant.php` lines 2719–2967 | Library route registration |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/routes/web.php` | Dead code — all routes commented |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Controllers/` | 26 controllers |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Models/` | 35 models |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Services/` | 9 services |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Http/Requests/` | 19 FormRequests |
| `/Users/bkwork/Herd/prime_ai/Modules/Library/app/Policies/` | 23 policies |
| `/Users/bkwork/Herd/prime_ai/tests/Browser/Modules/Library/` | 15 Dusk test files |
| `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-DDL_Tenant_Modules/64-Library/DDL/Library_ddl_v1.sql` | Primary Library DDL (1,178 lines) |

---

## 16. V1 → V2 Delta

### 16.1 Corrections from V1

| V1 Claim | V2 Correction | Source |
|---|---|---|
| "Module NOT wired into tenant.php at all (module unreachable)" | Module IS wired at tenant.php lines 2719–2967. All routes functional. | Gap analysis 2026-03-22 |
| "7 controllers zero auth" | Corrected to 6 controllers with zero `Gate::authorize()` calls (LibraryController, MasterDashboardController, LibFineController, LibCirculationReportController, LibFineReportController, LibReportPrintController) | Gap analysis code audit |
| "Module completion ~45%" | Revised to ~55% — all primary business flows implemented; missing items are security, scheduled jobs, and advanced analytics | Gap analysis section 13 |
| "8 controllers use `$request->all()`" | Confirmed across: LibFineController, LibReservationController, LibTransactionController (multiple), LibFineSlabDetailController, LibReportPrintController, LibInventoryAuditDetailController, LibCirculationReportController | Gap analysis section 3 |
| "34 DDL tables" | Confirmed 35 tables (33 in Library DDL v1 + `lib_engagement_events` and analytics tables) | Gap analysis section 1 |

### 16.2 New Content Added in V2

| Section | New Content |
|---|---|
| Section 4.9 | 9 new proposed functional requirements (FR-LIB-039 through FR-LIB-047) |
| Section 6.1 | Exact route fix with code snippet for `EnsureTenantHasModule` |
| Section 6.2–6.8 | Full route tables with Auth column showing zero-auth gaps |
| Section 8 | Business rules table with implementation status column |
| Section 12.2 | 20 proposed test scenarios with test type and priority |
| Section 13 | Glossary (new in V2) |
| Section 15.1 | Full controller audit matrix (Gate, $request->all, Vendor import, FormRequest) |
| Section 16 | This delta section |

### 16.3 Issues Carried Forward (Unresolved from V1)

All P0–P2 issues from V1 Section 14 remain open. Key ones:
- DDL-001 (duplicate `lib_fines`), DDL-002 (dual PK), DDL-003 (rfid_tag NOT NULL), DDL-004–008 (FK mismatches)
- Zero-auth controllers (now reclassified as P0 for LibFineController waiver)
- `$request->all()` mass assignment
- Grace period not enforced
- `outstanding_fines` decrement unverified
- Reservation notification not dispatched
- No scheduled commands for overdue/expiry
- No unit/feature tests

---

*Document generated from: V1 requirement (2026-03-25), Gap Analysis (2026-03-22), tenant.php lines 2719–2967 (live code), Modules/Library source code (26 controllers, 35 models, 9 services, 19 FormRequests, 23 policies), Library DDL v1 (1,178 lines), 15 browser test files.*
*V2 Author: Claude Code (Automated Analysis) | 2026-03-26*
