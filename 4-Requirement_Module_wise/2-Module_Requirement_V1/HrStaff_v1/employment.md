# Employment Details — Requirements

## What It Does
Manages contractual and financial employment information for staff members. Stores contract type, probation periods, bank account details (encrypted), emergency contacts, and previous employment history. Tracks all changes via an audited EmploymentHistory log. Operates as a supplement to the core Employee profile from SchoolSetup module.

Features:
- Encrypted bank account number storage
- JSON-based emergency contacts (unlimited entries)
- JSON-based previous employer records (unlimited entries)
- Full audit trail via EmploymentHistory model
- Employee code auto-generation (`EMP/YYYY/NNNNN`)
- Soft-delete with restore for employment records

## Database Fields

**hrs_employment_details**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `contract_type` | ENUM | `permanent`, `contractual`, `probation`, `part_time`, `substitute`. Required. |
| `probation_end_date` | DATE | Nullable. Only relevant when contract_type = probation. |
| `confirmation_date` | DATE | Nullable. Set when probation is successfully completed. |
| `notice_period_days` | INTEGER | Default 0. Range 0-180. |
| `bank_account_number` | VARCHAR(255) | Encrypted at rest via Laravel `encrypted` cast. |
| `bank_ifsc` | VARCHAR(11) | Required. 11-character IFSC code. |
| `bank_name` | VARCHAR(100) | Required. |
| `bank_branch` | VARCHAR(100) | Required. |
| `emergency_contact_json` | JSON | Array of objects: `{name, relation, phone, address}`. Cast to array. |
| `previous_employer_json` | JSON | Array of objects: `{employer_name, from_date, to_date, designation, reason_for_leaving}`. Cast to array. |
| `is_active` | BOOLEAN | Default true. |
| `created_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. |
| `updated_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_employment_history**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. CASCADE on delete. |
| `change_type` | VARCHAR(255) | Describes the change (e.g., `contract_change`, `bank_update`, `probation_extension`). |
| `old_value` | JSON | Snapshot of the previous field values before the change. Cast to array. |
| `new_value` | JSON | Snapshot of the new field values after the change. Cast to array. |
| `effective_date` | DATE | Date the change takes effect. |
| `changed_by` | BIGINT UNSIGNED FK → `sch_employees` | Employee who made the change. |
| `remarks` | VARCHAR(255) | Optional notes about why the change was made. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Employee Code Auto-Generation**
- Format: `EMP/YYYY/NNNNN` (e.g., `EMP/2026/00001`)
- Year prefix based on current year
- Sequence increments globally per year
- Generated before creation
- Lock-guarded to prevent duplicate codes

**Contract Type Behavior**
- `permanent`: No probation end date required. Confirmation date may be set.
- `probation`: `probation_end_date` must be in the future on creation. On confirmation, `confirmation_date` is set.
- `contractual`: Optional end date tracked in the contract. No probation.
- `part_time` / `substitute`: Limited-hour contracts.

**Bank Account Encryption**
- `bank_account_number` uses Laravel's `encrypted` cast
- Automatically decrypted when accessed via the model
- Never logged in plain text in EmploymentHistory
- The `bank_ifsc` field is NOT encrypted (static identifier)

**Emergency Contact Structure**
- JSON array allowing multiple contacts
- Each entry: `{name: string, relation: string, phone: string, address: string}`
- Front-end renders as dynamic add/remove rows via JavaScript
- At least one emergency contact recommended but not enforced at DB level

**Previous Employer Structure**
- JSON array allowing multiple employers
- Each entry: `{employer_name: string, from_date: date, to_date: date, designation: string, reason_for_leaving: string}`
- `to_date` must be before the employee's joining date at this school

**History Audit**
- `EmploymentService::createOrUpdate()` diffs old and new values
- On create: logs `employment_created` with empty old_value
- On update: logs `field_changed` for each changed field with old/new snapshots
- History entries are append-only and never modified

**Probation End Date Validation**
- When creating: `probation_end_date` must be after the current date
- When updating: if changing to permanent, `confirmation_date` is required

**Soft Delete Cascade**
- Deleting EmploymentDetail soft-deletes related EmploymentHistory records
- Trashed records can be restored with their history

## CRUD Operations

**Show Employment Details**
- Displays employment detail form pre-populated with existing data (or blank for new)
- Shows emergency contacts and previous employers as dynamic JSON lists
- Includes employment history timeline at the bottom

**Create / Update Employment Details**
- Contract type switch toggles probation/confirmation date visibility
- Bank details section with encrypted display (shows last 4 digits, full visible on toggle)
- Emergency contacts rendered as dynamic add/remove rows
- On update: diffs old vs new, logs changes to EmploymentHistory

**View Employment History**
- Returns paginated timeline of all employment changes
- Each entry shows: change type, old value → new value, effective date, who changed it, remarks

## Permissions

| Operation | Permission Key |
|---|---|
| View / manage employment details | `hrs.employment.manage` |
| View own employment record | Always allowed (policy allows self-view) |
| Edit own emergency contacts | `hrs.employment.manage` |
