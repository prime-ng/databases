# Rate Contracts — Requirements

## What It Does
Manages vendor-level rate contracts that fix prices for specified items over a validity period. Active contract rates auto-populate purchase order unit prices (BR-INV-013). Supports draft → active → expired/cancelled lifecycle with 30-day expiry alerts.

## Database Fields

### inv_rate_contracts

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `vendor_id` | INT UNSIGNED FK → vnd_vendors | Required. INT UNSIGNED to match vnd_vendors.id. |
| `contract_number` | VARCHAR(50) | Nullable. Unique. Auto-generated. e.g. RC-2026-001. |
| `valid_from` | DATE | Required. Contract start date. |
| `valid_to` | DATE | Required. Contract end date. Expiry alert fires 30 days before this date. |
| `status` | ENUM('draft','active','expired','cancelled') | Default 'draft'. |
| `remarks` | TEXT | Nullable. Additional notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_rate_contract_items_jnt

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `rate_contract_id` | BIGINT UNSIGNED FK → inv_rate_contracts | Required. ON DELETE CASCADE. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. |
| `agreed_rate` | DECIMAL(15,2) | Required. Fixed price per unit for this item in this contract. |
| `min_qty` | DECIMAL(15,3) | Nullable. Minimum order quantity. |
| `max_qty` | DECIMAL(15,3) | Nullable. Maximum order quantity. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `vendor_id` | Required, integer, exists:vnd_vendors,id | "The selected vendor is invalid." Must reference an existing, active vendor. |
| `contract_number` | Nullable, string, max:50, unique across all contracts (including soft-deleted) | "The contract number has already been taken." Auto-generated if not provided: RC-{YEAR}-{SEQUENCE}. |
| `valid_from` | Required, date | "The valid from date is required." Must be a valid date. |
| `valid_to` | Required, date, after_or_equal:valid_from | "The valid to date must be on or after the valid from date." Enforced at form validation and service layer. |
| `status` | Required, enum: draft/active/expired/cancelled | "The selected status is invalid." Transitions managed by dedicated service methods (activate, expire, cancel), not by direct status assignment. |
| `remarks` | Nullable, string, max:5000 | Truncated to 5000 characters if longer (TEXT column stores more, but application limits input). |
| `agreed_rate` (item line) | Required, numeric, min:0 | "The agreed rate must be at least 0." Must be a positive decimal. |
| `min_qty` (item line) | Nullable, numeric, min:0 | Must be 0 or greater if provided. |
| `max_qty` (item line) | Nullable, numeric, min:0, gt:min_qty if both set | If both min_qty and max_qty are set, max_qty must be greater than min_qty. Error: "Maximum quantity must be greater than minimum quantity." |
| `item_id` (item line) | Required, integer, exists:inv_stock_items,id | "The selected item is invalid." Must reference an existing stock item. |
| `rate_contract_id` (item line) | Required, integer, exists:inv_rate_contracts,id | Must reference an existing rate contract header. |

### Entity-Specific Rules / Lifecycle State Machine

**Status Lifecycle:**
```
[Draft] ──activate()──→ [Active] ──auto-expire()──→ [Expired]
                              │
                         cancel()
                              │
                         [Cancelled]

[Draft] ──cancel()──→ [Cancelled]
[Active] ──cancel()──→ [Cancelled]
[Expired] ←── (no reverse transitions allowed)
[Cancelled] ←── (no reverse transitions allowed)
```

**Status Transition Guards:**

1. **Draft → Active (`activate()`):**
   - Pre-condition: Contract must have at least 1 line item (`inv_rate_contract_items_jnt`).
   - Pre-condition: `valid_to` must be in the future (not already expired).
   - Pre-condition: Vendor must be active in vnd_vendors.
   - If no line items: "Cannot activate a contract with no items. Add at least one item first."
   - If valid_to has already passed: "Cannot activate a contract whose valid_to date has already passed."
   - Side effect: Sets `status = 'active'`.

2. **Active → Expired (`auto-expire()`, triggered by Artisan command `inventory:expire-rate-contracts`):**
   - Triggered by scheduled command running daily at midnight.
   - Pre-condition: `valid_to < today()` AND `status = 'active'`.
   - No manual expire action — only automatic.
   - Side effect: Sets `status = 'expired'`.
   - Logs: "Rate contract {contract_number} auto-expired on {date}."

3. **Any non-terminal → Cancelled (`cancel()`):**
   - Pre-condition: Contract is not already 'expired' or 'cancelled'.
   - Cancelling from 'draft' removes it from workflow without consequences.
   - Cancelling from 'active' prevents further PO rate lookups.
   - Side effect: Sets `status = 'cancelled'`.
   - Remarks field is NOT mandatory for cancellation (unlike PR rejection).

4. **Expired/Cancelled are terminal states:**
   - Once expired or cancelled, a contract cannot be re-activated.
   - To create a new agreement, a new contract record must be created.

**Contract Number Auto-Generation:**
- Pattern: `RC-{YEAR}-{SEQUENCE}`
- Sequence is zero-padded 4-digit: 0001, 0002, ...
- Reset annually: RC-2026-0001, RC-2026-0002, ... RC-2027-0001, ...
- Generated in `RateContractService::generateContractNumber()`:
  1. Find the highest contract_number for the current year using `LIKE 'RC-{YEAR}-%'`.
  2. Extract the numeric suffix, increment by 1.
  3. Format as `RC-{YEAR}-{PADDED_SEQUENCE}`.
  4. If no contracts exist for the year, start at RC-{YEAR}-0001.
- If user provides a custom contract_number, accept it provided it passes uniqueness validation.
- Custom numbers must still follow the pattern (not strictly enforced, but recommended).

**Expiry Alert Schedule:**
- Scheduled command `inventory:expire-rate-contracts` runs daily at midnight.
- Logic: `SELECT * FROM inv_rate_contracts WHERE status = 'active' AND valid_to BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)`.
- For each matching contract, fires `RateContractExpiringSoon` event.
- Event payload: `{contract_id, contract_number, vendor_id, valid_to, items_count}`.
- Consumer: Notification (NTF) module dispatches alert to store manager role.
- No duplicate alerts: check `sys_activity_logs` to ensure alert hasn't been sent in the last 24 hours for the same contract.

### Data Integrity

**Unique Constraints:**
- `contract_number` is UNIQUE (nullable — allows multiple NULLs in MySQL; if auto-generated, always non-null).
- `(rate_contract_id, item_id)` in rate_contract_items_jnt is UNIQUE — no duplicate items within the same contract.

**Foreign Key Cascades:**
- `inv_rate_contract_items_jnt.rate_contract_id` → `inv_rate_contracts.id`: ON DELETE CASCADE — deleting a contract removes all its line items.
- `inv_rate_contract_items_jnt.item_id` → `inv_stock_items.id`: Standard FK — cannot delete a stock item referenced by active rate contract items without first removing the contract line.

**Date Validation:**
- `valid_to` MUST be >= `valid_from`. Enforced at:
  1. FormRequest validation layer (`after_or_equal:valid_from`).
  2. Service layer as a secondary guard.
  3. If violated by direct DB manipulation (not possible via app), behavior is undefined.

**Min/Max Qty Logic in Rate Contract Items:**
- Both min_qty and max_qty are optional independently.
- If only min_qty is set: the contract rate applies for orders with quantity >= min_qty.
- If only max_qty is set: the contract rate applies for orders with quantity <= max_qty.
- If both are set: the contract rate applies for orders where min_qty <= qty <= max_qty.
- If neither is set: the contract rate applies for any quantity.
- During PO creation, if the ordered qty falls outside the min/max range, the contract rate should NOT be auto-applied (falls back to manual entry or last purchase rate).

### JSON Structure — Not applicable (no JSON columns).

### Soft Delete & Restore Rules

**Soft Delete (Rate Contract Header):**
1. Pre-delete check: cannot delete an active contract. Error: "Cannot delete an active rate contract. Cancel it first."
2. Pre-delete action: automatically sets `is_active = 0`.
3. The contract record gets `deleted_at` timestamp set.
4. Rate contract items are NOT cascade soft-deleted (they stay active unless explicitly deleted).
5. Audit log entry: action = "delete", entity_type = "inv_rate_contracts", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_rate_contracts", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records.
2. Pre-delete check: no remaining line items (they get cascade-deleted, but confirm).
3. Permanently removes the record from the database.
4. Audit log entry: action = "force_delete", entity_type = "inv_rate_contracts", entity_id = {id}.

**Soft Delete (Rate Contract Items):**
1. Individual line items can be deleted from a draft or active contract.
2. Cannot delete items from expired/cancelled contracts (these are read-only).
3. Deleting a line item from an active contract removes that item from contract pricing.
4. After deleting the last item in an active contract, the contract CAN remain active (no auto-cancel).

### Status Toggle (`is_active`)

- Route: `POST /inventory/rate-contracts/{id}/toggle-status`
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle guard: if toggling from 1→0 (deactivating), no guard conditions apply.
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- Audit log entry created on toggle.
- Does NOT change the `status` ENUM — only affects `is_active`.

### Audit Trail Rules

- Every create, update, status transition, soft delete, restore, force delete, and toggle-status action logs to `sys_activity_logs`.
- On status transitions (activate, cancel, expire): log "Status changed from {old} to {new} for contract {contract_number}."
- On create: log "Rate contract {contract_number} created for vendor {vendor_name} ({contract_id})."
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values.
- The global `activityLog()` helper is called for each mutation.
- The scheduled auto-expire command logs each expired contract as a batch entry: "Auto-expired {count} rate contracts on {date}."

### List View Rules

- Controller: `RateContractController@index`, Gate: `inventory.rate-contract.viewAny`.
- Pagination: 15 records per page via `->paginate(15)`.
- Eager loads: vendor (vnd_vendors relationship).
- Default sort: by created_at descending (most recent first).
- Columns displayed: Contract Number, Vendor Name, Valid From, Valid To, Status (badge with color: draft=gray, active=green, expired=red, cancelled=orange), Items Count, Days Remaining (for active contracts), Actions (View, Edit, Activate/Cancel buttons).
- Filter: status (draft/active/expired/cancelled/all) via dropdown.
- Filter: vendor (searchable select/dropdown).
- Filter: date range (valid_from and valid_to).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated.
- Row highlighting: contracts expiring within 30 days shown with warning background color.
- "Expiring Soon" badge shown when valid_to is within 30 days and status is active.

### Integration Rules

**PurchaseOrderService Integration (BR-INV-013):**
- When creating a PO from a PR conversion or manually selecting a vendor, the system queries for active rate contracts.
- Lookup: `SELECT irci.* FROM inv_rate_contract_items_jnt irci JOIN inv_rate_contracts irc ON irci.rate_contract_id = irc.id WHERE irc.vendor_id = {vendor_id} AND irc.status = 'active' AND irci.item_id = {item_id} AND CURDATE() BETWEEN irc.valid_from AND irc.valid_to`.
- If a matching active contract line is found, the PO item's `unit_price` is pre-populated with the `agreed_rate`.
- If multiple active contracts exist for the same (vendor, item) pair (overlapping periods), the one with the later `valid_from` date takes precedence (most recent contract).
- Expired contracts (`status = 'expired'` or `valid_to < today()`) are NEVER used for auto-population.
- The min/max qty enforcement: If the PO line's `ordered_qty` falls outside the contract's min/max range, the rate should NOT be auto-populated. Instead, the system falls back to last purchase rate or manual entry. Error note displayed: "Order quantity outside contract range. Manual rate entry required."
- This auto-population is a PRE-FILL convenience, not a hard enforcement. The user can override the unit price manually.

**RateContractExpiringSoon Integration:**
- Dispatched by scheduled command when valid_to is within 30 days and status = 'active'.
- Implementation: Daily cron `inventory:expire-rate-contracts`.
- Event: `RateContractExpiringSoon { contract_id, contract_number, vendor_id, valid_to, days_remaining }`.
- Consumer: NTF module sends notification to store manager role.
- Notification message: "Rate contract {contract_number} with {vendor_name} is expiring on {valid_to} ({days_remaining} days remaining)."

**Auto-Expire Integration:**
- Daily cron also transitions contracts where `valid_to < CURDATE()` and `status = 'active'` to `status = 'expired'`.
- Logs the auto-expire action in audit trail.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.rate-contract.viewAny` |
| View details | `inventory.rate-contract.view` |
| Create | `inventory.rate-contract.create` |
| Edit/update | `inventory.rate-contract.update` |
| Activate | `inventory.rate-contract.activate` |
| Soft delete | `inventory.rate-contract.delete` |
| Restore | `inventory.rate-contract.restore` |
| Force delete | `inventory.rate-contract.forceDelete` |
