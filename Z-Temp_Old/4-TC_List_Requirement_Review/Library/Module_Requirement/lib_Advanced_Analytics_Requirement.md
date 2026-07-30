# Advanced Analytics & Insights — Business Requirements

## What This Screen Does

The Advanced Analytics & Insights screen provides a comprehensive 9-tab analytical hub for library performance, member reading behavior, book popularity trends, collection health, predictive forecasts, member profiles, collection performance, demand forecasting, overdue tracking, and top-circulation reporting. Each tab loads data via AJAX from a dedicated analytics source — five physical tables (`lib_reading_behavior_analytics`, `lib_book_popularity_trends`, `lib_collection_health_metrics`, `lib_predictive_analytics`, `lib_engagement_events`) and four database views (`lib_view_member_360`, `lib_view_collection_performance`, `lib_view_predictive_demand`, `lib_view_overdue_books`, `lib_view_most_issued_books`). The screen is a tab-based hub with per-tab permission keys and per-tab filter forms that submit via AJAX to reload both chart and table sections without a full page refresh.

This screen is distinct from the Standard Reports (Dashboard, Fine, Circulation, Overdue, Acquisition, Digital) under the same Reports section. While those reports are chart-driven executive summaries with pre-calculated KPIs, Advanced Analytics provides granular drill-down into individual data points — per-member reading metrics, per-book daily popularity scores, category/genre-scoped collection health snapshots, and system-generated predictive records.

**Screen Location:** Library → Reports → Advanced Analytics  
**URL:** `/library/reports/advanced-analytics`

---

## When This Screen Is Used

- When analyzing member reading patterns — books read, pages read, reading consistency, genre preferences, completion rates, borrowing time patterns
- When tracking book popularity over time — daily requests, issues, reservations, digital views and downloads, popularity scores, trend direction (Rising/Falling/Stable)
- When reviewing collection health — total titles/copies, utilization rate, turnover rate, diversity score, relevance score, weeding priority, budget efficiency
- When reviewing system predictions — demand forecasts, member churn risk, resource optimization, acquisition recommendations, budget projections
- When auditing a member's 360-degree profile — engagement score, churn risk, currently borrowed books, overdue items, activity status
- When evaluating collection performance — demand vs supply, available vs issued copies, overdue count, avg loan days, popularity rank
- When forecasting demand — predicted next 3 months issues, confidence score, acquisition recommendations (Acquire More Copies / Monitor Demand / Maintain Current / Consider Weeding)
- When tracking overdue books — days overdue, estimated fine, fine rate per day, member contact info
- When reviewing most-issued books — issue count, unique borrowers, avg loan days, author name, last issue date

## Default Data Load

The `LibFineReportController@analyticsIndex()` method loads all nine analytics data sets from `LibAnalyticsReportService::getReport()`, each paginated at 20 records per page. The default active tab is `reading-behavior`. Filter forms and tables load via AJAX on tab show — the first load fires for the active tab immediately, then each subsequent tab loads when the user clicks it (lazy load via the `loaded` CSS class check). All filter forms submit via AJAX to reload chart and table sections independently.

---

---

## Key Fields at a Glance

**Reading Behavior Analytics (Tab 1 — `lib_reading_behavior_analytics`)**
Per-member reading metrics keyed to `member_id` and `academic_year_id`: total books read, total pages read, average reading days per book, preferred genre/category/language, loan completion rate (percentage of books returned on time), peak borrowing month and day, reading consistency score (0-100), genre/author diversity indices (Shannon index), preferred borrowing time (Morning/Afternoon/Evening/Weekend), digital vs physical ratio, renewal/reservation frequency, reading speed estimate (pages/day), and completion rate trend. Joined to `sys_users` via `lib_members.user_id` for member name display.

**Book Popularity Trends (Tab 2 — `lib_book_popularity_trends`)**
Daily book-level engagement tracking: daily requests, issues, reservations, digital views, and digital downloads. The `popularity_score` is a weighted composite score that determines the book's rank, and `trend_direction` (Rising/Falling/Stable) shows the direction of change. Additional metrics include `velocity_score` (rate of popularity change), `seasonality_factor`, `peer_comparison_rank`, `shelf_turnover_rate`, `waitlist_length`, `avg_wait_days`, and `recommendation_weight`. Unique constraint on (`book_id`, `tracking_date`).

**Collection Health Metrics (Tab 3 — `lib_collection_health_metrics`)**
Category/genre-scoped snapshots by `metric_date`: total titles, total copies, active/inactive titles, damaged/lost/withdrawn copies, utilization rate (percentage of collection in circulation), turnover rate (average issues per copy), age of collection (average years), collection diversity score, relevance score (demand match), acquisition effectiveness (ROI), weeding priority score, budget allocation efficiency, digital penetration rate, and physical vs digital ratio. Category and genre are nullable FK — NULL means all categories/genres.

**Predictive Analytics (Tab 4 — `lib_predictive_analytics`)**
System-generated predictions with soft deletes: `prediction_type` ENUM (Demand_Forecast, Member_Churn, Resource_Optimization, Acquisition_Recommendation, Seasonal_Pattern, Budget_Projection), `target_entity_type` ENUM (Book, Category, Genre, Member, Department, All), target entity ID, prediction period (start/end), predicted value (DECIMAL 10,2), confidence score (0-100), actual value (filled retroactively for accuracy tracking), accuracy score, model version, features used (JSON), insights text, and recommendations.

**Member 360 (Tab 5 — `lib_view_member_360` VIEW)**
A comprehensive database view joining `lib_members` → `sys_users` → `lib_membership_types` → `lib_reading_behavior_analytics` → `lib_genres`. Fields include member ID, membership number, first/last name, email, phone, membership type, registration/expiry date, status, total books borrowed, outstanding fines, engagement score, churn risk score, lifetime value, reading level, total pages read, avg reading days, consistency score, genre diversity, preferred genre, borrowing time, digital vs physical ratio, active reservations count, currently borrowed count, days since last activity, and computed activity status (New / Active / At Risk / Inactive).

**Collection Performance (Tab 6 — `lib_view_collection_performance` VIEW)**
A database view joining `lib_books_master` → publishers → resource types → book copies → transactions → reservations → popularity trends → collection health metrics. Fields: book ID, title, ISBN, publisher, resource type, total copies, available/issued/reserved/lost/damaged copies, total issues, overdue count, avg loan days, active reservations, avg queue position, popularity rank, curricular relevance score, student rating, popularity score, trend direction, collection utilization rate, and computed demand category (High/Medium/Low/Very Low Demand).

**Predictive Demand (Tab 7 — `lib_view_predictive_demand` VIEW)**
A database view joining `lib_books_master` → categories → genres → predictive analytics → curricular alignment. Fields: book ID, title, category name, genre name, publication year, last 3 months issues, last year issues, predicted next 3 months, confidence score, insights, recommendations, curricular relevance, and computed acquisition recommendation (Acquire More Copies / Monitor Demand / Maintain Current / Consider Weeding). Also computes priority CRITICAL/HIGH/MEDIUM/LOW based on `predicted_next_3_months` thresholds (50/30/10).

**Overdue Books (Tab 8 — `lib_view_overdue_books` VIEW)**
A database view joining `lib_transactions` → book copies → books master → members → users → membership types. Fields: transaction ID, title, ISBN, barcode, membership number, first/last name, email, phone, due date, days overdue, fine rate per day, estimated fine. Only includes transactions where status code = 'Issued' AND due_date < CURDATE() AND days overdue > grace period.

**Most Issued Books (Tab 9 — `lib_view_most_issued_books` VIEW)**
A database view joining `lib_books_master` → book copies → transactions where status code = 'Returned'. Fields: book ID, title, issue count, unique borrowers, avg loan days. Post-query enrichment adds author name (from primary author via `lib_book_author_jnt`) and last issue date (MAX of transaction issue_date).

---

## Business Rules and Conditions

1. **AJAX Tab Loading** — Only the active tab's charts and table sections are loaded on page load. Other tabs load lazily when clicked (via the `loaded` CSS class check). Forms submit via AJAX to reload chart and table sections for the current tab only.

2. **Read-Only Interface** — Analytics are computed by backend processes (scheduled jobs or manual triggers from the library management system). There is no create/edit/delete/crud functionality in this screen. All data is read-only.

3. **Lazy Per-Tab Authorization** — The `analyticsIndex()` method uses `Gate::authorize('tenant.lib-reading-behavior-analytics.viewAny')` at method entry for the default tab. Individual tab permissions are enforced in the Blade view via the `x-backend.tab.nav-tab` component's `permission` key per tab entry and the `@can` wrapper around each `@include`.

4. **Filter Scope** — Each tab has its own filter form with its own filter parameter names. The `LibAnalyticsReportService::getReport()` applies the filters from the `$analyticsFilters` array, which uses specific keys per tab (e.g., `min_consistency`, `segment_filter`, `demand_filter`, `min_overdue_days`, `issue_range`).

5. **Issue Range Post-Processing** — The Most Issued Books tab's `issue_range` filter is applied post-query by slicing the collection (`top10`, `top20`, `bottom`) using `$results->setCollection()`.

6. **Priority Computation** — The Predictive Demand view's priority (CRITICAL/HIGH/MEDIUM/LOW) is computed at runtime in the service based on `predicted_next_3_months` thresholds.

7. **Unique Paginator Names** — Each tab's pagination is handled by Laravel paginator page names that are unique per backend service instance. The service uses the default `page` parameter name.

---

## Workflow Steps

1. User navigates to Library → Reports → Advanced Analytics (`/library/reports/advanced-analytics`)
2. System loads the `analytics-reportIndex` view, default active tab is Reading Behavior
3. JavaScript fires `loadTabSection('reading-behavior', 'charts')` and `loadTabSection('reading-behavior', 'table')` — AJAX calls load chart and table content
4. User clicks a different tab — JavaScript detects `shown.bs.tab` event, checks if pane has `loaded` class, and fires AJAX load for charts and table
5. User applies filters on a tab and clicks Search — the filter form's submit event is intercepted, calling `loadTabSection()` with form serialized data
6. User clicks pagination links inside a tab-pane — the click event is intercepted, extracting the query string and calling `loadTabSection()` for that tab
7. All views are read-only — no create, edit, or delete actions exist on this screen

---

## Example Scenario

A Library Admin notices that the "Science" category has very low circulation. They open Advanced Analytics and look at the Collection Health tab (Tab 3), filtering by the Science category. The utilization rate is 18%, turnover rate is 0.3, and the weeding priority score is 78 (high). Switching to Collection Performance (Tab 6), they see that the five Science books have a "Very Low Demand" category, with total issues under 10 each and a Falling trend direction. They cross-reference with Predictive Demand (Tab 7) and see that the system's demand forecast predicts only 5-8 issues for these books over the next 3 months, with a "Consider Weeding" recommendation. The admin then checks Reading Behavior (Tab 1) and notices that most members prefer Mystery and Romance genres with 85%+ consistency scores. Finally, the admin navigates to Member 360 (Tab 5), filters by inactive activity status, and identifies 12 members who haven't borrowed in 90+ days who might benefit from a targeted outreach campaign. The admin concludes the Science collection needs weeding and replacement with high-demand genres.

---

## Related Screens

- **Library Reports Dashboard** (`/library/reports/fine-collection`) — High-level KPIs and chart-driven reports for Fine, Circulation, Overdue, Acquisition, and Digital resources (separate routing under `/reports/`)
- **Library Analytics Hub** (`/library-mgt/analytics`) — A separate 5-tab analytics screen focused on the physical analytics tables (Reading Behavior, Popularity, Collection Health, Predictive, Engagement Events) without the view-based tabs
- **Master Dashboard** — Top-level KPIs across all library operations
- **Library Main Hub** — Parent navigation hub for all Library modules

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibFineReportController@analyticsIndex`
**Route:** `GET /library/reports/advanced-analytics` named `library.reports.advanced-analytics`
**Service:** `Modules\Library\Services\LibAnalyticsReportService` — provides `getReport(array $filters)`, `getAcademicYears()`, `getCategories()`, `getGenres()`, `getPredictionTypes()`, `getMembershipTypes()`, `getResourceTypes()`, `getTrendDirections()`

**Data Sources (5 tables + 4 views):**
| Tab | Source | Type |
|-----|--------|------|
| Reading Behavior | `lib_reading_behavior_analytics` | Table (FK: member_id, academic_year_id, preferred_genre_id, preferred_category_id) |
| Popularity Trends | `lib_book_popularity_trends` | Table (FK: book_id, UNIQUE: book_id + tracking_date) |
| Collection Health | `lib_collection_health_metrics` | Table (FK: category_id, genre_id nullable) |
| Predictive Analytics | `lib_predictive_analytics` | Table (soft deletes) |
| Member 360 | `lib_view_member_360` | View (joins members → users → membership types → reading behavior → genres) |
| Collection Performance | `lib_view_collection_performance` | View (joins books → copies → transactions → popularity → health) |
| Predictive Demand | `lib_view_predictive_demand` | View (joins books → categories → genres → predictive analytics → curricular) |
| Overdue Books | `lib_view_overdue_books` | View (joins transactions → copies → books → members → users → membership types) |
| Most Issued Books | `lib_view_most_issued_books` | View (joins books → copies → transactions, post-enriched with authors/date) |

**View:** `library::lib-reports.analytics-reportIndex` (hub) + `library::lib-reports.analytics.{tab-id}` (9 partial views)

Key controller methods:
- `analyticsIndex(Request)` — Loads all 9 analytics data sets from `LibAnalyticsReportService::getReport()` with per-tab filters; loads filter options from service helpers; returns full view on initial load or JSON with rendered HTML for AJAX requests

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|--------------|
| Super Admin | `tenant.lib-reading-behavior-analytics.viewAny` | Full access (bypasses via Gate::before) |
| Library Admin | `tenant.lib-reading-behavior-analytics.viewAny` | View all 9 analytics tabs |
| Librarian | `tenant.lib-reading-behavior-analytics.viewAny` | View all 9 analytics tabs |
| Library Assistant | No direct permission | No access |

**Per-tab permissions (enforced in blade):**
| Tab | Permission |
|-----|-----------|
| Reading Behavior | `tenant.lib-reading-behavior-analytics.viewAny` |
| Popularity Trends | `tenant.lib-book-popularity-trends.viewAny` |
| Collection Health | `tenant.lib-collection-health-metrics.viewAny` |
| Predictive Analytics | `tenant.lib-predictive-analytics.viewAny` |
| Member 360 | `tenant.lib-members.viewAny` |
| Collection Performance | `tenant.lib-books-master.viewAny` |
| Predictive Demand | `tenant.lib-predictive-analytics.viewAny` |
| Overdue Books | `tenant.lib-transactions.viewAny` |
| Most Issued Books | `tenant.lib-transactions-history.viewAny` |

---

## How This Screen Works — Logic Flow (Non-Technical)

When the librarian opens the Advanced Analytics screen, they see a tabbed interface with nine tabs at the top. The system initially loads data only for the active tab (Reading Behavior) via background requests, fetching both a chart section and a table section. When the librarian clicks a different tab, the system loads that tab's data the first time only (lazy loading). Each tab has its own filter form with fields specific to that topic — for example, the Reading Behavior tab has Academic Year and Consistency Score filters, while the Overdue Books tab has Minimum Overdue Days, Minimum Fine, and Maximum Fine filters. When the librarian submits a filter form or clicks a pagination link, the system reloads the relevant table or chart via background request without refreshing the entire page, providing a smooth, app-like experience.

---

## Validate Before Save

(The Advanced Analytics & Insights screen is read-only — there is no data entry or save operation. All data is pre-computed by backend processes and served from analytics tables and database views.)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|---------------|-------------|
| Gate authorization fails | This action is unauthorized. | 403 |
| Tab has no data | Table displays empty state with "No records found." + Dashboard KPIs show 0 values | 200 |
| Invalid tab parameter | Falls back to `reading-behavior` default tab | 200 |
| AJAX load failure | `Failed to load {sectionName}.` displayed in the target container | Client-side |
| Service exception in any tab | Logged to Laravel error log; returns empty collection for that tab | 200 (graceful degradation) |

---

## Success Scenarios

**SS-001: View Reading Behavior data**
1. User opens Advanced Analytics — Reading Behavior tab loads by default
2. Chart section shows consistency distribution; table shows member names, books/pages read, avg reading days, preferred genre/category, consistency score, reading speed
3. Each row includes member name via `sys_users` join and genre/category names via FK joins

**SS-002: Search and filter within a tab**
1. User is on Collection Health tab
2. User selects Category = "Science" and submits the filter form
3. AJAX reloads chart and table showing only collection health metrics for Science category
4. Utilization rate, turnover rate, weeding priority score all update for the filtered scope

**SS-003: Navigate between all 9 tabs with independent filters**
1. User clicks through Reading Behavior → Popularity Trends → Collection Health → Predictive Analytics → Member 360 → Collection Performance → Predictive Demand → Overdue Books → Most Issued Books
2. Each tab loads its respective chart and table lazily on first click
3. Filters set on one tab do not affect other tabs
4. Tab parameter in URL allows direct linking to a specific tab

**SS-004: Overdue Books with fine calculation**
1. User is on Overdue Books tab
2. Table shows member name, book title, barcode, due date, days overdue, estimated fine (days_overdue × fine_rate_per_day)
3. User filters by "Minimum Overdue Days = 30" to see only severely overdue books
4. Pagination works independently via AJAX within the tab

---

## Failure Scenarios

**FS-001: User without permission accesses analytics**
1. User without `tenant.lib-reading-behavior-analytics.viewAny` opens the screen
2. `Gate::authorize()` throws AuthorizationException
3. System returns 403 Forbidden

**FS-002: Tab with no data renders empty state**
1. User opens Predictive Analytics tab but no predictions have been generated yet
2. Chart section shows ApexCharts with empty dataset (all zeros)
3. Table section renders a single row with "No records found." spanning all columns
4. No error is shown to the user — graceful empty state

**FS-003: AJAX request fails due to network issue**
1. User clicks a pagination link inside a tab
2. AJAX request fails (server error or network timeout)
3. Container shows "Failed to load table." error message
4. User can retry by clicking the pagination link again

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | `lib_reading_behavior_analytics` | Per-member, per-academic-year reading metrics; FK → `lib_members.id`, `academic_years.id`, `lib_genres.id`, `lib_categories.id`; has SoftDeletes |
| Table | `lib_book_popularity_trends` | Daily book-level engagement tracking; FK → `lib_books_master.id`; UNIQUE (`book_id`, `tracking_date`) |
| Table | `lib_collection_health_metrics` | Date-based collection health snapshots; FK → `lib_categories.id`, `lib_genres.id` (both nullable) |
| Table | `lib_predictive_analytics` | System predictions with ENUM prediction types and target entity types; has SoftDeletes |
| Table | `lib_engagement_events` | High-volume interaction event log with ENUM event types (Search, Browse, View_Details, etc.) |
| View | `lib_view_member_360` | Joins `lib_members` → `sys_users` → `lib_membership_types` → `lib_reading_behavior_analytics` → `lib_genres` |
| View | `lib_view_collection_performance` | Joins `lib_books_master` → publishers → resource_types → book_copies → transactions → reservations → popularity_trends → health_metrics |
| View | `lib_view_predictive_demand` | Joins `lib_books_master` → categories → genres → `lib_predictive_analytics` (Demand_Forecast type) → curricular_alignment |
| View | `lib_view_overdue_books` | Joins `lib_transactions` → book_copies → books_master → members → `sys_users` → membership_types |
| View | `lib_view_most_issued_books` | Joins `lib_books_master` → book_copies → transactions (Returned status) |
| FK | `member_id` | Links analytics tables to `lib_members.id` |
| FK | `book_id` | Links popularity/performance/overdue/most-issued tables to `lib_books_master.id` |
| Module | Library Core | All tables and views belong to the Library module |
| Module | Academic Setup | `sch_org_academic_sessions_jnt` (academic years) referenced by reading behavior analytics |
| Module | System Users | `sys_users` table referenced by member 360 and overdue books views |
