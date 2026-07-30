# fee_FeeNameRemoval_TcList

## Module: StudentFee → Governance → Fee Name Removal

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Tab Group | Governance |
| Feature | Fee Name Removal (Governance) |
| URL(s) | `/student-fee/governance` (tab) |
| Controller | `Modules\StudentFee\Http\Controllers\StudentFeeManagementController@governance()` |
| Model(s) | `Modules\StudentFee\Models\FeeNameRemovalLog` (table: `fee_name_removal_log`), `Modules\StudentFee\Models\FeeDefaulterHistory` (table: `fee_defaulter_history`) |
| Permissions | `tenant.student-fee-management.viewAny` |
| Soft Deletes | No (model does not use SoftDeletes) |
| CRUD Type | Read-only display — no create/edit/delete operations from this screen |

---

## 2. Pre-conditions

- Required permission: `tenant.student-fee-management.viewAny`
- At least one `FeeNameRemovalLog` record exists in the database
- For readmission filter tests: Mix of records with null and non-null `re_activated_date`
- Tenant context must be initialized

---

## 3. Default Data Load

When the page loads via `StudentFeeManagementController@governance()` (GET `/student-fee/governance`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Name Removal Logs | `FeeNameRemovalLog::with(['student.user','academicSession','removedBy'])->latest('removal_date')` | Latest by removal_date | search(student name), readmission status | 15/page (governance_page) |
| Stats Card | Aggregate queries on FeeNameRemovalLog | total, removed, readmitted, total_due, avg_days_overdue | None | None |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Seed data**: Create at least 3 FeeNameRemovalLog records with varying removal dates, due amounts, and readmission statuses
- **Stats validation**: Verify aggregate numbers match manual calculation
- **Pre-test cleanup**: Delete created test records by ID

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_name_removal_log`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | student_id | INT UNSIGNED FK | NOT NULL → std_students RESTRICT |
| BC-DB-03 | academic_session_id | SMALLINT UNSIGNED FK | NOT NULL → sch_org_academic_sessions_jnt RESTRICT |
| BC-DB-04 | removal_date | DATE | NOT NULL |
| BC-DB-05 | removal_reason | TEXT | NOT NULL |
| BC-DB-06 | total_due_at_removal | DECIMAL(12,2) | NOT NULL |
| BC-DB-07 | days_overdue | INT | NOT NULL |
| BC-DB-08 | triggered_by_rule_id | INT UNSIGNED FK NULL | → fee_fine_rules SET NULL |
| BC-DB-09 | removed_by | INT UNSIGNED FK NULL | → sys_users SET NULL |
| BC-DB-10 | re_admission_date | DATE | NULLABLE |
| BC-DB-11 | re_admission_fee_paid | DECIMAL(12,2) | NULLABLE |
| BC-DB-12 | re_admission_fee_head_id | INT UNSIGNED FK NULL | → fee_head_master SET NULL |
| BC-DB-13 | re_admission_transaction_id | INT UNSIGNED FK NULL | → fee_transactions SET NULL |
| BC-DB-14 | re_admitted_by | INT UNSIGNED FK NULL | → sys_users SET NULL |
| BC-DB-15 | re_activated_date | DATE | NULLABLE |
| BC-DB-16 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-17 | updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |

### 5.2 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.student-fee-management.viewAny | governance() | Without → 403 |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page load with no filter | All name removal records displayed, paginated |
| BC-BIZ-02 | Filter by status=readmitted | Only records with non-null re_activated_date shown |
| BC-BIZ-03 | Filter by status=removed | Only records with null re_activated_date shown |
| BC-BIZ-04 | Search by student name | Records filtered where student user name matches |
| BC-BIZ-05 | Stats — total | `FeeNameRemovalLog::count()` |
| BC-BIZ-06 | Stats — removed | `FeeNameRemovalLog::whereNull('re_activated_date')->count()` |
| BC-BIZ-07 | Stats — readmitted | `FeeNameRemovalLog::whereNotNull('re_activated_date')->count()` |
| BC-BIZ-08 | Stats — total_due | `FeeNameRemovalLog::sum('total_due_at_removal')` |
| BC-BIZ-09 | Stats — avg_days_overdue | `FeeNameRemovalLog::avg('days_overdue')`, rounded to 1 decimal |
| BC-BIZ-10 | Model — isReAdmitted | Returns true if re_activated_date is not null |
| BC-BIZ-11 | Model — markReActivated | Sets all re-admission fields including dates |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | student_id | std_students (id) | RESTRICT |
| BC-REF-02 | academic_session_id | sch_org_academic_sessions_jnt (id) | RESTRICT |
| BC-REF-03 | triggered_by_rule_id | fee_fine_rules (id) | SET NULL |
| BC-REF-04 | removed_by | sys_users (id) | SET NULL |
| BC-REF-05 | re_admission_fee_head_id | fee_head_master (id) | SET NULL |
| BC-REF-06 | re_admitted_by | sys_users (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Governance Page Loads With Name Removal Log | Page loads with paginated table and stats card | — | — | ⬜ |
| TC-P02 | Stats Card Displays Correct Totals | total, removed, readmitted, total_due, avg_days_overdue shown accurately | — | — | ⬜ |
| TC-P03 | Governance Page Shows All Required Columns | Table shows student, removal_date, total_due, days_overdue, removed_by, re-admission status | — | — | ⬜ |
| TC-P04 | Filter By Readmitted Status | Only records with re_activated_date not null shown | — | — | ⬜ |
| TC-P05 | Filter By Removed Status | Only records with re_activated_date null shown | — | — | ⬜ |
| TC-P06 | Search By Student Name | Grid filters to matching student records | — | — | ⬜ |
| TC-P07 | Pagination Works | Records paginated at 15 per page | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Empty State — No Name Removal Records | Page loads with empty table and stats showing zeros | — | — | ⬜ |
| TC-N02 | Search With No Matches | Empty table with "No records found" message | — | — | ⬜ |
| TC-N03 | Permission 403 Without viewAny | 403 Forbidden | — | — | ⬜ |
| TC-N04 | Guest Access Redirect | Redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Stats — removed + readmitted = total | `stats.removed + stats.readmitted = stats.total` | — | — | ⬜ |
| TC-D02 | B | Avg days overdue computation | avg returned as float rounded to 1 decimal | — | — | ⬜ |
| TC-D03 | C | Model — isReAdmitted returns true for re-activated | `$log->isReAdmitted()` = true when re_activated_date not null | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() before governance() | Calls Gate::authorize('tenant.student-fee-management.viewAny') | — | — | ◌ |
| TC-CR02 | CR | P1 | Re-admission status filter logic | Uses whereNotNull/whereNull on re_activated_date | — | — | ◌ |
| TC-CR03 | CR | P1 | Stats computed from DB aggregates | Uses count(), sum(), avg() directly | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Governance Page Loads With Name Removal Log

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loaded |
| 2 | Expand "Student Fee" from left sidebar | Menu options appear |
| 3 | Click "Governance" tab | GET /student-fee/governance |
| 4 | Check stats card at top | Shows: Total, Removed, Readmitted, Total Due, Avg Days Overdue |
| 5 | Check the name removal log table | Table with columns: Student Name, Removal Date, Total Due, Days Overdue, Removed By, Re-admission Status |
| 6 | Check pagination footer | Pagination controls visible (if >15 records) |

### TC-P04: Filter By Readmitted Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure some records have re_activated_date set and some don't | Mixed data exists |
| 2 | Select "Readmitted" from status filter dropdown | Page reloads with `?status=readmitted` |
| 3 | Verify all displayed records have non-null re_activated_date | All rows show readmitted status |
| 4 | Verify count matches stats.readmitted number | Filtered count matches |

---

## 8. Known Issues

- Read-only display: No create/edit/delete operations from this screen
- Model does not use SoftDeletes trait (unlike other fee models)
- `FeeDefaulterHistory` table exists in DDL but not used in the governance() controller method directly

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/governance` | `student-fee.governance` | `StudentFeeManagementController@governance` |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
