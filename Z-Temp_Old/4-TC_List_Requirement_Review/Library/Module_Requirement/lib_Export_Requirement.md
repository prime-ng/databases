# Export — Business Requirements

## What This Screen Does

The Export feature provides a unified mechanism for exporting any Library module entity to Excel (.xlsx), CSV, or PDF format. A generic `LibExportController` routes export requests through a single `export()` method that takes an entity slug and format parameter. The controller uses a large configuration array (`getEntityConfig()`) defining model class, columns, resolvers, and permission for each exportable entity. Data is exported using `Maatwebsite\Excel` for Excel/CSV and `Barryvdh\DomPDF` for PDF, with a shared Blade view for PDF rendering.

The export supports 35+ entities across all Library hubs — masters, config, acquisition, transactions, history, fines, members, and analytics. Each entity's column list and relation resolvers are defined in the config, enabling label-friendly column headers and relation-based value resolution (e.g., `publisher.name` instead of a raw foreign key ID).

---

## When This Screen Is Used

- When downloading a master list of all library members for offline records or audit
- When exporting book inventory data (titles, copies, conditions) for stock verification
- When generating fine reports or transaction histories for management
- When printing catalog lists for physical distribution or library guides
- When exporting analytics data (reading behavior, popularity trends, collection health) for external analysis
- When backing up configuration data such as fine slabs, account entries, or status masters

## Default Data Load

Export is triggered via GET request to `/export/{entity}/{format}` or `/library-mgt/export/{entity}/{format}`. The entity slug identifies which configuration to use from `getEntityConfig()`. The `buildQuery()` method optionally applies search (`?search=`) and status (`?status=`) filters from the request. For view-based entities (member-360, collection-perf, predictive-demand, overdue-books, most-issued), the query runs against MySQL views (`lib_view_*` tables) with tab-specific filter support. No pagination — all matching records are exported.

---

---

## Key Fields at a Glance

**Entity Configuration Structure**
Each exportable entity defines: `label` (human-readable name for file naming and PDF title), `model` (Eloquent model class for query building, or null for view-based entities), `columns` (array of field names to include), `resolvers` (mapping of field names to display labels and optional `relation` or `boolean` configuration), and `permission` (the Gate string required to export this entity).

**Column Resolution**
Simple fields are exported as-is. Relation fields (e.g., `publisher_id`) are resolved using dot-notation relation paths (e.g., `publisher.name`) to display human-readable values. Boolean fields are resolved via the `boolean => true` resolver option, converting 1/0 to Yes/No in output.

**Export Format Differences**
Excel and CSV exports use `GenericExport` with `Maatwebsite\Excel` — supports both `.xlsx` and `.csv` writer types. PDF exports use a generic Blade template (`library::lib-reports.exports.generic-pdf`) that renders records in a table with the configured columns and resolvers, then downloads as PDF.

---

## Business Rules and Conditions

1. **Permission Gating** — Each entity has its own permission string. The controller calls `Gate::authorize($entityConfig['permission'])` before building the query. For example, exporting books requires `tenant.lib-books-master.viewAny`.

2. **Unknown Entity Handling** — If the entity slug does not match any key in `getEntityConfig()`, the controller returns `abort(404, "Unknown entity: {$entity}")`.

3. **Unsupported Format Handling** — If the format is not `pdf`, `excel`, or `csv`, the controller returns `abort(400, "Unsupported format: {$format}")`.

4. **View-Based Entity Query** — Five entities (analytics-member-360, analytics-collection-perf, analytics-predictive-demand, analytics-overdue-books, analytics-most-issued) use MySQL views instead of Eloquent models. The `buildQuery()` method detects these via a `$viewEntities` map and runs `DB::table()` queries against the views instead.

5. **Tab-Specific Filters** — View-based entities support tab-specific filter parameters such as `min_engagement`, `segment_filter`, `demand_filter`, `min_confidence`, `min_overdue_days`, `min_issues`, etc.

6. **File Naming** — Exported files are named `{EntityLabel}_{YYYY-MM-DD}.{ext}` (e.g., `Categories_2026-07-24.xlsx`).

7. **Resolvers for Labels** — Each column in the resolvers map can optionally define a `label` for the PDF column header. If no resolver is provided, the raw column name is used.

---

## Workflow Steps

1. User navigates to any Library screen and clicks the Export button
2. User selects the target entity (pre-selected based on current screen) and format (Excel/CSV/PDF)
3. System appends optional search/filter parameters from the current view
4. User clicks Export — URL format: `/export/{entity}/{format}`
5. Controller validates entity exists in config, authorizes permission, builds query
6. For Excel/CSV: `GenericExport` processes records and streams the file download
7. For PDF: Blade template renders the table and streams the PDF download

---

## Example Scenario

A Library Admin wants to generate a list of all active members for the annual audit. They navigate to the Members screen and click Export, select "Excel" format, and click Download. The system calls `/export/lib-members/excel`, authorizes via `tenant.lib-members.viewAny`, queries all `LibMember` records with user and membership type relations, and streams a `.xlsx` file with columns: Membership Number, User Name, Membership Type, Registration Date, Expiry Date, Total Books Borrowed, Status, and Active status. The admin saves the file to their audit folder.

---

## Related Screens

- **Library Main Hub** — All hub screens have export triggers linked to this controller
- **Reports** — Report screens have dedicated print endpoints (`/reports/print/{reportType}`) that use `LibReportPrintController` for formatted report PDFs (not generic export)
- **Analytics** — Analytics views export through this controller with view-based entity configs

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibExportController`
**Export Classes:** `Modules\Library\Exports\GenericExport` (Maatwebsite\Excel)
**PDF View:** `library::lib-reports.exports.generic-pdf`
**Libraries:** `barryvdh/laravel-dompdf` (PDF), `maatwebsite/laravel-excel` (Excel/CSV)
**Routes:** `GET /export/{entity}/{format}` and `GET /library-mgt/export/{entity}/{format}`

Key controller methods:
- `export(Request, string $entity, string $format)` — Main export entry point; looks up config, authorizes, builds query, downloads file
- `getEntityConfig(string $entity): ?array` — Returns config array for 40+ entities (categories, genres, authors, keywords, publishers, resource-type, membership-type, location-masters, shelf-locations, book-condition, fine-types, fine-slab-configs, fine-slab-details, account-entry-configs, library-status-masters, books, book-purchases, book-copies, digital-resources, access-restrictions, reservations, transactions, digital-access-requests, digital-access, curricular-alignments, approved-reviews, transactions-history, inventory-audit, engagement-events, lib-members, fines, analytics-reading-behavior, analytics-popularity-trends, analytics-collection-health, analytics-predictive, analytics-member-360, analytics-collection-perf, analytics-predictive-demand, analytics-overdue-books, analytics-most-issued)
- `buildQuery(string $entity, array $config, Request $request)` — Builds the query with search/status filters; supports 40+ switch cases for entity-specific query logic and 5 view-based entity queries

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | Entity-specific `tenant.{slug}.viewAny` | Full export access (bypasses via Gate::before) |
| Library Admin | Entity-specific `tenant.{slug}.viewAny` | Export only entities with granted permission |
| Librarian | Entity-specific `tenant.{slug}.viewAny` | Export only entities with granted permission |

---

## How This Screen Works — Logic Flow (Non-Technical)

When a user clicks Export on any Library screen, the system receives a request specifying which data to export and in what format. It first checks whether the requested data type (like "Categories" or "Members") is a valid exportable entity, then verifies the user has permission to view that data. The system runs the same query that would show the data on screen — with any active search or filter applied — but instead of showing it in a table, it formats the data into a downloadable file. For Excel and CSV, the data is written into rows and columns based on a pre-configured list of fields. For PDF, the data is placed into a printable table layout. Once the file is generated, it automatically downloads to the user's computer.

---

## Validate Before Save

(The export feature has no data entry — validation is limited to URL parameters.)

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | entity | Must exist in getEntityConfig() keys | Unknown entity: {entity} (404) |
| 2 | format | Must be pdf, excel, or csv | Unsupported format: {format} (400) |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Unknown entity slug | Unknown entity: {entity} | 404 |
| Unsupported format | Unsupported format: {format} | 400 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Query error | (Laravel exception — 500 error) | 500 |
| PDF generation fails | (Exception from DomPDF — 500) | 500 |

---

## Success Scenarios

**SS-001: Export all members to Excel**
1. User navigates to Members screen, clicks Export, selects Excel
2. System authorizes `tenant.lib-members.viewAny`
3. Builds query with optional search filter, loads all matching members
4. `GenericExport` processes 1,200 member records with relation resolvers
5. File downloads as `Library_Members_2026-07-24.xlsx`
6. File opens in Excel with proper columns and human-readable values

**SS-002: Export book inventory to PDF**
1. User navigates to Book Copies screen, clicks Export, selects PDF
2. System authorizes `tenant.lib-book-copies.viewAny`
3. Builds query with all copies including book title, barcode, shelf location
4. Blade template renders a formatted PDF with table headers and 500 rows
5. File downloads as `Book_Copies_2026-07-24.pdf`

**SS-003: Export overdue books with filters**
1. User applies overdue filter and searches for specific book on the Fines screen
2. User clicks Export → Excel
3. System uses `?search=physics&status=overdue` to filter the query
4. Only matching overdue records are included in the export

--- 

## Failure Scenarios

**FS-001: User without permission tries to export**
1. User with only `tenant.lib-categories.viewAny` tries to export books
2. `Gate::authorize('tenant.lib-books-master.viewAny')` throws AuthorizationException
3. 403 Forbidden response returned
4. Export is not generated

**FS-002: Invalid entity slug**
1. User or developer calls `/export/non-existent-entity/excel`
2. `getEntityConfig()` returns null
3. Controller returns 404 with message "Unknown entity: non-existent-entity"

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Library | `maatwebsite/laravel-excel` | Excel and CSV export |
| Library | `barryvdh/laravel-dompdf` | PDF export |
| Table | All lib_* tables | Source data for all exportable entities |
| View | `lib_view_member_360` | MySQL view for Member 360 export |
| View | `lib_view_collection_performance` | MySQL view for Collection Performance export |
| View | `lib_view_predictive_demand` | MySQL view for Predictive Demand export |
| View | `lib_view_overdue_books` | MySQL view for Overdue Books export |
| View | `lib_view_most_issued_books` | MySQL view for Most Issued Books export |
| Class | `GenericExport` | Maatwebsite Excel export class |
| Blade | `library::lib-reports.exports.generic-pdf` | PDF template |
