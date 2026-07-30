# Fee Name Removal (Governance) — Business Requirements

## What This Screen Does

The Governance screen displays the Fee Name Removal Log, which tracks students whose names have been removed from school rolls due to prolonged fee default. It provides a read-only historical view of removals with filtering by readmission status and summary statistics. This feature supports the governance aspect of fee management, tracking defaulter patterns and re-admission workflows.

---

## When This Screen Is Used

- **Name Removal Monitoring** when administrators review students removed for non-payment
- **Re-admission Tracking** when viewing students who have been re-admitted after removal
- **Defaulter Analysis** when analyzing the financial impact of student defaults (total due, average days overdue)
- **Audit Reviews** when reviewing historical governance actions for compliance

## Default Data Load

This screen loads via `StudentFeeManagementController@governance()` which gates `tenant.student-fee-management.viewAny`. It loads `FeeNameRemovalLog::with(['student.user', 'academicSession', 'removedBy'])->latest('removal_date')->paginate(15)` with optional filtering by student name search and readmission status. Additionally, a stats card is computed with aggregate metrics.

---

## Key Fields at a Glance

**Removal Record**
`student_id`, `academic_session_id`, `removal_date`, `removal_reason`, `total_due_at_removal`, `days_overdue`. Linked to `FeeFineRule` via `triggered_by_rule_id` if auto-triggered.

**Re-admission Data**
`re_admission_date`, `re_admission_fee_paid`, `re_admission_fee_head_id` (FK → `fee_head_master`), `re_admission_transaction_id` (FK → `fee_transactions`), `re_admitted_by` (FK → `sys_users`), `re_activated_date` (date when student was re-activated).

**Stats Card**
`total` — total number of removal records. `removed` — count of records with null `re_activated_date` (still removed). `readmitted` — count of records with non-null `re_activated_date`. `total_due` — sum of `total_due_at_removal` across all records. `avg_days_overdue` — average of `days_overdue` rounded to 1 decimal.

---

## Business Rules and Conditions

**Read-only Display**
The Governance screen is read-only. No create/edit/delete operations are performed from this screen. Removals are triggered by fine rule expiry actions ("Remove Name") or manually via other processes.

**Readmission Filtering**
Records can be filtered by: `all` (no filter), `removed` (where `re_activated_date IS NULL`), `readmitted` (where `re_activated_date IS NOT NULL`).

**Defaulter History**
The companion table `fee_defaulter_history` stores per-student-per-session aggregate statistics for defaulter pattern analysis including total_fine_count, total_fine_amount, total_waived_amount, max_days_late, avg_days_late, missed_installments, name_removed flag, re_admitted flag, and defaulter_score for risk assessment.

---

## Workflow Steps

**Viewing Governance Records**
The admin navigates to Student Fee → Governance. The system loads the name removal log with pagination, search, and readmission status filter. The stats card displays aggregate metrics.

**Filtering Records**
Admin can search by student name or filter by readmission status (All / Removed / Readmitted). The query applies `whereNotNull('re_activated_date')` for readmitted and `whereNull('re_activated_date')` for removed.

---

## Example Scenario

At the end of the academic year, the school administration reviews the Governance tab. They see: 12 total name removals, 8 currently removed, 4 readmitted, with total due of ₹1,20,000 and an average of 45.3 days overdue. They can search for a specific student and see their full removal and re-admission history.

---

## Related Screens

- **Fine Management** — Fine rules with action_on_expiry = "Remove Name" trigger removals
- **Student Assignment** — Student fee assignments affected by name removal
- **Fee Invoicing** — Overdue invoices that led to name removal

---

## Requirements

- Method `governance()` in `StudentFeeManagementController` with gate `tenant.student-fee-management.viewAny`
- Read-only display (no CRUD controllers for name removal log)
- Search by student name via `whereHas('student.user', fn($q) => $q->where('name', 'like', "%{$search}%"))`
- Readmission status filter: `readmitted` → whereNotNull('re_activated_date'), `removed` → whereNull('re_activated_date')
- Pagination at 15 per page with `governance_page` query parameter
- Stats card with 5 metrics: total, removed, readmitted, total_due, avg_days_overdue
- `FeeNameRemovalLog` model with SoftDeletes-style relationships (no SoftDeletes trait in model)

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.student-fee-management.viewAny` | `governance()` | Page load |

## Logic Flow

1. **Page Load** — `governance()` gates permission, builds query with student name search and readmission filter, loads paginated results, computes stats card metrics.
2. **Filtering** — Search by student name uses `whereHas('student.user')`. Status filter checks `re_activated_date` null/not-null.
3. **Stats Calculation** — Total count, removed count (null re_activated), readmitted count (not-null re_activated), sum of total_due_at_removal, average of days_overdue (rounded to 1 decimal).

## Validate Before Save

No CRUD operations — read-only display only.

## Error Handling and Validation Messages

No validation errors — read-only display. Search and filter are applied via query string parameters.

## Success Scenarios

**SC-001 — Governance Page Loads With Stats**
Admin navigates to Governance tab. Page loads with name removal log paginated, stats card showing total/removed/readmitted/total_due/avg_days_overdue.

**SC-002 — Filter by Readmitted**
Admin selects "Readmitted" filter. Table shows only records with non-null re_activated_date. Stats update accordingly.

**SC-003 — Search by Student Name**
Admin types student name in search box. Table filters to matching records only.

## Failure Scenarios

No failure scenarios — read-only display with no write operations.

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_name_removal_log` | Main Table | Read-only query on this table |
| `fee_defaulter_history` | Companion Table | Aggregate defaulter analytics |
| `std_students` | FK Table | `student_id` FK RESTRICT |
| `sch_org_academic_sessions_jnt` | FK Table | `academic_session_id` FK RESTRICT |
| `fee_fine_rules` | FK Table | `triggered_by_rule_id` FK SET NULL |
| `sys_users` | FK Table | `removed_by`, `re_admitted_by` FK SET NULL |
| `fee_head_master` | FK Table | `re_admission_fee_head_id` FK SET NULL |
| `fee_transactions` | FK Table | `re_admission_transaction_id` FK SET NULL |
