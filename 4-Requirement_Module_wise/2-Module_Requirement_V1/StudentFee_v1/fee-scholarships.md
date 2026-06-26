# Fee Scholarships — Requirements

## What It Does
Manages scholarship programs and student applications. Supports government, trust, and corporate scholarship funds with configurable eligibility criteria, application windows, fund tracking, and renewal rules. Multi-stage application workflow with review committee tracking and approval history.

Features:
- Scholarship catalog with fund source (Government, Trust, Corporate)
- Fund pool tracking (total fund, available fund, auto-deduct on approval)
- Eligibility criteria stored as JSON
- Application date windows
- Max amount per student cap
- Renewal support with renewal criteria
- Multi-stage application workflow: Draft → Submitted → Under Review → Approved/Rejected/Waitlisted
- Review committee tracking
- Approval history with stage-level audit
- Fund disbursement tracking
- Soft-delete with restore

## Database Fields

**fee_scholarships**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(50) | Required. Short code: `GOVT_MERIT`, `TRUST_NEED`, `CORP_SPORTS`, etc. |
| `name` | VARCHAR(200) | Required. Scholarship name. |
| `fund_source` | ENUM | `Government`, `Trust`, `Corporate`. |
| `sponsor_name` | VARCHAR(200) | Nullable. Sponsor organization name. |
| `total_fund_amount` | DECIMAL(14,2) | Required. Total fund allocated. |
| `available_fund` | DECIMAL(14,2) | Required. Remaining fund. Defaults to total_fund_amount on creation. |
| `eligibility_criteria` | JSON | Array of eligibility conditions. Cast to array. |
| `application_start_date` | DATE | Required. When applications open. |
| `application_end_date` | DATE | Required. When applications close. Must be after start. |
| `max_amount_per_student` | DECIMAL(12,2) | Required. Maximum scholarship amount per student. |
| `requires_renewal` | BOOLEAN | Default false. Whether application needs annual renewal. |
| `renewal_criteria` | JSON | Nullable. Conditions for renewal. Cast to array. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**fee_scholarship_applications**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `scholarship_id` | BIGINT UNSIGNED FK → `fee_scholarships` | Required. |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `academic_session_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `application_date` | DATE | Required. |
| `application_data` | JSON | Submitted form data. Cast to array. |
| `documents_submitted` | JSON | Array of uploaded document metadata. Cast to array. |
| `current_stage` | INTEGER | Current workflow stage number. |
| `status` | ENUM | `Draft`, `Submitted`, `Under Review`, `Approved`, `Rejected`, `Waitlisted`. |
| `review_committee` | JSON | Array of reviewer user IDs. Cast to array. |
| `approved_amount` | DECIMAL(12,2) | Nullable. Amount approved (set on approval). |
| `disbursed` | BOOLEAN | Default false. Whether amount has been disbursed. |
| `disbursed_date` | DATE | Nullable. When disbursed. |
| `remarks` | TEXT | Nullable. |

**fee_scholarship_approval_histories**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `application_id` | BIGINT UNSIGNED FK → `fee_scholarship_applications` | Required. |
| `stage` | INTEGER | Stage number when action was taken. |
| `action_by` | BIGINT UNSIGNED FK → `sys_users` | Who took the action. |
| `action` | ENUM | `Submit`, `Approve`, `Reject`, `Request Info`, `Waitlist`. |
| `comments` | TEXT | Nullable. Action comments. |
| `action_date` | DATETIME | When the action was taken. |

## Business Rules

**Application Status Workflow**
```
Draft → Submitted → Under Review → Approved (→ disbursed)
                         │               │
                         ▼               ▼
                     Waitlisted       Rejected
```
- `Draft`: Initial. Student fills application form.
- `Submitted`: Student submits. No further edits.
- `Under Review`: Committee is reviewing.
- `Approved`: Scholarship granted. `approved_amount` set. Fund deducted from pool.
- `Rejected`: Not approved. `rejection_reason` stored in approval history.
- `Waitlisted`: Put on hold (if fund becomes available later).

**Fund Pool Management**
- On scholarship creation: `available_fund = total_fund_amount`
- On application approval: `available_fund = available_fund - approved_amount`
- If `available_fund < max_amount_per_student`: no new approvals until fund replenished
- `hasSufficientFund()`: checks if fund allows approval of given amount
- `deductFund($amount)`: decrements available_fund on approval

**Duplicate Prevention**
- One application per `scholarship_id + student_id + academic_session_id`
- Creating a duplicate is blocked

**Eligibility Check**
- `eligibility_criteria` is a JSON array: `[{field: "min_percentage", value: 60}, {field: "family_income", value: 500000}]`
- Stored for display/info; runtime validation is manual (admin reviews application data)

**Approval History**
- Every action on an application creates an `FeeScholarshipApprovalHistory` record
- Tracks: stage number, who acted, what action, comments, timestamp
- `action_date` uses the `CREATED_AT` column (custom timestamp name)

**Disbursement**
- Only approved applications can be disbursed
- `disbursed = true`, `disbursed_date` set
- Disbursement marks the scholarship amount as paid to the student's fee account

## CRUD Operations

**List Scholarships**
- Filter by: fund_source, status (active/open for applications)
- Shows: code, name, fund source, total fund, available fund, dates, applications count

**Create Scholarship**
- Set: fund source, sponsor, total fund, dates, max amount per student
- Eligibility criteria: dynamic key-value rows parsed from textarea to JSON

**List Applications**
- Filter by: scholarship, status, student
- Shows: student, scholarship, status, stage, amount, disbursed

**Create Application**
- Select: scholarship (only active + open for applications), student, session
- Upload documents (document names stored in documents_submitted JSON)
- On create: status = Draft

**Submit Application**
- Status: Draft → Submitted
- Creates approval history: Submit action

**Approve Application**
- Validates: status must be Submitted/Under Review/Waitlisted
- Validates: approved_amount ≤ max_amount_per_student AND approved_amount ≤ available_fund
- Deducts fund, sets approved_amount, creates approval history

**Reject Application**
- Requires rejection reason
- Creates approval history

**Waitlist Application**
- From Submitted or Under Review status

**Disburse Scholarship**
- Only from Approved status
- Marks as disbursed with date

## Permissions

| Operation | Permission Key |
|---|---|
| View scholarships | `tenant.fee-scholarship.viewAny` |
| Manage scholarships | `tenant.fee-scholarship.*` |
| View applications | `tenant.fee-scholarship-application.viewAny` |
| Create / Manage applications | `tenant.fee-scholarship-application.*` |
