# Library Analytics — Business Requirements

## What This Screen Does

The Library Analytics screen provides a multi-tab analytical view of library performance, member reading behavior, book popularity trends, collection health, predictive insights, and engagement event tracking. Each tab loads paginated data from a dedicated analytics table along with search filtering. The screen is a tab-based hub with five independent data tables — Reading Behavior Analytics, Book Popularity Trends, Collection Health Metrics, Predictive Analytics, and Engagement Events. Each tab has its own pagination namespace and search scope to prevent cross-tab interference.

This screen is distinct from the Reports section — Analytics focuses on trend data and behavioral metrics (pre-calculated by the system into dedicated analytics tables), whereas Reports provides aggregated summaries and chart-driven visualizations.

---

## When This Screen Is Used

- When analyzing member reading patterns — books read, pages read, reading consistency, genre preferences
- When tracking book popularity over time — daily requests, issues, reservations, digital views and downloads
- When reviewing collection health — total titles/copies, utilization rate, turnover rate, diversity score
- When reviewing system predictions — demand forecasts, member churn risk, budget projections
- When auditing granular member engagement events — searches, browse, view details, reservations, reviews

## Default Data Load

The `LibraryAnalyticsController@index()` method loads all five analytics queries simultaneously, each paginated at 20 records per page with unique paginator names (`rb_page`, `pop_page`, `health_page`, `pred_page`, `eng_page`). The default active tab is `reading-behavior`. Search is scoped per tab — only the active tab's query receives the search filter via the `$request->input('tab')` check. All queries use `latest()` ordering on their primary date field (`last_calculated_at`, `tracking_date`, `metric_date`, `prediction_date`, `created_at`).

---

---

## Key Fields at a Glance

**Reading Behavior Analytics (Tab 1)**
Shows per-member reading metrics for an academic year: total books read, total pages read, average reading days per book, preferred genre and category, preferred language, loan completion rate (on-time return percentage), peak borrowing month and day, reading consistency score (0-100), genre/author diversity indices, preferred borrowing time (Morning/Afternoon/Evening/Weekend), digital vs physical ratio, renewal frequency, reservation frequency, reading speed estimate (pages/day), and completion rate trend. Data is stored in `lib_reading_behavior_analytics` with a unique constraint per member per academic year.

**Book Popularity Trends (Tab 2)**
Daily tracking of book-level engagement: daily requests, issues, reservations, digital views, and digital downloads. A computed `popularity_score` (weighted composite) determines the book's rank, and `trend_direction` (Rising/Falling/Stable) shows direction of change. Additional metrics include `velocity_score` (rate of change), `seasonality_factor`, `peer_comparison_rank`, `shelf_turnover_rate`, `waitlist_length`, `avg_wait_days`, and `recommendation_weight`. Data is in `lib_book_popularity_trends` with one row per book per tracking date.

**Collection Health Metrics (Tab 3)**
Category/genre-scoped snapshots of collection health by metric date: total titles, total copies, active/inactive titles, damaged/lost/withdrawn copies, utilization rate (percentage of collection in circulation), turnover rate (average issues per copy), age of collection (average years), collection diversity score, relevance score, acquisition effectiveness, weeding priority score, budget allocation efficiency, digital penetration rate, and physical vs digital ratio. Data is in `lib_collection_health_metrics` with optional category/genre filtering.

**Predictive Analytics (Tab 4)**
System-generated predictions: prediction type (Demand_Forecast, Member_Churn, Resource_Optimization, Acquisition_Recommendation, Seasonal_Pattern, Budget_Projection), target entity type (Book/Category/Genre/Member/Department/All), predicted value, confidence score (0-100), actual value (filled retroactively for accuracy tracking), accuracy score, model version, features used (JSON), insights text, and recommendations. Data is in `lib_predictive_analytics` with soft deletes support.

**Engagement Events (Tab 5)**
Granular user interaction tracking: event type (Search, Browse, View_Details, Add_Reservation, Cancel_Reservation, Renew_Online, Digital_View, Digital_Download, Read_Online, Share_Resource, Add_Review, Rate_Book, Save_To_Wishlist, Request_Purchase, Ask_Librarian, Attend_Event), associated member, book, digital resource, search query text, filters used (JSON), session ID, device type (Desktop/Mobile/Tablet/Kiosk), browser, IP address, physical location ID, time spent (seconds), and interaction outcome. Data is in `lib_engagement_events` — a high-volume audit table.

---

## Business Rules and Conditions

1. **Tab-Scoped Search** — Only the active tab's query applies the search filter. For Reading Behavior, search targets member name via `whereHas('member.user')`. For Popularity, search targets book title via `whereHas('book')`. For Collection Health, search targets category name via `whereHas('category')`. For Predictive, search targets `prediction_type`. For Engagement, search targets `event_type`.

2. **Unique Paginator Names** — Each tab uses a unique page name (`rb_page`, `pop_page`, `health_page`, `pred_page`, `eng_page`) to prevent pagination conflicts.

3. **Read-Only Interface** — Analytics are computed by backend processes (scheduled jobs or manual triggers). There is no create/edit/delete functionality in this screen.

4. **Authorization** — The `index()` method uses `Gate::authorize('tenant.lib-reading-behavior-analytics.viewAny')` for the default tab. Individual tab permissions are enforced via the view, but the controller only checks the first tab's permission at method entry.

5. **Soft Deletes** — Reading Behavior Analytics and Predictive Analytics use `SoftDeletes`. Popularity Trends, Collection Health Metrics, and Engagement Events do not.

6. **Scope Methods on Model** — `LibReadingBehaviorAnalytics` provides `byAcademicYear()`, `highConsistency()`, and `fastReaders()` scopes for potential filtered queries.

---

## Workflow Steps

1. User navigates to Library → Analytics
2. System loads all five analytics tables simultaneously, default active tab is Reading Behavior
3. User clicks a different tab (Popularity, Collection Health, Predictive, or Engagement)
4. URL updates with `?tab={tab_id}`, page reloads showing the selected tab's data
5. User optionally types a search term and submits — search applies only to the active tab
6. User paginates through results — each tab maintains its own page state
7. All views are read-only — no create, edit, or delete actions

---

## Example Scenario

A Library Admin wants to understand why certain books are not circulating well. They open the Analytics screen and first look at Collection Health Metrics — filtered to the "Science" category, they see a utilization rate of only 22%. They switch to Book Popularity Trends and search for "Physics" — the five physics books show low daily issue counts with a Falling trend direction. They cross-reference with Reading Behavior Analytics and notice that most members prefer fiction genres (Mystery and Romance) with 85% consistency scores. The admin concludes that the science collection needs weeding and replacement with more engaging titles. They also check the Predictive Analytics tab to see if the demand forecast confirms this assessment.

---

## Related Screens

- **Master Dashboard** — High-level KPIs and quick metrics; Analytics provides deeper drill-down
- **Reports** — Chart-driven reports with date range filters (separate routing under `/reports/`)
- **Export** — All analytics entities can be exported via `/export/analytics-{entity}/{format}`
- **Library Main Hub** — Parent navigation hub

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibraryAnalyticsController`
**Models (5):** `LibReadingBehaviorAnalytics`, `LibBookPopularityTrend`, `LibCollectionHealthMetric`, `LibPredictiveAnalytic`, `LibEngagementEvent`

**Route:** `GET /library-mgt/analytics` named `analyticsIndex`

Key controller method:
- `index(Request)` — Loads all 5 analytics queries with tab-scoped search, each paginated at 20 with unique paginator names, returns `library::analyticsIndex` view

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-reading-behavior-analytics.viewAny` | Full access (bypasses via Gate::before) |
| Library Admin | `tenant.lib-reading-behavior-analytics.viewAny` | View all 5 analytics tabs |
| Librarian | `tenant.lib-reading-behavior-analytics.viewAny` | View all 5 analytics tabs |
| Library Assistant | No direct permission | No access |

---

## How This Screen Works — Logic Flow (Non-Technical)

When the librarian opens the Analytics screen, the system loads data from five different tracking tables all at once. Each table has a different focus: Reading Behavior tracks how members read (how many books they finish, their preferred genres, how consistent they are), Book Popularity tracks which books are in demand and whether their popularity is rising or falling, Collection Health measures the overall condition and usage of the book collection, Predictive shows the system's forward-looking forecasts based on historical patterns, and Engagement records every interaction a member has with the library system (searches, views, reservations). Clicking between tabs shows the corresponding data, and search only works within the active tab to avoid confusion.

---

## Validate Before Save

(The Analytics screen is read-only — there is no data entry or save operation.)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Gate authorization fails | This action is unauthorized. | 403 |
| Tab has no data | Table displays empty state with "No records found." | 200 |
| Invalid tab parameter | Falls back to default tab | 200 |

---

## Success Scenarios

**SS-001: View Reading Behavior data**
1. User opens Analytics — Reading Behavior tab loads by default
2. Table shows member names, books read, pages read, consistency scores
3. Each row includes preferred genre, category, and borrowing time
4. Averages at the bottom show overall library reading metrics

**SS-002: Search within a specific tab**
1. User is on Popularity Trends tab
2. User types "The Great Gatsby" in search
3. Search applies to book title only — other tabs unaffected
4. Matching book appears with its daily issues, popularity score, and trend direction

**SS-003: Navigate between all 5 tabs**
1. User clicks through Reading Behavior → Popularity → Collection Health → Predictive → Engagement
2. Each tab loads its respective data with independent pagination
3. Tab parameter in URL allows direct linking to a specific tab

--- 

## Failure Scenarios

**FS-001: User without permission accesses analytics**
1. User without `tenant.lib-reading-behavior-analytics.viewAny` opens the screen
2. `Gate::authorize()` throws AuthorizationException
3. System returns 403 Forbidden

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `lib_reading_behavior_analytics` | Per-member, per-academic-year reading metrics with FK to lib_members |
| Table | `lib_book_popularity_trends` | Daily book-level engagement tracking with FK to lib_books_master |
| Table | `lib_collection_health_metrics` | Date-based collection health snapshots with FK to lib_categories, lib_genres |
| Table | `lib_predictive_analytics` | System predictions with soft deletes |
| Table | `lib_engagement_events` | High-volume interaction event log (no soft deletes) |
| FK | `member_id` | All tables link back to `lib_members.id` |
| FK | `book_id` | Popularity Trends and Engagement Events link to `lib_books_master.id` |
