# Reports — Business Requirements

## What This Screen Does

The Reports screen provides comprehensive, chart-driven analytical reports across six major areas: Dashboard Overview, Fine Collection, Circulation Analysis, Overdue Reports, Acquisition Reports, and Digital Resource Reports. It is powered by `LibFineReportController` (for fine/overdue/acquisition/digital reports) and `LibCirculationReportController` (for circulation reports). The screen uses AJAX-based tab switching — when a tab is selected, the controller checks if the request is AJAX and, if so, returns only the rendered tab content HTML via JSON response instead of a full page reload. This enables a smooth single-page-like experience.

Each report tab has dedicated service classes (`LibFineReportService`, `LibCirculationReportService`, `LibOverdueReportService`, `LibAcquisitionReportService`, `LibDigitalReportService`, `LibDashboardReportService`, `LibAnalyticsReportService`) and chart preparation via `LibChartService`. The services compute summary data, breakdowns, trend data, and generate structured report arrays that are passed to the Blade view for rendering tables and charts.

---

## When This Screen Is Used

- When the librarian needs a quick dashboard-style overview of library performance metrics
- When analyzing fine collection patterns — total collected, waived, pending, top defaulters
- When reviewing circulation trends — books issued vs returned, most active members, peak usage times
- When tracking overdue books — which books are overdue, who has them, estimated fines
- When evaluating acquisition performance — new books added, spending by category, vendor analysis
- When monitoring digital resource usage — most viewed/downloaded e-books, license tracking, device analysis

## Default Data Load

The index page loads with the Dashboard tab active. All report data structures are initialized with empty/default values on first non-AJAX load (to render the initial page shell). Actual data loads only via AJAX calls when a tab is clicked. The `activeTab` parameter is derived from `request('tab', 'dashboard')` or `request('active_tab')`. Each report section has its own filter options: date range (`start_date`, `end_date`), and tab-specific filters like `fine_type_id`, `category_id`, `overdue_range`, `budget_range`, `resource_type`, etc.

---

---

## Key Fields at a Glance

**Dashboard Report Tab**
KPIs (total books, members, issues, returns, active users), quarterly trends broken down by quarter, highlights (top achievements), concerns (areas needing attention), recommendations, and a budget summary (allocated vs spent by category with remaining balance and percentage). Powered by `LibDashboardReportService`.

**Fine Report Tab**
Summary (total fines, collected, waived, pending, outstanding), fine breakdown by type and by membership type, overdue slabs (number of overdue items by day ranges like 1-7, 8-14, 15+ days), top defaulters (members with highest fine amounts), trends (monthly collection trend), and recommendations for improving fine collection. Powered by `LibFineReportService`.

**Circulation Report Tab**
Executive summary (total issues, returns, renewals, active users), circulation by day of week, by membership type, top borrowed books (most issued titles), category analysis (which categories circulate most), hourly usage patterns, trends over time, and recommendations. Powered by `LibCirculationReportService`. Supports filter by `category_id`.

**Overdue Report Tab**
Executive summary (total overdue, total fine amount, average overdue days), overdue by range (count by day ranges), detailed list of overdue items with member/book info, frequent offenders (repeat late returners), recovery actions taken/recommended. Powered by `LibOverdueReportService`. Supports filter by `overdue_range`.

**Acquisition Report Tab**
Budget summary (allocated vs spent vs remaining by category), predictive demand analysis (forecast of what to buy), high priority items needing immediate acquisition, replacement recommendations (old/damaged books needing replacement), digital resource acquisition needs, gap analysis (collection gaps by category), collection performance metrics, member demand signals, curricular alignment recommendations, and final prioritized recommendations. Powered by `LibAcquisitionReportService`.

**Digital Resource Report Tab**
Executive summary (total resources, new this month, total views, total downloads, active users), top resources (most viewed/downloaded), usage by membership type, hourly/daily usage patterns, license tracking (valid/expiring/expired), device type analysis (desktop vs mobile vs tablet), and recommendations. Powered by `LibDigitalReportService`.

---

## Business Rules and Conditions

1. **AJAX-Only Data Loading** — Report data is computed by service classes and returned only when the request is AJAX AND the active tab matches. On initial page load (non-AJAX), all report data is initialized to empty/default arrays. This prevents expensive report queries from running on every page load.

2. **Tab-Scoped Controllers** — `LibFineReportController` handles dashboard, fine, circulation, overdue, acquisition, and digital tabs. `LibCirculationReportController` handles the dedicated circulation report route with similar service logic.

3. **Date Range Default** — The default date range is the last 30 days (`now()->subDays(30)` to `now()`), customizable via filter inputs.

4. **Separate Print Endpoints** — Formatted PDF print versions of each report are available at dedicated `/reports/print/{reportType}` endpoints via `LibReportPrintController`, which has separate methods for circulation, acquisition, digital, overdue, and fine reports.

5. **Cache-Based Refresh** — The `refresh()` endpoint clears the cache for the current report type + filter combination using `Cache::forget()`, forcing fresh data on next load.

6. **Authorization** — The main index uses `Gate::authorize('tenant.lib-fines.viewAny')`. The circulation-specific route uses `Gate::authorize('tenant.lib-transactions.viewAny')`.

---

## Workflow Steps

1. User navigates to Library → Reports
2. Dashboard tab loads with default empty state (no chart queries executed yet)
3. User selects a tab (e.g., Fine Collection) — AJAX request sent with `tab=fine`
4. Server runs the appropriate service query with current date range filters
5. Server returns JSON with rendered HTML (charts + tables) for that tab
6. User applies filters (date range, fine type, category) and clicks Search/Apply
7. Another AJAX request loads filtered data for the active tab only
8. User can paginate overdue table (AJAX with `section=table` parameter)
9. User can click Print button to open a formatted PDF of the current report

---

## Example Scenario

A Library Admin wants to prepare a monthly report for the Principal. They open Reports and start with the Dashboard tab, which shows the overview KPIs. They switch to Fine Collection to see ₹12,500 collected this month with a breakdown by fine type — most fines are for late returns. They check Circulation Analysis and see that Fiction and Mystery categories have the highest turnover. They filter by date range to the current month and note that Wednesday afternoons are peak borrowing times. Finally, they click Print on the Circulation report to generate a PDF to include in their report.

---

## Related Screens

- **Analytics** — Tab-based view of pre-calculated analytics data (reading behavior, popularity trends, collection health, predictive analytics, engagement events)
- **Export** — Generic entity export for raw data download in Excel/CSV/PDF
- **Master Dashboard** — High-level live KPI dashboard (no filters, no date ranges)
- **Fine Management** — Individual fine records, payments, waivers

---

## Requirements

**Controllers:** `LibFineReportController` (6 report tabs), `LibCirculationReportController` (dedicated circulation route), `LibReportPrintController` (PDF print versions)
**Services (7):** `LibFineReportService`, `LibCirculationReportService`, `LibOverdueReportService`, `LibAcquisitionReportService`, `LibDigitalReportService`, `LibDashboardReportService`, `LibAnalyticsReportService`
**Chart Service:** `LibChartService` — prepares chart data arrays for all report types
**Routes:** Under `/reports/` prefix — `fine-collection`, `advanced-analytics`, `circulation`, `print/{reportType}` etc.
**Route Names:** `reports.fine-collection`, `reports.circulation`, `reports.advanced-analytics`

Key controller methods:
- `index(Request)` — Loads all 6 report tabs with AJAX support; returns full view on GET, JSON partial on AJAX
- `analyticsIndex(Request)` — Loads the Advanced Analytics report (9 sub-reports: reading-behavior, popularity-trends, collection-health, predictive, engagement, member-360, collection-perf, predictive-demand, overdue-books, most-issued)
- `refresh(Request)` — Clears cache for report+filter combination
- `export($format)` — Redirect with error (not yet implemented)

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-fines.viewAny` | Full access (bypasses via Gate::before) |
| Library Admin | `tenant.lib-fines.viewAny` | Full access to all 6 tabs |
| Librarian | `tenant.lib-fines.viewAny` | View all report tabs |
| Library Assistant | `tenant.lib-fines.viewAny` | View all report tabs |

---

## How This Screen Works — Logic Flow (Non-Technical)

When the librarian opens Reports, they see an empty shell page with tab navigation. No data queries run yet. The moment they click any tab, the system sends a quiet request to the server asking for just that tab's content. The server runs the specialized report service — for example, clicking "Fine Collection" triggers the fine report service to calculate totals, breakdowns, and trends from the transactions and fines tables. Charts are prepared as data arrays that a JavaScript charting library renders as bar charts, line charts, or pie charts. If the librarian changes a filter (like date range), clicking Search sends another quiet request with the new filter, and just that tab's content refreshes. The other tabs remain untouched until clicked. This makes the reports feel fast and responsive.

---

## Validate Before Save

(The Reports screen is read-only — there is no data entry or save operation. Filter inputs are validated by the browser.)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Gate authorization fails | This action is unauthorized. | 403 |
| AJAX load for unknown tab | Returns empty HTML for the tab | 200 |
| Report service data empty | Charts render with "No data available" message | 200 |
| Refresh cache failure | Failed to refresh: {error message} | 500 |
| Print export not implemented | Fine collection export is not yet implemented. | 302 (redirect with flash) |

---

## Success Scenarios

**SS-001: Load Fine Collection report with charts**
1. User opens Reports, clicks Fine Collection tab
2. AJAX request sends `active_tab=fine` to server
3. `LibFineReportService::getReport()` computes summary, breakdowns, trends
4. `LibChartService::prepareFineCharts()` creates chart data arrays
5. Server returns JSON with rendered HTML for charts and tables
6. User sees bar chart (fine by type), line chart (monthly trend), and summary cards

**SS-002: Apply date range filter to Circulation report**
1. User is on Circulation tab, changes start_date and end_date
2. Clicks Search — AJAX request with new date range
3. `LibCirculationReportService::getReport()` re-computes with filtered date range
4. Charts and tables refresh with new date range data
5. Summary cards update to reflect the filtered period

**SS-003: Print a report as PDF**
1. User is on Overdue tab viewing overdue data
2. User clicks Print button
3. `LibReportPrintController::printOverdue()` generates a formatted PDF
4. PDF automatically downloads with formatted columns and date range header

--- 

## Failure Scenarios

**FS-001: AJAX request for uninitialized tab**
1. User clicks Dashboard tab
2. AJAX sends request with `active_tab=dashboard`
3. `LibDashboardReportService::getReport()` runs with default filters
4. If dashboard data is empty, KPIs show 0, charts show no data
5. No error — dashboard renders gracefully

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `lib_transactions` | Source for circulation, overdue, fine reports |
| Table | `lib_fines` | Fine amounts, statuses, member links |
| Table | `lib_fine_payments` | Payment amounts, dates, methods |
| Table | `lib_book_purchases` | Acquisition spending data |
| Table | `lib_book_purchases_items` | Purchase items for cost breakdown |
| Table | `lib_digital_resources` | Digital resource counts and metrics |
| Table | `lib_digital_access_transactions` | Digital access usage tracking |
| Table | `lib_members` | Member counts and segments |
| Table | `lib_books_master` | Book counts and metadata |
| Service | `LibFineReportService` | Fine report computations |
| Service | `LibCirculationReportService` | Circulation report computations |
| Service | `LibOverdueReportService` | Overdue report computations |
| Service | `LibAcquisitionReportService` | Acquisition report computations |
| Service | `LibDigitalReportService` | Digital resource report computations |
| Service | `LibDashboardReportService` | Dashboard report computations |
| Service | `LibAnalyticsReportService` | Analytics report computations |
| Service | `LibChartService` | Chart data preparation for all report types |
| Controller | `LibReportPrintController` | PDF print report generation |
