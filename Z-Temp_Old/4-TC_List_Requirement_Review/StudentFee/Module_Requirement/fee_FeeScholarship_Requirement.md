# Fee Scholarship — Business Requirements

## What This Screen Does

The Fee Scholarship screen manages scholarship programs and fund definitions. Supports government, private, NGO, school fund, donor, and other fund sources with configurable eligibility criteria, application windows, fund tracking, and renewal rules. Each scholarship tracks total fund allocation and available balance with auto-deduction on approval.

---

## When This Screen Is Used

- **Scholarship Program Setup** when an admin defines a new merit-based or need-based scholarship
- **Fund Management** when tracking how much scholarship fund has been allocated and disbursed
- **Application Window Configuration** when setting the start and end dates for accepting applications
- **Renewal Criteria Setup** when configuring annual renewal requirements for multi-year scholarships

## Default Data Load

This screen displays within the Scholarship tab group. `StudentFeeManagementController@scholarship()` gates `tenant.student-fee-management.viewAny` and loads: `FeeScholarship::withCount('applications')` paginated at 15 per page, `FeeScholarshipApplication::with(['scholarship', 'student.user', 'academicSession'])` paginated at 15 per page, and `FeeScholarshipApprovalHistory::with(['application.scholarship', 'actionBy'])` paginated at 15 per page. All three grids are filterable independently.

---

## Key Fields at a Glance

**Scholarship Identity**
`code` — unique short code like `GOVT_MERIT`, `TRUST_NEED`. `name` — display name. `fund_source` — one of: Government, Private, NGO, School Fund, Donor, Other. `sponsor_name` — optional sponsor organization.

**Fund Tracking**
`total_fund_amount` — total allocated budget. `available_fund` — remaining balance (defaults to total_fund_amount on creation). `max_amount_per_student` — per-student cap.

**Application Window**
`application_start_date` and `application_end_date` define when applications can be submitted. `scopeOpenForApplication()` filters scholarships currently accepting applications.

**Eligibility & Renewal**
`eligibility_criteria` — JSON array of criteria (stored as textarea parsed by newlines into array). `requires_renewal` — boolean for multi-year scholarships. `renewal_criteria` — JSON array for renewal conditions.

---

## Business Rules and Conditions

**Fund Pool Management**
- On creation: `available_fund` defaults to `total_fund_amount`
- On application approval: `available_fund = available_fund - approved_amount`
- `hasSufficientFund($amount)`: checks if fund allows approval of given amount (if available_fund is null, always sufficient)
- `deductFund($amount)`: decrements available_fund on approval (null-safe)

**Application Window**
- `scopeOpenForApplication()`: active scholarships where current date falls between start_date and end_date (or where dates are null)
- `isApplicationOpen()`: per-instance check including is_active status

**Delete Protection**
- Scholarships with existing applications cannot be deleted. Error: "Cannot delete scholarship with existing applications."
- Soft delete only; force delete available from trash

**Code Handling**
- `code` is stored in uppercase via `strtoupper()` in store/update
- Unique constraint on `code` at DB level

---

## Workflow Steps

**Creating a Scholarship**
Admin selects fund source, enters code/name, sets total fund amount (available fund auto-populates), defines eligibility criteria as textarea (each line becomes a criteria item), sets application window dates, optionally sets max amount per student, and configures renewal.

**Editing a Scholarship**
Admin updates any field. Code is uppercased. Eligibility and renewal criteria are re-parsed from textarea lines.

**Deleting a Scholarship**
If no applications exist, the scholarship is deactivated (is_active=false) and soft-deleted. If applications exist, deletion is blocked.

---

## Example Scenario

A school launches a "Merit Scholarship 2025-26" funded by a corporate donor with a ₹5,00,000 total fund. Eligibility criteria: "Minimum 85% in previous class" and "Family income below ₹3,00,000". Max per student: ₹25,000. Applications open from 1st April to 30th June. The scholarship requires annual renewal with "Must maintain 80% in current class" as renewal criteria.

---

## Related Screens

- **Scholarship Applications** — Student applications linked to each scholarship
- **Scholarship Approval History** — Workflow audit trail for applications
- **Dashboard** — Scholarship student count on fee dashboard

---

## Requirements

- Controller `FeeScholarshipController`; `index()` redirects to `student-fee.scholarship` tab; gate `tenant.fee-scholarship.view`
- `store()` validates via `StoreFeeScholarshipRequest`, uses DB transaction, uppercases code, parses eligibility_criteria and renewal_criteria from textarea to array
- `update()` validates via `UpdateFeeScholarshipRequest`, DB transaction
- `destroy()` checks `$feeScholarship->applications()->exists()`, blocks with error if true, otherwise deactivates and soft-deletes
- `show()` uses `withCount('applications')`
- `trashedScholarships()` lists soft-deleted only, paginated at 15
- `restore()` restores with activity log
- `forceDelete()` permanently deletes
- `toggleStatus()` flips is_active, returns JSON `{success, is_active, message}`
- Fund sources passed to view: `['Government', 'Private', 'NGO', 'School Fund', 'Donor', 'Other']`

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.fee-scholarship.view` | `index()`, `show()` | Page load + view |
| `tenant.fee-scholarship.create` | `create()`, `store()` | Create form + submit |
| `tenant.fee-scholarship.update` | `edit()`, `update()` | Edit form + submit |
| `tenant.fee-scholarship.delete` | `destroy()` | Soft delete |
| `tenant.fee-scholarship.restore` | `trashedScholarships()`, `restore()` | Trash view + restore |
| `tenant.fee-scholarship.forceDelete` | `forceDelete()` | Permanent delete |
| `tenant.fee-scholarship.status` | `toggleStatus()` | Toggle active/inactive |

## Logic Flow

1. **Page Load** — Scholarship tab loads scholarship list (with applications count), application list, and approval history. All three paginated and independently filterable.
2. **Create** — `create()` passes fund sources. `store()` validates, wraps in DB transaction. Code uppercased. Eligibility criteria textarea split by newline, empty lines filtered, trimmed. Available_fund defaults to total_fund_amount.
3. **Edit** — `edit()` loads scholarship with fund sources. `update()` same parsing logic as store.
4. **Delete** — `destroy()` checks applications existence, blocks if any exist. Otherwise deactivates + soft-deletes.
5. **Restore** — `restore()` nullifies deleted_at. No automatic is_active reactivation (unlike fine rules).

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | `required, string, max:50, unique:fee_scholarships,code` | — |
| `name` | `required, string, max:150` | — |
| `fund_source` | `required, string, max:100` | — |
| `sponsor_name` | `nullable, string, max:150` | — |
| `total_fund_amount` | `nullable, numeric, min:0` | — |
| `available_fund` | `nullable, numeric, min:0` | — |
| `application_start_date` | `nullable, date` | — |
| `application_end_date` | `nullable, date, after_or_equal:application_start_date` | — |
| `max_amount_per_student` | `nullable, numeric, min:0` | — |
| `requires_renewal` | `nullable, boolean` | — |
| `eligibility_criteria` | `nullable, string` | — |
| `renewal_criteria` | `nullable, string` | — |
| `is_active` | `nullable, boolean` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Delete with existing applications | "Cannot delete scholarship with existing applications." | Controller |
| System error during create/update | `$e->getMessage()` | System error |
| Trash scholarship | "Fee Scholarship moved to trash." | Flash |
| Restore scholarship | "Scholarship restored." | Flash |
| Force delete | "Scholarship permanently deleted." | Flash |

## Success Scenarios

**SC-001 — Creating a Scholarship**
Admin creates scholarship with code "MERIT25", name "Merit Scholarship 2025", fund_source "Government", total_fund_amount 500000, available_fund 500000, eligibility criteria as textarea lines. System saves with uppercased code and parsed criteria array.

**SC-002 — Editing Scholarship With New Dates**
Admin updates application_end_date from 30th June to 31st July. Validation ensures end_date >= start_date.

**SC-003 — Toggle Scholarship Status**
Admin toggles scholarship inactive. System returns JSON success.

## Failure Scenarios

**FC-001 — Delete Scholarship With Applications**
Admin tries to delete a scholarship that has existing applications. System returns error: "Cannot delete scholarship with existing applications."

**FC-002 — Duplicate Code**
Admin creates scholarship with existing code "MERIT25". Unique validation fails.

**FC-003 — End Date Before Start Date**
Admin sets application_end_date before application_start_date. Validation rule `after_or_equal:application_start_date` fails.

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_scholarships` | Main Table | All CRUD on this table |
| `fee_scholarship_applications` | Child Table | Blocks delete if exists |
| `sys_dropdown_table` | Future Reference | Fund source standardization |
