# Library Tab 9: Inventory Audit & History

This tab manages physical inventory audits — where the library staff physically verifies that every book copy is in its expected location and condition. It also provides the complete transaction history audit trail for all library operations.

---

## How It Works

**Inventory Audit Sessions:** The librarian starts a new audit session by clicking "Start New Audit." The system creates an audit session record with the current date and the librarian who performed it. The session is created in "In Progress" status.

During the audit, the librarian scans each book copy's barcode or RFID tag using a handheld scanner or the system's barcode input. For each scan, the system records:
- The copy that was scanned
- Its expected location (from `lib_book_copies.shelf_location_id`)
- Its actual location (where it was found)
- The timestamp of the scan
- The condition at scan time

The system classifies each scan result:
- **Found** — Copy is at its expected location
- **Missing** — Copy is not found at its expected location
- **Misplaced** — Copy is found at a different location
- **Damaged** — Copy is found but in worse condition than recorded

**Completing the Audit:** When the librarian has scanned all expected copies, they close the session. The system calculates summary statistics:
- Total copies expected (all active copies)
- Total scanned
- Missing count
- Misplaced count
- Damaged count

If the scanned count equals the expected count, the session can be completed with a "No discrepancies found" summary. If there are discrepancies, the librarian can schedule a follow-up audit or mark missing copies as "Lost" after a reasonable search period.

**Transaction History:** This section shows a complete log of all library transactions — every issue, return, renewal, lost marking, and condition update. Each entry shows the transaction type, book copy, member, date, and the staff member who processed it. The librarian can filter by transaction type, date range, member, book, or staff member.

The history is append-only — no entries can be edited or deleted. If a transaction was processed incorrectly, a correction transaction is created (e.g., a return reversal) rather than modifying the original record.

---

## Important Business Rules

- An audit session cannot be created if there is already an "In Progress" audit session. The librarian must complete or cancel the existing one first.
- During an audit, the librarian can pause and resume the session. Scans are saved in real time, so no data is lost.
- A copy marked as "Missing" during audit is not automatically changed in the system. The librarian must follow up and manually mark it as Lost or Found after investigation.
- If a copy scanned as "Misplaced" is later moved to its correct location, it is still counted as a discrepancy in the audit summary.
- The transaction history retains records indefinitely. There is no automatic purging.
- If a member or staff user is deleted from the system, their name in the transaction history is replaced with "(Deleted User)" to preserve the audit trail.
- The audit summary can be exported to PDF for physical record-keeping.
- If the library has multiple branches, each branch conducts its own independent audit sessions.

---

## Database Columns & Behavior

### `lib_inventory_audit`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| uuid | CHAR(36) | No | No | — | Unique identifier |
| audit_date | DATE | No | No | — | When audit was performed |
| performed_by_id | BIGINT UNSIGNED | `users.id` | No | — | Who conducted the audit |
| total_scanned | INT UNSIGNED | No | No | 0 | Copies scanned |
| total_expected | INT UNSIGNED | No | No | 0 | Active copies expected |
| missing_copies | INT UNSIGNED | No | No | 0 | Count marked missing |
| misplaced_copies | INT UNSIGNED | No | No | 0 | Count found elsewhere |
| damaged_copies | INT UNSIGNED | No | No | 0 | Count found damaged |
| status | ENUM | No | No | 'In Progress' | In Progress, Completed, Cancelled |
| completed_at | DATETIME | No | Yes | NULL | When audit was completed |
| notes | TEXT | No | Yes | NULL | Optional notes |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_inventory_audit_details`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| audit_id | BIGINT UNSIGNED | `lib_inventory_audit.id` | No | — | Parent audit session |
| copy_id | BIGINT UNSIGNED | `lib_book_copies.id` | No | — | Scanned copy |
| expected_location_id | BIGINT UNSIGNED | `lib_shelf_locations.id` | Yes | NULL | Where it should be |
| actual_location_id | BIGINT UNSIGNED | `lib_shelf_locations.id` | Yes | NULL | Where it was found |
| scanned_at | DATETIME | No | No | — | When scanned |
| condition_id | BIGINT UNSIGNED | `lib_book_conditions.id` | Yes | NULL | Condition at scan |
| status | ENUM | No | No | 'found' | found, missing, misplaced, damaged |
| notes | TEXT | No | Yes | NULL | Optional notes |
| is_active | TINYINT(1) | No | No | 1 | Soft visibility |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |
| updated_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP ON UPDATE | Last modification |

### `lib_transaction_history`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| transaction_id | BIGINT UNSIGNED | `lib_transactions.id` | Yes | NULL | Related transaction |
| action_type | ENUM | No | No | — | issued, returned, renewed, marked_lost, condition_updated |
| old_value | JSON | No | Yes | NULL | Previous state |
| new_value | JSON | No | Yes | NULL | New state |
| performed_by_id | BIGINT UNSIGNED | `users.id` | No | — | Who performed the action |
| performed_at | DATETIME | No | No | — | When the action occurred |
| notes | TEXT | No | Yes | NULL | Additional context |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |

---

## Deep Analysis

### Business Workflows & State Machines

**Audit Session Lifecycle:**
```
START → IN PROGRESS (scanning copies) → COMPLETED (all scanned, summary generated)
                    ↓
               CANCELLED (abandoned, existing data preserved)
```

**Scan Classification Logic:**
```
Input: scanned copy barcode + actual_location + condition
  → Look up expected_location from lib_book_copies
  → If expected_location matches actual_location AND condition matches → "found"
  → If expected_location != actual_location → "misplaced"
  → If copy not found after reasonable search → "missing"
  → If location matches but condition is worse → "damaged"
```

**Transaction History:**
- Every state change in `lib_transactions` creates a corresponding entry in `lib_transaction_history`.
- The history records the change as a JSON diff (old_value → new_value) for complete auditability.

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Start audit | No other "In Progress" audit | "An audit session is already in progress. Complete or cancel it first." |
| Scan copy | Copy must be active | "This copy is withdrawn and cannot be scanned" |
| Complete audit | At least one scan recorded | "No scans recorded. Add at least one scan before completing." |
| Cancel audit | Provide reason | "Provide a reason for cancelling the audit session" |
| Duplicate scan | Same copy scanned twice in same session | Allowed — records the latest scan but shows a warning "Copy already scanned. Overwriting previous scan result." |

**Edge Cases:**
- If a copy is scanned as "missing" during audit and then found later, the audit detail is updated with corrected status and timestamp.
- Audit sessions do not auto-close. The librarian must explicitly complete or cancel.
- If a copy is issued during an active audit, it still appears in the expected count. The scanner at the circulation desk notes it as issued.
- Transaction history entries for deleted users show "(Deleted User)" — the `performed_by_id` is preserved to maintain referential integrity.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Book Copies | `lib_book_copies` | `copy_id` | Copy identification |
| Shelf Locations | `lib_shelf_locations` | `expected_location_id`, `actual_location_id` | Location tracking |
| Book Conditions | `lib_book_conditions` | `condition_id` | Condition assessment |
| Transactions | `lib_transactions` | `transaction_id` | Transaction history source |
| User (core) | `users` | `performed_by_id` | Staff identity |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View audit sessions | Librarian, Supervisor, Admin | `tenant.library.audit.view` |
| Start new audit | Librarian, Admin | `tenant.library.audit.create` |
| Scan copies in audit | Librarian, Admin | `tenant.library.audit.scan` |
| Complete audit | Librarian, Admin | `tenant.library.audit.complete` |
| Cancel audit | Supervisor, Admin | `tenant.library.audit.cancel` |
| Mark missing as lost | Supervisor, Admin | `tenant.library.audit.markLost` |
| View transaction history | Librarian, Supervisor, Admin | `tenant.library.history.view` |
| Export audit report | Librarian, Admin | `tenant.library.audit.export` |
| Export transaction history | Librarian, Admin | `tenant.library.history.export` |
