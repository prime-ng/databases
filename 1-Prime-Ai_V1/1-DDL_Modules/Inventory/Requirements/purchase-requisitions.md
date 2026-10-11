# Purchase Requisitions — Requirements

## What It Does
Manages internal purchase requisitions (PRs) submitted by departments. PRs initiate the procurement workflow with a full state machine: Draft → Submitted → Approved/Rejected → Converted/Cancelled. Features priority-based SLA, department-level tracking, estimated-rate budget planning, and CSV bulk import.

## Database Fields

### inv_purchase_requisitions

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `pr_number` | VARCHAR(50) | Required. Unique. Auto-generated: PR-{YEAR}-{SEQUENCE}. |
| `requested_by` | BIGINT UNSIGNED FK → sys_users | Required. The user who created/submitted the PR. |
| `department_id` | INT UNSIGNED FK → sch_department | Nullable. INT UNSIGNED to match sch_department.id. |
| `required_date` | DATE | Required. Requested delivery date. |
| `priority` | ENUM('low','normal','high','urgent') | Default 'normal'. Determines procurement SLA. |
| `status` | ENUM('draft','submitted','approved','rejected','converted','cancelled') | Default 'draft'. |
| `approved_by` | BIGINT UNSIGNED FK → sys_users | Nullable. Set on approve action. |
| `approved_at` | TIMESTAMP | Nullable. Set on approve action. |
| `remarks` | TEXT | Nullable. Rejection reason or general notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_purchase_requisition_items

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `pr_id` | BIGINT UNSIGNED FK → inv_purchase_requisitions | Required. ON DELETE CASCADE. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. |
| `qty` | DECIMAL(15,3) | Required. Requested quantity. Must be > 0. |
| `uom_id` | BIGINT UNSIGNED FK → inv_units_of_measure | Required. |
| `estimated_rate` | DECIMAL(15,2) | Nullable. Estimated unit price for budget planning. |
| `remarks` | VARCHAR(255) | Nullable. Line-level notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `pr_number` | Required, string, max:50, unique | "The PR number has already been taken." Auto-generated — never user-provided. |
| `requested_by` | Required, integer, exists:sys_users,id | "The requested by field is required." Automatically set to auth user on create. |
| `department_id` | Nullable, integer, exists:sch_department,id | "The selected department is invalid." If null, treated as no-department PR (allowed for non-departmental requests). |
| `required_date` | Required, date, after_or_equal:today | "The required date is required." Must be today or a future date. Cannot be in the past. |
| `priority` | Required, enum: low/normal/high/urgent | "The selected priority is invalid." Defaults to 'normal' if not provided. |
| `status` | Required, enum | Never user-selectable. Set by state machine transitions only. If malformed request to set status directly, return: "Status can only be changed through workflow actions (submit, approve, reject, cancel)." |
| `remarks` | Nullable, string, max:5000 | Required on reject action: "Rejection reason is required." On create/update, optional. |
| `qty` (item line) | Required, numeric, gt:0 | "The quantity must be greater than 0." Cannot be zero or negative. |
| `item_id` (item line) | Required, integer, exists:inv_stock_items,id | "The selected item is invalid." Must reference an active stock item. |
| `uom_id` (item line) | Required, integer, exists:inv_units_of_measure,id | "The selected unit of measure is invalid." Must reference an active UOM. |
| `estimated_rate` (item line) | Nullable, numeric, min:0 | "The estimated rate must be at least 0." If provided, used for budget planning. |

### Entity-Specific Rules / Lifecycle State Machine

**Full Status Lifecycle:**
```
[Draft] ──submit()──→ [Submitted] ──approve()──→ [Approved] ──convertToPO()──→ [Converted]
                           │                          │
                       reject()                   reject()
                           │                          │
                           └──────────→ [Rejected] ←───┘

[Draft] ──cancel()──→ [Cancelled]
[Submitted] ──cancel()──→ [Cancelled]
[Approved] ──cancel()──→ [Cancelled]
[Converted] ──cancel()──→ ✗ (cannot cancel converted PR)
[Rejected] ──cancel()──→ ✗ (rejected is terminal, cannot cancel)
```

**State Transition Details:**

**1. Draft → Submitted (`submit()`):**
- **Guard (at least 1 line item):** PR must have at least one inv_purchase_requisition_items record. Error: "Cannot submit a PR with no line items. Add at least one item first."
- **Guard (all qty > 0):** Every line item's `qty` must be > 0. Error: "Line item #{line_number}: Quantity must be greater than 0."
- **Guard (all item_ids valid):** Every line item's item_id must reference an active (non-deleted, is_active=1) stock item. Error: "Line item #{line_number}: Selected item is inactive or does not exist."
- **Action:** Sets `status = 'submitted'`.
- **Timestamp:** Sets `updated_at` to now. Does NOT set approved_by/approved_at.

**2. Submitted → Approved (`approve()`):**
- **Guard (approver has permission):** Auth user must have `inventory.purchase-requisition.approve` permission. Error: "You do not have permission to approve purchase requisitions." (403 response).
- **Guard (status must be 'submitted'):** If already approved, rejected, or converted, return: "Cannot approve a PR with status '{current_status}'. Only submitted PRs can be approved."
- **Action:** Sets `status = 'approved'`, `approved_by = auth()->id()`, `approved_at = now()`.
- **Side effect:** Record approval in audit log.

**3. Submitted → Rejected (`reject()`):**
- **Guard (remarks required):** Rejection requires a reason. If `remarks` is empty or null: "Rejection reason is required. Please provide remarks explaining why the PR is rejected."
- **Guard (status must be 'submitted'):** Error: "Cannot reject a PR with status '{current_status}'. Only submitted PRs can be rejected."
- **Action:** Sets `status = 'rejected'`, `approved_by = auth()->id()` (the rejecter is recorded in approved_by as the reviewer), `approved_at = now()`. The `remarks` field stores the rejection reason.
- **Side effect:** Notification sent to the `requested_by` user: "Your PR #{pr_number} has been rejected. Reason: {remarks}."

**4. Approved → Converted (`convertToPO()`):**
- **Guard (status must be 'approved'):** Error: "Cannot convert a PR with status '{current_status}'. Only approved PRs can be converted."
- **Guard (at least 1 unconverted line):** The PR must have line items that haven't been fully converted. If all lines are already converted: "All line items in this PR have already been converted to purchase orders."
- **Action:** Sets `status = 'converted'`.
- **Side effect (BR-INV-004):** All PR line items become read-only. Any attempt to update or delete a converted PR's line items returns: "Cannot modify a converted purchase requisition. The PR lines are read-only."
- **Side effect:** The `pr_id` on the resulting PO is set to this PR's id.

**5. Any → Cancelled (`cancel()`):**
- **Guard (not already converted):** Error: "Cannot cancel a PR that has already been converted to a purchase order." (This is enforced — converted PRs are final.)
- **Guard (not already rejected):** Error: "Cannot cancel a PR that has already been rejected."
- **Guard (not already cancelled):** Idempotent — if already cancelled, return silently or with info message.
- **Action:** Sets `status = 'cancelled'`.
- **Remarks:** Optional cancellation reason can be provided.

**Priority SLA Determination:**
- `low`: No SLA. Standard processing.
- `normal`: Expected processing within 5 working days.
- `high`: Expected processing within 2 working days.
- `urgent`: Expected processing within 1 working day.
- SLA is informational (displayed in list view and detail view) — not enforced by the system.
- SLA is calculated from `created_at` (or `updated_at` on submit) + configured business days.

**PR Number Auto-Generation:**
- Pattern: `PR-{YEAR}-{SEQUENCE}`
- 4-digit zero-padded sequence: PR-2026-0001, PR-2026-0002, ... PR-2027-0001, ...
- Generated in `PurchaseRequisitionService::generatePRNumber()`:
  1. Get current year: `date('Y')`.
  2. Find the highest pr_number in the current year: `SELECT pr_number FROM inv_purchase_requisitions WHERE pr_number LIKE 'PR-{YEAR}-%' ORDER BY pr_number DESC LIMIT 1`.
  3. Extract numeric suffix, increment by 1.
  4. Format: `PR-{YEAR}-{str_pad($seq, 4, '0', STR_PAD_LEFT)}`.
  5. If no PRs exist for the year, start at PR-{YEAR}-0001.

**Line Item Modifications by Status:**
- `draft`: Full CRUD on line items. Add, update, delete any line.
- `submitted`: Line items are locked (read-only). Cannot add, update, or delete. Error: "Cannot modify line items on a submitted PR. Only draft PRs can be edited."
- `approved`: Line items are locked. Same restriction as 'submitted'.
- `rejected`: Line items are locked (read-only). Cannot add, update, or delete. Error: "Cannot modify line items on a rejected PR."
- `converted`: Line items are locked and read-only (BR-INV-004). Error: "Cannot modify a converted purchase requisition."
- `cancelled`: Line items are locked. Same error as rejected.

### Data Integrity

**Unique Constraint:**
- `pr_number` is UNIQUE. Auto-generated; never user-provided. If a custom PR number format is ever needed, it must still pass uniqueness validation.

**Foreign Key Cascades:**
- `inv_purchase_requisition_items.pr_id` → `inv_purchase_requisitions.id`: ON DELETE CASCADE — deleting a PR removes all its line items.
- `inv_purchase_requisition_items.item_id` → `inv_stock_items.id`: Standard FK — cannot delete a stock item referenced by any PR line item.
- `inv_purchase_requisition_items.uom_id` → `inv_units_of_measure.id`: Standard FK — cannot delete a UOM referenced by any PR line item.
- `inv_purchase_requisitions.requested_by` → `sys_users.id`: Standard FK. ON DELETE RESTRICT (user cannot be deleted if they have PRs).
- `inv_purchase_requisitions.department_id` → `sch_department.id`: FK. ON DELETE SET NULL if department is deleted.

**Converted PR Read-Only Enforcement (BR-INV-004):**
- When status = 'converted', ALL write operations on the PR and its items are blocked:
  1. `update()` → 403 error.
  2. `destroy()` → 403 error (cannot delete converted PR).
  3. Any item-level update/destroy → 403 error.
  4. Any status transition → 403 error.
- This is enforced in `PurchaseRequisitionPolicy` AND in `PurchaseRequisitionService` (dual layer).
- Exception: Soft-deleted PRs can still be viewed; the converted status is preserved.

**Draft PR Cleanup:**
- Database-level: No automatic cleanup. Old draft PRs remain indefinitely.
- Application-level: A scheduled command `inventory:cleanup-draft-prs` MAY be implemented to auto-cancel draft PRs older than a configurable number of days (default: 90 days). This is OPTIONAL.

### JSON Structure — Not applicable (no JSON columns).

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must NOT be 'converted'. Error: "Cannot delete a converted purchase requisition."
2. Pre-delete check: status must NOT be 'approved' (must cancel first). Error: "Cannot delete an approved PR. Cancel it first."
3. Pre-delete check: status must NOT be 'submitted' (must reject or cancel first). Error: "Cannot delete a submitted PR. Cancel or reject it first."
4. If status is 'draft', 'rejected', or 'cancelled': delete allowed.
5. Pre-delete action: sets `is_active = 0` (deactivated).
6. The PR record gets `deleted_at` timestamp set.
7. PR line items are NOT cascade soft-deleted (they remain active for potential future reference).
8. Audit log entry: action = "delete", entity_type = "inv_purchase_requisitions", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_purchase_requisitions", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records.
2. Pre-delete check: PR must not be referenced by any PO (where `pr_id = {id}`). If referenced: "Cannot force delete this PR because it has been converted to one or more purchase orders."
3. Permanently removes the record from the database. Line items are cascade-deleted.
4. Audit log entry: action = "force_delete", entity_type = "inv_purchase_requisitions", entity_id = {id}.

### Status Toggle (`is_active`)

- Route: `POST /inventory/purchase-requisitions/{id}/toggle-status`
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle guard: if toggling from 1→0 (deactivating), PR must not be 'converted'. Error: "Cannot deactivate a converted purchase requisition."
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- Audit log entry created on toggle.

### Audit Trail Rules

- Every create, update, submit, approve, reject, cancel, convert, soft delete, restore, force delete, and toggle-status action logs to `sys_activity_logs`.
- On status transitions: log "PR {pr_number}: status changed from {old_status} to {new_status} by {user_name}."
- On convert: log "PR {pr_number} converted to purchase order PO-{po_number}."
- On create: log "Purchase requisition {pr_number} created by {user_name} with {count} line items."
- On update (non-status fields): detect changed fields via `$model->getChanges()`, log old/new values.
- On reject: log "PR {pr_number} rejected by {user_name}. Reason: {remarks}."
- Audit entries include: `entity_type = 'inv_purchase_requisitions'`, `entity_id = {id}`, `action = {action_type}`, `old_values`, `new_values`, `created_by`.

### List View Rules

- Controller: `PurchaseRequisitionController@index`, Gate: `inventory.purchase-requisition.viewAny`.
- Pagination: 15 records per page via `->paginate(15)`.
- Eager loads: requestedBy (sys_users relationship), department (sch_department relationship), items count.
- Default sort: by created_at descending (most recent first).
- Columns displayed: PR Number, Requested By, Department, Required Date, Priority (badge: low=gray, normal=blue, high=orange, urgent=red), Line Items Count, Status (badge with color), Created At, Actions (View, Edit, Submit, Approve, Reject buttons).
- Filter: status dropdown (draft/submitted/approved/rejected/converted/cancelled/all).
- Filter: priority dropdown (low/normal/high/urgent/all).
- Filter: department (searchable select).
- Filter: date range (from/to for created_at).
- Filter: search by PR number or requested by name (text input).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is role/permission-gated:
  - Submit button: visible only on draft PRs when user has `inventory.purchase-requisition.create` AND is the `requested_by` user.
  - Approve/Reject buttons: visible only on submitted PRs when user has `inventory.purchase-requisition.approve`.
  - Edit button: visible only on draft PRs (or when user has special override).
  - Delete button: visible only on deletable statuses (draft/rejected/cancelled) with `inventory.purchase-requisition.delete` permission.
- Row color coding: urgent priority row highlighted red; overdue required_date (> today for submitted/approved) shown with warning icon.
- Quick status summary bar at top: counts of Draft / Submitted / Approved / Rejected / Converted / Cancelled.

### Integration Rules

**PurchaseOrderService Integration (Convert PR to PO):**
- When PR is converted to PO, `PurchaseOrderService::convertFromPR()` performs:
  1. Validates PR status = 'approved'.
  2. Creates a new `inv_purchase_orders` record with `pr_id = {pr_id}`.
  3. Copies line items from `inv_purchase_requisition_items` to `inv_purchase_order_items`.
  4. Pre-fills vendor from preferred vendor link (ItemVendorService).
  5. Pre-fills unit_price from active rate contract if available (BR-INV-013).
  6. Marks PR status as 'converted'.
  7. PR lines become read-only (BR-INV-004 enforcement).
  8. If any line fails to copy (e.g., item deleted), the entire conversion rolls back.

**Partial PR Conversion:**
- Individual line items from an approved PR can be selected for conversion to PO.
- Remaining unconverted lines stay in 'approved' state on the PR.
- The PR status remains 'approved' until ALL lines have been converted.
- Only when the last line is converted does the PR status change to 'converted'.
- If a PO is created from only some lines, the remaining approved lines can be converted in a separate PO later.

**Quotation Integration:**
- An approved PR can optionally go through the quotation process before PO creation.
- The PR's `id` is stored as `inv_quotations.pr_id` to link RFQs back to the source PR.
- Quotation comparison matrix displays PR items side by side across vendor quotes.

**Accounting Integration:**
- PR estimated_rates feed into budget planning reports (read-only by Accounting module).
- No direct accounting event fired on PR creation — the PR is an internal document only.

**CSV Bulk Import:**
- Route: `POST /inventory/purchase-requisitions/import`.
- Expected CSV columns: `item_code, quantity, estimated_rate, remarks` (item_code can be SKU or item name).
- Pre-import validation:
  1. Parse CSV file.
  2. For each row, look up item_code in inv_stock_items (SKU match first, then name match).
  3. Validate quantity > 0.
  4. Validate estimated_rate >= 0 if provided.
  5. Return validation report with row-by-row results (success/failure with reason).
  6. If all rows pass, confirm import; if any fail, show errors and allow correction.
  7. On confirmed import, create PR with status 'draft'.
- Imported PRs follow the same lifecycle as manually created PRs.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.purchase-requisition.viewAny` |
| View details | `inventory.purchase-requisition.view` |
| Create | `inventory.purchase-requisition.create` |
| Edit/update (draft only) | `inventory.purchase-requisition.update` |
| Approve | `inventory.purchase-requisition.approve` |
| Soft delete | `inventory.purchase-requisition.delete` |
| Restore | `inventory.purchase-requisition.restore` |
| Force delete | `inventory.purchase-requisition.forceDelete` |
