# Asset Maintenance — Requirements

## What It Does
Tracks maintenance activities for fixed assets. Supports preventive maintenance, corrective/breakdown repairs, Annual Maintenance Contracts (AMC) with vendor linkage, and calibration records. Manages maintenance schedules with overdue alerts and cost tracking for asset lifecycle costing.

## Database Fields

### inv_asset_maintenance

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `asset_id` | BIGINT UNSIGNED FK → inv_assets | Required. Asset being maintained. |
| `maintenance_date` | DATE | Required. Scheduled or actual maintenance date. |
| `maintenance_type` | ENUM('preventive','corrective','amc','calibration') | Required. Category of maintenance activity. |
| `vendor_id` | INT UNSIGNED FK → vnd_vendors | Nullable. External service vendor (AMC vendor). |
| `cost` | DECIMAL(15,2) | Nullable. Maintenance cost incurred. |
| `notes` | TEXT | Nullable. Maintenance notes, findings, recommendations. |
| `next_due_date` | DATE | Nullable. Next scheduled maintenance date for recurring maintenance. |
| `status` | ENUM('scheduled','completed','overdue') | Required. Default 'scheduled'. Lifecycle status. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `asset_id` | Required, integer, exists:inv_assets,id | Must reference an existing, non-disposed asset. Error: "The selected asset is invalid or has been disposed." |
| `maintenance_date` | Required, date | Can be past, present, or future. Future dates indicate scheduled maintenance. Past dates indicate completed or overdue maintenance. |
| `maintenance_type` | Required, enum: preventive/corrective/amc/calibration | Validated against exact enum values. |
| `vendor_id` | Nullable, integer, exists:vnd_vendors,id | Recommended for AMC type. Required if maintenance_type = 'amc'. Error: "Vendor is required for AMC maintenance." |
| `cost` | Nullable, numeric, min:0 | Can be 0 for in-house maintenance. Required if status = 'completed'. Error: "Cost is required for completed maintenance." |
| `notes` | Nullable, string | Free text. Max 65,535 characters (TEXT column). |
| `next_due_date` | Nullable, date | Must be >= maintenance_date if provided. Error: "Next due date must be on or after the maintenance date." |
| `status` | Required, enum: scheduled/completed/overdue | Default 'scheduled'. Overdue is auto-transitioned by scheduled command, never set manually. |

### Entity-Specific Rules / Lifecycle State Machine

**Maintenance Lifecycle FSM:**

```
[Scheduled] ──complete()──→ [Completed]
     │
     │ (auto when next_due_date passes without completion)
     │
     ↓
  [Overdue]
```

**Transitions:**

| From | To | Action | Pre-conditions | Side Effects |
|---|---|---|---|---|
| Scheduled | Completed | complete() | maintenance_date must be <= today; cost must be provided | Sets status = 'completed'; records completion timestamp; updates updated_at |
| Scheduled | Overdue | (auto — scheduled command) | next_due_date < NOW() AND status = 'scheduled' | MaintenanceOverdue event fired; notification sent to store manager |
| Overdue | Completed | complete() | Same as scheduled→completed | Status set to 'completed'; overdue resolved |
| Completed | — | (no reverse transition) | — | Once completed, cannot revert to scheduled |
| Overdue | — | (update next_due_date) | If next_due_date updated to future date AND status = 'overdue' | Status auto-reverts to 'scheduled' (service layer check) |

**Preventive Maintenance:**
- Scheduled maintenance at regular intervals
- next_due_date set to the next scheduled date (e.g., maintenance_date + 3 months)
- Recurring: after completion, optionally create next scheduled record automatically
- If auto-create enabled: service creates a new 'scheduled' record with maintenance_date = previous.next_due_date and computed next_due_date

**Corrective Maintenance:**
- Unscheduled breakdown repair
- Typically initiated when asset condition = 'under_repair'
- next_due_date not typically set (one-off repair)
- Cost tracked for asset lifecycle analysis

**AMC (Annual Maintenance Contract):**
- Tied to external vendor (vendor_id required)
- Multi-year contracts tracked via separate AMC contract records if needed, or via recurring preventive maintenance records
- Vendor linkage enables procurement of spare parts through vendor module

**Calibration:**
- Precision equipment calibration tracking
- next_due_date is critical — calibration overdue may have compliance implications
- Calibration certificates can be attached as file uploads (future enhancement)

**Overdue Alert System:**
- Scheduled command: `php artisan inventory:maintenance-overdue`
- Frequency: daily (recommended via Laravel scheduler)
- Logic: ALL inv_asset_maintenance records WHERE status = 'scheduled' AND next_due_date IS NOT NULL AND next_due_date < NOW()
- Transitions matched records to 'overdue'
- Fires MaintenanceOverdue event → Notification module sends alert to store manager role
- Alert message: "Maintenance overdue for asset {asset_tag} ({maintenance_type}). Was due on {next_due_date}."
- Does NOT transition records without next_due_date (one-time maintenance cannot be overdue)

**Auto-resolve Overdue:**
- If an overdue record's next_due_date is updated to a future date (rescheduled), status reverts to 'scheduled'
- If maintenance is completed on an overdue record, status goes to 'completed'

### Data Integrity Rules

- CASCADE DELETE: inv_asset_maintenance records are deleted when parent asset is permanently removed (force delete). However, soft-deleting an asset does NOT cascade — maintenance records remain accessible.
- ON DELETE SET NULL: vendor_id set to NULL if vendor is deleted from Vendor module
- An asset with 'scheduled' maintenance records cannot be disposed — enforced at AssetService
- Completed maintenance records cannot be deleted — protection at controller level
- An asset can have multiple maintenance records simultaneously (different types or recurring cycles)
- next_due_date is informational for recurring maintenance; not all maintenance types require it
- cost column tracks total cost including parts and labor; itemization of parts is not stored (out of scope for this table)
- No asset can have maintenance created if asset condition = 'disposed'

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must NOT be 'completed'. Error: "Cannot delete completed maintenance records."
2. Pre-delete check: status must NOT be 'overdue'. Error: "Resolve overdue status before deleting."
3. Only 'scheduled' maintenance records can be soft-deleted
4. Audit log: action = "delete", entity_type = "inv_asset_maintenance", entity_id = {id}

**Restore:**
1. Only on soft-deleted 'scheduled' records
2. Sets deleted_at = NULL
3. Status restored to 'scheduled' (even if original next_due_date has passed — overdue transition will fire on next command run)
4. Audit log: action = "restore"

**Force Delete:**
1. Only on already soft-deleted records
2. Permanently removes maintenance record
3. No FK concerns (CASCADE on asset_id)

### Audit Trail Rules

- Every create, complete, soft delete, restore logged to hst_audit_log
- AuditService::log() with: entity_type = "inv_asset_maintenance", entity_id = {id}, action = {action_type}
- On complete: log cost, notes, next_due_date
- On overdue auto-transition: log as action = "maintenance_overdue" with system user reference
- Completion of overdue maintenance logged as action = "overdue_resolved"
- Cost updates (if allowed in rare admin scenarios) logged with old/new cost values

### List View Rules

- Controller: index() method, Gate: 'inventory.asset-maintenance.viewAny'
- Pagination: 15 records per page
- Eager loads: asset (asset_tag, stockItem.name), vendor (name)
- Default sort: by maintenance_date descending
- Columns displayed: Asset Tag, Asset Name, Maintenance Type (badge), Date, Vendor, Cost, Next Due Date, Status (badge — color-coded: blue=scheduled, green=completed, red=overdue), Actions
- Filter: asset_id dropdown (searchable select2)
- Filter: maintenance_type dropdown (all/preventive/corrective/amc/calibration)
- Filter: status dropdown (all/scheduled/completed/overdue)
- Filter: date range (from/to) for maintenance_date
- Filter: vendor_id dropdown (for AMC tracking)
- All filters preserved across pagination
- Actions column: Complete (visible when status = 'scheduled' or 'overdue'), View, Edit (only in scheduled status), Delete (only in scheduled status)
- Click row to expand notes and full details

### Integration Rules

**Notification Integration (via MaintenanceOverdue Event):**
- Event: MaintenanceOverdue fired by scheduled command
- Payload: `{asset_id, asset_tag, asset_item_name, maintenance_type, next_due_date, days_overdue}`
- Consumer: Notification module sends alert to store manager role
- Alert frequency: once per day per overdue record (command runs daily, but only fires event on first detection or configurable re-notify interval)

**Asset Integration:**
- Cannot create maintenance for disposed assets
- Pending 'scheduled' maintenance blocks asset disposal
- Asset condition can be updated to 'under_repair' when corrective maintenance is created (optional service-layer automation)
- Asset condition updated back from 'under_repair' when maintenance is completed (optional)

**Vendor Integration:**
- vendor_id references vnd_vendors.id (INT UNSIGNED)
- Vendor name/contact details displayed in maintenance detail view (read from vendor module)
- Future enhancement: create purchase requisition for spare parts from maintenance vendor

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.asset-maintenance.viewAny` |
| View details | `inventory.asset-maintenance.view` |
| Create | `inventory.asset-maintenance.create` |
| Edit/update | `inventory.asset-maintenance.update` |
| Complete maintenance | `inventory.asset-maintenance.complete` |
| Soft delete | `inventory.asset-maintenance.delete` |
| View trash & restore | `inventory.asset-maintenance.restore` |
| Force delete | `inventory.asset-maintenance.forceDelete` |
