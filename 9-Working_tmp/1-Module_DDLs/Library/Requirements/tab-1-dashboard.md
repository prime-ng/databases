# Library Tab 1: Dashboard

This is the first tab the librarian sees when they open the Library module. It provides a quick overview of the library's current state — key metrics, pending actions, recent activity, and trends — all in one place.

---

## How It Works

When the librarian opens this tab, they see several summary cards at the top. One card shows the total number of books in the library catalogue. Another shows how many copies are currently available for issue. A third shows how many books are currently issued to members. A fourth shows how many members the library has. And a fifth shows the total outstanding fine amount.

Below the summary cards, there are pending action panels. One panel shows overdue books that have not been returned past their due date. Another shows reservation requests that are waiting to be fulfilled. A third shows books that are currently issued and due for return soon. Each pending item shows key details — member name, book title, due date, and days overdue.

At the bottom, there is a recent activity feed showing the latest transactions: books issued, books returned, new members registered, and fines collected. Each entry shows what happened, when, and by whom.

Charts show circulation trends over the past week and month, popular book categories, and the distribution of books by status (Available, Issued, Reserved, Under Maintenance, Lost, Withdrawn).

Everything on this tab is read-only — it is designed for a quick visual check, not for taking actions. If the librarian wants to act on a pending item, they click through to the relevant tab.

---

## Important Business Rules

- All summary numbers are live — they query the database in real time. For large libraries with thousands of members and books, the dashboard may take a moment to load. Cards appear one by one as data comes in.
- The overdue panel shows books where the current date is past the due date and the transaction status is still "Issued." Books that have been returned do not appear.
- The reservation panel only shows reservations with status "Pending" — those waiting for an available copy. Fulfilled or cancelled reservations are excluded.
- The recent activity feed caps at 20 most recent events. To see older activity, the librarian uses the Audit Log tab.
- Charts are rendered client-side. Exporting charts requires using browser screenshot functionality.
- The dashboard only shows data for the librarian's own school library. In a multi-branch setup, the librarian sees only their assigned branch.
- If no data exists yet, cards show zero, charts are empty, and a message appears: "Start adding books to see your library dashboard."

---

## Database Columns & Behavior

### `lib_books_master`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| title | VARCHAR(500) | No | No | — | Full book title |
| subtitle | VARCHAR(500) | No | Yes | NULL | Optional subtitle |
| edition | VARCHAR(50) | No | Yes | NULL | Edition identifier |
| isbn | VARCHAR(20) | No | Yes | NULL | Unique ISBN (13-digit standard) |
| issn | VARCHAR(20) | No | Yes | NULL | ISSN for serials |
| doi | VARCHAR(100) | No | Yes | NULL | Digital Object Identifier |
| publication_year | YEAR | No | Yes | NULL | Year of publication |
| publisher_id | BIGINT UNSIGNED | `lib_publishers.id` | Yes | NULL | Publisher reference |
| language | VARCHAR(50) | No | Yes | NULL | Primary language |
| page_count | INT UNSIGNED | No | Yes | NULL | Number of pages |
| summary | TEXT | No | Yes | NULL | Book description |
| table_of_contents | TEXT | No | Yes | NULL | Chapter listing |
| cover_image_url | VARCHAR(500) | No | Yes | NULL | Cover image path |
| resource_type_id | BIGINT UNSIGNED | `lib_resource_types.id` | No | — | Physical, Digital, Audio |
| is_reference_only | TINYINT(1) | No | No | 0 | If 1, cannot be issued |
| lexile_level | VARCHAR(20) | No | Yes | NULL | Reading level score |
| reading_age_range | VARCHAR(50) | No | Yes | NULL | Recommended age |
| awards | TEXT | No | Yes | NULL | Awards JSON |
| series_name | VARCHAR(255) | No | Yes | NULL | Series grouping |
| series_position | INT UNSIGNED | No | Yes | NULL | Order within series |
| popularity_rank | INT UNSIGNED | No | Yes | 0 | Computed popularity score |
| academic_rating | DECIMAL(3,2) | No | Yes | NULL | Teacher rating |
| student_rating | DECIMAL(3,2) | No | Yes | NULL | Student rating |
| rating_count | INT UNSIGNED | No | Yes | 0 | Total ratings received |
| curricular_relevance_score | DECIMAL(5,2) | No | Yes | NULL | Curriculum alignment score |
| tags | JSON | No | Yes | NULL | Flexible tagging |
| ai_summary | TEXT | No | Yes | NULL | AI-generated summary |
| key_concepts | JSON | No | Yes | NULL | Key topics |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility flag |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_book_copies`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| book_id | BIGINT UNSIGNED | `lib_books_master.id` | No | — | Parent book record |
| accession_number | VARCHAR(50) | No | No | — | Unique library accession number |
| barcode | VARCHAR(100) | No | Yes | NULL | Unique barcode (can be same as accession) |
| rfid_tag | VARCHAR(100) | No | Yes | NULL | Unique RFID tag identifier |
| shelf_location_id | BIGINT UNSIGNED | `lib_shelf_locations.id` | Yes | NULL | Physical location |
| current_condition_id | BIGINT UNSIGNED | `lib_book_conditions.id` | No | — | Current condition state |
| purchase_date | DATE | No | Yes | NULL | When acquired |
| purchase_price | DECIMAL(10,2) | No | Yes | NULL | Acquisition cost |
| vendor_id | BIGINT UNSIGNED | External | Yes | NULL | Purchase vendor |
| is_lost | TINYINT(1) | No | No | 0 | Lost flag |
| is_damaged | TINYINT(1) | No | No | 0 | Damaged flag |
| is_withdrawn | TINYINT(1) | No | No | 0 | Withdrawn from collection |
| withdrawal_reason | VARCHAR(500) | No | Yes | NULL | Reason for withdrawal |
| status | ENUM | No | No | 'available' | available, issued, reserved, under_maintenance, lost, withdrawn |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_members`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| user_id | BIGINT UNSIGNED | `users.id` | No | — | Platform user reference (unique) |
| membership_type_id | BIGINT UNSIGNED | `lib_membership_types.id` | No | — | Borrowing ruleset |
| membership_number | VARCHAR(50) | No | No | — | Unique library card number |
| library_card_barcode | VARCHAR(100) | No | Yes | NULL | Barcode on physical card |
| registration_date | DATE | No | No | — | When member registered |
| expiry_date | DATE | No | Yes | NULL | Membership expiry |
| is_auto_renew | TINYINT(1) | No | No | 0 | Auto-renew membership |
| last_activity_date | DATE | No | Yes | NULL | Last transaction date |
| total_books_borrowed | INT UNSIGNED | No | No | 0 | Lifetime borrow count |
| total_fines_paid | DECIMAL(10,2) | No | No | 0.00 | Lifetime fines paid |
| outstanding_fines | DECIMAL(10,2) | No | No | 0.00 | Current unpaid fines |
| status | ENUM | No | No | 'active' | active, expired, suspended, deactivated |
| reading_level | VARCHAR(50) | No | Yes | NULL | Assessed reading ability |
| member_segment | VARCHAR(50) | No | Yes | NULL | Automated segment label |
| engagement_score | DECIMAL(5,2) | No | Yes | NULL | Engagement metric |
| churn_risk_score | DECIMAL(5,2) | No | Yes | NULL | Churn prediction |
| lifetime_value | DECIMAL(10,2) | No | Yes | NULL | LTV computation |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_transactions`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| copy_id | BIGINT UNSIGNED | `lib_book_copies.id` | No | — | Book copy being transacted |
| member_id | BIGINT UNSIGNED | `lib_members.id` | No | — | Member involved |
| issue_date | DATETIME | No | No | — | When the book was issued |
| due_date | DATETIME | No | No | — | Expected return date |
| return_date | DATETIME | No | Yes | NULL | Actual return date |
| issued_by_id | BIGINT UNSIGNED | `users.id` | Yes | NULL | Staff who issued |
| received_by_id | BIGINT UNSIGNED | `users.id` | Yes | NULL | Staff who received return |
| issue_condition_id | BIGINT UNSIGNED | `lib_book_conditions.id` | Yes | NULL | Condition at issue time |
| return_condition_id | BIGINT UNSIGNED | `lib_book_conditions.id` | Yes | NULL | Condition at return time |
| is_renewed | TINYINT(1) | No | No | 0 | Was this a renewal? |
| renewal_count | INT UNSIGNED | No | No | 0 | Number of times renewed |
| status | ENUM | No | No | 'Issued' | Issued, Returned, Overdue, Lost |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

---

## Deep Analysis

### Business Workflows & State Machines

**Dashboard Data Flow:**
The dashboard aggregates data from 6 core tables — `lib_books_master` (total catalogue count), `lib_book_copies` (available/issued/lost breakdown), `lib_members` (total/active members), `lib_transactions` (current issues, overdue count), `lib_reservations` (pending reservations), and `lib_fines` (outstanding amount). Each KPI runs an independent COUNT or SUM query filtered by `is_active = 1` and relevant status values.

**Pending Actions Panel:**
- Overdue items: `lib_transactions` WHERE `status = 'Issued'` AND `due_date < NOW()`
- Reservations pending: `lib_reservations` WHERE `status = 'Pending'`
- Due soon: `lib_transactions` WHERE `status = 'Issued'` AND `due_date BETWEEN NOW() AND NOW() + 3 days`

**State Dependency:** Dashboard is entirely read-only and reflects the live state of all Library module entities. No state mutations occur from this tab.

### Validation Rules & Edge Cases

- **Empty state:** All cards show zero, charts render empty with "Start adding books to see your library dashboard."
- **Large libraries:** For collections with 50,000+ books or 10,000+ members, summary counts may use cached aggregates refreshed every 5 minutes rather than real-time queries.
- **Time zone:** Due date calculations and "overdue" detection use the school's configured time zone.
- **Multi-branch:** In multi-branch setups, the librarian only sees data for their assigned branch. Supervisors see all branches with a branch filter dropdown.
- **Overdue precision:** A book is overdue if `NOW() > due_date` AND `status = 'Issued'`. Time-of-day comparisons are by date only (not time) — a book due on March 10 is overdue on March 11 regardless of the exact time.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| User (core) | `users` | `lib_members.user_id`, `lib_transactions.issued_by_id`, `lib_transactions.received_by_id` | Member identity, staff actions |
| SchoolSetup | `sch_classes` | `lib_book_subject_jnt.class_id` | Curriculum linkage |
| SchoolSetup | `sch_subjects` | `lib_book_subject_jnt.subject_id` | Subject mapping |

**Events/Listeners:** None triggered from this tab. It is a passive consumer of data.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View dashboard | Librarian, Supervisor, Admin | `tenant.library.dashboard.view` |
| View pending actions | Librarian, Supervisor | `tenant.library.dashboard.view` |
| View charts | Librarian, Supervisor, Admin | `tenant.library.dashboard.view` |
| View all branches | Supervisor, Admin | `tenant.library.dashboard.viewAny` |

- Students and teachers can view a read-only version with their own issued books and fines only.
- The full dashboard is librarian-facing.
