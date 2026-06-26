# Audit Trail — Business Requirements

## What This Screen Does

The Audit Trail log report is a secure, read-only system registry designed for security and administrative transparency. In school administration, grades and behavioral remarks are sensitive records. The Audit Trail automatically logs every creation, modification, or deletion of behavioral data, including score updates, remark edits, configuration overrides, and period locks.

This ledger ensures that any disputed grade change or configuration toggle can be traced back to the exact staff member, timestamp, IP address, and old vs. new values.

---

## When This Screen Is Used

- **Investigating Grade Discrepancies**: A parent complains that their child's rating was suddenly lowered; the HOD reviews the audit logs to check which teacher modified it and why.
- **Security Audits**: The IT Administrator checks the log to confirm if any unauthorized user attempted to override locked assessment periods.
- **Tracking System Changes**: Verifying when a global configuration (e.g., active rating scale) was modified and who performed the update.

---

## Key Columns & Filters

The Audit Trail is restricted to School Admins and is located under **Reports -> Audit Trail**.

### Search Filters
- **Date Range**: Start and End Date pickers (defaults to last 7 days).
- **Action Type**: Dropdown select (Options: `Grade Edit`, `Remark Edit`, `Config Change`, `Status Lock`, `Record Delete`).
- **User (Staff)**: Autocomplete search filter to look up actions performed by a specific employee.
- **Student**: Filter by a specific student profile.

### Audit Log Data Grid
| Timestamp | User | Action Category | Affected Student / Cohort | Description | Old Value | New Value | IP Address |
|-----------|------|-----------------|---------------------------|-------------|-----------|-----------|------------|
| 2026-11-28 14:05:12 | Mrs. Priya | `Grade Edit` | Amit Sharma (Class 8-A) | Modified Peer Collaboration rating. | `Satisfactory (3.0)` | `Exemplary (5.0)` | `192.168.1.45` |
| 2026-11-28 16:30:00 | Mr. Jacob | `Status Lock` | Grade 8-A (Term 1) | Approved and locked assessment period. | `Submitted` | `Approved` | `192.168.1.10` |

---

## Business Rules and Conditions

**The Immutable Ledger Rule**
- The `ba_audit_log` table is **strictly insert-only**.
- The system provides **no interface or API endpoint** to edit or delete rows in the audit trail. Even the Super Admin cannot modify these logs through the application UI to prevent tampering with historical school records.

**Detailed Difference Logging**
- Any change to student scores in `ba_assessment_ratings` must record:
  - The exact criterion affected.
  - The `old_value` (both Level Name and Numeric Score).
  - The `new_value` (both Level Name and Numeric Score).

**Automated Pruning**
- To prevent the database from growing excessively, audit logs older than **3 years** are automatically archived to cold storage and pruned from active transactional tables.

---

## Workflow Steps

**Investigating a Score Change**
1. Admin logs in and navigates to **Reports Hub -> Audit Trail**.
2. Applies filters: Student: `John Doe`, Action Type: `Grade Edit`.
3. Clicks **Search**.
4. The grid displays one row.
   - **Timestamp**: `2026-11-25 10:15:20`
   - **User**: `Mr. Roy`
   - **Description**: `"Modified 'Academic Honesty' rating for John Doe (10-A)."`
   - **Old Value**: `Exemplary (5.0)`
   - **New Value**: `Needs Improvement (1.0)`
5. This trace confirms that Mr. Roy lowered John's score on November 25th, providing the HOD with clear context for discussion.

---

## Example Scenario

A teacher disputes that she locked a section's grades by accident. The admin opens the Audit Trail, filters by Action Category: `Status Lock` and User: `Teacher Name`. The log reveals:
- **Timestamp**: `2026-11-26 15:45:10`
- **Action**: `"Teacher clicked 'Submit to Coordinator' for Class 7-C."`
- **IP Address**: `192.168.4.12` (Matching the teacher’s classroom computer).
This log confirms the lock action was initiated from the teacher's active workspace session.

---

## Related Screens

- [07-Configuration.md](./07-Configuration.md) — Tracks global settings changes recorded here.
- [09-Ratings.md](./09-Ratings.md) / [10-Remarks.md](./10-Remarks.md) — Audits score and text changes.
- [15-Reports-Hub.md](./15-Reports-Hub.md) — The parent reporting portal.
