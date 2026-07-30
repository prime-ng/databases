# Fee Scholarship Application — Business Requirements

## What This Screen Does

The Fee Scholarship Application screen manages student applications for scholarships. It supports a multi-stage workflow from Draft → Submitted → Under Review → Approved/Rejected/Waitlisted → Disbursed. Each application tracks scholarship, student, academic session, application data, submitted documents, and approval history.

---

## When This Screen Is Used

- **Student Application Submission** when a student applies for a scholarship through the system
- **Approval Processing** when the scholarship committee reviews and approves/rejects applications
- **Fund Disbursement** when approved scholarship amounts are disbursed to student accounts
- **Waitlist Management** when putting applications on hold pending fund availability

## Default Data Load

This screen displays within the Scholarship tab group alongside the Scholarship master list. `StudentFeeManagementController@scholarship()` gates `tenant.student-fee-management.viewAny` and loads applications paginated at 15 per page with scholarship, student, and academic session relations. Filterable by search (student/scholarship name) and status.

---

## Key Fields at a Glance

**Application Identity**
Linked to `scholarship_id` (FK → `fee_scholarships`), `student_id` (FK → `std_students`), `academic_session_id` (FK → `sch_org_academic_sessions_jnt`). `application_date` records submission date.

**Application Data**
`application_data` — JSON storing form responses to eligibility criteria. `documents_submitted` — JSON array of uploaded document metadata. `current_stage` — numeric workflow stage.

**Status Workflow**
Six statuses: `Draft`, `Submitted`, `Under Review`, `Approved`, `Rejected`, `Waitlisted`. `approved_amount` set on approval. `disbursed` boolean + `disbursed_date` when fund is released.

**Approval History**
Stored in `fee_scholarship_approval_history` table with action type (Submit/Approve/Reject/Request Info/Waitlist), action_by, comments, and action_date.

---

## Business Rules and Conditions

**Duplicate Prevention**
One application per `(scholarship_id, student_id, academic_session_id)` combination. Creating a duplicate returns error: "This student already has an application for this scholarship in the selected session."

**Status Workflow**
```
Draft → Submitted → Under Review → Approved (→ disbursed)
                         │               │
                         ▼               ▼
                     Waitlisted       Rejected
```
- **Draft**: Initial state on create. Can be submitted.
- **Submitted**: Application sent for review. Cannot be edited.
- **Under Review**: Committee reviewing. 
- **Approved**: Scholarship granted. `approved_amount` set. Fund deducted from pool.
- **Rejected**: Denied with `rejection_reason`.
- **Waitlisted**: On hold for future funds.

**Submit Rules**
- Only Draft applications can be submitted. Error: "Only Draft applications can be submitted."

**Approve Rules**
- Only Submitted or Under Review applications can be approved. Error: "Application cannot be approved in its current status."
- `approved_amount` must be ≤ `max_amount_per_student`. Error: "Amount exceeds the per-student maximum for this scholarship."
- `approved_amount` must be ≤ `available_fund`. Error: "Insufficient available fund in this scholarship."
- Requires `approved_amount` (required, numeric, min:0.01)

**Reject Rules**
- Submitted, Under Review, or Waitlisted applications can be rejected. Error: "Application cannot be rejected in its current status."
- Requires `rejection_reason` (required, string, max:500)

**Waitlist Rules**
- Only Submitted or Under Review applications can be waitlisted. Error: "Application cannot be waitlisted in its current status."

**Disburse Rules**
- Only Approved applications can be disbursed. Error: "Only approved applications can be marked as disbursed."
- Already disbursed applications cannot be disbursed again. Error: "Application is already disbursed."

**Fund Deduction**
On approval: `$scholarship->deductFund($approved_amount)` decrements available_fund.

---

## Workflow Steps

**Creating an Application**
Admin selects scholarship (only active + open for applications), student, academic session, enters application data, and submits. System checks duplicate (scholarship_id + student_id + session_id) and creates as Draft.

**Submitting an Application**
Draft application is submitted. Status changes to Submitted. Approval history records "Submit" action.

**Approving an Application**
Admin enters approved_amount and comments. System validates status (Submitted/Under Review), checks amount against max_per_student and available_fund, deducts fund, sets status to Approved.

**Rejecting an Application**
Admin enters rejection_reason (required). System validates status (Submitted/Under Review/Waitlisted), sets status to Rejected.

**Waitlisting an Application**
Admin enters optional comments. System sets status to Waitlisted.

**Disbursing an Application**
Only from Approved status. Sets disbursed=true and disbursed_date.

---

## Example Scenario

A student applies for the "Merit Scholarship 2025-26". The application is created as Draft. After reviewing, the admin submits it (→ Submitted). The committee reviews and approves ₹20,000 (→ Approved). The available fund is deducted from ₹5,00,000 to ₹4,80,000. Later, the finance team marks it as disbursed (→ Disbursed). Each action is recorded in the approval history table.

---

## Related Screens

- **Fee Scholarship** — Scholarship master data including fund sources and eligibility criteria
- **Fee Transaction** — Disbursed amounts may be linked to fee payments
- **Dashboard** — Approved scholarship student count

---

## Requirements

- Controller `FeeScholarshipApplicationController` with `FeeScholarshipService` DI
- `index()` redirects to `student-fee.scholarship` tab; gate `tenant.fee-scholarship-application.view`
- Resource routes limited to `only: ['index', 'create', 'store', 'show']`
- Custom action routes: submit, approve, reject, waitlist, disburse (all POST)
- `create()` loads active scholarships open for application, all students, all academic sessions
- `store()` validates via `StoreFeeScholarshipApplicationRequest`, checks duplicate, delegates to `FeeScholarshipService::createApplication()` which creates as Draft in DB transaction
- `show()` loads with scholarship, student.user, academicSession, approvalHistories.actionBy
- `submit()` gates `tenant.fee-scholarship-application.update`, delegates to service
- `approve()` gates `tenant.fee-scholarship-application.approve`, validates via `ApproveFeeScholarshipApplicationRequest` (approved_amount required), delegates to service
- `reject()` gates `tenant.fee-scholarship-application.approve`, validates via `RejectFeeScholarshipApplicationRequest` (rejection_reason required), delegates to service
- `waitlist()` gates `tenant.fee-scholarship-application.approve`, delegates to service
- `disburse()` gates `tenant.fee-scholarship-application.approve`, delegates to service

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.fee-scholarship-application.view` | `index()`, `show()` | Page load + view |
| `tenant.fee-scholarship-application.create` | `create()`, `store()` | Create form + submit |
| `tenant.fee-scholarship-application.update` | `submit()` | Submit draft |
| `tenant.fee-scholarship-application.approve` | `approve()`, `reject()`, `waitlist()`, `disburse()` | All workflow actions |

## Logic Flow

1. **Create** — `create()` loads active/open scholarships, students, academic sessions. `store()` validates, checks duplicate, calls service `createApplication()` which uses DB transaction and creates as Draft status.
2. **Submit** — `submit()` validates status is Draft via DomainException. Creates approval history with Submit action.
3. **Approve** — `approve()` validates status (Submitted/Under Review), amount vs max_per_student, amount vs available_fund. Deducts fund, sets Approved status, creates approval history.
4. **Reject** — `reject()` validates status (Submitted/Under Review/Waitlisted). Sets Rejected, creates approval history.
5. **Waitlist** — `waitlist()` validates status (Submitted/Under Review). Sets Waitlisted, creates approval history.
6. **Disburse** — `disburse()` validates status Approved and not already disbursed. Sets disbursed=true and disbursed_date.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `scholarship_id` | `required, integer, exists:fee_scholarships,id` | — |
| `student_id` | `required, integer, exists:std_students,id` | — |
| `academic_session_id` | `required, integer` | — |
| `application_date` | `required, date` | — |
| `application_data` | `nullable, string` | — |
| `remarks` | `nullable, string, max:1000` | — |
| **Approve** — `approved_amount` | `required, numeric, min:0.01` | — |
| **Approve** — `comments` | `nullable, string, max:500` | — |
| **Reject** — `rejection_reason` | `required, string, max:500` | — |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate application | "This student already has an application for this scholarship in the selected session." | Validation |
| Submit non-Draft | "Only Draft applications can be submitted." | DomainException |
| Approve invalid status | "Application cannot be approved in its current status." | DomainException |
| Amount exceeds max per student | "Amount exceeds the per-student maximum for this scholarship." | DomainException |
| Insufficient fund | "Insufficient available fund in this scholarship." | DomainException |
| Reject invalid status | "Application cannot be rejected in its current status." | DomainException |
| Waitlist invalid status | "Application cannot be waitlisted in its current status." | DomainException |
| Disburse non-Approved | "Only approved applications can be marked as dispersed." | DomainException |
| Disburse already done | "Application is already dispersed." | DomainException |

## Success Scenarios

**SC-001 — Creating and Submitting an Application**
Admin creates application for student "John Doe" to scholarship "Merit 2025" in session "2025-26" with application_data notes. Created as Draft. Then submits it → status = Submitted.

**SC-002 — Full Approval Workflow**
Application created → submitted → approved with ₹20,000 → fund deducted → disbursed. All approval history records created.

**SC-003 — Rejection With Reason**
Application submitted → rejected with reason "Insufficient academic performance". Status set to Rejected. Approval history created.

**SC-004 — Waitlist and Later Approval**
Application submitted → waitlisted → (later) approved when fund becomes available. All actions recorded in history.

## Failure Scenarios

**FC-001 — Duplicate Application**
Admin tries to create second application for same student+scholarship+session. Error: "This student already has an application for this scholarship in the selected session."

**FC-002 — Approve Without Sufficient Fund**
Admin approves amount ₹6,00,000 when only ₹5,00,000 available. Error: "Insufficient available fund in this scholarship."

**FC-003 — Disburse Already Disbursed Application**
Admin tries to disburse an already disbursed application. Error: "Application is already dispersed."

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_scholarship_applications` | Main Table | All CRUD + workflow |
| `fee_scholarship_approval_history` | Child Table | Approval audit trail |
| `fee_scholarships` | FK Table | `scholarship_id` FK RESTRICT |
| `std_students` | FK Table | `student_id` FK RESTRICT |
| `sch_org_academic_sessions_jnt` | FK Table | `academic_session_id` FK RESTRICT |
| `sys_users` | FK Table | `action_by` FK RESTRICT |
| `FeeScholarshipService` | Service | Business logic for all workflow actions |
