# Library Tab 8: Fines & Payments

This tab manages the library's fine system — calculating fines for late returns, lost books, and damaged books, configuring fine rules, processing payments, and waiving fines when appropriate.

---

## How It Works

**Fine Slab Configuration:** Before fines can be calculated, the librarian or administrator configures fine slabs. Each slab defines rules for a specific combination of membership type, resource type, and fine type (Late Return, Lost Book, Damaged Book, Processing Fee). Within each slab, day-range details specify the rate per day based on how many days overdue. For example:
- Days 1-7: ₹5 per day
- Days 8-30: ₹10 per day
- Days 31+: ₹20 per day (capped at maximum book cost)

Each slab has a maximum fine amount and a maximum fine type (Fixed amount, Book Cost, or Unlimited).

**Fine Calculation:** When a book is returned late, the system calculates the fine automatically. It counts the overdue days (return_date - due_date - grace_period), then applies the slab rates to each day range. The calculation breakdown is stored as JSON for transparency.

For lost books, the fine is the book's purchase price (or current replacement cost, if configured) plus a processing fee. For damaged books, the fine is calculated based on the extent of damage and the book's value.

**Fine Records:** Each fine record shows the member, transaction, fine type, amount, days overdue, calculation breakdown, current status (Pending, Paid, Waived, Overdue), and any waiver details.

**Processing Payments:** The librarian selects a fine record and processes a payment. Payment methods include Cash, Card, Online (through payment gateway integration), and Waiver. Partial payments are allowed — the remaining amount stays as "Pending." Each payment generates a unique receipt number.

**Waiving Fines:** A supervisor or admin can waive all or part of a fine. Waiving requires a reason (e.g., "Staff courtesy," "System error," "Administrative adjustment"). The waived amount and reason are recorded in the fine record. The waiver is audited.

**Fine Reports:** The tab includes a fine collection summary showing total fines collected, waived, and pending for the current month, with comparison to previous months.

---

## Important Business Rules

- Fines are calculated automatically on return if the book is overdue. The calculation applies the fine slab that was active at the time of issue, not at the time of return.
- The grace period (defined in membership type) delays the start of fine accrual. For example, a 3-day grace period means fines start on day 4.
- Late return fines are capped at the book's purchase price by default. Different caps can be configured per fine slab.
- Lost book fines use the current book purchase price or the replacement cost entered at the time of marking lost.
- Partial payments are allowed. The fine status remains "Pending" until fully paid.
- Waiving a fine does not delete it — the waived amount is recorded separately and visible in reports.
- Duplicate receipts are prevented — each payment has a unique auto-generated receipt number.
- If a fine remains unpaid for more than 90 days, the member's borrowing privileges are automatically suspended.
- Fine slab configurations support effective date ranges. If a slab's effective_from is in the future, it does not apply yet. If effective_to is in the past, it is archived.
- Priority levels on fine slabs determine which slab applies when multiple slabs match the same membership type and resource type.

---

## Database Columns & Behavior

### `lib_fine_slab_config`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| name | VARCHAR(255) | No | No | — | Slab display name |
| membership_type_id | BIGINT UNSIGNED | `lib_membership_types.id` | Yes | NULL | Target membership type (NULL = all) |
| resource_type_id | BIGINT UNSIGNED | `lib_resource_types.id` | Yes | NULL | Target resource type (NULL = all) |
| fine_type | ENUM | No | No | — | Late Return, Lost Book, Damaged Book, Processing Fee |
| max_fine_amount | DECIMAL(10,2) | No | Yes | NULL | Maximum fine cap |
| max_fine_type | ENUM | No | No | 'Fixed' | Fixed, BookCost, Unlimited |
| effective_from | DATE | No | Yes | NULL | Start of validity |
| effective_to | DATE | No | Yes | NULL | End of validity |
| priority | INT UNSIGNED | No | No | 0 | Resolution priority |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_fine_slab_details`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| fine_slab_config_id | BIGINT UNSIGNED | `lib_fine_slab_config.id` | No | — | Parent slab |
| from_day | INT UNSIGNED | No | No | — | Start day of range |
| to_day | INT UNSIGNED | No | No | — | End day of range (NULL = infinite) |
| rate_per_day | DECIMAL(10,2) | No | No | — | Daily rate |
| rate_type | ENUM | No | No | 'Fixed' | Fixed (₹ amount) or Percentage (of book cost) |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |

### `lib_fines`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| transaction_id | BIGINT UNSIGNED | `lib_transactions.id` | Yes | NULL | Related transaction |
| member_id | BIGINT UNSIGNED | `lib_members.id` | No | — | Member charged |
| fine_type | ENUM | No | No | — | Late Return, Lost Book, Damaged Book, Processing Fee |
| amount | DECIMAL(10,2) | No | No | — | Calculated fine amount |
| days_overdue | INT UNSIGNED | No | Yes | NULL | Days overdue (late returns only) |
| calculated_from | DATE | No | Yes | NULL | Fine period start |
| calculated_to | DATE | No | Yes | NULL | Fine period end |
| fine_slab_config_id | BIGINT UNSIGNED | `lib_fine_slab_config.id` | Yes | NULL | Slab used for calculation |
| calculation_breakdown | JSON | No | Yes | NULL | Per-slab breakdown |
| waived_amount | DECIMAL(10,2) | No | No | 0.00 | Amount waived |
| waived_by_id | BIGINT UNSIGNED | `users.id` | Yes | NULL | Who waived |
| waived_reason | VARCHAR(500) | No | Yes | NULL | Waiver reason |
| waived_at | DATETIME | No | Yes | NULL | When waived |
| status | ENUM | No | No | 'Pending' | Pending, Paid, Waived, Overdue |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_fine_payments`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| fine_id | BIGINT UNSIGNED | `lib_fines.id` | No | — | Related fine |
| amount_paid | DECIMAL(10,2) | No | No | — | Payment amount |
| payment_method | ENUM | No | No | — | Cash, Card, Online, Waiver |
| payment_reference | VARCHAR(255) | No | Yes | NULL | Transaction reference |
| payment_date | DATETIME | No | No | — | When paid |
| received_by_id | BIGINT UNSIGNED | `users.id` | No | — | Staff who received |
| receipt_number | VARCHAR(50) | No | No | — | Unique receipt number |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |

---

## Deep Analysis

### Business Workflows & State Machines

**Fine Lifecycle:**
```
Book returned overdue → Calculate fine → Fine(Pending)
  → Pay → Fine(Paid) + Payment record
  → Waive → Fine(Waived) + waiver details
  → 90 days unpaid → Fine(Overdue) + member suspended
```

**Fine Calculation Algorithm:**
```
overdue_days = MAX(0, return_date - due_date - grace_period)
total_fine = 0
For each slab_detail matching (membership_type, resource_type, fine_type):
  applicable_days = MIN(overdue_days, slab_detail.to_day) - slab_detail.from_day + 1
  if rate_type = Fixed: total_fine += applicable_days × rate_per_day
  if rate_type = Percentage: total_fine += applicable_days × (book_cost × rate_per_day / 100)
Apply max_fine_amount cap if configured and total_fine > max_fine_amount
```

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Pay fine | Payment amount must be > 0 | "Payment amount must be greater than zero" |
| Pay fine | Payment must not exceed remaining amount | "Payment amount exceeds remaining fine balance of ₹{balance}" |
| Waive fine | Reason required (min 10 chars) | "Provide a reason for waiving the fine (minimum 10 characters)" |
| Waive fine | Waived amount must not exceed fine amount | "Waived amount cannot exceed the fine amount" |
| Configure slab | Day ranges must not overlap | "Day ranges in this slab overlap: {from_day}-{to_day} conflicts with existing range" |
| Configure slab | Effective dates valid | "effective_to must be after effective_from" |

**Edge Cases:**
- If a book is returned in worse condition, the system generates a "Damaged Book" fine in addition to any late fine.
- If a member claims a book was already damaged when they received it, the issue condition record is examined. If there is a discrepancy, the fine may be disputed.
- Fines generated before a slab configuration change use the slab active at the time of issue.
- Payment reversals are not supported directly — create a waiver record for the paid amount instead.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Transactions | `lib_transactions` | `transaction_id` | Fine source transaction |
| Members | `lib_members` | `member_id` | Member reference |
| Membership Types | `lib_membership_types` | (via slab) | Fine rule targeting |
| Resource Types | `lib_resource_types` | (via slab) | Fine rule targeting |
| User (core) | `users` | `waived_by_id`, `received_by_id` | Staff identity |

**Scheduled Jobs:**
- Daily fine overdue job: marks fines unpaid for 90+ days as "Overdue" and suspends member borrowing.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View fines | Librarian, Admin | `tenant.library.fines.view` |
| Process payment | Librarian, Admin | `tenant.library.fines.pay` |
| Waive fine | Supervisor, Admin | `tenant.library.fines.waive` |
| Configure fine slabs | Admin only | `tenant.library.fines.configure` |
| Manage slab details | Admin only | `tenant.library.fines.configure` |
| View fine reports | Librarian, Supervisor, Admin | `tenant.library.fines.reports` |
| Export fine data | Librarian, Admin | `tenant.library.fines.export` |
| Reverse payment | Admin only | `tenant.library.fines.reverse` |
