# Library Tab 10: Reports & Analytics

This tab provides comprehensive reports and analytical insights about the library's operations, collection, members, and trends. It is designed for librarians, supervisors, and school administrators to make data-driven decisions.

---

## How It Works

When the librarian opens this tab, they see a report selection menu. Each report type has its own configuration options — date range, filters, and grouping preferences.

**Available Reports:**

**Circulation Analysis Report:** Shows borrowing trends over time — total issues and returns by day, week, or month. The report can be filtered by membership type, book category, or class. It includes charts showing peak borrowing periods, average loan duration, and renewal rates.

**Fine Collection Report:** Summarizes all fine activity — total fines collected, waived, and pending. It can be filtered by date range, fine type, and membership type. It shows collection efficiency (percentage of fines paid vs. total assessed) and trends over time.

**Overdue Report:** Lists all currently overdue books with member details, days overdue, and calculated fines. It can be filtered by days overdue range (1-7 days, 8-30 days, 31+ days) and by membership type. The report supports bulk sending of overdue reminders.

**Acquisition Report:** Shows what books were added to the collection within a date range — total new books, total new copies, purchase cost summary, and breakdown by category, publisher, or vendor. Helps with budget tracking and collection development planning.

**Digital Resource Report:** Shows usage statistics for digital resources — total downloads, total views, most accessed resources, and license expiry calendar.

**Member Engagement Report:** Shows member activity metrics — active members, inactive members (no activity in 90 days), borrowing frequency distribution, and member segment breakdown. Includes churn risk analysis and engagement score trends.

**Collection Health Report:** Shows the overall health of the book collection — total titles, total copies, available vs. issued ratio, condition distribution, withdrawn/lost rates, and collection age analysis (how many books are older than 5, 10, 15 years).

**Popularity Trends Report:** Shows which books and categories are most popular over time. Includes top 10 most borrowed books, most reserved books, and category popularity ranking.

**Generating and Exporting Reports:** All reports can be generated on-screen with interactive tables and charts. Every report can be exported to Excel or PDF. Exports include metadata — school name, report name, date range, generation timestamp, and the user who generated it.

---

## Important Business Rules

- Reports are read-only. No data can be modified from this tab.
- Report generation may take a moment for large datasets (10,000+ transactions). A loading indicator is shown. For very large datasets, reports are generated asynchronously and the librarian is notified when ready.
- The circulation analysis report excludes today's date by default to ensure complete data. The librarian can include today if needed.
- The fine collection report includes only finalized fines (Paid, Waived). Pending fines are shown in a separate "Outstanding" section.
- The overdue report does not auto-send reminders. The librarian selects members and triggers reminders manually.
- The acquisition report includes both purchased books and donated books. Donated books show purchase price as ₹0 with a "Donated" label.
- The collection health report's "age" calculation is based on publication year, not acquisition date. If publication year is unknown, the copy's purchase_date is used instead.
- Member engagement report data is updated daily by background analytics jobs. Real-time data may lag by up to 24 hours.
- Exports respect the librarian's data access scope (own branch only, unless they have cross-branch permissions).
- PDF exports are A4-formatted with school logo header and page numbers. Excel exports use flat table format with filters enabled.

---

## Database Columns & Behavior

### Analytics Tables (Denormalized / Computed)

**`lib_reading_behavior_analytics`** — Per-member reading pattern analysis
| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| member_id | BIGINT UNSIGNED | `lib_members.id` | No | — | Member reference |
| total_books_read | INT UNSIGNED | No | No | 0 | Books borrowed + returned |
| preferred_genre_id | BIGINT UNSIGNED | `lib_genres.id` | Yes | NULL | Most borrowed genre |
| preferred_category_id | BIGINT UNSIGNED | `lib_categories.id` | Yes | NULL | Most borrowed category |
| reading_consistency_score | DECIMAL(5,2) | No | Yes | NULL | Regularity of borrowing |
| diversity_index | DECIMAL(5,2) | No | Yes | NULL | Genre diversity score |
| last_analysis_date | DATE | No | Yes | NULL | When last computed |

**`lib_book_popularity_trends`** — Daily book popularity tracking
| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| book_id | BIGINT UNSIGNED | `lib_books_master.id` | No | — | Book reference |
| track_date | DATE | No | No | — | Date of tracking |
| request_count | INT UNSIGNED | No | No | 0 | Reserve requests |
| issue_count | INT UNSIGNED | No | No | 0 | Issues on this date |
| view_count | INT UNSIGNED | No | No | 0 | Digital resource views |
| popularity_score | DECIMAL(10,4) | No | Yes | NULL | Computed score |
| trend_direction | VARCHAR(20) | No | Yes | NULL | up, down, stable |

**`lib_collection_health_metrics`** — Aggregate collection metrics
**`lib_predictive_analytics`** — ML model outputs for demand forecast, churn prediction
**`lib_curricular_alignment`** — Book-to-curriculum mapping scores
**`lib_engagement_events`** — Granular interaction event log (search, browse, view, rate, etc.)

---

## Deep Analysis

### Business Workflows & State Machines

**Report Generation Flow:**
```
Select Report Type → Set Filters → Preview On-Screen → Export (Excel/PDF)
                                       ↓
                              Interactive table + charts
                                       ↓
                           (optional) Schedule recurring report
```

**Data Aggregation Methods:**
| Report | Primary Table(s) | Aggregation |
|--------|-----------------|-------------|
| Circulation Analysis | `lib_transactions` | COUNT/SUM by date range, group by type |
| Fine Collection | `lib_fines`, `lib_fine_payments` | SUM by status, payment method |
| Overdue | `lib_transactions` | WHERE status=Issued AND due_date < NOW() |
| Acquisition | `lib_book_copies` | COUNT by purchase_date range |
| Member Engagement | `lib_members`, `lib_reading_behavior_analytics` | Aggregate by segment, status |
| Collection Health | `lib_book_copies`, `lib_books_master` | COUNT by condition, status, pub year |
| Popularity Trends | `lib_book_popularity_trends` | SUM/AVG by date range |

### Validation Rules & Edge Cases

| Scenario | Handling |
|----------|----------|
| No data for selected filters | "No data matches the selected filters. Try adjusting your date range or filter criteria." |
| Report with 10,000+ records | Asynchronous generation with notification. Estimated time shown. |
| Export cancelled mid-generation | Partial export file is deleted. User must retry. |
| Selected date range exceeds 1 year | Warning: "Large date range may take longer to generate. Consider narrowing the range." |
| Librarian changes branch mid-session | Report filters reset to new branch's scope. |

**Edge Cases:**
- If a report is scheduled for recurring generation (e.g., monthly overdue report), the schedule respects weekends and holidays.
- Report caching: Reports generated with the same filters within a 15-minute window may serve cached results.
- The popularity score is computed as a weighted combination of issue_count, request_count, and view_count with recency bias.

### Integration Points

| Module | Table(s) | Purpose |
|--------|----------|---------|
| Transactions | `lib_transactions` | Circulation and overdue reports |
| Fines & Payments | `lib_fines`, `lib_fine_payments` | Fine reports |
| Book Master | `lib_books_master` | Collection reports |
| Book Copies | `lib_book_copies` | Acquisition, collection health |
| Members | `lib_members`, `lib_reading_behavior_analytics` | Engagement reports |
| Digital Resources | `lib_digital_resources` | Digital resource usage |
| Popularity Trends | `lib_book_popularity_trends` | Popularity analysis |

**Scheduled Jobs:**
- Daily analytics computation: Updates reading behavior analytics, popularity trends, collection health metrics, and predictive models.
- Weekly report generation (if scheduled): Generates and emails scheduled reports to configured recipients.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View circulation report | Librarian, Supervisor, Admin | `tenant.library.reports.circulation` |
| View fine report | Librarian, Supervisor, Admin | `tenant.library.reports.fines` |
| View overdue report | Librarian, Admin | `tenant.library.reports.overdue` |
| Send overdue reminders | Librarian, Admin | `tenant.library.reports.sendReminders` |
| View acquisition report | Librarian, Admin | `tenant.library.reports.acquisition` |
| View digital resource report | Librarian, Admin | `tenant.library.reports.digital` |
| View member engagement report | Supervisor, Admin | `tenant.library.reports.engagement` |
| View collection health report | Supervisor, Admin | `tenant.library.reports.collectionHealth` |
| View popularity trends | Librarian, Teacher, Admin | `tenant.library.reports.popularity` |
| Export any report | Librarian, Admin | `tenant.library.reports.export` |
| Schedule recurring reports | Admin only | `tenant.library.reports.schedule` |
| View analytics dashboards | Admin only | `tenant.library.reports.analytics` |
