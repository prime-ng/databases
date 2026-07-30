# Engagement Events — Business Requirements

## What This Screen Does

The Engagement Events screen is a read-only audit log that tracks all member interactions with the library system. Every search, book view, download, reservation, renewal, review submission, and portal browse action is recorded as an event. This screen is used exclusively for analytics, behavior tracking, and investigative purposes — no data is created or modified through this screen. It lives as a tab within the Library History & Audit hub.

---

## When This Screen Is Used

- When analyzing how members use the library portal — popular search terms, most-viewed books, device preferences
- When tracking member engagement trends over time for library performance reporting
- When investigating a specific member's activity history for dispute resolution or audit
- When generating usage reports for management or accreditation requirements
- When monitoring digital resource download patterns and license utilization

## Default Data Load

This screen displays as a tab within the Library History & Audit hub (tab id `engagement-events`). When the user navigates to History & Audit, `LibraryController@historyIndex()` loads all history tab data simultaneously. Engagement events are loaded with eager-loaded `member.user` and `book` relationships, ordered by `created_at` descending, paginated at 20 per page. Filters for event type, device type, and date range are available when the tab is active.

---

---

## Key Fields at a Glance

**Who and What**
Every event records which member performed the action (via `member_id` FK to `lib_members`). If the action involved a book, the `book_id` FK links to `lib_books_master`. If it involved a digital resource, `digital_resource_id` links to `lib_digital_resources`. The `event_type` ENUM defines 17 distinct interaction categories from Search and Browse to Ask_Librarian and Attend_Event.

**Search Context**
For search events, the `search_query` field captures the exact text the member entered. The `filters_used_json` JSON column stores any filters the member applied (e.g., category, author, publication year). A `session_id` groups related events into a single browsing session for session-level analytics.

**Technical Details**
The `device_type` ENUM (Desktop, Mobile, Tablet, Kiosk) identifies the platform used. The `browser` and `ip_address` fields provide additional client identification. The `location_id` FK links to `lib_location_masters` if the event occurred at a physical library location (e.g., an in-library browse).

**Engagement Metrics**
The `time_spent_seconds` field tracks how long the member spent on a view or read event. The `interaction_outcome` field records whether the action succeeded, failed, or was cancelled.

---

## Business Rules and Conditions

**Append-Only Log**
Events are inserted via server-side triggers in `StaffLibraryController`, `LibWishlistController`, and other controllers. There is no update or delete endpoint — events are never modified or removed through the UI. Data retention is managed separately (e.g., scheduled cleanup of old records).

**No Timestamps**
The model sets `public $timestamps = false`. Only `created_at` exists (default `CURRENT_TIMESTAMP`). There is no `updated_at` column, and no soft deletes are supported.

**Event Type ENUM**
The `event_type` column is a database ENUM with exactly 17 values: `Search`, `Browse`, `View_Details`, `Add_Reservation`, `Cancel_Reservation`, `Renew_Online`, `Digital_View`, `Digital_Download`, `Read_Online`, `Share_Resource`, `Add_Review`, `Rate_Book`, `Save_To_Wishlist`, `Request_Purchase`, `Ask_Librarian`, `Attend_Event`.

**Device Type ENUM**
The `device_type` column is a database ENUM with 4 values: `Desktop`, `Mobile`, `Tablet`, `Kiosk`.

---

## Workflow Steps

**Viewing Events**
The librarian navigates to Library → History & Audit → Engagement Events tab. They see a paginated table of events showing date/time, member name, event type, book title (if applicable), search query (if search event), device type, time spent, and interaction outcome. The librarian can filter by event type, device type, or date range.

**Analyzing Events**
The librarian uses the search bar to find specific events by event type, search query, device type, member name, or book title. Distinct event type values are loaded into a dropdown for filtering. Events are sorted by most recent first.

---

## Example Scenario

A librarian wants to investigate why a specific book has low circulation despite high search frequency. They navigate to History & Audit and open the Engagement Events tab. They filter by book title and see 47 events: 30 searches for the book, 10 view-detail events, 5 digital view events, and only 2 borrow events. The data suggests members are searching for the book but not borrowing it — possibly because it's a digital-only resource or all copies are checked out. The librarian shares this finding with the acquisition team.

---

## Related Screens

- **Transactions History** — Adjacent tab in History & Audit hub showing library staff actions
- **Inventory Audit** — Adjacent tab showing physical inventory scans
- **Library Analytics** — Aggregated engagement data used in behavioral analytics reports
- **Digital Resources** — Digital view and download events link back to specific digital resources

---

## Requirements

**Controller:** No dedicated controller — data is loaded via `LibraryController@historyIndex()` as part of the History & Audit hub
**Model:** `Modules\Library\Models\LibEngagementEvent` (table: `lib_engagement_events`, no timestamps, no soft deletes)
**Requests:** None — events are created via server-side logging traits, not forms
**Policy:** No dedicated policy; uses string-based `Gate::authorize()` with `tenant.lib-engagement-events.viewAny`
**Route:** No dedicated routes — accessed via `library.historyIndex` with tab parameter
**Tab:** `engagement-events` under `library.historyIndex`

Key data access:
- `LibraryController@historyIndex()` — Loads events with eager-loaded `member.user` and `book`; filters by event_type, device_type, date_from, date_to when tab is active; paginated at 20 per page
- `LibEngagementLogger` trait — Used by `StaffLibraryController` and `LibWishlistController` to log events on member actions (Browse, View_Details, Digital_View, Add_Reservation, Renew_Online, Cancel_Reservation, Download, View_Online, Add_Review, Save_To_Wishlist)

**Important:** This screen is **read-only**. There are no create, edit, update, delete, or trash operations available through the UI.

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | View all events |
| Librarian Admin | View all events |
| Librarian (view only) | View events |
| Library Staff | View events |

Access is gated by `Gate::authorize('tenant.lib-engagement-events.viewAny')` in the `historyIndex()` method.

---

## How This Screen Works — Logic Flow (Non-Technical)

The Engagement Events screen is a read-only log. Data is recorded automatically in the background whenever a member interacts with the library system — searching for books, viewing details, downloading digital resources, reserving books, renewing loans, submitting reviews, or managing their wishlist. Each event captures the member, the action type, the book or resource involved, the device used, and the time spent. The librarian views this data through a filterable, paginated table. No buttons or forms exist to create, edit, or delete events — the screen exists purely for observation and analysis.

---

## Validate Before Save

This screen does not accept user input for creating or modifying events. All event data is recorded server-side by the `LibEngagementLogger` trait. There are no form validations applicable.

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| No events found | Table shows empty state: "No engagement events found." |
| Filter returns no results | Table shows empty state matching current filters |

---

## Success Scenarios

1. A librarian filters by event type "Search" to see all member search queries for the current month. The system returns 342 search events sorted by most recent, showing the most popular search terms.
2. A librarian investigates a specific member's activity by searching the member's name. The system returns 15 events spanning two months — 8 searches, 3 book views, 2 downloads, and 2 reservations — providing a complete activity timeline.
3. A library administrator reviews device type distribution and discovers that 60% of events come from Mobile devices, informing the decision to prioritize mobile UI improvements.

---

## Failure Scenarios

1. A librarian tries to delete an event record. There is no delete endpoint — any attempt returns a 404.
2. A query for events older than 12 months returns no results because a data retention policy has automatically purged old records.
3. The engagement events table grows to millions of rows, causing the default query to be slow. The librarian must use date range filters to narrow the result set for acceptable performance.

---

## Dependencies module and tables

| Module | Tables |
|---|---|
| Library Core | `lib_engagement_events` (primary, no timestamps, no soft deletes) |
| Library Members | `lib_members` (FK `member_id`) |
| Library Books | `lib_books_master` (FK `book_id`) |
| Library Digital Resources | `lib_digital_resources` (FK `digital_resource_id`) |
| Library Locations | `lib_location_masters` (FK `location_id`) |
| Staff Portal | Events logged by `LibEngagementLogger` trait in `StaffLibraryController` and `LibWishlistController` |
