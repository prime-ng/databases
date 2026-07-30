# Lib Library Status Masters — Business Requirements

## What This Screen Does
Manages all possible status values used across the library module, organized by status type. This is a centralized status lookup table that serves multiple sub-domains: Book Status, Member Status, Transaction Status, Reservation Status, Fine Status, Inventory Audit Status, Inventory Audit Detail Status, Digital Resource Status, Digital Access Transaction Status, and Digital Access Request Status. Instead of hardcoding ENUMs in each table, statuses are stored as rows here, keyed by `status_type` + `code`. This allows adding new statuses without code changes. Each library table that has a `status` FK column stores the integer `id` referencing this table. Admins can define, edit, activate/deactivate, and delete status values (except pre-seeded system records which are protected). The create form dynamically loads all available status types for selection.

---

## When This Screen Is Used
- Initial configuration of all library status enums during module setup.
- Adding a new status for a specific category (e.g., adding "Gold Member" to Member Status).
- Modifying a status name, description, or color badge.
- Changing the display color of a status (used for visual badges in tables).
- Deactivating a status so it cannot be assigned to new records.
- Reviewing all available statuses across the library.

## Default Data Load
- Index: Paginated list of all status masters, filterable by `status_type`. Shows status type, code, name, color badge, system flag, and active toggle.
- Create: Form with a dropdown of all status types (loaded dynamically from distinct `status_type` values), plus fields for code, name, description, color (default 'secondary'), and active toggle.
- Edit: Pre-populated form for an existing status. System records (`is_system=1`) are blocked from editing.
- Show: Read-only display of the status record.

---

## Key Fields at a Glance
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | SMALLINT UNSIGNED | PK, auto-increment | Compact ID for FK references from other tables |
| status_type | VARCHAR(50) | NOT NULL | Category: 11 pre-defined types (see below) |
| code | VARCHAR(30) | NOT NULL, unique per type | Machine-readable identifier (e.g., `ACTIVE`, `SUSPENDED`, `PAID`) |
| name | VARCHAR(100) | NOT NULL | Human-readable label (e.g., "Active", "Suspended", "Paid") |
| description | VARCHAR(255) | nullable | Optional explanation of when this status applies |
| color | VARCHAR(30) | DEFAULT 'secondary' | Bootstrap color class used for badge rendering |
| is_system | TINYINT(1) | DEFAULT 0 | System records are **protected** — cannot be edited, deleted, or force-deleted via CRUD |
| is_active | TINYINT(1) | DEFAULT 1, boolean | Soft on/off toggle |

---

## Business Rules and Conditions

### 1. Status Type Scoping (CRITICAL)
When this table is used in any CRUD dropdown (e.g., Book Copies, Members, Transactions, Reservations, Fines, Inventory Audits, Digital Resources, Digital Access), the system must **filter by `status_type`** — only statuses matching the specific type are shown. The 11 defined status types:

| # | status_type | Consumed By (Table) |
|---|-------------|---------------------|
| 1 | `Book Status` | `lib_book_copies.status` |
| 2 | `Digital Resource Status` | `lib_digital_resources.status` |
| 3 | `Member Status` | `lib_members.status` |
| 4 | `Transaction Status` | `lib_transactions.status` |
| 5 | `Reservation Status` | `lib_reservations.status` |
| 6 | `Digital Access Request Status` | `lib_digital_access_requests.status` |
| 7 | `Fine Status` | `lib_fines.status` |
| 8 | `Inventory Audit Status` | `lib_inventory_audit.status` |
| 9 | `Inventory Audit Detail Status` | `lib_inventory_audit_details.status` |
| 10 | `Digital Access Transaction Status` | `lib_digital_access_transactions.status` |
| 11 | `Digital Resource Status` | `lib_digital_resources.status` |

### 2. Unique Code per Type
The combination `(status_type, code)` must be unique (enforced by `UNIQUE KEY uq_lib_statusMaster_StatusType_Code`). Two different status types can have the same code (e.g., `ACTIVE` can exist under both "Member Status" and "Book Status"), but the same type cannot have duplicate codes.

### 3. System Protection (`is_system`)
Records with `is_system = 1` are protected at the controller level:
- **Edit:** Blocked — `edit()` checks and redirects with error.
- **Delete (soft):** Blocked — `destroy()` checks and redirects with error.
- **Force Delete:** Blocked — `forceDelete()` checks and redirects with error.
- **View:** Allowed — system records are visible for reference.
- **Toggle Status:** Allowed — can deactivate system statuses if needed.

### 4. Inactive Filtering
When `is_active = 0`, the status is hidden from all consuming CRUD dropdowns. Queries must use `->where('is_active', true)` when fetching for dropdown/select lists.

### 5. Color Badges
The `color` field stores a Bootstrap color name (e.g., `success`, `danger`, `warning`, `primary`, `secondary`, `info`), used to render colored badges in UI tables.

### 6. Scope by Type
The model provides `scopeByType($type)` for easy filtering. Usage: `LibLibraryStatusMaster::byType('Member Status')->get()`.

### 7. Lookup by Code (`getIdByCode`)
Controllers and Services use `LibLibraryStatusMaster::getIdByCode(string $statusType, string $code)` to resolve status IDs at runtime. This method is case-insensitive and uses a static `$idCache` for performance. Whenever a new status is seeded or modified, the cache can be cleared via `clearIdCache()`.

### 8. Deactivation Impact
Deactivating a status does not affect existing records that reference it, but prevents new records from being assigned that status.

### 9. Soft Delete
Deleting a status soft-deletes it. Existing FK references remain valid. Restoring a soft-deleted status should make it available again.

---

## Pre-Seeded System Records (34 total)

The following 34 system records are pre-seeded at installation with `is_system = 1`:

| Status Type | Codes | Count |
|------------|-------|-------|
| `Book Status` | Available, Issued, Reserved, Under_Maintenance, Lost, Withdrawn | 6 |
| `Digital Resource Status` | Available, License Consumed, License Expired | 3 |
| `Member Status` | Active, Expired, Suspended, Deactivated | 4 |
| `Transaction Status` | Issued, Returned, Overdue, Lost | 4 |
| `Reservation Status` | Pending, Available, Picked_Up, Cancelled, Expired | 5 |
| `Digital Access Request Status` | Pending, Approved, Rejected, Withdrawn | 4 |
| `Fine Status` | Pending, Paid, Waived, Overdue | 4 |
| `Inventory Audit Status` | In Progress, Completed, Cancelled | 3 |
| `Inventory Audit Detail Status` | Found, Missing, Misplaced, Damaged | 4 |
| `Digital Access Transaction Status` | Active, Expired, Revoked, Completed | 4 |

These records cannot be edited or deleted via CRUD (controller-level block based on `is_system = 1`). They can only be toggled active/inactive.

---

## Usage Map (Where Each status_type is Used)

| status_type | Consumed By (Table/Model) | Consumed By (Controller/Code) |
|------------|--------------------------|-------------------------------|
| `Book Status` | `lib_book_copies.status` | LibTransactionController, LibBookMaster, LibInventoryAuditController, StaffLibraryController, MasterDashboardService, LibAcquisitionReportService, LibDashboardReportService |
| `Digital Resource Status` | `lib_digital_resources.status` | LibDigitalResourceController |
| `Member Status` | `lib_members.status` | LibTransactionController, LibReservationController, LibMember, MasterDashboardService, LibDashboardReportService |
| `Transaction Status` | `lib_transactions.status` | LibTransactionController, LibTransaction (model), StaffLibraryController |
| `Reservation Status` | `lib_reservations.status` | LibReservationController, LibReservation (model), StaffLibraryController, MasterDashboardService, LibAcquisitionReportService, LibDashboardReportService |
| `Digital Access Request Status` | `lib_digital_access_requests.status` | LibDigitalAccessRequestController |
| `Fine Status` | `lib_fines.status` | FineCalculationService, LibTransactionController, LibFineReportService |
| `Inventory Audit Status` | `lib_inventory_audit.status` | LibInventoryAuditController |
| `Inventory Audit Detail Status` | `lib_inventory_audit_details.status` | LibInventoryAuditController |
| `Digital Access Transaction Status` | `lib_digital_access_transactions.status` | LibDigitalAccessTransactionController |

---

## Workflow Steps
1. Admin navigates to Library Status Masters.
2. System loads all statuses grouped or filterable by `status_type`.
3. Admin selects a status type filter to narrow down the list.
4. Admin clicks "Add Status" to open the create form.
5. Admin selects the status type, enters a code, name, description, picks a color, and toggles active.
6. System validates: status_type required, code unique within that type, name required.
7. System saves and redirects to the list.
8. Admin can edit any **non-system** status to update its name, description, or color. System records show edit/delete buttons as disabled.
9. Admin can toggle active status or delete. System records can be toggled but not deleted.
10. Deleted statuses can be restored from the trash.

---

## Example Scenarios

**Adding a "Diamond Member" status:**
1. Admin selects `status_type` = "Member Status" from the dropdown.
2. Admin enters code = `DIAMOND`, name = `Diamond Member`, description = `Premium tier with highest borrowing privileges`, color = `info` (blue badge).
3. System saves the status. It now appears in the Member create/edit form as an available status option.
4. When a member reaches the Diamond tier, the librarian selects this status and a blue "Diamond Member" badge appears on the member's profile.

**Attempting to edit a system record:**
1. Admin clicks Edit on "Book Status" → "Available" (a system record).
2. Controller checks `$record->is_system`, redirects back with error "System records cannot be edited."
3. Similarly, delete and force-delete are blocked.

---

## Related Screens
- **Book Copies (lib_book_copies)** — `status` FK filtered by `status_type = 'Book Status'`
- **Member Management (lib_members)** — `status` FK filtered by `status_type = 'Member Status'`
- **Fine Management (lib_fines)** — `status` FK filtered by `status_type = 'Fine Status'`
- **Transaction Management (lib_transactions)** — `status` FK filtered by `status_type = 'Transaction Status'`
- **Reservations (lib_reservations)** — `status` FK filtered by `status_type = 'Reservation Status'`
- **Inventory Audit** — Two status types: Audit Status and Audit Detail Status
- **Digital Resources** — `status` FK filtered by `status_type = 'Digital Resource Status'`
- **Digital Access Transactions** — `status` FK filtered by `status_type = 'Digital Access Transaction Status'`

---

## Requirements
(technical: controller, model, validation, activityLog, policy)

- **Controller:** `LibLibraryStatusMasterController` — Standard CRUD. `create()` loads all distinct `status_type` values from the database for the dropdown. `edit()`, `destroy()`, and `forceDelete()` check `$record->is_system` and block with redirect error if true.
- **Model:** `LibLibraryStatusMaster` — table `lib_library_status_masters`, fillable: `status_type`, `code`, `name`, `description`, `color`, `is_system`, `is_active`. Scopes: `scopeByType($type)` for filtered queries. Static methods: `getIdByCode(string $statusType, string $code)` (case-insensitive, cached), `clearIdCache()`. No relationships defined.
- **Validation (FormRequest):** `status_type` => required|string|max:50; `code` => required|string|max:30|unique:lib_library_status_masters,code,NULL,id,status_type,$this->status_type (unique scoped by status_type); `name` => required|string|max:100; `description` => nullable|string|max:255; `color` => nullable|string|max:30; `is_active` => boolean.
- **ActivityLog:** Must call `activityLog()` after create, update, delete, restore, forceDelete.
- **Policy:** Gate string `tenant.lib-library-status-masters.*` mapped to `LibLibraryStatusMasterPolicy`.
- **Permissionslist entry:** `'lib-library-status-masters' => $crud`

---

## Who Can Access This Screen
- Users with `tenant.lib-library-status-masters.viewAny` — list page and tab visibility.
- Users with `tenant.lib-library-status-masters.create` — add button and store.
- Users with `tenant.lib-library-status-masters.view` — show/details page.
- Users with `tenant.lib-library-status-masters.update` — edit, update, toggle status.
- Users with `tenant.lib-library-status-masters.delete` — soft delete.
- Users with `tenant.lib-library-status-masters.restore` — trash view and restore.
- Users with `tenant.lib-library-status-masters.forceDelete` — permanent delete.

---

## How This Screen Works — Logic Flow (Non-Technical)
1. User opens the Library Status Masters page.
2. By default, the system shows all statuses across all types. The user can filter by status type using a dropdown.
3. The table displays each status with its type, code, name, a colored badge (using the configured color), a system record indicator, and an active toggle.
4. To add a new status, the user clicks "Add Status." The form presents a dropdown of all existing status types and fields for the code, name, description, and color.
5. When saving, the system checks that the combination of status type and code is unique.
6. After saving, the new status appears in the list and becomes available for use in its respective module area.
7. The user can change the display color of any status to control how it appears in badges across the system.
8. Pre-seeded system records (34 total, marked with "System") cannot be edited or deleted. Their edit and delete buttons are hidden or disabled.
9. Deactivated or deleted statuses are hidden from selection dropdowns but remain on existing records.
10. When building a create/edit form for a dependent entity (e.g., adding a book copy), the system calls `getIdByCode('Book Status', 'Available')` to pre-select the default status.

---

## Validate Before Save
1. `status_type` is required, must be a string ≤50 characters.
2. `code` is required, must be a string ≤30 characters, unique within the same `status_type`.
3. `name` is required, must be a string ≤100 characters.
4. `description` is optional, ≤255 characters.
5. `color` is optional, must be a string ≤30 characters (defaults to `secondary`).
6. `is_active` is a boolean flag.
7. Update validation scopes the unique `code` check to the same `status_type`, excluding the current record.
8. `is_system` is NOT user-assignable — it is set automatically for pre-seeded records only.

---

## Error Handling and Validation Messages

### General Validation
| Condition | Message |
|-----------|---------|
| Status type missing | "The status type field is required." |
| Code missing | "The code field is required." |
| Code duplicate within type | "The code has already been taken." |
| Code too long | "The code must not be greater than 30 characters." |
| Name missing | "The name field is required." |
| Name too long | "The name must not be greater than 100 characters." |

### System Protection Errors
| Condition | Message |
|-----------|---------|
| Edit system record | "System records cannot be edited." |
| Delete system record | "System records cannot be deleted." |
| Force delete system record | "System records cannot be permanently deleted." |

---

## Success Scenarios
1. **Create:** Valid status saved. Redirect to list with "Library Status Master created successfully."
2. **Update:** Modified status saved. Redirect to list with "Library Status Master updated successfully."
3. **Toggle Status:** AJAX toggles `is_active`. Returns `{success: true, is_active: bool}`.
4. **Soft Delete (non-system):** Record soft-deleted. Success message displayed.
5. **Restore:** Record restored, `is_active` set to true. Success message.
6. **Force Delete (non-system):** Record permanently removed. Success message.

---

## Failure Scenarios
1. **Create with duplicate code in same type:** Validation fails, code uniqueness scoped by status_type enforced.
2. **Create with same code in different type:** Allowed. No conflict.
3. **Update with code changed to another existing code in same type:** Unique validation fails.
4. **Edit a system record:** Controller redirects with error "System records cannot be edited."
5. **Delete a system record:** Controller redirects with error "System records cannot be deleted."
6. **Toggle status on non-existent record:** `findOrFail` throws 404.
7. **Force delete record referenced by FK:** FK constraint violation, caught as DB exception.

---

## Dependencies module and tables
| Dependency | Type | Details |
|-----------|------|---------|
| `lib_library_status_masters` | Table | Primary table for this feature |
| `lib_book_copies` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Book Status') |
| `lib_digital_resources` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Digital Resource Status') |
| `lib_members` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Member Status') |
| `lib_transactions` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Transaction Status') |
| `lib_reservations` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Reservation Status') |
| `lib_fines` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Fine Status') |
| `lib_inventory_audit` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Inventory Audit Status') |
| `lib_inventory_audit_details` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Inventory Audit Detail Status') |
| `lib_digital_access_transactions` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Digital Access Transaction Status') |
| `lib_digital_access_requests` | Table | `status` FK → `lib_library_status_masters.id` (filtered by 'Digital Access Request Status') |
| `lib-library-status-masters` | Permission | CRUD permissions defined in `permissionslist.php` |
| `LibLibraryStatusMasterPolicy` | Policy | Authorization policy mapped to `tenant.lib-library-status-masters.*` |
