# Withdrawals & Refund — Requirements

## What It Does
Record withdrawal of applications or enrolled students. Compute refund eligibility based on cycle refund policy, track refund status through finance approval pipeline, and handle post-enrollment withdrawal (disabling student accounts).

## Database Fields

### `adm_withdrawals`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `application_id` | BIGINT UNSIGNED | FK → `adm_applications.id`. |
| `allotment_id` | BIGINT UNSIGNED | Nullable FK → `adm_allotments.id`. Set if withdrawn after allotment. |
| `withdrawal_date` | DATE | Required. |
| `reason` | ENUM('Personal','Financial','Relocation','School_Change','Medical','Other') | Required. |
| `remarks` | TEXT | Nullable. |
| `fee_paid_amount` | DECIMAL(10,2) | Default `0.00`. Total fees paid. |
| `refund_eligible_amount` | DECIMAL(10,2) | Default `0.00`. Computed per refund policy. |
| `refund_status` | ENUM('Not_Eligible','Pending','Approved','Paid') | Default `'Not_Eligible'`. |
| `refund_processed_at` | DATE | Nullable. |
| `processed_by` | INT UNSIGNED | Nullable FK → `sys_users.id`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Refund Lifecycle (FSM)

```
Not_Eligible (no fee paid or beyond refund window)
Pending (fee paid, within window) → Approved (finance ok) → Paid (disbursed)
                                 → Not_Eligible (beyond refund window)
```

## Business Rules

**Application Fee Non-Refundable (BR-ADM-006)**
- Application fee is non-refundable by default.
- Refund policy per cycle may override for admission fee (not application fee).

**Refund Computation**
- `refund_eligible_amount` computed at withdrawal time by `AdmissionPipelineService::withdrawApplication()`.
- Refund % determined from `adm_admission_cycles.refund_policy_json`:
  ```json
  {
    "tiers": [
      {"days": 7, "percent": 100},
      {"days": 30, "percent": 50}
    ]
  }
  ```
- Days calculated from fee payment date to withdrawal date.

**Pre-Enrollment Withdrawal**
- Application status updated to `Withdrawn`.
- `adm_application_stages` logged with from_status and reason.
- Allotment (if exists) marked `Withdrawn`.
- Refund computed per policy.

**Post-Enrollment Withdrawal (Enrolled Student)**
- `EnrollmentService::withdraw()`:
  - Closes `std_student_academic_sessions` (`session_status_id → Withdrawn`, `is_current = 0`).
  - Disables `sys_users.is_active = 0`.
  - Student record preserved for history.
- Refund for enrolled students processed separately (not via `refund_policy_json`).

**State Validation**
- Application must not already be `Withdrawn` or `Enrolled` (for pre-enrollment).
- Allotment must not already be `Withdrawn`.

## CRUD Operations

**Create (Withdrawal Request)**
- Route: `POST /admission/applications/{application}/withdraw` → reason, withdrawal_date → system computes refund eligibility
- Application status → Withdrawn; allotment → Withdrawn if exists

**List**
- Route: `GET /admission/withdrawals` → filterable table (by refund_status, date range, reason)

**View**
- Route: `GET /admission/withdrawals/{withdrawal}` → detail with refund computation breakdown

**Update Refund Status**
- Route: `PATCH /admission/withdrawals/{withdrawal}/refund` → update refund_status (Pending → Approved → Paid)
- Only finance staff with `tenant.adm.refund.process` permission

**Delete (Soft)**
- Route: `DELETE /admission/withdrawals/{withdrawal}` → completed withdrawals cannot be deleted

## Permissions

| Operation | Permission Key |
|---|---|
| View withdrawals tab | `tenant.adm.application.viewAny` |
| Create withdrawal | `tenant.adm.application.update` |
| Process refund | `tenant.adm.refund.process` |
