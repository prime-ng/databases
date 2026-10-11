# Stock Issues — Requirements

## What It Does
Manages stock issue execution. Supports both request-based issues (linked to an approved Issue Request) and direct issues (with special permission). Records which items are issued from which godown, to which employee/department, and tracks acknowledgment of delivery. Triggers Accounting Stock Journal creation via StockIssued event.

## Database Fields

### inv_stock_issues

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `issue_number` | VARCHAR(50) | Required. Unique. Auto-generated: SI-{YEAR}-{SEQUENCE}. |
| `issue_request_id` | BIGINT UNSIGNED FK → inv_issue_requests | Nullable. NULL = direct issue (requires direct permission). |
| `godown_id` | BIGINT UNSIGNED FK → inv_godowns | Required. Source godown from which stock is issued. |
| `issued_by` | BIGINT UNSIGNED FK → sys_users | Required. Store Keeper who executed the issue. |
| `issued_to_employee_id` | INT UNSIGNED FK → sch_employees | Nullable. Receiving employee. |
| `department_id` | INT UNSIGNED FK → sch_department | Required. Receiving department. |
| `issue_date` | DATE | Required. Date of physical issue. |
| `voucher_id` | BIGINT UNSIGNED FK → acc_vouchers | Nullable. NULL until Accounting creates Stock Journal via StockIssued event. |
| `acknowledged_by` | BIGINT UNSIGNED FK → sys_users | Nullable. Receiver who confirmed delivery. |
| `acknowledged_at` | TIMESTAMP | Nullable. Mandatory for asset items. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_stock_issue_items

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `stock_issue_id` | BIGINT UNSIGNED FK → inv_stock_issues | Required. ON DELETE CASCADE. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. Item being issued. |
| `qty` | DECIMAL(15,3) | Required. Issued quantity. |
| `unit_cost` | DECIMAL(15,2) | Required. Determined by StockValuationService per item's valuation method. |
| `batch_number` | VARCHAR(50) | Nullable. FIFO batch number for batch-tracked items. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `issue_number` | Required, string, max:50, unique | Auto-generated as SI-{YEAR}-{SEQUENCE}. Never user-supplied. |
| `issue_request_id` | Nullable, integer, exists:inv_issue_requests,id | If provided, must reference an existing issue request with status 'approved'. If NULL, issuer must have `inventory.stock-issue.direct` permission. Error: "Direct issue requires inventory.stock-issue.direct permission." |
| `godown_id` | Required, integer, exists:inv_godowns,id | Must reference an active godown. Cannot issue from a deactivated godown. |
| `issued_by` | Required, integer, exists:sys_users,id | Must be the authenticated user executing the issue. |
| `issued_to_employee_id` | Nullable, integer, exists:sch_employees,id | Must reference an active employee record if provided. |
| `department_id` | Required, integer, exists:sch_department,id | Must reference an active department. |
| `issue_date` | Required, date, before_or_equal:today | Cannot be a future date. Must match or precede today. |
| `voucher_id` | Nullable, integer | Read-only after Accounting sets it. Never user-supplied. |
| `acknowledged_by` | Nullable, integer, exists:sys_users,id | Must be a different user than issued_by. Set via acknowledge() endpoint. |
| `acknowledged_at` | Nullable, timestamp | Set automatically when acknowledged_by is set. |
| `qty` (item) | Required, numeric, min:0.001 | Must be positive decimal. Cannot be zero or negative. |
| `unit_cost` (item) | Required, numeric, min:0 | Determined by StockValuationService. Never user-supplied. Read-only. |
| `batch_number` (item) | Nullable, string, max:50 | Required for items with has_batch_tracking = 1. Validated against existing batches in stock. |

### Entity-Specific Rules / Lifecycle State Machine

**Issue Execution Flow (via StockIssueService::executeIssue()):**

Pre-conditions:
- Requires approved Issue Request (status = 'approved') OR issuer has `inventory.stock-issue.direct` permission (BR-INV-010)
- Negative stock guard: current_qty >= requested qty per item per godown (BR-INV-003) — checked via StockLedgerService before any outward entry
- For request-based issue: inv_issue_request_items.issued_qty must not exceed requested_qty

Side effects (single DB transaction):
1. Fire StockIssued event → Accounting creates Stock Journal Voucher; sets voucher_id
2. StockLedgerService::postEntry() creates inv_stock_entries (entry_type = 'outward') per item
3. inv_stock_balances current_qty deducted (lockForUpdate() row-level lock)
4. inv_issue_request_items.issued_qty updated (cumulative across partial issues)
5. Issue Request status auto-transitioned:
   - If all items issued fully → status = 'issued'
   - If some items remain → status = 'partial'
6. ReorderAlertService::checkAndDispatch() per item — fires async job if current_qty <= reorder_level (BR-INV-011)

**Acknowledgment Workflow:**
- Route: `POST /inventory/stock-issues/{id}/acknowledge`
- Sets acknowledged_by and acknowledged_at
- Mandatory for asset-type items (delivery confirmation for fixed asset accountability)
- Optional for consumable items
- Once acknowledged, issue cannot be modified
- acknowledged_by must be a different user than issued_by

**Direct Issue (without Issue Request):**
- Route: `POST /inventory/stock-issues/direct`
- Requires `inventory.stock-issue.direct` permission (BR-INV-010)
- Bypasses all issue request approval steps
- Same stock deduction and accounting side effects as request-based issue
- issue_request_id remains NULL

**voucher_id Lifecycle:**
- Created: voucher_id = NULL
- After StockIssued event processed by Accounting: voucher_id set to acc_vouchers.id
- Once voucher_id is set, the stock issue becomes immutable — no edits or deletions allowed
- If Accounting fails to create voucher: issue remains in pending state, retry mechanism via scheduled command

**Issue Number Auto-generation:**
- Format: SI-{YEAR}-{SEQUENCE}
- Example: SI-2026-001
- Sequence resets annually (per calendar year)
- Generated by StockIssueService on creation, not user-supplied

### Data Integrity Rules

- inv_stock_issue_items CASCADE delete when parent inv_stock_issues is deleted
- inv_stock_issues.issue_request_id ON DELETE SET NULL — if source request is deleted, issue remains but link is severed
- unit_cost is immutable after creation — determined by StockValuationService at time of issue and stored permanently
- voucher_id, once set by Accounting event listener, must never be overwritten
- No direct UPDATE/DELETE on inv_stock_issues after voucher_id is set — enforce at controller + service layer
- batch_number must reference an existing batch in inv_stock_entries (application-level check, not DB FK)
- qty precision: DECIMAL(15,3) — whole numbers for batch-tracked items (validated at service layer)
- Negative stock prevention enforced at service layer before any outward entry — not just at DB level (BR-INV-003)
- FIFO batch selection for batch-tracked items: StockValuationService::selectFifoBatch() selects oldest batch_number first (BR-INV-008)
- Stock valuation method (FIFO/WAC/LPC) per item determines unit_cost calculation (BR-INV-009)

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: voucher_id must be NULL. If voucher_id is set (Accounting already processed), return error: "Cannot delete issue that has been processed by Accounting."
2. Pre-delete check: acknowledged_by must be NULL. If acknowledgment completed, return error: "Cannot delete acknowledged stock issue."
3. inv_stock_issue_items are soft-deleted along with parent (cascade — model event triggers soft delete on items)
4. Audit log created: action = "delete", entity_type = "inv_stock_issues", entity_id = {id}
5. Activity log created: message = "Stock issue {issue_number} was deleted."

**Restore:**
1. Only on soft-deleted records
2. Sets deleted_at = NULL
3. Does NOT restore is_active (remains 0)
4. All inv_stock_issue_items restored alongside parent
5. Audit log: action = "restore"

**Force Delete:**
1. Only on already soft-deleted records
2. Only allowed if no linked Accounting voucher (voucher_id = NULL)
3. Permanently removes record and all issue items

### Audit Trail Rules

- Every create, update, soft delete, restore, force delete, acknowledge logs to hst_audit_log
- AuditService::log() called with: entity_type = "inv_stock_issues", entity_id = {id}, action = {action_type}
- On create: log issued_by, department_id, linked request number (if any)
- On acknowledge: log acknowledged_by, acknowledged_at
- StockIssued event payload captured in sys_activity_logs for Accounting reconciliation
- On update (before voucher_id set): detect changed fields via $model->getChanges(), log old/new values

### List View Rules

- Controller: index() method, Gate: 'inventory.stock-issue.viewAny'
- Pagination: 15 records per page via ->paginate(15)
- Eager loads: godown (name), issuedBy (name), department (name), issueRequest (request_number)
- Default sort: by issue_date descending (most recent first)
- Columns displayed: Issue Number, Date, Godown, Issued By, Department, Request Link, Acknowledged (yes/no badge), Status (voucher_id present badge), Actions
- Filter: issue_number search (text input)
- Filter: godown_id dropdown, auto-submits on change
- Filter: department_id dropdown, auto-submits on change
- Filter: date range (from/to) for issue_date
- Filter: acknowledgment status (acknowledged/pending/all) via dropdown
- All filters preserved across pagination via ->withQueryString()
- Actions column permission-gated: Edit/Delete hidden if cannot update/delete; Acknowledge button visible if not yet acknowledged
- Print Slip button (print-friendly view of issue details) — available on all issues regardless of status

### Integration Rules

**Accounting Integration (via StockIssued Event):**
- Event: StockIssued fired by StockIssueService after successful issue execution
- Payload: `{stock_issue_id, department_id, godown_id, items:[{item_id, qty, rate, amount}], total_amount, stock_ledger_id, expense_ledger_id, narration}`
- Consumer: Accounting module creates Stock Journal (Dr Dept Consumption A/c, Cr Stock-in-Hand A/c)
- Response: Accounting sets inv_stock_issues.voucher_id via event listener
- Async: Event dispatched after DB commit; listener runs in same queue

**Reorder Integration:**
- After every outward entry, ReorderAlertService::checkAndDispatch() runs
- If current_qty <= reorder_level: ReorderAlertJob dispatched as async job (3 retries, 60s backoff) (BR-INV-011)
- If auto_reorder_pr = true: ReorderAlertJob creates Draft PR automatically

**Print Slip Integration:**
- Route: `GET /inventory/stock-issues/{id}/print`
- Renders print-friendly view with: issue_number, date, godown, issued_by, issued_to, department, item table (item name, qty, unit_cost), signature lines for issuer and receiver
- CSS @media print styles for clean output
- Barcode/QR of issue_number on slip header

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.stock-issue.viewAny` |
| View details | `inventory.stock-issue.view` |
| Create (request-based) | `inventory.stock-issue.create` |
| Create (direct) | `inventory.stock-issue.direct` |
| Edit/update | `inventory.stock-issue.update` |
| Soft delete | `inventory.stock-issue.delete` |
| View trash & restore | `inventory.stock-issue.restore` |
| Force delete | `inventory.stock-issue.forceDelete` |
| Acknowledge | `inventory.stock-issue.acknowledge` |
| Print slip | `inventory.stock-issue.print` |
