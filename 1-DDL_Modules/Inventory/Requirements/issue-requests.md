# Issue Requests — Requirements

## What It Does
Manages departmental stock issue requests. Department staff submit requests for stock items, which go through an approval workflow (Submitted → Approved → Issued/Partial → Rejected). Once approved, the request is fulfilled by the Stock Issue execution process. Supports partial fulfillment, department-level consumption tracking, and auto-generated request numbers.

## Database Fields

### inv_issue_requests

| Field | Type | Conditions |
|---|---|---|
| id | BIGINT UNSIGNED PK | Auto-increment |
| equest_number | VARCHAR(50) | Required. Unique. Auto-generated: IR-{YEAR}-{SEQUENCE}. |
| equested_by | BIGINT UNSIGNED FK → sys_users | Required. The user who created the request. |
| department_id | INT UNSIGNED FK → sch_department | Required. INT UNSIGNED to match sch_department.id. |
| equired_date | DATE | Required. Date by which items are needed. |
| status | ENUM('submitted','approved','issued','partial','rejected') | Default 'submitted'. |
| pproved_by | BIGINT UNSIGNED FK → sys_users | Nullable. Set on approval. |
| emarks | TEXT | Nullable. General notes or rejection reason. |
| is_active | TINYINT(1) | Default 1. |
| deleted_at | TIMESTAMP | Nullable. Soft delete marker. |
| created_at / updated_at | TIMESTAMP | Laravel standard. |

### inv_issue_request_items

| Field | Type | Conditions |
|---|---|---|
| id | BIGINT UNSIGNED PK | Auto-increment |
| issue_request_id | BIGINT UNSIGNED FK → inv_issue_requests | Required. ON DELETE CASCADE. |
| item_id | BIGINT UNSIGNED FK → inv_stock_items | Required. |
| equested_qty | DECIMAL(15,3) | Required. Quantity requested. Must be > 0. |
| issued_qty | DECIMAL(15,3) | Default 0. Auto-updated by StockIssueService. NOT user-editable. |
| uom_id | BIGINT UNSIGNED FK → inv_units_of_measure | Required. |
| is_active | TINYINT(1) | Default 1. |
| deleted_at | TIMESTAMP | Nullable. Soft delete marker. |
| created_at / updated_at | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| equest_number | Required, string, max:50, unique | Auto-generated. Never user-provided. "The request number has already been taken." |
| equested_by | Required, integer, exists:sys_users,id | Auto-set to auth user on create. Cannot be changed. |
| department_id | Required, integer, exists:sch_department,id | "The selected department is invalid." Must reference an existing active department. |
| equired_date | Required, date | "The required date is required." Cannot be in the past. Must be today or a future date. |
| status | Required, enum | Set by state machine transitions only. Default 'submitted'. |
| pproved_by | Read-only (system-set) | Set on approve action only. |
| emarks | Nullable, string, max:5000 | Required on reject action: "Rejection reason is required." On create/approve, optional. |
| equested_qty (item line) | Required, numeric, gt:0 | "The requested quantity must be greater than 0." |
| issued_qty (item line) | Read-only (system-updated) | Auto-updated by StockIssueService. Never user-input. If attempted: "Issued quantity is auto-updated from stock issue execution and cannot be manually set." |
| item_id (item line) | Required, integer, exists:inv_stock_items,id | "The selected item is invalid." Must reference an active stock item. |
| uom_id (item line) | Required, integer, exists:inv_units_of_measure,id | "The selected unit of measure is invalid." Must reference an active UOM. |

### Entity-Specific Rules / Lifecycle State Machine

**Full Status Lifecycle:**
`
[Submitted] ──approve()──→ [Approved] ──executeIssue()──→ [Issued]
      │                          │
  reject()                partialIssue()
      │                          │
[Rejected]              [Partial] ──completeIssue()──→ [Issued]

Note: Stock Issue Service (inv_stock_issues) is the execution layer.
Issue Request tracks the request status; Stock Issue tracks fulfillment.
`

**State Transition Details:**

**1. Submitted → Approved (pprove()):**
- **Guard (approver has permission):** Auth user must have inventory.issue-request.approve permission. Error: "You do not have permission to approve issue requests." (403 response).
- **Guard (at least 1 line item):** The request must have at least one inv_issue_request_items record. Error: "Cannot approve an issue request with no items."
- **Guard (all requested_qty > 0):** Every line item's equested_qty must be > 0. Error: "Line item #{line_number}: Requested quantity must be greater than 0."
- **Guard (status is 'submitted'):** Error: "Cannot approve an issue request with status '{current_status}'. Only submitted requests can be approved."
- **Action:** Sets status = 'approved', pproved_by = auth()->id().

**2. Submitted → Rejected (eject()):**
- **Guard (remarks required):** Rejection must include a reason. Error: "Rejection reason is required."
- **Guard (status is 'submitted'):** Error: "Cannot reject an issue request with status '{current_status}'. Only submitted requests can be rejected."
- **Action:** Sets status = 'rejected', pproved_by = auth()->id() (the reviewer). The emarks field stores the rejection reason.
- **Side effect:** Notification sent to the requester: "Your issue request #{request_number} has been rejected. Reason: {remarks}."

**3. Approved → Issued (executeIssue() — triggered by StockIssueService):**
- **Guard (status is 'approved'):** Error: "Cannot issue stock for a request with status '{current_status}'. Only approved requests can be issued."
- **Guard (stock availability — BR-INV-003):** For each line item, inv_stock_balances.current_qty >= requested_qty - issued_qty in the source godown. Error: "Insufficient stock for item {item_name}. Available: {available}, Requested: {requested}."
- **Action (by StockIssueService during stock issue execution):**
  1. Creates inv_stock_issues (header) and inv_stock_issue_items (lines).
  2. Creates outward inv_stock_entries.
  3. Deducts inv_stock_balances.current_qty.
  4. Updates inv_issue_request_items.issued_qty for each line.
  5. If ALL items fully issued: sets issue request status to 'issued'.
  6. Fires StockIssued event → Accounting creates Stock Journal Voucher.
- This transition is NOT called directly on the Issue Request controller — it is a side effect of StockIssueService::executeIssue().

**4. Approved → Partial (partialIssue() — triggered by StockIssueService):**
- This transition occurs when StockIssueService issues some (but not all) of the requested quantity.
- **Guard (status is 'approved'):** Error: "Cannot partially issue stock for a request with status '{current_status}'."
- **Trigger condition:** At least one line item has issued_qty < requested_qty, and at least one item has issued_qty > 0.
- **Action:** Sets issue request status to 'partial'.
- **Side effect:** A follow-up stock issue can be executed against the same issue request (for the remaining quantities).

**5. Partial → Issued (completeIssue() — triggered by StockIssueService):**
- This transition occurs when a follow-up stock issue fulfills the remaining quantities.
- **Guard (status is 'partial'):** Error: "Cannot complete an issue request with status '{current_status}'."
- **Trigger condition:** After a subsequent stock issue, check if ALL line items now have issued_qty >= requested_qty.
- **Action:** Sets issue request status to 'issued'.
- **Side effect:** No further stock issues can be executed against a fully issued request.

**6. Rejected Terminal State:**
- Once rejected, the request cannot be re-approved or modified.
- The requester can create a new issue request if needed.

**Request Number Auto-Generation:**
- Pattern: IR-{YEAR}-{SEQUENCE}
- 4-digit zero-padded sequence: IR-2026-0001, IR-2026-0002, ...
- Generated in IssueRequestService::generateRequestNumber():
  1. Get current year.
  2. Find highest request_number for current year using LIKE 'IR-{YEAR}-%'.
  3. Extract numeric suffix, increment by 1.
  4. Format: IR-{YEAR}-{str_pad(, 4, '0', STR_PAD_LEFT)}.
  5. If none exist for year, start at IR-{YEAR}-0001.

**Line Item Modifications by Status:**
- submitted: Line items are locked (read-only). Error: "Cannot modify line items on a submitted issue request."
- pproved: Line items are locked. Same error as submitted.
- issued: Line items are locked and read-only.
- partial: Line items are locked.
- ejected: Line items are locked.

### Data Integrity

**Unique Constraints:**
- equest_number is UNIQUE. Auto-generated; never user-provided.

**Foreign Key Cascades:**
- inv_issue_request_items.issue_request_id → inv_issue_requests.id: ON DELETE CASCADE.
- inv_issue_request_items.item_id → inv_stock_items.id: Standard FK.
- inv_issue_request_items.uom_id → inv_units_of_measure.id: Standard FK.
- inv_issue_requests.requested_by → sys_users.id: Standard FK.
- inv_issue_requests.department_id → sch_department.id: Standard FK.

**Issued Qty Tracking:**
- issued_qty on issue request items is the running total of all stock issues executed against that request line.
- It is NEVER set directly — only incremented by StockIssueService.
- Atomic update during stock issue execution: UPDATE inv_issue_request_items SET issued_qty = issued_qty + {issue_qty} WHERE id = {issue_request_item_id}.
- If a data integrity check reveals mismatch, the inv_issue_request_items.issued_qty is the source of truth (it is updated in the same transaction as the stock issue).

**Negative Stock Prevention (BR-INV-003):**
- During stock issue execution, StockIssueService validates available stock BEFORE executing the issue.
- Query: SELECT current_qty FROM inv_stock_balances WHERE stock_item_id = {item_id} AND godown_id = {godown_id} FOR UPDATE.
- If current_qty < issue_qty, the entire transaction is rejected: "Insufficient stock for item {item_name}. Available: {available_qty}, Requested: {requested_qty}."
- The row-level lock (FOR UPDATE) prevents race conditions where two concurrent issues could both pass the check before either deducts.

### JSON Structure — Not applicable (no JSON columns).

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must NOT be 'issued' or 'partial'. Error: "Cannot delete an issue request that has been issued or partially issued."
2. Pre-delete check: status must NOT be 'approved'. Error: "Cannot delete an approved issue request. Reject it first, or wait until it is issued."
3. If status is 'submitted' or 'rejected': delete allowed.
4. Pre-delete action: sets is_active = 0.
5. The issue request record gets deleted_at timestamp set.
6. Issue request items are NOT cascade soft-deleted.
7. Audit log entry: action = "delete", entity_type = "inv_issue_requests", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets deleted_at to NULL.
3. Does NOT set is_active back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_issue_requests", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records.
2. Pre-delete check: must not have any associated stock issues. If stock issues exist: "Cannot force delete this issue request because stock issues have been executed against it."
3. Permanently removes the record. Line items cascade-deleted.
4. Audit log entry: action = "force_delete", entity_type = "inv_issue_requests", entity_id = {id}.

### Status Toggle (is_active)

- Route: POST /inventory/issue-requests/{id}/toggle-status
- AJAX endpoint accepting JSON or form data.
- Toggles is_active between 0 and 1.
- Pre-toggle guard: if toggling from 1→0 (deactivating), issue request must not be 'issued' or 'partial'. Error: "Cannot deactivate an issue request that has been issued."
- On success, returns JSON: {"success": true, "is_active": bool, "message": "Status updated successfully."}
- Audit log entry created on toggle.

### Audit Trail Rules

- Every create, update, approve, reject, soft delete, restore, force delete, and toggle-status action logs to sys_activity_logs.
- On status transitions: log "Issue request {request_number}: status changed from {old} to {new} by {user_name}."
- On create: log "Issue request {request_number} created by {user_name} for department {department_name} with {count} items."
- On approve: log "Issue request {request_number} approved by {user_name}."
- On reject: log "Issue request {request_number} rejected by {user_name}. Reason: {remarks}."
- On stock issue execution: log "Stock issue {issue_number} executed against issue request {request_number}. Items: {item_count}."
- The global ctivityLog() helper is called for each mutation.

### List View Rules

- Controller: IssueRequestController@index, Gate: inventory.issue-request.viewAny.
- Pagination: 15 records per page via ->paginate(15).
- Eager loads: requestedBy (sys_users), department (sch_department), items count.
- Default sort: by created_at descending (most recent first).
- Columns displayed: Request Number, Requested By, Department, Required Date, Items Count, Fulfillment % (progress bar for partial/issued), Status (badge with color), Actions (View, Edit, Approve, Reject, Delete buttons).
- Filter: status dropdown (submitted/approved/issued/partial/rejected/all).
- Filter: department (searchable select).
- Filter: date range (required_date).
- Search: by request number, requester name, or department name (text input).
- All filters preserved across pagination via ->withQueryString().
- Actions column is permission-gated:
  - Approve/Reject buttons: visible only on submitted requests when user has inventory.issue-request.approve.
  - Edit button: visible only on submitted requests.
  - Delete button: visible only on submitted/rejected requests.
- Row color: overdue required_date (past today and still submitted/approved) highlighted orange.
- Quick stats bar: counts per status + overdue count.

### Integration Rules

**StockIssueService Integration (Fulfillment):**
- When executing a stock issue against an issue request, StockIssueService::executeIssue() performs:
  1. Validates issue request status = 'approved' (for indirect issue) OR user has inventory.stock-issue.direct permission (BR-INV-010).
  2. Validates stock availability per item (BR-INV-003).
  3. Creates inv_stock_issues and inv_stock_issue_items.
  4. Calls StockLedgerService::postEntry() for outward entry.
  5. Updates inv_issue_request_items.issued_qty += issue_qty.
  6. Updates issue request status:
     - If ALL lines have issued_qty >= requested_qty: status = 'issued'.
     - If SOME lines have issued_qty < requested_qty but at least one line has issued_qty > 0: status = 'partial'.
     - If NO lines have issued_qty > 0: status unchanged (stays 'approved').
  7. Fires StockIssued event → Accounting creates Stock Journal Voucher.
  8. Dispatches ReorderAlertJob if stock drops below reorder level (BR-INV-011).

**Acknowledgment Integration:**
- Acknowledgment is tracked on the Stock Issue entity (inv_stock_issues.acknowledged_by, cknowledged_at).
- It is NOT tracked directly on the Issue Request.
- For asset items, acknowledgment is mandatory (per BR-INV-012).

**Direct Issue Bypass (BR-INV-010):**
- Users with inventory.stock-issue.direct permission can issue stock without an issue request.
- In this case, the Stock Issue has issue_request_id = NULL.
- Direct issues do NOT create an Issue Request record.

**Partial Fulfillment Flow:**
1. Issue request is created (status: 'submitted').
2. Request is approved (status: 'approved').
3. Store Keeper executes first stock issue: issues 50 of 100 requested units.
   - issued_qty updated to 50 for the line.
   - Status becomes 'partial'.
4. Store Keeper executes second stock issue: issues remaining 50 units.
   - issued_qty updated to 100 for the line (fully issued).
   - Status becomes 'issued'.
5. If all items cannot be fulfilled due to stock shortage, the request remains 'partial' indefinitely.

**Reorder Alert Integration (BR-INV-011):**
- After each stock issue execution, StockIssueService dispatches ReorderAlertJob for each item where current_qty <= reorder_level.
- This is an async job (queued, 3 retries, 60s delay).
- The job does not block the issue request response.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | inventory.issue-request.viewAny |
| View details | inventory.issue-request.view |
| Create | inventory.issue-request.create |
| Edit/update | inventory.issue-request.update |
| Approve | inventory.issue-request.approve |
| Soft delete | inventory.issue-request.delete |
| Restore | inventory.issue-request.restore |
| Force delete | inventory.issue-request.forceDelete |
