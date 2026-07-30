# fee_Dashboard_TcList

## Module: StudentFee → Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee (FEE) |
| Tab Group | Dashboard (Single Endpoint) |
| Features | Dashboard Data — Summary KPIs (Total Fee, Collected, Outstanding, Students, Defaulters, Scholarship, Concession), Last 6 Months Collection Trend Chart, Recent 5 Transactions, Top 5 Defaulter Invoices, Class-Section Fee Collection Details |
| URL(s) | `GET /student-fee/dashboard` (name: `student-fee.dashboard`), `GET /student-fee/dashboard/fee-collection-details` (name: `dashboard.fee-collection`) |
| Controller | `Modules\StudentFee\Http\Controllers\StudentFeeManagementController` — `dashboard()` (lines 27–123), `dashboardFeeCollection()` (lines 125–233) |
| Model(s) | `FeeStudentAssignment`, `FeeTransaction`, `FeeInvoice`, `FeeScholarshipApplication`, `FeeStudentConcession`, `StudentAcademicSession`, `AcademicSession` |
| Validation | None — no FormRequest; no input parameters on main dashboard; fee-collection endpoint also has no parameters |
| Permission Gates | `Gate::authorize('tenant.student-fee-management.viewAny')` — single gate for both methods |
| Soft Deletes | FeeStudentAssignment filtered by `whereNull('deleted_at')` |
| Events | None — no activityLog calls in either dashboard method |

---

## 2. Pre-conditions

- Required permission: `tenant.student-fee-management.viewAny`
- At least one active academic session in `sch_org_academic_sessions_jnt` resolved via `AcademicSession::current()`
- For non-empty dashboard: at least one active `fee_student_assignment` record for the current session (`is_active = true`, `deleted_at IS NULL`)
- For total collected: at least one `fee_transaction` with `status = 'Success'` for students in the current session
- For defaulter data: at least one `fee_invoice` with `status = 'Overdue'` linked to an assignment in the current session
- For scholarship data: at least one `fee_scholarship_application` with `status = 'Approved'`
- For concession data: at least one `fee_student_concession` with `approval_status = 'Approved'`
- For chart data: successful transactions spanning multiple months within the last 6 calendar months
- For fee-collection details: `StudentAcademicSession` records with `session_status_id = 1` for the current session
- Tenant context must be initialized (stancl/tenancy)

---

## 3. Default Data Load

### 3.1 Session Resolution

When `dashboard()` or `dashboardFeeCollection()` loads:

| Parameter | Source | Default if Missing |
|-----------|--------|--------------------|
| academic_session_id | `AcademicSession::current()->first()` | Returns null → ALL KPIs default to zero/empty, empty collections returned to view |

### 3.2 Dashboard Data (`dashboard()`)

| Data | Query | Filters | Limit |
|------|-------|---------|-------|
| Student IDs | `FeeStudentAssignment::where('academic_session_id', $sessionId)->where('is_active', true)->whereNull('deleted_at')->pluck('student_id')` | active, current session, not soft-deleted | None |
| Total Fee Amount | `FeeStudentAssignment::where(...)->sum('total_fee_amount')` | Same as above | None (single agg) |
| Total Fee Collected | `FeeTransaction::whereIn('student_id', $studentIds)->where('status', 'Success')->sum('amount')` | Success status, students in session | None (single agg) |
| Total Fee Outstanding | `max(0, TotalFeeAmount - TotalFeeCollected)` | Clamped to minimum 0 | None |
| Total Students Count | `StudentAcademicSession::where('academic_session_id', $sessionId)->where('session_status_id', 1)->count()` | Active enrollment in session | None |
| Defaulter Students | `FeeInvoice::whereHas('studentAssignment', fn($q) => $q->where('academic_session_id', $sessionId))->where('status', 'Overdue')->get()` | Overdue invoices, session-scoped | None (full collection) |
| Scholarship Students | `FeeScholarshipApplication::where('status', 'Approved')->whereIn('student_id', $studentIds)->get()` | Approved, students in session | None (full collection) |
| Concession Students | `FeeStudentConcession::where('approval_status', 'Approved')->whereHas('assignment', fn($q) => $q->where('academic_session_id', $sessionId))->get()` | Approved, session-scoped | None (full collection) |
| Recent Transactions | `FeeTransaction::whereIn('student_id', $studentIds)->whereIn('status', ['Success', 'Pending'])->with(['student.user'])->latest('payment_date')` | Success/Pending status, session students | 5 |
| Top Defaulter Invoices | `FeeInvoice::whereHas('studentAssignment', fn($q) => $q->where('academic_session_id', $sessionId))->where('status', 'Overdue')->with(['studentAssignment.student.user'])->orderByDesc('balance_amount')` | Overdue, session-scoped | 5 |
| Chart Labels | 6 months: `now()->subMonths(5)` to `now()`, formatted as `'M Y'` | Last 6 calendar months | 6 |
| Chart Collected | Per-month sum of successful transactions for session students using `whereYear`/`whereMonth` | Same month scope | 6 |

### 3.3 Chart Data Calculation

```
for i = 5 to 0:
    month = now() - i months
    chartLabels[] = month->format('M Y')   // e.g., "Jan 2026"
    chartCollected[] = FeeTransaction::whereIn('student_id', $studentIds)
        ->where('status', 'Success')
        ->whereYear('payment_date', month->year)
        ->whereMonth('payment_date', month->month)
        ->sum('amount')
```

---

## 4. BC-DB — Database Schema

### 4.1 `fee_student_assignments` — Student Fee Assignments

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| student_id | INT UNSIGNED | NOT NULL | — | FK → std_students(id) ON DELETE CASCADE |
| class_id | INT UNSIGNED | NOT NULL | — | FK → sch_classes(id) ON DELETE RESTRICT (denormalized) |
| section_id | INT UNSIGNED | YES | NULL | FK → sch_sections(id) ON DELETE RESTRICT (denormalized) |
| academic_session_id | SMALLINT UNSIGNED | NOT NULL | — | FK → sch_org_academic_sessions_jnt(id) ON DELETE RESTRICT |
| fee_structure_id | INT UNSIGNED | NOT NULL | — | FK → fee_structure_master(id) ON DELETE RESTRICT |
| total_fee_amount | DECIMAL(12,2) | NOT NULL | — | Sum of structure details |
| opted_heads | JSON | YES | NULL | Selected optional heads |
| opted_groups | JSON | YES | NULL | Selected optional groups |
| assignment_date | DATE | NOT NULL | — | Assignment date |
| join_in_mid-year | TINYINT(1) | NOT NULL | 0 | Mid-year join flag |
| fee_start_date | DATE | YES | NULL | Fee start date for mid-year joins |
| proration_percentage | DECIMAL(5,2) | YES | NULL | Proration percentage |
| is_active | TINYINT(1) | NOT NULL | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Unique Constraint:** `uq_fee_student_session` on `(student_id, academic_session_id)`

### 4.2 `fee_transactions` — Payment Transactions

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| transaction_no | VARCHAR(50) | NOT NULL | — | Unique transaction number |
| student_id | INT UNSIGNED | NOT NULL | — | FK → std_students(id) ON DELETE RESTRICT |
| invoice_id | INT UNSIGNED | NOT NULL | — | FK → fee_invoices(id) ON DELETE RESTRICT |
| guardian_id | INT UNSIGNED | YES | NULL | FK → std_guardians(id) ON DELETE SET NULL |
| payment_date | DATETIME | NOT NULL | — | Payment date/time |
| payment_mode | ENUM('Cash','Cheque','DD','UPI','Credit Card','Debit Card','Net Banking','Wallet') | NOT NULL | — | Payment mode |
| payment_reference | VARCHAR(100) | YES | NULL | Cheque/DD/Transaction ID |
| bank_name | VARCHAR(100) | YES | NULL | Bank name |
| cheque_date | DATE | YES | NULL | Cheque date |
| amount | DECIMAL(12,2) | NOT NULL | — | Transaction amount |
| fine_adjusted | DECIMAL(10,2) | NOT NULL | 0.00 | Fine amount adjusted |
| concession_adjusted | DECIMAL(10,2) | NOT NULL | 0.00 | Concession amount adjusted |
| status | ENUM('Success','Pending','Failed','Refunded') | NOT NULL | 'Pending' | Transaction status |
| collected_by | INT UNSIGNED | NOT NULL | — | FK → sys_users(id) ON DELETE RESTRICT |
| remarks | TEXT | YES | NULL | Remarks |
| receipt_generated | TINYINT(1) | NOT NULL | 0 | Receipt flag |
| receipt_id | INT UNSIGNED | YES | NULL | FK → fee_receipts(id) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

### 4.3 `fee_invoices` — Fee Invoices

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| invoice_no | VARCHAR(50) | NOT NULL | — | Unique invoice number |
| student_assignment_id | INT UNSIGNED | NOT NULL | — | FK → fee_student_assignments(id) ON DELETE RESTRICT |
| installment_id | INT UNSIGNED | YES | NULL | FK → fee_installments(id) ON DELETE SET NULL |
| invoice_date | DATE | NOT NULL | — | Invoice date |
| due_date | DATE | NOT NULL | — | Due date |
| base_amount | DECIMAL(12,2) | NOT NULL | — | Base amount |
| concession_amount | DECIMAL(12,2) | NOT NULL | 0.00 | Concession amount |
| fine_amount | DECIMAL(12,2) | NOT NULL | 0.00 | Fine amount |
| tax_amount | DECIMAL(12,2) | NOT NULL | 0.00 | Tax amount |
| total_amount | DECIMAL(12,2) | NOT NULL | — | Total amount |
| paid_amount | DECIMAL(12,2) | NOT NULL | 0.00 | Paid amount |
| balance_amount | DECIMAL(12,2) | GENERATED ALWAYS | AS (`total_amount` - `paid_amount`) STORED | Computed balance |
| status | ENUM('Draft','Published','Partially Paid','Paid','Overdue','Cancelled') | NOT NULL | 'Draft' | Invoice status |
| invoice_pdf_path | VARCHAR(255) | YES | NULL | PDF path |
| generated_by | INT UNSIGNED | NOT NULL | — | FK → sys_users(id) ON DELETE RESTRICT |
| cancelled_by | INT UNSIGNED | YES | NULL | FK → sys_users(id) |
| cancellation_reason | TEXT | YES | NULL | Cancellation reason |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

### 4.4 `fee_scholarship_applications` — Scholarship Applications

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| scholarship_id | INT UNSIGNED | NOT NULL | — | FK → fee_scholarships(id) ON DELETE RESTRICT |
| student_id | INT UNSIGNED | NOT NULL | — | FK → std_students(id) ON DELETE RESTRICT |
| academic_session_id | SMALLINT UNSIGNED | NOT NULL | — | FK → sch_org_academic_sessions_jnt(id) ON DELETE RESTRICT |
| application_date | DATE | NOT NULL | — | Application date |
| application_data | JSON | NOT NULL | — | Student responses |
| documents_submitted | JSON | YES | NULL | Submitted documents |
| current_stage | INT | NOT NULL | 1 | Current approval stage |
| status | ENUM('Draft','Submitted','Under Review','Approved','Rejected','Waitlisted') | NOT NULL | 'Draft' | Application status |
| review_committee | JSON | YES | NULL | Committee members |
| approved_amount | DECIMAL(10,2) | YES | NULL | Approved amount |
| disbursed | TINYINT(1) | NOT NULL | 0 | Disbursed flag |
| disbursed_date | DATE | YES | NULL | Disbursement date |
| remarks | TEXT | YES | NULL | Remarks |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

### 4.5 `fee_student_concessions` — Student Concessions

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| student_assignment_id | INT UNSIGNED | NOT NULL | — | FK → fee_student_assignments(id) ON DELETE CASCADE |
| concession_type_id | INT UNSIGNED | NOT NULL | — | FK → fee_concession_types(id) ON DELETE RESTRICT |
| approved_by | INT UNSIGNED | YES | NULL | FK → sys_users(id) |
| approved_at | TIMESTAMP | YES | NULL | Approval timestamp |
| approval_status | ENUM('Pending','Approved','Rejected') | NOT NULL | 'Pending' | Approval status |
| rejection_reason | TEXT | YES | NULL | Rejection reason |
| discount_amount | DECIMAL(10,2) | NOT NULL | — | Discount amount |
| remarks | TEXT | YES | NULL | Remarks |
| created_by | INT UNSIGNED | YES | NULL | FK → sys_users(id) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |

---

## 5. BC-VAL — Validation Rules

### 5.1 Input Parameters

| Parameter | Type | Default | Parsing | Validation |
|-----------|------|---------|---------|------------|
| (none) | — | — | — | **No input parameters** — both `dashboard()` and `dashboardFeeCollection()` accept no request input; all data is derived from the current academic session |

**Known Gap:** No search/filter/date-range parameters on the dashboard — all data is hard-scoped to the entire current academic session.

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method | Access |
|-----------------|-------------------|--------|
| `tenant.student-fee-management.viewAny` | `dashboard()` | Grants access to ALL dashboard data |
| `tenant.student-fee-management.viewAny` | `dashboardFeeCollection()` | Grants access to detailed fee collection view |

**Behaviour:** `Gate::authorize('tenant.student-fee-management.viewAny')` — if the user lacks this permission, a `\Illuminate\Auth\Access\AuthorizationException` is thrown resulting in a 403 HTTP response. No granular scoping — this single permission controls access to ALL dashboard data and ALL other tabs in the module.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-D01 | Single Gate Authorization | `dashboard()` and `dashboardFeeCollection()` both use `Gate::authorize('tenant.student-fee-management.viewAny')` — single permission controls all dashboard access |
| BC-BIZ-D02 | Current Session Resolution | Both methods call `AcademicSession::current()->first()` — if null, ALL KPIs default to zero/empty |
| BC-BIZ-D03 | Student ID Collection | `FeeStudentAssignment::where('academic_session_id', $sessionId)->where('is_active', true)->whereNull('deleted_at')->pluck('student_id')` — active, non-deleted assignments only |
| BC-BIZ-D04 | Total Fee Sum | Sum of `total_fee_amount` from active, non-deleted assignments in current session |
| BC-BIZ-D05 | Total Collected Sum | Sum of `amount` from `FeeTransaction::where('status', 'Success')` scoped to session student IDs |
| BC-BIZ-D06 | Outstanding Clamping | `max(0, totalFeeAmount - totalFeeCollected)` — never negative |
| BC-BIZ-D07 | Student Count | `StudentAcademicSession::where('academic_session_id', $sessionId)->where('session_status_id', 1)` — actively enrolled only |
| BC-BIZ-D08 | Defaulter Identification | `FeeInvoice::where('status', 'Overdue')` with `whereHas('studentAssignment', session scope)` — counts all overdue invoices in session |
| BC-BIZ-D09 | Scholarship Identification | `FeeScholarshipApplication::where('status', 'Approved')` with `whereIn('student_id', $studentIds)` — approved scholarships for session students |
| BC-BIZ-D10 | Concession Identification | `FeeStudentConcession::where('approval_status', 'Approved')` with `whereHas('assignment', session scope)` — approved concessions for session assignments |
| BC-BIZ-D11 | Recent Transactions | Success or Pending status, session students, eager-loads `student.user`, ordered by `payment_date` DESC, limited to 5 |
| BC-BIZ-D12 | Top Defaulter Invoices | Overdue status, session-scoped, eager-loads `studentAssignment.student.user`, ordered by `balance_amount` DESC, limited to 5 |
| BC-BIZ-D13 | 6-Month Chart | Iterates `i` from 5 down to 0, subtracts `i` months from `now()`, formats label as `'M Y'`, sums successful transactions per month using `whereYear`/`whereMonth` |
| BC-BIZ-D14 | Empty Session — Default Data | When `!$currentSession`, returns view with 0/empty/collect() for all 11 view variables |
| BC-BIZ-D15 | No Pagination on Dashboard | Both methods return collection objects (not paginated) for KPIs. The view may limit display (5 transactions, 5 defaulters) but the queries return full collections |
| BC-BIZ-D16 | Fee Collection — Paid Calculation | `dashboardFeeCollection()` computes paid amounts per student via `FeeTransaction::groupBy('student_id')->selectRaw('student_id, SUM(amount) as total_paid')` scoped to `status = 'Success'` |
| BC-BIZ-D17 | Fee Collection — Class-Section Grouping | `StudentAcademicSession::with(['classSection.class', 'classSection.section', 'student.user'])->where('session_status_id', 1)` gets all enrolled students, then `->groupBy(fn($item) => $item->classSection->class->name . ' - ' . $item->classSection->section->name)` |
| BC-BIZ-D18 | Fee Collection — Chart | Charts total fee vs collected per class-section group; collected from `$paidByStudentId` map (real paid amounts from successful transactions) |
| BC-BIZ-D19 | Fee Collection — Assignment Eager Load | `FeeStudentAssignment::with(['feeStructure.details.head'])->where('academic_session_id', $sessionId)->where('is_active', true)->whereNull('deleted_at')->get()->keyBy('student_id')` — keyed by student_id for O(1) lookup |
| BC-BIZ-D20 | No Caching | Entire dashboard recomputed on every request — no cache/store/remember calls in either method |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_fsa_student | fee_student_assignments.student_id | std_students.id | CASCADE |
| fk_fsa_class | fee_student_assignments.class_id | sch_classes.id | RESTRICT |
| fk_fsa_section | fee_student_assignments.section_id | sch_sections.id | RESTRICT |
| fk_fsa_session | fee_student_assignments.academic_session_id | sch_org_academic_sessions_jnt.id | RESTRICT |
| fk_fsa_structure | fee_student_assignments.fee_structure_id | fee_structure_master.id | RESTRICT |
| fk_ft_student | fee_transactions.student_id | std_students.id | RESTRICT |
| fk_ft_invoice | fee_transactions.invoice_id | fee_invoices.id | RESTRICT |
| fk_ft_guardian | fee_transactions.guardian_id | std_guardians.id | SET NULL |
| fk_ft_collector | fee_transactions.collected_by | sys_users.id | RESTRICT |
| fk_finv_assignment | fee_invoices.student_assignment_id | fee_student_assignments.id | RESTRICT |
| fk_finv_installment | fee_invoices.installment_id | fee_installments.id | SET NULL |
| fk_finv_generator | fee_invoices.generated_by | sys_users.id | RESTRICT |
| fk_fsc_assignment | fee_student_concessions.student_assignment_id | fee_student_assignments.id | CASCADE |
| fk_fsc_concession | fee_student_concessions.concession_type_id | fee_concession_types.id | RESTRICT |
| fk_fsc_approver | fee_student_concessions.approved_by | sys_users.id | SET NULL |
| fk_fschapp_scholarship | fee_scholarship_applications.scholarship_id | fee_scholarships.id | RESTRICT |
| fk_fschapp_student | fee_scholarship_applications.student_id | std_students.id | RESTRICT |
| fk_fschapp_session | fee_scholarship_applications.academic_session_id | sch_org_academic_sessions_jnt.id | RESTRICT |

---

## 9. Test Case Summary

### 9.1 Dashboard — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-FEE-D-P01 | Dashboard | Positive | Dashboard loads with current academic session and displays all KPIs | 4 |
| TC-FEE-D-P02 | Dashboard | Positive | Dashboard gracefully loads with zero data when no academic session exists | 3 |
| TC-FEE-D-P03 | Dashboard | Positive | Dashboard loads with no student assignments — all fee KPIs show zero | 3 |
| TC-FEE-D-P04 | Total Fee Amount | Positive | Total Fee Amount sums active assignment totals correctly | 3 |
| TC-FEE-D-P05 | Total Fee Amount | Positive | Total Fee Amount excludes soft-deleted assignments from sum | 3 |
| TC-FEE-D-P06 | Total Fee Collected | Positive | Total Fee Collected sums only Success transactions | 3 |
| TC-FEE-D-P07 | Total Fee Collected | Positive | Total Fee Collected excludes Pending/Failed/Refunded transactions | 3 |
| TC-FEE-D-P08 | Total Fee Outstanding | Positive | Total Outstanding = Total Fee − Total Collected (positive) | 3 |
| TC-FEE-D-P09 | Total Fee Outstanding | Positive | Total Outstanding clamped to 0 when over-collected | 3 |
| TC-FEE-D-P10 | Total Students | Positive | Total Students Count matches enrolled count for session | 3 |
| TC-FEE-D-P11 | Total Students | Positive | Total Students Count excludes students with non-1 session_status_id | 3 |
| TC-FEE-D-P12 | Defaulter Students | Positive | Defaulter count matches overdue invoices in session | 3 |
| TC-FEE-D-P13 | Defaulter Students | Positive | Zero defaulters when no overdue invoices exist | 3 |
| TC-FEE-D-P14 | Scholarship Students | Positive | Scholarship count matches approved applications for session students | 3 |
| TC-FEE-D-P15 | Scholarship Students | Positive | Zero scholarships when no approved applications exist | 3 |
| TC-FEE-D-P16 | Concession Students | Positive | Concession count matches approved concessions for session assignments | 3 |
| TC-FEE-D-P17 | Concession Students | Positive | Zero concessions when no approved concessions exist | 3 |
| TC-FEE-D-P18 | Recent Transactions | Positive | Recent transactions returns 5 most recent by payment_date DESC | 4 |
| TC-FEE-D-P19 | Recent Transactions | Positive | Recent transactions includes both Success and Pending statuses | 3 |
| TC-FEE-D-P20 | Recent Transactions | Positive | Fewer than 5 transactions returns all available | 3 |
| TC-FEE-D-P21 | Recent Transactions | Positive | Recent transaction includes student.user relation (student name) | 3 |
| TC-FEE-D-P22 | Top Defaulter Invoices | Positive | Top defaulters sorted by balance_amount DESC | 4 |
| TC-FEE-D-P23 | Top Defaulter Invoices | Positive | Top defaulters limited to 5 invoices | 3 |
| TC-FEE-D-P24 | Top Defaulter Invoices | Positive | Fewer than 5 overdue invoices returns all available | 3 |
| TC-FEE-D-P25 | Top Defaulter Invoices | Positive | Top defaulter includes student name from studentAssignment.student.user | 3 |
| TC-FEE-D-P26 | Top Defaulter Invoices | Positive | Empty top defaulters when no overdue invoices exist | 3 |
| TC-FEE-D-P27 | 6-Month Chart | Positive | Chart has exactly 6 labels (monthly, last 6 months) | 3 |
| TC-FEE-D-P28 | 6-Month Chart | Positive | Chart labels formatted as 'M Y' (e.g., 'Jan 2026') | 3 |
| TC-FEE-D-P29 | 6-Month Chart | Positive | Chart collected values sum successful transactions per month | 4 |
| TC-FEE-D-P30 | 6-Month Chart | Positive | Chart shows zero for months with no transactions | 3 |
| TC-FEE-D-P31 | Auth | Positive | User with tenant.student-fee-management.viewAny can access dashboard | 2 |
| TC-FEE-D-P32 | Fee Collection Detail | Positive | Fee collection view groups students by class-section | 4 |
| TC-FEE-D-P33 | Fee Collection Detail | Positive | Fee collection view shows per-student fee, paid, outstanding | 4 |
| TC-FEE-D-P34 | Fee Collection Detail | Positive | Fee collection chart compares total vs collected per class-section | 3 |
| TC-FEE-D-P35 | Fee Collection Detail | Positive | Paid amounts match successful transaction sums per student | 3 |
| TC-FEE-D-P36 | Fee Collection Detail | Positive | Zero state when no students enrolled in session | 3 |

### 9.2 Dashboard — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-FEE-D-N01 | Auth | Negative | No permission — missing tenant.student-fee-management.viewAny returns 403 Forbidden | 2 |
| TC-FEE-D-N02 | Session | Negative | No active academic session — all KPIs default to zero/empty gracefully | 3 |
| TC-FEE-D-N03 | Session | Negative | AcademicSession::current() returns empty collection — empty state rendered | 2 |
| TC-FEE-D-N04 | Assignments | Negative | No active assignments in current session — Total Fee = 0, Collected = 0 | 2 |
| TC-FEE-D-N05 | Assignments | Negative | Only soft-deleted assignments exist — excluded from all calculations | 3 |
| TC-FEE-D-N06 | Transactions | Negative | Only Failed transactions exist — Total Collected = 0 | 2 |
| TC-FEE-D-N07 | Transactions | Negative | Only Pending transactions exist — Total Collected = 0 | 2 |
| TC-FEE-D-N08 | Invoices | Negative | No invoices at all — defaulter count = 0, top defaulters = empty | 2 |
| TC-FEE-D-N09 | Outstanding | Negative | Over-collection scenario (refunds not yet processed) — outstanding clamped to 0 | 3 |
| TC-FEE-D-N10 | Chart | Negative | No transactions in any of the last 6 months — all chart values = 0 | 2 |
| TC-FEE-D-N11 | Scholarship | Negative | Scholarship applications exist but none approved — scholarship count = 0 | 2 |
| TC-FEE-D-N12 | Concession | Negative | Concessions exist but none approved — concession count = 0 | 2 |
| TC-FEE-D-N13 | Invoices | Negative | Invoices exist but none with Overdue status — defaulter count = 0 | 2 |
| TC-FEE-D-N14 | Students | Negative | StudentAcademicSession records exist but with session_status_id != 1 — not counted | 3 |
| TC-FEE-D-N15 | Students | Negative | No StudentAcademicSession records for current session — student count = 0 | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-D01 | Code Review | Review | Gate::authorize('tenant.student-fee-management.viewAny') — single gate for entire dashboard | 2 |
| TC-CR-D02 | Code Review | Review | Session resolution — AcademicSession::current()->first() with null guard | 3 |
| TC-CR-D03 | Code Review | Review | Student IDs collected via pluck — two separate queries for assignments (IDs + sum) | 3 |
| TC-CR-D04 | Code Review | Review | Total fee collected scoped to session student IDs via whereIn | 3 |
| TC-CR-D05 | Code Review | Review | Outstanding formula uses max(0, ...) — no negative outstanding | 2 |
| TC-CR-D06 | Code Review | Review | Recent transactions limited to 5 with latest('payment_date') ordering | 2 |
| TC-CR-D07 | Code Review | Review | Top defaulters ordered by balance_amount DESC — highest debt first | 2 |
| TC-CR-D08 | Code Review | Review | Chart loops 6 times with subMonths — uses whereYear/whereMonth (not raw SQL) | 3 |
| TC-CR-D09 | Code Review | Review | No caching — entire dashboard recomputed on every request | 2 |
| TC-CR-D10 | Code Review | Review | No pagination — defaulterStudents/scholarshipStudents/concessionStudents load full collections | 3 |
| TC-CR-D11 | Code Review | Review | Empty state returns 11 view variables with zero/empty/collect() defaults | 3 |
| TC-CR-D12 | Code Review | Review | FeeCollection uses groupBy on Collection (class-section name) — in-memory grouping | 3 |
| TC-CR-D13 | Code Review | Review | FeeCollection paidByStudentId uses groupBy + selectRaw on DB — single query | 3 |
| TC-CR-D14 | Code Review | Review | FeeCollection chart rounds values with round() — integer display values | 2 |
| TC-CR-D15 | Code Review | Review | Concession query uses whereHas('assignment', session scope) — nested existence check | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-FEE-D-D01 | Dependency | Dependency | FeeStudentAssignment::where('academic_session_id', ...) — session FK exists | 2 |
| TC-FEE-D-D02 | Dependency | Dependency | FeeTransaction::where('status', 'Success') — ENUM value exists in DB | 2 |
| TC-FEE-D-D03 | Dependency | Dependency | FeeInvoice::where('status', 'Overdue') — ENUM value exists in DB | 2 |
| TC-FEE-D-D04 | Dependency | Dependency | FeeInvoice studentAssignment() relationship — belongsTo FeeStudentAssignment | 2 |
| TC-FEE-D-D05 | Dependency | Dependency | FeeTransaction student() relationship — belongsTo Student | 2 |
| TC-FEE-D-D06 | Dependency | Dependency | FeeTransaction student.user() relationship — belongsTo User through Student | 2 |
| TC-FEE-D-D07 | Dependency | Dependency | FeeInvoice studentAssignment.student.user() — chained relationships | 2 |
| TC-FEE-D-D08 | Dependency | Dependency | FeeScholarshipApplication::where('status', 'Approved') — ENUM value exists | 2 |
| TC-FEE-D-D09 | Dependency | Dependency | FeeStudentConcession::where('approval_status', 'Approved') — ENUM value exists | 2 |
| TC-FEE-D-D10 | Dependency | Dependency | StudentAcademicSession::where('session_status_id', 1) — status FK exists | 2 |
| TC-FEE-D-D11 | Dependency | Dependency | AcademicSession::current() scope — requires AcademicSession model in Prime module | 2 |
| TC-FEE-D-D12 | Dependency | Dependency | FeeStudentAssignment::whereNull('deleted_at') — SoftDeletes trait used | 2 |
| TC-FEE-D-D13 | Dependency | Dependency | Invoice balance_amount is MySQL GENERATED ALWAYS column — real-time computed | 2 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Dashboard

#### TC-FEE-D-P01: Dashboard loads with current academic session and displays all KPIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.student-fee-management.viewAny` permission sends GET to `/student-fee/dashboard` | 200 OK |
| 2 | Ensure an active academic session exists and fee_student_assignments have data for the session | Pre-condition |
| 3 | Verify `totalFeeAmount` > 0, `totalFeeCollected` > 0, `totalFeeOutstanding` >= 0 | KPIs populated |
| 4 | Verify all 11 view variables (totalFeeAmount, totalFeeCollected, totalFeeOutstanding, totalStudentsCount, defaulterStudents, scholarshipStudents, concessionStudents, recentTransactions, topDefaulterInvoices, chartLabels, chartCollected) are present | Full structure |

#### TC-FEE-D-P02: Dashboard gracefully loads with zero data when no academic session exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active academic session exists (AcademicSession::current() returns null) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK (no exception) |
| 3 | Verify all KPIs: totalFeeAmount=0, totalFeeCollected=0, totalFeeOutstanding=0, totalStudentsCount=0, defaulterStudents=empty collect(), scholarshipStudents=empty collect(), concessionStudents=empty collect(), recentTransactions=empty collect(), topDefaulterInvoices=empty collect(), chartLabels=[], chartCollected=[] | Zero data state |

#### TC-FEE-D-P03: Dashboard loads with no student assignments — all fee KPIs show zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active session exists but no fee_student_assignments for that session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeAmount=0, totalFeeCollected=0, totalFeeOutstanding=0 (student count may still be > 0) | Fee KPIs zero |

#### TC-FEE-D-P04: Total Fee Amount sums active assignment totals correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 fee_student_assignments for current session: amounts 25000, 35000, 40000, all is_active=true, deleted_at=null | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeAmount = 100000 (25000 + 35000 + 40000) | Correct sum |

#### TC-FEE-D-P05: Total Fee Amount excludes soft-deleted assignments from sum

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 2 active assignments (25000, 35000) and 1 soft-deleted (40000, deleted_at not null) for current session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeAmount = 60000 (25000 + 35000, excludes 40000) | Excludes soft-deleted |

#### TC-FEE-D-P06: Total Fee Collected sums only Success transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 transactions for session students: T1 (Success, 25000), T2 (Success, 15000), T3 (Pending, 10000) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeCollected = 40000 (25000 + 15000, excludes Pending 10000) | Only Success counted |

#### TC-FEE-D-P07: Total Fee Collected excludes Pending/Failed/Refunded transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 4 transactions: Success(10000), Pending(5000), Failed(2000), Refunded(3000) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeCollected = 10000 (only Success counted) | Others excluded |

#### TC-FEE-D-P08: Total Outstanding = Total Fee − Total Collected (positive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: totalFeeAmount=100000, totalFeeCollected=65000 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeOutstanding = 35000 (100000 − 65000) | Correct outstanding |

#### TC-FEE-D-P09: Total Outstanding clamped to 0 when over-collected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: totalFeeAmount=50000, totalFeeCollected=55000 (over-collected, e.g., before refund processed) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeOutstanding = 0 (clamped by max(0, ...)) | Clamped to zero |

#### TC-FEE-D-P10: Total Students Count matches enrolled count for session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 10 StudentAcademicSession records for current session with session_status_id=1 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalStudentsCount = 10 | Correct count |

#### TC-FEE-D-P11: Total Students Count excludes students with non-1 session_status_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 8 records with session_status_id=1, 3 records with session_status_id=2 (transferred) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalStudentsCount = 8 (excludes status_id=2) | Only active counted |

#### TC-FEE-D-P12: Defaulter count matches overdue invoices in session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 5 overdue invoices (status='Overdue') linked to session assignments | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify defaulterStudents collection has 5 items | Correct count |

#### TC-FEE-D-P13: Zero defaulters when no overdue invoices exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no invoices have status='Overdue' for current session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify defaulterStudents is empty collect() | No defaulters |

#### TC-FEE-D-P14: Scholarship count matches approved applications for session students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 scholarship applications with status='Approved' for session students | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify scholarshipStudents collection has 3 items | Correct count |

#### TC-FEE-D-P15: Zero scholarships when no approved applications exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Scholarship applications exist but none with status='Approved' (Draft/Submitted/Rejected) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify scholarshipStudents is empty collect() | No scholarships |

#### TC-FEE-D-P16: Concession count matches approved concessions for session assignments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 4 concessions with approval_status='Approved' linked to session assignments | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify concessionStudents collection has 4 items | Correct count |

#### TC-FEE-D-P17: Zero concessions when no approved concessions exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Concessions exist but none with approval_status='Approved' (Pending/Rejected) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify concessionStudents is empty collect() | No concessions |

#### TC-FEE-D-P18: Recent transactions returns 5 most recent by payment_date DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 7 transactions with staggered payment_dates (Jan 1–7, 2026) for session students | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify recentTransactions has 5 entries | Limited to 5 |
| 4 | Verify entries ordered by payment_date DESC (Jan 7, Jan 6, Jan 5, Jan 4, Jan 3) | Most recent first |

#### TC-FEE-D-P19: Recent transactions includes both Success and Pending statuses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 Success and 2 Pending transactions for session students | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify all 5 transactions appear (mix of Success and Pending statuses) | Both statuses included |

#### TC-FEE-D-P20: Fewer than 5 transactions returns all available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create only 3 transactions for session students | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify recentTransactions has 3 entries | All returned |

#### TC-FEE-D-P21: Recent transaction includes student.user relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a transaction for student with linked user (name='Rahul Sharma') | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify recentTransactions[0]->student->user has name data accessible by view | Relation loaded |

#### TC-FEE-D-P22: Top defaulter invoices sorted by balance_amount DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 overdue invoices with balance: INV1=45000, INV2=38000, INV3=32000, INV4=28000, INV5=22000 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify topDefaulterInvoices ordered by balance_amount DESC (45000, 38000, 32000, 28000, 22000) | Highest first |

#### TC-FEE-D-P23: Top defaulter invoices limited to 5

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 8 overdue invoices for session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify topDefaulterInvoices has 5 entries | Limited to 5 |

#### TC-FEE-D-P24: Fewer than 5 overdue invoices returns all available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create only 2 overdue invoices for session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify topDefaulterInvoices has 2 entries | All returned |

#### TC-FEE-D-P25: Top defaulter includes student name from chained relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create overdue invoice for student with user name via assignment → student → user chain | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify topDefaulterInvoices[0]->studentAssignment->student->user->name is accessible | Relation chain loaded |

#### TC-FEE-D-P26: Empty top defaulters when no overdue invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no invoices with status='Overdue' for current session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify topDefaulterInvoices is empty collect() | Empty collection |

#### TC-FEE-D-P27: Chart has exactly 6 labels (last 6 months)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Current date is, e.g., 2026-07-23 (any date) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify chartLabels has 6 entries (month-year strings) | 6 labels |

#### TC-FEE-D-P28: Chart labels formatted as 'M Y'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Current month is July 2026 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify chartLabels[5] = "Jul 2026" (current month), chartLabels[0] = "Feb 2026" (5 months ago) | 'M Y' format |

#### TC-FEE-D-P29: Chart collected values sum successful transactions per month

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create transactions: Feb 2026 (2 × 10000), Mar 2026 (1 × 15000), all Success, for session students | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify chartCollected[0] = 20000 (Feb sum), chartCollected[1] = 15000 (Mar sum) | Monthly sums correct |

#### TC-FEE-D-P30: Chart shows zero for months with no transactions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No transactions exist for any of the last 6 months | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify all chartCollected entries = 0.00 | Zero for empty months |

#### TC-FEE-D-P31: User with permission can access dashboard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user with `tenant.student-fee-management.viewAny` permission | Authenticated |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |

#### TC-FEE-D-P32: Fee collection view groups students by class-section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed students in classes: 5 in "10 - A", 3 in "10 - B" with session_status_id=1 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard/fee-collection-details` | 200 OK |
| 3 | Verify `groupedByClassSection` has 2 groups: "10 - A" (5 students), "10 - B" (3 students) | Grouped correctly |

#### TC-FEE-D-P33: Fee collection view shows per-student fee, paid, outstanding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has assignment (total=50000) and transaction (Success, amount=30000) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard/fee-collection-details` | 200 OK |
| 3 | Verify student entry in groupedByClassSection: total_fee=50000, paid=30000, outstanding=20000 | Per-student data |

#### TC-FEE-D-P34: Fee collection chart compares total vs collected per class-section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: Class "10 - A" has total_fee=500000, collected=350000; Class "10 - B" has total=300000, collected=250000 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard/fee-collection-details` | 200 OK |
| 3 | Verify chartLabels = ["10 - A", "10 - B"], chartTotalFee = [500000, 300000], chartCollected = [350000, 250000] | Chart data correct |

#### TC-FEE-D-P35: Paid amounts match successful transaction sums per student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Student has 2 successful transactions: 25000 + 15000 = 40000 total paid | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard/fee-collection-details` | 200 OK |
| 3 | Verify paidByStudentId for this student = 40000 (sum of both transactions) | Correct paid total |

#### TC-FEE-D-P36: Zero state when no students enrolled in session

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no StudentAcademicSession records for current session with session_status_id=1 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard/fee-collection-details` | 200 OK |
| 3 | Verify totalStudentsCount=0, groupedByClassSection=empty collect, chartLabels=[] | Zero state |

### 10.2 Negative TC Steps — Dashboard

#### TC-FEE-D-N01: No permission returns 403 Forbidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Authenticate as user WITHOUT `tenant.student-fee-management.viewAny` permission | Authenticated |
| 2 | Send GET to `/student-fee/dashboard` | 403 Forbidden |

#### TC-FEE-D-N02: No active academic session — all KPIs default to zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure AcademicSession::current() returns empty collection (no active session) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK (no exception) |
| 3 | Verify all KPIs are zero/empty as defined in TC-FEE-D-P02 | Graceful degradation |

#### TC-FEE-D-N03: AcademicSession::current() returns null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Simulate AcademicSession::current()->first() returning null | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify empty state view rendered instead of 500 error | No crash |

#### TC-FEE-D-N04: No active assignments — Total Fee = 0, Collected = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active session exists but no fee_student_assignments with is_active=true for that session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeAmount = 0, totalFeeCollected = 0, totalFeeOutstanding = 0 | Zero fee KPIs |

#### TC-FEE-D-N05: Only soft-deleted assignments exist — excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All fee_student_assignments for session have deleted_at not null | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeAmount = 0 (soft-deleted excluded by whereNull('deleted_at')) | Excluded |

#### TC-FEE-D-N06: Only Failed transactions — Total Collected = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Transactions exist but all have status='Failed' (not 'Success') | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeCollected = 0 | Failed excluded |

#### TC-FEE-D-N07: Only Pending transactions — Total Collected = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Transactions exist but all have status='Pending' (not 'Success') | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeCollected = 0 | Pending excluded from total |

#### TC-FEE-D-N08: No invoices at all — defaulter count = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no fee_invoices exist for any assignment in current session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify defaulterStudents is empty collect(), topDefaulterInvoices is empty collect() | Zero defaulter data |

#### TC-FEE-D-N09: Over-collection — outstanding clamped to 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Total fee assignments sum = 50000, but total success transactions = 55000 (e.g., payments before refund) | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalFeeOutstanding = 0 (not -5000) | Clamped |

#### TC-FEE-D-N10: No transactions in last 6 months — chart values all 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no successful fee_transactions exist for session students in last 6 months | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify all chartCollected entries = 0.00 | Zero chart values |

#### TC-FEE-D-N11: Scholarship apps exist but none approved — count = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed scholarship applications with statuses: Draft(1), Submitted(1), Under Review(1), Rejected(1) — none Approved | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify scholarshipStudents is empty collect() | Only approved counted |

#### TC-FEE-D-N12: Concessions exist but none approved — count = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed concessions with approval_statuses: Pending(2), Rejected(1) — none Approved | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify concessionStudents is empty collect() | Only approved counted |

#### TC-FEE-D-N13: Invoices exist but none overdue — defaulter count = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist with statuses: Published(2), Paid(3), Partially Paid(1), Cancelled(1) — none Overdue | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify defaulterStudents is empty collect() | Only overdue counted |

#### TC-FEE-D-N14: Students with non-1 session_status_id not counted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed: 5 students with session_status_id=1, 3 students with session_status_id=2, 2 with session_status_id=3 | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalStudentsCount = 5 (only status_id=1 counted) | Status filter correct |

#### TC-FEE-D-N15: No StudentAcademicSession records — student count = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no records in student_academic_sessions table for current session | Pre-condition |
| 2 | Send GET to `/student-fee/dashboard` | 200 OK |
| 3 | Verify totalStudentsCount = 0 | Zero students |

### 10.3 Code Review TC Steps — Dashboard

#### TC-CR-D01: Single gate authorization

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.student-fee-management.viewAny')` at line 29 of `dashboard()` | Single gate |
| 2 | Verify same gate at line 127 of `dashboardFeeCollection()` | Both methods protected |

#### TC-CR-D02: Session resolution with null guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$currentSession = \Modules\Prime\Models\AcademicSession::current()->first()` at line 31 | Session resolution |
| 2 | Review `if (!$currentSession)` guard returning zero/empty defaults at lines 33–47 | Null guard present |
| 3 | Verify same pattern in `dashboardFeeCollection()` at lines 129–146 | Consistent guard |

#### TC-CR-D03: Student IDs via pluck (two queries for assignments)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `FeeStudentAssignment::where(...)->pluck('student_id')` at lines 51–54 | IDs plucked |
| 2 | Review `FeeStudentAssignment::where(...)->sum('total_fee_amount')` at lines 56–59 | Sum query |
| 3 | Note: These are two separate DB queries — not combined into one | Optimization note |

#### TC-CR-D04: Fee collected scoped to session student IDs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `FeeTransaction::whereIn('student_id', $studentIds)->where('status', 'Success')->sum('amount')` at lines 61–63 | Scoped to session |

#### TC-CR-D05: Outstanding uses max(0, ...)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$totalFeeOutstanding = max(0, $totalFeeAmount - $totalFeeCollected)` at line 65 | Clamped |

#### TC-CR-D06: Recent transactions limited to 5 with payment_date DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->latest('payment_date')->limit(5)` at lines 83–88 | 5 limit + date ordering |

#### TC-CR-D07: Top defaulters ordered by balance_amount DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->orderByDesc('balance_amount')->limit(5)` at lines 90–95 | DESC + 5 limit |

#### TC-CR-D08: Chart uses whereYear/whereMonth (no raw SQL)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review chart loop at lines 98–108 — uses `whereYear` and `whereMonth` | No raw SQL |
| 2 | Note: This is DB-portable (unlike DATE_FORMAT raw SQL used in other modules) | Portable approach |

#### TC-CR-D09: No caching — full recompute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review entire `dashboard()` method for any cache/store/remember calls | No caching |
| 2 | Every request re-queries: assignments, transactions, invoices, scholarships, concessions, chart | Full recompute |

#### TC-CR-D10: No pagination on KPI collections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `defaulterStudents` query — no limit/pagination on get() | Full collection |
| 2 | Review `scholarshipStudents` query — no limit/pagination | Full collection |
| 3 | Review `concessionStudents` query — no limit/pagination | Full collection |

#### TC-CR-D11: Empty state returns 11 defaults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the `if (!$currentSession)` block — returns view with 11 zero/empty variables | 11 defaults |
| 2 | Verify each: totalFeeAmount=0, totalFeeCollected=0, totalFeeOutstanding=0, totalStudentsCount=0, 4x collect(), 2x [] | All defaulted |

#### TC-CR-D12: FeeCollection groups by class-section name in-memory

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->groupBy(function ($item) { return $item->classSection->class->name . ' - ' . $item->classSection->section->name; })` at lines 191–194 | In-memory grouping |

#### TC-CR-D13: FeeCollection paidByStudentId uses DB groupBy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `FeeTransaction::whereIn('student_id', $studentIds)->where('status', 'Success')->groupBy('student_id')->selectRaw('student_id, SUM(amount) as total_paid')->pluck('total_paid', 'student_id')` at lines 163–167 | DB-level aggregation |

#### TC-CR-D14: FeeCollection chart uses round()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `round($classTotal)` and `round($classCollected)` at lines 214–215 | Rounded values |

#### TC-CR-D15: Concession query uses whereHas

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `FeeStudentConcession::where('approval_status', 'Approved')->whereHas('assignment', fn($q) => $q->where('academic_session_id', $sessionId))` at lines 79–81 | Nested existence check |

### 10.4 Dependency TC Steps — Dashboard

#### TC-FEE-D-D01: FeeStudentAssignment academic_session_id FK exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `fee_student_assignments.academic_session_id SMALLINT UNSIGNED NOT NULL` | Column exists |
| 2 | Verify `fk_fsa_session` FK to `sch_org_academic_sessions_jnt(id) ON DELETE RESTRICT` | FK constraint |

#### TC-FEE-D-D02: FeeTransaction status ENUM includes 'Success'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `fee_transactions.status ENUM('Success','Pending','Failed','Refunded')` | ENUM defined |
| 2 | Verify 'Success' is a valid ENUM value | Included |

#### TC-FEE-D-D03: FeeInvoice status ENUM includes 'Overdue'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `fee_invoices.status ENUM('Draft','Published','Partially Paid','Paid','Overdue','Cancelled')` | ENUM defined |
| 2 | Verify 'Overdue' is a valid ENUM value | Included |

#### TC-FEE-D-D04: FeeInvoice studentAssignment() relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review FeeInvoice model for `studentAssignment()` method | belongsTo FeeStudentAssignment |
| 2 | Verify FK: `fee_invoices.student_assignment_id` → `fee_student_assignments.id` | FK mapped |

#### TC-FEE-D-D05: FeeTransaction student() relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review FeeTransaction model for `student()` method | belongsTo Student |
| 2 | Verify FK: `fee_transactions.student_id` → `std_students.id` | FK mapped |

#### TC-FEE-D-D06: FeeTransaction student.user() relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Student model for `user()` method | belongsTo User |
| 2 | Verify chained eager load: `->with(['student.user'])` at line 85 | Chain supported |

#### TC-FEE-D-D07: FeeInvoice studentAssignment.student.user() chain

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review FeeInvoice eager load: `->with(['studentAssignment.student.user'])` at line 92 | 3-level chain |
| 2 | Verify all intermediate relationships exist | Chain valid |

#### TC-FEE-D-D08: FeeScholarshipApplication status ENUM includes 'Approved'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `fee_scholarship_applications.status ENUM('Draft','Submitted','Under Review','Approved','Rejected','Waitlisted')` | ENUM defined |
| 2 | Verify 'Approved' is a valid ENUM value | Included |

#### TC-FEE-D-D09: FeeStudentConcession approval_status ENUM includes 'Approved'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `fee_student_concessions.approval_status ENUM('Pending','Approved','Rejected')` | ENUM defined |
| 2 | Verify 'Approved' is a valid ENUM value | Included |

#### TC-FEE-D-D10: StudentAcademicSession session_status_id column exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review StudentProfile model for `session_status_id` column | Column exists |
| 2 | Verify comparison `where('session_status_id', 1)` — 1 represents active enrollment | Status convention |

#### TC-FEE-D-D11: AcademicSession::current() scope exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `\Modules\Prime\Models\AcademicSession` for `scopeCurrent()` | Scope exists |
| 2 | Verify scope returns active session for the current date | Logic correct |

#### TC-FEE-D-D12: FeeStudentAssignment uses SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review FeeStudentAssignment model for `SoftDeletes` trait | Trait used |
| 2 | Verify `deleted_at` column in DDL | Column exists |
| 3 | Verify `whereNull('deleted_at')` in dashboard query | Soft delete filter |

#### TC-FEE-D-D13: Invoice balance_amount is GENERATED ALWAYS

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review DDL: `balance_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED` | Generated column |
| 2 | Note: This is a MySQL-specific feature — computed in real-time by the DB engine | MySQL specific |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/student-fee/dashboard` | `student-fee.dashboard` | `StudentFeeManagementController@dashboard` | `tenant.student-fee-management.viewAny` |
| GET | `/student-fee/dashboard/fee-collection-details` | `dashboard.fee-collection` | `StudentFeeManagementController@dashboardFeeCollection` | `tenant.student-fee-management.viewAny` |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-D01 | No caching — entire dashboard recomputed on every request | **Medium** | Every HTTP request re-queries assignments, transactions, invoices, scholarships, concessions, and chart data — performance degrades with data volume |
| KI-D02 | No pagination on KPI collections | **Low** | `defaulterStudents`, `scholarshipStudents`, and `concessionStudents` load full collections without pagination — view limits display but DB returns all rows |
| KI-D03 | Two separate queries for student IDs and fee sum | **Low** | The dashboard queries `FeeStudentAssignment` twice (once for `pluck('student_id')`, once for `sum('total_fee_amount')`) — could be combined into one query |
| KI-D04 | Single gate controls entire dashboard and all tabs | **Medium** | `tenant.student-fee-management.viewAny` is the only gate for the entire module — no granular permissions for dashboard vs configuration vs billing vs payment |
| KI-D05 | No date range or filter parameters | **Info** | Dashboard always reports for the entire current academic session — no way to view data for a custom date range or specific class/section |
| KI-D06 | Chart uses PHP loop with 6 separate DB queries | **Low** | The 6-month chart executes 6 individual `whereYear`/`whereMonth` sum queries — could be optimized to a single grouped query |
| KI-D07 | `balance_amount` is MySQL GENERATED ALWAYS column | **Info** | The `fee_invoices.balance_amount` column uses MySQL-specific `GENERATED ALWAYS AS ... STORED` syntax — not portable to other database drivers |
| KI-D08 | `defaulterStudents` and `topDefaulterInvoices` both query overdue invoices redundantly | **Low** | The defaulter count query (get()) and the top 5 query (limit 5) are separate DB queries on the same filtered dataset — could be combined |
| KI-D09 | No sorting on defaulterStudents collection | **Info** | The `defaulterStudents` collection has no explicit ordering (unlike `topDefaulterInvoices` which sorts by `balance_amount DESC`) |
| KI-D10 | FeeCollection view loads all enrolled students with classSection relation | **Low** | `StudentAcademicSession::with(['classSection.class', 'classSection.section', 'student.user'])` loads ALL enrolled students — could be paginated for large schools |

---

## 13. Feature Summary Matrix

| Feature | Controller Method | Key Models | Data Source |
|---------|-------------------|------------|-------------|
| Summary KPIs (7 cards) | `dashboard()` | FeeStudentAssignment, FeeTransaction, StudentAcademicSession | Sum/Count queries scoped to session |
| Defaulter Count | `dashboard()` | FeeInvoice | `where('status', 'Overdue')` via whereHas |
| Scholarship Count | `dashboard()` | FeeScholarshipApplication | `where('status', 'Approved')` |
| Concession Count | `dashboard()` | FeeStudentConcession | `where('approval_status', 'Approved')` |
| Recent 5 Transactions | `dashboard()` | FeeTransaction | `latest('payment_date')->limit(5)` |
| Top 5 Defaulter Invoices | `dashboard()` | FeeInvoice | `orderByDesc('balance_amount')->limit(5)` |
| 6-Month Collection Chart | `dashboard()` | FeeTransaction | PHP loop with whereYear/whereMonth sums |
| Fee Collection Detail | `dashboardFeeCollection()` | FeeStudentAssignment, FeeTransaction, StudentAcademicSession | Class-section grouping with per-student paid map |
