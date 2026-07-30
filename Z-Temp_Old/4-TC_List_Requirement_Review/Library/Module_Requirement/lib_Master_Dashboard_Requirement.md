# Master Dashboard — Business Requirements

## What This Screen Does

The Master Dashboard is the main Library landing screen — the first thing the librarian sees upon entering the Library module. It provides a comprehensive at-a-glance overview of the entire library's health, activity, and performance through dynamic KPI cards, trend charts, member segments, collection utilization data, weeding recommendations, popularity rankings, and recent activities. All data is sourced directly from live database tables (no hardcoded/static values) and reflects real counts, growth percentages, and calculated metrics from the last 30 days through yearly comparisons.

The dashboard is powered by `MasterDashboardService`, which queries multiple tables (lib_books_master, lib_members, lib_transactions, lib_fine_payments, lib_book_popularity_trends, lib_collection_health_metrics, lib_predictive_analytics, lib_curricular_alignment, lib_reading_behavior_analytics, lib_engagement_events, and others) and assembles a structured data payload for the view.

---

## When This Screen Is Used

- When logging into the Library module and wanting a quick summary of current activity
- When checking key performance indicators — member growth, book counts, transaction volumes, fine collections
- When reviewing popular books, collection health, or member engagement metrics
- When looking for weeding recommendations — copies that need repair, replacement, or withdrawal
- When checking overdue books, pending reservations, or member expiry renewals
- When generating insights for library management reporting

## Default Data Load

The `MasterDashboardService@getDashboardData()` method is called on every page load. It executes multiple aggregated queries across all major Library tables and returns a structured array with keys: `key_metrics` (7 KPI cards with YoY growth), `quick_stats` (6 KPI cards for the top row), `reading_trends` (6-month monthly trend with digital/physical breakdown), `popular_books` (top 5 by popularity_score), `collection_health` (utilization, turnover, damage/lost counts), `predictions` (latest 5 predictive insights), `curricular_alignment` (top 5 by alignment score), `recent_activities` (last 10 from transactions + fines + reservations), `member_segments` (High-Value/Regular/At-Risk/New/Inactive distribution), `collection_utilization` (per-category utilization, turnover, demand, and status), `membership` (overview by type with expiry and renewal counts), `engagement` (segment distribution with top/bottom 5 members), `reading` (preferred genres, reading speeds, peak activity times, digital/physical ratio), `weeding_recommendations` (top 10 copies needing action).

---

---

## Key Fields at a Glance

**KPI Cards (Top Row)**
Seven metric cards display total members (with growth percentage and active percentage), total books (with growth), transactions this year (with growth), fines collected in INR (with growth), overdue book count, digital resource count, and pending reservation count. Each card shows a trend direction (up/down) with the percentage change over last year. The quick_stats row adds six cards for Total Members, Total Books, Monthly Circulation, Fines Collected, Avg Loan Days, and Return Rate — each with month-over-month trend.

**Charts and Trends**
The reading behavior trends show a 6-month monthly bar chart comparing physical books read vs digital activities, derived from `lib_transactions` issue counts and `lib_engagement_events` digital events. A category utilization table shows titles, copies, utilization percentage, turnover rate, average age, demand level (Very High/High/Medium/Low), and health status (Healthy/Monitor/Action Needed) for each category.

**Popular Books and Collection Health**
The top 5 popular books are ranked by `popularity_score` from `lib_book_popularity_trends`. Collection health shows utilization rate (issued/total copies), turnover rate (total issues per copy), active titles, damaged/lost copy counts, diversity score, and collection age. Member segments automatically classify all members into High-Value (20+ books, zero fines), Regular (5+ books), At-Risk (fines >= 50 or 60+ days inactive), New (< 5 books), and Inactive (90+ days no activity).

**Weeding Recommendations**
The system identifies copies needing Withdraw (Poor/Damaged condition), Replace (age > 8 years), or Keep (acceptable condition). Priority is calculated: HIGH for Poor/Damaged/age>10, MEDIUM for age>8 or 24+ months unused, LOW for age>5 or 12+ months unused. Each recommendation shows the book title, condition, age, last issue date, category, and suggested action.

---

## Business Rules and Conditions

1. **100% Dynamic Data** — Every metric is computed from live database queries. If a metric's source table is empty, the service falls back to calculated values from related tables (e.g., collection health falls back from `lib_collection_health_metrics` to live counts from `lib_book_copies` and `lib_transactions`).

2. **YoY Growth Calculations** — Key metrics compare current year vs last year counts. Growth percentage is computed as `((current - lastYear) / lastYear) * 100`. If last year count is zero, it defaults to 1 to avoid division by zero.

3. **Trend Capping** — Month-over-month trends for quick_stats are capped between -100% and +100% to prevent extreme swing values from distorting the display.

4. **Member Segmentation Fallback** — If no `member_segment` values are stored in `lib_members`, the system computes segments dynamically based on `total_books_borrowed`, `outstanding_fines`, and `last_activity_date` using the classification rules described above.

5. **Predictive Analytics Lookback** — Only predictions from the last 7 days are displayed, ordered by confidence score descending, limited to 5 records.

6. **Collection Utilization Calculation** — Utilization rate per category = number of issues in last 12 months / total copies, capped at 100%. Turnover rate = total issues / total copies. Average age is computed from purchase bill dates.

7. **Weeding Priority Rules** — Poor/Damaged condition → HIGH priority → WITHDRAW action. Age > 8 years → HIGH priority → REPLACE action. Age > 5 years / unused > 12 months → LOW priority → KEEP action. Unused > 24 months or age > 8 with Fair condition → MEDIUM priority.

8. **Authorization** — Uses `Gate::authorize('tenant.lib-books-master.viewAny')`.

---

## Workflow Steps

1. User navigates to Library → Dashboard
2. `MasterDashboardController@index()` calls `MasterDashboardService@getDashboardData()`
3. User sees the full dashboard with KPI cards, charts, tables, and insights
4. All data reflects the current state of the database — no filters or drill-downs
5. User can click Quick Action links to navigate to specific sub-modules

---

## Example Scenario

The school's Library Admin logs into the system and opens the Library Dashboard. The top row shows 1,450 members (12.3% growth, 68% active last 30 days), 3,200 books (8.1% growth), and 450 transactions this year. The collection health card shows 68% utilization, 3.2 turnover rate, and 45 damaged copies. The weeding recommendations section flags 3 copies of an old encyclopedia set (12 years old, Fair condition) for replacement and a damaged copy of a popular fiction book for withdrawal. The engagement metrics show 24% of members are high-engagement and 13% are at risk of churning. The admin uses this information to plan a purchase order for replacement books and to schedule a member outreach campaign.

---

## Related Screens

- **Library Main Hub** — Navigation hub for all sub-modules, accessible via Quick Action buttons on the dashboard
- **Analytics** — Advanced analytics with reading behavior, popularity trends, collection health, and predictive analytics (deeper than dashboard)
- **Reports** — Report-specific views with filters and date ranges (Fine Reports, Circulation Analysis, Overdue Reports, Acquisition, Digital)

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\MasterDashboardController`
**Service:** `Modules\Library\Services\MasterDashboardService` (1211 lines — all dashboard data logic)
**Route:** `GET /library/dashboard` named `dashboard.master`
**Authorization:** `Gate::authorize('tenant.lib-books-master.viewAny')`

Key dashboard data sources:
- `LibBookMaster` — total books, book growth
- `LibMember` — total members, active members, growth, segments, memberships
- `LibTransaction` — total transactions, overdue count, avg loan days, issues
- `LibFinePayment` — fines collected amount and trends
- `LibBookPopularityTrend` — popular books ranking
- `LibCollectionHealthMetric` — collection health metrics (with fallback)
- `LibPredictiveAnalytic` — predictive insights (last 7 days)
- `LibCurricularAlignment` — top curricular alignments
- `LibEngagementEvent` — engagement metrics, peak times
- `LibReadingBehaviorAnalytics` — averages for consistency, diversity, digital ratio
- `LibBookCopy` — condition tracking, weeding recommendations
- `LibPhysicalBookRequest` — pending reservation count

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-books-master.viewAny` | Full view (bypasses via Gate::before) |
| Library Admin | `tenant.lib-books-master.viewAny` | Full view |
| Librarian | `tenant.lib-books-master.viewAny` | Full view |
| Library Assistant | `tenant.lib-books-master.viewAny` | Full view |

---

## How This Screen Works — Logic Flow (Non-Technical)

When the librarian opens the Dashboard, the system runs a series of behind-the-scenes calculations across the entire library database. It counts total members and books, calculates growth percentages by comparing current year to last year, counts how many transactions happened today, this month, and this year, sums up fines collected, checks how many books are overdue, and identifies which books are most popular. It also looks at each book copy's condition and age to suggest which books need to be repaired, replaced, or removed from the collection. For the member engagement section, the system looks at how many books each member has borrowed, how recently they were active, and any fines they owe — then groups them into categories like high-value readers, at-risk members, and inactive members. All of this happens on every page load so the information is always current.

---

## Validate Before Save

(The dashboard is read-only — there is no data entry or save operation.)

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Gate authorization fails | This action is unauthorized. | 403 |
| Dashboard service error | Logged to error log, dashboard renders with empty/default dataset | 200 (graceful fallback) |

---

## Success Scenarios

**SS-001: Full dashboard loads with real data**
1. User navigates to Library Dashboard
2. Controller authorizes, service queries all tables
3. 7 KPI cards display with real member counts, book counts, transactions, fines
4. Reading trends show 6-month chart with physical vs digital usage
5. Popular books table shows top 5 books with scores
6. Member segments display High-Value / Regular / At-Risk / New / Inactive distribution
7. Weeding recommendations list copies needing attention

**SS-002: Dashboard loads when some tables are empty**
1. A new school with only 50 books and 20 members loads the dashboard
2. Key metrics show the real low numbers with 0% or minimal growth
3. Popular books section shows the top 5 from available data
4. Member segments compute from actual borrowing activity
5. Weeding recommendations section may be empty or show minimal entries
6. No errors — all sections display gracefully with available data

--- 

## Failure Scenarios

**FS-001: Unauthorized access attempt**
1. User without `tenant.lib-books-master.viewAny` accesses the dashboard URL
2. `Gate::authorize()` throws AuthorizationException
3. System returns 403 Forbidden page

**FS-002: Database connection issue**
1. Database is temporarily unavailable
2. Service queries fail with exceptions
3. Exception is logged to Laravel error log
4. Dashboard view may render with empty/zero datasets depending on the error boundary

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | `lib_books_master` | Book counts, growth calculations |
| Table | `lib_members` | Member counts, activity tracking, segments |
| Table | `lib_transactions` | Issue/return counts, overdue, avg loan days |
| Table | `lib_fine_payments` | Fine collection totals |
| Table | `lib_book_copies` | Copy condition, weeding analysis |
| Table | `lib_book_popularity_trends` | Popularity scores |
| Table | `lib_collection_health_metrics` | Collection health (with fallback) |
| Table | `lib_predictive_analytics` | Predictive insights |
| Table | `lib_curricular_alignment` | Curriculum alignment scores |
| Table | `lib_engagement_events` | Digital activity counts, peak times |
| Table | `lib_reading_behavior_analytics` | Averages for consistency, diversity |
| Table | `lib_physical_book_requests` | Pending reservation counts |
| Table | `lib_book_category_jnt` | Category-to-book links |
| Table | `lib_book_genre_jnt` | Genre-based reading insights |
| Service | `MasterDashboardService` | All dashboard business logic (1211 lines) |
