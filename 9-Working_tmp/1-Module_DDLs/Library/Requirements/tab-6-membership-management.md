# Library Tab 6: Membership Management

This tab manages library members — who can borrow books, what their borrowing limits are, and their membership status. Members are linked to platform users (students, teachers, staff) and inherit their identity details from the core user system.

---

## How It Works

When the librarian opens this tab, they see a searchable list of all library members. Each entry shows the member's name, membership number, membership type, status (Active, Expired, Suspended, Deactivated), total books borrowed, and outstanding fines.

**Registering a New Member:** The librarian clicks "Add Member." They search for an existing platform user by name, email, or employee/student code. They select the user and assign a membership type. The system auto-generates a membership number and library card barcode. The registration date is set to today, and the expiry date is calculated based on the membership type's validity period.

**Membership Types:** Each membership type defines borrowing rules — maximum books allowed, loan period in days, renewal allowed and maximum renewals, fine rate per day, grace period in days, and priority level. Common types: Student (standard), Teacher (extended), Staff (limited), Premium Student (increased limits). The librarian can create custom types as needed.

**Managing Members:** The librarian can:
- Renew a membership (extends the expiry date)
- Suspend a member (blocks borrowing but preserves history)
- Reactivate a suspended member
- Deactivate a member (terminal — member cannot borrow but history is preserved)
- Update membership type (changes borrowing rules going forward)

**Member Dashboard:** Clicking on a member shows their details panel — current issued books, borrowing history, fine summary, and engagement metrics (total borrowed, fines paid, reading level, engagement score, churn risk).

**Bulk Operations:** The librarian can select multiple members and perform bulk actions: renew membership, change membership type, or export member data.

---

## Important Business Rules

- A platform user can only have one library membership record. If they already have one, the system shows the existing record instead of creating a new one.
- When a membership expires, the member cannot borrow books but can still return books and pay fines.
- Suspended members cannot borrow. Suspension reasons are recorded and visible to administrators.
- Changing a member's membership type does not affect currently issued books — existing loans follow the rules that were active when they were issued.
- Membership auto-renewal is optional. If enabled, the system attempts to renew 7 days before expiry. If the member is suspended or has outstanding fines over the threshold, auto-renewal is blocked.
- The member's `total_books_borrowed`, `total_fines_paid`, and `outstanding_fines` are computed counters updated by database triggers or service layer logic on each transaction/fine event.
- Reading level and member segment are computed by background analytics jobs, not entered manually.
- When a member is deactivated, all their active reservations are cancelled and a notification is sent.

---

## Database Columns & Behavior

### `lib_membership_types`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| code | VARCHAR(50) | No | No | — | Unique code |
| name | VARCHAR(255) | No | No | — | Display name |
| max_books_allowed | INT UNSIGNED | No | No | 0 | Max concurrent borrows |
| loan_period_days | INT UNSIGNED | No | No | 14 | Default loan duration |
| renewal_allowed | TINYINT(1) | No | No | 0 | Allow renewal |
| max_renewals | INT UNSIGNED | No | No | 0 | Max renewal count |
| fine_rate_per_day | DECIMAL(10,2) | No | No | 0.00 | Daily fine rate |
| grace_period_days | INT UNSIGNED | No | No | 0 | Days before fine starts |
| priority_level | INT UNSIGNED | No | No | 0 | Reservation priority |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |
| deleted_at | TIMESTAMP | No | Yes | NULL | Soft delete |

### `lib_members`

(Full column table documented in Tab 1 — Dashboard.)

---

## Deep Analysis

### Business Workflows & State Machines

**Member Status Lifecycle:**
```
REGISTRATION → ACTIVE ──→ EXPIRED → (renew) → ACTIVE
                  │               │
                  ├──→ SUSPENDED ──┘ (reactivate) → ACTIVE
                  │
                  └──→ DEACTIVATED (terminal)
```

**Membership Expiry Flow:**
```
Check expiry_date daily (cron)
  → If expiry_date < NOW() + 7 days AND is_auto_renew = 1
    → Attempt renewal
    → If successful: extend expiry_date, log activity
    → If blocked (fines/suspended): log failure, notify admin
  → If expiry_date < NOW(): set status = 'expired'
```

**Allow Borrowing Check:**
```
Member wants to borrow
  → status must be 'active'
  → expiry_date must be in the future (or null)
  → current_issued_count < membership_type.max_books_allowed
  → outstanding_fines < max_allowed_fines_threshold
  → If any check fails: show specific error message
```

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Register member | User must not already be a member | "This user is already registered as a library member" |
| Register member | User must be active in the system | "Selected user is not active" |
| Suspend member | Must not already be suspended | "Member is already suspended" |
| Deactivate member | All books must be returned first | "Member has {count} books still issued. Receive returns before deactivating." |
| Change membership type | New type must be active | "Selected membership type is not active" |
| Renew membership | Must not be deactivated | "Deactivated members cannot be renewed" |

**Edge Cases:**
- If a member with outstanding fines is deactivated, the fines remain collectible.
- If a membership type is deleted (soft), existing members keep their current rules.
- Members marked with status 'deactivated' cannot be re-registered — a new platform user account is required.
- Bulk renewal extends all selected members' expiry by their membership type's validity period.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| User (core) | `users` | `user_id` | Member identity |
| Transactions | `lib_transactions` | `member_id` | Borrowing records |
| Fines | `lib_fines` | `member_id` | Fine records |
| Reservations | `lib_reservations` | `member_id` | Reservation queue |
| Analytics | `lib_reading_behavior_analytics` | `member_id` | Reading patterns |

**Scheduled Jobs:** Daily cron checks membership expiry and attempts auto-renewal.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View member list | Librarian, Admin | `tenant.library.members.view` |
| View member details | Librarian, Admin | `tenant.library.members.view` |
| Register new member | Librarian, Admin | `tenant.library.members.create` |
| Edit member details | Librarian, Admin | `tenant.library.members.update` |
| Suspend/reactivate member | Librarian, Admin | `tenant.library.members.suspend` |
| Deactivate member | Admin only | `tenant.library.members.deactivate` |
| Renew membership | Librarian, Admin | `tenant.library.members.renew` |
| Change membership type | Librarian, Admin | `tenant.library.members.changeType` |
| Bulk operations | Librarian, Admin | `tenant.library.members.bulkUpdate` |
| Export member data | Librarian, Supervisor, Admin | `tenant.library.members.export` |
