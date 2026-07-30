# Digital Access Requests — Business Requirements

## What This Screen Does

The Digital Access Requests screen lets the librarian manage member requests to view or download e-books and digital resources. When a member wants to access a digital resource through the Staff Library Portal, they submit a request specifying the book, the digital resource, and the request type (e.g., Download, View_Online, Extended/Renewal). The librarian reviews the request and either approves it (which creates a `lib_digital_access_transactions` record granting access for the duration defined by the member's membership type `digital_access_days`) or rejects it with a reason. Members can also withdraw their own pending requests. The screen performs extensive validation before approval, checking: resource availability, membership type compatibility, digital access days, download permissions per user type, access restrictions, member suspension status, concurrent request limits, and renewal eligibility. Notifications are sent to the member at each lifecycle event (submitted, withdrawn, approved, rejected) and when access is subsequently revoked.

---

## When This Screen Is Used

- When a member requests access to an e-book or digital resource through the portal — the request appears as "Pending"
- When the librarian wants to approve the request — an access transaction with a calculated expiry date is created
- When the librarian needs to reject a request — the member is notified with a reason
- When a member withdraws their own pending request — it shows as "Withdrawn"
- When reviewing the full lifecycle of access requests for audit purposes

## Default Data Load

The Digital Access Requests screen opens as a tab pane within the Library Operations hub page (`library.transactionsIndex`). When the `digital-access-requests` tab is active, the controller loads all requests with eager-loaded member, user, book, digital resource, and reviewer relationships, ordered by latest first, paginated at 15 per page (`digital_page` paginator name). Filters support search by member name, book title, or reason text, and status filter. The tab redirect preserves all query parameters.

---

---

## Key Fields at a Glance

**Request Identity**
Every request has a `member_id` (FK to `lib_members`), `book_id` (FK to `lib_books_master`), `digital_resource_id` (FK to `lib_digital_resources`), and `request_type` (FK to `lib_digital_access_request_types`). The `reason` field captures why the member needs access.

**Status and Review**
The `status` field is an FK to `lib_library_status_masters.id` for `Digital Access Request Status` — possible codes: 'pending', 'approved', 'rejected', 'withdrawn'. When reviewed, `reviewed_by_id` (FK to `sys_users`) and `reviewed_at` timestamp are recorded. The `notes` field stores librarian comments or rejection reasons.

**Lifecycle**
`is_active` boolean controls whether the request is considered active. Soft deletes are supported. The `created_at` timestamp is used for unique constraint enforcement — a member can only have one pending request per book at any time.

---

## Business Rules and Conditions

**Status Machine**
The status transitions from `pending` to one of three terminal states: `approved`, `rejected`, or `withdrawn`. Once in a terminal state, the status cannot be changed. The `LibDigitalAccessRequest` model implements `canWithdraw(): bool` which checks that the raw status equals the pending status ID. The setStatusAttribute accessor converts string status codes to their corresponding status master IDs automatically.

**Approval Validation Chain (Executed in order)**
1. Only pending requests can be approved or rejected
2. Resource must be active (`digitalResource.is_active` must be true)
3. Membership type must have `digital_access_days` > 0
4. Member must not be suspended (`member.is_suspended` must be false)
5. Member type download permission: maps `user.user_type` to `can_student_download`, `can_teacher_download`, or `can_staff_download`
6. Membership type `can_restricted_members_view_list` must be false (0 = allowed, 1 = blocked)
7. Book resource type must not be physical-only (`is_physical && !is_digital`) and the membership type must allow the resource type
8. Access restrictions: if the digital resource has any active `LibDigitalResourceAccessRestriction` records, the member must match at least one (by user_id, role_id, designation_id, or department_id)
9. Request type code must map to a valid access type via `mapRequestTypeToAccessType()` — 'Extended' returns null and requires separate renewal flow
10. `digital_resource_id` must not be null (DDL constraint on transactions table)
11. Unique constraint `uq_lib_daReq_member_book_status` prevents duplicate pending requests per member+book

**Approval Effects**
On approval, the system: creates a `LibDigitalAccessTransaction` with `access_type` derived from the request type code mapping, calculates `access_expires_at` as `now() + membershipType.digital_access_days`, updates the request status to 'approved' with reviewer and timestamp, updates the member's `last_activity_date`, updates the book master's `updated_at`, and logs `Access_Granted` in `LibTransactionHistory`. Notifications are sent to the member at each lifecycle event.

**Renewal (Extended) Requests**
If the request type code is 'Extended', the approval is blocked and a separate renewal flow is expected. On the store/create side, the FormRequest validates: `renewal_allowed` flag on membership type, `max_renewals` limit, and that an existing access transaction exists for this member+book.

---

## Workflow Steps

1. Member submits a digital access request through Staff Library Portal
2. The request appears in the Digital Access Requests tab with status "Pending"
3. Librarian reviews the member details, requested book, digital resource, and request type
4. Librarian clicks **Approve** — system runs the full validation chain:
   a. All pre-approval conditions are checked (resource active, member not suspended, download permissions, access restrictions, etc.)
   b. If validation passes, an access transaction is created with calculated expiry
   c. Member receives approval notification
   d. Request status changes to "Approved"
5. OR Librarian clicks **Reject** — enters a reason in a modal/notes field:
   a. Request status changes to "Rejected"
   b. Member receives rejection notification
6. OR Member withdraws their own request (from the portal):
   a. Request status changes to "Withdrawn"
   b. Member receives withdrawal confirmation notification
7. Soft-deleted requests appear in the Trash tab for restore or permanent delete

---

## Example Scenario

A Grade 10 student wants to download a PDF copy of "Chemistry: The Central Science" for offline study. The student submits a digital access request through the Staff Library Portal, selecting the Download request type. The librarian opens the Digital Access Requests tab, sees the pending request, and reviews it. The system checks: the digital resource is active, the student's membership type allows digital access (15 days), the student is not suspended, students are allowed to download this resource (`can_student_download = 1`), there are no access restrictions on this resource, and the student doesn't already have a pending request. The librarian approves it — the system creates an access transaction with a 15-day expiry and sends the student a notification with the access link. The student can now view and download the PDF for the next 15 days.

---

## Related Screens

- **Digital Resources** — The resources being requested
- **Digital Access Request Types** — Lookup defining the type of access requested
- **Digital Access Transactions** — Active access sessions created upon approval
- **Library Members** — Member records checked for suspension and membership type
- **Library Operations Hub** — Parent hub containing the Digital Access Requests tab

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibDigitalAccessRequestController`
**Model:** `Modules\Library\Models\LibDigitalAccessRequest` (table: `lib_digital_access_requests`)
**Request:** `LibDigitalAccessRequestRequest`
**Policy:** None — uses `Gate::authorize()` with string permissions
**Route:** Resource route `Route::resource('lib-digital-access-requests', LibDigitalAccessRequestController::class)` plus `trashed`, `restore`, `forceDelete`, `toggleStatus`, `approveRequest`, `rejectRequest`, `withdrawRequest`, `revokeTransaction`, `heartbeat`

Key controller methods:
- `index()` — Redirects to transaction hub with tab=digital-access-requests
- `create()` — Returns form with members, books, digital resources, request types
- `store(LibDigitalAccessRequestRequest)` — Validates (extensive withValidator including all pre-checks), creates request, sends notification
- `show($id)` — Shows request details with eager-loaded relations
- `edit($id)` — Returns edit form (uses view permission), allows notes/status changes
- `update(LibDigitalAccessRequestRequest, $id)` — Routes to approve/reject/withdraw/updateGeneral based on status field
- `destroy($id)` — Soft-deletes request, logs activity
- `trashed()` — Lists soft-deleted requests with relations, paginated 15
- `restore($id)` — Restores request, logs activity
- `forceDelete($id)` — Permanently deletes with FK exception handling (QueryException 23000)
- `toggleStatus($id)` — Toggles `is_active` via AJAX, permission: `tenant.lib-digital-access-requests.update`
- `approveRequest($id)` — Dedicated POST endpoint, status validation + full approval chain
- `rejectRequest($request, $id)` — Validates notes required, changes to rejected
- `withdrawRequest($id)` — Checks canWithdraw(), changes to withdrawn
- `revokeTransaction($id, $request)` — Revokes active transaction with reason, logs history
- `heartbeat($id, $request)` — Updates `total_view_duration_sec` and `last_accessed_at` for active viewing sessions

---

## Who Can Access

| Role | Permission | Access Level |
|---|---|---|
| Super Admin | `tenant.lib-digital-access-requests.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-digital-access-requests.*` | Full CRUD + approve/reject/revoke |
| Librarian | `tenant.lib-digital-access-requests.viewAny`, `.view`, `.create`, `.update` | View, process, and manage requests |
| Library Assistant | `tenant.lib-digital-access-requests.viewAny`, `.view` | Read-only access |

---

## How This Screen Works — Logic Flow (Non-Technical)

When a library member wants to access a digital resource, they submit a request through the student or staff portal. The request appears in the librarian's Digital Access Requests tab with a "Pending" label. The librarian reviews the request — they can see who the member is, what book and digital resource they want, what type of access (download or just view), and why they need it. The librarian clicks Approve if everything looks right, and the system automatically: checks that the resource is still available, confirms the member's library membership allows digital access, makes sure the member isn't suspended, verifies the member's role (student/teacher/staff) has download permission, and checks that no access restrictions block this specific member. If all checks pass, the system grants access for a set number of days (based on the membership type), creates an active transaction record, and notifies the member. If any check fails, the approval is blocked with a specific error message. The librarian can also reject the request with a reason, or the member can withdraw their own request. Once approved, the access is tracked in the Digital Access Transactions tab.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|---|---|---|
| 1 | member_id | Required, integer, exists:lib_members,id | Please select a library member. |
| 2 | book_id | Required, integer, exists:lib_books_master,id | Please select a book. |
| 3 | digital_resource_id | Required, integer, exists:lib_digital_resources,id | Selected digital resource is invalid. |
| 4 | request_type | Required, integer, exists:lib_digital_access_request_types,id | Please select a request type. |
| 5 | reason | Nullable, string, max:1000 | Reason must not exceed 1000 characters. |
| 6 | is_active | Nullable, boolean | Active status must be true or false. |
| 7 | status | Required on PUT/PATCH, integer, exists:lib_library_status_masters,id | Invalid status. |
| 8 | notes | Nullable on PUT/PATCH, string, max:1000 | Notes must not exceed 1000 characters. |

**Custom After-Validation Rules (store only):**
- Physical-only books cannot have digital access requests
- Membership type must have `digital_access_days` > 0
- Member must not be suspended
- Member type must not have `can_restricted_members_view_list` enabled
- Digital resource must be active
- User type must have download permission (`can_student_download`, `can_teacher_download`, or `can_staff_download`)
- Access restrictions (if any) must include the member
- No duplicate pending requests for same member+book
- Extended (renewal) requests: must have `renewal_allowed`, within `max_renewals`, and must have existing access

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|---|---|---|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Approve — resource inactive | Cannot approve: digital resource is no longer available. | 422 (redirect) |
| Approve — digital_access_days is 0 | Cannot approve: digital_access_days is 0 for this membership type. | 422 (redirect) |
| Approve — member suspended | Cannot approve: member is suspended. | 422 (redirect) |
| Approve — download not allowed | Cannot approve: member type does not have permission to access this resource. | 422 (redirect) |
| Approve — restricted | Cannot approve: member is restricted from accessing this digital resource. | 422 (redirect) |
| Approve — physical-only book | Cannot approve: book is a physical-only resource. | 422 (redirect) |
| Approve — not pending | Only pending requests can be approved. | 422 (redirect) |
| Approve — invalid access type | Cannot approve: invalid access type resolved from request type. | 422 (redirect) |
| Reject — not pending | Only pending requests can be rejected. | 422 (redirect) |
| Withdraw — not pending | Only pending requests can be withdrawn. | 422 (redirect) |
| Force delete — FK constraint | Cannot delete this record: it is referenced by other records. | 422 (redirect) |
| Already has pending request | You already have a pending request for this book. | 422 |
| Model not found | No query results for model [LibDigitalAccessRequest] | 404 |

---

## Success Scenarios

**SC-001: Approve a pending download request**
1. Librarian opens a pending request for student "John Doe" wanting to download "Advanced Calculus"
2. System validates all conditions (resource active, membership valid, download allowed)
3. Librarian clicks Approve
4. System creates `LibDigitalAccessTransaction` with access_type='Download', expiry = now + membership.digital_access_days
5. Request status updated to 'approved', reviewed_by_id and reviewed_at set
6. LibTransactionHistory records 'Access_Granted'
7. Notification sent to member: "Your digital access request has been approved."
8. Success flash: "Digital access request approved. Access transaction created."

**SC-002: Reject a request with reason**
1. Librarian opens a pending request but notices the member has overdue fines
2. Librarian enters reason "Please clear outstanding fines before requesting digital access" and clicks Reject
3. Request status updated to 'rejected', reviewed_by_id and reviewed_at set
4. Notification sent to member with the rejection reason
5. Success flash: "Digital access request rejected."

**SC-003: Member withdraws pending request**
1. Member clicks Withdraw on their pending request via the portal
2. Controller checks `canWithdraw()` returns true
3. Request status updated to 'withdrawn'
4. Notification sent confirming withdrawal
5. Success flash: "Digital access request withdrawn."

---

## Failure Scenarios

**FC-001: Approve -> member suspended**
1. Librarian tries to approve a request for a member who has been suspended
2. Controller checks `$member->is_suspended` → true
3. Approval blocked with error: "Cannot approve: member is suspended."
4. Request remains in pending state

**FC-002: Approve -> no digital_access_days**
1. Librarian tries to approve for a membership type that has `digital_access_days` set to 0
2. Controller blocks with error: "Cannot approve: digital_access_days is 0 for this membership type."
3. Librarian must upgrade the member's membership type or contact admin

**FC-003: Force delete with existing transactions**
1. User navigates to trash and clicks force-delete on a request that has linked transactions
2. Database throws `QueryException` with code 23000
3. Controller catches the exception and redirects with error: "Cannot delete this record: it is referenced by other records."

---

## Dependencies module and tables

| Type | Name | Details |
|---|---|---|
| Table | lib_digital_access_requests | Main requests table with FK to member, book, digital resource, request type, status master |
| Table | lib_digital_access_transactions | Created on approval, FK: access_request_id |
| Table | lib_digital_access_request_types | Lookup for request type codes (Download, View_Online, etc.) |
| Table | lib_digital_resources | The digital resource being requested |
| Table | lib_books_master | Parent book record |
| Table | lib_members | Member making the request |
| Table | lib_membership_types | Defines digital_access_days, download permission flags |
| Table | lib_library_status_masters | Dynamic status for request lifecycle |
| Table | lib_digital_resource_access_restrictions | Pre-approval access restriction checks |
| Table | lib_transaction_history | Audit trail for access grants and revocations |
| Table | sys_users | Reviewer tracking |
| Module | Library Operations Hub | Parent hub containing Digital Access Requests tab |
| Module | Library Digital Resources | Consumed resources |
| Module | Notifications | Sends lifecycle notification events |
