# Library Main Hub — Business Requirements

## What This Screen Does

The Library Main Hub is the central navigation and data management screen for the Library module. It is a multi-tab hub page that consolidates all library sub-modules into six major sections: Masters, Configuration, Book Acquisition, Operations, Fines, and History & Audit. Each section is handled by a dedicated controller method that loads all sub-resource data, applies tab-scoped filters and search, and renders independent paginated tables within tab panes. The hub uses a single view per section with `@include` partials for each sub-tab's table body, following the tab-based hub pattern.

This is not a single screen but a family of hub screens — `tabIndex` (Masters), `configIndex` (Configuration), `acquisitionIndex` (Acquisition), `transactionIndex` (Operations), `finesIndex` (Fines), and `historyIndex` (History & Audit). Each hub method loads all sub-resources for that section simultaneously but only applies filters to the currently active tab to avoid query pollution across tabs.

---

## When This Screen Is Used

- When navigating to any part of the Library module for management or data entry
- When browsing master data such as Categories, Authors, Genres, Publishers
- When configuring fines, slabs, account entries, or library statuses
- When managing book acquisition activities — books master, purchases, copies, digital resources
- When processing library transactions — issues, returns, reservations, renewals
- When reviewing fines and collecting payments
- When auditing the library — transaction history, inventory audits, engagement events, settings

## Default Data Load

Each hub method loads all sub-resource queries simultaneously at the top of the method, each independently paginated (15 per page default, 20 for engagement events and settings) with unique paginator page names (e.g., `categories_page`, `authors_page`, `books_page`). Shared dropdown data for filters (buildings, zones, vendors, status lists) is loaded as active-only collections with no pagination. Tab permissions are enforced via a `$tabPermissions` map — only the active tab's permission is checked with `Gate::authorize()` at method entry.

---

---

## Key Fields at a Glance

Each sub-tab within the hub manages a distinct entity. The Masters hub covers Categories (hierarchical with parent-child and display_order), Authors (linked to countries and genres), Genres, Keywords, Publishers, Resource Types (physical/digital/audio flags), Membership Types (loan periods, max books, renewal rules), Location Masters (building-linked zone/floor/aisle/shelf/rack hierarchy), Shelf Locations (full location path), and Book Conditions (borrowable flag). The Configuration hub covers Fine Types, Fine Slab Configs (with membership/resource/fine type filters and priority), Fine Slab Details (day-range-based rate tables), Account Entry Configs (linking fines to accounting ledgers), and Library Status Masters (enum-based dynamic statuses across 9 status types). The Acquisition hub covers Books Master (full bibliographic data with relationships), Book Purchases (vendor bills and items), Book Copies (barcoded individual copies with location/condition/status), Digital Resources (file-based with license management), Access Restrictions (role/user/designation/department-based), and Digital Access Request Types. The Operations hub covers Transactions (issue/return lifecycle), Physical Book Requests (reservations and renewal requests), Digital Access Requests, Digital Access Transactions (granted access tracking), Curricular Alignments (book-to-curriculum mapping), and Book Reviews (moderated ratings). The History & Audit hub covers Transaction History, Inventory Audits, Engagement Events, and Library Settings.

---

## Business Rules and Conditions

1. **Tab-Scoped Filtering** — Each private query method checks `$request->input('tab')` before applying filters (`search`, `status`, date ranges). If the active tab does not match, filters are skipped to prevent cross-tab filter pollution.

2. **Unique Paginator Names** — Every sub-resource uses a distinct paginator page name (e.g., `books_page`, `copies_page`, `resources_page`) so that paginating one tab does not reset another tab's pagination.

3. **Permission Mapping** — Each hub method uses a `$tabPermissions` associative array mapping tab IDs to `tenant.{slug}.viewAny` permission strings. The default fallback permission targets the first tab's permission. `Gate::any()` with all tab permissions is used in `historyIndex` to allow access if the user has at least one tab's viewAny permission.

4. **Dual Security (Frontend + Backend)** — The hub view's `x-backend.tab.nav-tab` component uses the `permission` key to hide tab navigation items, and each `@include` within the tab body is additionally wrapped in `@can` for double-layer security.

5. **AJAX-Driven Search** — All hub index methods support standard GET form submissions. The `LibraryConfigController` additionally supports `wantsJson()` for AJAX partial table reloads.

6. **Book Availability Service** — The `checkBookAvailability` endpoint uses `BookAvailabilityCheckService` to scan all active books, update availability status, send notifications for newly available books, and return a JSON report.

---

## Workflow Steps

1. User navigates to Library → any hub section (Masters, Config, Acquisition, etc.)
2. System checks tab permission and loads all sub-resource queries with filters scoped to the active tab
3. User sees the hub view with tab navigation at the top and the active tab's content below
4. User clicks a different tab — the page reloads with `?tab={tab_id}` in the URL
5. User applies search or filter — form submit includes `tab={tab_id}` as a hidden field
6. User paginates — pagination links include `tab={tab_id}` to maintain tab state
7. From any tab, user can click Add/Create/View/Edit/Delete to navigate to the dedicated resource controller

---

## Example Scenario

A Library Admin opens the Library Masters hub and sees the Categories tab by default. They click the Authors tab to browse authors — the URL changes to `?tab=authors` and the system loads only the authors list with search and pagination. They search for "Shakespeare" in the search bar and the authors list filters to matching records. They then click over to the Books tab under Acquisition to check a newly purchased book, finding it via the publisher filter dropdown.

---

## Related Screens

- All dedicated resource controllers (LibCategoryController, LibAuthorController, LibBookMasterController, etc.) — accessed via the hub's action buttons
- Master Dashboard — top-level overview, separate from the hub
- Reports — separate routing group under `/reports/` prefix
- Export — available across all hub entities via `/export/{entity}/{format}`

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibraryController`
**Models:** All Library models (51 models under `Modules\Library\Models\`)
**Services:** `BookAvailabilityCheckService` for the check-book-availability endpoint
**Route Base:** `/library-mgt/` with six hub endpoints and one utility endpoint

Hub methods:
- `tabIndex(Request)` — Masters hub (10 sub-tabs: categories, genres, authors, keywords, publishers, resource-type, membership-type, location-masters, shelf-locations, book-condition)
- `configIndex(Request)` — Configuration hub (5 sub-tabs: fine-types, fine-slab-configs, fine-slab-details, account-entry-configs, library-status-masters)
- `acquisitionIndex(Request)` — Acquisition hub (6 sub-tabs: books, book-purchases, book-copies, digital-resources, access-restrictions, digital-access-request-types)
- `transactionIndex(Request)` — Operations hub (8 sub-tabs: reservations, transactions, digital-access-requests, renewal-requests, digital-access, curricular-alignments, approved-reviews)
- `finesIndex(Request)` — Fines listing with search by member/book, filter by status, fine type, member
- `historyIndex(Request)` — History & Audit hub (4 sub-tabs: transactions-history, inventory-audit, engagement-events, library-settings)
- `checkBookAvailability(Request, BookAvailabilityCheckService)` — Utility method to scan and update book availability

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | All `tenant.lib-*` permissions | Full hub access (bypasses via Gate::before) |
| Library Admin | All `tenant.lib-*` permissions | Full access to all tabs |
| Librarian | Tab-specific `tenant.{slug}.viewAny` | Access only to permitted tabs |
| Library Assistant | Tab-specific `tenant.{slug}.viewAny` | Read-only access to permitted tabs |

---

## How This Screen Works — Logic Flow (Non-Technical)

When the librarian opens any hub section, the system checks their permission for the active tab and loads all the data tables for that section's sub-modules at once — but only applies the search and filter to the currently visible tab. For example, opening the Masters hub loads categories, authors, genres, keywords, publishers, and all other master data simultaneously, but search and status filters only affect the categories tab because that's the default. Clicking a different tab re-loads the page with the appropriate tab parameter, and the filter now applies to the new active tab. Each table has its own pagination that stays independent — paginating to page 3 of categories won't affect page 1 of authors.

---

## Validate Before Save

(The hub itself has no save validation — validation occurs in individual resource controllers and their FormRequests when creating, editing, or deleting records from within the hub.)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Gate authorization fails for tab | This action is unauthorized. | 403 |
| Gate::any fails (all tabs denied) | 403 via abort(403) | 403 |
| Invalid tab parameter | Falls back to default tab permission | 403 if unauthorized |

---

## Success Scenarios

**SS-001: Navigate between tabs**
1. User opens Masters hub — Categories tab loads by default
2. User clicks Genres tab — page reloads with `?tab=genres`
3. Genres table loads with active search/status applied to genres only
4. Categories table remains loaded but hidden behind inactive tab

**SS-002: Search within a specific tab**
1. User is on the Acquisition hub with the Books tab active
2. User types "Physics" in search and clicks submit
3. Hidden `tab=books` field ensures search targets the Books query only
4. Books table filters to titles containing "Physics"

**SS-003: Tab-scoped pagination**
1. User paginates Categories to page 3 (uses `categories_page=3`)
2. User clicks Genres tab — pagination parameter reset
3. User returns to Categories — still on page 3

--- 

## Failure Scenarios

**FS-001: User without any tab permission**
1. User with no `tenant.lib-*` permissions opens Masters hub
2. `Gate::authorize()` on the default tab throws AuthorizationException
3. User receives 403 Forbidden page

**FS-002: User with one tab permission but accesses another**
1. User has `tenant.lib-categories.viewAny` but opens `?tab=authors`
2. `Gate::authorize('tenant.lib-authors.viewAny')` throws AuthorizationException
3. User receives 403 Forbidden — the Authors tab is hidden from navigation

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | All 51 lib_* tables | Every Library module table is referenced from at least one hub |
| Module | Library Models | All 51 models under `Modules\Library\Models` |
| Module | School Setup | `sch_buildings`, `sch_classes`, `sch_subjects` for location/curricular reference data |
| Module | Vendor | `vnd_vendors` for book purchase vendor references |
| Service | `BookAvailabilityCheckService` | Utility for the check-book-availability endpoint |
| Component | `x-backend.tab.nav-tab` | Blade component for tab navigation with permission key support |
