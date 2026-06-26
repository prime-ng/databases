# Stock Adjustments — Requirements

## What It Does
Manages physical count audit adjustments to correct stock balances. Records the difference between system-calculated quantity and physically counted quantity. Supports an approval workflow for adjustments above a configurable threshold. Positive variances create inward entries, negative variances create outward entries.

## Database Fields

### inv_stock_adjustments

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `adjustment_number` | VARCHAR(50) | Required. Unique. Auto-generated: ADJ-{YEAR}-{SEQUENCE}. |
| `adjustment_date` | DATE | Required. Physical count audit date. |
| `godown_id` | BIGINT UNSIGNED FK → inv_godowns | Required. Godown being audited. |
| `reason` | VARCHAR(500) | Nullable. Reason for the adjustment. |
| `status` | ENUM('draft','submitted','approved','rejected','posted') | Required. Default 'draft'. Lifecycle status. |
| `approved_by` | BIGINT UNSIGNED FK → sys_users | Nullable. Set on approval transition. |
| `approved_at` | TIMESTAMP | Nullable. Approval timestamp. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_stock_adjustment_items

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `adjustment_id` | BIGINT UNSIGNED FK → inv_stock_adjustments | Required. ON DELETE CASCADE. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. Item being counted. |
| `system_qty` | DECIMAL(15,3) | Required. Auto-populated from inv_stock_balances at time of adjustment creation (snapshot). Read-only. |
| `physical_qty` | DECIMAL(15,3) | Required. User-entered physically counted quantity. |
| `variance_qty` | DECIMAL(15,3) | GENERATED ALWAYS AS (physical_qty - system_qty) STORED. Never INSERT/UPDATE directly. Positive = surplus, negative = deficit. |
| `unit_cost` | DECIMAL(15,2) | Required. Valuation rate per unit from StockValuationService at time of adjustment. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `adjustment_number` | Required, string, max:50, unique | Auto-generated as ADJ-{YEAR}-{SEQUENCE}. Never user-supplied. |
| `adjustment_date` | Required, date, before_or_equal:today | Cannot be a future date. Must match the date of physical count. |
| `godown_id` | Required, integer, exists:inv_godowns,id | Must reference an active godown. Cannot adjust stock in a deactivated godown. |
| `reason` | Nullable, string, max:500 | Recommended for all adjustments. Required when total adjustment value exceeds threshold (BR-INV-017). Validation: "Reason is required for adjustments above the approval threshold." |
| `status` | Required, enum: draft/submitted/approved/rejected/posted | Validated against exact enum values. Transitioned by service, not user-supplied. |
| `approved_by` | Nullable, integer, exists:sys_users,id | Set automatically by approval action. Must be different from created_by. |
| `approved_at` | Nullable, timestamp | Set automatically when approved_by is set. |
| `item_id` (item) | Required, integer, exists:inv_stock_items,id | Must reference an active stock item. Cannot be a deactivated item. |
| `system_qty` (item) | Read-only — auto-populated | Snapshot taken from inv_stock_balances.current_qty at moment of adjustment creation. Never accepted from user input. |
| `physical_qty` (item) | Required, numeric | Must be >= 0. Can be zero (item not found physically). User-entered. |
| `variance_qty` (item) | Read-only — GENERATED ALWAYS | Never INSERT/UPDATE directly. Computed by MySQL as physical_qty - system_qty. DB-level enforcement — any attempt to INSERT/UPDATE this column raises a MySQL error. |
| `unit_cost` (item) | Required, numeric, min:0 | Determined by StockValuationService at time of adjustment. Read-only after creation. |
| Duplicate items | Unique constraint per adjustment | Same item cannot appear twice in one adjustment. Application-level check: "Item {name} is already listed in this adjustment." |

### Entity-Specific Rules / Lifecycle State Machine

**Adjustment Lifecycle FSM:**

```
[Draft] ──submit()──→ [Submitted] ──approve()*──→ [Approved] ──post()──→ [Posted]
                            │
                        reject()
                            │
                        [Rejected]
```

*approve() required only when total adjustment value >= configurable threshold (BR-INV-017)

**Transitions:**

| From | To | Action | Pre-conditions | Side Effects |
|---|---|---|---|---|
| Draft | Submitted | submit() | At least 1 item with physical_qty entered | Audit log; status updated; adjustment becomes read-only for item changes |
| Submitted | Approved | approve() | approver has `inventory.stock-adjustment.approve` permission; if total value >= threshold, approval mandatory | Sets approved_by, approved_at; audit log |
| Submitted | Rejected | reject() | approver has same permission | Sets reason as rejection note if provided; audit log |
| Approved | Posted | post() | status must be 'approved'; all items must have physical_qty entered; for deficit lines: deficit <= current_qty (BR-INV-003) | Stock entries created; balances updated; Accounting event fired |
| Any | — | cancel() | Only in draft or submitted status | Returns to draft with cleared approval |

**On post() — Single DB Transaction (per StockAdjustmentService):**
1. For each inv_stock_adjustment_items line:
   - If variance_qty > 0 (surplus): StockLedgerService::postEntry() with entry_type='adjustment' (inward); inv_stock_balances.current_qty incremented
   - If variance_qty < 0 (deficit): StockLedgerService::postEntry() with entry_type='adjustment' (outward); inv_stock_balances.current_qty decremented
   - Deficit pre-check: deficit quantity must not exceed current_qty (BR-INV-003)
2. Fire StockAdjusted event → Accounting creates Journal Entry (Dr/Cr Stock-in-Hand A/c)
3. ReorderAlertService::checkAndDispatch() for deficit items (BR-INV-011)
4. Status set to 'posted'

**Threshold Approval (BR-INV-017):**
- Configurable school-level setting: adjustment_approval_threshold
- Total adjustment value = SUM(ABS(variance_qty) × unit_cost) across all items
- If total >= threshold: submit() transitions to 'submitted', but post() blocked until approval
- If total < threshold: submit() can auto-approve (configurable — school setting: adjustment_auto_approve_below_threshold)
- Threshold checked at service layer, bypass not possible via UI

**variance_qty Semantic:**
- variance_qty = physical_qty - system_qty (GENERATED ALWAYS AS STORED)
- Positive variance: physical count > system → surplus → inward stock entry created
- Negative variance: physical count < system → deficit → outward stock entry created
- Zero variance: no stock entry created; item line posted as informational only
- The GENERATED ALWAYS AS STORED column is a DB-level guarantee — no application code can directly set variance_qty

**system_qty Snapshot:**
- Captured from inv_stock_balances.current_qty at adjustment creation time
- Does NOT change if stock moves after adjustment creation
- Freezes the system balance at audit time for accurate variance calculation
- If user reopens a draft adjustment that was created earlier, system_qty is NOT refreshed (intentional — preserves audit snapshot)

**Adjustment Number Auto-generation:**
- Format: ADJ-{YEAR}-{SEQUENCE}
- Example: ADJ-2026-042
- Sequence resets annually
- Generated by StockAdjustmentService on creation

### Data Integrity Rules

- variance_qty is a GENERATED ALWAYS AS STORED column — MySQL enforces read-only at DB level; any INSERT/UPDATE of variance_qty raises a MySQL error
- inv_stock_adjustment_items CASCADE delete when parent adjustment is deleted
- Once posted, adjustment is IMMUTABLE — no edits, no deletions, no reversals
- Corrections to posted adjustments require a NEW adjustment entry with appropriate reason
- system_qty snapshot integrity — preserved even if stock_balances change after creation
- unit_cost stored per-item at adjustment time; not recomputed from current valuation
- All items in a single adjustment must belong to the same godown (the godown_id on the header)
- Duplicate item_id per adjustment prevented at application level
- Positive and negative variance for same item within one adjustment not allowed (only one row per item)

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must be 'draft'. If submitted/approved/posted/rejected, return error: "Cannot delete adjustment in {status} status. Only draft adjustments can be deleted."
2. Pre-delete check: adjustment must not have any posted stock entries (never true for draft, but defensive check)
3. inv_stock_adjustment_items soft-deleted alongside parent
4. Audit log: action = "delete", entity_type = "inv_stock_adjustments", entity_id = {id}

**Restore:**
1. Only on soft-deleted records that were in 'draft' status at time of delete
2. Sets deleted_at = NULL
3. Restores to 'draft' status
4. Items restored alongside parent

**Force Delete:**
1. Only on already soft-deleted records
2. Only for adjustments that were never posted (defensive: no stock entries created)
3. Permanently removes record and all items

### Audit Trail Rules

- Every status transition logged: action = "adjustment.{new_status}" with old/new status values
- On submit: log number of items and total variance value
- On approve: log approved_by, approved_at, threshold exceeded flag
- On reject: log rejection reason
- On post: log total surplus value, total deficit value, number of stock entries created
- On edit (draft only): detect changed fields via $model->getChanges(), log old/new values
- All audit entries include adjustment_number for cross-referencing

### List View Rules

- Controller: index() method, Gate: 'inventory.stock-adjustment.viewAny'
- Pagination: 15 records per page
- Eager loads: godown (name), items count
- Default sort: by adjustment_date descending
- Columns displayed: Adjustment Number, Date, Godown, Status (badge — color-coded by status), Items Count, Total Variance Value, Approval Status (approved/rejected/pending), Actions
- Filter: adjustment_number search (text input)
- Filter: godown_id dropdown
- Filter: status dropdown (all/draft/submitted/approved/rejected/posted)
- Filter: date range (from/to) for adjustment_date
- All filters preserved across pagination
- Actions column permission-gated: Edit enabled only in draft status; Delete only in draft; Approve/Reject only in submitted; Post only in approved
- Click row to expand and view line items (AJAX expand or dedicated detail route)

### Integration Rules

**Accounting Integration (via StockAdjusted Event):**
- Event: StockAdjusted fired by StockLedgerService after successful posting
- Payload: `{adjustment_id, items:[{item_id, variance_qty, unit_cost, variance_value}], net_surplus, net_deficit}`
- Consumer: Accounting creates Journal Entry (Dr/Cr Stock-in-Hand A/c for surplus/deficit)
- Surplus: Dr Stock-in-Hand A/c, Cr Adjustment Suspense A/c
- Deficit: Dr Consumption/Write-off A/c, Cr Stock-in-Hand A/c
- No voucher_id column on adjustment tables (adjustments are informational for Accounting, not voucher-driven)

**Reorder Integration:**
- After deficit posting, ReorderAlertService::checkAndDispatch() runs
- Alerts triggered if current_qty drops below reorder_level due to adjustment deficit

**Notification Integration:**
- When adjustment requires approval: notification sent to users with inventory.stock-adjustment.approve permission
- Notification: "Stock adjustment {adjustment_number} in {godown} requires your approval. Total variance value: {value}."

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.stock-adjustment.viewAny` |
| View details | `inventory.stock-adjustment.view` |
| Create | `inventory.stock-adjustment.create` |
| Edit/update (draft only) | `inventory.stock-adjustment.update` |
| Submit | `inventory.stock-adjustment.submit` |
| Approve | `inventory.stock-adjustment.approve` |
| Soft delete | `inventory.stock-adjustment.delete` |
| View trash & restore | `inventory.stock-adjustment.restore` |
| Force delete | `inventory.stock-adjustment.forceDelete` |
